set terminal svg size 560,360; set output 'cb_linked_axes.svg'
# set link x2 via ... inverse ...: the top axis a function of the bottom one, here wavelength and wavenumber
set xlabel 'wavelength [um]'; set x2label 'wavenumber [1/cm]'
set link x2 via 1e4/x inverse 1e4/x
set xrange [2:20]; set xtics nomirror; set x2tics; set key top right
plot 1.0/(1 + ((x - 8)/2)**2) lw 2 t 'absorption band'
