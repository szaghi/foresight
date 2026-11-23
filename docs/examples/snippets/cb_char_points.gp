set terminal svg size 560,320; set output 'cb_char_points.svg'
# a character as the point (pt "c"), in its tc color, every 4 points (pi) or about 8 of them (pn)
set encoding utf8
set samples 41; set xrange [0:2*pi]; set key bottom left
plot '+' using 1:(sin(x)) with linespoints pt "◆" pi 4 tc rgb '#d55e00' lw 2 title 'pt "◆" pi 4', \
     '+' using 1:(cos(x)) with linespoints pt "x" pn 8 lw 2 title 'pt "x" pn 8'
