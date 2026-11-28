---
title: Data
---

# Data

Columns, expressions in `using`, headers, strings, times, tables, smoothing and bins. Part of the [gnuplot subset](/guide/gnuplot-subset) reference.

## Expressions in `using`

A field in parentheses is an expression evaluated on each row, with gnuplot's semantics:

```gnuplot
plot 'run.dat' using ($1/3600):($2*1e3)             # hours, milli-units
plot 'run.dat' using 1:($3 > 0 ? log10($3) : 1/0)   # 1/0 drops a point: a gap
plot 'run.dat' using 0:(sqrt($2**2 + $3**2)) with lines
```

| | |
|---|---|
| Columns | `$N` or `column(N)`, `$0` is the point number; `column()` takes an expression: `column($1 + 1)`, or a header name: `column("residual")`; `column(-1)` the block, `column(-2)` the dataset; the text of a column: [`strcol(N)`](#string-columns) |
| Operators, loosest first | `?:` · `\|\|` · `&&` · `\|` · `^` · `&` · `==` `!=` · `<` `<=` `>` `>=` · `<<` `>>` · `+` `-` · `*` `/` `%` · unary `-` `+` `!` `~` · `**` |
| Functions | `abs acos arg asin atan atan2 ceil conj cos cosh exp floor imag int log log10 real sgn sin sinh sqrt tan tanh`; gnuplot's [special functions](/guide/gnuplot/scripting#special-functions) (`erf`, `gamma`, `besj0`, `lambertw`, ...); the [string functions](/guide/gnuplot/scripting#strings), [`strcol`, `columnhead`](#string-columns), [`timecolumn`, `strftime`, `strptime`, `time`, `tm_*`, `weekdate_iso`](#time-data), [`system`](/guide/gnuplot/commands#shell-commands-reset-and-pause), [`index`](/guide/gnuplot/scripting#arrays), `rand(x)` (gnuplot's generator: `rand(0)` the next number, `rand(-1)` reset, `rand(N)` seeded; the same numbers as gnuplot), `exists("name")` (old name `exist`), `voxel(x,y,z)` (the active [voxel grid](/guide/gnuplot/3d#voxel-grids)) |
| Arrays | `A[i]` an element, `A[i:j]` a slice, `\|A\|` the size, `$NAME[i]` a datablock line, see [Arrays](/guide/gnuplot/scripting#arrays) |
| Function blocks | `$f(args)`, see [Function blocks](/guide/gnuplot/scripting#function-blocks) |
| Constants | numbers (`2`, `1.5`, `.5`, `1e-3`, hexadecimal `0xff`, octal `017`), `pi`, complex `{re, im}` and `I` (`{0,1}`) |
| Assignments | `name = value` (its value the value, right associative: `a = b = 0`) and gnuplot's serial evaluation `(a, b)`, each evaluated, the last the value: `using 1:(sum = sum + $2, sum)`; run when evaluated, on each row |

The rules are gnuplot's, checked against gnuplot 6.0:

- `**` is right associative and binds tighter than a unary minus: `-2**2` is -4, `2**3**2` is 512.
- Integer constants stay integers: `1/2` is 0 and `-5/2` is -2, but `1/2.` is 0.5; an integer overflow gives a real.
  Columns are reals, so `$2/2` is a real division. `floor`, `ceil`, `int`, `sgn`, comparisons and logical operators
  give integers.
- `&&`, `||` and `?:` evaluate only the operand they need: `$2 > 0 && log($2) > 1` never takes the log of a
  negative, `1 ? 5 : A[9]` is 5.
- The bitwise operators `&` `|` `^` `~` `<<` `>>` take 64-bit integers, with C's precedence: `5 & 3 == 1` is
  `5 & (3 == 1)`, 0. A real or a string is an error, `non-integer passed to boolean operator`; columns are reals, so
  write `int($3) & 2`. The shifts are gnuplot's on x86: the count modulo 64, `>>` logical (`-8 >> 1` is
  9223372036854775804). `0xff` and `017` (octal; `08` is an error) are integers, a real past the largest one.
- A missing cell, a division by zero, a domain error (`acos(2)`, `log(0)`) or an overflow make the point undefined:
  a gap in the line, as gnuplot's `1/0`. `set overflow undefined|NaN` makes an integer overflow undefined or NaN;
  `unset overflow` wraps `+` and `-` around (two's complement), as gnuplot. `int` beyond 9.22e18 and `floor`, `ceil`
  beyond 2^52 give NaN, as gnuplot.
- Values are complex, as gnuplot's: `{re, im}` and `I` are constants; `+ - * / **` follow gnuplot's formulas (powers in
  polar form: `(-8)**(1./3)` is `{1.0, 1.732...}`); `abs`, `arg`, `real`, `imag`, `conj`, `sqrt`, `exp`, `log`,
  `log10` (also of negative reals: `sqrt(-4)` is `{0.0, 2.0}`), `sin`, `cos`, `tan`, `sinh`, `cosh`, `tanh`, `asin`,
  `acos`, `atan`, `asinh`, `acosh`, `atanh` take complex arguments (gnuplot 6.0's formulas and branch cuts; `asin` and
  `acos` off [-1:1] and `acosh` below 1 give complex values too: `acosh(0.5)` is `{0.0, 1.047...}`), the other
  functions of one are undefined; comparisons `<`... compare the real parts, `==` `!=` both.
  `print` shows `{re, im}`. A plotted value whose imaginary part exceeds 1e-8 is undefined (gnuplot's `set zero`):
  `plot abs(A(w)), 180/pi*arg(A(w))` plots a transfer function.
- An assignment inside an expression sets the user variable when it runs: on each data row in `using`, so a running
  sum advances along the file; a variable assigned in a user function body is read when run wherever it is used
  (`avg5(x) = (shift5(x), (b1+b2+b3+b4+b5)/5)`), and so is one assigned in a `using` field by every field, the next
  ones (`using 2:1:(T = $4 + $5, sqrt(T)):($6/T)`) and the earlier ones, which read the previous row's value, as gnuplot
  evaluates the fields in order (`plot r=0 $D using (r):(dr = $2, r = r + dr, dr)`: the running start of each row);
  `A[i] = value` assigns an element of an [array](/guide/gnuplot/scripting#arrays).

A field must be a column number or an expression starting with a parenthesis (read whole, `($1+$2+$3)/3`), as in
gnuplot: `using 1:$2` and `using 1:2*3` are errors. A spec broken after a colon by a line continuation (`using 2:1:\` and the next line) is joined, as gnuplot, and
so are blanks around its colons (`using (T(3)) : ($0)`). A format string after the spec reads the fields of each line
by scanf conversions, as gnuplot: `using 1:2:3 "%lf %lf %lf"` (blank separated `%lf`, `%f`, `%le`, `%e`, `%g`). Syntax errors point at the character: `using: unexpected ")" at character 6 of "($2 +)"`.

Beyond gnuplot, foresight accepts `%` and the logical operators on reals, and an overflow gives a gap where gnuplot
stops the plot. Expressions take [user variables and functions](/guide/gnuplot/scripting#user-variables-and-functions) and
[strings](/guide/gnuplot/scripting#strings), the text of columns included ([`strcol`](#string-columns)), and
[function blocks](/guide/gnuplot/scripting#function-blocks).

## String columns

```gnuplot
plot 'runs.dat' u 0:2:xtic(strcol(1) . ' K')                          # tick labels built from the text of column 1
plot 'runs.dat' u 2:3:(sprintf('%s: %.1f', strcol(1), $3)) w labels    # labels mixing text and numbers
plot 'runs.dat' u 0:(strcol('solver') eq 'gmres' ? $2 : 1/0)           # the rows chosen by their text
plot 'runs.dat' u 0:2:xtic(columnhead(3))                              # every tick named by a header cell
```

| Function | Value |
|---|---|
| `strcol(N)`, `stringcolumn(N)` | the text of column `N` of the row (quotes removed); `N` a header name: `strcol("solver")` |
| `columnhead(N)`, `columnheader(N)` | the text of column `N` in the first row of the dataset |
| `column(-1)`, `column(-2)` | the block of the row within its dataset (blocks are parted by one blank line) and its dataset (two), from 0 |
| `timecolumn(N[, "format"])` | column `N` read as a [time](#time-data) |

As gnuplot, `strcol("name")` and `columnhead(N)` read the first row without making it a header (it stays a row, counted
by `$0`), unlike `column("name")`; a column beyond the end of its row is undefined (gnuplot stops the plot). The text
of `labels` and of `xtic(...)` is any string expression; a number there gives the text of the first column the
expression reads, as gnuplot (`u 1:2:($2*2) w labels` writes column 2 as it is), or the number as `%g` when it reads
none. The cell texts are kept in memory only for the items that read them. Labels and tick labels longer than 128
characters are cut.

## Tables

```gnuplot
set table $SMOOTH                            # or a file, 'smooth.dat' [append]; bare, the standard output
plot 'noisy.dat' u 1:2 smooth csplines
unset table
plot 'noisy.dat' u 1:2 w p, $SMOOTH w l      # the tabulated curve, plotted
```

<Plot name="cb_table" svg :width="560" :height="320" />

With `set table` a plot draws nothing: it writes the points of its items as gnuplot 6.0 tabulates them, byte for
byte, a block per item: `# Curve K of N, M points`, `# Curve title: "..."`, the column names, then a row per point in
the axis formats (`set format`, `% h` by default; `%h` writes `%g`'s plain `e+08` exponent there, as gnuplot's text
tables) and a flag, `i` inside the ranges, `o` outside a fixed range, `u`
undefined. The columns are `x y type`, with `ylow yhigh` for y error bars, `xlow xhigh` for x error bars and boxes,
both for xy error bars, `y1 y2` for a band of filled curves, `x y label` for labels. A plot of the functions writes
their samples, of smoothed data the smoothed points. The table goes to a file (emptied unless `append`), a datablock
(plotted, fitted, stated afterwards) or the standard output; `unset table` draws again.

### With table

```gnuplot
set table $SLOW                              # set table [where] [append] [separator whitespace|tab|comma|"c"]
plot 'steptimes.dat' u 1:2 w table if $2 > 1.6
unset table
plot 'steptimes.dat' u 1:2 w l, $SLOW u 1:2 w p
```

<Plot name="cb_with_table" svg :width="560" :height="320" />

`plot ... with table` writes the rows of a data item as text, where `set table` sends them, as gnuplot 6.0: each
`using` field after a blank, a number as `%g` (`set format` does not apply), `nan` if undefined, a string as it is
(`strcol(4)`, `sprintf(...)`), the fields joined by the separator, tab by default (`set table separator comma`, kept
until changed). Without `using`, the leading numeric cells of each row. Into a datablock a string field has no blank
and the separator one before it, gnuplot's layout (`a , 1 , 2`). `with table if CONDITION` writes the rows where the
condition holds; `index`, `every` and the column header names apply; blank lines and comments are not written and no
row is left out for a bad cell. A function with table writes nothing (gnuplot's warning), and without `set table` it
is gnuplot's error, `'with table' requires a previous 'set table'`.

### Markdown tables

```gnuplot
set table 'runs.md' markdown                 # every table of the plots below a Markdown pipe table
set datafile columnheaders
plot 'runs.dat' using (strcol(1)):"error":(sprintf('%.1f s', $4)) with table
unset table
```

```markdown
| case | error | (sprintf('%.1f s', $4)) |
| --- | --: | --- |
| coarse | 0.012 | 0.5 s |
```

A foresight extension for reports: `set table ... markdown` (until the next `set table`) or `with table markdown` (one
item) writes the tables as Markdown pipe tables (GitHub's, which VitePress, pandoc and GitLab render). The header of a
`with table` is the column names of the header row (`set datafile columnheaders`, `columnheader`, a named column) for
the fields that read a column whole (`2`, `"error"`, `strcol(1)`, `$3`), the field as written for the others
(`($3*1e3)`), the column number without `using`; numbers are right aligned, a `|` in a cell escaped, a blank line ends
the table. A plot's table (`set table` with another style) is a table per series, its title a paragraph before it, the
columns of gnuplot's text table without `type`, numbers in the axis formats (`set format y '%.3f'`), the breaks of a
curve left out. `splot` tables stay text: `markdown` refuses them. [F2. Tables](../../manual/paths/f-reports/02-tables)
and [F3. The report](../../manual/paths/f-reports/03-the-report) use them in a report.

## Time data

```gnuplot
set xdata time
set timefmt '%Y-%m-%d %H:%M:%S'           # the time spans two blank-separated columns: y is column 3
plot 'log.dat' u 1:3 w l                  # x ticked in whole hours, labels invented from the range
set format x '%H:%M'                      # or set: a time format
set xrange ['2024-03-01 06:00:00':'2024-03-01 18:00:00']
set xtics '2024-03-01 06:00:00', 3*3600   # tick positions as times, steps in seconds
plot 'log.dat' u (timecolumn(1) + 3600):3  # an expression on a time
print strftime('%a %d %b %Y %H:%M', strptime('%Y-%m-%d', '2024-03-01') + 5400)   # Fri 01 Mar 2024 01:30
```

As gnuplot, a time is the number of seconds since 1970-01-01 00:00 UTC (proleptic Gregorian calendar, no leap
seconds, no time zone). `set xdata time` (`ydata`, `x2data`, `y2data`) reads the x (y) field of each plot item with the
`timefmt`, a time spanning as many blank-separated columns as the format has blanks (as gnuplot: `using 1:3` above);
an unreadable time is a gap. Range ends, tick positions and [label](/guide/gnuplot/text#labels-arrows-and-objects) coordinates take time
strings on a time axis, read with the `timefmt`.

The ticks are gnuplot 6.0's: the step is the automatic one rounded to whole seconds, minutes, hours (1, 2, 3, 4, 6,
12, ...: duodecimal steps), days, weeks, months or years, the ticks fall on whole units of it (days at 0 AM, months on
the 1st), an autoscaled end extends to the step and then to a whole unit. A fixed step (`set xtics 3600`, an
expression: `3*3600`) is in seconds. Without a time format the labels are gnuplot's invented ones: within a day `%H:%M`
(`%H:%M:%S` under a minute, `%M:%S` within an hour), over days `%d/%m` (or `%m/%d` when the `timefmt` has the month
first) and `%H:%M` on a second line below a week, the year (`%y`, `%Y` across centuries) when the range crosses years.
`set mxtics N` divides each step, `set mxtics` gnuplot's automatic minor time steps; none by default. `set mxtics time
N UNITS` (gnuplot 6.0) puts a minor tick every N `seconds`, `minutes`, `hours`, `days`, `weeks` (multiples of N units
since 1970, weeks from Thursday 1 January 1970), `months` or `years` (the first day of every N-th one, counted from
1970): `set mxtics time 1 months` marks the 1st of every month, whatever its length. The HTML page regenerates the time
ticks after a zoom by the same rules (the `time` minor ticks excepted) and shows the cursor position as a date.

<Plot name="cb_time_minor" svg :width="640" :height="260" />

| Conversion | `strftime` writes, `strptime` reads |
|---|---|
| `%Y` `%y` `%m` `%d` `%j` | the year (4 digits, or 2: 69..99 the 1900s), month, day, day of the year |
| `%H` `%M` `%S` | hours, minutes, seconds (`%.3S` with decimals, rounded as gnuplot's time.c: 47.0999... is 47.100; `strptime` reads a fraction) |
| `%z` `%Z` | `strptime`: a zone offset (`Z` or [+-]hh[:]mm) taken off (12:24+01:00 is 11:24), a zone name skipped; `strftime` writes nothing, as gnuplot |
| `%b` `%B` `%a` `%A` | month and weekday names, abbreviated or full (`strptime` reads either, skips the weekday) |
| `%s` | the seconds since 1970 |
| `%p` | `am`, `pm` (`strptime`: `pm` adds 12 hours) |
| `%tH` `%tM` `%tS` | elapsed hours, minutes, seconds: the largest unit of the format unbounded (`%tH:%tM` of 361800 s is `100:30`) |
| `%I` `%k` `%l` `%D` `%F` `%T` `%R` `%r` `%w` `%U` `%W` `%%` | `strftime` only, as C's (`%p` lowercase, as gnuplot) |

`strftime("format", t)` writes a time, `strptime("format", "text")` reads one (undefined if the text does not match),
`timecolumn(N[, "format"])` reads column N (with the `timefmt` without a format), `time(0)` is the time now (`time(0.0)`
with its fraction, `time("format")` as text), taken when the expression is read. `tm_sec(t)`, `tm_min`, `tm_hour`,
`tm_mday`, `tm_mon`, `tm_year`, `tm_wday`, `tm_yday` give the fields of a time (UTC; `tm_mon` and `tm_yday` from 0,
`tm_wday` 0 on Sunday), `tm_week(t, 0)` its ISO 8601 week (`1` the CDC/MMWR epidemiological week, from Sunday), and
`weekdate_iso(year, week [, day])` / `weekdate_cdc(...)` the time of a week date (2004-W01-1 is 29 December 2003), as
gnuplot 6.0. In `strptime` a blank matches any run
of blanks; fields take up to their width in digits (`%Y%m%d` reads `20240301`) and may overflow (`25:70` is 26:10).
Conversions gnuplot does not know write nothing, as gnuplot's. `set format x "%H:%M" timedate` makes the x axis a time
axis for its ticks and labels without reading the data as times, `numeric` turns it back; `set xtics time` (gnuplot's
`timedate`) and `set xtics numeric` do the same. `set mxtics time N UNIT` takes gnuplot's abbreviations (`5 min`).
Not supported: time zones but in `strptime`, `%tH` with decimals.

## Smoothing

`smooth FILTER` replaces the points of a data item by a filtered series, as gnuplot computes it. Each run of points
(a block of the file, ended also by an undefined point or by a value not placeable on a log axis) is sorted by x, and
its points of equal x are merged into one:

| Filter | y of the merged point |
|---|---|
| `unique` | the mean of their y |
| `frequency` | the sum of their y: with `using (BIN):(1)`, a histogram ([`bins`](#bins) bins the values itself) |
| `fnormal` | `frequency` divided by the sum of y over the whole item |
| `cumulative` | the sum of y up to that x, within the run |
| `cnormal` | `cumulative` divided by the sum of y over the whole item: an empirical distribution |

```gnuplot
plot 'run.dat' u 1:2 smooth unique                              # iterations repeated by a restart: averaged
plot 'run.dat' u (floor($5/0.02)*0.02):(1) smooth frequency     # histogram of column 5, bins 0.02 wide
plot 'run.dat' u 5:(1) smooth cnormal                           # its empirical distribution
```

The [cookbook](/manual/cookbook#histogram-and-distribution) draws the last two.

The curve filters replace each run by `set samples` points (100 by default), as gnuplot 6.0 computes them:

| Filter | Curve |
|---|---|
| `csplines` | the natural cubic spline through the points sorted and merged as above (at least 3), sampled from the first x to the last within the x range |
| `acsplines` | the smoothing spline of Reinsch through them (at least 4): `using X:Y:W` weights each point, larger weights draw the curve closer (1 without) |
| `bezier` | the Bézier curve with the points as control points, in the file order: it starts and ends on the first and last point |
| `sbezier` | the same after sorting and merging the points |
| `mcsplines` | the monotone cubic spline of Fritsch and Carlson through the points sorted and merged (at least 2): no overshoot, it rises and falls only where the points do; sampled at the points and at max(`set samples`, 2n) points between the first and last x within the x range; of the first block of the item only, as gnuplot 6.0 |
| `path` | gnuplot 6.0's along-path spline: each set of points (apart at blank lines), in its order and not sorted, a natural cubic spline of x and of y against the path length (scaled by the x and y ranges), sampled at `set samples` points over the path; a set whose ends meet is closed, the spline wrapping around, and `with filledcurves closed` closes every set; at least 3 points a set |
| `kdensity` [`bandwidth B`] | the Gaussian kernel density of the x values weighted by y, over the x range: `using X:(1)`, or `using X` alone, for a density of counts; the bandwidth is gnuplot's default, (4/3n)^(1/5) times the standard deviation of x, unless given |

```gnuplot
plot 'run.dat' u 1:5 smooth csplines                  # a spline through the drag coefficient
plot 'run.dat' u 1:5:(0.1) smooth acsplines           # smoothed: small weights, a smooth curve
plot 'timestep.dat' smooth mcsplines                  # a time step through its plateaus, never beyond them
plot 'run.dat' u 5:(1) smooth kdensity bandwidth 0.01 # the distribution of column 5
```

The runs stay separate lines. `smooth` applies to `lines`, `points` and `linespoints`; with error bars or on a
function it is an error (gnuplot ignores the extra columns, or the filter); `acsplines` reads a third column as the
weights. A single `using` column (or a file of one column) is x, each point of weight 1, for `frequency` and
`kdensity`, as gnuplot: `using 5 smooth kdensity` is `using 5:(1) smooth kdensity`; the other filters read it as y
at the point numbers. `path` also applies to `filledcurves`. `unwrap` and the others are [not
supported](/guide/gnuplot-subset#not-supported).

### Bins

`bins` sorts the x values into bins of equal width and plots each bin as one point at its centre, as gnuplot 6.0:

```gnuplot
plot 'FILE' using X[:Y] bins[=N] [binrange [LO:HI]] [binwidth=W] [binvalue=sum|avg] [with STYLE]
plot 'FILE' using X[:Y] smooth bins[=N] ...       # the same
```

| Option | Bins |
|---|---|
| `bins` | `set samples` bins (100 by default) |
| `bins=N` | N bins (at least 2), the first centred on the smallest x, the last on the largest |
| `binrange [LO:HI]` | the centres of the first and last bins at LO and HI (numbers or constant expressions, `[xlow:xhigh]`), whatever the data: values beyond the outer edges fall in no bin |
| `binwidth=W` | bins W wide, as few as span the range, centred on it (N is then ignored) |
| `binvalue=avg` | the mean of the y of each bin (two or more points), not their sum |

With one column each value counts 1: a histogram. With `using X:Y` each point adds its y to its bin. A value on the
boundary of two bins falls in the upper one; `set xrange` does not change which bin a point falls in. The x
autoscale reaches the outer edges of the bins and the y autoscale includes 0, as gnuplot. The style is the data style
(`set style data`, `lines` by default): `with boxes` draws a histogram whose boxes touch. `bins` does not go with
`smooth` nor `lc variable`, and needs `using X` or `using X:Y`; its options read numbers, not expressions.

```gnuplot
plot 'steptimes.dat' u 2 bins binwidth=0.02 with boxes        # wall times per step, 0.02 s bins
plot 'run.dat' u 5:2 bins=20 binvalue=avg with histeps        # the mean residual per drag coefficient bin
```

The [cookbook](/manual/cookbook#a-histogram-of-a-sample) overlays the density of the same sample.

## Column headers

```gnuplot
set datafile separator comma
plot 'run.csv' using 1:"residual" title columnhead, '' using "iteration":(column("cd")*1e3)
set key autotitle columnhead       # every untitled item takes the header of its y column
plot 'immigration.dat' u "Denmark" t col           # a header name alone, quoted
```

As in gnuplot, the first row of each dataset is a header as soon as an item uses it: a quoted name in `using` (also
in `column("name")`), `title columnhead`, or `set key autotitle columnhead`. It is then neither a point nor counted by
`$0`; otherwise it is an ordinary row, whose words are missing values. A name is looked up in the header of the
dataset each row belongs to; a name no selected dataset has is an error. `title columnhead` takes the header of the
first column the y field reads (`($3*2)` gives the header of column 3), `columnhead(N)` of column `N`; no header, no
title. Quoted header cells may hold blanks: `"the res"`. `set key noautotitle` leaves untitled items, functions
included, out of the key. `set datafile columnheaders` makes the first row of every dataset a header, `notitle
columnhead` that of one item.
