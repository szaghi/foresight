#run pe01 foresight pe01_both.gp
# region both
# one script for gnuplot and foresight: the terminal chosen by what the program has
if (strstrt(GPVAL_TERMINALS, 'html') > 0) {
   set terminal svg size 600,360    # foresight: html, svg, pdfcairo, cairolatex, dumb, block
   set output 'pe01.svg'
} else {
   set terminal pngcairo size 600,360           # gnuplot
   set output 'pe01.png'
}
set title 'Bessel functions'
set xlabel 'x'
set key top right
set samples 200
plot [0:20] besj0(x) title 'J_0(x)', besj1(x) title 'J_1(x)' dt 2, besy0(x) title 'Y_0(x)' dt 3
# endregion both
