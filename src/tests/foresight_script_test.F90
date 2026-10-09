!< foresight_script test: gnuplot scripts rendered byte-exact, `using` expressions, functions, CSV data, the second y
!< axis, and unsupported constructs reported as errors.
program foresight_script_test
!< foresight_script test: gnuplot scripts rendered byte-exact, `using` expressions, functions, CSV data, the second y
!< axis, and unsupported constructs reported as errors.
!<
!< Run from the repository root; `FORESIGHT_UPDATE_GOLDEN=1` rewrites the reference file.
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan
use, intrinsic :: iso_fortran_env, only : error_unit, output_unit
use foresight, only : I4P, R8P, script_object
use foresight_style, only : FILL_EMPTY, FILL_SOLID, WITH_BOXES, WITH_CIRCLES, WITH_PIE, WITH_FILLEDCURVES, WITH_GAUGE, &
                            WITH_ROSE, WITH_IMPULSES, WITH_STEPS, WITH_FSTEPS, WITH_HISTEPS, WITH_DOTS, WITH_YERRORLINES, &
                            WITH_XERRORLINES, WITH_XYERRORLINES, WITH_BOXERRORBARS, WITH_BOXXYERROR, WITH_CANDLESTICKS, &
                            WITH_FINANCEBARS, WITH_BOXPLOT, WITH_VECTORS, WITH_ARROWS, WITH_ELLIPSES, WITH_POLYGONS, &
                            WITH_LABELS, WITH_SECTORS, &
                            WITH_HISTOGRAMS, WITH_LINES, &
                            WITH_LINESPOINTS, &
                            WITH_POINTS, WITH_READOUT

implicit none
character(len=*), parameter   :: data_file = 'foresight_script_test.dat'   !< Test data file.
character(len=*), parameter   :: output    = 'foresight_script_test.svg'   !< Rendered file.
character(len=*), parameter   :: golden    = 'src/tests/golden/script.svg' !< Reference file.
character(len=*), parameter   :: scratch   = 'foresight_script_test_expressions.svg' !< Expression plots.
character(len=*), parameter   :: options   = 'foresight_script_test_options.svg'     !< Options plot.
character(len=*), parameter   :: options_golden = 'src/tests/golden/options.svg'    !< Options reference.
character(len=*), parameter   :: csv_file  = 'foresight_script_test.csv'   !< CSV data file.
character(len=*), parameter   :: y2        = 'foresight_script_test_y2.svg'          !< Second y axis plot.
character(len=*), parameter   :: y2_golden = 'src/tests/golden/y2.svg'                !< Second y axis reference.
type(script_object)           :: interpreter                               !< Interpreter.
character(len=:), allocatable :: iomsg                                     !< Error message.
character(len=:), allocatable :: script                                    !< Script text.
character(len=8)              :: update_flag                               !< FORESIGHT_UPDATE_GOLDEN value.
integer(I4P)                  :: iostat                                    !< Status.
integer(I4P)                  :: unit                                      !< File unit.
integer(I4P)                  :: i                                         !< Counter.
logical                       :: test_passed(72)                           !< Per-check outcome.
real(R8P)                     :: xmin                                      !< Data extent start.
real(R8P)                     :: xmax                                      !< Data extent end.
real(R8P)                     :: ymin(2)                                   !< Data extent bottoms.
real(R8P)                     :: ymax(2)                                   !< Data extent tops.
logical                       :: found(2)                                  !< Data per y axis.
real(R8P), allocatable        :: arcs(:,:)                                 !< Wedge angles.

test_passed = .false.
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '# iteration  continuity  momentum'
do i = 1, 30
   write(unit, '(I0,2(1X,ES24.16E3))') i, 10.0_R8P**(-0.2_R8P * i), 10.0_R8P**(-0.15_R8P * i)
enddo
close(unit)

! a monitoring script: terminal, labels, log scale, two items from one file with abbreviations and ''
script = "set terminal svg size 500,350"//new_line('a')// &
         "set output '"//output//"'"//new_line('a')// &
         'set title "Residuals" # comment'//new_line('a')// &
         "set xlabel 'iteration'; set ylabel 'residual'"//new_line('a')// &
         "set logscale y"//new_line('a')// &
         "set grid"//new_line('a')// &
         "plot '"//data_file//"' u 1:2 w l t 'continuity', \"//new_line('a')// &
         "     '' u 1:3 w lp lw 2 ps 0.8 lc rgb '#e51e10' notitle"//new_line('a')
