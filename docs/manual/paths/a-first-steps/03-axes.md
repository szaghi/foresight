---
title: A3. Axes
---

# A3. Axes

**Goal:** residuals fall over decades: a linear axis shows the first iterations and flattens the rest. A log axis
shows the whole convergence.

<<< @/examples/snippets/ch3_axes-axes.f90{fortran}

<Plot name="ch3" />

## Why it works

- `set_logscale('y')` is gnuplot's `set logscale y`: base 10; non-positive values become gaps. `'x'`, `'xy'`, `'y2'`
  name other axes; without argument, all.
- `set_grid` draws grid lines at the major ticks (`g` toggles them in the page).
- `set_xrange(min, max)`: an absent end is autoscaled; `min > max` reverses the axis.
- `set_xtics(step=20)`: a tick every 20; `start` and `end` limit them. On a log axis the step is a factor.
- `set_format('%.0e', axes='y')`: the printf format of the tick labels, `%f`, `%e`, `%g`, and gnuplot's `%h`.
- An autoscaled end extends outward to the next tick, as gnuplot: the x axis above runs to 120, a multiple of the
  step, not to the last iteration. A fixed end does not move. Tick labels are exact decimals — `0.3`, never
  `0.30000000000000004` — because they are built from integers, in Fortran and in the page alike.

## Try this

- `set_format('10^{%L}', axes='y')` with `set_enhanced`: the powers of ten as superscripts.
- `set_xrange(min=60.0_R8P)`: the run after the restart only, the upper end still autoscaled.
- `set_logscale('xy')`: both axes logarithmic, the iterations spread over a decade and a bit.

## Pitfalls

- A log axis drops zeros and negative values silently: a residual exactly 0 at convergence leaves a gap.
- A fixed range clips the data outside it; the key still lists the series.
- Ticks too dense? Give a step: the automatic one follows gnuplot's rule, by the range only, not by the page size.

Reference: [ticks and label formats](/guide/gnuplot/axes#ticks-and-label-formats). Next:
[A4. From the log, with a script](./04-scripts).
