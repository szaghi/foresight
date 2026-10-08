---
title: 8. Watching the run
---

# 8. Watching the run

The case foresight was built for: the job runs for hours, appending to its log, and you want to watch it converge.

## In a browser

<<< @/examples/snippets/monitor.gp{gnuplot}

```bash
foresight --watch monitor.gp          # every second; --watch 10 for slow jobs
```

foresight runs the script, then polls the script and every data file it read; when one changes — the solver appended a
line — it runs again and rewrites `monitor.html`. The page reloads itself at the same period and **keeps your zoom**:
the view lives in the page URL as data values, not screen positions. Each rewrite is atomic, so a reload never sees half
a page. An error in one cycle (a typo saved in the script) is reported, and watching goes on.

On the job side there is nothing to link: write the columns, one line per iteration, and `flush`.

## Over ssh

The text terminal draws the plot with characters:

<<< @/examples/snippets/dumb-dumb.gp{gnuplot}

<<< @/examples/output/ch8-dumb.txt{text}

`foresight --watch dumb.gp` clears the screen and redraws in place at each change: no browser, no X forwarding, no port
to open.

## From the solver itself

The library can do the same without a script: re-save the figure every few iterations, and set the page to reload.

```fortran
call fig%set_refresh(5)               ! the page reloads every 5 s, keeping the zoom
do it = 1, max_it
   ! ... solve, append to the history arrays ...
   if (mod(it, 50) == 0) then
      call fig%clear                  ! drop the series, keep the settings
      call fig%plot(its(1:it), res(1:it), title='continuity')
      call fig%save('monitor.html')
   endif
enddo
```

::: tip What you learned
Live monitoring in a browser or a terminal, from a script or from the solver. Reference: [Live
Monitoring](/guide/monitoring), [Command Line](/guide/cli#watch-mode).
:::

That is the tour. The [Cookbook](../cookbook) has one recipe per task; the [Reference](/guide/features) the rest.
