set terminal svg size 560,320; set output 'cb_hist_groups.svg'
# two groups of bars from two files, titled below the axis, the second from linetype 3
set style data histograms
set style fill solid 0.7 border -1; set style histogram clustered gap 1
set ylabel 'wall time per step [s]'
plot newhistogram 'mesh and fluxes', 'timings.dat' u 2:xtic(1) t 'mesh', '' u 3 t 'fluxes', \
     newhistogram 'comm' lt 3, '' u 4:xtic(1) t 'comm'
