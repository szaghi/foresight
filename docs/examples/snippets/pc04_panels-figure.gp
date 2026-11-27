set terminal pdfcairo size double theme paper serif
set output 'pc04.pdf'
set multiplot layout 1,3 title "Second-order response"
set logscale x
set xlabel "ω / ω_n"
set title "(a) gain"
plot [0.1:10] for [z in "0.1 0.3 1"] 1/sqrt((1-x**2)**2 + (2*z*x)**2) title "ζ = ".z
set title "(b) phase"
plot [0.1:10] for [z in "0.1 0.3 1"] 180/pi*atan2(2*z*x, 1-x**2) title "ζ = ".z
unset logscale x
set title "(c) step"
set xlabel "ω_n t"
plot [0:20] for [z in "0.1 0.3"] 1 - exp(-z*x)*cos(sqrt(1-z**2)*x) title "ζ = ".z
unset multiplot
