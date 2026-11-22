set terminal svg size 560,320; set output 'cb_offsets.svg'
# room around the data (set offsets) and the date of the plot in the corner (set timestamp)
$RUNS << EOD
1 4.2
2 5.1
3 4.7
4 6.3
5 5.9
EOD
set offsets 0.5, 0.5, 1, 1
set timestamp "plotted %Y-%m-%d" bottom
plot $RUNS w lp pt 7 lw 2 t 'runs'
