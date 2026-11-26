set terminal svg size 560,400; set output 'cb_inset_clear.svg'
# an inset on a cleared box (clear), its key headed by a text entry (keyentry "text")
set multiplot
set title 'damped oscillation'
set samples 400
set key bottom right
plot [0:20] exp(-x/6)*cos(2*x) lw 2 title 'signal'
set origin 0.52, 0.5; set size 0.42, 0.38
clear
unset title
set key top right samplen 2
set xtics 1; set ytics 0.5
plot [0:3] exp(-x/6)*cos(2*x) lw 2 notitle, keyentry 'detail' font ':Bold', keyentry with lines lc 'gray50' title 't < 3'
unset multiplot
