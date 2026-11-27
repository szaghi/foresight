# the gain of a damped oscillator, its labels and key set by LaTeX: \input{cb_latex.tex}
set terminal cairolatex pdf size single
set output 'cb_latex.tex'
set xlabel '$\omega/\omega_0$'
set ylabel '$|H(i\omega)|$'
set logscale y
set key top right
H(w, z) = 1/sqrt((1 - w**2)**2 + (2*z*w)**2)
plot [0:3] H(x, 0.1) title '$\zeta = 0.1$', H(x, 0.3) title '$\zeta = 0.3$' dt 2, \
     H(x, 0.7) title '$\zeta = 0.7$' dt 3
