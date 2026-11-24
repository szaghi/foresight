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
use foresight_font, only : font_object
use penf, only : I4P, R8P
use foresight_theme, only : theme_object

implicit none
private
public :: axes_view
public :: backend_object
public :: arrow_head
public :: sized_head
public :: HEAD_ANGLE, HEAD_LENGTH

real(R8P), parameter :: HEAD_LENGTH = 18.0_R8P !< Arrowhead barb length [px], gnuplot svg default.
real(R8P), parameter :: HEAD_ANGLE  = 15.0_R8P !< Arrowhead barb angle off the shaft [deg], gnuplot default.

type :: axes_view
   !< Geometry and axis ranges of a plot panel.
   real(R8P) :: area(4)   = 0.0_R8P  !< Plot area: left, right, top, bottom [px].
   real(R8P) :: x(2)      = 0.0_R8P  !< x axis values at the axis start and end.
   real(R8P) :: y(2)      = 0.0_R8P  !< y axis values at the axis start and end.
   logical   :: xlog      = .false.  !< Log x axis.
   logical   :: ylog      = .false.  !< Log y axis.
   logical   :: grid      = .false.  !< Grid shown.
   logical   :: markup    = .false.  !< Tick labels with enhanced text markup, drawn again by the viewer as such.
   real(R8P) :: font_size = 12.0_R8P !< Font size [px].
   character(len=:), allocatable :: xtics   !< x tick positions for the viewer (`tics_object%attribute`), empty for auto.
   character(len=:), allocatable :: ytics   !< y tick positions for the viewer, empty for auto.
   character(len=:), allocatable :: xformat !< x tick label format, empty for the default.
   character(len=:), allocatable :: yformat !< y tick label format, empty for the default.
   logical   :: mirror(3) = [.true., .true., .false.] !< Ticks mirrored on the opposite border: x, y, y2.
   logical   :: y2_active = .false. !< Second y axis drawn; the `y2*` components are meaningful only then.
   real(R8P) :: y2(2)     = 0.0_R8P  !< y2 axis values at the axis start and end.
   logical   :: y2log     = .false.  !< Log y2 axis.
   character(len=:), allocatable :: y2tics   !< y2 tick positions for the viewer, empty for auto.
   character(len=:), allocatable :: y2format !< y2 tick label format, empty for the default.
   logical   :: x2_active = .false. !< Second x axis drawn; the `x2*` components are meaningful only then.
   real(R8P) :: x2(2)     = 0.0_R8P  !< x2 axis values at the axis start and end.
   logical   :: x2log     = .false.  !< Log x2 axis.
   logical   :: x2mirror  = .false.  !< x2 ticks mirrored on the bottom border.
   character(len=:), allocatable :: x2tics   !< x2 tick positions for the viewer, empty for auto.
   character(len=:), allocatable :: x2format !< x2 tick label format, empty for the default.
   character(len=:), allocatable :: xtime  !< Input time format of a time x axis (its `timefmt`), empty if numeric.
   character(len=:), allocatable :: ytime  !< Input time format of a time y axis, empty if numeric.
   character(len=:), allocatable :: y2time !< Input time format of a time y2 axis, empty if numeric.
   character(len=:), allocatable :: x2time !< Input time format of a time x2 axis, empty if numeric.
   character(len=:), allocatable :: gridlines !< Grid lines (`x y2 mx`), empty for the x and y major ones.
   character(len=:), allocatable :: gridstyle !< Grid line `color width dashes`, empty for the theme's.
endtype axes_view

