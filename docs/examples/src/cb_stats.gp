#run cb_stats foresight cb_stats.gp
set terminal svg size 560,320; set output 'cb_stats.svg'
# the drag coefficient once settled: statistics of the iterations from 80 on (the others invalid), the report printed
stats 'run.dat' u ($1 >= 80 ? $5 : 1/0) name 'cd' output
set xlabel 'iteration'; set ylabel 'cd'; set key bottom right
plot 'run.dat' u 1:5 w l lw 2 t 'cd', \
     cd_mean w l dt 2 lc 'black' t sprintf('mean %.4f +- %.4f', cd_mean, cd_stddev)
