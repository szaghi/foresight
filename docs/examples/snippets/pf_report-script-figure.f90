! a figure drawn by a script: its caption set there, its information from the figure the script built
call gp%init('report/residuals.svg')
call gp%run_text("set terminal svg size 600,340 theme paper"//nl// &
                 "set logscale y; set format y '10^{%L}'"//nl// &
                 "set xlabel 'iteration'; set ylabel 'residual'; set title 'Convergence'"//nl// &
                 "set caption 'The three residuals fall by five decades or more; the restart at iteration 60 does not "// &
                 "disturb them.'"//nl// &
                 "plot 'run.dat' u 1:2 w l t 'continuity', '' u 1:3 w l t 'momentum', '' u 1:4 w l t 'energy'", &
                 iostat, iomsg)
if (iostat /= 0_I4P) error stop iomsg
call gp%figure%save('report/residuals.svg', info=meta)
call add_figure(meta)
