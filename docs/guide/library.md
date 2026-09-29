---
title: Fortran Library
---

# Fortran Library

`use foresight` gives two types: `figure_object`, a figure driven by methods that mirror gnuplot commands, and
`script_object`, the interpreter of gnuplot scripts. The PENF kinds `I4P`, `I8P`, `R4P`, `R8P` are re-exported: real
data are `real(R8P)`, integer arguments `integer(I4P)`.

## A figure

```fortran
type(figure_object) :: fig

call fig%set_title('Residuals')
call fig%set_logscale('y')
call fig%plot(it, res, title='continuity')
call fig%save('residuals.html')
```

A fresh `figure_object` needs no initialisation. `init` resets it to the gnuplot defaults, optionally resizing:
600 x 480 px, 12 px font.

### Methods

| Method | gnuplot equivalent |
|---|---|
| `init([width], [height], [font_size])` | `reset`, `set terminal ... size` |
| `plot(x, y, [title], [with], [lc], [lw], [dt], [ps], [xlow], [xhigh], [ylow], [yhigh])` | one item of `plot` |
| `clear()` | the replacement done by a new `plot` |
| `save(file)` | `set output` + render |
| `set_title(title)`, `set_xlabel(label)`, `set_ylabel(label)` | `set title`, `set xlabel`, `set ylabel` |
| `set_xrange([min], [max])`, `set_yrange([min], [max])` | `set xrange [min:max]` |
| `set_logscale([axes])`, `unset_logscale([axes])` | `set logscale`, `unset logscale` |
| `set_grid([on])`, `set_key([on])` | `set grid`, `unset key` |
| `set_multiplot(rows, cols, [title])`, `next_panel()`, `unset_multiplot()` | `set multiplot layout` |
| `set_refresh(seconds)` | reload period of the HTML page |

### `plot` options

| Argument | Meaning | Default |
|---|---|---|
| `title` | key entry; empty for none | none |
| `with` | `lines`, `points`, `linespoints`, `yerrorbars`, `xerrorbars`, `xyerrorbars` (or `l`, `p`, `lp`, `yerr`, `xerr`, `xyerr`) | `lines` |
| `lc` | color, any SVG color (`'#e51e10'`, `'red'`) | gnuplot palette, by series |
| `lw` | line width [px] | 1 |
| `dt` | dash type 1..5 | 1 (solid) |
| `ps` | point size factor | 1 |
| `ylow`, `yhigh` | vertical error bar ends, for `yerrorbars`, `xyerrorbars` | — |
| `xlow`, `xhigh` | horizontal error bar ends, for `xerrorbars`, `xyerrorbars` | — |

`x` and `y` may contain NaN: those points, and non-positive values on log axes, are gaps in the line.

```fortran
call fig%plot(x, y, title='measured', with='yerrorbars', ylow=y - dy, yhigh=y + dy)
call fig%plot(x, fit, title='model', lc='black', dt=2_I4P)
```

### Ranges

As gnuplot `set xrange [min:max]`: an absent end is autoscaled, and an autoscaled end extends outward to the next
tick. `min > max` reverses the axis.

```fortran
call fig%set_xrange(min=10.0_R8P, max=0.0_R8P)   ! reversed
call fig%set_yrange(max=1.0_R8P)                 ! top fixed, bottom autoscaled
call fig%set_xrange()                            ! back to full autoscale
```

### Multiplot

`set_multiplot(rows, cols, title)` lays out a grid filled row by row, starting from the first panel. Settings and
plots apply to the current panel; `next_panel` moves on, carrying the settings over (not the series), as gnuplot does.
Panels never plotted stay blank.

```fortran
call fig%set_multiplot(1_I4P, 2_I4P, title='Run monitor')
call fig%set_title('residual')
call fig%set_logscale('y')
call fig%plot(it, res)
call fig%next_panel
call fig%set_title('drag coefficient')
call fig%unset_logscale('y')
call fig%plot(it, cd)
```

### Output

`save` picks the format from the file name: `.svg` static vector, `.html`/`.htm` interactive page, `.txt` text, `-`
text on the standard output. See [Output Formats](output-formats).

## Scripts from Fortran

`script_object` runs gnuplot-subset scripts, the same interpreter the command line uses. Errors are returned, never
stopped on:

```fortran
type(script_object)           :: gp
character(len=:), allocatable :: iomsg
integer(I4P)                  :: iostat

call gp%init('monitor.html')                    ! default output
call gp%run_file('monitor.gp', iostat, iomsg)
if (iostat /= 0) print '(A)', iomsg              ! e.g. monitor.gp:7: unsupported command "splot"
call gp%execute('replot', iostat, iomsg)        ! one statement
```

| Procedure | Purpose |
|---|---|
| `init(output)` | reset; plots go to `output` until `set output` |
| `run_file(file, iostat, iomsg)` | run a script file |
| `run_text(text, iostat, iomsg, [source])` | run script text, `source` names it in messages |
| `execute(statement, iostat, iomsg)` | run one statement |

After a run, `gp%output` is the current output file, and `gp%data_files(k)%text`, for `k` up to
`size(gp%data_files)`, are the data files read.

## Errors

The figure API stops with `error stop` on programming errors: `x` and `y` of different sizes, an unsupported
style, error bar styles without their bounds, a log axis over a non-positive fixed range, a full multiplot layout.
The interpreter instead reports every error through `iostat`/`iomsg`.
