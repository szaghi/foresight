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
| left drag | pan; on a 3D view, turn it (see [below](#turning-a-3d-view)) |
| right drag | zoom to the box |
| `u` | undo the last box zoom or autoscale; on a turned 3D view, back to the script's view |
| `a` | autoscale: back to the original view |
| `g` | toggle the grid |
| click on a key entry | hide or show its series |
| `l` | link or unlink the x zoom of the panels sharing their x axis (linked by default) |
| `f` | follow the end of the data: see [below](#following-a-live-run) |
| `h` or `?` | show or hide the help |

The cursor coordinates, in data values, show at the bottom left while the pointer is over a plot (with the y2 and x2
values when the panel has those axes; a date and time on a [time axis](/guide/gnuplot/data#time-data)). Shortcuts are
ignored while Ctrl, Meta or Alt is held, and the right-click menu is replaced by the box zoom. The wheel zoom and the
drag pan are not recorded for `u` (box zooms and `a` are). A reload waits while a drag is in progress. In a multiplot the mouse acts on the panel under the pointer, keys on the last
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

- **ticks, tick labels and grid** (y2 and x2 ticks included), with a line-by-line port of the Fortran tick rules
  (`src/js/viewer.js` mirrors `src/lib/foresight_ticks.F90`), so labels stay exact decimals; on time axes the time
  steps and the labels (two-line ones included) by the same rules as the Fortran side; text labels from the data
  (`xtic`, `x2tic`, `ytic`, `y2tic`) kept at their values; the minor ticks of `set mxtics time` are not redrawn.
  The labels are measured as the Fortran side measures them: the page carries the advance widths of the
  [compiled-in fonts](output-formats#fonts) for the characters 32-126 and 160-255 and the kerning of their ASCII
  pairs (11 kB), and each redrawn label records its width (`data-width`) in the axis' face;
- **error bar caps**, **point type markers** (`pt`), **arrowheads** of `vectors` and `arrows`, and the texts of `with
  labels`, kept at their pixel size in separate overlays;
- what does not follow the data is hidden while zoomed and shown again by `a`: the r and theta labels of a polar
  panel, the titles of histogram groups (`newhistogram`), and the [labels and arrows](/guide/gnuplot/text#labels-arrows-and-objects)
  placed at axis values (objects at axis values are data geometry and zoom with it); readouts and gauges are left
  alone.
Here as an image; written as an HTML page (`set terminal html` and `set output 'cb_annotations.html'` in the recipe) the wheel
zooms about the pointer, a right drag zooms on a box, `a` goes back.
pointer, a right drag zooms on a box, `a` goes back.

<Plot name="cb_annotations" svg :width="640" :height="400" />

The animation below shows what the viewer regenerates: the same data at narrower and narrower x windows, each frame
rendered by foresight with the ticks the viewer computes (exact decimals at every scale).

<Plot name="anim_zoom" svg :width="640" :height="320" caption="ticks regenerated while zooming (an animation)" />

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

## Turning a 3D view

A 3D view (`splot`, not `set view map`) turns with a left drag, as gnuplot's interactive terminals: a vertical drag
changes the rotation about x, 360 degrees a page height (up: larger), a horizontal one the rotation about z, 360
degrees a page width (right: smaller), both whole degrees in [0, 360). The bottom left corner shows `view: X, Z`,
the `set view X, Z` that draws it. `u` goes back to the script's view.

The page carries the view's scene (a `<metadata class="fs-scene">` in the panel): the base of the box, the z axis, the
tick labels, the lines and points of the series and the pm3d quadrangles in their colors, in the box's normalized
coordinates. The viewer projects them as foresight does (gnuplot's transform; at the script's view they land on
foresight's drawing within 0.01 px) and paints them farthest first. A turned view is a sketch of the plot: it has no
hidden-line removal (`set hidden3d`), no contours on the base, no annotations, and its tick labels stay at their
places of the script's view; the title, the key and the color box keep their places. The page itself, the SVG file
and the text devices draw the script's view only. Map views (`set view map`) zoom as 2D panels do not: they stay as
drawn.

## Limits

- Tick labels regenerated after a zoom can be wider than the margin reserved by Fortran for the original ones.
- The viewer measures characters beyond Latin-1 (Greek, math symbols) as 0.556 em and kerns ASCII pairs only; a
  label with them is drawn right, its recorded width may differ from the Fortran one.
- Log and linear scales cannot be toggled in the page: the data are written already mapped to the axis scale.
- Points on the border are clipped to the plot area, as matplotlib does (gnuplot shows them whole).
- Hiding a series does not rescale the axes, and following fits y to every shown series of the panel, on either y
  axis.
