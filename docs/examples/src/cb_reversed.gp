set terminal svg size 560,320; set output 'cb_reversed.svg'
# min > max reverses the axis
set xrange [120:0]
plot 'run.dat' u 1:5 t 'cd'
