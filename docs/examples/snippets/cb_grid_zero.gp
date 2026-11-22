set terminal svg size 560,320; set output 'cb_grid_zero.svg'
# major and minor grid lines in their own style, the zero axes, a two-sided thicker border, x ends at the data
set mxtics 5; set mytics 5
set grid x y mx my lc 'gray' lw 0.5 dt 3
set xzeroaxis lw 1.5; set yzeroaxis lw 1.5
set border 3 lw 1.5; set tics out nomirror scale 1.5, 0.75
set autoscale xfix; set key bottom right
plot [-2*pi:2*pi] sin(x)*exp(-0.1*x) t 'sin(x) exp(-x/10)', cos(x) t 'cos(x)'
