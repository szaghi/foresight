set terminal svg size 560,320; set output 'cb_hist_columns.svg'
# one stack per build (the column headers below them), each phase in its color, named in the key
set style data histograms
set style fill solid 0.8 border -1; set style histogram columnstacked
set ylabel 'share of the step [%]'; set key outside right
plot 'shares.dat' u 2 t columnhead, '' u 3 t columnhead, '' u 4:key(1) t columnhead
