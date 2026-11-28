---
title: Text and fonts
---

# Text and fonts

Labels, arrows and objects; fonts, gnuplot's enhanced text and TeX math. Part of the [gnuplot subset](/guide/gnuplot-subset) reference.

## Labels, arrows and objects

```gnuplot
set label 1 'peak' at pi/2, 1 point pt 7 offset 1,0
set label 'mean' at graph 0.5, first 0.2 center front tc rgb '#b3163f'
set arrow from 3,-0.2 to 4.6,-0.9                            # gnuplot's default head: two barbs
set arrow 2 from 3,0.2 rto 1.6,0.6 heads filled lw 2 lc rgb '#9400d3'
set arrow from graph 0.05,0.1 to graph 0.25,0.1 nohead dt 2 front
set object 1 rect from 4, graph 0 to 6, graph 1 fc rgb '#56b4e9' fs solid 0.25 noborder behind
set object circle at 2,-0.5 size 0.6 fc '#e69f00' fs solid 0.5 border
set object ellipse at 7,-0.6 size 1.6,0.5 angle 30
set object polygon from 0.5,0.6 to 1.5,0.6 to 1,0.95 to 0.5,0.6 fc lt 2 fs solid 0.6 front
unset label 1; unset arrow                                   # one tag, or all
```

<Plot name="cb_annotations" svg :width="640" :height="400" />

