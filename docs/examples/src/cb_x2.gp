set terminal svg size 560,320; set output 'cb_x2.svg'
set xrange [0:100]; set xtics nomirror; set xlabel 'frequency [Hz]'
set x2range [0:2]; set x2tics 0.25; set x2label 'Strouhal number fD/U (D = 0.1 m, U = 5 m/s)'
# the same peaks plotted against x2 (axes x2y1): f D / U = 0.02 f lands each on its impulse
plot 'spectrum.dat' w impulses lw 2 t 'lift spectrum', \
     ''             u ($1*0.02):2 axes x2y1 w p pt 7 ps 0.6 t 'against St (axes x2y1)'
