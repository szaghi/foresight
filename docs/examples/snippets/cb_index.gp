set terminal svg size 560,320; set output 'cb_index.svg'
set key bottom right
plot 'probes.dat' index 0 with lp pt 5 title 'run 1', '' index 1 with lp pt 9 title 'run 2'
