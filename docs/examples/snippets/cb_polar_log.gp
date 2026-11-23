set terminal svg size 480,420; set output 'cb_polar_log.svg'
# a log r axis: decades equally spaced from the pole at r = 1, impulses from the pole, theta labels turned
set polar; set angles degrees; set size square; unset border; set border polar; unset xtics; unset ytics; unset key
set logscale r; set rrange [1:1000]; set rtics (1, 10, 100, 1000)
set grid polar 30; set ttics 0,30 rotate
set samples 37; set trange [0:360]
plot 10**(1.5 + 1.5*cos(3*t)) with impulses lw 2
