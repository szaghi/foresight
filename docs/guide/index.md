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
<svg viewBox="0 0 900 360" role="img" aria-label="Fortran arrays, gnuplot scripts and growing logs flow into foresight's one engine, which writes gnuplot's plots from Fortran, live pages and terminal plots of a running job, and PDF, LaTeX and Markdown for papers and reports" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <symbol id="fsi-icon" viewBox="0.29 1.54 58.70 58.70">
      <path style="fill: var(--vp-c-text-1)" d="M39 47.2L40.9 48.5 43.5 50 44.3 48.8 43.4 48 42.5 46.8 41 44 39.6 41.9 39.1 41.1 36.7 36.1 36.2 35 35.2 32.2 34 29 33.7 27.8 33.1 24.9 32.5 23 31.6 21.9 30.5 21.6 25.4 21.3 24.4 21.4 23.3 21.7 22.3 22.9 21.6 25.6 20.7 28.4 19.7 31.7 17 38.1 16.2 39.6 14.1 42.9 13.4 43.8 11.8 45.5 10.5 47.3 10.5 44.8 10.7 42.8 10.7 40.5 10.9 38.5 10.9 36.5 11 34.3 11 32.3 11.2 30 11.1 28 11.1 25.8 11 24 11.1 21.5 11 19.7 11 17.7 10.9 15.5 11 13.2 11.1 10.5 11 9.5 10.6 7.7 10.4 7.3 10.2 7.1 9.9 6.9 9.6 6.8 9.2 6.8 8.9 6.9 8.6 7.1 8.4 7.3 8.2 7.7 8.1 8.8 7.8 10.3 7.7 11 8.1 13.5 8.1 15.5 8.2 17.3 8.1 19.8 8.2 21.8 8.2 23.8 8.3 25.8 8.1 28 8.1 30.2 8 32.2 8.1 34.2 7.9 36.5 7.9 38.5 7.8 40.2 7.8 42.7 7.7 44.7 7.7 46.7 7.5 48.7 7.6 51 7.4 53.5 7.5 53.9 7.6 54.2 7.9 54.5 8.2 54.8 8.6 54.9 9 54.9 10.2 54.8 12.5 54.9 14.7 54.9 17 55 19.2 54.8 21.5 54.9 23.8 54.8 26 54.9 28.3 54.8 30.3 54.9 32.8 54.8 35 54.9 37.3 54.9 39.5 55 41.8 54.9 43.8 54.9 45.5 54.8 47.8 55 48.5 54.9 50 54.7 50.4 54.5 50.7 54.2 50.9 53.8 51 53.4 51 53 50.9 52.5 50.7 52.2 50.3 51.9 49.9 51.7 47.2 51.6 44.2 51.9 41.7 51.9 39.5 52 38.3 52 38.3 51.3 38.5 50.6 39 49.2 39 48.7 39.1 48.3ZM25.6 27.6L26.7 27.8 28 27.9 28.8 27.8 29.7 27.3 30.4 30.4 32.5 37 32.5 40 32.5 40.9 32.5 41.8 32.9 44.5 32.9 45.4 33.1 47 33.4 48.2 33.5 50 33.6 52 33.9 52 33.9 50.9 34 50 34 49.1 34.4 46.3 34.4 43.6 34.5 42.7 34.5 41.1 35.8 43.7 36.5 44.8 37.2 45.6 37.2 45.8 37 46.1 36.9 46.3 37.1 46.5 37.2 46.7 37.2 47.4 37.2 47.9 37.5 49.5 37.7 50.2 37.8 50.9 38 52 34.7 52.1 32.7 52.1 30.5 52.1 28.2 52 26 52 23.7 51.9 21.9 52 21.9 51.5 22 50.6 22 49.7 22.1 48.8 22.1 47.9 22.3 47.2 22.3 46.3 22.4 45.2 22.4 43.6 22.4 42.7 22.4 40.9 22.5 40.2 22.4 39.3 22.4 38 22.5 37.1 22.3 36.3 23.5 33.3 24.4 29.8 25.2 27.6ZM10.3 52L10.3 50.7 10.6 50.8 11 50.9 11.5 50.8 11.9 50.6 15 48.7 15.6 48.1 16.1 47.6 16.1 48.1 16.3 48.6 16.3 48.8 16.5 49.5 16.7 49.7 16.9 50.9 16.9 51.3 17 51.5 17 51.9 14.8 51.8 12 52ZM17.6 45.5L20.5 40.7 20.7 42.1 20.8 44.5 21 45.4 21 46.1 21.2 47.3 21.3 47.9 21.4 48.8 21.6 50.6 21.6 52 19.3 51.8 17.3 51.9 17.5 50.6 17.7 50.4 17.8 49.4 17.9 49.2 18.1 48.5 18.1 47.8 18 47.6 17.9 46.5 17.9 46.2 17.9 46 17.7 45.8ZM29.5 26.3L28.4 25.9 28 25.9 27.1 25.7 26.1 25.7 25.8 25.7 25.8 25.4 29.3 25.5ZM22 48.8L21.9 49.7 21.9 50.6 21.8 51.3 21.7 51.3 21.9 48.8ZM33.2 42.3L33.3 43.6 33.4 44.5 33.4 45 33.3 45 33.1 42.3ZM17.1 50.9L17.1 51.3 17.2 51.5 17.1 51.8 17 51.8 17 50.9ZM37.8 48.8L37.9 49.7 38 50.2 37.9 50.2 37.7 48.8Z"/>
      <path style="fill: var(--vp-c-brand-1)" d="M51 11.9L51.5 13.1 51.8 13.7 51.9 14.4 51.9 15.1 51.7 15.7 51.4 16.4 51 17 50.5 17.5 50 17.9 48.9 18.7 47.7 19.3 47 19.4 46.4 19.5 45.7 19.5 45 19.4 44.4 19.2 43.2 18.6 42.7 18.2 42.3 17.7 41.9 17.2 41.6 16.6 41.4 15.9 41.4 15.3 41.4 14.6 41.7 13.4 42.1 12.1 42.4 11.5 42.8 10.9 43.3 10.4 43.9 10 44.6 9.8 45.3 9.6 46 9.5 47.3 9.6 47.9 9.7 48.6 9.9 49.2 10.2 49.7 10.5 50.2 10.9Z"/>
    </symbol>
    <symbol id="fsi-array" viewBox="0 0 28 28"><g fill="none" stroke="currentColor" stroke-width="1.6"><rect x="3" y="5" width="22" height="18" rx="3"/><path d="M3 11h22M3 17h22M10.3 5v18M17.6 5v18"/></g></symbol>
    <symbol id="fsi-script" viewBox="0 0 28 28"><g fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"><path d="M7 3h10l5 5v17H7z"/><path d="M17 3v5h5M10 13h9M10 17h9M10 21h6"/></g></symbol>
    <symbol id="fsi-log" viewBox="0 0 28 28"><g fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"><path d="M4 7h12M4 12h16M4 17h10M4 22h7"/><path d="M20 18v6M17 21h6" stroke-width="2"/></g></symbol>
    <linearGradient id="fsi-in" x1="0" x2="1"><stop offset="0" style="stop-color: var(--fs-ink-3); stop-opacity: .3"/><stop offset="1" style="stop-color: var(--fs-ink-3); stop-opacity: .12"/></linearGradient>
    <linearGradient id="fsi-o1" x1="0" x2="1"><stop offset="0" style="stop-color: var(--fs-path-1); stop-opacity: .12"/><stop offset="1" style="stop-color: var(--fs-path-1); stop-opacity: .5"/></linearGradient>
    <linearGradient id="fsi-o2" x1="0" x2="1"><stop offset="0" style="stop-color: var(--fs-path-2); stop-opacity: .12"/><stop offset="1" style="stop-color: var(--fs-path-2); stop-opacity: .5"/></linearGradient>
    <linearGradient id="fsi-o3" x1="0" x2="1"><stop offset="0" style="stop-color: var(--fs-path-3); stop-opacity: .12"/><stop offset="1" style="stop-color: var(--fs-path-3); stop-opacity: .5"/></linearGradient>
  </defs>
  <!-- in: three sources -->
  <path fill="url(#fsi-in)" d="M222 58 C290 58 300 146 362 146 L362 162 C298 162 286 86 222 86 Z"/>
  <path fill="url(#fsi-in)" d="M222 168 C290 168 300 172 362 172 L362 188 C300 188 290 196 222 196 Z"/>
  <path fill="url(#fsi-in)" d="M222 278 C286 278 298 198 362 198 L362 214 C300 214 290 306 222 306 Z"/>
  <rect x="16" y="40" width="206" height="64" rx="16" class="card"/>
  <use href="#fsi-array" x="30" y="58" width="28" height="28" style="color: var(--vp-c-text-2)"/>
  <text x="70" y="67" class="t-head" font-size="14">Fortran arrays</text>
  <text x="70" y="87" class="t-mono" font-size="11">fig%plot(x, y)</text>
  <rect x="16" y="150" width="206" height="64" rx="16" class="card"/>
  <use href="#fsi-script" x="30" y="168" width="28" height="28" style="color: var(--vp-c-text-2)"/>
  <text x="70" y="177" class="t-head" font-size="14">gnuplot scripts</text>
  <text x="70" y="197" class="t-mono" font-size="11">foresight run.gp</text>
  <rect x="16" y="260" width="206" height="64" rx="16" class="card"/>
  <use href="#fsi-log" x="30" y="278" width="28" height="28" style="color: var(--vp-c-text-2)"/>
  <text x="70" y="287" class="t-head" font-size="14">a growing log</text>
  <text x="70" y="307" class="t-mono" font-size="11">run.dat, run.csv</text>
  <!-- the engine: the icon -->
  <rect x="368" y="82" width="164" height="214" rx="28" class="shade" transform="translate(0 6)"/>
  <rect x="368" y="78" width="164" height="214" rx="28" class="card"/>
  <use href="#fsi-icon" x="395" y="92" width="110" height="110"/>
  <text x="450" y="240" text-anchor="middle" class="t-display" font-size="25">foresight</text>
  <text x="450" y="264" text-anchor="middle" class="t-cap" font-size="8.5">ONE ENGINE · PURE FORTRAN</text>
  <circle cx="368" cy="154" r="3.5" class="dot"/><circle cx="368" cy="180" r="3.5" class="dot"/><circle cx="368" cy="206" r="3.5" class="dot"/>
  <circle cx="532" cy="151" r="3.5" class="p1"/><circle cx="532" cy="180" r="3.5" class="p2"/><circle cx="532" cy="209" r="3.5" class="p3"/>
  <!-- out: three paths -->
  <path fill="url(#fsi-o1)" d="M538 142 C590 142 600 42 648 42 L648 98 C602 98 592 160 538 160 Z"/>
  <path fill="url(#fsi-o2)" d="M538 171 C586 171 600 152 648 152 L648 208 C600 208 586 189 538 189 Z"/>
  <path fill="url(#fsi-o3)" d="M538 200 C592 200 602 262 648 262 L648 318 C600 318 590 218 538 218 Z"/>
  <rect x="648" y="20" width="236" height="100" rx="18" class="card"/>
  <rect x="662" y="34" width="72" height="72" rx="12" class="soft"/>
  <path d="M672 96 V44 M672 96 H726" class="axis"/>
  <path d="M674 90 C684 48 694 46 702 68 S716 90 724 54" class="p1-s" stroke-width="2.2" stroke-linecap="round"/>
  <text x="748" y="56" class="t-head" font-size="13.5">gnuplot, from Fortran</text>
  <text x="748" y="76" class="t-body" font-size="11.5">its commands, its plots</text>
  <text x="748" y="94" class="t-mono p1" font-size="10.5">SVG · HTML</text>
  <rect x="648" y="130" width="236" height="100" rx="18" class="card"/>
  <rect x="662" y="144" width="72" height="72" rx="12" class="soft"/>
  <rect x="668" y="150" width="60" height="9" rx="3" style="fill: var(--vp-c-divider)"/>
  <circle cx="673" cy="154.5" r="1.6" class="dot"/><circle cx="678" cy="154.5" r="1.6" class="dot"/>
  <path d="M671 166 C680 166 684 196 694 196 S712 192 722 202" class="p2-s" stroke-width="2.2" stroke-linecap="round"/>
  <circle cx="722" cy="202" r="3.4" class="p2 pulse"/><circle cx="722" cy="202" r="3.4" class="p2"/>
  <text x="748" y="166" class="t-head" font-size="13.5">Watch a running job</text>
  <text x="748" y="186" class="t-body" font-size="11.5">redrawn as the log grows</text>
  <text x="748" y="204" class="t-mono p2" font-size="10.5">browser · terminal</text>
  <rect x="648" y="240" width="236" height="100" rx="18" class="card"/>
  <rect x="662" y="254" width="72" height="72" rx="12" class="soft"/>
  <rect x="676" y="258" width="44" height="64" rx="2" class="paper" style="stroke: var(--fs-ink-3)" stroke-width=".8"/>
  <rect x="681" y="264" width="34" height="20" class="p3" opacity=".18"/>
  <path d="M683 280 C690 266 698 266 704 274 S712 280 714 268" class="p3-s" stroke-width="1.6"/>
  <path d="M681 290 H715 M681 296 H715 M681 302 H708 M681 308 H715 M681 314 H700" class="axis" stroke-width="1.1"/>
  <text x="748" y="276" class="t-head" font-size="13.5">Papers and reports</text>
  <text x="748" y="296" class="t-body" font-size="11.5">printed size, TeX math</text>
  <text x="748" y="314" class="t-mono p3" font-size="10">PDF · LaTeX · Markdown</text>
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
