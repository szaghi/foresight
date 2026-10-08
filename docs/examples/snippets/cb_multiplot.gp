set terminal svg size 560,420; set output 'cb_multiplot.svg'
set multiplot layout 2,1
set logscale y; plot 'run.dat' u 1:2 t 'continuity'
unset logscale y; plot 'run.dat' u 1:5 t 'cd'
unset multiplot
