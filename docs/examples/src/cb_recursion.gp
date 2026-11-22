set terminal svg size 560,320; set output 'cb_recursion.svg'
# Chebyshev polynomials by their recurrence: a recursive user function, as gnuplot 6.0
T(n, x) = n == 0 ? 1 : n == 1 ? x : 2*x*T(n - 1, x) - T(n - 2, x)
set xrange [-1:1]; set yrange [-1.2:1.2]; set samples 200
set title 'T_n(x) = 2x T_{n-1}(x) - T_{n-2}(x)'; set key outside right
plot for [n = 2:5] T(n, x) t sprintf('T_%d', n)
