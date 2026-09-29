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
| `rename_file`, `sleep_ms` | `foresight_sys` | atomic rename and sub-second sleep (libc) |
| `I4P`, `I8P`, `R4P`, `R8P` | PENF | kind parameters |

The other modules are internal: their interfaces may change without notice.
