#run pc06 foresight pc06_latex_labels.gp && ls pc06* && grep -F '\put' pc06.tex
# region input
# the drawing as a PDF, the texts in a LaTeX picture that LaTeX sets: \input{pc06.tex} in a paper
set terminal cairolatex pdf size single
set output 'pc06.tex'
set xlabel '$t/\tau$'
set ylabel '$x/x_0$'
set key top right
plot [0:4] exp(-x)*cos(2*pi*x) title '$e^{-t/\tau}\cos\omega t$', exp(-x) title '$e^{-t/\tau}$' dt 2
# endregion input
# region standalone
# a whole document, its graphics pc06_standalone-inc.pdf: lualatex pc06_standalone.tex
set terminal cairolatex pdf standalone size single font ',10' header '\usepackage{lmodern}'
set output 'pc06_standalone.tex'
replot
# endregion standalone
