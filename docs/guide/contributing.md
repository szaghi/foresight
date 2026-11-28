---
title: Contributing
---

# Contributing

This is a FOSS project — anyone interested in using, developing, or contributing
is welcome. The project follows a KISS (Keep It Simple and Stupid) philosophy.

## Reporting Issues

- Open a ticket on the repository **GitHub Issues** page
- Clearly describe the problem, including steps to reproduce for bugs
- Note the earliest version you know has the issue

## Pull Requests

1. Fork the repository on GitHub
2. Create a topic branch from `master`:
   ```bash
   git checkout -b fix/master/my_contribution master
   ```
3. Test your changes with `fobis build --mode tests-gnu-debug && bash scripts/run_tests.sh`; after a change of
   the viewer (`src/js/viewer.js`), regenerate its Fortran copy (`fobis rule --ex embed-js`) and run its tests,
   `npm ci --prefix src/js && npm test --prefix src/js` (node only: tick rules, then key entries, linked zoom and
   follow mode in a parsed page)
4. A change of the output changes golden files (`src/tests/goldens`), compared byte for byte: run the golden test,
   look at the new `foresight_golden_NAME` files it writes (render them), and copy the ones you checked over
   `src/tests/goldens/NAME`; `FORESIGHT_UPDATE_GOLDEN=1` rewrites all of them at once (inspect before committing)
5. Check for unnecessary whitespace: `git diff --check`
6. Submit a pull request with a clear commit message

## Fortran Coding Style

- **Clarity over brevity**: `real :: gas_ideal_air` is better than `real :: gia`
- Single-character variable names only for loop counters
- Name all constants
- `implicit none` in every module and program
- Declare `intent` for all procedure arguments, ordered: pass arg → `inout` → `in` → `out` → optional
- Indent with two spaces (not tabs)
- No trailing whitespace; blank lines must contain no spaces
- Use `>, <, ==` instead of `.gt., .lt., .eq.`
- Avoid Windows-style CRLF line endings

### Recommended git whitespace settings

```ini
[color]
  ui = true
[color "diff"]
  whitespace = red reverse
[core]
  whitespace = fix,-indent-with-non-tab,trailing-space,cr-at-eol
```

## Documentation examples

Every snippet, output and plot of the learning paths and the cookbook comes from the sources in `docs/examples/src`: Fortran
programs and gnuplot scripts with marker comments (`!run ID COMMAND` or `#run ID COMMAND` for a run shown in the
pages, `!region NAME` ... `!endregion NAME` or `# region NAME` ... `# endregion NAME` for a part included on its own).

```bash
bash scripts/docs_examples.sh     # or: fobis rule --ex docs-examples
```

builds the library and the command line, runs every example, and regenerates `docs/examples/snippets`,
`docs/examples/output` and the plots in `docs/public/examples`, which the pages embed live with `<Plot name="..."/>`.
Each plot is written twice, `NAME.svg` (or `.html`) in the washi theme and `NAME-dark.svg` in the night one: the runs
happen twice, with `FORESIGHT_THEME=washi` and `night`, and `<Plot>` shows the one of the page mode. A recipe that sets
its own theme (`theme vfd`) keeps it in both.
The animations of the pages (`docs/public/examples/anim_*.svg`) are made by the same script from frames foresight
renders (`docs/examples/anim/*.gp`, run once per frame with `foresight -c SCRIPT FRAME`), assembled into one animated
SVG by `scripts/svg_frames.sh`.
Commit the regenerated files with the change: the CI runs the script and fails if any of them differs.

## Fidelity to gnuplot

foresight's identity is the gnuplot script: a layout change is judged against gnuplot 6.0 itself, on its own demos.
`scripts/fidelity/` holds the harness:

```bash
bash scripts/fidelity/fetch.sh                      # once: gnuplot 6.0.0's demos, checked by SHA-256
fobis build --mode foresight-gnu                    # the command line, bin/foresight
bash scripts/fidelity/run.sh bin/foresight mine     # gnuplot's and foresight's pages, scored
python3 scripts/fidelity/compare.py scripts/fidelity/baseline/scores.txt ~/.cache/foresight-fidelity/scores_mine.txt
bash scripts/fidelity/corpus.sh bin/foresight mine --check   # which demos foresight draws
```

