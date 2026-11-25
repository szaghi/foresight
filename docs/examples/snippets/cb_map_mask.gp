set terminal svg size 560,400; set output 'cb_map_mask.svg'
# a surface gridded from scattered points, masked to their convex hull (with mask, the mask item option)
set print $P
do for [i=1:120] {
  r = 2*sqrt(i*0.6180339887 - floor(i*0.6180339887))
  print sprintf("%g %g", r*cos(2.4*i) + 0.4*sin(i), 0.7*r*sin(2.4*i))
}
unset print
set table $HULL
plot $P using 1:2 convexhull with lines
unset table
set view map
set dgrid3d 50,50 gauss 0.6
set palette viridis
set key top left opaque
splot $HULL using 1:2:(0) with mask notitle, \
      $P using 1:2:($1*$2) mask with pm3d title 'x y', \
      $HULL using 1:2:(0) nogrid with lines lc 'black' lw 2 title 'hull'
