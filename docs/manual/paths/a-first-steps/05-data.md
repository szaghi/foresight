---
title: A5. CSV and expressions
---

# A5. CSV and expressions

**Goal:** read a CSV with a header row, name the columns by their header, and compute new columns while plotting.

Many tools write CSV with a header row, `run.csv` too:

<<< @/examples/output/solver-csv.txt{text}

Tell foresight the separator, and the header names the columns:

<<< @/examples/snippets/coefficients-csv.gp{gnuplot}

<<< @/examples/snippets/coefficients-using.gp{gnuplot}

<Plot name="ch5" />

## Why it works

- `set datafile separator comma` (or `tab`, or any characters `";,"`): every separator ends a cell; an empty cell
  holds no number, so its point is skipped. `unset datafile` goes back to whitespace.
- A quoted name selects a column by its header: `using "iteration":...`, and `column("cd")` inside an expression.
- `set key autotitle columnhead` titles each item with the header of its y column; an explicit `title` still wins.
  Once headers are in use, the first row of each dataset is a header, not a point.
- A parenthesized field is an expression evaluated on each row: `$5` and `column(5)` are column 5, `$0` the point
  number; gnuplot's operators and functions, its integer division included.
- `1/0` is undefined: `($1 > 60 ? $5 * 1e4 : 1/0)` keeps the points after the restart and drops the others.

## Try this

- `using "iteration":(log10(column("continuity")))`: a computed column by name.
- `stats 'run.csv' using "cd"` then `print STATS_mean`: the numbers behind the plot.
- `set table 'cd.md' markdown` before the plot: the same columns as a Markdown table ([F2](../f-reports/02-tables)).

## Pitfalls

- `5/2` is 2 in gnuplot (integer division): write `5.0/2`.
- A header name with blanks needs the quotes of the file (`"wall time"`) and a separator that is not a blank.
- `$5` inside double quotes in a shell `-e` is the shell's variable: quote the command with single quotes.

Reference: [Data Files](/guide/data-files), [column headers](/guide/gnuplot/data#column-headers),
[expressions](/guide/gnuplot/data#expressions-in-using). Next: [A6. Two axes and a model](./06-two-axes).
