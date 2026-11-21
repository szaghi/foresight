set terminal svg size 560,340; set output 'cb_x2_rotate.svg'
set xrange [0:100]; set xtics nomirror; set xlabel 'frequency [Hz]'
# the same axis read as periods on top: named ticks, rotated to fit
set x2range [0:100]
set x2tics ("40 ms" 25, "20 ms" 50, "13.3 ms" 75, "10 ms" 100) rotate by 45 out
set x2label 'period'
plot 'spectrum.dat' w impulses lw 2 t 'lift spectrum'
