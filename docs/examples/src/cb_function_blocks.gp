set terminal svg size 560,320; set output 'cb_function_blocks.svg'
# a function block: Newton's iterations for r**3 = a, with a local and a return from inside the loop
function $cbrt << EOF
  local r = ARGV[1] > 1 ? 1.0 * ARGV[1] : 1.0
  do for [k = 1:50] {
    d = (r**3 - ARGV[1]) / (3*r**2)
    r = r - d
    if (abs(d) < 1e-12) { return r }
  }
  return r
EOF
set xrange [0:8]; set samples 60; set key top left
label = sprintf('$cbrt(27) = %g, $cbrt(2) = %.6f', $cbrt(27), $cbrt(2)); set title label
plot $cbrt(x) w lp pi 6 pt 7 t '$cbrt(x), Newton', x**(1./3) dt 2 lw 2 t 'x**(1./3)'
