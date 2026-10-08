!< foresight_backend_dumb, text output device (gnuplot `dumb` terminal).
module foresight_backend_dumb
!< foresight_backend_dumb, text output device (gnuplot `dumb` terminal).
!<
!< The page is a grid of character cells, `CELL_WIDTH` x `CELL_HEIGHT` font sizes each, so the layout engine works
!< unchanged in its virtual pixels. Series are drawn with gnuplot's dumb symbols, one per color in order of use, the
!< frame with `+`, `-` and `|`, the grid with `.`; superscripts become `^`. Data segments are clipped to the plot area
!< before rasterisation: points far outside the range never cost more than the cells actually drawn.
use, intrinsic :: iso_fortran_env, only : output_unit
use foresight_backend, only : axes_view, backend_object
use foresight_sys, only : rename_file
use penf, only : I4P, R8P

implicit none
private
public :: backend_dumb

character(len=*), parameter :: SYMBOLS     = '*#$%@&=+' !< Series symbols, cycled.
character(len=*), parameter :: FRAME_COLOR = 'black'    !< Frame color, drawn as ticks.
character(len=*), parameter :: GRID_COLOR  = '#a0a0a0'  !< Grid color, drawn as dots on blank cells.
real(R8P),        parameter :: CELL_WIDTH  = 0.55_R8P   !< Cell width [font size].
real(R8P),        parameter :: CELL_HEIGHT = 1.25_R8P   !< Cell height [font size].

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
      procedure, pass(self) :: text
      procedure, pass(self) :: begin_plot_area
      procedure, pass(self) :: end_plot_area
      procedure, pass(self) :: data_polyline
      procedure, pass(self) :: data_dots
      procedure, pass(self) :: data_bars
      procedure, pass(self) :: text_width
      procedure, pass(self), private :: col          !< Column of an abscissa [px].
      procedure, pass(self), private :: row          !< Row of an ordinate [px].
      procedure, pass(self), private :: put          !< Set a cell.
      procedure, pass(self), private :: segment      !< Rasterise a cell segment.
      procedure, pass(self), private :: symbol_of    !< Symbol of a color.
      procedure, pass(self), private :: unit_segment !< Clip and rasterise a unit-square segment.
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
   if (allocated(self%symbols)) deallocate(self%symbols)
   allocate(self%symbols(0))
   endsubroutine begin_page

   subroutine end_page(self)
   !< Write the page, rows right-trimmed: to standard output, or atomically to the file.
   class(backend_dumb), intent(inout) :: self !< Device.
   character(len=:), allocatable      :: line !< Row text.
   integer(I4P)                       :: unit !< Output unit.
   integer(I4P)                       :: r    !< Row counter.
   integer(I4P)                       :: c    !< Column counter.

   if (self%file == '-') then
      unit = output_unit
      if (self%clear_screen) write(unit, '(A)', advance='no') achar(27)//'[H'//achar(27)//'[2J'
   else
      open(newunit=unit, file=self%file//'.tmp', action='write', status='replace')
   endif
   allocate(character(len=size(self%grid, 1)) :: line)
   do r = 1_I4P, size(self%grid, 2, kind=I4P)
      do c = 1_I4P, size(self%grid, 1, kind=I4P)
         line(c:c) = self%grid(c, r)
      enddo
      write(unit, '(A)') trim(line)
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

   subroutine begin_group(self, name, visible)
   !< A hidden group (the grid when off) is not drawn at all.
   class(backend_dumb), intent(inout)        :: self    !< Device.
   character(len=*),    intent(in)           :: name    !< Group name.
   logical,             intent(in), optional :: visible !< Group shown.

   self%hidden = .false.
   if (present(visible)) self%hidden = .not. visible
   endsubroutine begin_group

   subroutine end_group(self)
   !< Leave the group.
   class(backend_dumb), intent(inout) :: self !< Device.

   self%hidden = .false.
   endsubroutine end_group

   subroutine rect(self, x, y, width, height, stroke, fill, line_width)
   !< Stroked rectangles are drawn with `-`, `|` and `+` corners; fills are ignored.
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

   if (stroke == 'none' .or. self%hidden) return
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
         call self%segment(self%col(x(i)), self%row(y(i)), self%col(x(i + 1)), self%row(y(i + 1)), &
                           self%symbol_of(color), .false.)
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
      call self%put(self%col(x(i)), self%row(y(i)), self%symbol_of(color))
   enddo
   endsubroutine dots

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
      call self%unit_segment(x(i), y(i), x(i + 1), y(i + 1), self%symbol_of(color))
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
      call self%put(self%col(p(1)), self%row(p(2)), self%symbol_of(color))
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
      call self%unit_segment(x1(i), y1(i), x2(i), y2(i), merge('|', '-', vertical))
   enddo
   endsubroutine data_bars

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

   ! private procedures
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

   pure subroutine put(self, c, r, symbol)
   !< Set cell (`c`, `r`), ignoring cells off the page.
   class(backend_dumb), intent(inout) :: self   !< Device.
   integer(I4P),        intent(in)    :: c      !< Column.
   integer(I4P),        intent(in)    :: r      !< Row.
   character(len=1),    intent(in)    :: symbol !< Symbol.

   if (c < 1_I4P .or. c > size(self%grid, 1) .or. r < 1_I4P .or. r > size(self%grid, 2)) return
   self%grid(c, r) = symbol
   endsubroutine put

   pure subroutine segment(self, c1, r1, c2, r2, symbol, blank_only)
   !< Bresenham segment between cells, optionally writing blank cells only.
   class(backend_dumb), intent(inout) :: self       !< Device.
   integer(I4P),        intent(in)    :: c1         !< Start column.
   integer(I4P),        intent(in)    :: r1         !< Start row.
   integer(I4P),        intent(in)    :: c2         !< End column.
   integer(I4P),        intent(in)    :: r2         !< End row.
   character(len=1),    intent(in)    :: symbol     !< Symbol.
   logical,             intent(in)    :: blank_only !< Write blank cells only.
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
         call self%put(c, r, symbol)
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
   type(color_symbol)                 :: entry  !< New entry.
   integer(I4P)                       :: s      !< Counter.
   integer(I4P)                       :: k      !< Symbol index.

   do s = 1_I4P, size(self%symbols, kind=I4P)
      if (self%symbols(s)%color == color) then
         symbol = self%symbols(s)%symbol
         return
      endif
   enddo
   k = modulo(size(self%symbols, kind=I4P), len(SYMBOLS, kind=I4P)) + 1_I4P
   entry%color = color
   entry%symbol = SYMBOLS(k:k)
   self%symbols = [self%symbols, entry]
   symbol = entry%symbol
   endfunction symbol_of

   subroutine unit_segment(self, u1, v1, u2, v2, symbol)
   !< Clip the unit-square segment to [0, 1]^2 (Liang-Barsky), then rasterise it in the plot area.
   class(backend_dumb), intent(inout) :: self   !< Device.
   real(R8P),           intent(in)    :: u1     !< Start abscissa [unit].
   real(R8P),           intent(in)    :: v1     !< Start ordinate [unit].
   real(R8P),           intent(in)    :: u2     !< End abscissa [unit].
   real(R8P),           intent(in)    :: v2     !< End ordinate [unit].
   character(len=1),    intent(in)    :: symbol !< Symbol.
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
   call self%segment(self%col(a(1)), self%row(a(2)), self%col(b(1)), self%row(b(2)), symbol, .false.)
   endsubroutine unit_segment
endmodule foresight_backend_dumb
