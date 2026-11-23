set terminal svg size 560,320; set output 'cb_stats_matrix.svg'
# stats of a matrix: its size and extremes, also of the part `every` keeps; every on a matrix image
$M << EOM
3 3 3 3 3 3 3
3 4 4 4 4 4 3
3 4 5 5 5 4 3
3 4 5 6 5 4 3
3 4 5 5 5 4 3
3 4 4 4 4 4 3
3 3 3 3 3 3 3
EOM
stats $M every ::2::4 matrix nooutput
set title sprintf("columns 2 to 4: %d x %d values, mean %.2f", STATS_size_x, STATS_size_y, STATS_mean)
set xrange [-0.5:6.5]; set yrange [-0.5:6.5]; set cbrange [3:6]; unset key
plot $M every ::2::4 matrix with image
