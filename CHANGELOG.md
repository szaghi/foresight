# Changelog

All notable changes to this project are documented here.
Versions follow [Semantic Versioning](https://semver.org/).
Format follows [Keep a Changelog](https://keepachangelog.com/).

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



