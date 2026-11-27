---
title: C5. The paper
---

# C5. The paper

**Goal:** a LaTeX paper whose figures foresight wrote, included as they are.

<<< @/examples/paper/paper.tex{latex}

[paper.pdf](/paper/paper.pdf) is that source compiled: four figures of the previous chapters, two in a column, two
across the page, and two figures whose labels LaTeX sets ([C6](06-labels-set-by-latex)), included by `\input`.

```console
$ bash scripts/docs_examples.sh     # the figures, docs/public/examples/*.pdf
$ bash scripts/build_paper.sh docs/public/paper/paper.pdf
build_paper: docs/public/paper/paper.pdf (lualatex, 2 pages, 17 fonts, all embedded)
```

## Why it works

- Each figure is made at its final size (`size single`, `size double`): `\includegraphics{cb_paper}` takes it without
  `width=`, so its 8 pt texts stay 8 pt, as the captions around it.
- The figures' fonts are embedded (Type 3 fonts of their glyphs): the paper's PDF holds every font it shows, as a
  journal's checker asks. `scripts/build_paper.sh` checks it with `pdffonts`, and checks the log for any warning about
  the figures.
- `theme paper serif` sets the figure texts in Latin Modern Roman, the paper's own font.

## Try this

- `\usepackage{lmodern}` out, `\usepackage{mathptmx}` in (Times): then `theme paper` (sans) suits the figures better
  than `serif`.
- Build it with Tectonic (`tectonic paper.tex`): the CI does (`.github/workflows/paper.yml`).

## Pitfalls

- A figure wider than its column (a 600 px figure is 15.9 cm) overflows it: make it with `size single`, or put it in a
  `figure*`.
- The paper finds the figures through `\graphicspath`: build it where `docs/public/examples` is next to it, as
  `build_paper.sh` does.
