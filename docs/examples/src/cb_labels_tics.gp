set terminal svg size 560,320; set output 'cb_labels_tics.svg'
# labels with their own tic labels: the text at each point, the x tics named by a column, times on y
$EVENTS << EOD
1390852607.100	start
1390852607.400	mesh
1390852608.400	solve
1390852610.001	write
EOD
set ydata time; set timefmt "%s"; set format y "%H:%M:%.3S"
set offset 0.5, 1.5, 0.2, 0.2; unset key
plot $EVENTS using 0:1:(strftime("%.3S s", column(1))):xticlabels(2) with labels point pt 7 left offset 1,0.5
