---
title: F4. Print and web
---

# F4. Print and web

**Goal:** the same figure on the report's web page, as SVG, and in its printed version, as PDF at the size it is
printed.

<<< @/examples/snippets/pf04_print-two.f90{fortran}

<<< @/examples/output/pf04.txt{console}

<Plot name="pf04" svg :width="321" :height="227" />

[pf04.pdf](/examples/pf04.pdf) is 8.5 x 6 cm. The printed report names it with pandoc's attribute
`{width=8.50cm}`, from `print%width_cm`: `pandoc pf04_print.md -o pf04_print.pdf` prints it at its size, its 8 pt
texts unscaled.

## Why it works

- One figure, saved twice: the layout is the same on every device (the texts measured with the same font metrics), so
  the web and the printed figures say the same thing at the same places.
- `set_page_size(8.5, 6.0, 'cm')` gives the figure its printed size; the SVG is that size in CSS pixels (96 to the
  inch), the PDF in points. `width_cm` reads it back for the document.
- The PDF embeds its fonts: a converter, a printer and a journal's checker find them.

## Try this

- `set_page_size(17.8_R8P, 8.0_R8P, 'cm')`, a page-wide figure, and `{width=17.80cm}` follows.
- A third save to `pf04.html`: the interactive page for a web report, its zoom and hover.

## Pitfalls

- Markdown has no size for images: the `{width=...}` attribute is pandoc's (VitePress reads it too), GitHub shows it as text.
- Do not scale a figure to fit (`{width=100%}`): its texts and lines scale with it. Give it the size it is printed at.
