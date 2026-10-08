set terminal svg size 560,320; set output 'cb_smooth.svg'
set datafile separator comma   # run.csv: the whole history in one block (run.dat breaks it at the restart)
set xlabel 'cd'; set ylabel 'iterations'; set y2label 'fraction'; set y2tics; set key top left
# bins 0.02 wide: frequency sums the 1 of each point in a bin
plot 'run.csv' u (floor($5/0.02)*0.02):(1) smooth frequency w lp pt 7 t 'histogram', \
     '' u 5:(1) smooth cnormal axes x1y2 t 'distribution'
