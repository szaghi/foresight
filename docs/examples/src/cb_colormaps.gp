set terminal svg size 760,560; set output 'cb_colormaps.svg'
set multiplot layout 2,2
set title 'batlow: sequential'; set palette batlow
plot 'field.dat' u 1:2:3 w image notitle
set title 'vik: diverging, about 0'; set palette vik; set cbrange [-1:1]
plot 'field.dat' u 1:2:3 w image notitle
set title 'oleron: below and above 0'; set palette oleron; set cbrange [-1:1]
plot 'field.dat' u 1:2:3 w image notitle
set title 'romaO: cyclic, an angle'; set palette romaO; set cbrange [-180:180]
plot 'angle.dat' u 1:2:3 w image notitle
unset multiplot
