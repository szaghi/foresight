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
use foresight_axes, only : axes_names, axes_object, boxplot_words, key_position, polar_series, readout_position, &
                           POLAR_STYLES
use foresight_backend, only : backend_object
use foresight_backend_block, only : backend_block, BLOCK_CHARSETS
use foresight_backend_dumb, only : backend_dumb, TEXT_COLORS
use foresight_backend_html, only : backend_html
use foresight_backend_svg, only : backend_svg
use foresight_format, only : format_check, real_str
use foresight_style, only : fill_style
use foresight_theme, only : theme_named, theme_object, THEMES
use foresight_palette, only : palette_words
use foresight_ticks, only : tics_object, TICS_NONE
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
   integer(I4P)                   :: refresh      = 0_I4P     !< HTML page reload period [s], 0 for none.
   logical                        :: clear_screen = .false.   !< Clear the terminal before text output (live view).
   character(len=9)               :: text_charset = 'dumb'    !< Text output: `dumb` characters, or the block
                                                              !< character set `half`, `quadrants`, `sextants`,
                                                              !< `braille` (gnuplot `block` terminal).
   character(len=7)               :: text_colors  = 'mono'    !< Text output colors: `mono`, `ansi`, `ansi256`,
                                                              !< `ansirgb`.
   type(theme_object)             :: theme                    !< Output theme (foresight_theme), `classic` by default.
   integer(I4P)                   :: rows         = 1_I4P     !< Panel grid rows.
   integer(I4P)                   :: cols         = 1_I4P     !< Panel grid columns.
   integer(I4P)                   :: current      = 1_I4P     !< Current panel, filled row by row.
   logical                        :: layout       = .false.   !< Multiplot grid: panels in cells, else in their
                                                              !< `origin`/`size` boxes (single plot, manual multiplot).
   logical                        :: manual       = .false.   !< Manual multiplot: panels added on demand.
   character(len=:), allocatable  :: title                    !< Multiplot title, empty for none.
   type(axes_object), allocatable :: panels(:)                !< Plot panels.
   contains
      procedure, pass(self) :: clear           !< Remove the series of the current panel, keeping the settings.
      procedure, pass(self) :: image           !< gnuplot `plot ... with image`, a grid of values.
      procedure, pass(self) :: rgbimage        !< gnuplot `plot ... with rgbimage|rgbalpha`, a grid of colors.
      procedure, pass(self) :: init            !< Reset the figure, optionally resizing it.
      procedure, pass(self) :: next_panel      !< Move to the next multiplot panel, carrying the settings over.
      procedure, pass(self) :: plot            !< gnuplot `plot`, one series per call.
      procedure, pass(self) :: save            !< Render to a file; the format follows the extension.
      procedure, pass(self) :: set_angles      !< gnuplot `set angles`.
      procedure, pass(self) :: set_border      !< gnuplot `set border` / `unset border`.
      procedure, pass(self) :: set_boxwidth    !< gnuplot `set boxwidth`.
      procedure, pass(self) :: set_cblabel     !< gnuplot `set cblabel`.
      procedure, pass(self) :: set_cbrange     !< gnuplot `set cbrange`.
      procedure, pass(self) :: set_colorbox    !< gnuplot `set colorbox` / `unset colorbox`.
      procedure, pass(self) :: set_format      !< gnuplot `set format`.
      procedure, pass(self) :: set_grid        !< gnuplot `set grid` / `unset grid`.
      procedure, pass(self) :: set_key         !< gnuplot `set key` / `unset key`.
      procedure, pass(self) :: set_logscale    !< gnuplot `set logscale`.
      procedure, pass(self) :: set_multiplot   !< gnuplot `set multiplot layout rows,cols title "..."`.
      procedure, pass(self) :: set_origin      !< gnuplot `set origin`.
      procedure, pass(self) :: set_palette     !< gnuplot `set palette`.
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
      procedure, pass(self) :: set_text        !< Text output: gnuplot `dumb` or `block` terminal, colors.
      procedure, pass(self) :: set_theme       !< Output theme: classic, vfd, lcd; glow.
      procedure, pass(self) :: set_theta       !< gnuplot `set theta`.
      procedure, pass(self) :: set_title       !< gnuplot `set title`.
      procedure, pass(self) :: set_trange      !< gnuplot `set trange`.
      procedure, pass(self) :: set_ttics       !< gnuplot `set ttics` / `unset ttics`.
      procedure, pass(self) :: set_xlabel      !< gnuplot `set xlabel`.
      procedure, pass(self) :: set_xrange      !< gnuplot `set xrange`.
      procedure, pass(self) :: set_xtics       !< gnuplot `set xtics`.
      procedure, pass(self) :: set_ylabel      !< gnuplot `set ylabel`.
      procedure, pass(self) :: set_yrange      !< gnuplot `set yrange`.
      procedure, pass(self) :: set_ytics       !< gnuplot `set ytics`.
      procedure, pass(self) :: set_y2label     !< gnuplot `set y2label`.
      procedure, pass(self) :: set_y2range     !< gnuplot `set y2range`.
      procedure, pass(self) :: set_y2tics      !< gnuplot `set y2tics`.
      procedure, pass(self) :: unset_logscale  !< gnuplot `unset logscale`.
      procedure, pass(self) :: unset_multiplot !< gnuplot `unset multiplot`.
      procedure, pass(self) :: unset_xtics     !< gnuplot `unset xtics`.
      procedure, pass(self) :: unset_ytics     !< gnuplot `unset ytics`.
      procedure, pass(self) :: unset_y2tics    !< gnuplot `unset y2tics`.
      procedure, pass(self), private :: ensure_panels !< Allocate the single default panel if needed.
      procedure, pass(self), private :: render        !< Render on a device.
