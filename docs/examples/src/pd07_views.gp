#run pd07 foresight pd07_views.gp
# region views
# a surface to turn with the mouse: the HTML page redraws it from the plot's data at each angle
set terminal html size 640,440
set output 'pd07.html'
set view 60, 30
set pm3d depthorder
set palette viridis
set isosamples 30, 30
set xrange [-3:3]; set yrange [-3:3]
set xlabel 'x'; set ylabel 'y'
splot exp(-(x**2 + y**2)/4)*cos(2*x) with pm3d title 'exp(-r^2/4) cos 2x'
# endregion views
