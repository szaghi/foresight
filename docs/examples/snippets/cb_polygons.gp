set terminal svg size 560,320; set output 'cb_polygons.svg'
set style fill solid 0.3 border; set size ratio 0.7
plot 'cells.dat' w polygons t 'cells'
