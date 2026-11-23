set terminal svg size 560,360; set output 'cb_size_square.svg'
# set size ratio -1: one unit as long on x as on y, a circle round whatever the ranges
set size ratio -1
set parametric; set trange [0:2*pi]; set samples 200
set xrange [-3:3]; set yrange [-1.2:1.2]; set grid; set key top right
plot cos(t), sin(t) lw 2 t 'unit circle', 2*cos(t), 0.5*sin(t) lw 2 t 'ellipse 2 x 0.5'
