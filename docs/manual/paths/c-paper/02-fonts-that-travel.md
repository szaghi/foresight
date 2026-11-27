---
title: C2. Fonts that travel
---

# C2. Fonts that travel

**Goal:** a figure whose labels look the same on every machine and in every viewer, Greek and math included, and
whose fonts a journal's checker finds embedded.

<<< @/examples/snippets/pc02_fonts-figure.gp{gnuplot}

<<< @/examples/snippets/pc02_fonts-svg.gp{gnuplot}

<Plot name="pc02" svg />

[pc02.pdf](/examples/pc02.pdf) holds the same drawing.

## Why it works

- foresight compiles two font families in ([Fonts](/guide/output-formats#fonts)): Liberation Sans (Arial's metrics)
  and Latin Modern Roman (LaTeX's text font), four faces each, with Greek and the common math symbols. Every device
  measures the texts with them.
- The PDF embeds the glyphs it uses: a Type 3 font per face, its glyphs' outlines, a map to Unicode. `pdffonts
  pc02.pdf` lists them all `emb yes`, `uni yes`: the text copies and searches as written (`ζ`, `√`, `≤`).
- `set terminal svg fontglyphs` draws the SVG's texts from the same glyphs: each glyph defined once, each character a
  `<use>` of it, the text kept transparent for selection and screen readers. Without it (`fontnames`, the default) the
  SVG names the family and the reader's fonts draw it, in room measured for Liberation Sans.

## Try this

- `set ylabel "{/serif |H(iω)|}"`: a serif label among sans ones, its glyphs from Latin Modern.
- Remove `fontglyphs` and open the SVG on a machine without Arial: the PDF does not change, the SVG does.

## Pitfalls

- A family foresight does not have (`font "Times,12"`) is drawn in Liberation Sans in the PDF and in the glyph SVG
  (foresight warns once); use `serif` for Latin Modern Roman.
- Characters beyond the compiled-in set (CJK, emoji) take room but draw nothing in the PDF; the transparent text layer
  still holds them.
