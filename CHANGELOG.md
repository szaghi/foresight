# Changelog

All notable changes to this project are documented here.
Versions follow [Semantic Versioning](https://semver.org/).
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [0.16.0] — 2026-11-24
### Added
- **expression**: Tm_sec ... tm_yday, tm_week and week dates, as gnuplot 6.0

- **script**: Set pixmap, PNG images on the page, as gnuplot 6.0

- **script**: Fonts of the title, labels, key and page, as gnuplot 6.0

- **axes**: Fonts of the tick labels, as gnuplot 6.0

- **script**: Fonts of theta labels, timestamp and group titles


### Documentation
- Week dates, and the examples redrawn for markers and color boxes

- Fonts per text element


### Fixed
- **svg**: Marker lines as gnuplot's svg, whatever the line width

- **axes**: Autoscaled linear color axis extended to its ticks, as gnuplot 6.0

- **svg**: Front objects over the point markers, as gnuplot 6.0

- **nvfortran**: Ellipse sizes and set key at, without host association

- **axes**: Back objects over the polar grid and zero axes, as gnuplot 6.0

- **axes**: X and x2 label offsets move their margins, as gnuplot 6.0

- **svg**: Polar surface cells without seams, as gnuplot 6.0

- **script**: A datablock after other commands on its line, as gnuplot 6.0

- **expression**: Undefined variables in guarded operands, as gnuplot 6.0


## [0.15.0] — 2026-11-24
### Added
- **script**: Set for [...] and unset for [...], as gnuplot 6.0

- **format**: Gnuplot's power, prefix and multiple conversions in set format

- **axes**: Tick label format, font, offset and textcolor, as gnuplot 6.0

- **axes**: Set xtics axis|border and rangelimited, as gnuplot 6.0

- **key**: Set key spacing, height, maxrows, maxcols, textcolor and box line, as gnuplot 6.0

- **expression**: Gnuplot 6.0's special functions, to its last digit

- **script**: Set pointsize, as gnuplot 6.0

- **script**: Set linetype, as gnuplot 6.0

- **axes**: Set offsets, as gnuplot 6.0; set autoscale noextend honoured

- **script**: Set timestamp, as gnuplot 6.0

- **axes**: Set clip one|two|points, gnuplot 6.0's clip two default

- **script**: Set parametric, as gnuplot 6.0

- **axes**: Set jitter, as gnuplot 6.0

- **script**: Plot styles and smooth filters abbreviated as gnuplot 6.0

- **script**: Plot items as gnuplot 6.0: assignments, sampling ranges, for [i=A:*]

- **axes**: Axis label and title options, as gnuplot 6.0

- **script**: Functions drawn with boxes and filledcurves, as gnuplot 6.0

- **script**: Lc variable on circles, ellipses and boxes, as gnuplot 6.0

- **key**: Set key columns N, as gnuplot 6.0

- **figure**: Multiplot fill order and title font, as gnuplot 6.0

- **script**: Fill style, border and margin forms of gnuplot 6.0

- **script**: Tic and parallel axis arguments as expressions, as gnuplot 6.0

- **expression**: Sum [i=a:b] expressions, GPVAL_LINENO, show and test, as gnuplot 6.0

- **script**: Xticlabel(N) and every abbreviation of xticlabels, as gnuplot 6.0

- **style**: Custom dash types and the special linetype colors, as gnuplot 6.0

- **palette**: Set palette model HSV and r g b triples in defined, as gnuplot 6.0

- **script**: Overflow modes, mttics, refresh and settings without effect on svg, as gnuplot 6.0

- **expression**: Assignments and serial evaluation inside expressions, as gnuplot 6.0

- **expression**: Split() and join(), as gnuplot 6.0

- **script**: Call arguments and GPVAL_LINENO as gnuplot 6.0

- **script**: Skip N, string expression tic labels, unterminated strings, as gnuplot 6.0

- **expression**: Complex numbers, as gnuplot 6.0

- **script**: Set linetype with gnuplot's transparent colors, as gnuplot 6.0

- **figure**: Multiplot layout margins and spacing, range reverse, as gnuplot 6.0

- **script**: Set palette functions, as gnuplot 6.0

- **script**: Fc in plot items and rgb with a string variable, as gnuplot 6.0

- **axes**: Lc variable on candlesticks, boxxyerror, histograms, filledcurves and polygons

- **script**: Set datafile columnheaders and lt rgb, as gnuplot 6.0

- **axes**: With fillsteps, as gnuplot 6.0

- **script**: Set grid r, ttics lists and grid lt black, as gnuplot 6.0

- **script**: Object and arrow options of the demos, as gnuplot 6.0

- **svg**: Set style textbox and boxed labels, color names by prefix, notitle columnhead

- **script**: Set label ... boxed, as gnuplot 6.0

- **script**: Keyentry, boxed titles, and small gnuplot forms of the demos

- **script**: The '+' and '++' pseudo-files and sampling ranges, as gnuplot 6.0

- **script**: Vectors and arrows size, fixed, as N and per-point colors, as gnuplot 6.0

- **script**: Set style data|function filledcurves options, fit on arrays

- **script**: Title at end|beginning|X,Y, as gnuplot 6.0

- **script**: Character points, pt "c", with tc and pointnumber, as gnuplot 6.0

- **axis**: Autoscale limits [lb<*<ub:lb<*<ub], as gnuplot 6.0

- **script**: Lc palette z on the shape styles, variable colors of error bars and labels, ellipse units

- **script**: With labels rotate variable, as gnuplot 6.0

- **script**: Keyentry with the styles of data, as gnuplot 6.0

- **script**: Nonuniform matrix images and index "name", as gnuplot 6.0

- **polar**: Set logscale r, impulses from the pole, rotated r labels, as gnuplot 6.0

- **polar**: Filledcurves [above|below] r=V, as gnuplot 6.0

- **polar**: Set ttics rotate and offset, as gnuplot 6.0

- **expression**: Array elements assigned inside expressions, as gnuplot 6.0

- **script**: Arrowstyle variable and arrow words among the item options, as gnuplot 6.0

- **script**: Filledcurves above|below to y = 0, rgbform, fc palette cb, as gnuplot 6.0

- **script**: Using forms of the gnuplot demos, as gnuplot 6.0

- **script**: Sharpen and set ticslevel, as gnuplot 6.0

- **spiderplot**: Newspiderplot groups and keyentry with spiderplot, as gnuplot 6.0

- **polar**: Error bars along the radius, as gnuplot 6.0

- **palette**: Set colormap and lc palette NAME, as gnuplot 6.0

- **smooth**: Smooth path, as gnuplot 6.0

- **script**: Stats matrix, every on matrices, set xlabel boxed, as gnuplot 6.0

- **script**: Gnuplot's default tick labels in scripts, `% h`

- **axes**: Set size ratio -R, polar positions and labels, as gnuplot 6.0

- **script**: Set link x2|y2 [via f inverse g], as gnuplot 6.0

- **polar**: Inline ranges in polar mode, as gnuplot 6.0

- **parallelaxes**: Paxis range options, lc variable and lc palette z per row, as gnuplot 6.0

- **format**: Tick formats without a conversion; format "" hides labels, as gnuplot 6.0

- **script**: Using data formats, smoothed bands, short times, as gnuplot 6.0

- **fit**: Several independent variables, ranges per variable, array parameters, as gnuplot 6.0

- **script**: Column forms of the gnuplot demos, as gnuplot 6.0

- **script**: Key samples and key title justification, as gnuplot 6.0

- **script**: Inline data '-', as gnuplot 6.0

- **axes**: Set nonlinear x|y via f inverse g, as gnuplot 6.0

- **script**: Parser forms of the gnuplot demos, as gnuplot 6.0

- **script**: Time tics, labels with tic labels, zones and boxplot colors, as gnuplot 6.0

- **script**: Default point types of the item's linetype, as gnuplot 6.0

- **script**: Set rlabel and justified titles at beginning or end, as gnuplot 6.0

- **script**: Convexhull, concavehull, expand and the forms of their demos, as gnuplot 6.0

- **script**: String escapes, set encoding iso_8859_1 and \U+ in enhanced text, as gnuplot 6.0

- **script**: Set polar grid and with surface, as gnuplot 6.0

- **script**: Binary arrays and images on nonlinear axes, as gnuplot 6.0

- **script**: Ps variable and labels hypertext, as gnuplot 6.0

- **script**: Zsort, as gnuplot 6.0


### Changed
- **axes**: Panel colormaps the last component of axes_object


### Documentation
- Special functions, set for, tick and key options, format powers

- Offsets, parametric, clip, linetype, pointsize, jitter, timestamp

- Plot items, sums, fills, dashes, HSV palette, key, label and multiplot options

- Complex numbers, assignments, fillsteps, lc variable styles, textbox, polar labels and more

- Sampled pseudo-files, vector styles, titles at, character points, polar bands and more

- Array assignments, arrow styles per arrow, rugs, sharpen, spider sets, colormaps and more

- Linked axes, inline data, two-variable fits, key samples and more

- Nonlinear axes, reversed r, UTF-8 names, tic labels and more

- Hulls, polar surfaces, binary images, hypertext, zsort and more


### Fixed
- **script**: Coordinates of set label, arrow and object written with blanks

- **docs**: A gnuplot message in the gammafun docstring broke the API pages

- **svg**: Point markers drawn whole across the plot border, as gnuplot

- **script**: Reset session restores the default linetypes, as gnuplot 6.0

- **style**: Nvfortran 26.9 builds of steps 01-03 compile and pass

- **script**: Nvfortran 26.9 builds of steps 08-13 pass again

- **script**: Tic arguments joined through a temporary, for nvfortran 26.9

- **expression**: Join() through an index variable, for nvfortran 26.9

- **axis**: Parallel axes built by components, for nvfortran 26.9 -O0

- **script**: Colormap names looked up without an allocatable dummy, for nvfortran 26.9 -O2

- **polar**: Negative r with a fixed r range, as gnuplot 6.0

- **axes**: A title with new lines on several lines, as gnuplot 6.0

- **script**: An empty range end keeps the end, as gnuplot 6.0

- **script**: No internal functions read in option conditions, for nvfortran 26.9 -O2

- **axes**: Linked axis set up by a module procedure, for nvfortran 26.9

- **axes**: Linked axis automatic ticks and bare keyentry samples, as gnuplot 6.0

- **script**: The fill border along closed filledcurves only, as gnuplot 6.0

- **axes**: One probe axis in linked_axis, for nvfortran 26.9

- **script**: Colors by number, wrapped keys, row stacks and label lines, as gnuplot 6.0

- **script**: Fill colors, boxplot whiskers, key samples and parallel axes, as gnuplot 6.0

- **script**: Stacked colors, enhanced data labels, blanked points and titles, as gnuplot 6.0

- **script**: Polar grid line style and title options alone, as gnuplot 6.0

- **script**: Labels, keys, missing columns, boxplots, ellipses and polar grids, as gnuplot 6.0


### Performance
- **script**: Binary arrays read in linear time


## [0.14.0] — 2026-11-22
### Added
- **script**: Gnuplot's GPVAL variables, set encoding, exit and quit

- **axes**: Set tics, unset tics, set ticscale and tick scales, as gnuplot 6.0

- **axes**: Key reverse, Left, invert, opaque, samplen, width, offset, title; title offset

- **axes**: Set lmargin, rmargin, tmargin, bmargin and set margins, as gnuplot 6.0

- **script**: Rand, exist, the old one-line if, set dummy, set autoscale, range options, set bars

- **axes**: Set grid lines, layer and style, as gnuplot 6.0

- **axes**: Set border line options, set zeroaxis, set termoption, as gnuplot 6.0

- **text**: Enhanced text in titles, labels, key and ticks, as gnuplot 6.0


### Documentation
- Tick scale, key layout, margins, grid, zero axes, border, GPVAL, exit, rand, old if

- Enhanced text, reference, recipe and gallery


## [0.13.0] — 2026-11-22
### Added
- **expression**: Recursive user functions, as gnuplot 6.0

- **expression**: Bitwise operators and hex and octal integers, as gnuplot 6.0

- **script**: Array slices, as gnuplot 6.0

- **script**: Set print $NAME, as gnuplot 6.0

- **script**: Plot with table and set table separator, as gnuplot 6.0

- **script**: Function blocks and gnuplot's undefined value, as gnuplot 6.0


### Documentation
- Recursive functions, bitwise operators, slices, with table, set print $NAME, function blocks


### Fixed
- **script**: Undefine as gnuplot 6.0 on what is not a name


## [0.12.0] — 2026-11-22
### Added
- **expression**: String columns, strcol and columnhead, as gnuplot 6.0

- **script**: Datablocks, load, call, eval and macros, as gnuplot 6.0

- **time**: Time axes, timefmt and the time functions, as gnuplot 6.0

- **histograms**: Newhistogram, errorbars and columnstacked, as gnuplot 6.0

- **annotations**: Set label, set arrow and set object, as gnuplot 6.0

- **script**: Arrays, ARGV and datablock lines, as gnuplot 6.0

- **script**: System, command substitution, reset and set table, as gnuplot 6.0

- **script**: Pause, and reread rejected as gnuplot 6.0

- **annotations**: Arrow styles, rectangle style, dashed objects, character coordinates

- **plot**: Ytic, x2tic, y2tic, pointinterval, filledcurves to vertical lines, set errorbars, set mxtics time


### Documentation
- Strings columns, datablocks, time axes, histograms, annotations, animations

- Arrays, shell commands, reset, pause, tables, annotation styles, tick labels on any axis


### Fixed
- **tokens**: No merge of achar in the string escapes, an ifx internal error

- **script**: Reset in a multiplot resets the next panel, not the one drawn

- **expression**: No read of an unread token after a syntax error

- **script**: Color names and numbers as gnuplot 6.0 reads them


## [0.11.0] — 2026-11-21
### Added
- **expression**: String values, as gnuplot 6.0

- **script**: Print and set print, as gnuplot 6.0

- **script**: String expressions wherever a string goes, as gnuplot 6.0

- **script**: Do for, while, if/else, break and continue, as gnuplot 6.0

- **script**: Plot for, as gnuplot 6.0

- **stats**: Gnuplot's stats, in scripts and from Fortran


### Documentation
- Strings, print, blocks, plot for and stats


### Fixed
- **expression**: A syntax error ends the reader

- **cli**: No output file reported for a script that plots nothing


## [0.10.0] — 2026-11-21
### Added
- **axes**: Rotated x2 tick labels, as gnuplot 6.0

- **fit**: Gnuplot's fit for Fortran models

- **script**: Fit in scripts, as gnuplot 6.0


### Documentation
- **fit**: Fit in the reference, the cookbook, the gallery and the library


### Fixed
- **key**: The point sample of a color per point in the last point's color

- **dumb**: No empty row between the title, the x2 label and its ticks

- **fit**: Build with ifx 2026.2


## [0.9.0] — 2026-11-21
### Added
- **smooth**: Bins, as gnuplot 6.0

- **smooth**: Mcsplines, the monotone spline of gnuplot 6.0

- **style**: Lc palette z, cb and frac, as gnuplot 6.0

- **key**: Set key at a position and in the margins, as gnuplot 6.0


### Documentation
- Audit against the features, gaps filled

- **home**: The gallery follows the cookbook, every recipe shown


### Fixed
- **series**: The bins span without an optional argument, for nvfortran

- **polar**: A set trange leaves out the data beyond it, as gnuplot 6.0


## [0.8.0] — 2026-11-21
### Added
- **smooth**: Csplines, acsplines, bezier, sbezier and kdensity

- **script**: Lc variable and lc rgb variable, as gnuplot 6.0

- **axes**: The second x axis, as gnuplot 6.0

- **theme**: Washi and night, foresight's identity in light and dark


### Documentation
- Figures in the site's light and dark modes

- **readme**: The README in SETH's style

- **readme**: A self-ironic author line, as the other projects

- **home**: Authors and license as in the README


### Fixed
- **datafile**: Skip cells with no number in plain columns, as gnuplot

- **ticks**: Default log minor ticks between majors decades apart, as gnuplot

- **smooth**: Splines right under nvfortran 26.9

- **script**: Lc variable reads the linetype colors without an associate


## [0.7.0] — 2026-11-20
### Added
- **ticks**: Explicit tick lists and set xtics add, as gnuplot 6.0

- **ticks**: Minor ticks, set mxtics, mytics, my2tics and mcbtics

- **ticks**: Rotated x tick labels and outward ticks, as gnuplot 6.0

- **script**: Inline ranges, plot [x] [y] ..., as gnuplot 6.0

- **datafile**: Set datafile missing and commentschars, as gnuplot 6.0


## [0.6.2] — 2026-11-20
### Fixed
- Foresight compiles with nvfortran 26.9 and ifx 2026.2 under FIGURE's flags

- **datafile**: Xtic labels keep their length under a conforming compiler

- Foresight's suite passes under nvfortran 26.9


## [0.6.1] — 2026-11-20
### Added
- **ticks**: Automatic ticks step as gnuplot's, by the range only


## [0.6.0] — 2026-11-20
### Added
- **axes**: Set cbtics, set format cb and set logscale cb, as gnuplot 6.0

- **axes**: Set colorbox options, as gnuplot 6.0

- **expression**: User variables and functions in compiled expressions

- **script**: User variables and functions in scripts, as gnuplot 6.0


## [0.5.0] — 2026-11-20
### Added
- **build**: Fpm support

- **install**: The one-line installer

- **palette**: Tables of 44 named palettes, generated from the original releases

- **palette**: Set palette NAME, the named palettes, any case

- **palette**: Cividis named palette

- **palette**: Cubehelix palette, as gnuplot 6.0

- **palette**: Black_body named palette

- **palette**: Set palette file, as gnuplot 6.0

- **figure**: Set_palette_gradient, a palette gradient from arrays

- **style**: Set colorsequence, gnuplot's and the categorical orders


### Documentation
- New identity, Fugaku mark in the Kurenai palette

- **palette**: Name the series colors linetype colors, list the defined color names

- **palette**: Named palettes recipe, swatch of every name, goldens

- **features**: The styles row names the linetype colors


### Fixed
- **fpm**: Fpm install installs the library

- **docs**: The colormaps module docstring no longer breaks the API pages

- **palette**: Color restores the last palette set, as gnuplot

- **axes**: No bottom margin for x tick labels that are not drawn


## [0.4.0] — 2026-10-09
### Added
- Add steps, impulses, dots and error-line styles

- Add box, candlestick, finance and boxplot styles

- Add vectors, arrows, ellipses, polygons, labels and sectors

- Add fill patterns, filledcurves modes and rgb images

- Add parallel axis and spider plots


### Documentation
- Cover every feature in the cookbook and the landing gallery


## [0.3.0] — 2026-10-09
### Added
- Add boxes, filled curves and fill styles

- Add histograms and xtic category labels

- Add vfd and lcd themes and segmented bar fills

- Add image heatmaps, palettes and the color box

- Add circles, wedges, pie and donut charts

- Add gauge, radar and rose panel charts

- Add polar plots with the gnuplot round-plot idiom


## [0.2.3] — 2026-10-09
### Added
- Add seven-segment readouts for live monitoring


## [0.2.2] — 2026-10-08
### Added
- Add block terminal, smooth filters and live-monitoring viewer keys


### Documentation
- Rebuild the documentation around a tutorial, a cookbook and live plots


## [0.2.1] — 2026-10-08
### Added
- **script**: Add column headers, point types and keys outside the plot


### Fixed
- **ci**: Skip the release install smoke test while the repo is private


## [0.2.0] — 2026-10-08
### Added
- **script**: Add CSV separators, function plots and a second y axis

- **script**: Add set style function


### Fixed
- **ci**: Run install smoke test from the release workflow

- **build**: Exclude dependency docs from source scan

- **datafile**: Read cells as gnuplot and keep tick positions on set xtics


## [0.1.0] — 2026-09-29
### Added
- Initial foresight scaffold and static SVG plotting core

- **html**: Add interactive HTML output with gnuplot-like viewer

- **cli**: Add gnuplot-subset interpreter, data files and watch mode

- **figure**: Add multiplot, error bars and dumb text terminal ⚠ BREAKING CHANGE

- **script**: Add gnuplot expressions in using fields

- **script**: Add tick settings, label formats, key placement and styles

- **figure**: Add manual multiplot with set origin and set size


### Documentation
- Add VitePress documentation and fix dumb terminal text layout

- Add README and document foresight as a FoBiS dependency



