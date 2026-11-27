---
title: API Reference
---

# API Reference

The [API section](/api/) documents every module, type and procedure, generated from the source comments by
[formal](https://github.com/szaghi/formal):

```bash
cd docs
npm run docs:api      # formal generate --mirror-sources --diagrams --project ford.md --output api
```

`npm run docs:dev` and `npm run docs:build` regenerate it first.

## Public entry point

`use foresight` exports:

| Entity | Module | Purpose |
|---|---|---|
| `figure_object` | `foresight_figure` | figure with the gnuplot-like API — see [Fortran Library](library) |
| `script_object` | `foresight_script` | gnuplot subset interpreter — see [Scripts from Fortran](library#scripts-from-fortran) |
| `fit`, `fit_report`, `fit_result`, `fit_settings`, `model_function` | `foresight_fit` | gnuplot's `fit` for Fortran models — see [Fitting a model](library#fitting-a-model) |
| `stats`, `stats_report`, `stats_result`, `stats_column` | `foresight_stats` | gnuplot's `stats` of arrays — see [Statistics](library#statistics) |
| `civil_time`, `strftime`, `strptime` | `foresight_time` | gnuplot's time conversions — see [Times](library#times) |
| `rename_file`, `sleep_ms` | `foresight_sys` | atomic rename (`rename_file(old, new, [iostat])`: without `iostat` a failure stops) and sub-second sleep (libc) |
| `file_fingerprint` | `foresight_fingerprint` | a cheap fingerprint of a file's content, to tell that it changed (the watch mode) |
| `THEMES` | `foresight_theme` | the names of the output themes, blank separated: `classic vfd lcd washi night paper` |
| `I4P`, `I8P`, `R4P`, `R8P` | PENF | kind parameters |

The other modules are internal: their interfaces may change without notice.
