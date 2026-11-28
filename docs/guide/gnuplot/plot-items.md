---
title: Plot items
---

# Plot items

What a `plot` item is: files, functions, pseudo-files, iteration, parametric plots and clipping. Part of the [gnuplot subset](/guide/gnuplot-subset) reference.

## `plot` items

```gnuplot
plot [XRANGE] [YRANGE] ITEM, ITEM, ...
plot 'file' [using SPEC] [index N] [every N] [smooth FILTER | bins[=N] ...] [with STYLE] [title "text" [at ...] | notitle]
            [noenhanced] [axes x1y1|x1y2|x2y1|x2y2] [lc [rgb] "color" | lc N | lc [rgb] variable | lc palette ...]
            [lw W] [dt N] [ps S], ...
plot FUNCTION [with STYLE] [title "text" | notitle] [noenhanced] [axes x1y1|x1y2|x2y1|x2y2] [lc ...] [lw W] [dt N]
            [ps S], ...
```

Inline ranges `[min:max]` before the first item set the x range, then the y range, of that plot only, over `set
xrange` and `set yrange` (which they leave as they are: the next plot without them uses those again; `replot` keeps
them), as gnuplot. An empty or `*` end keeps the set one, `[]` skips an axis, the ends are constant expressions
(`[0:2*pi]`), and `[t=0:2]` names the dummy variable of the functions `t` instead of `x`:

```gnuplot
plot [0:2*pi] [-1.5:1.5] sin(x), cos(x)
plot [t=0:10] exp(-t/4)*sin(t)
plot [] [0:*] 'run.dat' u 1:2      # the y range only
```

