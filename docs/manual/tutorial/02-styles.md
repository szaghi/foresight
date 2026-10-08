---
title: 2. Styles and the key
---

# 2. Styles and the key

Three residuals on one plot must be told apart at a glance — also in grayscale print.

<<< @/examples/snippets/ch2_styles-styles.f90{fortran}

<Plot name="ch2" />

- Each series takes the next color of gnuplot's palette, unless `lc` sets one (any SVG color: `'#e51e10'`, `'red'`).
- `lw` is the line width [px], `dt` the dash type (1 solid, 2–5 dash patterns).
- `with='linespoints'` draws the points on the line; `with='points'` the points only. `pt` picks the point type, as
  gnuplot: 1 plus, 2 cross, 4 square, 6 circle, 8 triangle, … the odd ones from 5 filled; `ps` scales it.
- `it(::8)` plots every 8th iteration: a sparse series reads better with markers.

## The key

`set_key` takes gnuplot's position words: `left`, `right`, `center`, `top`, `bottom`, and `outside` to move it out of
the plot, which shrinks to make room. `box=.true.` draws a frame. `'below'` and `'above'` put the entries in a row under
or over the plot; `set_key(.false.)` hides it. An empty `title` keeps a series out of the key.

::: tip What you learned
Colors, widths, dash types and point types; the key inside or outside the plot. Reference: [Fortran
Library](/guide/library#plot-options), [gnuplot Subset](/guide/gnuplot-subset#point-types).
:::

Next: [3. Axes](./03-axes).
