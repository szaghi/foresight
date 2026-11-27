#run pc03 foresight pc03_paper.gp && ls pc03*.pdf
# region gnuplot
# gnuplot's own pdfcairo defaults: 5 x 3 in, "Sans,12" at fontscale 0.5, lines of 0.5 pt
set terminal pdfcairo
set output 'pc03_default.pdf'
set xlabel "x"
set ylabel "y"
plot [0:2*pi] sin(x) title "sin(x)", cos(x) title "cos(x)"
# endregion gnuplot
# region column
# a column of a journal: 8.5 x 6 cm, 8 pt texts, 0.75 pt lines, the Okabe-Ito colors
set terminal pdfcairo size single theme paper
set output 'pc03.pdf'
replot
# endregion column
# region units
# any size with its units, and gnuplot's line and font options
set terminal pdfcairo size 3.5in,2.5in font ",9" linewidth 1.5 dashlength 2 rounded
set output 'pc03_units.pdf'
replot
# endregion units
set terminal svg size 321,227 theme paper
set output 'pc03.svg'
replot
