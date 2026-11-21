set terminal svg size 560,320; set output 'cb_identity.svg'
set title 'eight series on the grid'
set key outside; set grid; set xrange [0:6]
plot sin(x+0.4)+0.5 w lp pt 7 ps 0.6, sin(x+0.8)+1 w lp pt 7 ps 0.6, sin(x+1.2)+1.5 w lp pt 7 ps 0.6, \
     sin(x+1.6)+2 w lp pt 7 ps 0.6, sin(x+2)+2.5 w lp pt 7 ps 0.6, sin(x+2.4)+3 w lp pt 7 ps 0.6, \
     sin(x+2.8)+3.5 w lp pt 7 ps 0.6, sin(x+3.2)+4 w lp pt 7 ps 0.6
