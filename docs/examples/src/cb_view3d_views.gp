set terminal svg size 760,400; set output 'cb_view3d_views.svg'
# one surface seen from two sides: the view rotated, the z axis stretched, the base plane at z = 0, the whole box
set multiplot layout 1,2 title 'one surface, two views'
set isosamples 20, 20
set xrange [-3:3]; set yrange [-3:3]
unset key
set title 'set view 60, 30'
splot exp(-(x**2 + y**2)/4)*cos(x)
set view 75, 210, 1, 1.2
set xyplane at 0
set border 4095
set title 'set view 75, 210, 1, 1.2'
splot exp(-(x**2 + y**2)/4)*cos(x)
unset multiplot
