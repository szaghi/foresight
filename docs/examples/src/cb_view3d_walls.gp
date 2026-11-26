set terminal svg size 560,400; set output 'cb_view3d_walls.svg'
# a surface boxed by the grid walls (set wall), drawn behind or in front as they face
set wall z0 fs transparent solid 0.5 border -1 fc 'slategray'
set wall x0 fs transparent solid 0.5 border -1 fc 'forest-green'
set wall y0 fs transparent solid 0.5 border -1 fc 'bisque'
set xrange [0:1]; set yrange [0:1]
set xyplane at 0
set isosamples 25,25
set palette cubehelix
unset colorbox; unset key
set view 65, 145
set title 'set wall x0, y0, z0'
splot .1 + y*sin(20*(x-0.5))/(20*(x-0.5)) with pm3d
