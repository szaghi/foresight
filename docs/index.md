---
layout: home

hero:
  name: foresight
  text: gnuplot-like plots from pure Fortran
  tagline: Plot from your solver or from a gnuplot script, and open the result in any browser — zoom, pan, live reload while the job runs. No Python, no gnuplot, nothing but a Fortran compiler.
  actions:
    - theme: brand
      text: Tutorial
      link: /manual/tutorial/01-first-plot
    - theme: alt
      text: Cookbook
      link: /manual/cookbook
    - theme: alt
      text: Reference
      link: /guide/features
    - theme: alt
      text: API
      link: /api/
    - theme: alt
      text: View on GitHub
      link: https://github.com/szaghi/foresight

features:
  - icon: 🖱️
    title: Interactive pages
    details: One self-contained HTML page per plot. Wheel zoom, drag to pan, box zoom, gnuplot hotkeys; ticks regenerated on zoom by the same rules as the Fortran side.
    link: /guide/viewer
    linkText: The viewer
  - icon: 🛰️
    title: Live monitoring
    details: foresight --watch re-renders while a running job appends to its logs; the page reloads itself and keeps your zoom. Over ssh, the text terminal redraws in place.
    link: /manual/tutorial/08-live
    linkText: Watch a run
  - icon: 📜
    title: The gnuplot language
    details: using expressions, index and every, CSV with column headers, two y axes, functions, styles, point types, multiplot, error bars — the subset monitoring scripts use.
    link: /guide/gnuplot-subset
    linkText: The subset
  - icon: 🧩
    title: Library and command line
    details: Call fig%plot from your solver, or run scripts from the shell. The command line is a thin shell over the interpreter the library exposes.
    link: /guide/library
    linkText: Fortran library
  - icon: 🎯
    title: Exact and reproducible
    details: Tick labels built from integers (0.3, never 0.30000000000000004), compiler-independent number formatting, byte-exact golden tests of every output format.
    link: /guide/architecture
    linkText: How it works
  - icon: 🪶
    title: Pure Fortran
    details: Fortran 2018 and two libc calls. Interactive HTML, static SVG and text, from one FoBiS build; the browser is the only viewer you need.
    link: /guide/install
    linkText: Install
---

<div class="fs-home">

## One run, one page

<p class="fs-lead">This is a foresight page, live: zoom with the wheel, drag to pan, press <kbd>a</kbd> to come back. The
<a href="./manual/tutorial/07-dashboard">dashboard</a> of the tutorial run, written by a ten-line gnuplot script.</p>

<Plot name="ch7" :width="900" :height="440" />

## Quick start

<p class="fs-lead">From the arrays of your program, or from the log it writes: the same plot, the same page.</p>

::: code-group

<<< @/examples/snippets/ch1_first_plot-all.f90{fortran} [Fortran library]

<<< @/examples/snippets/residuals.gp{gnuplot} [gnuplot script]

:::

```bash
fobis build --mode foresight-static-gnu       # the library, lib/libforesight.a
fobis build --mode foresight-gnu              # the command line, bin/foresight
foresight --watch residuals.gp                # re-render while the solver writes run.dat
```

## Gallery

<p class="fs-lead">Every image here is an actual foresight output, regenerated from the
<a href="./manual/cookbook">cookbook</a> recipes and checked by the CI.</p>

<div class="fs-gallery">
  <Plot name="cb_y2" svg :width="560" :height="320" caption="two y axes" />
  <Plot name="cb_xyerrorbars" svg :width="560" :height="320" caption="error bars on a log axis" />
  <Plot name="cb_model" svg :width="560" :height="320" caption="data and a model function" />
  <Plot name="cb_styles" svg :width="560" :height="320" caption="line styles and point types" />
  <Plot name="cb_key" svg :width="560" :height="320" caption="the key below the plot" />
  <Plot name="cb_function" svg :width="560" :height="320" caption="functions of x" />
</div>

## Authors

- Stefano Zaghi — [@szaghi](https://github.com/szaghi)

## Copyrights

foresight is distributed under the [GNU General Public License v3](http://www.gnu.org/licenses/gpl-3.0.html).

</div>
