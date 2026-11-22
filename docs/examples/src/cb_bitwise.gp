set terminal svg size 560,320; set output 'cb_bitwise.svg'
# solver status flags in one column, bit by bit: 1 converged step, 2 restart, 4 file written
$LOG << EOD
1 1.0e-1 0
2 3.2e-2 1
3 1.1e-2 1
4 2.5e-2 2
5 8.0e-3 1
6 2.4e-3 5
7 6.0e-3 2
8 1.6e-3 1
9 4.1e-4 5
10 1.0e-4 1
EOD
set logscale y; set format y '%.0e'; set xlabel 'step'; set key top right
plot $LOG u 1:2 w l t 'residual', \
     $LOG u 1:(int($3) & 2 ? $2 : 1/0) w p pt 6 ps 2 t 'restart (bit 2)', \
     $LOG u 1:(int($3) & 4 ? $2 : 1/0) w p pt 7 t 'file written (bit 4)'
