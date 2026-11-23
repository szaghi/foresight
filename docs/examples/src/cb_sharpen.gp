set terminal svg size 560,320; set output 'cb_sharpen.svg'
# sharpen: the extrema of a function between its samples found and added
set samples 150; set xrange [-8:8]; set yrange [-0.1:1.2]; set key bottom right
plot abs(sqrt(sin(x))) + 0.15 title "sampled", abs(sqrt(sin(x))) sharpen title "sharpen"
