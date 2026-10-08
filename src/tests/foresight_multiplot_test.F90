!< foresight multiplot, error bars and dumb terminal test: byte-exact references and error reporting.
program foresight_multiplot_test
!< foresight multiplot, error bars and dumb terminal test: byte-exact references and error reporting.
!<
!< Run from the repository root; `FORESIGHT_UPDATE_GOLDEN=1` rewrites the reference files.
use, intrinsic :: iso_fortran_env, only : error_unit, output_unit
use foresight, only : I4P, R8P, script_object

implicit none
character(len=*), parameter   :: data_file = 'foresight_multiplot_test.dat' !< Test data file.
character(len=*), parameter   :: golden    = 'src/tests/golden/'            !< Reference files directory.
type(script_object)           :: interpreter                                !< Interpreter.
character(len=:), allocatable :: iomsg                                      !< Error message.
character(len=:), allocatable :: multiplot                                  !< Multiplot script body.
character(len=8)              :: update_flag                                !< FORESIGHT_UPDATE_GOLDEN value.
logical                       :: update                                     !< Rewrite the references.
integer(I4P)                  :: iostat                                     !< Status.
integer(I4P)                  :: unit                                       !< File unit.
integer(I4P)                  :: i                                          !< Counter.
logical                       :: test_passed(13)                            !< Per-check outcome.

call get_environment_variable('FORESIGHT_UPDATE_GOLDEN', update_flag)
update = trim(update_flag) == '1'
test_passed = .false.
open(newunit=unit, file=data_file, action='write', status='replace')
write(unit, '(A)') '# iteration  residual  cd  dcd'
do i = 1, 12
   write(unit, '(I0,3(1X,ES24.16E3))') i, 10.0_R8P**(-0.3_R8P * i), 1.0_R8P + 0.1_R8P / real(i, R8P), 0.02_R8P * i
enddo
close(unit)

! two panels: settings carry over, the lazy advance keeps panel 1 untouched by the settings of panel 2
multiplot = "set multiplot layout 1,2 title 'Monitor'"//new_line('a')// &
            "set title 'residual'; set logscale y"//new_line('a')// &
            "plot '"//data_file//"' u 1:2 w l t 'res'"//new_line('a')// &
            "set title 'drag'; unset logscale y"//new_line('a')// &
            "plot '"//data_file//"' u 1:3:4 w yerrorbars t 'cd'"//new_line('a')// &
            "unset multiplot"//new_line('a')
