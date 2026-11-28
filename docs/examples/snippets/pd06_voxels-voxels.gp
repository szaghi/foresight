# a 3D scalar field on a voxel grid: filled around a helix, then the surface where it reaches a level
set terminal svg size 600,420 theme paper
set output 'pd06.svg'
set vgrid $helix size 25
set vxrange [-2:2]; set vyrange [-2:2]; set vzrange [0:11]
set xrange [-2:2]; set yrange [-2:2]; set zrange [0:11]
vfill sample [t=0:20] '+' using (cos($1)):(sin($1)):($1):(0.9):(10.0)
set view 60, 30
set xyplane at 0
set style fill transparent solid 0.35
set pm3d depthorder border lc 'black' lw 0.3
set key off
splot $helix with isosurface level 1.0 lc 'sea-green'
