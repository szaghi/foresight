!< foresight_sys, minimal libc interop for the services standard Fortran lacks.
module foresight_sys
!< foresight_sys, minimal libc interop for the services standard Fortran lacks.
!<
!< Standard Fortran has neither a file rename nor a sub-second sleep. Both are needed by the live (watch) mode: the
!< output page is rewritten into a temporary file and atomically renamed over the published one (the browser must
!< never read a half-written page), and data files are polled at a fixed cadence.
!<
!< @note POSIX only for now: `rename` replaces an existing destination atomically on POSIX, whereas on Windows the C
!< runtime `rename` fails if the destination exists; `nanosleep` is POSIX. The `timespec` layout assumes an LP64 ABI
!< (`time_t` and `long` both 64 bit), true on Linux and macOS x86_64/aarch64.
use, intrinsic :: iso_c_binding, only : c_char, c_int, c_long, c_null_char
use penf, only : I4P, I8P

implicit none
private
public :: rename_file
public :: sleep_ms

type, bind(C) :: timespec
   !< POSIX `struct timespec`.
   integer(c_long) :: tv_sec  = 0_c_long !< Seconds.
   integer(c_long) :: tv_nsec = 0_c_long !< Nanoseconds, in [0, 999999999].
endtype timespec

interface
   function c_rename(old, new) result(ierr) bind(C, name='rename')
   !< C `int rename(const char *old, const char *new)`.
   import :: c_char, c_int
   character(kind=c_char), intent(in) :: old(*) !< Old path, null-terminated.
   character(kind=c_char), intent(in) :: new(*) !< New path, null-terminated.
   integer(c_int)                     :: ierr   !< 0 on success, -1 on error.
   endfunction c_rename

   function c_nanosleep(req, rem) result(ierr) bind(C, name='nanosleep')
   !< C `int nanosleep(const struct timespec *req, struct timespec *rem)`.
   import :: c_int, timespec
   type(timespec), intent(in)  :: req  !< Requested interval.
   type(timespec), intent(out) :: rem  !< Remaining interval if interrupted.
   integer(c_int)              :: ierr !< 0 on success, -1 on error or interruption.
   endfunction c_nanosleep
endinterface

contains
   subroutine rename_file(old, new, iostat)
   !< Rename (move) file `old` to `new`, replacing `new` if it exists.
   !<
   !< On POSIX the replacement is atomic: a concurrent reader sees either the old or the new `new`, never a partial file.
   !< Both paths must be on the same filesystem.
   character(len=*), intent(in)            :: old    !< Current path.
   character(len=*), intent(in)            :: new    !< Target path.
   integer(I4P),     intent(out), optional :: iostat !< 0 on success, non-zero on failure; if absent, failure stops.
   integer(c_int)                          :: ierr   !< C return code.

   ierr = c_rename(trim(old)//c_null_char, trim(new)//c_null_char)
   if (present(iostat)) then
      iostat = int(ierr, I4P)
   elseif (ierr /= 0_c_int) then
      error stop 'foresight_sys: rename_file failed: "'//trim(old)//'" -> "'//trim(new)//'"'
   endif
   endsubroutine rename_file

   subroutine sleep_ms(milliseconds)
   !< Suspend the calling thread for at least `milliseconds` ms.
   !<
   !< An interruption by a signal resumes the sleep for the remaining interval.
   integer(I8P), intent(in) :: milliseconds !< Interval to sleep [ms]; non-positive values return immediately.
   type(timespec)           :: req          !< Requested interval.
   type(timespec)           :: rem          !< Remaining interval after an interruption.

   if (milliseconds <= 0_I8P) return
   req%tv_sec  = int(milliseconds / 1000_I8P, c_long)
   req%tv_nsec = int(mod(milliseconds, 1000_I8P) * 1000000_I8P, c_long)
   do while (c_nanosleep(req, rem) /= 0_c_int)
      req = rem
   enddo
   endsubroutine sleep_ms
endmodule foresight_sys
