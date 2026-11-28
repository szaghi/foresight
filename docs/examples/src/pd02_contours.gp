#run pd02 foresight pd02_contours.gp
# region contours
# the field's levels: filled contours under contour lines, in the map view
set terminal svg size 600,420
set output 'pd02.svg'
set view map
set size ratio -1
set contour base
set cntrparam levels discrete -0.2, 0.2, 0.4, 0.6, 0.8
set palette viridis
set cblabel '{/Symbol f}'
set title 'levels -0.2, 0.2, 0.4, 0.6, 0.8'
unset key
set xlabel 'x'; set ylabel 'y'
splot 'field.dat' using 1:2:3 with pm3d notitle, \
      'field.dat' using 1:2:3 with lines nosurface lc 'black' title 'levels'
# endregion contours
