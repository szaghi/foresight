set terminal svg size 560,320; set output 'cb_fill_color.svg'
# fc: the fill's own color, here transparent (#AARRGGBB), the line keeping lc; rgb reads a string variable
set samples 80
set table $E; plot [0:10] exp(-x / 4) * sin(2*x); unset table
Shade = '#80e0a080'
plot $E using 1:($2 + 0.15):($2 - 0.15) with filledcurves fc rgb Shade title 'error band', \
     '' using 1:2 with lines lw 2 lc rgb '#b03030' title 'model'
