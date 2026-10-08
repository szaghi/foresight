set terminal svg size 560,320; set output 'cb_errorbars.svg'
plot 'run.dat' using 1:5:6 every 5 with yerrorbars pt 7 ps 0.6 title 'cd'
