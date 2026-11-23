set terminal svg size 560,320; set output 'cb_autoscale_limits.svg'
# limits of the autoscaled ends: y at least from -1 to 1, x within [0:12] whatever the data
$D << EOD
-2 0.2
3 0.5
8 0.4
15 0.6
EOD
set yrange [*<-1:1<*]
set xrange [0<*:*<12]
plot $D with linespoints pt 7 lw 2 title '[0<*:*<12] x [*<-1:1<*]'
