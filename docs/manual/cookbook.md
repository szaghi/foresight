---
title: Cookbook
---

# Cookbook

One task per recipe: the script (or program), and the plot it writes. The scripts read the logs of the
[tutorial](./index) solver, `run.dat` and `run.csv`, and a few small files; run any of them with `foresight SCRIPT`.
Every plot here is regenerated from its recipe by `scripts/docs_examples.sh` and checked by the CI.

[[toc]]

## Two columns of a file

<<< @/examples/snippets/cb_columns.gp{gnuplot}

<Plot name="cb_columns" svg :width="560" :height="320" />

## A single column

<<< @/examples/snippets/cb_single_column.gp{gnuplot}

<Plot name="cb_single_column" svg :width="560" :height="320" />

With one column, x is the point number, as `using 0:1`; `using 2` alone does the same for column 2.

## One point every N

<<< @/examples/snippets/cb_every.gp{gnuplot}

<Plot name="cb_every" svg :width="560" :height="320" />

`every I:J:K:L:M:N` is gnuplot's full form: point and block increments, first and last points and blocks.

## One dataset of a file

<<< @/examples/snippets/cb_index.gp{gnuplot}

<Plot name="cb_index" svg :width="560" :height="320" />

Two blank lines separate datasets; `index N` (0-based) picks one.

## Scale and shift columns

<<< @/examples/snippets/cb_expression.gp{gnuplot}

<Plot name="cb_expression" svg :width="560" :height="320" />

A parenthesized field is an expression evaluated per row: `$N` is column N, `$0` the point number.

## Keep only some points

<<< @/examples/snippets/cb_filter.gp{gnuplot}

<Plot name="cb_filter" svg :width="560" :height="320" />

`1/0` is undefined: the point is dropped, a gap in a line.

## CSV with a header row

<<< @/examples/snippets/cb_csv_header.gp{gnuplot}

<Plot name="cb_csv_header" svg :width="560" :height="320" />

Quoted names select columns by header; `title columnhead` titles with the header of the y column. `set key autotitle columnhead` does it for every item.

## A log axis with exponent labels

<<< @/examples/snippets/cb_logscale.gp{gnuplot}

<Plot name="cb_logscale" svg :width="560" :height="320" />

## A reversed axis

<<< @/examples/snippets/cb_reversed.gp{gnuplot}

<Plot name="cb_reversed" svg :width="560" :height="320" />

## Tick steps and label formats

<<< @/examples/snippets/cb_ticks.gp{gnuplot}

<Plot name="cb_ticks" svg :width="560" :height="320" />

On a log axis the step is a factor: `set ytics 10` puts a tick every decade.

## Error bars

<<< @/examples/snippets/cb_errorbars.gp{gnuplot}

<Plot name="cb_errorbars" svg :width="560" :height="320" />

`x:y:dy`, or `x:y:low:high`; the caps keep their size under zoom.

## Error bars on both axes

<<< @/examples/snippets/cb_xyerrorbars.gp{gnuplot}

<Plot name="cb_xyerrorbars" svg :width="560" :height="320" />

`with xyerrorbars` takes `x:y:dx:dy`, or `x:y:xlow:xhigh:ylow:yhigh`.

## Line styles and point types

<<< @/examples/snippets/cb_styles.gp{gnuplot}

<Plot name="cb_styles" svg :width="560" :height="320" />

`set style line N` defines a style once; `ls N` applies it, the options after it override it.

## The key below the plot

<<< @/examples/snippets/cb_key.gp{gnuplot}

<Plot name="cb_key" svg :width="560" :height="320" />

`outside` moves the key to the right margin (or `outside left`, `outside top center`, ...); `below` and `above` lay it out in rows.

## No key

<<< @/examples/snippets/cb_no_key.gp{gnuplot}

<Plot name="cb_no_key" svg :width="560" :height="320" />

`notitle` keeps one item out of the key; `set key noautotitle` all the untitled ones.

## Two y axes

<<< @/examples/snippets/cb_y2.gp{gnuplot}

<Plot name="cb_y2" svg :width="560" :height="320" />

## Functions of x

<<< @/examples/snippets/cb_function.gp{gnuplot}

<Plot name="cb_function" svg :width="560" :height="320" />

Without data, functions are sampled over [-10:10], or the `xrange`; `set samples` sets the number of points.

## A model over the data

<<< @/examples/snippets/cb_model.gp{gnuplot}

<Plot name="cb_model" svg :width="560" :height="320" />

A function is sampled over the x range of the data of the same plot.

## Histogram and distribution

<<< @/examples/snippets/cb_smooth.gp{gnuplot}

<Plot name="cb_smooth" svg :width="560" :height="320" />

`smooth frequency` sums the y of the points of equal x: binned x and y = 1 count the points per bin. `smooth cnormal`
accumulates them over the sorted x, divided by the total: the fraction of iterations below each value. `smooth unique`
averages repeated x instead. See [Smoothing](/guide/gnuplot-subset#smoothing).

## A grid of panels

<<< @/examples/snippets/cb_multiplot.gp{gnuplot}

<Plot name="cb_multiplot" svg :width="560" :height="420" />

## Text in the terminal

<<< @/examples/snippets/cb_dumb.gp{gnuplot}

<<< @/examples/output/cb_dumb.txt{text}

`set terminal dumb` writes to the standard output; `set output 'plot.txt'` to a file.

## Unicode text in the terminal

<<< @/examples/snippets/cb_block.gp{gnuplot}

<<< @/examples/output/cb_block.txt{text}

`block` draws with Unicode characters of 2 x 4 dots (`braille`), 2 x 3 (`sextants`), 2 x 2 (`quadrants`, the default)
or 1 x 2 (`half`). Add `ansi` (or `ansi256`, `ansirgb`) to draw each series in its color, in `dumb` as well.

## A bar chart

<<< @/examples/snippets/cb_boxes.gp{gnuplot}

<Plot name="cb_boxes" svg :width="560" :height="320" />

Boxes stand on y = 0 and the autoscale reaches 0 and the box edges, unlike gnuplot: bar lengths are proportional to
the values. See [Boxes and filled curves](/guide/gnuplot-subset#boxes-and-filled-curves).

## A band around a curve

<<< @/examples/snippets/cb_filledcurves.gp{gnuplot}

<Plot name="cb_filledcurves" svg :width="560" :height="320" />

`x:y1:y2` fills between two columns; `filledcurves y=0` fills down to a line.

## Seven-segment readouts

<<< @/examples/snippets/cb_readout.gp{gnuplot}

<Plot name="cb_readout" svg :width="560" :height="420" />

A foresight extension: the last finite value of each item in seven-segment digits, its glass fixed by the field width
of `format`. A panel of readouts alone fills itself with digits; over a curve they lie in a window, placed as the key.
See [Readouts](/guide/gnuplot-subset#readouts).

<<< @/examples/snippets/cb_readout_dumb.gp{gnuplot}

<<< @/examples/output/cb_readout_dumb.txt{text}

## From Fortran: gaps in the data

NaN values are gaps, as gnuplot's undefined points; `save` writes any of the formats, `-` text on the standard output.

<<< @/examples/snippets/cb_gaps-gaps.f90{fortran}

<Plot name="cb_gaps" svg :width="560" :height="320" />

<<< @/examples/output/cb_gaps.txt{text}

## From Fortran: run gnuplot commands

`script_object` is the interpreter of the command line: scripts and single commands from the program, with errors
returned, never stopped on.

<<< @/examples/snippets/cb_script-script.f90{fortran}

<Plot name="cb_script" svg :width="560" :height="320" />
