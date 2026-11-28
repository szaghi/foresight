# The second axes: x2 and y2 labels and tick labels, with a title over them.
set title 'Both axes'
set xlabel 'x one'
set x2label 'x two'
set ylabel 'y one'
set y2label 'y two'
set xtics nomirror
set ytics nomirror
set x2tics
set y2tics
set xrange [0:4]; set x2range [0:40]
set yrange [0:1]; set y2range [0:100]
plot x/4 title 'line' axes x1y1
