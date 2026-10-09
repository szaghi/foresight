set terminal svg size 480,320; set output 'cb_rose.svg'
plot 'phases.dat' u 2:xtic(1) w rose
