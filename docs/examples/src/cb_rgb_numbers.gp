set terminal svg size 560,360; set output 'cb_rgb_numbers.svg'
# lc rgb with numbers (0xRRGGBB, 0xAARRGGBB with a transparency): a key wrapped into columns when tall
unset tics; unset border; set key center center; set style fill solid
plot 0 lt nodraw notitle, for [i = 0:35] keyentry with boxes lc rgb (int(255*i/35.)*65536 + int(255*(35-i)/35.)*256 + 128) \
     title sprintf("0x%06x", int(255*i/35.)*65536 + int(255*(35-i)/35.)*256 + 128)
