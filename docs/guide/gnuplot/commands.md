---
title: Commands and settings
---

# Commands and settings

Every command, the `set`/`unset` options, shell commands, print, fit and stats. Part of the [gnuplot subset](/guide/gnuplot-subset) reference.

## Commands

| Command | Effect |
|---|---|
| **p**lot *items* | replace the current plot and render it to the output |
| **sp**lot *items* | a [3D plot](/guide/gnuplot/3d#_3d-plots): items with a height z, functions of x and y; drawn in a [3D view](/guide/gnuplot/3d#_3d-views) or the map view (`set view map`) |
| **rep**lot [*items*] | render the last plot again (re-reading its data), optionally adding items |
| **ref**resh | the last plot again, without new items (gnuplot redraws its stored data; the files are read again here) |
| **se**t *option* | set an option |
| **uns**et *option* | reset an option |
| *name* `=` *expression* | a [user variable](/guide/gnuplot/scripting#user-variables-and-functions): the value now, integer or real |
| *name*`(`*p1*`, ...) =` *expression* | a [user function](/guide/gnuplot/scripting#user-variables-and-functions) |
| **fit** [`[min:max]`] *f(x)* `'file'` [*modifiers*] `via` *a*`,` *b* ... | [fit](#fit) the parameters of a function to data |
| **stat**s [`[x]`] [`[y]`] `'file'` [*modifiers*] [`name`\|`prefix "P"`] [`output`\|`nooutput`] | [statistics](#stats) of a column or a pair |
| **pr**int *expression*`,` ... | [print](#print) values |
| `do for [`*i*`=`*a*`:`*b*`] {` ... `}`, `while (`*c*`) {` ... `}`, `if (`*c*`) {` ... `} else {` ... `}` | [blocks](/guide/gnuplot/scripting#blocks-and-loops): loops and conditions, `break`, `continue` |
| `$NAME << WORD` ... `WORD` | a [datablock](/guide/gnuplot/scripting#datablocks-and-scripts): data inside the script, `plot $NAME` |
| `function $NAME`[`(`*p1*`, ...)`] `<< WORD` ... `WORD` | a [function block](/guide/gnuplot/scripting#function-blocks), called as `$NAME(args)`; inside it `local` *name* `=` ..., `return` [*expression*] |
| **l**oad `'file'` | run a [script file](/guide/gnuplot/scripting#datablocks-and-scripts) |
| **cal**l `'file'` [*arg* ...] | run a script file with arguments: `ARG1` ... `ARG9`, `ARGC` |
| **eva**l *string*, `eval(`*string*`)` | run a string as script lines |
| **cl**ear | in a [multiplot](/guide/gnuplot/axes#multiplot), the box of the next plot (`set origin`, `set size`) painted with the page color first, an inset over the plots below; otherwise nothing (each plot replaces the page) |
| **undef**ine *name* ... | forget variables (`name*`: those starting with `name`), arrays and datablocks (`$NAME`) |
| `array` *A*`[`*N*`]` [`= [`*e1*`, ...]`], `array` *A* `= [`*e1*`, ...]`, `array` *A* `=` *B*`[`*i*`:`*j*`]`, *A*`[`*i*`] =` *expression* | an [array](/guide/gnuplot/scripting#arrays) |
| **vcl**ear [`$GRID`], **vfi**ll\|**vgfi**ll *source* `using x:y:z:radius:(density)`, `voxel(`*x*`,`*y*`,`*z*`) =` *value* | [voxel grids](/guide/gnuplot/3d#voxel-grids): zero a grid, add a density around data points, set one grid point |
| **sy**stem `"command"` | run a [shell command](#shell-commands-reset-and-pause), its output on the standard output |
| **res**et [`session`\|`errors`\|`bind`] | the plot settings back to their [defaults](#shell-commands-reset-and-pause) |
| **pa**use *seconds*\|`-1`\|`mouse` [`"message"`] | [wait](#shell-commands-reset-and-pause): `while (1) { plot ...; pause 5 }` is the live loop |
| `reread` | an error, as gnuplot 6.0 (deprecated): use `while (1) { ...; pause N }` |
| `exit` [`message "text"`\|`error "text"`\|`status N`\|`gnuplot`], `quit` | end the script file being read (a `load` returns to its caller; `message` writes the text first), or with `error` fail with the text; `quit`, `exit gnuplot` and `exit status N` end the run (the command line returning `N`), see [below](#gpval-variables-and-exit) |

## `set` / `unset` options

| Option | `set` | `unset` |
|---|---|---|
| **tit**le `"text"` [`offset X,Y`] [`font F`] [`left`\|`center`\|`right`] [`tc COLOR`] [`noenhanced`] [`boxed`] | panel title, shifted by `offset` characters (y up; each coordinate may name its system, the second in the first's unless given: `offset graph 0.15, -0.33` fractions of the plot, through the view in 3D as gnuplot's map3d_position_r, `screen` fractions of the page); `left` and `right` justify it about its centre, as gnuplot's svg terminal; `tc` its color (`tc lt N` linetype N's); `font` its [font](/guide/gnuplot/text#fonts) (its size grows the top margin, as gnuplot); `noenhanced` writes it as it is, not as [enhanced text](/guide/gnuplot/text#enhanced-text); `boxed` on the background (text box style 0); a new line (`"a\nb"`) starts a line below, the plot lower, as gnuplot; options without a text (`set title offset 0,-2`) keep the title | no title |
| **caption** `"text"` | foresight: the caption a document gives the figure (the [library's `save` info](../library#what-a-document-needs)); not drawn; `unset caption` or `reset` clears it | no caption |
| `fit` [*options*] | [fit](#fit) report and stopping options; bare, the defaults | — |
| **pr**int [`"file"` [`append`] \| `"-"` \| `$NAME` [`append`]] | where [print](#print) writes: a file or a datablock (emptied unless `append`), `-` the standard output; bare, the standard error | the standard error |
| **tab**le [`"file"`\|`$NAME`] [`append`] [`separator` `whitespace`\|`tab`\|`comma`\|`"c"`] [`markdown`] | plots write their points as [text](/guide/gnuplot/data#tables) to the file, the datablock or the standard output, drawing nothing; the separator of [`with table`](/guide/gnuplot/data#with-table); `markdown` (foresight) [Markdown tables](/guide/gnuplot/data#markdown-tables) | plots drawn again |
| **errorb**ars (**bar**s) [`small`\|`large`\|`fullwidth`\|`SIZE`] [`front`\|`back`] [`lc C`] [`lw W`] | the cap length of the [error bars](/guide/gnuplot/plot-items#error-bar-caps) and boxplot whiskers (`small` none, `large`, the default, 1), their line | no caps |
| **xl**abel / **yl**abel / **y2l**abel / **x2l**abel `"text"` [`offset X[,Y]`] [`font F`] [`tc COLOR`] [`rotate` ...\|`norotate`] [`noenhanced`] [`boxed`] | axis label (`y2` on the right, `x2` on the top), shifted by `offset` characters (x right, y up; a third, 3D, offset read and ignored; the x label's y offset narrows or widens the bottom margin, the x2 label's the top one, as gnuplot), in its `tc` color and [font](/guide/gnuplot/text#fonts) (the x2 label's size grows the top margin, the others only their text, as gnuplot); `rotate` (`by A`, `parallel`) turns the labels of [3D views](/guide/gnuplot/3d#_3d-views) only, 2D ones keep gnuplot's default (the y label vertical); `left`/`center`/`right` read and ignored; `noenhanced`: as it is, not as [enhanced text](/guide/gnuplot/text#enhanced-text); `boxed` on the background; options without a text (`set xlabel offset 0,1.5 boxed`) keep the label, as gnuplot | no label |
| **xr**ange / **yr**ange / **y2r**ange / **x2r**ange [`[min:max]`] [`noextend`\|`extend`] [`reverse`\|`noreverse`] [`nowriteback`] | axis range; `*` autoscales an end, an empty end keeps it as it is (fixed or autoscaled: `set xrange [2:5]; set xrange [:10]` is [2:10], as gnuplot 6.0) (`lb<*<ub` within limits, see [below](/guide/gnuplot/axes#grid-zero-axes-and-border)), `[]` or no range keeps both; `min > max` reverses; `reverse` reverses an axis with an autoscaled end (an explicit range is left as it is, as gnuplot); `noextend` keeps autoscaled ends at the data | autoscale |
| **offset**s [`graph`] `L`, [`graph`] `R`, [`graph`] `T`, [`graph`] `B` | autoscaled x and y ends moved out, see [Offsets](/guide/gnuplot/axes#offsets) | no offsets |
| **par**ametric | [parametric](/guide/gnuplot/plot-items#parametric-plots) functions: items in pairs x(t), y(t) over `trange`; `splot` items in triples x(u,v), y(u,v), z(u,v) over `urange`, `vrange` | functions of x (the dummy variables back to x and y) |
| **clip** [`points`\|`one`\|`two`\|`radial`] | [clipping](/guide/gnuplot/plot-items#clipping) of segments and markers at the border (bare: `points`) | bare: `points`, `one`, `two` off |
| **timestamp** [`"format"`] [`top`\|`bottom`] [`rotate`\|`norotate`] [`offset X,Y`] [`font F`] [`textcolor C`] | the date and time in a corner, see [Margins](/guide/gnuplot/axes#margins) | no timestamp |
| **poi**ntsize `S` | the point size of the items without their own (`ps`), see [Point types](/guide/gnuplot/styles#point-types) | 1 |
| **linet**ype `N` [`lc`] [`lw`] [`dt`] [`pt`] [`ps`]\|`cycle N` | redefine linetype N, see [Styles](/guide/gnuplot/styles#styles); its color may have an alpha channel (`"#80bb33bb"`) | — |
| **jit**ter [`overlap` [`first`] `N`] [`spread S`] [`wrap W`] [`swarm`\|`square`\|`vertical`] | overlapping points spread out, see [Point types](/guide/gnuplot/styles#point-types) | no jitter |
| **log**scale [*axes*] [`10`] | base-10 log axes; *axes* concatenates `x`, `y`, `y2`, `x2`, `cb` (`y`, `xy2`, `cb`: the [color axis](/guide/gnuplot/3d#images-and-palettes)), all when absent; `r` alone the [polar](/guide/gnuplot/axes#polar-plots) radius | linear axes |
| **gr**id [[`no`][`m`]`x`\|`y`\|`z`\|`x2`\|`y2`\|`cb`[`tics`]]... [[`no`]**vert**ical] [`front`\|`back`\|`layerdefault`] [`lt N`] [`lc C`] [`lw W`] [`dt N`] [**po**lar [`STEP`]\|`r`\|**spider**plot] | grid lines at the ticks of the axes named (`m`: minor; the others kept; x and y when none), over the data with `front`, in its line (`lt 0` dots, the default, `lt -1` or `lt black` black); `polar`: on a [polar](/guide/gnuplot/axes#polar-plots) panel, rings at the r ticks and spokes every `STEP` (30 degrees by default, in the angle unit; a `STEP` beyond a full turn of radians is in degrees, as gnuplot) instead; `r` the rings alone (with `polar`, as `polar`), `nor` none; in a [3D view](/guide/gnuplot/3d#_3d-views) the x and y lines on the base plane, `z` at the major z ticks (`mz` the minor ones) and `vertical` at the x and y ticks on the back walls; `cb` (`mcb`) lines across the color box at its (minor) ticks | no grid |
| **pol**ar | [polar](/guide/gnuplot/axes#polar-plots) coordinates: items are theta:r, functions of `t`; `set polar grid ...` the grid of `with surface` (polar on) | x:y coordinates |
| **rl**abel `"text"` [`offset X,Y`] [`tc C`] ... | the label of the radial axis of a [polar](/guide/gnuplot/axes#polar-plots) plot | none |
| `isotropic` | equal unit lengths on x and y (`set size ratio -1`; `unset isotropic` frees them), gnuplot 6.0 | free |
| `chi_shape fraction F` | the default length of `concavehull`, F times the longest edge of the convex hull | 0.6 |
| **an**gles `degrees`\|`radians` | unit of theta, of `t` and of the trigonometric functions (radians by default) | — |
| `theta` [`right`\|`top`\|`left`\|`bottom`] [`clockwise`\|`cw`\|`counterclockwise`\|`ccw`] | where theta = 0 lies and its direction (right, counterclockwise by default) | right, counterclockwise |
| **rr**ange / **tr**ange `[min:max]` | r range (`min` at the pole, 0 when autoscaled) and theta range: of the functions (a full turn by default), and a set end leaves out the data points beyond it | — |
| **rti**cs [`auto` \| `STEP` \| `START,STEP[,END]`] | ticks of the r axis (automatic by default) | no r ticks |
| **tti**cs [[`START,`]`STEP`] [`format "fmt"`] \| [`add`] `("label" angle [level], ...)` | theta labels around the polar plot, in degrees; every 45 degrees without `STEP` (gnuplot: none); a list replaces them, or with `add` its items replace the labels at their angles | no theta labels (the default) |
| **mtt**ics [`N`] | minor theta ticks: `N` intervals between the labels, ticks on the polar border only, as gnuplot | none |
| **rax**is | the r axis, from the pole towards the right of the page (the default) | no r axis |
| **bor**der [`MASK`] [**po**lar] [`front`\|`back`\|`behind`] [`lt N`] [`lc C`] [`lw W`] [`dt N`] | frame sides, 1 bottom, 2 left, 4 top, 8 right (31, all, by default; `MASK` a number or a constant expression, a negative one its bits: -1 all); in a [3D view](/guide/gnuplot/3d#_3d-views) the base edges (1 to 8), verticals (16 to 128) and top edges (256 to 2048); in their line; `polar` adds the circle of the largest r, keeping the sides when no `MASK` is given; the layer is read and ignored (the border over the data) | no border |
| **k**ey [`on`\|`off`] [`left`\|`right`\|`center`] [`top`\|`bottom`\|`center`] [`inside`\|`outside`\|`lmargin`\|`rmargin`\|`tmargin`\|`bmargin`\|`below`\|`above`\|`at POSITION`] [`horizontal`\|`vertical`] [`box` [`lt`\|`lw`\|`lc`\|`dt`\|`ls` ...]\|`nobox`] [`opaque`] [`reverse`] [`Left`\|`Right`] [`invert`] [`samplen L`] [`spacing S`] [`width W`] [`height H`] [`maxrows N`\|`maxcols N`] [`columns N`] [`offset X,Y`] [`title "text"` [`left`\|`center`\|`right`]] [`font F`] [`textcolor C`\|`tc variable`\|`tc rgb variable`] [`noenhanced`] [`default`] [`autotitle` [`columnhead`]\|`noautotitle`] | show the key, inside the plot area (top right by default), in a margin or at a position, in its layout, see [below](/guide/gnuplot/axes#key); untitled items: as written, by [column header](/guide/gnuplot/data#column-headers), or none; the title centred over the key, `left` or `right` at its left or right side, as gnuplot | hide the key |
| **xti**cs / **yti**cs / **y2ti**cs / **x2ti**cs / **cbti**cs [`add`] [`auto`\|`autofreq` \| `STEP` \| `START,STEP[,END]` \| `("label" pos level, ...)`] [`mirror`\|`nomirror`] [`in`\|`out`] [`scale MAJOR[,MINOR]`\|`scale default`] [`rotate` [`by` *angle*]\|`norotate`] [`left`\|`right`\|`center`] [`axis`\|`border`] [`rangelimited`] [`format "f"`] [`font F`] [`offset X,Y`] [`textcolor C`] [`noenhanced`] | tick positions, see [below](/guide/gnuplot/axes#ticks-and-label-formats); `time`\|`timedate`\|`numeric`: the axis ticked as times or not ([time data](/guide/gnuplot/data#time-data)); `geographic`: the labels in degrees, minutes and seconds by the format ([below](/guide/gnuplot/axes#geographic-tick-labels)); `logscale`\|`nologscale`: on a log axis the step a factor, or added; `noenhanced`: the labels as they are, not as [enhanced text](/guide/gnuplot/text#enhanced-text); `y2tics` and `x2tics` are off by default, see [below](/guide/gnuplot/axes#second-y-axis) and [below](/guide/gnuplot/axes#second-x-axis); `cbtics` those of the color box | no ticks, labels nor grid lines |
| **tic**s [`mirror`\|`nomirror`] [`in`\|`out`] [`scale MAJOR[,MINOR]`\|`scale default`] [`border`] [`rotate` [`by A`]\|`norotate`] [`nooffset`] | the options of every axis' ticks (the scale of the color box's too); the x and y ticks turned off on again (bare or with options, gnuplot's set_tic_prop), see [below](/guide/gnuplot/axes#ticks-and-label-formats) | no ticks on any axis |
| **ticsc**ale `MAJOR` [`MINOR`] | gnuplot's old form of `set tics scale` | — |
| **lmar**gin / **rmar**gin / **tmar**gin / **bmar**gin [[`at`] `screen` `N` \| `N`] | a margin set: `N` characters from the panel's edge, or the border at the page fraction `N` (from the bottom left); bare or negative, computed, see [below](/guide/gnuplot/axes#margins) | computed |
| **marg**ins `L, R, B, T` | the four margins, each [`at screen`] `N` | all computed |
| **zero**axis / **xzero**axis / **yzero**axis / **x2zero**axis / **y2zero**axis [`lt N`] [`lc C`] [`lw W`] [`dt N`] | lines at the zero of the axes (`xzeroaxis`: y = 0), gnuplot's black dots by default | no line |
| **auto**scale [`x`\|`y`\|`x2`\|`y2`\|`cb`\|`z`\|`xy`][`min`\|`max`\|`fix`] [`fix`\|`noextend`] | the axes autoscaled again (all without one), `fix` and `noextend` their ends kept at the data | the ranges fixed as they are (all axes without one), as gnuplot |
| **du**mmy `NAME`[`, ...`] | the variable of plotted [functions](/guide/gnuplot/scripting#functions) (`x`; `t` in polar mode) | `x` |
| **enc**oding [`default`\|`utf8`\|`locale`\|`iso_8859_1`] | the text encoding (`GPVAL_ENCODING`); the output is UTF-8: with `iso_8859_1` the bytes of the texts (an octal `"\351"`) are written as their Latin-1 characters (gnuplot declares its output's encoding instead); other encodings are refused | `default` |
| **termopt**ion [`dash`\|`dashed`] [`enhanced`\|`noenhanced`] [`font F`] | gnuplot's terminal options foresight honours: dashes (always there), [enhanced text](/guide/gnuplot/text#enhanced-text) on (the default) or off, `font "name,size"` the page's [font](/guide/gnuplot/text#fonts) (also `set terminal svg font ...`) | — |
| **for**mat [*axes*] [`"format"`] [`timedate`\|`geographic`\|`numeric`] | tick label format of the *axes* (as `logscale`), see [below](/guide/gnuplot/axes#ticks-and-label-formats); on [time axes](/guide/gnuplot/data#time-data) a time format (`"%H:%M"`); `timedate` makes them time axes (ticks and labels only), `geographic` [geographic](/guide/gnuplot/axes#geographic-tick-labels) ones, `numeric` numeric ones | default labels |
| **xda**ta / **yda**ta / **x2da**ta / **y2da**ta [`time`] | the data of the axis are [times](/guide/gnuplot/data#time-data), read with the `timefmt`; the axis ticked and labelled in time units | numbers |
| **timef**mt `"format"` | the input [time format](/guide/gnuplot/data#time-data), `%d/%m/%y,%H:%M` by default | the default |
| **lab**el [`N`] ... | a [label](/guide/gnuplot/text#labels-arrows-and-objects) | `unset label [N]`: all, or tag `N` |
| **arr**ow [`N`] ... | an [arrow](/guide/gnuplot/text#labels-arrows-and-objects) | `unset arrow [N]` |
| **obj**ect [`N`] ... | an [object](/guide/gnuplot/text#labels-arrows-and-objects): a rectangle, circle, ellipse or polygon | `unset object [N]` |
| **st**yle **arr**ow `N` [`default`\|*arrow options*] | arrow style `N`, used by `set arrow ... as N` | `unset style arrow`: all |
| `unset style fill` | the default fill: empty, bordered (a border `lc bgnd` is the page color) | — |
| **st**yle **rect**angle [`fc C`] [`fs FILL`] [`lw W`] [`dt N`] | the look of the rectangles set next | — |
| **dataf**ile **sep**arator [`whitespace`\|`tab`\|`comma`\|`"chars"`] (`'\t'` the tab too, as gnuplot) | cell separators of data files, see [Data Files](../data-files#separators-csv); no argument: whitespace | whitespace (`unset datafile`) |
| **dataf**ile **mis**sing [`"string"`\|`NaN`] | the cells holding `string` are missing data: a point reading one is left out, its line not broken (a cell read through `column(expr)` is known only when evaluated: undefined there), see [Data Files](../data-files#missing-data-and-comments); no argument: none | none |
| **dataf**ile **com**mentschars [`"chars"`] | the characters starting a comment in data files; no argument: `#` | `#` |
| **dataf**ile **columnhead**ers \| **nocolumnhead**ers | the first row of each dataset is a header, in plots, `stats` and `fit` (other datafile options may follow) | not a header |
| **sam**ples `N`[`,M`] | points of each [function](/guide/gnuplot/scripting#functions), 100 by default; `M` the points along y of the [`splot` functions](/guide/gnuplot/3d#_3d-plots)' iso-curves of x (N by default); expressions truncated to integers, as gnuplot | 100 |
| **iso**samples `N`[`,M`] | the iso-curves of the [`splot` functions](/guide/gnuplot/3d#_3d-plots): M curves of y (the surface grid), N of x; 10 by default; M also the v samples of the [`'++'` pseudo-file](/guide/gnuplot/scripting#sampled-pseudo-files-and) | 10 |
| `view` *rot_x*[`,` *rot_z*[`,` *scale*[`,` *scale_z*]]] \| `map` [`scale S`] \| [`no`]`equal` [`xy`\|`xyz`] \| `azimuth A` \| `projection xy\|xz\|yz` | the [view](/guide/gnuplot/3d#_3d-views) of the 3D plots, gnuplot's `60, 30, 1, 1` by default (an empty field keeps its value); `azimuth` a rotation about the line of sight; `equal` the same unit on x and y (`xyz`: and z); `map` (`projection xy`) seen from above, as a 2D plot; `projection xz\|yz` the xz or yz plane seen edge-on | `60, 30, 1, 1`, no map |
| **cont**our[`s`] [`base`\|`surface`\|`both`] | the [contour lines](/guide/gnuplot/3d#contours) of the 3D surfaces: on the base plane (the default), at their heights, or both (in a map view the three are the same picture); gnuplot's deprecated `set clabel ["format"]` and `unset clabel` are `set cntrlabel format` and `onecolor` | no contour lines |
| **contourf**ill `auto N`\|`ztics`\|`cbtics`\|`palette`\|`firstlinetype N` | the slices of `with contourfill` (one option per command): `N` equal slices of the z range, or from each major z (color box) tick to the next; each in the palette color of its middle, or in linetypes `N`, `N+1`, ... | `auto 5`, the palette |
| **cntrp**aram [`linear`\|`cubicspline`\|`bspline`] [`points N`] [`order N`] [`levels` [`auto` [`N`]\|`N`\|`discrete z1, z2, ...`\|`incremental start, step`[`, end`]]] [`firstlinetype N`] [`sorted`\|`unsorted`] | the [contour](/guide/gnuplot/3d#contours) lines: linear segments, a cubic spline through their points or a B-spline approximation (`order` 2 to 10, 4 by default; `points` per interval, 5); about N automatic levels (5), or the levels given; the first level's linetype; levels high to low; alone, the defaults | — |
| **cntrl**abel [`format "fmt"`] [`onecolor`] [`font "f"`] [`start N`] [`interval N`] | the key labels of the [contour](/guide/gnuplot/3d#contours) levels (`"%8.3g"` by default); `onecolor`: every level in the surface's color, no key entries; font, start and interval (labels on the lines) read | `"%8.3g"`, a color per level |
| **dgrid3d** [`ROWS`[`,COLS`]] [`qnorm` [`Q`]\|`splines`\|`gauss`\|`cauchy`\|`exp`\|`box`\|`hann` [`kdensity`] [`DX`[`,DY`]]] | the scattered data of `splot` [gridded](/guide/gnuplot/3d#gridded-and-masked-surfaces): COLS iso-curves of x, ROWS points along y each (10, 10), every node a weighted mean of the points: inverse distance to the power Q (`qnorm`, 1), thin plate splines, or a kernel of the distance scaled by DX, DY (1, 1); `kdensity` the kernel's weighted sums, a density | not gridded |
| **pm**3d [`at b`\|`s`\|`t`...] [`interpolate N,M`] [`corners2color mean`\|`geomean`\|`harmean`\|`rms`\|`median`\|`min`\|`max`\|`c1`...`c4`] [`implicit`\|`explicit`] [`map`] [`clip`\|`clipz`\|`clip1in`\|`clip4in`] [`border` ...\|`noborder`] | the [pm3d surfaces](/guide/gnuplot/3d#_3d-plots): `set pm3d` alone draws every surface with pm3d too (implicit, as gnuplot); `interpolate` subdivides each quadrangle (0 or negative: gnuplot's automatic counts); `map` is `at b`, `set view map` and the pm3d data and function styles; `border` [`retrace`] [`lc`\|`lt`\|`lw` ...] outlines the quadrangles (black and 1 wide by default, `retrace` in their fill colors); `scansautomatic`\|`scansforward`\|`scansbackward`\|`depthorder` [`base`] the drawing order in 3D views; `lighting` [`primary F`] [`spec`[`ular`] `F`] [`spec2 F`] and `nolighting` the [lighting](/guide/gnuplot/3d#_3d-views) of the surfaces in 3D views; `spotlight` [`rot_x A`] [`rot_z B`] [`rgbcolor C`] [`Phong P`] [`default`] its second light; `flush`, `ftriangles` are read | only the items `with pm3d` (explicit); the pm3d styles back to lines |
| **hid**den3d [`offset N`\|`nooffset`] [...] | the hidden lines of the [3D views](/guide/gnuplot/3d#_3d-views) removed (a painter's algorithm): grid surfaces opaque, their underside in the next linetype | no hidden lines |
| **map**ping [`cartesian`\|`spherical`\|`cylindrical`] | splot's data columns: x:y:z, theta:phi:r or theta:z:r ([3D views](/guide/gnuplot/3d#_3d-views)) | `cartesian` |
| **xyp**lane `at Z` \| `relative F` \| `F`, **ticsl**evel `F` | the base plane of the [3D views](/guide/gnuplot/3d#_3d-views): at the height Z, or F times the z range below it (0.5 by default) | — |
| **wall**[`s`] [`y0`\|`x0`\|`y1`\|`x1`\|`z0`] [`fs ...`] [`fc C`] [`lw W`] | the [grid walls](/guide/gnuplot/3d#_3d-views) of a 3D view, polygons over the planes x = 0, y = 0, x = 1, y = 1 and z = 0 of the graph, half transparent in gnuplot's colors and bordered in black by default, drawn behind the plot or over it as they face; bare, `y0`, `x0` and `z0` | no walls |
| **boxd**epth `D`\|`square` | the depth of `splot ... with boxes` along y: the boxes [in 3D](/guide/gnuplot/3d#_3d-views) with their back, sides and top (`square` as deep as wide on the page) | flat boxes (their front face) |
| **su**rface [`implicit`\|`explicit`] | the surfaces of the [3D plots](/guide/gnuplot/3d#_3d-plots) drawn | not drawn (contours only) |
| **zr**ange, **zl**abel, **zti**cs, **mzti**cs, **zzero**axis | the z axis of the [3D plots](/guide/gnuplot/3d#_3d-plots): its range (the options of `xrange`), label (those of `xlabel`), ticks (those of `xtics`), minor ticks and zero axis | as the x ones |
| **ov**erflow [`float`\|`undefined`\|`NaN`] | an integer overflow of `+ - * **` gives a real (the default), an undefined value or NaN, see [Expressions](/guide/gnuplot/data#expressions-in-using) | `+` and `-` wrap around (two's complement), `*` and `**` give a real, as gnuplot |
| **mou**se, **mac**ros, `pointintervalbox`, **minus**sign, **mic**ro | read and ignored: they change nothing in gnuplot's svg output (interactive terminals, macros always on, `pointinterval` gaps); `minussign` and `micro` only with the default encoding, where gnuplot prints the same characters (refused after `set encoding utf8`); **ur**ange, **vr**ange set the grid of the [`'++'` pseudo-file](/guide/gnuplot/scripting#sampled-pseudo-files-and) | the same |
| `noxtics`, `noytics`, `nox2tics`, `noy2tics`, `nocbtics`, `nomxtics`, `nomytics`, `nokey`, `nogrid`, `noborder` | gnuplot's old forms of `unset xtics`, ... | — |
| **st**yle **d**ata `STYLE` | style of data items without `with` | — |
| **st**yle **f**unction `STYLE` | style of [functions](/guide/gnuplot/scripting#functions) without `with`: `lines`, `points`, `linespoints` | back to `lines` |
| **st**yle **l**ine `N` [`lc` ...] [`lt N`] [`lw W`] [`dt N`] [`pt N`] [`ps S`] | line style `N`, used by `ls N` | — |
| **st**yle **fi**ll `empty`\|[`transparent`] `solid` [`D`]\|[`transparent`] `pattern` [`N`] [`border` [`lc C`\|`-1`\|[`lt`] `N`]\|`noborder`] [`segments N`] | fill of the [boxes and filled curves](/guide/gnuplot/styles#boxes-and-filled-curves) plotted next; gnuplot's abbreviations (`s`, `p`, `tr`, `e`, `bo`, `nobo`); `border lt N` (or `border N`) the color of linetype N; `empty` with border by default; `pattern N` one of the 8 patterns of gnuplot's svg terminal, cycling over the filled items from N; `segments N` a foresight extension, see [below](/guide/gnuplot/styles#themes-and-segmented-fills) | — |
| **mxt**ics / **myt**ics / **my2t**ics / **mx2t**ics / **mcbt**ics [`N`\|`default`\|`time N UNITS`] | minor ticks: `N` intervals between major ticks, gnuplot's count without it; `default`: by default (none, 2..9 on log axes); `time N UNITS` one every N `seconds` ... `years` of a [time axis](/guide/gnuplot/data#time-data); see [below](/guide/gnuplot/axes#ticks-and-label-formats) | no minor ticks |
| `paxis` `N` `range [min:max]` [`reverse`\|`noreverse`] [`extend`\|`noextend`]\|`tics [...]`\|`label "text"` | parallel axis N (a constant expression: `set for [i=1:5] paxis i tics`) of the [parallel axis and spider plots](/guide/gnuplot/styles#parallel-axes-and-spider-plots): its range (autoscaled to its values, not extended; `[max:min]` reversed, the other range words read), ticks (off by default), label | `unset paxis N tics`: no ticks |
| **spi**derplot | spider plot coordinates and data style | back to lines |
| **st**yle `spiderplot` [`fs` FILL] [`lw W`] [`pt N`] [`ps S`] | polygons of the spider plots (empty with border by default) | — |
| `rgbmax` `V` | full intensity of the components of [RGB images](/guide/gnuplot/3d#images-and-palettes) (255 by default) | 255 |
| **pal**ette [`rgbformulae R,G,B`\|`defined (v c, ...)`\|`functions R, G, B`\|`cubehelix` [`start S`] [`cyc`[`les`] `C`] [`sat`[`uration`] `S`]\|`file 'f'` [`index N`] [`every E`] [`using U`]\|`gray`\|`color`\|`viridis`\|`NAME`] [`positive`\|`negative`] [`maxcolors N`] [`model RGB`\|`model HSV`\|`model CMY`] [`gamma G`] | palette of the [images](/guide/gnuplot/3d#images-and-palettes); none: the default (`rgbformulae 7,5,15`); `NAME` a [named palette](/guide/gnuplot/3d#named-palettes) (foresight extension); `defined` takes `v "color"` or `v r g b` (0 to 1), alone gnuplot 6.0's default gradient (dark blue, blue, green, yellow, orange, red, pink); `model HSV` (or gnuplot's `mode HSV`) reads the three components as hue, saturation and value, `model CMY` as cyan, magenta, yellow (gnuplot 6.0's models); `gamma G` the gamma of `gray` and `cubehelix` (1.5); `file` also `using gray:rgb` (`using 1:(rgbcolor(strcol(2)))`, a packed RGB) and `file '-'` (the rows after the command); `functions R, G, B`: three expressions of `gray` (0 to 1), clipped to 0..1, sampled at 1025 levels; `rgbformulae` abbreviates down to `rgb` (`rgbform`, as gnuplot) | — |
| **colormap** `new NAME` \| `NAME range [min:max]` | gnuplot 6.0's named colormaps: the current palette saved as NAME, for [`lc palette NAME`](/guide/gnuplot/styles#colors-per-point-and-from-the-palette); its own range, else the color axis' | — |
| **colors**equence `default`\|`podo`\|`classic`\|`NAME` [`N`] | the [linetype colors](/guide/gnuplot/styles#styles) of the series, `lc N` and the slices: gnuplot's 8 (`default`), `podo` (8), `classic` (13, gnuplot's svg terminal); `NAME [N]` foresight's: the first N (8) colors of a categorical order | — |
| **cbr**ange `[min:max]` | value range of the palette; `*` or empty autoscales an end | autoscaled |
| **cbl**abel `"text"` [`offset X,Y`] [`font F`] [`textcolor C`] [`rotate`\|`norotate`] [`noenhanced`] | color box label: vertical (`rotate`, the default) or horizontal (`norotate`), moved by `offset` in gnuplot's characters | no label |
| **colo**rbox [`vertical`\|`horizontal`] [`default`\|`user`] [`origin X,Y`] [`size W,H`] [`border`\|`bdefault`\|`noborder`] [`invert`\|`noinvert`] [`front`] | color box of the images, see [below](/guide/gnuplot/3d#images-and-palettes) | no color box, every option reset |
| **box**width [`W`] [`absolute`\|`relative`] | box width; no `W`: boxes touching (the default) | boxes touching |
| **st**yle `boxplot` [`range R`\|`fraction F`] [`outliers`\|`nooutliers`] [`pointtype P`] [`candlesticks`\|`financebars`] [`medianlinewidth W`] [`separation S`] [`labels off`\|`auto`\|`x`] [`sorted`\|`unsorted`] | layout of the [boxplots](/guide/gnuplot/styles#box-finance-and-boxplot-styles) plotted next | — |
| **st**yle **textbox** [`N`] [`opaque`\|`transparent`] [`fc C`] [`border` [`lc C`] [`lw W`]\|`noborder`] [`margins X,Y`] | text box style `N` (0 to 3) of the `boxed` labels; as gnuplot's svg terminal, an opaque or bordered style puts the text on the background (no border, no margin drawn) | — |
| **st**yle **hist**ogram `clustered` [`gap G`]\|`errorbars` [`gap G`] [`lw W`]\|`rowstacked`\|`columnstacked` [`title` [`tc C`] [`offset X,Y`] [`boxed`]] [`nokeyseparators`] | layout of the [histograms](/guide/gnuplot/styles#histograms) plotted next; clustered, gap 2 by default; the look of the group titles (`boxed`: on the background, text box style 0) | — |
| `readout` [`on`\|`off`] [`left`\|`right`\|`center`] [`top`\|`bottom`\|`center`] [`horizontal`\|`vertical`] [`opaque`\|`noopaque`] [`size H`] | foresight extension: where and how the [readouts](/guide/gnuplot/styles#readouts) of the panel are drawn | readouts not drawn |
| **ou**tput `"file"` | output file: `.svg`, `.html`, `.txt`, `-`; bare (gnuplot's standard output), and `unset output`: back to the default output | — |
| **te**rminal `svg`\|`html` [**si**ze `W,H`] [**ref**resh `S`] [`enhanced`\|`noenhanced`] [`fontglyphs`\|`fontnames`] [`theme classic`\|`vfd`\|`lcd`\|`washi`\|`night`\|`paper` [`serif`]] [`glow`\|`noglow`] | output format, size in px, HTML reload period, [enhanced text](/guide/gnuplot/text#enhanced-text) on (the default) or off; the SVG's texts drawn from the compiled-in glyphs (`fontglyphs`: the same on every machine, as the PDF) or by font name (`fontnames`, the default; HTML pages keep their texts by name), see [Output Formats](../output-formats#svg); the [theme](/guide/gnuplot/styles#themes-and-segmented-fills) (foresight extension, any terminal) | — |
| **te**rminal `pdfcairo`\|`pdf` [**si**ze `W,H`\|`single`\|`double`] [`font F`] [**fontscale** `S`] [**linewidth**\|`lw` `W`] [**dashlength**\|`dl` `D`] [`rounded`\|`butt`\|`square`] [`color`\|`mono`] [**background** `C`] [`transparent`] [`enhanced`\|`noenhanced`] [`fontglyphs`\|`fontnames`] [`theme paper` [`serif`]] | a PDF, as gnuplot 6.0's pdfcairo: 5 x 3 in, `"Sans,12"` at `fontscale 0.5` (drawn, as cairo does, at 4/3 of its points: 8 pt), lines of 0.5 pt times `linewidth`; sizes in inches or with their units (`8.5cm,6cm`, `240pt,170pt`); `single` and `double` a paper's column and page width (8.5 x 6 cm, 17.8 x 8 cm, foresight extension); `mono` lines and texts black, fills gray; the fonts embedded (`fontnames`: the 14 standard fonts by name); see [Output Formats](../output-formats#pdf) | — |
| **te**rminal `cairolatex` [`pdf`] [`standalone`\|`input`] [`blacktext`\|`colortext`] [**header** `"..."`\|`noheader`] [`font "name,size"`] [**si**ze `W,H`\|`single`\|`double`] [**fontscale** `S`] [**linewidth**\|`lw` `W`] [**dashlength**\|`dl` `D`] [`rounded`\|`butt`\|`square`] [`color`\|`mono`] | a LaTeX picture (`NAME.tex`) whose texts LaTeX sets, over its drawing as a PDF (`NAME.pdf`, `NAME-inc.pdf` when `standalone`), as gnuplot 6.0's cairolatex: its macros, `\put` positions in 0.05 bp, tick numbers in math (`$%h$`), automatic titles escaped; laid out for `font ",11"` at `fontscale 0.6`; `eps`, `png` and `enhanced` refused; see [Output Formats](../output-formats#latex-pictures-cairolatex) | positions from foresight's layout, not gnuplot's |
| **te**rminal `push`\|`pop` | read: foresight keeps its one terminal | — |
| **te**rminal `dumb` [**si**ze `COLS,ROWS`] [`mono`\|`ansi`\|`ansi256`\|`ansirgb`] | text output, 79 x 24 by default, on the standard output; the series in ANSI colors, see [Output Formats](../output-formats#text) | — |
| **te**rminal `block` [`half`\|`quadrants`\|`sextants`\|`braille`] [**si**ze `COLS,ROWS`] [`mono`\|`ansi`\|`ansi256`\|`ansirgb`] | text output drawn with Unicode block or Braille characters, 2 x 2 dots per character by default (`quadrants`), see [Output Formats](../output-formats#block-characters) | — |
| **multi**plot [**lay**out `R,C`] [**row**sfirst\|**col**umnsfirst] [**down**wards\|**up**wards] [**t**itle `"text"` [`font F`]] [**mar**gins [`screen`\|`char`] `L,R,B,T`] [**spa**cing [`screen`\|`char`] `X[,Y]`] | grid of panels, or panels in their `origin`/`size` boxes without layout, see [below](/guide/gnuplot/axes#multiplot) | back to one panel |
| **or**igin [`X,Y`] | bottom left corner of the plot, page fractions (default `0,0`); in a multiplot layout, the next panel only, then the layout resumes (as gnuplot) | — |
| **si**ze [**sq**uare\|**nosq**uare\|**ra**tio `R`\|**nora**tio] [`W,H`] | plot size, page fractions (default `1,1`; in a multiplot layout, the next panel only, as gnuplot); `square`, `ratio R` (> 0): the plot area height over width; `ratio -R`: the length of a y unit R times that of an x unit (`ratio -1`: a circle stays round, as gnuplot) | — |

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
being no mouse, as gnuplot on a terminal without one; `bind`, the hot keys of the interactive terminals, is read and
does nothing. In a loop with a plot, `while (1) { plot ...; pause 5 }`
rewrites the output every 5 seconds: the plot of a running job, seen live in the HTML page with `set terminal html
refresh 5` (each output is written whole, atomically). `reread`, the old idiom, is an error: gnuplot 6.0 rejects it as
deprecated. [`foresight --watch`](../cli#watch-mode) does the same without a loop, re-running the script when its data
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
the statements in it); `reset session` and `undefine` keep them. `set encoding` takes `default`, `utf8`, `locale` and
`iso_8859_1` (the output is UTF-8; other encodings are refused). `GPVAL_COMPILE_OPTIONS` names `+CHI_SHAPES`, as
gnuplot built with concave hulls.

`exit` ends the script file being read, as gnuplot: a file run by `load` or `call` returns to its caller, the script
given to the command line ends (its output written). `exit message "text"` writes the text first, `exit error "text"`
fails with it; `quit`, `exit gnuplot` and `exit status N` end the run, the command line returning `N`.

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
  `unitweights` with two columns; `yerr`, `yerror`, `zerror`, `zerrors` as `yerrors`; `index`, `every`; a range
  `[min:max]` before the function keeps the points with x inside. `xyerrors` reads `X:Y:XERROR:YERROR` and weighs each
  point by its effective error sqrt(YERROR² + (f'(X) XERROR)²), the slope f' of the model at the parameters being
  tried (Orear's effective variance, as gnuplot's).
- Without an error keyword, gnuplot's rule: of three columns or more the last is the errors unless the function uses
  the variable that column would be; `fit h(x,y) 'grid.dat' using 1:2:3` fits a function of x and y with unit
  weights.
- A complex model value (`sqrt` of a negative number) counts by its real part, as gnuplot's.
- `via 'file'` reads the parameters from a file of `name = value` lines (`#` comments), each fitted unless its line
  is marked `# FIXED`, as gnuplot's parameter files.
- Several independent variables, as gnuplot 6.0: `using X:Y:Z:S` fits a function of `x` and `y` to Z with the errors S
  (`fit f(x,y) 'grid.dat' using 1:2:3:(1) via a, b, c`), up to 12 variables with as many columns before the last two;
  the names are those of `set dummy` (`set dummy x, y, w`), then gnuplot's order `x`, `y`, `t`, `u`, `v`, one range per
  variable before the function
  (`fit [0:1][*:*] ...`). Array elements are parameters too: `via A[1], A[2]`.
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
| `start_lambda L` \| `lambda_factor F` | the first lambda (gnuplot's estimate by default); its factor (10) |
| [`no`]`prescale` \| [`no`]`errorscaling` \| [`no`]`errorvariables` | parameters scaled by their initial values; errors scaled by the reduced chi-square; *name*`_err` set (all on) |
| [`no`]`covariancevariables` | `FIT_COV_`*a*`_`*b* set, the covariance of each pair of parameters (off) |

Not supported: `set fit verbose`.
The [cookbook](/manual/cookbook#fitting-a-model) fits an order of accuracy; Fortran programs call `fit` directly
([library](../library.md#fitting-a-model)).

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
(as plot's; without it the first two columns if the first line has two), `index`, `every` (its fields may be
expressions, `every ::j:0:j:0`), `matrix`: the values of a matrix as one column, with gnuplot's `STATS_size_x`,
`STATS_size_y`, `STATS_columns` (the width) and the places of the extremes from 0 (`STATS_index_min_x`, `_y`,
`STATS_index_max_x`, `_y`), a record per value; `every` keeps columns (the points) and rows (the blocks) of it, as
for `plot ... matrix`. Not supported: `name columnheader`, the voxel grid form.
