plot 'run.csv' using "iteration":(column("cd") * 1e4), \
     ''        using 1:($1 > 60 ? $5 * 1e4 : 1/0) with points pt 6 title 'after the restart'
