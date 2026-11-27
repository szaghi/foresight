# a whole document, its graphics pc06_standalone-inc.pdf: lualatex pc06_standalone.tex
set terminal cairolatex pdf standalone size single font ',10' header '\usepackage{lmodern}'
set output 'pc06_standalone.tex'
replot
