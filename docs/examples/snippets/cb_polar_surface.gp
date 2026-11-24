set terminal svg size 520,420; set output 'cb_polar_surface.svg'
# set polar grid: scattered theta:r:z weighted onto a polar grid and drawn with surface, the points over it
set angles degrees
set polar grid 36,8 gauss scale 15
set print $S
do for [i=1:150] {
    t = 360*rand(0); r = 100*sqrt(rand(0))
    print t, r, exp(-((r*cos(t) - 40)**2 + (r*sin(t) - 20)**2)/800)
}
unset print
set size square; unset xtics; unset ytics; unset border; set border polar
set rtics 25; set ttics 0,45,315; unset key
set palette viridis; set cbrange [0:1]
plot $S using 1:2:3 with surface, $S using 1:2 with points pt 7 ps 0.4 lc "white"
