!< foresight_readout test: glass cells of readout formats, the segments a value lights, dashes, format checks.
program foresight_readout_test
!< foresight_readout test: glass cells of readout formats, the segments a value lights, dashes, format checks.
!<
!< Cells are compared as text: a digit, `-`, `E` or a blank per cell, `.` after a cell whose decimal point is lit.
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan, ieee_quiet_nan, ieee_value
use, intrinsic :: iso_fortran_env, only : output_unit
use foresight_readout, only : last_finite, readout_check, readout_glass, SEGMENT_DP
use penf, only : I4P, R8P

implicit none
real(R8P)                     :: nan             !< Quiet NaN.
character(len=:), allocatable :: prefix          !< Text before the glass.
character(len=:), allocatable :: suffix          !< Text after the glass.
logical                       :: test_passed(18) !< Per-check outcome.

nan = ieee_value(1.0_R8P, ieee_quiet_nan)
! the point is a segment: %9.2e has 8 cells, the sign blank one of them
test_passed(1) = glass('%9.2e', 0.0154_R8P) == ' 1.54E-02'
! no point: as many cells as the width
test_passed(2) = glass('%7.0f', 16010.0_R8P) == '  16010'
! %g prints a point or not: the glass keeps the width, the spare cell blank on the left
test_passed(3) = glass('%8.3G', 2.5e-5_R8P) == '  2.5E-05'
test_passed(4) = glass('%8.3g', 42.0_R8P) == '      42'
! a + sign or exponent sign lights nothing, keeping the cells of e+02 and e-02 aligned
test_passed(5) = glass('%+8.2f', 3.14159_R8P) == '    3.14'
test_passed(6) = glass('%9.2e', 154.0_R8P) == ' 1.54E 02'
! minus sign, left justification
test_passed(7) = glass('%6.1f', -2.5_R8P) == '  -2.5'
test_passed(8) = glass('%-8.1f', 2.5_R8P) == '2.5     '
! no finite reading, or wider than the glass: dashes, never truncated digits
test_passed(9) = glass('%9.2e', nan) == '--------'
test_passed(10) = glass('%5.1f', 12345.0_R8P) == '----'
! the text around the conversion is the unit beside the glass, not on it
test_passed(11) = glass('T=%5.2f h', 2.17_R8P) == ' 2.17' .and. prefix == 'T=' .and. suffix == ' h'
! the reading is the last finite value
test_passed(12) = last_finite([1.0_R8P, 2.0_R8P, nan]) == 2.0_R8P
test_passed(13) = ieee_is_nan(last_finite([nan, nan])) .and. ieee_is_nan(last_finite([real(R8P) ::]))
! format checks
test_passed(14) = len(readout_check('%9.2e')) == 0 .and. len(readout_check('%5.2f h')) == 0
test_passed(15) = index(readout_check('%.2e'), 'field width') > 0
test_passed(16) = index(readout_check('%8.2h'), '%h') > 0
test_passed(17) = index(readout_check('%1.1f'), 'no digit') > 0
test_passed(18) = len(readout_check('no conversion')) > 0
write(output_unit, '(A,18L2)') 'foresight readout checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1

contains
   function glass(format, value) result(text)
   !< Glass of `format` lit by `value`, as text; sets `prefix` and `suffix`.
   character(len=*), intent(in)  :: format   !< Readout format.
   real(R8P),        intent(in)  :: value    !< Value.
   character(len=:), allocatable :: text     !< Cells as text.
   integer(I4P), allocatable     :: masks(:) !< Cells.
   integer(I4P)                  :: k        !< Cell counter.

   call readout_glass(format, value, masks, prefix, suffix)
   text = ''
   do k = 1_I4P, size(masks, kind=I4P)
      text = text//cell_char(ibclr(masks(k), SEGMENT_DP))
      if (btest(masks(k), SEGMENT_DP)) text = text//'.'
   enddo
   endfunction glass

   function cell_char(mask) result(c)
   !< Character of the segments `mask`, `?` if none matches.
   integer(I4P),     intent(in) :: mask !< Segments, without the point.
   character(len=1)             :: c    !< Character.
   integer(I4P),     parameter  :: MASKS(13) = [63, 6, 91, 79, 102, 109, 125, 7, 127, 111, 64, 121, 0] !< 0-9 - E blank.
   character(len=*), parameter  :: CHARS = '0123456789-E ' !< Characters of MASKS.
   integer(I4P)                 :: k    !< Counter.

   c = '?'
   do k = 1_I4P, size(MASKS, kind=I4P)
      if (MASKS(k) == mask) c = CHARS(k:k)
   enddo
   endfunction cell_char
endprogram foresight_readout_test
