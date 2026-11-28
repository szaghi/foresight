# the runs of a mesh study (mesh.dat: a header row, then one run per line) as a Markdown table
set datafile columnheaders
set table 'pf02_runs.md' markdown
plot 'mesh.dat' using (strcol(1)):'cells':'error':'time' with table
unset table
# a plot's points as a table: a series per table, its title before it, numbers in the axis formats
set table 'pf02_fit.md' markdown
set format y '%.2e'
set samples 4
plot [1e3:1e6] 3.1*x**(-2.0/3) title 'model error' with lines
unset table
set terminal svg size 600,320 theme paper
set output 'pf02.svg'
set format y '10^{%L}'
set logscale xy
set xlabel 'cells'
set ylabel 'error'
set key top right
plot 'mesh.dat' using 'cells':'error' with linespoints title 'runs', \
     [1e3:1e6] 3.1*x**(-2.0/3) title 'model error' dt 2
