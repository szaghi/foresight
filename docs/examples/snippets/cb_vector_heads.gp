set terminal svg size 560,360; set output 'cb_vector_heads.svg'
# vectors with arrow styles: as N gives the heads, size and color of set style arrow N; size screen L,A per item
set style arrow 1 head filled size screen 0.025,25 lc rgb '#0072b2' lw 2
set style arrow 2 heads empty size screen 0.02,40 lc rgb '#d55e00'
set xrange [0:10]; set yrange [0:4]
plot sample [i=1:9:1] '+' using (i):(3):(0.6):(0.5) with vectors as 1 title 'as 1', \
     [i=1:9:1] '+' using (i):(1.5):(0.6):(-0.5) with vectors as 2 title 'as 2', \
     [i=1:9:2] '+' using (i):(0.5):(0.8):(0) with vectors size 0.4,15 filled lc rgb '#009e73' title 'size 0.4,15'
