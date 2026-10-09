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
logical                     :: test_passed(60)                  !< Per-figure outcome.

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
test_passed(22) = check('histograms.svg', figure_histograms(.false.))
test_passed(23) = check('histograms.txt', figure_histograms(.false.))
test_passed(24) = check('histograms_rowstacked.svg', figure_histograms(.true.))
! also the page of the viewer DOM test of text labels (src/js/viewer_dom_test.js)
test_passed(25) = check('histograms.html', figure_histograms(.false.))
test_passed(26) = check('segments.svg', figure_segments())
test_passed(27) = check('segments.txt', figure_segments())
test_passed(28) = check('theme_vfd.svg', figure_theme('vfd'))
test_passed(29) = check('theme_lcd.svg', figure_theme('lcd'))
test_passed(30) = check('theme_vfd_block.txt', figure_theme_block())
test_passed(31) = check('theme_vfd_noglow.svg', figure_theme('vfd', glow=.false.))
! also the page of the viewer DOM test of themes (src/js/viewer_dom_test.js)
test_passed(32) = check('theme_vfd.html', figure_theme('vfd'))
test_passed(33) = check('image.svg', figure_image(''))
test_passed(34) = check('image.txt', figure_image(''))
test_passed(35) = check('image_maxcolors.svg', figure_image('defined (0 "blue", 1 "white", 2 "red") maxcolors 6'))
test_passed(36) = check('image_viridis.svg', figure_image('viridis'))
test_passed(37) = check('image_vfd.svg', figure_image('maxcolors 8', theme='vfd'))
! also the page of the viewer DOM test of images (src/js/viewer_dom_test.js)
test_passed(38) = check('image.html', figure_image(''))
test_passed(39) = check('circles.svg', figure_circles())
test_passed(40) = check('circles.txt', figure_circles())
test_passed(41) = check('pie.svg', figure_pie(0.0_R8P))
test_passed(42) = check('pie.txt', figure_pie(0.0_R8P))
test_passed(43) = check('donut.svg', figure_pie(0.55_R8P))
test_passed(44) = check('donut_vfd.svg', figure_pie(0.6_R8P, theme='vfd'))
test_passed(45) = check('gauges.svg', figure_gauges())
test_passed(46) = check('gauges.txt', figure_gauges())
test_passed(47) = check('gauges_vfd.svg', figure_gauges(theme='vfd'))
test_passed(48) = check('radar.svg', figure_radar())
test_passed(49) = check('rose.svg', figure_rose(.false.))
test_passed(50) = check('rose_linear.svg', figure_rose(.true.))
test_passed(51) = check('polar.svg', figure_polar('plain'))
test_passed(52) = check('polar_round.svg', figure_polar('round'))
test_passed(53) = check('polar_round.txt', figure_polar('round'))
test_passed(54) = check('polar_round.html', figure_polar('round'))
test_passed(55) = check('polar_vfd.svg', figure_polar('round', theme='vfd'))
test_passed(56) = check('polar_rmin.svg', figure_polar('rmin'))
test_passed(57) = check('steps.svg', figure_steps())
test_passed(58) = check('steps.txt', figure_steps())
test_passed(59) = check('boxplot.svg', figure_boxplot())
test_passed(60) = check('boxplot.txt', figure_boxplot())
write(output_unit, '(A,60L2)') 'foresight golden checks:', test_passed
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

   function figure_histograms(stacked) result(fig)
   !< Histograms of three series over three labelled rows, a negative value: clustered (gap 2, y from 0, x one unit
   !< beyond the rows) or row-stacked (negative values stacked down from 0); text labels replace the x ticks.
   logical, intent(in) :: stacked !< Row-stacked, else clustered.
   type(figure_object) :: fig     !< Figure.
   character(len=8)    :: names(3) !< Row labels.

   names = ['Xall GPU', 'Xall CPU', 'ADAM    ']
   call fig%init(width=500_I4P, height=320_I4P)
   call fig%set_title('Time per step')
   call fig%set_style_fill('solid 0.6 border lc "black"')
   if (stacked) call fig%set_style_histogram('rowstacked')
   call fig%plot([0.0_R8P, 1.0_R8P, 2.0_R8P], [3.0_R8P, 5.0_R8P, 2.0_R8P], title='mesh', with='histograms', &
                 xlabels=names)
   call fig%plot([0.0_R8P, 1.0_R8P, 2.0_R8P], [2.0_R8P, 1.0_R8P, 4.0_R8P], title='io', with='histograms')
   call fig%plot([0.0_R8P, 1.0_R8P, 2.0_R8P], [1.0_R8P, 2.0_R8P, -1.0_R8P], title='comm', with='histograms')
   endfunction figure_histograms

   function figure_segments() result(fig)
   !< Segmented boxes (classic theme): 10 cells over the y range, lit when covered at least half, the others ghosts
   !< (not drawn in text); a negative box lights the cells below 0.
   type(figure_object) :: fig !< Figure.

   call fig%init(width=420_I4P, height=300_I4P)
   call fig%set_yrange(min=-2.0_R8P, max=8.0_R8P)
   call fig%plot([1.0_R8P, 2.0_R8P, 3.0_R8P, 4.0_R8P], [3.2_R8P, 7.0_R8P, -1.4_R8P, 5.6_R8P], title='level', &
                 with='boxes', fs='solid segments 10')
   endfunction figure_segments

   function figure_theme(name, glow) result(fig)
   !< A 1980s display: a log curve with a readout, segmented histograms, in the theme `name` (classic otherwise).
   character(len=*), intent(in)           :: name !< Theme name.
   logical,          intent(in), optional :: glow !< Glow override.
   type(figure_object)                    :: fig  !< Figure.
   real(R8P), allocatable                 :: it(:) !< Iterations.
   integer(I4P)                           :: i    !< Counter.

   call fig%init(width=600_I4P, height=400_I4P)
   call fig%set_theme(name=name, glow=glow)
   it = [(real(i, R8P), i = 1, 60)]
   call fig%set_multiplot(rows=1_I4P, cols=2_I4P, title='RUN 42')
   call fig%set_logscale('y')
   call fig%set_grid
   call fig%plot(it, 10.0_R8P**(-0.08_R8P * it) * (1.0_R8P + 0.3_R8P * sin(it / 3.0_R8P)), title='residual', lw=2.0_R8P)
   call fig%plot(it, 10.0_R8P**(-0.08_R8P * it) * (1.0_R8P + 0.3_R8P * sin(it / 3.0_R8P)), title='RES', &
                 with='readout', format='%9.2e')
   call fig%next_panel
   call fig%unset_logscale
   call fig%set_grid(.false.)
   call fig%set_readout(position='top right')
   call fig%plot([0.0_R8P, 1.0_R8P, 2.0_R8P], [3.0_R8P, 5.0_R8P, 2.0_R8P], title='mesh', with='histograms', &
                 fs='solid segments 12', xlabels=['GPU', 'CPU', 'MIX'])
   call fig%plot([0.0_R8P, 1.0_R8P, 2.0_R8P], [2.0_R8P, 1.0_R8P, 4.0_R8P], title='io', with='histograms', &
                 fs='solid segments 12')
   endfunction figure_theme

   function figure_theme_block() result(fig)
   !< The vfd display on the block device in true colors: the theme recolors the series only.
   type(figure_object) :: fig !< Figure.

   fig = figure_theme('vfd')
   call fig%set_text(charset='quadrants', colors='ansirgb')
   endfunction figure_theme_block

   function figure_image(palette, theme) result(fig)
   !< A heatmap of a 21 x 15 grid with an undefined (transparent) pixel, in the `palette`: x and y fit the pixel edges,
   !< the color box at the right with its label.
   character(len=*), intent(in)           :: palette !< Palette words.
   character(len=*), intent(in), optional :: theme   !< Theme name.
   type(figure_object)                    :: fig     !< Figure.
   real(R8P), allocatable                 :: x(:)    !< Pixel centre abscissae.
   real(R8P), allocatable                 :: y(:)    !< Pixel centre ordinates.
   real(R8P), allocatable                 :: z(:,:)  !< Values.
   integer(I4P)                           :: i       !< Column counter.
   integer(I4P)                           :: j       !< Row counter.

   call fig%init(width=420_I4P, height=300_I4P)
   if (present(theme)) call fig%set_theme(name=theme)
   x = [(-5.0_R8P + 0.5_R8P * real(i, R8P), i = 0, 20)]
   y = [(-3.5_R8P + 0.5_R8P * real(j, R8P), j = 0, 14)]
   allocate(z(size(x), size(y)))
   do j = 1_I4P, size(y, kind=I4P)
      do i = 1_I4P, size(x, kind=I4P)
         z(i, j) = exp(-(x(i)**2 + y(j)**2) / 6.0_R8P) * cos(x(i)) * cos(y(j))
      enddo
   enddo
   z(1, 1) = ieee_value(1.0_R8P, ieee_quiet_nan)
   call fig%set_palette(palette)
   call fig%set_cblabel('phi')
   call fig%image(z, x, y, title='field')
   endfunction figure_image

   function figure_circles() result(fig)
   !< Circles of radii in x units (the x autoscale widened by them, round on the page), one of the default radius, and
   !< wedges of a whole turn split in three (angles counterclockwise from the x direction, an end below its start).
   type(figure_object) :: fig    !< Figure.
   real(R8P)           :: nan    !< Quiet NaN.

   nan = ieee_value(1.0_R8P, ieee_quiet_nan)
   call fig%init(width=500_I4P, height=320_I4P)
   call fig%set_multiplot(rows=1_I4P, cols=2_I4P)
   call fig%set_style_fill('solid 0.4')
   call fig%plot([1.0_R8P, 2.0_R8P, 3.0_R8P, 4.0_R8P], [2.0_R8P, 2.6_R8P, 1.5_R8P, 2.4_R8P], title='cases', &
                 with='circles', radius=[0.3_R8P, 0.5_R8P, 0.4_R8P, nan])
   call fig%next_panel
   call fig%set_xrange(-1.2_R8P, 1.2_R8P)
   call fig%set_yrange(-1.2_R8P, 1.2_R8P)
   call fig%set_key(.false.)
   call fig%plot([0.0_R8P, 0.0_R8P, 0.0_R8P], [0.0_R8P, 0.0_R8P, 0.0_R8P], with='circles', &
                 radius=[1.0_R8P, 1.0_R8P, 0.7_R8P], &
                 angles=reshape([0.0_R8P, 60.0_R8P, 60.0_R8P, 200.0_R8P, 200.0_R8P, 0.0_R8P], [2, 3]))
   endfunction figure_circles

   function figure_pie(hole, theme) result(fig)
   !< A pie (or donut) alone in its panel: slices from 12 o'clock clockwise, the key with labels and percentages.
   real(R8P),        intent(in)           :: hole  !< Donut hole fraction, 0 for a pie.
   character(len=*), intent(in), optional :: theme !< Theme name.
   type(figure_object)                    :: fig   !< Figure.

   call fig%init(width=420_I4P, height=300_I4P)
   if (present(theme)) call fig%set_theme(name=theme)
   call fig%set_title('Time per step')
   call fig%plot([0.0_R8P, 1.0_R8P, 2.0_R8P, 3.0_R8P], [0.8_R8P, 2.1_R8P, 0.6_R8P, 0.3_R8P], with='pie', &
                 xlabels=['mesh  ', 'fluxes', 'comm  ', 'io    '], donut=hole)
   endfunction figure_pie

   function figure_gauges(theme) result(fig)
   !< Three gauges side by side: continuous, segmented (cells lit when covered half), beyond its scale (the track full,
   !< the digits true); the last finite value of each series.
   character(len=*), intent(in), optional :: theme !< Theme name.
   type(figure_object)                    :: fig   !< Figure.
   real(R8P), allocatable                 :: t(:)  !< Steps.
   integer(I4P)                           :: i     !< Counter.

   call fig%init(width=600_I4P, height=240_I4P)
   if (present(theme)) call fig%set_theme(name=theme)
   t = [(real(i, R8P), i = 1, 10)]
   call fig%plot(t, 600.0_R8P * t, title='RPM', with='gauge', scale=[0.0_R8P, 8000.0_R8P], format='%5.0f')
   call fig%plot(t, 0.07_R8P * t, title='LOAD', with='gauge', scale=[0.0_R8P, 1.0_R8P], format='%4.2f', &
                 fs='solid segments 20')
   call fig%plot(t, 22.0_R8P * t, title='TEMP', with='gauge', scale=[0.0_R8P, 200.0_R8P], format='%3.0f')
   endfunction figure_gauges

   function figure_radar() result(fig)
   !< A radar of two series over five named spokes, filled at 0.3: rings at the ticks of the common scale from 0.
   type(figure_object) :: fig !< Figure.

   call fig%init(width=460_I4P, height=320_I4P)
   call fig%set_style_fill('solid 0.3')
   call fig%plot([0.0_R8P, 1.0_R8P, 2.0_R8P, 3.0_R8P, 4.0_R8P], [8.0_R8P, 5.0_R8P, 7.0_R8P, 4.0_R8P, 9.0_R8P], &
                 title='gpu', with='radar', xlabels=['speed  ', 'memory ', 'energy ', 'cost   ', 'scaling'])
   call fig%plot([0.0_R8P, 1.0_R8P, 2.0_R8P, 3.0_R8P, 4.0_R8P], [4.0_R8P, 9.0_R8P, 3.0_R8P, 8.0_R8P, 5.0_R8P], &
                 title='cpu', with='radar')
   endfunction figure_radar

   function figure_rose(linear) result(fig)
   !< A rose of four named sectors, the area (or the radius, `linear`) by value, rings at the ticks of the scale.
   logical, intent(in) :: linear !< Radius by value.
   type(figure_object) :: fig    !< Figure.

   call fig%init(width=420_I4P, height=300_I4P)
   call fig%plot([0.0_R8P, 1.0_R8P, 2.0_R8P, 3.0_R8P], [0.8_R8P, 2.1_R8P, 0.6_R8P, 0.3_R8P], with='rose', &
                 xlabels=['mesh  ', 'fluxes', 'comm  ', 'io    '], linear=linear)
   endfunction figure_rose

   function figure_polar(kind, theme) result(fig)
   !< Polar plots of a cardioid r = 1 + cos(theta) (lines) and a filled pentagon, theta in degrees: `plain` keeps the
   !< rectangular frame, as gnuplot `set polar` alone; `round` is gnuplot's round idiom (square, polar border and grid,
   !< no x and y ticks, theta labels); `rmin` sets the pole at r = 0.5 (points below it undefined), theta from the
   !< top, clockwise.
   character(len=*), intent(in)           :: kind  !< `plain`, `round` or `rmin`.
   character(len=*), intent(in), optional :: theme !< Output theme.
   type(figure_object)                    :: fig   !< Figure.
   real(R8P)                              :: t(73) !< Theta [deg].
   integer(I4P)                           :: i     !< Counter.

   call fig%init(width=520_I4P, height=400_I4P)
   if (present(theme)) call fig%set_theme(name=theme)
   call fig%set_polar
   call fig%set_angles('degrees')
   if (kind /= 'plain') then
      call fig%set_size(ratio=1.0_R8P)
      call fig%set_border(0_I4P, polar=.true.)
      call fig%unset_xtics
      call fig%unset_ytics
      call fig%set_grid(polar=30.0_R8P)
      call fig%set_ttics(step=30.0_R8P)
      call fig%set_key(position='outside')
   endif
   if (kind == 'rmin') then
      call fig%set_rrange(min=0.5_R8P)
      call fig%set_theta('top', clockwise=.true.)
   endif
   t = [(5.0_R8P * real(i, R8P), i = 0, 72)]
   call fig%plot(t, 1.0_R8P + cos(t * (4.0_R8P * atan(1.0_R8P) / 180.0_R8P)), title='cardioid')
   call fig%plot([90.0_R8P, 162.0_R8P, 234.0_R8P, 306.0_R8P, 18.0_R8P, 90.0_R8P], &
                 [1.2_R8P, 1.2_R8P, 1.2_R8P, 1.2_R8P, 1.2_R8P, 1.2_R8P], title='pentagon', with='filledcurves', &
                 fs='transparent solid 0.3')
   endfunction figure_polar

   function figure_steps() result(fig)
   !< The lines family of gnuplot over four points: steps, fsteps and histeps; impulses and dots; y and x error lines;
   !< xy error lines.
   type(figure_object) :: fig    !< Figure.
   real(R8P)           :: x(4)   !< Abscissae.
   real(R8P)           :: y(4)   !< Ordinates.
   real(R8P)           :: d(4)   !< Errors.

   x = [1.0_R8P, 2.0_R8P, 4.0_R8P, 5.0_R8P]
   y = [2.0_R8P, 1.5_R8P, 3.0_R8P, 1.0_R8P]
   d = [0.3_R8P, 0.2_R8P, 0.5_R8P, 0.1_R8P]
   call fig%init(width=700_I4P, height=500_I4P)
   call fig%set_multiplot(rows=2_I4P, cols=2_I4P)
   call fig%set_key(position='top left')
   call fig%plot(x, y, title='steps', with='steps')
   call fig%plot(x, y, title='fsteps', with='fs')
   call fig%plot(x, y, title='histeps', with='his')
   call fig%next_panel
   call fig%plot(x, y, title='impulses', with='impulses', lw=2.0_R8P)
   call fig%plot(x, y + 0.5_R8P, title='dots', with='dots')
   call fig%next_panel
   call fig%plot(x, y, title='yerrorlines', with='yerrorlines', ylow=y - d, yhigh=y + d)
   call fig%plot(x, y + 1.0_R8P, title='xerrorlines', with='xerrorl', xlow=x - d, xhigh=x + d)
   call fig%next_panel
   call fig%plot(x, y, title='xyerrorlines', with='xyerrorlines', xlow=x - d, xhigh=x + d, ylow=y - d, yhigh=y + d)
   endfunction figure_steps

   function figure_boxplot() result(fig)
   !< The box styles of gnuplot: boxerrorbars and boxxyerror; candlesticks (one falling, filled; whisker crossbars)
   !< and financebars; boxplots of two factor levels with an outlier; the same as finance bars, without outliers.
   type(figure_object)    :: fig     !< Figure.
   real(R8P)              :: x(4)    !< Abscissae.
   real(R8P)              :: y(4)    !< Ordinates.
   real(R8P)              :: d(4)    !< Errors.
   real(R8P)              :: v(11)   !< Boxplot values.
   character(len=1)       :: f(11)   !< Boxplot factors.
   integer(I4P)           :: i       !< Counter.

   x = [1.0_R8P, 2.0_R8P, 4.0_R8P, 5.0_R8P]
   y = [2.0_R8P, 1.5_R8P, 3.0_R8P, 1.0_R8P]
   d = [0.3_R8P, 0.2_R8P, 0.5_R8P, 0.1_R8P]
   v = [1.0_R8P, 2.0_R8P, 3.0_R8P, 4.0_R8P, 5.0_R8P, 3.0_R8P, 4.0_R8P, 6.0_R8P, 8.0_R8P, 9.0_R8P, 20.0_R8P]
   f = ['a', 'a', 'a', 'a', 'a', 'b', 'b', 'b', 'b', 'b', 'b']
   call fig%init(width=760_I4P, height=560_I4P)
   call fig%set_multiplot(rows=2_I4P, cols=2_I4P)
   call fig%set_key(position='top left')
   call fig%set_style_fill('solid 0.3')
   call fig%plot(x, y, title='boxerrorbars', with='boxerrorbars', ylow=y - d, yhigh=y + d)
   call fig%plot(x + 0.2_R8P, y + 1.0_R8P, title='boxxyerror', with='boxx', xlow=x - d + 0.2_R8P, &
                 xhigh=x + d + 0.2_R8P, ylow=y + 1.0_R8P - d, yhigh=y + 1.0_R8P + d)
   call fig%next_panel
   call fig%set_style_fill('empty')
   call fig%set_boxwidth(0.4_R8P)
   call fig%plot(x, [1.5_R8P, 1.2_R8P, 3.4_R8P, 0.8_R8P], title='candlesticks', with='candlesticks', &
                 ylow=[1.2_R8P, 1.0_R8P, 2.2_R8P, 0.5_R8P], yhigh=[2.8_R8P, 2.2_R8P, 3.9_R8P, 1.9_R8P], &
                 close=[2.8_R8P, 1.9_R8P, 2.5_R8P, 1.6_R8P], whiskerbars=0.5_R8P)
   call fig%plot(x + 0.4_R8P, [1.5_R8P, 1.2_R8P, 3.4_R8P, 0.8_R8P], title='financebars', with='fin', &
                 ylow=[1.2_R8P, 1.0_R8P, 2.2_R8P, 0.5_R8P], yhigh=[2.8_R8P, 2.2_R8P, 3.9_R8P, 1.9_R8P], &
                 close=[2.8_R8P, 1.9_R8P, 2.5_R8P, 1.6_R8P])
   call fig%next_panel
   call fig%set_boxwidth()
   call fig%plot([(1.0_R8P, i = 1, 11)], v, title='boxplot', with='boxplot', factors=f)
   call fig%next_panel
   call fig%set_style_boxplot('nooutliers financebars')
   call fig%plot([(1.0_R8P, i = 1, 11)], v, title='financebars', with='boxplot', factors=f)
   endfunction figure_boxplot

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
