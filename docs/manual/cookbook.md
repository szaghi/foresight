---
title: Cookbook
---

# Cookbook

One task per recipe: the script (or program), and the plot it writes. The scripts read the logs of the
[tutorial](./index) solver, `run.dat` and `run.csv`, and a few small files; run any of them with `foresight SCRIPT`.
Every plot here is regenerated from its recipe by `scripts/docs_examples.sh` and checked by the CI.

[[toc]]

## Data and columns

### Two columns of a file

<<< @/examples/snippets/cb_columns.gp{gnuplot}

<Plot name="cb_columns" svg :width="560" :height="320" />

### A single column

<<< @/examples/snippets/cb_single_column.gp{gnuplot}

<Plot name="cb_single_column" svg :width="560" :height="320" />

With one column, x is the point number, as `using 0:1`; `using 2` alone does the same for column 2.

### One point every N

<<< @/examples/snippets/cb_every.gp{gnuplot}

<Plot name="cb_every" svg :width="560" :height="320" />

`every I:J:K:L:M:N` is gnuplot's full form: point and block increments, first and last points and blocks.

### One dataset of a file

<<< @/examples/snippets/cb_index.gp{gnuplot}

<Plot name="cb_index" svg :width="560" :height="320" />

Two blank lines separate datasets; `index N` (0-based) picks one.

### Scale and shift columns

<<< @/examples/snippets/cb_expression.gp{gnuplot}

<Plot name="cb_expression" svg :width="560" :height="320" />

A parenthesized field is an expression evaluated per row: `$N` is column N, `$0` the point number.

### Keep only some points

<<< @/examples/snippets/cb_filter.gp{gnuplot}

<Plot name="cb_filter" svg :width="560" :height="320" />

`1/0` is undefined: the point is dropped, a gap in a line.

### CSV with a header row

<<< @/examples/snippets/cb_csv_header.gp{gnuplot}

<Plot name="cb_csv_header" svg :width="560" :height="320" />

Quoted names select columns by header; `title columnhead` titles with the header of the y column. `set key autotitle columnhead` does it for every item.

### Missing values and other comment marks

<<< @/examples/snippets/cb_missing.gp{gnuplot}

<Plot name="cb_missing" svg :width="560" :height="320" />

The `-` cells are missing data: those points are left out and the lines go on; `%` starts the comments of this file.

## Axes, ticks and key

### A log axis with exponent labels

<<< @/examples/snippets/cb_logscale.gp{gnuplot}

<Plot name="cb_logscale" svg :width="560" :height="320" />

### A reversed axis

<<< @/examples/snippets/cb_reversed.gp{gnuplot}

<Plot name="cb_reversed" svg :width="560" :height="320" />

### Tick steps and label formats

<<< @/examples/snippets/cb_ticks.gp{gnuplot}

<Plot name="cb_ticks" svg :width="560" :height="320" />

On a log axis the step is a factor: `set ytics 10` puts a tick every decade.

### Named ticks and extra ticks

<<< @/examples/snippets/cb_tics_list.gp{gnuplot}

<Plot name="cb_tics_list" svg :width="560" :height="320" />

An explicit list replaces the ticks: names at chosen positions, `""` with level `1` for an unlabelled minor tick. With
`add` the list joins the automatic ticks; a label holding a conversion is the format of its position (`"%.0f mm"`).

### Minor ticks

<<< @/examples/snippets/cb_mtics.gp{gnuplot}

<Plot name="cb_mtics" svg :width="560" :height="320" />

`set mxtics 4` divides each step of x in 4; `set mytics` alone takes gnuplot's count, 9 per decade on a log axis.

### Rotated labels and outward ticks

<<< @/examples/snippets/cb_tics_rotate.gp{gnuplot}

<Plot name="cb_tics_rotate" svg :width="560" :height="320" />

Long category names fit rotated: `rotate by 30 right` ends each label at its tick, below the axis. `out` points the
ticks away from the plot; `nomirror` leaves the opposite border bare.

### Two y axes

<<< @/examples/snippets/cb_y2.gp{gnuplot}

<Plot name="cb_y2" svg :width="560" :height="320" />

### Two x axes

<<< @/examples/snippets/cb_x2.gp{gnuplot}

<Plot name="cb_x2" svg :width="560" :height="320" />

