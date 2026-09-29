!< foresight golden test: rendered SVG must match the reference files byte-for-byte.
program foresight_golden_test
!< foresight golden test: rendered SVG must match the reference files byte-for-byte.
!<
!< Run from the repository root. `FORESIGHT_UPDATE_GOLDEN=1` rewrites the references instead: inspect the rendering
!< before committing them.
use, intrinsic :: ieee_arithmetic, only : ieee_quiet_nan, ieee_value
use, intrinsic :: iso_fortran_env, only : error_unit, output_unit
use foresight, only : figure_object, I4P, R8P

implicit none
character(len=*), parameter :: GOLDEN_DIR = 'src/tests/golden/' !< Reference files directory.
character(len=8)            :: update_flag                      !< FORESIGHT_UPDATE_GOLDEN value.
logical                     :: update                           !< Rewrite the references.
logical                     :: test_passed(3)                   !< Per-figure outcome.

call get_environment_variable('FORESIGHT_UPDATE_GOLDEN', update_flag)
update = trim(update_flag) == '1'
test_passed(1) = check('lines', figure_lines())
test_passed(2) = check('semilogy', figure_semilogy())
test_passed(3) = check('points_reversed', figure_points_reversed())
write(output_unit, '(A,3L2)') 'foresight golden checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1

contains
   function figure_lines() result(fig)
   !< Two curves, a dashed one, title and axis labels; both axes autoscaled.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   x = [(8.0_R8P * atan(1.0_R8P) * real(i, R8P) / 100.0_R8P, i = 0, 100)]
   call fig%set_title('Trigonometric functions')
   call fig%set_xlabel('x [rad]')
   call fig%set_ylabel('f(x)')
   call fig%plot(x, sin(x), title='sin(x)')
   call fig%plot(x, cos(x), title='cos(x)', dt=2_I4P)
   endfunction figure_lines

   function figure_semilogy() result(fig)
   !< Log y axis with grid; a NaN and a zero residual break the line, a sparse series with points.
   type(figure_object)    :: fig    !< Figure.
   real(R8P), allocatable :: it(:)  !< Iterations.
   real(R8P), allocatable :: res(:) !< Residuals.
   real(R8P), allocatable :: it2(:) !< Sparse iterations.
   integer(I4P)           :: i      !< Counter.

   it = [(real(i, R8P), i = 1, 60)]
   res = 10.0_R8P**(-0.1_R8P * it) * (1.0_R8P + 0.3_R8P * sin(it))
   res(20) = ieee_value(1.0_R8P, ieee_quiet_nan)
   res(35) = 0.0_R8P
   it2 = [(real(i, R8P), i = 5, 60, 5)]
   call fig%set_title('Convergence history')
   call fig%set_xlabel('iteration')
   call fig%set_ylabel('residual')
   call fig%set_logscale('y')
   call fig%set_grid
   call fig%plot(it, res, title='continuity')
   call fig%plot(it2, 10.0_R8P**(-0.08_R8P * it2), title='momentum', with='linespoints', lw=2.0_R8P)
   endfunction figure_semilogy

   function figure_points_reversed() result(fig)
   !< Points on a reversed x range, y end fixed and start autoscaled, no key, label needing XML escapes.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   call fig%init(width=400_I4P, height=300_I4P)
   x = [(0.5_R8P * real(i, R8P), i = 0, 20)]
   call fig%set_xlabel('<T> & "q"')
   call fig%set_xrange(min=10.0_R8P, max=0.0_R8P)
   call fig%set_yrange(max=1.0_R8P)
   call fig%set_key(.false.)
   call fig%plot(x, x**2 / 100.0_R8P, title='parabola', with='points', ps=1.5_R8P)
   endfunction figure_points_reversed

   function check(name, fig) result(passed)
   !< Render `fig` and compare it with its reference file, or rewrite the reference in update mode.
   character(len=*),    intent(in)    :: name     !< Figure name.
   type(figure_object), intent(in)    :: fig      !< Figure.
   logical                            :: passed   !< Rendering matches the reference.
   type(figure_object)                :: figure   !< Figure being rendered (rendering updates its ticks).
   character(len=:), allocatable      :: output   !< Rendered file.
   character(len=:), allocatable      :: golden   !< Reference file.
   character(len=:), allocatable      :: produced !< Rendered content.
   logical                            :: exists   !< Reference exists.
   integer(I4P)                       :: unit     !< File unit.

   output = 'foresight_golden_'//name//'.svg'
   golden = GOLDEN_DIR//name//'.svg'
   figure = fig
   call figure%save(output)
   produced = read_text(output)
   if (update) then
      open(newunit=unit, file=golden, access='stream', form='unformatted', action='write', status='replace')
      write(unit) produced
      close(unit)
      write(output_unit, '(A)') 'updated '//golden
      passed = .true.
   else
      inquire(file=golden, exist=exists)
      passed = .false.
      if (exists) passed = produced == read_text(golden)
      if (.not. passed) write(error_unit, '(A)') name//': '//output//' differs from '//golden// &
                                                 ' (FORESIGHT_UPDATE_GOLDEN=1 rewrites it)'
   endif
   if (passed) then
      open(newunit=unit, file=output)
      close(unit, status='delete')
   endif
   endfunction check

   function read_text(file) result(text)
   !< Whole content of `file`.
   character(len=*), intent(in)  :: file  !< File name.
   character(len=:), allocatable :: text  !< Content.
   integer(I4P)                  :: unit  !< File unit.
   integer(I4P)                  :: bytes !< File size [bytes].

   open(newunit=unit, file=file, access='stream', form='unformatted', action='read', status='old')
   inquire(unit=unit, size=bytes)
   allocate(character(len=bytes) :: text)
   read(unit) text
   close(unit)
   endfunction read_text
endprogram foresight_golden_test
