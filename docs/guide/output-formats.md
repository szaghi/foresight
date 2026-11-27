---
title: Output Formats
---

# Output Formats

The format follows the output name, in the library (`fig%save(file)`) and in scripts (`set output`):

| Output | Format |
|---|---|
| `*.html`, `*.htm` | interactive page: SVG plus the embedded [viewer](viewer) |
| `*.svg` | static SVG |
| `*.pdf` | PDF, one page |
| `*.txt` | text, the gnuplot `dumb` or `block` terminal |
| `-` | text on the standard output |

In scripts, `set terminal svg|html|dumb|block` changes the format of the default output (the one derived from the
script name) but never an output set explicitly with `set output`.

## Fonts

foresight compiles two font families in, each in four faces (regular, bold, italic, bold italic): their advance
widths, kerning pairs and glyph outlines for Latin (ASCII, Latin-1, Latin Extended-A), Greek, punctuation and math
symbols.

| Family | Stands for | Faces from |
|---|---|---|
| `sans` | the default, `Arial`, `Helvetica`, `sans-serif`, `Liberation Sans`, `Arimo`, and every family foresight does not have | Liberation Sans 2.1.5 (Arial's metrics, as gnuplot's terminals draw by default) |
| `serif` | `serif`, `Latin Modern Roman`, `LM Roman`, `CMU Serif`, `Computer Modern` | Latin Modern Roman 10 (LaTeX's default text font); lowercase Greek and math symbols from Latin Modern Math, as TeX takes them |

A family is chosen by gnuplot's font spec (`set title font "serif,14"`, `font ":Bold"`) or the library's font
settings; the family name is matched without case nor blanks. A character Liberation Sans lacks (a few math symbols)
is taken from Latin Modern of the same style; one no face has counts 0.556 em. Text is measured with kerning, the
pairs the fonts' OpenType tables give. A script naming a family foresight does not have (`font "Times,12"`) is warned
once (`font family "Times" not compiled in: texts measured with the sans face`); the SVG still names the family, so a
reader with that font sees it, in room measured for Liberation Sans.

The font data stays under the fonts' licenses, not foresight's: Liberation Sans under the SIL Open Font License 1.1,
Latin Modern under the GUST Font License (`LICENSES/`). foresight calls its faces `sans` and `serif`: under the OFL a
converted subset may not carry the reserved name *Liberation*. Documents foresight writes are not covered by the font
licenses.

## SVG

A standalone SVG document, 600 x 480 px by default (`set terminal svg size W,H`), font Arial/Helvetica 12 px. The
layout measures every text with the [compiled-in fonts](#fonts): the reader's Arial (or Liberation Sans, which has its
metrics) fills the room exactly.

- The data of each panel live in a nested `<svg class="fs-plot">` whose `viewBox` is the unit square: coordinates are
  written with 6 decimals of the plot area, and `vector-effect="non-scaling-stroke"` keeps line widths in pixels.
- Panels are `<g class="fs-axes">` groups carrying their geometry and axis ranges as `data-*` attributes; the grid and
  the ticks are the groups `fs-grid`, `fs-xticks`, `fs-yticks`, error bar caps an `fs-caps` overlay. The viewer
  regenerates these; for a static SVG they are ordinary drawing. A polar panel adds its grid as `fs-pgrid` in the
  plot area (zoomed with the data) and its r tick labels and theta labels as `fs-polar`, hidden while zoomed. Arrow
  shafts are `fs-vectors` paths, their heads and the text of `labels` the pixel overlays `fs-heads` and `fs-labels`
  (each text carrying its data anchor), redrawn by the viewer after a zoom.
- Each series is a group `fs-series` and its key entry a group `fs-key-entry`, both numbered by `data-series` (from 1,
  in plot order): the viewer hides a series when its entry is clicked.
- All numbers are formatted by integer arithmetic, identically on every compiler: the same figure gives the same
  bytes.
- Texts are written by name (`font-family="Arial,..."`): the reader's fonts draw them, in room measured for the
  compiled-in ones. `set terminal svg fontglyphs` (`fig%set_fontglyphs(svg=.true.)`) draws them from the compiled-in
  glyphs instead, as the PDF: each glyph used defined once (`<path id="fs-g1-36">`, in font units), each character a
  `<use>` of it; the texts stay in the page, transparent, for selection, search and screen readers. The drawing is then
  the same on every machine. HTML pages keep their texts by name: the viewer redraws them.

## PDF

One page of the figure's size, 0.75 pt per pixel (96 px to the inch): a 600 x 480 px figure is 450 x 360 pt.
`set terminal pdfcairo` (or `pdf`) takes gnuplot 6.0's options: a size in inches or with units (`8.5cm,6cm`, or
`single` and `double` for a paper's column and page width), the font and `fontscale`, `linewidth`, `dashlength`,
`rounded`, `mono`, `background`; see [the terminal](gnuplot-subset#set-unset-options) and
[path C](/manual/paths/c-paper/03-sizes-and-the-paper-theme). The
drawing is the SVG's, primitive by primitive: lines with their widths, dashes and joins; filled polygons with their
opacity and gnuplot's fill patterns (tiling patterns of the SVG's 8 px tiles); point type markers, error bar caps and
arrowheads at their pixel size; images as 8-bit RGB with an alpha mask; readouts; texts with gnuplot's enhanced markup.
The plot area is a clipping path; markers crossing its border are drawn whole, as in the SVG.

- Texts are drawn from the [compiled-in fonts](#fonts), embedded: a Type 3 font for each face used (its glyphs'
  outlines, 255 to a font), kerned, with a ToUnicode map, so the text is selectable and searchable and `pdffonts`
  lists every font embedded. Any character of the fonts is there: Latin-1, Latin Extended-A, Greek, math symbols.
  `fig%set_fontglyphs(pdf=.false.)` sets them by name in the 14 standard fonts instead (Helvetica, Times, Symbol for
  gnuplot's `{/Symbol ...}`; WinAnsi encoded: Latin-1 and the typographic quotes, dashes and euro; other characters
  `?`), nothing embedded.
- The file is written in one piece, its content stream uncompressed, without dates nor identifiers: the same figure
  gives the same bytes. `scripts/check_pdf.py` checks every reference PDF of the test suite: `qpdf --check`, every
  font embedded, the text `pdftotext` extracts equal to the SVG's, and the drawing equal to the glyph SVG's of the
  same figure (rasterized, within 0.002 of the fidelity score).
- Left out: what needs a viewer (zoom, hidden series, hypertext) and `set pixmap` images (a PNG file, which PDF cannot
  hold as it is).

## HTML

The SVG document inline in a minimal page, followed by the viewer script. The page loads nothing from the network.
`set terminal html refresh S` (or `fig%set_refresh(S)`) makes it reload itself every `S` seconds; watch mode sets it
automatically. The page title (`<title>`) is the multiplot title, else the title of the first panel, else
`foresight`.

## Text

The layout engine draws on a grid of character cells, 79 x 24 by default (`set terminal dumb size COLS,ROWS`):

- series with gnuplot's symbols `*`, `#`, `$`, `%`, `@`, `&`, `=`, `+`, one per color in order of use;
- the frame with `+`, `-`, `|`, the grid with `.`, superscripts as `^` (`10^-5`);
- [enhanced text](gnuplot-subset#enhanced-text) without its markup (`T_{n-1}` as `Tn-1`, `{/Symbol a}` as `a`);
- error bars as `|` or `-` runs, without caps.

With `ansi`, `ansi256` or `ansirgb` (`set terminal dumb ansi`, as gnuplot) each series is drawn in its color through ANSI
escape sequences: the nearest of the six basic terminal colors, of the 256-color palette, or the color itself. The
frame, the text, and black or white series keep the terminal's own color, readable on a dark or a light background.

```
                             dumb
  1.3+--------+--------+-------+--------+--------+--------+
     |                                           cd****** |
     |                                           |    |   |
  1.2+                                  |    |   |    |   +
     |                         |    |   |    |   |    |   |
  1.1+   #*   |   |    |   |   |    |   |    |   |    |   +
     |   | ***#   |    |   |   |    |   |    |   |    |   |
     |        |***#****#***#***#****#***#****#***#****#***|
    1+            |    |   |   |    |   |    |   |    |   +
```

## Block characters

`set terminal block` (gnuplot 5.4+) draws the same layout with Unicode characters made of dots, for curves smoother
than the symbols of `dumb`: `half` (1 x 2 dots per character), `quadrants` (2 x 2, the default), `sextants` (2 x 3,
Unicode 13 fonts) or `braille` (2 x 4). The text — tick labels, titles, the key — is written over the graphics.

<<< @/examples/output/cb_block.txt{text}

The colors are those of `dumb` (`set terminal block braille ansirgb`); without them, the series are told apart by the
key only, as in gnuplot. A character holds one color, the last series drawn in it. Unlike gnuplot, a character without
dots is a blank (gnuplot writes the empty Braille pattern), so the lines copy and trim as text; points are a dot and
its four neighbours, clipped to the plot area.

## Images

`with image` writes an embedded PNG (8-bit RGBA, uncompressed: a few bytes per pixel, identical bytes for identical
data) with `image-rendering: pixelated`, so a pixel stays a sharp square at any zoom. In text, a character per cell.

## Themes

`set terminal ... theme vfd` (or `lcd`) recolors any output as a 1980s digital dashboard, `theme washi` (or `night`)
in the light (or dark) colors of foresight's identity, `classic` back to gnuplot's: see
[Themes and segmented fills](gnuplot-subset#themes-and-segmented-fills). SVG and HTML take the page, frame, grid and
series colors and, for `vfd`, a glow; text takes the series colors only. `theme paper` makes a figure for a paper:
gnuplot's white page and black frame, the Okabe-Ito colors (distinct for color-blind readers and in gray), 8 pt texts
and 0.75 pt lines; `theme paper serif` sets the texts in Latin Modern Roman. `foresight --theme NAME` sets the theme of
every plot of a run, unless the script sets its own.

The environment variable `FORESIGHT_THEME` names the theme of every new figure, of the library as of the command line,
as gnuplot's `GNUTERM` names a default terminal: a `set_theme`, a `set terminal ... theme` or `--theme` wins over it,
and an unknown name is ignored. This site draws each of its plots twice, with `FORESIGHT_THEME=washi` and `night`.

## Atomic writes

Every file output is written to `<file>.tmp` and renamed over `<file>` when complete (POSIX `rename`), so a browser,
an editor or a copy never sees a partial file.
