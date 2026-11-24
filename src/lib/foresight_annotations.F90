!< foresight_annotations, labels, arrows and objects placed on a panel (gnuplot `set label`, `set arrow`, `set object`).
module foresight_annotations
!< foresight_annotations, labels, arrows and objects placed on a panel (gnuplot `set label`, `set arrow`, `set object`).
!<
!< A position is two coordinates, each in its system: `first` (the x or y axis values), `second` (the x2 or y2
!< ones), `graph` (fractions of the plot area from its bottom left), `screen` (fractions of the page) or `character`
!< (character cells from the page's bottom left: 0.6 of the font size wide, the font size high, as the label offsets),
!< as gnuplot.
!<
!< Labels and arrows are not clipped, as gnuplot's; objects are clipped by the plot area when both coordinates of
!< every point are axis values (gnuplot's default `clip`), drawn in data space then (the interactive viewer zooms
!< them with the data); else on the page. Layers: `back` (the default) behind the data, `front` over the frame,
!< `behind` (objects) behind the grid too.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite
use foresight_axis, only : axis_object
use foresight_backend, only : arrow_head, backend_object
use foresight_style, only : style_object
use penf, only : I4P, R8P

implicit none
private
public :: arrow_object
public :: draw_arrows
public :: draw_labels
public :: draw_shapes
public :: has_shapes
public :: draw_pixmaps
public :: pixmap_object
public :: label_object
public :: place_object
public :: push
public :: shape_object
public :: anchored
public :: in_data

interface push
   !< Append an item through a temporary: nvfortran 26.9 corrupts `list = [list, item]` when the items hold
   !< deferred-length characters.
   module procedure push_label, push_arrow, push_shape, push_pixmap
endinterface push

character(len=*), parameter :: FRAME_COLOR = 'black' !< Default text and line color (the theme maps it).
real(R8P),        parameter :: PI = 4.0_R8P * atan(1.0_R8P) !< pi.

type :: place_object
   !< A position: its coordinates and the system of each.
   real(R8P)        :: x  = 0.0_R8P   !< Abscissa.
   real(R8P)        :: y  = 0.0_R8P   !< Ordinate.
   character(len=9) :: sx = 'first'   !< System of the abscissa: `first`, `second`, `graph`, `screen`, `character`.
   character(len=9) :: sy = 'first'   !< System of the ordinate.
endtype place_object

type :: label_object
   !< A label, gnuplot `set label`.
   integer(I4P)                  :: tag = 0_I4P          !< Tag (`set label N`).
   logical                       :: plain = .false.      !< The text as it is, not enhanced text (`noenhanced`).
   character(len=:), allocatable :: text                 !< Text.
   type(place_object)            :: at                   !< Position.
   character(len=6)              :: justify = 'left'     !< `left`, `center` or `right` of the position.
   real(R8P)                     :: rotate = 0.0_R8P     !< Angle [deg, counterclockwise].
   character(len=:), allocatable :: color                !< Text color, the frame's if empty.
   logical                       :: front = .false.      !< Over the frame, else behind the data.
   logical                       :: point = .false.      !< A point marks the position.
   integer(I4P)                  :: pt = 1_I4P           !< Point type.
   real(R8P)                     :: ps = 1.0_R8P         !< Point size.
   real(R8P)                     :: offset(2) = 0.0_R8P  !< Text offset [characters, y upward].
   logical                       :: boxed = .false.      !< On the background (gnuplot `boxed`, a drawn text box style).
endtype label_object

type :: arrow_object
   !< An arrow, gnuplot `set arrow`.
   integer(I4P)                  :: tag = 0_I4P          !< Tag (`set arrow N`).
   type(place_object)            :: from                 !< Tail.
   type(place_object)            :: to                   !< Tip, or the tip from the tail (`rto`).
   logical                       :: relative = .false.   !< `rto`: `to` is relative to `from`.
   integer(I4P)                  :: head = 1_I4P         !< Heads: 0 none, 1 at the tip, 2 at the tail, 3 both.
   real(R8P)                     :: length = 0.0_R8P     !< Head length (0: the default head).
   character(len=9)              :: length_system = 'first' !< System of the head length (x direction).
   real(R8P)                     :: angle = 15.0_R8P     !< Head barb angle [deg].
   character(len=8)              :: fill = 'nofilled'    !< Heads `nofilled` (two barbs), `filled`, `empty`,
                                                         !< `noborder`.
   logical                       :: front = .false.      !< Over the frame, else behind the data.
   logical                       :: polar = .false.      !< The tip by a length and an angle from the tail (gnuplot
                                                         !< `length L angle A`), not by `to`.
   real(R8P)                     :: span = 0.0_R8P       !< That length, negative backwards.
   character(len=9)              :: span_system = 'first' !< Its system (along x: first, second, graph, screen,
                                                          !< character).
   real(R8P)                     :: direction = 0.0_R8P  !< That angle on the page [deg, counterclockwise from x].
   character(len=:), allocatable :: color                !< Line color, the frame's if empty.
   real(R8P)                     :: lw = 1.0_R8P         !< Line width [px].
   character(len=:), allocatable :: dashes               !< SVG dash array, empty for solid.
endtype arrow_object

type :: shape_object
   !< An object, gnuplot `set object`: a rectangle, circle, ellipse or polygon.
   integer(I4P)                    :: tag = 0_I4P        !< Tag (`set object N`).
   character(len=9)                :: kind = 'rectangle' !< `rectangle`, `circle`, `ellipse`, `polygon`.
   type(place_object), allocatable :: points(:)          !< Rectangle corners (2) or centre (1, with `size`); circle
                                                         !< and ellipse centre; polygon vertices.
   type(place_object)              :: size               !< Rectangle and ellipse width and height, circle radius
                                                         !< (`x`, in the system `sx`).
   logical                         :: sized = .false.    !< The rectangle is given by its centre and size.
   real(R8P)                       :: angle = 0.0_R8P    !< Ellipse orientation [deg].
   real(R8P)                       :: arc(2) = [0.0_R8P, 360.0_R8P] !< Circle arc [deg].
   type(style_object)              :: style              !< Fill, border, color, line width.
   character(len=6)                :: layer = 'back'     !< `behind`, `back` or `front`.
   logical                         :: clip = .true.      !< Clipped by the plot area (axis coordinates only).
endtype shape_object

type :: pixmap_object
   !< An image from a PNG file, gnuplot `set pixmap`.
   integer(I4P)                  :: tag = 0_I4P         !< Tag (`set pixmap N`).
   character(len=:), allocatable :: png                 !< The file, base64.
   integer(I4P)                  :: pixels(2) = 0_I4P   !< Its width and height [pixels].
   type(place_object)            :: at                  !< Position: the lower left corner, or the centre.
   type(place_object)            :: span                !< Width and height, each in its system.
   integer(I4P)                  :: sized = 0_I4P       !< 0 its pixels, 1 `size` (both), 2 `width` (the height by
                                                        !< the aspect), 3 `height` (the width by the aspect).
   logical                       :: center = .false.    !< `at` is the centre.
   character(len=6)              :: layer = 'front'     !< `behind`, `back` or `front` (gnuplot's default).
endtype pixmap_object

type :: frame_object
   !< What a position needs: the plot area, the page, the axes.
   real(R8P)         :: area(4)   = 0.0_R8P !< Plot area: left, right, top, bottom [px].
   real(R8P)         :: canvas(2) = 0.0_R8P !< Page width and height [px].
   real(R8P)         :: cell(2)   = 0.0_R8P !< Character cell width and height [px].
endtype frame_object

contains
   pure function in_data(p) result(yes)
   !< Whether both coordinates of `p` are axis values (`first`, `second`).
   type(place_object), intent(in) :: p   !< Position.
   logical                        :: yes !< Axis values.

   yes = (p%sx == 'first' .or. p%sx == 'second') .and. (p%sy == 'first' .or. p%sy == 'second')
   endfunction in_data

   pure function anchored(p) result(yes)
   !< Whether a coordinate of `p` is an axis value: the label or arrow moves with the data.
   type(place_object), intent(in) :: p   !< Position.
   logical                        :: yes !< Tied to the data.

   yes = p%sx == 'first' .or. p%sx == 'second' .or. p%sy == 'first' .or. p%sy == 'second'
   endfunction anchored

   pure function unit_of(p, xaxis, yaxis, x2axis, y2axis) result(u)
   !< `p` in the unit square of the plot area (x right, y up); NaN for a value its log axis cannot place.
   type(place_object), intent(in) :: p      !< Position.
   type(axis_object),  intent(in) :: xaxis  !< x axis.
   type(axis_object),  intent(in) :: yaxis  !< y axis.
   type(axis_object),  intent(in) :: x2axis !< x2 axis.
   type(axis_object),  intent(in) :: y2axis !< y2 axis.
   real(R8P)                      :: u(2)   !< Unit coordinates.

   u(1) = coordinate(p%x, p%sx, xaxis, x2axis)
   u(2) = coordinate(p%y, p%sy, yaxis, y2axis)
   contains
      pure function coordinate(v, system, first, second) result(c)
      !< One unit coordinate (graph and screen ones: graph fractions; screen ones converted by `page_of`).
      real(R8P),         intent(in) :: v      !< Value.
      character(len=*),  intent(in) :: system !< System.
      type(axis_object), intent(in) :: first  !< First axis.
      type(axis_object), intent(in) :: second !< Second axis.
      real(R8P)                     :: c      !< Unit coordinate.

      select case (trim(system))
      case ('first')
         c = huge(1.0_R8P)
         if (first%accepts(v)) c = first%to_unit(v)
      case ('second')
         c = huge(1.0_R8P)
         if (second%accepts(v)) c = second%to_unit(v)
      case default
         c = v
      endselect
      endfunction coordinate
   endfunction unit_of

   pure function page_of(p, frame, xaxis, yaxis, x2axis, y2axis) result(xy)
   !< `p` on the page [px, y downward]; huge for an unplaceable value.
   type(place_object), intent(in) :: p      !< Position.
   type(frame_object), intent(in) :: frame  !< Plot area and page.
   type(axis_object),  intent(in) :: xaxis  !< x axis.
   type(axis_object),  intent(in) :: yaxis  !< y axis.
   type(axis_object),  intent(in) :: x2axis !< x2 axis.
   type(axis_object),  intent(in) :: y2axis !< y2 axis.
   real(R8P)                      :: xy(2)  !< Page position [px].
   real(R8P)                      :: u(2)   !< Unit coordinates.

   u = unit_of(p, xaxis, yaxis, x2axis, y2axis)
   if (any(u == huge(1.0_R8P))) then
      xy = huge(1.0_R8P)
      return
   endif
   if (p%sx == 'screen') then
      xy(1) = u(1) * frame%canvas(1)
   elseif (p%sx == 'character') then
      xy(1) = u(1) * frame%cell(1)
   else
      xy(1) = frame%area(1) + u(1) * (frame%area(2) - frame%area(1))
   endif
   if (p%sy == 'screen') then
      xy(2) = (1.0_R8P - u(2)) * frame%canvas(2)
   elseif (p%sy == 'character') then
      xy(2) = frame%canvas(2) - u(2) * frame%cell(2)
   else
      xy(2) = frame%area(4) - u(2) * (frame%area(4) - frame%area(3))
   endif
   endfunction page_of

   subroutine draw_labels(labels, front, backend, area, canvas, font_size, xaxis, yaxis, x2axis, y2axis)
   !< The labels of the layer (`front` or not): text at the position, justified, rotated, moved by the offset; a point
   !< marking the position if so set. Those tied to the data in the `fs-anchored` group (the viewer hides it while
   !< zoomed), the others in `fs-annotations`.
   type(label_object),    intent(in)    :: labels(:) !< Labels.
   logical,               intent(in)    :: front     !< The front layer, else the back one.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: area(4)   !< Plot area: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: canvas(2) !< Page width and height [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   type(axis_object),     intent(in)    :: xaxis     !< x axis.
   type(axis_object),     intent(in)    :: yaxis     !< y axis.
   type(axis_object),     intent(in)    :: x2axis    !< x2 axis.
   type(axis_object),     intent(in)    :: y2axis    !< y2 axis.
   type(frame_object)                   :: frame     !< Plot area and page.
   real(R8P)                            :: xy(2)     !< Position [px].
   real(R8P)                            :: t(2)      !< Text anchor [px].
   integer(I4P)                         :: k         !< Label counter.
   integer(I4P)                         :: pass      !< 1 page labels, 2 anchored ones.

   frame = frame_object(area=area, canvas=canvas, cell=[0.6_R8P * font_size, font_size])
   do pass = 1_I4P, 2_I4P
      if (.not. any([(labels(k)%front .eqv. front .and. (anchored(labels(k)%at) .eqv. pass == 2_I4P), &
                      k = 1_I4P, size(labels, kind=I4P))])) cycle
      call backend%begin_group(trim(merge('fs-anchored   ', 'fs-annotations', pass == 2_I4P)))
      do k = 1_I4P, size(labels, kind=I4P)
         if (labels(k)%front .neqv. front) cycle
         if (anchored(labels(k)%at) .neqv. pass == 2_I4P) cycle
         xy = page_of(labels(k)%at, frame, xaxis, yaxis, x2axis, y2axis)
         if (xy(1) == huge(1.0_R8P)) cycle
         if (labels(k)%point) call backend%dots([xy(1)], [xy(2)], color_of(labels(k)%color), &
                                                0.6_R8P * labels(k)%ps * font_size, pt=labels(k)%pt, line_width=1.0_R8P)
         ! the offset in characters (0.6 of the font size wide, 1 high), the baseline a third of the size down
         t = xy + [labels(k)%offset(1) * 0.6_R8P * font_size, -labels(k)%offset(2) * font_size + 0.35_R8P * font_size]
         backend%boxed = labels(k)%boxed
         if (labels(k)%rotate /= 0.0_R8P .and. backend%rotates_text()) then
            backend%literal = labels(k)%plain
            call backend%text(t(1), t(2), labels(k)%text, anchor_of(labels(k)%justify), rotate=-labels(k)%rotate, &
                              color=color_of(labels(k)%color))
         else
            backend%literal = labels(k)%plain
            ! a text on several lines (`"a\nb"`): the first at the position, the next ones below, as gnuplot
            block
               integer(I4P) :: a    !< Line start.
               integer(I4P) :: e    !< Line end.
               integer(I4P) :: line !< Line counter.

               a = 1_I4P
               line = 0_I4P
               do
                  e = index(labels(k)%text(a:), new_line('a'), kind=I4P)
                  if (e == 0_I4P) then
                     e = len(labels(k)%text, kind=I4P)
                  else
                     e = a + e - 2_I4P
                  endif
                  call backend%text(t(1), t(2) + line * 1.25_R8P * font_size, labels(k)%text(a:e), &
                                    anchor_of(labels(k)%justify), color=color_of(labels(k)%color))
                  a = e + 2_I4P
                  line = line + 1_I4P
                  if (a > len(labels(k)%text, kind=I4P)) exit
               enddo
            endblock
         endif
      enddo
      backend%literal = .false.
      backend%boxed = .false.
      call backend%end_group
   enddo
   endsubroutine draw_labels

   subroutine draw_arrows(arrows, front, backend, area, canvas, font_size, xaxis, yaxis, x2axis, y2axis)
   !< The arrows of the layer (`front` or not): a shaft from the tail to the tip, heads as set (`nofilled` two barbs,
   !< `filled`, `empty`, `noborder` a triangle). Those tied to the data in the `fs-anchored` group.
   type(arrow_object),    intent(in)    :: arrows(:) !< Arrows.
   logical,               intent(in)    :: front     !< The front layer, else the back one.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: area(4)   !< Plot area: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: canvas(2) !< Page width and height [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   type(axis_object),     intent(in)    :: xaxis     !< x axis.
   type(axis_object),     intent(in)    :: yaxis     !< y axis.
   type(axis_object),     intent(in)    :: x2axis    !< x2 axis.
   type(axis_object),     intent(in)    :: y2axis    !< y2 axis.
   type(frame_object)                   :: frame     !< Plot area and page.
   type(place_object)                   :: tip       !< Tip position.
   real(R8P)                            :: a(2)      !< Tail [px].
   real(R8P)                            :: b(2)      !< Tip [px].
   integer(I4P)                         :: k         !< Arrow counter.
   integer(I4P)                         :: pass      !< 1 page arrows, 2 anchored ones.
   logical                              :: tied      !< Tied to the data.

   frame = frame_object(area=area, canvas=canvas, cell=[0.6_R8P * font_size, font_size])
   do pass = 1_I4P, 2_I4P
      if (.not. any([(arrows(k)%front .eqv. front .and. ((anchored(arrows(k)%from) .or. anchored(arrows(k)%to)) &
                      .eqv. pass == 2_I4P), k = 1_I4P, size(arrows, kind=I4P))])) cycle
      call backend%begin_group(trim(merge('fs-anchored   ', 'fs-annotations', pass == 2_I4P)))
      do k = 1_I4P, size(arrows, kind=I4P)
         if (arrows(k)%front .neqv. front) cycle
         tied = anchored(arrows(k)%from) .or. anchored(arrows(k)%to)
         if (tied .neqv. pass == 2_I4P) cycle
         a = page_of(arrows(k)%from, frame, xaxis, yaxis, x2axis, y2axis)
         tip = arrows(k)%to
         if (arrows(k)%relative) then
            ! rto: the tip from the tail, in the tip's systems (axis values added before the mapping)
            tip%x = arrows(k)%from%x + arrows(k)%to%x
            tip%y = arrows(k)%from%y + arrows(k)%to%y
            if (tip%sx /= arrows(k)%from%sx) tip%sx = arrows(k)%from%sx
            if (tip%sy /= arrows(k)%from%sy) tip%sy = arrows(k)%from%sy
         endif
         b = page_of(tip, frame, xaxis, yaxis, x2axis, y2axis)
         if (arrows(k)%polar .and. all(a /= huge(1.0_R8P))) b = polar_tip(arrows(k), a)
         if (any(a == huge(1.0_R8P)) .or. any(b == huge(1.0_R8P))) cycle
         call backend%polyline([a(1), b(1)], [a(2), b(2)], color_of(arrows(k)%color), arrows(k)%lw, dashes_of(arrows(k)))
         if (arrows(k)%head == 1_I4P .or. arrows(k)%head == 3_I4P) call head(arrows(k), a, b)
         if (arrows(k)%head == 2_I4P .or. arrows(k)%head == 3_I4P) call head(arrows(k), b, a)
      enddo
      call backend%end_group
   enddo
   contains
      function polar_tip(arrow, tail) result(tip_px)
      !< The tip of `arrow` given by a length and an angle (gnuplot `length L angle A`): the length along x in its
      !< system, the angle on the page, from the tail [px].
      type(arrow_object), intent(in) :: arrow     !< Arrow.
      real(R8P),          intent(in) :: tail(2)   !< Tail [px].
      real(R8P)                      :: tip_px(2) !< Tip [px].
      type(place_object)             :: p         !< Tail and tail plus the length, along x.
      real(R8P)                      :: q(2)      !< Page point of the latter [px].
      real(R8P)                      :: length    !< Length [px].
      real(R8P), parameter           :: PI = acos(-1.0_R8P) !< pi.

      select case (trim(arrow%span_system))
      case ('first', 'second')
         ! axis units: the page distance of the tail moved by the length
         p = arrow%from
         p%x = arrow%from%x + arrow%span
         q = page_of(p, frame, xaxis, yaxis, x2axis, y2axis)
         length = sign(abs(q(1) - tail(1)), arrow%span)
      case ('graph')
         length = arrow%span * (frame%area(2) - frame%area(1))
      case ('screen')
         length = arrow%span * frame%canvas(1)
      case default
         length = arrow%span * frame%cell(1)
      endselect
      tip_px = [tail(1) + length * cos(arrow%direction * PI / 180.0_R8P), &
                tail(2) - length * sin(arrow%direction * PI / 180.0_R8P)]
      endfunction polar_tip

      subroutine head(arrow, tail, point)
      !< The head of `arrow` at `point`, the shaft coming from `tail`.
      type(arrow_object), intent(in) :: arrow   !< Arrow.
      real(R8P),          intent(in) :: tail(2) !< Shaft start [px].
      real(R8P),          intent(in) :: point(2) !< Head point [px].
      real(R8P)                      :: barbs(2, 2) !< Barb ends [px].
      real(R8P)                      :: length  !< Head length [px].
      real(R8P)                      :: d       !< Shaft direction, point to tail [rad].
      real(R8P)                      :: h       !< Barb angle [rad].
      character(len=:), allocatable  :: color   !< Color.

      color = color_of(arrow%color)
      if (arrow%length > 0.0_R8P) then
         select case (trim(arrow%length_system))
         case ('graph')
            length = arrow%length * (area(2) - area(1))
         case ('screen')
            length = arrow%length * canvas(1)
         case ('character')
            length = arrow%length * frame%cell(1)
         case default
            ! x axis values: the length of that span on the x axis
            length = abs(arrow%length / (xaxis%hi - xaxis%lo)) * (area(2) - area(1))
            if (xaxis%log) length = abs(arrow%length / (log10(xaxis%hi) - log10(xaxis%lo))) * (area(2) - area(1))
         endselect
         d = 0.0_R8P
         if (any(point /= tail)) d = atan2(tail(2) - point(2), tail(1) - point(1))
         h = arrow%angle * PI / 180.0_R8P
         barbs(:, 1) = point + length * [cos(d + h), sin(d + h)]
         barbs(:, 2) = point + length * [cos(d - h), sin(d - h)]
      else
         call arrow_head(tail, point, barbs)
      endif
      select case (trim(arrow%fill))
      case ('filled')
         call backend%polygon([barbs(1, 1), point(1), barbs(1, 2)], [barbs(2, 1), point(2), barbs(2, 2)], color, &
                              1.0_R8P, color, arrow%lw)
      case ('noborder')
         call backend%polygon([barbs(1, 1), point(1), barbs(1, 2)], [barbs(2, 1), point(2), barbs(2, 2)], color, &
                              1.0_R8P, 'none', arrow%lw)
      case ('empty')
         call backend%polygon([barbs(1, 1), point(1), barbs(1, 2)], [barbs(2, 1), point(2), barbs(2, 2)], 'none', &
                              1.0_R8P, color, arrow%lw)
      case default
         call backend%polyline([barbs(1, 1), point(1), barbs(1, 2)], [barbs(2, 1), point(2), barbs(2, 2)], color, &
                               arrow%lw, '')
      endselect
      endsubroutine head
   endsubroutine draw_arrows

   subroutine draw_pixmaps(pixmaps, layer, backend, area, canvas, font_size, xaxis, yaxis, x2axis, y2axis)
   !< The pixmaps of `layer` (`behind`, `back`, `front`), gnuplot `set pixmap`: each PNG at its position (its lower left
   !< corner, or its centre), its own pixels large, or `size` W,H, or `width` W (or `height` H) the other side by its
   !< aspect; W and H in their systems (`first` and `second` measured from the position, `graph`, `screen` fractions,
   !< `character` cells). Those tied to the data in the `fs-anchored` group (hidden by the viewer while zoomed).
   type(pixmap_object),   intent(in)    :: pixmaps(:) !< Pixmaps.
   character(len=*),      intent(in)    :: layer      !< Layer.
   class(backend_object), intent(inout) :: backend    !< Output device.
   real(R8P),             intent(in)    :: area(4)    !< Plot area: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: canvas(2)  !< Page width and height [px].
   real(R8P),             intent(in)    :: font_size  !< Font size [px].
   type(axis_object),     intent(in)    :: xaxis      !< x axis.
   type(axis_object),     intent(in)    :: yaxis      !< y axis.
   type(axis_object),     intent(in)    :: x2axis     !< x2 axis.
   type(axis_object),     intent(in)    :: y2axis     !< y2 axis.
   type(frame_object)                   :: frame      !< Plot area and page.
   real(R8P)                            :: xy(2)      !< Position [px].
   real(R8P)                            :: wh(2)      !< Width and height [px].
   integer(I4P)                         :: k          !< Pixmap counter.
   integer(I4P)                         :: pass       !< 1 page pixmaps, 2 anchored ones.

   frame = frame_object(area=area, canvas=canvas, cell=[0.6_R8P * font_size, font_size])
   do pass = 1_I4P, 2_I4P
      if (.not. any([(trim(pixmaps(k)%layer) == layer .and. (anchored(pixmaps(k)%at) .eqv. pass == 2_I4P), &
                      k = 1_I4P, size(pixmaps, kind=I4P))])) cycle
      if (pass == 2_I4P) call backend%begin_group('fs-anchored')
      do k = 1_I4P, size(pixmaps, kind=I4P)
         if (trim(pixmaps(k)%layer) /= layer) cycle
         if (anchored(pixmaps(k)%at) .neqv. pass == 2_I4P) cycle
         if (.not. allocated(pixmaps(k)%png) .or. any(pixmaps(k)%pixels <= 0_I4P)) cycle
         xy = page_of(pixmaps(k)%at, frame, xaxis, yaxis, x2axis, y2axis)
         if (xy(1) == huge(1.0_R8P)) cycle
         wh = real(pixmaps(k)%pixels, R8P)
         if (pixmaps(k)%sized > 0_I4P) then
            wh = span_of(pixmaps(k)%at, pixmaps(k)%span, frame, xaxis, yaxis, x2axis, y2axis)
            if (pixmaps(k)%sized == 2_I4P) wh(2) = wh(1) * real(pixmaps(k)%pixels(2), R8P) / &
                                                   real(pixmaps(k)%pixels(1), R8P)
            if (pixmaps(k)%sized == 3_I4P) wh(1) = wh(2) * real(pixmaps(k)%pixels(1), R8P) / &
                                                   real(pixmaps(k)%pixels(2), R8P)
         endif
         if (pixmaps(k)%center) then
            call backend%pixmap(xy(1) - 0.5_R8P * wh(1), xy(2) - 0.5_R8P * wh(2), wh(1), wh(2), pixmaps(k)%png)
         else
            call backend%pixmap(xy(1), xy(2) - wh(2), wh(1), wh(2), pixmaps(k)%png)
         endif
      enddo
      if (pass == 2_I4P) call backend%end_group
   enddo
   endsubroutine draw_pixmaps

   pure function span_of(centre, span, frame, xaxis, yaxis, x2axis, y2axis) result(size_px)
   !< The page size [px] of a width and height `span` (its systems in `sx`, `sy`) about `centre`: axis values measured
   !< across the centre (a log axis included), graph and screen ones as fractions, character ones in cells.
   type(place_object), intent(in) :: centre     !< Centre.
   type(place_object), intent(in) :: span       !< Width and height.
   type(frame_object), intent(in) :: frame      !< Plot area and page.
   type(axis_object),  intent(in) :: xaxis      !< x axis.
   type(axis_object),  intent(in) :: yaxis      !< y axis.
   type(axis_object),  intent(in) :: x2axis     !< x2 axis.
   type(axis_object),  intent(in) :: y2axis     !< y2 axis.
   real(R8P)                      :: size_px(2) !< Width and height [px].
   type(place_object)             :: lo         !< Lower corner.
   type(place_object)             :: hi         !< Upper corner.
   real(R8P)                      :: a(2)       !< Lower corner [px].
   real(R8P)                      :: b(2)       !< Upper corner [px].

   lo = centre
   hi = centre
   lo%sx = span%sx
   hi%sx = span%sx
   lo%sy = span%sy
   hi%sy = span%sy
   if (span%sx == centre%sx) then
      lo%x = centre%x - 0.5_R8P * span%x
      hi%x = centre%x + 0.5_R8P * span%x
   else
      lo%x = 0.0_R8P
      hi%x = span%x
   endif
   if (span%sy == centre%sy) then
      lo%y = centre%y - 0.5_R8P * span%y
      hi%y = centre%y + 0.5_R8P * span%y
   else
      lo%y = 0.0_R8P
      hi%y = span%y
   endif
   a = page_of(lo, frame, xaxis, yaxis, x2axis, y2axis)
   b = page_of(hi, frame, xaxis, yaxis, x2axis, y2axis)
   size_px = abs(b - a)
   endfunction span_of

   pure function in_space(shape) result(yes)
   !< Whether `shape` is drawn in data space: clipped, every point (and the size) in axis values.
   type(shape_object), intent(in) :: shape !< Object.
   logical                        :: yes   !< In data space.
   integer(I4P)                   :: i     !< Point counter.

   yes = shape%clip .and. allocated(shape%points)
   if (.not. yes) return
   do i = 1_I4P, size(shape%points, kind=I4P)
      yes = yes .and. in_data(shape%points(i))
   enddo
   endfunction in_space

   pure function has_shapes(shapes, layer, data_space) result(yes)
   !< Whether any of `shapes` is of `layer` and in data space (`data_space`), or on the page.
   type(shape_object), intent(in) :: shapes(:)  !< Objects.
   character(len=*),   intent(in) :: layer      !< Layer.
   logical,            intent(in) :: data_space !< The data space ones, else the page ones.
   logical                        :: yes        !< Any.
   integer(I4P)                   :: k          !< Object counter.

   yes = .false.
   do k = 1_I4P, size(shapes, kind=I4P)
      if (trim(shapes(k)%layer) /= layer) cycle
      if (in_space(shapes(k)) .eqv. data_space) then
         yes = .true.
         return
      endif
   enddo
   endfunction has_shapes

   subroutine draw_shapes(shapes, layer, data_space, backend, area, canvas, font_size, xaxis, yaxis, x2axis, y2axis)
   !< The objects of `layer` (`behind`, `back`, `front`), those in data space (`data_space`: clipped, both coordinates
   !< axis values, drawn in the unit square) or the others (on the page): rectangles, circles (an arc and its centre
   !< for a partial one), ellipses, polygons, in their fill and border.
   type(shape_object),    intent(in)    :: shapes(:)  !< Objects.
   character(len=*),      intent(in)    :: layer      !< Layer.
   logical,               intent(in)    :: data_space !< The data space ones, else the page ones.
   class(backend_object), intent(inout) :: backend    !< Output device.
   real(R8P),             intent(in)    :: area(4)    !< Plot area: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: canvas(2)  !< Page width and height [px].
   real(R8P),             intent(in)    :: font_size  !< Font size [px].
   type(axis_object),     intent(in)    :: xaxis      !< x axis.
   type(axis_object),     intent(in)    :: yaxis      !< y axis.
   type(axis_object),     intent(in)    :: x2axis     !< x2 axis.
   type(axis_object),     intent(in)    :: y2axis     !< y2 axis.
   type(frame_object)                   :: frame      !< Plot area and page.
   real(R8P), allocatable               :: px(:)      !< Outline [px].
   real(R8P), allocatable               :: py(:)      !< Outline [px].
   integer(I4P)                         :: k          !< Object counter.
   logical                              :: drawn      !< A group opened.
   character(len=:), allocatable        :: dashes     !< Border dash array, empty for solid.

   frame = frame_object(area=area, canvas=canvas, cell=[0.6_R8P * font_size, font_size])
   drawn = .false.
   do k = 1_I4P, size(shapes, kind=I4P)
      if (trim(shapes(k)%layer) /= layer) cycle
      if (in_space(shapes(k)) .neqv. data_space) cycle
      call outline(shapes(k), px, py)
      if (size(px) < 2) cycle
      if (.not. drawn) then
         call backend%begin_group('fs-objects')
         drawn = .true.
      endif
      associate(style => shapes(k)%style)
         ! a dashed border: the fill, then the outline closed as a dashed line
         dashes = ''
         if (style%dashtype /= 1_I4P .and. style%stroke_color() /= 'none') dashes = style%dasharray()
         if (data_space) then
            ! back to the unit square of the plot area
            px = (px - area(1)) / (area(2) - area(1))
            py = (area(4) - py) / (area(4) - area(3))
            if (len(dashes) > 0) then
               call backend%data_polygon(px, py, style%fill_color(), style%density, 'none', style%linewidth)
               call backend%data_polyline([px, px(1)], [py, py(1)], style%stroke_color(), style%linewidth, dashes)
            else
               call backend%data_polygon(px, py, style%fill_color(), style%density, style%stroke_color(), &
                                         style%linewidth)
            endif
         elseif (len(dashes) > 0) then
            call backend%polygon(px, py, style%fill_color(), style%density, 'none', style%linewidth)
            call backend%polyline([px, px(1)], [py, py(1)], style%stroke_color(), style%linewidth, dashes)
         else
            call backend%polygon(px, py, style%fill_color(), style%density, style%stroke_color(), style%linewidth)
         endif
      endassociate
   enddo
   if (drawn) call backend%end_group
   contains
      subroutine outline(shape, px, py)
      !< The outline of `shape` on the page [px], empty if a point is unplaceable.
      type(shape_object),     intent(in)  :: shape !< Object.
      real(R8P), allocatable, intent(out) :: px(:) !< Abscissae [px].
      real(R8P), allocatable, intent(out) :: py(:) !< Ordinates [px].
      real(R8P)                           :: c(2)  !< Centre or corner [px].
      real(R8P)                           :: e(2)  !< Opposite corner [px].
      real(R8P)                           :: half(2) !< Half size [px].
      real(R8P)                           :: t     !< Angle [rad].
      real(R8P)                           :: r     !< Radius [px].
      integer(I4P)                        :: i     !< Point counter.
      integer(I4P)                        :: m     !< Arc steps.
      type(place_object)                  :: corner !< A corner from the centre and size.

      allocate(px(0), py(0))
      if (.not. allocated(shape%points)) return
      if (size(shape%points) == 0) return
      c = page_of(shape%points(1), frame, xaxis, yaxis, x2axis, y2axis)
      if (any(c == huge(1.0_R8P))) return
      select case (trim(shape%kind))
      case ('rectangle')
         if (shape%sized) then
            half = 0.5_R8P * extent(shape%points(1), shape%size)
            px = [c(1) - half(1), c(1) + half(1), c(1) + half(1), c(1) - half(1)]
            py = [c(2) + half(2), c(2) + half(2), c(2) - half(2), c(2) - half(2)]
         else
            if (size(shape%points) < 2) return
            e = page_of(shape%points(2), frame, xaxis, yaxis, x2axis, y2axis)
            if (any(e == huge(1.0_R8P))) return
            px = [c(1), e(1), e(1), c(1)]
            py = [c(2), c(2), e(2), e(2)]
         endif
         corner = shape%points(1)
      case ('circle')
         ! the radius along x, round on the page; an arc: a wedge from the centre
         half = extent(shape%points(1), place_object(x=2.0_R8P * shape%size%x, y=2.0_R8P * shape%size%x, &
                                                     sx=shape%size%sx, sy=shape%size%sx))
         r = 0.5_R8P * half(1)
         m = max(2_I4P, nint(64.0_R8P * abs(shape%arc(2) - shape%arc(1)) / 360.0_R8P, I4P))
         deallocate(px, py)
         allocate(px(m + 1), py(m + 1))
         do i = 0_I4P, m
            t = (shape%arc(1) + (shape%arc(2) - shape%arc(1)) * real(i, R8P) / real(m, R8P)) * PI / 180.0_R8P
            px(i + 1_I4P) = c(1) + r * cos(t)
            py(i + 1_I4P) = c(2) - r * sin(t)
         enddo
         if (abs(shape%arc(2) - shape%arc(1)) < 360.0_R8P) then
            px = [c(1), px]
            py = [c(2), py]
         endif
      case ('ellipse')
         ! the axes in the units of the size (x then y), rotated in those units, as gnuplot's `units xy`
         deallocate(px, py)
         allocate(px(65), py(65))
         do i = 0_I4P, 64_I4P
            t = 2.0_R8P * PI * real(i, R8P) / 64.0_R8P
            corner = shape%points(1)
            associate(a => 0.5_R8P * shape%size%x, b => 0.5_R8P * shape%size%y, s => sin(shape%angle * PI / 180.0_R8P), &
                      q => cos(shape%angle * PI / 180.0_R8P))
               corner%x = shape%points(1)%x + a * cos(t) * q - b * sin(t) * s
               corner%y = shape%points(1)%y + a * cos(t) * s + b * sin(t) * q
            endassociate
            e = page_of(corner, frame, xaxis, yaxis, x2axis, y2axis)
            if (any(e == huge(1.0_R8P))) then
               deallocate(px, py)
               allocate(px(0), py(0))
               return
            endif
            px(i + 1_I4P) = e(1)
            py(i + 1_I4P) = e(2)
         enddo
      case ('polygon')
         deallocate(px, py)
         allocate(px(size(shape%points)), py(size(shape%points)))
         do i = 1_I4P, size(shape%points, kind=I4P)
            e = page_of(shape%points(i), frame, xaxis, yaxis, x2axis, y2axis)
            if (any(e == huge(1.0_R8P))) then
               deallocate(px, py)
               allocate(px(0), py(0))
               return
            endif
            px(i) = e(1)
            py(i) = e(2)
         enddo
      endselect
      endsubroutine outline

      pure function extent(centre, span) result(size_px)
      !< The page size [px] of a width and height `span` (its systems in `sx`, `sy`) about `centre`: axis values
      !< measured across the centre (a log axis included), graph and screen ones as fractions.
      type(place_object), intent(in) :: centre     !< Centre.
      type(place_object), intent(in) :: span       !< Width and height.
      real(R8P)                      :: size_px(2) !< Width and height [px].
      type(place_object)             :: lo         !< Lower corner.
      type(place_object)             :: hi         !< Upper corner.
      real(R8P)                      :: a(2)       !< Lower corner [px].
      real(R8P)                      :: b(2)       !< Upper corner [px].

      lo = centre
      hi = centre
      lo%sx = span%sx
      hi%sx = span%sx
      lo%sy = span%sy
      hi%sy = span%sy
      if (span%sx == centre%sx) then
         lo%x = centre%x - 0.5_R8P * span%x
         hi%x = centre%x + 0.5_R8P * span%x
      else
         lo%x = 0.0_R8P
         hi%x = span%x
      endif
      if (span%sy == centre%sy) then
         lo%y = centre%y - 0.5_R8P * span%y
         hi%y = centre%y + 0.5_R8P * span%y
      else
         lo%y = 0.0_R8P
         hi%y = span%y
      endif
      a = page_of(lo, frame, xaxis, yaxis, x2axis, y2axis)
      b = page_of(hi, frame, xaxis, yaxis, x2axis, y2axis)
      size_px = abs(b - a)
      endfunction extent
   endsubroutine draw_shapes

   pure function color_of(color) result(c)
   !< `color`, the frame's if unallocated or empty.
   character(len=:), allocatable, intent(in) :: color !< Color.
   character(len=:), allocatable             :: c     !< Color.

   c = FRAME_COLOR
   if (allocated(color)) then
      if (len(color) > 0) c = color
   endif
   endfunction color_of

   pure function dashes_of(arrow) result(d)
   !< SVG dash array of `arrow`, empty for solid.
   type(arrow_object), intent(in) :: arrow !< Arrow.
   character(len=:), allocatable  :: d     !< Dash array.

   d = ''
   if (allocated(arrow%dashes)) d = arrow%dashes
   endfunction dashes_of

   pure function anchor_of(justify) result(anchor)
   !< SVG text anchor of a justification.
   character(len=*), intent(in)  :: justify !< `left`, `center`, `right`.
   character(len=:), allocatable :: anchor  !< `start`, `middle`, `end`.

   select case (trim(justify))
   case ('center')
      anchor = 'middle'
   case ('right')
      anchor = 'end'
   case default
      anchor = 'start'
   endselect
   endfunction anchor_of

   pure subroutine push_label(list, item)
   !< Append `item` to `list` through a temporary.
   type(label_object), allocatable, intent(inout) :: list(:)  !< List.
   type(label_object),              intent(in)    :: item     !< New item.
   type(label_object), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                   :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_label

   pure subroutine push_arrow(list, item)
   !< Append `item` to `list` through a temporary.
   type(arrow_object), allocatable, intent(inout) :: list(:)  !< List.
   type(arrow_object),              intent(in)    :: item     !< New item.
   type(arrow_object), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                   :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_arrow

   pure subroutine push_pixmap(list, item)
   !< Append `item` to `list`.
   type(pixmap_object), allocatable, intent(inout) :: list(:) !< List.
   type(pixmap_object),              intent(in)    :: item    !< Item.
   type(pixmap_object), allocatable                :: grown(:) !< Longer list.
   integer(I4P)                                    :: k        !< Counter.

   if (.not. allocated(list)) allocate(list(0))
   allocate(grown(size(list) + 1))
   do k = 1_I4P, size(list, kind=I4P)
      grown(k) = list(k)
   enddo
   grown(size(grown)) = item
   call move_alloc(grown, list)
   endsubroutine push_pixmap

   pure subroutine push_shape(list, item)
   !< Append `item` to `list` through a temporary.
   type(shape_object), allocatable, intent(inout) :: list(:)  !< List.
   type(shape_object),              intent(in)    :: item     !< New item.
   type(shape_object), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                   :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_shape
endmodule foresight_annotations
