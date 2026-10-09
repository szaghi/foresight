set terminal svg size 560,320; set output 'cb_rowstacked.svg'
set style fill solid 0.6 border -1
set style histogram rowstacked; set boxwidth 0.6
plot 'timings.dat' u 2:xtic(1) w histograms t 'mesh', '' u 3 w hist t 'fluxes', '' u 4 w hist t 'comm'
