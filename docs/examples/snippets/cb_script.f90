program cb_script
!< Cookbook: gnuplot commands from Fortran, through the interpreter the command line uses.
use foresight, only : script_object, I4P
implicit none
type(script_object)           :: gp
character(len=:), allocatable :: iomsg
integer(I4P)                  :: iostat

call gp%init('cb_script.svg')
call gp%run_text("set terminal svg size 560,320"//new_line('a')// &
                 "set logscale y; plot 'run.dat' u 1:2 t 'continuity', '' u 1:3 t 'momentum'", iostat, iomsg)
if (iostat /= 0) print '(A)', iomsg
call gp%execute('set key bottom left', iostat, iomsg)
call gp%execute('replot', iostat, iomsg)            ! re-reads run.dat and renders again
endprogram cb_script
