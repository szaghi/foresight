set terminal svg size 560,400; set output 'cb_geographic.svg'
# a great-circle route labelled in degrees and compass letters (set xtics geographic)
set xrange [-180:180]; set yrange [-90:90]
set xtics 60 geographic; set format x "%D°%E"
set ytics 30; set format y "%D°%N" geographic
set grid
set size ratio 0.5
set title 'Lisbon to Tokyo'
lon(t) = -9.14 + t*(139.69 + 9.14)
lat(t) = 38.72 + (35.68 - 38.72)*t + 30*sin(pi*t)
set samples 100
plot sample [t=0:1] '+' using (lon($1)):(lat($1)) with lines lw 2 notitle, \
     '-' using 1:2:3 with labels point pt 7 offset 1,1 notitle
-9.14 38.72 Lisbon
139.69 35.68 Tokyo
e
