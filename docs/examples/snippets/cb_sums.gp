set terminal svg size 560,320; set output 'cb_sums.svg'
# partial sums of a Fourier series: sum [k=a:b] in a function, its order n set by assignments in the plot itself
square(x) = 4/pi * sum [k=1:n] sin((2*k - 1)*x) / (2*k - 1)
set samples 400
set xrange [-pi:pi]; set yrange [-1.6:1.6]
set key bottom right
plot n = 1, square(x) title 'n = 1', n = 3, square(x) title 'n = 3', n = 15, square(x) title 'n = 15'
