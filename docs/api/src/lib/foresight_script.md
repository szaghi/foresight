---
title: foresight_script
---

# foresight_script

> foresight_script, interpreter of a gnuplot command subset.

 Supported (with gnuplot abbreviations):

 - `set|unset title|xlabel|ylabel|y2label ["text"]`, `set xrange|yrange|y2range [min:max]` (`*` or empty autoscales
   an end), `set|unset logscale [AXES]` (AXES concatenates x, y, y2, e.g. `xy2`; all when absent),
   `set|unset grid`, `set|unset key`, `set output "file"`, `set terminal svg|html [size W,H] [refresh SECONDS]`;
 - `set terminal dumb [size COLS,ROWS] [mono|ansi|ansi256|ansirgb]` (text, default 79x24 on standard output `-`),
   `set terminal block [half|quadrants|sextants|braille] [size COLS,ROWS] [mono|ansi|ansi256|ansirgb]` (text drawn
   with Unicode block or Braille characters);
 - `set|unset multiplot [layout ROWS,COLS] [title "t"]`: each `plot` fills the next panel, settings carry over;
   without layout each panel lies in its `set origin X,Y` / `set size W,H` box (page fractions);
 - `set xtics|ytics|y2tics [auto|STEP|START,STEP[,END]] [mirror|nomirror]` (y2 ticks are off until set),
   `unset xtics|ytics|y2tics`, `set format [AXES] ["fmt"]`, `unset format`,
   `set key [on|off] [left|right|center] [top|bottom|center] [box|nobox] [autotitle [columnhead]|noautotitle]`,
   `set style data|function STYLE`, `unset style function`, `set style line N [lc ...] [lt N] [lw W] [dt N] [pt N]
   [ps S]`;
 - `set datafile separator [whitespace|tab|comma|"chars"]`, `unset datafile [separator]`; `set samples N[,M]`;
 - `plot 'file' [using [X:]Y[:...]] [index N] [every I:J:K:L:M:N] [with STYLE] [title "t"|notitle] [axes x1y1|x1y2]
   [smooth unique|frequency|fnormal|cumulative|cnormal] [lc [rgb] "color"|N] [lw W] [dt N] [pt N] [ps S], ...` (`''`
   repeats the previous file; smooth: see foresight_smooth), STYLE `lines|points|linespoints|
   yerrorbars|xerrorbars|xyerrorbars` (error bars: `x:y:dy` or `x:y:low:high`, `x:y:dx:dy` or
   `x:y:xlow:xhigh:ylow:yhigh`); `replot [items]`; a `using` field is a column number or a parenthesized expression,
   `($2*1e3)` (see foresight_expression), or a column header name, `"residual"`; `title columnhead[(N)]` titles an
   item with a column header; `ls N`, `lt N` in an item apply a line style, a palette color;
 - a function of `x` as a plot item, `plot sin(x)/x title "sinc"` (same options, styles lines, points or linespoints,
   `set style function`, `lines` by default): sampled at `set samples` points (100) over the x range before its
   extension to the ticks, the data extent, or [-10:10] with neither; evenly in log x on a log axis.

 Anything else is an error naming the command, never silently ignored. Errors are returned (`iostat`, `iomsg` with
 `source:line:`), not stopped on, so a watch loop can survive a bad cycle.

**Source**: `src/lib/foresight_script.F90`

**Dependencies**

```mermaid
graph LR
  foresight_script["foresight_script"] --> foresight_axes["foresight_axes"]
  foresight_script["foresight_script"] --> foresight_datafile["foresight_datafile"]
  foresight_script["foresight_script"] --> foresight_expression["foresight_expression"]
  foresight_script["foresight_script"] --> foresight_figure["foresight_figure"]
  foresight_script["foresight_script"] --> foresight_format["foresight_format"]
  foresight_script["foresight_script"] --> foresight_smooth["foresight_smooth"]
  foresight_script["foresight_script"] --> foresight_style["foresight_style"]
  foresight_script["foresight_script"] --> foresight_ticks["foresight_ticks"]
  foresight_script["foresight_script"] --> foresight_tokens["foresight_tokens"]
```

