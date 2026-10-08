set terminal svg size 560,320; set output 'cb_expression.svg'
set xlabel 'time [min]'; set ylabel 'cd [counts]'
plot 'run.dat' using ($1 * 0.5 / 60):($5 * 1e4) title 'cd'
