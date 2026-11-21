set terminal svg size 560,320; set output 'cb_plot_for.svg'
# one line per residual column, its title a word of a string
names = 'continuity momentum energy'
set logscale y; set format y '%.0e'; set xlabel 'iteration'; set ylabel 'residual'
plot for [i=2:4] 'run.dat' u 1:i w l lw 2 t word(names, i-1)
