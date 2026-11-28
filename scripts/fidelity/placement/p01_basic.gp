#! fonts: system
#! margins: 0.15 0.90 0.15 0.88
# The figure of issue #6's measure: title, both axis labels, tick labels, a two-row key, a label at data coordinates.
set title 'Damped oscillation'
set xlabel 'time'
set ylabel 'amplitude'
set key top right
set label 1 'peak' at 1.0, 0.6
set xrange [0:10]; set yrange [-1:1]
set samples 200
plot exp(-x/4)*cos(3*x) title 'response', exp(-x/4) title 'envelope'
