set terminal svg size 560,400; set output 'cb_binary_log.svg'
# a solver's binary log: records of an int32 iteration and two float64 residuals, read as gnuplot's binary format
set title 'residuals from a binary log'
set logscale y
set format y '10^{%L}'
set xlabel 'iteration'
set ylabel 'residual'
plot 'residuals.bin' binary format='%int32%float64%float64' using 1:2 with lines lw 2 title 'continuity', \
     'residuals.bin' binary format='%int32%*float64%float64' using 1:2 with lines lw 2 title 'momentum'
