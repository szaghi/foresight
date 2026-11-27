#run cb_paper_double foresight cb_paper_double.gp && ls cb_paper_double.*
# region figure
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
# endregion figure
set terminal svg size 673,302
set output 'cb_paper_double.svg'
set multiplot layout 1,2
set title "(a) response"
unset ylabel
plot [0.1:10] 1/sqrt((1-x**2)**2 + (0.2*x)**2) title "ζ = 0.1"
set title "(b) phase"
set ylabel "φ [deg]"
plot [0.1:10] 180/pi*atan2(0.2*x, 1-x**2) title "ζ = 0.1"
unset multiplot
