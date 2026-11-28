---
title: A4. From the log, with a script
---

# A4. From the log, with a script

**Goal:** plot the log a solver writes, one line per iteration, with a gnuplot script run by the `foresight` command
line: no program to compile.

Here is the pretend solver, writing `run.dat` (with a restart at iteration 60) and `run.csv`:

::: details solver.f90
<<< @/examples/snippets/solver.f90{fortran}
:::

<<< @/examples/output/solver-head.txt{text}

A gnuplot script plots it:

<<< @/examples/snippets/residuals.gp{gnuplot}

<<< @/examples/output/ch4.txt{text}

<Plot name="ch4" />

`-e` runs commands before the script, or instead of it:

<<< @/examples/output/ch4-e.txt{text}

<Plot name="ch4-e" svg :width="600" :height="480" />

## Why it works

- `using 1:2` plots column 2 against column 1; `using 2` alone plots it against the point number, as `using 0:2`.
- `''` repeats the previous file; abbreviations work as in gnuplot: `u 1:3 w l t 'momentum'`.
- `every 8` keeps one point in 8, in each block.
- The blank line of the restart ends a block: the lines break there, as in gnuplot. Two blank lines would start a new
  dataset, selected with `index`.
- The output defaults to the script name, `residuals.html`; `-o` sets another, and the extension picks the format.
- The command line and the library are one engine: a script is what a program writes through `figure_object` calls,
  line by line.

## Try this

- `foresight residuals.gp -o residuals.txt`: the same plot as text.
- `gnuplot residuals.gp` (with a `set terminal svg` line): the same script runs in gnuplot.
- `plot 'run.dat' index 0 u 1:2`: the restart's first block only, after making its blank line two.

## Pitfalls

- A column that holds text where a number is expected is a missing point, not an error: `set datafile missing` and
  the [data files](/guide/data-files) page explain the rules.
- `every 8` counts inside each block: after the restart the markers start again at its first line.
- Paths in a script are relative to where `foresight` runs, not to the script.

Reference: [Command Line](/guide/cli), [Data Files](/guide/data-files), [plot items](/guide/gnuplot/plot-items).
Next: [A5. CSV and expressions](./05-data).
