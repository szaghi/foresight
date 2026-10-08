set terminal svg size 560,320; set output 'cb_every.svg'
set logscale y
plot 'run.dat' u 1:2 every 10 with linespoints pt 6 title 'every 10th iteration'
