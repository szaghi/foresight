set terminal svg size 560,400; set output 'cb_view3d_surface.svg'
# a function of x and y as a mesh of iso-curves, in gnuplot's default 3D view (set view 60, 30)
set title 'sin(x) cos(y)'
set xlabel 'x'; set ylabel 'y'; set zlabel 'z'
set isosamples 25, 25
set xrange [-3:3]; set yrange [-3:3]
splot sin(x)*cos(y) title 'surface'
