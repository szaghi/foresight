---
title: A2. Styles and the key
---

# A2. Styles and the key

**Goal:** three residuals on one plot, told apart at a glance, also printed in gray.

<<< @/examples/snippets/ch2_styles-styles.f90{fortran}

<Plot name="ch2" />

## Why it works

- Each series takes the next of gnuplot's linetype colors, unless `lc` sets one (any SVG color: `'#e51e10'`, `'red'`).
- `lw` is the line width [px], `dt` the dash type (1 solid, 2–5 dash patterns): a dash pattern survives a gray
  printer, a color does not.
- `with='linespoints'` draws the points on the line; `with='points'` the points only. `pt` picks the point type, as
  gnuplot: 1 plus, 2 cross, 4 square, 6 circle, 8 triangle, … the odd ones from 5 filled; `ps` scales it.
- `it(::8)` plots every 8th iteration: a sparse series reads better with markers.

## The key

`set_key` takes gnuplot's position words: `left`, `right`, `center`, `top`, `bottom`, and `outside` to move it out of
the plot, which shrinks to make room. `box=.true.` draws a frame. `'below'` and `'above'` put the entries in a row under
or over the plot; `set_key(.false.)` hides it. An empty `title` keeps a series out of the key.

## Try this

- `with='steps'`: a residual logged once per iteration is a staircase, not a slope.
- `call fig%set_theme('paper')`: the Okabe-Ito colors, distinct for color-blind readers and in gray.
- `call fig%set_key(position='bottom left', box=.true.)`, then `position='outside'`: watch the plot shrink.

## Pitfalls

- A color and a dash type set on one series do not carry to the next: each `plot` call takes its own.
- Past a handful of series a plot stops being readable whatever the styles: split it into panels
  ([A6](./06-two-axes) and the [multiplot](/guide/gnuplot/axes#multiplot)).

Reference: [Fortran Library](/guide/library#plot-options), [point types](/guide/gnuplot/styles#point-types).
Next: [A3. Axes](./03-axes).
