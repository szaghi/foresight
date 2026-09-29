!< foresight command line tool: gnuplot-like scripts rendered to SVG/HTML.
program foresight_cli
!< foresight command line tool: gnuplot-like scripts rendered to SVG/HTML.
!<
!< Milestone 0 stub: the gnuplot-subset interpreter lands in milestone 3.
use, intrinsic :: iso_fortran_env, only : error_unit, output_unit
use foresight, only : I4P

implicit none
character(len=:), allocatable :: arg    !< Command line argument.
integer(I4P)                  :: length !< Argument length.

if (command_argument_count() == 0_I4P) then
   call print_usage
   stop
endif
call get_command_argument(1, length=length)
allocate(character(len=length) :: arg)
call get_command_argument(1, arg)
select case (arg)
case ('-h', '--help')
   call print_usage
case default
   write(error_unit, '(A)') 'foresight: script interpretation not implemented yet (milestone 3)'
   error stop 1
endselect

contains
   subroutine print_usage
   !< Print the command line usage.
   write(output_unit, '(A)') 'usage: foresight [-h|--help] SCRIPT'
   write(output_unit, '(A)') '  Render a gnuplot-like SCRIPT to SVG/HTML (not implemented yet).'
   endsubroutine print_usage
endprogram foresight_cli
