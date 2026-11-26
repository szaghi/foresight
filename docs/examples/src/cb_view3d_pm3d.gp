set terminal svg size 560,400; set output 'cb_view3d_pm3d.svg'
# a colored surface in a 3D view, its map on the base plane (set pm3d at bs)
set samples 40; set isosamples 40
set xrange [-3:3]; set yrange [-3:3]
set view 55, 35
set pm3d at bs
set palette rgbformulae 33,13,10
set key off
set title 'pm3d at the base and at the surface'
splot exp(-(x*x + y*y)/3)*cos(x*y) with pm3d
