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
character(len=*), parameter :: GOLDEN_DIR = 'src/tests/goldens/' !< Reference files directory.
character(len=8)            :: update_flag                      !< FORESIGHT_UPDATE_GOLDEN value.
logical                     :: update                           !< Rewrite the references.
logical                     :: test_passed(125)                  !< Per-figure outcome.

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
test_passed(61) = check('shapes.svg', figure_shapes())
test_passed(62) = check('shapes.txt', figure_shapes())
test_passed(63) = check('shapes.html', figure_shapes())
test_passed(64) = check('windrose.svg', figure_windrose())
test_passed(65) = check('patterns.svg', figure_patterns())
test_passed(66) = check('patterns.txt', figure_patterns())
test_passed(67) = check('spider.svg', figure_spider())
test_passed(68) = check('spider.txt', figure_spider())
test_passed(69) = check('image_batlow.svg', figure_image('batlow'))
test_passed(70) = check('image_vik.svg', figure_image('vik', cbmax=1.0_R8P))
test_passed(71) = check('image_romaO.svg', figure_image('romaO maxcolors 12'))
test_passed(72) = check('image_cubehelix.svg', figure_image('cubehelix'))
test_passed(73) = check('short_panels.svg', figure_short_panels())
! the library gradient renders as the same `defined` palette
test_passed(74) = rendered(figure_image('negative', gradient=.true.)) == &
                  rendered(figure_image('defined (0 "blue", 1 "white", 2 "red") negative'))
