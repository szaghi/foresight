set terminal svg size 560,360; set output 'cb_matrix_headers.svg'
# a CSV table as a heat map: its first row and column name the columns and rows (matrix columnheaders rowheaders)
$sales << EOD
,Q1,Q2,Q3,Q4
North,12,15,9,20
South,8,11,14,10
East,5,7,12,16
EOD
set datafile separator comma
set palette viridis
set title 'units sold'
plot $sales matrix rowheaders columnheaders using 1:2:3 with image notitle
