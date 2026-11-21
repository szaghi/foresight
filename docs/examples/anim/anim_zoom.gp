# frames 10 0.8
# zooming on x = 3: each frame the window narrower by 2.5, the ticks exact decimals at every scale
k = ARG1 + 0
w = 4.0 / 2.5**(k - 1)
set terminal svg size 640,320; set output sprintf('frames/anim_zoom_%02d.svg', k)
set title sprintf('x window %g wide', 2*w)
set samples 400; set grid
set xrange [3 - w : 3 + w]
plot sin(x) + x/10 lw 2 t 'sin(x) + x/10'
