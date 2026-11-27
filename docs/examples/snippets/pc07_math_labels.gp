# labels with TeX math: $...$ set as LaTeX sets it (Latin Modern Math), on every device
set terminal svg size 600,400
set output 'pc07.svg'
set title 'Damped response $x(t) = e^{-t/\tau}\cos\omega t$'
set xlabel '$t/\tau$'
set ylabel '$x/x_0$'
set label 1 '$\omega = \sqrt{k/m}$,  $\zeta = \frac{c}{2\sqrt{km}}$' at 1.3,-0.45
plot [0:4] exp(-x)*cos(2*pi*x) title '$e^{-t/\tau}\cos\omega t$', exp(-x) title '$e^{-t/\tau}$' dt 2
# the same figure for a paper: the PDF embeds the math glyphs as it embeds the text's
set terminal pdfcairo size single theme paper serif
set output 'pc07.pdf'
replot