test_passed(75) = check('colorsequence_batlowS.svg', figure_colorsequence())
test_passed(76) = check('image_logcb.svg', figure_logcb())
test_passed(77) = check('colorbox_modes.svg', figure_colorbox_modes())
test_passed(78) = check('tics_list.svg', figure_tics_list())
test_passed(79) = check('tics_list.txt', figure_tics_list())
test_passed(80) = check('mtics.svg', figure_mtics())
test_passed(81) = check('tics_rotate.svg', figure_tics_rotate())
test_passed(82) = check('tics_rotate.txt', figure_tics_rotate())
test_passed(83) = check('lc_variable.svg', figure_lc_variable())
test_passed(84) = check('x2.svg', figure_x2())
test_passed(85) = check('x2.html', figure_x2())
test_passed(86) = check('theme_washi.svg', figure_identity('washi'))
test_passed(87) = check('theme_night.svg', figure_identity('night'))
! also the page of the viewer DOM test of a dark theme (src/js/viewer_dom_test.js)
test_passed(88) = check('theme_night.html', figure_identity('night'))
! the key point sample in the last point's color, as gnuplot (the golden had the first's until 2026-11-21)
test_passed(89) = check('lc_palette_keys.svg', figure_lc_palette())
test_passed(90) = check('key_at.svg', figure_key_at())
test_passed(91) = check('x2_rotate.svg', figure_x2_rotate())
test_passed(92) = check('time_axis.svg', figure_time_axis())
test_passed(93) = check('time_axis.txt', figure_time_axis())
test_passed(94) = check('time_axis.html', figure_time_axis())
test_passed(95) = check('histogram_layouts.svg', figure_histogram_layouts())
test_passed(96) = check('histogram_layouts.txt', figure_histogram_layouts())
test_passed(97) = check('annotations.svg', figure_annotations())
test_passed(98) = check('annotations.txt', figure_annotations())
test_passed(99) = check('annotations.html', figure_annotations())
test_passed(100) = check('annotation_styles.svg', figure_annotation_styles())
test_passed(101) = check('annotation_styles.txt', figure_annotation_styles())
test_passed(102) = check('tic_labels_fills.svg', figure_tic_labels_fills())
test_passed(103) = check('tic_labels_fills.txt', figure_tic_labels_fills())
! enhanced text through the library API; the html page is also the one of the viewer DOM test of enhanced tick labels
test_passed(104) = check('enhanced.svg', figure_enhanced())
test_passed(105) = check('enhanced.html', figure_enhanced())
test_passed(106) = check('enhanced.txt', figure_enhanced())
! ticks on the zero axes; the html page is also the one of the viewer DOM test of tick placement
test_passed(107) = check('tics_axis.svg', figure_tics_axis())
test_passed(108) = check('tics_axis.html', figure_tics_axis())
! 3D plots, the map view (gnuplot `set view map`): scattered points colored by height, a grid as an image
test_passed(109) = check('map_points.svg', figure_map_points())
test_passed(110) = check('map_points.html', figure_map_points())
test_passed(111) = check('map_points.txt', figure_map_points())
test_passed(112) = check('map_image.svg', figure_map_image())
test_passed(113) = check('map_image.html', figure_map_image())
test_passed(114) = check('map_image.txt', figure_map_image())
! pm3d in the map view: a surface as colored quadrangles, and subdivided (interpolate 4,4)
test_passed(115) = check('map_pm3d.svg', figure_map_pm3d(1_I4P))
test_passed(116) = check('map_pm3d.html', figure_map_pm3d(1_I4P))
test_passed(117) = check('map_pm3d.txt', figure_map_pm3d(1_I4P))
test_passed(118) = check('map_pm3d_interpolate.svg', figure_map_pm3d(4_I4P))
! contour lines in the map view, a level per linetype and key entry, over a pm3d surface
test_passed(119) = check('map_contour.svg', figure_map_contour())
test_passed(120) = check('map_contour.html', figure_map_contour())
test_passed(121) = check('map_contour.txt', figure_map_contour())
test_passed(122) = check('map_dgrid3d.svg', figure_map_dgrid3d())
test_passed(123) = check('map_dgrid3d.html', figure_map_dgrid3d())
test_passed(124) = check('map_dgrid3d.txt', figure_map_dgrid3d())
! a 3D view (gnuplot's default view 60, 30): a surface mesh in its box, the ticks and labels of the three axes, the key
! and the title at gnuplot's places
test_passed(125) = check('view3d_frame.svg', figure_view3d_frame())
write(output_unit, '(A,125L2)') 'foresight golden checks:', test_passed
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

   function figure_tics_axis() result(fig)
   !< Ticks on the zero axes, gnuplot `set xtics axis; set ytics axis`: no margin for their labels.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   x = [(-3.0_R8P + 0.25_R8P * real(i, R8P), i = 0, 32)]
   call fig%init(width=500_I4P, height=320_I4P)
   call fig%set_xrange(min=-3.0_R8P, max=5.0_R8P)
   call fig%set_yrange(min=-1.0_R8P, max=2.0_R8P)
   call fig%plot(x, sin(x), title='sin(x)')
   fig%panels(1)%xaxis%tics%on_axis = .true.
   fig%panels(1)%yaxis%tics%on_axis = .true.
   endfunction figure_tics_axis

   function figure_enhanced() result(fig)
   !< gnuplot's enhanced text (fig%set_enhanced): sub and superscripts, a Greek letter, in the title, the labels, the
   !< key and the x tick labels; the y2 label and tick labels as they are (noenhanced).
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   x = [(0.25_R8P * real(i, R8P), i = 0, 12)]
   call fig%init(width=500_I4P, height=320_I4P)
   call fig%set_enhanced(.true.)
   call fig%set_title('Enhanced text: T_{n-1}(x) = x^2')
   call fig%set_xlabel('x_1 [m s^{-1}]')
   call fig%set_ylabel('{/Symbol a}^2')
   call fig%set_y2label('p_ref, as it is')
   call fig%set_xtics(positions=[0.0_R8P, 1.0_R8P, 2.0_R8P, 3.0_R8P], labels=['x_0', 'x_1', 'x_2', 'x_3'])
   call fig%set_y2tics(positions=[0.0_R8P, 3.0_R8P, 6.0_R8P], labels=['a_0', 'a_1', 'a_2'])
   fig%panels(1)%label_plain(3) = .true.
   fig%panels(1)%y2axis%tics%plain = .true.
   call fig%plot(x, x**2, title='y = x^2')
   call fig%plot(x, 2.0_R8P * x, title='y = 2 x_0', axes='x1y2')
   endfunction figure_enhanced

   function figure_x2() result(fig)
   !< Second x axis through the library API: a series on x2y2, its axis on the top border with outward ticks, minor
   !< ticks and a label; x and y ticks not mirrored.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: t(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   t = [(real(i, R8P), i = 0, 20)]
   call fig%init(width=500_I4P, height=340_I4P)
   call fig%set_title('two x axes')
   call fig%set_xlabel('time [s]')
   call fig%set_x2label('distance [m]')
   call fig%set_ylabel('speed [m/s]')
   call fig%set_y2label('energy [J]')
   call fig%set_xtics(mirror=.false.)
   call fig%set_ytics(mirror=.false.)
   call fig%set_x2tics(out=.true.)
   call fig%set_mx2tics(2_I4P)
   call fig%set_y2tics()
   call fig%set_key(position='top left')
   call fig%plot(t, 2.0_R8P + 0.3_R8P * t, title='speed')
   call fig%plot(12.0_R8P * t + 0.15_R8P * t**2, 50.0_R8P * (2.0_R8P + 0.3_R8P * t)**2, title='energy', &
                 with='linespoints', axes='x2y2')
   endfunction figure_x2

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

   function figure_tics_list() result(fig)
   !< Explicit tick lists, gnuplot `set xtics ("label" pos level, ...)`: month names on x with minor ticks between them
   !< (the range not extended to a tick grid), and on y the automatic ticks plus a labelled threshold and a formatted one.
   type(figure_object) :: fig !< Figure.

   call fig%init(width=520_I4P, height=320_I4P)
   call fig%set_xtics(positions=[1.0_R8P, 1.5_R8P, 2.0_R8P, 2.5_R8P, 3.0_R8P, 3.5_R8P, 4.0_R8P], &
                      labels=['Jan', '   ', 'Feb', '   ', 'Mar', '   ', 'Apr'], &
                      minor=[.false., .true., .false., .true., .false., .true., .false.])
   call fig%set_ytics(positions=[7.5_R8P, 4.25_R8P], labels=['limit  ', '%.2f mm'], add=.true.)
   call fig%set_grid
   call fig%plot([1.0_R8P, 2.0_R8P, 3.0_R8P, 4.0_R8P], [3.2_R8P, 6.1_R8P, 8.4_R8P, 5.0_R8P], title='rain', with='linespoints')
   endfunction figure_tics_list

   function figure_mtics() result(fig)
   !< Minor ticks, gnuplot `set mxtics [N]`: on x gnuplot's count (5 per step of 1, from a partial interval at each end),
   !< on the log y axis 4 intervals per decade, linear in value (gnuplot's rule); the color box 2 per step.
   type(figure_object) :: fig !< Figure.
   real(R8P)           :: z(6, 4) !< Image values.
   integer(I4P)        :: i       !< Column.
   integer(I4P)        :: j       !< Row.

   call fig%init(width=560_I4P, height=320_I4P)
   call fig%set_multiplot(rows=1_I4P, cols=2_I4P)
   call fig%set_xrange(min=0.3_R8P, max=7.7_R8P)
   call fig%set_logscale('y')
   call fig%set_yrange(min=1.0_R8P, max=1000.0_R8P)
   call fig%set_mxtics
   call fig%set_mytics(4_I4P)
   call fig%plot([1.0_R8P, 3.0_R8P, 5.0_R8P, 7.0_R8P], [2.0_R8P, 30.0_R8P, 120.0_R8P, 700.0_R8P], title='growth', &
                 with='linespoints')
   call fig%next_panel
   call fig%unset_logscale
   call fig%set_xrange
   call fig%set_yrange
   call fig%set_mxtics(0_I4P)
   call fig%set_mytics(0_I4P)
   call fig%set_mcbtics(2_I4P)
   z = reshape([((real(i * j, R8P), i = 1, 6), j = 1, 4)], [6, 4])
   call fig%image(z, title='')
   endfunction figure_mtics

   function figure_tics_rotate() result(fig)
   !< Rotated x tick labels and outward ticks, gnuplot `set xtics rotate [by A] [right]` and `out`: by 90 degrees
   !< right-justified, by 45 right-justified, by -30 left-justified (the default of rotate by), and outward ticks on x
   !< and y; the labels hang below the axis, the margins fit them. Text devices keep them upright, as gnuplot's dumb.
   type(figure_object)         :: fig        !< Figure.
   character(len=8), parameter :: MONTHS(4) = ['January ', 'February', 'March   ', 'April   '] !< Labels.
   real(R8P),        parameter :: X(4) = [1.0_R8P, 2.0_R8P, 3.0_R8P, 4.0_R8P] !< Months.
   real(R8P),        parameter :: Y(4) = [3.0_R8P, 5.0_R8P, 4.0_R8P, 6.0_R8P] !< Values.

   call fig%init(width=700_I4P, height=500_I4P)
   call fig%set_multiplot(rows=2_I4P, cols=2_I4P)
   call fig%set_xtics(positions=X, labels=MONTHS, rotate=90.0_R8P, justify='right')
   call fig%set_xlabel('month')
   call fig%plot(X, Y, title='rotate', with='linespoints')
   call fig%next_panel
   call fig%set_xtics(rotate=45.0_R8P, justify='right')
   call fig%plot(X, Y, title='by 45 right', with='linespoints')
   call fig%next_panel
   call fig%set_xtics(rotate=-30.0_R8P)
   call fig%plot(X, Y, title='by -30', with='linespoints')
   call fig%next_panel
   call fig%set_xtics(rotate=0.0_R8P, out=.true.)
   call fig%set_ytics(out=.true.)
   call fig%plot(X, Y, title='out', with='linespoints')
   endfunction figure_tics_rotate

   function figure_x2_rotate() result(fig)
   !< Rotated x2 tick labels (gnuplot `set x2tics rotate`): 90 degrees from the tick, and 45 with outward ticks, a
   !< title and an x2 label above them; the right margin takes the reach of the last label.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   x = [(0.25_R8P * real(i, R8P), i = 0, 40)]
   call fig%init(width=720_I4P, height=300_I4P)
   call fig%set_multiplot(rows=1_I4P, cols=2_I4P)
   call fig%set_title('rotate')
   call fig%set_x2range(0.0_R8P, 1000.0_R8P)
   call fig%set_x2tics(step=250.0_R8P, rotate=90.0_R8P)
   call fig%set_xtics(mirror=.false.)
   call fig%plot(x, sin(x), title='sin')
   call fig%next_panel()
   call fig%set_title('rotate by 45, out')
   call fig%set_x2label('wavelength [nm]')
   call fig%set_x2range(0.0_R8P, 1000.0_R8P)
   call fig%set_x2tics(step=250.0_R8P, rotate=45.0_R8P, out=.true.)
   call fig%set_xtics(mirror=.false.)
   call fig%plot(x, cos(x), title='cos')
   endfunction figure_x2_rotate

   function figure_annotations() result(fig)
   !< Labels, arrows and objects (gnuplot `set label`, `set arrow`, `set object`): a label at a data point marked by a
   !< point, one centred in graph coordinates, a rotated one in red, one in screen coordinates at the front; arrows with
   !< the head styles and a relative one; a shaded band behind the grid, a rectangle in the page color, a circle, an
   !< ellipse, a polygon.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   x = [(0.1_R8P * real(i, R8P), i = 0, 100)]
   call fig%init(width=640_I4P, height=400_I4P)
   call fig%set_title('labels, arrows, objects')
   call fig%set_grid(.true.)
   call fig%set_object('rectangle', [4.0_R8P, 6.0_R8P], [0.0_R8P, 1.0_R8P], system='first graph', fc='#56b4e9', &
                       fs='solid 0.25 noborder', layer='behind')
   call fig%set_object('rectangle', [8.0_R8P, 9.8_R8P], [0.6_R8P, 0.95_R8P], lw=1.0_R8P)
   call fig%set_object('circle', [2.0_R8P], [-0.5_R8P], radius=0.6_R8P, fc='#e69f00', fs='solid 0.5 border')
   call fig%set_object('ellipse', [7.0_R8P], [-0.6_R8P], width=1.6_R8P, height=0.5_R8P, angle=30.0_R8P)
   call fig%set_object('polygon', [0.5_R8P, 1.5_R8P, 1.0_R8P], [0.6_R8P, 0.6_R8P, 0.95_R8P], fc='#009e73', &
                       fs='solid 0.6', layer='front')
   call fig%set_label('peak', 1.5708_R8P, 1.0_R8P, point=.true., pt=7_I4P, offset=[1.0_R8P, 0.0_R8P])
   call fig%set_label('centre', 0.5_R8P, 0.5_R8P, system='graph', justify='center')
   call fig%set_label('rotated', 9.2_R8P, -0.9_R8P, rotate=60.0_R8P, color='red')
   call fig%set_label('screen', 0.98_R8P, 0.03_R8P, system='screen', justify='right', front=.true.)
   call fig%set_arrow(3.0_R8P, -0.2_R8P, 4.6_R8P, -0.9_R8P)
   call fig%set_arrow(3.0_R8P, 0.2_R8P, 4.6_R8P, 0.8_R8P, head='heads', filled='filled', lc='#9400d3', lw=2.0_R8P)
   call fig%set_arrow(8.9_R8P, 0.2_R8P, -1.0_R8P, 0.3_R8P, relative=.true., head='backhead', filled='empty', &
                      length=0.3_R8P, angle=25.0_R8P)
   call fig%set_arrow(0.05_R8P, 0.1_R8P, 0.25_R8P, 0.1_R8P, system='graph', head='nohead', dt=2_I4P, front=.true.)
   call fig%plot(x, sin(x), title='sin(x)')
   endfunction figure_annotations

   function figure_annotation_styles() result(fig)
   !< Dashed object borders (`set object ... dt N`), a label and an arrow in character coordinates (cells from the
   !< page's bottom left), a label mixing character and graph coordinates.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   x = [(0.1_R8P * real(i, R8P), i = 0, 100)]
   call fig%init(width=640_I4P, height=400_I4P)
   call fig%set_title('dashed objects, character coordinates')
   call fig%set_object('rectangle', [1.0_R8P, 3.0_R8P], [0.2_R8P, 0.8_R8P], fc='#e0e0ff', lw=2.0_R8P, dt=2_I4P)
   call fig%set_object('circle', [7.0_R8P], [-0.4_R8P], radius=0.8_R8P, dt=3_I4P, lw=1.5_R8P)
   call fig%set_object('ellipse', [5.0_R8P], [0.5_R8P], width=2.0_R8P, height=0.6_R8P, angle=-20.0_R8P, fc='#e69f00', &
                       fs='solid 0.4 border', dt=4_I4P)
   call fig%set_label('at character 12, 6', 12.0_R8P, 6.0_R8P, system='character')
   call fig%set_label('character 12, graph 0.55', 12.0_R8P, 0.55_R8P, system='character graph')
   call fig%set_arrow(30.0_R8P, 6.0_R8P, 0.5_R8P, 0.1_R8P, system='character', to_system='graph', filled='filled', &
                      lc='#9400d3')
   call fig%plot(x, sin(x), title='sin(x)')
   endfunction figure_annotation_styles

   function figure_tic_labels_fills() result(fig)
   !< Two panels: text labels on the y axis (gnuplot `ytic`) of a line with a marker every 3 points (`pointinterval`)
   !< and red error bars with long caps (`set errorbars 2 lc rgb "red"`); curves filled to the left border (`y1`), to
   !< the right one (`y2`) and to the line x = 5 (`x=5`).
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   x = [(real(i, R8P), i = 0, 9)]
   call fig%init(width=640_I4P, height=320_I4P)
   call fig%set_multiplot(rows=1_I4P, cols=2_I4P)
   call fig%set_title('ytic labels, pointinterval, errorbars')
   call fig%set_errorbars(size=2.0_R8P, lc='red')
   call fig%plot(x, [1.0_R8P, 3.0_R8P, 2.0_R8P, 5.0_R8P, 4.0_R8P, 6.0_R8P, 5.0_R8P, 7.0_R8P, 6.0_R8P, 8.0_R8P], &
                 title='pi 3', with='linespoints', pt=7_I4P, pi=3_I4P, &
                 xlabels=[character(len=4) :: 'one', 'low', '', 'mid', '', '', '', 'top', '', 'high'], labels_axis='y')
   call fig%plot([1.5_R8P, 4.5_R8P, 7.5_R8P], [2.0_R8P, 4.5_R8P, 6.5_R8P], title='errors', with='yerrorbars', &
                 ylow=[1.5_R8P, 3.5_R8P, 6.0_R8P], yhigh=[2.5_R8P, 5.5_R8P, 7.0_R8P])
   call fig%next_panel
   call fig%set_title('filledcurves y1, y2, x=5')
   call fig%set_errorbars
   call fig%set_xrange(0.0_R8P, 10.0_R8P)
   call fig%plot(x(3:6), [6.0_R8P, 7.0_R8P, 6.5_R8P, 7.5_R8P], title='y1', with='filledcurves', curve='y1')
   call fig%plot(x(5:8), [3.0_R8P, 4.0_R8P, 3.5_R8P, 4.5_R8P], title='y2', with='filledcurves', curve='y2', &
                 fs='transparent solid 0.5')
   call fig%plot(x(2:9), [0.5_R8P, 1.5_R8P, 1.0_R8P, 2.0_R8P, 1.0_R8P, 2.5_R8P, 1.5_R8P, 2.0_R8P], title='x=5', &
                 with='filledcurves', curve='x=5', fs='pattern 4')
   endfunction figure_tic_labels_fills

   function figure_histogram_layouts() result(fig)
   !< The histogram layouts of gnuplot 6.0: groups (`newhistogram`, the second from linetype 4, titled below the x
   !< axis), column stacks (rows in their linetype colors, named in the key), error bars (lw 2).
   type(figure_object) :: fig !< Figure.
   real(R8P)           :: rows(3) = [0.0_R8P, 1.0_R8P, 2.0_R8P] !< Row numbers.

   call fig%init(width=900_I4P, height=320_I4P)
   call fig%set_multiplot(rows=1_I4P, cols=3_I4P, title='histogram layouts')
   call fig%set_style_fill('solid 0.8 border -1')
   call fig%set_title('newhistogram')
   call fig%set_style_histogram('clustered', gap=1.0_R8P)
   call fig%new_histogram(title='A')
   call fig%plot(rows, [1.0_R8P, 2.0_R8P, 3.0_R8P], title='a', with='histograms', xlabels=['r1', 'r2', 'r3'])
   call fig%plot(rows, [2.0_R8P, 3.0_R8P, 1.0_R8P], title='b', with='histograms')
   call fig%new_histogram(title='B', lt=4_I4P)
   call fig%plot(rows, [3.0_R8P, 1.0_R8P, 2.0_R8P], title='c', with='histograms', xlabels=['r1', 'r2', 'r3'])
   call fig%next_panel()
   call fig%set_title('columnstacked')
   call fig%set_style_histogram('columnstacked')
   call fig%plot(rows, [1.0_R8P, 2.0_R8P, 3.0_R8P], title='a', with='histograms', xlabels=['a', ' ', ' '])
   call fig%plot(rows, [2.0_R8P, 3.0_R8P, 1.0_R8P], title='b', with='histograms', xlabels=['b', ' ', ' '])
   call fig%plot(rows, [3.0_R8P, 1.0_R8P, 2.0_R8P], title='c', with='histograms', xlabels=['c', ' ', ' '], &
                 labels=['r1', 'r2', 'r3'])
   call fig%next_panel()
   call fig%set_title('errorbars')
   call fig%set_style_histogram('errorbars', gap=1.0_R8P, lw=2.0_R8P)
   call fig%plot(rows, [1.0_R8P, 2.0_R8P, 3.0_R8P], title='a', with='histograms', ylow=[0.9_R8P, 1.8_R8P, 2.7_R8P], &
                 yhigh=[1.1_R8P, 2.2_R8P, 3.3_R8P], xlabels=['r1', 'r2', 'r3'])
   call fig%plot(rows, [2.0_R8P, 3.0_R8P, 1.0_R8P], title='b', with='histograms', ylow=[1.8_R8P, 2.9_R8P, 0.7_R8P], &
                 yhigh=[2.2_R8P, 3.1_R8P, 1.3_R8P])
   endfunction figure_histogram_layouts

   function figure_time_axis() result(fig)
   !< Time axes (gnuplot `set xdata time`): a day of half-hourly values over midnight, gnuplot's invented two-line
   !< labels `%d/%m\n%H:%M` (the timefmt has the day first); five weeks labelled `%d %b`, minor ticks by day.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: t(:) !< Times [s since 1970].
   integer(I4P)           :: i    !< Counter.

   ! 2024-03-01 10:00 UTC, every 30 minutes for a day
   t = [(1709287200.0_R8P + 1800.0_R8P * real(i, R8P), i = 0, 48)]
   call fig%init(width=720_I4P, height=320_I4P)
   call fig%set_multiplot(rows=1_I4P, cols=2_I4P, title='time axes')
   call fig%set_title('a day')
   call fig%set_time_axes('x', timefmt='%d/%m/%Y %H:%M')
   call fig%plot(t, 20.0_R8P + 5.0_R8P * sin(real([(i, i = 0, 48)], R8P) * 0.13_R8P), title='T [C]')
   call fig%next_panel()
   call fig%set_title('five weeks')
   call fig%set_time_axes('x')
   call fig%set_format('%d %b', 'x')
   call fig%set_mxtics(7_I4P)
   t = [(1709251200.0_R8P + 86400.0_R8P * real(i, R8P), i = 0, 35)]
   call fig%plot(t, real([(mod(i * 7, 11), i = 0, 35)], R8P), title='jobs', with='linespoints')
   endfunction figure_time_axis

   function figure_key_at() result(fig)
   !< The key at a position (gnuplot `set key at`): two panels, the bottom left corner of a boxed key on the data point
   !< (2, 0.5), a key centred on the plot area in graph coordinates, one in the right margin (gnuplot `rmargin`).
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   integer(I4P)           :: i    !< Counter.

   x = [(0.1_R8P * real(i, R8P), i = 0, 40)]
   call fig%init(width=720_I4P, height=300_I4P)
   call fig%set_multiplot(rows=1_I4P, cols=3_I4P, title='set key at, rmargin')
   call fig%set_key(position='left bottom', box=.true., at=[2.0_R8P, 0.5_R8P])
   call fig%plot(x, sin(x), title='sin')
   call fig%plot(x, cos(x), title='cos')
   call fig%next_panel()
   call fig%set_key(position='center center', at=[0.5_R8P, 0.5_R8P], system='graph')
   call fig%plot(x, x**2, title='x^2')
   call fig%next_panel()
   call fig%set_key(position='rmargin bottom')
   call fig%set_xtics(step=2.0_R8P)
   call fig%plot(x, exp(-x), title='exp(-x)')
   endfunction figure_key_at

   function figure_lc_palette() result(fig)
   !< Colors from the palette, gnuplot `lc palette`: a spiral colored by its radius (`z`, the color box spanning it),
   !< points by their value, and a constant fraction of the palette.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: t(:) !< Parameter.
   integer(I4P)           :: i    !< Counter.

   t = [(0.15_R8P * real(i, R8P), i = 0, 60)]
   call fig%init(width=520_I4P, height=320_I4P)
   call fig%set_cblabel('radius')
   call fig%plot(t * cos(t), t * sin(t), title='spiral', with='lines', lw=2.0_R8P, palette_z=t)
   call fig%plot(t(::6) * cos(t(::6)) + 1.0_R8P, -t(::6) * sin(t(::6)), title='points', with='points', pt=7_I4P, &
                 palette_z=t(::6))
   call fig%plot([-9.0_R8P, -4.0_R8P], [-6.5_R8P, -6.5_R8P], title='frac 0.8', with='lines', lw=3.0_R8P, &
                 palette_frac=0.8_R8P)
   endfunction figure_lc_palette

   function figure_lc_variable() result(fig)
   !< Colors per point, gnuplot `lc variable`: a line whose segments take the color of their end point, points by
   !< class, impulses by sign.
   type(figure_object)         :: fig     !< Figure.
   real(R8P)                   :: t(13)   !< Abscissae.
   character(len=7), parameter :: C(3) = ['#9400d3', '#009e73', '#e69f00'] !< Class colors.
   character(len=7)            :: phase(13) !< Colors of the line, by class.
   character(len=7)            :: sign(13)  !< Colors of the impulses, by sign.
   integer(I4P)                :: i       !< Counter.

   t = [(0.5_R8P * real(i, R8P), i = 0, 12)]
   ! a loop: nvfortran 26.9 returns the first argument of a character merge in an implied-do constructor
   do i = 1, 13
      phase(i) = C(1 + modulo(int(t(i)), 3))
      sign(i) = C(3)
      if (cos(t(i)) >= 0.0_R8P) sign(i) = C(2)
   enddo
   call fig%init(width=520_I4P, height=320_I4P)
   call fig%plot(t, sin(t), title='phase', with='linespoints', colors=phase)
   call fig%plot(t, cos(t) - 1.5_R8P, title='sign', with='impulses', colors=sign)
   endfunction figure_lc_variable

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

   function figure_identity(name) result(fig)
   !< foresight's identity themes: the eight series colors on the grid, with the key, the labels and the title.
   character(len=*), intent(in) :: name  !< Theme name.
   type(figure_object)          :: fig   !< Figure.
   real(R8P), allocatable       :: t(:)  !< Abscissae.
   integer(I4P)                 :: i     !< Counter.
   integer(I4P)                 :: k     !< Series counter.

   t = [(0.25_R8P * real(i, R8P), i = 0, 24)]
   call fig%init(width=560_I4P, height=320_I4P)
   call fig%set_theme(name=name)
   call fig%set_title('series colors of '//name)
   call fig%set_xlabel('t')
   call fig%set_ylabel('u')
   call fig%set_grid
   call fig%set_key(position='outside')
   do k = 1_I4P, 8_I4P
      call fig%plot(t, sin(t + 0.4_R8P * real(k, R8P)) + 0.5_R8P * real(k, R8P), title='lt '//achar(48 + k), &
                    with='linespoints', pt=7_I4P, ps=0.6_R8P)
   enddo
   endfunction figure_identity

   function figure_theme_block() result(fig)
   !< The vfd display on the block device in true colors: the theme recolors the series only.
   type(figure_object) :: fig !< Figure.

   fig = figure_theme('vfd')
   call fig%set_text(charset='quadrants', colors='ansirgb')
   endfunction figure_theme_block

   function figure_image(palette, theme, cbmax, gradient) result(fig)
   !< A heatmap of a 21 x 15 grid with an undefined (transparent) pixel, in the `palette`: x and y fit the pixel edges,
   !< the color box at the right with its label; `cbmax` sets the symmetric color range [-cbmax:cbmax].
   character(len=*), intent(in)           :: palette !< Palette words.
   character(len=*), intent(in), optional :: theme   !< Theme name.
   real(R8P),        intent(in), optional :: cbmax   !< Half width of a symmetric color range.
   logical,          intent(in), optional :: gradient !< First the gradient blue, white, red at 0, 1, 2.
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
   if (present(gradient)) call fig%set_palette_gradient([0.0_R8P, 1.0_R8P, 2.0_R8P], &
      reshape([0.0_R8P, 0.0_R8P, 1.0_R8P, 1.0_R8P, 1.0_R8P, 1.0_R8P, 1.0_R8P, 0.0_R8P, 0.0_R8P], [3, 3]))
   call fig%set_palette(palette)
   if (present(cbmax)) call fig%set_cbrange(-cbmax, cbmax)
   call fig%set_cblabel('phi')
   call fig%image(z, x, y, title='field')
   endfunction figure_image

   function figure_map_points() result(fig)
   !< A map view (gnuplot `set view map`) of scattered points colored by their height, a title, axis labels and the
   !< color box at gnuplot's map places.
   type(figure_object)    :: fig  !< Figure.
   real(R8P), allocatable :: x(:) !< Abscissae.
   real(R8P), allocatable :: y(:) !< Ordinates.
   real(R8P), allocatable :: z(:) !< Heights.
   integer(I4P)           :: k    !< Point counter.

   call fig%init(width=600_I4P, height=400_I4P)
   x = [(4.0_R8P * cos(0.37_R8P * real(k, R8P)) * real(k, R8P) / 40.0_R8P, k = 1, 40)]
   y = [(3.0_R8P * sin(0.37_R8P * real(k, R8P)) * real(k, R8P) / 40.0_R8P, k = 1, 40)]
   z = x * y
   call fig%set_view(map=.true.)
   call fig%set_title('spiral')
   call fig%set_xlabel('x')
   call fig%set_ylabel('y')
   call fig%splot(x, y, z, title='x*y', pt=7_I4P, palette=.true.)
   endfunction figure_map_points

   function figure_map_image() result(fig)
   !< A map view of a grid drawn as an image (gnuplot `splot ... with image`), the color box at the map's place.
   type(figure_object)    :: fig    !< Figure.
   real(R8P), allocatable :: x(:)   !< Pixel centre abscissae.
   real(R8P), allocatable :: y(:)   !< Pixel centre ordinates.
   real(R8P), allocatable :: z(:,:) !< Values.
   integer(I4P)           :: i      !< Column counter.
   integer(I4P)           :: j      !< Row counter.

   call fig%init(width=500_I4P, height=360_I4P)
   x = [(real(i, R8P), i = 0, 15)]
   y = [(real(j, R8P), j = 0, 11)]
   allocate(z(size(x), size(y)))
   do j = 1_I4P, size(y, kind=I4P)
      do i = 1_I4P, size(x, kind=I4P)
         z(i, j) = sin(0.4_R8P * x(i)) * cos(0.5_R8P * y(j))
      enddo
   enddo
   call fig%set_view(map=.true.)
   call fig%set_palette('viridis')
   call fig%set_cblabel('w')
   call fig%splot(x, y, z, with='image', title='w')
   endfunction figure_map_image

   function figure_map_pm3d(steps) result(fig)
   !< A map view of a surface drawn with pm3d (gnuplot `splot ... with pm3d`): a 9 x 7 grid of a Gaussian bump, each
   !< quadrangle in the palette color of its corners' mean, subdivided `steps` times each way (`set pm3d interpolate`).
   integer(I4P), intent(in) :: steps  !< Interpolation steps.
   type(figure_object)      :: fig    !< Figure.
   real(R8P), allocatable   :: x(:)   !< Abscissae.
   real(R8P), allocatable   :: y(:)   !< Ordinates.
   real(R8P), allocatable   :: z(:,:) !< Heights.
   integer(I4P)             :: i      !< Column counter.
   integer(I4P)             :: j      !< Row counter.

   call fig%init(width=500_I4P, height=360_I4P)
   x = [(-2.0_R8P + 0.5_R8P * real(i, R8P), i = 0, 8)]
   y = [(-1.5_R8P + 0.5_R8P * real(j, R8P), j = 0, 6)]
   allocate(z(size(x), size(y)))
   do j = 1_I4P, size(y, kind=I4P)
      do i = 1_I4P, size(x, kind=I4P)
         z(i, j) = exp(-(x(i)**2 + 2.0_R8P * y(j)**2))
      enddo
   enddo
   call fig%set_view(map=.true.)
   call fig%set_pm3d(interpolate=[steps, steps])
   call fig%set_title('pm3d')
   call fig%splot(x, y, z, with='pm3d', title='bump')
   endfunction figure_map_pm3d

   function figure_map_contour() result(fig)
   !< A map view of a surface with its contour lines (gnuplot `set contour`): automatic levels, a linetype and key
   !< entry each, the surface drawn as its iso-lines.
   type(figure_object)    :: fig    !< Figure.
   real(R8P), allocatable :: x(:)   !< Abscissae.
   real(R8P), allocatable :: y(:)   !< Ordinates.
   real(R8P), allocatable :: z(:,:) !< Heights.
   integer(I4P)           :: i      !< Column counter.
   integer(I4P)           :: j      !< Row counter.

   call fig%init(width=560_I4P, height=400_I4P)
   x = [(-3.0_R8P + 0.25_R8P * real(i, R8P), i = 0, 24)]
   y = [(-2.0_R8P + 0.25_R8P * real(j, R8P), j = 0, 16)]
   allocate(z(size(x), size(y)))
   do j = 1_I4P, size(y, kind=I4P)
      do i = 1_I4P, size(x, kind=I4P)
         z(i, j) = x(i) * exp(-(x(i)**2 + y(j)**2) / 2.0_R8P)
      enddo
   enddo
   call fig%set_view(map=.true.)
   call fig%set_contour(levels=6_I4P)
   call fig%set_title('contours')
   call fig%splot(x, y, z, title='x exp(-r^2/2)', lc='#c0c0c0')
   endfunction figure_map_contour

   function figure_map_dgrid3d() result(fig)
   !< A map view of scattered points gridded (gnuplot `set dgrid3d`, a Gaussian kernel) and drawn with pm3d: 60 points
   !< on a sunflower spiral, their heights a tilted saddle.
   type(figure_object)    :: fig    !< Figure.
   real(R8P), allocatable :: x(:)   !< Abscissae.
   real(R8P), allocatable :: y(:)   !< Ordinates.
   real(R8P), allocatable :: z(:)   !< Heights.
   real(R8P), parameter   :: GOLDEN_ANGLE = 2.399963229728653_R8P !< Spiral step [rad].
   integer(I4P)           :: k      !< Point counter.

   call fig%init(width=500_I4P, height=360_I4P)
   x = [(sqrt(real(k, R8P) / 60.0_R8P) * 2.0_R8P * cos(GOLDEN_ANGLE * real(k, R8P)), k = 1, 60)]
   y = [(sqrt(real(k, R8P) / 60.0_R8P) * 2.0_R8P * sin(GOLDEN_ANGLE * real(k, R8P)), k = 1, 60)]
   z = x * y + 0.5_R8P * x
   call fig%set_view(map=.true.)
   call fig%set_dgrid3d(rows=25_I4P, cols=25_I4P, mode='gauss', scale=[0.6_R8P, 0.6_R8P])
   call fig%set_title('dgrid3d')
   call fig%splot(x, y, z, with='pm3d', title='saddle')
   endfunction figure_map_dgrid3d

   function figure_view3d_frame() result(fig)
   !< A 3D view of a surface (gnuplot `splot` of a grid, its default view): the mesh of the grid, the box, the x, y and
   !< z ticks and labels, the key and the title.
   type(figure_object)    :: fig    !< Figure.
   real(R8P), allocatable :: x(:)   !< Abscissae.
   real(R8P), allocatable :: y(:)   !< Ordinates.
   real(R8P), allocatable :: z(:,:) !< Heights.
   integer(I4P)           :: i      !< Column counter.
   integer(I4P)           :: j      !< Row counter.

   call fig%init(width=600_I4P, height=400_I4P)
   x = [(-2.0_R8P + 0.25_R8P * real(i, R8P), i = 0, 16)]
   y = [(-3.0_R8P + 0.375_R8P * real(j, R8P), j = 0, 16)]
   allocate(z(size(x), size(y)))
   do j = 1_I4P, size(y, kind=I4P)
      do i = 1_I4P, size(x, kind=I4P)
         z(i, j) = sin(x(i)) * cos(y(j))
      enddo
   enddo
   call fig%set_title('sin(x) cos(y)')
   call fig%set_xlabel('x')
   call fig%set_ylabel('y')
   call fig%set_zlabel('z')
   call fig%splot(x, y, z, title='surface')
   endfunction figure_view3d_frame

   function figure_colorbox_modes() result(fig)
   !< Color boxes: horizontal below the plot, vertical inverted without border, and a user box over the plot.
   type(figure_object) :: fig     !< Figure.
   real(R8P)           :: z(21,15) !< Values.
   integer(I4P)        :: i       !< Column counter.
   integer(I4P)        :: j       !< Row counter.

   do j = 1_I4P, 15_I4P
      do i = 1_I4P, 21_I4P
         z(i, j) = exp(-(real(i - 11, R8P)**2 + real(j - 8, R8P)**2) / 24.0_R8P)
      enddo
   enddo
   call fig%init(width=900_I4P, height=320_I4P)
   call fig%set_multiplot(rows=1_I4P, cols=3_I4P)
   call fig%set_palette('viridis')
   call fig%set_cblabel('phi')
   call fig%set_colorbox(horizontal=.true.)
   call fig%image(z)
   call fig%next_panel
   call fig%set_colorbox(horizontal=.false., invert=.true., border=.false.)
   call fig%image(z)
   call fig%next_panel
   call fig%set_colorbox(border=.true., invert=.false., user=.true., origin=[0.9_R8P, 0.25_R8P], size=[0.02_R8P, 0.5_R8P])
   call fig%image(z)
   endfunction figure_colorbox_modes

   function figure_logcb() result(fig)
   !< A log color axis, gray palette: values 3, 30, 700 and 0, -5, 50; the axis spans the positive extent 3..700 (not
   !< decades), the nonpositive values take the low end, as gnuplot 6.0 (pixel for pixel).
   type(figure_object) :: fig    !< Figure.
   real(R8P)           :: z(3,2) !< Values.

   z = reshape([3.0_R8P, 30.0_R8P, 700.0_R8P, 0.0_R8P, -5.0_R8P, 50.0_R8P], [3, 2])
   call fig%init(width=420_I4P, height=300_I4P)
   call fig%set_logscale('cb')
   call fig%set_palette('gray')
   call fig%set_cblabel('z')
   call fig%image(z)
   endfunction figure_logcb

   function figure_colorsequence() result(fig)
   !< Seven curves in the first six colors of Crameri's categorical batlowS order (the seventh cycles to the first).
   type(figure_object) :: fig   !< Figure.
   real(R8P)           :: x(41) !< Abscissae.
   integer(I4P)        :: i     !< Point counter.
   integer(I4P)        :: k     !< Curve counter.

   x = [(0.1_R8P * real(i, R8P), i = 0, 40)]
   call fig%init(width=420_I4P, height=300_I4P)
   call fig%set_colorsequence('batlowS', colors=6_I4P)
   do k = 1_I4P, 7_I4P
      call fig%plot(x, sin(x + 0.4_R8P * real(k, R8P)) + 0.3_R8P * real(k, R8P), title='curve '//achar(48 + k))
   enddo
   endfunction figure_colorsequence

   function figure_short_panels() result(fig)
   !< Four 60 px panels with titles and no tics nor border: without x tick labels the bottom margin drops their row (as
   !< gnuplot), so each keeps a plot area.
   type(figure_object) :: fig     !< Figure.
   real(R8P)           :: z(32,2) !< Ramp values.
   integer(I4P)        :: i       !< Column counter.
   integer(I4P)        :: k       !< Panel counter.

   do i = 1_I4P, 32_I4P
      z(i, :) = real(i - 1_I4P, R8P)
   enddo
   call fig%init(width=300_I4P, height=240_I4P)
   call fig%set_multiplot(rows=4_I4P, cols=1_I4P)
   do k = 1_I4P, 4_I4P
      if (k > 1_I4P) call fig%next_panel
      call fig%set_title('panel')
      call fig%set_colorbox(.false.)
      call fig%set_border(0_I4P)
      call fig%unset_xtics
      call fig%unset_ytics
      call fig%set_palette('batlow')
      call fig%image(z)
   enddo
   endfunction figure_short_panels

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

   function figure_shapes() result(fig)
   !< The geometric styles of gnuplot: vectors (open and filled heads) with labels marking their points; arrows by
   !< length and angle, ellipses (sized and default); polygons of two blocks; sectors about the origin and off centre.
   type(figure_object) :: fig  !< Figure.
   real(R8P)           :: x(3) !< Abscissae.
   real(R8P)           :: y(3) !< Ordinates.
   real(R8P)           :: nan  !< Block separator.

   x = [1.0_R8P, 2.0_R8P, 4.0_R8P]
   y = [1.0_R8P, 3.0_R8P, 2.0_R8P]
   nan = ieee_value(1.0_R8P, ieee_quiet_nan)
   call fig%init(width=760_I4P, height=560_I4P)
   call fig%set_multiplot(rows=2_I4P, cols=2_I4P)
   call fig%set_key(position='top left')
   call fig%set_xrange(0.0_R8P, 6.0_R8P)
   call fig%set_yrange(0.0_R8P, 6.0_R8P)
   call fig%plot(x, y, title='vectors', with='vec', dx=[2.0_R8P, -1.0_R8P, 1.0_R8P], dy=[1.0_R8P, 2.0_R8P, -1.0_R8P])
   call fig%plot(x + 0.5_R8P, y, title='heads filled', with='vectors', dx=[2.0_R8P, -1.0_R8P, 1.0_R8P], &
                 dy=[1.0_R8P, 2.0_R8P, -1.0_R8P], head='heads filled')
   call fig%plot(x, y, with='labels', labels=['a ', 'bb', 'c '], label='left offset 1,0 point', pt=7_I4P)
   call fig%next_panel
   call fig%plot(x, y, title='arrows', with='arrows', length=[1.5_R8P, 1.5_R8P, 1.5_R8P], &
                 angle=[0.0_R8P, 30.0_R8P, 60.0_R8P])
   call fig%plot(x + 1.0_R8P, y + 2.0_R8P, title='ellipses', with='ell', major=[2.0_R8P, -1.0_R8P, 1.0_R8P], &
                 minor=[1.0_R8P, 1.0_R8P, -1.0_R8P], angle=[30.0_R8P, 30.0_R8P, 30.0_R8P])
   call fig%next_panel
   call fig%set_xrange()
   call fig%set_yrange()
   call fig%set_style_fill('solid 0.4')
   call fig%plot([0.0_R8P, 1.0_R8P, 1.0_R8P, nan, 2.0_R8P, 3.0_R8P, 2.5_R8P], &
                 [0.0_R8P, 0.0_R8P, 1.0_R8P, nan, 2.0_R8P, 2.0_R8P, 3.0_R8P], title='polygons', with='poly')
   call fig%next_panel
   call fig%set_angles('degrees')
   call fig%set_size(ratio=1.0_R8P)
   call fig%plot([0.0_R8P, 60.0_R8P, 180.0_R8P], [1.0_R8P, 1.0_R8P, 1.0_R8P], title='sectors', with='sectors', &
                 angle=[60.0_R8P, 120.0_R8P, 180.0_R8P], width=[0.5_R8P, 0.8_R8P, 0.3_R8P])
   call fig%plot([90.0_R8P], [0.5_R8P], title='off centre', with='sectors', angle=[90.0_R8P], width=[0.4_R8P], &
                 origins=reshape([1.0_R8P, 1.0_R8P], [2, 1]))
   endfunction figure_shapes

   function figure_windrose() result(fig)
   !< A wind rose of sectors on a polar panel: eight directions from the top clockwise, two speed classes stacked.
   type(figure_object) :: fig    !< Figure.
   real(R8P)           :: t(8)   !< Directions [deg].
   real(R8P)           :: low(8) !< Frequencies of the low speeds.
   real(R8P)           :: high(8) !< Frequencies of the high speeds.
   integer(I4P)        :: k      !< Counter.

   t = [(45.0_R8P * real(k, R8P) - 20.0_R8P, k = 0, 7)]
   low = [4.0_R8P, 2.0_R8P, 1.5_R8P, 3.0_R8P, 5.0_R8P, 6.0_R8P, 3.5_R8P, 2.5_R8P]
   high = [2.0_R8P, 1.0_R8P, 0.5_R8P, 1.5_R8P, 3.0_R8P, 4.0_R8P, 2.0_R8P, 1.0_R8P]
   call fig%init(width=520_I4P, height=420_I4P)
   call fig%set_polar
   call fig%set_angles('degrees')
   call fig%set_theta('top', clockwise=.true.)
   call fig%set_size(ratio=1.0_R8P)
   call fig%set_border(0_I4P, polar=.true.)
   call fig%unset_xtics
   call fig%unset_ytics
   call fig%set_grid(polar=45.0_R8P)
   call fig%set_ttics(step=45.0_R8P)
   call fig%set_key(position='outside')
   call fig%set_style_fill('solid 0.6 border lc "white"')
   call fig%plot(t, [(0.0_R8P, k = 1, 8)], title='< 5 m/s', with='sectors', angle=[(40.0_R8P, k = 1, 8)], width=low)
   call fig%plot(t, low, title='>= 5 m/s', with='sectors', angle=[(40.0_R8P, k = 1, 8)], width=high)
   endfunction figure_windrose

   function figure_patterns() result(fig)
   !< The fills of gnuplot: the 8 patterns of its svg terminal cycling from `set style fill pattern 1`; filledcurves
   !< to the bottom (x1) and top (x2), above and below a line, to a point (xy=), a band where its first curve is above;
   !< an RGB image with an alpha channel.
   type(figure_object) :: fig     !< Figure.
   real(R8P)           :: x(5)    !< Abscissae.
   real(R8P)           :: y(5)    !< Ordinates.
   real(R8P)           :: y2(5)   !< Second curve.
   integer(I4P)        :: k       !< Counter.

   x = [0.0_R8P, 1.0_R8P, 2.0_R8P, 3.0_R8P, 4.0_R8P]
   y = [1.0_R8P, 3.0_R8P, 0.5_R8P, 2.0_R8P, 1.0_R8P]
   y2 = [2.0_R8P, 1.0_R8P, 1.5_R8P, 0.5_R8P, 2.5_R8P]
   call fig%init(width=900_I4P, height=600_I4P)
   call fig%set_multiplot(rows=2_I4P, cols=3_I4P)
   call fig%set_key(.false.)
   call fig%set_title('patterns')
   call fig%set_boxwidth(0.8_R8P)
   call fig%set_style_fill('pattern 1')
   do k = 0, 7
      call fig%plot([real(k, R8P)], [1.0_R8P], with='boxes')
   enddo
   call fig%next_panel
   call fig%set_boxwidth()
   call fig%set_style_fill('solid 0.4')
   call fig%set_xrange(-1.0_R8P, 5.0_R8P)
   call fig%set_yrange(-1.0_R8P, 4.0_R8P)
   call fig%set_title('x1, x2')
   call fig%plot(x, y, with='filledcurves', curve='x1')
   call fig%plot(x, y + 1.0_R8P, with='filledcurves', curve='x2')
   call fig%next_panel
   call fig%set_title('above, below y=1.5')
   call fig%plot(x, y, with='filledcurves', base=1.5_R8P, curve='above')
   call fig%plot(x, y, with='filledcurves', base=1.5_R8P, curve='below')
   call fig%plot(x, y, lc='black')
   call fig%next_panel
   call fig%set_title('xy=2,0')
   call fig%plot(x, y, with='filledcurves', curve='xy=2,0')
   call fig%plot(x, y, lc='black')
   call fig%next_panel
   call fig%set_title('band above')
   call fig%plot(x, y, with='filledcurves', ylow=y2, curve='above')
   call fig%plot(x, y, lc='black')
   call fig%plot(x, y2, lc='blue')
   call fig%next_panel
   call fig%set_xrange()
   call fig%set_yrange()
   call fig%set_title('rgbalpha')
   call fig%rgbimage(reshape([255.0_R8P, 0.0_R8P, 0.0_R8P, 255.0_R8P], [2, 2]), &
                     reshape([0.0_R8P, 255.0_R8P, 0.0_R8P, 255.0_R8P], [2, 2]), &
                     reshape([0.0_R8P, 0.0_R8P, 255.0_R8P, 0.0_R8P], [2, 2]), &
                     alpha=reshape([255.0_R8P, 128.0_R8P, 255.0_R8P, 0.0_R8P], [2, 2]))
   endfunction figure_patterns

   function figure_spider() result(fig)
   !< The axis-based plots of gnuplot over five scores of three rows: parallel axes (ticks on the second) and a spider
   !< plot (axes from 0 to 100, ticks and the web on the first, filled polygons named by the rows).
   type(figure_object) :: fig       !< Figure.
   real(R8P)           :: v(3, 5)   !< Scores (row, axis).
   character(len=1)    :: names(5)  !< Axis names.
   integer(I4P)        :: k         !< Axis counter.

   v = reshape([15.0_R8P, 40.0_R8P, 70.0_R8P, 75.0_R8P, 40.0_R8P, 20.0_R8P, 20.0_R8P, 40.0_R8P, 85.0_R8P, &
                43.0_R8P, 60.0_R8P, 30.0_R8P, 90.0_R8P, 30.0_R8P, 55.0_R8P], [3, 5])
   names = ['A', 'B', 'C', 'D', 'E']
   call fig%init(width=900_I4P, height=420_I4P)
   call fig%set_multiplot(rows=1_I4P, cols=2_I4P)
   call fig%set_title('parallelaxes')
   call fig%set_paxis(2_I4P, tics=.true.)
   do k = 1, 5
      call fig%plot([0.0_R8P, 1.0_R8P, 2.0_R8P], v(:, k), title=names(k), with='parallelaxes')
   enddo
   call fig%next_panel
   call fig%set_title('spiderplot')
   call fig%set_spiderplot
   call fig%set_style_spiderplot('fs transparent solid 0.2 border')
   do k = 1, 5
      call fig%set_paxis(int(k, I4P), min=0.0_R8P, max=100.0_R8P)
   enddo
   call fig%set_paxis(1_I4P, tics=.true., label='unused')
   call fig%set_grid(spider=.true.)
   call fig%plot([0.0_R8P, 1.0_R8P, 2.0_R8P], v(:, 1), title=names(1), with='spiderplot', &
                 labels=['George ', 'Harriet', 'Ivan   '])
   do k = 2, 5
      call fig%plot([0.0_R8P, 1.0_R8P, 2.0_R8P], v(:, k), title=names(k), with='spiderplot')
   enddo
   endfunction figure_spider

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
      if (exists) passed = same_page(produced, read_text(golden))
      if (.not. passed) write(error_unit, '(A)') name//': '//output//' differs from '//golden// &
                                                 ' (FORESIGHT_UPDATE_GOLDEN=1 rewrites it)'
   endif
   if (passed) then
      open(newunit=unit, file=output)
      close(unit, status='delete')
   endif
   endfunction check

   function rendered(fig) result(text)
   !< The SVG of `fig`, through a scratch file.
   type(figure_object), intent(in) :: fig    !< Figure.
   character(len=:), allocatable   :: text   !< SVG.
   type(figure_object)             :: figure !< Figure being rendered.
   integer(I4P)                    :: unit   !< File unit.

   figure = fig
   call figure%save('foresight_golden_rendered.svg')
   text = read_text('foresight_golden_rendered.svg')
   open(newunit=unit, file='foresight_golden_rendered.svg')
   close(unit, status='delete')
   endfunction rendered

   function same_page(produced, reference) result(same)
   !< Whether `produced` matches `reference`. An HTML page is compared outside its script, the embedded viewer, which
   !< must be src/js/viewer.js itself: a viewer change neither rewrites every HTML reference nor goes unembedded.
   character(len=*), intent(in)  :: produced  !< Rendered content.
   character(len=*), intent(in)  :: reference !< Reference content.
   logical                       :: same      !< Match.
   character(len=*), parameter   :: OPEN_TAG = '<script>'   !< Script start.
   character(len=*), parameter   :: CLOSE_TAG = '</script>' !< Script end.
   integer                       :: p(2)      !< Script start and end in `produced`.
   integer                       :: r(2)      !< Script start and end in `reference`.

   p = [index(produced, OPEN_TAG), index(produced, CLOSE_TAG, back=.true.)]
   r = [index(reference, OPEN_TAG), index(reference, CLOSE_TAG, back=.true.)]
   if (any(p == 0) .or. any(r == 0)) then
      same = produced == reference
      return
   endif
   same = produced(1:p(1) + len(OPEN_TAG) - 1) == reference(1:r(1) + len(OPEN_TAG) - 1) .and. &
          produced(p(2):) == reference(r(2):)
   if (same) same = produced(p(1) + len(OPEN_TAG):p(2) - 1) == new_line('a')//read_text('src/js/viewer.js')
   endfunction same_page

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
