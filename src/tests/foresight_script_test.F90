!< foresight_script test: gnuplot scripts rendered byte-exact, `using` expressions, functions, CSV data, the second y
!< axis, and unsupported constructs reported as errors.
program foresight_script_test
!< foresight_script test: gnuplot scripts rendered byte-exact, `using` expressions, functions, CSV data, the second y
!< axis, and unsupported constructs reported as errors.
!<
!< Run from the repository root; `FORESIGHT_UPDATE_GOLDEN=1` rewrites the reference file.
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan
use, intrinsic :: iso_fortran_env, only : error_unit, output_unit
use foresight, only : fit, fit_result, I4P, R8P, script_object
use foresight_ticks, only : MINOR_AUTO, TICS_NONE
use foresight_style, only : FILL_EMPTY, FILL_PATTERN, FILL_SOLID, WITH_IMAGE, &
                            WITH_BOXES, WITH_CIRCLES, WITH_PIE, WITH_FILLEDCURVES, WITH_GAUGE, &
                            WITH_ROSE, WITH_IMPULSES, WITH_STEPS, WITH_FSTEPS, WITH_HISTEPS, WITH_DOTS, WITH_YERRORLINES, &
                            WITH_XERRORLINES, WITH_XYERRORLINES, WITH_BOXERRORBARS, WITH_BOXXYERROR, WITH_CANDLESTICKS, &
                            WITH_FINANCEBARS, WITH_BOXPLOT, WITH_VECTORS, WITH_ARROWS, WITH_ELLIPSES, WITH_POLYGONS, &
                            WITH_LABELS, WITH_SECTORS, WITH_PARALLELAXES, WITH_SPIDERPLOT, &
                            WITH_HISTOGRAMS, WITH_LINES, &
                            WITH_LINESPOINTS, &
                            WITH_POINTS, WITH_READOUT

implicit none
character(len=*), parameter   :: data_file = 'foresight_script_test.dat'   !< Test data file.
character(len=*), parameter   :: output    = 'foresight_script_test.svg'   !< Rendered file.
character(len=*), parameter   :: golden    = 'src/tests/goldens/script.svg' !< Reference file.
character(len=*), parameter   :: scratch   = 'foresight_script_test_expressions.svg' !< Expression plots.
character(len=*), parameter   :: options   = 'foresight_script_test_options.svg'     !< Options plot.
character(len=*), parameter   :: options_golden = 'src/tests/goldens/options.svg'    !< Options reference.
character(len=*), parameter   :: csv_file  = 'foresight_script_test.csv'   !< CSV data file.
character(len=*), parameter   :: y2        = 'foresight_script_test_y2.svg'          !< Second y axis plot.
character(len=*), parameter   :: y2_golden = 'src/tests/goldens/y2.svg'                !< Second y axis reference.
type(script_object)           :: interpreter                               !< Interpreter.
character(len=:), allocatable :: iomsg                                     !< Error message.
character(len=:), allocatable :: script                                    !< Script text.
character(len=8)              :: update_flag                               !< FORESIGHT_UPDATE_GOLDEN value.
integer(I4P)                  :: iostat                                    !< Status.
integer(I4P)                  :: unit                                      !< File unit.
integer(I4P)                  :: i                                         !< Counter.
logical                       :: test_passed(97)                           !< Per-check outcome.
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
call interpreter%run_text('plot [0:1] [0:1] [0:1] sin(x)', iostat, iomsg)
test_passed(7) = iostat /= 0_I4P .and. index(iomsg, 'at most two inline ranges') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:$2", iostat, iomsg)
test_passed(8) = iostat /= 0_I4P .and. index(iomsg, 'nor a parenthesized expression') > 0
call interpreter%run_text('set xrange [a:1]', iostat, iomsg)
test_passed(9) = iostat /= 0_I4P .and. index(iomsg, 'set xrange: undefined variable: a') > 0

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
call interpreter%run_text('set key offset 1,1', iostat, iomsg)
test_passed(18) = iostat /= 0_I4P .and. index(iomsg, 'set key: unsupported option "offset"') > 0
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
      ! the header row and the empty cell of row 12 hold no number: skipped, the line not broken (gnuplot)
      test_passed(27) = size(series%x) == 29 .and. series%x(1) == 1.0_R8P .and. series%x(12) == 13.0_R8P .and. &
                        .not. any(ieee_is_nan(series%y)) .and. &
                        abs(series%y(1) - 0.5_R8P - 0.3_R8P * sin(0.25_R8P)) < 1.0e-6_R8P
   endassociate
endif
call interpreter%run_text('set datafile separator "\t"', iostat, iomsg)
test_passed(28) = iostat == 0_I4P .and. interpreter%separator == achar(9)
call interpreter%run_text('unset datafile', iostat, iomsg)
test_passed(29) = iostat == 0_I4P .and. interpreter%separator == ''
call interpreter%run_text('set datafile missing "?"', iostat, iomsg)
test_passed(30) = iostat == 0_I4P .and. interpreter%missing == '?'
call interpreter%run_text('set datafile fortran', iostat, iomsg)
test_passed(30) = test_passed(30) .and. iostat /= 0_I4P .and. index(iomsg, 'set datafile: unsupported option "fortran"') > 0
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

! axes names: y and y2 are distinct, x2 is the second x axis
call interpreter%init('x.html')
call interpreter%run_text("set logscale xy2; set format y2 '%.1f'", iostat, iomsg)
associate(panel => interpreter%figure%panels(1))
   test_passed(33) = iostat == 0_I4P .and. panel%xaxis%log .and. .not. panel%yaxis%log .and. panel%y2axis%log .and. &
                     panel%y2axis%tics%format == '%.1f' .and. .not. panel%yaxis%tics%has_format()
endassociate
call interpreter%run_text("set logscale x2; set format x2 '%.2f'", iostat, iomsg)
test_passed(34) = iostat == 0_I4P .and. interpreter%figure%panels(1)%x2axis%log .and. &
                  interpreter%figure%panels(1)%x2axis%tics%format == '%.2f' .and. .not. interpreter%figure%panels(1)%yaxis%log
