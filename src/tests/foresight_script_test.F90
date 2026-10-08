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
use foresight_style, only : WITH_LINES

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
logical                       :: test_passed(37)                           !< Per-check outcome.

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
call interpreter%run_text('set key outside', iostat, iomsg)
test_passed(18) = iostat /= 0_I4P .and. index(iomsg, 'set key: unsupported option "outside"') > 0
call interpreter%run_text("plot '"//data_file//"' every 0", iostat, iomsg)
test_passed(19) = iostat /= 0_I4P .and. index(iomsg, 'positive increments') > 0
call interpreter%run_text('set style line 1 pt 7', iostat, iomsg)
test_passed(20) = iostat /= 0_I4P .and. index(iomsg, 'set style line: unsupported option "pt"') > 0

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
write(output_unit, '(A,37L2)') 'foresight_script checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1

contains
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
