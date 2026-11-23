set terminal svg size 560,400; set output 'cb_multiplot_margins.svg'
# a layout whose plot areas line up: margins (screen fractions) and spacing between them
set multiplot layout 2,2 margins 0.1, 0.97, 0.1, 0.9 spacing 0.07, 0.1 title 'aligned plot areas'
unset key
plot sin(x)
plot cos(x)
plot sin(2*x) * 100
plot cos(2*x) * 100
unset multiplot
