set terminal svg size 560,320; set output 'cb_interrupted_lines.svg'
# pointinterval -N: a marker every N points, the line blanked under it
set samples 60; set xrange [0:3]; set key top right
plot cos(x) lt -1 pi -4 pt 6 with linespoints t 'pi -4', cos(x - 0.4) lt -1 pi -5 pt 4 with linespoints t 'pi -5', \
     cos(x - 0.8) lt -1 pi 6 pt 7 with linespoints t 'pi 6'
