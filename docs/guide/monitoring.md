---
title: Live Monitoring
---

# Live Monitoring

The case foresight was built for: a job runs for hours, appends its residuals and forces to text files, and you want
to watch them — in a browser on your workstation, or in a terminal over ssh.

## The job side

Nothing to link: write the monitored quantities as columns, one line per step, and flush.

```fortran
write(log_unit, '(I0,2(1X,ES14.6E3))') it, res_rho, res_mom
flush(log_unit)
```

See [Data Files](data-files) for the format and for what happens when a line is read half-written.

## In a browser

```bash
foresight --watch residuals.gp
```

The script is run once, then the script and its data files are polled every second; on any change the
script runs again and rewrites `residuals.html`. The page reloads itself at the same period and **keeps your zoom**,
because the view is stored in its URL as data values, not as screen positions. Rewrites are atomic (a temporary file
renamed over the page), so a reload never catches half a page.

A longer period for slow jobs: `foresight --watch 10 residuals.gp`.

To watch the latest iterations only, zoom to a window of the width you want and press `f`: at each reload the window
slides to the end of the data and the y range fits what it shows ([Following a live run](viewer#following-a-live-run)).
A click on a key entry hides a series that crowds the others; both settings survive the reloads, in the page URL.

## Over ssh

```bash
foresight --watch -e "set terminal dumb" residuals.gp
foresight --watch -e "set terminal block braille ansi" residuals.gp
```

The plot is drawn in text on the standard output; each re-render clears the screen and redraws in place. No browser,
no X forwarding, no port to open. `block braille` draws with Braille dots, 2 x 4 per character, and `ansi` colors the
series ([Output Formats](output-formats#block-characters)): the curves of a terminal plot then read almost as a
picture.

## A cockpit for a run

`with readout` shows the newest value of a column in seven-segment digits, as a 1980s car dashboard: the iteration,
the residual, a coefficient, beside or over the curves. A readout follows its file at every cycle, like any plot item.

```gnuplot
set readout horizontal
plot 'run.dat' u 1 w readout format '%6.0f' t 'ITER', '' u 2 w readout format '%9.2e' t 'RESIDUAL'
```

The glass is fixed by the format, so the digits never jump between two reloads; a log not written yet shows dashes.
In the terminal the digits are drawn with characters, so the cockpit works over ssh too. See
[Readouts](gnuplot-subset#readouts) and the [cookbook](/manual/cookbook#seven-segment-readouts).

## Robustness

- An error in one cycle — a data file briefly missing, a script saved with a typo — is reported and watching goes on.
- Change detection compares each file's size and a hash of its content — all of it up to 1 MiB, the first and last
  64 KiB beyond. Appends, a restarted job rewriting its log, an edit of the script that keeps its length
  (`lw 2` → `lw 3`) are all caught; only a same-size change in the middle of a file larger than 1 MiB is missed, which
  an append-only log never does. File modification times are not used: standard Fortran cannot read them, and their
  resolution is seconds on some filesystems (network shares, WSL).
- `--max-cycles N` stops after `N` polls, for scripted use.
