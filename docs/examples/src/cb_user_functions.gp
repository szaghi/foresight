set terminal svg size 560,320; set output 'cb_user_functions.svg'
A = 2.0; tau = 3.0; omega = 2*pi/2
envelope(t) = A*exp(-t/tau)
signal(t) = envelope(t)*cos(omega*t)
set xrange [0:2*tau]
plot signal(x) t 'signal', envelope(x) t 'envelope', -envelope(x) notitle
