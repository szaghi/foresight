set terminal svg size 520,400; set output 'cb_polar_db.svg'
set polar; set angles degrees
set size square; unset border; set border polar; unset xtics; unset ytics
# a level in decibels: -30 dB at the pole, rings every 10 dB on the r axis
set rrange [-30:10]; set rtics 10; set raxis
set grid polar 30; set ttics 0,30; set key outside
# the model over the upper half only
set trange [0:180]
plot 'directivity.dat' u 1:(20*log10($2)) w lp pt 7 ps 0.6 t 'probe [dB]', \
     20*log10(1+cos(t)) t 'cardioid, upper half'
