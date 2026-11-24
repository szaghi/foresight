set terminal svg size 480,420; set output 'cb_reversed_r.svg'
# a reversed r axis: elevation 90 at the pole, the horizon on the rim, a sun path over the sky
set polar; set angles degrees; set theta top clockwise
set size square; unset border; unset xtics; unset ytics; set border polar
set rrange [90:0]; set rtics 30; set grid polar 45 lt -1 lw 0.5
set trange [60:300]; set key bottom right
plot 70 - 50*abs((t - 180)/120)**1.5 lw 2 t 'sun elevation'
