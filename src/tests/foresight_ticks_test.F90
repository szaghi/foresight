!< foresight_ticks test: nice steps, autoscale extension, exact labels, log decades, user tick settings.
program foresight_ticks_test
!< foresight_ticks test: nice steps, autoscale extension, exact labels, log decades, user tick settings.
!<
!< The fixed-step ranges and ticks are those gnuplot 6.0 produces for the same data (0.07..2.93, 3..170).
use, intrinsic :: iso_fortran_env, only : output_unit
use foresight_ticks, only : linear_ticks, log_ticks, nice_step, tick_object, tics_object, TICS_NONE
use penf, only : I4P, I8P, R8P

implicit none
type(tick_object), allocatable :: ticks(:)        !< Ticks.
real(R8P)                      :: lo              !< Axis start.
real(R8P)                      :: hi              !< Axis end.
integer(I8P)                   :: m               !< Step mantissa.
integer(I4P)                   :: e               !< Step exponent.
type(tics_object)              :: tics            !< User tick settings.
character(len=:), allocatable  :: message         !< Settings problem.
logical                        :: test_passed(22) !< Per-check outcome.

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

! log axis inside one decade, no multiple of the decade in range: linear ticks instead
lo = 2.1_R8P
hi = 2.3_R8P
call log_ticks(lo, hi, 150.0_R8P, .false., .false., ticks)
test_passed(13) = size(ticks) == 5 .and. ticks(1)%label == '2.1' .and. ticks(5)%label == '2.3'

! set xtics 0.4: autoscaled ends extended to multiples of the step
call tics%set_fixed('0.4', '', '', message)
call fixed_linear(tics)
test_passed(14) = lo == 0.0_R8P .and. abs(hi - 3.2_R8P) < 1.0e-12_R8P .and. size(ticks) == 9 .and. &
                  ticks(2)%label == '0.4' .and. ticks(9)%label == '3.2'

! set xtics 0.5,0.4: no extension below the start
call tics%set_fixed('0.4', '0.5', '', message)
call fixed_linear(tics)
test_passed(15) = lo == 0.07_R8P .and. abs(hi - 3.2_R8P) < 1.0e-12_R8P .and. size(ticks) == 7 .and. &
                  ticks(1)%label == '0.5' .and. ticks(7)%label == '2.9'

! set xtics 0.5,0.4,2: no extension beyond the end either
call tics%set_fixed('0.4', '0.5', '2', message)
call fixed_linear(tics)
test_passed(16) = lo == 0.07_R8P .and. hi == 2.93_R8P .and. size(ticks) == 4 .and. ticks(4)%label == '1.7'

! unset xtics: no ticks, no extension
tics = tics_object(mode=TICS_NONE)
call fixed_linear(tics)
test_passed(17) = lo == 0.07_R8P .and. hi == 2.93_R8P .and. size(ticks) == 0

! a label format on fixed ticks
call tics%set_fixed('0.25', '', '', message)
tics%format = '%.2f'
call fixed_linear(tics)
test_passed(18) = ticks(1)%label == '0.00' .and. ticks(2)%label == '0.25' .and. ticks(13)%label == '3.00'

! log axis, set ytics 3: decades extension as always, ticks at powers of 3
tics = tics_object()
call tics%set_fixed('3', '', '', message)
lo = 3.0_R8P
hi = 170.0_R8P
call log_ticks(lo, hi, 400.0_R8P, .true., .true., ticks, tics)
test_passed(19) = lo == 1.0_R8P .and. hi == 1000.0_R8P .and. size(ticks) == 7 .and. ticks(1)%label == '1' .and. &
                  ticks(7)%label == '729'

! log axis, set ytics 2,10
call tics%set_fixed('10', '2', '', message)
lo = 3.0_R8P
hi = 170.0_R8P
call log_ticks(lo, hi, 400.0_R8P, .true., .true., ticks, tics)
test_passed(20) = size(ticks) == 3 .and. ticks(1)%label == '2' .and. ticks(3)%label == '200'

! invalid settings are refused and leave the settings unchanged
call tics%set_fixed('-1', '', '', message)
test_passed(21) = index(message, 'positive') > 0 .and. tics%step == '10'
call tics%set_fixed('1e-10', '1e10', '', message)
test_passed(22) = index(message, 'differ too much') > 0

write(output_unit, '(A,22L2)') 'foresight_ticks checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1

contains
   subroutine fixed_linear(tics)
   !< Autoscaled linear ticks of the data range 0.07..2.93 on 500 px with `tics`.
   type(tics_object), intent(in) :: tics !< User tick settings.

   lo = 0.07_R8P
   hi = 2.93_R8P
   call linear_ticks(lo, hi, 500.0_R8P, .true., .true., ticks, tics)
   endsubroutine fixed_linear
endprogram foresight_ticks_test
