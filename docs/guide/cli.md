---
title: Command Line
---

# Command Line

```
usage: foresight [options] [SCRIPT]

Render a gnuplot-like SCRIPT to an interactive HTML page (default SCRIPT.html) or SVG.

options:
  -e, --execute COMMANDS  run COMMANDS before SCRIPT (repeatable)
  -o, --output FILE       default output file (.html or .svg)
  -w, --watch [SECONDS]   re-run when SCRIPT or its data files change (default 1 s)
      --max-cycles N      stop watching after N polls
  -h, --help              show this help
```

## Output file

Plots go to `SCRIPT.html` (the script name without directory and extension), or `foresight.html` when only `-e`
commands are given. `-o` changes that default; inside the script, `set output` wins, and `set terminal` changes the
extension of the default output only (`set terminal dumb` sends it to the standard output). See
[Output Formats](output-formats).

```bash
foresight residuals.gp                          # residuals.html
foresight -o report.svg residuals.gp            # report.svg
foresight -e "set terminal svg" residuals.gp    # residuals.svg
foresight -e "set logscale y" -e "plot 'log.dat' u 1:3"   # foresight.html, no script file
```

## `-e`

`-e` commands run before the script, in the same interpreter: use them to override terminal, output or settings
without editing the script, or to plot without a script at all.

## Watch mode

`--watch [SECONDS]` runs the script, then polls every `SECONDS` (default 1) the script and every data file it read
(size and content); when one changes, it runs again from a fresh interpreter. HTML output reloads itself in the browser at
the poll period, keeping the zoom; text output on the standard output clears the screen and redraws. See
[Live Monitoring](monitoring).

## Exit status

| Status | Meaning |
|---|---|
| 0 | success |
| 1 | error in the commands or the script, reported as `file:line: message` |
| 2 | command line error |

Errors print one line on the standard error, never a backtrace:

```
foresight: -e:1: unsupported command "splot"
```
