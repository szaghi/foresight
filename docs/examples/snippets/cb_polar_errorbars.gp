set terminal svg size 560,360; set output 'cb_polar_errorbars.svg'
# polar error bars: each along the radius, r - dr to r + dr
$DATA << EOD
0   1.3 0.2
30  0.9 0.1
60  0.7 0.1
90  1.0 0.3
120 1.1 0.1
150 0.5 0.1
180 1.2 0.2
EOD
set polar; set angles degrees; set grid polar 15
unset border; unset xtics; unset ytics; unset raxis
set yrange [0:1.5]; set size ratio 0.5
plot $DATA with yerrorbars lw 1.5 title "polar error bars"
