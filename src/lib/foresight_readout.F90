!< foresight_readout, seven-segment readouts: the glass a printf format defines and the segments a value lights on it.
module foresight_readout
!< foresight_readout, seven-segment readouts: the glass a printf format defines and the segments a value lights on it.
!<
!< A readout shows one number (the last finite value of a series) on a fixed-segment display, as the digital clusters
!< of 1980s cars: every cell of the glass is always there, the value only lights some of its segments. The glass is
!< therefore decided by the format, never by the value: `%9.2e` makes 8 cells (the decimal point is a segment of the
!< cell before it, as on real displays), and it keeps that width whatever the value, so a watched readout never jumps.
!<
!< A cell is a bit mask: bits 0 to 6 the segments a (top), b (top right), c (bottom right), d (bottom), e (bottom
!< left), f (top left), g (middle), bit 7 (`SEGMENT_DP`) the decimal point. A value with no finite reading, or wider
!< than the glass (printf would widen the field), lights the middle segment of every cell: dashes, never truncated
!< digits. The text around the conversion (`'%5.2f h'`) is not on the glass: it is the printed unit beside it.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite, ieee_quiet_nan, ieee_value
use foresight_format, only : decimal_of, format_decimal, split_format
use penf, only : I4P, I8P, R8P

implicit none
private
public :: DEFAULT_READOUT_FORMAT
public :: SEGMENT_DP
public :: SEGMENT_MIDDLE
public :: last_finite
public :: readout_check
public :: readout_glass

character(len=*), parameter :: DEFAULT_READOUT_FORMAT = '%10.3e' !< Format of a readout without one: any magnitude.
integer(I4P),     parameter :: SEGMENT_DP     = 7_I4P            !< Bit of the decimal point.
integer(I4P),     parameter :: SEGMENT_MIDDLE = 64_I4P           !< Mask of the middle segment g alone: a dash.
integer(I4P),     parameter :: DIGITS(0:9)    = [63_I4P, 6_I4P, 91_I4P, 79_I4P, 102_I4P, 109_I4P, 125_I4P, 7_I4P, &
                                                 127_I4P, 111_I4P] !< Masks of the digits 0..9.
integer(I4P),     parameter :: LETTER_E       = 121_I4P          !< Mask of `E`: segments a, d, e, f, g.

