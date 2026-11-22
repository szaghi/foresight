set terminal svg size 560,320; set output 'cb_clip.svg'
# clipping: by default, as gnuplot, a segment with both ends out of the plot is not drawn (no line down the asymptotes)
set multiplot layout 1,2
set yrange [-4:4]; set samples 60; set title 'default (unset clip two)'
plot [-2*pi:2*pi] tan(x) notitle
set clip two; set title 'set clip two'
replot
unset multiplot
