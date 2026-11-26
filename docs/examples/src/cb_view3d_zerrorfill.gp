set terminal svg size 560,400; set output 'cb_view3d_zerrorfill.svg'
# curves in 3D with their error bands (splot with zerrorfill), the far ones first
$D << EOD
0 0.0 0.3
1 0.8 0.3
2 1.2 0.4
3 1.0 0.3
4 1.6 0.5
5 2.1 0.4
6 1.9 0.5
EOD
set view 60, 25
set xyplane 0
set yrange [0.5:3.5]
set grid x y z vertical
set key top left
set title 'splot with zerrorfill'
splot for [k=3:1:-1] $D using 1:(k):($2*k):($3*k/2) with zerrorfill lt black fc lt k title sprintf('run %d', k)
