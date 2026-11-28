#run pd03 foresight pd03_surface.gp
# region surface
# the same field as a surface: a mesh of its grid lines, hidden lines removed
set terminal svg size 600,420 theme paper
set output 'pd03.svg'
set view 55, 35
set hidden3d
set xlabel 'x'; set ylabel 'y'; set zlabel '{/Symbol f}'
set ticslevel 0
splot 'field.dat' using 1:2:3 with lines title '{/Symbol f}(x,y)'
# endregion surface
