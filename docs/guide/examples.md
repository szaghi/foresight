---
title: Examples
---

# Examples

Every image on this page is an actual foresight output: the static SVG, with the interactive HTML page next to it.
The last ones are the reference files of the test suite, compared byte by byte on every run.

## Run monitor: multiplot with error bars

```fortran
program monitor
use foresight, only : figure_object, I4P, R8P
implicit none
type(figure_object)    :: fig
real(R8P), allocatable :: it(:), res(:), cd(:), dcd(:)
integer(I4P)           :: i

it  = [(real(i, R8P), i = 1, 40)]
res = 10.0_R8P**(-0.1_R8P * it)
cd  = 1.0_R8P + 0.2_R8P / it
dcd = 0.05_R8P / sqrt(it)

call fig%init(width=900_I4P, height=380_I4P)
call fig%set_multiplot(1_I4P, 2_I4P, title='Run monitor')
call fig%set_title('residual')
call fig%set_logscale('y')
call fig%set_grid
call fig%plot(it, res, title='continuity')
call fig%next_panel                        ! settings carry over, series do not
call fig%set_title('drag coefficient')
call fig%unset_logscale('y')
call fig%plot(it, cd, title='cd', with='yerrorbars', ylow=cd - dcd, yhigh=cd + dcd)
call fig%save('monitor.html')
endprogram monitor
```

Open [monitor.html](/foresight/examples/monitor.html){target="_self"}: each panel zooms on its own, the error bar caps keep
their size.

## Residuals from a gnuplot script

The script of the [Quick Start](quickstart#a-plot-from-the-shell), rendered by `foresight residuals.gp`:
[residuals.html](/foresight/examples/residuals.html){target="_self"}.

## Test suite references

Two curves, a dashed one, autoscaled axes:

![sin and cos](/examples/lines.svg)

Log y axis with grid; a NaN and a zero residual break the line, a sparse series drawn with linespoints:

![Convergence history on a log axis](/examples/semilogy.svg)

Points on a reversed x range, the y end fixed and its start autoscaled, no key, a label with XML special characters:

![Points on a reversed axis](/examples/points_reversed.svg)

Multiplot with a page title, log and linear panels, error bars —
[interactive version](/foresight/examples/multiplot.html){target="_self"}:

![Two-panel multiplot](/examples/multiplot.svg)

The `dumb` terminal ([dumb.txt](/foresight/examples/dumb.txt){target="_self"}): linespoints and error bars in text.
