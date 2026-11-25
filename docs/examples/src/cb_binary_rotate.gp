set terminal svg size 560,360; set output 'cb_binary_rotate.svg'
# a binary image placed by its centre and turned: right angles stay pixels, other angles draw each pixel a polygon
set size ratio -1
set xrange [-24:84]; set yrange [-24:44]
set key outside
plot 'gradient.rgb' binary array=(32,16) format='%uchar' center=(0,10) with rgbimage title 'center=(0,10)', \
     'gradient.rgb' binary array=(32,16) format='%uchar' center=(30,10) rotation=90d with rgbimage title 'rotation=90d', \
     'gradient.rgb' binary array=(32,16) format='%uchar' center=(62,10) rotation=30d with rgbimage title 'rotation=30d'
