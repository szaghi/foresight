set terminal svg size 560,320; set output 'cb_styles.svg'
set style line 1 lc rgb '#0072b2' lw 2
set style line 2 lc rgb '#e51e10' dt 2 pt 4
set logscale y
plot 'run.dat' u 1:2 ls 1 t 'continuity', '' u 1:3 every 6 w lp ls 2 t 'momentum'
