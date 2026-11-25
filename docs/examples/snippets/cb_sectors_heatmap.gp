set terminal svg size 560,400; set output 'cb_sectors_heatmap.svg'
# a polar heat map: one annular sector per (theta, r) cell, filled from the palette by a value (fc palette)
set angles degrees
set theta top cw
f(t, r) = r * cos(t + 20*r)**2
set size ratio -1
unset border; unset tics; unset key
set xrange [-5.5:5.5]; set yrange [-5.5:5.5]
set palette viridis
set table $cells
set view map
splot sample [t=0:350:10] [r=0:4.5:0.5] '++' using (t):(r):(0)
unset table
plot $cells using 1:2:(10):(0.5):(f($1+5, $2+0.25)) with sectors fc palette fill solid
