set terminal svg size 560,320; set output 'cb_xyerrorbars.svg'
set logscale x
set xlabel 'Re'; set ylabel 'cd'
plot 'measures.dat' using 1:2:3:4 with xyerrorbars pt 7 title 'wind tunnel'
