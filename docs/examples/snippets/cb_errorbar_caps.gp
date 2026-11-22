set terminal svg size 760,280; set output 'cb_errorbar_caps.svg'
# the error bar caps: the default, longer and red, none
set multiplot layout 1,3
set logscale x; set key off; set xrange [5e3:2e6]
set title 'default'
plot 'measures.dat' u 1:2:4 w yerrorbars pt 7
set title "set errorbars 3 lc 'red' lw 2"; set errorbars 3 lc rgb 'red' lw 2
plot 'measures.dat' u 1:2:4 w yerrorbars pt 7
set title 'set errorbars small'; set errorbars small
plot 'measures.dat' u 1:2:4 w yerrorbars pt 7
unset multiplot
