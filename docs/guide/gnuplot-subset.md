---
title: gnuplot Subset
---

# gnuplot Subset

foresight interprets a subset of the gnuplot command language. Everything outside it is an error naming the command
and its line (`script.gp:12: unsupported command "splot"`), never silently ignored: a script that runs is a script
that did what it says.

## Syntax

- One statement per line, or several separated by `;`
- `#` starts a comment (outside quotes)
- A line ending with `\` continues on the next one
- Strings in single quotes are literal; in double quotes `\t` is a tab, `\n` a new line (an x tick label on two
  lines; a blank in titles and labels) and `\` takes the next character literally (`\"`, `\\`)
- `@name` (outside quotes) is replaced by the value of the string variable `name`, a gnuplot macro:
  `cmd = 'set logscale y'; @cmd`
- A line `$NAME << WORD` starts a [datablock](#datablocks-and-scripts), its lines read as they are up to one starting
  with `WORD`
- `` `command` `` (outside single quotes, inside double ones too) is replaced by the standard output of the shell
  command, its last newline dropped: ``n = `wc -l < run.dat` ``, see
  [Shell commands](#shell-commands-reset-and-pause)
- Keywords accept gnuplot abbreviations: the shortest accepted form is in bold below

## Commands

| Command | Effect |
|---|---|
| **p**lot *items* | replace the current plot and render it to the output |
| **rep**lot [*items*] | render the last plot again (re-reading its data), optionally adding items |
| **ref**resh | the last plot again, without new items (gnuplot redraws its stored data; the files are read again here) |
| **se**t *option* | set an option |
| **uns**et *option* | reset an option |
| *name* `=` *expression* | a [user variable](#user-variables-and-functions): the value now, integer or real |
| *name*`(`*p1*`, ...) =` *expression* | a [user function](#user-variables-and-functions) |
| **fit** [`[min:max]`] *f(x)* `'file'` [*modifiers*] `via` *a*`,` *b* ... | [fit](#fit) the parameters of a function to data |
| **stat**s [`[x]`] [`[y]`] `'file'` [*modifiers*] [`name`\|`prefix "P"`] [`output`\|`nooutput`] | [statistics](#stats) of a column or a pair |
| **pr**int *expression*`,` ... | [print](#print) values |
| `do for [`*i*`=`*a*`:`*b*`] {` ... `}`, `while (`*c*`) {` ... `}`, `if (`*c*`) {` ... `} else {` ... `}` | [blocks](#blocks-and-loops): loops and conditions, `break`, `continue` |
| `$NAME << WORD` ... `WORD` | a [datablock](#datablocks-and-scripts): data inside the script, `plot $NAME` |
| `function $NAME << WORD` ... `WORD` | a [function block](#function-blocks), called as `$NAME(args)`; inside it `local` *name* `=` ..., `return` [*expression*] |
| **l**oad `'file'` | run a [script file](#datablocks-and-scripts) |
| **cal**l `'file'` [*arg* ...] | run a script file with arguments: `ARG1` ... `ARG9`, `ARGC` |
| **eva**l *string* | run a string as script lines |
| **undef**ine *name* ... | forget variables (`name*`: those starting with `name`), arrays and datablocks (`$NAME`) |
| `array` *A*`[`*N*`]` [`= [`*e1*`, ...]`], `array` *A* `= [`*e1*`, ...]`, `array` *A* `=` *B*`[`*i*`:`*j*`]`, *A*`[`*i*`] =` *expression* | an [array](#arrays) |
| **sy**stem `"command"` | run a [shell command](#shell-commands-reset-and-pause), its output on the standard output |
| **res**et [`session`\|`errors`\|`bind`] | the plot settings back to their [defaults](#shell-commands-reset-and-pause) |
| **pa**use *seconds*\|`-1`\|`mouse` [`"message"`] | [wait](#shell-commands-reset-and-pause): `while (1) { plot ...; pause 5 }` is the live loop |
| `reread` | an error, as gnuplot 6.0 (deprecated): use `while (1) { ...; pause N }` |
| `exit` [`message "text"`\|`error "text"`\|`status N`\|`gnuplot`], `quit` | end the script file being read (a `load` returns to its caller; `message` writes the text first), or with `error` fail with the text; `quit`, `exit gnuplot` and `exit status N` end the run (the command line returning `N`), see [below](#gpval-variables-and-exit) |

## `set` / `unset` options

| Option | `set` | `unset` |
|---|---|---|
| **tit**le `"text"` [`offset X,Y`] [`font F`] [`left`\|`center`\|`right`] [`tc COLOR`] [`noenhanced`] [`boxed`] | panel title, shifted by `offset` characters (y up); `left` and `right` justify it about its centre, as gnuplot's svg terminal; `tc` its color (`tc lt N` linetype N's); `font` read and ignored; `noenhanced` writes it as it is, not as [enhanced text](#enhanced-text); `boxed` on the background (text box style 0) | no title |
| `fit` [*options*] | [fit](#fit) report and stopping options; bare, the defaults | — |
| **pr**int [`"file"` [`append`] \| `"-"` \| `$NAME` [`append`]] | where [print](#print) writes: a file or a datablock (emptied unless `append`), `-` the standard output; bare, the standard error | the standard error |
| **tab**le [`"file"`\|`$NAME`] [`append`] [`separator` `whitespace`\|`tab`\|`comma`\|`"c"`] | plots write their points as [text](#tables) to the file, the datablock or the standard output, drawing nothing; the separator of [`with table`](#with-table) | plots drawn again |
| **errorb**ars (**bar**s) [`small`\|`large`\|`fullwidth`\|`SIZE`] [`front`\|`back`] [`lc C`] [`lw W`] | the cap length of the [error bars](#error-bar-caps) and boxplot whiskers (`small` none, `large`, the default, 1), their line | no caps |
| **xl**abel / **yl**abel / **y2l**abel / **x2l**abel `"text"` [`offset X[,Y]`] [`font F`] [`tc COLOR`] [`rotate` ...\|`norotate`] [`noenhanced`] | axis label (`y2` on the right, `x2` on the top), shifted by `offset` characters (x right, y up; a third, 3D, offset read and ignored), in its `tc` color; `font`, `rotate` and `left`/`center`/`right` read and ignored; `noenhanced`: as it is, not as [enhanced text](#enhanced-text) | no label |
| **xr**ange / **yr**ange / **y2r**ange / **x2r**ange [`[min:max]`] [`noextend`\|`extend`] [`reverse`\|`noreverse`] [`nowriteback`] | axis range; `*` or empty autoscales an end, `[]` or no range keeps both; `min > max` reverses; `reverse` reverses an axis with an autoscaled end (an explicit range is left as it is, as gnuplot); `noextend` keeps autoscaled ends at the data | autoscale |
| **offset**s [`graph`] `L`, [`graph`] `R`, [`graph`] `T`, [`graph`] `B` | autoscaled x and y ends moved out, see [Offsets](#offsets) | no offsets |
| **par**ametric | [parametric](#parametric-plots) functions: items in pairs x(t), y(t) over `trange` | functions of x |
| **clip** [`points`\|`one`\|`two`\|`radial`] | [clipping](#clipping) of segments and markers at the border (bare: `points`) | bare: `points`, `one`, `two` off |
| **timestamp** [`"format"`] [`top`\|`bottom`] [`rotate`\|`norotate`] [`offset X,Y`] [`font F`] [`textcolor C`] | the date and time in a corner, see [Margins](#margins) | no timestamp |
| **poi**ntsize `S` | the point size of the items without their own (`ps`), see [Point types](#point-types) | 1 |
| **linet**ype `N` [`lc`] [`lw`] [`dt`] [`pt`] [`ps`]\|`cycle N` | redefine linetype N, see [Styles](#styles); its color may have an alpha channel (`"#80bb33bb"`) | — |
| **jit**ter [`overlap` [`first`] `N`] [`spread S`] [`wrap W`] [`swarm`\|`square`\|`vertical`] | overlapping points spread out, see [Point types](#point-types) | no jitter |
| **log**scale [*axes*] [`10`] | base-10 log axes; *axes* concatenates `x`, `y`, `y2`, `x2`, `cb` (`y`, `xy2`, `cb`: the [color axis](#images-and-palettes)), all when absent | linear axes |
| **gr**id [[`no`][`m`]`x`\|`y`\|`x2`\|`y2`[`tics`]]... [`front`\|`back`\|`layerdefault`] [`lt N`] [`lc C`] [`lw W`] [`dt N`] [**po**lar [`STEP`]\|`r`\|**spider**plot] | grid lines at the ticks of the axes named (`m`: minor; the others kept; x and y when none), over the data with `front`, in its line (`lt 0` dots, the default, `lt -1` or `lt black` black); `polar`: on a [polar](#polar-plots) panel, rings at the r ticks and spokes every `STEP` (30 degrees by default, in the angle unit; a `STEP` beyond a full turn of radians is in degrees, as gnuplot) instead; `r` the rings alone (with `polar`, as `polar`), `nor` none | no grid |
| **pol**ar | [polar](#polar-plots) coordinates: items are theta:r, functions of `t` | x:y coordinates |
| **an**gles `degrees`\|`radians` | unit of theta, of `t` and of the trigonometric functions (radians by default) | — |
| `theta` [`right`\|`top`\|`left`\|`bottom`] [`clockwise`\|`cw`\|`counterclockwise`\|`ccw`] | where theta = 0 lies and its direction (right, counterclockwise by default) | right, counterclockwise |
| **rr**ange / **tr**ange `[min:max]` | r range (`min` at the pole, 0 when autoscaled) and theta range: of the functions (a full turn by default), and a set end leaves out the data points beyond it | — |
| **rti**cs [`auto` \| `STEP` \| `START,STEP[,END]`] | ticks of the r axis (automatic by default) | no r ticks |
| **tti**cs [[`START,`]`STEP`] [`format "fmt"`] \| [`add`] `("label" angle [level], ...)` | theta labels around the polar plot, in degrees; every 45 degrees without `STEP` (gnuplot: none); a list replaces them, or with `add` its items replace the labels at their angles | no theta labels (the default) |
| **mtt**ics [`N`] | minor theta ticks: `N` intervals between the labels, ticks on the polar border only, as gnuplot | none |
| **rax**is | the r axis, from the pole towards the right of the page (the default) | no r axis |
| **bor**der [`MASK`] [**po**lar] [`front`\|`back`\|`behind`] [`lt N`] [`lc C`] [`lw W`] [`dt N`] | frame sides, 1 bottom, 2 left, 4 top, 8 right (31, all, by default; `MASK` a number or a constant expression), in their line; `polar` adds the circle of the largest r, keeping the sides when no `MASK` is given; the layer is read and ignored (the border over the data) | no border |
| **k**ey [`on`\|`off`] [`left`\|`right`\|`center`] [`top`\|`bottom`\|`center`] [`inside`\|`outside`\|`lmargin`\|`rmargin`\|`tmargin`\|`bmargin`\|`below`\|`above`\|`at POSITION`] [`horizontal`\|`vertical`] [`box` [`lt`\|`lw`\|`lc`\|`dt`\|`ls` ...]\|`nobox`] [`opaque`] [`reverse`] [`Left`\|`Right`] [`invert`] [`samplen L`] [`spacing S`] [`width W`] [`height H`] [`maxrows N`\|`maxcols N`] [`columns N`] [`offset X,Y`] [`title "text"`] [`font F`] [`textcolor C`\|`tc variable`] [`noenhanced`] [`default`] [`autotitle` [`columnhead`]\|`noautotitle`] | show the key, inside the plot area (top right by default), in a margin or at a position, in its layout, see [below](#key); untitled items: as written, by [column header](#column-headers), or none | hide the key |
| **xti**cs / **yti**cs / **y2ti**cs / **x2ti**cs / **cbti**cs [`add`] [`auto`\|`autofreq` \| `STEP` \| `START,STEP[,END]` \| `("label" pos level, ...)`] [`mirror`\|`nomirror`] [`in`\|`out`] [`scale MAJOR[,MINOR]`\|`scale default`] [`rotate` [`by` *angle*]\|`norotate`] [`left`\|`right`\|`center`] [`axis`\|`border`] [`rangelimited`] [`format "f"`] [`font F`] [`offset X,Y`] [`textcolor C`] [`noenhanced`] | tick positions, see [below](#ticks-and-label-formats); `noenhanced`: the labels as they are, not as [enhanced text](#enhanced-text); `y2tics` and `x2tics` are off by default, see [below](#second-y-axis) and [below](#second-x-axis); `cbtics` those of the color box | no ticks, labels nor grid lines |
| **tic**s [`mirror`\|`nomirror`] [`in`\|`out`] [`scale MAJOR[,MINOR]`\|`scale default`] [`border`] | the options of every axis' ticks (the scale of the color box's too); bare, the x and y ticks on, see [below](#ticks-and-label-formats) | no ticks on any axis |
| **ticsc**ale `MAJOR` [`MINOR`] | gnuplot's old form of `set tics scale` | — |
| **lmar**gin / **rmar**gin / **tmar**gin / **bmar**gin [[`at`] `screen` `N` \| `N`] | a margin set: `N` characters from the panel's edge, or the border at the page fraction `N` (from the bottom left); bare or negative, computed, see [below](#margins) | computed |
| **marg**ins `L, R, B, T` | the four margins, each [`at screen`] `N` | all computed |
| **zero**axis / **xzero**axis / **yzero**axis / **x2zero**axis / **y2zero**axis [`lt N`] [`lc C`] [`lw W`] [`dt N`] | lines at the zero of the axes (`xzeroaxis`: y = 0), gnuplot's black dots by default | no line |
| **auto**scale [`x`\|`y`\|`x2`\|`y2`\|`cb`\|`xy`][`min`\|`max`\|`fix`] [`fix`\|`noextend`] | the axes autoscaled again (all without one), `fix` and `noextend` their ends kept at the data | — |
| **du**mmy `NAME`[`, ...`] | the variable of plotted [functions](#functions) (`x`; `t` in polar mode) | `x` |
| **enc**oding [`default`\|`utf8`\|`locale`] | the text encoding (`GPVAL_ENCODING`); the output is UTF-8, other encodings are refused | `default` |
| **termopt**ion [`dash`\|`dashed`] [`enhanced`\|`noenhanced`] [`font F`] | gnuplot's terminal options foresight honours: dashes (always there), [enhanced text](#enhanced-text) on (the default) or off, `font` read and ignored | — |
| **for**mat [*axes*] [`"format"`] [`timedate`\|`numeric`] | tick label format of the *axes* (as `logscale`), see [below](#ticks-and-label-formats); on [time axes](#time-data) a time format (`"%H:%M"`); `timedate` makes them time axes (ticks and labels only), `numeric` numeric ones | default labels |
| **xda**ta / **yda**ta / **x2da**ta / **y2da**ta [`time`] | the data of the axis are [times](#time-data), read with the `timefmt`; the axis ticked and labelled in time units | numbers |
| **timef**mt `"format"` | the input [time format](#time-data), `%d/%m/%y,%H:%M` by default | the default |
| **lab**el [`N`] ... | a [label](#labels-arrows-and-objects) | `unset label [N]`: all, or tag `N` |
| **arr**ow [`N`] ... | an [arrow](#labels-arrows-and-objects) | `unset arrow [N]` |
| **obj**ect [`N`] ... | an [object](#labels-arrows-and-objects): a rectangle, circle, ellipse or polygon | `unset object [N]` |
| **st**yle **arr**ow `N` [`default`\|*arrow options*] | arrow style `N`, used by `set arrow ... as N` | `unset style arrow`: all |
| **st**yle **rect**angle [`fc C`] [`fs FILL`] [`lw W`] [`dt N`] | the look of the rectangles set next | — |
| **dataf**ile **sep**arator [`whitespace`\|`tab`\|`comma`\|`"chars"`] (`'\t'` the tab too, as gnuplot) | cell separators of data files, see [Data Files](data-files#separators-csv); no argument: whitespace | whitespace (`unset datafile`) |
| **dataf**ile **mis**sing [`"string"`\|`NaN`] | the cells holding `string` are missing data: a point reading one is left out, its line not broken, see [Data Files](data-files#missing-data-and-comments); no argument: none | none |
| **dataf**ile **com**mentschars [`"chars"`] | the characters starting a comment in data files; no argument: `#` | `#` |
| **dataf**ile **columnhead**ers \| **nocolumnhead**ers | the first row of each dataset is a header, in plots, `stats` and `fit` (other datafile options may follow) | not a header |
| **sam**ples `N`[`,M`] | points of each [function](#functions), 100 by default; `M` is accepted and ignored; expressions truncated to integers, as gnuplot | 100 |
| **ov**erflow [`float`\|`undefined`\|`NaN`] | an integer overflow of `+ - * **` gives a real (the default), an undefined value or NaN, see [Expressions](#expressions-in-using) | `+` and `-` wrap around (two's complement), `*` and `**` give a real, as gnuplot |
| **iso**samples, **mou**se, **mac**ros, `pointintervalbox`, **zr**ange, **ur**ange, **vr**ange, **xyp**lane, **minus**sign, **mic**ro | read and ignored: they change nothing in gnuplot's 2D svg output (surfaces, interactive terminals, macros always on, `pointinterval` gaps, `splot`); `minussign` and `micro` only with the default encoding, where gnuplot prints the same characters (refused after `set encoding utf8`) | the same |
| **st**yle **d**ata `STYLE` | style of data items without `with` | — |
| **st**yle **f**unction `STYLE` | style of [functions](#functions) without `with`: `lines`, `points`, `linespoints` | back to `lines` |
| **st**yle **l**ine `N` [`lc` ...] [`lt N`] [`lw W`] [`dt N`] [`pt N`] [`ps S`] | line style `N`, used by `ls N` | — |
| **st**yle **fi**ll `empty`\|[`transparent`] `solid` [`D`]\|[`transparent`] `pattern` [`N`] [`border` [`lc C`\|`-1`\|[`lt`] `N`]\|`noborder`] [`segments N`] | fill of the [boxes and filled curves](#boxes-and-filled-curves) plotted next; gnuplot's abbreviations (`s`, `p`, `tr`, `e`, `bo`, `nobo`); `border lt N` (or `border N`) the color of linetype N; `empty` with border by default; `pattern N` one of the 8 patterns of gnuplot's svg terminal, cycling over the filled items from N; `segments N` a foresight extension, see [below](#themes-and-segmented-fills) | — |
| **mxt**ics / **myt**ics / **my2t**ics / **mx2t**ics / **mcbt**ics [`N`\|`default`\|`time N UNITS`] | minor ticks: `N` intervals between major ticks, gnuplot's count without it; `default`: by default (none, 2..9 on log axes); `time N UNITS` one every N `seconds` ... `years` of a [time axis](#time-data); see [below](#ticks-and-label-formats) | no minor ticks |
| `paxis` `N` `range [min:max]`\|`tics [...]`\|`label "text"` | parallel axis N (a constant expression: `set for [i=1:5] paxis i tics`) of the [parallel axis and spider plots](#parallel-axes-and-spider-plots): its range (autoscaled to its values, not extended), ticks (off by default), label | `unset paxis N tics`: no ticks |
| **spi**derplot | spider plot coordinates and data style | back to lines |
| **st**yle `spiderplot` [`fs` FILL] [`lw W`] [`pt N`] [`ps S`] | polygons of the spider plots (empty with border by default) | — |
| `rgbmax` `V` | full intensity of the components of [RGB images](#images-and-palettes) (255 by default) | 255 |
| **pal**ette [`rgbformulae R,G,B`\|`defined (v c, ...)`\|`functions R, G, B`\|`cubehelix` [`start S`] [`cycles C`] [`saturation S`]\|`file 'f'` [`index N`] [`every E`] [`using U`]\|`gray`\|`color`\|`viridis`\|`NAME`] [`positive`\|`negative`] [`maxcolors N`] [`model RGB`\|`model HSV`] | palette of the [images](#images-and-palettes); none: the default (`rgbformulae 7,5,15`); `NAME` a [named palette](#named-palettes) (foresight extension); `defined` takes `v "color"` or `v r g b` (0 to 1); `model HSV` (or gnuplot's `mode HSV`) reads the three components as hue, saturation and value; `functions R, G, B`: three expressions of `gray` (0 to 1), clipped to 0..1, sampled at 1025 levels | — |
| **colors**equence `default`\|`podo`\|`classic`\|`NAME` [`N`] | the [linetype colors](#styles) of the series, `lc N` and the slices: gnuplot's 8 (`default`), `podo` (8), `classic` (13, gnuplot's svg terminal); `NAME [N]` foresight's: the first N (8) colors of a categorical order | — |
| **cbr**ange `[min:max]` | value range of the palette; `*` or empty autoscales an end | — |
| **cbl**abel `"text"` | color box label | no label |
| **colo**rbox [`vertical`\|`horizontal`] [`default`\|`user`] [`origin X,Y`] [`size W,H`] [`border`\|`bdefault`\|`noborder`] [`invert`\|`noinvert`] [`front`] | color box of the images, see [below](#images-and-palettes) | no color box, every option reset |
| **box**width [`W`] [`absolute`\|`relative`] | box width; no `W`: boxes touching (the default) | boxes touching |
| **st**yle `boxplot` [`range R`\|`fraction F`] [`outliers`\|`nooutliers`] [`pointtype P`] [`candlesticks`\|`financebars`] [`medianlinewidth W`] [`separation S`] [`labels off`\|`auto`\|`x`] [`sorted`\|`unsorted`] | layout of the [boxplots](#box-finance-and-boxplot-styles) plotted next | — |
| **st**yle **textbox** [`N`] [`opaque`\|`transparent`] [`fc C`] [`border` [`lc C`] [`lw W`]\|`noborder`] [`margins X,Y`] | text box style `N` (0 to 3) of the `boxed` labels; as gnuplot's svg terminal, an opaque or bordered style puts the text on the background (no border, no margin drawn) | — |
| **st**yle **hist**ogram `clustered` [`gap G`]\|`errorbars` [`gap G`] [`lw W`]\|`rowstacked`\|`columnstacked` [`title` [`tc C`] [`offset X,Y`] [`boxed`]] [`nokeyseparators`] | layout of the [histograms](#histograms) plotted next; clustered, gap 2 by default; the look of the group titles (`boxed`: on the background, text box style 0) | — |
| `readout` [`on`\|`off`] [`left`\|`right`\|`center`] [`top`\|`bottom`\|`center`] [`horizontal`\|`vertical`] [`opaque`\|`noopaque`] [`size H`] | foresight extension: where and how the [readouts](#readouts) of the panel are drawn | readouts not drawn |
| **ou**tput `"file"` | output file: `.svg`, `.html`, `.txt`, `-` | — |
| **te**rminal `svg`\|`html` [**si**ze `W,H`] [**ref**resh `S`] [`enhanced`\|`noenhanced`] [`theme classic`\|`vfd`\|`lcd`\|`washi`\|`night`] [`glow`\|`noglow`] | output format, size in px, HTML reload period, [enhanced text](#enhanced-text) on (the default) or off; the [theme](#themes-and-segmented-fills) (foresight extension, any terminal) | — |
| **te**rminal `dumb` [**si**ze `COLS,ROWS`] [`mono`\|`ansi`\|`ansi256`\|`ansirgb`] | text output, 79 x 24 by default, on the standard output; the series in ANSI colors, see [Output Formats](output-formats#text) | — |
| **te**rminal `block` [`half`\|`quadrants`\|`sextants`\|`braille`] [**si**ze `COLS,ROWS`] [`mono`\|`ansi`\|`ansi256`\|`ansirgb`] | text output drawn with Unicode block or Braille characters, 2 x 2 dots per character by default (`quadrants`), see [Output Formats](output-formats#block-characters) | — |
| **multi**plot [**lay**out `R,C`] [**row**sfirst\|**col**umnsfirst] [**down**wards\|**up**wards] [**t**itle `"text"` [`font F`]] [**mar**gins [`screen`\|`char`] `L,R,B,T`] [**spa**cing [`screen`\|`char`] `X[,Y]`] | grid of panels, or panels in their `origin`/`size` boxes without layout, see [below](#multiplot) | back to one panel |
| **or**igin [`X,Y`] | bottom left corner of the plot, page fractions (default `0,0`); not with a layout | — |
| **si**ze [**sq**uare\|**nosq**uare\|**ra**tio `R`\|**nora**tio] [`W,H`] | plot size, page fractions (default `1,1`; not with a layout); `square`, `ratio R` (> 0): the plot area height over width | — |

## `plot` items

```gnuplot
plot [XRANGE] [YRANGE] ITEM, ITEM, ...
plot 'file' [using SPEC] [index N] [every N] [smooth FILTER | bins[=N] ...] [with STYLE] [title "text" [at ...] | notitle]
            [noenhanced] [axes x1y1|x1y2|x2y1|x2y2] [lc [rgb] "color" | lc N | lc [rgb] variable | lc palette ...]
            [lw W] [dt N] [ps S], ...
plot FUNCTION [with STYLE] [title "text" | notitle] [noenhanced] [axes x1y1|x1y2|x2y1|x2y2] [lc ...] [lw W] [dt N]
            [ps S], ...
```

Inline ranges `[min:max]` before the first item set the x range, then the y range, of that plot only, over `set
xrange` and `set yrange` (which they leave as they are: the next plot without them uses those again; `replot` keeps
them), as gnuplot. An empty or `*` end keeps the set one, `[]` skips an axis, the ends are constant expressions
(`[0:2*pi]`), and `[t=0:2]` names the dummy variable of the functions `t` instead of `x`:

```gnuplot
plot [0:2*pi] [-1.5:1.5] sin(x), cos(x)
plot [t=0:10] exp(-t/4)*sin(t)
plot [] [0:*] 'run.dat' u 1:2      # the y range only
```

They are not supported in polar mode (where gnuplot's first range is the t range): use `set trange`.

After the first item, a range before a function is that function's own sampling range, `*` its axis end, and
its title starts with it (`[0:*] x**2`); before a data item it is ignored with gnuplot's warning:

```gnuplot
plot [-2:2] x, [0:*] x**2           # x**2 sampled over [0:2] only
```

An item may be an assignment or a function definition, done in its turn: the functions after it see it.
`plot for [i=A:*]` iterates a data item until it yields no valid point, that last item not drawn (gnuplot's
unbounded iteration, `using i` over every column):

```gnuplot
plot s = .1, c(t), s = .3, c(t)     # c drawn with each s
plot for [col=2:*] 'run.dat' using 1:col title columnhead
```

| Modifier | Meaning |
|---|---|
| `'file'` | data file; `''` repeats the previous one |
| *function* | an expression of `x`, see [below](#functions) |
| **u**sing `SPEC` | fields separated by `:`, each a column number (0 is the point number), a quoted [column header](#column-headers) or a parenthesized [expression](#expressions-in-using): `Y`, `X:Y`, or the error bar layouts below; a last field `xtic(N)` (`xticlabels(N)`) labels the points with the text of column N, or `xtic(EXPR)` with a [string expression](#string-columns) (`xtic(strcol(1) . ' K')`), see [Histograms](#histograms); `x2tic`, `ytic`, `y2tic` on [those axes](#text-labels-on-any-axis) |
| *A* | an [array](#arrays): its index and value, as a file |
| `$NAME` | a [datablock](#datablocks-and-scripts), as a file |
| **newhist**ogram [`"title"`] [`lt N`] [`fs FILL`] [`at X`] | a new group of [histograms](#histograms), before the histograms of the group |
| **i**ndex `N` | dataset `N` (0-based) of the file |
| **mat**rix | the file is a matrix of values (columns the x index, rows the y index, from 0), for `with image` |
| **ev**ery `I:J:K:L:M:N` | gnuplot's `point_incr:block_incr:start_point:start_block:end_point:end_block`, empty fields default: `every 2`, `every ::1::10`, `every :::1::1` |
| `skip N` | the first `N` lines of the file are not read, whatever they hold (also in `stats` and `fit`) |
| `keyentry` | an item without points, its key entry only (`plot keyentry with boxes lc "red" title "x"`), untitled unless titled, as gnuplot 6.0; with the styles of functions |
| **fc** / **fillc**olor `COLOR` | the fill's own color (styles with a fill), the line and border keeping `lc`: `with filledcurves fc rgb "#80e0a080"` |
| **s**mooth `FILTER` | `unique`, `frequency`, `fnormal`, `cumulative`, `cnormal`, `csplines`, `acsplines`, `mcsplines`, `bezier`, `sbezier`, `kdensity [bandwidth B]`, see [below](#smoothing); `bins` see [Bins](#bins) |
| **w**ith `STYLE` | `lines` (`l`), `points` (`p`), `linespoints` (`lp`), `impulses` (`i`), `steps` (`st`), `fsteps` (`fs`), `histeps` (`his`), `dots` (`d`), see [below](#lines-steps-and-impulses); `yerrorbars` (`yerr`), `xerrorbars` (`xerr`), `xyerrorbars` (`xyerr`), `yerrorlines` (`yerrorl`), `xerrorlines` (`xerrorl`), `xyerrorlines` (`xyerrorl`), `boxes`, `boxerrorbars` (`boxer`), `boxxyerror` (`boxx`), `candlesticks` (`can`) [`whiskerbars` [`F`]], `financebars` (`fin`), `boxplot`, see [below](#box-finance-and-boxplot-styles); `vectors` (`vec`), `arrows`, `ellipses` (`ell`), `polygons` (`poly`), `labels`, `sectors` (`sec`), see [below](#vectors-ellipses-polygons-labels-and-sectors); `parallelaxes` (`parallel`) [`at X`], `spiderplot` (`spider`), see [below](#parallel-axes-and-spider-plots); `filledcurves` (`filledc`) [`closed`\|`x1`\|`x2`\|`y1`\|`y2`\|`y=V`\|`x=V`\|`xy=X,Y`] [`above`\|`below`], see [below](#boxes-and-filled-curves); `histograms` (`hist`), see [below](#histograms); `image` (`ima`), `rgbimage`, `rgbalpha` (`rgba`), see [below](#images-and-palettes); `circles` (`cir`), foresight's `pie [donut F]`, see [below](#circles-pies-and-donuts); foresight's `gauge range [A:B] [segments N]`, `radar`, `rose [linear]`, see [below](#gauges-radars-and-roses); foresight's `readout`, see [below](#readouts); `table` [`if COND`], the rows as [text](#with-table) |
| **fs** / **fills**tyle `FILL` | fill of a box or filled curve item, words as `set style fill` |
| `format "fmt"` | foresight extension, readouts and gauges: the glass of the [readout](#readouts), `%10.3e` by default |
| **t**itle `"text"` / **not**itle [`columnhead`] | key entry; by default the item as written, as gnuplot: `'run.dat' u 1:($2*1e3)`, `sin(x)/x`; `notitle columnhead`: none, the first row still a header |
| **t**itle **col**umnhead[`(N)`] | key entry from the [column header](#column-headers) of column `N` (an expression: `columnhead(i)` in a loop), or of the y column; `col`, `columnheader` as gnuplot |
| **ax**es `x1y1` / `x1y2` / `x2y1` / `x2y2` | plot against the first axes (default), the [second y axis](#second-y-axis), the [second x axis](#second-x-axis), or both second axes |
| `lc` [**rgb**] `"color"` / `lc N` / `lt N` | color (a gnuplot [color name](#color-names) or `#RRGGBB`), or the color of linetype `N` |
| `lc` [**rgb**] **var**iable | a color per point from the last `using` column (`using 1:2:3`): the linetype color of its number (cycling as `lc N`), or with `rgb` the 24-bit color `0xRRGGBB`; with `lines` (each segment in the color of its end point; in the key, the line sample in the first point's, the point sample in the last one's), `points`, `linespoints` and `impulses`, not with `smooth` |
| `lw` `W`, `dt` `N`, `ps` `S` | line width [px], dash type 1..5, point size |
| `dt "string"` / `dt (S, E, ...)` | gnuplot's custom dash patterns: `.` dot, `-` dash, `_` long dash, a blank a longer gap; or the solid and empty lengths; a string variable too (`dt new`); scaled by the line width as gnuplot's svg |
| `lc bgnd` / `lt nodraw` / `lt -1` | the background color, nothing drawn, black (`lt -2` nodraw, `lt -3` bgnd) |
| `pt` `N` / **pointt**ype `N` | [point type](#point-types); without it, points are round dots |
| `pi` `N` / **pointi**nterval `N` | a point on the first point and every N-th after it (`linespoints`, error bar styles; a negative N, gnuplot's line gap around the points, draws them every \|N\|) |
| `ls N` | line style `N` of `set style line`; the options after it override it |
| long forms | **linec**olor, **linet**ype, **linew**idth, **dasht**ype, **points**ize, **lines**tyle (`rgbcolor` for `rgb`), as gnuplot |

`using` defaults as gnuplot: `1:2`, or `0:1` for single-column files; `1:2:3` for `yerrorbars` and `xerrorbars`,
`1:2:3:4` for `xyerrorbars` (the same for the `errorlines`). Error bar layouts:

| Style | Columns |
|---|---|
| `yerrorbars` | `x:y:dy` or `x:y:ylow:yhigh` |
| `xerrorbars` | `x:y:dx` or `x:y:xlow:xhigh` |
| `xyerrorbars` | `x:y:dx:dy` or `x:y:xlow:xhigh:ylow:yhigh` |
| `boxes` | `x:y` or `x:y:width` |
| `filledcurves` | `x:y` (to `y=V`, `x=V`, a border, or the closed polygon), `x:y1:y2` (a band) |
| `histograms` | `y`, the rows at the point numbers 0, 1, ... |
| `image` | `x:y:z` on a regular grid (default `1:2:3`), or a `matrix` file |
| `circles` | `x:y` (default radius), `x:y:radius`, `x:y:radius:start:end` (wedges, degrees) |
| `pie` | `y`, one slice per row; `y:xtic(N)` names the slices |
| `gauge` | `y` (the last finite value), or `x:y` |
| `radar`, `rose` | `y`, one spoke or sector per row; `y:xtic(N)` names them |

### Error bar caps

```gnuplot
set errorbars 2 lc rgb 'red' lw 2     # caps twice as long, red bars
set errorbars small                   # no caps
unset errorbars                       # no caps either, as gnuplot
```

<Plot name="cb_errorbar_caps" svg :width="760" :height="280" />

`set errorbars SIZE` scales the caps of the error bars (y, x and xy bars, the bars of histograms and box error bars)
and of the boxplot whiskers: `large` is 1, the default cap, `small` 0, none; `fullwidth` is taken as `large`. `lc` and
`lw` draw the bars in that line instead of their series'; `front` and `back` are accepted. As gnuplot, the setting is
read when the plot is drawn. foresight's default cap is 6 px long (gnuplot's svg terminal draws 9 px).

## Iteration

```gnuplot
plot for [i = 2:4] 'run.dat' u 1:i w l t word('continuity momentum energy', i - 1)
plot 'run.dat' u 1:2, for [i = 3:4] '' u 1:i lc i
plot for [k in 'a.dat b.dat'] k u 1:2, for [i = 1:3] for [j = 1:2] i*j*x
set for [i = 1:3] label i sprintf("run %d", i) at i, i
unset for [i = 2:3] label i
```

`set for [...] OPTION` and `unset for [...] OPTION` run the command once per value of the clauses, as `do for`: the
loop variable local to it.

`plot for [...] ITEM` plots the item once per value, with gnuplot's clauses (`i = a:b[:c]`, `w in "words"`, several
of them, the last varying fastest); the item's `using` fields, title and options read the variable: a `using`
field that is a constant expression is the column it gives (`u 1:i`; a string, the column of that header name), the
line options take expressions (`lc i`, `lw w`). Each value adds a series with the next color, the default title is the
item as written (`'run.dat' u 1:i`), `''` is the previous file, an empty range plots nothing; iterated and plain items
mix. The loop variable is restored afterwards. Departure: in a plot an inner clause's bounds may not depend on an outer
variable (`for [i = 1:3] for [j = 1:i]` is an error; `do for` supports it).

## Expressions in `using`

A field in parentheses is an expression evaluated on each row, with gnuplot's semantics:

```gnuplot
plot 'run.dat' using ($1/3600):($2*1e3)             # hours, milli-units
plot 'run.dat' using 1:($3 > 0 ? log10($3) : 1/0)   # 1/0 drops a point: a gap
plot 'run.dat' using 0:(sqrt($2**2 + $3**2)) with lines
```

| | |
|---|---|
| Columns | `$N` or `column(N)`, `$0` is the point number; `column()` takes an expression: `column($1 + 1)`, or a header name: `column("residual")`; `column(-1)` the block, `column(-2)` the dataset; the text of a column: [`strcol(N)`](#string-columns) |
| Operators, loosest first | `?:` · `\|\|` · `&&` · `\|` · `^` · `&` · `==` `!=` · `<` `<=` `>` `>=` · `<<` `>>` · `+` `-` · `*` `/` `%` · unary `-` `+` `!` `~` · `**` |
| Functions | `abs acos arg asin atan atan2 ceil conj cos cosh exp floor imag int log log10 real sgn sin sinh sqrt tan tanh`; gnuplot's [special functions](#special-functions) (`erf`, `gamma`, `besj0`, `lambertw`, ...); the [string functions](#strings), [`strcol`, `columnhead`](#string-columns), [`timecolumn`, `strftime`, `strptime`, `time`](#time-data), [`system`](#shell-commands-reset-and-pause), [`index`](#arrays), `rand(x)` (gnuplot's generator: `rand(0)` the next number, `rand(-1)` reset, `rand(N)` seeded; the same numbers as gnuplot), `exists("name")` (old name `exist`) |
| Arrays | `A[i]` an element, `A[i:j]` a slice, `\|A\|` the size, `$NAME[i]` a datablock line, see [Arrays](#arrays) |
| Function blocks | `$f(args)`, see [Function blocks](#function-blocks) |
| Constants | numbers (`2`, `1.5`, `.5`, `1e-3`, hexadecimal `0xff`, octal `017`), `pi`, complex `{re, im}` and `I` (`{0,1}`) |
| Assignments | `name = value` (its value the value, right associative: `a = b = 0`) and gnuplot's serial evaluation `(a, b)`, each evaluated, the last the value: `using 1:(sum = sum + $2, sum)`; run when evaluated, on each row |

The rules are gnuplot's, checked against gnuplot 6.0:

- `**` is right associative and binds tighter than a unary minus: `-2**2` is -4, `2**3**2` is 512.
- Integer constants stay integers: `1/2` is 0 and `-5/2` is -2, but `1/2.` is 0.5; an integer overflow gives a real.
  Columns are reals, so `$2/2` is a real division. `floor`, `ceil`, `int`, `sgn`, comparisons and logical operators
  give integers.
- `&&`, `||` and `?:` evaluate only the operand they need: `$2 > 0 && log($2) > 1` never takes the log of a
  negative, `1 ? 5 : A[9]` is 5.
- The bitwise operators `&` `|` `^` `~` `<<` `>>` take 64-bit integers, with C's precedence: `5 & 3 == 1` is
  `5 & (3 == 1)`, 0. A real or a string is an error, `non-integer passed to boolean operator`; columns are reals, so
  write `int($3) & 2`. The shifts are gnuplot's on x86: the count modulo 64, `>>` logical (`-8 >> 1` is
  9223372036854775804). `0xff` and `017` (octal; `08` is an error) are integers, a real past the largest one.
- A missing cell, a division by zero, a domain error (`acos(2)`, `log(0)`) or an overflow make the point undefined:
  a gap in the line, as gnuplot's `1/0`. `set overflow undefined|NaN` makes an integer overflow undefined or NaN;
  `unset overflow` wraps `+` and `-` around (two's complement), as gnuplot. `int` beyond 9.22e18 and `floor`, `ceil`
  beyond 2^52 give NaN, as gnuplot.
- Values are complex, as gnuplot's: `{re, im}` and `I` are constants; `+ - * / **` follow gnuplot's formulas (powers in
  polar form: `(-8)**(1./3)` is `{1.0, 1.732...}`); `abs`, `arg`, `real`, `imag`, `conj`, `sqrt`, `exp`, `log`,
  `log10` (also of negative reals: `sqrt(-4)` is `{0.0, 2.0}`), `sin`, `cos`, `tan`, `sinh`, `cosh` take complex
  arguments, the other functions of one are undefined; comparisons `<`... compare the real parts, `==` `!=` both.
  `print` shows `{re, im}`. A plotted value whose imaginary part exceeds 1e-8 is undefined (gnuplot's `set zero`):
  `plot abs(A(w)), 180/pi*arg(A(w))` plots a transfer function.
- An assignment inside an expression sets the user variable when it runs: on each data row in `using`, so a running
  sum advances along the file; a variable assigned in a user function body is read when run wherever it is used
  (`avg5(x) = (shift5(x), (b1+b2+b3+b4+b5)/5)`).

A field must be a column number or one parenthesized expression, as in gnuplot: `using 1:$2` and `using 1:2*3` are
errors. Syntax errors point at the character: `using: unexpected ")" at character 6 of "($2 +)"`.

Beyond gnuplot, foresight accepts `%` and the logical operators on reals, and an overflow gives a gap where gnuplot
stops the plot. Expressions take [user variables and functions](#user-variables-and-functions) and
[strings](#strings), the text of columns included ([`strcol`](#string-columns)), and
[function blocks](#function-blocks).

## User variables and functions

```gnuplot
A = 2.0; tau = 3.0; omega = 2*pi/2
envelope(t) = A*exp(-t/tau)
signal(t) = envelope(t)*cos(omega*t)
set xrange [0:2*tau]
plot signal(x) t 'signal', envelope(x) t 'envelope', -envelope(x) notitle
```

<Plot name="cb_user_functions" svg :width="560" :height="320" />

As gnuplot: `name = expression` stores the value of the expression now, an integer stays an integer (`a = 2; b = a/3`
is 0, `a = 2.` is real); `name(p1, p2, ...) = expression` defines a function whose variables take their values when
it is called, that is when the plot is drawn (`f(x) = a*x; a = 3` then `plot f(x)` uses 3; `replot` after a new value
uses it). Expressions everywhere take them: plotted functions, `using` fields (`u 1:($2*scale)`), range ends (`set
xrange [0:2*tau]`, also `[-pi:pi]`). The plot's dummy variable wins over a user variable of its name, and is not seen
inside a function body (there `x` is the user variable `x`). Names are case sensitive (`a_1`, `A`), `pi` may be
assigned, the builtin functions may not be redefined. Errors as gnuplot: `undefined variable: c`, `function f requires
1 variable`. Variables also hold [strings](#strings); `undefine NAME` forgets one (see
[Datablocks and scripts](#datablocks-and-scripts)).

Functions may recurse, directly or through others, as in gnuplot 6.0:

```gnuplot
fact(n) = n <= 1 ? 1 : n*fact(n - 1)
T(n, x) = n == 0 ? 1 : n == 1 ? x : 2*x*T(n - 1, x) - T(n - 2, x)    # Chebyshev polynomials
even(n) = n == 0 ? 1 : odd(n - 1); odd(n) = n == 0 ? 0 : even(n - 1)
```

<Plot name="cb_recursion" svg :width="560" :height="320" />

As gnuplot, at most 251 nested calls: `t(n) = n == 0 ? 0 : t(n - 1)` runs `t(250)`, `t(251)` is `recursion depth
limit exceeded` (in a plot, the point is undefined). gnuplot's own evaluation stack overflows earlier on a recursion
that adds a term per call (`d(n) = n == 0 ? 0 : 1 + d(n - 1)` stops at `d(249)` there); foresight sizes its stack to
the depth limit. A function that does not call itself is compiled inline, as before; one that does is compiled once
and run on a call stack.

## Strings

```gnuplot
run = 'cavity'; n = 3
file = run . '_' . n . '.dat'                  # cavity_3.dat
set title sprintf('%s, mesh %d', run, n)
plot file u 1:2 t 'res ' . substr(file, 1, 6), '' u 1:3 t sprintf('p = %.2f', p)
```

Strings are gnuplot's: in double quotes with the escapes `\t`, `\n`, `\"`, `\\`, or in single quotes as they are.
A variable holds a string as well as a number, a user function may return one, `?:` chooses between them.

| Operation | Value |
|---|---|
| `a . b` | `a` joined to `b`; `b` a string or an integer (`'x' . 3` is `x3`; a real is an error) |
| `a eq b`, `a ne b` | 1 or 0; both strings |
| `s[i:j]`, `s[i:]`, `s[:j]`, `s[*:j]` | characters `i` to `j` (1-based), the ends clamped to the string, empty if they cross |
| `strlen(s)`, `substr(s, i, j)`, `strstrt(s, t)` | length; `s[i:j]`; position of `t` in `s`, 0 if none |
| `words(s)`, `word(s, n)`, `trim(s)` | number of blank-separated words; word `n` (empty if none); `s` without leading and trailing blanks |
| `split(s [, sep])`, `join(A, sep)` | gnuplot 6.0's: the words of `s` (or its pieces between the occurrences of `sep`, empty ones kept, none after a last one) as an array, assigned (`A = split(s)`), printed, sized (`\|split(s)\|`) or passed to `index` and `join`; the string elements of `A` joined with `sep` between every two; arguments known when read |
| `sprintf(format, ...)` | C's `printf`: `%d %i %u %o %x %X %c` (the integer part), `%f %F %e %E %g %G` (the real), `%s`, flags `-+ 0#`, width, precision, `%%`; conversions left without an argument are copied as written |
| `gprintf(format, x)` | `x` with a [`set format`](#ticks-and-label-formats) format |
| `value("name")`, `exists("name")` | the variable's value (NaN if none); 1 if it exists |
| `int(s)`, `real(s)` | the number a string starts with, truncated or real |

Arithmetic and `==` read a string's leading number, as gnuplot: `"3" + 1` is 4, `"2" / "4"` is 0 (two integers),
`"0x10" + 0` is 16; a string without one is an error (`non-numeric string found where a numeric expression was
expected`), as is a string used as a condition. `.` binds as `+` (`"a" . 2*3` is `a6`), `eq` and `ne` as `==`.
`sprintf` converts a real from its exact binary value, as C does: `sprintf("%.2f", 2.675)` is `2.67`.

A string goes wherever a string is taken, as an expression: titles and axis labels (`set title`, `set xlabel`,
...), `set output`, `set format`, `set print`, `set multiplot title`, plot titles (`t 'col' . i`) and plot file names
(`plot file u 1:2`, `plot 'run_' . n . '.dat'`; a plot item whose constant value is a string is a file). A number
where a string goes is an error (`set title 5`). The text of data columns is [`strcol`](#string-columns), times are
[`strftime` and `strptime`](#time-data), the output of a shell command [`system("command")`](#shell-commands-reset-and-pause);
[arrays](#arrays) hold strings too.

## String columns

```gnuplot
plot 'runs.dat' u 0:2:xtic(strcol(1) . ' K')                          # tick labels built from the text of column 1
plot 'runs.dat' u 2:3:(sprintf('%s: %.1f', strcol(1), $3)) w labels    # labels mixing text and numbers
plot 'runs.dat' u 0:(strcol('solver') eq 'gmres' ? $2 : 1/0)           # the rows chosen by their text
plot 'runs.dat' u 0:2:xtic(columnhead(3))                              # every tick named by a header cell
```

| Function | Value |
|---|---|
| `strcol(N)`, `stringcolumn(N)` | the text of column `N` of the row (quotes removed); `N` a header name: `strcol("solver")` |
| `columnhead(N)`, `columnheader(N)` | the text of column `N` in the first row of the dataset |
| `column(-1)`, `column(-2)` | the block of the row within its dataset (blocks are parted by one blank line) and its dataset (two), from 0 |
| `timecolumn(N[, "format"])` | column `N` read as a [time](#time-data) |

As gnuplot, `strcol("name")` and `columnhead(N)` read the first row without making it a header (it stays a row, counted
by `$0`), unlike `column("name")`; a column beyond the end of its row is undefined (gnuplot stops the plot). The text
of `labels` and of `xtic(...)` is any string expression; a number there gives the text of the first column the
expression reads, as gnuplot (`u 1:2:($2*2) w labels` writes column 2 as it is), or the number as `%g` when it reads
none. The cell texts are kept in memory only for the items that read them. Labels and tick labels longer than 128
characters are cut.

## Datablocks and scripts

```gnuplot
$RUN << EOD
# iteration  residual
1  0.50
2  0.31
3  0.12
EOD
plot $RUN u 1:2 w lp, 'run.dat' u 1:2      # a datablock is plotted, fitted, stated as a file
stats $RUN u 2 nooutput
print $RUN                                 # its lines, then an empty one
load 'style.gp'                            # another script
call 'panel.gp' 'cd' 3                     # ARG1 = "cd", ARG2 = "3", ARGC = 2
eval sprintf('set title "%s"', name)       # a string run as script lines
cmd = 'set logscale y'; @cmd               # a macro
undefine tmp_* $RUN                        # forget variables and datablocks
```

A datablock `$NAME << WORD` holds the lines after it, as they are (comments, blank lines and their dataset breaks
included), up to the line starting with `WORD`. Wherever a data file goes (`plot`, `fit`, `stats`, `set palette file`)
`$NAME` reads them instead; `exists("$NAME")` tells whether it is defined, `undefine $NAME` forgets it. A datablock is
read outside blocks (`do for {...}`) only. `$NAME[i]` is its line `i` (a string, from 1) and `|$NAME|` the number
of its lines, as gnuplot 6.0.

`load 'file'` runs the script `file` (a string expression), `ARG0` its name; `call 'file' arg1 ... arg9` also sets
`ARG1` to `ARG9` and `ARGC`, as gnuplot 6.0: a quoted argument as it is, a number as written (`2.50`), a variable or
a parenthesized expression its value, an integer as it is and a real as `%g` (`pi` is `3.14159`, `(n+1)` is `6`), a
word that names no variable as it is (`call 'f.gp' sub1`); `ARGV` holds the values (numbers for the numbers: `1.23e4`
is `ARG1` `"1.23e4"` and `ARGV[1]` 12300.0); the arguments not given are empty. The `ARG` variables are restored after the script, as gnuplot's (`ARGC` is 0 outside). The command line
does the same: [`foresight -c script.gp arg1 ...`](cli#options), as `gnuplot -c`. A loaded script is watched by
`--watch` as the data files are. `eval STRING` runs the string as script lines. `@name` substitutes the value of the
string variable `name` in the statement before it runs (gnuplot's macros; outside quotes; a number variable is an
error, where gnuplot warns and drops it). `undefine a b*` forgets the variable `a` and those whose name starts with
`b`, as gnuplot: nothing after `undefine` does nothing, a word that does not start as a name (`3`, `*`) is `not a
variable name`, a name with more after it (`a*b`) is ignored; functions stay defined. The array `ARGV` holds the
arguments as strings, as gnuplot 6.0 (`|ARGV|` is `ARGC`), restored after the script too.

## Arrays

```gnuplot
array T[4]                                   # 4 elements without a value
do for [i = 1:|T|] { T[i] = 300 + 25*i }
array names = ['inlet', 'throat', 'exit']    # elements of any type, the size from the list
array P[5] = [1, 2.5]                        # 5 elements, the first two set
print T, |T|, names[2], index(names, 'exit') # [325,350,375,400] 4 throat 3
plot T w lp, T u 1:($2 - 300) t 'rise'      # an array is a file: column 1 the index, 2 the value
stats T nooutput                             # its values: STATS_mean, ...
f(i) = T[i] / 300.; plot 'probes.dat' u 1:(f($1))   # an index known on each row
```

<Plot name="cb_arrays" svg :width="560" :height="320" />

Arrays are gnuplot 6.0's: `array A[N]` makes N elements (from 1) without a value, `= [e1, ...]` gives the first
ones (`array A = [...]` sizes it by the list); an element holds a number or a string, and `A[i] = expression` sets one
(a real index is truncated, as gnuplot). In expressions `A[i]` is an element, `|A|` the size, `index(A, value)` the
first element equal to the value (0 if none): a constant index is read when the expression is compiled, an index
depending on the data row (`A[$1]`, a function argument) on each row. `print A` shows `[1,2.5,"x",]` (an element
without a value empty), `plot A` and `stats A` read the index and the value of each element as a file (an element
without a value is undefined), `undefine A` forgets it, `exists("A")` tells it exists. A redeclaration replaces the
array. Errors as gnuplot: `array index out of range`, an element without a value is an error where its value is
needed. `ARGV` is the array of the script arguments, `$NAME[i]` a datablock line and `|$NAME|` their number. Not
supported: arrays as function arguments.

An element without a value is gnuplot's undefined value, as is the value of a [function block](#function-blocks)
without `return`: `print` shows it as `<undefined>`, an assignment stores nothing (`x = A[1]` leaves `x` as it was),
any operation on it is `uninitialized user variable` (`A[1] + 1`). An index out of range or without a value is found
when the element is evaluated, as gnuplot: `1 ? 5 : A[9]` is 5.

### Slices

```gnuplot
array M = [3.1, 3.4, 4.0, 5.2, 6.8, 8.1, 8.9, 8.6, 7.2, 5.6, 4.1, 3.3]
print M[1:3], M[10:], |M[4:6]|               # [3.1,3.4,4.0] [5.6,4.1,3.3] 3
S = M[7:9]; array W = M[:3]                  # copies, arrays themselves
print M[7:9][2], M[0:2], M[5:4]              # 8.6 [3.1,3.4] []
```

<Plot name="cb_slices" svg :width="560" :height="320" />

`A[i:j]` is the array of the elements `i` to `j`, as gnuplot 6.0: an empty or `*` end is the first or the last
element, the ends are clamped to the array (`A[0:9]`), `i > j` is the empty `[]`. A slice prints, sizes (`|A[i:j]|`),
indexes (`A[i:j][k]`) and makes a copy (`B = A[i:j]`, `array B = A[i:j]`; `B = A` copies too). Its ends are known when
the expression is compiled (no column, no function argument), and a slice is no number: `A[1:2] + 1` is an error
(gnuplot's is an internal one).

## Shell commands, reset and pause

```gnuplot
host = system('hostname')                    # the output of a shell command, its last newline dropped
n = `wc -l < run.dat`                        # the same, substituted in the line before it runs
set title sprintf('%s: %d lines', host, n)
system 'mkdir -p frames'                     # a command, its output on the standard output
reset                                        # the plot settings back to their defaults
while (1) {                                  # gnuplot 6.0's live loop
  plot 'run.dat' u 1:3 w l
  pause 5
}
```

<Plot name="cb_runtime" svg :width="760" :height="300" />

`system("command")` runs the command with `/bin/sh` and gives its standard output, the last newline dropped, as
gnuplot; it runs when its expression is compiled, so its command cannot depend on a data column or on the argument of a
user function (an error). `system "command"` runs a command, its output going to the standard output. A command
between backquotes is substituted by its output (the last newline dropped) in the statement before it runs, inside
double quotes too, not inside single ones. Not supported: `GPVAL_SYSTEM_ERRNO` and `GPVAL_SYSTEM_ERRMSG`.

`reset` puts the settings of the current panel back to their defaults, as gnuplot 6.0, keeping what it keeps: the
terminal and the output, `set fit`, `set print`, `set table`, the multiplot, the linetypes (`set colorsequence`) and
`set style data` (a gnuplot quirk, kept). `reset session` also forgets the user variables, functions and arrays (the
datablocks and the script arguments stay); `reset errors` and `reset bind` do nothing.

`pause SECONDS ["message"]` writes the message on the standard error and waits; `pause 0` only writes it; `pause -1`
waits for a line of the standard input (its end does not wait), `pause mouse [EVENTS]` only writes the message, there
being no mouse, as gnuplot on a terminal without one. In a loop with a plot, `while (1) { plot ...; pause 5 }`
rewrites the output every 5 seconds: the plot of a running job, seen live in the HTML page with `set terminal html
refresh 5` (each output is written whole, atomically). `reread`, the old idiom, is an error: gnuplot 6.0 rejects it as
deprecated. [`foresight --watch`](cli#options) does the same without a loop, re-running the script when its data
change.

### GPVAL variables and exit

```gnuplot
save_encoding = GPVAL_ENCODING; set encoding utf8
if (!strstrt(GPVAL_COMPILE_OPTIONS, "+LIBCERF")) { print "no libcerf here"; exit }
set encoding save_encoding
```

foresight sets gnuplot's variables that scripts read: `GPVAL_VERSION` (6.0, the gnuplot it follows) and
`GPVAL_PATCHLEVEL`, `GPVAL_COMPILE_OPTIONS` naming only the options of gnuplot that foresight has (`+OBJECTS +STATS
+POLARGRID +FUNCTIONBLOCKS`; `-LIBCERF` and the others it lacks), so a script testing them skips what is missing,
`GPVAL_ENCODING`, `GPVAL_TERM` (following `set terminal`), `GPVAL_TERMINALS`, `GPVAL_SYSNAME`, `GPVAL_MACHINE`,
`GPVAL_DEGREE_SIGN`, `GPVAL_LINENO` (the last line read of the statement, as gnuplot: the closing line of a block for
the statements in it); `reset session` and `undefine` keep them. `set encoding` takes `default`, `utf8` and `locale` (the
output is UTF-8; other encodings are refused).

`exit` ends the script file being read, as gnuplot: a file run by `load` or `call` returns to its caller, the script
given to the command line ends (its output written). `exit message "text"` writes the text first, `exit error "text"`
fails with it; `quit`, `exit gnuplot` and `exit status N` end the run, the command line returning `N`.

## Tables

```gnuplot
set table $SMOOTH                            # or a file, 'smooth.dat' [append]; bare, the standard output
plot 'noisy.dat' u 1:2 smooth csplines
unset table
plot 'noisy.dat' u 1:2 w p, $SMOOTH w l      # the tabulated curve, plotted
```

<Plot name="cb_table" svg :width="560" :height="320" />

With `set table` a plot draws nothing: it writes the points of its items as gnuplot 6.0 tabulates them, byte for
byte, a block per item: `# Curve K of N, M points`, `# Curve title: "..."`, the column names, then a row per point in
the axis formats (`set format`, `% h` by default) and a flag, `i` inside the ranges, `o` outside a fixed range, `u`
undefined. The columns are `x y type`, with `ylow yhigh` for y error bars, `xlow xhigh` for x error bars and boxes,
both for xy error bars, `y1 y2` for a band of filled curves, `x y label` for labels. A plot of the functions writes
their samples, of smoothed data the smoothed points. The table goes to a file (emptied unless `append`), a datablock
(plotted, fitted, stated afterwards) or the standard output; `unset table` draws again.

### With table

```gnuplot
set table $SLOW                              # set table [where] [append] [separator whitespace|tab|comma|"c"]
plot 'steptimes.dat' u 1:2 w table if $2 > 1.6
unset table
plot 'steptimes.dat' u 1:2 w l, $SLOW u 1:2 w p
```

<Plot name="cb_with_table" svg :width="560" :height="320" />

`plot ... with table` writes the rows of a data item as text, where `set table` sends them, as gnuplot 6.0: each
`using` field after a blank, a number as `%g` (`set format` does not apply), `nan` if undefined, a string as it is
(`strcol(4)`, `sprintf(...)`), the fields joined by the separator, tab by default (`set table separator comma`, kept
until changed). Without `using`, the leading numeric cells of each row. Into a datablock a string field has no blank
and the separator one before it, gnuplot's layout (`a , 1 , 2`). `with table if CONDITION` writes the rows where the
condition holds; `index`, `every` and the column header names apply; blank lines and comments are not written and no
row is left out for a bad cell. A function with table writes nothing (gnuplot's warning), and without `set table` it
is gnuplot's error, `'with table' requires a previous 'set table'`.

## Time data

```gnuplot
set xdata time
set timefmt '%Y-%m-%d %H:%M:%S'           # the time spans two blank-separated columns: y is column 3
plot 'log.dat' u 1:3 w l                  # x ticked in whole hours, labels invented from the range
set format x '%H:%M'                      # or set: a time format
set xrange ['2024-03-01 06:00:00':'2024-03-01 18:00:00']
set xtics '2024-03-01 06:00:00', 3*3600   # tick positions as times, steps in seconds
plot 'log.dat' u (timecolumn(1) + 3600):3  # an expression on a time
print strftime('%a %d %b %Y %H:%M', strptime('%Y-%m-%d', '2024-03-01') + 5400)   # Fri 01 Mar 2024 01:30
```

As gnuplot, a time is the number of seconds since 1970-01-01 00:00 UTC (proleptic Gregorian calendar, no leap
seconds, no time zone). `set xdata time` (`ydata`, `x2data`, `y2data`) reads the x (y) field of each plot item with the
`timefmt`, a time spanning as many blank-separated columns as the format has blanks (as gnuplot: `using 1:3` above);
an unreadable time is a gap. Range ends, tick positions and [label](#labels-arrows-and-objects) coordinates take time
strings on a time axis, read with the `timefmt`.

The ticks are gnuplot 6.0's: the step is the automatic one rounded to whole seconds, minutes, hours (1, 2, 3, 4, 6,
12, ...: duodecimal steps), days, weeks, months or years, the ticks fall on whole units of it (days at 0 AM, months on
the 1st), an autoscaled end extends to the step and then to a whole unit. A fixed step (`set xtics 3600`, an
expression: `3*3600`) is in seconds. Without a time format the labels are gnuplot's invented ones: within a day `%H:%M`
(`%H:%M:%S` under a minute, `%M:%S` within an hour), over days `%d/%m` (or `%m/%d` when the `timefmt` has the month
first) and `%H:%M` on a second line below a week, the year (`%y`, `%Y` across centuries) when the range crosses years.
`set mxtics N` divides each step, `set mxtics` gnuplot's automatic minor time steps; none by default. `set mxtics time
N UNITS` (gnuplot 6.0) puts a minor tick every N `seconds`, `minutes`, `hours`, `days`, `weeks` (multiples of N units
since 1970, weeks from Thursday 1 January 1970), `months` or `years` (the first day of every N-th one, counted from
1970): `set mxtics time 1 months` marks the 1st of every month, whatever its length. The HTML page regenerates the time
ticks after a zoom by the same rules (the `time` minor ticks excepted) and shows the cursor position as a date.

<Plot name="cb_time_minor" svg :width="640" :height="260" />

| Conversion | `strftime` writes, `strptime` reads |
|---|---|
| `%Y` `%y` `%m` `%d` `%j` | the year (4 digits, or 2: 69..99 the 1900s), month, day, day of the year |
| `%H` `%M` `%S` | hours, minutes, seconds (`%.3S` with decimals; `strptime` reads a fraction) |
| `%b` `%B` `%a` `%A` | month and weekday names, abbreviated or full (`strptime` reads either, skips the weekday) |
| `%s` | the seconds since 1970 |
| `%p` | `am`, `pm` (`strptime`: `pm` adds 12 hours) |
| `%tH` `%tM` `%tS` | elapsed hours, minutes, seconds: the largest unit of the format unbounded (`%tH:%tM` of 361800 s is `100:30`) |
| `%I` `%k` `%l` `%D` `%F` `%T` `%R` `%r` `%w` `%U` `%W` `%%` | `strftime` only, as C's (`%p` lowercase, as gnuplot) |

`strftime("format", t)` writes a time, `strptime("format", "text")` reads one (undefined if the text does not match),
`timecolumn(N[, "format"])` reads column N (with the `timefmt` without a format), `time(0)` is the time now (`time(0.0)`
with its fraction, `time("format")` as text), taken when the expression is read. In `strptime` a blank matches any run
of blanks; fields take up to their width in digits (`%Y%m%d` reads `20240301`) and may overflow (`25:70` is 26:10).
Conversions gnuplot does not know write nothing, as gnuplot's. `set format x "%H:%M" timedate` makes the x axis a time
axis for its ticks and labels without reading the data as times, `numeric` turns it back. Not supported: time zones,
`%tH` with decimals.

## Print

```gnuplot
print 'mean ', STATS_mean, ' after ', FIT_NITER, ' iterations'
set print 'summary.txt' append
print sprintf('%-10s %9.3e', 'cd', cd_mean)
```

`print` writes its values on one line separated by a blank: strings as they are, integers in decimal, reals as
gnuplot shows them (`%.15g`, `.0` appended when integral: `100.0`, `0.333333333333333`, `1e+20`). The line goes to
the standard error, as gnuplot's; `set print "file"` empties the file and sends the lines there, `set print "file"
append` keeps its content, `set print "-"` sends them to the standard output, `set print` and `unset print` back to the
standard error.

```gnuplot
set print $ERR                               # the printed lines make a datablock
do for [n = 1:6] { h = 0.4 / 2**n; print h, h**2 * (1 + h) }
set print
plot $ERR u 1:2 w lp                         # plotted, stated, printed as any datablock
```

<Plot name="cb_print_datablock" svg :width="560" :height="320" />

`set print $NAME` sends the lines to the datablock, emptied first unless `append` (which also creates it), as gnuplot
6.0.

## Function blocks

```gnuplot
function $cbrt << EOF
  local r = ARGV[1] > 1 ? 1.0 * ARGV[1] : 1.0
  do for [k = 1:50] {
    d = (r**3 - ARGV[1]) / (3*r**2)
    r = r - d
    if (abs(d) < 1e-12) { return r }
  }
  return r
EOF
print $cbrt(27)                              # 3.0
plot $cbrt(x)                                # in plotted functions and using fields too
```

<Plot name="cb_function_blocks" svg :width="560" :height="320" />

A function block is gnuplot 6.0's: `function $NAME << WORD`, then lines of script up to one starting with WORD. A call
`$NAME(args)` in any expression (printed, assigned, plotted, a `using` field) runs those lines with `ARGC` the number of
arguments and the array `ARGV` their values (both restored after); `return EXPR` ends the block with its value, from
inside loops and `if` blocks too, and a block without one gives the [undefined value](#arrays). `local NAME = ...` (or
`local array A[N]`) makes a variable that the end of the block restores; the other variables a block sets stay set,
as gnuplot. Blocks may call themselves and each other (250 deep at most). `print $NAME` shows `function $NAME( )` and
its lines, `undefine $NAME` forgets it, `$nosuch(1)` is gnuplot's `Not a function block`. Outside a block, `local` is a
plain assignment and `return` ends the script file being read (a `load` returns to its caller), as gnuplot. As in
gnuplot, the arguments come as `ARGV[i]`, not `ARG1` (which keep the caller's values). gnuplot 6.0.0 fails on a block
called inside `set title sprintf(...)`; foresight runs it, and through a variable both do.

## Blocks and loops

```gnuplot
do for [i = 1:3] {
   set output sprintf('panel_%d.svg', i)
   plot 'run.dat' u 1:(column(i + 1)) t word('continuity momentum energy', i)
}
k = 0
while (k < 3) { k = k + 1; print k }
if (exists('STATS_mean')) { print STATS_mean } else { print 'no stats yet' }
```

As gnuplot's: `do for [i = a:b[:c]] { ... }` runs the block for each integer from `a` to `b` by `c` (bounds
truncated to integers, a negative step counts down, an empty range none), `do for [w in "x y z"] { ... }` for each
word of a string; clauses may follow one another, `do for [w in "a b"] for [i = 1:2] { ... }`, the last one varying
fastest. The loop variable is local to the loop: its value before is restored afterwards, or it is removed.
`while (c) { ... }` runs while `c` is not 0, `if (c) { ... } else if (c) { ... } else { ... }` the first block whose
condition holds; `else` follows `}` on the same line. `break` leaves the loop (the whole `do`, all its clauses),
`continue` goes on with the next value. A block may span lines, with statements on new lines or separated by `;` and
comments inside it. A string as a condition and an unbounded range (`[i = 1:*]`) are errors.

gnuplot's old one-line form `if (c) command; ...; [else command; ...]` runs too, as gnuplot 6.0 still does: the rest
of its line is its own, the commands up to an `else` when the condition holds, those after it otherwise (`else if`
chains); inside a block it is gnuplot's error, `Old-style if/else statement encountered inside brackets`.

## Functions

A plot item that is not a quoted file is a function of `x`, with the operators, functions and rules of
[`using` expressions](#expressions-in-using), without columns:

```gnuplot
plot 'run.dat' u 1:2, 1e-1 * exp(-x/5) t 'model'
plot sin(x)/x, x > 0 ? log(x) : 1/0
set samples 400; plot x * sin(1/x)
```

As gnuplot, a function is sampled at `set samples` points (100) evenly over the x range before its extension to the
ticks: the `xrange` ends where set, else the extent of the data of the whole plot, else [-10:10]. On a log x axis the
samples are evenly spaced in log x. Undefined values (`1/0`, `log(-1)`) are gaps. Functions are drawn `with lines`
by default whatever `set style data` says; `set style function points` (or `linespoints`) changes it; `with boxes`
and `with filledcurves` fill the samples as data (a `y=V` base included), error bars are not usable. The expression runs up to the first item option, so blanks may separate its terms: `plot x * 2 + 1 t 'line'`.
`set dummy t` renames the variable (`plot t**2`), as gnuplot; `unset dummy` and `reset` bring back `x`.

`sum [i=a:b] term` adds the term for each integer `i` from `a` to `b` (ends known when the expression is read:
numbers or variables), integers staying integers and an empty range 0, as gnuplot; sums nest, and go into user
functions and plotted functions (at most 10000 terms, not in function blocks):

```gnuplot
print sum [i=1:10] i                         # 55
square(x) = 4/pi * sum [k=1:n] sin((2*k-1)*x)/(2*k-1)
plot n = 3, square(x), n = 15, square(x)
```

`NaN` is predefined, as `pi`: `plot NaN with boxes title "legend only"`.

In the HTML page a zoom does not resample: the samples are those of the original range.

On a [polar](#polar-plots) panel a function is r of `t`, sampled over `trange` (a full turn by default) as gnuplot:
`plot 1 + cos(t)`.

### Sampled pseudo-files `'+'` and `'++'`

```gnuplot
plot '+' using 1:(sin($1)):(sin($1)+0.3) with filledcurves
plot sample [t=0:2*pi:0.25] '+' using (3*cos(t)):(sin(t)) with linespoints
set urange [-2:2]; set vrange [-2:2]
plot '++' using 1:2:($2*0.4):(-$1*0.4) with vectors
```

As gnuplot 6.0, the pseudo-file `'+'` is a data file of one column, the samples of a variable: `set samples` values
evenly over the item's sampling range, else over `trange` in parametric and polar modes or when it is set, else over
the x range (the `xrange` ends where set, else the extent of the data plotted before it in the same command, else
[-10:10]; evenly in log x on a log x axis). The variable is the dummy (`x`, or the one of `set dummy`), and its value
is that of column 1 in the `using` expressions: `'+' using 1:(f(x))`. An item's sampling range names it and may give
the interval: `[t=-3:25:1.5] '+' using (t):(f(t))` samples from -3 by 1.5 while inside the range. Before the first
item the range follows the keyword `sample`, else it would be the plot's x range: `plot sample [i=1:10:1] '+' ...`.

`'++'` is a grid of two columns, u and v: `set samples` values over `urange`, by `set isosamples` (its second value)
values over `vrange` (both [-5:5] by default), v from its maximum down, the scan lines apart (a blank line). The
variables are `u` and `v`, or those its two ranges name: `sample [a=0:2:0.5][b=-1:1:0.5] '++' using (a):(b):(a*b)`.
`unset urange`, `unset vrange` and `unset trange` restore the defaults.

## Parametric plots

```gnuplot
set parametric; set trange [0:2*pi]
plot sin(3*t), cos(2*t) t 'Lissajous', [0:1] t, t**2
plot [0:pi] [-2:2] [-2:2] 2*cos(t), sin(t)     # [t] [x] [y]
unset parametric
```

`set parametric` makes a function item a pair `x(t), y(t)`, its options after the second expression, sampled at
`set samples` values of `t` over `trange` ([-5:5] by default, as gnuplot); the first inline range is the one of `t`,
then x and y. The automatic title is the pair as written; data items are as they are. `unset parametric` and `reset`
go back to functions of x.

## Clipping

As gnuplot, a line segment with one end outside the plot area is drawn up to the border (`set clip one`, the default)
and one with both ends outside is not drawn at all (`unset clip two`, the default: no line down the asymptotes of
`tan(x)`); `set clip two` draws its visible part, `unset clip one` leaves out the first kind too. `set clip points`
hides the markers that cross the border (bare `set clip` is `set clip points`, bare `unset clip` turns all three off).
Departure: without `clip points` a marker crossing the border is cut at it, where gnuplot draws it whole. `set clip
radial` (polar) is accepted.

## Special functions

gnuplot 6.0's real special functions, with its own algorithms (ports of its C code), so their values are gnuplot's
to the last digit:

```gnuplot
plot [0:20] besj0(x), besj1(x), besjn(2, x)
plot [-3:3] erf(x), norm(x), invnorm(norm(x))
print gamma(4.5), lgamma(100), igamma(2, 1), ibeta(2, 3, 0.4), lambertw(1), EllipticK(0.5)
```

| Functions | |
|---|---|
| `round(x)` | the nearest integer, halves away from zero |
| `cbrt(x)`, `asinh(x)`, `acosh(x)`, `atanh(x)` | cube root, inverse hyperbolic functions |
| `erf(x)`, `erfc(x)`, `inverf(y)` | the error function, its complement, its inverse |
| `norm(x)`, `invnorm(p)` | the normal distribution function and its inverse |
| `gamma(x)`, `lgamma(x)` | Γ and ln \|Γ\| |
| `igamma(a, x)`, `uigamma(a, x)`, `invigamma(a, p)` | the regularized incomplete gamma functions, lower and upper, and the inverse of the lower |
| `ibeta(a, b, x)`, `invibeta(a, b, p)` | the regularized incomplete beta function and its inverse |
| `besj0(x)`, `besj1(x)`, `besjn(n, x)`, `besy0(x)`, `besy1(x)`, `besyn(n, x)` | Bessel functions of the first and second kind |
| `besi0(x)`, `besi1(x)`, `besin(n, x)` | modified Bessel functions of the first kind |
| `lambertw(x)` | the principal branch of Lambert's W |
| `airy(x)` | the Airy function Ai |
| `expint(n, x)` | the exponential integral E<sub>n</sub> |
| `EllipticK(k)`, `EllipticE(k)`, `EllipticPi(n, k)` | the complete elliptic integrals |
| `voigt(x, y)` | the Voigt profile |
| `zeta(s)` | Riemann's ζ |
| `SynchrotronF(x)` | the synchrotron function |

The orders `n` of `besjn`, `besyn`, `besin` and `expint` must be integers (`besjn(2.0, x)` is an error), as gnuplot.
Outside its domain a function is undefined, a gap in a plot, as gnuplot's undefined value; so are the results gnuplot
gives as complex numbers (`acosh(0.5)`) or as infinities, foresight's values being finite real numbers. The complex
functions of gnuplot (`imag`, `arg`, `Ai`, `BesselJ`, ...) and those of libcerf (`VP`, `erfi`, `FresnelC`, ...) are not
supported. Built with gfortran the values are gnuplot's bit for bit; other compilers' mathematical libraries
(nvfortran's) differ by a few units in the last place in some ranges.

## Smoothing

`smooth FILTER` replaces the points of a data item by a filtered series, as gnuplot computes it. Each run of points
(a block of the file, ended also by an undefined point or by a value not placeable on a log axis) is sorted by x, and
its points of equal x are merged into one:

| Filter | y of the merged point |
|---|---|
| `unique` | the mean of their y |
| `frequency` | the sum of their y: with `using (BIN):(1)`, a histogram ([`bins`](#bins) bins the values itself) |
| `fnormal` | `frequency` divided by the sum of y over the whole item |
| `cumulative` | the sum of y up to that x, within the run |
| `cnormal` | `cumulative` divided by the sum of y over the whole item: an empirical distribution |

```gnuplot
plot 'run.dat' u 1:2 smooth unique                              # iterations repeated by a restart: averaged
plot 'run.dat' u (floor($5/0.02)*0.02):(1) smooth frequency     # histogram of column 5, bins 0.02 wide
plot 'run.dat' u 5:(1) smooth cnormal                           # its empirical distribution
```

The [cookbook](/manual/cookbook#histogram-and-distribution) draws the last two.

The curve filters replace each run by `set samples` points (100 by default), as gnuplot 6.0 computes them:

| Filter | Curve |
|---|---|
| `csplines` | the natural cubic spline through the points sorted and merged as above (at least 3), sampled from the first x to the last within the x range |
| `acsplines` | the smoothing spline of Reinsch through them (at least 4): `using X:Y:W` weights each point, larger weights draw the curve closer (1 without) |
| `bezier` | the Bézier curve with the points as control points, in the file order: it starts and ends on the first and last point |
| `sbezier` | the same after sorting and merging the points |
| `mcsplines` | the monotone cubic spline of Fritsch and Carlson through the points sorted and merged (at least 2): no overshoot, it rises and falls only where the points do; sampled at the points and at max(`set samples`, 2n) points between the first and last x within the x range; of the first block of the item only, as gnuplot 6.0 |
| `kdensity` [`bandwidth B`] | the Gaussian kernel density of the x values weighted by y, over the x range: `using X:(1)`, or `using X` alone, for a density of counts; the bandwidth is gnuplot's default, (4/3n)^(1/5) times the standard deviation of x, unless given |

```gnuplot
plot 'run.dat' u 1:5 smooth csplines                  # a spline through the drag coefficient
plot 'run.dat' u 1:5:(0.1) smooth acsplines           # smoothed: small weights, a smooth curve
plot 'timestep.dat' smooth mcsplines                  # a time step through its plateaus, never beyond them
plot 'run.dat' u 5:(1) smooth kdensity bandwidth 0.01 # the distribution of column 5
```

The runs stay separate lines. `smooth` applies to `lines`, `points` and `linespoints`; with error bars or on a
function it is an error (gnuplot ignores the extra columns, or the filter); `acsplines` reads a third column as the
weights. A single `using` column (or a file of one column) is x, each point of weight 1, for `frequency` and
`kdensity`, as gnuplot: `using 5 smooth kdensity` is `using 5:(1) smooth kdensity`; the other filters read it as y
at the point numbers. `unwrap`, `path` and the others are [not supported](#not-supported).

### Bins

`bins` sorts the x values into bins of equal width and plots each bin as one point at its centre, as gnuplot 6.0:

```gnuplot
plot 'FILE' using X[:Y] bins[=N] [binrange [LO:HI]] [binwidth=W] [binvalue=sum|avg] [with STYLE]
plot 'FILE' using X[:Y] smooth bins[=N] ...       # the same
```

| Option | Bins |
|---|---|
| `bins` | `set samples` bins (100 by default) |
| `bins=N` | N bins (at least 2), the first centred on the smallest x, the last on the largest |
| `binrange [LO:HI]` | the centres of the first and last bins at LO and HI, whatever the data: values beyond the outer edges fall in no bin |
| `binwidth=W` | bins W wide, as few as span the range, centred on it (N is then ignored) |
| `binvalue=avg` | the mean of the y of each bin (two or more points), not their sum |

With one column each value counts 1: a histogram. With `using X:Y` each point adds its y to its bin. A value on the
boundary of two bins falls in the upper one; `set xrange` does not change which bin a point falls in. The x
autoscale reaches the outer edges of the bins and the y autoscale includes 0, as gnuplot. The style is the data style
(`set style data`, `lines` by default): `with boxes` draws a histogram whose boxes touch. `bins` does not go with
`smooth` nor `lc variable`, and needs `using X` or `using X:Y`; its options read numbers, not expressions.

```gnuplot
plot 'steptimes.dat' u 2 bins binwidth=0.02 with boxes        # wall times per step, 0.02 s bins
plot 'run.dat' u 5:2 bins=20 binvalue=avg with histeps        # the mean residual per drag coefficient bin
```

The [cookbook](/manual/cookbook#a-histogram-of-a-sample) overlays the density of the same sample.

## Fit

```gnuplot
f(x) = c*x**p
fit f(x) 'convergence.dat' using 1:2 via c, p                 # c and p fitted, c_err, p_err, FIT_* set
fit [0.01:0.1] a*x + b 'run.dat' using 1:2:3 via a, b         # an x range, the third column the errors of y
fit a*x A using 1:2 via a                                     # an array: index and value
```

`fit` is gnuplot 6.0's: nonlinear least squares by the Marquardt-Levenberg method, translated from gnuplot's sources
step by step (prescaled parameters, one-sided derivatives, Givens rotations, the same lambda updates and stopping
rule), so the parameters, their errors and the iterations agree with gnuplot's to its printed digits.

- The model is any expression of `x`, user functions included; the parameters after `via` are user variables: an
  undefined one starts at 1. After the fit they hold the fitted values.
- Modifiers: `using X:Y` (the default `1:2`) or `X:Y:YERROR` (`yerrors` optional), the weights `1/YERROR**2`;
  `unitweights` with two columns (three are gnuplot's x:y:z, refused); `yerror`, `zerror`, `zerrors` as `yerrors`;
  `index`, `every`; a range `[min:max]` before the function keeps the points with x inside.
- Set after a fit: *name*`_err`, the asymptotic standard errors (scaled by sqrt(WSSR/ndf), gnuplot's `errorscaling`),
  `FIT_NDF`, `FIT_WSSR`, `FIT_STDFIT`, `FIT_P`, `FIT_NITER`, `FIT_CONVERGED`. `FIT_LIMIT` and `FIT_MAXITER`, when
  defined, set the stopping change and the most iterations.
- On failure (a singular matrix, an undefined model value) the statement fails with gnuplot's message and the
  parameters keep their values.

**Silent by default**, unlike gnuplot, which reports on the terminal and in `fit.log`:

| `set fit` option | Effect |
|---|---|
| `quiet` (default) \| `results` \| `brief` | no report; gnuplot's results on the standard error; with the progress lines too |
| `logfile "file"` \| `nologfile` (default; `log`, `nolog` abbreviate them) | append the full report to a file; no log file |
| `limit E` \| `limit_abs E` | stop when chi-square changes by less than E times itself (1e-5) plus `limit_abs` (0) |
| `maxiter N` \| `maxiter default` | at most N iterations; no limit |
| `start-lambda L` \| `lambda-factor F` | the first lambda (gnuplot's estimate by default); its factor (10) |
| [`no`]`prescale` \| [`no`]`errorscaling` \| [`no`]`errorvariables` | parameters scaled by their initial values; errors scaled by the reduced chi-square; *name*`_err` set (all on) |

Not supported: `via 'file'`, more than one independent variable, `set fit verbose`, `set fit covariancevariables`.
The [cookbook](/manual/cookbook#fitting-a-model) fits an order of accuracy; Fortran programs call `fit` directly
([library](library.md#fitting-a-model)).

## Stats

```gnuplot
stats 'run.dat' u 5 every ::100 name 'cd'           # cd_mean, cd_stddev, cd_min, ... of the last iterations
stats [0:1000] 'run.dat' u 1:5 output               # STATS_slope, STATS_correlation, ...; the report printed
plot 'run.dat' u 1:5 w l, cd_mean w l dt 2 t sprintf('mean %.4f', cd_mean)
```

`stats` is gnuplot 6.0's, translated from its sources: of one column the mean, the population and sample standard
deviations, skewness, kurtosis, mean absolute deviation, their standard errors, sum, sum of squares, minimum and
maximum with their 0-based index, median and quartiles; of two columns (`using N:M`) these of each (`_x`, `_y`) and the
least squares line (slope, intercept, their errors), the correlation, the sum of the products and the x of the y
minimum and maximum. They are set as gnuplot's variables, `STATS_mean` ... `STATS_slope`, or with `name "P"` as
`P_mean` ...; the variables of an earlier `stats` with the same prefix are forgotten first. `STATS_records`,
`STATS_invalid` (a used value undefined), `STATS_outofrange` (outside the ranges `[x] [y]` before the file),
`STATS_blank`, `STATS_blocks`, `STATS_headers` and `STATS_columns` count the file.

**Silent by default**, as `fit` (gnuplot prints its report; `nooutput` is gnuplot's silence, accepted; `prefix "P"`
is `name "P"`): `output` writes gnuplot's report where
[print](#print) writes, its screen layout on the standard error or output, its name-tab-value lines in a `set print`
file. A missing file is not an error, as gnuplot's (a script may test `exists("STATS_records")`). Modifiers: `using`
(as plot's; without it the first two columns if the first line has two), `index`, `every`. Not supported: `matrix`,
`name columnheader`, the voxel grid form.

## Second y axis

```gnuplot
set logscale y
set ytics nomirror; set y2tics
set ylabel 'residual'; set y2label 'coefficient'
plot 'run.dat' u 1:2 t 'residual', '' u 1:3 axes x1y2 t 'cd'
```

The items plotted `axes x1y2` are scaled on the second y axis, autoscaled on them alone (on the points inside the x
range), with its own `y2range`, `logscale y2` and `format y2`. As in gnuplot, the y2 ticks and labels are off until
`set y2tics`: they go on the right border, not mirrored on the left (`set y2tics mirror` does). The y ticks stay
mirrored on the right unless `set ytics nomirror`. The axis is drawn only when it has data, or a range fixed at both
ends; `y2label` reads upward on the right, as `ylabel` on the left. In the HTML page the y2 ticks follow the zoom and
the readout shows the y2 value too.

## Second x axis

```gnuplot
set xrange [0:100]; set xtics nomirror; set xlabel 'frequency [Hz]'
set x2range [0:2]; set x2tics 0.25; set x2label 'Strouhal number'
plot 'spectrum.dat' w impulses
```

The x2 axis is the top border's, as the y2 axis is the right one's: `axes x2y1` (or `x2y2`) scales an item on it,
autoscaled on those items alone, with its own `x2range`, `logscale x2`, `format x2`, `mx2tics`. Its ticks and labels
are off until `set x2tics`, not mirrored at the bottom (`set x2tics mirror` does); `x2label` goes above the tick
labels. As in gnuplot, `set x2tics` with no item on the axis spans the range of the first x axis, so a fixed
`x2range` relabels the top border in another unit, as above; a function plotted on x2 is sampled over the x2 range.
The axis is drawn when it has ticks, items or a range fixed at both ends. In the HTML page the x2 ticks follow the
zoom and the readout shows the x2 value too. gnuplot's `set link x2 via ... inverse ...` is
[not supported](#not-supported).

## Column headers

```gnuplot
set datafile separator comma
plot 'run.csv' using 1:"residual" title columnhead, '' using "iteration":(column("cd")*1e3)
set key autotitle columnhead       # every untitled item takes the header of its y column
```

As in gnuplot, the first row of each dataset is a header as soon as an item uses it: a quoted name in `using` (also
in `column("name")`), `title columnhead`, or `set key autotitle columnhead`. It is then neither a point nor counted by
`$0`; otherwise it is an ordinary row, whose words are missing values. A name is looked up in the header of the
dataset each row belongs to; a name no selected dataset has is an error. `title columnhead` takes the header of the
first column the y field reads (`($3*2)` gives the header of column 3), `columnhead(N)` of column `N`; no header, no
title. Quoted header cells may hold blanks: `"the res"`. `set key noautotitle` leaves untitled items, functions
included, out of the key. `set datafile columnheaders` makes the first row of every dataset a header, `notitle
columnhead` that of one item.

## Ticks and label formats

```gnuplot
set xtics 0.5            # a tick every 0.5
set xtics 0,5,30         # from 0 to 30 every 5
set ytics 0, ymax / 10.0, ymax          # expressions, blanks and all (a computed value to 12 digits)
set ytics 10             # on a log axis the step is a factor: 1, 10, 100, ...
unset xtics              # no ticks, no labels (nor their margin), no grid lines
set format y "%.1e"      # 1.0e-03
set format x "%g s"      # 0.5 s
set format y "%h"        # like %g, the exponent as a superscript: 1x10⁻⁵
set xtics ("Jan" 1, "Feb" 2, "Mar" 3)   # an explicit list replaces the ticks
set ytics add ("limit" 7.5)             # ... or is added to them
set tics out nomirror scale 1.5, 0.75   # every axis: outward, not mirrored, longer ticks
unset tics                              # no ticks on any axis
```

`set tics` sets the options of every axis at once, as gnuplot: `mirror`/`nomirror`, `in`/`out`, `scale MAJOR[,MINOR]`
(`scale default`: 1, 0.5), `axis`/`border`, `rangelimited`, and the label options below; bare, it turns the x and y
ticks on; `unset tics` turns them all off; `set ticscale` is the old form of the scale. The scale multiplies the tick
lengths (6 px major, foresight's; gnuplot's svg draws 9), `MINOR` half `MAJOR` when absent, `scale 0` draws no ticks
and keeps the labels; each axis takes it too (`set xtics scale 2`). Not supported in `set tics`: `front`, `back`,
`rotate`.

The tick labels of an axis (`set xtics ...`) or of every axis (`set tics ...`) take gnuplot's options: `format "..."`
(the axis' `set format`), `font "..."` (read and ignored: foresight has one font), `offset X[,Y]` and `nooffset` (a
shift in characters, 0.6 font sizes wide and 1 high, y up; gnuplot's svg characters are 0.7 by 1.5) and
`textcolor`/`tc COLOR`. `set tics` changes only the options it names.

```gnuplot
set xtics 1 offset 0,-0.5 tc rgb "#b3163f" format "%.1f"   # the x labels lower, red, one decimal
set tics font ",8" tc "gray40"                              # every axis' labels gray
```

`set xtics axis` draws the x ticks and their labels on the x axis (y = 0) instead of the bottom border, `set ytics
axis` the y ones on x = 0, as gnuplot: not mirrored, the plot area taking no margin for their labels, when the other
axis is linear with 0 in its range (else on the border); `border` puts them back. `rangelimited` keeps the ticks of an
axis within the range of its data and shortens that side of the border to it, `norangelimit` undoes it. The viewer
keeps both through a zoom.

```gnuplot
set xtics axis; set ytics axis                  # ticks on the axes through the origin
set border 3; set tics nomirror rangelimited    # Tufte's range frame
```

Automatic ticks step as gnuplot's: by the axis range only, whatever the size of the plot (0.5 on [-2:2], 0.2 on
[0:1], 2 on [0:13], 20 on [0:100]); log axes label every 1, 2, 5, ... decades by the same rule (every 2 decades on
[1:1e10]). Within a single decade foresight labels the 2..9 multiples where gnuplot shows the decade alone.

As in gnuplot, `set xtics` without positions (alone, or with only `mirror`/`nomirror`) keeps the last ones and turns
the ticks back on after `unset xtics`; `set xtics auto` returns to automatic ticks.

As in gnuplot, an autoscaled end extends outward to a multiple of the step, unless it lies below `START` or beyond
`END`; after `unset xtics` it does not extend at all. Log axes always extend to whole decades.

### Offsets

```gnuplot
set offsets 0.5, 0.5, 1, 1                    # left, right, top, bottom: x and y units
set offsets graph 0.05, graph 0.05, 0, 0      # fractions of the range
set autoscale noextend; set offsets 0, 0, 2, 2; plot sin(x)    # y [-3:3]
```

`set offsets L, R, T, B` moves the autoscaled ends of x and y out, as gnuplot: in axis units, or after `graph` by
fractions of the range; fixed ends stay, the extension to the ticks comes after, and functions are sampled on the
range before the offsets. On a log axis only `graph` offsets apply, in decades. `unset offsets` removes them.

The formats are gnuplot's: text with conversions `%[flags][width][.precision]type`, all applied to the same value,
and `%%` for `%`; flags `-`, `+`, space, `0`, `#`.

| Conversion | |
|---|---|
| `f`, `e`, `E`, `g`, `G` | C's printf |
| `h`, `H` | `g` with the exponent as a superscript: `x10` (`H`: `*10`) |
| `t` (`l`) | the mantissa to base 10, printed as `%f`: `%.1t` of 3456 is `3.5` (`l`: to the log base, 10 in foresight) |
| `T` (`L`) | the power of 10 (of the log base): `10^{%T}` labels a log axis `10³` with [enhanced text](#enhanced-text) |
| `s`, `S`, `c` | the mantissa to a power of 1000, that power, its SI prefix: `"%.0s %cHz"` is `2 MHz` |
| `b`, `B` | the mantissa to a power of 1024 and its binary prefix: `"%.1b %BB"` is `1.5 kiB` |
| `P` | the multiple of π: `"%.1Pπ"` |
| `x`, `X`, `o` | the integer part in hexadecimal or octal |

The value formatted is the exact decimal of the tick, so `set xtics 0.1` never shows `0.30000000000000004`, and a
rounding tie of the C conversions goes to the even digit, as printf does (`0.125` with `%.2f` is `0.12`). The
mantissas and powers are gnuplot's, computed in doubles as its `mant_exp`: a mantissa that rounds to the base moves to
the next power (`%.0t` of 9.6 is `1` and `%T` `1`), and on a decimal tie its rounding follows the C library's `pow`
(`%.1t` of 12.5 is `1.3` with glibc, as gnuplot).

```gnuplot
set logscale y; set format y "10^{%T}"     # 10^0, 10^1, ... as superscripts
set format x "%.0s %cHz"                   # 0 Hz, 500 kHz, 1 MHz
set format x "%.1t·10^{%T}"                # 3.5·10^3
```

An explicit list `("label" pos level, ...)` places the ticks itself, as gnuplot: each item is an optional quoted
label, a position (a constant expression: `2*pi`, user variables) and an optional level, `1` for a minor tick
(unlabelled, shorter). A label is printed as written, or used as the format of the position when it holds a conversion
(`"%.1f s" 2` is `2.0 s`); without a label the position gets the axis label (`set format`). Items outside the range are
left out, and a list alone does not extend an autoscaled end to a tick grid. Without `add` the list replaces the ticks
and any earlier list; with `add` it joins them, an item replacing the tick at its position. Positions without `add`
(`set xtics 2`, `set xtics auto`) and `unset xtics` forget the list; `set xtics add 2` keeps it beside the new step.

```gnuplot
set xtics ("Jan" 1, "" 1.5 1, "Feb" 2, "" 2.5 1, "Mar" 3)   # months, a minor tick between them
set ytics add ("limit" 7.5, "%.2f mm" 4.25)                 # the automatic ticks and two more
```

Minor ticks divide each interval between consecutive major ticks: `set mxtics N` in `N` parts, `set mxtics` by
gnuplot's count (2 when the step leads with 2, 0.2 or 20, else 5; 9 on log axes), linearly in value on log axes too
(`set mytics 4` puts them at 3.25, 5.5, 7.75 within each decade), as gnuplot. They cover the partial intervals at the
ends of an automatic step, stay within `START` and `END` of a fixed one, and an explicit list alone has none. By
default linear axes have none and log axes 9 intervals between majors, as gnuplot: the 2..9 multiples of each decade,
and linear intervals when the majors are several decades apart or a factor apart (`set ytics 100`); `unset mxtics`
removes them, `set mxtics default` restores them.

```gnuplot
set mxtics               # gnuplot's count: 5 per step of 1
set mytics 4             # 4 intervals between major ticks
unset mytics             # none, also the 2..9 of a log axis
```

`out` points the ticks (and their mirrors) outward, the plot area making room for them, `in` back inward (x, y, y2 and x2
ticks). `rotate` turns the x tick labels by 90 degrees, reading upward and right-justified; `rotate by A` by `A`
degrees counterclockwise, left-justified unless `left`, `right` or `center` follows; `norotate` restores them. As in
gnuplot, the glyphs of a rotated label are centred on its tick and a left-justified one at a positive angle runs up
into the plot: give it `right`, or a negative angle. The bottom margin grows to the labels that hang below the axis.
`set x2tics rotate` turns the x2 tick labels the same way above the plot: from their tick, reading away from it
(`rotate` is 90 degrees, left-justified there, as gnuplot), the top margin growing to them and the right one to the
reach of the last label. Unlike gnuplot, a negative angle keeps them above the border (gnuplot lets them run into
the plot). Text devices write the labels upright, as gnuplot's dumb terminal.

```gnuplot
set xtics rotate by 30 right out nomirror   # long category names, outward ticks
set ytics out
```

All these settings follow the zoom in the HTML page: the viewer places and formats the ticks by the same rules, the
list items keeping the labels they were drawn with.

### Text labels on any axis

```gnuplot
plot 'stations.dat' u 3:0:ytic(5) w lp pi 2 pt 7     # the y ticks named by column 5
set x2tics; plot 'run.dat' u 1:2:x2tic(6)             # x2 labels need x2 ticks on, as gnuplot
```

<Plot name="cb_ytic" svg :width="560" :height="320" />

`xtic(N)` names the x ticks at the abscissae, `x2tic(N)` the x2 ones, `ytic(N)` and `y2tic(N)` the y and y2 ticks at
the ordinates: the labels of a plot replace that axis' ticks, as gnuplot 6.0; the x2 and y2 ones show once `set
x2tics`/`set y2tics` turn the axis ticks on (gnuplot draws none otherwise). One label field per item, the last
`using` field. The HTML page keeps the x labels through a zoom; the other axes show numeric ticks while zoomed.

## Key

```gnuplot
set key bottom left box
set key center           # centred both ways
set key top center       # top, centred horizontally
set key outside          # right of the plot, top aligned
set key outside left bottom
set key below            # a row below the plot (above: over it), wrapping when the panel is narrow
set key inside           # back inside, keeping the rows
set key lmargin          # in the left margin (rmargin: the right one), aligned with the top of the plot
set key bmargin left     # below the plot, at its left (tmargin: above it), keeping the layout
set key at 60, 1e-2 left top          # its top left corner at x = 60, y = 0.01
set key at graph 0.5, 0.5 center      # centred on the plot area
set key at screen 0.98, screen 0.98   # its top right corner near the top right of the page
```

Position words apply in order; `center` centres the direction not named yet, as in gnuplot. Titles are right-aligned
with their sample on the right. Inside, the key lies in the plot area. `outside` puts it in the left or right margin,
aligned with the top, centre or bottom of the plot; centred horizontally, above (`top`) or below (`bottom`) the
plot; centred both ways it stays inside, as gnuplot. `below` and `above` centre a row of entries under the x label or
between the title and the plot (`below left` aligns it to the left); `horizontal` and `vertical` choose rows or a
column anywhere. The plot shrinks to make room for a key outside it.

The margins place it as gnuplot: `lmargin` and `rmargin` are `outside` on that side, aligned with the top, centre or
bottom of the plot; `tmargin` and `bmargin` above and below the plot, at its left, centre or right, keeping the
layout (`above` and `below` also centre it and lay it out in rows).

`at POSITION` places the key anywhere, its box aligned on the position as a text: `left`, `right`, `center` put the
left edge, the right edge or the centre of the box there, `top`, `bottom`, `center` its top, bottom or centre (top
right by default). POSITION is `[SYSTEM] X, [SYSTEM] Y`, SYSTEM one of `first` (the x and y values, the default),
`second` (x2 and y2), `graph` (0 to 1 across the plot area, from the bottom left), `screen` (0 to 1 across the page);
y takes the system of x unless given. The plot does not shrink for it. Position words keep `at`; `inside`,
`outside`, a margin, `below` and `above` cancel it, as gnuplot. Not supported: `character` and `polar` coordinates,
`fixed`, `spacing`, `maxcols`, `maxrows`.

```gnuplot
set key box opaque reverse Left invert samplen 2 width 1 title "runs" offset 0,-1
```

<Plot name="cb_key_layout" svg :width="560" :height="320" />

As gnuplot: `reverse` puts the samples left of the titles, `Left` and `Right` justify the titles, `invert` lists the
entries last to first, `opaque` paints the key area with the page color over the plot (its box then hides what passes
under it), `samplen L` makes the samples `L` characters long, `width W` adds `W` characters to the titles,
`offset X,Y` shifts the key by characters (y up) and `title "text"` puts a row over the entries; `default` restores
them all. A character is foresight's cell, 0.6 font sizes wide and 1 high. `font` is read and ignored (foresight has one
font); `noenhanced` writes the key's texts as they are, not as [enhanced text](#enhanced-text).

```gnuplot
set key box lt 4 lw 2 maxrows 3 spacing 1.5 tc variable   # 3 rows a column, titles in their series' colors
set key horizontal maxcols 2 height 1                     # at most 2 entries a row, a character taller
```

`spacing S` sets the rows S apart (in rows, 1 by default), `height H` adds H characters to the key, `maxrows N` gives a
vertical key N rows and as many columns as it needs, filled top down, and `maxcols N` (`maxcolumns`) caps the columns
of a horizontal key (`auto`, as many as fit, by default), as gnuplot; `columns N` lays the key out in exactly N
columns, filled top down (gnuplot's; `maxcol`, `maxrow` abbreviate). `textcolor`/`tc COLOR` writes the titles in a
color, `tc variable` each in the color of its series. After `box`, `lt`, `lw`, `lc`, `dt` and `ls` set its line.

```gnuplot
unset key; plot for [c in "A B C"] 'run.dat' using 1:(column(c)) title columnhead at end
plot 'a.dat' title "left" at 0.75, 0.18, 'b.dat' title at 0.75, 0.15   # one key area for several panels
```

As gnuplot 6.0, `title ... at end` writes the item's title after its last point, left-justified, and `at beginning`
before its first point, right-justified, with or without the key; `at X,Y` (screen coordinates, `screen` optional)
draws a key entry there, the title right-justified at the position and its sample after it, while the key is shown.
These titles leave the key; `title at ...` alone places the automatic title.
`set key auto` is `autotitle`, `fixed` (the key of `splot`) is accepted as it is. `set key default` resets them all.

## Grid, zero axes and border

```gnuplot
set mxtics 5; set mytics 5
set grid x y mx my lc "gray" lw 0.5 dt 3     # major and minor lines, solid gray dots
set grid front                               # over the data
set xzeroaxis lw 1.5; set yzeroaxis          # lines at y = 0 and x = 0, gnuplot's black dots by default
set border 3 lw 1.5                          # the left and bottom sides, thicker
set autoscale xfix                           # x ends at the data, not extended to the ticks
```

<Plot name="cb_grid_zero" svg :width="560" :height="320" />

`set grid` takes the lines to draw as gnuplot: `x`, `y`, `x2`, `y2` at the major ticks and `mx`, `my` at the minor
ones (also written `xtics`, `mxtics`, ...), each turned off with `no` (`noy`); the named lines change, the others are
kept, and with none the x and y lines are drawn. `front` draws the grid over the data, `back` and `layerdefault`
behind it; `lt 0` is foresight's dots (the default), `lt -1` the border's solid black, `lt N` the color of linetype
N, and `lc`, `lw`, `dt` set the line. The HTML viewer redraws the same lines in the same style when zoomed.

`set zeroaxis` (`xzeroaxis`: the line y = 0, `yzeroaxis`: x = 0, `x2zeroaxis`, `y2zeroaxis`) draws lines at the zero
of the axes, behind the data and zoomed with it, gnuplot's black dots by default, with the same line options.
`set border` takes them too, and `front` (foresight draws the border over the data, gnuplot's default).

`set autoscale` autoscales the named axes again (`x`, `y`, `x2`, `y2`, `cb`, `xy`; `xmin`, `ymax`: one end; all
without one); `fix` and `noextend` (and `xfix`, ...) keep the autoscaled ends at the data instead of extending them to
the ticks, as `set xrange [...] noextend`. `set xrange []` keeps the range; `noreverse` and `nowriteback` are accepted.
Not supported: `unset autoscale`, `keepfix` with effect, `writeback`, `restore`, autoscale limits (`[*<-5:5<*]`).

## Styles

```gnuplot
set style data linespoints
set style line 1 lc rgb '#e51e10' lw 2 dt 2
plot 'run.dat' u 1:2 ls 1 t 'residual', '' u 1:3 lt 3 t 'momentum'
```

`ls N` of an undefined style takes the color of linetype `N`, as gnuplot.

`set style data filledcurves OPTIONS` and `set style function filledcurves OPTIONS` (`y=0`, `y1=0`, `x1`, `below`,
...) give their options to the filledcurves items of data or functions given none, the default style or an explicit
`with filledcurves`, as gnuplot; options after another style are refused, as gnuplot.

Style names and `smooth` filters take gnuplot's abbreviations, read from its keyword tables in their order: `l`,
`line`, `p`, `point`, `lp`, `e` (yerrorbars), `errorl` (yerrorlines), `his` (histeps), `hist` (histograms), ...;
`smooth f` (frequency), `cum` (cumulative), `mcs` (mcsplines), `fnor` (fnormal), ...

The linetype colors cycle through gnuplot's sequence: `set colorsequence default` (dark violet, green, sky blue, orange,
yellow, blue, red, black), `podo` (black, orange, sky blue, green, yellow, blue, vermilion, pink) or `classic` (the
13 colors of gnuplot's svg terminal, red, green, blue, cyan, ...). Beyond gnuplot, `set colorsequence batlowS 6` takes
the first 6 colors of a categorical order of the Scientific colour maps (`actonS` ... `turkuS`, 22 orders of 100
colors of the [named palettes](#named-palettes), the most distinct first; 8 by default; any case). The sequence
applies to the series added after it and carries over to the next multiplot panels.

```gnuplot
set linetype 1 lc "dark-violet" lw 2 pt 7
set for [i = 1:3] linetype 10 + i lc "black"
set linetype cycle 4
```

`set linetype N` redefines linetype N, as gnuplot: its color among the linetype colors, its width, dash, point type and
size the defaults of the series of that linetype (`lc`, `lw`, `dt`, `pt`, `ps`; up to linetype 128). The
redefinitions are persistent: `reset` keeps them (`reset session` too, as the color sequence). `set linetype cycle N`
reuses the first N colors for the higher linetypes. An item's `lt N` takes the color of linetype N; `lt rgb COLOR`
(and `lt palette`) is a line color, as `lc`. A linetype color may have an alpha channel (`set linetype 9 lc
"#80bb33bb"`).

### Color names

```gnuplot
plot sin(x) lc 'green', cos(x) lc rgb 'dark-green', -sin(x) lc rgb '#c04000', -cos(x) lc rgb '#8000c0ff'
```

A color string (after `lc`, `rgb`, `fc`, `tc`, in every command) is read as gnuplot 6.0 reads it: one of its 111 names
(`show colornames`: `red`, `dark-green`, `light-goldenrod`, `gray0` ... `gray100`, case sensitive), or `#` / `0x` and
the hexadecimal number `0xRRGGBB` or `0xAARRGGBB`, the alpha `AA` from 0 (opaque) to 255 (transparent). The names
take gnuplot's colors, not the SVG ones of the same name: `green` is `#00ff00` (SVG's `#008000`), `gray` `#bebebe`,
`grey` `#c0c0c0`, `purple` `#c080ff`. A name not in the table is read as the first name that begins it, as gnuplot's
table lookup: `grey75` is `grey`. An SVG name gnuplot does not know (`darkgreen`, `Green`) is an error, as in
gnuplot: `unrecognized color name "darkgreen" and not a string "#AARRGGBB" or "0xAARRGGBB"`. After `rgb` a string
variable holding the color is read too (`Shade = "#80e0a080"; ... fc rgb Shade`). As gnuplot too, `#0f0`
is the number 0x0000f0, a blue, not CSS's short green. The [library](library) keeps SVG colors (`lc='green'` is
`#008000` there).

### Colors per point and from the palette

```gnuplot
plot 'run.dat' u 1:2:3 w lp lc variable          # linetype N of column 3 per point
plot 'run.dat' u 1:2:($3*65536) w p lc rgb var    # 24-bit 0xRRGGBB of the last column
plot 'run.dat' u 1:2:4 w l lc palette z           # column 4 through the palette, over the color axis
plot 'run.dat' u 1:2 w boxes lc palette frac 0.3  # one color: 30% along the palette
plot 'run.dat' u 1:2 w l lc palette cb 0.5        # one color: the value 0.5 of the color axis
```

| Color | Meaning |
|---|---|
| `lc variable` | the last `using` column is a linetype number per point, its color in the [color sequence](#styles) |
| `lc rgb variable` | the last `using` column is a color, `0xRRGGBB`, or `0xAARRGGBB` with AA the transparency (0 opaque, 255 invisible), as gnuplot |
| `lc palette` [`z`] | the last `using` column is a value per point, colored through the [palette](#images-and-palettes) over the color axis; the color axis spans these values (unless `set cbrange`) and the color box is drawn |
| `lc palette cb V` | one color for the item: the value V of the color axis (gnuplot's default [-10:10] when nothing sets or spans it) |
| `lc palette frac F` | one color for the item: the fraction F (0 to 1) of the palette |

As gnuplot, a line segment takes the color of its end point; a point whose palette value is undefined is not drawn,
nor the segment to it, but still counts for the autoscale.
The per-point forms (`variable`, `palette z`) apply to `lines`, `points`, `linespoints`, `impulses`, `vectors` and
`arrows` (`lc variable`
also to circles, ellipses, boxes, boxerrorbars, boxxyerror, candlesticks, financebars, histograms, `Y:COLOR`
included, filledcurves and polygons, a run of the last two in its first point's color), and not with `smooth` or
`bins`; `palette cb` and `frac` to every style but the readouts, the panel charts and `labels`, and to
functions; all of them in `set style line`. In the key, the line sample takes the color of the first point and the
point sample that of the last one, as gnuplot. Not supported: `lc palette NAME` (a named colormap of gnuplot 6).

## Lines, steps and impulses

```gnuplot
plot 'run.dat' u 1:2 w steps, '' u 1:2 w histeps, '' u 1:3:4 w yerrorlines
```

- `steps` joins the points horizontally then vertically, `fsteps` vertically then horizontally;
- `fillsteps` fills the area under `steps`: between two points the box from y = 0 (within the y range; the bottom of
  a log axis) to the first value, in the fill style (`set style fill solid`), as gnuplot; with an empty fill, the
  steps themselves;
- `histeps` draws a step around each point, its edges halfway to the neighbours (the end steps symmetric), from and
  back to y = 0 at the ends; unlike gnuplot the outer edges and 0 are in the autoscale, as for boxes;
- `impulses` draws a segment from y = 0 to each point, 0 included in the y autoscale (as gnuplot);
- `dots` draws a tiny dot per point (point type 0);
- `yerrorlines`, `xerrorlines`, `xyerrorlines` are `linespoints` with the error bars of the matching `errorbars`
  style, with the same `using` layouts.

Functions can be drawn with all of these but the error styles. As gnuplot, `his` abbreviates `histeps`; `histograms`
needs at least `hist`.

## Box, finance and boxplot styles

```gnuplot
set style fill solid 0.3
plot 'bench.dat' u 1:2:3 w boxerrorbars, '' u 1:4:5:6:7 w candlesticks whiskerbars 0.5
plot 'timings.dat' u (1):2:(0.5):1 w boxplot
```

| Style | `using` | Drawing |
|---|---|---|
| `boxerrorbars` | `x:y:ydelta`, `x:y:ydelta:width`, `x:y:ylow:yhigh:width` | a box from 0 (as `boxes`, a width <= 0 meaning `boxwidth`) with a y error bar |
| `boxxyerror` | `x:y:xdelta:ydelta`, `x:y:xlow:xhigh:ylow:yhigh` | a rectangle in the fill style |
| `candlesticks` | `x:open:low:high:close[:width]` (or `x:box_min:whisker_min:whisker_max:box_max`) | a box between open and close, whiskers to low and high; with an empty fill a box whose close is below its open is filled; `whiskerbars [F]` adds crossbars F box widths long |
| `financebars` | `x:open:low:high:close` | a line from low to high, a tick on the left at the open, on the right at the close |
| `boxplot` | `x:y[:width[:factor]]` | the quartiles of the y values as a box with the median line, whiskers to the farthest values within 1.5 interquartile ranges, the others as outliers (point type 7) |

As gnuplot, the candlestick width is `set boxwidth` or the 6th column, else a few pixels; financebars ticks are a few
pixels long. A **boxplot** summarizes all the values of its item at the x of the first row; a 4th `using` field, a
column number, names the level of each value (its text): one box per level, `separation` apart (1), named on the x axis
in order of appearance (`sorted`: alphabetical). The quartiles are gnuplot's: the value of rank n/4 (the mean of ranks
n/4 and n/4 + 1 when n/4 is whole); a level of fewer than 4 values draws nothing. `set style boxplot fraction 0.95`
has the whiskers span 95% of the values instead, `nooutliers` drops (and leaves out of the autoscale) the outliers,
`financebars` draws the boxplots as finance bars. The box width is the 3rd field, else `boxwidth`, else 0.5; the x
autoscale reaches a box width beyond the boxes, as gnuplot. Boxplots are computed when plotted: a watched script
recomputes them on each change of its data.

## Vectors, ellipses, polygons, labels and sectors

```gnuplot
plot 'flow.dat' u 1:2:3:4 w vectors filled head, '' u 1:2:5 w labels left offset 1,0 point pt 7
plot 'shapes.dat' u 1:2:3:4:5 w ellipses, 'blocks.dat' w polygons fs solid 0.3
set polar; set angles degrees; plot 'wind.dat' u 1:(0):(40):2 w sectors
```

| Style | `using` | Drawing |
|---|---|---|
| `vectors` | `x:y:xdelta:ydelta` | an arrow from x:y to x+xdelta:y+ydelta; after the style `head` (default), `heads`, `nohead`, `backhead`, `filled`, `empty`, `noborder` (filled), `size [first\|graph\|screen\|character] L,A` (head length, x axis values by default, and barb angle [deg]), `fixed`, `as N`\|`arrowstyle N` (the heads, fill, size, color and width of `set style arrow N`) |
| `arrows` | `x:y:length:angle` | an arrow of `length` (> 0: x units, the same on the page at any `angle` [deg]; in (-1, 0): a fraction of the plot width) |
| `ellipses` | `x:y`, `x:y:diameter`, `x:y:major:minor[:angle]` | an ellipse in the fill style, the major diameter in x units and the minor one in y units, rotated on the page (gnuplot `units xy`); without diameters (or a negative one) 5% x 3% of the plot |
| `polygons` | `x:y` | a closed polygon per block of the data (blocks end at single blank lines), in the fill style |
| `labels` | `x:y:column` | the text of the column at each point; `left`, `center`, `right`, `rotate by A`, `offset X,Y` (characters), `point` (with `pt`, `ps`), `tc "color"` anywhere in the item |
| `sectors` | `azimuth:radius:angle:width[:x0:y0]` | the annular sector from the azimuth over `angle`, from `radius` over `width`, about x0:y0 (0:0), angles in the `set angles` unit oriented by `set theta`; on a polar panel azimuth:radius are theta:r |

Arrowheads are gnuplot's (18 px, 15 degrees) unless `size` is given and, as label texts, keep their pixel size: in
the HTML page a zoom moves them with the data. `fixed` is read: foresight's heads never shrink on short arrows (gnuplot
shrinks them without it). `lc variable`, `lc rgb variable` (0xAARRGGBB, AA the transparency) and `lc palette z` color
each vector or arrow from the last `using` column; a row with an undefined field is no point and out of the color
range, as gnuplot. A second `set style arrow N` changes style N (`default` resets it), as gnuplot. Labels are black
(the frame color of a theme) unless `tc` is given, as gnuplot. Unlike gnuplot, sectors widen the autoscale to their
whole extent. Not supported: `arrowstyle variable`, the dashes of an arrow style on data arrows, the back angle of
`size`, variable rotations, `units xx|yy`, label fonts and `hypertext`.

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
`character` (character cells from the bottom left of the page: 0.6 of the font size wide and the font size high, the
cell of the label offsets; gnuplot's svg cell is about 0.7 by 1.5); the system of x is also y's unless y names one
(`graph 0.5, first 3`); the systems take gnuplot's abbreviations (`fir`, `sec`, `gr`, `sc`, `char`). A coordinate is a constant expression, or a time string on a [time axis](#time-data).

| Command | Options (gnuplot 6.0's, defaults first) |
|---|---|
| `set label [N] ["text"] [at POS]` | `left`\|`center`\|`right`, `norotate`\|`rotate [by A]`, `back`\|`front`, `tc`/`textcolor` `rgb "c"`\|`"c"`\|`lt N`, `nopoint`\|`point [pt N] [ps S]`, `offset X,Y` (characters), `font "f"` (read, ignored), `noenhanced` |
| `set arrow [N] from POS to\|rto POS` | `as N`/`arrowstyle N` (the look of `set style arrow N`, the options after it applied on it), `head`\|`nohead`\|`backhead`\|`heads`, `size [SYS] L,A` (head length in x axis values, or graph, screen, character; barb angle [deg]), `nofilled` (two barbs)\|`filled`\|`empty`\|`noborder`, `back`\|`front`, `lc`, `lt`, `lw`, `dt` |
| `set style arrow N [default]` | the arrow options above but the position: the look of the arrows `as N`; `unset style arrow` forgets them |
| `set object [N] rectangle from POS to\|rto POS` \| `rectangle center\|at POS size W,H` | `fc`/`fillcolor`, `fs`/`fillstyle` (as `set style fill`, `border lc C` included), `lw`, `dt` (a dashed border), `back`\|`front`\|`behind`, `clip`\|`noclip`, `default`; a rectangle in the page color (`fc bgnd`) with a black border, as gnuplot, or in the look of `set style rectangle` |
| `set style rectangle` | `fc`, `fs`, `lw`, `dt`: the look of the rectangles set next (their layer is not taken, as gnuplot 6.0) |
| `set object [N] circle [at POS] size R [arc [A:B]]` | as rectangle; empty with a black border; `R` in x axis values (round on the page), `radius R` the same, an arc a wedge from the centre |
| `set object [N] ellipse [at POS] size W,H [angle A]` | as circle; the axes in the units of x and y, turned by `A` in those units (gnuplot's `units xy`) |
| `set object [N] polygon from POS to POS to POS ...` | as circle |

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
[textbox style](#set-unset-options) `N` (0 by default) is opaque or has a border, as gnuplot's svg terminal (a filter
flooding the text's bounding box; no border, no margin). An arrow takes `fill` for `filled` and `ls N` (the color, width and dashes of line style N).

Not supported: `boxed` on axis labels, `hypertext`, `set style circle|ellipse`, `units xx|yy`.

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
| `{/Symbol a}` | the Symbol font: the Latin letters as the Greek ones (`a` α, `b` β, `c` χ, `p` π, `t` τ, `W` Ω, ...) |
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
- The Fortran library writes its texts as they are unless [`fig%set_enhanced(.true.)`](library#methods): a `_` in a
  title passed from a program stays a `_`.

Departures from gnuplot: the Symbol font is written as Unicode Greek letters (gnuplot's svg names the font
`Symbol`, which few systems have), and the `<text>` elements carry `xml:space="preserve"`, so the blank at the start
of a run is kept by every SVG renderer.

## Parallel axes and spider plots

```gnuplot
plot 'scores.dat' u 2 w parallelaxes t 'speed', '' u 3 w parallelaxes t 'memory', '' u 4 w parallelaxes t 'cost'

set spiderplot
set style spiderplot fs transparent solid 0.2 border
set paxis 1 range [0:100]; set paxis 1 tics; set grid spiderplot
plot 'scores.dat' u 2:key(1) t 'speed', '' u 3 t 'memory', '' u 4 t 'cost'
```

As gnuplot, each item is an **axis** (a column of the data) and each **row** a line across the axes (`parallelaxes`)
or a polygon (`spiderplot`); both are alone in their panel.

- Every axis has its own scale, `set paxis N range [min:max]`, autoscaled to its values without extension (the
  smallest at the bottom or at the centre); its ticks are off until `set paxis N tics` (the `set xtics` forms).
- `parallelaxes`: the axes at x = 1, 2, ... (or `at X`), the x range one unit beyond them, titled below by their
  items; the rows in the first item's style. Unlike gnuplot, no y axis is drawn: its numbers would belong to no axis.
- `spiderplot` (after `set spiderplot`, or `with spiderplot`): the axes from the centre, the first up, the others
  clockwise, labelled by their item titles (else `set paxis N label`); a polygon per row in its linetype color and the
  `set style spiderplot` fill, named in the key by `using ...:key(N)` (the text of column N); `set grid spiderplot` draws
  the web at the ticks of the first axis.

foresight's own [`with radar`](#gauges-radars-and-roses) is the transposed shorthand: an item per polygon, a spoke per
row, a common scale. Not supported: `newspiderplot`, `set style parallelaxis`, `lc variable` on the axes lines,
`keyentry`.

## Point types

```gnuplot
plot 'run.dat' u 1:2 w lp pt 7 t 'residual', '' u 1:3 w p pt 4 ps 1.5 t 'cd'
```

The shapes are those of gnuplot's svg terminal: `pt 0` a dot, 1 plus, 2 cross, 3 star, 4 square, 6 circle,
8 triangle, 10 inverted triangle, 12 diamond, 14 pentagon, each odd type from 5 the filled shape before it; beyond 15
they cycle. A marker is 9 px wide at `ps 1`, its lines `lw` wide. Without `pt` a point is foresight's round dot,
6 px at `ps 1`. In the HTML page markers keep their shape and size under zoom; the text terminal draws every point
with the symbol of its color. `set pointsize S` sets the size of the points without their own `ps` (an item's `ps`
replaces it, as gnuplot's); `unset pointsize` and `reset` restore 1.

```gnuplot
plot '+' using 1:(cos(x)) with linespoints pt "C" pi 4 tc rgb "blue"   # a character every 4 points, in blue
plot 'run.dat' with linespoints pt "✠" pn 10                           # about 10 points, evenly spread
```

`pt "c"` draws the first character of the string (UTF-8) as the point, centred, in the series color or the item's
`tc` color, as text that keeps its size under zoom; also in `set style line`. An item's `font` is read and ignored.
`pn N` (`pointnumber`) marks about N of the placeable points, every (count-1)/(N-1)-th, the start shifted by the
item's number, as gnuplot.

```gnuplot
set jitter overlap 1 spread 0.5            # a swarm: overlapping points moved aside
set jitter square; set jitter vertical     # also onto one row; along y instead
```

`set jitter` spreads out the overlapping points of `with points`, by gnuplot's algorithm: the points sorted by x
then y, each one closer than `overlap` (characters, 1 by default, or y units after `first`) to the first point of its
group moves aside by (j+1)/2 `spread` point sizes of 0.7 characters, alternately left and right, back within `wrap`
characters if given; `square` also puts it on the row of the first point, `vertical` moves it along y instead. `unset
jitter` turns it off. Departures: foresight's characters are narrower than gnuplot's svg ones (0.6 by 1 font sizes,
gnuplot's 0.7 by 1.5), so its swarms are a little narrower; `with impulses` is not jittered; the HTML page zooms the
moved markers with the data.

## Margins

```gnuplot
set multiplot layout 2,1
set lmargin at screen 0.14; set rmargin at screen 0.95   # the same borders in both panels
plot 'run.dat' u 1:2 w l
plot 'run.dat' u 1:($3*1e6) w l                          # wider y labels: the plot does not move
unset multiplot
```

<Plot name="cb_margins" svg :width="560" :height="360" />

`set lmargin N` (`rmargin`, `tmargin`, `bmargin`) puts the border `N` characters from the panel's edge, `set lmargin at
screen F` at the fraction `F` of the page (from the bottom left), as gnuplot; bare, negative or unset, the margin is
computed from the labels again. `set margins L, R, B, T` sets the four, in gnuplot's order, each `[at screen] N`. A
character is foresight's cell, 0.6 font sizes wide and 1 high (gnuplot's svg cell is about 0.7 by 1.5, so margins in
characters are narrower than gnuplot's; at screen fractions they match). Panels of a multiplot with the same margins
at screen line up whatever their tick labels.

```gnuplot
set timestamp                               # the date and time at the bottom left
set timestamp "%Y-%m-%d %H:%M" top          # in a format, at the top left
set timestamp rotate offset 1,0 tc "gray40" # reading upward on the left
```

`set timestamp` writes the date and time in the bottom left margin, as gnuplot (`top`: the top left one; `rotate`:
reading upward along the left side), in its format (gnuplot's asctime, `"%a %b %d %H:%M:%S %Y"`, by default; the
conversions of [time data](#time-data)), the plot area a row (or a column) smaller; `offset` moves it in characters,
`font` is read and ignored. The time is the local wall clock, or `SOURCE_DATE_EPOCH` (seconds since 1970) when that
variable is set, for reproducible pages: beyond gnuplot, which ignores it. `unset timestamp` removes it.

## Multiplot

```gnuplot
set multiplot layout 1,2 title 'Monitor'
set title 'residual'; set logscale y
plot 'run.dat' u 1:2 w l t 'res'
set title 'drag'; unset logscale y
plot 'run.dat' u 1:3:4 w yerrorbars t 'cd'
unset multiplot
```

Each `plot` fills the next panel with the settings in force. The advance happens at the first `set`, `unset` or
`plot` after a plot, so settings written for the next panel never alter the one just plotted. A plot beyond the last
panel is an error.

Without `layout`, each panel lies in the box of its `set origin` and `set size`, fractions of the page below the
multiplot title, from the bottom left as gnuplot. Panels may overlap: an inset.

```gnuplot
set multiplot title 'Run monitor'
plot 'run.dat' u 1:3 w l t 'cd'
set origin 0.35,0.35; set size 0.55,0.5; unset key; set logscale y
plot 'run.dat' u 1:2 w lp
unset multiplot
```

With `margins L,R,B,T` (screen fractions, or characters after `char`; a unit carries to the next values) the plot
areas of the layout fill that box, `spacing X[,Y]` apart (0.05 screen by default), as gnuplot's
mp_layout_margins_and_spacing; the panels' own margins are kept apart. `spacing` alone does nothing, as gnuplot.

```gnuplot
set multiplot layout 2,2 margins 0.1, 0.95, 0.1, 0.9 spacing 0.08, 0.1 title "aligned panels"
```

Panels are drawn in order, without a background: in the HTML page the mouse acts on the topmost panel under it.
On the standard output (`set terminal dumb` or `block`), a multiplot is printed once, complete, at `unset multiplot`; files are
rewritten at each plot, so that a watched page shows the panels done so far.

## Boxes and filled curves

```gnuplot
set style fill solid 0.5
set boxwidth 0.8 relative
plot 'run.dat' every 10 u 1:5 w boxes t 'cd every 10 iterations'
```

<Plot name="cb_boxes" svg :width="560" :height="320" />

A box stands on y = 0, down for a negative value. By default the boxes touch: each edge lies halfway to the next
point, the end boxes symmetric. `set boxwidth W` gives them the width W, `set boxwidth F relative` the fraction F of
the default, a third `using` column each its own width. The fill is the item color: `empty` draws the border only,
`solid D` fills at opacity D (`transparent` changes nothing in SVG, as in gnuplot's svg terminal); `border lc C`
colors the border, `noborder` drops it.

```gnuplot
plot 'run.dat' u 1:($5-$6):($5+$6) w filledcurves fs transparent solid 0.3 t 'cd +/- dcd', \
     ''        u 1:5 w l t 'cd'
```

<Plot name="cb_filledcurves" svg :width="560" :height="320" />

`filledcurves` fills the band between two columns (`x:y1:y2`), the area down to the line `y=V` (`y1=V`, `y2=V`), to
the bottom (`x1`) or top (`x2`) of the plot, across to the left (`y1`, `y`) or right (`y2`) border, across to the
vertical line `x=V` (`x1=V`, `x2=V`, as gnuplot 6.0 draws them), to the point `xy=X,Y`, or the polygon of the points
(`closed`, the default with two columns); `above` and `below` keep the parts where the curve is above or below its
line (`y=V`), or where the first curve of a band is above or below the second. As gnuplot, it fills even with an `empty` fill style and draws no
border: plot the curve too for an outline. Undefined points split the fill as they split a line.

`fs pattern N` fills with one of the 8 patterns of gnuplot's svg terminal: 0 empty, 1 and 2 crosshatches, 3 solid,
4 to 7 hatches (down, up, steeper up, steeper down), N cycling every 8; `set style fill pattern N` gives the filled
items of a plot the patterns N, N + 1, ... as gnuplot. In text a pattern is a fill character (`x`, `X`, `\`, `/`),
in `block` its hatches are dots.

Two deliberate differences from gnuplot, so that a bar is never misread:

- **The y autoscale of boxes reaches 0** (and that of `filledcurves y=V` reaches V). gnuplot autoscales to the values
  only and draws the bars from the bottom of the plot: with values 3, 5, 2 it draws the 3 a third as long as the 5.
- **The x autoscale reaches the box edges** whatever the width. With touching boxes gnuplot leaves them out and cuts
  the first and last bar in half.

In text a fill is drawn with the symbol of its series (`block`: whole dots), whatever its opacity.

## Histograms

```gnuplot
set style fill solid 0.6 border -1
plot 'timings.dat' u 2:xtic(1) w histograms t 'mesh', '' u 3 w hist t 'fluxes', '' u 4 w hist t 'comm'
```

<Plot name="cb_histograms" svg :width="560" :height="320" />

Each `histograms` item gives one bar per row of its file, the rows at 0, 1, 2, ...; the items of a panel are laid out
together, as gnuplot:

- `set style histogram clustered gap G` (the default, gap 2): the k items of a row side by side, each bar 1/(k + G)
  wide, the cluster centred on its row;
- `set style histogram rowstacked`: one stack per row, 1 wide; positive values pile up from 0, negative ones down
  from 0, each sign on its own stack.

`set boxwidth F` scales every bar. The x autoscale goes one unit beyond the first and last rows, as gnuplot; the y one
reaches 0 for clustered bars too (gnuplot leaves it out, as for [boxes](#boxes-and-filled-curves)). The fill is
`set style fill` or the item's `fs`.

`using Y:xtic(N)` labels each row with the text of column N (quoted, it may hold blanks): when any item has labels,
they replace the x ticks, at their rows, as gnuplot; the HTML page keeps them through a zoom. `xtic` works with any
style, `using 0:2:xtic(1) w boxes` too, and takes a [string expression](#string-columns).

```gnuplot
set style histogram errorbars gap 1 lw 2
plot 'timings.dat' u 2:3:xtic(1) t 'mesh', '' u 4:5 t 'fluxes'          # y:err, or y:low:high
set style histogram columnstacked
plot 'shares.dat' u 2 t columnhead, '' u 3 t columnhead, '' u 4:key(1) t columnhead
set style histogram clustered gap 1
plot newhistogram 'CPU', 'cpu.dat' u 2:xtic(1) t 'mesh', '' u 3 t 'solve', \
     newhistogram 'GPU' lt 1 fs pattern 4, 'gpu.dat' u 2:xtic(1) notitle, '' u 3 notitle
```

- `set style histogram errorbars [gap G] [lw W]` lays the bars out as `clustered`, each with its error bar at its
  centre: `using Y:ERR` (from `Y - ERR` to `Y + ERR`) or `using Y:LOW:HIGH`, in the border color of the fill (the item
  color without a border), `W` px wide.
- `set style histogram columnstacked` makes one stack per item at 0, 1, 2, ...: its rows stacked (positive values up,
  negative ones down), each row in the color of its linetype, as gnuplot. `key(N)` names the rows in the key (the
  last row first, as gnuplot); `title columnhead` labels the stack on the x axis.
- `newhistogram ["title"] [lt N] [fs FILL] [at X]` starts a group of histograms in the plot: its rows (or stacks)
  from `X`, else 2 rows after the last one of the previous group (the first group from its rows), its title centred
  below the x tick labels (the HTML page hides it while zoomed), the default colors of its items from linetype `N`,
  their fill `FILL`. The gap and the bar widths are those of each group (`1/(k + gap)` for its k items).

`set style histogram ... title [tc C] [offset X,Y]` colors and moves the group titles (`offset` in characters; a
`font` is read and ignored); `nokeyseparators` is accepted, foresight drawing no blank key row between the groups
where gnuplot does by default. `set errorbars` sets the [caps](#error-bar-caps) of the error bars.

The rows of a histogram are its abscissae as given (the point numbers from a script): a header row that is not a
number counts, as gnuplot.

## Readouts

A foresight extension, not gnuplot (gnuplot rejects these scripts): `with readout` shows the last finite value of an
item in seven-segment digits, as the digital instrument clusters of 1980s cars. It is made for live monitoring with
[`--watch`](monitoring) and for showcase pages, not for publication figures.

```gnuplot
set multiplot title 'Run monitor'
set origin 0,0.68; set size 1,0.32
set readout horizontal
plot 'run.dat' u 1 w readout format '%4.0f' t 'ITER', '' u 2 w readout format '%9.2e' t 'CONTINUITY'
set origin 0,0; set size 1,0.68
set readout vertical top right; unset key
plot 'run.dat' u 1:5 w l t 'cd', '' u 1:5 w readout format '%6.4f' t 'CD'
unset multiplot
```

<Plot name="cb_readout" svg :width="560" :height="420" />

- **The value** is the last point whose y is finite, after `using`, `every`, `index` and `smooth`; ranges, log axes
  and zoom do not apply. A readout takes no part in the autoscale and has no key entry: in a panel with curves, the
  curves alone set the axes.
- **The glass** is set by the format, never by the value, so a watched readout keeps its width: `format` is a
  [tick format](#ticks-and-label-formats) with a field width (`%9.2e`, not `%.2e`), without `%h`. Each character of
  the field is a cell, except the decimal point, a segment of the cell before it: `%9.2e` makes 8 cells. A `+` and
  the exponent sign `+` light nothing. Unlit segments are drawn faintly, as on the real displays.
- **No reading** (no finite value yet) or a value wider than the field lights a dash in every cell; digits are never
  cut. The text around the conversion, `'%5.2f h'`, is printed beside the glass: a unit.
- **The label** is the item title; `lc` colors the digits; `lw`, `dt`, `pt`, `ps` and `axes` are errors on a readout.
- **Placement.** The readouts of a panel form a block, a column (`vertical`, the default) or a row (`horizontal`),
  placed inside the plot area by the `set key` words (top left by default, the key being top right) over an opaque
  window hiding the curves below (`noopaque`: none). A panel of readouts alone has no axes: the digits grow until the
  block fills it, unless `set readout size H` fixes their height [px] (2.5 font sizes by default).
- **In text** (`dumb`, `block`), the digits are drawn with `_` and `|`, 3 rows of 4 characters per cell, in the item
  color with `ansi`; the unlit segments are not drawn. In the HTML page, zoom and follow mode leave readouts alone.

## Images and palettes

```gnuplot
set cblabel 'phi'
plot 'field.dat' u 1:2:3 w image t 'phi(x,y)'
```

<Plot name="cb_image" svg :width="560" :height="400" />

`with image` colors a regular grid of values (a heatmap): `x:y:z` points, evenly spaced in x and y (one per pixel
centre, missing points left transparent), or a `matrix` file, the values of each row along x, the rows along y. The x
and y axes fit the pixel edges, half a pixel beyond the first and last centres, never extended to the ticks, as
gnuplot. Undefined values are transparent.

The palette maps the values over `cbrange` (autoscaled to the values, not extended) to colors, as gnuplot 6.0 (its
`test palette` values): the default `rgbformulae 7,5,15` (black, blue, red, yellow), any of the 37 `rgbformulae`
(a negative number for the formula of 1 - gray), `defined (0 "blue", 1 "white", 2 "red")` interpolated in RGB (colors
`#rrggbb`, `0xrrggbb` or one of gnuplot's 111 [color names](#color-names)), `cubehelix` (Dave Green's helix through the color cube, lightness
rising with gray: `start S` its starting hue, `cycles C` its turns, `saturation S`; gnuplot's 0.5, -1.5, 1, reset at
each `cubehelix`, the options right after it), `file 'f'` (a gradient read from a data file, see below), `gray`,
`viridis`, or a [named palette](#named-palettes);
`color` (after `gray`) restores the last one set by `rgbformulae`, `defined`, `viridis` or a name, else the default;
`negative` reverses it, `maxcolors N` quantizes it to N bands. The color box at the right of the plot shows the palette over the range, with `cblabel`.
The palette colors only images and the color box: the series colors (`lc N`) are the linetype colors.

```gnuplot
set palette viridis maxcolors 10
set xlabel 'sweep'; set ylabel 'block'; set cblabel 'residual'
plot 'blocks.dat' matrix w image notitle
```

<Plot name="cb_matrix" svg :width="560" :height="400" />

In SVG and HTML an image is an embedded PNG, its pixels kept sharp at any zoom; the HTML page zooms it with the data.
In text each character takes the pixel at its centre, denser for brighter pixels (` .:-=+*#%@`), in its color with
`ansi`. The `vfd` and `lcd` themes replace the default palette with their own: with `vfd`, the dark glass for the
lowest values up to the emissive colors, and `maxcolors` turns the heatmap into a grid of lit levels; `washi` and
`night` keep it.

<Plot name="cb_image_vfd" svg :width="560" :height="400" />

`set palette file 'f'` reads a gradient as gnuplot: 4 columns `gray:r:g:b` (the grays increasing, mapped to 0..1 as
`defined`), or 3 columns `r:g:b` evenly spaced (the default is 4 columns when the rows have a 4th), the components
from 0 to 1 (clipped); `index`, `every` and `using` (expressions too) select and compute them as in `plot`, `#`
comments are skipped and a blank line is an error. Words before the file keep their effect (`set palette negative`
then `set palette file 'f'` stays negative), words after it apply to it. From the library, `set_palette_gradient`
takes the positions and colors as arrays.

```gnuplot
set palette file 'terrain.dat'
set cbrange [-1:1]; set cblabel 'height'
plot 'field.dat' u 1:2:3 w image notitle
```

<Plot name="cb_palette_file" svg :width="560" :height="400" />

The color axis takes the x and y settings: `set cbtics` (step, start, end; a factor on a log axis), `set format cb`
(a bare `set format` reaches it too, `set format xy` does not), `unset cbtics` (no ticks nor labels on the box).
`set logscale cb` maps log10 of the values: autoscaled, the axis spans the positive values (3 to 700, not widened to
decades), and values <= 0 take the low end color, as gnuplot; its decades are labelled 10 with an exponent, as the
log x and y axes.

```gnuplot
set logscale cb; set cblabel 'residual'
set cbtics 10
plot 'field.dat' u 1:2:(10**(3*$3)) w image notitle
```

<Plot name="cb_logcb" svg :width="560" :height="400" />

`set colorbox` places the box as gnuplot: `vertical` (the default) at the right of the plot, low values at the bottom
(`invert`: at the top); `user` in the box of `origin X,Y` and `size W,H`, fractions of the whole page from its bottom
left (0.9,0.2 and 0.05,0.6 by default), over the plot if so placed; `noborder` without its frame. `horizontal` puts
low values at the left, the tick labels and `cblabel` below: at its default place the box lies below the x labels,
as wide as the plot (gnuplot keeps the narrow vertical slot there: a horizontal box needs `user` in gnuplot), and
`invert` changes nothing, as gnuplot. A bare `set colorbox` returns the box to its default place, the other options
kept; `unset colorbox` resets them all.

```gnuplot
set colorbox horizontal
set colorbox vertical user origin 0.86,0.3 size 0.02,0.45 invert
```

<Plot name="cb_colorbox" svg :width="760" :height="320" />

Not supported: `functions` palettes, `set palette gamma` (1.5), `set palette model` other than RGB, `set colorbox back`
and border line types, `pm3d`.

`with rgbimage` (`using x:y:r:g:b`) and `with rgbalpha` (`x:y:r:g:b:a`) color the pixels of a regular grid directly,
the components from 0 to `set rgbmax` (255; 1.0 for fractions), without palette nor color box; an undefined component
makes its pixel transparent. Packed ARGB in one column and `matrix` RGB data are not supported.

### Named palettes

A foresight extension (gnuplot rejects these scripts): `set palette NAME` takes one of the 40 *Scientific colour maps*
(v8.0.1) by Fabio Crameri, one of matplotlib's `magma`, `inferno`, `plasma`, `viridis`, `cividis`, or Kenneth
Moreland's `black_body`, the name in any case
(`batlow`, `BATLOW`, `romao`). They are perceptually uniform (equal steps in value look like equal steps in color),
readable with color-vision deficiencies and, the sequential ones, in black-and-white print. A table of 256 colors,
gray g takes its color nint(255 g); `negative` reverses it, and `maxcolors N` takes the N colors nint(255 k / (N - 1)),
Crameri's discrete palettes (`batlow maxcolors 10` is his `batlow10`; a few of his differ by 4/255 at most).

| Type | Names | For |
|---|---|---|
| Sequential | `acton` `bamako` `batlow` `batlowK` `batlowW` `bilbao` `buda` `davos` `devon` `glasgow` `grayC` `hawaii` `imola` `lajolla` `lapaz` `lipari` `navia` `naviaW` `nuuk` `oslo` `tokyo` `turku`; `magma` `inferno` `plasma` `viridis` `cividis` `black_body` | a magnitude, low to high |
| Diverging | `bam` `berlin` `broc` `cork` `lisbon` `managua` `roma` `tofino` `vanimo` `vik` | a deviation from a meaningful centre (zero, a mean): set a `cbrange` symmetric about it |
| Multi-sequential | `bukavu` `fes` `oleron` | two regimes either side of a value at mid-palette (depth and height about sea level): set a `cbrange` that puts the value in the middle |
| Cyclic | `bamO` `brocO` `corkO` `romaO` `vikO` | a periodic quantity (phase, angle, direction, time of day): both ends have the same color |

<Plot name="cb_colormaps_all" svg :width="760" :height="1280" />

```gnuplot
set palette vik
set cbrange [-1:1]
plot 'field.dat' u 1:2:3 w image notitle
```

Their 22 categorical orders (`actonS` ... `turkuS`) color series instead: `set colorsequence batlowS 6`, see
[Styles](#styles).

Credit the Scientific colour maps as Crameri, F. (2018), *Scientific colour maps*, Zenodo,
[doi:10.5281/zenodo.1243862](https://doi.org/10.5281/zenodo.1243862), and see Crameri, Shephard and Heron (2020),
*The misuse of colour in science communication*, Nature Communications 11, 5444,
[doi:10.1038/s41467-020-19160-7](https://doi.org/10.1038/s41467-020-19160-7). `cividis` is Nuñez, Anderton and Renslow
(2018), *Optimizing colormaps with consideration for color vision deficiency to enable accurate interpretation of
scientific data*, PLoS ONE 13(7), e0199239, [doi:10.1371/journal.pone.0199239](https://doi.org/10.1371/journal.pone.0199239),
in the version its author gave matplotlib. The Scientific colour maps are MIT-licensed, magma, inferno, plasma and
viridis CC0, cividis under matplotlib's licence and Battelle's, black_body CC0: the notices are in
`src/lib/foresight_colormaps.F90`.

## Circles, pies and donuts

```gnuplot
set style fill solid 0.4
plot 'scaling.dat' u 2:3:4 w circles t 'memory [GB] as radius'
```

<Plot name="cb_circles" svg :width="560" :height="320" />

`with circles` draws a circle per point, as gnuplot: its radius in x-axis units (the third column; 2% of the plot
width without it), round on the page whatever the axis scales, filled with the fill style. The x autoscale widens to
the circles, the y one does not (gnuplot's choice: their height in y units depends on the page). With two more
columns, a start and an end angle in degrees counterclockwise from the x direction, it draws wedges.

```gnuplot
set title 'Time per step'
plot 'phases.dat' u 2:xtic(1) w pie
```

<Plot name="cb_pie" svg :width="480" :height="320" />

`with pie` is a foresight extension (gnuplot draws pies only through `circles` and computed angles): one slice per row,
proportional to the values, from 12 o'clock clockwise, each in its linetype color; the key lists the slices with their
`xtic` names and percentages. `donut F` leaves a hole of F times the radius. A pie is alone in its panel, without axes,
and takes non-negative values only: slices compare parts of a whole, which a signed quantity is not. Angles read less
precisely than lengths: for comparing the parts, [histograms](#histograms) are the better chart.

<Plot name="cb_donut_vfd" svg :width="480" :height="320" />

## Gauges, radars and roses

Foresight extensions, charts alone in their panel like the pie (several gauges or radar items side by side).

```gnuplot
set terminal svg size 600,240 theme vfd
plot 'run.dat' u 1 w gauge range [0:150] segments 24 format '%3.0f' t 'ITER', \
     ''        u 5 w gauge range [0:0.6] segments 24 format '%5.3f' t 'CD'
```

<Plot name="cb_gauges" svg :width="600" :height="240" />

**A gauge** shows the last finite value of its item, as a [readout](#readouts), on a 270-degree track from 7:30
clockwise to 4:30 over `range [A:B]` (required: a dashboard scale is fixed). The track is drawn faintly and lit up to
the value, in `segments N` cells if set (a cell lit when covered at least half); the scale ticks lie outside, the value
in seven-segment digits of `format` under the centre, titled by the item. A value beyond the range fills the track,
the digits still give it.

```gnuplot
set style fill solid 0.3
plot 'radar.dat' u 2:xtic(1) w radar t 'gpu', '' u 3 w radar t 'cpu'
```

<Plot name="cb_radar" svg :width="480" :height="320" />

**A radar** (spider) chart has a spoke per row, from 12 o'clock clockwise, named by the `xtic` labels; every item is a
polygon over the spokes on a common radial scale from 0 (or the smallest value, if negative), its rings at the ticks.

```gnuplot
plot 'phases.dat' u 2:xtic(1) w rose
```

<Plot name="cb_rose" svg :width="480" :height="320" />

**A rose** (Nightingale) chart has equal sectors, one per row in the linetype colors, named in the key. A sector's
**area** is proportional to its value, so twice the value looks twice as large; `rose linear` makes the radius
proportional instead, the common but exaggerating choice (twice the value, four times the area). The rings mark the
values of the scale.

## Polar plots

gnuplot's `set polar`: the items are theta:r, drawn at x = (r - rmin) cos(theta), y = (r - rmin) sin(theta) and joined
by straight segments, functions are r of `t`. As in gnuplot, `set polar` alone keeps the rectangular frame and the x
and y ticks, the r axis running from the pole to the right; the round plot is gnuplot's usual idiom:

```gnuplot
set terminal svg size 520,400 theme vfd
set polar; set angles degrees
set size square; unset border; set border polar; unset xtics; unset ytics
set grid polar 30; set ttics 0,30; set key outside
plot 'directivity.dat' u 1:2 w lp t 'probe', 1+cos(t) t 'cardioid'
```

<Plot name="cb_polar" svg :width="520" :height="400" />

- theta is in radians unless `set angles degrees` (which also makes `sin`, `cos`, `tan` take degrees and `asin`, `acos`,
  `atan`, `atan2` return them); `set theta top clockwise` puts theta = 0 at the top, growing clockwise;
- the r range starts at 0 at the pole and ends at the largest |r| extended to the r ticks; `set rrange [1:*]` puts
  r = 1 at the pole, the points below it undefined; with an autoscaled pole a negative r lies across it, as gnuplot;
- `set trange [min:max]` samples the functions of `t` over it; a set end also leaves out the data points of theta
  beyond it (gnuplot 6.0 excludes them), with no wrapping of the angles: `[-90:90]` keeps theta = 0 to 90 of data
  written 0 to 360;
- x and y autoscale to the disc, [-R:R] for R = rmax - rmin, extended to their ticks when these are on;
- `set grid polar` draws rings at the r ticks and spokes (`set grid r` the rings alone), `set border polar` the circle
  of rmax, `set ttics` the theta labels outside it (always in degrees; `set ttics add ("π" 180)` names an angle),
  `set mttics N` minor ticks on that circle, `set size square` keeps the circle round;
- the items are `lines`, `points`, `linespoints`, closed `filledcurves` (`using theta:r`) or readouts (of r), on the
  first axes; x and y stay linear.

In the HTML page a polar panel zooms as any other: the curves, rings, spokes and border are data, the r tick labels
and theta labels are hidden while zoomed. Unlike gnuplot, points beyond rmax are clipped at the plot area as the lines
(gnuplot hides them), and the autoscale takes the largest |r| (gnuplot: the largest r, degenerate when all are negative).

## Themes and segmented fills

Foresight extensions: the look of the digital dashboards of 1980s cars, for monitoring and showcase pages, and the
two faces of foresight's own identity, the colors of this site in its light and dark modes.

```gnuplot
set terminal svg size 640,440 theme vfd
set multiplot title 'RUN MONITOR'
set origin 0,0.62; set size 0.4,0.38; set readout vertical
plot 'run.dat' u 1 w readout format '%4.0f' t 'ITER', '' u 5 w readout format '%6.4f' t 'CD'
set origin 0.4,0.62; set size 0.6,0.38; set key top left
set style fill solid segments 10
plot 'timings.dat' u 2:xtic(1) w hist t 'mesh', '' u 3 w hist t 'fluxes'
set origin 0,0; set size 1,0.62; set key top right
set logscale y; set grid
plot 'run.dat' u 1:2 w l lw 2 t 'continuity', '' u 1:3 w l lw 2 t 'momentum'
unset multiplot
```

<Plot name="cb_vfd" svg :width="640" :height="440" />

**Themes** recolor the output, never the figure: `classic` (the default) changes nothing; `vfd` is a vacuum
fluorescent display, black glass, emissive series colors (cyan-green, amber, red, ...), the frame and labels printed in
blue, the data glowing; `lcd` a backlit liquid crystal display, pale green glass and dark segments; `washi` ink on warm
paper with a crimson first series, and `night` light text on a near-black red ground with a rose first series, the
light and dark modes of this site (its figures are drawn in them), every series color at least 3:1 against its ground.
The default linetype
colors (not another `set colorsequence`), the frame, grid and page become the theme ones; a color you give (`lc '#123456'`) is kept. `glow` and
`noglow` override the theme (only `vfd` glows by default); the glow is an SVG filter, so converters that do not render
filters (some PDF ones) drop or rasterize it. In the HTML page, the ticks and grid redrawn by a zoom take the theme
colors. In text the theme only recolors the series, with `ansi`, `ansi256` or `ansirgb`: the terminal background is
not foresight's.

**Segmented fills**, `fs solid segments N` (boxes, histograms): the y range is cut into N cells, the same for every
bar, as on a fixed-segment display. A bar lights the cells it covers at least half (it reads to the nearest cell: a
quantization, a display choice, not a measurement), the other cells of its column are drawn faintly (not drawn in
text). Zooming magnifies the cells with the data.

## Not supported

Inline ranges in polar mode, `set link x2|y2`, `splot`,
`fit` beyond [its subset](#fit), log bases other than 10, a negative `set size ratio`; `set rlabel`,
`set logscale r`, the `rtics` placement options; in `set xtics`, positions and a list together
(`set xtics 0,1 ("a" 2)`), `rotate` of the y, y2 and color box labels, `out` of the color box ticks, `axis` of the
x2 and y2 ticks, `log`/`nolog`; the complex forms of the functions but `abs`, `arg`, `real`, `imag`, `conj`, `sqrt`,
`exp`, `log`, `log10`, `sin`, `cos`, `tan`, `sinh`, `cosh` (gnuplot's `Ai`, `BesselJ`, ...) and those of libcerf
(`VP`, `erfi`, `FresnelC`, ...);
in [enhanced text](#enhanced-text), the fonts and the super and subscripts of the text devices; `splot`'s `set parametric` (u, v); in `set format`,
gnuplot's `geographic` formats; `set datafile` options other than `separator`, `missing`,
`commentschars` and `columnheaders`; `filledcurves r=`; `lc variable` with boxplot, error bars and labels, `lc palette z` with other styles than lines, points, linespoints, impulses, vectors and arrows, `lc palette NAME`, `set style boxplot labels x2`; the blank key rows of
`newhistogram` groups; the line gap of a negative `pointinterval` or `pointnumber`; `reread`
(deprecated in gnuplot 6.0), arrays as function arguments; the `smooth` filters
`unwrap`, `path`, the `kdensity` `period` option and smoothing on log axes in log space; the `block` character sets `dot`, `octants`, `sextpua`,
`octpua`, and its `optimize`, `attributes`, `charpoints`, `gppoints`, `animate` options; two tick
label fields in one `using` (`xtic(1):ytic(2)`); `set multiplot` `scale`, `offset`; palette
models other than RGB and HSV; `set ttics rotate`; `title at`; `keyentry` with
other styles than those of functions;
`fillsteps` options (`above`, `below`, `y=`); `set minussign` and `set micro` with `set encoding utf8`.
