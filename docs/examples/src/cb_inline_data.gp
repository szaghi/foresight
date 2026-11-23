set terminal svg size 560,320; set output 'cb_inline_data.svg'
# inline data '-': the lines after the plot, up to one starting with e, one block per '-' item
set key top left
plot '-' using 1:2 with linespoints pt 7 t 'first block', '-' with points pt 5 ps 1.4 t 'second block'
1 1.0
2 2.5
3 2.9
4 4.2
e
1.5 2.0
3.5 3.1
e
