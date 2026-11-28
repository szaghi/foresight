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
page; foresight builds with gfortran 16.2+, nvfortran 26.9+ and ifx 2026.2+.

## Layout compared with gnuplot

foresight lays a gnuplot script's page out as gnuplot 6.0 does, and measures how close it gets on gnuplot's own demos
(`scripts/fidelity/`, see [Contributing](contributing#fidelity-to-gnuplot)).

On svg, html, pdf and cairolatex, a 2D panel takes gnuplot's boundary (`boundary.c`) in the character cell of the
terminal the device stands for (`v_char`, `h_char`, `v_tic`, `h_tic`: svg's 1.5 and 0.7 font sizes, the cairo
terminals' line height and digit width of the font): the auto margins, the ticks' lengths, and the places of the
title, the axis labels, the tick labels and the key's rows. With the same plot area (`set lmargin at screen ...`),
every 2D text is within 0.5 px (svg) and 0.1 bp (cairolatex) of gnuplot's, but for the widths below;
`scripts/fidelity/placement.py` checks it on its probes. The differences left by design:

- **Text widths.** foresight measures every text with the metrics of its compiled-in fonts (advance widths and
  kerning, see [Fonts](output-formats#fonts)); gnuplot's layout estimates a text as its number of characters times
  `h_char`. Where gnuplot counts characters, foresight measures: the room of the y tick labels (so the y label's
  place and the left margin), the y2 ones, rotated x tick labels below the plot, and a key's column. Where labels are
  narrow (`-1`, `1.5`, `σ`), foresight's margins and key boxes are narrower than gnuplot's and the plot area wider. A
  key's titles are padded by a character (gnuplot's estimate mostly exceeds a measured title).
- **Baselines.** foresight puts a text's baseline 0.35 font sizes below its centre, gnuplot's svg terminal 0.325:
  0.3 px at 12 px. On cairolatex the `\put` point is the centre itself, exactly gnuplot's.
- **gnuplot's own defect.** In cairolatex gnuplot reads the height of a key's title from an uninitialized variable
  (`estimate_strlen` sets no height for LaTeX terminals): in the build measured, its key rows start at the key's top,
  the title over the first. foresight leaves a line to the title.
- **Fonts.** gnuplot's cairo terminals measure the machine's `Sans` (Noto Sans, DejaVu Sans...), foresight Liberation
  Sans, the font it embeds; the cell, and with it the margins, differ by the fonts' line heights. The fidelity scripts
  run gnuplot with `Sans` aliased to Liberation Sans.
- **Multiplot titles.** The cells of a multiplot layout lie under a multiplot title as gnuplot's; panels placed by
  `set origin` and `set size` under one start below foresight's title band, not over it as gnuplot draws them.
- **Text devices** keep foresight's rows of character cells for titles, labels and keys; 3D views and map views keep
  gnuplot's graph3d layout, polar plots foresight's.

## When to use something else

- **A figure laid out by TeX itself** (pgfplots' axes in the paper's own layout engine): pgfplots.
- **Raster output** (PNG, GIF) or EPS from pure Fortran: fplotlib, fortplot.
- **The full gnuplot language** (the commands foresight [does not support](gnuplot-subset#not-supported), the
  interactive terminals): gnuplot itself.
- **Fields on meshes**: ParaView through [VTKFortran](https://github.com/szaghi/VTKFortran).
