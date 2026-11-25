set terminal svg size 560,400; set output 'cb_view3d_hidden.svg'
# a parametric surface with hidden lines: opaque, its underside in the next color, the key below
set parametric
set hidden3d
set isosamples 36, 12
set urange [0:2*pi]; set vrange [-1:1]
set view 60, 30
set key below
set title 'a Moebius strip'
splot (1 + v/2*cos(u/2))*cos(u), (1 + v/2*cos(u/2))*sin(u), v/2*sin(u/2) title 'strip'
