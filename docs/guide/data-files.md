---
title: Data Files
---

# Data Files

`plot` reads gnuplot's default text format.

```
# iteration  continuity  momentum      <- comment line
1  1.0e-1  2.0e-1
2  8.9e-2  ?                           <- missing cell: a gap
3  7.9e-2  1.6e-1   # trailing comment

4  7.1e-2  1.4e-1                      <- one blank line: new block, the line breaks
5  6.3e-2  1.3e-1


1  5.0e-1  9.0e-1                      <- two blank lines: new dataset (index 1)
2  4.0e-1  8.0e-1
```

| Rule | Behaviour |
|---|---|
| Columns | separated by blanks or tabs |
| `#` | starts a comment anywhere on a line; comment-only lines are neither data nor separators |
| One blank line | ends a block: plotted lines are broken there |
| Two blank lines | end a dataset, selected with `index N` (0-based) |
| `?`, `NaN`, non-numbers | missing values: gaps in the plot |
| Short rows | the missing columns are missing values |
| Column 0 | the number of the point among those plotted in its dataset, from 0 (after `every`, as gnuplot) |
| `every I:J:K:L:M:N` | points `K` to `M` every `I` of each block, blocks `L` to `N` every `J` of each dataset, from 0 |

Values are stored flattened with capacities doubled on growth: a large log costs about one `real(R8P)` per value.

## Monitoring logs

A solver that appends one line per iteration and flushes it is all `--watch` needs:

```fortran
open(newunit=log_unit, file='residuals.dat', status='replace', action='write')
write(log_unit, '(A)') '# iteration  continuity  momentum'
do it = 1, max_it
   ! ... solve ...
   write(log_unit, '(I0,2(1X,ES14.6E3))') it, res_rho, res_mom
   flush(log_unit)
enddo
```

A cycle can read the last line while the solver is still writing it: a truncated cell becomes a missing value, or a
wrong one (`7.9` read from a half-written `7.95e-2`). The completed line changes the file size again, so the next cycle
redraws it correctly.
