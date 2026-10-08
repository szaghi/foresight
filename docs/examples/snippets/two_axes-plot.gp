plot 'run.dat' using 1:2 title 'continuity', \
     ''        using 1:5 axes x1y2 with points pt 7 ps 0.6 title 'cd', \
     0.30 + 0.25*exp(-x/25)*cos(x/6) axes x1y2 dt 2 title 'model'
