set terminal svg size 760,320; set output 'cb_unique.svg'
set multiplot layout 1,2
set xlabel 'step'; set ylabel 'wall time [s]'; set key top left
# the mean of the steps of each block of 25 (repeated x merged): unique
plot 'steptimes.dat' u 1:2 w p pt 7 ps 0.4 t 'per step', \
     ''              u (floor(($1-1)/25)*25+13):2 smooth unique w lp lw 2 pt 7 t 'mean of 25 steps'
set ylabel 'elapsed [s]'
# the running total: cumulative
plot 'steptimes.dat' u 1:2 smooth cumulative lw 2 t 'elapsed time'
unset multiplot
