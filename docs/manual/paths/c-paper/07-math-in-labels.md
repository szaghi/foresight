---
title: C7. Math in labels
---

# C7. Math in labels

**Goal:** formulas in a figure's labels, set as LaTeX sets them, in an SVG, a PDF or a web page.

<<< @/examples/snippets/pc07_math_labels-labels.gp

<Plot name="pc07" svg :width="600" :height="400" />

A text's `$...$` runs are TeX math: the title, the axis labels, the key titles and the label above. foresight lays
them out itself, with TeX's rules and the font LaTeX uses (Latin Modern Math), and draws their glyphs: no LaTeX
installation, the same figure on every machine.

<<< @/examples/snippets/pc07_math_labels-paper.gp

[pc07.pdf](/examples/pc07.pdf) is the figure for a paper's column: the math glyphs are embedded in it with the text's.

## What it sets

- Letters in math italic, digits and signs upright; Greek (`\alpha` ... `\omega`, `\Gamma` ... `\Omega`, `\varepsilon`,
  `\vartheta`, `\varphi`).
- Sub- and superscripts (`x_i^2`, `e^{-x^2}`, `a^{b^c}`), primes (`f'`).
- `\frac{a}{b}`, `\sqrt{x}` (the radical sized to its content), `\left(` ... `\right)` (`( ) [ ] | \{ \} \langle
  \rangle`).
- Operators and relations with TeX's spacing: `+ - \pm \times \cdot = < > \le \ge \ne \approx \equiv \sim \propto \to
  \in \subset`, `\partial \nabla \infty \ell \hbar`; inline `\sum`, `\prod`, `\int` with their limits as scripts.
- Accents `\hat`, `\bar`, `\vec`, `\tilde`, `\dot`, `\ddot`; `\mathrm{..}`, `\mathbf{..}`, `\mathit{..}` (the text
  font's faces, as unicode-math sets them); `\sin`, `\cos`, `\exp`, `\log`, `\max`, ... upright; spaces `\,`, `\:`,
  `\;`, `\!`, `\quad`, `\qquad`.

## Why it works

- foresight's math layout is TeX's (The TeXbook's appendix G) with the constants of the font's MATH table: script
  sizes 70 % and 50 % with their script glyphs, the shifts of sub- and superscripts, the fraction's shifts and rule on
  the math axis, the radical's size variant. Its test sets 40 formulas and compares every glyph with LuaLaTeX's: within
  0.5 pt at 10 pt (the worst is 0.15 pt).
- The SVG and the web page draw a text holding math from the glyphs (defined once, used per character), the text kept
  under them, transparent: selectable and searchable, as `fontglyphs` texts are. The PDF embeds the math glyphs as a
  Type 3 font of their own, with their Unicode.

## Try this

- `set label '$\left(\frac{\partial u}{\partial t}\right)_{\max} \le 10^{-3}$'`: a fenced fraction with a subscript.
- `set format y '$%.1f$'`: tick labels in math, their digits Latin Modern.
- `set terminal cairolatex` ([C6](06-labels-set-by-latex)): LaTeX sets the whole label, in the paper's own fonts.

## Pitfalls

- A `$` in a text starts math when another follows it: in a text holding math write `\$` for a dollar (`'from \$5
  to $x_0$'`); a single `$` is a dollar. An automatic title
  (`plot 'data$1.dat'`) and a `noenhanced` text are never math.
- No display style, `\begin{...}` environments, matrices or line breaks: a label's math is inline.
- The text devices (`dumb`, `block`) write the source as it is.
