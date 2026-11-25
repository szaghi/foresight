set terminal svg size 560,400; set output 'cb_map_points.svg'
# a field sampled at scattered points, seen from above: gnuplot's map view of a 3D plot
set view map
set title 'samples of x exp(-x^2 - y^2)'
set xlabel 'x'; set ylabel 'y'; set cblabel 'value'
set palette viridis
set xrange [-2:2]; set yrange [-2:2]
set samples 400
splot '+' using (r = 1.9*sqrt(rand(0)), t = 2*pi*rand(0), px = r*cos(t)):(py = r*sin(t)):(px*exp(-px**2 - py**2)) \
      with points pt 7 ps 0.8 lc palette notitle
