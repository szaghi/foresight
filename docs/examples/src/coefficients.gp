#run ch5 foresight coefficients.gp
# Tutorial 5: the CSV log, columns by name, values computed per row.
set terminal html size 640,380
set output 'ch5.html'
# region csv
set datafile separator comma
set key autotitle columnhead
# endregion csv
set title 'Drag coefficient'
set xlabel 'iteration'; set ylabel 'cd [counts]'
# region using
plot 'run.csv' using "iteration":(column("cd") * 1e4), \
     ''        using 1:($1 > 60 ? $5 * 1e4 : 1/0) with points pt 6 title 'after the restart'
# endregion using
