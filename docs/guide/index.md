---
title: About foresight
---

<script setup>
import { withBase } from 'vitepress'
</script>

<div class="fs-about-hero">
  <div class="fs-about-name">foresight</div>
  <p class="fs-about-tagline">Plots from pure Fortran, in gnuplot's language: watch a run live, keep your gnuplot
  scripts, put the figures in your paper. Nothing to install but a Fortran compiler.</p>
</div>

# About foresight

**foresight** (FORtran Easy Svg Interactive Gnuplot-like Html Tool) is a Fortran library and a command line tool. It
is made for three jobs:

<div class="fs-uses">
  <div class="fs-use">
    <img class="fs-only-light" :src="withBase('/icons/gnuplot.svg')" alt="" /><img class="fs-only-dark" :src="withBase('/icons/gnuplot-dark.svg')" alt="" />
    <h3>1 · gnuplot, from Fortran</h3>
    <p>gnuplot 6.0's command language, interpreted in Fortran: run your scripts with <code>foresight script.gp</code>,
    or call the same commands from your program (<code>fig%plot</code>, <code>fig%set_logscale</code>). Each feature
    is checked against gnuplot itself.</p>
    <a href="../manual/paths/e-gnuplot/01-running-a-script">Path E: from gnuplot →</a>
  </div>
  <div class="fs-use">
    <img class="fs-only-light" :src="withBase('/icons/live.svg')" alt="" /><img class="fs-only-dark" :src="withBase('/icons/live-dark.svg')" alt="" />
    <h3>2 · Watch a running job</h3>
    <p><code>foresight --watch</code> redraws while the solver writes its log. In the browser the page reloads and
    keeps your zoom, or follows the newest data; over ssh the terminal plot redraws in place.</p>
    <a href="../manual/paths/b-monitoring/01-a-dashboard">Path B: watching a simulation →</a>
  </div>
  <div class="fs-use">
    <img class="fs-only-light" :src="withBase('/icons/paper.svg')" alt="" /><img class="fs-only-dark" :src="withBase('/icons/paper-dark.svg')" alt="" />
    <h3>3 · Figures for papers</h3>
    <p>PDF at the size it is printed, its fonts embedded; TeX math in labels, set as LaTeX sets it; LaTeX pictures
    whose labels your paper sets; reports with alternative texts, captions and Markdown tables.</p>
    <a href="../manual/paths/c-paper/01-a-first-pdf">Path C: figures for a paper →</a>
  </div>
</div>

One engine serves the three: the same figure comes from a program or a script, and goes to the browser, the terminal
or the paper.

