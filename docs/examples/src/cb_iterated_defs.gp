set terminal svg size 560,320; set output 'cb_iterated_defs.svg'
# definitions before an iterated item run on each pass: a family of curves from two arrays
array rate[4] = [0.5, 1, 2, 4]
array shape[4] = [1, 1.3, 2, 3]
weibull(x, k, l) = 1 - exp(-(x/l)**k)
set xrange [0:5]; set key bottom right
plot for [i = 1:4] k = shape[i], l = 1.0/rate[i], weibull(x, k, l) lw 2 title sprintf("k = %.1f, rate %.1f", k, rate[i])
