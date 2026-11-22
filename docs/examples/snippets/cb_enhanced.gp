set terminal svg size 560,340; set output 'cb_enhanced.svg'
# gnuplot's enhanced text: sub and superscripts, Greek letters, sizes, bold and italic; noenhanced as it is
set title "{/:Bold Decay} of u(t) = u_0 e^{-t/{/Symbol t}}"
set xlabel "t / {/Symbol t}"; set ylabel "u / u_0"
set xrange [0:4]; set yrange [-0.6:1.1]
set xtics ("0" 0, "{/Symbol t}" 1, "2{/Symbol t}" 2, "3{/Symbol t}" 3, "4{/Symbol t}" 4)
set label 1 "{/:Italic half life} t_{1/2} = {/Symbol t} ln 2" at 0.8,0.55
set label 2 "run_07/u_probe.dat" at 2.3,-0.45 noenhanced
plot exp(-x) lw 2 t "e^{-t/{/Symbol t}}", exp(-x)*cos(2*pi*x) lw 2 t "e^{-t/{/Symbol t}} cos 2{/Symbol p}t"
