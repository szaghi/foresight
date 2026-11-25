set terminal svg size 560,320; set output 'cb_ytics_rotate.svg'
# long y tick labels read upward (rotate), the y2 ones turned by 45 degrees: narrower margins
set ytics 500 rotate format "%.0f MB/s" nomirror
set y2tics 3 rotate by 45 format "%.1f s"
set xrange [1:64]
set yrange [0:1600]; set y2range [0:12]
set key top left
plot 25*x title 'bandwidth' lw 2, 12/sqrt(x) axes x1y2 title 'latency' lw 2
