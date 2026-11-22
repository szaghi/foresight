# Changelog

All notable changes to this project are documented here.
Versions follow [Semantic Versioning](https://semver.org/).
Format follows [Keep a Changelog](https://keepachangelog.com/).

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



