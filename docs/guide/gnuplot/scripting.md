---
title: Scripting
---

# Scripting

Variables, functions, strings, datablocks, arrays, blocks and loops, special functions. Part of the [gnuplot subset](/guide/gnuplot-subset) reference.

## User variables and functions

```gnuplot
A = 2.0; tau = 3.0; omega = 2*pi/2
envelope(t) = A*exp(-t/tau)
signal(t) = envelope(t)*cos(omega*t)
set xrange [0:2*tau]
plot signal(x) t 'signal', envelope(x) t 'envelope', -envelope(x) notitle
```

<Plot name="cb_user_functions" svg :width="560" :height="320" />

As gnuplot: `name = expression` stores the value of the expression now, an integer stays an integer (`a = 2; b = a/3`
is 0, `a = 2.` is real); `name(p1, p2, ...) = expression` defines a function whose variables take their values when
it is called, that is when the plot is drawn (`f(x) = a*x; a = 3` then `plot f(x)` uses 3; `replot` after a new value
uses it). Names may hold UTF-8 letters (`π = pi`, `α(λ,φ) = ...`), as gnuplot. Expressions everywhere take them: plotted functions, `using` fields (`u 1:($2*scale)`), range ends (`set
xrange [0:2*tau]`, also `[-pi:pi]`). The plot's dummy variable wins over a user variable of its name, and is not seen
inside a function body (there `x` is the user variable `x`). Names are case sensitive (`a_1`, `A`), `pi` may be
assigned, the builtin functions may not be redefined. Errors as gnuplot: `undefined variable: c`, `function f requires
1 variable`; a variable in an operand run only if a condition holds (`exists("Q") && Q == 27`, the right one of
`&&`, `||`, the branches of `?:`) is read when run, an error only if reached, as gnuplot's. Variables also hold [strings](#strings); `undefine NAME` forgets one (see
[Datablocks and scripts](#datablocks-and-scripts)). Each function definition is kept as written in the string
variable `GPFUN_`*name*, as gnuplot's (`print GPFUN_f` prints `f(x) = a*x`).

Functions may recurse, directly or through others, as in gnuplot 6.0:

```gnuplot
fact(n) = n <= 1 ? 1 : n*fact(n - 1)
T(n, x) = n == 0 ? 1 : n == 1 ? x : 2*x*T(n - 1, x) - T(n - 2, x)    # Chebyshev polynomials
even(n) = n == 0 ? 1 : odd(n - 1); odd(n) = n == 0 ? 0 : even(n - 1)
```

<Plot name="cb_recursion" svg :width="560" :height="320" />

As gnuplot, at most 251 nested calls: `t(n) = n == 0 ? 0 : t(n - 1)` runs `t(250)`, `t(251)` is `recursion depth
limit exceeded` (in a plot, the point is undefined). gnuplot's own evaluation stack overflows earlier on a recursion
that adds a term per call (`d(n) = n == 0 ? 0 : 1 + d(n - 1)` stops at `d(249)` there); foresight sizes its stack to
the depth limit. A function that does not call itself is compiled inline, as before; one that does is compiled once
and run on a call stack.

## Strings

```gnuplot
run = 'cavity'; n = 3
file = run . '_' . n . '.dat'                  # cavity_3.dat
set title sprintf('%s, mesh %d', run, n)
plot file u 1:2 t 'res ' . substr(file, 1, 6), '' u 1:3 t sprintf('p = %.2f', p)
```

Strings are gnuplot's: in double quotes with the escapes `\t`, `\n`, `\r`, `\"`, `\\`, an octal byte `\ooo` (up to 4 digits after a
leading 0, else 3: `"\260"` the byte 176) and `\U+hhhh` kept for the enhanced text, another escaped character as it
is, or in single quotes as they are.
A variable holds a string as well as a number, a user function may return one, `?:` chooses between them.

