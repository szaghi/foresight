set terminal svg size 560,320; set output 'cb_running_mean.svg'
# assignments inside expressions: shift5 moves a five-value window on each row, (s = s + $2, ...) a running sum
set samples 80
set table $D; plot [0:8] sin(x) + 0.4*sin(9*x); unset table
shift5(x) = (b5 = b4, b4 = b3, b3 = b2, b2 = b1, b1 = x)
avg5(x) = (shift5(x), (b1 + b2 + b3 + b4 + b5) / 5.)
set key bottom left
plot b1 = b2 = b3 = b4 = b5 = 0, s = 0, \
     $D using 1:2 with points pt 7 ps 0.5 title 'data', \
     '' using 1:(avg5($2)) with lines lw 2 title 'mean of the last 5', \
     '' using 1:(s = s + $2, s / ($0 + 1)) with lines lw 2 title 'cumulative mean'
