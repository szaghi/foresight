---
title: Installation
---

# Installation

## Requirements

- A Fortran 2018 compiler. Tested with gfortran 16; the Intel `ifx` build modes exist but are not yet verified.
- A POSIX system (Linux, macOS): `rename` and `nanosleep` are called through `bind(C)`.
- [FoBiS](https://github.com/szaghi/FoBiS) 3.8+ to build.
- Optionally [Node.js](https://nodejs.org), only to run the viewer tests and to build this documentation.

## Build

```bash
git clone https://github.com/szaghi/foresight
cd foresight
fobis fetch                                  # PENF, BeFoR64, FACE, StringiFor into src/third_party
fobis build --mode foresight-gnu             # command line tool: bin/foresight
fobis build --mode foresight-static-gnu      # library: lib/libforesight.a, modules in lib/mod
```

`fobis build --lmodes` lists all modes:

| Mode | Builds |
|---|---|
| `foresight-gnu`, `foresight-intel` | the `foresight` command line tool in `bin/` |
| `foresight-static-gnu`, `foresight-static-intel` | the static library `libforesight.a` in `lib/` |
| `tests-gnu`, `tests-intel` | the test programs in `exe/` |
| `tests-gnu-debug`, `tests-intel-debug` | the tests with runtime checks and floating point traps |

## Test

```bash
fobis build --mode tests-gnu-debug
bash scripts/run_tests.sh            # Fortran tests, byte-exact golden files included
fobis rule --ex test-js              # viewer tick rules (needs node)
```

Tests run from the repository root, where they find the reference files in `src/tests/golden/`.

## Use the library

Compile against the modules and link the static library:

```bash
gfortran -I foresight/lib/mod my_program.f90 foresight/lib/libforesight.a -o my_program
```

and `use foresight` in the program: it re-exports the whole public API (`figure_object`, `script_object`) and the
PENF kinds `I4P`, `I8P`, `R4P`, `R8P`.
