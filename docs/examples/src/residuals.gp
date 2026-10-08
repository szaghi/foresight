#run ch4 foresight residuals.gp
# Tutorial 4: the solver log, plotted by a script.
set terminal html size 640,380
set output 'ch4.html'
set title 'Residual history'
set xlabel 'iteration'; set ylabel 'residual'
set logscale y
set grid
plot 'run.dat' using 1:2 with lines title 'continuity', \
     ''        using 1:3 with lines title 'momentum', \
     ''        using 1:4 every 8 with linespoints pt 7 title 'energy'
