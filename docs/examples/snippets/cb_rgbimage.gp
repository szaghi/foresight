set terminal svg size 560,400; set output 'cb_rgbimage.svg'
set size ratio 0.667
plot 'wheel.dat' u 1:2:3:4:5 w rgbimage t 'rgbimage'
