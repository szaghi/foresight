---
title: Feature map
---

# Feature map

Everything foresight does, and where it is documented. The [tutorial](/manual/) shows it at work; the
[cookbook](/manual/cookbook) one task at a time.

| Area | Features | Where |
|---|---|---|
| Plot styles | `lines`, `points`, `linespoints`, `impulses`, `steps`, `fsteps`, `histeps`, `dots`, `yerrorbars`, `xerrorbars`, `xyerrorbars`, `yerrorlines`, `xerrorlines`, `xyerrorlines`, `boxerrorbars`, `boxxyerror`, `candlesticks`, `financebars`, `boxplot` (quartiles, factors, outliers), `vectors`, `arrows`, `ellipses`, `polygons`, `labels`, `sectors`, `parallelaxes`, `spiderplot` (`set paxis`), `boxes`, `filledcurves` (bars from 0, bands, `x1`, `x2`, `xy=`, `above`/`below`; fill styles and patterns, `set boxwidth`), `histograms` clustered and row-stacked with `xtic(N)` category labels; gnuplot palette, dash types, widths, 15 point types and sizes; `set style line`, `ls` | [gnuplot Subset](gnuplot-subset#styles), [point types](gnuplot-subset#point-types) |
| Axes | linear and log scales, fixed or autoscaled ends extended to the ticks, reversed ranges; tick steps, `mirror`, printf label formats; a second y axis | [Ticks](gnuplot-subset#ticks-and-label-formats), [Second y axis](gnuplot-subset#second-y-axis) |
| Key | inside (any corner, centred), `outside`, `below`/`above` in rows, box; titles as written, from column headers, or none | [Key](gnuplot-subset#key) |
| Data files | whitespace, CSV or any separator; comments, blocks, datasets; `using`, `index`, `every`; column 0; missing values; cells read as gnuplot (C `strtod`) | [Data Files](data-files) |
| Expressions | `using ($2*1e3)`, `column("name")`, `?:`, `1/0` gaps, gnuplot's integer arithmetic and functions | [Expressions](gnuplot-subset#expressions-in-using) |
| Column headers | `using 1:"residual"`, `title columnhead`, `set key autotitle columnhead` | [Column headers](gnuplot-subset#column-headers) |
| Functions | `plot sin(x)/x`, sampled over the data x range, `set samples`, `set style function` | [Functions](gnuplot-subset#functions) |
| Smoothing | `smooth unique`, `frequency`, `fnormal`, `cumulative`, `cnormal`: averages of repeated x, histograms, distributions | [Smoothing](gnuplot-subset#smoothing) |
| Layout | multiplot grids with a title, panels in `origin`/`size` boxes (insets) | [Multiplot](gnuplot-subset#multiplot) |
| Output | interactive HTML (one self-contained page), SVG, text with characters (`dumb`) or Unicode blocks and Braille (`block`), in ANSI colors; atomic rewrites | [Output Formats](output-formats) |
| Viewer | wheel and box zoom, pan, `u` `a` `g` `h`, live coordinates (y2 too), ticks and markers regenerated on zoom; series hidden from the key; panels sharing x zoomed together; following the end of a live run; the view kept in the URL | [Interactive Viewer](viewer) |
| Circles and pies | `with circles` (bubbles, wedges); foresight's `with pie [donut F]`, slices named by `xtic(N)` with their percentages | [Circles, pies](gnuplot-subset#circles-pies-and-donuts) |
| Panel charts | foresight extensions: `with gauge` (sweep gauges of the last value, segmented), `with radar`, `with rose` (area by value) | [Gauges, radars, roses](gnuplot-subset#gauges-radars-and-roses) |
| Polar plots | `set polar`, `set angles`, `set theta`, `rrange`, `trange`, `set grid polar`, `set border polar`, `rtics`, `ttics`, `set size square`; functions of `t` | [Polar plots](gnuplot-subset#polar-plots) |
| Images | `with image` heatmaps and `rgbimage`/`rgbalpha` colors of `x:y:z` grids or `matrix` files; palettes (`rgbformulae`, `defined`, `gray`, `viridis`, `negative`, `maxcolors`), `cbrange`, `cblabel`, color box; embedded PNG, sharp at any zoom | [Images](gnuplot-subset#images-and-palettes) |
| Themes | foresight extension: `set terminal ... theme vfd\|lcd\|classic [glow\|noglow]`, 1980s dashboard colors and glow; segmented bars (`fs solid segments N`) with unlit cells | [Themes](gnuplot-subset#themes-and-segmented-fills) |
| Readouts | foresight extension: `with readout`, the last value of an item in seven-segment digits on a glass fixed by `format`; blocks of readouts over the curves or filling a panel; `set readout` | [Readouts](gnuplot-subset#readouts) |
| Monitoring | `--watch`: re-render on any change of the script or its data; reloading pages that keep the zoom or follow the newest data; the text terminal redrawn in place | [Live Monitoring](monitoring) |
| Library | `figure_object` (methods mirroring gnuplot commands), `script_object` (the interpreter) | [Fortran Library](library), [API](/api/) |
| Command line | `foresight [-e CMDS] [-o OUT] [-w [S]] [SCRIPT]` | [Command Line](cli) |
| Engineering | pure Fortran 2018; exact tick labels from integers; byte-exact golden tests; never an IEEE exception on bad data | [Architecture](architecture) |

```mermaid
flowchart LR
  S[gnuplot script] --> I[script_object]
  P[your program] --> F[figure_object]
  I --> F
  F --> H[HTML page] & V[SVG] & T[text]
```
