set terminal svg size 560,320; set output 'cb_function.svg'
set samples 400
plot sin(x)/x title 'sinc', exp(-abs(x)/4) dt 2
