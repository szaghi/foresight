!< foresight_figure, a figure: page, font and plot panel, driven by a gnuplot-like API.
module foresight_figure
!< foresight_figure, a figure: page, font and plot panel, driven by a gnuplot-like API.
!<
!< Every method mirrors a gnuplot command (`plot`, `set title`, `set xrange`, `set logscale`, ...) so that the command
!< line interpreter maps one-to-one onto this API.
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
use foresight_backend_svg, only : backend_svg
use penf, only : I4P, R8P

implicit none
private
public :: figure_object

type :: figure_object
   !< Figure.
   real(R8P)         :: width     = 600.0_R8P !< Page width [px], gnuplot svg terminal default.
   real(R8P)         :: height    = 480.0_R8P !< Page height [px], gnuplot svg terminal default.
   real(R8P)         :: font_size = 12.0_R8P  !< Font size [px].
   type(axes_object) :: axes                  !< Plot panel.
   contains
      procedure, pass(self) :: init            !< Reset the figure, optionally resizing it.
      procedure, pass(self) :: plot            !< gnuplot `plot`, one series per call.
      procedure, pass(self) :: save            !< Render to a file; the format follows the extension.
      procedure, pass(self) :: set_grid        !< gnuplot `set grid` / `unset grid`.
      procedure, pass(self) :: set_key         !< gnuplot `set key` / `unset key`.
      procedure, pass(self) :: set_logscale    !< gnuplot `set logscale`.
      procedure, pass(self) :: set_title       !< gnuplot `set title`.
      procedure, pass(self) :: set_xlabel      !< gnuplot `set xlabel`.
      procedure, pass(self) :: set_xrange      !< gnuplot `set xrange`.
      procedure, pass(self) :: set_ylabel      !< gnuplot `set ylabel`.
      procedure, pass(self) :: set_yrange      !< gnuplot `set yrange`.
      procedure, pass(self) :: unset_logscale  !< gnuplot `unset logscale`.
      procedure, pass(self), private :: render !< Render on a device.
endtype figure_object

