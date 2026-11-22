!< foresight_axes, a plot panel: the axes, the plotted series, the key and the decorations.
module foresight_axes
!< foresight_axes, a plot panel: the axes, the plotted series, the key and the decorations.
!<
!< Layout follows gnuplot defaults: full border with inward ticks mirrored on the opposite side, tick labels outside
!< bottom and left, key inside the plot area (top right by default) with right-aligned titles and the samples on their
!< right. A key `outside` lies in a side margin (left, right) or, centred, above or below the plot; `below` and `above`
!< lay its entries out in rows (`horizontal`), as many per row as the panel width holds.
!<
!< A second y axis (gnuplot `y2`) scales the series plotted on it (`axes x1y2`) on its own, autoscaled from them alone;
!< as gnuplot, its ticks and labels are off until `set y2tics` (on the right border, not mirrored), and it is drawn only
!< when it has data or a fully fixed range. A second x axis (gnuplot `x2`, `axes x2y1|x2y2`) likewise, on the top border;
!< as gnuplot, `set x2tics` alone draws it over the range of the first x axis when no series is plotted on it.
!< Text extents are measured by the output device (estimated for vector formats, whose viewer renders the glyphs).
!<
!< Boxes stand on y = 0 (`boxes`) and fills reach their baseline (`filledcurves y=V`): the box edges and the baselines
!< are stored as the bar ends `xlow`/`xhigh` and `ylow`, so they widen the autoscale as error bars do. Unlike gnuplot,
!< which leaves zero out of the y autoscale of boxes and the auto-width edges out of the x one, bars are drawn whole
!< and with lengths proportional to their values.
!<
!< Histograms (`with histograms`) lay out their bars from all the histogram series of the panel, as gnuplot: rows at
!< their abscissae (the point numbers 0, 1, ... from a script), `clustered` the k series side by side in slots
!< 1/(k + gap) wide centred on the row, `rowstacked` one stack per row, 1 wide, positive values up from 0 and negative
!< ones down from 0, `columnstacked` one stack per series (its rows stacked, each in its linetype color, the row names
!< in the key), `errorbars` clustered with an error bar on each bar; `boxwidth` scales each bar. Groups (gnuplot
!< `newhistogram`) follow one another, 2 rows apart (or from `at`), their titles below the x axis. The layout is redone
!< at every histogram added, the original values kept in `values`, the rows in `rows`; the x autoscale reaches one unit
!< beyond the first and last rows, as gnuplot. Unlike gnuplot, clustered bars reach 0 in the y autoscale, as boxes.
!<
!< Text labels of the abscissae (`xtic(N)`) of every series replace the x ticks (see foresight_axis).
!<
!< Circles (`with circles`, gnuplot) have their radius in x units (2% of the plot width by default) and are drawn round
!< on the page; with two angles [deg, counterclockwise from the x direction] they are wedges. A pie (`with pie`, a
!< foresight extension) is alone in its panel, without axes: its slices proportional to the values, from 12 o'clock
!< clockwise, each in its linetype color, a key entry per slice with its percentage; `donut` leaves a hole.
!<
!< Images (`with image`) color a regular grid of values by the panel palette (foresight_palette) over the color axis
!< `cbaxis`, autoscaled to the values or set (`cbrange`), its ends never extended to ticks; the x and y axes of a panel
!< with an image fit its pixel edges, unextended, as gnuplot. The color box lies at the right of the plot area. A theme
!< other than classic replaces the default palette with its own (dark glass to emissive colors for `vfd`).
!<
!< A polar panel (`polar`, gnuplot `set polar`) keeps its series as theta:r and projects them at each rendering about
!< the pole at r = rmin (the r axis start), x and y autoscaling to the disc of the largest radius; the frame stays
!< rectangular unless set otherwise (`border`, `border_polar`, `ratio`, the x and y ticks off), as gnuplot. Its polar
!< grid, border and r axis line are data geometry (zoomed by a viewer); the r tick labels and theta labels (`ttics`)
!< are page geometry, in the group `fs-polar`.
!<
!< Readouts (`with readout`, see foresight_readout) show the last finite value of their series in seven-segment
!< digits. They take no part in autoscale, the key or the plot area: they form a block of readouts, in a column or a
!< row, placed inside the plot area as the key is (top left by default) over a window hiding the curves below. A panel
!< of readouts alone has no axes: its block grows to fill the panel, unless a digit size is set.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite, ieee_quiet_nan, ieee_value
use foresight_annotations, only : arrow_object, draw_note_arrows => draw_arrows, draw_notes => draw_labels, draw_shapes, &
                                  label_object, shape_object
use foresight_axis, only : axis_object
use foresight_enhanced, only : has_markup, markup_literal
use foresight_format, only : int_str, real_str
use foresight_backend, only : axes_view, backend_object
use foresight_palette, only : hex_color, palette_object, palette_words
use foresight_readout, only : DEFAULT_READOUT_FORMAT, last_finite, readout_check, readout_glass
use foresight_series, only : push, series_object
use foresight_style, only : default_color, fill_style, FILL_EMPTY, FILL_PATTERN, FILL_SOLID, style_object, style_with, WITH_BOXES, &
                            WITH_CIRCLES, WITH_DOTS, WITH_FILLEDCURVES, WITH_FSTEPS, WITH_GAUGE, WITH_HISTEPS, &
                            WITH_HISTOGRAMS, WITH_IMAGE, WITH_IMPULSES, WITH_LINES, WITH_LINESPOINTS, WITH_PIE, &
                            WITH_POINTS, WITH_RADAR, WITH_READOUT, WITH_ROSE, WITH_STEPS, WITH_BOXERRORBARS, &
                            WITH_BOXXYERROR, WITH_CANDLESTICKS, WITH_FINANCEBARS, WITH_BOXPLOT, WITH_VECTORS, &
                            WITH_ARROWS, WITH_ELLIPSES, WITH_POLYGONS, WITH_LABELS, WITH_SECTORS, &
                            WITH_PARALLELAXES, WITH_SPIDERPLOT
use foresight_ticks, only : labels_attribute, linear_ticks, MINOR_DEFAULT, push, tick_object, tics_object, TICS_FIXED, &
                           TICS_NONE
use penf, only : I4P, I8P, R8P

implicit none
private
public :: axes_object
public :: colorbox_object
public :: axes_names
public :: boxplot_style
public :: paxis_object
public :: boxplot_words
public :: curve_words
public :: head_words
public :: spider_words
public :: label_words
public :: key_position
public :: polar_series
public :: readout_position
public :: POLAR_STYLES
public :: push

interface push
   !< Append an item through a temporary: nvfortran 26.9 corrupts `list = [list, item]` (and any `list = f(list)`)
   !< when the items hold deferred-length characters.
   module procedure push_axes
endinterface push

real(R8P),        parameter :: PAD           = 10.0_R8P  !< Outer padding [px].
real(R8P),        parameter :: TICK_MAJOR    = 6.0_R8P   !< Major tick length [px].
real(R8P),        parameter :: TICK_MINOR    = 3.0_R8P   !< Minor tick length [px].
real(R8P),        parameter :: GAP           = 6.0_R8P   !< Gap between border, tick labels and axis labels [px].
real(R8P),        parameter :: LINE_HEIGHT   = 1.25_R8P  !< Text line height [font size].
integer(I4P),     parameter :: HIST_CLUSTERED     = 0_I4P !< Histograms side by side in each row.
integer(I4P),     parameter :: HIST_ROWSTACKED    = 1_I4P !< Histograms stacked by row.
integer(I4P),     parameter :: HIST_COLUMNSTACKED = 2_I4P !< One stack per histogram, its rows stacked.
integer(I4P),     parameter :: HIST_ERRORBARS     = 3_I4P !< Clustered, with error bars.
real(R8P),        parameter :: SAMPLE_LENGTH = 3.0_R8P   !< Key sample length [font size].
real(R8P),        parameter :: CHAR_WIDTH    = 0.6_R8P   !< Character width [font size], gnuplot's character units.
real(R8P),        parameter :: CAP_LENGTH    = 6.0_R8P   !< Error bar cap length [px].
character(len=*), parameter :: FRAME_COLOR   = 'black'   !< Border and tick color.
character(len=*), parameter :: GRID_COLOR    = '#a0a0a0' !< Grid line color.
character(len=*), parameter :: GRID_DASHES   = '2,3'     !< Grid line dash array.
character(len=*), parameter :: WINDOW_FILL   = 'white'   !< Readout window fill: the page background.
real(R8P),        parameter :: DIGIT_HEIGHT  = 2.5_R8P   !< Default readout digit height [font size].
real(R8P),        parameter :: COLORBOX_SIZE = 1.5_R8P   !< Color box width [font size].
character(len=*), parameter :: POLAR_STYLES  = 'a polar panel takes lines, points, linespoints, closed filledcurves, '// &
                                               'sectors and readouts, on the first axes' !< Styles of a polar panel.
integer(I4P),     parameter :: CIRCLE_SIDES  = 180_I4P   !< Sides of the polygon drawing a circle.
real(R8P),        parameter :: PI_R8         = 4.0_R8P * atan(1.0_R8P) !< pi.

type :: paxis_object
   !< A parallel axis (gnuplot `set paxis N`) of parallel axis plots and spider plots.
   type(axis_object)             :: axis  !< Range and ticks: autoscaled to the values without extension, no ticks.
   character(len=:), allocatable :: label !< Label of a spider plot axis, the item title if unallocated.
endtype paxis_object

type :: boxplot_style
   !< Layout of the boxplots, gnuplot `set style boxplot`.
   real(R8P)        :: range       = 1.5_R8P  !< Whiskers to the farthest point within `range` interquartile ranges.
   real(R8P)        :: fraction    = 0.0_R8P  !< If > 0, whiskers spanning this fraction of the points instead.
   logical          :: outliers    = .true.   !< Draw the points beyond the whiskers.
   integer(I4P)     :: pointtype   = 7_I4P    !< Point type of the outliers.
   logical          :: financebars = .false.  !< Drawn as finance bars, else as candlesticks.
   real(R8P)        :: median_width = -1.0_R8P !< Median line width [px]; negative: the box line width, 0: none.
   real(R8P)        :: separation  = 1.0_R8P  !< Distance between the boxplots of the factor levels.
   character(len=4) :: labels      = 'auto'   !< Factor names as x tick labels: `auto` (or `x`), `off`.
   logical          :: sorted      = .false.  !< Factor levels in sorted order, else in order of appearance.
endtype boxplot_style

type :: colorbox_object
   !< Color box settings, gnuplot `set colorbox`.
   logical   :: horizontal = .false.                  !< Gradient left to right, else bottom to top.
   logical   :: user       = .false.                  !< In the `origin`/`size` box, else at the default place.
   logical   :: border     = .true.                   !< Frame drawn.
   logical   :: invert     = .false.                  !< A vertical box with low values at the top.
   real(R8P) :: origin(2)  = [0.9_R8P, 0.2_R8P]       !< User box bottom left, canvas fractions from the bottom left.
   real(R8P) :: size(2)    = [0.05_R8P, 0.6_R8P]      !< User box width and height, canvas fractions.
endtype colorbox_object

type :: axes_object
   !< Plot panel.
   type(axis_object)                :: xaxis          !< Horizontal axis.
   type(axis_object)                :: yaxis          !< Vertical axis.
   type(axis_object)                :: y2axis         !< Second vertical axis, on the right: no ticks until set
                                                      !< (gnuplot), see `set_defaults`.
   logical                          :: y2_active = .false. !< The second y axis is drawn, set by `setup_axes`.
   type(axis_object)                :: x2axis         !< Second horizontal axis, on the top: no ticks until set
                                                      !< (gnuplot), see `set_defaults`.
   logical                          :: x2_active = .false. !< The second x axis is drawn, set by `setup_axes`.
   type(series_object), allocatable :: series(:)      !< Plotted series.
   character(len=:), allocatable    :: title          !< Panel title, empty for none.
   logical                          :: grid = .false. !< Draw grid lines at the major ticks.
   logical                          :: key  = .true.  !< Draw the key.
   character(len=6)                 :: key_h = 'right' !< Key horizontal position: left, center, right.
   character(len=6)                 :: key_v = 'top'   !< Key vertical position: top, center, bottom.
   logical                          :: key_box = .false. !< Draw a box around the key.
   logical                          :: key_reverse = .false. !< Samples left of the titles (gnuplot `reverse`).
   logical                          :: key_plain = .false. !< The key's texts as they are, not enhanced (`noenhanced`).
   logical                          :: title_plain = .false. !< The title as it is, not enhanced (`noenhanced`).
   logical                          :: label_plain(4) = .false. !< The x, y, y2, x2 labels as they are (`noenhanced`).
   logical                          :: key_left = .false. !< Titles left-justified (gnuplot `Left`), else right.
   logical                          :: key_invert = .false. !< Entries in reverse order (gnuplot `invert`).
   logical                          :: key_opaque = .false. !< The key area painted over the plot (`opaque`).
   real(R8P)                        :: key_samplen = -1.0_R8P !< Sample length [character widths], negative for
                                                               !< foresight's (3 font sizes).
   real(R8P)                        :: key_extra = 0.0_R8P !< Width added to the titles [character widths], `width`.
   real(R8P)                        :: key_offset(2) = 0.0_R8P !< Key shift [characters], gnuplot `offset`.
   real(R8P)                        :: key_spacing = 1.0_R8P !< Row spacing [rows], gnuplot `spacing`.
   real(R8P)                        :: point_scale = 1.0_R8P !< Point size of the series without their own, gnuplot
                                                             !< `set pointsize`.
   real(R8P)                        :: key_height = 0.0_R8P !< Height added to the key [characters], `height`.
   integer(I4P)                     :: key_maxrows = 0_I4P !< Most rows of a vertical key (more: columns), 0 for one
                                                             !< column (gnuplot `maxrows`).
   integer(I4P)                     :: key_maxcols = 0_I4P !< Most columns of a horizontal key, 0 for as many as fit
                                                             !< (gnuplot `maxcols`).
   character(len=24)                :: key_tc = '' !< Title color: blank the frame's, `variable` each series' (`textcolor`).
   character(len=24)                :: key_box_lc = '' !< Box line color, the frame's if blank (`box lc`).
   real(R8P)                        :: key_box_lw = 1.0_R8P !< Box line width [px] (`box lw`).
   integer(I4P)                     :: key_box_dt = 1_I4P !< Box dash type (`box dt`), 1 solid.
   character(len=:), allocatable    :: key_title !< Key title, a row above the entries (gnuplot `set key title`).
   real(R8P)                        :: title_offset(2) = 0.0_R8P !< Title shift [characters], `set title offset`.
   real(R8P)                        :: margin_user(4) = -1.0_R8P !< Left, right, top, bottom margins set (gnuplot
                                                                  !< `set lmargin`...): characters, or a page fraction
                                                                  !< with `margin_screen`; negative: computed.
   logical                          :: margin_screen(4) = .false. !< The margin is `at screen F`: the border there.
   logical                          :: key_outside = .false. !< Key outside the plot area (gnuplot `outside`).
   character(len=6)                 :: key_margin = ''  !< `top` or `bottom` margin (gnuplot `above`, `below`), else
                                                        !< empty.
   logical                          :: key_horizontal = .false. !< Entries side by side, in rows.
   logical                          :: key_at = .false. !< Key placed at `key_xy` (gnuplot `set key at`).
   real(R8P)                        :: key_xy(2) = 0.0_R8P !< Key position, in `key_system` coordinates.
   character(len=6)                 :: key_system(2) = 'first' !< Coordinate systems of `key_xy`: `first`,
                                                               !< `second`, `graph`, `screen`.
   real(R8P)                        :: origin(2) = [0.0_R8P, 0.0_R8P] !< Bottom left corner, page fraction (`set origin`).
   real(R8P)                        :: size(2)   = [1.0_R8P, 1.0_R8P] !< Width, height, page fraction (`set size`).
   type(style_object)               :: fill_default     !< Fill of the filled styles, `set style fill` (its fill
                                                        !< components only).
   real(R8P)                        :: boxwidth = 0.0_R8P !< Box width, `set boxwidth`; 0 for auto (boxes touching).
   logical                          :: boxwidth_relative = .false. !< `boxwidth` scales the auto width.
   logical                          :: histogram_rowstacked = .false. !< Histograms stacked by row, else clustered.
   real(R8P)                        :: histogram_gap = 2.0_R8P !< Gap between clusters [bar slots].
   integer(I4P)                     :: histogram_mode = HIST_CLUSTERED !< Layout of the histograms: HIST_CLUSTERED,
                                                        !< HIST_ROWSTACKED, HIST_COLUMNSTACKED, HIST_ERRORBARS.
   real(R8P)                        :: histogram_lw = 0.0_R8P !< Error bar width of `errorbars` [px], 0: the series'.
   real(R8P)                        :: errorbar_size = 1.0_R8P !< Error bar and whisker cap length, in CAP_LENGTH
                                                               !< units (gnuplot `set errorbars SIZE`, 0 `small`).
   character(len=:), allocatable    :: hist_title_color  !< Color of the histogram group titles (`set style histogram
                                                         !< title tc`), the frame's if unallocated.
   real(R8P)                        :: hist_title_offset(2) = 0.0_R8P !< Their offset [characters, y upward].
   character(len=:), allocatable    :: errorbar_color    !< Error bar color (`set errorbars lc`), the series' if
                                                         !< unallocated.
   real(R8P)                        :: errorbar_lw = 0.0_R8P !< Error bar width [px] (`set errorbars lw`), 0: the
                                                             !< series'.
   integer(I4P)                     :: hist_group = 0_I4P   !< Group of the histograms plotted next (`newhistogram`).
   logical                          :: hist_at_set = .false. !< The next group starts at `hist_at`.
   real(R8P)                        :: hist_at = 0.0_R8P    !< Start of the next group.
   character(len=:), allocatable    :: hist_title           !< Title of the next group.
   integer(I4P)                     :: color_shift = 0_I4P  !< Shift of the default linetype colors of the next
                                                            !< series (gnuplot `newhistogram lt N`).
   type(palette_object)             :: palette          !< Palette of the images, `set palette`.
   character(len=7), allocatable    :: linecolors(:)    !< Linetype colors, `set colorsequence`; unallocated: gnuplot's.
   type(axis_object)                :: cbaxis         !< Color axis of the images, `set cbrange`; tight, see
                                                      !< `set_defaults`.
   logical                          :: colorbox = .true. !< Draw the color box of the images.
   type(colorbox_object)            :: cbox              !< Color box placement and look, `set colorbox`.
   real(R8P)                        :: canvas(2) = 0.0_R8P !< Page width and height being rendered [px].
   type(label_object), allocatable  :: notes(:)   !< Labels, gnuplot `set label`.
   type(arrow_object), allocatable  :: arrows(:)  !< Arrows, gnuplot `set arrow`.
   type(shape_object), allocatable  :: objects(:) !< Objects, gnuplot `set object`.
   real(R8P)                        :: x2_rise = 0.0_R8P   !< Height of the rotated x2 tick labels above their gap [px],
                                                           !< 0 if not rotated (set by `render` from the text widths).
   logical                          :: readout = .true. !< Draw the readouts.
   character(len=6)                 :: readout_h = 'left' !< Readout block horizontal position: left, center, right.
   character(len=6)                 :: readout_v = 'top'  !< Readout block vertical position: top, center, bottom.
   logical                          :: readout_horizontal = .false. !< Readouts side by side, else in a column.
   logical                          :: readout_opaque = .true. !< Window behind the readouts over a plot.
   real(R8P)                        :: readout_size = 0.0_R8P !< Digit height [px]; 0 for the default, which fills
                                                              !< a panel of readouts alone.
   logical                          :: polar = .false.   !< Polar coordinates (`set polar`): the series are theta:r.
   logical                          :: degrees = .false. !< Angles in degrees (`set angles degrees`), else radians.
   real(R8P)                        :: theta_origin = 0.0_R8P !< Direction of theta = 0 (`set theta`) [deg,
                                                              !< counterclockwise from the right].
   logical                          :: theta_clockwise = .false. !< Theta grows clockwise.
   type(axis_object)                :: raxis             !< Radial axis: `rrange`, `rtics`.
   logical                          :: raxis_on = .true. !< Draw the radial axis (`set|unset raxis`).
   type(axis_object)                :: taxis             !< Angle range of the plotted functions, `trange`.
   type(tics_object)                :: ttics          !< Theta labels around the polar plot; none until set, see
                                                      !< `set_defaults`.
   real(R8P)                        :: grid_polar = 0.0_R8P !< Spoke step of the polar grid [deg]; 0: rectangular grid.
   integer(I4P)                     :: border = 31_I4P   !< Border sides (gnuplot mask): 1 bottom, 2 left, 4 top, 8
                                                         !< right.
   logical                          :: border_polar = .false. !< Circle at the largest r (`set border polar`).
   real(R8P)                        :: ratio = 0.0_R8P   !< Plot area height over width (`set size ratio`, `square` is
                                                         !< 1); 0 for none.
   type(boxplot_style)              :: boxplot           !< Layout of the boxplots, `set style boxplot`.
   type(paxis_object), allocatable  :: paxes(:)          !< Parallel axes p1, p2, ... (`set paxis`), as many as set.
   logical                          :: spiderplot = .false. !< Spider plot coordinates (`set spiderplot`).
   type(style_object)               :: spider_style      !< Polygons of the spider plots (`set style spiderplot`).
   logical                          :: grid_spider = .false. !< Web of the spider plot (`set grid spiderplot`).
   logical                          :: grid_lines(6) = .false. !< Grid lines at the x, y, x2, y2 major ticks and the x, y
                                                               !< minor ticks (gnuplot `set grid x y x2 y2 mx my`);
                                                               !< none: x and y.
   logical                          :: grid_front = .false. !< Grid over the data (gnuplot `set grid front`).
   character(len=:), allocatable    :: border_lc !< Border line color, unallocated for the theme's frame color.
   real(R8P)                        :: border_lw = 1.0_R8P !< Border line width [px].
   integer(I4P)                     :: border_dt = 1_I4P   !< Border dash type, 1 solid.
   logical                          :: zero_axes(4) = .false. !< Lines at y = 0, x = 0, y2 = 0, x2 = 0 (gnuplot
                                                              !< `set xzeroaxis`, `yzeroaxis`, `x2zeroaxis`, `y2zeroaxis`).
   character(len=:), allocatable    :: zero_lc !< Zero axes line color, unallocated for the frame color.
   real(R8P)                        :: zero_lw = 1.0_R8P !< Zero axes line width [px].
   integer(I4P)                     :: zero_dt = 3_I4P   !< Zero axes dash type, gnuplot's dots (lt 0) by default.
   character(len=:), allocatable    :: grid_lc  !< Grid line color, unallocated for the theme's.
   real(R8P)                        :: grid_lw = 0.5_R8P !< Grid line width [px].
   integer(I4P)                     :: grid_dt = 0_I4P   !< Grid dash type, 0 for foresight's dots.
   contains
      procedure, pass(self) :: add_series                  !< Add a data series.
      procedure, pass(self) :: data_extent                 !< Extent of the placeable data.
      procedure, pass(self) :: series_extent               !< Extent of a series on its axes.
      procedure, pass(self) :: axes_extent                 !< Extent of the placeable data, per axis.
      procedure, pass(self) :: x2_room                     !< Room of the second x axis above the plot.
      procedure, pass(self) :: render                      !< Render the panel.
      procedure, pass(self) :: set_defaults                !< Settings of a new panel beyond its components' defaults.
      procedure, pass(self), private :: xlabels_extent !< Extent of the rotated x tick labels.
      procedure, pass(self), private :: group_rows     !< Lines of the histogram group titles.
      procedure, pass(self), private :: stacked_column !< Whether a series is a column stack.
      procedure, pass(self), private :: stack_names    !< The column stack naming the key rows.
      procedure, pass(self), private :: draw_group_titles !< Draw the histogram group titles.
      procedure, pass(self), private :: draw_frame         !< Draw border, ticks, labels and title.
      procedure, pass(self), private :: draw_grid          !< Draw the grid.
      procedure, pass(self), private :: draw_polar_axes    !< Draw the radial axis and the theta labels.
      procedure, pass(self), private :: draw_polar_grid    !< Draw the polar grid.
      procedure, pass(self), private :: page_angle         !< Page angle of a theta.
      procedure, pass(self), private :: draw_key           !< Draw the key.
      procedure, pass(self), private :: draw_readouts      !< Draw the readouts.
      procedure, pass(self), private :: key_layout         !< Key size and entry grid.
      procedure, pass(self), private :: key_sample         !< Key sample length.
      procedure, pass(self), private :: grid_dash_array        !< Grid dash array.
      procedure, pass(self), private :: draw_zero_axes     !< Draw the zero axes.
      procedure, pass(self), private :: key_place          !< Where the key lies.
      procedure, pass(self), private :: draw_series        !< Draw a series.
      procedure, pass(self), private :: has_title          !< Whether the panel has a title.
      procedure, pass(self), private :: is_readout         !< Whether a series is a readout.
      procedure, pass(self), private :: has_image          !< Whether the panel has an image.
      procedure, pass(self), private :: draw_colorbox      !< Draw the color box.
      procedure, pass(self), private :: draw_pie           !< Draw a pie panel.
      procedure, pass(self), private :: draw_gauges        !< Draw a panel of gauges.
      procedure, pass(self), private :: draw_radar         !< Draw a radar panel.
      procedure, pass(self), private :: draw_rose          !< Draw a rose panel.
      procedure, pass(self), private :: draw_parallel      !< Draw a parallel axis panel.
      procedure, pass(self), private :: draw_spider        !< Draw a spider plot panel.
      procedure, pass(self), private :: parallel_axis      !< A parallel axis set up for its values.
      procedure, pass(self), private :: colorbox_width     !< Room of the color box [px].
      procedure, pass(self), private :: colorbox_height    !< Room of a horizontal color box below the plot [px].
      procedure, pass(self), private :: place_plot_area    !< Plot area from the margins.
      procedure, pass(self), private :: setup_axes         !< Effective ranges and ticks.
endtype axes_object

