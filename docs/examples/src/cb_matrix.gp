set terminal svg size 560,400; set output 'cb_matrix.svg'
set palette viridis maxcolors 10
set xlabel 'sweep'; set ylabel 'block'; set cblabel 'residual'
plot 'blocks.dat' matrix w image notitle
