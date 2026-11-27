#run cb_paper foresight cb_paper.gp && ls cb_paper.*
# region figure
set terminal pdfcairo size single theme paper
set output 'cb_paper.pdf'
set xlabel "time [s]"
set ylabel "amplitude"
set key top right
plot [0:10] exp(-x/4)*cos(3*x) title "damped", exp(-x/4) dt 2 title "envelope"
# endregion figure
set terminal svg size 321,227
set output 'cb_paper.svg'
replot
