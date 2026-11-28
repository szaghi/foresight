---
title: B1. A dashboard
---

# B1. A dashboard

**Goal:** one panel per quantity of the run, side by side: the residuals, and the drag coefficient with its error
bars; then an inset that zooms on the last iterations.

<<< @/examples/snippets/dashboard-layout.gp{gnuplot}

<Plot name="ch7" :width="900" :height="440" />

Without `layout`, each panel lies in the box of its `set origin` and `set size`, page fractions: a zoom of the last
iterations over the whole history.

<<< @/examples/snippets/inset-inset.gp{gnuplot}

<Plot name="ch7-inset" :width="640" :height="400" />

## Why it works

- `set multiplot layout ROWS,COLS` lays out a grid; each `plot` fills the next panel, with the settings in force, so
  `unset logscale y` before the second plot affects that panel only. `unset multiplot` closes it.
- `with yerrorbars` takes a third column, the error: `x:y:dy` (or `x:y:low:high`). `xerrorbars` and `xyerrorbars` work
  the same way. The bar caps keep their size when you zoom.
- In the page, the pointer picks the panel. Both panels plot iterations 0 to 120, so they share their x axis: a zoom on
  one shows the same iterations on the other, each keeping its own y (`l` unlinks them). Try a box zoom (right drag)
  on the residuals.
- From Fortran, `set_multiplot(rows, cols)` and `next_panel` do the same ([Fortran Library](/guide/library#multiplot)).

## Try this

- `set multiplot layout 2,1 columnsfirst`: the panels stacked, the x axes aligned under each other.
- `set multiplot layout 1,2 margins 0.1,0.95,0.15,0.9 spacing 0.08`: the plot areas lined up whatever the tick labels.
- An inset with `set object 1 rectangle from screen 0.5,0.5 to screen 0.95,0.9 fc rgb 'white' behind` under it: a
  clean box.

## Pitfalls

- Settings carry over from panel to panel, as in gnuplot: undo what the previous panel set (`unset logscale y`).
- Panels placed with `set origin` and `set size` under a multiplot title start below the title band, not over it as
  gnuplot draws them (a [documented difference](/guide/comparison#layout-compared-with-gnuplot)).

Reference: [multiplot](/guide/gnuplot/axes#multiplot), [error bars](/guide/gnuplot/plot-items#plot-items).
Next: [B2. Watching the run](./02-watching-the-run).
