---
title: F1. A figure in a report
---

# F1. A figure in a report

**Goal:** a figure and the text a report writes around it, the image's alternative text and its caption, from the
program that draws it.

<<< @/examples/snippets/pf01_figure.f90{fortran}

<<< @/examples/output/pf01.txt{console}

<Plot name="pf01" svg :width="600" :height="320" />

`save('pf01.svg', info=meta)` writes the figure and returns a `figure_info`: the file and its format, the size in
pixels and in centimetres, an alternative text and the caption. The last three lines are the figure in a Markdown
report: an image whose alternative text describes it, its caption in italics below.

## Why it works

- The alternative text is made of the texts already in the figure: the title, each axis label, the key titles, as
  sentences (`Plot: Decay. x axis: time [s]. ...`). A screen reader reads it, a renderer shows it when the image is
  missing, a search engine indexes it. A multiplot gives one sentence group per panel (`Panel 2, plot: drag. ...`), a
  3D plot says `Surface plot`.
- `set_caption` (in scripts `set caption "..."`, a foresight extension) is not drawn: a caption belongs to the
  document, below the image or in LaTeX's `\caption`, where the document numbers it.
- The size in centimetres is the page size at 96 px to the inch, the size of the PDF page: what a converter needs to
  print the figure at its size ([F4](04-print-and-web)).

## Try this

- Save to `pf01.pdf` and `pf01.tex`: `meta%format` follows, and for the LaTeX picture `meta%graphics` names the PDF it
  includes.
- Leave out the title: the alternative text starts with `Plot.`; leave out every text and it is `Plot.` alone, a hint
  that the figure needs labels.

## Pitfalls

- gnuplot's enhanced markup is dropped from the alternative text (`c_d` reads `cd`), TeX math is kept as written: a
  screen reader spells `$\alpha$` out. Write the caption for the reader who cannot see the figure.
- `info` is filled by `save`: a figure saved twice returns the second file's information.
