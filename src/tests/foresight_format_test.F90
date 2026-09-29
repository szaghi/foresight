!< foresight_format test: exact decimal strings and XML escaping.
program foresight_format_test
!< foresight_format test: exact decimal strings and XML escaping.
use, intrinsic :: iso_fortran_env, only : output_unit
use foresight_format, only : decimal_str, fixed, int_str, xml_escape
use penf, only : I4P, I8P, R8P

implicit none
logical :: test_passed(10) !< Per-check outcome.

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

write(output_unit, '(A,10L2)') 'foresight_format checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1
endprogram foresight_format_test
