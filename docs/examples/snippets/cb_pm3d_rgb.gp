set terminal svg size 560,400; set output 'cb_pm3d_rgb.svg'
# a map colored by RGB values computed per point (pm3d lc rgb variable), each tile outlined
rgb(r, g, b) = int(255*r)*65536 + int(255*g)*256 + int(255*b)
set view map
set size ratio -1
set samples 16; set isosamples 16   # the '++' grid: 16 x 16 points of the u and v ranges
set urange [0:1]; set vrange [0:1]
set pm3d border lc 'white' lw 0.5
unset colorbox
set title 'red along x, blue along y'
splot '++' using 1:2:(0):(rgb($1, 0.3, $2)) with pm3d lc rgb variable notitle
