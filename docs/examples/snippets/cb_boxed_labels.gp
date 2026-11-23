set terminal svg size 560,320; set output 'cb_boxed_labels.svg'
# boxed labels: the text on the background, over the line (gnuplot's svg textbox)
set style textbox opaque
$D << EOD
1 3.1
2 4.7
3 6.2
4 5.4
5 6.8
6 4.9
EOD
set xrange [0.5:6.5]; set yrange [2:8]
plot $D using 1:2 with lines lw 3 title 'series', '' using 1:2:2 with labels boxed notitle
