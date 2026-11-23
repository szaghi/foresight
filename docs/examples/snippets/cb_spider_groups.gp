set terminal svg size 560,420; set output 'cb_spider_groups.svg'
# two sets of polygons on the same axes: newspiderplot starts the second; keyentry names each set
array A1 = [15, 75, 20, 43, 90, 50]
array A2 = [25, 25, 50, 50, 75, 50]
set spiderplot
set for [i=1:6] paxis i range [0:100]
set style spiderplot fs transparent solid 0.2 border lw 1 pt 6 ps 1.5
set grid spider
set key reverse
plot keyentry with spiderplot lc 3 lw 3 title "Array #1", \
     for [i=1:|A1|] A1 using (A1[i]) lc 3 lw 3 title sprintf("Scale %d", i), \
     newspiderplot, \
     keyentry with spiderplot lc 4 lw 2 title "Array #2", \
     for [j=1:|A2|] A2 using (A2[j]) lc 4 lw 2 notitle
