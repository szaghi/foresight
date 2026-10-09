set terminal svg size 480,320; set output 'cb_radar.svg'
set style fill solid 0.3
plot 'radar.dat' u 2:xtic(1) w radar t 'gpu', '' u 3 w radar t 'cpu'
