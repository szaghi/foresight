set terminal svg size 560,320; set output 'cb_fill_borders.svg'
# fills across: to the left border (y1), to the right one (y2), to the vertical line x = 5
$HIGH << EOD
2 7.2
3 7.8
4 7.0
5 8.1
EOD
$MID << EOD
5 4.0
6 4.6
7 4.2
8 5.0
EOD
$LOW << EOD
1 1.0
3 2.2
5 1.6
7 2.6
9 1.8
EOD
set xrange [0:10]; set yrange [0:9]; set key top center horizontal
plot $HIGH w filledcurves y1 fs solid 0.6 t 'y1', $MID w filledcurves y2 fs solid 0.6 t 'y2', \
     $LOW w filledcurves x=5 fs pattern 4 t 'x=5', $LOW w lp pt 7 lc 'black' notitle
