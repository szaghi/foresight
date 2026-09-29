---
layout: home

hero:
  name: foresight
  text: gnuplot-like plots from Fortran
  tagline: FORtran Easy Svg Interactive Gnuplot-like Html Tool — interactive HTML, SVG and text plots from a Fortran library or a gnuplot-style command line, with no dependency beyond a Fortran compiler.
  actions:
    - theme: brand
      text: Quick Start
      link: /guide/quickstart
    - theme: alt
      text: Examples
      link: /guide/examples
    - theme: alt
      text: View on GitHub
      link: https://github.com/szaghi/foresight

features:
  - icon: 🖱️
    title: Interactive HTML
    details: A single self-contained page per plot. Zoom, pan and gnuplot hotkeys (u, a, g) in any browser, ticks regenerated with the same rules as the Fortran side.
  - icon: 📈
    title: gnuplot Semantics
    details: Autoscale extended to the tick grid, reversed ranges, log axes, blocks and datasets in data files, the gnuplot palette and dash types — what gnuplot users expect.
  - icon: 🛰️
    title: Live Monitoring
    details: foresight --watch re-renders when a running job appends to its logs; the page reloads itself and keeps your zoom. Over plain ssh, the dumb terminal redraws in place.
  - icon: 🧩
    title: Library and CLI
    details: Call figure%plot from your solver, or run gnuplot-subset scripts from the shell. The CLI is a thin shell over the same library interpreter.
  - icon: 🎯
    title: Exact and Reproducible
    details: Tick labels built from integers (0.3, never 0.30000000000000004), compiler-independent number formatting, byte-exact golden tests of every output format.
  - icon: 🪶
    title: Pure Fortran
    details: Fortran 2018 plus two libc calls (rename, nanosleep). No Python, no gnuplot, no graphics library; the browser is the only viewer you need.
---

## Quick start

From Fortran:

```fortran
use foresight, only : figure_object, I4P, R8P
type(figure_object)    :: fig
real(R8P), allocatable :: t(:)
integer(I4P)           :: i

t = [(0.1_R8P * i, i = 0, 100)]
call fig%set_title('Damped oscillation')
call fig%plot(t, exp(-0.3_R8P * t) * cos(2.0_R8P * t), title='u(t)')
call fig%save('quickstart.html')   ! interactive page
```

From the shell, with a gnuplot script:

```bash
foresight residuals.gp            # writes residuals.html
foresight --watch residuals.gp    # re-renders while the job appends to residuals.dat
```

![A two-panel monitor: log residual and drag coefficient with error bars](/examples/multiplot.svg)

The same figure as an [interactive page](/foresight/examples/multiplot.html){target="_self"}: wheel to zoom, drag to pan, `u`
to undo, `a` to autoscale, `h` for help.