call interpreter%init('foresight_script_test.html')
call interpreter%run_text(script, iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(1) = iostat == 0_I4P .and. size(interpreter%data_files) == 1
test_passed(2) = matches_golden(output, golden)

! replot re-reads and re-renders
open(newunit=unit, file=output)
close(unit, status='delete')
call interpreter%execute('replot', iostat, iomsg)
inquire(file=output, exist=test_passed(3))

! the terminal sets the extension of the default output, never of an explicit one
call interpreter%init('run.html')
call interpreter%execute('set terminal svg', iostat, iomsg)
test_passed(4) = interpreter%output == 'run.svg'
call interpreter%execute("set output 'mine.html'", iostat, iomsg)
call interpreter%execute('set terminal svg', iostat, iomsg)
test_passed(5) = interpreter%output == 'mine.html'

! unsupported constructs are errors naming source and line
call interpreter%init('run.html')
call interpreter%run_text('set grid'//new_line('a')//'splot x', iostat, iomsg, source='t.gp')
test_passed(6) = iostat /= 0_I4P .and. iomsg == 't.gp:2: unsupported command "splot"'
call interpreter%run_text('plot [0:1] sin(x)', iostat, iomsg)
test_passed(7) = iostat /= 0_I4P .and. index(iomsg, 'inline ranges are not supported') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:$2", iostat, iomsg)
test_passed(8) = iostat /= 0_I4P .and. index(iomsg, 'nor a parenthesized expression') > 0
call interpreter%run_text('set xrange [a:1]', iostat, iomsg)
test_passed(9) = iostat /= 0_I4P .and. index(iomsg, 'is not a number') > 0

! using expressions: scaled column, blanks inside parentheses
call interpreter%init(scratch)
call interpreter%run_text("plot '"//data_file//"' u ($1 - 1):($2*1e3) t 'scaled'", iostat, iomsg)
if (iostat == 0_I4P) then
   associate(series => interpreter%figure%panels(1)%series(1))
      test_passed(10) = series%x(1) == 0.0_R8P .and. abs(series%y(1) / (1.0e3_R8P * 10.0_R8P**(-0.2_R8P)) - 1.0_R8P) &
                        < 1.0e-12_R8P
   endassociate
endif

! gnuplot automatic titles: the item as written; 1/0 filters points out
call interpreter%run_text("plot '"//data_file//"' u 0:($3 > 1.5e-3 ? $3 : 1/0), ''", iostat, iomsg)
if (iostat == 0_I4P) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(11) = panel%series(1)%title == "'"//data_file//"' u 0:($3 > 1.5e-3 ? $3 : 1/0)" .and. &
                        panel%series(2)%title == "''" .and. .not. ieee_is_nan(panel%series(1)%y(18)) .and. &
                        ieee_is_nan(panel%series(1)%y(19))
   endassociate
endif

! syntax errors point at the offending character
call interpreter%run_text("plot '"//data_file//"' u 1:($2 +)", iostat, iomsg)
test_passed(12) = iostat /= 0_I4P .and. index(iomsg, 'using: unexpected ")" at character 6 of "($2 +)"') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! key placement and box, data and line styles, full every, fixed ticks, label format
script = "set terminal svg size 500,350; set output '"//options//"'"//new_line('a')// &
         "set key bottom left box; set style data linespoints"//new_line('a')// &
         "set style line 1 lc rgb '#e51e10' lw 2 dt 2"//new_line('a')// &
         "set xtics 0,5,30; set logscale y; set format y '%.0e'"//new_line('a')// &
         "plot '"//data_file//"' every 2::1 u 1:2 t 'odd rows' ls 1, '' u 1:3 w l lt 3 t 'momentum'"
call interpreter%init('x.html')
call interpreter%run_text(script, iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(13) = iostat == 0_I4P .and. matches_golden(options, options_golden)
test_passed(14) = size(interpreter%figure%panels(1)%series(1)%x) == 15

! option errors name the option
call interpreter%run_text('set xtics 1,', iostat, iomsg)
test_passed(15) = iostat /= 0_I4P .and. index(iomsg, 'set xtics: supported forms') > 0
call interpreter%run_text("set format z '%g'", iostat, iomsg)
test_passed(16) = iostat /= 0_I4P .and. index(iomsg, 'axes must be among x, y, y2') > 0
call interpreter%run_text("set format y '%d'", iostat, iomsg)
test_passed(17) = iostat /= 0_I4P .and. index(iomsg, 'unsupported conversion "%d"') > 0
call interpreter%run_text('set key lmargin', iostat, iomsg)
test_passed(18) = iostat /= 0_I4P .and. index(iomsg, 'set key: unsupported option "lmargin"') > 0
call interpreter%run_text("plot '"//data_file//"' every 0", iostat, iomsg)
test_passed(19) = iostat /= 0_I4P .and. index(iomsg, 'positive increments') > 0
call interpreter%run_text('set style line 1 pi 2', iostat, iomsg)
test_passed(20) = iostat /= 0_I4P .and. index(iomsg, 'set style line: unsupported option "pi"') > 0

! functions: 100 samples over [-10:10] without data, the expression as written is the title
call interpreter%init(scratch)
call interpreter%run_text('plot sin(x)', iostat, iomsg)
if (iostat == 0_I4P) then
   associate(series => interpreter%figure%panels(1)%series(1))
      test_passed(21) = size(series%x) == 100 .and. series%x(1) == -10.0_R8P .and. series%x(100) == 10.0_R8P .and. &
                        series%y(1) == sin(-10.0_R8P) .and. series%title == 'sin(x)'
   endassociate
endif

! functions sampled over the data extent, at set samples points; lines whatever the data style; blanks kept in the title
call interpreter%run_text("set samples 5; set style data points"//new_line('a')// &
                          "plot '"//data_file//"' u 1:2, x  *  3 lw 2", iostat, iomsg)
if (iostat == 0_I4P) then
   associate(series => interpreter%figure%panels(1)%series(2))
      test_passed(22) = all(series%x == [1.0_R8P, 8.25_R8P, 15.5_R8P, 22.75_R8P, 30.0_R8P]) .and. &
                        all(series%y == 3.0_R8P * series%x) .and. series%title == 'x  *  3' .and. &
                        series%style%with == WITH_LINES .and. series%style%linewidth == 2.0_R8P
   endassociate
endif

! function errors
call interpreter%run_text('plot x u 1:2', iostat, iomsg)
test_passed(23) = iostat /= 0_I4P .and. index(iomsg, '"u" applies to data files, not to the function "x"') > 0
call interpreter%run_text('plot $1', iostat, iomsg)
test_passed(24) = iostat /= 0_I4P .and. index(iomsg, 'columns are only valid in using') > 0
call interpreter%run_text('plot x w yerr', iostat, iomsg)
test_passed(25) = iostat /= 0_I4P .and. index(iomsg, 'a function is drawn with lines, points, linespoints, impulses') > 0
call interpreter%run_text('set samples 1', iostat, iomsg)
test_passed(26) = iostat /= 0_I4P .and. index(iomsg, 'the sampling rate must be > 1') > 0 .and. &
                  interpreter%samples == 5_I4P
open(newunit=unit, file=scratch)
close(unit, status='delete')

! CSV data: header row, a missing cell, a quoted number
open(newunit=unit, file=csv_file, action='write', status='replace')
write(unit, '(A)') 'iteration,residual,coefficient'
do i = 1, 30
   if (i == 12) then
      write(unit, '(I0,A,ES24.16E3,A)') i, ',', 10.0_R8P**(-0.2_R8P * i), ','
   else
      write(unit, '(I0,A,ES24.16E3,A,F0.6,A)') i, ',', 10.0_R8P**(-0.2_R8P * i), ',"', &
                                               0.5_R8P + 0.3_R8P * sin(real(i, R8P) / 4.0_R8P), '"'
   endif
enddo
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("set datafile separator ','; plot '"//csv_file//"' u 1:3", iostat, iomsg)
if (iostat == 0_I4P) then
   associate(series => interpreter%figure%panels(1)%series(1))
      test_passed(27) = size(series%x) == 31 .and. ieee_is_nan(series%x(1)) .and. series%x(2) == 1.0_R8P .and. &
                        ieee_is_nan(series%y(13)) .and. abs(series%y(2) - 0.5_R8P - 0.3_R8P * sin(0.25_R8P)) < 1.0e-6_R8P
   endassociate
endif
call interpreter%run_text('set datafile separator "\t"', iostat, iomsg)
test_passed(28) = iostat == 0_I4P .and. interpreter%separator == achar(9)
call interpreter%run_text('unset datafile', iostat, iomsg)
test_passed(29) = iostat == 0_I4P .and. interpreter%separator == ''
call interpreter%run_text('set datafile missing "?"', iostat, iomsg)
test_passed(30) = iostat /= 0_I4P .and. index(iomsg, 'set datafile: unsupported option "missing"') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! second y axis: CSV data on both axes, a function on y2, y2 ticks and label, y ticks not mirrored
script = "set terminal svg size 500,350; set output '"//y2//"'"//new_line('a')// &
         "set datafile separator comma; set samples 20"//new_line('a')// &
         "set logscale y; set ytics nomirror; set y2tics 0.1; set ylabel 'residual'; set y2label 'coefficient'"// &
         new_line('a')//"plot '"//csv_file//"' u 1:2 t 'residual', '' u 1:3 axes x1y2 w p t 'coefficient', \"// &
         new_line('a')//"     0.5 + 0.3*sin(x/4) axes x1y2 t 'model'"
call interpreter%init('x.html')
call interpreter%run_text(script, iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(31) = iostat == 0_I4P .and. matches_golden(y2, y2_golden)
associate(panel => interpreter%figure%panels(1))
   test_passed(32) = .not. panel%series(1)%y2 .and. panel%series(2)%y2 .and. panel%series(3)%y2 .and. &
                     panel%series(3)%x(1) == 1.0_R8P .and. panel%series(3)%x(20) == 30.0_R8P .and. &
                     .not. panel%yaxis%tics%mirror .and. panel%y2_active
endassociate

! axes names: y and y2 are distinct, x2 is not supported
call interpreter%init('x.html')
call interpreter%run_text("set logscale xy2; set format y2 '%.1f'", iostat, iomsg)
associate(panel => interpreter%figure%panels(1))
   test_passed(33) = iostat == 0_I4P .and. panel%xaxis%log .and. .not. panel%yaxis%log .and. panel%y2axis%log .and. &
                     panel%y2axis%tics%format == '%.1f' .and. .not. panel%yaxis%tics%has_format()
endassociate
call interpreter%run_text('set logscale x2', iostat, iomsg)
test_passed(34) = iostat /= 0_I4P .and. index(iomsg, 'axes among x, y, y2 expected') > 0
call interpreter%run_text("plot '"//data_file//"' axes x2y1", iostat, iomsg)
test_passed(35) = iostat /= 0_I4P .and. index(iomsg, 'axes x1y1 or x1y2 expected, found "x2y1"') > 0

! set xtics without positions keeps the last ones, also after unset xtics; auto forgets them (gnuplot 6.0)
call interpreter%init('x.html')
associate(tics => interpreter%figure%panels(1)%xaxis%tics)
   call interpreter%run_text('set xtics 5; set xtics', iostat, iomsg)
   test_passed(36) = tics%attribute() == '* 5 *'
   call interpreter%run_text('unset xtics; set xtics', iostat, iomsg)
   test_passed(36) = test_passed(36) .and. tics%attribute() == '* 5 *'
   call interpreter%run_text('set xtics auto; unset xtics; set xtics', iostat, iomsg)
   test_passed(36) = test_passed(36) .and. tics%attribute() == ''
   call interpreter%run_text('set xtics 0,2,10; unset xtics; set xtics nomirror', iostat, iomsg)
   test_passed(36) = test_passed(36) .and. tics%attribute() == '0 2 10' .and. .not. tics%mirror
endassociate
! a number beyond the real range is an error, not an IEEE overflow
call interpreter%run_text('set xrange [1e999:1]', iostat, iomsg)
test_passed(37) = iostat /= 0_I4P .and. index(iomsg, '"1e999" is not a number') > 0

! set style function: the default style of functions, error bars refused; with overrides it; unset restores lines
call interpreter%init(scratch)
call interpreter%run_text('set style f p; plot x, x**2 w lp', iostat, iomsg)
test_passed(38) = iostat == 0_I4P
if (test_passed(38)) test_passed(38) = interpreter%figure%panels(1)%series(1)%style%with == WITH_POINTS .and. &
                                       interpreter%figure%panels(1)%series(2)%style%with == WITH_LINESPOINTS
call interpreter%run_text('set style function yerrorbars', iostat, iomsg)
test_passed(38) = test_passed(38) .and. iostat /= 0_I4P .and. index(iomsg, 'not usable for function plots') > 0
call interpreter%run_text('unset style function; plot x', iostat, iomsg)
test_passed(38) = test_passed(38) .and. iostat == 0_I4P
if (test_passed(38)) test_passed(38) = interpreter%figure%panels(1)%series(1)%style%with == WITH_LINES
open(newunit=unit, file=scratch)
close(unit, status='delete')

! column headers, as gnuplot 6.0: used by name, as titles; the header row is then not a point (nor counted by $0)
open(newunit=unit, file=csv_file, action='write', status='replace')
write(unit, '(A)') 'it,res,coef'
write(unit, '(A)') '1,10,5'
write(unit, '(A)') '2,20,6'
write(unit, '(A)') '3,30,7'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("set datafile separator comma"//new_line('a')//"plot '"//csv_file//"' u 1:""res"", "// &
                          "'' u 0:3 t columnhead, '' u 1:(column(""coef"")*2) t columnheader(2), '' u 1:3", iostat, iomsg)
test_passed(39) = iostat == 0_I4P
if (test_passed(39)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(39) = series(1)%title == "'"//csv_file//"' u 1:""res""" .and. all(series(1)%y == [10, 20, 30]) .and. &
                        series(2)%title == 'coef' .and. all(series(2)%x == [0, 1, 2]) .and. &
                        series(3)%title == 'res' .and. all(series(3)%y == [10, 12, 14]) .and. &
                        size(series(4)%y) == 4 .and. ieee_is_nan(series(4)%y(1))
   endassociate
endif
! autotitle columnhead: every item reads a header, explicit titles win
call interpreter%run_text("set key autotitle columnhead; plot '"//csv_file//"' u 1:2, '' u 1:3 t 'mine', '' u 0:3", &
                          iostat, iomsg)
test_passed(40) = iostat == 0_I4P
if (test_passed(40)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(40) = series(1)%title == 'res' .and. series(2)%title == 'mine' .and. size(series(2)%y) == 3 .and. &
                        series(3)%title == 'coef' .and. all(series(3)%x == [0, 1, 2])
   endassociate
endif
call interpreter%run_text("set key noautotitle; plot '"//csv_file//"' u 1:2, x", iostat, iomsg)
if (test_passed(40)) test_passed(40) = iostat == 0_I4P .and. interpreter%figure%panels(1)%series(1)%title == '' .and. &
                                       interpreter%figure%panels(1)%series(2)%title == ''
! names glued to ":", quoted names with blanks, columnhead(N), the header of each dataset
open(newunit=unit, file=csv_file, action='write', status='replace')
write(unit, '(A)') '"it" "the res" coef'
write(unit, '(A)') '1 10 5'
write(unit, '(A)') '2 20 6'
write(unit, '(A)') ''
write(unit, '(A)') ''
write(unit, '(A)') 'it res2 coef2'
write(unit, '(A)') '1 11 9'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("plot '"//csv_file//"' i 0 u ""it"":""the res"" t columnhead, '' i 0 u 1:($3*2) t "// &
                          "columnhead, '' i 0 u 1:3 t columnhead(9), '' index 1 u 1:""res2"" t columnhead(1)", iostat, iomsg)
test_passed(41) = iostat == 0_I4P
if (test_passed(41)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(41) = series(1)%title == 'the res' .and. all(series(1)%y == [10, 20]) .and. &
                        series(2)%title == 'coef' .and. series(3)%title == '' .and. series(4)%title == 'it' .and. &
                        all(series(4)%y == [11])
   endassociate
endif
call interpreter%run_text("plot '"//csv_file//"' u 1:""nope""", iostat, iomsg)
test_passed(42) = iostat /= 0_I4P .and. index(iomsg, 'no column with header "nope"') > 0
call interpreter%run_text("plot x t columnhead", iostat, iomsg)
test_passed(42) = test_passed(42) .and. iostat /= 0_I4P .and. index(iomsg, 'a function has no column header') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! point types: in an item, in a line style, the long form; never negative; without pt the round dot (-1)
call interpreter%init(scratch)
call interpreter%run_text("set style line 3 pt 6 ps 2; plot x w p pt 7, x w lp ls 3, x w p pointtype 12, x w p", &
                          iostat, iomsg)
test_passed(43) = iostat == 0_I4P
if (test_passed(43)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(43) = series(1)%style%pointtype == 7_I4P .and. series(2)%style%pointtype == 6_I4P .and. &
                        series(2)%style%pointsize == 2.0_R8P .and. series(3)%style%pointtype == 12_I4P .and. &
                        series(4)%style%pointtype == -1_I4P
   endassociate
endif
call interpreter%run_text("plot x w p pt -1", iostat, iomsg)
test_passed(43) = test_passed(43) .and. iostat /= 0_I4P .and. index(iomsg, 'pt needs a point type >= 0') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! smooth, as gnuplot 6 computes it (set table): each run (block, between undefined points) sorted by x, equal x merged;
! the normalized filters divide by the sum over every run
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '3 1', '1 2', '2 4', '1 6', 'NaN 5', '4 NaN', '2 1', '', '', '5 2', '0 3'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("plot '"//data_file//"' smooth unique, '' s cumulative, '' smooth cnormal, '' smooth frequency", &
                          iostat, iomsg)
test_passed(44) = iostat == 0_I4P
if (test_passed(44)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(44) = same(series(1)%x, [1, 2, 3, -1, 2, -1, 0, 5]) .and. same(series(1)%y, [4, 4, 1, -1, 1, -1, 3, 2]) &
                        .and. same(series(2)%y, [8, 12, 13, -1, 1, -1, 3, 5]) .and. &
                        same(series(3)%y * 19.0_R8P, [8, 12, 13, -1, 1, -1, 3, 5]) .and. &
                        same(series(4)%y, [8, 4, 1, -1, 1, -1, 3, 2])
   endassociate
endif
! a log y axis breaks the runs at the non-positive values
call interpreter%run_text("set logscale y; plot '"//data_file//"' smooth cumulative", iostat, iomsg)
test_passed(44) = test_passed(44) .and. iostat == 0_I4P
if (test_passed(44)) test_passed(44) = same(interpreter%figure%panels(1)%series(1)%y, [8, 12, 13, -1, 1, -1, 3, 5])
call interpreter%run_text("plot '"//data_file//"' smooth csplines", iostat, iomsg)
test_passed(45) = iostat /= 0_I4P .and. index(iomsg, 'unsupported smooth "csplines"') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2:(0.1) w yerr smooth unique", iostat, iomsg)
test_passed(45) = test_passed(45) .and. iostat /= 0_I4P .and. index(iomsg, 'smooth applies to lines') > 0
call interpreter%run_text("plot x smooth unique", iostat, iomsg)
test_passed(45) = test_passed(45) .and. iostat /= 0_I4P .and. index(iomsg, 'smooth applies to data files') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! readouts (a foresight extension): style, format, color, set readout; outside the autoscale (x from the curve only)
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 0.5', '2 0.25', '3 NaN'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("set readout bottom right horizontal noopaque size 20; plot '"//data_file//"' u 1:2 w l t 'r', "// &
                          "'' u 2 with readout format '%6.3f' title 'R' lc 'red'", iostat, iomsg)
test_passed(46) = iostat == 0_I4P
if (test_passed(46)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(46) = panel%series(2)%style%with == WITH_READOUT .and. panel%series(2)%format == '%6.3f' .and. &
                        panel%series(2)%style%color == 'red' .and. panel%readout_h == 'right' .and. &
                        panel%readout_v == 'bottom' .and. panel%readout_horizontal .and. .not. panel%readout_opaque &
                        .and. panel%readout_size == 20.0_R8P
      call panel%data_extent(xmin, xmax, ymin, ymax, found)
      test_passed(46) = test_passed(46) .and. xmin == 1.0_R8P .and. xmax == 2.0_R8P .and. ymin(1) == 0.25_R8P
   endassociate
endif
call interpreter%run_text('unset readout', iostat, iomsg)
test_passed(46) = test_passed(46) .and. iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%readout
! readout errors
call interpreter%run_text("plot '"//data_file//"' w l format '%5.2f'", iostat, iomsg)
test_passed(47) = iostat /= 0_I4P .and. index(iomsg, 'format applies to readouts and gauges only') > 0
call interpreter%run_text("plot '"//data_file//"' w readout lw 2", iostat, iomsg)
test_passed(47) = test_passed(47) .and. iostat /= 0_I4P .and. index(iomsg, 'a readout takes lc only') > 0
call interpreter%run_text("plot '"//data_file//"' w readout format '%.2e'", iostat, iomsg)
test_passed(47) = test_passed(47) .and. iostat /= 0_I4P .and. index(iomsg, 'needs a field width') > 0
call interpreter%run_text("set readout outside", iostat, iomsg)
test_passed(47) = test_passed(47) .and. iostat /= 0_I4P .and. index(iomsg, 'set readout: unsupported option') > 0
call interpreter%run_text("plot x w readout", iostat, iomsg)
test_passed(47) = test_passed(47) .and. iostat /= 0_I4P .and. index(iomsg, 'a function is drawn with lines') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! boxes: auto edges halfway to the neighbours, relative and absolute widths, a width column; base 0; fill styles
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 3 0.2', '2 5 0.2', '4 -2 0.2'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("set style fill solid 0.5 noborder; plot '"//data_file//"' w boxes, '' u 1:2:3 w boxes "// &
                          "fs empty border lc 'red'", iostat, iomsg)
test_passed(48) = iostat == 0_I4P
if (test_passed(48)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(48) = series(1)%style%with == WITH_BOXES .and. same(series(1)%xlow * 2.0_R8P, [1, 3, 6]) .and. &
                        same(series(1)%xhigh * 2.0_R8P, [3, 6, 10]) .and. same(series(1)%ylow, [0, 0, 0]) .and. &
                        series(1)%style%fill == FILL_SOLID .and. series(1)%style%density == 0.5_R8P .and. &
                        .not. series(1)%style%border .and. same(series(2)%xlow * 10.0_R8P, [9, 19, 39]) .and. &
                        series(2)%style%fill == FILL_EMPTY .and. series(2)%style%stroke_color() == 'red'
      ! the autoscale reaches the box edges and 0
      call interpreter%figure%panels(1)%data_extent(xmin, xmax, ymin, ymax, found)
      test_passed(48) = test_passed(48) .and. xmin == 0.5_R8P .and. xmax == 5.0_R8P .and. ymin(1) == -2.0_R8P
   endassociate
endif
call interpreter%run_text("set boxwidth 0.5 relative; plot '"//data_file//"' w boxes", iostat, iomsg)
test_passed(49) = iostat == 0_I4P
if (test_passed(49)) test_passed(49) = same(interpreter%figure%panels(1)%series(1)%xlow * 4.0_R8P, [3, 7, 14]) .and. &
                                       same(interpreter%figure%panels(1)%series(1)%xhigh * 4.0_R8P, [5, 10, 18])
call interpreter%run_text("set boxwidth 0.5; plot '"//data_file//"' w boxes; unset boxwidth", iostat, iomsg)
test_passed(49) = test_passed(49) .and. iostat == 0_I4P .and. &
                  same(interpreter%figure%panels(1)%series(1)%xlow * 4.0_R8P, [3, 7, 15])
! filledcurves: y=V baseline in the autoscale, a band, the closed default; always solid, no border
call interpreter%run_text("plot '"//data_file//"' w filledc y=10, '' u 1:2:3 w filledcurves, '' w filledcurves closed", &
                          iostat, iomsg)
test_passed(49) = test_passed(49) .and. iostat == 0_I4P
if (test_passed(49)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(49) = series(1)%style%with == WITH_FILLEDCURVES .and. same(series(1)%ylow, [10, 10, 10]) .and. &
                        same(series(2)%ylow * 10.0_R8P, [2, 2, 2]) .and. .not. allocated(series(3)%ylow) .and. &
                        series(3)%style%fill == FILL_SOLID .and. .not. series(3)%style%border
      call interpreter%figure%panels(1)%data_extent(xmin, xmax, ymin, ymax, found)
      test_passed(49) = test_passed(49) .and. ymax(1) == 10.0_R8P
   endassociate
endif
! fill errors
call interpreter%run_text("plot '"//data_file//"' w l fs solid", iostat, iomsg)
test_passed(50) = iostat /= 0_I4P .and. index(iomsg, 'the box styles and the panel charts only') > 0
call interpreter%run_text("set style fill pattern 2", iostat, iomsg)
test_passed(50) = test_passed(50) .and. iostat /= 0_I4P .and. index(iomsg, 'patterns are not supported') > 0
call interpreter%run_text("plot '"//data_file//"' w filledcurves above", iostat, iomsg)
test_passed(50) = test_passed(50) .and. iostat /= 0_I4P .and. index(iomsg, 'filledcurves above is not supported') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2:3:3 w boxes", iostat, iomsg)
test_passed(50) = test_passed(50) .and. iostat /= 0_I4P .and. index(iomsg, 'boxes needs using x:y or x:y:width') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2:3 w filledcurves y=0", iostat, iomsg)
test_passed(50) = test_passed(50) .and. iostat /= 0_I4P .and. index(iomsg, 'not both') > 0
call interpreter%run_text("set boxwidth wide", iostat, iomsg)
test_passed(50) = test_passed(50) .and. iostat /= 0_I4P .and. index(iomsg, 'set boxwidth: unsupported option') > 0
call interpreter%run_text("plot '"//data_file//"' w boxes fs solid 2", iostat, iomsg)
test_passed(50) = test_passed(50) .and. iostat /= 0_I4P .and. index(iomsg, 'density is between 0 and 1') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! histograms with xtic labels (same() reads -1 as NaN: values are shifted off it): clustered slots 1/(k+gap) centred on the rows 0, 1, 2; x one unit beyond, y to 0
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '"Xall GPU" 3 -2', 'B 5 1', 'C -2 4'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("plot '"//data_file//"' u 2:xtic(1) w hist, '' u 3 w histograms", iostat, iomsg)
test_passed(51) = iostat == 0_I4P
if (test_passed(51)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(51) = series(1)%style%with == WITH_HISTOGRAMS .and. trim(series(1)%xlabels(1)) == 'Xall GPU' .and. &
                        trim(series(1)%xlabels(3)) == 'C' .and. same(series(1)%x, [0, 1, 2]) .and. &
                        same(series(1)%xlow * 4.0_R8P + 4.0_R8P, [3, 7, 11]) .and. same(series(2)%xlow * 4.0_R8P, [0, 4, 8]) .and. &
                        same(series(2)%xhigh * 4.0_R8P, [1, 5, 9]) .and. .not. allocated(series(2)%xlabels)
      call interpreter%figure%panels(1)%data_extent(xmin, xmax, ymin, ymax, found)
      test_passed(51) = test_passed(51) .and. xmin == -1.0_R8P .and. xmax == 3.0_R8P .and. ymin(1) == -2.0_R8P
   endassociate
endif
! rowstacked: positive values up from 0, negative ones down, each row 1 wide; a gap on clusters
call interpreter%run_text("set style histogram rowstacked; plot '"//data_file//"' u 2:xtic(1) w hist, '' u 3 w hist", &
                          iostat, iomsg)
test_passed(52) = iostat == 0_I4P
if (test_passed(52)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(52) = same(series(2)%ylow, [0, 5, 0]) .and. same(series(2)%y, [-2, 6, 4]) .and. &
                        same(series(1)%y, [3, 5, -2]) .and. same(series(1)%xlow * 2.0_R8P + 2.0_R8P, [1, 3, 5])
   endassociate
endif
call interpreter%run_text("set style histogram clustered gap 1; plot '"//data_file//"' u 2 w hist, '' u 3 w hist", &
                          iostat, iomsg)
test_passed(52) = test_passed(52) .and. iostat == 0_I4P
if (test_passed(52)) test_passed(52) = same(interpreter%figure%panels(1)%series(2)%xhigh * 3.0_R8P, [1, 4, 7])
! histogram and label errors
call interpreter%run_text("plot '"//data_file//"' u 1:2 w hist", iostat, iomsg)
test_passed(53) = iostat /= 0_I4P .and. index(iomsg, 'histograms needs using Y or Y:xtic(N)') > 0
call interpreter%run_text("set style histogram columnstacked", iostat, iomsg)
test_passed(53) = test_passed(53) .and. iostat /= 0_I4P .and. index(iomsg, 'unsupported option "columnstacked"') > 0
call interpreter%run_text("plot '"//data_file//"' u 2:xtic(a) w hist", iostat, iomsg)
test_passed(53) = test_passed(53) .and. iostat /= 0_I4P .and. index(iomsg, 'xtic needs a column number') > 0
call interpreter%run_text("plot '"//data_file//"' u 2:ytic(1) w hist", iostat, iomsg)
test_passed(53) = test_passed(53) .and. iostat /= 0_I4P .and. index(iomsg, 'only xtic(N) labels are supported') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! themes and segmented fills (foresight extensions)
call interpreter%init(scratch)
call interpreter%run_text("set terminal svg theme vfd noglow; set style fill solid segments 12", iostat, iomsg)
test_passed(54) = iostat == 0_I4P
if (test_passed(54)) test_passed(54) = interpreter%figure%theme%name == 'vfd' .and. &
                                       .not. interpreter%figure%theme%glow .and. &
                                       interpreter%figure%panels(1)%fill_default%segments == 12_I4P
call interpreter%run_text("set terminal block theme lcd glow", iostat, iomsg)
test_passed(54) = test_passed(54) .and. iostat == 0_I4P .and. interpreter%figure%theme%name == 'lcd' .and. &
                  interpreter%figure%theme%glow
call interpreter%run_text("set terminal svg theme neon", iostat, iomsg)
test_passed(55) = iostat /= 0_I4P .and. index(iomsg, 'unknown theme "neon"') > 0
call interpreter%run_text("set style fill solid segments 2.5", iostat, iomsg)
test_passed(55) = test_passed(55) .and. iostat /= 0_I4P .and. index(iomsg, 'whole number of cells') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! images (same() reads -1 as NaN: edges shifted off it): x:y:z gathered on a regular grid (a missing point NaN), the pixel edges; a matrix file; palette, cbrange
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '0 0 1', '2 0 2', '4 0 3', '', '0 1 4', '2 1 5'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("set palette viridis maxcolors 5; set cbrange [0:10]; plot '"//data_file//"' u 1:2:3 w image", &
                          iostat, iomsg)
test_passed(56) = iostat == 0_I4P
if (test_passed(56)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(56) = size(panel%series(1)%grid, 1) == 3 .and. size(panel%series(1)%grid, 2) == 2 .and. &
                        same(panel%series(1)%x + 2.0_R8P, [1, 7]) .and. same(panel%series(1)%y * 2.0_R8P + 2.0_R8P, [1, 5]) .and. &
                        ieee_is_nan(panel%series(1)%grid(3, 2)) .and. panel%series(1)%grid(2, 2) == 5.0_R8P .and. &
                        panel%palette%maxcolors == 5_I4P .and. panel%cbaxis%max_fixed .and. &
                        panel%cbaxis%max_user == 10.0_R8P
   endassociate
endif
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 2 3', '4 5 6'
close(unit)
call interpreter%run_text("unset colorbox; plot '"//data_file//"' matrix w image", iostat, iomsg)
test_passed(57) = iostat == 0_I4P
if (test_passed(57)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(57) = .not. panel%colorbox .and. size(panel%series(1)%grid, 1) == 3 .and. &
                        panel%series(1)%grid(3, 2) == 6.0_R8P .and. same(panel%series(1)%x * 2.0_R8P + 2.0_R8P, [1, 7])
   endassociate
endif
! image errors
call interpreter%run_text("set palette cubehelix", iostat, iomsg)
test_passed(58) = iostat /= 0_I4P .and. index(iomsg, 'set palette: unsupported option "cubehelix"') > 0
call interpreter%run_text("plot '"//data_file//"' matrix w lines", iostat, iomsg)
test_passed(58) = test_passed(58) .and. iostat /= 0_I4P .and. index(iomsg, 'matrix data are plotted with image') > 0
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '0 0 1', '1 0 2', '3 0 3'
close(unit)
call interpreter%run_text("plot '"//data_file//"' u 1:2:3 w image", iostat, iomsg)
test_passed(58) = test_passed(58) .and. iostat /= 0_I4P .and. index(iomsg, 'not on a regular grid') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! circles: radius column widening the x autoscale, wedges; pie: one value per row, labels, donut
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') 'a 1 2 0.5 0 90', 'b 3 1 0.25 90 300'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("plot '"//data_file//"' u 2:3:4 w circles, '' u 2:3:4:5:6 w cir", iostat, iomsg)
test_passed(59) = iostat == 0_I4P
if (test_passed(59)) then
   associate(panel => interpreter%figure%panels(1))
      ! a local copy of the angles: gfortran 16 -fcheck=bounds misreads the bounds through the associate
      arcs = panel%series(2)%arcs
      test_passed(59) = panel%series(1)%style%with == WITH_CIRCLES .and. same(panel%series(1)%radius * 4.0_R8P, [2, 1]) &
                        .and. .not. allocated(panel%series(1)%arcs) .and. size(arcs, 1) == 2 .and. &
                        same(arcs(2, :), [90, 300])
      call panel%data_extent(xmin, xmax, ymin, ymax, found)
      test_passed(59) = test_passed(59) .and. xmin == 0.5_R8P .and. xmax == 3.25_R8P
   endassociate
endif
call interpreter%run_text("plot '"//data_file//"' u 4:xtic(1) w pie donut 0.5", iostat, iomsg)
test_passed(60) = iostat == 0_I4P
if (test_passed(60)) then
   associate(series => interpreter%figure%panels(1)%series(1))
      test_passed(60) = series%style%with == WITH_PIE .and. series%donut == 0.5_R8P .and. &
                        same(series%values * 4.0_R8P, [2, 1]) .and. trim(series%xlabels(2)) == 'b'
   endassociate
endif
! pie errors: negative values, not alone, a hole out of range
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 2', '-1 3'
close(unit)
call interpreter%run_text("plot '"//data_file//"' u 1 w pie", iostat, iomsg)
test_passed(61) = iostat /= 0_I4P .and. index(iomsg, 'a pie needs non-negative values') > 0
call interpreter%run_text("plot '"//data_file//"' u 2 w pie, '' u 2 w lines", iostat, iomsg)
test_passed(61) = test_passed(61) .and. iostat /= 0_I4P .and. index(iomsg, 'a pie, gauge, radar or rose is alone in its panel') > 0
call interpreter%run_text("plot '"//data_file//"' u 2 w pie donut 1.2", iostat, iomsg)
test_passed(61) = test_passed(61) .and. iostat /= 0_I4P .and. index(iomsg, 'from 0 to below 1') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! panel charts: gauges side by side (range, cells, format), a radar, a rose by radius
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') 'a 1 2', 'b 3 4', 'c 5 6'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("plot '"//data_file//"' u 2 w gauge range [0:10] segments 12 format '%4.1f' t 'A', "// &
                          "'' u 3 w gauge range [0:8] t 'B'", iostat, iomsg)
test_passed(62) = iostat == 0_I4P
if (test_passed(62)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(62) = panel%series(1)%style%with == WITH_GAUGE .and. same(panel%series(1)%scale, [0, 10]) .and. &
                        panel%series(1)%style%segments == 12_I4P .and. panel%series(1)%format == '%4.1f' .and. &
                        same(panel%series(2)%scale, [0, 8]) .and. panel%series(2)%style%segments == 0_I4P
   endassociate
endif
call interpreter%run_text("plot '"//data_file//"' u 2:xtic(1) w rose linear", iostat, iomsg)
test_passed(62) = test_passed(62) .and. iostat == 0_I4P
if (test_passed(62)) test_passed(62) = interpreter%figure%panels(1)%series(1)%style%with == WITH_ROSE .and. &
                                       interpreter%figure%panels(1)%series(1)%linear
call interpreter%run_text("plot '"//data_file//"' u 2:xtic(1) w radar, '' u 3 w radar", iostat, iomsg)
test_passed(62) = test_passed(62) .and. iostat == 0_I4P
! panel chart errors
call interpreter%run_text("plot '"//data_file//"' u 2 w gauge", iostat, iomsg)
test_passed(63) = iostat /= 0_I4P .and. index(iomsg, 'a gauge needs its scale') > 0
call interpreter%run_text("plot '"//data_file//"' u 2 w gauge range [0:1], '' u 3 w radar", iostat, iomsg)
test_passed(63) = test_passed(63) .and. iostat /= 0_I4P .and. index(iomsg, 'is alone in its panel') > 0
call interpreter%run_text("plot '"//data_file//"' u (-$2) w rose", iostat, iomsg)
test_passed(63) = test_passed(63) .and. iostat /= 0_I4P .and. index(iomsg, 'a rose needs non-negative values') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! polar: the settings of the round idiom, with abbreviations
call interpreter%init(scratch)
call interpreter%run_text("set pol; set an d; set theta t cw; set rr [1:*]; set tr [0:180]; set grid pol 45"// &
                          new_line('a')//"unset bor; set bor polar; set size sq; set tti 0,30 format '%g deg'"// &
                          new_line('a')//"set rti 0.5; unset rax", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(64) = iostat == 0_I4P
if (test_passed(64)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(64) = panel%polar .and. panel%degrees .and. panel%theta_origin == 90.0_R8P .and. &
                        panel%theta_clockwise .and. panel%raxis%min_fixed .and. panel%raxis%min_user == 1.0_R8P .and. &
                        .not. panel%raxis%max_fixed .and. panel%taxis%max_user == 180.0_R8P .and. panel%grid .and. &
                        panel%grid_polar == 45.0_R8P .and. panel%border == 0_I4P .and. panel%border_polar .and. &
                        panel%ratio == 1.0_R8P .and. panel%ttics%format == '%g deg' .and. panel%raxis%tics%step == '0.5' &
                        .and. .not. panel%raxis_on
   endassociate
endif
call interpreter%run_text("set angles radians; set grid polar 0.5; set border 3 polar; set size ratio 0.5 0.8,0.9"// &
                          new_line('a')//"unset theta; unset polar", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(64) = test_passed(64) .and. iostat == 0_I4P
if (test_passed(64)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(64) = abs(panel%grid_polar - 28.64788975654116_R8P) < 1.0e-9_R8P .and. panel%border == 3_I4P .and. &
                        panel%border_polar .and. panel%ratio == 0.5_R8P .and. same(panel%size * 10.0_R8P, [8, 9]) .and. &
                        panel%theta_origin == 0.0_R8P .and. .not. panel%theta_clockwise .and. .not. panel%polar
   endassociate
endif
! polar plots: data theta:r as given (projected at rendering only), a function of t over trange in degrees
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '0 1', '90 2', '180 3'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("set polar; set angles degrees; set trange [0:90]; set samples 3"//new_line('a')// &
                          "plot '"//data_file//"' u 1:2 w lp, 2*sin(t) w l", iostat, iomsg)
test_passed(65) = iostat == 0_I4P
if (test_passed(65)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(65) = same(panel%series(1)%x, [0, 90, 180]) .and. same(panel%series(1)%y, [1, 2, 3]) .and. &
                        same(panel%series(2)%x, [0, 45, 90]) .and. abs(panel%series(2)%y(3) - 2.0_R8P) < 1.0e-12_R8P &
                        .and. abs(panel%series(2)%y(2) - sqrt(2.0_R8P)) < 1.0e-12_R8P
   endassociate
endif
! polar errors: a style without polar form, the second axes, a band, a bad rrange, ttics, size ratio, border, angles
call interpreter%run_text("plot '"//data_file//"' u 1:2 w boxes", iostat, iomsg)
test_passed(66) = iostat /= 0_I4P .and. index(iomsg, 'a polar panel takes lines, points') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2 axes x1y2", iostat, iomsg)
test_passed(66) = test_passed(66) .and. iostat /= 0_I4P .and. index(iomsg, 'a polar panel takes') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2:(2*$2) w filledcurves", iostat, iomsg)
test_passed(66) = test_passed(66) .and. iostat /= 0_I4P .and. index(iomsg, 'a polar panel takes') > 0
call interpreter%run_text("set rrange [3:1]", iostat, iomsg)
test_passed(66) = test_passed(66) .and. iostat /= 0_I4P .and. index(iomsg, 'max must exceed min') > 0
call interpreter%run_text("set ttics 0,-30", iostat, iomsg)
test_passed(66) = test_passed(66) .and. iostat /= 0_I4P .and. index(iomsg, 'set ttics: supported forms') > 0
call interpreter%run_text("set size ratio -1", iostat, iomsg)
test_passed(66) = test_passed(66) .and. iostat /= 0_I4P .and. index(iomsg, 'negative ratios are not supported') > 0
call interpreter%run_text("set border 2.5", iostat, iomsg)
test_passed(66) = test_passed(66) .and. iostat /= 0_I4P .and. index(iomsg, 'the mask is an integer') > 0
call interpreter%run_text("set angles gradians", iostat, iomsg)
test_passed(66) = test_passed(66) .and. iostat /= 0_I4P .and. index(iomsg, 'degrees or radians expected') > 0
call interpreter%run_text("set grid polar 400", iostat, iomsg)
test_passed(66) = test_passed(66) .and. iostat /= 0_I4P .and. index(iomsg, 'below a full turn') > 0
call interpreter%run_text("set logscale y; plot '"//data_file//"' u 1:2", iostat, iomsg)
test_passed(66) = test_passed(66) .and. iostat /= 0_I4P .and. index(iomsg, 'linear x and y axes') > 0

! the lines family, with gnuplot's abbreviations: his is histeps, hist histograms
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 2 0.5', '2 3 0.25', '4 5 0.5'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("plot '"//data_file//"' w i, '' w st, '' w fs, '' w his, '' w d, '' u 1:2:3 w yerrorl, "// &
                          "'' u 1:2:3 w xerrorl, '' u 1:2:3:3 w xyerrorl, x w steps", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(67) = iostat == 0_I4P
if (test_passed(67)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(67) = all(panel%series%style%with == [WITH_IMPULSES, WITH_STEPS, WITH_FSTEPS, WITH_HISTEPS, &
                                                         WITH_DOTS, WITH_YERRORLINES, WITH_XERRORLINES, &
                                                         WITH_XYERRORLINES, WITH_STEPS]) .and. &
                        same(panel%series(1)%ylow, [0, 0, 0]) .and. same(panel%series(4)%xlow * 2.0_R8P, [1, 3, 6]) &
                        .and. same(panel%series(4)%xhigh * 2.0_R8P, [3, 6, 10]) .and. panel%series(5)%style%pointtype == 0 &
                        .and. same(panel%series(6)%ylow * 4.0_R8P, [6, 11, 18]) .and. &
                        same(panel%series(8)%xhigh * 4.0_R8P, [6, 9, 18]) .and. same(panel%series(8)%yhigh * 4.0_R8P, [10, 13, 22])
   endassociate
endif
call interpreter%run_text("plot '"//data_file//"' u 2 w hist", iostat, iomsg)
test_passed(67) = test_passed(67) .and. iostat == 0_I4P
if (test_passed(67)) test_passed(67) = interpreter%figure%panels(1)%series(1)%style%with == WITH_HISTOGRAMS
call interpreter%run_text("plot '"//data_file//"' u 1:2 w yerrorl", iostat, iomsg)
test_passed(68) = iostat /= 0_I4P .and. index(iomsg, 'yerrorlines needs using x:y:delta') > 0
call interpreter%run_text("plot x w xyerrorlines", iostat, iomsg)
test_passed(68) = test_passed(68) .and. iostat /= 0_I4P .and. index(iomsg, 'impulses, steps, fsteps, histeps or dots') > 0
call interpreter%run_text("plot x w hi", iostat, iomsg)
test_passed(68) = test_passed(68) .and. iostat /= 0_I4P .and. index(iomsg, 'unsupported style "hi"') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! the box styles: column layouts, whiskerbars anywhere in the item, boxplot quartiles per factor level
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 2 1 3 4 0.5 p', '2 3 2 5 6 0 p', '3 4 1 5 3 0.5 p', '4 5 2 7 8 0.5 q', '5 6 3 8 7 0.5 q', &
                   '6 7 4 9 9 0.5 q', '7 8 5 9 9 0.5 q', '8 9 1 9 9 0.5 q', '9 10 1 9 9 0.5 p', '10 30 1 9 9 0.5 p'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("set style boxplot sorted pt 6 range 1.5"//new_line('a')// &
                          "plot '"//data_file//"' u 1:2:3 w boxer, '' u 1:2:3:4:6 w boxerrorbars, '' u 1:2:3:3 w boxx, "// &
                          "'' u 1:2:3:4:5 w can t 'c' whiskerbars 0.5, '' u 1:2:3:4:5 w fin, "// &
                          "'' u (1):2:(0.4):7 w boxplot", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(69) = iostat == 0_I4P
if (test_passed(69)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(69) = all(panel%series%style%with == [WITH_BOXERRORBARS, WITH_BOXERRORBARS, WITH_BOXXYERROR, &
                                                         WITH_CANDLESTICKS, WITH_FINANCEBARS, WITH_BOXPLOT]) .and. &
                        same(panel%series(1)%ylow(1:2), [0, 0]) .and. same(panel%series(2)%xhigh(1:2) * 4.0_R8P, [5, 10]) &
                        .and. same(panel%series(3)%xlow(1:2), [0, 0]) .and. panel%series(4)%whiskerbars == 0.5_R8P .and. &
                        panel%boxplot%sorted .and. panel%boxplot%pointtype == 6_I4P
      ! local copies of the bounds: gfortran 16 -fcheck=bounds misreads their sections through the associate
      arcs = panel%series(1)%bounds
      test_passed(69) = test_passed(69) .and. same(arcs(1, 1:2), [1, 1])
      arcs = panel%series(2)%bounds
      test_passed(69) = test_passed(69) .and. same(arcs(2, 1:2), [3, 5])
      arcs = panel%series(4)%bounds
      test_passed(69) = test_passed(69) .and. same(arcs(2, 1:2), [4, 6])
      ! levels p (2 3 4 10 30) and q (5 6 7 8 9), sorted: p at x = 1, q at x = 2
      test_passed(69) = test_passed(69) .and. same(panel%series(6)%x, [1, 2]) .and. same(panel%series(6)%y, [4, 7]) .and. &
                        same(panel%series(6)%yhigh, [10, 9]) .and. &
                        trim(panel%series(6)%xlabels(1)) == 'p' .and. trim(panel%series(6)%xlabels(2)) == 'q'
      arcs = panel%series(6)%bounds
      test_passed(69) = test_passed(69) .and. same(arcs(1, :), [3, 6]) .and. same(arcs(2, :), [10, 8])
      arcs = panel%series(6)%outliers
      test_passed(69) = test_passed(69) .and. same(arcs(2, :), [30])
   endassociate
endif
call interpreter%run_text("plot '"//data_file//"' u 1:2:3:4 w candlesticks", iostat, iomsg)
test_passed(70) = iostat /= 0_I4P .and. index(iomsg, 'candlesticks needs using x:open:low:high:close') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2:3:(2*$4) w boxplot", iostat, iomsg)
test_passed(70) = test_passed(70) .and. iostat /= 0_I4P .and. index(iomsg, 'must be a column number') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2 w boxes whiskerbars", iostat, iomsg)
test_passed(70) = test_passed(70) .and. iostat /= 0_I4P .and. index(iomsg, 'whiskerbars applies to candlesticks') > 0
call interpreter%run_text("set style boxplot labels x2", iostat, iomsg)
test_passed(70) = test_passed(70) .and. iostat /= 0_I4P .and. index(iomsg, 'labels off, auto or x') > 0
call interpreter%run_text("set style boxplot fraction 2", iostat, iomsg)
test_passed(70) = test_passed(70) .and. iostat /= 0_I4P .and. index(iomsg, 'above 0 and up to 1') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! the geometric styles: vectors and arrows with head words, ellipses, polygons by blocks, labels, sectors
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 2 1 3 0.5 alpha', '2 3 2 -1 2 beta', '', '4 1 1 1 -1 "c d"'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("set angles degrees"//new_line('a')// &
                          "plot '"//data_file//"' w vec heads filled, '' u 1:2:3:4 w arrows nohead, "// &
                          "'' u 1:2:5:3:(30) w ell, '' w poly fs solid 0.3, '' u 1:2:6 w labels right rotate by 45 "// &
                          "offset 1,2 point pt 7 tc 'red', '' u 1:2:3:5 w sec", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(71) = iostat == 0_I4P
if (test_passed(71)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(71) = all(panel%series%style%with == [WITH_VECTORS, WITH_ARROWS, WITH_ELLIPSES, WITH_POLYGONS, &
                                                         WITH_LABELS, WITH_SECTORS]) .and. &
                        panel%series(1)%head == 3_I4P .and. panel%series(1)%head_filled .and. &
                        panel%series(2)%head == 0_I4P .and. &
                        trim(panel%series(5)%texts(1)) == 'alpha' .and. trim(panel%series(5)%texts(4)) == 'c d' .and. &
                        panel%series(5)%text_anchor == 'end' .and. panel%series(5)%text_rotate == 45.0_R8P .and. &
                        panel%series(5)%text_point .and. panel%series(5)%text_color == 'red' .and. &
                        panel%series(5)%style%pointtype == 7_I4P .and. same(panel%series(5)%text_offset, [1, 2])
      arcs = panel%series(1)%tips
      test_passed(71) = test_passed(71) .and. same(arcs(1, :), [2, 4, -1, 5]) .and. same(arcs(2, :), [5, 2, -1, 2])
      arcs = panel%series(3)%shape
      ! the third ellipse has a negative diameter: the default size (NaN)
      test_passed(71) = test_passed(71) .and. same(arcs(1, 1:2) * 2.0_R8P, [1, 4]) .and. same(arcs(2, 1:2), [1, 2]) &
                        .and. same(arcs(3, 1:2), [30, 30])
      ! a sector of 1 degree: an arc of 2 vertices out, 2 back, a NaN
      test_passed(71) = test_passed(71) .and. size(panel%series(6)%x) > 6
   endassociate
endif
call interpreter%run_text("plot '"//data_file//"' u 1:2:3 w vectors", iostat, iomsg)
test_passed(72) = iostat /= 0_I4P .and. index(iomsg, 'vectors needs using x:y:xdelta:ydelta') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2:($3) w labels", iostat, iomsg)
test_passed(72) = test_passed(72) .and. iostat /= 0_I4P .and. index(iomsg, 'must be a column number') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2:3 w ellipses units xx", iostat, iomsg)
test_passed(72) = test_passed(72) .and. iostat /= 0_I4P .and. index(iomsg, 'units xy only') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2:3 w sectors", iostat, iomsg)
test_passed(72) = test_passed(72) .and. iostat /= 0_I4P .and. index(iomsg, 'sectors needs using') > 0
call interpreter%run_text("unset xrange; unset yrange; unset y2range", iostat, iomsg)
test_passed(72) = test_passed(72) .and. iostat == 0_I4P
open(newunit=unit, file=scratch)
close(unit, status='delete')
open(newunit=unit, file=scratch)
close(unit, status='delete')

open(newunit=unit, file=data_file)
close(unit, status='delete')
open(newunit=unit, file=csv_file)
close(unit, status='delete')
if (all(test_passed)) then
   open(newunit=unit, file=output)
   close(unit, status='delete')
   open(newunit=unit, file=options)
   close(unit, status='delete')
   open(newunit=unit, file=y2)
   close(unit, status='delete')
endif
write(output_unit, '(A,72L2)') 'foresight_script checks:', test_passed
do i = 1, size(test_passed)
   if (.not. test_passed(i)) write(error_unit, '(A,I0)') 'failed check ', i
enddo
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1

contains
   pure function same(values, expected) result(equal)
   !< Whether `values` equal the integers `expected` to rounding, -1 standing for NaN.
   real(R8P),    intent(in) :: values(:)   !< Values.
   integer,      intent(in) :: expected(:) !< Expected values, -1 for NaN.
   logical                  :: equal       !< Equal.
   integer                  :: k           !< Counter.

   equal = size(values) == size(expected)
   if (.not. equal) return
   do k = 1, size(values)
      if (expected(k) == -1) then
         equal = equal .and. ieee_is_nan(values(k))
      elseif (ieee_is_nan(values(k))) then
         equal = .false.
      else
         equal = equal .and. abs(values(k) - real(expected(k), R8P)) <= 1e-12_R8P * max(1, abs(expected(k)))
      endif
   enddo
   endfunction same

   function matches_golden(output, golden) result(passed)
   !< Compare the rendered file with the reference, or rewrite the reference in update mode.
   character(len=*), intent(in)  :: output   !< Rendered file.
   character(len=*), intent(in)  :: golden   !< Reference file.
   logical                       :: passed   !< Rendering matches the reference.
   character(len=:), allocatable :: produced !< Rendered content.
   logical                       :: exists   !< Reference exists.
   integer(I4P)                  :: u        !< File unit.

   produced = read_text(output)
   call get_environment_variable('FORESIGHT_UPDATE_GOLDEN', update_flag)
   if (trim(update_flag) == '1') then
      open(newunit=u, file=golden, access='stream', form='unformatted', action='write', status='replace')
      write(u) produced
      close(u)
      write(output_unit, '(A)') 'updated '//golden
      passed = .true.
      return
   endif
   inquire(file=golden, exist=exists)
   passed = .false.
   if (exists) passed = produced == read_text(golden)
   if (.not. passed) write(error_unit, '(A)') output//' differs from '//golden//' (FORESIGHT_UPDATE_GOLDEN=1 rewrites it)'
   endfunction matches_golden

   function read_text(file) result(text)
   !< Whole content of `file`.
   character(len=*), intent(in)  :: file  !< File name.
   character(len=:), allocatable :: text  !< Content.
   integer(I4P)                  :: u     !< File unit.
   integer(I4P)                  :: bytes !< File size [bytes].

   open(newunit=u, file=file, access='stream', form='unformatted', action='read', status='old')
   inquire(unit=u, size=bytes)
   allocate(character(len=bytes) :: text)
   read(u) text
   close(u)
   endfunction read_text
endprogram foresight_script_test
