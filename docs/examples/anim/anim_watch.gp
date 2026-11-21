# frames 12 0.7
# a run watched: the log grows by 20 iterations a frame (foresight -c anim_watch.gp K)
k = ARG1 + 0
last = sprintf('%d', 20*k - 1)
set terminal svg size 640,380; set output sprintf('frames/anim_watch_%02d.svg', k)
set title 'a watched run'
set xdata time; set timefmt '%Y-%m-%d %H:%M:%S'; set format x '%H:%M'
set xrange ['2024-03-01 09:40:00':'2024-03-01 13:00:00']
set logscale y; set yrange [1e-5:1]; set format y '%h'
set ytics nomirror; set y2range [0.24:0.36]; set y2tics 0.02
set xlabel 'wall clock'; set ylabel 'residual'; set y2label 'cd'
set key bottom left
set readout top right vertical
plot 'live.dat' u 1:4 every ::0::@last w l lw 2 t 'residual', \
     '' u 1:5 every ::0::@last axes x1y2 w l lw 2 t 'cd', \
     '' u 1:3 every ::0::@last w readout format '%4.0f' t 'iteration'
