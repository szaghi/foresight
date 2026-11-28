---
title: E5. Checking against gnuplot
---

# E5. Checking against gnuplot

**Goal:** compare the pages foresight draws with gnuplot's, page by page, with a number for how close they are.

```console
$ bash scripts/fidelity/fetch.sh                        # gnuplot 6.0's demos, once
$ bash scripts/fidelity/run.sh bin/foresight mine -j 6  # every page by gnuplot and by foresight, then scored
$ python3 scripts/fidelity/compare.py scripts/fidelity/baseline/scores.txt \
          ~/.cache/foresight-fidelity/scores_mine.txt  # page by page against the committed baseline
```

foresight's repository carries this harness (`scripts/fidelity/`): it runs gnuplot 6.0's own demo scripts through
both programs, rasterizes each page and scores the difference. The project uses it as a gate: a change may not make a
page worse than before by more than 0.005 without a listed reason.

## Why it works

- The demos are gnuplot's test of itself: hundreds of pages exercising its commands. A page drawn by both is compared
  where it matters, the pixels, not the file.
- The score is low but not zero by design: foresight measures texts with real font metrics where gnuplot's layout
  estimates them, and some margins differ by a few points
  ([layout compared with gnuplot](/guide/comparison#layout-compared-with-gnuplot)).
- `scripts/fidelity/pdfcairo.py` and `cairolatex.py` compare the PDF and LaTeX terminals the same way.

## Try this

- Your own script: run it with `gnuplot` and with `foresight` to SVG and open both in a browser,
  side by side.

## Pitfalls

- gnuplot's demos call terminals and commands foresight refuses: those pages count as not drawn, not as different.
- The harness needs gnuplot 6.0 and a headless Chrome (to rasterize the pages); it is a developer's tool, not part
  of the build.

Reference: [Contributing](/guide/contributing#fidelity-to-gnuplot). This is the end of path E: the
[gnuplot subset](/guide/gnuplot-subset) is the reference by topic.
