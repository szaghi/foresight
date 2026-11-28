---
title: LaTeX labels (cairolatex)
---

# LaTeX labels (cairolatex)

For a LaTeX paper, foresight can leave the texts to the paper itself. `set terminal cairolatex` (gnuplot's terminal)
writes two files:

- the drawing as a PDF without its texts;
- a LaTeX picture that places every text where foresight laid it out.

The paper's LaTeX then sets the labels in its own fonts and sizes, with its own math and macros.

## TeX math or LaTeX labels?

| | [TeX math in labels](math) | LaTeX labels (`cairolatex`) |
|---|---|---|
| Who sets the texts | foresight, with LaTeX's rules | the paper's LaTeX |
| Fonts | Liberation Sans or Latin Modern, compiled in | the paper's, whatever they are |
| Math | the [subset](math#what-is-set), inline | all of LaTeX: display style, matrices, your macros |
| Formats | SVG, HTML, PDF, text | a PDF and a `.tex`, for LaTeX documents only |
| Needs LaTeX | no | yes, to see the figure |
| Best for | web pages, slides, reports, PDF figures for any journal | a LaTeX paper whose figures should match its text exactly |

Both measure the layout with foresight's fonts: the same script gives the same figure, the texts set by one or the
other.

## In a script

```gnuplot
set terminal cairolatex pdf input size 8.5cm,6cm
set output 'gain.tex'                       # writes gain.tex and gain.pdf
set xlabel '$\omega/\omega_0$'              # LaTeX source: math between $
set ylabel 'gain [\si{dB}]'                 # any macro the paper defines
plot ... title '$\zeta = 0.1$'
```

From Fortran:

```fortran
call fig%set_cairolatex(standalone=.false.)
call fig%save('gain.tex', info=meta)   ! meta%graphics is 'gain.pdf'
```

## In the paper

```latex
\usepackage{graphicx,color}   % in the preamble: gnuplot's picture defines a color
...
\begin{figure}
  \centering
  \input{gain.tex}            % reads gain.pdf, next to it
  \caption{The gain.}
\end{figure}
```

The [example paper](/paper/paper.pdf) includes two such figures (its Figures 5 and 6); the CI builds it with
Tectonic.

## Options

The options are gnuplot 6.0's:
- **graphics:** `pdf`, the only format (`eps` and `png` are refused);
- **document:** `input` (the default) or `standalone`, a whole document whose graphics are `NAME-inc.pdf`;
- **text colors:** `blacktext` (the default) or `colortext`;
- **LaTeX code:** `header "..."`;
- **font:** `font "name,size"`, a LaTeX font name and the size the layout uses (11 pt by default, laid out at
  `fontscale` 0.6);
- **from pdfcairo:** `size`, `fontscale`, `linewidth`, `dashlength`, `rounded` and `mono`.

The file is gnuplot's own, its macros written verbatim, so a document set up for gnuplot's cairolatex figures takes
foresight's unchanged. The tests check that every `\put` lands within 0.1 bp of the same text in foresight's SVG of
the figure.

## Rules

- Texts are LaTeX source, not gnuplot's enhanced text: `_`, `^`, `%`, `&`, `#` outside math must be escaped
  (`'run\_1'`); automatic titles are escaped for you.
- Tick numbers are written in math (`$-0.5$`), as gnuplot's.
- Keep `NAME.tex` and `NAME.pdf` together, or set `\graphicspath`.
- Positions are gnuplot's: with the same plot area every `\put` is within 0.1 bp of gnuplot's own, except where
  gnuplot counts characters for a width (the y label beside the tick labels, a key's column:
  [layout compared with gnuplot](comparison#layout-compared-with-gnuplot)). gnuplot measures the machine's `Sans`,
  foresight Liberation Sans: margins follow the fonts' line heights.

## See also

- [C6. Labels set by LaTeX](/manual/paths/c-paper/06-labels-set-by-latex): a figure, a standalone document, pitfalls.
- [Output formats](output-formats#latex-pictures-cairolatex): every detail of the file.
- [F5. LaTeX reports](/manual/paths/f-reports/05-latex-reports): figure environments written by a program.
