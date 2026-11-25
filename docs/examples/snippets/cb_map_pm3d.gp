set terminal svg size 560,400; set output 'cb_map_pm3d.svg'
# a function of x and y as a colored map: gnuplot's pm3d surface seen from above
set view map
set title 'sin(x) cos(y)'
set xlabel 'x'; set ylabel 'y'
set samples 30, 30; set isosamples 30, 30
set xrange [-pi:pi]; set yrange [-pi:pi]
set pm3d interpolate 2,2
splot sin(x)*cos(y) with pm3d notitle
