#run ch6 foresight two_axes.gp
# Tutorial 6: residual and drag on one plot, each on its own axis, and a model function.
set terminal html size 640,380
set output 'ch6.html'
set title 'Convergence and drag'
set xlabel 'iteration'
# region axes
set logscale y
set ylabel 'continuity residual'
set y2label 'cd'
set ytics nomirror
set y2tics
# endregion axes
# region plot
plot 'run.dat' using 1:2 title 'continuity', \
     ''        using 1:5 axes x1y2 with points pt 7 ps 0.6 title 'cd', \
     0.30 + 0.25*exp(-x/25)*cos(x/6) axes x1y2 dt 2 title 'model'
# endregion plot
