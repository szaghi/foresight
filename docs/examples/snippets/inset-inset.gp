set multiplot title 'Drag coefficient'
plot 'run.dat' u 1:5 w l t 'cd'
set origin 0.45,0.12; set size 0.5,0.45
unset key; set xrange [80:120]
plot 'run.dat' u 1:5:6 every 2 with yerrorbars pt 7 ps 0.5
unset multiplot
