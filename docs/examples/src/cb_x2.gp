set terminal svg size 560,320; set output 'cb_x2.svg'
set xrange [0:100]; set xtics nomirror; set xlabel 'frequency [Hz]'
set x2range [0:2]; set x2tics 0.25; set x2label 'Strouhal number fD/U (D = 0.1 m, U = 5 m/s)'
plot 'spectrum.dat' w impulses lw 2 t 'lift spectrum'
