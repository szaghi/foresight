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
use foresight_axes, only : axes_names, axes_object, key_position
use foresight_backend, only : backend_object
use foresight_backend_dumb, only : backend_dumb
use foresight_backend_html, only : backend_html
use foresight_backend_svg, only : backend_svg
use foresight_format, only : format_check, real_str
use foresight_ticks, only : tics_object, TICS_AUTO, TICS_NONE
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
      procedure, pass(self) :: init            !< Reset the figure, optionally resizing it.
      procedure, pass(self) :: next_panel      !< Move to the next multiplot panel, carrying the settings over.
      procedure, pass(self) :: plot            !< gnuplot `plot`, one series per call.
      procedure, pass(self) :: save            !< Render to a file; the format follows the extension.
      procedure, pass(self) :: set_format      !< gnuplot `set format`.
      procedure, pass(self) :: set_grid        !< gnuplot `set grid` / `unset grid`.
      procedure, pass(self) :: set_key         !< gnuplot `set key` / `unset key`.
      procedure, pass(self) :: set_logscale    !< gnuplot `set logscale`.
      procedure, pass(self) :: set_multiplot   !< gnuplot `set multiplot layout rows,cols title "..."`.
      procedure, pass(self) :: set_origin      !< gnuplot `set origin`.
      procedure, pass(self) :: set_refresh     !< HTML page reload period, for live monitoring.
      procedure, pass(self) :: set_size        !< gnuplot `set size`.
      procedure, pass(self) :: set_title       !< gnuplot `set title`.
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

   subroutine plot(self, x, y, title, with, lc, lw, dt, ps, xlow, xhigh, ylow, yhigh, axes)
   !< Add the series (`x`, `y`) to the current panel, as gnuplot `plot ... title ... with ... lc ... lw ... dt ... ps
   !< ... axes`.
   !<
   !< Error bar styles (`yerrorbars`, `xerrorbars`, `xyerrorbars`) take the bar bounds `ylow`/`yhigh`, `xlow`/`xhigh`.
   !< `axes='x1y2'` plots the series against the second y axis, scaled on its own.
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

   call self%ensure_panels
   call self%panels(self%current)%add_series(x, y, title=title, with=with, lc=lc, lw=lw, dt=dt, ps=ps, &
                                             xlow=xlow, xhigh=xhigh, ylow=ylow, yhigh=yhigh, axes=axes)
   endsubroutine plot

   subroutine save(self, file)
   !< Render the figure to `file`; the format follows the name: `.svg` static, `.html` interactive, `.txt` text (the
   !< gnuplot `dumb` terminal), `-` text on standard output.
   class(figure_object), intent(inout) :: self !< Figure.
   character(len=*),     intent(in)    :: file !< Output file.
   type(backend_svg)                   :: svg  !< SVG device.
   type(backend_html)                  :: html !< HTML device.
   type(backend_dumb)                  :: dumb !< Text device.

   call self%ensure_panels
   if (file == '-') then
      dumb%clear_screen = self%clear_screen
      call self%render(dumb, file)
      return
   endif
   select case (extension(file))
   case ('svg')
      call self%render(svg, file)
   case ('html', 'htm')
      html%title = self%title
      if (len(html%title) == 0 .and. allocated(self%panels(1)%title)) html%title = self%panels(1)%title
      html%refresh = self%refresh
      call self%render(html, file)
   case ('txt')
      call self%render(dumb, file)
   case default
      error stop 'foresight: unsupported output format of "'//file//'" (supported: .svg, .html, .txt, -)'
   endselect
   endsubroutine save

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

   subroutine set_grid(self, on)
   !< Draw grid lines at the major ticks (`on` absent or true), as gnuplot `set grid`, or not.
   class(figure_object), intent(inout)        :: self !< Figure.
   logical,              intent(in), optional :: on   !< Grid on.

   call self%ensure_panels
   self%panels(self%current)%grid = .true.
   if (present(on)) self%panels(self%current)%grid = on
   endsubroutine set_grid

   subroutine set_key(self, on, position, box)
   !< Draw the key (`on` absent or true), as gnuplot `set key`, or not; `position` takes gnuplot's words, e.g.
   !< `'bottom left'` or `'center'` (inside the plot area, top right by default); `box` draws a box around it.
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
         call key_position(position, panel%key_h, panel%key_v, bad)
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

   pure subroutine set_refresh(self, seconds)
   !< Make the HTML page reload itself every `seconds` (0 disables): live view of a file rewritten by a running job.
   !<
   !< The zoom survives the reload, being kept in the page URL as data values.
   class(figure_object), intent(inout) :: self    !< Figure.
   integer(I4P),         intent(in)    :: seconds !< Reload period [s].

   self%refresh = max(0_I4P, seconds)
   endsubroutine set_refresh

   subroutine set_size(self, width, height)
   !< Size of the plot as page fractions, as gnuplot `set size w,h`: for a single plot and the panels of a manual
   !< multiplot (not with a layout).
   class(figure_object), intent(inout) :: self   !< Figure.
   real(R8P),            intent(in)    :: width  !< Width, page width fraction, > 0.
   real(R8P),            intent(in)    :: height !< Height, page height fraction, > 0.

   if (self%layout) error stop 'foresight: set_size: not with a multiplot layout'
   if (width <= 0.0_R8P .or. height <= 0.0_R8P) error stop 'foresight: set_size: the size must be positive'
   call self%ensure_panels
   associate(panel => self%panels(self%current))
      panel%size = [width, height]
   endassociate
   endsubroutine set_size

   subroutine set_title(self, title)
   !< Set the title of the current panel, empty for none.
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: title !< Title.

   call self%ensure_panels
   self%panels(self%current)%title = title
   endsubroutine set_title

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
   !< step, start, end) keeps the tick positions, as gnuplot `set xtics nomirror`, turning off ticks on.
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
         if (tics%mode == TICS_NONE) tics%mode = TICS_AUTO
         return
      endif
   endif
   if (.not. present(step)) then
      if (present(start) .or. present(end)) error stop 'foresight: '//caller//': start and end need a step'
      tics%mode = TICS_AUTO
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
