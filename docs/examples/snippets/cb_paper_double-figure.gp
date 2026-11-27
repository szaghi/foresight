set terminal pdfcairo size double theme paper serif
set output 'cb_paper_double.pdf'
set multiplot layout 1,2
set title "(a) response"
set xlabel "{/serif ω / ω_n}"
set logscale x
plot [0.1:10] 1/sqrt((1-x**2)**2 + (0.2*x)**2) title "ζ = 0.1"
set title "(b) phase"
set ylabel "φ [deg]"
plot [0.1:10] 180/pi*atan2(0.2*x, 1-x**2) title "ζ = 0.1"
unset multiplot
