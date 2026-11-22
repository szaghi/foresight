set terminal svg size 560,360; set output 'cb_margins.svg'
# two panels lined up whatever their tick labels: the same left and right borders at screen fractions
set multiplot layout 2,1
set lmargin at screen 0.16; set rmargin at screen 0.96
set ylabel 'continuity'; set logscale y; set format y '%.0e'
plot 'run.dat' u 1:2 w l t 'continuity'
unset logscale y; set format y '%g'; set ylabel 'energy x 1e6'; set xlabel 'iteration'
plot 'run.dat' u 1:($3*1e6) w l lc 2 t 'energy'
unset multiplot
