set terminal svg size 560,320; set output 'cb_key_columns.svg'
# a key of 3 rows a column, the titles in their series' colors, a styled box
set key top left box lt 4 lw 1.5 maxrows 3 spacing 1.2 tc variable
set xrange [0:4]
plot for [k=1:7] x**(k/3.) lw 2 t sprintf('x^{%d/3}', k)
