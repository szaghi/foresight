set terminal svg size 560,320; set output 'cb_table.svg'
# a smoothed curve tabulated into a datablock, then plotted with the samples (a marker every 10 points)
set table $SMOOTH
plot 'noisy.dat' u 1:2 smooth csplines
unset table
set title sprintf('the spline, %d tabulated lines', |$SMOOTH|); set key bottom left
plot 'noisy.dat' u 1:2 w p pt 7 t 'samples', $SMOOTH u 1:2 w lp pi 10 pt 6 lw 2 t 'set table $SMOOTH, pi 10'
