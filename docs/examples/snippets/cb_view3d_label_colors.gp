set terminal svg size 560,400; set output 'cb_view3d_label_colors.svg'
# labels colored by their height on the palette (tc palette z): the color axis spans z
set xrange [-3:3]; set yrange [-3:3]; set zrange [-1:1]
set isosamples 30, 30
set view 60, 30
set palette rgbformulae 33,13,10
do for [k=-2:2] {
  set label k+3 sprintf('z = %4.1f', 0.5*k) at -3, 3.4, 0.5*k right tc palette z
}
set title 'heights in palette colors'
splot exp(-(x*x + y*y)/2)*cos(2*x) lc 'gray50' notitle
