set terminal svg size 560,320; set output 'cb_fillsteps.svg'
# fillsteps: the area under steps, filled to y = 0 in the fill style
set style fill solid 0.5
set samples 30
set table $H; plot [0:15] 6*exp(-(x - 6)**2 / 10) + 1; unset table
set yrange [0:8]
plot $H using 1:2 with fillsteps lc rgb '#56b4e9' title 'fillsteps', \
     '' using 1:2 with steps lw 2 lc rgb '#0072b2' title 'steps'