call interpreter%init('x.html')
call interpreter%run_text("set terminal svg size 700,350; set output 'foresight_multiplot_test.svg'"//new_line('a')// &
                          multiplot, iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(1) = iostat == 0_I4P .and. check('multiplot.svg', 'foresight_multiplot_test.svg')

call interpreter%init('x.html')
call interpreter%run_text("set terminal html size 700,350; set output 'foresight_multiplot_test.html'"// &
                          new_line('a')//multiplot, iostat, iomsg)
test_passed(2) = iostat == 0_I4P .and. check('multiplot.html', 'foresight_multiplot_test.html')

! dumb terminal to a text file; an unparenthesized expression in using is an error
call interpreter%init('x.html')
call interpreter%run_text("set terminal dumb size 60,20; set output 'foresight_multiplot_test.txt'"//new_line('a')// &
                          "set title 'dumb'; set key"//new_line('a')// &
                          "plot '"//data_file//"' u 1:3 w lp t 'cd', '' u 1:$3 notitle", iostat, iomsg)
test_passed(3) = iostat /= 0_I4P
call interpreter%run_text("plot '"//data_file//"' u 1:3 w lp t 'cd', '' u 1:3:4 w yerr notitle", iostat, iomsg)
test_passed(4) = iostat == 0_I4P .and. check('dumb.txt', 'foresight_multiplot_test.txt')

! dumb terminal defaults to standard output
call interpreter%init('x.html')
call interpreter%execute('set terminal dumb', iostat, iomsg)
test_passed(5) = interpreter%output == '-'

! errors: full layout, error bar columns
call interpreter%init('x.svg')
call interpreter%run_text("set multiplot layout 1,1"//new_line('a')//"plot '"//data_file//"'"//new_line('a')// &
                          "plot '"//data_file//"'", iostat, iomsg)
test_passed(6) = iostat /= 0_I4P .and. index(iomsg, 'multiplot: the layout is full') > 0
call interpreter%init('x.svg')
call interpreter%run_text("plot '"//data_file//"' u 1:2 w yerrorbars", iostat, iomsg)
test_passed(7) = iostat /= 0_I4P .and. index(iomsg, 'needs using x:y:delta') > 0

! manual multiplot: a main plot and an inset in their origin/size boxes, below the title
call interpreter%init('x.html')
call interpreter%run_text("set terminal svg size 600,400; set output 'foresight_multiplot_test_inset.svg'"// &
                          new_line('a')//"set multiplot title 'inset'"//new_line('a')// &
                          "plot '"//data_file//"' u 1:3 w l t 'cd'"//new_line('a')// &
                          "set origin 0.35,0.35; set size 0.55,0.5; unset key; set logscale y"//new_line('a')// &
                          "plot '"//data_file//"' u 1:2 w lp"//new_line('a')//"unset multiplot", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(8) = iostat == 0_I4P .and. check('inset.svg', 'foresight_multiplot_test_inset.svg')

! origin and size: not with a layout, positive sizes, restored by the bare commands
call interpreter%init('x.svg')
call interpreter%run_text("set multiplot layout 1,2"//new_line('a')//"set origin 0.1,0.1", iostat, iomsg)
test_passed(9) = iostat /= 0_I4P .and. index(iomsg, 'set origin: not supported with a multiplot layout') > 0
call interpreter%init('x.svg')
call interpreter%run_text("set size 0,1", iostat, iomsg)
test_passed(10) = iostat /= 0_I4P .and. index(iomsg, 'the size must be positive') > 0
call interpreter%run_text("set size 0.5,0.5; set origin 0.5,0.5; set size; set origin", iostat, iomsg)
test_passed(11) = iostat == 0_I4P .and. all(interpreter%figure%panels(1)%size == 1.0_R8P) .and. &
                  all(interpreter%figure%panels(1)%origin == 0.0_R8P)

! key placements: beside the plot (with a second y axis), on the left aligned to the bottom, rows below (wrapping in a
! narrow panel) and above
call interpreter%init('x.html')
call interpreter%run_text("set terminal svg size 900,600; set output 'foresight_multiplot_test_keys.svg'"// &
                          new_line('a')//"set multiplot layout 2,2"//new_line('a')// &
                          "set key outside; set y2tics; plot x t 'alpha', -x t 'beta' axes x1y2, 2*x t 'gamma'"// &
                          new_line('a')//"unset y2tics; set key outside left bottom box; set ylabel 'y'"// &
                          new_line('a')//"plot x t 'alpha', -x t 'beta', 2*x t 'gamma'"//new_line('a')// &
                          "set key below; set xlabel 'x'; plot x t 'alpha', -x t 'beta', 2*x t 'gamma', 3*x t 'delta', "// &
                          "4*x t 'epsilon'"//new_line('a')// &
                          "set key above box; set title 'title'; plot x t 'alpha', -x t 'beta'"//new_line('a')// &
                          "unset multiplot", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
test_passed(12) = iostat == 0_I4P .and. check('keys.svg', 'foresight_multiplot_test_keys.svg')
! the key words: below/above set rows, inside keeps them, outside centred both ways stays inside
call interpreter%init('x.svg')
call interpreter%run_text('set key below left; set key inside', iostat, iomsg)
associate(panel => interpreter%figure%panels(1))
   test_passed(13) = iostat == 0_I4P .and. panel%key_horizontal .and. .not. panel%key_outside .and. &
                     panel%key_margin == '' .and. panel%key_h == 'left'
endassociate

open(newunit=unit, file=data_file)
close(unit, status='delete')
! the full-layout case rendered its first panel before failing
open(newunit=unit, file='x.svg')
close(unit, status='delete')
write(output_unit, '(A,13L2)') 'foresight multiplot checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1

contains
   function check(name, output) result(passed)
   !< Compare `output` with the reference `name` (or rewrite it in update mode); remove `output` when matching.
   character(len=*), intent(in)  :: name     !< Reference file name.
   character(len=*), intent(in)  :: output   !< Rendered file.
   logical                       :: passed   !< Rendering matches the reference.
   character(len=:), allocatable :: produced !< Rendered content.
   logical                       :: exists   !< Reference exists.
   integer(I4P)                  :: u        !< File unit.

   produced = read_text(output)
   if (update) then
      open(newunit=u, file=golden//name, access='stream', form='unformatted', action='write', status='replace')
      write(u) produced
      close(u)
      write(output_unit, '(A)') 'updated '//golden//name
      passed = .true.
   else
      inquire(file=golden//name, exist=exists)
      passed = .false.
      if (exists) passed = produced == read_text(golden//name)
      if (.not. passed) write(error_unit, '(A)') output//' differs from '//golden//name// &
                                                 ' (FORESIGHT_UPDATE_GOLDEN=1 rewrites it)'
   endif
   if (passed) then
      open(newunit=u, file=output)
      close(u, status='delete')
   endif
   endfunction check

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
endprogram foresight_multiplot_test
