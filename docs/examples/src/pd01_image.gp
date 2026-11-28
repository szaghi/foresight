#run pd01 foresight pd01_image.gp
# region image
# a field on a grid (field.dat: x y phi, a block per row) as an image, its values through a palette
set terminal svg size 600,420
set output 'pd01.svg'
set title 'A damped wave'
set xlabel 'x'; set ylabel 'y'; set cblabel '{/Symbol f}'
set size ratio -1
set palette viridis
plot 'field.dat' using 1:2:3 with image notitle
# endregion image
