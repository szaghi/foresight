set terminal svg size 560,400; set output 'cb_image.svg'
set cblabel 'phi'
plot 'field.dat' u 1:2:3 w image t 'phi(x,y)'
