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
use foresight_style, only : FILL_EMPTY, FILL_SOLID, WITH_BOXES, WITH_FILLEDCURVES, WITH_HISTOGRAMS, WITH_LINES, &
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
logical                       :: test_passed(58)                           !< Per-check outcome.
real(R8P)                     :: xmin                                      !< Data extent start.
real(R8P)                     :: xmax                                      !< Data extent end.
real(R8P)                     :: ymin(2)                                   !< Data extent bottoms.
real(R8P)                     :: ymax(2)                                   !< Data extent tops.
logical                       :: found(2)                                  !< Data per y axis.

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
test_passed(25) = iostat /= 0_I4P .and. index(iomsg, 'a function is drawn with lines, points or linespoints') > 0
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
test_passed(47) = iostat /= 0_I4P .and. index(iomsg, 'format applies to readouts only') > 0
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
test_passed(50) = iostat /= 0_I4P .and. index(iomsg, 'fs applies to boxes, filledcurves and histograms only') > 0
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
write(output_unit, '(A,58L2)') 'foresight_script checks:', test_passed
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
