set terminal svg size 560,400; set output 'cb_palette_function.svg'
# points colored by palette(z) with a transparency in the top byte (lc rgb variable)
set cbrange [-1:1]
set palette rgbformulae 33,13,10
set samples 60
set key off
set title 'palette(z) colors, half transparent'
alpha = 0x80000000
plot sample [t=0:2*pi] '+' using (cos(t)):(sin(2*t)):(alpha + palette(sin(3*t))) \
     with points pt 7 ps 3 lc rgb variable
