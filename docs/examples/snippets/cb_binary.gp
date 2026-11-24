set terminal svg size 560,320; set output 'cb_binary.svg'
# binary arrays: raw RGB bytes (32 x 16 pixels, one %uchar per channel) as images, placed, scaled and flipped
set key outside
plot 'gradient.rgb' binary array=(32,16) format='%uchar' with rgbimage title 'raw', \
     'gradient.rgb' binary array=(32,16) format='%uchar' flipy dx=0.5 origin=(36,0) with rgbimage title 'flipy dx=0.5'