<div class="fs-infographic">
<svg viewBox="0 0 760 330" role="img" aria-label="Fortran arrays, gnuplot scripts and solver logs go into foresight's one engine, which writes interactive pages and terminal plots for monitoring, SVG for gnuplot users, and PDF, LaTeX pictures and Markdown reports for papers" xmlns="http://www.w3.org/2000/svg" font-family="Inter, system-ui, sans-serif">
  <defs>
    <marker id="fs-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0 0L10 5L0 10z" style="fill: var(--vp-c-text-3)" />
    </marker>
  </defs>
  <g font-size="13">
    <text x="95" y="22" text-anchor="middle" font-weight="700" style="fill: var(--vp-c-text-2)">IN</text>
    <rect x="10" y="40" width="170" height="64" rx="10" style="fill: var(--vp-c-bg-soft); stroke: var(--vp-c-divider)" />
    <text x="95" y="66" text-anchor="middle" font-weight="600" style="fill: var(--vp-c-text-1)">Fortran arrays</text>
    <text x="95" y="86" text-anchor="middle" font-size="11.5" style="fill: var(--vp-c-text-2)">call fig%plot(x, y)</text>
    <rect x="10" y="132" width="170" height="64" rx="10" style="fill: var(--vp-c-bg-soft); stroke: var(--vp-c-divider)" />
    <text x="95" y="158" text-anchor="middle" font-weight="600" style="fill: var(--vp-c-text-1)">gnuplot script</text>
    <text x="95" y="178" text-anchor="middle" font-size="11.5" style="fill: var(--vp-c-text-2)">foresight run.gp</text>
    <rect x="10" y="224" width="170" height="64" rx="10" style="fill: var(--vp-c-bg-soft); stroke: var(--vp-c-divider)" />
    <text x="95" y="250" text-anchor="middle" font-weight="600" style="fill: var(--vp-c-text-1)">solver log, growing</text>
    <text x="95" y="270" text-anchor="middle" font-size="11.5" style="fill: var(--vp-c-text-2)">run.dat, run.csv</text>

    <rect x="262" y="96" width="200" height="136" rx="14" style="fill: var(--vp-c-brand-soft); stroke: var(--vp-c-brand-1); stroke-width: 1.5" />
    <text x="362" y="132" text-anchor="middle" font-size="17" font-weight="700" style="fill: var(--vp-c-brand-1)">foresight</text>
    <text x="362" y="156" text-anchor="middle" font-size="11.5" style="fill: var(--vp-c-text-1)">one engine, pure Fortran</text>
    <text x="362" y="176" text-anchor="middle" font-size="11.5" style="fill: var(--vp-c-text-1)">gnuplot 6.0's language</text>
    <text x="362" y="196" text-anchor="middle" font-size="11.5" style="fill: var(--vp-c-text-1)">exact font metrics</text>
    <text x="362" y="216" text-anchor="middle" font-size="11.5" style="fill: var(--vp-c-text-1)">TeX math layout</text>

    <path d="M180 72 C220 72 225 130 260 140" fill="none" style="stroke: var(--vp-c-text-3)" stroke-width="1.5" marker-end="url(#fs-arrow)" />
    <path d="M180 164 L260 164" fill="none" style="stroke: var(--vp-c-text-3)" stroke-width="1.5" marker-end="url(#fs-arrow)" />
    <path d="M180 256 C220 256 225 198 260 188" fill="none" style="stroke: var(--vp-c-text-3)" stroke-width="1.5" marker-end="url(#fs-arrow)" />

    <text x="640" y="22" text-anchor="middle" font-weight="700" style="fill: var(--vp-c-text-2)">OUT</text>
    <rect x="530" y="34" width="220" height="62" rx="10" style="fill: var(--vp-c-bg-soft); stroke: var(--vp-c-indigo-1); stroke-width: 1.5" />
    <text x="545" y="56" font-weight="700" style="fill: var(--vp-c-indigo-1)">1 · gnuplot, from Fortran</text>
    <text x="545" y="78" font-size="11.5" style="fill: var(--vp-c-text-1)">SVG; the same script in gnuplot</text>
    <rect x="530" y="108" width="220" height="82" rx="10" style="fill: var(--vp-c-bg-soft); stroke: var(--vp-c-green-1); stroke-width: 1.5" />
    <text x="545" y="130" font-weight="700" style="fill: var(--vp-c-green-1)">2 · watch a run</text>
    <text x="545" y="152" font-size="11.5" style="fill: var(--vp-c-text-1)">HTML page: zoom, live reload</text>
    <text x="545" y="172" font-size="11.5" style="fill: var(--vp-c-text-1)">terminal plot over ssh</text>
    <rect x="530" y="202" width="220" height="102" rx="10" style="fill: var(--vp-c-bg-soft); stroke: var(--vp-c-yellow-1); stroke-width: 1.5" />
    <text x="545" y="224" font-weight="700" style="fill: var(--vp-c-yellow-1)">3 · papers and reports</text>
    <text x="545" y="246" font-size="11.5" style="fill: var(--vp-c-text-1)">PDF, fonts embedded</text>
    <text x="545" y="266" font-size="11.5" style="fill: var(--vp-c-text-1)">LaTeX picture (cairolatex)</text>
    <text x="545" y="286" font-size="11.5" style="fill: var(--vp-c-text-1)">Markdown report, tables</text>

    <path d="M462 140 C500 130 500 70 528 66" fill="none" style="stroke: var(--vp-c-text-3)" stroke-width="1.5" marker-end="url(#fs-arrow)" />
    <path d="M462 164 L528 150" fill="none" style="stroke: var(--vp-c-text-3)" stroke-width="1.5" marker-end="url(#fs-arrow)" />
    <path d="M462 188 C500 198 500 248 528 252" fill="none" style="stroke: var(--vp-c-text-3)" stroke-width="1.5" marker-end="url(#fs-arrow)" />
  </g>
