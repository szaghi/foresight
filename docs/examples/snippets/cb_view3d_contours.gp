set terminal svg size 560,400; set output 'cb_view3d_contours.svg'
# contour lines on the base plane of a 3D view, their values on them (with labels)
set contour base
set cntrparam levels incremental -0.8, 0.4, 0.8
set cntrlabel start 3 interval 30
set isosamples 30, 30
set xrange [-3:3]; set yrange [-3:3]
set view 60, 30
set key off
set title 'contours of sin(x) cos(y) and their values'
splot sin(x)*cos(y) lc 'gray50', sin(x)*cos(y) with labels boxed notitle
