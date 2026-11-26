set terminal svg size 560,400; set output 'cb_view3d_contourfill.svg'
# a surface filled between its contour levels: the slices of z at the z ticks (set contourfill ztics)
set samples 41; set isosamples 41
set xrange [-3:3]; set yrange [-3:3]
set view 55, 30
set palette viridis
set pm3d depthorder border lc 'black' lw 0.5
set contourfill ztics
set key off
set title 'splot with contourfill, set contourfill ztics'
splot exp(-(x*x + y*y)/3)*cos(x*y) with contourfill
