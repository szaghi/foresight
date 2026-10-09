set terminal svg size 560,320; set output 'cb_circles.svg'
set style fill solid 0.4
set xlabel 'cells [M]'; set ylabel 'speedup'; set xrange [0:20]; set yrange [0:11]
plot 'scaling.dat' u 2:3:4 w circles t 'memory [GB] as radius'
