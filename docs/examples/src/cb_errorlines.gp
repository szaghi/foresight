set terminal svg size 560,320; set output 'cb_errorlines.svg'
set logscale x; set xlabel 'Re'; set ylabel 'cd'
plot 'measures.dat' u 1:2:4 w yerrorlines pt 7 t 'yerrorlines', \
     ''             u 1:($2+0.1):3:4 w xyerrorlines pt 5 t 'xyerrorlines'
