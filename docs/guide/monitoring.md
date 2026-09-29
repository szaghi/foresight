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

The script is run once, then the sizes of the script and of its data files are polled every second; on any change the
script runs again and rewrites `residuals.html`. The page reloads itself at the same period and **keeps your zoom**,
because the view is stored in its URL as data values, not as screen positions. Rewrites are atomic (a temporary file
renamed over the page), so a reload never catches half a page.

A longer period for slow jobs: `foresight --watch 10 residuals.gp`.

## Over ssh

```bash
foresight --watch -e "set terminal dumb" residuals.gp
```

The plot is drawn in text on the standard output; each re-render clears the screen and redraws in place. No browser,
no X forwarding, no port to open.

## Robustness

- An error in one cycle — a data file briefly missing, a script saved with a typo — is reported and watching goes on.
- Change detection compares file sizes: right for append-only logs, blind to a rewrite that keeps the size exactly.
- `--max-cycles N` stops after `N` polls, for scripted use.
