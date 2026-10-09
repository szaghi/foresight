set terminal svg size 560,320; set output 'cb_arrows.svg'
set xrange [0:6]; set yrange [0:4.5]; set key below
plot 'stations.dat' u 1:2:3:4 w arrows lw 2 t 'wind (length: speed, angle: direction)', \
     ''             u 1:2:5 w labels right offset -1,0 notitle
