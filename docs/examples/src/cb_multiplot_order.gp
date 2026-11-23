set terminal svg size 560,360; set output 'cb_multiplot_order.svg'
# panels filled column by column from the bottom row: columnsfirst upwards
set multiplot layout 2,2 columnsfirst upwards title 'columnsfirst upwards' font ',12'
set ytics 1
do for [k = 1:4] {
   set title sprintf('panel %d', k)
   plot sin(k*x) notitle
}
unset multiplot
