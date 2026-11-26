set terminal svg size 560,400; set output 'cb_view3d_lighting.svg'
# a lit surface: the primary light, its highlights and a red spotlight (set pm3d lighting)
set samples 50; set isosamples 50
set xrange [-3:3]; set yrange [-3:3]
set view 50, 30
set pm3d lighting primary 0.6 specular 0.4 spec2 0.3
set pm3d depthorder
unset colorbox
set key off
set title 'pm3d lighting primary 0.6 specular 0.4 spec2 0.3'
splot cos(sqrt(x*x + y*y)*2)*exp(-(x*x + y*y)/8) with pm3d fc 'light-blue'
