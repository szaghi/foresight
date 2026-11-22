set terminal svg size 560,320; set output 'cb_random.svg'
# gnuplot's own random numbers (the same as gnuplot's from the same seed): three walks printed into a datablock
x = rand(7)
set print $WALK
do for [w = 1:3] { y = 0; do for [i = 0:200] { y = y + (rand(0) < 0.5 ? -1 : 1); print i, y }; print ""; print "" }
set print
if (!exists("steps")) steps = 200
set xrange [0:steps]; set xlabel 'step'; set ylabel 'position'; set xzeroaxis; set key bottom left
plot $WALK index 0 w l lw 1.5 t 'walk 1', '' index 1 w l lw 1.5 t 'walk 2', '' index 2 w l lw 1.5 t 'walk 3'
