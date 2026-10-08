---
title: About foresight
---

# About foresight

**foresight** (FORtran Easy Svg Interactive Gnuplot-like Html Tool) is a Fortran library and command line tool for the
small graphical work that surrounds scientific computing: convergence histories, monitored quantities of a running job,
quick looks at output files. It renders gnuplot-style plots to self-contained interactive HTML pages, static SVG, or
text, and needs nothing but a Fortran compiler.

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

## What it is not

foresight is deliberately scoped. It does not aim at publication figures with LaTeX labels (use pgfplots or
matplotlib), 3D or field visualisation (use ParaView through [VTKFortran](https://github.com/szaghi/VTKFortran)), or
fitting and 3D plots (`fit`, `splot`). Anything outside the supported gnuplot subset is reported as an
error naming the command, never silently ignored.

## Where to start

1. [Install](install) the library and the command line.
2. Follow the [tutorial](/manual/): one solver run, from a first plot to a live dashboard.
3. Look up a task in the [cookbook](/manual/cookbook), a command or method in the [reference](features).

Releases and their changes are in the [changelog](changelog).

## Authors

- Stefano Zaghi — [@szaghi](https://github.com/szaghi)

Contributions are welcome — see the [Contributing](contributing) page.

## Copyrights

foresight is distributed under the [GNU General Public License v3](http://www.gnu.org/licenses/gpl-3.0.html).
