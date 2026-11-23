set terminal svg size 560,320; set output 'cb_smooth_band.svg'
# a band x:y1:y2 smoothed (both curves by the filter, on the same samples), the fields read by a format string
$ENVELOPE << EOD
0 0.2 1.0
1 0.6 1.6
2 0.5 1.9
3 1.1 2.2
4 0.9 2.6
5 1.5 2.4
EOD
set samples 100; set key top left
plot $ENVELOPE using 1:2:3 "%lf %lf %lf" smooth csplines with filledcurves fs transparent solid 0.4 t 'smoothed band', \
     $ENVELOPE using 1:2:3 with filledcurves fs transparent solid 0.2 t 'raw band'
