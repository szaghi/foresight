---
title: Comparison
---

# Comparison

foresight sits between three families of tools: gnuplot and its front ends, which drive an external plotter; Fortran
wrappers of gnuplot or matplotlib; and pure Fortran plotting libraries that write images. Its niche is the combination
none of them covers: pure Fortran, interactive pages that need nothing to view, gnuplot usage, live monitoring.

| | foresight | gnuplot | feedgnuplot | ogpf, gnufor, fplot | pyplot-fortran | fplotlib | fortplot |
|---|---|---|---|---|---|---|---|
| Runtime dependency | none | — | gnuplot, Perl | gnuplot | Python + matplotlib | none | none (ffmpeg for video) |
| Language of the plotter | Fortran | C | gnuplot | gnuplot | Python | Fortran | Fortran |
| Callable from Fortran | yes | no | no | yes | yes | yes | yes |
| gnuplot command language | subset | full | through options | full (through gnuplot) | no | no | no |
| Interactive zoom/pan | self-contained HTML page | own window; HTML page (`canvas` terminal) | gnuplot window | gnuplot window | matplotlib window | no | no |
| Live monitoring of files | `--watch`: reloading pages that keep or follow the view; text redrawn in place | `replot`/`reread` loops | `--stream`, scrolling window (`--xlen`) | no | no | no | no |
| Terminal output | characters, Unicode blocks, Braille, ANSI colors | `dumb`, `block`, sixel graphics | through gnuplot | through gnuplot | no | no | ASCII |
| Static formats | SVG | many | through gnuplot | through gnuplot | through matplotlib | SVG, PNG, PDF, EPS, GIF | PNG, PDF; video through ffmpeg |
| Functions of x (`plot sin(x)`) | yes | yes | yes (`--equation`) | yes | no | no | no |
| Smoothing, histograms | `smooth`, 5 filters | `smooth`, 13 filters; `bins` | through gnuplot | through gnuplot | histograms | histograms | histograms |
| 3D, contours, fitting | no | yes | through gnuplot | through gnuplot | contours, 3D; no fit | contours, 3D axes; no fit | contours, 3D lines; no fit |

The rows on other projects summarise their documentation as of October 2026
([feedgnuplot](https://github.com/dkogan/feedgnuplot), [fplotlib](https://github.com/certik/fplotlib),
[fortplot](https://github.com/lazy-fortran/fortplot), [pyplot-fortran](https://github.com/jacobwilliams/pyplot-fortran),
[fplot](https://github.com/jchristopherson/fplot)); check them for their current state.

## Closest relatives

- **gnuplot's `canvas` terminal** writes an HTML page with mouse zoom, the nearest thing to a foresight page. It needs
  gnuplot to write it, and its helper scripts (`canvastext.js`, `gnuplot_common.js`) next to the page or at a URL
  (`jsdir`); a foresight page is one file, written by the Fortran program itself.
- **feedgnuplot** is the closest to `--watch`: it pipes a stream into gnuplot and redraws it, with a scrolling window
  of the recent past. foresight watches files rather than a pipe — the job writes its log as it would anyway — and the
  viewer's follow mode (`f`) gives the same scrolling window in the page.
- **fplotlib** and **fortplot** are pure Fortran like foresight, with many more plot types and raster output; they
  write images, not interactive pages, and read no gnuplot.

## When to use something else

- **Publication figures** with LaTeX typesetting and fine layout control: pgfplots, matplotlib.
- **Raster output** (PNG) or plot types beyond curves (contours, maps, 3D) from pure Fortran: fplotlib, fortplot.
- **The full gnuplot language** (user functions and variables, `fit`, `splot`, splines): gnuplot itself.
- **Fields on meshes**: ParaView through [VTKFortran](https://github.com/szaghi/VTKFortran).
