#run ch7 foresight dashboard.gp
# Tutorial 7: a dashboard of the run, one panel per quantity.
set terminal html size 900,440
set output 'ch7.html'
# region layout
set multiplot layout 1,2 title 'Run monitor'
set title 'residuals'
set logscale y; set grid
plot 'run.dat' u 1:2 t 'continuity', '' u 1:3 t 'momentum', '' u 1:4 t 'energy'
set title 'drag coefficient'
unset logscale y
plot 'run.dat' u 1:5:6 every 4 with yerrorbars pt 7 ps 0.5 t 'cd'
unset multiplot
# endregion layout
