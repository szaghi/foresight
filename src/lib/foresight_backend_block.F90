!< foresight_backend_block, text output device drawing with Unicode block or Braille characters (gnuplot `block`).
module foresight_backend_block
!< foresight_backend_block, text output device drawing with Unicode block or Braille characters (gnuplot `block`).
!<
!< The page is the character grid of foresight_backend_dumb, its layout and text unchanged; the graphics (frame, ticks,
!< grid, series, key samples) are drawn on a bitmap of `sx` x `sy` dots per cell, each cell written as the character
!< of its dots: `half` (1x2, half blocks), `quadrants` (2x2, the default as in gnuplot), `sextants` (2x3, Unicode 13)
!< or `braille` (2x4). Text is written over the graphics. Unlike gnuplot, a cell without dots is a blank, Braille
!< included, so rows trim and copy as text; a point is its dot and the four neighbours. A cell takes the color of the
!< last series drawn in it.
use foresight_style, only : pattern_parts
use foresight_backend_dumb, only : backend_dumb, FRAME_COLOR, GRID_COLOR, scanline
use penf, only : I4P, R8P

implicit none
private
public :: backend_block
public :: BLOCK_CHARSETS

character(len=*), parameter :: BLOCK_CHARSETS = 'half quadrants sextants braille' !< Character sets (gnuplot names).

type, extends(backend_dumb) :: backend_block
   !< Block character text device.
   character(len=9)     :: charset = 'quadrants' !< Character set.
   integer(I4P)         :: sx = 2_I4P            !< Dots per cell, horizontally.
   integer(I4P)         :: sy = 2_I4P            !< Dots per cell, vertically.
   logical, allocatable :: dots_on(:,:)          !< Bitmap, (dot column, dot row).
   integer(I4P)         :: clip(4) = 0_I4P       !< Dots of the open plot area: first, last column, first, last row;
                                                 !< all 0 outside one.
   contains
      procedure, pass(self) :: begin_page
      procedure, pass(self) :: begin_plot_area
      procedure, pass(self) :: end_plot_area
      procedure, pass(self) :: cell
      procedure, pass(self) :: clear
      procedure, pass(self) :: polyline
      procedure, pass(self) :: px_fill
      procedure, pass(self) :: px_point
      procedure, pass(self) :: px_segment
      procedure, pass(self) :: rect
      procedure, pass(self), private :: dot      !< Set a dot.
      procedure, pass(self), private :: dot_line !< Rasterise a dot segment.
endtype backend_block

