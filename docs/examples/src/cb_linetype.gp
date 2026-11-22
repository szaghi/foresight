set terminal svg size 560,320; set output 'cb_linetype.svg'
# the linetypes redefined: every plot after it takes these colors, widths and points; the points larger
set linetype 1 lc "dark-violet" lw 2 pt 7
set linetype 2 lc "sea-green" lw 2 pt 9
set linetype 3 lc "dark-orange" lw 2 pt 5 dt 2
set pointsize 1.3; set key top left
plot [0:5] for [k = 1:3] x**(k/2.) w lp pi 8 t sprintf('x^{%d/2}', k)
