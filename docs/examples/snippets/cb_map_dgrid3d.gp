set terminal svg size 560,400; set output 'cb_map_dgrid3d.svg'
# a density map of scattered points: set dgrid3d grids them with a Gaussian kernel (kdensity sums its weights)
set print $P
do for [i=1:400] {
  r = sqrt(i*0.6180339887 - floor(i*0.6180339887))
  c = (i % 3 == 0) ? 1.5 : -1
  print sprintf("%g %g", c + r*cos(2.4*i), 0.6*c + 0.8*r*sin(2.4*i))
}
unset print
set view map
set dgrid3d 60,60 gauss kdensity 0.35
set palette cubehelix negative
set key top left opaque
splot $P using 1:2:(1) with pm3d title 'density', \
      $P using 1:2:(0) nogrid with points pt 7 ps 0.3 lc 'black' title 'points'
