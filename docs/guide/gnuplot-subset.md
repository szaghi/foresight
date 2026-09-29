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
| **k**ey | show the key | hide the key |
| **ou**tput `"file"` | output file: `.svg`, `.html`, `.txt`, `-` | — |
| **te**rminal `svg`\|`html` [**si**ze `W,H`] [**ref**resh `S`] | output format, size in px, HTML reload period | — |
| **te**rminal `dumb` [**si**ze `COLS,ROWS`] | text output, 79 x 24 by default, on the standard output | — |
| **multi**plot **lay**out `R,C` [**t**itle `"text"`] | grid of panels, see below | back to one panel |

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
| **ev**ery `N` | one point every `N` in each block |
| **w**ith `STYLE` | `lines` (`l`), `points` (`p`), `linespoints` (`lp`), `yerrorbars` (`yerr`), `xerrorbars` (`xerr`), `xyerrorbars` (`xyerr`) |
| **t**itle `"text"` / **not**itle | key entry; by default the item as written, as gnuplot: `'run.dat' u 1:($2*1e3)` |
| `lc` [**rgb**] `"color"` / `lc N` | color, or the `N`-th palette color |
| `lw` `W`, `dt` `N`, `ps` `S` | line width [px], dash type 1..5, point size |

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

## Not supported

Plotting functions (`plot sin(x)`), user variables, `splot`, `fit`, `set format`, `set xtics`, `set style`,
`every` with more than a stride, log bases other than 10, key placement options, manual multiplot `origin`/`size`.
