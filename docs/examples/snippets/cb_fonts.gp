set terminal svg size 560,320; set output 'cb_fonts.svg'
# a font per text: sizes, weights, styles and families, as gnuplot's svg terminal
set title "Damped oscillation" font ",18"
set xlabel "time [s]" font ":Italic"
set ylabel "amplitude" font ":Bold"
set xtics font ",9"; set ytics font ",9"
set key font "serif:Italic,13"
set label 1 "first peak" at 1.6, 0.76 font "serif:Bold,13"
set samples 400; set xrange [0:12]
plot exp(-x/4)*sin(x) lw 2 title "e^{-t/4} sin t", exp(-x/4) dt 2 title "envelope"
