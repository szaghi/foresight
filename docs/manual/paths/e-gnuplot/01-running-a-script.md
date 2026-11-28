---
title: E1. Running a script
---

# E1. Running a script

**Goal:** a gnuplot script you already have, run by foresight, and kept running in gnuplot too.

<<< @/examples/snippets/pe01_both-both.gp{gnuplot}

<<< @/examples/output/pe01.txt{console}

<Plot name="pe01" svg :width="600" :height="360" />

`gnuplot pe01_both.gp` runs the same file and writes `pe01.png` with gnuplot's `pngcairo`.

## Why it works

- `foresight SCRIPT` reads gnuplot 6.0's command language: the same `set`, `plot`, `splot`, `fit`, `stats`, the same
  expressions, functions (`besj0`, `besy0`, ...) and enhanced text (`J_0`), abbreviations included.
- `GPVAL_TERMINALS` lists the terminals of the program that runs the script; `html` is foresight's alone, so
  `strstrt(GPVAL_TERMINALS, 'html') > 0` tells the two apart.
- `-e` runs commands before the script (`foresight -e "set logscale y" run.gp`), `-c` passes arguments as `ARG1` ...
  `ARG9`, as `gnuplot -c`; without `set output` the output is the script's name with `.html`, or `-o FILE`.

## Try this

- `foresight -c pe01_both.gp` with an argument read as `ARG1` in the title: `set title ARG1`.
- `foresight --watch pe01_both.gp`: the script runs again whenever it or its data change ([B2](../b-monitoring/02-watching-the-run)).

## Pitfalls

- A terminal foresight does not have (`pngcairo`, `qt`, `wxt`, `x11`) stops the script at its line: choose the
  terminal as above, or leave it to the command line (`foresight -o plot.svg script.gp`).
- `pause -1` waits for a line on the standard input, as in gnuplot: a script meant for a batch job should not have it
  (`pause mouse` only writes its message: there is no window to click).

Reference: [Command Line](/guide/cli), [gnuplot subset](/guide/gnuplot-subset). Next:
[E2. Terminals and outputs](./02-terminals).
