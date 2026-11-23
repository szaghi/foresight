set terminal svg size 560,320; set output 'cb_key_options.svg'
# the key in two columns, the y label moved and colored, the title on the right
set key top right columns 2 box
set ylabel 'amplitude' offset 1,0 tc rgb '#0072b2'
set title 'Bessel functions' right
set xrange [0:20]; set yrange [-1:1.6]
plot besj0(x), besj1(x), besy0(x), besy1(x)
