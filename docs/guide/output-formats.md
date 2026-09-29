---
title: Output Formats
---

# Output Formats

The format follows the output name, in the library (`fig%save(file)`) and in scripts (`set output`):

| Output | Format |
|---|---|
| `*.html`, `*.htm` | interactive page: SVG plus the embedded [viewer](viewer) |
| `*.svg` | static SVG |
| `*.txt` | text, the gnuplot `dumb` terminal |
| `-` | text on the standard output |

In scripts, `set terminal svg|html|dumb` changes the format of the default output (the one derived from the script
name) but never an output set explicitly with `set output`.

## SVG

A standalone SVG document, 600 x 480 px by default (`set terminal svg size W,H`), font Arial/Helvetica 12 px.

- The data of each panel live in a nested `<svg class="fs-plot">` whose `viewBox` is the unit square: coordinates are
  written with 6 decimals of the plot area, and `vector-effect="non-scaling-stroke"` keeps line widths in pixels.
- Panels are `<g class="fs-axes">` groups carrying their geometry and axis ranges as `data-*` attributes; the grid and
  the ticks are the groups `fs-grid`, `fs-xticks`, `fs-yticks`, error bar caps an `fs-caps` overlay. The viewer
  regenerates these; for a static SVG they are ordinary drawing.
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

## Atomic writes

Every file output is written to `<file>.tmp` and renamed over `<file>` when complete (POSIX `rename`), so a browser,
an editor or a copy never sees a partial file.