They are not supported in polar mode (where gnuplot's first range is the t range): use `set trange`.

After the first item, a range before a function is that function's own sampling range, `*` its axis end, and
its title starts with it (`[0:*] x**2`); before a data item it is ignored with gnuplot's warning:

```gnuplot
plot [-2:2] x, [0:*] x**2           # x**2 sampled over [0:2] only
```

An item may be an assignment or a function definition, done in its turn: the functions after it see it.
`plot for [i=A:*]` iterates a data item until it yields no valid point, that last item not drawn (gnuplot's
unbounded iteration, `using i` over every column):

```gnuplot
plot s = .1, c(t), s = .3, c(t)     # c drawn with each s
plot for [col=2:*] 'run.dat' using 1:col title columnhead
```

| Modifier | Meaning |
|---|---|
| `'file'` | data file; `''` repeats the previous one |
| *function* | an expression of `x`, see [below](/guide/gnuplot/scripting#functions) |
| **u**sing `SPEC` | fields separated by `:`, each a column number (0 is the point number), a quoted [column header](/guide/gnuplot/data#column-headers) or a parenthesized [expression](/guide/gnuplot/data#expressions-in-using): `Y`, `X:Y`, or the error bar layouts below; a last field `xtic(N)` (`xticlabels(N)`) labels the points with the text of column N, or `xtic(EXPR)` with a [string expression](/guide/gnuplot/data#string-columns) (`xtic(strcol(1) . ' K')`), see [Histograms](/guide/gnuplot/styles#histograms); `x2tic`, `ytic`, `y2tic` on [those axes](/guide/gnuplot/axes#text-labels-on-any-axis) |
| *A* | an [array](/guide/gnuplot/scripting#arrays): its index and value, as a file |
| `$NAME` | a [datablock](/guide/gnuplot/scripting#datablocks-and-scripts), as a file |
| **newhist**ogram [`"title"`] [`lt N`] [`fs FILL`] [`at X`] | a new group of [histograms](/guide/gnuplot/styles#histograms), before the histograms of the group |
| **i**ndex `N` \| `"name"` | dataset `N` (0-based, an expression: `index (i-1)`) of the file, or the dataset after the comment line starting with `name` (the comment characters and blanks before it removed), as gnuplot |
| **mat**rix | the file is a matrix of values (columns the x index, rows the y index, from 0), for `with image` (`pixels` read: the pixels are drawn one by one anyway); `every` keeps columns (the points) and rows (the blocks), at their places; with `using` or another style its rows `x y value`, as gnuplot's (`plot 'm' matrix using 1:2:3 with image, '' matrix using 1:2:(sprintf("%g",$3)) with labels`) |
| **nonuni**form **mat**rix | the first row of the matrix holds the x of the columns (after a value ignored), the first column the y of the rows, as gnuplot; for `with image`, evenly spaced (uneven pixels are not supported) |
| `matrix rowheaders`, `matrix columnheaders` | the first cell of each row of the matrix names its row, the first row names the columns (after its corner cell with `rowheaders`): the names are the y and x tick labels at the row and column numbers from 0, the numbers read as a plain matrix, as gnuplot |
| `sparse matrix=(C,R)` [`origin=(X0,Y0)`] [`dx=DX`] [`dy=DY`] | the points (`using x:y:value`, 1:2:3 by default) fill a grid of C columns and R rows at X0 + i DX, Y0 + j DY (origin 0,0, DX 1, DY = DX), each in the cell nearest to its x:y, the other cells undefined: a heat map of unordered or incomplete data (`with image`), as gnuplot's; a point off its cell's centre is drawn at the centre |
| **ev**ery `I:J:K:L:M:N` | gnuplot's `point_incr:block_incr:start_point:start_block:end_point:end_block`, empty fields default: `every 2`, `every ::1::10`, `every :::1::1`; the fields may be expressions, `every ::j:0:j:0` |
| `skip N` | the first `N` lines of the file are not read, whatever they hold (also in `stats` and `fit`) |
| `palette` | gnuplot's short form of `lc palette z` (`with lines palette`) |
| `nocontours`, `nosurface`, `nogrid`, `nohidden3d` | `splot`'s: no [contour lines](/guide/gnuplot/3d#contours) of the item; the item's contours only, its surface not drawn; the item's points as they are, not [gridded](/guide/gnuplot/3d#gridded-and-masked-surfaces) by `set dgrid3d`; the item out of the hidden surfaces of `set hidden3d`, drawn as it is |
| `mask` | the item (`with pm3d`, `with image`, `rgbimage`, `rgbalpha`) drawn only inside the polygons of the `with mask` item, see [Gridded and masked surfaces](/guide/gnuplot/3d#gridded-and-masked-surfaces) |
| `keyentry` | an item without points, its key entry only (`plot keyentry with boxes lc "red" title "x"`), untitled unless titled, as gnuplot 6.0; `keyentry "text"` [`font F`] its sample the text, titled blank unless titled; the linetype of the next item, not used up; with the other styles of a plot panel its sample is a filled box (polygons, boxplots, circles, ellipses, candlesticks, the box styles, histograms, sectors), a line and points (error lines) or a line; with `spiderplot` a key entry of a [spider plot](/guide/gnuplot/styles#parallel-axes-and-spider-plots) set |
| **newspider**plot | the next spider plot items a new set of polygons on the same axes, see [Parallel axes and spider plots](/guide/gnuplot/styles#parallel-axes-and-spider-plots) |
| `sharpen` | of a function: the extrema between its samples found (gnuplot 6.0's filter: a golden section search where the 5-term Savitzky-Golay second derivative turns) and added; ignored on data, as gnuplot |
| **fc** / **fillc**olor `COLOR` | the fill's own color (styles with a fill), its border too (over `lc`, unless `fs border lc` gives one, as gnuplot 6.0): `with filledcurves fc rgb "#80e0a080"`; `fc palette cb V`, `fc palette frac F` one palette color for the item |
| **s**mooth `FILTER` | `unique`, `frequency`, `fnormal`, `cumulative`, `cnormal`, `csplines`, `acsplines`, `mcsplines`, `bezier`, `sbezier`, `kdensity [bandwidth B]`, `path`, see [below](/guide/gnuplot/data#smoothing); `bins` see [Bins](/guide/gnuplot/data#bins); in `splot` `csplines` and `acsplines` (x:y:z[:weight]) of the lines, see [3D views](/guide/gnuplot/3d#_3d-views) |
| **w**ith `STYLE` | `lines` (`l`), `points` (`p`), `linespoints` (`lp`), `impulses` (`i`), `steps` (`st`), `fsteps` (`fs`), `histeps` (`his`), `dots` (`d`), see [below](/guide/gnuplot/styles#lines-steps-and-impulses); `yerrorbars` (`yerr`), `xerrorbars` (`xerr`), `xyerrorbars` (`xyerr`), `yerrorlines` (`yerrorl`), `xerrorlines` (`xerrorl`), `xyerrorlines` (`xyerrorl`), `boxes`, `boxerrorbars` (`boxer`), `boxxyerror` (`boxx`), `candlesticks` (`can`) [`whiskerbars` [`F`]], `financebars` (`fin`), `boxplot`, see [below](/guide/gnuplot/styles#box-finance-and-boxplot-styles); `vectors` (`vec`), `arrows`, `ellipses` (`ell`), `polygons` (`poly`), `labels`, `sectors` (`sec`), see [below](/guide/gnuplot/styles#vectors-ellipses-polygons-labels-and-sectors); `parallelaxes` (`parallel`) [`at X`], `spiderplot` (`spider`), see [below](/guide/gnuplot/styles#parallel-axes-and-spider-plots); `filledcurves` (`filledc`) [`closed`\|`x1`\|`x2`\|`y1`\|`y2`\|`y=V`\|`x=V`\|`xy=X,Y`] [`above`\|`below`], see [below](/guide/gnuplot/styles#boxes-and-filled-curves); `histograms` (`hist`), see [below](/guide/gnuplot/styles#histograms); `image` (`ima`), `rgbimage`, `rgbalpha` (`rgba`), see [below](/guide/gnuplot/3d#images-and-palettes); `surface` (`sur`) on a polar panel, see [below](/guide/gnuplot/axes#polar-plots); `circles` (`cir`), foresight's `pie [donut F]`, see [below](/guide/gnuplot/styles#circles-pies-and-donuts); foresight's `gauge range [A:B] [segments N]`, `radar`, `rose [linear]`, see [below](/guide/gnuplot/styles#gauges-radars-and-roses); foresight's `readout`, see [below](/guide/gnuplot/styles#readouts); `table` [`if COND`], the rows as [text](/guide/gnuplot/data#with-table); `splot`'s `pm3d`, see [3D plots](/guide/gnuplot/3d#_3d-plots); `contourfill` (splot), the pm3d surface in [z slices](/guide/gnuplot/3d#_3d-views); `zerrorfill` (`zerror`, splot, `x:y:z:dz` or `x:y:z:zlow:zhigh`), a line with its [z errors filled](/guide/gnuplot/3d#_3d-views); `mask`, polygons masking the `mask` items, see [below](/guide/gnuplot/3d#gridded-and-masked-surfaces) |
| **fs** / **fills**tyle `FILL` | fill of a box or filled curve item, words as `set style fill` (gnuplot's abbreviations: `bo`, `nobo`, `tr`, `so`, `e`mpty, `pa`) |
| `format "fmt"` | foresight extension, readouts and gauges: the glass of the [readout](/guide/gnuplot/styles#readouts), `%10.3e` by default |
| **t**itle `"text"` / **not**itle [`columnhead`] | key entry; by default the item as written, as gnuplot: `'run.dat' u 1:($2*1e3)`, `sin(x)/x`; `notitle columnhead`: none, the first row still a header; `title columnhead(N)[i:j]` a substring of the header |
| **t**itle **col**umnhead[`(N)`] | key entry from the [column header](/guide/gnuplot/data#column-headers) of column `N` (an expression: `columnhead(i)` in a loop), or of the y column; `col`, `columnheader` as gnuplot |
| **ax**es `x1y1` / `x1y2` / `x2y1` / `x2y2` | plot against the first axes (default), the [second y axis](/guide/gnuplot/axes#second-y-axis), the [second x axis](/guide/gnuplot/axes#second-x-axis), or both second axes |
| `lc` [**rgb**] `"color"` / `lc N` / `lt N` | color (a gnuplot [color name](/guide/gnuplot/styles#color-names) or `#RRGGBB`), or the color of linetype `N`; `lc rgb N` a number (an expression), the color 0xRRGGBB itself (0xAARRGGBB with a transparency AA); `lt -1`, `-2`, `-3` (and `ls` of them without such a style) are black, nodraw and the background, solid; `lc variable` 0 is linetype 0, gnuplot's gray |
| `lc` [**rgb**] **var**iable | a color per point from the last `using` column (`using 1:2:3`): the linetype color of its number (cycling as `lc N`), or with `rgb` the 24-bit color `0xRRGGBB`; with `lines` (each segment in the color of its end point; in the key, the line sample in the first point's, the point sample in the last one's), `points`, `linespoints` and `impulses`, not with `smooth` |
| `lw` `W`, `dt` `N`, `ps` `S` | line width [px], dash type 1..5 (`dt solid` is 1), point size |
| `dt "string"` / `dt (S, E, ...)` | gnuplot's custom dash patterns: `.` dot, `-` dash, `_` long dash, a blank a longer gap; or the solid and empty lengths; a string variable too (`dt new`); scaled by the line width as gnuplot's svg |
| `lc bgnd` / `lt nodraw` / `lt -1` | the background color, nothing drawn, black (`lt -2` nodraw, `lt -3` bgnd) |
| `pt` `N` / **pointt**ype `N` | [point type](/guide/gnuplot/styles#point-types); without it, the point type of the item's linetype, as gnuplot |
| `pi` `N` / **pointi**nterval `N` | a point on the first point and every N-th after it (`linespoints`, error bar styles); a negative N every \|N\|-th, the line blanked under each point (a disk of the background), as gnuplot |
| **noauto**scale | the item out of the autoscaling of its axes (a boxplot still widens x, as gnuplot places every box) |
| `ps` **var**iable | each point's size from the column after the style's (before an `lc variable` one), as gnuplot |
| `pt` **var**iable | each point's [type](/guide/gnuplot/styles#point-types) from the column after the sizes of `ps variable` (before an `lc variable` one): its integer part, a dot for 0 and less, as gnuplot |
| **convexhull** / **concavehull** [`expand D`] / **delaunay** | gnuplot 6.0's hull filters of the item's points, right after they are read: the convex hull (clockwise, closed), a chi-shape (concave hull: its length the real variable `chi_length` if positive, else `set chi_shape fraction F` of the longest hull edge, 0.6, the one used in `GPVAL_CHI_LENGTH`), `expand D` pushing the hull out by D (before or after `smooth path`), `delaunay` the triangles; every column follows its point. `smooth convexhull` is `convexhull smooth path` |
| **zsort** | the points of each curve drawn in the order of their z (the third column, `using x:y:z[:color]`), the highest last, as gnuplot 6.0 (also `smooth zsort`) |
| **bin**ary [`matrix`] \| `array=(W,H)` ... \| `format='...'` [`record=N[:N...]`] [`skip=N`] [`endian=...`] | gnuplot's binary files: the matrix binary (`binary` alone), the general binary records and the data arrays, see [Binary files](../data-files#binary-files) and [Images and palettes](/guide/gnuplot/3d#images-and-palettes) |
| `ls N` | line style `N` of `set style line`; the options after it override it |
| long forms | **linec**olor, **linet**ype, **linew**idth, **dasht**ype, **points**ize, **lines**tyle (`rgbcolor` for `rgb`), as gnuplot |

`using` defaults as gnuplot: `1:2`, or `0:1` for single-column files; `1:2:3` for `yerrorbars` and `xerrorbars`,
`1:2:3:4` for `xyerrorbars` (the same for the `errorlines`). Error bar layouts:

| Style | Columns |
|---|---|
| `yerrorbars` | `x:y:dy` or `x:y:ylow:yhigh` |
| `xerrorbars` | `x:y:dx` or `x:y:xlow:xhigh` |
| `xyerrorbars` | `x:y:dx:dy` or `x:y:xlow:xhigh:ylow:yhigh` |
| `boxes` | `x:y` or `x:y:width` |
| `filledcurves` | `x:y` (to `y=V`, `x=V`, a border, or the closed polygon), `x:y1:y2` (a band) |
| `histograms` | `y`, the rows at the point numbers 0, 1, ... |
| `image` | `x:y:z` on a regular grid (default `1:2:3`), or a `matrix` file; a complete grid of uneven spacing (2 x 2 at least) is drawn with its pixels evenly spread between the first and last values, as gnuplot |
| `circles` | `x:y` (default radius), `x:y:radius`, `x:y:radius:start:end` (wedges, degrees) |
| `pie` | `y`, one slice per row; `y:xtic(N)` names the slices |
| `gauge` | `y` (the last finite value), or `x:y` |
| `radar`, `rose` | `y`, one spoke or sector per row; `y:xtic(N)` names them |

### Error bar caps

```gnuplot
set errorbars 2 lc rgb 'red' lw 2     # caps twice as long, red bars
set errorbars small                   # no caps
unset errorbars                       # no caps either, as gnuplot
```

<Plot name="cb_errorbar_caps" svg :width="760" :height="280" />

`set errorbars SIZE` scales the caps of the error bars (y, x and xy bars, the bars of histograms and box error bars)
and of the boxplot whiskers: `large` is 1, the default cap, `small` 0, none; `fullwidth` is taken as `large`. `lc` and
`lw` draw the bars in that line instead of their series'; `front` and `back` are accepted. As gnuplot, the setting is
read when the plot is drawn. foresight's default cap is 6 px long (gnuplot's svg terminal draws 9 px).

## Iteration

```gnuplot
plot for [i = 2:4] 'run.dat' u 1:i w l t word('continuity momentum energy', i - 1)
plot 'run.dat' u 1:2, for [i = 3:4] '' u 1:i lc i
plot for [k in 'a.dat b.dat'] k u 1:2, for [i = 1:3] for [j = 1:2] i*j*x
set for [i = 1:3] label i sprintf("run %d", i) at i, i
unset for [i = 2:3] label i
```

`set for [...] OPTION` and `unset for [...] OPTION` run the command once per value of the clauses, as `do for`: the
loop variable local to it.

`plot for [...] ITEM` plots the item once per value, with gnuplot's clauses (`i = a:b[:c]`, `w in "words"`, several
of them, the last varying fastest); the item's `using` fields, title and options read the variable: a `using`
field that is a constant expression is the column it gives (`u 1:i`; a string, the column of that header name), the
line options take expressions (`lc i`, `lw w`). Each value adds a series with the next color, the default title is the
item as written (`'run.dat' u 1:i`), `''` is the previous file, an empty range plots nothing; iterated and plain items
mix. The loop variable is restored afterwards. An inner clause's bounds may depend on an outer variable, evaluated
again each time it moves, as gnuplot's (`for [i = 1:3] for [j = 1:i]`: six items).

Definitions written before an iterated item are its own, run on each pass, as gnuplot: `plot for [i = 1:7] rho =
r[i], lambda = l[i], f(x, rho, lambda)`. An assignment written before an item without a comma (`ysum=0 '' using ...`)
is run first and appears in the automatic title. A comma ending the plot ends it.

## Parametric plots

```gnuplot
set parametric; set trange [0:2*pi]
plot sin(3*t), cos(2*t) t 'Lissajous', [0:1] t, t**2
plot [0:pi] [-2:2] [-2:2] 2*cos(t), sin(t)     # [t] [x] [y]
unset parametric
```

`set parametric` makes a function item a pair `x(t), y(t)`, its options after the second expression, sampled at
`set samples` values of `t` over `trange` ([-5:5] by default, as gnuplot); the first inline range is the one of `t`,
then x and y. The automatic title is the pair as written; data items are as they are. `unset parametric` and `reset`
go back to functions of x.

## Clipping

As gnuplot, a line segment with one end outside the plot area is drawn up to the border (`set clip one`, the default)
and one with both ends outside is not drawn at all (`unset clip two`, the default: no line down the asymptotes of
`tan(x)`); `set clip two` draws its visible part, `unset clip one` leaves out the first kind too. `set clip points`
hides the markers that cross the border (bare `set clip` is `set clip points`, bare `unset clip` turns all three off).
Departure: without `clip points` a marker crossing the border is cut at it, where gnuplot draws it whole. `set clip
radial` (polar) is accepted.
