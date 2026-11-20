set terminal svg size 560,320; set output 'cb_mtics.svg'
set logscale y
set mxtics 4
set mytics
plot 'run.dat' u 1:2 t 'continuity', '' u 1:3 t 'momentum'
