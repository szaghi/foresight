set terminal svg size 560,320; set output 'cb_strcol.svg'
# the text of column 1 names the bars and labels them with the speedup; one solver chosen by its name
set style fill solid 0.6 border -1; set yrange [0:5]; set key top left
plot 'runs.dat' u 0:4:xtic(strcol(1) . "\n" . sprintf('%.0e', $2)) w boxes t 'speedup', \
     '' u 0:($4 + 0.25):(sprintf('%.0f s', $3)) w labels notitle, \
     '' u 0:(strcol(1) eq 'multigrid' ? $4 : 1/0) w p pt 7 ps 2 t 'multigrid'
