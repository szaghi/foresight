set terminal svg size 560,320; set output 'cb_gantt.svg'
# a Gantt chart: vectors from start to end, the task names as y tick labels, the title placed in graph coordinates
$TASKS << EOD
mesh     0  3
solver   2  9
post     8 11
report  10 12
EOD
set xrange [0:13]; set yrange [4.5:0.5]; set xlabel 'week'; set grid x
set key noautotitle
plot $TASKS using 2 : ($0 + 1) : ($3 - $2) : (0) : ytic(1) with vectors nohead lw 12 lc "steelblue", \
     keyentry title 'schedule' at graph 0.98, graph 0.92
