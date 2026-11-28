# Offsets in character units on the title and the axis labels.
set title 'Offset title' offset 0,-1
set xlabel 'offset x' offset 2,1
set ylabel 'offset y' offset -1,0
set xrange [0:10]; set yrange [0:10]
plot x title 'line'
