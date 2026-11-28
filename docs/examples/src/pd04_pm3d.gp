#run pd04 foresight pd04_pm3d.gp
# region pm3d
# a colored, lit surface: pm3d quadrilaterals sorted by depth, the palette on the height, a light from the viewer
set terminal svg size 600,420
set output 'pd04.svg'
set view 55, 35
set pm3d depthorder lighting primary 0.5 specular 0.3
set palette viridis
set xlabel 'x'; set ylabel 'y'; set cblabel '{/Symbol f}'
set ticslevel 0
splot 'field.dat' using 1:2:3 with pm3d notitle
# endregion pm3d
