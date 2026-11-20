set terminal svg size 760,320; set output 'cb_colorbox.svg'
set multiplot layout 1,2
set palette viridis; set cblabel 'phi'
set title 'set colorbox horizontal'; set colorbox horizontal
plot 'field.dat' u 1:2:3 w image notitle
set title 'set colorbox user ... invert'
set colorbox vertical user origin 0.86,0.3 size 0.02,0.45 invert
plot 'field.dat' u 1:2:3 w image notitle
unset multiplot