## Contents

- [line_style_object](#line-style-object)
- [script_object](#script-object)
- [init](#init)
- [run_file](#run-file)
- [run_text](#run-text)
- [execute](#execute)
- [plot_command](#plot-command)
- [register_file](#register-file)
- [save_output](#save-output)
- [set_command](#set-command)
- [unset_command](#unset-command)
- [fail](#fail)
- [parse_using](#parse-using)
- [apply_line_style](#apply-line-style)
- [parse_every](#parse-every)
- [after_command](#after-command)
- [axes_argument](#axes-argument)
- [canonical_style](#canonical-style)
- [change_extension](#change-extension)
- [extension](#extension)
- [is_multiplot_option](#is-multiplot-option)
- [keyword](#keyword)
- [is_word](#is-word)
- [next_integer](#next-integer)
- [next_real](#next-real)
- [next_word](#next-word)
- [no_more](#no-more)
- [columnhead_title](#columnhead-title)
- [function_drawable](#function-drawable)
- [is_item_option](#is-item-option)
- [is_line_option](#is-line-option)
- [line_option](#line-option)
- [plain_columns](#plain-columns)
- [string_argument](#string-argument)
- [valid_axes](#valid-axes)
- [to_number](#to-number)

## Variables

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `DUMB_CELL` | real(kind=R8P) | parameter | Text device cell size [font size]. |

## Derived Types

### line_style_object

Line properties: a `set style line`, or the options of a plot item; unallocated means the default.

#### Components

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `id` | integer(kind=I4P) |  | Style number. |
| `lc` | character(len=:) | allocatable | Color. |
| `lw` | real(kind=R8P) | allocatable | Line width. |
| `dt` | integer(kind=I4P) | allocatable | Dash type. |
| `ps` | real(kind=R8P) | allocatable | Point size. |
| `pt` | integer(kind=I4P) | allocatable | Point type. |

### script_object

Script interpreter state.

#### Components

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `figure` | type([figure_object](/api/src/lib/foresight_figure#figure-object)) |  | Figure being built. |
| `output` | character(len=:) | allocatable | Current output file. |
| `output_set` | logical |  | Output set by `set output`. |
| `previous_file` | character(len=:) | allocatable | File of the last plot item, for `''`. |
| `last_plot` | character(len=:) | allocatable | Items of the last plot, for `replot`. |
| `data_files` | type([token_object](/api/src/lib/foresight_tokens#token-object)) | allocatable | Data files read, for watching. |
| `live_refresh` | integer(kind=I4P) |  | HTML reload period applied when none is set [s]. |
| `multiplot` | logical |  | Inside `set multiplot`. |
| `advance_pending` | logical |  | A multiplot panel was plotted: the next command |
| `data_style` | character(len=:) | allocatable | Default plot style, `set style data`. |
| `function_style` | character(len=:) | allocatable | Default function style, `set style function`. |
| `autotitle` | character(len=:) | allocatable | Untitled items: `file` (as written), `columnhead`, |
| `line_styles` | type([line_style_object](/api/src/lib/foresight_script#line-style-object)) | allocatable | `set style line` definitions. |
| `separator` | character(len=:) | allocatable | Data cell separators, empty for whitespace. |
| `samples` | integer(kind=I4P) |  | Function samples, `set samples`. |

#### Type-Bound Procedures

| Name | Attributes | Description |
|------|------------|-------------|
| `execute` | pass(self) | Execute one statement. |
| `init` | pass(self) | Reset the interpreter. |
| `run_file` | pass(self) | Run a script file. |
| `run_text` | pass(self) | Run script text. |
| `plot_command` | pass(self) | `plot`. |
| `register_file` | pass(self) | Remember a data file. |
| `save_output` | pass(self) | Render to the current output. |
| `set_command` | pass(self) | `set`. |
| `unset_command` | pass(self) | `unset`. |

## Subroutines

### init

Reset the interpreter; plots go to `output` until `set output`.

```fortran
subroutine init(self, output)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([script_object](/api/src/lib/foresight_script#script-object)) | inout |  | Interpreter. |
| `output` | character(len=*) | in |  | Default output file. |

**Call graph**

```mermaid
flowchart TD
  init["init"] --> init["init"]
  init["init"] --> init["init"]
  style init fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### run_file

Run the script `file`.

```fortran
subroutine run_file(self, file, iostat, iomsg)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([script_object](/api/src/lib/foresight_script#script-object)) | inout |  | Interpreter. |
| `file` | character(len=*) | in |  | Script file. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  run_file["run_file"] --> run_text["run_text"]
  style run_file fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### run_text

Run script `text`: lines ending in `\` continue on the next one; the first error stops the run.

```fortran
subroutine run_text(self, text, iostat, iomsg, source)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([script_object](/api/src/lib/foresight_script#script-object)) | inout |  | Interpreter. |
| `text` | character(len=*) | in |  | Script text. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message, `source:line: ...`. |
| `source` | character(len=*) | in | optional | Source name for messages. |

**Call graph**

```mermaid
flowchart TD
  run_file["run_file"] --> run_text["run_text"]
  run_text["run_text"] --> process["process"]
  style run_text fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### execute

Execute one statement.

```fortran
subroutine execute(self, statement, iostat, iomsg)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([script_object](/api/src/lib/foresight_script#script-object)) | inout |  | Interpreter. |
| `statement` | character(len=*) | in |  | Statement. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  execute["execute"] --> after_command["after_command"]
  execute["execute"] --> fail["fail"]
  execute["execute"] --> is_multiplot_option["is_multiplot_option"]
  execute["execute"] --> keyword["keyword"]
  execute["execute"] --> next_panel["next_panel"]
  execute["execute"] --> plot_command["plot_command"]
  execute["execute"] --> set_command["set_command"]
  execute["execute"] --> tokenize["tokenize"]
  execute["execute"] --> unset_command["unset_command"]
  style execute fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### plot_command

`plot` items: each a data file or a function with modifiers, comma separated; replaces the previous plot and
 renders it.

 Functions are sampled once all the items are read: their x range depends on the data of the whole plot, as gnuplot.
 Until then each holds its place (its color, its key row) as an empty series.

```fortran
subroutine plot_command(self, tokens, text, iostat, iomsg)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([script_object](/api/src/lib/foresight_script#script-object)) | inout |  | Interpreter. |
| `tokens` | type([token_object](/api/src/lib/foresight_tokens#token-object)) | in |  | Items tokens. |
| `text` | character(len=*) | in |  | Text the tokens come from, for function titles. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  execute["execute"] --> plot_command["plot_command"]
  plot_command["plot_command"] --> apply_line_style["apply_line_style"]
  plot_command["plot_command"] --> canonical_style["canonical_style"]
  plot_command["plot_command"] --> clear["clear"]
  plot_command["plot_command"] --> columnhead_title["columnhead_title"]
  plot_command["plot_command"] --> compile["compile"]
  plot_command["plot_command"] --> default_using["default_using"]
  plot_command["plot_command"] --> fail["fail"]
  plot_command["plot_command"] --> function_drawable["function_drawable"]
  plot_command["plot_command"] --> header_title["header_title"]
  plot_command["plot_command"] --> is_item_option["is_item_option"]
  plot_command["plot_command"] --> is_line_option["is_line_option"]
  plot_command["plot_command"] --> is_word["is_word"]
  plot_command["plot_command"] --> keyword["keyword"]
  plot_command["plot_command"] --> line_option["line_option"]
  plot_command["plot_command"] --> load["load"]
  plot_command["plot_command"] --> missing_name["missing_name"]
  plot_command["plot_command"] --> name_count["name_count"]
  plot_command["plot_command"] --> next_integer["next_integer"]
  plot_command["plot_command"] --> next_word["next_word"]
  plot_command["plot_command"] --> parse_every["parse_every"]
  plot_command["plot_command"] --> parse_using["parse_using"]
  plot_command["plot_command"] --> plain_columns["plain_columns"]
  plot_command["plot_command"] --> plot["plot"]
  plot_command["plot_command"] --> register_file["register_file"]
  plot_command["plot_command"] --> sample_functions["sample_functions"]
  plot_command["plot_command"] --> save_output["save_output"]
  plot_command["plot_command"] --> set_column["set_column"]
  plot_command["plot_command"] --> smooth["smooth"]
  plot_command["plot_command"] --> table["table"]
  style plot_command fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### register_file

Remember `file` among the data files read (once).

```fortran
subroutine register_file(self, file)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([script_object](/api/src/lib/foresight_script#script-object)) | inout |  | Interpreter. |
| `file` | character(len=*) | in |  | Data file. |

**Call graph**

```mermaid
flowchart TD
  plot_command["plot_command"] --> register_file["register_file"]
  style register_file fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### save_output

Render the figure to the current output; the format follows its extension.

```fortran
subroutine save_output(self, iostat, iomsg)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([script_object](/api/src/lib/foresight_script#script-object)) | inout |  | Interpreter. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  plot_command["plot_command"] --> save_output["save_output"]
  unset_command["unset_command"] --> save_output["save_output"]
  save_output["save_output"] --> extension["extension"]
  save_output["save_output"] --> fail["fail"]
  save_output["save_output"] --> set_refresh["set_refresh"]
  style save_output fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### set_command

`set` options.

```fortran
subroutine set_command(self, tokens, iostat, iomsg)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([script_object](/api/src/lib/foresight_script#script-object)) | inout |  | Interpreter. |
| `tokens` | type([token_object](/api/src/lib/foresight_tokens#token-object)) | in |  | Option tokens. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  execute["execute"] --> set_command["set_command"]
  set_command["set_command"] --> axes_argument["axes_argument"]
  set_command["set_command"] --> change_extension["change_extension"]
  set_command["set_command"] --> datafile_option["datafile_option"]
  set_command["set_command"] --> fail["fail"]
  set_command["set_command"] --> format_option["format_option"]
  set_command["set_command"] --> is_word["is_word"]
  set_command["set_command"] --> key_option["key_option"]
  set_command["set_command"] --> keyword["keyword"]
  set_command["set_command"] --> next_integer["next_integer"]
  set_command["set_command"] --> no_more["no_more"]
  set_command["set_command"] --> pair_option["pair_option"]
  set_command["set_command"] --> samples_option["samples_option"]
  set_command["set_command"] --> set_grid["set_grid"]
  set_command["set_command"] --> set_logscale["set_logscale"]
  set_command["set_command"] --> set_multiplot["set_multiplot"]
  set_command["set_command"] --> set_range["set_range"]
  set_command["set_command"] --> set_refresh["set_refresh"]
  set_command["set_command"] --> set_text["set_text"]
  set_command["set_command"] --> set_title["set_title"]
  set_command["set_command"] --> set_xlabel["set_xlabel"]
  set_command["set_command"] --> set_y2label["set_y2label"]
  set_command["set_command"] --> set_ylabel["set_ylabel"]
  set_command["set_command"] --> string_argument["string_argument"]
  set_command["set_command"] --> style_option["style_option"]
  set_command["set_command"] --> tics_option["tics_option"]
  style set_command fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### unset_command

`unset` options.

```fortran
subroutine unset_command(self, tokens, iostat, iomsg)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([script_object](/api/src/lib/foresight_script#script-object)) | inout |  | Interpreter. |
| `tokens` | type([token_object](/api/src/lib/foresight_tokens#token-object)) | in |  | Option tokens. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  execute["execute"] --> unset_command["unset_command"]
  unset_command["unset_command"] --> axes_argument["axes_argument"]
  unset_command["unset_command"] --> fail["fail"]
  unset_command["unset_command"] --> keyword["keyword"]
  unset_command["unset_command"] --> no_more["no_more"]
  unset_command["unset_command"] --> save_output["save_output"]
  unset_command["unset_command"] --> set_format["set_format"]
  unset_command["unset_command"] --> set_grid["set_grid"]
  unset_command["unset_command"] --> set_key["set_key"]
  unset_command["unset_command"] --> set_title["set_title"]
  unset_command["unset_command"] --> set_xlabel["set_xlabel"]
  unset_command["unset_command"] --> set_y2label["set_y2label"]
  unset_command["unset_command"] --> set_ylabel["set_ylabel"]
  unset_command["unset_command"] --> unset_logscale["unset_logscale"]
  unset_command["unset_command"] --> unset_multiplot["unset_multiplot"]
  unset_command["unset_command"] --> unset_xtics["unset_xtics"]
  unset_command["unset_command"] --> unset_y2tics["unset_y2tics"]
  unset_command["unset_command"] --> unset_ytics["unset_ytics"]
  style unset_command fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### fail

Set an error.

**Attributes**: pure

```fortran
subroutine fail(message, iostat, iomsg)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `message` | character(len=*) | in |  | Error message. |
| `iostat` | integer(kind=I4P) | out |  | Set to 1. |
| `iomsg` | character(len=:) | out | allocatable | Set to `message`. |

**Call graph**

```mermaid
flowchart TD
  axes_argument["axes_argument"] --> fail["fail"]
  execute["execute"] --> fail["fail"]
  line_option["line_option"] --> fail["fail"]
  next_integer["next_integer"] --> fail["fail"]
  next_real["next_real"] --> fail["fail"]
  next_word["next_word"] --> fail["fail"]
  no_more["no_more"] --> fail["fail"]
  parse_every["parse_every"] --> fail["fail"]
  parse_using["parse_using"] --> fail["fail"]
  plot_command["plot_command"] --> fail["fail"]
  save_output["save_output"] --> fail["fail"]
  set_command["set_command"] --> fail["fail"]
  string_argument["string_argument"] --> fail["fail"]
  unset_command["unset_command"] --> fail["fail"]
  style fail fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### parse_using

`using` specification: 1 to 6 colon separated fields, each a column number (0 is the point number) or a
 parenthesized expression, as in gnuplot.

```fortran
subroutine parse_using(spec, fields, iostat, iomsg)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `spec` | character(len=*) | in |  | Specification. |
| `fields` | type([expression_object](/api/src/lib/foresight_expression#expression-object)) | out | allocatable | Fields. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  plot_command["plot_command"] --> parse_using["parse_using"]
  parse_using["parse_using"] --> compile["compile"]
  parse_using["parse_using"] --> fail["fail"]
  parse_using["parse_using"] --> is_parenthesized["is_parenthesized"]
  parse_using["parse_using"] --> is_quoted["is_quoted"]
  parse_using["parse_using"] --> set_column["set_column"]
  parse_using["parse_using"] --> set_name["set_name"]
  style parse_using fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### apply_line_style

Apply the line style `id` to `line`: its defined properties; an undefined style is the linetype `id`, as gnuplot.

**Attributes**: pure

```fortran
subroutine apply_line_style(styles, id, line)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `styles` | type([line_style_object](/api/src/lib/foresight_script#line-style-object)) | in |  | Defined styles. |
| `id` | integer(kind=I4P) | in |  | Style number. |
| `line` | type([line_style_object](/api/src/lib/foresight_script#line-style-object)) | inout |  | Line properties. |

**Call graph**

```mermaid
flowchart TD
  plot_command["plot_command"] --> apply_line_style["apply_line_style"]
  apply_line_style["apply_line_style"] --> default_color["default_color"]
  style apply_line_style fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### parse_every

gnuplot `every point_incr:block_incr:start_point:start_block:end_point:end_block`; empty or missing fields keep
 their defaults (1, 1, 0, 0, no end, no end).

```fortran
subroutine parse_every(spec, every, iostat, iomsg)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `spec` | character(len=*) | in |  | Specification. |
| `every` | integer(kind=I4P) | out |  | Fields, ends -1 for none. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  plot_command["plot_command"] --> parse_every["parse_every"]
  parse_every["parse_every"] --> fail["fail"]
  style parse_every fill:#3e63dd,stroke:#99b,stroke-width:2px
```

## Functions

### after_command

Text of `statement` after its first word.

**Attributes**: pure

**Returns**: `character(len=:)`

```fortran
function after_command(statement) result(rest)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `statement` | character(len=*) | in |  | Statement. |

**Call graph**

```mermaid
flowchart TD
  execute["execute"] --> after_command["after_command"]
  style after_command fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### axes_argument

Optional axes names after a `logscale` option (default all: `xyy2`); a base other than 10 is an error.

**Returns**: `logical`

```fortran
function axes_argument(tokens, axes, iostat, iomsg) result(ok)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `tokens` | type([token_object](/api/src/lib/foresight_tokens#token-object)) | in |  | Option tokens. |
| `axes` | character(len=:) | out | allocatable | Axes letters. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  set_command["set_command"] --> axes_argument["axes_argument"]
  unset_command["unset_command"] --> axes_argument["axes_argument"]
  axes_argument["axes_argument"] --> fail["fail"]
  axes_argument["axes_argument"] --> valid_axes["valid_axes"]
  style axes_argument fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### canonical_style

Full gnuplot style name of `word` (full or abbreviated), empty if unsupported.

**Attributes**: pure

**Returns**: `character(len=:)`

```fortran
function canonical_style(word) result(style)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `word` | character(len=*) | in |  | Style word. |

**Call graph**

```mermaid
flowchart TD
  plot_command["plot_command"] --> canonical_style["canonical_style"]
  style canonical_style fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### change_extension

`file` with its extension replaced by `ext` (appended if none).

**Attributes**: pure

**Returns**: `character(len=:)`

```fortran
function change_extension(file, ext) result(renamed)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `file` | character(len=*) | in |  | File name. |
| `ext` | character(len=*) | in |  | New extension. |

**Call graph**

```mermaid
flowchart TD
  set_command["set_command"] --> change_extension["change_extension"]
  style change_extension fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### extension

Lower case extension of `file`, empty if none.

**Attributes**: pure

**Returns**: `character(len=:)`

```fortran
function extension(file) result(ext)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `file` | character(len=*) | in |  | File name. |

**Call graph**

```mermaid
flowchart TD
  save["save"] --> extension["extension"]
  save_output["save_output"] --> extension["extension"]
  style extension fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### is_multiplot_option

Whether the statement is `set|unset multiplot ...`.

**Attributes**: pure

**Returns**: `logical`

```fortran
function is_multiplot_option(tokens) result(is)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `tokens` | type([token_object](/api/src/lib/foresight_tokens#token-object)) | in |  | Statement tokens. |

**Call graph**

```mermaid
flowchart TD
  execute["execute"] --> is_multiplot_option["is_multiplot_option"]
  is_multiplot_option["is_multiplot_option"] --> keyword["keyword"]
  style is_multiplot_option fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### keyword

Whether `word` abbreviates `full` with at least `minimum` characters, as gnuplot keywords.

**Attributes**: pure

**Returns**: `logical`

```fortran
function keyword(word, full, minimum) result(match)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `word` | character(len=*) | in |  | Word. |
| `full` | character(len=*) | in |  | Full keyword. |
| `minimum` | integer(kind=I4P) | in |  | Shortest accepted abbreviation. |

**Call graph**

```mermaid
flowchart TD
  columnhead_title["columnhead_title"] --> keyword["keyword"]
  execute["execute"] --> keyword["keyword"]
  is_item_option["is_item_option"] --> keyword["keyword"]
  is_line_option["is_line_option"] --> keyword["keyword"]
  is_multiplot_option["is_multiplot_option"] --> keyword["keyword"]
  line_option["line_option"] --> keyword["keyword"]
  plot_command["plot_command"] --> keyword["keyword"]
  set_command["set_command"] --> keyword["keyword"]
  unset_command["unset_command"] --> keyword["keyword"]
  style keyword fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### is_word

Whether `word` is one of the blank separated `words`.

**Attributes**: pure

**Returns**: `logical`

```fortran
function is_word(word, words) result(found)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `word` | character(len=*) | in |  | Word. |
| `words` | character(len=*) | in |  | Blank separated words. |

**Call graph**

```mermaid
flowchart TD
  plot_command["plot_command"] --> is_word["is_word"]
  set_command["set_command"] --> is_word["is_word"]
  set_text["set_text"] --> is_word["is_word"]
  style is_word fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### next_integer

Advance `i` to the next token, which must be an integer.

**Returns**: `logical`

```fortran
function next_integer(tokens, i, value, iostat, iomsg) result(ok)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `tokens` | type([token_object](/api/src/lib/foresight_tokens#token-object)) | in |  | Tokens. |
| `i` | integer(kind=I4P) | inout |  | Token counter. |
| `value` | integer(kind=I4P) | out |  | Integer. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  line_option["line_option"] --> next_integer["next_integer"]
  plot_command["plot_command"] --> next_integer["next_integer"]
  set_command["set_command"] --> next_integer["next_integer"]
  next_integer["next_integer"] --> fail["fail"]
  next_integer["next_integer"] --> next_word["next_word"]
  style next_integer fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### next_real

Advance `i` to the next token, which must be a number.

**Returns**: `logical`

```fortran
function next_real(tokens, i, value, iostat, iomsg) result(ok)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `tokens` | type([token_object](/api/src/lib/foresight_tokens#token-object)) | in |  | Tokens. |
| `i` | integer(kind=I4P) | inout |  | Token counter. |
| `value` | real(kind=R8P) | out |  | Number. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  line_option["line_option"] --> next_real["next_real"]
  next_real["next_real"] --> fail["fail"]
  next_real["next_real"] --> next_word["next_word"]
  next_real["next_real"] --> to_number["to_number"]
  style next_real fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### next_word

Advance `i` to the next token, which must be a bare word.

**Returns**: `logical`

```fortran
function next_word(tokens, i, word, iostat, iomsg) result(ok)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `tokens` | type([token_object](/api/src/lib/foresight_tokens#token-object)) | in |  | Tokens. |
| `i` | integer(kind=I4P) | inout |  | Token counter. |
| `word` | character(len=:) | out | allocatable | Token text. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  next_integer["next_integer"] --> next_word["next_word"]
  next_real["next_real"] --> next_word["next_word"]
  plot_command["plot_command"] --> next_word["next_word"]
  next_word["next_word"] --> fail["fail"]
  style next_word fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### no_more

Error if tokens exist from position `from` on (unsupported sub-options).

**Returns**: `logical`

```fortran
function no_more(tokens, from, iostat, iomsg) result(ok)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `tokens` | type([token_object](/api/src/lib/foresight_tokens#token-object)) | in |  | Tokens. |
| `from` | integer(kind=I4P) | in |  | First position that must be empty. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  set_command["set_command"] --> no_more["no_more"]
  unset_command["unset_command"] --> no_more["no_more"]
  no_more["no_more"] --> fail["fail"]
  style no_more fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### columnhead_title

Parse `columnhead`, `columnheader` or `columnhead(N)` (gnuplot `title columnhead`): `column` is N, or 0 for the
 column of the y field; false if `word` is none of them.

**Returns**: `logical`

```fortran
function columnhead_title(word, column) result(ok)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `word` | character(len=*) | in |  | Title word. |
| `column` | integer(kind=I4P) | out |  | Header column, 0 for the y one. |

**Call graph**

```mermaid
flowchart TD
  plot_command["plot_command"] --> columnhead_title["columnhead_title"]
  columnhead_title["columnhead_title"] --> keyword["keyword"]
  style columnhead_title fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### function_drawable

Whether the style `with` draws a function: lines, points or linespoints, not error bars.

**Attributes**: pure

**Returns**: `logical`

```fortran
function function_drawable(with) result(yes)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `with` | character(len=*) | in |  | Full style name. |

**Call graph**

```mermaid
flowchart TD
  plot_command["plot_command"] --> function_drawable["function_drawable"]
  style function_drawable fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### is_item_option

Whether `word` is a plot item option: it ends a function expression.

**Attributes**: pure

**Returns**: `logical`

```fortran
function is_item_option(word) result(is)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `word` | character(len=*) | in |  | Word. |

**Call graph**

```mermaid
flowchart TD
  plot_command["plot_command"] --> is_item_option["is_item_option"]
  is_item_option["is_item_option"] --> is_line_option["is_line_option"]
  is_item_option["is_item_option"] --> keyword["keyword"]
  style is_item_option fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### is_line_option

Whether `word` names a line property: `lc`, `lt`, `lw`, `dt`, `ps`, `pt` or their long forms.

**Attributes**: pure

**Returns**: `logical`

```fortran
function is_line_option(word) result(is)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `word` | character(len=*) | in |  | Option word. |

**Call graph**

```mermaid
flowchart TD
  is_item_option["is_item_option"] --> is_line_option["is_line_option"]
  plot_command["plot_command"] --> is_line_option["is_line_option"]
  is_line_option["is_line_option"] --> keyword["keyword"]
  style is_line_option fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### line_option

Parse the line property at `tokens(i)` and its value into `line`, leaving `i` on the value's last token:
 `lc [rgb] "color"`, `lc N`, `lt N` (palette color N), `lw W`, `dt N`, `ps S`, `pt N`.

**Returns**: `logical`

```fortran
function line_option(tokens, i, line, iostat, iomsg) result(ok)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `tokens` | type([token_object](/api/src/lib/foresight_tokens#token-object)) | in |  | Tokens. |
| `i` | integer(kind=I4P) | inout |  | Token counter. |
| `line` | type([line_style_object](/api/src/lib/foresight_script#line-style-object)) | inout |  | Line properties. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  plot_command["plot_command"] --> line_option["line_option"]
  line_option["line_option"] --> default_color["default_color"]
  line_option["line_option"] --> fail["fail"]
  line_option["line_option"] --> int_str["int_str"]
  line_option["line_option"] --> keyword["keyword"]
  line_option["line_option"] --> next_integer["next_integer"]
  line_option["line_option"] --> next_real["next_real"]
  style line_option fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### plain_columns

`using` fields of plain columns.

**Attributes**: pure

**Returns**: type([expression_object](/api/src/lib/foresight_expression#expression-object))

```fortran
function plain_columns(columns) result(fields)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `columns` | integer(kind=I4P) | in |  | Columns. |

**Call graph**

```mermaid
flowchart TD
  plot_command["plot_command"] --> plain_columns["plain_columns"]
  plain_columns["plain_columns"] --> set_column["set_column"]
  style plain_columns fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### string_argument

Optional single quoted string after an option; absent means empty.

**Returns**: `logical`

```fortran
function string_argument(tokens, text, iostat, iomsg) result(ok)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `tokens` | type([token_object](/api/src/lib/foresight_tokens#token-object)) | in |  | Option tokens. |
| `text` | character(len=:) | out | allocatable | String. |
| `iostat` | integer(kind=I4P) | out |  | 0 on success. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  set_command["set_command"] --> string_argument["string_argument"]
  string_argument["string_argument"] --> fail["fail"]
  style string_argument fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### valid_axes

Whether `names` concatenates supported axis names: x, y, y2.

**Attributes**: pure

**Returns**: `logical`

```fortran
function valid_axes(names) result(ok)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `names` | character(len=*) | in |  | Axis names. |

**Call graph**

```mermaid
flowchart TD
  axes_argument["axes_argument"] --> valid_axes["valid_axes"]
  valid_axes["valid_axes"] --> axes_names["axes_names"]
  style valid_axes fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### to_number

Parse a number; false if malformed or beyond the real range.

**Returns**: `logical`

```fortran
function to_number(word, value) result(ok)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `word` | character(len=*) | in |  | Text. |
| `value` | real(kind=R8P) | out |  | Number. |

**Call graph**

```mermaid
flowchart TD
  next_real["next_real"] --> to_number["to_number"]
  to_number["to_number"] --> real_from_decimal["real_from_decimal"]
  style to_number fill:#3e63dd,stroke:#99b,stroke-width:2px
```
