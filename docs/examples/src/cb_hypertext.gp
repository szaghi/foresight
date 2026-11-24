set terminal svg size 560,320; set output 'cb_hypertext.svg'
# labels hypertext: the texts shown on mouse-over of their points; ps variable: each point's size from a column
$CITIES << EOD
Paris     2.35 48.86 2.1
Lyon      4.84 45.76 0.5
Marseille 5.37 43.30 0.9
Toulouse  1.44 43.60 0.5
Lille     3.06 50.63 0.2
Nantes   -1.55 47.22 0.3
EOD
unset key
plot $CITIES using 2:3:(sprintf("%s\npop. %.1f M", strcol(1), $4)):(1 + 2*sqrt($4)) \
     with labels hypertext point pt 7 ps variable lc rgb "#e0a020", \
     '' using 2:3:(1 + 2*sqrt($4)) with points pt 6 ps variable lc "black"
