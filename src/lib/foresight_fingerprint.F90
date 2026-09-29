!< foresight_fingerprint, cheap change detection of files, for the watch mode.
module foresight_fingerprint
!< foresight_fingerprint, cheap change detection of files, for the watch mode.
!<
!< A fingerprint is the file size and a 32-bit FNV-1a hash of its content: of the whole file up to `FULL_LIMIT`
!< bytes, of its first and last `EDGE` bytes beyond. Standard Fortran has no modification time, and the POSIX one
!< needs the platform layout of `struct stat` and has a coarse resolution on some filesystems (network, WSL); the
!< content is portable and exact. It catches appends (size), rewrites of the same size (a restarted job, an edit of
!< `lw 2` into `lw 3` in a script) and, beyond `FULL_LIMIT`, any change of the first or last `EDGE` bytes: only a
!< same-size change in the middle of a large file goes unnoticed, which append-only logs never do.
use penf, only : I4P, I8P

implicit none
private
public :: file_fingerprint

integer(I8P), parameter :: FULL_LIMIT = 1048576_I8P    !< Files up to this size [bytes] are hashed whole.
integer(I8P), parameter :: EDGE       = 65536_I8P      !< Bytes hashed at each end of larger files.
integer(I8P), parameter :: FNV_OFFSET = 2166136261_I8P !< FNV-1a 32-bit offset basis.
integer(I8P), parameter :: FNV_PRIME  = 16777619_I8P   !< FNV-1a 32-bit prime.
integer(I8P), parameter :: MODULUS    = 4294967296_I8P !< 2**32: the hash stays below, so products fit I8P.

contains
   function file_fingerprint(file) result(fingerprint)
   !< Size and content hash of `file`; `[-1, 0]` if it is missing or unnamed.
   character(len=*), intent(in) :: file           !< File name.
   integer(I8P)                 :: fingerprint(2) !< Size [bytes] and hash.
   integer(I4P)                 :: unit           !< File unit.
   integer(I4P)                 :: iostat         !< I/O status.
   logical                      :: exists         !< File exists.

   fingerprint = [-1_I8P, 0_I8P]
   if (len(file) == 0) return
   inquire(file=file, exist=exists)
   if (.not. exists) return
   inquire(file=file, size=fingerprint(1))
   fingerprint(2) = FNV_OFFSET
   open(newunit=unit, file=file, access='stream', form='unformatted', action='read', status='old', iostat=iostat)
   if (iostat /= 0_I4P) return
   if (fingerprint(1) <= FULL_LIMIT) then
      call hash_bytes(1_I8P, fingerprint(1), fingerprint(2))
   else
      call hash_bytes(1_I8P, EDGE, fingerprint(2))
      call hash_bytes(fingerprint(1) - EDGE + 1_I8P, EDGE, fingerprint(2))
   endif
   close(unit)
   contains
      subroutine hash_bytes(first, count, hash)
      !< Fold `count` bytes from position `first` into `hash`; a file shrunk meanwhile just ends the fold.
      integer(I8P), intent(in)    :: first  !< First byte position.
      integer(I8P), intent(in)    :: count  !< Bytes to fold.
      integer(I8P), intent(inout) :: hash   !< Hash.
      character(len=4096)         :: buffer !< Read buffer.
      integer(I8P)                :: done   !< Bytes folded.
      integer(I8P)                :: n      !< Bytes of the current chunk.
      integer(I8P)                :: b      !< Byte counter.

      done = 0_I8P
      do while (done < count)
         n = min(int(len(buffer), I8P), count - done)
         read(unit, pos=first + done, iostat=iostat) buffer(1:n)
         if (iostat /= 0_I4P) return
         do b = 1_I8P, n
            hash = mod(ieor(hash, int(ichar(buffer(b:b)), I8P)) * FNV_PRIME, MODULUS)
         enddo
         done = done + n
      enddo
      endsubroutine hash_bytes
   endfunction file_fingerprint
endmodule foresight_fingerprint
