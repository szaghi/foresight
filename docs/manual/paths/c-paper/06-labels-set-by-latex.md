---
title: C6. Labels set by LaTeX
---

# C6. Labels set by LaTeX

**Goal:** a figure whose texts LaTeX sets, in the paper's own fonts and with its math.

<<< @/examples/snippets/pc06_latex_labels-input.gp

<<< @/examples/output/pc06.txt{console}

`pc06.tex` is a LaTeX picture: its drawing, `pc06.pdf`, has no text, and each label is a `\put` that LaTeX sets
where foresight would have drawn it. A paper includes it with `\input`:

```latex
\usepackage{graphicx}          % in the preamble (and color, for colortext)
...
\begin{figure}
  \centering
  \input{pc06.tex}
  \caption{The response and its envelope.}
\end{figure}
```

## A standalone document

<<< @/examples/snippets/pc06_latex_labels-standalone.gp

`standalone` writes a whole document, the figure alone on a page of its size (`lualatex pc06_standalone.tex` gives
`pc06_standalone.pdf`), its graphics `pc06_standalone-inc.pdf`; `header` adds LaTeX code to its preamble, the font
size (`,10`) chooses its `size10.clo`.

## Why it works

- The file is gnuplot's cairolatex file: the same macros, the same `\put(x,y){\makebox(0,0)[r]{\strut{}...}}`, so a
  document set up for gnuplot's figures (a `gnuplot.cfg`, `\GPblacktextfalse`) takes foresight's unchanged.
- The figure is laid out before LaTeX sets the texts: foresight counts a label's characters as gnuplot does (`$`,
  braces, `_` and `^` none, `\alpha` one) in an 8.8 pt font (`font ",11"` at `fontscale 0.6`, gnuplot's defaults),
  which leaves room for LaTeX's 10 or 11 pt.
- The tick numbers are math (`$-0.5$`): the same digits and minus as the paper's equations.

## Try this

- `colortext`: the texts in their colors (`set label ... textcolor`), when the paper loads `color`.
- `set ylabel '[r]{\shortstack{first \\ second}}'`: a text opening with `[` or `{` is its own box, two lines here.
- `header '\bfseries'` without `standalone`: the figure's texts bold, the paper's untouched.

## Pitfalls

- Texts are LaTeX: `_`, `^`, `%`, `&`, `#` outside math stop LaTeX (`'run_1'` must be `'run\_1'`). Automatic titles
  are escaped for you, as gnuplot does.
- Enhanced text (`{/Symbol a}`, `x^2` outside `$`) is not read: the terminal refuses `enhanced`.
- `\input` reads `pc06.pdf` by the name written in the file, relative to the document: keep the two files together,
  or set `\graphicspath`.