call interpreter%run_text('set logscale z', iostat, iomsg)
test_passed(34) = test_passed(34) .and. iostat /= 0_I4P .and. index(iomsg, 'axes among x, y, y2, cb, x2 expected') > 0
call interpreter%run_text("unset logscale; set output '"//scratch//"'; plot sin(x) axes x2y1", iostat, iomsg)
test_passed(35) = iostat == 0_I4P .and. interpreter%figure%panels(1)%series(1)%x2 .and. &
                  .not. interpreter%figure%panels(1)%series(1)%y2
call interpreter%run_text("plot '"//data_file//"' axes x3y1", iostat, iomsg)
test_passed(35) = test_passed(35) .and. iostat /= 0_I4P .and. &
                  index(iomsg, 'axes x1y1, x1y2, x2y1 or x2y2 expected, found "x3y1"') > 0

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
test_passed(37) = iostat /= 0_I4P .and. index(iomsg, 'set xrange: number out of range') > 0

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
                        size(series(4)%y) == 3 .and. all(series(4)%y == [5, 6, 7])
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
call interpreter%run_text("plot '"//data_file//"' smooth unwrap", iostat, iomsg)
test_passed(45) = iostat /= 0_I4P .and. index(iomsg, 'unsupported smooth "unwrap"') > 0
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
call interpreter%run_text("set style fill pattern 2.5", iostat, iomsg)
test_passed(50) = test_passed(50) .and. iostat /= 0_I4P .and. index(iomsg, 'the pattern is a whole number') > 0
call interpreter%run_text("plot '"//data_file//"' w filledcurves above", iostat, iomsg)
test_passed(50) = test_passed(50) .and. iostat /= 0_I4P .and. index(iomsg, 'above and below need y=V or a band') > 0
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

! histograms with xtic labels (same() reads -1 as NaN: values are shifted off it): clustered slots 1/(k+gap) centred
! on the rows 0, 1, 2; x one unit beyond, y to 0
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

! images (same() reads -1 as NaN: edges shifted off it): x:y:z gathered on a regular grid (a missing point NaN), the
! pixel edges; a matrix file; palette, cbrange
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
call interpreter%run_text("set palette functions", iostat, iomsg)
test_passed(58) = iostat /= 0_I4P .and. index(iomsg, 'set palette: unsupported option "functions"') > 0
call interpreter%run_text("set palette cubehelix start 0 cycles 1 saturation 2 negative", iostat, iomsg)
associate(palette => interpreter%figure%panels(interpreter%figure%current)%palette)
   test_passed(58) = test_passed(58) .and. iostat == 0_I4P .and. palette%negative .and. &
                     all(palette%cubehelix == [0.0_R8P, 1.0_R8P, 2.0_R8P])
endassociate
call interpreter%run_text("set palette cubehelix saturation x", iostat, iomsg)
test_passed(58) = test_passed(58) .and. iostat /= 0_I4P .and. index(iomsg, 'cubehelix saturation x (a number is expected)') > 0
call interpreter%run_text("set palette batlw", iostat, iomsg)
test_passed(58) = test_passed(58) .and. iostat /= 0_I4P .and. index(iomsg, 'set palette: unsupported option "batlw"') > 0
! a named palette (foresight extension), any case, with gnuplot's words
call interpreter%run_text("set palette Vik negative maxcolors 5", iostat, iomsg)
associate(palette => interpreter%figure%panels(interpreter%figure%current)%palette)
   test_passed(58) = test_passed(58) .and. iostat == 0_I4P .and. palette%table > 0_I4P .and. palette%negative .and. &
                     palette%maxcolors == 5_I4P .and. all(palette%rgb(0.0_R8P) == [89, 0, 8])
endassociate
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
test_passed(61) = test_passed(61) .and. iostat /= 0_I4P .and. index(iomsg, 'parallel axis or spider plot is alone in its panel') > 0
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

! fills: the default pattern cycling, an item's own pattern, filledcurves options, rgb images over rgbmax
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '0 0 1 0 0 1', '1 0 0 1 0 0.5', '0 1 0 0 1 1', '1 1 1 1 0 0'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("set style fill pattern 2"//new_line('a')// &
                          "plot '"//data_file//"' w boxes, '' w boxes, '' w boxes fs pattern 6, "// &
                          "'' w filledcurves x2, '' w filledc below y1=0.5, '' u 1:2:3 w filledcurves above, "// &
                          "'' w filledcurves xy=0.5,0.5", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(73) = iostat == 0_I4P
if (test_passed(73)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(73) = panel%series(1)%style%fill == FILL_PATTERN .and. panel%series(1)%style%pattern == 2_I4P .and. &
                        panel%series(2)%style%pattern == 3_I4P .and. panel%series(3)%style%pattern == 6_I4P .and. &
                        panel%series(4)%curve_to == 2_I4P .and. panel%series(5)%curve_side == -1_I4P .and. &
                        same(panel%series(5)%ylow * 2.0_R8P, [1, 1, 1, 1]) .and. panel%series(6)%curve_side == 1_I4P &
                        .and. panel%series(7)%curve_to == 3_I4P .and. same(panel%series(7)%curve_point * 2.0_R8P, [1, 1])
   endassociate
endif
call interpreter%run_text("set rgbmax 1"//new_line('a')//"plot '"//data_file//"' u 1:2:3:4:5:6 w rgba", iostat, iomsg)
test_passed(73) = test_passed(73) .and. iostat == 0_I4P
if (test_passed(73)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(73) = panel%series(1)%style%with == WITH_IMAGE .and. same((panel%series(1)%x + 1.0_R8P) * 2.0_R8P, [1, 5])
      arcs = panel%series(1)%channels(:, :, 1)
      ! pixel (0,0): 255, 0, 0, 255; pixel (1,0): 0, 255, 0, 128 (alpha 0.5 of rgbmax 1)
      test_passed(73) = test_passed(73) .and. same(arcs(:, 1), [255, 0, 0, 255]) .and. same(arcs(1:3, 2), [0, 255, 0]) &
                        .and. abs(arcs(4, 2) - 127.5_R8P) < 1.0e-9_R8P
   endassociate
endif
call interpreter%run_text("plot '"//data_file//"' u 1:2:3:4 w rgbimage", iostat, iomsg)
test_passed(74) = iostat /= 0_I4P .and. index(iomsg, 'rgbimage needs using x:y:r:g:b') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2:3 w filledcurves x1 above", iostat, iomsg)
test_passed(74) = test_passed(74) .and. iostat /= 0_I4P .and. index(iomsg, 'not with y=V nor a band') > 0
call interpreter%run_text("plot '"//data_file//"' w filledcurves r=1", iostat, iomsg)
test_passed(74) = test_passed(74) .and. iostat /= 0_I4P .and. index(iomsg, 'filledcurves r=1 is not supported') > 0
call interpreter%run_text("set rgbmax 0", iostat, iomsg)
test_passed(74) = test_passed(74) .and. iostat /= 0_I4P .and. index(iomsg, 'set rgbmax: a positive number') > 0
open(newunit=unit, file=scratch)
close(unit, status='delete')

! axis-based plots: parallel axes (at, paxis ranges and tics), a spider plot (its mode, style, web, key(N) row names)
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') 'George 15 75 20', 'Harriet 40 40 40', 'Ivan 70 20 85'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("set paxis 2 range [0:100]; set paxis 2 tics 25; set paxis 3 label 'third'"//new_line('a')// &
                          "plot '"//data_file//"' u 2 w parallel t 'A', '' u 3 w parallelaxes at 4 t 'B'", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(75) = iostat == 0_I4P
if (test_passed(75)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(75) = all(panel%series%style%with == [WITH_PARALLELAXES, WITH_PARALLELAXES]) .and. &
                        same(panel%series(1)%y, [15, 40, 70]) .and. .not. panel%series(1)%at_set .and. &
                        panel%series(2)%at_set .and. panel%series(2)%at == 4.0_R8P .and. size(panel%paxes) == 3 .and. &
                        panel%paxes(2)%axis%max_fixed .and. panel%paxes(2)%axis%max_user == 100.0_R8P .and. &
                        panel%paxes(2)%axis%tics%step == '25' .and. panel%paxes(3)%label == 'third' .and. &
                        panel%paxes(1)%axis%tics%mode == TICS_NONE
   endassociate
endif
call interpreter%run_text("set spi; set style spider fs solid 0.3 border lw 2 pt 7; set grid spider"//new_line('a')// &
                          "plot '"//data_file//"' u 2:key(1) t 'A', '' u 3 t 'B', '' u 4 t 'C'"//new_line('a')// &
                          "unset paxis 2 tics", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(75) = test_passed(75) .and. iostat == 0_I4P
if (test_passed(75)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(75) = panel%spiderplot .and. panel%grid_spider .and. panel%spider_style%fill == FILL_SOLID .and. &
                        panel%spider_style%density == 0.3_R8P .and. panel%spider_style%linewidth == 2.0_R8P .and. &
                        panel%spider_style%pointtype == 7_I4P .and. &
                        all(panel%series%style%with == [WITH_SPIDERPLOT, WITH_SPIDERPLOT, WITH_SPIDERPLOT]) .and. &
                        trim(panel%series(1)%texts(2)) == 'Harriet' .and. panel%paxes(2)%axis%tics%mode == TICS_NONE
   endassociate
endif
call interpreter%run_text("unset spiderplot; plot '"//data_file//"' u 2:key(1) w lines", iostat, iomsg)
test_passed(76) = iostat /= 0_I4P .and. index(iomsg, 'key(N) names the rows of a spider plot') > 0
call interpreter%run_text("plot '"//data_file//"' u 2 w parallelaxes, '' u 3 w lines", iostat, iomsg)
test_passed(76) = test_passed(76) .and. iostat /= 0_I4P .and. index(iomsg, 'is alone in its panel') > 0
call interpreter%run_text("set paxis 0 tics", iostat, iomsg)
test_passed(76) = test_passed(76) .and. iostat /= 0_I4P .and. index(iomsg, 'the axis number is 1 to 1000') > 0
call interpreter%run_text("set style spiderplot lw", iostat, iomsg)
test_passed(76) = test_passed(76) .and. iostat /= 0_I4P .and. index(iomsg, 'lw needs a number') > 0
call interpreter%run_text("plot '"//data_file//"' u 2 w lines at 3", iostat, iomsg)
test_passed(76) = test_passed(76) .and. iostat /= 0_I4P
! set palette file, against gnuplot 6.0 (test palette): gray:r:g:b rescaled, r:g:b evenly spaced, using, every, the
! words before the file kept, clipped components; bad data, decreasing grays, no file, two columns
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '# gray r g b', '0 0 0 1', '1 1 1 1', '3 1 0 0'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("set palette negative; set palette file '"//data_file//"'", iostat, iomsg)
associate(palette => interpreter%figure%panels(interpreter%figure%current)%palette)
   test_passed(77) = iostat == 0_I4P .and. palette%negative .and. all(palette%rgb(1.0_R8P) == [0, 0, 255]) .and. &
                     all(palette%rgb(0.75_R8P) == [191, 191, 255]) .and. all(palette%rgb(0.25_R8P) == [255, 96, 96])
endassociate
call interpreter%run_text("set palette positive; set palette file '"//data_file//"' u ($1*2):4:3:2 maxcolors 0", &
                          iostat, iomsg)
associate(palette => interpreter%figure%panels(interpreter%figure%current)%palette)
   test_passed(77) = test_passed(77) .and. iostat == 0_I4P .and. all(palette%rgb(0.0_R8P) == [255, 0, 0]) .and. &
                     all(palette%rgb(1.0_R8P) == [0, 0, 255])
endassociate
call interpreter%run_text("set palette file '"//data_file//"' every ::1", iostat, iomsg)
associate(palette => interpreter%figure%panels(interpreter%figure%current)%palette)
   test_passed(77) = test_passed(77) .and. iostat == 0_I4P .and. all(palette%rgb(0.0_R8P) == [255, 255, 255]) .and. &
                     all(palette%rgb(1.0_R8P) == [255, 0, 0])
endassociate
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '0 0 300', '255 255 255', '1 0 0'
close(unit)
call interpreter%run_text("set palette file '"//data_file//"'", iostat, iomsg)
associate(palette => interpreter%figure%panels(interpreter%figure%current)%palette)
   test_passed(77) = test_passed(77) .and. iostat == 0_I4P .and. all(palette%rgb(0.2_R8P) == [102, 102, 255]) .and. &
                     all(palette%rgb(0.9_R8P) == [255, 51, 51])
endassociate
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '0 0 0 1', '1 1 1 1', '', '2 1 0 0'
close(unit)
call interpreter%run_text("set palette file '"//data_file//"'", iostat, iomsg)
test_passed(77) = test_passed(77) .and. iostat /= 0_I4P .and. index(iomsg, 'bad data') > 0
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '0 0 0 1', '2 1 0 0', '1 1 1 1'
close(unit)
call interpreter%run_text("set palette file '"//data_file//"'", iostat, iomsg)
test_passed(77) = test_passed(77) .and. iostat /= 0_I4P .and. index(iomsg, 'the values must increase') > 0
call interpreter%run_text("set palette file '"//data_file//"' using 1:2", iostat, iomsg)
test_passed(77) = test_passed(77) .and. iostat /= 0_I4P .and. index(iomsg, 'r:g:b or gray:r:g:b') > 0
call interpreter%run_text("set palette file 'foresight_no_such_palette.dat'", iostat, iomsg)
test_passed(77) = test_passed(77) .and. iostat /= 0_I4P .and. index(iomsg, 'set palette file:') > 0
! set colorsequence: gnuplot 6.0's podo and classic (svg terminal) linetype colors, `colors` abbreviated, a categorical
! order (its first N colors, then cycling), lc N following it, default back; errors as gnuplot (no N, unknown names)
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 2 3 4 5', '2 3 4 5 6'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("set colors podo; plot '"//data_file//"' u 1:2 w l, '' u 1:3 w l lc 7", iostat, iomsg)
associate(panel => interpreter%figure%panels(1))
   test_passed(78) = iostat == 0_I4P .and. panel%series(1)%style%color == '#000000' .and. &
                     panel%series(2)%style%color == '#d55e00'
endassociate
call interpreter%init(scratch)
call interpreter%run_text("set colorsequence classic; plot '"//data_file//"' u 1:2 w l, '' u 1:3 w l", iostat, iomsg)
associate(panel => interpreter%figure%panels(1))
   test_passed(78) = test_passed(78) .and. iostat == 0_I4P .and. panel%series(1)%style%color == '#ff0000' .and. &
                     panel%series(2)%style%color == '#008000'
endassociate
call interpreter%init(scratch)
call interpreter%run_text("set colorsequence BatlowS 3; plot '"//data_file//"' u 1:2 w l, '' u 1:3 w l, '' u 1:4 w l, "// &
                          "'' u 1:5 w l, '' u 1:2 w l lc 2", iostat, iomsg)
associate(panel => interpreter%figure%panels(1))
   test_passed(78) = test_passed(78) .and. iostat == 0_I4P .and. panel%series(1)%style%color == '#011959' .and. &
                     panel%series(2)%style%color == '#faccfa' .and. panel%series(3)%style%color == '#828231' .and. &
                     panel%series(4)%style%color == '#011959' .and. panel%series(5)%style%color == '#faccfa'
endassociate
call interpreter%init(scratch)
call interpreter%run_text("set colorsequence podo; set colorsequence default; plot '"//data_file//"' u 1:2 w l", &
                          iostat, iomsg)
test_passed(78) = test_passed(78) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%series(1)%style%color == '#9400d3'
call interpreter%run_text("set colorsequence foo", iostat, iomsg)
test_passed(78) = test_passed(78) .and. iostat /= 0_I4P .and. index(iomsg, 'unknown color sequence "foo"') > 0
call interpreter%run_text("set colorsequence podo 3", iostat, iomsg)
test_passed(78) = test_passed(78) .and. iostat /= 0_I4P .and. index(iomsg, 'default, podo and classic none') > 0
call interpreter%run_text("set colorsequence batlowS 101", iostat, iomsg)
test_passed(78) = test_passed(78) .and. iostat /= 0_I4P .and. index(iomsg, '1 to 100 colors') > 0
call interpreter%run_text("set colorsequence", iostat, iomsg)
test_passed(78) = test_passed(78) .and. iostat /= 0_I4P
! the color axis, as gnuplot 6.0: cbtics, set format cb (a bare set format too, not set format xy), unset cbtics;
! logscale cb: the positive data extent (3..700, not decades), ticks at 10 and 100, the x axis untouched
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '0 0 0', '1 0 0.3', '2 0 1', '', '0 2 0.5', '1 2 0.7', '2 2 0.9'
close(unit)
test_passed(79) = colorbox_labels("set cbtics 0.25", ['0.25', '0.75'], ['0.2 '])
test_passed(79) = test_passed(79) .and. colorbox_labels("set format cb '%.2f'", ['0.00', '0.40', '1.00'], ['0.4 '])
test_passed(79) = test_passed(79) .and. colorbox_labels("set format '%.1e'", ['2.0e-01'], ['0.2    '])
test_passed(79) = test_passed(79) .and. colorbox_labels("set format xy '%.1e'", ['0.2'], ['0.6e-01'])
test_passed(79) = test_passed(79) .and. colorbox_labels("unset cbtics; set cblabel 'phi'", ['phi'], ['0.2'])
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '0 0 3', '1 0 30', '2 0 700', '', '0 1 0', '1 1 -5', '2 1 50'
close(unit)
! (foresight labels decades 10 with a superscript exponent, on every log axis)
test_passed(79) = test_passed(79) .and. colorbox_labels("set logscale cb", ['10'], ['1000'])
associate(panel => interpreter%figure%panels(1))
   test_passed(79) = test_passed(79) .and. panel%cbaxis%log .and. panel%cbaxis%lo == 3.0_R8P .and. &
                     panel%cbaxis%hi == 700.0_R8P .and. .not. panel%xaxis%log
   if (test_passed(79)) test_passed(79) = count(panel%cbaxis%ticks%major) == 2 .and. &
                                          all(pack(panel%cbaxis%ticks%value, panel%cbaxis%ticks%major) == [10.0_R8P, 100.0_R8P])
endassociate
call interpreter%run_text("set logscale cb x2", iostat, iomsg)
test_passed(79) = test_passed(79) .and. iostat /= 0_I4P
! set colorbox, as gnuplot 6.0: options and minimal abbreviations, origin/size kept until used, a bare set colorbox back
! to the default place (the rest kept), unset colorbox resetting every option; back, border line types, bad sizes
call interpreter%init(scratch)
call interpreter%run_text("set colorbox h u o 0.1,0.2 s 0.5, 0.05 nobo inv fr", iostat, iomsg)
associate(cbox => interpreter%figure%panels(1)%cbox)
   test_passed(80) = iostat == 0_I4P .and. cbox%horizontal .and. cbox%user .and. .not. cbox%border .and. cbox%invert .and. &
                     all(cbox%origin == [0.1_R8P, 0.2_R8P]) .and. all(cbox%size == [0.5_R8P, 0.05_R8P])
   call interpreter%run_text("set colorbox", iostat, iomsg)
   test_passed(80) = test_passed(80) .and. iostat == 0_I4P .and. .not. cbox%user .and. cbox%horizontal .and. &
                     cbox%invert .and. .not. cbox%border .and. all(cbox%origin == [0.1_R8P, 0.2_R8P])
   call interpreter%run_text("set colorbox user; set colorbox default vertical bdefault noinv", iostat, iomsg)
   test_passed(80) = test_passed(80) .and. iostat == 0_I4P .and. .not. (cbox%user .or. cbox%horizontal .or. cbox%invert) &
                     .and. cbox%border
   call interpreter%run_text("set colorbox horizontal invert noborder user; unset colorbox; set colorbox", iostat, iomsg)
   test_passed(80) = test_passed(80) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%colorbox .and. &
                     .not. (cbox%user .or. cbox%horizontal .or. cbox%invert) .and. cbox%border .and. &
                     all(cbox%origin == [0.9_R8P, 0.2_R8P]) .and. all(cbox%size == [0.05_R8P, 0.6_R8P])
endassociate
call interpreter%run_text("set colorbox back", iostat, iomsg)
test_passed(80) = test_passed(80) .and. iostat /= 0_I4P .and. index(iomsg, 'drawn in front') > 0
call interpreter%run_text("set colorbox border 3", iostat, iomsg)
test_passed(80) = test_passed(80) .and. iostat /= 0_I4P .and. index(iomsg, 'line types are not supported') > 0
call interpreter%run_text("set colorbox user size 0,0.5", iostat, iomsg)
test_passed(80) = test_passed(80) .and. iostat /= 0_I4P .and. index(iomsg, 'the size must be positive') > 0
call interpreter%run_text("set colorbox origin 0.1", iostat, iomsg)
test_passed(80) = test_passed(80) .and. iostat /= 0_I4P .and. index(iomsg, 'origin needs X,Y') > 0
call interpreter%run_text("set colorbox d", iostat, iomsg)
test_passed(80) = test_passed(80) .and. iostat /= 0_I4P .and. index(iomsg, 'unsupported option "d"') > 0
! user variables and functions, as gnuplot 6.0: a function of a variable over a range of that variable, replot
! seeing a new value, using expressions, the dummy variable winning, angles in degrees, statements on one line; errors
call interpreter%init(scratch)
call interpreter%run_text("a = 2"//new_line('a')//"f(x) = a*sin(x)"//new_line('a')//"set xrange [0:a]"// &
                          new_line('a')//"plot f(x)", iostat, iomsg)
associate(panel => interpreter%figure%panels(1))
   test_passed(81) = iostat == 0_I4P .and. panel%xaxis%max_fixed .and. panel%xaxis%max_user == 2.0_R8P
   if (test_passed(81)) test_passed(81) = abs(panel%series(1)%y(size(panel%series(1)%y)) - 2.0_R8P * sin(2.0_R8P)) < &
                                          1.0e-12_R8P
endassociate
call interpreter%run_text("a = 3; replot", iostat, iomsg)
associate(panel => interpreter%figure%panels(1))
   test_passed(81) = test_passed(81) .and. iostat == 0_I4P
   if (test_passed(81)) test_passed(81) = abs(panel%series(1)%y(size(panel%series(1)%y)) - 3.0_R8P * sin(2.0_R8P)) < &
                                          1.0e-12_R8P
endassociate
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 2', '2 4'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("scale = 10; plot '"//data_file//"' u 1:($2*scale)", iostat, iomsg)
test_passed(81) = test_passed(81) .and. iostat == 0_I4P
if (test_passed(81)) test_passed(81) = all(interpreter%figure%panels(1)%series(1)%y == [20.0_R8P, 40.0_R8P])
call interpreter%init(scratch)
call interpreter%run_text("x = 3; set xrange [0:2]; plot x**2", iostat, iomsg)
block
   real(R8P) :: v     !< Value.
   logical   :: found !< Found.

   associate(series => interpreter%figure%panels(1)%series(1))
      test_passed(81) = test_passed(81) .and. iostat == 0_I4P
      if (test_passed(81)) test_passed(81) = series%y(size(series%y)) == 4.0_R8P
   endassociate
   call interpreter%symbols%value_of('x', v, found)
   test_passed(81) = test_passed(81) .and. found .and. v == 3.0_R8P
   call interpreter%run_text("set angles degrees; s = sin(90); b = 7/2; set xrange [-pi:2*pi]", iostat, iomsg)
   call interpreter%symbols%value_of('s', v, found)
   test_passed(81) = test_passed(81) .and. iostat == 0_I4P .and. found .and. abs(v - 1.0_R8P) < 1.0e-15_R8P
   call interpreter%symbols%value_of('b', v, found)
   test_passed(81) = test_passed(81) .and. found .and. v == 3.0_R8P
   test_passed(81) = test_passed(81) .and. interpreter%figure%panels(1)%xaxis%min_user == -acos(-1.0_R8P)
endblock
call interpreter%run_text("h2( u , v ) = u*v; set xrange [0:h2(2, 3)]", iostat, iomsg)
test_passed(81) = test_passed(81) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%xaxis%max_user == 6.0_R8P
call interpreter%run_text("plot c*x", iostat, iomsg)
test_passed(81) = test_passed(81) .and. iostat /= 0_I4P .and. index(iomsg, 'undefined variable: c') > 0
call interpreter%run_text("fact(n) = n <= 1 ? 1 : n*fact(n-1)", iostat, iomsg)
test_passed(81) = test_passed(81) .and. iostat /= 0_I4P .and. index(iomsg, 'recursive function fact') > 0
call interpreter%run_text("a = $1", iostat, iomsg)
test_passed(81) = test_passed(81) .and. iostat /= 0_I4P .and. index(iomsg, 'columns are only valid in using') > 0
call interpreter%run_text("sin(x) = 2", iostat, iomsg)
test_passed(81) = test_passed(81) .and. iostat /= 0_I4P .and. index(iomsg, '"sin" is a builtin function') > 0
call interpreter%run_text("g(x) = x; plot g(1,2)", iostat, iomsg)
test_passed(81) = test_passed(81) .and. iostat /= 0_I4P .and. index(iomsg, 'function g requires 1 variable') > 0
call interpreter%run_text("a == 2", iostat, iomsg)
test_passed(81) = test_passed(81) .and. iostat /= 0_I4P .and. index(iomsg, 'unsupported command "a"') > 0

! explicit tick lists, as gnuplot 6.0: alone (a level 1 item is minor), added to the ticks (add), forgotten by positions
! without add and by unset; a label is a format if it has a conversion; positions are expressions
call interpreter%init(scratch)
associate(tics => interpreter%figure%panels(1)%xaxis%tics)
   call interpreter%run_text('set xtics ("a" 1, "b" 2.5 1, "c" 5)', iostat, iomsg)
   test_passed(82) = iostat == 0_I4P .and. tics%attribute(0.0_R8P, 6.7_R8P) == 'labels 1e0:a 2.5e0! 5e0:c'
   call interpreter%run_text('set xtics 2; set xtics add ("pi" pi)', iostat, iomsg)
   test_passed(82) = test_passed(82) .and. tics%attribute(0.0_R8P, 8.0_R8P) == '* 2 * labels 3.14159265358979e0:pi'
   call interpreter%run_text('set xtics ("a" 1); set xtics 2', iostat, iomsg)
   test_passed(82) = test_passed(82) .and. tics%attribute(0.0_R8P, 8.0_R8P) == '* 2 *'
   call interpreter%run_text('set xtics ("a" 1); unset xtics; set xtics', iostat, iomsg)
   test_passed(82) = test_passed(82) .and. tics%attribute(0.0_R8P, 8.0_R8P) == '* 2 *'
   call interpreter%run_text('set xtics auto; unset xtics; set xtics add ("b" 3)', iostat, iomsg)
   test_passed(82) = test_passed(82) .and. tics%attribute(0.0_R8P, 8.0_R8P) == 'auto labels 3e0:b'
   call interpreter%run_text('set xtics ("a" 1); set xtics add 2', iostat, iomsg)
   test_passed(82) = test_passed(82) .and. tics%attribute(0.0_R8P, 8.0_R8P) == '* 2 * labels 1e0:a'
   call interpreter%run_text('set xtics ("%.1f" 2, "x%gy" 3, "two" 1 + 1, 4,)', iostat, iomsg)
   test_passed(82) = test_passed(82) .and. tics%attribute(0.0_R8P, 8.0_R8P) == 'labels 2e0:2.0 3e0:x3y 2e0:two 4e0:4'
   call interpreter%run_text('set xtics ("a" 1) nomirror', iostat, iomsg)
   test_passed(82) = test_passed(82) .and. iostat == 0_I4P .and. .not. tics%mirror
endassociate
call interpreter%run_text('set xtics ("a")', iostat, iomsg)
test_passed(82) = test_passed(82) .and. iostat /= 0_I4P .and. index(iomsg, 'a list item needs a position') > 0
call interpreter%run_text('set xtics 1,2 ("a" 3)', iostat, iomsg)
test_passed(82) = test_passed(82) .and. iostat /= 0_I4P .and. index(iomsg, 'with positions is not supported') > 0
call interpreter%run_text('set xtics ("a" 1) ("b" 2)', iostat, iomsg)
test_passed(82) = test_passed(82) .and. iostat /= 0_I4P .and. index(iomsg, 'one list of ticks is expected') > 0
call interpreter%run_text('set xtics ("a 1)', iostat, iomsg)
test_passed(82) = test_passed(82) .and. iostat /= 0_I4P .and. index(iomsg, 'unclosed label') > 0
call interpreter%run_text('set xtics ("a" 1,, "b" 2)', iostat, iomsg)
test_passed(82) = test_passed(82) .and. iostat /= 0_I4P .and. index(iomsg, 'empty item in the list') > 0
call interpreter%run_text('set xtics ("a" 1 +)', iostat, iomsg)
test_passed(82) = test_passed(82) .and. iostat /= 0_I4P .and. index(iomsg, 'list item "1 +"') > 0
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '0 0 0', '1 0 0.3', '2 0 1', '', '0 2 0.5', '1 2 0.7', '2 2 0.9'
close(unit)
test_passed(82) = test_passed(82) .and. colorbox_labels('set cbtics ("low" 0.2, "high" 0.8)', ['low ', 'high'], ['0.2'])

! minor ticks, as gnuplot 6.0: set mxtics [N] (gnuplot's count without N), unset mxtics, set mxtics default
call interpreter%init(scratch)
associate(tics => interpreter%figure%panels(1)%xaxis%tics)
   call interpreter%run_text('set mxtics', iostat, iomsg)
   test_passed(83) = iostat == 0_I4P .and. tics%attribute() == 'auto minor auto'
   call interpreter%run_text('set xtics 2; set mxtics 4', iostat, iomsg)
   test_passed(83) = test_passed(83) .and. tics%attribute() == '* 2 * minor 4'
   call interpreter%run_text('unset mxtics', iostat, iomsg)
   test_passed(83) = test_passed(83) .and. tics%attribute() == '* 2 * minor 0'
   call interpreter%run_text('set mxtics default; set xtics auto', iostat, iomsg)
   test_passed(83) = test_passed(83) .and. tics%attribute() == ''
endassociate
call interpreter%run_text('set mytics 3; set my2tics; set mcbtics 2', iostat, iomsg)
associate(panel => interpreter%figure%panels(1))
   test_passed(83) = test_passed(83) .and. iostat == 0_I4P .and. panel%yaxis%tics%minor == 3_I4P .and. &
                     panel%y2axis%tics%minor == MINOR_AUTO .and. panel%cbaxis%tics%minor == 2_I4P
endassociate
call interpreter%run_text('set mxtics 0', iostat, iomsg)
test_passed(83) = test_passed(83) .and. iostat /= 0_I4P .and. index(iomsg, 'set mxtics: a number of intervals') > 0
call interpreter%run_text('set mxtics 2.5', iostat, iomsg)
test_passed(83) = test_passed(83) .and. iostat /= 0_I4P .and. index(iomsg, 'set mxtics: a number of intervals') > 0

! rotated x labels and outward ticks, as gnuplot 6.0: rotate is by 90 right-justified, rotate by A left-justified
! unless justified; they persist with new positions, until norotate and in
call interpreter%init(scratch)
associate(tics => interpreter%figure%panels(1)%xaxis%tics)
   call interpreter%run_text('set xtics rotate', iostat, iomsg)
   test_passed(84) = iostat == 0_I4P .and. tics%attribute() == 'auto rotate 9e1 end'
   call interpreter%run_text('set xtics 2 rotate by 45 right out', iostat, iomsg)
   test_passed(84) = test_passed(84) .and. tics%attribute() == '* 2 * out rotate 4.5e1 end'
   call interpreter%run_text('set xtics 5; set xtics rotate by -30', iostat, iomsg)
   test_passed(84) = test_passed(84) .and. tics%attribute() == '* 5 * out rotate -3e1 start'
   call interpreter%run_text('set xtics norotate in', iostat, iomsg)
   test_passed(84) = test_passed(84) .and. tics%attribute() == '* 5 *'
endassociate
call interpreter%run_text('set ytics out; set y2tics out', iostat, iomsg)
test_passed(84) = test_passed(84) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%yaxis%tics%out .and. &
                  interpreter%figure%panels(1)%y2axis%tics%out
call interpreter%run_text('set ytics rotate', iostat, iomsg)
test_passed(84) = test_passed(84) .and. iostat /= 0_I4P .and. index(iomsg, 'rotate is supported on xtics and x2tics only') > 0
call interpreter%run_text('set cbtics out', iostat, iomsg)
test_passed(84) = test_passed(84) .and. iostat /= 0_I4P .and. index(iomsg, 'in and out are supported on xtics') > 0
call interpreter%run_text('set xtics right', iostat, iomsg)
test_passed(84) = test_passed(84) .and. iostat /= 0_I4P .and. index(iomsg, 'right justifies rotated labels') > 0
call interpreter%run_text('set xtics rotate by', iostat, iomsg)
test_passed(84) = test_passed(84) .and. iostat /= 0_I4P .and. index(iomsg, 'rotate by needs an angle') > 0

! inline ranges, as gnuplot 6.0: [x] then [y] for that plot only (set xrange untouched), an empty or * end keeps the
! set one, [t=a:b] names the dummy variable, replot keeps them
call interpreter%init(scratch)
associate(panel => interpreter%figure%panels(1))
   call interpreter%run_text('set xrange [0:10]; plot [0:2*pi] [-2:2] sin(x)', iostat, iomsg)
   test_passed(85) = iostat == 0_I4P .and. panel%xaxis%lo == 0.0_R8P .and. &
                     abs(panel%xaxis%hi - 2.0_R8P * acos(-1.0_R8P)) < 1.0e-12_R8P .and. &
                     panel%yaxis%lo == -2.0_R8P .and. panel%yaxis%hi == 2.0_R8P .and. panel%xaxis%max_user == 10.0_R8P
   call interpreter%run_text('replot', iostat, iomsg)
   test_passed(85) = test_passed(85) .and. iostat == 0_I4P .and. panel%yaxis%hi == 2.0_R8P
   call interpreter%run_text('plot sin(x)', iostat, iomsg)
   test_passed(85) = test_passed(85) .and. iostat == 0_I4P .and. panel%xaxis%lo == 0.0_R8P .and. &
                     panel%xaxis%hi == 10.0_R8P .and. panel%yaxis%hi == 1.0_R8P
   call interpreter%run_text('plot [*:3] [] x', iostat, iomsg)
   test_passed(85) = test_passed(85) .and. iostat == 0_I4P .and. panel%xaxis%lo == 0.0_R8P .and. panel%xaxis%hi == 3.0_R8P
   call interpreter%run_text('unset xrange; plot [u=1:2] u**2', iostat, iomsg)
   test_passed(85) = test_passed(85) .and. iostat == 0_I4P .and. panel%xaxis%lo == 1.0_R8P .and. panel%yaxis%hi == 4.0_R8P
endassociate
call interpreter%run_text('plot [u=1:2] x', iostat, iomsg)
test_passed(85) = test_passed(85) .and. iostat /= 0_I4P .and. index(iomsg, 'undefined variable: x') > 0
call interpreter%run_text('plot [0:1] [0:1] [0:1] x', iostat, iomsg)
test_passed(85) = test_passed(85) .and. iostat /= 0_I4P .and. index(iomsg, 'at most two inline ranges') > 0
call interpreter%run_text('plot x, [0:1] x', iostat, iomsg)
test_passed(85) = test_passed(85) .and. iostat /= 0_I4P .and. index(iomsg, 'inline ranges go before the first item') > 0
call interpreter%run_text('plot [0;1] x', iostat, iomsg)
test_passed(85) = test_passed(85) .and. iostat /= 0_I4P
call interpreter%run_text('plot [1=0:1] x', iostat, iomsg)
test_passed(85) = test_passed(85) .and. iostat /= 0_I4P .and. index(iomsg, 'bad dummy variable name') > 0
call interpreter%run_text('plot [0:1]', iostat, iomsg)
test_passed(85) = test_passed(85) .and. iostat /= 0_I4P .and. index(iomsg, 'nothing to plot') > 0

! set datafile missing and commentschars, as gnuplot 6.0: a point reading the missing string (in a plain column or
! through an expression) is left out without breaking the line, a missing cell in an unused column does not matter;
! commentschars replaces #
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 1 7', '2 2 7', '3 ? 7', '% note', '4 4 ?', '5 5 7'
close(unit)
call interpreter%init(scratch)
associate(panel => interpreter%figure%panels(1))
   call interpreter%run_text("set datafile missing '?'; set datafile commentschars '#%'; plot '"//data_file// &
                             "' u 1:2 w l", iostat, iomsg)
   test_passed(86) = iostat == 0_I4P .and. size(panel%series(1)%x) == 4 .and. .not. any(ieee_is_nan(panel%series(1)%y))
   call interpreter%run_text("plot '"//data_file//"' u 1:($3) w l", iostat, iomsg)
   test_passed(86) = test_passed(86) .and. iostat == 0_I4P .and. size(panel%series(1)%x) == 4
   call interpreter%run_text("unset datafile; plot '"//data_file//"' u 1:2 w l", iostat, iomsg)
   ! without a missing string, ? and the % row hold no number: skipped too in a plain column (gnuplot)
   test_passed(86) = test_passed(86) .and. iostat == 0_I4P .and. size(panel%series(1)%x) == 4 .and. &
                     .not. any(ieee_is_nan(panel%series(1)%y))
endassociate
call interpreter%run_text("set datafile missing ?", iostat, iomsg)
test_passed(86) = test_passed(86) .and. iostat /= 0_I4P .and. index(iomsg, 'set datafile missing: a "string"') > 0
call interpreter%run_text("set datafile commentschars %", iostat, iomsg)
test_passed(86) = test_passed(86) .and. iostat /= 0_I4P .and. index(iomsg, 'set datafile commentschars: a "string"') > 0
call interpreter%run_text("set datafile fortran", iostat, iomsg)
test_passed(86) = test_passed(86) .and. iostat /= 0_I4P .and. index(iomsg, 'unsupported option "fortran"') > 0

! smooth csplines, acsplines, bezier, sbezier, kdensity: set samples points, the values of gnuplot 6.0 (set table)
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 2', '2 3', '4 1', '3 5', '5 4', '2 4', '6 2'
close(unit)
call interpreter%init(scratch)
associate(panel => interpreter%figure%panels(1))
   call interpreter%run_text("set samples 9; plot '"//data_file//"' smooth csplines, '' smooth acsplines, "// &
                             "'' smooth bezier, '' smooth sbezier, '' u 1:2 smooth kdensity, '' smooth kdensity bandwidth 0.5", &
                             iostat, iomsg)
   test_passed(87) = iostat == 0_I4P .and. all([(size(panel%series(i)%x) == 9, i = 1, 6)])
   if (test_passed(87)) test_passed(87) = &
      near(panel%series(1)%y(3), 4.21176_R8P) .and. near(panel%series(1)%y(6), 1.04256_R8P) .and. &
      near(panel%series(2)%y(1), 2.54139_R8P) .and. near(panel%series(2)%y(9), 2.37165_R8P) .and. &
      near(panel%series(3)%x(2), 1.86057_R8P) .and. near(panel%series(3)%y(8), 3.12_R8P) .and. &
      near(panel%series(4)%y(4), 3.37672_R8P) .and. near(panel%series(5)%y(1), 2.74479_R8P) .and. &
      near(panel%series(6)%y(3), 6.29595_R8P)
   call interpreter%run_text("plot '"//data_file//"' u 1:2:(0.5) smooth acsplines", iostat, iomsg)
   test_passed(87) = test_passed(87) .and. iostat == 0_I4P .and. size(panel%series(1)%x) == 9
endassociate
call interpreter%run_text("plot '"//data_file//"' every ::0::2 smooth acsplines", iostat, iomsg)
test_passed(87) = test_passed(87) .and. iostat /= 0_I4P .and. index(iomsg, 'acsplines need at least 4 points') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2:(-1) smooth acsplines", iostat, iomsg)
test_passed(87) = test_passed(87) .and. iostat /= 0_I4P .and. index(iomsg, 'acsplines need positive weights') > 0
call interpreter%run_text("plot '"//data_file//"' smooth kdensity bandwidth x", iostat, iomsg)
test_passed(87) = test_passed(87) .and. iostat /= 0_I4P .and. index(iomsg, 'a number is expected') > 0

! lc variable, as gnuplot 6.0: the last using column colors each point, a linetype number (cycling) or with rgb a
! 24-bit color; lines, points, linespoints and impulses only
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 1 1', '2 2 2', '3 3 3', '4 2 1', '5 3 9'
close(unit)
call interpreter%init(scratch)
associate(panel => interpreter%figure%panels(1))
   call interpreter%run_text("plot '"//data_file//"' u 1:2:3 w lp lc variable, '' u 1:2:($3*65536+255) w p lc rgb var", &
                             iostat, iomsg)
   test_passed(88) = iostat == 0_I4P
   if (test_passed(88)) test_passed(88) = all(panel%series(1)%colors == ['#9400d3', '#009e73', '#56b4e9', '#9400d3', &
                                                                        '#9400d3']) .and. &
                                          panel%series(2)%colors(5) == '#0900ff' .and. size(panel%series(1)%x) == 5 &
                                          .and. panel%series(2)%style%color == '#0100ff' ! key: the first point's
endassociate
call interpreter%run_text("plot '"//data_file//"' u 1:2:3 w boxes lc variable", iostat, iomsg)
test_passed(88) = test_passed(88) .and. iostat /= 0_I4P .and. index(iomsg, 'lc variable applies to lines') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2 w p lc variable", iostat, iomsg)
test_passed(88) = test_passed(88) .and. iostat /= 0_I4P .and. index(iomsg, 'lc variable needs using x:y:color') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2:3 w l lc var smooth unique", iostat, iomsg)
test_passed(88) = test_passed(88) .and. iostat /= 0_I4P .and. index(iomsg, 'lc variable does not go with smooth') > 0

! the second x axis, as gnuplot 6.0: set x2tics alone spans the first x axis range, series on x2 scale it on their own,
! functions on x2 are sampled over its range; off again with unset x2tics
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 1', '2 4', '3 9'
close(unit)
call interpreter%init(scratch)
associate(panel => interpreter%figure%panels(1))
   call interpreter%run_text("set x2tics; plot '"//data_file//"' w l", iostat, iomsg)
   test_passed(89) = iostat == 0_I4P .and. panel%x2_active .and. panel%x2axis%lo == panel%xaxis%lo .and. &
                     panel%x2axis%hi == panel%xaxis%hi
   call interpreter%run_text("set x2label 'top'; plot '"//data_file//"', '' u ($1*100):2 axes x2y1", iostat, iomsg)
   test_passed(89) = test_passed(89) .and. iostat == 0_I4P .and. panel%x2axis%lo == 100.0_R8P .and. &
                     panel%x2axis%hi == 300.0_R8P .and. panel%xaxis%lo == 1.0_R8P .and. panel%xaxis%hi == 3.0_R8P .and. &
                     panel%series(2)%x2 .and. panel%x2axis%label == 'top'
   call interpreter%run_text("unset x2tics; plot '"//data_file//"'", iostat, iomsg)
   test_passed(89) = test_passed(89) .and. iostat == 0_I4P .and. .not. panel%x2_active
   call interpreter%run_text("set x2range [0:10]; plot x axes x2y1, '"//data_file//"'", iostat, iomsg)
   test_passed(89) = test_passed(89) .and. iostat == 0_I4P .and. panel%series(1)%x(1) == 0.0_R8P .and. &
                     panel%series(1)%x(size(panel%series(1)%x)) == 10.0_R8P .and. panel%x2_active .and. &
                     panel%x2axis%hi == 10.0_R8P
   call interpreter%run_text('set x2tics out; set mx2tics 4; unset x2range; unset x2label', iostat, iomsg)
   test_passed(89) = test_passed(89) .and. iostat == 0_I4P .and. panel%x2axis%tics%out .and. &
                     panel%x2axis%tics%minor == 4_I4P .and. .not. panel%x2axis%min_fixed .and. .not. panel%x2axis%has_label()
endassociate
! rotated x2 labels, as gnuplot: rotate is 90 degrees from the tick (start), rotate by A too
call interpreter%run_text('set x2tics rotate', iostat, iomsg)
test_passed(89) = test_passed(89) .and. iostat == 0_I4P .and. &
                  interpreter%figure%panels(1)%x2axis%tics%rotate == 90.0_R8P .and. &
                  interpreter%figure%panels(1)%x2axis%tics%anchor() == 'start'
call interpreter%run_text('set x2tics rotate by 45 right', iostat, iomsg)
test_passed(89) = test_passed(89) .and. iostat == 0_I4P .and. &
                  interpreter%figure%panels(1)%x2axis%tics%rotate == 45.0_R8P .and. &
                  interpreter%figure%panels(1)%x2axis%tics%anchor() == 'end'
call interpreter%run_text('set y2tics rotate', iostat, iomsg)
test_passed(89) = test_passed(89) .and. iostat /= 0_I4P .and. &
                  index(iomsg, 'rotate is supported on xtics and x2tics only') > 0

! the identity themes washi and night; a default theme given to init (foresight --theme), which a script overrides
call interpreter%init(scratch, theme='night')
test_passed(90) = interpreter%figure%theme%name == 'night'
call interpreter%run_text('set terminal svg theme washi', iostat, iomsg)
test_passed(90) = test_passed(90) .and. iostat == 0_I4P .and. interpreter%figure%theme%name == 'washi' .and. &
                  interpreter%figure%theme%background == '#f3ede1'
call interpreter%run_text('set terminal svg theme sepia', iostat, iomsg)
test_passed(90) = test_passed(90) .and. iostat /= 0_I4P .and. &
                  index(iomsg, 'unknown theme "sepia" (supported: classic vfd lcd washi night)') > 0
call interpreter%init(scratch)
test_passed(90) = test_passed(90) .and. interpreter%figure%theme%is_classic()

! bins, as gnuplot 6.0 (set table, GPVAL_X_MIN...): equal-width bins centred from the first to the last x (or binrange),
! a binwidth centred on the range, the sum or the mean of y per bin; a single column is x, each point counting 1 (so
! for smooth frequency and kdensity); the autoscale spans the outer bin edges and y = 0
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1.5 2', '2.2 4', '2.7 1', '3.1 3', '3.9 5', '4.4 2', '5.0 6', '2.2 1'
close(unit)
call interpreter%init(scratch)
associate(panel => interpreter%figure%panels(1))
   call interpreter%run_text("plot '"//data_file//"' using 1 bins=4 with boxes, '' u 1:2 bins binwidth=1 binvalue=avg, "// &
                             "'' u 1 smooth bins = 3 binrange [0:6]", iostat, iomsg)
   test_passed(91) = iostat == 0_I4P
   if (test_passed(91)) test_passed(91) = &
      all(near(panel%series(1)%x, [1.5_R8P, 2.66667_R8P, 3.83333_R8P, 5.0_R8P])) .and. &
      same(panel%series(1)%y, [1, 4, 2, 1]) .and. &
      all(near(panel%series(2)%x, [1.75_R8P, 2.75_R8P, 3.75_R8P, 4.75_R8P])) .and. &
      all(near(panel%series(2)%y, [2.33333_R8P, 2.0_R8P, 5.0_R8P, 4.0_R8P])) .and. &
      same(panel%series(3)%x, [0, 3, 6]) .and. same(panel%series(3)%y, [0, 7, 1])
   call interpreter%run_text("plot '"//data_file//"' using 1 bins=4 with points", iostat, iomsg)
   test_passed(91) = test_passed(91) .and. iostat == 0_I4P .and. near(panel%xaxis%lo, 0.5_R8P) .and. &
                     near(panel%xaxis%hi, 6.0_R8P) .and. near(panel%yaxis%lo, 0.0_R8P) .and. near(panel%yaxis%hi, 4.0_R8P)
   call interpreter%run_text("plot '"//data_file//"' using 1 smooth frequency, '' u 1 smooth kdensity", iostat, iomsg)
   test_passed(91) = test_passed(91) .and. iostat == 0_I4P
   if (test_passed(91)) test_passed(91) = &
      all(near(panel%series(1)%x, [1.5_R8P, 2.2_R8P, 2.7_R8P, 3.1_R8P, 3.9_R8P, 4.4_R8P, 5.0_R8P])) .and. &
      same(panel%series(1)%y, [1, 2, 1, 1, 1, 1, 1])
endassociate
call interpreter%run_text("plot '"//data_file//"' bins smooth unique", iostat, iomsg)
test_passed(91) = test_passed(91) .and. iostat /= 0_I4P .and. index(iomsg, 'bins and smooth unique: not both') > 0
call interpreter%run_text("plot '"//data_file//"' bins binwidth=-1", iostat, iomsg)
test_passed(91) = test_passed(91) .and. iostat /= 0_I4P .and. index(iomsg, 'binwidth must be positive') > 0
call interpreter%run_text("plot '"//data_file//"' binwidth=1", iostat, iomsg)
test_passed(91) = test_passed(91) .and. iostat /= 0_I4P .and. index(iomsg, 'binwidth follows bins') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2:2 bins with boxes", iostat, iomsg)
test_passed(91) = test_passed(91) .and. iostat /= 0_I4P .and. index(iomsg, 'bins need using X or X:Y') > 0
call interpreter%run_text("plot '"//data_file//"' bins binvalue=max", iostat, iomsg)
test_passed(91) = test_passed(91) .and. iostat /= 0_I4P .and. index(iomsg, 'expecting binvalue={sum|avg}') > 0
call interpreter%run_text("plot x bins", iostat, iomsg)
test_passed(91) = test_passed(91) .and. iostat /= 0_I4P .and. index(iomsg, 'bins apply to data files') > 0

! smooth mcsplines, as gnuplot 6.0 (set table): the monotone spline of Fritsch and Carlson at the merged points and at
! max(samples, 2n) points, the first block only, within a fixed x range
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 2', '2 3', '4 1', '3 5', '5 4', '2 4', '6 2'
close(unit)
open(newunit=unit, file=csv_file, action='write', status='replace')
write(unit, '(A)') '1 1', '2 2', '3 2', '4 5', '', '', '10 1', '11 3'
close(unit)
call interpreter%init(scratch)
associate(panel => interpreter%figure%panels(1))
   call interpreter%run_text("set samples 9; plot '"//data_file//"' smooth mcsplines, '"//csv_file//"' smooth mcsplines", &
                             iostat, iomsg)
   test_passed(92) = iostat == 0_I4P
   if (test_passed(92)) test_passed(92) = size(panel%series(1)%x) == 18 .and. size(panel%series(2)%x) == 13
   if (test_passed(92)) test_passed(92) = &
      near(panel%series(1)%x(1), 1.0_R8P) .and. near(panel%series(1)%x(2), 1.0_R8P) .and. &
      near(panel%series(1)%x(3), 1.45455_R8P) .and. near(panel%series(1)%y(3), 2.68182_R8P) .and. &
      near(panel%series(1)%y(6), 4.17168_R8P) .and. near(panel%series(1)%y(10), 1.73028_R8P) .and. &
      near(panel%series(1)%x(17), 5.77273_R8P) .and. near(panel%series(1)%y(17), 2.53437_R8P) .and. &
      near(panel%series(1)%y(18), 2.0_R8P) .and. near(panel%series(2)%y(3), 1.46289_R8P) .and. &
      near(panel%series(2)%x(12), 3.8125_R8P) .and. near(panel%series(2)%y(12), 4.35181_R8P)
   call interpreter%run_text("set xrange [2.5:4.5]; plot '"//data_file//"' smooth mcsplines", iostat, iomsg)
   test_passed(92) = test_passed(92) .and. iostat == 0_I4P .and. size(panel%series(1)%x) == 18
   if (test_passed(92)) test_passed(92) = near(panel%series(1)%x(3), 2.5_R8P) .and. &
                                          near(panel%series(1)%y(3), 4.4375_R8P) .and. &
                                          near(panel%series(1)%y(8), 4.47408_R8P) .and. &
                                          near(panel%series(1)%y(16), 2.5_R8P)
endassociate
call interpreter%run_text("unset xrange; plot '"//data_file//"' every ::0::0 smooth mcsplines", iostat, iomsg)
test_passed(92) = test_passed(92) .and. iostat /= 0_I4P .and. index(iomsg, 'mcsplines need at least 2 points') > 0

! lc palette, as gnuplot 6.0 (svg probes): z (the default) colors each point by the last using column over the color
! axis, which spans those values; cb V and frac F color the whole item, any style but the panel charts
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 1 0', '2 3 5', '3 2 10', '4 4 2', '5 2 NaN'
close(unit)
call interpreter%init(scratch)
associate(panel => interpreter%figure%panels(1))
   call interpreter%run_text("plot '"//data_file//"' u 1:2:3 w lp lc palette z, '' u 1:2 w l lc palette frac 0.25, "// &
                             "'' u 1:2 w boxes lc palette cb 5, sin(x) lc palette frac 1", iostat, iomsg)
   test_passed(93) = iostat == 0_I4P
   if (test_passed(93)) test_passed(93) = &
      all(panel%series(1)%colors(1:4) == ['#000000', '#b42000', '#ffff00', '#7202f3']) .and. &
      panel%series(1)%colors(5) == 'none' .and. .not. ieee_is_nan(panel%series(1)%y(5)) .and. &
      panel%series(1)%style%color == '#000000' .and. &
      panel%series(2)%style%color == '#8004ff' .and. panel%series(3)%style%color == '#b42000' .and. &
      panel%series(4)%style%color == '#ffff00' .and. panel%cbaxis%lo == 0.0_R8P .and. panel%cbaxis%hi == 10.0_R8P
   ! without z values the color axis keeps gnuplot's default [-10:10]: cb 5 is three quarters of the palette
   call interpreter%run_text("set style line 3 lc palette cb 5 lw 2; plot '"//data_file//"' u 1:2 w l ls 3", &
                             iostat, iomsg)
   test_passed(93) = test_passed(93) .and. iostat == 0_I4P .and. panel%series(1)%style%color == '#dd6c00'
endassociate
call interpreter%run_text("plot sin(x) lc palette z", iostat, iomsg)
test_passed(93) = test_passed(93) .and. iostat /= 0_I4P .and. index(iomsg, 'lc palette z needs using x:y:z') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2 w l lc palette", iostat, iomsg)
test_passed(93) = test_passed(93) .and. iostat /= 0_I4P .and. index(iomsg, 'lc palette z needs using x:y:z') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2:3 w boxes lc palette z", iostat, iomsg)
test_passed(93) = test_passed(93) .and. iostat /= 0_I4P .and. index(iomsg, 'lc palette z applies to lines') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2 w l lc palette viridis", iostat, iomsg)
test_passed(93) = test_passed(93) .and. iostat /= 0_I4P .and. index(iomsg, 'no named colormap') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2 w l lc palette frac 2", iostat, iomsg)
test_passed(93) = test_passed(93) .and. iostat /= 0_I4P .and. index(iomsg, 'a fraction from 0 to 1') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2 w pie lc palette frac 0.5", iostat, iomsg)
test_passed(93) = test_passed(93) .and. iostat /= 0_I4P .and. index(iomsg, 'lc palette does not apply to pie') > 0

! the key at a position and in a margin, as gnuplot 6.0 (show key): at keeps through position words, a region cancels
! it; lmargin/rmargin are outside left/right, tmargin/bmargin above/below keeping the alignment and the layout
call interpreter%init(scratch)
associate(panel => interpreter%figure%panels(1))
   call interpreter%run_text("set key at 5,5", iostat, iomsg)
   test_passed(94) = iostat == 0_I4P .and. panel%key_at .and. all(panel%key_xy == [5.0_R8P, 5.0_R8P]) .and. &
                     all(panel%key_system == 'first')
   call interpreter%run_text("set key left bottom", iostat, iomsg)
   test_passed(94) = test_passed(94) .and. iostat == 0_I4P .and. panel%key_at .and. panel%key_h == 'left'
   call interpreter%run_text("set key at graph 0.2, 0.8 box", iostat, iomsg)
   test_passed(94) = test_passed(94) .and. iostat == 0_I4P .and. all(panel%key_system == 'graph') .and. panel%key_box
   call interpreter%run_text("set key at 1, screen 0.5", iostat, iomsg)
   test_passed(94) = test_passed(94) .and. iostat == 0_I4P .and. panel%key_system(1) == 'first' .and. &
                     panel%key_system(2) == 'screen' .and. panel%key_xy(2) == 0.5_R8P
   call interpreter%run_text("set key inside", iostat, iomsg)
   test_passed(94) = test_passed(94) .and. iostat == 0_I4P .and. .not. panel%key_at
   call interpreter%run_text("set key at 2,3; set key lmargin", iostat, iomsg)
   test_passed(94) = test_passed(94) .and. iostat == 0_I4P .and. .not. panel%key_at .and. panel%key_outside .and. &
                     panel%key_h == 'left' .and. len_trim(panel%key_margin) == 0
   call interpreter%run_text("set key tmargin right vertical", iostat, iomsg)
   test_passed(94) = test_passed(94) .and. iostat == 0_I4P .and. panel%key_margin == 'top' .and. &
                     panel%key_h == 'right' .and. .not. panel%key_horizontal
   call interpreter%run_text("set key bm; plot x", iostat, iomsg)
   test_passed(94) = test_passed(94) .and. iostat == 0_I4P .and. panel%key_margin == 'bottom'
endassociate
call interpreter%run_text("set key at character 2, 3", iostat, iomsg)
test_passed(94) = test_passed(94) .and. iostat /= 0_I4P .and. index(iomsg, 'character coordinates are not supported') > 0
call interpreter%run_text("set key at 2", iostat, iomsg)
test_passed(94) = test_passed(94) .and. iostat /= 0_I4P .and. index(iomsg, 'set key at: X, Y expected') > 0
call interpreter%run_text("set key at 2, y", iostat, iomsg)
test_passed(94) = test_passed(94) .and. iostat /= 0_I4P .and. index(iomsg, 'a number is expected, found "y"') > 0

! a set trange leaves out the polar data of theta beyond it, as gnuplot 6.0 (set table: flag e): out of the r autoscale
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '0 1', '90 2', '270 10'
close(unit)
call interpreter%init(scratch)
associate(panel => interpreter%figure%panels(1))
   call interpreter%run_text("set polar; set angles degrees; plot '"//data_file//"' w lp", iostat, iomsg)
   test_passed(95) = iostat == 0_I4P .and. panel%raxis%hi == 10.0_R8P
   call interpreter%run_text("set trange [0:180]; plot '"//data_file//"' w lp", iostat, iomsg)
   test_passed(95) = test_passed(95) .and. iostat == 0_I4P .and. panel%raxis%hi == 2.0_R8P .and. &
                     panel%series(1)%y(3) == 10.0_R8P
   call interpreter%run_text("set trange [180:0]; plot '"//data_file//"' w lp", iostat, iomsg)
   test_passed(95) = test_passed(95) .and. iostat == 0_I4P .and. panel%raxis%hi == 2.0_R8P
   call interpreter%run_text("set trange [*:*]; plot '"//data_file//"' w lp", iostat, iomsg)
   test_passed(95) = test_passed(95) .and. iostat == 0_I4P .and. panel%raxis%hi == 10.0_R8P
endassociate

! text terminals: the title, the x2 label and the x2 tick labels on consecutive rows, as gnuplot's dumb terminal
call interpreter%init('foresight_script_test_x2.txt')
call interpreter%run_text("set terminal dumb size 60,14; set output 'foresight_script_test_x2.txt'; "// &
                          "set title 'T'; set x2label 'top'; set x2tics; "// &
                          "plot x notitle, x*10 axes x2y1 notitle", iostat, iomsg)
test_passed(96) = iostat == 0_I4P .and. consecutive('foresight_script_test_x2.txt', ['T  ', 'top', '-10'])
open(newunit=unit, file='foresight_script_test_x2.txt')
close(unit, status='delete')

! fit from Fortran, as gnuplot 6.0 (fit c*h**p, print): the same parameters, errors, WSSR and iterations to 15 digits
block
   real(R8P)        :: h(5) = [0.1_R8P, 0.05_R8P, 0.025_R8P, 0.0125_R8P, 0.00625_R8P] !< Mesh sizes.
   real(R8P)        :: e(5) = [2.10e-3_R8P, 5.30e-4_R8P, 1.29e-4_R8P, 3.33e-5_R8P, 8.20e-6_R8P] !< Errors.
   real(R8P)        :: q(2) !< Parameters.
   type(fit_result) :: r    !< Outcome.

   q = 1.0_R8P
   call fit(power_law, h, e, q, names=['c', 'p'], result=r)
   test_passed(97) = len(r%message) == 0 .and. near15(q(1), 0.206069615792187_R8P) .and. &
                     near15(q(2), 1.99174433662703_R8P) .and. near15(r%errors(1), 0.00296226159940231_R8P) .and. &
                     near15(r%errors(2), 0.00611411344647372_R8P) .and. r%ndf == 3 .and. &
                     near15(r%wssr, 1.80725180545772e-11_R8P) .and. near15(r%stdfit, 2.45441901167243e-06_R8P) .and. &
                     r%niter == 9 .and. r%converged
   ! a zero start is 1e-30, unscaled, as gnuplot: 69 iterations to the same minimum
   q = [0.0_R8P, 1.0_R8P]
   call fit(power_law, h, e, q, result=r)
   test_passed(97) = test_passed(97) .and. len(r%message) == 0 .and. near15(q(1), 0.206069699039651_R8P) .and. &
                     near15(q(2), 1.9917445095641_R8P) .and. r%niter == 69
endblock
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
write(output_unit, '(A,97L2)') 'foresight_script checks:', test_passed
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

   function consecutive(file, starts) result(ok)
   !< Whether the first non-blank words of three consecutive lines of `file` are `starts`, in order.
   character(len=*), intent(in) :: file      !< Text file.
   character(len=*), intent(in) :: starts(3) !< First words of the lines.
   logical                      :: ok        !< Found.
   character(len=200)           :: lines(3)  !< Last three lines.
   integer(I4P)                 :: u         !< Unit.
   integer(I4P)                 :: ios       !< I/O status.

   ok = .false.
   lines = ''
   open(newunit=u, file=file, action='read', iostat=ios)
   if (ios /= 0_I4P) return
   do
      lines(1:2) = lines(2:3)
      read(u, '(A)', iostat=ios) lines(3)
      if (ios /= 0_I4P) exit
      if (index(adjustl(lines(1)), trim(starts(1))) == 1 .and. index(adjustl(lines(2)), trim(starts(2))) == 1 .and. &
          index(adjustl(lines(3)), trim(starts(3))) == 1) then
         ok = .true.
         exit
      endif
   enddo
   close(u)
   endfunction consecutive

   elemental function near15(a, b) result(close)
   !< Whether `a` is `b` to 1e-10 relative: fits match gnuplot's 15 printed digits with gfortran, 12 to 14 with
   !< nvfortran (its x**p rounds differently in the last bit).
   real(R8P), intent(in) :: a     !< Value.
   real(R8P), intent(in) :: b     !< Reference.
   logical               :: close !< Close.

   close = abs(a - b) <= 1.0e-10_R8P * max(1.0e-300_R8P, abs(b))
   endfunction near15

   function power_law(x, q) result(f)
   !< c * x**p, the model of the fit check.
   real(R8P), intent(in) :: x    !< Mesh size.
   real(R8P), intent(in) :: q(:) !< c, p.
   real(R8P)             :: f    !< Error.

   f = q(1) * x**q(2)
   endfunction power_law

   elemental function near(a, b) result(close)
   !< Whether `a` is `b` to 1e-5 relative (gnuplot prints 6 significant digits).
   real(R8P), intent(in) :: a     !< Value.
   real(R8P), intent(in) :: b     !< Reference.
   logical               :: close !< Close.

   close = abs(a - b) <= 1.0e-5_R8P * max(1.0_R8P, abs(b))
   endfunction near

   function colorbox_labels(settings, present_labels, absent_labels) result(ok)
   !< Plot the data file as an image after `settings` into an SVG, and whether its texts include every one of
   !< `present_labels` and none of `absent_labels` (blanks trimmed).
   character(len=*), intent(in)  :: settings          !< Commands before the plot.
   character(len=*), intent(in)  :: present_labels(:) !< Texts expected.
   character(len=*), intent(in)  :: absent_labels(:)  !< Texts not expected.
   logical                       :: ok                !< As expected.
   character(len=:), allocatable :: svg               !< Rendered SVG.
   integer(I4P)                  :: k                 !< Label counter.
   integer(I4P)                  :: u                 !< File unit.

   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg; set output 'foresight_script_test_cb.svg'; "//settings// &
                             "; plot '"//data_file//"' u 1:2:3 w image notitle", iostat, iomsg)
   ok = iostat == 0_I4P
   if (.not. ok) then
      write(error_unit, '(A)') 'colorbox_labels: '//iomsg
      return
   endif
   svg = read_text('foresight_script_test_cb.svg')
   do k = 1_I4P, size(present_labels, kind=I4P)
      ok = ok .and. index(svg, '>'//trim(present_labels(k))//'<') > 0
   enddo
   do k = 1_I4P, size(absent_labels, kind=I4P)
      ok = ok .and. index(svg, '>'//trim(absent_labels(k))//'<') == 0
   enddo
   open(newunit=u, file='foresight_script_test_cb.svg')
   close(u, status='delete')
   endfunction colorbox_labels

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
