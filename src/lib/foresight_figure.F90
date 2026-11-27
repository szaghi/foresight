!< foresight_figure, a figure: page, font and a grid of plot panels, driven by a gnuplot-like API.
module foresight_figure
!< foresight_figure, a figure: page, font and a grid of plot panels, driven by a gnuplot-like API.
!<
!< Every method mirrors a gnuplot command (`plot`, `set title`, `set xrange`, `set logscale`, `set multiplot`, ...)
!< so that the command line interpreter maps one-to-one onto this API. Settings and plots apply to the current panel;
!< a figure has one panel unless `set_multiplot` lays out a grid, filled panel by panel with `next_panel`.
!<```fortran
!< type(figure_object) :: fig
!< real(R8P)           :: x(3), y(3)
!< x = [1.0_R8P, 2.0_R8P, 3.0_R8P]
!< y = x**2
!< call fig%set_title('parabola')
!< call fig%plot(x, y, title='x^2', with='linespoints')
!< call fig%save('parabola.svg')
!<```
use, intrinsic :: ieee_arithmetic, only : ieee_quiet_nan, ieee_value
use foresight_axes, only : axes_names, axes_object, boxplot_words, colorbox_object, key_position, paxis_object, &
                           polar_series, push, readout_position, spider_words, POLAR_STYLES
use foresight_axis, only : axis_object, paxis_default
use foresight_backend, only : backend_object
use foresight_backend_block, only : backend_block, BLOCK_CHARSETS
use foresight_backend_dumb, only : backend_dumb, TEXT_COLORS
use foresight_backend_html, only : backend_html
use foresight_backend_svg, only : backend_svg
use foresight_format, only : format_check, real_str
use foresight_time, only : time_format_check
use foresight_style, only : default_color, fill_style, sequence_colors, style_object, FILL_EMPTY, FILL_SOLID, WITH_HISTOGRAMS
use foresight_annotations, only : arrow_object, label_object, pixmap_object, place_object, push, shape_object
use foresight_theme, only : theme_named, theme_object, THEMES
use foresight_palette, only : palette_gradient, palette_words
use foresight_ticks, only : MINOR_AUTO, tic_item, tics_object, TICS_NONE
use foresight_font, only : font_object
use foresight_contour, only : CONTOUR_BSPLINE, CONTOUR_CUBIC, CONTOUR_LINEAR, LEVELS_AUTO, LEVELS_DISCRETE, &
                              LEVELS_INCREMENTAL
use foresight_dgrid3d, only : grid_series, DGRID_BOX, DGRID_CAUCHY, DGRID_EXP, DGRID_GAUSS, DGRID_HANN, DGRID_QNORM, &
                              DGRID_SPLINES
use foresight_pm3d, only : CORNERS_C1, CORNERS_GEOMEAN, CORNERS_HARMEAN, CORNERS_MAX, CORNERS_MEAN, CORNERS_MEDIAN, &
                           CORNERS_MIN, CORNERS_RMS
use penf, only : I4P, R8P

implicit none
private
public :: figure_object

real(R8P), parameter :: PAD         = 10.0_R8P !< Outer padding [px].
real(R8P), parameter :: GAP         = 6.0_R8P  !< Gap below the multiplot title [px].
real(R8P), parameter :: LINE_HEIGHT = 1.25_R8P !< Text line height [font size].

