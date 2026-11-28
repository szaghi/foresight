#run pb03 foresight pb03_readouts.gp
# region readouts
# the numbers a long run is watched for, as seven-segment readouts over the convergence history
set terminal svg size 700,400 theme vfd
set output 'pb03.svg'
set multiplot title 'RUN MONITOR'
set origin 0,0.66; set size 1,0.34
set readout horizontal
plot 'run.dat' u 1 w readout format '%4.0f' t 'ITER', \
     '' u 2 w readout format '%9.2e' t 'CONTINUITY', \
     '' u 5 w readout format '%6.4f' t 'CD'
set origin 0,0; set size 1,0.66
set logscale y; set format y '10^{%L}'; set grid; set key top right
plot 'run.dat' u 1:2 w l lw 2 t 'continuity', '' u 1:3 w l lw 2 t 'momentum'
unset multiplot
# endregion readouts
