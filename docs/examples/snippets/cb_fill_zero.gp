set terminal svg size 560,320; set output 'cb_fill_zero.svg'
# filledcurves above or below without a base fills against y = 0, as gnuplot
set samples 200; set xrange [0:4*pi]; set key bottom left
set style fill transparent solid 0.4 noborder
plot sin(x) * exp(-x/8) with filledcurves above lc "#0072b2" title "above", \
     sin(x) * exp(-x/8) with filledcurves below lc "#d55e00" title "below", \
     sin(x) * exp(-x/8) with lines lc "black" notitle
