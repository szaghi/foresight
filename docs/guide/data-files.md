---
title: Data Files
---

# Data Files

`plot` reads gnuplot's default text format.

```
# iteration  continuity  momentum      <- comment line
1  1.0e-1  2.0e-1
2  8.9e-2  ?                           <- no number: the point is skipped
3  7.9e-2  1.6e-1   # trailing comment

4  7.1e-2  1.4e-1                      <- one blank line: new block, the line breaks
5  6.3e-2  1.3e-1


1  5.0e-1  9.0e-1                      <- two blank lines: new dataset (index 1)
2  4.0e-1  8.0e-1
```

| Rule | Behaviour |
|---|---|
| Columns | separated by blanks or tabs |
| `#` | starts a comment anywhere on a line; comment-only lines are neither data nor separators (`set datafile commentschars`: other characters) |
| One blank line | ends a block: plotted lines are broken there |
| Two blank lines | end a dataset, selected with `index N` (0-based) |
| `?`, words, empty cells | no number: a point that reads one in a plain column (`using 1:2`) is skipped, its line goes on to the next point; through an expression (`using 1:($2)`) it is undefined, a gap that breaks the line, as gnuplot |
| `NaN`, `inf` | numbers, undefined: a gap that breaks the line |
| Numbers | read as gnuplot (C `strtod`): the longest leading number counts, `3abc` is 3, `1.2.3` is 1.2, `1d3` is 1; hexadecimal too, `0x10` is 16; beyond the real range, a gap |
| `"quoted cell"` | one cell, blanks included; not a number |
| Short rows | a plain column beyond the row skips the point, as a cell with no number |
| Column 0 | the number of the point among those plotted in its dataset, from 0 (after `every`, as gnuplot) |
| `every I:J:K:L:M:N` | points `K` to `M` every `I` of each block, blocks `L` to `N` every `J` of each dataset, from 0 |

Values are stored flattened with capacities doubled on growth: a large log costs about one `real(R8P)` per value.

## Separators (CSV)

`set datafile separator` makes other characters separate the cells, as gnuplot:

```gnuplot
set datafile separator comma        # CSV; also "," or ";," (any of the characters)
set datafile separator tab          # or "\t"
set datafile separator              # back to whitespace, as unset datafile
```

```
iteration,residual,cd                  <- a header of words: no numbers, the row is skipped
1, 1.0e-1, 0.52                        <- blanks around cells are ignored
2,8.9e-2,                              <- empty cells, also a trailing one, hold no number
3,"7.9e-2",0.49                        <- a quoted cell is read without its quotes
```

Every separator ends a cell, so two in a row leave an empty one; separators inside double quotes do not count.
Comments, blocks and datasets work as above. A header row is skipped as a row of no numbers (still counted by column
0, as gnuplot counts every row) until an item uses the headers: `using 1:"residual"`, `title columnhead` or `set key autotitle columnhead` make the first row
of each dataset a header, no longer a point (see [Column headers](gnuplot-subset#column-headers)).

## Missing data and comments

`set datafile missing` names the string marking missing data, as gnuplot: a point that reads such a cell, in a plain
column or through an expression (`using 1:($2*1e3)`), is left out and its line goes on to the next point; the same
string in a column the item does not use changes nothing. `set datafile commentschars` sets the characters that start a
comment, on a line of their own or after the data (`#` by default):

```gnuplot
set datafile missing "-"          # a sensor that reports "-" when it has no value
set datafile missing NaN          # NaN cells left out too, instead of breaking the line
set datafile commentschars "#%"   # # and % start comments
unset datafile                    # whitespace, no missing string, # comments
```

Without a missing string, a cell with no number (`?`, `-`, a word) is skipped in a plain column, as above, but undefined
through an expression; the missing string is skipped both ways. `NaN` stays a gap that breaks the line unless it is
the missing string.

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

A cycle can read the last line while the solver is still writing it: a truncated cell holds no number, or a
wrong one (`7.9` read from a half-written `7.95e-2`). The completed line changes the file size again, so the next cycle
redraws it correctly.
