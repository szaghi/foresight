set terminal svg size 560,360; set output 'cb_named_colormaps.svg'
# named colormaps: each saved from a palette, then chosen per item by lc palette NAME
set palette defined (0 "gray90", 1 "dark-blue"); set colormap new blues
set palette defined (0 "dark-red", 1 "yellow"); set colormap new flame
set palette cubehelix; set colormap new ch
unset colorbox; set key off; set xrange [0:21]; set yrange [-1.5:4]
set samples 21
plot '+' using 1:(sin($1/3)):1 with points pt 7 ps 1.5 lc palette blues, \
     '+' using 1:(1.2 + sin($1/3)):1 with points pt 7 ps 1.5 lc palette flame, \
     '+' using 1:(2.4 + sin($1/3)):1 with points pt 7 ps 1.5 lc palette ch
