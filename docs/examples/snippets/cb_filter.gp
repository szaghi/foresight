set terminal svg size 560,320; set output 'cb_filter.svg'
# 1/0 is undefined: those points are gaps
plot 'run.dat' using 1:($5 > 0.3 ? $5 : 1/0) with points pt 7 title 'cd above 0.3'
