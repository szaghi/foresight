set terminal svg size 560,360; set output 'cb_nonuniform.svg'
# a nonuniform matrix: x in the first row, y in the first column; index "name" picks the dataset of that comment
$M << EOM
# coarse
0 0 1
0 1 2
1 3 4


# fine
0 0 0.5 1 1.5
0 0 1 2 3
0.5 1 2 3 4
1 2 3 4 5
EOM
set palette viridis
plot $M nonuniform matrix index "fine" with image title 'index "fine"'
