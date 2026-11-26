set terminal svg size 900,340; set output 'cb_view3d_projection.svg'
# a surface and its two side projections: the xz and yz planes seen edge-on, as gnuplot's set view projection
set multiplot layout 1,3 title 'a surface and its side projections'
set isosamples 24, 24
set xrange [-3:3]; set yrange [-3:3]
unset key
set xlabel 'x'; set ylabel 'y'; set zlabel 'z'; set ztics 0.5
f(x, y) = exp(-(x**2 + y**2)/4)*cos(x) + 0.1*y
set title 'set view 60, 30'
splot f(x, y)
set title 'set view projection xz'
set view projection xz
splot f(x, y)
set title 'set view projection yz'
set view projection yz
splot f(x, y)
unset multiplot
