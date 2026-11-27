# the drawing as a PDF, the texts in a LaTeX picture that LaTeX sets: \input{pc06.tex} in a paper
set terminal cairolatex pdf size single
set output 'pc06.tex'
set xlabel '$t/\tau$'
set ylabel '$x/x_0$'
set key top right
plot [0:4] exp(-x)*cos(2*pi*x) title '$e^{-t/\tau}\cos\omega t$', exp(-x) title '$e^{-t/\tau}$' dt 2
