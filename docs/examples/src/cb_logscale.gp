set terminal svg size 560,320; set output 'cb_logscale.svg'
set logscale y
set format y '%.0e'
set grid
plot 'run.dat' u 1:2 t 'continuity'
