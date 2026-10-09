set terminal svg size 560,320; set output 'cb_patterns.svg'
set style fill pattern 4 border; set key top left
plot 'timings.dat' u 2:xtic(1) w hist t 'mesh', '' u 3 w hist t 'fluxes', '' u 4 w hist t 'comm'
