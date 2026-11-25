set terminal svg size 520,400; set output 'cb_sparse_matrix.svg'
# a distance matrix given as its upper triangle: sparse matrix bins the points into a 4x4 grid, the rest empty
$DIST << EOD
1 1 0
1 2 20
1 3 30
1 4 40
2 2 0
2 3 50
2 4 60
3 3 0
3 4 20
4 4 0
EOD
set xrange [0.5:4.5]; set yrange [4.5:0.5]
set xtics 1; set ytics 1
set palette cubehelix negative
plot $DIST sparse matrix=(4,4) origin=(1,1) with image notitle
