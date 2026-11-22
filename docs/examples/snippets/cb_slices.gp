set terminal svg size 560,320; set output 'cb_slices.svg'
# twelve monthly values, the quarters as slices: printed, sized, averaged
array M = [3.1, 3.4, 4.0, 5.2, 6.8, 8.1, 8.9, 8.6, 7.2, 5.6, 4.1, 3.3]
array Q[4]
do for [q = 1:4] { S = M[3*q - 2:3*q]; Q[q] = (S[1] + S[2] + S[3]) / |S| }
print M[1:3], M[10:]
set xrange [0:13]; set xlabel 'month'; set key top left
set title sprintf('%d months, summer mean %.2f', |M|, Q[3])
plot M w lp pt 7 t 'month', Q u (3*$1 - 1):2 w p pt 5 ps 2 t 'quarter mean'
