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
| `h` or `?` | show or hide the help |

The cursor coordinates, in data values, show at the bottom left while the pointer is over a plot (with the y2 value
when the panel has a second y axis). In a multiplot the
mouse acts on the panel under the pointer, keys on the last panel hovered.

## What happens on zoom

The data are never re-plotted: they live in a nested SVG whose coordinates span the unit square, and zooming changes
its `viewBox` only. Line widths stay constant thanks to `vector-effect="non-scaling-stroke"`. What does change is
regenerated:

- **ticks, tick labels and grid** (y2 ticks included), with a line-by-line port of the Fortran tick rules
  (`src/js/viewer.js` mirrors `src/lib/foresight_ticks.F90`), so labels stay exact decimals;
- **error bar caps**, kept at their pixel length in a separate overlay.

Back at the original view (`a`), the ticks written by Fortran are restored exactly.

## State in the URL

Zoom and grid are kept in the page URL, as data values:

```
monitor.html#g=1&x=10,30&y=1e-4,1e-1          first panel
monitor.html#g=0&g1=1&x1=2,6&y1=0.9,1.1       second panel zoomed
```

A reload restores the view, which is what makes live pages usable: when new data change the autoscaled range, the
zoom still shows the same data window. Such a URL can be bookmarked or shared along with the file.

## Limits

- Tick labels regenerated after a zoom can be wider than the margin reserved by Fortran for the original ones.
- Log and linear scales cannot be toggled in the page: the data are written already mapped to the axis scale.
- Points on the border are clipped to the plot area, as matplotlib does (gnuplot shows them whole).
