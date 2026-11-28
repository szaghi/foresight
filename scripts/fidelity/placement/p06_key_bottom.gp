# A key of three rows at the bottom right, boxed.
set key bottom right box
set xrange [0:1]; set yrange [0:5]
plot 1+x title 'alpha', 2+x title 'beta', 3+x title 'gamma'
