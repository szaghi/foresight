set title "Residual history"
set xlabel "iteration"
set ylabel "residual"
set logscale y
set format y "10^{%L}"
set output 'pc01.pdf'
plot [1:200] exp(-x/30) title "Jacobi", exp(-x/12) dt 2 title "multigrid"
set terminal svg size 600,480
set output 'pc01.svg'
replot
