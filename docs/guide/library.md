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
| `plot(x, y, [title], [with], [lc], [lw], [dt], [ps], [xlow], [xhigh], [ylow], [yhigh], [axes], [pt], [format], [width], [base], [fs], [xlabels], [radius], [angles], [donut], [scale], [linear], [close], [whiskerbars], [factors], [dx], [dy], [length], [angle], [major], [minor], [labels], [label], [head], [origins], [curve], [at], [colors], [palette_z], [palette_cb], [palette_frac], [pi], [labels_axis])` | one item of `plot`; the arguments of each style are in the `plot` documentation of the [API](/api/); `colors(:)`: `lc variable` (a color per point), `palette_z(:)`: `lc palette z` (a value per point through the palette), `palette_cb`, `palette_frac`: `lc palette cb V`, `frac F`; `pi`: `pointinterval N`; `labels_axis`: the axis of the `xlabels`, `'x'` (`xtic`, the default), `'x2'`, `'y'` (`ytic`, at the ordinates), `'y2'` |
| `splot(x, y, z, [title], [with], [lc], [lw], [dt], [ps], [pt], [palette])` | one item of `splot`, a [3D plot](gnuplot-subset#3d-plots): `z(:)` scattered points (one scan, `points` by default), `z(:,:)` a grid `z(i, j)` at `(x(i), y(j))`, a scan per row (`lines` by default, `with='image'` its pixels, `with='pm3d'` colored quadrangles); `palette=.true.`: `lc palette` (colored by height) |
| `set_contour([on], [place], [kind], [levels], [discrete], [incremental], [points], [order], [firstlinetype], [sorted], [format], [onecolor])` | `set contour base`, `set cntrparam levels auto 6` (`levels=6`), `discrete=[0.5_R8P, 1._R8P]`, `incremental=[0._R8P, 0.25_R8P]`, `kind='bspline'`, `set cntrlabel format '%.2f' onecolor`: the [contour lines](gnuplot-subset#contours) of the 3D surfaces |
| `set_dgrid3d([on], [rows], [cols], [mode], [norm], [scale], [kdensity])` | `set dgrid3d 30,30 gauss 0.5` (`rows=30, cols=30, mode='gauss', scale=[0.5_R8P, 0.5_R8P]`), `kdensity=.true.`, `unset dgrid3d` (`on=.false.`): the scattered points of `splot(x, y, z)` [gridded](gnuplot-subset#gridded-and-masked-surfaces) |
| `set_pm3d([implicit], [interpolate], [corners2color], [clip4in])` | `set pm3d` (`implicit=.true.`), `unset pm3d` (`.false.`), `set pm3d interpolate 4,4` (`interpolate=[4, 4]`), `corners2color='c1'`: the [pm3d surfaces](gnuplot-subset#3d-plots), `splot(x, y, z2d, with='pm3d')` |
| `set_view([map], [rot_x], [rot_z], [scale], [zscale], [map_scale], [equal])` | `set view map` (`map=.true.`), `set view map scale 1.2`, `set view 60, 30, 1, 1`, `set view equal xy` (`equal=1`, `2` for `xyz`) |
| `set_zrange([min], [max])`, `set_zlabel(label)`, `set_ztics([step], [start], [end], [positions], [labels], [minor], [add])` | `set zrange`, `set zlabel`, `set ztics` of the 3D plots |
| `clear()` | the replacement done by a new `plot` |
| `save(file)` | `set output` + render |
| `set_title(title)`, `set_xlabel(label)`, `set_ylabel(label)`, `set_y2label(label)`, `set_x2label(label)` | `set title`, `set xlabel`, `set ylabel`, `set y2label`, `set x2label` |
| `set_enhanced([on])` | `set termoption enhanced` (`on=.false.`: `noenhanced`): the texts read as [enhanced text](gnuplot-subset#enhanced-text), `x^2`, `T_{n-1}`, `{/Symbol a}`; off by default in the library, on in the scripts |
| `set_xrange([min], [max])`, `set_yrange(...)`, `set_y2range(...)`, `set_x2range(...)` | `set xrange [min:max]` |
| `set_logscale([axes])`, `unset_logscale([axes])` | `set logscale`, `unset logscale`; `axes` concatenates `x`, `y`, `y2`, `x2`, `cb` (all when absent) |
| `set_grid([on], [polar], [spider])` | `set grid`, `unset grid`; `polar=30._R8P`: `set grid polar 30` (spoke step in degrees, 0 for the rectangular grid); `spider=.true.`: `set grid spiderplot` |
| `set_key([on], [position], [box], [at], [system])` | `set key bottom left box`, `set key outside`, `set key below`, `set key lmargin`, `unset key`; `at=[60._R8P, 1._R8P], position='left top'`: `set key at 60,1 left top`, `system='graph'` (or `'first screen'`, x then y): `set key at graph ...` |
| `set_xtics([step], [start], [end], [mirror], [positions], [labels], [minor], [add], [rotate], [justify], [out])`, `set_ytics(...)`, `set_y2tics(...)`, `set_x2tics(...)` | `set xtics START,STEP,END [no]mirror`; automatic without `step`; `mirror` alone keeps the positions; an explicit list (`positions`, `labels`, `minor`, `add`); `rotate=30._R8P, justify='right'`: `set xtics rotate by 30 right` (x and x2); `out=.true.`: `set xtics out` |
| `set_cbtics([step], [start], [end], [mirror], [positions], [labels], [minor], [add])`, `unset_cbtics()` | `set cbtics START,STEP,END`, `unset cbtics`: the ticks of the color box; an explicit list as `set_xtics` |
| `set_mxtics([intervals], [unit])`, `set_mytics(...)`, `set_my2tics(...)`, `set_mx2tics(...)`, `set_mcbtics(...)` | `set mxtics N`: `intervals` between major ticks; gnuplot's count when absent; 0 or 1 for none (`unset mxtics`); `set_mxtics(10, 'minutes')`: `set mxtics time 10 minutes` on a time axis (`seconds` to `years`) |
| `set_errorbars([size], [lc], [lw])` | `set errorbars 2 lc "red" lw 2`: the cap length of the error bars and boxplot whiskers (1 the default, 0 none), the error bar line |
| `set_time_axes([axes], [on], [timefmt])`, `set_timefmt(timefmt)` | `set xdata time` ([Time data](gnuplot-subset#time-data)): the values of the `axes` (`x`, `y`, `y2`, `x2`; all when absent) are seconds since 1970 UTC, ticked in whole time units and labelled by `set_format('%H:%M', 'x')` or a format invented from the range; `timefmt` (`set timefmt`) orders day and month in the invented labels; `on=.false.` back to numbers |
| `unset_xtics()`, `unset_ytics()`, `unset_y2tics()`, `unset_x2tics()` | `unset xtics` |
| `set_format(format, [axes])` | `set format y "%.1e"`, `set format cb "%.2f"`, on a time axis `set format x "%d %b"`; an empty format restores the default; all axes when absent |
| `set_multiplot([rows], [cols], [title])`, `next_panel()`, `unset_multiplot()` | `set multiplot [layout]` |
| `set_origin(x, y)`, `set_size([width, height], [ratio])` | `set origin`, `set size`: page fractions, not with a layout; `ratio=1._R8P`: `set size square` (0: `noratio`) |
| `set_polar([on])`, `set_angles(unit)`, `set_theta([origin], [clockwise])` | `set polar`, `set angles degrees`, `set theta top clockwise` ([Polar plots](gnuplot-subset#polar-plots)): `plot(theta, r)` |
| `set_rrange([min], [max])`, `set_trange([min], [max])` | `set rrange [1:*]`, `set trange` |
| `set_rtics([step], [start], [end], [on])`, `set_ttics([step], [start], [format], [on])`, `set_raxis([on])` | `set rtics`, `set ttics 0,30 format "%g"`, `set raxis`; `on=.false.`: `unset ...` |
| `set_border([mask], [polar])` | `set border 3`, `set border polar`, `unset border` (`mask=0`) |
| `set_style_fill(words)` | `set style fill solid 0.5 noborder`, `solid segments 10` |
| `rgbimage(red, green, blue, [x], [y], [title], [alpha])` | `plot ... with rgbimage` / `rgbalpha`: colors 0 to 255 per pixel (column, row) |
| `image(z, [x], [y], [title])` | `plot ... with image`: the values `z(column, row)` at the pixel centres `x`, `y` (evenly spaced; 0, 1, ... if absent) |
| `set_colorsequence(name, [colors])` | `set colorsequence podo`, `set colorsequence batlowS 6` (`colors=6`) |
| `set_palette_gradient(positions, colors)` | `set palette defined (...)` / `set palette file 'f'` from arrays: `colors(:, k)` (red, green, blue, 0 to 1) at increasing `positions(k)`; `set_palette` words can follow (`'negative'`) |
| `set_palette(words)` | `set palette viridis maxcolors 8`, `set palette defined (0 "blue", 1 "white", 2 "red")`, `set palette cubehelix cycles 1`, `set palette vik negative` (named palettes, see [Images and palettes](gnuplot-subset#images-and-palettes)) |
| `set_cbrange([min], [max])`, `set_cblabel(label)`, `set_colorbox([on], [horizontal], [user], [origin], [size], [border], [invert])` | `set cbrange [0:1]`, `set cblabel`, `set colorbox horizontal`, `set colorbox user origin 0.8,0.2 size 0.05,0.6` / `unset colorbox` (`on=.false.`) |
| `set_theme([name], [glow])` | `set terminal svg theme vfd noglow` (foresight extension): `classic`, `vfd`, `lcd`, `washi`, `night`; the default of a new figure is `FORESIGHT_THEME`, else `classic` |
| `set_paxis(n, [min], [max], [step], [start], [end], [tics], [label])` | `set paxis 2 range [0:100]`, `set paxis 2 tics 25`, `set paxis 1 label "speed"` |
| `set_spiderplot([on])`, `set_style_spiderplot(words)` | `set spiderplot`, `set style spiderplot fs transparent solid 0.2 border lw 2` |
| `set_style_boxplot(words)` | `set style boxplot nooutliers sorted fraction 0.95` |
| `set_style_histogram(style, [gap], [lw])` | `set style histogram clustered gap 1`, `rowstacked`, `columnstacked` (one stack per series, `labels` its row names), `errorbars gap 1 lw 2` (`plot(..., ylow, yhigh)` the error bar ends) |
| `new_histogram([title], [at], [lt])` | `plot newhistogram "title" at X lt N, ...`: the histograms plotted next form a new group of the plot |
| `set_label(text, x, y, [tag], [system], [justify], [rotate], [color], [front], [point], [pt], [ps], [offset])`, `unset_label([tag])` | `set label 1 "peak" at 3,1 right rotate by 30 tc "red" front point pt 7 offset 1,0`; `system='graph'` or `'graph first'` (x then y): the coordinate systems (`first`, `second`, `graph`, `screen`, `character`), `first` by default ([Labels, arrows and objects](gnuplot-subset#labels-arrows-and-objects)) |
| `set_arrow(x1, y1, x2, y2, [tag], [system], [to_system], [relative], [head], [length], [angle], [filled], [front], [lc], [lw], [dt])`, `unset_arrow([tag])` | `set arrow from 1,2 to 3,4 heads size 0.2,20 filled lw 2`; `relative`: `rto`; `head` `head`, `nohead`, `backhead`, `heads`; `filled` `nofilled` (default), `filled`, `empty`, `noborder` |
| `set_object(kind, x, y, [tag], [system], [width], [height], [radius], [angle], [arc], [fc], [fs], [lw], [dt], [layer], [clip])`, `unset_object([tag])` | `set object rect from 1,2 to 3,4`, `rect center 2,3 size 1,1` (`width`, `height`), `circle at 2,0 size 0.5 arc [0:90]`, `ellipse ... angle 30`, `polygon from ... to ...`; `fc`, `fs` the fill, `dt` a dashed border, `layer` `behind`, `back`, `front` |
| `add_label(label)`, `add_arrow(arrow)`, `add_object(object)` | the same from the `label_object`, `arrow_object`, `shape_object` of `foresight_annotations` (each coordinate in its own system), as the interpreter builds them |
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
| `labels` | also the row names of a spider plot (its key), on any of its items, and of a column stack (`columnstacked` histograms) | none |
| `curve` | filledcurves: gnuplot words `'x1'`, `'x2'`, `'xy=2,0'`, `'above'`, `'below'` (with `base` or a band `ylow`) | closed, or to `base`/`ylow` |
| `xlabels` | text labels of the points (gnuplot `xtic(N)`), blank for none: they replace the x ticks | — |
| `width` | boxes only: the width of each box (NaN: the default) | `set_boxwidth`, else touching |
| `base` | filledcurves only: fill down to the line y = `base` (with `ylow`: the band between `ylow` and `y`) | the closed polygon |
| `fs` | the filled styles (boxes, filledcurves, histograms, circles, pie, gauge, radar, rose, boxerrorbars, boxxyerror, candlesticks, boxplot, ellipses, polygons, sectors): gnuplot fill style words, `'solid 0.5 noborder'` | `set_style_fill` |
| `format` | readouts only: printf format with a field width, `'%9.2e'`; a readout takes `lc`, no other style option | `'%10.3e'` |
| `lc` | color, any SVG color (`'#e51e10'`, `'red'`; scripts read gnuplot's [color names](gnuplot-subset#color-names) instead) | the linetype colors, by series |
| `lw` | line width [px] | 1 |
| `dt` | dash type 1..5 | 1 (solid) |
| `ps` | point size factor | 1 |
| `pt` | gnuplot point type: 0 a dot, 1 plus, 2 cross, 3 star, 4-5 square, 6-7 circle, 8-9 triangle, 10-11 inverted triangle, 12-13 diamond, 14-15 pentagon (odd ones from 5 filled), cycling every 15 | round dot |
| `ylow`, `yhigh` | vertical error bar ends, for `yerrorbars`, `xyerrorbars`, and `histograms` with `set_style_histogram('errorbars')` | — |
| `xlow`, `xhigh` | horizontal error bar ends, for `xerrorbars`, `xyerrorbars` | — |
| `axes` | `x1y1`; `x1y2` for the second y axis, `x2y1` for the second x axis, `x2y2` both (each scaled on its own, ticks off until `set_y2tics`/`set_x2tics`) | `x1y1` |

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
if (iostat /= 0) print '(A)', iomsg              ! e.g. monitor.gp:7: unsupported command "bind"
call gp%execute('replot', iostat, iomsg)        ! one statement
```

| Procedure | Purpose |
|---|---|
| `init(output, [theme])` | reset; plots go to `output` until `set output`; `theme` the default output theme |
| `run_file(file, iostat, iomsg, [args])` | run a script file; `args(:)` (at most 9) are `ARG1` ... `ARG9` and the array `ARGV`, `ARGC` their number, `ARG0` the file, as `gnuplot -c` |
| `run_text(text, iostat, iomsg, [source])` | run script text, `source` names it in messages |
| `execute(statement, iostat, iomsg)` | run one statement |

After a run, `gp%output` is the current output file, `gp%data_files(k)%text`, for `k` up to
`size(gp%data_files)`, are the data files read (and the scripts loaded), `gp%last_plot` the items of the last
`plot`, and `gp%figure` the `figure_object` the script built: a program can go on with the API on it, or save it
elsewhere. `gp%symbols%value_of(name, v, found)` and `gp%symbols%string_of(name, text, found)` read the script
variables (`STATS_mean`, `FIT_WSSR`, ...).

## Times

`use foresight` exports gnuplot's time conversions, seconds since 1970-01-01 00:00 UTC
([Time data](gnuplot-subset#time-data)):

```fortran
use foresight, only : civil_time, strftime, strptime
real(R8P) :: t
logical   :: ok

t = civil_time(2024_I8P, 3_I8P, 1_I8P, 10_I8P, 30_I8P, 0.0_R8P)    ! 2024-03-01 10:30:00
print '(A)', strftime('%a %d %b %Y %H:%M', t)                      ! Fri 01 Mar 2024 10:30
call strptime('%Y-%m-%d %H:%M', '2024-03-02 08:00', t, ok)         ! ok false if the text does not match
call fig%set_time_axes('x')
call fig%set_format('%H:%M', 'x')
```

## Fitting a model

`fit` is gnuplot's `fit` for a Fortran function `model(x, p)`: the same Marquardt-Levenberg steps, so the same
parameters, errors and iterations as gnuplot to its printed digits. It is silent unless `report` is given:

```fortran
use foresight, only : fit, fit_result
real(R8P)        :: h(5) = [0.1_R8P, 0.05_R8P, 0.025_R8P, 0.0125_R8P, 0.00625_R8P]
real(R8P)        :: e(5) = [2.10e-3_R8P, 5.30e-4_R8P, 1.29e-4_R8P, 3.33e-5_R8P, 8.20e-6_R8P]
real(R8P)        :: q(2) = [1.0_R8P, 1.0_R8P]    ! initial c, p; fitted on return
type(fit_result) :: r

call fit(power_law, h, e, q, names=['c', 'p'], result=r)                  ! silent
call fit(power_law, h, e, q, names=['c', 'p'], report='-')                ! gnuplot's report on the standard error
call fit(power_law, h, e, q, names=['c', 'p'], report='fit.log')          ! appended to a file
if (len(r%message) > 0) print '(A)', r%message   ! e.g. Singular matrix in Invert_RtR; q unchanged
contains
   function power_law(x, p) result(f)
   real(R8P), intent(in) :: x, p(:)
   real(R8P)             :: f
   f = p(1) * x**p(2)
   endfunction power_law
```

| Argument | Purpose |
|---|---|
| `model` | `function model(x, p)`, real `x`, real `p(:)`: the model at `x` (interface `model_function`) |
| `x`, `y` | the data |
| `params` | initial values in, fitted values out (unchanged on failure) |
| `names` | parameter names in the report (`p1`, `p2`, ... if absent) |
| `err` | errors of `y`: weights `1/err**2` (unit weights if absent) |
| `settings` | `fit_settings`: `limit` (1e-5), `limit_abs`, `maxiter` (0, none), `start_lambda`, `lambda_factor` (10), `prescale`, `errorscaling` (gnuplot's `set fit` options) |
| `result` | `fit_result`: `params`, `errors` (gnuplot's `a_err`), `correlation`, `wssr`, `stdfit`, `p`, `ndf`, `niter`, `converged`, `message` (empty on success), `progress`, `stop_text` (why it stopped), `last_wssr`, `has_errors`, `weighted` |
| `report` | `'-'` the standard error (progress lines and results, as gnuplot's terminal), a file name (appended, gnuplot's `fit.log`) |

`fit_report(result, names, destination, [source], [function_text], [progress])` writes gnuplot's report of a
`fit_result` (`destination` `'-'` the standard error, else a file, appended). Scripts fit user functions with
`fit f(x) 'file' using 1:2 via a, b` ([gnuplot subset](gnuplot-subset.md#fit)).

## Statistics

`stats` is gnuplot's `stats` for Fortran arrays, the same values as gnuplot's `STATS_*` variables:

```fortran
use foresight, only : stats, stats_report, stats_result
type(stats_result) :: r

r = stats(cd)                                  ! one column: r%y%mean, r%y%stddev, r%y%median, ...
r = stats(h, error)                            ! two columns: r%x, r%y, r%slope, r%intercept, r%correlation, ...
print '(A,F8.5,A,F8.5)', 'cd = ', r%y%mean, ' +- ', r%y%stddev
call stats_report(r, unit=error_unit, formatted=.true.)   ! gnuplot's report
```

| Component | Value |
|---|---|
| `records` | number of values |
| `invalid`, `blank`, `blocks`, `headers`, `outofrange`, `columns` | the counts gnuplot reports of a file (a script's `stats`) |
| `x`, `y` (`stats_column`) | `mean`, `stddev`, `ssd` (sample), `skewness`, `kurtosis`, `adev`, `mean_err`, `stddev_err`, `skewness_err`, `kurtosis_err`, `sum`, `sumsq`, `min`, `max`, `median`, `lo_quartile`, `up_quartile`, `index_min`, `index_max` (0-based); `y` is the only column of `stats(y)` |
| `two` | two columns given |
| `slope`, `intercept`, `slope_err`, `intercept_err`, `correlation`, `sumxy`, `pos_min_y`, `pos_max_y` | the least squares line of two columns, gnuplot's |

`stats_report(r, unit, formatted)` writes gnuplot's report: its screen layout (`formatted`), or the name-tab-value
lines gnuplot writes to a `set print` file. Scripts call `stats 'file' using N[:M]` ([gnuplot subset](gnuplot-subset.md#stats)).

## Errors

The figure API stops with `error stop` on programming errors: `x` and `y` of different sizes, an unsupported
style, error bar styles without their bounds, a log axis over a non-positive fixed range, a full multiplot layout.
The interpreter instead reports every error through `iostat`/`iomsg`.
