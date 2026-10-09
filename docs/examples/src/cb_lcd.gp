set terminal svg size 640,300 theme lcd; set output 'cb_lcd.svg'
set multiplot layout 1,2
plot 'run.dat' u 1 w gauge range [0:150] segments 20 format '%3.0f' t 'ITER'
set key top right; set style fill solid segments 12
plot 'timings.dat' u 2:xtic(1) w hist t 'mesh', '' u 3 w hist t 'fluxes'
unset multiplot
