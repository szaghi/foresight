# skin friction of a flat plate: math in the axis labels and the key
set terminal svg size 560,320
set output 'cb_math.svg'
set xlabel '$\mathrm{Re}_x = U x/\nu$'
set ylabel '$c_f$'
set logscale xy
set format xy '$10^{%T}$'
set key top right
plot [1e4:1e8] 0.664/sqrt(x) title '$c_f = 0.664\,\mathrm{Re}_x^{-1/2}$', \
     0.0592*x**(-0.2) title '$c_f = 0.0592\,\mathrm{Re}_x^{-1/5}$' dt 2
