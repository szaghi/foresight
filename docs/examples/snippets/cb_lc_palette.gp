set terminal svg size 560,320; set output 'cb_lc_palette.svg'
set datafile separator comma   # run.csv: iteration, continuity, momentum, energy, cd, dcd
set palette viridis; set cblabel 'iteration'
set logscale y; set xlabel 'cd'; set ylabel 'residual'
# the path of the run in (cd, residual), colored by the iteration; a second residual in one palette color
plot 'run.csv' u 5:2:1 w lp pt 7 ps 0.6 lc palette z t 'continuity', \
     ''        u 5:3 w l lw 2 lc palette frac 0.9 t 'momentum'
