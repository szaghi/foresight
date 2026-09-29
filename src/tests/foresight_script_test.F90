!< foresight_script test: a gnuplot script rendered byte-exact, `using` expressions, and unsupported constructs
!< reported as errors.
program foresight_script_test
!< foresight_script test: a gnuplot script rendered byte-exact, `using` expressions, and unsupported constructs
!< reported as errors.
!<
!< Run from the repository root; `FORESIGHT_UPDATE_GOLDEN=1` rewrites the reference file.
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan
use, intrinsic :: iso_fortran_env, only : error_unit, output_unit
use foresight, only : I4P, R8P, script_object

implicit none
character(len=*), parameter   :: data_file = 'foresight_script_test.dat'   !< Test data file.
character(len=*), parameter   :: output    = 'foresight_script_test.svg'   !< Rendered file.
character(len=*), parameter   :: golden    = 'src/tests/golden/script.svg' !< Reference file.
character(len=*), parameter   :: scratch   = 'foresight_script_test_expressions.svg' !< Expression plots.
type(script_object)           :: interpreter                               !< Interpreter.
character(len=:), allocatable :: iomsg                                     !< Error message.
character(len=:), allocatable :: script                                    !< Script text.
character(len=8)              :: update_flag                               !< FORESIGHT_UPDATE_GOLDEN value.
integer(I4P)                  :: iostat                                    !< Status.
integer(I4P)                  :: unit                                      !< File unit.
integer(I4P)                  :: i                                         !< Counter.
logical                       :: test_passed(12)                           !< Per-check outcome.

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
test_passed(2) = matches_golden()

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
call interpreter%run_text('plot sin(x)', iostat, iomsg)
test_passed(7) = iostat /= 0_I4P .and. index(iomsg, 'functions and expressions are not supported') > 0
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

open(newunit=unit, file=data_file)
close(unit, status='delete')
if (all(test_passed)) then
   open(newunit=unit, file=output)
   close(unit, status='delete')
endif
write(output_unit, '(A,12L2)') 'foresight_script checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1

contains
   function matches_golden() result(passed)
   !< Compare the rendered file with the reference, or rewrite the reference in update mode.
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
