# A key of four rows at the top left, with a key title.
set key top left title 'Series'
set xrange [0:1]; set yrange [0:5]
plot x title 'one', 2*x title 'two', 3*x title 'three', 4*x title 'four'
