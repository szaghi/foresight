---
title: Interactive Viewer
---

# Interactive Viewer

An HTML page written by foresight is the SVG plot plus a small embedded script. The page is self-contained — no
network, no external files — and works opened straight from the disk.

## Controls

| Input | Action |
|---|---|
| mouse wheel | zoom around the cursor |
| shift + wheel | zoom x only |
| ctrl + wheel | zoom y only |
| left drag | pan |
| right drag | zoom to the box |
| `u` | undo the last box zoom or autoscale |
| `a` | autoscale: back to the original view |
| `g` | toggle the grid |
| click on a key entry | hide or show its series |
| `l` | link or unlink the x zoom of the panels sharing their x axis (linked by default) |
| `f` | follow the end of the data: see [below](#following-a-live-run) |
| `h` or `?` | show or hide the help |

The cursor coordinates, in data values, show at the bottom left while the pointer is over a plot (with the y2 value
when the panel has a second y axis). In a multiplot the mouse acts on the panel under the pointer, keys on the last
panel hovered.

## Hiding a series

A click on an entry of the key hides its series — lines, points, error bars — and dims the entry; another click shows
it again. A series without a title has no entry and stays shown. Hiding does not rescale the axes: a box zoom fits
what remains.

## Linked panels

Panels whose x axis is the same — same range, same scale, as the panels of a dashboard plotting the same iterations
— zoom and pan their x together: a box zoom on the residuals shows the same iterations in the forces panel, each panel
keeping its own y. `u` undoes the zoom on all of them. An inset, with its own x range, stays independent. `l` unlinks
them (and links them again).

## Following a live run

On a page that reloads with new data (`--watch`), zoom to the window you want to watch — the last 200 iterations, say
— and press `f`: the window slides to the end of the x axis, keeping its width, and the y range fits the points shown,
gnuplot's autoscale within the window. At each reload the window moves to the new end of the data: a scrolling view
of the recent past, as `feedgnuplot --xlen`. `f` again stops following; `a` shows the whole run.

## What happens on zoom

The data are never re-plotted: they live in a nested SVG whose coordinates span the unit square, and zooming changes
its `viewBox` only. Line widths stay constant thanks to `vector-effect="non-scaling-stroke"`. What does change is
regenerated:

- **ticks, tick labels and grid** (y2 ticks included), with a line-by-line port of the Fortran tick rules
  (`src/js/viewer.js` mirrors `src/lib/foresight_ticks.F90`), so labels stay exact decimals;
- **error bar caps** and **point type markers** (`pt`), kept at their pixel size in separate overlays.

Back at the original view (`a`), the ticks written by Fortran are restored exactly.

## State in the URL

Zoom, grid and hidden series are kept in the page URL, as data values:

```
monitor.html#g=1&x=10,30&y=1e-4,1e-1          first panel
monitor.html#g=0&g1=1&x1=2,6&y1=0.9,1.1       second panel zoomed
monitor.html#f=1&g=0&x=900,1000&y=1e-6,1e-3   following the end of the data
monitor.html#g=0&s=2,3                        series 2 and 3 hidden (numbered in plot order, from 1)
monitor.html#l=0&g=0&g1=0                     panels zoomed independently
```

A reload restores the view, which is what makes live pages usable: when new data change the autoscaled range, the
zoom still shows the same data window. Such a URL can be bookmarked or shared along with the file.

## Limits

- Tick labels regenerated after a zoom can be wider than the margin reserved by Fortran for the original ones.
- Log and linear scales cannot be toggled in the page: the data are written already mapped to the axis scale.
- Points on the border are clipped to the plot area, as matplotlib does (gnuplot shows them whole).
- Hiding a series does not rescale the axes, and following fits y to every shown series of the panel, on either y
  axis.
