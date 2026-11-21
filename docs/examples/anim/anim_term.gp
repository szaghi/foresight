# frames 12 0.7 text 680,330
# the same run over ssh: foresight --watch -e "set terminal block braille" redraws the terminal in place
k = ARG1 + 0
last = sprintf('%d', 20*k - 1)
set terminal block braille size 88,20; set output sprintf('frames/anim_term_%02d.txt', k)
set title 'residual (braille)'
set logscale y; set yrange [1e-5:1]; set xrange [0:240]
plot 'live.dat' u 3:4 every ::0::@last w l t 'residual'
