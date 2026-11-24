set terminal svg size 560,320; set output 'cb_hist_colors.svg'
# column-stacked histograms colored by category (lc variable), each stack named by its title
$RUN1 << EOD
mesh 3
solve 12
io 2
EOD
$RUN2 << EOD
mesh 2
solve 8
io 4
EOD
set style data histogram; set style histogram columns; set style fill solid border lc "black"; set boxwidth 0.6
names = "mesh solve io"
set linetype 101 lc "steelblue"; set linetype 102 lc "dark-orange"; set linetype 103 lc "sea-green"
color(name) = 100 + (name eq "mesh" ? 1 : name eq "solve" ? 2 : 3)
set key outside right title "phase"
plot for [run in "$RUN1 $RUN2"] run using 2:(color(strcol(1))) lc variable title run, \
     for [i=1:3] keyentry with boxes lc (100 + i) title word(names, i)
