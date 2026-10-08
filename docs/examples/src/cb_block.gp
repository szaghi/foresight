#run cb_block foresight cb_block.gp
set terminal block braille size 64,18
plot 'run.dat' u 1:5 t 'cd'
