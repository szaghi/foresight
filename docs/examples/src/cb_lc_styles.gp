set terminal svg size 560,320; set output 'cb_lc_styles.svg'
# lc variable on candlesticks: the last column picks the linetype, 2 (green) up, 7 (red) down
$P << EOD
1 10 8 14 12 2
2 12 11 16 15 2
3 15 12 17 13 7
4 13 9 14 10 7
5 10 7 12 11 2
EOD
set boxwidth 0.4; set style fill solid 0.7 border lc 'black'
set xrange [0:6]; set yrange [5:19]
plot $P using 1:2:3:4:5:6 with candlesticks lc variable title 'open, low, high, close'
