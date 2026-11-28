---
title: D6. Voxels and isosurfaces
---

# D6. Voxels and isosurfaces

**Goal:** a 3D scalar field, a value per voxel, shown as the surface where it reaches a level.

<<< @/examples/snippets/pd06_voxels-voxels.gp{gnuplot}

<Plot name="pd06" svg :width="600" :height="420" />

## Why it works

- `set vgrid $helix size 25` makes a grid of 25 x 25 x 25 voxels over `vxrange`, `vyrange`, `vzrange`, all zero.
- `vfill` adds to the voxels around each point of its data: here 200 points along a helix (the sampled pseudo-file
  `'+'`), each filling a sphere of radius 0.9 with the value 10.
- `with isosurface level 1.0` draws the surface where the field crosses 1, marching cubes with gnuplot 6.0's tables, as
  polygons sorted by depth; the transparent fill shows the inside.

## Try this

- `splot $helix with points pt 7 ps 0.3 above 1.0`: the voxels themselves, those above the level.
- `voxel(x, y, z) = ...` in an expression reads the grid: plot a slice with `splot [-2:2][-2:2] voxel(x, y, 5)`.
- A field from a simulation: write it as `x y z value` lines and fill the grid with `vfill 'field3d.dat' using
  1:2:3:(0.0):4`.

## Pitfalls

- The grid's resolution is the surface's: 25 per side is coarse, 100 per side is a million voxels to fill and scan.
- `vfill` adds, it does not set: run it twice and the values double.

Reference: [voxel grids](/guide/gnuplot/3d#voxel-grids). Next: [D7. Turning views](./07-turning-views).
