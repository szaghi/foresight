set terminal svg size 560,320; set output 'cb_dashes.svg'
# custom dash types: a dash string of . - _ and blanks, or the lengths (solid, empty, ...); lc bgnd hides a line
set yrange [0:6]; set key outside right
plot 1 lw 2 dt "-" title 'dt "-"', 2 lw 2 dt "." title 'dt "."', 3 lw 2 dt "._" title 'dt "._"', \
     4 lw 2 dt "..- " title 'dt "..- "', 5 lw 2 dt (20,5,2,5) title 'dt (20,5,2,5)'
