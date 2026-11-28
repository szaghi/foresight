#run pb05 foresight pb05_numbers.gp
# region numbers
# the numbers of the run on its plot: the converged mean of the last 20 iterations, the restart marked
stats 'run.dat' using ($1 > 100 ? $5 : 1/0) nooutput
set terminal svg size 640,380
set output 'pb05.svg'
set title sprintf('c_d = %.4f ± %.4f (the last 20 iterations, shaded)', STATS_mean, STATS_stddev)
set xlabel 'iteration'; set ylabel 'c_d'
set arrow 1 from 61, graph 0 to 61, graph 1 nohead dt 2
set label 1 'restart' at 61, graph 0.92 offset 0.5,0
set object 1 rectangle from 101, graph 0 to 120, graph 1 fc 'gray' fs solid 0.15 noborder behind
plot 'run.dat' u 1:5:6 w yerrorbars pt 7 ps 0.5 t 'c_d', STATS_mean w l dt 3 t 'mean'
# endregion numbers
