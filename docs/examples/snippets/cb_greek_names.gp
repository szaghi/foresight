set terminal svg size 560,320; set output 'cb_greek_names.svg'
# UTF-8 names: variables and functions written as the formulas are
ω = 2*pi; ζ = 0.15
y(τ) = exp(-ζ*ω*τ) * cos(ω*sqrt(1 - ζ**2)*τ)
set samples 300; set xrange [0:3]; set key top right
plot y(x) lw 2 t 'damped oscillation', exp(-ζ*ω*x) dt 2 t 'envelope'
