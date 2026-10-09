set terminal svg size 560,400; set output 'cb_spider.svg'
set spiderplot
set style spiderplot fs transparent solid 0.25 border lw 2
set paxis 1 range [0:10]; set paxis 2 range [0:10]; set paxis 3 range [0:10]
set paxis 4 range [0:10]; set paxis 5 range [0:10]
set paxis 1 tics 2; set grid spiderplot
plot 'solvers.dat' u 2:key(1) t 'speed', '' u 3 t 'memory', '' u 4 t 'accuracy', '' u 5 t 'scaling', '' u 6 t 'robustness'
