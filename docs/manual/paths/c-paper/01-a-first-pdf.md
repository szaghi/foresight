---
title: C1. A first PDF
---

# C1. A first PDF

**Goal:** a figure a paper takes as it is, written by foresight itself: no converter, no gnuplot.

<<< @/examples/snippets/pc01_first_pdf-figure.gp{gnuplot}

```console
$ foresight pc01_first_pdf.gp
```

<Plot name="pc01" svg />

The output's extension picks the format: `set output 'pc01.pdf'` in a script, `call fig%save('pc01.pdf')` from Fortran.
[pc01.pdf](/examples/pc01.pdf) is the figure above as a PDF of one page, 600x480 px at 96 px to the inch
(450x360 pt), the size of the SVG.

## Why it works

- The PDF device draws every primitive of the SVG device: lines (dashes, widths, joins), filled polygons with their
  opacity and gnuplot's fill patterns, markers, error bars, arrowheads, images (8-bit RGB with their alpha), readouts,
  and text with gnuplot's enhanced markup (`10^{%L}` above: a superscript placed and sized as in the SVG).
- The layout is the one of every device: texts are measured with the compiled-in fonts' metrics, so the PDF and the
  SVG place every label at the same point.
- The file is written in one piece, uncompressed and without dates: the same figure gives the same bytes, a figure
  under version control changes only when the plot does.

## Try this

- Add `set key bottom left box` and compare the two outputs.
- Write the same figure from Fortran: `call fig%save('residual.pdf')` after the `plot` calls of
  [the first chapter](../../tutorial/01-first-plot).

## Pitfalls

- A PDF shows what is drawn, not the viewer: hidden series, zoom and hover texts are the HTML page's.
- Texts in the 14 standard PDF fonts (Helvetica for the sans faces, Times for the serif ones) cover Latin-1 and the
  Symbol font's Greek; other characters become `?` until the fonts are embedded (the next chapter).
