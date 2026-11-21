set terminal svg size 560,320; set output 'cb_datablock.svg'
# data written inside the script: a datablock, plotted, fitted and measured as a file
$CONV << EOD
# h        error
0.1        2.10e-3
0.05       5.30e-4
0.025      1.29e-4
0.0125     3.33e-5
0.00625    8.20e-6
EOD
f(x) = c * x**p; c = 1; p = 1
fit f(x) $CONV u 1:2 via c, p
stats $CONV u 2 nooutput
set logscale xy; set format y '%h'; set key top left
set xlabel 'h'; set ylabel 'error'
plot $CONV u 1:2 w lp pt 7 t sprintf('%d errors', STATS_records), f(x) dt 2 t sprintf('order %.2f', p)
