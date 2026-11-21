---
title: Command Line
---

# Command Line

```
usage: foresight [options] [SCRIPT]
       foresight [options] -c SCRIPT [ARG1 ... ARG9]

Render a gnuplot-like SCRIPT to an interactive HTML page (default SCRIPT.html) or SVG.

options:
  -c, --call SCRIPT ARGS  run SCRIPT with ARGS as ARG1 ... ARG9 (ARGC their number), as gnuplot -c
  -e, --execute COMMANDS  run COMMANDS before SCRIPT (repeatable)
  -o, --output FILE       default output file (.html or .svg)
  -t, --theme NAME        default output theme: classic vfd lcd washi night
  -w, --watch [SECONDS]   re-run when SCRIPT or its data files change (default 1 s)
      --max-cycles N      stop watching after N polls
  -h, --help              show this help
```

## Output file

Plots go to `SCRIPT.html` (the script name without directory and extension), or `foresight.html` when only `-e`
commands are given. `-o` changes that default: any output `save` takes (`.svg`, `.html` or `.htm`, `.txt`, `-` the
standard output); inside the script, `set output` wins, and `set terminal` changes the extension of the default output
only (`set terminal dumb` or `block` sends it to the standard output). See [Output Formats](output-formats). After a
run that plotted, `foresight: FILE` on the standard output names the file written (not for the standard output, nor
for a script that only prints).

```bash
foresight residuals.gp                          # residuals.html
foresight -o report.svg residuals.gp            # report.svg
foresight -e "set terminal svg" residuals.gp    # residuals.svg
foresight -e "set logscale y" -e "plot 'log.dat' u 1:3"   # foresight.html, no script file
```

## Theme

`-t NAME` (`--theme NAME`) draws every plot of the run in the theme `NAME`, as `set terminal ... theme NAME` would,
unless the script sets a theme of its own: the same scripts in the light and dark colors of a site, for instance.
Without `-t`, the environment variable `FORESIGHT_THEME` gives the default (see
[Output Formats](output-formats#themes)).

```bash
foresight -t washi -o light.svg residuals.gp
foresight -t night -o dark.svg residuals.gp
```

## `-e`

`-e` commands run before the script, in the same interpreter: use them to override terminal, output or settings
without editing the script, or to plot without a script at all.

## `-c`

`-c SCRIPT ARG1 ...` runs the script with arguments, as `gnuplot -c`: inside it `ARG1` ... `ARG9` hold them as strings
(empty beyond the last), `ARGC` their number and `ARG0` the script name; the rest of the command line is the arguments,
at most 9. Without `-c`, `ARGC` is 0. A script calls another one with arguments by `call` (see
[Datablocks and scripts](gnuplot-subset#datablocks-and-scripts)).

```bash
foresight -c panel.gp cd 3          # ARG1 = "cd", ARG2 = "3"
```

## Watch mode

`--watch [SECONDS]` runs the script, then polls every `SECONDS` (default 1, digits and a dot: `-w 0.5`) the script,
the scripts it loaded and every data file it read (size and content); when one changes, it runs again from a fresh
interpreter, printing `foresight: watching, Ctrl-C to stop` first. HTML output reloads itself in the browser every
`SECONDS` rounded to whole seconds (at least 1), keeping the zoom, unless the script sets its own
`set terminal html refresh S`; text output on the standard output clears the screen and redraws. `--max-cycles N`
stops after N polls (tests, demos), with status 0 whatever the last cycle gave. See [Live Monitoring](monitoring).

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
