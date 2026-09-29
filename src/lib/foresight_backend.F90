!< foresight_backend, abstract output device.
module foresight_backend
!< foresight_backend, abstract output device.
!<
!< Two coordinate spaces. Page primitives take pixel coordinates (origin top-left, y downward). The `data_*`
!< primitives, valid between `begin_plot_area` and `end_plot_area`, take unit-square coordinates of the plot area
!< (origin bottom-left, y upward, [0, 1] spanning the axis ranges) and are clipped to it. Keeping data in unit
!< coordinates lets an interactive device zoom and pan by changing a single view transform.
!<
!< A panel is bracketed by `begin_axes`/`end_axes`, which hand the device the panel geometry and axis ranges, and its
!< redrawable decorations (grid, ticks) by named `begin_group`/`end_group`: an interactive device regenerates them after
!< a zoom, a static one just writes them.
use penf, only : R8P

implicit none
private
public :: axes_view
public :: backend_object

type :: axes_view
   !< Geometry and axis ranges of a plot panel.
   real(R8P) :: area(4)   = 0.0_R8P  !< Plot area: left, right, top, bottom [px].
   real(R8P) :: x(2)      = 0.0_R8P  !< x axis values at the axis start and end.
   real(R8P) :: y(2)      = 0.0_R8P  !< y axis values at the axis start and end.
   logical   :: xlog      = .false.  !< Log x axis.
   logical   :: ylog      = .false.  !< Log y axis.
   logical   :: grid      = .false.  !< Grid shown.
   real(R8P) :: font_size = 12.0_R8P !< Font size [px].
endtype axes_view

type, abstract :: backend_object
   !< Abstract output device.
   contains
      procedure(begin_page_interface),      pass(self), deferred :: begin_page      !< Open the output page.
      procedure(finish_interface),          pass(self), deferred :: end_page        !< Close the output page.
      procedure(begin_axes_interface),      pass(self), deferred :: begin_axes      !< Open a plot panel.
      procedure(finish_interface),          pass(self), deferred :: end_axes        !< Close the plot panel.
      procedure(begin_group_interface),     pass(self), deferred :: begin_group     !< Open a named group.
      procedure(finish_interface),          pass(self), deferred :: end_group       !< Close the group.
      procedure(rect_interface),            pass(self), deferred :: rect            !< Rectangle [px].
      procedure(lines_interface),           pass(self), deferred :: polyline        !< Polyline [px].
      procedure(dots_interface),            pass(self), deferred :: dots            !< Round dots [px].
      procedure(text_interface),            pass(self), deferred :: text            !< Text [px].
      procedure(begin_plot_area_interface), pass(self), deferred :: begin_plot_area !< Open the clipped plot area.
      procedure(finish_interface),          pass(self), deferred :: end_plot_area   !< Close the plot area.
      procedure(lines_interface),           pass(self), deferred :: data_polyline   !< Polyline [unit square].
      procedure(dots_interface),            pass(self), deferred :: data_dots       !< Round dots [unit square].
      procedure(bars_interface),            pass(self), deferred :: data_bars       !< Error bars [unit square].
endtype backend_object

