---
title: Axes, ticks and layout
---

# Axes, ticks and layout

Axes and their ticks, the key, grids, margins, multiplots and polar plots. Part of the [gnuplot subset](/guide/gnuplot-subset) reference.

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

## Second x axis

```gnuplot
set xrange [0:100]; set xtics nomirror; set xlabel 'frequency [Hz]'
set x2range [0:2]; set x2tics 0.25; set x2label 'Strouhal number'
plot 'spectrum.dat' w impulses
```

The x2 axis is the top border's, as the y2 axis is the right one's: `axes x2y1` (or `x2y2`) scales an item on it,
autoscaled on those items alone, with its own `x2range`, `logscale x2`, `format x2`, `mx2tics`. Its ticks and labels
are off until `set x2tics`, not mirrored at the bottom (`set x2tics mirror` does); `x2label` goes above the tick
labels. As in gnuplot, `set x2tics` with no item on the axis spans the range of the first x axis, so a fixed
`x2range` relabels the top border in another unit, as above; a function plotted on x2 is sampled over the x2 range.
The axis is drawn when it has ticks, items or a range fixed at both ends. In the HTML page the x2 ticks follow the
zoom and the readout shows the x2 value too.

`set link x2 via F(x) inverse G(x)` (and `set link y2`) links the second axis to the first: its range is the first's,
mapped by F (G maps back, as gnuplot 6.0 asks). Its automatic ticks sit at the automatic ticks of the first axis' range
(whatever `set xtics` says), each labelled by its mapped value: `via 1e4/x` over [2:20] reads 5000, 2500, 1666.67, ...
at 2, 4, 6, ..., as gnuplot; a step or a list (`set x2tics 500`) is in the second axis' own units. `set link x2` alone
makes the same axis on top; `unset link x2` frees it.

`set nonlinear x via F(x) inverse G(x)` (and `y`) places the axis linearly in the values of F, gnuplot's hidden axis:
`via log10(x) inverse 10**x` is a log axis, `via sqrt(x) inverse x**2` a square-root one, an F undefined over an
interval a broken axis (the values there not placed). The hidden axis takes the mapped data and ends and its own
automatic range. Its automatic ticks, at least 1 apart, are labelled by G of them, as gnuplot 6.0: `via sqrt(x)` over
[0:100] reads 0, 4, 16, ..., 100; a step or a list (`set xtics 10`) is in the axis' own values. `unset nonlinear x`
undoes it. `set nonlinear z|cb via log10(z) inverse 10**z` (the variable z for both, as gnuplot) makes the z or color
axis logarithmic, as `set logscale z|cb`; other maps of z and cb are refused. Not supported: x2, y2 and r.

## Ticks and label formats

```gnuplot
set xtics 0.5            # a tick every 0.5
set xtics 0,5,30         # from 0 to 30 every 5
set ytics 0, ymax / 10.0, ymax          # expressions, blanks and all (a computed value to 12 digits)
set ytics 10             # on a log axis the step is a factor: 1, 10, 100, ...
unset xtics              # no ticks, no labels (nor their margin), no grid lines
set format y "%.1e"      # 1.0e-03
set format x "%g s"      # 0.5 s
set format y "%h"        # like %g, the exponent as a superscript: 1x10⁻⁵
set format y ""          # the ticks without labels (in scripts, as gnuplot)
set format x "|"         # no conversion: the text itself at every tick
set ytics 10 logscale    # on a log axis the step a factor (the default)
set ytics 0.1 nologscale # ... or added: 0.1, 0.2, ..., 1 on a log axis
set xtics ("Jan" 1, "Feb" 2, "Mar" 3)   # an explicit list replaces the ticks
set ytics add ("limit" 7.5)             # ... or is added to them
set xtics 0,1,10 add ("" 0)             # a series and a list in one command: the list added
set tics out nomirror scale 1.5, 0.75   # every axis: outward, not mirrored, longer ticks
unset tics                              # no ticks on any axis (z and cb too)
```

