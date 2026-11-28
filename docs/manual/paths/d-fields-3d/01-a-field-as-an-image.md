---
title: D1. A field as an image
---

# D1. A field as an image

**Goal:** a scalar field of a 2D simulation, one value per grid point, shown as colors with the scale beside it.

<<< @/examples/snippets/pd01_image-image.gp{gnuplot}

<Plot name="pd01" svg :width="600" :height="420" />

`field.dat` holds `x y phi` on a 41 x 31 grid, a block of lines per row of the grid, as most solvers dump a field.

## Why it works

- `with image` draws one rectangle per data point, centred on it, sized by its neighbours: a regular grid becomes
  its cells, with no interpolation that would invent values between the points.
- The third column goes through the palette; the color box beside the plot is its scale, labelled by `set cblabel`.
- `set palette viridis` is one of 46 named palettes: perceptually uniform, readable in gray and by color-blind
  readers. A field with a sign wants a diverging one (`set palette vik`), centred with `set cbrange [-1:1]`.
- `set size ratio -1` makes a unit of x as long as a unit of y: the field keeps its shape.

## Try this

- `set palette vik; set cbrange [-1:1]`: zero in white, the signs in two colors.
- `set logscale cb` for a field over decades (a density, a residual).
- From Fortran: `call fig%image(phi, x, y)`, `phi(column, row)` with the rows upward ([Fortran Library](/guide/library)).

## Pitfalls

- `with image` needs a regular grid. Scattered points want `set dgrid3d` first ([D3](./03-a-surface)), or points
  colored by value: `plot 'f.dat' using 1:2:3 with points pt 7 lc palette`.
- A palette maps the range of the data: two figures compared side by side need the same `set cbrange`.

Reference: [images and palettes](/guide/gnuplot/3d#images-and-palettes). Next: [D2. Contours](./02-contours).
