set terminal svg size 560,320; set output 'cb_title_at.svg'
# titles at the end of their curves (no key), as gnuplot's title ... at end
unset key
set rmargin 10
set xrange [0:10]
plot for [k=1:4] k*sqrt(x) lw 2 title sprintf('k = %d', k) at end
