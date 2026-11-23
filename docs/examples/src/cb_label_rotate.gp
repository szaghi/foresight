set terminal svg size 560,360; set output 'cb_label_rotate.svg'
# labels turned by a column (rotate variable) and colored by another (tc variable)
set angles degrees; unset key
set xrange [0:13]; set yrange [0:13]
$Clock << EOD
1 one -30
2 two -60
3 three -90
4 four -120
5 five -150
6 six -180
7 seven -210
8 eight -240
9 nine -270
10 ten -300
11 eleven -330
12 twelve -360
EOD
plot $Clock using 1:1:2:3:0 with labels rotate variable tc variable
