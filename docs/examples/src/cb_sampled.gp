set terminal svg size 560,400; set output 'cb_sampled.svg'
# the '+' and '++' pseudo-files: sampled variables through using, a field of vectors and a sampled ellipse
set urange [-2:2]; set vrange [-2:2]; set samples 11; set isosamples 11
set xrange [-2.5:2.5]; set yrange [-2.5:2.5]; set size ratio 1
plot '++' using 1:2:($2*0.15):(-$1*0.15):(sqrt($1**2 + $2**2)) with vectors filled lc palette z notitle, \
     [t=0:2*pi:pi/20] '+' using (2*cos(t)):(1.2*sin(t)) with lines lw 2 title "[t=0:2π] '+'"
