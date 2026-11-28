# a velocity field (flow.dat: x y u v) as arrows, the cylinder drawn as an object
set terminal svg size 600,420 theme paper
set output 'pd05.svg'
set size ratio -1
set xrange [-3.5:3.5]; set yrange [-2.6:2.6]
set object 1 circle at 0,0 size 1 fc 'gray' fs solid 0.5 noborder
set xlabel 'x'; set ylabel 'y'
set key below
plot 'flow.dat' using 1:2:(2*$3):(2*$4) with vectors filled head lw 1.2 title 'velocity'
