set terminal svg size 560,320; set output 'cb_key_layout.svg'
# a key in its own layout: samples left of the titles, left-justified, last run first, painted over the curves
set key top right box opaque reverse Left invert samplen 2 width 1 title "runs" offset 0,-0.5
set xrange [0:10]; set yrange [0:1.1]; set xlabel 't [s]'
plot for [k = 1:4] 1 - exp(-k*x/4) lw 2 t sprintf('run %d, tau = %.1f s', k, 4./k)