abstract interface
   subroutine begin_page_interface(self, file, width, height, font_size)
   !< Open the output `file` with a page of `width` x `height` px and the default `font_size` [px].
   import :: backend_object, R8P
   class(backend_object), intent(inout) :: self      !< Device.
   character(len=*),      intent(in)    :: file      !< Output file.
   real(R8P),             intent(in)    :: width     !< Page width [px].
   real(R8P),             intent(in)    :: height    !< Page height [px].
   real(R8P),             intent(in)    :: font_size !< Default font size [px].
   endsubroutine begin_page_interface

   subroutine finish_interface(self)
   !< Close the current page, panel, group or plot area.
   import :: backend_object
   class(backend_object), intent(inout) :: self !< Device.
   endsubroutine finish_interface

   subroutine begin_axes_interface(self, view)
   !< Open a plot panel described by `view`.
   import :: axes_view, backend_object
   class(backend_object), intent(inout) :: self !< Device.
   type(axes_view),       intent(in)    :: view !< Panel geometry and axis ranges.
   endsubroutine begin_axes_interface

   subroutine begin_group_interface(self, name, visible)
   !< Open the group `name` of redrawable decorations; `visible` false hides it (default true).
   import :: backend_object
   class(backend_object), intent(inout)        :: self    !< Device.
   character(len=*),      intent(in)           :: name    !< Group name.
   logical,               intent(in), optional :: visible !< Group shown.
   endsubroutine begin_group_interface

   subroutine rect_interface(self, x, y, width, height, stroke, fill, line_width)
   !< Rectangle of top-left corner (`x`, `y`) [px]; `stroke` and `fill` are SVG colors or `none`.
   import :: backend_object, R8P
   class(backend_object), intent(inout) :: self       !< Device.
   real(R8P),             intent(in)    :: x          !< Left side [px].
   real(R8P),             intent(in)    :: y          !< Top side [px].
   real(R8P),             intent(in)    :: width      !< Width [px].
   real(R8P),             intent(in)    :: height     !< Height [px].
   character(len=*),      intent(in)    :: stroke     !< Stroke color.
   character(len=*),      intent(in)    :: fill       !< Fill color.
   real(R8P),             intent(in)    :: line_width !< Stroke width [px].
   endsubroutine rect_interface

   subroutine lines_interface(self, x, y, color, line_width, dasharray)
   !< Open polyline through the points (`x`, `y`); `dasharray` is empty for solid lines.
   import :: backend_object, R8P
   class(backend_object), intent(inout) :: self       !< Device.
   real(R8P),             intent(in)    :: x(:)       !< Abscissae.
   real(R8P),             intent(in)    :: y(:)       !< Ordinates.
   character(len=*),      intent(in)    :: color      !< Stroke color.
   real(R8P),             intent(in)    :: line_width !< Stroke width [px].
   character(len=*),      intent(in)    :: dasharray  !< SVG dash array, empty for solid.
   endsubroutine lines_interface

   subroutine bars_interface(self, x1, y1, x2, y2, color, line_width, cap, vertical)
   !< Error bars from (`x1`, `y1`) to (`x2`, `y2`) [unit square], with end caps `cap` px long across the bar.
   import :: backend_object, R8P
   class(backend_object), intent(inout) :: self       !< Device.
   real(R8P),             intent(in)    :: x1(:)      !< Bar start abscissae.
   real(R8P),             intent(in)    :: y1(:)      !< Bar start ordinates.
   real(R8P),             intent(in)    :: x2(:)      !< Bar end abscissae.
   real(R8P),             intent(in)    :: y2(:)      !< Bar end ordinates.
   character(len=*),      intent(in)    :: color      !< Stroke color.
   real(R8P),             intent(in)    :: line_width !< Stroke width [px].
   real(R8P),             intent(in)    :: cap        !< Cap length [px].
   logical,               intent(in)    :: vertical   !< Vertical bars (horizontal caps), else horizontal.
   endsubroutine bars_interface

   subroutine dots_interface(self, x, y, color, diameter)
   !< Filled round dots centred on the points (`x`, `y`).
   import :: backend_object, R8P
   class(backend_object), intent(inout) :: self     !< Device.
   real(R8P),             intent(in)    :: x(:)     !< Abscissae.
   real(R8P),             intent(in)    :: y(:)     !< Ordinates.
   character(len=*),      intent(in)    :: color    !< Fill color.
   real(R8P),             intent(in)    :: diameter !< Dot diameter [px].
   endsubroutine dots_interface

   subroutine text_interface(self, x, y, string, anchor, sup, rotate)
   !< Text whose baseline passes through the anchor point (`x`, `y`) [px].
   import :: backend_object, R8P
   class(backend_object), intent(inout)        :: self   !< Device.
   real(R8P),             intent(in)           :: x      !< Anchor abscissa [px].
   real(R8P),             intent(in)           :: y      !< Anchor ordinate (baseline) [px].
   character(len=*),      intent(in)           :: string !< Text.
   character(len=*),      intent(in)           :: anchor !< Horizontal anchor: `start`, `middle` or `end`.
   character(len=*),      intent(in), optional :: sup    !< Superscript appended to `string`.
   real(R8P),             intent(in), optional :: rotate !< Rotation about the anchor point [deg, clockwise].
   endsubroutine text_interface

   subroutine begin_plot_area_interface(self, x, y, width, height)
   !< Open the clipped plot area of top-left corner (`x`, `y`) and size `width` x `height` [px].
   import :: backend_object, R8P
   class(backend_object), intent(inout) :: self   !< Device.
   real(R8P),             intent(in)    :: x      !< Left side [px].
   real(R8P),             intent(in)    :: y      !< Top side [px].
   real(R8P),             intent(in)    :: width  !< Width [px].
   real(R8P),             intent(in)    :: height !< Height [px].
   endsubroutine begin_plot_area_interface
endinterface
endmodule foresight_backend
