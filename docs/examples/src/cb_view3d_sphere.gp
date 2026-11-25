set terminal svg size 560,420; set output 'cb_view3d_sphere.svg'
# longitude and latitude on a sphere: set mapping spherical reads splot's data as theta:phi[:r]
set angles degrees
set mapping spherical
set view equal xyz
set view 60, 30, 1.3
set xyplane at -1
set urange [0:360]; set vrange [-90:90]
set isosamples 25, 13
unset key
$cities << EOD
12.5 41.9 1 Rome
-74.0 40.7 1 "New York"
139.7 35.7 1 Tokyo
151.2 -33.9 1 Sydney
EOD
splot '++' using 1:2:(1) with lines lc 'gray', $cities using 1:2:3:4 with labels point pt 7 left offset 1,0
