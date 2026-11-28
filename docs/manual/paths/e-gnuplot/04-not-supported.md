---
title: E4. What foresight does not do
---

# E4. What foresight does not do

**Goal:** know where a script stops, and why it does not go on.

<<< @/examples/snippets/pe04_unsupported-unsupported.gp{gnuplot}

<<< @/examples/output/pe04.txt{console}

The message names the file, the line (of the whole file) and the command; nothing is drawn after it.

## Why it works

- foresight interprets a subset of gnuplot and refuses the rest: a script that runs is a script that did what it says,
  not one that skipped a line. The [list of what is not supported](/guide/gnuplot-subset#not-supported) is short and
  kept current.
- The commands that act on gnuplot's interactive windows only (`bind`, `set mouse`, `vclear`, `test`, `set term push`)
  are accepted and do nothing, as with gnuplot's file terminals: a script for the `qt` window runs as it is.
- Messages that name a limit say what is supported instead: `set palette: unsupported option "model XYZ" (RGB, HSV and
  CMY are supported, as gnuplot 6.0)`.

## Try this

- Comment the line out and run again; or put it in the gnuplot branch of [E3](./03-extensions).
- `foresight -e 'set loadpath "macros"' pe04_unsupported.gp`: the same error, from the command line.

## Pitfalls

- The first refused line stops the script: fix it and the next one may stop it too. Run the script once with each fix,
  or read the [list](/guide/gnuplot-subset#not-supported) first.
- `--watch` keeps watching after an error: fix the script, save it, and the next cycle runs it.

Reference: [gnuplot subset](/guide/gnuplot-subset#not-supported). Next: [E5. Checking against gnuplot](./05-checking).
