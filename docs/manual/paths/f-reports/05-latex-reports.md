---
title: F5. LaTeX reports
---

# F5. LaTeX reports

**Goal:** a report in LaTeX written by a program: each figure a LaTeX picture whose texts the report sets, in a figure
environment the program writes with its caption.

<<< @/examples/snippets/pf05_latex-environment.f90{fortran}

<<< @/examples/output/pf05.txt{console}

<Plot name="pf05" svg :width="321" :height="227" />

`pf05.tex` is the picture of [C6](../c-paper/06-labels-set-by-latex) (gnuplot's cairolatex): its drawing
[pf05.pdf](/examples/pf05.pdf), its labels `\put`s LaTeX sets in the report's fonts, `$Re$` and `$C_f$` in its math.
`pf05_figure.tex` is the environment around it; the report's main file `\input`s it where the figure goes.

## Why it works

- `meta%file` is the picture to `\input`, `meta%graphics` the PDF it includes (`pf05.pdf`): a build script copies both.
- The caption and the label come from the program, the numbering from LaTeX: `Figure~\ref{fig:friction}` stays right
  when figures move.
- The alternative text goes in as a comment, kept with the figure for whoever edits the report.

## Try this

- `call fig%set_cairolatex(standalone=.true.)`: `pf05.tex` becomes a whole document, compiled on its own to a PDF
  figure with the report's fonts (graphics `pf05-inc.pdf`, in `meta%graphics`).
- Write one fragment per figure and a `figures.tex` that inputs them in order.

## Pitfalls

- The picture needs `\usepackage{graphicx,color}` in the report's preamble ([C6](../c-paper/06-labels-set-by-latex)).
- A caption is LaTeX: escape `%`, `&`, `_` and `#` in it, or write it in math.
