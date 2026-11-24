set terminal svg size 560,320; set output 'cb_latin1.svg'
# octal escapes write bytes; set encoding iso_8859_1 reads them as Latin-1; the Symbol font's upper half; \U+ code points
set encoding iso_8859_1
set label 1 "Temperatura: 21 \260C, caf\351" at graph 0.05, 0.88
set label 2 "{/Symbol \362}f(x) dx, x {/Symbol \256} {/Symbol \245}" at graph 0.05, 0.76
set label 3 "U+2192: a \U+2192 b" at graph 0.05, 0.64
plot [0:10] sin(x) / (x + 1) lw 2 title "sin(x)/(x+1)"
