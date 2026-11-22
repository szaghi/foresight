set terminal svg size 760,300; set output 'cb_runtime.svg'
# a title from shell commands, then reset: the second panel is back to the defaults
host = system('echo solver-7')
n = `grep -vc '^#' live.dat`
set multiplot layout 1,2
set title sprintf('%s: %d log lines', host, n); set logscale y; set format y '%h'; set grid; set key off
plot 'live.dat' u 3:4 w l lw 2
reset
set title 'after reset'
plot 'live.dat' u 3:4 w l lw 2
unset multiplot
