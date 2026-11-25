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

### Text columns: names and labels

<<< @/examples/snippets/cb_strcol.gp{gnuplot}

<Plot name="cb_strcol" svg :width="560" :height="320" />

`strcol(1)` is the text of column 1: joined with a formatted number on a second line it names each bar (`xtic`), in
`sprintf` it builds the label of each bar (`with labels`), compared with `eq` it keeps one solver. See
[String columns](/guide/gnuplot-subset#string-columns).

### Data inside the script

<<< @/examples/snippets/cb_datablock.gp{gnuplot}

<Plot name="cb_datablock" svg :width="560" :height="320" />

A datablock keeps the data in the script itself: `plot`, `fit` and `stats` read `$CONV` as a file. See
[Datablocks and scripts](/guide/gnuplot-subset#datablocks-and-scripts).

### Data after the plot command

<<< @/examples/snippets/cb_inline_data.gp{gnuplot}

<Plot name="cb_inline_data" svg :width="560" :height="320" />

`'-'` reads the data from the lines after the statement, gnuplot's inline data: up to a line starting with `e`, one
block per `'-'` item, in order. See [Datablocks and scripts](/guide/gnuplot-subset#datablocks-and-scripts).

### A script with arguments

<<< @/examples/snippets/cb_call.gp{gnuplot}

<<< @/examples/files/panel.gp{gnuplot}

<Plot name="cb_call" svg :width="760" :height="300" />

`call` runs `panel.gp` with `ARG1` the column and `ARG2` the title; `column(ARG1 + 0)` reads the column the string
names. From the shell, `foresight -c panel.gp 2 continuity` does the same.

### Arrays

<<< @/examples/snippets/cb_arrays.gp{gnuplot}

<Plot name="cb_arrays" svg :width="560" :height="320" />

An array is filled in a loop, `|T|` its size; `plot T` and `stats T` read the index and the value of each element as
a file, `T[$1]` indexes it by a data column. See [Arrays](/guide/gnuplot-subset#arrays).

### Array slices

<<< @/examples/snippets/cb_slices.gp{gnuplot}

<Plot name="cb_slices" svg :width="560" :height="320" />

`M[3*q - 2:3*q]` is the array of a quarter's months, a copy assigned to `S`; `M[1:3]` and `M[10:]` print as arrays and
`|S|` is a slice's size. See [Slices](/guide/gnuplot-subset#slices).

### Shell commands and reset

<<< @/examples/snippets/cb_runtime.gp{gnuplot}

<Plot name="cb_runtime" svg :width="760" :height="300" />

`system('...')` and a command between backquotes give the output of a shell command (the run's host, the lines of the
log); `reset` puts the settings back to their defaults for the next panel. See
[Shell commands, reset and pause](/guide/gnuplot-subset#shell-commands-reset-and-pause).

### A plot that follows a run

<<< @/examples/snippets/cb_live_loop.gp{gnuplot}

<Plot name="cb_live_loop" svg :width="560" :height="320" />

gnuplot 6.0's live loop: each pass plots and pauses, the output rewritten at each plot. A real one is `while (1) {
plot ...; pause 5 }` with `set terminal html refresh 5`: the page in the browser follows the run (`foresight --watch`
does the same without a loop, see [Monitoring](/guide/monitoring)).

### A table of a plot

<<< @/examples/snippets/cb_table.gp{gnuplot}

<Plot name="cb_table" svg :width="560" :height="320" />

`set table $SMOOTH` makes the plot write its points into the datablock, in gnuplot's table layout, instead of drawing
them; plotted afterwards they are the spline itself, a marker every 10 points (`pi 10`). See
[Tables](/guide/gnuplot-subset#tables).

### Rows as text

<<< @/examples/snippets/cb_with_table.gp{gnuplot}

<<< @/examples/output/cb_with_table.txt{text}

<Plot name="cb_with_table" svg :width="560" :height="320" />

`with table if $2 > 1.6` writes the rows of the slow steps, as text, into the datablock: the `using` fields, each after
a blank, tab separated. Plotted over the whole run, they mark the steps that wrote a file. See
[With table](/guide/gnuplot-subset#with-table).

### Values printed into a datablock

<<< @/examples/snippets/cb_print_datablock.gp{gnuplot}

<Plot name="cb_print_datablock" svg :width="560" :height="320" />

`set print $ERR` sends the lines printed in the loop to a datablock, which then plots as data: a table computed by the
script itself. See [Print](/guide/gnuplot-subset#print).

### Random numbers

<<< @/examples/snippets/cb_random.gp{gnuplot}

<Plot name="cb_random" svg :width="560" :height="320" />

`rand(7)` seeds gnuplot's generator, `rand(0)` draws the next number: the walks are the ones gnuplot draws from the
same seed. `exists("steps")` lets a caller set the length first. See
[Expressions in using](/guide/gnuplot-subset#expressions-in-using).

## Axes, ticks and key

### A log axis with exponent labels

<<< @/examples/snippets/cb_logscale.gp{gnuplot}

<Plot name="cb_logscale" svg :width="560" :height="320" />

### A reversed axis

<<< @/examples/snippets/cb_reversed.gp{gnuplot}

<Plot name="cb_reversed" svg :width="560" :height="320" />


### Limits of the autoscale

<<< @/examples/snippets/cb_autoscale_limits.gp{gnuplot}

<Plot name="cb_autoscale_limits" svg :width="560" :height="320" />

`lb<*` and `*<ub` keep an autoscaled end within limits: the y range spans at least -1 to 1, the x range autoscales
within 0 to 12 whatever the data. See [Grid, zero axes and border](/guide/gnuplot-subset#grid-zero-axes-and-border).

### Tick steps and label formats

<<< @/examples/snippets/cb_ticks.gp{gnuplot}

<Plot name="cb_ticks" svg :width="560" :height="320" />

On a log axis the step is a factor: `set ytics 10` puts a tick every decade.

### Ticks without labels

<<< @/examples/snippets/cb_format_none.gp{gnuplot}

<Plot name="cb_format_none" svg :width="560" :height="320" />

`set format y ""` keeps the ticks and drops their labels (and their margin); a format without a conversion writes its
text at every tick. See [Ticks and label formats](/guide/gnuplot-subset#ticks-and-label-formats).

### Powers of ten and unit prefixes

<<< @/examples/snippets/cb_format_powers.gp{gnuplot}

<Plot name="cb_format_powers" svg :width="560" :height="320" />

gnuplot's `%T` is the power of ten of a value, as a superscript with enhanced text; `%s` its mantissa to a power of
1000 and `%c` the SI prefix of that power. See [Ticks and label formats](/guide/gnuplot-subset#ticks-and-label-formats).

### Ticks on the axes, a range frame

<<< @/examples/snippets/cb_tics_axis.gp{gnuplot}

<Plot name="cb_tics_axis" svg :width="640" :height="300" />

`set xtics axis` draws the ticks on y = 0, `set ytics axis` on x = 0, their labels taking no margin; `rangelimited`
keeps the ticks and the border side within the data. See
[Ticks and label formats](/guide/gnuplot-subset#ticks-and-label-formats).

### Room around the data, the date of the plot

<<< @/examples/snippets/cb_offsets.gp{gnuplot}

<Plot name="cb_offsets" svg :width="560" :height="320" />

`set offsets` moves the autoscaled ends out before the extension to the ticks; `set timestamp` writes the date (here
the documentation's fixed SOURCE_DATE_EPOCH). See [Offsets](/guide/gnuplot-subset#offsets) and
[Margins](/guide/gnuplot-subset#margins).

### Named ticks and extra ticks

<<< @/examples/snippets/cb_tics_list.gp{gnuplot}

<Plot name="cb_tics_list" svg :width="560" :height="320" />

An explicit list replaces the ticks: names at chosen positions, `""` with level `1` for an unlabelled minor tick. With
`add` the list joins the automatic ticks; a label holding a conversion is the format of its position (`"%.0f mm"`).

### A rug of ticks

<<< @/examples/snippets/cb_rug.gp{gnuplot}

<Plot name="cb_rug" svg :width="560" :height="360" />

An empty tic label is still a tick: `xtic("")` and `ytic("")` mark every row on both axes, a rug plot. See
[Text labels on any axis](/guide/gnuplot-subset#text-labels-on-any-axis).

### Names on the y axis

<<< @/examples/snippets/cb_ytic.gp{gnuplot}

<Plot name="cb_ytic" svg :width="560" :height="320" />

`ytic(5)` names the y ticks with column 5 at the ordinates (the point numbers here), as `xtic` does the x ones;
`x2tic` and `y2tic` need `set x2tics` and `set y2tics`. See
[Text labels on any axis](/guide/gnuplot-subset#text-labels-on-any-axis).

### Minor ticks

<<< @/examples/snippets/cb_mtics.gp{gnuplot}

<Plot name="cb_mtics" svg :width="560" :height="320" />

`set mxtics 4` divides each step of x in 4; `set mytics` alone takes gnuplot's count, 9 per decade on a log axis.

### Rotated labels and outward ticks

<<< @/examples/snippets/cb_tics_rotate.gp{gnuplot}

<Plot name="cb_tics_rotate" svg :width="560" :height="320" />

Long category names fit rotated: `rotate by 30 right` ends each label at its tick, below the axis. `out` points the
ticks away from the plot; `nomirror` leaves the opposite border bare.

### Rotated y labels

<<< @/examples/snippets/cb_ytics_rotate.gp{gnuplot}

<Plot name="cb_ytics_rotate" svg :width="560" :height="320" />

`set ytics rotate` turns long y labels to read upward, centred on their ticks, so the left margin stays narrow;
`rotate by 45` turns them by an angle, right-justified (on y2, left-justified), as gnuplot places them. See
[Ticks and label formats](/guide/gnuplot-subset#ticks-and-label-formats).

### A time axis

<<< @/examples/snippets/cb_time.gp{gnuplot}

<Plot name="cb_time" svg :width="640" :height="480" />

`set xdata time` reads the x field with the `timefmt`: the time spans two columns, so the residual is column 4. The
ticks fall on whole time units, the labels invented from the range as gnuplot's (`%H:%M:%S` within a day at minute
steps), or written by `set format x`; range ends are times. See [Time data](/guide/gnuplot-subset#time-data).

### Minor ticks in time units

<<< @/examples/snippets/cb_time_minor.gp{gnuplot}

<Plot name="cb_time_minor" svg :width="640" :height="260" />

`set mxtics time 10 minutes` (gnuplot 6.0) puts a minor tick at every 10 minutes of the clock, whatever the major
step; `time 1 months` marks the first of every month.

### Week dates

<<< @/examples/snippets/cb_weekdates.gp{gnuplot}

<Plot name="cb_weekdates" svg :width="640" :height="300" />

`weekdate_iso(year, week [, day])` gives the time of an ISO 8601 week date (weeks from Monday, week 1 the one of the
first Thursday: 2021-W01 starts on 4 January), `weekdate_cdc` the CDC epidemiological one (from Sunday), and
`tm_week(t, 0|1)` the week of a time, as gnuplot 6.0; `tm_mday`, `tm_mon` and the other `tm_*` give its fields. See
[Time data](/guide/gnuplot-subset#time-data).

### Two y axes

<<< @/examples/snippets/cb_y2.gp{gnuplot}

<Plot name="cb_y2" svg :width="560" :height="320" />

### Two x axes

<<< @/examples/snippets/cb_x2.gp{gnuplot}

<Plot name="cb_x2" svg :width="560" :height="320" />

The top border in another unit: the x2 axis takes the `x2range` given, here the frequency scaled to the Strouhal
number. The points are the same peaks plotted `axes x2y1`, against x2: each lands on its impulse, the check that the
two scales agree. Without a set `x2range`, items on x2 autoscale it on their own.

### A broken axis

<<< @/examples/snippets/cb_nonlinear_axis.gp{gnuplot}

<Plot name="cb_nonlinear_axis" svg :width="560" :height="320" />

`set nonlinear x via f(x) inverse g(x)` places the axis linearly in f: here f leaves out 100 to 500, a broken axis.
Its automatic ticks sit at the hidden axis' ticks, a step or a list in the axis' own values. See
[Ticks and label formats](/guide/gnuplot-subset#ticks-and-label-formats).

### A top axis linked to the bottom one

<<< @/examples/snippets/cb_linked_axes.gp{gnuplot}

<Plot name="cb_linked_axes" svg :width="560" :height="360" />

`set link x2 via F(x) inverse G(x)` maps the bottom axis onto the top one: wavenumber = 10⁴ / wavelength. As gnuplot
6.0, the top ticks sit at the bottom axis' automatic ticks, labelled by their mapped values. See
[Second x axis](/guide/gnuplot-subset#second-x-axis).

### Rotated labels on top

<<< @/examples/snippets/cb_x2_rotate.gp{gnuplot}

<Plot name="cb_x2_rotate" svg :width="560" :height="340" />

Named x2 ticks read the frequency axis as periods; `rotate by 45` turns them from their tick, away from the plot,
and the top margin grows to fit them. See [Ticks](/guide/gnuplot-subset#ticks-and-label-formats).

### The key below the plot

<<< @/examples/snippets/cb_key.gp{gnuplot}

<Plot name="cb_key" svg :width="560" :height="320" />

`outside` moves the key to the right margin (or `outside left`, `outside top center`, ...); `below` and `above` lay it out in rows.

### The key at a position

<<< @/examples/snippets/cb_key_at.gp{gnuplot}

<Plot name="cb_key_at" svg :width="560" :height="320" />

`at` puts the key where the data leave room: `left top` aligns its top left corner on the point, in data coordinates
by default, `graph` or `screen` fractions otherwise. `lmargin`, `rmargin`, `tmargin` and `bmargin` put it in a margin
instead. See [Key](/guide/gnuplot-subset#key).

### No key

<<< @/examples/snippets/cb_no_key.gp{gnuplot}

<Plot name="cb_no_key" svg :width="560" :height="320" />

`notitle` keeps one item out of the key; `set key noautotitle` all the untitled ones.


### Titles at the curves

<<< @/examples/snippets/cb_title_at.gp{gnuplot}

<Plot name="cb_title_at" svg :width="560" :height="320" />

`title ... at end` writes each title after the last point of its curve, with or without the key (`at beginning`
before the first one; `at X,Y` a key entry at a screen position). See [Key](/guide/gnuplot-subset#key).

### A key in its own layout

<<< @/examples/snippets/cb_key_layout.gp{gnuplot}

<Plot name="cb_key_layout" svg :width="560" :height="320" />

`reverse` puts the samples first and `Left` justifies the titles, `invert` lists the last run first, `opaque` paints the
key over the curves passing under it, `title` names it. See [Key](/guide/gnuplot-subset#key).

### A key in columns

<<< @/examples/snippets/cb_key_columns.gp{gnuplot}

<Plot name="cb_key_columns" svg :width="560" :height="320" />

`maxrows 3` starts a column every 3 entries, `tc variable` writes each title in its series' color, `lt 4 lw 1.5` styles
the box. See [Key](/guide/gnuplot-subset#key).


### Key entries of their own

<<< @/examples/snippets/cb_keyentry.gp{gnuplot}

<Plot name="cb_keyentry" svg :width="560" :height="320" />

`keyentry` adds a key entry with no data, here the samples of a boxplot and of error bars; `set style data
filledcurves y=0` gives the data items their fill to y = 0. See [Key](/guide/gnuplot-subset#key).

### Key samples of vectors, fills and labels

<<< @/examples/snippets/cb_key_samples.gp{gnuplot}

<Plot name="cb_key_samples" svg :width="560" :height="320" />

The key samples are gnuplot 6.0's: an arrow for vectors, a filled box with the fill style's border, none for a
`keyentry` of labels; `set key title "..." left` puts the title at the left of the key. See
[Key](/guide/gnuplot-subset#key).

### Key columns, label offsets, a title on the right

<<< @/examples/snippets/cb_key_options.gp{gnuplot}

<Plot name="cb_key_options" svg :width="560" :height="320" />

`set key columns N` lays the key out in N columns; `set ylabel "..." offset X,Y tc COLOR` moves (in characters) and
colors a label; `set title "..." right` justifies the title about its centre, as gnuplot. See
[Key](/guide/gnuplot-subset#key) and [Titles and labels](/guide/gnuplot-subset#set-unset-options).

### Enhanced text: sub and superscripts, Greek letters

<<< @/examples/snippets/cb_enhanced.gp{gnuplot}

<Plot name="cb_enhanced" svg :width="560" :height="340" />

gnuplot's markup, on by default: `_0` and `^{...}` sub and superscripts, `{/Symbol t}` a Greek τ, `{/:Bold ...}` and
`{/:Italic ...}`, also in the tick labels of a list. `noenhanced` writes a file name with its underscores as it is;
the automatic titles stay as they are. See [Enhanced text](/guide/gnuplot-subset#enhanced-text).

### Grid lines, zero axes and border

<<< @/examples/snippets/cb_grid_zero.gp{gnuplot}

<Plot name="cb_grid_zero" svg :width="560" :height="320" />

Grid lines at the major and minor ticks in their own style, the lines at x = 0 and y = 0, the left and bottom sides of
the border only, outward ticks longer than the default, x ends at the data (`set autoscale xfix`). See
[Grid, zero axes and border](/guide/gnuplot-subset#grid-zero-axes-and-border).

### One unit as long on both axes

<<< @/examples/snippets/cb_size_square.gp{gnuplot}

<Plot name="cb_size_square" svg :width="560" :height="360" />

`set size ratio -1` makes a unit of y as long as a unit of x, whatever the ranges: the circle stays round. `ratio -R`
makes a y unit R times an x unit. See [`set` options](/guide/gnuplot-subset#set-unset-options).

### A grid of panels

<<< @/examples/snippets/cb_multiplot.gp{gnuplot}

<Plot name="cb_multiplot" svg :width="560" :height="420" />

### Panels lined up

<<< @/examples/snippets/cb_margins.gp{gnuplot}

<Plot name="cb_margins" svg :width="560" :height="360" />

The same left and right borders at screen fractions line up the two panels, although the log labels of the first are
wider. See [Margins](/guide/gnuplot-subset#margins).

### Panels column by column

<<< @/examples/snippets/cb_multiplot_order.gp{gnuplot}

<Plot name="cb_multiplot_order" svg :width="560" :height="360" />

`set multiplot layout R,C columnsfirst upwards` fills the grid column by column from the bottom row (`rowsfirst` and
`downwards` are the defaults). See [Multiplot](/guide/gnuplot-subset#multiplot).


### Panels with margins and spacing

<<< @/examples/snippets/cb_multiplot_margins.gp{gnuplot}

<Plot name="cb_multiplot_margins" svg :width="560" :height="400" />

`margins L,R,B,T` puts the plot areas of the layout in that box of the page (screen fractions, or characters after
`char`), `spacing X,Y` apart: the plot areas line up whatever the tick labels. See
[Multiplot](/guide/gnuplot-subset#multiplot).

## Lines, points and error bars

### Special functions

<<< @/examples/snippets/cb_special_functions.gp{gnuplot}

<Plot name="cb_special_functions" svg :width="720" :height="480" />

gnuplot's Bessel, gamma, error, normal, Lambert W and Airy functions, by its own algorithms: the values are gnuplot's.
Γ is undefined at the poles, a gap. See [Special functions](/guide/gnuplot-subset#special-functions).


### Complex numbers

<<< @/examples/snippets/cb_complex.gp{gnuplot}

<Plot name="cb_complex" svg :width="560" :height="320" />

Values are complex, as gnuplot's: `I` is `{0,1}` (or write `{0,1}`), `abs` and `arg` give the gain and the phase of
a transfer function; a plotted value with an imaginary part is undefined. See
[Expressions](/guide/gnuplot-subset#expressions-in-using).

### Labels and arrows in a loop

<<< @/examples/snippets/cb_set_for.gp{gnuplot}

<Plot name="cb_set_for" svg :width="560" :height="320" />

`set for [i=1:5]` runs the `set` command once per value, `unset for` removes in a loop. See
[Iteration](/guide/gnuplot-subset#iteration).

### User variables and functions

<<< @/examples/snippets/cb_user_functions.gp{gnuplot}

<Plot name="cb_user_functions" svg :width="560" :height="320" />

`name = value` and `name(t) = expression` as in gnuplot: the functions read the variables when the plot is drawn,
and the range ends take expressions. See [User variables and functions](/guide/gnuplot-subset#user-variables-and-functions).

### A family of curves from arrays

<<< @/examples/snippets/cb_iterated_defs.gp{gnuplot}

<Plot name="cb_iterated_defs" svg :width="560" :height="320" />

Definitions written before an iterated item are run on each pass: `for [i = 1:4] k = shape[i], l = 1.0/rate[i],
weibull(x, k, l)`. See [Iteration](/guide/gnuplot-subset#iteration).

### Names as in the formulas

<<< @/examples/snippets/cb_greek_names.gp{gnuplot}

<Plot name="cb_greek_names" svg :width="560" :height="320" />

Names may hold UTF-8 letters, as gnuplot: `ω`, `ζ`, `τ` in variables, functions and their dummies. See
[User variables and functions](/guide/gnuplot-subset#user-variables-and-functions).


### Latin-1 strings and symbols

<<< @/examples/snippets/cb_latin1.gp{gnuplot}

<Plot name="cb_latin1" svg :width="560" :height="320" />

`"\260"` is an octal byte, as gnuplot; with `set encoding iso_8859_1` the bytes read as Latin-1 (°, é), the
Symbol font's upper half as its symbols (`\362` the integral, `\245` infinity), and `\U+hhhh` a code point in
enhanced text. See [Strings](/guide/gnuplot-subset#strings).

### Sums and assignments in a plot

<<< @/examples/snippets/cb_sums.gp{gnuplot}

<Plot name="cb_sums" svg :width="560" :height="320" />

`sum [k=a:b] term` adds the term for each k (integers stay integers); a plot item may be an assignment, done in its
turn, so each `square(x)` is drawn with the `n` set before it. See
[Expressions](/guide/gnuplot-subset#functions) and [Plot items](/guide/gnuplot-subset#plot-items).


### Assignments inside expressions

<<< @/examples/snippets/cb_running_mean.gp{gnuplot}

<Plot name="cb_running_mean" svg :width="560" :height="320" />

`name = value` is an operator and `(a, b)` evaluates both, the last the value, as gnuplot: an expression of a
`using` field runs on each row, so `s` sums along the file and `shift5` keeps the last five values in `b1` ...
`b5`. See [Expressions](/guide/gnuplot-subset#expressions-in-using).

### Array elements assigned in an expression

<<< @/examples/snippets/cb_array_assign.gp{gnuplot}

<Plot name="cb_array_assign" svg :width="560" :height="320" />

`A[i] = value` is an expression too: a `stats` or `plot` over a file stores each row in an element (`$0` counts
the rows from 0), and an expression that assigns elements of an array reads them as they are when it runs. See
[Arrays](/guide/gnuplot-subset#arrays).

### Recursive functions

<<< @/examples/snippets/cb_recursion.gp{gnuplot}

<Plot name="cb_recursion" svg :width="560" :height="320" />

The Chebyshev polynomials by their three-term recurrence: `T(n, x)` calls itself, as gnuplot 6.0 allows, 251 calls
deep at most. See [User variables and functions](/guide/gnuplot-subset#user-variables-and-functions).

### Function blocks

<<< @/examples/snippets/cb_function_blocks.gp{gnuplot}

<Plot name="cb_function_blocks" svg :width="560" :height="320" />

A function block runs script lines when called: Newton's iterations in a loop, a `local` start, a `return` from inside
the loop; `$cbrt(x)` is then plotted like any function. See [Function blocks](/guide/gnuplot-subset#function-blocks).

### Bit flags

<<< @/examples/snippets/cb_bitwise.gp{gnuplot}

<Plot name="cb_bitwise" svg :width="560" :height="320" />

A status column packs flags as bits: `int($3) & 2` keeps the restarts, `int($3) & 4` the steps that wrote a file (a
column is real, `int` makes it an integer for the bitwise operators). See
[Expressions in using](/guide/gnuplot-subset#expressions-in-using).

### Line styles and point types

<<< @/examples/snippets/cb_styles.gp{gnuplot}

<Plot name="cb_styles" svg :width="560" :height="320" />

`set style line N` defines a style once; `ls N` applies it, the options after it override it.

### Linetypes of your own

<<< @/examples/snippets/cb_linetype.gp{gnuplot}

<Plot name="cb_linetype" svg :width="560" :height="320" />

`set linetype N` redefines a linetype for every plot after it (`reset` keeps it); `set pointsize` sets the size of the
points without their own. See [Styles](/guide/gnuplot-subset#styles).

### Point and dash types

<<< @/examples/snippets/cb_point_types.gp{gnuplot}

<Plot name="cb_point_types" svg :width="640" :height="300" />

The 16 point types (`pt 0` a dot, odd ones from 5 filled) and the 5 dash types, for picking one; a one-line datablock
gives the point its place, `plot for` repeats it.


### Interrupted lines

<<< @/examples/snippets/cb_interrupted_lines.gp{gnuplot}

<Plot name="cb_interrupted_lines" svg :width="560" :height="320" />

`pointinterval -N` (`pi -N`) marks every N-th point and blanks the line under the marker; `pi N` only marks.
`lt -1` is solid black, whatever the dash type of the item's own linetype. See
[`plot` items](/guide/gnuplot-subset#plot-items).

### Characters as points

<<< @/examples/snippets/cb_char_points.gp{gnuplot}

<Plot name="cb_char_points" svg :width="560" :height="320" />

`pt "c"` draws a character as the point, in the item's `tc` color; `pi N` marks every N-th point, `pn N` about N
evenly spread. See [Point types](/guide/gnuplot-subset#point-types).

### Dash patterns of your own

<<< @/examples/snippets/cb_dashes.gp{gnuplot}

<Plot name="cb_dashes" svg :width="560" :height="320" />

`dt "string"` draws gnuplot's custom patterns: `.` a dot, `-` a dash, `_` a long dash, a blank a longer gap; `dt
(solid, empty, ...)` gives the lengths; both scale with the line width. `lc bgnd`, `lt nodraw` and `lt -1` are the
background, nothing and black. See [Line properties](/guide/gnuplot-subset#styles).

### A color per point

<<< @/examples/snippets/cb_lc_variable.gp{gnuplot}

<Plot name="cb_lc_variable" svg :width="560" :height="320" />

`lc variable` reads the color of each point from the last `using` column, a linetype number; a segment takes the color
of its end point, as in gnuplot. `lc rgb variable` reads 24-bit colors instead (`0xRRGGBB`). See
[Colors per point](/guide/gnuplot-subset#colors-per-point-and-from-the-palette).

### A type, size and color per point

<<< @/examples/snippets/cb_pt_variable.gp{gnuplot}

<Plot name="cb_pt_variable" svg :width="560" :height="360" />

`pt variable` reads each point's type from a column, after the sizes of `ps variable` and before the colors of
`lc rgb variable`: `using x:y:size:type:color`. The key sample of such an item is a dot, as gnuplot's. See
[Point types](/guide/gnuplot-subset#point-types).

### High values on top

<<< @/examples/snippets/cb_zsort.gp{gnuplot}

<Plot name="cb_zsort" svg :width="560" :height="320" />

`zsort` draws the points of a curve in the order of their z (the third column), the highest last, so dense clouds
show their extremes, as gnuplot 6.0. See [`plot` items](/guide/gnuplot-subset#plot-items).

### Colors from the palette

<<< @/examples/snippets/cb_lc_palette.gp{gnuplot}

<Plot name="cb_lc_palette" svg :width="560" :height="320" />

`lc palette z` colors each point by the last `using` column through the palette: here the iteration, so the path of
the run reads from dark to light, and the color box gives the scale. `lc palette frac F` takes one color of the
palette for a whole item. See [Colors per point](/guide/gnuplot-subset#colors-per-point-and-from-the-palette).

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

### Error bar caps

<<< @/examples/snippets/cb_errorbar_caps.gp{gnuplot}

<Plot name="cb_errorbar_caps" svg :width="760" :height="280" />

`set errorbars 3` makes the caps three times the default, `lc` and `lw` draw the bars in their own line, `small`
drops the caps. See [Error bar caps](/guide/gnuplot-subset#error-bar-caps).

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


### Filled steps

<<< @/examples/snippets/cb_fillsteps.gp{gnuplot}

<Plot name="cb_fillsteps" svg :width="560" :height="320" />

`with fillsteps` fills the area under the steps down to y = 0 in the fill style, as gnuplot. See
[Lines, steps and impulses](/guide/gnuplot-subset#lines-steps-and-impulses).

### A spectrum: impulses and dots

<<< @/examples/snippets/cb_impulses.gp{gnuplot}

<Plot name="cb_impulses" svg :width="560" :height="320" />

`impulses` draws a segment from y = 0 to each point (0 is in the autoscale, as gnuplot); `dots` a tiny dot per point.

### Functions of x

<<< @/examples/snippets/cb_function.gp{gnuplot}

<Plot name="cb_function" svg :width="560" :height="320" />

Without data, functions are sampled over [-10:10], or the `xrange`; `set samples` sets the number of points.

### Sharp extrema of a function

<<< @/examples/snippets/cb_sharpen.gp{gnuplot}

<Plot name="cb_sharpen" svg :width="560" :height="320" />

`sharpen` finds the extrema of a function that fall between its samples (a golden section search where the curve
turns) and adds them: the minima of `abs(sqrt(sin(x)))` reach 0, while the plain samples stop short. See
[Functions](/guide/gnuplot-subset#functions).

### Parametric curves

<<< @/examples/snippets/cb_parametric.gp{gnuplot}

<Plot name="cb_parametric" svg :width="560" :height="360" />

`set parametric` reads each function item as a pair x(t), y(t), sampled over `trange`. See
[Parametric plots](/guide/gnuplot-subset#parametric-plots).


### Sampled pseudo-files

<<< @/examples/snippets/cb_sampled.gp{gnuplot}

<Plot name="cb_sampled" svg :width="560" :height="400" />

The pseudo-file `'+'` samples a variable as its column 1, here `t` over the item's own range by `pi/20`; `'++'` is
a grid of `u` and `v` (`set samples`, `set isosamples` points over `urange`, `vrange`), the columns of a vector field
colored by its length. See [Sampled pseudo-files](/guide/gnuplot-subset#sampled-pseudo-files-and).

### Asymptotes and clipping

<<< @/examples/snippets/cb_clip.gp{gnuplot}

<Plot name="cb_clip" svg :width="560" :height="320" />

As gnuplot, a segment with both ends out of the plot is not drawn: no line down the asymptotes; `set clip two` draws
it. See [Clipping](/guide/gnuplot-subset#clipping).

### A range for one plot

<<< @/examples/snippets/cb_inline_range.gp{gnuplot}

<Plot name="cb_inline_range" svg :width="560" :height="320" />

Inline ranges set x, then y, for that plot only: `set xrange` is left alone. `t=` names the variable of the functions.

### A model over the data

<<< @/examples/snippets/cb_model.gp{gnuplot}

<Plot name="cb_model" svg :width="560" :height="320" />

A function is sampled over the x range of the data of the same plot.

### One line per column

<<< @/examples/snippets/cb_plot_for.gp{gnuplot}

<Plot name="cb_plot_for" svg :width="560" :height="320" />

`plot for` plots the item once per value of `i`: `u 1:i` reads column `i`, `word(names, i-1)` titles it, the colors
advance as for separate items.

### Statistics of a run

<<< @/examples/snippets/cb_stats.gp{gnuplot}

<<< @/examples/output/cb_stats.txt{text}

<Plot name="cb_stats" svg :width="560" :height="320" />

`stats` sets `cd_mean`, `cd_stddev` and the other `cd_*` values of the iterations kept (the condition makes the
others invalid); `output` prints gnuplot's report, silent otherwise. The mean is then a constant to plot, and
`sprintf` writes it in the title.

### A summary in the terminal

<<< @/examples/snippets/cb_loops.gp{gnuplot}

<<< @/examples/output/cb_loops.txt{text}

`do for` runs the block per column, `stats` (silent with `nooutput`, as in gnuplot) measures it, `print` and
`sprintf` write the table: a report at the end of a run, without a plot.

### Fitting a model

<<< @/examples/snippets/cb_fit.gp{gnuplot}

<<< @/examples/output/cb_fit.txt{text}

<Plot name="cb_fit" svg :width="560" :height="320" />

`fit` adjusts the parameters after `via` (user variables; an undefined one starts at 1) by gnuplot's
Marquardt-Levenberg method, to gnuplot's digits, and sets `c_err`, `p_err` and the `FIT_*` variables. It is silent
unless asked: `set fit results` prints gnuplot's report, `set fit logfile 'fit.log'` appends it to a file. Here the
slope `p` is the observed order of accuracy of a scheme. From Fortran, `call fit(model, x, y, params)` does the same
([library](../guide/library.md)).

### A fit of two variables

<<< @/examples/snippets/cb_fit_surface.gp{gnuplot}

<<< @/examples/output/cb_fit_surface.txt{text}

<Plot name="cb_fit_surface" svg :width="560" :height="320" />

`fit` takes a function of `x` and `y`: `using x:y:z:s`, the last column the errors (here 1, unweighted). The fitted
plane is drawn at each y as a line. See [Fit](/guide/gnuplot-subset#fit).

### Histogram and distribution

<<< @/examples/snippets/cb_smooth.gp{gnuplot}

<Plot name="cb_smooth" svg :width="560" :height="320" />

`smooth frequency` sums the y of the points of equal x: binned x and y = 1 count the points per bin (`bins` does the
binning itself: [a histogram of a sample](#a-histogram-of-a-sample)). `smooth cnormal`
accumulates them over the sorted x, divided by the total: the fraction of iterations below each value. `smooth unique`
averages repeated x instead. See [Smoothing](/guide/gnuplot-subset#smoothing).

### Block averages and running totals

<<< @/examples/snippets/cb_unique.gp{gnuplot}

<Plot name="cb_unique" svg :width="760" :height="320" />

`smooth unique` merges the points of equal x into their mean: an x rounded to blocks of 25 steps gives the mean wall
time of each block. `smooth cumulative` adds the y up to each x: the elapsed time of the run. See
[Smoothing](/guide/gnuplot-subset#smoothing).

### Splines and densities

<<< @/examples/snippets/cb_splines.gp{gnuplot}

<Plot name="cb_splines" svg :width="760" :height="320" />

`csplines` passes through every point; `acsplines` weighs fit against smoothness (smaller weights, smoother curve);
`sbezier` stays inside the points. `kdensity` estimates the distribution of a sample: gnuplot's bandwidth by default,
narrower to show more detail.

### A spline along a path

<<< @/examples/snippets/cb_smooth_path.gp{gnuplot}

<Plot name="cb_smooth_path" svg :width="560" :height="360" />

`smooth path` fits each set of points (apart at blank lines) in its order, not sorted on x: a closed set wraps
around, and `with filledcurves closed` closes every set. See [Smoothing](/guide/gnuplot-subset#smoothing).


### Hulls around scattered points

<<< @/examples/snippets/cb_hulls.gp{gnuplot}

<Plot name="cb_hulls" svg :width="560" :height="360" />

`convexhull` keeps the points of the bounding convex polygon, clockwise and closed; `concavehull` a chi-shape that
follows the hollows (its length from the variable `chi_length`, else `set chi_shape fraction` of the longest edge);
`expand D` pushes the hull out by D, and `smooth path` rounds it. As gnuplot 6.0, point for point. See
[Smoothing](/guide/gnuplot-subset#smoothing).

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

### Groups of bars

<<< @/examples/snippets/cb_hist_groups.gp{gnuplot}

<Plot name="cb_hist_groups" svg :width="560" :height="320" />

`newhistogram` starts a group 2 rows after the previous one, its title below the axis, its colors from `lt 3`.

### Group titles

<<< @/examples/snippets/cb_hist_titles.gp{gnuplot}

<Plot name="cb_hist_titles" svg :width="560" :height="320" />

`set style histogram ... title tc C offset X,Y` colors the group titles and moves them (in characters).

### One stack per column

<<< @/examples/snippets/cb_hist_columns.gp{gnuplot}

<Plot name="cb_hist_columns" svg :width="560" :height="320" />

`columnstacked` stacks each column: the rows in their linetype colors, named in the key by `key(1)`, the stacks named
by the column headers (`title columnhead`).

### Stacks colored by category

<<< @/examples/snippets/cb_hist_colors.gp{gnuplot}

<Plot name="cb_hist_colors" svg :width="560" :height="320" />

Column-stacked histograms take `lc variable`: each row in the linetype a function of its category gives; the
stacks are named by their titles and `keyentry` builds the key. See
[Histograms](/guide/gnuplot-subset#histograms).

### Clustered bars with error bars

<<< @/examples/snippets/cb_hist_errorbars.gp{gnuplot}

<Plot name="cb_hist_errorbars" svg :width="560" :height="320" />

`errorbars` lays the bars out as `clustered` and draws the error of each (`using Y:ERR`, or `Y:LOW:HIGH`), `lw 2` wide.

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


### Candles colored by a column

<<< @/examples/snippets/cb_lc_styles.gp{gnuplot}

<Plot name="cb_lc_styles" svg :width="560" :height="320" />

`lc variable` takes the linetype of each candle from the last `using` column: here 2 (green) when the price closes
up, 7 (red) when down. It also colors histograms, boxxyerror rectangles, filled curves and polygons. See
[Colors](/guide/gnuplot-subset#colors-per-point-and-from-the-palette).

### A swarm of points

<<< @/examples/snippets/cb_jitter.gp{gnuplot}

<Plot name="cb_jitter" svg :width="560" :height="320" />

`set jitter` moves the points that would overlap aside, alternately left and right: a bee swarm. The values are
drawn with gnuplot's `invnorm(rand(0))`. See [Point types](/guide/gnuplot-subset#point-types).

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


### A smoothed band

<<< @/examples/snippets/cb_smooth_band.gp{gnuplot}

<Plot name="cb_smooth_band" svg :width="560" :height="320" />

A band `x:y1:y2` of filledcurves takes the curve filters: `smooth csplines` smooths both curves on the same samples.
The format string after `using` reads the fields by scanf conversions, as gnuplot. See
[Boxes and filled curves](/guide/gnuplot-subset#boxes-and-filled-curves).

### A transparent fill color

<<< @/examples/snippets/cb_fill_color.gp{gnuplot}

<Plot name="cb_fill_color" svg :width="560" :height="320" />

`fc` is the fill's own color, here gnuplot's `#AARRGGBB` with an alpha channel, read from a string variable after
`rgb`; the line keeps `lc`. See [Plot items](/guide/gnuplot-subset#plot-items).

### Fill above and below a line

<<< @/examples/snippets/cb_fill_above.gp{gnuplot}

<Plot name="cb_fill_above" svg :width="560" :height="320" />

`filledcurves above y=V` and `below y=V` keep the parts of the area to the line where the curve is above or below it;
`x1` and `x2` fill to the bottom and top of the plot, `xy=X,Y` to a point. The restart at iteration 60 splits the fill as
it splits a line.

### Fill above and below zero

<<< @/examples/snippets/cb_fill_zero.gp{gnuplot}

<Plot name="cb_fill_zero" svg :width="560" :height="320" />

`above` and `below` without `y=V` fill against y = 0, as gnuplot; next to an axis word (`above x1`) they are
ignored. See [Boxes and filled curves](/guide/gnuplot-subset#boxes-and-filled-curves).

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


### Arrow styles on vectors

<<< @/examples/snippets/cb_vector_heads.gp{gnuplot}

<Plot name="cb_vector_heads" svg :width="560" :height="360" />

`with vectors as N` takes the heads, the fill, the head size and the color of `set style arrow N`; `size L,A` (x
axis values, or `screen`, `graph`, `character`) and `filled` set them on the item. See
[Vectors, ellipses, polygons, labels and sectors](/guide/gnuplot-subset#vectors-ellipses-polygons-labels-and-sectors).

### A style per arrow

<<< @/examples/snippets/cb_arrowstyle_var.gp{gnuplot}

<Plot name="cb_arrowstyle_var" svg :width="560" :height="360" />

`arrowstyle variable` (`as variable`) takes the number of an arrow style from the column after the vector's:
each arrow its heads, fill, width and color. See
[Vectors, ellipses, polygons, labels and sectors](/guide/gnuplot-subset#vectors-ellipses-polygons-labels-and-sectors).

### A Gantt chart

<<< @/examples/snippets/cb_gantt.gp{gnuplot}

<Plot name="cb_gantt" svg :width="560" :height="320" />

Each task is a vector from its start to its end, without a head, thick; `ytic(1)` names its row. The blanks around the
colons of `using` are read as gnuplot does, and `title ... at graph X, Y` places a key entry in the plot area. See
[Vectors](/guide/gnuplot-subset#vectors-ellipses-polygons-labels-and-sectors).

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

### The area under a curve

<<< @/examples/snippets/cb_area.gp{gnuplot}

<Plot name="cb_area" svg :width="560" :height="320" />

`filledcurves x1` fills down to the bottom of the plot, `closed` fills the polygon of the points.

### Fills to the borders

<<< @/examples/snippets/cb_fill_borders.gp{gnuplot}

<Plot name="cb_fill_borders" svg :width="560" :height="320" />

`y1` fills across to the left border, `y2` to the right one, `x=5` to the vertical line x = 5, as gnuplot 6.0. See
[Boxes and filled curves](/guide/gnuplot-subset#boxes-and-filled-curves).

### Functions filled

<<< @/examples/snippets/cb_function_fills.gp{gnuplot}

<Plot name="cb_function_fills" svg :width="560" :height="320" />

A function takes `with filledcurves` (to a level `y=V`, closed, `x1`, ...) and `with boxes` as data does, its samples
filled; a range before an item, `[0:4] 0.6*x`, samples that function alone over it. See
[Filled curves](/guide/gnuplot-subset#boxes-and-filled-curves) and [Plot items](/guide/gnuplot-subset#plot-items).

### A color per shape

<<< @/examples/snippets/cb_lc_shapes.gp{gnuplot}

<Plot name="cb_lc_shapes" svg :width="560" :height="320" />

`lc variable` colors each box, circle or ellipse by the last `using` column, a linetype number (`lc rgb variable`: a
24-bit color). See [Colors](/guide/gnuplot-subset#colors-per-point-and-from-the-palette).

### Labels, arrows and objects

<<< @/examples/snippets/cb_annotations.gp{gnuplot}

<Plot name="cb_annotations" svg :width="640" :height="400" />

Positions mix data (`first`), plot area (`graph`) and page (`screen`) coordinates; the band in `graph` y covers the
whole height behind the grid, the polygon is in front of the curve. In the HTML page the objects zoom with the data.
See [Labels, arrows and objects](/guide/gnuplot-subset#labels-arrows-and-objects).

### Images from PNG files

<<< @/examples/snippets/cb_pixmap.gp{gnuplot}

<Plot name="cb_pixmap" svg :width="560" :height="320" />

`set pixmap N 'file.png'` puts a PNG image on the page, as gnuplot 6.0: `at` its lower left corner (its centre with
`center`), in any coordinates; `width` (or `height`) sets one side, the other by the image's aspect; `size W,H` both,
none its own pixels. The SVG holds the file itself. See
[Labels, arrows and objects](/guide/gnuplot-subset#labels-arrows-and-objects).


### Fonts per text

<<< @/examples/snippets/cb_fonts.gp{gnuplot}

<Plot name="cb_fonts" svg :width="560" :height="320" />

Each text takes gnuplot's `font "family:Bold:Italic,size"`: the title larger, the axis labels italic and bold, the
tick labels smaller, the key and the label in a serif family. As gnuplot, only the title (and the x2 label, the key)
take room by their size. See [Fonts](/guide/gnuplot-subset#fonts).

### Boxed labels

<<< @/examples/snippets/cb_boxed_labels.gp{gnuplot}

<Plot name="cb_boxed_labels" svg :width="560" :height="320" />

`with labels boxed` writes each text on the background, over the line, when the text box style is opaque or has a
border, as gnuplot's svg terminal. See [Labels, arrows and objects](/guide/gnuplot-subset#labels-arrows-and-objects).



### Hypertext on points

<<< @/examples/snippets/cb_hypertext.gp{gnuplot}

<Plot name="cb_hypertext" svg :width="560" :height="320" />

`with labels hypertext` shows each text only on mouse-over of its point (hover the dots), as gnuplot's svg; `ps
variable` sizes each point from a column. See
[Labels, arrows and objects](/guide/gnuplot-subset#labels-arrows-and-objects).

### Labels turned and colored by columns

<<< @/examples/snippets/cb_label_rotate.gp{gnuplot}

<Plot name="cb_label_rotate" svg :width="560" :height="360" />

`with labels rotate variable` turns each label by the fourth column, `tc variable` colors it by the last one. See
[Vectors, ellipses, polygons, labels and sectors](/guide/gnuplot-subset#vectors-ellipses-polygons-labels-and-sectors).

### Labels with tic labels

<<< @/examples/snippets/cb_labels_tics.gp{gnuplot}

<Plot name="cb_labels_tics" svg :width="560" :height="320" />

`with labels` takes `xticlabels()` (and `yticlabels()`) besides its text column: the text at the point, the
names under the axis. `%.3S` rounds the milliseconds, as gnuplot. See
[Time data](/guide/gnuplot-subset#time-data).

### Arrow styles and dashed objects

<<< @/examples/snippets/cb_arrow_styles.gp{gnuplot}

<Plot name="cb_arrow_styles" svg :width="560" :height="360" />

`set style arrow N` names a look, `as N` applies it (an option after it changes that one only); `set style rectangle`
gives the rectangles set next their fill and border; `dt N` dashes an object's border; a label `at character X, Y`
stands X cells from the left and Y up from the bottom of the page.

## Heatmaps and images

### A heatmap

<<< @/examples/snippets/cb_image.gp{gnuplot}

<Plot name="cb_image" svg :width="560" :height="400" />

`x:y:z` points on a regular grid, colored by the default palette; the color box at the right.


### A heat map of sparse data

<<< @/examples/snippets/cb_sparse_matrix.gp{gnuplot}

<Plot name="cb_sparse_matrix" svg :width="520" :height="400" />

`sparse matrix=(4,4) origin=(1,1)` bins the given points into a 4 by 4 grid, each in its nearest cell, the cells
without a point left empty: here a distance matrix given as its upper triangle. See
[plot items](/guide/gnuplot-subset#plot-items).

### A table with named rows and columns

<<< @/examples/snippets/cb_matrix_headers.gp{gnuplot}

<Plot name="cb_matrix_headers" svg :width="560" :height="360" />

`matrix rowheaders columnheaders` reads a CSV table as gnuplot does: its first row names the columns, the first cell
of each row names it, and the names become the tick labels. See [plot items](/guide/gnuplot-subset#plot-items).
### A matrix file

<<< @/examples/snippets/cb_matrix.gp{gnuplot}

<Plot name="cb_matrix" svg :width="560" :height="400" />

`matrix` reads the values as they lie in the file: columns along x, rows along y. `maxcolors 10` quantizes the
palette. See [Images and palettes](/guide/gnuplot-subset#images-and-palettes).


### A matrix with its coordinates

<<< @/examples/snippets/cb_nonuniform.gp{gnuplot}

<Plot name="cb_nonuniform" svg :width="560" :height="360" />

`nonuniform matrix` reads the x of the columns in the first row and the y of the rows in the first column; `index
"fine"` picks the dataset after the comment line `# fine`. See
[Images and palettes](/guide/gnuplot-subset#images-and-palettes).

### Statistics of a matrix

<<< @/examples/snippets/cb_stats_matrix.gp{gnuplot}

<Plot name="cb_stats_matrix" svg :width="560" :height="320" />

`stats ... matrix` gives the statistics of the values with the size of the matrix (`STATS_size_x`, `_y`) and the
places of its extremes; `every` keeps columns (points) and rows (blocks) of a matrix, for `stats` and for the image.
See [Stats](/guide/gnuplot-subset#stats).

### Palettes

<<< @/examples/snippets/cb_palettes.gp{gnuplot}

<Plot name="cb_palettes" svg :width="760" :height="560" />

`set palette gray`, `rgbformulae R,G,B` (any of gnuplot's 37), `defined (v color, ...)`, `cubehelix [start S]
[cycles C] [saturation S]`, `viridis`, with `negative` and `maxcolors N`. See [Images and palettes](/guide/gnuplot-subset#images-and-palettes).

### A palette in hue, saturation and value

<<< @/examples/snippets/cb_palette_hsv.gp{gnuplot}

<Plot name="cb_palette_hsv" svg :width="560" :height="360" />

`set palette model HSV` reads the palette's three components as hue (0 to 1), saturation and value; `defined (v h s
v, ...)` takes them as numbers. See [Palettes](/guide/gnuplot-subset#images-and-palettes).


### A palette of functions

<<< @/examples/snippets/cb_palette_functions.gp{gnuplot}

<Plot name="cb_palette_functions" svg :width="560" :height="320" />

`set palette functions R, G, B` gives the three components as expressions of `gray`, here hue, saturation and value
(`model HSV`). See [Images and palettes](/guide/gnuplot-subset#images-and-palettes).

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


### Images from binary files

<<< @/examples/snippets/cb_binary.gp{gnuplot}

<Plot name="cb_binary" svg :width="560" :height="320" />

`binary array=(W,H) format='%uchar'` reads raw bytes, a pixel after the other, as gnuplot: `flipy` puts the first
scan line on top, `dx`, `dy` and `origin` place and scale the pixels. See
[Images and palettes](/guide/gnuplot-subset#images-and-palettes).

### Rotated images

<<< @/examples/snippets/cb_binary_rotate.gp{gnuplot}

<Plot name="cb_binary_rotate" svg :width="560" :height="360" />

`center=(X,Y)` places a binary image by its centre and `rotation=A` turns it about that centre (`90d`, `0.5pi` or
radians), as gnuplot: a right angle keeps the pixels a grid, any other one draws each pixel as a small polygon. See
[Images and palettes](/guide/gnuplot-subset#images-and-palettes).

### Colors as numbers

<<< @/examples/snippets/cb_rgb_numbers.gp{gnuplot}

<Plot name="cb_rgb_numbers" svg :width="560" :height="360" />

`lc rgb N` takes a number, 0xRRGGBB (0xAARRGGBB with a transparency): here an expression per entry; a key taller
than the page wraps into columns, as gnuplot. See [Key](/guide/gnuplot-subset#key).

### Named colormaps

<<< @/examples/snippets/cb_named_colormaps.gp{gnuplot}

<Plot name="cb_named_colormaps" svg :width="560" :height="360" />

`set colormap new NAME` saves the current palette, `lc palette NAME` colors an item's z column by it (over its own
range with `set colormap NAME range [a:b]`). See [Colors per point and from the
palette](/guide/gnuplot-subset#colors-per-point-and-from-the-palette).

### An RGB image

<<< @/examples/snippets/cb_rgbimage.gp{gnuplot}

<Plot name="cb_rgbimage" svg :width="560" :height="400" />

`rgbimage` (`x:y:r:g:b`) and `rgbalpha` (`x:y:r:g:b:a`) color each pixel directly, components 0 to 255 (`set rgbmax 1`
for fractions), without palette nor color box.

## 3D plots

### A surface in 3D

<<< @/examples/snippets/cb_view3d_surface.gp{gnuplot}

<Plot name="cb_view3d_surface" svg :width="560" :height="400" />

`splot` of a function of x and y draws it as a mesh of iso-curves (`set isosamples`) in gnuplot's default view,
`set view 60, 30`: the box, its base plane below the z range (`set xyplane relative 0.5`), the x and y ticks along
the front of the base, the z ticks at its left corner, the key at the top right, as gnuplot 6.0 places them. See
[3D views](/guide/gnuplot-subset#3d-views).

### One surface, two views

<<< @/examples/snippets/cb_view3d_views.gp{gnuplot}

<Plot name="cb_view3d_views" svg :width="760" :height="400" />

`set view ROT_X, ROT_Z, SCALE, SCALE_Z` turns the box (rot_x about the horizontal, then rot_z about the vertical) and
scales it, the z axis apart; `set xyplane at 0` puts the base plane at z = 0, `set border 4095` draws the whole box.
See [3D views](/guide/gnuplot-subset#3d-views).

### Arrows and labels in 3D

<<< @/examples/snippets/cb_view3d_arrows.gp{gnuplot}

<Plot name="cb_view3d_arrows" svg :width="560" :height="400" />

`set arrow` and `set label` take a third coordinate in a 3D view: x, y, z axis values projected as the data (`graph`
ones fractions of the three axes, `screen` ones as they are), here the axes drawn as arrows from the origin;
`set ztics axis` puts the z ticks on the z axis through x = y = 0. See [3D views](/guide/gnuplot-subset#3d-views).

### A field seen from above

<<< @/examples/snippets/cb_map_points.gp{gnuplot}

<Plot name="cb_map_points" svg :width="560" :height="400" />

`splot` plots points with a height; `set view map` looks at them from above, as a 2D plot laid out as gnuplot's 3D
map (its plot area, ticks and color box), `lc palette` coloring each point by its z. The `using` fields are `plot`'s
with the z third. See [3D plots](/guide/gnuplot-subset#3d-plots).

### A function as a colored map

<<< @/examples/snippets/cb_map_pm3d.gp{gnuplot}

<Plot name="cb_map_pm3d" svg :width="560" :height="400" />

`with pm3d` draws a surface as quadrangles colored by the palette, gnuplot's pm3d: seen from above it is a heatmap of
the function's grid (`set samples`, `set isosamples`), each cell split 2 by 2 (`set pm3d interpolate 2,2`). See
[3D plots](/guide/gnuplot-subset#3d-plots).

### Contour lines over a map

<<< @/examples/snippets/cb_map_contour.gp{gnuplot}

<Plot name="cb_map_contour" svg :width="560" :height="400" />

`set contour` traces the levels of the surface (gnuplot's contour.c), each in a linetype of its own with a key entry
for its value; `set pm3d at b` with `unset surface` draws the colored map without the surface's own lines. See
[Contours](/guide/gnuplot-subset#contours).

### A density map of scattered points

<<< @/examples/snippets/cb_map_dgrid3d.gp{gnuplot}

<Plot name="cb_map_dgrid3d" svg :width="560" :height="400" />

`set dgrid3d ... gauss kdensity` grids the points on a 60 by 60 grid with a Gaussian kernel, each node the sum of the
points' weights: a density map, drawn with pm3d; `nogrid` keeps the points of the second item as they are. See
[Gridded and masked surfaces](/guide/gnuplot-subset#gridded-and-masked-surfaces).

### A surface masked to its data

<<< @/examples/snippets/cb_map_mask.gp{gnuplot}

<Plot name="cb_map_mask" svg :width="560" :height="400" />

A grid from scattered points (`set dgrid3d`) covers their bounding box, beyond the data. Their convex hull, tabulated
into `$HULL`, becomes a mask (`with mask`): the pm3d item with the `mask` option is drawn only inside it. See
[Gridded and masked surfaces](/guide/gnuplot-subset#gridded-and-masked-surfaces).

## Polar and radial charts

### A polar plot

<<< @/examples/snippets/cb_polar.gp{gnuplot}

<Plot name="cb_polar" svg :width="520" :height="400" />

A probe's directivity against a cardioid model, theta in degrees, in gnuplot's round idiom: square plot, polar border
and grid, theta labels, no x and y ticks. See [Polar plots](/guide/gnuplot-subset#polar-plots).


### A reversed r axis

<<< @/examples/snippets/cb_reversed_r.gp{gnuplot}

<Plot name="cb_reversed_r" svg :width="480" :height="420" />

`set rrange [90:0]` puts 90 at the pole and 0 on the rim: an elevation, the horizon outside. The grid takes its line
style, `lt -1 lw 0.5` black and thin. See [Polar plots](/guide/gnuplot-subset#polar-plots).


### A labelled radial axis and clipped curves

<<< @/examples/snippets/cb_rlabel.gp{gnuplot}

<Plot name="cb_rlabel" svg :width="480" :height="420" />

`set rlabel` names the radial axis, over its middle; a curve leaving the r range is cut at the rim, where
`title ... at beginning|end left|right` puts its name. `set ttics add` places named angles alone. See
[Polar plots](/guide/gnuplot-subset#polar-plots).

### A surface on a polar grid

<<< @/examples/snippets/cb_polar_surface.gp{gnuplot}

<Plot name="cb_polar_surface" svg :width="520" :height="420" />

`set polar grid T,R gauss scale S` and `with surface` weigh scattered theta:r:z points onto a polar grid of T x R
cells, each drawn in the palette color of its value (qnorm, gauss, cauchy, exp or box weights, `kdensity` for
sums), as gnuplot 6.0's polar gridded surfaces. See [Polar plots](/guide/gnuplot-subset#polar-plots).

### Named angles on a polar plot

<<< @/examples/snippets/cb_polar_labels.gp{gnuplot}

<Plot name="cb_polar_labels" svg :width="480" :height="420" />

`set ttics add` names angles (here in radians, with Unicode), `set mttics` adds minor ticks on the polar border and
`set grid r polar 45` draws the rings of the r ticks and spokes every 45 degrees. See
[Polar plots](/guide/gnuplot-subset#polar-plots).


### A band outside a circle

<<< @/examples/snippets/cb_polar_fill.gp{gnuplot}

<Plot name="cb_polar_fill" svg :width="480" :height="420" />

`filledcurves above r=2.5` fills the band between the curve and the circle of radius 2.5 where the curve is outside
it (`below`: inside). See [Polar plots](/guide/gnuplot-subset#polar-plots).

### A log r axis

<<< @/examples/snippets/cb_polar_log.gp{gnuplot}

<Plot name="cb_polar_log" svg :width="480" :height="420" />

`set logscale r` spaces the decades evenly from the pole at the `rrange` start; `impulses` go from the pole and
`set ttics rotate` turns the theta labels along their angle. See [Polar plots](/guide/gnuplot-subset#polar-plots).

### Polar error bars

<<< @/examples/snippets/cb_polar_errorbars.gp{gnuplot}

<Plot name="cb_polar_errorbars" svg :width="560" :height="360" />

On a polar plot `yerrorbars` draw each bar along the radius, from r - dr to r + dr, its caps across it. See
[Polar plots](/guide/gnuplot-subset#polar-plots).

### A level in decibels

<<< @/examples/snippets/cb_polar_db.gp{gnuplot}

<Plot name="cb_polar_db" svg :width="520" :height="400" />

`set rrange [-30:10]` puts -30 dB at the pole, so a negative level is a distance from it, and the points below
-30 dB are left out; `set rtics 10` rings the levels on the r axis (`set raxis`). `set trange` samples the model over
the upper half only, and leaves out the data beyond it too, as gnuplot.

### A wind rose

<<< @/examples/snippets/cb_windrose.gp{gnuplot}

<Plot name="cb_windrose" svg :width="520" :height="420" />

`sectors` draws annular sectors from `azimuth:radius:angle:width`, angles in the `set angles` unit oriented by
`set theta`; on a polar panel they stack into a wind rose (two speed classes, one on top of the other).


### A polar heat map

<<< @/examples/snippets/cb_sectors_heatmap.gp{gnuplot}

<Plot name="cb_sectors_heatmap" svg :width="560" :height="400" />

Each (theta, r) cell of a polar grid is one annular sector, filled from the palette by a value: the last `using`
column with `fc palette` (or `lc palette z`; `lc rgb variable` takes packed colors, `hsv2rgb(h, s, v)` makes them),
on cartesian axes kept round by `set size ratio -1`. See
[Vectors, ellipses, polygons, labels and sectors](/guide/gnuplot-subset#vectors-ellipses-polygons-labels-and-sectors).
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

### Two sets of spider polygons

<<< @/examples/snippets/cb_spider_groups.gp{gnuplot}

<Plot name="cb_spider_groups" svg :width="560" :height="420" />

`newspiderplot` starts a new set of items whose polygons share the axes of the first set; `keyentry with
spiderplot` names a set in the key. A set takes the color and width of its first item. See [Parallel axes and
spider plots](/guide/gnuplot-subset#parallel-axes-and-spider-plots).

### Parallel axes

<<< @/examples/snippets/cb_parallel.gp{gnuplot}

<Plot name="cb_parallel" svg :width="560" :height="320" />

`parallelaxes`: each item is an axis (a column), each row a line across them; `set paxis N range` and `set paxis N tics`
scale and tick each axis. See [Parallel axes and spider plots](/guide/gnuplot-subset#parallel-axes-and-spider-plots).

### Parallel axes with their own ranges

<<< @/examples/snippets/cb_paxis_ranges.gp{gnuplot}

<Plot name="cb_paxis_ranges" svg :width="560" :height="360" />

Each axis has a range (`[350:100]` runs downwards) and ticks of its own; `lc variable` on the first item reads a
second field, here a group number, the color of every line. See
[Parallel axes and spider plots](/guide/gnuplot-subset#parallel-axes-and-spider-plots).

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

### A heatmap of lit levels

<<< @/examples/snippets/cb_image_vfd.gp{gnuplot}

<Plot name="cb_image_vfd" svg :width="560" :height="400" />

An image in the `vfd` theme: the palette mapped to the glow of the display.

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

### From Fortran: fit, stats, times, annotations

`fit` and `stats` work on Fortran arrays as gnuplot's commands on files; `civil_time` makes times for a time axis;
labels, arrows and objects are figure methods.

<<< @/examples/snippets/cb_fortran_tools.f90{fortran}

<Plot name="cb_fortran_tools" svg :width="760" :height="320" />

### From Fortran: run gnuplot commands

`script_object` is the interpreter of the command line: scripts and single commands from the program, with errors
returned, never stopped on.

<<< @/examples/snippets/cb_script-script.f90{fortran}

<Plot name="cb_script" svg :width="560" :height="320" />
