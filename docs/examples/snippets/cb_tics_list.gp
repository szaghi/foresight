set terminal svg size 560,320; set output 'cb_tics_list.svg'
set xtics ("Jan" 1, "" 1.5 1, "Feb" 2, "" 2.5 1, "Mar" 3, "" 3.5 1, "Apr" 4, "" 4.5 1, "May" 5, "" 5.5 1, "Jun" 6)
set ytics add ("alert" 75, "%.0f mm" 45)
set grid
set yrange [30:90]
plot 'rain.dat' u 1:2 w linespoints t 'rain'
