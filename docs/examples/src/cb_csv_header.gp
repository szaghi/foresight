set terminal svg size 560,320; set output 'cb_csv_header.svg'
set datafile separator comma
set logscale y
plot 'run.csv' using "iteration":"continuity" title columnhead, '' using 1:"energy" title columnhead
