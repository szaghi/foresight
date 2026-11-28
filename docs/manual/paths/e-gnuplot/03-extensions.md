---
title: E3. What foresight adds
---

# E3. What foresight adds

**Goal:** foresight's extensions in a script that still runs in gnuplot.

<<< @/examples/snippets/pe03_extensions-extensions.gp{gnuplot}

<Plot name="pe03" svg :width="600" :height="320" />

## Why it works

- foresight's own words are few and named: `theme` on the terminals (`classic`, `washi`, `night`, `vfd`, `lcd`,
  `paper`), the styles `readout` and `gauge`, `set readout`, `set caption`, `set table ... markdown`, the `html`
  terminal and its viewer. gnuplot stops on each of them, so they go in the branch only foresight reads.
- `if (...) { ... } else { ... }` is gnuplot's block `if`: both programs parse the whole block and run one branch.
- Everything else in the script is gnuplot's: a script that keeps its extensions in such branches runs in both.

## Try this

- `theme washi` and `theme night`: the light and dark colors of these pages.
- `with gauge` instead of `with readout`: a dial.
- `set table 'p.md' markdown` and `plot $P with table`: the data as a Markdown table ([F2](../f-reports/02-tables)).

## Pitfalls

- Inline data (`'-'`) cannot be read inside a `{ }` block: use a datablock (`$P << EOD`) as above.
- `GPVAL_VERSION` is 6.0 in both programs: test the terminals, not the version.

Reference: [themes](/guide/gnuplot/styles#themes-and-segmented-fills), [readouts](/guide/gnuplot/styles#readouts).
Next: [E4. What foresight does not do](./04-not-supported).