endtype figure_object

contains
   subroutine clear(self)
   !< Remove the series of the current panel, keeping every setting: a new gnuplot `plot` replaces the previous one.
   class(figure_object), intent(inout) :: self !< Figure.

   call self%ensure_panels
   ! the associate alias works around gfortran 16 -fcheck=bounds crashing on allocated() of a component of an element
   ! of an allocatable array component of a polymorphic dummy
   associate(panel => self%panels(self%current))
      if (allocated(panel%series)) deallocate(panel%series)
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
   self%rows = fresh%rows
   self%cols = fresh%cols
   self%current = fresh%current
   self%layout = fresh%layout
   self%manual = fresh%manual
   self%title = ''
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
   if (self%manual) then
      self%panels = [self%panels, settings]
   elseif (self%current >= size(self%panels, kind=I4P)) then
      error stop 'foresight: next_panel: the multiplot layout is full'
   endif
   self%current = self%current + 1_I4P
   self%panels(self%current) = settings
   endsubroutine next_panel

   subroutine plot(self, x, y, title, with, lc, lw, dt, ps, xlow, xhigh, ylow, yhigh, axes, pt, format, width, base, fs, &
                   xlabels, radius, angles, donut, scale, linear, close, whiskerbars, factors, dx, dy, length, angle, major, &
                   minor, labels, label, head, origins, curve)
   !< Add the series (`x`, `y`) to the current panel, as gnuplot `plot ... title ... with ... lc ... lw ... dt ... ps
   !< ... axes`.
   !<
   !< Error bar styles (`yerrorbars`, `xerrorbars`, `xyerrorbars`) take the bar bounds `ylow`/`yhigh`, `xlow`/`xhigh`.
   !< `axes='x1y2'` plots the series against the second y axis, scaled on its own. `pt` is gnuplot's point type (0 a
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
   character(len=*),     intent(in), optional :: lc       !< Line color (SVG color); default from the gnuplot palette.
   real(R8P),            intent(in), optional :: lw       !< Line width [px].
   integer(I4P),         intent(in), optional :: dt       !< Dash type, 1..5.
   real(R8P),            intent(in), optional :: ps       !< Point size scale factor.
   real(R8P),            intent(in), optional :: xlow(:)  !< Horizontal error bar starts.
   real(R8P),            intent(in), optional :: xhigh(:) !< Horizontal error bar ends.
   real(R8P),            intent(in), optional :: ylow(:)  !< Vertical error bar starts.
   real(R8P),            intent(in), optional :: yhigh(:) !< Vertical error bar ends.
   character(len=*),     intent(in), optional :: axes     !< Axes of the series: `x1y1` (default) or `x1y2`.
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

   call self%ensure_panels
   call self%panels(self%current)%add_series(x, y, title=title, with=with, lc=lc, lw=lw, dt=dt, ps=ps, &
                                             xlow=xlow, xhigh=xhigh, ylow=ylow, yhigh=yhigh, axes=axes, pt=pt, &
                                             format=format, width=width, base=base, fs=fs, xlabels=xlabels, &
                                             radius=radius, angles=angles, donut=donut, scale=scale, linear=linear, &
                                             close=close, whiskerbars=whiskerbars, factors=factors, dx=dx, dy=dy, &
                                             length=length, angle=angle, major=major, minor=minor, labels=labels, &
                                             label=label, head=head, origins=origins, curve=curve)
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

   subroutine set_colorbox(self, on)
   !< Draw the color box of the images (`on` absent or true), as gnuplot `set colorbox`, or not.
   class(figure_object), intent(inout)        :: self !< Figure.
   logical,              intent(in), optional :: on   !< Color box on.

   call self%ensure_panels
   self%panels(self%current)%colorbox = .true.
   if (present(on)) self%panels(self%current)%colorbox = on
   endsubroutine set_colorbox

   subroutine set_palette(self, words)
   !< Palette of the images, as gnuplot `set palette`: `''` (the default, rgbformulae 7,5,15), `'rgbformulae 33,13,10'`,
   !< `'defined (0 "blue", 1 "white", 2 "red")'`, `'gray'`, `'viridis'`, `'negative'`, `'maxcolors 8'`.
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: words !< Palette words.
   character(len=:), allocatable       :: bad   !< Unknown word.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      call palette_words(words, panel%palette, bad)
   endassociate
   if (len(bad) > 0) error stop 'foresight: set_palette: unsupported palette "'//bad//'"'
   endsubroutine set_palette

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

   subroutine set_style_histogram(self, style, gap)
   !< Layout of the histograms plotted next, as gnuplot `set style histogram clustered [gap G]|rowstacked`: `style`
   !< `clustered` (the default) or `rowstacked`; `gap` the space between clusters, in bar widths (2 by default).
   class(figure_object), intent(inout)        :: self  !< Figure.
   character(len=*),     intent(in)           :: style !< `clustered` or `rowstacked`.
   real(R8P),            intent(in), optional :: gap   !< Gap between clusters [bars].

   if (style /= 'clustered' .and. style /= 'rowstacked') &
      error stop 'foresight: set_style_histogram: clustered or rowstacked expected, not "'//style//'"'
   call self%ensure_panels
   associate(panel => self%panels(self%current))
      panel%histogram_rowstacked = style == 'rowstacked'
      if (present(gap)) then
         if (gap < 0.0_R8P) error stop 'foresight: set_style_histogram: the gap must not be negative'
         panel%histogram_gap = gap
      endif
   endassociate
   endsubroutine set_style_histogram

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

   subroutine set_format(self, format, axes)
   !< Tick label `format` of the `axes` named `x`, `y`, `y2` (all when absent), as gnuplot `set format`: text
   !< with one printf conversion `%[flags][width][.precision]` `f`, `e`, `E`, `g`, `G` or `h` (`g` with a `x10`
   !< superscript exponent), e.g. `'%.1e'` or `'%g s'`; an empty format restores the default labels.
   class(figure_object), intent(inout)        :: self    !< Figure.
   character(len=*),     intent(in)           :: format  !< Label format.
   character(len=*),     intent(in), optional :: axes    !< Axes names, e.g. `y`, `xy` or `y2`.
   character(len=:), allocatable              :: message !< Format problem.
   logical                                    :: named(3) !< x, y, y2 named.

   if (len(format) > 0) then
      message = format_check(format)
      if (len(message) > 0) error stop 'foresight: set_format: '//message
   endif
   named = which_axes(axes, 'set_format')
   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (named(1)) panel%xaxis%tics%format = format
      if (named(2)) panel%yaxis%tics%format = format
      if (named(3)) panel%y2axis%tics%format = format
   endassociate
   endsubroutine set_format

   subroutine set_grid(self, on, polar)
   !< Draw grid lines at the major ticks (`on` absent or true), as gnuplot `set grid`, or not. On a polar panel,
   !< `polar` > 0 draws the polar grid instead (gnuplot `set grid polar STEP`): rings at the major r ticks and spokes
   !< every `polar` degrees of theta; 0 restores the rectangular grid.
   class(figure_object), intent(inout)        :: self  !< Figure.
   logical,              intent(in), optional :: on    !< Grid on.
   real(R8P),            intent(in), optional :: polar !< Spoke step [deg], 0 for the rectangular grid.

   call self%ensure_panels
   self%panels(self%current)%grid = .true.
   if (present(on)) self%panels(self%current)%grid = on
   if (present(polar)) then
      if (polar < 0.0_R8P .or. polar >= 360.0_R8P) error stop 'foresight: set_grid: the polar step is 0 to below 360'
      self%panels(self%current)%grid_polar = polar
   endif
   endsubroutine set_grid

   subroutine set_key(self, on, position, box)
   !< Draw the key (`on` absent or true), as gnuplot `set key`, or not; `position` takes gnuplot's words, e.g.
   !< `'bottom left'`, `'center'` (inside the plot area, top right by default), `'outside'`, `'below'`, `'above'`,
   !< `'horizontal'`; `box` draws a box around it.
   class(figure_object), intent(inout)        :: self     !< Figure.
   logical,              intent(in), optional :: on       !< Key on.
   character(len=*),     intent(in), optional :: position !< Position words: left, right, center, top, bottom.
   logical,              intent(in), optional :: box      !< Box around the key.
   character(len=:), allocatable              :: bad      !< Unknown position word.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      panel%key = .true.
      if (present(on)) panel%key = on
      if (present(position)) then
         call key_position(position, panel%key_h, panel%key_v, panel%key_outside, panel%key_margin, &
                           panel%key_horizontal, bad)
         if (len(bad) > 0) error stop 'foresight: set_key: unknown position "'//bad//'"'
      endif
      if (present(box)) panel%key_box = box
   endassociate
   endsubroutine set_key

   subroutine set_logscale(self, axes)
   !< Base-10 log scale on the `axes` named `x`, `y`, `y2`; all axes when absent, as gnuplot.
   class(figure_object), intent(inout)        :: self     !< Figure.
   character(len=*),     intent(in), optional :: axes     !< Axes names, e.g. `y`, `xy` or `y2`.
   logical                                    :: named(3) !< x, y, y2 named.

   named = which_axes(axes, 'set_logscale')
   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (named(1)) panel%xaxis%log = .true.
      if (named(2)) panel%yaxis%log = .true.
      if (named(3)) panel%y2axis%log = .true.
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
   endsubroutine set_multiplot

   subroutine set_origin(self, x, y)
   !< Bottom left corner of the plot as page fractions, as gnuplot `set origin x,y`: for a single plot and the panels
   !< of a manual multiplot (not with a layout).
   class(figure_object), intent(inout) :: self !< Figure.
   real(R8P),            intent(in)    :: x    !< Left side, page width fraction.
   real(R8P),            intent(in)    :: y    !< Bottom side, page height fraction.

   if (self%layout) error stop 'foresight: set_origin: not with a multiplot layout'
   call self%ensure_panels
   ! associate alias: see the gfortran 16 -fcheck=bounds workaround in clear
   associate(panel => self%panels(self%current))
      panel%origin = [x, y]
   endassociate
   endsubroutine set_origin

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
   !< Size of the plot as page fractions, as gnuplot `set size w,h`: for a single plot and the panels of a manual
   !< multiplot (not with a layout). `ratio` > 0 fixes the plot area height over width (gnuplot `set size ratio R`,
   !< `square` is 1), 0 frees it (`noratio`).
   class(figure_object), intent(inout)        :: self   !< Figure.
   real(R8P),            intent(in), optional :: width  !< Width, page width fraction, > 0.
   real(R8P),            intent(in), optional :: height !< Height, page height fraction, > 0.
   real(R8P),            intent(in), optional :: ratio  !< Plot area height over width, 0 for none.

   if (present(width) .neqv. present(height)) error stop 'foresight: set_size: width and height go together'
   if (present(width)) then
      if (self%layout) error stop 'foresight: set_size: not with a multiplot layout'
      if (width <= 0.0_R8P .or. height <= 0.0_R8P) error stop 'foresight: set_size: the size must be positive'
   endif
   if (present(ratio)) then
      if (ratio < 0.0_R8P) error stop 'foresight: set_size: the ratio must not be negative'
   endif
   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (present(width)) panel%size = [width, height]
      if (present(ratio)) panel%ratio = ratio
   endassociate
   endsubroutine set_size

   subroutine set_theme(self, name, glow)
   !< Output theme (a foresight extension): `name` `classic` (the default), `vfd` (a vacuum fluorescent display: black
   !< glass, emissive colors, glowing data) or `lcd` (a backlit liquid crystal display); `glow` overrides the theme's
   !< glow (on in `vfd`). Text output takes the theme colors of the series only (`ansi` colors).
   class(figure_object), intent(inout)        :: self !< Figure.
   character(len=*),     intent(in), optional :: name !< Theme name.
   logical,              intent(in), optional :: glow !< Glowing data.

   if (present(name)) then
      if (index(' '//THEMES//' ', ' '//trim(name)//' ') == 0) &
         error stop 'foresight: set_theme: unknown theme "'//trim(name)//'" (supported: '//THEMES//')'
      self%theme = theme_named(name)
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

   subroutine set_title(self, title)
   !< Set the title of the current panel, empty for none.
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: title !< Title.

   call self%ensure_panels
   self%panels(self%current)%title = title
   endsubroutine set_title

   subroutine set_trange(self, min, max)
   !< Angle range the script functions of a polar panel are sampled over, as gnuplot `set trange [min:max]` (in
   !< `set_angles` units; a full turn from 0 when absent).
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

   subroutine set_xtics(self, step, start, end, mirror)
   !< x ticks every `step` from `start` to `end` (both optional), as gnuplot `set xtics START,STEP,END`; automatic
   !< without `step`. On a log axis the step is a factor (> 1): ticks at start * step**k. `mirror` false draws them on
   !< the bottom border only (gnuplot `nomirror`).
   class(figure_object), intent(inout)        :: self   !< Figure.
   real(R8P),            intent(in), optional :: step   !< Tick step, a factor on log axes.
   real(R8P),            intent(in), optional :: start  !< First tick.
   real(R8P),            intent(in), optional :: end    !< Last tick.
   logical,              intent(in), optional :: mirror !< Ticks also on the top border.

   call self%ensure_panels
   call set_tics(self%panels(self%current)%xaxis%tics, 'set_xtics', step, start, end, mirror)
   endsubroutine set_xtics

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

   subroutine set_ytics(self, step, start, end, mirror)
   !< y ticks every `step` from `start` to `end` (both optional), as gnuplot `set ytics START,STEP,END`; automatic
   !< without `step`. On a log axis the step is a factor (> 1): ticks at start * step**k. `mirror` false draws them on
   !< the left border only (gnuplot `nomirror`), leaving the right one to the second y axis.
   class(figure_object), intent(inout)        :: self   !< Figure.
   real(R8P),            intent(in), optional :: step   !< Tick step, a factor on log axes.
   real(R8P),            intent(in), optional :: start  !< First tick.
   real(R8P),            intent(in), optional :: end    !< Last tick.
   logical,              intent(in), optional :: mirror !< Ticks also on the right border.

   call self%ensure_panels
   call set_tics(self%panels(self%current)%yaxis%tics, 'set_ytics', step, start, end, mirror)
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

   subroutine set_y2tics(self, step, start, end, mirror)
   !< Ticks and labels of the second y axis on the right border, as gnuplot `set y2tics START,STEP,END` (automatic
   !< without `step`); off by default, as in gnuplot. `mirror` true draws the ticks on the left border too.
   class(figure_object), intent(inout)        :: self   !< Figure.
   real(R8P),            intent(in), optional :: step   !< Tick step, a factor on log axes.
   real(R8P),            intent(in), optional :: start  !< First tick.
   real(R8P),            intent(in), optional :: end    !< Last tick.
   logical,              intent(in), optional :: mirror !< Ticks also on the left border.

   call self%ensure_panels
   call set_tics(self%panels(self%current)%y2axis%tics, 'set_y2tics', step, start, end, mirror)
   endsubroutine set_y2tics

   subroutine unset_logscale(self, axes)
   !< Linear scale on the `axes` named `x`, `y`, `y2`; all axes when absent, as gnuplot.
   class(figure_object), intent(inout)        :: self     !< Figure.
   character(len=*),     intent(in), optional :: axes     !< Axes names, e.g. `y`, `xy` or `y2`.
   logical                                    :: named(3) !< x, y, y2 named.

   named = which_axes(axes, 'unset_logscale')
   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (named(1)) panel%xaxis%log = .false.
      if (named(2)) panel%yaxis%log = .false.
      if (named(3)) panel%y2axis%log = .false.
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
   self%panels(self%current)%xaxis%tics%mode = TICS_NONE
   endsubroutine unset_xtics

   subroutine unset_ytics(self)
   !< No y ticks, tick labels nor grid lines, as gnuplot `unset ytics`; autoscaled ends are then not extended.
   class(figure_object), intent(inout) :: self !< Figure.

   call self%ensure_panels
   self%panels(self%current)%yaxis%tics%mode = TICS_NONE
   endsubroutine unset_ytics

   subroutine unset_y2tics(self)
   !< No second y axis ticks nor tick labels, the default, as gnuplot `unset y2tics`.
   class(figure_object), intent(inout) :: self !< Figure.

   call self%ensure_panels
   self%panels(self%current)%y2axis%tics%mode = TICS_NONE
   endsubroutine unset_y2tics

   ! private procedures
   subroutine ensure_panels(self)
   !< Allocate the single default panel of a fresh figure.
   class(figure_object), intent(inout) :: self !< Figure.

   if (allocated(self%panels)) return
   allocate(self%panels(1))
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
   real(R8P)                            :: top     !< Top of the panel grid [px].
   real(R8P)                            :: cell(2) !< Grid cell width and height [px].
   integer(I4P)                         :: p       !< Panel counter.

   call backend%begin_page(file, self%width, self%height, self%font_size)
   call backend%rect(0.0_R8P, 0.0_R8P, self%width, self%height, 'none', 'white', 0.0_R8P)
   top = 0.0_R8P
   if (len(self%title) > 0) then
      call backend%text(0.5_R8P * self%width, PAD + self%font_size, self%title, 'middle')
      top = PAD + LINE_HEIGHT * self%font_size + GAP
   endif
   cell = [self%width / real(self%cols, R8P), (self%height - top) / real(self%rows, R8P)]
   do p = 1_I4P, size(self%panels, kind=I4P)
      ! associate alias: see the gfortran 16 -fcheck=bounds workaround in clear
      associate(panel => self%panels(p))
         if (size(self%panels) > 1) then
            if (.not. allocated(panel%series)) cycle
         endif
         if (self%layout) then
            call panel%render(backend, real(modulo(p - 1_I4P, self%cols), R8P) * cell(1), &
                              top + real((p - 1_I4P) / self%cols, R8P) * cell(2), cell(1), cell(2), self%font_size)
         else
            ! fractions from the bottom left of the page below the multiplot title, as gnuplot
            call panel%render(backend, panel%origin(1) * self%width, &
                              top + (1.0_R8P - panel%origin(2) - panel%size(2)) * (self%height - top), &
                              panel%size(1) * self%width, panel%size(2) * (self%height - top), self%font_size)
         endif
      endassociate
   enddo
   call backend%end_page
   endsubroutine render

   function which_axes(axes, caller) result(named)
   !< Axes named in `axes` (`x`, `y`, `y2`, concatenated), all when absent; unsupported names stop.
   character(len=*), intent(in), optional :: axes     !< Axes names.
   character(len=*), intent(in)           :: caller   !< Procedure name, for messages.
   logical                                :: named(3) !< x, y, y2 named.
   character(len=:), allocatable          :: bad      !< Unsupported name.

   named = .true.
   if (.not. present(axes)) return
   named = .false.
   call axes_names(axes, named(1), named(2), named(3), bad)
   if (len(bad) > 0 .or. len(axes) == 0) error stop 'foresight: '//caller//': axes must be among x, y, y2, not "'// &
                                                    axes//'"'
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

   subroutine set_tics(tics, caller, step, start, end, mirror)
   !< Fixed ticks from real settings, or automatic ones without `step`; invalid settings stop. `mirror` alone (no
   !< step, start, end) keeps the tick positions, as gnuplot `set xtics nomirror`, turning off ticks on at their last
   !< positions.
   type(tics_object),   intent(inout)        :: tics    !< Axis tick settings.
   character(len=*),    intent(in)           :: caller  !< Procedure name, for messages.
   real(R8P),           intent(in), optional :: step    !< Tick step.
   real(R8P),           intent(in), optional :: start   !< First tick.
   real(R8P),           intent(in), optional :: end     !< Last tick.
   logical,             intent(in), optional :: mirror  !< Ticks also on the opposite border.
   character(len=:), allocatable             :: first   !< Start text.
   character(len=:), allocatable             :: last    !< End text.
   character(len=:), allocatable             :: message !< Problem.

   if (present(mirror)) then
      tics%mirror = mirror
      if (.not. (present(step) .or. present(start) .or. present(end))) then
         call tics%enable
         return
      endif
   endif
   if (.not. present(step)) then
      if (present(start) .or. present(end)) error stop 'foresight: '//caller//': start and end need a step'
      call tics%set_auto
      return
   endif
   first = ''
   last = ''
   if (present(start)) first = real_str(start)
   if (present(end)) last = real_str(end)
   call tics%set_fixed(real_str(step), first, last, message)
   if (len(message) > 0) error stop 'foresight: '//caller//': '//message
   endsubroutine set_tics
endmodule foresight_figure
