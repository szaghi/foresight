#run pe03 foresight pe03_extensions.gp
# region extensions
# foresight's extensions, kept out of gnuplot's way: gnuplot reads the else branches
$P << EOD
1 3.00
2 2.61
3 2.43
4 2.37
5 2.35
EOD
set title 'pressure'
set xlabel 'iteration'
if (strstrt(GPVAL_TERMINALS, 'html') > 0) {
   set terminal svg size 600,320 theme vfd       # a theme: the colors of a 1980s car dashboard
   set output 'pe03.svg'
   set caption 'The pressure of the run.'        # for a report (save's info), not drawn
   set readout vertical top right
   unset key
   plot $P using 1:2 with lines title 'p', '' using 2 with readout format '%5.2f' title 'P'
} else {
   set terminal pngcairo size 600,320
   set output 'pe03.png'
   plot $P using 1:2 with lines title 'p'
}
# endregion extensions
