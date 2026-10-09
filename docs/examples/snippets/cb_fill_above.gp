set terminal svg size 560,320; set output 'cb_fill_above.svg'
set style fill solid 0.35; set xlabel 'iteration'; set ylabel 'cd'
plot 'run.dat' u 1:5 w filledcurves above y=0.35 t 'above 0.35', \
     ''        u 1:5 w filledcurves below y=0.35 t 'below 0.35', \
     ''        u 1:5 w l lc 'black' t 'cd'