| Operation | Value |
|---|---|
| `a . b` | `a` joined to `b`; `b` a string or an integer (`'x' . 3` is `x3`; a real is an error) |
| `a eq b`, `a ne b` | 1 or 0; both strings |
| `s[i:j]`, `s[i:]`, `s[:j]`, `s[*:j]` | characters `i` to `j` (1-based), the ends clamped to the string, empty if they cross |
| `strlen(s)`, `substr(s, i, j)`, `strstrt(s, t)` | length; `s[i:j]`; position of `t` in `s`, 0 if none |
| `words(s)`, `word(s, n)`, `trim(s)` | number of blank-separated words; word `n` (empty if none); `s` without leading and trailing blanks |
| `split(s [, sep])`, `join(A, sep)` | gnuplot 6.0's: the words of `s` (or its pieces between the occurrences of `sep`, empty ones kept, none after a last one) as an array, assigned (`A = split(s)`), printed, sized (`\|split(s)\|`) or passed to `index` and `join`; the string elements of `A` joined with `sep` between every two; arguments known when read |
| `sprintf(format, ...)` | C's `printf`: `%d %i %u %o %x %X %c` (the integer part), `%f %F %e %E %g %G` (the real), `%s`, flags `-+ 0#`, width, precision, `%%`; conversions left without an argument are copied as written |
| `gprintf(format, x)` | `x` with a [`set format`](/guide/gnuplot/axes#ticks-and-label-formats) format |
| `value("name")`, `exists("name")` | the variable's value (NaN if none); 1 if it exists |
| `rgbcolor("name")` | gnuplot 6.0's: the 24-bit RGB of a color name or `"#RRGGBB"` (`"#AARRGGBB"`: the alpha in the top byte) |
| `hsv2rgb(h, s, v)` | gnuplot's: the 24-bit RGB (an integer) of a hue, saturation and value, each clamped to 0..1 (the hue not in degrees), for `lc rgb variable` |
| `palette(z)` | gnuplot 6.0's: the 24-bit RGB of z in the current palette over the color axis as it stands (the last plot's; -10 to 10 before any; `set cbrange` in a plot command), for `lc rgb variable` |
| `int(s)`, `real(s)` | the number a string starts with, truncated or real |

Arithmetic and `==` read a string's leading number, as gnuplot: `"3" + 1` is 4, `"2" / "4"` is 0 (two integers),
`"0x10" + 0` is 16; a string without one is an error (`non-numeric string found where a numeric expression was
expected`), as is a string used as a condition. `.` binds as `+` (`"a" . 2*3` is `a6`), `eq` and `ne` as `==`.
`sprintf` converts a real from its exact binary value, as C does: `sprintf("%.2f", 2.675)` is `2.67`.

