set terminal html size 640,380
set output 'monitor.html'
set logscale y; set grid
plot 'run.dat' u 1:2 t 'continuity', '' u 1:3 t 'momentum'
