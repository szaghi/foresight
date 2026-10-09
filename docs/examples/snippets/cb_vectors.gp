set terminal svg size 560,400; set output 'cb_vectors.svg'
set size square; set xrange [-3.5:3.5]; set yrange [-2.8:2.8]; set key below
plot 'flow.dat' every 2 u 1:2:(2*$3):(2*$4) w vectors filled head t 'velocity', \
     'probes_xy.dat' u 1:2:3 w labels left offset 1,0 point pt 7 tc 'red' notitle