The top border in another unit: with no item on it, the x2 axis takes the `x2range` given, here the frequency scaled
to the Strouhal number. Items plotted `axes x2y1` scale it on their own instead.

### The key below the plot

<<< @/examples/snippets/cb_key.gp{gnuplot}

<Plot name="cb_key" svg :width="560" :height="320" />

`outside` moves the key to the right margin (or `outside left`, `outside top center`, ...); `below` and `above` lay it out in rows.

### No key

<<< @/examples/snippets/cb_no_key.gp{gnuplot}

<Plot name="cb_no_key" svg :width="560" :height="320" />

`notitle` keeps one item out of the key; `set key noautotitle` all the untitled ones.

### A grid of panels

<<< @/examples/snippets/cb_multiplot.gp{gnuplot}

<Plot name="cb_multiplot" svg :width="560" :height="420" />

## Lines, points and error bars

### User variables and functions

<<< @/examples/snippets/cb_user_functions.gp{gnuplot}

<Plot name="cb_user_functions" svg :width="560" :height="320" />

`name = value` and `name(t) = expression` as in gnuplot: the functions read the variables when the plot is drawn,
and the range ends take expressions. See [User variables and functions](/guide/gnuplot-subset#user-variables-and-functions).

### Line styles and point types

<<< @/examples/snippets/cb_styles.gp{gnuplot}

<Plot name="cb_styles" svg :width="560" :height="320" />

`set style line N` defines a style once; `ls N` applies it, the options after it override it.

### A color per point

<<< @/examples/snippets/cb_lc_variable.gp{gnuplot}

<Plot name="cb_lc_variable" svg :width="560" :height="320" />

`lc variable` reads the color of each point from the last `using` column, a linetype number; a segment takes the color
of its end point, as in gnuplot. `lc rgb variable` reads 24-bit colors instead (`0xRRGGBB`).

### Color sequences

<<< @/examples/snippets/cb_colorsequence.gp{gnuplot}

<Plot name="cb_colorsequence" svg :width="760" :height="320" />

`set colorsequence default|podo|classic` picks gnuplot's linetype colors; foresight's `set colorsequence batlowS 6`
takes the first colors of a categorical order of the Scientific colour maps, the most distinct first. See
[Styles](/guide/gnuplot-subset#styles).

### Error bars

<<< @/examples/snippets/cb_errorbars.gp{gnuplot}

<Plot name="cb_errorbars" svg :width="560" :height="320" />

`x:y:dy`, or `x:y:low:high`; the caps keep their size under zoom.

### Error bars on both axes

<<< @/examples/snippets/cb_xyerrorbars.gp{gnuplot}

<Plot name="cb_xyerrorbars" svg :width="560" :height="320" />

`with xyerrorbars` takes `x:y:dx:dy`, or `x:y:xlow:xhigh:ylow:yhigh`.

### Lines through error bars

<<< @/examples/snippets/cb_errorlines.gp{gnuplot}

<Plot name="cb_errorlines" svg :width="560" :height="320" />

`yerrorlines` and `xyerrorlines` are `linespoints` with the error bars of the matching `errorbars` style and the same
`using` layouts. See [Lines, steps and impulses](/guide/gnuplot-subset#lines-steps-and-impulses).

### Steps

<<< @/examples/snippets/cb_steps.gp{gnuplot}

<Plot name="cb_steps" svg :width="560" :height="320" />

`steps` goes horizontally then vertically, `fsteps` the other way round, `histeps` draws a step around each point
(edges halfway to the neighbours) from and back to 0. An adaptive time step reads best as steps.

### A spectrum: impulses and dots

<<< @/examples/snippets/cb_impulses.gp{gnuplot}

<Plot name="cb_impulses" svg :width="560" :height="320" />

`impulses` draws a segment from y = 0 to each point (0 is in the autoscale, as gnuplot); `dots` a tiny dot per point.

### Functions of x

<<< @/examples/snippets/cb_function.gp{gnuplot}

<Plot name="cb_function" svg :width="560" :height="320" />

Without data, functions are sampled over [-10:10], or the `xrange`; `set samples` sets the number of points.

### A range for one plot

<<< @/examples/snippets/cb_inline_range.gp{gnuplot}

<Plot name="cb_inline_range" svg :width="560" :height="320" />

Inline ranges set x, then y, for that plot only: `set xrange` is left alone. `t=` names the variable of the functions.

### A model over the data

<<< @/examples/snippets/cb_model.gp{gnuplot}

<Plot name="cb_model" svg :width="560" :height="320" />

A function is sampled over the x range of the data of the same plot.

### Histogram and distribution

<<< @/examples/snippets/cb_smooth.gp{gnuplot}

<Plot name="cb_smooth" svg :width="560" :height="320" />

`smooth frequency` sums the y of the points of equal x: binned x and y = 1 count the points per bin (`bins` does the
binning itself: [a histogram of a sample](#a-histogram-of-a-sample)). `smooth cnormal`
accumulates them over the sorted x, divided by the total: the fraction of iterations below each value. `smooth unique`
averages repeated x instead. See [Smoothing](/guide/gnuplot-subset#smoothing).

### Splines and densities

<<< @/examples/snippets/cb_splines.gp{gnuplot}

<Plot name="cb_splines" svg :width="760" :height="320" />

`csplines` passes through every point; `acsplines` weighs fit against smoothness (smaller weights, smoother curve);
`sbezier` stays inside the points. `kdensity` estimates the distribution of a sample: gnuplot's bandwidth by default,
narrower to show more detail.

### A monotone interpolation

<<< @/examples/snippets/cb_mcsplines.gp{gnuplot}

<Plot name="cb_mcsplines" svg :width="560" :height="320" />

The natural spline (`csplines`) swings above and below each plateau of the time step; the monotone spline of
Fritsch and Carlson (`mcsplines`) passes through the same points and never beyond them: a step stays a step, a
positive quantity stays positive. See [Smoothing](/guide/gnuplot-subset#smoothing).

## Bars and statistics

### A bar chart

<<< @/examples/snippets/cb_boxes.gp{gnuplot}

<Plot name="cb_boxes" svg :width="560" :height="320" />

Boxes stand on y = 0 and the autoscale reaches 0 and the box edges, unlike gnuplot: bar lengths are proportional to
the values. See [Boxes and filled curves](/guide/gnuplot-subset#boxes-and-filled-curves).


### A histogram of a sample

<<< @/examples/snippets/cb_bins.gp{gnuplot}

<Plot name="cb_bins" svg :width="560" :height="320" />

`bins` counts the values of one column in bins of equal width: here 0.02 s, as few bins as cover the data. Boxes
touch, and the autoscale reaches the outer bin edges and 0. The kernel density of the same column, each point weighted
by the bin width, lands on the same scale. See [Bins](/guide/gnuplot-subset#bins).
### Grouped bars with category labels

<<< @/examples/snippets/cb_histograms.gp{gnuplot}

<Plot name="cb_histograms" svg :width="560" :height="320" />

`xtic(1)` labels each row with the text of column 1; the labels replace the x ticks.

### Stacked bars

<<< @/examples/snippets/cb_rowstacked.gp{gnuplot}

<Plot name="cb_rowstacked" svg :width="560" :height="320" />

`rowstacked` piles the items of a row on one bar; `set boxwidth 0.6` leaves room between the stacks. See
[Histograms](/guide/gnuplot-subset#histograms).

### Bars with error bars

<<< @/examples/snippets/cb_boxerrorbars.gp{gnuplot}

<Plot name="cb_boxerrorbars" svg :width="560" :height="320" />

`boxerrorbars` is `boxes` with the y error bars: `x:y:ydelta`, `x:y:ydelta:width` or `x:y:ylow:yhigh:width`; `xtic(4)`
names the bars. See [Box, finance and boxplot styles](/guide/gnuplot-subset#box-finance-and-boxplot-styles).

### Pattern fills

<<< @/examples/snippets/cb_patterns.gp{gnuplot}

<Plot name="cb_patterns" svg :width="560" :height="320" />

`set style fill pattern N` hatches the filled items, the pattern cycling from N item after item as in gnuplot: the 8
patterns of its svg terminal (0 empty, 1 and 2 crosshatches, 3 solid, 4 to 7 hatches), for prints without color.

### Candlesticks and finance bars

<<< @/examples/snippets/cb_candlesticks.gp{gnuplot}

<Plot name="cb_candlesticks" svg :width="560" :height="320" />

`candlesticks` take `x:open:low:high:close` (here the first, smallest, largest and last residual of each window of 50
iterations): a box between open and close, whiskers to low and high, `whiskerbars 0.5` crossbars. With an empty fill a
falling candle (close below open) is filled, as gnuplot: a converging run fills them all. `financebars` draw the same
as a line with an open tick on the left and a close tick on the right.

### Box plots by category

<<< @/examples/snippets/cb_boxplot.gp{gnuplot}

<Plot name="cb_boxplot" svg :width="560" :height="320" />

`boxplot` summarizes the values of its item: quartiles, median, whiskers to the farthest values within 1.5
interquartile ranges, the others as outliers. The 4th `using` field is a factor column: one box per solver, named on
the x axis. `set style boxplot` sets the whisker range, outliers, sorting.

## Areas and shapes

### A band around a curve

<<< @/examples/snippets/cb_filledcurves.gp{gnuplot}

<Plot name="cb_filledcurves" svg :width="560" :height="320" />

`x:y1:y2` fills between two columns; `filledcurves y=0` fills down to a line.

### Fill above and below a line

<<< @/examples/snippets/cb_fill_above.gp{gnuplot}

<Plot name="cb_fill_above" svg :width="560" :height="320" />

`filledcurves above y=V` and `below y=V` keep the parts of the area to the line where the curve is above or below it;
`x1` and `x2` fill to the bottom and top of the plot, `xy=X,Y` to a point. The restart at iteration 60 splits the fill as
it splits a line.

### Rectangles

<<< @/examples/snippets/cb_boxxyerror.gp{gnuplot}

<Plot name="cb_boxxyerror" svg :width="560" :height="320" />

`boxxyerror` draws a rectangle per row, from `x:y:xdelta:ydelta` or `x:y:xlow:xhigh:ylow:yhigh`: here the blocks of a
domain decomposition.

### A bubble chart

<<< @/examples/snippets/cb_circles.gp{gnuplot}

<Plot name="cb_circles" svg :width="560" :height="320" />

The third column is the radius, in x units. See [Circles, pies and donuts](/guide/gnuplot-subset#circles-pies-and-donuts).

### A vector field with labelled probes

<<< @/examples/snippets/cb_vectors.gp{gnuplot}

<Plot name="cb_vectors" svg :width="560" :height="400" />

`vectors` draws an arrow from `x:y` by `xdelta:ydelta` (`head`, `heads`, `nohead`, `backhead`, `filled`); `labels`
writes the text of a column at each point, here with its point and an offset. See
[Vectors, ellipses, polygons, labels and sectors](/guide/gnuplot-subset#vectors-ellipses-polygons-labels-and-sectors). In the
HTML page the heads and the labels keep their size while the zoom moves them with the data.

### Arrows by length and angle

<<< @/examples/snippets/cb_arrows.gp{gnuplot}

<Plot name="cb_arrows" svg :width="560" :height="320" />

`arrows` takes `x:y:length:angle`, the length in x units and the same on the page at any angle (in degrees).

### Uncertainty ellipses

<<< @/examples/snippets/cb_ellipses.gp{gnuplot}

<Plot name="cb_ellipses" svg :width="560" :height="320" />

`ellipses` takes `x:y:major:minor:angle`, the diameters in x and y units, rotated on the page as gnuplot does.

### Polygons from blocks

<<< @/examples/snippets/cb_polygons.gp{gnuplot}

<Plot name="cb_polygons" svg :width="560" :height="320" />

`polygons` closes each block of the file (blocks end at a blank line) into a polygon in the fill style: mesh cells,
regions, outlines.

## Heatmaps and images

### A heatmap

<<< @/examples/snippets/cb_image.gp{gnuplot}

<Plot name="cb_image" svg :width="560" :height="400" />

`x:y:z` points on a regular grid, colored by the default palette; the color box at the right.

### A matrix file

<<< @/examples/snippets/cb_matrix.gp{gnuplot}

<Plot name="cb_matrix" svg :width="560" :height="400" />

`matrix` reads the values as they lie in the file: columns along x, rows along y. `maxcolors 10` quantizes the
palette. See [Images and palettes](/guide/gnuplot-subset#images-and-palettes).

### Palettes

<<< @/examples/snippets/cb_palettes.gp{gnuplot}

<Plot name="cb_palettes" svg :width="760" :height="560" />

`set palette gray`, `rgbformulae R,G,B` (any of gnuplot's 37), `defined (v color, ...)`, `cubehelix [start S]
[cycles C] [saturation S]`, `viridis`, with `negative` and `maxcolors N`. See [Images and palettes](/guide/gnuplot-subset#images-and-palettes).

### A log color axis

<<< @/examples/snippets/cb_logcb.gp{gnuplot}

<Plot name="cb_logcb" svg :width="560" :height="400" />

`set logscale cb` maps the values on a log scale, for residuals spanning decades; `set cbtics`, `set format cb` and
`unset cbtics` set the labels of the color box as those of the x and y axes. See
[Images and palettes](/guide/gnuplot-subset#images-and-palettes).

### Color box placement

<<< @/examples/snippets/cb_colorbox.gp{gnuplot}

<Plot name="cb_colorbox" svg :width="760" :height="320" />

`set colorbox horizontal` lays the box below the plot; `user origin X,Y size W,H` puts it anywhere on the page
(fractions from the bottom left), `invert` turns a vertical box upside down, `noborder` drops its frame. See
[Images and palettes](/guide/gnuplot-subset#images-and-palettes).

### A palette from a file

<<< @/examples/snippets/cb_palette_file.gp{gnuplot}

<Plot name="cb_palette_file" svg :width="560" :height="400" />

`set palette file 'terrain.dat'` reads a gradient as gnuplot: `gray r g b` rows (here sea below 0.5, land above), or
`r g b` rows evenly spaced; `using`, `index` and `every` work as in `plot`. See
[Images and palettes](/guide/gnuplot-subset#images-and-palettes).

### Named palettes

<<< @/examples/snippets/cb_colormaps.gp{gnuplot}

<Plot name="cb_colormaps" svg :width="760" :height="560" />

A foresight extension: `set palette NAME`, one of Crameri's *Scientific colour maps*, matplotlib's `magma`,
`inferno`, `plasma`, `viridis`, `cividis`, or Moreland's `black_body`, in any case. Pick the type for the data: sequential for a magnitude, diverging about a
meaningful centre (a symmetric `cbrange`), multi-sequential for two regimes either side of a value, cyclic for an
angle (`cbrange [-180:180]`, the ends meet). See [Named palettes](/guide/gnuplot-subset#named-palettes) for every name.

### An RGB image

<<< @/examples/snippets/cb_rgbimage.gp{gnuplot}

<Plot name="cb_rgbimage" svg :width="560" :height="400" />

`rgbimage` (`x:y:r:g:b`) and `rgbalpha` (`x:y:r:g:b:a`) color each pixel directly, components 0 to 255 (`set rgbmax 1`
for fractions), without palette nor color box.

## Polar and radial charts

### A polar plot

<<< @/examples/snippets/cb_polar.gp{gnuplot}

<Plot name="cb_polar" svg :width="520" :height="400" />

A probe's directivity against a cardioid model, theta in degrees, in gnuplot's round idiom: square plot, polar border
and grid, theta labels, no x and y ticks. See [Polar plots](/guide/gnuplot-subset#polar-plots).

### A wind rose

<<< @/examples/snippets/cb_windrose.gp{gnuplot}

<Plot name="cb_windrose" svg :width="520" :height="420" />

`sectors` draws annular sectors from `azimuth:radius:angle:width`, angles in the `set angles` unit oriented by
`set theta`; on a polar panel they stack into a wind rose (two speed classes, one on top of the other).

### A radar and a rose

<<< @/examples/snippets/cb_radar.gp{gnuplot}

<Plot name="cb_radar" svg :width="480" :height="320" />

<<< @/examples/snippets/cb_rose.gp{gnuplot}

<Plot name="cb_rose" svg :width="480" :height="320" />

### A spider plot

<<< @/examples/snippets/cb_spider.gp{gnuplot}

<Plot name="cb_spider" svg :width="560" :height="400" />

`set spiderplot`: each item is a radial axis, each row a polygon in its color, named by `key(1)`; `set grid spiderplot`
draws the web at the ticks of the first axis. foresight's `with radar` is the transposed shorthand (an item per polygon).

### Parallel axes

<<< @/examples/snippets/cb_parallel.gp{gnuplot}

<Plot name="cb_parallel" svg :width="560" :height="320" />

`parallelaxes`: each item is an axis (a column), each row a line across them; `set paxis N range` and `set paxis N tics`
scale and tick each axis. See [Parallel axes and spider plots](/guide/gnuplot-subset#parallel-axes-and-spider-plots).

### A pie and a donut

<<< @/examples/snippets/cb_pie.gp{gnuplot}

<Plot name="cb_pie" svg :width="480" :height="320" />

<<< @/examples/snippets/cb_donut_vfd.gp{gnuplot}

<Plot name="cb_donut_vfd" svg :width="480" :height="320" />

`xtic(1)` names the slices; the key gives their percentages.

### A cluster of gauges

<<< @/examples/snippets/cb_gauges.gp{gnuplot}

<Plot name="cb_gauges" svg :width="600" :height="240" />

Each gauge shows the last value of its column over a fixed `range`, lit in cells; with `--watch` the needle-less
gauges follow the run. See [Gauges, radars and roses](/guide/gnuplot-subset#gauges-radars-and-roses).

## Dashboards of the 1980s

### An 1980s dashboard

<<< @/examples/snippets/cb_vfd.gp{gnuplot}

<Plot name="cb_vfd" svg :width="640" :height="440" />

`theme vfd` turns the page into a vacuum fluorescent display; `theme lcd` into a backlit LCD. `segments 10` cuts the
bars into cells over the y range, the unlit ones drawn faintly. See
[Themes and segmented fills](/guide/gnuplot-subset#themes-and-segmented-fills).

### A liquid-crystal dashboard

<<< @/examples/snippets/cb_lcd.gp{gnuplot}

<Plot name="cb_lcd" svg :width="640" :height="300" />

`theme lcd`: the pale green glass and dark segments of a backlit LCD, here with a segmented gauge and segmented bars.
See [Themes and segmented fills](/guide/gnuplot-subset#themes-and-segmented-fills).

### Light and dark pages

<<< @/examples/snippets/cb_identity.gp{gnuplot}

<Plot name="cb_identity" svg :width="560" :height="320" />

The same script, no theme in it, drawn in the two faces of foresight's identity by the command line:

```bash
foresight -t washi -o light.svg cb_identity.gp   # ink on warm paper, a crimson first series
foresight -t night -o dark.svg cb_identity.gp    # light text on a near-black ground, a rose first series
```

These are the colors of this site: its figures follow the light and dark switch at the top of the page. A script that
sets its own theme (`set terminal svg theme vfd`) keeps it. See
[Themes and segmented fills](/guide/gnuplot-subset#themes-and-segmented-fills).

### Seven-segment readouts

<<< @/examples/snippets/cb_readout.gp{gnuplot}

<Plot name="cb_readout" svg :width="560" :height="420" />

A foresight extension: the last finite value of each item in seven-segment digits, its glass fixed by the field width
of `format`. A panel of readouts alone fills itself with digits; over a curve they lie in a window, placed as the key.
See [Readouts](/guide/gnuplot-subset#readouts).

<<< @/examples/snippets/cb_readout_dumb.gp{gnuplot}

<<< @/examples/output/cb_readout_dumb.txt{text}

## Text terminals

### Text in the terminal

<<< @/examples/snippets/cb_dumb.gp{gnuplot}

<<< @/examples/output/cb_dumb.txt{text}

`set terminal dumb` writes to the standard output; `set output 'plot.txt'` to a file.

### Unicode text in the terminal

<<< @/examples/snippets/cb_block.gp{gnuplot}

<<< @/examples/output/cb_block.txt{text}

`block` draws with Unicode characters of 2 x 4 dots (`braille`), 2 x 3 (`sextants`), 2 x 2 (`quadrants`, the default)
or 1 x 2 (`half`). Add `ansi` (or `ansi256`, `ansirgb`) to draw each series in its color, in `dumb` as well.

## From Fortran

### From Fortran: gaps in the data

NaN values are gaps, as gnuplot's undefined points; `save` writes any of the formats, `-` text on the standard output.

<<< @/examples/snippets/cb_gaps-gaps.f90{fortran}

<Plot name="cb_gaps" svg :width="560" :height="320" />

<<< @/examples/output/cb_gaps.txt{text}

### From Fortran: run gnuplot commands

`script_object` is the interpreter of the command line: scripts and single commands from the program, with errors
returned, never stopped on.

<<< @/examples/snippets/cb_script-script.f90{fortran}

<Plot name="cb_script" svg :width="560" :height="320" />
