!< foresight_format test: exact decimal strings, XML escaping, tick formats (checked against C printf).
program foresight_format_test
!< foresight_format test: exact decimal strings, XML escaping, tick formats (checked against C printf).
use, intrinsic :: iso_fortran_env, only : output_unit
use foresight_format, only : decimal_of, decimal_str, fixed, format_check, format_decimal, int_str, parse_decimal, &
                             real_str, xml_escape
use penf, only : I4P, I8P, R8P

implicit none
logical                       :: test_passed(27) !< Per-check outcome.
character(len=:), allocatable :: label           !< Formatted label.
character(len=:), allocatable :: sup             !< Formatted superscript.
integer(I8P)                  :: n               !< Decimal mantissa.
integer(I4P)                  :: e               !< Decimal exponent.
logical                       :: ok              !< Parsed.

test_passed( 1) = int_str(-42_I8P) == '-42'
test_passed( 2) = decimal_str(15_I8P, 1_I4P) == '1.5'
test_passed( 3) = decimal_str(-5_I8P, 3_I4P) == '-0.005'
test_passed( 4) = decimal_str(15_I8P, -2_I4P) == '1500'
test_passed( 5) = decimal_str(100_I8P, 2_I4P) == '1'
test_passed( 6) = fixed(0.5_R8P, 2_I4P) == '0.5'
test_passed( 7) = fixed(-0.001_R8P, 2_I4P) == '0'
test_passed( 8) = fixed(123.456789_R8P, 6_I4P) == '123.456789'
test_passed( 9) = fixed(1.0e30_R8P, 2_I4P) == '100000000000'
test_passed(10) = xml_escape('a<b & "c">') == 'a&lt;b &amp; &quot;c&quot;&gt;'
test_passed(11) = real_str(1.0_R8P) == '1e0'
test_passed(12) = real_str(-1.23e-4_R8P) == '-1.23e-4'
test_passed(13) = real_str(6.02214076e23_R8P) == '6.02214076e23'

! exact decimals
call parse_decimal('-0.2500', n, e, ok)
test_passed(14) = ok .and. n == -25_I8P .and. e == -2_I4P
call parse_decimal('1.5e3', n, e, ok)
test_passed(15) = ok .and. n == 15_I8P .and. e == 2_I4P
call parse_decimal('1.2.3', n, e, ok)
test_passed(16) = .not. ok
call decimal_of(0.1_R8P, n, e)
test_passed(17) = n == 1_I8P .and. e == -1_I4P

! tick formats, as C printf on the exact value: rounding half to even, carries, flags, width, %%
test_passed(18) = label_of('%.2f', 125_I8P, -3_I4P) == '0.12'
test_passed(19) = label_of('%.0f', 25_I8P, -1_I4P) == '2' .and. label_of('%.0f', 35_I8P, -1_I4P) == '4'
test_passed(20) = label_of('%.1e', 99999_I8P, -4_I4P) == '1.0e+01'
test_passed(21) = label_of('%g', 1_I8P, 6_I4P) == '1e+06' .and. label_of('%g', 12345_I8P, -2_I4P) == '123.45'
test_passed(22) = label_of('%+08.3f', -15_I8P, -1_I4P) == '-001.500'
test_passed(23) = label_of('t=%.1fs %%', 3_I8P, 0_I4P) == 't=3.0s %'
call format_decimal('%h', 15_I8P, 5_I4P, label, sup)
test_passed(24) = label == '1.5x10' .and. sup == '6'
test_passed(25) = label_of('%-6.1f|', 5_I8P, -1_I4P) == '0.5   |'
test_passed(26) = len(format_check('%.3g')) == 0 .and. index(format_check('%d'), 'unsupported conversion') > 0
test_passed(27) = index(format_check('%f %f'), 'more than one') > 0 .and. index(format_check('abc'), 'no conversion') > 0

write(output_unit, '(A,27L2)') 'foresight_format checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1

contains
   function label_of(format, n, e) result(label)
   !< Label of `n * 10**e` by `format`.
   character(len=*), intent(in)  :: format !< Format.
   integer(I8P),     intent(in)  :: n      !< Mantissa.
   integer(I4P),     intent(in)  :: e      !< Exponent.
   character(len=:), allocatable :: label  !< Label.
   character(len=:), allocatable :: sup    !< Superscript.

   call format_decimal(format, n, e, label, sup)
   endfunction label_of
endprogram foresight_format_test
