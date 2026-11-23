set terminal svg size 560,320; set output 'cb_palette_functions.svg'
# a palette of functions of gray: in HSV, the hue running from red to blue
set palette model HSV functions gray * 0.66, 0.8, 0.95
set samples 120
set table $S; plot [0:10] sin(x) * exp(-x / 8); unset table
plot $S using 1:2:2 with points pt 7 ps 1.2 lc palette z notitle
