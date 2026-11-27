# gnuplot's own pdfcairo defaults: 5 x 3 in, "Sans,12" at fontscale 0.5, lines of 0.5 pt
set terminal pdfcairo
set output 'pc03_default.pdf'
set xlabel "x"
set ylabel "y"
plot [0:2*pi] sin(x) title "sin(x)", cos(x) title "cos(x)"
