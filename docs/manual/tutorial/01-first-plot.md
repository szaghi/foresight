---
title: 1. A first plot
---

# 1. A first plot

The solver holds its residual history in an array: plot it, from the program itself.

<<< @/examples/snippets/ch1_first_plot.f90{fortran}

<Plot name="ch1" />

- `figure_object` is a figure: one plot, with gnuplot's defaults (600x480 px, autoscaled axes, the key top right).
  `init` resets it, here with a size.
- `set_title`, `set_xlabel`, `set_ylabel` are gnuplot's `set title`, `set xlabel`, `set ylabel`.
- `plot(x, y, title=...)` adds a series; `title` is its entry in the key. Call it again to add more.
- `save` renders the figure; the format follows the extension: `.html` an interactive page, `.svg` a static image of
  the same drawing, `.txt` (or `-`, the standard output) text.

## Building it

```bash
fobis build --mode foresight-static-gnu       # lib/libforesight.a and its modules
gfortran -I lib/mod ch1_first_plot.f90 lib/libforesight.a -o ch1_first_plot
./ch1_first_plot                              # writes ch1.html and ch1.svg
```

`use foresight` gives the whole API and the PENF kinds `I4P`, `R8P`. As a FoBiS dependency, see
[Installation](/guide/install#as-a-fobis-dependency).

## The page

Open `ch1.html`: it needs nothing but a browser, also from a file on a cluster copied to your laptop. The plot above
is that page: wheel to zoom about the pointer (shift: x only, ctrl: y only), drag to pan, right-drag a box, `u` to undo,
`a` to autoscale, `g` for the grid, `h` for help. Ticks and labels are regenerated at every zoom, by the same rules
as the Fortran side.

The static image is the same drawing, for reports and slides:

<Plot name="ch1" svg />

::: tip What you learned
A figure, a series, labels, and two output formats from one `save` call each. Reference: [Fortran
Library](/guide/library), [Output Formats](/guide/output-formats), [Interactive Viewer](/guide/viewer).
:::

Next: [2. Styles and the key](./02-styles).
