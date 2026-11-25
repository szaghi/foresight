set terminal svg size 560,360; set output 'cb_fit_xyerrors.svg'
# Pearson's data with York's weights: a straight line fitted three ways (gnuplot's fit.dem)
$PY << EOD
0.0 1000 5.9 1.0
0.9 1000 5.4 1.8
1.8 500 4.4 4.0
2.6 800 4.6 8.0
3.3 200 3.5 20.0
4.4 80 3.7 20.0
5.2 60 2.8 70.0
6.1 20 2.8 70.0
6.5 1.8 2.4 100.0
7.4 1.0 1.5 500.0
EOD
f(x) = a + b*x;    a = 5; b = -0.5
fy(x) = ay + by*x; ay = 5; by = -0.5
fxy(x) = axy + bxy*x; axy = 5; bxy = -0.5
fit f(x) $PY using 1:3 via a, b                                                  # no errors
fit fy(x) $PY using 1:3:(sqrt(1./$4)) yerrors via ay, by                         # errors of y
fit fxy(x) $PY using 1:3:(sqrt(1./$2)):(sqrt(1./$4)) xyerrors via axy, bxy       # errors of x and y
set key bottom left
set title "one line, three fits"
plot $PY using 1:3:(sqrt(1./$2)):(sqrt(1./$4)) with xyerrorbars lt -1 title 'data', \
     f(x) lw 2 title sprintf('no errors: %.3f %+.3f x', a, b), \
     fy(x) lw 2 title sprintf('yerrors: %.3f %+.3f x', ay, by), \
     fxy(x) lw 2 title sprintf('xyerrors: %.3f %+.3f x', axy, bxy)
