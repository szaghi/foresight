set terminal svg size 560,360; set output 'cb_palette_hsv.svg'
# a color wheel: the palette in hue, saturation, value (model HSV), the hue from the angle
set print $WHEEL
do for [j = 0:60] {
   do for [i = 0:60] {
      x = -1 + i/30.0; y = -1 + j/30.0
      print x, y, (x*x + y*y <= 1 ? atan2(y, x)/(2*pi) + 0.5 : NaN)
   }
   print ""
}
set print
set palette model HSV defined (0 0 1 1, 1 1 1 1)
set size square
set cbrange [0:1]; set cblabel 'hue'
plot $WHEEL using 1:2:3 with image notitle
