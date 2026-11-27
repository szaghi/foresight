set terminal svg size 560,400; set output 'cb_view3d_isosurface.svg'
# a voxel grid filled around a helix, its points and the surface enclosing them
set vgrid $helix size 25
set vxrange [-2:2]; set vyrange [-2:2]; set vzrange [0:11]
set xrange [-2:2]; set yrange [-2:2]; set zrange [0:11]
vfill sample [t=0:20] '+' using (cos($1)):(sin($1)):($1):(0.9):(10.0)
set view 60, 30, 1.6
set xyplane at 0
set style fill transparent solid 0.3
set pm3d depthorder border lc 'blue' lw 0.4
set key off
set title 'isosurface of a voxel grid (vfill, with isosurface)'
splot $helix with isosurface level 1.0 lt 3
