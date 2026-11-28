---
title: gnuplot Subset
---

# gnuplot Subset

foresight interprets a subset of the gnuplot command language, documented here by topic. Everything outside it is an
error naming the command and its line (`script.gp:12: unsupported command "history"`), never silently ignored: a script
that runs is a script that did what it says. The commands that act on gnuplot's interactive windows only (`bind`,
`set mouse`, `vclear`, `test`, `set term push`) are accepted and do nothing, as with gnuplot's file terminals.
[Path E](/manual/paths/e-gnuplot/01-running-a-script) is the guide for gnuplot users.

## Syntax

- One statement per line, or several separated by `;`
- `#` starts a comment (outside quotes)
- A line ending with `\` continues on the next one
- Strings in single quotes are literal; in double quotes `\t` is a tab, `\n` a new line (an x tick label on two
  lines; a blank in titles and labels) and `\` takes the next character literally (`\"`, `\\`)
- `@name` (outside quotes) is replaced by the value of the string variable `name`, a gnuplot macro:
  `cmd = 'set logscale y'; @cmd`
- A line `$NAME << WORD` starts a [datablock](/guide/gnuplot/scripting#datablocks-and-scripts), its lines read as they are up to one starting
  with `WORD`
- `` `command` `` (outside single quotes, inside double ones too) is replaced by the standard output of the shell
  command, its last newline dropped: ``n = `wc -l < run.dat` ``, see
  [Shell commands](/guide/gnuplot/commands#shell-commands-reset-and-pause)
- Keywords accept gnuplot abbreviations: the shortest accepted form is in bold below

## Topics

| Page | Sections |
|---|---|
| [Commands and settings](/guide/gnuplot/commands) | [Commands](/guide/gnuplot/commands#commands), [`set` / `unset` options](/guide/gnuplot/commands#set-unset-options), [Shell commands, reset and pause](/guide/gnuplot/commands#shell-commands-reset-and-pause), [Print](/guide/gnuplot/commands#print), [Fit](/guide/gnuplot/commands#fit), [Stats](/guide/gnuplot/commands#stats) |
| [Plot items](/guide/gnuplot/plot-items) | [`plot` items](/guide/gnuplot/plot-items#plot-items), [Iteration](/guide/gnuplot/plot-items#iteration), [Parametric plots](/guide/gnuplot/plot-items#parametric-plots), [Clipping](/guide/gnuplot/plot-items#clipping) |
| [Data](/guide/gnuplot/data) | [Expressions in `using`](/guide/gnuplot/data#expressions-in-using), [String columns](/guide/gnuplot/data#string-columns), [Column headers](/guide/gnuplot/data#column-headers), [Tables](/guide/gnuplot/data#tables), [Time data](/guide/gnuplot/data#time-data), [Smoothing](/guide/gnuplot/data#smoothing) |
| [Styles](/guide/gnuplot/styles) | [Styles](/guide/gnuplot/styles#styles), [Lines, steps and impulses](/guide/gnuplot/styles#lines-steps-and-impulses), [Box, finance and boxplot styles](/guide/gnuplot/styles#box-finance-and-boxplot-styles), [Vectors, ellipses, polygons, labels and sectors](/guide/gnuplot/styles#vectors-ellipses-polygons-labels-and-sectors), [Point types](/guide/gnuplot/styles#point-types), [Boxes and filled curves](/guide/gnuplot/styles#boxes-and-filled-curves), [Histograms](/guide/gnuplot/styles#histograms), [Readouts](/guide/gnuplot/styles#readouts), [Circles, pies and donuts](/guide/gnuplot/styles#circles-pies-and-donuts), [Gauges, radars and roses](/guide/gnuplot/styles#gauges-radars-and-roses), [Parallel axes and spider plots](/guide/gnuplot/styles#parallel-axes-and-spider-plots), [Themes and segmented fills](/guide/gnuplot/styles#themes-and-segmented-fills) |
| [Axes, ticks and layout](/guide/gnuplot/axes) | [Second y axis](/guide/gnuplot/axes#second-y-axis), [Second x axis](/guide/gnuplot/axes#second-x-axis), [Ticks and label formats](/guide/gnuplot/axes#ticks-and-label-formats), [Key](/guide/gnuplot/axes#key), [Grid, zero axes and border](/guide/gnuplot/axes#grid-zero-axes-and-border), [Margins](/guide/gnuplot/axes#margins), [Multiplot](/guide/gnuplot/axes#multiplot), [Polar plots](/guide/gnuplot/axes#polar-plots) |
| [Text and fonts](/guide/gnuplot/text) | [Labels, arrows and objects](/guide/gnuplot/text#labels-arrows-and-objects), [Fonts](/guide/gnuplot/text#fonts), [Enhanced text](/guide/gnuplot/text#enhanced-text) |
| [Images, palettes and 3D](/guide/gnuplot/3d) | [Images and palettes](/guide/gnuplot/3d#images-and-palettes), [3D plots](/guide/gnuplot/3d#_3d-plots) |
| [Scripting](/guide/gnuplot/scripting) | [User variables and functions](/guide/gnuplot/scripting#user-variables-and-functions), [Strings](/guide/gnuplot/scripting#strings), [Datablocks and scripts](/guide/gnuplot/scripting#datablocks-and-scripts), [Arrays](/guide/gnuplot/scripting#arrays), [Function blocks](/guide/gnuplot/scripting#function-blocks), [Blocks and loops](/guide/gnuplot/scripting#blocks-and-loops), [Functions](/guide/gnuplot/scripting#functions), [Special functions](/guide/gnuplot/scripting#special-functions) |

## Not supported

`fit` beyond [its subset](/guide/gnuplot/commands#fit), log bases other than 10; the `rtics` placement options; in `set xtics`, positions and a list together
(`set xtics 0,1 ("a" 2)`), `rotate` of the color box labels, `out` of the color box ticks, `axis` of the
x2 and y2 ticks; the complex forms of the special functions (gnuplot's `Ai`, `BesselJ`, ...) and those of libcerf
(`VP`, `erfi`, `FresnelC`, ...);
in [enhanced text](/guide/gnuplot/text#enhanced-text), the fonts and the super and subscripts of the text devices; in `set format`,
gnuplot's `geographic` formats; `set datafile` options other than `separator`, `missing`,
`commentschars` and `columnheaders`; `lc variable` and `lc palette z` with boxplot, `set style boxplot labels x2`; the blank key rows of
`newhistogram` groups; the line gap of a negative `pointinterval` or `pointnumber`; `reread`
(deprecated in gnuplot 6.0), arrays as function arguments; the `smooth` filters
`unwrap`, the `kdensity` `period` option and smoothing on log axes in log space; the `block` character sets `dot`, `octants`, `sextpua`,
`octpua`, and its `optimize`, `attributes`, `charpoints`, `gppoints`, `animate` options; `set multiplot` `scale`,
`offset`; palette models other than RGB, HSV and CMY; `keyentry` with the panel charts other than spider plots (pies,
...);
`fillsteps` options (`above`, `below`, `y=`); `set minussign` and `set micro` with `set encoding utf8`.
