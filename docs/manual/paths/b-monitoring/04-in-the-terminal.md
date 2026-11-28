---
title: B4. In the terminal
---

# B4. In the terminal

**Goal:** the run's convergence in the terminal you are logged in with, over ssh, with nothing else installed.

<<< @/examples/snippets/pb04_terminal-terminal.gp{gnuplot}

<<< @/examples/output/pb04.txt{text}

## Why it works

- `set terminal block braille` draws with Unicode Braille characters, 2 x 4 dots each: four times the resolution of
  `dumb`'s characters, in any terminal with a Unicode font.
- The text — tick labels, the key — is written over the graphics in the character cells.
- `foresight --watch pb04_terminal.gp` clears the screen and redraws in place at each change of the log: a live plot
  over plain ssh, no X forwarding, no port to open.

## Try this

- `set terminal block braille ansirgb`: the series in colors.
- `set terminal dumb size 72,22`: plain ASCII, for a log file or an e-mail.
- `set terminal block quadrants`: 2 x 2 blocks, coarser and heavier.

## Pitfalls

- The default tick labels of a log axis are gnuplot's `% h`, long in a text terminal (`10.000000`, as gnuplot 6.0
  writes them): `set format y '%.0e'` as above.
- A terminal narrower than the plot wraps its lines: give `size` the terminal's columns and rows.

Reference: [text terminals](/guide/output-formats), [cookbook](../../cookbook#text-terminals). Next:
[B5. Numbers on the plot](./05-numbers-on-the-plot).
