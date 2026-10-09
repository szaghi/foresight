---
title: gnuplot Subset
---

# gnuplot Subset

foresight interprets a subset of the gnuplot command language. Everything outside it is an error naming the command
and its line (`script.gp:12: unsupported command "splot"`), never silently ignored: a script that runs is a script
that did what it says.

## Syntax

- One statement per line, or several separated by `;`
- `#` starts a comment (outside quotes)
- A line ending with `\` continues on the next one
- Strings in single quotes are literal; in double quotes `\t` is a tab and `\` takes the next character literally
  (`\"`, `\\`)
- Keywords accept gnuplot abbreviations: the shortest accepted form is in bold below

## Commands

| Command | Effect |
|---|---|
| **p**lot *items* | replace the current plot and render it to the output |
| **rep**lot [*items*] | render the last plot again (re-reading its data), optionally adding items |
| **se**t *option* | set an option |
| **uns**et *option* | reset an option |

## `set` / `unset` options

| Option | `set` | `unset` |
|---|---|---|
| **tit**le `"text"` | panel title | no title |
| **xl**abel / **yl**abel / **y2l**abel `"text"` | axis label (`y2` on the right) | no label |
| **xr**ange / **yr**ange / **y2r**ange `[min:max]` | axis range; `*` or empty autoscales an end; `min > max` reverses | — |
| **log**scale [*axes*] [`10`] | base-10 log axes; *axes* concatenates `x`, `y`, `y2` (`y`, `xy2`), all when absent | linear axes |
| **gr**id | grid at major ticks | no grid |
| **k**ey [`on`\|`off`] [`left`\|`right`\|`center`] [`top`\|`bottom`\|`center`] [`box`\|`nobox`] [`autotitle` [`columnhead`]\|`noautotitle`] | show the key, inside the plot area (top right by default), see [below](#key); untitled items: as written, by [column header](#column-headers), or none | hide the key |
| **xti**cs / **yti**cs / **y2ti**cs [`auto` \| `STEP` \| `START,STEP[,END]`] [`mirror`\|`nomirror`] | tick positions, see [below](#ticks-and-label-formats); `y2tics` is off by default, see [below](#second-y-axis) | no ticks, labels nor grid lines |
| **for**mat [*axes*] [`"format"`] | tick label format of the *axes* (as `logscale`), see [below](#ticks-and-label-formats) | default labels |
| **dataf**ile **sep**arator [`whitespace`\|`tab`\|`comma`\|`"chars"`] | cell separators of data files, see [Data Files](data-files#separators-csv); no argument: whitespace | whitespace (`unset datafile`) |
| **sam**ples `N`[`,M`] | points of each [function](#functions), 100 by default; `M` is accepted and ignored | — |
| **st**yle **d**ata `STYLE` | style of data items without `with` | — |
| **st**yle **f**unction `STYLE` | style of [functions](#functions) without `with`: `lines`, `points`, `linespoints` | back to `lines` |
| **st**yle **l**ine `N` [`lc` ...] [`lt N`] [`lw W`] [`dt N`] [`pt N`] [`ps S`] | line style `N`, used by `ls N` | — |
| `readout` [`on`\|`off`] [`left`\|`right`\|`center`] [`top`\|`bottom`\|`center`] [`horizontal`\|`vertical`] [`opaque`\|`noopaque`] [`size H`] | foresight extension: where and how the [readouts](#readouts) of the panel are drawn | readouts not drawn |
| **ou**tput `"file"` | output file: `.svg`, `.html`, `.txt`, `-` | — |
| **te**rminal `svg`\|`html` [**si**ze `W,H`] [**ref**resh `S`] | output format, size in px, HTML reload period | — |
| **te**rminal `dumb` [**si**ze `COLS,ROWS`] [`mono`\|`ansi`\|`ansi256`\|`ansirgb`] | text output, 79 x 24 by default, on the standard output; the series in ANSI colors, see [Output Formats](output-formats#text) | — |
| **te**rminal `block` [`half`\|`quadrants`\|`sextants`\|`braille`] [**si**ze `COLS,ROWS`] [`mono`\|`ansi`\|`ansi256`\|`ansirgb`] | text output drawn with Unicode block or Braille characters, 2 x 2 dots per character by default (`quadrants`), see [Output Formats](output-formats#block-characters) | — |
| **multi**plot [**lay**out `R,C`] [**t**itle `"text"`] | grid of panels, or panels in their `origin`/`size` boxes without layout, see [below](#multiplot) | back to one panel |
| **or**igin [`X,Y`] | bottom left corner of the plot, page fractions (default `0,0`); not with a layout | — |
| **si**ze [`W,H`] | plot size, page fractions (default `1,1`); not with a layout | — |

## `plot` items

```gnuplot
plot 'file' [using SPEC] [index N] [every N] [smooth FILTER] [with STYLE] [title "text" | notitle]
            [axes x1y1|x1y2] [lc [rgb] "color" | lc N] [lw W] [dt N] [ps S], ...
plot FUNCTION [with STYLE] [title "text" | notitle] [axes x1y1|x1y2] [lc ...] [lw W] [dt N] [ps S], ...
```

| Modifier | Meaning |
|---|---|
| `'file'` | data file; `''` repeats the previous one |
| *function* | an expression of `x`, see [below](#functions) |
| **u**sing `SPEC` | fields separated by `:`, each a column number (0 is the point number), a quoted [column header](#column-headers) or a parenthesized [expression](#expressions-in-using): `Y`, `X:Y`, or the error bar layouts below |
| **i**ndex `N` | dataset `N` (0-based) of the file |
| **ev**ery `I:J:K:L:M:N` | gnuplot's `point_incr:block_incr:start_point:start_block:end_point:end_block`, empty fields default: `every 2`, `every ::1::10`, `every :::1::1` |
| **s**mooth `FILTER` | `unique`, `frequency`, `fnormal`, `cumulative`, `cnormal`, see [below](#smoothing) |
| **w**ith `STYLE` | `lines` (`l`), `points` (`p`), `linespoints` (`lp`), `yerrorbars` (`yerr`), `xerrorbars` (`xerr`), `xyerrorbars` (`xyerr`); foresight's `readout`, see [below](#readouts) |
| `format "fmt"` | foresight extension, readouts only: the glass of the [readout](#readouts), `%10.3e` by default |
| **t**itle `"text"` / **not**itle | key entry; by default the item as written, as gnuplot: `'run.dat' u 1:($2*1e3)`, `sin(x)/x` |
| **t**itle **columnh**ead[`(N)`] | key entry from the [column header](#column-headers) of column `N`, or of the y column |
| **ax**es `x1y1` / `x1y2` | plot against the first (default) or the [second y axis](#second-y-axis) |
| `lc` [**rgb**] `"color"` / `lc N` / `lt N` | color, or the `N`-th palette color |
| `lw` `W`, `dt` `N`, `ps` `S` | line width [px], dash type 1..5, point size |
| `pt` `N` / **pointt**ype `N` | [point type](#point-types); without it, points are round dots |
| `ls N` | line style `N` of `set style line`; the options after it override it |

`using` defaults as gnuplot: `1:2`, or `0:1` for single-column files; `1:2:3` for `yerrorbars` and `xerrorbars`,
`1:2:3:4` for `xyerrorbars`. Error bar layouts:

| Style | Columns |
|---|---|
| `yerrorbars` | `x:y:dy` or `x:y:ylow:yhigh` |
| `xerrorbars` | `x:y:dx` or `x:y:xlow:xhigh` |
| `xyerrorbars` | `x:y:dx:dy` or `x:y:xlow:xhigh:ylow:yhigh` |

## Expressions in `using`

A field in parentheses is an expression evaluated on each row, with gnuplot's semantics:

```gnuplot
plot 'run.dat' using ($1/3600):($2*1e3)             # hours, milli-units
plot 'run.dat' using 1:($3 > 0 ? log10($3) : 1/0)   # 1/0 drops a point: a gap
plot 'run.dat' using 0:(sqrt($2**2 + $3**2)) with lines
```

| | |
|---|---|
| Columns | `$N` or `column(N)`, `$0` is the point number; `column()` takes an expression: `column($1 + 1)`, or a header name: `column("residual")` |
| Operators, loosest first | `?:` · `\|\|` · `&&` · `==` `!=` · `<` `<=` `>` `>=` · `+` `-` · `*` `/` `%` · unary `-` `+` `!` · `**` |
| Functions | `abs acos asin atan atan2 ceil cos cosh exp floor int log log10 sgn sin sinh sqrt tan tanh` |
| Constants | numbers (`2`, `1.5`, `.5`, `1e-3`), `pi` |

The rules are gnuplot's, checked against gnuplot 6.0:

- `**` is right associative and binds tighter than a unary minus: `-2**2` is -4, `2**3**2` is 512.
- Integer constants stay integers: `1/2` is 0 and `-5/2` is -2, but `1/2.` is 0.5; an integer overflow gives a real.
  Columns are reals, so `$2/2` is a real division. `floor`, `ceil`, `int`, `sgn`, comparisons and logical operators
  give integers.
- `&&`, `||` and `?:` evaluate only the operand they need: `$2 > 0 && log($2) > 1` never takes the log of a
  negative.
- A missing cell, a division by zero, a domain error (`sqrt(-1)`, `log(0)`) or an overflow make the point undefined:
  a gap in the line, as gnuplot's `1/0`.

A field must be a column number or one parenthesized expression, as in gnuplot: `using 1:$2` and `using 1:2*3` are
errors. Syntax errors point at the character: `using: unexpected ")" at character 6 of "($2 +)"`.

Beyond gnuplot, foresight accepts `%` and the logical operators on reals, and an overflow gives a gap where gnuplot
stops the plot. Not supported: user variables and functions, string values (`stringcolumn`, string operators),
bitwise operators, the pseudo-columns -1 and -2.

## Functions

A plot item that is not a quoted file is a function of `x`, with the operators, functions and rules of
[`using` expressions](#expressions-in-using), without columns:

```gnuplot
plot 'run.dat' u 1:2, 1e-1 * exp(-x/5) t 'model'
plot sin(x)/x, x > 0 ? log(x) : 1/0
set samples 400; plot x * sin(1/x)
```

As gnuplot, a function is sampled at `set samples` points (100) evenly over the x range before its extension to the
ticks: the `xrange` ends where set, else the extent of the data of the whole plot, else [-10:10]. On a log x axis the
samples are evenly spaced in log x. Undefined values (`1/0`, `log(-1)`) are gaps. Functions are drawn `with lines`
by default whatever `set style data` says; `set style function points` (or `linespoints`) changes it, error bars are
not usable. The expression runs up to the first item option, so blanks may separate its terms: `plot x * 2 + 1 t 'line'`.

In the HTML page a zoom does not resample: the samples are those of the original range.

## Smoothing

`smooth FILTER` replaces the points of a data item by a filtered series, as gnuplot computes it. Each run of points
(a block of the file, ended also by an undefined point or by a value not placeable on a log axis) is sorted by x, and
its points of equal x are merged into one:

| Filter | y of the merged point |
|---|---|
| `unique` | the mean of their y |
| `frequency` | the sum of their y: with `using (BIN):(1)`, a histogram |
| `fnormal` | `frequency` divided by the sum of y over the whole item |
| `cumulative` | the sum of y up to that x, within the run |
| `cnormal` | `cumulative` divided by the sum of y over the whole item: an empirical distribution |

```gnuplot
plot 'run.dat' u 1:2 smooth unique                              # iterations repeated by a restart: averaged
plot 'run.dat' u (floor($5/0.02)*0.02):(1) smooth frequency     # histogram of column 5, bins 0.02 wide
plot 'run.dat' u 5:(1) smooth cnormal                           # its empirical distribution
```

The [cookbook](/manual/cookbook#histogram-and-distribution) draws the last two.

The runs stay separate lines. `smooth` applies to `lines`, `points` and `linespoints`; with error bars or on a
function it is an error (gnuplot ignores the extra columns, or the filter). The other filters (splines, Bézier,
`kdensity`, ...) are [not supported](#not-supported).

## Second y axis

```gnuplot
set logscale y
set ytics nomirror; set y2tics
set ylabel 'residual'; set y2label 'coefficient'
plot 'run.dat' u 1:2 t 'residual', '' u 1:3 axes x1y2 t 'cd'
```

The items plotted `axes x1y2` are scaled on the second y axis, autoscaled on them alone (on the points inside the x
range), with its own `y2range`, `logscale y2` and `format y2`. As in gnuplot, the y2 ticks and labels are off until
`set y2tics`: they go on the right border, not mirrored on the left (`set y2tics mirror` does). The y ticks stay
mirrored on the right unless `set ytics nomirror`. The axis is drawn only when it has data, or a range fixed at both
ends; `y2label` reads upward on the right, as `ylabel` on the left. In the HTML page the y2 ticks follow the zoom and
the readout shows the y2 value too.

## Column headers

```gnuplot
set datafile separator comma
plot 'run.csv' using 1:"residual" title columnhead, '' using "iteration":(column("cd")*1e3)
set key autotitle columnhead       # every untitled item takes the header of its y column
```

As in gnuplot, the first row of each dataset is a header as soon as an item uses it: a quoted name in `using` (also
in `column("name")`), `title columnhead`, or `set key autotitle columnhead`. It is then neither a point nor counted by
`$0`; otherwise it is an ordinary row, whose words are missing values. A name is looked up in the header of the
dataset each row belongs to; a name no selected dataset has is an error. `title columnhead` takes the header of the
first column the y field reads (`($3*2)` gives the header of column 3), `columnhead(N)` of column `N`; no header, no
title. Quoted header cells may hold blanks: `"the res"`. `set key noautotitle` leaves untitled items, functions
included, out of the key.

## Ticks and label formats

```gnuplot
set xtics 0.5            # a tick every 0.5
set xtics 0,5,30         # from 0 to 30 every 5
set ytics 10             # on a log axis the step is a factor: 1, 10, 100, ...
unset xtics              # no ticks, no labels, no grid lines
set format y "%.1e"      # 1.0e-03
set format x "%g s"      # 0.5 s
set format y "%h"        # like %g, the exponent as a superscript: 1x10⁻⁵
```

As in gnuplot, `set xtics` without positions (alone, or with only `mirror`/`nomirror`) keeps the last ones and turns
the ticks back on after `unset xtics`; `set xtics auto` returns to automatic ticks.

As in gnuplot, an autoscaled end extends outward to a multiple of the step, unless it lies below `START` or beyond
`END`; after `unset xtics` it does not extend at all. Log axes always extend to whole decades.

The formats are C printf's for one number: `%[flags][width][.precision]` with the conversions `f`, `e`, `E`, `g`,
`G` and gnuplot's `h`, flags `-`, `+`, space, `0`, and `%%` for `%`. The value formatted is the exact decimal of the
tick, so `set xtics 0.1` never shows `0.30000000000000004`, and a rounding tie goes to the even digit, as printf does
(`0.125` with `%.2f` is `0.12`).

Both settings follow the zoom in the HTML page: the viewer places and formats the ticks by the same rules.

## Key

```gnuplot
set key bottom left box
set key center           # centred both ways
set key top center       # top, centred horizontally
set key outside          # right of the plot, top aligned
set key outside left bottom
set key below            # a row below the plot (above: over it), wrapping when the panel is narrow
set key inside           # back inside, keeping the rows
```

Position words apply in order; `center` centres the direction not named yet, as in gnuplot. Titles are right-aligned
with their sample on the right. Inside, the key lies in the plot area. `outside` puts it in the left or right margin,
aligned with the top, centre or bottom of the plot; centred horizontally, above (`top`) or below (`bottom`) the
plot; centred both ways it stays inside, as gnuplot. `below` and `above` centre a row of entries under the x label or
between the title and the plot (`below left` aligns it to the left); `horizontal` and `vertical` choose rows or a
column anywhere. The plot shrinks to make room for a key outside it.

## Styles

```gnuplot
set style data linespoints
set style line 1 lc rgb '#e51e10' lw 2 dt 2
plot 'run.dat' u 1:2 ls 1 t 'residual', '' u 1:3 lt 3 t 'momentum'
```

`ls N` of an undefined style uses the palette color `N`, as gnuplot's linetype.

## Point types

```gnuplot
plot 'run.dat' u 1:2 w lp pt 7 t 'residual', '' u 1:3 w p pt 4 ps 1.5 t 'cd'
```

The shapes are those of gnuplot's svg terminal: `pt 0` a dot, 1 plus, 2 cross, 3 star, 4 square, 6 circle,
8 triangle, 10 inverted triangle, 12 diamond, 14 pentagon, each odd type from 5 the filled shape before it; beyond 15
they cycle. A marker is 9 px wide at `ps 1`, its lines `lw` wide. Without `pt` a point is foresight's round dot,
6 px at `ps 1`. In the HTML page markers keep their shape and size under zoom; the text terminal draws every point
with the symbol of its color.

## Multiplot

```gnuplot
set multiplot layout 1,2 title 'Monitor'
set title 'residual'; set logscale y
plot 'run.dat' u 1:2 w l t 'res'
set title 'drag'; unset logscale y
plot 'run.dat' u 1:3:4 w yerrorbars t 'cd'
unset multiplot
```

Each `plot` fills the next panel with the settings in force. The advance happens at the first `set`, `unset` or
`plot` after a plot, so settings written for the next panel never alter the one just plotted. A plot beyond the last
panel is an error.

Without `layout`, each panel lies in the box of its `set origin` and `set size`, fractions of the page below the
multiplot title, from the bottom left as gnuplot. Panels may overlap: an inset.

```gnuplot
set multiplot title 'Run monitor'
plot 'run.dat' u 1:3 w l t 'cd'
set origin 0.35,0.35; set size 0.55,0.5; unset key; set logscale y
plot 'run.dat' u 1:2 w lp
unset multiplot
```

Panels are drawn in order, without a background: in the HTML page the mouse acts on the topmost panel under it.
On the standard output (`set terminal dumb` or `block`), a multiplot is printed once, complete, at `unset multiplot`; files are
rewritten at each plot, so that a watched page shows the panels done so far.

## Readouts

A foresight extension, not gnuplot (gnuplot rejects these scripts): `with readout` shows the last finite value of an
item in seven-segment digits, as the digital instrument clusters of 1980s cars. It is made for live monitoring with
[`--watch`](monitoring) and for showcase pages, not for publication figures.

```gnuplot
set multiplot title 'Run monitor'
set origin 0,0.68; set size 1,0.32
set readout horizontal
plot 'run.dat' u 1 w readout format '%4.0f' t 'ITER', '' u 2 w readout format '%9.2e' t 'CONTINUITY'
set origin 0,0; set size 1,0.68
set readout vertical top right; unset key
plot 'run.dat' u 1:5 w l t 'cd', '' u 1:5 w readout format '%6.4f' t 'CD'
unset multiplot
```

<Plot name="cb_readout" svg :width="560" :height="420" />

- **The value** is the last point whose y is finite, after `using`, `every`, `index` and `smooth`; ranges, log axes
  and zoom do not apply. A readout takes no part in the autoscale and has no key entry: in a panel with curves, the
  curves alone set the axes.
- **The glass** is set by the format, never by the value, so a watched readout keeps its width: `format` is a
  [tick format](#ticks-and-label-formats) with a field width (`%9.2e`, not `%.2e`), without `%h`. Each character of
  the field is a cell, except the decimal point, a segment of the cell before it: `%9.2e` makes 8 cells. A `+` and
  the exponent sign `+` light nothing. Unlit segments are drawn faintly, as on the real displays.
- **No reading** (no finite value yet) or a value wider than the field lights a dash in every cell; digits are never
  cut. The text around the conversion, `'%5.2f h'`, is printed beside the glass: a unit.
- **The label** is the item title; `lc` colors the digits; `lw`, `dt`, `pt`, `ps` and `axes` are errors on a readout.
- **Placement.** The readouts of a panel form a block, a column (`vertical`, the default) or a row (`horizontal`),
  placed inside the plot area by the `set key` words (top left by default, the key being top right) over an opaque
  window hiding the curves below (`noopaque`: none). A panel of readouts alone has no axes: the digits grow until the
  block fills it, unless `set readout size H` fixes their height [px] (2.5 font sizes by default).
- **In text** (`dumb`, `block`), the digits are drawn with `_` and `|`, 3 rows of 4 characters per cell, in the item
  color with `ansi`; the unlit segments are not drawn. In the HTML page, zoom and follow mode leave readouts alone.

## Not supported

User variables and functions (`f(x) = ...`), inline ranges (`plot [0:1] sin(x)`), the second
x axis (`x2`, `axes x2y1`), `splot`, `fit`, log bases other than 10, `set size ratio` and `square`; in `set xtics`,
explicit tick lists `("a" 1, ...)`, minor ticks (`mxtics`) and the `rotate`, `out` options; in `set format`, the
`%s`, `%L`, `%T` conversions; `set datafile` options other than `separator` (`missing`, `commentschars`); the key
at a position (`at`) or in a named margin (`lmargin`, ...); `pointinterval` (`pi`); the `smooth` filters other than
`unique`, `frequency`, `fnormal`, `cumulative`, `cnormal` (`csplines`, `acsplines`, `mcsplines`, `bezier`,
`sbezier`, `kdensity`, `unwrap`, `path`) and `bins`; the `block` character sets `dot`, `octants`, `sextpua`,
`octpua`, and its `optimize`, `attributes`, `charpoints`, `gppoints`, `animate` options.