A string goes wherever a string is taken, as an expression: titles and axis labels (`set title`, `set xlabel`,
...), `set output`, `set format`, `set print`, `set multiplot title`, plot titles (`t 'col' . i`) and plot file names
(`plot file u 1:2`, `plot 'run_' . n . '.dat'`; a plot item whose constant value is a string is a file). A number
where a string goes is an error (`set title 5`). The text of data columns is [`strcol`](/guide/gnuplot/data#string-columns), times are
[`strftime` and `strptime`](/guide/gnuplot/data#time-data), the output of a shell command [`system("command")`](/guide/gnuplot/commands#shell-commands-reset-and-pause);
[arrays](#arrays) hold strings too.

## Datablocks and scripts

```gnuplot
$RUN << EOD
# iteration  residual
1  0.50
2  0.31
3  0.12
EOD
plot $RUN u 1:2 w lp, 'run.dat' u 1:2      # a datablock is plotted, fitted, stated as a file
stats $RUN u 2 nooutput
print $RUN                                 # its lines, then an empty one
load 'style.gp'                            # another script
call 'panel.gp' 'cd' 3                     # ARG1 = "cd", ARG2 = "3", ARGC = 2
eval sprintf('set title "%s"', name)       # a string run as script lines
cmd = 'set logscale y'; @cmd               # a macro
undefine tmp_* $RUN                        # forget variables and datablocks
```

Inline data, gnuplot's `'-'`: a `plot`, `replot`, `fit` or `stats` with `'-'` items reads the lines after the
statement up to one starting with `e` (blanks before it skipped), one block per `'-'` in the order written, then runs;
the auto title is `'-'` as written. A missing `e` is an error.

A datablock `$NAME << WORD` holds the lines after it, as they are (comments, blank lines and their dataset breaks
included), up to the line starting with `WORD`; it may end a line of other commands (`set polar; $P << EOD`), which
run first. Wherever a data file goes (`plot`, `fit`, `stats`, `set palette file`)
`$NAME` reads them instead; `exists("$NAME")` tells whether it is defined, `undefine $NAME` forgets it. A datablock is
read outside blocks (`do for {...}`) only. `$NAME[i]` is its line `i` (a string, from 1) and `|$NAME|` the number
of its lines, as gnuplot 6.0.

`load 'file'` runs the script `file` (a string expression), `ARG0` its name; `call 'file' arg1 ... arg9` also sets
`ARG1` to `ARG9` and `ARGC`, as gnuplot 6.0: a quoted argument as it is, a number as written (`2.50`), a variable or
a parenthesized expression its value, an integer as it is and a real as `%g` (`pi` is `3.14159`, `(n+1)` is `6`), a
word that names no variable as it is (`call 'f.gp' sub1`); `ARGV` holds the values (numbers for the numbers: `1.23e4`
is `ARG1` `"1.23e4"` and `ARGV[1]` 12300.0); the arguments not given are empty. The `ARG` variables are restored after the script, as gnuplot's (`ARGC` is 0 outside). The command line
does the same: [`foresight -c script.gp arg1 ...`](../cli#c), as `gnuplot -c`. A loaded script is watched by
`--watch` as the data files are. `eval STRING` runs the string as script lines. `@name` substitutes the value of the
string variable `name` in the statement before it runs (gnuplot's macros; outside quotes; a number variable is an
error, where gnuplot warns and drops it). `undefine a b*` forgets the variable `a` and those whose name starts with
`b`, as gnuplot: nothing after `undefine` does nothing, a word that does not start as a name (`3`, `*`) is `not a
variable name`, a name with more after it (`a*b`) is ignored; functions stay defined. The array `ARGV` holds the
arguments as strings, as gnuplot 6.0 (`|ARGV|` is `ARGC`), restored after the script too.

## Arrays

```gnuplot
array T[4]                                   # 4 elements without a value
do for [i = 1:|T|] { T[i] = 300 + 25*i }
array names = ['inlet', 'throat', 'exit']    # elements of any type, the size from the list
array P[5] = [1, 2.5]                        # 5 elements, the first two set
print T, |T|, names[2], index(names, 'exit') # [325,350,375,400] 4 throat 3
plot T w lp, T u 1:($2 - 300) t 'rise'      # an array is a file: column 1 the index, 2 the value
stats T nooutput                             # its values: STATS_mean, ...
f(i) = T[i] / 300.; plot 'probes.dat' u 1:(f($1))   # an index known on each row
```

<Plot name="cb_arrays" svg :width="560" :height="320" />

Arrays are gnuplot 6.0's: `array A[N]` makes N elements (from 1) without a value, `= [e1, ...]` gives the first
ones (`array A = [...]` sizes it by the list); an element holds a number or a string, and `A[i] = expression` sets one
(a real index is truncated, as gnuplot). In expressions `A[i]` is an element, `|A|` the size, `index(A, value)` the
first element equal to the value (0 if none): a constant index is read when the expression is compiled, an index
depending on the data row (`A[$1]`, a function argument) on each row. `print A` shows `[1,2.5,"x",]` (an element
without a value empty), `plot A` and `stats A` read the index and the value of each element as a file (an element
without a value is undefined), `undefine A` forgets it, `exists("A")` tells it exists. A redeclaration replaces the
array. Errors as gnuplot: `array index out of range`, an element without a value is an error where its value is
needed. `ARGV` is the array of the script arguments, `$NAME[i]` a datablock line and `|$NAME|` their number. An
element is also assigned inside an expression, gnuplot 6.0's `(A[i] = value)`, its value the value: `stats FILE using
(A[int($0+1)] = $2)` stores each row; an expression that assigns elements of an array reads them as they are when it
runs (`(A[1] = 7, A[1] + 1)` is 8). Not supported: arrays as function arguments.

An element without a value is gnuplot's undefined value, as is the value of a [function block](#function-blocks)
without `return`: `print` shows it as `<undefined>`, an assignment stores nothing (`x = A[1]` leaves `x` as it was),
any operation on it is `uninitialized user variable` (`A[1] + 1`). An index out of range or without a value is found
when the element is evaluated, as gnuplot: `1 ? 5 : A[9]` is 5.

### Slices

```gnuplot
array M = [3.1, 3.4, 4.0, 5.2, 6.8, 8.1, 8.9, 8.6, 7.2, 5.6, 4.1, 3.3]
print M[1:3], M[10:], |M[4:6]|               # [3.1,3.4,4.0] [5.6,4.1,3.3] 3
S = M[7:9]; array W = M[:3]                  # copies, arrays themselves
print M[7:9][2], M[0:2], M[5:4]              # 8.6 [3.1,3.4] []
```

<Plot name="cb_slices" svg :width="560" :height="320" />

`A[i:j]` is the array of the elements `i` to `j`, as gnuplot 6.0: an empty or `*` end is the first or the last
element, the ends are clamped to the array (`A[0:9]`), `i > j` is the empty `[]`. A slice prints, sizes (`|A[i:j]|`),
indexes (`A[i:j][k]`) and makes a copy (`B = A[i:j]`, `array B = A[i:j]`; `B = A` copies too). Its ends are known when
the expression is compiled (no column, no function argument), and a slice is no number: `A[1:2] + 1` is an error
(gnuplot's is an internal one).

## Function blocks

```gnuplot
function $cbrt << EOF
  local r = ARGV[1] > 1 ? 1.0 * ARGV[1] : 1.0
  do for [k = 1:50] {
    d = (r**3 - ARGV[1]) / (3*r**2)
    r = r - d
    if (abs(d) < 1e-12) { return r }
  }
  return r
EOF
print $cbrt(27)                              # 3.0
plot $cbrt(x)                                # in plotted functions and using fields too
```

<Plot name="cb_function_blocks" svg :width="560" :height="320" />

A function block is gnuplot 6.0's: `function $NAME << WORD`, then lines of script up to one starting with WORD. A call
`$NAME(args)` in any expression (printed, assigned, plotted, a `using` field) runs those lines with `ARGC` the number of
arguments and the array `ARGV` their values (both restored after); named parameters, `function $NAME(a, b) << WORD`,
are local variables holding the arguments given (`local a = ARGV[1]`, as gnuplot); `return EXPR` ends the block with its value, from
inside loops and `if` blocks too, and a block without one gives the [undefined value](#arrays). `local NAME = ...` (or
`local array A[N]`) makes a variable that the end of the block restores; the other variables a block sets stay set,
as gnuplot. Blocks may call themselves and each other (250 deep at most). `print $NAME` shows `function $NAME( )` and
its lines, `undefine $NAME` forgets it, `$nosuch(1)` is gnuplot's `Not a function block`. Outside a block, `local` is a
plain assignment and `return` ends the script file being read (a `load` returns to its caller), as gnuplot. As in
gnuplot, the arguments come as `ARGV[i]`, not `ARG1` (which keep the caller's values). gnuplot 6.0.0 fails on a block
called inside `set title sprintf(...)`; foresight runs it, and through a variable both do.

## Blocks and loops

```gnuplot
do for [i = 1:3] {
   set output sprintf('panel_%d.svg', i)
   plot 'run.dat' u 1:(column(i + 1)) t word('continuity momentum energy', i)
}
k = 0
while (k < 3) { k = k + 1; print k }
if (exists('STATS_mean')) { print STATS_mean } else { print 'no stats yet' }
```

As gnuplot's: `do for [i = a:b[:c]] { ... }` runs the block for each integer from `a` to `b` by `c` (bounds
truncated to integers, a negative step counts down, an empty range none), `do for [w in "x y z"] { ... }` for each
word of a string; clauses may follow one another, `do for [w in "a b"] for [i = 1:2] { ... }`, the last one varying
fastest. The loop variable is local to the loop: its value before is restored afterwards, or it is removed.
`while (c) { ... }` runs while `c` is not 0, `if (c) { ... } else if (c) { ... } else { ... }` the first block whose
condition holds; `else` follows `}` on the same line. `break` leaves the loop (the whole `do`, all its clauses),
`continue` goes on with the next value. A block may span lines, with statements on new lines or separated by `;` and
comments inside it. A string as a condition and an unbounded range (`[i = 1:*]`) are errors.

gnuplot's old one-line form `if (c) command; ...; [else command; ...]` runs too, as gnuplot 6.0 still does: the rest
of its line is its own, the commands up to an `else` when the condition holds, those after it otherwise (`else if`
chains); inside a block it is gnuplot's error, `Old-style if/else statement encountered inside brackets`.

## Functions

A plot item that is not a quoted file is a function of `x`, with the operators, functions and rules of
[`using` expressions](/guide/gnuplot/data#expressions-in-using), without columns:

```gnuplot
plot 'run.dat' u 1:2, 1e-1 * exp(-x/5) t 'model'
plot sin(x)/x, x > 0 ? log(x) : 1/0
set samples 400; plot x * sin(1/x)
```

As gnuplot, a function is sampled at `set samples` points (100) evenly over the x range before its extension to the
ticks: the `xrange` ends where set, else the extent of the data of the whole plot, else [-10:10]. On a log x axis the
samples are evenly spaced in log x. Undefined values (`1/0`, `log(-1)`) are gaps. Functions are drawn `with lines`
by default whatever `set style data` says; `set style function points` (or `linespoints`) changes it; `with boxes`
and `with filledcurves` fill the samples as data (a `y=V` base included), error bars are not usable. The expression runs up to the first item option, so blanks may separate its terms: `plot x * 2 + 1 t 'line'`.
`set dummy t` renames the variable (`plot t**2`), as gnuplot; `unset dummy` and `reset` bring back `x`.

`sum [i=a:b] term` adds the term for each integer `i` from `a` to `b` (ends known when the expression is read:
numbers or variables), integers staying integers and an empty range 0, as gnuplot; sums nest, and go into user
functions and plotted functions (at most 10000 terms, not in function blocks):

```gnuplot
print sum [i=1:10] i                         # 55
square(x) = 4/pi * sum [k=1:n] sin((2*k-1)*x)/(2*k-1)
plot n = 3, square(x), n = 15, square(x)
```

`NaN` is predefined, as `pi`: `plot NaN with boxes title "legend only"`.

In the HTML page a zoom does not resample: the samples are those of the original range.

On a [polar](/guide/gnuplot/axes#polar-plots) panel a function is r of `t`, sampled over `trange` (a full turn by default) as gnuplot:
`plot 1 + cos(t)`.

### Sampled pseudo-files `'+'` and `'++'`

```gnuplot
plot '+' using 1:(sin($1)):(sin($1)+0.3) with filledcurves
plot sample [t=0:2*pi:0.25] '+' using (3*cos(t)):(sin(t)) with linespoints
set urange [-2:2]; set vrange [-2:2]
plot '++' using 1:2:($2*0.4):(-$1*0.4) with vectors
```

As gnuplot 6.0, the pseudo-file `'+'` is a data file of one column, the samples of a variable: `set samples` values
evenly over the item's sampling range, else over `trange` in parametric and polar modes or when it is set, else over
the x range (the `xrange` ends where set, else the extent of the data plotted before it in the same command, else
[-10:10]; evenly in log x on a log x axis). The variable is the dummy (`x`, or the one of `set dummy`), and its value
is that of column 1 in the `using` expressions: `'+' using 1:(f(x))`. An item's sampling range names it and may give
the interval: `[t=-3:25:1.5] '+' using (t):(f(t))` samples from -3 by 1.5 while inside the range. Before the first
item the range follows the keyword `sample`, else it would be the plot's x range: `plot sample [i=1:10:1] '+' ...`,
also after the plot's own ranges: `splot [-2:2] [-2:2] sample [h=1:5] '+' using (cos(h)):(sin(h)):(h)`.

`'++'` is a grid of two columns, u and v: `set samples` values over `urange`, by `set isosamples` (its second value)
values over `vrange` (both [-5:5] by default), v from its maximum down, the scan lines apart (a blank line). The
variables are the splot's dummy variables, gnuplot's: `x` and `y` (`u` and `v` in parametric mode, the `set dummy`
names if set), or those its two ranges name: `splot '++' using 1:2:(sin(x)*cos(y))`,
`sample [a=0:2:0.5][b=-1:1:0.5] '++' using (a):(b):(a*b)`.
`unset urange`, `unset vrange` and `unset trange` restore the defaults.

## Special functions

gnuplot 6.0's real special functions, with its own algorithms (ports of its C code), so their values are gnuplot's
to the last digit:

```gnuplot
plot [0:20] besj0(x), besj1(x), besjn(2, x)
plot [-3:3] erf(x), norm(x), invnorm(norm(x))
print gamma(4.5), lgamma(100), igamma(2, 1), ibeta(2, 3, 0.4), lambertw(1), EllipticK(0.5)
```

| Functions | |
|---|---|
| `round(x)` | the nearest integer, halves away from zero |
| `cbrt(x)`, `asinh(x)`, `acosh(x)`, `atanh(x)` | cube root, inverse hyperbolic functions |
| `erf(x)`, `erfc(x)`, `inverf(y)` | the error function, its complement, its inverse |
| `norm(x)`, `invnorm(p)` | the normal distribution function and its inverse |
| `gamma(x)`, `lgamma(x)` | Γ and ln \|Γ\| |
| `igamma(a, x)`, `uigamma(a, x)`, `invigamma(a, p)` | the regularized incomplete gamma functions, lower and upper, and the inverse of the lower |
| `ibeta(a, b, x)`, `invibeta(a, b, p)` | the regularized incomplete beta function and its inverse |
| `besj0(x)`, `besj1(x)`, `besjn(n, x)`, `besy0(x)`, `besy1(x)`, `besyn(n, x)` | Bessel functions of the first and second kind |
| `besi0(x)`, `besi1(x)`, `besin(n, x)` | modified Bessel functions of the first kind |
| `lambertw(x)` | the principal branch of Lambert's W |
| `airy(x)` | the Airy function Ai |
| `expint(n, x)` | the exponential integral E<sub>n</sub> |
| `EllipticK(k)`, `EllipticE(k)`, `EllipticPi(n, k)` | the complete elliptic integrals |
| `voigt(x, y)` | the Voigt profile |
| `zeta(s)` | Riemann's ζ |
| `SynchrotronF(x)` | the synchrotron function |

The orders `n` of `besjn`, `besyn`, `besin` and `expint` must be integers (`besjn(2.0, x)` is an error), as gnuplot.
Outside its domain a function is undefined, a gap in a plot, as gnuplot's undefined value; so are the results gnuplot
gives as infinities, foresight's values being finite real numbers (the complex values of `asin`, `acos`, `acosh` are
gnuplot's, see [Expressions](/guide/gnuplot/data#expressions-in-using)). The complex special functions of gnuplot (`Ai`, `BesselJ`, ...) and those of libcerf (`VP`, `erfi`, `FresnelC`, ...) are not
supported. Built with gfortran the values are gnuplot's bit for bit; other compilers' mathematical libraries
(nvfortran's) differ by a few units in the last place in some ranges.
