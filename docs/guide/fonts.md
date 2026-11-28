---
title: Fonts
---

# Fonts

foresight carries its fonts inside the library. Every text is **measured** with these fonts' exact metrics on every
device, so the layout is the same everywhere. Whether a device also **draws** its texts with them depends on the
device. No system font, no font file and no LaTeX installation is needed.

## In short

| Output | Texts measured with | Texts drawn with |
|---|---|---|
| PDF (`.pdf`, `pdfcairo`) | the compiled-in fonts | the compiled-in fonts, **embedded** (Type 3, with a Unicode map: selectable, searchable) |
| SVG, default (`fontnames`) | the compiled-in fonts | the reader's fonts, by family name (`font-family="Arial,Helvetica,sans-serif"` by default) |
| SVG, `set terminal svg fontglyphs` | the compiled-in fonts | the compiled-in glyphs, each defined once (the same on every machine) |
| HTML page | the compiled-in fonts (the viewer too, for its tick labels) | the browser's fonts, by family name |
| LaTeX picture (`cairolatex`) | the compiled-in fonts, for the layout | **the paper's LaTeX**: its own fonts and math ([LaTeX labels](latex)) |
| Text (`dumb`, `block`) | one character cell | the terminal's font |

For a figure that must look the same everywhere, use PDF or `fontglyphs` SVG. For a web page, the default SVG and
HTML stay light and let the browser draw.

## The two families

foresight compiles two families in, each in four faces (regular, bold, italic, bold italic).

| foresight's name | Is used for | The data comes from |
|---|---|---|
| `sans` (the default) | `sans`, `Arial`, `Helvetica`, `sans-serif`, `Liberation Sans`, `Arimo`, and **every family foresight does not have** | Liberation Sans 2.1.5, with Arial's metrics, the font gnuplot's terminals use by default |
| `serif` | `serif`, `Latin Modern Roman`, `LM Roman`, `CMU Serif`, `Computer Modern` | Latin Modern Roman 10, LaTeX's default text font |

Each face covers Latin (ASCII, Latin-1, Latin Extended-A), Greek, punctuation and the common math symbols, with the
kerning pairs of the fonts' OpenType tables.
- **Serif gaps:** the serif faces take lowercase Greek and some math symbols from Latin Modern Math, as TeX does.
- **Sans gaps:** a character Liberation Sans lacks is taken from Latin Modern in the same style.
- **Neither:** a character no face has (CJK, emoji) takes 0.556 em, is not drawn in a PDF, and stays in the SVG's
  text.

TeX math has its own font, Latin Modern Math, also compiled in ([TeX math in labels](math)).

<Plot name="cb_fonts" svg :width="560" :height="320" caption="a font per text: family, weight, style and size" />

## Choosing a font

In a script, a font is gnuplot's `"family:Bold:Italic,size"`; every part is optional:

```gnuplot
set terminal svg size 640,400 font "serif,11"     # the page's font: every text
set title "Results" font ",16"                    # only a size
set xlabel "time" font ":Italic"                  # only a style
set key font ":Bold"                              # only a weight
set label 1 "peak" at 3, 0.9 font "serif:Bold,12" # a family, a weight and a size
set ylabel "{/serif |H(iω)|} [dB]"                # enhanced text: a family for part of a text
```

From Fortran:

```fortran
call fig%set_font('serif,10')            ! the page's font, as set terminal ... font
call fig%set_theme('paper', serif=.true.) ! a paper's figure in Latin Modern: 8 pt texts, 0.75 pt lines
call fig%set_fontglyphs(svg=.true.)       ! SVG texts drawn from the compiled-in glyphs
```

Fonts apply to:
- the title, the multiplot title and the axis labels;
- the tick labels of each axis and the key;
- `set label`, the data labels, the histogram group titles and the timestamp.

The layout grows with them, as gnuplot's does. The [text reference](/guide/gnuplot/text#fonts) has every rule.

## Sizes

| Output | A size `,N` is | So `"Sans,12"` is |
|---|---|---|
| SVG, HTML | N pixels | 12 px (9 pt in a PDF of the same figure) |
| `pdfcairo` | N points × `fontscale` (0.5 by default) × 4/3, as cairo draws it | 8 pt |
| `cairolatex` | the LaTeX font size, laid out at `fontscale` 0.6 | the paper's size |
| library `set_font` | N points (16 px in an SVG) | 12 pt |

`theme paper` sets 8 pt texts directly: the size of a journal's captions. Give the figure its printed size
(`size single`, `8.5cm,6cm`) rather than scaling it in the document, which scales its texts too
([path C](/manual/paths/c-paper/03-sizes-and-the-paper-theme)).

## A family foresight does not have

`font "Times,12"` is measured and, in a PDF or a `fontglyphs` SVG, drawn in the `sans` face. foresight warns once:

```console
foresight: warning: font family "Times" not compiled in: texts measured with the sans face (Liberation Sans)
```

A default SVG still names `Times` first, so a reader who has it sees it, set in room measured for Liberation Sans;
a wider family may need more room. Use `serif` for a serif text drawn the same everywhere. Font files
(`"/path/font.ttf"`) and gnuplot's `mbfont:` sets keep their size, weight and style; the family is foresight's.

## Licenses

The font data stays under the fonts' licenses: the SIL Open Font License 1.1 (Liberation Sans) and the GUST Font
License (Latin Modern). The figures foresight writes are not covered by them: see [License](license).

## See also

- [C2. Fonts that travel](/manual/paths/c-paper/02-fonts-that-travel): a figure whose fonts a journal's checker finds
  embedded.
- [Output formats](output-formats#pdf): what each device writes.
- [Enhanced text](/guide/gnuplot/text#enhanced-text): sizes and faces inside a text (`{/=8 ...}`, `{/:Bold ...}`).
