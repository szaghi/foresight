#! font: 16
# Every text at a large terminal font.
set title 'Large font'
set xlabel 'time'
set ylabel 'value'
set xrange [0:10]; set yrange [-1:1]
plot sin(x) title 'sine', cos(x) title 'cosine'
