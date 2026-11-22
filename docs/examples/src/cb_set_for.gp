set terminal svg size 560,320; set output 'cb_set_for.svg'
# labels and arrows set in a loop (set for), the last label removed (unset for)
set for [i=1:5] label i sprintf('t_{%d}', i) at i, i**2 + 3 center
set for [i=1:5] arrow i from i, i**2 + 2.2 to i, i**2 + 0.4
unset for [i=5:5] label i
set xrange [0:6]; set yrange [0:32]; set key top left
plot x**2 lw 2 t 'x^2'
