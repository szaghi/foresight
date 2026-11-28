# Axis labels of two lines on the four axes: one text per line, as gnuplot writes them.
set xlabel "distance\n(km)"
set ylabel "height\n(m)"
set x2label "upper\nscale"
set y2label "right\nside"
set xrange [0:5]; set yrange [0:20]
plot x**2 title 'square'
