set terminal svg size 560,400; set output 'cb_view3d_polygons.svg'
# a solid from its faces: splot with polygons, depth sorted and lit
$CUBE << EOD
0 0 0
1 0 0
1 1 0
0 1 0

0 0 1
1 0 1
1 1 1
0 1 1

0 0 0
1 0 0
1 0 1
0 0 1

0 1 0
1 1 0
1 1 1
0 1 1

0 0 0
0 1 0
0 1 1
0 0 1

1 0 0
1 1 0
1 1 1
1 0 1
EOD
set view equal xyz
set view 60, 35, 1.4
set xrange [-0.5:1.5]; set yrange [-0.5:1.5]; set zrange [-0.5:1.5]
unset border; unset tics; unset key
set pm3d depthorder border lc 'black' lw 1.5
set pm3d lighting primary 0.6 specular 0.3
set style fill transparent solid 0.8
set title 'splot with polygons, set pm3d depthorder lighting'
splot $CUBE with polygons fc 'steelblue'
