#run pc02 foresight pc02_fonts.gp && ls pc02.*
# region figure
set terminal svg size 600,400 fontglyphs
set title "Damping ζ = c / (2√(km)), Re ≈ 2·10^{3}, ΔT ≤ 5 °C"
set xlabel "{/serif ω / ω_n}"
set ylabel "|H(iω)|"
set logscale x
set key top right
H(x, z) = 1 / sqrt((1 - x**2)**2 + (2*z*x)**2)
set output 'pc02.pdf'
plot [0.1:10] H(x, 0.1) title "ζ = 0.1", H(x, 0.3) title "ζ = 0.3", H(x, 1) title "ζ = 1"
# endregion figure
# region svg
set output 'pc02.svg'
replot
# endregion svg
