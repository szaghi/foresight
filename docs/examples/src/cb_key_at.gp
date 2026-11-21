set terminal svg size 560,320; set output 'cb_key_at.svg'
set logscale y
# the top left corner of the key at iteration 60, residual 1 (data coordinates); graph or screen fractions also work
set key at 60, 1 left top box
plot 'run.dat' u 1:2 t 'continuity', '' u 1:3 t 'momentum', '' u 1:4 t 'energy'
