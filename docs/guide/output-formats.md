---
title: Output Formats
---

# Output Formats

The format follows the output name, in the library (`fig%save(file)`) and in scripts (`set output`):

| Output | Format |
|---|---|
| `*.html`, `*.htm` | interactive page: SVG plus the embedded [viewer](viewer) |
| `*.svg` | static SVG |
| `*.txt` | text, the gnuplot `dumb` or `block` terminal |
| `-` | text on the standard output |

In scripts, `set terminal svg|html|dumb|block` changes the format of the default output (the one derived from the
script name) but never an output set explicitly with `set output`.

## SVG

A standalone SVG document, 600 x 480 px by default (`set terminal svg size W,H`), font Arial/Helvetica 12 px.

- The data of each panel live in a nested `<svg class="fs-plot">` whose `viewBox` is the unit square: coordinates are
  written with 6 decimals of the plot area, and `vector-effect="non-scaling-stroke"` keeps line widths in pixels.
- Panels are `<g class="fs-axes">` groups carrying their geometry and axis ranges as `data-*` attributes; the grid and
  the ticks are the groups `fs-grid`, `fs-xticks`, `fs-yticks`, error bar caps an `fs-caps` overlay. The viewer
  regenerates these; for a static SVG they are ordinary drawing.
- Each series is a group `fs-series` and its key entry a group `fs-key-entry`, both numbered by `data-series` (from 1,
  in plot order): the viewer hides a series when its entry is clicked.
- All numbers are formatted by integer arithmetic, identically on every compiler: the same figure gives the same
  bytes.

## HTML

The SVG document inline in a minimal page, followed by the viewer script. The page loads nothing from the network.
`set terminal html refresh S` (or `fig%set_refresh(S)`) makes it reload itself every `S` seconds; watch mode sets it
automatically.

## Text

The layout engine draws on a grid of character cells, 79 x 24 by default (`set terminal dumb size COLS,ROWS`):

- series with gnuplot's symbols `*`, `#`, `$`, `%`, `@`, `&`, `=`, `+`, one per color in order of use;
- the frame with `+`, `-`, `|`, the grid with `.`, superscripts as `^` (`10^-5`);
- error bars as `|` or `-` runs, without caps.

With `ansi`, `ansi256` or `ansirgb` (`set terminal dumb ansi`, as gnuplot) each series is drawn in its color through ANSI
escape sequences: the nearest of the six basic terminal colors, of the 256-color palette, or the color itself. The
frame, the text, and black or white series keep the terminal's own color, readable on a dark or a light background.

```
                             dumb
  1.3+--------+--------+-------+--------+--------+--------+
     |                                           cd****** |
     |                                           |    |   |
  1.2+                                  |    |   |    |   +
     |                         |    |   |    |   |    |   |
  1.1+   #*   |   |    |   |   |    |   |    |   |    |   +
     |   | ***#   |    |   |   |    |   |    |   |    |   |
     |        |***#****#***#***#****#***#****#***#****#***|
    1+            |    |   |   |    |   |    |   |    |   +
```

## Block characters

`set terminal block` (gnuplot 5.4+) draws the same layout with Unicode characters made of dots, for curves smoother
than the symbols of `dumb`: `half` (1 x 2 dots per character), `quadrants` (2 x 2, the default), `sextants` (2 x 3,
Unicode 13 fonts) or `braille` (2 x 4). The text — tick labels, titles, the key — is written over the graphics.

<<< @/examples/output/cb_block.txt{text}

The colors are those of `dumb` (`set terminal block braille ansirgb`); without them, the series are told apart by the
key only, as in gnuplot. A character holds one color, the last series drawn in it. Unlike gnuplot, a character without
dots is a blank (gnuplot writes the empty Braille pattern), so the lines copy and trim as text; points are a dot and
its four neighbours, clipped to the plot area.

## Themes

`set terminal ... theme vfd` (or `lcd`, `classic`) recolors any output as a 1980s digital dashboard: see
[Themes and segmented fills](gnuplot-subset#themes-and-segmented-fills). SVG and HTML take the page, frame, grid and
series colors and, for `vfd`, a glow; text takes the series colors only.

## Atomic writes

Every file output is written to `<file>.tmp` and renamed over `<file>` when complete (POSIX `rename`), so a browser,
an editor or a copy never sees a partial file.
