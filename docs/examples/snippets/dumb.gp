# Tutorial 8: the same plot as text, for a terminal over ssh.
set terminal dumb size 72,22
set logscale y
plot 'run.dat' u 1:2 t 'continuity', '' u 1:3 t 'momentum'
