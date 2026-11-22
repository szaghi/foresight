set terminal svg size 560,320; set output 'cb_live_loop.svg'
# gnuplot 6.0's live loop: plot, pause, plot again (a real one is while (1) { ... }; here three passes)
set logscale y; set format y '%h'; set xlabel 'iteration'; set ylabel 'residual'
pass = 0
while (pass < 3) {
  pass = pass + 1
  set title sprintf('pass %d: %d iterations', pass, 80 * pass)
  plot 'live.dat' u 3:($3 <= 80 * pass ? $4 : 1/0) w l lw 2 t 'residual'
  pause 0.1
}
