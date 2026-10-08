#run cb_dumb foresight cb_dumb.gp
set terminal dumb size 64,18
plot 'run.dat' u 1:5 t 'cd'
