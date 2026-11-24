set terminal svg size 560,360; set output 'cb_hulls.svg'
# convexhull, concavehull (a chi-shape) and expand D: curves bounding scattered points
set print $P
do for [i=1:80] {
    print sprintf("%.4f %.4f", 3*invnorm(rand(0)) + (i % 2)*6, 2*invnorm(rand(0)))
}
unset print
set key outside right; set size ratio -1
plot $P with points pt 7 ps 0.5 lc "gray" title "points", \
     $P convexhull with lines lw 2 title "convexhull", \
     $P concavehull with lines lw 2 title "concavehull", \
     $P convexhull expand 1 smooth path with lines dt 2 title "expand 1 smooth path"
