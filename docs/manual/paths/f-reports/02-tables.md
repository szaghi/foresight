---
title: F2. Tables
---

# F2. Tables

**Goal:** the numbers behind a figure as tables a Markdown renderer shows, written by the script that plots them.

<<< @/examples/snippets/pf02_tables-tables.gp{gnuplot}

<<< @/examples/snippets/pf02_tables-plot-table.gp{gnuplot}

<<< @/examples/output/pf02.txt{console}

Rendered, the first table is:

| case | cells | error | time |
| --- | --: | --: | --: |
| coarse | 1000 | 0.032 | 0.4 |
| medium | 8000 | 0.0081 | 2.9 |
| fine | 64000 | 0.002 | 23.5 |
| finest | 512000 | 0.00051 | 190.2 |

and the figure the same script draws from the same file:

<Plot name="pf02" svg :width="600" :height="320" />

## Why it works

- `set table 'FILE' markdown` writes the tables of the plots that follow as Markdown pipe tables, the tables of
  GitHub, GitLab, pandoc and VitePress (whose markdown-it parses them back into the same cells in foresight's tests).
  `with table markdown` does it for one item.
- The header is the data's: with `set datafile columnheaders` a field that reads a column whole (`'cells'`,
  `strcol(1)`, `2`) takes its column's name; another field is named as written (`($3*1e3)`).
- Numbers are right aligned, texts left aligned, as a reader compares them. A `|` in a cell is escaped.
- A plot's table (any style but `table`) is the points foresight draws, a table per series after its title, the
  numbers in the axis formats: `set format y '%.2e'` above.

## Try this

- `using 'cells':(sprintf('%.1f s', $4))`: a formatted column, its header the field as written.
- `set table $T markdown` writes into a datablock: `print $T` shows it.
- Append to an open report: `set table 'report.md' append markdown` ([F3](03-the-report)).

## Pitfalls

- A table of `with table` writes numbers as `%g` (gnuplot's): `set format` applies to a plot's table only. Format
  with `sprintf` in the `using` field.
- A computed field is named as written: put the quantity in the data file, with its name, when the header matters.
- `splot` tables stay gnuplot's text: `markdown` refuses them.
