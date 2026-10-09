set terminal svg size 560,320; set output 'cb_candlesticks.svg'
set boxwidth 20; set xlabel 'iteration'; set ylabel 'log10 residual'
plot 'windows.dat' u 1:2:3:4:5 w candlesticks t 'candlesticks' whiskerbars 0.5, \
     ''            u ($1+20):2:3:4:5 w financebars t 'financebars'
