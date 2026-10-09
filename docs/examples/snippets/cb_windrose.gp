set terminal svg size 520,420; set output 'cb_windrose.svg'
set polar; set angles degrees; set theta top clockwise
set size square; unset border; set border polar; unset xtics; unset ytics
set grid polar 45; set ttics 0,45; set key outside
set style fill solid 0.6 border lc 'white'
plot 'wind.dat' u ($1-20):(0):(40):2 w sectors t '< 5 m/s', \
     ''         u ($1-20):2:(40):3 w sectors t '>= 5 m/s'
