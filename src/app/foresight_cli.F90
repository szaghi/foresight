!< foresight command line tool: gnuplot-like scripts rendered to SVG/HTML.
program foresight_cli
!< foresight command line tool: gnuplot-like scripts rendered to SVG/HTML.
!<
!< `foresight [-e COMMANDS] [-o OUTPUT] [-w [SECONDS]] [SCRIPT]` runs `COMMANDS` then `SCRIPT`. With `--watch` the run
!< is repeated whenever the script or a data file it plotted changes size (append-only logs of a running job), the
!< HTML output reloading itself in the browser; errors in a cycle are reported and watching goes on.
use, intrinsic :: iso_fortran_env, only : error_unit, output_unit
use foresight, only : I4P, I8P, R8P, script_object, sleep_ms

implicit none
character(len=:), allocatable :: script      !< Script file, empty for none.
character(len=:), allocatable :: commands    !< Commands of `-e`, run first.
character(len=:), allocatable :: output      !< Default output.
integer(I8P),     allocatable :: sizes(:)    !< Watched file sizes.
type(script_object)           :: interpreter !< Interpreter.
real(R8P)                     :: period      !< Watch period [s], 0 for no watch.
integer(I4P)                  :: max_cycles  !< Watch polls before stopping, negative for forever.
integer(I4P)                  :: cycle_count !< Watch polls done.
integer(I4P)                  :: status      !< Run status.

call parse_arguments
status = run()
if (period <= 0.0_R8P) then
   if (status /= 0_I4P) stop 1, quiet=.true.
   stop
endif
sizes = watched_sizes()
write(output_unit, '(A)') 'foresight: watching, Ctrl-C to stop'
cycle_count = 0_I4P
do while (max_cycles < 0_I4P .or. cycle_count < max_cycles)
   call sleep_ms(int(period * 1000.0_R8P, I8P))
   cycle_count = cycle_count + 1_I4P
   if (all_equal(sizes, watched_sizes())) cycle
   status = run()
   sizes = watched_sizes()
enddo

