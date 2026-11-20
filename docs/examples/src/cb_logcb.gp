set terminal svg size 560,400; set output 'cb_logcb.svg'
set logscale cb; set cblabel 'residual'
set cbtics 10
plot 'field.dat' u 1:2:(10**(3*$3)) w image notitle
