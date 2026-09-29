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
- Strings in single quotes are literal; in double quotes `\"` and `\\` are escapes
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
| **xl**abel / **yl**abel `"text"` | axis label | no label |
| **xr**ange / **yr**ange `[min:max]` | axis range; `*` or empty autoscales an end; `min > max` reverses | — |
| **log**scale [`x`\|`y`\|`xy`] [`10`] | base-10 log axes (default both) | linear axes |
| **gr**id | grid at major ticks | no grid |
| **k**ey [`on`\|`off`] [`left`\|`right`\|`center`] [`top`\|`bottom`\|`center`] [`box`\|`nobox`] | show the key, inside the plot area (top right by default), see [below](#key) | hide the key |
| **xti**cs / **yti**cs [`auto` \| `STEP` \| `START,STEP[,END]`] | tick positions, see [below](#ticks-and-label-formats) | no ticks, labels nor grid lines |
| **for**mat [`x`\|`y`\|`xy`] [`"format"`] | tick label format, see [below](#ticks-and-label-formats) | default labels |
| **st**yle **d**ata `STYLE` | style of items without `with` | — |
| **st**yle **l**ine `N` [`lc` ...] [`lt N`] [`lw W`] [`dt N`] [`ps S`] | line style `N`, used by `ls N` | — |
| **ou**tput `"file"` | output file: `.svg`, `.html`, `.txt`, `-` | — |
| **te**rminal `svg`\|`html` [**si**ze `W,H`] [**ref**resh `S`] | output format, size in px, HTML reload period | — |
| **te**rminal `dumb` [**si**ze `COLS,ROWS`] | text output, 79 x 24 by default, on the standard output | — |
| **multi**plot [**lay**out `R,C`] [**t**itle `"text"`] | grid of panels, or panels in their `origin`/`size` boxes without layout, see [below](#multiplot) | back to one panel |
| **or**igin [`X,Y`] | bottom left corner of the plot, page fractions (default `0,0`); not with a layout | — |
| **si**ze [`W,H`] | plot size, page fractions (default `1,1`); not with a layout | — |

## `plot` items

```gnuplot
plot 'file' [using SPEC] [index N] [every N] [with STYLE] [title "text" | notitle]
            [lc [rgb] "color" | lc N] [lw W] [dt N] [ps S], ...
```

| Modifier | Meaning |
|---|---|
| `'file'` | data file; `''` repeats the previous one |
| **u**sing `SPEC` | fields separated by `:`, each a column number (0 is the point number) or a parenthesized [expression](#expressions-in-using): `Y`, `X:Y`, or the error bar layouts below |
| **i**ndex `N` | dataset `N` (0-based) of the file |
| **ev**ery `I:J:K:L:M:N` | gnuplot's `point_incr:block_incr:start_point:start_block:end_point:end_block`, empty fields default: `every 2`, `every ::1::10`, `every :::1::1` |
| **w**ith `STYLE` | `lines` (`l`), `points` (`p`), `linespoints` (`lp`), `yerrorbars` (`yerr`), `xerrorbars` (`xerr`), `xyerrorbars` (`xyerr`) |
| **t**itle `"text"` / **not**itle | key entry; by default the item as written, as gnuplot: `'run.dat' u 1:($2*1e3)` |
| `lc` [**rgb**] `"color"` / `lc N` / `lt N` | color, or the `N`-th palette color |
| `lw` `W`, `dt` `N`, `ps` `S` | line width [px], dash type 1..5, point size |
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
| Columns | `$N` or `column(N)`, `$0` is the point number; `column()` takes an expression: `column($1 + 1)` |
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
stops the plot. Not supported: user variables and functions, string columns (`column("name")`, `stringcolumn`),
bitwise operators, the pseudo-columns -1 and -2.

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
```

Position words apply in order; `center` centres the direction not named yet, as in gnuplot. The key stays inside
the plot area, titles right-aligned with their sample on the right.

## Styles

```gnuplot
set style data linespoints
set style line 1 lc rgb '#e51e10' lw 2 dt 2
plot 'run.dat' u 1:2 ls 1 t 'residual', '' u 1:3 lt 3 t 'momentum'
```

`ls N` of an undefined style uses the palette color `N`, as gnuplot's linetype.

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
On the standard output (`set terminal dumb`), a multiplot is printed once, complete, at `unset multiplot`; files are
rewritten at each plot, so that a watched page shows the panels done so far.

## Not supported

Plotting functions (`plot sin(x)`), user variables, `splot`, `fit`, log bases other than 10, `set size ratio` and
`square`; in `set xtics`, explicit tick lists `("a" 1, ...)`, minor ticks (`mxtics`) and the `nomirror`,
`rotate`, `out` options; in `set format`, the `%s`, `%L`, `%T` conversions; the key `outside` the plot area;
point types (`pt`).
