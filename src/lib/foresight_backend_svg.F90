!< foresight_backend_svg, SVG output device.
module foresight_backend_svg
!< foresight_backend_svg, SVG output device.
!<
!< The document is streamed to `<file>.tmp` and renamed over `<file>` when the page ends, so a viewer polling `<file>`
!< never reads a partial document. The plot area is a nested `<svg class="fs-plot">` whose `viewBox` is the unit square:
!< data geometry lives in unit coordinates, and `vector-effect="non-scaling-stroke"` keeps its line widths in pixels.
!< Panels are `<g class="fs-axes">` carrying their geometry and axis ranges as `data-*` attributes; decorations the
!< interactive viewer regenerates are `<g class="fs-...">` groups. The second y axis and the mirror settings add their
!< attributes only when active or not the default, so a plain panel reads the same as before them.
use foresight_backend, only : axes_view, backend_object
use foresight_format, only : fixed, int_str, real_str, xml_escape
use foresight_sys, only : rename_file
use penf, only : I4P, I8P, R8P

implicit none
private
public :: backend_svg

integer(I4P),     parameter :: PX_DECIMALS    = 2_I4P                        !< Decimals of pixel coordinates.
integer(I4P),     parameter :: UNIT_DECIMALS  = 6_I4P                        !< Decimals of unit-square coordinates.
integer(I4P),     parameter :: PAIRS_PER_LINE = 8_I4P                        !< Coordinate pairs per output line.
character(len=*), parameter :: FONT_FAMILY    = 'Arial,Helvetica,sans-serif' !< Default font family.
! readout geometry, in digit heights
real(R8P),        parameter :: DIGIT_WIDTH    = 0.52_R8P   !< Digit width, between the vertical segment axes.
real(R8P),        parameter :: DIGIT_PITCH    = 0.86_R8P   !< Distance between the cells.
real(R8P),        parameter :: SEGMENT_WIDTH  = 0.13_R8P   !< Segment thickness, also the decimal point side.
real(R8P),        parameter :: POINT_OFFSET   = 0.64_R8P   !< Decimal point left side, from its cell.
real(R8P),        parameter :: SLANT          = 0.14054_R8P !< Slant: tan(8 deg), the bottom shifted left.
real(R8P),        parameter :: SEGMENT_GAP    = 0.35_R8P   !< Gap between segment ends [segment thickness].
character(len=*), parameter :: GHOST_OPACITY  = '0.07'     !< Opacity of the unlit segments.

type, extends(backend_object) :: backend_svg
   !< SVG output device.
   private
   integer(I4P)                  :: unit = -1_I4P !< Output unit.
   character(len=:), allocatable :: file          !< Final output file.
   character(len=:), allocatable :: tmp_file      !< File being written.
   real(R8P)                     :: area(4) = 0.0_R8P !< Current plot area: left, top, width, height [px].
   character(len=:), allocatable :: caps          !< Error bar caps of the current plot area, pixel overlay.
   character(len=:), allocatable :: marks         !< Point type markers of the current plot area, pixel overlay.
   integer(I4P)                  :: series = 0_I4P !< Series of the open group, 0 for none.
   contains
      ! deferred bindings
      procedure, pass(self) :: begin_page
      procedure, pass(self) :: end_page
      procedure, pass(self) :: begin_axes
      procedure, pass(self) :: end_axes
      procedure, pass(self) :: begin_group
      procedure, pass(self) :: end_group
      procedure, pass(self) :: rect
      procedure, pass(self) :: polyline
      procedure, pass(self) :: dots
      procedure, pass(self) :: polygon
      procedure, pass(self) :: text
      procedure, pass(self) :: begin_plot_area
      procedure, pass(self) :: end_plot_area
      procedure, pass(self) :: data_polyline
      procedure, pass(self) :: data_dots
      procedure, pass(self) :: data_bars
      procedure, pass(self) :: data_polygon
      procedure, pass(self) :: text_width
      procedure, pass(self) :: readout
      procedure, pass(self) :: readout_extent
      ! building blocks for extending devices
      procedure, pass(self) :: close_file  !< Close the stream and publish the file atomically.
      procedure, pass(self) :: open_file   !< Open the stream on `<file>.tmp`.
      procedure, pass(self) :: open_svg    !< Write the root `<svg>` start tag.
      procedure, pass(self) :: output_unit !< Unit of the open stream.
      procedure, pass(self) :: put         !< Write a line.
      procedure, pass(self), private :: write_pairs !< Write coordinate pairs.
endtype backend_svg