type, abstract :: backend_object
   !< Abstract output device.
   type(theme_object) :: theme !< Output theme: colors the layout's ones are mapped to (foresight_theme).
   logical            :: enhanced = .false. !< Texts read as gnuplot's enhanced text (foresight_enhanced).
   logical            :: latin1 = .false.   !< Texts in ISO 8859-1, written in UTF-8 (`set encoding iso_8859_1`).
   logical            :: literal = .false.  !< The texts written now as they are (an automatic title, noenhanced).
   real(R8P)          :: text_size = 12.0_R8P !< Default font size of the texts [px].
   logical            :: boxed = .false.     !< The texts written now are boxed (gnuplot's textbox): on the background.
   character(len=48)  :: page_family = ''    !< Font family of the page (`set terminal ... font`), empty: the device's.
   type(font_object)  :: font                !< The font of the texts written now (gnuplot `font "..."`); unset parts
                                             !< the page's.
   real(R8P)          :: head_px(2) = 0.0_R8P !< Length [px] and angle [deg] of the data arrowheads drawn now, 0 for
                                              !< the default head.
   contains
      procedure(begin_page_interface),      pass(self), deferred :: begin_page      !< Open the output page.
      procedure(finish_interface),          pass(self), deferred :: end_page        !< Close the output page.
      procedure(begin_axes_interface),      pass(self), deferred :: begin_axes      !< Open a plot panel.
      procedure(finish_interface),          pass(self), deferred :: end_axes        !< Close the plot panel.
      procedure(begin_group_interface),     pass(self), deferred :: begin_group     !< Open a named group.
      procedure(finish_interface),          pass(self), deferred :: end_group       !< Close the group.
      procedure(rect_interface),            pass(self), deferred :: rect            !< Rectangle [px].
      procedure(lines_interface),           pass(self), deferred :: polyline        !< Polyline [px].
      procedure(dots_interface),            pass(self), deferred :: dots            !< Round dots or markers [px].
      procedure(polygon_interface),         pass(self), deferred :: polygon         !< Filled polygon [px].
      procedure(image_interface),           pass(self), deferred :: image           !< Raster image [px].
      procedure(text_interface),            pass(self), deferred :: text            !< Text [px].
      procedure(begin_plot_area_interface), pass(self), deferred :: begin_plot_area !< Open the clipped plot area.
      procedure(finish_interface),          pass(self), deferred :: end_plot_area   !< Close the plot area.
      procedure(lines_interface),           pass(self), deferred :: data_polyline   !< Polyline [unit square].
      procedure(dots_interface),            pass(self), deferred :: data_dots       !< Dots or markers [unit square].
      procedure(bars_interface),            pass(self), deferred :: data_bars       !< Error bars [unit square].
      procedure(polygon_interface),         pass(self), deferred :: data_polygon    !< Filled polygon [unit square].
      procedure(image_interface),           pass(self), deferred :: data_image      !< Raster image [unit square].
      procedure(text_width_interface),      pass(self), deferred :: text_width      !< Text width [px].
      procedure(readout_interface),         pass(self), deferred :: readout         !< Seven-segment readout [px].
      procedure(readout_extent_interface),  pass(self), deferred :: readout_extent  !< Readout size [px].
      procedure(arrows_interface),          pass(self), deferred :: data_arrows     !< Arrows [unit square].
      procedure(label_interface),           pass(self), deferred :: data_label      !< Text at a point [unit square].
      procedure,                            pass(self)           :: rotates_text    !< Whether text can be rotated.
      procedure,                            pass(self)           :: row_height     !< Text row height, 0 if none.
      procedure,                            pass(self)           :: hover          !< Text on mouse-over of a point.
      procedure,                            pass(self)           :: pixmap         !< A PNG image [px].
      procedure,                            pass(self)           :: front_area     !< Open or close the front layer of
                                                                                      !< the plot area.
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

   subroutine begin_group_interface(self, name, visible, series)
   !< Open the group `name` of redrawable decorations; `visible` false hides it (default true). A group of a plotted
   !< series, or of its key entry, carries the series number `series` (from 1): an interactive viewer hides the series
   !< when its key entry is clicked.
   import :: backend_object, I4P
   class(backend_object), intent(inout)        :: self    !< Device.
   character(len=*),      intent(in)           :: name    !< Group name.
   logical,               intent(in), optional :: visible !< Group shown.
   integer(I4P),          intent(in), optional :: series  !< Series number.
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

   subroutine polygon_interface(self, x, y, fill, opacity, stroke, line_width, ghost)
   !< Closed polygon of the vertices (`x`, `y`): filled with `fill` at `opacity` (0..1), its border stroked with `stroke`
   !< `line_width` px wide; `fill` and `stroke` are SVG colors or `none`. In unit-square coordinates (`data_polygon`)
   !< it is clipped to the plot area. A `ghost` is an unlit cell of a segmented fill: drawn faintly (the theme ghost
   !< opacity, no border), or not at all on a device without faint intensity (text).
   import :: backend_object, R8P
   class(backend_object), intent(inout) :: self       !< Device.
   real(R8P),             intent(in)    :: x(:)       !< Vertex abscissae.
   real(R8P),             intent(in)    :: y(:)       !< Vertex ordinates.
   character(len=*),      intent(in)    :: fill       !< Fill color.
   real(R8P),             intent(in)    :: opacity    !< Fill opacity.
   character(len=*),      intent(in)    :: stroke     !< Border color.
   real(R8P),             intent(in)    :: line_width !< Border width [px].
   logical,               intent(in), optional :: ghost !< Unlit cell of a segmented fill.
   endsubroutine polygon_interface

   subroutine image_interface(self, x0, y0, x1, y1, rgba)
   !< Raster image `rgba(channel, column, row)` (red, green, blue, alpha 0..255; columns left to right, rows top to
   !< bottom) stretched over the box from (`x0`, `y0`) to (`x1`, `y1`): its top-left and bottom-right corners [px] for
   !< `image`, its bottom-left and top-right corners [unit square] for `data_image`, clipped to the plot area.
   import :: backend_object, I4P, R8P
   class(backend_object), intent(inout) :: self        !< Device.
   real(R8P),             intent(in)    :: x0          !< First corner abscissa.
   real(R8P),             intent(in)    :: y0          !< First corner ordinate.
   real(R8P),             intent(in)    :: x1          !< Opposite corner abscissa.
   real(R8P),             intent(in)    :: y1          !< Opposite corner ordinate.
   integer(I4P),          intent(in)    :: rgba(:,:,:) !< Pixels.
   endsubroutine image_interface

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

   subroutine dots_interface(self, x, y, color, diameter, pt, line_width)
   !< Filled round dots centred on the points (`x`, `y`), or the markers of the gnuplot point type `pt` (0 a dot, 1.. the
   !< shapes, cycling every 15) drawn `diameter` wide with lines `line_width` px wide (default 1).
   import :: backend_object, I4P, R8P
   class(backend_object), intent(inout)        :: self       !< Device.
   real(R8P),             intent(in)           :: x(:)       !< Abscissae.
   real(R8P),             intent(in)           :: y(:)       !< Ordinates.
   character(len=*),      intent(in)           :: color      !< Fill color.
   real(R8P),             intent(in)           :: diameter   !< Dot diameter, or marker width [px].
   integer(I4P),          intent(in), optional :: pt         !< gnuplot point type; negative or absent: round dots.
   real(R8P),             intent(in), optional :: line_width !< Marker line width [px].
   endsubroutine dots_interface

   subroutine text_interface(self, x, y, string, anchor, sup, rotate, color)
   !< Text whose baseline passes through the anchor point (`x`, `y`) [px].
   import :: backend_object, R8P
   class(backend_object), intent(inout)        :: self   !< Device.
   real(R8P),             intent(in)           :: x      !< Anchor abscissa [px].
   real(R8P),             intent(in)           :: y      !< Anchor ordinate (baseline) [px].
   character(len=*),      intent(in)           :: string !< Text.
   character(len=*),      intent(in)           :: anchor !< Horizontal anchor: `start`, `middle` or `end`.
   character(len=*),      intent(in), optional :: sup    !< Superscript appended to `string`.
   real(R8P),             intent(in), optional :: rotate !< Rotation about the anchor point [deg, clockwise].
   character(len=*),      intent(in), optional :: color  !< Text color, the frame's if absent.
   endsubroutine text_interface

   pure function text_width_interface(self, string, sup, font_size) result(width)
   !< Width of `string` with its superscript `sup` [px], as the device renders it (estimated for vector formats).
   import :: backend_object, R8P
   class(backend_object), intent(in) :: self      !< Device.
   character(len=*),      intent(in) :: string    !< Text.
   character(len=*),      intent(in) :: sup       !< Superscript.
   real(R8P),             intent(in) :: font_size !< Font size [px].
   real(R8P)                         :: width     !< Width [px].
   endfunction text_width_interface

   subroutine readout_interface(self, x, y, height, masks, label, prefix, suffix, color, font_size)
   !< Seven-segment readout (see foresight_readout) of top-left corner (`x`, `y`) [px]: `label` above a glass of
   !< `size(masks)` cells of digits `height` px high, each cell lit by its mask (bits 0-6 the segments a-g, bit 7 the
   !< decimal point) in `color`, the unit text `prefix` and `suffix` on its sides; text at `font_size`. It covers
   !< `readout_extent`.
   import :: backend_object, I4P, R8P
   class(backend_object), intent(inout) :: self      !< Device.
   real(R8P),             intent(in)    :: x         !< Left side [px].
   real(R8P),             intent(in)    :: y         !< Top side [px].
   real(R8P),             intent(in)    :: height    !< Digit height [px].
   integer(I4P),          intent(in)    :: masks(:)  !< Segments of each cell.
   character(len=*),      intent(in)    :: label     !< Label, empty for none.
   character(len=*),      intent(in)    :: prefix    !< Text before the glass.
   character(len=*),      intent(in)    :: suffix    !< Text after the glass.
   character(len=*),      intent(in)    :: color     !< Color of the lit segments.
   real(R8P),             intent(in)    :: font_size !< Font size of the texts [px].
   endsubroutine readout_interface

   pure function readout_extent_interface(self, height, cells, label, prefix, suffix, font_size) result(extent)
   !< Width and height [px] of a readout (see `readout_interface`) of `cells` cells of digits `height` px high.
   import :: backend_object, I4P, R8P
   class(backend_object), intent(in) :: self      !< Device.
   real(R8P),             intent(in) :: height    !< Digit height [px].
   integer(I4P),          intent(in) :: cells     !< Glass cells.
   character(len=*),      intent(in) :: label     !< Label, empty for none.
   character(len=*),      intent(in) :: prefix    !< Text before the glass.
   character(len=*),      intent(in) :: suffix    !< Text after the glass.
   real(R8P),             intent(in) :: font_size !< Font size of the texts [px].
   real(R8P)                         :: extent(2) !< Width and height [px].
   endfunction readout_extent_interface

   subroutine arrows_interface(self, x1, y1, x2, y2, color, line_width, head, filled)
   !< Arrows from (`x1`, `y1`) to (`x2`, `y2`) [unit square]: the shafts are data, the heads (`arrow_head`) keep their
   !< pixel size; `head` 0 none, 1 at the end, 2 at the start (gnuplot `backhead`), 3 both; `filled` heads are
   !< triangles, else open.
   import :: backend_object, I4P, R8P
   class(backend_object), intent(inout) :: self       !< Device.
   real(R8P),             intent(in)    :: x1(:)      !< Tail abscissae.
   real(R8P),             intent(in)    :: y1(:)      !< Tail ordinates.
   real(R8P),             intent(in)    :: x2(:)      !< Tip abscissae.
   real(R8P),             intent(in)    :: y2(:)      !< Tip ordinates.
   character(len=*),      intent(in)    :: color      !< Stroke color.
   real(R8P),             intent(in)    :: line_width !< Stroke width [px].
   integer(I4P),          intent(in)    :: head       !< Heads: 0 none, 1 end, 2 start, 3 both.
   logical,               intent(in)    :: filled     !< Filled heads.
   endsubroutine arrows_interface

   subroutine label_interface(self, x, y, string, anchor, rotate, color, dx, dy)
   !< Text anchored at the point (`x`, `y`) [unit square] moved by (`dx`, `dy`) [px, y down]: it keeps its pixel size,
   !< only its anchor moves with the data.
   import :: backend_object, R8P
   class(backend_object), intent(inout) :: self   !< Device.
   real(R8P),             intent(in)    :: x      !< Anchor abscissa [unit].
   real(R8P),             intent(in)    :: y      !< Anchor ordinate [unit].
   character(len=*),      intent(in)    :: string !< Text.
   character(len=*),      intent(in)    :: anchor !< Horizontal anchor: `start`, `middle` or `end`.
   real(R8P),             intent(in)    :: rotate !< Rotation [deg, counterclockwise].
   character(len=*),      intent(in)    :: color  !< Text color.
   real(R8P),             intent(in)    :: dx     !< Horizontal offset [px].
   real(R8P),             intent(in)    :: dy     !< Vertical offset [px, downward].
   endsubroutine label_interface

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

contains
   pure function rotates_text(self) result(rotates)
   !< Whether the device draws text rotated, as tick labels `rotate`d by gnuplot: true but on text devices, which
   !< write them horizontally, as gnuplot's dumb terminal.
   class(backend_object), intent(in) :: self    !< Device.
   logical                           :: rotates !< Rotated text.

   rotates = .true.
   endfunction rotates_text

   subroutine hover(self, x, y, text, diameter)
   !< `text` shown on mouse-over of the point (`x`, `y`) [unit square], a disk of `diameter` [px] (gnuplot's
   !< hypertext): nothing on a device without a mouse.
   class(backend_object), intent(inout) :: self     !< Device.
   real(R8P),             intent(in)    :: x        !< Abscissa [unit].
   real(R8P),             intent(in)    :: y        !< Ordinate [unit].
   character(len=*),      intent(in)    :: text     !< Text.
   real(R8P),             intent(in)    :: diameter !< Sensitive disk [px].

   endsubroutine hover

   subroutine pixmap(self, x, y, width, height, png)
   !< The PNG image `png` (base64) with its top left corner at (`x`, `y`), `width` x `height` [px], stretched (gnuplot
   !< `set pixmap`): nothing on a device without images.
   class(backend_object), intent(inout) :: self   !< Device.
   real(R8P),             intent(in)    :: x      !< Left side [px].
   real(R8P),             intent(in)    :: y      !< Top side [px].
   real(R8P),             intent(in)    :: width  !< Width [px].
   real(R8P),             intent(in)    :: height !< Height [px].
   character(len=*),      intent(in)    :: png    !< The PNG file, base64.

   endsubroutine pixmap

   subroutine front_area(self, opening, separate)
   !< Open (`opening`) or close the front layer of the plot area, after its overlays (markers, caps): the data space
   !< objects of gnuplot's `front` layer go above the points. `separate` false on a device that draws them in the plot
   !< area (before it closes): this one, nothing to open or close.
   class(backend_object), intent(inout) :: self     !< Device.
   logical,               intent(in)    :: opening  !< Open, else close.
   logical,               intent(out)   :: separate !< A layer of its own.

   separate = .false.
   endsubroutine front_area

   pure function row_height(self) result(height)
   !< Height of a text row of the device [px]: 0 on vector devices, where text sits anywhere.
   class(backend_object), intent(in) :: self   !< Device.
   real(R8P)                         :: height !< Row height [px].

   height = 0.0_R8P
   endfunction row_height

   pure subroutine arrow_head(tail, tip, barbs)
   !< The barbs of an arrowhead at `tip` pointing away from `tail` [px, any orientation]: HEAD_LENGTH px long,
   !< HEAD_ANGLE degrees off the shaft, as gnuplot's default head; `barbs(:, 1)` and `barbs(:, 2)`. A zero length
   !< shaft points right.
   real(R8P), intent(in)  :: tail(2)     !< Tail [px].
   real(R8P), intent(in)  :: tip(2)      !< Tip [px].
   real(R8P), intent(out) :: barbs(2, 2) !< Barb ends [px].

   call sized_head(tail, tip, HEAD_LENGTH, HEAD_ANGLE, barbs)
   endsubroutine arrow_head

   pure subroutine sized_head(tail, tip, length, angle, barbs)
   !< The barbs of an arrowhead at `tip` pointing away from `tail` [px, any orientation], `length` px long, `angle`
   !< degrees off the shaft: `barbs(:, 1)` and `barbs(:, 2)`. A zero length shaft points right.
   real(R8P), intent(in)  :: tail(2)     !< Tail [px].
   real(R8P), intent(in)  :: tip(2)      !< Tip [px].
   real(R8P), intent(in)  :: length      !< Barb length [px].
   real(R8P), intent(in)  :: angle       !< Barb angle [deg].
   real(R8P), intent(out) :: barbs(2, 2) !< Barb ends [px].
   real(R8P)              :: a           !< Shaft direction, tip to tail [rad].
   real(R8P)              :: h           !< Barb half angle [rad].

   a = 0.0_R8P
   if (any(tip /= tail)) a = atan2(tail(2) - tip(2), tail(1) - tip(1))
   if (all(tip == tail)) a = 4.0_R8P * atan(1.0_R8P)
   h = angle * atan(1.0_R8P) / 45.0_R8P
   barbs(:, 1) = tip + length * [cos(a + h), sin(a + h)]
   barbs(:, 2) = tip + length * [cos(a - h), sin(a - h)]
   endsubroutine sized_head

endmodule foresight_backend
