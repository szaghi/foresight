set terminal svg size 560,320; set output 'cb_function_fills.svg'
# functions filled as data: a band from a level, a closed curve, boxes of the samples over their own range
set samples 41
set xrange [0:10]; set yrange [0:8]
set key top right
set style fill transparent solid 0.35
plot 5 + sin(x) with filledcurves y=5 title 'filledcurves y=5', \
     2 + cos(x)*exp(-x/5) with filledcurves closed title 'filledcurves closed', \
     [0:4] 0.6*x with boxes fs solid 0.6 title 'boxes, [0:4]'
