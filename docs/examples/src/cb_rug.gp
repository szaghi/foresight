set terminal svg size 560,360; set output 'cb_rug.svg'
# a rug plot: empty tic labels are ticks too, one per row on each axis (xtic("") and ytic(""))
set samples 60
set xtics out scale 2 nomirror; set ytics out scale 2 nomirror
set xrange [-3:3]; set yrange [-3:3]; unset key
plot '+' using (2*sin($1*7.3)):(2*cos($1*3.1)):xtic(""):ytic("") with points pt 7 ps 0.6