contains
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
   self%axes = fresh%axes
   if (present(width)) self%width = real(width, R8P)
   if (present(height)) self%height = real(height, R8P)
   if (present(font_size)) self%font_size = font_size
   endsubroutine init

   subroutine plot(self, x, y, title, with, lc, lw, dt, ps)
   !< Add the series (`x`, `y`), as gnuplot `plot ... title ... with ... lc ... lw ... dt ... ps ...`.
   class(figure_object), intent(inout)        :: self  !< Figure.
   real(R8P),            intent(in)           :: x(:)  !< Abscissae.
   real(R8P),            intent(in)           :: y(:)  !< Ordinates.
   character(len=*),     intent(in), optional :: title !< Key title, empty or absent for none.
   character(len=*),     intent(in), optional :: with  !< Plotting style: `lines` (default), `points`, `linespoints`.
   character(len=*),     intent(in), optional :: lc    !< Line color (SVG color); default from the gnuplot palette.
   real(R8P),            intent(in), optional :: lw    !< Line width [px].
   integer(I4P),         intent(in), optional :: dt    !< Dash type, 1..5.
   real(R8P),            intent(in), optional :: ps    !< Point size scale factor.

   call self%axes%add_series(x, y, title=title, with=with, lc=lc, lw=lw, dt=dt, ps=ps)
   endsubroutine plot

   subroutine save(self, file)
   !< Render the figure to `file`; the format follows the extension (supported: `.svg`).
   class(figure_object), intent(inout) :: self !< Figure.
   character(len=*),     intent(in)    :: file !< Output file.
   type(backend_svg)                   :: svg  !< SVG device.

   select case (extension(file))
   case ('svg')
      call self%render(svg, file)
   case default
      error stop 'foresight: unsupported output format of "'//file//'" (supported: .svg)'
   endselect
   endsubroutine save

   pure subroutine set_grid(self, on)
   !< Draw grid lines at the major ticks (`on` absent or true), as gnuplot `set grid`, or not.
   class(figure_object), intent(inout)        :: self !< Figure.
   logical,              intent(in), optional :: on   !< Grid on.

   self%axes%grid = .true.
   if (present(on)) self%axes%grid = on
   endsubroutine set_grid

   pure subroutine set_key(self, on)
   !< Draw the key (`on` absent or true), as gnuplot `set key`, or not.
   class(figure_object), intent(inout)        :: self !< Figure.
   logical,              intent(in), optional :: on   !< Key on.

   self%axes%key = .true.
   if (present(on)) self%axes%key = on
   endsubroutine set_key

   pure subroutine set_logscale(self, axes)
   !< Base-10 log scale on the `axes` named by the letters `x`, `y`; all axes when absent, as gnuplot.
   class(figure_object), intent(inout)        :: self !< Figure.
   character(len=*),     intent(in), optional :: axes !< Axes letters, e.g. `y` or `xy`.

   if (present(axes)) then
      if (index(axes, 'x') > 0) self%axes%xaxis%log = .true.
      if (index(axes, 'y') > 0) self%axes%yaxis%log = .true.
   else
      self%axes%xaxis%log = .true.
      self%axes%yaxis%log = .true.
   endif
   endsubroutine set_logscale

   pure subroutine set_title(self, title)
   !< Set the title, empty for none.
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: title !< Title.

   self%axes%title = title
   endsubroutine set_title

   pure subroutine set_xlabel(self, label)
   !< Set the x axis label, empty for none.
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: label !< Label.

   self%axes%xaxis%label = label
   endsubroutine set_xlabel

   pure subroutine set_xrange(self, min, max)
   !< Set the x range as gnuplot `set xrange [min:max]`: an absent end is autoscaled, `min > max` reverses the axis.
   class(figure_object), intent(inout)        :: self !< Figure.
   real(R8P),            intent(in), optional :: min  !< Value at the axis start.
   real(R8P),            intent(in), optional :: max  !< Value at the axis end.

   call self%axes%xaxis%set_range(min=min, max=max)
   endsubroutine set_xrange

   pure subroutine set_ylabel(self, label)
   !< Set the y axis label, empty for none.
   class(figure_object), intent(inout) :: self  !< Figure.
   character(len=*),     intent(in)    :: label !< Label.

   self%axes%yaxis%label = label
   endsubroutine set_ylabel

   pure subroutine set_yrange(self, min, max)
   !< Set the y range as gnuplot `set yrange [min:max]`: an absent end is autoscaled, `min > max` reverses the axis.
   class(figure_object), intent(inout)        :: self !< Figure.
   real(R8P),            intent(in), optional :: min  !< Value at the axis start.
   real(R8P),            intent(in), optional :: max  !< Value at the axis end.

   call self%axes%yaxis%set_range(min=min, max=max)
   endsubroutine set_yrange

   pure subroutine unset_logscale(self, axes)
   !< Linear scale on the `axes` named by the letters `x`, `y`; all axes when absent, as gnuplot.
   class(figure_object), intent(inout)        :: self !< Figure.
   character(len=*),     intent(in), optional :: axes !< Axes letters, e.g. `y` or `xy`.

   if (present(axes)) then
      if (index(axes, 'x') > 0) self%axes%xaxis%log = .false.
      if (index(axes, 'y') > 0) self%axes%yaxis%log = .false.
   else
      self%axes%xaxis%log = .false.
      self%axes%yaxis%log = .false.
   endif
   endsubroutine unset_logscale

   ! private procedures
   subroutine render(self, backend, file)
   !< Render the figure on `backend`, writing `file`.
   class(figure_object),  intent(inout) :: self    !< Figure.
   class(backend_object), intent(inout) :: backend !< Output device.
   character(len=*),      intent(in)    :: file    !< Output file.

   call backend%begin_page(file, self%width, self%height, self%font_size)
   call backend%rect(0.0_R8P, 0.0_R8P, self%width, self%height, 'none', 'white', 0.0_R8P)
   call self%axes%render(backend, 0.0_R8P, 0.0_R8P, self%width, self%height, self%font_size)
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
