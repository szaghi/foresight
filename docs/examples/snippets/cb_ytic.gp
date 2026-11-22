set terminal svg size 560,320; set output 'cb_ytic.svg'
# the stations named on the y axis (ytic), their wind speed on x
set title 'wind speed by station'; set xlabel 'speed [m/s]'; set key off
set xrange [0:2]; set yrange [-0.5:4.5]
plot 'stations.dat' u (0):0:3:(0) w vectors nohead lw 3, '' u 3:0:ytic(5) w p pt 7 ps 2
