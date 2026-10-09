set terminal svg size 480,320; set output 'cb_pie.svg'
set title 'Time per step'
plot 'phases.dat' u 2:xtic(1) w pie
