set terminal svg size 560,400; set output 'cb_view3d_arrows.svg'
# a helix with its axes drawn as arrows, their names at the tips: annotations at x,y,z positions in a 3D view
set view equal xy
set view 60, 30, 1, 1.75
set xyplane at 0
unset border; unset key; unset xtics; unset ytics
set ztics axis
set arrow 1 from 0,0,0 to 1,0,0 head filled lw 1.5
set label 1 'x' at 1.2,0,0 center
set arrow 2 from 0,0,0 to 0,1,0 head filled lw 1.5
set label 2 'y' at 0,1.2,0 center
set arrow 3 from 0,0,0 to 0,0,21 head filled lw 1.5
set label 3 'z' at 0,0,23 center
splot sample [t=0:20] '+' using (cos($1)):(sin($1)):($1) with lines lw 2
