---
title: D2. Contours
---

# D2. Contours

**Goal:** the levels of the field: lines where it takes chosen values, over its colors.

<<< @/examples/snippets/pd02_contours-contours.gp{gnuplot}

<Plot name="pd02" svg :width="600" :height="420" />

## Why it works

- Contours are a 3D feature in gnuplot: `splot` reads the field as a surface, `set contour base` computes its level
  lines, and `set view map` looks at it from above, the 2D picture.
- `with pm3d` colors the cells by the palette, `with lines nosurface` draws only the contour lines of the second
  item, each level in its own line type, as gnuplot.
- `set cntrparam levels discrete ...` lists the levels; `levels incremental START, STEP, END` and `levels N` (about
  N levels at round values) are the other ways.

## Try this

- `set cntrparam bspline`: smoothed lines.
- `splot ... with contourfill`: bands between the levels instead of lines.
- `set contour both` without `set view map`: the lines on the surface and on the base, in 3D.

## Pitfalls

- The contour lines of a coarse grid are polygons through the cells: refine the grid, not the smoothing, when the
  shape matters.
- A level at exactly a constant value of the field (0 far from the wave here) draws the noise of the round-off: choose
  levels away from it.

Reference: [contours](/guide/gnuplot/3d#contours). Next: [D3. A surface](./03-a-surface).
