---
title: Comparison
---

# Comparison

foresight sits between two families of existing tools: Fortran wrappers that drive an external plotter, and pure
Fortran plotting libraries that write static images. Its niche is the combination nobody else covers: pure Fortran,
interactive HTML, gnuplot usage, live monitoring.

| | foresight | gnuplot | ogpf, gnufor, fplot | pyplot-fortran | fplotlib | fortplot |
|---|---|---|---|---|---|---|
| Runtime dependency | none | gnuplot | gnuplot | Python + matplotlib | none | none (core) |
| Language of the plotter | Fortran | C | gnuplot | Python | Fortran | Fortran |
| Interactive zoom/pan | HTML page | own window | gnuplot window | matplotlib window | no | no |
| Live monitoring of files | `--watch` | manual `replot` loops | no | no | no | no |
| gnuplot command language | subset | full | full (through gnuplot) | no | no | no |
| Callable library | yes | no | yes | yes | yes | yes |
| Static formats | SVG, text | many | through gnuplot | through matplotlib | SVG, PNG, PDF, EPS | PNG, PDF, ASCII |
| 3D, fitting, functions | no | yes | yes | yes | partly | partly |

The rows on other projects summarise their documentation at the time foresight was designed
([fplotlib](https://github.com/certik/fplotlib), [fortplot](https://github.com/lazy-fortran/fortplot),
[pyplot-fortran](https://github.com/jacobwilliams/pyplot-fortran), [fplot](https://github.com/jchristopherson/fplot));
check them for their current state.

## When to use something else

- **Publication figures** with LaTeX typesetting and fine layout control: pgfplots, matplotlib.
- **Static raster output** (PNG) from pure Fortran: fplotlib, whose PNG rasteriser and font are compiled in.
- **The full gnuplot language** (functions, `fit`, `splot`, `set format`...): gnuplot itself.
- **Fields on meshes**: ParaView through [VTKFortran](https://github.com/szaghi/VTKFortran).
