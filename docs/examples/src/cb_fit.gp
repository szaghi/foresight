#run cb_fit foresight cb_fit.gp
set terminal svg size 560,320; set output 'cb_fit.svg'
# the observed order of accuracy: fit error = c h^p, the report on the terminal
f(h) = c*h**p
c = 1; p = 1
set fit results
fit f(x) 'convergence.dat' using 1:2 via c, p
set logscale xy; set format y '%.0e'
set xlabel 'mesh size h'; set ylabel 'error'; set key top left
plot 'convergence.dat' w p pt 7 ps 1.2 t 'measured', f(x) lw 2 t sprintf('fit c h^p, p = %.2f', p)
