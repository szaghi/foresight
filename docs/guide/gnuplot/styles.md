---
title: Styles
---

# Styles

Plotting styles, colors and point types: lines, boxes, histograms, fills, pies, gauges, readouts and themes. Part of the [gnuplot subset](/guide/gnuplot-subset) reference.

## Styles

```gnuplot
set style data linespoints
set style line 1 lc rgb '#e51e10' lw 2 dt 2
plot 'run.dat' u 1:2 ls 1 t 'residual', '' u 1:3 lt 3 t 'momentum'
```

`ls N` of an undefined style takes the color of linetype `N`, as gnuplot.

`set style data filledcurves OPTIONS` and `set style function filledcurves OPTIONS` (`y=0`, `y1=0`, `x1`, `below`,
...) give their options to the filledcurves items of data or functions given none, the default style or an explicit
`with filledcurves`, as gnuplot; options after another style are refused, as gnuplot.

Style names and `smooth` filters take gnuplot's abbreviations, read from its keyword tables in their order: `l`,
`line`, `p`, `point`, `lp`, `e` (yerrorbars), `errorl` (yerrorlines), `his` (histeps), `hist` (histograms), ...;
`smooth f` (frequency), `cum` (cumulative), `mcs` (mcsplines), `fnor` (fnormal), ...