type :: figure_object
   !< Figure.
   real(R8P)                      :: width        = 600.0_R8P !< Page width [px], gnuplot svg terminal default.
   real(R8P)                      :: height       = 480.0_R8P !< Page height [px], gnuplot svg terminal default.
   real(R8P)                      :: font_size    = 12.0_R8P  !< Font size [px].
   logical                        :: latin1       = .false.   !< Texts in ISO 8859-1, written in UTF-8 (scripts' `set
                                                              !< encoding iso_8859_1`).
   logical                        :: enhanced     = .false.   !< Texts read as gnuplot's enhanced text (the scripts:
                                                              !< on, as gnuplot; the library: off unless set).
   integer(I4P)                   :: refresh      = 0_I4P     !< HTML page reload period [s], 0 for none.
   logical                        :: clear_screen = .false.   !< Clear the terminal before text output (live view).
   character(len=9)               :: text_charset = 'dumb'    !< Text output: `dumb` characters, or the block
                                                              !< character set `half`, `quadrants`, `sextants`,
                                                              !< `braille` (gnuplot `block` terminal).
   character(len=7)               :: text_colors  = 'mono'    !< Text output colors: `mono`, `ansi`, `ansi256`,
                                                              !< `ansirgb`.
   type(theme_object)             :: theme                    !< Output theme (foresight_theme), `classic` by default.
   logical                        :: theme_chosen = .false.   !< The theme was set: FORESIGHT_THEME no longer applies.
   integer(I4P)                   :: rows         = 1_I4P     !< Panel grid rows.
   integer(I4P)                   :: cols         = 1_I4P     !< Panel grid columns.
   integer(I4P)                   :: current      = 1_I4P     !< Current panel, filled row by row.
   logical                        :: layout       = .false.   !< Multiplot grid: panels in cells, else in their
                                                              !< `origin`/`size` boxes (single plot, manual multiplot).
   logical                        :: columns_first = .false.  !< Layout filled column by column (gnuplot
                                                              !< `columnsfirst`), else row by row.
   logical                        :: upwards      = .false.   !< Layout filled from the bottom row (gnuplot
                                                              !< `upwards`), else from the top.
   logical                        :: manual       = .false.   !< Manual multiplot: panels added on demand.
   character(len=:), allocatable  :: title                    !< Multiplot title, empty for none.
   type(font_object)              :: title_font               !< Multiplot title font (`set multiplot title ... font`).
   character(len=48)              :: font_family = ''         !< Page font family (`set terminal ... font "name,size"`),
                                                              !< empty for foresight's.
   type(axes_object), allocatable :: panels(:)                !< Plot panels.
   real(R8P)                      :: layout_margins(4) = -1.0_R8P !< Layout plot areas within left, right, bottom, top
                                                                  !< (gnuplot `set multiplot ... margins`): screen
                                                                  !< fractions, characters with `layout_chars`; -1 none.
   logical                        :: layout_chars(4) = .false.    !< Those margins are in characters.
   real(R8P)                      :: layout_spacing(2) = 0.05_R8P !< Space between the layout plot areas, x and y
                                                                  !< (gnuplot `spacing`, 0.05 screen by default).
   logical                        :: spacing_chars(2) = .false.   !< That space is in characters.
   logical                        :: gnuplot_labels = .false. !< gnuplot's default tick labels, `% h` per label
                                                               !< (the scripts'), on every axis of every panel.
   contains
      procedure, pass(self) :: clear           !< Remove the series of the current panel, keeping the settings.
      procedure, pass(self) :: image           !< gnuplot `plot ... with image`, a grid of values.
      procedure, pass(self) :: rgbimage        !< gnuplot `plot ... with rgbimage|rgbalpha`, a grid of colors.
      procedure, pass(self) :: init            !< Reset the figure, optionally resizing it.
      procedure, pass(self) :: next_panel      !< Move to the next multiplot panel, carrying the settings over.
      procedure, pass(self) :: plot            !< gnuplot `plot`, one series per call.
      procedure, pass(self), private :: splot_points !< gnuplot `splot` of scattered points.
      procedure, pass(self), private :: splot_grid   !< gnuplot `splot` of a grid.
      generic :: splot => splot_points, splot_grid   !< gnuplot `splot`, one surface or set of points per call.
      procedure, pass(self) :: set_view        !< gnuplot `set view`.
      procedure, pass(self) :: set_xyplane     !< gnuplot `set xyplane`.
      procedure, pass(self) :: set_hidden3d    !< gnuplot `set hidden3d`.
      procedure, pass(self) :: set_pm3d        !< gnuplot `set pm3d`.
      procedure, pass(self) :: set_spotlight   !< gnuplot `set pm3d spotlight`.
      procedure, pass(self) :: set_contourfill !< gnuplot `set contourfill`.
      procedure, pass(self) :: set_wall        !< gnuplot `set wall`, `set walls`.
      procedure, pass(self) :: set_boxdepth    !< gnuplot `set boxdepth`.
      procedure, pass(self) :: set_contour     !< gnuplot `set contour`, `set cntrparam`, `set cntrlabel`.
      procedure, pass(self) :: set_dgrid3d     !< gnuplot `set dgrid3d`.
      procedure, pass(self) :: set_zlabel      !< gnuplot `set zlabel`.
      procedure, pass(self) :: set_zrange      !< gnuplot `set zrange`.
      procedure, pass(self) :: set_ztics       !< gnuplot `set ztics`.
      procedure, pass(self) :: save            !< Render to a file; the format follows the extension.
      procedure, pass(self) :: set_angles      !< gnuplot `set angles`.
      procedure, pass(self) :: set_border      !< gnuplot `set border` / `unset border`.
      procedure, pass(self) :: set_errorbars   !< gnuplot `set errorbars`.
      procedure, pass(self) :: set_boxwidth    !< gnuplot `set boxwidth`.
      procedure, pass(self) :: set_cblabel     !< gnuplot `set cblabel`.
      procedure, pass(self) :: set_cbrange     !< gnuplot `set cbrange`.
      procedure, pass(self) :: set_colorbox    !< gnuplot `set colorbox` / `unset colorbox`.
      procedure, pass(self) :: set_format      !< gnuplot `set format`.
      procedure, pass(self) :: set_time_axes   !< gnuplot `set xdata time`.
      procedure, pass(self) :: set_timefmt     !< gnuplot `set timefmt`.
      procedure, pass(self) :: new_histogram   !< gnuplot `plot newhistogram`.
      procedure, pass(self) :: add_label       !< Add a label object (gnuplot `set label`).
      procedure, pass(self) :: add_arrow       !< Add an arrow object (gnuplot `set arrow`).
      procedure, pass(self) :: add_object      !< Add a shape object (gnuplot `set object`).
      procedure, pass(self) :: add_pixmap      !< Add an image from a PNG file (gnuplot `set pixmap`).
      procedure, pass(self) :: unset_pixmap    !< gnuplot `unset pixmap`.
      procedure, pass(self) :: set_label       !< gnuplot `set label`.
      procedure, pass(self) :: set_arrow       !< gnuplot `set arrow`.
      procedure, pass(self) :: set_object      !< gnuplot `set object`.
      procedure, pass(self) :: unset_label     !< gnuplot `unset label`.
      procedure, pass(self) :: unset_arrow     !< gnuplot `unset arrow`.
      procedure, pass(self) :: unset_object    !< gnuplot `unset object`.
      procedure, pass(self) :: set_grid        !< gnuplot `set grid` / `unset grid`.
      procedure, pass(self) :: set_key         !< gnuplot `set key` / `unset key`.
      procedure, pass(self) :: set_logscale    !< gnuplot `set logscale`.
      procedure, pass(self) :: set_multiplot   !< gnuplot `set multiplot layout rows,cols title "..."`.
      procedure, pass(self) :: set_origin      !< gnuplot `set origin`.
      procedure, pass(self) :: set_colorsequence !< gnuplot `set colorsequence`.
      procedure, pass(self) :: set_palette     !< gnuplot `set palette`.
      procedure, pass(self) :: set_palette_gradient !< gnuplot `set palette defined`/`file` from arrays.
      procedure, pass(self) :: set_paxis       !< gnuplot `set paxis N range|tics|label`.
      procedure, pass(self) :: set_polar       !< gnuplot `set polar` / `unset polar`.
      procedure, pass(self) :: set_raxis       !< gnuplot `set raxis` / `unset raxis`.
      procedure, pass(self) :: set_readout     !< Readouts: on/off, position, window, digit size.
      procedure, pass(self) :: set_refresh     !< HTML page reload period, for live monitoring.
      procedure, pass(self) :: set_rrange      !< gnuplot `set rrange`.
      procedure, pass(self) :: set_rtics       !< gnuplot `set rtics` / `unset rtics`.
      procedure, pass(self) :: set_size        !< gnuplot `set size`.
      procedure, pass(self) :: set_style_fill  !< gnuplot `set style fill`.
      procedure, pass(self) :: set_style_histogram !< gnuplot `set style histogram`.
      procedure, pass(self) :: set_style_boxplot   !< gnuplot `set style boxplot`.
      procedure, pass(self) :: set_style_spiderplot !< gnuplot `set style spiderplot`.
      procedure, pass(self) :: set_spiderplot  !< gnuplot `set spiderplot` / `unset spiderplot`.
      procedure, pass(self) :: set_text        !< Text output: gnuplot `dumb` or `block` terminal, colors.
      procedure, pass(self) :: set_theme       !< Output theme: classic, vfd, lcd; glow.
      procedure, pass(self) :: set_theta       !< gnuplot `set theta`.
      procedure, pass(self) :: set_margin   !< Set a margin, `set lmargin`...
      procedure, pass(self) :: set_enhanced !< Enhanced text on or off.
      procedure, pass(self) :: set_border_style !< Border line: lc, lw, dt.
      procedure, pass(self) :: set_zeroaxis !< Zero axes.
      procedure, pass(self) :: set_key_style !< Key layout: reverse, Left, invert, opaque, ...
      procedure, pass(self) :: set_title       !< gnuplot `set title`.
      procedure, pass(self) :: set_trange      !< gnuplot `set trange`.
      procedure, pass(self) :: set_ttics       !< gnuplot `set ttics` / `unset ttics`.
      procedure, pass(self) :: set_xlabel      !< gnuplot `set xlabel`.
      procedure, pass(self) :: set_xrange      !< gnuplot `set xrange`.
      procedure, pass(self) :: set_xtics       !< gnuplot `set xtics`.
      procedure, pass(self) :: set_mxtics      !< gnuplot `set mxtics`.
      procedure, pass(self) :: set_mytics      !< gnuplot `set mytics`.
      procedure, pass(self) :: set_my2tics     !< gnuplot `set my2tics`.
      procedure, pass(self) :: set_mx2tics     !< gnuplot `set mx2tics`.
      procedure, pass(self) :: set_mcbtics     !< gnuplot `set mcbtics`.
      procedure, pass(self) :: set_cbtics      !< gnuplot `set cbtics`.
      procedure, pass(self) :: unset_cbtics    !< gnuplot `unset cbtics`.
      procedure, pass(self) :: set_ylabel      !< gnuplot `set ylabel`.
      procedure, pass(self) :: set_yrange      !< gnuplot `set yrange`.
      procedure, pass(self) :: set_ytics       !< gnuplot `set ytics`.
      procedure, pass(self) :: set_y2label     !< gnuplot `set y2label`.
      procedure, pass(self) :: set_y2range     !< gnuplot `set y2range`.
      procedure, pass(self) :: set_y2tics      !< gnuplot `set y2tics`.
      procedure, pass(self) :: set_x2label     !< gnuplot `set x2label`.
      procedure, pass(self) :: set_x2range     !< gnuplot `set x2range`.
      procedure, pass(self) :: set_x2tics      !< gnuplot `set x2tics`.
      procedure, pass(self) :: unset_logscale  !< gnuplot `unset logscale`.
      procedure, pass(self) :: unset_multiplot !< gnuplot `unset multiplot`.
      procedure, pass(self) :: unset_xtics     !< gnuplot `unset xtics`.
      procedure, pass(self) :: unset_ytics     !< gnuplot `unset ytics`.
      procedure, pass(self) :: unset_y2tics    !< gnuplot `unset y2tics`.
      procedure, pass(self) :: unset_x2tics    !< gnuplot `unset x2tics`.
      procedure, pass(self), private :: environment_theme !< The theme of FORESIGHT_THEME, unless one was set.
      procedure, pass(self), private :: ensure_panels !< Allocate the single default panel if needed.
      procedure, pass(self), private :: render        !< Render on a device.
endtype figure_object

contains
   subroutine clear(self)
   !< Remove the series of the current panel, keeping every setting: a new gnuplot `plot` replaces the previous one,
   !< with the ranges of the previous plot command (`plot [min:max]`).
   class(figure_object), intent(inout) :: self !< Figure.

   call self%ensure_panels
   ! the associate alias works around gfortran 16 -fcheck=bounds crashing on allocated() of a component of an element
   ! of an allocatable array component of a polymorphic dummy
   associate(panel => self%panels(self%current))
      if (allocated(panel%series)) deallocate(panel%series)
      panel%hist_group = 0_I4P
      panel%hist_at_set = .false.
      panel%hist_title = ''
      panel%color_shift = 0_I4P
      panel%xaxis%plot_min_fixed = .false.
      panel%xaxis%plot_max_fixed = .false.
      panel%yaxis%plot_min_fixed = .false.
      panel%yaxis%plot_max_fixed = .false.
      panel%taxis%plot_min_fixed = .false.
      panel%taxis%plot_max_fixed = .false.
   endassociate
   endsubroutine clear

   subroutine rgbimage(self, red, green, blue, x, y, title, alpha)
   !< Image of the colors `red`, `green`, `blue` (and `alpha`, opaque if absent) per pixel (column, row), 0 to 255, as
   !< gnuplot `plot ... with rgbimage` (`rgbalpha`): pixel centres `x(column)`, `y(row)` as `image`; a NaN component
   !< makes its pixel transparent. No palette nor color box.
   class(figure_object), intent(inout)        :: self       !< Figure.
   real(R8P),            intent(in)           :: red(:,:)   !< Red components (column, row), rows upward.
   real(R8P),            intent(in)           :: green(:,:) !< Green components.
   real(R8P),            intent(in)           :: blue(:,:)  !< Blue components.
   real(R8P),            intent(in), optional :: x(:)       !< Pixel centre abscissae.
   real(R8P),            intent(in), optional :: y(:)       !< Pixel centre ordinates.
   character(len=*),     intent(in), optional :: title      !< Key title.
   real(R8P),            intent(in), optional :: alpha(:,:) !< Opacities, 0 (transparent) to 255.
   real(R8P), allocatable                     :: c(:,:,:)   !< Channels.
   real(R8P), allocatable                     :: xs(:)      !< Abscissae.
   real(R8P), allocatable                     :: ys(:)      !< Ordinates.
   integer(I4P)                               :: k          !< Counter.

   if (any(shape(green) /= shape(red)) .or. any(shape(blue) /= shape(red))) &
      error stop 'foresight: rgbimage: red, green and blue have different shapes'
   allocate(c(4, size(red, 1), size(red, 2)))
   c(1, :, :) = red
   c(2, :, :) = green
   c(3, :, :) = blue
   c(4, :, :) = 255.0_R8P
   if (present(alpha)) then
      if (any(shape(alpha) /= shape(red))) error stop 'foresight: rgbimage: alpha and red have different shapes'
      c(4, :, :) = alpha
   endif
   if (present(x)) then
      xs = x
   else
      xs = [(real(k, R8P), k = 0, size(red, 1) - 1)]
   endif
   if (present(y)) then
      ys = y
   else
      ys = [(real(k, R8P), k = 0, size(red, 2) - 1)]
   endif
   call self%ensure_panels
   call self%panels(self%current)%add_series(xs, ys, title=title, z=red, channels=c)
   endsubroutine rgbimage

   subroutine image(self, z, x, y, title)
   !< Image of the values `z(column, row)` (a heatmap), as gnuplot `plot ... with image`: pixel centres `x(column)` and
   !< `y(row)`, evenly spaced and increasing (0, 1, ... if absent, as gnuplot `matrix`), colored by `set_palette` over
   !< `set_cbrange`; NaN values are transparent. The x and y axes fit the pixel edges.
   class(figure_object), intent(inout)        :: self   !< Figure.
   real(R8P),            intent(in)           :: z(:,:) !< Values (column, row), rows upward.
   real(R8P),            intent(in), optional :: x(:)   !< Pixel centre abscissae.
   real(R8P),            intent(in), optional :: y(:)   !< Pixel centre ordinates.
   character(len=*),     intent(in), optional :: title  !< Key title.
   real(R8P), allocatable                     :: xs(:)  !< Abscissae.
   real(R8P), allocatable                     :: ys(:)  !< Ordinates.
   integer(I4P)                               :: k      !< Counter.

   if (present(x)) then
      xs = x
   else
      xs = [(real(k, R8P), k = 0, size(z, 1) - 1)]
   endif
   if (present(y)) then
      ys = y
   else
      ys = [(real(k, R8P), k = 0, size(z, 2) - 1)]
   endif
   call self%ensure_panels
   call self%panels(self%current)%add_series(xs, ys, title=title, z=z)
   endsubroutine image

   subroutine init(self, width, height, font_size)
   !< Reset the figure to gnuplot defaults, optionally resizing it.
   class(figure_object), intent(inout)        :: self      !< Figure.
   integer(I4P),         intent(in), optional :: width     !< Page width [px].
   integer(I4P),         intent(in), optional :: height    !< Page height [px].
   real(R8P),            intent(in), optional :: font_size !< Font size [px].
   type(figure_object)                        :: fresh     !< Default figure.

   self%width = fresh%width
   self%height = fresh%height
   self%font_size = fresh%font_size
   self%refresh = fresh%refresh
   self%clear_screen = fresh%clear_screen
   self%text_charset = fresh%text_charset
   self%text_colors = fresh%text_colors
   self%theme = fresh%theme
   self%theme_chosen = .false.
   self%rows = fresh%rows
   self%cols = fresh%cols
   self%current = fresh%current
   self%layout = fresh%layout
   self%manual = fresh%manual
   self%title = ''
   self%title_font = fresh%title_font
   if (allocated(self%panels)) deallocate(self%panels)
   call self%ensure_panels
   if (present(width)) self%width = real(width, R8P)
   if (present(height)) self%height = real(height, R8P)
   if (present(font_size)) self%font_size = font_size
   endsubroutine init

   subroutine next_panel(self)
   !< Move to the next panel of the multiplot: the next grid cell, or a new panel in a manual multiplot; the settings
   !< of the current panel carry over, as in gnuplot.
   class(figure_object), intent(inout) :: self     !< Figure.
   type(axes_object)                   :: settings !< Current panel without its series.

   call self%ensure_panels
   settings = self%panels(self%current)
   if (allocated(settings%series)) deallocate(settings%series)
   ! the histogram groups of a plot end with it
   settings%hist_group = 0_I4P
   settings%hist_at_set = .false.
   settings%hist_title = ''
   settings%color_shift = 0_I4P
   if (self%manual) then
      call push(self%panels, settings)
   elseif (self%current >= size(self%panels, kind=I4P)) then
      error stop 'foresight: next_panel: the multiplot layout is full'
   else
      ! the layout places the next panel again (gnuplot's multiplot_next)
      settings%layout_own = .false.
      settings%origin = [0.0_R8P, 0.0_R8P]
      settings%size = [1.0_R8P, 1.0_R8P]
   endif
   self%current = self%current + 1_I4P
   self%panels(self%current) = settings
   endsubroutine next_panel

   subroutine plot(self, x, y, title, with, lc, lw, dt, ps, xlow, xhigh, ylow, yhigh, axes, pt, format, width, base, fs, &
                   xlabels, radius, angles, donut, scale, linear, close, whiskerbars, factors, dx, dy, length, angle, major, &
                   minor, labels, label, head, origins, curve, at, colors, palette_z, palette_cb, palette_frac, pi, &
                   labels_axis)
   !< Add the series (`x`, `y`) to the current panel, as gnuplot `plot ... title ... with ... lc ... lw ... dt ... ps
   !< ... axes`. `colors` gives each point its color (gnuplot `lc variable`) with lines, points, linespoints, impulses
   !< and the error bars: a line segment takes the color of its end point, a bar its point's; in the key, the line sample
   !< that of the first point, the point sample that of the last one.
   !< `palette_z` colors each point by its value through the palette over the color axis (gnuplot `lc palette z`, the
   !< same styles and rules; the color axis spans these values and its box is drawn); `palette_cb` (a color axis value)
   !< and `palette_frac` (a fraction of the palette, 0 to 1) color the whole series (`lc palette cb|frac`).
   !<
   !< Error bar styles (`yerrorbars`, `xerrorbars`, `xyerrorbars`) take the bar bounds `ylow`/`yhigh`, `xlow`/`xhigh`.
   !< `axes='x1y2'` plots the series against the second y axis, scaled on its own, `x2y1` against the second x axis
   !< (`x2y2` both). `pt` is gnuplot's point type (0 a
   !< dot, 1 plus, 2 cross, 3 star, 4-5 square, 6-7 circle, 8-9 triangle, 10-11 inverted triangle, 12-13 diamond,
   !< 14-15 pentagon, odd ones from 5 filled; cycling every 15), 9 px wide at `ps` 1; without it points are round dots.
   !<
   !< `with='readout'` (a foresight extension) shows the last finite `y` in seven-segment digits, titled by `title`,
   !< on a glass of `format` (a printf conversion with a field width, `'%9.2e'`; `'%10.3e'` if absent): see
   !< foresight_readout and `set_readout`. A readout takes `lc` only among the style options.
   !<
   !< `with='boxes'` draws a bar from y = 0 to each `y`, `width` wide (per box; NaN or absent: `set_boxwidth`, else
   !< the boxes touch); `with='filledcurves'` fills down to `base`, between `ylow` and `y`, or the closed polygon of
   !< the points. `fs` takes gnuplot fill style words (`'solid 0.5 noborder'`), over `set_style_fill`.
   !<
   !< `with='histograms'` draws a bar per `y` in the row at `x` (0, 1, 2, ... as gnuplot), laid out with the other
   !< histograms of the panel by `set_style_histogram`. `xlabels` label the abscissae (gnuplot `xtic(N)`): text labels
   !< then replace the x ticks.
   !<
   !< `with='circles'` draws a circle per point, `radius` in x units (2% of the plot width if absent or NaN), a wedge
   !< with `angles(:, i)` = start and end [deg, counterclockwise from the x direction]. `with='pie'` (a foresight
   !< extension, alone in its panel) draws the `y` as slices from 12 o'clock clockwise, labelled by `xlabels` with
   !< their percentage in the key; `donut` (0 to below 1) leaves a hole of that fraction of the radius.
   !<
   !< Panel charts (foresight extensions, alone in their panel, several of the same kind side by side for gauges and
   !< radars): `with='gauge'` shows the last finite `y` on a 270-degree sweep over `scale` (its two end values), lit
   !< in `fs='segments N'` cells if set, the value in digits of `format`; `with='radar'` a polygon over a spoke per
   !< point, named by `xlabels`; `with='rose'` equal sectors of area by value (radius by value with `linear`).
   !<
   !< `with='boxerrorbars'` draws boxes (as `boxes`) with y error bars from `ylow` to `yhigh`; `boxxyerror` a rectangle
   !< from `xlow` to `xhigh`, `ylow` to `yhigh`; `candlesticks` and `financebars` take the open `y`, low `ylow`, high
   !< `yhigh` and `close` (a box-and-whisker plot: box start, whisker ends, box end), candlesticks a `width` and
   !< `whiskerbars` (crossbars, a fraction of the box width). `with='boxplot'` draws the quartiles, median, whiskers and
   !< outliers of the values `y` at `x(1)`, one box per level of `factors` if given, laid out by `set_style_boxplot`.
   !<
   !< `with='vectors'` draws arrows from the points by `dx`, `dy`; `arrows` by `length` (> 0 x units, kept at any angle;
   !< in (-1, 0) a fraction of the plot width) and `angle` [deg]; `head` takes gnuplot's words (`'heads filled'`).
   !< `ellipses` take `major`, `minor` diameters (x and y units) and `angle` [deg]; `polygons` fill each NaN-separated
   !< run of points; `labels` write `labels(i)` at the points with the `label` words (`'left offset 1,0 point'`);
   !< `sectors` draw the annular sectors from azimuth `x`, radius `y` by `angle` (the angle unit) and `width`.
   class(figure_object), intent(inout)        :: self     !< Figure.
   real(R8P),            intent(in)           :: x(:)     !< Abscissae.
   real(R8P),            intent(in)           :: y(:)     !< Ordinates.
   character(len=*),     intent(in), optional :: title    !< Key title, empty or absent for none.
   character(len=*),     intent(in), optional :: with     !< Plotting style: `lines` (default), `points`, ....
   character(len=*),     intent(in), optional :: lc       !< Line color (SVG color); default from the linetype colors.
   real(R8P),            intent(in), optional :: lw       !< Line width [px].
   integer(I4P),         intent(in), optional :: dt       !< Dash type, 1..5.
   real(R8P),            intent(in), optional :: ps       !< Point size scale factor.
   real(R8P),            intent(in), optional :: xlow(:)  !< Horizontal error bar starts.
   real(R8P),            intent(in), optional :: xhigh(:) !< Horizontal error bar ends.
   real(R8P),            intent(in), optional :: ylow(:)  !< Vertical error bar starts.
   real(R8P),            intent(in), optional :: yhigh(:) !< Vertical error bar ends.
   character(len=*),     intent(in), optional :: axes     !< Axes of the series: `x1y1` (default), `x1y2`, `x2y1`, `x2y2`.
   integer(I4P),         intent(in), optional :: pt       !< gnuplot point type, >= 0.
   character(len=*),     intent(in), optional :: format   !< Readout format.
   real(R8P),            intent(in), optional :: width(:) !< Box widths.
   real(R8P),            intent(in), optional :: base     !< Baseline of a fill.
   character(len=*),     intent(in), optional :: fs       !< Fill style words.
   character(len=*),     intent(in), optional :: xlabels(:) !< Text labels of the abscissae.
   real(R8P),            intent(in), optional :: radius(:) !< Circle radii [x units].
   real(R8P),            intent(in), optional :: angles(:,:) !< Wedge angles (2, point) [deg].
   real(R8P),            intent(in), optional :: donut    !< Pie hole fraction.
   real(R8P),            intent(in), optional :: scale(2) !< Gauge scale: the values at the sweep ends.
   logical,              intent(in), optional :: linear   !< Rose radius by value.
   real(R8P),            intent(in), optional :: close(:) !< Closing values of candlesticks and finance bars.
   real(R8P),            intent(in), optional :: whiskerbars !< Candlestick whisker crossbars, a box width fraction.
   character(len=*),     intent(in), optional :: factors(:) !< Factor level of each boxplot value.
   real(R8P),            intent(in), optional :: dx(:)      !< Vector extents along x.
   real(R8P),            intent(in), optional :: dy(:)      !< Vector extents along y.
   real(R8P),            intent(in), optional :: length(:)  !< Arrow lengths.
   real(R8P),            intent(in), optional :: angle(:)   !< Arrow or ellipse angles [deg], sector extents.
   real(R8P),            intent(in), optional :: major(:)   !< Ellipse major diameters.
   real(R8P),            intent(in), optional :: minor(:)   !< Ellipse minor diameters.
   character(len=*),     intent(in), optional :: labels(:)  !< Texts of labels.
   character(len=*),     intent(in), optional :: label      !< Label option words.
   character(len=*),     intent(in), optional :: head       !< Arrowhead words.
   real(R8P),            intent(in), optional :: origins(:,:) !< Sector centres (2, point).
   character(len=*),     intent(in), optional :: curve      !< Filled curve options (`'x1'`, `'above'`, `'xy=0,1'`).
   real(R8P),            intent(in), optional :: at         !< Position of a parallel axis.
   character(len=*),     intent(in), optional :: colors(:)  !< Color of each point (gnuplot `lc variable`).
   real(R8P),            intent(in), optional :: palette_z(:) !< Palette value of each point (`lc palette z`).
   real(R8P),            intent(in), optional :: palette_cb   !< A color axis value (`lc palette cb`).
   real(R8P),            intent(in), optional :: palette_frac !< A fraction of the palette (`lc palette frac`).
   integer(I4P),         intent(in), optional :: pi           !< A point marker every `pi` points (`pointinterval`).
   character(len=*),     intent(in), optional :: labels_axis  !< Axis the `xlabels` mark: `x` (default, `xtic`), `x2`
                                                              !< at the abscissae, `y` (`ytic`), `y2` at the ordinates.
   integer(I4P)                               :: last         !< Series added.

   call self%ensure_panels
   if (present(labels_axis)) then
      if (all(labels_axis /= ['x ', 'x2', 'y ', 'y2'])) &
         error stop 'foresight: plot: labels_axis must be x, x2, y or y2, not "'//labels_axis//'"'
   endif
   if (present(pi)) then
      if (pi < 1_I4P) error stop 'foresight: plot: pi must be positive'
   endif
   call self%panels(self%current)%add_series(x, y, title=title, with=with, lc=lc, lw=lw, dt=dt, ps=ps, &
                                             xlow=xlow, xhigh=xhigh, ylow=ylow, yhigh=yhigh, axes=axes, pt=pt, &
                                             format=format, width=width, base=base, fs=fs, xlabels=xlabels, &
                                             radius=radius, angles=angles, donut=donut, scale=scale, linear=linear, &
                                             close=close, whiskerbars=whiskerbars, factors=factors, dx=dx, dy=dy, &
                                             length=length, angle=angle, major=major, minor=minor, labels=labels, &
                                             label=label, head=head, origins=origins, curve=curve, at=at, &
                                             colors=colors, palette_z=palette_z, palette_cb=palette_cb, &
                                             palette_frac=palette_frac)
   last = size(self%panels(self%current)%series, kind=I4P)
   if (present(pi)) self%panels(self%current)%series(last)%pointinterval = pi
   if (present(labels_axis)) self%panels(self%current)%series(last)%label_axis = labels_axis
   endsubroutine plot

   subroutine save(self, file)
   !< Render the figure to `file`; the format follows the name: `.svg` static, `.html` interactive, `.txt` text (the
   !< gnuplot `dumb` or `block` terminal, see `set_text`), `-` text on standard output.
   class(figure_object), intent(inout) :: self   !< Figure.
   character(len=*),     intent(in)    :: file   !< Output file.
   type(backend_svg)                   :: svg    !< SVG device.
   type(backend_html)                  :: html   !< HTML device.

   call self%ensure_panels
   if (file == '-') then
      call text(self%clear_screen)
      return
   endif
   svg%theme = self%theme
   html%theme = self%theme
   select case (extension(file))
   case ('svg')
      call self%render(svg, file)
   case ('html', 'htm')
      html%title = self%title
      if (len(html%title) == 0 .and. allocated(self%panels(1)%title)) html%title = self%panels(1)%title
      html%refresh = self%refresh
      call self%render(html, file)
   case ('txt')
      call text(.false.)
   case default
      error stop 'foresight: unsupported output format of "'//file//'" (supported: .svg, .html, .txt, -)'
   endselect
   contains
      subroutine text(clear_screen)
      !< Render on the text device of `text_charset`.
      logical, intent(in) :: clear_screen !< Clear the terminal first.
      type(backend_dumb)  :: dumb         !< Text device.
      type(backend_block) :: blocks       !< Block character text device.

      dumb%theme = self%theme
      blocks%theme = self%theme
      if (self%text_charset == 'dumb') then
         dumb%clear_screen = clear_screen
         dumb%colors = self%text_colors
         call self%render(dumb, file)
      else
         blocks%clear_screen = clear_screen
         blocks%colors = self%text_colors
         blocks%charset = self%text_charset
         call self%render(blocks, file)
      endif
      endsubroutine text
   endsubroutine save

   subroutine set_cblabel(self, label)
   !< Color box label, as gnuplot `set cblabel`; empty for none.
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: label !< Label.

   call self%ensure_panels
   self%panels(self%current)%cbaxis%label = label
   endsubroutine set_cblabel

   subroutine set_cbrange(self, min, max)
   !< Color range of the images, as gnuplot `set cbrange [min:max]`: an absent end is autoscaled to the values.
   class(figure_object), intent(inout)        :: self !< Figure.
   real(R8P),            intent(in), optional :: min  !< Value of the first palette color.
   real(R8P),            intent(in), optional :: max  !< Value of the last palette color.

   call self%ensure_panels
   call self%panels(self%current)%cbaxis%set_range(min, max)
   endsubroutine set_cbrange

   subroutine set_colorbox(self, on, horizontal, user, origin, size, border, invert)
   !< Draw the color box of the images (`on` absent or true), as gnuplot `set colorbox`, or not (`on` false: `unset
   !< colorbox`, which also resets every option). `horizontal` (else vertical), `user` (in the `origin`, `size` box:
   !< canvas fractions from the bottom left; else at the default place: right of the plot, or below it when
   !< horizontal), `border`, `invert` (a vertical box with low values at the top). With no option at all the box returns
   !< to the default place, the others kept, as gnuplot's bare `set colorbox`.
   class(figure_object), intent(inout)        :: self       !< Figure.
   logical,              intent(in), optional :: on         !< Box drawn.
   logical,              intent(in), optional :: horizontal !< Horizontal, else vertical.
   logical,              intent(in), optional :: user       !< In the user box, else at the default place.
   real(R8P),            intent(in), optional :: origin(2)  !< User box bottom left, canvas fractions.
   real(R8P),            intent(in), optional :: size(2)    !< User box width and height, canvas fractions (> 0).
   logical,              intent(in), optional :: border     !< Frame drawn.
   logical,              intent(in), optional :: invert     !< Low values at the top of a vertical box.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      panel%colorbox = .true.
      if (present(on)) panel%colorbox = on
      if (.not. panel%colorbox) then
         panel%cbox = colorbox_object()
         return
      endif
      if (.not. (present(horizontal) .or. present(user) .or. present(origin) .or. present(size) .or. &
                 present(border) .or. present(invert))) panel%cbox%user = .false.
      if (present(horizontal)) panel%cbox%horizontal = horizontal
      if (present(user)) panel%cbox%user = user
      if (present(origin)) panel%cbox%origin = origin
      if (present(size)) then
         if (any(size <= 0.0_R8P)) error stop 'foresight: set_colorbox: the size must be positive'
         panel%cbox%size = size
      endif
      if (present(border)) panel%cbox%border = border
      if (present(invert)) panel%cbox%invert = invert
   endassociate
   endsubroutine set_colorbox

   subroutine set_palette(self, words)
   !< Palette of the images, as gnuplot `set palette`: `''` (the default, rgbformulae 7,5,15), `'rgbformulae 33,13,10'`,
   !< `'defined (0 "blue", 1 "white", 2 "red")'`, `'cubehelix start 0 cycles 1'`, `'gray'`, `'viridis'`, `'negative'`,
   !< `'maxcolors 8'`; a named palette
   !< of foresight_colormaps, any case (`'batlow'`, `'vik negative'`, `'romaO maxcolors 12'`).
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: words !< Palette words.
   character(len=:), allocatable       :: bad   !< Unknown word.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      call palette_words(words, panel%palette, bad)
   endassociate
   if (len(bad) > 0) error stop 'foresight: set_palette: unsupported palette "'//bad//'"'
   endsubroutine set_palette

   subroutine set_colorsequence(self, name, colors)
   !< Linetype colors of the series, `lc N` and the slices of the current panel (carried to the next ones), as gnuplot
   !< `set colorsequence default|podo|classic`; beyond gnuplot, a categorical order (`'batlowS'`, ..., any case) and
   !< the number of its `colors` taken (8 by default), the most distinct first. Series already added keep theirs; a
   !< theme recolors gnuplot's default sequence only.
   class(figure_object), intent(inout)        :: self   !< Figure.
   character(len=*),     intent(in)           :: name   !< Sequence.
   integer(I4P),         intent(in), optional :: colors !< Colors of a categorical order, 1 to 100.
   character(len=9), allocatable              :: list(:) !< Colors.
   character(len=:), allocatable              :: bad    !< Problem.
   integer(I4P)                               :: n      !< Colors asked.

   n = 0_I4P
   if (present(colors)) n = colors
   call sequence_colors(name, n, list, bad)
   if (len(bad) > 0) error stop 'foresight: set_colorsequence: '//bad
   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (allocated(panel%linecolors)) deallocate(panel%linecolors)
      if (size(list) > 0) panel%linecolors = list
   endassociate
   endsubroutine set_colorsequence

   subroutine set_palette_gradient(self, positions, colors)
   !< Palette of the images as a gradient, as gnuplot `set palette defined` or `set palette file`: `colors(:, k)`
   !< (red, green, blue, 0 to 1, clipped) at `positions(k)`, increasing (equal ones make a sharp step), mapped to
   !< 0..1. Other palette settings (`negative`, `maxcolors`) are kept; `set_palette` words can follow.
   class(figure_object), intent(inout) :: self         !< Figure.
   real(R8P),            intent(in)    :: positions(:) !< Positions.
   real(R8P),            intent(in)    :: colors(:,:)  !< Colors (red, green, blue; position).
   character(len=:), allocatable       :: bad          !< Problem.

   if (size(colors, 1) /= 3 .or. size(colors, 2) /= size(positions)) &
      error stop 'foresight: set_palette_gradient: colors(3, size(positions)) expected'
   call self%ensure_panels
   associate(panel => self%panels(self%current))
      call palette_gradient(panel%palette, positions, colors, bad)
   endassociate
   if (len(bad) > 0) error stop 'foresight: set_palette_gradient: '//bad
   endsubroutine set_palette_gradient

   subroutine set_angles(self, unit)
   !< Unit of the angles, as gnuplot `set angles degrees|radians` (radians by default): theta of a polar panel and
   !< the trigonometric functions of its expressions (`set_angles` affects the script interpreter's compilation).
   class(figure_object), intent(inout) :: self !< Figure.
   character(len=*),     intent(in)    :: unit !< `degrees` or `radians`.

   if (unit /= 'degrees' .and. unit /= 'radians') error stop 'foresight: set_angles: degrees or radians, not "'// &
                                                             unit//'"'
   call self%ensure_panels
   self%panels(self%current)%degrees = unit == 'degrees'
   endsubroutine set_angles

   subroutine set_border(self, mask, polar)
   !< Border sides, as gnuplot `set border MASK [polar]` (`unset border` is mask 0): 1 bottom, 2 left, 4 top, 8 right
   !< (31 by default, the full frame); `polar` adds the circle of the largest r on a polar panel. Without `mask`,
   !< `polar` keeps the sides (gnuplot: `unset border; set border polar` draws the circle alone), else the full frame
   !< is restored.
   class(figure_object), intent(inout)        :: self  !< Figure.
   integer(I4P),         intent(in), optional :: mask  !< Sides; 31 if absent.
   logical,              intent(in), optional :: polar !< Polar border.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (.not. present(polar)) panel%border = 31_I4P
      if (present(mask)) then
         if (mask < 0_I4P) error stop 'foresight: set_border: the mask must not be negative'
         panel%border = mask
      endif
      panel%border_polar = .false.
      if (present(polar)) panel%border_polar = polar
   endassociate
   endsubroutine set_border

   subroutine set_border_style(self, lc, lw, dt)
   !< The border's line, as gnuplot `set border ... lc C lw W dt N`: `lc` empty for the frame color.
   class(figure_object), intent(inout)        :: self !< Figure.
   character(len=*),     intent(in), optional :: lc   !< Line color.
   real(R8P),            intent(in), optional :: lw   !< Line width [px].
   integer(I4P),         intent(in), optional :: dt   !< Dash type, 1 solid.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (present(lc)) then
         if (len_trim(lc) > 0) then
            panel%border_lc = trim(lc)
         elseif (allocated(panel%border_lc)) then
            deallocate(panel%border_lc)
         endif
      endif
      if (present(lw)) panel%border_lw = lw
      if (present(dt)) panel%border_dt = dt
   endassociate
   endsubroutine set_border_style

   subroutine set_zeroaxis(self, axes, on, lc, lw, dt)
   !< Lines at the zero of the `axes` (`x`: y = 0, `y`: x = 0, `x2`, `y2`; blank-separated), as gnuplot `set xzeroaxis`
   !< (`on` absent or true) or `unset`, with their line: `lc` empty for the frame color, `dt` 3 gnuplot's dots.
   class(figure_object), intent(inout)        :: self !< Figure.
   character(len=*),     intent(in)           :: axes !< Axes.
   logical,              intent(in), optional :: on   !< Drawn.
   character(len=*),     intent(in), optional :: lc   !< Line color.
   real(R8P),            intent(in), optional :: lw   !< Line width [px].
   integer(I4P),         intent(in), optional :: dt   !< Dash type.
   logical                                    :: draw !< Drawn.

   call self%ensure_panels
   draw = .true.
   if (present(on)) draw = on
   associate(panel => self%panels(self%current))
      if (index(' '//axes//' ', ' x ') > 0) panel%zero_axes(1) = draw
      if (index(' '//axes//' ', ' y ') > 0) panel%zero_axes(2) = draw
      if (index(' '//axes//' ', ' y2 ') > 0) panel%zero_axes(3) = draw
      if (index(' '//axes//' ', ' x2 ') > 0) panel%zero_axes(4) = draw
      if (present(lc)) then
         if (len_trim(lc) > 0) then
            panel%zero_lc = trim(lc)
         elseif (allocated(panel%zero_lc)) then
            deallocate(panel%zero_lc)
         endif
      endif
      if (present(lw)) panel%zero_lw = lw
      if (present(dt)) panel%zero_dt = dt
   endassociate
   endsubroutine set_zeroaxis

   subroutine set_boxwidth(self, width, relative)
   !< Box width, as gnuplot `set boxwidth W [absolute|relative]`: `width` absent or 0 for the default, the boxes
   !< touching; `relative` scales that default instead of setting the width.
   class(figure_object), intent(inout)        :: self     !< Figure.
   real(R8P),            intent(in), optional :: width    !< Width, or fraction of the default with `relative`.
   logical,              intent(in), optional :: relative !< Relative width.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      panel%boxwidth = 0.0_R8P
      if (present(width)) then
         if (width < 0.0_R8P) error stop 'foresight: set_boxwidth: the width must not be negative'
         panel%boxwidth = width
      endif
      panel%boxwidth_relative = .false.
      if (present(relative)) panel%boxwidth_relative = relative
   endassociate
   endsubroutine set_boxwidth

   subroutine set_style_fill(self, words)
   !< Fill of the boxes and filled curves plotted next, as gnuplot `set style fill`: `'empty'`, `'solid 0.5'`,
   !< `'transparent solid 0.3 noborder'`, `'solid border lc "black"'`.
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: words !< Fill style words.
   character(len=:), allocatable       :: bad   !< Unknown word.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      call fill_style(words, panel%fill_default, bad)
   endassociate
   if (len(bad) > 0) error stop 'foresight: set_style_fill: unsupported fill style "'//bad//'"'
   endsubroutine set_style_fill

   subroutine set_style_histogram(self, style, gap, lw)
   !< Layout of the histograms plotted next, as gnuplot `set style histogram clustered [gap G]|errorbars [gap G] [lw
   !< W]|rowstacked|columnstacked`: `style` `clustered` (the default), `errorbars` (clustered, each bar with its error
   !< bar: `plot` `ylow`, `yhigh`), `rowstacked` (a stack per row) or `columnstacked` (a stack per histogram, its rows
   !< in their linetype colors, the row names given as `labels` its key entries); `gap` the space between clusters,
   !< in bar widths (2 by default, kept until set again); `lw` the error bar width [px].
   class(figure_object), intent(inout)        :: self  !< Figure.
   character(len=*),     intent(in)           :: style !< `clustered`, `errorbars`, `rowstacked` or `columnstacked`.
   real(R8P),            intent(in), optional :: gap   !< Gap between clusters [bars].
   real(R8P),            intent(in), optional :: lw    !< Error bar width [px].

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      select case (style)
      case ('clustered')
         panel%histogram_mode = 0_I4P
      case ('rowstacked')
         panel%histogram_mode = 1_I4P
      case ('columnstacked')
         panel%histogram_mode = 2_I4P
      case ('errorbars')
         panel%histogram_mode = 3_I4P
      case default
         error stop 'foresight: set_style_histogram: clustered, errorbars, rowstacked or columnstacked expected, not "'// &
                    style//'"'
      endselect
      panel%histogram_rowstacked = style == 'rowstacked'
      if (present(gap)) then
         if (gap < 0.0_R8P) error stop 'foresight: set_style_histogram: the gap must not be negative'
         panel%histogram_gap = gap
      endif
      panel%histogram_lw = 0.0_R8P
      if (present(lw)) then
         if (.not. (lw > 0.0_R8P)) error stop 'foresight: set_style_histogram: the line width must be positive'
         panel%histogram_lw = lw
      endif
   endassociate
   endsubroutine set_style_histogram

   subroutine new_histogram(self, title, at, lt)
   !< Start a new group of histograms in the current plot, as gnuplot `plot newhistogram ["title"] [at X] [lt N]`: the
   !< histograms plotted next form a group laid out after the previous one (2 rows after its last), or from `at`;
   !< `title` is written below the x axis under the group; `lt` makes their default colors start at linetype `N`.
   class(figure_object), intent(inout)        :: self  !< Figure.
   character(len=*),     intent(in), optional :: title !< Group title.
   real(R8P),            intent(in), optional :: at    !< Group start.
   integer(I4P),         intent(in), optional :: lt    !< First linetype of the group.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (allocated(panel%series)) then
         if (any(panel%series%style%with == WITH_HISTOGRAMS)) panel%hist_group = panel%hist_group + 1_I4P
      endif
      panel%hist_title = ''
      if (present(title)) panel%hist_title = title
      panel%hist_at_set = present(at)
      if (present(at)) panel%hist_at = at
      if (present(lt)) then
         if (lt < 1_I4P) error stop 'foresight: new_histogram: the linetype starts at 1'
         panel%color_shift = 0_I4P
         if (allocated(panel%series)) panel%color_shift = -size(panel%series, kind=I4P)
         panel%color_shift = panel%color_shift + lt - 1_I4P
      endif
   endassociate
   endsubroutine new_histogram

   subroutine set_style_boxplot(self, words)
   !< Layout of the boxplots plotted next, as gnuplot `set style boxplot`: `words` among `range R` (1.5), `fraction F`,
   !< `outliers` (the default) or `nooutliers`, `pointtype P` (7), `candlesticks` (the default) or `financebars`,
   !< `medianlinewidth W`, `separation S` (1), `labels off|auto|x`, `sorted` or `unsorted` (the default).
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: words !< Style words.
   character(len=:), allocatable       :: bad   !< Problem.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      call boxplot_words(words, panel%boxplot, bad)
   endassociate
   if (len(bad) > 0) error stop 'foresight: set_style_boxplot: '//bad
   endsubroutine set_style_boxplot

   subroutine set_format(self, format, axes, geographic)
   !< Tick label `format` of the `axes` named `x`, `y`, `y2`, `cb` (all when absent), as gnuplot `set format`: text
   !< with one printf conversion `%[flags][width][.precision]` `f`, `e`, `E`, `g`, `G` or `h` (`g` with a `x10`
   !< superscript exponent), e.g. `'%.1e'` or `'%g s'`; an empty format restores the default labels. On a time axis
   !< (`set_time_axes`) a time format, `'%H:%M'` (see foresight_time `strftime`). With `geographic` (gnuplot `set
   !< format x "..." geographic`, `set xtics geographic`) the labels are degrees, minutes and seconds: `%D` `%M` `%S`
   !< whole, `%d` `%m` `%s` as `%f`, `%E` `%N` the compass letter, e.g. `'%D %E'` (foresight_format `dms_label`).
   class(figure_object), intent(inout)        :: self       !< Figure.
   character(len=*),     intent(in)           :: format     !< Label format.
   character(len=*),     intent(in), optional :: axes       !< Axes names, e.g. `y`, `xy` or `y2`.
   logical,              intent(in), optional :: geographic !< Labels in degrees, minutes, seconds.
   character(len=:), allocatable              :: message    !< Format problem.
   logical                                    :: named(5)   !< x, y, y2, cb, x2 named.
   logical                                    :: geo        !< A geographic axis named.

   named = which_axes(axes, 'set_format')
   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (present(geographic)) then
         if (named(1)) panel%xaxis%tics%geographic = geographic
         if (named(2)) panel%yaxis%tics%geographic = geographic
         if (named(3)) panel%y2axis%tics%geographic = geographic
         if (named(4)) panel%cbaxis%tics%geographic = geographic
         if (named(5)) panel%x2axis%tics%geographic = geographic
      endif
      geo = (named(1) .and. panel%xaxis%tics%geographic) .or. (named(2) .and. panel%yaxis%tics%geographic) .or. &
            (named(3) .and. panel%y2axis%tics%geographic) .or. (named(4) .and. panel%cbaxis%tics%geographic) .or. &
            (named(5) .and. panel%x2axis%tics%geographic)
   endassociate
   if (len(format) > 0 .and. .not. geo) then
      message = format_check(format)
      if (len(message) > 0 .and. len(time_format_check(format)) > 0) error stop 'foresight: set_format: '//message
   endif
   associate(panel => self%panels(self%current))
      if (named(1)) panel%xaxis%tics%format = format
      if (named(2)) panel%yaxis%tics%format = format
      if (named(3)) panel%y2axis%tics%format = format
      if (named(4)) panel%cbaxis%tics%format = format
      if (named(5)) panel%x2axis%tics%format = format
   endassociate
   endsubroutine set_format

   subroutine set_time_axes(self, axes, on, timefmt)
   !< Time axes, as gnuplot `set xdata time`: the values of the `axes` named `x`, `y`, `y2`, `x2` (all when absent) are
   !< seconds since 1970-01-01 00:00 UTC, ticked in whole time units and labelled by a time format (`set_format`, or
   !< one invented from the range); `on` false turns them back to numbers. `timefmt` (gnuplot `set timefmt`, default
   !< `%d/%m/%y,%H:%M`) orders day and month in the invented labels.
   class(figure_object), intent(inout)        :: self    !< Figure.
   character(len=*),     intent(in), optional :: axes    !< Axes names, e.g. `x` or `xy2`.
   logical,              intent(in), optional :: on      !< Time axes (default), or numbers.
   character(len=*),     intent(in), optional :: timefmt !< Input time format.
   logical                                    :: named(5) !< x, y, y2, cb, x2 named.
   logical                                    :: time     !< Time axes.

   named = which_axes(axes, 'set_time_axes')
   if (named(4) .and. present(axes)) error stop 'foresight: set_time_axes: the color axis is not a time axis'
   time = .true.
   if (present(on)) time = on
   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (named(1)) panel%xaxis%time = time
      if (named(2)) panel%yaxis%time = time
      if (named(3)) panel%y2axis%time = time
      if (named(5)) panel%x2axis%time = time
      if (present(timefmt)) then
         panel%xaxis%timefmt = timefmt
         panel%yaxis%timefmt = timefmt
         panel%y2axis%timefmt = timefmt
         panel%x2axis%timefmt = timefmt
      endif
   endassociate
   endsubroutine set_time_axes

   subroutine set_timefmt(self, timefmt)
   !< The input time format (gnuplot `set timefmt`) of every axis of the current panel: the day and month order of
   !< the labels invented for time axes.
   class(figure_object), intent(inout) :: self    !< Figure.
   character(len=*),     intent(in)    :: timefmt !< Input time format.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      panel%xaxis%timefmt = timefmt
      panel%yaxis%timefmt = timefmt
      panel%y2axis%timefmt = timefmt
      panel%x2axis%timefmt = timefmt
   endassociate
   endsubroutine set_timefmt

   subroutine add_label(self, label)
   !< Add `label` to the current panel: tag 0 takes the next free tag, an existing tag is replaced (gnuplot `set label
   !< N`).
   class(figure_object), intent(inout) :: self  !< Figure.
   type(label_object),   intent(in)    :: label !< Label.
   type(label_object)                  :: item  !< Label with its tag.
   integer(I4P)                        :: k     !< Counter.

   call self%ensure_panels
   item = label
   associate(panel => self%panels(self%current))
      if (.not. allocated(panel%notes)) allocate(panel%notes(0))
      if (item%tag <= 0_I4P) item%tag = 1_I4P + maxval([0_I4P, panel%notes%tag])
      do k = 1_I4P, size(panel%notes, kind=I4P)
         if (panel%notes(k)%tag == item%tag) then
            panel%notes(k) = item
            return
         endif
      enddo
      call push(panel%notes, item)
   endassociate
   endsubroutine add_label

   subroutine add_arrow(self, arrow)
   !< Add `arrow` to the current panel: tag 0 takes the next free tag, an existing tag is replaced.
   class(figure_object), intent(inout) :: self  !< Figure.
   type(arrow_object),   intent(in)    :: arrow !< Arrow.
   type(arrow_object)                  :: item  !< Arrow with its tag.
   integer(I4P)                        :: k     !< Counter.

   call self%ensure_panels
   item = arrow
   associate(panel => self%panels(self%current))
      if (.not. allocated(panel%arrows)) allocate(panel%arrows(0))
      if (item%tag <= 0_I4P) item%tag = 1_I4P + maxval([0_I4P, panel%arrows%tag])
      do k = 1_I4P, size(panel%arrows, kind=I4P)
         if (panel%arrows(k)%tag == item%tag) then
            panel%arrows(k) = item
            return
         endif
      enddo
      call push(panel%arrows, item)
   endassociate
   endsubroutine add_arrow

   subroutine add_object(self, object)
   !< Add `object` to the current panel: tag 0 takes the next free tag, an existing tag is replaced.
   class(figure_object), intent(inout) :: self   !< Figure.
   type(shape_object),   intent(in)    :: object !< Object.
   type(shape_object)                  :: item   !< Object with its tag.
   integer(I4P)                        :: k      !< Counter.

   call self%ensure_panels
   item = object
   associate(panel => self%panels(self%current))
      if (.not. allocated(panel%objects)) allocate(panel%objects(0))
      if (item%tag <= 0_I4P) item%tag = 1_I4P + maxval([0_I4P, panel%objects%tag])
      do k = 1_I4P, size(panel%objects, kind=I4P)
         if (panel%objects(k)%tag == item%tag) then
            panel%objects(k) = item
            return
         endif
      enddo
      call push(panel%objects, item)
   endassociate
   endsubroutine add_object

   subroutine add_pixmap(self, pixmap)
   !< Add `pixmap` to the current panel, an existing tag replaced.
   class(figure_object), intent(inout) :: self   !< Figure.
   type(pixmap_object),  intent(in)    :: pixmap !< Pixmap.
   integer(I4P)                        :: k      !< Counter.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (allocated(panel%pixmaps)) then
         do k = 1_I4P, size(panel%pixmaps, kind=I4P)
            if (panel%pixmaps(k)%tag == pixmap%tag) then
               panel%pixmaps(k) = pixmap
               return
            endif
         enddo
      endif
      call push(panel%pixmaps, pixmap)
   endassociate
   endsubroutine add_pixmap

   subroutine unset_pixmap(self, tag)
   !< Remove the pixmap `tag` of the current panel, every pixmap without it (gnuplot `unset pixmap N`, `unset pixmaps`).
   class(figure_object), intent(inout)        :: self !< Figure.
   integer(I4P),         intent(in), optional :: tag  !< Tag.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (.not. allocated(panel%pixmaps)) return
      if (present(tag)) then
         panel%pixmaps = pack(panel%pixmaps, panel%pixmaps%tag /= tag)
      else
         deallocate(panel%pixmaps)
      endif
   endassociate
   endsubroutine unset_pixmap

   subroutine unset_label(self, tag)
   !< Remove the label `tag` of the current panel, every label without it (gnuplot `unset label [N]`).
   class(figure_object), intent(inout)        :: self !< Figure.
   integer(I4P),         intent(in), optional :: tag  !< Tag.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (.not. allocated(panel%notes)) return
      if (present(tag)) then
         panel%notes = pack(panel%notes, panel%notes%tag /= tag)
      else
         deallocate(panel%notes)
      endif
   endassociate
   endsubroutine unset_label

   subroutine unset_arrow(self, tag)
   !< Remove the arrow `tag` of the current panel, every arrow without it (gnuplot `unset arrow [N]`).
   class(figure_object), intent(inout)        :: self !< Figure.
   integer(I4P),         intent(in), optional :: tag  !< Tag.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (.not. allocated(panel%arrows)) return
      if (present(tag)) then
         panel%arrows = pack(panel%arrows, panel%arrows%tag /= tag)
      else
         deallocate(panel%arrows)
      endif
   endassociate
   endsubroutine unset_arrow

   subroutine unset_object(self, tag)
   !< Remove the object `tag` of the current panel, every object without it (gnuplot `unset object [N]`).
   class(figure_object), intent(inout)        :: self !< Figure.
   integer(I4P),         intent(in), optional :: tag  !< Tag.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (.not. allocated(panel%objects)) return
      if (present(tag)) then
         panel%objects = pack(panel%objects, panel%objects%tag /= tag)
      else
         deallocate(panel%objects)
      endif
   endassociate
   endsubroutine unset_object

   subroutine set_label(self, text, x, y, tag, system, justify, rotate, color, front, point, pt, ps, offset, offset_system)
   !< A label at (`x`, `y`), as gnuplot `set label [tag] "text" at x,y`: `system` the coordinate systems (`first`, the
   !< default, `second`, `graph`, `screen`; two words for x and y: `'graph first'`), `justify` `left` (default),
   !< `center` or `right`, `rotate` [deg], `color` of the text, `front` over the frame (else behind the data), `point`
   !< a marker (`pt`, `ps`) at the position, `offset` the text offset, in characters or in `offset_system` (`character`,
   !< `first`, `second`, `graph`, `screen`; two words for x and y, as gnuplot `offset graph 0.1, screen 0.02`).
   class(figure_object), intent(inout)        :: self      !< Figure.
   character(len=*),     intent(in)           :: text      !< Text.
   real(R8P),            intent(in)           :: x         !< Abscissa.
   real(R8P),            intent(in)           :: y         !< Ordinate.
   integer(I4P),         intent(in), optional :: tag       !< Tag, 0 or absent: the next free one.
   character(len=*),     intent(in), optional :: system    !< Coordinate systems.
   character(len=*),     intent(in), optional :: justify   !< `left`, `center`, `right`.
   real(R8P),            intent(in), optional :: rotate    !< Angle [deg, counterclockwise].
   character(len=*),     intent(in), optional :: color     !< Text color.
   logical,              intent(in), optional :: front     !< Over the frame.
   logical,              intent(in), optional :: point     !< A point at the position.
   integer(I4P),         intent(in), optional :: pt        !< Point type.
   real(R8P),            intent(in), optional :: ps        !< Point size.
   real(R8P),            intent(in), optional :: offset(2) !< Text offset.
   character(len=*),     intent(in), optional :: offset_system !< Its coordinate systems.
   type(label_object)                         :: label     !< Label.
   type(place_object)                         :: probe     !< The offset's systems, checked.

   label%text = text
   label%at = place(x, y, system, 'set_label')
   if (present(tag)) label%tag = tag
   if (present(justify)) then
      if (all(justify /= ['left  ', 'center', 'right '])) &
         error stop 'foresight: set_label: justify must be left, center or right, not "'//justify//'"'
      label%justify = justify
   endif
   if (present(rotate)) label%rotate = rotate
   label%color = ''
   if (present(color)) label%color = color
   if (present(front)) label%front = front
   if (present(point)) label%point = point
   if (present(pt)) label%pt = pt
   if (present(ps)) label%ps = ps
   if (present(offset)) label%offset = offset
   if (present(offset_system)) then
      probe = place(0.0_R8P, 0.0_R8P, offset_system, 'set_label')
      label%offset_system = [probe%sx, probe%sy]
   endif
   call self%add_label(label)
   endsubroutine set_label

   subroutine set_arrow(self, x1, y1, x2, y2, tag, system, to_system, relative, head, length, angle, filled, front, lc, &
                        lw, dt)
   !< An arrow from (`x1`, `y1`) to (`x2`, `y2`), as gnuplot `set arrow [tag] from x1,y1 to x2,y2`: `system` the
   !< coordinate systems of the tail (as `set_label`), `to_system` those of the tip (the tail's by default), `relative`
   !< the tip relative to the tail (`rto`); `head` `head` (default), `nohead`, `backhead` or `heads`; `length` (x
   !< axis values) and `angle` [deg] of the heads; `filled` `nofilled` (default, two barbs), `filled`, `empty` or
   !< `noborder`; `front` over the frame; `lc`, `lw`, `dt` the line.
   class(figure_object), intent(inout)        :: self      !< Figure.
   real(R8P),            intent(in)           :: x1        !< Tail abscissa.
   real(R8P),            intent(in)           :: y1        !< Tail ordinate.
   real(R8P),            intent(in)           :: x2        !< Tip abscissa.
   real(R8P),            intent(in)           :: y2        !< Tip ordinate.
   integer(I4P),         intent(in), optional :: tag       !< Tag, 0 or absent: the next free one.
   character(len=*),     intent(in), optional :: system    !< Coordinate systems of the tail.
   character(len=*),     intent(in), optional :: to_system !< Coordinate systems of the tip.
   logical,              intent(in), optional :: relative  !< The tip relative to the tail.
   character(len=*),     intent(in), optional :: head      !< `head`, `nohead`, `backhead`, `heads`.
   real(R8P),            intent(in), optional :: length    !< Head length [x axis values].
   real(R8P),            intent(in), optional :: angle     !< Head angle [deg].
   character(len=*),     intent(in), optional :: filled    !< `nofilled`, `filled`, `empty`, `noborder`.
   logical,              intent(in), optional :: front     !< Over the frame.
   character(len=*),     intent(in), optional :: lc        !< Line color.
   real(R8P),            intent(in), optional :: lw        !< Line width [px].
   integer(I4P),         intent(in), optional :: dt        !< Dash type, 1..5.
   type(arrow_object)                         :: arrow     !< Arrow.

   arrow%from = place(x1, y1, system, 'set_arrow')
   if (present(to_system)) then
      arrow%to = place(x2, y2, to_system, 'set_arrow')
   else
      arrow%to = place(x2, y2, system, 'set_arrow')
   endif
   if (present(tag)) arrow%tag = tag
   if (present(relative)) arrow%relative = relative
   if (present(head)) then
      select case (head)
      case ('nohead')
         arrow%head = 0_I4P
      case ('head')
         arrow%head = 1_I4P
      case ('backhead')
         arrow%head = 2_I4P
      case ('heads')
         arrow%head = 3_I4P
      case default
         error stop 'foresight: set_arrow: head must be head, nohead, backhead or heads, not "'//head//'"'
      endselect
   endif
   if (present(length)) arrow%length = length
   if (present(angle)) arrow%angle = angle
   if (present(filled)) then
      if (all(filled /= ['nofilled', 'filled  ', 'empty   ', 'noborder'])) &
         error stop 'foresight: set_arrow: filled must be nofilled, filled, empty or noborder, not "'//filled//'"'
      arrow%fill = filled
   endif
   if (present(front)) arrow%front = front
   arrow%color = ''
   if (present(lc)) arrow%color = lc
   if (present(lw)) arrow%lw = lw
   arrow%dashes = ''
   if (present(dt)) then
      block
         type(style_object) :: line !< Line of the dash type.

         line%dashtype = dt
         line%linewidth = arrow%lw
         arrow%dashes = line%dasharray()
      endblock
   endif
   call self%add_arrow(arrow)
   endsubroutine set_arrow

   subroutine set_object(self, kind, x, y, tag, system, width, height, radius, angle, arc, fc, fs, lw, dt, layer, clip, z)
   !< An object, as gnuplot `set object [tag] rectangle|circle|ellipse|polygon`: a `rectangle` from the corner (`x(1)`,
   !< `y(1)`) to (`x(2)`, `y(2)`), or centred on (`x(1)`, `y(1)`) with `width` and `height`; a `circle` centred on
   !< (`x(1)`, `y(1)`) of `radius` (x axis values), its `arc` [deg] a wedge if partial; an `ellipse` centred there,
   !< `width` and `height` (axis values), `angle` [deg]; a `polygon` of the vertices (`x`, `y`). `system` the
   !< coordinate systems (as `set_label`), `fc` the fill color, `fs` the fill style words (`'solid 0.3 border'`),
   !< `lw` the border width, `dt` its dash type (1 solid to 5), `layer` `behind`, `back` (default) or `front`, `clip`
   !< false to draw beyond the plot area. In 3D views a polygon takes the heights `z` of its vertices (in the system of
   !< the abscissae), and `layer='depthorder'` sorts it with the pm3d quadrangles (gnuplot's `depthorder`).
   !< By default, as gnuplot, a rectangle is filled with the page color and bordered black, the others empty, black.
   class(figure_object), intent(inout)        :: self   !< Figure.
   character(len=*),     intent(in)           :: kind   !< `rectangle`, `circle`, `ellipse`, `polygon`.
   real(R8P),            intent(in)           :: x(:)   !< Abscissae.
   real(R8P),            intent(in)           :: y(:)   !< Ordinates.
   integer(I4P),         intent(in), optional :: tag    !< Tag, 0 or absent: the next free one.
   character(len=*),     intent(in), optional :: system !< Coordinate systems.
   real(R8P),            intent(in), optional :: width  !< Rectangle or ellipse width.
   real(R8P),            intent(in), optional :: height !< Rectangle or ellipse height.
   real(R8P),            intent(in), optional :: radius !< Circle radius.
   real(R8P),            intent(in), optional :: angle  !< Ellipse angle [deg].
   real(R8P),            intent(in), optional :: arc(2) !< Circle arc [deg].
   character(len=*),     intent(in), optional :: fc     !< Fill color.
   character(len=*),     intent(in), optional :: fs     !< Fill style words.
   real(R8P),            intent(in), optional :: lw     !< Border width [px].
   integer(I4P),         intent(in), optional :: dt     !< Border dash type, 1 (solid) to 5.
   character(len=*),     intent(in), optional :: layer  !< `behind`, `back`, `front`.
   logical,              intent(in), optional :: clip   !< Clipped by the plot area.
   real(R8P),            intent(in), optional :: z(:)   !< Heights of a 3D polygon's vertices.
   type(shape_object)                         :: object !< Object.
   character(len=:), allocatable              :: bad    !< Unknown fill word.
   integer(I4P)                               :: k      !< Counter.

   if (size(x) /= size(y) .or. size(x) == 0) error stop 'foresight: set_object: x and y need the same, nonzero size'
   if (all(kind /= ['rectangle', 'circle   ', 'ellipse  ', 'polygon  '])) &
      error stop 'foresight: set_object: kind must be rectangle, circle, ellipse or polygon, not "'//kind//'"'
   object%kind = kind
   allocate(object%points(size(x)))
   do k = 1_I4P, size(x, kind=I4P)
      object%points(k) = place(x(k), y(k), system, 'set_object')
   enddo
   if (present(z)) then
      if (kind /= 'polygon' .or. size(z) /= size(x)) error stop 'foresight: set_object: z gives a polygon''s heights, '// &
                                                                'one per vertex'
      do k = 1_I4P, size(x, kind=I4P)
         object%points(k)%z = z(k)
         object%points(k)%sz = object%points(k)%sx
      enddo
   endif
   object%size%sx = object%points(1)%sx
   object%size%sy = object%points(1)%sy
   select case (kind)
   case ('rectangle')
      if (present(width) .neqv. present(height)) error stop 'foresight: set_object: a rectangle takes width and height'
      object%sized = present(width)
      if (.not. object%sized .and. size(x) /= 2) &
         error stop 'foresight: set_object: a rectangle takes two corners, or a centre with width and height'
      if (object%sized) object%size = place_object(x=width, y=height, sx=object%points(1)%sx, sy=object%points(1)%sy)
      object%style%fill = FILL_SOLID
      object%style%density = 1.0_R8P
      object%style%color = 'white'
      object%style%border_color = 'black'
   case ('circle')
      if (.not. present(radius)) error stop 'foresight: set_object: a circle takes its radius'
      object%size%x = radius
      if (present(arc)) object%arc = arc
      object%style%color = 'black'
   case ('ellipse')
      if (.not. (present(width) .and. present(height))) error stop 'foresight: set_object: an ellipse takes width and height'
      object%size = place_object(x=width, y=height, sx=object%points(1)%sx, sy=object%points(1)%sy)
      if (present(angle)) object%angle = angle
      object%style%color = 'black'
   case ('polygon')
      if (size(x) < 3) error stop 'foresight: set_object: a polygon takes 3 vertices at least'
      object%style%color = 'black'
   endselect
   object%style%border = .true.
   if (present(fc)) then
      object%style%color = fc
      if (allocated(object%style%border_color) .and. kind /= 'rectangle') deallocate(object%style%border_color)
   endif
   if (present(fs)) then
      call fill_style(fs, object%style, bad)
      if (len(bad) > 0) error stop 'foresight: set_object: unsupported fill style "'//bad//'"'
   endif
   if (present(lw)) object%style%linewidth = lw
   if (present(dt)) then
      if (dt < 1_I4P .or. dt > 5_I4P) error stop 'foresight: set_object: dash types 1 to 5'
      object%style%dashtype = dt
   endif
   if (present(layer)) then
      if (all(layer /= ['behind    ', 'back      ', 'front     ', 'depthorder'])) &
         error stop 'foresight: set_object: layer must be behind, back, front or depthorder, not "'//layer//'"'
      object%layer = layer
      if (layer == 'depthorder') object%layer = 'depth'
   endif
   if (present(clip)) object%clip = clip
   if (present(tag)) object%tag = tag
   call self%add_object(object)
   endsubroutine set_object

   subroutine set_paxis(self, n, min, max, step, start, end, tics, label)
   !< Parallel axis `n` of the parallel axis and spider plots, as gnuplot `set paxis n range [min:max]` (an absent end
   !< autoscaled to the values, without extension), `set paxis n tics [START,]STEP[,END]` (`tics` true: automatic
   !< ticks; false: none, the default), `set paxis n label "text"` (spider plots).
   class(figure_object), intent(inout)        :: self  !< Figure.
   integer(I4P),         intent(in)           :: n     !< Axis number, >= 1.
   real(R8P),            intent(in), optional :: min   !< Range start.
   real(R8P),            intent(in), optional :: max   !< Range end.
   real(R8P),            intent(in), optional :: step  !< Tick step.
   real(R8P),            intent(in), optional :: start !< First tick.
   real(R8P),            intent(in), optional :: end   !< Last tick.
   logical,              intent(in), optional :: tics  !< Ticks on (automatic) or off.
   character(len=*),     intent(in), optional :: label !< Axis label.
   type(paxis_object), allocatable            :: more(:) !< Grown axes.
   integer(I4P)                               :: k     !< Counter.

   if (n < 1_I4P .or. n > 1000_I4P) error stop 'foresight: set_paxis: the axis number is 1 to 1000'
   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (.not. allocated(panel%paxes)) allocate(panel%paxes(0))
      if (size(panel%paxes) < n) then
         allocate(more(n))
         do k = 1_I4P, n
            if (k <= size(panel%paxes)) then
               more(k) = panel%paxes(k)
            else
               more(k)%axis = paxis_default()
            endif
         enddo
         call move_alloc(more, panel%paxes)
      endif
      associate(axis => panel%paxes(n)%axis)
         if (present(min) .or. present(max)) call axis%set_range(min=min, max=max)
         if (present(tics)) then
            if (tics) then
               call axis%tics%set_auto
            else
               axis%tics%mode = TICS_NONE
            endif
         endif
         if (present(step)) call set_tics(axis%tics, 'set_paxis', step, start, end)
      endassociate
      if (present(label)) panel%paxes(n)%label = label
   endassociate
   endsubroutine set_paxis

   subroutine set_spiderplot(self, on)
   !< Spider plot coordinates (`on` absent or true), as gnuplot `set spiderplot`: the items of the panel are spider plot
   !< axes (its data style), its key not titled by the items; false restores the data style lines.
   class(figure_object), intent(inout)        :: self !< Figure.
   logical,              intent(in), optional :: on   !< Spider plot on.

   call self%ensure_panels
   self%panels(self%current)%spiderplot = .true.
   if (present(on)) self%panels(self%current)%spiderplot = on
   endsubroutine set_spiderplot

   subroutine set_style_spiderplot(self, words)
   !< Polygons of the spider plots plotted next, as gnuplot `set style spiderplot`: fill style words (`'fs transparent
   !< solid 0.2 border'`, `fs` optional) and `lw W`, `pt N`, `ps S`.
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: words !< Style words.
   character(len=:), allocatable       :: bad   !< Problem.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      call spider_words(words, panel%spider_style, bad)
   endassociate
   if (len(bad) > 0) error stop 'foresight: set_style_spiderplot: '//bad
   endsubroutine set_style_spiderplot

   subroutine set_grid(self, on, polar, spider, lines, front, lc, lw, dt)
   !< Draw grid lines at the major ticks (`on` absent or true), as gnuplot `set grid`, or not. On a polar panel,
   !< `polar` > 0 draws the polar grid instead (gnuplot `set grid polar STEP`): rings at the major r ticks and spokes
   !< every `polar` degrees of theta (360: none, the rings alone, gnuplot `set grid r`); 0 restores the rectangular
   !< grid. `spider` draws the web of the spider plots
   !< (gnuplot `set grid spiderplot`) at the ticks of their first axis.
   class(figure_object), intent(inout)        :: self   !< Figure.
   logical,              intent(in), optional :: on     !< Grid on.
   real(R8P),            intent(in), optional :: polar  !< Spoke step [deg], 0 for the rectangular grid.
   logical,              intent(in), optional :: spider !< Spider plot web.
   logical,              intent(in), optional :: lines(6) !< Lines at the x, y, x2, y2 major and x, y minor ticks
                                                         !< (gnuplot `set grid x y x2 y2 mx my`); none: x and y.
   logical,              intent(in), optional :: front  !< Over the data (gnuplot `front`), else behind.
   character(len=*),     intent(in), optional :: lc     !< Line color, empty for the theme's.
   real(R8P),            intent(in), optional :: lw     !< Line width [px].
   integer(I4P),         intent(in), optional :: dt     !< Dash type, 0 for foresight's dots, 1 solid.

   call self%ensure_panels
   if (present(lines)) self%panels(self%current)%grid_lines = lines
   if (present(front)) self%panels(self%current)%grid_front = front
   if (present(lc)) then
      if (len_trim(lc) > 0) then
         self%panels(self%current)%grid_lc = trim(lc)
      elseif (allocated(self%panels(self%current)%grid_lc)) then
         deallocate(self%panels(self%current)%grid_lc)
      endif
   endif
   if (present(lw)) self%panels(self%current)%grid_lw = lw
   if (present(dt)) self%panels(self%current)%grid_dt = dt
   if (present(spider)) self%panels(self%current)%grid_spider = spider
   self%panels(self%current)%grid = .true.
   if (present(on)) self%panels(self%current)%grid = on
   if (present(polar)) then
      if (polar < 0.0_R8P .or. polar > 360.0_R8P) error stop 'foresight: set_grid: the polar step is 0 to 360'
      self%panels(self%current)%grid_polar = polar
   endif
   endsubroutine set_grid

   subroutine set_key(self, on, position, box, at, system)
   !< Draw the key (`on` absent or true), as gnuplot `set key`, or not; `position` takes gnuplot's words, e.g.
   !< `'bottom left'`, `'center'` (inside the plot area, top right by default), `'outside'`, `'below'`, `'above'`,
   !< `'lmargin'`, `'tmargin left'`, `'horizontal'`; `box` draws a box around it. `at` places it at a position
   !< (gnuplot `set key at`), its box aligned there by the position words as a text (`'left bottom'`: its bottom left
   !< corner), in the coordinates of `system`: one or two words of `first` (the default: the x and y values), `second`
   !< (x2, y2), `graph` (fractions of the plot area), `screen` (fractions of the page), for x then y. `inside`,
   !< `outside`, the margins, `below` and `above` cancel `at`.
   class(figure_object), intent(inout)        :: self     !< Figure.
   logical,              intent(in), optional :: on       !< Key on.
   character(len=*),     intent(in), optional :: position !< Position words: left, right, center, top, bottom.
   logical,              intent(in), optional :: box      !< Box around the key.
   real(R8P),            intent(in), optional :: at(2)    !< Position of the key.
   character(len=*),     intent(in), optional :: system   !< Coordinate systems of `at`, x then y.
   character(len=:), allocatable              :: bad      !< Unknown position word.
   character(len=6)                           :: systems(2) !< Coordinate systems of `at`.
   integer(I4P)                               :: blank    !< Word separator.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      panel%key = .true.
      if (present(on)) panel%key = on
      if (present(position)) then
         call key_position(position, panel%key_h, panel%key_v, panel%key_outside, panel%key_margin, &
                           panel%key_horizontal, bad)
         if (len(bad) > 0) error stop 'foresight: set_key: unknown position "'//bad//'"'
         if (has_region(position)) panel%key_at = .false.
      endif
      if (present(box)) panel%key_box = box
      if (present(at)) then
         systems = 'first'
         if (present(system)) then
            blank = index(trim(adjustl(system)), ' ', kind=I4P)
            if (blank == 0_I4P) then
               systems = trim(adjustl(system))
            else
               systems(1) = trim(adjustl(system(:blank)))
               systems(2) = trim(adjustl(system(blank:)))
            endif
         endif
         if (any(systems /= 'first' .and. systems /= 'second' .and. systems /= 'graph' .and. systems /= 'screen')) &
            error stop 'foresight: set_key: the coordinate systems are first, second, graph, screen'
         panel%key_at = .true.
         panel%key_xy = at
         panel%key_system = systems
         panel%key_outside = .false.
         panel%key_margin = ''
      endif
   endassociate
   endsubroutine set_key

   subroutine set_logscale(self, axes)
   !< Base-10 log scale on the `axes` named `x`, `y`, `y2`, `cb` (the color axis of the images); all axes when absent,
   !< as gnuplot.
   class(figure_object), intent(inout)        :: self     !< Figure.
   character(len=*),     intent(in), optional :: axes     !< Axes names, e.g. `y`, `xy` or `y2`.
   logical                                    :: named(5) !< x, y, y2, cb, x2 named.

   named = which_axes(axes, 'set_logscale')
   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (named(1)) panel%xaxis%log = .true.
      if (named(2)) panel%yaxis%log = .true.
      if (named(3)) panel%y2axis%log = .true.
      if (named(4)) panel%cbaxis%log = .true.
      if (named(5)) panel%x2axis%log = .true.
   endassociate
   endsubroutine set_logscale

   subroutine set_multiplot(self, rows, cols, title)
   !< Lay out a `rows` x `cols` grid of panels, filled row by row starting from the first; every panel starts from the
   !< settings of the current one, without its series. Without `rows` and `cols`, a manual multiplot: each panel lies
   !< in its `set_origin`/`set_size` box, as gnuplot `set multiplot` without layout.
   class(figure_object), intent(inout)        :: self     !< Figure.
   integer(I4P),         intent(in), optional :: rows     !< Grid rows.
   integer(I4P),         intent(in), optional :: cols     !< Grid columns.
   character(len=*),     intent(in), optional :: title    !< Multiplot title.
   type(axes_object)                          :: settings !< Current panel without its series.
   integer(I4P)                               :: p        !< Panel counter.

   if (present(rows) .neqv. present(cols)) error stop 'foresight: set_multiplot: give both rows and cols, or neither'
   call self%ensure_panels
   settings = self%panels(self%current)
   if (allocated(settings%series)) deallocate(settings%series)
   deallocate(self%panels)
   self%layout = present(rows)
   self%manual = .not. present(rows)
   self%rows = 1_I4P
   self%cols = 1_I4P
   if (self%layout) then
      if (rows < 1_I4P .or. cols < 1_I4P) error stop 'foresight: set_multiplot: the layout needs positive rows and cols'
      if (any(settings%origin /= 0.0_R8P) .or. any(settings%size /= 1.0_R8P)) &
         error stop 'foresight: set_multiplot: a layout needs the default origin 0,0 and size 1,1'
      self%rows = rows
      self%cols = cols
   endif
   allocate(self%panels(self%rows * self%cols))
   do p = 1_I4P, self%rows * self%cols
      self%panels(p) = settings
   enddo
   self%current = 1_I4P
   self%title = ''
   if (present(title)) self%title = title
   self%columns_first = .false.
   self%upwards = .false.
   self%layout_margins = -1.0_R8P
   self%layout_chars = .false.
   self%layout_spacing = 0.05_R8P
   self%spacing_chars = .false.
   endsubroutine set_multiplot

   subroutine set_origin(self, x, y)
   !< Bottom left corner of the plot as page fractions, as gnuplot `set origin x,y`: for a single plot and the panels
   !< of a multiplot; in a layout the panel leaves its cell for its own box (its size the cell's unless set), as
   !< gnuplot, until the next panel.
   class(figure_object), intent(inout) :: self !< Figure.
   real(R8P),            intent(in)    :: x    !< Left side, page width fraction.
   real(R8P),            intent(in)    :: y    !< Bottom side, page height fraction.

   call self%ensure_panels
   call own_box(self)
   ! associate alias: see the gfortran 16 -fcheck=bounds workaround in clear
   associate(panel => self%panels(self%current))
      panel%origin = [x, y]
   endassociate
   endsubroutine set_origin

   subroutine own_box(self)
   !< The current panel of a multiplot layout leaves its grid cell for its own `origin`, `size` box (gnuplot's set
   !< origin, set size override the layout until the next plot), starting from its cell (page fractions from the bottom
   !< left, below no title band).
   class(figure_object), intent(inout) :: self !< Figure.
   integer(I4P)                        :: rc(2) !< Row and column of the cell, from 0.

   if (.not. self%layout) return
   associate(panel => self%panels(self%current))
      if (panel%layout_own) return
      if (self%columns_first) then
         rc = [modulo(self%current - 1_I4P, self%rows), (self%current - 1_I4P) / self%rows]
      else
         rc = [(self%current - 1_I4P) / self%cols, modulo(self%current - 1_I4P, self%cols)]
      endif
      if (self%upwards) rc(1) = self%rows - 1_I4P - rc(1)
      panel%origin = [real(rc(2), R8P) / real(self%cols, R8P), 1.0_R8P - real(rc(1) + 1_I4P, R8P) / real(self%rows, R8P)]
      panel%size = [1.0_R8P / real(self%cols, R8P), 1.0_R8P / real(self%rows, R8P)]
      panel%layout_own = .true.
   endassociate
   endsubroutine own_box

   subroutine set_text(self, charset, colors)
   !< Text output (`.txt`, `-`): `charset` `dumb` (default), drawing with characters, or the gnuplot `block` character
   !< set `half`, `quadrants`, `sextants`, `braille`; `colors` `mono` (default), `ansi`, `ansi256` or `ansirgb`, the
   !< series in ANSI colors. Absent arguments keep their setting.
   class(figure_object), intent(inout)        :: self    !< Figure.
   character(len=*),     intent(in), optional :: charset !< Character set.
   character(len=*),     intent(in), optional :: colors  !< Color mode.

   if (present(charset)) then
      if (charset /= 'dumb' .and. .not. is_word(charset, BLOCK_CHARSETS)) &
         error stop 'foresight: set_text: charset must be dumb, '//BLOCK_CHARSETS//', not "'//charset//'"'
      self%text_charset = charset
   endif
   if (present(colors)) then
      if (.not. is_word(colors, TEXT_COLORS)) &
         error stop 'foresight: set_text: colors must be one of '//TEXT_COLORS//', not "'//colors//'"'
      self%text_colors = colors
   endif
   contains
      pure function is_word(word, words) result(found)
      !< Whether `word` is one of the blank separated `words`.
      character(len=*), intent(in) :: word  !< Word.
      character(len=*), intent(in) :: words !< Blank separated words.
      logical                      :: found !< Found.

      found = len(word) > 0 .and. index(' '//words//' ', ' '//word//' ') > 0
      endfunction is_word
   endsubroutine set_text

   subroutine set_polar(self, on)
   !< Polar coordinates (`on` absent or true), as gnuplot `set polar`: the series of the panel are theta:r (theta in
   !< `set_angles` units, from the `set_theta` origin), drawn at x = (r - rmin) cos(theta), y = (r - rmin) sin(theta)
   !< joined by straight segments; x and y autoscale to the disc of the largest r. The frame stays rectangular, as
   !< gnuplot: a round plot sets the polar border, the polar grid, the square size and turns the x and y ticks off.
   class(figure_object), intent(inout)        :: self !< Figure.
   logical,              intent(in), optional :: on   !< Polar on.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      panel%polar = .true.
      if (present(on)) panel%polar = on
      if (panel%polar .and. allocated(panel%series)) then
         if (.not. all(polar_series(panel%series))) error stop 'foresight: set_polar: '//POLAR_STYLES
      endif
   endassociate
   endsubroutine set_polar

   subroutine set_raxis(self, on)
   !< Draw the radial axis of a polar panel (`on` absent or true; the default), as gnuplot `set raxis`, or not.
   class(figure_object), intent(inout)        :: self !< Figure.
   logical,              intent(in), optional :: on   !< Axis on.

   call self%ensure_panels
   self%panels(self%current)%raxis_on = .true.
   if (present(on)) self%panels(self%current)%raxis_on = on
   endsubroutine set_raxis

   subroutine set_readout(self, on, position, opaque, size)
   !< Draw the readouts (`on` absent or true) or not; `position` takes the `set key` words inside the plot area
   !< (`left`, `right`, `center`, `top`, `bottom`; top left by default) and `horizontal` or `vertical` (the default) for
   !< a row or a column of readouts; `opaque` draws a window behind them (default true); `size` is the digit height
   !< [px], 0 for the default (2.5 font sizes, growing to fill a panel of readouts alone).
   class(figure_object), intent(inout)        :: self     !< Figure.
   logical,              intent(in), optional :: on       !< Readouts on.
   character(len=*),     intent(in), optional :: position !< Position words.
   logical,              intent(in), optional :: opaque   !< Window behind the readouts.
   real(R8P),            intent(in), optional :: size     !< Digit height [px].
   character(len=:), allocatable              :: bad      !< Unknown position word.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      panel%readout = .true.
      if (present(on)) panel%readout = on
      if (present(position)) then
         call readout_position(position, panel%readout_h, panel%readout_v, panel%readout_horizontal, bad)
         if (len(bad) > 0) error stop 'foresight: set_readout: unknown position "'//bad//'"'
      endif
      if (present(opaque)) panel%readout_opaque = opaque
      if (present(size)) then
         if (size < 0.0_R8P) error stop 'foresight: set_readout: the digit size must not be negative'
         panel%readout_size = size
      endif
   endassociate
   endsubroutine set_readout

   pure subroutine set_refresh(self, seconds)
   !< Make the HTML page reload itself every `seconds` (0 disables): live view of a file rewritten by a running job.
   !<
   !< The zoom survives the reload, being kept in the page URL as data values.
   class(figure_object), intent(inout) :: self    !< Figure.
   integer(I4P),         intent(in)    :: seconds !< Reload period [s].

   self%refresh = max(0_I4P, seconds)
   endsubroutine set_refresh

   subroutine set_rrange(self, min, max)
   !< r range of a polar panel, as gnuplot `set rrange [min:max]`: `min` lies at the pole (0 when absent), the points
   !< below it are undefined; an absent `max` autoscales to the largest |r|, extended to the r ticks.
   class(figure_object), intent(inout)        :: self !< Figure.
   real(R8P),            intent(in), optional :: min  !< r at the pole.
   real(R8P),            intent(in), optional :: max  !< Largest r.

   if (present(min) .and. present(max)) then
      if (.not. max > min) error stop 'foresight: set_rrange: max must exceed min'
   endif
   call self%ensure_panels
   call self%panels(self%current)%raxis%set_range(min=min, max=max)
   endsubroutine set_rrange

   subroutine set_rtics(self, step, start, end, on)
   !< r ticks of a polar panel every `step` from `start` to `end`, automatic without `step` (the default), as gnuplot
   !< `set rtics`; `on` false turns them off (`unset rtics`).
   class(figure_object), intent(inout)        :: self  !< Figure.
   real(R8P),            intent(in), optional :: step  !< Tick step.
   real(R8P),            intent(in), optional :: start !< First tick.
   real(R8P),            intent(in), optional :: end   !< Last tick.
   logical,              intent(in), optional :: on    !< Ticks on.

   call self%ensure_panels
   if (present(on)) then
      if (.not. on) then
         self%panels(self%current)%raxis%tics%mode = TICS_NONE
         return
      endif
   endif
   call set_tics(self%panels(self%current)%raxis%tics, 'set_rtics', step, start, end)
   endsubroutine set_rtics

   subroutine set_size(self, width, height, ratio)
   !< Size of the plot as page fractions, as gnuplot `set size w,h`: for a single plot and the panels of a multiplot; in
   !< a layout the panel leaves its cell for its own box (at the cell's origin unless set), as gnuplot, until the next
   !< panel. `ratio` > 0 fixes the plot area height over width (gnuplot `set size ratio R`,
   !< `square` is 1), 0 frees it (`noratio`); a negative ratio -R makes a y unit R times an x unit long (gnuplot
   !< `set size ratio -1`: equal units, the plot area shrunk to the ranges).
   class(figure_object), intent(inout)        :: self   !< Figure.
   real(R8P),            intent(in), optional :: width  !< Width, page width fraction, > 0.
   real(R8P),            intent(in), optional :: height !< Height, page height fraction, > 0.
   real(R8P),            intent(in), optional :: ratio  !< Plot area height over width, 0 for none.

   if (present(width) .neqv. present(height)) error stop 'foresight: set_size: width and height go together'
   if (present(width)) then
      if (width <= 0.0_R8P .or. height <= 0.0_R8P) error stop 'foresight: set_size: the size must be positive'
   endif
   if (present(ratio)) then
   endif
   call self%ensure_panels
   if (present(width)) call own_box(self)
   associate(panel => self%panels(self%current))
      if (present(width)) panel%size = [width, height]
      if (present(ratio)) panel%ratio = ratio
   endassociate
   endsubroutine set_size

   subroutine set_theme(self, name, glow)
   !< Output theme (a foresight extension): `name` `classic` (the default), `vfd` (a vacuum fluorescent display: black
   !< glass, emissive colors, glowing data), `lcd` (a backlit liquid crystal display), `washi` or `night` (foresight's
   !< identity, light and dark: see foresight_theme); `glow` overrides the theme's
   !< glow (on in `vfd`). Text output takes the theme colors of the series only (`ansi` colors).
   class(figure_object), intent(inout)        :: self !< Figure.
   character(len=*),     intent(in), optional :: name !< Theme name.
   logical,              intent(in), optional :: glow !< Glowing data.

   if (present(name)) then
      if (index(' '//THEMES//' ', ' '//trim(name)//' ') == 0) &
         error stop 'foresight: set_theme: unknown theme "'//trim(name)//'" (supported: '//THEMES//')'
      self%theme = theme_named(name)
      self%theme_chosen = .true.
   endif
   if (present(glow)) self%theme%glow = glow
   endsubroutine set_theme

   subroutine set_theta(self, origin, clockwise)
   !< Where theta = 0 lies on a polar panel, `right` (the default), `top`, `left` or `bottom`, and whether theta grows
   !< `clockwise` (default counterclockwise), as gnuplot `set theta`.
   class(figure_object), intent(inout)        :: self      !< Figure.
   character(len=*),     intent(in), optional :: origin    !< Direction of theta = 0.
   logical,              intent(in), optional :: clockwise !< Theta grows clockwise.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (present(origin)) then
         select case (origin)
         case ('right')
            panel%theta_origin = 0.0_R8P
         case ('top')
            panel%theta_origin = 90.0_R8P
         case ('left')
            panel%theta_origin = 180.0_R8P
         case ('bottom')
            panel%theta_origin = 270.0_R8P
         case default
            error stop 'foresight: set_theta: right, top, left or bottom, not "'//origin//'"'
         endselect
      endif
      if (present(clockwise)) panel%theta_clockwise = clockwise
   endassociate
   endsubroutine set_theta

   subroutine set_key_style(self, reverse, left, invert, opaque, samplen, width, title, offset, title_justify)
   !< Key layout of the current panel, as gnuplot `set key`: `reverse` the samples left of the titles, `left` the titles
   !< left-justified (`Left`), `invert` the entries in reverse order, `opaque` the key area painted over the plot,
   !< `samplen` the sample length [character widths; negative: foresight's], `width` character widths added to the
   !< titles, `title` a row above the entries (empty: none), `offset` a shift [characters, y up], `title_justify` the
   !< title's justification (`left`, `center` or `right`, as gnuplot `set key title "T" left`). Apart from `set_key`:
   !< nvfortran 26.9 -O2 loses `present(at)` there with these optional arguments after it.
   class(figure_object), intent(inout)        :: self      !< Figure.
   logical,              intent(in), optional :: reverse   !< Samples left of the titles.
   logical,              intent(in), optional :: left      !< Titles left-justified.
   logical,              intent(in), optional :: invert    !< Entries in reverse order.
   logical,              intent(in), optional :: opaque    !< The key area painted over the plot.
   real(R8P),            intent(in), optional :: samplen   !< Sample length [character widths].
   real(R8P),            intent(in), optional :: width     !< Width added to the titles [character widths].
   character(len=*),     intent(in), optional :: title     !< Key title.
   real(R8P),            intent(in), optional :: offset(:) !< Key shift [characters].
   character(len=*),     intent(in), optional :: title_justify !< Key title justification.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (present(reverse)) panel%key_reverse = reverse
      if (present(left)) panel%key_left = left
      if (present(invert)) panel%key_invert = invert
      if (present(opaque)) panel%key_opaque = opaque
      if (present(samplen)) panel%key_samplen = samplen
      if (present(width)) panel%key_extra = width
      if (present(title)) panel%key_title = title
      if (present(offset)) panel%key_offset = offset
      if (present(title_justify)) then
         select case (title_justify)
         case ('left')
            panel%key_title_anchor = 'start'
         case ('center', 'centre')
            panel%key_title_anchor = 'middle'
         case ('right')
            panel%key_title_anchor = 'end'
         case default
            error stop 'foresight: set_key_style: title justification "'//title_justify//'" (left, center or right)'
         endselect
      endif
   endassociate
   endsubroutine set_key_style

   subroutine set_enhanced(self, on)
   !< Read the titles, labels and key entries as gnuplot's enhanced text (`x^2`, `T_{n-1}`, `{/Symbol a}`; see
   !< foresight_enhanced), as gnuplot `set termoption enhanced`, or as they are.
   class(figure_object), intent(inout)        :: self !< Figure.
   logical,              intent(in), optional :: on   !< Enhanced, true if absent.

   self%enhanced = .true.
   if (present(on)) self%enhanced = on
   endsubroutine set_enhanced

   subroutine set_margin(self, side, value, screen)
   !< Set a margin of the current panel, as gnuplot `set lmargin|rmargin|tmargin|bmargin`: `side` is `l`, `r`, `t` or
   !< `b`; `value` characters (0.6 font sizes wide, 1 high), or with `screen` the border at that fraction of the page
   !< (from the bottom left); a negative value (or none) lets it be computed.
   class(figure_object), intent(inout)        :: self   !< Figure.
   character(len=1),     intent(in)           :: side   !< `l`, `r`, `t` or `b`.
   real(R8P),            intent(in), optional :: value  !< Margin.
   logical,              intent(in), optional :: screen !< At a page fraction.
   integer(I4P)                               :: k      !< Side index: left, right, top, bottom.

   call self%ensure_panels
   k = index('lrtb', side, kind=I4P)
   if (k == 0_I4P) error stop 'foresight: set_margin: side is l, r, t or b'
   associate(panel => self%panels(self%current))
      panel%margin_user(k) = -1.0_R8P
      panel%margin_screen(k) = .false.
      if (present(value)) panel%margin_user(k) = value
      if (present(screen)) panel%margin_screen(k) = screen
      if (panel%margin_user(k) < 0.0_R8P) panel%margin_screen(k) = .false.
   endassociate
   endsubroutine set_margin

   subroutine set_title(self, title, offset)
   !< Set the title of the current panel, empty for none, shifted by `offset` characters (x right, y up; gnuplot
   !< `set title offset`).
   class(figure_object), intent(inout)        :: self      !< Figure.
   character(len=*),     intent(in)           :: title     !< Title.
   real(R8P),            intent(in), optional :: offset(2) !< Shift [characters].

   call self%ensure_panels
   self%panels(self%current)%title = title
   if (present(offset)) self%panels(self%current)%title_offset = offset
   endsubroutine set_title

   subroutine set_trange(self, min, max)
   !< Angle range the script functions of a polar panel are sampled over, as gnuplot `set trange [min:max]` (in
   !< `set_angles` units; a full turn from 0 when absent). A set end also leaves out the data points beyond it, as
   !< gnuplot 6.0.
   class(figure_object), intent(inout)        :: self !< Figure.
   real(R8P),            intent(in), optional :: min  !< First angle.
   real(R8P),            intent(in), optional :: max  !< Last angle.

   call self%ensure_panels
   call self%panels(self%current)%taxis%set_range(min=min, max=max)
   endsubroutine set_trange

   subroutine set_ttics(self, step, start, format, on)
   !< Theta labels of a polar panel outside its largest r, every `step` degrees from `start` (0), whatever the angle
   !< unit, as gnuplot `set ttics START,STEP`; every 45 degrees without `step` (gnuplot draws none); `format` the label
   !< format; `on` false turns them off (the default, `unset ttics`).
   class(figure_object), intent(inout)        :: self   !< Figure.
   real(R8P),            intent(in), optional :: step   !< Label step [deg].
   real(R8P),            intent(in), optional :: start  !< First label [deg].
   character(len=*),     intent(in), optional :: format !< Label format.
   logical,              intent(in), optional :: on     !< Labels on.
   character(len=:), allocatable              :: message !< Format problem.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (present(on)) then
         if (.not. on) then
            panel%ttics%mode = TICS_NONE
            return
         endif
      endif
      if (present(step)) then
         if (.not. step > 0.0_R8P) error stop 'foresight: set_ttics: the step must be positive'
      endif
      call set_tics(panel%ttics, 'set_ttics', step, start)
      if (present(format)) then
         message = format_check(format)
         if (len(message) > 0) error stop 'foresight: set_ttics: '//message
         panel%ttics%format = format
      endif
   endassociate
   endsubroutine set_ttics

   subroutine splot_points(self, x, y, z, title, with, lc, lw, dt, ps, pt, palette, zlow, zhigh, fs)
   !< Add the points (`x`, `y`, `z`) to the current panel, made a 3D panel, as gnuplot `splot ... using 1:2:3`: one
   !< scan of scattered points, in the style `with` (points by default) and the line options of `plot`; `palette`
   !< colors them by their height (gnuplot `lc palette`). `with='zerrorfill'`: the line through the points and the band
   !< from `zlow` to `zhigh` filled below it (gnuplot `splot ... using 1:2:3:4:5 with zerrorfill`); `with='boxes'`: 3D
   !< boxes from the base plane (their width `set_boxwidth`, their depth `set_boxdepth`); `with='polygons'`: the points
   !< the vertices of one polygon; `fs` the fill style words of these. zerrorfill's colors are gnuplot's: the band in
   !< the line color `lc` and the line in the fill's border color (black by default).
   class(figure_object), intent(inout)        :: self  !< Figure.
   real(R8P),            intent(in)           :: x(:)  !< Abscissae.
   real(R8P),            intent(in)           :: y(:)  !< Ordinates.
   real(R8P),            intent(in)           :: z(:)  !< Heights.
   character(len=*),     intent(in), optional :: title !< Key title.
   character(len=*),     intent(in), optional :: with  !< Style, points if absent.
   character(len=*),     intent(in), optional :: lc    !< Line color.
   real(R8P),            intent(in), optional :: lw    !< Line width [px].
   integer(I4P),         intent(in), optional :: dt    !< Dash type.
   real(R8P),            intent(in), optional :: ps    !< Point size.
   integer(I4P),         intent(in), optional :: pt    !< Point type.
   logical,              intent(in), optional :: palette !< Colored by height through the palette.
   real(R8P),            intent(in), optional :: zlow(:)  !< Lower ends of the z errors (`zerrorfill`).
   real(R8P),            intent(in), optional :: zhigh(:) !< Upper ends of the z errors (`zerrorfill`).
   character(len=*),     intent(in), optional :: fs    !< Fill style words.
   logical                                    :: by_z  !< Colored by height.
   logical                                    :: zerr  !< `with='zerrorfill'`.
   character(len=:), allocatable              :: bad   !< Unknown fill word.

   if (size(x) /= size(y) .or. size(x) /= size(z)) error stop 'foresight: splot: x, y and z sizes differ'
   by_z = .false.
   if (present(palette)) by_z = palette
   zerr = .false.
   if (present(with)) zerr = with == 'zerrorfill'
   if (zerr) then
      if (.not. (present(zlow) .and. present(zhigh))) error stop 'foresight: splot: zerrorfill takes zlow and zhigh'
      if (size(zlow) /= size(z) .or. size(zhigh) /= size(z)) error stop 'foresight: splot: zlow, zhigh and z sizes differ'
      call self%plot(x, y, title=title, with='lines', lc=lc, lw=lw, dt=dt)
   elseif (by_z) then
      if (present(with)) then
         call self%plot(x, y, title=title, with=with, lw=lw, dt=dt, ps=ps, pt=pt, palette_z=z, fs=fs)
      else
         call self%plot(x, y, title=title, with='points', lw=lw, dt=dt, ps=ps, pt=pt, palette_z=z)
      endif
   elseif (present(with)) then
      call self%plot(x, y, title=title, with=with, lc=lc, lw=lw, dt=dt, ps=ps, pt=pt, fs=fs)
   else
      call self%plot(x, y, title=title, with='points', lc=lc, lw=lw, dt=dt, ps=ps, pt=pt)
   endif
   call heights_of_last(self, z, reshape([1_I4P, size(z, kind=I4P)], [2, 1]))
   associate(panel => self%panels(self%current))
      if (zerr) then
         panel%series(size(panel%series))%zlow = zlow
         panel%series(size(panel%series))%zhigh = zhigh
         panel%series(size(panel%series))%zerrorfill = .true.
         ! its fill: set_style_fill's, then `fs` (gnuplot's fill_properties; its border colors the line)
         panel%series(size(panel%series))%style%fill = panel%fill_default%fill
         panel%series(size(panel%series))%style%density = panel%fill_default%density
         panel%series(size(panel%series))%style%pattern = panel%fill_default%pattern
         panel%series(size(panel%series))%style%border = panel%fill_default%border
         if (allocated(panel%fill_default%border_color)) &
            panel%series(size(panel%series))%style%border_color = panel%fill_default%border_color
         if (present(fs)) then
            call fill_style(fs, panel%series(size(panel%series))%style, bad)
            if (len(bad) > 0) error stop 'foresight: splot: unsupported fill style "'//bad//'"'
         endif
      endif
      ! set_dgrid3d: the scattered points gridded (gnuplot's grid_nongrid_data)
      if (panel%dgrid3d%on) call grid_series(panel%series(size(panel%series)), panel%dgrid3d)
   endassociate
   endsubroutine splot_points

   subroutine splot_grid(self, x, y, z, title, with, lc, lw, dt, ps, pt, palette)
   !< Add the surface `z(i, j)` at (`x(i)`, `y(j)`) to the current panel, made a 3D panel, as gnuplot `splot` of a
   !< grid: a scan per `y(j)` (gnuplot's iso-curves), in the style `with` (lines by default; `image` its pixels, the
   !< grid evenly spaced; `pm3d` colored quadrangles; `contourfill` the quadrangles cut into the slices of
   !< `set_contourfill`, each in one color) and the line options of `plot`; `palette` colors the points by height.
   class(figure_object), intent(inout)        :: self   !< Figure.
   real(R8P),            intent(in)           :: x(:)   !< Abscissae of the columns.
   real(R8P),            intent(in)           :: y(:)   !< Ordinates of the rows.
   real(R8P),            intent(in)           :: z(:,:) !< Heights (column, row).
   character(len=*),     intent(in), optional :: title  !< Key title.
   character(len=*),     intent(in), optional :: with   !< Style, lines if absent.
   character(len=*),     intent(in), optional :: lc     !< Line color.
   real(R8P),            intent(in), optional :: lw     !< Line width [px].
   integer(I4P),         intent(in), optional :: dt     !< Dash type.
   real(R8P),            intent(in), optional :: ps     !< Point size.
   integer(I4P),         intent(in), optional :: pt     !< Point type.
   logical,              intent(in), optional :: palette !< Colored by height through the palette.
   real(R8P),    allocatable                  :: xs(:)  !< Points, a NaN break after each scan.
   real(R8P),    allocatable                  :: ys(:)  !< Their ordinates.
   real(R8P),    allocatable                  :: zs(:)  !< Their heights.
   integer(I4P), allocatable                  :: scans(:,:) !< First and last point of each scan.
   integer(I4P)                               :: nx     !< Columns.
   integer(I4P)                               :: j      !< Row.
   integer(I4P)                               :: k      !< First point of the scan.

   if (size(z, 1) /= size(x) .or. size(z, 2) /= size(y)) error stop 'foresight: splot: z must be size(x) by size(y)'
   if (present(with)) then
      if (with == 'image') then
         ! the grid's pixels, as plot's image (gnuplot `splot ... with image`)
         call self%image(z, x, y, title=title)
         self%panels(self%current)%three_d = .true.
         return
      endif
   endif
   nx = size(x, kind=I4P)
   allocate(xs((nx + 1_I4P) * size(y) - 1_I4P), ys((nx + 1_I4P) * size(y) - 1_I4P), zs((nx + 1_I4P) * size(y) - 1_I4P))
   allocate(scans(2, size(y)))
   xs = ieee_value(1.0_R8P, ieee_quiet_nan)
   ys = xs
   zs = xs
   do j = 1_I4P, size(y, kind=I4P)
      k = (j - 1_I4P) * (nx + 1_I4P) + 1_I4P
      xs(k:k + nx - 1_I4P) = x
      ys(k:k + nx - 1_I4P) = y(j)
      zs(k:k + nx - 1_I4P) = z(:, j)
      scans(:, j) = [k, k + nx - 1_I4P]
   enddo
   if (present(palette)) then
      if (palette) then
         if (present(with)) then
            call self%plot(xs, ys, title=title, with=with, lw=lw, dt=dt, ps=ps, pt=pt, palette_z=zs)
         else
            call self%plot(xs, ys, title=title, with='lines', lw=lw, dt=dt, ps=ps, pt=pt, palette_z=zs)
         endif
         call heights_of_last(self, zs, scans)
         return
      endif
   endif
   if (present(with)) then
      if (with == 'contourfill') then
         ! a pm3d surface in z slices, out of the contours (gnuplot's CONTOURFILL, opt_out_of_contours)
         call self%plot(xs, ys, title=title, with='pm3d', lc=lc, lw=lw, dt=dt)
         call heights_of_last(self, zs, scans)
         associate(last => self%panels(self%current)%series(size(self%panels(self%current)%series)))
            last%contourfill = .true.
            last%no_contours = .true.
         endassociate
         return
      endif
      call self%plot(xs, ys, title=title, with=with, lc=lc, lw=lw, dt=dt, ps=ps, pt=pt)
   else
      call self%plot(xs, ys, title=title, with='lines', lc=lc, lw=lw, dt=dt, ps=ps, pt=pt)
   endif
   call heights_of_last(self, zs, scans)
   endsubroutine splot_grid

   subroutine heights_of_last(self, z, scans)
   !< The heights `z` and the `scans` of the last series of the current panel, made a 3D panel.
   class(figure_object), intent(inout) :: self       !< Figure.
   real(R8P),            intent(in)    :: z(:)       !< Heights.
   integer(I4P),         intent(in)    :: scans(:,:) !< First and last point of each scan.
   integer(I4P)                        :: last       !< Last series.

   associate(panel => self%panels(self%current))
      panel%three_d = .true.
      last = size(panel%series, kind=I4P)
      panel%series(last)%z = z
      panel%series(last)%scans = scans
      ! set_hidden3d: the underside in the linetype `offset` after the surface's, a linetype reserved for it (gnuplot)
      if (panel%view3d%hidden3d .and. panel%view3d%hidden_offset /= 0_I4P) then
         panel%series(last)%back_color = default_color(last + panel%color_shift + panel%view3d%hidden_offset, &
                                                       panel%linecolors)
         panel%color_shift = panel%color_shift + 1_I4P
      endif
      allocate(panel%series(last)%scan_sets(size(scans, 2)))
      panel%series(last)%scan_sets = 0_I4P
      panel%series(last)%grid_scans = size(scans, 2, kind=I4P)
   endassociate
   endsubroutine heights_of_last

   subroutine set_contour(self, on, place, kind, levels, discrete, incremental, points, order, firstlinetype, sorted, &
                          format, onecolor)
   !< The contour lines of the 3D surfaces, gnuplot `set contour PLACE` (`on`, `place` `base`, `surface`, `both`),
   !< `set cntrparam`: `kind` `linear`, `cubicspline`, `bspline`; `levels` N (automatic, about N), `discrete` the levels,
   !< `incremental` start, step[, end]; `points` per spline interval, B-spline `order`, `firstlinetype`, `sorted`;
   !< `set cntrlabel`: the label `format` ("%8.3g"), `onecolor`.
   class(figure_object), intent(inout)        :: self           !< Figure.
   logical,              intent(in), optional :: on             !< Contours drawn.
   character(len=*),     intent(in), optional :: place          !< `base`, `surface` or `both`.
   character(len=*),     intent(in), optional :: kind           !< `linear`, `cubicspline` or `bspline`.
   integer(I4P),         intent(in), optional :: levels         !< About N automatic levels.
   real(R8P),            intent(in), optional :: discrete(:)    !< The levels.
   real(R8P),            intent(in), optional :: incremental(:) !< Start, step[, end].
   integer(I4P),         intent(in), optional :: points         !< Points per spline interval.
   integer(I4P),         intent(in), optional :: order          !< B-spline order, 2 to 10.
   integer(I4P),         intent(in), optional :: firstlinetype  !< Linetype of the first level.
   logical,              intent(in), optional :: sorted         !< Levels high to low.
   character(len=*),     intent(in), optional :: format         !< Label format.
   logical,              intent(in), optional :: onecolor       !< All levels in the surface's color.

   call self%ensure_panels
   associate(cnt => self%panels(self%current)%contour)
      cnt%on = .true.
      if (present(on)) cnt%on = on
      if (present(place)) cnt%place = place
      if (present(kind)) then
         select case (kind)
         case ('linear')
            cnt%kind = CONTOUR_LINEAR
         case ('cubicspline')
            cnt%kind = CONTOUR_CUBIC
         case ('bspline')
            cnt%kind = CONTOUR_BSPLINE
         case default
            error stop 'foresight: set_contour: kind must be linear, cubicspline or bspline'
         endselect
      endif
      if (present(levels)) then
         cnt%levels_kind = LEVELS_AUTO
         cnt%levels = levels
      endif
      if (present(discrete)) then
         cnt%levels_kind = LEVELS_DISCRETE
         cnt%list = discrete
         cnt%levels = size(discrete, kind=I4P)
      endif
      if (present(incremental)) then
         if (size(incremental) < 2) error stop 'foresight: set_contour: incremental needs start, step[, end]'
         cnt%levels_kind = LEVELS_INCREMENTAL
         cnt%list = incremental(1:2)
         if (size(incremental) >= 3) cnt%levels = int((incremental(3) - incremental(1)) / incremental(2) + 1.0_R8P, I4P)
      endif
      if (present(points)) cnt%npoints = points
      if (present(order)) cnt%order = order
      if (present(firstlinetype)) cnt%firstlinetype = firstlinetype
      if (present(sorted)) cnt%sorted = sorted
      if (present(format)) cnt%format = format
      if (present(onecolor)) cnt%onecolor = onecolor
   endassociate
   endsubroutine set_contour

   subroutine set_dgrid3d(self, on, rows, cols, mode, norm, scale, kdensity)
   !< gnuplot `set dgrid3d`: the scattered points of `splot` gridded (`on`), `rows` points along y of `cols` iso-curves
   !< of x (10, 10), each node a weighted mean of the points by `mode`: `qnorm` (inverse distance to the power `norm`,
   !< 1), `splines` (thin plate splines), or a kernel of the distance scaled by `scale` (dx, dy; 1, 1) `gauss`,
   !< `cauchy`, `exp`, `box`, `hann`; `kdensity` the kernel's weighted sums, a density.
   class(figure_object), intent(inout)        :: self     !< Figure.
   logical,              intent(in), optional :: on       !< Data gridded.
   integer(I4P),         intent(in), optional :: rows     !< Points along y of each iso-curve.
   integer(I4P),         intent(in), optional :: cols     !< Iso-curves of x.
   character(len=*),     intent(in), optional :: mode     !< Weighting.
   integer(I4P),         intent(in), optional :: norm     !< The power of `qnorm`.
   real(R8P),            intent(in), optional :: scale(2) !< Kernel scales along x and y.
   logical,              intent(in), optional :: kdensity !< Kernel sums (a density), not means.

   call self%ensure_panels
   associate(dg => self%panels(self%current)%dgrid3d)
      dg%on = .true.
      if (present(on)) dg%on = on
      if (present(rows)) dg%rows = rows
      if (present(cols)) dg%cols = cols
      if (present(norm)) dg%norm = norm
      if (present(scale)) dg%scale = scale
      if (present(kdensity)) dg%kdensity = kdensity
      if (present(mode)) then
         select case (mode)
         case ('qnorm')
            dg%mode = DGRID_QNORM
         case ('splines')
            dg%mode = DGRID_SPLINES
         case ('gauss')
            dg%mode = DGRID_GAUSS
         case ('cauchy')
            dg%mode = DGRID_CAUCHY
         case ('exp')
            dg%mode = DGRID_EXP
         case ('box')
            dg%mode = DGRID_BOX
         case ('hann')
            dg%mode = DGRID_HANN
         case default
            error stop 'foresight: set_dgrid3d: mode must be qnorm, splines, gauss, cauchy, exp, box or hann'
         endselect
      endif
      if (dg%rows < 2_I4P .or. dg%cols < 2_I4P) error stop 'foresight: set_dgrid3d: rows and cols must be at least 2'
   endassociate
   endsubroutine set_dgrid3d

   subroutine set_pm3d(self, implicit, interpolate, corners2color, clip4in, at, order, border, clip, lighting, primary, &
                       specular, spec2)
   !< gnuplot `set pm3d`: `implicit` every surface drawn as colored quadrangles too (`set pm3d`; false: only the items
   !< `with='pm3d'`, `unset pm3d`), `interpolate` the steps along and between the scans (`interpolate N,M`, 0 or
   !< negative for gnuplot's automatic counts), `corners2color` the color of a quadrangle from its corners (`mean`,
   !< `geomean`, `harmean`, `rms`, `median`, `min`, `max`, `c1` to `c4`), `clip4in` its 4 corners in range. In 3D
   !< views: `at` where (`b` the base, `s` the surface, `t` the top, combined in drawing order, e.g. `'bs'`), `order`
   !< the drawing order (`scansautomatic`, `scansforward`, `scansbackward`, `depthorder`), `border` the quadrangles
   !< outlined in black; `clip` `'z'` (gnuplot's `clip z`, the default: the quadrangles cut at the z range), `'1in'`
   !< (`clip1in`: one corner in range is enough) or `'4in'` (`clip4in`); `lighting` gnuplot's `set pm3d lighting`
   !< (false: `nolighting`), its `primary` light (0.5), `specular` highlights (0.2) and `spec2` the spotlight's share (0,
   !< see `set_spotlight`), each between 0 and 1.
   class(figure_object), intent(inout)        :: self           !< Figure.
   logical,              intent(in), optional :: implicit       !< Every surface drawn with pm3d.
   integer(I4P),         intent(in), optional :: interpolate(2) !< Interpolation steps.
   character(len=*),     intent(in), optional :: corners2color  !< Color of a quadrangle from its corners.
   logical,              intent(in), optional :: clip4in        !< Its 4 corners in range.
   character(len=*),     intent(in), optional :: at             !< Where: b, s, t combined.
   character(len=*),     intent(in), optional :: order          !< Drawing order in 3D views.
   logical,              intent(in), optional :: border         !< Outlined quadrangles.
   character(len=*),     intent(in), optional :: clip           !< `z`, `1in` or `4in`.
   logical,              intent(in), optional :: lighting       !< Lit quadrangles.
   real(R8P),            intent(in), optional :: primary        !< Share of the primary light.
   real(R8P),            intent(in), optional :: specular       !< Share of the specular highlights.
   real(R8P),            intent(in), optional :: spec2          !< Share of the spotlight.

   call self%ensure_panels
   associate(pm => self%panels(self%current)%pm3d)
      if (present(clip)) then
         select case (clip)
         case ('z')
            pm%clip4in = .false.
            pm%clip_z = .true.
         case ('1in')
            pm%clip4in = .false.
            pm%clip_z = .false.
         case ('4in')
            pm%clip4in = .true.
            pm%clip_z = .false.
         case default
            error stop 'foresight: set_pm3d: clip must be z, 1in or 4in'
         endselect
      endif
      if (present(lighting)) then
         ! gnuplot's parse_lighting_options: `lighting` alone primary 0.5, specular 0.2, no spotlight
         pm%strength = 0.0_R8P
         pm%spec = 0.0_R8P
         pm%spec2 = 0.0_R8P
         if (lighting) then
            pm%strength = 0.5_R8P
            pm%spec = 0.2_R8P
         endif
      endif
      if (present(primary)) pm%strength = min(1.0_R8P, max(0.0_R8P, primary))
      if (present(specular)) pm%spec = min(1.0_R8P, max(0.0_R8P, specular))
      if (present(spec2)) pm%spec2 = min(1.0_R8P, max(0.0_R8P, spec2))
      if ((present(primary) .or. present(specular) .or. present(spec2)) .and. pm%strength == 0.0_R8P) &
         error stop 'foresight: set_pm3d: primary, specular and spec2 need lighting'
      if (present(at)) then
         if (len(at) == 0 .or. len(at) > 6 .or. verify(at, 'bst') /= 0) &
            error stop 'foresight: set_pm3d: at must combine b, s and t (6 letters at most)'
         pm%at = at
      endif
      if (present(order)) then
         select case (order)
         case ('scansautomatic')
            pm%direction = 0_I4P
         case ('scansforward')
            pm%direction = 1_I4P
         case ('scansbackward')
            pm%direction = 2_I4P
         case ('depthorder')
            pm%direction = 3_I4P
         case default
            error stop 'foresight: set_pm3d: order must be scansautomatic, scansforward, scansbackward or depthorder'
         endselect
      endif
      if (present(border)) then
         pm%border = border
         pm%border_color = 'black'
         pm%border_lw = 1.0_R8P
      endif
      if (present(implicit)) pm%implicit = implicit
      if (present(interpolate)) pm%interp = interpolate
      if (present(clip4in)) pm%clip4in = clip4in
      if (present(corners2color)) then
         select case (corners2color)
         case ('mean')
            pm%corners = CORNERS_MEAN
         case ('geomean')
            pm%corners = CORNERS_GEOMEAN
         case ('harmean')
            pm%corners = CORNERS_HARMEAN
         case ('rms')
            pm%corners = CORNERS_RMS
         case ('median')
            pm%corners = CORNERS_MEDIAN
         case ('min')
            pm%corners = CORNERS_MIN
         case ('max')
            pm%corners = CORNERS_MAX
         case ('c1', 'c2', 'c3', 'c4')
            pm%corners = CORNERS_C1 + iachar(corners2color(2:2)) - iachar('1')
         case default
            error stop 'foresight: set_pm3d: corners2color must be mean, geomean, harmean, rms, median, min, max, '// &
                       'c1, c2, c3 or c4'
         endselect
      endif
   endassociate
   endsubroutine set_pm3d

   subroutine set_spotlight(self, rot_x, rot_z, color, phong, default)
   !< The spotlight of pm3d's lighting, gnuplot `set pm3d spotlight [rot_x A] [rot_z B] [rgbcolor C] [Phong P]
   !< [default]`: its direction (`rot_x`, `rot_z` [deg], 50 and 90), its `color` ('#rrggbb', gnuplot's '#ff0044'), its
   !< Phong exponent `phong` (4); `default` those back first. Its share of the light is `set_pm3d(spec2=)`.
   class(figure_object), intent(inout)        :: self    !< Figure.
   real(R8P),            intent(in), optional :: rot_x   !< Rotation about x [deg].
   real(R8P),            intent(in), optional :: rot_z   !< Rotation about z [deg].
   character(len=*),     intent(in), optional :: color   !< Color, '#rrggbb'.
   real(R8P),            intent(in), optional :: phong   !< Phong exponent.
   logical,              intent(in), optional :: default !< gnuplot's spotlight first.
   integer(I4P)                               :: ios     !< Read status.

   call self%ensure_panels
   associate(pm => self%panels(self%current)%pm3d)
      if (present(default)) then
         if (default) then
            pm%spot_rot = [50.0_R8P, 90.0_R8P]
            pm%spot_rgb = 16711748_I4P
            pm%spot_phong = 4.0_R8P
         endif
      endif
      if (present(rot_x)) pm%spot_rot(1) = rot_x
      if (present(rot_z)) pm%spot_rot(2) = rot_z
      if (present(phong)) pm%spot_phong = abs(phong)
      if (present(color)) then
         ios = 1_I4P
         if (len(color) == 7) then
            if (color(1:1) == '#') read(color(2:7), '(Z6)', iostat=ios) pm%spot_rgb
         endif
         if (ios /= 0_I4P) error stop 'foresight: set_spotlight: color must be #rrggbb, not "'//color//'"'
      endif
   endassociate
   endsubroutine set_spotlight

   subroutine set_contourfill(self, levels, ztics, cbtics, firstlinetype, palette)
   !< The slices of `splot(..., with='contourfill')`, gnuplot `set contourfill`: `levels` N slices evenly over the z range
   !< (`auto N`, 5 by default), or bounded by the major `ztics` or `cbtics`; each slice colored by the palette at its
   !< middle (`palette`, the default), or in the linetypes from `firstlinetype`.
   class(figure_object), intent(inout)        :: self          !< Figure.
   integer(I4P),         intent(in), optional :: levels        !< Slices.
   logical,              intent(in), optional :: ztics         !< Bounded by the z ticks.
   logical,              intent(in), optional :: cbtics        !< Bounded by the cb ticks.
   integer(I4P),         intent(in), optional :: firstlinetype !< Linetype of the first slice.
   logical,              intent(in), optional :: palette       !< Colored by the palette.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (present(levels)) then
         panel%cfill_mode = 0_I4P
         panel%cfill_n = max(1_I4P, min(levels, 100_I4P))
      endif
      if (present(ztics)) then
         if (ztics) panel%cfill_mode = 1_I4P
      endif
      if (present(cbtics)) then
         if (cbtics) panel%cfill_mode = 2_I4P
      endif
      if (present(firstlinetype)) panel%cfill_lt = firstlinetype
      if (present(palette)) then
         if (palette) panel%cfill_lt = -1_I4P
      endif
   endassociate
   endsubroutine set_contourfill

   subroutine set_wall(self, which, on, fc, fs, lw)
   !< A grid wall of the 3D views, gnuplot `set wall y0|x0|y1|x1|z0` (the planes y = 0, x = 0, y = 1, x = 1, z = 0 of the
   !< graph) or, without `which`, `set walls` (y0, x0 and z0): filled half transparent in gnuplot's colors (the y walls
   !< '#cdb79e', the x ones '#228b22', z '#a0b6cd') and bordered black, drawn behind or in front of the plot as they face;
   !< `fc` the fill color, `fs` the fill style words (`'solid 0.3 noborder'`), `lw` the border width; `on` false removes
   !< it (every wall without `which`, `unset walls`).
   class(figure_object), intent(inout)        :: self  !< Figure.
   character(len=*),     intent(in), optional :: which !< `y0`, `x0`, `y1`, `x1` or `z0`.
   logical,              intent(in), optional :: on    !< Drawn.
   character(len=*),     intent(in), optional :: fc    !< Fill color.
   character(len=*),     intent(in), optional :: fs    !< Fill style words.
   real(R8P),            intent(in), optional :: lw    !< Border width [px].
   character(len=2), parameter :: NAMES(5) = ['y0', 'x0', 'y1', 'x1', 'z0'] !< gnuplot's wall tags, in order.
   logical                     :: drawn !< Drawn.
   integer(I4P)                :: w     !< Wall.
   integer(I4P)                :: k     !< Counter.

   call self%ensure_panels
   drawn = .true.
   if (present(on)) drawn = on
   if (.not. present(which)) then
      if (.not. drawn) then
         self%panels(self%current)%wall_on = .false.
         return
      endif
      if (.not. allocated(self%panels(self%current)%walls)) allocate(self%panels(self%current)%walls(5))
      do k = 1_I4P, 5_I4P
         if (k == 3_I4P .or. k == 4_I4P) cycle
         self%panels(self%current)%walls(k) = wall_polygon(k, fc, fs, lw)
         self%panels(self%current)%wall_on(k) = .true.
      enddo
      return
   endif
   do w = 5_I4P, 1_I4P, -1_I4P
      if (NAMES(w) == which) exit
   enddo
   if (w == 0_I4P) error stop 'foresight: set_wall: which must be y0, x0, y1, x1 or z0, not "'//which//'"'
   if (.not. drawn) then
      self%panels(self%current)%wall_on(w) = .false.
      return
   endif
   if (.not. allocated(self%panels(self%current)%walls)) allocate(self%panels(self%current)%walls(5))
   self%panels(self%current)%walls(w) = wall_polygon(w, fc, fs, lw)
   self%panels(self%current)%wall_on(w) = .true.
   endsubroutine set_wall

   function wall_polygon(k, fc, fs, lw) result(obj)
   !< Grid wall `k` (y0, x0, y1, x1, z0) with gnuplot's default style and the options: a module procedure, not an
   !< internal one of set_wall (nvfortran 26.9 corrupted the figure through one).
   integer(I4P),     intent(in)           :: k   !< Wall.
   character(len=*), intent(in), optional :: fc  !< Fill color.
   character(len=*), intent(in), optional :: fs  !< Fill style words.
   real(R8P),        intent(in), optional :: lw  !< Border width [px].
   type(shape_object)                     :: obj !< The wall.
   real(R8P), parameter :: CORNERS(3, 4, 5) = reshape([ &
      0.0_R8P, 0.0_R8P, 0.0_R8P,  0.0_R8P, 0.0_R8P, 1.0_R8P,  1.0_R8P, 0.0_R8P, 1.0_R8P,  1.0_R8P, 0.0_R8P, 0.0_R8P, &
      0.0_R8P, 0.0_R8P, 0.0_R8P,  0.0_R8P, 1.0_R8P, 0.0_R8P,  0.0_R8P, 1.0_R8P, 1.0_R8P,  0.0_R8P, 0.0_R8P, 1.0_R8P, &
      0.0_R8P, 1.0_R8P, 0.0_R8P,  1.0_R8P, 1.0_R8P, 0.0_R8P,  1.0_R8P, 1.0_R8P, 1.0_R8P,  0.0_R8P, 1.0_R8P, 1.0_R8P, &
      1.0_R8P, 0.0_R8P, 0.0_R8P,  1.0_R8P, 0.0_R8P, 1.0_R8P,  1.0_R8P, 1.0_R8P, 1.0_R8P,  1.0_R8P, 1.0_R8P, 0.0_R8P, &
      0.0_R8P, 0.0_R8P, 0.0_R8P,  1.0_R8P, 0.0_R8P, 0.0_R8P,  1.0_R8P, 1.0_R8P, 0.0_R8P,  0.0_R8P, 1.0_R8P, 0.0_R8P], &
      [3, 4, 5]) !< Graph corners of each wall, as gnuplot's.
   character(len=7), parameter :: COLORS(5) = ['#cdb79e', '#228b22', '#cdb79e', '#228b22', '#a0b6cd'] !< gnuplot's
                                                                                       !< WALL_Y/X/Z_COLOR.
   character(len=:), allocatable :: bad !< Unknown fill word.
   integer(I4P)                  :: c   !< Corner.
   integer(I4P)                  :: m   !< Its column.

   obj%kind = 'polygon'
   allocate(obj%points(5))
   do c = 1_I4P, 5_I4P
      m = 1_I4P + mod(c - 1_I4P, 4_I4P)
      obj%points(c)%x = CORNERS(1, m, k)
      obj%points(c)%y = CORNERS(2, m, k)
      obj%points(c)%z = CORNERS(3, m, k)
      obj%points(c)%sx = 'graph'
      obj%points(c)%sy = 'graph'
      obj%points(c)%sz = 'graph'
   enddo
   call fill_style('transparent solid 0.5 border', obj%style, bad)
   obj%style%color = COLORS(k)
   if (present(fc)) obj%style%color = fc
   if (present(fs)) then
      call fill_style(fs, obj%style, bad)
      if (len(bad) > 0) error stop 'foresight: set_wall: unsupported fill style "'//bad//'"'
   endif
   obj%style%border_color = 'black'
   if (present(lw)) obj%style%linewidth = lw
   obj%layer = 'fb'
   endfunction wall_polygon

   subroutine set_boxdepth(self, depth, square)
   !< The depth along y of the 3D boxes (`splot(..., with='boxes')`), gnuplot `set boxdepth D` (y autoscaled over y +- D),
   !< `set boxdepth square` (`square`: as deep as wide on the page); 0 or none: flat boxes (`unset boxdepth`).
   class(figure_object), intent(inout)        :: self   !< Figure.
   real(R8P),            intent(in), optional :: depth  !< Depth (y axis values).
   logical,              intent(in), optional :: square !< As deep as wide on the page.

   call self%ensure_panels
   self%panels(self%current)%boxdepth = 0.0_R8P
   if (present(depth)) then
      if (depth < 0.0_R8P) error stop 'foresight: set_boxdepth: the depth must not be negative'
      self%panels(self%current)%boxdepth = depth
   endif
   if (present(square)) then
      if (square) self%panels(self%current)%boxdepth = -1.0_R8P
   endif
   endsubroutine set_boxdepth

   subroutine set_view(self, map, rot_x, rot_z, scale, zscale, map_scale, equal, azimuth, projection)
   !< The view of the 3D panels, as gnuplot `set view ROT_X, ROT_Z, SCALE, SCALE_Z` (each kept if absent) or `set view
   !< map [scale S]` (`map` true; false back to the 3D view); `equal` 0 none, 1 `equal xy`, 2 `equal xyz`; `azimuth`
   !< a rotation about the line of sight (`set view azimuth A`); `projection` `xy` (the map), `xz` or `yz` (`set view
   !< projection`: the plane seen edge-on, gnuplot's fixed rotations, the line of sight turned by -90 degrees, the base
   !< plane at the bottom of the z range and the z tick labels centred; the yz plane with the z axis reversed). The
   !< rotations or the map end a projection.
   class(figure_object), intent(inout)        :: self       !< Figure.
   logical,              intent(in), optional :: map        !< Seen from above, as a map.
   real(R8P),            intent(in), optional :: rot_x      !< Rotation about x [deg].
   real(R8P),            intent(in), optional :: rot_z      !< Rotation about z [deg].
   real(R8P),            intent(in), optional :: scale      !< Scale.
   real(R8P),            intent(in), optional :: zscale     !< Scale of z.
   real(R8P),            intent(in), optional :: map_scale  !< Scale of the map view.
   integer(I4P),         intent(in), optional :: equal      !< Equal axes.
   real(R8P),            intent(in), optional :: azimuth    !< Rotation about the line of sight [deg].
   character(len=*),     intent(in), optional :: projection !< `xy`, `xz` or `yz`.

   call self%ensure_panels
   associate(view => self%panels(self%current)%view3d)
      if (present(map)) then
         view%map = map
         view%projection = 0_I4P
      endif
      if (present(rot_x) .or. present(rot_z)) view%projection = 0_I4P
      if (present(rot_x)) view%rot_x = rot_x
      if (present(rot_z)) view%rot_z = rot_z
      if (present(scale)) view%scale = scale
      if (present(zscale)) view%zscale = zscale
      if (present(map_scale)) view%map_scale = map_scale
      if (present(equal)) view%equal = equal
      if (present(azimuth)) view%azimuth = azimuth
      if (present(projection)) then
         select case (projection)
         case ('xy')
            view%map = .true.
            view%projection = 0_I4P
            view%azimuth = 0.0_R8P
         case ('xz', 'yz')
            ! gnuplot's do_3dplot rotations, the view scale 1.425 times the map one when drawn (1 after)
            view%map = .false.
            view%projection = merge(1_I4P, 2_I4P, projection == 'xz')
            view%rot_x = merge(270.0_R8P, 90.0_R8P, view%projection == 1_I4P)
            view%rot_z = merge(0.0_R8P, 90.0_R8P, view%projection == 1_I4P)
            view%scale = 1.0_R8P
            view%azimuth = -90.0_R8P
            view%xyplane_at = .false.
            view%ticslevel = 0.0_R8P
            self%panels(self%current)%zaxis%tics%justify = 'center'
         case default
            error stop 'foresight: set_view: projection must be xy, xz or yz'
         endselect
      endif
   endassociate
   endsubroutine set_view

   subroutine set_hidden3d(self, on, offset)
   !< Hidden lines of the 3D views, as gnuplot `set hidden3d [offset N]` (`on` false: `unset hidden3d`): the grid
   !< surfaces drawn opaque, their underside in the linetype `offset` (1) after their own; for the surfaces added after.
   class(figure_object), intent(inout)        :: self   !< Figure.
   logical,              intent(in), optional :: on     !< Hidden lines removed.
   integer(I4P),         intent(in), optional :: offset !< Linetype offset of the underside (0 the same).

   call self%ensure_panels
   associate(view => self%panels(self%current)%view3d)
      view%hidden3d = .true.
      if (present(on)) view%hidden3d = on
      if (present(offset)) view%hidden_offset = offset
   endassociate
   endsubroutine set_hidden3d

   subroutine set_xyplane(self, at, relative)
   !< The base plane of the 3D views: at the height `at` (gnuplot `set xyplane at Z`), or below the z range by the
   !< fraction `relative` of it (`set xyplane relative F`, `set ticslevel F`; 0.5 by default).
   class(figure_object), intent(inout)        :: self     !< Figure.
   real(R8P),            intent(in), optional :: at       !< Height.
   real(R8P),            intent(in), optional :: relative !< Fraction of the z range.

   call self%ensure_panels
   associate(view => self%panels(self%current)%view3d)
      if (present(at)) then
         view%xyplane_at = .true.
         view%xyplane_z = at
      endif
      if (present(relative)) then
         view%xyplane_at = .false.
         view%ticslevel = relative
      endif
   endassociate
   endsubroutine set_xyplane

   subroutine set_zlabel(self, label)
   !< Set the z axis label of the current panel (a 3D one), empty for none.
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: label !< Label.

   call self%ensure_panels
   self%panels(self%current)%zaxis%label = label
   endsubroutine set_zlabel

   subroutine set_zrange(self, min, max)
   !< Set the z range as gnuplot `set zrange [min:max]`: an absent end is autoscaled.
   class(figure_object), intent(inout)        :: self !< Figure.
   real(R8P),            intent(in), optional :: min  !< Value at the axis start.
   real(R8P),            intent(in), optional :: max  !< Value at the axis end.

   call self%ensure_panels
   call self%panels(self%current)%zaxis%set_range(min=min, max=max)
   endsubroutine set_zrange

   subroutine set_ztics(self, step, start, end, positions, labels, minor, add)
   !< z ticks every `step` from `start` to `end` (both optional), as gnuplot `set ztics START,STEP,END`; automatic
   !< without `step`; `positions`, `labels`, `minor` and `add` an explicit list, as `set_xtics`.
   class(figure_object), intent(inout)        :: self  !< Figure.
   real(R8P),            intent(in), optional :: step  !< Tick step.
   real(R8P),            intent(in), optional :: start !< First tick.
   real(R8P),            intent(in), optional :: end   !< Last tick.
   real(R8P),            intent(in), optional :: positions(:) !< Explicit list positions.
   character(len=*),     intent(in), optional :: labels(:)    !< Explicit list labels.
   logical,              intent(in), optional :: minor(:)     !< Explicit list minor ticks.
   logical,              intent(in), optional :: add          !< Add the list to the ticks.

   call self%ensure_panels
   call set_tics(self%panels(self%current)%zaxis%tics, 'set_ztics', step, start, end, positions=positions, &
                 labels=labels, minor=minor, add=add)
   endsubroutine set_ztics

   subroutine set_xlabel(self, label)
   !< Set the x axis label of the current panel, empty for none.
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: label !< Label.

   call self%ensure_panels
   self%panels(self%current)%xaxis%label = label
   endsubroutine set_xlabel

   subroutine set_xrange(self, min, max)
   !< Set the x range as gnuplot `set xrange [min:max]`: an absent end is autoscaled, `min > max` reverses the axis.
   class(figure_object), intent(inout)        :: self !< Figure.
   real(R8P),            intent(in), optional :: min  !< Value at the axis start.
   real(R8P),            intent(in), optional :: max  !< Value at the axis end.

   call self%ensure_panels
   call self%panels(self%current)%xaxis%set_range(min=min, max=max)
   endsubroutine set_xrange

   subroutine set_cbtics(self, step, start, end, positions, labels, minor, add)
   !< Ticks of the color box every `step` from `start` to `end` (both optional), as gnuplot `set cbtics START,STEP,END`;
   !< automatic without `step`. On a log color axis the step is a factor (> 1).
   !< `positions` is an explicit list, labelled by `labels` (as written, or a format with a conversion; the axis
   !< labels without them), `minor` marking minor ticks; `add` adds it to the ticks instead of replacing them,
   !< as gnuplot `set cbtics [add] ("label" pos level, ...)`.
   class(figure_object), intent(inout)        :: self  !< Figure.
   real(R8P),            intent(in), optional :: step  !< Tick step, a factor on a log axis.
   real(R8P),            intent(in), optional :: start !< First tick.
   real(R8P),            intent(in), optional :: end   !< Last tick.
   real(R8P),            intent(in), optional :: positions(:) !< Explicit list positions, gnuplot `("label" pos, ...)`.
   character(len=*),     intent(in), optional :: labels(:)    !< Explicit list labels (a format if with a conversion).
   logical,              intent(in), optional :: minor(:)     !< Explicit list minor ticks (gnuplot level 1).
   logical,              intent(in), optional :: add          !< Add the list to the ticks (gnuplot `add`).

   call self%ensure_panels
   call set_tics(self%panels(self%current)%cbaxis%tics, 'set_cbtics', step, start, end, positions=positions, &
                 labels=labels, minor=minor, add=add)
   endsubroutine set_cbtics

   subroutine unset_cbtics(self)
   !< No ticks nor tick labels on the color box, as gnuplot `unset cbtics` (the box and its label stay).
   class(figure_object), intent(inout) :: self !< Figure.

   call self%ensure_panels
   call self%panels(self%current)%cbaxis%tics%disable
   endsubroutine unset_cbtics

   subroutine set_xtics(self, step, start, end, mirror, positions, labels, minor, add, rotate, justify, out)
   !< x ticks every `step` from `start` to `end` (both optional), as gnuplot `set xtics START,STEP,END`; automatic
   !< without `step`. On a log axis the step is a factor (> 1): ticks at start * step**k. `mirror` false draws them on
   !< the bottom border only (gnuplot `nomirror`).
   !< `positions` is an explicit list, labelled by `labels` (as written, or a format with a conversion; the axis
   !< labels without them), `minor` marking minor ticks; `add` adds it to the ticks instead of replacing them,
   !< as gnuplot `set xtics [add] ("label" pos level, ...)`.
   !< `rotate` turns the labels [deg, counterclockwise], left-justified unless `justify` (gnuplot `rotate by A`; `rotate`
   !< is 90 with `justify='right'`); `out` points the ticks outward. Alone they keep the tick positions.
   class(figure_object), intent(inout)        :: self   !< Figure.
   real(R8P),            intent(in), optional :: step   !< Tick step, a factor on log axes.
   real(R8P),            intent(in), optional :: start  !< First tick.
   real(R8P),            intent(in), optional :: end    !< Last tick.
   logical,              intent(in), optional :: mirror !< Ticks also on the top border.
   real(R8P),            intent(in), optional :: positions(:) !< Explicit list positions, gnuplot `("label" pos, ...)`.
   character(len=*),     intent(in), optional :: labels(:)    !< Explicit list labels (a format if with a conversion).
   logical,              intent(in), optional :: minor(:)     !< Explicit list minor ticks (gnuplot level 1).
   logical,              intent(in), optional :: add          !< Add the list to the ticks (gnuplot `add`).
   real(R8P),            intent(in), optional :: rotate       !< Label angle [deg, counterclockwise], gnuplot `rotate by`.
   character(len=*),     intent(in), optional :: justify      !< Rotated label justification: left, right, center.
   logical,              intent(in), optional :: out          !< Ticks outward, gnuplot `out`.

   call self%ensure_panels
   call set_tics(self%panels(self%current)%xaxis%tics, 'set_xtics', step, start, end, mirror, positions, labels, minor, &
                 add, rotate, justify, out)
   endsubroutine set_xtics

   subroutine set_mxtics(self, intervals, unit)
   !< Minor x ticks, as gnuplot `set mxtics [N]`: `intervals` between consecutive major ticks of the automatic or
   !< fixed ticks (linearly in value on a log axis), gnuplot's count without it (2 or 5 by the step, 9 on log axes); 0 or
   !< 1 for none, as `unset mxtics`. With a time `unit` (`seconds`, `minutes`, `hours`, `days`, `weeks`, `months`,
   !< `years`), a minor tick every `intervals` units of a time axis, as gnuplot 6.0's `set mxtics time N UNITS`.
   class(figure_object), intent(inout)        :: self      !< Figure.
   integer(I4P),         intent(in), optional :: intervals !< Intervals between major ticks, or time units.
   character(len=*),     intent(in), optional :: unit      !< Time unit.

   call self%ensure_panels
   associate(tics => self%panels(self%current)%xaxis%tics)
      tics%minor = MINOR_AUTO
      tics%minor_count = 0_I4P
      tics%minor_unit = ''
      if (present(intervals)) tics%minor = max(0_I4P, intervals)
      if (present(unit)) then
         if (all(unit /= ['seconds', 'minutes', 'hours  ', 'days   ', 'weeks  ', 'months ', 'years  '])) &
            error stop 'foresight: set_mxtics: unit must be seconds, minutes, hours, days, weeks, months or years'
         if (.not. present(intervals)) error stop 'foresight: set_mxtics: a time unit needs the intervals'
         if (intervals < 1_I4P) error stop 'foresight: set_mxtics: the time intervals must be positive'
         tics%minor = 0_I4P
         tics%minor_count = intervals
         tics%minor_unit = unit
      endif
   endassociate
   endsubroutine set_mxtics

   subroutine set_errorbars(self, size, lc, lw)
   !< The error bars and boxplot whiskers, as gnuplot `set errorbars [SIZE] [lc C] [lw W]`: the cap length `size`
   !< (1 the default, 0 none, as `small`), the line color and width of the error bars (their series' if absent).
   class(figure_object), intent(inout)        :: self !< Figure.
   real(R8P),            intent(in), optional :: size !< Cap length, in units of the default.
   character(len=*),     intent(in), optional :: lc   !< Error bar color.
   real(R8P),            intent(in), optional :: lw   !< Error bar width [px].

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      panel%errorbar_size = 1.0_R8P
      if (present(size)) panel%errorbar_size = max(0.0_R8P, size)
      if (allocated(panel%errorbar_color)) deallocate(panel%errorbar_color)
      if (present(lc)) panel%errorbar_color = lc
      panel%errorbar_lw = 0.0_R8P
      if (present(lw)) panel%errorbar_lw = max(0.0_R8P, lw)
   endassociate
   endsubroutine set_errorbars

   subroutine set_mytics(self, intervals)
   !< Minor y ticks, as gnuplot `set mytics [N]`: `intervals` between consecutive major ticks of the automatic or
   !< fixed ticks (linearly in value on a log axis), gnuplot's count without it (2 or 5 by the step, 9 on log axes); 0 or
   !< 1 for none, as `unset mytics`.
   class(figure_object), intent(inout)        :: self      !< Figure.
   integer(I4P),         intent(in), optional :: intervals !< Intervals between major ticks.

   call self%ensure_panels
   associate(tics => self%panels(self%current)%yaxis%tics)
      tics%minor = MINOR_AUTO
      if (present(intervals)) tics%minor = max(0_I4P, intervals)
   endassociate
   endsubroutine set_mytics

   subroutine set_my2tics(self, intervals)
   !< Minor second y ticks, as gnuplot `set my2tics [N]`: `intervals` between consecutive major ticks of the automatic or
   !< fixed ticks (linearly in value on a log axis), gnuplot's count without it (2 or 5 by the step, 9 on log axes); 0 or
   !< 1 for none, as `unset my2tics`.
   class(figure_object), intent(inout)        :: self      !< Figure.
   integer(I4P),         intent(in), optional :: intervals !< Intervals between major ticks.

   call self%ensure_panels
   associate(tics => self%panels(self%current)%y2axis%tics)
      tics%minor = MINOR_AUTO
      if (present(intervals)) tics%minor = max(0_I4P, intervals)
   endassociate
   endsubroutine set_my2tics

   subroutine set_mx2tics(self, intervals)
   !< Minor second x ticks, as gnuplot `set mx2tics [N]`: `intervals` between consecutive major ticks of the automatic or
   !< fixed ticks (linearly in value on a log axis), gnuplot's count without it (2 or 5 by the step, 9 on log axes); 0 or
   !< 1 for none, as `unset mx2tics`.
   class(figure_object), intent(inout)        :: self      !< Figure.
   integer(I4P),         intent(in), optional :: intervals !< Intervals between major ticks.

   call self%ensure_panels
   associate(tics => self%panels(self%current)%x2axis%tics)
      tics%minor = MINOR_AUTO
      if (present(intervals)) tics%minor = max(0_I4P, intervals)
   endassociate
   endsubroutine set_mx2tics

   subroutine set_mcbtics(self, intervals)
   !< Minor color box ticks, as gnuplot `set mcbtics [N]`: `intervals` between consecutive major ticks of the automatic or
   !< fixed ticks (linearly in value on a log axis), gnuplot's count without it (2 or 5 by the step, 9 on log axes); 0 or
   !< 1 for none, as `unset mcbtics`.
   class(figure_object), intent(inout)        :: self      !< Figure.
   integer(I4P),         intent(in), optional :: intervals !< Intervals between major ticks.

   call self%ensure_panels
   associate(tics => self%panels(self%current)%cbaxis%tics)
      tics%minor = MINOR_AUTO
      if (present(intervals)) tics%minor = max(0_I4P, intervals)
   endassociate
   endsubroutine set_mcbtics

   subroutine set_ylabel(self, label)
   !< Set the y axis label of the current panel, empty for none.
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: label !< Label.

   call self%ensure_panels
   self%panels(self%current)%yaxis%label = label
   endsubroutine set_ylabel

   subroutine set_yrange(self, min, max)
   !< Set the y range as gnuplot `set yrange [min:max]`: an absent end is autoscaled, `min > max` reverses the axis.
   class(figure_object), intent(inout)        :: self !< Figure.
   real(R8P),            intent(in), optional :: min  !< Value at the axis start.
   real(R8P),            intent(in), optional :: max  !< Value at the axis end.

   call self%ensure_panels
   call self%panels(self%current)%yaxis%set_range(min=min, max=max)
   endsubroutine set_yrange

   subroutine set_ytics(self, step, start, end, mirror, positions, labels, minor, add, out)
   !< y ticks every `step` from `start` to `end` (both optional), as gnuplot `set ytics START,STEP,END`; automatic
   !< without `step`. On a log axis the step is a factor (> 1): ticks at start * step**k. `mirror` false draws them on
   !< the left border only (gnuplot `nomirror`), leaving the right one to the second y axis.
   !< `positions` is an explicit list, labelled by `labels` (as written, or a format with a conversion; the axis
   !< labels without them), `minor` marking minor ticks; `add` adds it to the ticks instead of replacing them,
   !< as gnuplot `set ytics [add] ("label" pos level, ...)`.
   !< `out` points the ticks outward (gnuplot `out`); `rotate` turns the labels [deg, counterclockwise] from their tick,
   !< reading away from the plot, left-justified unless `justify` (gnuplot `rotate by A`; `rotate` is 90); alone they
   !< keep the tick positions.
   class(figure_object), intent(inout)        :: self   !< Figure.
   real(R8P),            intent(in), optional :: step   !< Tick step, a factor on log axes.
   real(R8P),            intent(in), optional :: start  !< First tick.
   real(R8P),            intent(in), optional :: end    !< Last tick.
   logical,              intent(in), optional :: mirror !< Ticks also on the right border.
   real(R8P),            intent(in), optional :: positions(:) !< Explicit list positions, gnuplot `("label" pos, ...)`.
   character(len=*),     intent(in), optional :: labels(:)    !< Explicit list labels (a format if with a conversion).
   logical,              intent(in), optional :: minor(:)     !< Explicit list minor ticks (gnuplot level 1).
   logical,              intent(in), optional :: add          !< Add the list to the ticks (gnuplot `add`).
   logical,              intent(in), optional :: out          !< Ticks outward, gnuplot `out`.

   call self%ensure_panels
   call set_tics(self%panels(self%current)%yaxis%tics, 'set_ytics', step, start, end, mirror, positions, labels, minor, &
                 add, out=out)
   endsubroutine set_ytics

   subroutine set_y2label(self, label)
   !< Set the second y axis label of the current panel, on the right, empty for none.
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: label !< Label.

   call self%ensure_panels
   self%panels(self%current)%y2axis%label = label
   endsubroutine set_y2label

   subroutine set_y2range(self, min, max)
   !< Set the second y axis range as gnuplot `set y2range [min:max]`: an absent end is autoscaled on the `x1y2` series.
   class(figure_object), intent(inout)        :: self !< Figure.
   real(R8P),            intent(in), optional :: min  !< Value at the axis start.
   real(R8P),            intent(in), optional :: max  !< Value at the axis end.

   call self%ensure_panels
   call self%panels(self%current)%y2axis%set_range(min=min, max=max)
   endsubroutine set_y2range

   subroutine set_y2tics(self, step, start, end, mirror, positions, labels, minor, add, out)
   !< Ticks and labels of the second y axis on the right border, as gnuplot `set y2tics START,STEP,END` (automatic
   !< without `step`); off by default, as in gnuplot. `mirror` true draws the ticks on the left border too.
   !< `positions` is an explicit list, labelled by `labels` (as written, or a format with a conversion; the axis
   !< labels without them), `minor` marking minor ticks; `add` adds it to the ticks instead of replacing them,
   !< as gnuplot `set y2tics [add] ("label" pos level, ...)`.
   !< `out` points the ticks outward (gnuplot `out`); alone it keeps the tick positions.
   class(figure_object), intent(inout)        :: self   !< Figure.
   real(R8P),            intent(in), optional :: step   !< Tick step, a factor on log axes.
   real(R8P),            intent(in), optional :: start  !< First tick.
   real(R8P),            intent(in), optional :: end    !< Last tick.
   logical,              intent(in), optional :: mirror !< Ticks also on the left border.
   real(R8P),            intent(in), optional :: positions(:) !< Explicit list positions, gnuplot `("label" pos, ...)`.
   character(len=*),     intent(in), optional :: labels(:)    !< Explicit list labels (a format if with a conversion).
   logical,              intent(in), optional :: minor(:)     !< Explicit list minor ticks (gnuplot level 1).
   logical,              intent(in), optional :: add          !< Add the list to the ticks (gnuplot `add`).
   logical,              intent(in), optional :: out          !< Ticks outward, gnuplot `out`.

   call self%ensure_panels
   call set_tics(self%panels(self%current)%y2axis%tics, 'set_y2tics', step, start, end, mirror, positions, labels, minor, &
                 add, out=out)
   endsubroutine set_y2tics

   subroutine set_x2label(self, label)
   !< Set the second x axis label of the current panel, on the top, empty for none.
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: label !< Label.

   call self%ensure_panels
   self%panels(self%current)%x2axis%label = label
   endsubroutine set_x2label

   subroutine set_x2range(self, min, max)
   !< Set the second x axis range as gnuplot `set x2range [min:max]`: an absent end is autoscaled on the `x2y1` and
   !< `x2y2` series (the range of the first x axis without them).
   class(figure_object), intent(inout)        :: self !< Figure.
   real(R8P),            intent(in), optional :: min  !< Value at the axis start.
   real(R8P),            intent(in), optional :: max  !< Value at the axis end.

   call self%ensure_panels
   call self%panels(self%current)%x2axis%set_range(min=min, max=max)
   endsubroutine set_x2range

   subroutine set_x2tics(self, step, start, end, mirror, positions, labels, minor, add, out, rotate, justify)
   !< Ticks and labels of the second x axis on the top border, as gnuplot `set x2tics START,STEP,END` (automatic without
   !< `step`); off by default, as in gnuplot. Without series of its own the axis spans the first x axis range.
   !< `mirror` true draws the ticks on the bottom border too. `positions` is an explicit list, labelled by `labels` (as
   !< written, or a format with a conversion; the axis labels without them), `minor` marking minor ticks; `add` adds it
   !< to the ticks instead of replacing them, as gnuplot `set x2tics [add] ("label" pos level, ...)`.
   !< `out` points the ticks outward (gnuplot `out`); alone it keeps the tick positions.
   class(figure_object), intent(inout)        :: self   !< Figure.
   real(R8P),            intent(in), optional :: step   !< Tick step, a factor on log axes.
   real(R8P),            intent(in), optional :: start  !< First tick.
   real(R8P),            intent(in), optional :: end    !< Last tick.
   logical,              intent(in), optional :: mirror !< Ticks also on the bottom border.
   real(R8P),            intent(in), optional :: positions(:) !< Explicit list positions, gnuplot `("label" pos, ...)`.
   character(len=*),     intent(in), optional :: labels(:)    !< Explicit list labels (a format if with a conversion).
   logical,              intent(in), optional :: minor(:)     !< Explicit list minor ticks (gnuplot level 1).
   logical,              intent(in), optional :: add          !< Add the list to the ticks (gnuplot `add`).
   logical,              intent(in), optional :: out          !< Ticks outward, gnuplot `out`.
   real(R8P),            intent(in), optional :: rotate       !< Label angle [deg, counterclockwise], gnuplot `rotate by`.
   character(len=*),     intent(in), optional :: justify      !< Rotated label justification: left, right, center.

   call self%ensure_panels
   call set_tics(self%panels(self%current)%x2axis%tics, 'set_x2tics', step, start, end, mirror, positions, labels, minor, &
                 add, rotate=rotate, justify=justify, out=out)
   endsubroutine set_x2tics

   subroutine unset_logscale(self, axes)
   !< Linear scale on the `axes` named `x`, `y`, `y2`, `cb`; all axes when absent, as gnuplot.
   class(figure_object), intent(inout)        :: self     !< Figure.
   character(len=*),     intent(in), optional :: axes     !< Axes names, e.g. `y`, `xy` or `y2`.
   logical                                    :: named(5) !< x, y, y2, cb, x2 named.

   named = which_axes(axes, 'unset_logscale')
   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (named(1)) panel%xaxis%log = .false.
      if (named(2)) panel%yaxis%log = .false.
      if (named(3)) panel%y2axis%log = .false.
      if (named(4)) panel%cbaxis%log = .false.
      if (named(5)) panel%x2axis%log = .false.
   endassociate
   endsubroutine unset_logscale

   subroutine unset_multiplot(self)
   !< Back to a single panel, keeping the settings of the current one without its series.
   class(figure_object), intent(inout) :: self     !< Figure.
   type(axes_object)                   :: settings !< Current panel without its series.

   call self%ensure_panels
   settings = self%panels(self%current)
   if (allocated(settings%series)) deallocate(settings%series)
   deallocate(self%panels)
   allocate(self%panels(1))
   self%panels(1) = settings
   self%rows = 1_I4P
   self%cols = 1_I4P
   self%current = 1_I4P
   self%layout = .false.
   self%manual = .false.
   self%title = ''
   endsubroutine unset_multiplot

   subroutine unset_xtics(self)
   !< No x ticks, tick labels nor grid lines, as gnuplot `unset xtics`; autoscaled ends are then not extended.
   class(figure_object), intent(inout) :: self !< Figure.

   call self%ensure_panels
   call self%panels(self%current)%xaxis%tics%disable
   endsubroutine unset_xtics

   subroutine unset_ytics(self)
   !< No y ticks, tick labels nor grid lines, as gnuplot `unset ytics`; autoscaled ends are then not extended.
   class(figure_object), intent(inout) :: self !< Figure.

   call self%ensure_panels
   call self%panels(self%current)%yaxis%tics%disable
   endsubroutine unset_ytics

   subroutine unset_y2tics(self)
   !< No second y axis ticks nor tick labels, the default, as gnuplot `unset y2tics`.
   class(figure_object), intent(inout) :: self !< Figure.

   call self%ensure_panels
   call self%panels(self%current)%y2axis%tics%disable
   endsubroutine unset_y2tics

   subroutine unset_x2tics(self)
   !< No second x axis ticks nor tick labels, the default, as gnuplot `unset x2tics`.
   class(figure_object), intent(inout) :: self !< Figure.

   call self%ensure_panels
   call self%panels(self%current)%x2axis%tics%disable
   endsubroutine unset_x2tics

   ! private procedures
   subroutine environment_theme(self)
   !< The theme named by the environment variable `FORESIGHT_THEME` (see foresight_theme), as gnuplot's `GNUTERM`
   !< names a default terminal: for a fresh figure, unless a theme was set; an unknown name is ignored.
   class(figure_object), intent(inout) :: self   !< Figure.
   character(len=32)                   :: name   !< Theme name.
   integer(I4P)                        :: status !< Variable status: 0 when set and fitting.

   if (self%theme_chosen) return
   call get_environment_variable('FORESIGHT_THEME', name, status=status)
   if (status /= 0_I4P .or. len_trim(name) == 0) return
   if (index(' '//THEMES//' ', ' '//trim(name)//' ') == 0) return
   self%theme = theme_named(trim(name))
   endsubroutine environment_theme

   subroutine ensure_panels(self)
   !< Allocate the single default panel of a fresh figure.
   class(figure_object), intent(inout) :: self !< Figure.

   if (allocated(self%panels)) return
   call self%environment_theme
   allocate(self%panels(1))
   ! associate alias: see the gfortran 16 -fcheck=bounds workaround in clear
   associate(panel => self%panels(1))
      call panel%set_defaults
   endassociate
   self%rows = 1_I4P
   self%cols = 1_I4P
   self%current = 1_I4P
   if (.not. allocated(self%title)) self%title = ''
   endsubroutine ensure_panels

   subroutine render(self, backend, file)
   !< Render the figure on `backend`, writing `file`: the multiplot title on top, panels in grid cells of a layout or
   !< else in their `origin`/`size` boxes; in a multiplot the panels never plotted stay blank, as in gnuplot.
   class(figure_object),  intent(inout) :: self    !< Figure.
   class(backend_object), intent(inout) :: backend !< Output device.
   character(len=*),      intent(in)    :: file    !< Output file.
   real(R8P)                            :: top     !< Top of the panels placed by origin and size [px].
   real(R8P)                            :: layout_top !< Top of the layout's grid [px].
   real(R8P)                            :: cell(2) !< Grid cell width and height [px].
   integer(I4P)                         :: p       !< Panel counter.
   integer(I4P)                         :: rc(2)   !< Row and column of a panel's cell, from 0.
   real(R8P)                            :: page(2) !< Page width and height [px] (a variable: no argument temporary).

   backend%enhanced = self%enhanced
   backend%latin1 = self%latin1
   backend%text_size = self%font_size
   backend%page_family = self%font_family
   call backend%begin_page(file, self%width, self%height, self%font_size)
   page = [self%width, self%height]
   call backend%rect(0.0_R8P, 0.0_R8P, self%width, self%height, 'none', 'white', 0.0_R8P)
   top = 0.0_R8P
   layout_top = 0.0_R8P
   if (len(self%title) > 0) then
      ! lines apart at each new line (`"a\nb"`, a last one empty included), as gnuplot
      block
         integer(I4P) :: a    !< Line start.
         integer(I4P) :: e    !< Line end.
         integer(I4P) :: line !< Line counter.
         real(R8P)    :: size !< Title font size [px] (a text device: the page's).

         size = self%font_size
         if (.not. backend%row_height() > 0.0_R8P) size = self%title_font%size_px(self%font_size)
         a = 1_I4P
         line = 0_I4P
         do
            e = index(self%title(a:), new_line('a'), kind=I4P)
            if (e == 0_I4P) then
               e = len(self%title, kind=I4P)
            else
               e = a + e - 2_I4P
            endif
            backend%font = self%title_font
            if (e >= a) call backend%text(0.5_R8P * self%width, PAD + size + real(line, R8P) * LINE_HEIGHT * size, &
                                          self%title(a:e), 'middle')
            backend%font = font_object()
            line = line + 1_I4P
            a = e + 2_I4P
            if (a > len(self%title, kind=I4P) + 1_I4P) exit
         enddo
         top = PAD + real(line, R8P) * LINE_HEIGHT * size + GAP
         ! a layout's cells below gnuplot's band (mp_layout_size_and_offset): the title's lines, a character height
         ! (1.5 font sizes) each; panels placed by origin and size keep foresight's room (a documented difference)
         layout_top = top
         if (.not. backend%row_height() > 0.0_R8P) layout_top = real(line, R8P) * 1.5_R8P * size
      endblock
   endif
   cell = [self%width / real(self%cols, R8P), (self%height - layout_top) / real(self%rows, R8P)]
   do p = 1_I4P, size(self%panels, kind=I4P)
      ! associate alias: see the gfortran 16 -fcheck=bounds workaround in clear
      associate(panel => self%panels(p))
         if (size(self%panels) > 1) then
            if (.not. allocated(panel%series)) cycle
         endif
         if (self%gnuplot_labels) then
            ! the scripts' default tick labels: gnuplot's `% h`, each label by %g
            panel%xaxis%tics%per_label = .true.
            panel%yaxis%tics%per_label = .true.
            panel%x2axis%tics%per_label = .true.
            panel%y2axis%tics%per_label = .true.
            panel%cbaxis%tics%per_label = .true.
            panel%raxis%tics%per_label = .true.
            panel%zaxis%tics%per_label = .true.
            ! a vertical key taller than the panel wraps into columns, as gnuplot
            panel%gnuplot_key = .true.
         endif
         if (self%layout .and. .not. panel%layout_own) then
            ! the grid cell of panel p: row by row (or column by column), from the top row (or the bottom one)
            if (self%columns_first) then
               rc = [modulo(p - 1_I4P, self%rows), (p - 1_I4P) / self%rows]
            else
               rc = [(p - 1_I4P) / self%cols, modulo(p - 1_I4P, self%cols)]
            endif
            if (self%upwards) rc(1) = self%rows - 1_I4P - rc(1)
            ! gnuplot's cell (mp_layout_size_and_offset), where a 3D view lies: the title band its lines of gnuplot's
            ! character height
            block
               real(R8P)    :: band !< Title band [page fraction].
               integer(I4P) :: e    !< Character counter.

               band = 0.0_R8P
               if (len(self%title) > 0) band = real(1_I4P + count([(self%title(e:e) == new_line('a'), &
                                                     e = 1_I4P, len(self%title, kind=I4P))]), R8P) * 1.5_R8P * &
                                                     self%title_font%size_px(self%font_size) / self%height
               panel%box3d = [real(rc(2), R8P) / real(self%cols, R8P), &
                              (1.0_R8P - real(rc(1) + 1_I4P, R8P) / real(self%rows, R8P)) * (1.0_R8P - band), &
                              1.0_R8P / real(self%cols, R8P), (1.0_R8P - band) / real(self%rows, R8P)]
            endblock
            if (self%layout_margins(1) >= 0.0_R8P) then
               ! gnuplot `margins` (and `spacing`): the plot area of the cell set at screen fractions, the panel's own
               ! margins kept apart
               block
                  real(R8P) :: kept(4)   !< Panel margins.
                  logical   :: screen(4) !< Panel margins at screen fractions.

                  kept = panel%margin_user
                  screen = panel%margin_screen
                  panel%margin_user = layout_area(rc)
                  panel%margin_screen = .true.
                  call panel%render(backend, real(rc(2), R8P) * cell(1), layout_top + real(rc(1), R8P) * cell(2), cell(1), &
                                    cell(2), self%font_size, canvas=page)
                  panel%margin_user = kept
                  panel%margin_screen = screen
               endblock
            else
               call panel%render(backend, real(rc(2), R8P) * cell(1), layout_top + real(rc(1), R8P) * cell(2), cell(1), &
                                 cell(2), self%font_size, canvas=page)
            endif
         else
            panel%box3d = [panel%origin(1), panel%origin(2), panel%size(1), panel%size(2)]
            ! fractions from the bottom left of the page below the multiplot title, as gnuplot
            call panel%render(backend, panel%origin(1) * self%width, &
                              top + (1.0_R8P - panel%origin(2) - panel%size(2)) * (self%height - top), &
                              panel%size(1) * self%width, panel%size(2) * (self%height - top), self%font_size, &
                              canvas=page)
         endif
      endassociate
   enddo
   call backend%end_page
   contains
      function layout_area(rc) result(m)
      !< Plot area of the layout cell `rc` (row from the top, column) as screen fractions (left, right, top, bottom: the
      !< panel margins at screen), as gnuplot's mp_layout_margins_and_spacing; characters are the page's.
      integer(I4P), intent(in) :: rc(2)  !< Row and column, from 0.
      real(R8P)                :: m(4)   !< Left, right, top, bottom.
      real(R8P)                :: e(4)   !< Left, right, bottom, top edges.
      real(R8P)                :: gap(2) !< Spacing, x and y.
      real(R8P)                :: w      !< Plot area width.
      real(R8P)                :: h      !< Plot area height.
      real(R8P)                :: cx     !< Character width [page fraction].
      real(R8P)                :: cy     !< Character height [page fraction].

      ! gnuplot's svg character cell, 0.7 by 1.5 of the font size
      cx = 0.7_R8P * self%font_size / self%width
      cy = 1.5_R8P * self%font_size / self%height
      e = self%layout_margins
      if (self%layout_chars(1)) e(1) = e(1) * cx
      if (self%layout_chars(2)) e(2) = 1.0_R8P - e(2) * cx
      if (self%layout_chars(3)) e(3) = e(3) * cy
      if (self%layout_chars(4)) e(4) = 1.0_R8P - e(4) * cy
      gap = self%layout_spacing
      if (self%spacing_chars(1)) gap(1) = gap(1) * cx
      if (self%spacing_chars(2)) gap(2) = gap(2) * cy
      w = (e(2) - e(1) - real(self%cols - 1_I4P, R8P) * gap(1)) / real(self%cols, R8P)
      h = (e(4) - e(3) - real(self%rows - 1_I4P, R8P) * gap(2)) / real(self%rows, R8P)
      m(1) = e(1) + real(rc(2), R8P) * (w + gap(1))
      m(2) = m(1) + w
      m(4) = e(3) + real(self%rows - rc(1) - 1_I4P, R8P) * (h + gap(2))
      m(3) = m(4) + h
      endfunction layout_area
   endsubroutine render

   function place(x, y, system, caller) result(p)
   !< The position (`x`, `y`) in `system` (`first` when absent; one word for both coordinates, or two: x then y);
   !< unknown systems stop.
   real(R8P),        intent(in)           :: x      !< Abscissa.
   real(R8P),        intent(in)           :: y      !< Ordinate.
   character(len=*), intent(in), optional :: system !< Coordinate systems.
   character(len=*), intent(in)           :: caller !< Procedure name, for messages.
   type(place_object)                     :: p      !< Position.
   character(len=:), allocatable          :: words  !< Systems.
   integer(I4P)                           :: k      !< Blank position.

   p%x = x
   p%y = y
   if (.not. present(system)) return
   words = trim(adjustl(system))
   k = index(words, ' ', kind=I4P)
   if (k == 0_I4P) then
      p%sx = words
      p%sy = words
   else
      p%sx = words(1:k - 1_I4P)
      p%sy = trim(adjustl(words(k + 1_I4P:)))
   endif
   if (all(p%sx /= ['first    ', 'second   ', 'graph    ', 'screen   ', 'character']) .or. &
       all(p%sy /= ['first    ', 'second   ', 'graph    ', 'screen   ', 'character'])) &
      error stop 'foresight: '//caller//': coordinate systems are first, second, graph, screen or character, not "'// &
                 system//'"'
   endfunction place

   function which_axes(axes, caller) result(named)
   !< Axes named in `axes` (`x`, `y`, `y2`, `cb`, `x2`, concatenated), all when absent; unsupported names stop.
   character(len=*), intent(in), optional :: axes     !< Axes names.
   character(len=*), intent(in)           :: caller   !< Procedure name, for messages.
   logical                                :: named(5) !< x, y, y2, cb, x2 named.
   character(len=:), allocatable          :: bad      !< Unsupported name.

   named = .true.
   if (.not. present(axes)) return
   named = .false.
   call axes_names(axes, named(1), named(2), named(3), bad, cb=named(4), x2=named(5))
   if (len(bad) > 0 .or. len(axes) == 0) error stop 'foresight: '//caller//': axes must be among x, y, y2, cb, x2, '// &
                                                    'not "'//axes//'"'
   endfunction which_axes

   pure function extension(file) result(ext)
   !< Lower case extension of `file`, empty if none.
   character(len=*), intent(in)  :: file !< File name.
   character(len=:), allocatable :: ext  !< Extension.
   integer(I4P)                  :: dot  !< Position of the last dot.
   integer(I4P)                  :: i    !< Counter.

   dot = index(file, '.', back=.true., kind=I4P)
   ext = ''
   if (dot == 0_I4P) return
   ext = file(dot + 1_I4P:)
   do i = 1_I4P, len(ext, kind=I4P)
      if (ext(i:i) >= 'A' .and. ext(i:i) <= 'Z') ext(i:i) = achar(iachar(ext(i:i)) + 32)
   enddo
   endfunction extension

   subroutine set_tics(tics, caller, step, start, end, mirror, positions, labels, minor, add, rotate, justify, out)
   !< Fixed ticks from real settings, or automatic ones without `step`; invalid settings stop. `mirror` alone (no
   !< step, start, end) keeps the tick positions, as gnuplot `set xtics nomirror`, turning off ticks on at their last
   !< positions. `positions` is an explicit list (gnuplot `set xtics ("label" pos level, ...)`), with `labels` (each
   !< printed as written, a format if it has a conversion; the axis labels without them) and `minor` (level 1);
   !< `add` adds the list to the ticks, or a step to the list, instead of replacing them. `rotate` turns the labels by
   !< that angle [deg, counterclockwise; 0 upright], `justify` (`left`, `right`, `center`) anchors them (left by
   !< default, gnuplot `rotate by`), `out` points the ticks outward; alone, like `mirror`, they keep the positions.
   type(tics_object),   intent(inout)        :: tics         !< Axis tick settings.
   character(len=*),    intent(in)           :: caller       !< Procedure name, for messages.
   real(R8P),           intent(in), optional :: step         !< Tick step.
   real(R8P),           intent(in), optional :: start        !< First tick.
   real(R8P),           intent(in), optional :: end          !< Last tick.
   logical,             intent(in), optional :: mirror       !< Ticks also on the opposite border.
   real(R8P),           intent(in), optional :: positions(:) !< Explicit list positions.
   character(len=*),    intent(in), optional :: labels(:)    !< Explicit list labels.
   logical,             intent(in), optional :: minor(:)     !< Explicit list minor ticks.
   logical,             intent(in), optional :: add          !< Add to the ticks.
   real(R8P),           intent(in), optional :: rotate       !< Label angle [deg, counterclockwise].
   character(len=*),    intent(in), optional :: justify      !< Rotated label justification.
   logical,             intent(in), optional :: out          !< Ticks outward.
   type(tic_item), allocatable               :: items(:)     !< Explicit list.
   character(len=:), allocatable             :: first        !< Start text.
   character(len=:), allocatable             :: last         !< End text.
   character(len=:), allocatable             :: message      !< Problem.
   logical                                   :: adding       !< Add to the ticks.
   integer(I4P)                              :: k            !< Item counter.

   adding = .false.
   if (present(add)) adding = add
   if (present(rotate)) then
      tics%rotate = rotate
      tics%justify = ''
   endif
   if (present(justify)) then
      if (.not. any(trim(justify) == ['left  ', 'right ', 'center'])) &
         error stop 'foresight: '//caller//': justify must be left, right or center, not "'//trim(justify)//'"'
      tics%justify = trim(justify)
   endif
   if (present(out)) tics%out = out
   if ((present(rotate) .or. present(justify) .or. present(out)) .and. .not. (present(step) .or. present(start) .or. &
       present(end) .or. present(positions))) then
      if (present(mirror)) tics%mirror = mirror
      call tics%enable
      return
   endif
   if (present(positions)) then
      if (present(step) .or. present(start) .or. present(end)) &
         error stop 'foresight: '//caller//': positions and a step together (set them apart, with add)'
      if (present(labels)) then
         if (size(labels) /= size(positions)) error stop 'foresight: '//caller//': labels and positions differ in size'
      endif
      if (present(minor)) then
         if (size(minor) /= size(positions)) error stop 'foresight: '//caller//': minor and positions differ in size'
      endif
      allocate(items(size(positions)))
      do k = 1_I4P, size(positions, kind=I4P)
         items(k)%value = positions(k)
         items(k)%label = ''
         if (present(labels)) then
            items(k)%labelled = .true.
            items(k)%label = trim(labels(k))
         endif
         if (present(minor)) items(k)%major = .not. minor(k)
      enddo
      call tics%set_list(items, adding)
      if (present(mirror)) tics%mirror = mirror
      return
   endif
   if (present(labels) .or. present(minor)) error stop 'foresight: '//caller//': labels and minor need positions'
   if (present(mirror)) then
      tics%mirror = mirror
      if (.not. (present(step) .or. present(start) .or. present(end))) then
         call tics%enable
         return
      endif
   endif
   if (.not. present(step)) then
      if (present(start) .or. present(end)) error stop 'foresight: '//caller//': start and end need a step'
      if (adding) then
         call tics%enable
      else
         call tics%set_auto
      endif
      return
   endif
   if (.not. adding) call tics%clear_list
   first = ''
   last = ''
   if (present(start)) first = real_str(start)
   if (present(end)) last = real_str(end)
   call tics%set_fixed(real_str(step), first, last, message)
   if (len(message) > 0) error stop 'foresight: '//caller//': '//message
   endsubroutine set_tics
   pure function has_region(words) result(has)
   !< Whether the key position `words` name a region (`inside`, `outside`, a margin, `below`, `above`): they cancel
   !< `set key at`, as gnuplot.
   character(len=*), intent(in) :: words !< Position words.
   logical                      :: has   !< A region is named.
   character(len=*), parameter  :: REGIONS(16) = [character(len=7) :: 'inside', 'ins', 'outside', 'out', 'lmargin', &
                                                  'lm', 'rmargin', 'rm', 'tmargin', 'tm', 'bmargin', 'bm', 'below', &
                                                  'under', 'above', 'over'] !< Region words.
   integer(I4P)                 :: k     !< Counter.

   has = .false.
   do k = 1_I4P, size(REGIONS, kind=I4P)
      has = has .or. index(' '//words//' ', ' '//trim(REGIONS(k))//' ') > 0
   enddo
   endfunction has_region
endmodule foresight_figure
