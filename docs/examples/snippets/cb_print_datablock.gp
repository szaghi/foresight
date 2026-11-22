set terminal svg size 560,320; set output 'cb_print_datablock.svg'
# a convergence table computed in a loop, printed into a datablock, then plotted
set print $ERR
do for [n = 1:6] { h = 0.4 / 2**n; print h, h**2 * (1 + h) }
set print
set logscale xy; set format y '%.0e'; set key top left
set xlabel 'h'; set ylabel 'error'
plot $ERR u 1:2 w lp pt 7 t 'set print $ERR', x**2 dt 2 t 'h^2'
