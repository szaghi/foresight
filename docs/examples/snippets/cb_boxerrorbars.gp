set terminal svg size 560,320; set output 'cb_boxerrorbars.svg'
set style fill solid 0.4; set boxwidth 0.6
set ylabel 'seconds per step'
plot 'bench.dat' u 1:2:3:xtic(4) w boxerrorbars t 'mean +/- std of 20 runs'
