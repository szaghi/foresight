# a panel of the run: column ARG1 of run.dat, titled ARG2 (called by cb_call.gp)
set title ARG2
set logscale y
plot 'run.dat' u 1:(column(ARG1 + 0)) w l lw 2 t ARG2
