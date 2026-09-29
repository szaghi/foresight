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
| **u**sing `SPEC` | column numbers separated by `:`, 0 is the point number: `Y`, `X:Y`, or the error bar layouts below |
| **i**ndex `N` | dataset `N` (0-based) of the file |
| **ev**ery `N` | one point every `N` in each block |
| **w**ith `STYLE` | `lines` (`l`), `points` (`p`), `linespoints` (`lp`), `yerrorbars` (`yerr`), `xerrorbars` (`xerr`), `xyerrorbars` (`xyerr`) |
| **t**itle `"text"` / **not**itle | key entry; default is `"file" using X:Y` |
| `lc` [**rgb**] `"color"` / `lc N` | color, or the `N`-th palette color |
| `lw` `W`, `dt` `N`, `ps` `S` | line width [px], dash type 1..5, point size |

`using` defaults as gnuplot: `1:2`, or `0:1` for single-column files; `1:2:3` for `yerrorbars` and `xerrorbars`,
`1:2:3:4` for `xyerrorbars`. Error bar layouts:

| Style | Columns |
|---|---|
| `yerrorbars` | `x:y:dy` or `x:y:ylow:yhigh` |
| `xerrorbars` | `x:y:dx` or `x:y:xlow:xhigh` |
| `xyerrorbars` | `x:y:dx:dy` or `x:y:xlow:xhigh:ylow:yhigh` |

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

Functions and expressions (`plot sin(x)`, `using ($1*2):2`), `splot`, `fit`, `set format`, `set xtics`, `set style`,
`every` with more than a stride, log bases other than 10, key placement options, manual multiplot `origin`/`size`.
