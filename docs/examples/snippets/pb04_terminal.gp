# the convergence in a terminal: Braille dots, 2 x 4 per character cell, over ssh with nothing installed
set terminal block braille size 72,20
set logscale y
set format y '%.0e'
set key top right
plot 'run.dat' u 1:2 w l t 'continuity', '' u 1:3 w l t 'momentum'
