set terminal svg size 640,300; set output 'cb_tics_axis.svg'
# ticks on the axes through the origin; a range frame: ticks and border sides within the data range
$RUNS << EOD
0.5 1.1
1.5 1.9
2.5 2.1
3.5 3.0
4.5 3.2
EOD
set multiplot layout 1,2
set xtics axis; set ytics axis; set key top left
plot [-6:6] [-1.2:3.2] 3*sin(x)/x t '3 sinc(x)'
set xtics border nomirror rangelimited; set ytics border nomirror rangelimited; set border 3
plot [0:5] [0:4] $RUNS w lp pt 7 lw 2 t 'runs'
unset multiplot
