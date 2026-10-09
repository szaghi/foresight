set terminal svg size 560,320; set output 'cb_ellipses.svg'
set style fill transparent solid 0.2; set key top left
plot 'ellipses.dat' u 1:2:3:4:5 w ellipses t '1-sigma ellipses', '' u 1:2 w lp pt 7 t 'calibration'
