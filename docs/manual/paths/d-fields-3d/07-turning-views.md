---
title: D7. Turning views
---

# D7. Turning views

**Goal:** a 3D plot you turn with the mouse, in a page that needs nothing but a browser.

<<< @/examples/snippets/pd07_views-views.gp{gnuplot}

<Plot name="pd07" :width="640" :height="440" />

Drag in the plot above: a vertical drag turns it about x, a horizontal one about z, and the bottom left corner shows
`view: X, Z`, the `set view X, Z` that draws it. `u` goes back to the script's view.

## Why it works

- The HTML page carries the plot's 3D scene with the drawing: the box, the tick labels, the lines, points and pm3d
  quadrangles in their colors. The viewer projects them with gnuplot's transform, as foresight does (at the script's
  view they land on the drawing within 0.01 px), and paints them farthest first.
- The angles are gnuplot's `set view`: type the ones the corner shows into the script to save the view you chose.
- The same page zooms the 2D plots ([A1](../a-first-steps/01-a-first-plot)): one viewer for every figure.

## Try this

- Turn the plot until the peak faces you, read the view in the corner, and set it in the script.
- Save the same script to SVG and PDF: the static figures at the view of `set view`.

## Pitfalls

- A turned view is a sketch: no hidden lines (`set hidden3d`), no contours on the base, no annotations, and the tick
  labels stay at their places of the script's view. The script's view is the exact one.
- Map views (`set view map`) do not turn, and a static output (SVG, PDF) cannot: choose the view in the page, then set
  it in the script.

Reference: [3D views](/guide/gnuplot/3d#_3d-views), [Interactive Viewer](/guide/viewer). This is the end of
path D: [path E](../e-gnuplot/01-running-a-script) is for gnuplot users, the [cookbook](../../cookbook#_3d-plots) has
one recipe per 3D task.
