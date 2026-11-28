# Tick labels rotated by 45 degrees on x, and the x label below them.
set xlabel 'category'
set ylabel 'number'
set xtics rotate by 45 right
set xrange [0:6]; set yrange [0:30]
plot 5*x title 'count'
