# a summary of the run in the terminal: a loop over the columns, stats and sprintf
names = 'continuity momentum energy'
print sprintf('%-11s %10s %10s %7s', 'residual', 'max', 'min', 'orders')
do for [i = 2:4] {
   stats 'run.dat' u i name 'r' nooutput
   print sprintf('%-11s %10.3e %10.3e %7.1f', word(names, i - 1), r_max, r_min, log10(r_max/r_min))
}
