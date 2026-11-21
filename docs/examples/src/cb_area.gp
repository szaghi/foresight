set terminal svg size 560,320; set output 'cb_area.svg'
# the area under a curve (to the bottom of the plot, x1), and a closed polygon
$SHAPE << EOD
6 0.2
9 0.2
9.5 0.6
7.5 0.9
5.5 0.6
EOD
set style fill transparent solid 0.4; set xrange [0:10]; set yrange [0:1]; set key top left
plot 'run.dat' u ($1/20):($5*3 - 0.6) w filledcurves x1 t 'to the bottom (x1)', \
     $SHAPE w filledcurves closed t 'closed'
