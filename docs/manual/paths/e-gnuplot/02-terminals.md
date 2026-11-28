---
title: E2. Terminals and outputs
---

# E2. Terminals and outputs

**Goal:** the outputs foresight writes, through gnuplot's terminals: the same plot as an image, a page, a PDF and text.

<<< @/examples/snippets/pe02_terminals-terminals.gp{gnuplot}

<<< @/examples/output/pe02.txt{console}

<Plot name="pe02" svg :width="600" :height="320" />

[pe02.pdf](/examples/pe02.pdf), [pe02.html](/examples/pe02.html).

## Why it works

| gnuplot's terminal | foresight writes |
|---|---|
| `svg` | SVG, its texts by font name or drawn from the compiled-in glyphs (`fontglyphs`) |
| `pdfcairo`, `pdf` | PDF with its fonts embedded ([path C](../c-paper/01-a-first-pdf)) |
| `cairolatex` | a LaTeX picture and its PDF ([C6](../c-paper/06-labels-set-by-latex)) |
| `dumb`, `block` | text, with characters or Unicode blocks, in ANSI colors if asked |
| `html` (foresight's) | an interactive page: zoom, pan, hover, hidden series, live reload |
| `canvas`, `pngcairo`, `png`, `qt`, `wxt`, `x11`, `epslatex`, `postscript` | not available: an error naming the terminal |

- The options are gnuplot's (`size`, `font`, `linewidth`, `dashlength`, `rounded`, `standalone`, ...); `theme NAME` is
  foresight's.
- `replot` draws the last plot again on the new terminal and output, gnuplot's way of writing several formats.
- The layout is the same on every device: texts are measured with the fonts' metrics, so the SVG, the PDF and the page
  place every label at the same point.

## Try this

- `set terminal svg fontglyphs`: the SVG draws its texts from the embedded glyphs, the same on every machine.
- `set terminal block braille ansi`: the plot in Braille dots, colored, for a terminal over ssh.

## Pitfalls

- `set output` without `set terminal` picks the format from the extension in foresight, not in gnuplot: name the
  terminal for a script that runs in both.
- A PNG is not written: raster output is out of foresight's scope; convert an SVG or a PDF if a raster is needed.

Reference: [Output Formats](/guide/output-formats). Next: [E3. What foresight adds](./03-extensions).