contains
   ! deferred bindings
   subroutine begin_page(self, file, width, height, font_size)
   !< Open the output `file` with a page of `width` x `height` px and the default `font_size` [px].
   class(backend_svg), intent(inout) :: self      !< Device.
   character(len=*),   intent(in)    :: file      !< Output file.
   real(R8P),          intent(in)    :: width     !< Page width [px].
   real(R8P),          intent(in)    :: height    !< Page height [px].
   real(R8P),          intent(in)    :: font_size !< Default font size [px].

   call self%open_file(file)
   call self%put('<?xml version="1.0" encoding="UTF-8" standalone="no"?>')
   call self%open_svg(width, height, font_size)
   endsubroutine begin_page

   subroutine end_page(self)
   !< Close the document and publish it atomically.
   class(backend_svg), intent(inout) :: self !< Device.

   call self%put('</svg>')
   call self%close_file
   endsubroutine end_page

   subroutine begin_axes(self, view)
   !< Open a panel group carrying geometry and axis ranges as `data-*` attributes.
   class(backend_svg), intent(inout) :: self  !< Device.
   type(axes_view),    intent(in)    :: view  !< Panel geometry and axis ranges.
   character(len=:), allocatable     :: extra !< Tick settings attributes, only when set.

   character(len=:), allocatable     :: y2    !< Second y axis attributes, only when active.
   character(len=:), allocatable     :: logs  !< Log flags: x, y, and y2 when active.

   extra = attribute('data-xtics', view%xtics)//attribute('data-ytics', view%ytics)// &
           attribute('data-xformat', view%xformat)//attribute('data-yformat', view%yformat)
   if (any(view%mirror .neqv. [.true., .true., .false.])) &
      extra = extra//' data-mirror="'//flag(view%mirror(1))//' '//flag(view%mirror(2))//' '//flag(view%mirror(3))//'"'
   y2 = ''
   logs = flag(view%xlog)//' '//flag(view%ylog)
   if (view%y2_active) then
      y2 = ' data-y2="'//real_str(view%y2(1))//' '//real_str(view%y2(2))//'"'
      logs = logs//' '//flag(view%y2log)
      extra = extra//attribute('data-y2tics', view%y2tics)//attribute('data-y2format', view%y2format)
   endif
   call self%put('<g class="fs-axes" data-area="'//px(view%area(1))//' '//px(view%area(2))//' '//px(view%area(3))// &
                 ' '//px(view%area(4))//'" data-x="'//real_str(view%x(1))//' '//real_str(view%x(2))// &
                 '" data-y="'//real_str(view%y(1))//' '//real_str(view%y(2))//'"'//y2//' data-log="'//logs// &
                 '" data-grid="'//flag(view%grid)//'" data-font-size="'//px(view%font_size)//'"'//extra//'>')
   contains
      pure function attribute(name, value) result(text)
      !< ` name="value"` (XML escaped), or nothing if `value` is unallocated or empty.
      character(len=*),              intent(in) :: name  !< Attribute name.
      character(len=:), allocatable, intent(in) :: value !< Attribute value.
      character(len=:), allocatable             :: text  !< Attribute text.

      text = ''
      if (.not. allocated(value)) return
      if (len(value) > 0) text = ' '//name//'="'//xml_escape(value)//'"'
      endfunction attribute
   endsubroutine begin_axes

   subroutine end_axes(self)
   !< Close the panel group.
   class(backend_svg), intent(inout) :: self !< Device.

   call self%put('</g>')
   endsubroutine end_axes

   subroutine begin_group(self, name, visible, series)
   !< Open the group of class `name`; hidden with `display="none"` when `visible` is false; a series group carries its
   !< number as `data-series`, as do its overlay markers and caps.
   class(backend_svg), intent(inout)        :: self    !< Device.
   character(len=*),   intent(in)           :: name    !< Group name.
   logical,            intent(in), optional :: visible !< Group shown.
   integer(I4P),       intent(in), optional :: series  !< Series number.
   character(len=:), allocatable            :: line    !< Output line.

   line = '<g class="'//name//'"'
   if (present(visible)) then
      if (.not. visible) line = line//' display="none"'
   endif
   self%series = 0_I4P
   if (present(series)) then
      self%series = series
      line = line//series_attribute(series)
   endif
   call self%put(line//'>')
   endsubroutine begin_group

   subroutine end_group(self)
   !< Close the group.
   class(backend_svg), intent(inout) :: self !< Device.

   self%series = 0_I4P
   call self%put('</g>')
   endsubroutine end_group

   subroutine rect(self, x, y, width, height, stroke, fill, line_width)
   !< Rectangle of top-left corner (`x`, `y`) [px].
   class(backend_svg), intent(inout) :: self       !< Device.
   real(R8P),          intent(in)    :: x          !< Left side [px].
   real(R8P),          intent(in)    :: y          !< Top side [px].
   real(R8P),          intent(in)    :: width      !< Width [px].
   real(R8P),          intent(in)    :: height     !< Height [px].
   character(len=*),   intent(in)    :: stroke     !< Stroke color.
   character(len=*),   intent(in)    :: fill       !< Fill color.
   real(R8P),          intent(in)    :: line_width !< Stroke width [px].

   call self%put('<rect x="'//px(x)//'" y="'//px(y)//'" width="'//px(width)//'" height="'//px(height)// &
                 '" fill="'//fill//'" stroke="'//stroke//'" stroke-width="'//px(line_width)//'"/>')
   endsubroutine rect

   subroutine polyline(self, x, y, color, line_width, dasharray)
   !< Open polyline through the points (`x`, `y`) [px].
   class(backend_svg), intent(inout) :: self       !< Device.
   real(R8P),          intent(in)    :: x(:)       !< Abscissae [px].
   real(R8P),          intent(in)    :: y(:)       !< Ordinates [px].
   character(len=*),   intent(in)    :: color      !< Stroke color.
   real(R8P),          intent(in)    :: line_width !< Stroke width [px].
   character(len=*),   intent(in)    :: dasharray  !< SVG dash array, empty for solid.

   write(self%unit, '(A)', advance='no') '<polyline fill="none" stroke="'//color//'" stroke-width="'// &
                                         px(line_width)//'"'//dash_attribute(dasharray)//' points="'
   call self%write_pairs(x, y, PX_DECIMALS, '', '')
   call self%put('"/>')
   endsubroutine polyline

   subroutine dots(self, x, y, color, diameter, pt, line_width)
   !< Filled round dots centred on the points (`x`, `y`) [px], or point type markers.
   class(backend_svg), intent(inout)        :: self       !< Device.
   real(R8P),          intent(in)           :: x(:)       !< Abscissae [px].
   real(R8P),          intent(in)           :: y(:)       !< Ordinates [px].
   character(len=*),   intent(in)           :: color      !< Fill color.
   real(R8P),          intent(in)           :: diameter   !< Dot diameter, or marker width [px].
   integer(I4P),       intent(in), optional :: pt         !< gnuplot point type; negative or absent: round dots.
   real(R8P),          intent(in), optional :: line_width !< Marker line width [px].

   if (present(pt)) then
      if (pt >= 0_I4P) then
         call self%put(marker_element(x, y, color, diameter, pt, line_width))
         return
      endif
   endif
   ! a zero-length subpath with round caps renders as a dot of diameter stroke-width
   write(self%unit, '(A)', advance='no') '<path fill="none" stroke="'//color//'" stroke-width="'//px(diameter)// &
                                         '" stroke-linecap="round" d="'
   call self%write_pairs(x, y, PX_DECIMALS, 'M', 'h0')
   call self%put('"/>')
   endsubroutine dots

   subroutine polygon(self, x, y, fill, opacity, stroke, line_width)
   !< Closed polygon of the vertices (`x`, `y`) [px], filled and stroked.
   class(backend_svg), intent(inout) :: self       !< Device.
   real(R8P),          intent(in)    :: x(:)       !< Vertex abscissae [px].
   real(R8P),          intent(in)    :: y(:)       !< Vertex ordinates [px].
   character(len=*),   intent(in)    :: fill       !< Fill color.
   real(R8P),          intent(in)    :: opacity    !< Fill opacity.
   character(len=*),   intent(in)    :: stroke     !< Border color.
   real(R8P),          intent(in)    :: line_width !< Border width [px].

   write(self%unit, '(A)', advance='no') '<path'//paint(fill, opacity, stroke, line_width)//' d="M'
   call self%write_pairs(x, y, PX_DECIMALS, '', '')
   call self%put('Z"/>')
   endsubroutine polygon

   subroutine text(self, x, y, string, anchor, sup, rotate)
   !< Text whose baseline passes through the anchor point (`x`, `y`) [px].
   class(backend_svg), intent(inout)        :: self   !< Device.
   real(R8P),          intent(in)           :: x      !< Anchor abscissa [px].
   real(R8P),          intent(in)           :: y      !< Anchor ordinate (baseline) [px].
   character(len=*),   intent(in)           :: string !< Text.
   character(len=*),   intent(in)           :: anchor !< Horizontal anchor: `start`, `middle` or `end`.
   character(len=*),   intent(in), optional :: sup    !< Superscript appended to `string`.
   real(R8P),          intent(in), optional :: rotate !< Rotation about the anchor point [deg, clockwise].
   character(len=:), allocatable            :: line   !< Output line.

   line = '<text x="'//px(x)//'" y="'//px(y)//'"'
   if (anchor /= 'start') line = line//' text-anchor="'//anchor//'"'
   if (present(rotate)) line = line//' transform="rotate('//px(rotate)//' '//px(x)//' '//px(y)//')"'
   line = line//'>'//xml_escape(string)
   if (present(sup)) then
      if (len(sup) > 0) line = line//'<tspan dy="-0.45em" font-size="0.75em">'//xml_escape(sup)//'</tspan>'
   endif
   call self%put(line//'</text>')
   endsubroutine text

   subroutine begin_plot_area(self, x, y, width, height)
   !< Open the clipped plot area; its user space is the unit square, y upward.
   class(backend_svg), intent(inout) :: self   !< Device.
   real(R8P),          intent(in)    :: x      !< Left side [px].
   real(R8P),          intent(in)    :: y      !< Top side [px].
   real(R8P),          intent(in)    :: width  !< Width [px].
   real(R8P),          intent(in)    :: height !< Height [px].

   self%area = [x, y, width, height]
   self%caps = ''
   self%marks = ''
   call self%put('<svg class="fs-plot" x="'//px(x)//'" y="'//px(y)//'" width="'//px(width)//'" height="'//px(height)// &
                 '" viewBox="0 0 1 1" preserveAspectRatio="none" overflow="hidden">')
   endsubroutine begin_plot_area

   subroutine end_plot_area(self)
   !< Close the plot area, then write the overlays of error bar caps and point type markers (pixel space, clipped to the
   !< plot area): they keep their pixel size under zoom, the interactive viewer regenerates them from the data.
   class(backend_svg), intent(inout) :: self !< Device.

   call self%put('</svg>')
   call overlay('fs-caps', self%caps)
   call overlay('fs-marks', self%marks)
   self%caps = ''
   self%marks = ''
   contains
      subroutine overlay(name, content)
      !< Overlay `name` holding `content`, nothing if empty.
      character(len=*), intent(in) :: name    !< Overlay class.
      character(len=*), intent(in) :: content !< Elements.

      if (len(content) == 0) return
      call self%put('<svg class="'//name//'" x="'//px(self%area(1))//'" y="'//px(self%area(2))//'" width="'// &
                    px(self%area(3))//'" height="'//px(self%area(4))//'" viewBox="0 0 '//px(self%area(3))//' '// &
                    px(self%area(4))//'" overflow="hidden">')
      call self%put(content//'</svg>')
      endsubroutine overlay
   endsubroutine end_plot_area

   subroutine data_polyline(self, x, y, color, line_width, dasharray)
   !< Open polyline through the points (`x`, `y`) [unit square].
   class(backend_svg), intent(inout) :: self       !< Device.
   real(R8P),          intent(in)    :: x(:)       !< Abscissae [unit].
   real(R8P),          intent(in)    :: y(:)       !< Ordinates [unit].
   character(len=*),   intent(in)    :: color      !< Stroke color.
   real(R8P),          intent(in)    :: line_width !< Stroke width [px].
   character(len=*),   intent(in)    :: dasharray  !< SVG dash array, empty for solid.

   write(self%unit, '(A)', advance='no') '<polyline fill="none" stroke="'//color//'" stroke-width="'// &
                                         px(line_width)//'" stroke-linejoin="round" '// &
                                         'vector-effect="non-scaling-stroke"'//dash_attribute(dasharray)//' points="'
   call self%write_pairs(x, 1.0_R8P - y, UNIT_DECIMALS, '', '')
   call self%put('"/>')
   endsubroutine data_polyline

   subroutine data_dots(self, x, y, color, diameter, pt, line_width)
   !< Filled round dots centred on the points (`x`, `y`) [unit square], or point type markers.
   !<
   !< Markers keep their shape only in pixels: the plot area holds their centres as an invisible `fs-pts` path of
   !< `M` moves (unit square) carrying the marker as `data-*` attributes, and the markers are queued for the pixel
   !< overlay written by `end_plot_area`, which the interactive viewer regenerates from the centres after a zoom.
   class(backend_svg), intent(inout)        :: self       !< Device.
   real(R8P),          intent(in)           :: x(:)       !< Abscissae [unit].
   real(R8P),          intent(in)           :: y(:)       !< Ordinates [unit].
   character(len=*),   intent(in)           :: color      !< Fill color.
   real(R8P),          intent(in)           :: diameter   !< Dot diameter, or marker width [px].
   integer(I4P),       intent(in), optional :: pt         !< gnuplot point type; negative or absent: round dots.
   real(R8P),          intent(in), optional :: line_width !< Marker line width [px].
   real(R8P)                                :: width      !< Marker line width [px].

   if (present(pt)) then
      if (pt >= 0_I4P) then
         width = 1.0_R8P
         if (present(line_width)) width = line_width
         write(self%unit, '(A)', advance='no') '<path class="fs-pts" data-pt="'//int_str(int(pt, I8P))// &
                                               '" data-size="'//px(diameter)//'" data-lw="'//px(width)// &
                                               '" data-color="'//color//'" fill="none" stroke="none" d="'
         call self%write_pairs(x, 1.0_R8P - y, UNIT_DECIMALS, 'M', '')
         call self%put('"/>')
         self%marks = self%marks//marker_element(x * self%area(3), (1.0_R8P - y) * self%area(4), color, diameter, &
                                                 pt, width, self%series)//new_line('a')
         return
      endif
   endif
   write(self%unit, '(A)', advance='no') '<path fill="none" stroke="'//color//'" stroke-width="'//px(diameter)// &
                                         '" stroke-linecap="round" vector-effect="non-scaling-stroke" d="'
   call self%write_pairs(x, 1.0_R8P - y, UNIT_DECIMALS, 'M', 'h0')
   call self%put('"/>')
   endsubroutine data_dots

   subroutine data_bars(self, x1, y1, x2, y2, color, line_width, cap, vertical)
   !< Error bars [unit square] as one path of `Mx1,y1Lx2,y2` segments, classed `fs-ybars`/`fs-xbars` with the cap length
   !< in `data-cap`; caps are queued for the pixel overlay written by `end_plot_area`.
   class(backend_svg), intent(inout) :: self       !< Device.
   real(R8P),          intent(in)    :: x1(:)      !< Bar start abscissae.
   real(R8P),          intent(in)    :: y1(:)      !< Bar start ordinates.
   real(R8P),          intent(in)    :: x2(:)      !< Bar end abscissae.
   real(R8P),          intent(in)    :: y2(:)      !< Bar end ordinates.
   character(len=*),   intent(in)    :: color      !< Stroke color.
   real(R8P),          intent(in)    :: line_width !< Stroke width [px].
   real(R8P),          intent(in)    :: cap        !< Cap length [px].
   logical,            intent(in)    :: vertical   !< Vertical bars (horizontal caps), else horizontal.
   character(len=:), allocatable     :: kind       !< Bar class.
   real(R8P)                         :: h          !< Half cap length [px].
   real(R8P)                         :: p(2)       !< Bar end in the overlay [px].
   integer(I4P)                      :: i          !< Counter.
   integer(I4P)                      :: e          !< End counter.

   if (size(x1) == 0) return
   kind = merge('fs-ybars', 'fs-xbars', vertical)
   write(self%unit, '(A)', advance='no') '<path class="'//kind//'" data-cap="'//px(cap)//'" fill="none" stroke="'// &
                                         color//'" stroke-width="'//px(line_width)// &
                                         '" vector-effect="non-scaling-stroke" d="'
   do i = 1_I4P, size(x1, kind=I4P)
      if (i > 1_I4P) then
         if (modulo(i - 1_I4P, PAIRS_PER_LINE / 2_I4P) == 0_I4P) write(self%unit, '(A)') ''
      endif
      write(self%unit, '(A)', advance='no') 'M'//fixed(x1(i), UNIT_DECIMALS)//','// &
                                            fixed(1.0_R8P - y1(i), UNIT_DECIMALS)//'L'//fixed(x2(i), UNIT_DECIMALS)// &
                                            ','//fixed(1.0_R8P - y2(i), UNIT_DECIMALS)
   enddo
   call self%put('"/>')
   h = 0.5_R8P * cap
   if (self%series > 0_I4P) self%caps = self%caps//'<g'//series_attribute(self%series)//'>'//new_line('a')
   do i = 1_I4P, size(x1, kind=I4P)
      do e = 1_I4P, 2_I4P
         if (e == 1_I4P) then
            p = [x1(i) * self%area(3), (1.0_R8P - y1(i)) * self%area(4)]
         else
            p = [x2(i) * self%area(3), (1.0_R8P - y2(i)) * self%area(4)]
         endif
         if (vertical) then
            self%caps = self%caps//'<line x1="'//px(p(1) - h)//'" y1="'//px(p(2))//'" x2="'//px(p(1) + h)// &
                        '" y2="'//px(p(2))//'" stroke="'//color//'" stroke-width="'//px(line_width)//'"/>'//new_line('a')
         else
            self%caps = self%caps//'<line x1="'//px(p(1))//'" y1="'//px(p(2) - h)//'" x2="'//px(p(1))// &
                        '" y2="'//px(p(2) + h)//'" stroke="'//color//'" stroke-width="'//px(line_width)//'"/>'//new_line('a')
         endif
      enddo
   enddo
   if (self%series > 0_I4P) self%caps = self%caps//'</g>'//new_line('a')
   endsubroutine data_bars

   subroutine data_polygon(self, x, y, fill, opacity, stroke, line_width)
   !< Closed polygon of the vertices (`x`, `y`) [unit square], clipped by the plot area; its border keeps its pixel width
   !< under zoom.
   class(backend_svg), intent(inout) :: self       !< Device.
   real(R8P),          intent(in)    :: x(:)       !< Vertex abscissae [unit].
   real(R8P),          intent(in)    :: y(:)       !< Vertex ordinates [unit].
   character(len=*),   intent(in)    :: fill       !< Fill color.
   real(R8P),          intent(in)    :: opacity    !< Fill opacity.
   character(len=*),   intent(in)    :: stroke     !< Border color.
   real(R8P),          intent(in)    :: line_width !< Border width [px].

   write(self%unit, '(A)', advance='no') '<path'//paint(fill, opacity, stroke, line_width)// &
                                         ' vector-effect="non-scaling-stroke" d="M'
   call self%write_pairs(x, 1.0_R8P - y, UNIT_DECIMALS, '', '')
   call self%put('Z"/>')
   endsubroutine data_polygon

   pure function text_width(self, string, sup, font_size) result(width)
   !< Estimated width of `string` with its superscript `sup` [px]: the viewer renders the glyphs, so a mean advance of
   !< 0.55 font sizes (Arial digits: 0.556) is assumed, superscripts at 0.75 size.
   class(backend_svg), intent(in) :: self      !< Device.
   character(len=*),   intent(in) :: string    !< Text.
   character(len=*),   intent(in) :: sup       !< Superscript.
   real(R8P),          intent(in) :: font_size !< Font size [px].
   real(R8P)                      :: width     !< Width [px].

   width = 0.55_R8P * font_size * (real(len(string), R8P) + 0.75_R8P * real(len(sup), R8P))
   endfunction text_width

   subroutine readout(self, x, y, height, masks, label, prefix, suffix, color, font_size)
   !< Seven-segment readout of top-left corner (`x`, `y`) [px], a `<g class="fs-readout">`: the bold label above a
   !< glass slanted by 8 degrees, the unlit segments drawn faintly (`GHOST_OPACITY`), the unit text beside it.
   class(backend_svg), intent(inout) :: self      !< Device.
   real(R8P),          intent(in)    :: x         !< Left side [px].
   real(R8P),          intent(in)    :: y         !< Top side [px].
   real(R8P),          intent(in)    :: height    !< Digit height [px].
   integer(I4P),       intent(in)    :: masks(:)  !< Segments of each cell.
   character(len=*),   intent(in)    :: label     !< Label, empty for none.
   character(len=*),   intent(in)    :: prefix    !< Text before the glass.
   character(len=*),   intent(in)    :: suffix    !< Text after the glass.
   character(len=*),   intent(in)    :: color     !< Color of the lit segments.
   real(R8P),          intent(in)    :: font_size !< Font size of the texts [px].
   character(len=:), allocatable     :: lit       !< Path data of the lit segments.
   character(len=:), allocatable     :: ghost     !< Path data of the unlit segments.
   character(len=:), allocatable     :: piece     !< Path data of a segment.
   real(R8P)                         :: geometry(5) !< Glass left, top, width; prefix width; label row [px].
   real(R8P)                         :: ox        !< Cell left [px].
   real(R8P)                         :: t         !< Segment thickness [px].
   integer(I4P)                      :: k         !< Cell counter.
   integer(I4P)                      :: b         !< Segment bit.

   geometry = glass_geometry(self, x, y, height, size(masks, kind=I4P), label, prefix, font_size)
   t = SEGMENT_WIDTH * height
   lit = ''
   ghost = ''
   do k = 1_I4P, size(masks, kind=I4P)
      ox = real(k - 1_I4P, R8P) * DIGIT_PITCH * height
      do b = 0_I4P, 7_I4P
         if (b < 7_I4P) then
            piece = segment_path(ox, b, height)
         else
            piece = 'M'//px(ox + POINT_OFFSET * height)//','//px(height - 0.5_R8P * t)//'h'//px(t)//'v'//px(t)//'h'// &
                    px(-t)//'Z'
         endif
         if (btest(masks(k), b)) then
            lit = lit//piece
         else
            ghost = ghost//piece
         endif
      enddo
   enddo
   call self%put('<g class="fs-readout">')
   if (len(label) > 0) call self%put('<text x="'//px(x)//'" y="'//px(y + font_size)//'" font-weight="bold">'// &
                                     xml_escape(label)//'</text>')
   call self%put('<g transform="translate('//px(geometry(1))//' '//px(geometry(2))//') skewX(-8)" fill="'//color//'">')
   if (len(ghost) > 0) call self%put('<path fill-opacity="'//GHOST_OPACITY//'" d="'//ghost//'"/>')
   if (len(lit) > 0) call self%put('<path d="'//lit//'"/>')
   call self%put('</g>')
   if (len(prefix) > 0) call self%text(x, geometry(2) + height, prefix, 'start')
   if (len(suffix) > 0) call self%text(geometry(1) + geometry(3) + 0.5_R8P * font_size, geometry(2) + height, suffix, &
                                       'start')
   call self%put('</g>')
   endsubroutine readout

   pure function readout_extent(self, height, cells, label, prefix, suffix, font_size) result(extent)
   !< Width and height [px] of a readout: label row, glass with its slant and segment overhangs, unit text.
   class(backend_svg), intent(in) :: self      !< Device.
   real(R8P),          intent(in) :: height    !< Digit height [px].
   integer(I4P),       intent(in) :: cells     !< Glass cells.
   character(len=*),   intent(in) :: label     !< Label, empty for none.
   character(len=*),   intent(in) :: prefix    !< Text before the glass.
   character(len=*),   intent(in) :: suffix    !< Text after the glass.
   real(R8P),          intent(in) :: font_size !< Font size of the texts [px].
   real(R8P)                      :: extent(2) !< Width and height [px].
   real(R8P)                      :: geometry(5) !< Glass left, top, width; prefix width; label row [px].

   geometry = glass_geometry(self, 0.0_R8P, 0.0_R8P, height, cells, label, prefix, font_size)
   extent(1) = geometry(1) + geometry(3)
   if (len(suffix) > 0) extent(1) = extent(1) + 0.5_R8P * font_size + self%text_width(suffix, '', font_size)
   if (len(label) > 0) extent(1) = max(extent(1), self%text_width(label, '', font_size))
   extent(2) = geometry(5) + (1.0_R8P + SEGMENT_WIDTH) * height
   endfunction readout_extent

   ! building blocks for extending devices
   subroutine close_file(self)
   !< Close the stream and rename `<file>.tmp` over `<file>`.
   class(backend_svg), intent(inout) :: self !< Device.

   close(self%unit)
   self%unit = -1_I4P
   call rename_file(self%tmp_file, self%file)
   endsubroutine close_file

   subroutine open_file(self, file)
   !< Open the output stream on `<file>.tmp`.
   class(backend_svg), intent(inout) :: self   !< Device.
   character(len=*),   intent(in)    :: file   !< Output file.
   integer(I4P)                      :: iostat !< I/O status.
   character(len=256)                :: iomsg  !< I/O message.

   self%file = file
   self%tmp_file = file//'.tmp'
   open(newunit=self%unit, file=self%tmp_file, access='stream', form='formatted', action='write', status='replace', &
        iostat=iostat, iomsg=iomsg)
   if (iostat /= 0_I4P) error stop 'foresight: cannot open "'//self%tmp_file//'": '//trim(iomsg)
   endsubroutine open_file

   subroutine open_svg(self, width, height, font_size, attributes)
   !< Write the root `<svg>` start tag, with optional extra `attributes` (a leading space included).
   class(backend_svg), intent(inout)        :: self       !< Device.
   real(R8P),          intent(in)           :: width      !< Page width [px].
   real(R8P),          intent(in)           :: height     !< Page height [px].
   real(R8P),          intent(in)           :: font_size  !< Default font size [px].
   character(len=*),   intent(in), optional :: attributes !< Extra attributes.
   character(len=:), allocatable            :: extra      !< Extra attributes or empty.

   extra = ''
   if (present(attributes)) extra = attributes
   call self%put('<svg xmlns="http://www.w3.org/2000/svg" width="'//px(width)//'" height="'//px(height)// &
                 '" viewBox="0 0 '//px(width)//' '//px(height)//'" font-family="'//FONT_FAMILY// &
                 '" font-size="'//px(font_size)//'"'//extra//'>')
   endsubroutine open_svg

   pure function output_unit(self) result(unit)
   !< Unit of the open output stream.
   class(backend_svg), intent(in) :: self !< Device.
   integer(I4P)                   :: unit !< Output unit.

   unit = self%unit
   endfunction output_unit

   subroutine put(self, line)
   !< Write a complete line.
   class(backend_svg), intent(inout) :: self !< Device.
   character(len=*),   intent(in)    :: line !< Line.

   write(self%unit, '(A)') line
   endsubroutine put

   ! private procedures
   subroutine write_pairs(self, x, y, ndec, prefix, suffix)
   !< Write `prefix x,y suffix` for each point, space separated, `PAIRS_PER_LINE` per line, without final newline.
   class(backend_svg), intent(inout) :: self   !< Device.
   real(R8P),          intent(in)    :: x(:)   !< Abscissae.
   real(R8P),          intent(in)    :: y(:)   !< Ordinates.
   integer(I4P),       intent(in)    :: ndec   !< Decimals.
   character(len=*),   intent(in)    :: prefix !< Text before each pair.
   character(len=*),   intent(in)    :: suffix !< Text after each pair.
   integer(I4P)                      :: i      !< Counter.

   do i = 1_I4P, size(x, kind=I4P)
      if (i > 1_I4P) then
         if (modulo(i - 1_I4P, PAIRS_PER_LINE) == 0_I4P) then
            write(self%unit, '(A)') ''
         else
            write(self%unit, '(A)', advance='no') ' '
         endif
      endif
      write(self%unit, '(A)', advance='no') prefix//fixed(x(i), ndec)//','//fixed(y(i), ndec)//suffix
   enddo
   endsubroutine write_pairs

   function marker_element(x, y, color, width_px, pt, line_width, series) result(element)
   !< One `<path>` of the markers of gnuplot point type `pt`, `width_px` px wide, centred on the points (`x`, `y`) [px]:
   !< the filled shapes (the odd types from 5, and the dot) are filled with `color`, the others stroked only.
   real(R8P),        intent(in)           :: x(:)       !< Abscissae [px].
   real(R8P),        intent(in)           :: y(:)       !< Ordinates [px].
   character(len=*), intent(in)           :: color      !< Color.
   real(R8P),        intent(in)           :: width_px   !< Marker width [px].
   integer(I4P),     intent(in)           :: pt         !< gnuplot point type, >= 0.
   real(R8P),        intent(in), optional :: line_width !< Line width [px], default 1.
   integer(I4P),     intent(in), optional :: series     !< Series number, 0 or absent for none.
   character(len=:), allocatable          :: element    !< Path element.
   character(len=:), allocatable          :: d          !< Path data.
   character(len=:), allocatable          :: fill       !< Fill color or none.
   character(len=:), allocatable          :: width      !< Line width text.
   integer(I4P)                           :: shape      !< Shape: 0 the dot, 1..15.
   integer(I4P)                           :: used       !< Characters of `d` in use.
   integer(I4P)                           :: i          !< Counter.

   shape = 0_I4P
   if (pt > 0_I4P) shape = modulo(pt - 1_I4P, 15_I4P) + 1_I4P
   fill = 'none'
   if (shape == 0_I4P .or. modulo(shape, 2_I4P) == 1_I4P .and. shape >= 5_I4P) fill = color
   width = '1.00'
   if (present(line_width)) width = px(line_width)
   ! grown by doubling: a marker per point, never quadratic
   allocate(character(len=256) :: d)
   used = 0_I4P
   do i = 1_I4P, size(x, kind=I4P)
      call append(marker_path(x(i), y(i), 0.5_R8P * width_px, shape))
   enddo
   element = '<path'
   if (present(series)) then
      if (series > 0_I4P) element = element//series_attribute(series)
   endif
   element = element//' fill="'//fill//'" stroke="'//color//'" stroke-width="'//width//'" d="'//d(1:used)//'"/>'
   contains
      subroutine append(piece)
      !< Append `piece` to `d`.
      character(len=*), intent(in)  :: piece !< Text.
      character(len=:), allocatable :: grown !< Larger buffer.

      if (used + len(piece) > len(d)) then
         allocate(character(len=2 * (used + len(piece))) :: grown)
         grown(1:used) = d(1:used)
         call move_alloc(grown, d)
      endif
      d(used + 1:used + len(piece)) = piece
      used = used + len(piece, kind=I4P)
      endsubroutine append
   endfunction marker_element

   pure function marker_path(x, y, r, shape) result(d)
   !< Path data of a marker of half width `r` centred on (`x`, `y`) [px]: gnuplot's svg shapes, 1 plus, 2 cross, 3 star,
   !< 4-5 square, 6-7 circle, 8-9 triangle, 10-11 inverted triangle, 12-13 diamond, 14-15 pentagon, 0 a 1 px dot.
   real(R8P),    intent(in)      :: x     !< Centre abscissa [px].
   real(R8P),    intent(in)      :: y     !< Centre ordinate [px].
   real(R8P),    intent(in)      :: r     !< Half width [px].
   integer(I4P), intent(in)      :: shape !< Shape, 0..15.
   character(len=:), allocatable :: d     !< Path data.

   select case (shape)
   case (0_I4P)
      d = circle(0.5_R8P)
   case (1_I4P)
      d = plus()
   case (2_I4P)
      d = cross()
   case (3_I4P)
      d = plus()//cross()
   case (4_I4P, 5_I4P)
      d = outline([-1.0_R8P, 1.0_R8P, 1.0_R8P, -1.0_R8P], [-1.0_R8P, -1.0_R8P, 1.0_R8P, 1.0_R8P])
   case (6_I4P, 7_I4P)
      d = circle(r)
   case (8_I4P, 9_I4P)
      d = outline([0.0_R8P, -1.33_R8P, 1.33_R8P], [-1.33_R8P, 0.67_R8P, 0.67_R8P])
   case (10_I4P, 11_I4P)
      d = outline([0.0_R8P, -1.33_R8P, 1.33_R8P], [1.33_R8P, -0.67_R8P, -0.67_R8P])
   case (12_I4P, 13_I4P)
      d = outline([0.0_R8P, 1.414_R8P, 0.0_R8P, -1.414_R8P], [-1.414_R8P, 0.0_R8P, 1.414_R8P, 0.0_R8P])
   case default
      d = outline([0.0_R8P, 1.265_R8P, 0.782_R8P, -0.782_R8P, -1.265_R8P], &
                  [1.33_R8P, 0.411_R8P, -1.067_R8P, -1.067_R8P, 0.411_R8P])
   endselect
   contains
      pure function plus() result(p)
      !< Plus.
      character(len=:), allocatable :: p !< Path data.

      p = 'M'//px(x - r)//','//px(y)//'H'//px(x + r)//'M'//px(x)//','//px(y - r)//'V'//px(y + r)
      endfunction plus

      pure function cross() result(p)
      !< Diagonal cross.
      character(len=:), allocatable :: p !< Path data.

      p = 'M'//px(x - r)//','//px(y - r)//'L'//px(x + r)//','//px(y + r)//'M'//px(x + r)//','//px(y - r)//'L'// &
          px(x - r)//','//px(y + r)
      endfunction cross

      pure function circle(radius) result(p)
      !< Circle of `radius`, two arcs.
      real(R8P), intent(in)         :: radius !< Radius [px].
      character(len=:), allocatable :: p      !< Path data.

      p = 'M'//px(x - radius)//','//px(y)//'A'//px(radius)//','//px(radius)//' 0 1 0 '//px(x + radius)//','//px(y)// &
          'A'//px(radius)//','//px(radius)//' 0 1 0 '//px(x - radius)//','//px(y)//'Z'
      endfunction circle

      pure function outline(px_, py_) result(p)
      !< Closed polygon of the vertices (`px_`, `py_`), in half widths from the centre.
      real(R8P), intent(in)         :: px_(:) !< Vertex abscissae [half width].
      real(R8P), intent(in)         :: py_(:) !< Vertex ordinates [half width].
      character(len=:), allocatable :: p      !< Path data.
      integer(I4P)                  :: k      !< Vertex counter.

      p = 'M'//px(x + r * px_(1))//','//px(y + r * py_(1))
      do k = 2_I4P, size(px_, kind=I4P)
         p = p//'L'//px(x + r * px_(k))//','//px(y + r * py_(k))
      enddo
      p = p//'Z'
      endfunction outline
   endfunction marker_path

   pure function glass_geometry(self, x, y, height, cells, label, prefix, font_size) result(geometry)
   !< Glass of a readout of top-left corner (`x`, `y`): origin of its first cell (left, top of the digits), width up to
   !< the last decimal point, the prefix width and the label row height [px]. The origin leaves room for the slant of
   !< the digit bottoms and for the half thickness of the segments.
   class(backend_svg), intent(in) :: self        !< Device.
   real(R8P),          intent(in) :: x           !< Left side [px].
   real(R8P),          intent(in) :: y           !< Top side [px].
   real(R8P),          intent(in) :: height      !< Digit height [px].
   integer(I4P),       intent(in) :: cells       !< Glass cells.
   character(len=*),   intent(in) :: label       !< Label, empty for none.
   character(len=*),   intent(in) :: prefix      !< Text before the glass.
   real(R8P),          intent(in) :: font_size   !< Font size of the texts [px].
   real(R8P)                      :: geometry(5) !< Glass left, top, width; prefix width; label row [px].

   geometry(4) = 0.0_R8P
   if (len(prefix) > 0) geometry(4) = self%text_width(prefix, '', font_size) + 0.5_R8P * font_size
   geometry(5) = 0.0_R8P
   if (len(label) > 0) geometry(5) = 1.25_R8P * font_size
   geometry(1) = x + geometry(4) + (SLANT + 0.5_R8P * SEGMENT_WIDTH) * height
   geometry(2) = y + geometry(5) + 0.5_R8P * SEGMENT_WIDTH * height
   geometry(3) = (real(cells - 1_I4P, R8P) * DIGIT_PITCH + POINT_OFFSET + SEGMENT_WIDTH) * height
   endfunction glass_geometry

   pure function segment_path(ox, segment, height) result(d)
   !< Path data of the hexagon of `segment` (0-6: a, b, c, d, e, f, g) of the cell of left side `ox`, digits `height`
   !< px high, in glass coordinates (origin at the top left of the first cell).
   real(R8P),    intent(in)      :: ox      !< Cell left [px].
   integer(I4P), intent(in)      :: segment !< Segment, 0-6.
   real(R8P),    intent(in)      :: height  !< Digit height [px].
   character(len=:), allocatable :: d       !< Path data.
   real(R8P)                     :: w       !< Digit width [px].
   real(R8P)                     :: g       !< Gap at segment ends [px].
   real(R8P)                     :: m       !< Middle height [px].

   w = DIGIT_WIDTH * height
   g = SEGMENT_GAP * SEGMENT_WIDTH * height
   m = 0.5_R8P * height
   select case (segment)
   case (0_I4P)
      d = across(0.0_R8P)
   case (1_I4P)
      d = along(w, g, m - g)
   case (2_I4P)
      d = along(w, m + g, height - g)
   case (3_I4P)
      d = across(height)
   case (4_I4P)
      d = along(0.0_R8P, m + g, height - g)
   case (5_I4P)
      d = along(0.0_R8P, g, m - g)
   case default
      d = across(m)
   endselect
   contains
      pure function across(v) result(p)
      !< Horizontal hexagon at height `v`, between the vertical segments.
      real(R8P), intent(in)         :: v !< Ordinate [px].
      character(len=:), allocatable :: p !< Path data.
      real(R8P)                     :: h !< Half thickness [px].

      h = 0.5_R8P * SEGMENT_WIDTH * height
      p = 'M'//px(ox + g)//','//px(v)//'L'//px(ox + g + h)//','//px(v - h)//'L'//px(ox + w - g - h)//','//px(v - h)// &
          'L'//px(ox + w - g)//','//px(v)//'L'//px(ox + w - g - h)//','//px(v + h)//'L'//px(ox + g + h)//','// &
          px(v + h)//'Z'
      endfunction across

      pure function along(u, v1, v2) result(p)
      !< Vertical hexagon at `u` from `v1` to `v2`.
      real(R8P), intent(in)         :: u  !< Abscissa in the cell [px].
      real(R8P), intent(in)         :: v1 !< Top [px].
      real(R8P), intent(in)         :: v2 !< Bottom [px].
      character(len=:), allocatable :: p  !< Path data.
      real(R8P)                     :: h  !< Half thickness [px].

      h = 0.5_R8P * SEGMENT_WIDTH * height
      p = 'M'//px(ox + u)//','//px(v1)//'L'//px(ox + u + h)//','//px(v1 + h)//'L'//px(ox + u + h)//','//px(v2 - h)// &
          'L'//px(ox + u)//','//px(v2)//'L'//px(ox + u - h)//','//px(v2 - h)//'L'//px(ox + u - h)//','//px(v1 + h)//'Z'
      endfunction along
   endfunction segment_path

   pure function paint(fill, opacity, stroke, line_width) result(attributes)
   !< Fill and stroke attributes of a polygon: `fill-opacity` only below 1, the stroke width only with a stroke.
   character(len=*), intent(in)  :: fill       !< Fill color.
   real(R8P),        intent(in)  :: opacity    !< Fill opacity.
   character(len=*), intent(in)  :: stroke     !< Border color.
   real(R8P),        intent(in)  :: line_width !< Border width [px].
   character(len=:), allocatable :: attributes !< Attributes, a leading space included.

   attributes = ' fill="'//fill//'"'
   if (fill /= 'none' .and. opacity < 1.0_R8P) attributes = attributes//' fill-opacity="'//fixed(opacity, 3_I4P)//'"'
   attributes = attributes//' stroke="'//stroke//'"'
   if (stroke /= 'none') attributes = attributes//' stroke-width="'//px(line_width)//'" stroke-linejoin="miter"'
   endfunction paint

   pure function dash_attribute(dasharray) result(attribute)
   !< ` stroke-dasharray="..."` attribute, empty for solid lines.
   character(len=*), intent(in)  :: dasharray !< SVG dash array.
   character(len=:), allocatable :: attribute !< Attribute text.

   attribute = ''
   if (len(dasharray) > 0) attribute = ' stroke-dasharray="'//dasharray//'"'
   endfunction dash_attribute

   pure function series_attribute(series) result(attribute)
   !< ` data-series="N"` attribute.
   integer(I4P), intent(in)      :: series    !< Series number.
   character(len=:), allocatable :: attribute !< Attribute text.

   attribute = ' data-series="'//int_str(int(series, I8P))//'"'
   endfunction series_attribute

   pure function flag(value) result(str)
   !< `1` or `0`.
   logical, intent(in)           :: value !< Flag.
   character(len=:), allocatable :: str   !< Text.

   str = merge('1', '0', value)
   endfunction flag

   pure function px(v) result(str)
   !< Pixel coordinate text.
   real(R8P), intent(in)         :: v   !< Value [px].
   character(len=:), allocatable :: str !< Text.

   str = fixed(v, PX_DECIMALS)
   endfunction px
endmodule foresight_backend_svg
