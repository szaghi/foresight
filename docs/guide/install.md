---
title: Installation
---

# Installation

foresight is a Fortran library (`libforesight.a`, `use foresight`) and a command line tool (`foresight`) that runs
gnuplot scripts. There are three ways to install them:

1. the one-line installer;
2. a build with FoBiS;
3. a build with fpm.

After installing, [check the install](#check-the-install) and [use the library](#use-the-library).

## Requirements

| | Needed | Notes |
|---|---|---|
| **Fortran compiler** | Fortran 2018 | Tested in CI: gfortran 16.2, nvfortran 26.9, Intel ifx 2026.2. nvfortran 26.9 miscompiles some valid Fortran; foresight works around what it meets ([#3](https://github.com/szaghi/foresight/issues/3)). |
| **Operating system** | Linux, or another POSIX system | Tested in CI on Linux. foresight calls three POSIX functions through `bind(C)`: `rename`, `nanosleep`, `popen`. macOS is POSIX but not tested in CI. |
| **Windows** | through [WSL 2](https://learn.microsoft.com/windows/wsl/) | WSL runs Linux, and foresight with it. Native Windows (MSVC or MinGW toolchains) is not supported: `nanosleep` and `popen` are not standard there. A page or PDF written in WSL opens in any Windows browser or viewer. |
| **Build system** | one of [FoBiS](https://github.com/szaghi/FoBiS) 3.8+ or [fpm](https://fpm.fortran-lang.org) | The one-line installer installs FoBiS itself when it is missing (in a private environment, with Python 3.11+). No CMake or make build is shipped. |
| **Dependencies** | none to install | PENF, BeFoR64, FACE and StringiFor are fetched by FoBiS or fpm, and bundled in the release tarball. |

What foresight's outputs need:

| To... | You need |
|---|---|
| view an interactive page (`.html`) or an SVG | any browser; the page is one self-contained file |
| write a PDF | nothing: foresight writes PDF itself, with its fonts compiled in |
| view or print a PDF | any PDF viewer |
| use TeX math in labels | nothing: foresight lays it out and draws it ([TeX math](math)) |
| include a `cairolatex` figure | LaTeX with the `graphicx` and `color` packages ([LaTeX labels](latex)) |
| build the example paper | LuaLaTeX or Tectonic (`scripts/build_paper.sh`) |
| run the viewer's tests, build these docs | [Node.js](https://nodejs.org) |
| compare pages with gnuplot (fidelity harness) | gnuplot 6.0 and a headless Chrome |

## One-line install

```bash
curl -fsSL https://github.com/szaghi/foresight/releases/latest/download/install.sh | bash
```

This installs the latest release into `~/.local`, with the build system and compiler you choose.

- **Build system:** `--build fobis|fpm`; a menu asks if you don't say. The fpm build also installs the `foresight`
  command; the fobis build installs the library only.
- **Compiler:** `--fc NAME`, or `--gnu`, `--intel`, `--nvidia`; `$FC`, else gfortran, by default.
- **One install per compiler:** `lib/foresight/<compiler>-<version>/` and `include/foresight/<compiler>-<version>/`.
- **pkg-config:** `foresight.pc` in `~/.local/lib/pkgconfig`.

Pass options after `bash -s --`, for example:

```bash
curl -fsSL https://github.com/szaghi/foresight/releases/latest/download/install.sh | bash -s -- --build fpm --gnu --prefix /opt/foresight
```

`--help` lists every option, `--dry-run` shows what would be done, `--uninstall` removes the install. The installer
is FoBiS's ([one-line installer](https://szaghi.github.io/FoBiS/cookbook/installer)). Then compile against the
install through pkg-config:

```bash
export PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH
gfortran $(pkg-config --cflags foresight) my_program.f90 $(pkg-config --libs foresight) -o my_program
```

## With FoBiS

### Build from the sources

```bash
git clone https://github.com/szaghi/foresight
cd foresight
fobis fetch                                  # PENF, BeFoR64, FACE, StringiFor into src/third_party
fobis build --mode foresight-static-gnu      # the library: lib/libforesight.a, its modules in lib/mod
fobis build --mode foresight-gnu             # the command line tool: bin/foresight
```

Then compile your program against the modules and the library:

```bash
gfortran -I foresight/lib/mod my_program.f90 foresight/lib/libforesight.a -o my_program
```

`fobis build --lmodes` lists every mode:

| Mode | Builds |
|---|---|
| `foresight-static-gnu`, `foresight-static-intel` | the static library `libforesight.a` in `lib/` |
| `foresight-gnu`, `foresight-intel` | the `foresight` command line tool in `bin/` |
| `tests-gnu`, `tests-intel`, `tests-nvf` | the test programs in `exe/` |
| `tests-gnu-debug`, `tests-intel-debug`, `tests-nvf-debug` | the tests with runtime checks and floating point traps |

### As a FoBiS dependency

Declare foresight and PENF, its only dependency at compile time, in your project's `fobos`:

```ini
[dependencies]
deps_dir  = src/third_party
PENF      = https://github.com/szaghi/PENF
foresight = https://github.com/szaghi/foresight :: tag=v0.20.0
```

```bash
fobis fetch     # clone the sources
fobis build     # the foresight modules your program uses are compiled with it
```

With the default `use=sources`, the foresight modules are compiled as part of your build. `use=fobos` does not work
yet: FoBiS builds foresight with its own `fobos` but does not fetch foresight's dependencies inside it.

## With fpm

### Build from the sources

```bash
git clone https://github.com/szaghi/foresight
cd foresight
fpm build --profile release                  # the library and the command line tool
fpm run foresight -- script.gp               # run a gnuplot script
fpm install --prefix ~/.local                # bin/foresight, the library and its modules
```

fpm fetches the dependencies itself. `fpm test` runs the test programs listed in `fpm.toml`.

### As an fpm dependency

In your project's `fpm.toml`:

```toml
[dependencies]
foresight = { git = "https://github.com/szaghi/foresight", tag = "v0.20.0" }
```

`use foresight` in your sources; `fpm build` compiles foresight and its dependencies with your project.

## Check the install

The command line tool runs gnuplot commands without a script:

```bash
foresight -e "set terminal dumb size 60,16; plot sin(x)"   # a plot as text, in the terminal
foresight -e "plot sin(x), cos(x)" -o check.html           # an interactive page: open it in a browser
```

The library, with the smallest program:

```fortran
program check
use foresight, only : figure_object, R8P
implicit none
type(figure_object) :: fig
call fig%plot([1.0_R8P, 2.0_R8P, 3.0_R8P], [1.0_R8P, 4.0_R8P, 9.0_R8P], title='y = x^2')
call fig%save('check.svg')
endprogram check
```

```bash
gfortran $(pkg-config --cflags foresight) check.f90 $(pkg-config --libs foresight) -o check && ./check
```

A `check.svg` with three points joined by lines means the library works.

## Use the library

A complete program: two panels, three line styles, a log axis, and four output files. It is
[`docs/examples/src/qs_library.f90`](https://github.com/szaghi/foresight/blob/master/docs/examples/src/qs_library.f90),
compiled and run with the documentation.

### The module

<<< @/examples/snippets/qs_library-use.f90{fortran}

`use foresight` gives the whole public API and the PENF kinds: `I4P` for integers, `R8P` for reals (double
precision). `figure_object` is a figure; it starts with gnuplot's defaults (600 x 480 px, autoscaled axes, the key top
right).

### The data

<<< @/examples/snippets/qs_library-data.f90{fortran}

Series are plain arrays of `real(R8P)`, `x` and `y` of the same size. The figure copies them, so they can change after
the call. A `NaN` is a gap in the line, not an error.

### The figure

<<< @/examples/snippets/qs_library-figure.f90{fortran}

Every method is named after the gnuplot command it does: `set_title` is `set title`, `set_grid` is `set grid`, and so
on. The [gnuplot reference](/guide/gnuplot-subset) documents the library too. `set_multiplot` lays out a grid of
panels; the settings that follow apply to the current panel.

### The series

<<< @/examples/snippets/qs_library-series.f90{fortran}

`plot` adds one series to the current panel. Its optional arguments are gnuplot's item options:

| Argument | gnuplot | Here |
|---|---|---|
| `title` | `title` | the key entry; an empty title keeps the series out of the key |
| `with` | `with` | `lines` (the default), `points`, `linespoints`, `boxes`, `filledcurves`, `yerrorbars`, `image`, ... |
| `lw`, `dt` | `lw`, `dt` | line width [px], dash type (1 solid, 2-5 dashed) |
| `lc` | `lc` | a color: a name (`'gray'`) or `'#rrggbb'` |
| `pt`, `ps` | `pt`, `ps` | point type (7: filled circle) and size |

Every option, styles and series kinds included, is in the [Fortran Library](library) reference.

### A second panel

<<< @/examples/snippets/qs_library-panel.f90{fortran}

`next_panel` moves to the next cell of the multiplot, carrying the settings over, as gnuplot does. `set_enhanced`
reads texts as gnuplot's enhanced text: `10^{%L}` writes the powers of ten as superscripts. A text between `$` would be
[TeX math](math).

### Saving

<<< @/examples/snippets/qs_library-save.f90{fortran}

<<< @/examples/output/qs_library.txt{console}

<Plot name="qs_library" :width="760" :height="380" />

`save` picks the format from the file name:
- `.html`: the interactive page above (wheel to zoom, drag to pan, `a` to reset);
- `.svg`: a static image;
- `.pdf`: a PDF;
- `.tex`: a LaTeX picture;
- `.txt`: text;
- `-`: text on the standard output.

`info=meta` returns what a document needs: the file, its size in cm, an alternative text and the caption
([F1](/manual/paths/f-reports/01-a-figure-in-a-report)).

### Then

- [Path A](/manual/paths/a-first-steps/01-a-first-plot): a first plot, styles, axes, then the same plots from a script.
- [Scripts from Fortran](library#scripts-from-fortran): `script_object` runs gnuplot commands from your program.
- [Figures for a paper](/manual/paths/c-paper/01-a-first-pdf): PDF at its printed size, fonts, LaTeX labels.

## Run the tests

For contributors, from the repository root, where the tests find their reference files (`src/tests/goldens/`):

```bash
fobis build --mode tests-gnu-debug
bash scripts/run_tests.sh            # the Fortran tests, byte-exact golden files included
fobis rule --ex test-js              # the viewer's tick rules (needs Node.js)
```
