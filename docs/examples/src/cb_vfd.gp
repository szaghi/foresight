set terminal svg size 640,440 theme vfd; set output 'cb_vfd.svg'
set multiplot title 'RUN MONITOR'
set origin 0,0.62; set size 0.4,0.38; set readout vertical
plot 'run.dat' u 1 w readout format '%4.0f' t 'ITER', '' u 5 w readout format '%6.4f' t 'CD'
set origin 0.4,0.62; set size 0.6,0.38; set key top left
set style fill solid segments 10
plot 'timings.dat' u 2:xtic(1) w hist t 'mesh', '' u 3 w hist t 'fluxes'
set origin 0,0; set size 1,0.62; set key top right
set logscale y; set grid
plot 'run.dat' u 1:2 w l lw 2 t 'continuity', '' u 1:3 w l lw 2 t 'momentum'
unset multiplot
