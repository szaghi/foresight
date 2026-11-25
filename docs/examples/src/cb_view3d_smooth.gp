set terminal svg size 560,400; set output 'cb_view3d_smooth.svg'
# measured profiles at three depths smoothed in 3D: each scan a smoothing spline of its plane (gnuplot's 3D acsplines)
$P << EOD
0 0 1.0
0 1 1.9
0 2 1.4
0 3 2.6
0 4 2.1
0 5 2.4

1 0 0.8
1 1 1.5
1 2 1.6
1 3 2.2
1 4 2.4
1 5 2.0

2 0 0.5
2 1 1.2
2 2 1.0
2 3 1.8
2 4 1.7
2 5 1.9
EOD
set view 60, 30
set xyplane at 0
set xlabel 'depth'; set ylabel 'position'; set zlabel 'value'
set key below
splot $P using 1:2:3 with points pt 7 title 'measured', \
      $P using 1:2:3:(2) smooth acsplines lw 2 title 'acsplines, weight 2'
