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
use foresight_format, only : fixed, real_str, xml_escape
use foresight_sys, only : rename_file
use penf, only : I4P, R8P

implicit none
private
public :: backend_svg

integer(I4P),     parameter :: PX_DECIMALS    = 2_I4P                        !< Decimals of pixel coordinates.
integer(I4P),     parameter :: UNIT_DECIMALS  = 6_I4P                        !< Decimals of unit-square coordinates.
integer(I4P),     parameter :: PAIRS_PER_LINE = 8_I4P                        !< Coordinate pairs per output line.
character(len=*), parameter :: FONT_FAMILY    = 'Arial,Helvetica,sans-serif' !< Default font family.

type, extends(backend_object) :: backend_svg
   !< SVG output device.
   private
   integer(I4P)                  :: unit = -1_I4P !< Output unit.
   character(len=:), allocatable :: file          !< Final output file.
   character(len=:), allocatable :: tmp_file      !< File being written.
   real(R8P)                     :: area(4) = 0.0_R8P !< Current plot area: left, top, width, height [px].
   character(len=:), allocatable :: caps          !< Error bar caps of the current plot area, pixel overlay.
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
      procedure, pass(self) :: text
      procedure, pass(self) :: begin_plot_area
      procedure, pass(self) :: end_plot_area
      procedure, pass(self) :: data_polyline
      procedure, pass(self) :: data_dots
      procedure, pass(self) :: data_bars
      procedure, pass(self) :: text_width
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

   subroutine begin_group(self, name, visible)
   !< Open the group of class `name`; hidden with `display="none"` when `visible` is false.
   class(backend_svg), intent(inout)        :: self    !< Device.
   character(len=*),   intent(in)           :: name    !< Group name.
   logical,            intent(in), optional :: visible !< Group shown.
   character(len=:), allocatable            :: line    !< Output line.

   line = '<g class="'//name//'"'
   if (present(visible)) then
      if (.not. visible) line = line//' display="none"'
   endif
   call self%put(line//'>')
   endsubroutine begin_group

   subroutine end_group(self)
   !< Close the group.
   class(backend_svg), intent(inout) :: self !< Device.

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

   subroutine dots(self, x, y, color, diameter)
   !< Filled round dots centred on the points (`x`, `y`) [px].
   class(backend_svg), intent(inout) :: self     !< Device.
   real(R8P),          intent(in)    :: x(:)     !< Abscissae [px].
   real(R8P),          intent(in)    :: y(:)     !< Ordinates [px].
   character(len=*),   intent(in)    :: color    !< Fill color.
   real(R8P),          intent(in)    :: diameter !< Dot diameter [px].

   ! a zero-length subpath with round caps renders as a dot of diameter stroke-width
   write(self%unit, '(A)', advance='no') '<path fill="none" stroke="'//color//'" stroke-width="'//px(diameter)// &
                                         '" stroke-linecap="round" d="'
   call self%write_pairs(x, y, PX_DECIMALS, 'M', 'h0')
   call self%put('"/>')
   endsubroutine dots

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
   call self%put('<svg class="fs-plot" x="'//px(x)//'" y="'//px(y)//'" width="'//px(width)//'" height="'//px(height)// &
                 '" viewBox="0 0 1 1" preserveAspectRatio="none" overflow="hidden">')
   endsubroutine begin_plot_area

   subroutine end_plot_area(self)
   !< Close the plot area, then write the error bar caps overlay (pixel space, clipped to the plot area): caps keep
   !< their pixel length under zoom, the interactive viewer regenerates them from the bars.
   class(backend_svg), intent(inout) :: self !< Device.

   call self%put('</svg>')
   if (len(self%caps) == 0) return
   call self%put('<svg class="fs-caps" x="'//px(self%area(1))//'" y="'//px(self%area(2))//'" width="'// &
                 px(self%area(3))//'" height="'//px(self%area(4))//'" viewBox="0 0 '//px(self%area(3))//' '// &
                 px(self%area(4))//'" overflow="hidden">')
   call self%put(self%caps//'</svg>')
   self%caps = ''
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

   subroutine data_dots(self, x, y, color, diameter)
   !< Filled round dots centred on the points (`x`, `y`) [unit square].
   class(backend_svg), intent(inout) :: self     !< Device.
   real(R8P),          intent(in)    :: x(:)     !< Abscissae [unit].
   real(R8P),          intent(in)    :: y(:)     !< Ordinates [unit].
   character(len=*),   intent(in)    :: color    !< Fill color.
   real(R8P),          intent(in)    :: diameter !< Dot diameter [px].

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
   endsubroutine data_bars

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

   pure function dash_attribute(dasharray) result(attribute)
   !< ` stroke-dasharray="..."` attribute, empty for solid lines.
   character(len=*), intent(in)  :: dasharray !< SVG dash array.
   character(len=:), allocatable :: attribute !< Attribute text.

   attribute = ''
   if (len(dasharray) > 0) attribute = ' stroke-dasharray="'//dasharray//'"'
   endfunction dash_attribute

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
