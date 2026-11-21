set terminal svg size 560,320; set output 'cb_hist_errorbars.svg'
# the mean and the spread of each phase: errorbars histograms, using Y:ERR
set style data histograms
set style fill solid 0.6 border -1; set style histogram errorbars gap 1 lw 2
set yrange [0:*]; set ylabel 'wall time per step [s]'
plot 'timings.dat' u 2:($2*0.1):xtic(1) t 'mesh', '' u 3:($3*0.15) t 'fluxes', '' u 4:($4*0.3) t 'comm'
