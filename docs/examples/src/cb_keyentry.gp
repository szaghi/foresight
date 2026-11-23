set terminal svg size 560,320; set output 'cb_keyentry.svg'
# key entries of their own (keyentry) for a boxplot and error bars; set style data filledcurves y=0 for the data
set style fill solid 0.4
set style data filledcurves y=0
set key top left
$D << EOD
0 1
1 3
2 2
3 4
EOD
plot keyentry with boxplot lc 3 title 'boxplot sample', keyentry with yerrorbars lc 4 title 'error bars', \
     $D lc 1 title 'data (filledcurves y=0)'
