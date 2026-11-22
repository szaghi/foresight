set terminal svg size 560,360; set output 'cb_parametric.svg'
# parametric curves: x(t), y(t) over trange, a Lissajous figure and an epicycloid
set parametric; set trange [0:2*pi]; set samples 400
set size ratio 1; set xrange [-1.6:1.6]; set yrange [-1.6:1.6]; set key outside right
plot sin(3*t), cos(2*t) lw 2 t 'Lissajous 3:2', \
     1.2*cos(t) - 0.3*cos(4*t), 1.2*sin(t) - 0.3*sin(4*t) lw 2 t 'epicycloid'
