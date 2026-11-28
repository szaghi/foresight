---
title: A6. Two axes and a model
---

# A6. Two axes and a model

**Goal:** the residual (log) and the drag coefficient (linear) on one plot, each on its own scale, and a model
function over the data.

<<< @/examples/snippets/two_axes-axes.gp{gnuplot}

<<< @/examples/snippets/two_axes-plot.gp{gnuplot}

<Plot name="ch6" />

## Why it works

- `axes x1y2` plots an item against the second y axis, autoscaled on its items alone.
- As in gnuplot, the y2 ticks are off until `set y2tics`; `set ytics nomirror` keeps the y ticks off the right
  border. `set y2label`, `set y2range`, `set logscale y2` and `set format y2` work as for y.
- An item that is not a quoted file is a function of `x`, with the operators of `using` expressions. It is sampled
  at `set samples` points (100) over the x range of the data — here the iterations, 1 to 120 — and titled as written.
  Functions are drawn with lines unless `with` or `set style function` say otherwise.

## Try this

- `fit f(x) 'run.dat' u 1:5 via a, b` with `f(x) = a + b*exp(-x/25)`: the model's parameters from the data, then
  `plot ..., f(x) axes x1y2`.
- `set link y2 via y*1e4 inverse y/1e4`: a second axis that is the first one rescaled, gnuplot 6.0's way.

## Pitfalls

- Two axes on one plot are easy to misread: label both, and say in the key which axis a series uses (`cd (right)`).
- A function samples the x range of the data: alone (`plot sin(x)`) it uses `[-10:10]`, gnuplot's default.

Reference: [second y axis](/guide/gnuplot/axes#second-y-axis), [functions](/guide/gnuplot/scripting#functions).
Next: path B, [watching a simulation](../b-monitoring/01-a-dashboard).