</svg>
</div>

It draws gnuplot's plot styles (curves, bars, box plots, heatmaps, vector fields, polar and spider plots, `splot`'s 3D
views) and dashboard charts (readouts, gauges, pies). Its outputs are self-contained interactive HTML pages, SVG, PDF
with embedded fonts, LaTeX pictures (gnuplot's `cairolatex`) and text.

## Why

Python, gnuplot or MATLAB usually do this work, and each brings its own runtime into a workflow that is otherwise pure
Fortran: a Python environment to maintain on every cluster, a gnuplot build with the right terminals, glue scripts in a
second language. foresight takes the opposite path:

- **the plotting core is Fortran:** data never leaves the language, the solver can plot directly, and the build is one
  more FoBiS mode or fpm dependency;
- **the browser is the viewer:** every workstation already has one, and an HTML page with an embedded script gives
  zoom and pan without any GUI toolkit;
- **the command language is gnuplot's:** a subset, interpreted by the library, so existing habits and many existing
  scripts carry over;
- **the fonts are inside:** two families and a math font are compiled in, so every device measures text the same way
  and a PDF needs nothing from the machine ([Fonts](fonts), [TeX math](math), [LaTeX labels](latex)).

## What it is not

foresight is deliberately scoped:
- **Not a typesetter.** Display math, matrices and line breaking in labels are LaTeX's job (through `cairolatex`); a
  report's layout belongs to its Markdown renderer.
- **No PNG, no EPS.** It writes no raster images and no EPS, and has no journal presets and no CMYK.
- **Not 3D field visualisation.** For volume rendering or large meshes, use ParaView through
  [VTKFortran](https://github.com/szaghi/VTKFortran). foresight's 3D views are gnuplot's `splot`, drawn as gnuplot
  draws them; an HTML page can turn them with the mouse, as a sketch.
- **No silent skipping.** A command outside the supported gnuplot subset is reported as an error naming the command.

## Where to start

1. [Install](install) the library and the command line.
2. Browse the [gallery](gallery) for what it draws.
3. Follow a [learning path](/manual/): path A from a first plot to scripts, then the one of your job.
4. Look up a task in the [cookbook](/manual/cookbook), a command or method in the [reference](features).

Releases and their changes are in the [changelog](changelog).

## Authors

- Stefano Zaghi: [@szaghi](https://github.com/szaghi)

Contributions are welcome: see the [Contributing](contributing) page.

## License

foresight is available under your choice of license.

| License | SPDX | File |
|---|---|---|
| GNU General Public License v3 | `GPL-3.0-or-later` | [LICENSE.gpl3.md](https://github.com/szaghi/foresight/blob/master/LICENSE.gpl3.md) |
| BSD 2-Clause | `BSD-2-Clause` | [LICENSE.bsd-2.md](https://github.com/szaghi/foresight/blob/master/LICENSE.bsd-2.md) |
| BSD 3-Clause | `BSD-3-Clause` | [LICENSE.bsd-3.md](https://github.com/szaghi/foresight/blob/master/LICENSE.bsd-3.md) |
| MIT | `MIT` | [LICENSE.mit.md](https://github.com/szaghi/foresight/blob/master/LICENSE.mit.md) |

The third-party color tables of the named palettes and the compiled-in fonts keep their own licenses: see
[License](license).

© [Stefano Zaghi](https://github.com/szaghi)
