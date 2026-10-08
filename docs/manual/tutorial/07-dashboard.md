---
title: 7. A dashboard
---

# 7. A dashboard

One panel per quantity, side by side: the residuals, and the drag coefficient with its error bars.

<<< @/examples/snippets/dashboard-layout.gp{gnuplot}

<Plot name="ch7" :width="900" :height="440" />

- `set multiplot layout ROWS,COLS` lays out a grid; each `plot` fills the next panel, with the settings in force, so
  `unset logscale y` before the second plot affects that panel only. `unset multiplot` closes it.
- `with yerrorbars` takes a third column, the error: `x:y:dy` (or `x:y:low:high`). `xerrorbars` and `xyerrorbars` work
  the same way. The bar caps keep their size when you zoom.
- In the page, each panel zooms on its own: the pointer picks the panel.

## An inset

Without `layout`, each panel lies in the box of its `set origin` and `set size`, page fractions: a zoom of the last
iterations over the whole history.

<<< @/examples/snippets/inset-inset.gp{gnuplot}

<Plot name="ch7-inset" :width="640" :height="400" />

::: tip What you learned
Multiplot grids and insets, error bars. Reference: [gnuplot Subset](/guide/gnuplot-subset#multiplot); from Fortran,
`set_multiplot` and `next_panel` in the [Fortran Library](/guide/library).
:::

Next: [8. Watching the run](./08-live).
