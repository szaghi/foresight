set terminal svg size 560,320; set output 'cb_no_key.svg'
unset key
plot 'run.dat' u 1:5, '' u 1:5:6 every 10 with yerrorbars
