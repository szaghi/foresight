# Changelog

All notable changes to this project are documented here.
Versions follow [Semantic Versioning](https://semver.org/).
Format follows [Keep a Changelog](https://keepachangelog.com/).

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



