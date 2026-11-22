set terminal svg size 560,320; set output 'cb_with_table.svg'
# the slow steps of a run as text (with table if ...), then plotted over the whole run
set table $SLOW
plot 'steptimes.dat' u 1:2 w table if $2 > 1.6
unset table
print $SLOW[1], ' ... ', |$SLOW|, ' slow steps'
set xlabel 'step'; set ylabel 'wall time [s]'; set yrange [1:2]; set key top left
plot 'steptimes.dat' u 1:2 w l t 'every step', $SLOW u 1:2 w p pt 7 t 'with table if $2 > 1.6'
