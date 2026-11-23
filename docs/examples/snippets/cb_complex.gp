set terminal svg size 560,320; set output 'cb_complex.svg'
# a transfer function of complex values, {0,1} written I: its gain and its phase, as gnuplot plots them
A(w) = (I*w / (I*w + 100)) * (1 / (1 + I*w / 2e4))
set logscale x; set xrange [1:1e6]; set samples 400
set ylabel 'gain [dB]'; set y2label 'phase [deg]'
set ytics nomirror; set y2tics; set yrange [-45:5]; set y2range [-90:90]
set key bottom center
plot 20*log10(abs(A(x))) lw 2 title 'gain', 180/pi*arg(A(x)) axes x1y2 lw 2 title 'phase'
