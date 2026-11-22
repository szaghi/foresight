set terminal svg size 640,260; set output 'cb_time_minor.svg'
# a minor tick every 10 minutes of the wall clock, whatever the major step
set xdata time; set timefmt '%Y-%m-%d %H:%M:%S'; set format x '%H:%M'
set mxtics time 10 minutes
set title 'set mxtics time 10 minutes'; set logscale y; set format y '%h'; set key off
plot 'live.dat' u 1:4 w l lw 2
