set terminal svg size 760,320; set output 'cb_colorsequence.svg'
set multiplot layout 1,2
set key off; set xrange [0:6]
set title 'set colorsequence podo'; set colorsequence podo
plot sin(x), sin(x+1)+1, sin(x+2)+2, sin(x+3)+3, sin(x+4)+4, sin(x+5)+5
set title 'set colorsequence batlowS 6'; set colorsequence batlowS 6
plot sin(x), sin(x+1)+1, sin(x+2)+2, sin(x+3)+3, sin(x+4)+4, sin(x+5)+5
unset multiplot
