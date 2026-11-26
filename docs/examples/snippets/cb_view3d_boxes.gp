set terminal svg size 560,400; set output 'cb_view3d_boxes.svg'
# bars in 3D: splot with boxes, a depth (set boxdepth), lit and sorted by depth
$D << EOD
1 3 2 4
2 5 3 6
3 4 6 5
4 6 4 3
EOD
set boxwidth 0.4 absolute
set boxdepth 0.4
set style fill solid border lc 'black'
set pm3d depthorder base border lc 'black'
set pm3d lighting primary 0.5 specular 0.2
set xyplane at 0
set xrange [0:5]; set yrange [0:4]
set xtics 1; set ytics 1,1,3
set grid z vertical
set view 59, 24
unset key
set title 'splot with boxes, set boxdepth 0.4'
splot for [k=1:3] $D using 1:(k):k+1:(k == 1 ? 0x0072b2 : k == 2 ? 0xe69f00 : 0x009e73) with boxes fc rgb variable