contains
   pure function tick_length(tics, major) result(length)
   !< Length of a major or minor tick of an axis [px]: the major length times the axis' scale (gnuplot `set tics scale`).
   type(tics_object), intent(in) :: tics   !< Axis tick settings.
   logical,           intent(in) :: major  !< A major tick.
   real(R8P)                     :: length !< Length.

   length = TICK_MAJOR * merge(tics%scale(1), tics%scale(2), major)
   endfunction tick_length

   pure function out_shift(tics) result(shift)
   !< Room outward ticks take beyond the border [px], 0 for inward ones.
   type(tics_object), intent(in) :: tics  !< Axis tick settings.
   real(R8P)                     :: shift !< Room.

   shift = merge(tick_length(tics, .true.), 0.0_R8P, tics%out)
   endfunction out_shift

   subroutine add_series(self, x, y, title, with, lc, lw, dt, ps, xlow, xhigh, ylow, yhigh, axes, pt, format, width, &
                         base, fs, xlabels, z, radius, angles, donut, scale, linear, close, whiskerbars, factors, dx, dy, &
                         length, angle, major, minor, labels, label, head, origins, curve, channels, at, colors, &
                         palette_z, palette_cb, palette_frac)
   !< Add the series (`x`, `y`) with gnuplot-like style options; unset options take gnuplot defaults.
   !<
   !< The color from the palette, as gnuplot `lc palette`: `palette_z` maps a value per point over the color axis (`z`,
   !< lines, points, linespoints and impulses; a segment takes the color of its end point, a point of undefined value
   !< is not drawn, nor the segment to it, but counts for the autoscale, as gnuplot), `palette_cb` one color axis value,
   !< `palette_frac` one fraction of the palette (0 to 1) for the whole
   !< series. The color axis then spans the `palette_z` values too, and the color box is drawn.
   !<
   !< Error bar styles need their bounds: `ylow`/`yhigh` for `yerrorbars`, `xlow`/`xhigh` for `xerrorbars`, all four for
   !< `xyerrorbars`. `axes` is gnuplot's `x1y1` (default), `x1y2`, `x2y1` or `x2y2`: `x2` the second x axis, `y2` the
   !< second y axis. A `readout` takes its `format`
   !< (`DEFAULT_READOUT_FORMAT` if absent) and only the color among the style options.
   !<
   !< `boxes` take the box widths `width` (NaN for the default), else the panel `boxwidth`, else touching boxes;
   !< `filledcurves` fill to the line y = `base`, between `ylow` and `y`, or the closed polygon of the points. `fs`
   !< (gnuplot fill style words, `'solid 0.5 noborder'`) overrides the panel fill of either; `histograms` take the fill
   !< too. `xlabels` are text labels of the abscissae (blank for none), replacing the x ticks.
   !<
   !< `boxerrorbars` are boxes (as `boxes`) with the y error bars `ylow`/`yhigh`; `boxxyerror` rectangles from `xlow` to
   !< `xhigh`, `ylow` to `yhigh`; `candlesticks` and `financebars` take `y` the opening (or box start), `ylow` the low,
   !< `yhigh` the high and `close` the closing (or box end) values, candlesticks a `width` (else `boxwidth`, else a few
   !< pixels) and `whiskerbars`. A `boxplot` takes the values `y` at the position `x(1)`, one box per level of `factors`
   !< if given (`separation` apart, named on the x axis), its width `width(1)` (else `boxwidth`, else 0.5); the
   !< statistics are computed here, with the panel `boxplot` style.
   !<
   !< `vectors` go from each point by `dx`, `dy`; `arrows` by `length` and `angle`; both with `head` words. `ellipses`
   !< take `major` (both diameters if alone), `minor` and `angle` (the default 5% x 3% of the plot without diameters);
   !< `polygons` close each NaN-separated run of points; `labels` write `labels` with the `label` options; `sectors`
   !< are the annular sectors from azimuth `x` and radius `y` by `angle` and `width`, about `origins`.
   class(axes_object), intent(inout)        :: self   !< Panel.
   real(R8P),          intent(in)           :: x(:)   !< Abscissae.
   real(R8P),          intent(in)           :: y(:)   !< Ordinates.
   character(len=*),   intent(in), optional :: title  !< Key title, empty or absent for none.
   character(len=*),   intent(in), optional :: with   !< Plotting style: `lines` (default), `points`, `linespoints`.
   character(len=*),   intent(in), optional :: lc     !< Line color (SVG color); default from the linetype colors.
   real(R8P),          intent(in), optional :: lw     !< Line width [px].
   integer(I4P),       intent(in), optional :: dt     !< Dash type, 1..5.
   real(R8P),          intent(in), optional :: ps     !< Point size scale factor.
   real(R8P),          intent(in), optional :: xlow(:)  !< Horizontal error bar starts.
   real(R8P),          intent(in), optional :: xhigh(:) !< Horizontal error bar ends.
   real(R8P),          intent(in), optional :: ylow(:)  !< Vertical error bar starts.
   real(R8P),          intent(in), optional :: yhigh(:) !< Vertical error bar ends.
   character(len=*),   intent(in), optional :: axes     !< Axes of the series: `x1y1`, `x1y2`, `x2y1` or `x2y2`.
   integer(I4P),       intent(in), optional :: pt       !< gnuplot point type: 0 a dot, 1.. the shapes.
   character(len=*),   intent(in), optional :: format   !< Readout format.
   real(R8P),          intent(in), optional :: width(:) !< Box widths.
   real(R8P),          intent(in), optional :: base     !< Baseline of a fill.
   character(len=*),   intent(in), optional :: fs       !< Fill style words.
   character(len=*),   intent(in), optional :: xlabels(:) !< Text labels of the abscissae.
   real(R8P),          intent(in), optional :: z(:,:)   !< Image values (column, row): `x` and `y` are then the pixel
                                                        !< centres, evenly spaced and increasing.
   real(R8P),          intent(in), optional :: radius(:) !< Circle radii [x units], NaN for the default.
   real(R8P),          intent(in), optional :: angles(:,:) !< Wedge start and end angles (2, point) [deg].
   real(R8P),          intent(in), optional :: donut    !< Pie hole, a fraction of the radius (0 to below 1).
   real(R8P),          intent(in), optional :: scale(2) !< Gauge scale: the values at the start and end of the sweep.
   logical,            intent(in), optional :: linear   !< Rose sectors with the radius (not the area) by value.
   real(R8P),          intent(in), optional :: close(:) !< Closing prices of candlesticks and finance bars (`y` the
                                                        !< opening ones), or the box ends of a box-and-whisker plot.
   real(R8P),          intent(in), optional :: whiskerbars !< Crossbars of the candlestick whiskers, a fraction of the
                                                           !< box width.
   character(len=*),   intent(in), optional :: factors(:) !< Factor level of each value of a boxplot.
   real(R8P),          intent(in), optional :: dx(:)     !< Vector extents along x.
   real(R8P),          intent(in), optional :: dy(:)     !< Vector extents along y.
   real(R8P),          intent(in), optional :: length(:) !< Arrow lengths (> 0 x units, in (-1, 0) plot width fraction).
   real(R8P),          intent(in), optional :: angle(:)  !< Arrow or ellipse angles, sector angular extents [the angle
                                                         !< unit for sectors, else deg].
   real(R8P),          intent(in), optional :: major(:)  !< Ellipse major diameters [x units].
   real(R8P),          intent(in), optional :: minor(:)  !< Ellipse minor diameters [y units].
   character(len=*),   intent(in), optional :: labels(:) !< Texts of `labels`.
   character(len=*),   intent(in), optional :: label     !< Label options: gnuplot `with labels` words.
   character(len=*),   intent(in), optional :: head      !< Arrowhead words: `head`, `heads`, `nohead`, `backhead`,
                                                         !< `filled`, `empty`, `nofilled`.
   real(R8P),          intent(in), optional :: origins(:,:) !< Sector centres (2, point), [0, 0] if absent.
   character(len=*),   intent(in), optional :: curve     !< Filled curve options: gnuplot `closed`, `x1`, `x2`,
                                                         !< `xy=X,Y`, `above`, `below` (with `base` or a band).
   real(R8P),          intent(in), optional :: channels(:,:,:) !< RGB image colors (4, column, row), 0 to 255: red,
                                                               !< green, blue, alpha; `z` then its red ones.
   real(R8P),          intent(in), optional :: at        !< Position of a parallel axis (its number if absent).
   character(len=*),   intent(in), optional :: colors(:) !< Color of each point (gnuplot `lc variable`).
   real(R8P),          intent(in), optional :: palette_z(:) !< Palette value of each point (gnuplot `lc palette z`).
   real(R8P),          intent(in), optional :: palette_cb   !< A color axis value (gnuplot `lc palette cb`).
   real(R8P),          intent(in), optional :: palette_frac !< A fraction of the palette (gnuplot `lc palette frac`).
   type(series_object)                      :: series !< New series.
   character(len=:), allocatable            :: bad    !< Unknown fill style word.
   character(len=:), allocatable            :: message !< Readout format problem.
   integer(I4P)                             :: k       !< Series counter.

   if (present(z)) then
      call add_image
      return
   endif
   if (size(x) /= size(y)) error stop 'foresight: plot: x and y have different sizes'
   if (present(axes)) then
      if (all(axes /= ['x1y1', 'x1y2', 'x2y1', 'x2y2'])) &
         error stop 'foresight: plot: axes must be x1y1, x1y2, x2y1 or x2y2, not "'//axes//'"'
      series%x2 = axes(1:2) == 'x2'
      series%y2 = axes(3:4) == 'y2'
   endif
   if (.not. allocated(self%series)) allocate(self%series(0))
   series%x = x
   series%y = y
   series%title = ''
   if (present(title)) series%title = title
   if (present(with)) series%style%with = style_with(with)
   series%style%color = default_color(size(self%series, kind=I4P) + 1_I4P + self%color_shift, self%linecolors)
   ! gnuplot `set pointsize`: the default point size (an item's own replaces it)
   series%style%pointsize = self%point_scale
   if (present(lc)) series%style%color = lc
   if (present(lw)) series%style%linewidth = lw
   if (present(dt)) series%style%dashtype = dt
   if (present(ps)) series%style%pointsize = ps
   if (present(pt)) then
      if (pt < 0_I4P) error stop 'foresight: plot: the point type must not be negative'
      series%style%pointtype = pt
   endif
   if (series%style%with == WITH_READOUT) then
      if (present(lw) .or. present(dt) .or. present(ps) .or. present(pt) .or. present(axes)) &
         error stop 'foresight: plot: a readout takes lc only among the style options (no lw, dt, ps, pt, axes)'
      series%format = DEFAULT_READOUT_FORMAT
      if (present(format)) series%format = format
      message = readout_check(series%format)
      if (len(message) > 0) error stop 'foresight: plot: '//message
   elseif (series%style%with == WITH_GAUGE) then
      series%format = DEFAULT_READOUT_FORMAT
      if (present(format)) series%format = format
      message = readout_check(series%format)
      if (len(message) > 0) error stop 'foresight: plot: '//message
      if (.not. present(scale)) error stop 'foresight: plot: a gauge needs its scale, the values of its sweep ends'
      if (.not. (scale(2) /= scale(1))) error stop 'foresight: plot: the gauge scale ends must differ'
      series%scale = scale
   elseif (present(format)) then
      error stop 'foresight: plot: format applies to readouts and gauges only'
   endif
   ! the panel charts are alone in their panel: several gauges or radars side by side, one pie or rose
   if (size(self%series) > 0) then
      if (is_panel_chart(self%series(1)%style%with) .or. is_panel_chart(series%style%with)) then
         if (series%style%with /= self%series(1)%style%with .or. series%style%with == WITH_PIE .or. &
             series%style%with == WITH_ROSE) error stop 'foresight: plot: a pie, gauge, radar, rose, parallel axis or '// &
                                                        'spider plot is alone in its panel'
      endif
   endif
   if (series%style%fills()) then
      series%style%fill = self%fill_default%fill
      series%style%density = self%fill_default%density
      series%style%border = self%fill_default%border
      series%style%segments = self%fill_default%segments
      ! the default pattern cycles over the patterned items of the panel, as gnuplot
      series%style%pattern = self%fill_default%pattern + &
                             count([(self%series(k)%style%fill == FILL_PATTERN, k = 1_I4P, size(self%series, kind=I4P))])
      if (allocated(self%fill_default%border_color)) series%style%border_color = self%fill_default%border_color
      if (present(fs)) then
         call fill_style(fs, series%style, bad)
         if (len(bad) > 0) error stop 'foresight: plot: unsupported fill style "'//bad//'"'
      endif
      if (any(series%style%with == [WITH_PIE, WITH_GAUGE, WITH_ROSE]) .and. series%style%fill == FILL_EMPTY) then
         ! a pie, a gauge, a rose are filled, as a filled curve
         series%style%fill = FILL_SOLID
         series%style%density = 1.0_R8P
      endif
   elseif (present(fs) .or. present(width) .or. present(base)) then
      error stop 'foresight: plot: fs, width and base apply to boxes and filledcurves only'
   endif
   select case (series%style%with)
   case (WITH_BOXES)
      if (present(base) .or. present(ylow)) error stop 'foresight: plot: boxes stand on y = 0 (no base, no ylow)'
      if (present(width)) then
         if (size(width) /= size(x)) error stop 'foresight: plot: width and x have different sizes'
      endif
      call box_edges(series%xlow, series%xhigh)
      allocate(series%ylow(size(x)))
      series%ylow = 0.0_R8P
   case (WITH_CIRCLES)
      allocate(series%radius(size(x)))
      series%radius = ieee_value(1.0_R8P, ieee_quiet_nan)
      if (present(radius)) then
         if (size(radius) /= size(x)) error stop 'foresight: plot: radius and x have different sizes'
         series%radius = radius
         ! the circles widen the x autoscale, as gnuplot
         series%xlow = x - radius
         series%xhigh = x + radius
      endif
      if (present(angles)) then
         if (size(angles, 1) /= 2 .or. size(angles, 2) /= size(x)) &
            error stop 'foresight: plot: angles must be (2, size(x)): start and end of each wedge'
         series%arcs = angles
      endif
   case (WITH_PIE)
      if (size(self%series) > 0) error stop 'foresight: plot: a pie is alone in its panel'
      if (any(y < 0.0_R8P)) error stop 'foresight: plot: a pie needs non-negative values'
      series%donut = 0.0_R8P
      if (present(donut)) then
         if (donut < 0.0_R8P .or. donut >= 1.0_R8P) error stop 'foresight: plot: the donut hole is 0 to below 1'
         series%donut = donut
      endif
      series%values = y
   case (WITH_ROSE)
      if (any(y < 0.0_R8P)) error stop 'foresight: plot: a rose needs non-negative values'
      series%values = y
      if (present(linear)) series%linear = linear
   case (WITH_IMPULSES)
      ! from y = 0, which the y autoscale includes, as gnuplot
      allocate(series%ylow(size(x)))
      series%ylow = 0.0_R8P
   case (WITH_HISTEPS)
      ! steps around the points from y = 0: their edges and 0 widen the autoscale, as the boxes ones
      call histep_edges(series%xlow, series%xhigh)
      allocate(series%ylow(size(x)))
      series%ylow = 0.0_R8P
   case (WITH_DOTS)
      series%style%pointtype = 0_I4P
   case (WITH_BOXERRORBARS)
      if (.not. (present(ylow) .and. present(yhigh))) &
         error stop 'foresight: plot: boxerrorbars need ylow and yhigh, the error bar ends'
      if (size(ylow) /= size(x) .or. size(yhigh) /= size(x)) error stop 'foresight: plot: ylow/yhigh sizes differ from x'
      if (present(width)) then
         if (size(width) /= size(x)) error stop 'foresight: plot: width and x have different sizes'
      endif
      allocate(series%bounds(2, size(x)))
      series%bounds(1, :) = ylow
      series%bounds(2, :) = yhigh
      call box_edges(series%xlow, series%xhigh)
      allocate(series%ylow(size(x)))
      series%ylow = 0.0_R8P
   case (WITH_BOXXYERROR)
      if (.not. (present(xlow) .and. present(xhigh) .and. present(ylow) .and. present(yhigh))) &
         error stop 'foresight: plot: boxxyerror needs xlow, xhigh, ylow and yhigh'
      if (size(xlow) /= size(x) .or. size(xhigh) /= size(x) .or. size(ylow) /= size(x) .or. size(yhigh) /= size(x)) &
         error stop 'foresight: plot: xlow/xhigh/ylow/yhigh sizes differ from x'
      series%xlow = xlow
      series%xhigh = xhigh
      series%ylow = ylow
      series%yhigh = yhigh
   case (WITH_CANDLESTICKS, WITH_FINANCEBARS)
      if (.not. (present(ylow) .and. present(yhigh) .and. present(close))) &
         error stop 'foresight: plot: candlesticks and financebars need ylow (low), yhigh (high) and close'
      if (size(ylow) /= size(x) .or. size(yhigh) /= size(x) .or. size(close) /= size(x)) &
         error stop 'foresight: plot: ylow/yhigh/close sizes differ from x'
      allocate(series%bounds(2, size(x)))
      series%bounds(1, :) = y
      series%bounds(2, :) = close
      series%ylow = ylow
      series%yhigh = yhigh
      if (series%style%with == WITH_CANDLESTICKS) then
         if (present(width)) then
            if (size(width) /= size(x)) error stop 'foresight: plot: width and x have different sizes'
         endif
         ! a set width widens the x autoscale, the default one (pixels) does not, as gnuplot
         if (present(width) .or. self%boxwidth > 0.0_R8P) call box_edges(series%xlow, series%xhigh)
         if (present(whiskerbars)) then
            if (whiskerbars < 0.0_R8P) error stop 'foresight: plot: whiskerbars must not be negative'
            series%whiskerbars = whiskerbars
         endif
      endif
   case (WITH_BOXPLOT)
      call boxplot_stats
      if (len(bad) > 0) error stop 'foresight: plot: '//bad
   case (WITH_VECTORS)
      if (.not. (present(dx) .and. present(dy))) error stop 'foresight: plot: vectors need dx and dy'
      if (size(dx) /= size(x) .or. size(dy) /= size(x)) error stop 'foresight: plot: dx/dy sizes differ from x'
      allocate(series%tips(2, size(x)))
      series%tips(1, :) = x + dx
      series%tips(2, :) = y + dy
   case (WITH_ARROWS)
      if (.not. (present(length) .and. present(angle))) error stop 'foresight: plot: arrows need length and angle'
      if (size(length) /= size(x) .or. size(angle) /= size(x)) error stop 'foresight: plot: length/angle sizes differ from x'
      allocate(series%tips(2, size(x)))
      series%tips(1, :) = length
      series%tips(2, :) = angle
   case (WITH_ELLIPSES)
      call ellipse_shapes
      if (len(bad) > 0) error stop 'foresight: plot: '//bad
   case (WITH_LABELS)
      if (.not. present(labels)) error stop 'foresight: plot: labels need their texts'
      if (size(labels) /= size(x)) error stop 'foresight: plot: labels and x have different sizes'
      series%texts = labels
      if (present(label)) then
         call label_words(label, series, bad)
         if (len(bad) > 0) error stop 'foresight: plot: label: '//bad
      endif
   case (WITH_SECTORS)
      call sector_vertices
      if (len(bad) > 0) error stop 'foresight: plot: '//bad
   case (WITH_PARALLELAXES, WITH_SPIDERPLOT)
      ! an axis of the values of a column; the row names (spider plot key) as labels
      if (present(labels)) then
         if (size(labels) /= size(x)) error stop 'foresight: plot: labels and x have different sizes'
         series%texts = labels
      endif
      if (present(at)) then
         if (series%style%with /= WITH_PARALLELAXES) error stop 'foresight: plot: at applies to parallelaxes only'
         series%at = at
         series%at_set = .true.
      endif
   case (WITH_HISTOGRAMS)
      if (present(base) .or. present(width)) &
         error stop 'foresight: plot: histograms take no base nor width (set_boxwidth scales the bars)'
      if (present(ylow) .neqv. present(yhigh)) error stop 'foresight: plot: histogram error bars need ylow and yhigh'
      if (present(ylow) .and. self%histogram_mode /= HIST_ERRORBARS) &
         error stop 'foresight: plot: histogram error bars (ylow, yhigh) need set_style_histogram("errorbars")'
      if (present(ylow)) then
         if (size(ylow) /= size(y) .or. size(yhigh) /= size(y)) error stop 'foresight: plot: ylow/yhigh sizes differ from y'
         allocate(series%bounds(2, size(x)))
         series%bounds(1, :) = ylow
         series%bounds(2, :) = yhigh
      endif
      series%values = y
      series%hist_group = self%hist_group
      series%hist_at_set = self%hist_at_set
      series%hist_at = self%hist_at
      series%hist_title = ''
      if (allocated(self%hist_title)) series%hist_title = self%hist_title
      if (self%histogram_mode == HIST_COLUMNSTACKED .and. present(labels)) then
         ! the row names of a column stack (gnuplot `key(N)`): its key entries
         if (size(labels) /= size(x)) error stop 'foresight: plot: labels and x have different sizes'
         series%texts = labels
      endif
   case (WITH_FILLEDCURVES)
      ! gnuplot fills a curve even with an empty fill style, and never draws its border
      if (series%style%fill == FILL_EMPTY) series%style%density = 1.0_R8P
      if (series%style%fill /= FILL_PATTERN) series%style%fill = FILL_SOLID
      series%style%border = .false.
      if (present(base) .and. present(ylow)) error stop 'foresight: plot: a fill takes base or ylow, not both'
      if (present(base)) then
         allocate(series%ylow(size(x)))
         series%ylow = base
      endif
      if (present(curve)) then
         call curve_words(curve, series, bad)
         if (len(bad) > 0) error stop 'foresight: plot: filledcurves '//bad
         if (series%curve_to > 0_I4P .and. (present(base) .or. present(ylow))) &
            error stop 'foresight: plot: filledcurves x1, x2, xy= take no base nor ylow'
         if (series%curve_side /= 0_I4P .and. .not. (present(base) .or. present(ylow))) &
            error stop 'foresight: plot: filledcurves above and below need a line (base) or a band (ylow)'
      endif
   endselect
   if (present(curve) .and. series%style%with /= WITH_FILLEDCURVES) &
      error stop 'foresight: plot: curve applies to filledcurves only'
   if (present(head)) then
      if (.not. any(series%style%with == [WITH_VECTORS, WITH_ARROWS])) error stop 'foresight: plot: head applies to '// &
                                                                                  'vectors and arrows only'
      call head_words(head, series%head, series%head_filled, bad)
      if (len(bad) > 0) error stop 'foresight: plot: head: '//bad
   endif
   if (present(label) .and. series%style%with /= WITH_LABELS) error stop 'foresight: plot: label applies to labels only'
   if (present(at) .and. series%style%with /= WITH_PARALLELAXES) error stop 'foresight: plot: at applies to parallelaxes only'
   if (present(close) .and. .not. any(series%style%with == [WITH_CANDLESTICKS, WITH_FINANCEBARS])) &
      error stop 'foresight: plot: close applies to candlesticks and financebars only'
   if (present(factors) .and. series%style%with /= WITH_BOXPLOT) error stop 'foresight: plot: factors apply to boxplots only'
   if (series%style%draws_xbars()) then
      if (.not. (present(xlow) .and. present(xhigh))) error stop 'foresight: plot: x error bars need xlow and xhigh'
      if (size(xlow) /= size(x) .or. size(xhigh) /= size(x)) error stop 'foresight: plot: xlow/xhigh sizes differ from x'
      series%xlow = xlow
      series%xhigh = xhigh
   endif
   if (present(xlabels)) then
      if (size(xlabels) /= size(x)) error stop 'foresight: plot: xlabels and x have different sizes'
      series%xlabels = xlabels
   endif
   if (present(xlabels) .and. series%style%with == WITH_BOXPLOT) &
      error stop 'foresight: plot: a boxplot takes factors, not xlabels'
   if (present(colors)) then
      if (size(colors) /= size(x)) error stop 'foresight: plot: colors and x have different sizes'
      if (.not. any(series%style%with == [WITH_LINES, WITH_POINTS, WITH_LINESPOINTS, WITH_IMPULSES])) &
         error stop 'foresight: plot: colors (lc variable) apply to lines, points, linespoints and impulses'
      allocate(series%colors(size(colors)))
      series%colors(:) = colors
      if (size(colors) > 0) series%style%color = colors(1) ! the key line sample: the first point's color (gnuplot)
   endif
   if (count([present(palette_z), present(palette_cb), present(palette_frac), present(colors)]) > 1) &
      error stop 'foresight: plot: one of colors, palette_z, palette_cb, palette_frac'
   if (present(palette_z)) then
      if (size(palette_z) /= size(x)) error stop 'foresight: plot: palette_z and x have different sizes'
      if (.not. any(series%style%with == [WITH_LINES, WITH_POINTS, WITH_LINESPOINTS, WITH_IMPULSES])) &
         error stop 'foresight: plot: palette_z (lc palette z) applies to lines, points, linespoints and impulses'
      series%palette_mode = 1_I4P
      series%zvalues = palette_z
   elseif (present(palette_cb) .or. present(palette_frac)) then
      if (any(series%style%with == [WITH_READOUT, WITH_GAUGE, WITH_PIE, WITH_RADAR, WITH_ROSE, WITH_PARALLELAXES, &
                                    WITH_SPIDERPLOT, WITH_LABELS])) &
         error stop 'foresight: plot: palette_cb and palette_frac do not apply to readouts, panel charts and labels'
      series%palette_mode = merge(2_I4P, 3_I4P, present(palette_cb))
      if (present(palette_cb)) series%palette_value = palette_cb
      if (present(palette_frac)) series%palette_value = palette_frac
   endif
   if (series%style%with == WITH_FILLEDCURVES .and. present(ylow)) then
      if (size(ylow) /= size(y)) error stop 'foresight: plot: ylow and y have different sizes'
      series%ylow = ylow
   endif
   if (series%style%draws_ybars()) then
      if (.not. (present(ylow) .and. present(yhigh))) error stop 'foresight: plot: y error bars need ylow and yhigh'
      if (size(ylow) /= size(y) .or. size(yhigh) /= size(y)) error stop 'foresight: plot: ylow/yhigh sizes differ from y'
      series%ylow = ylow
      series%yhigh = yhigh
   endif
   if (self%polar .and. .not. polar_series(series)) error stop 'foresight: plot: '//POLAR_STYLES
   call push(self%series, series)
   if (series%style%with == WITH_HISTOGRAMS) call layout_histograms(self%series, self%histogram_mode, &
                                                                     self%histogram_gap, self%boxwidth, &
                                                                     self%linecolors)
   contains
      subroutine ellipse_shapes
      !< Ellipse diameters and angles: `major` alone for both diameters, a negative one (or none) for the default size;
      !< the extents of the sized ones widen the autoscale.
      real(R8P) :: a  !< Semi-major axis.
      real(R8P) :: b  !< Semi-minor axis.
      real(R8P) :: c  !< Angle cosine.
      real(R8P) :: sn !< Angle sine.
      integer(I4P) :: i !< Point counter.

      bad = ''
      allocate(series%shape(3, size(x)))
      series%shape = ieee_value(1.0_R8P, ieee_quiet_nan)
      series%shape(3, :) = 0.0_R8P
      if (present(angle)) then
         if (size(angle) /= size(x)) then
            bad = 'angle and x have different sizes'
            return
         endif
         series%shape(3, :) = angle
      endif
      if (present(minor) .and. .not. present(major)) then
         bad = 'ellipses take minor with major'
         return
      endif
      if (.not. present(major)) return
      if (size(major) /= size(x)) then
         bad = 'major and x have different sizes'
         return
      endif
      series%shape(1, :) = major
      series%shape(2, :) = major
      if (present(minor)) then
         if (size(minor) /= size(x)) then
            bad = 'minor and x have different sizes'
            return
         endif
         series%shape(2, :) = minor
      endif
      allocate(series%xlow(size(x)), series%xhigh(size(x)), series%ylow(size(x)), series%yhigh(size(x)))
      do i = 1_I4P, size(x, kind=I4P)
         ! a negative (or undefined) diameter: the default size, out of the autoscale
         if (.not. (ieee_is_finite(series%shape(1, i)) .and. ieee_is_finite(series%shape(2, i)) .and. &
                    ieee_is_finite(series%shape(3, i)))) then
            series%shape(1:2, i) = ieee_value(1.0_R8P, ieee_quiet_nan)
            if (.not. ieee_is_finite(series%shape(3, i))) series%shape(3, i) = 0.0_R8P
         elseif (series%shape(1, i) < 0.0_R8P .or. series%shape(2, i) < 0.0_R8P) then
            series%shape(1:2, i) = ieee_value(1.0_R8P, ieee_quiet_nan)
         endif
         if (.not. ieee_is_finite(series%shape(1, i))) then
            series%xlow(i) = series%shape(1, i)
            series%xhigh(i) = series%shape(1, i)
            series%ylow(i) = series%shape(1, i)
            series%yhigh(i) = series%shape(1, i)
            cycle
         endif
         a = 0.5_R8P * series%shape(1, i)
         b = 0.5_R8P * series%shape(2, i)
         c = cos(series%shape(3, i) * (PI_R8 / 180.0_R8P))
         sn = sin(series%shape(3, i) * (PI_R8 / 180.0_R8P))
         ! the bounding box of the rotated ellipse (NaN for the default size: not counted)
         series%xlow(i) = x(i) - sqrt((a * c)**2 + (b * sn)**2)
         series%xhigh(i) = x(i) + sqrt((a * c)**2 + (b * sn)**2)
         series%ylow(i) = y(i) - sqrt((a * sn)**2 + (b * c)**2)
         series%yhigh(i) = y(i) + sqrt((a * sn)**2 + (b * c)**2)
      enddo
      endsubroutine ellipse_shapes

      subroutine sector_vertices
      !< The outline of each sector as a run of vertices (runs separated by NaN): the arc at the outer radius from the
      !< azimuth `x` over `angle`, back along the inner radius `y`. Angles in the panel angle unit, oriented by its
      !< theta origin and direction, as gnuplot. On a polar panel the vertices are theta:r (no `origins`), else x:y.
      real(R8P), allocatable :: vx(:)  !< Vertex abscissae.
      real(R8P), allocatable :: vy(:)  !< Vertex ordinates.
      real(R8P)              :: unit   !< Angle unit [rad].
      real(R8P)              :: t      !< Vertex azimuth [angle unit].
      real(R8P)              :: r      !< Vertex radius.
      real(R8P)              :: phi    !< Vertex page angle [rad].
      real(R8P)              :: c(2)   !< Centre.
      real(R8P)              :: nan    !< Separator.
      integer(I4P)           :: m      !< Arc steps.
      integer(I4P)           :: i      !< Sector counter.
      integer(I4P)           :: k      !< Vertex counter.
      integer(I4P)           :: side   !< Outer (1) and inner (2) arc.

      bad = ''
      if (.not. (present(angle) .and. present(width))) then
         bad = 'sectors need angle (the angular extents) and width (the annular widths)'
         return
      endif
      if (size(angle) /= size(x) .or. size(width) /= size(x)) then
         bad = 'angle/width sizes differ from x'
         return
      endif
      if (present(origins)) then
         if (size(origins, 1) /= 2 .or. size(origins, 2) /= size(x)) then
            bad = 'origins must be (2, size(x))'
            return
         endif
         if (self%polar) then
            bad = 'sectors on a polar panel take no origins'
            return
         endif
      endif
      unit = merge(PI_R8 / 180.0_R8P, 1.0_R8P, self%degrees)
      nan = ieee_value(1.0_R8P, ieee_quiet_nan)
      allocate(vx(0), vy(0))
      do i = 1_I4P, size(x, kind=I4P)
         if (.not. (ieee_is_finite(x(i)) .and. ieee_is_finite(y(i)) .and. ieee_is_finite(angle(i)) .and. &
                    ieee_is_finite(width(i)))) cycle
         c = 0.0_R8P
         if (present(origins)) c = origins(:, i)
         ! an arc vertex every 5 degrees at most
         m = max(1_I4P, ceiling(abs(angle(i) * unit) / (5.0_R8P * PI_R8 / 180.0_R8P), I4P))
         do side = 1_I4P, 2_I4P
            do k = 0_I4P, m
               if (side == 1_I4P) then
                  t = x(i) + angle(i) * real(k, R8P) / real(m, R8P)
                  r = y(i) + width(i)
               else
                  t = x(i) + angle(i) * real(m - k, R8P) / real(m, R8P)
                  r = y(i)
               endif
               if (self%polar) then
                  vx = [vx, t]
                  vy = [vy, r]
               else
                  phi = (self%theta_origin * (PI_R8 / 180.0_R8P)) + merge(-1.0_R8P, 1.0_R8P, self%theta_clockwise) * &
                        t * unit
                  vx = [vx, c(1) + r * cos(phi)]
                  vy = [vy, c(2) + r * sin(phi)]
               endif
            enddo
         enddo
         vx = [vx, nan]
         vy = [vy, nan]
      enddo
      series%x = vx
      series%y = vy
      endsubroutine sector_vertices

      subroutine boxplot_stats
      !< The boxes of a boxplot from the values `y`: one per factor level (in order of appearance, or sorted), at
      !< x(1) + k * separation, each with its quartiles (`bounds`), median (`y`), whiskers (`ylow`, `yhigh`, the
      !< farthest values within the whisker range) and outliers, as gnuplot. A level of fewer than 4 values has no box.
      character(len=:), allocatable :: names(:) !< Factor levels.
      character(len=:), allocatable :: found(:) !< Factor levels found, the first `nf`.
      character(len=:), allocatable :: level    !< Current level.
      real(R8P), allocatable        :: v(:)     !< Values of a level, sorted.
      real(R8P), allocatable        :: cx(:)    !< Box centres.
      real(R8P)                     :: w        !< Box width.
      real(R8P)                     :: q(3)     !< Quartiles.
      real(R8P)                     :: lo       !< Lowest whisker limit.
      real(R8P)                     :: hi       !< Highest whisker limit.
      integer(I4P)                  :: nb       !< Boxes.
      integer(I4P)                  :: nf       !< Factor levels found.
      integer(I4P), allocatable     :: boxes(:) !< Level of each box drawn.
      real(R8P), allocatable        :: grown(:,:) !< Bounds or outliers, one more.
      integer(I4P)                  :: k        !< Box counter.
      integer(I4P)                  :: i        !< Value counter.
      integer(I4P)                  :: j        !< Sort counter.
      integer(I4P)                  :: e        !< Excluded values per side (fraction mode).
      logical                       :: named    !< Factor names shown.

      bad = ''
      if (size(x) == 0) then
         bad = 'a boxplot needs values'
         return
      endif
      if (present(width)) then
         if (size(width) /= size(x)) then
            bad = 'width and x have different sizes'
            return
         endif
      endif
      ! levels
      if (present(factors)) then
         if (size(factors) /= size(x)) then
            bad = 'factors and x have different sizes'
            return
         endif
         ! collected in a separate array: nvfortran 26.9 corrupts `names = [names, factors(i)]`
         allocate(character(len=len(factors)) :: found(size(factors)))
         nf = 0_I4P
         do i = 1_I4P, size(factors, kind=I4P)
            if (len_trim(factors(i)) == 0) cycle
            if (any(found(1_I4P:nf) == factors(i))) cycle
            nf = nf + 1_I4P
            found(nf) = factors(i)
         enddo
         names = found(1_I4P:nf)
         if (self%boxplot%sorted) then
            do i = 2_I4P, size(names, kind=I4P)
               level = names(i)
               j = i - 1_I4P
               do while (j >= 1_I4P)
                  if (llt(names(j), level) .or. names(j) == level) exit
                  names(j + 1_I4P) = names(j)
                  j = j - 1_I4P
               enddo
               names(j + 1_I4P) = level
            enddo
         endif
      else
         allocate(character(len=1) :: names(1))
         names(:) = ' '
      endif
      w = 0.5_R8P
      if (self%boxwidth > 0.0_R8P .and. .not. self%boxwidth_relative) w = self%boxwidth
      if (present(width)) then
         if (ieee_is_finite(width(1)) .and. width(1) > 0.0_R8P) w = width(1)
      endif
      nb = size(names, kind=I4P)
      allocate(cx(0))
      series%x = [real(R8P) ::]
      series%y = [real(R8P) ::]
      series%xlow = [real(R8P) ::]
      series%xhigh = [real(R8P) ::]
      series%ylow = [real(R8P) ::]
      series%yhigh = [real(R8P) ::]
      allocate(series%bounds(2, 0), series%outliers(2, 0))
      named = present(factors) .and. self%boxplot%labels /= 'off'
      allocate(boxes(0))
      do k = 1_I4P, nb
         if (present(factors)) then
            v = pack(y, factors == names(k) .and. ieee_is_finite(y))
         else
            v = pack(y, ieee_is_finite(y))
         endif
         if (size(v) < 4) cycle
         call sort(v)
         q = [quantile(v, 0.25_R8P), quantile(v, 0.5_R8P), quantile(v, 0.75_R8P)]
         if (self%boxplot%fraction > 0.0_R8P) then
            e = int(real(size(v), R8P) * (1.0_R8P - self%boxplot%fraction) * 0.5_R8P, I4P)
            lo = v(1 + e)
            hi = v(size(v) - e)
         else
            lo = q(1) - self%boxplot%range * (q(3) - q(1))
            hi = q(3) + self%boxplot%range * (q(3) - q(1))
            ! the whiskers end at data values
            lo = minval(v, mask=v >= lo)
            hi = maxval(v, mask=v <= hi)
         endif
         cx = [cx, x(1) + real(k - 1_I4P, R8P) * self%boxplot%separation]
         series%x = [series%x, cx(size(cx))]
         series%y = [series%y, q(2)]
         ! the x autoscale reaches a box width beyond the box edges, as gnuplot; the box is the middle third
         series%xlow = [series%xlow, cx(size(cx)) - 1.5_R8P * w]
         series%xhigh = [series%xhigh, cx(size(cx)) + 1.5_R8P * w]
         series%ylow = [series%ylow, lo]
         series%yhigh = [series%yhigh, hi]
         ! grown into `grown`: nvfortran 26.9 -O2 zeroes `a = reshape([a, ...], ...)`
         grown = reshape([series%bounds, q(1), q(3)], [2, size(cx)])
         call move_alloc(grown, series%bounds)
         boxes = [boxes, k]
         if (self%boxplot%outliers) then
            do i = 1_I4P, size(v, kind=I4P)
               if (v(i) < lo .or. v(i) > hi) then
                  grown = reshape([series%outliers, cx(size(cx)), v(i)], [2, size(series%outliers, 2) + 1])
                  call move_alloc(grown, series%outliers)
               endif
            enddo
         endif
      enddo
      ! the levels of the boxes drawn, at once: nvfortran 26.9 corrupts the growth of a deferred-length character array
      if (named) series%xlabels = names(boxes)
      endsubroutine boxplot_stats

      pure function quantile(v, p) result(value)
      !< Quantile `p` of the sorted values `v`, as gnuplot's boxplot: the value of rank p n, the mean of ranks p n and
      !< p n + 1 when p n is a whole number.
      real(R8P), intent(in) :: v(:)  !< Sorted values.
      real(R8P), intent(in) :: p     !< Probability.
      real(R8P)             :: value !< Quantile.
      real(R8P)             :: m     !< Rank p n.
      integer(I4P)          :: r     !< Rank.

      m = p * real(size(v), R8P)
      r = ceiling(m, I4P)
      if (abs(m - real(nint(m), R8P)) < 1.0e-9_R8P) then
         r = nint(m, I4P)
         value = 0.5_R8P * (v(r) + v(min(r + 1_I4P, size(v, kind=I4P))))
      else
         value = v(r)
      endif
      endfunction quantile

      pure subroutine sort(v)
      !< Sort `v` ascending (insertion sort: a boxplot holds few values).
      real(R8P), intent(inout) :: v(:) !< Values.
      real(R8P)                :: t    !< Swap buffer.
      integer(I4P)             :: i    !< Counter.
      integer(I4P)             :: j    !< Counter.

      do i = 2_I4P, size(v, kind=I4P)
         t = v(i)
         j = i - 1_I4P
         do while (j >= 1_I4P)
            if (v(j) <= t) exit
            v(j + 1_I4P) = v(j)
            j = j - 1_I4P
         enddo
         v(j + 1_I4P) = t
      enddo
      endsubroutine sort

      subroutine add_image
      !< The image of the values `z` at the pixel centres `x`, `y`: its pixel edges as `x` and `y` of the series.
      real(R8P) :: d(2) !< Pixel width and height.

      if (size(z, 1) /= size(x) .or. size(z, 2) /= size(y)) &
         error stop 'foresight: plot: an image needs size(z) = [size(x), size(y)]'
      if (size(x) == 0 .or. size(y) == 0) error stop 'foresight: plot: an image needs values'
      d = [spacing_of(x), spacing_of(y)]
      if (.not. allocated(self%series)) allocate(self%series(0))
      series%style%with = WITH_IMAGE
      series%x = [x(1) - 0.5_R8P * d(1), x(size(x)) + 0.5_R8P * d(1)]
      series%y = [y(1) - 0.5_R8P * d(2), y(size(y)) + 0.5_R8P * d(2)]
      series%grid = z
      if (present(channels)) then
         if (size(channels, 1) /= 4 .or. size(channels, 2) /= size(z, 1) .or. size(channels, 3) /= size(z, 2)) &
            error stop 'foresight: plot: RGB image channels must be (4, columns, rows)'
         series%channels = channels
      endif
      series%title = ''
      if (present(title)) series%title = title
      series%style%color = default_color(size(self%series, kind=I4P) + 1_I4P, self%linecolors)
      call push(self%series, series)
      endsubroutine add_image

      pure function spacing_of(c) result(step)
      !< Spacing of the evenly spaced, increasing pixel centres `c` (1 for a single one).
      real(R8P), intent(in) :: c(:) !< Pixel centres.
      real(R8P)             :: step !< Spacing.
      integer(I4P)          :: k    !< Counter.

      step = 1.0_R8P
      if (size(c) < 2) return
      step = (c(size(c)) - c(1)) / real(size(c) - 1, R8P)
      if (.not. step > 0.0_R8P) error stop 'foresight: plot: the pixel centres of an image must increase'
      do k = 2_I4P, size(c, kind=I4P)
         if (abs(c(k) - c(k - 1_I4P) - step) > 1.0e-6_R8P * step) &
            error stop 'foresight: plot: the pixel centres of an image must be evenly spaced (a regular grid)'
      enddo
      endfunction spacing_of
      pure subroutine histep_edges(left, right)
      !< Edges of the steps of `histeps`: halfway to the neighbours, the end steps symmetric (gnuplot), in data space.
      real(R8P), allocatable, intent(out) :: left(:)  !< Left edges.
      real(R8P), allocatable, intent(out) :: right(:) !< Right edges.
      integer(I4P)                        :: n        !< Points.

      n = size(x, kind=I4P)
      allocate(left(n), right(n))
      if (n == 0_I4P) return
      if (n == 1_I4P) then
         left = x - 0.5_R8P
         right = x + 0.5_R8P
         return
      endif
      left(2:n) = 0.5_R8P * (x(1:n - 1) + x(2:n))
      right(1:n - 1) = left(2:n)
      left(1) = x(1) - (left(2) - x(1))
      right(n) = x(n) + (x(n) - right(n - 1))
      endsubroutine histep_edges

      pure subroutine box_edges(left, right)
      !< Box edges: halfway to the neighbours (gnuplot's auto width, the end boxes symmetric), scaled by a relative
      !< `boxwidth`; or `boxwidth` itself; or the box's own `width`.
      real(R8P), allocatable, intent(out) :: left(:)  !< Left edges.
      real(R8P), allocatable, intent(out) :: right(:) !< Right edges.
      real(R8P)                           :: dl       !< Distance to the previous point.
      real(R8P)                           :: dr       !< Distance to the next point.
      integer(I4P)                        :: n        !< Points.
      integer(I4P)                        :: i        !< Counter.

      n = size(x, kind=I4P)
      allocate(left(n), right(n))
      do i = 1_I4P, n
         dl = huge(1.0_R8P)
         dr = huge(1.0_R8P)
         if (i > 1_I4P) then
            if (ieee_is_finite(x(i - 1_I4P)) .and. ieee_is_finite(x(i))) dl = x(i) - x(i - 1_I4P)
         endif
         if (i < n) then
            if (ieee_is_finite(x(i + 1_I4P)) .and. ieee_is_finite(x(i))) dr = x(i + 1_I4P) - x(i)
         endif
         if (dl == huge(1.0_R8P)) dl = dr
         if (dr == huge(1.0_R8P)) dr = dl
         ! a single box: unit width
         if (dl == huge(1.0_R8P)) then
            dl = 1.0_R8P
            dr = 1.0_R8P
         endif
         dl = 0.5_R8P * dl
         dr = 0.5_R8P * dr
         if (self%boxwidth > 0.0_R8P) then
            if (self%boxwidth_relative) then
               dl = self%boxwidth * dl
               dr = self%boxwidth * dr
            else
               dl = 0.5_R8P * self%boxwidth
               dr = dl
            endif
         endif
         if (present(width)) then
            if (ieee_is_finite(width(i))) then
               dl = 0.5_R8P * width(i)
               dr = dl
            endif
         endif
         left(i) = x(i) - dl
         right(i) = x(i) + dr
      enddo
      endsubroutine box_edges
   endsubroutine add_series

   pure subroutine data_extent(self, xmin, xmax, ymin, ymax, found)
   !< Extent of the series points placeable on their axes, the whole data before any range is set: x over the series on
   !< the first x axis, y per axis (1 the first, 2 the second); see `axes_extent`.
   class(axes_object), intent(in)  :: self      !< Panel.
   real(R8P),          intent(out) :: xmin      !< Smallest abscissa, first x axis.
   real(R8P),          intent(out) :: xmax      !< Largest abscissa, first x axis.
   real(R8P),          intent(out) :: ymin(2)   !< Smallest ordinate, per y axis.
   real(R8P),          intent(out) :: ymax(2)   !< Largest ordinate, per y axis.
   logical,            intent(out) :: found(2)  !< Any placeable point, per y axis.
   real(R8P)                       :: x0(2)     !< Smallest abscissa, per x axis.
   real(R8P)                       :: x1(2)     !< Largest abscissa, per x axis.
   logical                         :: xfound(2) !< Any placeable point, per x axis.

   call self%axes_extent(x0, x1, ymin, ymax, found, xfound)
   xmin = x0(1)
   xmax = x1(1)
   endsubroutine data_extent

   pure subroutine axes_extent(self, xmin, xmax, ymin, ymax, found, xfound)
   !< Extent of the series points placeable on their axes, the whole data before any range is set, per axis (1 the
   !< first, 2 the second): x over the series on each x axis, y over the series on each y axis.
   class(axes_object), intent(in)  :: self      !< Panel.
   real(R8P),          intent(out) :: xmin(2)   !< Smallest abscissa, per x axis.
   real(R8P),          intent(out) :: xmax(2)   !< Largest abscissa, per x axis.
   real(R8P),          intent(out) :: ymin(2)   !< Smallest ordinate, per y axis.
   real(R8P),          intent(out) :: ymax(2)   !< Largest ordinate, per y axis.
   logical,            intent(out) :: found(2)  !< Any placeable point, per y axis.
   logical,            intent(out) :: xfound(2) !< Any placeable point, per x axis.
   integer(I4P)                    :: s         !< Series counter.

   xmin = huge(1.0_R8P)
   xmax = -huge(1.0_R8P)
   ymin = huge(1.0_R8P)
   ymax = -huge(1.0_R8P)
   found = .false.
   xfound = .false.
   do s = 1_I4P, size(self%series, kind=I4P)
      if (self%is_readout(s)) cycle
      call self%series_extent(s, .false., xmin, xmax, ymin, ymax, found, xfound)
   enddo
   endsubroutine axes_extent

   pure subroutine series_extent(self, s, windowed, xmin, xmax, ymin, ymax, found, xfound)
   !< Widen the extent of the axes of the `s`-th series (index 1 the first axis, 2 the second) to its placeable points;
   !< `windowed`: only the points inside the range of its x axis (y autoscaling, as gnuplot).
   class(axes_object), intent(in)    :: self      !< Panel.
   integer(I4P),       intent(in)    :: s         !< Series index.
   logical,            intent(in)    :: windowed  !< Count only the points inside the x range.
   real(R8P),          intent(inout) :: xmin(2)   !< Smallest abscissa, per x axis.
   real(R8P),          intent(inout) :: xmax(2)   !< Largest abscissa, per x axis.
   real(R8P),          intent(inout) :: ymin(2)   !< Smallest ordinate, per y axis.
   real(R8P),          intent(inout) :: ymax(2)   !< Largest ordinate, per y axis.
   logical,            intent(inout) :: found(2)  !< Any placeable point, per y axis.
   logical,            intent(inout) :: xfound(2) !< Any placeable point, per x axis.
   logical                           :: hit       !< The series has a counted point.
   integer(I4P)                      :: kx        !< x axis of the series: 1 or 2.
   integer(I4P)                      :: ky        !< y axis of the series: 1 or 2.

   kx = merge(2_I4P, 1_I4P, self%series(s)%x2)
   ky = merge(2_I4P, 1_I4P, self%series(s)%y2)
   hit = .false.
   if (kx == 2_I4P) then
      if (ky == 2_I4P) then
         call widen(self%x2axis, self%y2axis, xmin(kx), xmax(kx), ymin(ky), ymax(ky), hit)
      else
         call widen(self%x2axis, self%yaxis, xmin(kx), xmax(kx), ymin(ky), ymax(ky), hit)
      endif
   elseif (ky == 2_I4P) then
      call widen(self%xaxis, self%y2axis, xmin(kx), xmax(kx), ymin(ky), ymax(ky), hit)
   else
      call widen(self%xaxis, self%yaxis, xmin(kx), xmax(kx), ymin(ky), ymax(ky), hit)
   endif
   found(ky) = found(ky) .or. hit
   xfound(kx) = xfound(kx) .or. hit
   contains
      pure subroutine widen(xaxis, yaxis, x0, x1, y0, y1, any)
      !< Widen by the series against its axes; the extent is an argument: a pure procedure defines no host-associated
      !< variable (F2018 C1594).
      type(axis_object), intent(in)    :: xaxis !< Horizontal axis.
      type(axis_object), intent(in)    :: yaxis !< Vertical axis.
      real(R8P),         intent(inout) :: x0    !< Smallest abscissa.
      real(R8P),         intent(inout) :: x1    !< Largest abscissa.
      real(R8P),         intent(inout) :: y0    !< Smallest ordinate.
      real(R8P),         intent(inout) :: y1    !< Largest ordinate.
      logical,           intent(inout) :: any   !< A counted point.

      if (windowed) then
         call self%series(s)%extent(xaxis, yaxis, x0, x1, y0, y1, any, xwindow=[xaxis%lo, xaxis%hi])
      else
         call self%series(s)%extent(xaxis, yaxis, x0, x1, y0, y1, any)
      endif
      endsubroutine widen
   endsubroutine series_extent

   pure subroutine set_defaults(self)
   !< Settings of a new panel that its components' default initialization does not give: the second y axis without
   !< ticks (nor mirror) until set, the color axis tight to the values, no theta labels until set. Set here, where a
   !< panel is made, not as component initializers: nvfortran 26.9 stops on a structure constructor of `axis_object` or
   !< `tics_object` (deferred-length character components) in a component's default initialization.
   class(axes_object), intent(inout) :: self !< Panel.

   self%y2axis%tics%mode = TICS_NONE
   self%y2axis%tics%mirror = .false.
   self%x2axis%tics%mode = TICS_NONE
   self%x2axis%tics%mirror = .false.
   self%cbaxis%tight = .true.
   self%ttics%mode = TICS_NONE
   endsubroutine set_defaults

   subroutine render(self, backend, x0, y0, width, height, font_size, canvas)
   !< Render the panel into the pixel box of top-left corner (`x0`, `y0`) and size `width` x `height`, on a page of
   !< `canvas` width and height (the box when absent), where a user color box lies.
   class(axes_object),    intent(inout) :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: x0        !< Box left side [px].
   real(R8P),             intent(in)    :: y0        !< Box top side [px].
   real(R8P),             intent(in)    :: width     !< Box width [px].
   real(R8P),             intent(in)    :: height    !< Box height [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   real(R8P),             intent(in), optional :: canvas(2) !< Page width and height [px].
   real(R8P)                            :: area(4)   !< Plot area: left, right, top, bottom [px].
   real(R8P)                            :: box(4)    !< Box left to the rest of the panel by an outside key:
                                                     !< left, top, width, height [px].
   real(R8P)                            :: key(2)    !< Key width and height [px].
   real(R8P)                            :: above     !< Room for a key above the plot [px].
   type(axes_view)                      :: view      !< Panel geometry and ranges for the device.
   type(series_object), allocatable     :: raw(:)    !< Series of a polar panel as given (theta:r), restored after
                                                     !< the drawing of their projection.
   integer(I4P)                         :: s         !< Series counter.
   integer(I4P)                         :: grid(3)   !< Key entries, columns, rows.

   self%canvas = [x0 + width, y0 + height]
   if (present(canvas)) self%canvas = canvas
   if (.not. allocated(self%series)) allocate(self%series(0))
   if (size(self%series) > 0) then
      if (is_panel_chart(self%series(1)%style%with)) then
         ! a panel chart alone: no axes, the chart and its key fill the panel below the title
         area = [x0 + PAD, x0 + width - PAD, y0 + PAD, y0 + height - PAD]
         if (self%has_title()) then
            backend%literal = self%title_plain
            call backend%text(x0 + 0.5_R8P * width, y0 + PAD + font_size, self%title, 'middle')
            backend%literal = .false.
            area(3) = area(3) + LINE_HEIGHT * font_size + GAP
         endif
         select case (self%series(1)%style%with)
         case (WITH_PIE)
            call self%draw_pie(backend, area, font_size)
         case (WITH_GAUGE)
            call self%draw_gauges(backend, area, font_size)
         case (WITH_RADAR)
            call self%draw_radar(backend, area, font_size)
         case (WITH_PARALLELAXES)
            call self%draw_parallel(backend, area, font_size)
         case (WITH_SPIDERPLOT)
            call self%draw_spider(backend, area, font_size)
         case default
            call self%draw_rose(backend, area, font_size)
         endselect
         return
      endif
      if (all([(self%is_readout(s), s = 1_I4P, size(self%series, kind=I4P))])) then
         ! readouts alone: no axes, the block fills the panel below the title
         area = [x0 + PAD, x0 + width - PAD, y0 + PAD, y0 + height - PAD]
         if (self%has_title()) then
            backend%literal = self%title_plain
            call backend%text(x0 + 0.5_R8P * width, y0 + PAD + font_size, self%title, 'middle')
            backend%literal = .false.
            area(3) = area(3) + LINE_HEIGHT * font_size + GAP
         endif
         if (self%readout) call self%draw_readouts(backend, area, font_size, .true.)
         return
      endif
   endif
   ! an outside key takes its side of the panel box; above the plot it goes below the title, as gnuplot
   box = [x0, y0, width, height]
   above = 0.0_R8P
   call self%key_layout(backend, font_size, width - 2.0_R8P * PAD, grid, key)
   if (self%key .and. grid(1) > 0_I4P) then
      select case (self%key_place())
      case ('left')
         box(1) = x0 + PAD + key(1)
         box(3) = width - PAD - key(1)
      case ('right')
         box(3) = width - PAD - key(1)
      case ('bottom')
         box(4) = height - PAD - key(2)
      case ('top')
         above = key(2) + GAP
      endselect
   endif
   if (self%polar) raw = self%series
   ! ticks depend on the plot area size, margins on the tick labels: refine a first guess twice
   associate(bx => box(1), by => box(2), bw => box(3), bh => box(4))
      area = [bx + 6.0_R8P * font_size, bx + bw - 2.0_R8P * font_size, &
              by + 2.0_R8P * font_size + above, by + bh - 4.0_R8P * font_size]
      call self%setup_axes(area, raw)
      if (backend%enhanced) call plain_ticks(self)
      self%x2_rise = x2labels_rise(self, backend, font_size)
      area = self%place_plot_area(backend, bx, by, bw, bh, font_size, above)
      call self%setup_axes(area, raw)
      if (backend%enhanced) call plain_ticks(self)
      self%x2_rise = x2labels_rise(self, backend, font_size)
      area = self%place_plot_area(backend, bx, by, bw, bh, font_size, above)
   endassociate
   ! the series colored by the palette, over the color axis just set up
   if (self%has_image(palette=.true.)) call paint_series(self%series, effective_palette(self%palette, &
                                                                                     backend%theme%name), self%cbaxis)

   view = axes_view(area=area, x=[self%xaxis%lo, self%xaxis%hi], y=[self%yaxis%lo, self%yaxis%hi], &
                    xlog=self%xaxis%log, ylog=self%yaxis%log, grid=self%grid, font_size=font_size)
   view%xtics = self%xaxis%tics%attribute(self%xaxis%lo, self%xaxis%hi)
   if (self%xaxis%labelled()) view%xtics = labels_attribute(self%xaxis%labels)
   view%ytics = self%yaxis%tics%attribute(self%yaxis%lo, self%yaxis%hi)
   ! text labels from the data (`ytic`, `x2tic`, `y2tic` as `xtic`): the viewer keeps them through a zoom
   if (self%yaxis%labelled()) view%ytics = labels_attribute(self%yaxis%labels)
   view%xformat = ''
   view%yformat = ''
   if (self%xaxis%tics%has_format()) view%xformat = self%xaxis%tics%format
   if (self%yaxis%tics%has_format()) view%yformat = self%yaxis%tics%format
   view%mirror = [self%xaxis%tics%mirror, self%yaxis%tics%mirror, self%y2axis%tics%mirror]
   view%y2_active = self%y2_active
   if (self%y2_active) then
      view%y2 = [self%y2axis%lo, self%y2axis%hi]
      view%y2log = self%y2axis%log
      view%y2tics = self%y2axis%tics%attribute(self%y2axis%lo, self%y2axis%hi)
      if (self%y2axis%labelled()) view%y2tics = labels_attribute(self%y2axis%labels)
      view%y2format = ''
      if (self%y2axis%tics%has_format()) view%y2format = self%y2axis%tics%format
   endif
   view%x2_active = self%x2_active
   if (self%x2_active) then
      view%x2 = [self%x2axis%lo, self%x2axis%hi]
      view%x2log = self%x2axis%log
      view%x2mirror = self%x2axis%tics%mirror
      view%x2tics = self%x2axis%tics%attribute(self%x2axis%lo, self%x2axis%hi)
      if (self%x2axis%labelled()) view%x2tics = labels_attribute(self%x2axis%labels)
      view%x2format = ''
      if (self%x2axis%tics%has_format()) view%x2format = self%x2axis%tics%format
   endif
   ! tick labels with markup, drawn again by the viewer as enhanced text
   view%markup = axis_markup(self%xaxis) .or. axis_markup(self%yaxis)
   if (self%y2_active) view%markup = view%markup .or. axis_markup(self%y2axis)
   if (self%x2_active) view%markup = view%markup .or. axis_markup(self%x2axis)
   ! tick labels not read as enhanced text: `noenhanced` first
   view%xtics = place_words(self%xaxis, style_words(self%xaxis%tics, plain_word(self%xaxis%tics%plain, view%xtics)))
   view%ytics = place_words(self%yaxis, style_words(self%yaxis%tics, plain_word(self%yaxis%tics%plain, view%ytics)))
   if (self%y2_active) view%y2tics = place_words(self%y2axis, style_words(self%y2axis%tics, &
                                                                         plain_word(self%y2axis%tics%plain, view%y2tics)))
   if (self%x2_active) view%x2tics = place_words(self%x2axis, style_words(self%x2axis%tics, &
                                                                         plain_word(self%x2axis%tics%plain, view%x2tics)))
   view%gridlines = grid_words(self%grid_lines)
   view%gridstyle = ''
   if (allocated(self%grid_lc) .or. self%grid_lw /= 0.5_R8P .or. self%grid_dt > 0_I4P) then
      view%gridstyle = GRID_COLOR
      if (allocated(self%grid_lc)) view%gridstyle = self%grid_lc
      view%gridstyle = view%gridstyle//' '//real_str(self%grid_lw)//' '//self%grid_dash_array()
   endif
   view%xtime = time_attribute(self%xaxis)
   view%ytime = time_attribute(self%yaxis)
   view%y2time = time_attribute(self%y2axis)
   view%x2time = time_attribute(self%x2axis)
   call backend%begin_axes(view)
   ! annotations: objects behind the grid, then the back layer (labels, arrows, objects on the page)
   call annotate('behind', .false.)
   ! grid lines always emitted, hidden when off: an interactive viewer can toggle them (over the data with front)
   if (.not. self%grid_front) then
      call backend%begin_group('fs-grid', visible=self%grid)
      call self%draw_grid(backend, area)
      call backend%end_group
   endif
   call annotate('back', .false.)
   call backend%begin_plot_area(area(1), area(3), area(2) - area(1), area(4) - area(3))
   ! the objects in data space, clipped and zoomed with the data, behind it
   call annotate('behind', .true.)
   call annotate('back', .true.)
   ! the zero axes, data geometry behind the series (gnuplot `set zeroaxis`)
   if (any(self%zero_axes)) call self%draw_zero_axes(backend)
   ! the polar grid and border are data geometry, zoomed with the series
   if (self%polar .and. self%grid_polar > 0.0_R8P) then
      call backend%begin_group('fs-pgrid', visible=self%grid)
      call self%draw_polar_grid(backend)
      call backend%end_group
   endif
   do s = 1_I4P, size(self%series, kind=I4P)
      if (self%is_readout(s)) cycle
      call backend%begin_group('fs-series', series=s)
      if (self%series(s)%x2 .and. self%series(s)%y2) then
         call self%draw_series(backend, s, self%x2axis, self%y2axis, area, font_size)
      elseif (self%series(s)%x2) then
         call self%draw_series(backend, s, self%x2axis, self%yaxis, area, font_size)
      elseif (self%series(s)%y2) then
         call self%draw_series(backend, s, self%xaxis, self%y2axis, area, font_size)
      else
         call self%draw_series(backend, s, self%xaxis, self%yaxis, area, font_size)
      endif
      call backend%end_group
   enddo
   if (self%polar) then
      associate(radius => self%raxis%hi - self%raxis%lo)
         if (self%border_polar) call backend%data_polyline(circle_u(radius), circle_v(radius), FRAME_COLOR, 1.0_R8P, '')
         ! the r axis towards the right of the page, as gnuplot
         if (self%raxis_on) call backend%data_polyline(self%xaxis%to_unit([0.0_R8P, radius]), &
                                                       self%yaxis%to_unit([0.0_R8P, 0.0_R8P]), FRAME_COLOR, 1.0_R8P, '')
      endassociate
   endif
   call annotate('front', .true.)
   call backend%end_plot_area
   if (self%grid_front) then
      call backend%begin_group('fs-grid', visible=self%grid)
      call self%draw_grid(backend, area)
      call backend%end_group
   endif
   call self%draw_frame(backend, area, box(1), box(2), box(1) + box(3), font_size)
   call annotate('front', .false.)
   if (self%polar) then
      call backend%begin_group('fs-polar')
      call self%draw_polar_axes(backend, area, font_size)
      call backend%end_group
   endif
   if (self%key .and. grid(1) > 0_I4P) call self%draw_key(backend, area, [x0, y0, x0 + width, y0 + height], font_size, &
                                                         grid, key)
   if (self%colorbox .and. self%has_image(palette=.true.)) call self%draw_colorbox(backend, area, &
                                                                                 [x0, y0, x0 + width, y0 + height], font_size)
   if (self%readout .and. any([(self%is_readout(s), s = 1_I4P, size(self%series, kind=I4P))])) &
      call self%draw_readouts(backend, area, font_size, .false.)
   call backend%end_axes
   if (self%polar) call move_alloc(raw, self%series)
   contains
      subroutine annotate(layer, data_space)
      !< The annotations of `layer`: the objects in data space (`data_space`), or the page ones with the labels and
      !< arrows of the layer (`front`, else the back one).
      character(len=*), intent(in) :: layer      !< `behind`, `back` or `front`.
      logical,          intent(in) :: data_space !< The data space objects, else the page annotations.

      if (allocated(self%objects)) call draw_shapes(self%objects, layer, data_space, backend, area, self%canvas, &
                                                    font_size, self%xaxis, self%yaxis, self%x2axis, self%y2axis)
      if (data_space .or. layer == 'behind') return
      if (allocated(self%notes)) call draw_notes(self%notes, layer == 'front', backend, area, self%canvas, font_size, &
                                                  self%xaxis, self%yaxis, self%x2axis, self%y2axis)
      if (allocated(self%arrows)) call draw_note_arrows(self%arrows, layer == 'front', backend, area, self%canvas, &
                                                   font_size, self%xaxis, self%yaxis, self%x2axis, self%y2axis)
      endsubroutine annotate
      pure function circle_u(rho) result(u)
      !< Unit abscissae of the circle of radius `rho` [r units] about the pole.
      real(R8P), intent(in)  :: rho  !< Radius.
      real(R8P), allocatable :: u(:) !< Unit abscissae.
      real(R8P), allocatable :: c(:) !< Abscissae [r units] (allocatable: nvfortran 26.9 does not allocate
                                     !< `u` for an elemental reference of constant extent, as the constructor's).
      integer(I4P)           :: k    !< Vertex counter.

      c = [(rho * cos(2.0_R8P * PI_R8 * real(k, R8P) / real(CIRCLE_SIDES, R8P)), k = 0_I4P, CIRCLE_SIDES)]
      u = self%xaxis%to_unit(c)
      endfunction circle_u

      pure function circle_v(rho) result(v)
      !< Unit ordinates of the circle of radius `rho` [r units] about the pole.
      real(R8P), intent(in)  :: rho  !< Radius.
      real(R8P), allocatable :: v(:) !< Unit ordinates.
      real(R8P), allocatable :: c(:) !< Ordinates [r units] (allocatable: nvfortran 26.9 does not allocate
                                     !< `v` for an elemental reference of constant extent, as the constructor's).
      integer(I4P)           :: k    !< Vertex counter.

      c = [(rho * sin(2.0_R8P * PI_R8 * real(k, R8P) / real(CIRCLE_SIDES, R8P)), k = 0_I4P, CIRCLE_SIDES)]
      v = self%yaxis%to_unit(c)
      endfunction circle_v
   endsubroutine render

   ! private procedures
   pure subroutine rotated_anchor(p, base, angle, font_size, x, y)
   !< Anchor of an x tick label rotated by `angle` [deg, counterclockwise] at the tick abscissa `p` [px], hanging from
   !< `base` [px]: its glyph band centred on the tick, GAP below the base as an upright label, as gnuplot places them.
   real(R8P), intent(in)  :: p         !< Tick abscissa [px].
   real(R8P), intent(in)  :: base      !< Ordinate the labels hang from [px].
   real(R8P), intent(in)  :: angle     !< Label angle [deg].
   real(R8P), intent(in)  :: font_size !< Font size [px].
   real(R8P), intent(out) :: x         !< Anchor abscissa [px].
   real(R8P), intent(out) :: y         !< Anchor ordinate [px].

   x = p + 0.35_R8P * font_size * sin(angle * PI_R8 / 180.0_R8P)
   y = base + GAP + 0.35_R8P * font_size * (1.0_R8P + cos(angle * PI_R8 / 180.0_R8P))
   endsubroutine rotated_anchor

   pure function rotated_extent(width, angle, anchor, font_size) result(extent)
   !< Extent of an x tick label `width` [px] wide rotated by `angle` [deg] with `anchor`, from its tick at the base
   !< ordinate (see `rotated_anchor`): depth below the base, then reach left and right of the tick [px]; the glyphs
   !< from 0.25 font sizes below the baseline to 0.75 above.
   real(R8P),        intent(in) :: width     !< Label width [px].
   real(R8P),        intent(in) :: angle     !< Label angle [deg].
   character(len=*), intent(in) :: anchor    !< `start`, `end` or `middle`.
   real(R8P),        intent(in) :: font_size !< Font size [px].
   real(R8P)                    :: extent(3) !< Depth, left reach, right reach [px].
   real(R8P)                    :: s(2)      !< Baseline ends from the anchor [px].
   real(R8P)                    :: t(2)      !< Glyph bottom and top from the baseline [px].
   real(R8P)                    :: c         !< Cosine of the angle.
   real(R8P)                    :: n         !< Sine of the angle.
   real(R8P)                    :: ax        !< Anchor abscissa from the tick [px].
   real(R8P)                    :: ay        !< Anchor ordinate from the base [px].
   real(R8P)                    :: x         !< Corner abscissa from the tick [px].
   real(R8P)                    :: y         !< Corner ordinate from the base [px].
   integer(I4P)                 :: i         !< Baseline end counter.
   integer(I4P)                 :: j         !< Glyph side counter.

   select case (trim(anchor))
   case ('end')
      s = [-width, 0.0_R8P]
   case ('middle')
      s = [-0.5_R8P * width, 0.5_R8P * width]
   case default
      s = [0.0_R8P, width]
   endselect
   t = [-0.25_R8P * font_size, 0.75_R8P * font_size]
   c = cos(angle * PI_R8 / 180.0_R8P)
   n = sin(angle * PI_R8 / 180.0_R8P)
   call rotated_anchor(0.0_R8P, 0.0_R8P, angle, font_size, ax, ay)
   extent = [ay, 0.0_R8P, 0.0_R8P]
   do i = 1_I4P, 2_I4P
      do j = 1_I4P, 2_I4P
         ! the text runs along (cos, -sin) on the page, its glyphs rise along (-sin, -cos)
         x = ax + s(i) * c - t(j) * n
         y = ay - s(i) * n - t(j) * c
         extent = [max(extent(1), y), max(extent(2), -x), max(extent(3), x)]
      enddo
   enddo
   endfunction rotated_extent

   pure function rotated_rise(width, angle, anchor, font_size) result(rise)
   !< Lowest and highest page ordinates [px, downward] from its anchor of a tick label `width` [px] wide rotated by
   !< `angle` [deg, counterclockwise] with `anchor` (`start`, `end`, `middle`): the glyphs from 0.25 font sizes below
   !< the baseline to 0.75 above, as `rotated_extent`.
   real(R8P),        intent(in) :: width     !< Label width [px].
   real(R8P),        intent(in) :: angle     !< Label angle [deg].
   character(len=*), intent(in) :: anchor    !< `start`, `end` or `middle`.
   real(R8P),        intent(in) :: font_size !< Font size [px].
   real(R8P)                    :: rise(2)   !< Lowest (largest) and highest (smallest) ordinate [px].
   real(R8P)                    :: s(2)      !< Baseline ends from the anchor [px].
   real(R8P)                    :: t(2)      !< Glyph bottom and top from the baseline [px].
   real(R8P)                    :: y         !< Corner ordinate [px].
   integer(I4P)                 :: i         !< Baseline end counter.
   integer(I4P)                 :: j         !< Glyph side counter.

   select case (trim(anchor))
   case ('end')
      s = [-width, 0.0_R8P]
   case ('middle')
      s = [-0.5_R8P * width, 0.5_R8P * width]
   case default
      s = [0.0_R8P, width]
   endselect
   t = [-0.25_R8P * font_size, 0.75_R8P * font_size]
   rise = [-huge(1.0_R8P), huge(1.0_R8P)]
   do i = 1_I4P, 2_I4P
      do j = 1_I4P, 2_I4P
         ! the text runs along (cos, -sin) on the page, its glyphs rise along (-sin, -cos)
         y = -s(i) * sin(angle * PI_R8 / 180.0_R8P) - t(j) * cos(angle * PI_R8 / 180.0_R8P)
         rise = [max(rise(1), y), min(rise(2), y)]
      enddo
   enddo
   endfunction rotated_rise

   pure function rotated_reach(width, angle, anchor, font_size) result(reach)
   !< Reach right of its tick [px] of an x2 tick label `width` [px] wide rotated by `angle` [deg] with `anchor`, drawn
   !< 0.35 font sizes times the sine of the angle right of the tick (see `draw_frame`).
   real(R8P),        intent(in) :: width     !< Label width [px].
   real(R8P),        intent(in) :: angle     !< Label angle [deg].
   character(len=*), intent(in) :: anchor    !< `start`, `end` or `middle`.
   real(R8P),        intent(in) :: font_size !< Font size [px].
   real(R8P)                    :: reach     !< Reach [px].
   real(R8P)                    :: s(2)      !< Baseline ends from the anchor [px].
   real(R8P)                    :: t(2)      !< Glyph bottom and top from the baseline [px].
   real(R8P)                    :: c         !< Cosine.
   real(R8P)                    :: n         !< Sine.
   integer(I4P)                 :: i         !< Counter.
   integer(I4P)                 :: j         !< Counter.

   select case (trim(anchor))
   case ('end')
      s = [-width, 0.0_R8P]
   case ('middle')
      s = [-0.5_R8P * width, 0.5_R8P * width]
   case default
      s = [0.0_R8P, width]
   endselect
   t = [-0.25_R8P * font_size, 0.75_R8P * font_size]
   c = cos(angle * PI_R8 / 180.0_R8P)
   n = sin(angle * PI_R8 / 180.0_R8P)
   reach = 0.0_R8P
   do i = 1_I4P, 2_I4P
      do j = 1_I4P, 2_I4P
         reach = max(reach, 0.35_R8P * font_size * n + s(i) * c - t(j) * n)
      enddo
   enddo
   endfunction rotated_reach

   pure function x2labels_rise(self, backend, font_size) result(height)
   !< Height [px] of the rotated x2 tick labels, the largest over the major ticks (see `rotated_rise`); 0 if they are
   !< not rotated, or the device writes text horizontally.
   class(axes_object),    intent(in) :: self      !< Panel.
   class(backend_object), intent(in) :: backend   !< Output device, for text widths.
   real(R8P),             intent(in) :: font_size !< Font size [px].
   real(R8P)                         :: height    !< Height [px].
   real(R8P)                         :: r(2)      !< Rise of a label [px].
   integer(I4P)                      :: t         !< Tick counter.

   height = 0.0_R8P
   if (.not. (self%x2_active .and. backend%rotates_text() .and. self%x2axis%tics%rotate /= 0.0_R8P)) return
   if (.not. allocated(self%x2axis%ticks)) return
   do t = 1_I4P, size(self%x2axis%ticks, kind=I4P)
      if (.not. self%x2axis%ticks(t)%major) cycle
      r = rotated_rise(backend%text_width(self%x2axis%ticks(t)%label, self%x2axis%ticks(t)%sup, font_size), &
                       self%x2axis%tics%rotate, self%x2axis%tics%anchor(), font_size)
      height = max(height, r(1) - r(2))
   enddo
   endfunction x2labels_rise

   pure function x2_room(self, font_size) result(room)
   !< Room above the top border of the second x axis [px]: its outward ticks, its tick labels row and its label.
   class(axes_object), intent(in) :: self      !< Panel.
   real(R8P),          intent(in) :: font_size !< Font size [px].
   real(R8P)                      :: room      !< Room [px].

   room = 0.0_R8P
   if (self%x2_active) then
      if (self%x2axis%tics%out .and. size(self%x2axis%ticks) > 0) room = tick_length(self%x2axis%tics, .true.)
      if (any(self%x2axis%ticks%major)) room = room + GAP + merge(self%x2_rise, LINE_HEIGHT * font_size, &
                                                                   self%x2_rise > 0.0_R8P)
   endif
   if (self%x2axis%has_label()) room = room + LINE_HEIGHT * font_size + GAP
   endfunction x2_room

   pure function stacked_column(self, s) result(yes)
   !< Whether series `s` is a column stack (columnstacked histograms): its rows, not its title, make the key.
   class(axes_object), intent(in) :: self !< Panel.
   integer(I4P),       intent(in) :: s    !< Series index.
   logical                        :: yes  !< A column stack.

   yes = self%series(s)%style%with == WITH_HISTOGRAMS .and. self%histogram_mode == HIST_COLUMNSTACKED
   endfunction stacked_column

   pure function stack_names(self) result(s)
   !< The last column stack with row names (gnuplot `key(N)`), 0 if none: its rows make the key.
   class(axes_object), intent(in) :: self !< Panel.
   integer(I4P)                   :: s    !< Series index.

   do s = size(self%series, kind=I4P), 1_I4P, -1_I4P
      if (.not. self%stacked_column(s)) cycle
      if (allocated(self%series(s)%texts)) return
   enddo
   s = 0_I4P
   endfunction stack_names

   pure function group_rows(self) result(rows)
   !< 1 if a histogram group has a title (gnuplot `newhistogram "title"`), a line below the x tick labels; else 0.
   class(axes_object), intent(in) :: self !< Panel.
   integer(I4P)                   :: rows !< Lines.
   integer(I4P)                   :: s    !< Series counter.

   rows = 0_I4P
   if (.not. allocated(self%series)) return
   do s = 1_I4P, size(self%series, kind=I4P)
      if (self%series(s)%style%with /= WITH_HISTOGRAMS) cycle
      if (.not. allocated(self%series(s)%hist_title)) cycle
      if (len(self%series(s)%hist_title) > 0) rows = 1_I4P
   enddo
   endfunction group_rows

   subroutine draw_group_titles(self, backend, left, right, baseline, font_size)
   !< The title of each histogram group centred under its bars (the middle of its rows, or stacks), on `baseline`,
   !< moved by `hist_title_offset` (0.6 of the font size wide and the font size high characters), in
   !< `hist_title_color`.
   class(axes_object),    intent(in)    :: self     !< Panel.
   class(backend_object), intent(inout) :: backend  !< Output device.
   real(R8P),             intent(in)    :: left     !< Plot area left [px].
   real(R8P),             intent(in)    :: right    !< Plot area right [px].
   real(R8P),             intent(in)    :: baseline !< Text baseline [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   real(R8P)                            :: lo       !< First row of the group.
   real(R8P)                            :: hi       !< Last row of the group.
   real(R8P)                            :: u        !< Unit abscissa of the group centre.
   integer(I4P)                         :: s        !< Series counter.
   integer(I4P)                         :: t        !< Series of the same group.

   call backend%begin_group('fs-groups')
   do s = 1_I4P, size(self%series, kind=I4P)
      if (self%series(s)%style%with /= WITH_HISTOGRAMS) cycle
      ! the first series of its group
      if (any([(self%series(t)%style%with == WITH_HISTOGRAMS .and. &
                self%series(t)%hist_group == self%series(s)%hist_group, t = 1_I4P, s - 1_I4P)])) cycle
      if (len(self%series(s)%hist_title) == 0) cycle
      lo = huge(1.0_R8P)
      hi = -huge(1.0_R8P)
      do t = s, size(self%series, kind=I4P)
         if (self%series(t)%style%with /= WITH_HISTOGRAMS) cycle
         if (self%series(t)%hist_group /= self%series(s)%hist_group) cycle
         lo = min(lo, minval(self%series(t)%x, mask=ieee_is_finite(self%series(t)%x)))
         hi = max(hi, maxval(self%series(t)%x, mask=ieee_is_finite(self%series(t)%x)))
      enddo
      if (.not. (lo <= hi)) cycle
      u = self%xaxis%to_unit(0.5_R8P * (lo + hi))
      if (u < 0.0_R8P .or. u > 1.0_R8P) cycle
      if (allocated(self%hist_title_color)) then
         call backend%text(left + u * (right - left) + 0.6_R8P * font_size * self%hist_title_offset(1), &
                           baseline - font_size * self%hist_title_offset(2), self%series(s)%hist_title, 'middle', &
                           color=self%hist_title_color)
      else
         call backend%text(left + u * (right - left) + 0.6_R8P * font_size * self%hist_title_offset(1), &
                           baseline - font_size * self%hist_title_offset(2), self%series(s)%hist_title, 'middle')
      endif
   enddo
   call backend%end_group
   endsubroutine draw_group_titles

   pure function xlabels_extent(self, backend, font_size) result(extent)
   !< Depth below the base, reach left and right of the tick [px] of the rotated x tick labels, the largest over the
   !< major ticks (see `rotated_extent`); zero without labels.
   class(axes_object),    intent(in) :: self      !< Panel.
   class(backend_object), intent(in) :: backend   !< Output device, for text widths.
   real(R8P),             intent(in) :: font_size !< Font size [px].
   real(R8P)                         :: extent(3) !< Depth, left reach, right reach [px].
   integer(I4P)                      :: t         !< Tick counter.

   extent = 0.0_R8P
   do t = 1_I4P, size(self%xaxis%ticks, kind=I4P)
      if (.not. self%xaxis%ticks(t)%major) cycle
      extent = max(extent, rotated_extent(backend%text_width(self%xaxis%ticks(t)%label, self%xaxis%ticks(t)%sup, &
                                                             font_size), self%xaxis%tics%rotate, &
                                          self%xaxis%tics%anchor(), font_size))
   enddo
   endfunction xlabels_extent

   subroutine draw_frame(self, backend, area, x0, y0, x1, font_size)
   !< Draw border, ticks (mirrored if so set), tick labels, axis labels and title.
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: area(4)   !< Plot area: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: x0        !< Box left side [px].
   real(R8P),             intent(in)    :: y0        !< Box top side [px].
   real(R8P),             intent(in)    :: x1        !< Box right side [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   real(R8P)                            :: p         !< Tick position [px].
   real(R8P)                            :: length    !< Tick length [px].
   real(R8P)                            :: angle     !< x label angle drawn [deg].
   real(R8P)                            :: shift     !< x labels moved down by outward ticks [px].
   real(R8P)                            :: depth     !< Room of the x tick labels below the border [px].
   real(R8P)                            :: label_y   !< Baseline of the x2 label [px].
   real(R8P)                            :: rise(2)   !< Lowest and highest page ordinates of a rotated x2 label from its
                                                     !< anchor [px].
   real(R8P)                            :: title_y   !< Baseline of the title [px].
   real(R8P)                            :: ax        !< Label anchor abscissa [px].
   real(R8P)                            :: ay        !< Label anchor ordinate [px].
   real(R8P)                            :: extent(3) !< Rotated x labels extent [px].
   integer(I4P)                         :: t         !< Tick counter.
   character(len=:), allocatable        :: bcolor    !< Border color.
   type(style_object)                   :: bline     !< Border line.
   real(R8P)                            :: base      !< Line of the ticks: the border, or the zero axis [px].
   real(R8P)                            :: span(2)   !< Ends of a border side limited to the data range [px].
   logical                              :: limited   !< A border side limited to the data range.

   angle = 0.0_R8P
   if (backend%rotates_text()) angle = self%xaxis%tics%rotate
   shift = out_shift(self%xaxis%tics)
   associate(left => area(1), right => area(2), top => area(3), bottom => area(4))
      ! the border's line (gnuplot `set border ... lc lw dt`), the frame color by default
      bcolor = FRAME_COLOR
      if (allocated(self%border_lc)) bcolor = self%border_lc
      bline%dashtype = self%border_dt
      bline%linewidth = self%border_lw
      ! a side of an axis whose ticks are range limited spans its data only (gnuplot `rangelimited`)
      limited = limits(self%xaxis) .or. limits(self%yaxis)
      if (self%x2_active) limited = limited .or. limits(self%x2axis)
      if (self%y2_active) limited = limited .or. limits(self%y2axis)
      if (iand(self%border, 15_I4P) == 15_I4P .and. self%border_dt == 1_I4P .and. .not. limited) then
         call backend%rect(left, top, right - left, bottom - top, bcolor, 'none', self%border_lw)
      else
         span = [left, right]
         if (limits(self%xaxis)) span = horizontal_span(self%xaxis)
         if (btest(self%border, 0)) call backend%polyline(span, [bottom, bottom], bcolor, self%border_lw, &
                                                          bline%dasharray())
         span = [bottom, top]
         if (limits(self%yaxis)) span = vertical_span(self%yaxis)
         if (btest(self%border, 1)) call backend%polyline([left, left], span, bcolor, self%border_lw, &
                                                          bline%dasharray())
         span = [left, right]
         if (self%x2_active) then
            if (limits(self%x2axis)) span = horizontal_span(self%x2axis)
         endif
         if (btest(self%border, 2)) call backend%polyline(span, [top, top], bcolor, self%border_lw, &
                                                          bline%dasharray())
         span = [bottom, top]
         if (self%y2_active) then
            if (limits(self%y2axis)) span = vertical_span(self%y2axis)
         endif
         if (btest(self%border, 3)) call backend%polyline([right, right], span, bcolor, self%border_lw, &
                                                          bline%dasharray())
      endif
      call backend%begin_group('fs-xticks')
      ! on the x axis (y = 0) with `set xtics axis`, not mirrored
      base = bottom
      if (on_zero(self%xaxis%tics, self%yaxis)) base = bottom - self%yaxis%to_unit(0.0_R8P) * (bottom - top)
      do t = 1_I4P, size(self%xaxis%ticks, kind=I4P)
         if (.not. within(self%xaxis, self%xaxis%ticks(t)%value)) cycle
         p = left + self%xaxis%to_unit(self%xaxis%ticks(t)%value) * (right - left)
         length = tick_length(self%xaxis%tics, self%xaxis%ticks(t)%major)
         if (self%xaxis%tics%out) then
            call backend%polyline([p, p], [base, base + length], FRAME_COLOR, 1.0_R8P, '')
            if (self%xaxis%tics%mirror .and. base == bottom) &
               call backend%polyline([p, p], [top, top - length], FRAME_COLOR, 1.0_R8P, '')
         else
            call backend%polyline([p, p], [base, base - length], FRAME_COLOR, 1.0_R8P, '')
            if (self%xaxis%tics%mirror .and. base == bottom) &
               call backend%polyline([p, p], [top, top + length], FRAME_COLOR, 1.0_R8P, '')
         endif
         if (.not. self%xaxis%ticks(t)%major) cycle
         if (angle /= 0.0_R8P) then
            call rotated_anchor(p, base + shift, angle, font_size, ax, ay)
            call tick_label(backend, self%xaxis%tics, font_size, ax, ay, self%xaxis%ticks(t)%label, &
                            trim(self%xaxis%tics%anchor()), self%xaxis%ticks(t)%sup, -angle)
         elseif (self%xaxis%tics%out) then
            call lines_text(backend, p + label_dx(self%xaxis%tics, font_size), base + shift + GAP + font_size + &
                            label_dy(self%xaxis%tics, font_size), self%xaxis%ticks(t)%label, self%xaxis%ticks(t)%sup, &
                            LINE_HEIGHT * font_size, self%xaxis%tics%color)
         else
            call lines_text(backend, p + label_dx(self%xaxis%tics, font_size), base + GAP + font_size + &
                            label_dy(self%xaxis%tics, font_size), self%xaxis%ticks(t)%label, self%xaxis%ticks(t)%sup, &
                            LINE_HEIGHT * font_size, self%xaxis%tics%color)
         endif
      enddo
      call backend%end_group
      ! the titles of the histogram groups (gnuplot `newhistogram "title"`), a line below the x tick labels
      if (self%group_rows() > 0_I4P) call self%draw_group_titles(backend, left, right, bottom + shift + GAP + &
                                                                 font_size + LINE_HEIGHT * font_size * &
                                                                 real(label_rows(self%xaxis%ticks), R8P), font_size)
      call backend%begin_group('fs-yticks')
      ! on the y axis (x = 0) with `set ytics axis`, not mirrored
      base = left
      if (on_zero(self%yaxis%tics, self%xaxis)) base = left + self%xaxis%to_unit(0.0_R8P) * (right - left)
      do t = 1_I4P, size(self%yaxis%ticks, kind=I4P)
         if (.not. within(self%yaxis, self%yaxis%ticks(t)%value)) cycle
         p = bottom - self%yaxis%to_unit(self%yaxis%ticks(t)%value) * (bottom - top)
         length = tick_length(self%yaxis%tics, self%yaxis%ticks(t)%major)
         if (self%yaxis%tics%out) then
            call backend%polyline([base, base - length], [p, p], FRAME_COLOR, 1.0_R8P, '')
            if (self%yaxis%tics%mirror .and. base == left) &
               call backend%polyline([right, right + length], [p, p], FRAME_COLOR, 1.0_R8P, '')
            if (self%yaxis%ticks(t)%major) call tick_label(backend, self%yaxis%tics, font_size, &
                                                           base - GAP - out_shift(self%yaxis%tics), p + 0.35_R8P * font_size, &
                                                           self%yaxis%ticks(t)%label, 'end', self%yaxis%ticks(t)%sup, 0.0_R8P)
            cycle
         endif
         call backend%polyline([base, base + length], [p, p], FRAME_COLOR, 1.0_R8P, '')
         if (self%yaxis%tics%mirror .and. base == left) &
            call backend%polyline([right, right - length], [p, p], FRAME_COLOR, 1.0_R8P, '')
         if (self%yaxis%ticks(t)%major) call tick_label(backend, self%yaxis%tics, font_size, base - GAP, &
                                                        p + 0.35_R8P * font_size, self%yaxis%ticks(t)%label, 'end', &
                                                        self%yaxis%ticks(t)%sup, 0.0_R8P)
      enddo
      call backend%end_group
      if (self%y2_active) then
         call backend%begin_group('fs-y2ticks')
         do t = 1_I4P, size(self%y2axis%ticks, kind=I4P)
            if (.not. within(self%y2axis, self%y2axis%ticks(t)%value)) cycle
            p = bottom - self%y2axis%to_unit(self%y2axis%ticks(t)%value) * (bottom - top)
            length = tick_length(self%y2axis%tics, self%y2axis%ticks(t)%major)
            if (self%y2axis%tics%out) then
               call backend%polyline([right, right + length], [p, p], FRAME_COLOR, 1.0_R8P, '')
               if (self%y2axis%tics%mirror) &
                  call backend%polyline([left, left - length], [p, p], FRAME_COLOR, 1.0_R8P, '')
               if (self%y2axis%ticks(t)%major) call tick_label(backend, self%y2axis%tics, font_size, &
                                                               right + GAP + out_shift(self%y2axis%tics), &
                                                               p + 0.35_R8P * font_size, self%y2axis%ticks(t)%label, &
                                                               'start', self%y2axis%ticks(t)%sup, 0.0_R8P)
               cycle
            endif
            call backend%polyline([right, right - length], [p, p], FRAME_COLOR, 1.0_R8P, '')
            if (self%y2axis%tics%mirror) call backend%polyline([left, left + length], [p, p], FRAME_COLOR, 1.0_R8P, '')
            if (self%y2axis%ticks(t)%major) call tick_label(backend, self%y2axis%tics, font_size, right + GAP, &
                                                            p + 0.35_R8P * font_size, self%y2axis%ticks(t)%label, &
                                                            'start', self%y2axis%ticks(t)%sup, 0.0_R8P)
         enddo
         call backend%end_group
      endif
      if (self%x2_active) then
         ! above the top border, labels on a line ending a quarter font size above it (descenders)
         call backend%begin_group('fs-x2ticks')
         do t = 1_I4P, size(self%x2axis%ticks, kind=I4P)
            if (.not. within(self%x2axis, self%x2axis%ticks(t)%value)) cycle
            p = left + self%x2axis%to_unit(self%x2axis%ticks(t)%value) * (right - left)
            length = tick_length(self%x2axis%tics, self%x2axis%ticks(t)%major)
            if (self%x2axis%tics%out) then
               call backend%polyline([p, p], [top, top - length], FRAME_COLOR, 1.0_R8P, '')
               if (self%x2axis%tics%mirror) &
                  call backend%polyline([p, p], [bottom, bottom + length], FRAME_COLOR, 1.0_R8P, '')
            else
               call backend%polyline([p, p], [top, top + length], FRAME_COLOR, 1.0_R8P, '')
               if (self%x2axis%tics%mirror) &
                  call backend%polyline([p, p], [bottom, bottom - length], FRAME_COLOR, 1.0_R8P, '')
            endif
            if (.not. self%x2axis%ticks(t)%major) cycle
            if (self%x2_rise > 0.0_R8P) then
               ! rotated: centred on the tick, the lowest glyph GAP above the border (or the outward ticks)
               rise = rotated_rise(backend%text_width(self%x2axis%ticks(t)%label, self%x2axis%ticks(t)%sup, font_size), &
                                   self%x2axis%tics%rotate, self%x2axis%tics%anchor(), font_size)
               call tick_label(backend, self%x2axis%tics, font_size, &
                               p + 0.35_R8P * font_size * sin(self%x2axis%tics%rotate * PI_R8 / 180.0_R8P), &
                               top - out_shift(self%x2axis%tics) - GAP - rise(1), self%x2axis%ticks(t)%label, &
                               trim(self%x2axis%tics%anchor()), self%x2axis%ticks(t)%sup, -self%x2axis%tics%rotate)
            else
               call tick_label(backend, self%x2axis%tics, font_size, p, &
                               top - out_shift(self%x2axis%tics) - GAP - 0.25_R8P * font_size, &
                               self%x2axis%ticks(t)%label, 'middle', self%x2axis%ticks(t)%sup, 0.0_R8P)
            endif
         enddo
         call backend%end_group
      endif
      if (self%x2axis%has_label()) then
         label_y = top - self%x2_room(font_size) + (LINE_HEIGHT - 0.25_R8P) * font_size
         ! on a text device, the row right above the x2 tick labels, as gnuplot's dumb terminal (the pixel gap could
         ! leave an empty row between them, depending on what lies above)
         if (backend%row_height() > 0.0_R8P .and. self%x2_active) then
            if (any(self%x2axis%ticks%major)) label_y = top - out_shift(self%x2axis%tics) - GAP - &
                                                       0.25_R8P * font_size - backend%row_height()
         endif
         backend%literal = self%label_plain(4)
         call backend%text(0.5_R8P * (left + right), label_y, self%x2axis%label, 'middle')
         backend%literal = .false.
      endif
      backend%literal = self%label_plain(1)
      if (self%xaxis%has_label()) then
         if (angle /= 0.0_R8P .or. self%xaxis%tics%out) then
            ! below the rotated or moved tick labels
            depth = shift + GAP + LINE_HEIGHT * font_size * real(label_rows(self%xaxis%ticks) + self%group_rows(), R8P)
            if (angle /= 0.0_R8P) then
               extent = self%xlabels_extent(backend, font_size)
               depth = shift + extent(1)
            endif
            call backend%text(0.5_R8P * (left + right), bottom + depth + GAP + font_size, self%xaxis%label, 'middle')
         else
            call backend%text(0.5_R8P * (left + right), bottom + 2.0_R8P * GAP + (1.0_R8P + LINE_HEIGHT * &
                              real(label_rows(self%xaxis%ticks) + self%group_rows(), R8P)) * font_size, &
                              self%xaxis%label, 'middle')
         endif
      endif
      backend%literal = self%label_plain(2)
      if (self%yaxis%has_label()) call backend%text(x0 + PAD + font_size, 0.5_R8P * (top + bottom), &
                                                    self%yaxis%label, 'middle', rotate=-90.0_R8P)
      backend%literal = self%label_plain(3)
      ! read upward as the y label, the glyphs on the left of the baseline
      if (self%y2axis%has_label()) call backend%text(x1 - PAD - 0.25_R8P * font_size, 0.5_R8P * (top + bottom), &
                                                     self%y2axis%label, 'middle', rotate=-90.0_R8P)
      backend%literal = .false.
      if (self%has_title()) then
         title_y = y0 + PAD + font_size
         ! on a text device, the row right above the x2 label or tick labels, with no empty row between them
         if (backend%row_height() > 0.0_R8P .and. self%x2_active) then
            if (self%x2axis%has_label() .and. any(self%x2axis%ticks%major)) then
               title_y = label_y - backend%row_height()
            elseif (any(self%x2axis%ticks%major)) then
               title_y = top - out_shift(self%x2axis%tics) - GAP - 0.25_R8P * font_size - &
                         backend%row_height()
            endif
         endif
         ! gnuplot `set title offset X,Y`: characters, y up
         backend%literal = self%title_plain
         call backend%text(0.5_R8P * (left + right) + self%title_offset(1) * CHAR_WIDTH * font_size, &
                           title_y - self%title_offset(2) * font_size, self%title, 'middle')
         backend%literal = .false.
      endif
   endassociate
   contains
      pure function horizontal_span(axis) result(ends)
      !< Abscissae of the data range of `axis` on the plot area, clipped to it [px].
      type(axis_object), intent(in) :: axis    !< Axis.
      real(R8P)                     :: ends(2) !< Left and right [px].

      ends = area(1) + axis%to_unit([axis%data_lo, axis%data_hi]) * (area(2) - area(1))
      ends = [max(area(1), min(ends(1), ends(2))), min(area(2), max(ends(1), ends(2)))]
      endfunction horizontal_span

      pure function vertical_span(axis) result(ends)
      !< Ordinates of the data range of `axis` on the plot area, clipped to it [px], bottom first.
      type(axis_object), intent(in) :: axis    !< Axis.
      real(R8P)                     :: ends(2) !< Bottom and top [px].

      ends = area(4) - axis%to_unit([axis%data_lo, axis%data_hi]) * (area(4) - area(3))
      ends = [min(area(4), max(ends(1), ends(2))), max(area(3), min(ends(1), ends(2)))]
      endfunction vertical_span
   endsubroutine draw_frame

   subroutine draw_grid(self, backend, area)
   !< Draw grid lines at the ticks of `grid_lines` (the x and y major ones by default), in the grid style.
   class(axes_object),    intent(in)    :: self    !< Panel.
   class(backend_object), intent(inout) :: backend !< Output device.
   real(R8P),             intent(in)    :: area(4) !< Plot area: left, right, top, bottom [px].
   real(R8P)                            :: p       !< Tick position [px].
   integer(I4P)                         :: t       !< Tick counter.
   logical                              :: on(6)   !< x, y, x2, y2, mx, my lines.
   character(len=:), allocatable        :: color   !< Line color.
   character(len=:), allocatable        :: dashes  !< Dash array.

   ! a polar grid replaces the rectangular one, as gnuplot
   if (self%polar .and. self%grid_polar > 0.0_R8P) return
   on = self%grid_lines
   if (.not. any(on)) on(1:2) = .true.
   color = GRID_COLOR
   if (allocated(self%grid_lc)) color = self%grid_lc
   dashes = self%grid_dash_array()
   associate(left => area(1), right => area(2), top => area(3), bottom => area(4))
      do t = 1_I4P, size(self%xaxis%ticks, kind=I4P)
         if (.not. merge(on(1), on(5), self%xaxis%ticks(t)%major)) cycle
         p = left + self%xaxis%to_unit(self%xaxis%ticks(t)%value) * (right - left)
         call backend%polyline([p, p], [bottom, top], color, self%grid_lw, dashes)
      enddo
      do t = 1_I4P, size(self%yaxis%ticks, kind=I4P)
         if (.not. merge(on(2), on(6), self%yaxis%ticks(t)%major)) cycle
         p = bottom - self%yaxis%to_unit(self%yaxis%ticks(t)%value) * (bottom - top)
         call backend%polyline([left, right], [p, p], color, self%grid_lw, dashes)
      enddo
      if (on(3) .and. self%x2_active) then
         do t = 1_I4P, size(self%x2axis%ticks, kind=I4P)
            if (.not. self%x2axis%ticks(t)%major) cycle
            p = left + self%x2axis%to_unit(self%x2axis%ticks(t)%value) * (right - left)
            call backend%polyline([p, p], [bottom, top], color, self%grid_lw, dashes)
         enddo
      endif
      if (on(4) .and. self%y2_active) then
         do t = 1_I4P, size(self%y2axis%ticks, kind=I4P)
            if (.not. self%y2axis%ticks(t)%major) cycle
            p = bottom - self%y2axis%to_unit(self%y2axis%ticks(t)%value) * (bottom - top)
            call backend%polyline([left, right], [p, p], color, self%grid_lw, dashes)
         enddo
      endif
   endassociate
   endsubroutine draw_grid

   subroutine draw_zero_axes(self, backend)
   !< The zero axes in the plot area's unit square: y = 0 (xzeroaxis), x = 0 (yzeroaxis), y2 = 0, x2 = 0, where in range.
   class(axes_object),    intent(in)    :: self    !< Panel.
   class(backend_object), intent(inout) :: backend !< Output device.
   type(style_object)                   :: zline   !< Zero axes line.
   character(len=:), allocatable        :: color   !< Line color.
   real(R8P)                            :: u       !< Unit coordinate of the zero.

   color = FRAME_COLOR
   if (allocated(self%zero_lc)) color = self%zero_lc
   zline%dashtype = self%zero_dt
   zline%linewidth = self%zero_lw
   if (self%zero_axes(1) .and. .not. self%yaxis%log) then
      u = self%yaxis%to_unit(0.0_R8P)
      if (u >= 0.0_R8P .and. u <= 1.0_R8P) call backend%data_polyline([0.0_R8P, 1.0_R8P], [u, u], color, self%zero_lw, &
                                                                       zline%dasharray())
   endif
   if (self%zero_axes(2) .and. .not. self%xaxis%log) then
      u = self%xaxis%to_unit(0.0_R8P)
      if (u >= 0.0_R8P .and. u <= 1.0_R8P) call backend%data_polyline([u, u], [0.0_R8P, 1.0_R8P], color, self%zero_lw, &
                                                                       zline%dasharray())
   endif
   if (self%zero_axes(3) .and. self%y2_active .and. .not. self%y2axis%log) then
      u = self%y2axis%to_unit(0.0_R8P)
      if (u >= 0.0_R8P .and. u <= 1.0_R8P) call backend%data_polyline([0.0_R8P, 1.0_R8P], [u, u], color, self%zero_lw, &
                                                                       zline%dasharray())
   endif
   if (self%zero_axes(4) .and. self%x2_active .and. .not. self%x2axis%log) then
      u = self%x2axis%to_unit(0.0_R8P)
      if (u >= 0.0_R8P .and. u <= 1.0_R8P) call backend%data_polyline([u, u], [0.0_R8P, 1.0_R8P], color, self%zero_lw, &
                                                                       zline%dasharray())
   endif
   endsubroutine draw_zero_axes

   pure function axis_markup(axis) result(yes)
   !< Whether a tick label of `axis` (drawn, from the data, of the explicit list, or its format) holds enhanced text
   !< markup, unless the labels are as they are (`noenhanced`).
   type(axis_object), intent(in) :: axis !< Axis.
   logical                       :: yes  !< Markup.
   integer(I4P)                  :: k    !< Counter.

   yes = .false.
   if (axis%tics%plain) return
   if (allocated(axis%ticks)) then
      do k = 1_I4P, size(axis%ticks, kind=I4P)
         if (allocated(axis%ticks(k)%label)) yes = yes .or. has_markup(axis%ticks(k)%label)
      enddo
   endif
   if (allocated(axis%labels)) then
      do k = 1_I4P, size(axis%labels, kind=I4P)
         if (allocated(axis%labels(k)%label)) yes = yes .or. has_markup(axis%labels(k)%label)
      enddo
   endif
   if (allocated(axis%tics%list)) then
      do k = 1_I4P, size(axis%tics%list, kind=I4P)
         if (allocated(axis%tics%list(k)%label)) yes = yes .or. has_markup(axis%tics%list(k)%label)
      enddo
   endif
   if (axis%tics%has_format()) yes = yes .or. has_markup(axis%tics%format)
   endfunction axis_markup

   pure function place_words(axis, text) result(words)
   !< The viewer tick settings `text`, after the placement of the ticks of `axis`: `axis` (on the zero axis of the other
   !< coordinate) and `rangelimited LO HI` (within the data range), if so.
   type(axis_object), intent(in) :: axis  !< Axis.
   character(len=*),  intent(in) :: text  !< Tick settings.
   character(len=:), allocatable :: words !< Settings.

   words = text
   if (limits(axis)) then
      if (len(words) > 0) words = ' '//words
      words = 'rangelimited '//real_str(axis%data_lo)//' '//real_str(axis%data_hi)//words
   endif
   if (axis%tics%on_axis) then
      if (len(words) > 0) words = ' '//words
      words = 'axis'//words
   endif
   endfunction place_words

   pure function style_words(tics, text) result(words)
   !< The viewer tick settings `text`, after the label style of `tics`: `offset X Y` (characters) and `color C`, if set.
   type(tics_object), intent(in) :: tics  !< Axis tick settings.
   character(len=*),  intent(in) :: text  !< Tick settings.
   character(len=:), allocatable :: words !< Settings.

   words = text
   if (len_trim(tics%color) > 0) then
      if (len(words) > 0) words = ' '//words
      words = 'color '//trim(tics%color)//words
   endif
   if (any(tics%offset /= 0.0_R8P)) then
      if (len(words) > 0) words = ' '//words
      words = 'offset '//real_str(tics%offset(1))//' '//real_str(tics%offset(2))//words
   endif
   endfunction style_words

   pure function plain_word(plain, tics) result(words)
   !< The viewer tick settings `tics`, after `noenhanced` if the labels are `plain` (not read as enhanced text).
   logical,          intent(in)  :: plain !< Labels as they are.
   character(len=*), intent(in)  :: tics  !< Tick settings.
   character(len=:), allocatable :: words !< Settings.

   words = tics
   if (.not. plain) return
   words = 'noenhanced'
   if (len(tics) > 0) words = words//' '//tics
   endfunction plain_word

   pure function grid_words(lines) result(words)
   !< The grid lines as the viewer reads them (`x y mx`), empty for the default x and y.
   logical, intent(in)           :: lines(6) !< x, y, x2, y2, mx, my.
   character(len=:), allocatable :: words    !< Words.
   character(len=*), parameter   :: NAMES(6) = [character(len=2) :: 'x', 'y', 'x2', 'y2', 'mx', 'my'] !< Names.
   integer(I4P)                  :: k        !< Counter.

   words = ''
   if (.not. any(lines)) return
   if (all(lines .eqv. [.true., .true., .false., .false., .false., .false.])) return
   do k = 1_I4P, 6_I4P
      if (lines(k)) words = words//' '//trim(NAMES(k))
   enddo
   words = words(2:)
   endfunction grid_words

   pure function grid_dash_array(self) result(dashes)
   !< Dash array of the grid lines: foresight's dots, or the dash type's (`set grid dt N`; 1 solid).
   class(axes_object), intent(in) :: self   !< Panel.
   character(len=:), allocatable  :: dashes !< Dash array.
   type(style_object)             :: line   !< A line of the dash type.

   dashes = GRID_DASHES
   if (self%grid_dt <= 0_I4P) return
   line%dashtype = self%grid_dt
   line%linewidth = self%grid_lw
   dashes = line%dasharray()
   endfunction grid_dash_array

   subroutine draw_polar_grid(self, backend)
   !< Draw the polar grid in the plot area: rings at the major r ticks, spokes every `grid_polar` degrees of theta.
   class(axes_object),    intent(in)    :: self    !< Panel.
   class(backend_object), intent(inout) :: backend !< Output device.
   real(R8P)                            :: radius  !< Largest radius [r units from the pole].
   real(R8P)                            :: rho     !< Ring radius [r units from the pole].
   real(R8P)                            :: a       !< Page angle [rad].
   real(R8P)                            :: turn(CIRCLE_SIDES + 1) !< Angles of the circle vertices [rad].
   integer(I4P)                         :: t       !< Tick counter.
   integer(I4P)                         :: k       !< Vertex or spoke counter.

   turn = [(2.0_R8P * PI_R8 * real(k, R8P) / real(CIRCLE_SIDES, R8P), k = 0_I4P, CIRCLE_SIDES)]
   radius = self%raxis%hi - self%raxis%lo
   do t = 1_I4P, size(self%raxis%ticks, kind=I4P)
      if (.not. self%raxis%ticks(t)%major) cycle
      rho = self%raxis%ticks(t)%value - self%raxis%lo
      if (rho <= 0.0_R8P .or. rho > radius * (1.0_R8P + 1.0e-9_R8P)) cycle
      call backend%data_polyline(self%xaxis%to_unit(rho * cos(turn)), self%yaxis%to_unit(rho * sin(turn)), GRID_COLOR, &
                                 0.5_R8P, GRID_DASHES)
   enddo
   k = 0_I4P
   do while (real(k, R8P) * self%grid_polar < 360.0_R8P - 1.0e-9_R8P)
      a = self%page_angle(real(k, R8P) * self%grid_polar)
      call backend%data_polyline(self%xaxis%to_unit([0.0_R8P, radius * cos(a)]), &
                                 self%yaxis%to_unit([0.0_R8P, radius * sin(a)]), GRID_COLOR, 0.5_R8P, GRID_DASHES)
      k = k + 1_I4P
   enddo
   endsubroutine draw_polar_grid

   subroutine draw_polar_axes(self, backend, area, font_size)
   !< Draw the ticks of the radial axis (a line from the pole to the largest r towards the right of the page whatever
   !< the theta origin, drawn with the data) and their labels below it, as gnuplot; and the theta labels (`ttics`)
   !< outside the largest r, with ticks on the polar border. Page geometry: hidden by the viewer while zoomed.
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: area(4)   !< Plot area: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   type(tick_object), allocatable       :: thetas(:) !< Theta labels.
   type(tics_object)                    :: tics      !< Theta label settings.
   character(len=:), allocatable        :: message   !< Settings problem.
   character(len=6)                     :: anchor    !< Label anchor.
   real(R8P)                            :: cx        !< Pole abscissa [px].
   real(R8P)                            :: cy        !< Pole ordinate [px].
   real(R8P)                            :: sx        !< Horizontal scale [px per r unit].
   real(R8P)                            :: sy        !< Vertical scale [px per r unit].
   real(R8P)                            :: radius    !< Largest radius [r units from the pole].
   real(R8P)                            :: p         !< Tick abscissa [px].
   real(R8P)                            :: a         !< Page angle [rad].
   real(R8P)                            :: lo        !< Theta range start [deg].
   real(R8P)                            :: hi        !< Theta range end [deg].
   real(R8P)                            :: length    !< Tick length [px].
   integer(I4P)                         :: t         !< Tick counter.

   associate(left => area(1), right => area(2), top => area(3), bottom => area(4))
      cx = left + self%xaxis%to_unit(0.0_R8P) * (right - left)
      cy = bottom - self%yaxis%to_unit(0.0_R8P) * (bottom - top)
      sx = (right - left) / (self%xaxis%hi - self%xaxis%lo)
      sy = (bottom - top) / (self%yaxis%hi - self%yaxis%lo)
   endassociate
   radius = self%raxis%hi - self%raxis%lo
   if (self%raxis_on) then
      do t = 1_I4P, size(self%raxis%ticks, kind=I4P)
         p = cx + (self%raxis%ticks(t)%value - self%raxis%lo) * sx
         length = tick_length(self%raxis%tics, self%raxis%ticks(t)%major)
         call backend%polyline([p, p], [cy, cy - length], FRAME_COLOR, 1.0_R8P, '')
         if (self%raxis%ticks(t)%major) call backend%text(p, cy + GAP + font_size, self%raxis%ticks(t)%label, &
                                                          'middle', sup=self%raxis%ticks(t)%sup)
      enddo
   endif
   if (self%ttics%mode == TICS_NONE) return
   tics = self%ttics
   ! automatic: every 45 degrees from 0 (gnuplot draws none)
   if (tics%mode /= TICS_FIXED) call tics%set_fixed('45', '0', '', message)
   lo = 0.0_R8P
   hi = 360.0_R8P
   call linear_ticks(lo, hi, 1.0_R8P, .false., .false., thetas, tics)
   do t = 1_I4P, size(thetas, kind=I4P)
      ! a full turn names the start direction again
      if (thetas(t)%value >= 360.0_R8P - 1.0e-9_R8P .and. any(thetas%value <= 1.0e-9_R8P)) cycle
      a = self%page_angle(thetas(t)%value)
      if (self%border_polar) call backend%polyline([cx + radius * sx * cos(a), cx + (radius * sx - TICK_MAJOR) * cos(a)], &
                                                   [cy - radius * sy * sin(a), cy - (radius * sy - TICK_MAJOR) * sin(a)], &
                                                   FRAME_COLOR, 1.0_R8P, '')
      anchor = 'middle'
      if (cos(a) > 0.3_R8P) anchor = 'start'
      if (cos(a) < -0.3_R8P) anchor = 'end'
      call backend%text(cx + (radius * sx + GAP) * cos(a), &
                        cy - (radius * sy + GAP + 0.5_R8P * font_size) * sin(a) + 0.35_R8P * font_size, &
                        thetas(t)%label, trim(anchor), sup=thetas(t)%sup)
   enddo
   endsubroutine draw_polar_axes

   elemental function page_angle(self, theta) result(a)
   !< Page angle of the theta `theta` [deg] (counterclockwise from the right) [rad], after `set theta`.
   class(axes_object), intent(in) :: self  !< Panel.
   real(R8P),          intent(in) :: theta !< Theta [deg].
   real(R8P)                      :: a     !< Page angle [rad].

   a = (self%theta_origin + merge(-theta, theta, self%theta_clockwise)) * (PI_R8 / 180.0_R8P)
   endfunction page_angle

   subroutine draw_key(self, backend, area, box, font_size, grid, extent)
   !< Draw the key at its place (`key_place`): right-aligned titles, style samples on their right; entries in a column,
   !< or row after row (`key_horizontal`).
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: area(4)   !< Plot area: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: box(4)    !< Panel box: left, top, right, bottom [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   integer(I4P),          intent(in)    :: grid(3)   !< Entries, columns, rows (`key_layout`).
   real(R8P),             intent(in)    :: extent(2) !< Key width and height [px] (`key_layout`).
   real(R8P)                            :: xs(2)     !< Sample abscissae [px].
   real(R8P)                            :: yc        !< Row centre ordinate [px].
   real(R8P)                            :: entry     !< Entry width, spacing included [px].
   real(R8P)                            :: left      !< Key left [px].
   real(R8P)                            :: top       !< Key top [px].
   character(len=:), allocatable        :: sample    !< Color of the point sample.
   integer(I4P)                         :: k         !< Entry counter.
   integer(I4P)                         :: s         !< Series counter.
   real(R8P)                            :: tx        !< Title abscissa [px].
   character(len=5)                     :: anchor    !< Title anchor.

   associate(width => extent(1), height => extent(2))
      entry = (width + GAP) / real(grid(2), R8P)
      if (self%key_at) then
         ! gnuplot `set key at`: the key box aligned on the position as a text, by left/right/center, top/bottom/center
         call key_anchor(left, top)
      else
      select case (self%key_place())
      case ('left', 'right')
         ! beside the plot, aligned with its border
         if (self%key_place() == 'left') then
            left = box(1) + PAD
         else
            left = box(3) - PAD - width
         endif
         select case (trim(self%key_v))
         case ('bottom')
            top = area(4) - height
         case ('center')
            top = 0.5_R8P * (area(3) + area(4) - height)
         case default
            top = area(3)
         endselect
      case ('top', 'bottom')
         ! above or below the plot, aligned with it
         select case (trim(self%key_h))
         case ('left')
            left = area(1)
         case ('right')
            left = area(2) - width
         case default
            left = 0.5_R8P * (area(1) + area(2) - width)
         endselect
         if (self%key_place() == 'top') then
            top = area(3) - self%x2_room(font_size) - GAP - height
         else
            top = box(4) - PAD - height
         endif
      case default
         select case (trim(self%key_h))
         case ('left')
            left = area(1) + PAD
         case ('center')
            left = 0.5_R8P * (area(1) + area(2) - width)
         case default
            left = area(2) - PAD - width
         endselect
         select case (trim(self%key_v))
         case ('bottom')
            top = area(4) - GAP - height
         case ('center')
            top = 0.5_R8P * (area(3) + area(4) - height)
         case default
            top = area(3) + GAP
         endselect
      endselect
      endif
      ! gnuplot `offset`: characters, y up
      left = left + self%key_offset(1) * CHAR_WIDTH * font_size
      top = top - self%key_offset(2) * font_size
      if (self%key_opaque) call backend%rect(left - GAP, top - 0.5_R8P * GAP, width + 2.0_R8P * GAP, height + GAP, &
                                             'none', WINDOW_FILL, 1.0_R8P)
      if (self%key_box) then
         ! gnuplot `set key box lc lw dt`
         block
            type(style_object)            :: bline  !< Box line.
            character(len=:), allocatable :: bcolor !< Box color.

            bcolor = FRAME_COLOR
            if (len_trim(self%key_box_lc) > 0) bcolor = trim(self%key_box_lc)
            if (self%key_box_dt == 1_I4P) then
               call backend%rect(left - GAP, top - 0.5_R8P * GAP, width + 2.0_R8P * GAP, height + GAP, bcolor, 'none', &
                                 self%key_box_lw)
            else
               bline%dashtype = self%key_box_dt
               bline%linewidth = self%key_box_lw
               call backend%polyline([left - GAP, left + width + GAP, left + width + GAP, left - GAP, left - GAP], &
                                     [top - 0.5_R8P * GAP, top - 0.5_R8P * GAP, top + height + 0.5_R8P * GAP, &
                                      top + height + 0.5_R8P * GAP, top - 0.5_R8P * GAP], bcolor, self%key_box_lw, &
                                     bline%dasharray())
            endif
         endblock
      endif
      if (allocated(self%key_title)) then
         if (len(self%key_title) > 0) then
            backend%literal = self%key_plain
            call backend%text(left + 0.5_R8P * width, top + 0.85_R8P * LINE_HEIGHT * font_size, self%key_title, 'middle')
            backend%literal = .false.
            top = top + LINE_HEIGHT * font_size
         endif
      endif
   endassociate
   k = 0_I4P
   do s = 1_I4P, size(self%series, kind=I4P)
      if (len(self%series(s)%title) == 0 .or. self%is_readout(s) .or. self%stacked_column(s)) cycle
      ! entry k (from 0; the last first with invert) in column mod(k, columns), row k / columns
      call entry_place(merge(grid(1) - 1_I4P - k, k, self%key_invert), xs, yc, tx, anchor)
      k = k + 1_I4P
      call backend%begin_group('fs-key-entry', series=s)
      if (self%series(s)%style%fills()) &
         call backend%polygon([xs(1), xs(2), xs(2), xs(1)], &
                              [yc + 0.35_R8P * font_size, yc + 0.35_R8P * font_size, yc - 0.35_R8P * font_size, &
                               yc - 0.35_R8P * font_size], self%series(s)%style%fill_color(), &
                              self%series(s)%style%density, self%series(s)%style%stroke_color(), &
                              self%series(s)%style%linewidth)
      if ((self%series(s)%style%draws_lines() .or. any(self%series(s)%style%with == [WITH_IMPULSES, WITH_FINANCEBARS, &
                                                                                    WITH_VECTORS, WITH_ARROWS])) .and. &
          trim(self%series(s)%style%color) /= 'none') &
         call backend%polyline(xs, [yc, yc], self%series(s)%style%color, self%series(s)%style%linewidth, &
                               self%series(s)%style%dasharray())
      if (self%series(s)%style%draws_ybars()) &
         call backend%polyline([0.5_R8P * (xs(1) + xs(2)), 0.5_R8P * (xs(1) + xs(2))], &
                               [yc - 0.4_R8P * font_size, yc + 0.4_R8P * font_size], self%series(s)%style%color, &
                               self%series(s)%style%linewidth, '')
      if (self%series(s)%style%draws_xbars()) &
         call backend%polyline(xs, [yc, yc], self%series(s)%style%color, self%series(s)%style%linewidth, '')
      if (self%series(s)%style%draws_points()) then
         ! with a color per point, the point sample in the last point's color, as gnuplot (the line sample: the first's)
         sample = self%series(s)%style%color
         if (allocated(self%series(s)%colors)) then
            if (size(self%series(s)%colors) > 0) sample = trim(self%series(s)%colors(size(self%series(s)%colors)))
         endif
         if (sample /= 'none') call backend%dots([0.5_R8P * (xs(1) + xs(2))], [yc], sample, &
                                                 self%series(s)%style%point_diameter(), &
                                                 pt=self%series(s)%style%pointtype, &
                                                 line_width=self%series(s)%style%linewidth)
      endif
      backend%literal = self%key_plain .or. self%series(s)%title_plain
      ! gnuplot `textcolor`: the titles in a color, or each in its series' (`variable`)
      if (trim(self%key_tc) == 'variable') then
         call backend%text(tx, yc + 0.35_R8P * font_size, self%series(s)%title, trim(anchor), &
                           color=self%series(s)%style%color)
      elseif (len_trim(self%key_tc) > 0) then
         call backend%text(tx, yc + 0.35_R8P * font_size, self%series(s)%title, trim(anchor), color=trim(self%key_tc))
      else
         call backend%text(tx, yc + 0.35_R8P * font_size, self%series(s)%title, trim(anchor))
      endif
      backend%literal = .false.
      call backend%end_group
   enddo
   ! the rows of column stacks, by their names, the last row first (as gnuplot): no series of their own
   s = self%stack_names()
   if (s > 0_I4P) then
      block
         type(style_object) :: row !< Style of a row.
         integer(I4P)       :: r   !< Row counter.

         do r = size(self%series(s)%texts, kind=I4P), 1_I4P, -1_I4P
            call entry_place(merge(grid(1) - 1_I4P - k, k, self%key_invert), xs, yc, tx, anchor)
            k = k + 1_I4P
            row = self%series(s)%style
            row%color = default_color(r, self%linecolors)
            call backend%begin_group('fs-key-row')
            call backend%polygon([xs(1), xs(2), xs(2), xs(1)], &
                                 [yc + 0.35_R8P * font_size, yc + 0.35_R8P * font_size, yc - 0.35_R8P * font_size, &
                                  yc - 0.35_R8P * font_size], row%fill_color(), row%density, row%stroke_color(), &
                                 row%linewidth)
            backend%literal = self%key_plain
            call backend%text(tx, yc + 0.35_R8P * font_size, trim(self%series(s)%texts(r)), trim(anchor))
            backend%literal = .false.
            call backend%end_group
         enddo
      endblock
   endif
   contains
      subroutine entry_place(n, xs, yc, tx, anchor)
      !< Sample abscissae, row centre and title position of entry `n` (from 0): the sample at the right of its cell, or at
      !< its left (`reverse`); the title beside it, right-justified, or left-justified (`Left`), as gnuplot.
      integer(I4P),     intent(in)  :: n      !< Entry.
      real(R8P),        intent(out) :: xs(2)  !< Sample abscissae [px].
      real(R8P),        intent(out) :: yc     !< Row centre [px].
      real(R8P),        intent(out) :: tx     !< Title abscissa [px].
      character(len=5), intent(out) :: anchor !< Title anchor.
      real(R8P)                     :: cell(2) !< Cell left and right [px].

      ! row after row (horizontal), column after column (vertical: more than one with `maxrows`)
      if (self%key_horizontal) then
         cell(1) = left + real(modulo(n, grid(2)), R8P) * entry
         yc = top + (real(n / grid(2), R8P) + 0.5_R8P) * self%key_spacing * LINE_HEIGHT * font_size
      else
         cell(1) = left + real(n / grid(3), R8P) * entry
         yc = top + (real(modulo(n, grid(3)), R8P) + 0.5_R8P) * self%key_spacing * LINE_HEIGHT * font_size
      endif
      cell(2) = cell(1) + entry - GAP
      if (self%key_reverse) then
         xs = [cell(1), cell(1) + self%key_sample(font_size)]
         tx = merge(xs(2) + GAP, cell(2), self%key_left)
      else
         xs = [cell(2) - self%key_sample(font_size), cell(2)]
         tx = merge(cell(1), xs(1) - GAP, self%key_left)
      endif
      anchor = merge('start', 'end  ', self%key_left)
      endsubroutine entry_place

      subroutine key_anchor(left, top)
      !< Left and top [px] of the key placed at `key_xy`: its box edge (`left`, `right`) or centre on the abscissa, its
      !< top, bottom or centre on the ordinate; `first` and `second` are the values of the x/y and x2/y2 axes, `graph`
      !< fractions of the plot area and `screen` of the page, from the bottom left.
      real(R8P), intent(out) :: left !< Key left [px].
      real(R8P), intent(out) :: top  !< Key top [px].
      real(R8P)              :: ax   !< Anchor abscissa [px].
      real(R8P)              :: ay   !< Anchor ordinate [px].

      select case (trim(self%key_system(1)))
      case ('graph')
         ax = area(1) + self%key_xy(1) * (area(2) - area(1))
      case ('screen')
         ax = self%key_xy(1) * self%canvas(1)
      case default
         if (trim(self%key_system(1)) == 'second' .and. self%x2_active) then
            ax = area(1) + self%x2axis%to_unit(self%key_xy(1)) * (area(2) - area(1))
         else
            ax = area(1) + self%xaxis%to_unit(self%key_xy(1)) * (area(2) - area(1))
         endif
      endselect
      select case (trim(self%key_system(2)))
      case ('graph')
         ay = area(4) - self%key_xy(2) * (area(4) - area(3))
      case ('screen')
         ay = (1.0_R8P - self%key_xy(2)) * self%canvas(2)
      case default
         if (trim(self%key_system(2)) == 'second' .and. self%y2_active) then
            ay = area(4) - self%y2axis%to_unit(self%key_xy(2)) * (area(4) - area(3))
         else
            ay = area(4) - self%yaxis%to_unit(self%key_xy(2)) * (area(4) - area(3))
         endif
      endselect
      select case (trim(self%key_h))
      case ('left')
         left = ax + GAP
      case ('center')
         left = ax - 0.5_R8P * extent(1)
      case default
         left = ax - extent(1) - GAP
      endselect
      select case (trim(self%key_v))
      case ('bottom')
         top = ay - extent(2) - 0.5_R8P * GAP
      case ('center')
         top = ay - 0.5_R8P * extent(2)
      case default
         top = ay + 0.5_R8P * GAP
      endselect
      endsubroutine key_anchor
   endsubroutine draw_key

   subroutine draw_readouts(self, backend, area, font_size, fill)
   !< Draw the block of readouts in `area`, as the key is placed inside the plot area: a column (or a row) of readouts,
   !< over an opaque window unless `fill`, where the readouts are alone in the panel and the digits grow until the
   !< block fills `area` (vector devices; text has one size), unless a digit size is set.
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: area(4)   !< Box: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   logical,               intent(in)    :: fill      !< Readouts alone, filling the box.
   type :: glass_object
      !< Readout content.
      integer(I4P), allocatable     :: masks(:) !< Segments of each cell.
      character(len=:), allocatable :: prefix   !< Text before the glass.
      character(len=:), allocatable :: suffix   !< Text after the glass.
   endtype glass_object
   type(glass_object), allocatable      :: glasses(:) !< Readouts, in series order.
   integer(I4P), allocatable            :: which(:)   !< Series of each readout.
   real(R8P),    allocatable            :: sizes(:,:) !< Width and height of each readout [px].
   real(R8P)                            :: height     !< Digit height [px].
   real(R8P)                            :: spacing    !< Space between readouts [px].
   real(R8P)                            :: block(2)   !< Block width and height [px].
   real(R8P)                            :: left       !< Block left [px].
   real(R8P)                            :: top        !< Block top [px].
   real(R8P)                            :: p          !< Position of the next readout [px].
   real(R8P)                            :: inset(2)   !< Block inset from the plot border, across and down [px].
   real(R8P)                            :: pad(2)     !< Window padding, across and down [px].
   integer(I4P)                         :: r          !< Readout counter.
   integer(I4P)                         :: s          !< Series counter.
   integer(I4P)                         :: along      !< Direction of the block: 1 a row, 2 a column.

   which = pack([(s, s = 1_I4P, size(self%series, kind=I4P))], [(self%is_readout(s), s = 1_I4P, &
                                                                  size(self%series, kind=I4P))])
   allocate(glasses(size(which)))
   do r = 1_I4P, size(which, kind=I4P)
      associate(series => self%series(which(r)))
         call readout_glass(series%format, last_finite(series%y), glasses(r)%masks, glasses(r)%prefix, &
                            glasses(r)%suffix)
      endassociate
   enddo
   along = merge(1_I4P, 2_I4P, self%readout_horizontal)
   spacing = merge(2.0_R8P, 1.0_R8P, self%readout_horizontal) * font_size
   height = DIGIT_HEIGHT * font_size
   if (self%readout_size > 0.0_R8P) then
      height = self%readout_size
   elseif (fill) then
      height = filling_height()
   endif
   call measure(height, sizes, block)
   select case (trim(self%readout_h))
   case ('right')
      left = area(2) - block(1)
   case ('center')
      left = 0.5_R8P * (area(1) + area(2) - block(1))
   case default
      left = area(1)
   endselect
   select case (trim(self%readout_v))
   case ('bottom')
      top = area(4) - block(2)
   case ('center')
      top = 0.5_R8P * (area(3) + area(4) - block(2))
   case default
      top = area(3)
   endselect
   if (.not. fill) then
      ! inside the plot area, the window clear of its border by a text cell at least: on a text device a smaller inset
      ! puts the window on the border row or column
      inset = [2.0_R8P * font_size, 2.0_R8P * LINE_HEIGHT * font_size]
      left = left + merge(-inset(1), merge(0.0_R8P, inset(1), trim(self%readout_h) == 'center'), &
                          trim(self%readout_h) == 'right')
      top = top + merge(-inset(2), merge(0.0_R8P, inset(2), trim(self%readout_v) == 'center'), &
                        trim(self%readout_v) == 'bottom')
   endif
   call backend%begin_group('fs-readouts')
   ! the window padding, a text cell, keeps the label off the window border on a text device too
   pad = [font_size, LINE_HEIGHT * font_size]
   if (.not. fill .and. self%readout_opaque) call backend%rect(left - pad(1), top - pad(2), block(1) + 2.0_R8P * pad(1), &
                                                               block(2) + 2.0_R8P * pad(2), FRAME_COLOR, WINDOW_FILL, &
                                                               1.0_R8P)
   p = merge(left, top, along == 1_I4P)
   do r = 1_I4P, size(which, kind=I4P)
      associate(series => self%series(which(r)))
         if (along == 1_I4P) then
            call backend%readout(p, top, height, glasses(r)%masks, series%title, glasses(r)%prefix, glasses(r)%suffix, &
                                 series%style%color, font_size)
         else
            call backend%readout(left, p, height, glasses(r)%masks, series%title, glasses(r)%prefix, glasses(r)%suffix, &
                                 series%style%color, font_size)
         endif
      endassociate
      p = p + sizes(along, r) + spacing
   enddo
   call backend%end_group
   contains
      subroutine measure(h, extents, total)
      !< Size of each readout and of the block at digit height `h`.
      real(R8P),              intent(in)  :: h          !< Digit height [px].
      real(R8P), allocatable, intent(out) :: extents(:,:) !< Width and height of each readout [px].
      real(R8P),              intent(out) :: total(2)   !< Block width and height [px].
      integer(I4P)                        :: k          !< Readout counter.

      allocate(extents(2, size(which)))
      do k = 1_I4P, size(which, kind=I4P)
         extents(:, k) = backend%readout_extent(h, size(glasses(k)%masks, kind=I4P), self%series(which(k))%title, &
                                                glasses(k)%prefix, glasses(k)%suffix, font_size)
      enddo
      total(along) = sum(extents(along, :)) + real(size(which) - 1, R8P) * spacing
      total(3_I4P - along) = maxval(extents(3_I4P - along, :))
      endsubroutine measure

      function filling_height() result(h)
      !< Largest digit height whose block fits `area`: readout sizes are affine in the digit height, measured at two
      !< heights; a device whose readouts do not grow (text) keeps the default.
      real(R8P)              :: h       !< Digit height [px].
      real(R8P), allocatable :: e1(:,:) !< Readout sizes at a unit height [px].
      real(R8P), allocatable :: e2(:,:) !< Readout sizes at twice the unit height [px].
      real(R8P)              :: t1(2)   !< Block size at a unit height [px].
      real(R8P)              :: t2(2)   !< Block size at twice the unit height [px].
      real(R8P)              :: room(2) !< Box width and height [px].
      integer(I4P)           :: d       !< Direction counter.

      call measure(font_size, e1, t1)
      call measure(2.0_R8P * font_size, e2, t2)
      room = [area(2) - area(1), area(4) - area(3)]
      h = huge(1.0_R8P)
      do d = 1_I4P, 2_I4P
         ! the block size along the stack is the sum of affine sizes (affine); across it, the largest one: bound each
         if (d == along) then
            call bound(t1(d), t2(d), room(d), h)
         else
            do s = 1_I4P, size(which, kind=I4P)
               call bound(e1(d, s), e2(d, s), room(d), h)
            enddo
         endif
      enddo
      if (h == huge(1.0_R8P)) h = DIGIT_HEIGHT * font_size
      h = max(h, font_size)
      endfunction filling_height

      pure subroutine bound(at1, at2, room, h)
      !< Lower `h` to the height whose size, `at1` at one font size and `at2` at two, reaches `room`.
      real(R8P), intent(in)    :: at1   !< Size at a digit height of one font size [px].
      real(R8P), intent(in)    :: at2   !< Size at a digit height of two font sizes [px].
      real(R8P), intent(in)    :: room  !< Room [px].
      real(R8P), intent(inout) :: h     !< Digit height [px].
      real(R8P)                :: slope !< Size per digit height.

      slope = (at2 - at1) / font_size
      if (slope > 0.0_R8P) h = min(h, font_size + (room - at1) / slope)
      endsubroutine bound
   endsubroutine draw_readouts

   pure subroutine key_layout(self, backend, font_size, room, grid, extent)
   !< Key grid and size: entries (titled series), columns (1, or as many as `room` holds when horizontal) and rows;
   !< each entry is the widest title, a gap and the sample, with a gap between entries.
   class(axes_object),    intent(in)  :: self      !< Panel.
   class(backend_object), intent(in)  :: backend   !< Output device, for text widths.
   real(R8P),             intent(in)  :: font_size !< Font size [px].
   real(R8P),             intent(in)  :: room      !< Width available to a row of entries [px].
   integer(I4P),          intent(out) :: grid(3)   !< Entries, columns, rows.
   real(R8P),             intent(out) :: extent(2) !< Key width and height [px].
   real(R8P)                          :: entry     !< Entry width, spacing included [px].
   integer(I4P)                       :: s         !< Series counter.
   integer(I4P)                       :: k         !< Row counter.

   grid = [0_I4P, 1_I4P, 0_I4P]
   entry = 0.0_R8P
   if (allocated(self%series)) then
      do s = 1_I4P, size(self%series, kind=I4P)
         if (len(self%series(s)%title) == 0 .or. self%is_readout(s) .or. self%stacked_column(s)) cycle
         grid(1) = grid(1) + 1_I4P
         entry = max(entry, backend%text_width(self%series(s)%title, '', font_size))
      enddo
      ! the rows of column stacks, by their names
      s = self%stack_names()
      if (s > 0_I4P) then
         do k = 1_I4P, size(self%series(s)%texts, kind=I4P)
            grid(1) = grid(1) + 1_I4P
            entry = max(entry, backend%text_width(trim(self%series(s)%texts(k)), '', font_size))
         enddo
      endif
   endif
   ! one font size of slack: vector devices only estimate text widths, and wide glyphs (m, w) exceed the estimate
   entry = entry + font_size + GAP + self%key_sample(font_size) + GAP + self%key_extra * CHAR_WIDTH * font_size
   if (self%key_horizontal .and. grid(1) > 0_I4P) then
      ! as many columns as fit, at most `maxcols`
      grid(2) = max(1_I4P, min(grid(1), int((room + GAP) / entry, I4P)))
      if (self%key_maxcols > 0_I4P) grid(2) = min(grid(2), self%key_maxcols)
   elseif (self%key_maxrows > 0_I4P .and. grid(1) > self%key_maxrows) then
      ! a vertical key of `maxrows` rows: as many columns as needed, filled top down
      grid(2) = (grid(1) + self%key_maxrows - 1_I4P) / self%key_maxrows
   endif
   grid(3) = (grid(1) + grid(2) - 1_I4P) / grid(2)
   extent = [real(grid(2), R8P) * entry - GAP, real(grid(3), R8P) * self%key_spacing * LINE_HEIGHT * font_size + &
             self%key_height * font_size]
   ! a title: a row above the entries, the key at least as wide
   if (allocated(self%key_title)) then
      if (len(self%key_title) > 0) then
         extent(1) = max(extent(1), backend%text_width(self%key_title, '', font_size) + font_size)
         extent(2) = extent(2) + LINE_HEIGHT * font_size
      endif
   endif
   endsubroutine key_layout

   pure function key_sample(self, font_size) result(length)
   !< Length of a key sample [px]: `samplen` character widths, else 3 font sizes.
   class(axes_object), intent(in) :: self      !< Panel.
   real(R8P),          intent(in) :: font_size !< Font size [px].
   real(R8P)                      :: length    !< Length.

   length = SAMPLE_LENGTH * font_size
   if (self%key_samplen >= 0.0_R8P) length = self%key_samplen * CHAR_WIDTH * font_size
   endfunction key_sample

   pure function key_place(self) result(place)
   !< Where the key lies: `inside` the plot area, in the `left` or `right` margin, `top` (above the plot) or `bottom`
   !< (below it); outside and centred both ways it stays inside, as gnuplot.
   class(axes_object), intent(in) :: self  !< Panel.
   character(len=6)               :: place !< Place.

   place = 'inside'
   if (len_trim(self%key_margin) > 0) then
      place = self%key_margin
   elseif (self%key_outside) then
      if (trim(self%key_h) /= 'center') then
         place = self%key_h
      elseif (trim(self%key_v) /= 'center') then
         place = self%key_v
      endif
   endif
   endfunction key_place

   subroutine draw_series(self, backend, s, xaxis, yaxis, area, font_size)
   !< Draw the `s`-th series in the plot area against its axes `xaxis` and `yaxis`; unplaceable points (NaN, non-positive
   !< on log axes) break the line.
   class(axes_object),    intent(in)    :: self     !< Panel.
   class(backend_object), intent(inout) :: backend  !< Output device.
   integer(I4P),          intent(in)    :: s        !< Series index.
   type(axis_object),     intent(in)    :: xaxis    !< Horizontal axis of the series.
   type(axis_object),     intent(in)    :: yaxis    !< Vertical axis of the series.
   real(R8P),             intent(in)    :: area(4)  !< Plot area: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px], for the label offsets.
   logical, allocatable                 :: valid(:) !< Placeable points.
   logical, allocatable                 :: marked(:) !< Points marked (`pointinterval`).
   real(R8P), allocatable               :: u(:)     !< Unit abscissae.
   real(R8P), allocatable               :: v(:)     !< Unit ordinates.
   integer(I4P)                         :: n        !< Number of points.
   integer(I4P)                         :: i1       !< First point of a run.
   integer(I4P)                         :: i2       !< Last point of a run.
   integer(I4P)                         :: i        !< Point counter.

   associate(series => self%series(s))
      n = size(series%x, kind=I4P)
      valid = series%valid(xaxis, yaxis)
      allocate(u(n), v(n))
      u = 0.0_R8P
      v = 0.0_R8P
      where (valid)
         u = xaxis%to_unit(series%x)
         v = yaxis%to_unit(series%y)
      endwhere
      if (series%style%with == WITH_IMAGE) then
         call draw_image
         return
      endif
      if (series%style%with == WITH_CIRCLES) then
         call draw_circles
         return
      endif
      if (series%style%with == WITH_BOXES .or. series%style%with == WITH_HISTOGRAMS) call draw_boxes
      if (series%style%with == WITH_HISTOGRAMS .and. allocated(series%bounds)) call draw_histogram_bars
      if (series%style%with == WITH_BOXERRORBARS) then
         call draw_boxes
         call draw_box_bars
      endif
      if (series%style%with == WITH_BOXXYERROR) call draw_rectangles
      select case (series%style%with)
      case (WITH_VECTORS, WITH_ARROWS)
         call draw_arrows
      case (WITH_ELLIPSES)
         call draw_ellipses
      case (WITH_POLYGONS, WITH_SECTORS)
         call draw_polygons
      case (WITH_LABELS)
         call draw_labels
      endselect
      if (series%style%with == WITH_CANDLESTICKS .or. series%style%with == WITH_FINANCEBARS .or. &
          series%style%with == WITH_BOXPLOT) call draw_candles
      if (series%style%with == WITH_FILLEDCURVES) call draw_fill
      if (series%style%draws_lines()) then
         i1 = 1_I4P
         do while (i1 <= n)
            if (.not. valid(i1)) then
               i1 = i1 + 1_I4P
               cycle
            endif
            i2 = i1
            do while (i2 < n)
               if (.not. valid(i2 + 1_I4P)) exit
               i2 = i2 + 1_I4P
            enddo
            if (allocated(series%colors)) then
               ! lc variable: each segment in the color of its end point (gnuplot); `none` (an undefined palette
               ! value) draws nothing
               do i = i1, i2 - 1_I4P
                  if (series%colors(i + 1_I4P) == 'none') cycle
                  call backend%data_polyline(u(i:i + 1_I4P), v(i:i + 1_I4P), trim(series%colors(i + 1_I4P)), &
                                             series%style%linewidth, series%style%dasharray())
               enddo
            elseif (i2 > i1 .or. series%style%with == WITH_HISTEPS) then
               call draw_run(i1, i2)
            endif
            i1 = i2 + 1_I4P
         enddo
      endif
      if (series%style%with == WITH_IMPULSES) call draw_impulses
      if (series%style%draws_ybars()) call draw_bars(series%ylow, series%yhigh, yaxis, .true.)
      if (series%style%draws_xbars()) call draw_bars(series%xlow, series%xhigh, xaxis, .false.)
      if (series%style%draws_points() .and. any(valid)) then
         ! `pointinterval N`: a marker on the first point and every N-th after it
         marked = valid
         if (series%pointinterval > 1_I4P) marked = valid .and. [(mod(i1 - 1_I4P, series%pointinterval) == 0_I4P, &
                                                                  i1 = 1_I4P, n)]
         if (allocated(series%colors)) then
            ! lc variable: each point in its color, consecutive points of one color together
            i1 = 1_I4P
            do while (i1 <= n)
               i2 = i1
               do while (i2 < n)
                  if (series%colors(i2 + 1_I4P) /= series%colors(i1)) exit
                  i2 = i2 + 1_I4P
               enddo
               if (any(marked(i1:i2)) .and. series%colors(i1) /= 'none') &
                  call backend%data_dots(pack(u(i1:i2), marked(i1:i2)), pack(v(i1:i2), marked(i1:i2)), &
                                         trim(series%colors(i1)), series%style%point_diameter(), &
                                         pt=series%style%pointtype, line_width=series%style%linewidth)
               i1 = i2 + 1_I4P
            enddo
         else
            call backend%data_dots(pack(u, marked), pack(v, marked), series%style%color, series%style%point_diameter(), &
                                   pt=series%style%pointtype, line_width=series%style%linewidth)
         endif
      endif
   endassociate
   contains
      subroutine draw_run(i1, i2)
      !< The line through the run of placeable points `i1` to `i2`: straight segments, or the steps of `steps`
      !< (horizontal first), `fsteps` (vertical first), `histeps` (around the points, from and back to y = 0).
      integer(I4P), intent(in) :: i1    !< First point.
      integer(I4P), intent(in) :: i2    !< Last point.
      real(R8P), allocatable   :: pu(:) !< Vertex abscissae [unit].
      real(R8P), allocatable   :: pv(:) !< Vertex ordinates [unit].
      real(R8P)                :: v0    !< Unit ordinate of y = 0.
      integer(I4P)             :: k     !< Point counter.
      integer(I4P)             :: m     !< Points of the run.

      m = i2 - i1 + 1_I4P
      associate(series => self%series(s))
         select case (series%style%with)
         case (WITH_STEPS, WITH_FSTEPS)
            allocate(pu(2_I4P * m - 1_I4P), pv(2_I4P * m - 1_I4P))
            pu(1::2) = u(i1:i2)
            pv(1::2) = v(i1:i2)
            if (series%style%with == WITH_STEPS) then
               pu(2::2) = u(i1 + 1_I4P:i2)
               pv(2::2) = v(i1:i2 - 1_I4P)
            else
               pu(2::2) = u(i1:i2 - 1_I4P)
               pv(2::2) = v(i1 + 1_I4P:i2)
            endif
         case (WITH_HISTEPS)
            if (.not. (all(xaxis%accepts(series%xlow(i1:i2))) .and. all(xaxis%accepts(series%xhigh(i1:i2))))) &
               return
            v0 = -1.0_R8P
            if (yaxis%accepts(0.0_R8P)) v0 = yaxis%to_unit(0.0_R8P)
            allocate(pu(2_I4P * m + 2_I4P), pv(2_I4P * m + 2_I4P))
            do k = 1_I4P, m
               pu(2_I4P * k) = xaxis%to_unit(series%xlow(i1 + k - 1_I4P))
               pu(2_I4P * k + 1_I4P) = xaxis%to_unit(series%xhigh(i1 + k - 1_I4P))
               pv(2_I4P * k : 2_I4P * k + 1_I4P) = v(i1 + k - 1_I4P)
            enddo
            pu(1) = pu(2)
            pv(1) = v0
            pu(2_I4P * m + 2_I4P) = pu(2_I4P * m + 1_I4P)
            pv(2_I4P * m + 2_I4P) = v0
         case default
            pu = u(i1:i2)
            pv = v(i1:i2)
         endselect
         call backend%data_polyline(pu, pv, series%style%color, series%style%linewidth, series%style%dasharray())
      endassociate
      endsubroutine draw_run

      subroutine draw_arrows
      !< `vectors` from each placeable point to its tip; `arrows` of a length (> 0: x units, kept whatever the angle;
      !< in (-1, 0): a fraction of the plot width) and an angle [deg], as gnuplot.
      real(R8P), allocatable :: tu(:) !< Tip abscissae [unit].
      real(R8P), allocatable :: tv(:) !< Tip ordinates [unit].
      logical, allocatable   :: ok(:) !< Drawn arrows.
      real(R8P)              :: w     !< Plot width [px].
      real(R8P)              :: h     !< Plot height [px].
      real(R8P)              :: l     !< Arrow length [px].
      real(R8P)              :: a     !< Arrow angle [rad].
      integer(I4P)           :: i     !< Point counter.

      w = area(2) - area(1)
      h = area(4) - area(3)
      allocate(tu(n), tv(n), ok(n))
      tu = 0.0_R8P
      tv = 0.0_R8P
      associate(series => self%series(s))
         do i = 1_I4P, n
            ok(i) = valid(i) .and. ieee_is_finite(series%tips(1, i)) .and. ieee_is_finite(series%tips(2, i))
            if (.not. ok(i)) cycle
            if (series%style%with == WITH_VECTORS) then
               ok(i) = xaxis%accepts(series%tips(1, i)) .and. yaxis%accepts(series%tips(2, i))
               if (.not. ok(i)) cycle
               tu(i) = xaxis%to_unit(series%tips(1, i))
               tv(i) = yaxis%to_unit(series%tips(2, i))
            else
               l = series%tips(1, i)
               if (l > 0.0_R8P) then
                  l = l * w / abs(xaxis%hi - xaxis%lo)
               else
                  l = abs(l) * w
               endif
               a = series%tips(2, i) * (PI_R8 / 180.0_R8P)
               tu(i) = u(i) + l * cos(a) / w
               tv(i) = v(i) + l * sin(a) / h
            endif
         enddo
         if (any(ok)) call backend%data_arrows(pack(u, ok), pack(v, ok), pack(tu, ok), pack(tv, ok), series%style%color, &
                                               series%style%linewidth, series%head, series%head_filled)
      endassociate
      endsubroutine draw_arrows

      subroutine draw_ellipses
      !< An ellipse per placeable point, as gnuplot `units xy`: the major diameter in x units and the minor one in y units,
      !< converted to pixels, then rotated by its angle on the page; with no diameters, the default 5% x 3% of the plot
      !< area. (On log axes the diameters are taken at the centre.)
      real(R8P)    :: t(65)  !< Vertex parameters [rad].
      real(R8P)    :: ex(65) !< Vertex abscissae.
      real(R8P)    :: ey(65) !< Vertex ordinates.
      real(R8P)    :: phi    !< Angle [rad].
      real(R8P)    :: a      !< Semi-major axis [px].
      real(R8P)    :: b      !< Semi-minor axis [px].
      real(R8P)    :: w      !< Plot width [px].
      real(R8P)    :: h      !< Plot height [px].
      integer(I4P) :: k      !< Vertex counter.
      integer(I4P) :: i      !< Point counter.

      t = [(2.0_R8P * PI_R8 * real(k, R8P) / 64.0_R8P, k = 0_I4P, 64_I4P)]
      w = area(2) - area(1)
      h = area(4) - area(3)
      associate(series => self%series(s))
         do i = 1_I4P, n
            if (.not. valid(i)) cycle
            phi = series%shape(3, i) * (PI_R8 / 180.0_R8P)
            if (ieee_is_finite(series%shape(1, i))) then
               ! semi-axes in pixels: the unit extents of the diameters about the centre
               if (.not. (xaxis%accepts(series%x(i) + 0.5_R8P * series%shape(1, i)) .and. &
                          yaxis%accepts(series%y(i) + 0.5_R8P * series%shape(2, i)))) cycle
               a = abs(xaxis%to_unit(series%x(i) + 0.5_R8P * series%shape(1, i)) - u(i)) * w
               b = abs(yaxis%to_unit(series%y(i) + 0.5_R8P * series%shape(2, i)) - v(i)) * h
            else
               a = 0.025_R8P * w
               b = 0.015_R8P * h
            endif
            ex = u(i) + (a * cos(t) * cos(phi) - b * sin(t) * sin(phi)) / w
            ey = v(i) + (a * cos(t) * sin(phi) + b * sin(t) * cos(phi)) / h
            call backend%data_polygon(ex, ey, series%style%fill_color(), series%style%density, &
                                      series%style%stroke_color(), series%style%linewidth)
         enddo
      endassociate
      endsubroutine draw_ellipses

      subroutine draw_polygons
      !< `polygons` and `sectors`: each run of placeable points (blocks of the data, or the vertices of a sector) a
      !< closed polygon in the fill style.
      integer(I4P) :: i1 !< First point of a run.
      integer(I4P) :: i2 !< Last point of a run.

      associate(series => self%series(s))
         i1 = 1_I4P
         do while (i1 <= n)
            if (.not. valid(i1)) then
               i1 = i1 + 1_I4P
               cycle
            endif
            i2 = i1
            do while (i2 < n)
               if (.not. valid(i2 + 1_I4P)) exit
               i2 = i2 + 1_I4P
            enddo
            if (i2 > i1 + 1_I4P) call backend%data_polygon(u(i1:i2), v(i1:i2), series%style%fill_color(), &
                                                         series%style%density, series%style%stroke_color(), &
                                                         series%style%linewidth)
            i1 = i2 + 1_I4P
         enddo
      endassociate
      endsubroutine draw_polygons

      subroutine draw_labels
      !< The text of each placeable point at it, moved by the offset [characters]; its point marked if so set.
      character(len=:), allocatable :: color !< Text color.
      integer(I4P)                  :: i     !< Point counter.

      associate(series => self%series(s))
         color = FRAME_COLOR
         if (allocated(series%text_color)) color = series%text_color
         if (series%text_point .and. any(valid)) &
            call backend%data_dots(pack(u, valid), pack(v, valid), color, series%style%point_diameter(), &
                                   pt=series%style%pointtype, line_width=series%style%linewidth)
         do i = 1_I4P, n
            if (.not. valid(i)) cycle
            if (len_trim(series%texts(i)) == 0) cycle
            call backend%data_label(u(i), v(i), trim(series%texts(i)), trim(series%text_anchor), series%text_rotate, &
                                    color, series%text_offset(1) * 0.6_R8P * font_size, &
                                    -series%text_offset(2) * font_size + 0.35_R8P * font_size)
         enddo
      endassociate
      endsubroutine draw_labels

      subroutine draw_box_bars
      !< The y error bars of `boxerrorbars`, at the box centres.
      real(R8P), allocatable :: low(:)  !< Bar starts.
      real(R8P), allocatable :: high(:) !< Bar ends.

      ! local copies: gfortran 16 debug builds misread sections of components reached through the class dummy
      associate(series => self%series(s))
         low = series%bounds(1, :)
         high = series%bounds(2, :)
      endassociate
      call draw_bars(low, high, yaxis, .true.)
      endsubroutine draw_box_bars

      subroutine draw_rectangles
      !< `boxxyerror`: a rectangle from xlow to xhigh, ylow to yhigh per placeable point, in the fill style.
      integer(I4P) :: i !< Point counter.

      associate(series => self%series(s))
         do i = 1_I4P, n
            if (.not. valid(i)) cycle
            if (.not. (xaxis%accepts(series%xlow(i)) .and. xaxis%accepts(series%xhigh(i)) .and. &
                       yaxis%accepts(series%ylow(i)) .and. yaxis%accepts(series%yhigh(i)))) cycle
            call backend%data_polygon(xaxis%to_unit([series%xlow(i), series%xhigh(i), series%xhigh(i), &
                                                          series%xlow(i)]), &
                                      yaxis%to_unit([series%ylow(i), series%ylow(i), series%yhigh(i), series%yhigh(i)]), &
                                      series%style%fill_color(), series%style%density, series%style%stroke_color(), &
                                      series%style%linewidth)
         enddo
      endassociate
      endsubroutine draw_rectangles

      subroutine draw_candles
      !< `candlesticks` (and `boxplot` boxes): a box between the two `bounds` (open and close, the quartiles), whiskers
      !< from it to the low and high values (`ylow`, `yhigh`, swapped if reversed); its width from the box edges, else
      !< CAP_LENGTH pixels. With an empty fill, a candlestick whose close is below its open is filled, as gnuplot.
      !< Boxplots add capped whiskers, the median line and the outliers. `financebars` (and boxplots so styled): a line
      !< from low to high, a tick on the left at the open, one on the right at the close.
      real(R8P)                     :: ul      !< Box left [unit].
      real(R8P)                     :: ur      !< Box right [unit].
      real(R8P)                     :: b(2)    !< Box ends [unit].
      real(R8P)                     :: wv(2)   !< Whisker ends [unit].
      real(R8P)                     :: tick    !< Finance bar tick length [unit].
      real(R8P)                     :: c       !< Crossbar half width [unit].
      real(R8P)                     :: mw      !< Median line width [px].
      real(R8P)                     :: density !< Box fill opacity.
      character(len=:), allocatable :: fill    !< Box fill color.
      logical                       :: finance !< Drawn as a finance bar.
      integer(I4P)                  :: i       !< Point counter.

      tick = 0.5_R8P * self%errorbar_size * CAP_LENGTH / (area(2) - area(1))
      associate(series => self%series(s))
         finance = series%style%with == WITH_FINANCEBARS .or. &
                   (series%style%with == WITH_BOXPLOT .and. self%boxplot%financebars)
         do i = 1_I4P, n
            if (.not. valid(i)) cycle
            if (.not. (yaxis%accepts(series%bounds(1, i)) .and. yaxis%accepts(series%bounds(2, i)) .and. &
                       yaxis%accepts(series%ylow(i)) .and. yaxis%accepts(series%yhigh(i)))) cycle
            b = yaxis%to_unit(series%bounds(:, i))
            wv = yaxis%to_unit([min(series%ylow(i), series%yhigh(i)), max(series%ylow(i), series%yhigh(i))])
            if (finance) then
               call backend%data_polyline([u(i), u(i)], wv, series%style%color, series%style%linewidth, '')
               call backend%data_polyline([u(i) - tick, u(i)], [b(1), b(1)], series%style%color, &
                                          series%style%linewidth, '')
               call backend%data_polyline([u(i), u(i) + tick], [b(2), b(2)], series%style%color, &
                                          series%style%linewidth, '')
               if (series%style%with == WITH_BOXPLOT) &
                  call backend%data_polyline([u(i) - tick, u(i) + tick], [v(i), v(i)], series%style%color, &
                                             series%style%linewidth, '')
               cycle
            endif
            if (series%style%with == WITH_BOXPLOT) then
               ! the box: the middle third of the autoscale extent
               ul = xaxis%to_unit(series%x(i) - (series%x(i) - series%xlow(i)) / 3.0_R8P)
               ur = xaxis%to_unit(series%x(i) + (series%xhigh(i) - series%x(i)) / 3.0_R8P)
            elseif (allocated(series%xlow)) then
               if (.not. (xaxis%accepts(series%xlow(i)) .and. xaxis%accepts(series%xhigh(i)))) cycle
               ul = xaxis%to_unit(series%xlow(i))
               ur = xaxis%to_unit(series%xhigh(i))
            else
               ul = u(i) - tick
               ur = u(i) + tick
            endif
            fill = series%style%fill_color()
            density = series%style%density
            if (series%style%with == WITH_CANDLESTICKS .and. series%style%fill == FILL_EMPTY .and. &
                series%bounds(2, i) < series%bounds(1, i)) then
               fill = series%style%color
               density = 1.0_R8P
            endif
            call backend%data_polygon([ul, ur, ur, ul], [b(1), b(1), b(2), b(2)], fill, density, &
                                      series%style%stroke_color(), series%style%linewidth)
            if (series%style%with == WITH_BOXPLOT) then
               ! capped whiskers, as gnuplot's boxplots
               call backend%data_bars([u(i), u(i)], [minval(b), maxval(b)], [u(i), u(i)], wv, series%style%color, &
                                      series%style%linewidth, self%errorbar_size * CAP_LENGTH, .true.)
               mw = self%boxplot%median_width
               if (mw < 0.0_R8P) mw = series%style%linewidth
               if (mw > 0.0_R8P) call backend%data_polyline([ul, ur], [v(i), v(i)], series%style%color, mw, '')
            else
               call backend%data_polyline([u(i), u(i)], [minval(b), wv(1)], series%style%color, &
                                          series%style%linewidth, '')
               call backend%data_polyline([u(i), u(i)], [maxval(b), wv(2)], series%style%color, &
                                          series%style%linewidth, '')
               if (series%whiskerbars > 0.0_R8P) then
                  c = 0.5_R8P * series%whiskerbars * (ur - ul)
                  call backend%data_polyline([u(i) - c, u(i) + c], [wv(1), wv(1)], series%style%color, &
                                             series%style%linewidth, '')
                  call backend%data_polyline([u(i) - c, u(i) + c], [wv(2), wv(2)], series%style%color, &
                                             series%style%linewidth, '')
               endif
            endif
         enddo
         if (series%style%with == WITH_BOXPLOT .and. allocated(series%outliers)) call draw_outliers
      endassociate
      endsubroutine draw_candles

      subroutine draw_outliers
      !< The outliers of a boxplot, in the boxplot point type.
      real(R8P), allocatable :: ox(:) !< Outlier abscissae.
      real(R8P), allocatable :: oy(:) !< Outlier ordinates.
      logical, allocatable   :: ok(:) !< Placeable outliers.

      associate(series => self%series(s))
         ox = series%outliers(1, :)
         oy = series%outliers(2, :)
      endassociate
      ok = xaxis%accepts(ox) .and. yaxis%accepts(oy)
      if (.not. any(ok)) return
      associate(series => self%series(s))
         call backend%data_dots(xaxis%to_unit(pack(ox, ok)), yaxis%to_unit(pack(oy, ok)), series%style%color, &
                                series%style%point_diameter(), pt=self%boxplot%pointtype, &
                                line_width=series%style%linewidth)
      endassociate
      endsubroutine draw_outliers

      subroutine draw_impulses
      !< A segment from y = 0 (the axis bottom on a log axis) to each placeable point.
      real(R8P)    :: v0 !< Unit ordinate of y = 0.
      integer(I4P) :: i  !< Point counter.

      v0 = -1.0_R8P
      if (yaxis%accepts(0.0_R8P)) v0 = yaxis%to_unit(0.0_R8P)
      associate(series => self%series(s))
         do i = 1_I4P, n
            if (.not. valid(i)) cycle
            if (allocated(series%colors)) then
               if (series%colors(i) == 'none') cycle
               call backend%data_polyline([u(i), u(i)], [v0, v(i)], trim(series%colors(i)), series%style%linewidth, &
                                          series%style%dasharray())
            else
               call backend%data_polyline([u(i), u(i)], [v0, v(i)], series%style%color, series%style%linewidth, &
                                          series%style%dasharray())
            endif
         enddo
      endassociate
      endsubroutine draw_impulses

      subroutine draw_boxes
      !< One polygon per placeable box, from its baseline (0, or the axis bottom on a log axis) to its value; with
      !< `segments N`, the column of N cells over the y range, the ones the box covers at least half lit, the others
      !< ghosts.
      real(R8P) :: v0 !< Unit ordinate of the baseline.
      integer(I4P) :: i !< Box counter.

      associate(series => self%series(s))
         do i = 1_I4P, n
            if (.not. valid(i)) cycle
            if (.not. (xaxis%accepts(series%xlow(i)) .and. xaxis%accepts(series%xhigh(i)))) cycle
            v0 = -1.0_R8P
            if (yaxis%accepts(series%ylow(i))) v0 = yaxis%to_unit(series%ylow(i))
            if (series%style%segments > 0_I4P) then
               call draw_cells(xaxis%to_unit(series%xlow(i)), xaxis%to_unit(series%xhigh(i)), v0, v(i))
               cycle
            endif
            if (allocated(series%colors)) then
               ! a color per box (the rows of a column stack)
               block
                  type(style_object) :: row !< Style of the box.

                  row = series%style
                  row%color = trim(series%colors(i))
                  call backend%data_polygon([xaxis%to_unit(series%xlow(i)), xaxis%to_unit(series%xhigh(i)), &
                                             xaxis%to_unit(series%xhigh(i)), xaxis%to_unit(series%xlow(i))], &
                                            [v0, v0, v(i), v(i)], row%fill_color(), row%density, row%stroke_color(), &
                                            row%linewidth)
               endblock
               cycle
            endif
            call backend%data_polygon([xaxis%to_unit(series%xlow(i)), xaxis%to_unit(series%xhigh(i)), &
                                       xaxis%to_unit(series%xhigh(i)), xaxis%to_unit(series%xlow(i))], &
                                      [v0, v0, v(i), v(i)], series%style%fill_color(), series%style%density, &
                                      series%style%stroke_color(), series%style%linewidth)
         enddo
      endassociate
      endsubroutine draw_boxes

      subroutine draw_histogram_bars
      !< The error bars of `errorbars` histograms (their `bounds`), at the bar centres, in the series color (or the
      !< border color of the fill), `histogram_lw` wide if set.
      real(R8P), allocatable :: low(:)    !< Bar starts.
      real(R8P), allocatable :: high(:)   !< Bar ends.
      real(R8P), allocatable :: centre(:) !< Unit bar centres.
      logical, allocatable   :: ok(:)     !< Drawn bars.
      real(R8P)              :: width     !< Line width [px].

      associate(series => self%series(s))
         low = series%bounds(1, :)
         high = series%bounds(2, :)
         ok = valid .and. yaxis%accepts(low) .and. yaxis%accepts(high) .and. xaxis%accepts(series%xlow) .and. &
              xaxis%accepts(series%xhigh)
         if (.not. any(ok)) return
         centre = xaxis%to_unit(0.5_R8P * (pack(series%xlow, ok) + pack(series%xhigh, ok)))
         width = series%style%linewidth
         if (self%histogram_lw > 0.0_R8P) width = self%histogram_lw
         if (self%errorbar_lw > 0.0_R8P) width = self%errorbar_lw
         if (allocated(self%errorbar_color)) then
            call backend%data_bars(centre, yaxis%to_unit(pack(low, ok)), centre, yaxis%to_unit(pack(high, ok)), &
                                   self%errorbar_color, width, self%errorbar_size * CAP_LENGTH, .true.)
         elseif (series%style%stroke_color() == 'none') then
            call backend%data_bars(centre, yaxis%to_unit(pack(low, ok)), centre, yaxis%to_unit(pack(high, ok)), &
                                   series%style%color, width, self%errorbar_size * CAP_LENGTH, .true.)
         else
            call backend%data_bars(centre, yaxis%to_unit(pack(low, ok)), centre, yaxis%to_unit(pack(high, ok)), &
                                   series%style%stroke_color(), width, self%errorbar_size * CAP_LENGTH, .true.)
         endif
      endassociate
      endsubroutine draw_histogram_bars

      subroutine draw_circles
      !< Each placeable point a circle (or a wedge with its angles) round on the page: its radius in x units converted
      !< to pixels, then the outline back to the unit square of the plot area.
      real(R8P), allocatable :: px(:) !< Outline abscissae [px from the centre].
      real(R8P), allocatable :: py(:) !< Outline ordinates [px from the centre, upward].
      real(R8P)              :: r     !< Radius [px].
      real(R8P)              :: w     !< Plot area width [px].
      real(R8P)              :: h     !< Plot area height [px].
      integer(I4P)           :: i     !< Point counter.

      w = area(2) - area(1)
      h = area(4) - area(3)
      associate(series => self%series(s))
         do i = 1_I4P, n
            if (.not. valid(i)) cycle
            r = 0.02_R8P * w
            if (ieee_is_finite(series%radius(i))) then
               if (.not. xaxis%accepts(series%x(i) + series%radius(i))) cycle
               r = abs(xaxis%to_unit(series%x(i) + series%radius(i)) - u(i)) * w
            endif
            if (allocated(series%arcs)) then
               call outline(r, 0.0_R8P, series%arcs(1, i), series%arcs(2, i), px, py)
            else
               call outline(r, 0.0_R8P, 0.0_R8P, 360.0_R8P, px, py)
            endif
            call backend%data_polygon(u(i) + px / w, v(i) + py / h, series%style%fill_color(), series%style%density, &
                                      series%style%stroke_color(), series%style%linewidth)
         enddo
      endassociate
      endsubroutine draw_circles

      subroutine draw_image
      !< The image pixels in the palette colors over the color axis, undefined values transparent; reversed axes flip it.
      integer(I4P), allocatable :: rgba(:,:,:) !< Pixels, rows top to bottom.
      real(R8P)                 :: u(2)        !< Unit abscissae of the left and right edges.
      real(R8P)                 :: w(2)        !< Unit ordinates of the bottom and top edges.
      integer(I4P)              :: i           !< Column counter.
      integer(I4P)              :: j           !< Row counter.
      integer(I4P)              :: ii          !< Pixel column.
      integer(I4P)              :: jj          !< Pixel row, top to bottom.

      associate(series => self%series(s))
         if (.not. (all(xaxis%accepts(series%x)) .and. all(yaxis%accepts(series%y)))) return
         u = xaxis%to_unit(series%x)
         w = yaxis%to_unit(series%y)
         allocate(rgba(4, size(series%grid, 1), size(series%grid, 2)))
         do j = 1_I4P, size(series%grid, 2, kind=I4P)
            do i = 1_I4P, size(series%grid, 1, kind=I4P)
               ii = i
               if (u(1) > u(2)) ii = size(series%grid, 1, kind=I4P) - i + 1_I4P
               jj = size(series%grid, 2, kind=I4P) - j + 1_I4P
               if (w(1) > w(2)) jj = j
               if (allocated(series%channels)) then
                  ! RGB colors, an undefined channel making the pixel transparent
                  if (all(ieee_is_finite(series%channels(:, i, j)))) then
                     rgba(:, ii, jj) = nint(min(255.0_R8P, max(0.0_R8P, series%channels(:, i, j))), I4P)
                  else
                     rgba(:, ii, jj) = 0_I4P
                  endif
               else
                  rgba(:, ii, jj) = pixel(series%grid(i, j))
               endif
            enddo
         enddo
         call backend%data_image(minval(u), minval(w), maxval(u), maxval(w), rgba)
      endassociate
      endsubroutine draw_image

      function pixel(value) result(c)
      !< RGBA of `value` in the palette over the color axis; transparent if undefined.
      real(R8P), intent(in) :: value !< Value.
      integer(I4P)          :: c(4)  !< Pixel.
      type(palette_object)  :: p     !< Effective palette.

      c = 0_I4P
      if (.not. ieee_is_finite(value)) return
      p = effective_palette(self%palette, backend%theme%name)
      if (self%cbaxis%log .and. value <= 0.0_R8P) then
         ! no logarithm: the low end of the color axis, as gnuplot
         c(1:3) = p%rgb(merge(0.0_R8P, 1.0_R8P, self%cbaxis%lo < self%cbaxis%hi))
      else
         c(1:3) = p%rgb(self%cbaxis%to_unit(value))
      endif
      c(4) = 255_I4P
      endfunction pixel

      subroutine draw_cells(u1, u2, v0, v1)
      !< The cells of a segmented column between `u1` and `u2`: N cells over the unit height, each inset by an eighth of
      !< its height top and bottom and a tenth of the column on each side (touching boxes stay apart columns); lit when
      !< the box from `v0` to `v1` covers at least half of it, else a ghost.
      real(R8P), intent(in) :: u1   !< Column left [unit].
      real(R8P), intent(in) :: u2   !< Column right [unit].
      real(R8P), intent(in) :: v0   !< Box base [unit].
      real(R8P), intent(in) :: v1   !< Box top [unit].
      real(R8P)             :: h    !< Cell height [unit].
      real(R8P)             :: c0   !< Cell bottom [unit].
      real(R8P)             :: c1   !< Cell top [unit].
      real(R8P)             :: inset !< Cell inset, top and bottom [unit].
      real(R8P)             :: a    !< Cell left [unit].
      real(R8P)             :: b    !< Cell right [unit].
      integer(I4P)          :: c    !< Cell counter.

      associate(series => self%series(s))
         h = 1.0_R8P / real(series%style%segments, R8P)
         inset = 0.125_R8P * h
         a = u1 + 0.1_R8P * (u2 - u1)
         b = u2 - 0.1_R8P * (u2 - u1)
         do c = 0_I4P, series%style%segments - 1_I4P
            c0 = real(c, R8P) * h
            c1 = c0 + h
            if (min(max(v0, v1), c1) - max(min(v0, v1), c0) >= 0.5_R8P * h) then
               call backend%data_polygon([a, b, b, a], [c0 + inset, c0 + inset, c1 - inset, c1 - inset], &
                                         series%style%fill_color(), series%style%density, series%style%stroke_color(), &
                                         series%style%linewidth)
            else
               call backend%data_polygon([a, b, b, a], [c0 + inset, c0 + inset, c1 - inset, c1 - inset], &
                                         series%style%color, 1.0_R8P, 'none', 0.0_R8P, ghost=.true.)
            endif
         enddo
      endassociate
      endsubroutine draw_cells

      subroutine draw_fill
      !< One polygon per run of placeable points: the curve and back along its baseline (a line, the lower curve of a
      !< band, the bottom or top of the plot), or the curve closed on itself, or closed on a point; `above` and `below`
      !< keep the parts where the curve is above or below the baseline, the crossings inserted.
      logical, allocatable   :: ok(:)  !< Points placeable with their lower end.
      real(R8P), allocatable :: w(:)   !< Unit ordinates of the baseline.
      real(R8P), allocatable :: pu(:)  !< Run abscissae, crossings inserted [unit].
      real(R8P), allocatable :: pv(:)  !< Run ordinates [unit].
      real(R8P), allocatable :: pw(:)  !< Run baseline [unit].
      real(R8P)              :: p(2)   !< Point of `xy=` [unit].
      real(R8P)              :: t      !< Crossing parameter.
      integer(I4P)           :: a      !< First point of a run.
      integer(I4P)           :: b      !< Last point of a run.
      integer(I4P)           :: k      !< Point counter.
      logical                :: based  !< Filled to a baseline.

      associate(series => self%series(s))
         ok = valid
         allocate(w(n))
         w = 0.0_R8P
         based = allocated(series%ylow) .or. series%curve_to == 1_I4P .or. series%curve_to == 2_I4P
         ! to a vertical line: the left (y1) or right (y2) border, or x = V
         if (series%curve_to >= 4_I4P) then
            select case (series%curve_to)
            case (4_I4P)
               p(1) = 0.0_R8P
            case (5_I4P)
               p(1) = 1.0_R8P
            case default
               if (.not. xaxis%accepts(series%curve_point(1))) return
               p(1) = xaxis%to_unit(series%curve_point(1))
            endselect
         endif
         if (allocated(series%ylow)) then
            ok = ok .and. yaxis%accepts(series%ylow)
            where (ok) w = yaxis%to_unit(series%ylow)
         elseif (series%curve_to == 2_I4P) then
            w = 1.0_R8P
         endif
         if (series%curve_to == 3_I4P) then
            if (.not. (xaxis%accepts(series%curve_point(1)) .and. yaxis%accepts(series%curve_point(2)))) return
            p = [xaxis%to_unit(series%curve_point(1)), yaxis%to_unit(series%curve_point(2))]
         endif
         a = 1_I4P
         do while (a <= n)
            if (.not. ok(a)) then
               a = a + 1_I4P
               cycle
            endif
            b = a
            do while (b < n)
               if (.not. ok(b + 1_I4P)) exit
               b = b + 1_I4P
            enddo
            if (b > a) then
               if (based) then
                  ! the run with the crossings of its baseline, then each side kept or flattened onto the baseline
                  pu = [u(a)]
                  pv = [v(a)]
                  pw = [w(a)]
                  do k = a, b - 1_I4P
                     if (series%curve_side /= 0_I4P .and. (v(k) - w(k)) * (v(k + 1_I4P) - w(k + 1_I4P)) < 0.0_R8P) then
                        t = (v(k) - w(k)) / ((v(k) - w(k)) - (v(k + 1_I4P) - w(k + 1_I4P)))
                        pu = [pu, u(k) + t * (u(k + 1_I4P) - u(k))]
                        pw = [pw, w(k) + t * (w(k + 1_I4P) - w(k))]
                        pv = [pv, pw(size(pw))]
                     endif
                     pu = [pu, u(k + 1_I4P)]
                     pv = [pv, v(k + 1_I4P)]
                     pw = [pw, w(k + 1_I4P)]
                  enddo
                  if (series%curve_side > 0_I4P) pv = max(pv, pw)
                  if (series%curve_side < 0_I4P) pv = min(pv, pw)
                  call backend%data_polygon([pu, pu(size(pu):1:-1)], [pv, pw(size(pw):1:-1)], &
                                            series%style%fill_color(), series%style%density, 'none', 0.0_R8P)
               elseif (series%curve_to == 3_I4P) then
                  call backend%data_polygon([u(a:b), p(1)], [v(a:b), p(2)], series%style%fill_color(), &
                                            series%style%density, 'none', 0.0_R8P)
               elseif (series%curve_to >= 4_I4P) then
                  call backend%data_polygon([u(a:b), p(1), p(1)], [v(a:b), v(b), v(a)], series%style%fill_color(), &
                                            series%style%density, 'none', 0.0_R8P)
               else
                  call backend%data_polygon(u(a:b), v(a:b), series%style%fill_color(), series%style%density, 'none', &
                                            0.0_R8P)
               endif
            endif
            a = b + 1_I4P
         enddo
      endassociate
      endsubroutine draw_fill

      subroutine draw_bars(low, high, axis, vertical)
      !< Error bars of the placeable points whose both ends are placeable on `axis`.
      real(R8P),         intent(in) :: low(:)   !< Bar starts.
      real(R8P),         intent(in) :: high(:)  !< Bar ends.
      type(axis_object), intent(in) :: axis     !< Axis of the bars.
      logical,           intent(in) :: vertical !< Vertical bars.
      logical, allocatable          :: ok(:)    !< Drawn bars.
      real(R8P), allocatable        :: a(:)     !< Unit bar starts.
      real(R8P), allocatable        :: b(:)     !< Unit bar ends.
      character(len=:), allocatable :: color    !< Bar color.
      real(R8P)                     :: width    !< Bar width [px].

      ok = valid .and. axis%accepts(low) .and. axis%accepts(high)
      if (.not. any(ok)) return
      a = axis%to_unit(pack(low, ok))
      b = axis%to_unit(pack(high, ok))
      associate(series => self%series(s))
         ! `set errorbars`: the cap length, the line
         color = series%style%color
         if (allocated(self%errorbar_color)) color = self%errorbar_color
         width = series%style%linewidth
         if (self%errorbar_lw > 0.0_R8P) width = self%errorbar_lw
         if (vertical) then
            call backend%data_bars(pack(u, ok), a, pack(u, ok), b, color, width, self%errorbar_size * CAP_LENGTH, .true.)
         else
            call backend%data_bars(a, pack(v, ok), b, pack(v, ok), color, width, self%errorbar_size * CAP_LENGTH, .false.)
         endif
      endassociate
      endsubroutine draw_bars
   endsubroutine draw_series

   pure subroutine outline(r, r_in, a1, a2, px, py)
   !< Outline of a circle (radius `r`, from `a1` to `a2` covering 360 degrees and no hole), a wedge (from the centre
   !< along the arc from `a1` to `a2` [deg, counterclockwise]) or, with a hole of radius `r_in`, a ring sector: the
   !< vertices relative to the centre [same unit as `r`, y upward]; arcs sampled every 360/64 degrees at most.
   real(R8P),              intent(in)  :: r     !< Radius.
   real(R8P),              intent(in)  :: r_in  !< Hole radius, 0 for none.
   real(R8P),              intent(in)  :: a1    !< Start angle [deg].
   real(R8P),              intent(in)  :: a2    !< End angle [deg]; below `a1`: one more turn, as gnuplot.
   real(R8P), allocatable, intent(out) :: px(:) !< Vertex abscissae.
   real(R8P), allocatable, intent(out) :: py(:) !< Vertex ordinates.
   real(R8P), parameter                :: DEG = 4.0_R8P * atan(1.0_R8P) / 180.0_R8P !< Degrees to radians.
   real(R8P)                           :: b     !< End angle, after `a1`.
   real(R8P), allocatable              :: t(:)  !< Arc angles [rad].
   integer(I4P)                        :: m     !< Arc steps.
   integer(I4P)                        :: k     !< Counter.

   b = a2
   if (b < a1) b = b + 360.0_R8P
   if (b - a1 >= 360.0_R8P .and. r_in <= 0.0_R8P) then
      allocate(t(64))
      t = [(real(k, R8P) * 360.0_R8P / 64.0_R8P * DEG, k = 0, 63)]
      px = r * cos(t)
      py = r * sin(t)
      return
   endif
   m = max(2_I4P, ceiling((b - a1) / (360.0_R8P / 64.0_R8P), I4P))
   t = [((a1 + (b - a1) * real(k, R8P) / real(m, R8P)) * DEG, k = 0, m)]
   if (r_in > 0.0_R8P) then
      px = [r * cos(t), r_in * cos(t(m + 1:1:-1))]
      py = [r * sin(t), r_in * sin(t(m + 1:1:-1))]
   else
      px = [0.0_R8P, r * cos(t)]
      py = [0.0_R8P, r * sin(t)]
   endif
   endsubroutine outline

   pure subroutine image_range(all, zmin, zmax, found, positive)
   !< Range of the finite values (the positive ones with `positive`, for a log color axis) of the images among the
   !< series `all`, and of the `lc palette z` values. A module procedure on the series array, as `layout_histograms`:
   !< gfortran 16 debug builds misread
   !< `self%series(s)%grid` through the class dummy.
   type(series_object), intent(in)  :: all(:)   !< Series of the panel.
   real(R8P),           intent(out) :: zmin     !< Smallest value.
   real(R8P),           intent(out) :: zmax     !< Largest value.
   logical,             intent(out) :: found    !< Any finite value.
   logical,             intent(in)  :: positive !< Positive values only.
   integer(I4P)                     :: s      !< Series counter.
   integer(I4P)                     :: i      !< Column counter.
   integer(I4P)                     :: j      !< Row counter.

   zmin = huge(1.0_R8P)
   zmax = -huge(1.0_R8P)
   found = .false.
   do s = 1_I4P, size(all, kind=I4P)
      if (all(s)%palette_mode == 1_I4P .and. allocated(all(s)%zvalues)) then
         ! lc palette z: the values of the points
         do i = 1_I4P, size(all(s)%zvalues, kind=I4P)
            if (.not. ieee_is_finite(all(s)%zvalues(i))) cycle
            if (positive .and. all(s)%zvalues(i) <= 0.0_R8P) cycle
            found = .true.
            zmin = min(zmin, all(s)%zvalues(i))
            zmax = max(zmax, all(s)%zvalues(i))
         enddo
      endif
      if (all(s)%style%with /= WITH_IMAGE .or. allocated(all(s)%channels)) cycle
      do j = 1_I4P, size(all(s)%grid, 2, kind=I4P)
         do i = 1_I4P, size(all(s)%grid, 1, kind=I4P)
            if (.not. ieee_is_finite(all(s)%grid(i, j))) cycle
            if (positive .and. all(s)%grid(i, j) <= 0.0_R8P) cycle
            found = .true.
            zmin = min(zmin, all(s)%grid(i, j))
            zmax = max(zmax, all(s)%grid(i, j))
         enddo
      enddo
   enddo
   endsubroutine image_range

   subroutine layout_histograms(all, mode, gap, boxwidth, linecolors)
   !< Bars of every histogram series of `all` from their `values`, group by group (gnuplot `newhistogram`): the first
   !< group from its rows (or `at`), each next one 2 rows after the last of the previous one (or `at`), as gnuplot.
   !< Within a group: clustered (and errorbars) side by side in each row, 1/(k + gap) wide for k series; stacked by row
   !< (positive values up from 0, negative ones down, each sign on its own stack); or one stack per series
   !< (columnstacked), its rows stacked, each row in its linetype color. A module procedure on the series array, not
   !< a binding: gfortran 16 corrupts the descriptor of `self%series` reached through the class dummy after its
   !< reallocation by `add_series`.
   type(series_object), intent(inout)        :: all(:)        !< Series of the panel.
   integer(I4P),        intent(in)           :: mode          !< HIST_CLUSTERED, HIST_ROWSTACKED, ...
   real(R8P),           intent(in)           :: gap           !< Gap between clusters [bar slots].
   real(R8P),           intent(in)           :: boxwidth      !< Bar width factor, 0 for 1.
   character(len=7),    intent(in), optional :: linecolors(:) !< Linetype colors (`set colorsequence`).
   real(R8P), allocatable             :: up(:)      !< Top of the positive stack of each row.
   real(R8P), allocatable             :: down(:)    !< Bottom of the negative stack of each row.
   real(R8P)                          :: slot       !< Clustered slot width.
   real(R8P)                          :: scale      !< Bar width factor.
   real(R8P)                          :: centre     !< Bar centre offset from its row.
   real(R8P)                          :: start      !< Start of the current group.
   real(R8P)                          :: last       !< Last row (or stack) of the previous group.
   real(R8P)                          :: rows       !< Last row of the group.
   integer(I4P)                       :: k          !< Histogram series of the group.
   integer(I4P)                       :: j          !< Histogram series counter in the group.
   integer(I4P)                       :: s          !< Series counter.
   integer(I4P)                       :: i          !< Row counter.
   integer(I4P)                       :: n          !< Rows.
   integer(I4P)                       :: g          !< Group.
   integer(I4P)                       :: first      !< First series of the group.
   logical                            :: started    !< A group laid out.

   scale = 1.0_R8P
   if (boxwidth > 0.0_R8P) scale = boxwidth
   started = .false.
   last = 0.0_R8P
   s = 1_I4P
   do while (s <= size(all, kind=I4P))
      if (all(s)%style%with /= WITH_HISTOGRAMS) then
         s = s + 1_I4P
         cycle
      endif
      ! the group of series s: its series, rows, start
      g = all(s)%hist_group
      first = s
      k = 0_I4P
      n = 0_I4P
      rows = 0.0_R8P
      do i = first, size(all, kind=I4P)
         if (all(i)%style%with /= WITH_HISTOGRAMS) cycle
         if (all(i)%hist_group /= g) cycle
         k = k + 1_I4P
         n = max(n, size(all(i)%values, kind=I4P))
         ! the rows as given, kept: the layout is redone at every histogram added
         if (.not. allocated(all(i)%rows)) all(i)%rows = all(i)%x
         if (any(ieee_is_finite(all(i)%rows))) rows = max(rows, maxval(all(i)%rows, mask=ieee_is_finite(all(i)%rows)))
      enddo
      if (all(first)%hist_at_set) then
         start = all(first)%hist_at
      elseif (started) then
         start = last + 2.0_R8P
      else
         start = 0.0_R8P
      endif
      if (allocated(up)) deallocate(up, down)
      allocate(up(n), down(n))
      up = 0.0_R8P
      down = 0.0_R8P
      slot = 1.0_R8P / (real(k, R8P) + gap)
      j = 0_I4P
      do i = first, size(all, kind=I4P)
         if (all(i)%style%with /= WITH_HISTOGRAMS) cycle
         if (all(i)%hist_group /= g) cycle
         j = j + 1_I4P
         call lay(all(i), j)
      enddo
      if (mode == HIST_COLUMNSTACKED) then
         last = start + real(k - 1_I4P, R8P)
      else
         last = start + rows
      endif
      started = .true.
      ! the next group
      s = first + 1_I4P
      do while (s <= size(all, kind=I4P))
         if (all(s)%style%with == WITH_HISTOGRAMS) then
            if (all(s)%hist_group /= g) exit
         endif
         s = s + 1_I4P
      enddo
   enddo
   contains
      subroutine lay(series, j)
      !< The bars of `series`, the `j`-th of its group.
      type(series_object), intent(inout) :: series !< Histogram series.
      integer(I4P),        intent(in)    :: j      !< Rank in the group.
      integer(I4P)                       :: m      !< Rows of the series.
      integer(I4P)                       :: r      !< Row counter.

      m = size(series%values, kind=I4P)
      if (allocated(series%xlow)) deallocate(series%xlow)
      if (allocated(series%xhigh)) deallocate(series%xhigh)
      if (allocated(series%ylow)) deallocate(series%ylow)
      if (allocated(series%colors)) deallocate(series%colors)
      allocate(series%xlow(m), series%xhigh(m), series%ylow(m))
      select case (mode)
      case (HIST_ROWSTACKED)
         do r = 1_I4P, m
            series%x(r) = start + series%rows(r)
            series%xlow(r) = series%x(r) - 0.5_R8P * scale
            series%xhigh(r) = series%x(r) + 0.5_R8P * scale
            call stack(series, r, r)
         enddo
      case (HIST_COLUMNSTACKED)
         ! one stack, each row in the color of its linetype
         allocate(series%colors(m))
         up = 0.0_R8P
         down = 0.0_R8P
         do r = 1_I4P, m
            series%x(r) = start + real(j - 1_I4P, R8P)
            series%xlow(r) = series%x(r) - 0.5_R8P * scale
            series%xhigh(r) = series%x(r) + 0.5_R8P * scale
            series%colors(r) = default_color(r, linecolors)
            call stack(series, r, 1_I4P)
         enddo
      case default
         centre = (real(j, R8P) - 0.5_R8P * real(k + 1_I4P, R8P)) * slot
         do r = 1_I4P, m
            series%x(r) = start + series%rows(r)
            series%xlow(r) = series%x(r) + centre - 0.5_R8P * slot * scale
            series%xhigh(r) = series%x(r) + centre + 0.5_R8P * slot * scale
            series%ylow(r) = 0.0_R8P
            series%y(r) = series%values(r)
         enddo
      endselect
      endsubroutine lay

      subroutine stack(series, r, p)
      !< Row `r` of `series` on the stack `p` (its positive or negative part).
      type(series_object), intent(inout) :: series !< Histogram series.
      integer(I4P),        intent(in)    :: r      !< Row.
      integer(I4P),        intent(in)    :: p      !< Stack.

      series%ylow(r) = 0.0_R8P
      series%y(r) = series%values(r)
      if (.not. ieee_is_finite(series%values(r))) return
      if (series%values(r) >= 0.0_R8P) then
         series%ylow(r) = up(p)
         up(p) = up(p) + series%values(r)
         series%y(r) = up(p)
      else
         series%ylow(r) = down(p)
         down(p) = down(p) + series%values(r)
         series%y(r) = down(p)
      endif
      endsubroutine stack
   endsubroutine layout_histograms

   subroutine draw_pie(self, backend, box, font_size)
   !< A pie panel in the box (left, right, top, bottom) [px]: the slices of the values, from 12 o'clock clockwise in the
   !< linetype colors, a hole of the donut fraction of the radius; the key at the right, an entry per slice with its
   !< label and percentage.
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: box(4)    !< Box: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   character(len=:), allocatable        :: labels(:) !< Key entries.
   real(R8P), allocatable               :: px(:)     !< Slice outline [px from the centre].
   real(R8P), allocatable               :: py(:)     !< Slice outline [px from the centre, upward].
   real(R8P)                            :: total     !< Sum of the values.
   real(R8P)                            :: start     !< Slice start angle [deg].
   real(R8P)                            :: span      !< Slice angle [deg].
   real(R8P)                            :: key_width !< Key width [px].
   real(R8P)                            :: centre(2) !< Pie centre [px].
   real(R8P)                            :: r         !< Pie radius [px].
   real(R8P)                            :: yk        !< Key row centre [px].
   integer(I4P)                         :: k         !< Slice counter.
   integer(I4P)                         :: m         !< Slices.

   associate(series => self%series(1))
      m = size(series%values, kind=I4P)
      total = sum(series%values, mask=ieee_is_finite(series%values))
      allocate(character(len=64) :: labels(m))
      key_width = 0.0_R8P
      do k = 1_I4P, m
         labels(k) = ''
         if (allocated(series%xlabels)) labels(k) = trim(series%xlabels(k))
         if (total > 0.0_R8P .and. ieee_is_finite(series%values(k))) &
            labels(k) = trim(labels(k))//' '//int_str(int(nint(100.0_R8P * series%values(k) / total), I8P))//'%'
         labels(k) = adjustl(labels(k))
         key_width = max(key_width, backend%text_width(trim(labels(k)), '', font_size))
      enddo
      key_width = key_width + font_size + GAP + SAMPLE_LENGTH * font_size + GAP
      if (.not. self%key) key_width = 0.0_R8P
      r = 0.45_R8P * min(box(2) - box(1) - key_width, box(4) - box(3))
      centre = [0.5_R8P * (box(1) + box(2) - key_width), 0.5_R8P * (box(3) + box(4))]
      call backend%begin_group('fs-pie')
      if (total > 0.0_R8P .and. r > 0.0_R8P) then
         start = 90.0_R8P
         do k = 1_I4P, m
            if (.not. ieee_is_finite(series%values(k))) cycle
            span = 360.0_R8P * series%values(k) / total
            if (span <= 0.0_R8P) cycle
            call outline(r, series%donut * r, start - span, start, px, py)
            call backend%polygon(centre(1) + px, centre(2) - py, slice_color(k), series%style%density, &
                                 merge('white', 'none ', series%style%border), 1.0_R8P)
            start = start - span
         enddo
      endif
      if (self%key) then
         do k = 1_I4P, m
            yk = box(3) + GAP + (real(k, R8P) - 0.5_R8P) * LINE_HEIGHT * font_size
            call backend%polygon([box(2) - SAMPLE_LENGTH * font_size, box(2), box(2), box(2) - SAMPLE_LENGTH * font_size], &
                                 [yk + 0.35_R8P * font_size, yk + 0.35_R8P * font_size, yk - 0.35_R8P * font_size, &
                                  yk - 0.35_R8P * font_size], slice_color(k), series%style%density, 'none', 0.0_R8P)
            call backend%text(box(2) - SAMPLE_LENGTH * font_size - GAP, yk + 0.35_R8P * font_size, trim(labels(k)), 'end')
         enddo
      endif
      call backend%end_group
   endassociate
   contains
      pure function slice_color(k) result(color)
      !< Color of the `k`-th slice: the linetype color `k`.
      integer(I4P), intent(in)      :: k     !< Slice.
      character(len=:), allocatable :: color !< SVG color.

      color = default_color(k, self%linecolors)
      endfunction slice_color
   endsubroutine draw_pie

   subroutine draw_gauges(self, backend, box, font_size)
   !< Gauges side by side in the box (left, right, top, bottom) [px], one per series: a track of 270 degrees from 7:30
   !< clockwise to 4:30, faint, lit from its start to the last finite value over the gauge scale (in `segments` cells
   !< if set, a cell lit when covered at least half); the scale ticks outside, the value in seven-segment digits under
   !< the centre, titled by the series.
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: box(4)    !< Box: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   real(R8P), parameter                 :: START = 225.0_R8P !< Sweep start [deg, counterclockwise from 3 o'clock].
   real(R8P), parameter                 :: SWEEP = 270.0_R8P !< Sweep [deg], clockwise.
   real(R8P), parameter                 :: DEG = 4.0_R8P * atan(1.0_R8P) / 180.0_R8P !< Degrees to radians.
   type(tick_object), allocatable       :: ticks(:)  !< Scale ticks.
   integer(I4P), allocatable            :: masks(:)  !< Digit cells.
   character(len=:), allocatable        :: prefix    !< Text before the digits.
   character(len=:), allocatable        :: suffix    !< Text after the digits.
   real(R8P), allocatable               :: px(:)     !< Outline [px from the centre].
   real(R8P), allocatable               :: py(:)     !< Outline [px from the centre, upward].
   real(R8P)                            :: cell      !< Width of a gauge [px].
   real(R8P)                            :: r         !< Track outer radius [px].
   real(R8P)                            :: c(2)      !< Gauge centre [px].
   real(R8P)                            :: t         !< Lit fraction of the sweep.
   real(R8P)                            :: value     !< Reading.
   real(R8P)                            :: a         !< Angle [deg].
   real(R8P)                            :: lo        !< Scale start.
   real(R8P)                            :: hi        !< Scale end.
   real(R8P)                            :: ext(2)    !< Digits size [px].
   real(R8P)                            :: hd        !< Digit height [px].
   real(R8P)                            :: gap       !< Gap between cells [deg].
   integer(I4P)                         :: g         !< Gauge counter.
   integer(I4P)                         :: k         !< Counter.

   cell = (box(2) - box(1)) / real(size(self%series), R8P)
   r = min(0.36_R8P * cell, (box(4) - box(3)) / 2.6_R8P)
   call backend%begin_group('fs-gauges')
   do g = 1_I4P, size(self%series, kind=I4P)
      associate(series => self%series(g))
         c = [box(1) + (real(g, R8P) - 0.5_R8P) * cell, box(3) + 1.35_R8P * r]
         lo = series%scale(1)
         hi = series%scale(2)
         value = last_finite(series%y)
         t = 0.0_R8P
         if (ieee_is_finite(value)) t = min(1.0_R8P, max(0.0_R8P, (value - lo) / (hi - lo)))
         if (series%style%segments > 0_I4P) then
            gap = 0.08_R8P * SWEEP / real(series%style%segments, R8P)
            do k = 0_I4P, series%style%segments - 1_I4P
               call outline(r, 0.78_R8P * r, START - SWEEP * real(k + 1_I4P, R8P) / real(series%style%segments, R8P) + gap, &
                            START - SWEEP * real(k, R8P) / real(series%style%segments, R8P) - gap, px, py)
               if (t * real(series%style%segments, R8P) >= real(k, R8P) + 0.5_R8P) then
                  call backend%polygon(c(1) + px, c(2) - py, series%style%fill_color(), series%style%density, 'none', &
                                       0.0_R8P)
               else
                  call backend%polygon(c(1) + px, c(2) - py, series%style%color, 1.0_R8P, 'none', 0.0_R8P, ghost=.true.)
               endif
            enddo
         else
            call outline(r, 0.78_R8P * r, START - SWEEP, START, px, py)
            call backend%polygon(c(1) + px, c(2) - py, series%style%color, 1.0_R8P, 'none', 0.0_R8P, ghost=.true.)
            if (t > 0.0_R8P) then
               call outline(r, 0.78_R8P * r, START - SWEEP * t, START, px, py)
               call backend%polygon(c(1) + px, c(2) - py, series%style%fill_color(), series%style%density, 'none', 0.0_R8P)
            endif
         endif
         ! the scale: ticks outside the track, never extended beyond its ends
         a = min(lo, hi)
         t = max(lo, hi)
         call linear_ticks(a, t, SWEEP * DEG * r, .false., .false., ticks)
         do k = 1_I4P, size(ticks, kind=I4P)
            a = (START - SWEEP * (ticks(k)%value - lo) / (hi - lo)) * DEG
            call backend%polyline([c(1) + 1.03_R8P * r * cos(a), c(1) + 1.12_R8P * r * cos(a)], &
                                  [c(2) - 1.03_R8P * r * sin(a), c(2) - 1.12_R8P * r * sin(a)], FRAME_COLOR, 1.0_R8P, '')
            call backend%text(c(1) + 1.3_R8P * r * cos(a), c(2) - 1.3_R8P * r * sin(a) + 0.35_R8P * font_size, &
                              ticks(k)%label, 'middle', sup=ticks(k)%sup)
         enddo
         ! the reading in digits under the centre, titled by the series
         call readout_glass(series%format, value, masks, prefix, suffix)
         hd = max(font_size, 0.24_R8P * r)
         ext = backend%readout_extent(hd, size(masks, kind=I4P), series%title, prefix, suffix, font_size)
         call backend%readout(c(1) - 0.5_R8P * ext(1), c(2) - 0.15_R8P * r, hd, masks, series%title, prefix, suffix, &
                              series%style%color, font_size)
      endassociate
   enddo
   call backend%end_group
   endsubroutine draw_gauges

   subroutine draw_radar(self, backend, box, font_size)
   !< A radar (spider) chart in the box (left, right, top, bottom) [px]: a spoke per row, from 12 o'clock clockwise,
   !< named by the `xtic` labels of the first series having them; rings at the ticks of the common radial scale (from 0,
   !< or the smallest value if negative, extended to a tick); a polygon per series; the key at the right.
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: box(4)    !< Box: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   real(R8P), parameter                 :: DEG = 4.0_R8P * atan(1.0_R8P) / 180.0_R8P !< Degrees to radians.
   type(tick_object), allocatable       :: ticks(:)  !< Radial ticks.
   character(len=:), allocatable        :: names(:)  !< Spoke names.
   character(len=:), allocatable        :: labels(:) !< Key entries.
   character(len=:), allocatable        :: colors(:) !< Key colors.
   real(R8P), allocatable               :: rx(:)     !< Polygon abscissae [px].
   real(R8P), allocatable               :: ry(:)     !< Polygon ordinates [px].
   real(R8P)                            :: lo        !< Radial scale start.
   real(R8P)                            :: hi        !< Radial scale end.
   real(R8P)                            :: key_width !< Key width [px].
   real(R8P)                            :: radius    !< Chart radius [px].
   real(R8P)                            :: c(2)      !< Centre [px].
   real(R8P)                            :: a         !< Spoke angle [rad].
   real(R8P)                            :: f         !< Radial fraction.
   integer(I4P)                         :: m         !< Spokes.
   integer(I4P)                         :: s         !< Series counter.
   integer(I4P)                         :: k         !< Counter.

   m = 0_I4P
   lo = 0.0_R8P
   hi = -huge(1.0_R8P)
   allocate(character(len=1) :: names(0))
   do s = 1_I4P, size(self%series, kind=I4P)
      associate(series => self%series(s))
         m = max(m, size(series%y, kind=I4P))
         if (any(ieee_is_finite(series%y))) then
            lo = min(lo, minval(series%y, mask=ieee_is_finite(series%y)))
            hi = max(hi, maxval(series%y, mask=ieee_is_finite(series%y)))
         endif
         if (size(names) == 0 .and. allocated(series%xlabels)) names = series%xlabels
      endassociate
   enddo
   if (hi <= lo) hi = lo + 1.0_R8P
   radius = 0.4_R8P * min(box(2) - box(1), box(4) - box(3))
   call linear_ticks(lo, hi, radius, .false., .true., ticks)
   allocate(character(len=64) :: labels(size(self%series)), colors(size(self%series)))
   do s = 1_I4P, size(self%series, kind=I4P)
      labels(s) = self%series(s)%title
      colors(s) = self%series(s)%style%color
   enddo
   key_width = 0.0_R8P
   if (self%key) key_width = chart_key_width(backend, labels, font_size)
   radius = 0.4_R8P * min(box(2) - box(1) - key_width, box(4) - box(3) - 2.0_R8P * LINE_HEIGHT * font_size)
   c = [0.5_R8P * (box(1) + box(2) - key_width), 0.5_R8P * (box(3) + box(4))]
   call backend%begin_group('fs-radar')
   allocate(rx(m), ry(m))
   ! the web: a ring per tick, a spoke per row with its name
   do k = 1_I4P, size(ticks, kind=I4P)
      f = (ticks(k)%value - lo) / (hi - lo)
      if (f <= 0.0_R8P) cycle
      call spokes(f * radius)
      call backend%polygon(rx, ry, 'none', 1.0_R8P, GRID_COLOR, 0.5_R8P)
      call backend%text(c(1) + 0.3_R8P * font_size, c(2) - f * radius - 0.2_R8P * font_size, ticks(k)%label, 'start', &
                        sup=ticks(k)%sup)
   enddo
   do k = 1_I4P, m
      a = (90.0_R8P - 360.0_R8P * real(k - 1_I4P, R8P) / real(m, R8P)) * DEG
      call backend%polyline([c(1), c(1) + radius * cos(a)], [c(2), c(2) - radius * sin(a)], GRID_COLOR, 0.5_R8P, '')
      if (k <= size(names)) call backend%text(c(1) + 1.18_R8P * radius * cos(a), &
                                              c(2) - 1.18_R8P * radius * sin(a) + 0.35_R8P * font_size, trim(names(k)), &
                                              merge('start ', merge('end   ', 'middle', cos(a) < -0.2_R8P), &
                                                    cos(a) > 0.2_R8P))
   enddo
   ! a polygon per series, its undefined values at the centre
   do s = 1_I4P, size(self%series, kind=I4P)
      associate(series => self%series(s))
         do k = 1_I4P, m
            a = (90.0_R8P - 360.0_R8P * real(k - 1_I4P, R8P) / real(m, R8P)) * DEG
            f = 0.0_R8P
            if (k <= size(series%y)) then
               if (ieee_is_finite(series%y(k))) f = (series%y(k) - lo) / (hi - lo)
            endif
            rx(k) = c(1) + f * radius * cos(a)
            ry(k) = c(2) - f * radius * sin(a)
         enddo
         call backend%polygon(rx, ry, series%style%fill_color(), series%style%density, series%style%color, &
                              max(1.0_R8P, series%style%linewidth))
      endassociate
   enddo
   if (self%key) call chart_key(backend, box(2), box(3), labels, colors, 1.0_R8P, font_size)
   call backend%end_group
   contains
      subroutine spokes(rr)
      !< The ring of radius `rr` through the spokes, into `rx`, `ry`.
      real(R8P), intent(in) :: rr !< Ring radius [px].
      integer(I4P)          :: j  !< Spoke counter.

      do j = 1_I4P, m
         a = (90.0_R8P - 360.0_R8P * real(j - 1_I4P, R8P) / real(m, R8P)) * DEG
         rx(j) = c(1) + rr * cos(a)
         ry(j) = c(2) - rr * sin(a)
      enddo
      endsubroutine spokes
   endsubroutine draw_radar

   subroutine draw_rose(self, backend, box, font_size)
   !< A rose (Nightingale) chart in the box (left, right, top, bottom) [px]: equal sectors from 12 o'clock clockwise, one
   !< per row in the linetype colors, the sector area proportional to the value (its radius with `linear`); rings at the
   !< ticks of the value scale; the key at the right, the sector names.
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: box(4)    !< Box: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   type(tick_object), allocatable       :: ticks(:)  !< Value ticks.
   character(len=:), allocatable        :: labels(:) !< Key entries.
   character(len=:), allocatable        :: colors(:) !< Key colors.
   real(R8P), allocatable               :: px(:)     !< Outline [px from the centre].
   real(R8P), allocatable               :: py(:)     !< Outline [px from the centre, upward].
   real(R8P)                            :: lo        !< Scale start (0).
   real(R8P)                            :: hi        !< Scale end.
   real(R8P)                            :: key_width !< Key width [px].
   real(R8P)                            :: radius    !< Chart radius [px].
   real(R8P)                            :: c(2)      !< Centre [px].
   real(R8P)                            :: span      !< Sector angle [deg].
   integer(I4P)                         :: m         !< Sectors.
   integer(I4P)                         :: k         !< Counter.

   associate(series => self%series(1))
      m = size(series%values, kind=I4P)
      lo = 0.0_R8P
      hi = 1.0_R8P
      if (any(ieee_is_finite(series%values))) hi = max(hi * tiny(1.0_R8P), maxval(series%values, &
                                                                                  mask=ieee_is_finite(series%values)))
      call linear_ticks(lo, hi, 100.0_R8P, .false., .true., ticks)
      allocate(character(len=64) :: labels(m), colors(m))
      do k = 1_I4P, m
         labels(k) = ''
         if (allocated(series%xlabels)) labels(k) = trim(series%xlabels(k))
         colors(k) = default_color(k, self%linecolors)
      enddo
      key_width = 0.0_R8P
      if (self%key .and. allocated(series%xlabels)) key_width = chart_key_width(backend, labels, font_size)
      radius = 0.45_R8P * min(box(2) - box(1) - key_width, box(4) - box(3))
      c = [0.5_R8P * (box(1) + box(2) - key_width), 0.5_R8P * (box(3) + box(4))]
      call backend%begin_group('fs-rose')
      span = 360.0_R8P / real(max(1_I4P, m), R8P)
      do k = 1_I4P, m
         if (.not. ieee_is_finite(series%values(k))) cycle
         if (series%values(k) <= 0.0_R8P) cycle
         call outline(radius * fraction(series%values(k)), 0.0_R8P, 90.0_R8P - span * real(k, R8P), &
                      90.0_R8P - span * real(k - 1_I4P, R8P), px, py)
         call backend%polygon(c(1) + px, c(2) - py, default_color(k, self%linecolors), series%style%density, &
                              merge('white', 'none ', series%style%border), 1.0_R8P)
      enddo
      ! the scale over the sectors: rings and their values on the 12 o'clock line
      do k = 1_I4P, size(ticks, kind=I4P)
         if (ticks(k)%value <= 0.0_R8P) cycle
         call outline(radius * fraction(ticks(k)%value), 0.0_R8P, 0.0_R8P, 360.0_R8P, px, py)
         call backend%polygon(c(1) + px, c(2) - py, 'none', 1.0_R8P, GRID_COLOR, 0.5_R8P)
         call backend%text(c(1) + 0.3_R8P * font_size, c(2) - radius * fraction(ticks(k)%value) - 0.2_R8P * font_size, &
                           ticks(k)%label, 'start', sup=ticks(k)%sup)
      enddo
      if (self%key .and. allocated(series%xlabels)) call chart_key(backend, box(2), box(3), labels, colors, &
                                                                   series%style%density, font_size)
      call backend%end_group
   endassociate
   contains
      pure function fraction(v) result(f)
      !< Radius fraction of the value `v`: its square root over the scale (the area by value), or linear.
      real(R8P), intent(in) :: v !< Value.
      real(R8P)             :: f !< Fraction of the radius.

      if (self%series(1)%linear) then
         f = v / hi
      else
         f = sqrt(max(0.0_R8P, v) / hi)
      endif
      endfunction fraction
   endsubroutine draw_rose

   pure function chart_key_width(backend, labels, font_size) result(width)
   !< Width of a chart key [px]: the widest entry, a gap, the sample.
   class(backend_object), intent(in) :: backend   !< Output device.
   character(len=*),      intent(in) :: labels(:) !< Entries.
   real(R8P),             intent(in) :: font_size !< Font size [px].
   real(R8P)                         :: width     !< Width [px].
   integer(I4P)                      :: k         !< Counter.

   width = 0.0_R8P
   do k = 1_I4P, size(labels, kind=I4P)
      width = max(width, backend%text_width(trim(labels(k)), '', font_size))
   enddo
   width = width + font_size + GAP + SAMPLE_LENGTH * font_size + GAP
   endfunction chart_key_width

   subroutine chart_key(backend, right, top, labels, colors, density, font_size)
   !< A chart key at the top right: an entry per label, a filled sample in its color on the right of its text.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: right     !< Key right side [px].
   real(R8P),             intent(in)    :: top       !< Key top [px].
   character(len=*),      intent(in)    :: labels(:) !< Entries.
   character(len=*),      intent(in)    :: colors(:) !< Sample colors.
   real(R8P),             intent(in)    :: density   !< Sample opacity.
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   real(R8P)                            :: yk        !< Row centre [px].
   integer(I4P)                         :: k         !< Counter.

   do k = 1_I4P, size(labels, kind=I4P)
      if (len_trim(labels(k)) == 0) cycle
      yk = top + GAP + (real(k, R8P) - 0.5_R8P) * LINE_HEIGHT * font_size
      call backend%polygon([right - SAMPLE_LENGTH * font_size, right, right, right - SAMPLE_LENGTH * font_size], &
                           [yk + 0.35_R8P * font_size, yk + 0.35_R8P * font_size, yk - 0.35_R8P * font_size, &
                            yk - 0.35_R8P * font_size], trim(colors(k)), density, 'none', 0.0_R8P)
      call backend%text(right - SAMPLE_LENGTH * font_size - GAP, yk + 0.35_R8P * font_size, trim(labels(k)), 'end')
   enddo
   endsubroutine chart_key

   pure subroutine polar_extent(all, rmax, found)
   !< Largest |r| of the points of the series `all` (theta:r) drawn on a polar panel, readouts aside.
   type(series_object), intent(in)  :: all(:) !< Series, theta:r.
   real(R8P),           intent(out) :: rmax   !< Largest |r|.
   logical,             intent(out) :: found  !< Any point.
   integer(I4P)                     :: s      !< Series counter.
   integer(I4P)                     :: i      !< Point counter.

   rmax = 0.0_R8P
   found = .false.
   do s = 1_I4P, size(all, kind=I4P)
      if (all(s)%style%with == WITH_READOUT) cycle
      do i = 1_I4P, size(all(s)%x, kind=I4P)
         if (.not. (ieee_is_finite(all(s)%x(i)) .and. ieee_is_finite(all(s)%y(i)))) cycle
         rmax = max(rmax, abs(all(s)%y(i)))
         found = .true.
      enddo
   enddo
   endsubroutine polar_extent

   pure subroutine polar_window(all, fixed, ends)
   !< Make undefined the points of the series `all` (theta:r) whose theta lies outside the fixed ends of the theta range
   !< (gnuplot `set trange`, which excludes them from polar data plots); an autoscaled end excludes nothing. Readouts
   !< kept. A module procedure on the series array, as `polar_project`.
   type(series_object), intent(inout) :: all(:)   !< Series, theta:r.
   logical,             intent(in)    :: fixed(2) !< Start, end of the theta range set.
   real(R8P),           intent(in)    :: ends(2)  !< Start, end of the theta range.
   real(R8P)                          :: lo       !< Smallest theta kept.
   real(R8P)                          :: hi       !< Largest theta kept.
   integer(I4P)                       :: s        !< Series counter.
   integer(I4P)                       :: i        !< Point counter.

   if (.not. any(fixed)) return
   lo = -huge(1.0_R8P)
   hi = huge(1.0_R8P)
   if (fixed(1)) lo = ends(1)
   if (fixed(2)) hi = ends(2)
   if (fixed(1) .and. fixed(2) .and. ends(1) > ends(2)) then
      lo = ends(2)
      hi = ends(1)
   endif
   do s = 1_I4P, size(all, kind=I4P)
      if (all(s)%style%with == WITH_READOUT) cycle
      do i = 1_I4P, size(all(s)%x, kind=I4P)
         if (.not. ieee_is_finite(all(s)%x(i))) cycle
         if (all(s)%x(i) < lo .or. all(s)%x(i) > hi) all(s)%y(i) = ieee_value(1.0_R8P, ieee_quiet_nan)
      enddo
   enddo
   endsubroutine polar_window

   pure subroutine polar_project(all, rmin, cut, degrees, origin, clockwise)
   !< Project the series `all` from theta:r to x:y about the pole at r = `rmin`, as gnuplot: x = (r - rmin) cos(phi),
   !< y = (r - rmin) sin(phi), phi the page angle of theta; with `cut` (a fixed `rmin`) a point with r below `rmin` is
   !< undefined, else it lies across the pole. Readouts kept.
   !< (A module procedure, not a binding: gfortran 16 debug builds misread the components of `self%series` reached
   !< through the class dummy after their reallocation.)
   type(series_object), intent(inout) :: all(:)    !< Series: theta:r in, x:y out.
   real(R8P),           intent(in)    :: rmin      !< r at the pole.
   logical,             intent(in)    :: cut       !< Points below `rmin` undefined.
   logical,             intent(in)    :: degrees   !< Theta in degrees, else radians.
   real(R8P),           intent(in)    :: origin    !< Page angle of theta = 0 [deg].
   logical,             intent(in)    :: clockwise !< Theta grows clockwise.
   real(R8P)                          :: nan       !< Undefined value.
   real(R8P)                          :: phi       !< Page angle [rad].
   real(R8P)                          :: rho       !< Distance from the pole [r units].
   integer(I4P)                       :: s         !< Series counter.
   integer(I4P)                       :: i         !< Point counter.

   nan = ieee_value(1.0_R8P, ieee_quiet_nan)
   do s = 1_I4P, size(all, kind=I4P)
      if (all(s)%style%with == WITH_READOUT) cycle
      do i = 1_I4P, size(all(s)%x, kind=I4P)
         if (ieee_is_finite(all(s)%x(i)) .and. ieee_is_finite(all(s)%y(i))) then
            if (all(s)%y(i) >= rmin .or. .not. cut) then
               phi = all(s)%x(i)
               if (degrees) phi = phi * (PI_R8 / 180.0_R8P)
               if (clockwise) phi = -phi
               phi = phi + origin * (PI_R8 / 180.0_R8P)
               rho = all(s)%y(i) - rmin
               all(s)%x(i) = rho * cos(phi)
               all(s)%y(i) = rho * sin(phi)
               cycle
            endif
         endif
         all(s)%x(i) = nan
         all(s)%y(i) = nan
      enddo
   enddo
   endsubroutine polar_project

   pure subroutine boxplot_words(words, style, bad)
   !< Update the boxplot `style` with gnuplot `set style boxplot` words: `range R`, `fraction F`, `[no]outliers`,
   !< `pointtype|pt P`, `candlesticks`, `financebars`, `medianlinewidth W`, `separation S`, `labels off|auto|x`,
   !< `sorted`, `unsorted`. `bad` names the first problem, empty if none (the style is then unchanged).
   character(len=*),              intent(in)    :: words !< Words.
   type(boxplot_style),           intent(inout) :: style !< Boxplot style.
   character(len=:), allocatable, intent(out)   :: bad   !< Problem, empty if none.
   type(boxplot_style)                          :: new   !< Updated style.
   character(len=:), allocatable                :: w     !< Current word.
   character(len=:), allocatable                :: arg   !< Its argument.
   real(R8P)                                    :: r     !< Numeric argument.
   integer(I4P)                                 :: pos   !< Scan position.
   integer(I4P)                                 :: ios   !< Read status.

   bad = ''
   new = style
   pos = 1_I4P
   do
      call next_word(pos, w)
      if (len(w) == 0) exit
      select case (w)
      case ('outliers', 'nooutliers')
         new%outliers = w == 'outliers'
      case ('candlesticks', 'financebars')
         new%financebars = w == 'financebars'
      case ('sorted', 'unsorted')
         new%sorted = w == 'sorted'
      case ('labels')
         call next_word(pos, arg)
         select case (arg)
         case ('off', 'auto', 'x')
            new%labels = arg
         case default
            bad = 'labels off, auto or x expected'
            return
         endselect
      case ('range', 'fraction', 'pointtype', 'pt', 'medianlinewidth', 'separation')
         call next_word(pos, arg)
         read(arg, *, iostat=ios) r
         if (len(arg) == 0 .or. ios /= 0) then
            bad = w//' needs a number'
            return
         endif
         select case (w)
         case ('range')
            if (r < 0.0_R8P) then
               bad = 'the range must not be negative'
               return
            endif
            new%range = r
            new%fraction = 0.0_R8P
         case ('fraction')
            if (r <= 0.0_R8P .or. r > 1.0_R8P) then
               bad = 'the fraction is above 0 and up to 1'
               return
            endif
            new%fraction = r
         case ('pointtype', 'pt')
            if (r < 0.0_R8P .or. r /= aint(r)) then
               bad = 'the point type is an integer >= 0'
               return
            endif
            new%pointtype = int(r, I4P)
         case ('medianlinewidth')
            if (r < 0.0_R8P) then
               bad = 'the median line width must not be negative'
               return
            endif
            new%median_width = r
         case default
            if (.not. r > 0.0_R8P) then
               bad = 'the separation must be positive'
               return
            endif
            new%separation = r
         endselect
      case default
         bad = 'unsupported option "'//w//'"'
         return
      endselect
   enddo
   style = new
   contains
      pure subroutine next_word(pos, word)
      !< Next blank separated word of `words` from `pos` (advanced past it), empty at the end.
      integer(I4P),                  intent(inout) :: pos   !< Scan position.
      character(len=:), allocatable, intent(out)   :: word  !< Word.
      integer(I4P)                                 :: first !< Word start.

      do while (pos <= len(words))
         if (words(pos:pos) /= ' ') exit
         pos = pos + 1_I4P
      enddo
      first = pos
      do while (pos <= len(words))
         if (words(pos:pos) == ' ') exit
         pos = pos + 1_I4P
      enddo
      word = words(first:pos - 1_I4P)
      endsubroutine next_word
   endsubroutine boxplot_words

   pure subroutine curve_words(words, series, bad)
   !< Filled curve options of `series` from gnuplot words: `closed`, `x1` (to the bottom), `x2` (to the top), `xy=X,Y`
   !< (to a point), `y1` or `y` (to the left border), `y2` (to the right one), `x1=V`, `x2=V`, `x=V` (to the vertical
   !< line x = V, as gnuplot 6.0 draws them), `above`, `below` (where the curve is above or below its line or second
   !< curve). `bad` names the first problem.
   character(len=*),              intent(in)    :: words  !< Words.
   type(series_object),           intent(inout) :: series !< Filled curve series.
   character(len=:), allocatable, intent(out)   :: bad    !< Problem, empty if none.
   character(len=:), allocatable                :: w      !< Current word.
   integer(I4P)                                 :: pos    !< Scan position.
   integer(I4P)                                 :: comma  !< Comma position.
   integer(I4P)                                 :: ios    !< Read status.

   bad = ''
   pos = 1_I4P
   do
      call scan_word(words, pos, w)
      if (len(w) == 0) exit
      select case (w)
      case ('closed')
         series%curve_to = 0_I4P
      case ('x1')
         series%curve_to = 1_I4P
      case ('x2')
         series%curve_to = 2_I4P
      case ('y1', 'y')
         series%curve_to = 4_I4P
      case ('y2')
         series%curve_to = 5_I4P
      case ('above')
         series%curve_side = 1_I4P
      case ('below')
         series%curve_side = -1_I4P
      case default
         if (index(w, 'x1=') == 1 .or. index(w, 'x2=') == 1 .or. index(w, 'x=') == 1) then
            read(w(index(w, '=') + 1:), *, iostat=ios) series%curve_point(1)
            if (ios /= 0) then
               bad = 'x=V expected, found "'//w//'"'
               return
            endif
            series%curve_to = 6_I4P
            cycle
         endif
         if (index(w, 'xy=') /= 1) then
            bad = 'option "'//w//'" is not supported (closed, x1, x2, y1, y2, x=V, xy=X,Y, above, below)'
            return
         endif
         comma = index(w, ',', kind=I4P)
         ios = 1
         if (comma > 4_I4P) then
            read(w(4:comma - 1_I4P), *, iostat=ios) series%curve_point(1)
            if (ios == 0) read(w(comma + 1_I4P:), *, iostat=ios) series%curve_point(2)
         endif
         if (ios /= 0) then
            bad = 'xy=X,Y expected, found "'//w//'"'
            return
         endif
         series%curve_to = 3_I4P
      endselect
   enddo
   endsubroutine curve_words

   subroutine spider_words(words, style, bad)
   !< The spider plot `style` from gnuplot `set style spiderplot` words: fill style words (after an optional `fs` or
   !< `fillstyle`), `lw|linewidth W`, `pt|pointtype N`, `ps|pointsize S`. `bad` names the first problem.
   character(len=*),              intent(in)    :: words !< Words.
   type(style_object),            intent(inout) :: style !< Spider plot style.
   character(len=:), allocatable, intent(out)   :: bad   !< Problem, empty if none.
   character(len=:), allocatable                :: w     !< Current word.
   character(len=:), allocatable                :: arg   !< Argument.
   character(len=:), allocatable                :: fill  !< Fill words.
   type(style_object)                           :: new   !< Updated style.
   real(R8P)                                    :: r     !< Number.
   integer(I4P)                                 :: pos   !< Scan position.
   integer(I4P)                                 :: ios   !< Read status.

   bad = ''
   new = style
   fill = ''
   pos = 1_I4P
   do
      call scan_word(words, pos, w)
      if (len(w) == 0) exit
      select case (w)
      case ('fs', 'fillstyle')
      case ('lw', 'linewidth', 'pt', 'pointtype', 'ps', 'pointsize')
         call scan_word(words, pos, arg)
         read(arg, *, iostat=ios) r
         if (len(arg) == 0 .or. ios /= 0) then
            bad = w//' needs a number'
            return
         endif
         select case (w)
         case ('lw', 'linewidth')
            new%linewidth = r
         case ('pt', 'pointtype')
            new%pointtype = int(r, I4P)
         case default
            new%pointsize = r
         endselect
      case default
         fill = fill//' '//w
      endselect
   enddo
   if (len(fill) > 0) then
      call fill_style(fill, new, bad)
      if (len(bad) > 0) then
         bad = 'unsupported option "'//bad//'"'
         return
      endif
   endif
   style = new
   endsubroutine spider_words

   pure subroutine head_words(words, head, filled, bad)
   !< Arrowheads from gnuplot words: `head` (at the end), `heads` (both), `nohead`, `backhead` (at the start); `filled`,
   !< `empty` or `nofilled` (open). `bad` names an unknown word, empty if none.
   character(len=*),              intent(in)    :: words  !< Words.
   integer(I4P),                  intent(inout) :: head   !< Heads: 0 none, 1 end, 2 start, 3 both.
   logical,                       intent(inout) :: filled !< Filled heads.
   character(len=:), allocatable, intent(out)   :: bad    !< Unknown word, empty if none.
   character(len=:), allocatable                :: w      !< Current word.
   integer(I4P)                                 :: pos    !< Scan position.

   bad = ''
   pos = 1_I4P
   do
      call scan_word(words, pos, w)
      if (len(w) == 0) exit
      select case (w)
      case ('head')
         head = 1_I4P
      case ('heads')
         head = 3_I4P
      case ('nohead')
         head = 0_I4P
      case ('backhead')
         head = 2_I4P
      case ('filled')
         filled = .true.
      case ('empty', 'nofilled')
         filled = .false.
      case default
         bad = 'unsupported arrow option "'//w//'" (head, heads, nohead, backhead, filled, empty, nofilled)'
         return
      endselect
   enddo
   endsubroutine head_words

   pure subroutine label_words(words, series, bad)
   !< Label options of `series` from gnuplot `with labels` words: `left`, `center`, `right`, `rotate by A`, `norotate`,
   !< `offset X,Y` [characters], `point` / `nopoint`, `tc|textcolor [rgb] "color"`. `bad` names the first problem.
   character(len=*),              intent(in)    :: words  !< Words.
   type(series_object),           intent(inout) :: series !< Labels series.
   character(len=:), allocatable, intent(out)   :: bad    !< Problem, empty if none.
   character(len=:), allocatable                :: w      !< Current word.
   character(len=:), allocatable                :: arg    !< Argument.
   real(R8P)                                    :: r(2)   !< Numbers.
   integer(I4P)                                 :: pos    !< Scan position.
   integer(I4P)                                 :: comma  !< Comma position.
   integer(I4P)                                 :: ios    !< Read status.

   bad = ''
   pos = 1_I4P
   do
      call scan_word(words, pos, w)
      if (len(w) == 0) exit
      select case (w)
      case ('left')
         series%text_anchor = 'start'
      case ('center', 'centre')
         series%text_anchor = 'middle'
      case ('right')
         series%text_anchor = 'end'
      case ('norotate')
         series%text_rotate = 0.0_R8P
      case ('rotate')
         call scan_word(words, pos, arg)
         if (arg /= 'by') then
            bad = 'rotate by A expected'
            return
         endif
         call scan_word(words, pos, arg)
         read(arg, *, iostat=ios) r(1)
         if (len(arg) == 0 .or. ios /= 0) then
            bad = 'rotate by A expected'
            return
         endif
         series%text_rotate = r(1)
      case ('offset')
         call scan_word(words, pos, arg)
         comma = index(arg, ',', kind=I4P)
         ios = 1
         if (comma > 1_I4P) then
            read(arg(1:comma - 1_I4P), *, iostat=ios) r(1)
            if (ios == 0) read(arg(comma + 1_I4P:), *, iostat=ios) r(2)
         endif
         if (ios /= 0) then
            bad = 'offset X,Y expected'
            return
         endif
         series%text_offset = r
      case ('point')
         series%text_point = .true.
      case ('nopoint')
         series%text_point = .false.
      case ('tc', 'textcolor')
         call scan_word(words, pos, arg)
         if (arg == 'rgb') call scan_word(words, pos, arg)
         if (len(arg) < 3) then
            bad = 'tc "color" expected'
            return
         endif
         if (.not. ((arg(1:1) == '"' .and. arg(len(arg):) == '"') .or. (arg(1:1) == "'" .and. arg(len(arg):) == "'"))) &
            then
            bad = 'tc "color" expected'
            return
         endif
         series%text_color = arg(2:len(arg) - 1)
      case default
         bad = 'unsupported option "'//w//'"'
         return
      endselect
   enddo
   endsubroutine label_words

   pure subroutine scan_word(text, pos, word)
   !< Next blank separated word of `text` from `pos`, advanced past it; a quoted word may hold blanks. Empty at the end.
   character(len=*),              intent(in)    :: text !< Text.
   integer(I4P),                  intent(inout) :: pos  !< Scan position.
   character(len=:), allocatable, intent(out)   :: word !< Word.
   integer(I4P)                                 :: first !< Word start.
   character(len=1)                             :: q     !< Open quote.

   do while (pos <= len(text))
      if (text(pos:pos) /= ' ') exit
      pos = pos + 1_I4P
   enddo
   first = pos
   if (pos <= len(text)) then
      if (text(pos:pos) == '"' .or. text(pos:pos) == "'") then
         q = text(pos:pos)
         pos = pos + 1_I4P
         do while (pos <= len(text))
            if (text(pos:pos) == q) exit
            pos = pos + 1_I4P
         enddo
         pos = min(pos + 1_I4P, len(text) + 1_I4P)
         word = text(first:pos - 1_I4P)
         return
      endif
   endif
   do while (pos <= len(text))
      if (text(pos:pos) == ' ') exit
      pos = pos + 1_I4P
   enddo
   word = text(first:pos - 1_I4P)
   endsubroutine scan_word

   elemental function polar_series(series) result(ok)
   !< Whether `series` can be drawn on a polar panel (see POLAR_STYLES).
   type(series_object), intent(in) :: series !< Series.
   logical                         :: ok     !< Polar series.

   select case (series%style%with)
   case (WITH_LINES, WITH_POINTS, WITH_LINESPOINTS, WITH_READOUT, WITH_SECTORS)
      ok = .true.
   case (WITH_FILLEDCURVES)
      ok = .not. allocated(series%ylow)
   case default
      ok = .false.
   endselect
   ok = ok .and. .not. (series%y2 .or. series%x2)
   endfunction polar_series

   function parallel_axis(self, k, npx) result(axis)
   !< The parallel axis `k` (`set paxis k`, else autoscaled without extension and without ticks) set up for the values
   !< of the `k`-th series, `npx` pixels long.
   class(axes_object), intent(in) :: self !< Panel.
   integer(I4P),       intent(in) :: k    !< Axis number.
   real(R8P),          intent(in) :: npx  !< Axis length [px].
   type(axis_object)              :: axis !< Axis.
   real(R8P), allocatable         :: v(:) !< Finite values.

   axis = axis_object(tight=.true., tics=tics_object(mode=TICS_NONE))
   if (allocated(self%paxes)) then
      if (k <= size(self%paxes)) axis = self%paxes(k)%axis
   endif
   associate(series => self%series(k))
      v = pack(series%y, ieee_is_finite(series%y))
   endassociate
   if (size(v) > 0) then
      call axis%setup(minval(v), maxval(v), .true., npx)
   else
      call axis%setup(0.0_R8P, 1.0_R8P, .false., npx)
   endif
   endfunction parallel_axis

   subroutine draw_parallel(self, backend, box, font_size)
   !< A parallel axis plot in the box (left, right, top, bottom) [px], as gnuplot: a vertical axis per series at its
   !< number (or `at`), the x range one unit beyond the first and last, each axis scaled on its own (`set paxis`) and
   !< titled below by its series; a line per row across the axes, in the first series' style; the frame around.
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: box(4)    !< Box: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   type(axis_object), allocatable       :: axes(:)   !< Axes.
   real(R8P), allocatable               :: pos(:)    !< Axis positions [px].
   real(R8P), allocatable               :: lx(:)     !< Row line abscissae [px].
   real(R8P), allocatable               :: ly(:)     !< Row line ordinates [px].
   real(R8P)                            :: area(4)   !< Plot area: left, right, top, bottom [px].
   real(R8P)                            :: xlo       !< x range start.
   real(R8P)                            :: xhi       !< x range end.
   real(R8P)                            :: p         !< Tick ordinate [px].
   integer(I4P)                         :: n         !< Axes.
   integer(I4P)                         :: m         !< Rows.
   integer(I4P)                         :: k         !< Axis counter.
   integer(I4P)                         :: j         !< Row counter.
   integer(I4P)                         :: t         !< Tick counter.

   n = size(self%series, kind=I4P)
   area = [box(1) + 4.0_R8P * font_size, box(2) - 2.0_R8P * font_size, box(3) + 0.5_R8P * font_size, &
           box(4) - LINE_HEIGHT * font_size - GAP]
   allocate(axes(n), pos(n))
   m = 0_I4P
   do k = 1_I4P, n
      axes(k) = self%parallel_axis(k, area(4) - area(3))
      associate(series => self%series(k))
         pos(k) = real(k, R8P)
         if (series%at_set) pos(k) = series%at
         m = max(m, size(series%y, kind=I4P))
      endassociate
   enddo
   xlo = minval(pos) - 1.0_R8P
   xhi = maxval(pos) + 1.0_R8P
   pos = area(1) + (pos - xlo) / (xhi - xlo) * (area(2) - area(1))
   call backend%begin_group('fs-parallel')
   call backend%rect(area(1), area(3), area(2) - area(1), area(4) - area(3), FRAME_COLOR, 'none', 1.0_R8P)
   ! a line per row, broken at undefined values
   associate(first => self%series(1))
      do j = 1_I4P, m
         allocate(lx(0), ly(0))
         do k = 1_I4P, n
            associate(series => self%series(k))
               if (j <= size(series%y)) then
                  if (ieee_is_finite(series%y(j))) then
                     lx = [lx, pos(k)]
                     ly = [ly, area(4) - axes(k)%to_unit(series%y(j)) * (area(4) - area(3))]
                     cycle
                  endif
               endif
            endassociate
            if (size(lx) > 1) call backend%polyline(lx, ly, first%style%color, first%style%linewidth, &
                                                    first%style%dasharray())
            deallocate(lx, ly)
            allocate(lx(0), ly(0))
         enddo
         if (size(lx) > 1) call backend%polyline(lx, ly, first%style%color, first%style%linewidth, first%style%dasharray())
         deallocate(lx, ly)
      enddo
   endassociate
   ! the axes over the lines, as gnuplot's front parallel axis style
   do k = 1_I4P, n
      call backend%polyline([pos(k), pos(k)], [area(4), area(3)], FRAME_COLOR, 2.0_R8P, '')
      do t = 1_I4P, size(axes(k)%ticks, kind=I4P)
         p = area(4) - axes(k)%to_unit(axes(k)%ticks(t)%value) * (area(4) - area(3))
         call backend%polyline([pos(k), pos(k) + merge(TICK_MAJOR, TICK_MINOR, axes(k)%ticks(t)%major)], [p, p], &
                               FRAME_COLOR, 1.0_R8P, '')
         if (axes(k)%ticks(t)%major) call backend%text(pos(k) - GAP, p + 0.35_R8P * font_size, axes(k)%ticks(t)%label, &
                                                       'end', sup=axes(k)%ticks(t)%sup)
      enddo
      associate(series => self%series(k))
         if (len(series%title) > 0) call backend%text(pos(k), area(4) + GAP + font_size, series%title, 'middle')
      endassociate
   enddo
   call backend%end_group
   endsubroutine draw_parallel

   subroutine draw_spider(self, backend, box, font_size)
   !< A spider plot in the box (left, right, top, bottom) [px], as gnuplot: a radial axis per series, the first up, the
   !< others clockwise, each scaled on its own (`set paxis`, the smallest value at the centre by default) and labelled
   !< outside by its series title, else by `set paxis N label`; the web (`set grid spiderplot`) at the ticks of axis 1; a
   !< polygon per row in its linetype color and the spider plot style, named in the key by the `key(N)` column.
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: box(4)    !< Box: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   real(R8P), parameter                 :: DEG = 4.0_R8P * atan(1.0_R8P) / 180.0_R8P !< Degrees to radians.
   type(axis_object), allocatable       :: axes(:)   !< Axes.
   character(len=:), allocatable        :: names(:)  !< Row names.
   character(len=:), allocatable        :: colors(:) !< Row colors.
   character(len=:), allocatable        :: label     !< Axis label.
   real(R8P), allocatable               :: rx(:)     !< Polygon abscissae [px].
   real(R8P), allocatable               :: ry(:)     !< Polygon ordinates [px].
   real(R8P)                            :: key_width !< Key width [px].
   real(R8P)                            :: radius    !< Axis length [px].
   real(R8P)                            :: c(2)      !< Centre [px].
   real(R8P)                            :: a         !< Axis angle [rad].
   real(R8P)                            :: f         !< Radial fraction.
   integer(I4P)                         :: n         !< Axes.
   integer(I4P)                         :: m         !< Rows.
   integer(I4P)                         :: k         !< Axis counter.
   integer(I4P)                         :: j         !< Row counter.
   integer(I4P)                         :: t         !< Tick counter.

   n = size(self%series, kind=I4P)
   m = 0_I4P
   do k = 1_I4P, n
      associate(series => self%series(k))
         m = max(m, size(series%y, kind=I4P))
      endassociate
   enddo
   allocate(character(len=64) :: names(0))
   associate(first => self%series(1))
      if (allocated(first%texts)) names = first%texts
   endassociate
   allocate(character(len=16) :: colors(m))
   do j = 1_I4P, m
      colors(j) = default_color(j, self%linecolors)
   enddo
   key_width = 0.0_R8P
   if (self%key .and. size(names) > 0) key_width = chart_key_width(backend, names, font_size)
   radius = 0.4_R8P * min(box(2) - box(1) - key_width, box(4) - box(3) - 2.0_R8P * LINE_HEIGHT * font_size)
   c = [0.5_R8P * (box(1) + box(2) - key_width), 0.5_R8P * (box(3) + box(4))]
   allocate(axes(n), rx(n), ry(n))
   do k = 1_I4P, n
      axes(k) = self%parallel_axis(k, radius)
   enddo
   call backend%begin_group('fs-spider')
   ! the web at the ticks of the first axis
   if (self%grid_spider) then
      do t = 1_I4P, size(axes(1)%ticks, kind=I4P)
         if (.not. axes(1)%ticks(t)%major) cycle
         f = axes(1)%to_unit(axes(1)%ticks(t)%value)
         if (f <= 0.0_R8P .or. f > 1.0_R8P + 1.0e-9_R8P) cycle
         do k = 1_I4P, n
            a = angle(k)
            rx(k) = c(1) + f * radius * cos(a)
            ry(k) = c(2) - f * radius * sin(a)
         enddo
         call backend%polyline([rx, rx(1)], [ry, ry(1)], GRID_COLOR, 0.5_R8P, GRID_DASHES)
      enddo
   endif
   ! a polygon per row, an undefined value at the centre
   do j = 1_I4P, m
      do k = 1_I4P, n
         a = angle(k)
         f = 0.0_R8P
         associate(series => self%series(k))
            if (j <= size(series%y)) then
               if (ieee_is_finite(series%y(j))) f = min(1.0_R8P, max(0.0_R8P, axes(k)%to_unit(series%y(j))))
            endif
         endassociate
         rx(k) = c(1) + f * radius * cos(a)
         ry(k) = c(2) - f * radius * sin(a)
      enddo
      associate(st => self%spider_style)
         call backend%polygon(rx, ry, merge(trim(colors(j)), 'none   ', st%fill /= FILL_EMPTY), st%density, &
                              merge(trim(colors(j)), 'none   ', st%border .or. st%fill == FILL_EMPTY), &
                              max(1.0_R8P, st%linewidth))
         if (st%pointtype >= 0_I4P) call backend%dots(rx, ry, trim(colors(j)), st%point_diameter(), pt=st%pointtype, &
                                                      line_width=st%linewidth)
      endassociate
   enddo
   ! the axes over the polygons, their ticks and labels
   do k = 1_I4P, n
      a = angle(k)
      call backend%polyline([c(1), c(1) + radius * cos(a)], [c(2), c(2) - radius * sin(a)], FRAME_COLOR, 2.0_R8P, '')
      do t = 1_I4P, size(axes(k)%ticks, kind=I4P)
         f = axes(k)%to_unit(axes(k)%ticks(t)%value)
         if (f < -1.0e-9_R8P .or. f > 1.0_R8P + 1.0e-9_R8P) cycle
         associate(px => c(1) + f * radius * cos(a), py => c(2) - f * radius * sin(a), &
                   l => merge(TICK_MAJOR, TICK_MINOR, axes(k)%ticks(t)%major))
            call backend%polyline([px - 0.5_R8P * l * sin(a), px + 0.5_R8P * l * sin(a)], &
                                  [py - 0.5_R8P * l * cos(a), py + 0.5_R8P * l * cos(a)], FRAME_COLOR, 1.0_R8P, '')
            ! no label at the centre, shared by the axes
            if (axes(k)%ticks(t)%major .and. f > 1.0e-9_R8P) call backend%text(px + GAP * sin(a) + 0.3_R8P * font_size, &
                                                          py + GAP * cos(a) + 0.35_R8P * font_size, &
                                                          axes(k)%ticks(t)%label, 'start', sup=axes(k)%ticks(t)%sup)
         endassociate
      enddo
      ! the item title overrides the axis label, as gnuplot
      label = ''
      if (allocated(self%paxes)) then
         if (k <= size(self%paxes)) then
            if (allocated(self%paxes(k)%label)) label = self%paxes(k)%label
         endif
      endif
      associate(series => self%series(k))
         if (len(series%title) > 0) label = series%title
      endassociate
      if (len(label) > 0) call backend%text(c(1) + 1.12_R8P * radius * cos(a), &
                                            c(2) - 1.12_R8P * radius * sin(a) + 0.35_R8P * font_size, label, &
                                            merge('start ', merge('end   ', 'middle', cos(a) < -0.2_R8P), cos(a) > 0.2_R8P))
   enddo
   if (self%key .and. size(names) > 0) &
      call chart_key(backend, box(2), box(3), names, colors(1:size(names)), self%spider_style%density, font_size)
   call backend%end_group
   contains
      pure function angle(axis) result(rad)
      !< Page angle of the axis `axis`: the first up, the others clockwise [rad].
      integer(I4P), intent(in) :: axis !< Axis number.
      real(R8P)                :: rad  !< Angle [rad].

      rad = (90.0_R8P - 360.0_R8P * real(axis - 1_I4P, R8P) / real(n, R8P)) * DEG
      endfunction angle
   endsubroutine draw_spider

   elemental function is_panel_chart(with) result(is)
   !< Whether the style `with` is a chart alone in its panel, without the x and y axes: pie, gauge, radar, rose, and the
   !< parallel axis and spider plots.
   integer(I4P), intent(in) :: with !< Style code.
   logical                  :: is   !< Panel chart.

   is = any(with == [WITH_PIE, WITH_GAUGE, WITH_RADAR, WITH_ROSE, WITH_PARALLELAXES, WITH_SPIDERPLOT])
   endfunction is_panel_chart

   pure function has_image(self, palette) result(has)
   !< Whether the panel has an image; with `palette` true, an image of values colored by the palette (not RGB) or a
   !< series colored by it (`lc palette`): the color axis and its box are then drawn.
   class(axes_object), intent(in)           :: self    !< Panel.
   logical,            intent(in), optional :: palette !< Palette images only.
   logical                                  :: has     !< An image is plotted.
   logical                                  :: only    !< Palette images only.

   has = .false.
   only = .false.
   if (present(palette)) only = palette
   if (.not. allocated(self%series)) return
   has = any_image(self%series, only)
   endfunction has_image

   pure function any_image(all, palette) result(has)
   !< Whether the series `all` hold an image, a palette one (not RGB) if `palette`. A module procedure on the series
   !< array, as `image_range`: gfortran 16 debug builds misread the components of `self%series(s)` through the class
   !< dummy.
   type(series_object), intent(in) :: all(:)  !< Series of the panel.
   logical,             intent(in) :: palette !< Palette images only.
   logical                         :: has     !< An image is plotted.
   integer(I4P)                    :: s       !< Series counter.

   has = .false.
   do s = 1_I4P, size(all, kind=I4P)
      ! a series colored by the palette (lc palette) needs the color axis and its box, as a palette image
      if (palette .and. all(s)%palette_mode > 0_I4P) has = .true.
      if (all(s)%style%with /= WITH_IMAGE) cycle
      if (palette .and. allocated(all(s)%channels)) cycle
      has = .true.
   enddo
   endfunction any_image

   pure subroutine paint_series(all, p, cbaxis)
   !< The colors of the series of `all` colored by the palette `p` (gnuplot `lc palette`): per point over the color
   !< axis `cbaxis` (`z`; the key line sample takes the first point's color, the point sample the last's), one color
   !< axis value (`cb`) or one fraction
   !< (`frac`). A value not placeable on a log color axis takes its low end, as the images. A module procedure on the
   !< series array, as `image_range`.
   type(series_object),  intent(inout) :: all(:) !< Series of the panel.
   type(palette_object), intent(in)    :: p      !< Effective palette.
   type(axis_object),    intent(in)    :: cbaxis !< Color axis.
   integer(I4P)                        :: s      !< Series counter.
   integer(I4P)                        :: i      !< Point counter.

   do s = 1_I4P, size(all, kind=I4P)
      select case (all(s)%palette_mode)
      case (1_I4P)
         if (.not. allocated(all(s)%zvalues)) cycle
         if (allocated(all(s)%colors)) deallocate(all(s)%colors)
         allocate(all(s)%colors(size(all(s)%zvalues)))
         do i = 1_I4P, size(all(s)%zvalues, kind=I4P)
            all(s)%colors(i) = cb_color(all(s)%zvalues(i))
         enddo
         if (size(all(s)%colors) > 0) all(s)%style%color = all(s)%colors(1)
      case (2_I4P)
         all(s)%style%color = cb_color(all(s)%palette_value)
      case (3_I4P)
         all(s)%style%color = hex_color(p%rgb(all(s)%palette_value))
      endselect
   enddo
   contains
      pure function cb_color(value) result(hex)
      !< Color of the color axis `value`.
      real(R8P), intent(in) :: value !< Value.
      character(len=7)      :: hex   !< Color.

      if (.not. ieee_is_finite(value)) then
         ! an undefined value: the point is not drawn, as gnuplot (it still counts for the autoscale)
         hex = 'none'
      elseif (cbaxis%log .and. value <= 0.0_R8P) then
         hex = hex_color(p%rgb(merge(0.0_R8P, 1.0_R8P, cbaxis%lo < cbaxis%hi)))
      else
         hex = hex_color(p%rgb(cbaxis%to_unit(value)))
      endif
      endfunction cb_color
   endsubroutine paint_series

   function effective_palette(palette, theme) result(p)
   !< `palette`, or the palette of the `theme` if it has the default colors: from the dark glass to the emissive colors
   !< (`vfd`), from the pale glass to the dark segments (`lcd`), quantized as `palette` (`maxcolors`).
   type(palette_object), intent(in) :: palette !< Panel palette.
   character(len=*),     intent(in) :: theme   !< Theme name.
   type(palette_object)             :: p       !< Palette.
   character(len=:), allocatable    :: bad     !< Unknown word, never set.

   p = palette
   if (.not. palette%is_default()) return
   select case (trim(theme))
   case ('vfd')
      call palette_words('defined (0 "#04070a", 0.55 "#3dffc6", 1 "#f5e663")', p, bad)
   case ('lcd')
      call palette_words('defined (0 "#c8d0b8", 1 "#0b3d2e")', p, bad)
   endselect
   p%maxcolors = palette%maxcolors
   endfunction effective_palette

   elemental function is_readout(self, s) result(is)
   !< Whether the `s`-th series is a readout.
   class(axes_object), intent(in) :: self !< Panel.
   integer(I4P),       intent(in) :: s    !< Series index.
   logical                        :: is   !< Readout.

   is = self%series(s)%style%with == WITH_READOUT
   endfunction is_readout

   pure function has_title(self) result(has)
   !< Whether the panel has a non-empty title.
   class(axes_object), intent(in) :: self !< Panel.
   logical                        :: has  !< The title is set.

   has = .false.
   if (allocated(self%title)) has = len(self%title) > 0
   endfunction has_title

   pure function place_plot_area(self, backend, x0, y0, width, height, font_size, above) result(area)
   !< Plot area left by the margins that tick labels, axis labels, title and a key `above` need, measured by the device.
   class(axes_object),    intent(in) :: self       !< Panel.
   class(backend_object), intent(in) :: backend    !< Output device, for text widths.
   real(R8P),          intent(in) :: x0         !< Box left side [px].
   real(R8P),          intent(in) :: y0         !< Box top side [px].
   real(R8P),          intent(in) :: width      !< Box width [px].
   real(R8P),          intent(in) :: height     !< Box height [px].
   real(R8P),          intent(in) :: font_size  !< Font size [px].
   real(R8P),          intent(in) :: above      !< Room for a key between the title and the plot [px].
   real(R8P)                      :: area(4)    !< Plot area: left, right, top, bottom [px].
   real(R8P)                      :: margins(4) !< Left, right, top, bottom margins [px].
   real(R8P)                      :: y2_margin  !< Right margin the second y axis needs [px].
   real(R8P)                      :: extent(3)  !< Rotated x labels: depth, left and right reach [px].
   logical                        :: rotated    !< The x tick labels are drawn rotated.
   integer(I4P)                   :: t          !< Tick counter.

   rotated = self%xaxis%tics%rotate /= 0.0_R8P .and. backend%rotates_text()
   extent = 0.0_R8P
   if (rotated) extent = self%xlabels_extent(backend, font_size)
   ! y tick labels on the y axis (x = 0) take no margin
   if (on_zero(self%yaxis%tics, self%xaxis)) then
      margins(1) = PAD
   else
      margins(1) = PAD + labels_width(self%yaxis) + GAP
      if (self%yaxis%tics%out) margins(1) = margins(1) + tick_length(self%yaxis%tics, .true.)
   endif
   if (self%yaxis%has_label()) margins(1) = margins(1) + LINE_HEIGHT * font_size + GAP
   ! rotated x labels of the leftmost tick may reach beyond the left border
   if (rotated) margins(1) = max(margins(1), PAD + extent(2))
   ! the rightmost x tick label is centred on the border: half of it sticks out
   margins(2) = PAD
   if (rotated) then
      margins(2) = max(margins(2), PAD + extent(3))
   else
      do t = 1_I4P, size(self%xaxis%ticks, kind=I4P)
         if (self%xaxis%ticks(t)%major) margins(2) = max(margins(2), &
            0.5_R8P * backend%text_width(self%xaxis%ticks(t)%label, self%xaxis%ticks(t)%sup, font_size))
      enddo
   endif
   if (self%y2_active .or. self%y2axis%has_label()) then
      y2_margin = PAD
      if (self%y2_active) then
         if (any(self%y2axis%ticks%major)) y2_margin = y2_margin + labels_width(self%y2axis) + GAP
         if (self%y2axis%tics%out) y2_margin = y2_margin + tick_length(self%y2axis%tics, .true.)
      endif
      if (self%y2axis%has_label()) y2_margin = y2_margin + LINE_HEIGHT * font_size + GAP
      margins(2) = max(margins(2), y2_margin)
   endif
   if (self%colorbox .and. self%has_image(palette=.true.) .and. .not. (self%cbox%user .or. self%cbox%horizontal)) &
      margins(2) = margins(2) + self%colorbox_width(backend, font_size)
   margins(3) = PAD + 0.5_R8P * font_size
   if (self%has_title()) margins(3) = margins(3) + LINE_HEIGHT * font_size + GAP
   margins(3) = margins(3) + above + self%x2_room(font_size)
   ! the rightmost x2 tick label sticks out as the x one; rotated, by its reach right of the tick
   if (self%x2_active) then
      do t = 1_I4P, size(self%x2axis%ticks, kind=I4P)
         if (.not. self%x2axis%ticks(t)%major) cycle
         if (self%x2_rise > 0.0_R8P) then
            margins(2) = max(margins(2), rotated_reach(backend%text_width(self%x2axis%ticks(t)%label, &
                                                                          self%x2axis%ticks(t)%sup, font_size), &
                                                       self%x2axis%tics%rotate, self%x2axis%tics%anchor(), font_size))
         else
            margins(2) = max(margins(2), &
                             0.5_R8P * backend%text_width(self%x2axis%ticks(t)%label, self%x2axis%ticks(t)%sup, font_size))
         endif
      enddo
   endif
   ! the row of the x tick labels only if there are labels (gnuplot: 36 px with them, 16.8 without, at 400x300)
   margins(4) = PAD + 0.5_R8P * font_size
   ! x tick labels on the x axis (y = 0) take no margin
   if (on_zero(self%xaxis%tics, self%yaxis)) then
      continue
   elseif (any(self%xaxis%ticks%major)) then
      if (rotated) then
         margins(4) = PAD + out_shift(self%xaxis%tics) + extent(1)
      elseif (self%xaxis%tics%out) then
         margins(4) = PAD + GAP + LINE_HEIGHT * font_size * real(label_rows(self%xaxis%ticks), R8P) + &
                      tick_length(self%xaxis%tics, .true.)
      else
         margins(4) = PAD + GAP + LINE_HEIGHT * font_size * real(label_rows(self%xaxis%ticks), R8P)
      endif
      margins(4) = margins(4) + LINE_HEIGHT * font_size * real(self%group_rows(), R8P)
   elseif (self%xaxis%tics%out .and. size(self%xaxis%ticks) > 0) then
      margins(4) = margins(4) + tick_length(self%xaxis%tics, .true.)
   endif
   if (self%xaxis%has_label()) margins(4) = margins(4) + LINE_HEIGHT * font_size + GAP
   if (self%polar .and. self%ttics%mode /= TICS_NONE) then
      ! theta labels outside the disc, as wide as "360"
      margins(1:2) = max(margins(1:2), PAD + GAP + backend%text_width('360', '', font_size))
      margins(3:4) = max(margins(3:4), [PAD, PAD] + GAP + LINE_HEIGHT * font_size + [above, 0.0_R8P])
   endif
   ! a horizontal color box at its default place: below the x labels
   if (self%colorbox .and. self%has_image(palette=.true.) .and. self%cbox%horizontal .and. .not. self%cbox%user) &
      margins(4) = margins(4) + self%colorbox_height(font_size)
   area = [x0 + margins(1), x0 + width - margins(2), y0 + margins(3), y0 + height - margins(4)]
   ! margins set: characters from the panel box, or the border at a fraction of the page (gnuplot `at screen`, from the
   ! bottom left)
   if (self%margin_user(1) >= 0.0_R8P) area(1) = merge(self%margin_user(1) * self%canvas(1), &
                                                       x0 + self%margin_user(1) * CHAR_WIDTH * font_size, &
                                                       self%margin_screen(1))
   if (self%margin_user(2) >= 0.0_R8P) area(2) = merge(self%margin_user(2) * self%canvas(1), &
                                                       x0 + width - self%margin_user(2) * CHAR_WIDTH * font_size, &
                                                       self%margin_screen(2))
   if (self%margin_user(3) >= 0.0_R8P) area(3) = merge((1.0_R8P - self%margin_user(3)) * self%canvas(2), &
                                                       y0 + self%margin_user(3) * font_size, self%margin_screen(3))
   if (self%margin_user(4) >= 0.0_R8P) area(4) = merge((1.0_R8P - self%margin_user(4)) * self%canvas(2), &
                                                       y0 + height - self%margin_user(4) * font_size, &
                                                       self%margin_screen(4))
   if (self%ratio > 0.0_R8P) call fit_ratio(area)
   contains
      pure subroutine fit_ratio(area)
      !< Shrink the plot area to the height over width `ratio`, centred, as gnuplot `set size ratio`.
      !< The area is an argument: a pure procedure defines no host-associated variable (F2018 C1594).
      real(R8P), intent(inout) :: area(4) !< Plot area [px].
      real(R8P)                :: w       !< Width [px].
      real(R8P)                :: h       !< Height [px].

      w = area(2) - area(1)
      h = area(4) - area(3)
      if (h > self%ratio * w) then
         area(3) = area(3) + 0.5_R8P * (h - self%ratio * w)
         area(4) = area(3) + self%ratio * w
      else
         area(1) = area(1) + 0.5_R8P * (w - h / self%ratio)
         area(2) = area(1) + h / self%ratio
      endif
      endsubroutine fit_ratio

      pure function labels_width(axis) result(widest)
      !< Width of the widest major tick label of a vertical `axis` [px], measured by the device.
      type(axis_object), intent(in) :: axis   !< Axis.
      real(R8P)                     :: widest !< Width [px].
      integer(I4P)                  :: k      !< Tick counter.

      widest = 0.0_R8P
      do k = 1_I4P, size(axis%ticks, kind=I4P)
         if (axis%ticks(k)%major) widest = max(widest, backend%text_width(axis%ticks(k)%label, axis%ticks(k)%sup, &
                                                                          font_size))
      enddo
      endfunction labels_width
   endfunction place_plot_area

   pure function colorbox_width(self, backend, font_size) result(room)
   !< Room of the color box at the right of the plot area: a gap, the box, a gap, its tick labels, the label [px].
   class(axes_object),    intent(in) :: self      !< Panel.
   class(backend_object), intent(in) :: backend   !< Output device, for text widths.
   real(R8P),             intent(in) :: font_size !< Font size [px].
   real(R8P)                         :: room      !< Width [px].
   integer(I4P)                      :: k         !< Tick counter.

   room = 2.0_R8P * GAP + COLORBOX_SIZE * font_size + GAP
   if (allocated(self%cbaxis%ticks)) then
      do k = 1_I4P, size(self%cbaxis%ticks, kind=I4P)
         room = max(room, 3.0_R8P * GAP + COLORBOX_SIZE * font_size + &
                    backend%text_width(self%cbaxis%ticks(k)%label, self%cbaxis%ticks(k)%sup, font_size))
      enddo
   endif
   if (self%cbaxis%has_label()) room = room + GAP + LINE_HEIGHT * font_size
   endfunction colorbox_width

   pure function colorbox_height(self, font_size) result(room)
   !< Room of a horizontal color box below the x labels: a gap, the box, its tick labels, the label [px].
   class(axes_object),    intent(in) :: self      !< Panel.
   real(R8P),             intent(in) :: font_size !< Font size [px].
   real(R8P)                         :: room      !< Height [px].

   room = 2.0_R8P * GAP + COLORBOX_SIZE * font_size
   if (allocated(self%cbaxis%ticks)) then
      if (any(self%cbaxis%ticks%major)) room = room + GAP + LINE_HEIGHT * font_size
   endif
   if (self%cbaxis%has_label()) room = room + GAP + LINE_HEIGHT * font_size
   endfunction colorbox_height

   subroutine draw_colorbox(self, backend, area, panel, font_size)
   !< The color box: the palette gradient over the color axis, its frame (`border`), ticks, labels and label. Vertical,
   !< low values at the bottom (at the top with `invert`), at the right of the plot by default; horizontal, low values
   !< at the left, below the x labels by default; or in the `user` box (canvas fractions from the bottom left).
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: area(4)   !< Plot area: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: panel(4)  !< Panel box: left, top, right, bottom [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   integer(I4P), allocatable            :: rgba(:,:,:) !< Gradient.
   type(palette_object)                 :: p         !< Effective palette.
   real(R8P)                            :: box(4)    !< Box left, top, width, height [px].
   real(R8P)                            :: pos       !< Tick position [px].
   real(R8P)                            :: g         !< Gray level.
   real(R8P)                            :: widest    !< Widest tick label [px].
   logical                              :: labelled  !< Any tick label.
   real(R8P)                            :: cb_major  !< Major tick length [px].
   real(R8P)                            :: cb_minor  !< Minor tick length [px].
   integer(I4P)                         :: n         !< Gradient steps.
   integer(I4P)                         :: k         !< Counter.

   if (self%cbox%user) then
      box(3:4) = self%cbox%size * self%canvas
      box(1) = self%cbox%origin(1) * self%canvas(1)
      box(2) = (1.0_R8P - self%cbox%origin(2)) * self%canvas(2) - box(4)
   elseif (self%cbox%horizontal) then
      box = [area(1), panel(4) - PAD - self%colorbox_height(font_size) + GAP, area(2) - area(1), &
             COLORBOX_SIZE * font_size]
   else
      box = [panel(3) - PAD - self%colorbox_width(backend, font_size) + GAP, area(3), COLORBOX_SIZE * font_size, &
             area(4) - area(3)]
   endif
   p = effective_palette(self%palette, backend%theme%name)
   n = 256_I4P
   if (p%maxcolors > 0_I4P) n = p%maxcolors
   if (self%cbox%horizontal) then
      allocate(rgba(4, n, 1))
   else
      allocate(rgba(4, 1, n))
   endif
   do k = 1_I4P, n
      ! left to right low to high; top to bottom high to low (low to high inverted)
      g = (real(k, R8P) - 0.5_R8P) / real(n, R8P)
      if (.not. (self%cbox%horizontal .or. self%cbox%invert)) g = 1.0_R8P - g
      if (self%cbox%horizontal) then
         rgba(1:3, k, 1) = p%rgb(g)
         rgba(4, k, 1) = 255_I4P
      else
         rgba(1:3, 1, k) = p%rgb(g)
         rgba(4, 1, k) = 255_I4P
      endif
   enddo
   widest = 0.0_R8P
   labelled = .false.
   cb_major = tick_length(self%cbaxis%tics, .true.)
   cb_minor = tick_length(self%cbaxis%tics, .false.)
   call backend%begin_group('fs-colorbox')
   associate(left => box(1), top => box(2), bw => box(3), bh => box(4))
      call backend%image(left, top, left + bw, top + bh, rgba)
      if (self%cbox%border) call backend%rect(left, top, bw, bh, FRAME_COLOR, 'none', 1.0_R8P)
      do k = 1_I4P, size(self%cbaxis%ticks, kind=I4P)
         if (.not. self%cbaxis%ticks(k)%major) then
            ! minor ticks once set (mcbtics): the log decade multiples are not drawn by default
            if (self%cbaxis%tics%minor == MINOR_DEFAULT) cycle
            if (self%cbox%horizontal) then
               pos = left + self%cbaxis%to_unit(self%cbaxis%ticks(k)%value) * bw
               call backend%polyline([pos, pos], [top + bh, top + bh - cb_minor], FRAME_COLOR, 1.0_R8P, '')
            else
               pos = self%cbaxis%to_unit(self%cbaxis%ticks(k)%value) * bh
               pos = merge(top + pos, top + bh - pos, self%cbox%invert)
               call backend%polyline([left + bw, left + bw - cb_minor], [pos, pos], FRAME_COLOR, 1.0_R8P, '')
            endif
            cycle
         endif
         labelled = .true.
         if (self%cbox%horizontal) then
            pos = left + self%cbaxis%to_unit(self%cbaxis%ticks(k)%value) * bw
            call backend%polyline([pos, pos], [top + bh, top + bh - cb_major], FRAME_COLOR, 1.0_R8P, '')
            call backend%text(pos, top + bh + GAP + font_size, self%cbaxis%ticks(k)%label, 'middle', &
                              sup=self%cbaxis%ticks(k)%sup)
         else
            pos = self%cbaxis%to_unit(self%cbaxis%ticks(k)%value) * bh
            pos = merge(top + pos, top + bh - pos, self%cbox%invert)
            call backend%polyline([left + bw, left + bw - cb_major], [pos, pos], FRAME_COLOR, 1.0_R8P, '')
            call backend%text(left + bw + GAP, pos + 0.35_R8P * font_size, self%cbaxis%ticks(k)%label, 'start', &
                              sup=self%cbaxis%ticks(k)%sup)
         endif
      enddo
      ! as colorbox_width: over every tick
      do k = 1_I4P, size(self%cbaxis%ticks, kind=I4P)
         widest = max(widest, backend%text_width(self%cbaxis%ticks(k)%label, self%cbaxis%ticks(k)%sup, font_size))
      enddo
      if (self%cbaxis%has_label()) then
         if (self%cbox%horizontal) then
            call backend%text(left + 0.5_R8P * bw, top + bh + GAP + font_size + &
                              merge(GAP + LINE_HEIGHT * font_size, 0.0_R8P, labelled), self%cbaxis%label, 'middle')
         else
            call backend%text(left + bw + 3.0_R8P * GAP + widest + (LINE_HEIGHT - 0.25_R8P) * font_size, &
                              top + 0.5_R8P * bh, self%cbaxis%label, 'middle', rotate=-90.0_R8P)
         endif
      endif
   endassociate
   call backend%end_group
   endsubroutine draw_colorbox

   subroutine setup_axes(self, area, raw)
   !< Effective ranges and ticks for the plot area: x from every series, each y axis from its own series and the points
   !< inside the x range, as gnuplot. The second y axis is active when it has data or both its ends are fixed; the second
   !< x axis also when its ticks are set, then on the range of the first one without data of its own (gnuplot).
   !<
   !< A polar panel sets up its r axis from the series as given (`raw`, theta:r), projects them into its series, and
   !< autoscales x and y to the disc of the largest radius, as gnuplot.
   class(axes_object),  intent(inout)        :: self    !< Panel.
   real(R8P),           intent(in)           :: area(4) !< Plot area: left, right, top, bottom [px].
   type(series_object), intent(in), optional :: raw(:)  !< Series of a polar panel, theta:r.
   real(R8P)                         :: radius    !< Disc radius of a polar panel [r units from the pole].
   real(R8P)                         :: xmin(2)   !< Smallest abscissa, per x axis.
   real(R8P)                         :: xmax(2)   !< Largest abscissa, per x axis.
   real(R8P)                         :: ymin(2)   !< Smallest ordinate, per y axis.
   real(R8P)                         :: ymax(2)   !< Largest ordinate, per y axis.
   logical                           :: found(2)  !< Any placeable point, per y axis.
   logical                           :: xfound(2) !< Any placeable point, per x axis.
   integer(I4P)                      :: s         !< Series counter.

   if (self%polar) then
      call setup_polar
   else
      call self%axes_extent(xmin, xmax, ymin, ymax, found, xfound)
   endif
   ! a panel with an image fits its pixel edges, as gnuplot
   self%xaxis%tight = self%has_image()
   self%yaxis%tight = self%has_image()
   call collect_labels
   call self%xaxis%setup(xmin(1), xmax(1), xfound(1), area(2) - area(1))
   self%x2_active = .not. self%polar .and. (xfound(2) .or. (self%x2axis%min_fixed .and. self%x2axis%max_fixed) .or. &
                                            self%x2axis%tics%mode /= TICS_NONE)
   if (self%x2_active) then
      ! no data of its own: the range of the first x axis, as is (gnuplot)
      self%x2axis%tight = self%has_image() .or. .not. xfound(2)
      if (xfound(2)) then
         call self%x2axis%setup(xmin(2), xmax(2), .true., area(2) - area(1))
      else
         call self%x2axis%setup(min(self%xaxis%lo, self%xaxis%hi), max(self%xaxis%lo, self%xaxis%hi), .true., &
                                area(2) - area(1))
      endif
   endif
   xmin = huge(1.0_R8P)
   xmax = -huge(1.0_R8P)
   xfound = .false.
   ymin = huge(1.0_R8P)
   ymax = -huge(1.0_R8P)
   found = .false.
   if (self%polar) then
      ymin(1) = -radius
      ymax(1) = radius
      found(1) = .true.
   endif
   do s = 1_I4P, size(self%series, kind=I4P)
      if (self%is_readout(s) .or. self%polar) cycle
      call self%series_extent(s, .true., xmin, xmax, ymin, ymax, found, xfound)
   enddo
   call self%yaxis%setup(ymin(1), ymax(1), found(1), area(4) - area(3))
   self%y2_active = found(2) .or. (self%y2axis%min_fixed .and. self%y2axis%max_fixed)
   if (self%y2_active) call self%y2axis%setup(ymin(2), ymax(2), found(2), area(4) - area(3))
   ! tick labels on several lines (a time format `%m/%d\n%H:%M`) on the x axis only: one line elsewhere
   if (allocated(self%yaxis%ticks)) call one_line(self%yaxis%ticks)
   if (allocated(self%y2axis%ticks)) call one_line(self%y2axis%ticks)
   if (allocated(self%x2axis%ticks)) call one_line(self%x2axis%ticks)
   if (allocated(self%xaxis%ticks) .and. self%xaxis%tics%rotate /= 0.0_R8P) call one_line(self%xaxis%ticks)
   if (self%has_image(palette=.true.)) call setup_colors
   contains
      subroutine setup_polar
      !< The r axis from the largest |r| of the series (the pole at r = 0 unless set), extended to the r ticks; the
      !< series projected; x and y over the disc.
      real(R8P) :: rmax  !< Largest |r|.
      real(R8P) :: rmin  !< r at the pole.
      logical   :: any_r !< Any point.

      ! the points of theta outside a set trange are undefined, as gnuplot 6.0: out of the autoscale and of the drawing
      self%series = raw
      call polar_window(self%series, [self%taxis%min_fixed, self%taxis%max_fixed], &
                        [self%taxis%min_user, self%taxis%max_user])
      call polar_extent(self%series, rmax, any_r)
      rmin = 0.0_R8P
      if (self%raxis%min_fixed) rmin = self%raxis%min_user
      if (.not. any_r .or. .not. rmax > rmin) rmax = rmin + 1.0_R8P
      call self%raxis%setup(0.0_R8P, rmax, .true., 0.5_R8P * min(area(2) - area(1), area(4) - area(3)))
      radius = self%raxis%hi - self%raxis%lo
      call polar_project(self%series, self%raxis%lo, self%raxis%min_fixed, self%degrees, self%theta_origin, &
                         self%theta_clockwise)
      xmin(1) = -radius
      xmax(1) = radius
      found = [.true., .false.]
      xfound = [.true., .false.]
      endsubroutine setup_polar

      subroutine setup_colors
      !< The color axis over the finite values of the images (the positive ones on a log axis; or `cbrange`), never
      !< extended.
      real(R8P) :: zmin  !< Smallest value.
      real(R8P) :: zmax  !< Largest value.
      logical   :: any_z !< Any finite value.

      real(R8P) :: npx   !< Color box length [px].

      call image_range(self%series, zmin, zmax, any_z, positive=self%cbaxis%log)
      if (self%cbox%user) then
         npx = merge(self%cbox%size(1) * self%canvas(1), self%cbox%size(2) * self%canvas(2), self%cbox%horizontal)
      else
         npx = merge(area(2) - area(1), area(4) - area(3), self%cbox%horizontal)
      endif
      call self%cbaxis%setup(zmin, zmax, any_z, npx)
      endsubroutine setup_colors

      subroutine collect_labels
      !< Text labels of every series on their axis (x, x2 at the abscissae; y, y2 at the ordinates), by value (the first
      !< label of a value wins), ascending; shown where the axis has ticks (x2, y2: once set, as gnuplot 6.0).
      call axis_labels('x ', self%xaxis)
      call axis_labels('x2', self%x2axis)
      call axis_labels('y ', self%yaxis)
      call axis_labels('y2', self%y2axis)
      endsubroutine collect_labels

      subroutine axis_labels(name, axis)
      !< The text labels of the series marking axis `name`, set on `axis` (left as they are if none).
      character(len=2),  intent(in)    :: name !< Axis name.
      type(axis_object), intent(inout) :: axis !< The axis.
      type(tick_object), allocatable :: labels(:) !< Labels.
      type(tick_object)              :: t         !< Swap buffer.
      real(R8P)                      :: value     !< Labelled value.
      integer(I4P)                   :: i         !< Point counter.
      integer(I4P)                   :: j         !< Sort counter.
      integer(I4P)                   :: n         !< Labels.

      allocate(labels(0))
      do s = 1_I4P, size(self%series, kind=I4P)
         if (.not. allocated(self%series(s)%xlabels)) cycle
         if (self%series(s)%label_axis /= name) cycle
         associate(series => self%series(s))
            do i = 1_I4P, size(series%x, kind=I4P)
               value = series%x(i)
               if (name(1:1) == 'y') value = series%y(i)
               if (len_trim(series%xlabels(i)) == 0 .or. .not. ieee_is_finite(value)) cycle
               if (size(labels) > 0) then
                  if (any(labels%value == value)) cycle
               endif
               call push(labels, tick_object(value=value, major=.true., label=trim(series%xlabels(i)), sup=''))
            enddo
         endassociate
      enddo
      n = size(labels, kind=I4P)
      do i = 2_I4P, n
         t = labels(i)
         j = i - 1_I4P
         do while (j >= 1_I4P)
            if (labels(j)%value <= t%value) exit
            labels(j + 1_I4P) = labels(j)
            j = j - 1_I4P
         enddo
         labels(j + 1_I4P) = t
      enddo
      call move_alloc(labels, axis%labels)
      endsubroutine axis_labels
   endsubroutine setup_axes

   subroutine plain_ticks(self)
   !< On an enhanced text device, the tick labels of the `noenhanced` axes escaped, read as they are (their widths
   !< measured as drawn).
   type(axes_object), intent(inout) :: self !< Panel.

   call escape(self%xaxis)
   call escape(self%yaxis)
   call escape(self%y2axis)
   call escape(self%x2axis)
   call escape(self%cbaxis)
   contains
      subroutine escape(axis)
      !< The tick labels of `axis` escaped, if `noenhanced`.
      type(axis_object), intent(inout) :: axis !< Axis.
      integer(I4P)                     :: t    !< Tick counter.

      if (.not. (axis%tics%plain .and. allocated(axis%ticks))) return
      do t = 1_I4P, size(axis%ticks, kind=I4P)
         if (allocated(axis%ticks(t)%label)) axis%ticks(t)%label = markup_literal(axis%ticks(t)%label)
      enddo
      endsubroutine escape
   endsubroutine plain_ticks

   pure function time_attribute(axis) result(text)
   !< The input time format of a time axis (the viewer's mark of one), empty if numeric.
   type(axis_object), intent(in) :: axis !< Axis.
   character(len=:), allocatable :: text !< Attribute text.

   text = ''
   if (.not. axis%time .or. axis%log) return
   text = '%d/%m/%y,%H:%M'
   if (allocated(axis%timefmt)) text = axis%timefmt
   endfunction time_attribute

   pure subroutine one_line(ticks)
   !< Tick labels on several lines (new lines in them) joined on one line, a blank between the lines.
   type(tick_object), intent(inout) :: ticks(:) !< Ticks.
   integer(I4P)                     :: t        !< Tick counter.
   integer(I4P)                     :: k        !< New line position.

   do t = 1_I4P, size(ticks, kind=I4P)
      if (.not. allocated(ticks(t)%label)) cycle
      do
         k = index(ticks(t)%label, new_line('a'), kind=I4P)
         if (k == 0_I4P) exit
         ticks(t)%label(k:k) = ' '
      enddo
   enddo
   endsubroutine one_line

   pure function label_rows(ticks) result(rows)
   !< Lines of the tallest major tick label (new lines in it), at least 1.
   type(tick_object), intent(in) :: ticks(:) !< Ticks.
   integer(I4P)                  :: rows     !< Lines.
   integer(I4P)                  :: t        !< Tick counter.
   integer(I4P)                  :: k        !< Character counter.
   integer(I4P)                  :: n        !< Lines of a label.

   rows = 1_I4P
   do t = 1_I4P, size(ticks, kind=I4P)
      if (.not. ticks(t)%major .or. .not. allocated(ticks(t)%label)) cycle
      n = 1_I4P
      do k = 1_I4P, len(ticks(t)%label, kind=I4P)
         if (ticks(t)%label(k:k) == new_line('a')) n = n + 1_I4P
      enddo
      rows = max(rows, n)
   enddo
   endfunction label_rows

   subroutine lines_text(backend, x, y, label, sup, step, color)
   !< A centred text on several lines (new lines in `label`), the first baseline at `y`, the next `step` lower; the
   !< superscript `sup` ends the last line; in `color` unless blank.
   class(backend_object), intent(inout) :: backend !< Output device.
   real(R8P),             intent(in)    :: x       !< Centre abscissa [px].
   real(R8P),             intent(in)    :: y       !< First baseline [px].
   character(len=*),      intent(in)    :: label   !< Text.
   character(len=*),      intent(in)    :: sup     !< Superscript.
   real(R8P),             intent(in)    :: step    !< Line spacing [px].
   character(len=*),      intent(in)    :: color   !< Text color, the frame's if blank.
   integer(I4P)                         :: first   !< Line start.
   integer(I4P)                         :: k       !< New line position.
   integer(I4P)                         :: row     !< Line counter.

   first = 1_I4P
   row = 0_I4P
   do
      k = index(label(first:), new_line('a'), kind=I4P)
      if (k == 0_I4P) exit
      if (len_trim(color) > 0) then
         call backend%text(x, y + real(row, R8P) * step, label(first:first + k - 2_I4P), 'middle', color=trim(color))
      else
         call backend%text(x, y + real(row, R8P) * step, label(first:first + k - 2_I4P), 'middle')
      endif
      first = first + k
      row = row + 1_I4P
   enddo
   if (len_trim(color) > 0) then
      call backend%text(x, y + real(row, R8P) * step, label(first:), 'middle', sup=sup, color=trim(color))
   else
      call backend%text(x, y + real(row, R8P) * step, label(first:), 'middle', sup=sup)
   endif
   endsubroutine lines_text

   subroutine tick_label(backend, tics, font_size, x, y, label, anchor, sup, rotate)
   !< A tick label at (`x`, `y`) [px], moved by the `offset` of its axis `tics` and in their `color` (the frame's if
   !< blank), turned by `rotate` [deg, clockwise] unless 0.
   class(backend_object), intent(inout) :: backend   !< Output device.
   type(tics_object),     intent(in)    :: tics      !< Axis tick settings.
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   real(R8P),             intent(in)    :: x         !< Anchor abscissa [px].
   real(R8P),             intent(in)    :: y         !< Anchor ordinate (baseline) [px].
   character(len=*),      intent(in)    :: label     !< Text.
   character(len=*),      intent(in)    :: anchor    !< Horizontal anchor.
   character(len=*),      intent(in)    :: sup       !< Superscript.
   real(R8P),             intent(in)    :: rotate    !< Rotation [deg, clockwise], 0 for none.
   real(R8P)                            :: px        !< Abscissa moved.
   real(R8P)                            :: py        !< Ordinate moved.

   px = x + label_dx(tics, font_size)
   py = y + label_dy(tics, font_size)
   if (rotate /= 0.0_R8P) then
      if (len_trim(tics%color) > 0) then
         call backend%text(px, py, label, anchor, sup=sup, rotate=rotate, color=trim(tics%color))
      else
         call backend%text(px, py, label, anchor, sup=sup, rotate=rotate)
      endif
   elseif (len_trim(tics%color) > 0) then
      call backend%text(px, py, label, anchor, sup=sup, color=trim(tics%color))
   else
      call backend%text(px, py, label, anchor, sup=sup)
   endif
   endsubroutine tick_label

   pure function on_zero(tics, other) result(yes)
   !< Whether ticks set `axis` (`tics`) lie on the zero of the `other` axis: linear, with 0 in its range.
   type(tics_object), intent(in) :: tics  !< Tick settings.
   type(axis_object), intent(in) :: other !< The other coordinate's axis.
   logical                       :: yes   !< On the zero axis.
   real(R8P)                     :: u     !< Unit coordinate of 0.

   yes = .false.
   if (.not. tics%on_axis) return
   if (other%log) return
   u = other%to_unit(0.0_R8P)
   yes = u >= 0.0_R8P .and. u <= 1.0_R8P
   endfunction on_zero

   pure function limits(axis) result(yes)
   !< Whether the ticks and border side of `axis` are limited to its data range (`rangelimited`, with data).
   type(axis_object), intent(in) :: axis !< Axis.
   logical                       :: yes  !< Range limited.

   yes = axis%tics%rangelimited .and. axis%has_data
   endfunction limits

   pure function within(axis, v) result(yes)
   !< Whether a tick at `v` is drawn: always, or within the data range of a `rangelimited` axis (a hair of tolerance).
   type(axis_object), intent(in) :: axis !< Axis.
   real(R8P),         intent(in) :: v    !< Tick value.
   logical                       :: yes  !< Drawn.
   real(R8P)                     :: tol  !< Tolerance.

   yes = .true.
   if (.not. limits(axis)) return
   tol = 1.0e-9_R8P * max(abs(axis%data_hi - axis%data_lo), abs(axis%data_hi), abs(axis%data_lo), tiny(1.0_R8P))
   yes = v >= axis%data_lo - tol .and. v <= axis%data_hi + tol
   endfunction within

   pure function label_dx(tics, font_size) result(dx)
   !< Horizontal shift of the tick labels of `tics` [px]: their `offset` in characters.
   type(tics_object), intent(in) :: tics      !< Axis tick settings.
   real(R8P),         intent(in) :: font_size !< Font size [px].
   real(R8P)                     :: dx        !< Shift, right.

   dx = tics%offset(1) * CHAR_WIDTH * font_size
   endfunction label_dx

   pure function label_dy(tics, font_size) result(dy)
   !< Vertical shift of the tick labels of `tics` [px]: their `offset` in characters (y up).
   type(tics_object), intent(in) :: tics      !< Axis tick settings.
   real(R8P),         intent(in) :: font_size !< Font size [px].
   real(R8P)                     :: dy        !< Shift, down.

   dy = -tics%offset(2) * font_size
   endfunction label_dy

   pure subroutine axes_names(names, x, y, y2, bad, cb, x2)
   !< Axes named by gnuplot's concatenated axis names, e.g. `x`, `y2`, `xy`, `xyy2`, `cb`, `x2`: each found one sets its
   !< flag (the others are left unchanged); `bad` is the first unsupported rest (`cb` or `x2` without their flag
   !< present), empty if none.
   character(len=*),              intent(in)    :: names !< Axis names.
   logical,                       intent(inout) :: x     !< x named.
   logical,                       intent(inout) :: y     !< y named.
   logical,                       intent(inout) :: y2    !< y2 named.
   character(len=:), allocatable, intent(out)   :: bad   !< Unsupported rest, empty if none.
   logical,             optional, intent(inout) :: cb    !< cb (color axis) named.
   logical,             optional, intent(inout) :: x2    !< x2 named.
   integer(I4P)                                 :: i     !< Character counter.
   logical                                      :: two   !< A `2` follows.

   bad = ''
   i = 1_I4P
   do while (i <= len(names))
      two = .false.
      if (i < len(names)) two = names(i + 1:i + 1) == '2'
      if (present(cb) .and. i < len(names)) then
         if (names(i:i + 1) == 'cb') then
            cb = .true.
            i = i + 2_I4P
            cycle
         endif
      endif
      if (names(i:i) == 'y' .and. two) then
         y2 = .true.
      elseif (names(i:i) == 'x' .and. two .and. present(x2)) then
         x2 = .true.
      elseif (names(i:i) == 'x' .and. .not. two) then
         x = .true.
      elseif (names(i:i) == 'y') then
         y = .true.
      else
         bad = names(i:)
         return
      endif
      i = i + merge(2_I4P, 1_I4P, two)
   enddo
   endsubroutine axes_names

   pure subroutine readout_position(words, horizontal, vertical, layout, bad)
   !< Update the readout block position from the `set key` position words inside the plot area (see `key_position`):
   !< `outside`, `below` and `above` are not readout positions.
   character(len=*),              intent(in)    :: words      !< Blank separated words.
   character(len=6),              intent(inout) :: horizontal !< Horizontal position.
   character(len=6),              intent(inout) :: vertical   !< Vertical position.
   logical,                       intent(inout) :: layout     !< Readouts side by side.
   character(len=:), allocatable, intent(out)   :: bad        !< First word not a position, empty if none.
   logical                                      :: outside    !< Outside the plot area.
   character(len=6)                             :: margin     !< Margin.

   outside = .false.
   margin = ''
   call key_position(words, horizontal, vertical, outside, margin, layout, bad)
   if (len(bad) == 0 .and. (outside .or. len_trim(margin) > 0)) &
      bad = 'outside/above/below (readouts lie inside the plot area)'
   endsubroutine readout_position

   pure subroutine key_position(words, horizontal, vertical, outside, margin, layout, bad)
   !< Update the key position from gnuplot `set key` position words, applied in order: `left`, `right`, `top`,
   !< `bottom`, and `center`, which centres the direction not given yet by `words` (both if none, as gnuplot);
   !< `inside`, `outside`; `below` (`under`) and `above` (`over`), centred rows below or above the plot; the margins
   !< `lmargin`, `rmargin` (outside, left or right, keeping the vertical position), `tmargin`, `bmargin` (above or below
   !< the plot, keeping the horizontal position and the layout), as gnuplot; `horizontal`, `vertical` the layout of the
   !< entries.
   character(len=*),              intent(in)    :: words      !< Blank separated words.
   character(len=6),              intent(inout) :: horizontal !< Horizontal position.
   character(len=6),              intent(inout) :: vertical   !< Vertical position.
   logical,                       intent(inout) :: outside    !< Outside the plot area.
   character(len=6),              intent(inout) :: margin     !< `top`, `bottom` or empty.
   logical,                       intent(inout) :: layout     !< Entries side by side.
   character(len=:), allocatable, intent(out)   :: bad        !< First word not a position, empty if none.
   character(len=:), allocatable                :: word       !< Current word.
   integer(I4P)                                 :: start      !< Word start.
   integer(I4P)                                 :: finish     !< Word end.
   logical                                      :: h_set      !< Horizontal position given.
   logical                                      :: v_set      !< Vertical position given.

   bad = ''
   h_set = .false.
   v_set = .false.
   start = 1_I4P
   do while (start <= len(words))
      if (words(start:start) == ' ') then
         start = start + 1_I4P
         cycle
      endif
      finish = index(words(start:), ' ', kind=I4P)
      if (finish == 0_I4P) then
         finish = len(words, kind=I4P)
      else
         finish = start + finish - 2_I4P
      endif
      word = words(start:finish)
      start = finish + 1_I4P
      select case (word)
      case ('left', 'right')
         horizontal = word
         h_set = .true.
      case ('top', 'bottom')
         vertical = word
         v_set = .true.
      case ('center')
         if (h_set .and. .not. v_set) then
            vertical = 'center'
         elseif (v_set .and. .not. h_set) then
            horizontal = 'center'
         else
            horizontal = 'center'
            vertical = 'center'
         endif
      case ('inside', 'ins')
         outside = .false.
         margin = ''
      case ('outside', 'out')
         outside = .true.
         margin = ''
      case ('below', 'under', 'above', 'over')
         margin = merge('bottom', 'top   ', word == 'below' .or. word == 'under')
         horizontal = 'center'
         h_set = .false.
         layout = .true.
      case ('lmargin', 'lm', 'rmargin', 'rm')
         outside = .true.
         margin = ''
         horizontal = merge('left ', 'right', word(1:1) == 'l')
         h_set = .true.
      case ('tmargin', 'tm', 'bmargin', 'bm')
         margin = merge('top   ', 'bottom', word(1:1) == 't')
      case ('horizontal', 'horiz')
         layout = .true.
      case ('vertical', 'vert')
         layout = .false.
      case default
         bad = word
         return
      endselect
   enddo
   endsubroutine key_position

   pure subroutine push_axes(list, item)
   !< Append `item` to `list` (an unallocated `list` is empty), through a temporary: see `push`.
   type(axes_object), allocatable, intent(inout) :: list(:)  !< List.
   type(axes_object),              intent(in)    :: item     !< New item.
   type(axes_object), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                  :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_axes
endmodule foresight_axes
