---
title: 3. Axes
---

# 3. Axes

Residuals fall over decades: a linear axis shows the first iterations and flattens the rest. A log axis shows the
whole convergence.

<<< @/examples/snippets/ch3_axes-axes.f90{fortran}

<Plot name="ch3" />

- `set_logscale('y')` is gnuplot's `set logscale y`: base 10; non-positive values become gaps. `'x'`, `'xy'`, `'y2'`
  name other axes; without argument, all.
- `set_grid` draws grid lines at the major ticks (`g` toggles them in the page).
- `set_xrange(min, max)`: an absent end is autoscaled; `min > max` reverses the axis.
- `set_xtics(step=20)`: a tick every 20; `start` and `end` limit them. On a log axis the step is a factor.
- `set_format('%.0e', axes='y')`: the printf format of the tick labels, `%f`, `%e`, `%g`, and gnuplot's `%h`.

## Autoscaling, as gnuplot

An autoscaled end extends outward to the next tick: the x axis above runs to 120, a multiple of the step, not to the
last iteration. A fixed end does not move. Tick labels are exact decimals — `0.3`, never `0.30000000000000004` —
because they are built from integers, in Fortran and in the page alike.

::: tip What you learned
Log axes, grid, ranges, tick steps and label formats. Reference: [gnuplot Subset](/guide/gnuplot-subset#ticks-and-label-formats).
:::

Next: [4. From the log, with a script](./04-scripts).
