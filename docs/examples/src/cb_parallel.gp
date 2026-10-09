set terminal svg size 560,320; set output 'cb_parallel.svg'
set paxis 1 range [0:10]; set paxis 2 range [0:10]; set paxis 3 range [0:10]
set paxis 4 range [0:10]; set paxis 5 range [0:10]; set paxis 1 tics 2
plot 'solvers.dat' u 2 w parallel lw 2 t 'speed', '' u 3 w parallel t 'memory', '' u 4 w parallel t 'accuracy', \
     ''            u 5 w parallel t 'scaling', '' u 6 w parallel t 'robustness'