- `fetch.sh` downloads the gnuplot 6.0.0 release tarball (or takes `--tarball FILE`), checks its SHA-256 and prepares
  the work directory, `~/.cache/foresight-fidelity` unless `FORESIGHT_FIDELITY` names another: the demos, the binary
  files the demo Makefile makes (gnuplot's `bf_test`) and a copy of each listed demo (`demos.txt`) writing one
  600x400 SVG page per `pause`.
- `run.sh FORESIGHT TAG` renders every page with the system's `gnuplot` (6.0; once, kept in `gp/`) and with the given
  binary (`fs_TAG/`, one private copy of the demos per job), then `score.py` rasterizes both pages with a headless
  Chrome (Playwright's, or `FORESIGHT_CHROME`) and scores each pair.
- A **score** is the mean absolute difference of the two pages as 120x80 grayscale images blurred by 2 px: 0 for the
  same page, 1 for opposite ones. It measures where the ink is (a moved axis, a missing key, another range), not the
  shapes of glyphs or the anti-aliasing. A page drawn by one program only scores 1 and is flagged `gp only` or
  `fs only`. A page around 0.02 matches gnuplot's closely; above 0.1 something is missing or misplaced.
- `compare.py BASE NEW` prints the totals over the pages both runs drew, the pages drawn or lost, and the pages worse
  by more than 0.005 (`--worse`); it exits 1 on a lost or a worse page. A layout change lists the reason of every
  worse page in its commit. `--tol 1e-4 --volatile scripts/fidelity/volatile.txt` checks a reproduction (the
  volatile pages print the day they are rendered).
- `corpus.sh FORESIGHT TAG` runs every demo of the directory as gnuplot would, its own terminal and outputs, and counts
  the demos foresight draws (exit 0 and at least one page); `--check` fails when a demo drawn in
  `baseline/corpus_*.txt` no longer is.
- `baseline/` holds the scores and the corpus tables of the last accepted state. A change that improves them commits
  the new files with the change.

### Text placement

A page score sees a text that moved by a few pixels only faintly. `placement.py` measures where each 2D text stands:

```bash
python3 scripts/fidelity/placement.py                   # every probe, svg and cairolatex
python3 scripts/fidelity/placement.py --probe p05_key_rows --term svg
```

- Each probe of `scripts/fidelity/placement/` is a gnuplot script run by both programs through `svg size 600,400`
  and `cairolatex pdf input size 5in,3in`, with the border at fixed fractions of the canvas (`set lmargin at
  screen ...`): the plot area is the same, so what differs is where the texts go.
- The texts are matched by content, and each pair's offset is printed, foresight's position less gnuplot's: in px for
  svg (the baseline anchor), in bp for cairolatex (the `\put` point), positive downward.
- gnuplot's cairo terminals measure their font through fontconfig. The probe aliases `Sans` to Liberation Sans, the
  font foresight lays texts out with, unless the probe says `#! fonts: system`. `#! font: N` sets the terminal font
  size, `#! margins: L R B T` the border.
- A text found in one output only is an error (exit 1). `baseline/placement.txt` holds the last accepted table.

## Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/) so that `CHANGELOG.md` is generated automatically from the git log:

| Prefix | Purpose | Changelog section |
|--------|---------|-------------------|
| `feat:` | New feature or capability | New features |
| `fix:` | Bug fix | Bug fixes |
| `perf:` | Performance improvement | Performance |
| `refactor:` | Code restructuring | Refactoring |
| `docs:` | Documentation only | Documentation |
| `test:` | Tests | Testing |
| `build:` | Build system | Build system |
| `ci:` | CI/CD pipeline | CI/CD |
| `chore:` | Maintenance | Miscellaneous |

Append `!` for breaking changes (`feat!:`, `fix!:`). Reference issues with `#123` — they are auto-linked.

```
feat: add R32P kind parameter
fix: correct byte_size for character arrays (#42)
feat!: rename check_endian to init_endian
```

---

## Creating a release

Releases are fully automated via `scripts/release.sh` and GitHub Actions. The only steps needed are:

```bash
# Install git-cliff once
npx git-cliff@latest

# Then, to release:
scripts/release.sh patch   # v1.2.3 → v1.2.4
scripts/release.sh minor   # v1.2.3 → v1.3.0
scripts/release.sh major   # v1.2.3 → v2.0.0
scripts/release.sh v2.1.0  # explicit version
```

`release.sh` will ask for confirmation, then:

1. Regenerate `CHANGELOG.md` from the git log via [git-cliff](https://git-cliff.org/)
2. Update `VERSION`
3. Commit with `chore(release): vX.Y.Z`
4. Create an annotated git tag
5. Push commit + tag

Pushing the tag triggers the GitHub Actions release workflow, which automatically:
- Runs the full test suite and uploads coverage
- Builds this documentation site and deploys it to GitHub Pages
- Packages a versioned tarball
- Publishes a GitHub release with the changelog section as release notes