contains
   pure function readout_check(format) result(message)
   !< Empty if `format` is a readout format: a tick format (see foresight_format `format_check`) with a field width,
   !< which fixes the glass, and not `%h`, whose superscript has no seven-segment form.
   character(len=*), intent(in)  :: format  !< Format.
   character(len=:), allocatable :: message !< Problem, empty if none.
   character(len=:), allocatable :: prefix  !< Text before the conversion.
   character(len=:), allocatable :: suffix  !< Text after the conversion.
   character(len=:), allocatable :: flags   !< Conversion flags.
   character(len=1)              :: type    !< Conversion type.
   integer(I4P)                  :: width   !< Field width.
   integer(I4P)                  :: prec    !< Precision, -1 if absent.

   call split_format(format, prefix, flags, width, prec, type, suffix, message)
   if (len(message) > 0) return
   if (type == 'h') then
      message = 'readout format "'//format//'": %h has no seven-segment form (use %e or %g)'
   elseif (width == 0_I4P) then
      message = 'readout format "'//format//'" needs a field width, which fixes the glass, e.g. %9.2e'
   elseif (glass_cells(width, prec, type) < 1_I4P) then
      message = 'readout format "'//format//'": the field width leaves no digit'
   endif
   endfunction readout_check

   pure subroutine readout_glass(format, value, masks, prefix, suffix)
   !< Cells of the glass of the readout `format` (see `readout_check`), lit by `value`; `prefix` and `suffix` are the
   !< text around the conversion, printed beside the glass.
   character(len=*),              intent(in)  :: format   !< Readout format.
   real(R8P),                     intent(in)  :: value    !< Value shown; not finite for none.
   integer(I4P), allocatable,     intent(out) :: masks(:) !< Segments of each cell, left to right.
   character(len=:), allocatable, intent(out) :: prefix   !< Text before the glass.
   character(len=:), allocatable, intent(out) :: suffix   !< Text after the glass.
   character(len=:), allocatable              :: flags    !< Conversion flags.
   character(len=:), allocatable              :: message  !< Format problem.
   character(len=:), allocatable              :: label    !< Formatted value with the text around it.
   character(len=:), allocatable              :: sup      !< Superscript, never set by a readout format.
   integer(I4P),     allocatable              :: lit(:)   !< Cells of the formatted value.
   character(len=1)                           :: type     !< Conversion type.
   integer(I4P)                               :: width    !< Field width.
   integer(I4P)                               :: prec     !< Precision, -1 if absent.
   integer(I8P)                               :: n        !< Mantissa of the value.
   integer(I4P)                               :: e        !< Exponent of the value.
   integer(I4P)                               :: k        !< Cells of the formatted value.
   integer(I4P)                               :: i        !< Character counter.

   call split_format(format, prefix, flags, width, prec, type, suffix, message)
   allocate(masks(max(1_I4P, glass_cells(width, prec, type))))
   masks = SEGMENT_MIDDLE
   if (.not. ieee_is_finite(value)) return
   call decimal_of(value, n, e)
   call format_decimal(format, n, e, label, sup)
   associate(body => label(len(prefix) + 1:len(label) - len(suffix)))
      allocate(lit(len(body)))
      k = 0_I4P
      do i = 1_I4P, len(body, kind=I4P)
         if (body(i:i) == '.') then
            ! the point lights a segment of the cell before it
            if (k == 0_I4P) then
               k = 1_I4P
               lit(k) = 0_I4P
            endif
            lit(k) = ibset(lit(k), SEGMENT_DP)
         else
            k = k + 1_I4P
            lit(k) = glyph(body(i:i))
         endif
      enddo
   endassociate
   ! wider than the glass: dashes
   if (k > size(masks, kind=I4P)) return
   masks = 0_I4P
   masks(size(masks, kind=I4P) - k + 1_I4P:) = lit(1:k)
   endsubroutine readout_glass

   pure function last_finite(y) result(value)
   !< Last finite element of `y`, NaN if none: the reading of a readout.
   real(R8P), intent(in) :: y(:)  !< Series ordinates.
   real(R8P)             :: value !< Reading.
   integer(I4P)          :: i     !< Counter.

   do i = size(y, kind=I4P), 1_I4P, -1_I4P
      if (ieee_is_finite(y(i))) then
         value = y(i)
         return
      endif
   enddo
   value = ieee_value(1.0_R8P, ieee_quiet_nan)
   endfunction last_finite

   ! private procedures
   pure function glass_cells(width, prec, type) result(cells)
   !< Cells of the glass of a conversion: its field width, less the decimal point that `f` and `e` always print with a
   !< non-zero precision (it lights a segment of a cell); `g` may print one or not, the spare cell stays blank.
   integer(I4P),     intent(in) :: width !< Field width.
   integer(I4P),     intent(in) :: prec  !< Precision, -1 if absent (6).
   character(len=1), intent(in) :: type  !< Conversion type.
   integer(I4P)                 :: cells !< Cells.

   cells = width
   if ((type == 'f' .or. type == 'e' .or. type == 'E') .and. prec /= 0_I4P) cells = width - 1_I4P
   endfunction glass_cells

   elemental function glyph(c) result(mask)
   !< Segments lit by the character `c` of a formatted number: a digit, `-` (the middle segment), `e` or `E`; blanks and
   !< `+` (an exponent sign) light none, keeping `e+02` and `e-02` on the same cells.
   character(len=1), intent(in) :: c    !< Character.
   integer(I4P)                 :: mask !< Segments.

   select case (c)
   case ('0':'9')
      mask = DIGITS(iachar(c) - iachar('0'))
   case ('-')
      mask = SEGMENT_MIDDLE
   case ('e', 'E')
      mask = LETTER_E
   case default
      mask = 0_I4P
   endselect
   endfunction glyph
endmodule foresight_readout
