---
title: C4. Multi-panel figures
---

# C4. Multi-panel figures

**Goal:** one figure of several panels across the page, labelled (a), (b), (c), in the paper's font.

<<< @/examples/snippets/pc04_panels-figure.gp{gnuplot}

<Plot name="pc04" svg :width="673" :height="302" />

[pc04.pdf](/examples/pc04.pdf) spans the page (`size double`, 17.8 x 8 cm), its texts in Latin Modern Roman
(`theme paper serif`): the figure* environment of a two-column paper takes it as it is.

## Why it works

- `set multiplot layout 1,3 title "..."` divides the page as gnuplot does: the title's band on top (its lines a
  character height each), then three cells of equal width; each panel's own title takes gnuplot's room above its plot.
- The panels share the page's font and sizes: one `set terminal` sets them all.
- `plot for [z in "0.1 0.3 1"]` draws one curve per value, `"ζ = ".z` its key entry.

## Try this

- `set multiplot layout 2,2`: four panels in a `size 17.8cm,12cm` page.
- `set key off` in all panels but the first: one key for the figure.

## Pitfalls

- Panels placed by `set origin` and `set size` under a multiplot title start below foresight's title band, where
  gnuplot draws them from the page's top (a documented difference: see [Comparison](/guide/comparison)).
- Each panel measures its own margins: give the panels the same tick label widths (`set format y "%.1f"`) to align
  their plot areas.
