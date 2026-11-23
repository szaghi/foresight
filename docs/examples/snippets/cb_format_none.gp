set terminal svg size 560,320; set output 'cb_format_none.svg'
# set format y "": the ticks kept, their labels hidden; a format without conversion writes its text at every tick
set format y ""; set format x "|"; set grid; set key off
plot sin(x) lw 2
