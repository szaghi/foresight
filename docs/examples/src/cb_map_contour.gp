set terminal svg size 560,400; set output 'cb_map_contour.svg'
# contour lines over a pm3d map: the levels of a function, a linetype and a key entry each
set view map
set pm3d at b; unset surface
set contour base
set cntrparam levels incremental -0.75, 0.5, 0.75
set samples 40, 40; set isosamples 40, 40
set xrange [-3:3]; set yrange [-3:3]
set palette cubehelix
set key top left box opaque
splot sin(x)*cos(y) lw 2 title 'sin(x) cos(y)'
