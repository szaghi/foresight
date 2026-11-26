!< foresight_script test: gnuplot scripts rendered byte-exact, `using` expressions, functions, CSV data, the second y
!< axis, and unsupported constructs reported as errors.
program foresight_script_test
!< foresight_script test: gnuplot scripts rendered byte-exact, `using` expressions, functions, CSV data, the second y
!< axis, and unsupported constructs reported as errors.
!<
!< Run from the repository root; `FORESIGHT_UPDATE_GOLDEN=1` rewrites the reference file.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite, ieee_is_nan
use, intrinsic :: iso_fortran_env, only : error_unit, output_unit
use foresight, only : figure_object, fit, fit_result, I4P, I8P, R8P, script_object, stats, stats_result
use foresight_backend, only : arrow_head, sized_head
use foresight_expression, only : value_object
use foresight_font, only : font_object, font_of
use foresight_ticks, only : MINOR_AUTO, TICS_FIXED, TICS_NONE
use foresight_style, only : default_color, FILL_EMPTY, FILL_PATTERN, FILL_SOLID, WITH_IMAGE, WITH_FILLSTEPS, &
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
integer(I8P)                  :: start_count                               !< Clock at the start of a timed check.
integer(I8P)                  :: end_count                                 !< Clock at its end.
integer(I8P)                  :: count_rate                                !< Clock ticks per second.
integer(I4P)                  :: i                                         !< Counter.
logical                       :: test_passed(280)                           !< Per-check outcome.
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
         "     '' u 1:3 w lp lw 2 ps 0.75 lc rgb '#e51e10' notitle"//new_line('a')
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
call interpreter%run_text('set grid'//new_line('a')//'sumplot x', iostat, iomsg, source='t.gp')
test_passed(6) = iostat /= 0_I4P .and. iomsg == 't.gp:2: unsupported command "sumplot"'
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
call interpreter%run_text("set format q '%g'", iostat, iomsg)
test_passed(16) = iostat /= 0_I4P .and. index(iomsg, 'axes must be among x, y, y2') > 0
call interpreter%run_text("set format y '%d'", iostat, iomsg)
test_passed(17) = iostat /= 0_I4P .and. index(iomsg, 'unsupported conversion "%d"') > 0
call interpreter%run_text('set key sparkle 2', iostat, iomsg)
test_passed(18) = iostat /= 0_I4P .and. index(iomsg, 'set key: unsupported option "sparkle"') > 0
call interpreter%run_text("plot '"//data_file//"' every 0", iostat, iomsg)
test_passed(19) = iostat /= 0_I4P .and. index(iomsg, 'positive increments') > 0
call interpreter%run_text('set style line 1 sparkle 2', iostat, iomsg)
test_passed(20) = iostat /= 0_I4P .and. index(iomsg, 'set style line: unsupported option "sparkle"') > 0

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
test_passed(34) = test_passed(34) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%zaxis%log
call interpreter%run_text('set logscale q', iostat, iomsg)
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

! point types: in an item, in a line style, the long form; never negative; without pt the item's linetype, as gnuplot
call interpreter%init(scratch)
call interpreter%run_text("set style line 3 pt 6 ps 2; plot x w p pt 7, x w lp ls 3, x w p pointtype 12, x w p", &
                          iostat, iomsg)
test_passed(43) = iostat == 0_I4P
if (test_passed(43)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(43) = series(1)%style%pointtype == 7_I4P .and. series(2)%style%pointtype == 6_I4P .and. &
                        series(2)%style%pointsize == 2.0_R8P .and. series(3)%style%pointtype == 12_I4P .and. &
                        series(4)%style%pointtype == 4_I4P
   endassociate
endif
! gnuplot 6.0: lt 1..8 and ls of a predefined linetype give its point type, a higher lt the item's own, a style of
! a higher number without pt or lt point type 1, a keyentry takes the next item's linetype without using it up
call interpreter%run_text("set style line 12 lc rgb 'red'; set style line 2 lt 4; plot x w p lt 5, x w p lt 12, "// &
                          "x w p ls 12, x w p ls 2, x w l, x w p, keyentry w p t 'k', x w p", iostat, iomsg)
test_passed(43) = test_passed(43) .and. iostat == 0_I4P
if (test_passed(43)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(43) = all(series([1, 2, 3, 4, 6, 7, 8])%style%pointtype == [5, 2, 1, 4, 6, 7, 7]) .and. &
                        series(5)%style%pointtype == -1_I4P
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
                        panel%series(2)%style%color == '#ff0000' .and. panel%readout_h == 'right' .and. &
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
                        series(2)%style%fill == FILL_EMPTY .and. series(2)%style%stroke_color() == '#ff0000'
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
call interpreter%run_text("plot '"//data_file//"' w filledcurves above x=1", iostat, iomsg)
test_passed(50) = test_passed(50) .and. iostat /= 0_I4P .and. index(iomsg, 'above and below apply to y=V and bands') > 0
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
call interpreter%run_text("set style histogram stacked", iostat, iomsg)
test_passed(53) = test_passed(53) .and. iostat /= 0_I4P .and. index(iomsg, 'unsupported option "stacked"') > 0
call interpreter%run_text("plot '"//data_file//"' u 2:xtic(a) w hist", iostat, iomsg)
test_passed(53) = test_passed(53) .and. iostat /= 0_I4P .and. index(iomsg, 'xtic: undefined variable: a') > 0
call interpreter%run_text("plot '"//data_file//"' u 2:ztic(1) w hist", iostat, iomsg)
test_passed(53) = test_passed(53) .and. iostat /= 0_I4P .and. index(iomsg, 'field "ztic(1)" is neither') > 0
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
test_passed(58) = iostat /= 0_I4P .and. index(iomsg, 'set palette: functions R, G, B expected') > 0
call interpreter%run_text("set palette fit2rgbformulae", iostat, iomsg)
test_passed(58) = test_passed(58) .and. iostat /= 0_I4P .and. &
                  index(iomsg, 'set palette: unsupported option "fit2rgbformulae"') > 0
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
! a matrix with another style: its rows x y z, as gnuplot's
call interpreter%run_text("plot '"//data_file//"' matrix w lines", iostat, iomsg)
test_passed(58) = test_passed(58) .and. iostat == 0_I4P
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
call interpreter%run_text("set rrange [3:3]", iostat, iomsg)
test_passed(66) = test_passed(66) .and. iostat /= 0_I4P .and. index(iomsg, 'an empty range') > 0
call interpreter%run_text("set ttics 0,-30", iostat, iomsg)
test_passed(66) = test_passed(66) .and. iostat /= 0_I4P .and. index(iomsg, 'set ttics: supported forms') > 0
call interpreter%run_text("set size ratio square", iostat, iomsg)
test_passed(66) = test_passed(66) .and. iostat /= 0_I4P .and. index(iomsg, 'ratio needs a number') > 0
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
test_passed(68) = test_passed(68) .and. iostat /= 0_I4P .and. index(iomsg, 'dots, boxes, filledcurves or pm3d') > 0
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
                        panel%series(5)%text_point .and. panel%series(5)%text_color == '#ff0000' .and. &
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
call interpreter%run_text("plot '"//data_file//"' u 1:2:(1/0) w labels", iostat, iomsg)
test_passed(72) = test_passed(72) .and. iostat == 0_I4P
call interpreter%run_text("plot '"//data_file//"' u 1:2:3 w ellipses units xz", iostat, iomsg)
test_passed(72) = test_passed(72) .and. iostat /= 0_I4P .and. index(iomsg, 'units xy, xx or yy') > 0
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
test_passed(74) = test_passed(74) .and. iostat /= 0_I4P .and. index(iomsg, 'filledcurves r=V applies to polar plots') &
                   > 0
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
call interpreter%run_text("set palette file '"//data_file//"' using 1", iostat, iomsg)
test_passed(77) = test_passed(77) .and. iostat /= 0_I4P .and. index(iomsg, 'r:g:b, gray:r:g:b or gray:rgb') > 0
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
call interpreter%run_text("fact(n) = n <= 1 ? 1 : n*fact(n-1); r = fact(6)", iostat, iomsg)
test_passed(81) = test_passed(81) .and. iostat == 0_I4P
block
   real(R8P) :: r     !< fact(6).
   logical   :: found !< Defined.

   call interpreter%symbols%value_of('r', r, found)
   test_passed(81) = test_passed(81) .and. found .and. r == 720.0_R8P
endblock
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
call interpreter%run_text('set ztics rotate', iostat, iomsg)
test_passed(84) = test_passed(84) .and. iostat /= 0_I4P .and. &
                  index(iomsg, 'rotate is supported on xtics, x2tics, ytics, y2tics and rtics only') > 0
call interpreter%run_text('set cbtics out', iostat, iomsg)
test_passed(84) = test_passed(84) .and. iostat /= 0_I4P .and. index(iomsg, 'in and out are supported on xtics') > 0
! a justification of unrotated labels is read (gnuplot also moves them), kept for a rotation
call interpreter%run_text('set xtics right', iostat, iomsg)
test_passed(84) = test_passed(84) .and. iostat == 0_I4P .and. &
                  interpreter%figure%panels(1)%xaxis%tics%attribute() == '* 5 *'
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
test_passed(85) = test_passed(85) .and. iostat == 0_I4P
if (test_passed(85)) test_passed(85) = interpreter%figure%panels(1)%series(2)%x(1) == 0.0_R8P .and. &
                                       interpreter%figure%panels(1)%series(2)%x(size(interpreter%figure%panels(1)%series(2)%x)) &
                                       == 1.0_R8P
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
call interpreter%run_text("plot '"//data_file//"' u 1:2:3 w steps lc variable", iostat, iomsg)
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
call interpreter%run_text('set cbtics rotate', iostat, iomsg)
test_passed(89) = test_passed(89) .and. iostat /= 0_I4P .and. &
                  index(iomsg, 'rotate is supported on xtics, x2tics, ytics, y2tics and rtics only') > 0

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
call interpreter%run_text("plot '"//data_file//"' u 1:2:3 w steps lc palette z", iostat, iomsg)
test_passed(93) = test_passed(93) .and. iostat /= 0_I4P .and. index(iomsg, 'lc palette z applies to lines') > 0
call interpreter%run_text("plot '"//data_file//"' u 1:2 w l lc palette viridis", iostat, iomsg)
test_passed(93) = test_passed(93) .and. iostat /= 0_I4P .and. index(iomsg, 'no colormap "viridis"') > 0
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

! fit in scripts, as gnuplot 6.0 (print after fit): the parameters (undefined ones start at 1), their _err, FIT_*;
! a third using column (or yerrors) weights the points; [min:max] restricts x; silent; a log file on request
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 2.1 0.1', '2 3.9 0.2', '3 6.2 0.1', '4 7.8 0.3', '5 10.1 0.2'
close(unit)
call interpreter%init(scratch)
block
   real(R8P) :: v(8) !< Variable values.
   logical   :: ok   !< All found.

   call interpreter%run_text("fit m*x+q '"//data_file//"' using 1:2 via m, q", iostat, iomsg)
   test_passed(98) = iostat == 0_I4P
   call values(['m       ', 'q       ', 'm_err   ', 'q_err   ', 'FIT_WSSR', 'FIT_NITE', 'FIT_NDF ', 'FIT_CONV'], v, ok)
   test_passed(98) = test_passed(98) .and. ok .and. near15(v(1), 1.98999999990952_R8P) .and. &
                     near15(v(2), 0.050000000326559_R8P) .and. near15(v(3), 0.0597215762239003_R8P) .and. &
                     near15(v(4), 0.198074060222589_R8P) .and. near15(v(5), 0.107_R8P) .and. v(6) == 4.0_R8P .and. &
                     v(7) == 3.0_R8P .and. v(8) == 1.0_R8P
   call interpreter%run_text("m = 1; q = 1; fit m*x+q '"//data_file//"' using 1:2:3 via m, q", iostat, iomsg)
   call values(['m       ', 'q       ', 'm_err   ', 'q_err   ', 'FIT_WSSR', 'FIT_P   ', 'FIT_NITE', 'FIT_NDF '], v, ok)
   test_passed(98) = test_passed(98) .and. iostat == 0_I4P .and. ok .and. near15(v(1), 2.00626151010991_R8P) .and. &
                     near15(v(2), 0.0915285451764245_R8P) .and. near15(v(3), 0.0478216551485147_R8P) .and. &
                     near15(v(4), 0.129093971639277_R8P) .and. near15(v(5), 2.97237569060776_R8P) .and. &
                     abs(v(6) - 0.395903940519543_R8P) < 1.0e-12_R8P
   call interpreter%run_text("m = 1; q = 1; fit [2:4] m*x+q '"//data_file//"' using 1:2 via m, q", iostat, iomsg)
   call values(['m       ', 'q       ', 'FIT_NDF '], v(1:3), ok)
   test_passed(98) = test_passed(98) .and. iostat == 0_I4P .and. ok .and. near15(v(1), 1.94999999430012_R8P) .and. &
                     near15(v(2), 0.116666684913463_R8P) .and. v(3) == 1.0_R8P
   call interpreter%run_text("fit zz*x '"//data_file//"' via zz", iostat, iomsg)
   call values(['zz      '], v(1:1), ok)
   test_passed(98) = test_passed(98) .and. iostat == 0_I4P .and. ok .and. near15(v(1), 2.00363636363636_R8P)
   ! a log file appended on request, gnuplot's layout
   call interpreter%run_text("set fit logfile 'foresight_script_test_fit.log'; m = 1; q = 1; "// &
                             "fit m*x+q '"//data_file//"' via m, q", iostat, iomsg)
   test_passed(98) = test_passed(98) .and. iostat == 0_I4P .and. &
                     consecutive('foresight_script_test_fit.log', ['Final  ', '=======', 'm      '])
   open(newunit=unit, file='foresight_script_test_fit.log')
   close(unit, status='delete')
endblock
call interpreter%run_text("set fit nologfile; m = 0; q = 1; fit m*x+q '"//data_file//"' via m, q", iostat, iomsg)
test_passed(98) = test_passed(98) .and. iostat /= 0_I4P .and. index(iomsg, 'Singular matrix in Invert_RtR') > 0
call interpreter%run_text("fit m*x+q '"//data_file//"'", iostat, iomsg)
test_passed(98) = test_passed(98) .and. iostat /= 0_I4P .and. index(iomsg, 'via and the names of the parameters') > 0
! a parameter file that cannot be read (check 264 reads one)
call interpreter%run_text("fit m*x+q '"//data_file//"' via 'p.par'", iostat, iomsg)
test_passed(98) = test_passed(98) .and. iostat /= 0_I4P .and. index(iomsg, 'cannot read the parameter file') > 0
call interpreter%run_text("set fit verbose", iostat, iomsg)
test_passed(98) = test_passed(98) .and. iostat /= 0_I4P .and. index(iomsg, 'unsupported option "verbose"') > 0
call interpreter%run_text("fit m*x+q '"//data_file//"' using 1 via m, q", iostat, iomsg)
test_passed(98) = test_passed(98) .and. iostat /= 0_I4P .and. index(iomsg, 'using X:Z, X:Z:S, X:Y:Z:S') > 0
call interpreter%run_text("set fit limit 1e-9 maxiter 3 results noerrorvariables", iostat, iomsg)
test_passed(98) = test_passed(98) .and. iostat == 0_I4P .and. interpreter%fit_options%limit == 1.0e-9_R8P .and. &
                  interpreter%fit_options%maxiter == 3_I4P .and. interpreter%fit_verbosity == 'results' .and. &
                  .not. interpreter%fit_errorvariables
call interpreter%run_text("set fit", iostat, iomsg)
test_passed(98) = test_passed(98) .and. iostat == 0_I4P .and. interpreter%fit_verbosity == 'quiet'
open(newunit=unit, file=scratch)
close(unit, status='delete')
open(newunit=unit, file=scratch)
close(unit, status='delete')

open(newunit=unit, file=data_file)
close(unit, status='delete')
open(newunit=unit, file=csv_file)
close(unit, status='delete')
! print, as gnuplot 6.0: values separated by a blank (reals as %.15g, .0 when integral), to set print's file
call interpreter%init(scratch)
call interpreter%run_text("set print 'foresight_script_test_print.txt'; s = sprintf('%.3f', pi); "// &
                          "print s, 1/3., 100.0, 7, ""a"" . 'b'; print 'x\ty', ""x\ty""; "// &
                          "set print 'foresight_script_test_print.txt' append; print 2**63; set print", iostat, iomsg)
test_passed(99) = iostat == 0_I4P .and. interpreter%print_file == '' .and. &
                  file_is('foresight_script_test_print.txt', &
                          [character(len=40) :: '3.142 0.333333333333333 100.0 7 ab', 'x\ty x'//achar(9)//'y', &
                           '9.22337203685478e+18'])
call interpreter%run_text("set print 'foresight_script_test_print.txt'; print 1", iostat, iomsg)
test_passed(99) = test_passed(99) .and. file_is('foresight_script_test_print.txt', [character(len=1) :: '1'])
call interpreter%run_text("print", iostat, iomsg)
test_passed(99) = test_passed(99) .and. iostat /= 0_I4P .and. index(iomsg, 'print: an expression is expected') > 0
call interpreter%run_text("print 1/0", iostat, iomsg)
test_passed(99) = test_passed(99) .and. iostat /= 0_I4P .and. index(iomsg, 'print: undefined value: 1/0') > 0
call interpreter%run_text("print 'a' + 1", iostat, iomsg)
test_passed(99) = test_passed(99) .and. iostat /= 0_I4P .and. index(iomsg, 'non-numeric string') > 0
call interpreter%run_text("unset print; set print 'a' b", iostat, iomsg)
test_passed(99) = test_passed(99) .and. iostat /= 0_I4P .and. interpreter%print_file == '' .and. &
                  index(iomsg, 'set print: "file" [append] or "-" expected') > 0
open(newunit=unit, file='foresight_script_test_print.txt')
close(unit, status='delete')

! string expressions wherever a string goes, as gnuplot 6.0: set options, plot file names and titles
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 2 3', '2 3 4', '3 4 5'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("i = 2; name = 'foresight_script_test_strings'; d = '"//data_file//"'"//new_line('a')// &
                          "set terminal svg size 300,200; set output name . '.svg'"//new_line('a')// &
                          "set title sprintf('run %d', i); set xlabel 'x' . ' [m]'; set format y '%' . '.1f'"// &
                          new_line('a')//"plot d u 1:2 t 'col' . i, d[1:3] . d[4:] u 1:3, '' u 1:2 notitle", &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(100) = iostat == 0_I4P
if (test_passed(100)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(100) = interpreter%output == 'foresight_script_test_strings.svg' .and. panel%title == 'run 2' .and. &
                         panel%xaxis%label == 'x [m]' .and. panel%yaxis%tics%format == '%.1f' .and. &
                         size(panel%series) == 3
      if (test_passed(100)) test_passed(100) = panel%series(1)%title == 'col2' .and. &
                                               panel%series(2)%title == 'd[1:3] . d[4:] u 1:3' .and. &
                                               panel%series(3)%y(3) == 4.0_R8P .and. panel%series(2)%y(3) == 5.0_R8P
   endassociate
endif
call interpreter%run_text("set title 5", iostat, iomsg)
test_passed(100) = test_passed(100) .and. iostat /= 0_I4P .and. &
                   index(iomsg, 'set title: a string is expected, found the number 5') > 0
call interpreter%run_text("set output 'a' 'b'", iostat, iomsg)
test_passed(100) = test_passed(100) .and. iostat /= 0_I4P .and. index(iomsg, 'unexpected "b" after the string') > 0
call interpreter%run_text("plot x t 3", iostat, iomsg)
test_passed(100) = test_passed(100) .and. iostat /= 0_I4P .and. &
                   index(iomsg, 'plot: title: a string is expected, found the number 3') > 0
call interpreter%run_text("set format zz '%g'", iostat, iomsg)
test_passed(100) = test_passed(100) .and. iostat /= 0_I4P .and. index(iomsg, 'axes must be among') > 0
open(newunit=unit, file='foresight_script_test_strings.svg')
close(unit, status='delete')
open(newunit=unit, file=data_file)
close(unit, status='delete')

! blocks and flow control, as gnuplot 6.0 (the printed lines of the same script)
call interpreter%init(scratch)
call interpreter%run_text("set print 'foresight_script_test_blocks.txt'"//new_line('a')// &
                          "do for [i=1:10:4] { print i }"//new_line('a')// &
                          "i = 7; do for [i=1:2] { }; print i"//new_line('a')// &
                          "do for [i=3:1] { print i }; print 'end'"//new_line('a')// &
                          "do for [i=3:1:-1] { print i }"//new_line('a')// &
                          "do for [s in ""a bb c""] { print s }"//new_line('a')// &
                          "do for [i=1:2] {"//new_line('a')// &
                          achar(9)//"do for [j=1:2] {"//new_line('a')// &
                          "      print i, j   # a comment {"//new_line('a')// &
                          "   }"//new_line('a')// &
                          "}"//new_line('a')// &
                          "do for [i=1:3] { if (i==2) { continue }; print i }"//new_line('a')// &
                          "do for [i=1:3] { if (i==2) { break }; print i }"//new_line('a')// &
                          "do for [x=0.5:2] { print x }"//new_line('a')// &
                          "do for [w in 'x y'] for [i=1:2] { print w, i }"//new_line('a')// &
                          "k=0; while (k<3) { k=k+1; print k }"//new_line('a')// &
                          "if (0) { print 'y' } else if (1) { print 'm' } else { print 'n' }"//new_line('a')// &
                          "do for [i=1:3] { i = 10; print i }"//new_line('a')// &
                          "print exists('j'), exists('w')"//new_line('a')// &
                          "set print", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(101) = iostat == 0_I4P .and. &
   file_is('foresight_script_test_blocks.txt', [character(len=5) :: '1', '5', '9', '7', 'end', '3', '2', '1', 'a', 'bb', &
           'c', '1 1', '1 2', '2 1', '2 2', '1', '3', '1', '0', '1', '2', 'x 1', 'x 2', 'y 1', 'y 2', '1', '2', '3', 'm', &
           '10', '10', '10', '0 0'])
call interpreter%run_text("break", iostat, iomsg)
test_passed(101) = test_passed(101) .and. iostat /= 0_I4P .and. index(iomsg, 'break outside a loop') > 0
call interpreter%run_text("if (1)", iostat, iomsg)
test_passed(101) = test_passed(101) .and. iostat /= 0_I4P .and. index(iomsg, '{ ... } or a command expected') > 0
call interpreter%run_text("do for [i=1:2] {"//new_line('a')//"print i", iostat, iomsg)
test_passed(101) = test_passed(101) .and. iostat /= 0_I4P .and. index(iomsg, 'script:1: "{" not closed') > 0
call interpreter%run_text("do for [i=1:*] { }", iostat, iomsg)
test_passed(101) = test_passed(101) .and. iostat /= 0_I4P .and. index(iomsg, 'unbounded iteration') > 0
call interpreter%run_text("if ('a') { }", iostat, iomsg)
test_passed(101) = test_passed(101) .and. iostat /= 0_I4P .and. index(iomsg, 'a string used as a condition') > 0
call interpreter%run_text("do for [i=1:2] { print undefined_name }", iostat, iomsg)
test_passed(101) = test_passed(101) .and. iostat /= 0_I4P .and. index(iomsg, 'undefined variable: undefined_name') > 0
open(newunit=unit, file='foresight_script_test_blocks.txt')
close(unit, status='delete')

! plot for, as gnuplot 6.0: an item per value, titles as written, colors advancing, '' the previous file
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '1 1 2 3', '2 2 3 4', '3 3 4 5'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("plot for [i=2:4] '"//data_file//"' u 1:i w l", iostat, iomsg)
test_passed(102) = iostat == 0_I4P
if (test_passed(102)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(102) = size(panel%series) == 3
      if (test_passed(102)) test_passed(102) = panel%series(1)%title == "'"//data_file//"' u 1:i" .and. &
                                               panel%series(3)%y(3) == 5.0_R8P .and. &
                                               panel%series(1)%style%color == '#9400d3' .and. &
                                               panel%series(3)%style%color == '#56b4e9'
   endassociate
endif
call interpreter%run_text("plot for [i=2:3] '"//data_file//"' u 1:i t sprintf('col %d', i) lc i, "// &
                          "for [i=4:2:-1] '' u 1:i, for [f in '"//data_file//" "//data_file//"'] f u 1:2, "// &
                          "for [i=3:1] x, for [i=1:2] for [j=1:2] i*j*x", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(102) = test_passed(102) .and. iostat == 0_I4P
if (test_passed(102)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(102) = size(panel%series) == 11
      if (test_passed(102)) test_passed(102) = panel%series(1)%title == 'col 2' .and. &
                                               panel%series(2)%title == 'col 3' .and. &
                                               panel%series(1)%style%color == '#009e73' .and. &
                                               panel%series(2)%style%color == '#56b4e9' .and. &
                                               panel%series(3)%y(1) == 3.0_R8P .and. panel%series(5)%y(1) == 1.0_R8P .and. &
                                               panel%series(6)%title == 'f u 1:2' .and. &
                                               panel%series(11)%title == 'i*j*x'
   endassociate
endif
block
   real(R8P) :: v     !< Value.
   logical   :: found !< Variable found.

   call interpreter%symbols%value_of('i', v, found)
   test_passed(102) = test_passed(102) .and. .not. found
endblock
! bounds depending on an outer variable: evaluated again as it moves (gnuplot's; check 268), three items
call interpreter%run_text("plot for [i=1:2] for [j=1:i] x", iostat, iomsg)
test_passed(102) = test_passed(102) .and. iostat == 0_I4P .and. size(interpreter%figure%panels(1)%series) == 3
open(newunit=unit, file=data_file)
close(unit, status='delete')

! stats, as gnuplot 6.0: the variables and the report of a set print file, byte for byte gnuplot's own (the golden),
! blank lines, invalid records and ranges counted
open(newunit=unit, file='foresight_script_test_stats.dat', action='write', status='replace')
write(unit, '(A)') '# h', '1 2.5', '2 3.5', '3 1.0', '', '4 7.0', '5 NaN', '6 -1'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text("set print 'foresight_script_test_stats.txt'"//new_line('a')// &
                          "stats 'foresight_script_test_stats.dat' using 2 output"//new_line('a')// &
                          "stats 'foresight_script_test_stats.dat' u 1:2 name 'B' output"//new_line('a')// &
                          "print STATS_records, STATS_mean, B_slope, B_pos_max_y, STATS_index_max"//new_line('a')// &
                          "set print", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(103) = iostat == 0_I4P .and. same_file('foresight_script_test_stats.txt', 'src/tests/goldens/stats_print.txt')
block
   real(R8P) :: v(4)  !< Values.
   logical   :: found !< Variable found.
   logical   :: whole !< Integer.

   call interpreter%symbols%value_of('STATS_stddev', v(1), found)
   call interpreter%symbols%value_of('B_correlation', v(2), found)
   call interpreter%symbols%value_of('B_kurtosis_x', v(3), found)
   call interpreter%symbols%value_of('STATS_invalid', v(4), found, whole)
   test_passed(103) = test_passed(103) .and. near15(v(1), 2.67207784317748_R8P) .and. &
                      near15(v(2), -0.308882556392762_R8P) .and. near15(v(3), 1.9945215485756_R8P) .and. &
                      v(4) == 1.0_R8P .and. whole
endblock
call interpreter%run_text("stats [2:5] 'foresight_script_test_stats.dat' u 1:2 name 'R'; stats 'nope.dat' u 2", &
                          iostat, iomsg)
block
   real(R8P) :: v(3)  !< Values.
   logical   :: found !< Variable found.

   call interpreter%symbols%value_of('R_records', v(1), found)
   call interpreter%symbols%value_of('R_outofrange', v(2), found)
   call interpreter%symbols%value_of('R_mean_x', v(3), found)
   test_passed(103) = test_passed(103) .and. iostat == 0_I4P .and. &
                      v(1) == 3.0_R8P .and. v(2) == 2.0_R8P .and. v(3) == 3.0_R8P
endblock
call interpreter%run_text("stats 'foresight_script_test_stats.dat' u 2 name '1x'", iostat, iomsg)
test_passed(103) = test_passed(103) .and. iostat /= 0_I4P .and. index(iomsg, 'illegal prefix "1x"') > 0
open(newunit=unit, file='foresight_script_test_stats.dat')
close(unit, status='delete')
open(newunit=unit, file='foresight_script_test_stats.txt')
close(unit, status='delete')

! stats from Fortran, as gnuplot 6.0 (stats ... nooutput, then show variables)
block
   real(R8P)          :: x(5) = [1.0_R8P, 2.0_R8P, 3.0_R8P, 4.0_R8P, 6.0_R8P] !< First column.
   real(R8P)          :: y(5) = [2.5_R8P, 3.5_R8P, 1.0_R8P, 7.0_R8P, -1.0_R8P] !< Second column.
   type(stats_result) :: r !< Statistics.

   r = stats(y)
   test_passed(104) = r%records == 5_I4P .and. near15(r%y%ssd, 2.98747384925793_R8P) .and. &
                      near15(r%y%skewness, 0.368579812184168_R8P) .and. near15(r%y%kurtosis_err, 2.19089023002066_R8P) .and. &
                      r%y%median == 2.5_R8P .and. r%y%lo_quartile == 1.0_R8P .and. r%y%index_min == 4_I4P .and. .not. r%two
   r = stats(x, y)
   test_passed(104) = test_passed(104) .and. r%two .and. near15(r%slope, -0.47972972972973_R8P) .and. &
                      near15(r%intercept_err, 3.09853107354641_R8P) .and. near15(r%x%stddev_err, 0.544058820349418_R8P) &
                      .and. r%pos_min_y == 6.0_R8P .and. r%pos_max_y == 4.0_R8P .and. r%sumxy == 34.5_R8P
endblock

! string columns, as gnuplot 6.0: strcol/stringcolumn (number or header name), columnhead(N), the pseudo-columns -1
! (block) and -2 (dataset), string fields of labels and xtic
open(newunit=unit, file='foresight_script_test_strings.dat', action='write', status='replace')
write(unit, '(A)') 'name value err', '"alpha one" 1.5 0.2', 'beta 2.5 0.3', '', 'gamma 3 0.1', '', '', 'delta 4 0.5'
close(unit)
call interpreter%run_text("set output 'foresight_script_test_strings.svg'", iostat, iomsg)
call interpreter%run_text("plot 'foresight_script_test_strings.dat' u 0:(strcol(1) eq 'beta' ? $2 : 1/0), "// &
                          "'' u 0:(strlen(stringcolumn(1))), '' u (column(-1)):(column(-2)), "// &
                          "'' u 0:2:xtic(strcol(1) . '!'), '' u 2:3:(sprintf('%s=%g', strcol(1), $2)) w labels, "// &
                          "'' u 2:3:($3*2) w labels, '' u 0:(strcol('value') eq '3' ? 1 : 0), "// &
                          "'' u 0:2:xtic(columnhead(3))", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(105) = iostat == 0_I4P
if (test_passed(105)) then
   associate(panel => interpreter%figure%panels(1))
      ! the header row is a row (no header used): an invalid point, as gnuplot's
      test_passed(105) = same(panel%series(1)%y * 10.0_R8P, [-1, -1, 25, -1, -1, -1, -1])
      test_passed(105) = test_passed(105) .and. same(panel%series(2)%y, [4, 9, 4, -1, 5, -1, 5])
      test_passed(105) = test_passed(105) .and. same(panel%series(3)%x, [0, 0, 0, -1, 1, -1, 0]) .and. &
                         same(panel%series(3)%y, [0, 0, 0, -1, 0, -1, 1])
      test_passed(105) = test_passed(105) .and. trim(panel%series(4)%xlabels(1)) == 'alpha one!' .and. &
                         trim(panel%series(4)%xlabels(2)) == 'beta!'
      test_passed(105) = test_passed(105) .and. trim(panel%series(5)%texts(1)) == 'alpha one=1.5' .and. &
                         trim(panel%series(6)%texts(1)) == '0.2' .and. trim(panel%series(8)%xlabels(1)) == 'err'
      test_passed(105) = test_passed(105) .and. same(panel%series(7)%y, [0, 0, 0, -1, 1, -1, -1])
   endassociate
endif
call interpreter%run_text("plot 'foresight_script_test_strings.dat' u 0:(strcol(1, 2))", iostat, iomsg)
test_passed(105) = test_passed(105) .and. iostat /= 0_I4P .and. index(iomsg, 'strcol needs 1 argument') > 0
call interpreter%run_text("plot strcol(1)", iostat, iomsg)
test_passed(105) = test_passed(105) .and. iostat /= 0_I4P .and. index(iomsg, 'only valid in using') > 0
call interpreter%run_text("stats 'foresight_script_test_strings.dat' u (strcol(1) ne 'delta' ? $2 : 1/0) nooutput", &
                          iostat, iomsg)
block
   real(R8P) :: v(2)  !< Values.
   logical   :: found !< Variable found.

   call interpreter%symbols%value_of('STATS_records', v(1), found)
   call interpreter%symbols%value_of('STATS_max', v(2), found)
   test_passed(105) = test_passed(105) .and. iostat == 0_I4P .and. v(1) == 3.0_R8P .and. v(2) == 3.0_R8P
endblock
open(newunit=unit, file='foresight_script_test_strings.dat')
close(unit, status='delete')
open(newunit=unit, file='foresight_script_test_strings.svg')
close(unit, status='delete')

! datablocks, load, call with arguments, eval, macros, undefine, as gnuplot 6.0
open(newunit=unit, file='foresight_script_test_sub.gp', action='write', status='replace')
write(unit, '(A)') 'sub_argc = ARGC', 'sub_args = ARG0 . "|" . ARG1 . "|" . ARG2 . "|" . ARG3 . "|" . ARG4', 'sub_x = 42'
close(unit)
script = 'set output "foresight_script_test_blocks.svg"'//new_line('a')// &
         '$D << EOD'//new_line('a')// &
         '1 10'//new_line('a')// &
         '2 20  # a comment'//new_line('a')// &
         '3 30'//new_line('a')// &
         'EOD'//new_line('a')// &
         'plot $D using 1:2 title "block", $D u 1:($2*2)'//new_line('a')// &
         'stats $D using 2 nooutput'//new_line('a')// &
         'b = 1; fit b*x $D using 1:2 via b'//new_line('a')// &
         'v = 5; call "foresight_script_test_sub.gp" "a b" 2.50 v (v+1)'//new_line('a')// &
         'after_argc = ARGC'//new_line('a')// &
         'eval sprintf("e_%d = %d", 3, 9)'//new_line('a')// &
         'cmd = "m_x = 7"; @cmd'//new_line('a')// &
         'what = "e_3"; m_y = @what + 1'//new_line('a')// &
         'has_d = exists("$D"); undefine $D; gone_d = exists("$D")'//new_line('a')// &
         'p_1 = 1; p_2 = 2; undefine p_*; gone_p = exists("p_1") + exists("p_2")'//new_line('a')// &
         'set print "foresight_script_test_blocks.txt"'//new_line('a')// &
         '$E << END'//new_line('a')// &
         '  5 6'//new_line('a')// &
         'END'//new_line('a')// &
         'print $E'//new_line('a')// &
         'unset print'
call interpreter%run_text(script, iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(106) = iostat == 0_I4P
if (test_passed(106)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(106) = same(panel%series(1)%y, [10, 20, 30]) .and. same(panel%series(2)%y, [20, 40, 60]) .and. &
                         trim(panel%series(1)%title) == 'block'
   endassociate
   block
      real(R8P)                     :: v(9)  !< Values.
      logical                       :: found !< Variable found.
      character(len=:), allocatable :: text  !< String value.

      call interpreter%symbols%value_of('STATS_mean', v(1), found)
      call interpreter%symbols%value_of('b', v(2), found)
      call interpreter%symbols%value_of('sub_argc', v(3), found)
      call interpreter%symbols%value_of('after_argc', v(4), found)
      call interpreter%symbols%value_of('e_3', v(5), found)
      call interpreter%symbols%value_of('m_x', v(6), found)
      call interpreter%symbols%value_of('m_y', v(7), found)
      call interpreter%symbols%value_of('has_d', v(8), found)
      call interpreter%symbols%value_of('gone_d', v(9), found)
      test_passed(106) = v(1) == 20.0_R8P .and. abs(v(2) - 10.0_R8P) < 1e-6_R8P .and. v(3) == 4.0_R8P .and. &
                         v(4) == 0.0_R8P .and. v(5) == 9.0_R8P .and. v(6) == 7.0_R8P .and. v(7) == 10.0_R8P .and. &
                         v(8) == 1.0_R8P .and. v(9) == 0.0_R8P
      call interpreter%symbols%string_of('sub_args', text, found)
      test_passed(106) = test_passed(106) .and. text == 'foresight_script_test_sub.gp|a b|2.50|5|6'
      call interpreter%symbols%value_of('gone_p', v(1), found)
      test_passed(106) = test_passed(106) .and. v(1) == 0.0_R8P
      call interpreter%symbols%value_of('ARG1', v(1), found)
      test_passed(106) = test_passed(106) .and. .not. found
   endblock
   test_passed(106) = test_passed(106) .and. file_is('foresight_script_test_blocks.txt', ['  5 6', '     '])
endif
call interpreter%run_text('plot $NONE u 1:2', iostat, iomsg)
test_passed(106) = test_passed(106) .and. iostat /= 0_I4P .and. index(iomsg, 'no datablock $NONE') > 0
call interpreter%run_text('$Q << EOQ'//new_line('a')//'1 2', iostat, iomsg)
test_passed(106) = test_passed(106) .and. iostat /= 0_I4P .and. index(iomsg, 'no line "EOQ" ends it') > 0
call interpreter%run_text('x_1 = 3; @x_1', iostat, iomsg)
test_passed(106) = test_passed(106) .and. iostat /= 0_I4P .and. index(iomsg, 'no string variable x_1') > 0
call interpreter%run_text('load "foresight_script_test_none.gp"', iostat, iomsg)
test_passed(106) = test_passed(106) .and. iostat /= 0_I4P .and. index(iomsg, 'cannot open script') > 0
call interpreter%run_text('load "foresight_script_test_sub.gp" 1', iostat, iomsg)
test_passed(106) = test_passed(106) .and. iostat /= 0_I4P .and. index(iomsg, 'call passes arguments') > 0
! undefine as gnuplot: nothing after it does nothing, a number or * alone is not a name, a*b is ignored; functions stay
call interpreter%run_text('undefine; ff(x) = 2*x; undefine ff; uu = ff(2); undefine a*b', iostat, iomsg)
test_passed(106) = test_passed(106) .and. iostat == 0_I4P
call interpreter%run_text('undefine 3', iostat, iomsg)
test_passed(106) = test_passed(106) .and. iostat /= 0_I4P .and. index(iomsg, 'not a variable name: "3"') > 0
call interpreter%run_text('undefine *', iostat, iomsg)
test_passed(106) = test_passed(106) .and. iostat /= 0_I4P .and. index(iomsg, 'not a variable name') > 0
open(newunit=unit, file='foresight_script_test_sub.gp')
close(unit, status='delete')
open(newunit=unit, file='foresight_script_test_blocks.svg')
close(unit, status='delete')
open(newunit=unit, file='foresight_script_test_blocks.txt')
close(unit, status='delete')

! time data, as gnuplot 6.0: set xdata time, set timefmt (a time over two whitespace columns), time ranges, the time
! functions, time formats only on time axes
open(newunit=unit, file='foresight_script_test_time.dat', action='write', status='replace')
write(unit, '(A)') '2024-03-01 10:00:00 1.5', '2024-03-01 10:30:00 2.5', '2024-03-01 12:15:30 2.0', &
                   '2024-03-02 08:00:00 3.0'
close(unit)
call interpreter%run_text('set output "foresight_script_test_time.svg"'//new_line('a')// &
                          'set xdata time; set timefmt "%Y-%m-%d %H:%M:%S"'//new_line('a')// &
                          'set format x "%H:%M"'//new_line('a')// &
                          'plot "foresight_script_test_time.dat" using 1:3, "" using (timecolumn(1) + 3600):3'// &
                          new_line('a')// &
                          't_a = strptime("%Y-%m-%d", "2024-03-01"); t_b = strftime("%d %b %Y %H:%M", t_a + 5400)'// &
                          new_line('a')// &
                          't_c = strftime("%tH:%tM", 361800)', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(107) = iostat == 0_I4P
if (test_passed(107)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(107) = panel%xaxis%time .and. size(panel%series(1)%x) == 4 .and. &
                         panel%series(1)%x(1) == 1709287200.0_R8P .and. panel%series(1)%x(3) == 1709295330.0_R8P .and. &
                         panel%series(2)%x(1) == 1709290800.0_R8P .and. panel%series(1)%y(4) == 3.0_R8P
      ! gnuplot's ticks: 10:00 to 10:00 next day (the second item an hour later), every 2 hours
      test_passed(107) = test_passed(107) .and. panel%xaxis%ticks(1)%label == '10:00' .and. &
                         panel%xaxis%lo == 1709287200.0_R8P .and. panel%xaxis%hi == 1709373600.0_R8P
   endassociate
   block
      character(len=:), allocatable :: text  !< String value.
      logical                       :: found !< Variable found.

      call interpreter%symbols%string_of('t_b', text, found)
      test_passed(107) = test_passed(107) .and. text == '01 Mar 2024 01:30'
      call interpreter%symbols%string_of('t_c', text, found)
      test_passed(107) = test_passed(107) .and. text == '100:30'
   endblock
endif
call interpreter%run_text('set xrange ["2024-03-01 12:00:00":"2024-03-01 18:00:00"]; set xtics 7200*1.5; '// &
                          'plot "foresight_script_test_time.dat" using 1:3', iostat, iomsg)
test_passed(107) = test_passed(107) .and. iostat == 0_I4P
if (test_passed(107)) then
   associate(axis => interpreter%figure%panels(1)%xaxis)
      test_passed(107) = axis%lo == 1709294400.0_R8P .and. axis%hi == 1709316000.0_R8P .and. size(axis%ticks) == 3 &
                         .and. axis%ticks(2)%label == '15:00'
   endassociate
endif
call interpreter%run_text('set xrange ["2024/03/01":*]', iostat, iomsg)
test_passed(107) = test_passed(107) .and. iostat /= 0_I4P .and. index(iomsg, 'does not match the timefmt') > 0
call interpreter%run_text("set xdata; set format y '%Y'", iostat, iomsg)
test_passed(107) = test_passed(107) .and. iostat /= 0_I4P .and. index(iomsg, 'unsupported conversion') > 0
call interpreter%run_text("set format x '%d/%m' timedate", iostat, iomsg)
test_passed(107) = test_passed(107) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%xaxis%time
call interpreter%run_text("set xdata blah", iostat, iomsg)
test_passed(107) = test_passed(107) .and. iostat /= 0_I4P .and. index(iomsg, 'time or nothing expected') > 0
call interpreter%run_text('set format x "%g"; set xrange [*:*]; set xtics autofreq; set timefmt; set xdata; '// &
                          'set format x "%g" numeric', iostat, iomsg)
test_passed(107) = test_passed(107) .and. iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%xaxis%time
open(newunit=unit, file='foresight_script_test_time.dat')
close(unit, status='delete')
open(newunit=unit, file='foresight_script_test_time.svg')
close(unit, status='delete')

! histogram layouts, as gnuplot 6.0: newhistogram groups (2 rows after the previous group, or at X; lt, fs),
! errorbars (Y:ERR, Y:LOW:HIGH), columnstacked (key(N) rows, title columnhead the stack label)
open(newunit=unit, file='foresight_script_test_hist.dat', action='write', status='replace')
write(unit, '(A)') 'name a b c ea eb', 'r1 1 2 3 0.1 0.2', 'r2 2 3 1 0.2 0.1', 'r3 3 1 2 0.3 0.3'
close(unit)
call interpreter%run_text('set output "foresight_script_test_hist.svg"; set style data histograms'//new_line('a')// &
                          'set style histogram clustered gap 1'//new_line('a')// &
                          'plot newhistogram "A", "foresight_script_test_hist.dat" u 2:xtic(1) t "a", "" u 3, '// &
                          'newhistogram "B" lt 4 fs solid 0.5, "" u 4 t "c", newhistogram at 10, "" u 2', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(108) = iostat == 0_I4P
if (test_passed(108)) then
   associate(panel => interpreter%figure%panels(1))
      ! the header row is an invalid row of each, counted (as gnuplot): the rows at 1, 2, 3 in the first group
      test_passed(108) = same(panel%series(1)%x, [1, 2, 3]) .and. same(panel%series(3)%x, [6, 7, 8]) .and. &
                         same(panel%series(4)%x, [11, 12, 13]) .and. panel%series(3)%hist_title == 'B' .and. &
                         panel%series(3)%style%density == 0.5_R8P .and. panel%series(3)%style%color == '#e69f00' .and. &
                         same(panel%series(1)%xhigh * 3.0_R8P, [3, 6, 9]) .and. &
                         same(panel%series(3)%xhigh * 4.0_R8P, [25, 29, 33])
   endassociate
endif
call interpreter%run_text('set style histogram errorbars gap 1 lw 2; '// &
                          'plot "foresight_script_test_hist.dat" u 2:5 t "a", "" u 3:($3-1):($3+1) t "b"', iostat, iomsg)
test_passed(108) = test_passed(108) .and. iostat == 0_I4P
if (test_passed(108)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(108) = allocated(panel%series(1)%bounds) .and. panel%histogram_lw == 2.0_R8P .and. &
                         same(panel%series(1)%bounds(1, :) * 10.0_R8P, [9, 18, 27]) .and. &
                         same(panel%series(2)%bounds(2, :), [3, 4, 2])
   endassociate
endif
call interpreter%run_text('set style histogram columnstacked; '// &
                          'plot "foresight_script_test_hist.dat" u 2 title columnhead, "" u 3:key(1)', iostat, iomsg)
test_passed(108) = test_passed(108) .and. iostat == 0_I4P
if (test_passed(108)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(108) = same(panel%series(1)%x, [0, 0, 0]) .and. same(panel%series(2)%x, [1, 1, 1]) .and. &
                         same(panel%series(2)%ylow, [0, 2, 5]) .and. same(panel%series(2)%y, [2, 5, 6]) .and. &
                         trim(panel%series(2)%texts(3)) == 'r3' .and. trim(panel%series(1)%xlabels(1)) == 'a' .and. &
                         panel%series(1)%colors(2) == '#009e73'
   endassociate
endif
call interpreter%run_text('set style histogram errorbars; '// &
                          'plot "foresight_script_test_hist.dat" u 2:3:4:5', iostat, iomsg)
test_passed(108) = test_passed(108) .and. iostat /= 0_I4P .and. index(iomsg, 'needs using Y or Y:xtic(N)') > 0
call interpreter%run_text('plot newhistogram "A" blah, "foresight_script_test_hist.dat" u 2', iostat, iomsg)
test_passed(108) = test_passed(108) .and. iostat /= 0_I4P .and. index(iomsg, 'newhistogram: unsupported option') > 0
call interpreter%run_text('set style histogram clustered lw 2', iostat, iomsg)
test_passed(108) = test_passed(108) .and. iostat /= 0_I4P .and. index(iomsg, 'lw applies to errorbars') > 0
call interpreter%run_text('set style histogram clustered gap 2', iostat, iomsg)
open(newunit=unit, file='foresight_script_test_hist.dat')
close(unit, status='delete')
open(newunit=unit, file='foresight_script_test_hist.svg')
close(unit, status='delete')

! labels, arrows, objects, as gnuplot 6.0: tags, positions in several systems, a tag modified, unset
call interpreter%run_text('set output "foresight_script_test_notes.svg"; set xrange [0:10]'//new_line('a')// &
                          'set label 1 "peak" at pi/2, 1 point pt 7 offset 1,0'//new_line('a')// &
                          'set label "mid" at graph 0.5, first 2 center rotate by 30 tc rgb "red" front'//new_line('a')// &
                          'set label 1 right'//new_line('a')// &
                          'set arrow from 1,2 rto 3,-1 heads filled size screen 0.02,20 lc rgb "blue" lw 2 dt 2'// &
                          new_line('a')// &
                          'set object 3 rect from 4, graph 0 to 6, graph 1 fc lt 2 fs solid 0.3 noborder behind'// &
                          new_line('a')// &
                          'set object circle at 2,0 size 0.5 arc [0:90] fc "#e69f00" front'//new_line('a')// &
                          'set object 9 polygon from 0,0 to 1,0 to 1,1 to 0,0'//new_line('a')// &
                          'plot sin(x)', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(109) = iostat == 0_I4P
if (test_passed(109)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(109) = size(panel%notes) == 2 .and. panel%notes(1)%tag == 1_I4P .and. panel%notes(2)%tag == 2_I4P &
                         .and. panel%notes(1)%justify == 'right' .and. panel%notes(1)%point .and. &
                         panel%notes(1)%pt == 7_I4P .and. abs(panel%notes(1)%at%x - 2.0_R8P * atan(1.0_R8P)) < 1e-12_R8P &
                         .and. panel%notes(2)%at%sx == 'graph' .and. panel%notes(2)%at%sy == 'first' .and. &
                         panel%notes(2)%color == '#ff0000' .and. panel%notes(2)%front .and. panel%notes(2)%rotate == 30.0_R8P
      test_passed(109) = test_passed(109) .and. size(panel%arrows) == 1 .and. panel%arrows(1)%relative .and. &
                         panel%arrows(1)%head == 3_I4P .and. panel%arrows(1)%fill == 'filled' .and. &
                         panel%arrows(1)%length_system == 'screen' .and. panel%arrows(1)%angle == 20.0_R8P .and. &
                         panel%arrows(1)%color == '#0000ff' .and. len(panel%arrows(1)%dashes) > 0
      test_passed(109) = test_passed(109) .and. size(panel%objects) == 3 .and. panel%objects(1)%tag == 3_I4P .and. &
                         panel%objects(1)%layer == 'behind' .and. panel%objects(1)%points(1)%sy == 'graph' .and. &
                         panel%objects(1)%style%color == '#009e73' .and. panel%objects(2)%tag == 4_I4P .and. &
                         panel%objects(2)%kind == 'circle' .and. panel%objects(2)%arc(2) == 90.0_R8P .and. &
                         panel%objects(3)%kind == 'polygon' .and. size(panel%objects(3)%points) == 4
   endassociate
endif
call interpreter%run_text('unset label 1; unset arrow; set object 3 fc rgb "red"', iostat, iomsg)
test_passed(109) = test_passed(109) .and. iostat == 0_I4P
if (test_passed(109)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(109) = size(panel%notes) == 1 .and. .not. allocated(panel%arrows) .and. &
                         panel%objects(1)%style%color == '#ff0000' .and. panel%objects(1)%kind == 'rectangle' .and. &
                         panel%objects(1)%layer == 'behind'
   endassociate
endif
call interpreter%run_text('set label "x" at lunar 1,1', iostat, iomsg)
test_passed(109) = test_passed(109) .and. iostat /= 0_I4P
call interpreter%run_text('set arrow 2 nohead', iostat, iomsg)
test_passed(109) = test_passed(109) .and. iostat /= 0_I4P .and. index(iomsg, 'from POS to|rto POS') > 0
call interpreter%run_text('set object 7 polygon from 0,0 to 1,1', iostat, iomsg)
test_passed(109) = test_passed(109) .and. iostat /= 0_I4P .and. index(iomsg, '3 vertices') > 0
call interpreter%run_text('set label 3 "a" at 1 2', iostat, iomsg)
test_passed(109) = test_passed(109) .and. iostat /= 0_I4P .and. index(iomsg, 'a position is') > 0
call interpreter%run_text('unset label; unset object; unset arrow; set xrange [*:*]', iostat, iomsg)
test_passed(109) = test_passed(109) .and. iostat == 0_I4P
open(newunit=unit, file='foresight_script_test_notes.svg')
close(unit, status='delete')

! arrays, as gnuplot 6.0: declared, set by element, printed, sized, indexed at run time, plotted, stated; ARGV;
! datablock lines
call interpreter%init(scratch)
call interpreter%run_text("set print 'foresight_script_test_arrays.txt'"//new_line('a')// &
                          'array A[3]; print A, |A|; A[1] = 5; A[2] = "two"; print A; print A[1] + 1, A[2]'//new_line('a')// &
                          'array B = [1, 2.5, "x", 4]; print B, |B|, B[3], B[1.7]'//new_line('a')// &
                          'array C[3] = [7, 8]; print C; do for [i = 1:|C| - 1] { print C[i] }'//new_line('a')// &
                          'f(i) = B[i] * 2; print f(4), exists("B"), index(B, 4), index(B, "x"), index(B, 9)'// &
                          new_line('a')//'$D << EOD'//new_line('a')//'1 2'//new_line('a')//'3 4'//new_line('a')// &
                          'EOD'//new_line('a')//'print |$D|, $D[2], $D[2][3:3]; print ARGC, |ARGV|'//new_line('a')// &
                          'array Q = [3, 1, 4, 1, 5]; stats Q nooutput; print STATS_mean, STATS_records'//new_line('a')// &
                          'undefine B; print exists("B"); set print', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(110) = iostat == 0_I4P .and. &
   file_is('foresight_script_test_arrays.txt', [character(len=24) :: '[,,] 3', '[5,"two",]', '6 two', &
           '[1,2.5,"x",4] 4 x 1', '[7,8,]', '7', '8', '8 1 4 3 0', '2 3 4 4', '0 0', '2.8 5', '0'])
call interpreter%run_text('set output "foresight_script_test_arrays.svg"; plot Q using 1:(Q[$1] * 2), Q', iostat, iomsg)
test_passed(110) = test_passed(110) .and. iostat == 0_I4P
if (test_passed(110)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(110) = size(panel%series) == 2 .and. same(panel%series(1)%y, [6, 2, 8, 2, 10]) .and. &
                         same(panel%series(2)%x, [1, 2, 3, 4, 5]) .and. &
                         panel%series(2)%title == 'Q'
   endassociate
endif
call interpreter%run_text('array E[2]; print E[3]', iostat, iomsg)
test_passed(110) = test_passed(110) .and. iostat /= 0_I4P .and. index(iomsg, 'array index out of range: E[3]') > 0
call interpreter%run_text('print E[1] + 1', iostat, iomsg)
test_passed(110) = test_passed(110) .and. iostat /= 0_I4P .and. index(iomsg, 'uninitialized user variable: E[1] + 1') > 0
call interpreter%run_text('E[0] = 1', iostat, iomsg)
test_passed(110) = test_passed(110) .and. iostat /= 0_I4P .and. index(iomsg, 'array index out of range') > 0
call interpreter%run_text('array E[1] = [1, 2]', iostat, iomsg)
test_passed(110) = test_passed(110) .and. iostat /= 0_I4P .and. index(iomsg, 'more elements than its size') > 0
call interpreter%run_text('print E[1:2] + 1', iostat, iomsg)
test_passed(110) = test_passed(110) .and. iostat /= 0_I4P .and. index(iomsg, 'is an array: print it') > 0
call interpreter%run_text('print |x|', iostat, iomsg)
test_passed(110) = test_passed(110) .and. iostat /= 0_I4P .and. index(iomsg, 'takes an array or a datablock') > 0
call interpreter%run_text('print 6 | 2.5', iostat, iomsg)
test_passed(110) = test_passed(110) .and. iostat /= 0_I4P .and. index(iomsg, 'non-integer passed to boolean operator') > 0
call interpreter%run_text("set print 'foresight_script_test_arrays.txt'; print E; set print", iostat, iomsg)
test_passed(110) = test_passed(110) .and. iostat == 0_I4P
call interpreter%run_text('x = E + 1', iostat, iomsg)
test_passed(110) = test_passed(110) .and. iostat /= 0_I4P .and. index(iomsg, 'needs an index') > 0
open(newunit=unit, file='foresight_script_test_arrays.txt')
close(unit, status='delete')
open(newunit=unit, file='foresight_script_test_arrays.svg')
close(unit, status='delete')

! system, backquotes, reset, set table, as gnuplot 6.0
call interpreter%init(scratch)
open(newunit=unit, file='foresight_script_test_table.dat')
write(unit, '(A)') '1 2 0.5 a', '2 4 0.3 b', '3 3 0.2 c'
close(unit)
call interpreter%run_text("set print 'foresight_script_test_system.txt'"//new_line('a')// &
                          'print system("echo hello; echo world"); x = system("echo 3"); print x + 1, strlen(x)'// &
                          new_line('a')//'print `echo 42`; y = `echo 5` * 2; print y; print "a `echo b` c"'// &
                          new_line('a')//"print 'a `echo b` c'; print system('printf ""a\n\n""') . '|'"// &
                          new_line('a')//'set samples 7; set style data points; set style function points; a = 1'// &
                          new_line('a')//'set xrange [0:1]; set logscale y; reset; print exists("a")'//new_line('a')// &
                          'reset session; print exists("a"), exists("ARGC"); set print', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(111) = iostat == 0_I4P .and. &
   file_is('foresight_script_test_system.txt', [character(len=12) :: 'hello', 'world', '4 1', '42', '10', 'a b c', &
           'a `echo b` c', 'a', '|', '1', '0 1'])
test_passed(111) = test_passed(111) .and. interpreter%samples == 100_I4P .and. interpreter%data_style == 'points' &
                   .and. interpreter%function_style == 'lines' .and. .not. interpreter%figure%panels(1)%yaxis%log .and. &
                   .not. interpreter%figure%panels(1)%xaxis%min_fixed
call interpreter%run_text("set table 'foresight_script_test_table.txt'; set samples 3"//new_line('a')// &
                          'plot [0:2] x**2 title "sq"'//new_line('a')// &
                          "plot 'foresight_script_test_table.dat' u 1:2:3 with yerrorbars title 'e'"//new_line('a')// &
                          "plot '' u 1:2:4 with labels title 'l', '' u 1:2 w boxes title 'b'"//new_line('a')// &
                          "set format y '%.3f'; set yrange [0:3.5]; plot '' u 1:2 w p t 'p'; unset table", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(111) = test_passed(111) .and. iostat == 0_I4P .and. .not. interpreter%table .and. &
   file_is('foresight_script_test_table.txt', [character(len=32) :: '', '# Curve 0 of 1, 3 points', &
           '# Curve title: "sq"', '# x y type', ' 0  0  i', ' 1  1  i', ' 2  4  i', '', '', '# Curve 0 of 1, 3 points', &
           '# Curve title: "e"', '# x y ylow yhigh type', ' 1  2  1.5  2.5  i', ' 2  4  3.7  4.3  i', &
           ' 3  3  2.8  3.2  i', '', '', '# Curve 0 of 2, 3 points', '# Curve title: "l"', '# x y label type', &
           ' 1  2 "a"', ' 2  4 "b"', ' 3  3 "c"', '', '', '# Curve 1 of 2, 3 points', '# Curve title: "b"', &
           '# x y xlow xhigh type', ' 1  2  1  1  i', ' 2  4  2  2  i', ' 3  3  3  3  i', '', '', &
           '# Curve 0 of 1, 3 points', '# Curve title: "p"', '# x y type', ' 1 2.000  i', ' 2 4.000  o', ' 3 3.000  i', &
           ''])
call interpreter%run_text('set table $T; plot [0:1] x title "t"; unset table; n = |$T|', iostat, iomsg)
test_passed(111) = test_passed(111) .and. iostat == 0_I4P
if (test_passed(111)) then
   block
      real(R8P) :: v     !< Value.
      logical   :: found !< Variable found.

      call interpreter%symbols%value_of('n', v, found)
      test_passed(111) = found .and. v == 8.0_R8P
   endblock
endif
call interpreter%run_text('reset bogus', iostat, iomsg)
test_passed(111) = test_passed(111) .and. iostat /= 0_I4P .and. index(iomsg, 'session, errors or bind') > 0
call interpreter%run_text('print `echo 1', iostat, iomsg)
test_passed(111) = test_passed(111) .and. iostat /= 0_I4P .and. index(iomsg, 'unmatched `') > 0
call interpreter%run_text('plot "foresight_script_test_table.dat" u 1:(system($2))', iostat, iomsg)
test_passed(111) = test_passed(111) .and. iostat /= 0_I4P .and. index(iomsg, 'system takes a command known now') > 0
call interpreter%run_text('set table "x" separator semicolon', iostat, iomsg)
test_passed(111) = test_passed(111) .and. iostat /= 0_I4P .and. index(iomsg, 'separator whitespace|tab|comma') > 0
open(newunit=unit, file='foresight_script_test_system.txt')
close(unit, status='delete')
open(newunit=unit, file='foresight_script_test_table.txt')
close(unit, status='delete')
open(newunit=unit, file='foresight_script_test_table.dat')
close(unit, status='delete')

! pause and the live loop of gnuplot 6.0 (a plot rewritten after each pause); reread deprecated
call interpreter%init(scratch)
call system_clock(count=start_count, count_rate=count_rate)
call interpreter%run_text('set output "foresight_script_test_pause.svg"; i = 0'//new_line('a')// &
                          'while (i < 3) { i = i + 1; plot [0:1] x*i; pa 0.05 }'//new_line('a')// &
                          'pause 0; pause mouse close; pause (i > 2 ? 0 : 1)', iostat, iomsg)
call system_clock(count=end_count)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(112) = iostat == 0_I4P .and. real(end_count - start_count, R8P) / real(count_rate, R8P) >= 0.14_R8P
if (test_passed(112)) test_passed(112) = abs(interpreter%figure%panels(1)%series(1)%y(100) - 3.0_R8P) < 1e-12_R8P
call interpreter%run_text('reread', iostat, iomsg)
test_passed(112) = test_passed(112) .and. iostat /= 0_I4P .and. index(iomsg, 'deprecated in gnuplot 6.0') > 0
call interpreter%run_text('pause', iostat, iomsg)
test_passed(112) = test_passed(112) .and. iostat /= 0_I4P .and. index(iomsg, '-1 or mouse') > 0
call interpreter%run_text('pause mouse wheel', iostat, iomsg)
test_passed(112) = test_passed(112) .and. iostat /= 0_I4P .and. index(iomsg, 'unknown event "wheel"') > 0
call interpreter%run_text('pause 1/0', iostat, iomsg)
test_passed(112) = test_passed(112) .and. iostat /= 0_I4P .and. index(iomsg, 'pause: undefined value') > 0
open(newunit=unit, file='foresight_script_test_pause.svg')
close(unit, status='delete')

! arrow styles, the rectangle style, object dash types, character coordinates, as gnuplot 6.0
call interpreter%init(scratch)
call interpreter%run_text('set output "foresight_script_test_styles.svg"'//new_line('a')// &
                          'set style arrow 1 head filled size screen 0.03,15 lc rgb "red" lw 2 dt 2'//new_line('a')// &
                          'set style arrow 2 nohead lc rgb "blue"'//new_line('a')// &
                          'set arrow 1 from 1,1 to 4,4 as 1 lc rgb "green"'//new_line('a')// &
                          'set arrow 2 from 1,4 to 4,1 lw 3 arrowstyle 2'//new_line('a')// &
                          'set style rectangle fc rgb "yellow" fs solid 0.5 border lc rgb "green" lw 2 front'// &
                          new_line('a')//'set object 1 rect from 5,1 to 7,3'//new_line('a')// &
                          'set object 2 circle at 8,8 size 1 dt 3'//new_line('a')// &
                          'set label 1 "c" at character 3, graph 0.5'//new_line('a')// &
                          'set arrow 3 from character 1,1 to character 8,4 size character 2,20'//new_line('a')// &
                          'plot [0:10] x', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(113) = iostat == 0_I4P
if (test_passed(113)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(113) = panel%arrows(1)%color == '#00ff00' .and. panel%arrows(1)%fill == 'filled' .and. &
                         panel%arrows(1)%lw == 2.0_R8P .and. len(panel%arrows(1)%dashes) > 0 .and. &
                         panel%arrows(1)%length_system == 'screen' .and. panel%arrows(2)%head == 0_I4P .and. &
                         panel%arrows(2)%color == '#0000ff' .and. panel%arrows(2)%lw == 1.0_R8P .and. &
                         panel%objects(1)%style%color == '#ffff00' .and. panel%objects(1)%style%density == 0.5_R8P .and. &
                         panel%objects(1)%style%border_color == '#00ff00' .and. panel%objects(1)%style%linewidth == 2.0_R8P &
                         .and. panel%objects(1)%layer == 'back' .and. panel%objects(2)%style%dashtype == 3_I4P .and. &
                         panel%notes(1)%at%sx == 'character' .and. panel%notes(1)%at%sy == 'graph' .and. &
                         panel%arrows(3)%from%sx == 'character' .and. panel%arrows(3)%length_system == 'character'
   endassociate
endif
call interpreter%run_text('set arrow 4 from 0,0 to 1,1 as 9', iostat, iomsg)
test_passed(113) = test_passed(113) .and. iostat /= 0_I4P .and. index(iomsg, 'arrow style 9 is not defined') > 0
call interpreter%run_text('unset style arrow; set arrow 4 from 0,0 to 1,1 as 1', iostat, iomsg)
test_passed(113) = test_passed(113) .and. iostat /= 0_I4P .and. index(iomsg, 'arrow style 1 is not defined') > 0
call interpreter%run_text('set style arrow from 0,0 to 1,1', iostat, iomsg)
test_passed(113) = test_passed(113) .and. iostat /= 0_I4P .and. index(iomsg, 'a style number') > 0
call interpreter%run_text('set style rectangle from 0,0 to 1,1', iostat, iomsg)
test_passed(113) = test_passed(113) .and. iostat /= 0_I4P .and. index(iomsg, 'style options only') > 0
call interpreter%run_text('set object 5 rect from 0,0 to 1,1 dt 9', iostat, iomsg)
test_passed(113) = test_passed(113) .and. iostat /= 0_I4P .and. index(iomsg, 'dash types 1 to 5') > 0
call interpreter%run_text('reset; set object 6 rect from 0,0 to 1,1', iostat, iomsg)
test_passed(113) = test_passed(113) .and. iostat == 0_I4P
if (test_passed(113)) test_passed(113) = interpreter%figure%panels(1)%objects(1)%style%color == 'white'
open(newunit=unit, file='foresight_script_test_styles.svg')
close(unit, status='delete')

! ytic/x2tic/y2tic labels, pointinterval, filledcurves to vertical lines, set errorbars, histogram titles, minor time
! ticks, as gnuplot 6.0
call interpreter%init(scratch)
open(newunit=unit, file='foresight_script_test_gaps.dat')
write(unit, '(A)') 'Jan 3 0.5', 'Feb 5 0.3', 'Mar 4 0.2'
close(unit)
call interpreter%run_text('set output "foresight_script_test_gaps.svg"'//new_line('a')// &
                          'set errorbars 2 lc rgb "red" lw 2'//new_line('a')// &
                          'plot "foresight_script_test_gaps.dat" u 0:2:ytic(1) w lp pi 2 pt 7, '// &
                          '"" u 0:2:3 w yerrorbars pointinterval -2, "" u 0:2:x2tic(1) w p'//new_line('a')// &
                          'set style histogram clustered title tc rgb "blue" offset 1,-0.5 nokeyseparators', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(114) = iostat == 0_I4P
if (test_passed(114)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(114) = panel%series(1)%label_axis == 'y' .and. panel%series(1)%pointinterval == 2_I4P .and. &
                         panel%series(2)%pointinterval == -2_I4P .and. panel%series(3)%label_axis == 'x2' .and. &
                         panel%errorbar_size == 2.0_R8P .and. panel%errorbar_color == '#ff0000' .and. &
                         panel%errorbar_lw == 2.0_R8P .and. panel%hist_title_color == '#0000ff' .and. &
                         all(panel%hist_title_offset == [1.0_R8P, -0.5_R8P])
      ! the y labels replace the y ticks; the x2 ones need set x2tics (as gnuplot 6.0)
      if (test_passed(114)) test_passed(114) = panel%yaxis%labelled() .and. .not. panel%x2axis%labelled()
      if (test_passed(114)) test_passed(114) = panel%yaxis%labels(1)%label == 'Jan' .and. &
                                               panel%yaxis%labels(3)%label == 'Feb'
   endassociate
endif
call interpreter%run_text('unset errorbars; set xrange [0:5]'//new_line('a')// &
                          'plot "foresight_script_test_gaps.dat" u 0:2 w filledcurves y1, "" u 0:2 w filledcurves y2, '// &
                          '"" u 0:2 w filledcurves x=1.5, "" u 0:2 w filledcurves y2=4'//new_line('a')// &
                          'set xdata time; set mxtics time 6 hours', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(114) = test_passed(114) .and. iostat == 0_I4P
if (test_passed(114)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(114) = panel%errorbar_size == 0.0_R8P .and. panel%series(1)%curve_to == 4_I4P .and. &
                         panel%series(2)%curve_to == 5_I4P .and. panel%series(3)%curve_to == 6_I4P .and. &
                         panel%series(3)%curve_point(1) == 1.5_R8P .and. allocated(panel%series(4)%ylow) .and. &
                         panel%xaxis%tics%minor_count == 6_I4P .and. panel%xaxis%tics%minor_unit == 'hours'
   endassociate
endif
call interpreter%run_text('plot "foresight_script_test_gaps.dat" u 0:2 w filledcurves x=1 above', iostat, iomsg)
test_passed(114) = test_passed(114) .and. iostat /= 0_I4P .and. index(iomsg, 'above and below apply to') > 0
call interpreter%run_text('plot "foresight_script_test_gaps.dat" u 0:2 w lp pi 0', iostat, iomsg)
test_passed(114) = test_passed(114) .and. iostat /= 0_I4P .and. index(iomsg, 'N not 0') > 0
call interpreter%run_text('set mxtics time 2 fortnights', iostat, iomsg)
test_passed(114) = test_passed(114) .and. iostat /= 0_I4P .and. index(iomsg, 'time N seconds') > 0
call interpreter%run_text('set errorbars wide', iostat, iomsg)
test_passed(114) = test_passed(114) .and. iostat /= 0_I4P .and. index(iomsg, 'unsupported option "wide"') > 0
call interpreter%run_text('plot "foresight_script_test_gaps.dat" u 0:2 w filledcurves r=1', iostat, iomsg)
test_passed(114) = test_passed(114) .and. iostat /= 0_I4P .and. index(iomsg, 'r=V applies to polar plots') > 0
open(newunit=unit, file='foresight_script_test_gaps.dat')
close(unit, status='delete')
open(newunit=unit, file='foresight_script_test_gaps.svg')
close(unit, status='delete')

! reset in a multiplot resets the next panel, not the one drawn (gnuplot draws a panel at its plot); ytic labels kept
! by the HTML page through a zoom
call interpreter%init(scratch)
open(newunit=unit, file='foresight_script_test_reset.dat')
write(unit, '(A)') 'Jan 3', 'Feb 5', 'Mar 4'
close(unit)
call interpreter%run_text('set output "foresight_script_test_reset.html"; set multiplot layout 1,2'//new_line('a')// &
                          'set title "first"; set logscale y'//new_line('a')// &
                          'plot "foresight_script_test_reset.dat" u 0:2:ytic(1) w lp'//new_line('a')// &
                          'reset; plot "foresight_script_test_reset.dat" u 0:2', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(115) = iostat == 0_I4P
if (test_passed(115)) test_passed(115) = interpreter%figure%panels(1)%title == 'first' .and. &
                                         interpreter%figure%panels(1)%yaxis%log .and. &
                                         .not. interpreter%figure%panels(2)%yaxis%log .and. &
                                         .not. allocated(interpreter%figure%panels(2)%title)
if (test_passed(115)) test_passed(115) = file_has('foresight_script_test_reset.html', 'ytics="labels 3e0:Jan 4e0:Mar 5e0:Feb"')
call interpreter%run_text('unset multiplot', iostat, iomsg)
open(newunit=unit, file='foresight_script_test_reset.dat')
close(unit, status='delete')
open(newunit=unit, file='foresight_script_test_reset.html')
close(unit, status='delete')

! color strings as gnuplot reads them: its names (green is #00ff00, not SVG's #008000), # and 0x numbers with alpha;
! an SVG-only name fails as gnuplot
call interpreter%init(scratch)
call interpreter%run_text('set object 1 rect from 0,0 to 1,1 fc rgb "0x8000ff00"'//new_line('a')// &
                          'set label 1 "a" at 0,0 tc "dark-green"'//new_line('a')// &
                          'plot x lc "green", 2*x linecolor rgbcolor "gray90"', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(116) = iostat == 0_I4P
if (test_passed(116)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(116) = panel%series(1)%style%color == '#00ff00' .and. panel%series(2)%style%color == '#e5e5e5' .and. &
                         panel%objects(1)%style%color == '#00ff007f' .and. panel%notes(1)%color == '#006400'
   endassociate
endif
call interpreter%run_text('plot x lc rgb "darkgreen"', iostat, iomsg)
test_passed(116) = test_passed(116) .and. iostat /= 0_I4P .and. &
                   index(iomsg, 'unrecognized color name "darkgreen" and not a string "#AARRGGBB"') > 0
call interpreter%run_text('set palette defined (0 "dark-green", 1 "0xffffff"); plot x lc rgb "Green"', iostat, iomsg)
test_passed(116) = test_passed(116) .and. iostat /= 0_I4P .and. index(iomsg, '"Green"') > 0

! stats of a datablock counts its blank lines and blocks (gnuplot: 3 2 4); stats of a datablock or an array opens no
! file of its name (nvfortran created an empty one)
call interpreter%init(scratch)
call interpreter%run_text('$S << EOD'//new_line('a')//'1 2'//new_line('a')//'2 3'//new_line('a')//''//new_line('a')// &
                          '3 4'//new_line('a')//''//new_line('a')//''//new_line('a')//'5 6'//new_line('a')//'EOD'// &
                          new_line('a')//'stats $S u 2 nooutput; b1 = STATS_blank; b2 = STATS_blocks; b3 = STATS_records'// &
                          new_line('a')//'array R = [1, 2, 3]; stats R nooutput', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(117) = iostat == 0_I4P
if (test_passed(117)) then
   block
      real(R8P) :: counts(4) !< b1, b2, b3, STATS_blank.
      logical   :: known(4)  !< Variables defined.
      logical   :: there     !< File exists.

      call interpreter%symbols%value_of('b1', counts(1), known(1))
      call interpreter%symbols%value_of('b2', counts(2), known(2))
      call interpreter%symbols%value_of('b3', counts(3), known(3))
      call interpreter%symbols%value_of('STATS_blank', counts(4), known(4))
      test_passed(117) = all(known) .and. same(counts, [3, 2, 4, 0])
      inquire(file='$S', exist=there)
      test_passed(117) = test_passed(117) .and. .not. there
      inquire(file='R', exist=there)
      test_passed(117) = test_passed(117) .and. .not. there
   endblock
endif

! array slices, as gnuplot 6.0: printed, sized, indexed, assigned (a copy), clamped, empty
call interpreter%init(scratch)
call interpreter%run_text("set print 'foresight_script_test_slices.txt'"//new_line('a')// &
                          'array A = [1, 2, 3, 4, 5]; print A[2:4], |A[2:4]|, A[:2], A[4:], A[3:3], A[4:2]'// &
                          new_line('a')//'print A[0:2], A[2:9], A[2:*], A[*:2]; i = 2; print A[i:i+1][2] + 10'// &
                          new_line('a')//'B = A[2:3]; B[1] = 9; array C = A[4:]; print A, B, C, |C|'// &
                          new_line('a')//'array G[3]; G[1] = "g"; print G[1:2]; set print', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(118) = iostat == 0_I4P .and. &
   file_is('foresight_script_test_slices.txt', [character(len=40) :: '[2,3,4] 3 [1,2] [4,5] [3] []', &
           '[1,2] [2,3,4,5] [2,3,4,5] [1,2]', '13', '[1,2,3,4,5] [9,3] [4,5] 2', '["g",]'])
call interpreter%run_text('print A[2:3][5]', iostat, iomsg)
test_passed(118) = test_passed(118) .and. iostat /= 0_I4P .and. index(iomsg, 'array index out of range') > 0
call interpreter%run_text('print A["a":2]', iostat, iomsg)
test_passed(118) = test_passed(118) .and. iostat /= 0_I4P
open(newunit=unit, file='foresight_script_test_slices.txt')
close(unit, status='delete')

! set print $NAME, as gnuplot 6.0: the printed lines make the datablock (emptied unless append), read back as data
call interpreter%init(scratch)
call interpreter%run_text('set print $P; print "a", 1; print 2.5; set print $P append; print "c"; set print'// &
                          new_line('a')//'set print $Q; do for [i=1:3] { print i, i**2 }; unset print'// &
                          new_line('a')//'stats $Q u 2 nooutput; s = STATS_sum; n = |$P|'// &
                          new_line('a')//"set print 'foresight_script_test_printdb.txt'; print $P; set print", &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(119) = iostat == 0_I4P
if (test_passed(119)) then
   block
      real(R8P) :: v(2)     !< s, n.
      logical   :: known(2) !< Defined.

      call interpreter%symbols%value_of('s', v(1), known(1))
      call interpreter%symbols%value_of('n', v(2), known(2))
      test_passed(119) = all(known) .and. same(v, [14, 3]) .and. &
                         file_is('foresight_script_test_printdb.txt', [character(len=8) :: 'a 1', '2.5', 'c', ''])
   endblock
endif
open(newunit=unit, file='foresight_script_test_printdb.txt')
close(unit, status='delete')

! plot with table, as gnuplot 6.0: the using fields as text (a blank before each, tab separated; %g, nan, strings as
! they are), the leading numeric columns without using, if COND, every; into a datablock a string without its blank
! and the separator after one; set table separator; a function writes nothing
call interpreter%init(scratch)
open(newunit=unit, file='foresight_script_test_wtable.dat')
write(unit, '(A)') '1 2 3 a', '2 4 5 b', '# c', '', '3 6 7 c'
close(unit)
call interpreter%run_text("set table 'foresight_script_test_wtable.txt'"//new_line('a')// &
                          'plot "foresight_script_test_wtable.dat" with table'//new_line('a')// &
                          'plot "foresight_script_test_wtable.dat" u 1:($2*1.5):(strcol(4)):4 w table if $1 > 1'// &
                          new_line('a')//'plot "foresight_script_test_wtable.dat" u 0:(1e-20) every 2 w table, x w table'// &
                          new_line('a')//'set table $T separator comma'//new_line('a')// &
                          'plot "foresight_script_test_wtable.dat" u (strcol(4)):1:2 w table; unset table'// &
                          new_line('a')//"set table 'foresight_script_test_wtable.txt' append"//new_line('a')// &
                          'plot "foresight_script_test_wtable.dat" u 1:2 w table; unset table', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(120) = iostat == 0_I4P .and. &
   file_is('foresight_script_test_wtable.txt', [character(len=24) :: ' 1'//achar(9)//' 2'//achar(9)//' 3', &
           ' 2'//achar(9)//' 4'//achar(9)//' 5', ' 3'//achar(9)//' 6'//achar(9)//' 7', &
           ' 2'//achar(9)//' 6'//achar(9)//' b'//achar(9)//' nan', ' 3'//achar(9)//' 9'//achar(9)//' c'//achar(9)//' nan', &
           ' 0'//achar(9)//' 1e-20', ' 1'//achar(9)//' 1e-20', ' 1, 2', ' 2, 4', ' 3, 6'])
if (test_passed(120)) then
   block
      character(len=:), allocatable :: text  !< $T.
      logical                       :: found !< Defined.

      call interpreter%symbols%string_of('$T', text, found)
      test_passed(120) = found
      if (found) test_passed(120) = text == 'a , 1 , 2'//new_line('a')//'b , 2 , 4'//new_line('a')//'c , 3 , 6'// &
                                             new_line('a')
   endblock
endif
call interpreter%run_text('plot "foresight_script_test_wtable.dat" w table', iostat, iomsg)
test_passed(120) = test_passed(120) .and. iostat /= 0_I4P .and. index(iomsg, "requires a previous 'set table'") > 0
open(newunit=unit, file='foresight_script_test_wtable.dat')
close(unit, status='delete')
open(newunit=unit, file='foresight_script_test_wtable.txt')
close(unit, status='delete')

! function blocks, as gnuplot 6.0: ARGC and ARGV, local, return (from a loop too), no return the undefined value,
! global side effects, recursion, a block in a plotted function, print of a block, return at the top level
call interpreter%init(scratch)
call interpreter%run_text("set print 'foresight_script_test_blocks2.txt'"//new_line('a')// &
                          'function $sum << EOF'//new_line('a')//'  s = 0'//new_line('a')// &
                          '  do for [i = 1:ARGC] { s = s + ARGV[i] }'//new_line('a')//'  return s'//new_line('a')// &
                          'EOF'//new_line('a')//'print $sum(1, 2, 3), $sum(), s'//new_line('a')// &
                          'function $max << EOF'//new_line('a')//'  local m = ARGV[1]'//new_line('a')// &
                          '  if (ARGV[2] > m) { m = ARGV[2] }'//new_line('a')//'  return m'//new_line('a')//'EOF'// &
                          new_line('a')//'m = 9; print $max(3, 7), $max(9, 2), m'//new_line('a')// &
                          'function $fact << EOF'//new_line('a')//'  if (ARGV[1] <= 1) { return 1 }'//new_line('a')// &
                          '  return ARGV[1] * $fact(ARGV[1] - 1)'//new_line('a')//'EOF'//new_line('a')// &
                          'function $first << EOF'//new_line('a')// &
                          '  do for [i = 1:5] { if (i == 3) { return sprintf("<%d>", i) } }'//new_line('a')// &
                          'EOF'//new_line('a')//'function $none << EOF'//new_line('a')//'  y = 5'//new_line('a')// &
                          'EOF'//new_line('a')//'print $fact(5), $first(), $none(1), y, ARGC'//new_line('a')// &
                          'function $r << EOF'//new_line('a')//'  return ARGC > 0 ? ARGV[1] + $r() : 100'// &
                          new_line('a')//'EOF'//new_line('a')//'print $r(5)'//new_line('a')//'print $max'//new_line('a')// &
                          'f(x) = $max(x, 0); set xrange [-2:2]; set samples 5; set table $T; plot f(x); unset table'// &
                          new_line('a')//'set print'//new_line('a')//'return'//new_line('a')//'z = 1', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(121) = iostat == 0_I4P .and. &
   file_is('foresight_script_test_blocks2.txt', [character(len=40) :: '6 0 0', '7 9 9', &
           '120 <3> <undefined> 5 0', '105', 'function $max( )', '  local m = ARGV[1]', &
           '  if (ARGV[2] > m) { m = ARGV[2] }', '  return m', ''])
if (test_passed(121)) then
   block
      character(len=:), allocatable :: text  !< $T.
      logical                       :: found !< Defined.
      real(R8P)                     :: z     !< Set after the return, if run.

      call interpreter%symbols%value_of('z', z, found)
      test_passed(121) = .not. found

      call interpreter%symbols%string_of('$T', text, found)
      test_passed(121) = test_passed(121) .and. found
      if (found) test_passed(121) = test_passed(121) .and. index(text, ' 2  2  i') > 0 .and. index(text, '-1  0  i') > 0
   endblock
endif
call interpreter%run_text('print $nosuch(1)', iostat, iomsg)
test_passed(121) = test_passed(121) .and. iostat /= 0_I4P .and. index(iomsg, 'Not a function block: $nosuch') > 0
call interpreter%run_text('function $bad << EOF'//new_line('a')//'  nosuchcommand'//new_line('a')//'EOF'// &
                          new_line('a')//'print $bad()', iostat, iomsg)
test_passed(121) = test_passed(121) .and. iostat /= 0_I4P .and. index(iomsg, '$bad:1: unsupported command') > 0
open(newunit=unit, file='foresight_script_test_blocks2.txt')
close(unit, status='delete')

! gnuplot's GPVAL_* variables (kept by reset session and undefine), set encoding, exit and quit
call interpreter%init(scratch)
call interpreter%run_text("set print 'foresight_script_test_gpval.txt'"//new_line('a')// &
                          'save = GPVAL_ENCODING; set encoding utf8; print save, GPVAL_ENCODING; set encoding save'// &
                          new_line('a')//'undefine GPVAL_*; reset session; print GPVAL_ENCODING, GPVAL_VERSION, GPVAL_TERM'// &
                          new_line('a')//'print strstrt(GPVAL_COMPILE_OPTIONS, "+STATS") > 0, '// &
                          'strstrt(GPVAL_COMPILE_OPTIONS, "+LIBCERF") > 0'//new_line('a')// &
                          'if (!strstrt(GPVAL_COMPILE_OPTIONS, "+LIBCERF")) { print "no libcerf"; exit }'// &
                          new_line('a')//'print "not reached"', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(122) = iostat == 0_I4P
call interpreter%run_text("set print 'foresight_script_test_gpval.txt' append; print 'next'; quit; print 'no'", &
                          iostat, iomsg)
test_passed(122) = test_passed(122) .and. iostat == 0_I4P
call interpreter%run_text("print 'after quit, nothing'", iostat, iomsg)
call interpreter%init(scratch)
call interpreter%run_text("exit status 3; print 'no'", iostat, iomsg)
test_passed(122) = test_passed(122) .and. iostat == 0_I4P .and. interpreter%exit_status == 3_I4P .and. &
   file_is('foresight_script_test_gpval.txt', [character(len=24) :: 'default utf8', 'default 6.0 svg', '1 0', &
           'no libcerf', 'next'])
call interpreter%init(scratch)
call interpreter%run_text('exit error "boom"', iostat, iomsg)
test_passed(122) = test_passed(122) .and. iostat /= 0_I4P .and. index(iomsg, 'boom') > 0
call interpreter%run_text('set encoding cp1252', iostat, iomsg)
test_passed(122) = test_passed(122) .and. iostat /= 0_I4P .and. index(iomsg, 'only default, utf8, locale and iso_8859_1') > 0
open(newunit=unit, file='foresight_script_test_gpval.txt')
close(unit, status='delete')

! set tics (every axis), set ticscale, scale per axis, unset tics, as gnuplot 6.0: a scale MAJOR alone makes MINOR its
! half, default is 1, 0.5; the tick lengths and the viewer attribute follow
call interpreter%init(scratch)
call interpreter%run_text('set tics nomirror out scale 2, 0.25; set ytics scale default', iostat, iomsg)
test_passed(123) = iostat == 0_I4P
associate(panel => interpreter%figure%panels(1))
   test_passed(123) = test_passed(123) .and. .not. panel%xaxis%tics%mirror .and. panel%x2axis%tics%out .and. &
                      all(panel%xaxis%tics%scale == [2.0_R8P, 0.25_R8P]) .and. &
                      all(panel%cbaxis%tics%scale == [2.0_R8P, 0.25_R8P]) .and. &
                      all(panel%yaxis%tics%scale == [1.0_R8P, 0.5_R8P]) .and. &
                      index(panel%xaxis%tics%attribute(), 'out scale 2e0 2.5e-1') > 0
endassociate
call interpreter%run_text('set ticscale 3', iostat, iomsg)
test_passed(123) = test_passed(123) .and. iostat == 0_I4P .and. &
                   all(interpreter%figure%panels(1)%y2axis%tics%scale == [3.0_R8P, 1.5_R8P])
call interpreter%run_text('unset tics', iostat, iomsg)
test_passed(123) = test_passed(123) .and. iostat == 0_I4P .and. &
                   interpreter%figure%panels(1)%xaxis%tics%attribute() == 'none' .and. &
                   interpreter%figure%panels(1)%cbaxis%tics%attribute() == 'none'
call interpreter%run_text('set tics; set output "foresight_script_test_tics.svg"; set tics scale 2; plot [0:10] x', &
                          iostat, iomsg)
test_passed(123) = test_passed(123) .and. iostat == 0_I4P .and. &
                   interpreter%figure%panels(1)%xaxis%tics%attribute() /= 'none'
! set tics front: the grid over the data, as set grid front (gnuplot's grid_tics_in_front)
call interpreter%run_text('set tics front', iostat, iomsg)
test_passed(123) = test_passed(123) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%grid_front
call interpreter%run_text('set tics bogus', iostat, iomsg)
test_passed(123) = test_passed(123) .and. iostat /= 0_I4P .and. index(iomsg, 'supported options are mirror') > 0
open(newunit=unit, file='foresight_script_test_tics.svg')
close(unit, status='delete')

! set key reverse, Left, invert, opaque, samplen, width, offset, title, default, abbreviations; set title offset, font
call interpreter%init(scratch)
call interpreter%run_text('set key reverse Left invert opaque samplen 2 width 1.5 offset 1,-2 title "T" bot cent '// &
                          'font ",8" noenhanced; set title "top" offset 0,-1 font ",14" noenh; set key autotitle column', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(124) = iostat == 0_I4P
associate(panel => interpreter%figure%panels(1))
   test_passed(124) = test_passed(124) .and. panel%key_reverse .and. panel%key_left .and. panel%key_invert .and. &
                      panel%key_opaque .and. panel%key_samplen == 2.0_R8P .and. panel%key_extra == 1.5_R8P .and. &
                      all(panel%key_offset == [1.0_R8P, -2.0_R8P]) .and. panel%key_title == 'T' .and. &
                      panel%key_v == 'bottom' .and. panel%key_h == 'center' .and. &
                      all(panel%title_offset == [0.0_R8P, -1.0_R8P]) .and. panel%title == 'top' .and. &
                      interpreter%autotitle == 'columnhead'
endassociate
call interpreter%run_text('set key default', iostat, iomsg)
associate(panel => interpreter%figure%panels(1))
   test_passed(124) = test_passed(124) .and. iostat == 0_I4P .and. .not. panel%key_reverse .and. &
                      .not. panel%key_invert .and. panel%key_samplen < 0.0_R8P .and. len(panel%key_title) == 0 .and. &
                      panel%key_v == 'top' .and. panel%key_h == 'right'
endassociate
call interpreter%run_text('set key noenhanced', iostat, iomsg)
test_passed(124) = test_passed(124) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%key_plain
call interpreter%run_text('set key enhanced', iostat, iomsg)
test_passed(124) = test_passed(124) .and. iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%key_plain

! set lmargin|rmargin|tmargin|bmargin [at screen] N, set margins L,R,B,T, unset: the border where they say (characters
! 0.6 font sizes wide and 1 high, screen fractions from the bottom left)
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 400,300; set output "foresight_script_test_margins.svg"'//new_line('a')// &
                          'set lmargin 10; set rmargin at screen 0.9; set tmargin 3; set bmargin at screen 0.2'// &
                          new_line('a')//'plot [0:10] x notitle', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(125) = iostat == 0_I4P .and. file_has('foresight_script_test_margins.svg', &
                   '<rect x="72" y="36" width="288" height="204" fill="none" stroke="black"')
call interpreter%run_text('set margins 1, 2, at screen 0.1, 4', iostat, iomsg)
associate(panel => interpreter%figure%panels(1))
   test_passed(125) = test_passed(125) .and. iostat == 0_I4P .and. &
                      all(panel%margin_user == [1.0_R8P, 2.0_R8P, 4.0_R8P, 0.1_R8P]) .and. &
                      all(panel%margin_screen .eqv. [.false., .false., .false., .true.])
endassociate
call interpreter%run_text('unset margins; set lmargin 3; unset lmargin', iostat, iomsg)
test_passed(125) = test_passed(125) .and. iostat == 0_I4P .and. all(interpreter%figure%panels(1)%margin_user < 0.0_R8P)
call interpreter%run_text('set lmargin at graph 0.1', iostat, iomsg)
test_passed(125) = test_passed(125) .and. iostat /= 0_I4P .and. index(iomsg, 'only screen') > 0
open(newunit=unit, file='foresight_script_test_margins.svg')
close(unit, status='delete')

! rand (gnuplot's generator, to its digits), exist, the old one-line if (else, and refused inside blocks), set bars,
! set dummy, set autoscale, set xrange [] and noextend
call interpreter%init(scratch)
call interpreter%run_text("set print 'foresight_script_test_batch.txt'"//new_line('a')// &
                          'print rand(0), rand(-1), rand(5); print exist("rand")'//new_line('a')// &
                          'x = 1; if (x == 2) print "no"; else print "else"; print "too"'//new_line('a')// &
                          'if (x == 1) print "yes"; print "same line"'//new_line('a')// &
                          'if (x == 2) print "skipped"; print "skipped too"'//new_line('a')// &
                          'set print', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(126) = iostat == 0_I4P .and. &
   file_is('foresight_script_test_batch.txt', [character(len=60) :: &
           '0.222457440974512 0.222457440974512 0.999998420858381', '0', 'else', 'too', 'yes', 'same line'])
call interpreter%run_text('do for [i=1:2] { if (i == 1) print "x"; print "y" }', iostat, iomsg)
test_passed(126) = test_passed(126) .and. iostat /= 0_I4P .and. index(iomsg, 'Old-style if/else') > 0
call interpreter%run_text('set bars 2; set dummy t; set xrange [1:5]; set autoscale x; set yrange [2:3] noextend'// &
                          new_line('a')//'set yrange []; set autoscale ymax; set autoscale xfix', iostat, iomsg)
associate(panel => interpreter%figure%panels(1))
   test_passed(126) = test_passed(126) .and. iostat == 0_I4P .and. panel%errorbar_size == 2.0_R8P .and. &
                      interpreter%dummy == 't' .and. .not. panel%xaxis%min_fixed .and. .not. panel%xaxis%max_fixed &
                      .and. panel%xaxis%noextend .and. panel%yaxis%noextend .and. panel%yaxis%min_fixed .and. &
                      panel%yaxis%min_user == 2.0_R8P .and. .not. panel%yaxis%max_fixed
endassociate
call interpreter%run_text('set xrange [0:1]; plot t**2', iostat, iomsg)
test_passed(126) = test_passed(126) .and. iostat == 0_I4P
call interpreter%run_text('print rand(1.5)', iostat, iomsg)
test_passed(126) = test_passed(126) .and. iostat /= 0_I4P .and. index(iomsg, 'Illegal seed value') > 0
! writeback read (check 265), another option refused
call interpreter%run_text('set xrange [0:1] backwrite', iostat, iomsg)
test_passed(126) = test_passed(126) .and. iostat /= 0_I4P .and. index(iomsg, 'unsupported option "backwrite"') > 0
open(newunit=unit, file='foresight_script_test_batch.txt')
close(unit, status='delete')

! set grid: the lines named (no to remove, the others kept, x and y when none), front, the line style (lt 0 the dots,
! lt -1 black), as gnuplot 6.0; the viewer gets them
call interpreter%init(scratch)
call interpreter%run_text('set grid y; set grid mx noy x2tics front lw 2 dt 3 lc "gray"', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
associate(panel => interpreter%figure%panels(1))
   test_passed(127) = iostat == 0_I4P .and. panel%grid .and. &
                      all(panel%grid_lines .eqv. [.false., .false., .true., .false., .true., .false.]) .and. &
                      panel%grid_front .and. panel%grid_lw == 2.0_R8P .and. panel%grid_dt == 3_I4P .and. &
                      panel%grid_lc == '#bebebe'
endassociate
call interpreter%run_text('unset grid; set grid lt -1 back; set output "foresight_script_test_grid.svg"; plot [0:1] x', &
                          iostat, iomsg)
test_passed(127) = test_passed(127) .and. iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%grid_front .and. &
                   file_has('foresight_script_test_grid.svg', 'data-grid-style="black 2e0 "')
! the z and vertical grids of the 3D views
call interpreter%run_text('set grid ztics vertical', iostat, iomsg)
test_passed(127) = test_passed(127) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%view3d%grid_z .and. &
                   interpreter%figure%panels(1)%view3d%grid_vertical
call interpreter%run_text('set grid wtics', iostat, iomsg)
test_passed(127) = test_passed(127) .and. iostat /= 0_I4P .and. index(iomsg, 'unsupported option "wtics"') > 0
open(newunit=unit, file='foresight_script_test_grid.svg')
close(unit, status='delete')

! set zeroaxis (gnuplot's black dots), set border line options, set termoption dash and noenhanced
call interpreter%init(scratch)
call interpreter%run_text('set zeroaxis; set y2zeroaxis lw 2 lt 1; set border 3 lw 2 lc "red" front'//new_line('a')// &
                          'set termoption dash noenhanced font ",10"; set output "foresight_script_test_zero.svg"'// &
                          new_line('a')//'plot [-5:5] x', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
associate(panel => interpreter%figure%panels(1))
   test_passed(128) = iostat == 0_I4P .and. all(panel%zero_axes .eqv. [.true., .true., .true., .false.]) .and. &
                      panel%zero_lw == 2.0_R8P .and. panel%zero_dt == 1_I4P .and. panel%border == 3_I4P .and. &
                      panel%border_lw == 2.0_R8P .and. panel%border_lc == '#ff0000'
endassociate
test_passed(128) = test_passed(128) .and. file_has('foresight_script_test_zero.svg', 'stroke="#ff0000" stroke-width="2"')
test_passed(128) = test_passed(128) .and. .not. interpreter%figure%enhanced
call interpreter%run_text('unset zeroaxis; set termoption enhanced', iostat, iomsg)
test_passed(128) = test_passed(128) .and. iostat == 0_I4P .and. interpreter%figure%enhanced .and. &
                   .not. any(interpreter%figure%panels(1)%zero_axes)
open(newunit=unit, file='foresight_script_test_zero.svg')
close(unit, status='delete')

! enhanced text, on by default in the scripts (gnuplot's svg terminal): the title, labels, key entries and tick labels
! as <tspan> elements; noenhanced texts, the automatic titles (file name, function) and set terminal noenhanced as
! they are
call interpreter%init(scratch)
test_passed(129) = interpreter%figure%enhanced
call interpreter%run_text('set term svg size 400,300; set output "foresight_script_test_enh.svg"'//new_line('a')// &
                          'set title "T_{n-1}"; set xlabel "x_1" noenhanced; set ylabel "{/Symbol a}^2"'// &
                          new_line('a')//'set label 1 "L_a" at 0,0; set label 2 "N_b" at 1,1 noenhanced'// &
                          new_line('a')//'set xtics ("t_1" -2, "t^2" 2); set ytics ("u_1" 0) noenhanced'// &
                          new_line('a')//'x_v = 1; plot [-5:5] x**2 t "e^{x}", x title "p_q" noenhanced, x_v*x', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(129) = test_passed(129) .and. iostat == 0_I4P .and. &
                   file_has('foresight_script_test_enh.svg', '<tspan>T</tspan><tspan font-size="9.6" dy="3.6">n-1') .and. &
                   file_has('foresight_script_test_enh.svg', '>x_1</text>') .and. &
                   file_has('foresight_script_test_enh.svg', '<tspan>'//char(206)//char(177)//'</tspan>') .and. &
                   file_has('foresight_script_test_enh.svg', '<tspan>L</tspan>') .and. &
                   file_has('foresight_script_test_enh.svg', '>N_b</text>') .and. &
                   file_has('foresight_script_test_enh.svg', '<tspan>t</tspan><tspan font-size="9.6" dy="-6">2') .and. &
                   file_has('foresight_script_test_enh.svg', '>u_1</text>') .and. &
                   file_has('foresight_script_test_enh.svg', '<tspan>e</tspan>') .and. &
                   file_has('foresight_script_test_enh.svg', '>p_q</text>') .and. &
                   file_has('foresight_script_test_enh.svg', '>x_v*x</text>')
call interpreter%run_text('set terminal svg noenhanced; replot', iostat, iomsg)
test_passed(129) = test_passed(129) .and. iostat == 0_I4P .and. .not. interpreter%figure%enhanced .and. &
                   file_has('foresight_script_test_enh.svg', '>T_{n-1}</text>') .and. &
                   .not. file_has('foresight_script_test_enh.svg', '<tspan')
open(newunit=unit, file='foresight_script_test_enh.svg')
close(unit, status='delete')

! set for [...] and unset for [...]: the option for each value, nested clauses, the loop variable local (gnuplot 6.0:
! labels L1, a1, a2, b1, b2 left); set for is not set format
call interpreter%init(scratch)
call interpreter%run_text('i = 7; set for [i=1:3] label i sprintf("L%d",i) at i,i'//new_line('a')// &
                          'set for [w in "a b"] for [k=1:2] label sprintf("%s%d",w,k) at k,0'//new_line('a')// &
                          'unset for [i=2:3] label i', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(130) = iostat == 0_I4P .and. size(interpreter%figure%panels(1)%notes) == 5
if (test_passed(130)) test_passed(130) = interpreter%figure%panels(1)%notes(1)%text == 'L1' .and. &
                                         interpreter%figure%panels(1)%notes(5)%text == 'b2'
block
   real(R8P) :: v     !< Value.
   logical   :: found !< Variable found.

   call interpreter%symbols%value_of('i', v, found)
   test_passed(130) = test_passed(130) .and. found .and. v == 7.0_R8P
endblock
call interpreter%run_text('set for [i=1:2]', iostat, iomsg)
test_passed(130) = test_passed(130) .and. iostat /= 0_I4P .and. index(iomsg, 'an option is expected') > 0

! set format power conversions (gnuplot 6.0's labels): 10^{%T} on a log axis, %.0s %c on a linear one
call interpreter%init(scratch)
call interpreter%run_text('set term svg; set output "foresight_script_test_powers.svg"; set logscale y'//new_line('a')// &
                          'set format y "10^{%T}"; set format x "%.0s %cHz"; plot [0:5e6] [1:1e5] x', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(131) = iostat == 0_I4P
test_passed(131) = test_passed(131) .and. file_has('foresight_script_test_powers.svg', 'dy="-6">3</tspan>') .and. &
                   file_has('foresight_script_test_powers.svg', '>2 MHz</text>') .and. &
                   file_has('foresight_script_test_powers.svg', '>0 Hz</text>')
open(newunit=unit, file='foresight_script_test_powers.svg')
close(unit, status='delete')

! tick label options: format, font (the labels' size, the viewer told), offset (characters 0.6 by 1 font size, y up),
! textcolor, of an axis and of every axis (set tics)
call interpreter%init(scratch)
call interpreter%run_text('set term svg; set output "foresight_script_test_ticlabels.svg"'//new_line('a')// &
                          'set tics format "%.2f" tc rgb "blue" font ",8"'//new_line('a')// &
                          'set xtics 1 offset 0,-1 textcolor rgb "red" format "%.1f" nomirror'//new_line('a')// &
                          'plot [0:5] [0:1] x/5', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(132) = iostat == 0_I4P
if (test_passed(132)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(132) = panel%xaxis%tics%format == '%.1f' .and. panel%yaxis%tics%format == '%.2f' .and. &
                         trim(panel%xaxis%tics%color) == '#ff0000' .and. trim(panel%yaxis%tics%color) == '#0000ff' &
                         .and. all(panel%xaxis%tics%offset == [0.0_R8P, -1.0_R8P]) .and. &
                         all(panel%yaxis%tics%offset == 0.0_R8P) .and. .not. panel%xaxis%tics%mirror
   endassociate
endif
test_passed(132) = test_passed(132) .and. file_has('foresight_script_test_ticlabels.svg', 'fill="#ff0000">2.0</text>') &
                   .and. file_has('foresight_script_test_ticlabels.svg', 'fill="#0000ff">0.40</text>') .and. &
                   file_has('foresight_script_test_ticlabels.svg', &
                            'data-xtics="offset 0 -1e0 font 8e0 0 0 - color #ff0000 * 1 *"') .and. &
                   file_has('foresight_script_test_ticlabels.svg', 'font-size="8" text-anchor="end" fill="#0000ff">0.40<')
open(newunit=unit, file='foresight_script_test_ticlabels.svg')
close(unit, status='delete')
call interpreter%run_text('set xtics format "%q"', iostat, iomsg)
test_passed(132) = test_passed(132) .and. iostat /= 0_I4P .and. index(iomsg, 'unsupported conversion') > 0

! tick placement: axis (on the zero axis of the other coordinate, no margin for the labels), border, rangelimited (the
! ticks and the border side within the data range)
call interpreter%init(scratch)
call interpreter%run_text('$D << EOD'//new_line('a')//'-1 0.2'//new_line('a')//'1 1.2'//new_line('a')//'3 0.5'// &
                          new_line('a')//'EOD'//new_line('a')// &
                          'set term svg size 400,300; set output "foresight_script_test_axis.svg"'//new_line('a')// &
                          'set xtics axis; set ytics nomirror rangelimited; set border 3'//new_line('a')// &
                          'plot [-3:5][-1:2] $D w lp', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(133) = iostat == 0_I4P
if (test_passed(133)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(133) = panel%xaxis%tics%on_axis .and. panel%yaxis%tics%rangelimited .and. panel%yaxis%has_data .and. &
                         panel%yaxis%data_lo == 0.2_R8P .and. panel%yaxis%data_hi == 1.2_R8P
   endassociate
endif
test_passed(133) = test_passed(133) .and. file_has('foresight_script_test_axis.svg', 'data-xtics="axis"') .and. &
                   file_has('foresight_script_test_axis.svg', 'data-ytics="rangelimited 2e-1 1.2e0"') .and. &
                   .not. file_has('foresight_script_test_axis.svg', '>1.5</text>') .and. &
                   file_has('foresight_script_test_axis.svg', '>0.5</text>')
open(newunit=unit, file='foresight_script_test_axis.svg')
close(unit, status='delete')
call interpreter%run_text('set tics border norangelimit', iostat, iomsg)
test_passed(133) = test_passed(133) .and. iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%xaxis%tics%on_axis &
                   .and. .not. interpreter%figure%panels(1)%yaxis%tics%rangelimited

! key options: box line (lt, lw), maxrows (columns filled top down), spacing, height, textcolor variable, auto (autotitle)
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 700,320; set output "foresight_script_test_keyopts.svg"'//new_line('a')// &
                          'set key box lt 4 lw 2 maxrows 3 spacing 1.5 height 1 tc variable fixed'//new_line('a')// &
                          'plot for [k=1:7] k*x t sprintf("curve %d", k)', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(134) = iostat == 0_I4P
if (test_passed(134)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(134) = panel%key_maxrows == 3_I4P .and. panel%key_spacing == 1.5_R8P .and. panel%key_height == 1.0_R8P &
                         .and. trim(panel%key_tc) == 'variable' .and. trim(panel%key_box_lc) == '#e69f00' .and. &
                         panel%key_box_lw == 2.0_R8P
   endassociate
endif
test_passed(134) = test_passed(134) .and. file_has('foresight_script_test_keyopts.svg', 'fill="#9400d3">curve 1</text>') &
                   .and. file_has('foresight_script_test_keyopts.svg', 'stroke="#e69f00" stroke-width="2"')
open(newunit=unit, file='foresight_script_test_keyopts.svg')
close(unit, status='delete')
call interpreter%run_text('set key auto column; set key maxcols auto textcolor rgb "red" default', iostat, iomsg)
test_passed(134) = test_passed(134) .and. iostat == 0_I4P .and. interpreter%autotitle == 'file' .and. &
                   interpreter%figure%panels(1)%key_maxrows == 0_I4P .and. len_trim(interpreter%figure%panels(1)%key_tc) == 0
call interpreter%run_text('set key auto column', iostat, iomsg)
test_passed(134) = test_passed(134) .and. iostat == 0_I4P .and. interpreter%autotitle == 'columnhead'

! a coordinate of set label, arrow and object written with blanks, as gnuplot: `at 1, 3 + 2`
call interpreter%init(scratch)
call interpreter%run_text("set label 1 'a' at 1 + 1, 3 + 2 center; set arrow 1 from 0, 0 to 1, 2 * 3 nohead", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(135) = iostat == 0_I4P
if (test_passed(135)) test_passed(135) = interpreter%figure%panels(1)%notes(1)%at%x == 2.0_R8P .and. &
                                         interpreter%figure%panels(1)%notes(1)%at%y == 5.0_R8P .and. &
                                         interpreter%figure%panels(1)%notes(1)%justify == 'center'

! gnuplot's special functions in expressions (values: gnuplot 6.0's), an integer order, undefined values
call interpreter%init(scratch)
call interpreter%run_text('a = besjn(3, 2.5); b = gamma(4.5); c = round(-2.5); d = igamma(2, 1)'//new_line('a')// &
                          'e = lambertw(1); f = EllipticK(0.5)', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
block
   real(R8P) :: v(6)     !< Values.
   logical   :: found(6) !< Variables found.
   logical   :: is_int   !< Integer value.

   call interpreter%symbols%value_of('a', v(1), found(1))
   call interpreter%symbols%value_of('b', v(2), found(2))
   call interpreter%symbols%value_of('c', v(3), found(3), is_int)
   call interpreter%symbols%value_of('d', v(4), found(4))
   call interpreter%symbols%value_of('e', v(5), found(5))
   call interpreter%symbols%value_of('f', v(6), found(6))
   test_passed(136) = iostat == 0_I4P .and. all(found) .and. is_int .and. v(3) == -3.0_R8P .and. &
                      abs(v(1) - 0.21660039103911355_R8P) < 1.0e-15_R8P .and. &
                      abs(v(2) - 11.63172839656745_R8P) < 1.0e-13_R8P .and. &
                      abs(v(4) - 0.26424111765711505_R8P) < 1.0e-15_R8P .and. &
                      abs(v(5) - 0.56714329040978384_R8P) < 1.0e-15_R8P .and. &
                      abs(v(6) - 1.6857503548125963_R8P) < 1.0e-15_R8P
endblock
call interpreter%run_text('g = besjn(2.0, 1)', iostat, iomsg)
test_passed(136) = test_passed(136) .and. iostat /= 0_I4P .and. index(iomsg, 'must be an integer') > 0
call interpreter%run_text('g = gamma(-1)', iostat, iomsg)
test_passed(136) = test_passed(136) .and. iostat /= 0_I4P .and. index(iomsg, 'undefined value') > 0
call interpreter%run_text('besj0(x) = x', iostat, iomsg)
test_passed(136) = test_passed(136) .and. iostat /= 0_I4P .and. index(iomsg, 'builtin function') > 0

! set pointsize: the default point size of the items without their own (gnuplot: ps replaces it); unset, reset: 1
call interpreter%init(scratch)
call interpreter%run_text('$P << EOD'//new_line('a')//'1 1'//new_line('a')//'2 2'//new_line('a')//'EOD'//new_line('a')// &
                          'set pointsize 2; plot $P w p pt 7, $P w p pt 7 ps 1.5', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(137) = iostat == 0_I4P
if (test_passed(137)) test_passed(137) = interpreter%figure%panels(1)%series(1)%style%pointsize == 2.0_R8P .and. &
                                         interpreter%figure%panels(1)%series(2)%style%pointsize == 1.5_R8P
call interpreter%run_text('unset pointsize', iostat, iomsg)
test_passed(137) = test_passed(137) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%point_scale == 1.0_R8P
call interpreter%run_text('set pointsize 3; reset', iostat, iomsg)
test_passed(137) = test_passed(137) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%point_scale == 1.0_R8P
call interpreter%run_text('set pointsize -1', iostat, iomsg)
test_passed(137) = test_passed(137) .and. iostat /= 0_I4P .and. index(iomsg, 'must be positive') > 0

! set linetype: the color, width, dash, point of the series of a linetype; persistent across reset; set linetype cycle
call interpreter%init(scratch)
call interpreter%run_text('set linetype 1 lc "dark-red" lw 3 pt 7 ps 1.5; set for [i=1:2] linetype 8+i lc "black"'// &
                          new_line('a')//'reset'//new_line('a')//'plot for [k=1:10] k*x', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(138) = iostat == 0_I4P
if (test_passed(138)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(138) = panel%series(1)%style%color == '#8b0000' .and. panel%series(1)%style%linewidth == 3.0_R8P &
                         .and. panel%series(1)%style%pointtype == 7_I4P .and. panel%series(1)%style%pointsize == 1.5_R8P &
                         .and. panel%series(9)%style%color == '#000000' .and. panel%series(10)%style%color == '#000000' &
                         .and. panel%series(2)%style%linewidth == 1.0_R8P .and. size(panel%linecolors) == 16
   endassociate
endif
call interpreter%run_text('set linetype cycle 3', iostat, iomsg)
test_passed(138) = test_passed(138) .and. iostat == 0_I4P .and. size(interpreter%figure%panels(1)%linecolors) == 3
call interpreter%run_text('set linetype 1 lc palette', iostat, iomsg)
test_passed(138) = test_passed(138) .and. iostat /= 0_I4P

! set offsets: the autoscaled ends moved out, in axis units or graph fractions, before the tick extension; noextend
! (set autoscale) honoured; functions sampled on the range before (gnuplot 6.0's ranges)
call interpreter%init(scratch)
call interpreter%run_text('set term svg; set output "foresight_script_test_offsets.svg"'//new_line('a')// &
                          'set offsets graph 0.05, 0, 2, 2; set autoscale noextend; plot sin(x)', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(139) = iostat == 0_I4P
if (test_passed(139)) test_passed(139) = interpreter%figure%panels(1)%xaxis%lo == -11.0_R8P .and. &
                                         interpreter%figure%panels(1)%xaxis%hi == 10.0_R8P .and. &
                                         abs(interpreter%figure%panels(1)%yaxis%hi - 2.99938455761244_R8P) < 1.0e-12_R8P
call interpreter%run_text('$O << EOD'//new_line('a')//'1 2'//new_line('a')//'3 5'//new_line('a')//'4 3'//new_line('a')// &
                          'EOD'//new_line('a')//'reset; set term svg; set output "foresight_script_test_offsets.svg"'// &
                          new_line('a')//'set offsets 1, 1, 1, 1; plot [0:5] $O', iostat, iomsg)
test_passed(139) = test_passed(139) .and. iostat == 0_I4P
if (test_passed(139)) test_passed(139) = interpreter%figure%panels(1)%xaxis%lo == 0.0_R8P .and. &
                                         interpreter%figure%panels(1)%xaxis%hi == 5.0_R8P .and. &
                                         interpreter%figure%panels(1)%yaxis%lo == 1.0_R8P .and. &
                                         interpreter%figure%panels(1)%yaxis%hi == 6.0_R8P
call interpreter%run_text('unset offsets', iostat, iomsg)
test_passed(139) = test_passed(139) .and. iostat == 0_I4P .and. all(interpreter%figure%panels(1)%yaxis%offset == 0.0_R8P)
open(newunit=unit, file='foresight_script_test_offsets.svg')
close(unit, status='delete')

! set timestamp: the date and time now (SOURCE_DATE_EPOCH if set) in the bottom left margin, the plot area a row
! shorter; top, rotate, offset, textcolor; unset
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 500,300; set output "foresight_script_test_stamp.svg"'//new_line('a')// &
                          'set timestamp "stamp %Y" offset 1,0 tc "red"; plot x', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(140) = iostat == 0_I4P .and. file_has('foresight_script_test_stamp.svg', 'fill="#ff0000">stamp 20') .and. &
                   file_has('foresight_script_test_stamp.svg', 'data-area="35.8 490 16 254"')
call interpreter%run_text('set timestamp top rotate; replot', iostat, iomsg)
test_passed(140) = test_passed(140) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%stamp_top .and. &
                   interpreter%figure%panels(1)%stamp_rotate .and. &
                   file_has('foresight_script_test_stamp.svg', 'transform="rotate(-90')
call interpreter%run_text('unset timestamp', iostat, iomsg)
test_passed(140) = test_passed(140) .and. iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%stamp
open(newunit=unit, file='foresight_script_test_stamp.svg')
close(unit, status='delete')

! set clip: gnuplot's defaults (clip one, no clip two: a segment with both ends out of the plot area is not drawn, as
! the asymptotes of tan(x)); set clip two draws it; set clip points hides the markers crossing the border; unset clip
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 400,300; set output "foresight_script_test_clip.svg"'//new_line('a')// &
                          'set yrange [-3:3]; set samples 50; plot [-4:4] tan(x) notitle', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
block
   integer(I4P) :: lines(2) !< Series polylines without and with clip two.

   lines(1) = series_polylines('foresight_script_test_clip.svg')
   call interpreter%run_text('set clip two; replot', iostat, iomsg)
   lines(2) = series_polylines('foresight_script_test_clip.svg')
   test_passed(141) = iostat == 0_I4P .and. lines(1) == 3_I4P .and. lines(2) == 1_I4P .and. &
                      interpreter%figure%panels(1)%clip_two
endblock
call interpreter%run_text('set clip; unset clip one', iostat, iomsg)
test_passed(141) = test_passed(141) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%clip_points .and. &
                   .not. interpreter%figure%panels(1)%clip_one
call interpreter%run_text('unset clip', iostat, iomsg)
test_passed(141) = test_passed(141) .and. iostat == 0_I4P .and. .not. (interpreter%figure%panels(1)%clip_points .or. &
                   interpreter%figure%panels(1)%clip_two)
call interpreter%run_text('set clip sometimes', iostat, iomsg)
test_passed(141) = test_passed(141) .and. iostat /= 0_I4P
open(newunit=unit, file='foresight_script_test_clip.svg')
close(unit, status='delete')

! set parametric: function items in pairs x(t), y(t) over trange ([-5:5] by default, the first inline range), the
! title the pair as written; data items as they are; unset parametric
call interpreter%init(scratch)
call interpreter%run_text('set parametric; set samples 5; plot [0:1] t, t**2; ', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(142) = iostat == 0_I4P
if (test_passed(142)) test_passed(142) = all(interpreter%figure%panels(1)%series(1)%x == &
                                             [0.0_R8P, 0.25_R8P, 0.5_R8P, 0.75_R8P, 1.0_R8P]) .and. &
                                         all(interpreter%figure%panels(1)%series(1)%y == &
                                             [0.0_R8P, 0.0625_R8P, 0.25_R8P, 0.5625_R8P, 1.0_R8P]) .and. &
                                         interpreter%figure%panels(1)%series(1)%title == 't, t**2'
call interpreter%run_text('set samples 3; plot t, 2*t', iostat, iomsg)
test_passed(142) = test_passed(142) .and. iostat == 0_I4P
if (test_passed(142)) test_passed(142) = all(interpreter%figure%panels(1)%series(1)%x == [-5.0_R8P, 0.0_R8P, 5.0_R8P])
call interpreter%run_text('plot sin(t)', iostat, iomsg)
test_passed(142) = test_passed(142) .and. iostat /= 0_I4P .and. index(iomsg, 'not fully specified') > 0
call interpreter%run_text('unset parametric; plot [0:1] x', iostat, iomsg)
test_passed(142) = test_passed(142) .and. iostat == 0_I4P .and. .not. interpreter%parametric

! set jitter: overlapping points of with points spread out on x (swarm), y kept; options; unset jitter
call interpreter%init(scratch)
call interpreter%run_text('$J << EOD'//new_line('a')//'1 5'//new_line('a')//'1 5'//new_line('a')//'1 5'//new_line('a')// &
                          'EOD'//new_line('a')//'set term svg; set output "foresight_script_test_jitter.svg"'// &
                          new_line('a')//'set xrange [0:2]; set yrange [0:10]; plot $J w p pt 7 notitle', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
block
   character(len=:), allocatable :: plain    !< Without jitter.
   character(len=:), allocatable :: jittered !< With jitter.

   plain = text_of_file('foresight_script_test_jitter.svg')
   call interpreter%run_text('set jitter overlap 1.5 spread 0.5 wrap 3 square; replot', iostat, iomsg)
   jittered = text_of_file('foresight_script_test_jitter.svg')
   test_passed(143) = iostat == 0_I4P .and. plain /= jittered .and. &
                      interpreter%figure%panels(1)%jitter_overlap == 1.5_R8P .and. &
                      interpreter%figure%panels(1)%jitter_spread == 0.5_R8P .and. &
                      interpreter%figure%panels(1)%jitter_wrap == 3.0_R8P .and. interpreter%figure%panels(1)%jitter_style == 1_I4P
endblock
call interpreter%run_text('unset jitter', iostat, iomsg)
test_passed(143) = test_passed(143) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%jitter_spread == 0.0_R8P
call interpreter%run_text('set jitter sideways', iostat, iomsg)
test_passed(143) = test_passed(143) .and. iostat /= 0_I4P .and. index(iomsg, 'unrecognized keyword') > 0
open(newunit=unit, file='foresight_script_test_jitter.svg')
close(unit, status='delete')

! markers drawn whole: a marker crossing the border lets its overlay overflow; centres out of the plot area not drawn
call interpreter%init(scratch)
call interpreter%run_text('$M << EOD'//new_line('a')//'0 0'//new_line('a')//'5 5'//new_line('a')//'20 5'//new_line('a')// &
                          'EOD'//new_line('a')//'set term svg; set output "foresight_script_test_marks.svg"'// &
                          new_line('a')//'set xrange [0:10]; set yrange [0:10]; plot $M w p pt 4 notitle', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
block
   character(len=:), allocatable :: svg    !< Output.
   character(len=:), allocatable :: centres !< The fs-pts path.
   integer                       :: moves   !< Markers in it.

   svg = text_of_file('foresight_script_test_marks.svg')
   centres = svg(index(svg, 'class="fs-pts"'):)
   centres = centres(:index(centres, '/>'))
   moves = 0
   do i = 1, len(centres)
      if (centres(i:i) == 'M') moves = moves + 1
   enddo
   test_passed(144) = iostat == 0_I4P .and. index(svg(index(svg, 'class="fs-marks"'):), 'overflow="visible"') > 0 .and. &
                     moves == 2
   call interpreter%run_text('set xrange [-1:11]; set yrange [-1:11]; replot', iostat, iomsg)
   svg = text_of_file('foresight_script_test_marks.svg')
   test_passed(144) = test_passed(144) .and. iostat == 0_I4P .and. &
                     index(svg(index(svg, 'class="fs-marks"'):), 'overflow="hidden"') > 0
endblock
open(newunit=unit, file='foresight_script_test_marks.svg')
close(unit, status='delete')

! reset keeps the linetypes (set linetype, set colorsequence), reset session restores gnuplot's
call interpreter%init(scratch)
call interpreter%run_text('set linetype 1 lw 3; set colorsequence podo; reset', iostat, iomsg)
test_passed(145) = iostat == 0_I4P .and. interpreter%figure%panels(1)%lt_lw(1) == 3.0_R8P .and. &
                  allocated(interpreter%figure%panels(1)%linecolors)
call interpreter%run_text('reset session', iostat, iomsg)
test_passed(145) = test_passed(145) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%lt_lw(1) < 0.0_R8P .and. &
                  .not. allocated(interpreter%figure%panels(1)%linecolors)

! gnuplot's keyword tables, abbreviations in order: style data line/point, with e (yerrorbars), smooth freq/mcs/cum
call interpreter%init(scratch)
call interpreter%run_text('set style data line', iostat, iomsg)
test_passed(146) = iostat == 0_I4P .and. interpreter%data_style == 'lines'
call interpreter%run_text('set style data point', iostat, iomsg)
test_passed(146) = test_passed(146) .and. iostat == 0_I4P .and. interpreter%data_style == 'points'
call interpreter%run_text('set style data e', iostat, iomsg)
test_passed(146) = test_passed(146) .and. iostat == 0_I4P .and. interpreter%data_style == 'yerrorbars'
call interpreter%run_text('set style data errorl', iostat, iomsg)
test_passed(146) = test_passed(146) .and. iostat == 0_I4P .and. interpreter%data_style == 'yerrorlines'
call interpreter%run_text('set style data his', iostat, iomsg)
test_passed(146) = test_passed(146) .and. iostat == 0_I4P .and. interpreter%data_style == 'histeps'
call interpreter%run_text('$F << EOD'//new_line('a')//'1'//new_line('a')//'1'//new_line('a')//'2'//new_line('a')// &
                          'EOD'//new_line('a')//'plot $F u 1:(1) smooth freq w l, $F u 1:(1) smooth cum w l, '// &
                          '$F u 1:1 smooth mcs w l', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(146) = test_passed(146) .and. iostat == 0_I4P
if (test_passed(146)) test_passed(146) = all(interpreter%figure%panels(1)%series(1)%y == [2.0_R8P, 1.0_R8P]) .and. &
                                       all(interpreter%figure%panels(1)%series(2)%y == [2.0_R8P, 3.0_R8P])
call interpreter%run_text('set style data linesx', iostat, iomsg)
test_passed(146) = test_passed(146) .and. iostat /= 0_I4P

! plot items as gnuplot 6.0: assignments done in turn, NaN, a sampling range per item, columnheader(EXPR), for [i=A:*]
call interpreter%init(scratch)
call interpreter%run_text('set samples 3; plot [0:1] s=.1, s*x, s=.3, s*x, NaN', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(147) = iostat == 0_I4P
if (test_passed(147)) test_passed(147) = size(interpreter%figure%panels(1)%series) == 3
if (test_passed(147)) test_passed(147) = abs(interpreter%figure%panels(1)%series(1)%y(3) - 0.1_R8P) < 1.0e-12_R8P .and. &
                                       abs(interpreter%figure%panels(1)%series(2)%y(3) - 0.3_R8P) < 1.0e-12_R8P .and. &
                                       .not. any(interpreter%figure%panels(1)%series(3)%y == &
                                                 interpreter%figure%panels(1)%series(3)%y)
call interpreter%run_text('plot [-2:2] x, [0:*] x**2', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(147) = test_passed(147) .and. iostat == 0_I4P
if (test_passed(147)) test_passed(147) = all(interpreter%figure%panels(1)%series(2)%x == [0.0_R8P, 1.0_R8P, 2.0_R8P]) .and. &
                                       interpreter%figure%panels(1)%series(2)%title == '[0:*] x**2'
call interpreter%run_text('$H << EOD'//new_line('a')//'x b c'//new_line('a')//'1 2 3'//new_line('a')//'2 4 6'// &
                          new_line('a')//'EOD'//new_line('a')//'plot for [i=2:3] $H using 1:i title columnheader(i)', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(147) = test_passed(147) .and. iostat == 0_I4P
if (test_passed(147)) test_passed(147) = size(interpreter%figure%panels(1)%series) == 2 .and. &
                                       interpreter%figure%panels(1)%series(1)%title == 'b' .and. &
                                       interpreter%figure%panels(1)%series(2)%title == 'c'
call interpreter%run_text('plot for [k=2:*] $H using 1:k title columnhead', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(147) = test_passed(147) .and. iostat == 0_I4P
if (test_passed(147)) test_passed(147) = size(interpreter%figure%panels(1)%series) == 2 .and. &
                                       interpreter%figure%panels(1)%series(2)%title == 'c'

call interpreter%run_text('plot $H using 1:2 ti col', iostat, iomsg)
test_passed(147) = test_passed(147) .and. iostat == 0_I4P
if (test_passed(147)) test_passed(147) = interpreter%figure%panels(1)%series(1)%title == 'b'
! axis labels and the title as gnuplot 6.0: offset X[,Y] in characters, tc, font, rotate; title left|center|right
call interpreter%init(scratch)
call interpreter%run_text('set term svg; set output "foresight_script_test_labels.svg"; '// &
                          'set ylabel "YY" offset 2,1 tc rgb "#ff0000" rotate parallel font ",12"; '// &
                          'set xlabel "XX" offset 3; set x2label "X2" offset 0,-1,0; set title "TT" right tc lt 2; plot x', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(148) = iostat == 0_I4P
if (test_passed(148)) test_passed(148) = all(interpreter%figure%panels(1)%label_offset(:, 2) == [2.0_R8P, 1.0_R8P]) .and. &
                                       all(interpreter%figure%panels(1)%label_offset(:, 1) == [3.0_R8P, 0.0_R8P]) .and. &
                                       all(interpreter%figure%panels(1)%label_offset(:, 4) == [0.0_R8P, -1.0_R8P]) .and. &
                                       interpreter%figure%panels(1)%label_color(2) == '#ff0000' .and. &
                                       interpreter%figure%panels(1)%title_anchor == 'end'
block
   character(len=:), allocatable :: svg !< Output.

   svg = text_of_file('foresight_script_test_labels.svg')
   test_passed(148) = test_passed(148) .and. index(svg, 'text-anchor="end" fill=') > 0 .and. &
                     index(svg, 'fill="#ff0000">YY</text>') > 0
endblock
call interpreter%run_text('set title "TT" left; set ylabel "YY" offset 1,', iostat, iomsg)
test_passed(148) = test_passed(148) .and. iostat /= 0_I4P .and. interpreter%figure%panels(1)%title_anchor == 'start'
call interpreter%run_text('set xlabel "XX" sideways', iostat, iomsg)
test_passed(148) = test_passed(148) .and. iostat /= 0_I4P .and. index(iomsg, 'unexpected "sideways"') > 0
open(newunit=unit, file='foresight_script_test_labels.svg')
close(unit, status='delete')

! functions filled as gnuplot 6.0: with boxes, with filledcurves (closed, x1, y=V base after sampling)
call interpreter%init(scratch)
call interpreter%run_text('set samples 3; plot [0:2] x with boxes fs solid, x**2 with filledcurves y=1, '// &
                          'x with filledcurves x1', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(149) = iostat == 0_I4P
if (test_passed(149)) test_passed(149) = interpreter%figure%panels(1)%series(1)%style%with == WITH_BOXES .and. &
                                       all(interpreter%figure%panels(1)%series(1)%y == [0.0_R8P, 1.0_R8P, 2.0_R8P]) .and. &
                                       interpreter%figure%panels(1)%series(2)%style%with == WITH_FILLEDCURVES .and. &
                                       allocated(interpreter%figure%panels(1)%series(2)%ylow)
if (test_passed(149)) test_passed(149) = size(interpreter%figure%panels(1)%series(2)%ylow) == 3 .and. &
                                       all(interpreter%figure%panels(1)%series(2)%ylow == 1.0_R8P) .and. &
                                       interpreter%figure%panels(1)%series(3)%curve_to == 1_I4P
call interpreter%run_text('plot x with filledcurves above x=1', iostat, iomsg)
test_passed(149) = test_passed(149) .and. iostat /= 0_I4P .and. index(iomsg, 'need y=V for a function') > 0
call interpreter%run_text('plot x with yerrorbars', iostat, iomsg)
test_passed(149) = test_passed(149) .and. iostat /= 0_I4P .and. index(iomsg, 'boxes, filledcurves or pm3d') > 0

! lc variable on circles, ellipses and boxes: each shape in its point's color, the key sample in the first one's
call interpreter%init(scratch)
call interpreter%run_text('$C << EOD'//new_line('a')//'1 1 1'//new_line('a')//'2 2 2'//new_line('a')//'3 1 3'// &
                          new_line('a')//'EOD'//new_line('a')//'plot $C using 1:2:(.2):3 with circles lc variable, '// &
                          '$C using 1:2:3 with boxes lc variable, $C using 1:2:(1):(.5):(0):3 with ellipses lc variable', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(150) = iostat == 0_I4P
if (test_passed(150)) test_passed(150) = size(interpreter%figure%panels(1)%series) == 3
if (test_passed(150)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(150) = allocated(panel%series(1)%colors) .and. allocated(panel%series(2)%colors) .and. &
                        allocated(panel%series(3)%colors)
      if (test_passed(150)) test_passed(150) = panel%series(1)%colors(2) == default_color(2_I4P) .and. &
                                             panel%series(2)%colors(3) == default_color(3_I4P) .and. &
                                             panel%series(3)%colors(1) == default_color(1_I4P) .and. &
                                             all(panel%series(1)%radius == 0.2_R8P)
   endassociate
endif
call interpreter%run_text('plot $C using 1:2:3 with steps lc variable', iostat, iomsg)
test_passed(150) = test_passed(150) .and. iostat /= 0_I4P .and. index(iomsg, 'polygons, sectors, the error bars') > 0

! set key columns N (gnuplot's user columns: N columns, filled top down), maxcol and maxrow abbreviations
call interpreter%init(scratch)
call interpreter%run_text('set key columns 2; set key maxcol 3 maxrow 4', iostat, iomsg)
test_passed(151) = iostat == 0_I4P .and. interpreter%figure%panels(1)%key_columns == 2_I4P .and. &
                  interpreter%figure%panels(1)%key_maxcols == 3_I4P .and. interpreter%figure%panels(1)%key_maxrows == 4_I4P
call interpreter%run_text('set key default', iostat, iomsg)
test_passed(151) = test_passed(151) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%key_columns == 0_I4P
call interpreter%run_text('set term svg; set output "foresight_script_test_keycols.svg"; set key columns 2; '// &
                          'plot x t "a", 2*x t "b", 3*x t "c"', iostat, iomsg)
block
   character(len=:), allocatable :: svg !< Output.
   integer(I4P)                  :: ya  !< Position of a.
   integer(I4P)                  :: yc  !< Position of c.

   svg = text_of_file('foresight_script_test_keycols.svg')
   ! a and c side by side in the first row: the same baseline
   ya = index(svg, '>a</text>')
   yc = index(svg, '>c</text>')
   test_passed(151) = test_passed(151) .and. iostat == 0_I4P .and. ya > 0 .and. yc > 0
   if (test_passed(151)) test_passed(151) = baseline(svg, ya) == baseline(svg, yc) .and. &
                                          baseline(svg, index(svg, '>b</text>')) > baseline(svg, ya)
endblock
open(newunit=unit, file='foresight_script_test_keycols.svg')
close(unit, status='delete')

! set multiplot layout R,C columnsfirst|rowsfirst upwards|downwards, title ... font: the fill order of the cells
call interpreter%init(scratch)
call interpreter%run_text('set term svg; set output "foresight_script_test_mpfill.svg"; '// &
                          'set multiplot layout 2,2 columnsfirst upwards title "M" font ",14"; '// &
                          'set title "P1"; plot x; set title "P2"; plot x; unset multiplot', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
block
   character(len=:), allocatable :: svg !< Output.
   real(R8P)                     :: y1  !< Baseline of P1.
   real(R8P)                     :: y2  !< Baseline of P2.

   svg = text_of_file('foresight_script_test_mpfill.svg')
   test_passed(152) = iostat == 0_I4P .and. index(svg, '>P1</text>') > 0 .and. index(svg, '>P2</text>') > 0
   if (test_passed(152)) then
      ! columns first, upwards: P1 bottom left, P2 above it (top left)
      y1 = baseline(svg, index(svg, '>P1</text>'))
      y2 = baseline(svg, index(svg, '>P2</text>'))
      test_passed(152) = y2 < y1
   endif
endblock
call interpreter%run_text('set multiplot layout 2,2 scale 1,1', iostat, iomsg)
test_passed(152) = test_passed(152) .and. iostat /= 0_I4P .and. index(iomsg, 'unsupported option "scale"') > 0
open(newunit=unit, file='foresight_script_test_mpfill.svg')
close(unit, status='delete')

call interpreter%run_text('set key autotitle column; set key columns 3', iostat, iomsg)
test_passed(152) = test_passed(152) .and. iostat == 0_I4P .and. interpreter%autotitle == 'columnhead' .and. &
                   interpreter%figure%panels(1)%key_columns == 3_I4P
! layout options as gnuplot 6.0: fill style abbreviations and border lt N, set border back and an expression mask,
! set rmargin screen F (without at)
call interpreter%init(scratch)
call interpreter%run_text('$B << EOD'//new_line('a')//'1 1'//new_line('a')//'2 2'//new_line('a')//'EOD'//new_line('a')// &
                          'set style fill tr s 0.2 bo lt 8; plot $B with boxes', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(153) = iostat == 0_I4P
if (test_passed(153)) test_passed(153) = interpreter%figure%panels(1)%series(1)%style%border_color == default_color(8_I4P) .and. &
                                       abs(interpreter%figure%panels(1)%series(1)%style%density - 0.2_R8P) < 1.0e-12_R8P
call interpreter%run_text('set style fill solid border lt -1; plot $B with boxes', iostat, iomsg)
test_passed(153) = test_passed(153) .and. iostat == 0_I4P
if (test_passed(153)) test_passed(153) = interpreter%figure%panels(1)%series(1)%style%border_color == 'black'
call interpreter%run_text('bb = 1 + 2; set border bb back', iostat, iomsg)
test_passed(153) = test_passed(153) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%border == 3_I4P
call interpreter%run_text('set rmargin screen 0.7', iostat, iomsg)
test_passed(153) = test_passed(153) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%margin_screen(2) .and. &
                  interpreter%figure%panels(1)%margin_user(2) == 0.7_R8P
call interpreter%run_text('set border sideways', iostat, iomsg)
test_passed(153) = test_passed(153) .and. iostat /= 0_I4P .and. index(iomsg, 'unsupported option "sideways"') > 0

call interpreter%run_text('set style fill pattern 2 bo 3; plot $B with boxes', iostat, iomsg)
test_passed(153) = test_passed(153) .and. iostat == 0_I4P
if (test_passed(153)) test_passed(153) = interpreter%figure%panels(1)%series(1)%style%border_color == default_color(3_I4P)
! set ytics START, INCR, END written with blanks; set paxis with an expression; set ttics format EXPR font F
call interpreter%init(scratch)
call interpreter%run_text('ymax = 0.5; set ytics 0, ymax / 10.0, ymax', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(154) = iostat == 0_I4P .and. interpreter%figure%panels(1)%yaxis%tics%step == '0.05'
call interpreter%run_text('set for [i=1:2] paxis i range [0:10]', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(154) = test_passed(154) .and. iostat == 0_I4P
call interpreter%run_text('set polar; set ttics 0,30 format "%g"."x" font ":Italic"', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(154) = test_passed(154) .and. iostat == 0_I4P
call interpreter%run_text('set ttics 0,30 format "%g" sideways', iostat, iomsg)
test_passed(154) = test_passed(154) .and. iostat /= 0_I4P

call interpreter%run_text('ymax = 0.23911711601960603; set ytics 0, ymax / 10.0, ymax', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(154) = test_passed(154) .and. iostat == 0_I4P .and. &
                   interpreter%figure%panels(1)%yaxis%tics%step == '0.023911711602'
! sum [i=a:b] EXPRESSION (integers stay integers, empty is 0, nested, in a user function and a plotted function),
! GPVAL_LINENO, show and test run as no-ops
call interpreter%init(scratch)
call interpreter%run_text('a = sum [i=1:3] 1234567891; b = sum [i=1:0] i; c = sum [i=1:3] 0.5*i; '// &
                          'd = sum [i=1:2] sum [j=1:3] i*j; f(x) = sum [k=1:3] k*x; e = f(2)', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(155) = iostat == 0_I4P
if (test_passed(155)) then
   block
      real(R8P) :: v(5) !< a to e.

      call interpreter%symbols%constant('a', v(1), iostat, iomsg)
      call interpreter%symbols%constant('b', v(2), iostat, iomsg)
      call interpreter%symbols%constant('c', v(3), iostat, iomsg)
      call interpreter%symbols%constant('d', v(4), iostat, iomsg)
      call interpreter%symbols%constant('e', v(5), iostat, iomsg)
      test_passed(155) = all(v == [3703703673.0_R8P, 0.0_R8P, 3.0_R8P, 18.0_R8P, 12.0_R8P])
   endblock
endif
call interpreter%run_text('set samples 3; plot [0:2] sum [k=1:2] k*x', iostat, iomsg)
test_passed(155) = test_passed(155) .and. iostat == 0_I4P
if (test_passed(155)) test_passed(155) = all(interpreter%figure%panels(1)%series(1)%y == [0.0_R8P, 3.0_R8P, 6.0_R8P])
call interpreter%run_text('show xrange; test'//new_line('a')//'n = GPVAL_LINENO', iostat, iomsg)
test_passed(155) = test_passed(155) .and. iostat == 0_I4P
if (test_passed(155)) then
   block
      real(R8P) :: n !< Line.

      call interpreter%symbols%constant('n', n, iostat, iomsg)
      test_passed(155) = iostat == 0_I4P .and. n == 2.0_R8P
   endblock
endif
call interpreter%run_text('print sum [i=1:3 i', iostat, iomsg)
test_passed(155) = test_passed(155) .and. iostat /= 0_I4P

! using ... :xticlabel(N): any gnuplot abbreviation of xticlabels (xtic$labels), and its x2, y, y2 forms
call interpreter%init(scratch)
call interpreter%run_text('$L << EOD'//new_line('a')//'a 1'//new_line('a')//'b 2'//new_line('a')//'EOD'//new_line('a')// &
                          'plot $L using 2:xticlabel(1), $L using 2:xticl(1), $L using 2:yticlabel(1)', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(156) = iostat == 0_I4P
if (test_passed(156)) test_passed(156) = allocated(interpreter%figure%panels(1)%series(1)%xlabels) .and. &
                                       allocated(interpreter%figure%panels(1)%series(2)%xlabels)
if (test_passed(156)) test_passed(156) = interpreter%figure%panels(1)%series(1)%xlabels(2) == 'b' .and. &
                                       interpreter%figure%panels(1)%series(2)%xlabels(1) == 'a'
call interpreter%run_text('plot $L using 2:xticlabelsx(1)', iostat, iomsg)
test_passed(156) = test_passed(156) .and. iostat /= 0_I4P

! custom dash types as gnuplot 6.0 (dt "-", dt (50,6,2,6), a string variable; half the line width per unit as its svg
! terminal) and the special colors bgnd, nodraw, black (lc and lt)
call interpreter%init(scratch)
call interpreter%run_text('set term svg; set output "foresight_script_test_dash.svg"; new = "..- "; '// &
                          'plot x dt "-" lw 2, 2*x dt (50,6,2,6), 3*x dt new, 4*x lc bgnd, 5*x lt nodraw, 6*x lt -1', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(157) = iostat == 0_I4P
if (test_passed(157)) then
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_dash.svg')
      test_passed(157) = index(svg, 'stroke-dasharray="10,10"') > 0 .and. &
                        index(svg, 'stroke-dasharray="25,3,1,3"') > 0 .and. &
                        index(svg, 'stroke-dasharray="1,2.5,1,2.5,5,10"') > 0 .and. &
                        interpreter%figure%panels(1)%series(4)%style%color == '#ffffff' .and. &
                        interpreter%figure%panels(1)%series(5)%style%color == 'none' .and. &
                        interpreter%figure%panels(1)%series(6)%style%color == '#000000'
   endblock
endif
call interpreter%run_text('plot x dt "-x"', iostat, iomsg)
test_passed(157) = test_passed(157) .and. iostat /= 0_I4P .and. index(iomsg, 'a dash pattern') > 0
open(newunit=unit, file='foresight_script_test_dash.svg')
close(unit, status='delete')

! set palette model HSV (and gnuplot's `mode HSV`): the components are hue, saturation, value, as gnuplot
call interpreter%init(scratch)
call interpreter%run_text('set palette mode HSV; set palette defined (0 0 1 1, 1 1 1 1)', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(158) = iostat == 0_I4P .and. interpreter%figure%panels(1)%palette%hsv
if (test_passed(158)) test_passed(158) = all(interpreter%figure%panels(1)%palette%rgb(0.0_R8P) == [255, 0, 0]) .and. &
                                       all(interpreter%figure%panels(1)%palette%rgb(1.0_R8P/3.0_R8P) == [0, 255, 0]) .and. &
                                       all(interpreter%figure%panels(1)%palette%rgb(0.5_R8P) == [0, 255, 255])
call interpreter%run_text('set palette model RGB', iostat, iomsg)
test_passed(158) = test_passed(158) .and. iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%palette%hsv
call interpreter%run_text('set palette model XYZ', iostat, iomsg)
test_passed(158) = test_passed(158) .and. iostat /= 0_I4P .and. index(iomsg, 'RGB, HSV and CMY are supported') > 0


! settings that leave gnuplot's 2D svg unchanged (isosamples, mouse, macros, pointintervalbox, zrange, minussign with
! the default encoding), refresh, unset samples, set samples EXPR, and the integer overflow modes as gnuplot 6.0
call interpreter%init(scratch)
call interpreter%run_text('set isosamples 3.9, 4; set mouse mouseformat 6; unset mouse; set macros; unset macros; '// &
                          'set pointintervalbox 1.5; set zrange [-1:2]; set minussign; set micro; unset minus; '// &
                          'a = 3; set samples (a*4.5), 2*a', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(159) = iostat == 0_I4P .and. interpreter%samples == 13_I4P
call interpreter%run_text('unset samples; set xrange [0:1]; plot x; set xrange [0:2]; refresh', iostat, iomsg)
test_passed(159) = test_passed(159) .and. iostat == 0_I4P .and. interpreter%samples == 100_I4P
if (test_passed(159)) test_passed(159) = maxval(interpreter%figure%panels(1)%series(1)%x) == 2.0_R8P
call interpreter%run_text('set encoding utf8', iostat, iomsg)
test_passed(159) = test_passed(159) .and. iostat /= 0_I4P .and. index(iomsg, 'unset them first') > 0
call interpreter%run_text('unset micro; set encoding utf8; set minussign', iostat, iomsg)
test_passed(159) = test_passed(159) .and. iostat /= 0_I4P .and. index(iomsg, 'not supported with set encoding utf8') > 0
call interpreter%run_text('A = 2**62; unset overflow; b = A + A; c = -3*A; d = -A - A - A; set overflow NaN; e = A + A; '// &
                          'set overflow; f = A + A; g = int(1e19); h = floor(2.**52 * 1.5)', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(159) = test_passed(159) .and. iostat == 0_I4P
if (test_passed(159)) then
   block
      real(R8P) :: v(6) !< b, c, d, e, f, g.
      real(R8P) :: h    !< floor of 1.5 * 2**52.

      call interpreter%symbols%constant('b', v(1), iostat, iomsg)
      call interpreter%symbols%constant('c', v(2), iostat, iomsg)
      call interpreter%symbols%constant('d', v(3), iostat, iomsg)
      call interpreter%symbols%constant('e', v(4), iostat, iomsg)
      call interpreter%symbols%constant('f', v(5), iostat, iomsg)
      call interpreter%symbols%constant('g', v(6), iostat, iomsg)
      call interpreter%symbols%constant('h', h, iostat, iomsg)
      test_passed(159) = v(1) == -9223372036854775808.0_R8P .and. v(2) == -3.0_R8P * 2.0_R8P**62 .and. &
                        v(3) == 2.0_R8P**62 .and. ieee_is_nan(v(4)) .and. v(5) == 2.0_R8P**63 .and. &
                        ieee_is_nan(v(6)) .and. ieee_is_nan(h)
   endblock
endif
call interpreter%run_text('set overflow undefined; i = 2**64', iostat, iomsg)
test_passed(159) = test_passed(159) .and. iostat /= 0_I4P
call interpreter%run_text('set overflow wrap', iostat, iomsg)
test_passed(159) = test_passed(159) .and. iostat /= 0_I4P .and. index(iomsg, 'float, undefined or NaN') > 0
call interpreter%run_text('reset session; j = 2**62 + 2**62', iostat, iomsg)
test_passed(159) = test_passed(159) .and. iostat == 0_I4P
if (test_passed(159)) then
   block
      real(R8P) :: j !< Overflowed sum.

      call interpreter%symbols%constant('j', j, iostat, iomsg)
      test_passed(159) = j == 2.0_R8P**63
   endblock
endif
! set mttics: minor ticks on the polar border, unlabelled
call interpreter%init(scratch)
call interpreter%run_text('set polar; set ttics 0,90; set mttics 3; set border polar; set rrange [0:1]; plot 1', &
                          iostat, iomsg)
test_passed(159) = test_passed(159) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%ttics%minor == 3_I4P
call interpreter%run_text('unset mttics', iostat, iomsg)
test_passed(159) = test_passed(159) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%ttics%minor == 0_I4P


! assignments inside expressions and gnuplot's serial evaluation (a, b), as gnuplot 6.0: run when evaluated, on each
! data row in using, the variables of a function body read at run time wherever compiled; `name=value 'file'`, an
! assignment the item follows without a comma
call interpreter%init(scratch)
call interpreter%run_text('a = (b = 2, b + 1); c = d = 4; f(x) = (n = x * 2, n + 1); e = f(3); g = n'// &
                          new_line('a')//'$D << EOD'//new_line('a')//'1 10'//new_line('a')//'2 20'//new_line('a')//'3 30'// &
                          new_line('a')//'EOD'//new_line('a')// &
                          'plot s = 0, $D using 1:(s = s + $2, s), t=100 $D using 1:(t = t + 1)', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(160) = iostat == 0_I4P
if (test_passed(160)) then
   block
      real(R8P) :: v(8) !< a, b, c, d, e, g, s, t.

      call interpreter%symbols%constant('a', v(1), iostat, iomsg)
      call interpreter%symbols%constant('b', v(2), iostat, iomsg)
      call interpreter%symbols%constant('c', v(3), iostat, iomsg)
      call interpreter%symbols%constant('d', v(4), iostat, iomsg)
      call interpreter%symbols%constant('e', v(5), iostat, iomsg)
      call interpreter%symbols%constant('g', v(6), iostat, iomsg)
      call interpreter%symbols%constant('s', v(7), iostat, iomsg)
      call interpreter%symbols%constant('t', v(8), iostat, iomsg)
      test_passed(160) = all(v == [3.0_R8P, 2.0_R8P, 4.0_R8P, 4.0_R8P, 7.0_R8P, 6.0_R8P, 60.0_R8P, 103.0_R8P])
   endblock
endif
if (test_passed(160)) test_passed(160) = all(interpreter%figure%panels(1)%series(1)%y == [10.0_R8P, 30.0_R8P, 60.0_R8P]) &
                                       .and. all(interpreter%figure%panels(1)%series(2)%y == [101.0_R8P, 102.0_R8P, 103.0_R8P])
call interpreter%run_text('h(x) = (unknown_k + x, unknown_k = 1); print h(1)', iostat, iomsg)
test_passed(160) = test_passed(160) .and. iostat /= 0_I4P .and. index(iomsg, 'undefined variable') > 0
call interpreter%run_text('print (1 = 2)', iostat, iomsg)
test_passed(160) = test_passed(160) .and. iostat /= 0_I4P


! gnuplot 6.0 split() and join(): words on white space, pieces on a separator (empty ones kept, none after a last one)
call interpreter%init(scratch)
call interpreter%run_text('A = split("a  b c"); n = |split("x y")|; s = join(split("a b"), "-"); '// &
                          'B = split("a,b,,c,", ","); m = |B|; i = index(split("p q r"), "q"); '// &
                          'array C[3]; C[1] = "p"; C[2] = 2; t = join(C, "+")', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(161) = iostat == 0_I4P
if (test_passed(161)) then
   block
      character(len=:), allocatable :: text !< A string.
      logical                       :: found !< Found.
      real(R8P)                     :: v(3)  !< n, m, i.

      call interpreter%symbols%constant('n', v(1), iostat, iomsg)
      call interpreter%symbols%constant('m', v(2), iostat, iomsg)
      call interpreter%symbols%constant('i', v(3), iostat, iomsg)
      test_passed(161) = all(v == [2.0_R8P, 4.0_R8P, 2.0_R8P]) .and. interpreter%symbols%array_size('A') == 3_I4P
      call interpreter%symbols%string_of('s', text, found)
      test_passed(161) = test_passed(161) .and. found .and. text == 'a-b'
      call interpreter%symbols%string_of('t', text, found)
      test_passed(161) = test_passed(161) .and. found .and. text == 'p++'
      call interpreter%symbols%text_of('B[3]', text, found, iostat, iomsg)
      test_passed(161) = test_passed(161) .and. iostat == 0_I4P .and. found .and. text == ''
   endblock
endif
call interpreter%run_text('x = split("a b") + 1', iostat, iomsg)
test_passed(161) = test_passed(161) .and. iostat /= 0_I4P .and. index(iomsg, 'split() is an array') > 0
call interpreter%run_text('y = join(3, "-")', iostat, iomsg)
test_passed(161) = test_passed(161) .and. iostat /= 0_I4P .and. index(iomsg, 'join: expecting') > 0


! call arguments as gnuplot 6.0's prepare_call: a number as written (its value in ARGV), a word naming no variable as
! it is, an integer value as an integer, a real one as %g; GPVAL_LINENO the last line read (a block's closing line)
open(newunit=unit, file='foresight_script_test_call.gp')
write(unit, '(A)') 'r1 = ARG1; r3 = ARG3; r4 = ARG4; r6 = ARG6; r7 = ARG7; v1 = ARGV[1]; v4 = ARGV[4]; n = ARGC'
close(unit)
call interpreter%init(scratch)
call interpreter%run_text('BAZ = 5.67; S = "a b"; call "foresight_script_test_call.gp" 1.23e4 "s" FOO BAZ "x" S '// &
                          '(1+3+4) pi'//new_line('a')//'if (1) {'//new_line('a')//'k = 1'//new_line('a')// &
                          'm = GPVAL_LINENO'//new_line('a')//'}', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(162) = iostat == 0_I4P
if (test_passed(162)) then
   block
      character(len=:), allocatable :: text(:) !< r1, r3, r4, r6, r7.
      character(len=:), allocatable :: t       !< One.
      logical                       :: found   !< Found.
      real(R8P)                     :: v(4)    !< v1, v4, n, m.
      integer(I4P)                  :: j       !< Counter.
      character(len=2), parameter   :: NAMES(5) = ['r1', 'r3', 'r4', 'r6', 'r7'] !< Texts.
      character(len=6), parameter   :: EXPECTED(5) = ['1.23e4', 'FOO   ', '5.67  ', 'a b   ', '8     '] !< Values.

      allocate(character(len=6) :: text(5))
      do j = 1_I4P, 5_I4P
         call interpreter%symbols%string_of(NAMES(j), t, found)
         test_passed(162) = test_passed(162) .and. found
         if (found) test_passed(162) = test_passed(162) .and. t == trim(EXPECTED(j))
      enddo
      call interpreter%symbols%constant('v1', v(1), iostat, iomsg)
      call interpreter%symbols%constant('v4', v(2), iostat, iomsg)
      call interpreter%symbols%constant('n', v(3), iostat, iomsg)
      call interpreter%symbols%constant('m', v(4), iostat, iomsg)
      test_passed(162) = test_passed(162) .and. all(v == [12300.0_R8P, 5.67_R8P, 8.0_R8P, 5.0_R8P])
   endblock
endif
open(newunit=unit, file='foresight_script_test_call.gp')
close(unit, status='delete')


! skip N (plot, stats), tic list labels as string expressions, unterminated strings closed by the line end, escapes
! kept through command substitution, as gnuplot 6.0
call interpreter%init(scratch)
call interpreter%run_text('$D << EOD'//new_line('a')//'# h'//new_line('a')//'1 10'//new_line('a')//'2 20'// &
                          new_line('a')//'3 30'//new_line('a')//'EOD'//new_line('a')// &
                          'plot $D skip 2 using 1:2; stats $D skip 3 using 2 nooutput; '// &
                          'lab = "L"; set xtics (sprintf("%dσ", 2) 2, lab 3, "q" 4 1, 5); '// &
                          't = "x\`y\`"; set title "open', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(163) = iostat == 0_I4P
if (test_passed(163)) test_passed(163) = all(interpreter%figure%panels(1)%series(1)%y == [20.0_R8P, 30.0_R8P])
if (test_passed(163)) then
   block
      real(R8P)                     :: n     !< STATS_records.
      character(len=:), allocatable :: text  !< t.
      logical                       :: found !< Found.

      call interpreter%symbols%constant('STATS_records', n, iostat, iomsg)
      test_passed(163) = iostat == 0_I4P .and. n == 1.0_R8P
      call interpreter%symbols%string_of('t', text, found)
      test_passed(163) = test_passed(163) .and. found .and. text == 'x`y`'
   endblock
endif
if (test_passed(163)) then
   associate(items => interpreter%figure%panels(1)%xaxis%tics%list)
      test_passed(163) = size(items) == 4
      if (test_passed(163)) test_passed(163) = items(1)%label == '2σ' .and. items(1)%value == 2.0_R8P .and. &
                                             items(2)%label == 'L' .and. items(3)%label == 'q' .and. &
                                             .not. items(3)%major .and. .not. items(4)%labelled
   endassociate
endif
if (test_passed(163)) test_passed(163) = interpreter%figure%panels(1)%title == 'open'


! complex numbers as gnuplot 6.0: {re, im}, I, arithmetic and powers by its formulas, abs/arg/real/imag/conj, sqrt and
! log of negative reals; printed as {re, im}; a plotted value with an imaginary part beyond 1e-8 is undefined
call interpreter%init(scratch)
call interpreter%run_text('a = abs({3,4}); b = 180/pi*arg({0,1}); c = real({1,2}*{3,4}); d = imag(1/{0,1}); '// &
                          'e = imag(sqrt(-4)); f = imag(log(-1)); g = imag((-8)**(1./3)); h = real(I*I); '// &
                          'k = ({1,2} == {1,2}) + ({1,2} < {2,0}); m = imag(conj(7*I)); '// &
                          'set samples 3; plot [0:2] abs({1,1}*x), {1,1}*x, sqrt(x-1); set ytics tc lt 2', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(164) = iostat == 0_I4P
if (test_passed(164)) then
   block
      real(R8P)                   :: v(10) !< a to m.
      integer(I4P)                :: j     !< Counter.
      character(len=1), parameter :: NAMES(10) = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'k', 'm'] !< Variables.

      do j = 1_I4P, 10_I4P
         call interpreter%symbols%constant(NAMES(j), v(j), iostat, iomsg)
         test_passed(164) = test_passed(164) .and. iostat == 0_I4P
      enddo
      test_passed(164) = test_passed(164) .and. v(1) == 5.0_R8P .and. abs(v(2) - 90.0_R8P) < 1.0e-12_R8P .and. &
                        v(3) == -5.0_R8P .and. v(4) == -1.0_R8P .and. v(5) == 2.0_R8P .and. &
                        abs(v(6) - acos(-1.0_R8P)) < 1.0e-15_R8P .and. abs(v(7) - sqrt(3.0_R8P)) < 1.0e-14_R8P .and. &
                        v(8) == -1.0_R8P .and. v(9) == 2.0_R8P .and. v(10) == -7.0_R8P
   endblock
endif
if (test_passed(164)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(164) = abs(series(1)%y(3) - 2.0_R8P * sqrt(2.0_R8P)) < 1.0e-14_R8P .and. series(2)%y(1) == 0.0_R8P &
                        .and. ieee_is_nan(series(2)%y(2)) .and. ieee_is_nan(series(3)%y(1)) .and. series(3)%y(3) == 1.0_R8P
   endassociate
   test_passed(164) = test_passed(164) .and. interpreter%figure%panels(1)%yaxis%tics%color == default_color(2_I4P)
endif
call interpreter%run_text('x = {1,2} % 2', iostat, iomsg)
test_passed(164) = test_passed(164) .and. iostat /= 0_I4P
call interpreter%run_text('y = {1, a}', iostat, iomsg)
test_passed(164) = test_passed(164) .and. iostat /= 0_I4P .and. index(iomsg, 'invalid complex constant') > 0


! set linetype N lc "#AARRGGBB": gnuplot's transparent colors kept as #rrggbbaa (alpha 255 - AA)
call interpreter%init(scratch)
call interpreter%run_text('set linetype 9 lc "#80bb33bb"; plot x lt 9', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(165) = iostat == 0_I4P
if (test_passed(165)) test_passed(165) = trim(interpreter%figure%panels(1)%linecolors(9)) == '#bb33bb7f' .and. &
                                       interpreter%figure%panels(1)%series(1)%style%color == '#bb33bb7f'
call interpreter%run_text('set linetype 3 lc palette', iostat, iomsg)
test_passed(165) = test_passed(165) .and. iostat /= 0_I4P .and. index(iomsg, 'a fixed color is expected') > 0


! set multiplot layout ... margins L,R,B,T spacing X,Y (gnuplot's plot areas at screen fractions, char units too) and
! set xrange|yrange reverse (an axis with an autoscaled end reversed, an explicit range left as it is)
call interpreter%init(scratch)
call interpreter%run_text('set multiplot layout 2,2 margins 0.1, 0.9, 0.1, 0.9 spacing 0.1, 0.2', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(166) = iostat == 0_I4P
if (test_passed(166)) test_passed(166) = all(interpreter%figure%layout_margins == [0.1_R8P, 0.9_R8P, 0.1_R8P, 0.9_R8P]) &
                                       .and. all(interpreter%figure%layout_spacing == [0.1_R8P, 0.2_R8P])
call interpreter%run_text('unset multiplot; set multiplot layout 1,2 margins char 3, 3, 2, 4', iostat, iomsg)
test_passed(166) = test_passed(166) .and. iostat == 0_I4P
if (test_passed(166)) test_passed(166) = all(interpreter%figure%layout_chars) .and. &
                                       all(interpreter%figure%layout_spacing == 0.05_R8P)
call interpreter%run_text('unset multiplot; set multiplot layout 1,2 margins 0.1, -1, 0.1, 0.9 spacing 0.1', iostat, &
                          iomsg)
test_passed(166) = test_passed(166) .and. iostat /= 0_I4P .and. index(iomsg, 'positive margin and spacing') > 0
call interpreter%init(scratch)
call interpreter%run_text('set yrange reverse; plot [0:1] x', iostat, iomsg)
test_passed(166) = test_passed(166) .and. iostat == 0_I4P
if (test_passed(166)) then
   call interpreter%figure%panels(1)%yaxis%setup(0.0_R8P, 1.0_R8P, .true., 100.0_R8P)
   test_passed(166) = interpreter%figure%panels(1)%yaxis%lo > interpreter%figure%panels(1)%yaxis%hi
endif
call interpreter%run_text('set yrange [0:1] reverse', iostat, iomsg)
test_passed(166) = test_passed(166) .and. iostat == 0_I4P
if (test_passed(166)) then
   call interpreter%figure%panels(1)%yaxis%setup(0.0_R8P, 1.0_R8P, .true., 100.0_R8P)
   test_passed(166) = interpreter%figure%panels(1)%yaxis%lo < interpreter%figure%panels(1)%yaxis%hi
endif
call interpreter%run_text('set rrange reverse', iostat, iomsg)
test_passed(166) = test_passed(166) .and. iostat /= 0_I4P .and. index(iomsg, 'reverse applies to') > 0


! set palette functions R, G, B: expressions of gray (clipped to 0..1), in the palette's model (RGB, HSV)
call interpreter%init(scratch)
call interpreter%run_text('set palette functions gray, gray**2, 1 - gray', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(167) = iostat == 0_I4P
if (test_passed(167)) test_passed(167) = all(interpreter%figure%panels(1)%palette%rgb(0.5_R8P) == [128, 64, 128]) .and. &
                                       all(interpreter%figure%panels(1)%palette%rgb(0.3_R8P) == [77, 23, 179])
call interpreter%run_text('set palette model HSV func 0, 0, 2*gray', iostat, iomsg)
test_passed(167) = test_passed(167) .and. iostat == 0_I4P
if (test_passed(167)) test_passed(167) = interpreter%figure%panels(1)%palette%hsv .and. &
                                       all(interpreter%figure%panels(1)%palette%rgb(0.25_R8P) == [128, 128, 128]) .and. &
                                       all(interpreter%figure%panels(1)%palette%rgb(0.75_R8P) == [255, 255, 255])
call interpreter%run_text('set palette functions gray, gray', iostat, iomsg)
test_passed(167) = test_passed(167) .and. iostat /= 0_I4P .and. index(iomsg, 'functions R, G, B expected') > 0


! fc|fillcolor COLOR in a plot item (the fill's own color, the line keeps lc) and `rgb NAME`, a string variable
call interpreter%init(scratch)
call interpreter%run_text('Shade = "#80E0A080"; plot x with filledcurves y=0 fc rgb Shade lc "red", '// &
                          '2*x with boxes fs solid fillcolor "blue" lc rgb Shade', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(168) = iostat == 0_I4P
if (test_passed(168)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(168) = series(1)%style%fill_color() == '#e0a0807f' .and. series(1)%style%color == '#ff0000' .and. &
                        series(2)%style%fill_color() == '#0000ff' .and. series(2)%style%color == '#e0a0807f'
   endassociate
endif
call interpreter%run_text('plot x with filledcurves fc palette', iostat, iomsg)
test_passed(168) = test_passed(168) .and. iostat /= 0_I4P .and. index(iomsg, 'lc palette z needs using x:y:z') > 0


! lc variable on candlesticks, boxxyerror, histograms (Y:COLOR), filledcurves and polygons (a color per run, its
! first point's); labels of a pseudo-column (using 1:2:0) are its integers, as gnuplot's label hack
call interpreter%init(scratch)
call interpreter%run_text('$D << EOD'//new_line('a')//'1 2 1 3 2'//new_line('a')//'2 3 2 4 3'//new_line('a')// &
                          new_line('a')//'3 1 0 2 1'//new_line('a')//'4 2 1 3 2'//new_line('a')//'EOD'// &
                          new_line('a')//'plot $D using 1:2:3:4:5:1 with candlesticks lc variable, '// &
                          '$D using 2:1 with histograms lc variable, '// &
                          '$D using 1:2:(column(-1)+3) with filledcurves lc variable, '// &
                          '$D using 1:2:(column(-1)+5) with polygons lc variable, '// &
                          '$D using 1:2:0 with labels', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(169) = iostat == 0_I4P
if (test_passed(169)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(169) = size(series) == 5
      ! the blank line between the blocks is a gap point, the third
      if (test_passed(169)) test_passed(169) = series(1)%colors(4) == default_color(3_I4P) .and. &
                                             series(2)%colors(5) == default_color(4_I4P) .and. &
                                             series(3)%colors(1) == default_color(3_I4P) .and. &
                                             series(3)%colors(4) == default_color(4_I4P) .and. &
                                             series(4)%colors(4) == default_color(6_I4P) .and. &
                                             trim(series(5)%texts(1)) == '0' .and. trim(series(5)%texts(5)) == '3'
   endassociate
endif


! set datafile columnheaders (the first row of each dataset a header, plot and stats; with other options after it) and
! `lt rgb COLOR`, a line color given after lt (set style line 1 lt rgb "red")
call interpreter%init(scratch)
call interpreter%run_text('$D << EOD'//new_line('a')//'h1 h2'//new_line('a')//'1 2'//new_line('a')//'3 4'// &
                          new_line('a')//'EOD'//new_line('a')//'set datafile columnheaders separator whitespace; '// &
                          'plot $D using 1:2; stats $D using 1 nooutput; set style line 1 lt rgb "red" lw 3; '// &
                          'plot $D using 1:2 ls 1', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(170) = iostat == 0_I4P .and. interpreter%column_headers
if (test_passed(170)) then
   block
      real(R8P) :: n !< STATS_records.

      call interpreter%symbols%constant('STATS_records', n, iostat, iomsg)
      test_passed(170) = n == 2.0_R8P .and. size(interpreter%figure%panels(1)%series(1)%x) == 2 .and. &
                        interpreter%figure%panels(1)%series(1)%style%color == '#ff0000'
   endblock
endif
call interpreter%run_text('unset datafile columnheaders', iostat, iomsg)
test_passed(170) = test_passed(170) .and. iostat == 0_I4P .and. .not. interpreter%column_headers


! with fillsteps: the area under steps from y = 0, a run one polygon (its fill), the steps themselves without a fill
call interpreter%init(scratch)
call interpreter%run_text('set term svg; set output "foresight_script_test_fillsteps.svg"; set style fill solid'// &
                          new_line('a')//'$D << EOD'//new_line('a')//'1 2'//new_line('a')//'2 3'//new_line('a')// &
                          '3 1'//new_line('a')//'EOD'//new_line('a')//'plot $D with fillst lc rgb "#123456"', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(171) = iostat == 0_I4P
if (test_passed(171)) then
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_fillsteps.svg')
      test_passed(171) = interpreter%figure%panels(1)%series(1)%style%with == WITH_FILLSTEPS .and. &
                        index(svg, 'fill="#123456"') > 0 .and. &
                        index(svg(index(svg, 'fill="#123456"') + 1:), 'fill="#123456"') > 0
   endblock
endif
open(newunit=unit, file='foresight_script_test_fillsteps.svg')
close(unit, status='delete')


! set grid r [polar STEP] (the polar grid at the r ticks, the rings alone without polar; a STEP beyond a full turn of
! radians is in degrees, as gnuplot), set grid lt black, set ttics [add] ("label" angle, ...)
call interpreter%init(scratch)
call interpreter%run_text('set polar; set grid r polar 60; set grid lt black lw .3; set ttics 0,30; '// &
                          'set ttics add ("pi" 180, "pi/2" 90)', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(172) = iostat == 0_I4P
if (test_passed(172)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(172) = abs(panel%grid_polar - 60.0_R8P) < 1.0e-12_R8P .and. panel%grid_lc == 'black' .and. &
                        allocated(panel%ttics%list)
      if (test_passed(172)) test_passed(172) = size(panel%ttics%list) == 2 .and. panel%ttics%list(1)%label == 'pi'
   endassociate
endif
call interpreter%run_text('set grid r', iostat, iomsg)
test_passed(172) = test_passed(172) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%grid_polar == 360.0_R8P
call interpreter%run_text('set grid nor', iostat, iomsg)
test_passed(172) = test_passed(172) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%grid_polar == 0.0_R8P


! arrow `fill` (gnuplot's fil$led) and `ls N`, coordinate system abbreviations (char, sc, gr), a circle's `radius`, a
! number ending with its point before a keyword (`size 2.,4. angle 20.`)
call interpreter%init(scratch)
call interpreter%run_text('set style line 2 lc "red" lw 3; set arrow 1 from 0,0 to 1,1 fill ls 2; '// &
                          'set object 2 rect at 0,0 size char 3, char 1; '// &
                          'set object 3 ellipse center 1.5,1.0 size 2.,4. angle 20.; '// &
                          'set object 4 circle at sc 0.5, 0.5 radius 0.25', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(173) = iostat == 0_I4P
if (test_passed(173)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(173) = panel%arrows(1)%fill == 'filled' .and. panel%arrows(1)%color == '#ff0000' .and. &
                        panel%arrows(1)%lw == 3.0_R8P .and. trim(panel%objects(1)%size%sx) == 'character' .and. &
                        panel%objects(2)%size%y == 4.0_R8P .and. panel%objects(2)%angle == 20.0_R8P .and. &
                        trim(panel%objects(3)%points(1)%sx) == 'screen' .and. panel%objects(3)%size%x == 0.25_R8P
   endassociate
endif


! set style textbox and `with labels boxed [bs N]`: gnuplot's svg textbox, the text on the background through a filter
! (opaque or bordered styles); color names matched by prefix (grey75 is grey); `notitle columnhead`
call interpreter%init(scratch)
call interpreter%run_text('set term svg; set output "foresight_script_test_textbox.svg"; '// &
                          'set style textbox 2 opaque margins 6,1.5 fc "grey75" border lc black; '// &
                          'set style textbox 3 transparent noborder'//new_line('a')//'$D << EOD'//new_line('a')// &
                          'h v'//new_line('a')//'1 5'//new_line('a')//'2 6'//new_line('a')//'EOD'//new_line('a')// &
                          'plot $D using 1:2:2 with labels boxed bs 2 notitle column, $D using 1:2:2 with labels '// &
                          'boxed bs 3 notitle columnhead, $D using 1:2 lc "grey75" notitle', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(174) = iostat == 0_I4P
if (test_passed(174)) then
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_textbox.svg')
      associate(series => interpreter%figure%panels(1)%series)
         test_passed(174) = series(1)%text_boxed .and. .not. series(2)%text_boxed .and. size(series(1)%x) == 2 .and. &
                           series(3)%style%color == '#c0c0c0' .and. index(svg, '<filter id="textbox"') > 0 .and. &
                           index(svg, 'filter="url(#textbox)"') > 0
      endassociate
   endblock
endif
open(newunit=unit, file='foresight_script_test_textbox.svg')
close(unit, status='delete')
call interpreter%run_text('set style textbox 4 opaque', iostat, iomsg)
test_passed(174) = test_passed(174) .and. iostat /= 0_I4P .and. index(iomsg, 'styles are 0 to 3') > 0


! set label ... boxed [bs N]: on the background when that text box style is drawn
call interpreter%init(scratch)
call interpreter%run_text('set style textbox 1 transparent noborder; set label 1 "a" at 0,0 boxed; '// &
                          'set label 2 "b" at 1,1 boxed bs 1; set label 3 "c" at 2,2', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(175) = iostat == 0_I4P
if (test_passed(175)) test_passed(175) = interpreter%figure%panels(1)%notes(1)%boxed .and. &
                                       .not. interpreter%figure%panels(1)%notes(2)%boxed .and. &
                                       .not. interpreter%figure%panels(1)%notes(3)%boxed


! keyentry (a key entry only, untitled unless titled), set urange/vrange/xyplane read and ignored, noenh, rangelimit,
! boxed titles and histogram group titles, an empty tick list `set xtics ()`
call interpreter%init(scratch)
call interpreter%run_text('set urange [0:1]; set xyplane 0; set label 1 "x_1" at 0,0 noenh; set tics rangelimit; '// &
                          'set title "T" boxed; set style histogram clustered title boxed; set xtics (); '// &
                          'plot x, keyentry with boxes lc "red" title "legend", keyentry with boxes', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(176) = iostat == 0_I4P
if (test_passed(176)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(176) = size(panel%series) == 3 .and. panel%series(2)%title == 'legend' .and. &
                        panel%series(3)%title == '' .and. panel%notes(1)%plain .and. panel%xaxis%tics%rangelimited &
                        .and. panel%title_boxed .and. panel%hist_title_boxed .and. .not. panel%xaxis%tics%series
   endassociate
endif

! the '+' pseudo-file: set samples over the x range ([-10:10] autoscaled without data), the dummy x its value;
! `sample [i=a:b:step]` names the variable and the interval, a later item's [t=a:b:step] its own
call interpreter%init(scratch)
call interpreter%run_text('set samples 5; f(x) = 2*x; plot sample [i=5:20:5] ''+'' using (i):(cos(i)), '// &
                          '[t=-3:3:1.5] ''+'' using (t):(t); plot ''+'' using 1:(f(x))', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(177) = iostat == 0_I4P
if (test_passed(177)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(177) = size(series) == 1
      if (test_passed(177)) test_passed(177) = &
         all(abs(series(1)%x - [-10.0_R8P, -5.0_R8P, 0.0_R8P, 5.0_R8P, 10.0_R8P]) < 1.0e-12_R8P) .and. &
         all(abs(series(1)%y - 2.0_R8P * series(1)%x) < 1.0e-12_R8P)
   endassociate
endif
if (test_passed(177)) then
   call interpreter%init(scratch)
   call interpreter%run_text('set samples 5; plot sample [i=5:20:5] ''+'' using (i):(cos(i)), '// &
                             '[t=-3:3:1.5] ''+'' using (t):(t)', iostat, iomsg)
   test_passed(177) = iostat == 0_I4P
   if (test_passed(177)) then
      associate(series => interpreter%figure%panels(1)%series)
         test_passed(177) = all(abs(series(1)%x - [5.0_R8P, 10.0_R8P, 15.0_R8P, 20.0_R8P]) < 1.0e-12_R8P) .and. &
                            abs(series(1)%y(2) - cos(10.0_R8P)) < 1.0e-12_R8P .and. &
                            all(abs(series(2)%x - [-3.0_R8P, -1.5_R8P, 0.0_R8P, 1.5_R8P, 3.0_R8P]) < 1.0e-12_R8P)
      endassociate
   endif
endif

! the '++' pseudo-file: urange by set samples, vrange by the second set isosamples value, v from its maximum, scan lines
! apart; [u=a:b:step][v=a:b:step] an item's own grid; set trange the '+' samples
call interpreter%init(scratch)
call interpreter%run_text('set samples 3; set isosamples 2; set urange [0:1]; set vrange [10:20]; '// &
                          'plot ''++'' using 1:2, [u=0:2:1][v=5:6:1] ''++'' using (u):(u*v)', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(178) = iostat == 0_I4P
if (test_passed(178)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(178) = size(series) == 2
      if (test_passed(178)) test_passed(178) = &
         abs(series(1)%x(1)) < 1.0e-12_R8P .and. abs(series(1)%x(2) - 0.5_R8P) < 1.0e-12_R8P .and. &
         abs(series(1)%y(1) - 20.0_R8P) < 1.0e-12_R8P .and. abs(series(1)%y(size(series(1)%y)) - 10.0_R8P) < 1.0e-12_R8P &
         .and. abs(series(2)%y(3) - 12.0_R8P) < 1.0e-12_R8P .and. abs(series(2)%y(size(series(2)%y)) - 10.0_R8P) < 1.0e-12_R8P
   endassociate
endif
if (test_passed(178)) then
   call interpreter%init(scratch)
   call interpreter%run_text('set samples 5; set trange [0:1]; plot ''+'' using 1:1', iostat, iomsg)
   test_passed(178) = iostat == 0_I4P
   if (test_passed(178)) test_passed(178) = abs(interpreter%figure%panels(1)%series(1)%x(2) - 0.25_R8P) < 1.0e-12_R8P
endif

! with vectors as N: the heads, fill and size of `set style arrow N` (a second `set style arrow N` changes the first),
! the head size in the svg (and for the viewer); lc rgb variable 0xAARRGGBB, the transparency AA as the opacity 255-AA
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 600,400; set output "foresight_script_test_vectors_as.svg"; '// &
                          'set style arrow 1 size screen 0.03,20 noborder; set style arrow 1 lc rgb variable lw 3; '// &
                          'set xrange [-1:1]; set yrange [-1:1]; '// &
                          'plot sample [i=0:1:1] ''+'' using (0):(0):(i):(1):(0x80FF0000 + i) with vectors as 1', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(179) = iostat == 0_I4P
if (test_passed(179)) then
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_vectors_as.svg')
      associate(series => interpreter%figure%panels(1)%series(1))
         test_passed(179) = series%head_filled .and. abs(series%head_size(1) - 0.03_R8P) < 1.0e-12_R8P .and. &
                           abs(series%head_size(2) - 20.0_R8P) < 1.0e-12_R8P .and. series%head_system == 'screen' .and. &
                           index(svg, 'data-length="18" data-angle="20"') > 0 .and. &
                           index(svg, 'stroke="#ff00007f"') > 0 .and. index(svg, 'stroke="#ff00017f"') > 0
      endassociate
   endblock
endif
open(newunit=unit, file='foresight_script_test_vectors_as.svg')
close(unit, status='delete')

! with vectors size first L,A filled and lc palette z (a row with an undefined field out of the color range)
call interpreter%init(scratch)
call interpreter%run_text('$D << EOD'//new_line('a')//'0 0 1 1 2'//new_line('a')//'1 1 NaN 1 0'//new_line('a')// &
                          '2 2 1 0 4'//new_line('a')//'EOD'//new_line('a')// &
                          'plot $D using 1:2:3:4:5 with vectors size 0.5,30 filled lc palette z', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(180) = iostat == 0_I4P
if (test_passed(180)) then
   associate(series => interpreter%figure%panels(1)%series(1))
      test_passed(180) = series%head_filled .and. abs(series%head_size(1) - 0.5_R8P) < 1.0e-12_R8P .and. &
                        abs(series%head_size(2) - 30.0_R8P) < 1.0e-12_R8P .and. series%head_system == 'first' .and. &
                        series%palette_mode == 1_I4P
      if (test_passed(180)) test_passed(180) = ieee_is_nan(series%zvalues(2)) .and. series%zvalues(3) == 4.0_R8P
   endassociate
endif

! set style data|function filledcurves OPTIONS: the options of the filledcurves items given none (y=0 the base line,
! x1 a curve word); options of other styles refused, as gnuplot; set fit nolog, fit on an array
call interpreter%init(scratch)
call interpreter%run_text('set style data filledcurves y=0; set style function filledcurves y1=-1'//new_line('a')// &
                          '$D << EOD'//new_line('a')//'1 2'//new_line('a')//'2 3'//new_line('a')//'EOD'//new_line('a')// &
                          'plot $D, x with filledcurves, $D with filledcurves x1', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(181) = iostat == 0_I4P
if (test_passed(181)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(181) = series(1)%style%with == WITH_FILLEDCURVES .and. all(series(1)%ylow == 0.0_R8P) .and. &
                        all(series(2)%ylow == -1.0_R8P) .and. .not. allocated(series(3)%ylow) .and. &
                        series(3)%curve_to > 0_I4P
   endassociate
endif
if (test_passed(181)) then
   call interpreter%init(scratch)
   call interpreter%run_text('set style data lines y=0', iostat, iomsg)
   test_passed(181) = iostat /= 0_I4P .and. index(iomsg, 'filledcurves only') > 0
endif
if (test_passed(181)) then
   call interpreter%init(scratch)
   call interpreter%run_text('set fit nolog quiet; array A[5] = [1, 2, 3, 4, 5]; a = 0.5; '// &
                             'fit a*x A using 1:2 via a', iostat, iomsg)
   if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
   test_passed(181) = iostat == 0_I4P
   if (test_passed(181)) then
      block
         real(R8P) :: v     !< Fitted a.
         logical   :: found !< Defined.

         call interpreter%symbols%value_of('a', v, found)
         test_passed(181) = found .and. abs(v - 1.0_R8P) < 1.0e-6_R8P
      endblock
   endif
endif

! title ... at end|beginning by the first or last point, with or without the key; at X,Y a key entry at a screen
! position while the key is shown (`title at X,Y` the automatic title); none of them in the key; set datafile
! separator '\t' (single-quoted) the tab
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 600,400; set output "foresight_script_test_title_at.svg"; unset key; '// &
                          'set datafile separator ''\t'''//new_line('a')// &
                          '$D << EOD'//new_line('a')//'1'//achar(9)//'2'//new_line('a')//'2'//achar(9)//'3'//new_line('a')// &
                          'EOD'//new_line('a')// &
                          'plot $D title "last" at end, $D title "first" at beg, $D title "placed" at 0.5,0.5', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(182) = iostat == 0_I4P
if (test_passed(182)) then
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_title_at.svg')
      associate(series => interpreter%figure%panels(1)%series)
         test_passed(182) = series(1)%title_at == 2_I4P .and. series(2)%title_at == 1_I4P .and. &
                           series(3)%title_at == 3_I4P .and. all(abs(series(3)%title_xy - 0.5_R8P) < 1.0e-12_R8P) .and. &
                           index(svg, '>last<') > 0 .and. index(svg, '>first<') > 0 .and. index(svg, '>placed<') == 0 .and. &
                           interpreter%separator == achar(9)
      endassociate
   endblock
endif
if (test_passed(182)) then
   call interpreter%run_text('set key; set output "foresight_script_test_title_at.svg"; '// &
                             'plot $D title "last" at end, $D title at 0.5,0.5, $D title "keyed"', iostat, iomsg)
   test_passed(182) = iostat == 0_I4P
   if (test_passed(182)) then
      block
         character(len=:), allocatable :: svg !< Output.

         svg = text_of_file('foresight_script_test_title_at.svg')
         test_passed(182) = index(svg, '>$D<') > 0 .and. index(svg, '>keyed<') > 0 .and. &
                           index(svg, 'text-anchor="end">$D<') > 0
      endblock
   endif
endif
open(newunit=unit, file='foresight_script_test_title_at.svg')
close(unit, status='delete')

! pt "c": the character as the point (the first one of a UTF-8 string), tc its color, in the key too; pn N about N
! points evenly spread (gnuplot's plot_points); set style line N pt "c"; font read and ignored
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 600,400; set output "foresight_script_test_char_points.svg"; '// &
                          'set style line 3 pt "Ж"; set samples 21; set xrange [0:20]; '// &
                          'plot ''+'' using 1:1 with linespoints pt "Cxy" tc rgb "#123456" font ":Bold" pn 5, '// &
                          '''+'' using 1:(2*$1) with points ls 3', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(183) = iostat == 0_I4P
if (test_passed(183)) then
   block
      character(len=:), allocatable :: svg !< Output.
      integer(I4P)                  :: k   !< Occurrences.
      integer(I4P)                  :: p   !< Position.

      svg = text_of_file('foresight_script_test_char_points.svg')
      associate(series => interpreter%figure%panels(1)%series)
         test_passed(183) = series(1)%style%point_char == 'C' .and. series(1)%text_color == '#123456' .and. &
                           series(1)%pointnumber == 5_I4P .and. series(2)%style%point_char == 'Ж'
      endassociate
      ! pn 5 over 21 points: every 5th, from the first (plot 0): 5 markers, and the key sample
      k = 0_I4P
      p = 0_I4P
      do
         if (index(svg(p + 1:), '>C<') == 0) exit
         p = p + index(svg(p + 1:), '>C<')
         k = k + 1_I4P
      enddo
      test_passed(183) = test_passed(183) .and. k == 6_I4P .and. index(svg, '>Ж<') > 0 .and. index(svg, '#123456') > 0
   endblock
endif
open(newunit=unit, file='foresight_script_test_char_points.svg')
close(unit, status='delete')

! autoscale limits, gnuplot's [lb<*<ub:lb<*<ub]: the autoscaled ends within their limits, the tick extension too;
! set autoscale x forgets them, a bare set autoscale keeps them
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 600,400; set output "foresight_script_test_limits.svg"'//new_line('a')// &
                          '$D << EOD'//new_line('a')//'-17 -9'//new_line('a')//'18 9'//new_line('a')//'EOD'//new_line('a')// &
                          'set xrange [*<-40:30<*]; set yrange [-20<*:*<5]; plot $D', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(184) = iostat == 0_I4P
if (test_passed(184)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(184) = all(panel%xaxis%bounded .eqv. reshape([.false., .true., .true., .false.], [2, 2])) .and. &
                        abs(panel%xaxis%lo + 40.0_R8P) < 1.0e-9_R8P .and. abs(panel%xaxis%hi - 30.0_R8P) < 1.0e-9_R8P .and. &
                        abs(panel%yaxis%lo + 10.0_R8P) < 1.0e-9_R8P .and. abs(panel%yaxis%hi - 5.0_R8P) < 1.0e-9_R8P
   endassociate
endif
if (test_passed(184)) then
   call interpreter%run_text('set autoscale; plot $D', iostat, iomsg)
   test_passed(184) = iostat == 0_I4P .and. abs(interpreter%figure%panels(1)%xaxis%lo + 40.0_R8P) < 1.0e-9_R8P
   call interpreter%run_text('set autoscale x; plot $D', iostat, iomsg)
   test_passed(184) = test_passed(184) .and. iostat == 0_I4P .and. abs(interpreter%figure%panels(1)%xaxis%lo + 20.0_R8P) < &
                     1.0e-9_R8P .and. .not. any(interpreter%figure%panels(1)%xaxis%bounded)
endif
open(newunit=unit, file='foresight_script_test_limits.svg')
close(unit, status='delete')

! lc palette z on boxes and ellipses, lc variable on error bars (a bar per point in its color), labels tc variable and
! tc palette z (the text the third column, the color the fourth), ellipses units xx|yy
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 600,400; set output "foresight_script_test_varcolor.svg"'//new_line('a')// &
                          '$D << EOD'//new_line('a')//'1 2 1'//new_line('a')//'2 3 2'//new_line('a')//'EOD'//new_line('a')// &
                          'plot $D using 1:2:3 with boxes lc palette z, $D using 1:2:(0.2):3 with yerrorbars lc variable, '// &
                          '$D using 1:2:2:3 with labels tc variable, $D using 1:2:2:3 with labels tc palette z, '// &
                          '$D using 1:2:(1):(0.5):(0):3 with ellipses units yy lc palette', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(185) = iostat == 0_I4P
if (test_passed(185)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(185) = series(1)%palette_mode == 1_I4P .and. allocated(series(2)%colors) .and. &
                        allocated(series(3)%colors) .and. series(4)%palette_mode == 1_I4P .and. &
                        series(5)%ellipse_units == 'yy' .and. series(5)%palette_mode == 1_I4P
      if (test_passed(185)) test_passed(185) = series(2)%colors(1) /= series(2)%colors(2) .and. &
                                             trim(series(3)%texts(2)) == '3'
   endassociate
endif
open(newunit=unit, file='foresight_script_test_varcolor.svg')
close(unit, status='delete')

! with labels rotate variable: x:y:text:angle (and the color last, tc variable), each label at its angle
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 600,400; set output "foresight_script_test_rotate_var.svg"'//new_line('a')// &
                          '$D << EOD'//new_line('a')//'1 one -30'//new_line('a')//'2 two 45'//new_line('a')//'EOD'// &
                          new_line('a')//'plot $D using 1:1:2:3:0 with labels rotate variable tc variable, '// &
                          '$D using 1:1:2:3 with labels rotate var font ",20"', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(186) = iostat == 0_I4P
if (test_passed(186)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(186) = allocated(series(1)%text_rotations) .and. allocated(series(1)%colors) .and. &
                        allocated(series(2)%text_rotations)
      if (test_passed(186)) test_passed(186) = all(abs(series(1)%text_rotations - [-30.0_R8P, 45.0_R8P]) < 1.0e-12_R8P) &
                                             .and. trim(series(1)%texts(2)) == 'two' .and. &
                                             .not. allocated(series(2)%colors)
   endassociate
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_rotate_var.svg')
      test_passed(186) = test_passed(186) .and. index(svg, 'rotate(-45') > 0 .and. index(svg, 'rotate(30') > 0
   endblock
endif
open(newunit=unit, file='foresight_script_test_rotate_var.svg')
close(unit, status='delete')

! keyentry with the styles functions cannot take: its key sample (a filled box for the filled styles, else a line),
! first in the plot too; a keyentry does not use up a linetype (the next item takes it), as gnuplot; refused with the
! panel charts
call interpreter%init(scratch)
call interpreter%run_text('plot keyentry with boxplot title "box", keyentry with yerrorbars lc 4 title "bars", sin(x)', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(187) = iostat == 0_I4P
if (test_passed(187)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(187) = size(series) == 3
      if (test_passed(187)) test_passed(187) = series(1)%style%with == WITH_FILLEDCURVES .and. &
                                             series(1)%title == 'box' .and. series(2)%style%with == WITH_LINES .and. &
                                             series(1)%style%color == default_color(1_I4P) .and. &
                                             series(3)%style%color == default_color(1_I4P)
   endassociate
endif
if (test_passed(187)) then
   call interpreter%run_text('plot keyentry with gauge title "s"', iostat, iomsg)
   test_passed(187) = iostat /= 0_I4P .and. index(iomsg, 'keyentry with gauge is not supported') > 0
endif

! nonuniform matrix: the first row the x of the columns, the first column the y of the rows; index "name" the dataset
! after the comment line starting with the name (a quoted datablock name read as the datablock)
call interpreter%init(scratch)
call interpreter%run_text('$M << EOM'//new_line('a')//'# junk'//new_line('a')//''//new_line('a')//'# setA'//new_line('a')// &
                          '0 0.5 1.5'//new_line('a')//'2 3 4'//new_line('a')//'4 5 6'//new_line('a')//''//new_line('a')// &
                          ''//new_line('a')//'# setB'//new_line('a')//'0 10 20'//new_line('a')//'1 7 8'//new_line('a')// &
                          '3 9 10'//new_line('a')//'EOM'//new_line('a')// &
                          'plot ''$M'' nonuniform matrix index "setB" with image', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(188) = iostat == 0_I4P
if (test_passed(188)) then
   associate(series => interpreter%figure%panels(1)%series(1))
      test_passed(188) = series%style%with == WITH_IMAGE
      if (test_passed(188)) test_passed(188) = all(abs(series%grid - reshape([7.0_R8P, 8.0_R8P, 9.0_R8P, 10.0_R8P], &
                                                                         [2, 2])) < 1.0e-12_R8P)
   endassociate
endif
if (test_passed(188)) then
   call interpreter%run_text('plot ''$M'' nonuniform matrix index "setZ" with image', iostat, iomsg)
   test_passed(188) = iostat /= 0_I4P .and. index(iomsg, 'no dataset of that name') > 0
endif

! set logscale r: the pole at the r axis start, the radius log10(r / rmin), points below it undefined; impulses on a
! polar panel from the pole; set rtics rotate; set noxtics as unset xtics, set view read and ignored
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 500,500; set output "foresight_script_test_logr.svg"'//new_line('a')// &
                          '$D << EOD'//new_line('a')//'0 1'//new_line('a')//'90 10'//new_line('a')//'180 100'// &
                          new_line('a')//'270 0.1'//new_line('a')//'EOD'//new_line('a')// &
                          'set polar; set angles degrees; set logscale r 10; set rrange [1:100]; set rtics rotate by 90; '// &
                          'set noxtics; set view equal xy; plot $D with impulses', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(189) = iostat == 0_I4P
if (test_passed(189)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(189) = panel%raxis%log .and. panel%xaxis%tics%mode == TICS_NONE .and. &
                        abs(panel%raxis%tics%rotate - 90.0_R8P) < 1.0e-12_R8P .and. panel%raxis%lo == 1.0_R8P .and. &
                        panel%raxis%hi == 100.0_R8P
   endassociate
   ! the r labels 1, 10, 100 turned, a decade apart on the page (log r)
   block
      character(len=:), allocatable :: svg  !< Output.
      real(R8P)                     :: x(3) !< Label anchors.
      integer(I4P)                  :: p    !< Position.
      integer(I4P)                  :: k    !< Label counter.

      svg = text_of_file('foresight_script_test_logr.svg')
      p = 0_I4P
      do k = 1_I4P, 3_I4P
         if (index(svg(p + 1:), 'rotate(-90 ') == 0) exit
         p = p + index(svg(p + 1:), 'rotate(-90 ') + 10
         read(svg(p + 1:index(svg(p + 1:), ' ') + p - 1), *) x(k)
      enddo
      test_passed(189) = test_passed(189) .and. k == 4_I4P
      if (test_passed(189)) test_passed(189) = abs((x(3) - x(2)) - (x(2) - x(1))) < 0.2_R8P
   endblock
endif
if (test_passed(189)) then
   call interpreter%run_text('unset logscale r; plot $D with impulses', iostat, iomsg)
   test_passed(189) = iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%raxis%log
endif
open(newunit=unit, file='foresight_script_test_logr.svg')
close(unit, status='delete')

! polar filledcurves [above|below] r=V: the band between the curve and the circle of radius V, in pieces where the
! curve is above (or below) it, closed polygons apart at gaps; refused on a cartesian panel
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 500,500; set output "foresight_script_test_polar_fill.svg"; set polar; '// &
                          'set samples 9; set trange [0:2*pi]; plot 2+cos(2*t) with filledcurves above r=2', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(190) = iostat == 0_I4P
if (test_passed(190)) then
   associate(series => interpreter%figure%panels(1)%series(1))
      test_passed(190) = series%style%with == WITH_FILLEDCURVES .and. allocated(series%ylow) .and. &
                        series%curve_side == 1_I4P
      if (test_passed(190)) test_passed(190) = all(series%ylow == 2.0_R8P)
   endassociate
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_polar_fill.svg')
      test_passed(190) = test_passed(190) .and. index(svg, '<path') > 0
   endblock
endif
if (test_passed(190)) then
   call interpreter%run_text('unset polar; plot x with filledcurves r=2', iostat, iomsg)
   test_passed(190) = iostat /= 0_I4P .and. index(iomsg, 'r=V applies to polar plots') > 0
endif
open(newunit=unit, file='foresight_script_test_polar_fill.svg')
close(unit, status='delete')

! set ttics rotate: the theta labels turned along their angle, centred at 1.1 radii; offset R moves them out (radially,
! as gnuplot); the label options alone keep the ticks, new positions keep the options
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 500,500; set output "foresight_script_test_ttics_rotate.svg"; '// &
                          'set polar; set angles degrees; set ttics 0,90; set ttics rotate offset 1; set rrange [0:2]; '// &
                          'set border polar; plot 1', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(191) = iostat == 0_I4P
if (test_passed(191)) then
   associate(ttics => interpreter%figure%panels(1)%ttics)
      test_passed(191) = ttics%rotate == 90.0_R8P .and. ttics%offset(1) == 1.0_R8P .and. ttics%mode == TICS_FIXED
   endassociate
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_ttics_rotate.svg')
      ! theta 90 at the top is upright (no turn), theta 0 on the right turned by 90 degrees
      test_passed(191) = test_passed(191) .and. index(svg, 'rotate(90 ') > 0 .and. index(svg, 'rotate(-90 ') > 0
   endblock
endif
if (test_passed(191)) then
   call interpreter%run_text('set ttics 0,45', iostat, iomsg)
   test_passed(191) = iostat == 0_I4P .and. interpreter%figure%panels(1)%ttics%rotate == 90.0_R8P
   call interpreter%run_text('set ttics norotate', iostat, iomsg)
   test_passed(191) = test_passed(191) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%ttics%rotate == 0.0_R8P
endif
open(newunit=unit, file='foresight_script_test_ttics_rotate.svg')
close(unit, status='delete')

! array elements assigned inside expressions, gnuplot's `stats FILE using (A[int($0+1)] = $2)`: stored when the row is
! read, the value of the assignment the value; reads of an array the expression assigns are read when run
call interpreter%init(scratch)
call interpreter%run_text('$D << EOD'//new_line('a')//'1 10'//new_line('a')//'2 20'//new_line('a')//'3 30'// &
                          new_line('a')//'EOD'//new_line('a')//'array A[3]; '// &
                          'stats $D using (A[int($0+1)] = $2) nooutput; x = A[1] + A[2] + A[3]; '// &
                          'y = (A[1] = 7, A[1] + 1); stats $D using (A[2] = A[2] + $2) nooutput; z = A[2]', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(192) = iostat == 0_I4P
if (test_passed(192)) then
   block
   real(R8P) :: v     !< Value.
   logical   :: found !< Found.

   call interpreter%symbols%value_of('x', v, found)
   test_passed(192) = found .and. v == 60.0_R8P
   call interpreter%symbols%value_of('y', v, found)
   test_passed(192) = test_passed(192) .and. found .and. v == 8.0_R8P
   call interpreter%symbols%value_of('z', v, found)
   test_passed(192) = test_passed(192) .and. found .and. v == 80.0_R8P
   endblock
endif
! out of range: an error
call interpreter%run_text('w = (A[4] = 1)', iostat, iomsg)
test_passed(192) = test_passed(192) .and. iostat /= 0_I4P .and. index(iomsg, 'out of range') > 0

! arrowstyle variable: each arrow the heads, fill, width and color of the style its column names (a style not defined
! the item's own); arrow words among the other options, `with vectors lt 4 filled`
call interpreter%init(scratch)
call interpreter%run_text('$V << EOD'//new_line('a')//'0 0 1 1 1'//new_line('a')//'1 0 1 1 2'//new_line('a')// &
                          '2 0 1 1 99'//new_line('a')//'EOD'//new_line('a')// &
                          'set term svg; set output "foresight_script_test_arrowvar.svg"; '// &
                          'set style arrow 1 nohead lc rgb "red" lw 3; set style arrow 2 heads filled lc rgb "blue"; '// &
                          'plot $V using 1:2:3:4:5 with vectors as var title "T", '// &
                          '$V using 1:($2+2):3:4 with vectors lt 4 filled', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(193) = iostat == 0_I4P
if (test_passed(193)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(193) = allocated(series(1)%arrow_heads)
      if (test_passed(193)) test_passed(193) = all(series(1)%arrow_heads == [0_I4P, 3_I4P, 1_I4P]) .and. &
                                             all(series(1)%arrow_filled .eqv. [.false., .true., .false.]) .and. &
                                             all(series(1)%arrow_widths == [3.0_R8P, 1.0_R8P, 1.0_R8P])
      test_passed(193) = test_passed(193) .and. series(2)%head_filled .and. .not. allocated(series(2)%arrow_heads)
   endassociate
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_arrowvar.svg')
      test_passed(193) = test_passed(193) .and. index(svg, 'data-head="0" data-filled="0" fill="none" stroke="#ff0000" '// &
                                                        'stroke-width="3"') > 0 .and. &
                        index(svg, 'data-head="3" data-filled="1" fill="none" stroke="#0000ff"') > 0
   endblock
endif
open(newunit=unit, file='foresight_script_test_arrowvar.svg')
close(unit, status='delete')
! an arrowstyle variable item needs its style column
call interpreter%run_text('plot $V using 1:2:3:4 with vectors as variable', iostat, iomsg)
test_passed(193) = test_passed(193) .and. iostat /= 0_I4P .and. index(iomsg, 'style[:z]') > 0

! filledcurves above|below without y=V nor a band: above or below y = 0; with an axis word (`above x1`) the words
! dropped, as gnuplot 6.0; the rgbform abbreviation; fc palette cb V; image pixels; `set key title "T" left` a title
! justification, not the key's place
call interpreter%init(scratch)
call interpreter%run_text('$D << EOD'//new_line('a')//'-1 -1'//new_line('a')//'1 1'//new_line('a')//'EOD'// &
                          new_line('a')//'set palette rgbform -7,2,-7; set key outside right center; '// &
                          'set key title "Outcomes" left; '// &
                          'plot x with filledcurves above, $D with filledcurves below, $D with filledcurves above x1, '// &
                          'keyentry with boxes fc palette cb 1 title "one"', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(194) = iostat == 0_I4P
if (test_passed(194)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(194) = all(panel%palette%formulae == [-7_I4P, 2_I4P, -7_I4P]) .and. panel%key_h == 'right' .and. &
                        panel%key_outside
      test_passed(194) = test_passed(194) .and. panel%series(1)%curve_side == 1_I4P .and. &
                        panel%series(2)%curve_side == -1_I4P .and. panel%series(2)%curve_to == 0_I4P .and. &
                        all(panel%series(2)%ylow == 0.0_R8P)
      test_passed(194) = test_passed(194) .and. panel%series(3)%curve_side == 0_I4P .and. panel%series(3)%curve_to == 1_I4P
      test_passed(194) = test_passed(194) .and. panel%series(4)%palette_mode == 2_I4P
   endassociate
endif

! using forms of the demos: a header substring title `columnhead(2)[1:1]`, empty tic labels as ticks on two axes
! (`xtic(""):ytic("")`, the rug), a spec continued after a colon, a variable assigned by a field read by the next,
! every with expressions, labels with further columns
call interpreter%init(scratch)
call interpreter%run_text('$D << EOD'//new_line('a')//'A Bee'//new_line('a')//'1 2'//new_line('a')//'3 4'// &
                          new_line('a')//'EOD'//new_line('a')//'$E << EOD'//new_line('a')//'1 2'//new_line('a')// &
                          '3 4'//new_line('a')//'EOD'//new_line('a')//'j = 1; '// &
                          'plot $D using 1:2 title columnhead(2)[1:2], $D using 1:2:xtic(""):ytic("") with points, '// &
                          '$E using 1: 2 every ::j::j, $D using 1:(T = $1 + $2, T):($2 / T) with yerrorbars, '// &
                          '$D using 1:2:2:0 with labels', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(195) = iostat == 0_I4P
if (test_passed(195)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(195) = panel%series(1)%title == 'Be' .and. allocated(panel%series(2)%xlabels) .and. &
                        allocated(panel%series(2)%xlabels2) .and. panel%series(2)%label_axis == 'y' .and. &
                        panel%series(2)%label_axis2 == 'x'
      test_passed(195) = test_passed(195) .and. size(panel%series(3)%x) == 1
      if (test_passed(195)) test_passed(195) = panel%series(3)%x(1) == 3.0_R8P
      test_passed(195) = test_passed(195) .and. size(panel%series(4)%y) == 2
      if (test_passed(195)) test_passed(195) = panel%series(4)%y(2) == 7.0_R8P .and. &
                                             abs(panel%series(4)%yhigh(2) - (7.0_R8P + 4.0_R8P / 7.0_R8P)) < 1e-12_R8P
   endassociate
   call interpreter%run_text('set term svg; set output "foresight_script_test_rug.svg"; replot', iostat, iomsg)
   test_passed(195) = test_passed(195) .and. iostat == 0_I4P
   ! the rug: ticks at x = 1, 3 and y = 2, 4 (both data rows), their labels empty
   associate(panel => interpreter%figure%panels(1))
      test_passed(195) = test_passed(195) .and. size(panel%xaxis%labels) == 2 .and. size(panel%yaxis%labels) == 2
   endassociate
   open(newunit=unit, file='foresight_script_test_rug.svg')
   close(unit, status='delete')
endif

! sharpen: the truncated extrema of a function found between its samples and added (gnuplot 6.0's filter), the
! minima of abs(sin(x)) reach 0; set ticslevel read and ignored
call interpreter%init(scratch)
call interpreter%run_text('set ticslevel 0.5; set samples 50; set xrange [-8:8]; '// &
                          'set term svg; set output "foresight_script_test_sharpen.svg"; '// &
                          'plot abs(sin(x)) sharpen, abs(sin(x)) + 1', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(196) = iostat == 0_I4P
if (test_passed(196)) then
   associate(panel => interpreter%figure%panels(1))
      ! the sharpened curve: more points than samples, ascending, the minima at the multiples of pi
      test_passed(196) = size(panel%series(1)%x) > 50 .and. size(panel%series(2)%x) == 50 .and. &
                        all(panel%series(1)%x(2:) >= panel%series(1)%x(:size(panel%series(1)%x) - 1))
      if (test_passed(196)) test_passed(196) = minval(abs(panel%series(1)%y)) < 1.0e-9_R8P .and. &
                                             minval(abs(panel%series(2)%y)) > 1.0_R8P
   endassociate
endif
open(newunit=unit, file='foresight_script_test_sharpen.svg')
close(unit, status='delete')

! newspiderplot: a new group of polygons on the same axes; keyentry with spiderplot: a key entry, no axis; the polygon
! color and width of a group from its first item; an array source read for its first row, as gnuplot 6.0
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 600,500; set output "foresight_script_test_spider.svg"; '// &
                          'array A1 = [15, 75, 20]; array A2 = [25, 25, 50]; set spiderplot; '// &
                          'set for [i=1:3] paxis i range [0:100]; set style spiderplot fs transparent solid 0.2 border; '// &
                          'plot keyentry with spiderplot lc 3 lw 3 title "One", '// &
                          'for [i=1:|A1|] A1 using (A1[i]) lc 3 lw 3 title sprintf("S%d", i), newspiderplot, '// &
                          'keyentry with spiderplot lc 4 title "Two", for [j=1:|A2|] A2 using (A2[j]) lc 4 notitle', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(197) = iostat == 0_I4P
if (test_passed(197)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(197) = size(panel%series) == 8 .and. panel%series(1)%spider_key .and. panel%series(5)%spider_key .and. &
                        all(panel%series(2:4)%spider_group == 0_I4P) .and. &
                        all(panel%series(6:8)%spider_group == 1_I4P) .and. panel%series(2)%spider_lw == 3.0_R8P
      if (test_passed(197)) test_passed(197) = size(panel%series(2)%y) == 1 .and. panel%series(3)%y(1) == 75.0_R8P
   endassociate
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_spider.svg')
      ! the polygon of the first group 3 px wide; the axes named by the first group; the key entries named
      test_passed(197) = index(svg, '>S2<') > 0 .and. index(svg, '>One<') > 0 .and. index(svg, '>Two<') > 0 .and. &
                        index(svg, 'stroke-width="3"') > 0
   endblock
endif
open(newunit=unit, file='foresight_script_test_spider.svg')
close(unit, status='delete')

! polar error bars: yerrorbars on a polar panel, each bar along the radius from r - dr to r + dr at theta, its caps
! across it (gnuplot 6.0's poldat.dem); the r range reaches the bar ends
call interpreter%init(scratch)
call interpreter%run_text('$P << EOD'//new_line('a')//'0 1.3 0.2'//new_line('a')//'90 0.5 0.1'//new_line('a')//'EOD'// &
                          new_line('a')//'set term svg; set output "foresight_script_test_polar_bars.svg"; '// &
                          'set polar; set angles degrees; plot $P with yerrorbars', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(198) = iostat == 0_I4P
if (test_passed(198)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(198) = allocated(panel%series(1)%yhigh)
   endassociate
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_polar_bars.svg')
      ! radial bars drawn as lines (no vertical fs-ybars)
      test_passed(198) = test_passed(198) .and. index(svg, 'fs-ybars') == 0 .and. index(svg, 'polyline') > 0
   endblock
endif
open(newunit=unit, file='foresight_script_test_polar_bars.svg')
close(unit, status='delete')

! named colormaps: `set colormap new NAME` saves the palette, `lc palette NAME` colors z by it (over its range if set,
! `set colormap NAME range [a:b]`); `set key textcolor rgb variable`; `dt solid`
call interpreter%init(scratch)
call interpreter%run_text('$C << EOD'//new_line('a')//'1 1 0'//new_line('a')//'2 2 10'//new_line('a')//'EOD'// &
                          new_line('a')//'set term svg; set output "foresight_script_test_colormap.svg"; '// &
                          'set palette defined (0 "white", 1 "red"); set colormap new reds; '// &
                          'set palette defined (0 "white", 1 "blue"); set colormap new blues; '// &
                          'set colormap blues range [0:20]; set cbrange [0:10]; set key textcolor rgb variable; '// &
                          'set errorbars lw 1 dt solid; '// &
                          'plot $C using 1:2:3 with points lc palette reds, $C using 1:($2+1):3 with points lc pal blues', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(199) = iostat == 0_I4P
if (test_passed(199)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(199) = panel%key_tc == 'variable' .and. allocated(panel%colormaps)
      if (test_passed(199)) test_passed(199) = size(panel%colormaps) == 2 .and. panel%series(1)%colormap == 1_I4P .and. &
                                             panel%series(2)%colormap == 2_I4P .and. panel%colormaps(2)%ranged
   endassociate
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_colormap.svg')
      ! z = 10: full red with reds over the cb range [0:10]; half blue (#8080ff) with blues over its own [0:20]
      test_passed(199) = test_passed(199) .and. index(svg, '#ff0000') > 0 .and. index(svg, '#7f7fff') + &
                        index(svg, '#8080ff') > 0
   endblock
endif
open(newunit=unit, file='foresight_script_test_colormap.svg')
close(unit, status='delete')
call interpreter%run_text('plot $C using 1:2:3 with points lc palette greens', iostat, iomsg)
test_passed(199) = test_passed(199) .and. iostat /= 0_I4P .and. index(iomsg, 'no colormap "greens"') > 0

! smooth path: a spline along each set of points in their order (gnuplot 6.0's along-path splines), from the first point
! to the last, the sets apart; with filledcurves every set closed
call interpreter%init(scratch)
call interpreter%run_text('$S << EOD'//new_line('a')//'1 2'//new_line('a')//'1.5 2'//new_line('a')//'2 2.5'// &
                          new_line('a')//'3 5'//new_line('a')//''//new_line('a')//'3 3'//new_line('a')//'3.5 3.1'// &
                          new_line('a')//'3.6 3.7'//new_line('a')//'3 3'//new_line('a')//'EOD'//new_line('a')// &
                          'set samples 50; plot $S using 1:2 smooth path with lines, $S smooth path with filledcurves closed', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(200) = iostat == 0_I4P
if (test_passed(200)) then
   associate(open_path => interpreter%figure%panels(1)%series(1), closed_path => interpreter%figure%panels(1)%series(2))
      ! two sets apart at an undefined point; the open one from (1, 2) to (3, 5), the second (a ring) back to (3, 3)
      test_passed(200) = size(open_path%x) > 20 .and. count(.not. ieee_is_finite(open_path%x)) == 2
      if (test_passed(200)) test_passed(200) = open_path%x(1) == 1.0_R8P .and. open_path%y(1) == 2.0_R8P
      if (test_passed(200)) then
         block
            integer(I4P) :: k !< End of the first set.

            k = 1_I4P
            do while (ieee_is_finite(open_path%x(k + 1_I4P)))
               k = k + 1_I4P
            enddo
            test_passed(200) = open_path%x(k) == 3.0_R8P .and. open_path%y(k) == 5.0_R8P .and. &
                              open_path%x(k + 1_I4P + 1_I4P) == 3.0_R8P
         endblock
      endif
      ! filledcurves closes the open set too: its last point is its first
      test_passed(200) = test_passed(200) .and. size(closed_path%x) > size(open_path%x)
   endassociate
endif

! stats ... matrix: the values of a matrix as one column, its size and the places of its extremes (from 0, in the
! submatrix every keeps: columns as the points, rows as the blocks), as gnuplot 6.0; every on a matrix image; set xlabel
! boxed
call interpreter%init(scratch)
call interpreter%run_text('$M << EOM'//new_line('a')//'1 2 3 4'//new_line('a')//'5 6 7 8'//new_line('a')// &
                          '9 10 11 12'//new_line('a')//'EOM'//new_line('a')// &
                          'stats $M matrix nooutput; a = STATS_size_x; b = STATS_size_y; c = STATS_mean; '// &
                          'stats $M every ::1::2 matrix nooutput; d = STATS_size_x; e = STATS_index_max_x; '// &
                          'f = STATS_records; set xlabel "x" boxed; plot $M every 2 matrix with image', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(201) = iostat == 0_I4P
if (test_passed(201)) then
   block
      real(R8P) :: v(6)  !< Values read.
      logical   :: found !< Found.
      integer   :: k     !< Counter.
      character(len=1), parameter :: NAMES(6) = ['a', 'b', 'c', 'd', 'e', 'f'] !< Variables.

      do k = 1, 6
         call interpreter%symbols%value_of(NAMES(k), v(k), found)
         test_passed(201) = test_passed(201) .and. found
      enddo
      ! gnuplot 6.0: 4 x 3, mean 6.5; every ::1::2 keeps columns 1 and 2: 2 wide, the max (11) at column 1, 6 values
      test_passed(201) = test_passed(201) .and. all(v == [4.0_R8P, 3.0_R8P, 6.5_R8P, 2.0_R8P, 1.0_R8P, 6.0_R8P])
   endblock
   associate(panel => interpreter%figure%panels(1))
      ! every 2: columns 0 and 2, at their places
      test_passed(201) = test_passed(201) .and. size(panel%series(1)%grid, 1) == 2 .and. panel%label_boxed == 1_I4P
   endassociate
endif

! negative r with a fixed r range, as gnuplot 6.0's polar_to_xy: r >= rmin at r - rmin; r < -rmin (rmin >= 0) across
! the pole at r + rmin; between them undefined
block
   character(len=*), parameter :: RANGES(3) = ['[0:2]  ', '[0.5:2]', '[-1:2] '] !< r ranges.
   character(len=*), parameter :: PATHS(3) = [character(len=48) :: 'd="M0.25,0.5 M0.5,0.625 M0.676777,0.323223"', &
                                              'd="M0.333333,0.5 M0.617851,0.382149"', &
                                              'd="M0.5,0.5 M0.5,0.416667 M0.735702,0.264298"'] !< Unit points.
   character(len=:), allocatable :: svg !< Output.
   integer                       :: k   !< Counter.

   test_passed(202) = .true.
   do k = 1, 3
      call interpreter%init(scratch)
      call interpreter%run_text('$R << EOD'//new_line('a')//'0 -1'//new_line('a')//'90 -0.5'//new_line('a')//'45 1'// &
                                new_line('a')//'EOD'//new_line('a')//'set term svg size 400,400; '// &
                                'set output "foresight_script_test_negative_r.svg"; set polar; set angles degrees; '// &
                                'unset key; set rrange '//trim(RANGES(k))//'; plot $R with points pt 7', iostat, iomsg)
      if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
      svg = text_of_file('foresight_script_test_negative_r.svg')
      test_passed(202) = test_passed(202) .and. iostat == 0_I4P .and. index(svg, trim(PATHS(k))) > 0
   enddo
   open(newunit=unit, file='foresight_script_test_negative_r.svg')
   close(unit, status='delete')
endblock

! a title with "\n" on two lines, as gnuplot: each line its own text, the second a row lower, the plot area lower
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 600,400; set output "foresight_script_test_title_lines.svg"; '// &
                          'set title "first line\nsecond line"; plot x', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(203) = iostat == 0_I4P
if (test_passed(203)) then
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_title_lines.svg')
      test_passed(203) = index(svg, '>first line</text>') > 0 .and. index(svg, '>second line</text>') > 0 .and. &
                        index(svg, '&#10;') == 0
   endblock
endif
open(newunit=unit, file='foresight_script_test_title_lines.svg')
close(unit, status='delete')

! an empty range end keeps the end as it is (gnuplot 6.0: `set xrange [2:5]; set xrange [:10]` is [2:10]); `*`
! autoscales it
call interpreter%init(scratch)
call interpreter%run_text('set xrange [2:5]; set xrange [:10]; set yrange [1:2]; set yrange [*:3]', iostat, iomsg)
test_passed(204) = iostat == 0_I4P
if (test_passed(204)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(204) = panel%xaxis%min_fixed .and. panel%xaxis%min_user == 2.0_R8P .and. panel%xaxis%max_fixed .and. &
                        panel%xaxis%max_user == 10.0_R8P .and. .not. panel%yaxis%min_fixed .and. &
                        panel%yaxis%max_user == 3.0_R8P
   endassociate
endif
call interpreter%run_text('set xrange [3:]', iostat, iomsg)
associate(panel => interpreter%figure%panels(1))
   test_passed(204) = test_passed(204) .and. iostat == 0_I4P .and. panel%xaxis%min_user == 3.0_R8P .and. &
                     panel%xaxis%max_fixed .and. panel%xaxis%max_user == 10.0_R8P
endassociate

! the scripts' default tick labels are gnuplot's `% h`: %g per label (500000, 1x10^6), `%.Pf` for a narrow axis away
! from 0 (gnuplot's invented precision); the library keeps its rule (its goldens)
call interpreter%init(scratch)
call interpreter%run_text('set term svg; set output "foresight_script_test_h_labels.svg"; set yrange [0:2e6]; '// &
                          'set xrange [1e-6:1e-5]; plot x', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(205) = iostat == 0_I4P
if (test_passed(205)) then
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_h_labels.svg')
      test_passed(205) = index(svg, '>500000</text>') > 0 .and. index(svg, '>1.5x10<tspan') > 0 .and. &
                        index(svg, '>0.000010</text>') > 0 .and. index(svg, 'data-yformat="%h"') > 0
   endblock
endif
open(newunit=unit, file='foresight_script_test_h_labels.svg')
close(unit, status='delete')

! set size ratio -1: equal units, the plot area height over width the y span over the x span; positions `polar
! THETA, R` and labels on a polar panel
call interpreter%init(scratch)
call interpreter%run_text('set term svg size 600,400; set output "foresight_script_test_ratio.svg"; set size ratio -1; '// &
                          'set xrange [0:4]; set yrange [0:1]; plot x/4', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(206) = iostat == 0_I4P
if (test_passed(206)) then
   block
      character(len=:), allocatable :: svg  !< Output.
      real(R8P)                     :: a(4) !< Plot area.
      integer                       :: k    !< Position.
      integer                       :: ios  !< Status.

      svg = text_of_file('foresight_script_test_ratio.svg')
      k = index(svg, 'data-area="')
      test_passed(206) = k > 0
      if (test_passed(206)) then
         read(svg(k + 11:index(svg(k + 11:), '"') + k + 9), *, iostat=ios) a
         test_passed(206) = ios == 0
         if (test_passed(206)) test_passed(206) = abs((a(4) - a(3)) / (a(2) - a(1)) - 0.25_R8P) < 1.0e-3_R8P
      endif
   endblock
endif
open(newunit=unit, file='foresight_script_test_ratio.svg')
close(unit, status='delete')
call interpreter%init(scratch)
call interpreter%run_text('set polar; set angles degrees; set theta top cw; set label 1 at polar 90, 2 "E"'//new_line('a')// &
                          '$L << EOD'//new_line('a')//'0 1 N'//new_line('a')//'EOD'//new_line('a')// &
                          'set rrange [0:3]; plot $L using 1:2:3 with labels', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
associate(note => interpreter%figure%panels(1)%notes(1))
   ! theta 90 clockwise from the top: on the right, x = 2
   test_passed(206) = test_passed(206) .and. iostat == 0_I4P .and. abs(note%at%x - 2.0_R8P) < 1.0e-12_R8P .and. &
                     abs(note%at%y) < 1.0e-12_R8P
endassociate

! set link x2 [via f inverse g]: x2 on the range of x, its ticks at nice x2 values placed through the inverse; data
! given on x2 plotted on x through the inverse; unset link
call interpreter%init(scratch)
call interpreter%run_text('set term svg; set output "foresight_script_test_link.svg"; set x2tics 1; '// &
                          'set link x2 via x*2 inv x/2; set xrange [1:5]; '// &
                          'plot sample [i=2:10:2] ''+'' using (i):(i) axes x2y1 with lp', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(207) = iostat == 0_I4P
if (test_passed(207)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(207) = panel%link_x2 .and. panel%link_x2_via .and. .not. panel%series(1)%x2
      if (test_passed(207)) test_passed(207) = abs(panel%series(1)%x(1) - 1.0_R8P) < 1.0e-12_R8P .and. &
                                             abs(panel%series(1)%x(5) - 5.0_R8P) < 1.0e-12_R8P
   endassociate
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_link.svg')
      ! the x2 labels are the doubled values: 2 ... 10, the 10 at x = 5
      test_passed(207) = test_passed(207) .and. index(svg, '>10</text>') > 0 .and. index(svg, '>9</text>') > 0
   endblock
endif
open(newunit=unit, file='foresight_script_test_link.svg')
close(unit, status='delete')
call interpreter%run_text('unset link x2', iostat, iomsg)
test_passed(207) = test_passed(207) .and. iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%link_x2

! polar inline ranges, as gnuplot 6.0: the first the t range of the functions of this plot, [t=a:b] or [a:b]
call interpreter%init(scratch)
call interpreter%run_text('set polar; set samples 11; set term svg; set output "foresight_script_test_polar_inline.svg"; '// &
                          'plot [t=0:pi] t', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(208) = iostat == 0_I4P
if (test_passed(208)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(208) = panel%taxis%plot_max_fixed .and. abs(panel%taxis%plot_max - acos(-1.0_R8P)) < 1.0e-12_R8P
   endassociate
endif
open(newunit=unit, file='foresight_script_test_polar_inline.svg')
close(unit, status='delete')

! parallel axes: set paxis N range [a:*] reverse, tics left (unrotated labels: read), lc variable and lc palette z of
! the first item (a color per row, using Y:COLOR), as gnuplot 6.0's parallel.dem
call interpreter%init(scratch)
call interpreter%run_text('$P << EOD'//new_line('a')//'1 2 3'//new_line('a')//'2 3 1'//new_line('a')//'3 1 2'// &
                          new_line('a')//'EOD'//new_line('a')//'set style data parallelaxes; '// &
                          'set paxis 2 range [0:*] reverse; set paxis 2 tics left offset 4; '// &
                          'plot $P using 1:($0+1) lc variable, '''' using 2, '''' using 3', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(209) = iostat == 0_I4P
if (test_passed(209)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(209) = panel%paxes(2)%axis%reverse .and. allocated(panel%series(1)%colors)
      if (test_passed(209)) test_passed(209) = size(panel%series(1)%colors) == 3
   endassociate
endif
call interpreter%run_text('plot $P using 1:0 lc palette, '''' using 2, '''' using 3', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(209) = test_passed(209) .and. iostat == 0_I4P
if (test_passed(209)) test_passed(209) = interpreter%figure%panels(1)%series(1)%palette_mode == 1_I4P

! tick formats without a conversion: their text on every tick (`set format y "    "`, layout.dem); `set format x ""`
! and `set xtics format ""` hide the labels, as gnuplot; `set format x` restores the default
call interpreter%init(scratch)
call interpreter%run_text('set term svg; set output "foresight_script_test_format_text.svg"; set format y "abc"; '// &
                          'set format x ""; set yrange [0:2]; set xrange [0:4]; plot x', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(210) = iostat == 0_I4P
if (test_passed(210)) then
   block
      character(len=:), allocatable :: svg !< Output.

      svg = text_of_file('foresight_script_test_format_text.svg')
      test_passed(210) = index(svg, '>abc</text>') > 0 .and. index(svg, '>1</text>') == 0 .and. &
                        interpreter%figure%panels(1)%xaxis%tics%format == ' '
   endblock
endif
open(newunit=unit, file='foresight_script_test_format_text.svg')
close(unit, status='delete')
call interpreter%run_text('set format x; set xtics format ""', iostat, iomsg)
test_passed(210) = test_passed(210) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%xaxis%tics%format == ' '

! a using data format of plain %lf conversions; a band x:y1:y2 of filledcurves smoothed (both curves on the same
! samples); a time shorter than the timefmt read with the other fields at their defaults, as gnuplot 6.0
call interpreter%init(scratch)
call interpreter%run_text('$B << EOD'//new_line('a')//'1 1 0'//new_line('a')//'2 3 1'//new_line('a')//'3 2 0'// &
                          new_line('a')//'4 4 2'//new_line('a')//'EOD'//new_line('a')//'set samples 20; '// &
                          'plot $B using 1:2:3 "%lf %lf %lf" smooth csplines with filledcurves; '// &
                          'set timefmt "%d/%m/%y\t%H%M"; t = strptime("%d/%m/%y\t%H%M", "1/6/93")', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(211) = iostat == 0_I4P
if (test_passed(211)) then
   associate(series => interpreter%figure%panels(1)%series(1))
      test_passed(211) = size(series%x) == 20 .and. allocated(series%ylow)
      if (test_passed(211)) test_passed(211) = size(series%ylow) == 20
   endassociate
   block
      real(R8P) :: v     !< Value.
      logical   :: found !< Found.

      call interpreter%symbols%value_of('t', v, found)
      test_passed(211) = test_passed(211) .and. found .and. v == 738892800.0_R8P
   endblock
endif
call interpreter%run_text('plot $B using 1:2 "%*lf %lf"', iostat, iomsg)
test_passed(211) = test_passed(211) .and. iostat /= 0_I4P .and. index(iomsg, 'blank separated %lf') > 0

! fit of several independent variables (gnuplot's using X:Y:Z:S, names x, y then set dummy's), a range per variable,
! array elements as parameters (via A[1], A[2])
call interpreter%init(scratch)
call interpreter%run_text('$F << EOD'//new_line('a')//'1 0 0 2'//new_line('a')//'0 1 0 -3'//new_line('a')// &
                          '1 1 1 3'//new_line('a')//'2 1 0 1'//new_line('a')//'1 2 1 0'//new_line('a')//'3 1 2 7'// &
                          new_line('a')//'EOD'//new_line('a')// &
                          'm(x,y) = a*x + b*y; a = 1; b = 1; fit m(x,y) $F using 1:2:4:(1) via a, b; '// &
                          'set dummy x, y, w; array A[3] = [1, 1, 1]; n(x,y,w) = A[1]*x + A[2]*y + A[3]*w; '// &
                          'fit n(x,y,w) $F using 1:2:3:4:(1) via A[1], A[2], A[3]; p = A[3]', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(212) = iostat == 0_I4P
if (test_passed(212)) then
   block
      real(R8P) :: v(3)  !< Values.
      logical   :: found !< Found.

      call interpreter%symbols%value_of('a', v(1), found)
      call interpreter%symbols%value_of('b', v(2), found)
      call interpreter%symbols%value_of('p', v(3), found)
      ! the least squares solution, as gnuplot 6.0 prints it: A = [1.53571428571479,-2.14285714285658,2.57142857142707]
      test_passed(212) = found .and. abs(v(3) - 2.57142857142707_R8P) < 1.0e-9_R8P
   endblock
endif

! column forms of the corpus: a using spec with blanks around ':', a user function calling timecolumn twice, labels
! `offset X` alone, `title at graph X, Y`, vectors with yticlabels, a log tic series, `% h` as `% g` in tables
call interpreter%init(scratch)
call interpreter%run_text('$G << EOD'//new_line('a')//'03 1 2'//new_line('a')//'05 2 3'//new_line('a')//'EOD'// &
                          new_line('a')//'g(c) = timecolumn(c, "%H"); set logscale y; set ytics 10 logscale; '// &
                          'set format y "% h"; set table $T; plot $G using (g(1) + g(1)) : 2; unset table; '// &
                          'set print "foresight_script_test_table.txt"; print $T; set print; '// &
                          'plot $G using 2 : 3 : 1 with labels offset -2 title "L" at graph 0.5, 0.9, '// &
                          '$G using 2:3:(1):(0):yticlabel(1) with vectors', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(213) = iostat == 0_I4P
if (test_passed(213)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(213) = panel%series(1)%title_at == 4_I4P .and. allocated(panel%series(2)%xlabels)
   endassociate
   block
      character(len=200) :: line  !< Table line.
      integer(I4P)       :: ios   !< Read status.
      logical            :: found !< Line found.

      ! gnuplot 6.0: " 21600  1  i", the timecolumn sum, "% h" as "% g" in a table
      found = .false.
      open(newunit=unit, file='foresight_script_test_table.txt')
      do
         read(unit, '(A)', iostat=ios) line
         if (ios /= 0) exit
         if (trim(line) == ' 21600  1  i') found = .true.
      enddo
      close(unit, status='delete')
      test_passed(213) = test_passed(213) .and. found
   endblock
endif
call interpreter%run_text('set ytics 10 nologscale', iostat, iomsg)
test_passed(213) = test_passed(213) .and. iostat == 0_I4P

! key samples as gnuplot 6.0: vectors an arrow (gnuplot_sample), keyentry with labels none, the fill border of
! filledcurves around the key sample (the global fill style) and along the curve (the item's own fs), the key title
! justification
call interpreter%init(scratch)
call interpreter%run_text('$V << EOD'//new_line('a')//'1 1 1 0.5'//new_line('a')//'2 2 1 -0.5'//new_line('a')// &
                          'EOD'//new_line('a')//'set key title "K" left; set style fill solid 0.3 border lc "red"; '// &
                          'plot $V using 1:2:3:4 with vectors title "v", $V using 1:2 with filledcurves y=0, '// &
                          'keyentry with labels title "kl", $V using 1:2 with filledcurves fs solid 0.5 border', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(214) = iostat == 0_I4P
if (test_passed(214)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(214) = panel%series(1)%gnuplot_sample .and. panel%series(2)%fill_edges == 1_I4P .and. &
                        panel%series(2)%fill_border .and. trim(panel%series(3)%style%color) == 'none' .and. &
                        panel%series(4)%fill_edges == 1_I4P .and. trim(panel%key_title_anchor) == 'start'
   endassociate
endif
call interpreter%run_text('set key title "K" right; set style fill solid noborder; '// &
                          'plot $V using 1:2 with filledcurves y=0', iostat, iomsg)
test_passed(214) = test_passed(214) .and. iostat == 0_I4P
if (test_passed(214)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(214) = .not. panel%series(1)%fill_border .and. trim(panel%key_title_anchor) == 'end'
   endassociate
endif

! inline data '-', as gnuplot 6.0: the lines after the plot up to one starting with `e` (blanks skipped), one block per
! item, the auto titles as written; fit and stats of '-'; a missing `e` an error
call interpreter%init(scratch)
call interpreter%run_text("plot '-' using 1:2 with lines, ""-"" with points"//new_line('a')//'1 2'//new_line('a')// &
                          '3 4'//new_line('a')//'e'//new_line('a')//'5 6'//new_line('a')//'  e  '//new_line('a')// &
                          "f(x) = a*x; a = 1; fit f(x) '-' using 1:2 via a"//new_line('a')//'1 2'//new_line('a')// &
                          '2 4'//new_line('a')//'3 6.1'//new_line('a')//'e'//new_line('a')// &
                          "stats [0:10] '-' using 1 nooutput"//new_line('a')//'4'//new_line('a')//'6'//new_line('a')// &
                          'e', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(215) = iostat == 0_I4P
if (test_passed(215)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(215) = size(panel%series) == 2 .and. size(panel%series(1)%x) == 2 .and. &
                        size(panel%series(2)%x) == 1
      if (test_passed(215)) test_passed(215) = trim(panel%series(1)%title) == "'-' using 1:2" .and. &
                                             trim(panel%series(2)%title) == '"-"' .and. panel%series(2)%y(1) == 6.0_R8P
   endassociate
   block
      real(R8P) :: v(2)  !< Values.
      logical   :: found !< Found.

      call interpreter%symbols%value_of('a', v(1), found)
      test_passed(215) = test_passed(215) .and. found .and. abs(v(1) - 2.02142857142857_R8P) < 1.0e-6_R8P
      call interpreter%symbols%value_of('STATS_mean', v(2), found)
      test_passed(215) = test_passed(215) .and. found .and. v(2) == 5.0_R8P
   endblock
endif
call interpreter%run_text("plot '-'"//new_line('a')//'1 2', iostat, iomsg)
test_passed(215) = test_passed(215) .and. iostat /= 0_I4P .and. index(iomsg, 'no line "e" ends it') > 0

! a linked x2 axis' automatic ticks at the primary's automatic ones, labelled by the mapped values (gnuplot 6.0: 1e4/x
! over [2:20] reads 5000, 2500, 1666.67, ...); a keyentry without a style draws no sample
call interpreter%init(scratch)
call interpreter%run_text('set output "foresight_script_test_link.svg"; set link x2 via 1e4/x inverse 1e4/x; '// &
                          'set xrange [2:20]; set x2tics; set xtics 3; plot x, keyentry title "k"', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(216) = iostat == 0_I4P
if (test_passed(216)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(216) = trim(panel%series(2)%style%color) == 'none'
      if (allocated(panel%x2axis%ticks)) then
         test_passed(216) = test_passed(216) .and. count(panel%x2axis%ticks%major) == 10
         if (test_passed(216)) test_passed(216) = abs(panel%x2axis%ticks(3)%value - 6.0_R8P) < 1.0e-9_R8P .and. &
                                                panel%x2axis%ticks(3)%label == '1666.67'
      else
         test_passed(216) = .false.
      endif
   endassociate
   open(newunit=unit, file='foresight_script_test_link.svg')
   close(unit, status='delete')
endif

! the fill border of filledcurves where gnuplot 6.0 draws it: around every key sample, along a closed curve only (not
! along a fill to y=0); one red stroke for each: the closed curve, its sample, the y=0 sample
call interpreter%init(scratch)
call interpreter%run_text('$C << EOD'//new_line('a')//'0 0.2'//new_line('a')//'1 0.6'//new_line('a')//'2 0.5'// &
                          new_line('a')//'EOD'//new_line('a')//'set output "foresight_script_test_edges.svg"; '// &
                          'set style fill solid 0.3 border lc "red"; plot $C using 1:2 with filledcurves closed, '// &
                          '$C using 1:2 with filledcurves y=0', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(217) = iostat == 0_I4P
if (test_passed(217)) then
   block
      character(len=1000) :: line !< SVG line.
      integer(I4P)        :: ios  !< Read status.
      integer(I4P)        :: n    !< Red strokes.

      n = 0_I4P
      open(newunit=unit, file='foresight_script_test_edges.svg')
      do
         read(unit, '(A)', iostat=ios) line
         if (ios /= 0) exit
         if (index(line, 'stroke="#ff0000"') > 0) n = n + 1_I4P
      enddo
      close(unit, status='delete')
      test_passed(217) = n == 3_I4P
   endblock
endif

! set nonlinear x|y via f inverse g, as gnuplot 6.0: automatic ticks at the hidden axis' ticks (a step of 1 at least)
! labelled by g (sqrt over [0:100]: 0, 4, 16, ..., 100), placed linearly in f; a broken axis (f undefined inside) keeps
! its ends placeable; set arrow from P length L angle A; a bare set output back to the default output
call interpreter%init(scratch)
call interpreter%run_text('set output "foresight_script_test_nonlinear.svg"; set xrange [0:100]; '// &
                          'set nonlinear x via sqrt(x) inverse x**2; set yrange [15:600] noextend; '// &
                          'f(x) = (x <= 100) ? x : (x < 500) ? NaN : (x - 375); '// &
                          'g(x) = (x <= 100) ? x : (x < 125) ? NaN : (x + 375); set nonlinear y via f(y) inverse g(y); '// &
                          'set ytics 50; set arrow 1 from 50, graph 0 length graph 0.1 angle 90; plot x', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(218) = iostat == 0_I4P
if (test_passed(218)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(218) = size(panel%xaxis%ticks) == 6
      if (test_passed(218)) test_passed(218) = panel%xaxis%ticks(3)%label == '16' .and. &
         abs(panel%xaxis%to_unit(16.0_R8P) - 0.4_R8P) < 1.0e-9_R8P .and. &
         abs(panel%xaxis%to_unit(30.0_R8P) - sqrt(30.0_R8P) / 10.0_R8P) < 1.0e-5_R8P
      ! y: 100 and 500 placed (the edges of the gap), 300 not
      test_passed(218) = test_passed(218) .and. panel%yaxis%accepts(100.0_R8P) .and. panel%yaxis%accepts(500.0_R8P) .and. &
                        .not. panel%yaxis%accepts(300.0_R8P) .and. &
                        abs(panel%yaxis%to_unit(500.0_R8P) - (125.0_R8P - 15.0_R8P) / 210.0_R8P) < 1.0e-9_R8P
   endassociate
endif
call interpreter%run_text('set output; unset nonlinear', iostat, iomsg)
test_passed(218) = test_passed(218) .and. iostat == 0_I4P
call interpreter%run_text('set nonlinear x2 via x inverse x', iostat, iomsg)
test_passed(218) = test_passed(218) .and. iostat /= 0_I4P
open(newunit=unit, file='foresight_script_test_nonlinear.svg')
close(unit, status='delete')

! parser forms of the demos, as gnuplot 6.0: using "NAME" alone, definitions before an iterated item run on each pass,
! an assignment glued to its item in the title, label at x, y, z, ls (expr), index expr, a trailing comma, set terminal
! push|pop, set rrange [90:0] (reversed r), UTF-8 names (π = pi), ttics list then font, ytics nologscale (an additive
! step on a log axis)
call interpreter%init(scratch)
call interpreter%run_text('$H << EOD'//new_line('a')//'x A B'//new_line('a')//'1 2 3'//new_line('a')//'2 4 5'// &
                          new_line('a')//''//new_line('a')//''//new_line('a')//'3 1 1'//new_line('a')//'EOD'// &
                          new_line('a')//'set terminal push; set terminal pop; π = pi; φ(λ) = 2*λ; '// &
                          'set label 1 "a" at graph 0.5, 0.85, 0 center; array r[2] = [1, 2]; set style line 2 lc "red"; '// &
                          'plot $H u "A" t col, ysum=0 $H u 1:(ysum=ysum+$2, ysum), '// &
                          'for [i = 1:2] k = r[i], m = φ(i), k*x+m title sprintf("%d", m), $H index (2-1) ls (1+1),', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(219) = iostat == 0_I4P
if (test_passed(219)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(219) = size(panel%series) == 5
      if (test_passed(219)) test_passed(219) = panel%series(1)%y(2) == 4.0_R8P .and. &
         trim(panel%series(2)%title) == 'ysum=0 $H u 1:(ysum=ysum+$2, ysum)' .and. &
         trim(panel%series(3)%title) == '2' .and. trim(panel%series(4)%title) == '4' .and. &
         size(panel%series(5)%x) == 1 .and. trim(panel%series(5)%style%color) == '#ff0000'
   endassociate
   block
      real(R8P) :: v     !< Value.
      logical   :: found !< Found.

      call interpreter%symbols%value_of('π', v, found)
      test_passed(219) = test_passed(219) .and. found .and. abs(v - acos(-1.0_R8P)) < 1.0e-15_R8P
   endblock
endif
call interpreter%run_text('set output "foresight_script_test_rr.svg"; set polar; set rrange [90:0]; '// &
                          'set ttics add ("N" 0) font ":Bold"; plot 60', iostat, iomsg)
test_passed(219) = test_passed(219) .and. iostat == 0_I4P
if (test_passed(219)) then
   associate(panel => interpreter%figure%panels(1))
      ! a [90:0] r axis: 90 at the pole, 0 on the rim
      test_passed(219) = panel%raxis%lo == 90.0_R8P .and. panel%raxis%hi == 0.0_R8P
   endassociate
endif
call interpreter%init(scratch)
call interpreter%run_text('set output "foresight_script_test_rr.svg"; set log y; set yrange [0.1:1]; '// &
                          'set ytics 0.1 nolog; plot x', iostat, iomsg)
test_passed(219) = test_passed(219) .and. iostat == 0_I4P
if (test_passed(219)) test_passed(219) = count(interpreter%figure%panels(1)%yaxis%ticks%major) == 10
open(newunit=unit, file='foresight_script_test_rr.svg')
close(unit, status='delete')

! time and boxplot forms of the demos, as gnuplot 6.0: set xtics time (timedate), set mxtics time 5 min, labels with
! tic labels, strptime %z and %Z, strftime %.3S rounded, boxplot factors in lc variable (lt N, N+1, ...), noautoscale
call interpreter%init(scratch)
call interpreter%run_text('$L << EOD'//new_line('a')//'1 A'//new_line('a')//'2 B'//new_line('a')//'EOD'// &
                          new_line('a')//'set xtics time format "%H"; set mxtics time 5 min; '// &
                          't1 = strptime("%d/%m/%y %H:%M%z", "18/02/19 12:24+01:00"); '// &
                          't2 = strptime("%d/%m/%y %H:%M %Z", "18/02/19 13:24 CET"); '// &
                          's = strftime("%H:%M:%.3S", 1390852607.1); '// &
                          'plot $L using 1:1:(strcol(2)):xticlabels(2):yticlabels(2) with labels', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(220) = iostat == 0_I4P
if (test_passed(220)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(220) = panel%xaxis%time .and. panel%xaxis%tics%minor_unit == 'minutes' .and. &
                        panel%xaxis%tics%minor_count == 5_I4P .and. allocated(panel%series(1)%xlabels) .and. &
                        allocated(panel%series(1)%xlabels2)
      if (test_passed(220)) test_passed(220) = trim(panel%series(1)%texts(2)) == 'B' .and. &
                                             trim(panel%series(1)%xlabels(1)) == 'A'
   endassociate
   block
      real(R8P)                     :: v(2)  !< Values.
      logical                       :: found !< Found.
      character(len=:), allocatable :: text  !< String.

      call interpreter%symbols%value_of('t1', v(1), found)
      call interpreter%symbols%value_of('t2', v(2), found)
      ! gnuplot 6.0: 1550489040 and 1550496240
      test_passed(220) = test_passed(220) .and. v(1) == 1550489040.0_R8P .and. v(2) == 1550496240.0_R8P
      call interpreter%symbols%string_of('s', text, found)
      test_passed(220) = test_passed(220) .and. found .and. text == '19:56:47.100'
   endblock
endif
call interpreter%init(scratch)
call interpreter%run_text('$B << EOD'//new_line('a')//'1 A'//new_line('a')//'2 A'//new_line('a')//'3 B'//new_line('a')// &
                          '5 B'//new_line('a')//'EOD'//new_line('a')//'set linetype 51 lc "red"; '// &
                          'set linetype 52 lc "green"; set style data boxplot; '// &
                          'plot $B using (1):1:(0):2 lt 51 lc variable, $B using (5):($1*100) w p noauto', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(220) = test_passed(220) .and. iostat == 0_I4P
if (test_passed(220)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(220) = allocated(panel%series(1)%colors) .and. panel%series(2)%noautoscale
      if (test_passed(220)) test_passed(220) = trim(panel%series(1)%colors(1)) == '#ff0000' .and. &
                                             trim(panel%series(1)%colors(2)) == '#00ff00'
   endassociate
endif

! fidelity to gnuplot 6.0's renders: lc rgb 0xAARRGGBB numbers, ls -1 black, rowstacked histograms on their row
! numbers (a missing value keeps the rows of the next ones), their table values, a tall key wrapped into columns,
! labels on several lines
call interpreter%init(scratch)
call interpreter%run_text('set datafile missing "-"'//new_line('a')//'$D << EOD'//new_line('a')//'r1 1 - 2'// &
                          new_line('a')//'r2 1 1 1'//new_line('a')//'EOD'//new_line('a')// &
                          'set style data histograms; set style histogram rowstacked; '// &
                          'plot $D using 2:xtic(1) lc rgb 0xcdc0b0, "" using 3 lc rgb 0x80ff0000, "" using 4 ls -1', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(221) = iostat == 0_I4P
if (test_passed(221)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(221) = trim(panel%series(1)%style%color) == '#cdc0b0' .and. &
                        trim(panel%series(2)%style%color) == '#ff00007f' .and. &
                        trim(panel%series(3)%style%color) == '#000000'
      ! row r1: 1 then 2 on it (the second series has no r1), top 3
      if (test_passed(221)) test_passed(221) = panel%series(3)%y(1) == 3.0_R8P .and. panel%series(3)%ylow(1) == 1.0_R8P
   endassociate
endif
call interpreter%init(scratch)
call interpreter%run_text('set output "foresight_script_test_wrap.svg"; set terminal svg size 400,200; '// &
                          'set label 1 "a\nb" at 1, 1; plot for [i=1:30] i*x title sprintf("%d", i)', iostat, iomsg)
test_passed(221) = test_passed(221) .and. iostat == 0_I4P
if (test_passed(221)) then
   block
      character(len=1000) :: line !< SVG line.
      integer(I4P)        :: ios  !< Read status.
      integer(I4P)        :: n    !< Label lines.
      real(R8P)           :: xs(2) !< Abscissae of the titles "1" and "30".
      integer(I4P)        :: k    !< Position.

      n = 0_I4P
      xs = 0.0_R8P
      open(newunit=unit, file='foresight_script_test_wrap.svg')
      do
         read(unit, '(A)', iostat=ios) line
         if (ios /= 0) exit
         if (index(line, '>a</text>') > 0 .or. index(line, '>b</text>') > 0) n = n + 1_I4P
         k = index(line, '<text x="')
         if (k > 0 .and. index(line, '>1</text>') > 0 .and. index(line, 'text-anchor="end"') > 0) &
            read(line(k + 9:index(line(k + 9:), '"') + k + 7), *) xs(1)
         if (k > 0 .and. index(line, '>30</text>') > 0 .and. index(line, 'text-anchor="end"') > 0) &
            read(line(k + 9:index(line(k + 9:), '"') + k + 7), *) xs(2)
      enddo
      close(unit, status='delete')
      ! the label on two lines; the 30 entries in more than one column
      test_passed(221) = n == 2_I4P .and. xs(2) > xs(1)
   endblock
endif

! fidelity to gnuplot 6.0's renders: fc colors a filled item's border (over lc), a boxplot's whiskers in the border
! color, the key sample samplen + a tick, a boxed key's title line, parallel axes over their values, named by explicit
! titles only, lc variable 0 gray, a palette color box, no frame without a border
call interpreter%init(scratch)
call interpreter%run_text('set output "foresight_script_test_fid.svg"; set style fill solid 0.5 border; '// &
                          'set key box title "T" samplen 1; plot x with filledcurves fc "brown" lc "blue"', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(222) = iostat == 0_I4P
if (test_passed(222)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(222) = panel%series(1)%style%border_color == '#a52a2a' .and. panel%gnuplot_key
   endassociate
endif
call interpreter%init(scratch)
call interpreter%run_text('$P << EOD'//new_line('a')//'2 30 0'//new_line('a')//'5 40 1'//new_line('a')//'EOD'// &
                          new_line('a')//'set output "foresight_script_test_fid.svg"; unset border; '// &
                          'set style data parallelaxes; set paxis 1 range [0:10]; set paxis 1 tics; '// &
                          'plot $P using 1:3 lc variable, "" using 2 title "second"', iostat, iomsg)
test_passed(222) = test_passed(222) .and. iostat == 0_I4P
if (test_passed(222)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(222) = panel%series(1)%title_auto .and. .not. panel%series(2)%title_auto .and. &
                        allocated(panel%series(1)%colors)
      if (test_passed(222)) test_passed(222) = trim(panel%series(1)%colors(1)) == '#808080'
   endassociate
   block
      character(len=1000) :: line   !< SVG line.
      integer(I4P)        :: ios    !< Read status.
      logical             :: frame  !< A frame rectangle.
      logical             :: ten    !< The tick 10 (beyond the values of axis 1).

      frame = .false.
      ten = .false.
      open(newunit=unit, file='foresight_script_test_fid.svg')
      do
         read(unit, '(A)', iostat=ios) line
         if (ios /= 0) exit
         if (index(line, '<rect') > 0 .and. index(line, 'fill="none"') > 0) frame = .true.
         if (index(line, '>10</text>') > 0) ten = .true.
      enddo
      close(unit, status='delete')
      test_passed(222) = test_passed(222) .and. .not. frame .and. .not. ten
   endblock
endif

! fidelity to gnuplot 6.0's renders: column-stacked histograms with lc variable colors and their titles under the
! stacks, a multiplot title on several lines, enhanced data labels, an ellipse's extent in the autoscale, pointinterval
! -N (the sign kept, the line blanked under the points), lt -1 solid
call interpreter%init(scratch)
call interpreter%run_text('$S1 << EOD'//new_line('a')//'A 15'//new_line('a')//'B 21'//new_line('a')//'EOD'// &
                          new_line('a')//'set style data histogram; set style histogram columns; '// &
                          'set linetype 101 lc "red"; set linetype 102 lc "blue"; '// &
                          'plot $S1 using 2:(100 + strstrt("AB", strcol(1))) lc variable title "First"', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(223) = iostat == 0_I4P
if (test_passed(223)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(223) = allocated(panel%series(1)%colors) .and. allocated(panel%series(1)%xlabels)
      if (test_passed(223)) test_passed(223) = trim(panel%series(1)%colors(1)) == '#ff0000' .and. &
                                             trim(panel%series(1)%colors(2)) == '#0000ff' .and. &
                                             trim(panel%series(1)%xlabels(1)) == 'First'
   endassociate
endif
call interpreter%init(scratch)
call interpreter%run_text('$E << EOD'//new_line('a')//'0 10 10 6 90'//new_line('a')//'EOD'//new_line('a')// &
                          'set output "foresight_script_test_fid6.svg"; set multiplot layout 1,2 title "M1\nM2"; '// &
                          'plot $E using 1:2:3:4:5 with ellipses; plot sin(x) lt -1 pi -4 with lp, '// &
                          '$E using 1:2:("{/=8 Small}") with labels', iostat, iomsg)
test_passed(223) = test_passed(223) .and. iostat == 0_I4P
if (test_passed(223)) then
   associate(panel => interpreter%figure%panels(1))
      ! the ellipse 10 tall (turned by 90 degrees) about y = 10: the y range reaches 15
      test_passed(223) = panel%yaxis%hi >= 15.0_R8P
   endassociate
   associate(panel => interpreter%figure%panels(2))
      test_passed(223) = test_passed(223) .and. panel%series(1)%pointinterval == -4_I4P
   endassociate
   call interpreter%run_text('unset multiplot', iostat, iomsg)
   block
      character(len=1000) :: line  !< SVG line.
      integer(I4P)        :: ios   !< Read status.
      integer(I4P)        :: n     !< Findings.

      n = 0_I4P
      open(newunit=unit, file='foresight_script_test_fid6.svg')
      do
         read(unit, '(A)', iostat=ios) line
         if (ios /= 0) exit
         if (index(line, '>M1</text>') > 0 .or. index(line, '>M2</text>') > 0) n = n + 1_I4P
         if (index(line, 'font-size="8">Small') > 0) n = n + 1_I4P
         if (index(line, 'stroke-dasharray') > 0 .and. index(line, 'fs-series') > 0) n = n - 10_I4P
      enddo
      close(unit, status='delete')
      test_passed(223) = test_passed(223) .and. n == 3_I4P
   endblock
endif

! fidelity to gnuplot 6.0's renders: set title with options alone keeps its text (windrose's `set title offset 0,-2`),
! the polar grid in the grid's line (`set grid polar lt -1 lw .5`: black, solid)
call interpreter%init(scratch)
call interpreter%run_text('set output "foresight_script_test_fid7.svg"; set title "TTT"; set title offset 0,-2; '// &
                          'set polar; set grid polar lt -1 lw 0.5; plot 1', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(224) = iostat == 0_I4P
if (test_passed(224)) then
   block
      character(len=1000) :: line  !< SVG line.
      integer(I4P)        :: ios   !< Read status.
      logical             :: title !< The title written.
      logical             :: black !< A black grid line.
      logical             :: dots  !< A dotted grid line.

      title = .false.
      black = .false.
      dots = .false.
      open(newunit=unit, file='foresight_script_test_fid7.svg')
      do
         read(unit, '(A)', iostat=ios) line
         if (ios /= 0) exit
         if (index(line, '>TTT</text>') > 0) title = .true.
         if (index(line, 'stroke="black" stroke-width="0.5"') > 0) black = .true.
         if (index(line, 'stroke="#a0a0a0"') > 0 .and. index(line, 'dasharray') > 0) dots = .true.
      enddo
      close(unit, status='delete')
      test_passed(224) = title .and. black .and. .not. dots
   endblock
endif


! set rlabel (gnuplot 6.0): over the middle of the radial axis, 2 character heights above its tick labels; titles at
! beginning|end with left|right, polar plots too (solar_path)
call interpreter%init(scratch)
call interpreter%run_text('set output "foresight_script_test_rlabel.svg"; set polar; set rrange [0:2]; set rtics 0.5; '// &
                          'unset xtics; unset ytics; set size square; set rlabel "RLAB"; '// &
                          "plot '+' using 1:1 w l title 'BEG' at beg left, '+' using 1:1 w l title 'END' at end right", &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(225) = iostat == 0_I4P
if (test_passed(225)) then
   block
      character(len=1000) :: line   !< SVG line.
      integer(I4P)        :: ios    !< Read status.
      logical             :: label  !< The r label, centred.
      logical             :: beg    !< BEG left-justified (start).
      logical             :: fin    !< END right-justified (end).

      label = .false.
      beg = .false.
      fin = .false.
      open(newunit=unit, file='foresight_script_test_rlabel.svg')
      do
         read(unit, '(A)', iostat=ios) line
         if (ios /= 0) exit
         if (index(line, 'text-anchor="middle">RLAB</text>') > 0) label = .true.
         if (index(line, '>BEG</text>') > 0 .and. index(line, 'text-anchor') == 0) beg = .true.
         if (index(line, 'text-anchor="end">END</text>') > 0) fin = .true.
      enddo
      close(unit, status='delete')
      test_passed(225) = label .and. beg .and. fin
   endblock
endif
call interpreter%run_text('unset rlabel', iostat, iomsg)
test_passed(225) = test_passed(225) .and. iostat == 0_I4P .and. &
                  len(interpreter%figure%panels(1)%raxis%label) == 0


! hull filters (gnuplot 6.0 convexhull, expand, concavehull, delaunay; values from gnuplot's set table) and the forms of
! their demos: set chi_shape fraction, GPVAL_CHI_LENGTH, +CHI_SHAPES, real("+Inf"), set tics INCR, set isotropic,
! key offset in screen units
call interpreter%init(scratch)
call interpreter%run_text('$T << EOD'//new_line('a')//'0 0'//new_line('a')//'2 -1'//new_line('a')//'5 0'// &
                          new_line('a')//'3 4'//new_line('a')//'-1 2'//new_line('a')//'1 1'//new_line('a')//'5 4'// &
                          new_line('a')//'EOD'//new_line('a')//'$S << EOD'//new_line('a')//'0 0'//new_line('a')// &
                          '4 0'//new_line('a')//'4 3'//new_line('a')//'0 3'//new_line('a')//'2 1'//new_line('a')// &
                          '1 2'//new_line('a')//'EOD'//new_line('a')//'$C << EOD'//new_line('a')//'0 0'// &
                          new_line('a')//'4 0'//new_line('a')//'8 0'//new_line('a')//'8 4'//new_line('a')//'8 8'// &
                          new_line('a')//'4 8'//new_line('a')//'0 8'//new_line('a')//'0 4'//new_line('a')//'4 4.5'// &
                          new_line('a')//'3 7'//new_line('a')//'5 7'//new_line('a')//'EOD', iostat, iomsg)
call interpreter%run_text('plot $T convexhull w l, $S convexhull expand 1 w l, $C concavehull w l, $C delaunay w l', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(226) = iostat == 0_I4P
if (test_passed(226)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(226) = matches(series(1)%x, [-1, 3, 5, 5, 2, 0, -1]) .and. matches(series(1)%y, [2, 4, 4, 0, -1, 0, 2])
      test_passed(226) = test_passed(226) .and. matches(series(2)%x, [0, -1, -1, 0, 4, 5, 5, 4, 0, -1]) .and. &
                        matches(series(2)%y, [-1, 0, 3, 4, 4, 3, 0, -1, -1, 0])
      test_passed(226) = test_passed(226) .and. matches(series(3)%x, [4, 5, 8, 8, 8, 4, 0, 0, 0, 3, 4]) .and. &
                        matches(series(3)%y, [8, 7, 8, 4, 0, 0, 0, 4, 8, 7, 8]) .and. size(series(4)%x) == 60
   endassociate
endif
call interpreter%run_text('chi_length = 3.5; plot $C concavehull w l', iostat, iomsg)
test_passed(226) = test_passed(226) .and. iostat == 0_I4P
if (test_passed(226)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(226) = matches(series(1)%x, [0, 3, 4, 5, 8, 8, 8, 4, 0, 0, 0]) .and. &
                        matches(series(1)%y, [8, 7, 8, 7, 8, 4, 0, 0, 0, 4, 8])
   endassociate
endif
! an integer chi_length is not read (gnuplot reads a real one only): the default, 0.6 of the longest hull edge
call interpreter%run_text('chi_length = 5; set chi_shape fraction 0.3; plot $C concavehull w l; '// &
                          'v = GPVAL_CHI_LENGTH; w = real("+Inf"); z = real("-inf"); '// &
                          'u = strstrt(GPVAL_COMPILE_OPTIONS, "+CHI_SHAPES")', iostat, iomsg)
test_passed(226) = test_passed(226) .and. iostat == 0_I4P
if (test_passed(226)) then
   block
      real(R8P) :: v, w, z, u !< Values read back.
      logical   :: found      !< Defined.

      call interpreter%symbols%value_of('v', v, found)
      call interpreter%symbols%value_of('w', w, found)
      call interpreter%symbols%value_of('z', z, found)
      call interpreter%symbols%value_of('u', u, found)
      test_passed(226) = abs(v - 1.2_R8P) < 1.0e-12_R8P .and. w > huge(1.0_R8P) .and. z < -huge(1.0_R8P) .and. &
                        u > 0.0_R8P
   endblock
endif
call interpreter%run_text('set tics 0.5; set isotropic; set key offset screen -0.3, -.2', iostat, iomsg)
test_passed(226) = test_passed(226) .and. iostat == 0_I4P
if (test_passed(226)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(226) = panel%xaxis%tics%mode == TICS_FIXED .and. panel%yaxis%tics%mode == TICS_FIXED .and. &
                        panel%ratio == -1.0_R8P .and. all(panel%key_offset_unit == 1_I4P) .and. &
                        all(near(panel%key_offset, [-0.3_R8P, -0.2_R8P]))
   endassociate
endif
call interpreter%run_text('unset isotropic', iostat, iomsg)
test_passed(226) = test_passed(226) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%ratio == 0.0_R8P


! fidelity to gnuplot 6.0 (solar_path, chi_shapes): polar lines clipped at the end of the r range, the curve ending on
! the rim; `set ttics add` alone draws its own labels, -90 at 270; titles at the end on several lines; a later
! `set title "text"` keeps noenhanced
call interpreter%init(scratch)
call interpreter%run_text('set output "foresight_script_test_rim.svg"; set polar; set size square; unset xtics; '// &
                          'unset ytics; set border polar; set rrange [0:1]; set samples 50; '// &
                          "set ttics add ('N' 0, 'W' -90); set title noenhanced offset 0,-2; set title 'a_b'; "// &
                          'plot 0.5+t/4 lw 2 title "one"."\n"."two" at end', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(227) = iostat == 0_I4P .and. interpreter%figure%panels(1)%title_plain
if (test_passed(227)) then
   block
      character(len=20000)   :: line   !< SVG line.
      real(R8P), allocatable :: uv(:)  !< Polyline coordinates.
      integer(I4P)           :: ios    !< Read status.
      integer(I4P)           :: k      !< Position.
      integer(I4P)           :: n      !< Coordinates.
      logical                :: rim    !< The curve within the rim, its end on it.
      logical                :: labels !< N and W, no automatic 45.
      logical                :: rows   !< The title on two rows.

      rim = .false.
      labels = .true.
      n = 0_I4P
      rows = .false.
      open(newunit=unit, file='foresight_script_test_rim.svg')
      do
         read(unit, '(A)', iostat=ios) line
         if (ios /= 0) exit
         if (index(line, '<polyline') > 0 .and. index(line, 'stroke-width="2"') > 0) then
            k = index(line, 'points="') + 8
            line = line(k:)
            ! the points wrap over several lines, up to the closing quote
            do while (index(line, '"') == 0)
               block
                  character(len=4000) :: more !< Next line.

                  read(unit, '(A)', iostat=ios) more
                  if (ios /= 0) exit
                  line = trim(line)//' '//trim(more)
               endblock
            enddo
            if (index(line, '"') > 0) line = line(1:index(line, '"') - 1)
            do k = 1, len_trim(line)
               if (line(k:k) == ',') line(k:k) = ' '
            enddo
            n = (count([(line(k:k) == ' ', k = 1, len_trim(line))]) + 1) / 2
            allocate(uv(2 * n))
            read(line, *) uv
            ! unit coordinates: the pole at (0.5, 0.5), the rim 0.5 away
            rim = all(hypot(uv(1::2) - 0.5_R8P, uv(2::2) - 0.5_R8P) <= 0.5_R8P + 1.0e-5_R8P) .and. &
                  abs(hypot(uv(2 * n - 1) - 0.5_R8P, uv(2 * n) - 0.5_R8P) - 0.5_R8P) < 1.0e-5_R8P
         endif
         if (index(line, '>45</text>') > 0) labels = .false.
         if (index(line, '>two</text>') > 0) rows = .true.
      enddo
      close(unit)
      open(newunit=unit, file='foresight_script_test_rim.svg')
      k = 0_I4P
      do
         read(unit, '(A)', iostat=ios) line
         if (ios /= 0) exit
         if (index(line, '>N</text>') > 0 .or. index(line, '>W</text>') > 0) k = k + 1_I4P
      enddo
      close(unit, status='delete')
      test_passed(227) = rim .and. labels .and. rows .and. k == 2_I4P .and. n > 10_I4P
   endblock
endif


! gnuplot's string escapes (parse_esc): octal bytes (up to 4 digits after a 0, else 3), \r, \U+ kept for the enhanced
! text (there the character of that code point), another character as it is; set encoding iso_8859_1: the bytes
! written in UTF-8 (enhancedtext.dem's "\362" and "\245")
call interpreter%init(scratch)
call interpreter%run_text('a = "[\101\1010\0101\7\q\"\\]"; b = "\U+2192"; c = strlen("\362")', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(228) = iostat == 0_I4P
if (test_passed(228)) then
   block
      type(value_object) :: v      !< Value read back.
      real(R8P)          :: n      !< strlen.
      logical            :: found  !< Defined.

      call interpreter%symbols%get('a', v, found)
      test_passed(228) = found .and. v%s == '[A'//'A0'//'A'//achar(7)//'q"\]'
      call interpreter%symbols%get('b', v, found)
      test_passed(228) = test_passed(228) .and. found .and. v%s == '\U+2192'
      call interpreter%symbols%value_of('c', n, found)
      test_passed(228) = test_passed(228) .and. n == 1.0_R8P
   endblock
endif
call interpreter%run_text('set output "foresight_script_test_latin1.svg"; set encoding iso_8859_1; '// &
                          'set label 1 "x\362y" at 0,0; set label 2 "p\U+2192q" at 0,0.5; plot x', iostat, iomsg)
test_passed(228) = test_passed(228) .and. iostat == 0_I4P
if (test_passed(228)) then
   block
      character(len=1000) :: line   !< SVG line.
      integer(I4P)        :: ios    !< Read status.
      logical             :: latin1 !< x, o grave (U+00F2 in UTF-8), y.
      logical             :: arrow  !< p, U+2192 in UTF-8, q.

      latin1 = .false.
      arrow = .false.
      open(newunit=unit, file='foresight_script_test_latin1.svg')
      do
         read(unit, '(A)', iostat=ios) line
         if (ios /= 0) exit
         if (index(line, '>x'//achar(195)//achar(178)//'y<') > 0) latin1 = .true.
         if (index(line, '>p'//achar(226)//achar(134)//achar(146)//'q<') > 0) arrow = .true.
      enddo
      close(unit, status='delete')
      test_passed(228) = latin1 .and. arrow
   endblock
endif
call interpreter%run_text('set encoding default', iostat, iomsg)
test_passed(228) = test_passed(228) .and. iostat == 0_I4P .and. .not. interpreter%figure%latin1


! set polar grid and with surface (gnuplot 6.0, polargrid.dem): theta:r:z weighted onto the polar grid, each cell a
! polygon in the palette color of its value (the gray levels of gnuplot 6.0's svg for these points); the grid's
! settings, its theta wedge, unset polar grid; set grid on a polar panel (rings and spokes at the theta ticks);
! set ttics START,STEP,END; set rrange noextend; unset style fill
call interpreter%init(scratch)
call interpreter%run_text('set output "foresight_script_test_pgrid.svg"; set angles degrees; '// &
                          'set polar grid 6,2 gauss scale 1; set palette gray; set cbrange [0:10]'//new_line('a')// &
                          '$P << EOD'//new_line('a')//'0 1 2'//new_line('a')//'90 1.5 8'//new_line('a')// &
                          '200 0.5 5'//new_line('a')//'300 2 1'//new_line('a')//'EOD'//new_line('a')// &
                          'plot $P using 1:2:3 with surface title "s"', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(229) = iostat == 0_I4P
if (test_passed(229)) then
   associate(panel => interpreter%figure%panels(1), grid => interpreter%polar_grid)
      test_passed(229) = panel%polar .and. grid%theta_segments == 6_I4P .and. grid%r_segments == 2_I4P .and. &
                        grid%mode == 2_I4P .and. panel%series(1)%style%with == WITH_POLYGONS .and. &
                        panel%series(1)%key_mid_palette .and. size(panel%series(1)%x) == 64
   endassociate
   block
      character(len=1000) :: line   !< SVG line.
      integer(I4P)        :: ios    !< Read status.
      integer(I4P)        :: k      !< Position.
      integer(I4P)        :: n      !< Cells.
      integer(I4P)        :: g(12)  !< Their gray levels.
      integer(I4P)        :: tmp    !< Swap.
      integer(I4P)        :: a, b   !< Counters.

      n = 0_I4P
      g = 0_I4P
      open(newunit=unit, file='foresight_script_test_pgrid.svg')
      do
         read(unit, '(A)', iostat=ios) line
         if (ios /= 0) exit
         k = index(line, '<path fill="#')
         if (k == 0 .or. index(line, 'stroke="none" vector-effect') == 0) cycle
         n = n + 1_I4P
         if (n <= 12_I4P) read(line(k + 13:k + 14), '(Z2)') g(n)
      enddo
      close(unit, status='delete')
      do a = 1, 11
         do b = a + 1, 12
            if (g(b) < g(a)) then
               tmp = g(a)
               g(a) = g(b)
               g(b) = tmp
            endif
         enddo
      enddo
      test_passed(229) = test_passed(229) .and. n == 12_I4P .and. &
                        all(g == [75, 79, 114, 115, 130, 137, 156, 160, 165, 169, 183, 216])
   endblock
endif
! the theta wedge: cells starting in it, clamped to its end
call interpreter%run_text('set polar grid theta [0:90] qnorm 2 kdensity; plot $P using 1:2:3 with surface', &
                          iostat, iomsg)
test_passed(229) = test_passed(229) .and. iostat == 0_I4P
if (test_passed(229)) then
   associate(panel => interpreter%figure%panels(1), grid => interpreter%polar_grid)
      test_passed(229) = size(panel%series(1)%x) == 24 .and. grid%mode == 1_I4P .and. grid%norm_q == 2_I4P .and. &
                        grid%kdensity .and. grid%tmax == 90.0_R8P
   endassociate
endif
call interpreter%run_text('unset polar grid; set polar; set ttics 0,30,330; set grid; set rrange [*:*] noextend; '// &
                          'set style fill solid; unset style fill', iostat, iomsg)
test_passed(229) = test_passed(229) .and. iostat == 0_I4P
if (test_passed(229)) then
   associate(panel => interpreter%figure%panels(1), grid => interpreter%polar_grid)
      test_passed(229) = grid%theta_segments == 24_I4P .and. grid%tmax == 360.0_R8P .and. panel%raxis%noextend .and. &
                        panel%ttics%mode == TICS_FIXED .and. panel%fill_default%fill == FILL_EMPTY
   endassociate
endif
call interpreter%run_text('plot $P using 1:2 with points', iostat, iomsg)
test_passed(229) = test_passed(229) .and. iostat == 0_I4P
call interpreter%run_text('unset polar', iostat, iomsg)
test_passed(229) = test_passed(229) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%ttics%mode == TICS_NONE
call interpreter%run_text('plot $P using 1:2:3 with surface', iostat, iomsg)
test_passed(229) = test_passed(229) .and. iostat /= 0_I4P .and. index(iomsg, 'set polar') > 0


! gnuplot binary arrays (probably_tux, nonlinear3): 'file' binary array=(W,H) format='%uchar' flipy dx= origin=, the
! fields of each pixel then its x:y, the item's using after them
block
   integer :: k !< Byte.

   open(newunit=unit, file='foresight_script_test_binary.rgb', access='stream', form='unformatted', status='replace')
   write(unit) [(achar(k), k = 10, 21)]
   close(unit)
endblock
call interpreter%init(scratch)
call interpreter%run_text("plot 'foresight_script_test_binary.rgb' binary array=(2,2) format='%uchar' with rgbimage", &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(230) = iostat == 0_I4P
if (test_passed(230)) then
   associate(series => interpreter%figure%panels(1)%series(1))
      ! pixel (1,1) the first 3 bytes, (2,1) the next, the second scan line above
      test_passed(230) = allocated(series%channels) .and. size(series%grid, 1) == 2 .and. size(series%grid, 2) == 2
      if (test_passed(230)) test_passed(230) = all(nint(series%channels(1:3, 1, 1)) == [10, 11, 12]) .and. &
                                              all(nint(series%channels(1:3, 2, 1)) == [13, 14, 15]) .and. &
                                              all(nint(series%channels(1:3, 1, 2)) == [16, 17, 18])
   endassociate
endif
call interpreter%run_text("plot 'foresight_script_test_binary.rgb' binary array=(2,2) flipy dx=2 origin=(10,0) "// &
                          "format='%uchar%uchar%uchar' using ($1+$2+$3) with image", iostat, iomsg)
test_passed(230) = test_passed(230) .and. iostat == 0_I4P
if (test_passed(230)) then
   associate(series => interpreter%figure%panels(1)%series(1))
      ! flipy: the first scan line on top; dx=2 from x=10
      test_passed(230) = size(series%grid, 1) == 2 .and. size(series%grid, 2) == 2
      if (test_passed(230)) test_passed(230) = nint(series%grid(1, 2)) == 33 .and. nint(series%grid(1, 1)) == 51 .and. &
                                              minval(series%x) <= 10.0_R8P .and. maxval(series%x) >= 12.0_R8P
   endassociate
endif
call interpreter%run_text("plot 'foresight_script_test_binary.rgb' binary filetype=png with rgbimage", iostat, iomsg)
test_passed(230) = test_passed(230) .and. iostat /= 0_I4P .and. index(iomsg, 'filetype') > 0
open(newunit=unit, file='foresight_script_test_binary.rgb')
close(unit, status='delete')


! ps variable (each point's size from the column after the style's), with labels hypertext (the texts on mouse-over of
! their points, a transparent disk with its title, none drawn), the points of labels in the item's lc (gnuplot 6.0)
call interpreter%init(scratch)
call interpreter%run_text('set output "foresight_script_test_hyper.svg"'//new_line('a')//'$C << EOD'//new_line('a')// &
                          '1 1 Lyon 2'//new_line('a')//'2 3 Nice 0.5'//new_line('a')//'EOD'//new_line('a')// &
                          "plot $C using 1:2:3:4 with labels hypertext point pt 7 ps var lc rgb '#ffee99', "// &
                          "$C using 1:2:4 with points pt 6 ps variable lc rgb 'black'", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(231) = iostat == 0_I4P
if (test_passed(231)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(231) = series(1)%hypertext .and. allocated(series(1)%point_sizes) .and. &
                        allocated(series(2)%point_sizes) .and. allocated(series(1)%point_color)
      if (test_passed(231)) test_passed(231) = all(series(2)%point_sizes == [2.0_R8P, 0.5_R8P]) .and. &
                                              series(1)%point_color == '#ffee99'
   endassociate
   block
      character(len=1000) :: line  !< SVG line.
      integer(I4P)        :: ios   !< Read status.
      integer(I4P)        :: tips  !< Tooltips.
      logical             :: text  !< A label drawn.
      logical             :: big   !< The size 2 point (18 px).

      tips = 0_I4P
      text = .false.
      big = .false.
      open(newunit=unit, file='foresight_script_test_hyper.svg')
      do
         read(unit, '(A)', iostat=ios) line
         if (ios /= 0) exit
         if (index(line, 'class="fs-hover"') > 0 .and. index(line, '<title>Lyon</title>') > 0) tips = tips + 1_I4P
         if (index(line, 'class="fs-hover"') > 0 .and. index(line, '<title>Nice</title>') > 0) tips = tips + 1_I4P
         if (index(line, '>Lyon</text>') > 0) text = .true.
         if (index(line, 'data-pt="6" data-size="18"') > 0) big = .true.
      enddo
      close(unit, status='delete')
      test_passed(231) = test_passed(231) .and. tips == 2_I4P .and. .not. text .and. big
   endblock
endif


! zsort (gnuplot 6.0): the points of each block drawn in the order of their z (third column, stably, the lowest first),
! the z column dropped; smooth zsort the same
call interpreter%init(scratch)
call interpreter%run_text('$Z << EOD'//new_line('a')//'1 1 3'//new_line('a')//'2 2 1'//new_line('a')//'3 3 2'// &
                          new_line('a')//'4 4 1'//new_line('a')//''//new_line('a')//'5 5 9'//new_line('a')//'6 6 0'// &
                          new_line('a')//'EOD'//new_line('a')//'plot $Z using 1:2:3 zsort with points, '// &
                          '$Z using 1:2:3:3 smooth zsort with points lc palette', iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(232) = iostat == 0_I4P
if (test_passed(232)) then
   associate(series => interpreter%figure%panels(1)%series)
      ! the first block 2, 4 (z 1, in their order), 3, 1; the second 6, 5; the blank line kept between them
      test_passed(232) = same(series(1)%x, [2, 4, 3, 1, -1, 6, 5]) .and. same(series(2)%x, [2, 4, 3, 1, -1, 6, 5]) &
                        .and. allocated(series(2)%zvalues)
      if (test_passed(232)) test_passed(232) = same(series(2)%zvalues, [1, 1, 2, 3, -1, 0, 9])
   endassociate
endif


! fidelity to gnuplot 6.0 (round 10 demos): set xlabel with options alone keeps its text (matrix_every); a fill border
! lc bgnd the background (windrose); key invert mirrors the rows, each entry in its column (histograms); a missing cell
! read through column(i) leaves that point out only (histograms); noauto boxplots still widen x (boxplot); ellipses
! autoscale as gnuplot (half the larger diameter, 1.4 on y); group titles below rotated tick labels
call interpreter%init(scratch)
call interpreter%run_text('set xlabel "sub"; set xlabel offset 0,1.5 boxed; set style fill solid border lc bgnd', &
                          iostat, iomsg)
test_passed(233) = iostat == 0_I4P
if (test_passed(233)) then
   associate(panel => interpreter%figure%panels(1))
      test_passed(233) = panel%xaxis%label == 'sub' .and. panel%fill_default%border_color == 'white'
   endassociate
endif
call interpreter%run_text('set datafile missing "-"'//new_line('a')//'$M << EOD'//new_line('a')//'1 2 -'// &
                          new_line('a')//'2 3 4'//new_line('a')//'EOD'//new_line('a')//'i = 2'//new_line('a')// &
                          'plot $M using 1:(column(i)) with points, $M using 1:3 with points', iostat, iomsg)
test_passed(233) = test_passed(233) .and. iostat == 0_I4P
if (test_passed(233)) then
   associate(series => interpreter%figure%panels(1)%series)
      ! column(2) is never missing: both points; column 3 is missing in the first row: one point
      test_passed(233) = size(series(1)%x) == 2 .and. size(series(2)%x) == 1
   endassociate
endif
! (a boxplot needs 4 points at least: gnuplot 6.0 draws none of 3)
call interpreter%run_text('unset datafile; set style data boxplot'//new_line('a')//'$B << EOD'//new_line('a')// &
                          '1'//new_line('a')//'2'//new_line('a')//'3'//new_line('a')//'4'//new_line('a')//'5'// &
                          new_line('a')//'EOD'//new_line('a')// &
                          'plot $B using (1):1, $B using (4):($1*100) noauto', iostat, iomsg)
test_passed(233) = test_passed(233) .and. iostat == 0_I4P
if (test_passed(233)) then
   block
      real(R8P) :: xmin(2), xmax(2), ymin(2), ymax(2) !< Extent.
      logical   :: found(2), xfound(2)                 !< Points found.

      call interpreter%figure%panels(1)%axes_extent(xmin, xmax, ymin, ymax, found, xfound)
      ! the noauto box at x 4 counts for x, its values (100-300) not for y
      test_passed(233) = xmax(1) >= 4.0_R8P .and. ymax(1) < 10.0_R8P
   endblock
endif
call interpreter%run_text('set style data lines'//new_line('a')//'$E << EOD'//new_line('a')//'0 10 10 6 60'// &
                          new_line('a')//'EOD'//new_line('a')//'plot $E using 1:2:3:4:5 with ellipses', iostat, iomsg)
test_passed(233) = test_passed(233) .and. iostat == 0_I4P
if (test_passed(233)) then
   block
      real(R8P) :: xmin(2), xmax(2), ymin(2), ymax(2) !< Extent.
      logical   :: found(2), xfound(2)                 !< Points found.

      call interpreter%figure%panels(1)%axes_extent(xmin, xmax, ymin, ymax, found, xfound)
      test_passed(233) = abs(xmax(1) - 5.0_R8P) < 1.0e-9_R8P .and. abs(ymax(1) - 17.0_R8P) < 1.0e-9_R8P
   endblock
endif
! a two-column key inverted, and histogram group titles under rotated tick labels: rendered
call interpreter%run_text('set output "foresight_script_test_fid10.svg"; set key invert maxrows 2; '// &
                          'set style data histograms; set xtics rotate by -45'//new_line('a')//'$H << EOD'// &
                          new_line('a')//'a 1 2 3'//new_line('a')//'b 2 3 4'//new_line('a')//'EOD'//new_line('a')// &
                          'plot newhistogram "G", $H using 2:xtic(1) t "one", "" using 3 t "two", "" using 4 t "three"', &
                          iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(233) = test_passed(233) .and. iostat == 0_I4P
if (test_passed(233)) then
   block
      character(len=1000) :: line   !< SVG line.
      integer(I4P)        :: ios    !< Read status.
      real(R8P)           :: y(3)   !< Title baselines.
      integer(I4P)        :: k      !< Position.

      y = -1.0_R8P
      open(newunit=unit, file='foresight_script_test_fid10.svg')
      do
         read(unit, '(A)', iostat=ios) line
         if (ios /= 0) exit
         k = index(line, ' y="')
         if (k == 0) cycle
         if (index(line, '>one</text>') > 0) read(line(k + 4:index(line(k + 4:), '"') + k + 2), *) y(1)
         if (index(line, '>two</text>') > 0) read(line(k + 4:index(line(k + 4:), '"') + k + 2), *) y(2)
         if (index(line, '>three</text>') > 0) read(line(k + 4:index(line(k + 4:), '"') + k + 2), *) y(3)
      enddo
      close(unit, status='delete')
      ! two rows, two columns: one and two in the first column mirrored (two above one), three in the second at the
      ! bottom row
      test_passed(233) = all(y > 0.0_R8P) .and. y(2) < y(1) .and. abs(y(3) - y(1)) < 1.0e-6_R8P
   endblock
endif

! an autoscaled linear color axis extended to its ticks, as gnuplot 6.0 (data 0.13..0.87: 0.1..0.9), images included;
! noextend and set autoscale cbfix keep the data (a log one is never extended, check 79)
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '0 0 0.13', '1 0 0.5', '', '0 1 0.6', '1 1 0.87'
close(unit)
test_passed(234) = colorbox_labels("", ['0.1', '0.9'], ['1.0'])
associate(panel => interpreter%figure%panels(1))
   test_passed(234) = test_passed(234) .and. abs(panel%cbaxis%lo - 0.1_R8P) < 1.0e-12_R8P .and. &
                     abs(panel%cbaxis%hi - 0.9_R8P) < 1.0e-12_R8P
endassociate
test_passed(234) = test_passed(234) .and. colorbox_labels("set cbrange [*:*] noextend", ['0.2'], ['0.1'])
associate(panel => interpreter%figure%panels(1))
   test_passed(234) = test_passed(234) .and. panel%cbaxis%lo == 0.13_R8P .and. panel%cbaxis%hi == 0.87_R8P
endassociate
test_passed(234) = test_passed(234) .and. colorbox_labels("set autoscale cbfix", ['0.2'], ['0.1'])
associate(panel => interpreter%figure%panels(1))
   test_passed(234) = test_passed(234) .and. panel%cbaxis%lo == 0.13_R8P .and. panel%cbaxis%hi == 0.87_R8P
endassociate

! time functions, as gnuplot 6.0 (identical on 4000 days and 36 years of week dates): tm_sec ... tm_yday (tm_mon and
! tm_yday from 0), tm_week ISO and CDC, weekdate_iso and weekdate_cdc (day 1 when omitted, 0 as 1)
call interpreter%init(scratch)
call interpreter%run_text("set print 'foresight_script_test_print.txt'; t = 1700000000.75; "// &
                          "print tm_sec(t), tm_min(t), tm_hour(t), tm_mday(t), tm_mon(t), tm_year(t), tm_wday(t), "// &
                          "tm_yday(t), tm_week(t, 0), tm_week(t, 1); "// &
                          "print strftime('%Y-%m-%d', weekdate_iso(2004, 1)), strftime('%Y-%m-%d', weekdate_iso(2009, 1, 2)), "// &
                          "strftime('%Y-%m-%d', weekdate_cdc(2021, 1)), strftime('%Y-%m-%d', weekdate_cdc(2022, 52, 7)); "// &
                          "print tm_week(strptime('%Y-%m-%d', '2021-01-01'), 0), tm_week(-86400*3, 0), "// &
                          "weekdate_iso(2020, 53, 0), tm_sec(-0.5); set print", iostat, iomsg)
test_passed(235) = iostat == 0_I4P .and. &
                  file_is('foresight_script_test_print.txt', &
                          [character(len=50) :: '20.0 13.0 22.0 14.0 10.0 2023.0 2.0 317.0 46 46', &
                           '2003-12-29 2008-12-30 2021-01-03 2022-12-31', '53 1 1609113600.0 59.0'])
call interpreter%run_text("x = weekdate_iso(2020, 54)", iostat, iomsg)
test_passed(235) = test_passed(235) .and. iostat /= 0_I4P

! back objects in data space over the polar grid and the zero axes, as gnuplot 6.0 (windrose.dem: its centre disk
! covers the spokes)
call interpreter%init(scratch)
call interpreter%run_text("set terminal svg; set output 'foresight_script_test_layers.svg'; set polar; "// &
                          "set grid polar; set xzeroaxis; set object 1 circle at 0,0 radius 0.2 fs solid fc 'white'; "// &
                          "plot 1 notitle", iostat, iomsg)
test_passed(236) = iostat == 0_I4P
if (test_passed(236)) then
   block
      character(len=:), allocatable :: svg !< Rendered SVG.

      svg = read_text('foresight_script_test_layers.svg')
      test_passed(236) = index(svg, 'fs-pgrid') > 0 .and. index(svg, 'fs-objects') > index(svg, 'fs-pgrid') .and. &
                        index(svg, 'fs-objects') < index(svg, 'fs-series')
   endblock
endif

! an x label offset down widens the bottom margin, up narrows it, as gnuplot's boundary (histograms.dem: the key under
! the plot below its offset label)
block
   character(len=:), allocatable :: svg     !< Rendered SVG.
   real(R8P)                     :: tall(3) !< Plot area heights: no offset, offset down, offset up.
   integer(I4P)                  :: k       !< Case counter.
   integer(I4P)                  :: at      !< Position in the SVG.
   character(len=12)             :: offsets(3) = [character(len=12) :: '0,0', '0,-2', '0,1']

   test_passed(237) = .true.
   do k = 1_I4P, 3_I4P
      call interpreter%init(scratch)
      call interpreter%run_text("set terminal svg; set output 'foresight_script_test_offset.svg'; "// &
                                "set xlabel 'x' offset "//trim(offsets(k))//"; plot x notitle", iostat, iomsg)
      test_passed(237) = test_passed(237) .and. iostat == 0_I4P
      if (.not. test_passed(237)) exit
      svg = read_text('foresight_script_test_offset.svg')
      at = index(svg, 'class="fs-plot"')
      at = at + index(svg(at:), 'height="') + 7
      read(svg(at:at + index(svg(at:), '"') - 2), *) tall(k)
   enddo
   if (test_passed(237)) test_passed(237) = tall(2) < tall(1) .and. tall(3) > tall(1)
endblock

! the cells of a polar gridded surface with crisp edges, no seams between them, as gnuplot's svg; other polygons not
call interpreter%init(scratch)
call interpreter%run_text("set terminal svg; set output 'foresight_script_test_crisp.svg'; set polar"// &
                          new_line('a')//"$P << EOD"//new_line('a')//"0 1 1"//new_line('a')//"90 2 2"//new_line('a')//"180 1 3"// &
                          new_line('a')//"270 2 4"//new_line('a')//"EOD"//new_line('a')// &
                          "plot $P using 1:2:3 with surface notitle", iostat, iomsg)
test_passed(238) = iostat == 0_I4P
if (test_passed(238)) test_passed(238) = index(read_text('foresight_script_test_crisp.svg'), &
                                              '<g class="fs-crisp" shape-rendering="crispEdges">') > 0
call interpreter%init(scratch)
call interpreter%run_text("set terminal svg; set output 'foresight_script_test_crisp.svg'"// &
                          new_line('a')//"$Q << EOD"//new_line('a')//"0 0"//new_line('a')//"1 0"//new_line('a')//"1 1"// &
                          new_line('a')//"EOD"//new_line('a')//"plot $Q with polygons notitle", iostat, iomsg)
test_passed(238) = test_passed(238) .and. iostat == 0_I4P
if (test_passed(238)) test_passed(238) = index(read_text('foresight_script_test_crisp.svg'), 'crispEdges') == 0

! a datablock started after other commands on its line (`set polar; $P << EOD`), as gnuplot 6.0: the commands run
! first; a `;` inside quotes does not split
call interpreter%init(scratch)
call interpreter%run_text("a = 'x;y'; set polar; $P << EOD"//new_line('a')//"0 1"//new_line('a')//"90 2"// &
                          new_line('a')//"EOD"//new_line('a')//"n = |$P|; m = strlen(a)", iostat, iomsg)
test_passed(239) = iostat == 0_I4P .and. interpreter%figure%panels(1)%polar
if (test_passed(239)) then
   block
      real(R8P) :: v     !< Value.
      logical   :: found !< Defined.

      call interpreter%symbols%value_of('n', v, found)
      test_passed(239) = found .and. v == 2.0_R8P
      call interpreter%symbols%value_of('m', v, found)
      test_passed(239) = test_passed(239) .and. found .and. v == 3.0_R8P
   endblock
endif

! set pixmap, as gnuplot 6.0: a PNG file at a position (its lower left corner, or its centre), its own pixels large,
! or a size, or a width (the height by its aspect); the svg an <image> of the file; unset pixmap N; a file not PNG
block
   integer(I4P), parameter :: PNG(71) = [137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 2, 0, &
                                         0, 0, 1, 8, 2, 0, 0, 0, 123, 64, 232, 221, 0, 0, 0, 14, 73, 68, 65, 84, 120, &
                                         156, 99, 248, 207, 192, 0, 66, 255, 1, 15, 249, 3, 253, 133, 17, 153, 118, 0, &
                                         0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130] !< A 2 x 1 PNG.
   character(len=:), allocatable :: svg !< Rendered SVG.
   integer(I4P)                  :: k   !< Byte counter.

   open(newunit=unit, file='foresight_script_test_pixmap.png', access='stream', form='unformatted', status='replace')
   write(unit) [(achar(PNG(k)), k = 1, 71)]
   close(unit)
   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_pixmap.svg'; "// &
                             "set pixmap 1 'foresight_script_test_pixmap.png' at screen 0.1, 0.1 width screen 0.2 back; "// &
                             "set pixmap 2 'foresight_script_test_pixmap.png' at screen 0.5, 0.5 center; "// &
                             "set pixmap 3 'foresight_script_test_pixmap.png' at screen 0, 0 size screen 0.1, 0.05; "// &
                             "unset pixmap 3; plot x", iostat, iomsg)
   test_passed(240) = iostat == 0_I4P
   if (test_passed(240)) then
      svg = read_text('foresight_script_test_pixmap.svg')
      ! 1: 120 px wide, 60 high (the aspect 2:1), its lower left at (60, 360); 2: 2 x 1 px about the page centre
      test_passed(240) = index(svg, '<image x="60" y="300" width="120" height="60"') > 0 .and. &
                        index(svg, '<image x="299" y="199.5" width="2" height="1"') > 0 .and. &
                        index(svg, 'height="20"') == 0 .and. index(svg, 'data:image/png;base64,iVBORw0KGgo') > 0
   endif
   call interpreter%run_text("set pixmap 4 'foresight_script_test_pixmap.svg'", iostat, iomsg)
   test_passed(240) = test_passed(240) .and. iostat /= 0_I4P .and. index(iomsg, 'not a PNG file') > 0
   call interpreter%run_text("set pixmap 'foresight_script_test_pixmap.png'", iostat, iomsg)
   test_passed(240) = test_passed(240) .and. iostat /= 0_I4P .and. index(iomsg, 'a pixmap number is expected') > 0
endblock

! an undefined variable in an operand run only if a condition holds, as gnuplot 6.0 (`exists("Q") && Q == 27`, the
! mouse demos' idiom): read when run, an error only if reached; elsewhere an error when compiled
call interpreter%init(scratch)
call interpreter%run_text("a = exists('QQ') && QQ == 27; b = !exists('QQ') || QQ == 1; c = exists('QQ') ? QQ : -1; "// &
                          "QQ = 5; d = exists('QQ') && QQ == 5", iostat, iomsg)
test_passed(241) = iostat == 0_I4P
if (test_passed(241)) then
   block
      real(R8P) :: v(4)     !< Values.
      logical   :: found(4) !< Defined.

      call interpreter%symbols%value_of('a', v(1), found(1))
      call interpreter%symbols%value_of('b', v(2), found(2))
      call interpreter%symbols%value_of('c', v(3), found(3))
      call interpreter%symbols%value_of('d', v(4), found(4))
      test_passed(241) = all(found) .and. all(v == [0.0_R8P, 1.0_R8P, -1.0_R8P, 1.0_R8P])
   endblock
endif
call interpreter%run_text("e = 1 ? RR : 2", iostat, iomsg)
test_passed(241) = test_passed(241) .and. iostat /= 0_I4P .and. index(iomsg, 'undefined variable') > 0
call interpreter%run_text("e = RR + 1", iostat, iomsg)
test_passed(241) = test_passed(241) .and. iostat /= 0_I4P .and. index(iomsg, 'undefined variable: RR') > 0

! fonts per element, as gnuplot 6.0's svg: "family:Bold:Italic,size" (font files and mbfont sets no family); the title,
! axis labels, key, labels, data labels, color box label, multiplot title in their fonts; set terminal font the page's
block
   character(len=:), allocatable :: svg  !< Rendered SVG.
   type(font_object)             :: f(5) !< Parsed fonts.

   f(1) = font_of(',8')
   f(2) = font_of(':Bold')
   f(3) = font_of('Times:Italic,10')
   f(4) = font_of('/usr/share/fonts/a.ttf,11')
   f(5) = font_of('mbfont:sazanami mincho,vera,20')
   test_passed(242) = f(1)%size == 8.0_R8P .and. len_trim(f(1)%family) == 0 .and. .not. f(1)%bold .and. &
                     f(2)%bold .and. f(2)%size == 0.0_R8P .and. len_trim(f(2)%family) == 0 .and. &
                     f(3)%italic .and. f(3)%family == 'Times' .and. f(3)%size == 10.0_R8P .and. &
                     len_trim(f(4)%family) == 0 .and. f(4)%size == 11.0_R8P .and. len_trim(f(5)%family) == 0
   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400 font 'Georgia,11'; "// &
                             "set output 'foresight_script_test_fonts.svg'; set title 'T' font ',20'; "// &
                             "set xlabel 'X' font 'serif,15'; set ylabel 'Y' font ':Bold'; set key font ':Bold,14'; "// &
                             "set label 1 'L' at 0,0 font 'Times:Bold,14'; set cblabel 'C' font ',9'; "// &
                             "plot x title 'c', '+' using 1:1:('d') with labels font ':Italic' notitle", iostat, iomsg)
   test_passed(242) = test_passed(242) .and. iostat == 0_I4P
   if (test_passed(242)) then
      svg = read_text('foresight_script_test_fonts.svg')
      test_passed(242) = index(svg, 'font-family="Georgia,') > 0 .and. index(svg, 'font-size="11"') > 0 .and. &
                        index(svg, 'font-size="20" text-anchor="middle">T<') > 0 .and. &
                        index(svg, 'font-size="15" font-family="serif" text-anchor="middle">X<') > 0 .and. &
                        index(svg, 'font-weight="bold" text-anchor="middle" transform="rotate(-90') > 0 .and. &
                        index(svg, 'font-size="14" font-weight="bold" text-anchor="end">c<') > 0 .and. &
                        index(svg, 'font-size="14" font-family="Times" font-weight="bold"') > 0 .and. &
                        index(svg, 'font-style="italic">d<') > 0
   endif
   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_fonts.svg'; "// &
                             "set multiplot layout 2,1 title 'M' font ',18'; plot x; plot x; unset multiplot", &
                             iostat, iomsg)
   test_passed(242) = test_passed(242) .and. iostat == 0_I4P
   if (test_passed(242)) test_passed(242) = index(read_text('foresight_script_test_fonts.svg'), &
                                                 'font-size="18" text-anchor="middle">M<') > 0
   call interpreter%run_text("set title 'T' font", iostat, iomsg)
   test_passed(242) = test_passed(242) .and. iostat /= 0_I4P .and. index(iomsg, 'font needs') > 0
endblock

! fonts of the theta labels (set ttics font), the timestamp and the histogram group titles, as gnuplot 6.0
call interpreter%init(scratch)
call interpreter%run_text("set terminal svg; set output 'foresight_script_test_fonts2.svg'; set polar; "// &
                          "set ttics 0, 90 font ',7'; set timestamp font ':Italic'; plot 1 notitle", iostat, iomsg)
test_passed(243) = iostat == 0_I4P
if (test_passed(243)) test_passed(243) = interpreter%figure%panels(1)%ttics%font%size == 7.0_R8P .and. &
                                       index(read_text('foresight_script_test_fonts2.svg'), 'font-size="7"') > 0 .and. &
                                       index(read_text('foresight_script_test_fonts2.svg'), 'font-style="italic"') > 0
call interpreter%init(scratch)
call interpreter%run_text("set terminal svg; set output 'foresight_script_test_fonts2.svg'"//new_line('a')// &
                          "$H << EOD"//new_line('a')//"a 1"//new_line('a')//"b 2"//new_line('a')//"EOD"// &
                          new_line('a')//"set style data histograms; set style histogram clustered title font ',9'"// &
                          new_line('a')//"plot newhistogram 'G', $H using 2:xtic(1) notitle", iostat, iomsg)
test_passed(243) = test_passed(243) .and. iostat == 0_I4P
if (test_passed(243)) test_passed(243) = index(read_text('foresight_script_test_fonts2.svg'), &
                                              'font-size="9" text-anchor="middle">G<') > 0


! splot data as gnuplot 6.0 tabulates them: a function's grid iso-curves, data scans last first, one column (point and
! scan numbers), a matrix, a surface per dataset, set format z and the out-of-range flag
block
   character(len=:), allocatable :: tab !< Table text.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   call interpreter%init(scratch)
   call interpreter%run_text("set table 'foresight_script_test.dat'; set isosamples 3,2; set samples 4,5; "// &
                             "splot x*y; unset table", iostat, iomsg)
   test_passed(244) = iostat == 0_I4P
   tab = read_text('foresight_script_test.dat')
   test_passed(244) = test_passed(244) .and. tab == nl//'# Surface 0 of 1 surfaces'//nl//nl//'# Curve title: "x*y"'// &
                     nl//nl//'# IsoCurve 0, 4 points'//nl//'# x y z type'//nl//'-10 -10  100 i'//nl// &
                     '-3.33333 -10  33.3333 i'//nl//' 3.33333 -10 -33.3333 i'//nl//' 10 -10 -100 i'//nl//nl// &
                     '# IsoCurve 1, 4 points'//nl//'# x y z type'//nl//'-10  10 -100 i'//nl// &
                     '-3.33333  10 -33.3333 i'//nl//' 3.33333  10  33.3333 i'//nl//' 10  10  100 i'//nl//nl
   ! the second set of iso-curves (x fixed) is drawn, not tabulated
   test_passed(244) = test_passed(244) .and. size(interpreter%figure%panels(1)%series(1)%scans, 2) == 5 .and. &
                     interpreter%figure%panels(1)%series(1)%grid_scans == 2
   call interpreter%init(scratch)
   call interpreter%run_text("set table 'foresight_script_test.dat'"//nl//"$d << EOD"//nl//"1 1 1"//nl//"2 1 2"//nl// &
                             nl//"1 2 3"//nl//"2 2 4"//nl//nl//nl//"5 5 5"//nl//"EOD"//nl//"set format z '%.2f'; "// &
                             "set zrange [0:4.5]; splot $d using 1:2:3, $d index 0 every 1:1:0:1 notitle; "// &
                             "unset table", iostat, iomsg)
   test_passed(244) = test_passed(244) .and. iostat == 0_I4P
   tab = read_text('foresight_script_test.dat')
   test_passed(244) = test_passed(244) .and. tab == nl//'# Surface 0 of 3 surfaces'//nl//nl// &
                     '# Curve title: "$d using 1:2:3"'//nl//nl//'# IsoCurve 0, 2 points'//nl//'# x y z type'//nl// &
                     ' 1  2 3.00 i'//nl//' 2  2 4.00 i'//nl//nl//'# IsoCurve 1, 2 points'//nl//'# x y z type'//nl// &
                     ' 1  1 1.00 i'//nl//' 2  1 2.00 i'//nl//nl//nl//'# Surface 1 of 3 surfaces'//nl//nl// &
                     '# IsoCurve 0, 1 points'//nl//'# x y z type'//nl//' 5  5 5.00 o'//nl//nl//nl// &
                     '# Surface 2 of 3 surfaces'//nl//nl//'# IsoCurve 0, 2 points'//nl//'# x y z type'//nl// &
                     ' 1  2 3.00 i'//nl//' 2  2 4.00 i'//nl//nl
   call interpreter%init(scratch)
   call interpreter%run_text("set table 'foresight_script_test.dat'"//nl//"$m << EOD"//nl//"1 2 3"//nl//"4 5 6"//nl// &
                             "EOD"//nl//"$c << EOD"//nl//"5"//nl//"6"//nl//nl//"7"//nl//"EOD"//nl// &
                             "splot $m matrix using 1:2:($3*2) with lines, $c; unset table", iostat, iomsg)
   test_passed(244) = test_passed(244) .and. iostat == 0_I4P
   tab = read_text('foresight_script_test.dat')
   test_passed(244) = test_passed(244) .and. index(tab, '# Curve title: "$m matrix using 1:2:($3*2)"') > 0 .and. &
                     index(tab, ' 0  1  8 i'//nl//' 1  1  10 i'//nl//' 2  1  12 i') > 0 .and. &
                     index(tab, '# Curve title: "$c"'//nl//nl//'# IsoCurve 0, 1 points'//nl//'# x y z type'//nl// &
                           ' 0  1  7 i'//nl//nl//'# IsoCurve 1, 2 points'//nl//'# x y z type'//nl//' 0  0  5 i'//nl// &
                           ' 1  0  6 i') > 0
   ! the automatic title of a 2D item holds its data options, as gnuplot's
   call interpreter%init(scratch)
   call interpreter%run_text("set table 'foresight_script_test.dat'"//nl//"$d << EOD"//nl//"1 1"//nl//nl//nl//"2 2"// &
                             nl//"EOD"//nl//"plot $d i 1 u 1:2; unset table", iostat, iomsg)
   test_passed(244) = test_passed(244) .and. iostat == 0_I4P .and. &
                     index(read_text('foresight_script_test.dat'), '# Curve title: "$d i 1 u 1:2"') > 0
endblock


! splot's settings: set view (rot_x, rot_z, scales, map, equal, azimuth), set xyplane and ticslevel, the z axis,
! isosamples and samples (both values), surface; their unset; the errors
call interpreter%init(scratch)
call interpreter%run_text("set view 70, , 1.5, 2; set xyplane at -1; set zrange [0:5]; set zlabel 'Z' offset 1,2; "// &
                          "set ztics 0.5; set mztics 2; set isosamples 3,4; set samples 5,6; set zzeroaxis lt 1; "// &
                          "unset surface; set view azimuth 10; set view equal xyz", iostat, iomsg)
test_passed(245) = iostat == 0_I4P
associate(panel => interpreter%figure%panels(1))
   test_passed(245) = test_passed(245) .and. panel%view3d%rot_x == 70.0_R8P .and. panel%view3d%rot_z == 30.0_R8P .and. &
                     panel%view3d%scale == 1.5_R8P .and. panel%view3d%zscale == 2.0_R8P .and. panel%view3d%xyplane_at &
                     .and. panel%view3d%xyplane_z == -1.0_R8P .and. panel%zaxis%max_user == 5.0_R8P .and. &
                     panel%zaxis%label == 'Z' .and. panel%label_offset(1, 6) == 1.0_R8P .and. &
                     panel%zaxis%tics%minor == 2_I4P .and. .not. panel%view3d%surface .and. panel%view3d%zzeroaxis .and. &
                     panel%view3d%azimuth == 10.0_R8P .and. panel%view3d%equal == 2_I4P .and. .not. panel%view3d%map
endassociate
call interpreter%run_text("set view map scale 1.2; set ticslevel 0.3; unset zrange; unset zlabel; set surface", &
                          iostat, iomsg)
test_passed(245) = test_passed(245) .and. iostat == 0_I4P
associate(panel => interpreter%figure%panels(1))
   test_passed(245) = test_passed(245) .and. panel%view3d%map .and. panel%view3d%map_scale == 1.2_R8P .and. &
                     .not. panel%view3d%xyplane_at .and. panel%view3d%ticslevel == 0.3_R8P .and. &
                     .not. panel%zaxis%max_fixed .and. panel%zaxis%label == '' .and. panel%view3d%surface
endassociate
call interpreter%run_text("unset view", iostat, iomsg)
test_passed(245) = test_passed(245) .and. iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%view3d%map
! a 3D view is drawn (check 262)
call interpreter%run_text("splot x*y", iostat, iomsg)
test_passed(245) = test_passed(245) .and. iostat == 0_I4P
call interpreter%run_text("set view 400", iostat, iomsg)
test_passed(245) = test_passed(245) .and. iostat /= 0_I4P .and. index(iomsg, 'rot_x must be in [0:360]') > 0
call interpreter%run_text("set view map; splot [0:1] [0:1] [0:1] [0:1] x*y", iostat, iomsg)
test_passed(245) = test_passed(245) .and. iostat /= 0_I4P .and. index(iomsg, 'at most three inline ranges') > 0
call interpreter%run_text("set table 'foresight_script_test.dat'; splot '+' using 1:1 notitle; unset table", iostat, &
                          iomsg)
test_passed(245) = test_passed(245) .and. iostat /= 0_I4P .and. index(iomsg, 'using needs x:y:z') > 0
call interpreter%run_text("set table 'foresight_script_test.dat'; splot [-1:1] [0:2] [-5:5] x+y; unset table", iostat, &
                          iomsg)
test_passed(245) = test_passed(245) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%zaxis%plot_max == 5.0_R8P &
                  .and. interpreter%figure%panels(1)%series(1)%x(1) == -1.0_R8P .and. &
                  interpreter%figure%panels(1)%series(1)%y(1) == 0.0_R8P


! the library's splot: scattered points (one scan) and a grid (a scan per row, NaN breaks between), the z axis
block
   type(figure_object) :: fig !< Library figure.

   call fig%splot([1.0_R8P, 2.0_R8P], [3.0_R8P, 4.0_R8P], [5.0_R8P, 6.0_R8P], title='p')
   call fig%splot([0.0_R8P, 1.0_R8P, 2.0_R8P], [0.0_R8P, 1.0_R8P], &
                  reshape([1.0_R8P, 2.0_R8P, 3.0_R8P, 4.0_R8P, 5.0_R8P, 6.0_R8P], [3, 2]), with='lines')
   call fig%set_zrange(min=0.0_R8P, max=7.0_R8P)
   call fig%set_zlabel('height')
   call fig%set_ztics(step=2.0_R8P)
   associate(panel => fig%panels(1))
      test_passed(246) = panel%three_d .and. size(panel%series) == 2 .and. panel%series(1)%z(2) == 6.0_R8P .and. &
                        all(panel%series(1)%scans(:, 1) == [1, 2]) .and. size(panel%series(2)%x) == 7 .and. &
                        all(panel%series(2)%scans(:, 2) == [5, 7]) .and. panel%series(2)%z(6) == 5.0_R8P .and. &
                        panel%series(2)%y(5) == 1.0_R8P .and. ieee_is_nan(panel%series(2)%x(4)) .and. &
                        panel%series(2)%grid_scans == 2 .and. panel%zaxis%max_user == 7.0_R8P .and. &
                        panel%zaxis%label == 'height' .and. panel%series(1)%style%with == WITH_POINTS
   endassociate
endblock


! the map view (set view map) at gnuplot 6.0's places (probed on its svg): plot area, tick labels, axis labels, title,
! color box; a 2D matrix with using fields and labels; unset autoscale; "#RRGGBB" with a tail; object tags as
! expressions; fill as fillstyle
block
   character(len=:), allocatable :: svg !< Page.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_map.svg'; set view map; "// &
                             "set title 'Map title'; set xlabel 'X label'; set ylabel 'Y label'; set xrange [0:10]; "// &
                             "set yrange [0:5]"//nl//"$p << EOD"//nl//"1 1 0"//nl//"9 4 1"//nl//"EOD"//nl// &
                             "splot $p using 1:2:3 with points pt 7 lc palette title 'pts'", iostat, iomsg)
   test_passed(247) = iostat == 0_I4P
   if (test_passed(247)) then
      svg = read_text('foresight_script_test_map.svg')
      test_passed(247) = index(svg, '<rect x="71.61" y="73.8" width="401.92" height="252.4"') > 0 .and. &
                        index(svg, 'x="71.61" y="350.43" text-anchor="middle">0<') > 0 .and. &
                        index(svg, 'x="56.52" y="330.1" text-anchor="end">0<') > 0 .and. &
                        index(svg, 'x="272.57" y="377.43" text-anchor="middle">X label<') > 0 .and. &
                        index(svg, 'x="39.45" y="200" text-anchor="middle" transform="rotate(-90 39.45 200)">Y label<') &
                        > 0 .and. index(svg, 'x="272.57" y="50.7" text-anchor="middle">Map title<') > 0 .and. &
                        index(svg, '<rect x="491.97" y="73.8" width="20.1" height="252.4"') > 0 .and. &
                        index(svg, 'x="405.19" y="95.7" text-anchor="end">pts<') > 0
   endif
   ! a matrix through using, with image and with labels (gnuplot's heatmaps.dem)
   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg; set output 'foresight_script_test_map.svg'"//nl//"$m << EOD"//nl// &
                             "0 1"//nl//"2 0"//nl//"EOD"//nl//"plot $m matrix using 1:2:3 with image, $m matrix "// &
                             "using 1:2:($3 == 0 ? '' : sprintf('%g', $3)) with labels", iostat, iomsg)
   test_passed(247) = test_passed(247) .and. iostat == 0_I4P
   if (test_passed(247)) test_passed(247) = size(interpreter%figure%panels(1)%series) == 2 .and. &
                                         trim(interpreter%figure%panels(1)%series(2)%texts(4)) == '2'
   call interpreter%run_text("set xrange [1:4]; unset autoscale; set object 2*11 rect from 0,0 to 1,1 "// &
                             "fc rgb '#DDAA00 junk'", iostat, iomsg)
   test_passed(247) = test_passed(247) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%yaxis%max_fixed .and. &
                     interpreter%figure%panels(1)%xaxis%max_user == 4.0_R8P .and. &
                     interpreter%figure%panels(1)%objects(size(interpreter%figure%panels(1)%objects))%tag == 22
   call interpreter%run_text("plot '+' using 1:1 with boxes fill solid 0.5", iostat, iomsg)
   test_passed(247) = test_passed(247) .and. iostat == 0_I4P
endblock


! pm3d in the map view (gnuplot 6.0's colors, probed): the quadrangles of a 3 x 3 grid by their corners' mean, c1, and
! interpolated 2,2; implicit pm3d with the points over it; set pm3d options, map, unset pm3d; plot with pm3d refused
block
   character(len=:), allocatable :: svg  !< Page.
   character(len=:), allocatable :: grid !< The grid datablock.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   grid = "$g << EOD"//nl//"0 0 0"//nl//"1 0 1"//nl//"2 0 2"//nl//nl//"0 1 3"//nl//"1 1 4"//nl//"2 1 8"//nl//nl// &
          "0 2 6"//nl//"1 2 7"//nl//"2 2 9"//nl//"EOD"//nl
   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_pm3d.svg'; "// &
                             "set view map"//nl//grid//"splot $g using 1:2:3 with pm3d notitle", iostat, iomsg)
   test_passed(248) = iostat == 0_I4P
   if (test_passed(248)) then
      svg = read_text('foresight_script_test_pm3d.svg')
      test_passed(248) = index(svg, 'fill="#7803fb"') > 0 .and. index(svg, 'fill="#a5127f"') > 0 .and. &
                        index(svg, 'fill="#be2c00"') > 0 .and. index(svg, 'fill="#e17800"') > 0
   endif
   call interpreter%run_text("set pm3d corners2color c1; replot", iostat, iomsg)
   test_passed(248) = test_passed(248) .and. iostat == 0_I4P
   if (test_passed(248)) then
      svg = read_text('foresight_script_test_pm3d.svg')
      test_passed(248) = index(svg, 'fill="#5500a4"') > 0 .and. index(svg, 'fill="#9309dd"') > 0 .and. &
                        index(svg, 'fill="#aa1657"') > 0
   endif
   call interpreter%run_text("set pm3d interpolate 2,2 corners2color mean; replot", iostat, iomsg)
   test_passed(248) = test_passed(248) .and. iostat == 0_I4P
   if (test_passed(248)) then
      svg = read_text('foresight_script_test_pm3d.svg')
      test_passed(248) = index(svg, 'fill="#6801dd"') > 0 .and. index(svg, 'fill="#f2bc00"') > 0 .and. &
                        index(svg, 'fill="#cb4000"') > 0
   endif
   ! implicit: a surface drawn with pm3d and as itself (points over the quadrangles)
   call interpreter%run_text("set pm3d; splot $g using 1:2:3 title 'g'", iostat, iomsg)
   test_passed(248) = test_passed(248) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%pm3d%implicit
   if (test_passed(248)) then
      svg = read_text('foresight_script_test_pm3d.svg')
      test_passed(248) = index(svg, 'fill="#7803fb"') > 0 .and. index(svg, '<g class="fs-series" data-series="2">'// &
                         new_line('a')//'<polyline') > 0
   endif
   call interpreter%run_text("set pm3d map clip4in interpolate 0,-50", iostat, iomsg)
   associate(panel => interpreter%figure%panels(1))
      test_passed(248) = test_passed(248) .and. iostat == 0_I4P .and. panel%pm3d%at == 'b' .and. panel%view3d%map .and. &
                        panel%pm3d%clip4in .and. all(panel%pm3d%interp == [0, -50]) .and. &
                        interpreter%data_style == 'pm3d' .and. interpreter%function_style == 'pm3d'
   endassociate
   call interpreter%run_text("unset pm3d", iostat, iomsg)
   test_passed(248) = test_passed(248) .and. iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%pm3d%implicit .and. &
                     interpreter%data_style == 'lines' .and. interpreter%function_style == 'lines'
   call interpreter%run_text("plot x with pm3d", iostat, iomsg)
   test_passed(248) = test_passed(248) .and. iostat /= 0_I4P .and. index(iomsg, 'pm3d draws the surfaces of splot') > 0
   call interpreter%run_text("set pm3d corners2color avg", iostat, iomsg)
   test_passed(248) = test_passed(248) .and. iostat /= 0_I4P .and. index(iomsg, 'corners2color needs') > 0
endblock


! palettes and functions for pm3d demos: set palette gamma, model CMY, defined alone (gnuplot's default gradient), file
! gray:rgb with rgbcolor(), file '-'; parametric surfaces (u, v) as gnuplot tabulates them; unset parametric resets the
! dummy variables; set tics rotate
block
   character(len=1), parameter :: nl = new_line('a') !< New line.
   real(R8P)                   :: v     !< A value.
   logical                     :: found !< Variable found.

   call interpreter%init(scratch)
   call interpreter%run_text("set palette gray gamma 0.75", iostat, iomsg)
   test_passed(249) = iostat == 0_I4P .and. interpreter%figure%panels(1)%palette%gamma == 0.75_R8P .and. &
                     all(interpreter%figure%panels(1)%palette%rgb(0.5_R8P) == nint(255.0_R8P * 0.5_R8P**(1.0_R8P/0.75_R8P)))
   call interpreter%run_text("set palette color model CMY rgbformulae 7,5,15", iostat, iomsg)
   test_passed(249) = test_passed(249) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%palette%cmy .and. &
                     all(interpreter%figure%panels(1)%palette%rgb(0.0_R8P) == [255, 255, 255])
   call interpreter%run_text("set palette model RGB defined", iostat, iomsg)
   test_passed(249) = test_passed(249) .and. iostat == 0_I4P .and. &
                     all(interpreter%figure%panels(1)%palette%rgb(0.1_R8P) == [0, 0, 255])
   call interpreter%run_text("r = rgbcolor('red'); w = rgbcolor('white')", iostat, iomsg)
   call interpreter%symbols%value_of('r', v, found)
   test_passed(249) = test_passed(249) .and. iostat == 0_I4P .and. found .and. v == 16711680.0_R8P
   call interpreter%symbols%value_of('w', v, found)
   test_passed(249) = test_passed(249) .and. found .and. v == 16777215.0_R8P
   call interpreter%run_text("$C << EOD"//nl//"0 black"//nl//"1 red"//nl//"EOD"//nl// &
                             "set palette file $C using 1:(rgbcolor(strcol(2)))", iostat, iomsg)
   test_passed(249) = test_passed(249) .and. iostat == 0_I4P .and. &
                     all(interpreter%figure%panels(1)%palette%rgb(1.0_R8P) == [255, 0, 0])
   call interpreter%run_text("set palette file '-'"//nl//"0 0 1"//nl//"1 1 0"//nl//"e", iostat, iomsg)
   test_passed(249) = test_passed(249) .and. iostat == 0_I4P .and. &
                     all(interpreter%figure%panels(1)%palette%rgb(0.0_R8P) == [0, 0, 255])
   ! a parametric surface: x(u,v), y(u,v), z(u,v) on the u, v grid
   call interpreter%init(scratch)
   call interpreter%run_text("set table 'foresight_script_test.dat'; set parametric; set isosamples 2,2; "// &
                             "set samples 2,2; set urange [0:1]; set vrange [0:2]; splot u, v, u+v; unset table", &
                             iostat, iomsg)
   test_passed(249) = test_passed(249) .and. iostat == 0_I4P .and. read_text('foresight_script_test.dat') == nl// &
                     '# Surface 0 of 1 surfaces'//nl//nl//'# Curve title: "u, v, u+v"'//nl//nl// &
                     '# IsoCurve 0, 2 points'//nl//'# x y z type'//nl//' 0  0  0 i'//nl//' 1  0  1 i'//nl//nl// &
                     '# IsoCurve 1, 2 points'//nl//'# x y z type'//nl//' 0  2  2 i'//nl//' 1  2  3 i'//nl//nl
   call interpreter%run_text("set dummy u,v; unset parametric; set table 'foresight_script_test.dat'; plot x; "// &
                             "unset table", iostat, iomsg)
   test_passed(249) = test_passed(249) .and. iostat == 0_I4P
   call interpreter%run_text("set tics rotate by 45 nooffset", iostat, iomsg)
   test_passed(249) = test_passed(249) .and. iostat == 0_I4P .and. &
                     interpreter%figure%panels(1)%xaxis%tics%rotate == 45.0_R8P
endblock


! contours (a port of gnuplot 6.0's contour.c) as gnuplot tabulates them: discrete levels over the surface, auto levels
! without it, cubic spline, B-spline and incremental levels; the options, errors, nocontours
block
   character(len=:), allocatable :: tab !< Table.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   call interpreter%init(scratch)
   call interpreter%run_text("set table 'foresight_script_test.dat'; set contour base; set cntrparam levels discrete "// &
                             "0.5, 1.5; set isosamples 4,4; set samples 4,4; set xrange [0:3]; set yrange [0:3]; "// &
                             "splot x+y; unset table", iostat, iomsg)
   test_passed(250) = iostat == 0_I4P
   tab = read_text('foresight_script_test.dat')
   test_passed(250) = test_passed(250) .and. index(tab, ' 3  3  6 i'//nl//nl//nl//'# Contour 0, label:      1.5'//nl// &
                     ' 1.5  0  1.5 '//nl//' 1  0.5  1.5 '//nl//' 0.5  1  1.5 '//nl//' 0  1.5  1.5 '//nl//nl//nl// &
                     '# Contour 1, label:      0.5'//nl//' 0.5  0  0.5 '//nl//' 0  0.5  0.5 '//nl//nl) > 0
   call interpreter%run_text("set table 'foresight_script_test.dat'; unset surface; set cntrparam levels auto 5; "// &
                             "splot x*y; unset table", iostat, iomsg)
   test_passed(250) = test_passed(250) .and. iostat == 0_I4P .and. read_text('foresight_script_test.dat') == nl// &
                     '# Surface 0 of 1 surfaces'//nl//nl//'# Curve title: "x*y"'//nl//nl// &
                     '# Contour 0, label:        8'//nl//' 3  2.66667  8 '//nl//' 2.66667  3  8 '//nl//nl//nl// &
                     '# Contour 1, label:        6'//nl//' 3  2  6 '//nl//' 2  3  6 '//nl//nl//nl// &
                     '# Contour 2, label:        4'//nl//' 3  1.33333  4 '//nl//' 2  2  4 '//nl//' 1.33333  3  4 '// &
                     nl//nl//nl//'# Contour 3, label:        2'//nl//' 3  0.666667  2 '//nl//' 2  1  2 '//nl// &
                     ' 1  2  2 '//nl//' 0.666667  3  2 '//nl//nl
   call interpreter%init(scratch)
   call interpreter%run_text("set contour base; unset surface; set isosamples 6,6; set samples 6,6; "// &
                             "set xrange [-2:2]; set yrange [-2:2]; set cntrparam levels discrete 0.3, 0.6; "// &
                             "set table 'foresight_script_test.dat'; set cntrparam cubicspline points 4; "// &
                             "splot exp(-x**2-y**2); unset table", iostat, iomsg)
   tab = read_text('foresight_script_test.dat')
   test_passed(250) = test_passed(250) .and. iostat == 0_I4P .and. index(tab, '# Contour 0, label:      0.6'//nl// &
                     '-0.4 -0.592501  0.6 '//nl//'-0.505787 -0.508757  0.6 '//nl//'-0.590241 -0.403593  0.6 ') > 0
   call interpreter%run_text("set table 'foresight_script_test.dat'; set cntrparam bspline order 3 points 3; "// &
                             "splot exp(-x**2-y**2); unset table", iostat, iomsg)
   tab = read_text('foresight_script_test.dat')
   test_passed(250) = test_passed(250) .and. iostat == 0_I4P .and. index(tab, '# Contour 0, label:      0.6'//nl// &
                     '-0.496251 -0.496251  0.6 '//nl//'-0.549723 -0.398334  0.6 '//nl//'-0.581807 -0.232917  0.6 ') > 0
   call interpreter%run_text("set table 'foresight_script_test.dat'; set cntrparam linear levels incremental "// &
                             "0.1, 0.2, 0.9; splot exp(-x**2-y**2); unset table", iostat, iomsg)
   tab = read_text('foresight_script_test.dat')
   test_passed(250) = test_passed(250) .and. iostat == 0_I4P .and. index(tab, '# Contour 0, label:      0.7'//nl// &
                     '-0.4 -0.439903  0.7 '//nl//'-0.439903 -0.4  0.7 ') > 0 .and. &
                     interpreter%figure%panels(1)%contour%levels == 5
   ! options and errors
   call interpreter%run_text("set cntrlabel format '%.1f' onecolor; set contour both", iostat, iomsg)
   test_passed(250) = test_passed(250) .and. iostat == 0_I4P .and. &
                     interpreter%figure%panels(1)%contour%format == '%.1f' .and. &
                     interpreter%figure%panels(1)%contour%onecolor .and. interpreter%figure%panels(1)%contour%place == 'both'
   call interpreter%run_text("set cntrparam order 11", iostat, iomsg)
   test_passed(250) = test_passed(250) .and. iostat /= 0_I4P .and. index(iomsg, 'order must be in [2..10]') > 0
   call interpreter%run_text("set contour sideways", iostat, iomsg)
   test_passed(250) = test_passed(250) .and. iostat /= 0_I4P .and. index(iomsg, 'base, surface or both') > 0
   call interpreter%run_text("set table 'foresight_script_test.dat'; splot x*y nocontours; unset table", iostat, iomsg)
   test_passed(250) = test_passed(250) .and. iostat == 0_I4P .and. &
                     index(read_text('foresight_script_test.dat'), '# Contour') == 0
   call interpreter%run_text("unset contour", iostat, iomsg)
   test_passed(250) = test_passed(250) .and. iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%contour%on
endblock

! set dgrid3d (a port of gnuplot 6.0's grid_nongrid_data) as gnuplot tabulates it: qnorm 1 and 2, gauss, kdensity, thin
! plate splines, box (a node out of reach undefined); nogrid; with mask and the mask option of pm3d
block
   character(len=:), allocatable :: tab   !< Table.
   character(len=:), allocatable :: svg   !< Rendering.
   character(len=:), allocatable :: data  !< Scattered points.
   integer(I4P)                  :: whole !< Quadrangles unmasked.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   data = "$d << EOD"//nl//"0 0 1"//nl//"1 0.3 2"//nl//"0.4 1 3"//nl//"1.2 1.4 0.5"//nl//"0.7 0.6 2.5"//nl//"EOD"//nl
   call interpreter%init(scratch)
   call interpreter%run_text(data//"set dgrid3d 4,3; set table 'foresight_script_test.dat'; splot $d using 1:2:3; "// &
                             "unset table", iostat, iomsg)
   tab = read_text('foresight_script_test.dat')
   test_passed(251) = iostat == 0_I4P .and. index(tab, '# IsoCurve 0, 4 points'//nl//'# x y z type'//nl// &
                     ' 1.2  0  1.92421 i'//nl//' 1.2  0.466667  1.95642 i'//nl//' 1.2  0.933333  1.75134 i'//nl// &
                     ' 1.2  1.4  0.5 i') > 0 .and. index(tab, ' 0  0  1 i'//nl//' 0  0.466667  1.86131 i') > 0 .and. &
                     index(tab, '# IsoCurve 3') == 0
   call interpreter%run_text("set dgrid3d 4,3 qnorm 2; set table 'foresight_script_test.dat'; splot $d using 1:2:3; "// &
                             "unset table", iostat, iomsg)
   test_passed(251) = test_passed(251) .and. iostat == 0_I4P .and. index(read_text('foresight_script_test.dat'), &
                     ' 0  0.466667  1.80364 i'//nl//' 0  0.933333  2.47603 i') > 0
   call interpreter%run_text("set dgrid3d 3,4 gauss 0.5,0.7; set table 'foresight_script_test.dat'; "// &
                             "splot $d using 1:2:3; unset table", iostat, iomsg)
   test_passed(251) = test_passed(251) .and. iostat == 0_I4P .and. index(read_text('foresight_script_test.dat'), &
                     ' 1.2  0.7  1.78104 i') > 0
   call interpreter%run_text("set dgrid3d 3,3 gauss kdensity 0.5; set table 'foresight_script_test.dat'; "// &
                             "splot $d using 1:2:(1); unset table", iostat, iomsg)
   test_passed(251) = test_passed(251) .and. iostat == 0_I4P .and. index(read_text('foresight_script_test.dat'), &
                     ' 1.2  0  0.686642 i'//nl//' 1.2  0.7  0.99802 i'//nl//' 1.2  1.4  1.07594 i') > 0
   call interpreter%run_text("set dgrid3d 3,3 splines; set table 'foresight_script_test.dat'; "// &
                             "splot $d using 1:2:3; unset table", iostat, iomsg)
   test_passed(251) = test_passed(251) .and. iostat == 0_I4P .and. index(read_text('foresight_script_test.dat'), &
                     ' 1.2  0  1.42185 i'//nl//' 1.2  0.7  1.57401 i'//nl//' 1.2  1.4  0.5 i') > 0
   call interpreter%run_text("set dgrid3d 3,3 box 0.3; set table 'foresight_script_test.dat'; "// &
                             "splot $d using 1:2:3; unset table", iostat, iomsg)
   test_passed(251) = test_passed(251) .and. iostat == 0_I4P .and. index(read_text('foresight_script_test.dat'), &
                     ' 0.6  0.7  2.5 i'//nl//' 0.6  1.4  NaN u') > 0
   ! nogrid: the item's points as they are; unset dgrid3d
   call interpreter%run_text("set table 'foresight_script_test.dat'; splot $d using 1:2:3 nogrid; unset table", &
                             iostat, iomsg)
   test_passed(251) = test_passed(251) .and. iostat == 0_I4P .and. index(read_text('foresight_script_test.dat'), &
                     '# IsoCurve 0, 5 points') > 0
   call interpreter%run_text("set dgrid3d 1,3", iostat, iomsg)
   test_passed(251) = test_passed(251) .and. iostat /= 0_I4P
   call interpreter%run_text("set dgrid3d 3,3 sideways", iostat, iomsg)
   test_passed(251) = test_passed(251) .and. iostat /= 0_I4P .and. index(iomsg, 'unrecognized keyword') > 0
   call interpreter%run_text("unset dgrid3d", iostat, iomsg)
   test_passed(251) = test_passed(251) .and. iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%dgrid3d%on
   ! with mask: not drawn, its key entry a text alone; a pm3d item `mask` keeps the quadrangles inside its polygons
   call interpreter%init(scratch)
   call interpreter%run_text("$m << EOD"//nl//"-2 -2"//nl//"2 -2"//nl//"0 2"//nl//nl//"1.5 1.5"//nl//"2.5 1.5"//nl// &
                             "2.5 2.5"//nl//"EOD"//nl//"set terminal svg; set output 'foresight_script_test.svg'; "// &
                             "set view map; set isosamples 6,6; set xrange [-3:3]; set yrange [-3:3]; "// &
                             "splot x*y with pm3d", iostat, iomsg)
   whole = count_text(read_text('foresight_script_test.svg'), '<path')
   call interpreter%run_text("splot $m using 1:2:(0) with mask title 'mask', x*y mask with pm3d title 'surf'", &
                             iostat, iomsg)
   svg = read_text('foresight_script_test.svg')
   test_passed(251) = test_passed(251) .and. iostat == 0_I4P .and. whole > 0_I4P .and. &
                     count_text(svg, '<path') > 0_I4P .and. count_text(svg, '<path') < whole .and. &
                     index(svg, '>mask<') > 0 .and. index(svg, '>surf<') > 0
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(251) = test_passed(251) .and. series(1)%key_blank .and. .not. series(1)%masked .and. &
                        series(2)%masked
   endassociate
endblock

! pt variable: each point's type from a column (gnuplot's int(v), a dot for 0 and less), after the sizes of ps variable
! and before the colors of lc rgb variable; the key sample a dot
block
   character(len=:), allocatable :: svg  !< Rendering.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   call interpreter%init(scratch)
   call interpreter%run_text("$D << EOD"//nl//"1 1 0 2 0xee0000"//nl//"2 1 1 3 0x00dd00"//nl//"3 1 7.6 1 0x0000ee"// &
                             nl//"4 1 16 2 0xee00ee"//nl//"5 1 -2 1 0xddaa00"//nl//"EOD"//nl// &
                             "set terminal svg; set output 'foresight_script_test.svg'; "// &
                             "plot $D using 1:2:3 with points pt variable title 'v'", iostat, iomsg)
   svg = read_text('foresight_script_test.svg')
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(252) = iostat == 0_I4P .and. allocated(series(1)%point_types)
      if (test_passed(252)) test_passed(252) = all(series(1)%point_types == [0, 1, 7, 16, 0]) .and. &
                                                .not. allocated(series(1)%point_sizes)
   endassociate
   test_passed(252) = test_passed(252) .and. index(svg, 'data-pt="7"') > 0
   call interpreter%run_text("plot $D using 1:2:4:3:5 with points ps var pt var lc rgb var notitle", iostat, iomsg)
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(252) = test_passed(252) .and. iostat == 0_I4P .and. allocated(series(1)%point_types) .and. &
                        allocated(series(1)%point_sizes) .and. allocated(series(1)%colors)
      if (test_passed(252)) test_passed(252) = all(series(1)%point_types == [0, 1, 7, 16, 0]) .and. &
                                                all(series(1)%point_sizes == [2.0_R8P, 3.0_R8P, 1.0_R8P, 2.0_R8P, &
                                                                              1.0_R8P])
   endassociate
   call interpreter%run_text("plot $D using 1:2:(0.5):(1.5):3 with yerrorbars pt var notitle", iostat, iomsg)
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(252) = test_passed(252) .and. iostat == 0_I4P .and. allocated(series(1)%point_types)
   endassociate
   call interpreter%run_text("set view map; splot $D using 1:2:(0):3 with points pt var notitle", iostat, iomsg)
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(252) = test_passed(252) .and. iostat == 0_I4P .and. allocated(series(1)%point_types)
      if (test_passed(252)) test_passed(252) = all(series(1)%point_types == [0, 1, 7, 16, 0])
   endassociate
endblock

! set table writes a negative zero with its sign, as gnuplot's printf: `% h`, a width, a left-justified field
block
   character(len=1), parameter :: nl = new_line('a') !< New line.

   call interpreter%init(scratch)
   call interpreter%run_text("set table 'foresight_script_test.dat'; plot '+' using 1:(-1*0.0) every ::0::1; "// &
                             "unset table", iostat, iomsg)
   test_passed(253) = iostat == 0_I4P .and. read_text('foresight_script_test.dat') == nl// &
                     '# Curve 0 of 1, 2 points'//nl//'# Curve title: "''+'' using 1:(-1*0.0) every ::0::1"'//nl// &
                     '# x y type'//nl//'-10 -0  i'//nl//'-9.79798 -0  i'//nl//nl
   call interpreter%run_text("set format y '%8.3f'; set format x '%-6g|'; set table 'foresight_script_test.dat'; "// &
                             "plot '+' using (-1*0.0):(-1*0.0) every ::0::0; unset table", iostat, iomsg)
   test_passed(253) = test_passed(253) .and. iostat == 0_I4P .and. index(read_text('foresight_script_test.dat'), &
                     nl//'-0    |   -0.000  i'//nl) > 0
endblock

! a "-" within the string of another option (a title) is not the inline file of `set palette file '-'`
block
   character(len=1), parameter :: nl = new_line('a') !< New line.

   call interpreter%init(scratch)
   call interpreter%run_text("set title 'set palette file ""-"" (3 columns)'"//nl//"set palette file ""-"""//nl// &
                             "0 0 1"//nl//"1 1 0"//nl//"e", iostat, iomsg)
   test_passed(253) = test_passed(253) .and. iostat == 0_I4P .and. &
                     interpreter%figure%panels(1)%title == 'set palette file "-" (3 columns)' .and. &
                     all(interpreter%figure%panels(1)%palette%rgb(0.0_R8P) == [0, 0, 255])
endblock

! set palette defined alone: gnuplot 6.0's default gradient (color.c), 8 stops from dark blue to pink
block
   call interpreter%init(scratch)
   call interpreter%run_text("set palette defined", iostat, iomsg)
   test_passed(254) = iostat == 0_I4P .and. all(interpreter%figure%panels(1)%palette%rgb(0.1_R8P) == [0, 0, 255]) .and. &
                     all(interpreter%figure%panels(1)%palette%rgb(0.8_R8P) == [255, 0, 0]) .and. &
                     all(interpreter%figure%panels(1)%palette%rgb(1.0_R8P) == [255, 204, 204])
   ! set datafile columnheaders: the first row of a palette file is a header (pm3dcolors.dem)
   call interpreter%run_text("set datafile columnheaders"//new_line('a')// &
                             "set palette file '-' using ($0):1:2:(($1+$2)/2)"//new_line('a')//"0 0"// &
                             new_line('a')//"0 1"//new_line('a')//"1 0"//new_line('a')//"1 1"//new_line('a')//"e", &
                             iostat, iomsg)
   test_passed(254) = test_passed(254) .and. iostat == 0_I4P .and. &
                     all(interpreter%figure%panels(1)%palette%rgb(0.0_R8P) == [0, 255, 128]) .and. &
                     all(interpreter%figure%panels(1)%palette%rgb(1.0_R8P) == [255, 255, 255])
endblock

! gnuplot's default arrowhead (term.c do_arrow): barbs 0.3 of the shaft within 2.7 and 18 px, 15 degrees off it; a zero
! length shaft has no head; with vectors of gnuplot's svg sizes (probed: a 5.28 px shaft, barbs 2.6 px back, 0.69 px
! aside)
block
   real(R8P) :: barbs(2, 2) !< Barb ends [px].

   call arrow_head([0.0_R8P, 0.0_R8P], [5.28_R8P, 0.0_R8P], barbs)
   test_passed(255) = abs(barbs(1, 1) - (5.28_R8P - 2.7_R8P * cos(acos(-1.0_R8P) / 12.0_R8P))) < 1.0e-9_R8P .and. &
                      abs(abs(barbs(2, 1)) - 2.7_R8P * sin(acos(-1.0_R8P) / 12.0_R8P)) < 1.0e-9_R8P
   call arrow_head([0.0_R8P, 0.0_R8P], [30.0_R8P, 0.0_R8P], barbs)
   test_passed(255) = test_passed(255) .and. abs(norm2(barbs(:, 1) - [30.0_R8P, 0.0_R8P]) - 9.0_R8P) < 1.0e-9_R8P
   call arrow_head([0.0_R8P, 0.0_R8P], [0.0_R8P, 200.0_R8P], barbs)
   test_passed(255) = test_passed(255) .and. abs(norm2(barbs(:, 2) - [0.0_R8P, 200.0_R8P]) - 18.0_R8P) < 1.0e-9_R8P
   call arrow_head([3.0_R8P, 4.0_R8P], [3.0_R8P, 4.0_R8P], barbs)
   test_passed(255) = test_passed(255) .and. all(barbs(:, 1) == [3.0_R8P, 4.0_R8P]) .and. &
                      all(barbs(:, 2) == [3.0_R8P, 4.0_R8P])
endblock

! rotated y and y2 tick labels, as gnuplot 6.0: `rotate` upward and centred on the tick, `rotate by A` right-justified
! (y2: left), `set tics rotate` on the four axes; the margin grows to their reach
block
   character(len=:), allocatable :: svg !< Rendering.

   call interpreter%init(scratch)
   call interpreter%run_text("set ytics rotate; set y2tics rotate by 45; set y2range [0:10]; set terminal svg; "// &
                             "set output 'foresight_script_test.svg'; plot x", iostat, iomsg)
   svg = read_text('foresight_script_test.svg')
   associate(panel => interpreter%figure%panels(1))
      test_passed(256) = iostat == 0_I4P .and. panel%yaxis%tics%rotate == 90.0_R8P .and. &
                        panel%yaxis%tics%justify == 'center' .and. panel%y2axis%tics%rotate == 45.0_R8P .and. &
                        len_trim(panel%y2axis%tics%justify) == 0
   endassociate
   test_passed(256) = test_passed(256) .and. index(svg, 'text-anchor="middle" transform="rotate(-90') > 0 .and. &
                     index(svg, 'transform="rotate(-45') > 0
   call interpreter%run_text("set tics rotate by 30", iostat, iomsg)
   associate(panel => interpreter%figure%panels(1))
      test_passed(256) = test_passed(256) .and. iostat == 0_I4P .and. panel%yaxis%tics%rotate == 30.0_R8P .and. &
                        panel%xaxis%tics%rotate == 30.0_R8P .and. len_trim(panel%yaxis%tics%justify) == 0
   endassociate
   call interpreter%run_text("set tics rotate; set ytics norotate; set cbtics in", iostat, iomsg)
   associate(panel => interpreter%figure%panels(1))
      test_passed(256) = test_passed(256) .and. iostat == 0_I4P .and. panel%yaxis%tics%rotate == 0.0_R8P .and. &
                        panel%y2axis%tics%justify == 'center'
   endassociate
endblock

! sectors.dem's needs, as gnuplot 6.0: sectors colored per row (lc rgb variable, fc palette), about centres on a polar
! panel, units xx; vectors on a polar panel; hsv2rgb; fill style abbreviations; a layout after set size; reset of set
! size; a using field reading a variable a later field assigns (the previous row's value)
block
   character(len=1), parameter :: nl = new_line('a') !< New line.
   character(len=:), allocatable :: tab !< Table.

   call interpreter%init(scratch)
   call interpreter%run_text("$S << EOD"//nl//"0 1 90 1 1"//nl//"90 1 90 1 2"//nl//"EOD"//nl// &
                             "set angles degrees; plot $S using 1:2:3:4:(hsv2rgb($5/4.0,1,1)) with sectors "// &
                             "fc rgb variable fs solid bo lc 'black'", iostat, iomsg)
   test_passed(257) = iostat == 0_I4P
   if (test_passed(257)) test_passed(257) = size(interpreter%figure%panels(1)%series) == 1
   if (test_passed(257)) then
   associate(series => interpreter%figure%panels(1)%series)
      test_passed(257) = allocated(series(1)%colors) .and. allocated(series(1)%vertex_rows)
      if (test_passed(257)) test_passed(257) = series(1)%colors(1) == '#7fff00' .and. &
                                                series(1)%colors(size(series(1)%colors) - 1) == '#00ffff' .and. &
                                                series(1)%style%border
   endassociate
   endif
   call interpreter%run_text("plot $S using 1:2:3:4:5 with sectors units xx lc palette z", iostat, iomsg)
   test_passed(257) = test_passed(257) .and. iostat == 0_I4P
   if (test_passed(257)) then
      associate(series => interpreter%figure%panels(1)%series)
         test_passed(257) = series(1)%ellipse_units == 'xx' .and. allocated(series(1)%zvalues)
         if (test_passed(257)) test_passed(257) = series(1)%zvalues(1) == 1.0_R8P .and. &
                                                   series(1)%zvalues(size(series(1)%zvalues) - 1) == 2.0_R8P
      endassociate
   endif
   call interpreter%run_text("set polar; plot $S using 1:2:3:(0.5):(45):(3) with sectors, "// &
                             "$S using 1:2:(10):(1) with vectors", iostat, iomsg)
   test_passed(257) = test_passed(257) .and. iostat == 0_I4P
   call interpreter%run_text("print hsv2rgb(0, 1, 1)", iostat, iomsg)
   test_passed(257) = test_passed(257) .and. iostat == 0_I4P
   call interpreter%init(scratch)
   call interpreter%run_text("set size 0.5,0.5; set multiplot layout 1,2; plot x; plot x; unset multiplot", iostat, iomsg)
   test_passed(257) = test_passed(257) .and. iostat == 0_I4P .and. &
                     all(interpreter%figure%panels(1)%size == [0.5_R8P, 0.5_R8P])
   call interpreter%run_text("reset", iostat, iomsg)
   test_passed(257) = test_passed(257) .and. iostat == 0_I4P .and. all(interpreter%figure%panels(1)%size == 1.0_R8P)
   call interpreter%run_text("$data << EOD"//nl//"A 12"//nl//"B 20"//nl//"C 25"//nl//"EOD"//nl// &
                             "set table $T; plot r=0 $data using 2:(r):(dr=$2,r=r+dr,dr) with table; unset table; "// &
                             "set print 'foresight_script_test.dat'; print $T; unset print", iostat, iomsg)
   tab = read_text('foresight_script_test.dat')
   test_passed(257) = test_passed(257) .and. iostat == 0_I4P .and. index(tab, '20 '//achar(9)//' 12') > 0 .and. &
                     index(tab, '25 '//achar(9)//' 32') > 0
endblock

! gnuplot's sparse matrix=(C,R) [origin=(X0,Y0)] [dx= dy=]: the points binned to the nearest cell of a full grid, the
! others undefined; matrix rowheaders columnheaders: the names tick labels at the column and row numbers
block
   character(len=1), parameter   :: nl = new_line('a') !< New line.
   character(len=:), allocatable :: svg !< Rendering.

   call interpreter%init(scratch)
   call interpreter%run_text("$sp << EOD"//nl//"1 1 5"//nl//"3 2 7"//nl//"2.9 0.1 9"//nl//"EOD"//nl// &
                             "set terminal svg; set output 'foresight_script_test.svg'; "// &
                             "plot $sp sparse matrix=(3,3) origin=(1,0) dx=1 using 1:2:3 with image", iostat, iomsg)
   test_passed(258) = iostat == 0_I4P
   if (test_passed(258)) test_passed(258) = size(interpreter%figure%panels(1)%series) == 1
   if (test_passed(258)) then
      associate(series => interpreter%figure%panels(1)%series(1))
         test_passed(258) = allocated(series%grid)
         if (test_passed(258)) test_passed(258) = size(series%grid, 1) == 3 .and. size(series%grid, 2) == 3 .and. &
                                                series%grid(1, 2) == 5.0_R8P .and. series%grid(3, 3) == 7.0_R8P .and. &
                                                series%grid(3, 1) == 9.0_R8P .and. .not. series%grid(2, 2) == series%grid(2, 2)
      endassociate
   endif
   call interpreter%run_text("plot $sp sparse matrix=(0,3) using 1:2:3 with image", iostat, iomsg)
   test_passed(258) = test_passed(258) .and. iostat /= 0_I4P .and. index(iomsg, 'sparse matrix=(<cols>,<rows>)') > 0
   call interpreter%run_text("$h << EOD"//nl//",Apple,Bacon,Cream"//nl//"Row 1, 5, 4, 3"//nl//"Row 2, 2, 2, 0"//nl// &
                             "EOD"//nl//"set datafile separator comma; "// &
                             "plot $h matrix rowheaders columnheaders using 1:2:3 with image; set datafile separator", &
                             iostat, iomsg)
   svg = read_text('foresight_script_test.svg')
   test_passed(258) = test_passed(258) .and. iostat == 0_I4P .and. index(svg, '>Bacon<') > 0 .and. index(svg, '>Row 2<') > 0
   if (test_passed(258)) test_passed(258) = size(interpreter%figure%panels(1)%series) == 3
   if (test_passed(258)) test_passed(258) = interpreter%figure%panels(1)%series(1)%grid(2, 1) == 4.0_R8P .and. &
                                         interpreter%figure%panels(1)%series(2)%noautoscale
endblock

! binary images as gnuplot 6.0: center=(X,Y) moves the natural centre, rotation=A (d, pi, radians) turns the pixels
! about it (about the origin with origin=), off the right angles each pixel a polygon; %*type skips a field; dx alone
! sets dy; a using field starting with a parenthesis is read whole
block
   integer(I4P) :: u !< File unit.

   open(newunit=u, file='foresight_script_test.bin', access='stream', form='unformatted', status='replace')
   write(u) achar(10)//achar(20)//achar(30)//achar(40)//achar(50)//achar(60)
   close(u)
   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg; set output 'foresight_script_test.svg'; plot 'foresight_script_test.bin' "// &
                             "binary array=(3,2) center=( 10,20 ) format='%uchar' with image", iostat, iomsg)
   test_passed(259) = iostat == 0_I4P
   if (test_passed(259)) test_passed(259) = abs(interpreter%figure%panels(1)%series(1)%x(1) - 8.5_R8P) < 1.0e-9_R8P .and. &
                                         abs(interpreter%figure%panels(1)%series(1)%y(2) - 21.0_R8P) < 1.0e-9_R8P
   call interpreter%run_text("plot 'foresight_script_test.bin' binary array=(3,2) rotation=90d format='%uchar' with image", &
                             iostat, iomsg)
   test_passed(259) = test_passed(259) .and. iostat == 0_I4P
   if (test_passed(259)) test_passed(259) = size(interpreter%figure%panels(1)%series(1)%grid, 1) == 2 .and. &
                                         size(interpreter%figure%panels(1)%series(1)%grid, 2) == 3
   call interpreter%run_text("plot 'foresight_script_test.bin' binary array=(3,2) rot=0.25pi format='%uchar' "// &
                             "using ($1)*2 with image", iostat, iomsg)
   test_passed(259) = test_passed(259) .and. iostat == 0_I4P
   if (test_passed(259)) test_passed(259) = interpreter%figure%panels(1)%series(1)%style%with == WITH_POLYGONS
   call interpreter%run_text("plot 'foresight_script_test.bin' binary array=(3,1) format='%uchar%*uchar' with image", &
                             iostat, iomsg)
   test_passed(259) = test_passed(259) .and. iostat == 0_I4P
   if (test_passed(259)) test_passed(259) = all(interpreter%figure%panels(1)%series(1)%grid(:, 1) == [10, 30, 50])
   call interpreter%run_text("plot 'foresight_script_test.bin' binary array=(3,2) dx=2 format='%uchar' with image", &
                             iostat, iomsg)
   test_passed(259) = test_passed(259) .and. iostat == 0_I4P
   if (test_passed(259)) test_passed(259) = abs(interpreter%figure%panels(1)%series(1)%y(2) - 3.0_R8P) < 1.0e-9_R8P
   open(newunit=u, file='foresight_script_test.bin')
   close(u, status='delete')
endblock

! a sized arrowhead on a short arrow, as gnuplot's do_arrow: halved to half the shaft, its angle widened so the barbs
! spread as far (probed: a 15.86 px shaft, size 52.86 px at 20 degrees: barbs 3.02 px back, 7.33 px aside), unless
! `fixed`; the fixed of items, set arrow and arrow styles
block
   real(R8P) :: barbs(2, 2) !< Barb ends [px].

   call sized_head([0.0_R8P, 0.0_R8P], [15.86_R8P, 0.0_R8P], 52.86_R8P, 20.0_R8P, barbs)
   test_passed(260) = abs(15.86_R8P - barbs(1, 1) - 3.02_R8P) < 0.01_R8P .and. abs(abs(barbs(2, 1)) - 7.33_R8P) < 0.01_R8P
   call sized_head([0.0_R8P, 0.0_R8P], [15.86_R8P, 0.0_R8P], 52.86_R8P, 20.0_R8P, barbs, fixed=.true.)
   test_passed(260) = test_passed(260) .and. abs(15.86_R8P - barbs(1, 1) - 49.67_R8P) < 0.01_R8P
   call interpreter%init(scratch)
   call interpreter%run_text("set style arrow 2 head size 1,20 fixed; set arrow 1 from 0,0 to 1,1 size 1,20 fixed; "// &
                             "plot '+' using 1:1:(0.1):(0) with vectors size 1,20 fixed, "// &
                             "'+' using 1:1:(0.1):(0) with vectors as 2, '+' using 1:1:(0.1):(0) with vectors size 1,20", &
                             iostat, iomsg)
   test_passed(260) = test_passed(260) .and. iostat == 0_I4P
   if (test_passed(260)) then
      associate(panel => interpreter%figure%panels(1))
         test_passed(260) = panel%arrows(1)%fixed .and. panel%series(1)%head_fixed .and. panel%series(2)%head_fixed .and. &
                           .not. panel%series(3)%head_fixed
      endassociate
   endif
endblock


! without a color box the autoscaled color axis keeps the data range (gnuplot 6.0 extends it to the ticks it draws:
! probed, data 100..255 gives GPVAL_CB 100..260 with the box, 100..255 without, images and lc palette alike)
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '0 0 0.13', '1 0 0.5', '', '0 1 0.6', '1 1 0.87'
close(unit)
test_passed(261) = colorbox_labels("unset colorbox", [character(len=1) ::], ['0.1', '0.9'])
associate(panel => interpreter%figure%panels(1))
   test_passed(261) = test_passed(261) .and. panel%cbaxis%lo == 0.13_R8P .and. panel%cbaxis%hi == 0.87_R8P
endassociate


! a 3D view as gnuplot 6.0 draws it (do_3dplot, svg terminal): its default view 60, 30 of x*y over [-10:10]^2 places
! the first x tick label, the first y tick label, the first z tick label, the key title and the title where gnuplot's
! svg does (probed, to 0.01 px); the left base edge from the z axis corner to the back one
block
   character(len=:), allocatable :: svg !< Rendered SVG.
   integer(I4P)                  :: u   !< File unit.

   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_3d.svg'; "// &
                             "set title 'A title'; splot x*y", iostat, iomsg)
   test_passed(262) = iostat == 0_I4P
   if (test_passed(262)) then
      svg = read_text('foresight_script_test_3d.svg')
      test_passed(262) = index(svg, '<text x="80.38" y="302.66" text-anchor="middle">-10<') > 0 .and. &
                        index(svg, '<text x="367.01" y="344.47">-10<') > 0 .and. &
                        index(svg, '<text x="67.96" y="245.67" text-anchor="end">-100<') > 0 .and. &
                        index(svg, '<text x="505.88" y="66.91" text-anchor="end">x*y<') > 0 .and. &
                        index(svg, '<text x="300" y="40.52" text-anchor="middle">A title<') > 0 .and. &
                        index(svg, 'points="85.95,292.91 242.64,216.21"') > 0
      if (.not. test_passed(262)) write(error_unit, '(A)') 'check 262: '//svg
   endif
   open(newunit=u, file='foresight_script_test_3d.svg')
   close(u, status='delete')
   ! set xyplane, set view azimuth and equal read; ztics in and out
   call interpreter%run_text("set xyplane at -1; set view 70, 120, 1.2, 0.8; set view azimuth 30; set view equal xyz; "// &
                             "set ztics out mirror", iostat, iomsg)
   test_passed(262) = test_passed(262) .and. iostat == 0_I4P
   if (test_passed(262)) then
      associate(panel => interpreter%figure%panels(1))
         test_passed(262) = panel%view3d%xyplane_at .and. panel%view3d%xyplane_z == -1.0_R8P .and. &
                           panel%view3d%rot_x == 70.0_R8P .and. panel%view3d%rot_z == 120.0_R8P .and. &
                           panel%view3d%scale == 1.2_R8P .and. panel%view3d%zscale == 0.8_R8P .and. &
                           panel%view3d%azimuth == 30.0_R8P .and. panel%view3d%equal == 2_I4P .and. &
                           panel%zaxis%tics%out .and. panel%zaxis%tics%mirror
      endassociate
   endif
endblock


! labels, arrows and objects in a 3D view at their projected positions, as gnuplot's map3d_position: x, y, z axis
! values (probed: "X" at 1.2,0,0 centred at 397.34 px, "Z" at 0,0,23 at 299.90 px), graph fractions of the three
! axes, screen positions as they are; the third coordinate read (its system the y one's unless given)
block
   character(len=:), allocatable :: svg !< Rendered SVG.
   integer(I4P)                  :: u   !< File unit.

   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_3dl.svg'; "// &
                             "set view equal xy; set xyplane at 0; unset border; unset key; unset xtics; "// &
                             "unset ytics; set ztics axis; set arrow 1 from 0,0,0 to 1,0,0 head filled lw 1.5; "// &
                             "set label 1 at 1.2,0,0 'X' center; set label 3 at 0,0,23 'Z' center; "// &
                             "set label 4 'screen' at screen 0.1, 0.9; set label 5 'graph' at graph 0.5, 0.5, 1; "// &
                             "set view 60, 30, 1., 1.75; "// &
                             "splot sample [t=0:20] '+' using (cos($1)):(sin($1)):($1) with lines lw 2", iostat, iomsg)
   test_passed(263) = iostat == 0_I4P
   if (test_passed(263)) then
      svg = read_text('foresight_script_test_3dl.svg')
      test_passed(263) = index(svg, '<text x="397.34" ') > 0 .and. index(svg, '<text x="299.9" ') > 0 .and. &
                        index(svg, '<text x="60" ') > 0 .and. index(svg, '<text x="300" ') > 0
      if (.not. test_passed(263)) write(error_unit, '(A)') 'check 263: '//svg
      associate(panel => interpreter%figure%panels(1))
         test_passed(263) = test_passed(263) .and. panel%notes(2)%at%z == 23.0_R8P .and. &
                           panel%notes(2)%at%sz == 'first' .and. panel%notes(4)%at%sz == 'graph' .and. &
                           panel%arrows(1)%to%x == 1.0_R8P
      endassociate
   endif
   open(newunit=u, file='foresight_script_test_3dl.svg')
   close(u, status='delete')
endblock


! fit as gnuplot 6.0's fit.dem: a function of x and y with three columns (unit weights: the function uses y), its
! parameters from a file (a FIXED one kept), xyerrors (York's weights, the effective variance: probed digits), the
! covariance variables, yerr, start_lambda; GPFUN_name the definition as written
block
   integer(I4P)                  :: u     !< File unit.
   real(R8P)                     :: v(2)  !< Values.
   logical                       :: found !< Defined.
   character(len=:), allocatable :: text  !< A string variable.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   call interpreter%init(scratch)
   open(newunit=u, file='foresight_script_test.par', action='write', status='replace')
   write(u, '(A)') '# start', 'a'//achar(9)//'= 1.5', 'b = 2.5   # FIXED'
   close(u)
   call interpreter%run_text("h(x,y) = a*x + b*y"//nl//"$d << EOD"//nl//"0 0 1"//nl//"1 0 2"//nl//"0 1 3"//nl// &
                             "1 1 4.1"//nl//"EOD"//nl//"fit h(x,y) $d using 1:2:3 via a, b", iostat, iomsg)
   test_passed(264) = iostat == 0_I4P
   call interpreter%symbols%value_of('a', v(1), found)
   call interpreter%symbols%value_of('b', v(2), found)
   test_passed(264) = test_passed(264) .and. abs(v(1) - 1.70000003670338_R8P) < 1.0e-9_R8P .and. &
                     abs(v(2) - 2.69999995378878_R8P) < 1.0e-9_R8P
   call interpreter%run_text("fit h(x,y) $d using 1:2:3 via 'foresight_script_test.par'", iostat, iomsg)
   test_passed(264) = test_passed(264) .and. iostat == 0_I4P
   call interpreter%symbols%value_of('b', v(2), found)
   test_passed(264) = test_passed(264) .and. v(2) == 2.5_R8P
   open(newunit=u, file='foresight_script_test.par')
   close(u, status='delete')
   call interpreter%run_text("$P << EOD"//nl//"0.0 1000 5.9 1.0"//nl//"0.9 1000 5.4 1.8"//nl//"1.8 500 4.4 4.0"//nl// &
                             "2.6 800 4.6 8.0"//nl//"3.3 200 3.5 20.0"//nl//"4.4 80 3.7 20.0"//nl// &
                             "5.2 60 2.8 70.0"//nl//"6.1 20 2.8 70.0"//nl//"6.5 1.8 2.4 100.0"//nl// &
                             "7.4 1.0 1.5 500.0"//nl//"EOD"//nl//"f(x) = a1 + a2*x; a1 = 5; a2 = -0.5"//nl// &
                             "set fit covariancevariables start_lambda 0.01"//nl// &
                             "fit f(x) $P using 1:3:(sqrt(1./$2)):(sqrt(1./$4)) xyerrors via a1, a2", iostat, iomsg)
   test_passed(264) = test_passed(264) .and. iostat == 0_I4P
   call interpreter%symbols%value_of('a1', v(1), found)
   call interpreter%symbols%value_of('a2', v(2), found)
   test_passed(264) = test_passed(264) .and. abs(v(1) - 5.39608232951652_R8P) < 1.0e-9_R8P .and. &
                      abs(v(2) + 0.463454807950324_R8P) < 1.0e-9_R8P
   call interpreter%symbols%value_of('FIT_COV_a1_a2', v(1), found)
   test_passed(264) = test_passed(264) .and. found .and. abs(v(1) + 0.0246207560840814_R8P) < 1.0e-9_R8P
   call interpreter%run_text("set fit nocovariancevariables; fit f(x) $P using 1:3:(sqrt(1./$4)) yerr via a1, a2", &
                             iostat, iomsg)
   test_passed(264) = test_passed(264) .and. iostat == 0_I4P
   call interpreter%run_text("l(x) = y0 + m*x"//nl//"msg = GPFUN_l", iostat, iomsg)
   test_passed(264) = test_passed(264) .and. iostat == 0_I4P
   call interpreter%symbols%string_of('msg', text, found)
   test_passed(264) = test_passed(264) .and. found .and. text == 'l(x) = y0 + m*x'
endblock


! what gnuplot 6.0's tier-B demos (issue #4) read: splot with surface (the mesh lines) and its error bar styles
! (points), set termoption solid, set border -1 lt black, an object's border lt, a range's writeback, the second
! dummy of set dummy u, v, the pseudo-column -2 as a bare using field, a doubled quote in a single-quoted string
block
   character(len=:), allocatable :: text  !< A string variable.
   logical                       :: found !< Defined.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   call interpreter%init(scratch)
   call interpreter%run_text("set table 'foresight_script_test.dat'; set isosamples 3; splot [0:1][0:1] x*y with surface"// &
                             "; unset table", iostat, iomsg)
   test_passed(265) = iostat == 0_I4P
   if (test_passed(265)) test_passed(265) = interpreter%figure%panels(1)%series(1)%style%with == WITH_LINES
   call interpreter%run_text("$e << EOD"//nl//"0 0 1 0.1"//nl//"1 1 2 0.2"//nl//"EOD"//nl// &
                             "set table 'foresight_script_test.dat'; splot $e using 1:2:3 with yerrorbars; unset table", &
                             iostat, iomsg)
   test_passed(265) = test_passed(265) .and. iostat == 0_I4P
   if (test_passed(265)) test_passed(265) = interpreter%figure%panels(1)%series(1)%style%with == WITH_POINTS
   call interpreter%run_text("set termoption solid; set border -1 front lt black; set xrange [0:1] writeback; "// &
                             "set object 1 circle at 0,0 radius 1 fs solid border lt -1 fc rgb 'red'", iostat, iomsg)
   test_passed(265) = test_passed(265) .and. iostat == 0_I4P
   if (test_passed(265)) test_passed(265) = interpreter%figure%panels(1)%border == 4095_I4P .and. &
                                          interpreter%figure%panels(1)%border_dt == 1_I4P
   call interpreter%run_text("set dummy u, v; set table 'foresight_script_test.dat'; splot [0:1][0:1] u+v; "// &
                             "unset table; set dummy x, y", iostat, iomsg)
   test_passed(265) = test_passed(265) .and. iostat == 0_I4P
   call interpreter%run_text("$f << EOD"//nl//"1 2"//nl//"2 3"//nl//nl//nl//"3 4"//nl//"EOD"//nl// &
                             "set table 'foresight_script_test.dat'; plot $f using 1:-2; unset table", iostat, iomsg)
   test_passed(265) = test_passed(265) .and. iostat == 0_I4P
   if (test_passed(265)) then
      associate(y => interpreter%figure%panels(1)%series(1)%y)
         ! the datasets of the points (a break between them)
         test_passed(265) = y(1) == 0.0_R8P .and. y(2) == 0.0_R8P .and. y(size(y)) == 1.0_R8P
      endassociate
   endif
   call interpreter%run_text("s = 'it''s'", iostat, iomsg)
   test_passed(265) = test_passed(265) .and. iostat == 0_I4P
   call interpreter%symbols%string_of('s', text, found)
   test_passed(265) = test_passed(265) .and. found .and. text == "it's"
endblock


! set mapping spherical|cylindrical: splot's data columns theta:phi:r (r 1 for two columns) or theta:z:r made x, y, z
! as gnuplot's get_3ddata, in the angle unit; a function's samples not mapped; unset mapping back to cartesian
block
   character(len=1), parameter :: nl = new_line('a') !< New line.

   call interpreter%init(scratch)
   call interpreter%run_text("$s << EOD"//nl//"90 0"//nl//"0 90"//nl//"EOD"//nl//"$c << EOD"//nl//"90 5 2"//nl// &
                             "EOD"//nl//"set angles degrees; set mapping spherical; "// &
                             "set table 'foresight_script_test.dat'; splot $s, $c; unset table", iostat, iomsg)
   test_passed(266) = iostat == 0_I4P
   if (test_passed(266)) then
      associate(series => interpreter%figure%panels(1)%series)
         test_passed(266) = abs(series(1)%x(1)) < 1.0e-15_R8P .and. abs(series(1)%y(1) - 1.0_R8P) < 1.0e-15_R8P .and. &
                           abs(series(1)%z(1)) < 1.0e-15_R8P .and. series(1)%z(2) == 1.0_R8P .and. &
                           abs(series(2)%x(1)) < 1.0e-15_R8P .and. &
                           abs(series(2)%z(1) - 2.0_R8P * sin(5.0_R8P * atan(1.0_R8P) / 45.0_R8P)) < 1.0e-15_R8P
      endassociate
   endif
   call interpreter%run_text("set mapping cylindrical; set table 'foresight_script_test.dat'; splot $c; unset table", &
                             iostat, iomsg)
   test_passed(266) = test_passed(266) .and. iostat == 0_I4P
   if (test_passed(266)) then
      associate(series => interpreter%figure%panels(1)%series)
         test_passed(266) = abs(series(1)%x(1)) < 1.0e-15_R8P .and. abs(series(1)%y(1) - 2.0_R8P) < 1.0e-15_R8P .and. &
                           series(1)%z(1) == 5.0_R8P
      endassociate
   endif
   call interpreter%run_text("set mapping bogus", iostat, iomsg)
   test_passed(266) = test_passed(266) .and. iostat /= 0_I4P .and. index(iomsg, 'cartesian, spherical or cylindrical') > 0
   call interpreter%run_text("unset mapping", iostat, iomsg)
   test_passed(266) = test_passed(266) .and. iostat == 0_I4P .and. interpreter%mapping == 0_I4P
endblock


! set hidden3d, as gnuplot 6.0 (a painter's algorithm here): a function's grid of isosamples points both ways and no
! crossing curves, its underside in the linetype after its own (the next item's linetype one further), the surface
! drawn as opaque quadrangles; the key below the plot at gnuplot's place (probed: the title's end at 486.66, 349.89);
! set autoscale z
block
   character(len=:), allocatable :: svg !< Rendered SVG.
   integer(I4P)                  :: u   !< File unit.

   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_hid.svg'; "// &
                             "set parametric; set isosamples 50,10; set hidden; set key below; "// &
                             "set urange [-pi/2:pi/2]; set vrange [0:2*pi]; set ztics nomirror -1.0,0.25,1.0; "// &
                             "set view 45,50; splot cos(u)*cos(v),cos(u)*sin(v),sin(u)", iostat, iomsg)
   test_passed(267) = iostat == 0_I4P
   if (test_passed(267)) then
      svg = read_text('foresight_script_test_hid.svg')
      test_passed(267) = index(svg, 'fs-hidden3d') > 0 .and. &
                        index(svg, '<text x="486.66" y="349.89" text-anchor="end">cos(u)*cos(v),cos(u)*sin(v),sin(u)<') > 0
      associate(series => interpreter%figure%panels(1)%series(1))
         test_passed(267) = test_passed(267) .and. series%grid_scans == 10_I4P .and. size(series%scans, 2) == 10 .and. &
                           series%scans(2, 1) - series%scans(1, 1) + 1_I4P == 50_I4P .and. allocated(series%back_color)
      endassociate
      if (.not. test_passed(267)) write(error_unit, '(A)') 'check 267: '//svg
   endif
   open(newunit=u, file='foresight_script_test_hid.svg')
   close(u, status='delete')
   call interpreter%run_text("set hidden3d offset 2 trianglepattern 3 undefined 1 altdiagonal bentover; "// &
                             "set zrange [0:1]; set autoscale z", iostat, iomsg)
   test_passed(267) = test_passed(267) .and. iostat == 0_I4P .and. &
                     interpreter%figure%panels(1)%view3d%hidden_offset == 2_I4P .and. &
                     .not. interpreter%figure%panels(1)%zaxis%min_fixed
   call interpreter%run_text("unset hidden3d", iostat, iomsg)
   test_passed(267) = test_passed(267) .and. iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%view3d%hidden3d
endblock


! plot for clauses with bounds depending on an outer variable (gnuplot 6.0's iterate.dem: for [i=1:3] for [k=i:i]
! for [j=1:k], the items in gnuplot's order), sample after the inline ranges (splot [-2:2][-2:2] sample [h=1:5] '+'),
! rgbalpha of one packed ARGB column (the alpha inverted, as gnuplot)
block
   character(len=1), parameter   :: nl = new_line('a') !< New line.
   character(len=12), parameter  :: titles(6) = [character(len=12) :: 'k=1 j=1', 'k=2 j=1', 'k=2 j=2', 'k=3 j=1', &
                                                 'k=3 j=2', 'k=3 j=3'] !< gnuplot's titles.
   integer(I4P)                  :: k !< Item counter.

   call interpreter%init(scratch)
   call interpreter%run_text("set table 'foresight_script_test.dat'; plot for [i=1:3] for [k=i:i] for [j=1:k] "// &
                             "10*k + j title sprintf('k=%d j=%d', k, j); unset table", iostat, iomsg)
   test_passed(268) = iostat == 0_I4P
   if (test_passed(268)) then
      test_passed(268) = size(interpreter%figure%panels(1)%series) == 6
      if (test_passed(268)) test_passed(268) = all([(interpreter%figure%panels(1)%series(k)%title == trim(titles(k)), &
                                                   k = 1_I4P, 6_I4P)])
   endif
   call interpreter%run_text("set table 'foresight_script_test.dat'; "// &
                             "splot [-2:2][-2:2] sample [h=1:5] '+' using (cos(h)):(sin(h)):(h); unset table", &
                             iostat, iomsg)
   test_passed(268) = test_passed(268) .and. iostat == 0_I4P
   if (test_passed(268)) test_passed(268) = interpreter%figure%panels(1)%series(1)%z(1) == 1.0_R8P
   call interpreter%run_text("$B << EOB"//nl//"0x40ff8000 0x00000000"//nl//"0x00ffffff 0x0000ff00"//nl//"EOB"//nl// &
                             "set table 'foresight_script_test.dat'; plot $B matrix using 1:2:3 with rgbalpha; "// &
                             "unset table", iostat, iomsg)
   test_passed(268) = test_passed(268) .and. iostat == 0_I4P
   if (test_passed(268)) then
      associate(c => interpreter%figure%panels(1)%series(1)%channels)
         test_passed(268) = c(1, 1, 1) == 255.0_R8P .and. c(2, 1, 1) == 128.0_R8P .and. c(3, 1, 1) == 0.0_R8P .and. &
                           c(4, 1, 1) == 191.0_R8P .and. c(4, 2, 1) == 255.0_R8P
      endassociate
   endif
endblock


! splot ... smooth csplines|acsplines, as gnuplot 6.0's gen_3d_splines: each scan smoothed in 3D, `set samples` points;
! a curve in a plane of constant x splined as z of y (probed: gnuplot's table, csplines through 6 points sampled 6
! times gives them back; acsplines weighted 1 at y = 0 gives 1.16974); the other smoothings refused in splot
block
   character(len=1), parameter :: nl = new_line('a') !< New line.

   call interpreter%init(scratch)
   call interpreter%run_text("$d << EOD"//nl//"0 0 1"//nl//"0 1 2"//nl//"0 2 1.5"//nl//"0 3 3"//nl//"0 4 2"//nl// &
                             "0 5 2.5"//nl//"EOD"//nl//"set samples 6; set table 'foresight_script_test.dat'; "// &
                             "splot $d using 1:2:3 smooth csplines, $d using 1:2:3:(1) smooth acsplines; unset table", &
                             iostat, iomsg)
   test_passed(269) = iostat == 0_I4P
   if (test_passed(269)) then
      associate(series => interpreter%figure%panels(1)%series)
         test_passed(269) = size(series(1)%x) == 6 .and. abs(series(1)%z(4) - 3.0_R8P) < 1.0e-12_R8P .and. &
                           abs(series(2)%z(1) - 1.16974_R8P) < 1.0e-5_R8P
      endassociate
   endif
   call interpreter%run_text("splot $d using 1:2:3 smooth bezier", iostat, iomsg)
   test_passed(269) = test_passed(269) .and. iostat /= 0_I4P .and. index(iomsg, 'csplines and acsplines') > 0
endblock



! pm3d `lc rgb variable` (`fc rgb variable`): each quadrangle in the mean of its corners' packed colors channel by
! channel, the transparency averaged too (gnuplot 6.0, probed: red, blue, green and 0x80ffffff give rgb(127,127,127)
! at opacity 0.87); `c1` of a surface of 2 scans the later scan's first point (gnuplot's scansautomatic order); `lc
! variable` the palette of the column (rgb(119,3,250)); `set pm3d border lt black lw 1.5`, `retrace`
block
   character(len=:), allocatable :: svg  !< Page.
   character(len=:), allocatable :: quad !< The quadrangle datablock.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   quad = "$q << EOD"//nl//"0 0 0 16711680"//nl//"0 1 0 255"//nl//nl//"1 0 0 65280"//nl//"1 1 0 2164260863"//nl// &
          "EOD"//nl
   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_pm3d.svg'; "// &
                             "set view map"//nl//quad//"splot $q using 1:2:3:4 with pm3d lc rgb variable", iostat, iomsg)
   test_passed(270) = iostat == 0_I4P
   if (test_passed(270)) then
      svg = read_text('foresight_script_test_pm3d.svg')
      test_passed(270) = index(svg, 'fill="#7f7f7fdf"') > 0
   endif
   call interpreter%run_text("splot $q using 1:2:3:4 with pm3d fc rgb variable", iostat, iomsg)
   test_passed(270) = test_passed(270) .and. iostat == 0_I4P
   if (test_passed(270)) test_passed(270) = index(read_text('foresight_script_test_pm3d.svg'), 'fill="#7f7f7fdf"') > 0
   call interpreter%run_text("set pm3d corners2color c1; replot", iostat, iomsg)
   test_passed(270) = test_passed(270) .and. iostat == 0_I4P
   if (test_passed(270)) test_passed(270) = index(read_text('foresight_script_test_pm3d.svg'), 'fill="#00ff00"') > 0
   call interpreter%run_text("set pm3d corners2color mean; splot $q using 1:2:3:4 with pm3d lc variable", iostat, iomsg)
   test_passed(270) = test_passed(270) .and. iostat == 0_I4P
   if (test_passed(270)) test_passed(270) = index(read_text('foresight_script_test_pm3d.svg'), 'fill="#7703fa"') > 0
   call interpreter%run_text("set pm3d border lt black lw 1.5; splot $q using 1:2:3:4 with pm3d lc rgb variable", &
                             iostat, iomsg)
   test_passed(270) = test_passed(270) .and. iostat == 0_I4P
   if (test_passed(270)) then
      svg = read_text('foresight_script_test_pm3d.svg')
      test_passed(270) = index(svg, 'fill="#7f7f7fdf" stroke="#000000" stroke-width="1.5"') > 0
   endif
   call interpreter%run_text("set pm3d border retrace; replot", iostat, iomsg)
   test_passed(270) = test_passed(270) .and. iostat == 0_I4P
   if (test_passed(270)) test_passed(270) = index(read_text('foresight_script_test_pm3d.svg'), &
                                                'fill="#7f7f7fdf" stroke="#7f7f7fdf"') > 0
   call interpreter%run_text("set pm3d border lc palette", iostat, iomsg)
   test_passed(270) = test_passed(270) .and. iostat /= 0_I4P .and. index(iomsg, 'border: a color') > 0
endblock



! gnuplot's option forms read by the tier B and C demos: `set no{foo}` as `unset foo` (`set nomztics`, gnuplot's
! set_command); `unset log z`; `set palette cubehelix cyc[les] C sat[uration] S` (gnuplot's almost_equals);
! `set label ... tc def[ault]` and `tc lt N`; `set cblabel "text" offset X,Y tc COLOR norotate` (offset in gnuplot's
! characters, h_char 0.7 and v_char 1.5 font sizes, probed); `splot [x=a:b] [y=c:d] f(x,y)` naming the dummies after
! `set dummy u,v` (gnuplot's surface1.dem)
block
   character(len=:), allocatable :: svg !< Page.

   call interpreter%init(scratch)
   call interpreter%run_text("set mztics 2; set nomztics; set log z; unset log z; "// &
                             "set palette cubehelix start 1 cyc 2 sat 0.5", iostat, iomsg)
   associate(panel => interpreter%figure%panels(1))
      test_passed(271) = iostat == 0_I4P .and. panel%zaxis%tics%minor /= 2_I4P .and. .not. panel%zaxis%log .and. &
                        all(panel%palette%cubehelix == [1.0_R8P, 2.0_R8P, 0.5_R8P])
   endassociate
   call interpreter%run_text("set label 1 'a' at 0,0 tc lt 2; set label 1 'a' at 0,0 tc def", iostat, iomsg)
   test_passed(271) = test_passed(271) .and. iostat == 0_I4P
   if (test_passed(271)) test_passed(271) = len(interpreter%figure%panels(1)%notes(1)%color) == 0
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_cb.svg'; "// &
                             "set cblabel 'Phase' offset -2,1 tc 'red'; plot '++' using 1:2:($1*$2) with image", &
                             iostat, iomsg)
   test_passed(271) = test_passed(271) .and. iostat == 0_I4P
   if (test_passed(271)) then
      svg = read_text('foresight_script_test_cb.svg')
      test_passed(271) = index(svg, 'x="570.2" y="174.5" text-anchor="middle" transform="rotate(-90 570.2 174.5)" '// &
                                   'fill="#ff0000">Phase') > 0
   endif
   call interpreter%run_text("set cblabel norotate offset 0,0 tc def; replot", iostat, iomsg)
   test_passed(271) = test_passed(271) .and. iostat == 0_I4P
   if (test_passed(271)) test_passed(271) = index(read_text('foresight_script_test_cb.svg'), &
                                                'x="583.1" y="196.4" text-anchor="middle">Phase') > 0
   call interpreter%run_text("set dummy u,v; set table 'foresight_script_test.dat'; "// &
                             "splot [x=0:1] [y=0:2] x*y; unset table", iostat, iomsg)
   test_passed(271) = test_passed(271) .and. iostat == 0_I4P
   if (test_passed(271)) then
      associate(series => interpreter%figure%panels(1)%series)
         test_passed(271) = abs(maxval(series(1)%z, mask=ieee_is_finite(series(1)%z)) - 2.0_R8P) < 1.0e-12_R8P
      endassociate
   endif
endblock



! labels in palette colors, gnuplot 6.0's (probed): `tc palette z` the z of the label over the color axis, `cb V` a
! value, `frac F` a fraction; the color axis set up for them alone (cbrange [0:1]: black, rgb(180,32,0),
! rgb(114,2,243)), over the z range without a cbrange (labels at z -10, 0, 9 with zrange [-10:10]: black,
! rgb(180,32,0), rgb(249,219,0)); `set xtics geographic` with `set format x "%D %E"` (gnuplot's gstrdms: 150 W, 0,
! 80 N); splot pm3d lc rgb variable of three fields, the heights its packed colors (gnuplot's complex_trig.dem)
block
   character(len=:), allocatable :: svg  !< Page.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_tc.svg'; "// &
                             "set cbrange [0:1]; set label 1 'Z' at 0,0 tc palette z; "// &
                             "set label 2 'C' at 0,0.5 tc palette cb 0.5; set label 3 'F' at 0,0.8 tc palette frac 0.2; "// &
                             "splot x*y", iostat, iomsg)
   test_passed(272) = iostat == 0_I4P
   if (test_passed(272)) then
      svg = read_text('foresight_script_test_tc.svg')
      test_passed(272) = index(svg, 'fill="#000000">Z<') > 0 .and. index(svg, 'fill="#b42000">C<') > 0 .and. &
                        index(svg, 'fill="#7202f3">F<') > 0
   endif
   call interpreter%run_text("unset label; unset cbrange; set xrange [-10:10]; set yrange [-10:10]; "// &
                             "set zrange [-10:10]; set label 1 'A' at 0,0,-10 tc pal z; "// &
                             "set label 2 'B' at 0,0,0 tc pal z; set label 3 'C' at 0,0,9 tc pal z; splot x*y/10", &
                             iostat, iomsg)
   test_passed(272) = test_passed(272) .and. iostat == 0_I4P
   if (test_passed(272)) then
      svg = read_text('foresight_script_test_tc.svg')
      test_passed(272) = index(svg, 'fill="#000000">A<') > 0 .and. index(svg, 'fill="#b42000">B<') > 0 .and. &
                        index(svg, 'fill="#f9db00">C<') > 0
   endif
   call interpreter%run_text("reset; set xrange [-180:180]; set xtics geographic; set format x '%D %E'; "// &
                             "plot x", iostat, iomsg)
   test_passed(272) = test_passed(272) .and. iostat == 0_I4P
   if (test_passed(272)) then
      svg = read_text('foresight_script_test_tc.svg')
      test_passed(272) = index(svg, '>150 W<') > 0 .and. index(svg, '>0  <') > 0 .and. index(svg, '>100 E<') > 0
   endif
   call interpreter%run_text("set format y '%D %N' geographic; set yrange [-90:90]; replot", iostat, iomsg)
   test_passed(272) = test_passed(272) .and. iostat == 0_I4P
   if (test_passed(272)) test_passed(272) = index(read_text('foresight_script_test_tc.svg'), '>80 N<') > 0
   call interpreter%run_text("reset; set view map"//nl//"$q << EOD"//nl//"0 0 16711680"//nl//"0 1 255"//nl//nl// &
                             "1 0 65280"//nl//"1 1 2164260863"//nl//"EOD"//nl// &
                             "splot $q using 1:2:3 with pm3d lc rgb variable", iostat, iomsg)
   test_passed(272) = test_passed(272) .and. iostat == 0_I4P
   if (test_passed(272)) test_passed(272) = index(read_text('foresight_script_test_tc.svg'), 'fill="#7f7f7fdf"') > 0
endblock



! plot items and commands of gnuplot 6.0's demos (probed): `eval(EXPR)`; function blocks with named parameters
! (`function $F(a, b) << EOD`, each `local NAME = ARGV[k]`); `splot 'f' using 1`, x the point in its scan and y the
! scan in its dataset (gnuplot's table: 0 1 8 after 0 0 5..7); an array element starting an item (`U[2]*x`);
! `nohidden3d`; `clear` in a multiplot (the next box painted, 60,80 180x120 as gnuplot); `keyentry "text"` its text the
! sample; `palette(z)` over the color axis as it stands (-10 to 10 before a plot: palette(5) dd6c00, as gnuplot); an
! unevenly sampled complete grid as an image (sampling.dem: 25, 31, 35, ... spread evenly)
block
   character(len=:), allocatable :: svg  !< Page.
   character(len=1), parameter   :: nl = new_line('a') !< New line.
   real(R8P)                     :: v    !< A value.
   logical                       :: found !< Variable found.

   call interpreter%init(scratch)
   call interpreter%run_text("eval(sprintf('k = %d', 7))"//nl//"function $F(a, b) << EOD"//nl//"  return a*10 + b"//nl// &
                             "EOD"//nl//"r = $F(3, 4)"//nl//"p = palette(5)", iostat, iomsg)
   test_passed(273) = iostat == 0_I4P
   call interpreter%symbols%value_of('k', v, found)
   test_passed(273) = test_passed(273) .and. found .and. v == 7.0_R8P
   call interpreter%symbols%value_of('r', v, found)
   test_passed(273) = test_passed(273) .and. found .and. v == 34.0_R8P
   call interpreter%symbols%value_of('p', v, found)
   test_passed(273) = test_passed(273) .and. found .and. v == 14511104.0_R8P
   call interpreter%run_text("$o << EOD"//nl//"5"//nl//"6"//nl//"7"//nl//nl//"8"//nl//"9"//nl//"EOD"//nl// &
                             "set table 'foresight_script_test.dat'; splot $o using 1 nohidden3d; unset table", &
                             iostat, iomsg)
   test_passed(273) = test_passed(273) .and. iostat == 0_I4P
   if (test_passed(273)) then
      associate(series => interpreter%figure%panels(1)%series(1))
         test_passed(273) = series%x(5) == 0.0_R8P .and. series%y(5) == 1.0_R8P .and. series%z(5) == 8.0_R8P .and. &
                           series%x(3) == 2.0_R8P .and. series%no_hidden
      endassociate
   endif
   call interpreter%run_text("array U[3] = [0.1, 0.2, 0.3]; set table 'foresight_script_test.dat'; "// &
                             "plot [0:1] U[2]*x; unset table", iostat, iomsg)
   test_passed(273) = test_passed(273) .and. iostat == 0_I4P
   if (test_passed(273)) test_passed(273) = abs(maxval(interpreter%figure%panels(1)%series(1)%y, &
                                                     mask=ieee_is_finite(interpreter%figure%panels(1)%series(1)%y)) - &
                                              0.2_R8P) < 1.0e-12_R8P
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_clear.svg'"//nl// &
                             "set multiplot; plot x; set origin 0.1,0.5; set size 0.3,0.3; clear; "// &
                             "plot x**2, keyentry 'Secondary' font ':Bold'; unset multiplot", iostat, iomsg)
   test_passed(273) = test_passed(273) .and. iostat == 0_I4P
   if (test_passed(273)) then
      svg = read_text('foresight_script_test_clear.svg')
      test_passed(273) = index(svg, '<rect x="60" y="80" width="180" height="120" fill="#ffffff"') > 0 .and. &
                        index(svg, 'font-weight="bold">Secondary</text>') > 0
   endif
   call interpreter%run_text("reset; set output 'foresight_script_test_clear.svg'; set view map; "// &
                             "splot sample [u=25:75:1][v=25:75:4] '++' using 1:2:0:(u):(v):(0):(255) with rgbalpha", &
                             iostat, iomsg)
   test_passed(273) = test_passed(273) .and. iostat == 0_I4P
endblock



! contours in 3D views, as gnuplot 6.0's graph3d (probed: the same lines and key entries): `set contour[s] base` the
! levels at the base plane, each its series and key entry (x*y: 100, 50, 0, -50, the surface first), `surface` at
! their heights, `both`; `unset clabel` (deprecated) one series in the surface's color; a function `with labels` its
! contour labels alone, centred and boxed at the points start, start + interval, ... (gnuplot's cntr3d_labels)
block
   character(len=:), allocatable :: svg !< Page.
   integer(I4P)                  :: lines !< Polylines of the page.
   integer(I4P)                  :: k     !< Position.

   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_c3d.svg'; "// &
                             "set contours base; splot x*y", iostat, iomsg)
   test_passed(274) = iostat == 0_I4P
   if (test_passed(274)) then
      svg = read_text('foresight_script_test_c3d.svg')
      lines = 0_I4P
      k = 1_I4P
      do while (index(svg(k:), '<polyline') > 0)
         k = k + index(svg(k:), '<polyline', kind=I4P)
         lines = lines + 1_I4P
      enddo
      test_passed(274) = index(svg, 'data-series="5"') > 0 .and. index(svg, 'data-series="6"') == 0 .and. lines == 64
   endif
   call interpreter%run_text("set contour both; replot", iostat, iomsg)
   test_passed(274) = test_passed(274) .and. iostat == 0_I4P
   if (test_passed(274)) test_passed(274) = index(read_text('foresight_script_test_c3d.svg'), 'data-series="9"') > 0
   call interpreter%run_text("set contour base; unset clabel; replot", iostat, iomsg)
   test_passed(274) = test_passed(274) .and. iostat == 0_I4P
   if (test_passed(274)) then
      svg = read_text('foresight_script_test_c3d.svg')
      test_passed(274) = index(svg, 'data-series="2"') > 0 .and. index(svg, 'data-series="3"') == 0 .and. &
                        interpreter%figure%panels(1)%contour%onecolor
   endif
   call interpreter%run_text("set clabel; set cntrparam levels auto 10; splot x**2-y**2 with labels boxed notitle", &
                             iostat, iomsg)
   test_passed(274) = test_passed(274) .and. iostat == 0_I4P
   if (test_passed(274)) then
      svg = read_text('foresight_script_test_c3d.svg')
      test_passed(274) = index(svg, 'filter="url(#textbox)" data-u="0.5451" data-v="0.5625"') > 0 .and. &
                        .not. interpreter%figure%panels(1)%contour%onecolor
   endif
endblock



! pm3d in a 3D view, gnuplot 6.0's pm3d_plot (probed: the svg polygons of a 3 x 3 grid, default view 60, 30, 600 x 400):
! the first quadrangle 242.65,81.92 164.30,158.56 300,169.97 378.34,93.32 in rgb(190,44,0), the next in rgb(225,120,0)
! (scansautomatic: the scans and points in gnuplot's order); `at b` on the base plane (208.14, 248.72, ...);
! `depthorder` the second drawn rgb(120,3,251); the color box at gnuplot's default place for a 3D plot; the pm3d
! warning of the repair round gone
block
   character(len=:), allocatable :: svg  !< Page.
   character(len=:), allocatable :: grid !< The grid datablock.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   grid = "$g << EOD"//nl//"0 0 0"//nl//"1 0 1"//nl//"2 0 2"//nl//nl//"0 1 3"//nl//"1 1 4"//nl//"2 1 8"//nl//nl// &
          "0 2 6"//nl//"1 2 7"//nl//"2 2 9"//nl//"EOD"//nl
   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_p3d.svg'"//nl//grid// &
                             "splot $g using 1:2:3 with pm3d notitle", iostat, iomsg)
   test_passed(275) = iostat == 0_I4P
   if (test_passed(275)) then
      svg = read_text('foresight_script_test_p3d.svg')
      test_passed(275) = index(svg, 'fill="#be2c00" stroke="none" vector-effect="non-scaling-stroke" '// &
                                   'd="M0.404417,0.2048 0.273833,0.3964 0.5,0.424925 0.630567,0.2333Z"') > 0 .and. &
                        index(svg, 'class="fs-colorbox"') > 0
      test_passed(275) = test_passed(275) .and. index(svg, '#be2c00') < index(svg, '#e17800')
   endif
   call interpreter%run_text("set pm3d at b; replot", iostat, iomsg)
   test_passed(275) = test_passed(275) .and. iostat == 0_I4P
   if (test_passed(275)) test_passed(275) = index(read_text('foresight_script_test_p3d.svg'), &
                                                'd="M0.404417,0.52035 0.273833,0.6218 0.5,0.680375 0.630567,0.578925Z"') > 0
   call interpreter%run_text("set pm3d at s depthorder; replot", iostat, iomsg)
   test_passed(275) = test_passed(275) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%pm3d%direction == 3_I4P
   if (test_passed(275)) then
      svg = read_text('foresight_script_test_p3d.svg')
      test_passed(275) = index(svg, '#7803fb') < index(svg, '#e17800') .and. index(svg, '#7803fb') > index(svg, '#be2c00')
   endif
   call interpreter%run_text("set pm3d at bstbst scansforward; replot", iostat, iomsg)
   test_passed(275) = test_passed(275) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%pm3d%at == 'bstbst' .and. &
                     interpreter%figure%panels(1)%pm3d%direction == 1_I4P
endblock



! pm3d lighting, gnuplot 6.0's apply_lighting_model (probed: the svg polygons of a 3 x 3 grid, 600 x 400, view 60, 30):
! `lighting` alone rgb(192,48,5), rgb(218,116,0), rgb(123,8,252); `primary 0.8 specular 0.5` rgb(198,56,13); a fill
! color lit (`fc "gray"`, `primary 0.5 specular 0.3`) rgb(194,194,194), rgb(184,184,184); `fc ls N` the style's
! color; `nolighting` back to the palette's rgb(190,44,0); spotlight options read; `bind` a no-op; an implicit pm3d
! surface of `lc rgb variable` lines in their colors (rgb(170,238,238))
block
   character(len=:), allocatable :: svg  !< Page.
   character(len=:), allocatable :: grid !< The grid datablock.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   grid = "$g << EOD"//nl//"0 0 0"//nl//"1 0 1"//nl//"2 0 2"//nl//nl//"0 1 3"//nl//"1 1 4"//nl//"2 1 8"//nl//nl// &
          "0 2 6"//nl//"1 2 7"//nl//"2 2 9"//nl//"EOD"//nl
   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_lit.svg'"//nl//grid// &
                             "set pm3d lighting"//nl//"splot $g using 1:2:3 with pm3d notitle", iostat, iomsg)
   test_passed(276) = iostat == 0_I4P
   if (test_passed(276)) then
      svg = read_text('foresight_script_test_lit.svg')
      test_passed(276) = index(svg, '#c03005') > 0 .and. index(svg, '#c03005') < index(svg, '#da7400') .and. &
                        index(svg, '#da7400') < index(svg, '#7b08fc') .and. index(svg, '#be2c00') == 0
   endif
   call interpreter%run_text("set pm3d lighting primary 0.8 specular 0.5; replot", iostat, iomsg)
   test_passed(276) = test_passed(276) .and. iostat == 0_I4P
   if (test_passed(276)) test_passed(276) = index(read_text('foresight_script_test_lit.svg'), '#c6380d') > 0
   call interpreter%run_text("set pm3d lighting primary 0.5 specular 0.3"//nl// &
                             "splot $g using 1:2:3 with pm3d fc 'gray' notitle", iostat, iomsg)
   test_passed(276) = test_passed(276) .and. iostat == 0_I4P
   if (test_passed(276)) then
      svg = read_text('foresight_script_test_lit.svg')
      test_passed(276) = index(svg, '#c2c2c2') > 0 .and. index(svg, '#b8b8b8') > 0
   endif
   call interpreter%run_text("set pm3d nolighting"//nl//"set style line 3 lc rgb '#336699'"//nl// &
                             "splot $g using 1:2:3 with pm3d fc ls 3 notitle", iostat, iomsg)
   test_passed(276) = test_passed(276) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%pm3d%strength == 0.0_R8P
   if (test_passed(276)) test_passed(276) = index(read_text('foresight_script_test_lit.svg'), 'fill="#336699"') > 0
   call interpreter%run_text("bind all 'x' 'replot'"//nl// &
                             "set pm3d spotlight rot_x 30 rot_z 60 rgbcolor 'blue' Phong 6"//nl// &
                             "set pm3d lighting spec2 0.4", iostat, iomsg)
   test_passed(276) = test_passed(276) .and. iostat == 0_I4P
   if (test_passed(276)) test_passed(276) = &
      all(interpreter%figure%panels(1)%pm3d%spot_rot == [30.0_R8P, 60.0_R8P]) .and. &
      interpreter%figure%panels(1)%pm3d%spot_rgb == 255_I4P .and. interpreter%figure%panels(1)%pm3d%spot_phong == 6.0_R8P &
      .and. interpreter%figure%panels(1)%pm3d%spec2 == 0.4_R8P .and. interpreter%figure%panels(1)%pm3d%strength == 0.5_R8P
   call interpreter%run_text("set pm3d spotlight default", iostat, iomsg)
   test_passed(276) = test_passed(276) .and. iostat == 0_I4P .and. &
                     interpreter%figure%panels(1)%pm3d%spot_rgb == 16711748_I4P
   ! an implicit pm3d surface of `lc rgb variable` lines in their packed colors (gnuplot's color_from_rgbvar)
   call interpreter%run_text("unset pm3d; set pm3d implicit nolighting"//nl// &
                             "splot $g using 1:2:3:(0xAAEEEE) nosurface lc rgb variable notitle", iostat, iomsg)
   test_passed(276) = test_passed(276) .and. iostat == 0_I4P
   if (test_passed(276)) test_passed(276) = index(read_text('foresight_script_test_lit.svg'), 'fill="#aaeeee"') > 0

endblock



! `with contourfill`, gnuplot 6.0's plot3d_contourfill (probed: the svg polygons of a 3 x 3 grid, 600 x 400): `set
! contourfill auto 3` the quadrangles clipped to 3 slices of the z range, slice after slice, each in the palette color
! of its middle (rgb(104,1,221) first: a degenerate triangle at a corner, then a pentagon); `ztics` 27 polygons;
! `firstlinetype 3` in linetypes 3, 4, ...; a map view the same polygons; the default `clip z` of pm3d clipping the
! quadrangles at a z range set (a pentagon in rgb(236,161,0)), the color axis autoscaled over the points within it
! (rgb(193,48,0) first); `set tics scale 0` turning back on the x and y ticks turned off (gnuplot's set_tic_prop)
block
   character(len=:), allocatable :: svg  !< Page.
   character(len=:), allocatable :: grid !< The grid datablock.
   character(len=1), parameter   :: nl = new_line('a') !< New line.
   integer(I4P)                  :: k, n !< Counters.

   grid = "$g << EOD"//nl//"0 0 0"//nl//"1 0 1"//nl//"2 0 2"//nl//nl//"0 1 3"//nl//"1 1 4"//nl//"2 1 8"//nl//nl// &
          "0 2 6"//nl//"1 2 7"//nl//"2 2 9"//nl//"EOD"//nl
   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_cf.svg'"//nl//grid// &
                             "set contourfill auto 3"//nl//"splot $g using 1:2:3 with contourfill notitle", iostat, iomsg)
   test_passed(277) = iostat == 0_I4P
   if (test_passed(277)) then
      svg = read_text('foresight_script_test_cf.svg')
      test_passed(277) = index(svg, 'fill="#6801dd" stroke="none" vector-effect="non-scaling-stroke" '// &
                                   'd="M0.273833,0.3964 0.273833,0.3964 0.273833,0.3964Z"') > 0 .and. &
                        index(svg, 'd="M0.273833,0.3964 0.143267,0.587975 0.369433,0.6165 0.456483,0.48875 '// &
                                   '0.273833,0.3964Z"') > 0 .and. &
                        index(svg, 'fill="#b42000" stroke="none" vector-effect="non-scaling-stroke" '// &
                                   'd="M0.58705,0.297175 0.5,0.424925 0.613083,0.394075Z"') > 0 .and. &
                        index(svg, '#6801dd') < index(svg, '#b42000') .and. index(svg, 'class="fs-colorbox"') > 0
   endif
   call interpreter%run_text("set contourfill ztics; replot", iostat, iomsg)
   test_passed(277) = test_passed(277) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%cfill_mode == 1_I4P
   if (test_passed(277)) then
      svg = read_text('foresight_script_test_cf.svg')
      svg = svg(index(svg, 'fs-crisp'):)
      n = 0_I4P
      k = index(svg, '<path fill=')
      do while (k > 0)
         n = n + 1_I4P
         svg = svg(k + 1:)
         k = index(svg, '<path fill=')
      enddo
      test_passed(277) = n == 27_I4P
   endif
   call interpreter%run_text("set contourfill auto 3; set contourfill firstlinetype 3; replot", iostat, iomsg)
   test_passed(277) = test_passed(277) .and. iostat == 0_I4P
   if (test_passed(277)) then
      svg = read_text('foresight_script_test_cf.svg')
      test_passed(277) = index(svg, 'fill="#56b4e9"') > 0 .and. index(svg, 'fill="#6801dd"') == 0
   endif
   call interpreter%run_text("unset contourfill; set contourfill auto 3; set view map; replot", iostat, iomsg)
   test_passed(277) = test_passed(277) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%cfill_lt == -1_I4P
   if (test_passed(277)) test_passed(277) = index(read_text('foresight_script_test_cf.svg'), &
                                                'd="M0,1 0,0.5 0,0.5 0.5,0.666667 0.5,1Z"') > 0
   call interpreter%run_text("set contourfill bogus", iostat, iomsg)
   test_passed(277) = test_passed(277) .and. iostat /= 0_I4P
   ! pm3d's default clip z
   call interpreter%run_text("set view 60,30; set zrange [1:8]"//nl// &
                             "splot $g using 1:2:3 with pm3d notitle", iostat, iomsg)
   test_passed(277) = test_passed(277) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%pm3d%clip_z
   if (test_passed(277)) then
      svg = read_text('foresight_script_test_cf.svg')
      test_passed(277) = index(svg, 'fill="#c13000" stroke="none" vector-effect="non-scaling-stroke" '// &
                                   'd="M0.404417,0.191925 0.273833,0.409275 0.5,0.4292 0.630567,0.21185Z"') > 0 .and. &
                        index(svg, 'fill="#eca100" stroke="none" vector-effect="non-scaling-stroke" '// &
                                   'd="M0.630567,0.21185 0.5,0.4292 0.726167,0.3332 0.726167,0.3332 0.74365,0.202475Z"') &
                        > 0
   endif
   call interpreter%run_text("set pm3d clip4in", iostat, iomsg)
   test_passed(277) = test_passed(277) .and. iostat == 0_I4P .and. .not. interpreter%figure%panels(1)%pm3d%clip_z
   ! set tics options turn the x and y ticks on again
   call interpreter%run_text("unset xtics; unset ytics; set tics scale 0", iostat, iomsg)
   test_passed(277) = test_passed(277) .and. iostat == 0_I4P .and. &
                     interpreter%figure%panels(1)%xaxis%tics%mode /= TICS_NONE .and. &
                     interpreter%figure%panels(1)%yaxis%tics%mode /= TICS_NONE
endblock



! `with zerrorfill`, gnuplot 6.0's plot3d_zerrorfill (probed on its svg, 600 x 400): a quadrangle from the low to the
! high ends between each two points (x:y:z:dz, or x:y:z:zlow:zhigh), in the fill color (164.30,212.65 164.30,176.60
! 254.77,138.11 254.77,210.24 in rgb(255,215,0)), the line through z in the line color, the key sample the fill and the
! line; `fc lt N` the color of linetype N; `set wall` the walls y0, x0, z0 as gnuplot's (half transparent, in its
! colors, back or front as they face: x0 at 85.96,235.19 242.65,154.05 242.65,45.85 85.96,127), `border -1` black,
! `unset wall`; `set grid z` at the major z ticks only, `mz` the minor ones
block
   character(len=:), allocatable :: svg  !< Page.
   character(len=:), allocatable :: pts  !< The points datablock.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   pts = "$z << EOD"//nl//"1 1 3 0.5"//nl//"2 1 4 1"//nl//"3 1 2 0.5"//nl//"4 1 5 1"//nl//"EOD"//nl
   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_ze.svg'"//nl//pts// &
                             "set xyplane 0"//nl//"splot $z using 1:2:3:4 with zerrorfill lt 7 fc 'gold' title 'err'", &
                             iostat, iomsg)
   test_passed(278) = iostat == 0_I4P
   if (test_passed(278)) then
      svg = read_text('foresight_script_test_ze.svg')
      test_passed(278) = index(svg, 'fill="#ffd700" stroke="none" vector-effect="non-scaling-stroke" '// &
                                   'd="M0.273833,0.531625 0.273833,0.4415 0.424617,0.345275 0.424617,0.5256Z"') > 0 .and. &
                        index(svg, 'stroke="#e51e10"') > 0
   endif
   call interpreter%run_text("splot $z using 1:2:3:($3-$4):($3+$4) with zerrorf fc lt 3 notitle", iostat, iomsg)
   test_passed(278) = test_passed(278) .and. iostat == 0_I4P
   if (test_passed(278)) then
      svg = read_text('foresight_script_test_ze.svg')
      test_passed(278) = index(svg, 'fill="#56b4e9" stroke="none" vector-effect="non-scaling-stroke" '// &
                                   'd="M0.273833,0.531625 0.273833,0.4415 0.424617,0.345275 0.424617,0.5256Z"') > 0
   endif
   call interpreter%run_text("splot $z using 1:2:3 with zerrorfill", iostat, iomsg)
   test_passed(278) = test_passed(278) .and. iostat /= 0_I4P
   ! the grid walls
   call interpreter%run_text("set xyplane relative 0.5; set wall"//nl//"splot x*y notitle", iostat, iomsg)
   test_passed(278) = test_passed(278) .and. iostat == 0_I4P .and. count(interpreter%figure%panels(1)%wall_on) == 3
   if (test_passed(278)) then
      svg = read_text('foresight_script_test_ze.svg')
      test_passed(278) = index(svg, '<path fill="#228b22" fill-opacity="0.5" stroke="none" '// &
                                   'd="M85.96,235.19 242.65,154.05 242.65,45.85 85.96,127 85.96,235.19Z"') > 0 .and. &
                        index(svg, 'fill="#228b22"') < index(svg, 'fill="#a0b6cd"') .and. &
                        index(svg, 'fill="#a0b6cd"') < index(svg, 'fill="#cdb79e"')
   endif
   call interpreter%run_text("set wall x1 fs transparent solid 0.5 border -1 fc 'red'", iostat, iomsg)
   test_passed(278) = test_passed(278) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%wall_on(4) .and. &
                     interpreter%figure%panels(1)%walls(4)%style%border
   if (test_passed(278)) test_passed(278) = interpreter%figure%panels(1)%walls(4)%style%border_color == 'black'
   call interpreter%run_text("set wall q0", iostat, iomsg)
   test_passed(278) = test_passed(278) .and. iostat /= 0_I4P
   call interpreter%run_text("unset wall", iostat, iomsg)
   test_passed(278) = test_passed(278) .and. iostat == 0_I4P .and. .not. any(interpreter%figure%panels(1)%wall_on)
   ! the z grid at the major ticks, mz at the minor ones
   call interpreter%run_text("set grid z", iostat, iomsg)
   test_passed(278) = test_passed(278) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%view3d%grid_z .and. &
                     .not. interpreter%figure%panels(1)%view3d%grid_mz
   call interpreter%run_text("set grid mz", iostat, iomsg)
   test_passed(278) = test_passed(278) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%view3d%grid_mz
endblock



! `splot with boxes`, gnuplot 6.0's plot3d_boxes (probed on its svg, 600 x 400, view 59, 24): a front face from z = 0
! to each height, x the box width about the point (189.29,273.74 189.29,193.42 225.08,198.33 225.08,278.65 in
! rgb(148,0,211)); `set boxdepth 0.6` the back, sides and top too, `fc rgb variable` lit by `set pm3d lighting`
! (gnuplot's illuminate_one_quadrangle: rgb(14,61,59) first), sorted by their base with `depthorder base`; `set boxdepth
! square`, `unset boxdepth`; `set xtics 0,1,4 add ("" 0)` the ticks then the list added
block
   character(len=:), allocatable :: svg  !< Page.
   character(len=:), allocatable :: pts  !< The points datablock.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   pts = "$b << EOD"//nl//"1 2"//nl//"2 4"//nl//"3 3"//nl//"EOD"//nl
   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_bx.svg'"//nl//pts// &
                             "set boxwidth 0.5 abs; set xyplane at 0; set yrange [0:3]; set xrange [0:4]"//nl// &
                             "set view 59, 24; set style fill solid 1.0 border lc black"//nl// &
                             "splot $b using 1:(1):2 with boxes notitle", iostat, iomsg)
   test_passed(279) = iostat == 0_I4P
   if (test_passed(279)) then
      svg = read_text('foresight_script_test_bx.svg')
      test_passed(279) = index(svg, 'fill="#9400d3" stroke="black" stroke-width="1" stroke-linejoin="miter" '// &
                                   'vector-effect="non-scaling-stroke" d="M0.315483,0.68435 0.315483,0.48355 '// &
                                   '0.375133,0.495825 0.375133,0.696625Z"') > 0
   endif
   call interpreter%run_text("set boxdepth 0.6; set pm3d lighting; set pm3d depthorder base"//nl// &
                             "splot $b using 1:(1):2:($1*1000000) with boxes fc rgb variable notitle", iostat, iomsg)
   test_passed(279) = test_passed(279) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%boxdepth == 0.6_R8P
   if (test_passed(279)) then
      svg = read_text('foresight_script_test_bx.svg')
      test_passed(279) = index(svg, 'fill="#0e3d3b" stroke="black" stroke-width="1" stroke-linejoin="miter" '// &
                                    'vector-effect="non-scaling-stroke" '// &
                                   'd="M0.336733,0.662325 0.336733,0.461525 0.396383,0.4738 0.396383,0.674575Z"') > 0
   endif
   call interpreter%run_text("set boxdepth square", iostat, iomsg)
   test_passed(279) = test_passed(279) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%boxdepth == -1.0_R8P
   call interpreter%run_text("unset boxdepth", iostat, iomsg)
   test_passed(279) = test_passed(279) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%boxdepth == 0.0_R8P
   call interpreter%run_text("set xtics 0,1,4 offset 0,-0.5 add ('' 0)", iostat, iomsg)
   test_passed(279) = test_passed(279) .and. iostat == 0_I4P .and. interpreter%figure%panels(1)%xaxis%tics%mode == TICS_FIXED
endblock



! 3D polygons, gnuplot 6.0's (probed on its svg, 600 x 400): `set object N polygon depthorder` sorted with the pm3d
! quadrangles (`set pm3d depthorder`), closed, outlined by `set pm3d border`, `fc ls N` line style N+1's color on the
! back (rgb(255,192,32) of goldenrod on object 2), each in its fill style (object 2 half transparent); `splot ... with
! polygons` a polygon per block, a triangle a quadrangle with its first corner again, lit by `set pm3d lighting`
! (rgb(95,95,95)); the depth queue in runs of one style; `set object N polygon` options without vertices (accepted,
! nothing drawn), `fs pattern EXPR`; `unset tics` the z ticks too; `set linetype N lc palette frac F` the palette color
block
   character(len=:), allocatable :: svg  !< Page.
   character(len=:), allocatable :: pts  !< The polygons datablock.
   character(len=1), parameter   :: nl = new_line('a') !< New line.

   pts = "$P << EOD"//nl//"0 0 1"//nl//"1 0 1"//nl//"1 1 1.5"//nl//nl//"0 1 0"//nl//"1 1 0"//nl//"1 2 0.5"//nl// &
         "0 2 0.5"//nl//"EOD"//nl
   call interpreter%init(scratch)
   call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_script_test_pg.svg'"//nl//pts// &
                             "set style line 101 lc 'forest-green'; set style line 102 lc 'goldenrod'"//nl// &
                             "set obj 1 polygon from 0,0,0 to 1,0,0 to 0,1,1 depthorder fs solid fc ls 101"//nl// &
                             "set obj 2 polygon from 0,0,0 to 0,1,1 to 1,0,0 depthorder fs transparent solid 0.5 "// &
                             "fc ls 101"//nl//"set pm3d depthorder border lc 'black' lw 2"//nl// &
                             "set xrange [-1:2]; set yrange [-1:2]; set zrange [-1:2]; set pm3d lighting"//nl// &
                             "splot $P with polygons fc 'gray75' notitle", iostat, iomsg)
   test_passed(280) = iostat == 0_I4P .and. trim(interpreter%figure%panels(1)%objects(1)%layer) == 'depth'
   if (test_passed(280)) then
      svg = read_text('foresight_script_test_pg.svg')
      test_passed(280) = index(svg, '<path fill="#5f5f5f" stroke="black" stroke-width="2" stroke-linejoin="miter" '// &
                                   'vector-effect="non-scaling-stroke" d="M0.46815,0.401625 0.6189,0.440675 '// &
                                   '0.705967,0.327975 0.555183,0.288925Z"') > 0 .and. &
                        index(svg, '<path fill="#ffc020" fill-opacity="0.5" stroke="black" stroke-width="2" '// &
                                   'stroke-linejoin="miter" vector-effect="non-scaling-stroke" d="M0.3811,0.46925 '// &
                                   '0.46815,0.311475 0.53185,0.508275 0.3811,0.46925Z"') > 0 .and. &
                        index(svg, '<path fill="#228b22" stroke="black" stroke-width="2" stroke-linejoin="miter" '// &
                                   'vector-effect="non-scaling-stroke" d="M0.3811,0.46925 0.53185,0.508275 '// &
                                   '0.46815,0.311475 0.3811,0.46925Z"') > 0
      test_passed(280) = test_passed(280) .and. index(svg, '#ffc020') < index(svg, '#228b22')
   endif
   ! options without vertices: accepted; a pattern given by an expression
   call interpreter%run_text("o = 3"//nl//"set obj 9 polygon depthorder fs transparent pattern o fc 'red'", iostat, &
                             iomsg)
   test_passed(280) = test_passed(280) .and. iostat == 0_I4P
   call interpreter%run_text("set obj 2 polygon depthorder fs transparent pattern o", iostat, iomsg)
   test_passed(280) = test_passed(280) .and. iostat == 0_I4P .and. &
                     allocated(interpreter%figure%panels(1)%objects(2)%points)
   if (test_passed(280)) test_passed(280) = interpreter%figure%panels(1)%objects(2)%style%pattern == 3_I4P .and. &
                                          size(interpreter%figure%panels(1)%objects(2)%points) == 3
   ! unset tics: the z ticks too; a linetype in a palette fraction
   call interpreter%run_text("unset tics", iostat, iomsg)
   test_passed(280) = test_passed(280) .and. iostat == 0_I4P .and. &
                     interpreter%figure%panels(1)%zaxis%tics%mode == TICS_NONE
   call interpreter%run_text("set palette defined (0 'black', 1 'white')"//nl//"i = 2"//nl// &
                             "set linetype 77 lc palette frac i/4.", iostat, iomsg)
   test_passed(280) = test_passed(280) .and. iostat == 0_I4P
endblock

if (all(test_passed)) then
   open(newunit=unit, file=output)
   close(unit, status='delete')
   open(newunit=unit, file=options)
   close(unit, status='delete')
   open(newunit=unit, file=y2)
   close(unit, status='delete')
endif
write(output_unit, '(A,250L2)') 'foresight_script checks:', test_passed
do i = 1, size(test_passed)
   if (.not. test_passed(i)) write(error_unit, '(A,I0)') 'failed check ', i
enddo
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1

contains
   function baseline(svg, at) result(y)
   !< The `y` attribute of the SVG `<text>` element holding position `at` of `svg`.
   character(len=*), intent(in) :: svg  !< SVG.
   integer(I4P),     intent(in) :: at   !< Position inside the element.
   real(R8P)                    :: y    !< Baseline.
   integer(I4P)                 :: open !< Element start.
   integer(I4P)                 :: q    !< Value start.
   integer(I4P)                 :: ios  !< Read status.

   y = -1.0_R8P
   open = index(svg(:at), '<text', back=.true.)
   if (open == 0_I4P) return
   q = index(svg(open:at), ' y="')
   if (q == 0_I4P) return
   q = open + q + 3_I4P
   read(svg(q:q + index(svg(q:), '"') - 2), *, iostat=ios) y
   if (ios /= 0_I4P) y = -1.0_R8P
   endfunction baseline

   function text_of_file(file) result(text)
   !< The whole text of `file`, its lines joined.
   character(len=*), intent(in)  :: file !< File.
   character(len=:), allocatable :: text !< Text.
   character(len=4096)           :: line !< A line.
   integer                       :: unit !< Unit.
   integer                       :: ios  !< Read status.

   text = ''
   open(newunit=unit, file=file, action='read', status='old', iostat=ios)
   if (ios /= 0) return
   do
      read(unit, '(A)', iostat=ios) line
      if (ios /= 0) exit
      text = text//trim(line)//new_line('a')
   enddo
   close(unit)
   endfunction text_of_file

   function series_polylines(file) result(count)
   !< The polylines of the first series of the SVG `file` (inside its `fs-series` group).
   character(len=*), intent(in)  :: file  !< SVG file.
   integer(I4P)                  :: count !< Polylines.
   character(len=4096)           :: line  !< A line.
   logical                       :: in    !< Inside the series group.
   integer                       :: unit  !< Unit.
   integer                       :: ios   !< Read status.

   count = 0_I4P
   in = .false.
   open(newunit=unit, file=file, action='read', status='old', iostat=ios)
   if (ios /= 0) return
   do
      read(unit, '(A)', iostat=ios) line
      if (ios /= 0) exit
      if (index(line, 'class="fs-series"') > 0) in = .true.
      if (in .and. index(line, '<polyline') > 0) count = count + 1_I4P
      if (in .and. index(line, '</g>') > 0) exit
   enddo
   close(unit)
   endfunction series_polylines

   pure function count_text(text, part) result(n)
   !< Occurrences of `part` in `text`.
   character(len=*), intent(in) :: text !< Text.
   character(len=*), intent(in) :: part !< Part sought.
   integer(I4P)                 :: n    !< Occurrences.
   integer(I4P)                 :: k    !< Search start.
   integer(I4P)                 :: at   !< Position found.

   n = 0_I4P
   k = 1_I4P
   do
      at = index(text(k:), part)
      if (at == 0) exit
      n = n + 1_I4P
      k = k + at - 1_I4P + len(part)
      if (k > len(text)) exit
   enddo
   endfunction count_text

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

   pure function matches(values, expected) result(equal)
   !< Whether `values` equal the integers `expected` to rounding (no NaN convention: -1 is -1).
   real(R8P), intent(in) :: values(:)   !< Values.
   integer,   intent(in) :: expected(:) !< Expected values.
   logical               :: equal       !< Equal.

   equal = size(values) == size(expected)
   if (equal) equal = all(abs(values - real(expected, R8P)) <= 1.0e-12_R8P * max(1.0_R8P, abs(real(expected, R8P))))
   endfunction matches

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

   function same_file(file, reference) result(ok)
   !< Whether `file` and `reference` hold the same lines.
   character(len=*), intent(in) :: file      !< Text file.
   character(len=*), intent(in) :: reference !< Reference file.
   logical                      :: ok        !< Same lines.
   character(len=500)           :: a         !< Line of the file.
   character(len=500)           :: b         !< Line of the reference.
   integer(I4P)                 :: u         !< File unit.
   integer(I4P)                 :: v         !< Reference unit.
   integer(I4P)                 :: ios(2)    !< I/O status.

   ok = .false.
   open(newunit=u, file=file, action='read', iostat=ios(1))
   open(newunit=v, file=reference, action='read', iostat=ios(2))
   if (all(ios == 0_I4P)) then
      do
         read(u, '(A)', iostat=ios(1)) a
         read(v, '(A)', iostat=ios(2)) b
         if (any(ios /= 0_I4P)) exit
         if (a /= b) exit
      enddo
      ok = all(ios /= 0_I4P)
   endif
   close(u)
   close(v)
   endfunction same_file

   function file_has(file, text) result(ok)
   !< Whether `file` holds `text` (on one line).
   character(len=*), intent(in) :: file !< Text file.
   character(len=*), intent(in) :: text !< Text looked for.
   logical                      :: ok   !< Found.
   character(len=4000)          :: line !< Line read.
   integer(I4P)                 :: u    !< Unit.
   integer(I4P)                 :: ios  !< I/O status.

   ok = .false.
   open(newunit=u, file=file, action='read', iostat=ios)
   if (ios /= 0_I4P) return
   do
      read(u, '(A)', iostat=ios) line
      if (ios /= 0_I4P) exit
      if (index(line, text) > 0) then
         ok = .true.
         exit
      endif
   enddo
   close(u)
   endfunction file_has

   function file_is(file, lines) result(ok)
   !< Whether `file` holds exactly `lines` (trailing blanks of each ignored).
   character(len=*), intent(in) :: file     !< Text file.
   character(len=*), intent(in) :: lines(:) !< Expected lines.
   logical                      :: ok       !< Same lines.
   character(len=500)           :: line     !< Line read.
   integer(I4P)                 :: u        !< Unit.
   integer(I4P)                 :: ios      !< I/O status.
   integer(I4P)                 :: k        !< Lines read.

   ok = .false.
   open(newunit=u, file=file, action='read', iostat=ios)
   if (ios /= 0_I4P) return
   k = 0_I4P
   do
      read(u, '(A)', iostat=ios) line
      if (ios /= 0_I4P) exit
      k = k + 1_I4P
      if (k > size(lines, kind=I4P)) exit
      if (trim(line) /= trim(lines(k))) exit
   enddo
   close(u)
   ok = ios /= 0_I4P .and. k == size(lines, kind=I4P)
   endfunction file_is

   subroutine values(names, v, ok)
   !< The values `v` of the script variables `names` (8 characters, the leading ones of longer names: FIT_NITER is
   !< FIT_NITE), `ok` if all exist.
   character(len=*), intent(in)  :: names(:) !< Names.
   real(R8P),        intent(out) :: v(:)     !< Values.
   logical,          intent(out) :: ok       !< All found.
   character(len=*), parameter   :: FULL(3) = [character(len=13) :: 'FIT_NITER', 'FIT_CONVERGED', 'FIT_NDF'] !< Long.
   character(len=:), allocatable :: name     !< Full name.
   logical                       :: found    !< Found.
   integer(I4P)                  :: j        !< Counter.

   ok = .true.
   do j = 1_I4P, size(names, kind=I4P)
      name = trim(names(j))
      if (name == 'FIT_NITE') name = trim(FULL(1))
      if (name == 'FIT_CONV') name = trim(FULL(2))
      call interpreter%symbols%value_of(name, v(j), found)
      if (.not. found) v(j) = 0.0_R8P
      ok = ok .and. found
   enddo
   endsubroutine values

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