`set tics` sets the options of every axis at once, as gnuplot: `mirror`/`nomirror`, `in`/`out`, `scale MAJOR[,MINOR]`
(`scale default`: 1, 0.5), `axis`/`border`, `rangelimited`, and the label options below; bare, it turns the x and y
ticks on; `unset tics` turns them all off; `set ticscale` is the old form of the scale. The scale multiplies the tick
lengths (6 px major, foresight's; gnuplot's svg draws 9), `MINOR` half `MAJOR` when absent, `scale 0` draws no ticks
and keeps the labels; each axis takes it too (`set xtics scale 2`). `set tics front|back` puts the grid over the data or behind it (gnuplot's one layer of grid and ticks), `set tics INCR` the step of every axis (which axes show ticks unchanged). Not supported in `set tics`:
`rotate`.

The tick labels of an axis (`set xtics ...`) or of every axis (`set tics ...`) take gnuplot's options: `format "..."`
(the axis' `set format`), `font "..."` (the labels' [font](/guide/gnuplot/text#fonts), placed as the page's, as gnuplot), `offset X[,Y]` and `nooffset` (a
shift in characters, gnuplot's svg cell: 0.7 font sizes wide and 1.5 high, y up) and
`textcolor`/`tc COLOR`. `set tics` changes only the options it names. gnuplot's old forms `set no{option}` (`set
noxtics`, `set nomztics`, `set nokey`, ...) are `unset {option}`, as gnuplot.

```gnuplot
set xtics 1 offset 0,-0.5 tc rgb "#b3163f" format "%.1f"   # the x labels lower, red, one decimal
set tics font ",8" tc "gray40"                              # every axis' labels gray
```

`set xtics axis` draws the x ticks and their labels on the x axis (y = 0) instead of the bottom border, `set ytics
axis` the y ones on x = 0, as gnuplot: not mirrored, the plot area taking no margin for their labels, when the other
axis is linear with 0 in its range (else on the border); `border` puts them back. `rangelimited` keeps the ticks of an
axis within the range of its data and shortens that side of the border to it, `norangelimit` undoes it. The viewer
keeps both through a zoom.

```gnuplot
set xtics axis; set ytics axis                  # ticks on the axes through the origin
set border 3; set tics nomirror rangelimited    # Tufte's range frame
```

Automatic ticks step as gnuplot's: by the axis range only, whatever the size of the plot (0.5 on [-2:2], 0.2 on
[0:1], 2 on [0:13], 20 on [0:100]); log axes label every 1, 2, 5, ... decades by the same rule (every 2 decades on
[1:1e10]). Within a single decade foresight labels the 2..9 multiples where gnuplot shows the decade alone.

Without a `set format` the tick labels of a script are gnuplot's default format `% h`: each label `%g` with a `x10`
superscript exponent (500000, 1x10⁶, 0.0005, 1x10⁻⁵), and an axis whose ends have one sign and whose span (or start)
is small takes gnuplot's invented `%.Pf`, P = ceil(-log10(min(|max - min|, |min|))) when 5 to 9 ([1e-6:1e-5] reads
0.000001 ... 0.000010), as gnuplot's copy_or_invent_formatstring; the HTML viewer relabels a zoom with `%h`. The
library keeps its own default: plain decimals, a `x10` exponent from 1e5 up and below 1e-3 for the whole axis.

As in gnuplot, `set xtics` without positions (alone, or with only `mirror`/`nomirror`) keeps the last ones and turns
the ticks back on after `unset xtics`; `set xtics auto` returns to automatic ticks.

As in gnuplot, an autoscaled end extends outward to a multiple of the step, unless it lies below `START` or beyond
`END`; after `unset xtics` it does not extend at all. Log axes always extend to whole decades.

### Offsets

```gnuplot
set offsets 0.5, 0.5, 1, 1                    # left, right, top, bottom: x and y units
set offsets graph 0.05, graph 0.05, 0, 0      # fractions of the range
set autoscale noextend; set offsets 0, 0, 2, 2; plot sin(x)    # y [-3:3]
```

`set offsets L, R, T, B` moves the autoscaled ends of x and y out, as gnuplot: in axis units, or after `graph` by
fractions of the range; fixed ends stay, the extension to the ticks comes after, and functions are sampled on the
range before the offsets. On a log axis only `graph` offsets apply, in decades. `unset offsets` removes them.

The formats are gnuplot's: text with conversions `%[flags][width][.precision]type`, all applied to the same value,
and `%%` for `%`; flags `-`, `+`, space, `0`, `#`.

| Conversion | |
|---|---|
| `f`, `e`, `E`, `g`, `G` | C's printf |
| `h`, `H` | `g` with the exponent as a superscript: `x10` (`H`: `*10`) |
| `t` (`l`) | the mantissa to base 10, printed as `%f`: `%.1t` of 3456 is `3.5` (`l`: to the log base, 10 in foresight) |
| `T` (`L`) | the power of 10 (of the log base): `10^{%T}` labels a log axis `10³` with [enhanced text](/guide/gnuplot/text#enhanced-text) |
| `s`, `S`, `c` | the mantissa to a power of 1000, that power, its SI prefix: `"%.0s %cHz"` is `2 MHz` |
| `b`, `B` | the mantissa to a power of 1024 and its binary prefix: `"%.1b %BB"` is `1.5 kiB` |
| `P` | the multiple of π: `"%.1Pπ"` |
| `x`, `X`, `o` | the integer part in hexadecimal or octal |

The value formatted is the exact decimal of the tick, so `set xtics 0.1` never shows `0.30000000000000004`, and a
rounding tie of the C conversions goes to the even digit, as printf does (`0.125` with `%.2f` is `0.12`). The
mantissas and powers are gnuplot's, computed in doubles as its `mant_exp`: a mantissa that rounds to the base moves to
the next power (`%.0t` of 9.6 is `1` and `%T` `1`), and on a decimal tie its rounding follows the C library's `pow`
(`%.1t` of 12.5 is `1.3` with glibc, as gnuplot).

```gnuplot
set logscale y; set format y "10^{%T}"     # 10^0, 10^1, ... as superscripts
set format x "%.0s %cHz"                   # 0 Hz, 500 kHz, 1 MHz
set format x "%.1t·10^{%T}"                # 3.5·10^3
```

An explicit list `("label" pos level, ...)` places the ticks itself, as gnuplot: each item is an optional quoted
label, a position (a constant expression: `2*pi`, user variables) and an optional level, `1` for a minor tick
(unlabelled, shorter). A label is printed as written, or used as the format of the position when it holds a conversion
(`"%.1f s" 2` is `2.0 s`); without a label the position gets the axis label (`set format`). Items outside the range are
left out, and a list alone does not extend an autoscaled end to a tick grid. Without `add` the list replaces the ticks
and any earlier list; with `add` it joins them, an item replacing the tick at its position. Positions without `add`
(`set xtics 2`, `set xtics auto`) and `unset xtics` forget the list; `set xtics add 2` keeps it beside the new step.

```gnuplot
set xtics ("Jan" 1, "" 1.5 1, "Feb" 2, "" 2.5 1, "Mar" 3)   # months, a minor tick between them
set ytics add ("limit" 7.5, "%.2f mm" 4.25)                 # the automatic ticks and two more
```

Minor ticks divide each interval between consecutive major ticks: `set mxtics N` in `N` parts, `set mxtics` by
gnuplot's count (2 when the step leads with 2, 0.2 or 20, else 5; 9 on log axes), linearly in value on log axes too
(`set mytics 4` puts them at 3.25, 5.5, 7.75 within each decade), as gnuplot. They cover the partial intervals at the
ends of an automatic step, stay within `START` and `END` of a fixed one, and an explicit list alone has none. By
default linear axes have none and log axes 9 intervals between majors, as gnuplot: the 2..9 multiples of each decade,
and linear intervals when the majors are several decades apart or a factor apart (`set ytics 100`); `unset mxtics`
removes them, `set mxtics default` restores them.

```gnuplot
set mxtics               # gnuplot's count: 5 per step of 1
set mytics 4             # 4 intervals between major ticks
unset mytics             # none, also the 2..9 of a log axis
```

`out` points the ticks (and their mirrors) outward, the plot area making room for them, `in` back inward (x, y, y2 and x2
ticks). `rotate` turns the x tick labels by 90 degrees, reading upward and right-justified; `rotate by A` by `A`
degrees counterclockwise, left-justified unless `left`, `right` or `center` follows; `norotate` restores them. As in
gnuplot, the glyphs of a rotated label are centred on its tick and a left-justified one at a positive angle runs up
into the plot: give it `right`, or a negative angle. The bottom margin grows to the labels that hang below the axis.
`set x2tics rotate` turns the x2 tick labels the same way above the plot: from their tick, reading away from it
(`rotate` is 90 degrees, left-justified there, as gnuplot), the top margin growing to them and the right one to the
reach of the last label. Unlike gnuplot, a negative angle keeps them above the border (gnuplot lets them run into
the plot). `set ytics rotate` turns the y tick labels to read upward, centred on their tick; `rotate by A` turns
them by `A` degrees, their glyphs centred on the tick and right-justified (y2: left) unless justified, at gnuplot's
distances from the border; the left (right) margin grows to their reach. `set tics rotate [by A]` turns the labels
of the four axes. Text devices write the labels upright, as gnuplot's dumb terminal.

```gnuplot
set xtics rotate by 30 right out nomirror   # long category names, outward ticks
set ytics out
```

All these settings follow the zoom in the HTML page: the viewer places and formats the ticks by the same rules, the
list items keeping the labels they were drawn with.

### Text labels on any axis

```gnuplot
plot 'stations.dat' u 3:0:ytic(5) w lp pi 2 pt 7     # the y ticks named by column 5
set x2tics; plot 'run.dat' u 1:2:x2tic(6)             # x2 labels need x2 ticks on, as gnuplot
```

<Plot name="cb_ytic" svg :width="560" :height="320" />

`xtic(N)` names the x ticks at the abscissae, `x2tic(N)` the x2 ones, `ytic(N)` and `y2tic(N)` the y and y2 ticks at
the ordinates: the labels of a plot replace that axis' ticks, as gnuplot 6.0; the x2 and y2 ones show once `set
x2tics`/`set y2tics` turn the axis ticks on (gnuplot draws none otherwise). One label field per item, the last
`using` field, or one each for two axes (`using 1:2:xtic(""):ytic("")`). In a script an empty label is still a tick, as
gnuplot: `xtic("")` and `ytic("")` mark every row, a rug plot (the library's blank labels are no ticks). The HTML page
keeps the x labels through a zoom; the other axes show numeric ticks while zoomed.

### Geographic tick labels

```gnuplot
set xrange [-180:180]; set yrange [-90:90]
set xtics geographic; set format x "%D %E"     # 150 W ... 0 ... 150 E
set format y "%D %N" geographic                 # 80 S ... 80 N
```

`set xtics geographic` (or `set format x "..." geographic`) labels the ticks in degrees, minutes and seconds,
gnuplot's gstrdms: `%D` whole degrees, `%d` degrees as `%f` (with its width and precision), `%M` and `%m` minutes,
`%S` and `%s` seconds, `%E` E or W and `%N` N or S (blank at 0) in place of the sign; the value is first brought
within -180 to 180. The ticks are placed as on any axis; `timedate` or `numeric` turns the labels back.

## Key

```gnuplot
set key bottom left box
set key center           # centred both ways
set key top center       # top, centred horizontally
set key outside          # right of the plot, top aligned
set key outside left bottom
set key below            # a row below the plot (above: over it), wrapping when the panel is narrow
set key inside           # back inside, keeping the rows
set key lmargin          # in the left margin (rmargin: the right one), aligned with the top of the plot
set key bmargin left     # below the plot, at its left (tmargin: above it), keeping the layout
set key at 60, 1e-2 left top          # its top left corner at x = 60, y = 0.01
set key at graph 0.5, 0.5 center      # centred on the plot area
set key at screen 0.98, screen 0.98   # its top right corner near the top right of the page
```

In a 3D view a key `at screen X,Y` has its top at Y and its right edge at X (its centre with `center`, its left edge
with `left`), its entries laid out as gnuplot's do_3dkey_layout.

Position words apply in order; `center` centres the direction not named yet, as in gnuplot. Titles are right-aligned
with their sample on the right. Inside, the key lies in the plot area. `outside` puts it in the left or right margin,
aligned with the top, centre or bottom of the plot; centred horizontally, above (`top`) or below (`bottom`) the
plot; centred both ways it stays inside, as gnuplot. `below` and `above` centre a row of entries under the x label or
between the title and the plot (`below left` aligns it to the left); `horizontal` and `vertical` choose rows or a
column anywhere. The plot shrinks to make room for a key outside it.

The margins place it as gnuplot: `lmargin` and `rmargin` are `outside` on that side, aligned with the top, centre or
bottom of the plot; `tmargin` and `bmargin` above and below the plot, at its left, centre or right, keeping the
layout (`above` and `below` also centre it and lay it out in rows).

`at POSITION` places the key anywhere, its box aligned on the position as a text: `left`, `right`, `center` put the
left edge, the right edge or the centre of the box there, `top`, `bottom`, `center` its top, bottom or centre (top
right by default). POSITION is `[SYSTEM] X, [SYSTEM] Y`, SYSTEM one of `first` (the x and y values, the default),
`second` (x2 and y2), `graph` (0 to 1 across the plot area, from the bottom left), `screen` (0 to 1 across the page);
y takes the system of x unless given. The plot does not shrink for it. Position words keep `at`; `inside`,
`outside`, a margin, `below` and `above` cancel it, as gnuplot. Not supported: `character` and `polar` coordinates,
`fixed`, `spacing`, `maxcols`, `maxrows`.

```gnuplot
set key box opaque reverse Left invert samplen 2 width 1 title "runs" offset 0,-1
```

<Plot name="cb_key_layout" svg :width="560" :height="320" />

As gnuplot: `reverse` puts the samples left of the titles, `Left` and `Right` justify the titles, `invert` mirrors the
rows of the key (last to first in one column; with several, each entry keeps its column), `opaque` paints the key area with the page color over the plot (its box then hides what passes
under it), `samplen L` makes the samples `L` characters long, `width W` adds `W` characters to the titles,
`offset X,Y` shifts the key by characters (y up; `offset screen X, Y` or `graph` by fractions, y in the system of x
unless given) and `title "text"` puts a row over the entries (centred, or `left`
and `right` after the text: at the left side of the key or the right end of the samples); `default` restores
them all. The samples are gnuplot 6.0's: a line, points, a filled box (its fill border around it when the fill style
has one), an arrow for `vectors` and `arrows`, none for `labels` (their point with `labels point`) and for a
`keyentry` without a style. In a script `samplen L` is L characters plus a tick length (gnuplot's `samplen * h_char +
h_tic`), a boxed key draws a line under its title, and a vertical key taller than the panel wraps into columns, filled
top down, as gnuplot. A character is gnuplot's svg cell, 0.7 font sizes wide and 1.5 high (the 2D key's sample
length `samplen` keeps 0.6 font sizes a character: foresight's 2D key is its own). `font` the key's [font](/guide/gnuplot/text#fonts) (its
rows and widths by its size); `noenhanced` writes the key's texts as they are, not as [enhanced text](/guide/gnuplot/text#enhanced-text).

```gnuplot
set key box lt 4 lw 2 maxrows 3 spacing 1.5 tc variable   # 3 rows a column, titles in their series' colors
set key horizontal maxcols 2 height 1                     # at most 2 entries a row, a character taller
```

`spacing S` sets the rows S apart (in rows, 1 by default), `height H` adds H characters to the key, `maxrows N` gives a
vertical key N rows and as many columns as it needs, filled top down, and `maxcols N` (`maxcolumns`) caps the columns
of a horizontal key (`auto`, as many as fit, by default), as gnuplot; `columns N` lays the key out in exactly N
columns, filled top down (gnuplot's; `maxcol`, `maxrow` abbreviate). `textcolor`/`tc COLOR` writes the titles in a
color, `tc variable` each in the color of its series. After `box`, `lt`, `lw`, `lc`, `dt` and `ls` set its line.

```gnuplot
unset key; plot for [c in "A B C"] 'run.dat' using 1:(column(c)) title columnhead at end
plot 'a.dat' title "left" at 0.75, 0.18, 'b.dat' title at 0.75, 0.15   # one key area for several panels
```

As gnuplot 6.0, `title ... at end` writes the item's title after its last point, left-justified, and `at beginning`
before its first point, right-justified, with or without the key; `at X,Y` (screen coordinates, `screen` optional;
`at graph X, Y` in the plot area's, one system for both) draws a key entry there, the title right-justified at the position and its sample after it, while the key is shown.
These titles leave the key; `title at ...` alone places the automatic title.
`set key auto` is `autotitle`, `fixed` (the key of `splot`) is accepted as it is. `set key default` resets them all.

## Grid, zero axes and border

```gnuplot
set mxtics 5; set mytics 5
set grid x y mx my lc "gray" lw 0.5 dt 3     # major and minor lines, solid gray dots
set grid front                               # over the data
set xzeroaxis lw 1.5; set yzeroaxis          # lines at y = 0 and x = 0, gnuplot's black dots by default
set border 3 lw 1.5                          # the left and bottom sides, thicker
set autoscale xfix                           # x ends at the data, not extended to the ticks
```

<Plot name="cb_grid_zero" svg :width="560" :height="320" />

`set grid` takes the lines to draw as gnuplot: `x`, `y`, `x2`, `y2` at the major ticks and `mx`, `my` at the minor
ones (also written `xtics`, `mxtics`, ...), each turned off with `no` (`noy`); the named lines change, the others are
kept, and with none the x and y lines are drawn. `front` draws the grid over the data, `back` and `layerdefault`
behind it; `lt 0` is foresight's dots (the default), `lt -1` the border's solid black, `lt N` the color of linetype
N, and `lc`, `lw`, `dt` set the line. The HTML viewer redraws the same lines in the same style when zoomed.

`set zeroaxis` (`xzeroaxis`: the line y = 0, `yzeroaxis`: x = 0, `x2zeroaxis`, `y2zeroaxis`) draws lines at the zero
of the axes, behind the data and zoomed with it, gnuplot's black dots by default, with the same line options.
`set border` takes them too, and `front` (foresight draws the border over the data, gnuplot's default).

`set autoscale` autoscales the named axes again (`x`, `y`, `x2`, `y2`, `cb`, `xy`; `xmin`, `ymax`: one end; all
without one); `fix` and `noextend` (and `xfix`, ...) keep the autoscaled ends at the data instead of extending them to
the ticks, as `set xrange [...] noextend`. `set xrange []` keeps the range; `noreverse` and `nowriteback` are accepted.
Not supported: `unset autoscale`, `keepfix` with effect, `writeback`, `restore`.

```gnuplot
set yrange [*<-5:5<*]          # autoscaled, at least from -5 to 5
set xrange [-30<*:*<10]        # autoscaled within [-30:10]
set xrange [-30<*<10:10<*<15]  # the start between -30 and 10, the end between 10 and 15
```

As gnuplot 6.0, an autoscaled end takes limits, `lb<*`, `*<ub` or `lb<*<ub` (x, y, x2, y2 and the color axis): the
end is kept within them before the extension to the ticks, which does not pass the outer one (`lb` of the start, `ub`
of the end). Each end given decides its own limits; `[]` and `set autoscale x` (the axis name alone) forget them, a
bare `set autoscale` keeps them.

## Margins

```gnuplot
set multiplot layout 2,1
set lmargin at screen 0.14; set rmargin at screen 0.95   # the same borders in both panels
plot 'run.dat' u 1:2 w l
plot 'run.dat' u 1:($3*1e6) w l                          # wider y labels: the plot does not move
unset multiplot
```

<Plot name="cb_margins" svg :width="560" :height="360" />

`set lmargin N` (`rmargin`, `tmargin`, `bmargin`) puts the border `N` characters from the panel's edge, `set lmargin at
screen F` at the fraction `F` of the page (from the bottom left), as gnuplot; bare, negative or unset, the margin is
computed from the labels again. `set margins L, R, B, T` sets the four, in gnuplot's order, each `[at screen] N`. A
character is gnuplot's svg cell, 0.7 font sizes wide and 1.5 high (`set lmargin 10` 84 px at 12 pt, as gnuplot). Panels of a multiplot with the same margins
at screen line up whatever their tick labels.

```gnuplot
set timestamp                               # the date and time at the bottom left
set timestamp "%Y-%m-%d %H:%M" top          # in a format, at the top left
set timestamp rotate offset 1,0 tc "gray40" # reading upward on the left
```

`set timestamp` writes the date and time in the bottom left margin, as gnuplot (`top`: the top left one; `rotate`:
reading upward along the left side), in its format (gnuplot's asctime, `"%a %b %d %H:%M:%S %Y"`, by default; the
conversions of [time data](/guide/gnuplot/data#time-data)), the plot area a row (or a column) smaller; `offset` moves it in characters,
`font` its [font](/guide/gnuplot/text#fonts). The time is the local wall clock, or `SOURCE_DATE_EPOCH` (seconds since 1970) when that
variable is set, for reproducible pages: beyond gnuplot, which ignores it. `unset timestamp` removes it.

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
multiplot title, from the bottom left as gnuplot. A `layout` places the panels itself: a `set size` or `set origin`
given before it comes back after `unset multiplot`, as gnuplot's; `reset` outside a multiplot restores size 1,1 and
origin 0,0. Panels may overlap: an inset. A multiplot title on several lines
(`"a\nb"`) takes a row per line, as gnuplot.

```gnuplot
set multiplot title 'Run monitor'
plot 'run.dat' u 1:3 w l t 'cd'
set origin 0.35,0.35; set size 0.55,0.5; unset key; set logscale y
plot 'run.dat' u 1:2 w lp
unset multiplot
```

With `margins L,R,B,T` (screen fractions, or characters after `char`; a unit carries to the next values) the plot
areas of the layout fill that box, `spacing X[,Y]` apart (0.05 screen by default), as gnuplot's
mp_layout_margins_and_spacing; the panels' own margins are kept apart. `spacing` alone does nothing, as gnuplot.

```gnuplot
set multiplot layout 2,2 margins 0.1, 0.95, 0.1, 0.9 spacing 0.08, 0.1 title "aligned panels"
```

Panels are drawn in order, without a background: in the HTML page the mouse acts on the topmost panel under it.
On the standard output (`set terminal dumb` or `block`), a multiplot is printed once, complete, at `unset multiplot`; files are
rewritten at each plot, so that a watched page shows the panels done so far.

## Polar plots

gnuplot's `set polar`: the items are theta:r, drawn at x = (r - rmin) cos(theta), y = (r - rmin) sin(theta) and joined
by straight segments, functions are r of `t`. As in gnuplot, `set polar` alone keeps the rectangular frame and the x
and y ticks, the r axis running from the pole to the right; the round plot is gnuplot's usual idiom:

```gnuplot
set terminal svg size 520,400 theme vfd
set polar; set angles degrees
set size square; unset border; set border polar; unset xtics; unset ytics
set grid polar 30; set ttics 0,30; set key outside
plot 'directivity.dat' u 1:2 w lp t 'probe', 1+cos(t) t 'cardioid'
```

<Plot name="cb_polar" svg :width="520" :height="400" />

- theta is in radians unless `set angles degrees` (which also makes `sin`, `cos`, `tan` take degrees and `asin`, `acos`,
  `atan`, `atan2` return them); `set theta top clockwise` puts theta = 0 at the top, growing clockwise;
- the r range starts at 0 at the pole and ends at the largest |r| extended to the r ticks; `set rrange [1:*]` puts
  r = 1 at the pole: r >= 1 at r - 1 from it, a negative r beyond -1 across it at |r| - 1, the r between -1 and 1
  undefined (gnuplot 6.0's polar_to_xy); with an autoscaled pole a negative r lies across it, as gnuplot; `set rrange
  [90:0]` reverses the r axis: 90 at the pole, 0 on the rim (an elevation), a larger r undefined;
- `set trange [min:max]` samples the functions of `t` over it, and so does the first inline range of a polar plot
  (`plot [0:2*pi] 1 + cos(t)`; the next ones are x and y, as gnuplot); a set end also leaves out the data points of theta
  beyond it (gnuplot 6.0 excludes them), with no wrapping of the angles: `[-90:90]` keeps theta = 0 to 90 of data
  written 0 to 360;
- x and y autoscale to the disc, [-R:R] for R = rmax - rmin, extended to their ticks when these are on;
- `set grid polar` draws rings at the r ticks and spokes (`set grid r` the rings alone), in the grid's line (`set grid
  polar lt -1 lw .5`: black, thin, solid; else foresight's gray dots), `set border polar` the circle
  of rmax, `set ttics` the theta labels outside it (always in degrees; `set ttics add ("π" 180)` names an angle;
  `rotate` turns them along their angle, centred at 1.1 radii, `offset R` moves them out by 0.05 radii a unit, as
  gnuplot's radial use of it; these options alone keep the ticks), `set mttics N` minor ticks on that circle,
  `set size square` keeps the circle round;
- `set logscale r` (base 10) places r at log10(r / rmin) from the pole, rmin the `rrange` start (else the smallest
  positive r), the points below it undefined; the rings and the r ticks follow, `set rtics rotate by A` turns their
  labels, as gnuplot;
- the items are `lines`, `points`, `linespoints`, `impulses` (from the pole), `yerrorbars` (`theta:r:dr` or
  `theta:r:rlow:rhigh`, each bar along the radius with its caps across it, as gnuplot's poldat.dem), `filledcurves`
  (closed, `using theta:r`, or `[above|below] r=V`: the band between the curve and the circle of radius V, where the
  curve is above, or below, it, as gnuplot), `polygons`, `sectors`, `vectors` (`theta:r:dtheta:dr`, from theta:r to
  theta+dtheta:r+dr), `with surface` (below) or readouts (of r), on the first
  axes; x and y stay linear; `using theta:r:z` with points or lines reads the z and ignores it, as gnuplot;
- a curve leaving the r range is cut where it crosses the rim, as gnuplot clips it, a point beyond the rim not drawn;
  `title ... at beginning|end [left|right]` names a curve at its first or last point (on the rim for a cut one);
- `set rlabel "text" [offset X,Y] [tc C] ...` names the r axis, centred over its middle two lines above its tick
  labels (gnuplot 6.0; polar plots only); `set rrange ... noextend` keeps the autoscaled end at the data;
- a plain `set grid` draws rings at the r ticks and spokes at the theta ticks set by the user (`set ttics 0,30,330`,
  START,STEP,END); the spokes end on the largest ring drawn; `set ttics add (...)` alone draws its own labels (`-90` at
  270); `unset polar` clears the theta ticks, as gnuplot;
- `set polar grid [T, R] [qnorm [Q] | gauss | cauchy | exp | box [kdensity]] [scale S] [theta [MIN:MAX]] [r [MIN:MAX]]`
  and `plot ... using theta:r:z with surface`: gnuplot 6.0's polar gridded surfaces. Every point weighs on every cell
  centre of a polar grid of T x R cells (24 x 10 by default) by its polar distance d: 1/d^Q (qnorm, Q 1 by default),
  exp(-(d/S)^2), 1/(1+(d/S)^2), exp(-d/S), or 1 within S (box); a cell takes the weighted mean, or with `kdensity` the
  sum; r runs from 0 to the largest r plus a quarter segment. Each cell is a polygon of its 4 corners in the palette
  color of its value, clipped to the r range, the `r` limits and the `theta` wedge (an end below 0 a turn later), drawn
  with crisp edges (no seams between cells, as gnuplot's svg); the color range covers the whole grid, the key sample is the palette's middle. `unset polar grid` restores the
  defaults.

In the HTML page a polar panel zooms as any other: the curves, rings, spokes and border are data, the r tick labels
and theta labels are hidden while zoomed. Unlike gnuplot, points beyond rmax are clipped at the plot area as the lines
(gnuplot hides them), and the autoscale takes the largest |r| (gnuplot: the largest r, degenerate when all are negative).
