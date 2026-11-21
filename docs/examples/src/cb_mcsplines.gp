set terminal svg size 560,320; set output 'cb_mcsplines.svg'
set xlabel 'iteration'; set ylabel 'dt [ms]'; set key top left
set yrange [0:5]
plot 'timestep.dat' w p pt 7 t 'time step', \
     ''             smooth csplines dt 2 t 'csplines', \
     ''             smooth mcsplines lw 2 t 'mcsplines'
