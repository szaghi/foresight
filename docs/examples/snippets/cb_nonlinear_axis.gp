set terminal svg size 560,320; set output 'cb_nonlinear_axis.svg'
# set nonlinear x: a broken axis, the gap between 100 and 500 left out (f undefined there)
gap = 25.
f(x) = (x <= 100) ? x : (x < 500) ? NaN : (x - 400 + gap)
g(x) = (x <= 100) ? x : (x < 100 + gap) ? NaN : (x + 400 - gap)
set xrange [15:600] noextend
set nonlinear x via f(x) inverse g(x)
set xtics 50; set border 3; set xtics nomirror; set ytics nomirror; set key top right
$LOAD << EOD
20 3.1
40 2.6
60 2.2
80 1.9
100 1.7
520 0.9
540 0.85
560 0.82
580 0.8
EOD
plot $LOAD using 1:2 with linespoints pt 7 t 'residual'
