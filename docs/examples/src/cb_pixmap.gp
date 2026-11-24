set terminal svg size 560,320; set output 'cb_pixmap.svg'
# PNG images on the page: a badge in the corner, one per marked point
set pixmap 1 'badge.png' at screen 0.97, 0.94 width screen 0.06 center front
set pixmap 2 'badge.png' at 2, sin(2) center width char 2
set pixmap 3 'badge.png' at 5, sin(5) center width char 2
set key off; set xrange [0:2*pi]
plot sin(x) lw 2
