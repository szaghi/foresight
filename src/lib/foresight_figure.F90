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
use foresight_axes, only : axes_object
use foresight_backend, only : backend_object
use foresight_backend_dumb, only : backend_dumb
use foresight_backend_html, only : backend_html
use foresight_backend_svg, only : backend_svg
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
   character(len=:), allocatable  :: title                    !< Multiplot title, empty for none.
   type(axes_object), allocatable :: panels(:)                !< Plot panels.
   contains
      procedure, pass(self) :: clear           !< Remove the series of the current panel, keeping the settings.
      procedure, pass(self) :: init            !< Reset the figure, optionally resizing it.
      procedure, pass(self) :: next_panel      !< Move to the next multiplot panel, carrying the settings over.
      procedure, pass(self) :: plot            !< gnuplot `plot`, one series per call.
      procedure, pass(self) :: save            !< Render to a file; the format follows the extension.
      procedure, pass(self) :: set_grid        !< gnuplot `set grid` / `unset grid`.
      procedure, pass(self) :: set_key         !< gnuplot `set key` / `unset key`.
      procedure, pass(self) :: set_logscale    !< gnuplot `set logscale`.
      procedure, pass(self) :: set_multiplot   !< gnuplot `set multiplot layout rows,cols title "..."`.
      procedure, pass(self) :: set_refresh     !< HTML page reload period, for live monitoring.
      procedure, pass(self) :: set_title       !< gnuplot `set title`.
      procedure, pass(self) :: set_xlabel      !< gnuplot `set xlabel`.
      procedure, pass(self) :: set_xrange      !< gnuplot `set xrange`.
      procedure, pass(self) :: set_ylabel      !< gnuplot `set ylabel`.
      procedure, pass(self) :: set_yrange      !< gnuplot `set yrange`.
      procedure, pass(self) :: unset_logscale  !< gnuplot `unset logscale`.
      procedure, pass(self) :: unset_multiplot !< gnuplot `unset multiplot`.
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
   self%title = ''
   if (allocated(self%panels)) deallocate(self%panels)
   call self%ensure_panels
   if (present(width)) self%width = real(width, R8P)
   if (present(height)) self%height = real(height, R8P)
   if (present(font_size)) self%font_size = font_size
   endsubroutine init

   subroutine next_panel(self)
   !< Move to the next panel of the multiplot grid; the settings of the current panel carry over, as in gnuplot.
   class(figure_object), intent(inout) :: self     !< Figure.
   type(axes_object)                   :: settings !< Current panel without its series.

   call self%ensure_panels
   if (self%current >= size(self%panels, kind=I4P)) error stop 'foresight: next_panel: the multiplot layout is full'
   settings = self%panels(self%current)
   if (allocated(settings%series)) deallocate(settings%series)
   self%current = self%current + 1_I4P
   self%panels(self%current) = settings
   endsubroutine next_panel

   subroutine plot(self, x, y, title, with, lc, lw, dt, ps, xlow, xhigh, ylow, yhigh)
   !< Add the series (`x`, `y`) to the current panel, as gnuplot `plot ... title ... with ... lc ... lw ... dt ... ps`.
   !<
   !< Error bar styles (`yerrorbars`, `xerrorbars`, `xyerrorbars`) take the bar bounds `ylow`/`yhigh`, `xlow`/`xhigh`.
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

   call self%ensure_panels
   call self%panels(self%current)%add_series(x, y, title=title, with=with, lc=lc, lw=lw, dt=dt, ps=ps, &
                                             xlow=xlow, xhigh=xhigh, ylow=ylow, yhigh=yhigh)
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

   subroutine set_grid(self, on)
   !< Draw grid lines at the major ticks (`on` absent or true), as gnuplot `set grid`, or not.
   class(figure_object), intent(inout)        :: self !< Figure.
   logical,              intent(in), optional :: on   !< Grid on.

   call self%ensure_panels
   self%panels(self%current)%grid = .true.
   if (present(on)) self%panels(self%current)%grid = on
   endsubroutine set_grid

   subroutine set_key(self, on)
   !< Draw the key (`on` absent or true), as gnuplot `set key`, or not.
   class(figure_object), intent(inout)        :: self !< Figure.
   logical,              intent(in), optional :: on   !< Key on.

   call self%ensure_panels
   self%panels(self%current)%key = .true.
   if (present(on)) self%panels(self%current)%key = on
   endsubroutine set_key

   subroutine set_logscale(self, axes)
   !< Base-10 log scale on the `axes` named by the letters `x`, `y`; all axes when absent, as gnuplot.
   class(figure_object), intent(inout)        :: self !< Figure.
   character(len=*),     intent(in), optional :: axes !< Axes letters, e.g. `y` or `xy`.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (present(axes)) then
         if (index(axes, 'x') > 0) panel%xaxis%log = .true.
         if (index(axes, 'y') > 0) panel%yaxis%log = .true.
      else
         panel%xaxis%log = .true.
         panel%yaxis%log = .true.
      endif
   endassociate
   endsubroutine set_logscale

   subroutine set_multiplot(self, rows, cols, title)
   !< Lay out a `rows` x `cols` grid of panels, filled row by row starting from the first; every panel starts from the
   !< settings of the current one, without its series.
   class(figure_object), intent(inout)        :: self     !< Figure.
   integer(I4P),         intent(in)           :: rows     !< Grid rows.
   integer(I4P),         intent(in)           :: cols     !< Grid columns.
   character(len=*),     intent(in), optional :: title    !< Multiplot title.
   type(axes_object)                          :: settings !< Current panel without its series.
   integer(I4P)                               :: p        !< Panel counter.

   if (rows < 1_I4P .or. cols < 1_I4P) error stop 'foresight: set_multiplot: the layout needs positive rows and cols'
   call self%ensure_panels
   settings = self%panels(self%current)
   if (allocated(settings%series)) deallocate(settings%series)
   deallocate(self%panels)
   allocate(self%panels(rows * cols))
   do p = 1_I4P, rows * cols
      self%panels(p) = settings
   enddo
   self%rows = rows
   self%cols = cols
   self%current = 1_I4P
   self%title = ''
   if (present(title)) self%title = title
   endsubroutine set_multiplot

   pure subroutine set_refresh(self, seconds)
   !< Make the HTML page reload itself every `seconds` (0 disables): live view of a file rewritten by a running job.
   !<
   !< The zoom survives the reload, being kept in the page URL as data values.
   class(figure_object), intent(inout) :: self    !< Figure.
   integer(I4P),         intent(in)    :: seconds !< Reload period [s].

   self%refresh = max(0_I4P, seconds)
   endsubroutine set_refresh

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

   subroutine unset_logscale(self, axes)
   !< Linear scale on the `axes` named by the letters `x`, `y`; all axes when absent, as gnuplot.
   class(figure_object), intent(inout)        :: self !< Figure.
   character(len=*),     intent(in), optional :: axes !< Axes letters, e.g. `y` or `xy`.

   call self%ensure_panels
   associate(panel => self%panels(self%current))
      if (present(axes)) then
         if (index(axes, 'x') > 0) panel%xaxis%log = .false.
         if (index(axes, 'y') > 0) panel%yaxis%log = .false.
      else
         panel%xaxis%log = .false.
         panel%yaxis%log = .false.
      endif
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
   self%title = ''
   endsubroutine unset_multiplot

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
   !< Render the figure on `backend`, writing `file`: the multiplot title on top, panels in grid cells; in a multiplot
   !< the panels never plotted stay blank, as in gnuplot.
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
         call panel%render(backend, real(modulo(p - 1_I4P, self%cols), R8P) * cell(1), &
                           top + real((p - 1_I4P) / self%cols, R8P) * cell(2), cell(1), cell(2), self%font_size)
      endassociate
   enddo
   call backend%end_page
   endsubroutine render

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
endmodule foresight_figure
