set terminal svg size 560,320; set output 'cb_ticks.svg'
set xtics 0,30,120
set ytics 0.1
set format y '%.2f'
plot 'run.dat' u 1:5 t 'cd'
