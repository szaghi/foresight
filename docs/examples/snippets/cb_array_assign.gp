set terminal svg size 560,320; set output 'cb_array_assign.svg'
# array elements assigned inside an expression: stats stores each row of a datablock in A, then A is plotted
$DATA << EOD
1 3.2
2 4.1
3 2.7
4 5.0
5 3.9
EOD
stats $DATA using 1 nooutput
array A[STATS_records]
stats $DATA using (A[int($0 + 1)] = $2) nooutput
set key left; set yrange [0:6]; set xrange [0:6]
plot A using 1:2 with linespoints pt 7 title "A[i] filled by stats", \
     A using 1:2:(sprintf("%.1f", $2)) with labels offset 0,1 notitle
