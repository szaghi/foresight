set terminal svg size 760,320; set output 'cb_splines.svg'
set multiplot layout 1,2
set samples 200
set key bottom left
plot 'noisy.dat' u 1:2 w p pt 7 t 'signal', \
     ''          u 1:2 smooth csplines t 'csplines', \
     ''          u 1:2:(2) smooth acsplines t 'acsplines', \
     ''          u 1:2 smooth sbezier t 'sbezier'
set key top right
set xrange [-2:6]
plot 'noisy.dat' u 3:(1) smooth kdensity t 'kdensity', \
     ''          u 3:(1) smooth kdensity bandwidth 0.15 t 'bandwidth 0.15'
unset multiplot
