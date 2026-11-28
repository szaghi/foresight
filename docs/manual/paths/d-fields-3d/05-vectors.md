---
title: D5. Vector fields
---

# D5. Vector fields

**Goal:** a velocity field as arrows, the body in the flow drawn as an object.

<<< @/examples/snippets/pd05_vectors-vectors.gp{gnuplot}

<Plot name="pd05" svg :width="600" :height="420" />

`flow.dat` holds `x y u v`, the potential flow past a unit cylinder.

## Why it works

- `with vectors` takes four columns: the tail `x y` and the components `dx dy`; `(2*$3):(2*$4)` scales them so the
  arrows read, in units of the axes.
- `set object circle` draws the cylinder in axis units: it zooms and pans with the data in the HTML page.
- `set size ratio -1`: a unit of x as long as one of y, so the directions are true.

## Try this

- `using 1:2:3:4:(sqrt($3**2+$4**2)) with vectors lc palette`: the arrows colored by the speed.
- `every 2` for a dense field: one arrow in two along each block.
- `set style arrow 1 head filled size 0.08,20` and `with vectors arrowstyle 1`: the head's size and angle.

## Pitfalls

- Arrows of a field that varies over decades are either invisible or overlapping: normalize them
  (`($3/sqrt($3**2+$4**2))`) and color them by the magnitude instead.
- `(2*$3):(2*$4)` scales the arrows in axis units: a field on another scale needs another factor, or arrows that
  overlap their neighbours.

Reference: [vectors](/guide/gnuplot/styles#vectors-ellipses-polygons-labels-and-sectors). Next:
[D6. Voxels and isosurfaces](./06-voxels).
