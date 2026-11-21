set terminal svg size 560,320; set output 'cb_lc_variable.svg'
set key top left
plot 'classes.dat' u 1:2:3 w p pt 7 ps 1.5 lc variable t 'runs, colored by class', \
     ''            u 1:2:(1+($2 > 3)) w l lc variable t 'segments above 3 in green'
