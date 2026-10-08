set terminal svg size 560,320; set output 'cb_model.svg'
# the function is sampled over the x range of the data
plot 'run.dat' u 1:5 with points pt 6 t 'cd', 0.30 + 0.25*exp(-x/25)*cos(x/6) t 'model'
