---
title: 5. CSV and expressions
---

# 5. CSV and expressions

Many tools write CSV with a header row, `run.csv` too:

<<< @/examples/output/solver-csv.txt{text}

Tell foresight the separator, and the header names the columns:

<<< @/examples/snippets/coefficients-csv.gp{gnuplot}

<<< @/examples/snippets/coefficients-using.gp{gnuplot}

<Plot name="ch5" />

- `set datafile separator comma` (or `tab`, or any characters `";,"`): every separator ends a cell; an empty cell is a
  gap. `unset datafile` goes back to whitespace.
- A quoted name selects a column by its header: `using "iteration":...`, and `column("cd")` inside an expression.
- `set key autotitle columnhead` titles each item with the header of its y column; an explicit `title` still wins.
  Once headers are in use, the first row of each dataset is a header, not a point.
- A parenthesized field is an expression evaluated on each row: `$5` and `column(5)` are column 5, `$0` the point
  number; gnuplot's operators and functions, its integer division included.
- `1/0` is undefined: `($1 > 60 ? $5 * 1e4 : 1/0)` keeps the points after the restart and drops the others.

::: tip What you learned
CSV, columns by name, titles from the header, computed columns and filters. Reference: [Data Files](/guide/data-files),
[gnuplot Subset](/guide/gnuplot-subset#column-headers), [expressions](/guide/gnuplot-subset#expressions-in-using).
:::

Next: [6. Two axes and a model](./06-two-axes).
