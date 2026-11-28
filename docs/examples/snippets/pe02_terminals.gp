# one plot, every output: each `set terminal` and `set output`, then `replot`
set title 'Damped oscillation'
set xlabel 't [s]'
set samples 300
set terminal svg size 600,320
set output 'pe02.svg'
plot [0:10] exp(-x/4)*cos(3*x) title 'response', exp(-x/4) title 'envelope' dt 2
set terminal html size 600,320
set output 'pe02.html'
replot
set terminal pdfcairo size 12cm,6.4cm
set output 'pe02.pdf'
replot
set terminal dumb size 70,20
set output 'pe02.txt'
replot
