set terminal svg size 480,420; set output 'cb_polar_labels.svg'
# polar labels: theta every 45 degrees, three named angles, minor ticks on the border, the rings of the r ticks
set encoding utf8
set polar; set size square; unset border; set border polar; unset xtics; unset ytics; unset key
set grid r polar 45
set ttics 0,45 format '%g'.GPVAL_DEGREE_SIGN
set ttics add ('π/2' 90, 'π' 180, '3π/2' 270)
set mttics 3
set rrange [0:6]
plot t lw 2
