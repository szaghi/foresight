set terminal svg size 560,360; set output 'cb_paxis_ranges.svg'
# parallel axes: a range, tics and a reversed axis each, every line in the color of a group column
$RUNS << EOD
1.2 300 0.010 2 1
2.5 150 0.004 5 2
4.0 120 0.002 9 3
3.1 200 0.006 6 2
EOD
set style data parallelaxes
set paxis 1 range [0:5]; set paxis 2 range [350:100]; set paxis 3 range [0:0.012]
set paxis 4 range [0:10]; set for [i = 1:4] paxis i tics
plot $RUNS using 1:5 lc variable lw 2 t 'CFL', '' using 2 t 'cells', '' using 3 t 'error', '' using 4 t 'speedup'