contains
   subroutine parse_arguments
   !< Parse the command line.
   character(len=:), allocatable :: arg   !< Current argument.
   character(len=:), allocatable :: value !< Option value.
   integer(I4P)                  :: a     !< Argument counter.
   integer(I4P)                  :: n     !< Number of arguments.
   integer(I4P)                  :: ios   !< Conversion status.

   script = ''
   commands = ''
   output = ''
   period = 0.0_R8P
   max_cycles = -1_I4P
   n = command_argument_count()
   a = 1_I4P
   do while (a <= n)
      arg = argument(a)
      select case (arg)
      case ('-h', '--help')
         call print_usage
         stop
      case ('-e', '--execute')
         value = option_value(a)
         commands = commands//value//new_line('a')
      case ('-o', '--output')
         output = option_value(a)
      case ('-w', '--watch')
         period = 1.0_R8P
         if (a < n) then
            value = argument(a + 1_I4P)
            read(value, *, iostat=ios) period
            if (ios == 0_I4P .and. verify(value, '0123456789.') == 0) then
               a = a + 1_I4P
            else
               period = 1.0_R8P
            endif
         endif
         if (period <= 0.0_R8P) call usage_error('--watch needs a positive period')
      case ('--max-cycles')
         value = option_value(a)
         read(value, *, iostat=ios) max_cycles
         if (ios /= 0_I4P) call usage_error('--max-cycles needs an integer')
      case default
         if (arg(1:1) == '-') call usage_error('unknown option "'//arg//'"')
         if (len(script) > 0) call usage_error('only one script can be given')
         script = arg
      endselect
      a = a + 1_I4P
   enddo
   if (len(script) == 0 .and. len(commands) == 0) then
      call print_usage
      stop 1, quiet=.true.
   endif
   if (len(output) == 0) then
      output = 'foresight.html'
      if (len(script) > 0) output = base_name(script)//'.html'
   endif
   endsubroutine parse_arguments

   function run() result(status)
   !< Run commands and script from a fresh interpreter; report errors.
   integer(I4P)                  :: status !< 0 on success.
   character(len=:), allocatable :: iomsg  !< Error message.

   call interpreter%init(output)
   if (period > 0.0_R8P) interpreter%live_refresh = max(1_I4P, nint(period, I4P))
   status = 0_I4P
   if (len(commands) > 0) call interpreter%run_text(commands, status, iomsg, source='-e')
   if (status == 0_I4P .and. len(script) > 0) call interpreter%run_file(script, status, iomsg)
   if (status /= 0_I4P) then
      write(error_unit, '(A)') 'foresight: '//iomsg
   elseif (interpreter%output /= '-') then
      ! a plot on standard output (dumb terminal) is the whole output
      write(output_unit, '(A)') 'foresight: '//interpreter%output
   endif
   endfunction run

   function watched_sizes() result(bytes)
   !< Sizes of the script and of the data files read in the last run; -1 for a missing file.
   integer(I8P), allocatable :: bytes(:) !< File sizes.
   integer(I4P)              :: f        !< Counter.

   allocate(bytes(size(interpreter%data_files) + 1))
   bytes(1) = file_size(script)
   do f = 1_I4P, size(interpreter%data_files, kind=I4P)
      bytes(f + 1_I4P) = file_size(interpreter%data_files(f)%text)
   enddo
   endfunction watched_sizes

   function file_size(file) result(bytes)
   !< Size of `file` [bytes], -1 if missing or unnamed.
   character(len=*), intent(in) :: file   !< File name.
   integer(I8P)                 :: bytes  !< Size.
   logical                      :: exists !< File exists.

   bytes = -1_I8P
   if (len(file) == 0) return
   inquire(file=file, exist=exists)
   if (exists) inquire(file=file, size=bytes)
   endfunction file_size

   pure function all_equal(a, b) result(equal)
   !< Whether two size lists are identical.
   integer(I8P), intent(in) :: a(:)  !< First list.
   integer(I8P), intent(in) :: b(:)  !< Second list.
   logical                  :: equal !< Identical.

   equal = size(a) == size(b)
   if (equal) equal = all(a == b)
   endfunction all_equal

   function argument(a) result(arg)
   !< Command line argument `a`.
   integer(I4P), intent(in)      :: a      !< Argument index.
   character(len=:), allocatable :: arg    !< Argument.
   integer(I4P)                  :: length !< Argument length.

   call get_command_argument(a, length=length)
   allocate(character(len=length) :: arg)
   call get_command_argument(a, arg)
   endfunction argument

   function option_value(a) result(value)
   !< Value of the option at `a`, advancing past it.
   integer(I4P), intent(inout)   :: a     !< Option index.
   character(len=:), allocatable :: value !< Option value.

   if (a >= command_argument_count()) call usage_error('"'//argument(a)//'" needs a value')
   a = a + 1_I4P
   value = argument(a)
   endfunction option_value

   pure function base_name(file) result(base)
   !< `file` without directory and extension.
   character(len=*), intent(in)  :: file  !< File name.
   character(len=:), allocatable :: base  !< Base name.
   integer(I4P)                  :: slash !< Last slash.
   integer(I4P)                  :: dot   !< Last dot.

   slash = index(file, '/', back=.true., kind=I4P)
   base = file(slash + 1_I4P:)
   dot = index(base, '.', back=.true., kind=I4P)
   if (dot > 1_I4P) base = base(1:dot - 1_I4P)
   endfunction base_name

   subroutine print_usage
   !< Print the command line usage.
   write(output_unit, '(A)') 'usage: foresight [options] [SCRIPT]'
   write(output_unit, '(A)') ''
   write(output_unit, '(A)') 'Render a gnuplot-like SCRIPT to an interactive HTML page (default SCRIPT.html) or SVG.'
   write(output_unit, '(A)') ''
   write(output_unit, '(A)') 'options:'
   write(output_unit, '(A)') '  -e, --execute COMMANDS  run COMMANDS before SCRIPT (repeatable)'
   write(output_unit, '(A)') '  -o, --output FILE       default output file (.html or .svg)'
   write(output_unit, '(A)') '  -w, --watch [SECONDS]   re-run when SCRIPT or its data files change (default 1 s)'
   write(output_unit, '(A)') '      --max-cycles N      stop watching after N polls'
   write(output_unit, '(A)') '  -h, --help              show this help'
   endsubroutine print_usage

   subroutine usage_error(message)
   !< Report a command line error and stop.
   character(len=*), intent(in) :: message !< Error message.

   write(error_unit, '(A)') 'foresight: '//message//' (see --help)'
   stop 2, quiet=.true.
   endsubroutine usage_error
endprogram foresight_cli
