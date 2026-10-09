set terminal svg size 560,320; set output 'cb_boxxyerror.svg'
set style fill transparent solid 0.25
plot 'partition.dat' u 1:2:3:4:5:6 w boxxyerror t 'blocks', '' u 1:2 w p pt 7 t 'centres'
