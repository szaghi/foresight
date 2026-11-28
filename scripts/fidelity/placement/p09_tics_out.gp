# Tick marks outside the border, scaled: the labels move out with them.
set tics out scale 2
set title 'Ticks out'
set xlabel 'x'
set ylabel 'y'
set xrange [0:10]; set yrange [0:100]
plot x**2 title 'square'
