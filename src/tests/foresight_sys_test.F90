!< foresight_sys test: atomic rename over an existing file, and sleep duration.
program foresight_sys_test
!< foresight_sys test: atomic rename over an existing file, and sleep duration.
use, intrinsic :: iso_fortran_env, only : error_unit, output_unit
use foresight, only : I4P, I8P, R8P, rename_file, sleep_ms

implicit none
character(len=*), parameter :: old = 'foresight_sys_test.tmp'     !< Source of the rename.
character(len=*), parameter :: new = 'foresight_sys_test.out.tmp' !< Pre-existing target of the rename.
character(len=16)           :: line                               !< Line read back from the target.
logical                     :: test_passed(4)                     !< Per-check outcome.
logical                     :: exists                             !< File existence flag.
integer(I4P)                :: unit                               !< Scratch unit.
integer(I4P)                :: iostat                             !< I/O status.
integer(I8P)                :: count_rate                         !< Clock ticks per second.
integer(I8P)                :: t0                                 !< Clock at sleep start.
integer(I8P)                :: t1                                 !< Clock at sleep end.
real(R8P)                   :: elapsed_ms                         !< Measured sleep [ms].

test_passed = .false.

! rename must replace an existing target
open(newunit=unit, file=new, action='write', status='replace')
write(unit, '(A)') 'old'
close(unit)
open(newunit=unit, file=old, action='write', status='replace')
write(unit, '(A)') 'new'
close(unit)
call rename_file(old=old, new=new, iostat=iostat)
test_passed(1) = iostat == 0_I4P
inquire(file=old, exist=exists)
test_passed(2) = .not. exists
open(newunit=unit, file=new, action='read', status='old')
read(unit, '(A)') line
close(unit, status='delete')
test_passed(3) = trim(line) == 'new'

! sleep must last at least the requested interval
call system_clock(t0, count_rate)
call sleep_ms(50_I8P)
call system_clock(t1)
elapsed_ms = real(t1 - t0, R8P) * 1000.0_R8P / real(count_rate, R8P)
test_passed(4) = elapsed_ms >= 50.0_R8P

write(output_unit, '(A,4L2)') 'foresight_sys checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) then
   write(error_unit, '(A,F0.3,A)') 'measured sleep: ', elapsed_ms, ' ms'
   error stop 1
endif
endprogram foresight_sys_test
