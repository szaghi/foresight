set terminal svg size 560,360; set output 'cb_pt_variable.svg'
# points whose type, size and color come from columns (pt variable, ps variable, lc rgb variable)
$SITES << EOD
# x    y    size  type  color
  1.0  2.0  1.5   7     0x1b9e77
  2.2  3.1  2.5   5     0xd95f02
  3.1  1.4  1.0   9     0x7570b3
  4.0  2.6  3.0   7     0xe7298a
  5.2  3.4  2.0   13    0x66a61e
  5.8  1.8  1.5   5     0xe6ab02
EOD
set xrange [0:7]; set yrange [0:4.5]
set key top left
plot $SITES using 1:2:3:4:5 with points ps variable pt variable lc rgb variable title 'sites'
