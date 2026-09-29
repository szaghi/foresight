!< foresight_ticks test: nice steps, autoscale extension, exact labels, log decades.
program foresight_ticks_test
!< foresight_ticks test: nice steps, autoscale extension, exact labels, log decades.
use, intrinsic :: iso_fortran_env, only : output_unit
use foresight_ticks, only : linear_ticks, log_ticks, nice_step, tick_object
use penf, only : I4P, I8P, R8P

implicit none
type(tick_object), allocatable :: ticks(:)        !< Ticks.
real(R8P)                      :: lo              !< Axis start.
real(R8P)                      :: hi              !< Axis end.
integer(I8P)                   :: m               !< Step mantissa.
integer(I4P)                   :: e               !< Step exponent.
logical                        :: test_passed(12) !< Per-check outcome.

! nice steps
call nice_step(0.4_R8P, m, e)
test_passed(1) = m == 5_I8P .and. e == -1_I4P
call nice_step(1000.0_R8P, m, e)
test_passed(2) = m == 1_I8P .and. e == 3_I4P

! autoscale extends [0.3:9.7] to [0:10], step 1 on 500 px
lo = 0.3_R8P
hi = 9.7_R8P
call linear_ticks(lo, hi, 500.0_R8P, .true., .true., ticks)
test_passed(3) = lo == 0.0_R8P .and. hi == 10.0_R8P .and. size(ticks) == 11
test_passed(4) = ticks(2)%label == '1' .and. ticks(11)%label == '10'

! labels are exact decimals, never 0.30000000000000004
lo = 0.0_R8P
hi = 0.3_R8P
call linear_ticks(lo, hi, 150.0_R8P, .false., .false., ticks)
test_passed(5) = size(ticks) == 4 .and. ticks(4)%label == '0.3'

! scientific labels for small magnitudes
lo = 0.0_R8P
hi = 2.0e-4_R8P
call linear_ticks(lo, hi, 200.0_R8P, .false., .false., ticks)
test_passed(6) = ticks(2)%label == '5x10' .and. ticks(2)%sup == '-5' .and. &
                 ticks(4)%label == '1.5x10' .and. ticks(4)%sup == '-4' .and. ticks(1)%label == '0'

! reversed fixed range keeps its ends
lo = 10.0_R8P
hi = 0.0_R8P
call linear_ticks(lo, hi, 500.0_R8P, .false., .false., ticks)
test_passed(7) = lo == 10.0_R8P .and. hi == 0.0_R8P .and. size(ticks) == 11

! log axis: autoscale to whole decades, majors 10^-5..10^1, minors in between
lo = 3.0e-5_R8P
hi = 2.0_R8P
call log_ticks(lo, hi, 400.0_R8P, .true., .true., ticks)
test_passed(8) = abs(lo - 1.0e-5_R8P) < 1.0e-20_R8P .and. hi == 10.0_R8P
test_passed(9) = count(ticks%major) == 7 .and. size(ticks) == 7 + 6 * 8
test_passed(10) = ticks(1)%label == '10' .and. ticks(1)%sup == '-5'

! log axis narrower than a decade: minors labelled in plain decimals
lo = 2.0_R8P
hi = 8.0_R8P
call log_ticks(lo, hi, 400.0_R8P, .false., .false., ticks)
test_passed(11) = count(ticks%major) == 7
test_passed(12) = ticks(1)%label == '2' .and. ticks(7)%label == '8'

write(output_unit, '(A,12L2)') 'foresight_ticks checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1
endprogram foresight_ticks_test
