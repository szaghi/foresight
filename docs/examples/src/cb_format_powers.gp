set terminal svg size 560,320; set output 'cb_format_powers.svg'
# powers of ten as superscripts on a log axis, SI prefixes on a linear one (gnuplot's %T and %s %c)
set logscale y; set format y "10^{%T}"
set format x "%.1s %cHz"; set xlabel 'frequency'; set ylabel 'gain'
set xrange [0:2e6]; set yrange [1e-2:1e4]
plot 1e4 / (1 + (x/2e5)**2) lw 2 t 'low pass, 200 kHz'
