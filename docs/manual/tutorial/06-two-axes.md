---
title: 6. Two axes and a model
---

# 6. Two axes and a model

The residual (log) and the drag coefficient (linear) on one plot: each needs its own scale. The second y axis, on
the right, gives it — and a model function lies over the data.

<<< @/examples/snippets/two_axes-axes.gp{gnuplot}

<<< @/examples/snippets/two_axes-plot.gp{gnuplot}

<Plot name="ch6" />

- `axes x1y2` plots an item against the second y axis, autoscaled on its items alone.
- As in gnuplot, the y2 ticks are off until `set y2tics`; `set ytics nomirror` keeps the y ticks off the right
  border. `set y2label`, `set y2range`, `set logscale y2` and `set format y2` work as for y.
- An item that is not a quoted file is a function of `x`, with the operators of `using` expressions. It is sampled
  at `set samples` points (100) over the x range of the data — here the iterations, 1 to 120 — and titled as written.
  Functions are drawn with lines unless `with` or `set style function` say otherwise.

::: tip What you learned
A second y axis and model functions over data. Reference: [gnuplot Subset](/guide/gnuplot-subset#second-y-axis),
[Functions](/guide/gnuplot-subset#functions).
:::

Next: [7. A dashboard](./07-dashboard).
