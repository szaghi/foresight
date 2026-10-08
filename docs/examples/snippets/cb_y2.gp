set terminal svg size 560,320; set output 'cb_y2.svg'
set logscale y; set ytics nomirror; set y2tics
plot 'run.dat' u 1:2 t 'residual', '' u 1:5 axes x1y2 t 'cd'
