set terminal svg size 560,320; set output 'cb_missing.svg'
set datafile commentschars "%"
set datafile missing "-"
plot 'sensor.dat' u 1:2 w lp t 'inlet', '' u 1:3 w lp t 'outlet'
