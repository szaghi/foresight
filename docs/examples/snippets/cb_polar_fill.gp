set terminal svg size 480,420; set output 'cb_polar_fill.svg'
# a polar band: the area outside the circle r = 2.5 (filledcurves above r=2.5), and its curve
set polar; set size square; unset border; set border polar; unset xtics; unset ytics; unset key
set grid polar 30; set rrange [0:4]
set style fill solid 0.5
plot 3 + sin(t)*cos(5*t) with filledcurves above r=2.5, 3 + sin(t)*cos(5*t) with lines lw 2
