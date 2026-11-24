set terminal svg size 560,320; set output 'cb_zsort.svg'
# zsort: the points drawn in the order of their z, the high values on top
set print $D
do for [i=1:3000] { print rand(0), rand(0), invnorm(rand(0)) }
unset print
set palette cubehelix negative; set cbrange [-3:3]; unset key
set multiplot layout 1,2
set title "file order"
plot $D using 1:2:3 with points pt 7 ps 0.5 lc palette
set title "zsort"
plot $D using 1:2:3:3 zsort with points pt 7 ps 0.5 lc palette
unset multiplot
