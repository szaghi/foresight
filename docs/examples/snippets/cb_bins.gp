set terminal svg size 560,320; set output 'cb_bins.svg'
set style fill solid 0.4 border
set xlabel 'wall time per step [s]'; set ylabel 'steps'
# one column: x, each step counting 1; kdensity weighted by the bin width, on the same scale
plot 'steptimes.dat' u 2 bins binwidth=0.02 with boxes t 'bins, 0.02 s wide', \
     ''              u 2:(0.02) smooth kdensity lw 2 t 'kdensity'
