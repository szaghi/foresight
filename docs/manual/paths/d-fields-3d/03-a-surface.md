---
title: D3. A surface
---

# D3. A surface

**Goal:** the same field as a surface in 3D, its height the value, seen from an angle.

<<< @/examples/snippets/pd03_surface-surface.gp{gnuplot}

<Plot name="pd03" svg :width="600" :height="420" />

## Why it works

- `splot` reads the grid's blocks as the lines of a mesh: `with lines` draws its two families of grid lines.
- `set view 55, 35` turns the view: the rotation about the x axis, then about the vertical; `set view 60, 30` is
  gnuplot's default.
- `set hidden3d` removes the lines behind the surface, gnuplot's way: the top of the mesh in one color, its underside in
  another.
- `set ticslevel 0` puts the base at the lowest z (gnuplot's default lifts the surface over the base).

## Try this

- `set dgrid3d 30,30 qnorm 2` before plotting scattered points: they are gridded first, then drawn as a surface.
- From Fortran: `call fig%splot(x, y, z)` with a grid, then `set_view` and `set_hidden3d`.
- `set view equal xyz`: the axes at their true lengths.

## Pitfalls

- A file without the blank lines between rows is a cloud of points, not a grid: `splot` then draws lines along the file
  order. Write the blank lines, or grid it with `set dgrid3d`.
- `set hidden3d` needs a grid; it does not apply to scattered points.

Reference: [3D plots](/guide/gnuplot/3d#_3d-plots), [3D views](/guide/gnuplot/3d#_3d-views). Next:
[D4. Colored and lit surfaces](./04-pm3d).
