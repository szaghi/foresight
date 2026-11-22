set terminal svg size 560,320; set output 'cb_jitter.svg'
# a swarm plot: overlapping values of three groups spread out (set jitter)
set print $SCORES
do for [g = 1:3] { do for [i = 1:40] { print g, round(5*g + 3 + 2*invnorm(rand(0))) } }
set print
set jitter overlap 1 spread 0.6
set xrange [0.3:3.7]; set xtics ("A" 1, "B" 2, "C" 3); set ylabel 'score'
plot $SCORES u 1:2:1 w p pt 7 ps 0.7 lc variable notitle
