---
title: Features
---

# Features

## Plotting

- Styles `lines`, `points`, `linespoints`, `yerrorbars`, `xerrorbars`, `xyerrorbars`
- gnuplot 5 default palette, dash types 1–5, line width and point size per series
- Linear and base-10 logarithmic axes, fixed or autoscaled ends, reversed ranges
- Title, axis labels, grid, key (legend) at the top right as in gnuplot
- Multiplot: a grid of panels with an optional page title
- Missing values (NaN, non-positive values on log axes, `?` cells) break lines instead of corrupting them

## gnuplot semantics

- Autoscaled ends extend outward to the tick grid; an empty range is widened by 1%
- y autoscales on the points inside the x range only
- Error bar ends widen the autoscale
- Data files with comments, blocks (one blank line) and datasets (two blank lines), `using`, `index`, `every`,
  pseudo-column 0
- `set xtics`/`ytics` steps and `set format` printf labels, following the zoom in the viewer; key placement and
  box; `set style data`, `set style line` and `ls`; the full `every`
- Expressions in `using` with gnuplot's rules, integer division and `1/0` gaps included: `u 1:($2*1e3)`,
  `u 1:($3 > 0 ? log10($3) : 1/0)`
- A command subset with gnuplot abbreviations (`u 1:2 w lp t 'x'`), `''` for the previous file, `replot`,
  `set multiplot layout`

## Output

- **HTML**: one self-contained page with an embedded viewer — no network, no external resources
- **SVG**: standalone vector file, the same drawing as the HTML page
- **Text**: the gnuplot `dumb` terminal, to a file or the standard output
- Files are written to `<file>.tmp` and renamed over the target: a viewer never reads half a file

## Interaction (HTML)

- Wheel zoom around the cursor (x or y only with shift or ctrl), drag to pan, right-drag zoom box
- gnuplot hotkeys: `u` undo zoom, `a` autoscale, `g` grid, `h` help
- Live cursor coordinates
- Ticks, grid and error bar caps regenerated after every zoom with the same rules as the Fortran side
- Zoom and grid kept in the page URL, as data values: they survive reloads of a live page

## Monitoring

- `foresight --watch` re-renders whenever the script or a data file it reads changes
- HTML pages reload themselves; the text terminal clears and redraws in place
- Errors in one cycle (a file being rewritten, a typo) are reported and watching goes on

## Engineering

- Pure Fortran 2018; libc `rename` and `nanosleep` through `bind(C)` are the only system services
- Exact tick labels built from integers; compiler-independent number formatting
- Byte-exact golden tests of SVG, HTML and text outputs, in debug and release builds
- Tick generation capped at 1000 ticks, data segments clipped before rasterisation: extreme zooms and outliers
  cannot blow up memory
