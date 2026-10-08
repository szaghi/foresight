# Tutorial 8: the script foresight --watch re-renders while the solver writes run.dat.
set terminal html size 640,380
set output 'monitor.html'
set logscale y; set grid
plot 'run.dat' u 1:2 t 'continuity', '' u 1:3 t 'momentum'
