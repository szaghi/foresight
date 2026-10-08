---
title: Tutorial
---

# Tutorial

The tutorial follows one job from its first plot to a live dashboard: a pretend flow solver whose residuals fall over
the iterations while its drag coefficient settles. Each chapter is a complete program or script of
[`docs/examples/src`](https://github.com/szaghi/foresight/tree/master/docs/examples/src); every plot on these pages is
the page it wrote, live — zoom it.

| Chapter | You learn |
|---|---|
| [1. A first plot](./tutorial/01-first-plot) | `figure_object`: plot arrays, label the axes, save HTML and SVG |
| [2. Styles and the key](./tutorial/02-styles) | colors, widths, dash and point types; the key inside or outside |
| [3. Axes](./tutorial/03-axes) | log scale, grid, ranges, tick steps and label formats |
| [4. From the log, with a script](./tutorial/04-scripts) | the solver log and a gnuplot script; `using`, `every`, `''`, `-e` |
| [5. CSV and expressions](./tutorial/05-data) | separators, columns by header name, values computed per row, gaps |
| [6. Two axes and a model](./tutorial/06-two-axes) | the second y axis; functions of `x` sampled over the data |
| [7. A dashboard](./tutorial/07-dashboard) | multiplot layouts, error bars, an inset |
| [8. Watching the run](./tutorial/08-live) | `--watch`, the reloading page, the text terminal over ssh |

```mermaid
flowchart LR
  A[1. first plot] --> B[2. styles] --> C[3. axes] --> D[4. scripts]
  D --> E[5. CSV] --> F[6. two axes] --> G[7. dashboard] --> H[8. live]
```

Chapters 1–3 use the Fortran library, 4–8 the command line: the two are the same engine, a script is what a program
writes through `figure_object` calls, line by line.

## Then

The [Cookbook](./cookbook) answers one task per recipe; the [Reference](/guide/features) covers every command and
method.

## Running the examples

```bash
bash scripts/docs_examples.sh
```

builds the library and the command line, compiles and runs every example, and regenerates the snippets, outputs and
plots these pages include. The CI runs it too and fails if any of them differs from the committed one.
