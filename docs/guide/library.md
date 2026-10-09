---
title: Fortran Library
---

# Fortran Library

`use foresight` gives two types: `figure_object`, a figure driven by methods that mirror gnuplot commands, and
`script_object`, the interpreter of gnuplot scripts. The PENF kinds `I4P`, `I8P`, `R4P`, `R8P` are re-exported: real
data are `real(R8P)`, integer arguments `integer(I4P)`.

## A figure

```fortran
type(figure_object) :: fig

call fig%set_title('Residuals')
call fig%set_logscale('y')
call fig%plot(it, res, title='continuity')
call fig%save('residuals.html')
```

A fresh `figure_object` needs no initialisation. `init` resets it to the gnuplot defaults, optionally resizing:
600 x 480 px, 12 px font.

### Methods

| Method | gnuplot equivalent |
|---|---|
| `init([width], [height], [font_size])` | `reset`, `set terminal ... size` |
| `plot(x, y, [title], [with], [lc], [lw], [dt], [ps], [xlow], [xhigh], [ylow], [yhigh], [axes], [pt], [format], [width], [base], [fs], [xlabels], [radius], [angles], [donut], [scale], [linear])` | one item of `plot` |
| `clear()` | the replacement done by a new `plot` |
| `save(file)` | `set output` + render |
| `set_title(title)`, `set_xlabel(label)`, `set_ylabel(label)`, `set_y2label(label)` | `set title`, `set xlabel`, `set ylabel`, `set y2label` |
| `set_xrange([min], [max])`, `set_yrange(...)`, `set_y2range(...)` | `set xrange [min:max]` |
| `set_logscale([axes])`, `unset_logscale([axes])` | `set logscale`, `unset logscale`; `axes` concatenates `x`, `y`, `y2` (all when absent) |
| `set_grid([on], [polar], [spider])` | `set grid`, `unset grid`; `polar=30._R8P`: `set grid polar 30` (spoke step in degrees, 0 for the rectangular grid); `spider=.true.`: `set grid spiderplot` |
| `set_key([on], [position], [box])` | `set key bottom left box`, `set key outside`, `set key below`, `unset key` |
| `set_xtics([step], [start], [end], [mirror])`, `set_ytics(...)`, `set_y2tics(...)` | `set xtics START,STEP,END [no]mirror`; automatic without `step`; `mirror` alone keeps the positions |
| `unset_xtics()`, `unset_ytics()`, `unset_y2tics()` | `unset xtics` |
| `set_format(format, [axes])` | `set format y "%.1e"`; an empty format restores the default; all axes when absent |
| `set_multiplot([rows], [cols], [title])`, `next_panel()`, `unset_multiplot()` | `set multiplot [layout]` |
| `set_origin(x, y)`, `set_size([width, height], [ratio])` | `set origin`, `set size`: page fractions, not with a layout; `ratio=1._R8P`: `set size square` (0: `noratio`) |
| `set_polar([on])`, `set_angles(unit)`, `set_theta([origin], [clockwise])` | `set polar`, `set angles degrees`, `set theta top clockwise` ([Polar plots](gnuplot-subset#polar-plots)): `plot(theta, r)` |
| `set_rrange([min], [max])`, `set_trange([min], [max])` | `set rrange [1:*]`, `set trange` |
| `set_rtics([step], [start], [end], [on])`, `set_ttics([step], [start], [format], [on])`, `set_raxis([on])` | `set rtics`, `set ttics 0,30 format "%g"`, `set raxis`; `on=.false.`: `unset ...` |
| `set_border([mask], [polar])` | `set border 3`, `set border polar`, `unset border` (`mask=0`) |
| `set_style_fill(words)` | `set style fill solid 0.5 noborder`, `solid segments 10` |
| `rgbimage(red, green, blue, [x], [y], [title], [alpha])` | `plot ... with rgbimage` / `rgbalpha`: colors 0 to 255 per pixel (column, row) |
| `image(z, [x], [y], [title])` | `plot ... with image`: the values `z(column, row)` at the pixel centres `x`, `y` (evenly spaced; 0, 1, ... if absent) |
| `set_palette(words)` | `set palette viridis maxcolors 8`, `set palette defined (0 "blue", 1 "white", 2 "red")` |
| `set_cbrange([min], [max])`, `set_cblabel(label)`, `set_colorbox([on])` | `set cbrange [0:1]`, `set cblabel`, `set colorbox` / `unset colorbox` |
| `set_theme([name], [glow])` | `set terminal svg theme vfd noglow` (foresight extension): `classic`, `vfd`, `lcd` |
| `set_paxis(n, [min], [max], [step], [start], [end], [tics], [label])` | `set paxis 2 range [0:100]`, `set paxis 2 tics 25`, `set paxis 1 label "speed"` |
| `set_spiderplot([on])`, `set_style_spiderplot(words)` | `set spiderplot`, `set style spiderplot fs transparent solid 0.2 border lw 2` |
| `set_style_boxplot(words)` | `set style boxplot nooutliers sorted fraction 0.95` |
| `set_style_histogram(style, [gap])` | `set style histogram clustered gap 1`, `set style histogram rowstacked` |
| `set_boxwidth([width], [relative])` | `set boxwidth 0.5`, `set boxwidth 0.8 relative`; no `width`: boxes touching |
| `set_readout([on], [position], [opaque], [size])` | `set readout top right horizontal noopaque size 30`, `unset readout` (foresight extension, see [Readouts](gnuplot-subset#readouts)) |
| `set_refresh(seconds)` | reload period of the HTML page |
| `set_text([charset], [colors])` | text output (`.txt`, `-`): `charset` `dumb` (default) or `half`, `quadrants`, `sextants`, `braille`, the `set terminal block` sets; `colors` `mono` (default), `ansi`, `ansi256`, `ansirgb` |

### `plot` options

| Argument | Meaning | Default |
|---|---|---|
| `title` | key entry; empty for none | none |
| `with` | `lines`, `points`, `linespoints`, `impulses`, `steps`, `fsteps`, `histeps`, `dots`, `yerrorbars`, `xerrorbars`, `xyerrorbars`, `yerrorlines`, `xerrorlines`, `xyerrorlines`, `boxerrorbars`, `boxxyerror`, `candlesticks`, `financebars`, `boxplot` ([Box styles](gnuplot-subset#box-finance-and-boxplot-styles)), `vectors`, `arrows`, `ellipses`, `polygons`, `labels`, `sectors` ([Shapes](gnuplot-subset#vectors-ellipses-polygons-labels-and-sectors)), `parallelaxes`, `spiderplot` ([Parallel axes](gnuplot-subset#parallel-axes-and-spider-plots); abbreviated as gnuplot: `l`, `p`, `lp`, `i`, `st`, `fs`, `his`, `d`, `yerr`, ...; [Lines, steps](gnuplot-subset#lines-steps-and-impulses)); `circles`, `pie` ([Circles and pies](gnuplot-subset#circles-pies-and-donuts)); `gauge`, `radar`, `rose` ([Gauges](gnuplot-subset#gauges-radars-and-roses)); `boxes`, `filledcurves` ([Boxes](gnuplot-subset#boxes-and-filled-curves)); `histograms` ([Histograms](gnuplot-subset#histograms)), the rows at `x`; `readout`, the last finite `y` in seven-segment digits ([Readouts](gnuplot-subset#readouts)) | `lines` |
| `radius`, `angles` | circles only: radii [x units] (NaN: the default), and `angles(2, n)` start and end of wedges [deg] | 2% of the plot width; whole circles |
| `donut` | pie only (`with='pie'`): the hole, a fraction of the radius | 0, a pie |
| `scale` | gauge only (`with='gauge'`): the values at the ends of the sweep, `[0._R8P, 8000._R8P]`; cells with `fs='segments N'` | required |
| `linear` | rose only (`with='rose'`): the radius, not the area, by value | `.false.` |
| `close` | candlesticks and financebars: the closing values, `y` the opening ones, `ylow`/`yhigh` the low and high | required |
| `whiskerbars` | candlesticks: whisker crossbars, a fraction of the box width | none |
| `factors` | boxplot: the level of each value of `y` (one box per level, named on the x axis) | one box |
| `dx`, `dy` | vectors: the arrow extents | required |
| `length`, `angle` | arrows: lengths and angles [deg]; `angle` also rotates ellipses [deg] and spans sectors [angle unit] | required (arrows) |
| `head` | vectors and arrows: gnuplot words, `'heads filled'`, `'nohead'` | `'head'` |
| `major`, `minor` | ellipses: diameters in x and y units (`major` alone for both, negative for the default size) | 5% x 3% of the plot |
| `labels`, `label` | labels: the texts, and gnuplot option words `'left rotate by 30 offset 1,0 point tc "red"'` | required, none |
| `width`, `origins` | sectors: annular widths, and centres `(2, n)` | required, `[0, 0]` |
| `at` | parallelaxes: the position of the axis | its number |
| `labels` | also the row names of a spider plot (its key), on any of its items | none |
| `curve` | filledcurves: gnuplot words `'x1'`, `'x2'`, `'xy=2,0'`, `'above'`, `'below'` (with `base` or a band `ylow`) | closed, or to `base`/`ylow` |
| `xlabels` | text labels of the points (gnuplot `xtic(N)`), blank for none: they replace the x ticks | — |
| `width` | boxes only: the width of each box (NaN: the default) | `set_boxwidth`, else touching |
| `base` | filledcurves only: fill down to the line y = `base` (with `ylow`: the band between `ylow` and `y`) | the closed polygon |
| `fs` | boxes and filledcurves: gnuplot fill style words, `'solid 0.5 noborder'` | `set_style_fill` |
| `format` | readouts only: printf format with a field width, `'%9.2e'`; a readout takes `lc`, no other style option | `'%10.3e'` |
| `lc` | color, any SVG color (`'#e51e10'`, `'red'`) | gnuplot palette, by series |
| `lw` | line width [px] | 1 |
| `dt` | dash type 1..5 | 1 (solid) |
| `ps` | point size factor | 1 |
| `pt` | gnuplot point type: 0 a dot, 1 plus, 2 cross, 3 star, 4-5 square, 6-7 circle, 8-9 triangle, 10-11 inverted triangle, 12-13 diamond, 14-15 pentagon (odd ones from 5 filled), cycling every 15 | round dot |
| `ylow`, `yhigh` | vertical error bar ends, for `yerrorbars`, `xyerrorbars` | — |
| `xlow`, `xhigh` | horizontal error bar ends, for `xerrorbars`, `xyerrorbars` | — |
| `axes` | `x1y1`, or `x1y2` for the second y axis (scaled on its own, ticks off until `set_y2tics`) | `x1y1` |

`x` and `y` may contain NaN: those points, and non-positive values on log axes, are gaps in the line.

```fortran
call fig%plot(x, y, title='measured', with='yerrorbars', ylow=y - dy, yhigh=y + dy)
call fig%plot(x, fit, title='model', lc='black', dt=2_I4P)
```

### Ranges

As gnuplot `set xrange [min:max]`: an absent end is autoscaled, and an autoscaled end extends outward to the next
tick. `min > max` reverses the axis.

```fortran
call fig%set_xrange(min=10.0_R8P, max=0.0_R8P)   ! reversed
call fig%set_yrange(max=1.0_R8P)                 ! top fixed, bottom autoscaled
call fig%set_xrange()                            ! back to full autoscale
```

### Multiplot

`set_multiplot(rows, cols, title)` lays out a grid filled row by row, starting from the first panel. Settings and
plots apply to the current panel; `next_panel` moves on, carrying the settings over (not the series), as gnuplot does.
Panels never plotted stay blank.

```fortran
call fig%set_multiplot(1_I4P, 2_I4P, title='Run monitor')
call fig%set_title('residual')
call fig%set_logscale('y')
call fig%plot(it, res)
call fig%next_panel
call fig%set_title('drag coefficient')
call fig%unset_logscale('y')
call fig%plot(it, cd)
```

Without `rows` and `cols`, `set_multiplot` starts a manual multiplot: each `next_panel` adds a panel, placed in the
box of `set_origin` and `set_size` (page fractions from the bottom left, below the title), for insets:

```fortran
call fig%set_multiplot(title='Run monitor')
call fig%plot(it, cd, title='cd')
call fig%next_panel
call fig%set_origin(0.35_R8P, 0.35_R8P)
call fig%set_size(0.55_R8P, 0.5_R8P)
call fig%set_logscale('y')
call fig%plot(it, res)
```

### Output

`save` picks the format from the file name: `.svg` static vector, `.html`/`.htm` interactive page, `.txt` text, `-`
text on the standard output. See [Output Formats](output-formats).

## Scripts from Fortran

`script_object` runs gnuplot-subset scripts, the same interpreter the command line uses. Errors are returned, never
stopped on:

```fortran
type(script_object)           :: gp
character(len=:), allocatable :: iomsg
integer(I4P)                  :: iostat

call gp%init('monitor.html')                    ! default output
call gp%run_file('monitor.gp', iostat, iomsg)
if (iostat /= 0) print '(A)', iomsg              ! e.g. monitor.gp:7: unsupported command "splot"
call gp%execute('replot', iostat, iomsg)        ! one statement
```

| Procedure | Purpose |
|---|---|
| `init(output)` | reset; plots go to `output` until `set output` |
| `run_file(file, iostat, iomsg)` | run a script file |
| `run_text(text, iostat, iomsg, [source])` | run script text, `source` names it in messages |
| `execute(statement, iostat, iomsg)` | run one statement |

After a run, `gp%output` is the current output file, and `gp%data_files(k)%text`, for `k` up to
`size(gp%data_files)`, are the data files read.

## Errors

The figure API stops with `error stop` on programming errors: `x` and `y` of different sizes, an unsupported
style, error bar styles without their bounds, a log axis over a non-positive fixed range, a full multiplot layout.
The interpreter instead reports every error through `iostat`/`iomsg`.
