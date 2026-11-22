set terminal svg size 560,320; set output 'cb_arrays.svg'
# arrays: filled in a loop, plotted and stated as a file, indexed by a data column
array T[8]
do for [i = 1:|T|] { T[i] = 300 + 40 * (1 - exp(-0.4 * i)) }
array where = ['inlet', 'throat', 'exit']
stats T nooutput
set title sprintf('%d probes (%s to %s), mean %.1f K', |T|, where[1], where[|where|], STATS_mean)
set xlabel 'probe'; set ylabel 'T [K]'; set key bottom right; set xrange [0:9]
plot T w lp pt 7 t 'T', T u 1:(T[$1] - STATS_mean + 300) w lp dt 2 t 'T - mean + 300'
