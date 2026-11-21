set terminal svg size 640,480; set output 'cb_time.svg'
# a log stamped with the wall clock: the time spans two columns (y is column 4), ticks in whole time units
set xdata time; set timefmt '%Y-%m-%d %H:%M:%S'
set multiplot layout 2,1
set title 'labels invented by gnuplot rules'; set logscale y; set format y '%h'
plot 'live.dat' u 1:4 w l lw 2 t 'residual'
set title "set format x '%H:%M', a 30 minutes step"; unset logscale y; set format y '%g'
set format x '%H:%M'; set xtics 1800; set xrange ['2024-03-01 10:00:00':'2024-03-01 12:00:00']
plot 'live.dat' u 1:5 w l lw 2 t 'cd'
unset multiplot