contains
   subroutine begin_page(self, file, width, height, font_size)
   !< Start a blank page and its bitmap.
   class(backend_block), intent(inout) :: self      !< Device.
   character(len=*),     intent(in)    :: file      !< Output file, `-` for standard output.
   real(R8P),            intent(in)    :: width     !< Page width [px].
   real(R8P),            intent(in)    :: height    !< Page height [px].
   real(R8P),            intent(in)    :: font_size !< Font size [px].

   call self%backend_dumb%begin_page(file, width, height, font_size)
   select case (trim(self%charset))
   case ('half')
      self%sx = 1_I4P
      self%sy = 2_I4P
   case ('sextants')
      self%sx = 2_I4P
      self%sy = 3_I4P
   case ('braille')
      self%sx = 2_I4P
      self%sy = 4_I4P
   case default
      self%sx = 2_I4P
      self%sy = 2_I4P
   endselect
   if (allocated(self%dots_on)) deallocate(self%dots_on)
   allocate(self%dots_on(size(self%grid, 1) * self%sx, size(self%grid, 2) * self%sy))
   self%dots_on = .false.
   endsubroutine begin_page

   subroutine begin_plot_area(self, x, y, width, height)
   !< Remember the plot area and its dots, where point markers are clipped.
   class(backend_block), intent(inout) :: self   !< Device.
   real(R8P),            intent(in)    :: x      !< Left side [px].
   real(R8P),            intent(in)    :: y      !< Top side [px].
   real(R8P),            intent(in)    :: width  !< Width [px].
   real(R8P),            intent(in)    :: height !< Height [px].

   call self%backend_dumb%begin_plot_area(x, y, width, height)
   self%clip = [dot_index(x, self%cw, self%sx, size(self%dots_on, 1, kind=I4P)), &
                dot_index(x + width, self%cw, self%sx, size(self%dots_on, 1, kind=I4P)), &
                dot_index(y, self%ch, self%sy, size(self%dots_on, 2, kind=I4P)), &
                dot_index(y + height, self%ch, self%sy, size(self%dots_on, 2, kind=I4P))]
   endsubroutine begin_plot_area

   subroutine end_plot_area(self)
   !< Leave the plot area: markers are no longer clipped (key samples).
   class(backend_block), intent(inout) :: self !< Device.

   self%clip = 0_I4P
   endsubroutine end_plot_area

   pure function cell(self, c, r) result(text)
   !< Text of the cell (`c`, `r`): its text character, else the character of its dots, a blank if none.
   class(backend_block), intent(in) :: self !< Device.
   integer(I4P),         intent(in) :: c    !< Column.
   integer(I4P),         intent(in) :: r    !< Row.
   character(len=:), allocatable    :: text !< Cell text (UTF-8).
   integer(I4P)                     :: bits !< Dots of the cell, bit (i - 1) + sx * (j - 1) for dot (i, j).
   integer(I4P)                     :: i    !< Dot column in the cell.
   integer(I4P)                     :: j    !< Dot row in the cell.

   if (self%grid(c, r) /= ' ') then
      text = self%grid(c, r)
      return
   endif
   bits = 0_I4P
   do j = 1_I4P, self%sy
      do i = 1_I4P, self%sx
         if (self%dots_on((c - 1_I4P) * self%sx + i, (r - 1_I4P) * self%sy + j)) &
            bits = ibset(bits, (i - 1_I4P) + self%sx * (j - 1_I4P))
      enddo
   enddo
   text = ' '
   if (bits == 0_I4P) return
   text = utf8(code_point(self%charset, bits))
   endfunction cell

   subroutine clear(self, x, y, width, height)
   !< Blank the cells and the dots of the box of top-left corner (`x`, `y`) and size `width` x `height` [px].
   class(backend_block), intent(inout) :: self   !< Device.
   real(R8P),            intent(in)    :: x      !< Left side [px].
   real(R8P),            intent(in)    :: y      !< Top side [px].
   real(R8P),            intent(in)    :: width  !< Width [px].
   real(R8P),            intent(in)    :: height !< Height [px].
   integer(I4P)                        :: i(2)   !< First and last dot columns.
   integer(I4P)                        :: j(2)   !< First and last dot rows.

   call self%backend_dumb%clear(x, y, width, height)
   ! whole cells, as the text grid
   i = [(self%col(x) - 1_I4P) * self%sx + 1_I4P, self%col(x + width) * self%sx]
   j = [(self%row(y) - 1_I4P) * self%sy + 1_I4P, self%row(y + height) * self%sy]
   self%dots_on(i(1):i(2), j(1):j(2)) = .false.
   endsubroutine clear

   subroutine polyline(self, x, y, color, line_width, dasharray)
   !< Frame lines (ticks) and key samples drawn on the bitmap, grid lines dotted (every other dot).
   class(backend_block), intent(inout) :: self       !< Device.
   real(R8P),            intent(in)    :: x(:)       !< Abscissae [px].
   real(R8P),            intent(in)    :: y(:)       !< Ordinates [px].
   character(len=*),     intent(in)    :: color      !< Stroke color.
   real(R8P),            intent(in)    :: line_width !< Stroke width [px].
   character(len=*),     intent(in)    :: dasharray  !< SVG dash array.
   integer(I4P)                        :: i          !< Counter.

   if (self%hidden) return
   do i = 1_I4P, size(x, kind=I4P) - 1_I4P
      if (color == FRAME_COLOR .or. color == GRID_COLOR) then
         call self%dot_line([x(i), y(i)], [x(i + 1), y(i + 1)], 0_I4P, color == GRID_COLOR)
      else
         call self%px_segment([x(i), y(i)], [x(i + 1), y(i + 1)], color, '')
      endif
   enddo
   endsubroutine polyline

   subroutine px_fill(self, x, y, color)
   !< Fill the dots whose centre lies inside the polygon (`x`, `y`) [px], coloring their cells (even-odd rule).
   class(backend_block), intent(inout) :: self  !< Device.
   real(R8P),            intent(in)    :: x(:)  !< Vertex abscissae [px].
   real(R8P),            intent(in)    :: y(:)  !< Vertex ordinates [px].
   character(len=*),     intent(in)    :: color !< Fill color.
   real(R8P), allocatable              :: xs(:) !< Crossings of a dot row.
   real(R8P)                           :: dw    !< Dot width [px].
   real(R8P)                           :: dh    !< Dot height [px].
   integer(I4P)                        :: tint  !< Color index.
   integer(I4P)                        :: i     !< Dot column.
   integer(I4P)                        :: j     !< Dot row.
   integer(I4P)                        :: k     !< Crossing pair counter.
   integer(I4P)                        :: pattern !< Fill pattern, 0 for none.
   character(len=:), allocatable       :: paint !< Fill color, a pattern's color.

   ! a pattern fill sets the dots of its hatches: lines down (4, 7), up (5, 6), both (1, 2)
   call pattern_parts(color, pattern, paint)
   tint = self%color_index(paint)
   dw = self%cw / real(self%sx, R8P)
   dh = self%ch / real(self%sy, R8P)
   do j = dot_index(minval(y), self%ch, self%sy, size(self%dots_on, 2, kind=I4P)), &
          dot_index(maxval(y), self%ch, self%sy, size(self%dots_on, 2, kind=I4P))
      xs = scanline(x, y, (real(j, R8P) - 0.5_R8P) * dh)
      do k = 1_I4P, size(xs, kind=I4P) - 1_I4P, 2_I4P
         do i = dot_index(xs(k), self%cw, self%sx, size(self%dots_on, 1, kind=I4P)), &
                dot_index(xs(k + 1_I4P), self%cw, self%sx, size(self%dots_on, 1, kind=I4P))
            if ((real(i, R8P) - 0.5_R8P) * dw >= xs(k) .and. (real(i, R8P) - 0.5_R8P) * dw <= xs(k + 1_I4P)) then
               if (hatched(i, j)) call self%dot(i, j, tint)
            endif
         enddo
      enddo
   enddo
   contains
      pure function hatched(i, j) result(on)
      !< Whether the dot (`i`, `j`) belongs to the fill pattern.
      integer(I4P), intent(in) :: i  !< Dot column.
      integer(I4P), intent(in) :: j  !< Dot row.
      logical                  :: on !< Set.

      select case (pattern)
      case (1_I4P, 2_I4P)
         on = modulo(i - j, 3_I4P) == 0_I4P .or. modulo(i + j, 3_I4P) == 0_I4P
      case (4_I4P, 7_I4P)
         on = modulo(i - j, 3_I4P) == 0_I4P
      case (5_I4P, 6_I4P)
         on = modulo(i + j, 3_I4P) == 0_I4P
      case default
         on = .true.
      endselect
      endfunction hatched
   endsubroutine px_fill

   subroutine px_point(self, p, color)
   !< A data point at `p` [px]: its dot and the four neighbours, inside the plot area when in one.
   class(backend_block), intent(inout) :: self  !< Device.
   real(R8P),            intent(in)    :: p(2)  !< Point [px].
   character(len=*),     intent(in)    :: color !< Color.
   integer(I4P)                        :: i     !< Dot column of the point.
   integer(I4P)                        :: j     !< Dot row of the point.
   integer(I4P)                        :: tint  !< Color index.

   tint = self%color_index(color)
   i = dot_index(p(1), self%cw, self%sx, size(self%dots_on, 1, kind=I4P))
   j = dot_index(p(2), self%ch, self%sy, size(self%dots_on, 2, kind=I4P))
   call clipped(i, j)
   call clipped(i - 1_I4P, j)
   call clipped(i + 1_I4P, j)
   call clipped(i, j - 1_I4P)
   call clipped(i, j + 1_I4P)
   contains
      subroutine clipped(di, dj)
      !< Set dot (`di`, `dj`) unless outside the open plot area.
      integer(I4P), intent(in) :: di !< Dot column.
      integer(I4P), intent(in) :: dj !< Dot row.

      if (self%clip(1) > 0_I4P) then
         if (di < self%clip(1) .or. di > self%clip(2) .or. dj < self%clip(3) .or. dj > self%clip(4)) return
      endif
      call self%dot(di, dj, tint)
      endsubroutine clipped
   endsubroutine px_point

   subroutine px_segment(self, a, b, color, symbol)
   !< A data segment from `a` to `b` [px] on the bitmap; `symbol` (the error bar character in text) is not used, but
   !< for the grid one `.`: a dotted line.
   class(backend_block), intent(inout) :: self   !< Device.
   real(R8P),            intent(in)    :: a(2)   !< Start [px].
   real(R8P),            intent(in)    :: b(2)   !< End [px].
   character(len=*),     intent(in)    :: color  !< Color.
   character(len=*),     intent(in)    :: symbol !< Symbol: `.` dots the line.

   call self%dot_line(a, b, self%color_index(color), symbol == '.')
   endsubroutine px_segment

   subroutine rect(self, x, y, width, height, stroke, fill, line_width)
   !< Stroked rectangles drawn on the bitmap; a fill blanks the cells and dots covered.
   class(backend_block), intent(inout) :: self       !< Device.
   real(R8P),            intent(in)    :: x          !< Left side [px].
   real(R8P),            intent(in)    :: y          !< Top side [px].
   real(R8P),            intent(in)    :: width      !< Width [px].
   real(R8P),            intent(in)    :: height     !< Height [px].
   character(len=*),     intent(in)    :: stroke     !< Stroke color.
   character(len=*),     intent(in)    :: fill       !< Fill color.
   real(R8P),            intent(in)    :: line_width !< Stroke width [px].

   if (self%hidden) return
   if (fill /= 'none') call self%clear(x, y, width, height)
   if (stroke == 'none') return
   call self%dot_line([x, y], [x + width, y], 0_I4P, .false.)
   call self%dot_line([x + width, y], [x + width, y + height], 0_I4P, .false.)
   call self%dot_line([x + width, y + height], [x, y + height], 0_I4P, .false.)
   call self%dot_line([x, y + height], [x, y], 0_I4P, .false.)
   endsubroutine rect

   ! private procedures
   pure subroutine dot(self, i, j, tint)
   !< Set dot (`i`, `j`) and color its cell with `tint` (unless 0, or the cell holds text), ignoring dots off the page.
   class(backend_block), intent(inout) :: self !< Device.
   integer(I4P),         intent(in)    :: i    !< Dot column.
   integer(I4P),         intent(in)    :: j    !< Dot row.
   integer(I4P),         intent(in)    :: tint !< Color index, 0 to keep the cell color.
   integer(I4P)                        :: c    !< Cell column.
   integer(I4P)                        :: r    !< Cell row.

   if (i < 1_I4P .or. i > size(self%dots_on, 1) .or. j < 1_I4P .or. j > size(self%dots_on, 2)) return
   self%dots_on(i, j) = .true.
   c = (i - 1_I4P) / self%sx + 1_I4P
   r = (j - 1_I4P) / self%sy + 1_I4P
   if (tint /= 0_I4P .and. self%grid(c, r) == ' ') self%tint(c, r) = tint
   endsubroutine dot

   pure subroutine dot_line(self, a, b, tint, dotted)
   !< Bresenham segment of dots from `a` to `b` [px], every other dot if `dotted`.
   class(backend_block), intent(inout) :: self   !< Device.
   real(R8P),            intent(in)    :: a(2)   !< Start [px].
   real(R8P),            intent(in)    :: b(2)   !< End [px].
   integer(I4P),         intent(in)    :: tint   !< Color index, 0 for the default.
   logical,              intent(in)    :: dotted !< Every other dot only.
   integer(I4P)                        :: i      !< Current dot column.
   integer(I4P)                        :: j      !< Current dot row.
   integer(I4P)                        :: i2     !< End dot column.
   integer(I4P)                        :: j2     !< End dot row.
   integer(I4P)                        :: di     !< Column distance.
   integer(I4P)                        :: dj     !< Row distance (negative).
   integer(I4P)                        :: si     !< Column step.
   integer(I4P)                        :: sj     !< Row step.
   integer(I4P)                        :: err    !< Bresenham error.
   integer(I4P)                        :: e2     !< Twice the error before the step.
   integer(I4P)                        :: n      !< Dots visited.

   ! dots clamped to the page, as cells are: a segment far off the page costs no more than the page (data segments
   ! arrive clipped to the plot area)
   i = dot_index(a(1), self%cw, self%sx, size(self%dots_on, 1, kind=I4P))
   j = dot_index(a(2), self%ch, self%sy, size(self%dots_on, 2, kind=I4P))
   i2 = dot_index(b(1), self%cw, self%sx, size(self%dots_on, 1, kind=I4P))
   j2 = dot_index(b(2), self%ch, self%sy, size(self%dots_on, 2, kind=I4P))
   di = abs(i2 - i)
   dj = -abs(j2 - j)
   si = merge(1_I4P, -1_I4P, i < i2)
   sj = merge(1_I4P, -1_I4P, j < j2)
   err = di + dj
   n = 0_I4P
   do
      if (.not. dotted .or. modulo(n, 2_I4P) == 0_I4P) call self%dot(i, j, tint)
      n = n + 1_I4P
      if (i == i2 .and. j == j2) exit
      ! both tests on the error before the step (see backend_dumb%segment)
      e2 = 2_I4P * err
      if (e2 >= dj) then
         err = err + dj
         i = i + si
      endif
      if (e2 <= di) then
         err = err + di
         j = j + sj
      endif
   enddo
   endsubroutine dot_line

   elemental function dot_index(p, cell_size, per_cell, last) result(d)
   !< Dot containing the coordinate `p` [px] with cells `cell_size` px wide of `per_cell` dots, clamped to 1..`last`.
   real(R8P),    intent(in) :: p         !< Coordinate [px].
   real(R8P),    intent(in) :: cell_size !< Cell size [px].
   integer(I4P), intent(in) :: per_cell  !< Dots per cell.
   integer(I4P), intent(in) :: last      !< Last dot.
   integer(I4P)             :: d         !< Dot.

   d = min(max(1_I4P, floor(p / cell_size * real(per_cell, R8P), I4P) + 1_I4P), last)
   endfunction dot_index

   pure function code_point(charset, bits) result(code)
   !< Unicode code point of the cell character of `charset` with the dots `bits`, non-zero: bit i + sx * j for the dot of
   !< column i and row j (from 0, left to right, top to bottom).
   character(len=*), intent(in) :: charset !< Character set.
   integer(I4P),     intent(in) :: bits    !< Dots.
   integer(I4P)                 :: code    !< Code point.
   ! by dots: upper left 1, upper right 2, lower left 4, lower right 8
   integer(I4P), parameter      :: QUADRANTS(15) = [int(z'2598'), int(z'259D'), int(z'2580'), int(z'2596'), &
                                                    int(z'258C'), int(z'259E'), int(z'259B'), int(z'2597'), &
                                                    int(z'259A'), int(z'2590'), int(z'259C'), int(z'2584'), &
                                                    int(z'2599'), int(z'259F'), int(z'2588')]
   ! by dots: upper 1, lower 2
   integer(I4P), parameter      :: HALVES(3) = [int(z'2580'), int(z'2584'), int(z'2588')]
   ! Braille dot values of the bits: dots 1, 4 (upper row), 2, 5, 3, 6, then 7, 8 (lower row)
   integer(I4P), parameter      :: BRAILLE(8) = [1, 8, 2, 16, 4, 32, 64, 128]
   integer(I4P)                 :: k       !< Bit counter.

   select case (trim(charset))
   case ('half')
      code = HALVES(bits)
   case ('sextants')
      ! U+1FB00 onwards in bit order, skipping the left and right halves (21, 42) and the full block (63)
      select case (bits)
      case (21_I4P)
         code = int(z'258C')
      case (42_I4P)
         code = int(z'2590')
      case (63_I4P)
         code = int(z'2588')
      case default
         code = int(z'1FB00') + bits - 1_I4P
         if (bits > 21_I4P) code = code - 1_I4P
         if (bits > 42_I4P) code = code - 1_I4P
      endselect
   case ('braille')
      code = int(z'2800')
      do k = 0_I4P, 7_I4P
         if (btest(bits, k)) code = code + BRAILLE(k + 1_I4P)
      enddo
   case default
      code = QUADRANTS(bits)
   endselect
   endfunction code_point

   pure function utf8(code) result(text)
   !< UTF-8 encoding of the code point `code` (at most U+10FFFF).
   integer(I4P), intent(in)      :: code !< Code point.
   character(len=:), allocatable :: text !< Encoded bytes.

   if (code < int(z'80')) then
      text = achar(code)
   elseif (code < int(z'800')) then
      text = char(int(z'C0') + ishft(code, -6))//char(int(z'80') + iand(code, int(z'3F')))
   elseif (code < int(z'10000')) then
      text = char(int(z'E0') + ishft(code, -12))//char(int(z'80') + iand(ishft(code, -6), int(z'3F')))// &
             char(int(z'80') + iand(code, int(z'3F')))
   else
      text = char(int(z'F0') + ishft(code, -18))//char(int(z'80') + iand(ishft(code, -12), int(z'3F')))// &
             char(int(z'80') + iand(ishft(code, -6), int(z'3F')))//char(int(z'80') + iand(code, int(z'3F')))
   endif
   endfunction utf8
endmodule foresight_backend_block