A position is `x, y`, each coordinate in its system: `first` (the values of the x and y axes, the default), `second`
(the x2, y2 axes), `graph` (fractions of the plot area from its bottom left), `screen` (fractions of the page) or
`character` (character cells from the bottom left of the page, gnuplot's svg cell: 0.7 of the font size wide and 1.5
high, the cell of the label offsets too); a label with a point has its text moved right and up by half the point
(gnuplot's pointsize times half a tick); the system of x is also y's unless y names one
(`graph 0.5, first 3`); the systems take gnuplot's abbreviations (`fir`, `sec`, `gr`, `sc`, `char`). A coordinate is a constant expression, or a time string on a [time axis](/guide/gnuplot/data#time-data).

| Command | Options (gnuplot 6.0's, defaults first) |
|---|---|
| `set label [N] ["text"] [at POS]` | a text on several lines (`"a\nb"`) one below the other, the first at the position; a third (3D) coordinate of POS read and ignored; `left`\|`center`\|`right`, `norotate`\|`rotate [by A]`, `back`\|`front`, `tc`/`textcolor` `rgb "c"`\|`"c"`\|`lt N`\|`default`\|`palette z`\|`palette cb V`\|`palette frac F` (the palette color of the label's z, of a value or of a fraction, over the color axis: when no item sets it, the extent of the plotted heights, not extended to ticks, as gnuplot), `nopoint`\|`point [pt N] [ps S]`, `offset X,Y` (characters; each coordinate may name its system, the second in the first's unless given, as gnuplot: `offset graph 0.1, 0.1` fractions of the plot area, `screen` of the page, `first`, `second` axis units from 0; in 3D views `first` and `graph` offsets projected through the view, gnuplot's map3d_position_r, which refuses them mixed with `screen` or `character` ones), `font "f"` (its [font](#fonts)), `noenhanced` |
| `set arrow [N] from POS to\|rto POS\|length [SYS] L angle A` | `as N`/`arrowstyle N` (the look of `set style arrow N`, the options after it applied on it), `head`\|`nohead`\|`backhead`\|`heads`, `size [SYS] L,A` (head length in x axis values, or graph, screen, character; barb angle [deg]); `length L angle A` the tip from the tail, the length along x in its system (negative: backwards), the angle on the page, `nofilled` (two barbs)\|`filled`\|`empty`\|`noborder`, `back`\|`front`, `lc`, `lt`, `lw`, `dt` |
| `set style arrow N [default]` | the arrow options above but the position: the look of the arrows `as N`; `unset style arrow` forgets them |
| `set object [N] rectangle from POS to\|rto POS` \| `rectangle center\|at POS size W,H` | `fc`/`fillcolor`, `fs`/`fillstyle` (as `set style fill`, `border lc C` included), `lw`, `dt` (a dashed border), `back`\|`front`\|`behind`, `clip`\|`noclip`, `default`; a rectangle in the page color (`fc bgnd`) with a black border, as gnuplot, or in the look of `set style rectangle` |
| `set style rectangle` | `fc`, `fs`, `lw`, `dt`: the look of the rectangles set next (their layer is not taken, as gnuplot 6.0) |
| `set object [N] circle [at POS] size R [arc [A:B]]` | as rectangle; empty with a black border; `R` in x axis values (round on the page), `radius R` the same, an arc a wedge from the centre |
| `set object [N] ellipse [at POS] size W,H [angle A]` | as circle; the axes in the units of x and y, turned by `A` in those units (gnuplot's `units xy`) |
| `set object [N] polygon from POS to POS to POS ...` | as circle; in a [3D view](/guide/gnuplot/3d#_3d-views) `depthorder` sorts it with the pm3d quadrangles (`set pm3d depthorder`), `fc ls N` colors its back in line style N+1's; options without vertices change an existing one (or are accepted, nothing drawn) |
| `set pixmap N "file.png"\|colormap NAME [at POS] [size W,H \| width W \| height H] [center]` | a PNG image, gnuplot 6.0's (`colormap NAME`: a column of the 256 colors of a `set colormap new NAME`, the first on top, a row from the left when more than twice as wide as high, gnuplot's colorbox of a named palette): `at` its lower left corner (`center` its centre), its own pixels without a size, `width` or `height` alone the other side by its aspect; W, H in any system (`first` by default, `char` cells); `behind`, `back`, `front` (the default) its layer; `unset pixmap N`, `unset pixmaps`. PNG only (gnuplot also reads JPEG and GIF); the SVG holds the file, text devices draw nothing |

`N` is a tag: an existing one is replaced, or changed when no position is given (`set object 3 fc rgb "red"`), as
gnuplot; without it the next free tag. `rto` is relative to the previous point. Layers: `back` behind the data,
`front` over the frame and the data, `behind` (objects) behind the grid too. Labels and arrows are not clipped, as
gnuplot's; objects are clipped by the plot area (`noclip` lets them out), as gnuplot's. Objects whose points are all
axis values are data geometry: the HTML page zooms them with the data; labels and arrows at axis values are hidden
while zoomed, shown again by `a`, those in graph and screen coordinates stay in place. Text devices draw labels upright
and fill objects with characters.

```gnuplot
set style arrow 1 head filled size screen 0.02,15 lc rgb '#b3163f' lw 2
set arrow from 1,1 to 4,4 as 1                      # the style
set arrow from 1,4 to 4,1 as 1 lc rgb '#0072b2'     # the style, another color
set style rectangle fc rgb '#fff3b0' fs solid border lc rgb '#e69f00'
set object rect from 5,1 to 7,3                     # in the rectangle style
set object circle at 8,8 size 1 dt 3                # a dotted border
set label 'note' at character 2, 1                  # 2 cells from the left, 1 up from the bottom of the page
```

<Plot name="cb_arrow_styles" svg :width="560" :height="360" />

`set label ... boxed [bs N]`, `with labels boxed [bs N]` (and `set title ... boxed`, `set style histogram ... title
boxed`) draw the text on the background when the
[textbox style](/guide/gnuplot/commands#set-unset-options) `N` (0 by default) is opaque or has a border, as gnuplot's svg terminal (a filter
flooding the text's bounding box; no border, no margin). An arrow takes `fill` for `filled` and `ls N` (the color, width and dashes of line style N).

Not supported: `boxed` on axis labels, `hypertext`, `set style circle|ellipse`, `units xx|yy`.

## Fonts

```gnuplot
set terminal svg size 640,400 font "Georgia,11"   # the page's font: every text
set title "Results" font ",20"                    # a size
set xlabel "time" font ":Italic"                  # a style
set ytics font ",8"                               # the tick labels of an axis (set tics font: every axis)
set key font ":Bold"                              # a weight
set label 1 "peak" at 3, 0.9 font "Times:Bold,14" # a family, a weight and a size
plot 'run.dat' using 1:2:3 with labels font ",8"  # data labels
```

A font is gnuplot's `"family:Bold:Italic,size"`, each part optional, as gnuplot 6.0's svg terminal: the size in pixels
(`",8"`), `:Bold` and `:Italic` (or ` bold`, ` italic`), the family (`"serif"`, `"Times"`, `"Lucida Sans"`). Fonts
apply to the title, the multiplot title, the axis labels (x, y, x2, y2, r, cb), the tick labels of each axis (theta's
too), the key, `set label`, the data labels, the histogram group titles, the timestamp and the page (`set terminal ... font`, `set termoption font`). The layout grows as
gnuplot's: the title, the multiplot title and the x2 label take rows of their size, the key its size; the tick labels
and the other axis labels are placed as the page's text, only their glyphs change. A family is written to the SVG as
given, the page's after it as fallback: the reader's fonts draw it, while foresight measures every text with its
[compiled-in fonts](../output-formats#fonts) (Liberation Sans for the sans families and every family it does not have,
warned once; Latin Modern Roman for the serif ones), so a family wider than those may need room. The PDF, and the SVG
with `set terminal svg fontglyphs`, draw the texts from those fonts' glyphs. Font files (`"/path/a.ttf"`) and gnuplot's
`mbfont:` sets name no family an SVG can use: their size, weight and style are kept. Text devices keep their one
cell. Within a text, [enhanced text](#enhanced-text) changes the size and the style of a part (`{/=8 ...}`,
`{/:Bold ...}`).

## Enhanced text

Titles, axis labels, key entries, labels and tick labels read gnuplot's enhanced text markup, on by default as in
gnuplot's svg terminal:

```gnuplot
set title "{/:Bold Decay} of u(t) = u_0 e^{-t/{/Symbol t}}"
set ylabel "u / u_0"
set label 2 "run_07/u_probe.dat" at 2.3,-0.45 noenhanced    # as it is
plot exp(-x) t "e^{-t/{/Symbol t}}"
```

<Plot name="cb_enhanced" svg :width="560" :height="340" />

| Markup | Meaning |
|---|---|
| `x^2`, `x^{n+1}` | superscript: 0.8 of the size, raised half the current size |
| `x_i`, `x_{i,j}` | subscript: 0.8 of the size, lowered 0.3 of it; nested ones apply again |
| `{...}` | a group: the operand of `^ _ @ & ~`, the extent of a font |
| `{/Symbol a}` | the Symbol font: the Latin letters as the Greek ones (`a` α, `b` β, `c` χ, `p` π, `t` τ, `W` Ω, ...), the characters 160-255 (Latin-1, an octal byte with `set encoding iso_8859_1`) as its symbols (`\362` ∫, `\245` ∞, `\256` →, Adobe's encoding) |
| `\U+hhhh` | the character of that code point (its hex digits read greedily, as gnuplot) |
| `{/=16 B}`, `{/*1.5 B}` | an absolute size (points, the base is 12) or a relative one |
| `{/:Bold B}`, `{/:Italic I}`, `{/Helvetica:Italic t}` | weight, style, family |
| `@` | the next element takes no room: `x@^2_i` stacks the superscript over the subscript |
| `&{text}` | the text invisible, its room kept |
| `~a{.8-}` | overprint: the second element over the first, raised by 0.8 of the size |
| `\^`, `\_`, `\{`, `\@`, ... | the character as it is: `'\^'` in single quotes, `"\\^"` in double quotes |

- The markup characters `^ _ { } @ & ~ \` act in any title: `"R&D"` hides the `D`, as in gnuplot. Write `"R\\&D"`
  (or `'R\&D'`), or the text `noenhanced`.
- `set termoption noenhanced` or `set terminal svg noenhanced` turns it off, `enhanced` on again.
- `noenhanced` keeps one text as it is: `set title`, `set xlabel` (`ylabel`, `y2label`, `x2label`), `set key` (its
  entries and title), `set label`, `set xtics` (and the other axes; `set tics` all of them) and a plot item.
- The automatic titles stay as they are, as gnuplot's: the file name and its `using` columns, the function. A
  column header title or an explicit one is enhanced text: `plot 'run.dat' u 1:2 t 'p_{ref}'`.
- The text devices (`dumb`, `block`) drop the markup, the Symbol font as its Latin letters (gnuplot's dumb terminal
  also lifts a superscript one row).
- The HTML viewer draws the tick labels again after a zoom as enhanced text too.
- The Fortran library writes its texts as they are unless [`fig%set_enhanced(.true.)`](../library#methods): a `_` in a
  title passed from a program stays a `_`.

Departures from gnuplot: the Symbol font is written as Unicode Greek letters (gnuplot's svg names the font
`Symbol`, which few systems have), and the `<text>` elements carry `xml:space="preserve"`, so the blank at the start
of a run is kept by every SVG renderer.

### TeX math

A foresight extension: a text's `$...$` runs are TeX math, laid out as LaTeX lays them out (unicode-math, Latin
Modern Math) and drawn from the compiled-in math glyphs, in any label, title, key title or tick label: `set xlabel
'$t/\tau$'`, `plot f(x) title '$e^{-t/\tau}\cos\omega t$'`. The subset: math italic letters, Greek, sub- and
superscripts and primes, `\frac`, `\sqrt`, `\left` ... `\right`, operators and relations with TeX's spacing, inline
`\sum`, `\prod`, `\int`, accents (`\hat`, `\bar`, `\vec`, ...), `\mathrm`, `\mathbf`, operator names (`\sin`, ...)
and spaces; no display style nor environments; see [path C](/manual/paths/c-paper/07-math-in-labels).

- The text around a formula stays enhanced text; in a text holding math `\$` is a dollar; a single `$` is a dollar.
  Automatic titles and `noenhanced` texts are never math.
- SVG and HTML draw a text holding math from the glyphs, over the text kept transparent (selectable); PDF embeds the
  math glyphs; the text devices write the source; `cairolatex` hands it to LaTeX.
- The viewer keeps math labels as drawn; a zoom draws the tick labels again, as text: a math tick format
  (`set format y '$%.1f$'`) is then written as its source.
- foresight_math_test compares 40 formulas with LuaLaTeX's layout, every glyph within 0.5 pt at 10 pt;
  `scripts/check_math.py` checks them in the SVG and PDF goldens.
