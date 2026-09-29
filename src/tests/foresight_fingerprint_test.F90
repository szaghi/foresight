!< foresight_fingerprint test: the changes the watch mode must see, and the documented blind spot.
program foresight_fingerprint_test
!< foresight_fingerprint test: the changes the watch mode must see, and the documented blind spot.
use, intrinsic :: iso_fortran_env, only : output_unit
use foresight, only : file_fingerprint, I4P, I8P

implicit none
character(len=*), parameter :: file = 'foresight_fingerprint_test.tmp' !< Scratch file.
integer(I8P)                :: before(2)                           !< Fingerprint before a change.
integer(I8P)                :: after(2)                            !< Fingerprint after a change.
integer(I4P)                :: unit                                !< File unit.
logical                     :: test_passed(8)                      !< Per-check outcome.

! missing file
test_passed(1) = all(file_fingerprint('foresight_no_such_file.tmp') == [-1_I8P, 0_I8P])

! a script edit keeping the length is seen; the same content is not a change
call write_text('plot "run.dat" u 1:2 w l lw 2')
before = file_fingerprint(file)
call write_text('plot "run.dat" u 1:2 w l lw 3')
after = file_fingerprint(file)
test_passed(2) = before(1) == after(1) .and. before(2) /= after(2)
call write_text('plot "run.dat" u 1:2 w l lw 3')
test_passed(3) = all(after == file_fingerprint(file))

! an append is seen
open(newunit=unit, file=file, access='stream', form='unformatted', position='append', action='write')
write(unit) '1 2'//new_line('a')
close(unit)
test_passed(4) = any(after /= file_fingerprint(file))

! a file beyond the fully hashed size (1 MiB): its first and last bytes are watched, its middle is not
call write_bytes(1200000_I8P)
before = file_fingerprint(file)
call patch_byte(1_I8P)
test_passed(5) = any(before /= file_fingerprint(file))
before = file_fingerprint(file)
call patch_byte(1200000_I8P)
test_passed(6) = any(before /= file_fingerprint(file))
before = file_fingerprint(file)
call patch_byte(600000_I8P)
test_passed(7) = all(before == file_fingerprint(file))
test_passed(8) = before(1) == 1200000_I8P

open(newunit=unit, file=file)
close(unit, status='delete')
write(output_unit, '(A,8L2)') 'foresight_fingerprint checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1

contains
   subroutine write_text(text)
   !< Replace the file with `text`, without a newline.
   character(len=*), intent(in) :: text !< Content.

   open(newunit=unit, file=file, access='stream', form='unformatted', status='replace', action='write')
   write(unit) text
   close(unit)
   endsubroutine write_text

   subroutine write_bytes(n)
   !< Replace the file with `n` bytes (a multiple of 1000) of a repeating pattern.
   integer(I8P), intent(in) :: n       !< Size.
   character(len=1000)      :: pattern !< Written block.
   integer(I8P)             :: k       !< Counter.

   do k = 1_I8P, int(len(pattern), I8P)
      pattern(k:k) = achar(48 + mod(k, 10_I8P))
   enddo
   open(newunit=unit, file=file, access='stream', form='unformatted', status='replace', action='write')
   do k = 1_I8P, n / len(pattern)
      write(unit) pattern
   enddo
   close(unit)
   endsubroutine write_bytes

   subroutine patch_byte(position)
   !< Overwrite the byte at `position` with `#`, keeping the size.
   integer(I8P), intent(in) :: position !< Byte position.

   open(newunit=unit, file=file, access='stream', form='unformatted', status='old', action='readwrite')
   write(unit, pos=position) '#'
   close(unit)
   endsubroutine patch_byte
endprogram foresight_fingerprint_test
