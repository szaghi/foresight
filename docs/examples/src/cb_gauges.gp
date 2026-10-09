set terminal svg size 600,240 theme vfd; set output 'cb_gauges.svg'
plot 'run.dat' u 1 w gauge range [0:150] segments 24 format '%3.0f' t 'ITER', \
     ''        u 5 w gauge range [0:0.6] segments 24 format '%5.3f' t 'CD'