The linetype colors cycle through gnuplot's sequence: `set colorsequence default` (dark violet, green, sky blue, orange,
yellow, blue, red, black), `podo` (black, orange, sky blue, green, yellow, blue, vermilion, pink) or `classic` (the
13 colors of gnuplot's svg terminal, red, green, blue, cyan, ...). Beyond gnuplot, `set colorsequence batlowS 6` takes
the first 6 colors of a categorical order of the Scientific colour maps (`actonS` ... `turkuS`, 22 orders of 100
colors of the [named palettes](/guide/gnuplot/3d#named-palettes), the most distinct first; 8 by default; any case). The sequence
applies to the series added after it and carries over to the next multiplot panels.

```gnuplot
set linetype 1 lc "dark-violet" lw 2 pt 7
set for [i = 1:3] linetype 10 + i lc "black"
set linetype cycle 4
```

`set linetype N` redefines linetype N, as gnuplot: its color among the linetype colors, its width, dash, point type and
size the defaults of the series of that linetype (`lc`, `lw`, `dt`, `pt`, `ps`; up to linetype 128). The
redefinitions are persistent: `reset` keeps them (`reset session` too, as the color sequence). `set linetype cycle N`
reuses the first N colors for the higher linetypes. An item's `lt N` takes the color of linetype N; `lt rgb COLOR`
(and `lt palette`) is a line color, as `lc`. A linetype color may have an alpha channel (`set linetype 9 lc
"#80bb33bb"`), or be a palette fraction (`lc palette frac F`, the color of the current palette there).

### Color names

```gnuplot
plot sin(x) lc 'green', cos(x) lc rgb 'dark-green', -sin(x) lc rgb '#c04000', -cos(x) lc rgb '#8000c0ff'
```

A color string (after `lc`, `rgb`, `fc`, `tc`, in every command) is read as gnuplot 6.0 reads it: one of its 111 names
(`show colornames`: `red`, `dark-green`, `light-goldenrod`, `gray0` ... `gray100`, case sensitive), or `#` / `0x` and
the hexadecimal number `0xRRGGBB` or `0xAARRGGBB`, the alpha `AA` from 0 (opaque) to 255 (transparent). The names
take gnuplot's colors, not the SVG ones of the same name: `green` is `#00ff00` (SVG's `#008000`), `gray` `#bebebe`,
`grey` `#c0c0c0`, `purple` `#c080ff`. A name not in the table is read as the first name that begins it, as gnuplot's
table lookup: `grey75` is `grey`. An SVG name gnuplot does not know (`darkgreen`, `Green`) is an error, as in
gnuplot: `unrecognized color name "darkgreen" and not a string "#AARRGGBB" or "0xAARRGGBB"`. After `rgb` a string
variable holding the color is read too (`Shade = "#80e0a080"; ... fc rgb Shade`). As gnuplot too, `#0f0`
is the number 0x0000f0, a blue, not CSS's short green. The [library](../library) keeps SVG colors (`lc='green'` is
`#008000` there).

### Colors per point and from the palette

```gnuplot
plot 'run.dat' u 1:2:3 w lp lc variable          # linetype N of column 3 per point
plot 'run.dat' u 1:2:($3*65536) w p lc rgb var    # 24-bit 0xRRGGBB of the last column
plot 'run.dat' u 1:2:4 w l lc palette z           # column 4 through the palette, over the color axis
plot 'run.dat' u 1:2 w boxes lc palette frac 0.3  # one color: 30% along the palette
plot 'run.dat' u 1:2 w l lc palette cb 0.5        # one color: the value 0.5 of the color axis
```

| Color | Meaning |
|---|---|
| `lc variable` | the last `using` column is a linetype number per point, its color in the [color sequence](#styles) |
| `lc rgb variable` | the last `using` column is a color, `0xRRGGBB`, or `0xAARRGGBB` with AA the transparency (0 opaque, 255 invisible), as gnuplot |
| `lc palette` [`z`] | the last `using` column is a value per point, colored through the [palette](/guide/gnuplot/3d#images-and-palettes) over the color axis; the color axis spans these values (unless `set cbrange`) and the color box is drawn |
| `lc palette cb V` | one color for the item: the value V of the color axis (gnuplot's default [-10:10] when nothing sets or spans it) |
| `lc palette frac F` | one color for the item: the fraction F (0 to 1) of the palette |

As gnuplot, a line segment takes the color of its end point; a point whose palette value is undefined is not drawn,
nor the segment to it, but still counts for the autoscale.
The per-point forms (`variable`, `palette z`) apply to `lines`, `points`, `linespoints`, `impulses`, `vectors`,
`arrows`, the error bars (each bar in its point's color), circles, ellipses, boxes, boxerrorbars, boxxyerror,
candlesticks, financebars, histograms (`Y:COLOR` included), filledcurves and polygons (a run of the last two in its
first point's color), and to `labels` as `tc variable`, `tc rgb variable` or `tc palette z` (`using x:y:text:color`);
not with `smooth` or `bins`; `palette cb` and `frac` to every style but the readouts, the panel charts and `labels`, and to
functions; all of them in `set style line`. In the key, the line sample takes the color of the first point and the
point sample that of the last one, as gnuplot. `fc palette cb V` and `fc palette frac F` give an item one palette
color (fill and line). gnuplot 6.0's named colormaps: `set colormap new NAME` saves the current palette as NAME, `set
colormap NAME range [min:max]` gives it a range of its own, and `lc palette NAME` colors the z column of an item by it
(over its range, else over the color axis); `fc palette NAME` colors a pm3d surface by it, read reversed while the
current palette is `negative` (gnuplot's cb2gray flips the gray before the lookup); an undefined NAME is an error.

## Lines, steps and impulses

```gnuplot
plot 'run.dat' u 1:2 w steps, '' u 1:2 w histeps, '' u 1:3:4 w yerrorlines
```

- `steps` joins the points horizontally then vertically, `fsteps` vertically then horizontally;
- `fillsteps` fills the area under `steps`: between two points the box from y = 0 (within the y range; the bottom of
  a log axis) to the first value, in the fill style (`set style fill solid`), as gnuplot; with an empty fill, the
  steps themselves;
- `histeps` draws a step around each point, its edges halfway to the neighbours (the end steps symmetric), from and
  back to y = 0 at the ends; unlike gnuplot the outer edges and 0 are in the autoscale, as for boxes;
- `impulses` draws a segment from y = 0 to each point, 0 included in the y autoscale (as gnuplot);
- `dots` draws a tiny dot per point (point type 0);
- `yerrorlines`, `xerrorlines`, `xyerrorlines` are `linespoints` with the error bars of the matching `errorbars`
  style, with the same `using` layouts.

Functions can be drawn with all of these but the error styles. As gnuplot, `his` abbreviates `histeps`; `histograms`
needs at least `hist`.

## Box, finance and boxplot styles

```gnuplot
set style fill solid 0.3
plot 'bench.dat' u 1:2:3 w boxerrorbars, '' u 1:4:5:6:7 w candlesticks whiskerbars 0.5
plot 'timings.dat' u (1):2:(0.5):1 w boxplot
```

| Style | `using` | Drawing |
|---|---|---|
| `boxerrorbars` | `x:y:ydelta`, `x:y:ydelta:width`, `x:y:ylow:yhigh:width` | a box from 0 (as `boxes`, a width <= 0 meaning `boxwidth`) with a y error bar |
| `boxxyerror` | `x:y:xdelta:ydelta`, `x:y:xlow:xhigh:ylow:yhigh` | a rectangle in the fill style |
| `candlesticks` | `x:open:low:high:close[:width]` (or `x:box_min:whisker_min:whisker_max:box_max`) | a box between open and close, whiskers to low and high; with an empty fill a box whose close is below its open is filled; `whiskerbars [F]` adds crossbars F box widths long |
| `financebars` | `x:open:low:high:close` | a line from low to high, a tick on the left at the open, on the right at the close |
| `boxplot` | `x:y[:width[:factor]]` | the quartiles of the y values as a box with the median line, whiskers to the farthest values within 1.5 interquartile ranges, the others as outliers (point type 7); the whiskers and median in the border color when the fill style has one (`border -1`: black), as gnuplot; with factors, `lc variable` gives each factor the linetype of its index from the item's (`lt 51 lc variable`: 51, 52, ...) |

As gnuplot, the candlestick width is `set boxwidth` or the 6th column, else a few pixels; financebars ticks are a few
pixels long. A **boxplot** summarizes all the values of its item at the x of the first row; a 4th `using` field, a
column number, names the level of each value (its text): one box per level, `separation` apart (1), named on the x axis
in order of appearance (`sorted`: alphabetical). The quartiles are gnuplot's: the value of rank n/4 (the mean of ranks
n/4 and n/4 + 1 when n/4 is whole); a level of fewer than 4 values draws nothing. `set style boxplot fraction 0.95`
has the whiskers span 95% of the values instead, `nooutliers` drops (and leaves out of the autoscale) the outliers,
`financebars` draws the boxplots as finance bars. The box width is the 3rd field, else `boxwidth`, else 0.5; the x
autoscale reaches a box width beyond the boxes, as gnuplot. Boxplots are computed when plotted: a watched script
recomputes them on each change of its data.

## Vectors, ellipses, polygons, labels and sectors

```gnuplot
plot 'flow.dat' u 1:2:3:4 w vectors filled head, '' u 1:2:5 w labels left offset 1,0 point pt 7
plot 'shapes.dat' u 1:2:3:4:5 w ellipses, 'blocks.dat' w polygons fs solid 0.3
set polar; set angles degrees; plot 'wind.dat' u 1:(0):(40):2 w sectors
```

| Style | `using` | Drawing |
|---|---|---|
| `vectors` | `x:y:xdelta:ydelta` | an arrow from x:y to x+xdelta:y+ydelta; after the style `head` (default), `heads`, `nohead`, `backhead`, `filled`, `empty`, `noborder` (filled), `size [first\|graph\|screen\|character] L,A` (head length, x axis values by default, and barb angle [deg]), `fixed`, `as N`\|`arrowstyle N` (the heads, fill, size, color and width of `set style arrow N`) |
| `arrows` | `x:y:length:angle` | an arrow of `length` (> 0: x units, the same on the page at any `angle` [deg]; in (-1, 0): a fraction of the plot width) |
| `ellipses` | `x:y`, `x:y:diameter`, `x:y:major:minor[:angle]` | an ellipse in the fill style, the major diameter in x units and the minor one in y units, rotated on the page (gnuplot `units xy`; `units xx` and `units yy` both in x, or y, units); without diameters (or a negative one) 5% x 3% of the plot; the autoscale takes gnuplot's empirical box: half the larger diameter about the centre, times 1.1 on x for `units xx` and 1.4 on y but for `units yy` (rotated ellipses on unequal scales fit) |
| `polygons` | `x:y` | a closed polygon per block of the data (blocks end at single blank lines), in the fill style |
| `labels` | `x:y:column` | the text of the column at each point; `left`, `center`, `right`, `rotate by A`, `rotate variable` (the angle of a fourth column, `x:y:text:angle`), `offset X,Y` (characters; `offset X` alone, Y 0), `point` (with `pt`, `ps`, `ps variable`; the point in the item's `lc`, black without one, as gnuplot), `hypertext` (the texts not drawn but shown on mouse-over of their points: the browser's tooltip, gnuplot's svg hypertext), `tc "color"`, `tc variable`, `tc palette z` (the color of the last column) anywhere in the item; further columns are read and ignored, as gnuplot; `xticlabels(N)`, `yticlabels(N)` after them name the axes too (`using 0:1:(text):xticlabels(2)`); a text on several lines (`"a\nb"`) one below the other; enhanced text as the other labels |
| `sectors` | `azimuth:radius:angle:width[:x0:y0]` | the annular sector from the azimuth over `angle`, from `radius` over `width`, about x0:y0 (0:0), angles in the `set angles` unit oriented by `set theta`; on a polar panel azimuth:radius are theta:r; `lc variable`, `lc rgb variable`, `lc palette z` (`fc` too: the last column) color each sector, as gnuplot; `units xx` (`yy`) draws them round at the x (y) axis scale; on a polar panel x0:y0 are a theta:r centre, the sector drawn about it (gnuplot's sectors.dem) |

Arrowheads are gnuplot's unless `size` is given: barbs 15 degrees off the shaft, 0.3 of its length, within 2.7 and
18 px (gnuplot's svg), so the heads of arrows shorter than 60 px shrink with them. As label texts they are drawn in
pixels: in the HTML page a zoom moves them with the data and sizes them by the arrows as zoomed. A head with `size`
keeps it unless the arrow is shorter than twice it: the head is then halved to half the arrow, its barbs widened to
spread as far, as gnuplot's; `fixed` keeps it whole. `lc variable`, `lc rgb variable` (0xAARRGGBB, AA the transparency) and `lc palette z` color
each vector or arrow from the last `using` column; a row with an undefined field is no point and out of the color
range, as gnuplot. A second `set style arrow N` changes style N (`default` resets it), as gnuplot. Labels are black
(the frame color of a theme) unless `tc` is given, as gnuplot. Unlike gnuplot, sectors widen the autoscale to their
whole extent. `arrowstyle variable` (`as variable`) reads a style number per arrow from the column after the vector's
(`using x:y:dx:dy:style[:z]`): each arrow takes the heads, fill, head size, width and color of `set style arrow N`, a
style of `lc palette z` the palette color of the z column; a style not defined leaves the arrow the item's own. The
arrow words may come among the other item options (`with vectors lt 4 filled`). Not supported: the dashes of an arrow
style on data arrows, the back angle of `size`, label fonts and `hypertext`.

## Parallel axes and spider plots

```gnuplot
plot 'scores.dat' u 2 w parallelaxes t 'speed', '' u 3 w parallelaxes t 'memory', '' u 4 w parallelaxes t 'cost'

set spiderplot
set style spiderplot fs transparent solid 0.2 border
set paxis 1 range [0:100]; set paxis 1 tics; set grid spiderplot
plot 'scores.dat' u 2:key(1) t 'speed', '' u 3 t 'memory', '' u 4 t 'cost'
```

As gnuplot, each item is an **axis** (a column of the data) and each **row** a line across the axes (`parallelaxes`)
or a polygon (`spiderplot`); both are alone in their panel.

- Every axis has its own scale, `set paxis N range [min:max]`, autoscaled to its values without extension (the
  smallest at the bottom or at the centre); its ticks are off until `set paxis N tics` (the `set xtics` forms).
- `parallelaxes`: the axes at x = 1, 2, ... (or `at X`), the x range one unit beyond them, titled below by their
  items' explicit titles (an automatic one names none, as gnuplot); each axis line and its ticks over the extent of
  its values, its range the scale (gnuplot's); the frame unless `unset border`; with `lc palette` the color box of
  the z range; the rows in the first item's style, or each in its own color: `lc variable` or `lc palette` on the first item
  reads a second field (`using 1:5 lc variable`, the color of every row from column 5). Unlike gnuplot, no y axis is
  drawn: its numbers would belong to no axis.
- `spiderplot` (after `set spiderplot`, or `with spiderplot`): the axes from the centre, the first up, the others
  clockwise, labelled by their item titles (else `set paxis N label`); a polygon per row in its linetype color and the
  `set style spiderplot` fill, named in the key by `using ...:key(N)` (the text of column N); `set grid spiderplot` draws
  the web at the ticks of the first axis.

foresight's own [`with radar`](#gauges-radars-and-roses) is the transposed shorthand: an item per polygon, a spoke per
row, a common scale.

`newspiderplot` starts a new set of items: their polygons share the axes of the first set (scaled on the values of
every set), its series restarting at the first axis; the polygons of a set take the color and width of its first item
when given, as gnuplot; the axes are named by the first set. `keyentry with spiderplot ... title "T"` adds a key entry
of its own color, no axis. An array source gives one row in a spider plot (its first element), as gnuplot 6.0. Not
supported: `set style parallelaxis`, `lc variable` on the axes lines.

## Point types

```gnuplot
plot 'run.dat' u 1:2 w lp pt 7 t 'residual', '' u 1:3 w p pt 4 ps 1.5 t 'cd'
```

The shapes are those of gnuplot's svg terminal: `pt 0` a dot, 1 plus, 2 cross, 3 star, 4 square, 6 circle,
8 triangle, 10 inverted triangle, 12 diamond, 14 pentagon, each odd type from 5 the filled shape before it; beyond 15
they cycle. A marker is 9 px wide at `ps 1`, its lines about `ps` px wide whatever `lw`, as gnuplot's svg (0.222 of the half width; the dot 0.5 px). Without `pt` an item draws the point type of its
linetype, as gnuplot 6.0: the k-th item type k (cycling every 15), `lt N` of the eight predefined linetypes type N,
`ls N` the point type of its style (of its `lt`, else type N up to 8, else 1); a keyentry does not use one up.
`pt variable` takes each point's type from a column (after the sizes of `ps variable`, before the colors of
`lc rgb variable`: `using 1:2:size:type:color`), its integer part, a dot for 0 and less; its key sample is a dot, as
gnuplot's. The
library's own `plot` keeps foresight's round dot, 6 px at `ps 1`, without `pt`. In the HTML page markers keep their shape and size under zoom; the text terminal draws every point
with the symbol of its color. `set pointsize S` sets the size of the points without their own `ps` (an item's `ps`
replaces it, as gnuplot's); `unset pointsize` and `reset` restore 1.

```gnuplot
plot '+' using 1:(cos(x)) with linespoints pt "C" pi 4 tc rgb "blue"   # a character every 4 points, in blue
plot 'run.dat' with linespoints pt "✠" pn 10                           # about 10 points, evenly spread
```

`pt "c"` draws the first character of the string (UTF-8) as the point, centred, in the series color or the item's
`tc` color, as text that keeps its size under zoom; also in `set style line`. An item's `font` is its labels' (`with labels font ",8"`); the characters of `pt "c"` keep the page's.
`pn N` (`pointnumber`) marks about N of the placeable points, every (count-1)/(N-1)-th, the start shifted by the
item's number, as gnuplot.

```gnuplot
set jitter overlap 1 spread 0.5            # a swarm: overlapping points moved aside
set jitter square; set jitter vertical     # also onto one row; along y instead
```

`set jitter` spreads out the overlapping points of `with points`, by gnuplot's algorithm: the points sorted by x
then y, each one closer than `overlap` (characters, 1 by default, or y units after `first`) to the first point of its
group moves aside by (j+1)/2 `spread` point sizes of 0.7 characters, alternately left and right, back within `wrap`
characters if given; `square` also puts it on the row of the first point, `vertical` moves it along y instead. `unset
jitter` turns it off. Departures: foresight's characters are narrower than gnuplot's svg ones (0.6 by 1 font sizes,
gnuplot's 0.7 by 1.5), so its swarms are a little narrower; `with impulses` is not jittered; the HTML page zooms the
moved markers with the data.

## Boxes and filled curves

```gnuplot
set style fill solid 0.5
set boxwidth 0.8 relative
plot 'run.dat' every 10 u 1:5 w boxes t 'cd every 10 iterations'
```

<Plot name="cb_boxes" svg :width="560" :height="320" />

A box stands on y = 0, down for a negative value. By default the boxes touch: each edge lies halfway to the next
point, the end boxes symmetric. `set boxwidth W` gives them the width W, `set boxwidth F relative` the fraction F of
the default, a third `using` column each its own width. The fill is the item color: `empty` draws the border only,
`solid D` fills at opacity D (`transparent` changes nothing in SVG, as in gnuplot's svg terminal); `border lc C`
colors the border, `noborder` drops it.

```gnuplot
plot 'run.dat' u 1:($5-$6):($5+$6) w filledcurves fs transparent solid 0.3 t 'cd +/- dcd', \
     ''        u 1:5 w l t 'cd'
```

<Plot name="cb_filledcurves" svg :width="560" :height="320" />

`filledcurves` fills the band between two columns (`x:y1:y2`), the area down to the line `y=V` (`y1=V`, `y2=V`), to
the bottom (`x1`) or top (`x2`) of the plot, across to the left (`y1`, `y`) or right (`y2`) border, across to the
vertical line `x=V` (`x1=V`, `x2=V`, as gnuplot 6.0 draws them), to the point `xy=X,Y`, or the polygon of the points
(`closed`, the default with two columns); `above` and `below` keep the parts where the curve is above or below its
line (`y=V`), or where the first curve of a band is above or below the second; without a line nor a band they fill
against y = 0, and next to an axis word (`above x1`) they are ignored, as gnuplot 6.0. As gnuplot, it fills even with
an `empty` fill style. In a script the fill style's border is drawn where gnuplot 6.0 draws it: around the key sample,
and along a closed curve (the curve, not its closing side); a fill to a line, an axis or a band has none (plot the
curve too for an outline); the library draws no border. A band takes the curve filters: `using 1:2:3 smooth
csplines` smooths both curves on the same samples. Undefined points split the fill as they split a line.

`fs pattern N` fills with one of the 8 patterns of gnuplot's svg terminal: 0 empty, 1 and 2 crosshatches, 3 solid,
4 to 7 hatches (down, up, steeper up, steeper down), N cycling every 8; `set style fill pattern N` gives the filled
items of a plot the patterns N, N + 1, ... as gnuplot. In text a pattern is a fill character (`x`, `X`, `\`, `/`),
in `block` its hatches are dots.

Two deliberate differences from gnuplot, so that a bar is never misread:

- **The y autoscale of boxes reaches 0** (and that of `filledcurves y=V` reaches V). gnuplot autoscales to the values
  only and draws the bars from the bottom of the plot: with values 3, 5, 2 it draws the 3 a third as long as the 5.
- **The x autoscale reaches the box edges** whatever the width. With touching boxes gnuplot leaves them out and cuts
  the first and last bar in half.

In text a fill is drawn with the symbol of its series (`block`: whole dots), whatever its opacity.

## Histograms

```gnuplot
set style fill solid 0.6 border -1
plot 'timings.dat' u 2:xtic(1) w histograms t 'mesh', '' u 3 w hist t 'fluxes', '' u 4 w hist t 'comm'
```

<Plot name="cb_histograms" svg :width="560" :height="320" />

Each `histograms` item gives one bar per row of its file, the rows at 0, 1, 2, ...; the items of a panel are laid out
together, as gnuplot:

- `set style histogram clustered gap G` (the default, gap 2): the k items of a row side by side, each bar 1/(k + G)
  wide, the cluster centred on its row;
- `set style histogram rowstacked`: one stack per row, 1 wide; positive values pile up from 0, negative ones down
  from 0, each sign on its own stack; an item without a row (a missing value) leaves the stack of that row to the
  others, the next rows unchanged.
- `set style histogram columns` (`columnstacked`): one stack per item, named under it by its title, its rows in the
  colors of their linetypes, or each its own with `lc variable` (a function of the row's category, as gnuplot's
  histogram_colors demo).

A table of histograms (`set table`) writes their values, not the stacked tops.

`set boxwidth F` scales every bar. The x autoscale goes one unit beyond the first and last rows, as gnuplot; the y one
reaches 0 for clustered bars too (gnuplot leaves it out, as for [boxes](#boxes-and-filled-curves)). The fill is
`set style fill` or the item's `fs`.

`using Y:xtic(N)` labels each row with the text of column N (quoted, it may hold blanks): when any item has labels,
they replace the x ticks, at their rows, as gnuplot; the HTML page keeps them through a zoom. `xtic` works with any
style, `using 0:2:xtic(1) w boxes` too, and takes a [string expression](/guide/gnuplot/data#string-columns).

```gnuplot
set style histogram errorbars gap 1 lw 2
plot 'timings.dat' u 2:3:xtic(1) t 'mesh', '' u 4:5 t 'fluxes'          # y:err, or y:low:high
set style histogram columnstacked
plot 'shares.dat' u 2 t columnhead, '' u 3 t columnhead, '' u 4:key(1) t columnhead
set style histogram clustered gap 1
plot newhistogram 'CPU', 'cpu.dat' u 2:xtic(1) t 'mesh', '' u 3 t 'solve', \
     newhistogram 'GPU' lt 1 fs pattern 4, 'gpu.dat' u 2:xtic(1) notitle, '' u 3 notitle
```

- `set style histogram errorbars [gap G] [lw W]` lays the bars out as `clustered`, each with its error bar at its
  centre: `using Y:ERR` (from `Y - ERR` to `Y + ERR`) or `using Y:LOW:HIGH`, in the border color of the fill (the item
  color without a border), `W` px wide.
- `set style histogram columnstacked` makes one stack per item at 0, 1, 2, ...: its rows stacked (positive values up,
  negative ones down), each row in the color of its linetype, as gnuplot. `key(N)` names the rows in the key (the
  last row first, as gnuplot); `title columnhead` labels the stack on the x axis.
- `newhistogram ["title"] [lt N] [fs FILL] [at X]` starts a group of histograms in the plot: its rows (or stacks)
  from `X`, else 2 rows after the last one of the previous group (the first group from its rows), its title centred
  below the x tick labels (the HTML page hides it while zoomed), the default colors of its items from linetype `N`,
  their fill `FILL`. The gap and the bar widths are those of each group (`1/(k + gap)` for its k items).

`set style histogram ... title [tc C] [offset X,Y]` colors and moves the group titles (`offset` in characters; a
`font` their [font](/guide/gnuplot/text#fonts)); `nokeyseparators` is accepted, foresight drawing no blank key row between the groups
where gnuplot does by default. `set errorbars` sets the [caps](/guide/gnuplot/plot-items#error-bar-caps) of the error bars.

The rows of a histogram are its abscissae as given (the point numbers from a script): a header row that is not a
number counts, as gnuplot.

## Readouts

A foresight extension, not gnuplot (gnuplot rejects these scripts): `with readout` shows the last finite value of an
item in seven-segment digits, as the digital instrument clusters of 1980s cars. It is made for live monitoring with
[`--watch`](../monitoring) and for showcase pages, not for publication figures.

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
  [tick format](/guide/gnuplot/axes#ticks-and-label-formats) with a field width (`%9.2e`, not `%.2e`), without `%h`. Each character of
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

## Circles, pies and donuts

```gnuplot
set style fill solid 0.4
plot 'scaling.dat' u 2:3:4 w circles t 'memory [GB] as radius'
```

<Plot name="cb_circles" svg :width="560" :height="320" />

`with circles` draws a circle per point, as gnuplot: its radius in x-axis units (the third column; 2% of the plot
width without it), round on the page whatever the axis scales, filled with the fill style. The x autoscale widens to
the circles, the y one does not (gnuplot's choice: their height in y units depends on the page). With two more
columns, a start and an end angle in degrees counterclockwise from the x direction, it draws wedges.

```gnuplot
set title 'Time per step'
plot 'phases.dat' u 2:xtic(1) w pie
```

<Plot name="cb_pie" svg :width="480" :height="320" />

`with pie` is a foresight extension (gnuplot draws pies only through `circles` and computed angles): one slice per row,
proportional to the values, from 12 o'clock clockwise, each in its linetype color; the key lists the slices with their
`xtic` names and percentages. `donut F` leaves a hole of F times the radius. A pie is alone in its panel, without axes,
and takes non-negative values only: slices compare parts of a whole, which a signed quantity is not. Angles read less
precisely than lengths: for comparing the parts, [histograms](#histograms) are the better chart.

<Plot name="cb_donut_vfd" svg :width="480" :height="320" />

## Gauges, radars and roses

Foresight extensions, charts alone in their panel like the pie (several gauges or radar items side by side).

```gnuplot
set terminal svg size 600,240 theme vfd
plot 'run.dat' u 1 w gauge range [0:150] segments 24 format '%3.0f' t 'ITER', \
     ''        u 5 w gauge range [0:0.6] segments 24 format '%5.3f' t 'CD'
```

<Plot name="cb_gauges" svg :width="600" :height="240" />

**A gauge** shows the last finite value of its item, as a [readout](#readouts), on a 270-degree track from 7:30
clockwise to 4:30 over `range [A:B]` (required: a dashboard scale is fixed). The track is drawn faintly and lit up to
the value, in `segments N` cells if set (a cell lit when covered at least half); the scale ticks lie outside, the value
in seven-segment digits of `format` under the centre, titled by the item. A value beyond the range fills the track,
the digits still give it.

```gnuplot
set style fill solid 0.3
plot 'radar.dat' u 2:xtic(1) w radar t 'gpu', '' u 3 w radar t 'cpu'
```

<Plot name="cb_radar" svg :width="480" :height="320" />

**A radar** (spider) chart has a spoke per row, from 12 o'clock clockwise, named by the `xtic` labels; every item is a
polygon over the spokes on a common radial scale from 0 (or the smallest value, if negative), its rings at the ticks.

```gnuplot
plot 'phases.dat' u 2:xtic(1) w rose
```

<Plot name="cb_rose" svg :width="480" :height="320" />

**A rose** (Nightingale) chart has equal sectors, one per row in the linetype colors, named in the key. A sector's
**area** is proportional to its value, so twice the value looks twice as large; `rose linear` makes the radius
proportional instead, the common but exaggerating choice (twice the value, four times the area). The rings mark the
values of the scale.

## Themes and segmented fills

Foresight extensions: the look of the digital dashboards of 1980s cars, for monitoring and showcase pages, and the
two faces of foresight's own identity, the colors of this site in its light and dark modes.

```gnuplot
set terminal svg size 640,440 theme vfd
set multiplot title 'RUN MONITOR'
set origin 0,0.62; set size 0.4,0.38; set readout vertical
plot 'run.dat' u 1 w readout format '%4.0f' t 'ITER', '' u 5 w readout format '%6.4f' t 'CD'
set origin 0.4,0.62; set size 0.6,0.38; set key top left
set style fill solid segments 10
plot 'timings.dat' u 2:xtic(1) w hist t 'mesh', '' u 3 w hist t 'fluxes'
set origin 0,0; set size 1,0.62; set key top right
set logscale y; set grid
plot 'run.dat' u 1:2 w l lw 2 t 'continuity', '' u 1:3 w l lw 2 t 'momentum'
unset multiplot
```

<Plot name="cb_vfd" svg :width="640" :height="440" />

**Themes** recolor the output, never the figure: `classic` (the default) changes nothing; `vfd` is a vacuum
fluorescent display, black glass, emissive series colors (cyan-green, amber, red, ...), the frame and labels printed in
blue, the data glowing; `lcd` a backlit liquid crystal display, pale green glass and dark segments; `washi` ink on warm
paper with a crimson first series, and `night` light text on a near-black red ground with a rose first series, the
light and dark modes of this site (its figures are drawn in them), every series color at least 3:1 against its ground.
The default linetype
colors (not another `set colorsequence`), the frame, grid and page become the theme ones; a color you give (`lc '#123456'`) is kept. `glow` and
`noglow` override the theme (only `vfd` glows by default); the glow is an SVG filter, so converters that do not render
filters (some PDF ones) drop or rasterize it. In the HTML page, the ticks and grid redrawn by a zoom take the theme
colors. In text the theme only recolors the series, with `ansi`, `ansi256` or `ansirgb`: the terminal background is
not foresight's.

**Segmented fills**, `fs solid segments N` (boxes, histograms): the y range is cut into N cells, the same for every
bar, as on a fixed-segment display. A bar lights the cells it covers at least half (it reads to the nearest cell: a
quantization, a display choice, not a measurement), the other cells of its column are drawn faintly (not drawn in
text). Zooming magnifies the cells with the data.
