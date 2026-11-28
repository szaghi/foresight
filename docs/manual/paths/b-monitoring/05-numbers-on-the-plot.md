---
title: B5. Numbers on the plot
---

# B5. Numbers on the plot

**Goal:** the plot of the run says its result: the converged value with its spread, the restart marked, the window the
value comes from shaded.

<<< @/examples/snippets/pb05_numbers-numbers.gp{gnuplot}

<Plot name="pb05" svg :width="640" :height="380" />

## Why it works

- `stats` computes gnuplot's statistics of a column into variables, `STATS_mean`, `STATS_stddev`, ...;
  `($1 > 100 ? $5 : 1/0)` keeps the last 20 iterations, `1/0` being undefined. `nooutput` keeps the report off the
  terminal.
- `sprintf` writes them into the title, a string expression; it changes with the log under `--watch`.
- An arrow from `graph 0` to `graph 1` spans the plot at an x value; a rectangle `behind` shades a range of
  iterations; both are in axis units, so they move with a zoom in the page.
- A constant (`STATS_mean`) plotted as a function is a horizontal line over the data's x range.

## Try this

- `fit a + b*exp(-x/c) 'run.dat' u 1:5 via a, b, c` and `FIT_STDFIT` in the title: the value the run tends to.
- From Fortran, the same numbers: `stats(cd(101:))` ([Statistics](/guide/library#statistics)).

## Pitfalls

- `every ::100` counts points inside each block of the file: after the restart's blank line, a block starts again at
  0. Select by value, as above, when the file has blocks.
- A mean of a quantity that still oscillates is not a converged value: shade the window you averaged over, as above,
  so the reader can judge.

Reference: [stats](/guide/gnuplot/commands#stats), [labels, arrows and objects](/guide/gnuplot/text#labels-arrows-and-objects).
This is the end of path B: [path D](../d-fields-3d/01-a-field-as-an-image) for fields, [path F](../f-reports/01-a-figure-in-a-report)
for the report of the run.
