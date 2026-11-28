---
title: TeX math in labels
---

# TeX math in labels

A text's `$...$` runs are TeX math: foresight lays them out as LaTeX does and draws them itself, in every format. It
needs no LaTeX installation, and the figure looks the same on every machine.

```gnuplot
set xlabel '$t/\tau$'
set ylabel '$\left|H(i\omega)\right|$ [dB]'
plot f(x) title '$e^{-t/\tau}\cos\omega t$'
```

```fortran
call fig%set_xlabel('$t/\tau$')
call fig%plot(t, u, title='$u_\infty \le 10^{-3}$')
```

<Plot name="pc07" svg :width="600" :height="400" caption="TeX math in a title, axis labels, key titles and a label" />

## What is set

| Kind | Examples |
|---|---|
| Letters, digits | math italic letters, upright digits and signs; Greek `\alpha` ... `\omega`, `\Gamma` ... `\Omega`, `\varepsilon`, `\vartheta`, `\varphi` |
| Scripts | `x_i^2`, `e^{-x^2}`, `a^{b^c}`, primes `f'` |
| Structures | `\frac{a}{b}`, `\sqrt{x}` (sized to its content), `\left(` ... `\right)` with `( ) [ ] \| \{ \} \langle \rangle` |
| Operators, relations | `+ - \pm \times \cdot = < > \le \ge \ne \approx \equiv \sim \propto \to \in \subset`, `\partial \nabla \infty \ell \hbar` |
| Large operators | inline `\sum`, `\prod`, `\int`, their limits as scripts |
| Accents | `\hat`, `\bar`, `\vec`, `\tilde`, `\dot`, `\ddot` |
| Fonts and names | `\mathrm{..}`, `\mathbf{..}`, `\mathit{..}` (the text font's faces, as unicode-math sets them); `\sin`, `\cos`, `\exp`, `\log`, `\max`, ... upright |
| Spaces | `\,`, `\:`, `\;`, `\!`, `\quad`, `\qquad` |

Not set: display style, environments (`\begin{...}`), matrices, line breaks. A label's math is inline, as in a
paragraph of text. For any of these, let LaTeX set the label ([LaTeX labels](latex)).

## Where it works

| Output | Math is |
|---|---|
| SVG, HTML | drawn from Latin Modern Math's glyphs, over the source kept as transparent text (selectable, searchable) |
| PDF | drawn from the glyphs, embedded as a font of their own with their Unicode |
| `cairolatex` | handed to the paper's LaTeX, as written |
| `dumb`, `block` | written as its source |

In any label, title, key title or tick label; `set format y '$%.1f$'` sets the tick numbers in math.

## How close to LaTeX

The layout follows TeX's rules (The TeXbook's appendix G) with the constants of Latin Modern Math's MATH table: script
sizes of 70 % and 50 % with their script glyphs, the shifts of sub- and superscripts, the fraction's rule on the math
axis, the radical's size variant. The test suite sets 40 formulas and compares every glyph with LuaLaTeX's
(unicode-math): all within 0.5 pt at 10 pt (`foresight_math_test`), in the SVG and the PDF of a figure too
(`scripts/check_math.py`).

## Rules

- **When `$` starts math:** a `$` opens math only when another one closes it, as pandoc reads Markdown. A single `$`
  is a dollar (`'cost: $5'`), and in a text holding math `\$` is a dollar (`'from \$5 to $x_0$'`).
- **Mixed with enhanced text:** the text around a formula stays enhanced text (`'{/:Bold Gain} $|H|$'`).
- **Never math:** automatic titles (`plot 'data$1.dat'`) and `noenhanced` texts.
- **In the HTML viewer:** a zoom draws the tick labels again as plain text, so a math tick format shows its source after
  a zoom.

## See also

- [C7. Math in labels](/manual/paths/c-paper/07-math-in-labels): a figure with math, for a paper.
- [Fonts](fonts): the text fonts around the math.
- [LaTeX labels](latex): the whole label set by the paper's LaTeX.
