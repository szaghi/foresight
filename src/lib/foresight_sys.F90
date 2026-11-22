!< foresight_sys, minimal libc interop for the services standard Fortran lacks.
module foresight_sys
!< foresight_sys, minimal libc interop for the services standard Fortran lacks.
!<
!< Standard Fortran has neither a file rename nor a sub-second sleep. Both are needed by the live (watch) mode: the
!< output page is rewritten into a temporary file and atomically renamed over the published one (the browser must
!< never read a half-written page), and data files are polled at a fixed cadence. Nor can it read the output of a
!< shell command (gnuplot's `system("command")`): `command_output` reads it through a pipe.
!<
!< @note POSIX only for now: `rename` replaces an existing destination atomically on POSIX, whereas on Windows the C
!< runtime `rename` fails if the destination exists; `nanosleep` and `popen` are POSIX. The `timespec` layout assumes an LP64 ABI
!< (`time_t` and `long` both 64 bit), true on Linux and macOS x86_64/aarch64.
use, intrinsic :: iso_c_binding, only : c_associated, c_char, c_int, c_long, c_null_char, c_ptr, c_size_t
use penf, only : I4P, I8P

implicit none
private
public :: command_output
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

   function c_popen(command, mode) result(stream) bind(C, name='popen')
   !< C `FILE *popen(const char *command, const char *mode)`.
   import :: c_char, c_ptr
   character(kind=c_char), intent(in) :: command(*) !< Shell command, null-terminated.
   character(kind=c_char), intent(in) :: mode(*)    !< `r`, null-terminated.
   type(c_ptr)                        :: stream     !< Pipe, null on error.
   endfunction c_popen

   function c_fread(buffer, size, count, stream) result(items) bind(C, name='fread')
   !< C `size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream)`.
   import :: c_char, c_ptr, c_size_t
   character(kind=c_char), intent(out)       :: buffer(*) !< Bytes read.
   integer(c_size_t),      intent(in), value :: size      !< Item size.
   integer(c_size_t),      intent(in), value :: count     !< Items wanted.
   type(c_ptr),            intent(in), value :: stream    !< Stream.
   integer(c_size_t)                         :: items     !< Items read.
   endfunction c_fread

   function c_pclose(stream) result(status) bind(C, name='pclose')
   !< C `int pclose(FILE *stream)`.
   import :: c_int, c_ptr
   type(c_ptr), intent(in), value :: stream !< Pipe.
   integer(c_int)                 :: status !< Wait status of the command, -1 on error.
   endfunction c_pclose
endinterface

contains
   subroutine command_output(command, output, status)
   !< Run the shell `command` (`/bin/sh -c`) and read its standard output, as gnuplot's `system("command")`.
   !<
   !< `status` is the command's exit status (0 on success), -1 if it could not run.
   character(len=*),              intent(in)  :: command !< Shell command.
   character(len=:), allocatable, intent(out) :: output  !< Its standard output.
   integer(I4P),                  intent(out) :: status  !< Exit status, -1 if it did not run.
   integer(c_size_t), parameter               :: CHUNK = 4096_c_size_t !< Bytes read at once.
   character(kind=c_char)                     :: buffer(CHUNK) !< Bytes read.
   type(c_ptr)                                :: stream  !< Pipe.
   integer(c_size_t)                          :: n       !< Bytes read.
   integer(c_int)                             :: code    !< Wait status.
   integer(I4P)                               :: k       !< Byte counter.

   output = ''
   status = -1_I4P
   stream = c_popen(command//c_null_char, 'r'//c_null_char)
   if (.not. c_associated(stream)) return
   do
      n = c_fread(buffer, 1_c_size_t, CHUNK, stream)
      if (n <= 0_c_size_t) exit
      block
         character(len=int(n, I4P)) :: piece !< Bytes as text.

         do k = 1_I4P, int(n, I4P)
            piece(k:k) = buffer(k)
         enddo
         output = output//piece
      endblock
   enddo
   code = c_pclose(stream)
   if (code == -1_c_int) return
   ! the exit status of a normal exit (WEXITSTATUS), else (a signal) the wait status
   if (iand(code, 127_c_int) == 0_c_int) then
      status = int(iand(ishft(code, -8), 255_c_int), I4P)
   else
      status = int(code, I4P)
   endif
   endsubroutine command_output

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
