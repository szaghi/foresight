set terminal svg size 480,320 theme vfd; set output 'cb_donut_vfd.svg'
set title 'TIME PER STEP'
plot 'phases.dat' u 2:xtic(1) w pie donut 0.6
