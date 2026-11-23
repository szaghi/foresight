set terminal svg size 560,360; set output 'cb_arrowstyle_var.svg'
# a style per arrow: the fifth column names `set style arrow N` (heads, fill, width, color)
set style arrow 1 head filled size screen 0.02,20 lc rgb "#0072b2" lw 2
set style arrow 2 heads nofilled lc rgb "#d55e00" lw 1
set style arrow 3 nohead lc rgb "#009e73" lw 3 dt 2
unset key; set xrange [0:13]; set yrange [-1.5:1.5]
plot '+' using ($0):(sin($0/2)):(0.8):(0.5*cos($0/2)):(int($0)%3 + 1) with vectors arrowstyle variable
