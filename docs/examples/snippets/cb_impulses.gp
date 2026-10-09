set terminal svg size 560,320; set output 'cb_impulses.svg'
set xlabel 'frequency [Hz]'; set ylabel 'amplitude'
plot 'spectrum.dat' u 1:2 w impulses lw 3 t 'impulses', '' u 1:($2+0.05) w dots t 'dots'
