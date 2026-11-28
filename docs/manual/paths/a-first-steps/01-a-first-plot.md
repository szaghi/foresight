---
title: A1. A first plot
---

# A1. A first plot

**Goal:** the solver holds its residual history in an array: plot it from the program itself, as an interactive page
and as an image.

<<< @/examples/snippets/ch1_first_plot.f90{fortran}

<Plot name="ch1" />

## Building it

```bash
fobis build --mode foresight-static-gnu       # lib/libforesight.a and its modules
gfortran -I lib/mod ch1_first_plot.f90 lib/libforesight.a -o ch1_first_plot
./ch1_first_plot                              # writes ch1.html and ch1.svg
```

`use foresight` gives the whole API and the PENF kinds `I4P`, `R8P`. As a FoBiS or fpm dependency, see
[Installation](/guide/install#as-a-fobis-dependency).

Open `ch1.html`: it needs nothing but a browser, also from a file on a cluster copied to your laptop. The plot above
is that page: wheel to zoom about the pointer (shift: x only, ctrl: y only), drag to pan, right-drag a box, `u` to undo,
`a` to autoscale, `g` for the grid, `h` for help. The static image is the same drawing, for reports and slides:

<Plot name="ch1" svg />

## Why it works

- `figure_object` is a figure: one plot, with gnuplot's defaults (600x480 px, autoscaled axes, the key top right).
  `init` resets it, here with a size.
- `set_title`, `set_xlabel`, `set_ylabel` are gnuplot's `set title`, `set xlabel`, `set ylabel`: every method is named
  after the gnuplot command it does, so the [gnuplot reference](/guide/gnuplot-subset) documents the library too.
- `plot(x, y, title=...)` adds a series; `title` is its entry in the key. Call it again to add more.
- `save` renders the figure; the format follows the extension: `.html` an interactive page, `.svg` a static image of
  the same drawing, `.pdf` a PDF, `.txt` (or `-`, the standard output) text. Ticks and labels are computed by the same
  rules in Fortran and in the page, so a zoom regenerates them as gnuplot would.

## Try this

- `call fig%save('-')`: the plot as text on the terminal, the quickest look over ssh.
- Plot `log10(rho)` instead of `rho`, then go to [A3](./03-axes) for the right way, a log axis.
- Save to `ch1.pdf` and open it: the figure a paper takes ([path C](../c-paper/01-a-first-pdf)).

## Pitfalls

- The arrays of a series must have the same size; the plot keeps a copy, so they can change after the call.
- `init` forgets everything, series and settings: call it once per figure, before the settings.
- A NaN is a gap in the line, not an error: a series full of NaN draws nothing.

Reference: [Fortran Library](/guide/library), [Output Formats](/guide/output-formats),
[Interactive Viewer](/guide/viewer). Next: [A2. Styles and the key](./02-styles).
