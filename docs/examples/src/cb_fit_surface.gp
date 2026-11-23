#run cb_fit_surface foresight cb_fit_surface.gp
set terminal svg size 560,320; set output 'cb_fit_surface.svg'
# fit of two independent variables: using x:y:z:s, the function of x and y
$GRID << EOD
1 1 3.1
1 2 5.0
2 1 4.1
2 2 6.0
3 1 4.9
3 2 7.1
3 3 9.0
EOD
plane(x, y) = a*x + b*y + c
a = 1; b = 1; c = 0.5
fit plane(x, y) $GRID using 1:2:3:(1) via a, b, c
print sprintf('a = %.3f, b = %.3f, c = %.3f', a, b, c)
set xlabel 'x'; set ylabel 'z'; set key top left
plot for [k = 1:3] $GRID using 1:($2 == k ? $3 : NaN) with points pt 7 ps 1.4 lc k t sprintf('y = %d', k), \
     for [k = 1:3] plane(x, k) lw 2 lc k notitle
