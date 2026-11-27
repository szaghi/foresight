---
title: C3. Sizes and the paper theme
---

# C3. Sizes and the paper theme

**Goal:** a figure at the size it is printed, its texts at the size of the paper's captions, without scaling it in
LaTeX (scaling a figure scales its texts and lines).

<<< @/examples/snippets/pc03_paper-gnuplot.gp{gnuplot}

<<< @/examples/snippets/pc03_paper-column.gp{gnuplot}

<Plot name="pc03" svg :width="321" :height="227" />

[pc03.pdf](/examples/pc03.pdf) is 8.5 x 6 cm (240.94 x 170.08 pt), the width of a two-column journal's column:
`\includegraphics{pc03}` takes it at its size, its 8 pt texts as small as the paper's captions. gnuplot's defaults are
in [pc03_default.pdf](/examples/pc03_default.pdf).

<<< @/examples/snippets/pc03_paper-units.gp{gnuplot}

## Why it works

- `set terminal pdfcairo` reads gnuplot 6.0's options: the same script gives the same page with gnuplot and with
  foresight (the fidelity harness compares 20 demo pages drawn both ways, `scripts/fidelity/pdfcairo.py`).
- Sizes take inches by default, or their units: `cm`, `in`, `pt`. `size single` (8.5 x 6 cm) and `size double`
  (17.8 x 8 cm) are foresight's names for a column and the width of a page.
- A font size is in points, times `fontscale` (0.5 by default) and, as cairo draws it, 4/3: gnuplot's `"Sans,12"` is
  8 pt on the page. `theme paper` sets the texts at 8 pt directly, the lines at 0.75 pt and the colors to the Okabe-Ito
  set, which stays distinct for color-blind readers and in gray.

## Try this

- `theme paper serif`: the texts in Latin Modern Roman, the font of the paper itself.
- `mono`: the lines black, told apart by their dashes (`dt 2`, `dt 3`); the fills in gray.

## Pitfalls

- `\includegraphics[width=\linewidth]` rescales the figure: give it its final size here instead and include it as it
  is.
- gnuplot's `fontscale` and the 4/3 apply to `pdfcairo` only; the library's `set_font("Sans,8")` is 8 pt.
