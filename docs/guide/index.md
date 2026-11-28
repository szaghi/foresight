---
title: About foresight
---

# About foresight

**foresight** (FORtran Easy Svg Interactive Gnuplot-like Html Tool) is a Fortran library and command line tool for the
graphical work that surrounds scientific computing, from the first look at a run to the figures of its paper:
convergence histories, monitored quantities of a running job, quick looks at output files, benchmark charts, and the
figures and tables of papers and reports. It renders gnuplot's plot styles (curves, bars, box plots, heatmaps, vector
fields, polar and spider plots, `splot`'s 3D views) and dashboard charts (readouts, gauges, pies) to self-contained
interactive HTML pages, SVG, PDF with embedded fonts, LaTeX pictures (gnuplot's `cairolatex`) and text, and needs
nothing but a Fortran compiler.

## Why

That grey zone between computing and visualisation is usually covered by Python, gnuplot or MATLAB. Each brings its
own runtime into a workflow that is otherwise pure Fortran: a Python environment to maintain on every cluster, a
gnuplot build with the right terminals, glue scripts in a second language. foresight takes the opposite path:

- **the plotting core is Fortran**: data never leaves the language, the solver can plot directly, and the build is
  one more FoBiS mode;
- **the browser is the viewer**: every workstation already has one, and an HTML page with an embedded script gives
  zoom and pan without any GUI toolkit;
- **the command language is gnuplot's**: a subset, interpreted by the library, so existing habits and many existing
  scripts carry over.

## Papers and reports

A figure goes into a paper or a report with no post-processing:

- **PDF** written by foresight itself, gnuplot's `pdfcairo` syntax and sizes, the fonts embedded (Liberation Sans,
  Latin Modern Roman) and measured with their exact metrics on every device, a `paper` theme for a journal's column
  ([path C](/manual/paths/c-paper/01-a-first-pdf));
- **LaTeX labels**: gnuplot's `cairolatex`, the drawing as a PDF and every text a `\put` the paper's LaTeX sets
  ([C6](/manual/paths/c-paper/06-labels-set-by-latex));
- **TeX math in labels** (`$\frac{t}{\tau}$`), set as LaTeX sets it in Latin Modern Math, in every format, the HTML
  page and the terminal included ([C7](/manual/paths/c-paper/07-math-in-labels));
- **Reports**: `save` returns what a document needs (the size, an alternative text, the caption), and tables are written
  as Markdown ([path F](/manual/paths/f-reports/01-a-figure-in-a-report)).

## What it is not

foresight is deliberately scoped. It is not a typesetter: display math, matrices and line breaking in labels are
LaTeX's (through `cairolatex`), a report's layout is its renderer's. It writes no raster images (PNG) and no EPS, has
no journal presets and no CMYK. It is not 3D field visualisation (volume rendering, large meshes: use ParaView through
[VTKFortran](https://github.com/szaghi/VTKFortran)); its 3D views are gnuplot's `splot`, drawn as gnuplot draws them,
an HTML page turning them with the mouse as a sketch. Anything outside the supported gnuplot subset is reported as an
error naming the command, never silently ignored.

## Where to start

1. [Install](install) the library and the command line.
2. Follow a [learning path](/manual/): path A from a first plot to scripts, then the one of your job.
3. Look up a task in the [cookbook](/manual/cookbook), a command or method in the [reference](features).

Releases and their changes are in the [changelog](changelog).

## Authors

- Stefano Zaghi — [@szaghi](https://github.com/szaghi)

Contributions are welcome — see the [Contributing](contributing) page.

## Copyrights

foresight is distributed under a multi-licensing system:

- **FOSS projects**: [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html)
- **Closed source / commercial**: [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause), [BSD 3-Clause](http://opensource.org/licenses/BSD-3-Clause), or [MIT](http://opensource.org/licenses/MIT)
