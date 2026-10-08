set terminal svg size 560,320; set output 'cb_columns.svg'
plot 'run.dat' using 1:5 with lines title 'cd'
