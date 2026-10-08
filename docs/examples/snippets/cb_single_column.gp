set terminal svg size 560,320; set output 'cb_single_column.svg'
# one column: x is the point number, as using 0:1
plot 'single.dat' with linespoints pt 7
