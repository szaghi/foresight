!< foresight_backend_dumb, text output device (gnuplot `dumb` terminal).
module foresight_backend_dumb
!< foresight_backend_dumb, text output device (gnuplot `dumb` terminal).
!<
!< The page is a grid of character cells, `CELL_WIDTH` x `CELL_HEIGHT` font sizes each, so the layout engine works
!< unchanged in its virtual pixels. Series are drawn with gnuplot's dumb symbols, one per color in order of use, the
!< frame with `+`, `-` and `|`, the grid with `.`; superscripts become `^`. Data segments are clipped to the plot area
!< before rasterisation: points far outside the range never cost more than the cells actually drawn.
!<
!< With `colors` other than `mono` (gnuplot `ansi`, `ansi256`, `ansirgb`) the cells of each series take its color
!< through ANSI escape sequences, the nearest of the 6 basic colors, of the 256-color palette, or the color itself;
!< frame, grid, text, and black, white or named series colors keep the terminal's own color.
!<
!< Data are drawn through `px_segment` and `px_point`, in pixels: a device drawing at a finer resolution than the cells
!< (foresight_backend_block) overrides them, `cell`, `clear`, `rect` and `polyline`, and keeps the rest.
!<
!< Readouts are seven-segment digits in characters, 3 rows of 4 columns per cell (` _ `, `|_|`, `|_|`, the decimal point
!< a `.` in the fourth column); the unlit segments are not drawn, text has no faint intensity. A filled rectangle (the
!< readout window) clears the cells it covers.
!<
!< Filled polygons (boxes, filledcurves) fill the cells whose centre lies inside with the symbol of the fill color
!< (gnuplot's dumb uses `#`, which is also a series symbol here: a fill would hide the second curve), whatever the
!< opacity, then draw the border with the color symbol; in the plot area they are clipped
!< to it first (Sutherland-Hodgman). Fills go through `px_fill`, which a finer device overrides.
!<
!< Images (`with image`, color boxes) are drawn a character per cell, the cell taking the pixel at its centre: a
!< character of density growing with the pixel luminance (` .:-=+*#%@`), in its color with `ansi`; transparent pixels
!< (undefined values) are left blank.
use, intrinsic :: iso_fortran_env, only : output_unit
use foresight_backend, only : axes_view, backend_object
use foresight_theme, only : theme_object
use foresight_sys, only : rename_file
use penf, only : I4P, R8P

implicit none
private
public :: backend_dumb
public :: FRAME_COLOR
public :: GRID_COLOR
public :: TEXT_COLORS
public :: scanline

character(len=*), parameter :: SYMBOLS     = '*#$%@&=+' !< Series symbols, cycled.
character(len=*), parameter :: FRAME_COLOR = 'black'    !< Frame color, drawn as ticks.
character(len=*), parameter :: GRID_COLOR  = '#a0a0a0'  !< Grid color, drawn as dots on blank cells.
real(R8P),        parameter :: CELL_WIDTH  = 0.55_R8P   !< Cell width [font size].
real(R8P),        parameter :: CELL_HEIGHT = 1.25_R8P   !< Cell height [font size].
character(len=*), parameter :: TEXT_COLORS = 'mono ansi ansi256 ansirgb' !< Color modes (gnuplot names).
character(len=1), parameter :: ESC         = achar(27)  !< Escape character.

type :: color_symbol
   !< Symbol assigned to a color.
   character(len=:), allocatable :: color  !< SVG color.
   character(len=1)              :: symbol !< Cell symbol.
endtype color_symbol

type, extends(backend_object) :: backend_dumb
   !< Text output device.
   logical                         :: clear_screen = .false. !< Clear the terminal before writing to standard output.
   character(len=:), allocatable   :: file                   !< Output file, `-` for standard output.
   character(len=1), allocatable   :: grid(:,:)              !< Cells, (column, row).
   type(color_symbol), allocatable :: symbols(:)             !< Symbols in use.
   integer(I4P), allocatable       :: tint(:,:)              !< Cell color, index in `symbols`, 0 for the default.
   character(len=7)                :: colors = 'mono'        !< Color mode: `mono`, `ansi`, `ansi256`, `ansirgb`.
   real(R8P)                       :: cw = 1.0_R8P           !< Cell width [px].
   real(R8P)                       :: ch = 1.0_R8P           !< Cell height [px].
   real(R8P)                       :: font_size = 12.0_R8P   !< Font size [px].
   real(R8P)                       :: area(4) = 0.0_R8P      !< Plot area: left, top, width, height [px].
   logical                         :: hidden = .false.       !< Inside a hidden group: nothing is drawn.
   contains
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
      procedure, pass(self) :: image
      procedure, pass(self) :: text
      procedure, pass(self) :: begin_plot_area
      procedure, pass(self) :: end_plot_area
      procedure, pass(self) :: data_polyline
      procedure, pass(self) :: data_dots
      procedure, pass(self) :: data_bars
      procedure, pass(self) :: data_polygon
      procedure, pass(self) :: data_image
      procedure, pass(self) :: text_width
      procedure, pass(self) :: readout
      procedure, pass(self) :: readout_extent
      ! building blocks for finer devices
      procedure, pass(self) :: cell         !< Text of a cell.
      procedure, pass(self) :: clear        !< Blank a box.
      procedure, pass(self) :: col          !< Column of an abscissa [px].
      procedure, pass(self) :: color_index  !< Index of a color in `symbols`.
      procedure, pass(self) :: px_fill      !< Fill a polygon [px].
      procedure, pass(self) :: px_point     !< Draw a data point [px].
      procedure, pass(self) :: px_segment   !< Draw a data segment [px].
      procedure, pass(self) :: row          !< Row of an ordinate [px].
      procedure, pass(self) :: put          !< Set a cell.
      procedure, pass(self), private :: segment      !< Rasterise a cell segment.
      procedure, pass(self), private :: symbol_of    !< Symbol of a color.
      procedure, pass(self), private :: unit_segment !< Clip and draw a unit-square segment.
endtype backend_dumb

contains
   subroutine begin_page(self, file, width, height, font_size)
   !< Start a blank page of `width` x `height` px.
   class(backend_dumb), intent(inout) :: self      !< Device.
   character(len=*),    intent(in)    :: file      !< Output file, `-` for standard output.
   real(R8P),           intent(in)    :: width     !< Page width [px].
   real(R8P),           intent(in)    :: height    !< Page height [px].
   real(R8P),           intent(in)    :: font_size !< Font size [px].

   self%file = file
   self%font_size = font_size
   self%cw = CELL_WIDTH * font_size
   self%ch = CELL_HEIGHT * font_size
   self%hidden = .false.
   if (allocated(self%grid)) deallocate(self%grid)
   allocate(self%grid(max(1_I4P, nint(width / self%cw, I4P)), max(1_I4P, nint(height / self%ch, I4P))))
   self%grid = ' '
   if (allocated(self%tint)) deallocate(self%tint)
   allocate(self%tint(size(self%grid, 1), size(self%grid, 2)))
   self%tint = 0_I4P
   if (allocated(self%symbols)) deallocate(self%symbols)
   allocate(self%symbols(0))
   endsubroutine begin_page

   subroutine end_page(self)
   !< Write the page, rows right-trimmed: to standard output, or atomically to the file.
   class(backend_dumb), intent(inout) :: self  !< Device.
   character(len=:), allocatable      :: line  !< Row text.
   integer(I4P)                       :: unit  !< Output unit.
   integer(I4P)                       :: r     !< Row counter.
   integer(I4P)                       :: c     !< Column counter.
   integer(I4P)                       :: last  !< Last non-blank column.
   integer(I4P)                       :: color !< Color of the text written so far, 0 for the default.

   if (self%file == '-') then
      unit = output_unit
      if (self%clear_screen) write(unit, '(A)', advance='no') achar(27)//'[H'//achar(27)//'[2J'
   else
      open(newunit=unit, file=self%file//'.tmp', action='write', status='replace')
   endif
   do r = 1_I4P, size(self%grid, 2, kind=I4P)
      last = 0_I4P
      do c = size(self%grid, 1, kind=I4P), 1_I4P, -1_I4P
         if (self%cell(c, r) /= ' ') then
            last = c
            exit
         endif
      enddo
      line = ''
      color = 0_I4P
      do c = 1_I4P, last
         if (self%colors /= 'mono' .and. self%tint(c, r) /= color .and. self%cell(c, r) /= ' ') then
            color = self%tint(c, r)
            line = line//ansi_escape(self%colors, color_rgb(self%symbols, color, self%theme))
         endif
         line = line//self%cell(c, r)
      enddo
      if (color /= 0_I4P) line = line//ESC//'[39m'
      write(unit, '(A)') line
   enddo
   if (self%file /= '-') then
      close(unit)
      call rename_file(self%file//'.tmp', self%file)
   endif
   endsubroutine end_page

   subroutine begin_axes(self, view)
   !< No panel metadata in text.
   class(backend_dumb), intent(inout) :: self !< Device.
   type(axes_view),     intent(in)    :: view !< Panel geometry and axis ranges.
   endsubroutine begin_axes

   subroutine end_axes(self)
   !< No panel metadata in text.
   class(backend_dumb), intent(inout) :: self !< Device.
   endsubroutine end_axes

   subroutine begin_group(self, name, visible, series)
   !< A hidden group (the grid when off) is not drawn at all.
   class(backend_dumb), intent(inout)        :: self    !< Device.
   character(len=*),    intent(in)           :: name    !< Group name.
   logical,             intent(in), optional :: visible !< Group shown.
   integer(I4P),        intent(in), optional :: series  !< Series number, unused in text.

   self%hidden = .false.
   if (present(visible)) self%hidden = .not. visible
   endsubroutine begin_group

   subroutine end_group(self)
   !< Leave the group.
   class(backend_dumb), intent(inout) :: self !< Device.

   self%hidden = .false.
   endsubroutine end_group

   subroutine rect(self, x, y, width, height, stroke, fill, line_width)
   !< Stroked rectangles are drawn with `-`, `|` and `+` corners; a fill blanks the cells covered.
   class(backend_dumb), intent(inout) :: self       !< Device.
   real(R8P),           intent(in)    :: x          !< Left side [px].
   real(R8P),           intent(in)    :: y          !< Top side [px].
   real(R8P),           intent(in)    :: width      !< Width [px].
   real(R8P),           intent(in)    :: height     !< Height [px].
   character(len=*),    intent(in)    :: stroke     !< Stroke color.
   character(len=*),    intent(in)    :: fill       !< Fill color.
   real(R8P),           intent(in)    :: line_width !< Stroke width [px].
   integer(I4P)                       :: c(2)       !< Side columns.
   integer(I4P)                       :: r(2)       !< Side rows.
   integer(I4P)                       :: k          !< Counter.

   if (self%hidden) return
   if (fill /= 'none') call self%clear(x, y, width, height)
   if (stroke == 'none') return
   c = [self%col(x), self%col(x + width)]
   r = [self%row(y), self%row(y + height)]
   do k = c(1), c(2)
      call self%put(k, r(1), '-')
      call self%put(k, r(2), '-')
   enddo
   do k = r(1), r(2)
      call self%put(c(1), k, '|')
      call self%put(c(2), k, '|')
   enddo
   call self%put(c(1), r(1), '+')
   call self%put(c(2), r(1), '+')
   call self%put(c(1), r(2), '+')
   call self%put(c(2), r(2), '+')
   endsubroutine rect

   subroutine polyline(self, x, y, color, line_width, dasharray)
   !< Frame polylines (ticks) mark their start with `+`, grid lines dot blank cells, others use the color symbol.
   class(backend_dumb), intent(inout) :: self       !< Device.
   real(R8P),           intent(in)    :: x(:)       !< Abscissae [px].
   real(R8P),           intent(in)    :: y(:)       !< Ordinates [px].
   character(len=*),    intent(in)    :: color      !< Stroke color.
   real(R8P),           intent(in)    :: line_width !< Stroke width [px].
   character(len=*),    intent(in)    :: dasharray  !< SVG dash array.
   integer(I4P)                       :: i          !< Counter.

   if (size(x) == 0 .or. self%hidden) return
   if (color == FRAME_COLOR) then
      call self%put(self%col(x(1)), self%row(y(1)), '+')
      return
   endif
   do i = 1_I4P, size(x, kind=I4P) - 1_I4P
      if (color == GRID_COLOR) then
         call self%segment(self%col(x(i)), self%row(y(i)), self%col(x(i + 1)), self%row(y(i + 1)), '.', .true.)
      else
         call self%px_segment([x(i), y(i)], [x(i + 1), y(i + 1)], color, '')
      endif
   enddo
   endsubroutine polyline

   subroutine dots(self, x, y, color, diameter, pt, line_width)
   !< Dots are the color symbol, whatever the point type.
   class(backend_dumb), intent(inout)        :: self       !< Device.
   real(R8P),           intent(in)           :: x(:)       !< Abscissae [px].
   real(R8P),           intent(in)           :: y(:)       !< Ordinates [px].
   character(len=*),    intent(in)           :: color      !< Fill color.
   real(R8P),           intent(in)           :: diameter   !< Dot diameter [px].
   integer(I4P),        intent(in), optional :: pt         !< Point type, ignored.
   real(R8P),           intent(in), optional :: line_width !< Marker line width, ignored.
   integer(I4P)                       :: i        !< Counter.

   if (self%hidden) return
   do i = 1_I4P, size(x, kind=I4P)
      call self%px_point([x(i), y(i)], color)
   enddo
   endsubroutine dots

   subroutine polygon(self, x, y, fill, opacity, stroke, line_width, ghost)
   !< Closed polygon [px]: its inside filled (`px_fill`) unless `fill` is `none`, then its border with the symbol of
   !< `stroke` unless `none`; the opacity has no meaning in text, a ghost (unlit cell) is not drawn.
   class(backend_dumb), intent(inout) :: self       !< Device.
   real(R8P),           intent(in)    :: x(:)       !< Vertex abscissae [px].
   real(R8P),           intent(in)    :: y(:)       !< Vertex ordinates [px].
   character(len=*),    intent(in)    :: fill       !< Fill color.
   real(R8P),           intent(in)    :: opacity    !< Fill opacity, unused.
   character(len=*),    intent(in)    :: stroke     !< Border color.
   real(R8P),           intent(in)    :: line_width !< Border width, unused.
   logical,             intent(in), optional :: ghost !< Unlit cell of a segmented fill.
   integer(I4P)                       :: i          !< Vertex counter.

   if (self%hidden .or. size(x) < 2) return
   if (present(ghost)) then
      if (ghost) return
   endif
   if (fill /= 'none') call self%px_fill(x, y, fill)
   if (stroke == 'none') return
   do i = 1_I4P, size(x, kind=I4P)
      call self%px_segment([x(i), y(i)], [x(modulo(i, size(x, kind=I4P)) + 1_I4P), y(modulo(i, size(x, kind=I4P)) + 1_I4P)], &
                           stroke, '')
   enddo
   endsubroutine polygon

   subroutine image(self, x0, y0, x1, y1, rgba)
   !< Raster image over the box of top-left (`x0`, `y0`) and bottom-right (`x1`, `y1`) corners [px]: a character per cell
   !< whose centre lies inside, the density of the pixel luminance, in the pixel color.
   class(backend_dumb), intent(inout) :: self        !< Device.
   real(R8P),           intent(in)    :: x0          !< Left [px].
   real(R8P),           intent(in)    :: y0          !< Top [px].
   real(R8P),           intent(in)    :: x1          !< Right [px].
   real(R8P),           intent(in)    :: y1          !< Bottom [px].
   integer(I4P),        intent(in)    :: rgba(:,:,:) !< Pixels.
   character(len=*), parameter        :: RAMP = ' .:-=+*#%@' !< Characters by density.
   real(R8P)                          :: cx          !< Cell centre abscissa [px].
   real(R8P)                          :: cy          !< Cell centre ordinate [px].
   real(R8P)                          :: lum         !< Pixel luminance, 0..1.
   integer(I4P)                       :: c           !< Column.
   integer(I4P)                       :: r           !< Row.
   integer(I4P)                       :: i           !< Pixel column.
   integer(I4P)                       :: j           !< Pixel row.
   integer(I4P)                       :: k           !< Ramp index.

   if (self%hidden .or. x1 <= x0 .or. y1 <= y0) return
   do r = self%row(y0), self%row(y1)
      cy = (real(r, R8P) - 0.5_R8P) * self%ch
      if (cy < y0 .or. cy > y1) cycle
      j = min(size(rgba, 3, kind=I4P), 1_I4P + int((cy - y0) / (y1 - y0) * real(size(rgba, 3), R8P), I4P))
      do c = self%col(x0), self%col(x1)
         cx = (real(c, R8P) - 0.5_R8P) * self%cw
         if (cx < x0 .or. cx > x1) cycle
         i = min(size(rgba, 2, kind=I4P), 1_I4P + int((cx - x0) / (x1 - x0) * real(size(rgba, 2), R8P), I4P))
         if (rgba(4, i, j) == 0_I4P) cycle
         lum = (0.299_R8P * rgba(1, i, j) + 0.587_R8P * rgba(2, i, j) + 0.114_R8P * rgba(3, i, j)) / 255.0_R8P
         ! the darkest pixels still drawn: a blank would read as no data
         k = max(2_I4P, min(len(RAMP, kind=I4P), 1_I4P + nint(lum * real(len(RAMP) - 1, R8P), I4P)))
         call self%put(c, r, RAMP(k:k), self%color_index(hex_of(rgba(1:3, i, j))))
      enddo
   enddo
   contains
      pure function hex_of(v) result(hex)
      !< `#rrggbb` of the channels `v`.
      integer(I4P), intent(in)    :: v(3) !< Channels.
      character(len=7)            :: hex  !< Color.
      character(len=*), parameter :: D = '0123456789abcdef' !< Digits.
      integer(I4P)                :: n    !< Channel counter.

      hex = '#'
      do n = 1_I4P, 3_I4P
         hex(2 * n:2 * n) = D(v(n) / 16 + 1:v(n) / 16 + 1)
         hex(2 * n + 1:2 * n + 1) = D(modulo(v(n), 16) + 1:modulo(v(n), 16) + 1)
      enddo
      endfunction hex_of
   endsubroutine image

   subroutine text(self, x, y, string, anchor, sup, rotate)
   !< Text in the row of its baseline; superscripts appended after `^`; rotated text written top to bottom.
   class(backend_dumb), intent(inout)        :: self   !< Device.
   real(R8P),           intent(in)           :: x      !< Anchor abscissa [px].
   real(R8P),           intent(in)           :: y      !< Anchor ordinate (baseline) [px].
   character(len=*),    intent(in)           :: string !< Text.
   character(len=*),    intent(in)           :: anchor !< Horizontal anchor: `start`, `middle` or `end`.
   character(len=*),    intent(in), optional :: sup    !< Superscript appended to `string`.
   real(R8P),           intent(in), optional :: rotate !< Rotation [deg].
   character(len=:), allocatable             :: full   !< Text with superscript.
   integer(I4P)                              :: c      !< Start column.
   integer(I4P)                              :: r      !< Row.
   integer(I4P)                              :: n      !< Length.
   integer(I4P)                              :: k      !< Counter.

   if (self%hidden) return
   full = string
   if (present(sup)) then
      if (len(sup) > 0) full = full//'^'//sup
   endif
   n = len(full, kind=I4P)
   if (n == 0_I4P) return
   r = self%row(y - 0.35_R8P * self%font_size)
   c = self%col(x)
   if (present(rotate)) then
      do k = 1_I4P, n
         call self%put(c, r - n / 2_I4P + k - 1_I4P, full(k:k))
      enddo
      return
   endif
   select case (anchor)
   case ('middle')
      c = c - n / 2_I4P
   case ('end')
      c = c - n + 1_I4P
   endselect
   do k = 1_I4P, n
      call self%put(c + k - 1_I4P, r, full(k:k))
   enddo
   endsubroutine text

   subroutine begin_plot_area(self, x, y, width, height)
   !< Remember the plot area, where unit-square coordinates map.
   class(backend_dumb), intent(inout) :: self   !< Device.
   real(R8P),           intent(in)    :: x      !< Left side [px].
   real(R8P),           intent(in)    :: y      !< Top side [px].
   real(R8P),           intent(in)    :: width  !< Width [px].
   real(R8P),           intent(in)    :: height !< Height [px].

   self%area = [x, y, width, height]
   endsubroutine begin_plot_area

   subroutine end_plot_area(self)
   !< Nothing to close in text.
   class(backend_dumb), intent(inout) :: self !< Device.
   endsubroutine end_plot_area

   subroutine data_polyline(self, x, y, color, line_width, dasharray)
   !< Polyline [unit square] drawn with the color symbol, clipped to the plot area.
   class(backend_dumb), intent(inout) :: self       !< Device.
   real(R8P),           intent(in)    :: x(:)       !< Abscissae [unit].
   real(R8P),           intent(in)    :: y(:)       !< Ordinates [unit].
   character(len=*),    intent(in)    :: color      !< Stroke color.
   real(R8P),           intent(in)    :: line_width !< Stroke width [px].
   character(len=*),    intent(in)    :: dasharray  !< SVG dash array.
   integer(I4P)                       :: i          !< Counter.

   do i = 1_I4P, size(x, kind=I4P) - 1_I4P
      call self%unit_segment(x(i), y(i), x(i + 1), y(i + 1), color, '')
   enddo
   endsubroutine data_polyline

   subroutine data_dots(self, x, y, color, diameter, pt, line_width)
   !< Dots [unit square] inside the plot area drawn with the color symbol, whatever the point type.
   class(backend_dumb), intent(inout)        :: self       !< Device.
   real(R8P),           intent(in)           :: x(:)       !< Abscissae [unit].
   real(R8P),           intent(in)           :: y(:)       !< Ordinates [unit].
   character(len=*),    intent(in)           :: color      !< Fill color.
   real(R8P),           intent(in)           :: diameter   !< Dot diameter [px].
   integer(I4P),        intent(in), optional :: pt         !< Point type, ignored.
   real(R8P),           intent(in), optional :: line_width !< Marker line width, ignored.
   real(R8P)                          :: p(2)     !< Dot position [px].
   integer(I4P)                       :: i        !< Counter.

   do i = 1_I4P, size(x, kind=I4P)
      if (x(i) < 0.0_R8P .or. x(i) > 1.0_R8P .or. y(i) < 0.0_R8P .or. y(i) > 1.0_R8P) cycle
      p = [self%area(1) + x(i) * self%area(3), self%area(2) + (1.0_R8P - y(i)) * self%area(4)]
      call self%px_point(p, color)
   enddo
   endsubroutine data_dots

   subroutine data_bars(self, x1, y1, x2, y2, color, line_width, cap, vertical)
   !< Error bars [unit square] as `|` (vertical) or `-` (horizontal) runs, clipped to the plot area; no caps.
   class(backend_dumb), intent(inout) :: self       !< Device.
   real(R8P),           intent(in)    :: x1(:)      !< Bar start abscissae.
   real(R8P),           intent(in)    :: y1(:)      !< Bar start ordinates.
   real(R8P),           intent(in)    :: x2(:)      !< Bar end abscissae.
   real(R8P),           intent(in)    :: y2(:)      !< Bar end ordinates.
   character(len=*),    intent(in)    :: color      !< Stroke color.
   real(R8P),           intent(in)    :: line_width !< Stroke width [px].
   real(R8P),           intent(in)    :: cap        !< Cap length [px].
   logical,             intent(in)    :: vertical   !< Vertical bars.
   integer(I4P)                       :: i          !< Counter.

   do i = 1_I4P, size(x1, kind=I4P)
      call self%unit_segment(x1(i), y1(i), x2(i), y2(i), color, merge('|', '-', vertical))
   enddo
   endsubroutine data_bars

   subroutine data_polygon(self, x, y, fill, opacity, stroke, line_width, ghost)
   !< Closed polygon [unit square] clipped to the plot area, then drawn in it as `polygon`.
   class(backend_dumb), intent(inout) :: self       !< Device.
   real(R8P),           intent(in)    :: x(:)       !< Vertex abscissae [unit].
   real(R8P),           intent(in)    :: y(:)       !< Vertex ordinates [unit].
   character(len=*),    intent(in)    :: fill       !< Fill color.
   real(R8P),           intent(in)    :: opacity    !< Fill opacity.
   character(len=*),    intent(in)    :: stroke     !< Border color.
   real(R8P),           intent(in)    :: line_width !< Border width [px].
   logical,             intent(in), optional :: ghost !< Unlit cell of a segmented fill.
   real(R8P), allocatable             :: cx(:)      !< Clipped abscissae [unit].
   real(R8P), allocatable             :: cy(:)      !< Clipped ordinates [unit].

   call clip_unit(x, y, cx, cy)
   if (size(cx) < 3) return
   call self%polygon(self%area(1) + cx * self%area(3), self%area(2) + (1.0_R8P - cy) * self%area(4), fill, opacity, &
                     stroke, line_width, ghost)
   endsubroutine data_polygon

   subroutine data_image(self, x0, y0, x1, y1, rgba)
   !< Raster image over the box of bottom-left (`x0`, `y0`) and top-right (`x1`, `y1`) corners [unit square], clipped to
   !< the plot area: the pixels of the visible part drawn as `image`.
   class(backend_dumb), intent(inout) :: self        !< Device.
   real(R8P),           intent(in)    :: x0          !< Left [unit].
   real(R8P),           intent(in)    :: y0          !< Bottom [unit].
   real(R8P),           intent(in)    :: x1          !< Right [unit].
   real(R8P),           intent(in)    :: y1          !< Top [unit].
   integer(I4P),        intent(in)    :: rgba(:,:,:) !< Pixels.
   integer(I4P)                       :: i(2)        !< Visible pixel columns.
   integer(I4P)                       :: j(2)        !< Visible pixel rows, top to bottom.
   real(R8P)                          :: a(2)        !< Visible box, left and right [unit].
   real(R8P)                          :: b(2)        !< Visible box, bottom and top [unit].

   if (x1 <= x0 .or. y1 <= y0) return
   ! whole pixels inside the unit square, as a subimage
   i = [1_I4P + max(0_I4P, int(-x0 / (x1 - x0) * size(rgba, 2), I4P)), &
        size(rgba, 2, kind=I4P) - max(0_I4P, int((x1 - 1.0_R8P) / (x1 - x0) * size(rgba, 2), I4P))]
   j = [1_I4P + max(0_I4P, int((y1 - 1.0_R8P) / (y1 - y0) * size(rgba, 3), I4P)), &
        size(rgba, 3, kind=I4P) - max(0_I4P, int(-y0 / (y1 - y0) * size(rgba, 3), I4P))]
   if (i(1) > i(2) .or. j(1) > j(2)) return
   a = x0 + (x1 - x0) * [real(i(1) - 1_I4P, R8P), real(i(2), R8P)] / real(size(rgba, 2), R8P)
   b = y1 - (y1 - y0) * [real(j(2), R8P), real(j(1) - 1_I4P, R8P)] / real(size(rgba, 3), R8P)
   call self%image(self%area(1) + a(1) * self%area(3), self%area(2) + (1.0_R8P - b(2)) * self%area(4), &
                   self%area(1) + a(2) * self%area(3), self%area(2) + (1.0_R8P - b(1)) * self%area(4), &
                   rgba(:, i(1):i(2), j(1):j(2)))
   endsubroutine data_image

   pure function text_width(self, string, sup, font_size) result(width)
   !< Width of `string` in cells [px]: superscripts take full cells after a `^`.
   class(backend_dumb), intent(in) :: self      !< Device.
   character(len=*),    intent(in) :: string    !< Text.
   character(len=*),    intent(in) :: sup       !< Superscript.
   real(R8P),           intent(in) :: font_size !< Font size [px].
   real(R8P)                       :: width     !< Width [px].

   width = CELL_WIDTH * font_size * real(len(string), R8P)
   if (len(sup) > 0) width = width + CELL_WIDTH * font_size * real(len(sup) + 1, R8P)
   endfunction text_width

   subroutine readout(self, x, y, height, masks, label, prefix, suffix, color, font_size)
   !< Seven-segment readout of top-left corner (`x`, `y`) [px] in characters: the label row, then 3 rows of 4 columns
   !< per cell, lit segments in the series color, the whole glass written so that it covers what lies below; the
   !< digit `height` is not used, characters have one size.
   class(backend_dumb), intent(inout) :: self      !< Device.
   real(R8P),           intent(in)    :: x         !< Left side [px].
   real(R8P),           intent(in)    :: y         !< Top side [px].
   real(R8P),           intent(in)    :: height    !< Digit height [px], unused.
   integer(I4P),        intent(in)    :: masks(:)  !< Segments of each cell.
   character(len=*),    intent(in)    :: label     !< Label, empty for none.
   character(len=*),    intent(in)    :: prefix    !< Text before the glass.
   character(len=*),    intent(in)    :: suffix    !< Text after the glass.
   character(len=*),    intent(in)    :: color     !< Color of the lit segments.
   real(R8P),           intent(in)    :: font_size !< Font size [px], unused.
   character(len=4)                   :: rows(3)   !< Characters of a cell.
   integer(I4P)                       :: c0        !< Left column.
   integer(I4P)                       :: r0        !< First glass row.
   integer(I4P)                       :: cg        !< First glass column.
   integer(I4P)                       :: tint      !< Color index.
   integer(I4P)                       :: k         !< Cell counter.
   integer(I4P)                       :: i         !< Column counter.
   integer(I4P)                       :: j         !< Row counter.

   if (self%hidden) return
   c0 = self%col(x)
   r0 = self%row(y)
   if (len(label) > 0) then
      call write_text(c0, r0, label)
      r0 = r0 + 1_I4P
   endif
   cg = c0
   if (len(prefix) > 0) then
      call write_text(c0, r0 + 2_I4P, prefix)
      cg = c0 + len(prefix, kind=I4P) + 1_I4P
   endif
   tint = self%color_index(color)
   do k = 1_I4P, size(masks, kind=I4P)
      rows(1) = ' '//lit(0_I4P, '_')//'  '
      rows(2) = lit(5_I4P, '|')//lit(6_I4P, '_')//lit(1_I4P, '|')//' '
      rows(3) = lit(4_I4P, '|')//lit(3_I4P, '_')//lit(2_I4P, '|')//lit(7_I4P, '.')
      do j = 1_I4P, 3_I4P
         do i = 1_I4P, 4_I4P
            if (rows(j)(i:i) == ' ') then
               call self%put(cg + 4_I4P * (k - 1_I4P) + i - 1_I4P, r0 + j - 1_I4P, ' ')
            else
               call self%put(cg + 4_I4P * (k - 1_I4P) + i - 1_I4P, r0 + j - 1_I4P, rows(j)(i:i), tint)
            endif
         enddo
      enddo
   enddo
   if (len(suffix) > 0) call write_text(cg + 4_I4P * size(masks, kind=I4P), r0 + 2_I4P, suffix)
   contains
      pure function lit(segment, symbol) result(c)
      !< `symbol` if `segment` of the cell `k` is lit, else a blank.
      integer(I4P),     intent(in) :: segment !< Segment bit.
      character(len=1), intent(in) :: symbol  !< Symbol.
      character(len=1)             :: c       !< Character.

      c = merge(symbol, ' ', btest(masks(k), segment))
      endfunction lit

      subroutine write_text(c, r, string)
      !< `string` from column `c` of row `r`.
      integer(I4P),     intent(in) :: c      !< Start column.
      integer(I4P),     intent(in) :: r      !< Row.
      character(len=*), intent(in) :: string !< Text.
      integer(I4P)                 :: n      !< Counter.

      do n = 1_I4P, len(string, kind=I4P)
         call self%put(c + n - 1_I4P, r, string(n:n))
      enddo
      endsubroutine write_text
   endsubroutine readout

   pure function readout_extent(self, height, cells, label, prefix, suffix, font_size) result(extent)
   !< Width and height [px] of a readout in characters: 4 columns per cell and the unit text, 3 rows and the label.
   class(backend_dumb), intent(in) :: self      !< Device.
   real(R8P),           intent(in) :: height    !< Digit height [px], unused.
   integer(I4P),        intent(in) :: cells     !< Glass cells.
   character(len=*),    intent(in) :: label     !< Label, empty for none.
   character(len=*),    intent(in) :: prefix    !< Text before the glass.
   character(len=*),    intent(in) :: suffix    !< Text after the glass.
   real(R8P),           intent(in) :: font_size !< Font size [px].
   real(R8P)                       :: extent(2) !< Width and height [px].
   integer(I4P)                    :: columns   !< Columns.

   columns = 4_I4P * cells + len(suffix, kind=I4P)
   if (len(prefix) > 0) columns = columns + len(prefix, kind=I4P) + 1_I4P
   columns = max(columns, len(label, kind=I4P))
   extent = [CELL_WIDTH * font_size * real(columns, R8P), &
             CELL_HEIGHT * font_size * real(merge(4_I4P, 3_I4P, len(label) > 0), R8P)]
   endfunction readout_extent

   ! building blocks for finer devices
   pure function cell(self, c, r) result(text)
   !< Text of the cell (`c`, `r`): its character.
   class(backend_dumb), intent(in) :: self !< Device.
   integer(I4P),        intent(in) :: c    !< Column.
   integer(I4P),        intent(in) :: r    !< Row.
   character(len=:), allocatable   :: text !< Cell text (UTF-8).

   text = self%grid(c, r)
   endfunction cell

   subroutine clear(self, x, y, width, height)
   !< Blank the cells of the box of top-left corner (`x`, `y`) and size `width` x `height` [px].
   class(backend_dumb), intent(inout) :: self   !< Device.
   real(R8P),           intent(in)    :: x      !< Left side [px].
   real(R8P),           intent(in)    :: y      !< Top side [px].
   real(R8P),           intent(in)    :: width  !< Width [px].
   real(R8P),           intent(in)    :: height !< Height [px].

   self%grid(self%col(x):self%col(x + width), self%row(y):self%row(y + height)) = ' '
   self%tint(self%col(x):self%col(x + width), self%row(y):self%row(y + height)) = 0_I4P
   endsubroutine clear

   elemental function col(self, x) result(c)
   !< Column of the cell containing the abscissa `x` [px], clamped to the page.
   class(backend_dumb), intent(in) :: self !< Device.
   real(R8P),           intent(in) :: x    !< Abscissa [px].
   integer(I4P)                    :: c    !< Column.

   ! truncation, as for rows: frame and text map consistently, text below a border never lands on it
   c = min(max(1_I4P, floor(x / self%cw, I4P) + 1_I4P), size(self%grid, 1, kind=I4P))
   endfunction col

   elemental function row(self, y) result(r)
   !< Row of the cell containing the ordinate `y` [px], clamped to the page.
   class(backend_dumb), intent(in) :: self !< Device.
   real(R8P),           intent(in) :: y    !< Ordinate [px].
   integer(I4P)                    :: r    !< Row.

   r = min(max(1_I4P, floor(y / self%ch, I4P) + 1_I4P), size(self%grid, 2, kind=I4P))
   endfunction row

   function color_index(self, color) result(k)
   !< Index of `color` in `symbols`, assigning the next symbol on first use.
   class(backend_dumb), intent(inout) :: self  !< Device.
   character(len=*),    intent(in)    :: color !< SVG color.
   integer(I4P)                       :: k     !< Index.
   integer(I4P)                       :: s     !< Symbol position.
   type(color_symbol)                 :: entry !< New entry.

   do k = 1_I4P, size(self%symbols, kind=I4P)
      if (self%symbols(k)%color == color) return
   enddo
   s = modulo(k - 1_I4P, len(SYMBOLS, kind=I4P)) + 1_I4P
   entry%color = color
   entry%symbol = SYMBOLS(s:s)
   self%symbols = [self%symbols, entry]
   endfunction color_index

   subroutine px_fill(self, x, y, color)
   !< Fill the cells whose centre lies inside the polygon (`x`, `y`) [px] with the symbol of `color` (even-odd rule).
   class(backend_dumb), intent(inout) :: self    !< Device.
   real(R8P),           intent(in)    :: x(:)    !< Vertex abscissae [px].
   real(R8P),           intent(in)    :: y(:)    !< Vertex ordinates [px].
   character(len=*),    intent(in)    :: color   !< Fill color.
   real(R8P), allocatable             :: xs(:)   !< Crossings of a row.
   integer(I4P)                       :: tint    !< Color index.
   integer(I4P)                       :: r       !< Row counter.
   integer(I4P)                       :: c       !< Column counter.
   integer(I4P)                       :: k       !< Crossing pair counter.
   character(len=1)                   :: symbol  !< Fill symbol.

   tint = self%color_index(color)
   symbol = self%symbol_of(color)
   do r = self%row(minval(y)), self%row(maxval(y))
      xs = scanline(x, y, (real(r, R8P) - 0.5_R8P) * self%ch)
      do k = 1_I4P, size(xs, kind=I4P) - 1_I4P, 2_I4P
         do c = self%col(xs(k)), self%col(xs(k + 1_I4P))
            if ((real(c, R8P) - 0.5_R8P) * self%cw >= xs(k) .and. (real(c, R8P) - 0.5_R8P) * self%cw <= xs(k + 1_I4P)) &
               call self%put(c, r, symbol, tint)
         enddo
      enddo
   enddo
   endsubroutine px_fill

   subroutine px_point(self, p, color)
   !< A data point at `p` [px]: the color symbol in its cell.
   class(backend_dumb), intent(inout) :: self  !< Device.
   real(R8P),           intent(in)    :: p(2)  !< Point [px].
   character(len=*),    intent(in)    :: color !< Color.

   call self%put(self%col(p(1)), self%row(p(2)), self%symbol_of(color), self%color_index(color))
   endsubroutine px_point

   subroutine px_segment(self, a, b, color, symbol)
   !< A data segment from `a` to `b` [px] with `symbol`, or the color symbol if empty.
   class(backend_dumb), intent(inout) :: self   !< Device.
   real(R8P),           intent(in)    :: a(2)   !< Start [px].
   real(R8P),           intent(in)    :: b(2)   !< End [px].
   character(len=*),    intent(in)    :: color  !< Color.
   character(len=*),    intent(in)    :: symbol !< Symbol, empty for the color symbol.
   character(len=1)                   :: s      !< Drawn symbol.

   s = symbol
   if (len(symbol) == 0) s = self%symbol_of(color)
   call self%segment(self%col(a(1)), self%row(a(2)), self%col(b(1)), self%row(b(2)), s, .false., &
                     self%color_index(color))
   endsubroutine px_segment

   pure subroutine put(self, c, r, symbol, tint)
   !< Set cell (`c`, `r`) and its color index `tint` (default 0), ignoring cells off the page.
   class(backend_dumb), intent(inout)        :: self   !< Device.
   integer(I4P),        intent(in)           :: c      !< Column.
   integer(I4P),        intent(in)           :: r      !< Row.
   character(len=1),    intent(in)           :: symbol !< Symbol.
   integer(I4P),        intent(in), optional :: tint   !< Color index in `symbols`.

   if (c < 1_I4P .or. c > size(self%grid, 1) .or. r < 1_I4P .or. r > size(self%grid, 2)) return
   self%grid(c, r) = symbol
   self%tint(c, r) = 0_I4P
   if (present(tint)) self%tint(c, r) = tint
   endsubroutine put

   ! private procedures

   pure subroutine segment(self, c1, r1, c2, r2, symbol, blank_only, tint)
   !< Bresenham segment between cells, optionally writing blank cells only.
   class(backend_dumb), intent(inout)        :: self       !< Device.
   integer(I4P),        intent(in)           :: c1         !< Start column.
   integer(I4P),        intent(in)           :: r1         !< Start row.
   integer(I4P),        intent(in)           :: c2         !< End column.
   integer(I4P),        intent(in)           :: r2         !< End row.
   character(len=1),    intent(in)           :: symbol     !< Symbol.
   logical,             intent(in)           :: blank_only !< Write blank cells only.
   integer(I4P),        intent(in), optional :: tint       !< Color index in `symbols`.
   integer(I4P)                       :: c          !< Current column.
   integer(I4P)                       :: r          !< Current row.
   integer(I4P)                       :: dc         !< Column distance.
   integer(I4P)                       :: dr         !< Row distance (negative).
   integer(I4P)                       :: sc         !< Column step.
   integer(I4P)                       :: sr         !< Row step.
   integer(I4P)                       :: err        !< Bresenham error.
   integer(I4P)                       :: e2         !< Twice the error before the step.

   c = c1
   r = r1
   dc = abs(c2 - c1)
   dr = -abs(r2 - r1)
   sc = merge(1_I4P, -1_I4P, c1 < c2)
   sr = merge(1_I4P, -1_I4P, r1 < r2)
   err = dc + dr
   do
      if (blank_only) then
         if (c >= 1_I4P .and. c <= size(self%grid, 1) .and. r >= 1_I4P .and. r <= size(self%grid, 2)) then
            if (self%grid(c, r) == ' ') self%grid(c, r) = symbol
         endif
      else
         call self%put(c, r, symbol, tint)
      endif
      if (c == c2 .and. r == r2) exit
      ! both tests on the error before the step: testing the updated one overshoots the end on some slopes, and the
      ! loop never meets (c2, r2)
      e2 = 2_I4P * err
      if (e2 >= dr) then
         err = err + dr
         c = c + sc
      endif
      if (e2 <= dc) then
         err = err + dc
         r = r + sr
      endif
   enddo
   endsubroutine segment

   function symbol_of(self, color) result(symbol)
   !< Symbol of `color`, assigning the next one on first use.
   class(backend_dumb), intent(inout) :: self   !< Device.
   character(len=*),    intent(in)    :: color  !< SVG color.
   character(len=1)                   :: symbol !< Symbol.
   integer(I4P)                       :: k      !< Index in `symbols`.

   k = self%color_index(color)
   symbol = self%symbols(k)%symbol
   endfunction symbol_of

   subroutine unit_segment(self, u1, v1, u2, v2, color, symbol)
   !< Clip the unit-square segment to [0, 1]^2 (Liang-Barsky), then draw it in the plot area.
   class(backend_dumb), intent(inout) :: self   !< Device.
   real(R8P),           intent(in)    :: u1     !< Start abscissa [unit].
   real(R8P),           intent(in)    :: v1     !< Start ordinate [unit].
   real(R8P),           intent(in)    :: u2     !< End abscissa [unit].
   real(R8P),           intent(in)    :: v2     !< End ordinate [unit].
   character(len=*),    intent(in)    :: color  !< Color.
   character(len=*),    intent(in)    :: symbol !< Symbol, empty for the color symbol.
   real(R8P)                          :: t0     !< Clipped start parameter.
   real(R8P)                          :: t1     !< Clipped end parameter.
   real(R8P)                          :: p(4)   !< Liang-Barsky directions.
   real(R8P)                          :: q(4)   !< Liang-Barsky distances.
   real(R8P)                          :: t      !< Boundary parameter.
   real(R8P)                          :: a(2)   !< Clipped start [px].
   real(R8P)                          :: b(2)   !< Clipped end [px].
   integer(I4P)                       :: k      !< Boundary counter.

   if (self%hidden) return
   t0 = 0.0_R8P
   t1 = 1.0_R8P
   p = [-(u2 - u1), u2 - u1, -(v2 - v1), v2 - v1]
   q = [u1, 1.0_R8P - u1, v1, 1.0_R8P - v1]
   do k = 1_I4P, 4_I4P
      if (p(k) == 0.0_R8P) then
         if (q(k) < 0.0_R8P) return
      else
         t = q(k) / p(k)
         if (p(k) < 0.0_R8P) then
            t0 = max(t0, t)
         else
            t1 = min(t1, t)
         endif
      endif
   enddo
   if (t0 > t1) return
   a = [self%area(1) + (u1 + t0 * (u2 - u1)) * self%area(3), self%area(2) + (1.0_R8P - v1 - t0 * (v2 - v1)) * self%area(4)]
   b = [self%area(1) + (u1 + t1 * (u2 - u1)) * self%area(3), self%area(2) + (1.0_R8P - v1 - t1 * (v2 - v1)) * self%area(4)]
   call self%px_segment(a, b, color, symbol)
   endsubroutine unit_segment

   pure function scanline(x, y, yc) result(xs)
   !< Sorted abscissae where the horizontal line `yc` crosses the edges of the closed polygon (`x`, `y`): pairs bound its
   !< inside (even-odd rule). An edge counts its lower end and not its upper one, so a vertex on the line counts once.
   real(R8P), intent(in)  :: x(:)  !< Vertex abscissae.
   real(R8P), intent(in)  :: y(:)  !< Vertex ordinates.
   real(R8P), intent(in)  :: yc    !< Line ordinate.
   real(R8P), allocatable :: xs(:) !< Crossings, increasing.
   real(R8P)              :: t     !< Swap buffer.
   integer(I4P)           :: i     !< Vertex counter.
   integer(I4P)           :: j     !< Next vertex.
   integer(I4P)           :: n     !< Crossings.

   allocate(xs(size(x)))
   n = 0_I4P
   do i = 1_I4P, size(x, kind=I4P)
      j = modulo(i, size(x, kind=I4P)) + 1_I4P
      if ((y(i) <= yc .and. yc < y(j)) .or. (y(j) <= yc .and. yc < y(i))) then
         n = n + 1_I4P
         xs(n) = x(i) + (yc - y(i)) / (y(j) - y(i)) * (x(j) - x(i))
      endif
   enddo
   xs = xs(1:n)
   ! insertion sort: a few crossings per line
   do i = 2_I4P, n
      t = xs(i)
      j = i - 1_I4P
      do while (j >= 1_I4P)
         if (xs(j) <= t) exit
         xs(j + 1_I4P) = xs(j)
         j = j - 1_I4P
      enddo
      xs(j + 1_I4P) = t
   enddo
   endfunction scanline

   pure subroutine clip_unit(x, y, cx, cy)
   !< The polygon (`x`, `y`) clipped to the unit square (Sutherland-Hodgman, one side at a time).
   real(R8P),              intent(in)  :: x(:)  !< Vertex abscissae.
   real(R8P),              intent(in)  :: y(:)  !< Vertex ordinates.
   real(R8P), allocatable, intent(out) :: cx(:) !< Clipped abscissae.
   real(R8P), allocatable, intent(out) :: cy(:) !< Clipped ordinates.
   real(R8P), allocatable              :: ox(:) !< Output abscissae of a side.
   real(R8P), allocatable              :: oy(:) !< Output ordinates of a side.
   real(R8P)                           :: t     !< Crossing parameter on the edge.
   logical                             :: now   !< Current vertex inside the side.
   logical                             :: was   !< Previous vertex inside the side.
   integer(I4P)                        :: side  !< Side: x >= 0, x <= 1, y >= 0, y <= 1.
   integer(I4P)                        :: i     !< Vertex counter.
   integer(I4P)                        :: j     !< Previous vertex.
   integer(I4P)                        :: n     !< Output vertices.

   cx = x
   cy = y
   do side = 1_I4P, 4_I4P
      if (size(cx) == 0) return
      allocate(ox(2 * size(cx)), oy(2 * size(cx)))
      n = 0_I4P
      do i = 1_I4P, size(cx, kind=I4P)
         j = modulo(i - 2_I4P, size(cx, kind=I4P)) + 1_I4P
         now = inside(cx(i), cy(i))
         was = inside(cx(j), cy(j))
         if (now .neqv. was) then
            ! the edge from j to i crosses the side: add the crossing
            if (side <= 2_I4P) then
               t = (merge(0.0_R8P, 1.0_R8P, side == 1_I4P) - cx(j)) / (cx(i) - cx(j))
            else
               t = (merge(0.0_R8P, 1.0_R8P, side == 3_I4P) - cy(j)) / (cy(i) - cy(j))
            endif
            n = n + 1_I4P
            ox(n) = cx(j) + t * (cx(i) - cx(j))
            oy(n) = cy(j) + t * (cy(i) - cy(j))
         endif
         if (now) then
            n = n + 1_I4P
            ox(n) = cx(i)
            oy(n) = cy(i)
         endif
      enddo
      cx = ox(1:n)
      cy = oy(1:n)
      deallocate(ox, oy)
   enddo
   contains
      pure function inside(u, v) result(is)
      !< Whether (`u`, `v`) lies inside the current side.
      real(R8P), intent(in) :: u  !< Abscissa.
      real(R8P), intent(in) :: v  !< Ordinate.
      logical               :: is !< Inside.

      select case (side)
      case (1_I4P)
         is = u >= 0.0_R8P
      case (2_I4P)
         is = u <= 1.0_R8P
      case (3_I4P)
         is = v >= 0.0_R8P
      case default
         is = v <= 1.0_R8P
      endselect
      endfunction inside
   endsubroutine clip_unit

   pure function color_rgb(symbols, k, theme) result(rgb)
   !< Red, green, blue (0-255) of the color `k` of `symbols` in the `theme`; -1 for the terminal's own color: index 0, a
   !< color that is not `#rrggbb`, black or white (unreadable on one of the backgrounds).
   type(color_symbol), intent(in) :: symbols(:) !< Symbols in use.
   integer(I4P),       intent(in) :: k          !< Index, 0 for the default.
   type(theme_object), intent(in) :: theme      !< Output theme.
   integer(I4P)                   :: rgb(3)     !< Color.
   integer(I4P)                   :: i          !< Component counter.
   integer(I4P)                   :: ios        !< Conversion status.
   character(len=:), allocatable  :: color      !< Theme color.

   rgb = -1_I4P
   if (k < 1_I4P) return
   ! a local copy, not an associate: gfortran 16 aborts leaving an associate of a function result by return
   color = theme%map(symbols(k)%color)
   if (len(color) /= 7 .or. color(1:1) /= '#') return
   do i = 1_I4P, 3_I4P
      read(color(2 * i:2 * i + 1), '(Z2)', iostat=ios) rgb(i)
      if (ios /= 0_I4P) then
         rgb = -1_I4P
         return
      endif
   enddo
   if (all(rgb == 0_I4P) .or. all(rgb == 255_I4P)) rgb = -1_I4P
   endfunction color_rgb

   pure function ansi_escape(mode, rgb) result(escape)
   !< ANSI escape sequence setting the foreground to `rgb` in the color `mode`, or to the default if `rgb` is -1: the
   !< nearest of the 6 basic colors (no black and white) for `ansi`, of the 6x6x6 cube and the gray ramp for `ansi256`,
   !< the color itself for `ansirgb`.
   character(len=*), intent(in)  :: mode   !< `ansi`, `ansi256` or `ansirgb`.
   integer(I4P),     intent(in)  :: rgb(3) !< Color, -1 for the default.
   character(len=:), allocatable :: escape !< Escape sequence.
   integer(I4P), parameter       :: BASIC(3,6) = reshape([205, 0, 0,  0, 205, 0,  205, 205, 0,  0, 0, 238, &
                                                          205, 0, 205,  0, 205, 205], [3, 6]) !< xterm basic colors.
   integer(I4P), parameter       :: LEVELS(6) = [0, 95, 135, 175, 215, 255] !< xterm 256-color cube levels.
   integer(I4P)                  :: cube(3) !< Nearest cube level indexes.
   integer(I4P)                  :: gray    !< Nearest gray ramp index.
   integer(I4P)                  :: k       !< Counter.
   integer(I4P)                  :: best    !< Nearest basic color.

   if (rgb(1) < 0_I4P) then
      escape = ESC//'[39m'
      return
   endif
   select case (trim(mode))
   case ('ansi')
      best = 1_I4P
      do k = 2_I4P, 6_I4P
         if (sum((BASIC(:, k) - rgb)**2) < sum((BASIC(:, best) - rgb)**2)) best = k
      enddo
      escape = ESC//'['//str(30_I4P + best)//'m'
   case ('ansi256')
      do k = 1_I4P, 3_I4P
         cube(k) = minloc(abs(LEVELS - rgb(k)), dim=1) - 1_I4P
      enddo
      gray = min(23_I4P, max(0_I4P, (sum(rgb) / 3_I4P - 3_I4P) / 10_I4P))
      if (sum((LEVELS(cube + 1_I4P) - rgb)**2) <= sum((8_I4P + 10_I4P * gray - rgb)**2)) then
         escape = ESC//'[38;5;'//str(16_I4P + 36_I4P * cube(1) + 6_I4P * cube(2) + cube(3))//'m'
      else
         escape = ESC//'[38;5;'//str(232_I4P + gray)//'m'
      endif
   case default
      escape = ESC//'[38;2;'//str(rgb(1))//';'//str(rgb(2))//';'//str(rgb(3))//'m'
   endselect
   contains
      pure function str(n) result(text)
      !< Decimal text of `n`.
      integer(I4P), intent(in)      :: n    !< Number.
      character(len=:), allocatable :: text !< Text.
      character(len=11)             :: buffer !< Conversion buffer.

      write(buffer, '(I0)') n
      text = trim(buffer)
      endfunction str
   endfunction ansi_escape
endmodule foresight_backend_dumb
