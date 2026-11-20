set terminal svg size 560,320; set output 'cb_tics_rotate.svg'
set style fill solid 0.6
set boxwidth 0.6
set xtics rotate by 30 right out nomirror
set ytics out nomirror
set xrange [-0.6:4.6]; set yrange [0:*]
plot 'throughput.dat' u 1:3:xtic(2) w boxes t 'time [s]'
