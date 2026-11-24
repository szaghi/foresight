set terminal svg size 480,420; set output 'cb_rlabel.svg'
# set rlabel names the radial axis; titles at the beginning or end of curves, justified; polar lines clipped at the r range
set polar; set angles degrees; set theta top clockwise
set rrange [90:0]; set rtics 30 format "%.0f°"
set rlabel "altitude" offset -2
unset xtics; unset ytics; unset border; set border polar; unset key; set size square
set grid polar 45
set ttics add ("N" 0, "E" 90, "S" 180, "W" -90)
set samples 361
plot [0:360] 60*cos(t - 180) lw 2 title "summer" at end left, \
             25*cos(t - 180) - 10 lw 2 title "winter" at beginning right
