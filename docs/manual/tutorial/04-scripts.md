---
title: 4. From the log, with a script
---

# 4. From the log, with a script

A real solver writes its history to a log, one line per iteration. Here is the pretend one, writing `run.dat` (with a
restart at iteration 60) and `run.csv`:

::: details solver.f90
<<< @/examples/snippets/solver.f90{fortran}
:::

<<< @/examples/output/solver-head.txt{text}

A gnuplot script plots it, through the `foresight` command line:

<<< @/examples/snippets/residuals.gp{gnuplot}

<<< @/examples/output/ch4.txt{text}

<Plot name="ch4" />

- `using 1:2` plots column 2 against column 1; `using 2` alone plots it against the point number, as `using 0:2`.
- `''` repeats the previous file; abbreviations work as in gnuplot: `u 1:3 w l t 'momentum'`.
- `every 8` keeps one point in 8, in each block.
- The blank line of the restart ends a block: the lines break there, as in gnuplot. Two blank lines would start a new
  dataset, selected with `index`.

## Without a script

`-e` runs commands before the script — or instead of it:

<<< @/examples/output/ch4-e.txt{text}

<Plot name="ch4-e" svg :width="600" :height="480" />

The output defaults to the script name, `residuals.html`; `-o` sets another, and the extension picks the format.

::: tip What you learned
Scripts, data files and the command line; `using`, `every`, `''`. Reference: [Command Line](/guide/cli),
[Data Files](/guide/data-files), [gnuplot Subset](/guide/gnuplot-subset#plot-items).
:::

Next: [5. CSV and expressions](./05-data).
