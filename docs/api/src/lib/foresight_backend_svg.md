---
title: foresight_backend_svg
---

# foresight_backend_svg

> foresight_backend_svg, SVG output device.

 The document is streamed to `<file>.tmp` and renamed over `<file>` when the page ends, so a viewer polling `<file>`
 never reads a partial document. The plot area is a nested `<svg class="fs-plot">` whose `viewBox` is the unit square:
 data geometry lives in unit coordinates, and `vector-effect="non-scaling-stroke"` keeps its line widths in pixels.
 Panels are `<g class="fs-axes">` carrying their geometry and axis ranges as `data-*` attributes; decorations the
 interactive viewer regenerates are `<g class="fs-...">` groups.

**Source**: `src/lib/foresight_backend_svg.F90`

**Dependencies**

```mermaid
graph LR
  foresight_backend_svg["foresight_backend_svg"] --> foresight_backend["foresight_backend"]
  foresight_backend_svg["foresight_backend_svg"] --> foresight_format["foresight_format"]
  foresight_backend_svg["foresight_backend_svg"] --> foresight_sys["foresight_sys"]
```

## Contents

- [backend_svg](#backend-svg)
- [begin_page](#begin-page)
- [end_page](#end-page)
- [begin_axes](#begin-axes)
- [end_axes](#end-axes)
- [begin_group](#begin-group)
- [end_group](#end-group)
- [rect](#rect)
- [polyline](#polyline)
- [dots](#dots)
- [text](#text)
- [begin_plot_area](#begin-plot-area)
- [end_plot_area](#end-plot-area)
- [data_polyline](#data-polyline)
- [data_dots](#data-dots)
- [data_bars](#data-bars)
- [close_file](#close-file)
- [open_file](#open-file)
- [open_svg](#open-svg)
- [put](#put)
- [write_pairs](#write-pairs)
- [text_width](#text-width)
- [output_unit](#output-unit)
- [dash_attribute](#dash-attribute)
- [flag](#flag)
- [px](#px)

## Variables

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `PX_DECIMALS` | integer(kind=I4P) | parameter | Decimals of pixel coordinates. |
| `UNIT_DECIMALS` | integer(kind=I4P) | parameter | Decimals of unit-square coordinates. |
| `PAIRS_PER_LINE` | integer(kind=I4P) | parameter | Coordinate pairs per output line. |
| `FONT_FAMILY` | character(len=*) | parameter | Default font family. |

## Derived Types

### backend_svg

SVG output device.

**Inheritance**

```mermaid
classDiagram
  backend_object <|-- backend_svg
  backend_svg <|-- backend_html
```

**Extends**: [`backend_object`](/api/src/lib/foresight_backend#backend-object)

#### Components

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `unit` | integer(kind=I4P) |  | Output unit. |
| `file` | character(len=:) | allocatable | Final output file. |
| `tmp_file` | character(len=:) | allocatable | File being written. |
| `area` | real(kind=R8P) |  | Current plot area: left, top, width, height [px]. |
| `caps` | character(len=:) | allocatable | Error bar caps of the current plot area, pixel overlay. |

#### Type-Bound Procedures

| Name | Attributes | Description |
|------|------------|-------------|
| `begin_page` | pass(self) |  |
| `end_page` | pass(self) |  |
| `begin_axes` | pass(self) |  |
| `end_axes` | pass(self) |  |
| `begin_group` | pass(self) |  |
| `end_group` | pass(self) |  |
| `rect` | pass(self) |  |
| `polyline` | pass(self) |  |
| `dots` | pass(self) |  |
| `text` | pass(self) |  |
| `begin_plot_area` | pass(self) |  |
| `end_plot_area` | pass(self) |  |
| `data_polyline` | pass(self) |  |
| `data_dots` | pass(self) |  |
| `data_bars` | pass(self) |  |
| `text_width` | pass(self) |  |
| `close_file` | pass(self) | Close the stream and publish the file atomically. |
| `open_file` | pass(self) | Open the stream on `.tmp`. |
| `open_svg` | pass(self) | Write the root `` start tag. |
| `output_unit` | pass(self) | Unit of the open stream. |
| `put` | pass(self) | Write a line. |
| `write_pairs` | pass(self) | Write coordinate pairs. |

## Subroutines

### begin_page

Open the output `file` with a page of `width` x `height` px and the default `font_size` [px].

```fortran
subroutine begin_page(self, file, width, height, font_size)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `file` | character(len=*) | in |  | Output file. |
| `width` | real(kind=R8P) | in |  | Page width [px]. |
| `height` | real(kind=R8P) | in |  | Page height [px]. |
| `font_size` | real(kind=R8P) | in |  | Default font size [px]. |

**Call graph**

```mermaid
flowchart TD
  render["render"] --> begin_page["begin_page"]
  begin_page["begin_page"] --> open_file["open_file"]
  begin_page["begin_page"] --> open_svg["open_svg"]
  begin_page["begin_page"] --> put["put"]
  style begin_page fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### end_page

Close the document and publish it atomically.

```fortran
subroutine end_page(self)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |

**Call graph**

```mermaid
flowchart TD
  render["render"] --> end_page["end_page"]
  end_page["end_page"] --> close_file["close_file"]
  end_page["end_page"] --> put["put"]
  style end_page fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### begin_axes

Open a panel group carrying geometry and axis ranges as `data-*` attributes.

```fortran
subroutine begin_axes(self, view)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `view` | type([axes_view](/api/src/lib/foresight_backend#axes-view)) | in |  | Panel geometry and axis ranges. |

**Call graph**

```mermaid
flowchart TD
  render["render"] --> begin_axes["begin_axes"]
  begin_axes["begin_axes"] --> attribute["attribute"]
  begin_axes["begin_axes"] --> flag["flag"]
  begin_axes["begin_axes"] --> put["put"]
  begin_axes["begin_axes"] --> px["px"]
  begin_axes["begin_axes"] --> real_str["real_str"]
  style begin_axes fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### end_axes

Close the panel group.

```fortran
subroutine end_axes(self)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |

**Call graph**

```mermaid
flowchart TD
  render["render"] --> end_axes["end_axes"]
  end_axes["end_axes"] --> put["put"]
  style end_axes fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### begin_group

Open the group of class `name`; hidden with `display="none"` when `visible` is false.

```fortran
subroutine begin_group(self, name, visible)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `name` | character(len=*) | in |  | Group name. |
| `visible` | logical | in | optional | Group shown. |

**Call graph**

```mermaid
flowchart TD
  draw_frame["draw_frame"] --> begin_group["begin_group"]
  render["render"] --> begin_group["begin_group"]
  begin_group["begin_group"] --> put["put"]
  style begin_group fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### end_group

Close the group.

```fortran
subroutine end_group(self)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |

**Call graph**

```mermaid
flowchart TD
  draw_frame["draw_frame"] --> end_group["end_group"]
  render["render"] --> end_group["end_group"]
  end_group["end_group"] --> put["put"]
  style end_group fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### rect

Rectangle of top-left corner (`x`, `y`) [px].

```fortran
subroutine rect(self, x, y, width, height, stroke, fill, line_width)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `x` | real(kind=R8P) | in |  | Left side [px]. |
| `y` | real(kind=R8P) | in |  | Top side [px]. |
| `width` | real(kind=R8P) | in |  | Width [px]. |
| `height` | real(kind=R8P) | in |  | Height [px]. |
| `stroke` | character(len=*) | in |  | Stroke color. |
| `fill` | character(len=*) | in |  | Fill color. |
| `line_width` | real(kind=R8P) | in |  | Stroke width [px]. |

**Call graph**

```mermaid
flowchart TD
  draw_frame["draw_frame"] --> rect["rect"]
  draw_key["draw_key"] --> rect["rect"]
  render["render"] --> rect["rect"]
  rect["rect"] --> put["put"]
  rect["rect"] --> px["px"]
  style rect fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### polyline

Open polyline through the points (`x`, `y`) [px].

```fortran
subroutine polyline(self, x, y, color, line_width, dasharray)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `x` | real(kind=R8P) | in |  | Abscissae [px]. |
| `y` | real(kind=R8P) | in |  | Ordinates [px]. |
| `color` | character(len=*) | in |  | Stroke color. |
| `line_width` | real(kind=R8P) | in |  | Stroke width [px]. |
| `dasharray` | character(len=*) | in |  | SVG dash array, empty for solid. |

**Call graph**

```mermaid
flowchart TD
  draw_frame["draw_frame"] --> polyline["polyline"]
  draw_grid["draw_grid"] --> polyline["polyline"]
  draw_key["draw_key"] --> polyline["polyline"]
  polyline["polyline"] --> dash_attribute["dash_attribute"]
  polyline["polyline"] --> put["put"]
  polyline["polyline"] --> px["px"]
  polyline["polyline"] --> write_pairs["write_pairs"]
  style polyline fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### dots

Filled round dots centred on the points (`x`, `y`) [px].

```fortran
subroutine dots(self, x, y, color, diameter)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `x` | real(kind=R8P) | in |  | Abscissae [px]. |
| `y` | real(kind=R8P) | in |  | Ordinates [px]. |
| `color` | character(len=*) | in |  | Fill color. |
| `diameter` | real(kind=R8P) | in |  | Dot diameter [px]. |

**Call graph**

```mermaid
flowchart TD
  draw_key["draw_key"] --> dots["dots"]
  dots["dots"] --> put["put"]
  dots["dots"] --> px["px"]
  dots["dots"] --> write_pairs["write_pairs"]
  style dots fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### text

Text whose baseline passes through the anchor point (`x`, `y`) [px].

```fortran
subroutine text(self, x, y, string, anchor, sup, rotate)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `x` | real(kind=R8P) | in |  | Anchor abscissa [px]. |
| `y` | real(kind=R8P) | in |  | Anchor ordinate (baseline) [px]. |
| `string` | character(len=*) | in |  | Text. |
| `anchor` | character(len=*) | in |  | Horizontal anchor: `start`, `middle` or `end`. |
| `sup` | character(len=*) | in | optional | Superscript appended to `string`. |
| `rotate` | real(kind=R8P) | in | optional | Rotation about the anchor point [deg, clockwise]. |

**Call graph**

```mermaid
flowchart TD
  draw_frame["draw_frame"] --> text["text"]
  draw_key["draw_key"] --> text["text"]
  render["render"] --> text["text"]
  text["text"] --> put["put"]
  text["text"] --> px["px"]
  text["text"] --> xml_escape["xml_escape"]
  style text fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### begin_plot_area

Open the clipped plot area; its user space is the unit square, y upward.

```fortran
subroutine begin_plot_area(self, x, y, width, height)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `x` | real(kind=R8P) | in |  | Left side [px]. |
| `y` | real(kind=R8P) | in |  | Top side [px]. |
| `width` | real(kind=R8P) | in |  | Width [px]. |
| `height` | real(kind=R8P) | in |  | Height [px]. |

**Call graph**

```mermaid
flowchart TD
  render["render"] --> begin_plot_area["begin_plot_area"]
  begin_plot_area["begin_plot_area"] --> put["put"]
  begin_plot_area["begin_plot_area"] --> px["px"]
  style begin_plot_area fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### end_plot_area

Close the plot area, then write the error bar caps overlay (pixel space, clipped to the plot area): caps keep
 their pixel length under zoom, the interactive viewer regenerates them from the bars.

```fortran
subroutine end_plot_area(self)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |

**Call graph**

```mermaid
flowchart TD
  render["render"] --> end_plot_area["end_plot_area"]
  end_plot_area["end_plot_area"] --> put["put"]
  end_plot_area["end_plot_area"] --> px["px"]
  style end_plot_area fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### data_polyline

Open polyline through the points (`x`, `y`) [unit square].

```fortran
subroutine data_polyline(self, x, y, color, line_width, dasharray)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `x` | real(kind=R8P) | in |  | Abscissae [unit]. |
| `y` | real(kind=R8P) | in |  | Ordinates [unit]. |
| `color` | character(len=*) | in |  | Stroke color. |
| `line_width` | real(kind=R8P) | in |  | Stroke width [px]. |
| `dasharray` | character(len=*) | in |  | SVG dash array, empty for solid. |

**Call graph**

```mermaid
flowchart TD
  draw_series["draw_series"] --> data_polyline["data_polyline"]
  data_polyline["data_polyline"] --> dash_attribute["dash_attribute"]
  data_polyline["data_polyline"] --> put["put"]
  data_polyline["data_polyline"] --> px["px"]
  data_polyline["data_polyline"] --> write_pairs["write_pairs"]
  style data_polyline fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### data_dots

Filled round dots centred on the points (`x`, `y`) [unit square].

```fortran
subroutine data_dots(self, x, y, color, diameter)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `x` | real(kind=R8P) | in |  | Abscissae [unit]. |
| `y` | real(kind=R8P) | in |  | Ordinates [unit]. |
| `color` | character(len=*) | in |  | Fill color. |
| `diameter` | real(kind=R8P) | in |  | Dot diameter [px]. |

**Call graph**

```mermaid
flowchart TD
  draw_series["draw_series"] --> data_dots["data_dots"]
  data_dots["data_dots"] --> put["put"]
  data_dots["data_dots"] --> px["px"]
  data_dots["data_dots"] --> write_pairs["write_pairs"]
  style data_dots fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### data_bars

Error bars [unit square] as one path of `Mx1,y1Lx2,y2` segments, classed `fs-ybars`/`fs-xbars` with the cap length
 in `data-cap`; caps are queued for the pixel overlay written by `end_plot_area`.

```fortran
subroutine data_bars(self, x1, y1, x2, y2, color, line_width, cap, vertical)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `x1` | real(kind=R8P) | in |  | Bar start abscissae. |
| `y1` | real(kind=R8P) | in |  | Bar start ordinates. |
| `x2` | real(kind=R8P) | in |  | Bar end abscissae. |
| `y2` | real(kind=R8P) | in |  | Bar end ordinates. |
| `color` | character(len=*) | in |  | Stroke color. |
| `line_width` | real(kind=R8P) | in |  | Stroke width [px]. |
| `cap` | real(kind=R8P) | in |  | Cap length [px]. |
| `vertical` | logical | in |  | Vertical bars (horizontal caps), else horizontal. |

**Call graph**

```mermaid
flowchart TD
  data_bars["data_bars"] --> fixed["fixed"]
  data_bars["data_bars"] --> put["put"]
  data_bars["data_bars"] --> px["px"]
  style data_bars fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### close_file

Close the stream and rename `<file>.tmp` over `<file>`.

```fortran
subroutine close_file(self)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |

**Call graph**

```mermaid
flowchart TD
  end_page["end_page"] --> close_file["close_file"]
  end_page["end_page"] --> close_file["close_file"]
  close_file["close_file"] --> rename_file["rename_file"]
  style close_file fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### open_file

Open the output stream on `<file>.tmp`.

```fortran
subroutine open_file(self, file)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `file` | character(len=*) | in |  | Output file. |

**Call graph**

```mermaid
flowchart TD
  begin_page["begin_page"] --> open_file["open_file"]
  begin_page["begin_page"] --> open_file["open_file"]
  style open_file fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### open_svg

Write the root `<svg>` start tag, with optional extra `attributes` (a leading space included).

```fortran
subroutine open_svg(self, width, height, font_size, attributes)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `width` | real(kind=R8P) | in |  | Page width [px]. |
| `height` | real(kind=R8P) | in |  | Page height [px]. |
| `font_size` | real(kind=R8P) | in |  | Default font size [px]. |
| `attributes` | character(len=*) | in | optional | Extra attributes. |

**Call graph**

```mermaid
flowchart TD
  begin_page["begin_page"] --> open_svg["open_svg"]
  begin_page["begin_page"] --> open_svg["open_svg"]
  open_svg["open_svg"] --> put["put"]
  open_svg["open_svg"] --> px["px"]
  style open_svg fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### put

Write a complete line.

```fortran
subroutine put(self, line)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `line` | character(len=*) | in |  | Line. |

**Call graph**

```mermaid
flowchart TD
  begin_axes["begin_axes"] --> put["put"]
  begin_group["begin_group"] --> put["put"]
  begin_page["begin_page"] --> put["put"]
  begin_page["begin_page"] --> put["put"]
  begin_plot_area["begin_plot_area"] --> put["put"]
  data_bars["data_bars"] --> put["put"]
  data_dots["data_dots"] --> put["put"]
  data_dots["data_dots"] --> put["put"]
  data_polyline["data_polyline"] --> put["put"]
  dots["dots"] --> put["put"]
  dots["dots"] --> put["put"]
  end_axes["end_axes"] --> put["put"]
  end_group["end_group"] --> put["put"]
  end_page["end_page"] --> put["put"]
  end_page["end_page"] --> put["put"]
  end_plot_area["end_plot_area"] --> put["put"]
  open_svg["open_svg"] --> put["put"]
  polyline["polyline"] --> put["put"]
  polyline["polyline"] --> put["put"]
  rect["rect"] --> put["put"]
  rect["rect"] --> put["put"]
  segment["segment"] --> put["put"]
  text["text"] --> put["put"]
  text["text"] --> put["put"]
  style put fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### write_pairs

Write `prefix x,y suffix` for each point, space separated, `PAIRS_PER_LINE` per line, without final newline.

```fortran
subroutine write_pairs(self, x, y, ndec, prefix, suffix)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | inout |  | Device. |
| `x` | real(kind=R8P) | in |  | Abscissae. |
| `y` | real(kind=R8P) | in |  | Ordinates. |
| `ndec` | integer(kind=I4P) | in |  | Decimals. |
| `prefix` | character(len=*) | in |  | Text before each pair. |
| `suffix` | character(len=*) | in |  | Text after each pair. |

**Call graph**

```mermaid
flowchart TD
  data_dots["data_dots"] --> write_pairs["write_pairs"]
  data_polyline["data_polyline"] --> write_pairs["write_pairs"]
  dots["dots"] --> write_pairs["write_pairs"]
  polyline["polyline"] --> write_pairs["write_pairs"]
  write_pairs["write_pairs"] --> fixed["fixed"]
  style write_pairs fill:#3e63dd,stroke:#99b,stroke-width:2px
```

## Functions

### text_width

Estimated width of `string` with its superscript `sup` [px]: the viewer renders the glyphs, so a mean advance of
 0.55 font sizes (Arial digits: 0.556) is assumed, superscripts at 0.75 size.

**Attributes**: pure

**Returns**: `real(kind=R8P)`

```fortran
function text_width(self, string, sup, font_size) result(width)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | in |  | Device. |
| `string` | character(len=*) | in |  | Text. |
| `sup` | character(len=*) | in |  | Superscript. |
| `font_size` | real(kind=R8P) | in |  | Font size [px]. |

**Call graph**

```mermaid
flowchart TD
  draw_key["draw_key"] --> text_width["text_width"]
  place_plot_area["place_plot_area"] --> text_width["text_width"]
  ytick_labels_width["ytick_labels_width"] --> text_width["text_width"]
  style text_width fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### output_unit

Unit of the open output stream.

**Attributes**: pure

**Returns**: `integer(kind=I4P)`

```fortran
function output_unit(self) result(unit)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([backend_svg](/api/src/lib/foresight_backend_svg#backend-svg)) | in |  | Device. |

**Call graph**

```mermaid
flowchart TD
  end_page["end_page"] --> output_unit["output_unit"]
  style output_unit fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### dash_attribute

` stroke-dasharray="..."` attribute, empty for solid lines.

**Attributes**: pure

**Returns**: `character(len=:)`

```fortran
function dash_attribute(dasharray) result(attribute)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `dasharray` | character(len=*) | in |  | SVG dash array. |

**Call graph**

```mermaid
flowchart TD
  data_polyline["data_polyline"] --> dash_attribute["dash_attribute"]
  polyline["polyline"] --> dash_attribute["dash_attribute"]
  style dash_attribute fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### flag

`1` or `0`.

**Attributes**: pure

**Returns**: `character(len=:)`

```fortran
function flag(value) result(str)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `value` | logical | in |  | Flag. |

**Call graph**

```mermaid
flowchart TD
  begin_axes["begin_axes"] --> flag["flag"]
  style flag fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### px

Pixel coordinate text.

**Attributes**: pure

**Returns**: `character(len=:)`

```fortran
function px(v) result(str)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `v` | real(kind=R8P) | in |  | Value [px]. |

**Call graph**

```mermaid
flowchart TD
  begin_axes["begin_axes"] --> px["px"]
  begin_plot_area["begin_plot_area"] --> px["px"]
  data_bars["data_bars"] --> px["px"]
  data_dots["data_dots"] --> px["px"]
  data_polyline["data_polyline"] --> px["px"]
  dots["dots"] --> px["px"]
  end_plot_area["end_plot_area"] --> px["px"]
  open_svg["open_svg"] --> px["px"]
  polyline["polyline"] --> px["px"]
  rect["rect"] --> px["px"]
  text["text"] --> px["px"]
  px["px"] --> fixed["fixed"]
  style px fill:#3e63dd,stroke:#99b,stroke-width:2px
```
