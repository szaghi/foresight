set terminal svg size 640,400; set output 'cb_annotations.svg'
# labels, arrows and objects in data, graph and page coordinates
set title 'labels, arrows, objects'; set grid; set xrange [0:10]
set object 1 rect from 4, graph 0 to 6, graph 1 fc rgb '#56b4e9' fs solid 0.25 noborder behind
set object 2 rect from 8,0.6 to 9.8,0.95
set object 3 circle at 2,-0.5 size 0.6 fc rgb '#e69f00' fs solid 0.5 border
set object 4 ellipse at 7,-0.6 size 1.6,0.5 angle 30
set object 5 polygon from 0.5,0.6 to 1.5,0.6 to 1,0.95 to 0.5,0.6 fc lt 2 fs solid 0.6 front
set label 1 'peak' at pi/2, 1 point pt 7 offset 1,0
set label 2 'transient' at graph 0.5, 0.5 center
set label 3 'rotated' at 9.2,-0.9 rotate by 60 tc rgb 'red'
set label 4 'screen 0.98, 0.03' at screen 0.98, 0.03 right front
set arrow 1 from 3,-0.2 to 4.6,-0.9
set arrow 2 from 3,0.2 to 4.6,0.8 heads filled lc rgb '#9400d3' lw 2
set arrow 3 from 8.9,0.2 rto -1,0.3 backhead empty size 0.3,25
set arrow 4 from graph 0.05,0.1 to graph 0.25,0.1 nohead dt 2 front
plot sin(x) lw 2 t 'sin(x)'
