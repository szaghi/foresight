set terminal svg size 560,360; set output 'cb_arrow_styles.svg'
# arrow styles, the rectangle style, dashed borders, character coordinates
set style arrow 1 head filled size screen 0.025,15 lc rgb '#b3163f' lw 2
set style arrow 2 nohead lc rgb '#0072b2' dt 2
set arrow from 1,1 to 4,4 as 1
set arrow from 1,4 to 4,1 as 2
set arrow from 6,8.5 to 8.2,6.6 as 1 lc rgb '#009e73'
set style rectangle fc rgb '#fff3b0' fs solid border lc rgb '#e69f00' lw 2
set object 1 rect from 5,1 to 7,3
set object 2 rect from 1.5,6 to 3.5,8 dt 2 fc rgb '#dfe9ff'
set object 3 circle at 8,8 size 1 dt 3 lw 1.5
set label 'at character 9, 5' at character 9, 5
set xrange [0:10]; set yrange [0:10]; set key off
plot 5 dt 3 lc 'gray' notitle
