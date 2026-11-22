set terminal svg size 720,480; set output 'cb_special_functions.svg'
# gnuplot's special functions: Bessel, gamma, error and normal, Lambert W and Airy
set multiplot layout 2,2
set key bottom left; set title 'Bessel'
plot [0:20] besj0(x) t 'J_0', besj1(x) t 'J_1', besjn(2, x) t 'J_2', besy0(x) t 'Y_0'
set key top left; set title 'gamma'
plot [-4:5] [-6:6] gamma(x) t '{/Symbol G}(x)', lgamma(x) t 'ln|{/Symbol G}(x)|'
set key top left; set title 'error and normal'
plot [-3:3] [-1.1:1.1] erf(x) t 'erf', norm(x) t 'norm', x >= 0 ? igamma(2, x) : 1/0 t 'igamma(2, x)'
set key top left; set title 'Lambert W, Airy'
plot [-2:5] lambertw(x) t 'W(x)', airy(x) t 'Ai(x)'
unset multiplot
