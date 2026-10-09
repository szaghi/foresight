set terminal svg size 560,320; set output 'cb_steps.svg'
set xlabel 'iteration'; set ylabel 'dt [ms]'; set key bottom right
plot 'timestep.dat' u 1:2 w steps lw 2 t 'steps', '' u 1:2 w fsteps t 'fsteps', '' u 1:($2+1) w histeps t 'histeps + 1'
