set terminal svg size 560,400; set output 'cb_palette_file.svg'
set palette file 'terrain.dat'
set cbrange [-1:1]; set cblabel 'height'
plot 'field.dat' u 1:2:3 w image notitle
