set terminal svg size 560,320; set output 'cb_hist_titles.svg'
# group titles in a color, moved down half a line
set style data histograms; set style fill solid 0.7 border -1
set style histogram clustered gap 1 title tc rgb '#b3163f' offset 0,-0.5
set key top left; set ylabel 'wall time [s]'
plot newhistogram 'mesh', 'timings.dat' u 2:xtic(1) t 'mesh', \
     newhistogram 'fluxes', '' u 3:xtic(1) t 'fluxes'
