!< foresight_backend_svg, SVG output device.
module foresight_backend_svg
!< foresight_backend_svg, SVG output device.
!<
!< The document is streamed to `<file>.tmp` and renamed over `<file>` when the page ends, so a viewer polling `<file>`
!< never reads a partial document. The plot area is a nested `<svg>` whose `viewBox` is the unit square: data geometry
!< lives in unit coordinates, and `vector-effect="non-scaling-stroke"` keeps its line widths in pixels.
use foresight_backend, only : backend_object
use foresight_format, only : fixed, xml_escape
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
   contains
      procedure, pass(self) :: begin_page
      procedure, pass(self) :: end_page
      procedure, pass(self) :: rect
      procedure, pass(self) :: polyline
      procedure, pass(self) :: dots
      procedure, pass(self) :: text
      procedure, pass(self) :: begin_plot_area
      procedure, pass(self) :: end_plot_area
      procedure, pass(self) :: data_polyline
      procedure, pass(self) :: data_dots
      procedure, pass(self), private :: put         !< Write a line.
      procedure, pass(self), private :: write_pairs !< Write coordinate pairs.
endtype backend_svg

contains
   subroutine begin_page(self, file, width, height, font_size)
   !< Open the output `file` with a page of `width` x `height` px and the default `font_size` [px].
   class(backend_svg), intent(inout) :: self      !< Device.
   character(len=*),   intent(in)    :: file      !< Output file.
   real(R8P),          intent(in)    :: width     !< Page width [px].
   real(R8P),          intent(in)    :: height    !< Page height [px].
   real(R8P),          intent(in)    :: font_size !< Default font size [px].
   integer(I4P)                      :: iostat    !< I/O status.
   character(len=256)                :: iomsg     !< I/O message.

   self%file = file
   self%tmp_file = file//'.tmp'
   open(newunit=self%unit, file=self%tmp_file, access='stream', form='formatted', action='write', status='replace', &
        iostat=iostat, iomsg=iomsg)
   if (iostat /= 0_I4P) error stop 'foresight: cannot open "'//self%tmp_file//'": '//trim(iomsg)
   call self%put('<?xml version="1.0" encoding="UTF-8" standalone="no"?>')
   call self%put('<svg xmlns="http://www.w3.org/2000/svg" width="'//px(width)//'" height="'//px(height)// &
                 '" viewBox="0 0 '//px(width)//' '//px(height)//'" font-family="'//FONT_FAMILY// &
                 '" font-size="'//px(font_size)//'">')
   endsubroutine begin_page

   subroutine end_page(self)
   !< Close the document and publish it atomically.
   class(backend_svg), intent(inout) :: self !< Device.

   call self%put('</svg>')
   close(self%unit)
   self%unit = -1_I4P
   call rename_file(self%tmp_file, self%file)
   endsubroutine end_page

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

   call self%put('<svg x="'//px(x)//'" y="'//px(y)//'" width="'//px(width)//'" height="'//px(height)// &
                 '" viewBox="0 0 1 1" preserveAspectRatio="none" overflow="hidden">')
   endsubroutine begin_plot_area

   subroutine end_plot_area(self)
   !< Close the plot area.
   class(backend_svg), intent(inout) :: self !< Device.

   call self%put('</svg>')
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

   ! private procedures
   subroutine put(self, line)
   !< Write a complete line.
   class(backend_svg), intent(inout) :: self !< Device.
   character(len=*),   intent(in)    :: line !< Line.

   write(self%unit, '(A)') line
   endsubroutine put

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

   pure function px(v) result(str)
   !< Pixel coordinate text.
   real(R8P), intent(in)         :: v   !< Value [px].
   character(len=:), allocatable :: str !< Text.

   str = fixed(v, PX_DECIMALS)
   endfunction px

   pure function dash_attribute(dasharray) result(attribute)
   !< ` stroke-dasharray="..."` attribute, empty for solid lines.
   character(len=*), intent(in)  :: dasharray !< SVG dash array.
   character(len=:), allocatable :: attribute !< Attribute text.

   attribute = ''
   if (len(dasharray) > 0) attribute = ' stroke-dasharray="'//dasharray//'"'
   endfunction dash_attribute
endmodule foresight_backend_svg
