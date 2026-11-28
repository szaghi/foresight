---
title: Comparison
---

# Comparison

foresight sits between three families of tools: gnuplot and its front ends, which drive an external plotter; Fortran
wrappers of gnuplot or matplotlib; and pure Fortran plotting libraries that write images. Its niche is the combination
none of them covers: pure Fortran, interactive pages that need nothing to view, gnuplot usage, live monitoring, and
the figures of a paper or a report from the same script.

| | foresight | gnuplot | feedgnuplot | ogpf, gnufor, fplot | pyplot-fortran | fplotlib | fortplot |
|---|---|---|---|---|---|---|---|
| Runtime dependency | none | — | gnuplot, Perl | gnuplot | Python + matplotlib | none | none (ffmpeg for video) |
| Language of the plotter | Fortran | C | gnuplot | gnuplot | Python | Fortran | Fortran |
| Callable from Fortran | yes | no | no | yes | yes | yes | yes |
| gnuplot command language | subset | full | through options | full (through gnuplot) | no | no | no |
| Interactive zoom/pan | self-contained HTML page | own window; HTML page (`canvas` terminal) | gnuplot window | gnuplot window | matplotlib window | no | no |
| Live monitoring of files | `--watch`: reloading pages that keep or follow the view; text redrawn in place | `replot`/`reread` loops | `--stream`, scrolling window (`--xlen`) | no | no | no | no |
| Terminal output | characters, Unicode blocks, Braille, ANSI colors | `dumb`, `block`, sixel graphics | through gnuplot | through gnuplot | no | no | ASCII |
| Static formats | SVG, PDF (fonts embedded), LaTeX picture (`cairolatex`), text; Markdown tables | many | through gnuplot | through gnuplot | through matplotlib | SVG, PNG, PDF, EPS, GIF | PNG, PDF; video through ffmpeg |
| Text in figures | two embedded families with exact metrics; gnuplot's enhanced text; a TeX-math subset set as LaTeX sets it; LaTeX's own labels through `cairolatex` | system fonts; enhanced text; LaTeX through `epslatex`/`cairolatex` | through gnuplot | through gnuplot | matplotlib's mathtext or LaTeX | its own TeX-math typesetter | its own text rendering |
| Interface | gnuplot's commands, and a Fortran API named after them | gnuplot's commands | command-line options | Fortran calls emitting gnuplot | matplotlib's, from Fortran | matplotlib-style Fortran API | matplotlib-style Fortran API |
| Functions of x (`plot sin(x)`) | yes | yes | yes (`--equation`) | yes | no | no | no |
| 2D plot styles | every gnuplot 2D style (lines to spider plots, heatmaps, polar); pies, gauges, readouts | all | through gnuplot | through gnuplot | through matplotlib | many | many |
| Smoothing, histograms | `smooth`, 11 filters; `bins` | `smooth`, 13 filters; `bins` | through gnuplot | through gnuplot | histograms | histograms | histograms |
| Fitting | `fit`, gnuplot's Marquardt-Levenberg, in scripts and from Fortran | `fit` | through gnuplot | through gnuplot | no | no | no |
| 3D, contours | `splot` in 3D views and the map view: meshes with hidden lines, pm3d surfaces (depth sorted, lit), contours, filled contours, gridded and masked surfaces, error bands, 3D bars, polygons, grid walls; turned by the mouse in the HTML page (a sketch of the plot while turned) | yes | through gnuplot | through gnuplot | contours, 3D | contours, 3D axes | contours, 3D lines |

The rows on other projects summarise their documentation as of October 2026
([feedgnuplot](https://github.com/dkogan/feedgnuplot), [fplotlib](https://github.com/fortran-lang/fplotlib),
[fortplot](https://github.com/lazy-fortran/fortplot), [pyplot-fortran](https://github.com/jacobwilliams/pyplot-fortran),
[fplot](https://github.com/jchristopherson/fplot)); check them for their current state.

## Closest relatives

- **gnuplot's `canvas` terminal** writes an HTML page with mouse zoom, the nearest thing to a foresight page. It needs
  gnuplot to write it, and its helper scripts (`canvastext.js`, `gnuplot_common.js`) next to the page or at a URL
  (`jsdir`); a foresight page is one file, written by the Fortran program itself.
- **feedgnuplot** is the closest to `--watch`: it pipes a stream into gnuplot and redraws it, with a scrolling window
  of the recent past. foresight watches files rather than a pipe — the job writes its log as it would anyway — and the
  viewer's follow mode (`f`) gives the same scrolling window in the page.
- **fplotlib** and **fortplot** are pure Fortran like foresight, with raster output and 3D; they write images, not
  interactive pages, and read no gnuplot.

## foresight or fplotlib

[fplotlib](https://github.com/fortran-lang/fplotlib) (fortran-lang) is the closest project in purpose since foresight
v0.20.0: pure Fortran, figures for papers, TeX math in labels, a Markdown typesetter for reports. The two are siblings,
not alternatives built on each other: foresight depends on no part of it, and borrows its methods (checking a layout
against a reference typesetter, glyph by glyph) rather than its code.

Choose **fplotlib** when you want matplotlib's interface from Fortran (`plot`, `subplots`, axes objects), raster
images (PNG, GIF) or EPS, or when its compilers (gfortran, flang, LFortran) are the ones you build with.

Choose **foresight** when the figures already are, or should be, gnuplot scripts (the same script on the cluster, in
the terminal, in the browser and in the paper); when the paper is LaTeX and its labels should be set by LaTeX
(`cairolatex`); when the run must be watched while it writes its logs; or when the figure should be an interactive
page; foresight builds with gfortran, nvfortran and ifx.

## Layout compared with gnuplot

foresight lays a gnuplot script's page out as gnuplot 6.0 does, and measures how close it gets on gnuplot's own demos
(`scripts/fidelity/`, see [Contributing](contributing#fidelity-to-gnuplot)). The differences left by design:

- **Text widths.** foresight measures every text with the metrics of its compiled-in fonts (advance widths and
  kerning, see [Fonts](output-formats#fonts)); gnuplot's layout estimates a text as its number of characters times a
  character width. Where labels are narrow (`-1`, `1.5`, `σ`), foresight's margins and key boxes are narrower than
  gnuplot's and the plot area wider.
- **Titles.** A panel's title takes gnuplot's room above the plot (a character height, its lines, a character height),
  as do the cells of a multiplot layout under a multiplot title. Panels placed by `set origin` and `set size` under a
  multiplot title start below foresight's title band, not over it as gnuplot draws them.
- **Text devices** keep foresight's rows of character cells for titles and labels.

## When to use something else

- **A figure laid out by TeX itself** (pgfplots' axes in the paper's own layout engine): pgfplots.
- **Raster output** (PNG, GIF) or EPS from pure Fortran: fplotlib, fortplot.
- **The full gnuplot language** (the commands foresight [does not support](gnuplot-subset#not-supported), the
  interactive terminals): gnuplot itself.
- **Fields on meshes**: ParaView through [VTKFortran](https://github.com/szaghi/VTKFortran).
