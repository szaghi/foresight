set terminal svg size 560,320; set output 'cb_key.svg'
set key below box
set logscale y
plot 'run.dat' u 1:2 t 'continuity', '' u 1:3 t 'momentum', '' u 1:4 t 'energy'
