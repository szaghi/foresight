set terminal svg size 640,300; set output 'cb_point_types.svg'
# the point types 0..15 (pt) and dash types 1..5 (dt): a reference chart
$ROW << EOD
0 1
EOD
set xrange [-0.5:15.5]; set yrange [-6:2]; unset ytics; set xtics 1; set key off
set title 'point types (pt 0 to 15) and dash types (dt 1 to 5)'
plot for [i = 0:15] $ROW u (i):2 w p pt i ps 2 notitle, \
     for [d = 1:5] -d dt d lw 2 notitle
