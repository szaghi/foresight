set terminal svg size 560,360; set output 'cb_smooth_path.svg'
# smooth path: a spline along each set of points in their order, closed with filledcurves
$CURVES << EOD
1   2
1.5 2
2   2.5
3   5
2.5 5
1.5 4

3   3
3.5 3.1
3.7 3.2
3.6 3.7
3.5 4.0
3.2 3.5
3   3
EOD
set xrange [0:5]; set yrange [1:6]; set key top right
set style fill transparent solid 0.25 border
plot $CURVES using 1:2 smooth path with filledcurves closed title "smooth path", \
     $CURVES using 1:2 with points pt 7 lc "#0072b2" title "points"
