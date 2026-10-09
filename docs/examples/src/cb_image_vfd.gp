set terminal svg size 560,400 theme vfd; set output 'cb_image_vfd.svg'
set palette maxcolors 8
plot 'field.dat' u 1:2:3 w image notitle
