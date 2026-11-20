set terminal svg size 560,320; set output 'cb_inline_range.svg'
plot [t=0:4*pi] [-1.2:1.2] sin(t) t 'sin(t)', exp(-t/6)*cos(t) t 'damped'
