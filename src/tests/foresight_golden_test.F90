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
logical                     :: test_passed(21)                  !< Per-figure outcome.

call get_environment_variable('FORESIGHT_UPDATE_GOLDEN', update_flag)
update = trim(update_flag) == '1'
test_passed(1) = check('lines.svg', figure_lines())
test_passed(2) = check('semilogy.svg', figure_semilogy())
test_passed(3) = check('points_reversed.svg', figure_points_reversed())
test_passed(4) = check('semilogy.html', figure_semilogy())
test_passed(5) = check('y2_api.svg', figure_y2())
test_passed(6) = check('slopes.txt', figure_slopes())
test_passed(7) = check('point_types.svg', figure_point_types())
test_passed(8) = check('readouts.svg', figure_readouts())
test_passed(9) = check('readouts.txt', figure_readouts())
test_passed(10) = check('readout_mixed.svg', figure_readout_mixed())
test_passed(11) = check('readout_mixed.txt', figure_readout_mixed())
test_passed(12) = check('readout_block.txt', figure_readout_block())
test_passed(13) = check('readout_row.svg', figure_readout_row())
! also the page of the viewer DOM test of readouts (src/js/viewer_dom_test.js)
test_passed(14) = check('readout_mixed.html', figure_readout_mixed())
test_passed(15) = check('boxes.svg', figure_boxes())
test_passed(16) = check('boxes.txt', figure_boxes())
test_passed(17) = check('boxes_relative.svg', figure_boxes_relative())
test_passed(18) = check('fills.svg', figure_fills())
test_passed(19) = check('fills.txt', figure_fills())
test_passed(20) = check('fills_block.txt', figure_fills_block())
! also the page of the viewer DOM test of boxes (src/js/viewer_dom_test.js)
test_passed(21) = check('boxes.html', figure_boxes())
write(output_unit, '(A,21L2)') 'foresight golden checks:', test_passed
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

   function figure_y2() result(fig)
   !< Second y axis through the library API: a log y2 range fixed at both ends, y and x ticks not mirrored.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: t(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   t = [(real(i, R8P), i = 0, 20)]
   call fig%init(width=500_I4P, height=320_I4P)
   call fig%set_xlabel('time')
   call fig%set_ylabel('temperature')
   call fig%set_y2label('pressure')
   call fig%set_xtics(mirror=.false.)
   call fig%set_ytics(mirror=.false.)
   call fig%set_y2tics()
   call fig%set_logscale('y2')
   call fig%set_y2range(min=1.0_R8P, max=1.0e3_R8P)
   call fig%plot(t, 300.0_R8P + 2.0_R8P * t, title='T')
   call fig%plot(t, 10.0_R8P**(0.1_R8P * t + 0.5_R8P), title='p', with='points', axes='x1y2')
   endfunction figure_y2

   function figure_slopes() result(fig)
   !< Text device: segments of every slope; a Bresenham error update once overshot some ends and never stopped.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   ! 60 x 12 characters of the text device
   call fig%init(width=396_I4P, height=180_I4P)
   x = [(real(i, R8P), i = 1, 30)]
   call fig%plot(x, 10.0_R8P**(-0.2_R8P * x), title='decay')
   endfunction figure_slopes

   function figure_point_types() result(fig)
   !< gnuplot point types: stroked, filled, the dot, a type beyond 15 cycling; markers in the key; a reversed y range.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   call fig%init(width=420_I4P, height=300_I4P)
   x = [(real(i, R8P), i = 1, 8)]
   call fig%set_yrange(min=5.0_R8P, max=0.0_R8P)
   call fig%plot(x, 1.0_R8P + 0.1_R8P * x, title='plus', with='points', pt=1_I4P)
   call fig%plot(x, 2.0_R8P + 0.1_R8P * x, title='circle', with='linespoints', pt=7_I4P, lw=2.0_R8P)
   call fig%plot(x, 3.0_R8P + 0.1_R8P * x, title='triangle', with='points', pt=8_I4P, ps=2.0_R8P)
   call fig%plot(x, 4.0_R8P + 0.1_R8P * x, title='pt 27: diamond', with='points', pt=27_I4P)
   call fig%plot(x, 4.5_R8P + 0.0_R8P * x, title='dot', with='points', pt=0_I4P)
   endfunction figure_point_types

   function figure_readouts() result(fig)
   !< Readouts alone: no axes, the digits grow to fill the panel; a NaN last row (the last finite value is shown), a
   !< unit suffix, a value wider than its glass (dashes).
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: it(:) !< Iterations.
   real(R8P), allocatable :: res(:) !< Residuals.
   integer(I4P)           :: i    !< Counter.

   call fig%init(width=420_I4P, height=300_I4P)
   it = [(real(i, R8P), i = 1, 50)]
   res = 10.0_R8P**(-0.1_R8P * it)
   res(50) = ieee_value(1.0_R8P, ieee_quiet_nan)
   call fig%set_title('Run monitor')
   call fig%plot(it, it, title='ITER', with='readout', format='%5.0f')
   call fig%plot(it, res, title='RESIDUAL', with='readout', format='%9.2e')
   call fig%plot(it, 0.05_R8P * it, title='WALL', with='readout', format='%5.2f h')
   call fig%plot(it, 1.0e6_R8P * it, title='OVERFLOW', with='readout', format='%5.1f')
   endfunction figure_readouts

   function figure_readout_mixed() result(fig)
   !< A readout over a curve: outside autoscale and key, in its opaque window at the top left, its own color.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: t(:) !< Times.
   integer(I4P)           :: i    !< Counter.

   call fig%init(width=500_I4P, height=320_I4P)
   t = [(0.05_R8P * real(i, R8P), i = 0, 40)]
   call fig%set_xlabel('time')
   call fig%plot(t, 0.02_R8P * t**2 - 0.003_R8P, title='Cx')
   call fig%plot(t, 1.0e3_R8P + t, title='CX', with='readout', format='%9.2e', lc='#e51e10')
   endfunction figure_readout_mixed

   function figure_readout_block() result(fig)
   !< The mixed readout on the block device with ANSI colors: segments in the series color, the window clearing dots.
   type(figure_object) :: fig !< Figure.

   fig = figure_readout_mixed()
   call fig%set_text(charset='braille', colors='ansi')
   endfunction figure_readout_block

   function figure_readout_row() result(fig)
   !< Readouts in a row at the bottom right, fixed digit size, no window.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   call fig%init(width=500_I4P, height=320_I4P)
   x = [(real(i, R8P), i = 1, 20)]
   call fig%set_readout(position='bottom right horizontal', opaque=.false., size=24.0_R8P)
   call fig%plot(x, sqrt(x), title='sqrt(x)')
   call fig%plot(x, x, title='N', with='readout', format='%3.0f')
   call fig%plot(x, sqrt(x), title='ROOT', with='readout', format='%6.3f')
   endfunction figure_readout_row

   function figure_boxes() result(fig)
   !< Boxes: touching (auto width, uneven x), from y = 0 with a negative value, x autoscaled to the box edges (unlike
   !< gnuplot), y to 0; a second series with its own widths, solid without border; key samples.
   type(figure_object) :: fig !< Figure.

   call fig%init(width=500_I4P, height=320_I4P)
   call fig%set_title('Boxes')
   call fig%plot([1.0_R8P, 2.0_R8P, 4.0_R8P, 5.0_R8P], [3.0_R8P, 5.0_R8P, -2.0_R8P, 4.0_R8P], title='auto', &
                 with='boxes', fs='solid 0.4')
   call fig%plot([1.3_R8P, 2.3_R8P, 4.3_R8P, 5.3_R8P], [1.5_R8P, 2.5_R8P, -1.0_R8P, 2.0_R8P], title='width', &
                 with='boxes', width=[0.3_R8P, 0.3_R8P, 0.3_R8P, 0.3_R8P], fs='solid noborder')
   endfunction figure_boxes

   function figure_boxes_relative() result(fig)
   !< Boxes at 60% of the auto width, positive values only (y still from 0), empty with a black border.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   call fig%init(width=420_I4P, height=300_I4P)
   x = [(real(i, R8P), i = 1, 6)]
   call fig%set_boxwidth(0.6_R8P, relative=.true.)
   call fig%set_style_fill('empty border lc "black"')
   call fig%plot(x, 10.0_R8P + x, title='counts', with='boxes')
   endfunction figure_boxes_relative

   function figure_fills() result(fig)
   !< filledcurves: down to y = 0.5, a band split by a NaN, a closed polygon; never a border, filled even when the fill
   !< style is empty (as gnuplot).
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   real(R8P), allocatable :: lo(:) !< Band lower curve.
   integer(I4P)           :: i    !< Counter.

   call fig%init(width=500_I4P, height=320_I4P)
   x = [(0.25_R8P * real(i, R8P), i = 0, 40)]
   lo = sin(x) + 2.0_R8P
   lo(20) = ieee_value(1.0_R8P, ieee_quiet_nan)
   call fig%plot(x, sin(x), title='to 0.5', with='filledcurves', base=0.5_R8P, fs='solid 0.3')
   call fig%plot(x, lo + 0.5_R8P, ylow=lo, title='band', with='filledcurves')
   call fig%plot([7.0_R8P, 9.0_R8P, 8.0_R8P], [-1.0_R8P, -1.0_R8P, 0.5_R8P], title='closed', with='filledc', &
                 fs='transparent solid 0.5')
   endfunction figure_fills

   function figure_fills_block() result(fig)
   !< The fills on the block device with ANSI colors.
   type(figure_object) :: fig !< Figure.

   fig = figure_fills()
   call fig%set_text(charset='quadrants', colors='ansi')
   endfunction figure_fills_block

   function check(name, fig) result(passed)
   !< Render `fig` and compare it with its reference file, or rewrite the reference in update mode.
   character(len=*),    intent(in)    :: name     !< Reference file name, with the format extension.
   type(figure_object), intent(in)    :: fig      !< Figure.
   logical                            :: passed   !< Rendering matches the reference.
   type(figure_object)                :: figure   !< Figure being rendered (rendering updates its ticks).
   character(len=:), allocatable      :: output   !< Rendered file.
   character(len=:), allocatable      :: golden   !< Reference file.
   character(len=:), allocatable      :: produced !< Rendered content.
   logical                            :: exists   !< Reference exists.
   integer(I4P)                       :: unit     !< File unit.

   output = 'foresight_golden_'//name
   golden = GOLDEN_DIR//name
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
