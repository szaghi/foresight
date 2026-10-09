set terminal svg size 560,320; set output 'cb_boxplot.svg'
set style fill solid 0.3; set ylabel 'wall time per step [s]'
plot 'walltime.dat' u (1):2:(0.5):1 w boxplot t '12 runs per solver'
