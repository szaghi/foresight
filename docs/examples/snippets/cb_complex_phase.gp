set terminal svg size 560,460; set output 'cb_complex_phase.svg'
# a complex function over the plane: the hue its phase, the saturation its magnitude (gnuplot's complex_trig demo)
set palette model HSV defined (0 0 1 1, 1 1 1 1)
set cbrange [-pi:pi]
set cbtics ("-π" -pi, "0" 0, "π" pi)
set cblabel 'phase'
hue(x, y) = (pi + atan2(-y, -x)) / (2*pi)
sat(z) = abs(z) > 1 ? 1 : abs(z)
color(x, y) = hsv2rgb(hue(real(f(x, y)), imag(f(x, y))), sat(f(x, y)), 1)
f(x, y) = atanh(x + y*{0,1})
set urange [-2:2]; set vrange [-2:2]; set xrange [-2:2]; set yrange [-2:2]
set view map; set size square; unset key
set isosamples 80, 80
set title 'atanh(x + iy)'
splot '++' using 1:2:(color(x, y)) with pm3d lc rgb variable
