set terminal svg size 560,320; set output 'cb_lc_shapes.svg'
# a color per shape: boxes and circles take lc variable, the last using column a linetype
$D << EOD
1 3 0.30 1
2 5 0.40 2
3 2 0.25 3
4 6 0.50 4
5 4 0.35 5
EOD
set style fill solid 0.5
set xrange [0:6]; set yrange [0:8]
plot $D using 1:2:4 with boxes lc variable notitle, $D using 1:($2 + 1):3:4 with circles lc variable notitle
