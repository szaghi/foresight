set terminal svg size 760,300; set output 'cb_palettes.svg'
set multiplot layout 1,3
unset colorbox
set title 'gray'; set palette gray
plot 'field.dat' u 1:2:3 w image notitle
set title 'rgbformulae 33,13,10'; set palette rgbformulae 33,13,10
plot 'field.dat' u 1:2:3 w image notitle
set title 'defined'; set palette defined (0 'blue', 1 'white', 2 'red')
plot 'field.dat' u 1:2:3 w image notitle
unset multiplot
