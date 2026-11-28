---
title: B3. Readouts
---

# B3. Readouts

**Goal:** the few numbers a long run is watched for, large enough to read across the room, over its history.

<<< @/examples/snippets/pb03_readouts-readouts.gp{gnuplot}

<Plot name="pb03" svg :width="700" :height="400" />

## Why it works

- `with readout` shows the last value of a column as a seven-segment display; the format fixes its digits, the
  unlit segments the glass (`%9.2e`: nine digits, all shown, those not used dim).
- `set readout horizontal` lines the readouts up in their panel; `vertical` stacks them.
- `theme vfd` draws in the colors of a 1980s car dashboard, a light trace on black, legible on a monitor left on the
  side of a desk; `lcd` is the gray of a calculator.
- Under `--watch`, the readouts change with the log: the newest iteration, the newest residual.

## Try this

- `with gauge range [0:0.6] segments 24` for the drag coefficient: a dial with its bands.
- `theme lcd` and `set terminal dumb`: the same readouts in a terminal, drawn with characters.
- From Fortran: `call fig%plot(x, y, with='readout', format='%6.4f', title='CD')`.

## Pitfalls

- A readout's format needs a field width (`%6.4f`, not `%.4f`): it is the number of digits of the glass.
- A readout shows one number: the last row of the column. Read the history from the plot under it.

Reference: [readouts](/guide/gnuplot/styles#readouts), [themes](/guide/gnuplot/styles#themes-and-segmented-fills).
Next: [B4. In the terminal](./04-in-the-terminal).
