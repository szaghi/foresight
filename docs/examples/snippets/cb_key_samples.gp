set terminal svg size 560,320; set output 'cb_key_samples.svg'
# key samples as gnuplot 6.0: an arrow for vectors, none for a keyentry of labels, the fill border around a fill
$V << EOD
1 1 1 0.5
2 2 1 -0.4
4 1 -1 0.6
EOD
set key title 'samples' left box; set style fill solid 0.3 border lc 'black'; set xrange [0:6]; set yrange [0:3.5]
plot $V using 1:2:3:4 with vectors lw 2 t 'vectors', $V using 1:2 with filledcurves y=0 t 'filledcurves', \
     keyentry with labels t 'labels (no sample)'
