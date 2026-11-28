# a plot's points as a table: a series per table, its title before it, numbers in the axis formats
set table 'pf02_fit.md' markdown
set format y '%.2e'
set samples 4
plot [1e3:1e6] 3.1*x**(-2.0/3) title 'model error' with lines
unset table
