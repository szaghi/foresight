!< foresight_script, interpreter of a gnuplot command subset.
module foresight_script
!< foresight_script, interpreter of a gnuplot command subset.
!<
!< Supported (with gnuplot abbreviations):
!<
!< - `NAME = expression` (a user variable, its value now), `NAME(P1, ...) = expression` (a user function, see
!<   foresight_expression); expressions take them everywhere, range ends included (`set xrange [0:2*pi]`);
!< - `set|unset title|xlabel|ylabel|y2label|x2label ["text"]`, `set xrange|yrange|y2range|x2range [min:max]` (`*` or
!<   empty autoscales an end), `set|unset logscale [AXES]` (AXES concatenates x, y, y2, x2, cb, e.g. `xy2`; all when
!<   absent),
!<   `set|unset grid`, `set|unset key`, `set output "file"`, `set terminal svg|html [size W,H] [refresh SECONDS]`;
!< - `set terminal dumb [size COLS,ROWS] [mono|ansi|ansi256|ansirgb]` (text, default 79x24 on standard output `-`),
!<   `set terminal block [half|quadrants|sextants|braille] [size COLS,ROWS] [mono|ansi|ansi256|ansirgb]` (text drawn
!<   with Unicode block or Braille characters);
!< - `set|unset multiplot [layout ROWS,COLS] [title "t"]`: each `plot` fills the next panel, settings carry over;
!<   without layout each panel lies in its `set origin X,Y` / `set size W,H` box (page fractions);
!< - `set xtics|ytics|y2tics|x2tics [auto|STEP|START,STEP[,END]] [mirror|nomirror]` (y2 and x2 ticks are off until
!<   set), `unset xtics|ytics|y2tics|x2tics`, `set format [AXES] ["fmt"]`, `unset format`,
!<   `set key [on|off] [left|right|center] [top|bottom|center] [box|nobox] [autotitle [columnhead]|noautotitle]`,
!<   `set style data|function STYLE`, `unset style function`, `set style line N [lc ...] [lt N] [lw W] [dt N] [pt N]
!<   [ps S]`;
!< - `set datafile separator [whitespace|tab|comma|"chars"]`, `unset datafile [separator]`; `set samples N[,M]`;
!< - `plot 'file' [using [X:]Y[:...]] [index N] [every I:J:K:L:M:N] [with STYLE] [title "t"|notitle] [axes x1y1|x1y2|x2y1|x2y2]
!<   [smooth FILTER] [bins[=N] [binrange [LO:HI]] [binwidth=W] [binvalue=sum|avg]] [lc [rgb] "color"|N] [lw W] [dt N]
!<   [pt N] [ps S], ...` (`''` repeats the previous file; smooth and bins: see foresight_smooth), STYLE
!<   `lines|points|linespoints|impulses|steps|fsteps|histeps|dots|yerrorbars|xerrorbars|xyerrorbars|yerrorlines|
!<   xerrorlines|xyerrorlines` (error bars: `x:y:dy` or `x:y:low:high`, `x:y:dx:dy` or `x:y:xlow:xhigh:ylow:yhigh`),
!<   abbreviated as gnuplot (foresight_style);
!<   `replot [items]`; a `using` field is a column number or a parenthesized expression,
!<   `($2*1e3)` (see foresight_expression), or a column header name, `"residual"`; `title columnhead[(N)]` titles an
!<   item with a column header; `ls N`, `lt N` in an item apply a line style, a linetype color; `set colorsequence
!<   default|podo|classic|NAME [N]` picks the linetype colors (NAME: a categorical order, `batlowS`, ...);
!< - `with boxerrorbars|boxxyerror|candlesticks [whiskerbars [F]]|financebars|boxplot` (gnuplot's layouts), `set style
!<   boxplot [range R|fraction F] [[no]outliers] [pointtype P] [candlesticks|financebars] [medianlinewidth W]
!<   [separation S] [labels off|auto|x] [sorted|unsorted]`;
!< - `with vectors|arrows [head|heads|nohead|backhead] [filled|empty|nofilled|noborder] [size [SYS] L,A] [fixed]
!<   [as|arrowstyle N]`, `with ellipses [units xy]`,
!<   `with polygons`, `with labels [left|center|right] [rotate by A] [offset X,Y] [point] [tc "c"]` (`using x:y:N`, the
!<   text of column N), `with sectors` (gnuplot's layouts); `unset xrange|yrange|y2range` autoscales;
!< - `with parallelaxes [at X]`, `set|unset spiderplot`, `with spiderplot` (`using Y[:key(N)]`, an axis per item, a line or
!<   polygon per row), `set paxis N range [min:max]|tics [...]|label "t"`, `unset paxis N tics`, `set style spiderplot
!<   [fs FILL] [lw W] [pt N] [ps S]`, `set grid spiderplot`;
!< - `with boxes` (`using x:y[:width]`, from y = 0), `with filledcurves [closed|x1|x2|y=V|xy=X,Y] [above|below]`
!<   (`using x:y1:y2` for a band), `with rgbimage|rgbalpha` (`x:y:r:g:b[:a]`), `set|unset rgbmax V`,
!<   `fs|fillstyle FILL` in an item, `set style fill FILL` (FILL: `empty`, `[transparent] solid [D]`, `pattern [N]`,
!<   `border [lc C|-1]`,
!<   `noborder`), `set boxwidth [W] [absolute|relative]`, `unset boxwidth`;
!< - `with histograms` (`using Y[:xtic(N)]`, the rows at the point numbers 0, 1, ...), `set style histogram
!<   clustered [gap G]|errorbars [gap G] [lw W]|rowstacked|columnstacked` (errorbars: `using Y:ERR` or `Y:LOW:HIGH`;
!<   columnstacked: `key(N)` the row names), `plot newhistogram ["title"] [lt N] [fs FILL] [at X], ...` groups;
!<   `using ...:xtic(N)` / `xticlabels(N)`: the text of column N labels the abscissae, the labels replacing the x
!<   ticks; `xtic(EXPR)` a string expression (`strcol(1) . ' K'`); `x2tic`, `ytic`, `y2tic` likewise on their axis (the
!<   ordinates for y and y2; x2 and y2 once their ticks are set); `pi|pointinterval N` a marker every N points,
!<   `pn|pointnumber N` about N; `pt "c"` a character as the point (`tc` its color, `font` ignored);
!<   `set errorbars [small|large|fullwidth|SIZE] [lc C] [lw W]`, `unset errorbars`;
!< - string columns in `using` expressions: `strcol(N)`, `stringcolumn(N)` (N a number or a header name),
!<   `columnhead(N)`, the pseudo-columns `column(-1)` (block) and `column(-2)` (dataset); the text of labels a column
!<   or an expression;
!< - `plot 'file' [matrix] with image` (`using x:y:z` on a regular grid, or the values of a `matrix` file), `set palette
!<   [rgbformulae R,G,B|defined (v c, ...)|cubehelix [start S] [cycles C] [saturation S]|file 'f' [index N] [every E]
!<   [using U]|gray|grey|color|NAME|positive|
!<   negative|maxcolors N|model RGB]` (NAME: a
!<   named palette of foresight_colormaps, `viridis`, `batlow`, ..., any case), `set cbrange [min:max]`,
!<   `set|unset cblabel ["t"]`, `set|unset colorbox [vertical|horizontal] [default|user] [origin X,Y] [size W,H]
!<   [border|bdefault|noborder] [invert|noinvert] [front]`, `set|unset cbtics`, `set format cb`, `set|unset logscale cb`;
!< - `with circles` (`using x:y[:r[:start:end]]`, wedges with angles in degrees); foresight's `with pie [donut F]`
!<   (`using Y[:xtic(N)]`, alone in its panel);
!< - foresight's panel charts: `with gauge range [A:B] [segments N] [format "fmt"]`, `with radar`, `with rose [linear]`
!<   (`using Y[:xtic(N)]`), alone in their panel (several gauges or radars side by side);
!< - `set|unset polar` (items theta:r, functions of `t` over `set trange [min:max]`), `set angles degrees|radians`
!<   (also the trigonometric functions of the expressions), `set|unset theta [right|top|left|bottom] [clockwise|cw|
!<   counterclockwise|ccw]`, `set rrange [min:max]`, `set|unset rtics [...]` (as xtics), `set|unset ttics [[START,]STEP]
!<   [format "fmt"]`, `set|unset raxis`, `set grid [polar [STEP]]`, `set border [MASK] [polar]`, `unset border`,
!<   `set size [square|nosquare|ratio R|noratio] [W,H]`;
!< - foresight extensions: `set terminal ... theme classic|vfd|lcd|washi|night [glow|noglow]` (any terminal), the colors
!<   of a 1980s display or of foresight's identity (see foresight_theme); `fs ... segments N`, bars cut into N cells
!<   over the y range (foresight_style);
!<   `plot ... with readout [format "fmt"]`, the last finite value of the item in seven-segment
!<   digits on a glass of `fmt` (a printf conversion with a field width, `%10.3e` by default; see foresight_readout),
!<   `lc` its only style option; `set readout [on|off] [left|right|center] [top|bottom|center] [horizontal|vertical]
!<   [opaque|noopaque] [size H]`, `unset readout`;
!< - `set label [N] "text" at POS ...`, `set arrow [N] from POS to|rto POS ...`, `set object [N] rectangle|circle|ellipse|
!<   polygon ...`, `unset label|arrow|object [N]`, `set style arrow N ...`, `unset style arrow`, `set style rectangle
!<   ...` (see `annotation_option`, foresight_annotations);
!< - time data: `set xdata|ydata|x2data|y2data [time]` (the x or y field read with `set timefmt "fmt"`, the axis
!<   ticked and labelled in time units), `set format x "%H:%M" [timedate|numeric]`, time strings as range ends and
!<   tick positions, `timecolumn(N[, "fmt"])`, `strftime(fmt, t)`, `strptime(fmt, s)`, `time(0)` (see foresight_time);
!< - datablocks `$NAME << WORD` (the lines up to one starting with WORD) plotted, fitted, stated as a file (`plot $D`),
!<   `print $NAME`, `load FILE`, `call FILE ARG1 ...` (ARG0..ARG9, ARGC, restored after it), `eval STRING`, macros
!<   `@name` (a string variable's value), `undefine NAME|NAME*|$NAME`; `$NAME[i]` a line of a datablock, `|$NAME|`
!<   their number; inline data `'-'` of plot, replot, fit and stats (the lines after the statement up to one starting
!<   with `e`, one block per item);
!< - arrays: `array A[N]`, `array A[N] = [E1, ...]`, `array A = [E1, ...]` (elements of any type, some possibly without
!<   a value), `A[i] = E`, `A[i]` and `|A|` in expressions (an index of a data row resolved on each row), `index(A, V)`,
!<   `print A`, `plot A` and `stats A` (the index and the value of each element, as a file), `ARGV` (the arguments of
!<   `call` and `foresight -c`);
!< - `system("command")` (its standard output, run when the expression is compiled), `system "command"`, `` `command` ``
!<   substitution outside single quotes; `reset [session|errors|bind]` (see `reset_command`); `set table ["file"|$NAME]
!<   [append]`, `unset table` (plots write their points as text, see `write_table`); `pause SECONDS|-1|mouse
!<   ["message"]` (see `pause_command`); `reread` is an error, deprecated in gnuplot 6.0;
!< - a function of `x` as a plot item, `plot sin(x)/x title "sinc"` (same options, styles lines, points or linespoints,
!<   `set style function`, `lines` by default): sampled at `set samples` points (100) over the x range before its
!<   extension to the ticks, the data extent, or [-10:10] with neither; evenly in log x on a log axis.
!< - the pseudo-files `'+'` (samples of a variable, column 1) and `'++'` (a u, v grid, columns 1 and 2), `plot sample
!<   [t=a:b:step] '+' using (t):(f(t))`, an item's `[name=a:b:step]`; `set urange`, `set vrange`, `set isosamples` (the
!<   `'++'` grid; surfaces otherwise), `unset trange|rrange|urange|vrange`.
!< - read and ignored, as they leave gnuplot's 2D svg output unchanged: `set|unset
!<   mouse`, `set|unset macros` (macros always on), `set pointintervalbox`, `set zrange`, `set|unset minussign` and
!<   `set|unset micro` with the default encoding (rejected with utf8, where gnuplot changes the signs); `refresh` is
!<   `replot` without new items; `set|unset overflow [float|undefined|NaN]` (integer overflow, see
!<   `foresight_expression`), `set|unset mttics [N]` (minor ticks on the polar border), `unset samples` (100).
!<
!< Anything else is an error naming the command, never silently ignored. Errors are returned (`iostat`, `iomsg` with
!< `source:line:`), not stopped on, so a watch loop can survive a bad cycle.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite, ieee_is_nan, ieee_quiet_nan, ieee_value
use, intrinsic :: iso_fortran_env, only : error_unit, input_unit, output_unit
use foresight_axes, only : axes_names, axes_object, contour_label, surface_contours, &
                           MAX_LINETYPES, boxplot_style, boxplot_words, polar_series, &
                           spider_words, POLAR_STYLES, colormap_object
use foresight_datafile, only : datafile_object
use foresight_expression, only : block_hook, element_fetch_hook, element_hook, fetch_hook, store_hook, expression_object, &
                                 list_text, push, &
                                 saved_array, saved_variable, &
                                 symbols_object, value_list, value_object, overflow_mode, OVERFLOW_IGNORE, &
                                 OVERFLOW_FLOAT, OVERFLOW_UNDEFINED, OVERFLOW_NAN
use foresight_font, only : font_object, font_of
use foresight_annotations, only : arrow_object, label_object, pixmap_object, place_object, push, shape_object
use foresight_axis, only : axis_object
use foresight_figure, only : figure_object
use foresight_series, only : series_object
use foresight_view3d, only : view3d_object
use foresight_dgrid3d, only : dgrid3d_object, grid_series, DGRID_BOX, DGRID_CAUCHY, DGRID_EXP, DGRID_GAUSS, &
                              DGRID_HANN, DGRID_QNORM, DGRID_SPLINES
use foresight_contour, only : CONTOUR_BSPLINE, CONTOUR_CUBIC, CONTOUR_LINEAR, LEVELS_AUTO, LEVELS_DISCRETE, &
                              LEVELS_INCREMENTAL
use foresight_pm3d, only : pm3d_object, CORNERS_C1, CORNERS_GEOMEAN, CORNERS_HARMEAN, CORNERS_MAX, CORNERS_MEAN, &
                            CORNERS_MEDIAN, CORNERS_MIN, CORNERS_RMS
use foresight_format, only : c_real, decimal_of, decimal_str, format_check, format_decimal, gnuplot_real, int_str, &
                             real_from_decimal
use foresight_readout, only : readout_check
use foresight_sys, only : command_output, sleep_ms
use foresight_time, only : strptime, time_format_check
use foresight_fit, only : fit_model, fit_report, fit_result, fit_settings, levenberg_marquardt
use foresight_stats, only : stats, stats_column, stats_report, stats_result
use foresight_smooth, only : bin_values, CURVE_MODES, path_spline, smooth, smooth_curve, SMOOTH_MODES
use foresight_palette, only : gnuplot_color, hex_color, named_color, palette_gradient, palette_object, palette_words
use foresight_theme, only : THEMES
use foresight_style, only : custom_dashtype, default_color, fill_style, &
                            gnuplot_abbreviates, sequence_colors, style_name, style_object, style_with, &
                            STYLE_NAMES, WITH_GAUGE, WITH_PARALLELAXES, WITH_PIE, WITH_RADAR, WITH_ROSE, WITH_SPIDERPLOT, &
                            FILL_SOLID, FILL_PATTERN, WITH_BOXES, WITH_FILLEDCURVES, WITH_HISTOGRAMS, WITH_LABELS, &
                            WITH_XERRORBARS, WITH_MASK, &
                            WITH_XERRORLINES, &
                            WITH_XYERRORBARS, WITH_XYERRORLINES, WITH_YERRORBARS, WITH_YERRORLINES, &
                            WITH_POINTS, WITH_LINESPOINTS
use foresight_hulls, only : concave_hull, convex_hull, delaunay_triangles, expand_hull
use foresight_ticks, only : MINOR_AUTO, MINOR_DEFAULT, MINOR_NONE, push, tic_item, tics_object, TICS_NONE
use foresight_tokens, only : brace_balance, push, split_statements, strip_comment, token_object, tokenize, TOKEN_COMMA, &
                             TOKEN_RANGE, TOKEN_STRING, TOKEN_WORD, UNAME_CHARS, UNAME_START
use penf, only : I1P, I4P, I8P, R4P, R8P
use befor64, only : b64_encode, b64_init, is_b64_initialized

implicit none
private
public :: script_object

interface push
   !< Append an item through a temporary: nvfortran 26.9 corrupts `list = [list, item]` (and any `list = f(list)`)
   !< when the items hold deferred-length characters.
   module procedure push_line_style
endinterface push

real(R8P), parameter :: DUMB_CELL(2) = [0.55_R8P, 1.25_R8P] !< Text device cell size [font size].
integer(I4P),      parameter :: FOREVER = 1000_I4P !< Values of an unbounded plot iteration, `for [i=A:*]`, at most.
character(len=12), parameter :: LC_VARIABLE     = '*variable'    !< `lc variable` marker in a line color.
character(len=12), parameter :: LC_RGB_VARIABLE = '*rgbvariable' !< `lc rgb variable` marker in a line color.
character(len=12), parameter :: LC_PALETTE_Z    = '*palettez'    !< `lc palette [z]` marker in a line color.
real(R8P),         parameter :: PI_SCRIPT       = 4.0_R8P * atan(1.0_R8P) !< pi.
character(len=12), parameter :: LC_PALETTE_CB   = '*palettecb'   !< `lc palette cb V` marker in a line color.
character(len=12), parameter :: LC_PALETTE_FRAC = '*palettefrac' !< `lc palette frac F` marker in a line color.
character(len=*), parameter :: FUNCTION_STYLES = 'lines, points, linespoints, impulses, steps, fsteps, histeps, dots, '// &
                                                  'boxes, filledcurves or pm3d (splot)' !< Styles
                                                 !< drawing functions.

type :: line_style_object
   !< Line properties: a `set style line`, or the options of a plot item; unallocated means the default.
   integer(I4P)                  :: id = 0_I4P !< Style number.
   character(len=:), allocatable :: lc         !< Color.
   real(R8P),        allocatable :: lw         !< Line width.
   integer(I4P),     allocatable :: dt         !< Dash type.
   real(R8P),        allocatable :: ps         !< Point size.
   integer(I4P),     allocatable :: pt         !< Point type.
   integer(I4P),     allocatable :: pi         !< A point every N (`pointinterval`).
   real(R8P)                     :: palette = 0.0_R8P !< Value of `lc palette cb V` or `frac F`.
   character(len=:), allocatable :: pt_char    !< A character as the point (`pt "c"`).
   integer(I4P),     allocatable :: pn         !< About N points evenly spread (`pointnumber`).
   character(len=:), allocatable :: colormap   !< A named colormap (`lc palette NAME`).
   integer(I4P)                  :: ptdef = 0_I4P !< Default point type from `lt N`/`ls N` (gnuplot), 0 if none.
endtype line_style_object

type :: polar_grid_type
   !< gnuplot's `set polar grid`: the polar grid of `with surface` and the weighting of the data on it.
   integer(I4P) :: theta_segments = 24_I4P      !< Angular segments.
   integer(I4P) :: r_segments = 10_I4P          !< Radial segments.
   integer(I4P) :: mode = 1_I4P                 !< Weighting: 1 qnorm, 2 gauss, 3 cauchy, 4 exp, 5 box.
   integer(I4P) :: norm_q = 1_I4P               !< qnorm power.
   logical      :: kdensity = .false.           !< Sums of weights (a kernel density), not weighted means.
   real(R8P)    :: scale = 1.0_R8P              !< Distance scale of the kernels.
   real(R8P)    :: rmin = 0.0_R8P               !< Radial clipping start (`r [min:max]`).
   real(R8P)    :: rmax = huge(1.0_R8P)         !< Radial clipping end.
   real(R8P)    :: tmin = 0.0_R8P               !< Angular clipping start [deg] (`theta [min:max]`).
   real(R8P)    :: tmax = 360.0_R8P             !< Angular clipping end [deg].
endtype polar_grid_type

type :: loop_level
   !< One `for [...]` clause of a plot item: its variable, values, the value in use and the variable before the loop.
   character(len=:), allocatable   :: name           !< Loop variable.
   type(token_object), allocatable :: values(:)      !< Values, as text.
   logical                         :: words = .false. !< String values.
   integer(I4P)                    :: pos = 1_I4P    !< Value in use.
   type(saved_variable)            :: saved          !< The variable before the loop.
   logical                         :: forever = .false. !< `for [i=A:*]`: until an item yields no valid point.
endtype loop_level

type :: local_state
   !< A variable made `local` in a function block: its state before, restored when the block ends.
   type(saved_variable) :: v !< The variable of the name.
   type(saved_array)    :: a !< The array of the name.
endtype local_state

type :: script_object
   !< Script interpreter state.
   type(figure_object)             :: figure                   !< Figure being built.
   character(len=:), allocatable   :: output                   !< Current output file.
   logical                         :: output_set = .false.     !< Output set by `set output`.
   character(len=:), allocatable   :: default_output           !< The output given at init, back after a bare
                                                               !< `set output`.
   character(len=:), allocatable   :: previous_file            !< File of the last plot item, for `''`.
   character(len=:), allocatable   :: last_plot                !< Items of the last plot, for `replot`.
   type(token_object), allocatable :: data_files(:)            !< Data files read, for watching.
   integer(I4P)                    :: live_refresh = 0_I4P     !< HTML reload period applied when none is set [s].
   logical                         :: multiplot = .false.      !< Inside `set multiplot`.
   logical                         :: parametric = .false.     !< gnuplot `set parametric`: function items in pairs,
                                                                !< x(t), y(t) over trange.
   logical                         :: advance_pending = .false. !< A multiplot panel was plotted: the next command
                                                                !< opens the next panel.
   character(len=:), allocatable   :: data_style               !< Default plot style, `set style data`.
   character(len=:), allocatable   :: function_style           !< Default function style, `set style function`.
   character(len=:), allocatable   :: autotitle                !< Untitled items: `file` (as written), `columnhead`,
                                                                !< `none` (gnuplot `set key [no]autotitle`).
   type(line_style_object), allocatable :: line_styles(:)      !< `set style line` definitions.
   type(polar_grid_type)           :: polar_grid               !< `set polar grid`.
   character(len=:), allocatable   :: separator                !< Data cell separators, empty for whitespace.
   character(len=:), allocatable   :: missing                  !< Missing data string, empty for none.
   character(len=:), allocatable   :: comments                 !< Characters starting a comment in data files.
   logical                         :: textbox_drawn(0:3) = .true. !< `set style textbox [N]`: the boxed texts of style N
                                                               !< have their box (opaque, or a border: gnuplot's svg
                                                               !< draws the background then).
   logical                         :: column_headers = .false. !< `set datafile columnheaders`: the first row of each
                                                               !< dataset is a header.
   integer(I4P)                    :: samples = 100_I4P        !< Function samples, `set samples`.
   real(R8P)                       :: rgbmax = 255.0_R8P       !< Full intensity of RGB image components, `set rgbmax`.
   integer(I4P)                    :: binary_count = 0_I4P     !< Datablocks made of binary files (`$__binaryN`).
   real(R8P)                       :: chi_fraction = 0.6_R8P   !< Default concave hull length, a fraction of the longest
                                                               !< convex hull edge (`set chi_shape fraction`).
   type(symbols_object)            :: symbols                  !< User variables and functions, `a = 2`, `f(x) = ...`.
   type(fit_settings)              :: fit_options              !< `set fit` limit, maxiter, lambda, scaling options.
   character(len=7)                :: fit_verbosity = 'quiet'  !< `set fit quiet|results|brief`: the report on the
                                                               !< standard error (none by default, unlike gnuplot).
   character(len=:), allocatable   :: fit_logfile              !< `set fit logfile`, empty for none (the default).
   logical                         :: fit_errorvariables = .true. !< `set fit errorvariables`: NAME_err set.
   character(len=:), allocatable   :: timefmt                  !< Input time format, gnuplot `set timefmt`.
   logical                         :: time_data(4) = .false.   !< Time data on x, y, y2, x2 (`set xdata time`).
   character(len=:), allocatable   :: print_file               !< `set print`: '' the standard error (gnuplot's
                                                               !< default), '-' the standard output, else a file.
   integer(I4P)                    :: loop_depth = 0_I4P       !< Loops (`do for`, `while`) being run.
   integer(I4P)                    :: loop_signal = 0_I4P      !< `break` (1) or `continue` (2) pending, else 0.
   logical                         :: table = .false.          !< `set table`: plots write their points as text.
   type(arrow_object), allocatable :: arrow_styles(:)          !< `set style arrow N` definitions (their tags).
   type(shape_object)              :: rectangle_style          !< `set style rectangle`: new rectangles' style.
   character(len=:), allocatable   :: table_file               !< Where: a file, a datablock (`$NAME`), '-' the
                                                               !< standard output.
   character(len=1)                :: table_sep = achar(9)     !< `set table separator`, of `plot with table`.
   integer(I4P)                    :: block_depth = 0_I4P      !< Function blocks running.
   logical                         :: returned = .false.       !< `return EXPR` gave the running block a value.
   type(value_object)              :: return_value             !< That value.
   type(local_state), allocatable  :: locals(:)                !< Variables made `local` by the running blocks.
   character(len=:), allocatable   :: encoding                 !< `set encoding`: GPVAL_ENCODING, `default` or `utf8`.
   logical                         :: minus_sign = .false.     !< `set minussign`: no effect with the default encoding.
   logical                         :: micro = .false.          !< `set micro`: no effect with the default encoding.
   character(len=:), allocatable   :: term_name                !< The terminal: GPVAL_TERM.
   integer(I4P), public            :: exit_status = 0_I4P      !< `exit status N`: the status the run ends with.
   character(len=:), allocatable   :: dummy                    !< `set dummy NAME`: the functions' variable, empty for
                                                               !< gnuplot's (x, t in polar mode).
   integer(I4P)                    :: isosamples = 10_I4P      !< `set isosamples N,M`: M, the v samples of `'++'`
                                                               !< and the iso-curves of y of the splot functions.
   integer(I4P)                    :: isosamples1 = 10_I4P     !< N: the iso-curves of x of the splot functions.
   integer(I4P)                    :: samples2 = 100_I4P       !< `set samples N,M`: M, the samples along y of the
                                                               !< splot functions' iso-curves of x.
   logical                         :: last_splot = .false.     !< The last plot a splot (for replot, refresh).
   real(R8P)                       :: uv_range(2, 2) = reshape([-5.0_R8P, 5.0_R8P, -5.0_R8P, 5.0_R8P], [2, 2])
                                                               !< `set urange`, `set vrange` (columns u, v).
   character(len=:), allocatable   :: data_curve               !< `set style data filledcurves OPTIONS`: the options
                                                               !< of the data filledcurves given none.
   character(len=:), allocatable   :: function_curve           !< The same of the functions (`set style function`).
   character(len=64), allocatable  :: colormap_names(:)        !< Named colormaps (`set colormap new NAME`).
   character(len=:), allocatable   :: dummies                  !< `set dummy` names, blank separated (the variables of
                                                               !< a fit of several), empty for gnuplot's x y.
   type(colormap_object), allocatable :: colormaps(:)          !< Their palettes and ranges.
   contains
      procedure, pass(self) :: execute                !< Execute one statement.
      procedure, pass(self) :: init                   !< Reset the interpreter.
      procedure, pass(self) :: run_file               !< Run a script file.
      procedure, pass(self) :: run_text               !< Run script text.
      procedure, pass(self), private :: assignment    !< `a = 2`, `f(x) = ...`.
      procedure, pass(self), private :: plot_command  !< `plot`.
      procedure, pass(self), private :: plot_items    !< `plot` items, binary files as datablocks.
      procedure, pass(self), private :: binary_items  !< Binary files of `plot` items as datablocks.
      procedure, pass(self), private :: reset_command !< `reset`.
      procedure, pass(self), private :: pause_command !< `pause`.
      procedure, pass(self), private :: write_table   !< The points of a plot as text (`set table`).
      procedure, pass(self), private :: fit_command   !< `fit`.
      procedure, pass(self), private :: print_command !< `print`.
      procedure, pass(self), private :: stats_command !< `stats`.
      procedure, pass(self), private :: load_data     !< Load a data file or a datablock.
      procedure, pass(self), private :: set_time_data !< `set xdata time`, `set xdata`.
      procedure, pass(self), private :: range_value   !< Value of a range end.
      procedure, pass(self), private :: colormap_index !< Index of a named colormap, 0 if none.
      procedure, pass(self), private :: annotation_option !< `set label`, `set arrow`, `set object`.
      procedure, pass(self), private :: call_command  !< `load`, `call`.
      procedure, pass(self), private :: expand_macros !< `@name` substitution.
      procedure, pass(self), private :: do_block      !< `do for [...] { ... }`.
      procedure, pass(self), private :: set_for       !< `set for [...] OPTION`, `unset for [...] OPTION`.
      procedure, pass(self), private :: while_block   !< `while (...) { ... }`.
      procedure, pass(self), private :: if_block      !< `if (...) { ... } else ...`.
      procedure, pass(self), private :: run_body      !< The statements of a block.
      procedure, pass(self), private :: old_if_line   !< gnuplot's old one-line if.
      procedure, pass(self), private :: run_list      !< Statements in order.
      procedure, pass(self), private :: run_loops     !< Nested `for` clauses of a block.
      procedure, pass(self), private :: string_expression !< A string expression across tokens.
      procedure, pass(self), private :: string_argument   !< The string after a set option.
      procedure, pass(self), private :: text_color        !< The color after `tc`.
      procedure, pass(self), private :: register_file !< Remember a data file.
      procedure, pass(self), private :: save_output   !< Render to the current output.
      procedure, pass(self), private :: set_command   !< `set`.
      procedure, pass(self), private :: unset_command !< `unset`.
      procedure, pass(self), private :: exit_command  !< `exit`, `quit`.
endtype script_object

type, extends(fit_model) :: script_model
   !< A `fit` model: a user expression of x whose parameters are user variables, set and the expression compiled again
   !< for each parameter vector (a user variable is a constant of a compiled expression).
   character(len=:), allocatable  :: text     !< Model expression.
   character(len=32), allocatable :: names(:) !< Parameter names.
   real(R8P), allocatable         :: x(:)     !< Abscissae.
   logical                        :: degrees = .false. !< Angles in degrees.
   type(symbols_object)           :: symbols  !< User variables and functions, a copy of the script's.
   real(R8P), allocatable         :: xs(:,:)  !< Independent variables of each point (point, variable), several.
   character(len=:), allocatable  :: vars     !< Their names, blank separated (columns 1, 2, ... of a row).
   contains
      procedure, pass(self) :: values => script_model_values !< Values at the abscissae.
endtype script_model

class(script_object), pointer :: active => null() !< The interpreter running (function blocks run in it).

contains
   subroutine init(self, output, theme)
   !< Reset the interpreter; plots go to `output` until `set output`, in the output `theme` (see foresight_theme, blank
   !< or absent: `classic`) until `set terminal ... theme`.
   class(script_object), intent(inout)        :: self   !< Interpreter.
   character(len=*),     intent(in)           :: output !< Default output file.
   character(len=*),     intent(in), optional :: theme  !< Default output theme.

   call self%figure%init
   ! gnuplot's enhanced text, on by default in the scripts (its svg and dumb terminals)
   call self%figure%set_enhanced(.true.)
   ! gnuplot's default tick labels, `% h` (100000, not 1x10^5): the scripts' (the library keeps its rule)
   self%figure%gnuplot_labels = .true.
   if (present(theme)) then
      if (len_trim(theme) > 0) call self%figure%set_theme(name=trim(theme))
   endif
   self%output = output
   self%default_output = output
   self%output_set = .false.
   self%multiplot = .false.
   self%advance_pending = .false.
   self%previous_file = ''
   self%last_plot = ''
   if (allocated(self%data_files)) deallocate(self%data_files)
   allocate(self%data_files(0))
   self%data_style = 'lines'
   self%function_style = 'lines'
   self%data_curve = ''
   self%function_curve = ''
   self%autotitle = 'file'
   if (allocated(self%line_styles)) deallocate(self%line_styles)
   allocate(self%line_styles(0))
   self%separator = ''
   self%missing = ''
   self%comments = '#'
   self%column_headers = .false.
   self%samples = 100_I4P
   self%isosamples = 10_I4P
   self%isosamples1 = 10_I4P
   self%samples2 = 100_I4P
   self%uv_range = reshape([-5.0_R8P, 5.0_R8P, -5.0_R8P, 5.0_R8P], [2, 2])
   self%rgbmax = 255.0_R8P
   self%chi_fraction = 0.6_R8P
   self%polar_grid = polar_grid_type()
   ! a new session: gnuplot's program settings at start
   overflow_mode = OVERFLOW_FLOAT
   self%minus_sign = .false.
   self%micro = .false.
   call self%symbols%clear
   call self%symbols%set_value('ARGC', 0.0_R8P, is_int=.true.)
   call self%symbols%set_array('ARGV', [character(len=1) ::])
   self%timefmt = '%d/%m/%y,%H:%M'
   self%symbols%timefmt = self%timefmt
   self%time_data = .false.
   self%fit_options = fit_settings()
   self%fit_verbosity = 'quiet'
   self%fit_logfile = ''
   self%fit_errorvariables = .true.
   self%print_file = ''
   self%loop_depth = 0_I4P
   self%loop_signal = 0_I4P
   self%table = .false.
   self%table_file = ''
   self%table_sep = achar(9)
   self%block_depth = 0_I4P
   self%returned = .false.
   if (allocated(self%locals)) deallocate(self%locals)
   allocate(self%locals(0))
   self%exit_status = 0_I4P
   self%dummy = ''
   self%dummies = ''
   self%parametric = .false.
   self%encoding = 'default'
   self%term_name = 'html'
   if (len(output) > 4) then
      if (output(len(output) - 3:) == '.svg') self%term_name = 'svg'
   endif
   call gnuplot_values(self)
   block_hook => run_block
   store_hook => store_variable
   element_hook => store_element
   element_fetch_hook => fetch_element
   fetch_hook => fetch_variable
   call default_styles(self)
   endsubroutine init

   subroutine gnuplot_values(self)
   !< gnuplot's GPVAL_* variables of foresight: the gnuplot version it follows (6.0, patchlevel 0), its compile options
   !< (only those of gnuplot that foresight has: scripts test them to skip what is missing), the encoding, the
   !< terminal and the terminals, the system.
   class(script_object), intent(inout) :: self    !< Interpreter.
   character(len=:), allocatable       :: text    !< Command output.
   integer(I4P)                        :: status  !< Command status.

   call self%symbols%set_value('GPVAL_VERSION', 6.0_R8P, is_int=.false.)
   call self%symbols%set_string('GPVAL_PATCHLEVEL', '0')
   call self%symbols%set_string('GPVAL_COMPILE_OPTIONS', '+OBJECTS +STATS +POLARGRID +FUNCTIONBLOCKS '// &
                                '+CHI_SHAPES -LIBCERF -COMPLEX_FUNCS -WATCHPOINTS -EXTERNAL_FUNCTIONS')
   call self%symbols%set_string('GPVAL_ENCODING', self%encoding)
   call self%symbols%set_string('GPVAL_TERM', self%term_name)
   call self%symbols%set_string('GPVAL_TERMINALS', 'block dumb html svg')
   call self%symbols%set_string('GPVAL_DEGREE_SIGN', achar(194)//achar(176))
   call command_output('uname -s', text, status)
   if (status /= 0_I4P .or. len(text) == 0) text = 'unknown'
   if (text(len(text):len(text)) == new_line('a')) text = text(1:len(text) - 1)
   call self%symbols%set_string('GPVAL_SYSNAME', text)
   call command_output('uname -m', text, status)
   if (status /= 0_I4P .or. len(text) == 0) text = 'unknown'
   if (text(len(text):len(text)) == new_line('a')) text = text(1:len(text) - 1)
   call self%symbols%set_string('GPVAL_MACHINE', text)
   endsubroutine gnuplot_values

   subroutine store_variable(name, v)
   !< An assignment run by an expression (foresight_expression's `store_hook`), `(a = 2, a + 1)`: the variable of the
   !< active interpreter set.
   character(len=*),   intent(in) :: name !< Variable name.
   type(value_object), intent(in) :: v    !< Value.

   if (associated(active)) call active%symbols%put(name, v)
   endsubroutine store_variable

   subroutine store_element(name, i, v, ok)
   !< An array element assigned by an expression (foresight_expression's `element_hook`), `(A[$0+1] = $2)`: the element
   !< of the active interpreter's array set, `ok` false if out of range.
   character(len=*),   intent(in)  :: name !< Array name.
   integer(I8P),       intent(in)  :: i    !< Element.
   type(value_object), intent(in)  :: v    !< Value.
   logical,            intent(out) :: ok   !< Stored.

   ok = .false.
   if (associated(active)) call active%symbols%set_element(name, i, v, ok)
   endsubroutine store_element

   subroutine fetch_element(name, i, v, found, set)
   !< An array element read when an expression runs that assigns elements of it (foresight_expression's
   !< `element_fetch_hook`): the element of the active interpreter's array.
   character(len=*),   intent(in)  :: name  !< Array name.
   integer(I8P),       intent(in)  :: i     !< Element.
   type(value_object), intent(out) :: v     !< Value.
   logical,            intent(out) :: found !< In range.
   logical,            intent(out) :: set   !< With a value.

   v = value_object()
   found = .false.
   set = .false.
   if (associated(active)) call active%symbols%get_element(name, i, v, found, set)
   endsubroutine fetch_element

   subroutine fetch_variable(name, v, found)
   !< The value of a variable an expression assigns, read when it runs (foresight_expression's `fetch_hook`).
   character(len=*),   intent(in)  :: name  !< Variable name.
   type(value_object), intent(out) :: v     !< Value.
   logical,            intent(out) :: found !< A variable of that name.

   v = value_object()
   found = .false.
   if (associated(active)) call active%symbols%get(name, v, found)
   endsubroutine fetch_variable

   recursive subroutine run_block(name, args, result, ok, message)
   !< gnuplot 6.0 function block `name` called on `args` (foresight_expression's `block_hook`): its body run by the
   !< active interpreter with ARGC and ARGV the arguments (restored after), the variables made `local` restored when it
   !< ends; the value of its `return`, `ok` false if none (undefined) or if it failed (`message`).
   character(len=*),              intent(in)  :: name       !< Block name.
   type(value_object),            intent(in)  :: args(:)    !< Arguments.
   type(value_object),            intent(out) :: result     !< Returned value.
   logical,                       intent(out) :: ok         !< A value returned.
   character(len=:), allocatable, intent(out) :: message    !< Error, empty if none.
   type(saved_variable)                       :: saved_argc !< ARGC before.
   type(saved_array)                          :: saved_argv !< ARGV before.
   type(value_list)                           :: argv       !< The arguments, as ARGV.
   type(local_state), allocatable             :: kept(:)    !< Locals of the callers.
   character(len=:), allocatable              :: body       !< Block body.
   character(len=:), allocatable              :: msg        !< Error of the body.
   integer(I4P)                               :: first      !< Locals before the call.
   integer(I4P)                               :: k          !< Counter.
   integer(I4P)                               :: iostat     !< Status.
   logical                                    :: found      !< Block found.
   logical                                    :: returned   !< A value returned.

   ok = .false.
   message = ''
   if (.not. associated(active)) then
      message = 'function blocks run in a script'
      return
   endif
   if (active%block_depth >= 250_I4P) then
      message = 'recursion depth limit exceeded'
      return
   endif
   call active%symbols%string_of(name, body, found)
   if (.not. found .or. .not. active%symbols%is_block(name)) then
      message = 'Not a function block: '//name
      return
   endif
   call active%symbols%save_variable('ARGC', saved_argc)
   call active%symbols%save_array('ARGV', saved_argv)
   call active%symbols%set_value('ARGC', real(size(args), R8P), is_int=.true.)
   allocate(argv%items(size(args)), argv%set(size(args)))
   do k = 1_I4P, size(args, kind=I4P)
      argv%items(k) = args(k)
   enddo
   argv%set = .true.
   call active%symbols%store_array('ARGV', argv, iostat, msg)
   first = size(active%locals, kind=I4P)
   active%block_depth = active%block_depth + 1_I4P
   active%returned = .false.
   call active%run_text(body, iostat, msg, source=name)
   if (active%loop_signal == 3_I4P) active%loop_signal = 0_I4P
   returned = active%returned
   if (returned) result = active%return_value
   active%returned = .false.
   do k = size(active%locals, kind=I4P), first + 1_I4P, -1_I4P
      call active%symbols%restore_array(active%locals(k)%a)
      call active%symbols%restore(active%locals(k)%v)
   enddo
   if (size(active%locals, kind=I4P) > first) then
      ! through a temporary (nvfortran 26.9: see foresight_tokens push)
      allocate(kept(first))
      if (first > 0_I4P) kept(:) = active%locals(1:first)
      call move_alloc(kept, active%locals)
   endif
   call active%symbols%restore(saved_argc)
   call active%symbols%restore_array(saved_argv)
   active%block_depth = active%block_depth - 1_I4P
   if (iostat /= 0_I4P) then
      message = msg
      return
   endif
   ok = returned
   endsubroutine run_block

   recursive subroutine run_file(self, file, iostat, iomsg, args)
   !< Run the script `file`. With `args` (as gnuplot's `gnuplot -c FILE ARG1 ...`), ARG0 is the file name, ARG1 to
   !< ARG9 the arguments (empty beyond them), ARGC their number.
   class(script_object),          intent(inout)        :: self    !< Interpreter.
   character(len=*),              intent(in)           :: file    !< Script file.
   integer(I4P),                  intent(out)          :: iostat  !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg   !< Error message.
   character(len=*),              intent(in), optional :: args(:) !< Script arguments, at most 9.
   character(len=*), parameter                         :: DIGITS = '0123456789' !< Argument numbers.
   integer(I4P)                                        :: k       !< Argument counter.
   character(len=:), allocatable                :: text    !< Script text.
   character(len=256)                           :: message !< I/O message.
   integer(I4P)                                 :: unit    !< File unit.
   integer(I4P)                                 :: bytes   !< File size.

   iomsg = ''
   if (present(args)) then
      if (size(args) > 9) then
         call fail('at most 9 script arguments', iostat, iomsg)
         return
      endif
      call self%symbols%set_string('ARG0', file)
      do k = 1_I4P, 9_I4P
         if (k <= size(args, kind=I4P)) then
            call self%symbols%set_string('ARG'//DIGITS(k + 1_I4P:k + 1_I4P), trim(args(k)))
         else
            call self%symbols%set_string('ARG'//DIGITS(k + 1_I4P:k + 1_I4P), '')
         endif
      enddo
      call self%symbols%set_value('ARGC', real(size(args), R8P), is_int=.true.)
      call self%symbols%set_array('ARGV', args)
   endif
   open(newunit=unit, file=file, access='stream', form='unformatted', action='read', status='old', &
        iostat=iostat, iomsg=message)
   if (iostat /= 0_I4P) then
      iomsg = 'cannot open script "'//file//'": '//trim(message)
      return
   endif
   inquire(unit=unit, size=bytes)
   allocate(character(len=max(0_I4P, bytes)) :: text)
   if (bytes > 0_I4P) read(unit, iostat=iostat) text
   close(unit)
   if (iostat /= 0_I4P) then
      iomsg = 'cannot read script "'//file//'"'
      return
   endif
   call self%run_text(text, iostat, iomsg, source=file)
   ! a return ends this file only
   if (self%loop_signal == 3_I4P .and. self%block_depth == 0_I4P) self%loop_signal = 0_I4P
   endsubroutine run_file

   recursive subroutine run_text(self, text, iostat, iomsg, source)
   !< Run script `text`: lines ending in `\` continue on the next one; the first error stops the run. A line
   !< `$NAME << WORD` starts a datablock: the lines after it, as they are, up to a line starting with WORD; a line
   !< `function $NAME << WORD` a function block (gnuplot 6.0). A `return` ends the run.
   class(script_object),          intent(inout), target :: self      !< Interpreter.
   character(len=*),              intent(in)           :: text       !< Script text.
   integer(I4P),                  intent(out)          :: iostat     !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg      !< Error message, `source:line: ...`.
   character(len=*),              intent(in), optional :: source     !< Source name for messages.
   character(len=:), allocatable                       :: line       !< Logical line.
   character(len=:), allocatable                       :: name       !< Source name.
   integer(I4P)                                        :: start      !< Current physical line start.
   integer(I4P)                                        :: finish     !< Current physical line end.
   integer(I4P)                                        :: lineno     !< Current physical line number.
   integer(I4P)                                        :: first_line !< First physical line of the logical line.
   character(len=:), allocatable                       :: block      !< Lines of an open block, `{` not yet closed.
   character(len=:), allocatable                       :: code       !< Logical line without its comment.
   integer(I4P)                                        :: depth      !< Open braces of the block.
   integer(I4P)                                        :: block_line !< First line of the block.
   character(len=:), allocatable                       :: here_name  !< Datablock being read, empty if none.
   character(len=:), allocatable                       :: here_end   !< Its terminator.
   character(len=:), allocatable                       :: here_text  !< Its lines.
   integer(I4P)                                        :: here_line  !< Its first line.
   logical                                             :: here_function !< A function block, not a datablock.
   integer(I4P)                                        :: semicolon     !< Last statement separator of the line.
   character(len=:), allocatable                       :: inline_quotes !< Quotes of the inline data items (`'-'`) of
                                                                        !< the pending line, empty if none.
   character(len=:), allocatable                       :: inline_text   !< Lines of the inline data being read.
   character(len=:), allocatable                       :: pending       !< Line run once its inline data are read.
   character(len=:), allocatable                       :: data_line     !< An inline data line, blanks skipped.
   integer(I4P)                                        :: inline_k      !< Inline data item being read.
   integer(I4P)                                        :: pending_line  !< First line of the pending line.

   active => self
   ! after quit (or exit status N), nothing more runs
   if (self%loop_signal == 4_I4P) return
   here_function = .false.
   iostat = 0_I4P
   iomsg = ''
   inline_quotes = ''
   inline_text = ''
   pending = ''
   inline_k = 0_I4P
   pending_line = 0_I4P
   here_name = ''
   here_end = ''
   here_text = ''
   here_line = 0_I4P
   block = ''
   depth = 0_I4P
   block_line = 0_I4P
   name = 'script'
   if (present(source)) name = source
   line = ''
   lineno = 0_I4P
   first_line = 1_I4P
   start = 1_I4P
   do while (start <= len(text))
      finish = index(text(start:), new_line('a'), kind=I4P)
      if (finish == 0_I4P) then
         finish = len(text, kind=I4P)
      else
         finish = start + finish - 2_I4P
      endif
      lineno = lineno + 1_I4P
      if (len(inline_quotes) > 0) then
         ! inline data of the pending line (gnuplot's '-'): the lines up to one starting with `e`, blanks skipped
         line = text(start:finish)
         start = finish + 2_I4P
         if (len(line) > 0) then
            if (line(len(line):len(line)) == achar(13)) line = line(1:len(line) - 1)
         endif
         data_line = trim(adjustl(line))
         if (len(data_line) > 0) then
            if (data_line(1:1) == 'e') then
               call self%symbols%set_string(inline_name(inline_quotes(inline_k:inline_k), inline_k), inline_text)
               inline_text = ''
               inline_k = inline_k + 1_I4P
               line = ''
               if (inline_k > len(inline_quotes, kind=I4P)) then
                  inline_quotes = ''
                  first_line = pending_line
                  call take(pending)
                  if (iostat /= 0_I4P) return
                  if (self%loop_signal >= 3_I4P) exit
               endif
               cycle
            endif
         endif
         inline_text = inline_text//line//new_line('a')
         line = ''
         cycle
      endif
      if (len(here_name) > 0) then
         ! a datablock line, as it is (a carriage return dropped)
         line = text(start:finish)
         start = finish + 2_I4P
         if (len(line) > 0) then
            if (line(len(line):len(line)) == achar(13)) line = line(1:len(line) - 1)
         endif
         if (index(line, here_end) == 1) then
            if (here_function) then
               call self%symbols%define_block(here_name, here_text)
            else
               call self%symbols%set_string(here_name, here_text)
            endif
            here_name = ''
         else
            here_text = here_text//line//new_line('a')
         endif
         line = ''
         cycle
      endif
      if (len(line) == 0) first_line = lineno
      line = line//text(start:finish)
      start = finish + 2_I4P
      if (len(line) > 0) then
         if (line(len(line):len(line)) == achar(13)) line = line(1:len(line) - 1)
      endif
      if (len(line) > 0) then
         if (line(len(line):len(line)) == '\') then
            line = line(1:len(line) - 1)
            cycle
         endif
      endif
      here_function = .false.
      if (len(block) == 0 .and. leading_word(line) == 'function') then
         ! function $NAME << WORD
         here_function = heredoc(trim(adjustl(line(index(line, 'function') + 8:))), here_name, here_end)
         if (.not. here_function) then
            call fail('function: function $NAME << WORD expected', iostat, iomsg)
            iomsg = name//':'//int_str(int(first_line, I8P))//': '//iomsg
            return
         endif
         here_text = ''
         here_line = first_line
         line = ''
         cycle
      endif
      if (len(block) == 0 .and. heredoc(line, here_name, here_end)) then
         here_text = ''
         here_line = first_line
         line = ''
         cycle
      endif
      if (len(block) == 0) then
         ! `set polar; $P << EOD`: the commands before the datablock run, then its lines are read, as gnuplot
         semicolon = last_semicolon(line)
         if (semicolon > 0_I4P) then
            if (heredoc(line(semicolon + 1_I4P:), here_name, here_end)) then
               call take(line(1:semicolon - 1_I4P))
               if (iostat /= 0_I4P) return
               here_text = ''
               here_line = first_line
               line = ''
               cycle
            endif
         endif
      endif
      if (len(block) == 0) then
         ! a plot of inline data ('-'): run once the data lines after it are read
         call inline_items(line, pending, inline_quotes)
         if (len(inline_quotes) > 0) then
            inline_k = 1_I4P
            inline_text = ''
            pending_line = first_line
            line = ''
            cycle
         endif
      endif
      call take(line)
      if (iostat /= 0_I4P) return
      line = ''
      if (self%loop_signal >= 3_I4P) exit
   enddo
   if (self%loop_signal == 4_I4P) return
   if (self%loop_signal == 3_I4P) then
      ! return: the rest is not run; outside a function block, script text run directly ends here
      if (self%block_depth == 0_I4P .and. .not. present(source)) self%loop_signal = 0_I4P
      return
   endif
   ! a continuation on the last line
   if (len(line) > 0) call take(line)
   if (iostat /= 0_I4P) return
   if (len(block) > 0) then
      call fail('"{" not closed', iostat, iomsg)
      iomsg = name//':'//int_str(int(block_line, I8P))//': '//iomsg
   endif
   if (len(here_name) > 0) then
      call fail('datablock '//here_name//': no line "'//here_end//'" ends it', iostat, iomsg)
      iomsg = name//':'//int_str(int(here_line, I8P))//': '//iomsg
   endif
   if (len(inline_quotes) > 0) then
      call fail("inline data '-': no line ""e"" ends it", iostat, iomsg)
      iomsg = name//':'//int_str(int(pending_line, I8P))//': '//iomsg
   endif
   contains
      recursive subroutine take(logical_line)
      !< Execute a logical line, or keep it while a block (`do for [...] {`, `if (...) {`) is open.
      character(len=*), intent(in) :: logical_line !< Logical line.

      code = strip_comment(logical_line)
      if (len(block) == 0 .and. brace_balance(code) <= 0) then
         call process(logical_line, first_line)
         return
      endif
      if (len(block) == 0) block_line = first_line
      block = block//code//new_line('a')
      depth = depth + brace_balance(code)
      if (depth <= 0_I4P) then
         call process(block, block_line)
         block = ''
         depth = 0_I4P
      endif
      endsubroutine take

      recursive subroutine process(logical_line, at)
      !< Execute the statements of a logical line (or of a block over several lines) starting at line `at`.
      character(len=*), intent(in)    :: logical_line  !< Logical line.
      integer(I4P),     intent(in)    :: at            !< Its first line.
      type(token_object), allocatable :: statements(:) !< Statements.
      integer(I4P)                    :: s             !< Statement counter.
      integer(I4P)                    :: e             !< Last statement of an old if's line.

      call split_statements(logical_line, statements)
      ! gnuplot's GPVAL_LINENO: the last line read of the statement in its file (a continued line's last, the line
      ! closing a block for the statements in it)
      call self%symbols%set_value('GPVAL_LINENO', real(max(at, lineno), R8P), is_int=.true.)
      s = 1_I4P
      do while (s <= size(statements, kind=I4P))
         if (old_if(statements(s)%text)) then
            ! gnuplot's old one-line if: the statements of its line are its own
            e = same_line_end(logical_line, statements, s)
            call self%old_if_line(statements(s:e), iostat, iomsg)
            s = e
         else
            call self%execute(statements(s)%text, iostat, iomsg)
         endif
         if (iostat /= 0_I4P) then
            iomsg = name//':'//int_str(int(at, I8P))//': '//iomsg
            return
         endif
         if (self%loop_signal >= 3_I4P) return
         s = s + 1_I4P
      enddo
      endsubroutine process
   endsubroutine run_text

   recursive subroutine execute(self, statement, iostat, iomsg)
   !< Execute one statement.
   class(script_object),          intent(inout), target :: self !< Interpreter.
   character(len=*),              intent(in)    :: statement !< Statement.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   type(token_object), allocatable              :: tokens(:) !< Statement tokens.
   character(len=:), allocatable                :: command   !< Command word.
   character(len=:), allocatable                :: expanded  !< Statement after `@name` substitution.
   character(len=:), allocatable                :: text      !< String argument.
   integer(I4P)                                 :: i         !< Token counter.

   ! function blocks called by the expressions run in this interpreter
   active => self
   ! blocks, flow control (their bodies are expanded statement by statement, when they run)
   command = leading_word(statement)
   if (.not. is_word(command, 'do while if else')) then
      call self%expand_macros(statement, expanded, iostat, iomsg)
      if (iostat /= 0_I4P) return
      if (expanded /= statement) then
         call self%execute(expanded, iostat, iomsg)
         return
      endif
      call expand_backquotes(statement, expanded, iostat, iomsg)
      if (iostat /= 0_I4P) return
      if (expanded /= statement) then
         call self%execute(expanded, iostat, iomsg)
         return
      endif
   endif
   ! `set for [...] ...`, `unset for [...] ...` (not `set format`)
   if (keyword(command, 'set', 2_I4P) .or. keyword(command, 'unset', 3_I4P)) then
      if (for_follows(statement, command)) then
         call self%set_for(statement, iostat, iomsg)
         return
      endif
   endif
   select case (command)
   case ('do')
      call self%do_block(statement, iostat, iomsg)
      return
   case ('while')
      call self%while_block(statement, iostat, iomsg)
      return
   case ('if')
      call self%if_block(statement, iostat, iomsg)
      return
   case ('else')
      call fail('else without if (else follows "}" on the same line)', iostat, iomsg)
      return
   case ('exit', 'quit')
      ! gnuplot: exit [message "text"] ends the script file being read (a load returns to its caller); quit, exit
      ! gnuplot and exit status N end the whole run (N its status); exit error "text" fails with the text
      iostat = 0_I4P
      iomsg = ''
      call self%exit_command(statement, command, iostat, iomsg)
      return
   case ('return')
      ! gnuplot 6.0: the value of the running function block; outside one, the end of the script file being read
      iostat = 0_I4P
      iomsg = ''
      text = trim(adjustl(statement))
      text = trim(adjustl(text(7:)))
      self%returned = .false.
      if (len(text) > 0) then
         block
            type(value_object) :: v !< Returned value.

            call self%symbols%evaluate_constant(text, v, iostat, iomsg, &
                                                degrees=self%figure%panels(self%figure%current)%degrees, undefined=.true.)
            if (iostat /= 0_I4P) then
               iomsg = 'return: '//iomsg
               return
            endif
            self%return_value = v
            self%returned = .true.
         endblock
      endif
      self%loop_signal = 3_I4P
      return
   case ('local')
      ! gnuplot 6.0: in a function block the variable (or array) is restored when the block ends; outside one, a plain
      ! assignment
      text = trim(adjustl(statement))
      text = trim(adjustl(text(6:)))
      if (self%block_depth > 0_I4P) then
         block
            character(len=:), allocatable :: local_name !< Variable name.
            type(local_state)             :: state      !< Its state before.
            integer(I4P)                  :: e          !< End of the name.

            local_name = text
            if (leading_word(local_name) == 'array') local_name = trim(adjustl(local_name(6:)))
            e = verify(local_name, UNAME_CHARS, kind=I4P)
            if (e > 0_I4P) local_name = local_name(1:e - 1_I4P)
            if (len(local_name) == 0) then
               call fail('local: a variable name is expected', iostat, iomsg)
               return
            endif
            call self%symbols%save_variable(local_name, state%v)
            call self%symbols%save_array(local_name, state%a)
            call push_local(self%locals, state)
         endblock
      endif
      call self%execute(text, iostat, iomsg)
      return
   case ('break', 'continue')
      iostat = 0_I4P
      iomsg = ''
      if (trim(adjustl(statement)) /= command) then
         call fail(command//' takes nothing after it', iostat, iomsg)
      elseif (self%loop_depth == 0_I4P) then
         call fail(command//' outside a loop', iostat, iomsg)
      else
         self%loop_signal = merge(1_I4P, 2_I4P, command == 'break')
      endif
      return
   endselect
   if (self%assignment(statement, iostat, iomsg)) return
   call tokenize(statement, tokens, iostat, iomsg)
   if (iostat /= 0_I4P) return
   if (size(tokens) == 0) return
   ! `rgb NAME`, a string variable holding the color (gnuplot reads a string expression there)
   do i = 2_I4P, size(tokens, kind=I4P)
      if (tokens(i)%kind /= TOKEN_WORD .or. tokens(i - 1_I4P)%kind /= TOKEN_WORD) cycle
      if (.not. keyword(tokens(i - 1_I4P)%text, 'rgbcolor', 3_I4P)) cycle
      if (is_word(tokens(i)%text, 'variable var')) cycle
      block
         character(len=:), allocatable :: value !< The variable's string.
         logical                       :: found !< A string variable.

         call self%symbols%string_of(tokens(i)%text, value, found)
         if (found) then
            tokens(i)%kind = TOKEN_STRING
            tokens(i)%text = value
         endif
      endblock
   enddo
   call resolve_colors(tokens, iostat, iomsg)
   if (iostat /= 0_I4P) return
   if (tokens(1)%kind /= TOKEN_WORD) then
      call fail('a command was expected, found "'//tokens(1)%text//'"', iostat, iomsg)
      return
   endif
   command = tokens(1)%text
   ! in a multiplot, the first command after a plot opens the next panel (the multiplot options excepted)
   if (self%advance_pending .and. (keyword(command, 'set', 2_I4P) .or. keyword(command, 'unset', 3_I4P) .or. &
                                   keyword(command, 'plot', 1_I4P) .or. keyword(command, 'splot', 2_I4P) .or. &
                                   keyword(command, 'reset', 3_I4P))) then
      if (.not. is_multiplot_option(tokens)) then
         if (self%figure%layout .and. self%figure%current >= size(self%figure%panels, kind=I4P)) then
            call fail('multiplot: the layout is full', iostat, iomsg)
            return
         endif
         call self%figure%next_panel
         self%advance_pending = .false.
      endif
   endif
   if (keyword(command, 'set', 2_I4P)) then
      call self%set_command(tokens(2:), iostat, iomsg)
   elseif (keyword(command, 'unset', 3_I4P)) then
      call self%unset_command(tokens(2:), iostat, iomsg)
   elseif (keyword(command, 'plot', 1_I4P)) then
      self%last_plot = after_command(statement)
      self%last_splot = .false.
      call self%plot_command(tokens(2:), statement, iostat, iomsg)
   elseif (keyword(command, 'splot', 2_I4P)) then
      self%last_plot = after_command(statement)
      self%last_splot = .true.
      call self%plot_command(tokens(2:), statement, iostat, iomsg, three_d=.true.)
   elseif (command == 'fit') then
      call self%fit_command(tokens(2:), statement, iostat, iomsg)
   elseif (keyword(command, 'print', 2_I4P)) then
      call self%print_command(after_command(statement), iostat, iomsg)
   elseif (keyword(command, 'stats', 4_I4P)) then
      call self%stats_command(tokens(2:), iostat, iomsg)
   elseif (keyword(command, 'load', 1_I4P) .or. keyword(command, 'call', 3_I4P)) then
      call self%call_command(tokens, keyword(command, 'call', 3_I4P), iostat, iomsg)
   elseif (keyword(command, 'system', 2_I4P)) then
      ! the command runs with the standard output shared
      i = 2_I4P
      if (size(tokens) < 2) then
         call fail('system: a command string is expected', iostat, iomsg)
         return
      endif
      if (.not. self%string_expression(tokens, i, text, iostat, iomsg)) then
         iomsg = 'system: '//iomsg
         return
      endif
      if (i < size(tokens, kind=I4P)) then
         call fail('system: unexpected "'//tokens(i + 1_I4P)%text//'"', iostat, iomsg)
         return
      endif
      flush(output_unit)
      call execute_command_line(text, wait=.true.)
   elseif (keyword(command, 'reset', 3_I4P)) then
      call self%reset_command(tokens(2:), iostat, iomsg)
   elseif (keyword(command, 'pause', 2_I4P)) then
      call self%pause_command(tokens(2:), iostat, iomsg)
   elseif (command == 'reread') then
      call fail('reread is deprecated in gnuplot 6.0, not supported: loop with while (1) { plot ...; pause N }', &
                iostat, iomsg)
   elseif (command == 'array') then
      call array_command(self%symbols, after_command(statement), self%figure%panels(self%figure%current)%degrees, &
                         iostat, iomsg)
   elseif (keyword(command, 'eval', 3_I4P)) then
      ! the string, run as script lines
      i = 2_I4P
      if (size(tokens) < 2) then
         call fail('eval: a string is expected', iostat, iomsg)
         return
      endif
      if (.not. self%string_expression(tokens, i, text, iostat, iomsg)) then
         iomsg = 'eval: '//iomsg
         return
      endif
      if (i < size(tokens, kind=I4P)) then
         call fail('eval: unexpected "'//tokens(i + 1_I4P)%text//'"', iostat, iomsg)
         return
      endif
      call self%run_text(text, iostat, iomsg, source='eval')
   elseif (keyword(command, 'undefine', 3_I4P)) then
      ! variables, arrays and datablocks; NAME* every variable whose name starts with NAME; as gnuplot nothing after
      ! undefine does nothing, a word not starting as a name is "Not a variable name", a name and more (a*b) is ignored
      do i = 2_I4P, size(tokens, kind=I4P)
         text = tokens(i)%text
         if (tokens(i)%kind /= TOKEN_WORD .or. len(text) == 0) then
            call fail('undefine: not a variable name: "'//text//'"', iostat, iomsg)
            return
         endif
         if (scan(text(1:1), UNAME_START//'$') == 0) then
            call fail('undefine: not a variable name: "'//text//'"', iostat, iomsg)
            return
         endif
         if (index(text(1:len(text) - 1), '*') > 0) cycle
         ! gnuplot's own variables stay (undefine GPVAL_* does nothing to them)
         if (index(text, 'GPVAL_') == 1) cycle
         if (text(len(text):len(text)) == '*') then
            call self%symbols%remove_prefix(text(1:len(text) - 1))
         else
            call self%symbols%remove(text)
         endif
      enddo
   elseif (keyword(command, 'replot', 3_I4P)) then
      if (len(self%last_plot) == 0) then
         call fail('replot: no previous plot', iostat, iomsg)
         return
      endif
      if (size(tokens) > 1) self%last_plot = self%last_plot//', '//after_command(statement)
      call tokenize(self%last_plot, tokens, iostat, iomsg)
      if (iostat /= 0_I4P) return
      call resolve_colors(tokens, iostat, iomsg)
      if (iostat /= 0_I4P) return
      call self%plot_command(tokens, self%last_plot, iostat, iomsg, three_d=self%last_splot)
   elseif (keyword(command, 'refresh', 3_I4P)) then
      ! gnuplot redraws the last plot from its stored data: the data are read again here, the same files
      if (len(self%last_plot) == 0) then
         call fail('refresh: no previous plot', iostat, iomsg)
         return
      endif
      if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
      call tokenize(self%last_plot, tokens, iostat, iomsg)
      if (iostat /= 0_I4P) return
      call resolve_colors(tokens, iostat, iomsg)
      if (iostat /= 0_I4P) return
      call self%plot_command(tokens, self%last_plot, iostat, iomsg, three_d=self%last_splot)
   elseif (keyword(command, 'show', 2_I4P) .or. command == 'test') then
      ! gnuplot `show ...` prints settings, `test` draws a test page: nothing here, as a script runs on
      continue
   else
      call fail('unsupported command "'//command//'"', iostat, iomsg)
   endif
   endsubroutine execute

   function string_expression(self, tokens, i, text, iostat, iomsg) result(ok)
   !< The string expression starting at token `i`, as gnuplot takes one wherever a string goes: a quoted string, or
   !< an expression of strings, string variables and functions (`"run".i.".dat"`, `sprintf("p = %.2f", p)`, `name`). On
   !< return `i` is its last token. A number is an error.
   class(script_object),          intent(in)    :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Tokens.
   integer(I4P),                  intent(inout) :: i         !< First token in, last token out.
   character(len=:), allocatable, intent(out)   :: text      !< String.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   logical                                      :: ok        !< Success.
   integer(I4P)                                 :: last      !< Last token.
   logical                                      :: is_string !< A string value.

   iostat = 0_I4P
   iomsg = ''
   text = ''
   ok = .false.
   last = expression_end(tokens, i)
   if (last == i .and. tokens(i)%kind == TOKEN_STRING) then
      text = tokens(i)%text
      ok = .true.
      return
   endif
   ! a datablock name stands for its data, as a file name
   if (last == i .and. tokens(i)%kind == TOKEN_WORD) then
      if (is_datablock(tokens(i)%text) .or. self%symbols%is_array(tokens(i)%text)) then
         text = tokens(i)%text
         ok = .true.
         return
      endif
   endif
   call self%symbols%text_of(expression_source(tokens(i:last)), text, is_string, iostat, iomsg, &
                             degrees=self%figure%panels(self%figure%current)%degrees)
   if (iostat /= 0_I4P) return
   if (.not. is_string) then
      call fail('a string is expected, found the number '//text, iostat, iomsg)
      return
   endif
   i = last
   ok = .true.
   endfunction string_expression

   function font_spec(self, tokens, i, font, iostat, iomsg) result(ok)
   !< The font after the `font` word at token `i` (gnuplot `font "family:Bold:Italic,size"`, a string expression),
   !< `i` left on its last token.
   class(script_object),          intent(in)    :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Tokens.
   integer(I4P),                  intent(inout) :: i         !< The `font` word in, the spec's last token out.
   type(font_object),             intent(out)   :: font      !< Font.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   logical                                      :: ok        !< Success.
   character(len=:), allocatable                :: text      !< Spec.

   font = font_object()
   iostat = 0_I4P
   iomsg = ''
   ok = i < size(tokens, kind=I4P)
   if (.not. ok) then
      call fail('font needs a "name,size"', iostat, iomsg)
      return
   endif
   i = i + 1_I4P
   ok = self%string_expression(tokens, i, text, iostat, iomsg)
   if (.not. ok) then
      iomsg = 'font: '//iomsg
      return
   endif
   font = font_of(text)
   endfunction font_spec

   function string_argument(self, tokens, text, iostat, iomsg) result(ok)
   !< Optional string expression after an option (`set title "T"`, `set output name . ".svg"`); absent means empty.
   class(script_object),          intent(in)  :: self      !< Interpreter.
   type(token_object),            intent(in)  :: tokens(:) !< Option tokens.
   character(len=:), allocatable, intent(out) :: text      !< String.
   integer(I4P),                  intent(out) :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out) :: iomsg     !< Error message.
   logical                                    :: ok        !< Success.
   integer(I4P)                               :: i         !< Last token of the string.

   iostat = 0_I4P
   iomsg = ''
   text = ''
   ok = .true.
   if (size(tokens) < 2) return
   i = 2_I4P
   ok = self%string_expression(tokens, i, text, iostat, iomsg)
   if (.not. ok) then
      iomsg = 'set '//tokens(1)%text//': '//iomsg
      return
   endif
   if (i < size(tokens, kind=I4P)) then
      call fail('set '//tokens(1)%text//': unexpected "'//tokens(i + 1_I4P)%text//'" after the string', iostat, iomsg)
      ok = .false.
   endif
   endfunction string_argument

   function text_color(self, tokens, i, color, iostat, iomsg) result(ok)
   !< `tc|textcolor COLOR` with `tc` at token `i`, left on the color's last token: `lt N` (linetype N's color), else as
   !< a line color (`rgb "red"`, `"#rrggbb"`, a number); palette colors refused.
   class(script_object),          intent(in)    :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Statement tokens.
   integer(I4P),                  intent(inout) :: i         !< Token counter.
   character(len=*),              intent(inout) :: color     !< Color read.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   logical                                      :: ok        !< Read.
   type(token_object), allocatable              :: copy(:)   !< Tokens, `lc` for the color word.
   type(line_style_object)                      :: probe     !< Color read.

   iostat = 0_I4P
   iomsg = ''
   ! `tc lt N`: the color of linetype N
   if (i < size(tokens, kind=I4P)) then
      if (tokens(i + 1_I4P)%text == 'lt' .or. keyword(tokens(i + 1_I4P)%text, 'linetype', 5_I4P)) then
         block
            integer(I4P) :: n !< Linetype.

            i = i + 1_I4P
            ok = next_integer(tokens, i, n, iostat, iomsg, self%symbols)
            if (.not. ok) return
            color = default_color(max(n, 1_I4P), self%figure%panels(self%figure%current)%linecolors)
         endblock
         return
      endif
   endif
   copy = tokens
   copy(i)%text = 'lc'
   ok = line_option(copy, i, probe, iostat, iomsg, self%figure%panels(self%figure%current)%linecolors, self%symbols)
   if (.not. ok) return
   if (allocated(probe%lc)) then
      if (index(probe%lc, '*') == 1) then
         call fail('palette colors do not apply to text', iostat, iomsg)
         ok = .false.
         return
      endif
      color = probe%lc
   endif
   endfunction text_color

   recursive subroutine do_block(self, statement, iostat, iomsg)
   !< gnuplot `do for [i = a:b[:c]] [for [...]] { ... }` and `do for [w in "words"] { ... }`: the body run for each value,
   !< the clauses nested left to right; the loop variable is local to the loop (its value before is restored, or it is
   !< removed), bounds are truncated to integers, `break` leaves the whole `do`, `continue` its innermost clause.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   character(len=*),              intent(in)    :: statement !< The whole statement.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   type(token_object), allocatable              :: specs(:)  !< `for` clauses, brackets removed.
   character(len=:), allocatable                :: rest      !< Text still to read.
   character(len=:), allocatable                :: after     !< Text after a part read.
   character(len=:), allocatable                :: body      !< Block body.

   iostat = 0_I4P
   iomsg = ''
   rest = trim(adjustl(statement))
   rest = trim(adjustl(rest(3:)))
   call for_clauses(rest, specs, iostat, iomsg)
   if (iostat /= 0_I4P) then
      iomsg = 'do '//iomsg
      return
   endif
   if (size(specs) == 0) then
      call fail('do: for [...] expected', iostat, iomsg)
      return
   endif
   if (.not. block_body(rest, body, after)) then
      call fail('do for: { ... } expected after the clauses', iostat, iomsg)
      return
   endif
   rest = after
   if (len(rest) > 0) then
      call fail('do for: unexpected "'//rest//'" after the block', iostat, iomsg)
      return
   endif
   self%loop_depth = self%loop_depth + 1_I4P
   call self%run_loops(specs, 1_I4P, body, iostat, iomsg)
   self%loop_depth = self%loop_depth - 1_I4P
   if (self%loop_signal < 3_I4P) self%loop_signal = 0_I4P
   endsubroutine do_block

   subroutine for_clauses(rest, specs, iostat, iomsg)
   !< The leading `for [...]` clauses of `rest` (brackets removed), `rest` left after them.
   character(len=:), allocatable,   intent(inout) :: rest     !< Text, the clauses removed.
   type(token_object), allocatable, intent(out)   :: specs(:) !< Clauses.
   integer(I4P),                    intent(out)   :: iostat   !< 0 on success.
   character(len=:), allocatable,   intent(out)   :: iomsg    !< Error message.
   type(token_object)                             :: spec     !< One clause.
   integer(I4P)                                   :: close    !< Closing bracket.

   iostat = 0_I4P
   iomsg = ''
   allocate(specs(0))
   do while (leading_word(rest) == 'for')
      rest = trim(adjustl(rest(4:)))
      close = 0_I4P
      if (len(rest) > 0) then
         if (rest(1:1) == '[') close = matching(rest, 1_I4P)
      endif
      if (close == 0_I4P) then
         call fail('for: [i = a:b] or [w in "words"] expected', iostat, iomsg)
         return
      endif
      spec%text = rest(2:close - 1_I4P)
      call push(specs, spec)
      rest = trim(adjustl(rest(close + 1_I4P:)))
   enddo
   endsubroutine for_clauses

   recursive subroutine set_for(self, statement, iostat, iomsg)
   !< gnuplot `set for [i = a:b] OPTION ...` and `unset for [...] OPTION`: the command run for each value of the
   !< clauses (nested left to right), the loop variable local to it, as `do for`.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   character(len=*),              intent(in)    :: statement !< The whole statement.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   type(token_object), allocatable              :: specs(:)  !< `for` clauses, brackets removed.
   character(len=:), allocatable                :: command   !< `set` or `unset`, as written.
   character(len=:), allocatable                :: rest      !< Text after the clauses.

   rest = trim(adjustl(statement))
   command = leading_word(rest)
   rest = trim(adjustl(rest(len(command) + 1:)))
   call for_clauses(rest, specs, iostat, iomsg)
   if (iostat /= 0_I4P) then
      iomsg = command//' '//iomsg
      return
   endif
   if (len(rest) == 0) then
      call fail(command//' for: an option is expected after the clauses', iostat, iomsg)
      return
   endif
   self%loop_depth = self%loop_depth + 1_I4P
   call self%run_loops(specs, 1_I4P, command//' '//rest, iostat, iomsg)
   self%loop_depth = self%loop_depth - 1_I4P
   if (self%loop_signal < 3_I4P) self%loop_signal = 0_I4P
   endsubroutine set_for

   recursive subroutine run_loops(self, specs, level, body, iostat, iomsg)
   !< Run clause `level` of `specs`, the inner clauses (or the body) for each of its values.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: specs(:)  !< `for` clauses.
   integer(I4P),                  intent(in)    :: level     !< Clause.
   character(len=*),              intent(in)    :: body      !< Block body.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   type(saved_variable)                         :: saved     !< The loop variable before the loop.
   character(len=:), allocatable                :: name      !< Loop variable.
   type(token_object), allocatable              :: list(:)   !< Words of the `in` list.
   integer(I8P)                                 :: k         !< Word counter.
   logical                                      :: is_words  !< `w in "..."`.

   call for_values(self, specs(level)%text, name, list, is_words, iostat, iomsg)
   if (iostat /= 0_I4P) then
      iomsg = 'do for ['//specs(level)%text//']: '//iomsg
      return
   endif
   call self%symbols%save_variable(name, saved)
   do k = 1_I8P, size(list, kind=I8P)
      call set_loop_variable(self, name, list(k)%text, is_words)
      call step
      if (iostat /= 0_I4P .or. self%loop_signal == 1_I4P .or. self%loop_signal >= 3_I4P) exit
   enddo
   call self%symbols%restore(saved)
   contains
      recursive subroutine step
      !< One value: the inner clauses, or the body; a `continue` ends this value only.
      if (level < size(specs, kind=I4P)) then
         call self%run_loops(specs, level + 1_I4P, body, iostat, iomsg)
      else
         call self%run_body(body, iostat, iomsg)
      endif
      if (self%loop_signal == 2_I4P) self%loop_signal = 0_I4P
      endsubroutine step

   endsubroutine run_loops

   subroutine for_values(self, text, var, values, words, iostat, iomsg)
   !< The values of a `for` clause: `var = a:b[:c]` (integers, bounds truncated, `c` 1 by default) or `var in "w1 w2"`
   !< (the words of a string expression, `words` true).
   class(script_object),            intent(in)  :: self      !< Interpreter.
   character(len=*),                intent(in)  :: text      !< Clause, brackets removed.
   character(len=:), allocatable,   intent(out) :: var       !< Loop variable.
   type(token_object), allocatable, intent(out) :: values(:) !< Values, as text.
   logical,                         intent(out) :: words     !< `in` form: the values are strings.
   integer(I4P),                    intent(out) :: iostat    !< 0 on success.
   character(len=:), allocatable,   intent(out) :: iomsg     !< Error message.
   character(len=:), allocatable :: parts(:)  !< Range ends.
   character(len=:), allocatable :: list      !< `in` words.
   type(token_object)            :: item      !< One value.
   logical                       :: is_string !< A string.
   integer(I8P)                  :: range(3)  !< First, last, step.
   integer(I8P)                  :: v         !< Value.
   integer(I4P)                  :: e         !< `=` or ` in `.
   integer(I4P)                  :: j         !< Counter.
   real(R8P)                     :: x         !< Bound.

   iostat = 0_I4P
   iomsg = ''
   allocate(values(0))
   words = .false.
   e = index(text, ' in ', kind=I4P)
   if (e > 0_I4P .and. (index(text, '=') == 0 .or. index(text, '=') > e)) then
      words = .true.
      var = trim(adjustl(text(1:e - 1_I4P)))
      call self%symbols%text_of(trim(adjustl(text(e + 4_I4P:))), list, is_string, iostat, iomsg, &
                                degrees=self%figure%panels(self%figure%current)%degrees)
      if (iostat /= 0_I4P) return
      if (.not. is_string) then
         call fail('a string of words is expected after in', iostat, iomsg)
         return
      endif
      call split_words(list, values)
   else
      e = index(text, '=', kind=I4P)
      if (e == 0_I4P) then
         call fail('i = a:b[:c] or w in "words" expected', iostat, iomsg)
         return
      endif
      var = trim(adjustl(text(1:e - 1_I4P)))
      call split_range(text(e + 1_I4P:), parts)
      if (size(parts) < 2 .or. size(parts) > 3) then
         call fail('i = a:b[:c] expected', iostat, iomsg)
         return
      endif
      range = [1_I8P, 0_I8P, 1_I8P]
      do j = 1_I4P, size(parts, kind=I4P)
         if (trim(adjustl(parts(j))) == '*') then
            call fail('unbounded iteration is not accepted', iostat, iomsg)
            return
         endif
         call self%symbols%constant(trim(parts(j)), x, iostat, iomsg, &
                                    degrees=self%figure%panels(self%figure%current)%degrees)
         if (iostat /= 0_I4P) return
         if (abs(x) >= 9.0e18_R8P) then
            call fail('bound out of range', iostat, iomsg)
            return
         endif
         range(j) = int(x, I8P)
      enddo
      if (range(3) == 0_I8P) then
         call fail('the step must not be 0', iostat, iomsg)
         return
      endif
      v = range(1)
      do while ((range(3) > 0_I8P .and. v <= range(2)) .or. (range(3) < 0_I8P .and. v >= range(2)))
         item%text = int_str(v)
         call push(values, item)
         v = v + range(3)
      enddo
   endif
   if (len(var) == 0 .or. verify(var, UNAME_CHARS) > 0) then
      call fail('invalid loop variable "'//var//'"', iostat, iomsg)
   endif
   endsubroutine for_values

   subroutine set_loop_variable(self, name, value, is_string)
   !< Set the loop variable `name` to `value`: a string (a word) or an integer in decimal.
   class(script_object), intent(inout) :: self      !< Interpreter.
   character(len=*),     intent(in)    :: name      !< Variable.
   character(len=*),     intent(in)    :: value     !< Value.
   logical,              intent(in)    :: is_string !< A string.
   integer(I8P)                        :: v         !< Integer value.

   if (is_string) then
      call self%symbols%set_string(name, value)
   else
      read(value, *) v
      call self%symbols%set_value(name, real(v, R8P), .true.)
   endif
   endsubroutine set_loop_variable

   recursive subroutine while_block(self, statement, iostat, iomsg)
   !< gnuplot `while (condition) { ... }`: the body run while the condition (a number, not 0) holds.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   character(len=*),              intent(in)    :: statement !< The whole statement.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   character(len=:), allocatable                :: rest      !< Text still to read.
   character(len=:), allocatable                :: after     !< Text after a part read.
   character(len=:), allocatable                :: condition !< Condition.
   character(len=:), allocatable                :: body      !< Block body.
   logical                                      :: holds     !< Condition true.

   iostat = 0_I4P
   iomsg = ''
   rest = trim(adjustl(statement))
   rest = trim(adjustl(rest(6:)))
   if (.not. parenthesized(rest, condition, after)) then
      call fail('while: (condition) expected', iostat, iomsg)
      return
   endif
   rest = after
   if (.not. block_body(rest, body, after)) then
      call fail('while: { ... } expected after the condition', iostat, iomsg)
      return
   endif
   rest = after
   if (len(rest) > 0) then
      call fail('while: unexpected "'//rest//'" after the block', iostat, iomsg)
      return
   endif
   self%loop_depth = self%loop_depth + 1_I4P
   do
      call truth_of(self, condition, holds, iostat, iomsg)
      if (iostat /= 0_I4P) then
         iomsg = 'while: '//iomsg
         exit
      endif
      if (.not. holds) exit
      call self%run_body(body, iostat, iomsg)
      if (iostat /= 0_I4P .or. self%loop_signal == 1_I4P .or. self%loop_signal >= 3_I4P) exit
      self%loop_signal = 0_I4P
   enddo
   self%loop_depth = self%loop_depth - 1_I4P
   if (self%loop_signal < 3_I4P) self%loop_signal = 0_I4P
   endsubroutine while_block

   recursive subroutine if_block(self, statement, iostat, iomsg)
   !< gnuplot `if (condition) { ... } [else if (condition) { ... }]... [else { ... }]`: the first block whose condition
   !< holds is run. gnuplot's old one-line form, `if (condition) command`, is `old_if_line`'s.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   character(len=*),              intent(in)    :: statement !< The whole statement.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   character(len=:), allocatable                :: rest      !< Text still to read.
   character(len=:), allocatable                :: after     !< Text after a part read.
   character(len=:), allocatable                :: condition !< Condition.
   character(len=:), allocatable                :: body      !< Block body.
   logical                                      :: holds     !< Condition true.
   logical                                      :: done      !< A block was run.

   iostat = 0_I4P
   iomsg = ''
   done = .false.
   rest = trim(adjustl(statement))
   rest = trim(adjustl(rest(3:)))
   do
      if (.not. parenthesized(rest, condition, after)) then
         call fail('if: (condition) expected', iostat, iomsg)
         return
      endif
      rest = after
      if (.not. block_body(rest, body, after)) then
         call fail('if: { ... } or a command expected after the condition', iostat, iomsg)
         return
      endif
      rest = after
      if (.not. done) then
         call truth_of(self, condition, holds, iostat, iomsg)
         if (iostat /= 0_I4P) then
            iomsg = 'if: '//iomsg
            return
         endif
         if (holds) then
            call self%run_body(body, iostat, iomsg)
            if (iostat /= 0_I4P) return
            done = .true.
         endif
      endif
      if (len(rest) == 0) return
      if (leading_word(rest) /= 'else') then
         call fail('if: unexpected "'//rest//'" after the block', iostat, iomsg)
         return
      endif
      rest = trim(adjustl(rest(5:)))
      if (leading_word(rest) == 'if') then
         rest = trim(adjustl(rest(3:)))
         cycle
      endif
      if (.not. block_body(rest, body, after)) then
         call fail('else: { ... } expected', iostat, iomsg)
         return
      endif
      rest = after
      if (len(rest) > 0) then
         call fail('else: unexpected "'//rest//'" after the block', iostat, iomsg)
         return
      endif
      if (.not. done) call self%run_body(body, iostat, iomsg)
      return
   enddo
   endsubroutine if_block

   recursive subroutine run_body(self, body, iostat, iomsg)
   !< Run the statements of a block body, stopping at a `break` or a `continue`.
   class(script_object),          intent(inout) :: self          !< Interpreter.
   character(len=*),              intent(in)    :: body          !< Body.
   integer(I4P),                  intent(out)   :: iostat        !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg         !< Error message.
   type(token_object), allocatable              :: statements(:) !< Statements.
   integer(I4P)                                 :: s             !< Statement counter.

   iostat = 0_I4P
   iomsg = ''
   call split_statements(body, statements)
   do s = 1_I4P, size(statements, kind=I4P)
      if (old_if(statements(s)%text)) then
         ! as gnuplot 6.0: the old one-line form only outside blocks
         call fail('Old-style if/else statement encountered inside brackets', iostat, iomsg)
         return
      endif
      call self%execute(statements(s)%text, iostat, iomsg)
      if (iostat /= 0_I4P .or. self%loop_signal /= 0_I4P) return
   enddo
   endsubroutine run_body

   recursive subroutine old_if_line(self, statements, iostat, iomsg)
   !< gnuplot's old one-line `if (condition) command; ...; [else command; ...]`: `statements` the if and the rest of its
   !< line; when the condition holds the commands up to an `else` run, else those after it (`else if` chains), as
   !< gnuplot 6.0 still runs it.
   class(script_object),          intent(inout) :: self          !< Interpreter.
   type(token_object),            intent(in)    :: statements(:) !< The if and the statements after it on its line.
   integer(I4P),                  intent(out)   :: iostat        !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg         !< Error message.
   type(token_object), allocatable              :: list(:)       !< The commands after the condition.
   character(len=:), allocatable                :: rest          !< Text after `if`.
   character(len=:), allocatable                :: condition     !< Condition.
   character(len=:), allocatable                :: after         !< First command.
   logical                                      :: holds         !< Condition true.
   integer(I4P)                                 :: e             !< The `else` statement, 0 if none.
   integer(I4P)                                 :: k             !< Counter.

   iostat = 0_I4P
   iomsg = ''
   rest = trim(adjustl(statements(1)%text))
   rest = trim(adjustl(rest(3:)))
   if (.not. parenthesized(rest, condition, after)) then
      call fail('if: (condition) expected', iostat, iomsg)
      return
   endif
   list = statements
   list(1)%text = trim(adjustl(after))
   e = 0_I4P
   do k = 2_I4P, size(list, kind=I4P)
      if (leading_word(list(k)%text) == 'else') then
         e = k
         exit
      endif
   enddo
   call truth_of(self, condition, holds, iostat, iomsg)
   if (iostat /= 0_I4P) then
      iomsg = 'if: '//iomsg
      return
   endif
   if (holds) then
      if (e == 0_I4P) e = size(list, kind=I4P) + 1_I4P
      call self%run_list(list(1:e - 1_I4P), iostat, iomsg)
   elseif (e > 0_I4P) then
      list(e)%text = trim(adjustl(list(e)%text(5:)))
      call self%run_list(list(e:), iostat, iomsg)
   endif
   endsubroutine old_if_line

   recursive subroutine run_list(self, statements, iostat, iomsg)
   !< Run `statements` in order (an old one-line if among them takes the rest), stopping at an error or a signal.
   class(script_object),          intent(inout) :: self          !< Interpreter.
   type(token_object),            intent(in)    :: statements(:) !< Statements.
   integer(I4P),                  intent(out)   :: iostat        !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg         !< Error message.
   integer(I4P)                                 :: s             !< Statement counter.

   iostat = 0_I4P
   iomsg = ''
   do s = 1_I4P, size(statements, kind=I4P)
      if (len_trim(statements(s)%text) == 0) cycle
      if (old_if(statements(s)%text)) then
         call self%old_if_line(statements(s:), iostat, iomsg)
         return
      endif
      call self%execute(statements(s)%text, iostat, iomsg)
      if (iostat /= 0_I4P .or. self%loop_signal /= 0_I4P) return
   enddo
   endsubroutine run_list

   subroutine truth_of(self, condition, holds, iostat, iomsg)
   !< Whether the constant expression `condition` holds (a number other than 0; a string is an error).
   class(script_object),          intent(in)  :: self      !< Interpreter.
   character(len=*),              intent(in)  :: condition !< Condition.
   logical,                       intent(out) :: holds     !< True.
   integer(I4P),                  intent(out) :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out) :: iomsg     !< Error message.
   character(len=:), allocatable              :: text      !< Value.
   logical                                    :: is_string !< A string.
   real(R8P)                                  :: v         !< Value.

   holds = .false.
   call self%symbols%text_of(condition, text, is_string, iostat, iomsg, &
                             degrees=self%figure%panels(self%figure%current)%degrees)
   if (iostat /= 0_I4P) return
   if (is_string) then
      call fail('a string used as a condition: '//condition, iostat, iomsg)
      return
   endif
   call self%symbols%constant(condition, v, iostat, iomsg, degrees=self%figure%panels(self%figure%current)%degrees)
   holds = v /= 0.0_R8P
   endsubroutine truth_of

   subroutine stats_command(self, tokens, iostat, iomsg)
   !< gnuplot `stats [[xmin:xmax] [[ymin:ymax]]] FILE [using N[:M]] [index N] [every ...] [name "P"] [output|nooutput]`:
   !< foresight_stats on the column (or the pair) as STATS_* variables (P_* with a name); the records with an undefined
   !< used value are invalid, those outside the ranges out of range. Silent unless `output`, unlike gnuplot: the report
   !< then goes where `print` writes (gnuplot's screen layout on the standard error or output, its name-tab-value lines
   !< in a `set print` file).
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Tokens after `stats`.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   character(len=*), parameter :: BASES(52) = [character(len=13) :: 'records', 'invalid', 'headers', 'blank', 'blocks', &
      'outofrange', 'columns', 'mean', 'stddev', 'ssd', 'skewness', 'kurtosis', 'adev', 'mean_err', 'stddev_err', &
      'skewness_err', 'kurtosis_err', 'sum', 'sumsq', 'min', 'max', 'median', 'lo_quartile', 'up_quartile', 'index_min', &
      'index_max', 'slope', 'intercept', 'slope_err', 'intercept_err', 'correlation', 'sumxy', 'pos_min_y', 'pos_max_y', &
      'mean_x', 'mean_y', 'stddev_x', 'stddev_y', 'ssd_x', 'ssd_y', 'min_x', 'min_y', 'max_x', 'max_y', 'sum_x', 'sum_y', &
      'sumsq_x', 'sumsq_y', 'median_x', 'median_y', 'index_min_x', 'index_min_y'] !< Variables cleared first (gnuplot's).
   type(datafile_object)                        :: data      !< Data file.
   type(expression_object), allocatable         :: fields(:) !< `using` fields.
   type(stats_result)                           :: r         !< Statistics.
   type(expression_object)                      :: point     !< The point number field.
   character(len=:), allocatable                :: file      !< Data file name.
   character(len=:), allocatable                :: spec      !< `using` as written.
   character(len=:), allocatable                :: word      !< Current word.
   character(len=:), allocatable                :: prefix    !< Variable prefix.
   real(R8P), allocatable                       :: values(:,:) !< `using` values.
   real(R8P), allocatable                       :: x(:)      !< First column kept.
   real(R8P), allocatable                       :: y(:)      !< Column (or second) kept.
   logical, allocatable                         :: keep(:)   !< Records kept.
   real(R8P)                                    :: ranges(2, 2) !< x and y ranges.
   logical                                      :: limited(2, 2) !< Range ends given.
   logical                                      :: output    !< Report requested.
   logical                                      :: found     !< The file exists.
   logical                                      :: two       !< Two columns.
   logical                                      :: texts     !< The cell texts are read (`strcol`).
   logical                                      :: is_matrix !< `matrix`: the values of a matrix.
   integer(I4P)                                 :: msize(2)  !< Columns and rows of the (sub)matrix.
   integer(I4P)                                 :: nranges   !< Ranges given.
   integer(I4P)                                 :: set_index !< Dataset, -1 for all.
   integer(I4P)                                 :: every(6)  !< `every` fields.
   integer(I4P)                                 :: skip      !< First lines of the file not read (`skip N`).
   integer(I4P)                                 :: i         !< Token counter.
   integer(I4P)                                 :: k         !< Counter.
   integer(I4P)                                 :: unit      !< Report unit.

   iostat = 0_I4P
   iomsg = ''
   ranges = 0.0_R8P
   limited = .false.
   nranges = 0_I4P
   i = 1_I4P
   do while (i <= size(tokens, kind=I4P))
      if (tokens(i)%kind /= TOKEN_RANGE) exit
      nranges = nranges + 1_I4P
      if (nranges > 2_I4P) then
         call fail('stats: at most two ranges, [x] and [y]', iostat, iomsg)
         return
      endif
      call stats_range(tokens(i)%text, nranges)
      if (iostat /= 0_I4P) return
      i = i + 1_I4P
   enddo
   if (i > size(tokens, kind=I4P)) then
      call fail('stats: a data file is expected', iostat, iomsg)
      return
   endif
   if (.not. self%string_expression(tokens, i, file, iostat, iomsg)) then
      iomsg = 'stats: '//iomsg
      return
   endif
   if (len(file) == 0) file = self%previous_file
   spec = ''
   set_index = -1_I4P
   every = [1_I4P, 1_I4P, 0_I4P, 0_I4P, -1_I4P, -1_I4P]
   skip = 0_I4P
   is_matrix = .false.
   msize = 0_I4P
   prefix = 'STATS_'
   output = .false.
   i = i + 1_I4P
   do while (i <= size(tokens, kind=I4P))
      word = tokens(i)%text
      if (keyword(word, 'using', 1_I4P)) then
         if (.not. next_word(tokens, i, spec, iostat, iomsg)) return
         call parse_using(spec, fields, iostat, iomsg, self%figure%panels(self%figure%current)%degrees, self%symbols)
         if (iostat /= 0_I4P) return
      elseif (keyword(word, 'index', 1_I4P)) then
         if (.not. next_integer(tokens, i, set_index, iostat, iomsg, self%symbols)) return
      elseif (keyword(word, 'every', 2_I4P)) then
         if (.not. next_word(tokens, i, word, iostat, iomsg)) return
         call parse_every(word, every, iostat, iomsg, self%symbols)
         if (iostat /= 0_I4P) return
      elseif (word == 'skip') then
         ! gnuplot's `skip N`: the first N lines of the file not read
         if (.not. next_integer(tokens, i, skip, iostat, iomsg, self%symbols)) return
      elseif (keyword(word, 'matrix', 3_I4P)) then
         ! the values of a matrix (every: columns, rows), as one column
         is_matrix = .true.
      elseif (word == 'name' .or. keyword(word, 'prefix', 3_I4P)) then
         i = i + 1_I4P
         if (i > size(tokens, kind=I4P)) then
            call fail('stats: name "prefix" expected', iostat, iomsg)
            return
         endif
         if (.not. self%string_expression(tokens, i, prefix, iostat, iomsg)) then
            iomsg = 'stats: name: '//iomsg
            return
         endif
         if (len(prefix) == 0 .or. scan(prefix(1:1), '0123456789') > 0 .or. &
             verify(prefix, UNAME_CHARS) > 0) then
            call fail('stats: illegal prefix "'//prefix//'"', iostat, iomsg)
            return
         endif
         if (prefix(len(prefix):len(prefix)) /= '_') prefix = prefix//'_'
      elseif (keyword(word, 'output', 3_I4P)) then
         output = .true.
      elseif (keyword(word, 'nooutput', 5_I4P)) then
         output = .false.
      else
         call fail('stats: unsupported option "'//word//'" (using, index, every, name, output, nooutput)', iostat, iomsg)
         return
      endif
      i = i + 1_I4P
   enddo
   ! a missing file is not an error, as gnuplot's (a script may test for it): the variables are left as they are
   found = is_datablock(file) .or. self%symbols%is_array(file)
   if (.not. found) inquire(file=file, exist=found)
   if (.not. found) then
      if (output) write(error_unit, '(A)') 'Cannot find or open file "'//file//'"'
      return
   endif
   texts = .false.
   if (allocated(fields)) texts = any(fields%uses_text())
   call self%load_data(data, file, iostat, iomsg, keep_text=texts, skip=skip)
   if (iostat /= 0_I4P) then
      iomsg = 'stats: '//iomsg
      return
   endif
   self%previous_file = file
   if (is_matrix .and. allocated(fields)) then
      call fail('stats: a matrix takes no using', iostat, iomsg)
      return
   endif
   if (is_matrix) fields = plain_columns([1_I4P])
   if (.not. allocated(fields) .and. self%symbols%is_array(file)) then
      ! an array: its values, as gnuplot's
      call parse_using('2', fields, iostat, iomsg, self%figure%panels(self%figure%current)%degrees, self%symbols)
      if (iostat /= 0_I4P) return
   endif
   if (.not. allocated(fields)) then
      ! gnuplot: the first two columns if the first data line has both, else the first
      if (data%nrows > 0_I4P) then
         if (data%first(2) - data%first(1) >= 2_I4P) then
            fields = plain_columns([1_I4P, 2_I4P])
         else
            fields = plain_columns([1_I4P])
         endif
      else
         fields = plain_columns([1_I4P])
      endif
   endif
   if (size(fields) > 2) then
      call fail('stats: using N or N:M (one or two columns)', iostat, iomsg)
      return
   endif
   two = size(fields) == 2
   ! the point number as a last field: NaN only on the rows the table inserts at block breaks, not records
   call point%set_column(0_I4P)
   call push(fields, point)
   if (is_matrix) then
      ! the values of the (sub)matrix row by row, as one column (the point number a last, finite, column)
      block
         real(R8P), allocatable        :: z(:,:)   !< Matrix.
         real(R8P), allocatable        :: sub(:,:) !< Submatrix.
         real(R8P), allocatable        :: cx(:)    !< Its column indices.
         real(R8P), allocatable        :: ry(:)    !< Its row indices.
         character(len=:), allocatable :: problem  !< Matrix problem.

         call data%matrix(set_index, z, problem)
         if (len(problem) > 0) then
            call fail('stats: '//problem//' in "'//file//'"', iostat, iomsg)
            return
         endif
         call matrix_every(z, every, sub, cx, ry)
         msize = [size(sub, 1, kind=I4P), size(sub, 2, kind=I4P)]
         allocate(values(size(sub), 2))
         values(:, 1) = reshape(sub, [size(sub)])
         values(:, 2) = 0.0_R8P
      endblock
   else
      call data%table(fields, set_index, every, values, header=any(fields%name_count() > 0_I4P) .or. &
                      self%column_headers)
   endif
   ! the variables of an earlier stats with this prefix are forgotten first, as gnuplot
   do k = 1_I4P, size(BASES, kind=I4P)
      call self%symbols%remove(prefix//trim(BASES(k)))
   enddo
   do k = 1_I4P, size(BASES, kind=I4P)
      call self%symbols%remove(prefix//trim(BASES(k))//'_x')
      call self%symbols%remove(prefix//trim(BASES(k))//'_y')
   enddo
   allocate(keep(size(values, 1)))
   r%invalid = 0_I4P
   r%outofrange = 0_I4P
   do k = 1_I4P, size(values, 1, kind=I4P)
      keep(k) = .false.
      if (.not. ieee_is_finite(values(k, size(values, 2)))) cycle
      keep(k) = all(ieee_is_finite(values(k, 1:size(values, 2) - 1)))
      if (.not. keep(k)) then
         r%invalid = r%invalid + 1_I4P
         cycle
      endif
      if (two) then
         keep(k) = inside(values(k, 1), 1_I4P) .and. inside(values(k, 2), 2_I4P)
      else
         keep(k) = inside(values(k, 1), 2_I4P)
      endif
      if (.not. keep(k)) r%outofrange = r%outofrange + 1_I4P
   enddo
   if (count(keep) == 0) then
      ! gnuplot: a warning, no variables
      return
   endif
   if (two) then
      x = pack(values(:, 1), keep)
      y = pack(values(:, 2), keep)
      block
         type(stats_result) :: pair !< Pair statistics.

         pair = stats(x, y)
         call copy_counts(pair)
      endblock
   else
      y = pack(values(:, 1), keep)
      block
         type(stats_result) :: single !< Column statistics.

         single = stats(y)
         call copy_counts(single)
      endblock
   endif
   call file_counts
   call set_int('records', r%records)
   call set_int('invalid', r%invalid)
   call set_int('headers', r%headers)
   call set_int('blank', r%blank)
   call set_int('blocks', r%blocks)
   call set_int('outofrange', r%outofrange)
   call set_int('columns', r%columns)
   if (two) then
      call set_column(r%x, '_x')
      call set_column(r%y, '_y')
      call set_real('slope', r%slope)
      call set_real('intercept', r%intercept)
      call set_real('slope_err', r%slope_err)
      call set_real('intercept_err', r%intercept_err)
      call set_real('correlation', r%correlation)
      call set_real('sumxy', r%sumxy)
      call set_real('pos_min_y', r%pos_min_y)
      call set_real('pos_max_y', r%pos_max_y)
   else
      call set_column(r%y, '')
   endif
   if (is_matrix) then
      ! gnuplot's matrix variables: its size, the place (from 0, in the submatrix) of the extremes, a record per value
      call set_int('records', count(keep))
      call set_int('columns', msize(1))
      call set_int('size_x', msize(1))
      call set_int('size_y', msize(2))
      block
         integer(I4P) :: at(2) !< First extreme, row by row.

         at = first_at(minval(values(:, 1), mask=keep))
         call set_int('index_min_x', at(1))
         call set_int('index_min_y', at(2))
         at = first_at(maxval(values(:, 1), mask=keep))
         call set_int('index_max_x', at(1))
         call set_int('index_max_y', at(2))
      endblock
   endif
   if (.not. output) return
   select case (self%print_file)
   case ('')
      call stats_report(r, int(error_unit, I4P), .true.)
   case ('-')
      call stats_report(r, int(output_unit, I4P), .true.)
   case default
      open(newunit=unit, file=self%print_file, position='append', action='write', iostat=iostat)
      if (iostat /= 0_I4P) then
         call fail('stats: cannot write "'//self%print_file//'"', iostat, iomsg)
         return
      endif
      call stats_report(r, unit, .false.)
      close(unit)
   endselect
   contains
      function first_at(v) result(at)
      !< Column and row (from 0) of the first value `v` of the submatrix read row by row.
      real(R8P), intent(in) :: v     !< Value.
      integer(I4P)          :: at(2) !< Column, row.
      integer(I4P)          :: k     !< Value counter.

      at = 0_I4P
      do k = 1_I4P, size(values, 1, kind=I4P)
         if (.not. keep(k)) cycle
         if (values(k, 1) == v) then
            at = [mod(k - 1_I4P, max(1_I4P, msize(1))), (k - 1_I4P) / max(1_I4P, msize(1))]
            return
         endif
      enddo
      endfunction first_at

      subroutine stats_range(text, n)
      !< Range `n` (1 x, 2 y) of the text `min:max`, either end empty or `*` for none.
      character(len=*), intent(in) :: text  !< Range text.
      integer(I4P),     intent(in) :: n     !< Axis.
      integer(I4P)                 :: colon !< Separator.
      integer(I4P)                 :: e     !< End.
      character(len=:), allocatable :: part !< One end.

      colon = index(text, ':', kind=I4P)
      if (colon == 0_I4P) then
         call fail('stats: a range is [min:max]', iostat, iomsg)
         return
      endif
      do e = 1_I4P, 2_I4P
         if (e == 1_I4P) then
            part = trim(adjustl(text(1:colon - 1_I4P)))
         else
            part = trim(adjustl(text(colon + 1_I4P:)))
         endif
         if (len(part) == 0 .or. part == '*') cycle
         call self%symbols%constant(part, ranges(e, n), iostat, iomsg, &
                                    degrees=self%figure%panels(self%figure%current)%degrees)
         if (iostat /= 0_I4P) then
            iomsg = 'stats: range: '//iomsg
            return
         endif
         limited(e, n) = .true.
      enddo
      endsubroutine stats_range

      function inside(v, n) result(yes)
      !< Whether `v` lies in range `n`, as gnuplot's validate_data (each end only if given).
      real(R8P),    intent(in) :: v   !< Value.
      integer(I4P), intent(in) :: n   !< Axis.
      logical                  :: yes !< Inside.

      yes = .true.
      if (limited(1, n)) yes = v >= ranges(1, n)
      if (limited(2, n) .and. yes) yes = v <= ranges(2, n)
      endfunction inside

      subroutine copy_counts(computed)
      !< `r` from the computed statistics, the counts found here kept.
      type(stats_result), intent(in) :: computed !< Statistics of the kept records.
      integer(I4P)                   :: counts(2) !< Invalid and out of range.

      counts = [r%invalid, r%outofrange]
      r = computed
      r%invalid = counts(1)
      r%outofrange = counts(2)
      endsubroutine copy_counts

      subroutine file_counts
      !< Blank lines and blocks of the file or datablock (a block ends at two blank lines), header records, columns:
      !< gnuplot's.
      character(len=:), allocatable :: text    !< File or datablock content, lines ended by new lines.
      character(len=:), allocatable :: one     !< One line.
      character(len=256)            :: line    !< One line read.
      integer(I4P)                  :: u       !< Unit.
      integer(I4P)                  :: ios     !< Status.
      integer(I4P)                  :: run     !< Consecutive blank lines.
      integer(I4P)                  :: doubles !< Second blank lines.
      integer(I4P)                  :: cut     !< End of a line.
      logical                       :: found   !< Datablock defined.

      r%blank = 0_I4P
      doubles = 0_I4P
      run = 0_I4P
      text = ''
      if (is_datablock(file)) then
         call self%symbols%string_of(file, text, found)
         if (.not. found) text = ''
      elseif (.not. self%symbols%is_array(file)) then
         ! status old: an open for reading must not create the file (nvfortran creates it otherwise)
         open(newunit=u, file=file, status='old', action='read', iostat=ios)
         if (ios == 0_I4P) then
            do
               read(u, '(A)', iostat=ios) line
               if (ios /= 0_I4P) exit
               text = text//trim(line)//new_line('a')
            enddo
            close(u)
         endif
      endif
      do while (len(text) > 0)
         cut = index(text, new_line('a'), kind=I4P)
         if (cut == 0_I4P) cut = len(text, kind=I4P) + 1_I4P
         one = text(1:cut - 1_I4P)
         text = text(min(cut + 1_I4P, len(text, kind=I4P) + 1_I4P):)
         if (len_trim(adjustl(one)) == 0 .or. one == achar(13)) then
            r%blank = r%blank + 1_I4P
            run = run + 1_I4P
            if (run == 2_I4P) doubles = doubles + 1_I4P
         else
            run = 0_I4P
         endif
      enddo
      r%blocks = doubles + 1_I4P
      r%headers = merge(1_I4P, 0_I4P, any(fields%name_count() > 0_I4P))
      r%columns = 0_I4P
      if (data%nrows > 0_I4P) r%columns = data%first(2) - data%first(1)
      endsubroutine file_counts

      subroutine set_int(base, v)
      !< Set the integer variable prefix//base.
      character(len=*), intent(in) :: base !< Name after the prefix.
      integer(I4P),     intent(in) :: v    !< Value.

      call self%symbols%set_value(prefix//base, real(v, R8P), .true.)
      endsubroutine set_int

      subroutine set_real(base, v)
      !< Set the real variable prefix//base.
      character(len=*), intent(in) :: base !< Name after the prefix.
      real(R8P),        intent(in) :: v    !< Value.

      call self%symbols%set_value(prefix//base, v, .false.)
      endsubroutine set_real

      subroutine set_column(s, suffix)
      !< The variables of one column, gnuplot's names with `suffix` (`_x`, `_y` or none).
      type(stats_column), intent(in) :: s      !< Column statistics.
      character(len=*),   intent(in) :: suffix !< Suffix.

      call set_real('mean'//suffix, s%mean)
      call set_real('stddev'//suffix, s%stddev)
      call set_real('ssd'//suffix, s%ssd)
      call set_real('skewness'//suffix, s%skewness)
      call set_real('kurtosis'//suffix, s%kurtosis)
      call set_real('adev'//suffix, s%adev)
      call set_real('mean_err'//suffix, s%mean_err)
      call set_real('stddev_err'//suffix, s%stddev_err)
      call set_real('skewness_err'//suffix, s%skewness_err)
      call set_real('kurtosis_err'//suffix, s%kurtosis_err)
      call set_real('sum'//suffix, s%sum)
      call set_real('sumsq'//suffix, s%sumsq)
      call set_real('min'//suffix, s%min)
      call set_real('max'//suffix, s%max)
      call set_real('median'//suffix, s%median)
      call set_real('lo_quartile'//suffix, s%lo_quartile)
      call set_real('up_quartile'//suffix, s%up_quartile)
      call set_int('index_min'//suffix, s%index_min)
      call set_int('index_max'//suffix, s%index_max)
      endsubroutine set_column
   endsubroutine stats_command

   subroutine print_command(self, text, iostat, iomsg)
   !< gnuplot `print EXPRESSION, ...`: the values (strings as they are, numbers as gnuplot shows them) separated by a
   !< blank, on one line of the standard error, or where `set print` sends it.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   character(len=*),              intent(in)    :: text      !< Text after `print`.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   type(token_object), allocatable              :: parts(:)  !< Expressions.
   character(len=:), allocatable                :: line      !< Printed line.
   character(len=:), allocatable                :: value     !< One value.
   integer(I4P)                                 :: k         !< Counter.
   integer(I4P)                                 :: unit      !< Output unit.
   logical                                      :: is_string !< A string value.
   type(value_list)                             :: elements  !< An array's elements.
   logical                                      :: listed    !< An array or a slice.

   iostat = 0_I4P
   iomsg = ''
   line = ''
   ! a datablock: its lines, then an empty one, as gnuplot
   if (is_datablock(trim(adjustl(text)))) then
      block
         logical :: found !< Datablock found.

         call self%symbols%string_of(trim(adjustl(text)), line, found)
         if (.not. found) then
            call fail('print: no datablock '//trim(adjustl(text)), iostat, iomsg)
            return
         endif
         ! a function block: its head, then its lines, as gnuplot
         if (self%symbols%is_block(trim(adjustl(text)))) line = 'function '//trim(adjustl(text))//'( )'//new_line('a')//line
      endblock
      if (len(line) > 0) then
         if (line(len(line):len(line)) == new_line('a')) line = line(1:len(line) - 1)
      endif
      line = line//new_line('a')
   else
   call split_arguments(text, parts)
   if (size(parts) == 0) then
      call fail('print: an expression is expected', iostat, iomsg)
      return
   endif
   do k = 1_I4P, size(parts, kind=I4P)
      if (len_trim(parts(k)%text) == 0) then
         call fail('print: an expression is expected', iostat, iomsg)
         return
      endif
      ! an array or a slice of one prints as gnuplot's [1,2,"x"]
      call self%symbols%array_value(parts(k)%text, elements, listed, iostat, iomsg, &
                                    degrees=self%figure%panels(self%figure%current)%degrees)
      if (iostat == 0_I4P .and. listed) then
         value = list_text(elements)
      elseif (iostat == 0_I4P) then
         call self%symbols%text_of(parts(k)%text, value, is_string, iostat, iomsg, &
                                   degrees=self%figure%panels(self%figure%current)%degrees)
      endif
      if (iostat /= 0_I4P) then
         iomsg = 'print: '//iomsg
         return
      endif
      if (k > 1_I4P) line = line//' '
      line = line//value
   enddo
   endif
   select case (self%print_file)
   case ('')
      write(error_unit, '(A)') line
   case ('-')
      write(output_unit, '(A)') line
   case default
      if (is_datablock(self%print_file)) then
         ! a line of the datablock (undefined since set print: a new one)
         block
            character(len=:), allocatable :: text  !< Datablock lines.
            logical                       :: found !< Datablock defined.

            call self%symbols%string_of(self%print_file, text, found)
            if (.not. found) text = ''
            call self%symbols%set_string(self%print_file, text//line//new_line('a'))
         endblock
         return
      endif
      open(newunit=unit, file=self%print_file, position='append', action='write', iostat=iostat)
      if (iostat /= 0_I4P) then
         call fail('print: cannot write "'//self%print_file//'"', iostat, iomsg)
         return
      endif
      write(unit, '(A)') line
      close(unit)
   endselect
   endsubroutine print_command

   subroutine fit_command(self, tokens, statement, iostat, iomsg)
   !< gnuplot `fit [[min:max]] EXPRESSION 'file' [using X:Y[:ERR]] [index N] [every ...] [yerrors|unitweights]
   !< via P1, P2, ...`: the parameters (user variables; an undefined one starts at 1) fitted by foresight_fit, then
   !< set to the result, with `P_err` (`set fit errorvariables`) and FIT_NDF, FIT_WSSR, FIT_STDFIT, FIT_P, FIT_NITER,
   !< FIT_CONVERGED. The report goes to the standard error with `set fit results|brief`, to a file with `set fit
   !< logfile`; silent by default. On failure the parameters keep their values.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Tokens after `fit`.
   character(len=*),              intent(in)    :: statement !< The whole statement.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   type(datafile_object)                        :: data      !< Data file.
   type(expression_object), allocatable         :: fields(:) !< `using` fields.
   type(expression_object)                      :: model     !< Compiled model.
   type(fit_result)                             :: result    !< Fit outcome.
   type(fit_settings)                           :: options   !< Fit options.
   type(script_model)                           :: fitted    !< Model fitted.
   character(len=:), allocatable                :: text      !< Model expression.
   character(len=:), allocatable                :: file      !< Data file name.
   character(len=:), allocatable                :: spec      !< `using` as written.
   character(len=:), allocatable                :: word      !< Current word.
   character(len=32), allocatable               :: names(:)  !< Parameter names.
   character(len=32), allocatable               :: kept(:)   !< Names grown (through a temporary).
   real(R8P), allocatable                       :: values(:,:) !< `using` values.
   real(R8P), allocatable                       :: x(:)      !< Abscissae.
   real(R8P), allocatable                       :: z(:)      !< Data.
   real(R8P), allocatable                       :: err(:)    !< Errors of the data.
   real(R8P), allocatable                       :: start(:)  !< Initial parameters.
   logical, allocatable                         :: use(:)    !< Points fitted.
   real(R8P)                                    :: range(2, 13) !< Ranges of the variables, then of the data, inline.
   logical                                      :: limited(2, 13) !< Their ends given.
   integer(I4P)                                 :: nranges   !< Ranges given.
   integer(I4P)                                 :: nvar      !< Independent variables.
   character(len=:), allocatable                :: vars      !< Their names, blank separated.
   real(R8P)                                    :: v         !< Number.
   logical                                      :: found     !< Variable found.
   logical                                      :: weighted  !< Errors given.
   logical                                      :: unit      !< `unitweights` given.
   integer(I4P)                                 :: set_index !< Dataset, -1 for all.
   integer(I4P)                                 :: every(6)  !< `every` fields.
   integer(I4P)                                 :: skip      !< First lines of the file not read (`skip N`).
   integer(I4P)                                 :: i         !< Token counter.
   integer(I4P)                                 :: k         !< Counter.
   integer(I4P)                                 :: colon     !< Range separator.
   integer(I4P)                                 :: first     !< First token of the model.

   iostat = 0_I4P
   iomsg = ''
   i = 1_I4P
   if (size(tokens) == 0) then
      call fail('fit: a function, a data file and via are expected', iostat, iomsg)
      return
   endif
   ! the ranges of the independent variables in order, then of the data (gnuplot's): [min:max], [] or `*` none
   nranges = 0_I4P
   limited = .false.
   range = 0.0_R8P
   do while (i <= size(tokens, kind=I4P))
      if (tokens(i)%kind /= TOKEN_RANGE) exit
      nranges = nranges + 1_I4P
      if (nranges > 13_I4P) then
         call fail('fit: at most 13 ranges (12 variables and the data)', iostat, iomsg)
         return
      endif
      if (len_trim(tokens(i)%text) > 0) then
         colon = index(tokens(i)%text, ':', kind=I4P)
         if (colon == 0_I4P .or. index(tokens(i)%text, '=') > 0) then
            call fail('fit: a range is [min:max]', iostat, iomsg)
            return
         endif
         do k = 1_I4P, 2_I4P
            if (k == 1_I4P) then
               word = trim(adjustl(tokens(i)%text(1:colon - 1_I4P)))
            else
               word = trim(adjustl(tokens(i)%text(colon + 1_I4P:)))
            endif
            if (len(word) == 0 .or. word == '*') cycle
            call self%symbols%constant(word, range(k, nranges), iostat, iomsg)
            if (iostat /= 0_I4P) then
               iomsg = 'fit: range: '//iomsg
               return
            endif
            limited(k, nranges) = .true.
         enddo
      endif
      i = i + 1_I4P
   enddo
   ! the model: the text up to the data file name
   first = i
   do while (i <= size(tokens, kind=I4P))
      if (tokens(i)%kind == TOKEN_STRING) exit
      if (is_datablock(tokens(i)%text)) exit
      ! an array, as gnuplot's `fit f(x) A using 1:2 via a` (its element A[i] is the model's)
      if (i > first .and. tokens(i)%kind == TOKEN_WORD .and. self%symbols%is_array(tokens(i)%text)) then
         if (i == size(tokens, kind=I4P)) exit
         if (is_word(tokens(i + 1_I4P)%text, 'using u via index every')) exit
      endif
      i = i + 1_I4P
   enddo
   if (i > size(tokens, kind=I4P) .or. i == first) then
      call fail('fit: a function then a quoted data file (or a datablock, an array) are expected', iostat, iomsg)
      return
   endif
   text = trim(adjustl(statement(tokens(first)%first:tokens(i)%first - 1_I4P)))
   file = tokens(i)%text
   spec = ''
   set_index = -1_I4P
   every = [1_I4P, 1_I4P, 0_I4P, 0_I4P, -1_I4P, -1_I4P]
   skip = 0_I4P
   weighted = .false.
   unit = .false.
   allocate(names(0))
   i = i + 1_I4P
   do while (i <= size(tokens, kind=I4P))
      word = tokens(i)%text
      if (keyword(word, 'using', 1_I4P)) then
         if (.not. next_word(tokens, i, spec, iostat, iomsg)) return
         call parse_using(spec, fields, iostat, iomsg, self%figure%panels(self%figure%current)%degrees, self%symbols)
         if (iostat /= 0_I4P) return
      elseif (keyword(word, 'index', 1_I4P)) then
         if (.not. next_integer(tokens, i, set_index, iostat, iomsg, self%symbols)) return
      elseif (keyword(word, 'every', 2_I4P)) then
         if (.not. next_word(tokens, i, word, iostat, iomsg)) return
         call parse_every(word, every, iostat, iomsg, self%symbols)
         if (iostat /= 0_I4P) return
      elseif (word == 'skip') then
         ! gnuplot's `skip N`: the first N lines of the file not read
         if (.not. next_integer(tokens, i, skip, iostat, iomsg, self%symbols)) return
      elseif (word == 'yerrors' .or. word == 'yerror' .or. word == 'zerror' .or. word == 'zerrors') then
         weighted = .true.
         unit = .false.
      elseif (word == 'unitweights') then
         weighted = .false.
         unit = .true.
      elseif (word == 'via') then
         i = i + 1_I4P
         do while (i <= size(tokens, kind=I4P))
            if (tokens(i)%kind == TOKEN_STRING) then
               call fail('fit: via a parameter file is not supported (via the parameter names is)', iostat, iomsg)
               return
            endif
            if (tokens(i)%kind == TOKEN_WORD) then
               allocate(kept(size(names) + 1))
               kept(1:size(names)) = names
               kept(size(kept)) = tokens(i)%text
               ! an array element, `via A[1], A[2]` (the index a range token)
               if (i < size(tokens, kind=I4P)) then
                  if (tokens(i + 1_I4P)%kind == TOKEN_RANGE) then
                     i = i + 1_I4P
                     kept(size(kept)) = trim(kept(size(kept)))//'['//trim(adjustl(tokens(i)%text))//']'
                  endif
               endif
               call move_alloc(kept, names)
            endif
            i = i + 1_I4P
         enddo
         exit
      else
         call fail('fit: unsupported option "'//word//'"', iostat, iomsg)
         return
      endif
      i = i + 1_I4P
   enddo
   if (size(names) == 0) then
      call fail('fit: via and the names of the parameters are expected', iostat, iomsg)
      return
   endif
   ! the data: the independent variables, the data and their errors (`using X:Z:S`, `using X:Y:Z:S`, ...; with
   ! unitweights no errors, `using X:Y:Z`), as gnuplot: 2 columns X:Z, more the last the errors unless unitweights
   if (.not. allocated(fields)) fields = plain_columns([1_I4P, 2_I4P])
   if (size(fields) == 1) then
      call fail('fit: using X:Z, X:Z:S, X:Y:Z:S, ... expected', iostat, iomsg)
      return
   endif
   if (size(fields) >= 3 .and. .not. unit) weighted = .true.
   nvar = size(fields, kind=I4P) - merge(2_I4P, 1_I4P, weighted)
   if (nvar < 1_I4P .or. nvar > 12_I4P) then
      call fail('fit: 1 to 12 independent variables, using X:Z[:S], X:Y:Z[:S], ...', iostat, iomsg)
      return
   endif
   if (nranges > nvar + 1_I4P) then
      call fail('fit: more ranges than variables and data', iostat, iomsg)
      return
   endif
   ! their names: `set dummy` (all of them), else x then y, as gnuplot
   vars = ' x y'
   if (len(self%dummy) > 0) vars = ' '//self%dummy//' y'
   if (allocated(self%dummies)) then
      if (len_trim(self%dummies) > 0) vars = self%dummies
   endif
   if (word_count(vars) < nvar) then
      call fail('fit: name the independent variables beyond the second with set dummy', iostat, iomsg)
      return
   endif
   call self%load_data(data, file, iostat, iomsg, keep_text=any(fields%uses_text()), skip=skip)
   if (iostat /= 0_I4P) then
      iomsg = 'fit: '//iomsg
      return
   endif
   call data%table(fields, set_index, every, values, header=any(fields%name_count() > 0_I4P) .or. self%column_headers)
   allocate(use(size(values, 1)))
   use = .true.
   do k = 1_I4P, nvar + 1_I4P + merge(1_I4P, 0_I4P, weighted)
      use = use .and. ieee_is_finite(values(:, k))
   enddo
   ! the ranges: of the variables, then of the data
   do i = 1_I4P, nranges
      do k = 1_I4P, size(use, kind=I4P)
         if (.not. use(k)) cycle
         if (limited(1, i)) use(k) = values(k, i) >= range(1, i)
         if (limited(2, i) .and. use(k)) use(k) = values(k, i) <= range(2, i)
      enddo
   enddo
   x = pack(values(:, 1), use)
   z = pack(values(:, nvar + 1_I4P), use)
   if (weighted) then
      err = pack(values(:, nvar + 2_I4P), use)
   else
      allocate(err(size(z)))
      err = 1.0_R8P
   endif
   ! the parameters: their values now, 1 if undefined (gnuplot)
   allocate(start(size(names)))
   do k = 1_I4P, size(names, kind=I4P)
      call get_parameter(self%symbols, trim(names(k)), v, found)
      if (.not. found) v = 1.0_R8P
      start(k) = v
      call set_parameter(self%symbols, trim(names(k)), v)
   enddo
   if (nvar == 1_I4P) then
      call model%compile(text, iostat, iomsg, variable=first_word(vars), &
                         degrees=self%figure%panels(self%figure%current)%degrees, symbols=self%symbols)
   else
      call model%compile(text, iostat, iomsg, degrees=self%figure%panels(self%figure%current)%degrees, &
                         symbols=self%symbols, sampled=vars)
   endif
   if (iostat /= 0_I4P) then
      iomsg = 'fit: '//iomsg
      return
   endif
   options = self%fit_options
   ! gnuplot's variables FIT_LIMIT and FIT_MAXITER, when defined
   call self%symbols%value_of('FIT_LIMIT', v, found)
   if (found) then
      if (v > 0.0_R8P) options%limit = v
   endif
   call self%symbols%value_of('FIT_MAXITER', v, found)
   if (found) then
      if (v >= 0.0_R8P) options%maxiter = nint(v, I4P)
   endif
   call self%symbols%set_value('FIT_CONVERGED', 0.0_R8P, .true.)
   fitted%text = text
   fitted%names = names
   fitted%x = x
   if (nvar == 1_I4P) then
      fitted%vars = first_word(vars)
   else
      fitted%vars = vars
      allocate(fitted%xs(size(x), nvar))
      do k = 1_I4P, nvar
         fitted%xs(:, k) = pack(values(:, k), use)
      enddo
   endif
   fitted%degrees = self%figure%panels(self%figure%current)%degrees
   fitted%symbols = self%symbols
   call levenberg_marquardt(fitted, z, err, start, options, result, weighted)
   if (len(result%message) > 0) then
      do k = 1_I4P, size(names, kind=I4P)
         call set_parameter(self%symbols, trim(names(k)), start(k))
      enddo
   else
      do k = 1_I4P, size(names, kind=I4P)
         call set_parameter(self%symbols, trim(names(k)), result%params(k))
         if (self%fit_errorvariables .and. index(names(k), '[') == 0) &
            call self%symbols%set_value(trim(names(k))//'_err', result%errors(k), .false.)
      enddo
      call self%symbols%set_value('FIT_NDF', real(result%ndf, R8P), .true.)
      call self%symbols%set_value('FIT_WSSR', result%wssr, .false.)
      call self%symbols%set_value('FIT_STDFIT', result%stdfit, .false.)
      call self%symbols%set_value('FIT_P', result%p, .false.)
      call self%symbols%set_value('FIT_NITER', real(result%niter, R8P), .true.)
      call self%symbols%set_value('FIT_CONVERGED', merge(1.0_R8P, 0.0_R8P, result%converged), .true.)
   endif
   if (self%fit_verbosity /= 'quiet') call fit_report(result, names, '-', "'"//file//"'"//trim(' using '//spec), &
                                                      text, self%fit_verbosity == 'brief')
   if (len(self%fit_logfile) > 0) call fit_report(result, names, self%fit_logfile, &
                                                  "'"//file//"'"//trim(' using '//spec), text, .false.)
   if (len(result%message) > 0) call fail('fit: '//result%message, iostat, iomsg)
   endsubroutine fit_command

   subroutine script_model_values(self, p, f, ok)
   !< The model at every abscissa, the parameters set as user variables of the model's own symbols.
   class(script_model), intent(inout) :: self !< Model.
   real(R8P),           intent(in)    :: p(:) !< Parameters.
   real(R8P),           intent(out)   :: f(:) !< Values.
   logical,             intent(out)   :: ok   !< All defined.
   type(expression_object)            :: e    !< Model at these parameters.
   character(len=:), allocatable      :: msg  !< Compilation message.
   integer(I4P)                       :: ios  !< Compilation status.
   integer(I4P)                       :: q    !< Counter.

   do q = 1_I4P, size(p, kind=I4P)
      call set_parameter(self%symbols, trim(self%names(q)), p(q))
   enddo
   if (allocated(self%xs)) then
      ! several independent variables: their names read the columns of a row of xs
      call e%compile(self%text, ios, msg, degrees=self%degrees, symbols=self%symbols, sampled=self%vars)
      ok = ios == 0_I4P
      if (.not. ok) return
      do q = 1_I4P, size(self%xs, 1, kind=I4P)
         f(q) = e%evaluate(self%xs(q, :), q - 1_I4P)
      enddo
   else
      call e%compile(self%text, ios, msg, variable=self%vars, degrees=self%degrees, symbols=self%symbols)
      ok = ios == 0_I4P
      if (.not. ok) return
      do q = 1_I4P, size(self%x, kind=I4P)
         f(q) = e%value_at(self%x(q))
      enddo
   endif
   ok = all(ieee_is_finite(f))
   endsubroutine script_model_values

   pure function word_count(text) result(n)
   !< Number of blank separated words of `text`.
   character(len=*), intent(in) :: text !< Text.
   integer(I4P)                 :: n    !< Words.
   integer(I4P)                 :: k    !< Character counter.

   n = 0_I4P
   do k = 1_I4P, len(text, kind=I4P)
      if (text(k:k) == ' ') cycle
      if (k == 1_I4P) then
         n = n + 1_I4P
      elseif (text(k - 1_I4P:k - 1_I4P) == ' ') then
         n = n + 1_I4P
      endif
   enddo
   endfunction word_count

   pure function first_word(text) result(word)
   !< The first blank separated word of `text`.
   character(len=*), intent(in)  :: text !< Text.
   character(len=:), allocatable :: word !< First word.
   integer(I4P)                  :: b    !< Its end.

   word = trim(adjustl(text))
   b = index(word, ' ', kind=I4P)
   if (b > 0_I4P) word = word(1:b - 1_I4P)
   endfunction first_word

   subroutine set_parameter(symbols, name, v)
   !< Set the fit parameter `name` to `v`: a user variable, or an array element `A[i]` (gnuplot's `via A[1], A[2]`).
   type(symbols_object), intent(inout) :: symbols !< Symbols.
   character(len=*),     intent(in)    :: name    !< Parameter.
   real(R8P),            intent(in)    :: v       !< Value.
   integer(I4P)                        :: b       !< Bracket.
   integer(I8P)                        :: k       !< Element.
   integer(I4P)                        :: ios     !< Read status.
   logical                             :: ok      !< Set.
   type(value_object)                  :: e       !< Element value (by components: nvfortran 26.9).

   b = index(name, '[', kind=I4P)
   if (b > 1_I4P .and. name(len(name):len(name)) == ']') then
      read(name(b + 1_I4P:len(name) - 1), *, iostat=ios) k
      e%r = v
      if (ios == 0_I4P) call symbols%set_element(name(1:b - 1_I4P), k, e, ok)
   else
      call symbols%set_value(name, v, .false.)
   endif
   endsubroutine set_parameter

   subroutine get_parameter(symbols, name, v, found)
   !< Value of the fit parameter `name`: a user variable or an array element `A[i]`; `found` false if none (or none
   !< set).
   type(symbols_object), intent(in)  :: symbols !< Symbols.
   character(len=*),     intent(in)  :: name    !< Parameter.
   real(R8P),            intent(out) :: v       !< Value.
   logical,              intent(out) :: found   !< A value found.
   integer(I4P)                      :: b       !< Bracket.
   integer(I8P)                      :: k       !< Element.
   integer(I4P)                      :: ios     !< Read status.
   type(value_object)                :: e       !< Element.
   logical                           :: set     !< Element set.

   v = 0.0_R8P
   found = .false.
   b = index(name, '[', kind=I4P)
   if (b > 1_I4P .and. name(len(name):len(name)) == ']') then
      read(name(b + 1_I4P:len(name) - 1), *, iostat=ios) k
      if (ios /= 0_I4P) return
      call symbols%get_element(name(1:b - 1_I4P), k, e, found, set)
      found = found .and. set .and. .not. e%is_string
      if (found) v = merge(real(e%i, R8P), e%r, e%is_int)
   else
      call symbols%value_of(name, v, found)
   endif
   endsubroutine get_parameter

   ! private procedures
   function assignment(self, statement, iostat, iomsg) result(done)
   !< gnuplot's `NAME = expression` (a user variable, its value now) or `NAME(P1, ...) = expression` (a user function):
   !< an `=` right after the name or the parameter list, not `==`. False if `statement` is neither.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   character(len=*),              intent(in)    :: statement !< Statement.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   logical                                      :: done      !< An assignment or a definition.
   character(len=*), parameter   :: LETTERS = UNAME_START
   character(len=:), allocatable :: s       !< Statement, leading blanks removed.
   character(len=:), allocatable :: name    !< Symbol name.
   character(len=:), allocatable :: list    !< Parameter list.
   character(len=:), allocatable :: rhs     !< Right-hand side (a copy: nvfortran 26.9 blanks an associate name
                                            !< of a substring).
   character(len=64), allocatable :: params(:) !< Parameters.
   integer(I4P)                  :: k       !< Character counter.
   integer(I4P)                  :: e       !< Name end.
   integer(I4P)                  :: close   !< Closing parenthesis.
   integer(I4P)                  :: comma   !< Parameter separator.
   logical                       :: is_function !< A function definition.
   type(value_list)              :: elements    !< An array's elements.
   logical                       :: listed      !< An array or a slice.

   iostat = 0_I4P
   iomsg = ''
   done = .false.
   s = trim(adjustl(statement))
   if (len(s) == 0) return
   if (scan(s(1:1), LETTERS) == 0) return
   e = verify(s, UNAME_CHARS, kind=I4P)
   if (e == 0_I4P) return
   name = s(1:e - 1_I4P)
   k = e
   is_function = .false.
   if (s(k:k) == '[' .and. self%symbols%is_array(name)) then
      ! an array element, `A[i] = expression`
      close = closing_bracket(s, k)
      if (close == 0_I4P) return
      list = s(k + 1_I4P:close - 1_I4P)
      k = close + 1_I4P
      do while (k <= len(s, kind=I4P))
         if (s(k:k) /= ' ' .and. s(k:k) /= achar(9)) exit
         k = k + 1_I4P
      enddo
      if (k > len(s, kind=I4P)) return
      if (s(k:k) /= '=') return
      if (k < len(s, kind=I4P)) then
         if (s(k + 1_I4P:k + 1_I4P) == '=') return
      endif
      done = .true.
      rhs = s(k + 1_I4P:)
      call self%symbols%assign_element(name, list, trim(adjustl(rhs)), iostat, iomsg, &
                                       degrees=self%figure%panels(self%figure%current)%degrees)
      return
   endif
   if (s(k:k) == '(') then
      close = index(s(k:), ')', kind=I4P)
      if (close == 0_I4P) return
      list = s(k + 1_I4P:k + close - 2_I4P)
      k = k + close
      is_function = .true.
   endif
   do while (k <= len(s, kind=I4P))
      if (s(k:k) /= ' ' .and. s(k:k) /= achar(9)) exit
      k = k + 1_I4P
   enddo
   if (k > len(s, kind=I4P)) return
   if (s(k:k) /= '=') return
   if (k < len(s, kind=I4P)) then
      if (s(k + 1_I4P:k + 1_I4P) == '=') return
   endif
   done = .true.
   rhs = s(k + 1_I4P:)
   if (is_function) then
      allocate(params(0))
      do while (len_trim(list) > 0)
         comma = index(list, ',', kind=I4P)
         if (comma == 0_I4P) comma = len(list, kind=I4P) + 1_I4P
         params = [character(len=64) :: params, adjustl(list(1:comma - 1_I4P))]
         list = list(min(comma + 1_I4P, len(list, kind=I4P) + 1_I4P):)
      enddo
      call self%symbols%define(name, params, trim(adjustl(rhs)), iostat, iomsg)
   else
      ! an array or a slice of one makes an array, gnuplot's B = A[2:3]
      call self%symbols%array_value(rhs, elements, listed, iostat, iomsg, &
                                    degrees=self%figure%panels(self%figure%current)%degrees)
      if (iostat /= 0_I4P) return
      if (listed) then
         call self%symbols%store_array(name, elements, iostat, iomsg)
         return
      endif
      call self%symbols%assign(name, trim(adjustl(rhs)), iostat, iomsg, &
                               degrees=self%figure%panels(self%figure%current)%degrees)
   endif
   endfunction assignment

   subroutine binary_items(self, tokens, three_d, items, iostat, iomsg)
   !< The `plot` tokens with each gnuplot binary array (`'file' binary array=(W,H)|WxH [record=...] [format='%uchar...']
   !< [flipx] [flipy] [flip=x|y] [dx=DX] [dy=DY] [origin=(X,Y)] [skip=N] [endian=little|big]`) read into a datablock,
   !< one line per pixel: its fields (as the format: one specifier for every field, else one per field) then x and y
   !< (pixel i, j at origin + (i dx, j dy), the first scan line at the bottom unless flipped); the item's `using`
   !< prefixed by these x:y columns, or `using x:y:1:...:N` (N fields: rgbimage 3, rgbalpha 4, else the format's); a
   !< splot's (`three_d`) by x:y:(0), its pixels at z 0 (gnuplot's).
   class(script_object),            intent(inout) :: self      !< Interpreter.
   type(token_object),              intent(in)    :: tokens(:) !< Items tokens.
   logical,                         intent(in)    :: three_d   !< A splot.
   type(token_object), allocatable, intent(out)   :: items(:)  !< Tokens, binary files as datablocks.
   integer(I4P),                    intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable,   intent(out)   :: iomsg     !< Error message.
   character(len=:), allocatable                  :: word      !< Option word.
   character(len=:), allocatable                  :: value     !< Option value.
   character(len=:), allocatable                  :: format    !< Field formats.
   character(len=:), allocatable                  :: lines     !< Datablock text.
   character(len=:), allocatable                  :: bytes     !< File content.
   character(len=:), allocatable                  :: name      !< Datablock name.
   character(len=:), allocatable                  :: style     !< The item's style.
   character(len=8)                               :: kinds(64) !< Field types.
   real(R8P)                                      :: step(2)   !< Pixel size.
   real(R8P)                                      :: origin(2) !< First pixel position.
   real(R8P)                                      :: v         !< A value read.
   integer(I4P)                                   :: shape(2)  !< Pixels across and up.
   integer(I4P)                                   :: nkinds    !< Field types given.
   integer(I4P)                                   :: nfields   !< Fields per pixel.
   integer(I4P)                                   :: skip      !< Header bytes.
   integer(I4P)                                   :: pos       !< Byte position.
   integer(I4P)                                   :: k, j, q, f, c !< Counters.
   integer(I4P)                                   :: last      !< Item end.
   integer(I4P)                                   :: u         !< File unit.
   integer(I4P)                                   :: nbytes    !< File size.
   logical                                        :: flip(2)   !< Flipped x, y.
   logical                                        :: big       !< Big endian.
   logical                                        :: has_using !< The item has its using.
   type(token_object)                             :: t         !< New token.

   iostat = 0_I4P
   iomsg = ''
   allocate(items(0))
   k = 1_I4P
   do while (k <= size(tokens, kind=I4P))
      if (.not. (tokens(k)%kind == TOKEN_WORD .and. tokens(k)%text == 'binary' .and. size(items) > 0)) then
         call push(items, tokens(k))
         k = k + 1_I4P
         cycle
      endif
      ! the options
      shape = 0_I4P
      step = 1.0_R8P
      origin = 0.0_R8P
      flip = .false.
      big = .false.
      skip = 0_I4P
      format = ''
      k = k + 1_I4P
      do while (k <= size(tokens, kind=I4P))
         if (tokens(k)%kind /= TOKEN_WORD) exit
         word = tokens(k)%text
         value = ''
         if (index(word, '=') > 0) then
            value = word(index(word, '=') + 1:)
            word = word(1:index(word, '=') - 1)
         endif
         select case (word)
         case ('array', 'record')
            ! (W,H) or WxH, or W alone (one line)
            value = strip_parentheses(value)
            do q = 1_I4P, len(value, kind=I4P)
               if (value(q:q) == 'x' .or. value(q:q) == ',' .or. value(q:q) == ':') value(q:q) = ' '
            enddo
            shape = 1_I4P
            if (index(trim(adjustl(value)), ' ') > 0) then
               read(value, *, iostat=iostat) shape
            else
               read(value, *, iostat=iostat) shape(1)
            endif
            if (iostat /= 0_I4P .or. any(shape < 1_I4P)) then
               call fail('plot: binary '//word//'=(W,H) expected', iostat, iomsg)
               return
            endif
         case ('format')
            format = value
            if (len(format) > 1) then
               if (scan(format(1:1), '"'//"'") > 0) format = format(2:len(format) - 1)
            endif
         case ('flipx', 'flipy')
            flip(merge(1, 2, word == 'flipx')) = .true.
         case ('flip')
            if (index(value, 'x') > 0) flip(1) = .true.
            if (index(value, 'y') > 0) flip(2) = .true.
         case ('dx', 'dy')
            if (.not. to_number(value, v)) then
               call fail('plot: binary '//word//'=D expected', iostat, iomsg)
               return
            endif
            step(merge(1, 2, word == 'dx')) = v
         case ('origin')
            value = strip_parentheses(value)
            read(value, *, iostat=iostat) origin
            if (iostat /= 0_I4P) then
               call fail('plot: binary origin=(X,Y) expected', iostat, iomsg)
               return
            endif
         case ('skip')
            read(value, *, iostat=iostat) skip
            if (iostat /= 0_I4P) then
               call fail('plot: binary skip=N expected', iostat, iomsg)
               return
            endif
         case ('endian')
            big = value == 'big' .or. value == 'swap'
         case ('filetype')
            call fail('plot: binary filetype='//value//' is not supported (raw arrays only)', iostat, iomsg)
            return
         case default
            exit
         endselect
         k = k + 1_I4P
      enddo
      if (any(shape < 1_I4P)) then
         call fail('plot: binary needs array=(W,H) (raw arrays only)', iostat, iomsg)
         return
      endif
      ! the item: its style and using, up to the next comma
      last = k - 1_I4P
      has_using = .false.
      style = ''
      do q = k, size(tokens, kind=I4P)
         if (tokens(q)%kind == TOKEN_COMMA) exit
         last = q
         if (tokens(q)%kind == TOKEN_WORD .and. keyword(tokens(q)%text, 'using', 1_I4P)) has_using = .true.
         if (tokens(q)%kind == TOKEN_WORD .and. keyword(tokens(q)%text, 'with', 1_I4P) .and. &
             q < size(tokens, kind=I4P)) style = style_name(tokens(q + 1_I4P)%text)
      enddo
      ! the field types: %type each (one for every field)
      nkinds = 0_I4P
      q = 1_I4P
      do while (q <= len(format, kind=I4P) .and. nkinds < size(kinds, kind=I4P))
         if (format(q:q) /= '%') then
            q = q + 1_I4P
            cycle
         endif
         j = q + 1_I4P
         do while (j <= len(format, kind=I4P))
            if (format(j:j) == '%') exit
            j = j + 1_I4P
         enddo
         nkinds = nkinds + 1_I4P
         kinds(nkinds) = format(q + 1:j - 1)
         q = j
      enddo
      if (nkinds == 0_I4P) then
         ! gnuplot's default: floats
         nkinds = 1_I4P
         kinds(1) = 'float'
      endif
      nfields = nkinds
      if (nkinds == 1_I4P) then
         select case (style)
         case ('rgbimage')
            nfields = 3_I4P
         case ('rgbalpha')
            nfields = 4_I4P
         case default
            nfields = 1_I4P
         endselect
      endif
      ! the bytes
      open(newunit=u, file=items(size(items))%text, access='stream', form='unformatted', action='read', &
           status='old', iostat=iostat)
      if (iostat /= 0_I4P) then
         call fail('plot: cannot open "'//items(size(items))%text//'"', iostat, iomsg)
         return
      endif
      inquire(unit=u, size=nbytes)
      allocate(character(len=max(nbytes, 0)) :: bytes)
      if (nbytes > 0) read(u, iostat=iostat) bytes
      close(u)
      pos = skip + 1_I4P
      ! the text in a buffer sized for the widest numbers (a concatenation per value would be quadratic)
      block
         character(len=32)             :: cell   !< A value written.
         character(len=:), allocatable :: buffer !< Datablock text.
         integer(I4P)                  :: row    !< Scan line.
         integer(I4P)                  :: col    !< Pixel in it.
         integer(I4P)                  :: at     !< Characters written.
         integer(I4P)                  :: w      !< Width of a value.

         allocate(character(len=int(shape(1), I8P) * shape(2) * (nfields + 2_I4P) * 26_I8P) :: buffer)
         at = 0_I4P
         do row = 0_I4P, shape(2) - 1_I4P
            do col = 0_I4P, shape(1) - 1_I4P
               do f = 1_I4P, nfields
                  c = min(f, nkinds)
                  call read_field(trim(kinds(c)), v)
                  if (iostat /= 0_I4P) return
                  write(cell, '(ES24.16E3)') v
                  w = len_trim(adjustl(cell), kind=I4P)
                  buffer(at + 1:at + w + 1) = trim(adjustl(cell))//' '
                  at = at + w + 1_I4P
               enddo
               write(cell, '(ES24.16E3)') origin(1) + step(1) * real(merge(shape(1) - 1_I4P - col, col, flip(1)), R8P)
               w = len_trim(adjustl(cell), kind=I4P)
               buffer(at + 1:at + w + 1) = trim(adjustl(cell))//' '
               at = at + w + 1_I4P
               write(cell, '(ES24.16E3)') origin(2) + step(2) * real(merge(shape(2) - 1_I4P - row, row, flip(2)), R8P)
               w = len_trim(adjustl(cell), kind=I4P)
               buffer(at + 1:at + w + 1) = trim(adjustl(cell))//new_line('a')
               at = at + w + 1_I4P
            enddo
         enddo
         lines = buffer(1:at)
      endblock
      deallocate(bytes)
      ! the datablock, named for this item
      self%binary_count = self%binary_count + 1_I4P
      name = '$__binary'//int_str(int(self%binary_count, I8P))
      call self%symbols%set_string(name, lines)
      items(size(items))%kind = TOKEN_WORD
      items(size(items))%text = name
      ! the item's using after the x:y columns of the pixels, or every field
      t%kind = TOKEN_WORD
      if (.not. has_using) then
         t%text = 'using'
         call push(items, t)
         t%text = int_str(int(nfields + 1_I4P, I8P))//':'//int_str(int(nfields + 2_I4P, I8P))
         if (three_d) t%text = t%text//':(0)'
         do f = 1_I4P, nfields
            t%text = t%text//':'//int_str(int(f, I8P))
         enddo
         call push(items, t)
      endif
      do q = k, last
         call push(items, tokens(q))
         if (q > k) then
            if (tokens(q - 1_I4P)%kind == TOKEN_WORD .and. keyword(tokens(q - 1_I4P)%text, 'using', 1_I4P)) &
               items(size(items))%text = int_str(int(nfields + 1_I4P, I8P))//':'// &
                                         int_str(int(nfields + 2_I4P, I8P))//trim(merge(':(0)', '    ', three_d))// &
                                         ':'//tokens(q)%text
         endif
      enddo
      k = last + 1_I4P
   enddo
   contains
      pure function strip_parentheses(text) result(inner)
      !< `text` without its surrounding parentheses.
      character(len=*), intent(in)  :: text  !< Text.
      character(len=:), allocatable :: inner !< Inside.

      inner = trim(adjustl(text))
      if (len(inner) > 0) then
         if (inner(1:1) == '(') inner = inner(2:)
      endif
      if (index(inner, ')') > 0) inner = inner(1:index(inner, ')') - 1)
      endfunction strip_parentheses

      subroutine read_field(kind, value)
      !< The next field of type `kind` from the bytes (gnuplot's %char, %uchar, %short, %ushort, %int, %uint, %long,
      !< %ulong, %float, %double and their sized names), little endian unless big.
      character(len=*), intent(in)  :: kind  !< Type.
      real(R8P),        intent(out) :: value !< Value.
      integer(I4P)                  :: n     !< Bytes.
      character(len=8)              :: b     !< The field's bytes, little endian.
      integer(I4P)                  :: q     !< Byte.

      value = 0.0_R8P
      select case (kind)
      case ('char', 'uchar', 'int8', 'uint8')
         n = 1_I4P
      case ('short', 'ushort', 'int16', 'uint16')
         n = 2_I4P
      case ('int', 'uint', 'int32', 'uint32', 'float', 'float32')
         n = 4_I4P
      case ('long', 'ulong', 'int64', 'uint64', 'double', 'float64')
         n = 8_I4P
      case default
         call fail('plot: binary format: unsupported type "%'//kind//'"', iostat, iomsg)
         return
      endselect
      if (pos + n - 1_I4P > len(bytes, kind=I4P)) then
         call fail('plot: binary: the file is shorter than its array', iostat, iomsg)
         return
      endif
      b = repeat(achar(0), 8)
      do q = 1_I4P, n
         if (big) then
            b(q:q) = bytes(pos + n - q:pos + n - q)
         else
            b(q:q) = bytes(pos + q - 1_I4P:pos + q - 1_I4P)
         endif
      enddo
      pos = pos + n
      select case (kind)
      case ('uchar', 'uint8')
         value = real(iachar(b(1:1)), R8P)
      case ('char', 'int8')
         value = real(iachar(b(1:1)), R8P)
         if (value > 127.0_R8P) value = value - 256.0_R8P
      case ('short', 'int16', 'ushort', 'uint16')
         value = real(iachar(b(1:1)), R8P) + 256.0_R8P * real(iachar(b(2:2)), R8P)
         if (value > 32767.0_R8P .and. (kind == 'short' .or. kind == 'int16')) value = value - 65536.0_R8P
      case ('int', 'int32', 'uint', 'uint32')
         value = real(iachar(b(1:1)), R8P) + 256.0_R8P * (real(iachar(b(2:2)), R8P) + 256.0_R8P * &
                 (real(iachar(b(3:3)), R8P) + 256.0_R8P * real(iachar(b(4:4)), R8P)))
         if (value > 2147483647.0_R8P .and. (kind == 'int' .or. kind == 'int32')) value = value - 4294967296.0_R8P
      case ('long', 'int64', 'ulong', 'uint64')
         value = real(transfer(b(1:8), 0_I8P), R8P)
      case ('float', 'float32')
         value = real(transfer(b(1:4), 0.0_R4P), R8P)
      case default
         value = transfer(b(1:8), 0.0_R8P)
      endselect
      endsubroutine read_field
   endsubroutine binary_items

   subroutine plot_command(self, tokens, text, iostat, iomsg, three_d)
   !< `plot` and `splot` (`three_d`) (plot_items), gnuplot's binary arrays (`'file' binary array=...`) first read into
   !< datablocks.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Items tokens.
   character(len=*),              intent(in)    :: text      !< Text the tokens come from, for function titles.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   logical,             optional, intent(in)    :: three_d   !< A splot.
   logical                                      :: splot_mode !< A splot.
   type(token_object), allocatable              :: items(:)  !< Tokens, binary files as datablocks.
   integer(I4P)                                 :: k         !< Token counter.
   logical                                      :: binary    !< A binary file among the items.

   splot_mode = .false.
   if (present(three_d)) splot_mode = three_d
   binary = .false.
   do k = 2_I4P, size(tokens, kind=I4P)
      if (tokens(k)%kind == TOKEN_WORD .and. tokens(k)%text == 'binary') binary = .true.
   enddo
   if (.not. binary) then
      call self%plot_items(tokens, text, iostat, iomsg, splot_mode)
      return
   endif
   call self%binary_items(tokens, splot_mode, items, iostat, iomsg)
   if (iostat /= 0_I4P) return
   call self%plot_items(items, text, iostat, iomsg, splot_mode)
   endsubroutine plot_command

   subroutine plot_items(self, tokens, text, iostat, iomsg, splot_mode)
   !< `plot` items: each a data file or a function with modifiers, comma separated; replaces the previous plot and
   !< renders it.
   !<
   !< Functions are sampled once all the items are read: their x range depends on the data of the whole plot, as gnuplot.
   !< Until then each holds its place (its color, its key row) as an empty series.
   !<
   !< `splot` (`splot_mode`, gnuplot 6.0's): the items have a z, the third using field, read as the last column and kept
   !< apart (`zfield`), so that the other fields are the styles' plot fields; a function of x and y is sampled on its
   !< iso-curves (`function_rows`), a matrix becomes rows x y z (`matrix_rows`), both read as data. The series keep their
   !< heights and scans (`attach_z`): the blocks of the data, separated by blank lines.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Items tokens.
   character(len=*),              intent(in)    :: text      !< Text the tokens come from, for function titles.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   logical,                       intent(in)    :: splot_mode !< A splot.
   type(expression_object)                      :: zfield    !< The z field of a splot item.
   logical                                      :: z_read    !< `zfield` read as the last column of the values.
   logical                                      :: one_column3d !< A splot of one data column: z, x and y the point
                                                                !< and scan numbers.
   real(R8P),        allocatable                :: z3(:)     !< The heights of the splot item.
   integer(I4P),     allocatable                :: row_sets(:) !< Dataset of each row, -1 for the breaks.
   character(len=:), allocatable                :: generated !< Rows of a splot function or matrix.
   integer(I4P)                                 :: grid_rows !< Scans of a splot function's grid, 0: all scans.
   character(len=:), allocatable                :: shown_spec !< The using spec as written, for the title.
   character(len=:), allocatable                :: para_fields !< A parametric splot item: its x, y, z functions as
                                                               !< using fields of its u, v grid.
   integer(I4P)                                 :: item_first !< First token of the item (its file).
   integer(I4P)                                 :: title_to  !< Last token of the automatic title: the file and its
                                                             !< data options after it (index, every, using, matrix).
   logical                                      :: other_seen !< An option other than the data ones met.
   character(len=:), allocatable                :: option_word !< The current option as written.
   logical                                      :: item_nocontours !< `nocontours`: no contour lines of the item.
   logical                                      :: item_nosurface  !< `nosurface`: the item's surface not drawn.
   logical                                      :: item_nogrid     !< `nogrid`: the item's data not gridded (dgrid3d).
   logical                                      :: item_mask       !< `mask`: the item masked by the `with mask` polygons.
   type(datafile_object)                        :: data      !< Current data file.
   type(expression_object)                      :: func      !< Current function.
   type(expression_object), allocatable         :: functions(:) !< Functions of the plot.
   type(expression_object), allocatable         :: yfunctions(:) !< y(t) of the parametric functions, in their order.
   type(expression_object)                      :: yfunc     !< Current y(t) of a parametric pair.
   integer(I4P),            allocatable         :: slots(:)  !< Series index of each function.
   logical,                 allocatable         :: sharpens(:) !< Each function sharpened (gnuplot `sharpen`).
   integer(I4P)                                 :: spider_group !< Spider plot group (gnuplot `newspiderplot`).
   logical                                      :: sharpen_item !< The item is sharpened.
   integer(I4P)                                 :: hull      !< `convexhull` 1, `concavehull` 2, `delaunay` 3, none 0.
   real(R8P)                                    :: hull_expand !< `expand D` of the hull, 0 for none.
   logical                                      :: surface_item !< A polar gridded surface (`with surface`).
   logical                                      :: ps_var    !< `ps variable`: each point's size from a column.
   logical                                      :: pt_var    !< `pt variable`: each point's type from a column.
   logical                                      :: zsort_item !< `zsort`: the points drawn in the order of their z.
   logical                                      :: hypertext !< `with labels hypertext`: the texts on mouse-over.
   real(R8P), allocatable                       :: point_sizes(:) !< The sizes of `ps variable`.
   integer(I4P), allocatable                    :: point_types(:) !< The types of `pt variable`.
   character(len=:), allocatable                :: axes      !< Item axes, `x1y1`, `x1y2`, `x2y1` or `x2y2`.
   character(len=:), allocatable                :: file      !< Item data file.
   character(len=:), allocatable                :: written   !< Item data file as written, for the automatic title.
   character(len=:), allocatable                :: spec      !< `using` specification as written, empty if none.
   character(len=:), allocatable                :: using     !< `using` keyword as written.
   character(len=1)                             :: quote     !< Quote of the data file.
   character(len=:), allocatable                :: loaded    !< File in `data`.
   character(len=:), allocatable                :: fill_rgb  !< Fill color of the item (`fc`), unallocated if none.
   logical                                      :: head_skipped !< `notitle columnhead`: the first row a header.
   logical                                      :: keyentry  !< The item is gnuplot's `keyentry`.
   logical                                      :: keyentry_blank !< A keyentry without sample (`with labels`, or
                                                                  !< no `with`).
   logical                                      :: with_given !< The item has its `with`.
   integer(I4P)                                 :: loaded_skip !< Lines it skipped (`skip N`).
   character(len=:), allocatable                :: word      !< Modifier.
   character(len=:), allocatable                :: title     !< Item title.
   character(len=:), allocatable                :: with      !< Item style.
   character(len=:), allocatable                :: filter    !< Item `smooth` filter, empty for none.
   real(R8P)                                    :: bandwidth !< kdensity bandwidth, default if not positive.
   logical                                      :: binned    !< `bins`: the item is binned.
   integer(I4P)                                 :: nbins     !< `bins=N`, the number of bins (`set samples` if absent).
   real(R8P)                                    :: binrange(2) !< `binrange [lo:hi]`, equal ends for the data's.
   real(R8P)                                    :: binwidth  !< `binwidth=W`, not positive if absent.
   logical                                      :: binavg    !< `binvalue=avg`.
   real(R8P)                                    :: bin_edges(2) !< Outer edges of the bins.
   logical                                      :: lcvar     !< lc variable: the colors from the last using column.
   logical                                      :: box_lcvar !< lc variable on boxplot factors: a linetype per factor.
   integer(I4P)                                 :: item_lt   !< The item's `lt N`, 0 if not given.
   logical                                      :: item_noauto !< The item out of the autoscaling (`noautoscale`).
   logical                                      :: lcz       !< lc palette z: the palette values from the last column.
   character(len=:), allocatable                :: palette_lc !< `lc palette` marker of the item, empty for none.
   real(R8P),        allocatable                :: zcolors(:) !< Palette values of the points (`lc palette z`).
   logical                                      :: arrow_var    !< `arrowstyle variable`: a style per arrow.
   logical                                      :: string_next  !< A quoted string after the option word.
   logical                                      :: single_offset !< A label offset X alone.
   logical                                      :: band_smooth  !< A smoothed band of filledcurves (x:y1:y2).
   real(R8P),        allocatable                :: band_low(:)  !< Its second curve smoothed.
   logical                                      :: at_next      !< The word `at` after the option word.
   real(R8P),        allocatable                :: arrow_tags(:) !< Arrow style of each arrow (`arrowstyle variable`).
   real(R8P),        allocatable                :: arrow_z(:)    !< Palette value of each arrow (its style's
                                                                  !< `lc palette z`).
   character(len=24), allocatable               :: point_colors(:) !< Point colors of lc variable.
   character(len=:), allocatable                :: format    !< Item readout format, unallocated if not given.
   character(len=:), allocatable                :: shaping   !< Item option a readout does not take, empty if none.
   character(len=:), allocatable                :: fs        !< Item fill style words, unallocated if not given.
   real(R8P),        allocatable                :: base      !< Baseline of `filledcurves y=V`, unallocated if none.
   real(R8P),        allocatable                :: widths(:) !< Box widths, `using x:y:width`.
   real(R8P),        allocatable                :: hole      !< Pie hole fraction (`donut F`), unallocated for none.
   real(R8P),        allocatable                :: gauge_scale(:) !< Gauge scale (`range [A:B]`), unallocated for none.
   integer(I4P)                                 :: cells     !< Gauge cells (`segments N`), 0 for none.
   logical                                      :: rose_linear !< Rose radius by value (`linear`).
   real(R8P),        allocatable                :: whisker   !< Candlestick whisker crossbars (`whiskerbars [F]`).
   real(R8P),        allocatable                :: closes(:) !< Closing values of candlesticks and finance bars.
   character(len=:), allocatable                :: heads     !< Arrowhead words of vectors and arrows.
   real(R8P)                                    :: item_head(2) !< Their head length (0 the default) and angle [deg].
   integer(I4P)                                 :: title_at  !< Title place: 0 the key, 1 beginning, 2 end, 3 at X,Y.
   integer(I4P)                                 :: title_justify !< Its justification: 0 its own, 1 left, 2 right.
   character(len=:), allocatable                :: point_tc  !< Color of the character points (`tc`).
   type(font_object)                            :: item_font !< Font of the item's labels (`font "..."`).
   character(len=2)                             :: ellipse_units !< Units of the ellipse diameters (`units xy|xx|yy`).
   logical                                      :: rotate_var !< Labels rotated by a using field (`rotate variable`).
   logical                                      :: polar_base !< The base is a polar `r=V`.
   real(R8P),        allocatable                :: label_rotations(:) !< Their rotations [deg].
   real(R8P)                                    :: title_xy(2) !< That position [screen fractions].
   character(len=9)                             :: item_head_system !< System of the head length.
   character(len=:), allocatable                :: curve     !< Filled curve option words.
   logical                                      :: keyed     !< The label column is `key(N)`, row names.
   real(R8P),        allocatable                :: at_x      !< Position of a parallel axis (`at X`).
   character(len=:), allocatable                :: label_opts !< Option words of labels.
   character(len=:), allocatable                :: group_fs  !< Fill of the histograms of a group (`newhistogram fs`).
   logical                                      :: errorbars !< Histograms with error bars (`set style histogram
                                                             !< errorbars`).
   logical                                      :: columns   !< Column stacked histograms.
   real(R8P),        allocatable                :: arcs(:,:) !< Wedge angles of circles.
   integer(I4P)                                 :: label_col !< Column of `xtic(N)`, 1 for an expression, 0 for none.
   character(len=2)                             :: label_axis !< Axis of the text labels: `x`, `x2`, `y`, `y2`.
   type(expression_object)                      :: label_field !< Field of the text labels (`xtic(...)`, labels).
   logical                                      :: needs_text !< The cell texts are read (`strcol`, labels).
   logical                                      :: time_axis(2) !< Time data on the x and y axes of the item.
   character(len=:), allocatable                :: xlabels(:) !< Text labels of the points.
   integer(I4P)                                 :: label_col2 !< A second tic labels field (`xtic(..):ytic(..)`), 1, or
                                                              !< 0 for none.
   type(expression_object)                      :: label_field2 !< Its field.
   character(len=2)                             :: label_axis2  !< Its axis.
   character(len=:), allocatable                :: labels2(:)   !< Its text labels of the points.
   integer(I4P)                                 :: tic_col  !< `labels` with tic labels (`xticlabels(2)`): the column of
                                                            !< those, as label_col, 0 for none.
   type(expression_object)                      :: tic_field !< Its field.
   character(len=:), allocatable                :: ticlabels(:) !< Its text labels of the points.
   logical                                      :: one_field !< `using` gives one field (before the point number).
   logical                                      :: weight_one !< The single column is x, each point of weight 1.
   logical                                      :: is_matrix !< The item reads a `matrix` file.
   logical                                      :: nonuniform !< A `nonuniform matrix`: x and y in its first row and column.
   type(line_style_object)                      :: line      !< Item line properties.
   real(R8P),        allocatable                :: x(:)      !< Abscissae.
   real(R8P),        allocatable                :: y(:)      !< Ordinates.
   real(R8P),        allocatable                :: values(:,:) !< Values of the `using` fields.
   real(R8P),        allocatable                :: xlow(:)   !< Horizontal error bar starts.
   real(R8P),        allocatable                :: xhigh(:)  !< Horizontal error bar ends.
   real(R8P),        allocatable                :: ylow(:)   !< Vertical error bar starts.
   real(R8P),        allocatable                :: yhigh(:)  !< Vertical error bar ends.
   type(expression_object), allocatable         :: fields(:) !< `using` fields, unallocated for default.
   type(expression_object)                      :: point     !< Point number field.
   type(expression_object), allocatable         :: kept(:)   !< Fields kept (`fields = f(fields)` by a temporary: see
                                                             !< `push`).
   integer(I4P)                                 :: ux        !< Default abscissa column.
   integer(I4P)                                 :: uy        !< Default ordinate column.
   integer(I4P)                                 :: nbar      !< Error bar columns.
   integer(I4P)                                 :: set_index !< Dataset, -1 for all.
   integer(I4P)                                 :: every(6)  !< `every` fields.
   integer(I4P)                                 :: skip      !< First lines of the file not read (`skip N`).
   integer(I4P)                                 :: number    !< Integer argument.
   integer(I4P)                                 :: i         !< Token counter.
   integer(I4P)                                 :: head      !< First token of a function.
   logical                                      :: has_title !< Title given (or notitle).
   logical                                      :: is_function !< The item is a function, else a data file.
   logical                                      :: is_head     !< `title columnhead[(N)]`.
   integer(I4P)                                 :: head_column !< Column of `title columnhead(N)`.
   integer(I4P)                                 :: head_piece(2) !< Substring `[i:j]` of that header, 0 for all.
   type(loop_level), allocatable                :: levels(:)   !< `for [...]` clauses of the current item.
   integer(I4P)                                 :: item_start  !< First token of an iterated item.
   logical                                      :: skip_item   !< An iteration without values.
   logical                                      :: polar_ok !< The item can be drawn on a polar panel.
   logical                                      :: headed    !< The first row of each dataset is a header.
   integer(I4P)                                 :: title_column !< Header column titling the item: 0 the y one,
                                                                !< negative for none (gnuplot `title columnhead(N)`).
   character(len=:), allocatable                :: missing   !< Header name found nowhere.
   character(len=:), allocatable                :: dummy     !< Dummy variable of the functions.
   type(expression_object)                      :: table_if  !< `with table if COND`: the condition.
   logical                                      :: auto_title !< The item's title is the automatic one (literal).
   logical                                      :: plain_item !< `noenhanced`: the item's title as it is.
   logical                                      :: has_table_if !< A `with table` condition given.
   integer(I4P)                                 :: nranges   !< Inline ranges read.
   real(R8P),        allocatable                :: own_range(:,:) !< Sampling range of each function, `plot f(x),
                                                                  !< [A:B] g(x)` (`own_set` the ends given).
   logical,          allocatable                :: own_set(:,:) !< Ends of `own_range` given.
   real(R8P),        allocatable                :: own_base(:) !< `filledcurves y=V` base of each function, NaN if
                                                               !< none.
   real(R8P)                                    :: item_range(2) !< Sampling range of the current item.
   logical                                      :: item_set(2) !< Ends of `item_range` given.
   character(len=:), allocatable                :: item_prefix !< The item's range as written, for its title.
   character(len=:), allocatable                :: item_glued  !< An assignment the item follows without a comma, as
                                                               !< written (`ysum=0 `), for its title.
   character(len=32)                            :: sample_names(2) !< Variables named by the item's sampling ranges.
   real(R8P)                                    :: sample_range(2, 2) !< Ends of the item's sampling ranges.
   logical                                      :: sample_set(2, 2) !< Ends given.
   real(R8P)                                    :: sample_step(2) !< Sampling intervals given, 0 for none.
   integer(I4P)                                 :: nsample   !< Sampling ranges of the item.
   integer(I4P)                                 :: pseudo    !< Pseudo-file: 1 `'+'`, 2 `'++'`, 0 none.
   character(len=:), allocatable                :: sampled   !< Its sample variables.
   character(len=:), allocatable                :: item_dummy !< The dummy variable of the item's function.
   logical                                      :: sample_first !< `plot sample [...] ...`: no plot range.

   iostat = 0_I4P
   iomsg = ''
   loaded = ''
   loaded_skip = 0_I4P
   allocate(functions(0), slots(0), yfunctions(0), own_range(2, 0), own_set(2, 0), own_base(0), sharpens(0))
   spider_group = 0_I4P
   call self%figure%clear
   self%figure%panels(self%figure%current)%three_d = splot_mode
   if (size(tokens) == 0) then
      call fail('plot: nothing to plot', iostat, iomsg)
      return
   endif
   ! gnuplot's dummy variable is t in polar and parametric modes
   dummy = merge('t', 'x', self%figure%panels(self%figure%current)%polar .or. self%parametric)
   if (len(self%dummy) > 0) dummy = self%dummy
   ! inline ranges, [x] then [y], for this plot only: plot [0:2*pi] [-1:1] sin(x), plot [t=0:1] t**2; after the
   ! `sample` keyword, the first item's sampling ranges
   i = 1_I4P
   nranges = 0_I4P
   sample_first = .false.
   if (size(tokens) >= 2) then
      if (tokens(1)%kind == TOKEN_WORD .and. tokens(2)%kind == TOKEN_RANGE) sample_first = tokens(1)%text == 'sample'
   endif
   if (sample_first) i = 2_I4P
   do while (i <= size(tokens, kind=I4P))
      if (sample_first) exit
      if (tokens(i)%kind /= TOKEN_RANGE) exit
      nranges = nranges + 1_I4P
      if (splot_mode) then
         ! [x] [y] [z]
         if (nranges > 3_I4P) then
            call fail('splot: at most three inline ranges, [x], [y] and [z], are supported', iostat, iomsg)
            return
         endif
         call inline_range(tokens(i)%text, merge(4_I4P, nranges, nranges == 3_I4P))
         if (iostat /= 0_I4P) return
         i = i + 1_I4P
         cycle
      endif
      if (nranges > merge(3_I4P, 2_I4P, self%parametric .or. self%figure%panels(self%figure%current)%polar)) then
         if (self%parametric .or. self%figure%panels(self%figure%current)%polar) then
            call fail('plot: at most three inline ranges, [t], [x] and [y], in parametric mode', iostat, iomsg)
         else
            call fail('plot: at most two inline ranges, [x] and [y], are supported', iostat, iomsg)
         endif
         return
      endif
      ! parametric and polar: [t] [x] [y], as gnuplot
      if (self%parametric .or. self%figure%panels(self%figure%current)%polar) then
         call inline_range(tokens(i)%text, merge(3_I4P, nranges - 1_I4P, nranges == 1_I4P))
      else
         call inline_range(tokens(i)%text, nranges)
      endif
      if (iostat /= 0_I4P) return
      i = i + 1_I4P
   enddo
   if (i > size(tokens, kind=I4P)) then
      call fail('plot: nothing to plot', iostat, iomsg)
      return
   endif
   allocate(levels(0))
   do
      ! data file or function; a comma ending the plot ends it, as gnuplot
      if (i > size(tokens, kind=I4P)) then
         if (size(levels) == 0 .and. tokens(size(tokens))%kind == TOKEN_COMMA) exit
         call fail('plot: missing item after ","', iostat, iomsg)
         return
      endif
      ! plot for [...] item: the item parsed again for each value of its clauses
      if (size(levels) == 0) then
         call iteration_start
         if (iostat /= 0_I4P) return
         if (skip_item) then
            ! an empty iteration: no series, as gnuplot
            do while (i <= size(tokens, kind=I4P))
               if (tokens(i)%kind == TOKEN_COMMA) exit
               i = i + 1_I4P
            enddo
            if (i > size(tokens, kind=I4P)) exit
            i = i + 1_I4P
            cycle
         endif
      endif
      ! newspiderplot: the next spider plot items a new group of polygons on the same axes, as gnuplot
      if (tokens(i)%kind == TOKEN_WORD) then
         if (tokens(i)%text == 'newspiderplot') then
            spider_group = spider_group + 1_I4P
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) exit
            if (tokens(i)%kind /= TOKEN_COMMA) then
               call fail('plot: newspiderplot takes no options', iostat, iomsg)
               return
            endif
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) exit
            cycle
         endif
      endif
      ! newhistogram ["title"] [lt N] [fs FILL] [at X]: the next histograms a new group
      if (tokens(i)%kind == TOKEN_WORD) then
         if (keyword(tokens(i)%text, 'newhistogram', 4_I4P)) then
            call new_histogram
            if (iostat /= 0_I4P) return
            if (i > size(tokens, kind=I4P)) then
               call fail('plot: newhistogram needs histograms after it', iostat, iomsg)
               return
            endif
            i = i + 1_I4P
            cycle
         endif
      endif
      ! gnuplot: a range before an item after the first is its own sampling range, `*` the axis end
      item_set = .false.
      item_range = 0.0_R8P
      item_prefix = ''
      item_glued = ''
      sample_names = ''
      sample_range = 0.0_R8P
      sample_set = .false.
      sample_step = 0.0_R8P
      nsample = 0_I4P
      ! [min:max], [name=min:max], [name=min:max:step]; two for `'++'` (u then v)
      do while (tokens(i)%kind == TOKEN_RANGE .and. nsample < 2_I4P)
         nsample = nsample + 1_I4P
         item_prefix = item_prefix//'['//tokens(i)%text//'] '
         call sampling_range(tokens(i)%text, nsample)
         if (iostat /= 0_I4P) return
         i = i + 1_I4P
         if (i > size(tokens, kind=I4P)) then
            call fail('plot: missing item after "'//trim(item_prefix)//'"', iostat, iomsg)
            return
         endif
      enddo
      item_set = sample_set(:, 1)
      item_range = sample_range(:, 1)
      item_dummy = dummy
      if (len_trim(sample_names(1)) > 0) item_dummy = trim(sample_names(1))
      ! gnuplot: an item may be an assignment or a function definition, done in its turn (`plot s=.1, c(t), s=.3,
      ! c(t)`): the functions after it are compiled with it
      if (tokens(i)%kind == TOKEN_WORD) then
         block
            integer(I4P)                  :: last    !< Last token of the item.
            character(len=:), allocatable :: message !< Assignment error.
            integer(I4P)                  :: status  !< Assignment status.

            last = i
            do while (last < size(tokens, kind=I4P))
               if (tokens(last + 1_I4P)%kind == TOKEN_COMMA) exit
               last = last + 1_I4P
            enddo
            ! an assignment the item follows without a comma, gnuplot's `plot ysum=0 '' using ...`
            if (expression_end(tokens, i) < last) then
               if (index(text(tokens(i)%first:tokens(expression_end(tokens, i))%last), '=') > 0 .and. &
                   tokens(expression_end(tokens, i) + 1_I4P)%kind /= TOKEN_RANGE) then
                  if (self%assignment(text(tokens(i)%first:tokens(expression_end(tokens, i))%last), status, &
                                      message)) then
                     if (status /= 0_I4P) then
                        call fail('plot: '//message, iostat, iomsg)
                        return
                     endif
                     item_glued = text(tokens(i)%first:tokens(expression_end(tokens, i))%last)//' '
                     i = expression_end(tokens, i) + 1_I4P
                     last = i - 1_I4P
                  endif
               endif
            endif
            if (last < i) then
               continue
            elseif (index(text(tokens(i)%first:tokens(last)%last), '=') > 0) then
               if (self%assignment(text(tokens(i)%first:tokens(last)%last), status, message)) then
                  if (status /= 0_I4P) then
                     call fail('plot: '//message, iostat, iomsg)
                     return
                  endif
                  i = last + 1_I4P
                  ! gnuplot: definitions before an iterated item are its own, run on each pass (`for [i=1:3] k = r[i],
                  ! f(x, k)`): the item after them is still iterated
                  if (size(levels) > 0 .and. i < size(tokens, kind=I4P)) then
                     i = i + 1_I4P
                     cycle
                  endif
                  if (size(levels) > 0) then
                     if (next_values()) then
                        i = item_start
                        cycle
                     endif
                     call iteration_end
                  endif
                  if (i > size(tokens, kind=I4P)) exit
                  i = i + 1_I4P
                  cycle
               endif
            endif
         endblock
      endif
      item_first = i
      is_function = tokens(i)%kind == TOKEN_WORD
      keyentry = .false.
      keyentry_blank = .false.
      quote = ' '
      ! a word joined to strings or substrings is a string expression, a file name: d[1:3] . "x.dat"
      if (is_function) is_function = all(tokens(i:expression_end(tokens, i))%kind == TOKEN_WORD)
      if (tokens(i)%kind == TOKEN_RANGE) then
         call fail('plot: one sampling range per item, found "['//tokens(i)%text//']"', iostat, iomsg)
         return
      elseif (tokens(i)%kind == TOKEN_COMMA) then
         call fail('plot: missing item before ","', iostat, iomsg)
         return
      elseif ((is_datablock(tokens(i)%text) .or. self%symbols%is_array(tokens(i)%text)) .and. &
              tokens(i)%kind == TOKEN_WORD) then
         is_function = .false.
         file = tokens(i)%text
         written = file
         self%previous_file = file
      elseif (is_function .and. tokens(i)%text == 'keyentry') then
         ! gnuplot 6.0's keyentry: a key entry only, no point; the function NaN, untitled unless titled
         is_function = .true.
         written = 'NaN'
         keyentry = .true.
         ! its own function (a keyentry first in the plot has no other)
         call func%compile(written, iostat, iomsg)
         if (iostat /= 0_I4P) return
      elseif (is_function) then
         ! the expression runs up to the first item option: blanks may separate its words, `x * 2`
         head = i
         do while (i < size(tokens, kind=I4P))
            ! the range of `sum [i=a:b] term` is the sum's
            if (tokens(i + 1_I4P)%kind == TOKEN_RANGE .and. sum_head(tokens(i))) then
               i = i + 1_I4P
               cycle
            endif
            if (tokens(i + 1_I4P)%kind /= TOKEN_WORD) exit
            if (is_item_option(tokens(i + 1_I4P)%text)) exit
            i = i + 1_I4P
         enddo
         written = text(tokens(head)%first:tokens(i)%last)
         ! a constant string expression is a data file name, as gnuplot's `plot name u 1:2`
         block
            character(len=:), allocatable :: value     !< Constant value.
            character(len=:), allocatable :: message   !< Not a constant.
            integer(I4P)                  :: status    !< Constant status.
            logical                       :: is_string !< A string.

            call self%symbols%text_of(written, value, is_string, status, message, &
                                      degrees=self%figure%panels(self%figure%current)%degrees)
            if (status == 0_I4P .and. is_string) then
               is_function = .false.
               file = value
            endif
         endblock
         if (is_function .and. splot_mode) then
            ! a function of x and y, read as the third field of its sampled grid (function_rows); in parametric mode
            ! three, x(u,v), y(u,v), z(u,v), the fields of its u, v grid
            para_fields = ''
            if (self%parametric) then
               block
                  integer(I4P)                  :: part  !< Function counter.
                  integer(I4P)                  :: first !< First token of a function.
                  character(len=:), allocatable :: f     !< The functions as fields.

                  f = '('//written//')'
                  do part = 2_I4P, 3_I4P
                     if (i + 2_I4P > size(tokens, kind=I4P)) then
                        call fail('splot: parametric function not fully specified: x(u,v), y(u,v), z(u,v) expected', &
                                  iostat, iomsg)
                        return
                     endif
                     if (tokens(i + 1_I4P)%kind /= TOKEN_COMMA) then
                        call fail('splot: parametric function not fully specified: x(u,v), y(u,v), z(u,v) expected', &
                                  iostat, iomsg)
                        return
                     endif
                     i = i + 2_I4P
                     first = i
                     do while (i < size(tokens, kind=I4P))
                        if (tokens(i + 1_I4P)%kind /= TOKEN_WORD) exit
                        if (is_item_option(tokens(i + 1_I4P)%text)) exit
                        i = i + 1_I4P
                     enddo
                     f = f//':('//text(tokens(first)%first:tokens(i)%last)//')'
                  enddo
                  written = text(tokens(head)%first:tokens(i)%last)
                  para_fields = f
               endblock
            endif
         elseif (is_function) then
            associate(panel => self%figure%panels(self%figure%current))
               call func%compile(written, iostat, iomsg, variable=item_dummy, degrees=panel%degrees, &
                                 symbols=self%symbols)
            endassociate
            if (iostat /= 0_I4P) then
               iomsg = 'plot: '//iomsg
               return
            endif
            if (self%parametric) then
               ! gnuplot `set parametric`: the item is a pair x(t), y(t), its options after the second
               block
                  integer(I4P)                  :: head2    !< First token of y(t).
                  character(len=:), allocatable :: written2 !< y(t) as written.

                  if (i + 2_I4P > size(tokens, kind=I4P)) then
                     call fail('plot: parametric function not fully specified: x(t), y(t) expected', iostat, iomsg)
                     return
                  endif
                  if (tokens(i + 1_I4P)%kind /= TOKEN_COMMA) then
                     call fail('plot: parametric function not fully specified: x(t), y(t) expected', iostat, iomsg)
                     return
                  endif
                  i = i + 2_I4P
                  head2 = i
                  do while (i < size(tokens, kind=I4P))
                     if (tokens(i + 1_I4P)%kind == TOKEN_RANGE .and. sum_head(tokens(i))) then
                        i = i + 1_I4P
                        cycle
                     endif
                     if (tokens(i + 1_I4P)%kind /= TOKEN_WORD) exit
                     if (is_item_option(tokens(i + 1_I4P)%text)) exit
                     i = i + 1_I4P
                  enddo
                  written2 = text(tokens(head2)%first:tokens(i)%last)
                  associate(panel => self%figure%panels(self%figure%current))
                     call yfunc%compile(written2, iostat, iomsg, variable=item_dummy, degrees=panel%degrees, &
                                        symbols=self%symbols)
                  endassociate
                  if (iostat /= 0_I4P) then
                     iomsg = 'plot: '//iomsg
                     return
                  endif
                  written = written//', '//written2
               endblock
            endif
         else
            if (len(file) == 0) file = self%previous_file
            if (len(file) == 0) then
               call fail('plot: '''' needs a previous data file', iostat, iomsg)
               return
            endif
            self%previous_file = file
         endif
      elseif (expression_end(tokens, i) > i) then
         ! a string expression as the file name: "run".i.".dat"
         head = i
         if (.not. self%string_expression(tokens, i, file, iostat, iomsg)) then
            iomsg = 'plot: '//iomsg
            return
         endif
         written = text(tokens(head)%first:tokens(i)%last)
         if (len(file) == 0) file = self%previous_file
         if (len(file) == 0) then
            call fail('plot: '''' needs a previous data file', iostat, iomsg)
            return
         endif
         self%previous_file = file
      else
         file = tokens(i)%text
         written = file
         quote = tokens(i)%quote
         if (len(file) == 0) file = self%previous_file
         if (len(file) == 0) then
            call fail('plot: '''' needs a previous data file', iostat, iomsg)
            return
         endif
         self%previous_file = file
      endif
      ! gnuplot's pseudo-files: '+' samples a variable (column 1), '++' a grid of two (columns 1 and 2)
      pseudo = 0_I4P
      sampled = ''
      if (.not. is_function .and. quote /= ' ') then
         if (file == '+' .or. file == '++') pseudo = len(file, kind=I4P)
      endif
      if (pseudo == 1_I4P) then
         sampled = dummy
         if (len_trim(sample_names(1)) > 0) sampled = trim(sample_names(1))
      elseif (pseudo == 2_I4P) then
         sampled = 'u v'
         if (len_trim(sample_names(1)) > 0) sampled = trim(sample_names(1))//' v'
         if (len_trim(sample_names(2)) > 0) sampled = sampled(1:index(sampled, ' '))//trim(sample_names(2))
      endif
      if (nsample == 2_I4P .and. pseudo /= 2_I4P) then
         call fail('plot: two sampling ranges apply to the ''++'' pseudo-file only', iostat, iomsg)
         return
      endif
      if (is_function .and. sample_step(1) /= 0.0_R8P) then
         call fail('plot: a sampling interval applies to the ''+'' and ''++'' pseudo-files, not to functions', &
                   iostat, iomsg)
         return
      endif
      if (len(item_prefix) > 0 .and. .not. is_function .and. pseudo == 0_I4P) then
         write(error_unit, '(A)') 'foresight: warning: ignoring sample range in non-sampled data plot'
         item_set = .false.
      endif
      ! modifiers
      if (allocated(fields)) deallocate(fields)
      spec = ''
      using = 'using'
      label_col = 0_I4P
      label_col2 = 0_I4P
      tic_col = 0_I4P
      label_axis = 'x'
      is_matrix = .false.
      nonuniform = .false.
      set_index = -1_I4P
      every = [1_I4P, 1_I4P, 0_I4P, 0_I4P, -1_I4P, -1_I4P]
      skip = 0_I4P
      with = self%data_style
      if (is_function) with = self%function_style
      with_given = .false.
      has_table_if = .false.
      has_title = .false.
      auto_title = .false.
      plain_item = .false.
      title = ''
      title_column = -1_I4P
      head_piece = 0_I4P
      axes = 'x1y1'
      filter = ''
      bandwidth = 0.0_R8P
      binned = .false.
      nbins = self%samples
      binrange = 0.0_R8P
      binwidth = -1.0_R8P
      binavg = .false.
      lcvar = .false.
      box_lcvar = .false.
      item_lt = 0_I4P
      item_noauto = .false.
      if (allocated(format)) deallocate(format)
      if (allocated(hole)) deallocate(hole)
      if (allocated(whisker)) deallocate(whisker)
      heads = ''
      arrow_var = .false.
      sharpen_item = .false.
      hull = 0_I4P
      hull_expand = 0.0_R8P
      surface_item = .false.
      ps_var = .false.
      pt_var = .false.
      zsort_item = .false.
      hypertext = .false.
      if (allocated(point_sizes)) deallocate(point_sizes)
      if (allocated(point_types)) deallocate(point_types)
      band_smooth = .false.
      polar_base = .false.
      rotate_var = .false.
      ellipse_units = 'xy'
      if (allocated(point_tc)) deallocate(point_tc)
      item_font = font_object()
      title_at = 0_I4P
      title_justify = 0_I4P
      title_xy = 0.0_R8P
      item_head = 0.0_R8P
      item_head_system = 'first'
      label_opts = ''
      curve = ''
      keyed = .false.
      if (allocated(at_x)) deallocate(at_x)
      if (allocated(gauge_scale)) deallocate(gauge_scale)
      cells = 0_I4P
      rose_linear = .false.
      if (allocated(fs)) deallocate(fs)
      if (allocated(fill_rgb)) deallocate(fill_rgb)
      head_skipped = .false.
      if (allocated(base)) deallocate(base)
      shaping = ''
      line = line_style_object()
      title_to = i
      other_seen = .false.
      item_nocontours = .false.
      item_nosurface = .false.
      item_nogrid = .false.
      item_mask = .false.
      i = i + 1_I4P
      do while (i <= size(tokens, kind=I4P))
         if (tokens(i)%kind == TOKEN_COMMA) exit
         word = tokens(i)%text
         option_word = word
         if (tokens(i)%kind /= TOKEN_WORD) then
            call fail('plot: unexpected "'//word//'"', iostat, iomsg)
            return
         endif
         ! the next token, read here and not by internal functions in the conditions below: nvfortran 26.9 -O2 inlined
         ! those and read the token counter stale (`index "name"` misparsed, bug 24)
         string_next = .false.
         at_next = .false.
         if (i < size(tokens, kind=I4P)) then
            string_next = tokens(i + 1_I4P)%kind == TOKEN_STRING
            at_next = tokens(i + 1_I4P)%kind == TOKEN_WORD .and. tokens(i + 1_I4P)%text == 'at'
         endif
         if (is_function .and. (keyword(word, 'using', 1_I4P) .or. keyword(word, 'index', 1_I4P) .or. &
                                keyword(word, 'every', 2_I4P))) then
            call fail('plot: "'//word//'" applies to data files, not to the function "'//written//'"', iostat, iomsg)
            return
         elseif (keyword(word, 'using', 1_I4P)) then
            using = word
            ! a header name alone, quoted (`using "Denmark"`), as gnuplot
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%kind == TOKEN_STRING) then
                  i = i + 1_I4P
                  spec = '"'//tokens(i)%text//'"'
               elseif (.not. next_word(tokens, i, spec, iostat, iomsg)) then
                  return
               endif
            elseif (.not. next_word(tokens, i, spec, iostat, iomsg)) then
               return
            endif
            ! a spec broken after a colon (`using 2:1:\` and the next line), or written with blanks around its colons
            ! (`using (T(2)) : ($0) : 1`): its fields joined, as gnuplot
            do while (i < size(tokens, kind=I4P))
               if (tokens(i + 1_I4P)%kind /= TOKEN_WORD) exit
               if (spec(len(spec):len(spec)) /= ':' .and. tokens(i + 1_I4P)%text(1:1) /= ':') exit
               i = i + 1_I4P
               spec = spec//tokens(i)%text
            enddo
            ! gnuplot's data format after the spec, `using 1:2:3 "%lf %lf %lf"`: blank separated numeric conversions
            ! read the columns as foresight does (other formats are refused)
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%kind == TOKEN_STRING) then
                  i = i + 1_I4P
                  if (.not. plain_data_format(tokens(i)%text)) then
                     call fail('plot: a using format of blank separated %lf, %f, %le, %e, %g conversions is '// &
                               'supported, not "'//tokens(i)%text//'"', iostat, iomsg)
                     return
                  endif
               endif
            endif
            call split_xtic(spec, label_col, iostat, iomsg, keyed, label_field, label_axis)
            if (iostat /= 0_I4P) return
            if (label_col > 0_I4P .and. .not. keyed) then
               ! tic labels on two axes, `using 1:2:xtic(""):ytic("")` (the rug plot), as gnuplot
               block
                  logical :: keyed2 !< A key(N) field.

                  call split_xtic(spec, label_col2, iostat, iomsg, keyed2, label_field2, label_axis2)
                  if (iostat /= 0_I4P) return
                  if (label_col2 > 0_I4P .and. (keyed2 .or. label_axis2 == label_axis)) then
                     call fail('plot: two tic labels fields need two axes, xtic(..):ytic(..)', iostat, iomsg)
                     return
                  endif
               endblock
            endif
            if (pseudo > 0_I4P) then
               call parse_using(spec, fields, iostat, iomsg, self%figure%panels(self%figure%current)%degrees, &
                                self%symbols, sampled=sampled)
            else
               call parse_using(spec, fields, iostat, iomsg, self%figure%panels(self%figure%current)%degrees, &
                                self%symbols)
            endif
            if (iostat /= 0_I4P) return
         elseif (keyword(word, 'matrix', 3_I4P) .or. keyword(word, 'nonuniform', 4_I4P)) then
            if (is_function) then
               call fail('plot: matrix applies to data files, not to the function "'//written//'"', iostat, iomsg)
               return
            endif
            ! gnuplot `nonuniform matrix`: the first row the x values, the first column the y ones
            if (keyword(word, 'nonuniform', 4_I4P)) then
               if (.not. next_word(tokens, i, word, iostat, iomsg)) return
               if (.not. keyword(word, 'matrix', 3_I4P)) then
                  call fail('plot: nonuniform matrix expected', iostat, iomsg)
                  return
               endif
               nonuniform = .true.
            endif
            is_matrix = .true.
         elseif (keyword(word, 'index', 1_I4P) .and. string_next) then
            ! gnuplot `index "name"`: the dataset after the comment line starting with the name
            i = i + 1_I4P
            set_index = named_index(tokens(i)%text)
            if (iostat /= 0_I4P) return
         elseif (keyword(word, 'index', 1_I4P)) then
            if (.not. next_integer(tokens, i, set_index, iostat, iomsg, self%symbols)) return
         elseif (keyword(word, 'every', 2_I4P)) then
            if (.not. next_word(tokens, i, word, iostat, iomsg)) return
            call parse_every(word, every, iostat, iomsg, self%symbols)
            if (iostat /= 0_I4P) return
         elseif (word == 'skip') then
            ! gnuplot's `skip N`: the first N lines of the file not read
            if (is_function) then
               call fail('plot: "skip" applies to data files, not to the function "'//written//'"', iostat, iomsg)
               return
            endif
            if (.not. next_integer(tokens, i, skip, iostat, iomsg, self%symbols)) return
         elseif (keyword(word, 'with', 1_I4P)) then
            if (.not. next_word(tokens, i, word, iostat, iomsg)) return
            with = canonical_style(word)
            with_given = .true.
            if (len(with) == 0) then
               call fail('plot: unsupported style "'//word//'" (supported: '//STYLE_NAMES//')', iostat, iomsg)
               return
            endif
            if (with == 'table') then
               if (.not. self%table) then
                  call fail("plot: 'with table' requires a previous 'set table'", iostat, iomsg)
                  return
               endif
               ! if CONDITION, up to the end of the item: the rows written
               if (i < size(tokens, kind=I4P)) then
                  if (tokens(i + 1_I4P)%kind == TOKEN_WORD .and. tokens(i + 1_I4P)%text == 'if') then
                     i = i + 2_I4P
                     if (i > size(tokens, kind=I4P)) then
                        call fail('plot: with table if needs a condition', iostat, iomsg)
                        return
                     endif
                     head = i
                     do while (i < size(tokens, kind=I4P))
                        if (tokens(i + 1_I4P)%kind == TOKEN_COMMA) exit
                        i = i + 1_I4P
                     enddo
                     call table_if%compile(text(tokens(head)%first:tokens(i)%last), iostat, iomsg, &
                                           degrees=self%figure%panels(self%figure%current)%degrees, &
                                           symbols=self%symbols)
                     if (iostat /= 0_I4P) then
                        iomsg = 'plot: with table if: '//iomsg
                        return
                     endif
                     has_table_if = .true.
                  endif
               endif
            endif
            ! keyentry of another style: its key sample only, a filled box for the filled styles, a line and points for
            ! the error lines, else a line (the panel charts have no key entries of their own)
            if (keyentry .and. .not. function_drawable(with) .and. with /= 'table') then
               if (with == 'spiderplot') then
                  ! a key entry of the spider plot group: no axis (spider_key)
                  continue
               elseif (is_word(with, 'parallelaxes pie radar rose gauge readout')) then
                  call fail('plot: keyentry with '//with//' is not supported', iostat, iomsg)
                  return
               elseif (is_word(with, 'polygons circles ellipses boxplot candlesticks boxxyerror boxerrorbars '// &
                               'histograms sectors')) then
                  with = 'filledcurves'
               elseif (is_word(with, 'xerrorlines yerrorlines xyerrorlines')) then
                  with = 'linespoints'
               elseif (with == 'labels') then
                  ! no sample, as gnuplot 6.0
                  with = 'lines'
                  keyentry_blank = .true.
               else
                  with = 'lines'
               endif
            endif
            if (is_function .and. .not. function_drawable(with) .and. with /= 'table' .and. &
                .not. (keyentry .and. with == 'spiderplot')) then
               call fail('plot: a function is drawn with '//FUNCTION_STYLES//', not '//with, iostat, iomsg)
               return
            endif
            if (with == 'gauge') then
               do while (i < size(tokens, kind=I4P))
                  if (tokens(i + 1_I4P)%text == 'range') then
                     i = i + 2_I4P
                     if (i > size(tokens, kind=I4P)) then
                        call fail('plot: gauge range needs [A:B]', iostat, iomsg)
                        return
                     endif
                     if (.not. gauge_range(tokens(i))) return
                  elseif (tokens(i + 1_I4P)%text == 'segments') then
                     i = i + 1_I4P
                     if (.not. next_integer(tokens, i, cells, iostat, iomsg)) return
                     if (cells < 1_I4P .or. cells > 1000_I4P) then
                        call fail('plot: gauge segments takes 1 to 1000 cells', iostat, iomsg)
                        return
                     endif
                  else
                     exit
                  endif
               enddo
            endif
            if (with == 'vectors' .or. with == 'arrows') then
               ! arrow style words right after the style, as gnuplot: heads, fills, `size [SYS] L,A[,B]`, `fixed`,
               ! `as|arrowstyle N`
               do while (i < size(tokens, kind=I4P))
                  word = tokens(i + 1_I4P)%text
                  if (is_word(word, 'head heads nohead backhead filled empty nofilled')) then
                     i = i + 1_I4P
                     heads = heads//' '//word
                  elseif (word == 'noborder') then
                     i = i + 1_I4P
                     heads = heads//' filled'
                  elseif (word == 'fixed') then
                     ! foresight's heads keep their size on short arrows anyway
                     i = i + 1_I4P
                  elseif (word == 'size') then
                     i = i + 1_I4P
                     if (.not. head_size_option()) return
                  elseif (word == 'as' .or. keyword(word, 'arrowstyle', 6_I4P)) then
                     i = i + 1_I4P
                     if (.not. item_arrow_style()) return
                  else
                     exit
                  endif
               enddo
            endif
            if (with == 'ellipses' .and. i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%text == 'units') then
                  i = i + 2_I4P
                  if (i > size(tokens, kind=I4P)) then
                     call fail('plot: ellipses units xy expected', iostat, iomsg)
                     return
                  endif
                  if (.not. is_word(tokens(i)%text, 'xy xx yy')) then
                     call fail('plot: ellipses take units xy, xx or yy (the axes of the two diameters)', iostat, iomsg)
                     return
                  endif
                  ellipse_units = tokens(i)%text
               endif
            endif
            if (with == 'rose' .and. i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%text == 'linear') then
                  i = i + 1_I4P
                  rose_linear = .true.
               endif
            endif
            if (with == 'pie' .and. i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%text == 'donut') then
                  i = i + 1_I4P
                  allocate(hole)
                  if (.not. next_number(hole)) return
                  if (hole < 0.0_R8P .or. hole >= 1.0_R8P) then
                     call fail('plot: pie donut F needs a hole fraction from 0 to below 1', iostat, iomsg)
                     return
                  endif
               endif
            endif
            if (with == 'filledcurves' .and. i < size(tokens, kind=I4P)) then
               ! the fill options: closed (the default), x1, x2, y=V (y1=V), xy=X,Y, above, below
               do while (i < size(tokens, kind=I4P))
                  if (tokens(i + 1_I4P)%kind /= TOKEN_WORD) exit
                  word = tokens(i + 1_I4P)%text
                  if (is_word(word, 'closed x1 x2 above below y1 y2 y')) then
                     i = i + 1_I4P
                     curve = curve//' '//word
                  elseif (index(word, 'x=') == 1 .or. index(word, 'x1=') == 1 .or. index(word, 'x2=') == 1) then
                     ! to the vertical line x = V
                     i = i + 1_I4P
                     block
                        real(R8P) :: v !< The line.

                        if (.not. to_number(word(index(word, '=') + 1:), v)) then
                           call fail('plot: filledcurves '//word(1:index(word, '='))//'V needs a number, found "'// &
                                     word//'"', iostat, iomsg)
                           return
                        endif
                     endblock
                     curve = curve//' '//word
                  elseif (index(word, 'y=') == 1 .or. index(word, 'y1=') == 1 .or. index(word, 'y2=') == 1) then
                     i = i + 1_I4P
                     allocate(base)
                     if (.not. to_number(word(index(word, '=') + 1:), base)) then
                        call fail('plot: filledcurves y=V needs a number, found "'//word//'"', iostat, iomsg)
                        return
                     endif
                  elseif (index(word, 'xy=') == 1) then
                     ! xy=X,Y: the comma is a token of its own
                     if (i + 3_I4P > size(tokens, kind=I4P)) then
                        call fail('plot: filledcurves xy=X,Y expected', iostat, iomsg)
                        return
                     endif
                     if (tokens(i + 2_I4P)%kind /= TOKEN_COMMA) then
                        call fail('plot: filledcurves xy=X,Y expected', iostat, iomsg)
                        return
                     endif
                     curve = curve//' '//word//','//tokens(i + 3_I4P)%text
                     i = i + 3_I4P
                  elseif (index(word, 'r=') == 1) then
                     ! gnuplot's polar `r=V`: the band to the circle of radius V
                     if (.not. self%figure%panels(self%figure%current)%polar) then
                        call fail('plot: filledcurves r=V applies to polar plots', iostat, iomsg)
                        return
                     endif
                     i = i + 1_I4P
                     allocate(base)
                     if (.not. to_number(word(3:), base)) then
                        call fail('plot: filledcurves r=V needs a number, found "'//word//'"', iostat, iomsg)
                        return
                     endif
                     polar_base = .true.
                  elseif (word == 'r') then
                     call fail('plot: filledcurves r=V expected (the radius of the circle)', iostat, iomsg)
                     return
                  else
                     exit
                  endif
               enddo
            endif
         elseif (word == 'bins' .or. index(word, 'bins=') == 1 .or. word == 'binrange' .or. &
                 index(word, 'binwidth') == 1 .or. index(word, 'binval') == 1) then
            if (.not. bins_option()) return
         elseif (keyword(word, 'smooth', 1_I4P)) then
            if (.not. next_word(tokens, i, filter, iostat, iomsg)) return
            ! gnuplot: smooth bins is the filter bins, its options after it
            if (filter == 'bins' .or. index(filter, 'bins=') == 1) then
               filter = ''
               word = tokens(i)%text
               if (.not. bins_option()) return
               i = i + 1_I4P
               cycle
            endif
            ! gnuplot's deprecated `smooth convexhull`: `convexhull smooth path`
            if (gnuplot_abbreviates(filter, 'convex$hull')) then
               filter = 'path'
               hull = 1_I4P
            endif
            ! `smooth zsort`: the zsort filter (gnuplot 6.0)
            if (gnuplot_abbreviates(filter, 'z$sort')) then
               zsort_item = .true.
               filter = ''
               i = i + 1_I4P
               cycle
            endif
            filter = smooth_name(filter)
            if (.not. (is_word(filter, SMOOTH_MODES) .or. is_word(filter, CURVE_MODES) .or. filter == 'path')) then
               call fail('plot: unsupported smooth "'//filter//'" (supported: '//SMOOTH_MODES//' '//CURVE_MODES// &
                         ' path)', iostat, iomsg)
               return
            endif
            ! smooth kdensity bandwidth B
            if (filter == 'kdensity' .and. i < size(tokens, kind=I4P)) then
               if (keyword(tokens(i + 1_I4P)%text, 'bandwidth', 3_I4P)) then
                  i = i + 1_I4P
                  if (.not. next_number(bandwidth)) return
               endif
            endif
            if (is_function) then
               call fail('plot: smooth applies to data files, not to the function "'//written//'"', iostat, iomsg)
               return
            endif
         elseif (word == 'fs' .or. word == 'fill' .or. keyword(word, 'fillstyle', 5_I4P)) then
            call fill_words(fs)
            if (iostat /= 0_I4P) return
         elseif (word == 'fc' .or. keyword(word, 'fillcolor', 5_I4P)) then
            ! the fill color, gnuplot's: read as a line color, the line keeps its own
            block
               type(token_object), allocatable :: copy(:)  !< Tokens, `lc` for the word.
               type(line_style_object)         :: probe    !< Color read.

               copy = tokens
               copy(i)%text = 'lc'
               if (.not. line_option(copy, i, probe, iostat, iomsg, &
                                     self%figure%panels(self%figure%current)%linecolors, self%symbols)) then
                  iomsg = 'plot: fc: '//iomsg
                  return
               endif
               if (allocated(probe%lc)) then
                  if (index(probe%lc, '*palette') == 1 .and. probe%lc /= LC_PALETTE_Z) then
                     ! `fc palette cb V|frac F`: one palette color, the item's (fill and line), as gnuplot's keyentry
                     line%lc = probe%lc
                     line%palette = probe%palette
                  elseif (probe%lc == LC_PALETTE_Z .or. probe%lc == LC_VARIABLE .or. probe%lc == LC_RGB_VARIABLE) then
                     ! `fc palette [z]`, `fc variable`: the fills (and lines) colored per point, as lc's
                     line%lc = probe%lc
                  elseif (index(probe%lc, '*') == 1) then
                     call fail('plot: fc: this color form is not supported (lc variable, lc palette z color the '// &
                               'fills)', iostat, iomsg)
                     return
                  else
                     fill_rgb = probe%lc
                  endif
               endif
            endblock
         elseif (with == 'labels' .and. word == 'hypertext') then
            ! gnuplot's hypertext: the texts shown on mouse-over of their points, not drawn
            hypertext = .true.
         elseif (with == 'labels' .and. is_word(word, 'left center centre right norotate point nopoint rotate offset '// &
                                                'tc textcolor boxed')) then
            ! label options, in any order among the item options (pt, ps, lc are line options)
            if (.not. label_option()) return
         elseif (word == 'at' .and. with == 'parallelaxes') then
            allocate(at_x)
            if (.not. next_number(at_x)) return
         elseif (keyword(word, 'whiskerbars', 7_I4P)) then
            ! candlesticks crossbars, a fraction of the box width (1 by default)
            if (allocated(whisker)) deallocate(whisker)
            allocate(whisker)
            whisker = 1.0_R8P
            if (i < size(tokens, kind=I4P)) then
               if (to_number(tokens(i + 1_I4P)%text, whisker)) then
                  i = i + 1_I4P
               else
                  whisker = 1.0_R8P
               endif
            endif
            if (whisker < 0.0_R8P) then
               call fail('plot: whiskerbars takes a fraction of the box width >= 0', iostat, iomsg)
               return
            endif
         elseif (word == 'format') then
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) then
               call fail('plot: format needs a quoted string', iostat, iomsg)
               return
            endif
            if (tokens(i)%kind /= TOKEN_STRING) then
               call fail('plot: format needs a quoted string', iostat, iomsg)
               return
            endif
            format = tokens(i)%text
         elseif (keyword(word, 'axes', 2_I4P)) then
            shaping = word
            if (.not. next_word(tokens, i, axes, iostat, iomsg)) return
            if (all(axes /= ['x1y1', 'x1y2', 'x2y1', 'x2y2'])) then
               call fail('plot: axes x1y1, x1y2, x2y1 or x2y2 expected, found "'//axes//'"', iostat, iomsg)
               return
            endif
         elseif (keyword(word, 'title', 1_I4P) .and. at_next) then
            ! `title at ...`: the automatic title, placed
            i = i + 1_I4P
            if (.not. title_place()) return
         elseif (keyword(word, 'title', 1_I4P)) then
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) then
               call fail('plot: title needs a quoted string or columnhead', iostat, iomsg)
               return
            endif
            ! columnhead_title sets title_column: called on words only (Fortran does not short-circuit .and.)
            is_head = .false.
            if (tokens(i)%kind == TOKEN_WORD) is_head = columnhead_title(tokens(i)%text, head_column)
            ! columnhead(EXPRESSION), its column the value now: `for [i=3:22] '' using i title columnheader(i)`
            if (.not. is_head .and. tokens(i)%kind == TOKEN_WORD) then
               block
                  integer(I4P) :: open !< Opening parenthesis.
                  real(R8P)    :: v    !< Column.

                  open = index(tokens(i)%text, '(', kind=I4P)
                  if (open > 1_I4P .and. tokens(i)%text(len(tokens(i)%text):) == ')') then
                     if (keyword(tokens(i)%text(1:open - 1_I4P), 'columnheader', 3_I4P)) then
                        call self%range_value(tokens(i)%text(open + 1_I4P:len(tokens(i)%text) - 1), v, iostat, iomsg)
                        if (iostat /= 0_I4P) then
                           iomsg = 'plot: title: '//iomsg
                           return
                        endif
                        if (v < 1.0_R8P .or. v /= aint(v)) then
                           call fail('plot: title: columnhead needs a column number, found "'//tokens(i)%text//'"', &
                                     iostat, iomsg)
                           return
                        endif
                        is_head = .true.
                        head_column = int(v, I4P)
                     endif
                  endif
               endblock
            endif
            if (is_head) title_column = head_column
            if (is_head) then
               if (is_function) then
                  call fail('plot: a function has no column header', iostat, iomsg)
                  return
               endif
               ! `columnhead(N)[i:j]`: a substring of the header, as gnuplot's string expressions
               head_piece = 0_I4P
               if (i < size(tokens, kind=I4P)) then
                  if (tokens(i + 1_I4P)%kind == TOKEN_RANGE) then
                     i = i + 1_I4P
                     if (.not. substring_range(tokens(i)%text)) return
                  endif
               endif
            elseif (tokens(i)%kind == TOKEN_WORD .or. tokens(i)%kind == TOKEN_STRING) then
               ! a string expression: "speed", 'f' . i, sprintf("p = %.2f", p)
               if (.not. self%string_expression(tokens, i, title, iostat, iomsg)) then
                  iomsg = 'plot: title: '//iomsg
                  return
               endif
            else
               call fail('plot: title needs a string or columnhead', iostat, iomsg)
               return
            endif
            has_title = .true.
            ! gnuplot `title ... at beginning|end|X,Y`: by the curve, or a key entry at a screen position
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%kind == TOKEN_WORD .and. tokens(i + 1_I4P)%text == 'at') then
                  i = i + 1_I4P
                  if (.not. title_place()) return
               endif
            endif
         elseif (word == 'convexhull' .or. word == 'concavehull' .or. word == 'delaunay') then
            ! gnuplot's hull filters, `expand D` after them (`delaunay`: the triangles, gnuplot's undocumented filter)
            hull = merge(1_I4P, merge(2_I4P, 3_I4P, word == 'concavehull'), word == 'convexhull')
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%text == 'expand') then
                  i = i + 1_I4P
                  if (.not. next_real(tokens, i, hull_expand, iostat, iomsg, self%symbols)) then
                     iomsg = 'plot: expand: '//iomsg
                     return
                  endif
               endif
            endif
            if (is_function) then
               call fail('plot: '//word//' applies to data, not to the function "'//written//'"', iostat, iomsg)
               return
            endif
         elseif (word == 'zsort') then
            ! gnuplot's zsort filter: the points of each curve drawn in the order of their z (third column)
            zsort_item = .true.
         elseif (word == 'expand' .and. hull > 0_I4P) then
            ! `expand D` of a hull after other options (`concavehull smooth path expand D`)
            if (.not. next_real(tokens, i, hull_expand, iostat, iomsg, self%symbols)) then
               iomsg = 'plot: expand: '//iomsg
               return
            endif
         elseif (word == 'sharpen') then
            ! gnuplot's sharpen: the extrema of a function found between its samples (data: ignored, as gnuplot)
            sharpen_item = is_function
         elseif (keyword(word, 'notitle', 3_I4P)) then
            title = ''
            has_title = .true.
            ! `notitle columnhead [N]`: no title, the first row still a header
            if (i < size(tokens, kind=I4P)) then
               if (keyword(tokens(i + 1_I4P)%text, 'columnheader', 3_I4P) .or. tokens(i + 1_I4P)%text == 'col') then
                  i = i + 1_I4P
                  head_skipped = .true.
                  if (i < size(tokens, kind=I4P)) then
                     if (verify(tokens(i + 1_I4P)%text, '0123456789') == 0) i = i + 1_I4P
                  endif
               endif
            endif
         elseif (is_word(word, 'noenhanced enhanced')) then
            ! the title as it is, or as enhanced text
            plain_item = word == 'noenhanced'
         elseif (word == 'ls' .or. keyword(word, 'linestyle', 5_I4P)) then
            ! a number or an expression (`ls (i+1)`), as gnuplot
            block
               real(R8P) :: v !< Style number.

               if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) then
                  iomsg = 'plot: ls: '//iomsg
                  return
               endif
               number = nint(v, I4P)
            endblock
            call apply_line_style(self%line_styles, number, line, self%figure%panels(self%figure%current)%linecolors)
         elseif ((word == 'ps' .or. keyword(word, 'pointsize', 6_I4P)) .and. i < size(tokens, kind=I4P) .and. &
                 is_word(tokens(min(i + 1_I4P, size(tokens, kind=I4P)))%text, 'var variable')) then
            ! gnuplot `ps variable`: each point's size from the column after the style's
            ps_var = .true.
            i = i + 1_I4P
         elseif ((word == 'pt' .or. keyword(word, 'pointtype', 6_I4P)) .and. i < size(tokens, kind=I4P) .and. &
                 is_word(tokens(min(i + 1_I4P, size(tokens, kind=I4P)))%text, 'var variable')) then
            ! gnuplot `pt variable`: each point's type from the column after the sizes' (`ps variable`)
            pt_var = .true.
            i = i + 1_I4P
         elseif (is_line_option(word)) then
            if (.not. (word == 'lc' .or. keyword(word, 'linecolor', 5_I4P) .or. word == 'lt' .or. &
                       keyword(word, 'linetype', 5_I4P))) shaping = word
            ! the linetype number, for boxplot factors in lc variable (`lt 51 lc variable`)
            if ((word == 'lt' .or. keyword(word, 'linetype', 5_I4P)) .and. i < size(tokens, kind=I4P)) then
               if (verify(tokens(i + 1_I4P)%text, '0123456789') == 0 .and. len(tokens(i + 1_I4P)%text) <= 6) &
                  read(tokens(i + 1_I4P)%text, *) item_lt
            endif
            if (.not. line_option(tokens, i, line, iostat, iomsg, self%figure%panels(self%figure%current)%linecolors, &
                                  self%symbols)) then
               iomsg = 'plot: '//iomsg
               return
            endif
            if (allocated(line%colormap)) then
               ! `lc palette NAME`: a colormap of `set colormap new NAME`
               if (self%colormap_index(line%colormap) == 0_I4P) then
                  call fail('plot: no colormap "'//line%colormap//'" (set colormap new NAME)', iostat, iomsg)
                  return
               endif
            endif
         elseif (word == 'tc' .or. keyword(word, 'textcolor', 5_I4P)) then
            ! the color of the character points (`pt "c"`), as gnuplot
            block
               character(len=64) :: color !< Color read.

               color = ''
               if (.not. self%text_color(tokens, i, color, iostat, iomsg)) then
                  iomsg = 'plot: '//iomsg
                  return
               endif
               point_tc = trim(color)
            endblock
         elseif (word == 'font') then
            ! the font of the item's labels (`with labels font ",8"`)
            if (.not. font_spec(self, tokens, i, item_font, iostat, iomsg)) then
               iomsg = 'plot: '//iomsg
               return
            endif
         elseif (word == 'volatile') then
            ! gnuplot's volatile (the data may change, for replot and the mouse): read and ignored
            continue
         elseif (keyword(word, 'noautoscale', 6_I4P)) then
            ! gnuplot `noautoscale` (`noauto`): the item out of the autoscaling
            item_noauto = .true.
         elseif (word == 'pixels' .and. (with == 'image' .or. with == 'rgbimage' .or. with == 'rgbalpha')) then
            ! gnuplot draws the image as a rectangle per pixel: foresight's images are drawn so anyway
            continue
         elseif (arrow_word(word)) then
            ! arrow words among the other options of vectors and arrows, as gnuplot (`with vectors lt 4 filled`)
            if (is_word(word, 'head heads nohead backhead filled empty nofilled')) then
               heads = heads//' '//word
            elseif (word == 'noborder') then
               heads = heads//' filled'
            elseif (word == 'size') then
               if (.not. head_size_option()) return
            elseif (word == 'as' .or. keyword(word, 'arrowstyle', 6_I4P)) then
               if (.not. item_arrow_style()) return
            endif
         elseif (splot_mode .and. (keyword(word, 'nocontours', 6_I4P) .or. word == 'nocontour')) then
            ! splot's: no contour lines of the item
            item_nocontours = .true.
         elseif (splot_mode .and. keyword(word, 'nosurface', 6_I4P)) then
            ! splot's: the item's contours only, its surface not drawn
            item_nosurface = .true.
         elseif (splot_mode .and. word == 'nogrid') then
            ! splot's: the item's data as they are, not gridded by set dgrid3d
            item_nogrid = .true.
         elseif (word == 'mask') then
            ! gnuplot's: the item (pm3d, image) drawn only inside the polygons of the `with mask` item
            item_mask = .true.
         else
            call fail('plot: unsupported option "'//word//'"', iostat, iomsg)
            return
         endif
         ! the data options right after the file are in its automatic title, as gnuplot's (df_open's tokens)
         if (.not. other_seen .and. (keyword(option_word, 'using', 1_I4P) .or. keyword(option_word, 'index', 1_I4P) &
                                     .or. keyword(option_word, 'every', 2_I4P) .or. &
                                     keyword(option_word, 'matrix', 3_I4P) .or. &
                                     keyword(option_word, 'nonuniform', 4_I4P) .or. option_word == 'skip')) then
            title_to = i
         else
            other_seen = .true.
         endif
         i = i + 1_I4P
      enddo
      if (with == 'pm3d' .and. .not. splot_mode) then
         call fail('plot: with pm3d draws the surfaces of splot', iostat, iomsg)
         return
      endif
      if (with == 'readout') then
         if (len(shaping) > 0) then
            call fail('plot: a readout takes lc only among the style options, not "'//shaping//'"', iostat, iomsg)
            return
         endif
         if (allocated(format)) then
            if (len(readout_check(format)) > 0) then
               call fail('plot: '//readout_check(format), iostat, iomsg)
               return
            endif
         endif
      elseif (allocated(format) .and. with /= 'gauge') then
         call fail('plot: format applies to readouts and gauges only', iostat, iomsg)
         return
      endif
      if (with == 'gauge') then
         if (allocated(format)) then
            if (len(readout_check(format)) > 0) then
               call fail('plot: '//readout_check(format), iostat, iomsg)
               return
            endif
         endif
         if (.not. allocated(gauge_scale)) then
            call fail('plot: a gauge needs its scale: with gauge range [A:B]', iostat, iomsg)
            return
         endif
      endif
      if (allocated(line%lc)) then
         ! labels take tc palette z (their colors from the last column), not one palette color
         ! parallel axes take lc palette z (a color per row, gnuplot's using Y:Z)
         if (index(line%lc, '*palette') == 1 .and. (is_word(with, 'readout gauge pie radar rose '// &
                                                                  'spiderplot image rgbimage rgbalpha') .or. &
                                                    (with == 'labels' .and. line%lc /= LC_PALETTE_Z) .or. &
                                                    (with == 'parallelaxes' .and. line%lc /= LC_PALETTE_Z))) then
            call fail('plot: lc palette does not apply to '//with, iostat, iomsg)
            return
         endif
      endif
      if (allocated(at_x) .and. with /= 'parallelaxes') then
         call fail('plot: at applies to parallelaxes only', iostat, iomsg)
         return
      endif
      associate(panel => self%figure%panels(self%figure%current))
         errorbars = with == 'histograms' .and. panel%histogram_mode == 3_I4P
         columns = with == 'histograms' .and. panel%histogram_mode == 2_I4P
      endassociate
      if (keyed .and. with /= 'spiderplot' .and. .not. columns) then
         call fail('plot: key(N) names the rows of a spider plot or of column stacked histograms', iostat, iomsg)
         return
      endif
      if (with == 'histograms' .and. .not. allocated(fs) .and. allocated(group_fs)) fs = group_fs
      if (allocated(whisker) .and. with /= 'candlesticks') then
         call fail('plot: whiskerbars applies to candlesticks only', iostat, iomsg)
         return
      endif
      ! filledcurves without options: those of `set style data|function filledcurves ...`, as gnuplot
      if (with == 'filledcurves' .and. len_trim(curve) == 0 .and. .not. allocated(base)) then
         block
            character(len=:), allocatable :: bad !< Problem (none: checked when set).

            if (is_function) then
               if (allocated(self%function_curve)) call filled_options(self%function_curve, curve, base, bad)
            else
               if (allocated(self%data_curve)) call filled_options(self%data_curve, curve, base, bad)
            endif
         endblock
      endif
      if (allocated(fs) .and. .not. is_word(with, 'boxes filledcurves histograms circles pie gauge radar rose '// &
                                            'boxerrorbars boxxyerror candlesticks boxplot ellipses polygons sectors '// &
                                            'fillsteps surface')) then
         call fail('plot: fs applies to boxes, filledcurves, histograms, circles, the box styles and the panel charts '// &
                   'only', iostat, iomsg)
         return
      endif
      associate(panel => self%figure%panels(self%figure%current))
         if (panel%polar) then
            polar_ok = is_word(with, 'lines points linespoints impulses yerrorbars labels filledcurves sectors readout '// &
                               'polygons surface') &
                       .and. &
                       (.not. allocated(base) .or. polar_base)
            if (allocated(axes)) polar_ok = polar_ok .and. axes == 'x1y1'
            if (.not. polar_ok) then
               call fail('plot: '//POLAR_STYLES, iostat, iomsg)
               return
            endif
            if (panel%xaxis%log .or. panel%yaxis%log) then
               call fail('plot: a polar panel has linear x and y axes (unset logscale)', iostat, iomsg)
               return
            endif
         endif
      endassociate
      grid_rows = 0_I4P
      if (splot_mode .and. is_function .and. .not. keyentry) then
         ! splot f(x,y): its iso-curves as generated rows x y, the function their third field, the expression its title
         if (.not. has_title .and. self%autotitle /= 'none') then
            title = item_glued//item_prefix//written
            auto_title = .true.
            has_title = .true.
         endif
         call function_rows(generated)
         if (iostat /= 0_I4P) return
         block
            character(len=:), allocatable :: names !< The two dummy variables.

            names = 'x y'
            if (len_trim(self%dummies) > 0) then
               if (word_count(self%dummies) >= 2) then
                  names = trim(first_word(self%dummies))//' '// &
                          trim(first_word(adjustl(self%dummies(index(adjustl(self%dummies), ' '):))))
               else
                  names = trim(first_word(self%dummies))//' y'
               endif
            endif
            spec = '1:2:('//written//')'
            if (len(para_fields) > 0) then
               ! parametric: the u, v grid, the three functions the fields
               names = 'u v'
               spec = para_fields
            endif
            using = 'using'
            sampled = names
            call parse_using(spec, fields, iostat, iomsg, self%figure%panels(self%figure%current)%degrees, &
                             self%symbols, sampled=names)
            if (iostat /= 0_I4P) then
               iomsg = 'splot: '//iomsg
               return
            endif
         endblock
         is_function = .false.
         pseudo = 3_I4P
         file = '++'
      endif
      if (is_function .and. with == 'table') then
         ! gnuplot writes nothing for a function, with a warning
         write(error_unit, '(A)') "foresight: warning: 'with table' requires a data source not a pure function"
         if (size(levels) > 0) then
            if (next_values()) then
               i = item_start
               cycle
            endif
            call iteration_end
         endif
         if (i > size(tokens, kind=I4P)) exit
         i = i + 1_I4P
         cycle
      endif
      if (is_function) then
         ! sampled at the end; gnuplot: the expression as written is the title
         if (.not. has_title .and. self%autotitle /= 'none' .and. .not. keyentry) then
            ! the expression as it is, not enhanced text
            title = item_glued//item_prefix//written
            auto_title = .true.
         endif
         palette_lc = ''
         if (allocated(line%lc)) then
            if (line%lc == LC_PALETTE_Z) then
               call fail('plot: lc palette z needs using x:y:z, not the function "'//written//'"', iostat, iomsg)
               return
            elseif (index(line%lc, '*palette') == 1) then
               palette_lc = line%lc
               deallocate(line%lc)
            endif
         endif
         if (with == 'boxes' .or. with == 'filledcurves') then
            ! gnuplot fills functions too: the boxes or the curve of the samples (a y=V base filled after sampling)
            if (allocated(fs)) then
               if (.not. fill_ok(fs)) return
            endif
            if (len(curve) > 0) then
               call above_below_base(curve, base, .false.)
               if ((index(curve, 'x') > 0 .or. index(curve, ' y') > 0) .and. allocated(base)) then
                  call fail('plot: filledcurves x1, x2, y1, y2, x=V, xy= fill to the plot, a line or a point: not '// &
                            'with y=V', iostat, iomsg)
                  return
               endif
               if ((index(curve, 'above') > 0 .or. index(curve, 'below') > 0) .and. .not. allocated(base)) then
                  call fail('plot: filledcurves above and below need y=V for a function', iostat, iomsg)
                  return
               endif
               call self%figure%plot([real(R8P) ::], [real(R8P) ::], title=title, with=with, lc=line%lc, &
                                     lw=line%lw, dt=line%dt, axes=axes, base=base, fs=fs, curve=curve)
            else
               call self%figure%plot([real(R8P) ::], [real(R8P) ::], title=title, with=with, lc=line%lc, &
                                     lw=line%lw, dt=line%dt, axes=axes, base=base, fs=fs)
            endif
         else
            call self%figure%plot([real(R8P) ::], [real(R8P) ::], title=title, with=with, lc=line%lc, lw=line%lw, &
                                  dt=line%dt, ps=line%ps, axes=axes, pt=line%pt)
         endif
         if (len(palette_lc) > 0) call paint_last
         call mark_last
         call fill_last
         call push(functions, func)
         sharpens = [sharpens, sharpen_item]
         if (self%parametric) call push(yfunctions, yfunc)
         if (allocated(base)) then
            own_base = [own_base, base]
         else
            own_base = [own_base, ieee_value(1.0_R8P, ieee_quiet_nan)]
         endif
         ! a plain reshape: through block temporaries and move_alloc, nvfortran 26.9 -O2 miscompiled plot_command
         ! (checks 85, 96, 124, 134, 147 and the keys golden failed)
         own_range = reshape([own_range, item_range], [2, size(functions)])
         own_set = reshape([own_set, item_set], [2, size(functions)])
         ! associate alias: see the gfortran 16 -fcheck=bounds workaround in foresight_figure
         associate(panel => self%figure%panels(self%figure%current))
            slots = [slots, size(panel%series, kind=I4P)]
         endassociate
         if (size(levels) > 0) then
            if (next_values()) then
               i = item_start
               cycle
            endif
            call iteration_end
         endif
         if (i > size(tokens, kind=I4P)) exit
         i = i + 1_I4P
         cycle
      endif
      ! data
      z_read = .false.
      one_column3d = .false.
      shown_spec = spec
      if (splot_mode) then
         call splot_columns
         if (iostat /= 0_I4P) return
      elseif (is_matrix .and. (allocated(fields) .or. .not. is_word(with, 'image rgbimage rgbalpha'))) then
         ! a matrix with using fields or another style than image: its rows x y z read as data, as gnuplot's
         call matrix_rows
         if (iostat /= 0_I4P) return
      endif
      if (is_matrix .and. with /= 'image') then
         if (with == 'rgbimage' .or. with == 'rgbalpha') then
            call fail('plot: '//with//' takes using x:y:r:g:b'//trim(merge(':a', '  ', with == 'rgbalpha'))// &
                      ', not a matrix', iostat, iomsg)
            return
         endif
         call fail('plot: matrix data are plotted with image', iostat, iomsg)
         return
      endif
      ! the text of labels (third using field, a plain column; 3 by default), read as the xtic labels are
      if (with == 'labels') then
         if (label_col > 0_I4P) then
            ! tic labels too (`using 0:1:(text):xticlabels(2)`, gnuplot's timedat): kept apart from the text
            tic_col = label_col
            tic_field = label_field
            label_col = 0_I4P
         endif
         if (.not. allocated(fields)) then
            label_col = 3_I4P
            call label_field%set_column(label_col)
         elseif (size(fields) >= 3_I4P + merge(1_I4P, 0_I4P, rotate_var) + merge(1_I4P, 0_I4P, ps_var) + &
                                   merge(1_I4P, 0_I4P, pt_var) + merge(1_I4P, 0_I4P, variable_lc() .or. palette_z_lc())) &
            then
            ! a column number (its text) or an expression: a string (`(sprintf(...))`, `(strcol(1))`), or a number
            ! written as the text of the first column it reads, as gnuplot; the rotation (`rotate variable`) and the
            ! color (tc variable) columns after it
            word = third_field(spec)
            if (word == '0' .or. word == '-1' .or. word == '-2') then
               ! a pseudo-column: its integer as the text, gnuplot's "label hack"
               label_col = 1_I4P
               call label_field%compile('sprintf("%d", int(column('//word//')))', iostat, iomsg)
               if (iostat /= 0_I4P) return
            elseif (len(word) > 0 .and. verify(word, '0123456789') == 0 .and. len(word) <= 9) then
               read(word, *) label_col
               call label_field%set_column(label_col)
            else
               label_col = 1_I4P
               label_field = fields(3)
            endif
            ! further columns read and ignored, as gnuplot (circles.dem's x:y:text:0)
            kept = [fields(1:2), fields(4:3_I4P + merge(1_I4P, 0_I4P, rotate_var) + merge(1_I4P, 0_I4P, ps_var) + &
                                             merge(1_I4P, 0_I4P, pt_var) + &
                                             merge(1_I4P, 0_I4P, variable_lc() .or. palette_z_lc()))]
            call move_alloc(kept, fields)
         else
            call fail('plot: labels needs using x:y:text_column', iostat, iomsg)
            return
         endif
      endif
      ! a boxplot factor (fourth using field): the text of a plain column, read as the xtic labels are
      if (with == 'boxplot' .and. allocated(fields)) then
         if (size(fields) == 4) then
            if (label_col > 0_I4P) then
               call fail('plot: a boxplot takes a factor column or xtic(), not both', iostat, iomsg)
               return
            endif
            word = trim(adjustl(spec(index(spec, ':', back=.true.) + 1:)))
            if (len(word) == 0 .or. verify(word, '0123456789') /= 0 .or. len(word) > 9) then
               call fail('plot: the boxplot factor (4th using field) must be a column number', iostat, iomsg)
               return
            endif
            read(word, *) label_col
            call label_field%set_column(label_col)
            kept = fields(1:3)
            call move_alloc(kept, fields)
         endif
      endif
      ! reloaded to keep the cell texts, for the labels and strcol
      time_axis(1) = merge(self%time_data(4), self%time_data(1), axes(2:2) == '2')
      time_axis(2) = merge(self%time_data(3), self%time_data(2), axes(4:4) == '2')
      needs_text = label_col > 0_I4P .or. any(time_axis) .or. with == 'table'
      if (allocated(fields)) needs_text = needs_text .or. any(fields%uses_text())
      if (pseudo > 0_I4P) then
         ! generated for each item: its rows follow the ranges and samples now
         block
            character(len=:), allocatable :: rows !< Generated rows.

            call pseudo_rows(rows)
            if (iostat /= 0_I4P) return
            call self%load_data(data, file, iostat, iomsg, keep_text=needs_text, content=rows)
            if (iostat /= 0_I4P) return
         endblock
         loaded = ''
      elseif (file /= loaded .or. (needs_text .and. .not. data%has_text) .or. skip /= loaded_skip) then
         call self%load_data(data, file, iostat, iomsg, keep_text=needs_text, skip=skip)
         if (iostat /= 0_I4P) return
         loaded = file
         loaded_skip = skip
         call self%register_file(file)
      endif
      if (with == 'table') then
         call table_item
         if (iostat /= 0_I4P) return
         if (size(levels) > 0) then
            if (next_values()) then
               i = item_start
               cycle
            endif
            call iteration_end
         endif
         if (i > size(tokens, kind=I4P)) exit
         i = i + 1_I4P
         cycle
      endif
      if (with == 'image' .or. with == 'rgbimage' .or. with == 'rgbalpha') then
         call image_item
         if (iostat /= 0_I4P) return
         associate(panel => self%figure%panels(self%figure%current))
            if (size(panel%series) > 0) panel%series(size(panel%series))%masked = item_mask
         endassociate
         if (i > size(tokens, kind=I4P)) exit
         i = i + 1_I4P
         cycle
      endif
      ! columns: gnuplot defaults are 1:2 (0:1 for one column), 1:2:3 for x/y error bars, 1:2:3:4 for xy error bars
      one_field = .false.
      weight_one = .false.
      if (binned .and. len(filter) > 0) then
         call fail('plot: bins and smooth '//filter//': not both', iostat, iomsg)
         return
      endif
      if (.not. allocated(fields)) then
         select case (with)
         case ('yerrorbars', 'xerrorbars', 'yerrorlines', 'xerrorlines')
            fields = plain_columns([1_I4P, 2_I4P, 3_I4P])
         case ('xyerrorbars', 'xyerrorlines', 'boxxyerror')
            fields = plain_columns([1_I4P, 2_I4P, 3_I4P, 4_I4P])
         case ('boxerrorbars')
            fields = plain_columns([1_I4P, 2_I4P, 3_I4P])
         case ('candlesticks', 'financebars')
            fields = plain_columns([1_I4P, 2_I4P, 3_I4P, 4_I4P, 5_I4P])
         case ('vectors', 'arrows', 'sectors')
            fields = plain_columns([1_I4P, 2_I4P, 3_I4P, 4_I4P])
         case ('histograms', 'pie', 'radar', 'rose', 'gauge', 'parallelaxes', 'spiderplot')
            ! one value per row: the first column at the point numbers
            fields = plain_columns([0_I4P, 1_I4P])
         case default
            call data%default_using(ux, uy)
            fields = plain_columns([ux, uy])
            ! a single column binned or smoothed by frequency or kdensity: x, each point of weight 1, as gnuplot
            weight_one = ux == 0_I4P .and. (binned .or. filter == 'frequency' .or. filter == 'kdensity')
         endselect
         one_field = is_word(with, 'histograms pie radar rose gauge parallelaxes spiderplot')
      elseif (size(fields) == 1) then
         one_field = .true.
         weight_one = binned .or. filter == 'frequency' .or. filter == 'kdensity'
         call point%set_column(0_I4P)
         kept = [point, fields(1)]
         call move_alloc(kept, fields)
      elseif ((with == 'histograms' .and. size(fields) == 2 .and. variable_lc()) .or. &
              (with == 'parallelaxes' .and. size(fields) == 2 .and. (variable_lc() .or. palette_z_lc()))) then
         ! histograms Y:COLOR with lc variable, at the point numbers
         call point%set_column(0_I4P)
         kept = [point, fields]
         call move_alloc(kept, fields)
      elseif (errorbars .and. (size(fields) == 2 .or. size(fields) == 3)) then
         ! errorbars histograms: Y:ERR or Y:LOW:HIGH, at the point numbers
         one_field = .true.
         call point%set_column(0_I4P)
         kept = [point, fields]
         call move_alloc(kept, fields)
      endif
      ! time data (gnuplot `set xdata time`): the x field and the y field read with the timefmt
      if (.not. one_field) then
         if (time_axis(1)) call fields(1)%set_time(self%timefmt)
         if (time_axis(2) .and. size(fields) >= 2) call fields(2)%set_time(self%timefmt)
      endif
      ! lc variable: the last field is the color column, out of the style's fields
      lcvar = .false.
      lcz = .false.
      if (allocated(line%lc)) then
         lcvar = line%lc == LC_VARIABLE .or. line%lc == LC_RGB_VARIABLE
         lcz = line%lc == LC_PALETTE_Z
      endif
      ! boxplot factors in lc variable: each box in the linetype of its factor index from the item's (gnuplot 6.0), no
      ! color column
      box_lcvar = .false.
      if (lcvar .and. with == 'boxplot' .and. label_col > 0_I4P) box_lcvar = line%lc == LC_VARIABLE
      if (box_lcvar) then
         lcvar = .false.
         deallocate(line%lc)
      endif
      if (lcvar .or. lcz) then
         word = trim(merge('lc palette z', 'lc variable ', lcz))
         if (.not. is_word(with, 'lines points linespoints impulses vectors arrows circles ellipses boxes '// &
                           'candlesticks financebars boxxyerror boxerrorbars histograms filledcurves polygons '// &
                           'xerrorbars yerrorbars xyerrorbars xerrorlines yerrorlines xyerrorlines labels '// &
                           'parallelaxes pm3d')) then
            call fail('plot: '//word//' applies to lines, points, linespoints, impulses, vectors, arrows, circles, '// &
                      'ellipses, boxes, boxerrorbars, boxxyerror, candlesticks, financebars, histograms, filledcurves, '// &
                      'polygons, the error bars, parallel axes and labels (tc variable), not to '//with, iostat, iomsg)
            return
         endif
         if (one_field .or. size(fields) < 3) then
            call fail('plot: '//word//' needs using x:y:'//trim(merge('z    ', 'color', lcz)), iostat, iomsg)
            return
         endif
         if (len(filter) > 0 .or. binned) then
            call fail('plot: '//word//' does not go with smooth nor bins', iostat, iomsg)
            return
         endif
      endif
      nbar = size(fields, kind=I4P) - 2_I4P - merge(1_I4P, 0_I4P, lcvar .or. lcz) - merge(1_I4P, 0_I4P, ps_var) - &
             merge(1_I4P, 0_I4P, pt_var)
      if (binned .and. nbar /= 0_I4P) then
         call fail('plot: bins need using X or X:Y', iostat, iomsg)
         return
      endif
      select case (with)
      case ('yerrorbars', 'xerrorbars', 'yerrorlines', 'xerrorlines')
         if (nbar /= 1_I4P .and. nbar /= 2_I4P) then
            call fail('plot: '//with//' needs using x:y:delta or x:y:low:high', iostat, iomsg)
            return
         endif
      case ('xyerrorbars', 'xyerrorlines')
         if (nbar /= 2_I4P .and. nbar /= 4_I4P) then
            call fail('plot: '//with//' needs using x:y:dx:dy or x:y:xlow:xhigh:ylow:yhigh', iostat, iomsg)
            return
         endif
      case ('histograms', 'pie', 'radar', 'rose', 'parallelaxes', 'spiderplot')
         if (.not. (one_field .or. (with == 'histograms' .and. lcvar .and. nbar == 0_I4P) .or. &
                    (with == 'parallelaxes' .and. (lcvar .or. lcz) .and. nbar == 0_I4P))) then
            call fail('plot: '//with//' needs using Y or Y:xtic(N) (the rows are the point numbers)', iostat, iomsg)
            return
         endif
      case ('boxerrorbars')
         if (nbar < 1_I4P .or. nbar > 3_I4P) then
            call fail('plot: boxerrorbars needs using x:y:ydelta[:width] or x:y:ylow:yhigh:width', iostat, iomsg)
            return
         endif
      case ('boxxyerror')
         if (nbar /= 2_I4P .and. nbar /= 4_I4P) then
            call fail('plot: boxxyerror needs using x:y:xdelta:ydelta or x:y:xlow:xhigh:ylow:yhigh', iostat, iomsg)
            return
         endif
      case ('candlesticks', 'financebars')
         if (nbar /= 3_I4P .and. .not. (nbar == 4_I4P .and. with == 'candlesticks')) then
            call fail('plot: '//with//' needs using x:open:low:high:close'// &
                      trim(merge('[:width]', '        ', with == 'candlesticks')), iostat, iomsg)
            return
         endif
      case ('vectors', 'arrows')
         if (arrow_var .and. (lcvar .or. lcz)) then
            call fail('plot: arrowstyle variable takes the colors of the arrow styles (no lc variable nor palette)', &
                      iostat, iomsg)
            return
         endif
         if (arrow_var .and. nbar /= 3_I4P .and. nbar /= 4_I4P) then
            call fail('plot: '//with//' arrowstyle variable needs using x:y:'// &
                      trim(merge('xdelta:ydelta', 'length:angle ', with == 'vectors'))//':style[:z]', iostat, iomsg)
            return
         elseif (.not. arrow_var .and. nbar /= 2_I4P) then
            call fail('plot: '//with//' needs using x:y:'//trim(merge('xdelta:ydelta', 'length:angle ', with == 'vectors')), &
                      iostat, iomsg)
            return
         endif
      case ('ellipses')
         if (nbar > 3_I4P) then
            call fail('plot: ellipses needs using x:y[:diameter|:major:minor[:angle]]', iostat, iomsg)
            return
         endif
      case ('sectors')
         if (nbar /= 2_I4P .and. nbar /= 4_I4P) then
            call fail('plot: sectors needs using azimuth:radius:angle:width[:x0:y0]', iostat, iomsg)
            return
         endif
      case ('surface')
         ! gnuplot's polar gridded surface: theta:r:z, polar only
         if (.not. self%figure%panels(self%figure%current)%polar) then
            call fail('plot: with surface needs set polar (gnuplot: for non-polar gridded surfaces use splot)', &
                      iostat, iomsg)
            return
         endif
         if (nbar /= 1_I4P) then
            call fail('plot: surface needs using theta:r:z', iostat, iomsg)
            return
         endif
      case ('polygons', 'labels')
         if (nbar /= merge(1_I4P, 0_I4P, rotate_var .and. with == 'labels')) then
            call fail('plot: '//with//' needs using x:y'//trim(merge(':text_column', '            ', with == 'labels')), &
                      iostat, iomsg)
            return
         endif
      case ('boxplot')
         if (nbar > 1_I4P .or. one_field) then
            call fail('plot: boxplot needs using x:y[:width[:factor column]]', iostat, iomsg)
            return
         endif
      case ('circles')
         if (nbar /= 0_I4P .and. nbar /= 1_I4P .and. nbar /= 3_I4P) then
            call fail('plot: circles needs using x:y, x:y:radius or x:y:radius:start:end', iostat, iomsg)
            return
         endif
      case ('boxes')
         if (nbar > 1_I4P) then
            call fail('plot: boxes needs using x:y or x:y:width', iostat, iomsg)
            return
         endif
      case ('filledcurves')
         if (nbar > 1_I4P) then
            call fail('plot: filledcurves needs using x:y or x:y1:y2', iostat, iomsg)
            return
         endif
         if (nbar == 1_I4P .and. self%figure%panels(self%figure%current)%polar) then
            call fail('plot: '//POLAR_STYLES, iostat, iomsg)
            return
         endif
         if (nbar == 1_I4P .and. allocated(base)) then
            call fail('plot: filledcurves y=V fills to a line, a band x:y1:y2 between two curves: not both', &
                      iostat, iomsg)
            return
         endif
      case default
         ! smooth acsplines: X:Y:WEIGHT, the weights read by the smoothing; polar theta:r:z data (gnuplot's polar grid
         ! demos) drawn as points or lines, the z ignored as gnuplot
         if (nbar /= 0_I4P .and. .not. (nbar == 1_I4P .and. filter == 'acsplines') .and. .not. (nbar == 1_I4P .and. &
             self%figure%panels(self%figure%current)%polar .and. is_word(with, 'points lines linespoints')) .and. &
             .not. (nbar == 1_I4P .and. zsort_item)) then
            call fail('plot: '//with//' needs using X:Y or Y', iostat, iomsg)
            return
         endif
      endselect
      ! a band x:y1:y2 of filledcurves takes the curve filters (each curve smoothed on the same samples), as gnuplot
      band_smooth = with == 'filledcurves' .and. nbar == 1_I4P .and. is_word(filter, CURVE_MODES) .and. &
                    filter /= 'acsplines'
      if (len(filter) > 0 .and. nbar /= 0_I4P .and. .not. (nbar == 1_I4P .and. filter == 'acsplines') .and. &
          .not. band_smooth) then
         call fail('plot: smooth applies to lines, points and linespoints, not to '//with, iostat, iomsg)
         return
      endif
      if (.not. has_title) then
         select case (self%autotitle)
         case ('columnhead')
            title_column = 0_I4P
         case ('file')
            ! gnuplot: the item as written, '' included, as it is (not enhanced text)
            call item_auto_title(text, tokens(item_first)%first, tokens(item_first)%last, tokens(title_to)%last, &
                                 written, quote, shown_spec, using, title)
            title = item_glued//title
            auto_title = .true.
         endselect
      endif
      ! the first row of each dataset is a header as soon as one is used, as gnuplot
      headed = title_column >= 0_I4P .or. self%autotitle == 'columnhead' .or. any(fields%name_count() > 0_I4P) .or. &
               self%column_headers .or. head_skipped
      if (headed) then
         missing = data%missing_name(fields, set_index)
         if (len(missing) > 0) then
            call fail('plot: no column with header "'//missing//'" in "'//file//'"', iostat, iomsg)
            return
         endif
         if (title_column >= 0_I4P) then
            title = header_title(max(0_I4P, set_index))
            if (head_piece(1) > 0_I4P) &
               title = title(min(head_piece(1), len(title, kind=I4P) + 1_I4P):min(head_piece(2), len(title, kind=I4P)))
         endif
      endif
      if (label_col > 0_I4P) then
         if (label_col2 > 0_I4P) &
            call data%table(fields, set_index, every, values, header=headed, labels=labels2, label=label_field2)
         if (tic_col > 0_I4P) &
            call data%table(fields, set_index, every, values, header=headed, labels=ticlabels, label=tic_field)
         if (z_read) then
            call data%table([fields, zfield], set_index, every, values, header=headed, labels=xlabels, &
                            label=label_field, sets=row_sets)
         else
            call data%table(fields, set_index, every, values, header=headed, labels=xlabels, label=label_field)
         endif
      else
         if (z_read) then
            call data%table([fields, zfield], set_index, every, values, header=headed, sets=row_sets)
         else
            call data%table(fields, set_index, every, values, header=headed)
         endif
         if (allocated(xlabels)) deallocate(xlabels)
      endif
      if (z_read) then
         ! the heights apart, the other columns the plot's
         ! a plain reassignment: nvfortran 26.9 broke the values of every plot (2D too) after a move_alloc into them
         ! in a block here
         z3 = values(:, size(values, 2))
         values = values(:, 1:size(values, 2) - 1)
         if (one_column3d) call scan_numbers(values, row_sets)
      endif
      if (weight_one) then
         values(:, 1) = values(:, 2)
         values(:, 2) = 1.0_R8P
      endif
      ! pt variable: the types column (the last, or before the color one) out of the values: gnuplot's int(v), a dot
      ! for 0 and less
      if (pt_var .and. size(values, 2) >= 3) then
         block
            integer(I4P)              :: c    !< Types column.
            integer(I4P), allocatable :: rest(:) !< The other columns.
            integer(I4P)              :: k    !< Column counter.

            c = size(values, 2, kind=I4P) - merge(1_I4P, 0_I4P, lcvar .or. lcz)
            allocate(point_types(size(values, 1)))
            do k = 1_I4P, size(values, 1, kind=I4P)
               point_types(k) = 0_I4P
               if (ieee_is_finite(values(k, c))) then
                  if (abs(values(k, c)) < 1.0e9_R8P) point_types(k) = max(0_I4P, int(values(k, c), I4P))
               endif
            enddo
            rest = pack([(k, k = 1_I4P, size(values, 2, kind=I4P))], [(k /= c, k = 1_I4P, size(values, 2, kind=I4P))])
            values = values(:, rest)
         endblock
      endif
      ! ps variable: the sizes column (the last, or before the color one) out of the values
      if (ps_var .and. size(values, 2) >= 3) then
         block
            integer(I4P)              :: c    !< Sizes column.
            integer(I4P), allocatable :: rest(:) !< The other columns.
            integer(I4P)              :: k    !< Column counter.

            c = size(values, 2, kind=I4P) - merge(1_I4P, 0_I4P, lcvar .or. lcz)
            point_sizes = values(:, c)
            rest = pack([(k, k = 1_I4P, size(values, 2, kind=I4P))], [(k /= c, k = 1_I4P, size(values, 2, kind=I4P))])
            values = values(:, rest)
         endblock
      endif
      if (hull > 0_I4P) call hull_filter
      if (zsort_item) call zsort_filter
      if (with == 'surface') call surface_grid
      x = values(:, 1)
      y = values(:, 2)
      ! gnuplot `set link x2|y2`: values on the linked axis plotted on the first one (through `inverse`)
      associate(panel => self%figure%panels(self%figure%current))
         if (axes(1:2) == 'x2' .and. panel%link_x2) then
            if (panel%link_x2_via) then
               block
                  integer(I4P) :: r !< Row.

                  do r = 1_I4P, size(x, kind=I4P)
                     x(r) = panel%link_maps(2)%value_at(x(r))
                  enddo
               endblock
            endif
            axes(1:2) = 'x1'
         endif
         if (axes(3:4) == 'y2' .and. panel%link_y2) then
            if (panel%link_y2_via) then
               block
                  integer(I4P) :: r !< Row.

                  do r = 1_I4P, size(y, kind=I4P)
                     y(r) = panel%link_maps(4)%value_at(y(r))
                  enddo
               endblock
            endif
            axes(3:4) = 'y1'
         endif
      endassociate
      if (lcvar) call variable_colors(values(:, size(values, 2)), line%lc == LC_RGB_VARIABLE)
      if (arrow_var) then
         ! the style column, and the palette value of the styles with lc palette z
         arrow_tags = values(:, 5)
         if (size(values, 2) >= 6) then
            arrow_z = values(:, 6)
         else
            if (allocated(arrow_z)) deallocate(arrow_z)
            allocate(arrow_z(size(values, 1)))
            arrow_z = ieee_value(1.0_R8P, ieee_quiet_nan)
         endif
      endif
      if (with == 'labels' .and. rotate_var) label_rotations = values(:, 3)
      if (lcz) then
         ! a row with an undefined field is no point for gnuplot: nor a palette value of the color axis
         zcolors = values(:, size(values, 2))
         block
            integer(I4P) :: r !< Row.

            do r = 1_I4P, size(values, 1, kind=I4P)
               if (.not. all(ieee_is_finite(values(r, :)))) zcolors(r) = ieee_value(1.0_R8P, ieee_quiet_nan)
            enddo
         endblock
      endif
      ! lc palette: the series gets its palette colors once added (paint_last); no SVG color meanwhile
      palette_lc = ''
      if (allocated(line%lc)) then
         if (index(line%lc, '*palette') == 1) then
            palette_lc = line%lc
            deallocate(line%lc)
         endif
      endif
      if (binned) then
         ! associate alias: see the gfortran 16 -fcheck=bounds workaround in foresight_figure
         associate(panel => self%figure%panels(self%figure%current))
            call bin_values(values(:, 1), values(:, 2), nbins, binrange(1), binrange(2), binwidth, binavg, &
                            merge(panel%x2axis%log, panel%xaxis%log, axes(1:2) == 'x2'), &
                            merge(panel%y2axis%log, panel%yaxis%log, axes(3:4) == 'y2'), x, y, bin_edges, word)
         endassociate
         if (len(word) > 0) then
            call fail('plot: bins: '//word, iostat, iomsg)
            return
         endif
      elseif (is_word(filter, CURVE_MODES)) then
         call curve_filter
         if (iostat /= 0_I4P) return
      elseif (filter == 'path') then
         call path_filter
      elseif (len(filter) > 0) then
         ! associate alias: see the gfortran 16 -fcheck=bounds workaround in foresight_figure
         associate(panel => self%figure%panels(self%figure%current))
            call smooth(filter, values(:, 1), values(:, 2), merge(panel%x2axis%log, panel%xaxis%log, axes(1:2) == 'x2'), &
                        merge(panel%y2axis%log, panel%yaxis%log, axes(3:4) == 'y2'), x, y)
         endassociate
      endif
      if (allocated(xlow)) deallocate(xlow, xhigh)
      if (allocated(ylow)) deallocate(ylow)
      if (allocated(yhigh)) deallocate(yhigh)
      if (allocated(widths)) deallocate(widths)
      select case (with)
      case ('boxes')
         if (nbar == 1_I4P) widths = values(:, 3)
      case ('circles')
         if (nbar >= 1_I4P) widths = values(:, 3)
         if (allocated(arcs)) deallocate(arcs)
         if (nbar == 3_I4P) arcs = transpose(values(:, 4:5))
      case ('filledcurves')
         if (nbar == 1_I4P) ylow = values(:, 3)
         if (band_smooth .and. allocated(band_low)) ylow = band_low
      case ('histograms')
         if (errorbars .and. nbar == 1_I4P) then
            ylow = y - values(:, 3)
            yhigh = y + values(:, 3)
         elseif (errorbars .and. nbar == 2_I4P) then
            ylow = values(:, 3)
            yhigh = values(:, 4)
         elseif (errorbars) then
            call fail('plot: errorbars histograms need using Y:ERR or Y:LOW:HIGH', iostat, iomsg)
            return
         endif
      case ('boxerrorbars')
         if (nbar == 3_I4P) then
            ylow = values(:, 3)
            yhigh = values(:, 4)
            widths = values(:, 5)
         else
            ylow = y - values(:, 3)
            yhigh = y + values(:, 3)
            if (nbar == 2_I4P) widths = values(:, 4)
         endif
         ! a width <= 0 means the boxwidth, as gnuplot
         if (allocated(widths)) where (.not. widths > 0.0_R8P) widths = ieee_value(1.0_R8P, ieee_quiet_nan)
      case ('boxxyerror')
         if (nbar == 2_I4P) then
            xlow = x - values(:, 3)
            xhigh = x + values(:, 3)
            ylow = y - values(:, 4)
            yhigh = y + values(:, 4)
         else
            xlow = values(:, 3)
            xhigh = values(:, 4)
            ylow = values(:, 5)
            yhigh = values(:, 6)
         endif
      case ('candlesticks', 'financebars')
         ylow = values(:, 3)
         yhigh = values(:, 4)
         closes = values(:, 5)
         if (nbar == 4_I4P) widths = values(:, 6)
      case ('boxplot')
         if (nbar >= 1_I4P) widths = values(:, 3)
      case ('vectors', 'arrows')
         xlow = values(:, 3)
         xhigh = values(:, 4)
      case ('ellipses')
         if (nbar >= 1_I4P) xlow = values(:, 3)
         if (nbar == 1_I4P) xhigh = values(:, 3)
         if (nbar >= 2_I4P) xhigh = values(:, 4)
         if (nbar == 3_I4P) ylow = values(:, 5)
      case ('sectors')
         xlow = values(:, 3)
         xhigh = values(:, 4)
         if (nbar == 4_I4P) then
            if (allocated(arcs)) deallocate(arcs)
            arcs = transpose(values(:, 5:6))
         endif
      case ('yerrorbars', 'yerrorlines')
         if (nbar == 1_I4P) then
            ylow = y - values(:, 3)
            yhigh = y + values(:, 3)
         else
            ylow = values(:, 3)
            yhigh = values(:, 4)
         endif
      case ('xerrorbars', 'xerrorlines')
         if (nbar == 1_I4P) then
            xlow = x - values(:, 3)
            xhigh = x + values(:, 3)
         else
            xlow = values(:, 3)
            xhigh = values(:, 4)
         endif
      case ('xyerrorbars', 'xyerrorlines')
         if (nbar == 2_I4P) then
            xlow = x - values(:, 3)
            xhigh = x + values(:, 3)
            ylow = y - values(:, 4)
            yhigh = y + values(:, 4)
         else
            xlow = values(:, 3)
            xhigh = values(:, 4)
            ylow = values(:, 5)
            yhigh = values(:, 6)
         endif
      endselect
      ! unallocated optional arguments are absent: gnuplot defaults apply
      ! the panel charts are alone in their panel: several gauges or radars side by side, one pie or rose
      associate(panel => self%figure%panels(self%figure%current))
         if (allocated(panel%series)) then
            if (size(panel%series) > 0) then
               if (is_word(with, 'pie gauge radar rose parallelaxes spiderplot') .or. &
                   any(panel%series(1)%style%with == [WITH_PIE, WITH_GAUGE, WITH_RADAR, WITH_ROSE, WITH_PARALLELAXES, &
                                                       WITH_SPIDERPLOT])) then
                  if (with == 'pie' .or. with == 'rose' .or. panel%series(1)%style%with /= style_code(with)) then
                     call fail('plot: a pie, gauge, radar, rose, parallel axis or spider plot is alone in its panel '// &
                               '(several gauges, radars or axes side by side)', iostat, iomsg)
                     return
                  endif
               endif
            endif
         endif
      endassociate
      if (with == 'pie' .or. with == 'rose') then
         if (any(y < 0.0_R8P)) then
            call fail('plot: a '//with//' needs non-negative values', iostat, iomsg)
            return
         endif
      endif
      if (with == 'readout') then
         ! a line style may carry widths and sizes: a readout keeps its color only
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, format=format)
      elseif (with == 'circles') then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         if (lcvar) deallocate(line%lc)
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, axes=axes, fs=fs, &
                               xlabels=xlabels, radius=widths, angles=arcs)
         if (lcvar) call color_last
      elseif (with == 'pie') then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         call self%figure%plot(x, y, title=title, with=with, fs=fs, xlabels=xlabels, donut=hole)
      elseif (with == 'gauge') then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         if (cells > 0_I4P) then
            if (.not. allocated(fs)) fs = 'solid'
            fs = fs//' segments '//int_str(int(cells, I8P))
         endif
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, fs=fs, format=format, scale=gauge_scale)
      elseif (with == 'radar' .or. with == 'rose') then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, fs=fs, xlabels=xlabels, &
                               linear=rose_linear)
      elseif (with == 'boxerrorbars' .or. with == 'boxxyerror') then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         if (lcvar) deallocate(line%lc)
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, xlow=xlow, &
                               xhigh=xhigh, ylow=ylow, yhigh=yhigh, axes=axes, width=widths, fs=fs, xlabels=xlabels)
         if (lcvar) call color_last
      elseif (with == 'candlesticks' .or. with == 'financebars') then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         if (lcvar) deallocate(line%lc)
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, ylow=ylow, &
                               yhigh=yhigh, close=closes, axes=axes, width=widths, fs=fs, xlabels=xlabels, &
                               whiskerbars=whisker)
         if (lcvar) call color_last
      elseif (with == 'vectors') then
         if (lcvar) deallocate(line%lc)
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, axes=axes, dx=xlow, &
                               dy=xhigh, head=heads, xlabels=xlabels)
         call head_last
         if (lcvar) call color_last
         if (arrow_var) call arrow_styles_last
      elseif (with == 'arrows') then
         if (lcvar) deallocate(line%lc)
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, axes=axes, &
                               length=xlow, angle=xhigh, head=heads, xlabels=xlabels)
         call head_last
         if (lcvar) call color_last
         if (arrow_var) call arrow_styles_last
      elseif (with == 'ellipses' .or. with == 'polygons') then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         if (lcvar) deallocate(line%lc)
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, axes=axes, fs=fs, &
                               major=xlow, minor=xhigh, angle=ylow)
         if (lcvar) call color_last
      elseif (with == 'sectors') then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         if (nbar == 4_I4P) then
            call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, axes=axes, fs=fs, &
                                  angle=xlow, width=xhigh, origins=arcs)
         else
            call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, axes=axes, fs=fs, &
                                  angle=xlow, width=xhigh)
         endif
      elseif (with == 'labels') then
         if (lcvar) deallocate(line%lc)
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, ps=line%ps, pt=line%pt, &
                               axes=axes, labels=xlabels, label=label_opts)
         if (lcvar) call color_last
         if (tic_col > 0_I4P .and. allocated(ticlabels)) then
            associate(panel => self%figure%panels(self%figure%current))
               if (size(ticlabels) == size(panel%series(size(panel%series))%x)) then
                  allocate(panel%series(size(panel%series))%xlabels(size(ticlabels)))
                  panel%series(size(panel%series))%xlabels = ticlabels
               endif
            endassociate
         endif
         if (rotate_var) then
            associate(panel => self%figure%panels(self%figure%current))
               panel%series(size(panel%series))%text_rotations = label_rotations
            endassociate
         endif
      elseif (with == 'parallelaxes' .or. with == 'spiderplot') then
         if (keyed .and. with == 'parallelaxes') then
            call fail('plot: key(N) names the rows of a spider plot', iostat, iomsg)
            return
         endif
         if (label_col > 0_I4P .and. .not. keyed) then
            call fail('plot: '//with//' takes key(N), not xtic(N)', iostat, iomsg)
            return
         endif
         ! gnuplot 6.0 reads one row of an array in a spider plot (spiderplot.dem's `Array1 using (Array1[i])`)
         if (with == 'spiderplot' .and. self%symbols%is_array(file) .and. size(x) > 1) then
            x = x(1:1)
            y = y(1:1)
         endif
         ! lc variable of parallel axes: a color per row (gnuplot's using Y:COLOR)
         if (lcvar) deallocate(line%lc)
         if (keyed) then
            call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, labels=xlabels, &
                                  at=at_x)
         else
            call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, at=at_x)
         endif
         if (lcvar) call color_last
      elseif (with == 'boxplot') then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         if (label_col > 0_I4P) then
            call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, ps=line%ps, &
                                  axes=axes, width=widths, fs=fs, factors=xlabels)
            if (box_lcvar) then
               associate(panel => self%figure%panels(self%figure%current))
                  block
                     integer(I4P) :: last !< The boxplot series.
                     integer(I4P) :: base !< Linetype of the first factor.
                     integer(I4P) :: k    !< Factor counter.
                     integer(I4P) :: nf   !< Distinct factors.
                     integer(I4P) :: j    !< Earlier label counter.
                     logical      :: seen !< A label met before.

                     ! the factors are the distinct labels in their order of appearance (the boxes, made later)
                     nf = 0_I4P
                     do k = 1_I4P, size(xlabels, kind=I4P)
                        seen = .false.
                        do j = 1_I4P, k - 1_I4P
                           if (xlabels(j) == xlabels(k)) then
                              seen = .true.
                              exit
                           endif
                        enddo
                        if (.not. seen) nf = nf + 1_I4P
                     enddo
                     last = size(panel%series, kind=I4P)
                     base = last + panel%color_shift
                     if (item_lt > 0_I4P) base = item_lt
                     if (allocated(panel%series(last)%colors)) deallocate(panel%series(last)%colors)
                     allocate(panel%series(last)%colors(nf))
                     do k = 1_I4P, nf
                        panel%series(last)%colors(k) = default_color(base + k - 1_I4P, &
                                                                     self%figure%panels(self%figure%current)%linecolors)
                     enddo
                     if (nf > 0_I4P) panel%series(last)%style%color = trim(panel%series(last)%colors(1))
                  endblock
               endassociate
            endif
         else
            call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, ps=line%ps, &
                                  axes=axes, width=widths, fs=fs)
         endif
      elseif (with == 'filledcurves' .and. len(curve) > 0) then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         call above_below_base(curve, base, allocated(ylow))
         ! the library stops on these: a script fails gracefully
         if ((index(curve, 'x') > 0 .or. index(curve, ' y') > 0) .and. (allocated(base) .or. allocated(ylow))) then
            call fail('plot: filledcurves x1, x2, y1, y2, x=V, xy= fill to the plot, a line or a point: not with y=V '// &
                      'nor a band', iostat, iomsg)
            return
         endif
         if ((index(curve, 'above') > 0 .or. index(curve, 'below') > 0) .and. &
             (index(curve, ' y') > 0 .or. index(curve, 'x=') > 0 .or. index(curve, 'x1=') > 0 .or. &
              index(curve, 'x2=') > 0)) then
            call fail('plot: filledcurves above and below apply to y=V and bands', iostat, iomsg)
            return
         endif
         if ((index(curve, 'above') > 0 .or. index(curve, 'below') > 0) .and. &
             .not. (allocated(base) .or. allocated(ylow))) then
            call fail('plot: filledcurves above and below need y=V or a band x:y1:y2', iostat, iomsg)
            return
         endif
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, ylow=ylow, axes=axes, &
                               base=base, fs=fs, xlabels=xlabels, curve=curve)
      elseif (with == 'histograms' .and. columns) then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         if (lcvar) deallocate(line%lc)
         ! a column stack: the rows named by key(N) in the key; titled by columnhead, the stack's x tick label
         if (is_head .and. len(title) > 0) then
            block
               character(len=:), allocatable :: heads(:) !< The stack label on its first row.

               allocate(character(len=len(title)) :: heads(size(x)))
               heads(:) = ''
               if (size(x) > 0) heads(1) = title
               if (keyed) then
                  call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, axes=axes, &
                                        fs=fs, xlabels=heads, labels=xlabels)
               else
                  call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, axes=axes, &
                                        fs=fs, xlabels=heads)
               endif
            endblock
         elseif (keyed) then
            call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, axes=axes, fs=fs, &
                                  labels=xlabels)
         else
            call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, axes=axes, fs=fs)
         endif
         if (lcvar) call color_last
      elseif (with == 'boxes' .or. with == 'filledcurves' .or. with == 'histograms') then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         if (lcvar) deallocate(line%lc)
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, ylow=ylow, axes=axes, &
                               width=widths, base=base, fs=fs, xlabels=xlabels, yhigh=yhigh)
         if (lcvar) call color_last
      elseif (lcvar) then
         ! the key sample and the default color of the item: its own, not the marker
         deallocate(line%lc)
         call self%figure%plot(x, y, title=title, with=with, lw=line%lw, dt=line%dt, ps=line%ps, xlow=xlow, &
                               xhigh=xhigh, ylow=ylow, yhigh=yhigh, axes=axes, pt=line%pt, xlabels=xlabels, &
                               colors=point_colors)
      else
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, ps=line%ps, &
                               xlow=xlow, xhigh=xhigh, ylow=ylow, yhigh=yhigh, axes=axes, pt=line%pt, xlabels=xlabels)
      endif
      if (len(palette_lc) > 0) call paint_last
      call mark_last
      call fill_last
      if (z_read) call attach_z(z3, row_sets)
      if (binned) then
         ! the autoscale spans the outer bin edges and y = 0, as gnuplot
         associate(panel => self%figure%panels(self%figure%current))
            panel%series(size(panel%series))%spanned = .true.
            panel%series(size(panel%series))%span = [bin_edges(1), bin_edges(2), 0.0_R8P, 0.0_R8P]
         endassociate
      endif
      ! `for [i=A:*]`: the first item without a valid point ends the iteration, and is not drawn (gnuplot)
      if (size(levels) > 0) then
         if (any(levels%forever)) then
            if (.not. self%figure%panels(self%figure%current)%last_drawable()) then
               call self%figure%panels(self%figure%current)%drop_last
               call iteration_end
               if (i > size(tokens, kind=I4P)) exit
               i = i + 1_I4P
               cycle
            endif
         endif
      endif
      if (size(levels) > 0) then
         if (next_values()) then
            i = item_start
            cycle
         endif
         call iteration_end
      endif
      if (i > size(tokens, kind=I4P)) exit
      i = i + 1_I4P
   enddo
   if (size(functions) > 0) then
      call sample_functions
      ! the `filledcurves y=V` base of the filled functions, one per sample
      block
         integer(I4P) :: k !< Function.

         do k = 1_I4P, size(functions, kind=I4P)
            if (ieee_is_nan(own_base(k))) cycle
            associate(series => self%figure%panels(self%figure%current)%series(slots(k)))
               if (allocated(series%x)) then
                  if (allocated(series%ylow)) deallocate(series%ylow)
                  allocate(series%ylow(size(series%x)))
                  series%ylow = own_base(k)
               endif
            endassociate
         enddo
      endblock
   endif
   if (self%table) then
      ! `set table`: the points as text, nothing drawn
      call self%write_table(iostat, iomsg)
      return
   endif
   if (splot_mode .and. .not. self%figure%panels(self%figure%current)%view3d%map) then
      call fail('splot: 3D views are not drawn yet (foresight 3D support, phase 2): set view map draws the map view', &
                iostat, iomsg)
      return
   endif
   if (self%multiplot) self%advance_pending = .true.
   ! a multiplot on the standard output is printed once, complete, at unset multiplot (as gnuplot); files are rewritten
   ! at each plot, so that a watched page shows the panels done so far
   if (self%multiplot .and. self%output == '-') return
   call self%save_output(iostat, iomsg)
   contains
      subroutine splot_columns
      !< splot's using fields made plot's: the third, z, apart in `zfield` (read after the others as the last column,
      !< `z_read`), the others the style's plot fields in their order, `spec` rewritten so (labels read their text field
      !< from it). gnuplot's defaults: 1:2:3 (1:2:3:4 labels, 1:2:3:4:5:6 vectors); a single data column is z, x and y the
      !< point and scan numbers (`scan_numbers`); `with image` takes x:y:value (z 0) or x:y:z:value; the z delta of
      !< vectors is read and ignored (a map view). A matrix becomes rows x y z (`matrix_rows`), but a `matrix with image`
      !< without using stays plot's image of a matrix. `lc palette` colors by z unless a column follows the plot fields.
      character(len=:), allocatable        :: parts(:) !< The fields as written.
      character(len=:), allocatable        :: zspec    !< The z field as written.
      character(len=:), allocatable        :: rest     !< The plot fields.
      type(expression_object), allocatable :: zfields(:) !< The z field parsed.
      integer(I4P)                         :: n        !< Fields.
      integer(I4P)                         :: needed   !< Plot fields of the style with a color column.
      integer(I4P)                         :: k        !< Field counter.
      logical                              :: image_style !< An image style.

      image_style = with == 'image' .or. with == 'rgbimage' .or. with == 'rgbalpha'
      if (len(filter) > 0 .or. binned .or. hull > 0_I4P .or. zsort_item) then
         call fail('splot: smooth, bins, hulls and zsort apply to plot', iostat, iomsg)
         return
      endif
      if (is_matrix) then
         if (image_style .and. .not. allocated(fields)) return
         call matrix_rows
         if (iostat /= 0_I4P) return
      endif
      if (.not. allocated(fields)) then
         ux = 1_I4P
         if (pseudo == 0_I4P) then
            ! the columns of the data
            call self%load_data(data, file, iostat, iomsg, skip=skip)
            if (iostat /= 0_I4P) return
            loaded = file
            loaded_skip = skip
            call self%register_file(file)
            call data%default_using(ux, uy)
         endif
         if (ux == 0_I4P) then
            one_column3d = .true.
            spec = '1:1:1'
         else
            select case (with)
            case ('labels')
               spec = '1:2:3:4'
            case ('vectors')
               spec = '1:2:3:4:5:6'
            case default
               spec = '1:2:3'
            endselect
         endif
      endif
      call using_parts(spec, parts)
      n = size(parts, kind=I4P)
      if (with == 'image' .and. n == 3_I4P) then
         zspec = '(0)'
         rest = trim(parts(1))//':'//trim(parts(2))//':'//trim(parts(3))
      elseif (n < 3_I4P) then
         call fail('splot: using needs x:y:z, found "'//spec//'"', iostat, iomsg)
         return
      else
         zspec = trim(parts(3))
         rest = trim(parts(1))//':'//trim(parts(2))
         do k = 4_I4P, n
            ! the z delta of vectors (the sixth field) is the 3D view's
            if (with == 'vectors' .and. k == 6_I4P) cycle
            rest = rest//':'//trim(parts(k))
         enddo
      endif
      ! pm3d: a fourth field is the color of the points (gnuplot's color from a column), read as lc palette z's
      if (with == 'pm3d' .and. n >= 4_I4P .and. .not. allocated(line%lc)) line%lc = LC_PALETTE_Z
      ! lc palette (z): the z as the color column, unless the item gives one after its plot fields
      if (allocated(line%lc)) then
         if (line%lc == LC_PALETTE_Z) then
            needed = 3_I4P + merge(1_I4P, 0_I4P, ps_var) + merge(1_I4P, 0_I4P, pt_var) + &
                     merge(1_I4P, 0_I4P, with == 'labels') + &
                     merge(1_I4P, 0_I4P, rotate_var) + merge(2_I4P, 0_I4P, with == 'vectors')
            if (word_count(replace_colons(rest)) < needed) rest = rest//':'//zspec
         endif
      endif
      spec = rest
      if (len(sampled) > 0 .and. pseudo /= 4_I4P) then
         call parse_using(spec, fields, iostat, iomsg, self%figure%panels(self%figure%current)%degrees, self%symbols, &
                          sampled=sampled)
         if (iostat == 0_I4P) call parse_using(zspec, zfields, iostat, iomsg, &
                                               self%figure%panels(self%figure%current)%degrees, self%symbols, &
                                               sampled=sampled)
      else
         call parse_using(spec, fields, iostat, iomsg, self%figure%panels(self%figure%current)%degrees, self%symbols)
         if (iostat == 0_I4P) call parse_using(zspec, zfields, iostat, iomsg, &
                                               self%figure%panels(self%figure%current)%degrees, self%symbols)
      endif
      if (iostat /= 0_I4P) then
         iomsg = 'splot: '//iomsg
         return
      endif
      if (image_style) return
      zfield = zfields(1)
      z_read = .true.
      endsubroutine splot_columns

      subroutine matrix_rows
      !< A splot matrix as generated rows `x y z`, a block per matrix row (gnuplot's scans): x the column number and y
      !< the row number from 0, or (`nonuniform`) the first row and column of the file.
      real(R8P),        allocatable :: zm(:,:) !< The matrix (column, row).
      character(len=:), allocatable :: problem !< Matrix problem.
      character(len=:), allocatable :: buffer  !< Rows.
      integer(I4P)                  :: used    !< Its length used.
      integer(I4P)                  :: c       !< Column.
      integer(I4P)                  :: r       !< Row.
      integer(I4P)                  :: c0      !< First value column.
      real(R8P)                     :: xv      !< Abscissa.
      real(R8P)                     :: yv      !< Ordinate.

      call self%load_data(data, file, iostat, iomsg, skip=skip)
      if (iostat /= 0_I4P) return
      loaded = file
      loaded_skip = skip
      call self%register_file(file)
      call data%matrix(set_index, zm, problem)
      if (len(problem) > 0) then
         call fail('splot: '//problem//' in "'//file//'"', iostat, iomsg)
         return
      endif
      if (size(zm) == 0) then
         call fail('splot: no values in "'//file//'"', iostat, iomsg)
         return
      endif
      if (any(every /= [1_I4P, 1_I4P, 0_I4P, 0_I4P, -1_I4P, -1_I4P])) then
         call fail('splot: every on a matrix is not supported', iostat, iomsg)
         return
      endif
      c0 = merge(2_I4P, 1_I4P, nonuniform)
      used = 0_I4P
      do r = c0, size(zm, 2, kind=I4P)
         yv = real(r - 1_I4P, R8P)
         if (nonuniform) yv = zm(1, r)
         do c = c0, size(zm, 1, kind=I4P)
            xv = real(c - 1_I4P, R8P)
            if (nonuniform) xv = zm(c, 1)
            call append_text(buffer, used, gnuplot_real(xv)//' '//gnuplot_real(yv)//' '//gnuplot_real(zm(c, r))// &
                             new_line('a'))
         enddo
         call append_text(buffer, used, new_line('a'))
      enddo
      generated = ''
      if (used > 0_I4P) generated = buffer(1:used)
      is_matrix = .false.
      pseudo = 4_I4P
      loaded = ''
      endsubroutine matrix_rows

      subroutine function_rows(rows)
      !< The rows of a splot function, as gnuplot 6.0 samples it (plot3d.c, calculate_set_of_isolines): `set isosamples
      !< N1,N2` iso-curves of y (N2 of them, `set samples` S1 points along x each) then N1 iso-curves of x (S2 points
      !< along y each), over the x and y ranges (inline, set, the data so far when autoscaled, [-10:10] without); the
      !< columns x and y, a blank line after each curve. The first N2 curves are the surface grid (`grid_rows`).
      character(len=:), allocatable, intent(out) :: rows   !< Rows.
      character(len=:), allocatable              :: buffer !< Rows being built.
      integer(I4P)                               :: used   !< Its length used.
      real(R8P)                                  :: lo(2)  !< Range starts, x and y.
      real(R8P)                                  :: hi(2)  !< Range ends.
      real(R8P)                                  :: u      !< x sample.
      real(R8P)                                  :: v      !< y sample.
      integer(I4P)                               :: j      !< Curve counter.
      integer(I4P)                               :: k      !< Sample counter.

      call surface_range(1_I4P, lo(1), hi(1))
      call surface_range(2_I4P, lo(2), hi(2))
      ! gnuplot's samples, min + i step with the step computed first, written to the last bit
      used = 0_I4P
      do j = 0_I4P, self%isosamples - 1_I4P
         v = lo(2) + real(j, R8P) * ((hi(2) - lo(2)) / real(self%isosamples - 1_I4P, R8P))
         do k = 0_I4P, self%samples - 1_I4P
            u = lo(1) + real(k, R8P) * ((hi(1) - lo(1)) / real(self%samples - 1_I4P, R8P))
            call append_text(buffer, used, exact_real(u)//' '//exact_real(v)//new_line('a'))
         enddo
         call append_text(buffer, used, new_line('a'))
      enddo
      do j = 0_I4P, self%isosamples1 - 1_I4P
         u = lo(1) + real(j, R8P) * ((hi(1) - lo(1)) / real(self%isosamples1 - 1_I4P, R8P))
         do k = 0_I4P, self%samples2 - 1_I4P
            v = lo(2) + real(k, R8P) * ((hi(2) - lo(2)) / real(self%samples2 - 1_I4P, R8P))
            call append_text(buffer, used, exact_real(u)//' '//exact_real(v)//new_line('a'))
         enddo
         call append_text(buffer, used, new_line('a'))
      enddo
      rows = buffer(1:used)
      grid_rows = self%isosamples
      endsubroutine function_rows

      subroutine surface_range(axis, lo, hi)
      !< The sampling range of a splot function along x (`axis` 1) or y (2): the plot's inline range, else the set one,
      !< else the data so far, else [-10:10], as gnuplot.
      integer(I4P), intent(in)  :: axis !< 1 x, 2 y.
      real(R8P),    intent(out) :: lo   !< Start.
      real(R8P),    intent(out) :: hi   !< End.
      real(R8P)                 :: x0(2), x1(2), y0(2), y1(2) !< Data extent.
      logical                   :: found(2), xfound(2)        !< Any data.

      if (self%parametric) then
         ! the u and v ranges of the parametric surfaces
         lo = self%uv_range(1, axis)
         hi = self%uv_range(2, axis)
         return
      endif
      associate(panel => self%figure%panels(self%figure%current))
         call panel%axes_extent(x0, x1, y0, y1, found, xfound)
         lo = -10.0_R8P
         hi = 10.0_R8P
         if (axis == 1_I4P) then
            if (xfound(1)) then
               lo = x0(1)
               hi = x1(1)
            endif
            if (panel%xaxis%min_fixed) lo = panel%xaxis%min_user
            if (panel%xaxis%max_fixed) hi = panel%xaxis%max_user
            if (panel%xaxis%plot_min_fixed) lo = panel%xaxis%plot_min
            if (panel%xaxis%plot_max_fixed) hi = panel%xaxis%plot_max
         else
            if (found(1)) then
               lo = y0(1)
               hi = y1(1)
            endif
            if (panel%yaxis%min_fixed) lo = panel%yaxis%min_user
            if (panel%yaxis%max_fixed) hi = panel%yaxis%max_user
            if (panel%yaxis%plot_min_fixed) lo = panel%yaxis%plot_min
            if (panel%yaxis%plot_max_fixed) hi = panel%yaxis%plot_max
         endif
      endassociate
      endsubroutine surface_range

      subroutine scan_numbers(rows, marks)
      !< One data column: x the point number within its scan, y the scan number within its dataset (gnuplot's).
      real(R8P),    intent(inout) :: rows(:,:) !< Rows, x and y set.
      integer(I4P), intent(in)    :: marks(:)  !< Dataset of each row, -1 at the breaks.
      integer(I4P) :: r    !< Row.
      integer(I4P) :: p    !< Point within the scan.
      integer(I4P) :: sc   !< Scan within the dataset.
      integer(I4P) :: last !< Dataset of the last point.

      p = 0_I4P
      sc = 0_I4P
      last = -2_I4P
      do r = 1_I4P, size(rows, 1, kind=I4P)
         if (marks(r) < 0_I4P) then
            sc = sc + 1_I4P
            p = 0_I4P
            cycle
         endif
         if (marks(r) /= last) then
            sc = 0_I4P
            p = 0_I4P
            last = marks(r)
         endif
         rows(r, 1) = real(p, R8P)
         rows(r, 2) = real(sc, R8P)
         p = p + 1_I4P
      enddo
      endsubroutine scan_numbers

      subroutine attach_z(heights, marks)
      !< The heights and scans of the splot item, on its series: the scans are the runs of points between the breaks,
      !< each in its dataset; a function's first `grid_rows` scans its grid.
      real(R8P),    intent(in) :: heights(:) !< Heights.
      integer(I4P), intent(in) :: marks(:)   !< Dataset of each row, -1 at the breaks.
      integer(I4P)              :: last  !< The item's series.
      integer(I4P)              :: n     !< Scans.
      integer(I4P)              :: r     !< Row.
      integer(I4P), allocatable :: bounds(:,:) !< Scans: first and last point.
      integer(I4P), allocatable :: sets(:)     !< Their datasets.

      allocate(bounds(2, size(heights)), sets(size(heights)))
      n = 0_I4P
      do r = 1_I4P, size(heights, kind=I4P)
         if (marks(r) < 0_I4P) cycle
         if (r == 1_I4P) then
            n = n + 1_I4P
            bounds(1, n) = r
            sets(n) = marks(r)
         elseif (marks(r - 1_I4P) < 0_I4P) then
            n = n + 1_I4P
            bounds(1, n) = r
            sets(n) = marks(r)
         endif
         bounds(2, n) = r
      enddo
      associate(panel => self%figure%panels(self%figure%current))
         last = size(panel%series, kind=I4P)
         if (last == 0_I4P) return
         if (size(panel%series(last)%x) /= size(heights)) return
         call set_heights(panel%series(last), heights, bounds(:, 1:n), sets(1:n), &
                          merge(grid_rows, n, grid_rows > 0_I4P .and. grid_rows <= n), pseudo /= 3_I4P)
         panel%series(last)%no_contours = item_nocontours
         panel%series(last)%no_surface = item_nosurface
         ! set dgrid3d: the data (not a function's samples) gridded, gnuplot's grid_nongrid_data
         ! a mask is never gridded (gnuplot's opt_out_of_dgrid3d)
         if (panel%dgrid3d%on .and. pseudo /= 3_I4P .and. .not. item_nogrid .and. &
             panel%series(last)%style%with /= WITH_MASK) call grid_series(panel%series(last), panel%dgrid3d)
      endassociate
      endsubroutine attach_z

      subroutine table_item
      !< A data item `with table`: its rows written now as text where `set table` sends them (gnuplot's layout).
      type(expression_object), allocatable :: used(:)  !< `using` fields, none for the leading numeric cells.
      character(len=:), allocatable        :: lines    !< Rows written.
      character(len=:), allocatable        :: old      !< Datablock before.
      logical                              :: found    !< Datablock found.
      integer(I4P)                         :: unit     !< File unit.

      if (allocated(fields)) then
         used = fields
      else
         allocate(used(0))
      endif
      if (has_table_if) then
         call data%table_lines(used, set_index, every, any(used%name_count() > 0_I4P), self%table_sep, &
                               is_datablock(self%table_file), lines, condition=table_if)
      else
         call data%table_lines(used, set_index, every, any(used%name_count() > 0_I4P), self%table_sep, &
                               is_datablock(self%table_file), lines)
      endif
      if (is_datablock(self%table_file)) then
         call self%symbols%string_of(self%table_file, old, found)
         if (.not. found) old = ''
         call self%symbols%set_string(self%table_file, old//lines)
      elseif (len(lines) == 0) then
         return
      elseif (self%table_file == '-') then
         write(output_unit, '(A)') lines(1:len(lines) - 1)
      else
         open(newunit=unit, file=self%table_file, position='append', action='write', iostat=iostat)
         if (iostat /= 0_I4P) then
            call fail('set table: cannot write "'//self%table_file//'"', iostat, iomsg)
            return
         endif
         write(unit, '(A)') lines(1:len(lines) - 1)
         close(unit)
      endif
      endsubroutine table_item

      subroutine iteration_start
      !< The `for [...]` clauses before the item at `i`: their values, the loop variables set to the first ones, `i` the
      !< first token of the item. No value in a clause: `skip_item`.
      type(loop_level), allocatable :: grown(:) !< Levels, one more.
      type(loop_level)              :: level    !< New level.
      integer(I4P)                  :: n        !< Levels.
      integer(I4P)                  :: k        !< Counter.

      skip_item = .false.
      do while (i < size(tokens, kind=I4P))
         if (tokens(i)%kind /= TOKEN_WORD) exit
         if (tokens(i)%text /= 'for') exit
         if (tokens(i + 1_I4P)%kind /= TOKEN_RANGE) exit
         do k = 1_I4P, size(levels, kind=I4P)
            if (mentions(tokens(i + 1_I4P)%text, levels(k)%name)) then
               call fail('plot: for ['//tokens(i + 1_I4P)%text//']: bounds depending on the outer variable '// &
                         levels(k)%name//' are not supported in a plot (they are in do for)', iostat, iomsg)
               return
            endif
         enddo
         ! gnuplot `for [i=A:*]`, an unbounded iteration of a data item: up to FOREVER values, ended by the first
         ! item without a valid point
         level%forever = .false.
         block
            character(len=:), allocatable :: parts(:) !< Range ends.
            character(len=:), allocatable :: clause   !< Clause, `*` replaced.
            integer(I4P)                  :: e        !< `=`.

            clause = tokens(i + 1_I4P)%text
            e = index(clause, '=', kind=I4P)
            if (e > 0_I4P .and. index(clause, ' in ') == 0) then
               call split_range(clause(e + 1_I4P:), parts)
               if (size(parts) >= 2) then
                  if (trim(adjustl(parts(2))) == '*' .and. trim(adjustl(parts(1))) /= '*') then
                     level%forever = .true.
                     clause = clause(1:e)//trim(parts(1))//':('//trim(parts(1))//')+'//int_str(int(FOREVER - 1, I8P))
                     if (size(parts) == 3) clause = clause//':'//trim(parts(3))
                  endif
               endif
            endif
            call for_values(self, clause, level%name, level%values, level%words, iostat, iomsg)
         endblock
         if (iostat /= 0_I4P) then
            iomsg = 'plot: for ['//tokens(i + 1_I4P)%text//']: '//iomsg
            return
         endif
         call self%symbols%save_variable(level%name, level%saved)
         level%pos = 1_I4P
         if (size(level%values) == 0) skip_item = .true.
         n = size(levels, kind=I4P)
         allocate(grown(n + 1_I4P))
         do k = 1_I4P, n
            grown(k) = levels(k)
         enddo
         grown(n + 1_I4P) = level
         call move_alloc(grown, levels)
         i = i + 2_I4P
      enddo
      if (size(levels) == 0) return
      if (skip_item) then
         call iteration_end
         return
      endif
      if (i > size(tokens, kind=I4P)) then
         call fail('plot: for [...]: an item is expected', iostat, iomsg)
         return
      endif
      do k = 1_I4P, size(levels, kind=I4P)
         call set_loop_variable(self, levels(k)%name, levels(k)%values(1)%text, levels(k)%words)
      enddo
      item_start = i
      endsubroutine iteration_start

      function next_values() result(more)
      !< Advance the clauses to their next values, the last clause first; false when all are done.
      logical      :: more !< Values left.
      integer(I4P) :: k    !< Clause.

      more = .false.
      k = size(levels, kind=I4P)
      do while (k >= 1_I4P)
         if (levels(k)%pos < size(levels(k)%values, kind=I4P)) then
            levels(k)%pos = levels(k)%pos + 1_I4P
            call set_loop_variable(self, levels(k)%name, levels(k)%values(levels(k)%pos)%text, levels(k)%words)
            more = .true.
            return
         endif
         levels(k)%pos = 1_I4P
         call set_loop_variable(self, levels(k)%name, levels(k)%values(1)%text, levels(k)%words)
         k = k - 1_I4P
      enddo
      endfunction next_values

      subroutine iteration_end
      !< Restore the loop variables (the innermost first) and forget the clauses.
      integer(I4P) :: k !< Clause.

      do k = size(levels, kind=I4P), 1_I4P, -1_I4P
         call self%symbols%restore(levels(k)%saved)
      enddo
      deallocate(levels)
      allocate(levels(0))
      endsubroutine iteration_end

      function gauge_range(token) result(ok)
      !< The gauge scale of the range token `[A:B]`, both ends numbers; fails the plot if not.
      type(token_object), intent(in) :: token !< Range token.
      logical                        :: ok    !< Read.
      real(R8P)                      :: v(2)  !< Ends.
      integer(I4P)                   :: colon !< Separator position.

      ok = .false.
      colon = index(token%text, ':', kind=I4P)
      if (token%kind /= TOKEN_RANGE .or. colon == 0_I4P) then
         call fail('plot: gauge range needs [A:B], found "'//token%text//'"', iostat, iomsg)
         return
      endif
      if (.not. (to_number(trim(adjustl(token%text(1:colon - 1_I4P))), v(1)) .and. &
                 to_number(trim(adjustl(token%text(colon + 1_I4P:))), v(2)))) then
         call fail('plot: gauge range needs two numbers [A:B], found "['//token%text//']"', iostat, iomsg)
         return
      endif
      if (v(1) == v(2)) then
         call fail('plot: the gauge range ends must differ', iostat, iomsg)
         return
      endif
      gauge_scale = v
      ok = .true.
      endfunction gauge_range

      function label_option() result(ok)
      !< The label option at `tokens(i)` into `label_opts`, leaving `i` on its last token; fails the plot if malformed.
      logical :: ok !< Parsed.

      ok = .false.
      select case (tokens(i)%text)
      case ('rotate')
         ! `rotate variable`: each label by the angle of its fourth using field, as gnuplot
         if (i < size(tokens, kind=I4P)) then
            if (keyword(tokens(i + 1_I4P)%text, 'variable', 3_I4P)) then
               i = i + 1_I4P
               rotate_var = .true.
               ok = .true.
               return
            endif
         endif
         if (i + 2_I4P > size(tokens, kind=I4P)) then
            call fail('plot: labels rotate by A expected', iostat, iomsg)
            return
         endif
         label_opts = label_opts//' rotate '//tokens(i + 1_I4P)%text//' '//tokens(i + 2_I4P)%text
         i = i + 2_I4P
      case ('offset')
         if (i < size(tokens, kind=I4P)) then
            if (keyword(tokens(i + 1_I4P)%text, 'character', 4_I4P)) i = i + 1_I4P
         endif
         if (i + 1_I4P > size(tokens, kind=I4P)) then
            call fail('plot: labels offset X,Y expected', iostat, iomsg)
            return
         endif
         ! `offset X` alone: Y 0, as gnuplot
         single_offset = .true.
         if (i + 3_I4P <= size(tokens, kind=I4P)) single_offset = tokens(i + 2_I4P)%kind /= TOKEN_COMMA
         if (single_offset) then
            label_opts = label_opts//' offset '//tokens(i + 1_I4P)%text//',0'
            i = i + 1_I4P
         else
            label_opts = label_opts//' offset '//tokens(i + 1_I4P)%text//','//tokens(i + 3_I4P)%text
            i = i + 3_I4P
         endif
      case ('tc', 'textcolor')
         block
            logical :: rgb !< `rgb` given.

            rgb = .false.
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%text == 'rgb') then
                  i = i + 1_I4P
                  rgb = .true.
               endif
            endif
            ! `tc [rgb] variable`: each label in the color of the last using column, as lc variable (gnuplot)
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%kind == TOKEN_WORD .and. keyword(tokens(i + 1_I4P)%text, 'variable', 3_I4P)) then
                  i = i + 1_I4P
                  line%lc = trim(merge(LC_RGB_VARIABLE, LC_VARIABLE, rgb))
                  ok = .true.
                  return
               endif
               ! `tc palette [z]`: each label in the palette color of the last using column
               if (tokens(i + 1_I4P)%kind == TOKEN_WORD .and. keyword(tokens(i + 1_I4P)%text, 'palette', 3_I4P) .and. &
                   .not. rgb) then
                  i = i + 1_I4P
                  if (i < size(tokens, kind=I4P)) then
                     if (tokens(i + 1_I4P)%text == 'z') i = i + 1_I4P
                  endif
                  line%lc = trim(LC_PALETTE_Z)
                  ok = .true.
                  return
               endif
            endif
         endblock
         if (i >= size(tokens, kind=I4P)) then
            call fail('plot: labels tc "color" expected', iostat, iomsg)
            return
         endif
         if (tokens(i + 1_I4P)%kind /= TOKEN_STRING) then
            call fail('plot: labels tc "color" expected', iostat, iomsg)
            return
         endif
         label_opts = label_opts//' tc "'//tokens(i + 1_I4P)%text//'"'
         i = i + 1_I4P
      case ('boxed')
         ! in text box style 0, or `bs N`: drawn when the style is opaque or has a border (gnuplot's svg)
         block
            integer(I4P) :: bs !< Text box style.

            bs = 0_I4P
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%text == 'bs') then
                  i = i + 1_I4P
                  if (.not. next_integer(tokens, i, bs, iostat, iomsg, self%symbols)) return
                  if (bs < 0_I4P .or. bs > size(self%textbox_drawn, kind=I4P) - 1_I4P) then
                     call fail('plot: labels boxed bs N: N from 0 to '// &
                               int_str(int(size(self%textbox_drawn) - 1, I8P)), iostat, iomsg)
                     return
                  endif
               endif
            endif
            if (self%textbox_drawn(bs)) label_opts = label_opts//' boxed'
         endblock
      case default
         label_opts = label_opts//' '//tokens(i)%text
      endselect
      ok = .true.
      endfunction label_option

      function next_number(v) result(ok)
      !< The number token after `i` into `v`, advancing `i`; fails the plot if there is none.
      real(R8P), intent(out) :: v  !< Number.
      logical                :: ok !< Read.

      ok = .false.
      v = 0.0_R8P
      i = i + 1_I4P
      if (i > size(tokens, kind=I4P)) then
         call fail('plot: a number is expected after "'//tokens(i - 1_I4P)%text//'"', iostat, iomsg)
         return
      endif
      if (.not. to_number(tokens(i)%text, v)) then
         call fail('plot: a number is expected, found "'//tokens(i)%text//'"', iostat, iomsg)
         return
      endif
      ok = .true.
      endfunction next_number

      function variable_lc() result(yes)
      !< Whether the item's line color is `lc [rgb] variable`.
      logical :: yes !< The color column marker.

      yes = .false.
      if (allocated(line%lc)) yes = line%lc == LC_VARIABLE .or. line%lc == LC_RGB_VARIABLE
      endfunction variable_lc

      subroutine fill_last
      !< The fill color of the item (`fc`) on its series; a filledcurves fill border where gnuplot 6.0 draws it: around
      !< the key sample, and along a closed curve.
      associate(panel => self%figure%panels(self%figure%current))
         if (with == 'filledcurves') panel%series(size(panel%series))%fill_edges = 1_I4P
         if (allocated(fill_rgb)) then
            panel%series(size(panel%series))%style%fill_rgb = fill_rgb
            ! the item's border in its fill color too, unless `fs border lc` gives one (gnuplot 6.0: fc over lc)
            if (.not. allocated(panel%series(size(panel%series))%style%border_color)) then
               panel%series(size(panel%series))%style%border_color = fill_rgb
            elseif (len(panel%series(size(panel%series))%style%border_color) == 0) then
               panel%series(size(panel%series))%style%border_color = fill_rgb
            endif
         endif
      endassociate
      endsubroutine fill_last

      pure function third_field(text) result(field)
      !< The third field of a `using` specification (fields apart at the `:` outside parentheses and quotes).
      character(len=*), intent(in)  :: text  !< Specification.
      character(len=:), allocatable :: field !< Third field, trimmed.
      character(len=1)              :: quote !< Open quote, blank if none.
      integer(I4P)                  :: depth !< Parenthesis depth.
      integer(I4P)                  :: f     !< Field counter.
      integer(I4P)                  :: start !< Field start.
      integer(I4P)                  :: c     !< Character counter.

      field = ''
      quote = ' '
      depth = 0_I4P
      f = 1_I4P
      start = 1_I4P
      do c = 1_I4P, len(text, kind=I4P)
         if (quote /= ' ') then
            if (text(c:c) == quote) quote = ' '
         elseif (text(c:c) == '"' .or. text(c:c) == "'") then
            quote = text(c:c)
         elseif (text(c:c) == '(') then
            depth = depth + 1_I4P
         elseif (text(c:c) == ')') then
            depth = depth - 1_I4P
         elseif (text(c:c) == ':' .and. depth == 0_I4P) then
            if (f == 3_I4P) then
               field = trim(adjustl(text(start:c - 1_I4P)))
               return
            endif
            f = f + 1_I4P
            start = c + 1_I4P
         endif
      enddo
      if (f == 3_I4P) field = trim(adjustl(text(start:)))
      endfunction third_field

      function palette_z_lc() result(yes)
      !< Whether the item's color is `lc|tc palette z`.
      logical :: yes !< Palette color by the last column.

      yes = .false.
      if (allocated(line%lc)) yes = line%lc == LC_PALETTE_Z
      endfunction palette_z_lc

      subroutine arrow_styles_last
      !< `arrowstyle variable` of the vectors or arrows just added: each arrow the heads, fill, head size, width and
      !< color of the arrow style its column names (`set style arrow N`), a style of `lc palette z` the palette color
      !< of its z column; a style not defined leaves the arrow the item's own, as the key sample.
      integer(I4P) :: last  !< Series just added.
      integer(I4P) :: k     !< Arrow counter.
      integer(I4P) :: j     !< Style counter.
      integer(I4P) :: n     !< Arrows.
      logical      :: paint !< A style of lc palette z.

      associate(panel => self%figure%panels(self%figure%current))
         last = size(panel%series, kind=I4P)
         associate(series => panel%series(last))
            n = size(series%x, kind=I4P)
            if (size(arrow_tags) /= n) return
            allocate(series%arrow_heads(n), series%arrow_filled(n), series%arrow_widths(n), series%arrow_sizes(2, n), &
                     series%arrow_systems(n), series%colors(n))
            allocate(series%zvalues(n))
            series%zvalues = ieee_value(1.0_R8P, ieee_quiet_nan)
            paint = .false.
            do k = 1_I4P, n
               series%arrow_heads(k) = series%head
               series%arrow_filled(k) = series%head_filled
               series%arrow_widths(k) = series%style%linewidth
               series%arrow_sizes(:, k) = series%head_size
               series%arrow_systems(k) = series%head_system
               series%colors(k) = series%style%color
               if (.not. allocated(self%arrow_styles) .or. .not. ieee_is_finite(arrow_tags(k))) cycle
               do j = 1_I4P, size(self%arrow_styles, kind=I4P)
                  if (real(self%arrow_styles(j)%tag, R8P) /= arrow_tags(k)) cycle
                  associate(style => self%arrow_styles(j))
                     series%arrow_heads(k) = style%head
                     series%arrow_filled(k) = any(trim(style%fill) == ['filled  ', 'noborder'])
                     series%arrow_widths(k) = style%lw
                     series%arrow_sizes(:, k) = 0.0_R8P
                     if (style%length > 0.0_R8P) then
                        series%arrow_sizes(:, k) = [style%length, style%angle]
                        series%arrow_systems(k) = style%length_system
                     endif
                     if (allocated(style%color)) then
                        if (style%color == LC_PALETTE_Z) then
                           series%zvalues(k) = arrow_z(k)
                           paint = .true.
                        elseif (len(style%color) > 0 .and. style%color(1:1) /= '*') then
                           series%colors(k) = style%color
                        endif
                     endif
                  endassociate
                  exit
               enddo
            enddo
            ! the arrows of palette colors colored with the color axis (the others keep theirs)
            if (paint) then
               series%palette_mode = 1_I4P
            else
               deallocate(series%zvalues)
            endif
         endassociate
      endassociate
      endsubroutine arrow_styles_last

      function arrow_word(word) result(yes)
      !< Whether `word` is an arrow option of an item drawn with vectors or arrows.
      character(len=*), intent(in) :: word !< Option.
      logical                      :: yes  !< An arrow option.

      yes = .false.
      if (.not. allocated(with)) return
      if (.not. (with == 'vectors' .or. with == 'arrows')) return
      yes = is_word(word, 'head heads nohead backhead filled empty nofilled noborder fixed size as') .or. &
            keyword(word, 'arrowstyle', 6_I4P)
      endfunction arrow_word

      subroutine head_last
      !< The head size of the vectors or arrows just added (`size L,A`).
      associate(panel => self%figure%panels(self%figure%current))
         associate(last => panel%series(size(panel%series)))
            last%head_size = item_head
            last%head_system = item_head_system
         endassociate
      endassociate
      endsubroutine head_last

      function head_size_option() result(ok)
      !< `size [first|graph|screen|character] L,A[,B]` of vectors and arrows (token `i` is `size`): the head length in
      !< the system (x axis values by default) and its angle [deg]; the back angle B is read and ignored.
      logical                       :: ok    !< Success.
      real(R8P)                     :: v     !< Number.
      integer(I4P)                  :: k     !< Number counter.
      character(len=:), allocatable :: piece !< Number text.

      ok = .false.
      item_head_system = 'first'
      if (i < size(tokens, kind=I4P)) then
         if (is_word(tokens(i + 1_I4P)%text, 'first graph screen character')) then
            i = i + 1_I4P
            item_head_system = tokens(i)%text
         endif
      endif
      do k = 1_I4P, 3_I4P
         if (k > 1_I4P) then
            ! a comma, then a number: the next value (not the next item)
            if (i + 1_I4P >= size(tokens, kind=I4P)) exit
            if (tokens(i + 1_I4P)%kind /= TOKEN_COMMA) exit
            if (tokens(i + 2_I4P)%kind /= TOKEN_WORD) exit
            if (verify(tokens(i + 2_I4P)%text(1:1), '0123456789.+-') /= 0) exit
            i = i + 1_I4P
         endif
         if (i >= size(tokens, kind=I4P)) then
            call fail('plot: size [first|graph|screen|character] LENGTH,ANGLE expected', iostat, iomsg)
            return
         endif
         i = i + 1_I4P
         piece = tokens(i)%text
         call self%symbols%constant(piece, v, iostat, iomsg, degrees=self%figure%panels(self%figure%current)%degrees)
         if (iostat /= 0_I4P) then
            iomsg = 'plot: size: '//iomsg
            return
         endif
         if (k == 1_I4P) item_head(1) = abs(v)
         if (k == 2_I4P) item_head(2) = v
      enddo
      if (item_head(2) == 0.0_R8P) item_head(2) = 15.0_R8P
      ok = .true.
      endfunction head_size_option

      function item_arrow_style() result(ok)
      !< `as N` or `arrowstyle N` of vectors and arrows (token `i` the keyword): the heads, fill, size, color and width
      !< of `set style arrow N`, as gnuplot.
      logical      :: ok !< Success.
      integer(I4P) :: n  !< Style number.
      integer(I4P) :: j  !< Style counter.

      ok = .false.
      if (i < size(tokens, kind=I4P)) then
         if (tokens(i + 1_I4P)%text == 'variable' .or. tokens(i + 1_I4P)%text == 'var') then
            ! a style per arrow, from the column after the vector's (gnuplot `arrowstyle variable`)
            i = i + 1_I4P
            arrow_var = .true.
            ok = .true.
            return
         endif
      endif
      if (.not. next_integer(tokens, i, n, iostat, iomsg, self%symbols)) return
      ok = .true.
      if (.not. allocated(self%arrow_styles)) return
      do j = 1_I4P, size(self%arrow_styles, kind=I4P)
         if (self%arrow_styles(j)%tag /= n) cycle
         associate(style => self%arrow_styles(j))
            heads = heads//' '//trim(merge('nohead  ', 'head    ', style%head == 0_I4P))
            if (style%head == 2_I4P) heads = heads//' backhead'
            if (style%head == 3_I4P) heads = heads//' heads'
            if (any(trim(style%fill) == ['filled  ', 'noborder'])) then
               heads = heads//' filled'
            else
               heads = heads//' nofilled'
            endif
            item_head = 0.0_R8P
            if (style%length > 0.0_R8P) then
               item_head = [style%length, style%angle]
               item_head_system = style%length_system
            endif
            if (allocated(style%color)) then
               if (len(style%color) > 0) line%lc = style%color
            endif
            line%lw = style%lw
         endassociate
         exit
      enddo
      endfunction item_arrow_style

      subroutine color_last
      !< `lc variable` of circles, ellipses, boxes and candlesticks: each shape in its point's color, the key sample in
      !< the first one's
      !< (gnuplot).
      associate(panel => self%figure%panels(self%figure%current))
         associate(last => panel%series(size(panel%series)))
            if (size(point_colors) /= size(last%x)) return
            last%colors = point_colors
            if (size(point_colors) > 0) last%style%color = trim(point_colors(1))
            ! a histogram rebuilds its colors at every layout: its own kept apart
            if (last%style%with == WITH_HISTOGRAMS) last%own_colors = point_colors
         endassociate
      endassociate
      endsubroutine color_last

      subroutine mark_last
      !< The series just added: the axis of its text labels (`ytic(N)`, ...) and its point interval.
      integer(I4P) :: last !< Series just added.
      integer(I4P) :: kpt  !< Linetype of the default point type.

      associate(panel => self%figure%panels(self%figure%current))
         last = size(panel%series, kind=I4P)
         if (last < 1_I4P) return
         panel%series(last)%label_axis = label_axis
         if (panel%series(last)%style%with == WITH_SPIDERPLOT) then
            ! the group, a key entry, and the polygon color and width of the group's first item
            panel%series(last)%spider_group = spider_group
            panel%series(last)%spider_key = keyentry
            if (allocated(line%lc)) then
               if (len(line%lc) > 0) then
                  if (line%lc(1:1) /= '*') panel%series(last)%spider_color = line%lc
               endif
            endif
            if (allocated(line%lw)) panel%series(last)%spider_lw = line%lw
         endif
         ! gnuplot's xtic(..): a blank label still a tick
         panel%series(last)%blank_ticks = label_col > 0_I4P .and. .not. keyed
         if (label_col2 > 0_I4P .and. allocated(labels2)) then
            if (size(labels2) == size(panel%series(last)%x)) then
               panel%series(last)%label_axis2 = label_axis2
               allocate(panel%series(last)%xlabels2(size(labels2)))
               panel%series(last)%xlabels2 = labels2
            endif
         endif
         ! gnuplot's default point type: the item's linetype, cycling every 15
         if (panel%series(last)%style%pointtype < 0_I4P) then
            select case (panel%series(last)%style%with)
            case (WITH_POINTS, WITH_LINESPOINTS, WITH_YERRORBARS, WITH_XERRORBARS, WITH_XYERRORBARS, &
                  WITH_YERRORLINES, WITH_XERRORLINES, WITH_XYERRORLINES)
               kpt = last + panel%color_shift
               if (line%ptdef > 0_I4P) kpt = line%ptdef
               panel%series(last)%style%pointtype = modulo(kpt - 1_I4P, 15_I4P) + 1_I4P
            endselect
         endif
         if (allocated(line%pi)) panel%series(last)%pointinterval = line%pi
         if (allocated(line%pn)) panel%series(last)%pointnumber = line%pn
         panel%series(last)%ellipse_units = ellipse_units
         ! a keyentry takes the linetype of the next item without using it up, as gnuplot
         if (keyentry) panel%color_shift = panel%color_shift - 1_I4P
         panel%series(last)%noautoscale = item_noauto
         panel%series(last)%masked = item_mask
         ! a mask is not drawn: its key entry is its title alone (gnuplot's)
         panel%series(last)%key_blank = panel%series(last)%key_blank .or. panel%series(last)%style%with == WITH_MASK
         panel%series(last)%key_mid_palette = surface_item
         panel%series(last)%crisp = surface_item
         if (allocated(point_sizes)) then
            if (size(point_sizes) == size(panel%series(last)%x)) panel%series(last)%point_sizes = point_sizes
         endif
         if (allocated(point_types)) then
            if (size(point_types) == size(panel%series(last)%x)) panel%series(last)%point_types = point_types
         endif
         panel%series(last)%hypertext = hypertext
         ! the points of labels in the item's lc, black without one (gnuplot); the text in its tc
         if (panel%series(last)%style%with == WITH_LABELS .and. allocated(line%lc)) then
            if (len(line%lc) > 0) then
               if (line%lc(1:1) /= '*') panel%series(last)%point_color = line%lc
            endif
         endif
         ! a keyentry of labels, or of no style: no sample, as gnuplot 6.0
         if (keyentry_blank .or. (keyentry .and. .not. with_given)) panel%series(last)%style%color = 'none'
         panel%series(last)%gnuplot_sample = .true.
         panel%series(last)%title_plain = auto_title .or. plain_item
         panel%series(last)%title_auto = auto_title
         panel%series(last)%title_at = title_at
         panel%series(last)%title_justify = title_justify
         panel%series(last)%title_xy = title_xy
         if (allocated(line%pt_char)) panel%series(last)%style%point_char = line%pt_char
         if (allocated(point_tc) .and. panel%series(last)%style%with /= WITH_LABELS) &
            panel%series(last)%text_color = point_tc
         panel%series(last)%font = item_font
      endassociate
      endsubroutine mark_last

      function title_place() result(ok)
      !< The place after `title ... at` (token `i` is `at`): `beginning`, `end`, or `X,Y` in screen coordinates (an
      !< optional `screen` before each), as gnuplot.
      logical      :: ok !< Success.
      integer(I4P) :: c  !< Coordinate.
      real(R8P)    :: v  !< Value.

      ok = .false.
      if (i >= size(tokens, kind=I4P)) then
         call fail('plot: title at: beginning, end or X,Y expected', iostat, iomsg)
         return
      endif
      if (keyword(tokens(i + 1_I4P)%text, 'beginning', 3_I4P) .or. tokens(i + 1_I4P)%text == 'end') then
         i = i + 1_I4P
         title_at = merge(2_I4P, 1_I4P, tokens(i)%text == 'end')
         ! gnuplot's justification of that title: left or right
         if (i < size(tokens, kind=I4P)) then
            select case (tokens(i + 1_I4P)%text)
            case ('left')
               i = i + 1_I4P
               title_justify = 1_I4P
            case ('right')
               i = i + 1_I4P
               title_justify = 2_I4P
            endselect
         endif
      else
         ! screen coordinates (3), or graph ones (4): one system for both
         title_at = 3_I4P
         do c = 1_I4P, 2_I4P
            if (c == 2_I4P) then
               if (i + 1_I4P > size(tokens, kind=I4P)) exit
               if (tokens(i + 1_I4P)%kind /= TOKEN_COMMA) then
                  call fail('plot: title at X,Y expected', iostat, iomsg)
                  return
               endif
               i = i + 1_I4P
            endif
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%text == 'screen') then
                  i = i + 1_I4P
                  if (c == 2_I4P .and. title_at == 4_I4P) then
                     call fail('plot: title at: X and Y in one system (screen or graph)', iostat, iomsg)
                     return
                  endif
               elseif (tokens(i + 1_I4P)%text == 'graph') then
                  i = i + 1_I4P
                  if (c == 2_I4P .and. title_at == 3_I4P) then
                     call fail('plot: title at: X and Y in one system (screen or graph)', iostat, iomsg)
                     return
                  endif
                  title_at = 4_I4P
               endif
            endif
            if (.not. next_real(tokens, i, v, iostat, iomsg)) then
               iomsg = 'plot: title at: '//iomsg
               return
            endif
            title_xy(c) = v
         enddo
      endif
      ok = .true.
      endfunction title_place

      subroutine paint_last
      !< Color the series just added from the palette (`lc palette`, marker `palette_lc`): its `z` values (a point of
      !< undefined value not drawn, as gnuplot), the color axis value or the fraction of `line%palette`.
      integer(I4P) :: last !< Series just added.

      associate(panel => self%figure%panels(self%figure%current))
         last = size(panel%series, kind=I4P)
         select case (palette_lc)
         case (LC_PALETTE_Z)
            panel%series(last)%palette_mode = 1_I4P
            panel%series(last)%zvalues = zcolors
            if (allocated(line%colormap)) then
               ! a named colormap: a copy in the panel, the series pointing at it
               block
                  integer(I4P) :: k !< Colormap counter.

                  k = self%colormap_index(line%colormap)
                  if (.not. allocated(panel%colormaps)) allocate(panel%colormaps(0))
                  panel%colormaps = [panel%colormaps, self%colormaps(k)]
                  panel%series(last)%colormap = size(panel%colormaps, kind=I4P)
               endblock
            endif
         case (LC_PALETTE_CB)
            panel%series(last)%palette_mode = 2_I4P
            panel%series(last)%palette_value = line%palette
         case default
            panel%series(last)%palette_mode = 3_I4P
            panel%series(last)%palette_value = line%palette
         endselect
      endassociate
      endsubroutine paint_last

      function bins_option() result(ok)
      !< The `bins` option at token `i` (`word`), advancing `i` past its value: `bins[=N]`, `binrange [LO:HI]`,
      !< `binwidth=W`, `binvalue=sum|avg` (the last three after `bins`, as gnuplot); fails the plot if malformed.
      logical                       :: ok    !< Read.
      character(len=:), allocatable :: text  !< Value text.
      character(len=:), allocatable :: name  !< Option name.
      real(R8P)                     :: v     !< Number.
      integer(I4P)                  :: colon !< Range separator.

      ok = .false.
      if (is_function) then
         call fail('plot: bins apply to data files, not to the function "'//written//'"', iostat, iomsg)
         return
      endif
      name = word
      if (index(word, '=') > 0) name = word(1:index(word, '=') - 1)
      if (name /= 'bins' .and. .not. binned) then
         call fail('plot: '//name//' follows bins', iostat, iomsg)
         return
      endif
      select case (name)
      case ('bins')
         if (len(filter) > 0) then
            call fail('plot: bins and smooth '//filter//': not both', iostat, iomsg)
            return
         endif
         binned = .true.
         if (index(word, '=') == 0) then
            ! bins alone: set samples bins; else the = may be its own token
            if (i >= size(tokens, kind=I4P)) then
               ok = .true.
               return
            endif
            if (index(tokens(i + 1_I4P)%text, '=') /= 1) then
               ok = .true.
               return
            endif
         endif
         if (.not. value_text(text)) return
         if (verify(text, '0123456789+-') /= 0 .or. scan(text, '0123456789') == 0 .or. len(text) > 9) then
            call fail('plot: bins=N needs an integer, found "'//text//'"', iostat, iomsg)
            return
         endif
         read(text, *) nbins
         ! gnuplot: not positive means set samples
         if (nbins <= 0_I4P) nbins = self%samples
      case ('binrange')
         if (i >= size(tokens, kind=I4P)) then
            call fail('plot: binrange needs [LO:HI]', iostat, iomsg)
            return
         endif
         i = i + 1_I4P
         text = tokens(i)%text
         colon = index(text, ':', kind=I4P)
         if (tokens(i)%kind /= TOKEN_RANGE .or. colon == 0_I4P) then
            call fail('plot: binrange needs [LO:HI]', iostat, iomsg)
            return
         endif
         if (.not. (to_number(trim(adjustl(text(1:colon - 1_I4P))), binrange(1)) .and. &
                    to_number(trim(adjustl(text(colon + 1_I4P:))), binrange(2)))) then
            call fail('plot: binrange needs two numbers, found "['//text//']"', iostat, iomsg)
            return
         endif
      case ('binwidth')
         if (.not. value_text(text)) return
         if (.not. to_number(text, v)) then
            call fail('plot: binwidth=W needs a number, found "'//text//'"', iostat, iomsg)
            return
         endif
         if (.not. v > 0.0_R8P) then
            call fail('plot: binwidth must be positive', iostat, iomsg)
            return
         endif
         binwidth = v
      case default
         if (.not. (keyword(name, 'binvalue', 6_I4P))) then
            call fail('plot: unsupported option "'//word//'"', iostat, iomsg)
            return
         endif
         if (.not. value_text(text)) return
         if (text /= 'sum' .and. text /= 'avg') then
            call fail('plot: expecting binvalue={sum|avg}', iostat, iomsg)
            return
         endif
         binavg = text == 'avg'
      endselect
      ok = .true.
      endfunction bins_option

      function value_text(text) result(ok)
      !< The value of the option `word` at token `i` written NAME=VALUE, the = and the value glued to the name or in
      !< tokens of their own, advancing `i` past it; fails the plot if there is none.
      character(len=:), allocatable, intent(out) :: text !< Value.
      logical                                    :: ok   !< Read.

      ok = .false.
      text = ''
      if (index(word, '=') > 0) then
         text = word(index(word, '=') + 1:)
      elseif (i < size(tokens, kind=I4P)) then
         if (index(tokens(i + 1_I4P)%text, '=') == 1) then
            i = i + 1_I4P
            text = tokens(i)%text(2:)
         endif
      endif
      if (len(text) == 0 .and. i < size(tokens, kind=I4P)) then
         if (index(word, '=') > 0 .or. tokens(i)%text == '=') then
            i = i + 1_I4P
            text = tokens(i)%text
         endif
      endif
      if (len(text) == 0) then
         call fail('plot: '//word//' needs =VALUE', iostat, iomsg)
         return
      endif
      ok = .true.
      endfunction value_text

      subroutine variable_colors(c, rgb)
      !< The colors of the points from their color column `c`, gnuplot `lc variable`: the linetype color of each
      !< number (`set colorsequence`), or with `rgb` the color 0xAARRGGBB (AA the transparency, 0 opaque, as gnuplot);
      !< an undefined value takes linetype 1.
      !< The linetype colors go to default_color as the component itself, never through an associate name: they are
      !< unallocated by default (gnuplot's), and an associate selector must be allocated (nvfortran -O0 faults on it).
      real(R8P), intent(in)       :: c(:)  !< Color column.
      logical,   intent(in)       :: rgb   !< `lc rgb variable`.
      character(len=*), parameter :: HEX = '0123456789abcdef' !< Hexadecimal digits.
      integer(I8P)                :: code  !< 24-bit color.
      integer(I4P)                :: k     !< Point counter.
      integer(I4P)                :: d     !< Digit counter.
      integer(I4P)                :: digit !< Hexadecimal digit.

      if (allocated(point_colors)) deallocate(point_colors)
      allocate(point_colors(size(c)))
      do k = 1_I4P, size(c, kind=I4P)
         if (.not. ieee_is_finite(c(k))) then
            point_colors(k) = default_color(1_I4P, self%figure%panels(self%figure%current)%linecolors)
         elseif (rgb) then
            ! 0xAARRGGBB: a transparency AA (0 opaque) is the SVG opacity 255 - AA, #rrggbbaa
            code = iand(int(c(k), I8P), int(z'FFFFFF', I8P))
            point_colors(k) = '#'
            do d = 5_I4P, 0_I4P, -1_I4P
               digit = int(iand(ishft(code, -4_I4P * d), 15_I8P), I4P)
               point_colors(k)(7 - d:7 - d) = HEX(digit + 1:digit + 1)
            enddo
            code = 255_I8P - iand(ishft(int(c(k), I8P), -24_I4P), 255_I8P)
            if (code < 255_I8P .and. len(point_colors) >= 9) &
               point_colors(k)(8:9) = HEX(code / 16_I8P + 1_I8P:code / 16_I8P + 1_I8P)// &
                                      HEX(mod(code, 16_I8P) + 1_I8P:mod(code, 16_I8P) + 1_I8P)
         elseif (int(c(k), I4P) == 0_I4P) then
            ! linetype 0: gnuplot's gray
            point_colors(k) = '#808080'
         else
            point_colors(k) = default_color(int(c(k), I4P), self%figure%panels(self%figure%current)%linecolors)
         endif
      enddo
      endsubroutine variable_colors

      subroutine curve_filter
      !< The curve smoothing of the item (csplines, acsplines, bezier, sbezier, kdensity) into (x, y): `set samples`
      !< points, over the x range (fixed, inline, else the data's), acsplines weighted by a third column (1 without).
      real(R8P), allocatable        :: weights(:) !< acsplines weights.
      character(len=:), allocatable :: problem    !< Smoothing problem.
      real(R8P)                     :: lo         !< Smallest abscissa sampled.
      real(R8P)                     :: hi         !< Largest abscissa sampled.
      logical,   allocatable        :: finite(:)  !< Finite abscissae.

      if (size(values, 2) >= 3 .and. filter == 'acsplines') then
         weights = values(:, 3)
      else
         allocate(weights(size(values, 1)))
         weights = 1.0_R8P
      endif
      finite = ieee_is_finite(values(:, 1))
      if (.not. any(finite)) then
         call fail('plot: smooth '//filter//': no points', iostat, iomsg)
         return
      endif
      associate(panel => self%figure%panels(self%figure%current))
         if (axes(1:2) == 'x2') then
            call panel%x2axis%range_of(minval(values(:, 1), mask=finite), maxval(values(:, 1), mask=finite), .true., &
                                       lo, hi)
         else
            call panel%xaxis%range_of(minval(values(:, 1), mask=finite), maxval(values(:, 1), mask=finite), .true., &
                                      lo, hi)
         endif
         call smooth_curve(filter, values(:, 1), values(:, 2), weights, self%samples, lo, hi, bandwidth, &
                           merge(panel%x2axis%log, panel%xaxis%log, axes(1:2) == 'x2'), &
                           merge(panel%y2axis%log, panel%yaxis%log, axes(3:4) == 'y2'), x, y, problem)
         if (allocated(band_low)) deallocate(band_low)
         if (band_smooth .and. len(problem) == 0 .and. size(values, 2) >= 3) then
            ! the second curve of the band, on the same samples
            block
               real(R8P), allocatable :: x2(:) !< Its abscissae (those of the first).

               call smooth_curve(filter, values(:, 1), values(:, 3), weights, self%samples, lo, hi, bandwidth, &
                                 merge(panel%x2axis%log, panel%xaxis%log, axes(1:2) == 'x2'), &
                                 merge(panel%y2axis%log, panel%yaxis%log, axes(3:4) == 'y2'), x2, band_low, problem)
               if (size(band_low) /= size(y)) deallocate(band_low)
            endblock
         endif
      endassociate
      if (len(problem) > 0) call fail('plot: smooth '//filter//': '//problem, iostat, iomsg)
      endsubroutine curve_filter

      subroutine surface_grid
      !< gnuplot's `with surface` in polar mode (grid_polar_data, plot_polar_grid): the points theta:r:z weighted onto
      !< the polar grid of `set polar grid` (every point on every cell centre: qnorm 1/d^q, or a kernel of d/scale:
      !< gauss, cauchy, exp, box; a weighted mean, or the sum with kdensity), r from 0 to the largest r (a quarter of a
      !< segment more when autoscaled); each cell, clipped to the r range and the theta wedge of the grid, a polygon of
      !< its 4 corners in the palette color of its value, filled, unbordered: the item becomes polygons with lc palette.
      real(R8P),    allocatable :: th(:)    !< Data theta [rad, in 0..2pi].
      real(R8P),    allocatable :: cells(:,:) !< Polygon rows: theta, r, z (5 per cell, the last undefined).
      logical,      allocatable :: used(:)  !< Data point with theta and r.
      real(R8P)                 :: to_rad   !< Radians per user angle unit.
      real(R8P)                 :: rlo, rhi !< Grid r range.
      real(R8P)                 :: dr, dt   !< Segment sizes [r, deg].
      real(R8P)                 :: t, r     !< Cell corner [deg, r].
      real(R8P)                 :: z, w     !< Weighted sum and weights.
      real(R8P)                 :: d        !< Distance of a point to a cell centre.
      real(R8P)                 :: dtheta   !< Angle between them [rad].
      real(R8P)                 :: wt       !< A kernel weight.
      real(R8P)                 :: cmin, cmax !< Radial clipping.
      real(R8P)                 :: tmin, tmax !< Angular clipping [deg].
      real(R8P)                 :: c(4)     !< Cell bounds: theta low, theta high, r low, r high.
      real(R8P)                 :: zlo, zhi !< Values of the whole grid.
      logical                   :: lo_in, hi_in !< Theta bounds within the wedge.
      integer(I4P)              :: i, j, k  !< Counters.
      integer(I4P)              :: m        !< Polygon rows.

      associate(panel => self%figure%panels(self%figure%current), grid => self%polar_grid)
         to_rad = merge(PI_SCRIPT / 180.0_R8P, 1.0_R8P, panel%degrees)
         allocate(th(size(values, 1)), used(size(values, 1)))
         used = ieee_is_finite(values(:, 1)) .and. ieee_is_finite(values(:, 2)) .and. ieee_is_finite(values(:, 3))
         ! theta in 0..2pi (gnuplot's store_polar_point)
         do i = 1_I4P, size(values, 1, kind=I4P)
            th(i) = 0.0_R8P
            if (.not. used(i)) cycle
            th(i) = values(i, 1) * to_rad
            if (th(i) >= -630.0_R8P) then
               do while (th(i) < 0.0_R8P)
                  th(i) = th(i) + 2.0_R8P * PI_SCRIPT
               enddo
            endif
            if (th(i) <= 630.0_R8P) then
               do while (th(i) > 2.0_R8P * PI_SCRIPT)
                  th(i) = th(i) - 2.0_R8P * PI_SCRIPT
               enddo
            endif
         enddo
         rlo = 0.0_R8P
         if (panel%raxis%log .and. panel%raxis%min_fixed) rlo = panel%raxis%min_user
         if (panel%raxis%max_fixed) then
            rhi = panel%raxis%max_user
         else
            rhi = -huge(1.0_R8P)
            if (any(used)) rhi = maxval(values(:, 2), mask=used)
            rhi = rhi + (rhi - rlo) / real(grid%r_segments, R8P) / 4.0_R8P
         endif
         dr = (rhi - rlo) / real(grid%r_segments, R8P)
         dt = 360.0_R8P / real(grid%theta_segments, R8P)
         ! clipping: the r range and the grid's r limits, the grid's theta wedge
         cmin = max(merge(panel%raxis%min_user, rlo, panel%raxis%min_fixed), grid%rmin)
         cmax = min(rhi, grid%rmax)
         tmin = grid%tmin
         tmax = grid%tmax
         if (tmax - tmin >= 360.0_R8P) then
            tmin = 0.0_R8P
            tmax = 360.0_R8P
         endif
         allocate(cells(5 * grid%theta_segments * grid%r_segments + 4, 3))
         cells = ieee_value(1.0_R8P, ieee_quiet_nan)
         m = 0_I4P
         zlo = huge(1.0_R8P)
         zhi = -huge(1.0_R8P)
         do i = 0_I4P, grid%r_segments - 1_I4P
            r = rlo + real(i, R8P) * dr
            do j = 0_I4P, grid%theta_segments - 1_I4P
               t = real(j, R8P) * dt
               z = 0.0_R8P
               w = 0.0_R8P
               do k = 1_I4P, size(values, 1, kind=I4P)
                  if (.not. used(k)) cycle
                  ! distance to the cell centre (gnuplot's polar_dist)
                  dtheta = abs((t + 0.5_R8P * dt) * PI_SCRIPT / 180.0_R8P - th(k))
                  if (dtheta > PI_SCRIPT) dtheta = 2.0_R8P * PI_SCRIPT - dtheta
                  d = sqrt((r + 0.5_R8P * dr - values(k, 2) * cos(dtheta))**2 + (values(k, 2) * sin(dtheta))**2)
                  if (grid%mode == 1_I4P) then
                     if (grid%norm_q > 1_I4P) d = d**grid%norm_q
                     if (d == 0.0_R8P) then
                        z = values(k, 3)
                        w = 1.0_R8P
                        exit
                     endif
                     z = z + values(k, 3) / d
                     w = w + 1.0_R8P / d
                  else
                     d = d / grid%scale
                     select case (grid%mode)
                     case (2_I4P)
                        wt = exp(-d * d)
                     case (3_I4P)
                        wt = 1.0_R8P / (1.0_R8P + d * d)
                     case (4_I4P)
                        wt = exp(-d)
                     case default
                        wt = merge(1.0_R8P, 0.0_R8P, d < 1.0_R8P)
                     endselect
                     z = z + values(k, 3) * wt
                     w = w + wt
                  endif
               enddo
               if (.not. grid%kdensity) then
                  if (w > 0.0_R8P) then
                     z = z / w
                  else
                     z = ieee_value(1.0_R8P, ieee_quiet_nan)
                  endif
               endif
               ! every cell counts for the color range, clipped or not (gnuplot autoscales z on the whole grid)
               if (ieee_is_finite(z)) then
                  zlo = min(zlo, z)
                  zhi = max(zhi, z)
               endif
               c = [t, t + dt, r, r + dr]
               if (c(4) < cmin .or. c(3) > cmax) cycle
               c(3) = max(c(3), cmin)
               c(4) = min(c(4), cmax)
               lo_in = in_wedge(c(1), tmin, tmax)
               hi_in = in_wedge(c(2), tmin, tmax)
               if (lo_in) then
                  if (.not. hi_in) c(2) = tmax
               elseif (hi_in) then
                  c(1) = tmin
               else
                  cycle
               endif
               cells(m + 1:m + 4, 1) = [c(1), c(2), c(2), c(1)] * (PI_SCRIPT / 180.0_R8P) / to_rad
               cells(m + 1:m + 4, 2) = [c(3), c(3), c(4), c(4)]
               cells(m + 1:m + 4, 3) = z
               m = m + 5_I4P
            enddo
         enddo
         ! two lone points, never drawn (a polygon needs 3): the whole grid's r end and z range for the autoscale, as
         ! gnuplot's (the r axis up to the grid, the colors of the whole grid)
         if (zlo <= zhi) then
            cells(m + 1, :) = [0.0_R8P, rhi, zlo]
            cells(m + 3, :) = [0.0_R8P, rhi, zhi]
            m = m + 4_I4P
         endif
      endassociate
      values = cells(1:m, :)
      ! drawn as polygons in the palette colors of their value, filled solid and unbordered (gnuplot's quadrangles)
      with = 'polygons'
      surface_item = .true.
      lcz = .true.
      line%lc = LC_PALETTE_Z
      if (.not. allocated(fs)) fs = 'solid 1.0'
      fs = fs//' noborder'
      if (allocated(xlabels)) deallocate(xlabels)
      endsubroutine surface_grid

      subroutine zsort_filter
      !< gnuplot's zsort: the rows of each curve (a run of defined points) sorted by their z, the third column, stably
      !< (glibc's merge sort), the lowest first, then the z column dropped (`using x:y:z[:color]`).
      integer(I4P), allocatable :: order(:) !< Row order.
      integer(I4P), allocatable :: rest(:)  !< Columns kept.
      integer(I4P)              :: first    !< Run start.
      integer(I4P)              :: last     !< Run end.
      integer(I4P)              :: k        !< Counter.
      integer(I4P)              :: j        !< Counter.
      integer(I4P)              :: key      !< Row moved.
      integer(I4P)              :: n        !< Rows.
      logical                   :: after    !< A row after the key.

      if (size(values, 2) < 3) return
      n = size(values, 1, kind=I4P)
      order = [(k, k = 1_I4P, n)]
      first = 1_I4P
      do while (first <= n)
         if (.not. (ieee_is_finite(values(first, 1)) .and. ieee_is_finite(values(first, 2)))) then
            first = first + 1_I4P
            cycle
         endif
         last = first
         do while (last < n)
            if (.not. (ieee_is_finite(values(last + 1, 1)) .and. ieee_is_finite(values(last + 1, 2)))) exit
            last = last + 1_I4P
         enddo
         ! a stable insertion sort of the run on z (an undefined z last)
         do k = first + 1_I4P, last
            key = order(k)
            j = k - 1_I4P
            do while (j >= first)
               ! row order(j) after the key on z (an undefined z after every other)
               if (.not. ieee_is_finite(values(order(j), 3))) then
                  after = ieee_is_finite(values(key, 3))
               elseif (.not. ieee_is_finite(values(key, 3))) then
                  after = .false.
               else
                  after = values(order(j), 3) > values(key, 3)
               endif
               if (.not. after) exit
               order(j + 1) = order(j)
               j = j - 1_I4P
            enddo
            order(j + 1) = key
         enddo
         first = last + 1_I4P
      enddo
      values = values(order, :)
      rest = pack([(k, k = 1_I4P, size(values, 2, kind=I4P))], [(k /= 3_I4P, k = 1_I4P, size(values, 2, kind=I4P))])
      values = values(:, rest)
      if (allocated(xlabels)) then
         if (size(xlabels) == n) xlabels = xlabels(order)
      endif
      endsubroutine zsort_filter

      subroutine hull_filter
      !< gnuplot's hull filters of the item's points, right after they are read: `convexhull` or `concavehull` (its
      !< characteristic length the variable chi_length if positive, else `set chi_shape fraction` of the longest convex
      !< hull edge, the one used in GPVAL_CHI_LENGTH), then `expand D`; every column follows its point.
      integer(I4P), allocatable :: rows(:)   !< Rows of finite points.
      integer(I4P), allocatable :: idx(:)    !< Hull rows among them.
      integer(I4P), allocatable :: src(:)    !< Hull point of each expanded point.
      real(R8P),    allocatable :: kept(:,:) !< Finite points.
      real(R8P),    allocatable :: ex(:)     !< Expanded abscissae.
      real(R8P),    allocatable :: ey(:)     !< Expanded ordinates.
      real(R8P)                 :: chi       !< Characteristic length given, 0 for none.
      real(R8P)                 :: chi_used  !< Characteristic length used.
      logical                   :: found     !< chi_length defined.
      logical                   :: is_int    !< chi_length an integer.
      integer(I4P)              :: r         !< Row.

      rows = pack([(r, r = 1_I4P, size(values, 1, kind=I4P))], ieee_is_finite(values(:, 1)) .and. &
                  ieee_is_finite(values(:, 2)))
      kept = values(rows, :)
      if (hull == 1_I4P) then
         call convex_hull(kept(:, 1), kept(:, 2), idx)
      elseif (hull == 3_I4P) then
         ! the triangles, each closed, a blank line (an undefined point) after each
         call delaunay_triangles(kept(:, 1), kept(:, 2), idx)
         block
            real(R8P), allocatable :: tris(:,:) !< Triangle points.
            integer(I4P)           :: k         !< Counter.

            allocate(tris(size(idx), size(kept, 2)))
            tris = ieee_value(1.0_R8P, ieee_quiet_nan)
            do k = 1_I4P, size(idx, kind=I4P)
               if (idx(k) > 0_I4P) tris(k, :) = kept(idx(k), :)
            enddo
            values = tris
         endblock
         if (allocated(xlabels)) deallocate(xlabels)
         return
      else
         ! gnuplot reads chi_length only when it holds a real (an integer, `chi_length = 5`, is ignored)
         call self%symbols%value_of('chi_length', chi, found, is_int)
         if (.not. found .or. is_int) chi = 0.0_R8P
         if (.not. chi > 0.0_R8P) chi = 0.0_R8P
         call concave_hull(kept(:, 1), kept(:, 2), chi, self%chi_fraction, idx, chi_used)
         call self%symbols%set_value('GPVAL_CHI_LENGTH', chi_used, is_int=.false.)
      endif
      values = kept(idx, :)
      rows = rows(idx)
      if (hull_expand /= 0.0_R8P) then
         call expand_hull(values(:, 1), values(:, 2), hull_expand, ex, ey, src)
         values = values(src, :)
         values(:, 1) = ex
         values(:, 2) = ey
         rows = rows(src)
      endif
      if (allocated(xlabels)) then
         if (size(xlabels) >= maxval([0_I4P, rows])) xlabels = xlabels(rows)
      endif
      endsubroutine hull_filter

      subroutine path_filter
      !< gnuplot's `smooth path` of the item into (x, y): a spline along each set of points in their order (path_spline),
      !< `set samples` points over a path, the path length scaled by the x and y ranges (set, else the data's), every
      !< set closed with filledcurves.
      real(R8P)            :: span(2) !< x and y scales.
      logical, allocatable :: finite(:) !< Finite points.
      integer(I4P)         :: k       !< Axis counter.

      finite = ieee_is_finite(values(:, 1)) .and. ieee_is_finite(values(:, 2))
      span = 1.0_R8P
      associate(panel => self%figure%panels(self%figure%current))
         do k = 1_I4P, 2_I4P
            if (any(finite)) span(k) = maxval(values(:, k), mask=finite) - minval(values(:, k), mask=finite)
            ! a set range instead (no merge of axes: gfortran 16 frees their components twice)
            if (k == 1_I4P .and. axes(1:2) == 'x2') then
               if (panel%x2axis%min_fixed .and. panel%x2axis%max_fixed) &
                  span(k) = panel%x2axis%max_user - panel%x2axis%min_user
            elseif (k == 1_I4P) then
               if (panel%xaxis%min_fixed .and. panel%xaxis%max_fixed) span(k) = panel%xaxis%max_user - panel%xaxis%min_user
            elseif (axes(3:4) == 'y2') then
               if (panel%y2axis%min_fixed .and. panel%y2axis%max_fixed) &
                  span(k) = panel%y2axis%max_user - panel%y2axis%min_user
            else
               if (panel%yaxis%min_fixed .and. panel%yaxis%max_fixed) span(k) = panel%yaxis%max_user - panel%yaxis%min_user
            endif
         enddo
      endassociate
      call path_spline(values(:, 1), values(:, 2), self%samples, span(1), span(2), with == 'filledcurves', x, y)
      endsubroutine path_filter

      subroutine new_histogram
      !< `newhistogram ["title"] [lt|linetype N] [fs|fillstyle FILL] [at X]` at token `i`, up to the next comma (`i` on
      !< it): the next histograms a new group, laid out after the previous one or from X, the title below the x axis,
      !< their default colors from linetype N, their fill FILL.
      character(len=:), allocatable :: text  !< Group title.
      real(R8P), allocatable        :: start !< Group start.
      integer(I4P), allocatable     :: lt    !< First linetype.
      integer(I4P)                  :: n     !< Linetype read.
      real(R8P)                     :: v     !< Start read.

      text = ''
      if (allocated(group_fs)) deallocate(group_fs)
      i = i + 1_I4P
      if (i <= size(tokens, kind=I4P)) then
         if (tokens(i)%kind == TOKEN_STRING .or. (tokens(i)%kind == TOKEN_WORD .and. .not. &
             is_word(tokens(i)%text, 'lt linetype fs fillstyle at'))) then
            if (.not. self%string_expression(tokens, i, text, iostat, iomsg)) then
               iomsg = 'plot: newhistogram: '//iomsg
               return
            endif
            i = i + 1_I4P
         endif
      endif
      do while (i <= size(tokens, kind=I4P))
         if (tokens(i)%kind == TOKEN_COMMA) exit
         if (is_word(tokens(i)%text, 'lt linetype')) then
            if (.not. next_integer(tokens, i, n, iostat, iomsg, self%symbols)) return
            if (n < 1_I4P) then
               call fail('plot: newhistogram: the linetype starts at 1', iostat, iomsg)
               return
            endif
            lt = n
         elseif (is_word(tokens(i)%text, 'fs fillstyle')) then
            group_fs = ''
            do while (i < size(tokens, kind=I4P))
               if (tokens(i + 1_I4P)%kind == TOKEN_COMMA) exit
               if (is_word(tokens(i + 1_I4P)%text, 'lt linetype at')) exit
               i = i + 1_I4P
               group_fs = group_fs//' '//tokens(i)%text
            enddo
         elseif (tokens(i)%text == 'at') then
            if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) return
            start = v
         else
            call fail('plot: newhistogram: unsupported option "'//tokens(i)%text//'" ("title", lt N, fs FILL, at X)', &
                      iostat, iomsg)
            return
         endif
         i = i + 1_I4P
      enddo
      if (allocated(lt) .and. allocated(start)) then
         call self%figure%new_histogram(title=text, at=start, lt=lt)
      elseif (allocated(lt)) then
         call self%figure%new_histogram(title=text, lt=lt)
      elseif (allocated(start)) then
         call self%figure%new_histogram(title=text, at=start)
      else
         call self%figure%new_histogram(title=text)
      endif
      endsubroutine new_histogram

      subroutine sampling_range(text, k)
      !< The `k`-th sampling range of an item, `[min:max]`, `[name=min:max]` or `[name=min:max:step]` (`text` without
      !< brackets); an empty or `*` end is not given.
      character(len=*), intent(in)  :: text  !< Range text.
      integer(I4P),     intent(in)  :: k     !< Range: 1 the first (u), 2 the second (v).
      character(len=:), allocatable :: body  !< Range without the variable name.
      character(len=:), allocatable :: rest  !< After the first colon.
      integer(I4P)                  :: colon !< Separator.
      integer(I4P)                  :: equal !< Variable name separator.
      real(R8P)                     :: v     !< Interval.

      body = text
      equal = index(text, '=', kind=I4P)
      colon = top_colon(text)
      if (scan(text, '"'//"'") > 0 .and. equal > scan(text, '"'//"'")) equal = 0_I4P
      if (equal > 0_I4P .and. (colon == 0_I4P .or. equal < colon)) then
         sample_names(k) = trim(adjustl(text(1:equal - 1_I4P)))
         if (len_trim(sample_names(k)) == 0 .or. &
             verify(trim(sample_names(k)), UNAME_CHARS) /= 0 .or. &
             verify(sample_names(k)(1:1), '0123456789') == 0) then
            call fail('plot: bad sampling variable name in "['//text//']"', iostat, iomsg)
            return
         endif
         body = text(equal + 1_I4P:)
         colon = top_colon(body)
      endif
      if (colon == 0_I4P) then
         call fail('plot: a sampling range [min:max] is expected, found "['//text//']"', iostat, iomsg)
         return
      endif
      rest = body(colon + 1_I4P:)
      call inline_end(body(1:colon - 1_I4P), sample_set(1, k), sample_range(1, k))
      if (iostat /= 0_I4P) return
      colon = top_colon(rest)
      if (colon > 0_I4P) then
         call inline_end(rest(1:colon - 1_I4P), sample_set(2, k), sample_range(2, k))
         if (iostat /= 0_I4P) return
         call self%range_value(trim(adjustl(rest(colon + 1_I4P:))), v, iostat, iomsg)
         if (iostat /= 0_I4P) then
            iomsg = 'plot: sampling interval: '//iomsg
            return
         endif
         if (v == 0.0_R8P) then
            call fail('plot: the sampling interval of "['//text//']" must not be 0', iostat, iomsg)
            return
         endif
         sample_step(k) = v
      else
         call inline_end(rest, sample_set(2, k), sample_range(2, k))
      endif
      endsubroutine sampling_range

      subroutine pseudo_rows(rows)
      !< The rows of the item's pseudo-file, as gnuplot 6.0's: `'+'` samples t over the sampling range, else trange
      !< (parametric and polar modes, or a set trange), else the x range (the data so far when autoscaled, [-10:10]
      !< without), `set samples` of them or by the interval; `'++'` a grid over urange (`set samples`) and vrange
      !< (`set isosamples`, the second value) or the ranges given, v from its maximum, scan lines apart.
      character(len=:), allocatable, intent(out) :: rows  !< Rows.
      real(R8P)                                  :: lo    !< First sample.
      real(R8P)                                  :: hi    !< Last sample.
      real(R8P)                                  :: step  !< Interval.
      real(R8P)                                  :: t     !< Sample.
      real(R8P)                                  :: ends(2, 2) !< u and v ranges.
      real(R8P)                                  :: steps(2)   !< u and v intervals.
      integer(I4P)                               :: counts(2)  !< u and v samples.
      integer(I4P)                               :: j     !< Sample counter.
      integer(I4P)                               :: jv    !< Scan line counter.
      integer(I4P)                               :: c     !< Column.
      logical                                    :: logx  !< Samples even on a log x axis.
      integer(I4P), parameter                    :: MAX_ROWS = 1000000_I4P !< Bound of an explicit sampling.

      rows = ''
      if (pseudo >= 3_I4P) then
         ! a splot function's iso-curves or a matrix's rows, generated before
         rows = generated
         return
      endif
      if (pseudo == 1_I4P) then
         logx = .false.
         associate(panel => self%figure%panels(self%figure%current))
            if (self%parametric .or. panel%polar) then
               lo = merge(-5.0_R8P, 0.0_R8P, self%parametric .and. .not. panel%polar)
               hi = merge(5.0_R8P, merge(360.0_R8P, 2.0_R8P * acos(-1.0_R8P), panel%degrees), &
                          self%parametric .and. .not. panel%polar)
               if (panel%taxis%min_fixed) lo = panel%taxis%min_user
               if (panel%taxis%max_fixed) hi = panel%taxis%max_user
            elseif (panel%taxis%min_fixed .and. panel%taxis%max_fixed) then
               lo = panel%taxis%min_user
               hi = panel%taxis%max_user
            else
               block
                  real(R8P) :: x0(2)     !< Smallest abscissa, per x axis.
                  real(R8P) :: x1(2)     !< Largest abscissa, per x axis.
                  real(R8P) :: y0(2)     !< Smallest ordinate, per y axis.
                  real(R8P) :: y1(2)     !< Largest ordinate, per y axis.
                  logical   :: found(2)  !< Any point, per y axis.
                  logical   :: xfound(2) !< Any point, per x axis.

                  call panel%axes_extent(x0, x1, y0, y1, found, xfound)
                  lo = -10.0_R8P
                  hi = 10.0_R8P
                  if (xfound(1)) then
                     lo = x0(1)
                     hi = x1(1)
                  endif
               endblock
               if (panel%xaxis%min_fixed) lo = panel%xaxis%min_user
               if (panel%xaxis%max_fixed) hi = panel%xaxis%max_user
               if (panel%xaxis%plot_min_fixed) lo = panel%xaxis%plot_min
               if (panel%xaxis%plot_max_fixed) hi = panel%xaxis%plot_max
               logx = panel%xaxis%log .and. lo > 0.0_R8P .and. hi > 0.0_R8P
            endif
         endassociate
         if (sample_set(1, 1)) lo = sample_range(1, 1)
         if (sample_set(2, 1)) hi = sample_range(2, 1)
         if (any(sample_set(:, 1)) .or. sample_step(1) /= 0.0_R8P) then
            ! an explicit sampling range: from its start by the interval while inside it
            logx = .false.
            step = sample_step(1)
            if (step == 0.0_R8P) step = (hi - lo) / real(self%samples - 1_I4P, R8P)
            if (step == 0.0_R8P) step = 1.0_R8P
            do j = 0_I4P, MAX_ROWS
               t = lo + real(j, R8P) * step
               if (t < min(lo, hi) .or. t > max(lo, hi)) exit
               rows = rows//gnuplot_real(t)//new_line('a')
            enddo
         else
            if (logx) then
               lo = log10(lo)
               hi = log10(hi)
            endif
            step = (hi - lo) / real(self%samples - 1_I4P, R8P)
            if (step == 0.0_R8P) step = 1.0_R8P
            do j = 0_I4P, self%samples - 1_I4P
               t = lo + real(j, R8P) * step
               if (logx) t = 10.0_R8P**t
               rows = rows//gnuplot_real(t)//new_line('a')
            enddo
         endif
      else
         ends = self%uv_range
         do c = 1_I4P, 2_I4P
            if (sample_set(1, c)) ends(1, c) = sample_range(1, c)
            if (sample_set(2, c)) ends(2, c) = sample_range(2, c)
            if (sample_step(c) /= 0.0_R8P) then
               steps(c) = sample_step(c)
               counts(c) = max(1_I4P, int(floor((ends(2, c) - ends(1, c)) / steps(c)), I4P) + 1_I4P)
            else
               counts(c) = merge(self%samples, self%isosamples, c == 1_I4P)
               steps(c) = (ends(2, c) - ends(1, c)) / real(counts(c) - 1_I4P, R8P)
            endif
         enddo
         do jv = 0_I4P, counts(2) - 1_I4P
            if (jv > 0_I4P) rows = rows//new_line('a')
            t = ends(2, 2) - real(jv, R8P) * steps(2)
            if (jv == counts(2) - 1_I4P) t = ends(1, 2)
            do j = 0_I4P, counts(1) - 1_I4P
               if (j == counts(1) - 1_I4P) then
                  rows = rows//gnuplot_real(ends(2, 1))//' '//gnuplot_real(t)//new_line('a')
               else
                  rows = rows//gnuplot_real(ends(1, 1) + real(j, R8P) * steps(1))//' '//gnuplot_real(t)//new_line('a')
               endif
            enddo
         enddo
      endif
      endsubroutine pseudo_rows

      subroutine inline_range(text, axis)
      !< An inline range `[min:max]` of the plot command (`text` without brackets): of x (`axis` 1), y (2), t (3,
      !< the first range in parametric mode) or z (4, splot's third); `[name=min:max]` of x or t also names the dummy
      !< variable; an empty or `*` end keeps the set one, as gnuplot.
      character(len=*), intent(in)  :: text  !< Range text.
      integer(I4P),     intent(in)  :: axis  !< 1 x, 2 y, 3 t, 4 z.
      logical                       :: first !< A range of the dummy variable (x or t).
      character(len=:), allocatable :: body  !< Range without the dummy variable.
      integer(I4P)                  :: colon !< Separator.
      integer(I4P)                  :: equal !< Dummy variable separator.

      first = axis == 1_I4P .or. axis == 3_I4P
      body = text
      equal = index(text, '=', kind=I4P)
      colon = top_colon(text)
      ! a quoted time holds no dummy variable
      if (scan(text, '"'//"'") > 0 .and. equal > scan(text, '"'//"'")) equal = 0_I4P
      if (first .and. equal > 0_I4P .and. (colon == 0_I4P .or. equal < colon)) then
         dummy = trim(adjustl(text(1:equal - 1_I4P)))
         if (len(dummy) == 0) then
            call fail('plot: bad dummy variable name in "['//text//']"', iostat, iomsg)
            return
         endif
         if (verify(dummy, UNAME_CHARS) /= 0 .or. &
             verify(dummy(1:1), '0123456789') == 0) then
            call fail('plot: bad dummy variable name in "['//text//']"', iostat, iomsg)
            return
         endif
         body = text(equal + 1_I4P:)
         colon = top_colon(body)
      endif
      if (len_trim(body) == 0) return
      if (colon == 0_I4P) then
         call fail('plot: inline range "['//text//']": [min:max] expected', iostat, iomsg)
         return
      endif
      associate(panel => self%figure%panels(self%figure%current))
         if (axis == 4_I4P) then
            call inline_end(body(1:colon - 1_I4P), panel%zaxis%plot_min_fixed, panel%zaxis%plot_min)
            if (iostat == 0_I4P) call inline_end(body(colon + 1_I4P:), panel%zaxis%plot_max_fixed, panel%zaxis%plot_max)
         elseif (axis == 3_I4P) then
            call inline_end(body(1:colon - 1_I4P), panel%taxis%plot_min_fixed, panel%taxis%plot_min)
            if (iostat == 0_I4P) call inline_end(body(colon + 1_I4P:), panel%taxis%plot_max_fixed, panel%taxis%plot_max)
         elseif (axis == 1_I4P) then
            call inline_end(body(1:colon - 1_I4P), panel%xaxis%plot_min_fixed, panel%xaxis%plot_min)
            if (iostat == 0_I4P) call inline_end(body(colon + 1_I4P:), panel%xaxis%plot_max_fixed, panel%xaxis%plot_max)
         else
            call inline_end(body(1:colon - 1_I4P), panel%yaxis%plot_min_fixed, panel%yaxis%plot_min)
            if (iostat == 0_I4P) call inline_end(body(colon + 1_I4P:), panel%yaxis%plot_max_fixed, panel%yaxis%plot_max)
         endif
      endassociate
      endsubroutine inline_range

      subroutine inline_end(text, fixed, value)
      !< One end of an inline range: empty or `*` keeps the set one, else a number or a constant expression.
      character(len=*), intent(in)    :: text  !< End text.
      logical,          intent(inout) :: fixed !< End given.
      real(R8P),        intent(inout) :: value !< End value.
      real(R8P)                       :: v     !< Parsed value.

      if (len_trim(text) == 0 .or. trim(adjustl(text)) == '*') return
      call self%range_value(trim(adjustl(text)), v, iostat, iomsg)
      if (iostat /= 0_I4P) then
         iomsg = 'plot: inline range: '//iomsg
         return
      endif
      fixed = .true.
      value = v
      endsubroutine inline_end

      subroutine image_item
      !< An image item: the values of a `matrix` file, or `using x:y:z` (default 1:2:3) gathered on a regular grid.
      real(R8P), allocatable        :: points(:,:) !< Values of the `using` fields (local: nvfortran 26.9 breaks the
                                                   !< column sections of the host's `values` allocated here).
      real(R8P), allocatable        :: z(:,:)      !< Grid values.
      real(R8P), allocatable        :: xs(:)       !< Pixel centre abscissae.
      real(R8P), allocatable        :: ys(:)       !< Pixel centre ordinates.
      character(len=:), allocatable :: problem     !< Grid problem.

      if (.not. has_title .and. self%autotitle == 'file') then
         call item_auto_title(text, tokens(item_first)%first, tokens(item_first)%last, tokens(title_to)%last, &
                              written, quote, shown_spec, using, title)
      endif
      if (is_matrix) then
         if (allocated(fields)) then
            call fail('plot: a matrix item takes no using', iostat, iomsg)
            return
         endif
         call data%matrix(set_index, z, problem)
         if (len(problem) > 0) then
            call fail('plot: '//problem//' in "'//file//'"', iostat, iomsg)
            return
         endif
         if (size(z) == 0) then
            call fail('plot: no values in "'//file//'"', iostat, iomsg)
            return
         endif
         if (nonuniform) then
            ! the first row (its first value ignored) the x of the columns, the first column the y of the rows
            if (size(z, 1) < 2 .or. size(z, 2) < 2) then
               call fail('plot: a nonuniform matrix needs its x row, its y column and values in "'//file//'"', iostat, &
                         iomsg)
               return
            endif
            xs = z(2:, 1)
            ys = z(1, 2:)
            if (.not. (even(xs) .and. even(ys))) then
               call fail('plot: image of a nonuniform matrix: evenly spaced x and y increasing are expected (the '// &
                         'pixels of uneven ones are not supported)', iostat, iomsg)
               return
            endif
            call self%figure%image(z(2:, 2:), xs, ys, title=title)
            return
         endif
         if (any(every /= [1_I4P, 1_I4P, 0_I4P, 0_I4P, -1_I4P, -1_I4P])) then
            ! gnuplot's every on a matrix: the columns kept as the points, the rows as the blocks, at their places
            block
               real(R8P), allocatable :: sub(:,:) !< Submatrix.

               call matrix_every(z, every, sub, xs, ys)
               if (size(sub) == 0) then
                  call fail('plot: every leaves no values of "'//file//'"', iostat, iomsg)
                  return
               endif
               call self%figure%image(sub, xs, ys, title=title)
            endblock
            return
         endif
         call self%figure%image(z, title=title)
         return
      endif
      if (with /= 'image') then
         call rgb_item
         return
      endif
      if (.not. allocated(fields)) fields = plain_columns([1_I4P, 2_I4P, 3_I4P])
      if (size(fields) /= 3) then
         call fail('plot: image needs using x:y:z (or a matrix file)', iostat, iomsg)
         return
      endif
      call data%table(fields, set_index, every, points)
      call regular_grid(points(:, 1), points(:, 2), points(:, 3), xs, ys, z, problem)
      if (len(problem) > 0) then
         call fail('plot: image of "'//file//'": '//problem, iostat, iomsg)
         return
      endif
      call self%figure%image(z, xs, ys, title=title)
      endsubroutine image_item

      pure function even(v) result(yes)
      !< Whether `v` increases by an even step (one value: even).
      real(R8P), intent(in) :: v(:) !< Values.
      logical               :: yes  !< Even and increasing.
      real(R8P)             :: step !< First step.

      yes = .true.
      if (size(v) < 2) return
      step = v(2) - v(1)
      yes = step > 0.0_R8P .and. all(abs((v(2:) - v(:size(v) - 1)) - step) <= 1.0e-9_R8P * abs(step) * size(v))
      endfunction even

      function named_index(name) result(k)
      !< The dataset (from 0) after the comment line of the item's file starting with `name` (the comment characters and
      !< blanks before it removed), as gnuplot; datasets apart at two blank lines; fails the plot if none.
      character(len=*), intent(in)  :: name  !< Dataset name.
      integer(I4P)                  :: k     !< Dataset.
      character(len=:), allocatable :: text  !< File or datablock content.
      character(len=:), allocatable :: line  !< Current line.
      integer(I4P)                  :: p     !< Line start.
      integer(I4P)                  :: q     !< Line end.
      integer(I4P)                  :: blank !< Blank lines in a row.
      logical                       :: seen  !< Data rows read.
      logical                       :: named !< The name found.
      logical                       :: found !< Datablock found.

      k = 0_I4P
      if (is_datablock(file)) then
         call self%symbols%string_of(file, text, found)
      else
         found = read_whole(file, text)
      endif
      if (.not. found) then
         call fail('plot: index "'//name//'": cannot read "'//file//'"', iostat, iomsg)
         return
      endif
      blank = 0_I4P
      seen = .false.
      named = .false.
      p = 1_I4P
      do while (p <= len(text, kind=I4P))
         q = index(text(p:), new_line('a'), kind=I4P)
         if (q == 0_I4P) then
            q = len(text, kind=I4P) + 1_I4P
         else
            q = p + q - 1_I4P
         endif
         line = trim(adjustl(text(p:q - 1_I4P)))
         p = q + 1_I4P
         if (len(line) == 0) then
            blank = blank + 1_I4P
         elseif (scan(line(1:1), self%comments) > 0) then
            line = trim(adjustl(line(verify(line, self%comments//' '//achar(9)):)))
            if (index(line, name) == 1) named = .true.
         else
            if (seen .and. blank >= 2_I4P) k = k + 1_I4P
            blank = 0_I4P
            seen = .true.
            if (named) return
         endif
      enddo
      call fail('plot: index "'//name//'": no dataset of that name in "'//file//'"', iostat, iomsg)
      endfunction named_index

      subroutine rgb_item
      !< An `rgbimage` (`using x:y:r:g:b`) or `rgbalpha` (`x:y:r:g:b:a`) item on a regular grid, the components scaled
      !< from [0:rgbmax] to [0:255].
      real(R8P), allocatable        :: points(:,:) !< Values of the `using` fields (local: see `image_item`).
      real(R8P), allocatable        :: c(:,:,:) !< Channels on the grid (4, column, row).
      real(R8P), allocatable        :: z(:,:)   !< One channel on the grid.
      real(R8P), allocatable        :: xs(:)    !< Pixel centre abscissae.
      real(R8P), allocatable        :: ys(:)    !< Pixel centre ordinates.
      character(len=:), allocatable :: problem  !< Grid problem.
      integer(I4P)                  :: m        !< Channels read.
      integer(I4P)                  :: k        !< Channel counter.

      m = merge(4_I4P, 3_I4P, with == 'rgbalpha')
      if (.not. allocated(fields)) fields = plain_columns([(k, k = 1_I4P, m + 2_I4P)])
      if (size(fields) /= m + 2_I4P) then
         call fail('plot: '//with//' needs using x:y:r:g:b'//trim(merge(':a', '  ', m == 4_I4P)), iostat, iomsg)
         return
      endif
      call data%table(fields, set_index, every, points)
      do k = 1_I4P, m
         call regular_grid(points(:, 1), points(:, 2), points(:, 2_I4P + k) * (255.0_R8P / self%rgbmax), xs, ys, z, &
                           problem)
         if (len(problem) > 0) then
            call fail('plot: '//with//' of "'//file//'": '//problem, iostat, iomsg)
            return
         endif
         if (k == 1_I4P) then
            allocate(c(4, size(z, 1), size(z, 2)))
            c(4, :, :) = 255.0_R8P
         endif
         c(k, :, :) = z
      enddo
      call self%figure%rgbimage(c(1, :, :), c(2, :, :), c(3, :, :), xs, ys, title=title, alpha=c(4, :, :))
      endsubroutine rgb_item

      subroutine split_xtic(spec, column, iostat, iomsg, keyed, field, axis)
      !< Remove a last `using` field `xtic(...)` or `xticlabels(...)` (any gnuplot abbreviation between, `xticlabel`)
      !< from `spec`, returning its `field`: a column N
      !< (`column` N), or a string expression (`xtic(strcol(1) . ' K')`, `xtic("a")` the same text on every row;
      !< `column` 1), `column` 0 if none; `key(N)` (the row names of a spider plot) likewise, with `keyed` true.
      !< `x2tic(...)`, `ytic(...)`, `y2tic(...)` (and their `ticlabels` forms) likewise, the labels on that `axis`.
      character(len=:), allocatable, intent(inout) :: spec   !< `using` specification.
      integer(I4P),                  intent(out)   :: column !< Label column, 0 for none.
      integer(I4P),                  intent(inout) :: iostat !< Status.
      character(len=:), allocatable, intent(inout) :: iomsg  !< Error message.
      logical,                       intent(out)   :: keyed  !< The field is `key(N)`.
      type(expression_object),       intent(inout) :: field  !< Label field.
      character(len=2),              intent(out)   :: axis   !< Axis of the labels.
      character(len=:), allocatable                :: last   !< Last field.
      character(len=:), allocatable                :: head   !< Its function name.
      character(len=:), allocatable                :: inner  !< Argument of the label field.
      integer(I4P)                                 :: k      !< Character counter.
      integer(I4P)                                 :: depth  !< Parenthesis depth.
      integer(I4P)                                 :: cut    !< Last top-level colon, 0 for none.
      real(R8P)                                    :: v      !< Column number.

      column = 0_I4P
      keyed = .false.
      axis = 'x'
      depth = 0_I4P
      cut = 0_I4P
      do k = 1_I4P, len(spec, kind=I4P)
         select case (spec(k:k))
         case ('(')
            depth = depth + 1_I4P
         case (')')
            depth = depth - 1_I4P
         case (':')
            if (depth == 0_I4P) cut = k
         endselect
      enddo
      last = spec(cut + 1_I4P:)
      keyed = index(last, 'key(') == 1
      head = ''
      if (index(last, '(') > 1) head = last(1:index(last, '(') - 1)
      ! gnuplot's xtic$labels: xtic, xticl, ..., xticlabel, xticlabels
      if (gnuplot_abbreviates(head, 'xtic$labels')) then
         axis = 'x'
      elseif (gnuplot_abbreviates(head, 'x2tic$labels')) then
         axis = 'x2'
      elseif (gnuplot_abbreviates(head, 'ytic$labels')) then
         axis = 'y'
      elseif (gnuplot_abbreviates(head, 'y2tic$labels')) then
         axis = 'y2'
      elseif (.not. keyed) then
         return
      endif
      inner = last(index(last, '(') + 1:len(last) - 1)
      if (last(len(last):len(last)) /= ')') then
         call fail('plot: xtic needs a column number or an expression, xtic(1), found "'//last//'"', iostat, iomsg)
         return
      endif
      if (to_number(inner, v)) then
         if (v < 1.0_R8P .or. v /= aint(v)) then
            call fail('plot: xtic needs a column number, xtic(1), found "'//last//'"', iostat, iomsg)
            return
         endif
         column = int(v, I4P)
         call field%set_column(column)
      elseif (keyed) then
         call fail('plot: key needs a column number, key(1), found "'//last//'"', iostat, iomsg)
         return
      else
         call field%compile(inner, iostat, iomsg, degrees=self%figure%panels(self%figure%current)%degrees, &
                            symbols=self%symbols)
         if (iostat /= 0_I4P) then
            iomsg = 'plot: xtic: '//iomsg
            return
         endif
         column = 1_I4P
      endif
      if (cut == 0_I4P) then
         call fail('plot: xtic(N) labels a value: using Y:xtic(N) or X:Y:xtic(N)', iostat, iomsg)
         return
      endif
      spec = spec(1:cut - 1_I4P)
      endsubroutine split_xtic

      subroutine fill_words(words)
      !< Fill style words of an item after `fs`, up to the next item option or comma: `empty`, `transparent`, `solid`
      !< and its density, `border` and its color (`lc [rgb] C`, `-1`), `noborder`, `pattern` (refused later).
      character(len=:), allocatable, intent(out) :: words !< Fill style words.
      character(len=:), allocatable              :: w     !< Current word.
      character(len=:), allocatable              :: prev  !< Previous word.
      real(R8P)                                  :: v     !< Number.

      words = ''
      prev = ''
      do while (i < size(tokens, kind=I4P))
         if (tokens(i + 1_I4P)%kind == TOKEN_COMMA) exit
         w = tokens(i + 1_I4P)%text
         if (tokens(i + 1_I4P)%kind == TOKEN_STRING .or. prev == 'rgb' .or. prev == 'rgbcolor' .or. &
             ((prev == 'lc' .or. prev == 'linecolor') .and. w /= 'rgb' .and. w /= 'rgbcolor')) then
            ! a color: only after lc or rgb
            if (.not. (prev == 'lc' .or. prev == 'linecolor' .or. prev == 'rgb' .or. prev == 'rgbcolor')) exit
         elseif (is_word(w, 'empty transparent solid border noborder pattern segments')) then
         elseif ((w == 'lc' .or. w == 'linecolor') .and. prev == 'border') then
         elseif ((w == 'rgb' .or. w == 'rgbcolor') .and. (prev == 'lc' .or. prev == 'linecolor')) then
         elseif (to_number(w, v) .and. (prev == 'solid' .or. prev == 'border' .or. prev == 'pattern' .or. &
                                         prev == 'segments')) then
         else
            exit
         endif
         words = words//' '//w
         prev = w
         i = i + 1_I4P
      enddo
      if (len(words) == 0) call fail('plot: fs needs a fill style (empty, solid D, border, noborder)', iostat, iomsg)
      endsubroutine fill_words

      function fill_ok(words) result(ok)
      !< Whether the fill style `words` are understood; fails the plot if not.
      character(len=*), intent(in)  :: words !< Fill style words.
      logical                       :: ok    !< Understood.
      type(style_object)            :: probe !< Style the words are tried on.
      character(len=:), allocatable :: bad   !< Unknown word.

      call fill_style(words, probe, bad)
      ok = len(bad) == 0
      if (.not. ok) call fail('plot: unsupported fill style "'//bad//'"', iostat, iomsg)
      endfunction fill_ok

      function substring_range(text) result(ok)
      !< The substring range `i:j` (`[i:j]`, `[i:]`, `[:j]`) of a column header title into `head_piece`.
      character(len=*), intent(in) :: text !< Range, brackets removed.
      logical                      :: ok   !< Success.
      integer(I4P)                 :: c    !< Colon.
      real(R8P)                    :: v    !< End.

      ok = .false.
      c = index(text, ':', kind=I4P)
      if (c == 0_I4P) then
         call fail('plot: title: columnhead(N)[i:j] expected, found "['//text//']"', iostat, iomsg)
         return
      endif
      head_piece = [1_I4P, huge(1_I4P)]
      if (len_trim(text(1:c - 1_I4P)) > 0 .and. trim(adjustl(text(1:c - 1_I4P))) /= '*') then
         call self%range_value(text(1:c - 1_I4P), v, iostat, iomsg)
         if (iostat /= 0_I4P) return
         head_piece(1) = max(1_I4P, int(v, I4P))
      endif
      if (len_trim(text(c + 1_I4P:)) > 0 .and. trim(adjustl(text(c + 1_I4P:))) /= '*') then
         call self%range_value(text(c + 1_I4P:), v, iostat, iomsg)
         if (iostat /= 0_I4P) return
         head_piece(2) = int(v, I4P)
      endif
      ok = .true.
      endfunction substring_range

      function header_title(set) result(name)
      !< Header of the column titling the item in dataset `set`: `title_column`, or the first column the y field reads;
      !< empty if none, as gnuplot.
      integer(I4P), intent(in)      :: set  !< Dataset.
      character(len=:), allocatable :: name !< Title.
      integer(I4P)                  :: c    !< Column.
      type(expression_object)       :: y    !< y field on the header.
      character(len=:), allocatable :: names(:) !< Header names.

      c = title_column
      if (c == 0_I4P) then
         call data%header_names(set, names)
         y = fields(2)%resolve(names)
         c = y%first_column()
      endif
      name = data%column_header(set, c)
      endfunction header_title

      subroutine sample_functions
      !< Sample the functions at `self%samples` abscissae over the x range of the data before its tick extension (the
      !< user ends, the data extent, else the axis default range): evenly, in log x on a log axis. A function on the
      !< second x axis over its range, that of the first x axis if it has neither data nor ends of its own (gnuplot).
      real(R8P), allocatable :: xs(:)     !< Sample abscissae.
      real(R8P), allocatable :: xs2(:)    !< Sample abscissae on the second x axis.
      real(R8P), allocatable :: ys(:)     !< Sample values.
      real(R8P)              :: xmin(2)   !< Smallest data abscissa, per x axis.
      real(R8P)              :: xmax(2)   !< Largest data abscissa, per x axis.
      real(R8P)              :: ymin(2)   !< Smallest data ordinates, unused.
      real(R8P)              :: ymax(2)   !< Largest data ordinates, unused.
      real(R8P)              :: lo        !< Range start.
      real(R8P)              :: hi        !< Range end.
      logical                :: found(2)  !< Any data per y axis.
      logical                :: xfound(2) !< Any data per x axis.
      logical                :: ok(2)     !< Placeable samples, per x axis.
      integer(I4P)           :: n         !< Samples.
      integer(I4P)           :: f         !< Function counter.
      integer(I4P)           :: j         !< Sample counter.

      n = self%samples
      associate(panel => self%figure%panels(self%figure%current))
         if (self%parametric .and. .not. panel%polar) then
            ! gnuplot `set parametric`: x(t), y(t) over trange, [-5:5] by default
            lo = -5.0_R8P
            hi = 5.0_R8P
            if (panel%taxis%min_fixed) lo = panel%taxis%min_user
            if (panel%taxis%max_fixed) hi = panel%taxis%max_user
            if (panel%taxis%plot_min_fixed) lo = panel%taxis%plot_min
            if (panel%taxis%plot_max_fixed) hi = panel%taxis%plot_max
            allocate(xs(n), ys(n))
            do f = 1_I4P, size(functions, kind=I4P)
               do j = 1_I4P, n
                  xs(j) = lo + real(j - 1_I4P, R8P) * ((hi - lo) / real(n - 1_I4P, R8P))
               enddo
               xs(n) = hi
               do j = 1_I4P, n
                  ys(j) = yfunctions(f)%value_at(xs(j))
                  xs(j) = functions(f)%value_at(xs(j))
               enddo
               call panel%resample(slots(f), xs, ys)
            enddo
            return
         endif
         if (panel%polar) then
            ! over trange, a full turn by default, as gnuplot
            lo = 0.0_R8P
            hi = merge(360.0_R8P, 2.0_R8P * acos(-1.0_R8P), panel%degrees)
            if (panel%taxis%min_fixed) lo = panel%taxis%min_user
            if (panel%taxis%max_fixed) hi = panel%taxis%max_user
            ! an inline [t=a:b] of this plot
            if (panel%taxis%plot_min_fixed) lo = panel%taxis%plot_min
            if (panel%taxis%plot_max_fixed) hi = panel%taxis%plot_max
            allocate(xs(n), ys(n))
            do j = 1_I4P, n
               xs(j) = lo + real(j - 1_I4P, R8P) * ((hi - lo) / real(n - 1_I4P, R8P))
            enddo
            xs(n) = hi
            do f = 1_I4P, size(functions, kind=I4P)
               do j = 1_I4P, n
                  ys(j) = functions(f)%value_at(xs(j))
               enddo
               call panel%resample(slots(f), xs, ys)
            enddo
            return
         endif
         ! the functions are still empty: the extent is the data one
         call panel%axes_extent(xmin, xmax, ymin, ymax, found, xfound)
         call panel%xaxis%range_of(xmin(1), xmax(1), xfound(1), lo, hi)
         call sample_grid(panel%xaxis%log, lo, hi, xs, ok(1))
         if (xfound(2) .or. panel%x2axis%min_fixed .or. panel%x2axis%max_fixed .or. panel%x2axis%plot_min_fixed .or. &
             panel%x2axis%plot_max_fixed) call panel%x2axis%range_of(xmin(2), xmax(2), xfound(2), lo, hi)
         call sample_grid(panel%x2axis%log, lo, hi, xs2, ok(2))
         allocate(ys(n))
         do f = 1_I4P, size(functions, kind=I4P)
            associate(series => panel%series(slots(f)))
               if (any(own_set(:, f))) then
                  ! its own sampling range, the axis ends for those not given
                  block
                     real(R8P), allocatable :: grid(:) !< Abscissae of the item.
                     real(R8P)              :: ends(2) !< Item range.
                     logical                :: good    !< Placeable samples.

                     if (.not. ok(merge(2_I4P, 1_I4P, series%x2))) cycle
                     if (series%x2) then
                        ends = [xs2(1), xs2(size(xs2))]
                     else
                        ends = [xs(1), xs(size(xs))]
                     endif
                     where (own_set(:, f)) ends = own_range(:, f)
                     call sample_grid(merge(panel%x2axis%log, panel%xaxis%log, series%x2), ends(1), ends(2), grid, &
                                      good)
                     if (.not. good) cycle
                     do j = 1_I4P, n
                        ys(j) = functions(f)%value_at(grid(j))
                     enddo
                     call panel%resample(slots(f), grid, ys)
                  endblock
                  cycle
               endif
               ! a log axis on a non-positive range is reported by the rendering
               if (.not. ok(merge(2_I4P, 1_I4P, series%x2))) cycle
               do j = 1_I4P, n
                  if (series%x2) then
                     ys(j) = functions(f)%value_at(xs2(j))
                  else
                     ys(j) = functions(f)%value_at(xs(j))
                  endif
               enddo
               if (sharpens(f)) then
                  block
                     real(R8P), allocatable :: sx(:) !< Sharpened abscissae.
                     real(R8P), allocatable :: sy(:) !< Sharpened values.

                     if (series%x2) then
                        call sharpened(functions(f), xs2, ys, sx, sy)
                     else
                        call sharpened(functions(f), xs, ys, sx, sy)
                     endif
                     call panel%resample(slots(f), sx, sy)
                  endblock
               elseif (series%x2) then
                  call panel%resample(slots(f), xs2, ys)
               else
                  call panel%resample(slots(f), xs, ys)
               endif
            endassociate
         enddo
      endassociate
      endsubroutine sample_functions

      subroutine sample_grid(log, lo, hi, xs, ok)
      !< `self%samples` abscissae from `lo` to `hi`, evenly, in log x on a `log` axis; `ok` false (no samples) for a log
      !< axis on a non-positive range.
      logical,                intent(in)  :: log   !< Log axis.
      real(R8P),              intent(in)  :: lo    !< Range start.
      real(R8P),              intent(in)  :: hi    !< Range end.
      real(R8P), allocatable, intent(out) :: xs(:) !< Sample abscissae.
      logical,                intent(out) :: ok    !< Samples placeable.
      real(R8P)                           :: a     !< Range start, log10 on a log axis.
      real(R8P)                           :: step  !< Sample spacing, in log10 on a log axis.
      integer(I4P)                        :: m     !< Samples.
      integer(I4P)                        :: j     !< Sample counter.

      m = self%samples
      ok = .not. (log .and. (lo <= 0.0_R8P .or. hi <= 0.0_R8P))
      if (.not. ok) return
      a = lo
      if (log) a = log10(lo)
      ! never hi - lo, which overflows on extreme ends
      if (log) then
         step = log10(hi) / real(m - 1_I4P, R8P) - a / real(m - 1_I4P, R8P)
      else
         step = hi / real(m - 1_I4P, R8P) - lo / real(m - 1_I4P, R8P)
      endif
      allocate(xs(m))
      do j = 1_I4P, m
         xs(j) = a + real(j - 1_I4P, R8P) * step
         if (log) xs(j) = 10.0_R8P**xs(j)
      enddo
      ! exact ends: a sample past an autoscaled end would widen the axis by a rounding error
      xs(1) = lo
      xs(m) = hi
      endsubroutine sample_grid
   endsubroutine plot_items

   recursive subroutine call_command(self, tokens, is_call, iostat, iomsg)
   !< gnuplot `load FILE` and `call FILE [ARG1 ... ARG9]`: run the script FILE (a string expression), ARG0 its name
   !< and, for `call`, ARGC the number of arguments and ARG1 to ARG9 their texts (a quoted string as it is, a number
   !< as written, a variable or a parenthesized expression its value: a string as it is, an integer as it is, a real
   !< as `%g`; any other word as it is, gnuplot's `call "f" sub1`), ARGV their values (numbers for the numbers, as
   !< gnuplot's prepare_call); those variables are restored after it. The script is watched as a data file is.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Statement tokens, the command first.
   logical,                       intent(in)    :: is_call   !< `call`, else `load`.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   character(len=*), parameter                  :: DIGITS = '0123456789' !< Argument numbers.
   character(len=*), parameter                  :: NAME_CHARS = &
                                                   UNAME_CHARS !< Names.
   type(saved_variable)                         :: saved(11) !< ARG0 to ARG9 and ARGC before the call.
   type(saved_array)                            :: saved_argv !< ARGV before the call.
   type(token_object), allocatable              :: args(:)   !< Argument texts.
   type(token_object)                           :: arg       !< One argument.
   type(value_object), allocatable              :: values(:) !< Argument values (ARGV).
   type(value_object)                           :: typed     !< One argument value.
   character(len=:), allocatable                :: file      !< Script.
   character(len=:), allocatable                :: command   !< `load` or `call`.
   character(len=:), allocatable                :: value     !< Value of an argument.
   character(len=:), allocatable                :: message   !< Error of the script.
   integer(I4P)                                 :: i         !< Token counter.
   integer(I4P)                                 :: k         !< Argument counter.
   integer(I4P)                                 :: status    !< Status of the script.
   logical                                      :: is_string !< A string value.
   real(R8P)                                    :: number    !< A numeric argument.

   iostat = 0_I4P
   iomsg = ''
   command = merge('call', 'load', is_call)
   if (size(tokens) < 2) then
      call fail(command//': a script file is expected', iostat, iomsg)
      return
   endif
   i = 2_I4P
   if (.not. self%string_expression(tokens, i, file, iostat, iomsg)) then
      iomsg = command//': '//iomsg
      return
   endif
   allocate(args(0), values(0))
   do while (i < size(tokens, kind=I4P))
      i = i + 1_I4P
      if (.not. is_call) then
         call fail('load: unexpected "'//tokens(i)%text//'" (call passes arguments)', iostat, iomsg)
         return
      endif
      if (tokens(i)%kind == TOKEN_STRING) then
         arg%text = tokens(i)%text
         ! by components: nvfortran 26.9 miscompiles constructors of types with deferred-length components
         typed = value_object()
         typed%is_string = .true.
         typed%s = arg%text
      elseif (tokens(i)%kind /= TOKEN_WORD) then
         call fail('call: unexpected "'//tokens(i)%text//'"', iostat, iomsg)
         return
      elseif (to_number(tokens(i)%text, number)) then
         ! a number as written; its value in ARGV
         arg%text = tokens(i)%text
         typed = value_object()
         typed%r = number
      elseif (verify(tokens(i)%text, NAME_CHARS) == 0 .and. .not. self%symbols%defined(tokens(i)%text)) then
         ! a word that names no variable: the word itself, gnuplot's pre-version 5 wrapping
         arg%text = tokens(i)%text
         typed = value_object()
         typed%is_string = .true.
         typed%s = arg%text
      else
         call self%symbols%evaluate_constant(tokens(i)%text, typed, iostat, iomsg, &
                                             degrees=self%figure%panels(self%figure%current)%degrees)
         if (iostat /= 0_I4P) then
            iomsg = 'call: '//iomsg
            return
         endif
         if (typed%is_string) then
            arg%text = typed%s
         elseif (typed%is_int) then
            arg%text = int_str(typed%i)
         else
            arg%text = c_real('', 0_I4P, -1_I4P, 'g', typed%r)
         endif
      endif
      if (size(args) == 9) then
         call fail('call: at most 9 arguments', iostat, iomsg)
         return
      endif
      call push(args, arg)
      call push(values, typed)
   enddo
   do k = 0_I4P, 9_I4P
      call self%symbols%save_variable('ARG'//DIGITS(k + 1_I4P:k + 1_I4P), saved(k + 1_I4P))
   enddo
   call self%symbols%save_variable('ARGC', saved(11))
   call self%symbols%save_array('ARGV', saved_argv)
   call self%symbols%set_string('ARG0', file)
   if (is_call) then
      do k = 1_I4P, 9_I4P
         if (k <= size(args, kind=I4P)) then
            call self%symbols%set_string('ARG'//DIGITS(k + 1_I4P:k + 1_I4P), args(k)%text)
         else
            call self%symbols%set_string('ARG'//DIGITS(k + 1_I4P:k + 1_I4P), '')
         endif
      enddo
      call self%symbols%set_value('ARGC', real(size(args), R8P), is_int=.true.)
      block
         type(value_list) :: argv !< The argument values.

         allocate(argv%set(size(values)))
         argv%set = .true.
         call move_alloc(values, argv%items)
         call self%symbols%store_array('ARGV', argv, iostat, iomsg)
         if (iostat /= 0_I4P) return
      endblock
   endif
   call self%register_file(file)
   call self%run_file(file, status, message)
   ! the ARG variables back, also after an error
   do k = 1_I4P, 11_I4P
      call self%symbols%restore(saved(k))
   enddo
   call self%symbols%restore_array(saved_argv)
   iostat = status
   iomsg = message
   endsubroutine call_command

   subroutine pause_command(self, tokens, iostat, iomsg)
   !< gnuplot `pause SECONDS ["message"]`: the message on the standard error, then a wait of SECONDS (0: none); -1 waits
   !< for a line on the standard input (its end does not wait). `pause mouse [EVENTS] ["message"]`: no mouse here, the
   !< message only, as gnuplot on a terminal without one. With a plot in a loop, `while (1) { plot ...; pause 5 }`, the
   !< output is rewritten every 5 s: gnuplot 6.0's live idiom.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Tokens after `pause`.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   character(len=:), allocatable                :: message   !< Message, unallocated if none.
   character(len=256)                           :: line      !< Line read.
   real(R8P)                                    :: seconds   !< Time to wait.
   integer(I4P)                                 :: i         !< Token counter.
   integer(I4P)                                 :: last      !< Last token of the time.
   integer(I4P)                                 :: ios       !< Read status.
   logical                                      :: mouse     !< `pause mouse`.

   iostat = 0_I4P
   iomsg = ''
   if (size(tokens) == 0) then
      call fail('pause: a time in seconds, -1 or mouse is expected', iostat, iomsg)
      return
   endif
   mouse = keyword(tokens(1)%text, 'mouse', 2_I4P) .and. tokens(1)%kind == TOKEN_WORD
   i = 1_I4P
   seconds = 0.0_R8P
   if (mouse) then
      ! the events (keypress, button1, button2, button3, close, any, comma separated) wait for nothing here
      i = 2_I4P
      do while (i <= size(tokens, kind=I4P))
         if (tokens(i)%kind == TOKEN_STRING) exit
         if (tokens(i)%kind == TOKEN_WORD) then
            if (.not. is_word(tokens(i)%text, 'keypress button1 button2 button3 close any')) then
               call fail('pause mouse: unknown event "'//tokens(i)%text//'"', iostat, iomsg)
               return
            endif
         endif
         i = i + 1_I4P
      enddo
   else
      last = expression_end(tokens, 1_I4P)
      call self%symbols%constant(expression_source(tokens(1:last)), seconds, iostat, iomsg, &
                                 degrees=self%figure%panels(self%figure%current)%degrees)
      if (iostat /= 0_I4P) then
         iomsg = 'pause: '//iomsg
         return
      endif
      i = last + 1_I4P
   endif
   if (i <= size(tokens, kind=I4P)) then
      if (.not. self%string_expression(tokens, i, message, iostat, iomsg)) then
         iomsg = 'pause: '//iomsg
         return
      endif
      if (i < size(tokens, kind=I4P)) then
         call fail('pause: unexpected "'//tokens(i + 1_I4P)%text//'"', iostat, iomsg)
         return
      endif
   endif
   flush(output_unit)
   if (seconds < 0.0_R8P) then
      if (allocated(message)) write(error_unit, '(A)', advance='no') message
      flush(error_unit)
      read(input_unit, '(A)', iostat=ios) line
   else
      if (allocated(message)) write(error_unit, '(A)') message
      flush(error_unit)
      if (seconds > 0.0_R8P) call sleep_ms(nint(1000.0_R8P * min(seconds, 1.0e9_R8P), I8P))
   endif
   endsubroutine pause_command

   subroutine reset_command(self, tokens, iostat, iomsg)
   !< gnuplot `reset [session|errors|bind]`: the plot settings back to their defaults, as gnuplot 6.0 keeps the
   !< terminal, the output, `set fit`, `set print`, `set table`, the multiplot, the linetypes (`set colorsequence`) and,
   !< a quirk kept, `set style data`. `reset session` also forgets the user variables, functions and arrays (the
   !< script arguments kept) and restores the default linetypes; `reset errors` and `reset bind` do nothing here.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Tokens after `reset`.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   character(len=*), parameter                  :: DIGITS = '0123456789' !< Argument numbers.
   type(axes_object)                            :: fresh     !< Default panel.
   type(axes_object)                            :: kept      !< The panel before.
   type(saved_variable)                         :: saved(11) !< ARG0 to ARG9 and ARGC.
   type(saved_array)                            :: argv      !< ARGV.
   integer(I4P)                                 :: k         !< Counter.

   iostat = 0_I4P
   iomsg = ''
   if (size(tokens) > 1) then
      call fail('reset: unexpected "'//tokens(2)%text//'"', iostat, iomsg)
      return
   endif
   if (size(tokens) == 1) then
      if (is_word(tokens(1)%text, 'errors bind')) return
      if (tokens(1)%text /= 'session') then
         call fail('reset: session, errors or bind expected, found "'//tokens(1)%text//'"', iostat, iomsg)
         return
      endif
      do k = 0_I4P, 9_I4P
         call self%symbols%save_variable('ARG'//DIGITS(k + 1_I4P:k + 1_I4P), saved(k + 1_I4P))
      enddo
      call self%symbols%save_variable('ARGC', saved(11))
      call self%symbols%save_array('ARGV', argv)
      ! the datablocks are variables too: kept, as gnuplot's
      call clear_keeping_datablocks
      do k = 1_I4P, 11_I4P
         call self%symbols%restore(saved(k))
      enddo
      call self%symbols%restore_array(argv)
      ! gnuplot's own variables stay
      call gnuplot_values(self)
      ! program settings `reset` leaves, as gnuplot's session start
      overflow_mode = OVERFLOW_FLOAT
      self%minus_sign = .false.
      self%micro = .false.
   endif
   ! the current panel: its plot, place and linetypes kept
   kept = self%figure%panels(self%figure%current)
   self%figure%panels(self%figure%current) = fresh
   call self%figure%panels(self%figure%current)%set_defaults
   if (allocated(kept%series)) self%figure%panels(self%figure%current)%series = kept%series
   self%figure%panels(self%figure%current)%origin = kept%origin
   self%figure%panels(self%figure%current)%size = kept%size
   ! gnuplot's linetypes (and `set colorsequence`) survive `reset`, not `reset session`
   if (size(tokens) == 0) then
      if (allocated(kept%linecolors)) self%figure%panels(self%figure%current)%linecolors = kept%linecolors
      self%figure%panels(self%figure%current)%lt_lw = kept%lt_lw
      self%figure%panels(self%figure%current)%lt_dt = kept%lt_dt
      self%figure%panels(self%figure%current)%lt_pt = kept%lt_pt
      self%figure%panels(self%figure%current)%lt_ps = kept%lt_ps
   endif
   self%function_style = 'lines'
   self%autotitle = 'file'
   if (allocated(self%line_styles)) deallocate(self%line_styles)
   allocate(self%line_styles(0))
   self%separator = ''
   self%missing = ''
   self%comments = '#'
   self%column_headers = .false.
   self%samples = 100_I4P
   self%isosamples = 10_I4P
   self%isosamples1 = 10_I4P
   self%samples2 = 100_I4P
   self%uv_range = reshape([-5.0_R8P, 5.0_R8P, -5.0_R8P, 5.0_R8P], [2, 2])
   self%rgbmax = 255.0_R8P
   self%chi_fraction = 0.6_R8P
   self%polar_grid = polar_grid_type()
   self%timefmt = '%d/%m/%y,%H:%M'
   self%symbols%timefmt = self%timefmt
   self%time_data = .false.
   self%dummy = ''
   self%dummies = ''
   self%parametric = .false.
   call default_styles(self)
   contains
      subroutine clear_keeping_datablocks
      !< Forget every symbol but the datablocks.
      type(symbols_object) :: blocks !< The datablocks.
      character(len=:), allocatable :: names(:) !< Datablock names.
      character(len=:), allocatable :: text     !< Datablock lines.
      logical                       :: found    !< Found.
      integer(I4P)                  :: j        !< Counter.

      call self%symbols%datablock_names(names)
      do j = 1_I4P, size(names, kind=I4P)
         call self%symbols%string_of(trim(names(j)), text, found)
         call blocks%set_string(trim(names(j)), text)
      enddo
      blocks%timefmt = self%symbols%timefmt
      self%symbols = blocks
      endsubroutine clear_keeping_datablocks
   endsubroutine reset_command

   subroutine write_table(self, iostat, iomsg)
   !< `set table`: the points of the current panel's series as gnuplot 6.0 tabulates them, a block per series (`#
   !< Curve K of N, M points`, its title, the column names) whose rows are the values in the axis formats (`set
   !< format`, `% h` by default) and a flag, `i` in range, `o` outside a fixed range, `u` undefined; the columns: `x y
   !< type`, with `ylow yhigh` (y error bars), `xlow xhigh` (x error bars, boxes), both (xy error bars), `y1 y2`
   !< (filled curves between two curves) or `x y label` (labels).
   class(script_object),          intent(inout) :: self   !< Interpreter.
   integer(I4P),                  intent(out)   :: iostat !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg  !< Error message.
   character(len=:), allocatable                :: text   !< Table.
   character(len=:), allocatable                :: xfmt   !< x format.
   character(len=:), allocatable                :: yfmt   !< y format.
   character(len=:), allocatable                :: names  !< Column names.
   character(len=:), allocatable                :: row    !< One row.
   character(len=:), allocatable                :: old    !< Datablock lines before.
   character(len=1)                             :: flag   !< Point flag.
   logical                                      :: found  !< Datablock found.
   integer(I4P)                                 :: n      !< Series.
   integer(I4P)                                 :: k      !< Series counter.
   integer(I4P)                                 :: p      !< Point counter.
   integer(I4P)                                 :: unit   !< File unit.
   character(len=:), allocatable                :: zfmt   !< z format.
   integer(I4P)                                 :: nsurf  !< Surfaces of a splot.
   integer(I4P)                                 :: isurf  !< Surface counter.
   integer(I4P)                                 :: d      !< Dataset counter.
   integer(I4P)                                 :: j      !< Scan counter.
   integer(I4P)                                 :: q      !< Scan.
   integer(I4P)                                 :: curve  !< Iso-curve number within its surface.

   iostat = 0_I4P
   iomsg = ''
   text = ''
   associate(panel => self%figure%panels(self%figure%current))
      n = 0_I4P
      if (allocated(panel%series)) n = size(panel%series, kind=I4P)
      if (panel%three_d) then
         ! splot, as gnuplot 6.0 tabulates it: a surface per dataset of each item (`# Surface K of N surfaces`, the item
         ! title on its first), its grid scans (the data ones last first, gnuplot's order) as `# IsoCurve J, M points`,
         ! rows `x y z type`
         xfmt = axis_format(panel%xaxis%tics%format, panel%xaxis%time)
         yfmt = axis_format(panel%yaxis%tics%format, panel%yaxis%time)
         zfmt = axis_format(panel%zaxis%tics%format, panel%zaxis%time)
         nsurf = 0_I4P
         do k = 1_I4P, n
            if (.not. allocated(panel%series(k)%scans)) cycle
            if (panel%series(k)%grid_scans > 0_I4P) &
               nsurf = nsurf + maxval(panel%series(k)%scan_sets(1:panel%series(k)%grid_scans)) - &
                       minval(panel%series(k)%scan_sets(1:panel%series(k)%grid_scans)) + 1_I4P
         enddo
         isurf = 0_I4P
         do k = 1_I4P, n
            associate(series => panel%series(k))
               if (.not. allocated(series%scans)) cycle
               if (series%grid_scans == 0_I4P) cycle
               do d = minval(series%scan_sets(1:series%grid_scans)), maxval(series%scan_sets(1:series%grid_scans))
                  ! gnuplot's print_3dtable: a blank line before each block
                  text = text//new_line('a')//'# Surface '//int_str(int(isurf, I8P))//' of '// &
                         int_str(int(nsurf, I8P))//' surfaces'//new_line('a')
                  if (d == minval(series%scan_sets(1:series%grid_scans)) .and. len(series%title) > 0) &
                     text = text//new_line('a')//'# Curve title: "'//series%title//'"'//new_line('a')
                  if (panel%view3d%surface .and. .not. series%no_surface) then
                     curve = 0_I4P
                     do j = 1_I4P, series%grid_scans
                        q = merge(series%grid_scans + 1_I4P - j, j, series%data_scans)
                        if (series%scan_sets(q) /= d) cycle
                        text = text//new_line('a')//'# IsoCurve '//int_str(int(curve, I8P))//', '// &
                               int_str(int(series%scans(2, q) - series%scans(1, q) + 1_I4P, I8P))//' points'// &
                               new_line('a')//'# x y z type'//new_line('a')
                        do p = series%scans(1, q), series%scans(2, q)
                           flag = 'i'
                           if (.not. (ieee_is_finite(series%x(p)) .and. ieee_is_finite(series%y(p)) .and. &
                                      ieee_is_finite(series%z(p)))) then
                              flag = 'u'
                           elseif (outside(series%x(p), panel%xaxis) .or. outside(series%y(p), panel%yaxis) .or. &
                                   outside(series%z(p), panel%zaxis)) then
                              flag = 'o'
                           endif
                           text = text//number(series%x(p), xfmt)//' '//number(series%y(p), yfmt)//' '// &
                                  number(series%z(p), zfmt)//' '//flag//new_line('a')
                        enddo
                        curve = curve + 1_I4P
                     enddo
                     text = text//new_line('a')
                  endif
                  ! the contour lines (set contour): a header per level, a blank line after each chunk
                  if (panel%contour%on .and. .not. series%no_contours) then
                     block
                        real(R8P), allocatable :: cx(:), cy(:), cz(:) !< Lines, NaN separated.
                        real(R8P), allocatable :: level(:)            !< Level of each chunk.
                        logical,   allocatable :: first(:)            !< First chunk of its level.
                        integer(I4P)           :: c                   !< Chunk counter.
                        integer(I4P)           :: r                   !< Row.
                        integer(I4P)           :: number_level        !< Level number.

                        call surface_contours(panel, series, d, cx, cy, cz, level, first)
                        r = 0_I4P
                        number_level = 0_I4P
                        do c = 1_I4P, size(level, kind=I4P)
                           if (first(c)) then
                              text = text//new_line('a')//'# Contour '//int_str(int(number_level, I8P))// &
                                     ', label: '//contour_label(panel%contour%format, level(c))//new_line('a')
                              number_level = number_level + 1_I4P
                           endif
                           do
                              r = r + 1_I4P
                              if (r > size(cx, kind=I4P)) exit
                              if (.not. ieee_is_finite(cx(r))) exit
                              text = text//number(cx(r), xfmt)//' '//number(cy(r), yfmt)//' '// &
                                     number(cz(r), zfmt)//' '//new_line('a')
                           enddo
                           text = text//new_line('a')
                        enddo
                     endblock
                  endif
                  isurf = isurf + 1_I4P
               enddo
            endassociate
         enddo
         n = 0_I4P
      endif
      do k = 1_I4P, n
         associate(series => panel%series(k))
            xfmt = axis_format(panel%xaxis%tics%format, panel%xaxis%time)
            yfmt = axis_format(panel%yaxis%tics%format, panel%yaxis%time)
            if (series%x2) xfmt = axis_format(panel%x2axis%tics%format, panel%x2axis%time)
            if (series%y2) yfmt = axis_format(panel%y2axis%tics%format, panel%y2axis%time)
            select case (series%style%with)
            case (WITH_LABELS)
               names = 'x y label type'
            case (WITH_YERRORBARS, WITH_YERRORLINES)
               names = 'x y ylow yhigh type'
            case (WITH_XERRORBARS, WITH_XERRORLINES, WITH_BOXES)
               names = 'x y xlow xhigh type'
            case (WITH_XYERRORBARS, WITH_XYERRORLINES)
               names = 'x y xlow xhigh ylow yhigh type'
            case default
               names = 'x y type'
               if (series%style%with == WITH_FILLEDCURVES .and. allocated(series%ylow)) names = 'x y1 y2 type'
            endselect
            if (k > 1_I4P) text = text//new_line('a')//new_line('a')
            text = text//'# Curve '//int_str(int(k - 1_I4P, I8P))//' of '//int_str(int(n, I8P))//', '// &
                   int_str(int(size(series%x), I8P))//' points'//new_line('a')//'# Curve title: "'// &
                   series%title//'"'//new_line('a')//'# '//names//new_line('a')
            do p = 1_I4P, size(series%x, kind=I4P)
               row = number(series%x(p), xfmt)//' '//number(series%y(p), yfmt)
               ! a histogram: its own values, not the stacked tops (gnuplot)
               if (series%style%with == WITH_HISTOGRAMS .and. allocated(series%values)) then
                  if (p <= size(series%values, kind=I4P)) &
                     row = number(series%x(p), xfmt)//' '//number(series%values(p), yfmt)
               endif
               select case (names)
               case ('x y label type')
                  row = row//' "'//trim(series%texts(p))//'"'
               case ('x y ylow yhigh type')
                  row = row//' '//number(series%ylow(p), yfmt)//' '//number(series%yhigh(p), yfmt)
               case ('x y xlow xhigh type')
                  if (allocated(series%xlow) .and. series%style%with /= WITH_BOXES) then
                     row = row//' '//number(series%xlow(p), xfmt)//' '//number(series%xhigh(p), xfmt)
                  else
                     ! boxes: the abscissa twice, as gnuplot 6.0 tabulates them
                     row = row//' '//number(series%x(p), xfmt)//' '//number(series%x(p), xfmt)
                  endif
               case ('x y xlow xhigh ylow yhigh type')
                  row = row//' '//number(series%xlow(p), xfmt)//' '//number(series%xhigh(p), xfmt)//' '// &
                        number(series%ylow(p), yfmt)//' '//number(series%yhigh(p), yfmt)
               case ('x y1 y2 type')
                  row = row//' '//number(series%ylow(p), yfmt)
               endselect
               if (names /= 'x y label type') then
                  flag = 'i'
                  if (.not. (ieee_is_finite(series%x(p)) .and. ieee_is_finite(series%y(p)))) then
                     flag = 'u'
                  else
                     ! no merge of the axes: gfortran 16 frees their components twice
                     if (series%x2) then
                        if (outside(series%x(p), panel%x2axis)) flag = 'o'
                     elseif (outside(series%x(p), panel%xaxis)) then
                        flag = 'o'
                     endif
                     if (series%y2) then
                        if (outside(series%y(p), panel%y2axis)) flag = 'o'
                     elseif (outside(series%y(p), panel%yaxis)) then
                        flag = 'o'
                     endif
                  endif
                  row = row//'  '//flag
               endif
               text = text//row//new_line('a')
            enddo
         endassociate
      enddo
   endassociate
   ! a blank line before and after the plot, two between its curves
   if (n > 0_I4P) text = new_line('a')//text//new_line('a')
   if (is_datablock(self%table_file)) then
      call self%symbols%string_of(self%table_file, old, found)
      call self%symbols%set_string(self%table_file, old//text)
   elseif (len(text) == 0) then
      return
   elseif (self%table_file == '-') then
      ! the last newline ends the record
      write(output_unit, '(A)') text(1:len(text) - 1)
   else
      open(newunit=unit, file=self%table_file, position='append', action='write', iostat=iostat)
      if (iostat /= 0_I4P) then
         call fail('set table: cannot write "'//self%table_file//'"', iostat, iomsg)
         return
      endif
      write(unit, '(A)') text(1:len(text) - 1)
      close(unit)
   endif
   contains
      pure function axis_format(format, time) result(f)
      !< The table format of an axis: its `set format`, `% h` if none or a time format.
      character(len=:), allocatable, intent(in) :: format !< Axis label format.
      logical,                       intent(in) :: time   !< A time axis.
      character(len=:), allocatable             :: f      !< Format.

      f = '% h'
      if (allocated(format)) then
         if (len(format) > 0 .and. .not. time) f = format
      endif
      endfunction axis_format

      pure function number(v, format) result(t)
      !< `v` in `format`, `NaN` if undefined (after a blank with the space flag, as a number would have).
      real(R8P),        intent(in)  :: v      !< Value.
      character(len=*), intent(in)  :: format !< Format.
      character(len=:), allocatable :: t      !< Text.
      character(len=:), allocatable :: sup    !< `%h` exponent.
      integer(I8P)                  :: mantissa !< Decimal mantissa.
      integer(I4P)                  :: e        !< Decimal exponent.
      integer(I4P)                  :: p        !< First non-blank character.
      integer(I4P)                  :: q        !< First blank after it.

      if (.not. ieee_is_finite(v)) then
         t = 'NaN'
         if (index(format, '% ') > 0) t = ' NaN'
         return
      endif
      call decimal_of(v, mantissa, e)
      call format_decimal(table_conversions(format), mantissa, e, t, sup)
      if (len(sup) > 0) t = t//'e'//sup
      ! a negative zero keeps its sign, as C's printf (x*y at y = 0 and x < 0): right before the digits, over the plus
      ! flag or a blank of the padding (space flag, width), else added (a left-justified field keeps its width)
      if (v == 0.0_R8P .and. sign(1.0_R8P, v) < 0.0_R8P .and. len_trim(t) > 0) then
         p = verify(t, ' ')
         if (t(p:p) == '+') then
            t(p:p) = '-'
         elseif (t(p:p) /= '-') then
            q = scan(t(p:), ' ')
            if (p > 1_I4P) then
               t(p - 1_I4P:p - 1_I4P) = '-'
            elseif (q > 0_I4P) then
               ! left-justified: a blank of the padding after the digits taken
               q = p + q - 1_I4P
               t = '-'//t(1:q - 1_I4P)//t(q + 1_I4P:)
            else
               t = '-'//t
            endif
         endif
      endif
      endfunction number

      pure function table_conversions(format) result(f)
      !< `format` with its `%h`/`%H` conversions as `%g`/`%G`: a table is plain text, as gnuplot 6.0 writes it.
      character(len=*), intent(in)  :: format !< Format.
      character(len=:), allocatable :: f      !< Table format.
      integer(I4P)                  :: i      !< Character counter.

      f = format
      i = 1_I4P
      do while (i < len(f, kind=I4P))
         if (f(i:i) == '%') then
            i = i + 1_I4P
            if (f(i:i) == '%') then
               i = i + 1_I4P
               cycle
            endif
            do while (i < len(f, kind=I4P) .and. scan(f(i:i), ' +-#0123456789.') > 0)
               i = i + 1_I4P
            enddo
            if (f(i:i) == 'h') f(i:i) = 'g'
            if (f(i:i) == 'H') f(i:i) = 'G'
         endif
         i = i + 1_I4P
      enddo
      endfunction table_conversions

      pure function outside(v, axis) result(yes)
      !< Whether `v` lies outside the fixed ends of `axis`.
      real(R8P),         intent(in) :: v    !< Value.
      type(axis_object), intent(in) :: axis !< Axis.
      logical                       :: yes  !< Outside.

      yes = .false.
      if (axis%min_fixed .and. axis%max_fixed) then
         yes = v < min(axis%min_user, axis%max_user) .or. v > max(axis%min_user, axis%max_user)
      elseif (axis%min_fixed) then
         yes = v < axis%min_user
      elseif (axis%max_fixed) then
         yes = v > axis%max_user
      endif
      endfunction outside
   endsubroutine write_table

   subroutine expand_macros(self, statement, expanded, iostat, iomsg)
   !< gnuplot macros: each `@name` outside quotes replaced by the value of the string variable `name`.
   class(script_object),          intent(in)  :: self      !< Interpreter.
   character(len=*),              intent(in)  :: statement !< Statement.
   character(len=:), allocatable, intent(out) :: expanded  !< Statement after substitution.
   integer(I4P),                  intent(out) :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out) :: iomsg     !< Error message.
   character(len=*), parameter    :: LETTERS = UNAME_START !< Name start.
   character(len=:), allocatable  :: value     !< Variable value.
   character(len=1)               :: quote     !< Open quote, blank if none.
   integer(I4P)                   :: i         !< Character counter.
   integer(I4P)                   :: e         !< Name end.
   logical                        :: found     !< String variable found.

   iostat = 0_I4P
   iomsg = ''
   expanded = ''
   if (index(statement, '@') == 0) then
      expanded = statement
      return
   endif
   quote = ' '
   i = 1_I4P
   do while (i <= len(statement, kind=I4P))
      associate(c => statement(i:i))
         if (quote /= ' ') then
            if (c == quote) quote = ' '
            if (c == '\' .and. quote == '"' .and. i < len(statement)) then
               expanded = expanded//statement(i:i + 1_I4P)
               i = i + 2_I4P
               cycle
            endif
         elseif (c == '"' .or. c == "'") then
            quote = c
         elseif (c == '#') then
            ! a comment: left as it is
            expanded = expanded//statement(i:)
            return
         elseif (c == '@' .and. i < len(statement)) then
            if (scan(statement(i + 1_I4P:i + 1_I4P), LETTERS) > 0) then
               e = verify(statement(i + 1_I4P:), UNAME_CHARS, kind=I4P)
               if (e == 0_I4P) then
                  e = len(statement, kind=I4P)
               else
                  e = i + e - 1_I4P
               endif
               call self%symbols%string_of(statement(i + 1_I4P:e), value, found)
               if (.not. found) then
                  call fail('macro @'//statement(i + 1_I4P:e)//': no string variable '//statement(i + 1_I4P:e), &
                            iostat, iomsg)
                  return
               endif
               expanded = expanded//value
               i = e + 1_I4P
               cycle
            endif
         endif
         expanded = expanded//c
      endassociate
      i = i + 1_I4P
   enddo
   endsubroutine expand_macros

   subroutine annotation_option(self, tokens, iostat, iomsg)
   !< `set label [N] ["text"] [at POS] [left|center|right] [norotate|rotate [by A]] [front|back] [tc COLOR] [point
   !< [pt N] [ps S] [lc C]|nopoint] [offset X,Y] [font F] [noenhanced]`,
   !< `set arrow [N] [from POS to|rto POS] [as|arrowstyle S] [nohead|head|backhead|heads] [size [SYS] L,A[,B]]
   !< [filled|empty|nofilled|noborder] [front|back] [lc C] [lt N] [lw W] [dt N]` (`as S` the look of `set style arrow
   !< S`, the options after it applied on it), `set style arrow S [default|ARROW OPTIONS]`,
   !< `set object [N] rectangle [from POS to|rto POS|center|at POS size W,H] | circle [at|center POS] size R [arc
   !< [A:B]] | ellipse [at|center POS] size W,H [angle A] | polygon from POS to POS ... [front|back|behind] [clip|noclip]
   !< [fc|fillcolor COLOR] [fs FILL] [lw W] [dt N] [default]` (a new rectangle in the style of `set style rectangle
   !< [fc C] [fs FILL] [lw W] [dt N]`, its layer not taken, as gnuplot 6.0); `set label|arrow|object N ...` without a
   !< position changes tag N (gnuplot's). A position is `[SYS] x, [SYS] y`, SYS among first (default), second, graph,
   !< screen, character, the system of x also y's unless given; each coordinate an expression, or a time string on a
   !< time axis.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Option tokens (the option first).
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   character(len=:), allocatable                :: option    !< `label`, `arrow` or `object`.
   character(len=:), allocatable                :: word      !< Current word.
   character(len=:), allocatable                :: text      !< String.
   type(label_object)                           :: label     !< Label.
   type(arrow_object)                           :: arrow     !< Arrow.
   type(shape_object)                           :: object    !< Object.
   type(pixmap_object)                          :: pix       !< Pixmap.
   type(place_object)                           :: p         !< A position.
   type(line_style_object)                      :: line      !< Line properties read.
   integer(I4P)                                 :: i         !< Token counter.
   integer(I4P)                                 :: tag       !< Tag.
   integer(I4P)                                 :: k         !< Counter.
   logical                                      :: found     !< The tag exists.
   logical                                      :: placed    !< A position given.
   logical                                      :: kind_set  !< An object kind given.
   real(R8P)                                    :: v         !< A number.
   logical                                      :: polar_place !< A position `polar THETA, R`.

   iostat = 0_I4P
   iomsg = ''
   if (keyword(tokens(1)%text, 'label', 3_I4P)) then
      option = 'label'
   elseif (keyword(tokens(1)%text, 'arrow', 3_I4P)) then
      option = 'arrow'
   elseif (tokens(1)%text == 'arrowstyle') then
      option = 'style arrow'
   elseif (tokens(1)%text == 'rectanglestyle') then
      option = 'style rectangle'
   elseif (tokens(1)%text == 'pixmap') then
      option = 'pixmap'
   else
      option = 'object'
   endif
   i = 2_I4P
   tag = 0_I4P
   ! a tag: a number (or an expression) before anything else
   if (i <= size(tokens, kind=I4P)) then
      if (tokens(i)%kind == TOKEN_WORD .and. .not. is_annotation_word(tokens(i)%text)) then
         call self%symbols%value_of(tokens(i)%text, v, found)
         ! a numeric constant expression too, `set object i*11 noclip` in a loop (clipobject.dem); never a string one
         ! (`set label sprintf("%s%d", w, k) at ...`, its text)
         if (.not. found .and. scan(tokens(i)%text, '"'//"'") == 0) then
            block
               character(len=:), allocatable :: message !< Not a constant.
               integer(I4P)                  :: status  !< Constant status.

               call self%symbols%constant(tokens(i)%text, v, status, message)
               found = status == 0_I4P
            endblock
         endif
         if (to_number(tokens(i)%text, v) .or. scan(tokens(i)%text(1:1), '0123456789(') > 0 .or. found) then
            k = i - 1_I4P
            if (.not. next_integer(tokens, k, tag, iostat, iomsg, self%symbols)) return
            if (tag < 1_I4P) then
               call fail('set '//option//': the tag must be positive', iostat, iomsg)
               return
            endif
            i = k + 1_I4P
         endif
      endif
   endif
   ! an existing tag is modified (gnuplot): start from it
   found = .false.
   associate(panel => self%figure%panels(self%figure%current))
      select case (option)
      case ('label')
         if (allocated(panel%notes) .and. tag > 0_I4P) then
            do k = 1_I4P, size(panel%notes, kind=I4P)
               if (panel%notes(k)%tag == tag) then
                  label = panel%notes(k)
                  found = .true.
               endif
            enddo
         endif
      case ('arrow')
         if (allocated(panel%arrows) .and. tag > 0_I4P) then
            do k = 1_I4P, size(panel%arrows, kind=I4P)
               if (panel%arrows(k)%tag == tag) then
                  arrow = panel%arrows(k)
                  found = .true.
               endif
            enddo
         endif
      case ('style arrow')
         ! a style is redefined from gnuplot's default arrow
         continue
      case ('style rectangle')
         object = self%rectangle_style
         found = .true.
      case ('pixmap')
         if (allocated(panel%pixmaps) .and. tag > 0_I4P) then
            do k = 1_I4P, size(panel%pixmaps, kind=I4P)
               if (panel%pixmaps(k)%tag == tag) then
                  pix = panel%pixmaps(k)
                  found = .true.
               endif
            enddo
         endif
      case default
         if (allocated(panel%objects) .and. tag > 0_I4P) then
            do k = 1_I4P, size(panel%objects, kind=I4P)
               if (panel%objects(k)%tag == tag) then
                  object = panel%objects(k)
                  found = .true.
               endif
            enddo
         endif
      endselect
   endassociate
   if (.not. found) then
      label%text = ''
      label%color = ''
      arrow%color = ''
      arrow%dashes = ''
      object%kind = 'rectangle'
      call default_object(object)
   endif
   if (option == 'style arrow' .and. tag == 0_I4P) then
      call fail('set style arrow: a style number is expected', iostat, iomsg)
      return
   endif
   if (option == 'pixmap' .and. tag == 0_I4P) then
      call fail('set pixmap: a pixmap number is expected', iostat, iomsg)
      return
   endif
   pix%tag = tag
   if (option == 'pixmap' .and. tag == 0_I4P) then
      call fail('set pixmap: a pixmap number is expected', iostat, iomsg)
      return
   endif
   pix%tag = tag
   label%tag = tag
   arrow%tag = tag
   object%tag = tag
   placed = found
   kind_set = found
   ! gnuplot: `set style arrow N` again changes style N, the options not given kept (`default` resets it)
   if (option == 'style arrow' .and. allocated(self%arrow_styles)) then
      block
         integer(I4P) :: j !< Style counter.

         do j = 1_I4P, size(self%arrow_styles, kind=I4P)
            if (self%arrow_styles(j)%tag == tag) arrow = self%arrow_styles(j)
         enddo
      endblock
   endif
   select case (option)
   case ('label')
      call label_words
   case ('arrow', 'style arrow')
      call arrow_words
   case ('pixmap')
      call pixmap_words
   case default
      call object_words
   endselect
   if (iostat /= 0_I4P) return
   select case (option)
   case ('style arrow')
      call store_arrow_style
   case ('style rectangle')
      ! the style words only: no position, the layer not taken (as gnuplot 6.0)
      if (allocated(object%points) .or. trim(object%kind) /= 'rectangle') then
         call fail('set style rectangle: style options only (fc, fs, lw, dt, default)', iostat, iomsg)
         return
      endif
      object%layer = 'back'
      object%tag = 0_I4P
      self%rectangle_style = object
   case ('label')
      call self%figure%add_label(label)
   case ('pixmap')
      if (.not. allocated(pix%png)) then
         call fail('set pixmap: a PNG file is expected', iostat, iomsg)
         return
      endif
      call self%figure%add_pixmap(pix)
   case ('arrow')
      if (.not. placed) then
         call fail('set arrow: from POS to|rto POS expected', iostat, iomsg)
         return
      endif
      call self%figure%add_arrow(arrow)
   case default
      if (.not. allocated(object%points)) then
         call fail('set object: a rectangle, circle, ellipse or polygon with its position expected', iostat, iomsg)
         return
      endif
      call self%figure%add_object(object)
   endselect
   contains
      subroutine store_arrow_style
      !< Keep `arrow` as the arrow style of its tag (the earlier one changed by the options): its look only.
      integer(I4P) :: j !< Style counter.

      if (option == 'style arrow' .and. placed) then
         call fail('set style arrow: style options only, no position', iostat, iomsg)
         return
      endif
      if (.not. allocated(self%arrow_styles)) allocate(self%arrow_styles(0))
      do j = 1_I4P, size(self%arrow_styles, kind=I4P)
         if (self%arrow_styles(j)%tag == arrow%tag) then
            self%arrow_styles(j) = arrow
            return
         endif
      enddo
      call push(self%arrow_styles, arrow)
      endsubroutine store_arrow_style

      subroutine apply_arrow_style
      !< `as N` or `arrowstyle N` (token `i`): the look of style N, the options after it applied on it.
      integer(I4P)       :: n     !< Style number.
      integer(I4P)       :: j     !< Style counter.
      type(arrow_object) :: style !< The style.

      if (.not. next_integer(tokens, i, n, iostat, iomsg, self%symbols)) return
      do j = 1_I4P, size(self%arrow_styles, kind=I4P)
         if (self%arrow_styles(j)%tag == n) then
            style = self%arrow_styles(j)
            arrow%head = style%head
            arrow%length = style%length
            arrow%length_system = style%length_system
            arrow%angle = style%angle
            arrow%fill = style%fill
            arrow%front = style%front
            arrow%color = style%color
            arrow%lw = style%lw
            arrow%dashes = style%dashes
            return
         endif
      enddo
      call fail('set arrow: arrow style '//int_str(int(n, I8P))//' is not defined (set style arrow N ...)', iostat, &
                iomsg)
      endsubroutine apply_arrow_style

      subroutine pixmap_words
      !< gnuplot `set pixmap N "file.png" [at POS] [size W,H | width W | height H] [center] [behind|back|front]`: the
      !< PNG file read now (its width and height from its header), POS its lower left corner (its centre with
      !< `center`), W and H in their systems (`first` by default), the other side by the aspect with `width` or
      !< `height` alone, its own pixels without.
      character(len=:), allocatable :: word !< Current word.

         do while (i <= size(tokens, kind=I4P))
            word = tokens(i)%text
            if (tokens(i)%kind == TOKEN_STRING) then
               call read_png(word)
               if (iostat /= 0_I4P) return
            elseif (word == 'at') then
               call position(pix%at)
            elseif (word == 'size') then
               call position(pix%span)
               pix%sized = 1_I4P
            elseif (word == 'width') then
               pix%span%sx = 'first'
               call coordinate(pix%span%x, pix%span%sx)
               pix%sized = 2_I4P
            elseif (word == 'height') then
               pix%span%sy = 'first'
               call coordinate(pix%span%y, pix%span%sy)
               pix%sized = 3_I4P
            elseif (word == 'center' .or. word == 'centre') then
               pix%center = .true.
            elseif (is_word(word, 'behind back front')) then
               pix%layer = word
            else
               call fail('set pixmap: unsupported option "'//word//'" (a file, at, size, width, height, center, '// &
                         'behind, back, front are)', iostat, iomsg)
            endif
            if (iostat /= 0_I4P) return
            i = i + 1_I4P
         enddo
      endsubroutine pixmap_words

      subroutine read_png(file)
      !< The PNG `file` into `pix`: its bytes as base64, its width and height (the IHDR chunk, big endian).
      character(len=*), intent(in)  :: file     !< File name.
      integer(I1P), allocatable     :: bytes(:) !< File bytes.
      character(len=:), allocatable :: code     !< Base64.
      integer(I4P)                  :: unit     !< File unit.
      integer(I4P)                  :: n        !< File size [bytes].
      integer(I4P)                  :: ios      !< I/O status.
      integer(I4P)                  :: k        !< Byte counter.
      integer(I4P), parameter       :: SIGNATURE(8) = [137_I4P, 80_I4P, 78_I4P, 71_I4P, 13_I4P, 10_I4P, 26_I4P, &
                                                       10_I4P] !< PNG signature.

         open(newunit=unit, file=file, access='stream', form='unformatted', action='read', status='old', iostat=ios)
         if (ios /= 0_I4P) then
            call fail('set pixmap: cannot open "'//file//'"', iostat, iomsg)
            return
         endif
         inquire(unit=unit, size=n)
         if (n < 24_I4P) then
            close(unit)
            call fail('set pixmap: "'//file//'" is not a PNG file (foresight reads PNG files only)', iostat, iomsg)
            return
         endif
         allocate(bytes(n))
         read(unit, iostat=ios) bytes
         close(unit)
         if (ios /= 0_I4P) then
            call fail('set pixmap: cannot read "'//file//'"', iostat, iomsg)
            return
         endif
         do k = 1_I4P, 8_I4P
            if (iand(int(bytes(k), I4P), 255_I4P) /= SIGNATURE(k)) then
               call fail('set pixmap: "'//file//'" is not a PNG file (foresight reads PNG files only)', iostat, iomsg)
               return
            endif
         enddo
         pix%pixels = 0_I4P
         do k = 1_I4P, 4_I4P
            pix%pixels(1) = pix%pixels(1) * 256_I4P + iand(int(bytes(16_I4P + k), I4P), 255_I4P)
            pix%pixels(2) = pix%pixels(2) * 256_I4P + iand(int(bytes(20_I4P + k), I4P), 255_I4P)
         enddo
         if (.not. is_b64_initialized) call b64_init
         call b64_encode(n=bytes, code=code)
         pix%png = code
      endsubroutine read_png

      pure function is_annotation_word(w) result(yes)
      !< Whether `w` is an option word of the annotations (not a tag).
      character(len=*), intent(in) :: w   !< Word.
      logical                      :: yes !< An option word.

      yes = is_word(w, 'at from to rto left center centre right rotate norotate front back behind tc textcolor '// &
                    'point nopoint offset font noenhanced enhanced rect rectangle circle ellipse polygon size arc '// &
                    'angle fc fillcolor fs fillstyle lw linewidth lc linecolor lt linetype dt dashtype nohead head '// &
                    'backhead heads filled empty nofilled noborder clip noclip default units boxed noboxed as arrowstyle '// &
                    'noenh noenha noenhan noenhanc noenhance enh enha enhan enhanc enhance width height')
      endfunction is_annotation_word

      subroutine position(q)
      !< A position `[SYS] x, [SYS] y` from token `i` (left on its last token).
      type(place_object), intent(out) :: q !< Position.

      q = place_object()
      ! gnuplot's `polar THETA, R`: the first-axis x, y of that theta and radius on a polar panel, with the theta
      ! origin, direction and angle unit set now (gnuplot converts when drawing)
      polar_place = .false.
      if (i < size(tokens, kind=I4P)) polar_place = tokens(i + 1_I4P)%text == 'polar'
      if (polar_place) then
         i = i + 1_I4P
         call coordinate(q%x, q%sx)
         if (iostat /= 0_I4P) return
         if (i >= size(tokens, kind=I4P)) then
            call fail('set '//option//': a polar position is "polar theta, r"', iostat, iomsg)
            return
         endif
         i = i + 1_I4P
         call coordinate(q%y, q%sy)
         if (iostat /= 0_I4P) return
         associate(panel => self%figure%panels(self%figure%current))
            block
               real(R8P) :: phi !< Page angle [rad].
               real(R8P) :: rho !< Distance from the pole.

               phi = q%x
               if (panel%degrees) phi = phi * acos(-1.0_R8P) / 180.0_R8P
               if (panel%theta_clockwise) phi = -phi
               phi = phi + panel%theta_origin * acos(-1.0_R8P) / 180.0_R8P
               rho = q%y
               if (panel%raxis%min_fixed) rho = rho - panel%raxis%min_user
               q%x = rho * cos(phi)
               q%y = rho * sin(phi)
               q%sx = 'first'
               q%sy = 'first'
            endblock
         endassociate
         ! a third coordinate (gnuplot's z): read and ignored
         if (i < size(tokens, kind=I4P)) then
            if (tokens(i + 1_I4P)%kind == TOKEN_COMMA) then
               block
                  real(R8P)        :: z  !< Ignored.
                  character(len=9) :: sz !< Its system.

                  sz = 'first'
                  i = i + 1_I4P
                  call coordinate(z, sz)
               endblock
            endif
         endif
         return
      endif
      call coordinate(q%x, q%sx)
      if (iostat /= 0_I4P) return
      q%sy = q%sx
      if (i >= size(tokens, kind=I4P)) then
         call fail('set '//option//': a position is "x, y"', iostat, iomsg)
         return
      endif
      if (tokens(i + 1_I4P)%kind /= TOKEN_COMMA) then
         call fail('set '//option//': a position is "x, y", found "'//tokens(i + 1_I4P)%text//'"', iostat, iomsg)
         return
      endif
      i = i + 1_I4P
      call coordinate(q%y, q%sy)
      if (iostat /= 0_I4P) return
      ! a third coordinate (gnuplot's z, for splot): read and ignored
      if (i < size(tokens, kind=I4P)) then
         if (tokens(i + 1_I4P)%kind == TOKEN_COMMA) then
            block
               real(R8P)        :: z  !< Ignored.
               character(len=9) :: sz !< Its system.

               sz = q%sy
               i = i + 1_I4P
               call coordinate(z, sz)
            endblock
         endif
      endif
      endsubroutine position

      subroutine coordinate(value, system)
      !< One coordinate `[SYS] value` after token `i`, `i` left on its value.
      real(R8P),        intent(out)   :: value  !< Value.
      character(len=9), intent(inout) :: system !< Its system (kept if not given).
      character(len=:), allocatable   :: written !< Value as written.

      value = 0.0_R8P
      i = i + 1_I4P
      if (i > size(tokens, kind=I4P)) then
         call fail('set '//option//': a coordinate is missing', iostat, iomsg)
         return
      endif
      if (tokens(i)%kind == TOKEN_WORD .and. coordinate_system(tokens(i)%text) /= '') then
         ! gnuplot's abbreviations: fir$st, sec$ond, gr$aph, sc$reen, char$acter
         system = coordinate_system(tokens(i)%text)
         i = i + 1_I4P
         if (i > size(tokens, kind=I4P)) then
            call fail('set '//option//': a coordinate is missing after '//trim(system), iostat, iomsg)
            return
         endif
      endif
      written = tokens(i)%text
      if (tokens(i)%kind == TOKEN_STRING) then
         written = '"'//written//'"'
      elseif (expression_end(tokens, i) > i) then
         ! an expression written with blanks, `1, 3 + 2`: its tokens
         written = expression_source(tokens(i:expression_end(tokens, i)))
         i = expression_end(tokens, i)
      endif
      call self%range_value(written, value, iostat, iomsg)
      if (iostat /= 0_I4P) iomsg = 'set '//option//': '//iomsg
      endsubroutine coordinate

      subroutine pair(values, system)
      !< Two numbers `[SYS] a, b` after token `i` (an object size, an arrow head size), `i` left on the last.
      real(R8P),        intent(out)   :: values(2) !< Numbers.
      character(len=9), intent(inout) :: system    !< System of the first.
      character(len=9)                :: second    !< System of the second (ignored).

      call coordinate(values(1), system)
      if (iostat /= 0_I4P) return
      values(2) = 0.0_R8P
      if (i < size(tokens, kind=I4P)) then
         if (tokens(i + 1_I4P)%kind == TOKEN_COMMA) then
            i = i + 1_I4P
            second = system
            call coordinate(values(2), second)
         endif
      endif
      endsubroutine pair

      subroutine label_words
      !< The words of `set label`.
      do while (i <= size(tokens, kind=I4P))
         word = tokens(i)%text
         if (tokens(i)%kind == TOKEN_STRING .or. (tokens(i)%kind == TOKEN_WORD .and. .not. is_annotation_word(word))) &
            then
            if (.not. self%string_expression(tokens, i, text, iostat, iomsg)) then
               iomsg = 'set label: '//iomsg
               return
            endif
            label%text = text
         elseif (word == 'at') then
            call position(label%at)
         elseif (is_word(word, 'left center centre right')) then
            label%justify = word
            if (word == 'centre') label%justify = 'center'
         elseif (word == 'norotate') then
            label%rotate = 0.0_R8P
         elseif (word == 'rotate') then
            label%rotate = 90.0_R8P
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%text == 'by') then
                  i = i + 1_I4P
                  if (.not. next_real(tokens, i, label%rotate, iostat, iomsg, self%symbols)) return
               endif
            endif
         elseif (word == 'front' .or. word == 'back') then
            label%front = word == 'front'
         elseif (word == 'tc' .or. keyword(word, 'textcolor', 5_I4P)) then
            call color_words(label%color)
         elseif (word == 'point') then
            label%point = .true.
            do while (i < size(tokens, kind=I4P))
               if (.not. is_line_option(tokens(i + 1_I4P)%text)) exit
               i = i + 1_I4P
               if (.not. line_option(tokens, i, line, iostat, iomsg, self%figure%panels(self%figure%current)% &
                                     linecolors, self%symbols)) return
            enddo
            if (allocated(line%pt)) label%pt = line%pt
            if (allocated(line%ps)) label%ps = line%ps
         elseif (word == 'nopoint') then
            label%point = .false.
         elseif (word == 'boxed' .and. option == 'label') then
            ! in text box style 0, or `bs N`: on the background when that style is drawn (gnuplot's svg)
            block
               integer(I4P) :: bs !< Text box style.

               bs = 0_I4P
               if (i < size(tokens, kind=I4P)) then
                  if (tokens(i + 1_I4P)%text == 'bs') then
                     i = i + 1_I4P
                     if (.not. next_integer(tokens, i, bs, iostat, iomsg, self%symbols)) return
                     if (bs < 0_I4P .or. bs > 3_I4P) then
                        call fail('set label: boxed bs N: N from 0 to 3', iostat, iomsg)
                        return
                     endif
                  endif
               endif
               label%boxed = self%textbox_drawn(bs)
            endblock
         elseif (word == 'noboxed' .and. option == 'label') then
            label%boxed = .false.
         elseif (word == 'offset') then
            block
               character(len=9) :: system !< Offset system (characters only).

               system = 'first'
               call pair(label%offset, system)
            endblock
         elseif (word == 'font') then
            if (.not. font_spec(self, tokens, i, label%font, iostat, iomsg)) then
               iomsg = 'set label: '//iomsg
               return
            endif
         elseif (keyword(word, 'noenhanced', 5_I4P) .or. keyword(word, 'enhanced', 3_I4P)) then
            ! gnuplot's noenh$anced, enh$anced
            label%plain = word(1:2) == 'no'
         else
            call fail('set label: unsupported option "'//word//'"', iostat, iomsg)
            return
         endif
         if (iostat /= 0_I4P) return
         i = i + 1_I4P
      enddo
      endsubroutine label_words

      subroutine arrow_words
      !< The words of `set arrow`.
      real(R8P)        :: size2(2) !< Head length and angle.
      character(len=9) :: second   !< System of the angle (ignored).

      do while (i <= size(tokens, kind=I4P))
         word = tokens(i)%text
         if (word == 'from') then
            call position(arrow%from)
            placed = .true.
         elseif (word == 'to' .or. word == 'rto') then
            call position(arrow%to)
            arrow%relative = word == 'rto'
            arrow%polar = .false.
         elseif (word == 'length') then
            ! gnuplot `length [SYS] L angle A`: the tip from the tail
            arrow%span_system = 'first'
            call coordinate(arrow%span, arrow%span_system)
            if (iostat /= 0_I4P) return
            if (i + 2_I4P > size(tokens, kind=I4P)) then
               call fail('set arrow: length L angle A expected', iostat, iomsg)
               return
            endif
            if (tokens(i + 1_I4P)%text /= 'angle') then
               call fail('set arrow: length L angle A expected', iostat, iomsg)
               return
            endif
            i = i + 1_I4P
            second = 'first'
            call coordinate(arrow%direction, second)
            if (iostat /= 0_I4P) return
            arrow%polar = .true.
            arrow%relative = .false.
         elseif (is_word(word, 'nohead head backhead heads')) then
            arrow%head = merge(0_I4P, merge(1_I4P, merge(2_I4P, 3_I4P, word == 'backhead'), word == 'head'), &
                               word == 'nohead')
         elseif (word == 'size') then
            ! `[SYS] L,A`, as pair reads it: written out here, since nvfortran 26.9 -O2 skipped the angle read
            ! through pair in this procedure (bug 24, depending on unrelated procedures of the module)
            arrow%length_system = 'first'
            size2 = 0.0_R8P
            call coordinate(size2(1), arrow%length_system)
            if (iostat /= 0_I4P) return
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%kind == TOKEN_COMMA) then
                  i = i + 1_I4P
                  second = arrow%length_system
                  call coordinate(size2(2), second)
                  if (iostat /= 0_I4P) return
               endif
            endif
            arrow%length = size2(1)
            if (size2(2) /= 0.0_R8P) arrow%angle = size2(2)
            ! a back angle is read and ignored
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%kind == TOKEN_COMMA) i = i + 2_I4P
            endif
         elseif (is_word(word, 'filled empty nofilled noborder') .or. keyword(word, 'filled', 3_I4P)) then
            ! `fill` abbreviates filled (gnuplot's fil$led)
            arrow%fill = word
            if (keyword(word, 'filled', 3_I4P)) arrow%fill = 'filled'
         elseif (word == 'ls' .or. keyword(word, 'linestyle', 5_I4P)) then
            ! the color, width and dashes of line style N
            block
               integer(I4P)            :: n     !< Line style.
               type(line_style_object) :: probe !< Its line.

               if (.not. next_integer(tokens, i, n, iostat, iomsg, self%symbols)) return
               call apply_line_style(self%line_styles, n, probe, self%figure%panels(self%figure%current)%linecolors)
               if (allocated(probe%lc)) arrow%color = probe%lc
               if (allocated(probe%lw)) arrow%lw = probe%lw
               if (allocated(probe%dt)) then
                  block
                     type(style_object) :: dashes !< Line of the dash type.

                     dashes%dashtype = probe%dt
                     dashes%linewidth = arrow%lw
                     arrow%dashes = dashes%dasharray()
                  endblock
               endif
            endblock
         elseif (word == 'front' .or. word == 'back') then
            arrow%front = word == 'front'
         elseif (is_line_option(word)) then
            if (.not. line_option(tokens, i, line, iostat, iomsg, self%figure%panels(self%figure%current)%linecolors, &
                                  self%symbols)) return
            if (allocated(line%lc)) arrow%color = line%lc
            if (allocated(line%lw)) arrow%lw = line%lw
            if (allocated(line%dt)) then
               block
                  type(style_object) :: dashes !< Line of the dash type.

                  dashes%dashtype = line%dt
                  dashes%linewidth = arrow%lw
                  arrow%dashes = dashes%dasharray()
               endblock
            endif
         elseif (word == 'fixed') then
            continue
         elseif ((word == 'as' .or. word == 'arrowstyle') .and. option == 'arrow') then
            call apply_arrow_style
         elseif (word == 'default' .and. option == 'style arrow') then
            ! by components: nvfortran 26.9 stops on constructors of types holding deferred-length characters
            block
               type(arrow_object) :: fresh !< gnuplot's default arrow.

               fresh%tag = arrow%tag
               fresh%color = ''
               fresh%dashes = ''
               arrow = fresh
            endblock
         else
            call fail('set '//option//': unsupported option "'//word//'"', iostat, iomsg)
            return
         endif
         if (iostat /= 0_I4P) return
         i = i + 1_I4P
      enddo
      endsubroutine arrow_words

      subroutine object_words
      !< The words of `set object`.
      real(R8P)                     :: size2(2) !< Width and height.
      character(len=9)              :: system   !< System of a size.
      character(len=:), allocatable :: bad      !< Unknown fill word.
      character(len=:), allocatable :: fill     !< Fill words.
      type(place_object)            :: corner   !< A corner.
      type(place_object)            :: vertices(1) !< A vertex to push.

      do while (i <= size(tokens, kind=I4P))
         word = tokens(i)%text
         if (keyword(word, 'rectangle', 4_I4P) .or. is_word(word, 'circle ellipse polygon')) then
            if (keyword(word, 'rectangle', 4_I4P)) word = 'rectangle'
            if (kind_set .and. trim(object%kind) /= word) then
               ! another kind: a new object of that kind, its style the default
               object%kind = word
               call default_object(object)
               if (allocated(object%points)) deallocate(object%points)
            endif
            object%kind = word
            call default_object_style(object)
            kind_set = .true.
         elseif (word == 'from') then
            call position(p)
            if (iostat /= 0_I4P) return
            if (allocated(object%points)) deallocate(object%points)
            allocate(object%points(1))
            object%points(1) = p
            object%sized = .false.
         elseif (word == 'to' .or. word == 'rto') then
            if (.not. allocated(object%points)) then
               call fail('set object: to needs a from first', iostat, iomsg)
               return
            endif
            call position(p)
            if (iostat /= 0_I4P) return
            if (word == 'rto') then
               corner = object%points(size(object%points))
               p%x = corner%x + p%x
               p%y = corner%y + p%y
               p%sx = corner%sx
               p%sy = corner%sy
            endif
            vertices(1) = p
            object%points = [object%points, vertices]
         elseif (word == 'at' .or. word == 'center' .or. word == 'centre') then
            call position(p)
            if (iostat /= 0_I4P) return
            if (allocated(object%points)) deallocate(object%points)
            allocate(object%points(1))
            object%points(1) = p
            if (trim(object%kind) == 'rectangle') object%sized = .true.
         elseif (word == 'size' .or. (word == 'radius' .and. trim(object%kind) == 'circle')) then
            ! `radius R` names a circle's size, as gnuplot
            system = 'first'
            if (allocated(object%points)) system = object%points(1)%sx
            call pair(size2, system)
            if (iostat /= 0_I4P) return
            object%size%x = size2(1)
            object%size%y = size2(2)
            object%size%sx = system
            object%size%sy = system
            if (allocated(object%points)) object%size%sy = object%points(1)%sy
            if (trim(object%kind) == 'rectangle') object%sized = .true.
         elseif (word == 'arc') then
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) then
               call fail('set object: arc [A:B] expected', iostat, iomsg)
               return
            endif
            if (tokens(i)%kind /= TOKEN_RANGE .or. index(tokens(i)%text, ':') == 0) then
               call fail('set object: arc [A:B] expected', iostat, iomsg)
               return
            endif
            k = index(tokens(i)%text, ':', kind=I4P)
            call self%range_value(trim(adjustl(tokens(i)%text(1:k - 1_I4P))), object%arc(1), iostat, iomsg)
            if (iostat == 0_I4P) call self%range_value(trim(adjustl(tokens(i)%text(k + 1_I4P:))), object%arc(2), iostat, &
                                                       iomsg)
         elseif (word == 'angle') then
            if (.not. next_real(tokens, i, object%angle, iostat, iomsg, self%symbols)) return
         elseif (word == 'units') then
            i = i + 1_I4P
            if (i <= size(tokens, kind=I4P)) then
               if (tokens(i)%text /= 'xy') then
                  call fail('set object: units xy only', iostat, iomsg)
                  return
               endif
            endif
         elseif (is_word(word, 'wedge nowedge')) then
            continue
         elseif (is_word(word, 'front back behind')) then
            object%layer = word
         elseif (word == 'clip' .or. word == 'noclip') then
            object%clip = word == 'clip'
         elseif (word == 'fc' .or. keyword(word, 'fillcolor', 5_I4P)) then
            block
               character(len=:), allocatable :: color !< Fill color.

               call color_words(color)
               if (iostat /= 0_I4P) return
               if (color == 'bgnd') color = 'white'
               object%style%color = color
               if (trim(object%kind) /= 'rectangle' .and. allocated(object%style%border_color)) &
                  deallocate(object%style%border_color)
            endblock
         elseif (word == 'fs' .or. keyword(word, 'fillstyle', 5_I4P)) then
            fill = ''
            do while (i < size(tokens, kind=I4P))
               ! the fill words, `border lc COLOR` included
               if (is_annotation_word(tokens(i + 1_I4P)%text) .and. .not. is_word(tokens(i + 1_I4P)%text, &
                   'empty noborder') .and. .not. (is_word(tokens(i + 1_I4P)%text, 'lc linecolor rgb rgbcolor') .and. &
                   (tokens(i)%text == 'border' .or. is_word(tokens(i)%text, 'lc linecolor')))) exit
               i = i + 1_I4P
               if (tokens(i)%kind == TOKEN_STRING) then
                  fill = fill//' "'//tokens(i)%text//'"'
               else
                  fill = fill//' '//tokens(i)%text
               endif
               ! the color after lc [rgb]
               if (is_word(tokens(i)%text, 'lc linecolor rgb rgbcolor') .and. i < size(tokens, kind=I4P)) then
                  if (tokens(i + 1_I4P)%kind == TOKEN_STRING .or. .not. is_annotation_word(tokens(i + 1_I4P)%text)) &
                     then
                     if (.not. is_word(tokens(i + 1_I4P)%text, 'rgb rgbcolor')) then
                        i = i + 1_I4P
                        if (tokens(i)%kind == TOKEN_STRING) then
                           fill = fill//' "'//tokens(i)%text//'"'
                        else
                           fill = fill//' '//tokens(i)%text
                        endif
                     endif
                  endif
               endif
            enddo
            call fill_style(fill, object%style, bad)
            if (len(bad) > 0) then
               call fail('set object: unsupported fill style "'//bad//'"', iostat, iomsg)
               return
            endif
         elseif (word == 'lw' .or. keyword(word, 'linewidth', 5_I4P)) then
            if (.not. next_real(tokens, i, object%style%linewidth, iostat, iomsg, self%symbols)) return
         elseif (word == 'dt' .or. keyword(word, 'dashtype', 5_I4P)) then
            if (.not. next_integer(tokens, i, k, iostat, iomsg, self%symbols)) return
            if (k < 1_I4P .or. k > 5_I4P) then
               call fail('set '//option//': dash types 1 to 5', iostat, iomsg)
               return
            endif
            object%style%dashtype = k
         elseif (word == 'default') then
            call default_object_style(object)
         else
            call fail('set '//option//': unsupported option "'//word//'"', iostat, iomsg)
            return
         endif
         if (iostat /= 0_I4P) return
         i = i + 1_I4P
      enddo
      if (.not. allocated(object%points)) return
      select case (trim(object%kind))
      case ('rectangle')
         if (.not. object%sized .and. size(object%points) /= 2) then
            call fail('set object: a rectangle is from POS to POS, or at POS size W,H', iostat, iomsg)
         endif
      case ('circle')
         if (object%size%x <= 0.0_R8P) object%size%x = 1.0_R8P
      case ('polygon')
         if (size(object%points) < 3) call fail('set object: a polygon has 3 vertices at least', iostat, iomsg)
      endselect
      endsubroutine object_words

      subroutine color_words(color)
      !< A color after `tc`, `fc` (token `i`): `rgb "color"`, `"color"`, `lt N`, `N`, `bgnd`, `black`; `i` left on its
      !< last token.
      character(len=:), allocatable, intent(out) :: color !< Color.
      type(token_object), allocatable            :: copy(:) !< Tokens with `lc` for the color word.
      type(line_style_object)                    :: probe   !< Color read.

      color = ''
      if (i >= size(tokens, kind=I4P)) then
         call fail('set '//option//': '//tokens(i)%text//' needs a color', iostat, iomsg)
         return
      endif
      if (is_word(tokens(i + 1_I4P)%text, 'bgnd black')) then
         i = i + 1_I4P
         color = merge('white', 'black', tokens(i)%text == 'bgnd')
         return
      endif
      if (keyword(tokens(i + 1_I4P)%text, 'linetype', 5_I4P) .or. tokens(i + 1_I4P)%text == 'lt') i = i + 1_I4P
      copy = tokens
      if (.not. (copy(i)%text == 'lt' .or. keyword(copy(i)%text, 'linetype', 5_I4P))) copy(i)%text = 'lc'
      if (.not. line_option(copy, i, probe, iostat, iomsg, self%figure%panels(self%figure%current)%linecolors, &
                            self%symbols)) return
      if (allocated(probe%lc)) color = probe%lc
      if (index(color, '*') == 1) then
         call fail('set '//option//': variable and palette colors do not apply', iostat, iomsg)
         return
      endif
      endsubroutine color_words

      subroutine default_object(shape)
      !< gnuplot's default object: no points, its kind's style.
      type(shape_object), intent(inout) :: shape !< Object.

      shape%sized = .false.
      shape%angle = 0.0_R8P
      shape%arc = [0.0_R8P, 360.0_R8P]
      shape%size = place_object()
      shape%layer = 'back'
      shape%clip = .true.
      call default_object_style(shape)
      endsubroutine default_object

      subroutine default_object_style(shape)
      !< gnuplot's default style of an object: a rectangle filled with the page color, bordered black; the others empty,
      !< black.
      type(shape_object), intent(inout) :: shape !< Object.

      shape%style = style_object()
      shape%style%border = .true.
      if (trim(shape%kind) == 'rectangle' .and. option /= 'style rectangle') then
         ! `set style rectangle`
         shape%style = self%rectangle_style%style
      elseif (trim(shape%kind) == 'rectangle') then
         shape%style%fill = FILL_SOLID
         shape%style%density = 1.0_R8P
         shape%style%color = 'white'
         shape%style%border_color = 'black'
      else
         shape%style%color = 'black'
      endif
      endsubroutine default_object_style
   endsubroutine annotation_option

   subroutine range_value(self, text, v, iostat, iomsg)
   !< Value of a range end: a number, a constant expression (`2*pi`, user variables), or a string: a time read with the
   !< timefmt (`set xrange ["2024-03-01":"2024-03-02"]` on a time axis).
   class(script_object),          intent(in)  :: self      !< Interpreter.
   character(len=*),              intent(in)  :: text      !< End text.
   real(R8P),                     intent(out) :: v         !< Value.
   integer(I4P),                  intent(out) :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out) :: iomsg     !< Error message.
   character(len=:), allocatable              :: value     !< Value as text.
   logical                                    :: is_string !< A string value.
   logical                                    :: ok        !< Time read.

   iostat = 0_I4P
   iomsg = ''
   if (to_number(text, v)) return
   call self%symbols%text_of(text, value, is_string, iostat, iomsg, &
                             degrees=self%figure%panels(self%figure%current)%degrees)
   if (iostat /= 0_I4P) return
   if (is_string) then
      call strptime(self%timefmt, value, v, ok)
      if (.not. ok) call fail('the time "'//value//'" does not match the timefmt "'//self%timefmt//'"', iostat, iomsg)
      return
   endif
   call self%symbols%constant(text, v, iostat, iomsg, degrees=self%figure%panels(self%figure%current)%degrees)
   endsubroutine range_value

   subroutine set_time_data(self, option, on)
   !< `set xdata|ydata|y2data|x2data [time]` (`option` the option word): the data of that axis read as times with the
   !< timefmt (`on`), or as numbers; the axis ticked and labelled as times or numbers.
   class(script_object), intent(inout) :: self   !< Interpreter.
   character(len=*),     intent(in)    :: option !< Option word, `xdata`, `y2da`, ...
   logical,              intent(in)    :: on     !< Time data.
   character(len=2)                    :: axis   !< Axis name.

   axis = option(1:index(option, 'd') - 1)
   select case (trim(axis))
   case ('x')
      self%time_data(1) = on
   case ('y')
      self%time_data(2) = on
   case ('y2')
      self%time_data(3) = on
   case ('x2')
      self%time_data(4) = on
   endselect
   call self%figure%set_time_axes(trim(axis), on=on, timefmt=self%timefmt)
   endsubroutine set_time_data

   subroutine load_data(self, data, file, iostat, iomsg, keep_text, skip, content)
   !< Load the data file `file`, or the datablock it names (`$DATA`), with the `set datafile` options; `skip` its first
   !< lines not read (gnuplot `skip N`); `content` the rows of a pseudo-file (`'+'`) instead.
   class(script_object),          intent(in)           :: self      !< Interpreter.
   type(datafile_object),         intent(inout)        :: data      !< Data.
   character(len=*),              intent(in)           :: file      !< File or datablock name.
   integer(I4P),                  intent(out)          :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg     !< Error message.
   logical,                       intent(in), optional :: keep_text !< Keep the cell texts.
   integer(I4P),                  intent(in), optional :: skip      !< First lines not read.
   character(len=*),              intent(in), optional :: content   !< Rows of a pseudo-file.
   character(len=:), allocatable                       :: lines     !< Datablock lines.
   logical                                             :: found     !< Datablock found.

   if (present(content)) then
      call data%load(file, iostat, iomsg, separator='', missing='', comments='#', keep_text=keep_text, content=content)
   elseif (self%symbols%is_array(file)) then
      ! an array: the index and the value of each element, as gnuplot's `plot A`
      call data%load(file, iostat, iomsg, separator='', missing=self%missing, comments=self%comments, &
                     keep_text=keep_text, content=self%symbols%array_data(file), skip=skip)
   elseif (is_datablock(file)) then
      call self%symbols%string_of(file, lines, found)
      if (.not. found) then
         call fail('no datablock '//file, iostat, iomsg)
         return
      endif
      call data%load(file, iostat, iomsg, separator=self%separator, missing=self%missing, comments=self%comments, &
                     keep_text=keep_text, content=lines, skip=skip)
   else
      call data%load(file, iostat, iomsg, separator=self%separator, missing=self%missing, comments=self%comments, &
                     keep_text=keep_text, skip=skip)
   endif
   endsubroutine load_data

   subroutine register_file(self, file)
   !< Remember `file` among the data files read (once), not a datablock.
   class(script_object), intent(inout) :: self  !< Interpreter.
   character(len=*),     intent(in)    :: file  !< Data file.
   type(token_object)                  :: entry !< New entry.
   integer(I4P)                        :: f     !< Counter.

   if (is_datablock(file) .or. self%symbols%is_array(file)) return
   do f = 1_I4P, size(self%data_files, kind=I4P)
      if (self%data_files(f)%text == file) return
   enddo
   entry%text = file
   call push(self%data_files, entry)
   endsubroutine register_file

   subroutine save_output(self, iostat, iomsg)
   !< Render the figure to the current output; the format follows its extension.
   class(script_object),          intent(inout) :: self    !< Interpreter.
   integer(I4P),                  intent(out)   :: iostat  !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg   !< Error message.
   integer(I4P)                                 :: refresh !< Figure refresh to restore.

   iostat = 0_I4P
   iomsg = ''
   if (self%output /= '-') then
      select case (extension(self%output))
      case ('svg', 'html', 'htm', 'txt')
      case default
         call fail('unsupported output "'//self%output//'" (supported: .svg, .html, .txt, -)', iostat, iomsg)
         return
      endselect
   endif
   self%figure%clear_screen = self%live_refresh > 0_I4P
   refresh = self%figure%refresh
   if (refresh == 0_I4P) call self%figure%set_refresh(self%live_refresh)
   call self%figure%save(self%output)
   call self%figure%set_refresh(refresh)
   endsubroutine save_output

   recursive subroutine set_command(self, tokens, iostat, iomsg)
   !< `set` options.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Option tokens.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   character(len=:), allocatable                :: option    !< Option word.
   character(len=:), allocatable                :: text      !< String argument.
   integer(I4P)                                 :: i         !< Token counter.
   integer(I4P)                                 :: k         !< Margin counter.
   integer(I4P)                                 :: width     !< Terminal width.
   integer(I4P)                                 :: height    !< Terminal height.
   integer(I4P)                                 :: seconds   !< Refresh period.
   integer(I4P)                                 :: rows      !< Multiplot rows.
   integer(I4P)                                 :: cols      !< Multiplot columns.
   logical                                      :: columns_first !< Multiplot `columnsfirst`.
   logical                                      :: upwards   !< Multiplot `upwards`.
   integer(I4P)                                 :: last      !< Last token of an expression.
   real(R8P)                                    :: margins(4) !< Multiplot layout margins.
   real(R8P)                                    :: spacing(2) !< Multiplot layout spacing.
   logical                                      :: margin_chars(4) !< Those margins in characters.
   logical                                      :: spacing_chars(2) !< That spacing in characters.
   logical                                      :: unit_chars !< The last unit given is characters.
   logical                                      :: set_margins !< Multiplot margins given.
   logical                                      :: set_spacing !< Multiplot spacing given.
   logical                                      :: r_named   !< The option names the r axis alone (`logscale r`).

   iostat = 0_I4P
   iomsg = ''
   if (size(tokens) == 0) then
      call fail('set: missing option', iostat, iomsg)
      return
   endif
   ! read here, not by an internal function: nvfortran 26.9 -O2 inlined one and crashed comparing tokens(2)%text (bug 24)
   r_named = .false.
   if (size(tokens) >= 2) r_named = tokens(2)%text == 'r'
   option = tokens(1)%text
   ! gnuplot's old `set noxtics`, `set nokey`, ...: the unset of the option
   if (is_word(option, 'noxtics noytics nox2tics noy2tics nocbtics nomxtics nomytics nokey nogrid noborder')) then
      block
         type(token_object), allocatable :: words(:) !< The option without its `no`.

         words = tokens
         words(1)%text = option(3:)
         call self%unset_command(words, iostat, iomsg)
      endblock
      return
   endif
   if (keyword(option, 'title', 3_I4P)) then
      call title_option
   elseif (keyword(option, 'xlabel', 2_I4P)) then
      if (.not. axis_label(1_I4P)) return
      call self%figure%set_xlabel(text)
   elseif (keyword(option, 'ylabel', 2_I4P)) then
      if (.not. axis_label(2_I4P)) return
      call self%figure%set_ylabel(text)
   elseif (keyword(option, 'y2label', 3_I4P)) then
      if (.not. axis_label(3_I4P)) return
      call self%figure%set_y2label(text)
   elseif (keyword(option, 'x2label', 3_I4P)) then
      if (.not. axis_label(4_I4P)) return
      call self%figure%set_x2label(text)
   elseif (keyword(option, 'rlabel', 3_I4P)) then
      ! gnuplot `set rlabel`: over the radial axis of polar plots
      if (.not. axis_label(5_I4P)) return
      self%figure%panels(self%figure%current)%raxis%label = text
   elseif (keyword(option, 'label', 3_I4P) .or. keyword(option, 'arrow', 3_I4P) .or. keyword(option, 'object', 3_I4P) &
           .or. option == 'pixmap') then
      call self%annotation_option(tokens, iostat, iomsg)
   elseif (is_word(option, 'xdata ydata y2data x2data xda yda y2da x2da xdat ydat y2dat x2dat')) then
      ! `set xdata time`: the x data are times read with the timefmt, the axis ticked and labelled as times
      if (size(tokens) > 2) then
         call fail('set '//option//': time or nothing expected', iostat, iomsg)
         return
      endif
      text = ''
      if (size(tokens) == 2) then
         if (.not. keyword(tokens(2)%text, 'time', 1_I4P)) then
            call fail('set '//option//': time or nothing expected, found "'//tokens(2)%text//'"', iostat, iomsg)
            return
         endif
         text = 'time'
      endif
      call self%set_time_data(option, len(text) > 0)
   elseif (option == 'offset' .or. option == 'offsets') then
      call offsets_option
   elseif (keyword(option, 'timestamp', 5_I4P)) then
      call timestamp_option
   elseif (keyword(option, 'jitter', 3_I4P)) then
      call jitter_option
   elseif (keyword(option, 'parametric', 3_I4P)) then
      ! gnuplot `set parametric`: function items in pairs, x(t), y(t) over trange
      if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
      self%parametric = .true.
   elseif (keyword(option, 'clip', 2_I4P)) then
      ! gnuplot `set clip [points|one|two|radial]`: bare, the points
      if (.not. clip_words(self%figure%panels(self%figure%current), tokens, .true., iostat, iomsg)) return
   elseif (keyword(option, 'linetype', 5_I4P)) then
      call linetype_option
   elseif (keyword(option, 'pointsize', 3_I4P)) then
      ! gnuplot `set pointsize S`: the default point size, 1 when bare
      block
         real(R8P) :: v !< Size.

         v = 1.0_R8P
         if (size(tokens) > 1) then
            i = 1_I4P
            if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) then
               iomsg = 'set pointsize: '//iomsg
               return
            endif
            if (i < size(tokens, kind=I4P)) then
               call fail('set pointsize: unexpected "'//tokens(i + 1_I4P)%text//'"', iostat, iomsg)
               return
            endif
         endif
         if (.not. v > 0.0_R8P) then
            call fail('set pointsize: the size must be positive', iostat, iomsg)
            return
         endif
         self%figure%panels(self%figure%current)%point_scale = v
      endblock
   elseif (keyword(option, 'timefmt', 5_I4P)) then
      if (.not. self%string_argument(tokens, text, iostat, iomsg)) return
      if (len(text) == 0) text = '%d/%m/%y,%H:%M'
      self%timefmt = text
      self%symbols%timefmt = text
      call self%figure%set_timefmt(text)
   elseif (keyword(option, 'xrange', 2_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%xaxis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user, tight=axis%noextend, &
                        reverse=axis%reverse, bounded=axis%bounded, limits=axis%limits)
      endassociate
   elseif (keyword(option, 'yrange', 2_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%yaxis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user, tight=axis%noextend, &
                        reverse=axis%reverse, bounded=axis%bounded, limits=axis%limits)
      endassociate
   elseif (keyword(option, 'y2range', 3_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%y2axis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user, tight=axis%noextend, &
                        reverse=axis%reverse, bounded=axis%bounded, limits=axis%limits)
      endassociate
   elseif (keyword(option, 'x2range', 3_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%x2axis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user, tight=axis%noextend, &
                        reverse=axis%reverse, bounded=axis%bounded, limits=axis%limits)
      endassociate
   elseif (keyword(option, 'logscale', 3_I4P) .and. r_named) then
      ! gnuplot `set logscale r [10]`: the radial axis of the polar panels
      if (size(tokens) > 3) then
         call fail('set logscale r: a base 10 at most is expected', iostat, iomsg)
         return
      endif
      if (size(tokens) == 3) then
         if (tokens(3)%text /= '10') then
            call fail('set logscale r: log bases other than 10 are not supported', iostat, iomsg)
            return
         endif
      endif
      self%figure%panels(self%figure%current)%raxis%log = .true.
   elseif (keyword(option, 'logscale', 3_I4P)) then
      ! the z axis (splot's) apart from the others
      if (size(tokens) >= 2) then
         if (index(tokens(2)%text, 'z') > 0 .and. tokens(2)%kind == TOKEN_WORD) then
            self%figure%panels(self%figure%current)%zaxis%log = .true.
            if (len(tokens(2)%text) == 1) then
               if (size(tokens) >= 3) then
                  if (tokens(3)%text /= '10' .or. size(tokens) > 3) then
                     call fail('logscale: only base 10 is supported', iostat, iomsg)
                     return
                  endif
               endif
               return
            endif
            block
               type(token_object), allocatable :: rest(:) !< The other axes.

               rest = tokens
               rest(2)%text = rest(2)%text(1:index(rest(2)%text, 'z') - 1)//rest(2)%text(index(rest(2)%text, 'z') + 1:)
               if (.not. axes_argument(rest, text, iostat, iomsg)) return
            endblock
            call self%figure%set_logscale(text)
            return
         endif
      else
         self%figure%panels(self%figure%current)%zaxis%log = .true.
      endif
      if (.not. axes_argument(tokens, text, iostat, iomsg)) return
      call self%figure%set_logscale(text)
   elseif (keyword(option, 'grid', 2_I4P)) then
      call grid_option
   elseif (keyword(option, 'spiderplot', 3_I4P)) then
      if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
      ! as gnuplot: spider plot coordinates and data style
      call self%figure%set_spiderplot(.true.)
      self%data_style = 'spiderplot'
   elseif (option == 'paxis') then
      call paxis_option
   elseif (option == 'chi_shape') then
      ! gnuplot `set chi_shape fraction F`: the default characteristic length of concave hulls, F times the longest
      ! edge of the convex hull
      block
         real(R8P) :: v !< Fraction.

         if (size(tokens) /= 3) then
            call fail('set chi_shape: fraction F expected', iostat, iomsg)
            return
         endif
         if (.not. keyword(tokens(2)%text, 'fraction', 2_I4P)) then
            call fail('set chi_shape: fraction F expected', iostat, iomsg)
            return
         endif
         if (.not. to_number(tokens(3)%text, v)) then
            call fail('set chi_shape fraction: a number between 0 and 1 expected', iostat, iomsg)
            return
         endif
         if (.not. (v > 0.0_R8P .and. v <= 1.0_R8P)) then
            call fail('set chi_shape fraction: a number between 0 and 1 expected', iostat, iomsg)
            return
         endif
         self%chi_fraction = v
      endblock
   elseif (option == 'rgbmax') then
      block
         real(R8P) :: v !< Full intensity.

         if (size(tokens) /= 2) then
            call fail('set rgbmax: a positive number expected', iostat, iomsg)
            return
         endif
         if (.not. to_number(tokens(2)%text, v)) then
            call fail('set rgbmax: a positive number expected', iostat, iomsg)
            return
         endif
         if (.not. v > 0.0_R8P) then
            call fail('set rgbmax: a positive number expected', iostat, iomsg)
            return
         endif
         self%rgbmax = v
      endblock
   elseif (keyword(option, 'polar', 3_I4P)) then
      if (size(tokens) >= 2) then
         if (tokens(2)%text == 'grid') then
            call polar_grid_option
            if (iostat /= 0_I4P) return
         elseif (.not. no_more(tokens, 2_I4P, iostat, iomsg)) then
            return
         endif
      endif
      associate(panel => self%figure%panels(self%figure%current))
         if (allocated(panel%series)) then
            if (.not. all(polar_series(panel%series))) then
               call fail('set polar: '//POLAR_STYLES, iostat, iomsg)
               return
            endif
         endif
      endassociate
      call self%figure%set_polar(.true.)
   elseif (keyword(option, 'angles', 2_I4P)) then
      if (size(tokens) == 2) then
         if (keyword(tokens(2)%text, 'degrees', 1_I4P)) then
            call self%figure%set_angles('degrees')
            return
         elseif (keyword(tokens(2)%text, 'radians', 1_I4P)) then
            call self%figure%set_angles('radians')
            return
         endif
      endif
      call fail('set angles: degrees or radians expected', iostat, iomsg)
   elseif (option == 'theta') then
      call theta_option
   elseif (keyword(option, 'rrange', 2_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%raxis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user, tight=axis%noextend)
         if (iostat == 0_I4P .and. axis%min_fixed .and. axis%max_fixed) then
            ! [90:0]: a reversed r axis, as gnuplot (not on a log r axis)
            if (axis%max_user == axis%min_user) call fail('set rrange: an empty range', iostat, iomsg)
         endif
      endassociate
   elseif (keyword(option, 'trange', 2_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%taxis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user)
      endassociate
   elseif (keyword(option, 'rtics', 3_I4P)) then
      call tics_option(self%figure%panels(self%figure%current)%raxis%tics)
   elseif (keyword(option, 'ttics', 3_I4P)) then
      call ttics_option
   elseif (keyword(option, 'raxis', 3_I4P)) then
      if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
      call self%figure%set_raxis(.true.)
   elseif (keyword(option, 'border', 3_I4P)) then
      call border_option
   elseif (keyword(option, 'key', 1_I4P)) then
      call key_option
   elseif (option == 'readout') then
      call readout_option
   elseif (keyword(option, 'palette', 3_I4P)) then
      call palette_option
   elseif (option == 'colormap') then
      call colormap_option
   elseif (option == 'link') then
      call link_option
   elseif (keyword(option, 'nonlinear', 4_I4P)) then
      call nonlinear_option
   elseif (keyword(option, 'colorsequence', 6_I4P)) then
      call colorsequence_option
   elseif (keyword(option, 'cbrange', 3_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%cbaxis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user, tight=axis%noextend, &
                        reverse=axis%reverse, bounded=axis%bounded, limits=axis%limits)
      endassociate
   elseif (keyword(option, 'cblabel', 3_I4P)) then
      ! `set cblabel "text" [font F]`
      block
         integer(I4P) :: f !< The `font` word, or past the end.

         f = size(tokens, kind=I4P) + 1_I4P
         do k = 2_I4P, size(tokens, kind=I4P)
            if (tokens(k)%kind == TOKEN_WORD .and. tokens(k)%text == 'font') then
               f = k
               exit
            endif
         enddo
         if (.not. self%string_argument(tokens(1:f - 1_I4P), text, iostat, iomsg)) return
         if (f <= size(tokens, kind=I4P)) then
            if (.not. font_spec(self, tokens, f, self%figure%panels(self%figure%current)%cblabel_font, iostat, &
                                iomsg)) then
               iomsg = 'set cblabel: '//iomsg
               return
            endif
            if (.not. no_more(tokens, f + 1_I4P, iostat, iomsg)) return
         endif
      endblock
      call self%figure%set_cblabel(text)
   elseif (keyword(option, 'colorbox', 4_I4P)) then
      call colorbox_option
   elseif (keyword(option, 'boxwidth', 3_I4P)) then
      call boxwidth_option
   elseif (keyword(option, 'output', 2_I4P)) then
      if (size(tokens) < 2) then
         ! bare (gnuplot: the standard output): back to the default output
         if (allocated(self%default_output)) self%output = self%default_output
         self%output_set = .false.
         return
      endif
      if (.not. self%string_argument(tokens, text, iostat, iomsg)) return
      if (len(text) == 0) then
         call fail('set output: a file name is required', iostat, iomsg)
         return
      endif
      self%output = text
      self%output_set = .true.
   elseif (keyword(option, 'encoding', 3_I4P)) then
      ! gnuplot's encodings foresight writes faithfully: default (bytes as they are), utf8 (locale, here) and iso_8859_1
      text = 'default'
      if (size(tokens) >= 2) then
         if (tokens(2)%kind == TOKEN_WORD .and. is_word(tokens(2)%text, 'default utf8 locale')) then
            text = tokens(2)%text
         elseif (tokens(2)%kind == TOKEN_WORD .and. size(tokens) == 2 .and. &
                 .not. string_variable_of(self%symbols, tokens(2)%text)) then
            ! an encoding name (iso_8859_1, cp1252, ...), not a variable holding one
            text = tokens(2)%text
         else
            i = 2_I4P
            if (.not. self%string_expression(tokens, i, text, iostat, iomsg)) then
               iomsg = 'set encoding: '//iomsg
               return
            endif
         endif
      endif
      if (text == 'locale') text = 'utf8'
      if (.not. is_word(text, 'default utf8 iso_8859_1')) then
         call fail('set encoding: only default, utf8, locale and iso_8859_1 are supported (the output is UTF-8), not "'// &
                   text//'"', iostat, iomsg)
         return
      endif
      ! ISO 8859-1: its texts written in UTF-8 (gnuplot declares the encoding of its output instead)
      self%figure%latin1 = text == 'iso_8859_1'
      if (text == 'utf8' .and. (self%minus_sign .or. self%micro)) then
         call fail('set encoding utf8: set minussign and set micro are not supported with it (unset them first)', &
                   iostat, iomsg)
         return
      endif
      self%encoding = text
      call self%symbols%set_string('GPVAL_ENCODING', text)
   elseif (keyword(option, 'terminal', 2_I4P)) then
      if (size(tokens) < 2) then
         call fail('set terminal: svg, html, dumb or block expected', iostat, iomsg)
         return
      endif
      text = tokens(2)%text
      ! gnuplot's terminal stack: foresight keeps its one terminal (a script pushes before a printing terminal and pops
      ! after it)
      if (text == 'push' .or. text == 'pop') then
         if (.not. no_more(tokens, 3_I4P, iostat, iomsg)) return
         return
      endif
      select case (text)
      case ('svg', 'html')
      case ('dumb', 'block')
         ! gnuplot dumb and block default size, in characters
         self%figure%width = 79.0_R8P * DUMB_CELL(1) * self%figure%font_size
         self%figure%height = 24.0_R8P * DUMB_CELL(2) * self%figure%font_size
         call self%figure%set_text(charset=merge('dumb     ', 'quadrants', text == 'dumb'), colors='mono')
      case default
         call fail('set terminal: unsupported terminal "'//text//'" (supported: svg, html, dumb, block)', iostat, iomsg)
         return
      endselect
      self%term_name = text
      call self%symbols%set_string('GPVAL_TERM', text)
      i = 3_I4P
      do while (i <= size(tokens, kind=I4P))
         if (is_word(tokens(i)%text, 'enhanced noenhanced')) then
            call self%figure%set_enhanced(tokens(i)%text == 'enhanced')
         elseif ((text == 'dumb' .or. text == 'block') .and. is_word(tokens(i)%text, 'mono ansi ansi256 ansirgb')) then
            call self%figure%set_text(colors=tokens(i)%text)
         elseif (text == 'block' .and. is_word(tokens(i)%text, 'half quadrants sextants braille')) then
            call self%figure%set_text(charset=tokens(i)%text)
         elseif (keyword(tokens(i)%text, 'size', 2_I4P)) then
            if (.not. next_integer(tokens, i, width, iostat, iomsg)) return
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) then
               call fail('set terminal: size W,H expected', iostat, iomsg)
               return
            endif
            if (tokens(i)%kind /= TOKEN_COMMA) then
               call fail('set terminal: size W,H expected', iostat, iomsg)
               return
            endif
            if (.not. next_integer(tokens, i, height, iostat, iomsg)) return
            if (width < 1_I4P .or. height < 1_I4P) then
               call fail('set terminal: size must be positive', iostat, iomsg)
               return
            endif
            if (text == 'dumb' .or. text == 'block') then
               ! characters to the virtual pixels of the text devices
               self%figure%width = real(width, R8P) * DUMB_CELL(1) * self%figure%font_size
               self%figure%height = real(height, R8P) * DUMB_CELL(2) * self%figure%font_size
            else
               self%figure%width = real(width, R8P)
               self%figure%height = real(height, R8P)
            endif
         elseif (keyword(tokens(i)%text, 'refresh', 3_I4P)) then
            if (.not. next_integer(tokens, i, seconds, iostat, iomsg)) return
            call self%figure%set_refresh(seconds)
         elseif (tokens(i)%text == 'theme') then
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) then
               call fail('set terminal: theme needs a name ('//THEMES//')', iostat, iomsg)
               return
            endif
            if (.not. is_word(tokens(i)%text, THEMES)) then
               call fail('set terminal: unknown theme "'//tokens(i)%text//'" (supported: '//THEMES//')', iostat, iomsg)
               return
            endif
            call self%figure%set_theme(name=tokens(i)%text)
         elseif (tokens(i)%text == 'glow' .or. tokens(i)%text == 'noglow') then
            call self%figure%set_theme(glow=tokens(i)%text == 'glow')
         elseif (tokens(i)%text == 'font') then
            block
               type(font_object) :: font !< Page font.

               if (.not. font_spec(self, tokens, i, font, iostat, iomsg)) then
                  iomsg = 'set terminal: '//iomsg
                  return
               endif
               ! the size and family of every text (gnuplot's terminal font)
               if (font%size > 0.0_R8P) self%figure%font_size = font%size
               self%figure%font_family = font%family
            endblock
         else
            call fail('set terminal: unsupported option "'//tokens(i)%text//'"', iostat, iomsg)
            return
         endif
         i = i + 1_I4P
      enddo
      ! the terminal decides the format of the default output, never of one set explicitly
      if (.not. self%output_set) then
         if (text == 'dumb' .or. text == 'block') then
            self%output = '-'
         elseif (self%output == '-') then
            self%output = 'foresight.'//text
         else
            self%output = change_extension(self%output, text)
         endif
      endif
   elseif (keyword(option, 'style', 2_I4P)) then
      call style_option
   elseif (is_word(option, 'lmargin rmargin tmargin bmargin lmar rmar tmar bmar lmarg rmarg tmarg bmarg')) then
      ! set lmargin [[at screen] N]: characters, or the border at a page fraction; bare or negative, computed
      i = 1_I4P
      if (.not. margin_value(option(1:1))) return
      if (i < size(tokens, kind=I4P)) then
         call fail('set '//option//': [at screen] N expected', iostat, iomsg)
         return
      endif
   elseif (keyword(option, 'margins', 4_I4P)) then
      ! set margins L, R, B, T (gnuplot's order), each [at screen] N
      i = 1_I4P
      do k = 1_I4P, 4_I4P
         if (.not. margin_value('lrbt'(k:k))) return
         if (k < 4_I4P) then
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) then
               call fail('set margins: L, R, B, T expected', iostat, iomsg)
               return
            endif
            if (tokens(i)%kind /= TOKEN_COMMA) then
               call fail('set margins: L, R, B, T expected', iostat, iomsg)
               return
            endif
         endif
      enddo
      if (i < size(tokens, kind=I4P)) then
         call fail('set margins: L, R, B, T expected', iostat, iomsg)
         return
      endif
   elseif (keyword(option, 'dummy', 2_I4P)) then
      ! set dummy NAME[, NAME2...]: the first names the variable of the functions (the others are splot's)
      if (size(tokens) < 2) then
         self%dummy = ''
   self%dummies = ''
      elseif (tokens(2)%kind /= TOKEN_WORD .or. &
              verify(tokens(2)%text, UNAME_CHARS) /= 0 .or. &
              scan(tokens(2)%text(1:1), '0123456789') > 0) then
         call fail('set dummy: a variable name is expected, found "'//tokens(2)%text//'"', iostat, iomsg)
         return
      else
         self%dummy = tokens(2)%text
         ! all the names, for a fit of several variables (`set dummy x, y, x2, x3`)
         self%dummies = ''
         do i = 2_I4P, size(tokens, kind=I4P)
            if (tokens(i)%kind == TOKEN_WORD) self%dummies = self%dummies//' '//tokens(i)%text
         enddo
      endif
   elseif (keyword(option, 'autoscale', 4_I4P)) then
      call autoscale_option
   elseif (keyword(option, 'zeroaxis', 4_I4P)) then
      call zeroaxis_option('x y')
   elseif (keyword(option, 'xzeroaxis', 5_I4P)) then
      call zeroaxis_option('x')
   elseif (keyword(option, 'yzeroaxis', 5_I4P)) then
      call zeroaxis_option('y')
   elseif (keyword(option, 'x2zeroaxis', 6_I4P)) then
      call zeroaxis_option('x2')
   elseif (keyword(option, 'y2zeroaxis', 6_I4P)) then
      call zeroaxis_option('y2')
   elseif (keyword(option, 'termoption', 5_I4P)) then
      ! gnuplot's terminal options foresight honours: dashed lines are always there (dash, dashed), its text is never
      ! enhanced (noenhanced); font is read and ignored
      i = 2_I4P
      do while (i <= size(tokens, kind=I4P))
         select case (tokens(i)%text)
         case ('dash', 'dashed')
            continue
         case ('noenhanced', 'noenh')
            call self%figure%set_enhanced(.false.)
         case ('enhanced', 'enh')
            call self%figure%set_enhanced(.true.)
         case ('font')
            block
               type(font_object) :: font !< Page font.

               if (.not. font_spec(self, tokens, i, font, iostat, iomsg)) then
                  iomsg = 'set terminal: '//iomsg
                  return
               endif
               ! the size and family of every text (gnuplot's terminal font)
               if (font%size > 0.0_R8P) self%figure%font_size = font%size
               self%figure%font_family = font%family
            endblock
         case default
            call fail('set termoption: unsupported option "'//tokens(i)%text//'" (dash, noenhanced, font)', iostat, &
                      iomsg)
            return
         endselect
         i = i + 1_I4P
      enddo
   elseif (keyword(option, 'ticscale', 5_I4P)) then
      ! gnuplot's old form of set tics scale
      call all_tics_option(scale_only=.true.)
   elseif (keyword(option, 'tics', 3_I4P)) then
      call all_tics_option(scale_only=.false.)
   elseif (keyword(option, 'xtics', 3_I4P)) then
      call tics_option(self%figure%panels(self%figure%current)%xaxis%tics)
   elseif (keyword(option, 'ytics', 3_I4P)) then
      call tics_option(self%figure%panels(self%figure%current)%yaxis%tics)
   elseif (keyword(option, 'y2tics', 4_I4P)) then
      call tics_option(self%figure%panels(self%figure%current)%y2axis%tics)
   elseif (keyword(option, 'x2tics', 4_I4P)) then
      call tics_option(self%figure%panels(self%figure%current)%x2axis%tics)
   elseif (keyword(option, 'cbtics', 4_I4P)) then
      call tics_option(self%figure%panels(self%figure%current)%cbaxis%tics)
   elseif (keyword(option, 'mxtics', 3_I4P)) then
      call minor_option(self%figure%panels(self%figure%current)%xaxis%tics)
   elseif (keyword(option, 'mytics', 3_I4P)) then
      call minor_option(self%figure%panels(self%figure%current)%yaxis%tics)
   elseif (keyword(option, 'my2tics', 4_I4P)) then
      call minor_option(self%figure%panels(self%figure%current)%y2axis%tics)
   elseif (keyword(option, 'mx2tics', 4_I4P)) then
      call minor_option(self%figure%panels(self%figure%current)%x2axis%tics)
   elseif (keyword(option, 'mcbtics', 4_I4P)) then
      call minor_option(self%figure%panels(self%figure%current)%cbaxis%tics)
   elseif (keyword(option, 'datafile', 5_I4P)) then
      ! `columnheaders` (or `nocolumnheaders`) first, the other options after it as their own setting
      if (size(tokens) > 1) then
         if (keyword(tokens(2)%text, 'columnheaders', 7_I4P) .or. keyword(tokens(2)%text, 'nocolumnheaders', 9_I4P)) &
            then
            self%column_headers = tokens(2)%text(1:2) /= 'no'
            if (size(tokens) > 2) call self%set_command([tokens(1), tokens(3:)], iostat, iomsg)
            return
         endif
      endif
      call datafile_option
   elseif (option == 'fit') then
      call fit_option
   elseif (keyword(option, 'print', 2_I4P)) then
      call print_option
   elseif (keyword(option, 'table', 3_I4P)) then
      call table_option
   elseif (keyword(option, 'errorbars', 6_I4P) .or. keyword(option, 'bars', 3_I4P)) then
      call errorbars_option
   elseif (keyword(option, 'samples', 3_I4P)) then
      call samples_option(.true.)
   elseif (keyword(option, 'format', 3_I4P)) then
      call format_option
   elseif (keyword(option, 'origin', 2_I4P)) then
      call pair_option([0.0_R8P, 0.0_R8P], tokens)
   elseif (keyword(option, 'size', 2_I4P)) then
      call size_option
   elseif (option == 'isotropic') then
      ! gnuplot 6.0 `set isotropic`: equal unit lengths on x and y, `set size ratio -1` in 2D
      if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
      call self%figure%set_size(ratio=-1.0_R8P)
   elseif (keyword(option, 'multiplot', 5_I4P)) then
      rows = 0_I4P
      cols = 0_I4P
      margins = -1.0_R8P
      spacing = 0.05_R8P
      margin_chars = .false.
      spacing_chars = .false.
      set_margins = .false.
      set_spacing = .false.
      text = ''
      columns_first = .false.
      upwards = .false.
      i = 2_I4P
      do while (i <= size(tokens, kind=I4P))
         if (keyword(tokens(i)%text, 'rowsfirst', 3_I4P)) then
            columns_first = .false.
         elseif (keyword(tokens(i)%text, 'columnsfirst', 3_I4P)) then
            columns_first = .true.
         elseif (keyword(tokens(i)%text, 'downwards', 4_I4P)) then
            upwards = .false.
         elseif (keyword(tokens(i)%text, 'upwards', 2_I4P)) then
            upwards = .true.
         elseif (tokens(i)%text == 'font') then
            ! the font of the title
            if (.not. font_spec(self, tokens, i, self%figure%title_font, iostat, iomsg)) then
               iomsg = 'set multiplot: '//iomsg
               return
            endif
         elseif (keyword(tokens(i)%text, 'margins', 3_I4P)) then
            ! `margins [screen|char] L, R, B, T`: the unit of one value is that of the next too
            unit_chars = .false.
            do k = 1_I4P, 4_I4P
               if (k > 1_I4P) then
                  i = i + 1_I4P
                  if (i > size(tokens, kind=I4P)) exit
                  if (tokens(i)%kind /= TOKEN_COMMA) exit
               endif
               if (.not. layout_value(margins(k), unit_chars)) return
               margin_chars(k) = unit_chars
            enddo
            if (k <= 4_I4P) then
               call fail('set multiplot: margins LEFT, RIGHT, BOTTOM, TOP expected', iostat, iomsg)
               return
            endif
            set_margins = .true.
         elseif (keyword(tokens(i)%text, 'spacing', 3_I4P)) then
            ! `spacing [screen|char] X [, [screen|char] Y]`: Y is X when absent
            unit_chars = .false.
            if (.not. layout_value(spacing(1), unit_chars)) return
            spacing_chars = unit_chars
            spacing(2) = spacing(1)
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%kind == TOKEN_COMMA) then
                  i = i + 1_I4P
                  if (.not. layout_value(spacing(2), unit_chars)) return
                  spacing_chars(2) = unit_chars
               endif
            endif
            set_spacing = .true.
         elseif (keyword(tokens(i)%text, 'layout', 3_I4P)) then
            if (.not. next_integer(tokens, i, rows, iostat, iomsg)) return
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) then
               call fail('set multiplot: layout ROWS,COLS expected', iostat, iomsg)
               return
            endif
            if (tokens(i)%kind /= TOKEN_COMMA) then
               call fail('set multiplot: layout ROWS,COLS expected', iostat, iomsg)
               return
            endif
            if (.not. next_integer(tokens, i, cols, iostat, iomsg)) return
         elseif (keyword(tokens(i)%text, 'title', 1_I4P)) then
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) then
               call fail('set multiplot: title needs a quoted string', iostat, iomsg)
               return
            endif
            if (.not. self%string_expression(tokens, i, text, iostat, iomsg)) then
               iomsg = 'set multiplot: title: '//iomsg
               return
            endif
         else
            call fail('set multiplot: unsupported option "'//tokens(i)%text//'"', iostat, iomsg)
            return
         endif
         i = i + 1_I4P
      enddo
      if (rows == 0_I4P .and. cols == 0_I4P) then
         ! no layout: manual multiplot, each panel in its set origin / set size box
         call self%figure%set_multiplot(title=text)
      else
         if (rows < 1_I4P .or. cols < 1_I4P) then
            call fail('set multiplot: layout ROWS,COLS needs positive values', iostat, iomsg)
            return
         endif
         associate(panel => self%figure%panels(self%figure%current))
            if (any(panel%origin /= 0.0_R8P) .or. any(panel%size /= 1.0_R8P)) then
               call fail('set multiplot: a layout needs the default origin and size (set origin 0,0; set size 1,1)', &
                         iostat, iomsg)
               return
            endif
         endassociate
         call self%figure%set_multiplot(rows, cols, text)
         self%figure%columns_first = columns_first
         self%figure%upwards = upwards
         ! gnuplot: margins place every plot area, with spacing (0.05 screen without); spacing alone does nothing
         if (set_margins) then
            if (set_spacing .and. (any(margins < 0.0_R8P) .or. any(spacing < 0.0_R8P))) then
               call fail('set multiplot: must give positive margin and spacing values', iostat, iomsg)
               return
            endif
            self%figure%layout_margins = margins
            self%figure%layout_chars = margin_chars
            if (set_spacing) then
               self%figure%layout_spacing = spacing
               self%figure%spacing_chars = spacing_chars
            endif
         endif
      endif
      self%multiplot = .true.
      self%advance_pending = .false.
   elseif (keyword(option, 'isosamples', 3_I4P)) then
      ! the surfaces' (splot, not in foresight); M the v samples of the `'++'` pseudo-file
      call samples_option(.false.)
   elseif (keyword(option, 'pm3d', 2_I4P)) then
      call pm3d_option(tokens)
   elseif (keyword(option, 'contour', 3_I4P)) then
      ! `set contour [base|surface|both]`
      associate(cnt => self%figure%panels(self%figure%current)%contour)
         cnt%place = 'base'
         if (size(tokens) > 1) then
            if (keyword(tokens(2)%text, 'base', 2_I4P)) then
               cnt%place = 'base'
            elseif (keyword(tokens(2)%text, 'surface', 1_I4P)) then
               cnt%place = 'surface'
            elseif (keyword(tokens(2)%text, 'both', 2_I4P)) then
               cnt%place = 'both'
            else
               call fail('set contour: base, surface or both expected, found "'//tokens(2)%text//'"', iostat, iomsg)
               return
            endif
            if (.not. no_more(tokens, 3_I4P, iostat, iomsg)) return
         endif
         cnt%on = .true.
      endassociate
   elseif (keyword(option, 'cntrparam', 5_I4P)) then
      call cntrparam_option(tokens)
   elseif (keyword(option, 'dgrid3d', 2_I4P)) then
      call dgrid3d_option(tokens)
   elseif (keyword(option, 'cntrlabel', 5_I4P)) then
      call cntrlabel_option(tokens)
   elseif (option == 'view') then
      call view_option(tokens)
   elseif (keyword(option, 'xyplane', 3_I4P) .or. keyword(option, 'ticslevel', 5_I4P)) then
      call xyplane_option(tokens)
   elseif (keyword(option, 'surface', 2_I4P)) then
      ! `set surface [implicit|explicit]`: the surfaces drawn (the pm3d modes read)
      if (size(tokens) > 1) then
         if (.not. is_word(tokens(2)%text, 'implicit explicit')) then
            call fail('set surface: implicit or explicit expected, found "'//tokens(2)%text//'"', iostat, iomsg)
            return
         endif
         if (.not. no_more(tokens, 3_I4P, iostat, iomsg)) return
      endif
      self%figure%panels(self%figure%current)%view3d%surface = .true.
   elseif (keyword(option, 'zrange', 2_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%zaxis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user, tight=axis%noextend, &
                        reverse=axis%reverse, bounded=axis%bounded, limits=axis%limits)
      endassociate
   elseif (keyword(option, 'zlabel', 2_I4P)) then
      if (.not. axis_label(6_I4P)) return
      self%figure%panels(self%figure%current)%zaxis%label = text
   elseif (keyword(option, 'ztics', 3_I4P)) then
      call tics_option(self%figure%panels(self%figure%current)%zaxis%tics)
   elseif (keyword(option, 'mztics', 3_I4P)) then
      call minor_option(self%figure%panels(self%figure%current)%zaxis%tics)
   elseif (keyword(option, 'zzeroaxis', 5_I4P)) then
      ! the z zero axis of the 3D views (its line options read)
      i = 1_I4P
      do while (i < size(tokens, kind=I4P))
         i = i + 1_I4P
         if (tokens(i)%kind /= TOKEN_WORD .or. .not. is_line_option(tokens(i)%text)) then
            call fail('set zzeroaxis: unsupported option "'//tokens(i)%text//'" (lt, lc, lw, dt)', iostat, iomsg)
            return
         endif
         i = i + 1_I4P
         if (i < size(tokens, kind=I4P)) then
            if (tokens(i)%text == 'rgb' .or. tokens(i)%text == 'rgbcolor') i = i + 1_I4P
         endif
      enddo
      self%figure%panels(self%figure%current)%view3d%zzeroaxis = .true.
   elseif (keyword(option, 'urange', 2_I4P) .or. keyword(option, 'vrange', 2_I4P)) then
      ! u and v the ranges of the `'++'` pseudo-file
      block
         logical   :: fixed(2) !< Bound given.
         real(R8P) :: bound(2) !< Bounds.
         integer(I4P) :: c     !< Column: 1 u, 2 v.

         call set_range(fixed(1), bound(1), fixed(2), bound(2))
         if (iostat == 0_I4P) then
            c = merge(1_I4P, 2_I4P, option(1:1) == 'u')
            if (fixed(1)) self%uv_range(1, c) = bound(1)
            if (fixed(2)) self%uv_range(2, c) = bound(2)
         endif
      endblock
   elseif (keyword(option, 'mouse', 3_I4P)) then
      ! interactive terminals only: the options are not read
      continue
   elseif (keyword(option, 'macros', 3_I4P)) then
      ! macros are always on, as gnuplot 6.0's (the command is kept for old scripts)
      if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
   elseif (option == 'pointintervalbox') then
      ! the blank around the points of `pointinterval` lines, not drawn by foresight: checked and ignored
      block
         real(R8P) :: v !< Box size.

         i = 2_I4P
         if (i > size(tokens, kind=I4P)) return
         last = expression_end(tokens, i)
         call self%symbols%constant(expression_source(tokens(i:last)), v, iostat, iomsg, &
                                    degrees=self%figure%panels(self%figure%current)%degrees)
         if (iostat /= 0_I4P) then
            iomsg = 'set pointintervalbox: '//iomsg
            return
         endif
         if (.not. no_more(tokens, last + 1_I4P, iostat, iomsg)) return
      endblock
   elseif (keyword(option, 'minussign', 5_I4P) .or. keyword(option, 'minus_sign', 5_I4P) .or. &
           keyword(option, 'micro', 3_I4P)) then
      ! gnuplot's minus sign (U+2212) and micro sign: only for an encoding that has them, not the default one
      if (self%encoding == 'utf8') then
         call fail('set '//option//': not supported with set encoding utf8 (the default encoding has no such sign)', &
                   iostat, iomsg)
         return
      endif
      if (keyword(option, 'micro', 3_I4P)) then
         ! `set micro "string"`: the sign to use, read
         if (size(tokens) > 1) then
            i = 2_I4P
            if (.not. self%string_expression(tokens, i, text, iostat, iomsg)) then
               iomsg = 'set micro: '//iomsg
               return
            endif
            if (.not. no_more(tokens, i + 1_I4P, iostat, iomsg)) return
         endif
         self%micro = .true.
      else
         if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
         self%minus_sign = .true.
      endif
   elseif (keyword(option, 'overflow', 3_I4P)) then
      ! integer overflow of + - * **: float (default), undefined or NaN (gnuplot 6.0)
      if (size(tokens) == 1) then
         overflow_mode = OVERFLOW_FLOAT
      elseif (tokens(2)%text == 'float') then
         overflow_mode = OVERFLOW_FLOAT
      elseif (tokens(2)%text == 'undefined') then
         overflow_mode = OVERFLOW_UNDEFINED
      elseif (tokens(2)%text == 'NaN' .or. tokens(2)%text == 'nan') then
         overflow_mode = OVERFLOW_NAN
      else
         call fail('set overflow: float, undefined or NaN expected, found "'//tokens(2)%text//'"', iostat, iomsg)
         return
      endif
      if (size(tokens) > 2) then
         if (.not. no_more(tokens, 3_I4P, iostat, iomsg)) return
      endif
   elseif (keyword(option, 'mttics', 3_I4P)) then
      call minor_option(self%figure%panels(self%figure%current)%ttics)
   else
      call fail('unsupported option "set '//option//'"', iostat, iomsg)
   endif
   contains
      function layout_value(v, chars) result(ok)
      !< A multiplot margin or spacing after token `i` (left on its last token): `[screen|char[acter]] EXPR`, the unit
      !< kept from the previous value when absent (`chars`); negative is none (-1), a screen fraction clamped to [0,1].
      real(R8P), intent(out)   :: v     !< Value.
      logical,   intent(inout) :: chars !< In characters, else screen.
      logical                  :: ok    !< Read.

      v = -1.0_R8P
      ok = .false.
      i = i + 1_I4P
      if (i > size(tokens, kind=I4P)) then
         call fail('set multiplot: a margin or spacing value is expected', iostat, iomsg)
         return
      endif
      if (keyword(tokens(i)%text, 'screen', 2_I4P)) then
         chars = .false.
         i = i + 1_I4P
      elseif (keyword(tokens(i)%text, 'character', 4_I4P)) then
         chars = .true.
         i = i + 1_I4P
      endif
      if (i > size(tokens, kind=I4P)) then
         call fail('set multiplot: a margin or spacing value is expected', iostat, iomsg)
         return
      endif
      last = expression_end(tokens, i)
      call self%symbols%constant(expression_source(tokens(i:last)), v, iostat, iomsg, &
                                 degrees=self%figure%panels(self%figure%current)%degrees)
      if (iostat /= 0_I4P) then
         iomsg = 'set multiplot: '//iomsg
         return
      endif
      i = last
      if (v < 0.0_R8P) v = -1.0_R8P
      if (.not. chars .and. v >= 0.0_R8P) v = min(v, 1.0_R8P)
      ok = .true.
      endfunction layout_value

      subroutine set_range(min_fixed, min_user, max_fixed, max_user, tight, reverse, bounded, limits)
      !< Parse `[[min:max]] [noextend|extend] [reverse|noreverse] [nowriteback]`: `*` or an empty end autoscales it, `[]`
      !< or no range keeps both; `noextend` keeps autoscaled ends at the data (`tight`), `reverse` reverses an axis with
      !< an autoscaled end, as gnuplot; `lb<*<ub` an autoscaled end within limits (`bounded`, `limits`).
      logical,   intent(inout)           :: min_fixed !< Start fixed.
      real(R8P), intent(inout)           :: min_user  !< Start value.
      logical,   intent(inout)           :: max_fixed !< End fixed.
      real(R8P), intent(inout)           :: max_user  !< End value.
      logical,   intent(inout), optional :: tight     !< Autoscaled ends not extended to the ticks.
      logical,   intent(inout), optional :: reverse   !< Reversed with an autoscaled end.
      logical,   intent(inout), optional :: bounded(2, 2) !< Limits of the autoscaled ends given (end, lower|upper).
      real(R8P), intent(inout), optional :: limits(2, 2)  !< Those limits.
      integer(I4P)                       :: colon     !< Separator position.
      integer(I4P)                       :: k         !< Option counter.
      integer(I4P)                       :: first     !< First option token.

      if (size(tokens) < 2) then
         call fail('set '//option//': [min:max] expected', iostat, iomsg)
         return
      endif
      first = merge(3_I4P, 2_I4P, tokens(2)%kind == TOKEN_RANGE)
      do k = first, size(tokens, kind=I4P)
         select case (tokens(k)%text)
         case ('noextend', 'extend')
            if (.not. present(tight)) then
               call fail('set '//option//': '//tokens(k)%text//' applies to x, y, x2, y2, r and cb', iostat, iomsg)
               return
            endif
            tight = tokens(k)%text == 'noextend'
         case ('reverse', 'noreverse')
            if (present(reverse)) then
               reverse = tokens(k)%text == 'reverse'
            elseif (tokens(k)%text == 'reverse') then
               call fail('set '//option//': reverse applies to x, y, x2, y2 and cb', iostat, iomsg)
               return
            endif
         case ('nowriteback')
            continue
         case default
            call fail('set '//option//': unsupported option "'//tokens(k)%text//'" (noextend, extend, reverse, '// &
                      'noreverse, nowriteback)', iostat, iomsg)
            return
         endselect
      enddo
      if (first == 2_I4P) return
      if (tokens(2)%kind == TOKEN_RANGE .and. len_trim(tokens(2)%text) == 0) then
         ! `[]` keeps the range and forgets the limits of its ends, as gnuplot's load_range
         if (present(bounded)) bounded = .false.
         return
      endif
      colon = top_colon(tokens(2)%text)
      if (tokens(2)%kind /= TOKEN_RANGE .or. colon == 0_I4P) then
         call fail('set '//option//': [min:max] expected', iostat, iomsg)
         return
      endif
      call range_end(tokens(2)%text(1:colon - 1_I4P), min_fixed, min_user, 1_I4P, bounded, limits)
      if (iostat /= 0_I4P) return
      call range_end(tokens(2)%text(colon + 1_I4P:), max_fixed, max_user, 2_I4P, bounded, limits)
      endsubroutine set_range

      subroutine range_end(text, fixed, value, e, bounded, limits)
      !< One range end (`e` 1 the start, 2 the end): empty keeps the end as it is (fixed or autoscaled, as gnuplot 6.0:
      !< `set xrange [2:5]; set xrange [:10]` is [2:10]), `*` autoscales, `lb<*`, `*<ub`, `lb<*<ub` autoscales within
      !< limits (`bounded`, `limits`), else a number or a constant expression (`2*pi`, user variables).
      character(len=*), intent(in)              :: text  !< End text.
      logical,          intent(inout)           :: fixed !< End fixed.
      real(R8P),        intent(inout)           :: value !< End value.
      integer(I4P),     intent(in)              :: e     !< End.
      logical,          intent(inout), optional :: bounded(2, 2) !< Limits given (end, lower|upper).
      real(R8P),        intent(inout), optional :: limits(2, 2)  !< Limits.
      character(len=:), allocatable   :: rest  !< Text after the star.
      integer(I4P)                    :: star  !< The star.
      real(R8P)                       :: v     !< Parsed value.

      ! an empty end keeps the end and its limits (probed: gnuplot 6.0 keeps a set value); a given one decides them
      if (len_trim(text) == 0) return
      if (present(bounded)) bounded(e, :) = .false.
      if (trim(adjustl(text)) == '*') then
         fixed = .false.
         return
      endif
      star = index(text, '*', kind=I4P)
      if (star > 0_I4P .and. index(text, '<') > 0) then
         ! gnuplot's limits: the star the autoscaled end, a `<` on each side of it
         if (.not. present(bounded)) then
            call fail('set '//option//': limits of an autoscaled end apply to x, y, x2, y2 and cb', iostat, iomsg)
            return
         endif
         if (star > 1_I4P) then
            if (text(star - 1_I4P:star - 1_I4P) /= '<' .or. len_trim(text(1:star - 2_I4P)) == 0) then
               call fail('set '//option//': LIMIT<*<LIMIT expected, found "'//text//'"', iostat, iomsg)
               return
            endif
            call self%range_value(trim(adjustl(text(1:star - 2_I4P))), v, iostat, iomsg)
            if (iostat /= 0_I4P) then
               iomsg = 'set '//option//': '//iomsg
               return
            endif
            bounded(e, 1) = .true.
            limits(e, 1) = v
         endif
         rest = trim(adjustl(text(star + 1_I4P:)))
         if (len(rest) > 0) then
            if (rest(1:1) /= '<' .or. len_trim(rest) < 2) then
               call fail('set '//option//': LIMIT<*<LIMIT expected, found "'//text//'"', iostat, iomsg)
               return
            endif
            call self%range_value(trim(adjustl(rest(2:))), v, iostat, iomsg)
            if (iostat /= 0_I4P) then
               iomsg = 'set '//option//': '//iomsg
               return
            endif
            bounded(e, 2) = .true.
            limits(e, 2) = v
         endif
         fixed = .false.
         return
      endif
      call self%range_value(trim(adjustl(text)), v, iostat, iomsg)
      if (iostat /= 0_I4P) then
         iomsg = 'set '//option//': '//iomsg
         return
      endif
      fixed = .true.
      value = v
      endsubroutine range_end


      subroutine print_option
      !< `set print ["file" [append] | "-" | $NAME [append]]`: where `print` writes; a file or a datablock is emptied
      !< unless `append`; bare, the standard error.
      character(len=:), allocatable :: name   !< File name.
      integer(I4P)                  :: unit   !< File unit.
      integer(I4P)                  :: k      !< Last token of the name.
      logical                       :: append !< `append` given.
      character(len=:), allocatable :: text   !< Datablock lines.
      logical                       :: found  !< Datablock defined.

      if (size(tokens) == 1) then
         self%print_file = ''
         return
      endif
      k = 2_I4P
      if (tokens(2)%kind == TOKEN_WORD .and. is_datablock(tokens(2)%text)) then
         ! a datablock, its lines the printed ones
         name = tokens(2)%text
      elseif (tokens(2)%kind == TOKEN_STRING .or. tokens(2)%kind == TOKEN_WORD) then
         if (.not. keyword(tokens(2)%text, 'append', 3_I4P) .or. tokens(2)%kind == TOKEN_STRING) then
            if (.not. self%string_expression(tokens, k, name, iostat, iomsg)) then
               iomsg = 'set print: '//iomsg
               return
            endif
         endif
      endif
      append = .false.
      if (k == size(tokens, kind=I4P) - 1_I4P) append = keyword(tokens(k + 1_I4P)%text, 'append', 3_I4P)
      if (.not. allocated(name) .or. (k < size(tokens, kind=I4P) .and. .not. append) .or. &
          k < size(tokens, kind=I4P) - 1_I4P) then
         call fail('set print: "file" [append] or "-" expected', iostat, iomsg)
         return
      endif
      if (name == '-') then
         self%print_file = '-'
         return
      endif
      if (len(name) == 0) then
         self%print_file = ''
         return
      endif
      if (is_datablock(name)) then
         call self%symbols%string_of(name, text, found)
         if (.not. append .or. .not. found) call self%symbols%set_string(name, '')
         self%print_file = name
         return
      endif
      if (.not. append) then
         open(newunit=unit, file=name, status='replace', action='write', iostat=iostat)
         if (iostat /= 0_I4P) then
            call fail('set print: cannot write "'//name//'"', iostat, iomsg)
            return
         endif
         close(unit)
      endif
      self%print_file = name
      endsubroutine print_option

      subroutine histogram_title(s)
      !< `title [tc|textcolor COLOR] [offset X,Y] [font F] [[no]enhanced]` of `set style histogram`, from token `s`
      !< (left on its last token): the color and offset of the group titles.
      integer(I4P), intent(inout)   :: s      !< Token counter.
      type(token_object), allocatable :: copy(:) !< Tokens with `lc` for the color word.
      type(line_style_object)       :: probe  !< Color read.
      real(R8P)                     :: v(2)   !< Offset.

      associate(panel => self%figure%panels(self%figure%current))
         do while (s < size(tokens, kind=I4P))
            if (tokens(s + 1_I4P)%text == 'tc' .or. keyword(tokens(s + 1_I4P)%text, 'textcolor', 5_I4P)) then
               s = s + 1_I4P
               copy = tokens
               copy(s)%text = 'lc'
               if (.not. line_option(copy, s, probe, iostat, iomsg, panel%linecolors, self%symbols)) return
               if (.not. allocated(probe%lc)) cycle
               if (index(probe%lc, '*') == 1) then
                  call fail('set style histogram title: variable and palette colors do not apply', iostat, iomsg)
                  return
               endif
               panel%hist_title_color = probe%lc
            elseif (tokens(s + 1_I4P)%text == 'offset') then
               s = s + 1_I4P
               if (.not. next_real(tokens, s, v(1), iostat, iomsg, self%symbols)) return
               v(2) = 0.0_R8P
               if (s < size(tokens, kind=I4P)) then
                  if (tokens(s + 1_I4P)%kind == TOKEN_COMMA) then
                     s = s + 1_I4P
                     if (.not. next_real(tokens, s, v(2), iostat, iomsg, self%symbols)) return
                  endif
               endif
               panel%hist_title_offset = v
            elseif (tokens(s + 1_I4P)%text == 'font') then
               ! the group titles' font
               s = s + 1_I4P
               if (.not. font_spec(self, tokens, s, panel%hist_title_font, iostat, iomsg)) then
                  iomsg = 'set style histogram: title: '//iomsg
                  return
               endif
            elseif (is_word(tokens(s + 1_I4P)%text, 'enhanced noenhanced')) then
               s = s + 1_I4P
            elseif (is_word(tokens(s + 1_I4P)%text, 'boxed noboxed')) then
               ! the group titles on the background when text box style 0 is drawn (gnuplot's svg textbox)
               s = s + 1_I4P
               panel%hist_title_boxed = tokens(s)%text == 'boxed' .and. self%textbox_drawn(0)
            else
               exit
            endif
         enddo
      endassociate
      endsubroutine histogram_title

      subroutine errorbars_option
      !< `set errorbars [small|large|fullwidth|SIZE] [front|back] [LINE PROPERTIES]`: the cap length of the error bars
      !< and boxplot whiskers (0 small, 1 large, the default; fullwidth taken as large), their line (`lc`, `lw`).
      type(line_style_object) :: probe !< Line read.
      real(R8P)               :: v     !< Size.
      integer(I4P)            :: s     !< Token counter.

      associate(panel => self%figure%panels(self%figure%current))
         panel%errorbar_size = 1.0_R8P
         if (allocated(panel%errorbar_color)) deallocate(panel%errorbar_color)
         panel%errorbar_lw = 0.0_R8P
         s = 2_I4P
         do while (s <= size(tokens, kind=I4P))
            if (keyword(tokens(s)%text, 'small', 2_I4P)) then
               panel%errorbar_size = 0.0_R8P
            elseif (keyword(tokens(s)%text, 'large', 2_I4P) .or. keyword(tokens(s)%text, 'fullwidth', 4_I4P)) then
               panel%errorbar_size = 1.0_R8P
            elseif (is_word(tokens(s)%text, 'front back')) then
               continue
            elseif (is_line_option(tokens(s)%text)) then
               if (.not. line_option(tokens, s, probe, iostat, iomsg, panel%linecolors, self%symbols)) return
               if (allocated(probe%lc)) then
                  if (index(probe%lc, '*') == 1) then
                     call fail('set errorbars: variable and palette colors do not apply', iostat, iomsg)
                     return
                  endif
                  panel%errorbar_color = probe%lc
               endif
               if (allocated(probe%lw)) panel%errorbar_lw = probe%lw
            elseif (to_number(tokens(s)%text, v) .and. s == 2_I4P) then
               if (v < 0.0_R8P) then
                  call fail('set errorbars: the size must not be negative', iostat, iomsg)
                  return
               endif
               panel%errorbar_size = v
            else
               call fail('set errorbars: unsupported option "'//tokens(s)%text//'" (small, large, fullwidth, SIZE, '// &
                         'front, back, lc, lw)', iostat, iomsg)
               return
            endif
            s = s + 1_I4P
         enddo
      endassociate
      endsubroutine errorbars_option

      subroutine table_option
      !< `set table ["file" | $NAME] [append] [separator whitespace|tab|comma|"c"]`: plots write their points to the
      !< file (emptied unless `append`), to the datablock (likewise), or bare to the standard output; nothing is drawn
      !< until `unset table`. The separator, of `plot with table` only, stays until changed (gnuplot: tab).
      character(len=:), allocatable :: name   !< File or datablock name.
      integer(I4P)                  :: unit   !< File unit.
      integer(I4P)                  :: k      !< Last token of the name.
      logical                       :: append !< `append` given.
      logical                       :: found  !< Datablock found.
      integer(I4P)                  :: n      !< Tokens before the separator.

      n = size(tokens, kind=I4P)
      do k = 2_I4P, size(tokens, kind=I4P)
         if (tokens(k)%kind /= TOKEN_WORD .or. .not. keyword(tokens(k)%text, 'separator', 3_I4P)) cycle
         if (k /= size(tokens, kind=I4P) - 1_I4P) then
            call fail('set table: separator whitespace|tab|comma|"c" expected, last', iostat, iomsg)
            return
         endif
         if (tokens(k + 1_I4P)%kind == TOKEN_STRING .and. len(tokens(k + 1_I4P)%text) > 0) then
            self%table_sep = tokens(k + 1_I4P)%text(1:1)
         elseif (is_word(tokens(k + 1_I4P)%text, 'whitespace tab')) then
            self%table_sep = achar(9)
         elseif (tokens(k + 1_I4P)%text == 'comma') then
            self%table_sep = ','
         else
            call fail('set table: separator whitespace|tab|comma|"c" expected', iostat, iomsg)
            return
         endif
         n = k - 1_I4P
         exit
      enddo
      name = '-'
      k = 1_I4P
      if (n > 1_I4P) then
         if (.not. keyword(tokens(2)%text, 'append', 3_I4P) .or. tokens(2)%kind == TOKEN_STRING) then
            k = 2_I4P
            if (.not. self%string_expression(tokens, k, name, iostat, iomsg)) then
               iomsg = 'set table: '//iomsg
               return
            endif
         endif
      endif
      append = .false.
      if (k == n - 1_I4P) append = keyword(tokens(k + 1_I4P)%text, 'append', 3_I4P)
      if ((k < n .and. .not. append) .or. k < n - 1_I4P) then
         call fail('set table: "file" or $NAME [append] [separator S] expected', iostat, iomsg)
         return
      endif
      if (len(name) == 0) name = '-'
      if (is_datablock(name)) then
         call self%symbols%string_of(name, text, found)
         if (.not. append .or. .not. found) call self%symbols%set_string(name, '')
      elseif (name /= '-' .and. .not. append) then
         open(newunit=unit, file=name, status='replace', action='write', iostat=iostat)
         if (iostat /= 0_I4P) then
            call fail('set table: cannot write "'//name//'"', iostat, iomsg)
            return
         endif
         close(unit)
      endif
      self%table = .true.
      self%table_file = name
      endsubroutine table_option

      subroutine fit_option
      !< `set fit [quiet|results|brief] [logfile "file"|nologfile] [limit E] [limit_abs E] [maxiter N|default]
      !< [start-lambda L] [lambda-factor F] [[no]prescale] [[no]errorscaling] [[no]errorvariables]`; bare, the defaults
      !< (silent, no log file, gnuplot's limits).
      character(len=:), allocatable :: word !< Option word.
      real(R8P)                     :: v    !< Number.
      integer(I4P)                  :: n    !< Integer.

      if (size(tokens) == 1) then
         self%fit_options = fit_settings()
         self%fit_verbosity = 'quiet'
         self%fit_logfile = ''
         self%fit_errorvariables = .true.
         return
      endif
      i = 2_I4P
      do while (i <= size(tokens, kind=I4P))
         word = tokens(i)%text
         select case (word)
         case ('quiet', 'results', 'brief')
            self%fit_verbosity = word
         case ('log', 'logf', 'logfi', 'logfil', 'logfile')
            ! gnuplot's log$file
            if (i == size(tokens, kind=I4P)) then
               call fail('set fit logfile: a "file" is expected', iostat, iomsg)
               return
            endif
            i = i + 1_I4P
            if (tokens(i)%kind /= TOKEN_STRING .or. len(tokens(i)%text) == 0) then
               call fail('set fit logfile: a "file" is expected', iostat, iomsg)
               return
            endif
            self%fit_logfile = tokens(i)%text
         case ('nolog', 'nologf', 'nologfi', 'nologfil', 'nologfile')
            self%fit_logfile = ''
         case ('limit', 'limit_abs', 'start-lambda', 'lambda-factor')
            if (.not. next_real(tokens, i, v, iostat, iomsg)) then
               iomsg = 'set fit '//word//': '//iomsg
               return
            endif
            if (.not. v > 0.0_R8P .and. word /= 'limit_abs' .and. word /= 'start-lambda') then
               call fail('set fit '//word//': a positive number is expected', iostat, iomsg)
               return
            endif
            select case (word)
            case ('limit')
               self%fit_options%limit = v
            case ('limit_abs')
               self%fit_options%limit_abs = max(0.0_R8P, v)
            case ('start-lambda')
               self%fit_options%start_lambda = max(0.0_R8P, v)
            case default
               self%fit_options%lambda_factor = v
            endselect
         case ('maxiter')
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%text == 'default') then
                  self%fit_options%maxiter = 0_I4P
                  i = i + 2_I4P
                  cycle
               endif
            endif
            if (.not. next_integer(tokens, i, n, iostat, iomsg)) then
               iomsg = 'set fit maxiter: '//iomsg
               return
            endif
            self%fit_options%maxiter = max(0_I4P, n)
         case ('prescale', 'noprescale')
            self%fit_options%prescale = word == 'prescale'
         case ('errorscaling', 'noerrorscaling')
            self%fit_options%errorscaling = word == 'errorscaling'
         case ('errorvariables', 'noerrorvariables')
            self%fit_errorvariables = word == 'errorvariables'
         case default
            call fail('set fit: unsupported option "'//word//'" (supported: quiet, results, brief, logfile, '// &
                      'nologfile, limit, limit_abs, maxiter, start-lambda, lambda-factor, [no]prescale, '// &
                      '[no]errorscaling, [no]errorvariables)', iostat, iomsg)
            return
         endselect
         i = i + 1_I4P
      enddo
      endsubroutine fit_option

      subroutine jitter_option
      !< gnuplot `set jitter [overlap [first] N] [spread S] [wrap W] [swarm|square|vertical]`: the overlapping points
      !< of `with points` spread out; bare: overlap 1 character, spread 1, no wrap, swarm (gnuplot's set_jitter).
      real(R8P) :: v !< A number.

      associate(panel => self%figure%panels(self%figure%current))
         panel%jitter_overlap = 1.0_R8P
         panel%jitter_first = .false.
         panel%jitter_spread = 1.0_R8P
         panel%jitter_wrap = 0.0_R8P
         panel%jitter_style = 0_I4P
         i = 2_I4P
         do while (i <= size(tokens, kind=I4P))
            if (keyword(tokens(i)%text, 'overlap', 4_I4P)) then
               if (i < size(tokens, kind=I4P)) then
                  if (is_word(tokens(i + 1_I4P)%text, 'first character')) then
                     panel%jitter_first = tokens(i + 1_I4P)%text == 'first'
                     i = i + 1_I4P
                  endif
               endif
               if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) then
                  iomsg = 'set jitter: overlap: '//iomsg
                  return
               endif
               panel%jitter_overlap = v
            elseif (tokens(i)%text == 'spread') then
               if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) then
                  iomsg = 'set jitter: spread: '//iomsg
                  return
               endif
               panel%jitter_spread = merge(v, 1.0_R8P, v > 0.0_R8P)
            elseif (tokens(i)%text == 'wrap') then
               if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) then
                  iomsg = 'set jitter: wrap: '//iomsg
                  return
               endif
               panel%jitter_wrap = v
            elseif (tokens(i)%text == 'swarm') then
               panel%jitter_style = 0_I4P
            elseif (tokens(i)%text == 'square') then
               panel%jitter_style = 1_I4P
            elseif (keyword(tokens(i)%text, 'vertical', 4_I4P)) then
               panel%jitter_style = 2_I4P
            else
               call fail('set jitter: unrecognized keyword "'//tokens(i)%text//'"', iostat, iomsg)
               return
            endif
            i = i + 1_I4P
         enddo
      endassociate
      endsubroutine jitter_option

      subroutine timestamp_option
      !< gnuplot `set timestamp ["format"] [top|bottom] [rotate|norotate] [offset X[,Y]] [font F] [textcolor C]`: the
      !< date and time in the bottom (top) left margin, in the format (gnuplot's asctime by default).
      type(token_object), allocatable :: copy(:)  !< Tokens with `lc` for the color word.
      type(line_style_object)         :: probe    !< Color read.
      character(len=:), allocatable   :: text     !< Format.
      real(R8P)                       :: v(2)     !< Offset.

      associate(panel => self%figure%panels(self%figure%current))
         panel%stamp = .true.
         i = 2_I4P
         do while (i <= size(tokens, kind=I4P))
            if (tokens(i)%kind == TOKEN_STRING .or. (tokens(i)%kind == TOKEN_WORD .and. &
                .not. is_word(tokens(i)%text, 'top bottom rotate norotate offset font textcolor tc'))) then
               if (.not. self%string_expression(tokens, i, text, iostat, iomsg)) then
                  iomsg = 'set timestamp: '//iomsg
                  return
               endif
               if (len(text) > len(panel%stamp_format)) then
                  call fail('set timestamp: the format is too long', iostat, iomsg)
                  return
               endif
               panel%stamp_format = text
            elseif (is_word(tokens(i)%text, 'top bottom')) then
               panel%stamp_top = tokens(i)%text == 'top'
            elseif (is_word(tokens(i)%text, 'rotate norotate')) then
               panel%stamp_rotate = tokens(i)%text == 'rotate'
            elseif (tokens(i)%text == 'offset') then
               if (.not. next_real(tokens, i, v(1), iostat, iomsg, self%symbols)) then
                  iomsg = 'set timestamp: offset: '//iomsg
                  return
               endif
               v(2) = 0.0_R8P
               if (i < size(tokens, kind=I4P)) then
                  if (tokens(i + 1_I4P)%kind == TOKEN_COMMA) then
                     i = i + 1_I4P
                     if (.not. next_real(tokens, i, v(2), iostat, iomsg, self%symbols)) then
                        iomsg = 'set timestamp: offset: '//iomsg
                        return
                     endif
                  endif
               endif
               panel%stamp_offset = v
            elseif (tokens(i)%text == 'font') then
               if (.not. font_spec(self, tokens, i, panel%stamp_font, iostat, iomsg)) then
                  iomsg = 'set timestamp: '//iomsg
                  return
               endif
            else
               copy = tokens
               copy(i)%text = 'lc'
               if (.not. line_option(copy, i, probe, iostat, iomsg, panel%linecolors, self%symbols)) return
               if (allocated(probe%lc)) then
                  if (index(probe%lc, '*') == 1 .or. len(probe%lc) > len(panel%stamp_color)) then
                     call fail('set timestamp: textcolor: variable and palette colors do not apply', iostat, iomsg)
                     return
                  endif
                  panel%stamp_color = probe%lc
               endif
            endif
            i = i + 1_I4P
         enddo
      endassociate
      endsubroutine timestamp_option

      subroutine offsets_option
      !< gnuplot `set offsets [graph] L, [graph] R, [graph] T, [graph] B`: the autoscaled ends of x and y moved out, in
      !< axis units (`first`) or fractions of the range (`graph`); missing ones are 0.
      real(R8P) :: v(4)     !< Left, right, top, bottom.
      logical   :: graph(4) !< In graph fractions.
      integer(I4P) :: k     !< Offset counter.

      v = 0.0_R8P
      graph = .false.
      i = 1_I4P
      do k = 1_I4P, 4_I4P
         if (i >= size(tokens, kind=I4P)) exit
         if (tokens(i + 1_I4P)%kind == TOKEN_WORD .and. is_word(tokens(i + 1_I4P)%text, 'graph first')) then
            graph(k) = tokens(i + 1_I4P)%text == 'graph'
            i = i + 1_I4P
         endif
         if (.not. next_real(tokens, i, v(k), iostat, iomsg, self%symbols)) then
            iomsg = 'set offsets: '//iomsg
            return
         endif
         if (i < size(tokens, kind=I4P)) then
            if (tokens(i + 1_I4P)%kind /= TOKEN_COMMA) then
               call fail('set offsets: "," expected, found "'//tokens(i + 1_I4P)%text//'"', iostat, iomsg)
               return
            endif
            i = i + 1_I4P
         endif
      enddo
      if (i < size(tokens, kind=I4P)) then
         call fail('set offsets: four offsets at most: left, right, top, bottom', iostat, iomsg)
         return
      endif
      associate(panel => self%figure%panels(self%figure%current))
         panel%xaxis%offset = [v(1), v(2)]
         panel%xaxis%offset_graph = [graph(1), graph(2)]
         panel%yaxis%offset = [v(4), v(3)]
         panel%yaxis%offset_graph = [graph(4), graph(3)]
      endassociate
      endsubroutine offsets_option

      subroutine linetype_option
      !< gnuplot `set linetype N [lc C] [lw W] [dt D] [pt P] [ps S] [pi I]`: linetype N redefined, persistent (`reset`
      !< keeps it); its color among the linetype colors (padded to whole cycles of the current ones, so that the higher
      !< linetypes still cycle as gnuplot's), the rest the defaults of its series; `set linetype cycle N` reuses the
      !< first N colors for the higher linetypes.
      type(line_style_object)       :: lt     !< Properties read.
      character(len=9), allocatable :: list(:) !< Linetype colors.
      integer(I4P)                  :: n      !< Linetype.
      integer(I4P)                  :: base   !< Colors of a cycle now.
      integer(I4P)                  :: m      !< Colors after.
      integer(I4P)                  :: k      !< Counter.

      i = 2_I4P
      if (size(tokens) >= 2) then
         if (tokens(2)%text == 'cycle') then
            if (.not. next_integer(tokens, i, n, iostat, iomsg)) then
               iomsg = 'set linetype cycle: '//iomsg
               return
            endif
            if (n < 1_I4P) then
               call fail('set linetype cycle: the cycle must be positive', iostat, iomsg)
               return
            endif
            associate(panel => self%figure%panels(self%figure%current))
               allocate(list(n))
               do k = 1_I4P, n
                  list(k) = default_color(k, self%figure%panels(self%figure%current)%linecolors)
               enddo
               panel%linecolors = list
            endassociate
            return
         endif
      endif
      i = 1_I4P
      ! a constant expression (`set for [i=1:3] linetype 10+i ...`)
      block
         real(R8P) :: v !< Linetype, as read.

         if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) then
            iomsg = 'set linetype: '//iomsg
            return
         endif
         if (v /= aint(v) .or. abs(v) > 1.0e6_R8P) then
            call fail('set linetype: the linetype must be an integer', iostat, iomsg)
            return
         endif
         n = nint(v, I4P)
      endblock
      if (n < 1_I4P .or. n > MAX_LINETYPES) then
         call fail('set linetype: the linetype must be between 1 and '//int_str(int(MAX_LINETYPES, I8P)), iostat, iomsg)
         return
      endif
      i = i + 1_I4P
      do while (i <= size(tokens, kind=I4P))
         if (.not. is_line_option(tokens(i)%text)) then
            call fail('set linetype: unsupported option "'//tokens(i)%text//'"', iostat, iomsg)
            return
         endif
         if (.not. line_option(tokens, i, lt, iostat, iomsg, self%figure%panels(self%figure%current)%linecolors, &
                               self%symbols)) then
            iomsg = 'set linetype: '//iomsg
            return
         endif
         i = i + 1_I4P
      enddo
      associate(panel => self%figure%panels(self%figure%current))
         if (allocated(lt%lc)) then
            ! the names kept for the themes (black, white) as their #rrggbb; gnuplot's #AARRGGBB is kept as #rrggbbaa
            if (.not. ((len(lt%lc) == 7 .or. len(lt%lc) == 9) .and. lt%lc(1:1) == '#')) then
               block
                  integer(I4P) :: c(3) !< Channels.
                  logical      :: ok   !< A named color.

                  call named_color(lt%lc, c, ok)
                  if (.not. ok) then
                     call fail('set linetype: a fixed color is expected, not "'//lt%lc//'"', iostat, iomsg)
                     return
                  endif
                  lt%lc = hex_color(c)
               endblock
            endif
            base = 8_I4P
            if (allocated(panel%linecolors)) then
               if (size(panel%linecolors) > 0) base = size(panel%linecolors, kind=I4P)
            endif
            m = max(base, ((n + base - 1_I4P) / base) * base)
            allocate(list(m))
            do k = 1_I4P, m
               list(k) = default_color(k, self%figure%panels(self%figure%current)%linecolors)
            enddo
            list(n) = lt%lc
            panel%linecolors = list
         endif
         if (allocated(lt%lw)) panel%lt_lw(n) = lt%lw
         if (allocated(lt%dt)) panel%lt_dt(n) = lt%dt
         if (allocated(lt%pt)) panel%lt_pt(n) = lt%pt
         if (allocated(lt%ps)) panel%lt_ps(n) = lt%ps
      endassociate
      endsubroutine linetype_option

      function axis_label(axis) result(ok)
      !< `set xlabel ["text"] [offset X[,Y]] [font F] [tc COLOR] [rotate ...|norotate] [left|right|center]
      !< [noenhanced|enhanced]` (and ylabel, y2label, x2label: `axis` 1 to 4): the text, shifted by characters (x right,
      !< y up), in its color, and whether it is read as it is, not as enhanced text. The font, the rotation and the
      !< justification are read and ignored, as one font and the axis' own layout are foresight's.
      integer(I4P), intent(in)      :: axis   !< Axis: 1 x, 2 y, 3 y2, 4 x2, 5 r, 6 z.
      logical                       :: ok     !< Success.
      character(len=*), parameter   :: WORDS = 'offset font tc textcolor textc textco textcol textcolo rotate norotate '// &
                                               'left right center centre noenhanced noenh enhanced enh boxed noboxed' !< Options.
      real(R8P)                     :: offset(2) !< Shift [characters].
      real(R8P)                     :: z      !< gnuplot's z offset, ignored.
      character(len=24)             :: color  !< Color.
      logical                       :: plain  !< `noenhanced`: the label as it is.
      type(font_object)             :: font   !< Font.
      integer(I4P)                  :: j      !< First option token.
      integer(I4P)                  :: k      !< Token counter.

      j = size(tokens, kind=I4P) + 1_I4P
      do k = 2_I4P, size(tokens, kind=I4P)
         if (tokens(k)%kind /= TOKEN_WORD) cycle
         if (is_word(tokens(k)%text, WORDS)) then
            j = k
            exit
         endif
      enddo
      ok = self%string_argument(tokens(1:j - 1_I4P), text, iostat, iomsg)
      if (.not. ok) return
      ! options alone (`set xlabel offset 0,1.5 boxed`): the text kept, as gnuplot
      if (j == 2_I4P .and. size(tokens) > 1) then
         associate(panel => self%figure%panels(self%figure%current))
            select case (axis)
            case (1_I4P)
               if (allocated(panel%xaxis%label)) text = panel%xaxis%label
            case (2_I4P)
               if (allocated(panel%yaxis%label)) text = panel%yaxis%label
            case (3_I4P)
               if (allocated(panel%y2axis%label)) text = panel%y2axis%label
            case (4_I4P)
               if (allocated(panel%x2axis%label)) text = panel%x2axis%label
            case (6_I4P)
               if (allocated(panel%zaxis%label)) text = panel%zaxis%label
            case default
               if (allocated(panel%raxis%label)) text = panel%raxis%label
            endselect
         endassociate
      endif
      ok = .false.
      plain = .false.
      offset = self%figure%panels(self%figure%current)%label_offset(:, axis)
      color = self%figure%panels(self%figure%current)%label_color(axis)
      font = self%figure%panels(self%figure%current)%label_font(axis)
      k = j
      do while (k <= size(tokens, kind=I4P))
         select case (tokens(k)%text)
         case ('offset')
            if (k < size(tokens, kind=I4P)) then
               if (is_word(tokens(k + 1_I4P)%text, 'character char')) k = k + 1_I4P
            endif
            if (.not. next_real(tokens, k, offset(1), iostat, iomsg, self%symbols)) return
            offset(2) = 0.0_R8P
            if (k < size(tokens, kind=I4P)) then
               if (tokens(k + 1_I4P)%kind == TOKEN_COMMA) then
                  k = k + 1_I4P
                  if (.not. next_real(tokens, k, offset(2), iostat, iomsg, self%symbols)) return
                  ! a third (z) offset is gnuplot's 3D one
                  if (k < size(tokens, kind=I4P)) then
                     if (tokens(k + 1_I4P)%kind == TOKEN_COMMA) then
                        k = k + 1_I4P
                        if (.not. next_real(tokens, k, z, iostat, iomsg, self%symbols)) return
                     endif
                  endif
               endif
            endif
         case ('font')
            if (.not. font_spec(self, tokens, k, font, iostat, iomsg)) then
               iomsg = 'set '//tokens(1)%text//': '//iomsg
               return
            endif
         case ('tc', 'textcolor', 'textc', 'textco', 'textcol', 'textcolo')
            if (.not. self%text_color(tokens, k, color, iostat, iomsg)) then
               iomsg = 'set '//tokens(1)%text//': '//iomsg
               return
            endif
         case ('rotate')
            ! rotate parallel, rotate by A
            if (k < size(tokens, kind=I4P)) then
               if (tokens(k + 1_I4P)%text == 'parallel') then
                  k = k + 1_I4P
               elseif (tokens(k + 1_I4P)%text == 'by') then
                  k = k + 2_I4P
               endif
            endif
         case ('norotate', 'left', 'right', 'center', 'centre')
         case ('noenhanced', 'noenh')
            plain = .true.
         case ('enhanced', 'enh')
            plain = .false.
         case ('boxed')
            ! on the background (gnuplot's text box, `set style textbox`)
            associate(panel => self%figure%panels(self%figure%current))
               panel%label_boxed = ibset(panel%label_boxed, axis - 1_I4P)
            endassociate
         case ('noboxed')
            associate(panel => self%figure%panels(self%figure%current))
               panel%label_boxed = ibclr(panel%label_boxed, axis - 1_I4P)
            endassociate
         case default
            call fail('set '//tokens(1)%text//': unexpected "'//tokens(k)%text//'" (offset, font, tc, rotate, '// &
                      'noenhanced, boxed)', iostat, iomsg)
            return
         endselect
         k = k + 1_I4P
      enddo
      self%figure%panels(self%figure%current)%label_plain(axis) = plain
      self%figure%panels(self%figure%current)%label_offset(:, axis) = offset
      self%figure%panels(self%figure%current)%label_color(axis) = color
      self%figure%panels(self%figure%current)%label_font(axis) = font
      ok = .true.
      endfunction axis_label

      subroutine dgrid3d_option(toks)
      !< gnuplot `set dgrid3d [ROWS[,COLS]] [qnorm [Q]|splines|gauss|cauchy|exp|box|hann [kdensity] [DX[,DY]]]`: the
      !< scattered data of splot gridded, ROWS points along y of COLS iso-curves of x (10, 10, qnorm 1 by default).
      type(token_object), intent(in) :: toks(:) !< The option tokens (passed: nvfortran 26.9 misreads host dummies).
      type(dgrid3d_object)           :: new     !< The settings read.
      integer(I4P)                   :: k       !< Token counter.
      integer(I4P)                   :: n       !< An integer read.
      real(R8P)                      :: v       !< A number read.

      new = self%figure%panels(self%figure%current)%dgrid3d
      new%kdensity = .false.
      k = 2_I4P
      if (k <= size(toks, kind=I4P)) then
         if (to_number(toks(k)%text, v) .or. scan(toks(k)%text(1:1), '(') > 0) then
            k = k - 1_I4P
            if (.not. next_integer(toks, k, n, iostat, iomsg, self%symbols)) return
            new%rows = n
            new%cols = n
            if (k < size(toks, kind=I4P)) then
               if (toks(k + 1_I4P)%kind == TOKEN_COMMA) then
                  k = k + 1_I4P
                  if (.not. next_integer(toks, k, n, iostat, iomsg, self%symbols)) return
                  new%cols = n
               endif
            endif
            k = k + 1_I4P
         endif
      endif
      do while (k <= size(toks, kind=I4P))
         select case (toks(k)%text)
         case ('qnorm')
            new%mode = DGRID_QNORM
            if (k < size(toks, kind=I4P)) then
               if (to_number(toks(k + 1_I4P)%text, v)) then
                  if (.not. next_integer(toks, k, n, iostat, iomsg, self%symbols)) return
                  new%norm = n
               endif
            endif
         case ('splines', 'spline')
            new%mode = DGRID_SPLINES
         case ('gauss', 'cauchy', 'exp', 'box', 'hann')
            select case (toks(k)%text)
            case ('gauss')
               new%mode = DGRID_GAUSS
            case ('cauchy')
               new%mode = DGRID_CAUCHY
            case ('exp')
               new%mode = DGRID_EXP
            case ('box')
               new%mode = DGRID_BOX
            case default
               new%mode = DGRID_HANN
            endselect
            if (k < size(toks, kind=I4P)) then
               if (keyword(toks(k + 1_I4P)%text, 'kdensity2d', 5_I4P)) then
                  new%kdensity = .true.
                  k = k + 1_I4P
               endif
            endif
            if (k < size(toks, kind=I4P)) then
               if (to_number(toks(k + 1_I4P)%text, v) .or. toks(k + 1_I4P)%text(1:1) == '(') then
                  if (.not. next_real(toks, k, v, iostat, iomsg, self%symbols)) return
                  new%scale = v
                  if (k < size(toks, kind=I4P)) then
                     if (toks(k + 1_I4P)%kind == TOKEN_COMMA) then
                        k = k + 1_I4P
                        if (.not. next_real(toks, k, v, iostat, iomsg, self%symbols)) return
                        new%scale(2) = v
                     endif
                  endif
               endif
            endif
         case default
            call fail('set dgrid3d: unrecognized keyword or unexpected value "'//toks(k)%text//'"', iostat, iomsg)
            return
         endselect
         k = k + 1_I4P
      enddo
      if (new%rows < 2_I4P .or. new%rows > 1000_I4P .or. new%cols < 2_I4P .or. new%cols > 1000_I4P) then
         call fail('set dgrid3d: number of grid points must be in [2:1000]', iostat, iomsg)
         return
      endif
      if (any(new%scale < 0.0_R8P)) then
         call fail('set dgrid3d: scale factors must be greater than zero', iostat, iomsg)
         return
      endif
      new%on = .true.
      self%figure%panels(self%figure%current)%dgrid3d = new
      endsubroutine dgrid3d_option

      subroutine cntrparam_option(toks)
      !< gnuplot `set cntrparam [linear|cubicspline|bspline] [points N] [order N] [levels [auto [N]|N|discrete z1,
      !< z2, ...|incremental start, step[, end]]] [firstlinetype N] [sorted|unsorted]`; alone, the defaults.
      type(token_object), intent(in) :: toks(:) !< The option tokens (passed: nvfortran 26.9 misreads host dummies).
      integer(I4P)                   :: k       !< Token counter.
      integer(I4P)                   :: n       !< An integer read.
      real(R8P)                      :: v       !< A number read.
      real(R8P), allocatable         :: list(:) !< Levels read.
      logical                        :: discrete !< Discrete levels, else incremental.

      associate(cnt => self%figure%panels(self%figure%current)%contour)
         if (size(toks) < 2) then
            cnt%npoints = 5_I4P
            cnt%kind = CONTOUR_LINEAR
            cnt%order = 4_I4P
            cnt%levels = 5_I4P
            cnt%levels_kind = LEVELS_AUTO
            cnt%firstlinetype = 0_I4P
            return
         endif
         k = 2_I4P
         do while (k <= size(toks, kind=I4P))
            if (keyword(toks(k)%text, 'points', 1_I4P)) then
               if (.not. next_integer(toks, k, n, iostat, iomsg, self%symbols)) return
               cnt%npoints = max(1_I4P, n)
            elseif (keyword(toks(k)%text, 'firstlinetype', 5_I4P)) then
               if (.not. next_integer(toks, k, n, iostat, iomsg, self%symbols)) return
               cnt%firstlinetype = n
            elseif (keyword(toks(k)%text, 'sorted', 4_I4P)) then
               cnt%sorted = .true.
            elseif (keyword(toks(k)%text, 'unsorted', 6_I4P)) then
               cnt%sorted = .false.
            elseif (keyword(toks(k)%text, 'linear', 2_I4P)) then
               cnt%kind = CONTOUR_LINEAR
            elseif (keyword(toks(k)%text, 'cubicspline', 1_I4P)) then
               cnt%kind = CONTOUR_CUBIC
            elseif (keyword(toks(k)%text, 'bspline', 1_I4P)) then
               cnt%kind = CONTOUR_BSPLINE
            elseif (keyword(toks(k)%text, 'order', 1_I4P)) then
               if (.not. next_integer(toks, k, n, iostat, iomsg, self%symbols)) return
               if (n < 2_I4P .or. n > 10_I4P) then
                  call fail('set cntrparam: bspline order must be in [2..10] range', iostat, iomsg)
                  return
               endif
               cnt%order = n
            elseif (keyword(toks(k)%text, 'levels', 2_I4P)) then
               if (k == size(toks, kind=I4P)) then
                  call fail('set cntrparam: levels needs auto [N], N, discrete or incremental', iostat, iomsg)
                  return
               endif
               k = k + 1_I4P
               if (keyword(toks(k)%text, 'discrete', 2_I4P) .or. keyword(toks(k)%text, 'incremental', 2_I4P)) then
                  discrete = keyword(toks(k)%text, 'discrete', 2_I4P)
                  ! the numbers comma separated to the end
                  allocate(list(0))
                  do
                     if (.not. next_real(toks, k, v, iostat, iomsg, self%symbols)) then
                        iomsg = 'set cntrparam: '//iomsg
                        return
                     endif
                     list = [list, v]
                     if (k >= size(toks, kind=I4P)) exit
                     if (toks(k + 1_I4P)%kind /= TOKEN_COMMA) exit
                     k = k + 1_I4P
                  enddo
                  if (discrete) then
                     cnt%levels_kind = LEVELS_DISCRETE
                     cnt%list = list
                     cnt%levels = size(list, kind=I4P)
                  else
                     if (size(list) < 2) then
                        call fail('set cntrparam: incremental needs start, step[, end]', iostat, iomsg)
                        return
                     endif
                     if (list(2) == 0.0_R8P) then
                        call fail('set cntrparam: increment cannot be 0', iostat, iomsg)
                        return
                     endif
                     cnt%levels_kind = LEVELS_INCREMENTAL
                     cnt%list = list(1:2)
                     ! gnuplot's count, truncated: 10,10,50 is 5 levels, 10,10,49 four
                     if (size(list) >= 3) cnt%levels = int((list(3) - list(1)) / list(2) + 1.0_R8P, I4P)
                  endif
                  deallocate(list)
               elseif (keyword(toks(k)%text, 'auto', 2_I4P)) then
                  cnt%levels_kind = LEVELS_AUTO
                  if (k < size(toks, kind=I4P)) then
                     if (toks(k + 1_I4P)%kind == TOKEN_WORD .and. .not. is_cntrparam_word(toks(k + 1_I4P)%text)) then
                        if (.not. next_integer(toks, k, n, iostat, iomsg, self%symbols)) return
                        cnt%levels = n
                     endif
                  endif
               else
                  k = k - 1_I4P
                  if (.not. next_integer(toks, k, n, iostat, iomsg, self%symbols)) return
                  if (cnt%levels_kind /= LEVELS_DISCRETE) cnt%levels = n
               endif
            else
               call fail("set cntrparam: expecting 'linear', 'cubicspline', 'bspline', 'points', 'levels' or "// &
                         "'order', found """//toks(k)%text//'"', iostat, iomsg)
               return
            endif
            k = k + 1_I4P
         enddo
      endassociate
      endsubroutine cntrparam_option

      subroutine cntrlabel_option(toks)
      !< gnuplot `set cntrlabel [format "fmt"] [font "f"] [start N] [interval N] [onecolor]`; alone, the defaults.
      type(token_object), intent(in) :: toks(:) !< The option tokens (passed: nvfortran 26.9 misreads host dummies).
      integer(I4P)                   :: k       !< Token counter.
      integer(I4P)                   :: n       !< An integer read.

      associate(cnt => self%figure%panels(self%figure%current)%contour)
         if (size(toks) < 2) then
            cnt%format = '%8.3g'
            cnt%onecolor = .false.
            return
         endif
         k = 2_I4P
         do while (k <= size(toks, kind=I4P))
            if (keyword(toks(k)%text, 'format', 4_I4P)) then
               k = k + 1_I4P
               if (k > size(toks, kind=I4P)) then
                  call fail('set cntrlabel: format needs a string', iostat, iomsg)
                  return
               endif
               cnt%format = toks(k)%text
            elseif (toks(k)%text == 'font') then
               k = k + 1_I4P
            elseif (keyword(toks(k)%text, 'onecolor', 3_I4P)) then
               cnt%onecolor = .true.
            elseif (toks(k)%text == 'start') then
               if (.not. next_integer(toks, k, n, iostat, iomsg, self%symbols)) return
               cnt%label_start = n
            elseif (keyword(toks(k)%text, 'interval', 3_I4P)) then
               if (.not. next_integer(toks, k, n, iostat, iomsg, self%symbols)) return
               cnt%label_interval = n
            else
               call fail('set cntrlabel: unexpected "'//toks(k)%text//'" (format, font, start, interval, onecolor)', &
                         iostat, iomsg)
               return
            endif
            k = k + 1_I4P
         enddo
      endassociate
      endsubroutine cntrlabel_option

      subroutine pm3d_option(toks)
      !< gnuplot `set pm3d [at b|s|t...] [interpolate N,M] [corners2color mean|geomean|harmean|rms|median|min|max|c1..c4]
      !< [implicit|explicit] [map] [clip|clip1in|clip4in] [border ...|noborder] [scansforward|scansbackward|
      !< scansautomatic|depthorder [base]] [flush begin|center|end] [[no]ftriangles] [[no]clipcb] [nohidden3d]`: the
      !< drawing order options and the border are read (a map view needs none); `set pm3d` alone is gnuplot's defaults,
      !< implicit, as `at` first; `map` is `at b` with `set view map` and the pm3d data and function styles.
      type(token_object), intent(in) :: toks(:) !< The option tokens (passed: nvfortran 26.9 misreads host dummies).
      type(pm3d_object)              :: fresh   !< Defaults.
      integer(I4P)                   :: k       !< Token counter.
      integer(I4P)                   :: n       !< A step count.
      character(len=:), allocatable  :: w       !< Option word.
      real(R8P)                      :: v       !< A number read.

      associate(pm => self%figure%panels(self%figure%current)%pm3d)
         if (size(toks) < 2) then
            pm = fresh
            pm%implicit = .true.
            return
         endif
         k = 2_I4P
         do while (k <= size(toks, kind=I4P))
            w = toks(k)%text
            if (w == 'at') then
               if (k == size(toks, kind=I4P)) then
                  call fail('set pm3d: at needs b, s or t', iostat, iomsg)
                  return
               endif
               k = k + 1_I4P
               if (verify(toks(k)%text, 'bst') /= 0 .or. len(toks(k)%text) > 3) then
                  call fail('set pm3d: at needs b, s or t, found "'//toks(k)%text//'"', iostat, iomsg)
                  return
               endif
               pm%at = toks(k)%text
               if (k == 3_I4P) pm%implicit = .true.
            elseif (keyword(w, 'interpolate', 6_I4P)) then
               if (.not. next_integer(toks, k, n, iostat, iomsg, self%symbols)) return
               pm%interp(1) = n
               if (k >= size(toks, kind=I4P)) then
                  call fail('set pm3d: interpolate needs N,M', iostat, iomsg)
                  return
               endif
               if (toks(k + 1_I4P)%kind /= TOKEN_COMMA) then
                  call fail('set pm3d: interpolate needs N,M', iostat, iomsg)
                  return
               endif
               k = k + 1_I4P
               if (.not. next_integer(toks, k, n, iostat, iomsg, self%symbols)) return
               pm%interp(2) = n
            elseif (keyword(w, 'corners2color', 9_I4P) .or. w == 'c2c') then
               if (k == size(toks, kind=I4P)) then
                  call fail('set pm3d: corners2color needs mean, geomean, harmean, rms, median, min, max, c1, c2, '// &
                            'c3 or c4', iostat, iomsg)
                  return
               endif
               k = k + 1_I4P
               select case (toks(k)%text)
               case ('mean')
                  pm%corners = CORNERS_MEAN
               case ('geomean')
                  pm%corners = CORNERS_GEOMEAN
               case ('harmean')
                  pm%corners = CORNERS_HARMEAN
               case ('rms')
                  pm%corners = CORNERS_RMS
               case ('median')
                  pm%corners = CORNERS_MEDIAN
               case ('min')
                  pm%corners = CORNERS_MIN
               case ('max')
                  pm%corners = CORNERS_MAX
               case ('c1', 'c2', 'c3', 'c4')
                  pm%corners = CORNERS_C1 + iachar(toks(k)%text(2:2)) - iachar('1')
               case default
                  call fail('set pm3d: corners2color needs mean, geomean, harmean, rms, median, min, max, c1, c2, '// &
                            'c3 or c4, found "'//toks(k)%text//'"', iostat, iomsg)
                  return
               endselect
            elseif (keyword(w, 'implicit', 1_I4P) .or. keyword(w, 'noexplicit', 3_I4P)) then
               pm%implicit = .true.
            elseif (keyword(w, 'explicit', 1_I4P) .or. keyword(w, 'noimplicit', 3_I4P)) then
               pm%implicit = .false.
            elseif (w == 'map') then
               pm%at = 'b'
               self%data_style = 'pm3d'
               self%function_style = 'pm3d'
               self%figure%panels(self%figure%current)%view3d%map = .true.
            elseif (w == 'clip4in' .or. keyword(w, 'clip4in', 5_I4P)) then
               pm%clip4in = .true.
            elseif (w == 'clip' .or. keyword(w, 'clip1in', 5_I4P)) then
               pm%clip4in = .false.
            elseif (keyword(w, 'border', 2_I4P)) then
               ! its line properties read, the border not drawn
               pm%border = .true.
               do while (k < size(toks, kind=I4P))
                  if (toks(k + 1_I4P)%kind /= TOKEN_WORD) then
                     k = k + 1_I4P
                     cycle
                  endif
                  if (.not. (is_line_option(toks(k + 1_I4P)%text) .or. toks(k + 1_I4P)%text == 'retrace' .or. &
                             toks(k + 1_I4P)%text == 'rgb' .or. toks(k + 1_I4P)%text == 'rgbcolor' .or. &
                             toks(k + 1_I4P)%text == 'palette' .or. toks(k + 1_I4P)%text == 'variable' .or. &
                             to_number(toks(k + 1_I4P)%text, v))) exit
                  k = k + 1_I4P
               enddo
            elseif (keyword(w, 'noborder', 4_I4P)) then
               pm%border = .false.
            elseif (keyword(w, 'flush', 2_I4P)) then
               k = k + 1_I4P
            elseif (keyword(w, 'depthorder', 3_I4P)) then
               if (k < size(toks, kind=I4P)) then
                  if (toks(k + 1_I4P)%text == 'base') k = k + 1_I4P
               endif
            elseif (keyword(w, 'scansforward', 8_I4P) .or. keyword(w, 'scansbackward', 9_I4P) .or. &
                    keyword(w, 'scansautomatic', 9_I4P) .or. keyword(w, 'ftriangles', 3_I4P) .or. &
                    keyword(w, 'noftriangles', 5_I4P) .or. w == 'clipcb' .or. w == 'noclipcb' .or. &
                    keyword(w, 'nohidden3d', 4_I4P) .or. keyword(w, 'nolighting', 7_I4P)) then
               continue
            elseif (keyword(w, 'hidden3d', 2_I4P)) then
               ! deprecated: hidden3d N, the border linetype
               if (k < size(toks, kind=I4P)) then
                  if (to_number(toks(k + 1_I4P)%text, v)) k = k + 1_I4P
               endif
            else
               call fail('set pm3d: unsupported option "'//w//'"', iostat, iomsg)
               return
            endif
            k = k + 1_I4P
         enddo
      endassociate
      endsubroutine pm3d_option

      subroutine view_option(toks)
      !< gnuplot `set view ROT_X[,ROT_Z[,SCALE[,SCALE_Z]]]` (empty fields keep theirs), `set view map [scale S]`,
      !< `set view [no]equal [xy|xyz]`, `set view azimuth A`, `set view projection xy` (the map); `set view` alone keeps
      !< the view.
      type(token_object), intent(in) :: toks(:) !< The option tokens (passed: nvfortran 26.9 misreads host dummies).
      real(R8P)    :: v    !< A value.
      integer(I4P) :: f    !< Field: 1 rot_x, 2 rot_z, 3 scale, 4 scale_z.

      if (size(toks) < 2) return
      associate(view => self%figure%panels(self%figure%current)%view3d)
         select case (toks(2)%text)
         case ('map')
            view%map = .true.
            view%map_scale = 1.0_R8P
            i = 2_I4P
            if (size(toks) > 2) then
               if (toks(3)%text /= 'scale') then
                  call fail('set view map: scale S expected, found "'//toks(3)%text//'"', iostat, iomsg)
                  return
               endif
               i = 3_I4P
               if (.not. next_real(toks, i, view%map_scale, iostat, iomsg, self%symbols)) return
            endif
            if (.not. no_more(toks, i + 1_I4P, iostat, iomsg)) return
         case ('equal')
            view%equal = 1_I4P
            if (size(toks) > 2) then
               if (toks(3)%text == 'xyz') then
                  view%equal = 2_I4P
               elseif (toks(3)%text /= 'xy') then
                  call fail('set view equal: xy or xyz expected, found "'//toks(3)%text//'"', iostat, iomsg)
                  return
               endif
               if (.not. no_more(toks, 4_I4P, iostat, iomsg)) return
            endif
         case ('noequal')
            view%equal = 0_I4P
         case ('azimuth')
            i = 2_I4P
            if (.not. next_real(toks, i, view%azimuth, iostat, iomsg, self%symbols)) return
            if (.not. no_more(toks, i + 1_I4P, iostat, iomsg)) return
         case ('projection')
            if (size(toks) < 3) then
               call fail('set view projection: xy, xz or yz expected', iostat, iomsg)
               return
            endif
            if (toks(3)%text /= 'xy') then
               call fail('set view projection '//toks(3)%text//': not supported yet (the xy projection is the '// &
                         'map view)', iostat, iomsg)
               return
            endif
            view%map = .true.
            view%map_scale = 1.0_R8P
         case default
            ! ROT_X, ROT_Z, SCALE, SCALE_Z, each may be empty
            f = 1_I4P
            i = 1_I4P
            do while (i < size(toks, kind=I4P))
               if (toks(i + 1_I4P)%kind == TOKEN_COMMA) then
                  f = f + 1_I4P
                  i = i + 1_I4P
                  cycle
               endif
               if (f > 4_I4P) then
                  call fail('set view: at most ROT_X, ROT_Z, SCALE, SCALE_Z', iostat, iomsg)
                  return
               endif
               if (.not. next_real(toks, i, v, iostat, iomsg, self%symbols)) then
                  iomsg = 'set view: '//iomsg
                  return
               endif
               select case (f)
               case (1_I4P)
                  if (v < 0.0_R8P .or. v > 360.0_R8P) then
                     call fail('set view: rot_x must be in [0:360] degrees', iostat, iomsg)
                     return
                  endif
                  view%rot_x = v
               case (2_I4P)
                  if (v < 0.0_R8P .or. v > 360.0_R8P) then
                     call fail('set view: rot_z must be in [0:360] degrees', iostat, iomsg)
                     return
                  endif
                  view%rot_z = v
               case (3_I4P)
                  if (v < 1.0e-6_R8P) then
                     call fail('set view: scale must be > 0', iostat, iomsg)
                     return
                  endif
                  view%scale = v
               case default
                  if (v < 1.0e-6_R8P) then
                     call fail('set view: zscale must be > 0', iostat, iomsg)
                     return
                  endif
                  view%zscale = v
               endselect
            enddo
            view%map = .false.
         endselect
      endassociate
      endsubroutine view_option

      subroutine xyplane_option(toks)
      !< gnuplot `set xyplane at Z`, `set xyplane relative F`, `set xyplane F` and `set ticslevel F`: the base plane at
      !< the height Z, or F times the z range below the range.
      type(token_object), intent(in) :: toks(:) !< The option tokens (passed: nvfortran 26.9 misreads host dummies).
      associate(view => self%figure%panels(self%figure%current)%view3d)
         i = 1_I4P
         if (size(toks) < 2) then
            call fail('set '//option//': a value expected', iostat, iomsg)
            return
         endif
         if (toks(2)%text == 'at') then
            i = 2_I4P
            if (.not. next_real(toks, i, view%xyplane_z, iostat, iomsg, self%symbols)) return
            view%xyplane_at = .true.
         else
            if (toks(2)%text == 'relative') i = 2_I4P
            if (.not. next_real(toks, i, view%ticslevel, iostat, iomsg, self%symbols)) return
            view%xyplane_at = .false.
         endif
         if (.not. no_more(toks, i + 1_I4P, iostat, iomsg)) return
      endassociate
      endsubroutine xyplane_option

      subroutine title_option
      !< `set title ["text"] [offset X,Y] [font "f"] [left|center|right] [tc COLOR] [noenhanced] [enhanced]`: the text,
      !< shifted by characters (x right, y up), justified about the centre (gnuplot's), in its color; `font` is read and
      !< ignored (one font in foresight); `noenhanced` writes it as it is, not enhanced text.
      real(R8P) :: offset(2) !< Shift [characters].
      integer(I4P) :: j      !< First option token.
      logical   :: plain     !< `noenhanced`: the title as it is.
      character(len=6)  :: anchor !< Justification.
      character(len=24) :: color  !< Color.
      logical           :: boxed  !< `boxed`.

      j = size(tokens, kind=I4P) + 1_I4P
      do i = 2_I4P, size(tokens, kind=I4P)
         if (tokens(i)%kind /= TOKEN_WORD) cycle
         if (is_word(tokens(i)%text, 'offset font noenhanced noenh enhanced enh left right center centre tc '// &
                     'textcolor textc textco textcol textcolo boxed noboxed')) then
            j = i
            exit
         endif
      enddo
      if (j == 2_I4P) then
         ! options alone (`set title offset 0,-2`): the text kept, as gnuplot
         text = ''
         if (allocated(self%figure%panels(self%figure%current)%title)) text = self%figure%panels(self%figure%current)%title
      elseif (.not. self%string_argument(tokens(1:j - 1_I4P), text, iostat, iomsg)) then
         return
      endif
      offset = self%figure%panels(self%figure%current)%title_offset
      anchor = self%figure%panels(self%figure%current)%title_anchor
      color = self%figure%panels(self%figure%current)%title_color
      boxed = .false.
      ! noenhanced kept by a later `set title "text"`, as gnuplot
      plain = self%figure%panels(self%figure%current)%title_plain
      i = j
      do while (i <= size(tokens, kind=I4P))
         select case (tokens(i)%text)
         case ('offset')
            if (.not. next_real(tokens, i, offset(1), iostat, iomsg, self%symbols)) return
            if (i >= size(tokens, kind=I4P)) then
               call fail('set title: offset X,Y expected', iostat, iomsg)
               return
            endif
            if (tokens(i + 1_I4P)%kind /= TOKEN_COMMA) then
               call fail('set title: offset X,Y expected', iostat, iomsg)
               return
            endif
            i = i + 1_I4P
            if (.not. next_real(tokens, i, offset(2), iostat, iomsg, self%symbols)) return
         case ('font')
            if (.not. font_spec(self, tokens, i, self%figure%panels(self%figure%current)%title_font, iostat, iomsg)) then
               iomsg = 'set title: '//iomsg
               return
            endif
         case ('noenhanced', 'noenh')
            plain = .true.
         case ('enhanced', 'enh')
            plain = .false.
         case ('left')
            anchor = 'start'
         case ('right')
            anchor = 'end'
         case ('center', 'centre')
            anchor = 'middle'
         case ('tc', 'textcolor', 'textc', 'textco', 'textcol', 'textcolo')
            if (.not. self%text_color(tokens, i, color, iostat, iomsg)) then
               iomsg = 'set title: '//iomsg
               return
            endif
         case ('boxed')
            ! on the background when text box style 0 is drawn (gnuplot's svg textbox)
            boxed = self%textbox_drawn(0)
         case ('noboxed')
            boxed = .false.
         case default
            call fail('set title: unexpected "'//tokens(i)%text//'" (offset, font, left, center, right, tc, '// &
                      'noenhanced, boxed)', iostat, iomsg)
            return
         endselect
         i = i + 1_I4P
      enddo
      call self%figure%set_title(text, offset=offset)
      self%figure%panels(self%figure%current)%title_boxed = boxed
      self%figure%panels(self%figure%current)%title_plain = plain
      self%figure%panels(self%figure%current)%title_anchor = anchor
      self%figure%panels(self%figure%current)%title_color = color
      endsubroutine title_option

      subroutine key_option
      !< `set key [on|off] [left|right|center] [top|bottom|center] [box|nobox] [inside|outside|below|above|lmargin|
      !< rmargin|tmargin|bmargin|at POSITION] [horizontal|vertical] [autotitle [columnhead]|noautotitle]`; POSITION is
      !< `[SYSTEM] X, [SYSTEM] Y`, SYSTEM `first` (default), `second`, `graph` or `screen`, y taking the one of x.
      character(len=:), allocatable :: words  !< Position words.
      logical                       :: on     !< Key on.
      logical, allocatable          :: box    !< Box, unallocated if not given.
      real(R8P), allocatable        :: at(:)  !< Key position, unallocated if not given.
      character(len=6)              :: sys(2) !< Coordinate systems of the position.
      logical                       :: placed !< A coordinate read.
      real(R8P)                     :: v      !< A number.
      real(R8P)                     :: xy(2)  !< An offset.

      on = .true.
      words = ''
      i = 1_I4P
      do while (i < size(tokens, kind=I4P))
         i = i + 1_I4P
         select case (tokens(i)%text)
         case ('at')
            allocate(at(2))
            call key_coordinate(tokens, i, at(1), sys(1), 'first ', placed)
            if (.not. placed) return
            if (i >= size(tokens, kind=I4P)) then
               call fail('set key at: X, Y expected', iostat, iomsg)
               return
            endif
            i = i + 1_I4P
            if (tokens(i)%kind /= TOKEN_COMMA) then
               call fail('set key at: X, Y expected', iostat, iomsg)
               return
            endif
            call key_coordinate(tokens, i, at(2), sys(2), sys(1), placed)
            if (.not. placed) return
         case ('autotitle', 'auto')
            self%autotitle = 'file'
            if (i < size(tokens, kind=I4P)) then
               ! `col`, `column`, `columnhead`: gnuplot's col$umnheader, not the `columns N` option
               if (keyword(tokens(i + 1_I4P)%text, 'columnheader', 3_I4P)) then
                  self%autotitle = 'columnhead'
                  i = i + 1_I4P
               endif
            endif
         case ('noautotitle')
            self%autotitle = 'none'
         case ('columnhead', 'columnheader')
            if (i == 2_I4P) then
               call fail('set key: columnhead goes after autotitle', iostat, iomsg)
               return
            endif
            if (tokens(i - 1_I4P)%text /= 'autotitle' .and. tokens(i - 1_I4P)%text /= 'auto') then
               call fail('set key: columnhead goes after autotitle', iostat, iomsg)
               return
            endif
         case ('on')
            on = .true.
         case ('off')
            on = .false.
         case ('box')
            box = .true.
         case ('nobox')
            box = .false.
         case ('left', 'right', 'center', 'top', 'bottom', 'inside', 'ins', 'outside', 'out', 'below', 'under', 'above', &
               'over', 'horizontal', 'horiz', 'vertical', 'vert', 'lmargin', 'lm', 'rmargin', 'rm', 'tmargin', 'tm', &
               'bmargin', 'bm')
            words = words//' '//tokens(i)%text
         case ('cent')
            words = words//' center'
         case ('bot')
            words = words//' bottom'
         case ('reverse', 'noreverse')
            call self%figure%set_key_style(reverse=tokens(i)%text == 'reverse')
         case ('Left', 'Right')
            call self%figure%set_key_style(left=tokens(i)%text == 'Left')
         case ('invert', 'noinvert')
            call self%figure%set_key_style(invert=tokens(i)%text == 'invert')
         case ('opaque', 'noopaque')
            call self%figure%set_key_style(opaque=tokens(i)%text == 'opaque')
         case ('samplen')
            if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) return
            call self%figure%set_key_style(samplen=max(0.0_R8P, v))
         case ('width')
            if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) return
            call self%figure%set_key_style(width=v)
         case ('offset')
            ! each coordinate in characters (the default), screen or graph fractions; y in the system of x unless
            ! given, as gnuplot
            block
               integer(I4P) :: units(2) !< Coordinate systems: 0 characters, 1 screen, 2 graph.

               units = 0_I4P
               if (i < size(tokens, kind=I4P)) then
                  select case (tokens(i + 1_I4P)%text)
                  case ('screen')
                     units(1) = 1_I4P
                     i = i + 1_I4P
                  case ('graph')
                     units(1) = 2_I4P
                     i = i + 1_I4P
                  case ('character', 'char', 'first', 'second')
                     units(1) = 0_I4P
                     i = i + 1_I4P
                  endselect
               endif
               if (.not. next_real(tokens, i, xy(1), iostat, iomsg, self%symbols)) return
               if (i >= size(tokens, kind=I4P)) then
                  call fail('set key: offset X,Y expected', iostat, iomsg)
                  return
               endif
               if (tokens(i + 1_I4P)%kind /= TOKEN_COMMA) then
                  call fail('set key: offset X,Y expected', iostat, iomsg)
                  return
               endif
               i = i + 1_I4P
               units(2) = units(1)
               if (i < size(tokens, kind=I4P)) then
                  select case (tokens(i + 1_I4P)%text)
                  case ('screen')
                     units(2) = 1_I4P
                     i = i + 1_I4P
                  case ('graph')
                     units(2) = 2_I4P
                     i = i + 1_I4P
                  case ('character', 'char', 'first', 'second')
                     units(2) = 0_I4P
                     i = i + 1_I4P
                  endselect
               endif
               if (.not. next_real(tokens, i, xy(2), iostat, iomsg, self%symbols)) return
               call self%figure%set_key_style(offset=xy)
               self%figure%panels(self%figure%current)%key_offset_unit = units
            endblock
         case ('title')
            ! a string expression, or nothing (no title)
            if (i < size(tokens, kind=I4P)) then
               if (.not. is_word(tokens(i + 1_I4P)%text, 'font noenhanced enhanced box nobox')) then
                  i = i + 1_I4P
                  if (.not. self%string_expression(tokens, i, text, iostat, iomsg)) then
                     iomsg = 'set key title: '//iomsg
                     return
                  endif
                  call self%figure%set_key_style(title=text, title_justify='center')
                  ! `left|center|right` right after the title: its justification, not the key's place
                  if (i < size(tokens, kind=I4P)) then
                     if (is_word(tokens(i + 1_I4P)%text, 'left center centre right')) then
                        i = i + 1_I4P
                        call self%figure%set_key_style(title_justify=tokens(i)%text)
                     endif
                  endif
                  cycle
               endif
            endif
            call self%figure%set_key_style(title='')
         case ('notitle')
            call self%figure%set_key_style(title='')
         case ('font')
            if (.not. font_spec(self, tokens, i, self%figure%panels(self%figure%current)%key_font, iostat, iomsg)) then
               iomsg = 'set key: '//iomsg
               return
            endif
         case ('noenhanced', 'noenh', 'enhanced', 'enh')
            ! the key's texts as they are, or as enhanced text
            self%figure%panels(self%figure%current)%key_plain = tokens(i)%text(1:2) == 'no'
         case ('default')
            words = ' top right inside vertical'
            box = .false.
            call self%figure%set_key_style(reverse=.false., left=.false., invert=.false., opaque=.false., samplen=-1.0_R8P, &
                                     width=0.0_R8P, title='', offset=[0.0_R8P, 0.0_R8P])
            self%autotitle = 'file'
            associate(panel => self%figure%panels(self%figure%current))
               panel%key_spacing = 1.0_R8P
               panel%key_height = 0.0_R8P
               panel%key_maxrows = 0_I4P
               panel%key_maxcols = 0_I4P
               panel%key_columns = 0_I4P
               panel%key_tc = ''
               panel%key_box_lc = ''
               panel%key_box_lw = 1.0_R8P
               panel%key_box_dt = 1_I4P
            endassociate
         case ('spacing')
            ! the row spacing, in rows
            if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) return
            self%figure%panels(self%figure%current)%key_spacing = max(0.0_R8P, v)
         case ('height')
            ! characters added to the key height
            if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) return
            self%figure%panels(self%figure%current)%key_height = v
         case ('col', 'cols', 'colu', 'colum', 'column', 'columns')
            ! gnuplot `columns N`: the key in N columns, filled top down
            if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) return
            self%figure%panels(self%figure%current)%key_columns = min(100_I4P, max(0_I4P, nint(v, I4P)))
         case ('maxrow', 'maxrows', 'maxcol', 'maxcols', 'maxcolu', 'maxcolum', 'maxcolumn', 'maxcolumns')
            ! the most rows of a vertical key, the most columns of a horizontal one; `auto` as many as fit
            block
               integer(I4P)                  :: most  !< Rows or columns, 0 for auto.
               character(len=:), allocatable :: which !< The option word.

               which = tokens(i)%text
               if (which == 'maxrow') which = 'maxrows'
               most = 0_I4P
               if (i < size(tokens, kind=I4P)) then
                  if (keyword(tokens(i + 1_I4P)%text, 'automatic', 1_I4P)) then
                     i = i + 1_I4P
                  else
                     if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) return
                     most = max(0_I4P, nint(v, I4P))
                  endif
               endif
               if (which == 'maxrows') then
                  self%figure%panels(self%figure%current)%key_maxrows = most
               else
                  self%figure%panels(self%figure%current)%key_maxcols = most
               endif
            endblock
         case ('tc', 'textcolor', 'textc', 'textco', 'textcol', 'textcolo')
            ! the titles in a color, or each in its series' (`variable`)
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%text == 'variable') then
                  i = i + 1_I4P
                  self%figure%panels(self%figure%current)%key_tc = 'variable'
                  cycle
               endif
               ! `rgb variable`, as gnuplot: each title in its series' color
               if (i + 1_I4P < size(tokens, kind=I4P)) then
                  if (is_word(tokens(i + 1_I4P)%text, 'rgb rgbcolor') .and. tokens(i + 2_I4P)%text == 'variable') then
                     i = i + 2_I4P
                     self%figure%panels(self%figure%current)%key_tc = 'variable'
                     cycle
                  endif
               endif
            endif
            block
               type(token_object), allocatable :: copy(:) !< Tokens with `lc` for the color word.
               type(line_style_object)         :: probe   !< Color read.

               copy = tokens
               copy(i)%text = 'lc'
               if (.not. line_option(copy, i, probe, iostat, iomsg, self%figure%panels(self%figure%current)% &
                                     linecolors, self%symbols)) return
               if (allocated(probe%lc)) then
                  if (index(probe%lc, '*') == 1) then
                     call fail('set key textcolor: palette colors do not apply', iostat, iomsg)
                     return
                  endif
                  self%figure%panels(self%figure%current)%key_tc = probe%lc
               endif
            endblock
         case ('lt', 'linetype', 'lw', 'linewidth', 'lc', 'linecolor', 'dt', 'dashtype', 'ls', 'linestyle')
            ! the line of the key box
            block
               type(line_style_object) :: probe !< Line read.

               if (tokens(i)%text == 'ls' .or. tokens(i)%text == 'linestyle') then
                  if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) return
                  call apply_line_style(self%line_styles, nint(v, I4P), probe, &
                                        self%figure%panels(self%figure%current)%linecolors)
               elseif (.not. line_option(tokens, i, probe, iostat, iomsg, self%figure%panels(self%figure%current)% &
                                         linecolors, self%symbols)) then
                  return
               endif
               associate(panel => self%figure%panels(self%figure%current))
                  if (allocated(probe%lc)) then
                     if (index(probe%lc, '*') == 1 .or. len(probe%lc) > len(panel%key_box_lc)) then
                        call fail('set key box: variable and palette colors do not apply', iostat, iomsg)
                        return
                     endif
                     panel%key_box_lc = probe%lc
                  endif
                  if (allocated(probe%lw)) panel%key_box_lw = probe%lw
                  if (allocated(probe%dt)) panel%key_box_dt = probe%dt
               endassociate
            endblock
         case ('fixed')
            ! the key of splot: a 2D key as it is
            continue
         case default
            call fail('set key: unsupported option "'//tokens(i)%text//'" (supported: on, off, left, right, center, '// &
                      'top, bottom, box, nobox, inside, outside, below, above, lmargin, rmargin, tmargin, bmargin, '// &
                      'at, horizontal, vertical, reverse, Left, Right, invert, opaque, samplen, spacing, width, height, '// &
                      'columns, maxrows, maxcols, offset, title, font, textcolor, lt, lw, lc, dt, ls, noenhanced, default, '// &
                      'autotitle [columnhead], noautotitle)', iostat, iomsg)
            return
         endselect
      enddo
      if (allocated(at)) then
         call self%figure%set_key(on, position=words, box=box, at=at, system=sys(1)//' '//sys(2))
      else
         call self%figure%set_key(on, position=words, box=box)
      endif
      endsubroutine key_option

      subroutine key_coordinate(toks, k, v, system, default, ok)
      !< The coordinate after token `k` of `toks` (`set key at`), `[SYSTEM] NUMBER`, advancing `k` to its number;
      !< `system` the one given, else `default`. Fails the command if malformed. The tokens and their counter passed,
      !< not host associated: called from key_option, nvfortran 26.9 gave it the host's `tokens` with size 1.
      type(token_object), intent(in)    :: toks(:) !< Option tokens.
      integer(I4P),       intent(inout) :: k       !< Token counter.
      real(R8P),          intent(out)   :: v       !< Coordinate.
      character(len=6),   intent(out)   :: system  !< Its coordinate system.
      character(len=6),   intent(in)    :: default !< System if none is given.
      logical,            intent(out)   :: ok      !< Read.

      ok = .false.
      v = 0.0_R8P
      system = default
      if (k >= size(toks, kind=I4P)) then
         call fail('set key at: X, Y expected', iostat, iomsg)
         return
      endif
      if (is_word(toks(k + 1_I4P)%text, 'first second graph screen')) then
         k = k + 1_I4P
         system = toks(k)%text
      elseif (keyword(toks(k + 1_I4P)%text, 'character', 4_I4P) .or. toks(k + 1_I4P)%text == 'polar') then
         call fail('set key at: '//toks(k + 1_I4P)%text//' coordinates are not supported (first, second, graph, '// &
                   'screen are)', iostat, iomsg)
         return
      endif
      if (k >= size(toks, kind=I4P)) then
         call fail('set key at: X, Y expected', iostat, iomsg)
         return
      endif
      k = k + 1_I4P
      if (.not. to_number(toks(k)%text, v)) then
         call fail('set key at: a number is expected, found "'//toks(k)%text//'"', iostat, iomsg)
         return
      endif
      ok = .true.
      endsubroutine key_coordinate

      subroutine colorbox_option
      !< `set colorbox [vertical|horizontal] [default|user] [origin X,Y] [size W,H] [border|bdefault|noborder]
      !< [invert|noinvert] [front]`, gnuplot's keywords and abbreviations; bare, the box returns to the default place.
      logical, allocatable   :: horizontal !< Orientation, if given.
      logical, allocatable   :: user       !< Placement, if given.
      logical, allocatable   :: border     !< Frame, if given.
      logical, allocatable   :: invert     !< Inversion, if given.
      real(R8P), allocatable :: origin(:)  !< User box origin, if given.
      real(R8P), allocatable :: box(:)     !< User box size, if given.
      character(len=:), allocatable :: word !< Option word.
      real(R8P)              :: pair(2)    !< Two numbers.

      if (size(tokens) == 1) then
         call self%figure%set_colorbox(.true.)
         return
      endif
      i = 2_I4P
      do while (i <= size(tokens, kind=I4P))
         word = tokens(i)%text
         if (tokens(i)%kind /= TOKEN_WORD) then
            call fail('set colorbox: unexpected "'//word//'"', iostat, iomsg)
            return
         elseif (keyword(word, 'vertical', 1_I4P)) then
            horizontal = .false.
         elseif (keyword(word, 'horizontal', 1_I4P)) then
            horizontal = .true.
         elseif (keyword(word, 'default', 3_I4P)) then
            user = .false.
         elseif (keyword(word, 'user', 1_I4P)) then
            user = .true.
         elseif (keyword(word, 'origin', 1_I4P)) then
            if (.not. number_pair('origin', pair)) return
            origin = pair
         elseif (keyword(word, 'size', 1_I4P)) then
            if (.not. number_pair('size', pair)) return
            if (any(pair <= 0.0_R8P)) then
               call fail('set colorbox: the size must be positive', iostat, iomsg)
               return
            endif
            box = pair
         elseif (keyword(word, 'bdefault', 2_I4P) .or. keyword(word, 'border', 2_I4P)) then
            border = .true.
            if (i < size(tokens, kind=I4P)) then
               if (to_number(tokens(i + 1_I4P)%text, pair(1))) then
                  call fail('set colorbox: border line types are not supported (border or noborder)', iostat, iomsg)
                  return
               endif
            endif
         elseif (keyword(word, 'noborder', 4_I4P)) then
            border = .false.
         elseif (keyword(word, 'invert', 3_I4P)) then
            invert = .true.
         elseif (keyword(word, 'noinvert', 5_I4P)) then
            invert = .false.
         elseif (keyword(word, 'front', 2_I4P)) then
            continue
         elseif (keyword(word, 'back', 2_I4P)) then
            call fail('set colorbox: back is not supported (the box is drawn in front)', iostat, iomsg)
            return
         else
            call fail('set colorbox: unsupported option "'//word//'"', iostat, iomsg)
            return
         endif
         i = i + 1_I4P
      enddo
      call self%figure%set_colorbox(.true., horizontal=horizontal, user=user, origin=origin, size=box, border=border, &
                                    invert=invert)
      endsubroutine colorbox_option

      function number_pair(name, pair) result(ok)
      !< Read `X,Y` after the `name` keyword at token `i` into `pair`, leaving `i` on Y.
      character(len=*), intent(in)  :: name    !< Keyword, for messages.
      real(R8P),        intent(out) :: pair(2) !< X and Y.
      logical                       :: ok      !< Read.

      ok = i + 3_I4P <= size(tokens, kind=I4P)
      if (ok) ok = tokens(i + 2_I4P)%kind == TOKEN_COMMA .and. to_number(tokens(i + 1_I4P)%text, pair(1)) .and. &
                   to_number(tokens(i + 3_I4P)%text, pair(2))
      if (.not. ok) then
         call fail('set colorbox: '//name//' needs X,Y', iostat, iomsg)
         return
      endif
      i = i + 3_I4P
      endfunction number_pair

      subroutine colorsequence_option
      !< `set colorsequence default|podo|classic` (gnuplot's linetype colors), or foresight's `NAME [N]`: the first N
      !< colors (8 by default) of a categorical order (`batlowS`, ..., any case).
      character(len=9), allocatable :: list(:) !< Colors.
      character(len=:), allocatable :: bad     !< Problem.
      real(R8P)                     :: v       !< Number of colors.
      integer(I4P)                  :: n       !< Number of colors.
      logical                       :: ok      !< Number read.

      if (size(tokens) < 2) then
         call fail('set colorsequence: default, podo, classic or a categorical order (batlowS, ...) expected', &
                   iostat, iomsg)
         return
      endif
      n = 0_I4P
      if (size(tokens) > 3) then
         call fail('set colorsequence: unexpected "'//tokens(4)%text//'"', iostat, iomsg)
         return
      elseif (size(tokens) == 3) then
         call real_from_decimal(tokens(3)%text, v, ok)
         if (ok) ok = .not. any(tokens(2)%text == ['default', 'podo   ', 'classic'])
         if (ok) ok = v >= 1.0_R8P .and. v <= 100.0_R8P .and. v == aint(v)
         if (.not. ok) then
            call fail('set colorsequence: "'//tokens(3)%text//'" (a categorical order takes 1 to 100 colors; '// &
                      'default, podo and classic none)', iostat, iomsg)
            return
         endif
         n = int(v, I4P)
      endif
      call sequence_colors(tokens(2)%text, n, list, bad)
      if (len(bad) > 0) then
         call fail('set colorsequence: '//bad, iostat, iomsg)
         return
      endif
      associate(panel => self%figure%panels(self%figure%current))
         if (allocated(panel%linecolors)) deallocate(panel%linecolors)
         if (size(list) > 0) panel%linecolors = list
      endassociate
      endsubroutine colorsequence_option

      subroutine nonlinear_option
      !< gnuplot `set nonlinear x|y via EXPR inverse EXPR`: the axis placed linearly in the values of the first map (of
      !< `x`, of `y`), the second its inverse; see foresight_axes' nonlinear_axis.
      type(expression_object) :: fwd  !< Forward map.
      type(expression_object) :: inv  !< Inverse map.
      character(len=1)        :: axis !< x or y.
      integer(I4P)            :: k    !< Token counter.
      integer(I4P)            :: v    !< Token of `via`.
      integer(I4P)            :: w    !< Token of `inverse`.

      if (size(tokens) < 2) then
         call fail('set nonlinear: x or y expected', iostat, iomsg)
         return
      endif
      if (.not. (tokens(2)%text == 'x' .or. tokens(2)%text == 'y')) then
         call fail('set nonlinear: x or y expected (x2, y2, cb and r are not supported), found "'//tokens(2)%text//'"', &
                   iostat, iomsg)
         return
      endif
      axis = tokens(2)%text
      v = 0_I4P
      w = 0_I4P
      do k = 3_I4P, size(tokens, kind=I4P)
         if (tokens(k)%text == 'via') v = k
         if (keyword(tokens(k)%text, 'inverse', 3_I4P)) w = k
      enddo
      if (v /= 3_I4P .or. w <= v + 1_I4P .or. w >= size(tokens, kind=I4P)) then
         call fail('set nonlinear: via EXPR inverse EXPR expected', iostat, iomsg)
         return
      endif
      associate(panel => self%figure%panels(self%figure%current))
         call fwd%compile(expression_source(tokens(v + 1_I4P:w - 1_I4P)), iostat, iomsg, variable=axis, &
                          degrees=panel%degrees, symbols=self%symbols)
         if (iostat /= 0_I4P) then
            iomsg = 'set nonlinear: via: '//iomsg
            return
         endif
         call inv%compile(expression_source(tokens(w + 1_I4P:)), iostat, iomsg, variable=axis, &
                          degrees=panel%degrees, symbols=self%symbols)
         if (iostat /= 0_I4P) then
            iomsg = 'set nonlinear: inverse: '//iomsg
            return
         endif
         call grow_maps
         if (axis == 'x') then
            panel%link_maps(5) = fwd
            panel%link_maps(6) = inv
            panel%nonlinear_x = .true.
         else
            panel%link_maps(7) = fwd
            panel%link_maps(8) = inv
            panel%nonlinear_y = .true.
         endif
      endassociate
      endsubroutine nonlinear_option

      subroutine grow_maps
      !< The maps of the current panel, 8 (link and nonlinear), those set kept.
      type(expression_object), allocatable :: maps(:) !< Maps.
      integer(I4P)                         :: k       !< Counter.

      associate(panel => self%figure%panels(self%figure%current))
         if (allocated(panel%link_maps)) then
            if (size(panel%link_maps) >= 8) return
            allocate(maps(8))
            do k = 1_I4P, size(panel%link_maps, kind=I4P)
               maps(k) = panel%link_maps(k)
            enddo
            call move_alloc(maps, panel%link_maps)
         else
            allocate(panel%link_maps(8))
         endif
      endassociate
      endsubroutine grow_maps

      subroutine link_option
      !< gnuplot `set link x2|y2 [via EXPR inverse EXPR]` (`x`, `y` name them too): the secondary axis on the range of
      !< the first, its ticks through the maps (of `x`, of `y`), its data plotted through the inverse.
      type(expression_object)       :: fwd     !< Forward map.
      type(expression_object)       :: inv     !< Inverse map.
      character(len=:), allocatable :: axis    !< x2 or y2.
      character(len=1)              :: dummy   !< Map variable.
      integer(I4P)                  :: k       !< Token counter.
      integer(I4P)                  :: v       !< Token of `via`.
      integer(I4P)                  :: w       !< Token of `inverse`.

      if (size(tokens) < 2) then
         call fail('set link: x2 or y2 expected', iostat, iomsg)
         return
      endif
      axis = tokens(2)%text
      if (axis == 'x') axis = 'x2'
      if (axis == 'y') axis = 'y2'
      if (.not. (axis == 'x2' .or. axis == 'y2')) then
         call fail('set link: x2 or y2 expected, found "'//tokens(2)%text//'"', iostat, iomsg)
         return
      endif
      dummy = axis(1:1)
      v = 0_I4P
      w = 0_I4P
      do k = 3_I4P, size(tokens, kind=I4P)
         if (tokens(k)%text == 'via') v = k
         if (keyword(tokens(k)%text, 'inverse', 3_I4P)) w = k
      enddo
      associate(panel => self%figure%panels(self%figure%current))
         if (v == 0_I4P) then
            if (size(tokens) > 2) then
               call fail('set link: via EXPR inverse EXPR expected', iostat, iomsg)
               return
            endif
            if (axis == 'x2') then
               panel%link_x2 = .true.
               panel%link_x2_via = .false.
            else
               panel%link_y2 = .true.
               panel%link_y2_via = .false.
            endif
            return
         endif
         if (v /= 3_I4P .or. w <= v + 1_I4P .or. w >= size(tokens, kind=I4P)) then
            call fail('set link: via EXPR inverse EXPR expected', iostat, iomsg)
            return
         endif
         call fwd%compile(expression_source(tokens(v + 1_I4P:w - 1_I4P)), iostat, iomsg, variable=dummy, &
                          degrees=panel%degrees, symbols=self%symbols)
         if (iostat /= 0_I4P) then
            iomsg = 'set link: via: '//iomsg
            return
         endif
         call inv%compile(expression_source(tokens(w + 1_I4P:)), iostat, iomsg, variable=dummy, &
                          degrees=panel%degrees, symbols=self%symbols)
         if (iostat /= 0_I4P) then
            iomsg = 'set link: inverse: '//iomsg
            return
         endif
         call grow_maps
         if (axis == 'x2') then
            panel%link_maps(1) = fwd
            panel%link_maps(2) = inv
            panel%link_x2 = .true.
            panel%link_x2_via = .true.
         else
            panel%link_maps(3) = fwd
            panel%link_maps(4) = inv
            panel%link_y2 = .true.
            panel%link_y2_via = .true.
         endif
      endassociate
      endsubroutine link_option

      subroutine colormap_option
      !< gnuplot 6.0's `set colormap new NAME` (the current palette saved as NAME, for `lc palette NAME`) and `set
      !< colormap NAME range [min:max]` (its own range, else the color axis').
      integer(I4P)          :: k     !< Colormap index.
      integer(I4P)          :: colon !< Range separator.
      type(colormap_object) :: map   !< New colormap.

      if (size(tokens) == 3) then
         if (tokens(2)%text == 'new') then
            map%palette = self%figure%panels(self%figure%current)%palette
            k = self%colormap_index(tokens(3)%text)
            if (.not. allocated(self%colormap_names)) allocate(self%colormap_names(0), self%colormaps(0))
            if (k == 0_I4P) then
               self%colormap_names = [self%colormap_names, [character(len=64) :: tokens(3)%text]]
               self%colormaps = [self%colormaps, map]
            else
               self%colormaps(k) = map
            endif
            return
         endif
      endif
      if (size(tokens) == 4) then
         if (tokens(3)%text == 'range' .and. tokens(4)%kind == TOKEN_RANGE) then
            k = self%colormap_index(tokens(2)%text)
            if (k == 0_I4P) then
               call fail('set colormap: no colormap "'//tokens(2)%text//'" (set colormap new NAME)', iostat, iomsg)
               return
            endif
            colon = index(tokens(4)%text, ':', kind=I4P)
            if (colon == 0_I4P) then
               call fail('set colormap: range [min:max] expected', iostat, iomsg)
               return
            endif
            associate(map_k => self%colormaps(k))
               call self%range_value(tokens(4)%text(1:colon - 1_I4P), map_k%range(1), iostat, iomsg)
               if (iostat /= 0_I4P) return
               call self%range_value(tokens(4)%text(colon + 1_I4P:), map_k%range(2), iostat, iomsg)
               if (iostat /= 0_I4P) return
               map_k%ranged = .true.
            endassociate
            return
         endif
      endif
      call fail('set colormap: new NAME or NAME range [min:max] expected', iostat, iomsg)
      endsubroutine colormap_option

      subroutine palette_option
      !< `set palette [WORDS]`: checked on a copy, then applied (see foresight_palette). `file 'f' [index N] [every E]
      !< [using U]` reads a gradient as gnuplot: 4 columns gray:r:g:b, or 3 columns r:g:b evenly spaced (default: 4
      !< if the rows have a 4th column), components 0 to 1 (clipped), `#` comments skipped, no blank lines.
      !< `functions R, G, B`: three expressions of `gray` (0 to 1), clipped to 0..1, the components of the model (RGB or
      !< HSV), sampled at 1025 gray levels into a gradient (linear between them, far below a color step).
      type(palette_object)                 :: probe  !< Palette the words are tried on.
      character(len=:), allocatable        :: formulas(:) !< `functions` expressions, empty if none.
      character(len=:), allocatable        :: words  !< Palette words.
      character(len=:), allocatable        :: after  !< Palette words after the file.
      character(len=:), allocatable        :: bad    !< Unknown word.
      character(len=:), allocatable        :: file   !< Palette file.
      character(len=:), allocatable        :: word   !< Modifier argument.
      type(datafile_object)                :: pdata  !< Palette file data.
      type(expression_object), allocatable :: pfields(:) !< `using` fields.
      real(R8P), allocatable               :: rows(:,:)  !< Gradient rows.
      real(R8P), allocatable               :: pos(:)     !< Gradient positions.
      integer(I4P)                         :: pevery(6)  !< `every` fields.
      integer(I4P)                         :: pindex     !< Dataset, negative for all.
      integer(I4P)                         :: n          !< Rows.
      integer(I4P)                         :: k          !< Row counter.

      words = ''
      after = ''
      file = ''
      pindex = -1_I4P
      pevery = [1_I4P, 1_I4P, 0_I4P, 0_I4P, -1_I4P, -1_I4P]
      allocate(character(len=0) :: formulas(0))
      i = 2_I4P
      do while (i <= size(tokens, kind=I4P))
         if (tokens(i)%kind == TOKEN_WORD .and. keyword(tokens(i)%text, 'functions', 2_I4P) .and. len(file) == 0) then
            ! three expressions of gray, comma separated
            block
               character(len=:), allocatable :: part(:) !< The three texts.
               integer(I4P)                  :: c       !< Component.
               integer(I4P)                  :: e       !< Last token of one.
               integer(I4P)                  :: width   !< Longest.
               type(token_object)            :: f(3)    !< Texts.

               do c = 1_I4P, 3_I4P
                  i = i + 1_I4P
                  if (c > 1_I4P) then
                     if (i <= size(tokens, kind=I4P)) then
                        if (tokens(i)%kind /= TOKEN_COMMA) i = size(tokens, kind=I4P) + 1_I4P
                     endif
                     i = i + 1_I4P
                  endif
                  if (i > size(tokens, kind=I4P)) then
                     call fail('set palette: functions R, G, B expected (expressions of gray)', iostat, iomsg)
                     return
                  endif
                  e = expression_end(tokens, i)
                  f(c)%text = expression_source(tokens(i:e))
                  i = e
               enddo
               width = max(len(f(1)%text), len(f(2)%text), len(f(3)%text))
               allocate(character(len=width) :: part(3))
               do c = 1_I4P, 3_I4P
                  part(c) = f(c)%text
               enddo
               call move_alloc(part, formulas)
            endblock
         elseif (tokens(i)%kind == TOKEN_WORD .and. tokens(i)%text == 'file' .and. len(file) == 0) then
            if (i == size(tokens, kind=I4P)) then
               call fail('set palette: file needs a file name', iostat, iomsg)
               return
            endif
            i = i + 1_I4P
            file = tokens(i)%text
            if (len(file) == 0) then
               call fail('set palette: file needs a file name', iostat, iomsg)
               return
            endif
            do while (i < size(tokens, kind=I4P))
               word = tokens(i + 1_I4P)%text
               if (keyword(word, 'using', 1_I4P)) then
                  i = i + 1_I4P
                  if (.not. next_word(tokens, i, word, iostat, iomsg)) return
                  call parse_using(word, pfields, iostat, iomsg, self%figure%panels(self%figure%current)%degrees, &
                                   self%symbols)
                  if (iostat /= 0_I4P) return
               elseif (keyword(word, 'index', 1_I4P)) then
                  i = i + 1_I4P
                  if (.not. next_integer(tokens, i, pindex, iostat, iomsg)) return
               elseif (keyword(word, 'every', 2_I4P)) then
                  i = i + 1_I4P
                  if (.not. next_word(tokens, i, word, iostat, iomsg)) return
                  call parse_every(word, pevery, iostat, iomsg, self%symbols)
                  if (iostat /= 0_I4P) return
               else
                  exit
               endif
            enddo
         elseif (len(file) == 0) then
            words = words//' '//tokens(i)%text
         else
            after = after//' '//tokens(i)%text
         endif
         i = i + 1_I4P
      enddo
      probe = self%figure%panels(self%figure%current)%palette
      ! no words reset the palette, unless a file follows: then they only modify it, as gnuplot
      bad = ''
      if (len(file) == 0 .or. len_trim(words) > 0) call palette_words(words, probe, bad)
      if (len(bad) > 0) then
         call fail('set palette: unsupported option "'//bad//'"', iostat, iomsg)
         return
      endif
      if (size(formulas) == 3) then
         ! the functions sampled into a gradient, the words (model, negative, ...) kept
         block
            type(expression_object) :: fe(3)       !< Compiled functions.
            real(R8P)               :: grays(1025) !< Gray levels.
            real(R8P)               :: comps(3, 1025) !< Components.
            integer(I4P)            :: c           !< Component.
            integer(I4P)            :: g           !< Level.

            do c = 1_I4P, 3_I4P
               call fe(c)%compile(trim(formulas(c)), iostat, iomsg, variable='gray', &
                                  degrees=self%figure%panels(self%figure%current)%degrees, symbols=self%symbols)
               if (iostat /= 0_I4P) then
                  iomsg = 'set palette functions: '//iomsg
                  return
               endif
            enddo
            do g = 1_I4P, 1025_I4P
               grays(g) = real(g - 1_I4P, R8P) / 1024.0_R8P
               do c = 1_I4P, 3_I4P
                  comps(c, g) = fe(c)%value_at(grays(g))
                  if (comps(c, g) /= comps(c, g)) then
                     call fail('set palette functions: undefined at gray = '//gnuplot_real(grays(g)), iostat, iomsg)
                     return
                  endif
               enddo
            enddo
            call palette_gradient(probe, grays, comps, bad)
            if (len(bad) > 0) then
               call fail('set palette functions: '//bad, iostat, iomsg)
               return
            endif
            self%figure%panels(self%figure%current)%palette = probe
         endblock
         return
      endif
      if (len(file) == 0) then
         call self%figure%set_palette(words)
         return
      endif
      if (allocated(pfields)) then
         ! the cell texts kept for a field reading them (`rgbcolor(strcol(2))`)
         call self%load_data(pdata, file, iostat, iomsg, keep_text=any(pfields%uses_text()))
      else
         call self%load_data(pdata, file, iostat, iomsg)
      endif
      if (iostat /= 0_I4P) then
         iomsg = 'set palette file: '//iomsg
         return
      endif
      call self%register_file(file)
      if (.not. allocated(pfields)) then
         ! gnuplot's default: gray:r:g:b if the rows have a 4th column, else r:g:b
         pfields = plain_columns([1_I4P, 2_I4P, 3_I4P, 4_I4P])
         call pdata%table(pfields, pindex, pevery, rows)
         ! rows without a 4th column are skipped (gnuplot): none left means r:g:b
         if (size(rows, 1) == 0) then
            pfields = plain_columns([1_I4P, 2_I4P, 3_I4P])
         elseif (all(rows(:, 4) /= rows(:, 4))) then
            pfields = plain_columns([1_I4P, 2_I4P, 3_I4P])
         endif
      endif
      if (size(pfields) < 2 .or. size(pfields) > 4) then
         call fail('set palette file: using needs r:g:b, gray:r:g:b or gray:rgb', iostat, iomsg)
         return
      endif
      call pdata%table(pfields, pindex, pevery, rows)
      n = size(rows, 1, kind=I4P)
      if (n == 0_I4P) then
         call fail('set palette file: no colors in "'//file//'"', iostat, iomsg)
         return
      endif
      do k = 1_I4P, n
         if (any(rows(k, :) /= rows(k, :))) then
            call fail('set palette file: bad data in "'//file//'" (a number in every column, no blank line)', &
                      iostat, iomsg)
            return
         endif
      enddo
      if (size(pfields) == 4) then
         pos = rows(:, 1)
         call palette_gradient(probe, pos, transpose(rows(:, 2:4)), bad)
      elseif (size(pfields) == 2) then
         ! gray:rgb, the 24-bit RGB packed (gnuplot's `using 1:(rgbcolor(strcol(2)))`)
         pos = rows(:, 1)
         block
            real(R8P), allocatable :: rgb(:,:) !< Channels 0..1 (3, row).
            integer(I8P)           :: packed   !< Packed RGB.

            allocate(rgb(3, n))
            do k = 1_I4P, n
               packed = int(rows(k, 2), I8P)
               rgb(:, k) = real([ibits(packed, 16, 8), ibits(packed, 8, 8), ibits(packed, 0, 8)], R8P) / 255.0_R8P
            enddo
            call palette_gradient(probe, pos, rgb, bad)
         endblock
      else
         pos = [(real(k, R8P), k = 0_I4P, n - 1_I4P)]
         call palette_gradient(probe, pos, transpose(rows(:, 1:3)), bad)
      endif
      if (len(bad) > 0) then
         call fail('set palette file: "'//file//'": '//bad, iostat, iomsg)
         return
      endif
      if (len_trim(after) > 0) call palette_words(after, probe, bad)
      if (len(bad) > 0) then
         call fail('set palette: unsupported option "'//bad//'"', iostat, iomsg)
         return
      endif
      self%figure%panels(self%figure%current)%palette = probe
      endsubroutine palette_option

      subroutine boxwidth_option
      !< `set boxwidth [W] [absolute|relative]`: no width restores the default, boxes touching.
      real(R8P), allocatable :: width    !< Width.
      logical                :: relative !< Relative width.
      real(R8P)              :: v        !< Parsed number.

      relative = .false.
      do i = 2_I4P, size(tokens, kind=I4P)
         if (keyword(tokens(i)%text, 'absolute', 1_I4P)) then
            relative = .false.
         elseif (keyword(tokens(i)%text, 'relative', 1_I4P)) then
            relative = .true.
         elseif (i == 2_I4P .and. to_number(tokens(i)%text, v)) then
            if (v < 0.0_R8P) then
               call fail('set boxwidth: the width must not be negative', iostat, iomsg)
               return
            endif
            width = v
         else
            call fail('set boxwidth: unsupported option "'//tokens(i)%text//'" (W [absolute|relative] expected)', &
                      iostat, iomsg)
            return
         endif
      enddo
      call self%figure%set_boxwidth(width, relative)
      endsubroutine boxwidth_option

      subroutine readout_option
      !< `set readout [on|off] [left|right|center] [top|bottom|center] [horizontal|vertical] [opaque|noopaque]
      !< [size H]`, a foresight extension.
      character(len=:), allocatable :: words  !< Position words.
      logical                       :: on     !< Readouts on.
      logical, allocatable          :: opaque !< Window, unallocated if not given.
      real(R8P), allocatable        :: digits !< Digit height, unallocated if not given.
      real(R8P)                     :: v      !< Parsed number.

      on = .true.
      words = ''
      i = 2_I4P
      do while (i <= size(tokens, kind=I4P))
         select case (tokens(i)%text)
         case ('on')
            on = .true.
         case ('off')
            on = .false.
         case ('opaque')
            opaque = .true.
         case ('noopaque')
            opaque = .false.
         case ('size')
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) then
               call fail('set readout: size needs a digit height [px]', iostat, iomsg)
               return
            endif
            if (.not. to_number(tokens(i)%text, v)) then
               call fail('set readout: size needs a digit height [px], found "'//tokens(i)%text//'"', iostat, iomsg)
               return
            endif
            if (v < 0.0_R8P) then
               call fail('set readout: size must not be negative', iostat, iomsg)
               return
            endif
            digits = v
         case ('left', 'right', 'center', 'top', 'bottom', 'horizontal', 'horiz', 'vertical', 'vert')
            words = words//' '//tokens(i)%text
         case default
            call fail('set readout: unsupported option "'//tokens(i)%text//'" (supported: on, off, left, right, '// &
                      'center, top, bottom, horizontal, vertical, opaque, noopaque, size H)', iostat, iomsg)
            return
         endselect
         i = i + 1_I4P
      enddo
      call self%figure%set_readout(on, position=words, opaque=opaque, size=digits)
      endsubroutine readout_option

      subroutine pair_option(default, words)
      !< `set origin [X,Y]` and `set size [W,H]`, page fractions; no values restore `default`.
      real(R8P),          intent(in) :: default(2) !< Default values.
      type(token_object), intent(in) :: words(:)   !< Option tokens (of size, without the aspect words).
      type(token_object), allocatable :: tokens(:) !< Option tokens.
      real(R8P)                       :: pair(2)   !< Values.

      tokens = words
      if (self%figure%layout) then
         call fail('set '//option//': not supported with a multiplot layout', iostat, iomsg)
         return
      endif
      pair = default
      if (size(tokens) > 1) then
         if (size(tokens) /= 4 .or. tokens(2)%kind /= TOKEN_WORD .or. tokens(3)%kind /= TOKEN_COMMA .or. &
             tokens(4)%kind /= TOKEN_WORD) then
            call fail('set '//option//': two numbers X,Y expected', iostat, iomsg)
            return
         endif
         if (.not. (to_number(tokens(2)%text, pair(1)) .and. to_number(tokens(4)%text, pair(2)))) then
            call fail('set '//option//': two numbers X,Y expected', iostat, iomsg)
            return
         endif
      endif
      if (keyword(option, 'size', 2_I4P)) then
         if (any(pair <= 0.0_R8P)) then
            call fail('set size: the size must be positive', iostat, iomsg)
            return
         endif
         call self%figure%set_size(pair(1), pair(2))
      else
         call self%figure%set_origin(pair(1), pair(2))
      endif
      endsubroutine pair_option

      subroutine paxis_option
      !< `set paxis N range [min:max]|tics [auto|STEP|START,STEP[,END]]|label "text"`.
      real(R8P)    :: v    !< Axis number.
      integer(I4P) :: n    !< Axis number.

      if (size(tokens) < 3) then
         call fail('set paxis: N range|tics|label expected', iostat, iomsg)
         return
      endif
      if (.not. to_number(tokens(2)%text, v)) then
         ! a constant expression: `set for [i=1:5] paxis i tics`
         block
            character(len=:), allocatable :: message !< Not a constant.
            integer(I4P)                  :: status  !< Constant status.

            call self%symbols%constant(trim(tokens(2)%text), v, status, message)
            if (status /= 0_I4P) then
               call fail('set paxis: an axis number is expected, found "'//tokens(2)%text//'"', iostat, iomsg)
               return
            endif
         endblock
      endif
      if (v < 1.0_R8P .or. v > 1000.0_R8P .or. v /= aint(v)) then
         call fail('set paxis: the axis number is 1 to 1000', iostat, iomsg)
         return
      endif
      n = int(v, I4P)
      ! the axis exists before its settings change in place
      call self%figure%set_paxis(n)
      associate(panel => self%figure%panels(self%figure%current))
         if (keyword(tokens(3)%text, 'range', 3_I4P)) then
            if (size(tokens) < 4) then
               call fail('set paxis: range [min:max] expected', iostat, iomsg)
               return
            endif
            ! the range options after it, as set xrange's: reverse (an axis with an autoscaled end), extend
            block
               integer(I4P) :: k !< Option counter.

               do k = 5_I4P, size(tokens, kind=I4P)
                  select case (tokens(k)%text)
                  case ('reverse', 'noreverse')
                     panel%paxes(n)%axis%reverse = tokens(k)%text == 'reverse'
                  case ('extend', 'noextend')
                     panel%paxes(n)%axis%noextend = tokens(k)%text == 'noextend'
                  case ('writeback', 'nowriteback', 'restore')
                     continue
                  case default
                     call fail('set paxis: range [min:max] [reverse|noreverse] [extend|noextend] expected, found "'// &
                               tokens(k)%text//'"', iostat, iomsg)
                     return
                  endselect
               enddo
            endblock
            block
               integer(I4P) :: colon !< Separator position.

               colon = index(tokens(4)%text, ':', kind=I4P)
               if (tokens(4)%kind /= TOKEN_RANGE .or. colon == 0_I4P) then
                  call fail('set paxis: range [min:max] expected', iostat, iomsg)
                  return
               endif
               associate(axis => panel%paxes(n)%axis)
                  call range_end(tokens(4)%text(1:colon - 1_I4P), axis%min_fixed, axis%min_user, 1_I4P)
                  if (iostat /= 0_I4P) return
                  call range_end(tokens(4)%text(colon + 1_I4P:), axis%max_fixed, axis%max_user, 2_I4P)
               endassociate
            endblock
         elseif (keyword(tokens(3)%text, 'tics', 3_I4P)) then
            call tics_option(panel%paxes(n)%axis%tics, tokens(3:))
         elseif (keyword(tokens(3)%text, 'label', 3_I4P)) then
            if (size(tokens) /= 4 .or. tokens(4)%kind /= TOKEN_STRING) then
               call fail('set paxis: label "text" expected', iostat, iomsg)
               return
            endif
            panel%paxes(n)%label = tokens(4)%text
         else
            call fail('set paxis: unsupported option "'//tokens(3)%text//'" (range, tics, label)', iostat, iomsg)
         endif
      endassociate
      endsubroutine paxis_option

      subroutine polar_grid_option
      !< gnuplot `set polar grid [T[, R]] [qnorm [Q]|gauss|cauchy|exp|box [kdensity]] [scale S] [theta [MIN:MAX]]
      !< [r [MIN:MAX]]`: the segments of the grid of `with surface` (T in 6..999, R in 2..100, others ignored), the
      !< weighting of the data and the clipping of the grid; a theta end below 0 a turn later.
      integer(I4P)                  :: k     !< Token.
      integer(I4P)                  :: n     !< Number read.
      real(R8P)                     :: v     !< Value read.
      real(R8P)                     :: lim(2) !< Range limits.
      character(len=:), allocatable :: part  !< A range limit as written.

      k = 3_I4P
      associate(grid => self%polar_grid)
         if (k <= size(tokens, kind=I4P)) then
            if (verify(tokens(k)%text(1:1), '0123456789') == 0) then
               ! next_integer reads the token after its index
               k = k - 1_I4P
               if (.not. next_integer(tokens, k, n, iostat, iomsg, self%symbols)) return
               if (n > 5_I4P .and. n < 1000_I4P) grid%theta_segments = n
               if (k < size(tokens, kind=I4P)) then
                  if (tokens(k + 1_I4P)%kind == TOKEN_COMMA) then
                     k = k + 1_I4P
                     if (.not. next_integer(tokens, k, n, iostat, iomsg, self%symbols)) return
                     if (n > 1_I4P .and. n < 101_I4P) grid%r_segments = n
                  endif
               endif
               k = k + 1_I4P
            endif
         endif
         do while (k <= size(tokens, kind=I4P))
            select case (tokens(k)%text)
            case ('qnorm', 'gauss', 'cauchy', 'exp', 'box')
               grid%mode = index('qgceb', tokens(k)%text(1:1), kind=I4P)
               if (tokens(k)%text == 'qnorm' .and. k < size(tokens, kind=I4P)) then
                  if (verify(tokens(k + 1_I4P)%text(1:1), '0123456789') == 0) then
                     if (.not. next_integer(tokens, k, n, iostat, iomsg, self%symbols)) return
                     if (n > 0_I4P .and. n < 25_I4P) grid%norm_q = n
                  endif
               endif
               grid%kdensity = .false.
               if (k < size(tokens, kind=I4P)) then
                  if (tokens(k + 1_I4P)%text == 'kdensity') then
                     grid%kdensity = .true.
                     k = k + 1_I4P
                  endif
               endif
            case ('scale')
               if (.not. next_real(tokens, k, v, iostat, iomsg, self%symbols)) return
               grid%scale = v
               if (.not. grid%scale > 0.0_R8P) grid%scale = 1.0_R8P
            case ('theta', 'r')
               if (k == size(tokens, kind=I4P)) then
                  call fail('set polar grid: '//tokens(k)%text//' [min:max] expected', iostat, iomsg)
                  return
               endif
               if (tokens(k + 1_I4P)%kind /= TOKEN_RANGE .or. index(tokens(k + 1_I4P)%text, ':') == 0) then
                  call fail('set polar grid: '//tokens(k)%text//' [min:max] expected', iostat, iomsg)
                  return
               endif
               lim = merge([0.0_R8P, 360.0_R8P], [0.0_R8P, huge(1.0_R8P)], tokens(k)%text == 'theta')
               do n = 1_I4P, 2_I4P
                  if (n == 1_I4P) then
                     part = trim(adjustl(tokens(k + 1_I4P)%text(1:index(tokens(k + 1_I4P)%text, ':') - 1)))
                  else
                     part = trim(adjustl(tokens(k + 1_I4P)%text(index(tokens(k + 1_I4P)%text, ':') + 1:)))
                  endif
                  if (len(part) == 0 .or. part == '*') cycle
                  call self%symbols%constant(part, v, iostat, iomsg, degrees=self%figure%panels(self%figure%current)%degrees)
                  if (iostat /= 0_I4P) then
                     iomsg = 'set polar grid: '//iomsg
                     return
                  endif
                  lim(n) = v
               enddo
               if (tokens(k)%text == 'theta') then
                  if (lim(2) < 0.0_R8P) lim(2) = lim(2) + 360.0_R8P
                  grid%tmin = lim(1)
                  grid%tmax = lim(2)
               else
                  grid%rmin = lim(1)
                  grid%rmax = lim(2)
               endif
               k = k + 1_I4P
            case default
               call fail('set polar grid: unexpected "'//tokens(k)%text//'" (T,R, qnorm, gauss, cauchy, exp, box, '// &
                         'kdensity, scale, theta [min:max], r [min:max])', iostat, iomsg)
               return
            endselect
            k = k + 1_I4P
         enddo
      endassociate
      endsubroutine polar_grid_option

      subroutine size_option
      !< `set size [square|nosquare|ratio R|noratio] [W,H]`: the plot area aspect, and the page fractions of the plot
      !< (no values restore 1,1).
      type(token_object), allocatable :: rest(:) !< Size tokens, aspect words removed.
      real(R8P)                       :: ratio   !< Height over width.
      logical                         :: aspect  !< An aspect word given.

      allocate(rest(1))
      rest(1) = tokens(1)
      aspect = .false.
      ratio = 0.0_R8P
      i = 2_I4P
      do while (i <= size(tokens, kind=I4P))
         if (tokens(i)%kind == TOKEN_WORD .and. keyword(tokens(i)%text, 'square', 2_I4P)) then
            aspect = .true.
            ratio = 1.0_R8P
         elseif (tokens(i)%kind == TOKEN_WORD .and. (keyword(tokens(i)%text, 'nosquare', 4_I4P) .or. &
                                                     keyword(tokens(i)%text, 'noratio', 4_I4P))) then
            aspect = .true.
            ratio = 0.0_R8P
         elseif (tokens(i)%kind == TOKEN_WORD .and. keyword(tokens(i)%text, 'ratio', 2_I4P)) then
            aspect = .true.
            i = i + 1_I4P
            ok_ratio: block
               if (i <= size(tokens, kind=I4P)) then
                  if (to_number(tokens(i)%text, ratio)) exit ok_ratio
               endif
               call fail('set size: ratio needs a number', iostat, iomsg)
               return
            endblock ok_ratio
         else
            call push(rest, tokens(i))
         endif
         i = i + 1_I4P
      enddo
      if (aspect) call self%figure%set_size(ratio=ratio)
      if (aspect .and. size(rest) == 1) return
      call pair_option([1.0_R8P, 1.0_R8P], rest)
      endsubroutine size_option

      subroutine grid_option
      !< `set grid [[no]{m}{x|y|x2|y2}tics|x|y|x2|y2|mx|my]... [front|back|layerdefault] [lt N] [lc C] [lw W] [dt N]
      !< [polar [STEP]] [spiderplot]`, as gnuplot: the named lines turned on (off with no), the others kept, x and y when
      !< none is; the line style of the grid; the polar grid with spokes every STEP (30 by default) in the angle unit.
      real(R8P)                     :: step   !< Spoke step.
      real(R8P)                     :: v      !< A number.
      logical                       :: lines(6) !< x, y, x2, y2, mx, my.
      logical                       :: polar  !< polar given.
      logical                       :: rings  !< r given: the rings at the r ticks.
      logical                       :: tokens_black !< `lt black` read.
      logical                       :: no_rings !< nor given.
      character(len=:), allocatable :: w      !< Word.
      character(len=:), allocatable :: base   !< Word without no.
      type(line_style_object)       :: style  !< Line properties.
      integer(I4P)                  :: k      !< Line index.

      associate(panel => self%figure%panels(self%figure%current))
         lines = panel%grid_lines
      endassociate
      polar = .false.
      tokens_black = .false.
      rings = .false.
      no_rings = .false.
      step = 30.0_R8P
      i = 2_I4P
      do while (i <= size(tokens, kind=I4P))
         w = tokens(i)%text
         base = w
         if (len(w) > 2) then
            if (w(1:2) == 'no') base = w(3:)
         endif
         k = grid_line_index(base)
         if (k > 0_I4P) then
            lines(k) = base == w
         elseif (is_word(w, 'front back layerdefault')) then
            call self%figure%set_grid(front=w == 'front')
         elseif (keyword(w, 'spiderplot', 6_I4P)) then
            call self%figure%set_grid(spider=.true.)
         elseif (is_word(w, 'r rtics')) then
            ! gnuplot's polar grid at the r ticks: the rings (with polar, its spokes too)
            rings = .true.
         elseif (is_word(w, 'nor nortics')) then
            rings = .false.
            no_rings = .true.
         elseif (keyword(w, 'polar', 2_I4P)) then
            polar = .true.
            if (i < size(tokens, kind=I4P)) then
               if (to_number(tokens(i + 1_I4P)%text, v)) then
                  step = v
                  ! in the angle unit, but beyond a full turn of radians in degrees, as gnuplot's (`polar 60`)
                  if (.not. self%figure%panels(self%figure%current)%degrees .and. v <= 2.0_R8P * acos(-1.0_R8P)) &
                     step = step * (180.0_R8P / acos(-1.0_R8P))
                  i = i + 1_I4P
               endif
            endif
            if (.not. (step > 0.0_R8P .and. step < 360.0_R8P)) then
               call fail('set grid polar: the step must be positive and below a full turn', iostat, iomsg)
               return
            endif
         elseif (is_line_option(w)) then
            if (keyword(w, 'linetype', 5_I4P) .or. w == 'lt') then
               ! lt 0: gnuplot's grid dots, lt -1 (black): the border's solid black
               if (i < size(tokens, kind=I4P)) then
                  if (tokens(i + 1_I4P)%text == 'black') then
                     tokens_black = .true.
                  endif
               endif
               if (tokens_black) then
                  i = i + 1_I4P
                  v = -1.0_R8P
                  tokens_black = .false.
               elseif (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) then
                  return
               endif
               if (nint(v) == 0) then
                  call self%figure%set_grid(lc='', dt=0_I4P)
               elseif (nint(v) == -1) then
                  call self%figure%set_grid(lc='black', dt=1_I4P)
               else
                  call self%figure%set_grid(lc=default_color(int(v, I4P), &
                                            self%figure%panels(self%figure%current)%linecolors), dt=1_I4P)
               endif
            else
               if (.not. line_option(tokens, i, style, iostat, iomsg, &
                                     self%figure%panels(self%figure%current)%linecolors, self%symbols)) return
               if (allocated(style%lc)) call self%figure%set_grid(lc=style%lc)
               if (keyword(w, 'linewidth', 5_I4P) .or. w == 'lw') call self%figure%set_grid(lw=style%lw)
               if (keyword(w, 'dashtype', 5_I4P) .or. w == 'dt') call self%figure%set_grid(dt=style%dt)
            endif
         elseif (tokens(i)%kind == TOKEN_COMMA) then
            ! the minor grid's style follows: the same here
            continue
         else
            call fail('set grid: unsupported option "'//w//'" (x, y, x2, y2, mx, my and their {no}{m}tics forms, '// &
                      'r, front, back, layerdefault, lt, lc, lw, dt, polar [STEP], spiderplot)', iostat, iomsg)
            return
         endif
         i = i + 1_I4P
      enddo
      if (.not. any(lines)) lines(1:2) = .true.
      if (polar) then
         call self%figure%set_grid(.true., polar=step, lines=lines)
      elseif (rings) then
         ! the rings alone: no spoke (a step of a full turn draws none)
         call self%figure%set_grid(.true., polar=360.0_R8P, lines=lines)
      elseif (no_rings) then
         call self%figure%set_grid(polar=0.0_R8P)
      else
         call self%figure%set_grid(.true., lines=lines)
         if (size(tokens) == 1 .or. any(is_word_list(tokens(2:)))) then
            call self%figure%set_grid(polar=0.0_R8P)
         endif
      endif
      endsubroutine grid_option

      pure function grid_line_index(w) result(k)
      !< Index of a grid line word: x, y, x2, y2, mx, my or their tics forms (xtics, mxtics, ...); 0 if none.
      character(len=*), intent(in) :: w !< Word.
      integer(I4P)                 :: k !< x, y, x2, y2, mx, my: 1 to 6.

      select case (w)
      case ('x', 'xtics', 'xtic')
         k = 1_I4P
      case ('y', 'ytics', 'ytic')
         k = 2_I4P
      case ('x2', 'x2tics', 'x2tic')
         k = 3_I4P
      case ('y2', 'y2tics', 'y2tic')
         k = 4_I4P
      case ('mx', 'mxtics', 'mxtic')
         k = 5_I4P
      case ('my', 'mytics', 'mytic')
         k = 6_I4P
      case default
         k = 0_I4P
      endselect
      endfunction grid_line_index

      pure function is_word_list(toks) result(yes)
      !< Per token: whether it names a grid line (a rectangular grid asked).
      type(token_object), intent(in) :: toks(:) !< Tokens.
      logical                        :: yes(size(toks)) !< Grid line words.
      integer(I4P)                   :: k       !< Counter.

      do k = 1_I4P, size(toks, kind=I4P)
         yes(k) = grid_line_index(toks(k)%text) > 0_I4P
      enddo
      endfunction is_word_list

      subroutine theta_option
      !< `set theta [right|top|left|bottom] [clockwise|cw|counterclockwise|ccw]`; no words restore right ccw.
      character(len=6) :: origin    !< Direction of theta = 0.
      logical          :: clockwise !< Theta grows clockwise.

      origin = 'right'
      clockwise = .false.
      do i = 2_I4P, size(tokens, kind=I4P)
         if (keyword(tokens(i)%text, 'right', 1_I4P)) then
            origin = 'right'
         elseif (keyword(tokens(i)%text, 'top', 1_I4P)) then
            origin = 'top'
         elseif (keyword(tokens(i)%text, 'left', 1_I4P)) then
            origin = 'left'
         elseif (keyword(tokens(i)%text, 'bottom', 1_I4P)) then
            origin = 'bottom'
         elseif (tokens(i)%text == 'clockwise' .or. tokens(i)%text == 'cw') then
            clockwise = .true.
         elseif (tokens(i)%text == 'counterclockwise' .or. tokens(i)%text == 'ccw') then
            clockwise = .false.
         else
            call fail('set theta: unsupported option "'//tokens(i)%text//'" (right, top, left, bottom, clockwise, '// &
                      'counterclockwise)', iostat, iomsg)
            return
         endif
      enddo
      call self%figure%set_theta(trim(origin), clockwise)
      endsubroutine theta_option

      subroutine ttics_option
      !< `set ttics [[START,]STEP] [format FMT] [font F] [rotate|norotate] [offset R]`: theta labels [deg]; no step:
      !< every 45 degrees; FMT a string expression; the font read and ignored; `rotate` turns the labels along their
      !< angle, `offset` moves them out (gnuplot's radial use of its x), alone they keep the ticks.
      character(len=:), allocatable :: format  !< Label format.
      character(len=:), allocatable :: message !< Format problem.
      real(R8P)                     :: v(2)    !< Start, step.
      integer(I4P)                  :: n       !< Position tokens.
      integer(I4P)                  :: last    !< Last token before `font`.
      integer(I4P)                  :: j       !< Format expression end.
      integer(I4P)                  :: k       !< Token counter.
      type(token_object), allocatable :: kept(:) !< The tokens but the label options.
      logical                       :: rotated !< `rotate` or `norotate` given.
      logical                       :: shifted !< `offset` given.
      real(R8P)                     :: shift   !< Radial offset.
      logical                       :: turn    !< `rotate`.

      ! `rotate [by A]`, `norotate`, `offset X[,Y]`: taken out of the tokens
      rotated = .false.
      shifted = .false.
      turn = .false.
      shift = 0.0_R8P
      allocate(kept(0))
      k = 1_I4P
      do while (k <= size(tokens, kind=I4P))
         if (tokens(k)%kind == TOKEN_WORD .and. (tokens(k)%text == 'rotate' .or. tokens(k)%text == 'norotate')) then
            rotated = .true.
            turn = tokens(k)%text == 'rotate'
            if (turn .and. k + 1_I4P < size(tokens, kind=I4P)) then
               if (tokens(k + 1_I4P)%text == 'by') k = k + 2_I4P
            endif
         elseif (tokens(k)%kind == TOKEN_WORD .and. tokens(k)%text == 'offset') then
            if (k == size(tokens, kind=I4P)) then
               call fail('set ttics: offset R expected', iostat, iomsg)
               return
            endif
            k = k + 1_I4P
            if (.not. to_number(tokens(k)%text, shift)) then
               call fail('set ttics: offset R expected (a number, the radial shift)', iostat, iomsg)
               return
            endif
            shifted = .true.
            ! a y offset read and ignored, as gnuplot
            if (k + 2_I4P <= size(tokens, kind=I4P)) then
               if (tokens(k + 1_I4P)%kind == TOKEN_COMMA) k = k + 2_I4P
            endif
         else
            call push(kept, tokens(k))
         endif
         k = k + 1_I4P
      enddo
      associate(ttics => self%figure%panels(self%figure%current)%ttics)
         if (rotated) ttics%rotate = merge(90.0_R8P, 0.0_R8P, turn)
         if (shifted) ttics%offset(1) = shift
         ! the label options alone: the ticks kept (on if off)
         if ((rotated .or. shifted) .and. size(kept) == 1) then
            if (ttics%mode == TICS_NONE) call self%figure%set_ttics()
            return
         endif
      endassociate
      call ttics_positions(kept)
      endsubroutine ttics_option

      subroutine ttics_positions(tokens)
      !< The positions, list and format of `set ttics` (see `ttics_option`), its label options taken out.
      type(token_object), intent(in) :: tokens(:) !< Option tokens.
      character(len=:), allocatable :: format  !< Label format.
      character(len=:), allocatable :: message !< Format problem.
      real(R8P)                     :: v(3)    !< Start, step, end.
      integer(I4P)                  :: n       !< Position tokens.
      integer(I4P)                  :: last    !< Last token before `font`.
      integer(I4P)                  :: j       !< Format expression end.
      integer(I4P)                  :: k       !< Token counter.
      real(R8P)                     :: turned  !< Label rotation kept.
      real(R8P)                     :: moved   !< Label offset kept.

      associate(ttics => self%figure%panels(self%figure%current)%ttics)
         turned = ttics%rotate
         moved = ttics%offset(1)
      endassociate
      last = size(tokens, kind=I4P)
      ! `[add] ("label" angle [level], ...)`: an explicit list, replacing the labels or added to them
      if (last >= 2_I4P) then
         block
            type(tic_item), allocatable :: items(:) !< List items.
            logical                     :: add      !< `add`.
            integer(I4P)                :: at       !< List token.

            add = tokens(2)%text == 'add'
            at = merge(3_I4P, 2_I4P, add)
            if (at <= last) then
               if (tokens(at)%text(1:min(1, len(tokens(at)%text))) == '(') then
                  ! `font F` after the list: the labels' font, as the other tics options
                  if (at + 2_I4P == last) then
                     if (tokens(at + 1_I4P)%text == 'font') then
                        j = at + 1_I4P
                        if (.not. font_spec(self, tokens, j, self%figure%panels(self%figure%current)%ttics%font, &
                                            iostat, iomsg)) then
                           iomsg = 'set ttics: '//iomsg
                           return
                        endif
                        last = at
                     endif
                  endif
                  if (at /= last) then
                     call fail('set ttics: unexpected "'//tokens(at + 1_I4P)%text//'" after the list', iostat, iomsg)
                     return
                  endif
                  call list_items(tokens(at)%text, items)
                  if (iostat /= 0_I4P) return
                  associate(ttics => self%figure%panels(self%figure%current)%ttics)
                     if (ttics%mode == TICS_NONE) call self%figure%set_ttics()
                     call ttics%set_list(items, add)
                  endassociate
                  return
               endif
            endif
         endblock
      endif
      ! `font F` at the end: the labels' font
      if (last >= 3_I4P) then
         if (tokens(last - 1_I4P)%kind == TOKEN_WORD .and. tokens(last - 1_I4P)%text == 'font') then
            j = last - 1_I4P
            if (.not. font_spec(self, tokens, j, self%figure%panels(self%figure%current)%ttics%font, iostat, &
                                iomsg)) then
               iomsg = 'set ttics: '//iomsg
               return
            endif
            last = last - 2_I4P
         endif
      endif
      ! `format EXPRESSION`, a string expression (`"%g".GPVAL_DEGREE_SIGN`)
      n = last - 1_I4P
      do k = 2_I4P, last - 1_I4P
         if (tokens(k)%kind == TOKEN_WORD .and. keyword(tokens(k)%text, 'format', 1_I4P)) then
            j = k + 1_I4P
            if (.not. self%string_expression(tokens(1:last), j, format, iostat, iomsg)) then
               iomsg = 'set ttics: format: '//iomsg
               return
            endif
            if (j /= last) then
               call fail('set ttics: unexpected "'//tokens(j + 1_I4P)%text//'" after the format', iostat, iomsg)
               return
            endif
            message = format_check(format)
            if (len(message) > 0) then
               call fail('set ttics: '//message, iostat, iomsg)
               return
            endif
            n = k - 2_I4P
            exit
         endif
      enddo
      select case (n)
      case (0_I4P)
         call self%figure%set_ttics(format=format)
      case (1_I4P)
         if (.not. to_number(tokens(2)%text, v(2))) n = -1_I4P
         if (n > 0_I4P) then
            if (.not. v(2) > 0.0_R8P) n = -1_I4P
         endif
         if (n > 0_I4P) call self%figure%set_ttics(step=v(2), format=format)
      case (3_I4P)
         if (tokens(3)%kind /= TOKEN_COMMA .or. .not. to_number(tokens(2)%text, v(1)) .or. &
             .not. to_number(tokens(4)%text, v(2))) n = -1_I4P
         if (n > 0_I4P) then
            if (.not. v(2) > 0.0_R8P) n = -1_I4P
         endif
         if (n > 0_I4P) call self%figure%set_ttics(step=v(2), start=v(1), format=format)
      case (5_I4P)
         ! START,STEP,END: the labels up to END
         if (tokens(3)%kind /= TOKEN_COMMA .or. tokens(5)%kind /= TOKEN_COMMA .or. &
             .not. to_number(tokens(2)%text, v(1)) .or. .not. to_number(tokens(4)%text, v(2)) .or. &
             .not. to_number(tokens(6)%text, v(3))) n = -1_I4P
         if (n > 0_I4P) then
            if (.not. v(2) > 0.0_R8P) n = -1_I4P
         endif
         if (n > 0_I4P) then
            call self%figure%set_ttics(step=v(2), start=v(1), format=format)
            call self%figure%panels(self%figure%current)%ttics%set_fixed(tokens(4)%text, tokens(2)%text, &
                                                                         tokens(6)%text, message)
            if (len(message) > 0) n = -1_I4P
         endif
      case default
         n = -1_I4P
      endselect
      if (n < 0_I4P) call fail('set ttics: supported forms are STEP, START,STEP and START,STEP,END (degrees, step > '// &
                               '0), with format "fmt"', iostat, iomsg)
      ! the label options survive the new positions
      associate(ttics => self%figure%panels(self%figure%current)%ttics)
         ttics%rotate = turned
         ttics%offset(1) = moved
      endassociate
      endsubroutine ttics_positions

      subroutine border_option
      !< `set border [MASK] [polar] [front|back|behind] [LINE OPTIONS]`: the sides of the frame (1 bottom, 2 left, 4 top,
      !< 8 right; 31 by default; MASK a number or a constant expression) and the circle of the largest r on a polar panel;
      !< the layer is read and ignored (the border over the data).
      integer(I4P) :: mask  !< Sides, -1 if not given.
      logical      :: polar !< Polar border.
      real(R8P)    :: v     !< Mask value.

      mask = -1_I4P
      polar = .false.
      i = 1_I4P
      do while (i < size(tokens, kind=I4P))
         i = i + 1_I4P
         if (tokens(i)%kind == TOKEN_WORD .and. keyword(tokens(i)%text, 'polar', 2_I4P)) then
            polar = .true.
         elseif (tokens(i)%kind == TOKEN_WORD .and. is_word(tokens(i)%text, 'front back behind')) then
            ! foresight draws the border over the data, gnuplot's default: the layer is read and ignored
            continue
         elseif (tokens(i)%kind == TOKEN_WORD .and. is_line_option(tokens(i)%text)) then
            if (.not. line_props(tokens, i, 'border')) return
         else
            ! the mask: a number or a constant expression (`set border bb`)
            if (.not. to_number(tokens(i)%text, v)) then
               block
                  character(len=:), allocatable :: message !< Not a constant.
                  integer(I4P)                  :: status  !< Constant status.

                  call self%symbols%constant(trim(tokens(i)%text), v, status, message)
                  if (status /= 0_I4P) then
                     call fail('set border: unsupported option "'//tokens(i)%text//'" (MASK, polar, front, back, '// &
                               'behind, lt, lc, lw, dt)', iostat, iomsg)
                     return
                  endif
               endblock
            endif
            if (v < 0.0_R8P .or. v > 4095.0_R8P .or. v /= aint(v)) then
               call fail('set border: the mask is an integer 0 to 4095', iostat, iomsg)
               return
            endif
            mask = int(v, I4P)
         endif
      enddo
      if (mask >= 0_I4P) then
         call self%figure%set_border(mask, polar)
      elseif (polar) then
         call self%figure%set_border(polar=.true.)
      else
         call self%figure%set_border()
      endif
      endsubroutine border_option

      function line_props(toks, k, what, axes) result(ok)
      !< A line property at token `k` (left on its last token) for the border or the zero axes: lt N (0 gnuplot's
      !< dots, -1 the frame's black solid, N the color of linetype N), lc, lw, dt.
      type(token_object), intent(in)           :: toks(:) !< Tokens.
      integer(I4P),       intent(inout)        :: k       !< Token counter.
      character(len=*),   intent(in)           :: what    !< `border` or `zeroaxis`.
      character(len=*),   intent(in), optional :: axes    !< Zero axes.
      logical                                  :: ok      !< Well formed.
      type(line_style_object)                  :: style   !< Line properties.
      real(R8P)                                :: v       !< A number.
      character(len=:), allocatable            :: w       !< Property.

      ok = .true.
      w = toks(k)%text
      if (keyword(w, 'linetype', 5_I4P) .or. w == 'lt') then
         ok = next_real(toks, k, v, iostat, iomsg, self%symbols)
         if (.not. ok) return
         select case (nint(v))
         case (0)
            call apply_line(what, axes, lc='', dt=3_I4P)
         case (-1)
            call apply_line(what, axes, lc='', dt=1_I4P)
         case default
            call apply_line(what, axes, lc=default_color(int(v, I4P), self%figure%panels(self%figure%current)%linecolors), dt=1_I4P)
         endselect
         return
      endif
      ok = line_option(toks, k, style, iostat, iomsg, self%figure%panels(self%figure%current)%linecolors, self%symbols)
      if (.not. ok) return
      if (keyword(w, 'linewidth', 5_I4P) .or. w == 'lw') then
         call apply_line(what, axes, lw=style%lw)
      elseif (keyword(w, 'dashtype', 5_I4P) .or. w == 'dt') then
         call apply_line(what, axes, dt=style%dt)
      elseif (allocated(style%lc)) then
         call apply_line(what, axes, lc=style%lc)
      else
         call fail('set '//what//': '//w//' does not apply', iostat, iomsg)
         ok = .false.
      endif
      endfunction line_props

      subroutine apply_line(what, axes, lc, lw, dt)
      !< Set a line property on the border (`what` border) or the zero axes `axes`.
      character(len=*), intent(in)           :: what !< `border` or `zeroaxis`.
      character(len=*), intent(in), optional :: axes !< Zero axes.
      character(len=*), intent(in), optional :: lc   !< Color.
      real(R8P),        intent(in), optional :: lw   !< Width.
      integer(I4P),     intent(in), optional :: dt   !< Dash type.

      if (what == 'border') then
         call self%figure%set_border_style(lc=lc, lw=lw, dt=dt)
      else
         call self%figure%set_zeroaxis(axes, lc=lc, lw=lw, dt=dt)
      endif
      endsubroutine apply_line

      subroutine zeroaxis_option(axes)
      !< gnuplot `set zeroaxis|xzeroaxis|yzeroaxis|x2zeroaxis|y2zeroaxis [lt N] [lc C] [lw W] [dt N]`: the lines at
      !< zero of `axes`, gnuplot's black dots by default.
      character(len=*), intent(in) :: axes !< Axes.

      call self%figure%set_zeroaxis(axes)
      i = 1_I4P
      do while (i < size(tokens, kind=I4P))
         i = i + 1_I4P
         if (tokens(i)%kind /= TOKEN_WORD .or. .not. is_line_option(tokens(i)%text)) then
            call fail('set '//option//': unsupported option "'//tokens(i)%text//'" (lt, lc, lw, dt)', iostat, iomsg)
            return
         endif
         if (.not. line_props(tokens, i, 'zeroaxis', axes)) return
      enddo
      endsubroutine zeroaxis_option

      subroutine autoscale_option
      !< gnuplot `set autoscale [AXES|AXESmin|AXESmax|AXESfix|fix|noextend|keepfix]...` (AXES x, y, x2, y2, cb, xy):
      !< the named axes (all without one) autoscaled again, `fix` and `noextend` their ends not extended to the ticks.
      logical :: named(5)  !< x, y, x2, y2, cb named.
      logical :: tight     !< fix or noextend.
      character(len=:), allocatable :: w !< Word.
      character(len=*), parameter   :: AXES(5) = [character(len=2) :: 'x', 'y', 'x2', 'y2', 'cb'] !< Axis names.
      integer(I4P) :: a    !< Axis counter.
      integer(I4P) :: k    !< Token counter.
      logical      :: ends(2) !< min, max autoscaled.

      named = .false.
      tight = .false.
      do k = 2_I4P, size(tokens, kind=I4P)
         w = tokens(k)%text
         ends = .true.
         if (w == 'fix' .or. w == 'noextend') then
            tight = .true.
            cycle
         endif
         if (w == 'keepfix') cycle
         if (w == 'xy') then
            named(1:2) = .true.
            call autoscale(1_I4P, ends, .false.)
            call autoscale(2_I4P, ends, .false.)
            cycle
         endif
         do a = 1_I4P, 5_I4P
            if (index(w, trim(AXES(a))) /= 1) cycle
            select case (w(len_trim(AXES(a)) + 1:))
            case ('')
               exit
            case ('min')
               ends = [.true., .false.]
               exit
            case ('max')
               ends = [.false., .true.]
               exit
            case ('fix', 'fixmin', 'fixmax')
               exit
            endselect
         enddo
         if (a > 5_I4P) then
            call fail('set autoscale: unsupported option "'//w//'" (x, y, x2, y2, cb, xy with min, max, fix; fix, '// &
                      'noextend)', iostat, iomsg)
            return
         endif
         named(a) = .true.
         call autoscale(a, ends, index(w, 'fix') > 0)
         ! `set autoscale x` (the axis name alone) forgets the limits of its ends, as gnuplot's set_autoscale_axis
         if (w == trim(AXES(a))) call forget_limits(a)
      enddo
      if (.not. any(named)) then
         do a = 1_I4P, 5_I4P
            call autoscale(a, [.true., .true.], tight)
         enddo
      elseif (tight) then
         do a = 1_I4P, 5_I4P
            if (named(a)) call autoscale(a, [.false., .false.], .true.)
         enddo
      endif
      endsubroutine autoscale_option

      subroutine forget_limits(a)
      !< The limits of the autoscaled ends of axis `a` (x, y, x2, y2, cb) forgotten.
      integer(I4P), intent(in) :: a !< Axis.

      associate(panel => self%figure%panels(self%figure%current))
         select case (a)
         case (1_I4P)
            panel%xaxis%bounded = .false.
         case (2_I4P)
            panel%yaxis%bounded = .false.
         case (3_I4P)
            panel%x2axis%bounded = .false.
         case (4_I4P)
            panel%y2axis%bounded = .false.
         case default
            panel%cbaxis%bounded = .false.
         endselect
      endassociate
      endsubroutine forget_limits

      subroutine autoscale(a, ends, fix)
      !< Axis `a` (x, y, x2, y2, cb) autoscaled at its `ends` (min, max), not extended to the ticks with `fix`.
      integer(I4P), intent(in) :: a       !< Axis.
      logical,      intent(in) :: ends(2) !< min, max autoscaled.
      logical,      intent(in) :: fix     !< Ends at the data.

      associate(panel => self%figure%panels(self%figure%current))
         select case (a)
         case (1_I4P)
            call autoscale_axis(panel%xaxis, ends, fix)
         case (2_I4P)
            call autoscale_axis(panel%yaxis, ends, fix)
         case (3_I4P)
            call autoscale_axis(panel%x2axis, ends, fix)
         case (4_I4P)
            call autoscale_axis(panel%y2axis, ends, fix)
         case default
            call autoscale_axis(panel%cbaxis, ends, fix)
         endselect
      endassociate
      endsubroutine autoscale

      function margin_value(side) result(ok)
      !< A margin after token `i` (left on its last token): `[at screen] N`, or nothing (computed).
      character(len=1), intent(in) :: side   !< `l`, `r`, `t` or `b`.
      logical                      :: ok     !< Well formed.
      logical                      :: screen !< `at screen`.
      real(R8P)                    :: v      !< Value.

      ok = .true.
      if (i >= size(tokens, kind=I4P)) then
         call self%figure%set_margin(side)
         return
      endif
      if (tokens(i + 1_I4P)%kind == TOKEN_COMMA) then
         call self%figure%set_margin(side)
         return
      endif
      screen = .false.
      if (keyword(tokens(i + 1_I4P)%text, 'screen', 2_I4P)) then
         ! gnuplot also reads `set lmargin screen X`, without `at`
         screen = .true.
         i = i + 1_I4P
      elseif (tokens(i + 1_I4P)%text == 'at') then
         if (i + 2_I4P > size(tokens, kind=I4P)) then
            call fail('set '//option//': at screen F expected', iostat, iomsg)
            ok = .false.
            return
         endif
         if (.not. keyword(tokens(i + 2_I4P)%text, 'screen', 2_I4P)) then
            call fail('set '//option//': at screen F expected (only screen)', iostat, iomsg)
            ok = .false.
            return
         endif
         screen = .true.
         i = i + 2_I4P
      endif
      ok = next_real(tokens, i, v, iostat, iomsg, self%symbols)
      if (.not. ok) then
         iomsg = 'set '//option//': '//iomsg
         return
      endif
      call self%figure%set_margin(side, value=v, screen=screen)
      endfunction margin_value

      subroutine all_tics_option(scale_only)
      !< gnuplot `set tics [mirror|nomirror] [in|out] [scale MAJOR[,MINOR]|default] [border]`: the options of every axis
      !< (scale also the color box's); bare, the x and y ticks on. `set ticscale MAJOR [MINOR]` (`scale_only`) its scale.
      logical, intent(in)  :: scale_only !< `set ticscale`.
      real(R8P)            :: scale(2)   !< Tick scale.
      type(token_object), allocatable :: toks(:) !< Tokens, `scale` put first for ticscale.
      logical              :: scaled     !< A scale given.
      type(tics_object)    :: labels     !< The label options read (offset, color).
      character(len=:), allocatable :: fmt !< `format "..."`, unallocated if not given.
      logical              :: styled     !< Label options given.

      toks = tokens
      scaled = .false.
      styled = .false.
      associate(panel => self%figure%panels(self%figure%current))
         if (size(toks) == 1) then
            if (scale_only) then
               call fail('set ticscale: a scale is expected', iostat, iomsg)
               return
            endif
            call panel%xaxis%tics%enable
            call panel%yaxis%tics%enable
            return
         endif
         if (scale_only) toks(1)%text = 'scale'
         i = merge(1_I4P, 2_I4P, scale_only)
         do while (i <= size(toks, kind=I4P))
            if (toks(i)%kind == TOKEN_WORD .and. keyword(toks(i)%text, 'scale', 2_I4P)) then
               if (.not. scale_values(toks, i, scale)) return
               scaled = .true.
            elseif (toks(i)%kind == TOKEN_WORD .and. is_word(toks(i)%text, 'mirror nomirror')) then
               panel%xaxis%tics%mirror = toks(i)%text == 'mirror'
               panel%yaxis%tics%mirror = toks(i)%text == 'mirror'
               panel%x2axis%tics%mirror = toks(i)%text == 'mirror'
               panel%y2axis%tics%mirror = toks(i)%text == 'mirror'
            elseif (toks(i)%kind == TOKEN_WORD .and. is_word(toks(i)%text, 'in out')) then
               panel%xaxis%tics%out = toks(i)%text == 'out'
               panel%yaxis%tics%out = toks(i)%text == 'out'
               panel%x2axis%tics%out = toks(i)%text == 'out'
               panel%y2axis%tics%out = toks(i)%text == 'out'
            elseif (toks(i)%kind == TOKEN_WORD .and. is_word(toks(i)%text, 'axis border')) then
               ! on the zero axes, or on the border
               panel%xaxis%tics%on_axis = toks(i)%text == 'axis'
               panel%yaxis%tics%on_axis = toks(i)%text == 'axis'
            elseif (toks(i)%kind == TOKEN_WORD .and. (keyword(toks(i)%text, 'rangelimited', 10_I4P) .or. &
                                                      keyword(toks(i)%text, 'norangelimited', 12_I4P))) then
               ! the ticks (and the border sides) within the data ranges; gnuplot's rangelimit$ed
               panel%xaxis%tics%rangelimited = toks(i)%text(1:2) /= 'no'
               panel%yaxis%tics%rangelimited = toks(i)%text(1:2) /= 'no'
               panel%x2axis%tics%rangelimited = toks(i)%text(1:2) /= 'no'
               panel%y2axis%tics%rangelimited = toks(i)%text(1:2) /= 'no'
            elseif (toks(i)%kind == TOKEN_WORD .and. (toks(i)%text == 'rotate' .or. toks(i)%text == 'norotate')) then
               ! the x and x2 labels turned (`rotate` 90 degrees, `rotate by A`); the y ones are not (read)
               block
                  real(R8P) :: angle !< Angle [deg].

                  angle = merge(90.0_R8P, 0.0_R8P, toks(i)%text == 'rotate')
                  if (toks(i)%text == 'rotate' .and. i + 1_I4P < size(toks, kind=I4P)) then
                     if (toks(i + 1_I4P)%text == 'by') then
                        i = i + 1_I4P
                        if (.not. next_real(toks, i, angle, iostat, iomsg, self%symbols)) return
                     endif
                  endif
                  panel%xaxis%tics%rotate = angle
                  panel%x2axis%tics%rotate = angle
               endblock
            elseif (toks(i)%kind == TOKEN_WORD .and. toks(i)%text == 'nooffset') then
               panel%xaxis%tics%offset = 0.0_R8P
               panel%yaxis%tics%offset = 0.0_R8P
               panel%x2axis%tics%offset = 0.0_R8P
               panel%y2axis%tics%offset = 0.0_R8P
            elseif (label_option(toks, i, labels, fmt)) then
               if (iostat /= 0_I4P) return
               styled = .true.
            elseif (toks(i)%kind == TOKEN_WORD .and. is_word(toks(i)%text, 'noenhanced enhanced')) then
               ! the tick labels as they are, or as enhanced text
               panel%xaxis%tics%plain = toks(i)%text == 'noenhanced'
               panel%yaxis%tics%plain = toks(i)%text == 'noenhanced'
               panel%x2axis%tics%plain = toks(i)%text == 'noenhanced'
               panel%y2axis%tics%plain = toks(i)%text == 'noenhanced'
               panel%cbaxis%tics%plain = toks(i)%text == 'noenhanced'
            elseif (toks(i)%kind == TOKEN_WORD .and. is_word(toks(i)%text, 'front back')) then
               ! gnuplot's grid_tics_in_front: the grid (and ticks) over the data, as `set grid front`
               panel%grid_front = toks(i)%text == 'front'
            elseif (toks(i)%kind == TOKEN_WORD .and. verify(toks(i)%text(1:1), '0123456789.') == 0) then
               ! gnuplot `set tics INCR`: the step of every axis, which axes show ticks unchanged
               block
                  character(len=:), allocatable :: message !< Step problem.
                  real(R8P)                     :: v       !< Step.

                  if (.not. to_number(toks(i)%text, v)) then
                     call fail('set tics: a number expected, found "'//toks(i)%text//'"', iostat, iomsg)
                     return
                  endif
                  message = ''
                  if (panel%xaxis%tics%mode /= TICS_NONE) call panel%xaxis%tics%set_fixed(toks(i)%text, '', '', message)
                  if (panel%yaxis%tics%mode /= TICS_NONE .and. len(message) == 0) &
                     call panel%yaxis%tics%set_fixed(toks(i)%text, '', '', message)
                  if (panel%x2axis%tics%mode /= TICS_NONE .and. len(message) == 0) &
                     call panel%x2axis%tics%set_fixed(toks(i)%text, '', '', message)
                  if (panel%y2axis%tics%mode /= TICS_NONE .and. len(message) == 0) &
                     call panel%y2axis%tics%set_fixed(toks(i)%text, '', '', message)
                  if (len(message) > 0) then
                     call fail('set tics: '//message, iostat, iomsg)
                     return
                  endif
               endblock
            else
               call fail('set tics: supported options are mirror, nomirror, in, out, scale, axis, border, '// &
                         'rangelimited, format, font, offset, textcolor and noenhanced, not "'//toks(i)%text//'"', &
                         iostat, iomsg)
               return
            endif
            i = i + 1_I4P
         enddo
         if (scaled) then
            panel%xaxis%tics%scale = scale
            panel%yaxis%tics%scale = scale
            panel%x2axis%tics%scale = scale
            panel%y2axis%tics%scale = scale
            panel%cbaxis%tics%scale = scale
         endif
         ! the label options of every axis
         if (styled) then
            if (allocated(fmt)) then
               panel%xaxis%tics%format = fmt
               panel%yaxis%tics%format = fmt
               panel%x2axis%tics%format = fmt
               panel%y2axis%tics%format = fmt
               panel%cbaxis%tics%format = fmt
            endif
            ! the options given only
            if (offset_given()) then
               panel%xaxis%tics%offset = labels%offset
               panel%yaxis%tics%offset = labels%offset
               panel%x2axis%tics%offset = labels%offset
               panel%y2axis%tics%offset = labels%offset
               panel%cbaxis%tics%offset = labels%offset
            endif
            if (len_trim(labels%color) > 0) then
               panel%xaxis%tics%color = labels%color
               panel%yaxis%tics%color = labels%color
               panel%x2axis%tics%color = labels%color
               panel%y2axis%tics%color = labels%color
               panel%cbaxis%tics%color = labels%color
            endif
            if (labels%font%is_set()) then
               panel%xaxis%tics%font = labels%font
               panel%yaxis%tics%font = labels%font
               panel%x2axis%tics%font = labels%font
               panel%y2axis%tics%font = labels%font
               panel%cbaxis%tics%font = labels%font
               panel%ttics%font = labels%font
            endif
         endif
      endassociate
      endsubroutine all_tics_option

      function scale_values(toks, k, scale) result(ok)
      !< `scale MAJOR[,MINOR]` or `scale default` at token `k` (left on its last token): the tick lengths in major lengths,
      !< MINOR half MAJOR if absent, as gnuplot; default 1, 0.5.
      type(token_object), intent(in)    :: toks(:)  !< Tokens.
      integer(I4P),       intent(inout) :: k        !< Token counter.
      real(R8P),          intent(inout) :: scale(2) !< Tick scale.
      logical                           :: ok       !< Well formed.
      real(R8P)                         :: v        !< A number.

      ok = .false.
      if (k >= size(toks, kind=I4P)) then
         call fail('set '//option//': scale needs MAJOR[,MINOR] or default', iostat, iomsg)
         return
      endif
      if (toks(k + 1_I4P)%text == 'default') then
         scale = [1.0_R8P, 0.5_R8P]
         k = k + 1_I4P
         ok = .true.
         return
      endif
      if (.not. to_number(toks(k + 1_I4P)%text, v) .or. v < 0.0_R8P) then
         call fail('set '//option//': scale needs MAJOR[,MINOR] or default, not "'//toks(k + 1_I4P)%text//'"', iostat, &
                   iomsg)
         return
      endif
      k = k + 1_I4P
      scale = [v, 0.5_R8P * v]
      if (k + 1_I4P < size(toks, kind=I4P)) then
         if (toks(k + 1_I4P)%kind == TOKEN_COMMA) then
            if (.not. to_number(toks(k + 2_I4P)%text, v) .or. v < 0.0_R8P) then
               call fail('set '//option//': scale needs MAJOR[,MINOR], not "'//toks(k + 2_I4P)%text//'"', iostat, iomsg)
               return
            endif
            scale(2) = v
            k = k + 2_I4P
         endif
      endif
      ok = .true.
      endfunction scale_values

      function offset_given() result(yes)
      !< Whether the command tokens hold `offset` or `nooffset`.
      logical      :: yes !< Found.
      integer(I4P) :: k   !< Counter.

      yes = .false.
      do k = 1_I4P, size(tokens, kind=I4P)
         if (tokens(k)%text == 'offset' .or. tokens(k)%text == 'nooffset') yes = .true.
      enddo
      endfunction offset_given

      function label_option(toks, i, tics, fmt) result(handled)
      !< The tick label options of `set xtics` and `set tics` at `toks(i)`, `i` left on their last token: `format "f"`
      !< (`fmt`, checked: a number or a time format), `font "f"` (the labels' font), `offset X[,Y]`
      !< (characters, y up) and `nooffset`, `textcolor|tc COLOR`. False if `toks(i)` is none of them; an error sets
      !< `iostat`.
      type(token_object),            intent(in)    :: toks(:) !< Option tokens.
      integer(I4P),                  intent(inout) :: i       !< Token counter.
      type(tics_object),             intent(inout) :: tics    !< Axis tick settings.
      character(len=:), allocatable, intent(inout) :: fmt     !< Label format read.
      logical                                      :: handled !< An option of the labels.
      type(token_object), allocatable              :: copy(:) !< Tokens with `lc` for the color word.
      type(line_style_object)                      :: probe   !< Color read.
      character(len=:), allocatable                :: text    !< A string.
      real(R8P)                                    :: v(2)    !< Offset.

      handled = .false.
      if (toks(i)%kind /= TOKEN_WORD) return
      handled = .true.
      if (toks(i)%text == 'format') then
         if (i == size(toks, kind=I4P)) then
            call fail('set '//option//': format needs a string', iostat, iomsg)
            return
         endif
         i = i + 1_I4P
         if (.not. self%string_expression(toks, i, text, iostat, iomsg)) then
            iomsg = 'set '//option//': format: '//iomsg
            return
         endif
         if (len(text) > 0) then
            if (len(format_check(text)) > 0 .and. len(time_format_check(text)) > 0) then
               call fail('set '//option//': format: '//format_check(text), iostat, iomsg)
               return
            endif
         endif
         fmt = text
      elseif (toks(i)%text == 'font') then
         ! the labels' font (gnuplot `set xtics font ",8"`)
         if (.not. font_spec(self, toks, i, tics%font, iostat, iomsg)) then
            iomsg = 'set '//option//': '//iomsg
            return
         endif
      elseif (toks(i)%text == 'offset') then
         if (.not. next_real(toks, i, v(1), iostat, iomsg, self%symbols)) then
            iomsg = 'set '//option//': offset: '//iomsg
            return
         endif
         v(2) = 0.0_R8P
         if (i < size(toks, kind=I4P)) then
            if (toks(i + 1_I4P)%kind == TOKEN_COMMA) then
               i = i + 1_I4P
               if (.not. next_real(toks, i, v(2), iostat, iomsg, self%symbols)) then
                  iomsg = 'set '//option//': offset: '//iomsg
                  return
               endif
            endif
         endif
         tics%offset = v
      elseif (toks(i)%text == 'nooffset') then
         tics%offset = 0.0_R8P
      elseif (toks(i)%text == 'tc' .or. keyword(toks(i)%text, 'textcolor', 5_I4P)) then
         ! a line color, or `lt N` (linetype N's color, `set ytics tc lt 1`)
         block
            character(len=len(tics%color)) :: color !< Color read.

            color = tics%color
            if (.not. self%text_color(toks, i, color, iostat, iomsg)) then
               iomsg = 'set '//option//': textcolor: '//iomsg
               return
            endif
            tics%color = color
         endblock
      else
         handled = .false.
      endif
      endfunction label_option

      subroutine tics_option(tics, words)
      !< `set xtics|ytics|y2tics|cbtics [add] [auto|autofreq|STEP|START,STEP|START,STEP,END|("label" pos level, ...)]
      !< [mirror|nomirror] [in|out] [rotate [by ANGLE]|norotate] [left|right|center]`: without positions the last ones
      !< are kept, turning off ticks on (gnuplot); `auto` resets them. `out` (x, y, y2) points the ticks outward; `rotate`
      !< (x only) turns the labels, by 90 degrees right-justified, `rotate by ANGLE` left-justified unless justified.
      !< An explicit list replaces the ticks, with `add` it extends them (and an earlier list); positions without `add`
      !< forget an earlier list. `words` (the tics keyword and its arguments) replaces the option tokens.
      type(tics_object),  intent(inout)        :: tics     !< Axis tick settings.
      type(token_object), intent(in), optional :: words(:) !< Option tokens, if not the command ones.
      type(token_object), allocatable  :: args(:) !< Position tokens, mirror words removed.
      type(token_object), allocatable  :: toks(:) !< Option tokens.
      type(tic_item), allocatable      :: items(:) !< Explicit list items.
      character(len=:), allocatable    :: message !< Problem.
      character(len=:), allocatable    :: list    !< Explicit list, `(...)`, empty if none.
      logical                          :: ok      !< Well formed.
      logical                          :: add     !< `add`: extend the ticks.
      character(len=6)                 :: justify !< Justification given, blank if none.
      real(R8P)                        :: angle   !< Rotation angle [deg].
      logical, allocatable             :: mirror  !< Mirror setting, unallocated if not given.
      character(len=:), allocatable    :: fmt     !< `format "..."`, unallocated if not given.
      integer(I4P)                     :: n       !< Position tokens.
      integer(I4P)                     :: k       !< Position counter.
      real(R8P)                        :: v       !< Position value.
      integer(I4P)                     :: additive !< `nologscale` 1, `logscale` 0, neither -1.

      additive = -1_I4P
      if (present(words)) then
         toks = words
      else
         toks = tokens
      endif
      allocate(args(0))
      add = .false.
      list = ''
      justify = ''
      i = 2_I4P
      do while (i <= size(toks, kind=I4P))
         if (toks(i)%kind == TOKEN_WORD .and. any(toks(i)%text == ['in      ', 'out     ', 'rotate  ', 'norotate'])) then
            if (.not. (keyword(option, 'xtics', 3_I4P) .or. keyword(option, 'x2tics', 4_I4P) .or. &
                       keyword(option, 'rtics', 3_I4P)) .and. &
                (toks(i)%text == 'rotate' .or. toks(i)%text == 'norotate')) then
               call fail('set '//option//': rotate is supported on xtics, x2tics and rtics only', iostat, iomsg)
               return
            endif
            if (.not. any([keyword(option, 'xtics', 3_I4P), keyword(option, 'ytics', 3_I4P), keyword(option, 'y2tics', 4_I4P), &
                           keyword(option, 'x2tics', 4_I4P)]) &
                .and. (toks(i)%text == 'in' .or. toks(i)%text == 'out')) then
               call fail('set '//option//': in and out are supported on xtics, ytics, y2tics and x2tics only', iostat, &
                         iomsg)
               return
            endif
            select case (toks(i)%text)
            case ('in')
               tics%out = .false.
            case ('out')
               tics%out = .true.
            case ('norotate')
               tics%rotate = 0.0_R8P
               tics%justify = ''
            case default
               ! rotate: 90 degrees, right-justified below the plot, from the tick above it; rotate by ANGLE:
               ! left-justified (gnuplot)
               tics%rotate = 90.0_R8P
               tics%justify = trim(merge('     ', 'right', keyword(option, 'x2tics', 4_I4P)))
               if (i < size(toks, kind=I4P)) then
                  if (toks(i + 1_I4P)%text == 'by') then
                     if (i + 2_I4P > size(toks, kind=I4P)) then
                        call fail('set '//option//': rotate by needs an angle', iostat, iomsg)
                        return
                     endif
                     if (.not. to_number(toks(i + 2_I4P)%text, angle)) then
                        call fail('set '//option//': rotate by needs an angle, not "'//toks(i + 2_I4P)%text//'"', &
                                  iostat, iomsg)
                        return
                     endif
                     tics%rotate = angle
                     tics%justify = ''
                     i = i + 2_I4P
                  endif
               endif
            endselect
         elseif (toks(i)%kind == TOKEN_WORD .and. any(toks(i)%text == ['left  ', 'right ', 'center'])) then
            justify = toks(i)%text
         elseif (toks(i)%kind == TOKEN_WORD .and. keyword(toks(i)%text, 'scale', 2_I4P)) then
            if (.not. scale_values(toks, i, tics%scale)) return
         elseif (toks(i)%kind == TOKEN_WORD .and. keyword(toks(i)%text, 'mirror', 3_I4P)) then
            mirror = .true.
         elseif (toks(i)%kind == TOKEN_WORD .and. keyword(toks(i)%text, 'nomirror', 4_I4P)) then
            mirror = .false.
         elseif (toks(i)%kind == TOKEN_WORD .and. (keyword(toks(i)%text, 'timedate', 4_I4P) .or. &
                                                  toks(i)%text == 'numeric')) then
            ! gnuplot `set xtics time|timedate|numeric`: the axis ticked and labelled in time units, or not (as `set
            ! format x ... timedate`)
            block
               character(len=:), allocatable :: axis !< Axis name.

               axis = ''
               if (keyword(option, 'xtics', 3_I4P)) axis = 'x'
               if (keyword(option, 'ytics', 3_I4P)) axis = 'y'
               if (keyword(option, 'y2tics', 4_I4P)) axis = 'y2'
               if (keyword(option, 'x2tics', 4_I4P)) axis = 'x2'
               if (len(axis) == 0) then
                  call fail('set '//option//': time and numeric apply to x, y, x2 and y2', iostat, iomsg)
                  return
               endif
               call self%figure%set_time_axes(axis, on=toks(i)%text /= 'numeric')
            endblock
         elseif (toks(i)%kind == TOKEN_WORD .and. keyword(toks(i)%text, 'logscale', 3_I4P)) then
            ! gnuplot's logscale tic series: the step a factor on a log axis (the default)
            additive = 0_I4P
         elseif (toks(i)%kind == TOKEN_WORD .and. keyword(toks(i)%text, 'nologscale', 5_I4P)) then
            ! an additive step on a log axis
            additive = 1_I4P
         elseif (toks(i)%kind == TOKEN_WORD .and. toks(i)%text == 'add') then
            add = .true.
         elseif (toks(i)%kind == TOKEN_WORD .and. is_word(toks(i)%text, 'noenhanced enhanced')) then
            ! the labels as they are, or as enhanced text
            tics%plain = toks(i)%text == 'noenhanced'
         elseif (label_option(toks, i, tics, fmt)) then
            if (iostat /= 0_I4P) return
         elseif (toks(i)%kind == TOKEN_WORD .and. is_word(toks(i)%text, 'axis border')) then
            ! on the zero axis of the other coordinate, or on the border
            tics%on_axis = toks(i)%text == 'axis'
         elseif (toks(i)%kind == TOKEN_WORD .and. (keyword(toks(i)%text, 'rangelimited', 10_I4P) .or. &
                                                   keyword(toks(i)%text, 'norangelimited', 12_I4P))) then
            ! the ticks (and the border side) within the data range; gnuplot's rangelimit$ed
            tics%rangelimited = toks(i)%text(1:2) /= 'no'
         elseif (toks(i)%kind == TOKEN_WORD .and. toks(i)%text(1:min(1, len(toks(i)%text))) == '(') then
            if (len(list) > 0) then
               call fail('set '//option//': one list of ticks is expected', iostat, iomsg)
               return
            endif
            list = toks(i)%text
         else
            call push(args, toks(i))
         endif
         i = i + 1_I4P
      enddo
      if (allocated(fmt)) then
         ! `format ""`: no labels, as gnuplot (a blank one each)
         if (len(fmt) == 0) fmt = ' '
         tics%format = fmt
      endif
      if (len_trim(justify) > 0) then
         ! the justification of the labels: of the rotated ones (gnuplot also moves the unrotated ones: read and
         ! kept for a rotation)
         tics%justify = justify
      endif
      n = size(args, kind=I4P)
      if (len(list) > 0) then
         if (n > 0_I4P) then
            call fail('set '//option//': a list of ticks with positions is not supported (set them apart, with add)', &
                      iostat, iomsg)
            return
         endif
         call list_items(list, items)
         if (iostat /= 0_I4P) return
         call tics%set_list(items, add)
         if (allocated(mirror)) tics%mirror = mirror
         return
      endif
      if (additive >= 0_I4P) tics%additive = additive == 1_I4P
      if (n == 0_I4P) then
         if (allocated(mirror)) tics%mirror = mirror
         call tics%enable
         return
      endif
      ! an expression written with blanks is several words: one argument (`set ytics 0, ymax / 10.0, ymax`)
      block
         type(token_object), allocatable :: merged(:) !< Arguments, the words between commas joined.
         character(len=:), allocatable   :: joined    !< Words joined.
         integer(I4P)                    :: a         !< Argument counter.

         allocate(merged(0))
         do a = 1_I4P, n
            if (size(merged) > 0 .and. args(a)%kind == TOKEN_WORD) then
               if (merged(size(merged))%kind == TOKEN_WORD) then
                  ! through a temporary: nvfortran 26.9 corrupts `c%text = c%text//...` (its bug 1)
                  joined = merged(size(merged))%text//' '//args(a)%text
                  merged(size(merged))%text = joined
                  cycle
               endif
            endif
            call push(merged, args(a))
         enddo
         args = merged
         n = size(args, kind=I4P)
      endblock
      ok = mod(n, 2_I4P) == 1_I4P .and. n <= 5_I4P
      if (ok) ok = all(args(1:n:2)%kind == TOKEN_WORD .or. args(1:n:2)%kind == TOKEN_STRING)
      if (ok .and. n > 1_I4P) ok = all(args(2:n:2)%kind == TOKEN_COMMA)
      if (.not. ok) then
         call fail('set '//option//': supported forms are STEP, START,STEP, START,STEP,END and auto, with mirror or '// &
                   'nomirror', iostat, iomsg)
         return
      endif
      message = ''
      ! expressions (`7200*3`) and times (`"2024-03-01"`, read with the timefmt) as decimal texts
      do k = 1_I4P, n, 2_I4P
         if (k == 1_I4P .and. n == 1_I4P .and. keyword(args(1)%text, 'autofreq', 4_I4P)) exit
         if (args(k)%kind == TOKEN_STRING) args(k)%text = '"'//args(k)%text//'"'
         if (.not. to_number(args(k)%text, v)) then
            call self%range_value(args(k)%text, v, iostat, iomsg)
            if (iostat /= 0_I4P) then
               iomsg = 'set '//option//': '//iomsg
               return
            endif
            block
               integer(I8P) :: dn !< Mantissa.
               integer(I4P) :: de !< Exponent.

               call decimal_of(v, dn, de)
               ! a computed value to 12 significant digits: start, step and end then share one exact scale (mantissas
               ! below 1e15) even a decade or more apart (`set ytics 0, ymax / 10.0, ymax`)
               do while (abs(dn) >= 1000000000000_I8P)
                  dn = (dn + sign(5_I8P, dn)) / 10_I8P
                  de = de + 1_I4P
               enddo
               args(k)%text = decimal_str(dn, -de)
            endblock
         endif
      enddo
      ! positions without add forget an explicit list, as gnuplot
      if (.not. add) call tics%clear_list
      select case (n)
      case (1_I4P)
         if (keyword(args(1)%text, 'autofreq', 4_I4P)) then
            call tics%set_auto
         else
            call tics%set_fixed(args(1)%text, '', '', message)
         endif
      case (3_I4P)
         call tics%set_fixed(args(3)%text, args(1)%text, '', message)
      case default
         call tics%set_fixed(args(3)%text, args(1)%text, args(5)%text, message)
      endselect
      if (len(message) > 0) then
         call fail('set '//option//': '//message, iostat, iomsg)
         return
      endif
      if (allocated(mirror)) tics%mirror = mirror
      endsubroutine tics_option

      subroutine minor_option(tics)
      !< `set mxtics|mytics|my2tics|mcbtics [N|default|time N UNITS]`: N intervals between consecutive major ticks,
      !< gnuplot's automatic count without N; `default` restores the minor ticks by default (none, 2..9 on log axes);
      !< `time N UNITS` a minor tick every N time units (time axes).
      type(tics_object), intent(inout) :: tics !< Axis tick settings.
      integer(I4P)                     :: n    !< Intervals.
      integer(I4P)                     :: ios  !< Read status.

      tics%minor_count = 0_I4P
      tics%minor_unit = ''
      if (size(tokens) == 1) then
         tics%minor = MINOR_AUTO
         return
      endif
      if (tokens(2)%text == 'time') then
         ! `time N UNITS`: a minor tick every N units of a time axis (gnuplot 6.0)
         block
            character(len=:), allocatable :: unit !< Unit, plural.

            if (size(tokens) == 4) then
               if (verify(tokens(3)%text, '0123456789') == 0 .and. len(tokens(3)%text) <= 6) then
                  read(tokens(3)%text, *, iostat=ios) n
                  ! gnuplot's abbreviations: sec, min, hour, day, week, mon, year
                  unit = ''
                  if (len(tokens(4)%text) >= 3) then
                     select case (tokens(4)%text(1:3))
                     case ('sec')
                        unit = 'seconds'
                     case ('min')
                        unit = 'minutes'
                     case ('hou')
                        unit = 'hours'
                     case ('day')
                        unit = 'days'
                     case ('wee')
                        unit = 'weeks'
                     case ('mon')
                        unit = 'months'
                     case ('yea')
                        unit = 'years'
                     endselect
                  endif
                  if (ios == 0_I4P .and. n >= 1_I4P .and. is_word(unit, 'seconds minutes hours days weeks months years')) &
                     then
                     tics%minor = MINOR_NONE
                     tics%minor_count = n
                     tics%minor_unit = unit
                     return
                  endif
               endif
            endif
            call fail('set '//option//': time N seconds|minutes|hours|days|weeks|months|years is expected', iostat, &
                      iomsg)
            return
         endblock
      endif
      if (size(tokens) == 2 .and. tokens(2)%kind == TOKEN_WORD) then
         if (keyword(tokens(2)%text, 'default', 3_I4P)) then
            tics%minor = MINOR_DEFAULT
            return
         elseif (verify(tokens(2)%text, '0123456789') == 0 .and. len(tokens(2)%text) <= 6) then
            read(tokens(2)%text, *, iostat=ios) n
            if (ios == 0_I4P .and. n >= 1_I4P) then
               tics%minor = n
               return
            endif
         endif
      endif
      call fail('set '//option//': a number of intervals (a whole number from 1) or default is expected', iostat, iomsg)
      endsubroutine minor_option

      subroutine list_items(text, items)
      !< The items of the explicit tick list `text`, `({"label"} pos {level}, ...)`, comma separated (a trailing comma is
      !< allowed): the position a constant expression, the level 1 for a minor tick (others are major), as gnuplot.
      character(len=*),            intent(in)  :: text     !< List, parentheses included.
      type(tic_item), allocatable, intent(out) :: items(:) !< Items.
      type(tic_item)                           :: item     !< Current item.
      character(len=:), allocatable            :: body     !< List without its parentheses.
      character(len=:), allocatable            :: entry    !< Current item text.
      character(len=:), allocatable            :: rest     !< Item text after the label.
      character(len=1)                         :: quote    !< Open quote, blank if none.
      integer(I4P)                             :: depth    !< Parenthesis depth.
      integer(I4P)                             :: start    !< Item start.
      integer(I4P)                             :: k        !< Character counter.
      integer(I4P)                             :: close    !< Closing quote of the label.

      allocate(items(0))
      if (text(len(text):len(text)) /= ')') then
         call fail('set '//option//': the list of ticks "'//text//'" is not closed', iostat, iomsg)
         return
      endif
      body = text(2:len(text) - 1)
      ! `()`: an empty list, no ticks (gnuplot's `set xtics ()`)
      if (len_trim(body) == 0) return
      quote = ' '
      depth = 0_I4P
      start = 1_I4P
      do k = 1_I4P, len(body, kind=I4P) + 1_I4P
         if (k <= len(body, kind=I4P)) then
            if (quote /= ' ') then
               if (body(k:k) == quote) quote = ' '
               cycle
            elseif (body(k:k) == '"' .or. body(k:k) == "'") then
               quote = body(k:k)
               cycle
            elseif (body(k:k) == '(') then
               depth = depth + 1_I4P
               cycle
            elseif (body(k:k) == ')') then
               depth = depth - 1_I4P
               cycle
            elseif (body(k:k) /= ',' .or. depth > 0_I4P) then
               cycle
            endif
         endif
         entry = trim(adjustl(body(start:k - 1_I4P)))
         start = k + 1_I4P
         if (len(entry) == 0) then
            ! a trailing comma, as gnuplot; an empty item elsewhere is an error
            if (k > len(body, kind=I4P) .and. size(items) > 0) exit
            call fail('set '//option//': empty item in the list of ticks "'//text//'"', iostat, iomsg)
            return
         endif
         item%labelled = entry(1:1) == '"' .or. entry(1:1) == "'"
         item%label = ''
         rest = entry
         if (item%labelled) then
            close = index(entry(2:), entry(1:1), kind=I4P) + 1_I4P
            if (close == 1_I4P) then
               call fail('set '//option//': unclosed label in "'//entry//'"', iostat, iomsg)
               return
            endif
            item%label = entry(2:close - 1_I4P)
            rest = trim(adjustl(entry(close + 1_I4P:)))
         else
            ! a label as a string expression, gnuplot's (sprintf("%d", i) i): the first part ending an expression
            ! before a blank whose value is a string
            call expression_label(entry, item, rest)
            if (iostat /= 0_I4P) return
         endif
         call item_position(rest, item)
         if (iostat /= 0_I4P) return
         call push(items, item)
      enddo
      endsubroutine list_items

      subroutine expression_label(text, item, rest)
      !< The label of a list item `text` given by a string expression (`sprintf("%d", i) i`, a string variable): the
      !< first part of `text` ending an expression before a blank (no operator on either side) whose value is a string;
      !< `rest` the text after it, all of `text` when there is none.
      character(len=*),              intent(in)    :: text  !< Item text.
      type(tic_item),                intent(inout) :: item  !< Item.
      character(len=:), allocatable, intent(out)   :: rest  !< Position and level.
      character(len=*), parameter                  :: OPERATORS = '.+-*/%?:<>=!&|^~,' !< Operator characters.
      type(value_object)                           :: v     !< Value of a part.
      character(len=:), allocatable                :: msg   !< Error of a part.
      character(len=1)                             :: quote !< Open quote, blank if none.
      integer(I4P)                                 :: depth !< Bracket depth.
      integer(I4P)                                 :: b     !< Character counter.
      integer(I4P)                                 :: after !< First non-blank after a blank.
      integer(I4P)                                 :: status !< Status of a part.

      rest = text
      quote = ' '
      depth = 0_I4P
      do b = 1_I4P, len(text, kind=I4P)
         if (quote /= ' ') then
            if (text(b:b) == quote) quote = ' '
            cycle
         endif
         select case (text(b:b))
         case ('"', "'")
            quote = text(b:b)
         case ('(', '[', '{')
            depth = depth + 1_I4P
         case (')', ']', '}')
            depth = depth - 1_I4P
         case (' ')
            if (depth /= 0_I4P .or. b == 1_I4P) cycle
            if (text(b - 1_I4P:b - 1_I4P) == ' ' .or. scan(text(b - 1_I4P:b - 1_I4P), OPERATORS) > 0) cycle
            after = verify(text(b:), ' ', kind=I4P)
            if (after == 0_I4P) exit
            after = b + after - 1_I4P
            if (scan(text(after:after), OPERATORS) > 0) cycle
            call self%symbols%evaluate_constant(text(1:b - 1_I4P), v, status, msg, &
                                                degrees=self%figure%panels(self%figure%current)%degrees)
            if (status == 0_I4P .and. v%is_string) then
               item%labelled = .true.
               item%label = v%s
               rest = trim(adjustl(text(after:)))
               return
            endif
         endselect
      enddo
      endsubroutine expression_label

      subroutine item_position(text, item)
      !< Position and level of a list item from `text`, `pos {level}`: the whole text is the position if it is a valid
      !< expression, else its last word is the level.
      character(len=*), intent(in)    :: text  !< Position and level.
      type(tic_item),   intent(inout) :: item  !< Item.
      character(len=:), allocatable   :: first !< Message of the whole text as a position.
      real(R8P)                       :: v     !< Value.
      integer(I4P)                    :: blank !< Last blank.
      integer(I4P)                    :: level !< Level.
      integer(I4P)                    :: ios   !< Read status.

      if (len(text) == 0) then
         call fail('set '//option//': a list item needs a position', iostat, iomsg)
         return
      endif
      item%major = .true.
      call self%symbols%constant(text, v, iostat, iomsg, degrees=self%figure%panels(self%figure%current)%degrees)
      if (iostat == 0_I4P) then
         item%value = v
         return
      endif
      first = iomsg
      blank = index(text, ' ', back=.true., kind=I4P)
      if (blank > 0_I4P) then
         read(text(blank + 1_I4P:), *, iostat=ios) level
         if (ios == 0_I4P .and. verify(text(blank + 1_I4P:), '0123456789') == 0) then
            call self%symbols%constant(trim(text(1:blank - 1_I4P)), v, iostat, iomsg, &
                                       degrees=self%figure%panels(self%figure%current)%degrees)
            if (iostat == 0_I4P) then
               item%value = v
               item%major = level /= 1_I4P
               return
            endif
         endif
      endif
      iostat = 1_I4P
      iomsg = 'set '//option//': list item "'//text//'": '//first
      endsubroutine item_position

      subroutine datafile_option
      !< `set datafile separator [whitespace|tab|comma|"chars"]` (no argument restores whitespace), `set datafile
      !< missing ["string"|NaN]` (a point reading that cell is left out, the line not broken; none without argument),
      !< `set datafile commentschars ["chars"]` (`#` without argument), as gnuplot.
      if (size(tokens) < 2) then
         call fail('set datafile: separator, missing or commentschars is expected', iostat, iomsg)
         return
      endif
      if (tokens(2)%kind == TOKEN_WORD .and. keyword(tokens(2)%text, 'missing', 3_I4P)) then
         if (size(tokens) > 3) then
            call fail('set datafile missing: one "string" (or NaN) is expected', iostat, iomsg)
         elseif (size(tokens) == 2) then
            self%missing = ''
         elseif (tokens(3)%kind == TOKEN_STRING .or. tokens(3)%text == 'NaN') then
            self%missing = trim(adjustl(tokens(3)%text))
         else
            call fail('set datafile missing: a "string" (or NaN) is expected, found "'//tokens(3)%text//'"', iostat, &
                      iomsg)
         endif
         return
      endif
      if (tokens(2)%kind == TOKEN_WORD .and. keyword(tokens(2)%text, 'commentschars', 3_I4P)) then
         if (size(tokens) > 3) then
            call fail('set datafile commentschars: one "string" of characters is expected', iostat, iomsg)
         elseif (size(tokens) == 2) then
            self%comments = '#'
         elseif (tokens(3)%kind == TOKEN_STRING) then
            self%comments = tokens(3)%text
         else
            call fail('set datafile commentschars: a "string" of characters is expected, found "'//tokens(3)%text// &
                      '"', iostat, iomsg)
         endif
         return
      endif
      if (.not. keyword(tokens(2)%text, 'separator', 3_I4P) .or. tokens(2)%kind /= TOKEN_WORD) then
         call fail('set datafile: unsupported option "'//tokens(2)%text//'" (separator, missing and commentschars '// &
                   'are)', iostat, iomsg)
         return
      endif
      if (size(tokens) > 3) then
         call fail('set datafile separator: one of whitespace, tab, comma or "characters" is expected', iostat, iomsg)
         return
      endif
      if (size(tokens) == 2) then
         self%separator = ''
      elseif (tokens(3)%kind == TOKEN_STRING .and. tokens(3)%quote == "'" .and. tokens(3)%text == '\t') then
         ! gnuplot takes the single-quoted '\t' (no escapes there) as the tab too
         self%separator = achar(9)
      elseif (tokens(3)%kind == TOKEN_STRING) then
         ! "" is whitespace, as no argument
         self%separator = tokens(3)%text
      elseif (keyword(tokens(3)%text, 'whitespace', 5_I4P)) then
         self%separator = ''
      elseif (tokens(3)%text == 'tab') then
         self%separator = achar(9)
      elseif (tokens(3)%text == 'comma') then
         self%separator = ','
      else
         call fail('set datafile separator: one of whitespace, tab, comma or "characters" is expected, found "'// &
                   tokens(3)%text//'"', iostat, iomsg)
      endif
      endsubroutine datafile_option

      subroutine samples_option(store)
      !< `set samples N[,M]` (`store`) and `set isosamples N[,M]`: N function samples, M (for surfaces) checked and
      !< ignored; N and M expressions truncated to integers, as gnuplot's.
      logical, intent(in) :: store !< `set samples`, else checked only.
      integer(I4P)        :: n     !< Samples.
      integer(I4P)        :: m     !< Second sampling rate.

      i = 2_I4P
      if (.not. integer_expression(n)) return
      m = n
      if (size(tokens, kind=I4P) > i) then
         i = i + 1_I4P
         if (tokens(i)%kind /= TOKEN_COMMA) then
            call fail('set '//option//': N or N,M expected', iostat, iomsg)
            return
         endif
         i = i + 1_I4P
         if (.not. integer_expression(m)) return
         if (.not. no_more(tokens, i + 1_I4P, iostat, iomsg)) return
      endif
      if (n < 2_I4P .or. m < 2_I4P) then
         call fail('set '//option//': the sampling rate must be > 1', iostat, iomsg)
         return
      endif
      if (store) then
         self%samples = n
         self%samples2 = m
      else
         self%isosamples1 = n
         self%isosamples = m
      endif
      endsubroutine samples_option

      function integer_expression(n) result(ok)
      !< The expression from token `i` (left on its last token) truncated to an integer, as gnuplot's int_expression.
      integer(I4P), intent(out) :: n  !< Value.
      logical                   :: ok !< Success.
      real(R8P)                 :: v  !< Value, real.

      n = 0_I4P
      ok = i <= size(tokens, kind=I4P)
      if (.not. ok) then
         call fail('set '//option//': a number is expected', iostat, iomsg)
         return
      endif
      last = expression_end(tokens, i)
      call self%symbols%constant(expression_source(tokens(i:last)), v, iostat, iomsg, &
                                 degrees=self%figure%panels(self%figure%current)%degrees)
      ok = iostat == 0_I4P
      if (.not. ok) then
         iomsg = 'set '//option//': '//iomsg
         return
      endif
      ok = abs(v) < 2.0e9_R8P
      if (.not. ok) then
         call fail('set '//option//': the sampling rate is too large', iostat, iomsg)
         return
      endif
      n = int(v, I4P)
      i = last
      endfunction integer_expression

      subroutine format_option
      !< `set format [x|y|y2|cb|x2|xy...] ["format"] [timedate|numeric]` (all axes by default): no format restores the
      !< default labels; a time format (`%H:%M`) labels time axes; `timedate` makes the axes time axes (ticks and
      !< labels, the data read as numbers), `numeric` numeric ones.
      character(len=:), allocatable :: axes    !< Axes letters.
      character(len=:), allocatable :: format  !< Label format.
      character(len=:), allocatable :: message !< Problem.
      character(len=:), allocatable :: kind    !< `timedate`, `numeric` or empty.
      logical                       :: zaxis   !< The z axis named (splot's): its format set apart.

      axes = 'xyy2cbx2'
      zaxis = .true.
      format = ''
      i = 2_I4P
      ! a lone word before the format names the axes
      if (i < size(tokens, kind=I4P)) then
         if (tokens(i)%kind == TOKEN_WORD .and. expression_end(tokens, i) == i) then
            axes = tokens(i)%text
            zaxis = index(axes, 'z') > 0
            if (zaxis) axes = axes(1:index(axes, 'z') - 1)//axes(index(axes, 'z') + 1:)
            if (len(axes) == 0 .and. zaxis) axes = 'z'
            if (axes == 'z' .and. tokens(i)%text /= 'z') axes = 'zz'
            if (axes == 'z') then
               continue
            elseif (.not. valid_axes(axes)) then
               call fail('set format: axes must be among x, y, y2, cb, x2 (e.g. y or xy2), not "'//axes//'"', iostat, iomsg)
               return
            endif
            i = i + 1_I4P
         endif
      elseif (i == size(tokens, kind=I4P)) then
         if (tokens(i)%kind == TOKEN_WORD .and. valid_axes(tokens(i)%text)) then
            axes = tokens(i)%text
            zaxis = .false.
            i = i + 1_I4P
         elseif (tokens(i)%kind == TOKEN_WORD .and. tokens(i)%text == 'z') then
            axes = 'z'
            i = i + 1_I4P
         endif
      endif
      if (i <= size(tokens, kind=I4P)) then
         ! a string expression: "%.1f", fmt, "%" . ".1f"
         if (.not. self%string_expression(tokens, i, format, iostat, iomsg)) then
            iomsg = 'set format: '//iomsg
            return
         endif
         kind = ''
         if (i + 1_I4P == size(tokens, kind=I4P)) then
            if (is_word(tokens(i + 1_I4P)%text, 'timedate numeric')) then
               kind = tokens(i + 1_I4P)%text
               i = i + 1_I4P
            endif
         endif
         if (i < size(tokens, kind=I4P)) then
            call fail('set format: unexpected "'//tokens(i + 1_I4P)%text//'" after the format', iostat, iomsg)
            return
         endif
         ! gnuplot's `set format x ""`: no labels (a blank one each); `set format x` alone restores the default
         if (len(format) == 0) format = ' '
         if (len(format) > 0) then
            ! a time format only for time axes (`%d` is a day there, not an integer)
            message = format_check(format)
            if (len(message) > 0 .and. (kind == 'timedate' .or. time_axes(axes))) then
               if (len(time_format_check(format)) == 0) message = ''
            endif
            if (len(message) > 0) then
               call fail('set format: '//message, iostat, iomsg)
               return
            endif
         endif
         if (len(kind) > 0) then
            if (axes == 'xyy2cbx2') axes = 'xyy2x2'
            if (index(axes, 'cb') > 0) then
               call fail('set format: the color axis is not a time axis', iostat, iomsg)
               return
            endif
            call self%figure%set_time_axes(axes, on=kind == 'timedate')
         endif
      endif
      if (zaxis) self%figure%panels(self%figure%current)%zaxis%tics%format = format
      if (axes /= 'z') call self%figure%set_format(format, axes)
      endsubroutine format_option

      function time_axes(names) result(time)
      !< Whether one of the axes `names` (`x`, `y`, `y2`, `x2` concatenated) is a time axis (`set xdata time`, `set
      !< format ... timedate`).
      character(len=*), intent(in)  :: names   !< Axes names.
      logical                       :: time    !< A time axis named.
      character(len=:), allocatable :: bad     !< Unknown name.
      logical                       :: named(5) !< x, y, y2, cb, x2 named.

      call axes_names(names, named(1), named(2), named(3), bad, cb=named(4), x2=named(5))
      associate(panel => self%figure%panels(self%figure%current))
         time = (named(1) .and. panel%xaxis%time) .or. (named(2) .and. panel%yaxis%time) .or. &
                (named(3) .and. panel%y2axis%time) .or. (named(5) .and. panel%x2axis%time)
      endassociate
      endfunction time_axes

      subroutine style_option
      !< `set style data|function STYLE [filledcurves options]`, `set style line N [lc ...] [lt N] [lw W] [dt N] [ps S]`.
      type(line_style_object) :: style !< New line style.
      character(len=:), allocatable :: with !< Style name.
      character(len=:), allocatable :: curve_text !< Filledcurves options of `set style data|function`.
      integer(I4P) :: s !< Counter.

      if (size(tokens) >= 2) then
         if (keyword(tokens(2)%text, 'arrow', 3_I4P) .or. keyword(tokens(2)%text, 'rectangle', 4_I4P)) then
            ! the words of set arrow or set object: the style kept, not drawn
            block
               type(token_object), allocatable :: words(:) !< `arrowstyle|rectanglestyle` and the words.

               words = tokens(2:)
               words(1)%text = merge('arrowstyle    ', 'rectanglestyle', keyword(tokens(2)%text, 'arrow', 3_I4P))
               words(1)%text = trim(words(1)%text)
               call self%annotation_option(words, iostat, iomsg)
            endblock
            return
         elseif (keyword(tokens(2)%text, 'data', 1_I4P)) then
            if (size(tokens) < 3) then
               call fail('set style data: one style is expected', iostat, iomsg)
               return
            endif
            with = canonical_style(tokens(3)%text)
            if (len(with) == 0) then
               call fail('set style data: unsupported style "'//tokens(3)%text//'"', iostat, iomsg)
               return
            endif
            if (.not. style_curve('data', with, curve_text)) return
            self%data_style = with
            self%data_curve = curve_text
            return
         elseif (keyword(tokens(2)%text, 'spiderplot', 6_I4P)) then
            block
               type(style_object)            :: probe !< Style the words are tried on.
               character(len=:), allocatable :: words !< Option words.
               character(len=:), allocatable :: bad   !< Problem.

               words = ''
               do s = 3_I4P, size(tokens, kind=I4P)
                  if (tokens(s)%kind == TOKEN_STRING) then
                     words = words//' "'//tokens(s)%text//'"'
                  else
                     words = words//' '//tokens(s)%text
                  endif
               enddo
               associate(panel => self%figure%panels(self%figure%current))
                  probe = panel%spider_style
               endassociate
               call spider_words(words, probe, bad)
               if (len(bad) > 0) then
                  call fail('set style spiderplot: '//bad, iostat, iomsg)
                  return
               endif
               call self%figure%set_style_spiderplot(words)
            endblock
            return
         elseif (tokens(2)%text == 'boxplot') then
            block
               type(boxplot_style)           :: probe !< Style the words are tried on.
               character(len=:), allocatable :: words !< Option words.
               character(len=:), allocatable :: bad   !< Problem.

               words = ''
               do s = 3_I4P, size(tokens, kind=I4P)
                  words = words//' '//tokens(s)%text
               enddo
               associate(panel => self%figure%panels(self%figure%current))
                  probe = panel%boxplot
               endassociate
               call boxplot_words(words, probe, bad)
               if (len(bad) > 0) then
                  call fail('set style boxplot: '//bad, iostat, iomsg)
                  return
               endif
               call self%figure%set_style_boxplot(words)
            endblock
            return
         elseif (keyword(tokens(2)%text, 'histogram', 4_I4P)) then
            block
               character(len=13)      :: mode  !< Layout.
               real(R8P), allocatable :: gap   !< Cluster gap.
               real(R8P), allocatable :: width !< Error bar width.
               real(R8P)              :: v     !< Number.

               mode = 'clustered'
               s = 3_I4P
               do while (s <= size(tokens, kind=I4P))
                  if (keyword(tokens(s)%text, 'clustered', 7_I4P)) then
                     mode = 'clustered'
                  elseif (keyword(tokens(s)%text, 'rowstacked', 4_I4P)) then
                     mode = 'rowstacked'
                  elseif (keyword(tokens(s)%text, 'columnstacked', 7_I4P)) then
                     mode = 'columnstacked'
                  elseif (keyword(tokens(s)%text, 'errorbars', 5_I4P)) then
                     mode = 'errorbars'
                  elseif (is_word(tokens(s)%text, 'keyseparators nokeyseparators')) then
                     ! foresight draws no blank key row between the groups: nokeyseparators is its look
                     continue
                  elseif (tokens(s)%text == 'title') then
                     call histogram_title(s)
                     if (iostat /= 0_I4P) return
                  elseif (tokens(s)%text == 'gap' .or. is_word(tokens(s)%text, 'lw linewidth')) then
                     s = s + 1_I4P
                     if (s > size(tokens, kind=I4P)) then
                        call fail('set style histogram: '//tokens(s - 1_I4P)%text//' needs a number', iostat, iomsg)
                        return
                     endif
                     if (.not. to_number(tokens(s)%text, v)) then
                        call fail('set style histogram: '//tokens(s - 1_I4P)%text//' needs a number', iostat, iomsg)
                        return
                     endif
                     if (tokens(s - 1_I4P)%text == 'gap') then
                        if (v < 0.0_R8P) then
                           call fail('set style histogram: the gap must not be negative', iostat, iomsg)
                           return
                        endif
                        gap = v
                     else
                        if (.not. (v > 0.0_R8P)) then
                           call fail('set style histogram: the line width must be positive', iostat, iomsg)
                           return
                        endif
                        width = v
                     endif
                  else
                     call fail('set style histogram: unsupported option "'//tokens(s)%text//'" (clustered [gap G], '// &
                               'errorbars [gap G] [lw W], rowstacked, columnstacked, title [tc C] [offset X,Y] '// &
                               '[font F], [no]keyseparators are supported)', iostat, iomsg)
                     return
                  endif
                  s = s + 1_I4P
               enddo
               if (allocated(width) .and. trim(mode) /= 'errorbars') then
                  call fail('set style histogram: lw applies to errorbars', iostat, iomsg)
                  return
               endif
               call self%figure%set_style_histogram(trim(mode), gap, width)
            endblock
            return
         elseif (keyword(tokens(2)%text, 'fill', 2_I4P)) then
            block
               type(style_object)            :: probe !< Style the words are tried on.
               character(len=:), allocatable :: words !< Fill style words.
               character(len=:), allocatable :: bad   !< Unknown word.

               words = ''
               do s = 3_I4P, size(tokens, kind=I4P)
                  words = words//' '//tokens(s)%text
               enddo
               call fill_style(words, probe, bad)
               if (len(bad) > 0) then
                  call fail('set style fill: unsupported option "'//bad//'"', iostat, iomsg)
                  return
               endif
               call self%figure%set_style_fill(words)
            endblock
            return
         elseif (keyword(tokens(2)%text, 'function', 1_I4P)) then
            if (size(tokens) < 3) then
               call fail('set style function: one style is expected', iostat, iomsg)
               return
            endif
            with = canonical_style(tokens(3)%text)
            if (len(with) == 0) then
               call fail('set style function: unsupported style "'//tokens(3)%text//'"', iostat, iomsg)
               return
            endif
            if (.not. function_drawable(with)) then
               call fail('set style function: '//with//' is not usable for function plots ('//FUNCTION_STYLES// &
                         ' are)', iostat, iomsg)
               return
            endif
            if (.not. style_curve('function', with, curve_text)) return
            self%function_style = with
            self%function_curve = curve_text
            return
         elseif (keyword(tokens(2)%text, 'line', 1_I4P)) then
            i = 2_I4P
            if (.not. next_integer(tokens, i, style%id, iostat, iomsg)) return
            if (style%id < 1_I4P) then
               call fail('set style line: the style number must be positive', iostat, iomsg)
               return
            endif
            i = i + 1_I4P
            do while (i <= size(tokens, kind=I4P))
               if (.not. is_line_option(tokens(i)%text)) then
                  call fail('set style line: unsupported option "'//tokens(i)%text//'"', iostat, iomsg)
                  return
               endif
               if (.not. line_option(tokens, i, style, iostat, iomsg, &
                                     self%figure%panels(self%figure%current)%linecolors)) then
                  iomsg = 'set style line: '//iomsg
                  return
               endif
               i = i + 1_I4P
            enddo
            do s = 1_I4P, size(self%line_styles, kind=I4P)
               if (self%line_styles(s)%id == style%id) then
                  self%line_styles(s) = style
                  return
               endif
            enddo
            call push(self%line_styles, style)
            return
         endif
      endif
      if (size(tokens) >= 2) then
         if (keyword(tokens(2)%text, 'textbox', 4_I4P)) then
            ! `set style textbox [N] [opaque|transparent] [fc C] [border [lc C] [lw W]|noborder] [margins X,Y]
            ! [linewidth W]`: gnuplot's svg terminal draws the background of a boxed text when the style is opaque or
            ! has a border, without border nor margins (their values are read)
            block
               integer(I4P) :: n        !< Style number.
               logical      :: opaque   !< opaque given last.
               logical      :: noborder !< noborder given last.
               integer(I4P) :: k        !< Token counter.

               n = 0_I4P
               k = 3_I4P
               if (k <= size(tokens, kind=I4P)) then
                  if (verify(tokens(k)%text, '0123456789') == 0) then
                     read(tokens(k)%text, *) n
                     k = k + 1_I4P
                  endif
               endif
               if (n > 3_I4P) then
                  call fail('set style textbox: the styles are 0 to 3', iostat, iomsg)
                  return
               endif
               opaque = .false.
               noborder = .false.
               do while (k <= size(tokens, kind=I4P))
                  select case (tokens(k)%text)
                  case ('opaque')
                     opaque = .true.
                  case ('transparent')
                     opaque = .false.
                  case ('noborder')
                     noborder = .true.
                  case ('border')
                     noborder = .false.
                  case ('fc', 'fillcolor', 'lc', 'linecolor', 'lt', 'linetype', 'lw', 'linewidth', 'margins', 'margin')
                     ! a value follows (a color, a width, X,Y): read and not drawn by the svg
                     if (tokens(k)%text(1:min(6, len(tokens(k)%text))) == 'margin') then
                        k = k + 1_I4P
                        if (k < size(tokens, kind=I4P)) then
                           if (tokens(k + 1_I4P)%kind == TOKEN_COMMA) k = k + 2_I4P
                        endif
                     else
                        k = k + 1_I4P
                        if (k <= size(tokens, kind=I4P)) then
                           if (is_word(tokens(k)%text, 'rgb rgbcolor')) k = k + 1_I4P
                        endif
                     endif
                  case default
                     call fail('set style textbox: unsupported option "'//tokens(k)%text//'" (opaque, transparent, '// &
                               'fc, border, noborder, lc, lw, margins)', iostat, iomsg)
                     return
                  endselect
                  k = k + 1_I4P
               enddo
               self%textbox_drawn(n) = opaque .or. .not. noborder
            endblock
            return
         endif
      endif
      call fail('set style: only "data STYLE", "function STYLE", "line N ...", "fill ...", "histogram ..." and '// &
                '"textbox ..." are supported', iostat, iomsg)
      endsubroutine style_option

      function style_curve(kind, with, curve_text) result(ok)
      !< The options after the style `with` of `set style data|function` (`kind`): filledcurves' only (as gnuplot),
      !< checked and kept as `curve_text`.
      character(len=*),              intent(in)  :: kind       !< `data` or `function`.
      character(len=*),              intent(in)  :: with       !< Style.
      character(len=:), allocatable, intent(out) :: curve_text !< Options.
      logical                       :: ok    !< Success.
      character(len=:), allocatable :: curve !< Option words.
      character(len=:), allocatable :: bad   !< Problem.
      real(R8P),        allocatable :: base  !< Base line.
      integer(I4P)                  :: t     !< Token counter.

      ok = .false.
      curve_text = ''
      do t = 4_I4P, size(tokens, kind=I4P)
         if (tokens(t)%kind == TOKEN_COMMA) then
            curve_text = curve_text//','
         elseif (t > 4_I4P .and. tokens(t - 1_I4P)%kind == TOKEN_COMMA) then
            curve_text = curve_text//tokens(t)%text
         else
            curve_text = curve_text//' '//tokens(t)%text
         endif
      enddo
      curve_text = trim(adjustl(curve_text))
      if (len(curve_text) > 0 .and. with /= 'filledcurves') then
         call fail('set style '//kind//': options apply to filledcurves only, as gnuplot', iostat, iomsg)
         return
      endif
      call filled_options(curve_text, curve, base, bad)
      if (len(bad) > 0) then
         call fail('set style '//kind//': filledcurves '//bad, iostat, iomsg)
         return
      endif
      ok = .true.
      endfunction style_curve
   endsubroutine set_command

   subroutine unset_command(self, tokens, iostat, iomsg)
   !< `unset` options.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Option tokens.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   character(len=:), allocatable                :: option    !< Option word.
   character(len=:), allocatable                :: axes      !< Axes letters.
   logical                                      :: ok        !< Supported sub-option.

   iostat = 0_I4P
   iomsg = ''
   if (size(tokens) == 0) then
      call fail('unset: missing option', iostat, iomsg)
      return
   endif
   option = tokens(1)%text
   if (option == 'paxis') then
      block
         real(R8P) :: v !< Axis number.

         ok = .false.
         if (size(tokens) == 3) then
            if (to_number(tokens(2)%text, v) .and. keyword(tokens(3)%text, 'tics', 3_I4P)) ok = v >= 1.0_R8P .and. &
                                                                                             v <= 1000.0_R8P .and. v == aint(v)
         endif
         if (.not. ok) then
            call fail('unset paxis: N tics expected', iostat, iomsg)
            return
         endif
         call self%figure%set_paxis(int(v, I4P), tics=.false.)
      endblock
      return
   elseif (keyword(option, 'logscale', 3_I4P) .and. size(tokens) == 2) then
      if (tokens(2)%text == 'r') then
         self%figure%panels(self%figure%current)%raxis%log = .false.
         return
      endif
      if (.not. axes_argument(tokens, axes, iostat, iomsg)) return
      call self%figure%unset_logscale(axes)
      return
   elseif (keyword(option, 'logscale', 3_I4P)) then
      if (size(tokens) >= 2) then
         if (index(tokens(2)%text, 'z') > 0) then
            self%figure%panels(self%figure%current)%zaxis%log = .false.
            if (len(tokens(2)%text) == 1) return
            block
               type(token_object), allocatable :: rest(:) !< The other axes.

               rest = tokens
               rest(2)%text = rest(2)%text(1:index(rest(2)%text, 'z') - 1)//rest(2)%text(index(rest(2)%text, 'z') + 1:)
               if (.not. axes_argument(rest, axes, iostat, iomsg)) return
            endblock
            call self%figure%unset_logscale(axes)
            return
         endif
      else
         self%figure%panels(self%figure%current)%zaxis%log = .false.
      endif
      if (.not. axes_argument(tokens, axes, iostat, iomsg)) return
      call self%figure%unset_logscale(axes)
      return
   elseif (keyword(option, 'pointsize', 3_I4P)) then
      self%figure%panels(self%figure%current)%point_scale = 1.0_R8P
      return
   elseif (keyword(option, 'timestamp', 5_I4P)) then
      self%figure%panels(self%figure%current)%stamp = .false.
      return
   elseif (keyword(option, 'parametric', 3_I4P)) then
      ! gnuplot's unset parametric: the dummy variables back to x and y
      if (self%parametric) then
         self%dummy = ''
         self%dummies = ''
      endif
      self%parametric = .false.
      return
   elseif (keyword(option, 'jitter', 3_I4P)) then
      self%figure%panels(self%figure%current)%jitter_spread = 0.0_R8P
      return
   elseif (keyword(option, 'clip', 2_I4P)) then
      ! gnuplot `unset clip [points|one|two|radial]`: bare, points, one and two
      if (.not. clip_words(self%figure%panels(self%figure%current), tokens, .false., iostat, iomsg)) return
      return
   elseif (option == 'offset' .or. option == 'offsets') then
      self%figure%panels(self%figure%current)%xaxis%offset = 0.0_R8P
      self%figure%panels(self%figure%current)%yaxis%offset = 0.0_R8P
      return
   elseif (keyword(option, 'style', 2_I4P)) then
      ok = .false.
      if (size(tokens) == 2) ok = keyword(tokens(2)%text, 'function', 1_I4P) .or. keyword(tokens(2)%text, 'arrow', 3_I4P) &
                                  .or. keyword(tokens(2)%text, 'fill', 2_I4P)
      if (.not. ok) then
         call fail('unset style: only "function", "arrow" and "fill" are supported', iostat, iomsg)
         return
      endif
      if (keyword(tokens(2)%text, 'fill', 2_I4P)) then
         ! gnuplot's default fill: empty, bordered
         self%figure%panels(self%figure%current)%fill_default = style_object()
      elseif (keyword(tokens(2)%text, 'arrow', 3_I4P)) then
         if (allocated(self%arrow_styles)) deallocate(self%arrow_styles)
         allocate(self%arrow_styles(0))
      else
         self%function_style = 'lines'
      endif
      return
   elseif (keyword(option, 'datafile', 5_I4P)) then
      ! all the datafile settings, or one of them
      if (size(tokens) > 1) then
         if (keyword(tokens(2)%text, 'separator', 3_I4P)) then
            self%separator = ''
         elseif (keyword(tokens(2)%text, 'missing', 3_I4P)) then
            self%missing = ''
         elseif (keyword(tokens(2)%text, 'commentschars', 3_I4P)) then
            self%comments = '#'
         elseif (keyword(tokens(2)%text, 'columnheaders', 7_I4P)) then
            self%column_headers = .false.
         else
            call fail('unset datafile: unsupported option "'//tokens(2)%text//'" (separator, missing, '// &
                      'commentschars and columnheaders are)', iostat, iomsg)
            return
         endif
         if (.not. no_more(tokens, 3_I4P, iostat, iomsg)) return
         return
      endif
      self%separator = ''
      self%missing = ''
      self%comments = '#'
      self%column_headers = .false.
      return
   endif
   ! labels, arrows, objects take a tag (handled below)
   if (.not. (keyword(option, 'label', 3_I4P) .or. keyword(option, 'arrow', 3_I4P) .or. &
              keyword(option, 'object', 3_I4P) .or. option == 'link' .or. keyword(option, 'nonlinear', 4_I4P) .or. &
              option == 'pixmap')) then
      ! `unset polar grid` (gnuplot's grid settings)
      if (keyword(option, 'polar', 3_I4P) .and. size(tokens) == 2) then
         if (tokens(2)%text /= 'grid') then
            if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
         endif
      elseif (.not. no_more(tokens, 2_I4P, iostat, iomsg)) then
         return
      endif
   endif
   if (keyword(option, 'multiplot', 5_I4P)) then
      if (self%multiplot .and. self%output == '-') then
         call self%save_output(iostat, iomsg)
         if (iostat /= 0_I4P) return
      endif
      call self%figure%unset_multiplot
      self%multiplot = .false.
      self%advance_pending = .false.
   elseif (keyword(option, 'title', 3_I4P)) then
      call self%figure%set_title('')
   elseif (keyword(option, 'xlabel', 2_I4P)) then
      call self%figure%set_xlabel('')
   elseif (keyword(option, 'ylabel', 2_I4P)) then
      call self%figure%set_ylabel('')
   elseif (keyword(option, 'y2label', 3_I4P)) then
      call self%figure%set_y2label('')
   elseif (keyword(option, 'x2label', 3_I4P)) then
      call self%figure%set_x2label('')
   elseif (keyword(option, 'rlabel', 3_I4P)) then
      self%figure%panels(self%figure%current)%raxis%label = ''
   elseif (option == 'isotropic') then
      call self%figure%set_size(ratio=0.0_R8P)
   elseif (keyword(option, 'grid', 2_I4P)) then
      call self%figure%set_grid(.false., polar=0.0_R8P)
   elseif (keyword(option, 'polar', 3_I4P)) then
      ! gnuplot: the angular clipping of the grid restored; `unset polar grid` the grid settings too
      self%polar_grid%tmin = 0.0_R8P
      self%polar_grid%tmax = 360.0_R8P
      if (size(tokens) >= 2) then
         if (tokens(2)%text == 'grid') self%polar_grid = polar_grid_type()
      endif
      ! gnuplot's unset polar clears the theta ticks too (unset_tics on its theta axis)
      call self%figure%set_ttics(on=.false.)
      call self%figure%set_polar(.false.)
   elseif (option == 'rgbmax') then
      self%rgbmax = 255.0_R8P
   elseif (keyword(option, 'spiderplot', 3_I4P)) then
      call self%figure%set_spiderplot(.false.)
      if (self%data_style == 'spiderplot') self%data_style = 'lines'
   elseif (option == 'link') then
      ! gnuplot `unset link [x2|y2]`: both, or the one named
      associate(panel => self%figure%panels(self%figure%current))
         if (size(tokens) < 2) then
            panel%link_x2 = .false.
            panel%link_y2 = .false.
         elseif (is_word(tokens(2)%text, 'x x2')) then
            panel%link_x2 = .false.
         elseif (is_word(tokens(2)%text, 'y y2')) then
            panel%link_y2 = .false.
         else
            call fail('unset link: x2 or y2 expected', iostat, iomsg)
            return
         endif
      endassociate
   elseif (keyword(option, 'output', 2_I4P)) then
      ! as a bare `set output`: back to the default output
      if (allocated(self%default_output)) self%output = self%default_output
      self%output_set = .false.
   elseif (keyword(option, 'nonlinear', 4_I4P)) then
      ! gnuplot `unset nonlinear [x|y]`
      associate(panel => self%figure%panels(self%figure%current))
         if (size(tokens) < 2) then
            panel%nonlinear_x = .false.
            panel%nonlinear_y = .false.
         elseif (tokens(2)%text == 'x') then
            panel%nonlinear_x = .false.
         elseif (tokens(2)%text == 'y') then
            panel%nonlinear_y = .false.
         else
            call fail('unset nonlinear: x or y expected (x2, y2, cb and r are not supported)', iostat, iomsg)
            return
         endif
      endassociate
   elseif (option == 'theta') then
      call self%figure%set_theta('right', .false.)
   elseif (keyword(option, 'raxis', 3_I4P)) then
      call self%figure%set_raxis(.false.)
   elseif (keyword(option, 'rtics', 3_I4P)) then
      call self%figure%set_rtics(on=.false.)
   elseif (keyword(option, 'ttics', 3_I4P)) then
      call self%figure%set_ttics(on=.false.)
   elseif (keyword(option, 'border', 3_I4P)) then
      call self%figure%set_border(0_I4P, .false.)
   elseif (keyword(option, 'key', 1_I4P)) then
      call self%figure%set_key(.false.)
   elseif (option == 'readout') then
      call self%figure%set_readout(.false.)
   elseif (keyword(option, 'colorbox', 4_I4P)) then
      call self%figure%set_colorbox(.false.)
   elseif (keyword(option, 'cblabel', 3_I4P)) then
      call self%figure%set_cblabel('')
   elseif (keyword(option, 'boxwidth', 3_I4P)) then
      call self%figure%set_boxwidth()
   elseif (option == 'pixmap' .or. option == 'pixmaps') then
      ! unset pixmap N, unset pixmaps
      block
         integer(I4P) :: n !< Tag.
         integer(I4P) :: j !< Token counter.

         if (size(tokens) > 2 .or. (option == 'pixmap' .and. size(tokens) /= 2) .or. &
             (option == 'pixmaps' .and. size(tokens) /= 1)) then
            call fail('unset pixmap N, or unset pixmaps, expected', iostat, iomsg)
            return
         endif
         if (option == 'pixmap') then
            j = 1_I4P
            if (.not. next_integer(tokens, j, n, iostat, iomsg, self%symbols)) return
            call self%figure%unset_pixmap(n)
         else
            call self%figure%unset_pixmap()
         endif
      endblock
   elseif (keyword(option, 'label', 3_I4P) .or. keyword(option, 'arrow', 3_I4P) .or. keyword(option, 'object', 3_I4P)) &
      then
      ! unset label|arrow|object [N]
      block
         integer(I4P) :: n !< Tag.
         integer(I4P) :: j !< Token counter.

         if (size(tokens) > 2) then
            call fail('unset '//option//': a tag or nothing expected', iostat, iomsg)
            return
         endif
         if (size(tokens) == 2) then
            j = 1_I4P
            if (.not. next_integer(tokens, j, n, iostat, iomsg, self%symbols)) return
         endif
         if (keyword(option, 'label', 3_I4P)) then
            if (size(tokens) == 2) then
               call self%figure%unset_label(n)
            else
               call self%figure%unset_label()
            endif
         elseif (keyword(option, 'arrow', 3_I4P)) then
            if (size(tokens) == 2) then
               call self%figure%unset_arrow(n)
            else
               call self%figure%unset_arrow()
            endif
         else
            if (size(tokens) == 2) then
               call self%figure%unset_object(n)
            else
               call self%figure%unset_object()
            endif
         endif
      endblock
   elseif (is_word(option, 'xdata ydata y2data x2data xda yda y2da x2da xdat ydat y2dat x2dat')) then
      call self%set_time_data(option, .false.)
   elseif (keyword(option, 'timefmt', 5_I4P)) then
      self%timefmt = '%d/%m/%y,%H:%M'
      self%symbols%timefmt = self%timefmt
      call self%figure%set_timefmt(self%timefmt)
   elseif (keyword(option, 'xrange', 2_I4P)) then
      call self%figure%set_xrange()
   elseif (keyword(option, 'yrange', 2_I4P)) then
      call self%figure%set_yrange()
   elseif (keyword(option, 'y2range', 3_I4P)) then
      call self%figure%set_y2range()
   elseif (keyword(option, 'x2range', 3_I4P)) then
      call self%figure%set_x2range()
   elseif (keyword(option, 'trange', 2_I4P)) then
      self%figure%panels(self%figure%current)%taxis%min_fixed = .false.
      self%figure%panels(self%figure%current)%taxis%max_fixed = .false.
   elseif (keyword(option, 'rrange', 2_I4P)) then
      self%figure%panels(self%figure%current)%raxis%min_fixed = .false.
      self%figure%panels(self%figure%current)%raxis%max_fixed = .false.
   elseif (keyword(option, 'urange', 2_I4P) .or. keyword(option, 'vrange', 2_I4P)) then
      if (option(1:1) == 'u') self%uv_range(:, 1) = [-5.0_R8P, 5.0_R8P]
      if (option(1:1) == 'v') self%uv_range(:, 2) = [-5.0_R8P, 5.0_R8P]
   elseif (keyword(option, 'autoscale', 4_I4P)) then
      ! gnuplot `unset autoscale [AXES]`: the ranges of the axes (all by default) fixed as they are now
      block
         character(len=:), allocatable :: names !< Axes named.

         names = 'x y x2 y2 z cb'
         if (size(tokens) > 1) names = tokens(2)%text
         associate(panel => self%figure%panels(self%figure%current))
            if (names == 'x y x2 y2 z cb' .or. index(names, 'x') > 0) call fix_range(panel%xaxis)
            if (names == 'x y x2 y2 z cb' .or. index(names, 'y') > 0) call fix_range(panel%yaxis)
            if (names == 'x y x2 y2 z cb') then
               call fix_range(panel%x2axis)
               call fix_range(panel%y2axis)
               call fix_range(panel%zaxis)
               call fix_range(panel%cbaxis)
            elseif (index(names, 'z') > 0) then
               call fix_range(panel%zaxis)
            elseif (index(names, 'cb') > 0) then
               call fix_range(panel%cbaxis)
            endif
         endassociate
      endblock
   elseif (keyword(option, 'dgrid3d', 2_I4P)) then
      self%figure%panels(self%figure%current)%dgrid3d%on = .false.
   elseif (keyword(option, 'contour', 3_I4P)) then
      self%figure%panels(self%figure%current)%contour%on = .false.
   elseif (keyword(option, 'pm3d', 2_I4P)) then
      ! the surfaces no more drawn with pm3d (gnuplot: explicit), the pm3d data and function styles back to the defaults
      ! (lines, foresight's data style)
      self%figure%panels(self%figure%current)%pm3d%implicit = .false.
      if (self%data_style == 'pm3d') self%data_style = 'lines'
      if (self%function_style == 'pm3d') self%function_style = 'lines'
   elseif (keyword(option, 'zrange', 2_I4P)) then
      self%figure%panels(self%figure%current)%zaxis%min_fixed = .false.
      self%figure%panels(self%figure%current)%zaxis%max_fixed = .false.
   elseif (keyword(option, 'zlabel', 2_I4P)) then
      self%figure%panels(self%figure%current)%zaxis%label = ''
   elseif (keyword(option, 'ztics', 3_I4P)) then
      call self%figure%panels(self%figure%current)%zaxis%tics%disable
   elseif (keyword(option, 'mztics', 3_I4P)) then
      self%figure%panels(self%figure%current)%zaxis%tics%minor = 0_I4P
   elseif (keyword(option, 'zzeroaxis', 5_I4P)) then
      self%figure%panels(self%figure%current)%view3d%zzeroaxis = .false.
   elseif (keyword(option, 'surface', 2_I4P)) then
      self%figure%panels(self%figure%current)%view3d%surface = .false.
   elseif (option == 'view') then
      ! gnuplot 6.0: unset view is set view 60, 30, 1, 1 (the map off)
      block
         type(view3d_object) :: fresh !< Default view.

         self%figure%panels(self%figure%current)%view3d%rot_x = fresh%rot_x
         self%figure%panels(self%figure%current)%view3d%rot_z = fresh%rot_z
         self%figure%panels(self%figure%current)%view3d%scale = fresh%scale
         self%figure%panels(self%figure%current)%view3d%zscale = fresh%zscale
         self%figure%panels(self%figure%current)%view3d%map = fresh%map
      endblock
   elseif (is_word(option, 'lmargin rmargin tmargin bmargin lmar rmar tmar bmar lmarg rmarg tmarg bmarg')) then
      call self%figure%set_margin(option(1:1))
   elseif (keyword(option, 'margins', 4_I4P)) then
      call self%figure%set_margin('l')
      call self%figure%set_margin('r')
      call self%figure%set_margin('t')
      call self%figure%set_margin('b')
   elseif (keyword(option, 'zeroaxis', 4_I4P)) then
      call self%figure%set_zeroaxis('x y x2 y2', on=.false.)
   elseif (keyword(option, 'xzeroaxis', 5_I4P)) then
      call self%figure%set_zeroaxis('x', on=.false.)
   elseif (keyword(option, 'yzeroaxis', 5_I4P)) then
      call self%figure%set_zeroaxis('y', on=.false.)
   elseif (keyword(option, 'x2zeroaxis', 6_I4P)) then
      call self%figure%set_zeroaxis('x2', on=.false.)
   elseif (keyword(option, 'y2zeroaxis', 6_I4P)) then
      call self%figure%set_zeroaxis('y2', on=.false.)
   elseif (keyword(option, 'tics', 3_I4P)) then
      ! every axis, as gnuplot
      call self%figure%unset_xtics
      call self%figure%unset_ytics
      call self%figure%unset_x2tics
      call self%figure%unset_y2tics
      call self%figure%unset_cbtics
   elseif (keyword(option, 'xtics', 3_I4P)) then
      call self%figure%unset_xtics
   elseif (keyword(option, 'ytics', 3_I4P)) then
      call self%figure%unset_ytics
   elseif (keyword(option, 'y2tics', 4_I4P)) then
      call self%figure%unset_y2tics
   elseif (keyword(option, 'x2tics', 4_I4P)) then
      call self%figure%unset_x2tics
   elseif (keyword(option, 'cbtics', 4_I4P)) then
      call self%figure%unset_cbtics
   elseif (keyword(option, 'mxtics', 3_I4P)) then
      call self%figure%set_mxtics(0_I4P)
   elseif (keyword(option, 'mytics', 3_I4P)) then
      call self%figure%set_mytics(0_I4P)
   elseif (keyword(option, 'my2tics', 4_I4P)) then
      call self%figure%set_my2tics(0_I4P)
   elseif (keyword(option, 'mx2tics', 4_I4P)) then
      call self%figure%set_mx2tics(0_I4P)
   elseif (keyword(option, 'mcbtics', 4_I4P)) then
      call self%figure%set_mcbtics(0_I4P)
   elseif (keyword(option, 'format', 3_I4P)) then
      call self%figure%set_format('')
   elseif (keyword(option, 'print', 2_I4P)) then
      self%print_file = ''
   elseif (keyword(option, 'table', 3_I4P)) then
      self%table = .false.
   elseif (keyword(option, 'errorbars', 6_I4P) .or. keyword(option, 'bars', 3_I4P)) then
      ! no crossbars, as gnuplot's unset errorbars
      self%figure%panels(self%figure%current)%errorbar_size = 0.0_R8P
   elseif (keyword(option, 'samples', 3_I4P)) then
      self%samples = 100_I4P
      self%samples2 = 100_I4P
   elseif (keyword(option, 'isosamples', 3_I4P)) then
      self%isosamples = 10_I4P
      self%isosamples1 = 10_I4P
   elseif (keyword(option, 'mouse', 3_I4P) .or. &
           keyword(option, 'macros', 3_I4P)) then
      ! surfaces, interactive terminals, macros always on: nothing to undo
      continue
   elseif (keyword(option, 'minussign', 5_I4P) .or. keyword(option, 'minus_sign', 5_I4P)) then
      self%minus_sign = .false.
   elseif (keyword(option, 'micro', 3_I4P)) then
      self%micro = .false.
   elseif (keyword(option, 'overflow', 3_I4P)) then
      ! `+` and `-` wrap around as two's complement, gnuplot's `unset overflow`
      overflow_mode = OVERFLOW_IGNORE
   elseif (keyword(option, 'mttics', 3_I4P)) then
      self%figure%panels(self%figure%current)%ttics%minor = MINOR_NONE
   else
      call fail('unsupported option "unset '//option//'"', iostat, iomsg)
   endif
   endsubroutine unset_command

   ! helpers
   pure function is_cntrparam_word(word) result(yes)
   !< Whether `word` is an option of `set cntrparam`.
   character(len=*), intent(in) :: word !< Word.
   logical                      :: yes  !< An option.

   yes = keyword(word, 'points', 1_I4P) .or. keyword(word, 'firstlinetype', 5_I4P) .or. keyword(word, 'sorted', 4_I4P) &
         .or. keyword(word, 'unsorted', 6_I4P) .or. keyword(word, 'linear', 2_I4P) .or. &
         keyword(word, 'cubicspline', 1_I4P) .or. keyword(word, 'bspline', 1_I4P) .or. keyword(word, 'order', 1_I4P) &
         .or. keyword(word, 'levels', 2_I4P)
   endfunction is_cntrparam_word

   pure subroutine fix_range(axis)
   !< The range of `axis` fixed as it is (gnuplot `unset autoscale`): its set ends, else the effective ones.
   type(axis_object), intent(inout) :: axis !< Axis.

   if (.not. axis%min_fixed) axis%min_user = axis%lo
   if (.not. axis%max_fixed) axis%max_user = axis%hi
   axis%min_fixed = .true.
   axis%max_fixed = .true.
   endsubroutine fix_range

   pure subroutine item_auto_title(text, first, file_last, last, written, quote, spec, using, title)
   !< The automatic title of a data item, gnuplot's: the item as written from its file (characters `first` to
   !< `file_last` of the statement `text`) through its data options (index, every, using, matrix, skip: up to `last`);
   !< inline data as '-' or "-"; from the file `written` in its `quote` and the `using` `spec` when the positions are
   !< not the text's (binary items rewritten). A subroutine with its arguments: nvfortran 26.9 broke the data of the
   !< plot through an internal function of plot_items returning the title.
   character(len=*),              intent(in)  :: text      !< Statement.
   integer(I4P),                  intent(in)  :: first     !< First character of the file.
   integer(I4P),                  intent(in)  :: file_last !< Its last character.
   integer(I4P),                  intent(in)  :: last      !< Last character of the data options.
   character(len=*),              intent(in)  :: written   !< The file as written.
   character(len=*),              intent(in)  :: quote     !< Its quote.
   character(len=*),              intent(in)  :: spec      !< The using spec as written.
   character(len=*),              intent(in)  :: using     !< The using keyword as written.
   character(len=:), allocatable, intent(out) :: title     !< Title.

   if (first < 1_I4P .or. last > len(text, kind=I4P) .or. last < first) then
      title = trim(quote)//written//trim(quote)
      if (len(spec) > 0) title = title//' '//using//' '//spec
   elseif (index(written, '$FS_INLINE_S') == 1) then
      title = "'-'"//text(file_last + 1_I4P:last)
   elseif (index(written, '$FS_INLINE_D') == 1) then
      title = '"-"'//text(file_last + 1_I4P:last)
   else
      title = text(first:last)
   endif
   endsubroutine item_auto_title

   pure function exact_real(v) result(text)
   !< `v` written to its last bit (17 significant digits), read back the same.
   real(R8P), intent(in)         :: v    !< Value.
   character(len=:), allocatable :: text !< Text.
   character(len=32)             :: buf  !< Buffer.

   write(buf, '(ES25.17E3)') v
   text = trim(adjustl(buf))
   endfunction exact_real

   pure subroutine set_heights(series, z, scans, sets, grid, read)
   !< Give `series` its heights `z` and its `scans` (first and last point of each) in their datasets `sets`, the first
   !< `grid` of them its surface grid, `read` from data (gnuplot keeps those last first).
   type(series_object), intent(inout) :: series     !< Series.
   real(R8P),           intent(in)    :: z(:)       !< Heights.
   integer(I4P),        intent(in)    :: scans(:,:) !< Scans.
   integer(I4P),        intent(in)    :: sets(:)    !< Their datasets.
   integer(I4P),        intent(in)    :: grid       !< Grid scans.
   logical,             intent(in)    :: read       !< Read from data.

   series%z = z
   series%scans = scans
   series%scan_sets = sets
   series%grid_scans = grid
   series%data_scans = read
   endsubroutine set_heights

   pure subroutine append_text(buffer, used, piece)
   !< Append `piece` to `buffer(1:used)`, doubling its length as needed: a long text built in linear time.
   character(len=:), allocatable, intent(inout) :: buffer !< Text, valid up to `used`.
   integer(I4P),                  intent(inout) :: used   !< Its length used.
   character(len=*),              intent(in)    :: piece  !< Text appended.
   character(len=:), allocatable                :: bigger !< Grown text.

   if (.not. allocated(buffer)) then
      allocate(character(len=max(4096, 2 * len(piece))) :: buffer)
      used = 0_I4P
   endif
   if (used + len(piece) > len(buffer)) then
      allocate(character(len=max(2 * len(buffer), used + len(piece))) :: bigger)
      bigger(1:used) = buffer(1:used)
      call move_alloc(bigger, buffer)
   endif
   buffer(used + 1:used + len(piece)) = piece
   used = used + len(piece, kind=I4P)
   endsubroutine append_text

   pure subroutine using_parts(spec, parts)
   !< The fields of a using spec as written, split at the colons outside parentheses and quotes (as parse_using).
   character(len=*),              intent(in)  :: spec     !< Specification.
   character(len=:), allocatable, intent(out) :: parts(:) !< Fields, blank padded.
   integer(I4P)                               :: n        !< Fields.
   integer(I4P)                               :: k        !< Character counter.
   integer(I4P)                               :: start    !< Field start.
   integer(I4P)                               :: depth    !< Parenthesis depth.
   character(len=1)                           :: quote    !< Open quote, blank if none.

   n = 1_I4P
   depth = 0_I4P
   quote = ' '
   do k = 1_I4P, len(spec, kind=I4P)
      if (quote /= ' ') then
         if (spec(k:k) == quote) quote = ' '
      elseif (spec(k:k) == '"' .or. spec(k:k) == "'") then
         quote = spec(k:k)
      elseif (spec(k:k) == '(') then
         depth = depth + 1_I4P
      elseif (spec(k:k) == ')') then
         depth = depth - 1_I4P
      elseif (spec(k:k) == ':' .and. depth == 0_I4P) then
         n = n + 1_I4P
      endif
   enddo
   allocate(character(len=max(1, len(spec))) :: parts(n))
   parts(:) = ''
   n = 1_I4P
   depth = 0_I4P
   quote = ' '
   start = 1_I4P
   do k = 1_I4P, len(spec, kind=I4P)
      if (quote /= ' ') then
         if (spec(k:k) == quote) quote = ' '
      elseif (spec(k:k) == '"' .or. spec(k:k) == "'") then
         quote = spec(k:k)
      elseif (spec(k:k) == '(') then
         depth = depth + 1_I4P
      elseif (spec(k:k) == ')') then
         depth = depth - 1_I4P
      elseif (spec(k:k) == ':' .and. depth == 0_I4P) then
         parts(n) = spec(start:k - 1_I4P)
         n = n + 1_I4P
         start = k + 1_I4P
      endif
   enddo
   parts(n) = spec(start:)
   endsubroutine using_parts

   pure function replace_colons(spec) result(words)
   !< The fields of a using spec as blank separated words (the count of its fields by word_count).
   character(len=*), intent(in)  :: spec  !< Specification.
   character(len=:), allocatable :: words !< Fields, one word each.
   character(len=:), allocatable :: parts(:) !< Fields.
   integer(I4P)                  :: k     !< Field counter.

   call using_parts(spec, parts)
   words = ''
   do k = 1_I4P, size(parts, kind=I4P)
      words = words//' x'
   enddo
   endfunction replace_colons

   pure function top_colon(text) result(colon)
   !< Position of the first `:` outside quotes and parentheses, 0 if none.
   character(len=*), intent(in) :: text  !< Text.
   integer(I4P)                 :: colon !< Position.
   character(len=1)             :: quote !< Open quote, blank if none.
   integer(I4P)                 :: depth !< Parenthesis depth.
   integer(I4P)                 :: i     !< Character counter.

   colon = 0_I4P
   quote = ' '
   depth = 0_I4P
   do i = 1_I4P, len(text, kind=I4P)
      if (quote /= ' ') then
         if (text(i:i) == quote) quote = ' '
      elseif (text(i:i) == '"' .or. text(i:i) == "'") then
         quote = text(i:i)
      elseif (text(i:i) == '(') then
         depth = depth + 1_I4P
      elseif (text(i:i) == ')') then
         depth = depth - 1_I4P
      elseif (text(i:i) == ':' .and. depth == 0_I4P) then
         colon = i
         return
      endif
   enddo
   endfunction top_colon

   pure function is_datablock(word) result(yes)
   !< Whether `word` names a datablock: `$`, then a letter or `_`, then letters, digits, `_` (gnuplot `$DATA`).
   character(len=*), intent(in) :: word !< Word.
   logical                      :: yes  !< A datablock name.
   character(len=*), parameter  :: LETTERS = UNAME_START

   yes = len(word) >= 2
   if (yes) yes = word(1:1) == '$' .and. scan(word(2:2), LETTERS) > 0
   if (yes) yes = verify(word(2:), UNAME_CHARS) == 0
   endfunction is_datablock

   pure function string_variable_of(symbols, name) result(yes)
   !< Whether `name` is a string variable of `symbols`.
   type(symbols_object), intent(in) :: symbols !< Symbols.
   character(len=*),     intent(in) :: name    !< Name.
   logical                          :: yes     !< A string variable.
   character(len=:), allocatable    :: text    !< Its value.

   call symbols%string_of(name, text, yes)
   endfunction string_variable_of

   recursive subroutine exit_command(self, statement, command, iostat, iomsg)
   !< gnuplot `exit`, `exit message "text"` (the text on the standard error), `exit error "text"`, `exit status N`,
   !< `exit gnuplot`, `quit`: `exit` ends the script file being read, as `return` (signal 3); the others the run
   !< (signal 4), `exit status N` with N its status.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   character(len=*),              intent(in)    :: statement !< The statement.
   character(len=*),              intent(in)    :: command   !< `exit` or `quit`.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   character(len=:), allocatable                :: rest      !< Text after the command.
   character(len=:), allocatable                :: word      !< Option.
   character(len=:), allocatable                :: text      !< Message.
   logical                                      :: is_string !< A string value.
   real(R8P)                                    :: v         !< Status.

   iostat = 0_I4P
   iomsg = ''
   rest = trim(adjustl(statement))
   rest = trim(adjustl(rest(len(command) + 1:)))
   if (command == 'quit') then
      if (len(rest) > 0) then
         call fail('quit takes nothing after it', iostat, iomsg)
         return
      endif
      self%loop_signal = 4_I4P
      return
   endif
   word = leading_word(rest)
   if (len(word) > 0) rest = trim(adjustl(rest(len(word) + 1:)))
   select case (word)
   case ('')
      if (len(rest) > 0) then
         call fail('exit: message, error, status or gnuplot expected, found "'//rest//'"', iostat, iomsg)
         return
      endif
      self%loop_signal = 3_I4P
   case ('message', 'error')
      call self%symbols%text_of(rest, text, is_string, iostat, iomsg)
      if (iostat /= 0_I4P) then
         iomsg = 'exit '//word//': '//iomsg
         return
      endif
      if (word == 'error') then
         call fail(text, iostat, iomsg)
         return
      endif
      write(error_unit, '(A)') text
      self%loop_signal = 3_I4P
   case ('status')
      call self%symbols%constant(rest, v, iostat, iomsg)
      if (iostat /= 0_I4P) then
         iomsg = 'exit status: '//iomsg
         return
      endif
      self%exit_status = int(v, I4P)
      self%loop_signal = 4_I4P
   case ('gnuplot')
      self%loop_signal = 4_I4P
   case default
      call fail('exit: message, error, status or gnuplot expected, found "'//word//'"', iostat, iomsg)
   endselect
   endsubroutine exit_command

   pure subroutine push_local(list, item)
   !< Append `item` to `list`, through a temporary (nvfortran 26.9: see foresight_tokens push).
   type(local_state), allocatable, intent(inout) :: list(:)  !< List.
   type(local_state),              intent(in)    :: item     !< New item.
   type(local_state), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                  :: n        !< Items before the push.

   if (.not. allocated(list)) allocate(list(0))
   n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_local

   pure function last_semicolon(line) result(k)
   !< Position of the last `;` of `line` outside quotes (a statement separator), 0 if none.
   character(len=*), intent(in) :: line  !< Logical line.
   integer(I4P)                 :: k     !< Position.
   character                    :: quote !< Open quote, blank if none.
   integer(I4P)                 :: i     !< Character counter.

   k = 0_I4P
   quote = ' '
   i = 0_I4P
   do while (i < len(line, kind=I4P))
      i = i + 1_I4P
      if (quote /= ' ') then
         if (line(i:i) == '\' .and. quote == '"') then
            i = i + 1_I4P
         elseif (line(i:i) == quote) then
            quote = ' '
         endif
      elseif (line(i:i) == '"' .or. line(i:i) == "'") then
         quote = line(i:i)
      elseif (line(i:i) == '#') then
         exit
      elseif (line(i:i) == ';') then
         k = i
      endif
   enddo
   endfunction last_semicolon

   function heredoc(line, name, terminator) result(yes)
   !< Whether `line` starts a datablock, `$NAME << WORD` (blanks optional around `<<`, a comment after WORD), giving
   !< its `name` (`$NAME`) and `terminator`.
   character(len=*),              intent(in)    :: line       !< Logical line.
   character(len=:), allocatable, intent(inout) :: name       !< Datablock name.
   character(len=:), allocatable, intent(inout) :: terminator !< Terminating word.
   logical                                      :: yes        !< A datablock start.
   character(len=:), allocatable                :: t          !< Line without leading blanks.
   integer(I4P)                                 :: k          !< `<<` position.
   integer(I4P)                                 :: e          !< Word end.
   character(len=:), allocatable                :: rest       !< Text after `<<`.

   yes = .false.
   t = trim(adjustl(line))
   k = index(t, '<<', kind=I4P)
   if (k < 3_I4P) return
   if (.not. is_datablock(trim(t(1:k - 1_I4P)))) return
   rest = trim(adjustl(t(k + 2_I4P:)))
   e = scan(rest, ' #'//achar(9), kind=I4P) - 1_I4P
   if (e < 0_I4P) e = len(rest, kind=I4P)
   if (e == 0_I4P) return
   if (verify(rest(1:e), UNAME_CHARS) /= 0) return
   name = trim(t(1:k - 1_I4P))
   terminator = rest(1:e)
   yes = .true.
   endfunction heredoc

   pure function for_follows(statement, command) result(yes)
   !< Whether `statement`, after its `command` word, goes on with `for [`.
   character(len=*), intent(in)  :: statement !< Statement.
   character(len=*), intent(in)  :: command   !< Its first word.
   logical                       :: yes       !< `for [` follows.
   character(len=:), allocatable :: rest      !< Text after the command.

   rest = trim(adjustl(statement))
   rest = trim(adjustl(rest(len(command) + 1:)))
   yes = leading_word(rest) == 'for'
   if (.not. yes) return
   rest = trim(adjustl(rest(4:)))
   yes = .false.
   if (len(rest) > 0) yes = rest(1:1) == '['
   endfunction for_follows

   pure function leading_word(text) result(word)
   !< The letters starting `text` (blanks skipped): `do`, `if`, `while`, `else`, `for`, `break`.
   character(len=*), intent(in)  :: text !< Text.
   character(len=:), allocatable :: word !< Leading word.
   character(len=:), allocatable :: t    !< Text without leading blanks.
   integer(I4P)                  :: e    !< First character after the word.

   t = trim(adjustl(text))
   e = verify(t, UNAME_START, kind=I4P)
   if (e == 0_I4P) e = len(t, kind=I4P) + 1_I4P
   word = t(1:e - 1_I4P)
   endfunction leading_word

   pure function inline_name(quote, n) result(name)
   !< The datablock of the `n`-th inline data item `'-'` of a line: `$FS_INLINE_S<n>` quoted by `'`, `$FS_INLINE_D<n>`
   !< by `"` (the auto title written back as the item was).
   character(len=1), intent(in)  :: quote !< Quote of the item.
   integer(I4P),     intent(in)  :: n     !< Item order.
   character(len=:), allocatable :: name  !< Datablock name.

   name = '$FS_INLINE_D'
   if (quote == "'") name = '$FS_INLINE_S'
   name = name//int_str(int(n, I8P))
   endfunction inline_name

   pure subroutine inline_items(line, rewritten, quotes)
   !< The inline data items `'-'` of the plot, replot, fit and stats statements of a line: `rewritten` with each one as
   !< its datablock (`inline_name`), `quotes` the quote of each (one character per item, empty if none), in order.
   character(len=*),              intent(in)  :: line      !< Logical line.
   character(len=:), allocatable, intent(out) :: rewritten !< Line with the datablock names.
   character(len=:), allocatable, intent(out) :: quotes    !< Quote of each item.
   character(len=:), allocatable              :: part      !< A statement rewritten.
   character(len=1)                           :: quote     !< Open quote, blank if none.
   integer(I4P)                               :: a         !< Statement start.
   integer(I4P)                               :: i         !< Character counter.
   integer(I4P)                               :: depth     !< Bracket depth.

   rewritten = ''
   quotes = ''
   if (index(line, '-') == 0) then
      rewritten = line
      return
   endif
   quote = ' '
   depth = 0_I4P
   a = 1_I4P
   do i = 1_I4P, len(line, kind=I4P) + 1_I4P
      if (i <= len(line, kind=I4P)) then
         if (quote /= ' ') then
            if (line(i:i) == quote) quote = ' '
            cycle
         endif
         select case (line(i:i))
         case ("'", '"')
            quote = line(i:i)
            cycle
         case ('(', '[', '{')
            depth = depth + 1_I4P
            cycle
         case (')', ']', '}')
            depth = depth - 1_I4P
            cycle
         case (';')
            if (depth /= 0_I4P) cycle
         case default
            cycle
         endselect
      endif
      ! a statement ends at i
      call inline_statement(line(a:i - 1_I4P), quotes, part)
      rewritten = rewritten//part
      if (i <= len(line, kind=I4P)) rewritten = rewritten//';'
      a = i + 1_I4P
   enddo
   endsubroutine inline_items

   pure subroutine inline_statement(line, quotes, rewritten)
   !< The inline data items of a plot, replot, fit or stats statement, `quotes` extended with theirs (see
   !< `inline_items`). An item is `'-'` or `"-"` where a file is expected: first, or after a comma, past inline ranges
   !< and `for [...]`; for fit, after a blank.
   character(len=*),              intent(in)    :: line      !< Statement.
   character(len=:), allocatable, intent(inout) :: quotes    !< Quote of each item.
   character(len=:), allocatable, intent(out)   :: rewritten !< Statement with the datablock names.
   character(len=:), allocatable              :: word      !< Command word.
   integer(I4P)                               :: i         !< Character counter.
   integer(I4P)                               :: e         !< Closing bracket or quote.
   integer(I4P)                               :: depth     !< Parentheses depth.
   logical                                    :: expect    !< A file item may start here.
   character(len=:), allocatable              :: after     !< The statement from its first word.

   rewritten = line
   if (index(line, '-') == 0) return
   word = leading_word(line)
   if (len(word) == 0) return
   ! `set palette file '-'`: its file the inline data that follow (a `set palette` statement, not a `"-"` within the
   ! string of another option, such as a title)
   if (keyword(word, 'set', 2_I4P) .and. index(line, 'palette') > 0) then
      after = adjustl(line)
      i = index(after, ' ', kind=I4P)
      if (i == 0_I4P) return
      if (.not. keyword(leading_word(after(i:)), 'palette', 3_I4P)) return
      i = index(line, "file '-'", kind=I4P)
      if (i == 0_I4P) i = index(line, 'file "-"', kind=I4P)
      if (i > 0_I4P) then
         quotes = quotes//line(i + 5_I4P:i + 5_I4P)
         rewritten = line(1:i + 4_I4P)//inline_name(line(i + 5_I4P:i + 5_I4P), len(quotes, kind=I4P))// &
                     line(i + 8_I4P:)
      endif
      return
   endif
   if (.not. (keyword(word, 'plot', 1_I4P) .or. keyword(word, 'replot', 3_I4P) .or. word == 'fit' .or. &
              keyword(word, 'stats', 2_I4P) .or. keyword(word, 'splot', 2_I4P))) return
   i = index(line, word, kind=I4P) + len(word, kind=I4P)
   rewritten = line(1:i - 1)
   expect = .true.
   depth = 0_I4P
   do while (i <= len(line, kind=I4P))
      associate(c => line(i:i))
         if (c == ' ' .or. c == achar(9)) then
            rewritten = rewritten//c
            ! fit's file follows its function, a blank apart
            if (word == 'fit' .and. depth == 0_I4P) expect = .true.
         elseif (c == '[' .and. expect) then
            ! an inline range or the iteration of `for`
            e = matching(line, i)
            if (e == 0_I4P) e = len(line, kind=I4P)
            rewritten = rewritten//line(i:e)
            i = e
         elseif (expect .and. i + 2_I4P <= len(line, kind=I4P) .and. index(line(i:), 'for') == 1) then
            rewritten = rewritten//'for'
            i = i + 2_I4P
         elseif ((c == "'" .or. c == '"') .and. expect .and. i + 2_I4P <= len(line, kind=I4P)) then
            expect = .false.
            if (line(i + 1_I4P:i + 2_I4P) == '-'//c) then
               quotes = quotes//c
               rewritten = rewritten//inline_name(c, len(quotes, kind=I4P))
               i = i + 2_I4P
            else
               e = i + index(line(i + 1_I4P:), c, kind=I4P)
               if (e == i) e = len(line, kind=I4P)
               rewritten = rewritten//line(i:e)
               i = e
            endif
         elseif (c == "'" .or. c == '"') then
            ! a string: skipped whole
            e = i + index(line(i + 1_I4P:), c, kind=I4P)
            if (e == i) e = len(line, kind=I4P)
            rewritten = rewritten//line(i:e)
            i = e
         else
            expect = .false.
            if (c == '(' .or. c == '[' .or. c == '{') depth = depth + 1_I4P
            if (c == ')' .or. c == ']' .or. c == '}') depth = depth - 1_I4P
            if (c == ',' .and. depth == 0_I4P) expect = .true.
            rewritten = rewritten//c
         endif
      endassociate
      i = i + 1_I4P
   enddo
   endsubroutine inline_statement

   pure function matching(text, open) result(close)
   !< Position of the bracket closing the one at `open` (`(`, `[` or `{`), quotes and nesting respected; 0 if none.
   character(len=*), intent(in) :: text  !< Text.
   integer(I4P),     intent(in) :: open  !< Opening bracket.
   integer(I4P)                 :: close !< Closing bracket.
   character(len=1)             :: left  !< Opening bracket.
   character(len=1)             :: right !< Closing bracket.
   character(len=1)             :: quote !< Open quote, blank if none.
   integer(I4P)                 :: depth !< Nesting.

   left = text(open:open)
   right = merge(')', merge(']', '}', left == '['), left == '(')
   quote = ' '
   depth = 0_I4P
   close = open
   do while (close <= len(text, kind=I4P))
      if (quote /= ' ') then
         if (quote == '"' .and. text(close:close) == '\') then
            close = close + 1_I4P
         elseif (text(close:close) == quote) then
            quote = ' '
         endif
      elseif (text(close:close) == '"' .or. text(close:close) == "'") then
         quote = text(close:close)
      elseif (text(close:close) == left) then
         depth = depth + 1_I4P
      elseif (text(close:close) == right) then
         depth = depth - 1_I4P
         if (depth == 0_I4P) return
      endif
      close = close + 1_I4P
   enddo
   close = 0_I4P
   endfunction matching

   function block_body(text, body, rest) result(ok)
   !< `{ body } rest`: the body and the text after the closing brace.
   character(len=*),              intent(in)  :: text !< Text starting with `{`.
   character(len=:), allocatable, intent(out) :: body !< Body.
   character(len=:), allocatable, intent(out) :: rest !< After the block.
   logical                                    :: ok   !< A block found.
   integer(I4P)                               :: close !< Closing brace.

   body = ''
   rest = text
   ok = .false.
   if (len(text) == 0) return
   if (text(1:1) /= '{') return
   close = matching(text, 1_I4P)
   if (close == 0_I4P) return
   body = text(2:close - 1_I4P)
   rest = trim(adjustl(text(close + 1_I4P:)))
   ok = .true.
   endfunction block_body

   pure subroutine autoscale_axis(axis, ends, fix)
   !< `axis` autoscaled at its `ends` (min, max), not extended to the ticks with `fix` (gnuplot `set autoscale`).
   type(axis_object), intent(inout) :: axis    !< Axis.
   logical,           intent(in)    :: ends(2) !< min, max autoscaled.
   logical,           intent(in)    :: fix     !< Ends at the data.

   if (ends(1)) axis%min_fixed = .false.
   if (ends(2)) axis%max_fixed = .false.
   if (fix) axis%noextend = .true.
   endsubroutine autoscale_axis

   function old_if(statement) result(yes)
   !< Whether `statement` is gnuplot's old one-line `if (condition) command` (no block after the condition).
   character(len=*), intent(in)  :: statement !< Statement.
   logical                       :: yes       !< An old if.
   character(len=:), allocatable :: rest      !< Text after `if`.
   character(len=:), allocatable :: inside    !< Condition.
   character(len=:), allocatable :: after     !< Text after the condition.

   yes = leading_word(statement) == 'if'
   if (.not. yes) return
   rest = trim(adjustl(statement))
   rest = trim(adjustl(rest(3:)))
   yes = parenthesized(rest, inside, after)
   if (yes) yes = len_trim(after) > 0
   if (yes) yes = adjustl(after) /= '{' .and. index(adjustl(after), '{') /= 1
   endfunction old_if

   pure function same_line_end(text, statements, s) result(e)
   !< The last of `statements` (from `s`) on the same line of `text` as statement `s`.
   character(len=*),   intent(in) :: text          !< Text the statements come from.
   type(token_object), intent(in) :: statements(:) !< Statements, with their places in `text`.
   integer(I4P),       intent(in) :: s             !< First statement.
   integer(I4P)                   :: e             !< Last on its line.

   e = s
   do while (e < size(statements, kind=I4P))
      if (index(text(statements(e)%last + 1:statements(e + 1_I4P)%first - 1), new_line('a')) > 0) exit
      e = e + 1_I4P
   enddo
   endfunction same_line_end

   function parenthesized(text, inside, rest) result(ok)
   !< `( inside ) rest`.
   character(len=*),              intent(in)  :: text   !< Text starting with `(`.
   character(len=:), allocatable, intent(out) :: inside !< Inside the parentheses.
   character(len=:), allocatable, intent(out) :: rest   !< After them.
   logical                                    :: ok     !< Found.
   integer(I4P)                               :: close  !< Closing parenthesis.

   inside = ''
   rest = text
   ok = .false.
   if (len(text) == 0) return
   if (text(1:1) /= '(') return
   close = matching(text, 1_I4P)
   if (close == 0_I4P) return
   inside = text(2:close - 1_I4P)
   rest = trim(adjustl(text(close + 1_I4P:)))
   ok = len_trim(inside) > 0
   endfunction parenthesized

   pure function mentions(text, name) result(yes)
   !< Whether the identifier `name` appears in `text` (not as part of a longer identifier).
   character(len=*), intent(in) :: text !< Text.
   character(len=*), intent(in) :: name !< Identifier.
   logical                      :: yes  !< Mentioned.
   character(len=*), parameter  :: WORD = UNAME_CHARS
   integer(I4P)                 :: k    !< Occurrence.
   integer(I4P)                 :: from !< Search start.

   yes = .false.
   from = 1_I4P
   do
      k = index(text(from:), name, kind=I4P)
      if (k == 0_I4P) return
      k = from + k - 1_I4P
      yes = .true.
      if (k > 1_I4P) yes = scan(text(k - 1_I4P:k - 1_I4P), WORD) == 0
      if (yes .and. k + len(name) <= len(text)) then
         yes = scan(text(k + len(name):k + len(name)), WORD) == 0
      endif
      if (yes) return
      from = k + 1_I4P
   enddo
   endfunction mentions

   pure subroutine split_words(text, words)
   !< The blank-separated words of `text` (blanks, tabs, new lines), as gnuplot's words() and word().
   character(len=*),                intent(in)  :: text     !< Text.
   type(token_object), allocatable, intent(out) :: words(:) !< Words.
   type(token_object)                           :: word     !< One word.
   integer(I4P)                                 :: i        !< Character counter.
   integer(I4P)                                 :: start    !< Word start.

   allocate(words(0))
   i = 1_I4P
   do while (i <= len(text, kind=I4P))
      if (scan(text(i:i), ' '//achar(9)//achar(10)//achar(13)) > 0) then
         i = i + 1_I4P
         cycle
      endif
      start = i
      do while (i <= len(text, kind=I4P))
         if (scan(text(i:i), ' '//achar(9)//achar(10)//achar(13)) > 0) exit
         i = i + 1_I4P
      enddo
      word%text = text(start:i - 1_I4P)
      call push(words, word)
   enddo
   endsubroutine split_words

   pure subroutine split_range(text, parts)
   !< `a:b[:c]` cut at the colons outside parentheses and quotes.
   character(len=*),              intent(in)  :: text     !< Range.
   character(len=:), allocatable, intent(out) :: parts(:) !< Ends.
   character(len=1)                           :: quote    !< Open quote, blank if none.
   integer(I4P)                               :: depth    !< Parenthesis depth.
   integer(I4P)                               :: start    !< Part start.
   integer(I4P)                               :: i        !< Character counter.
   integer(I4P)                               :: n        !< Parts.
   integer(I4P)                               :: cuts(4)  !< Part starts.

   quote = ' '
   depth = 0_I4P
   n = 1_I4P
   cuts(1) = 1_I4P
   do i = 1_I4P, len(text, kind=I4P)
      if (quote /= ' ') then
         if (text(i:i) == quote) quote = ' '
      elseif (text(i:i) == '"' .or. text(i:i) == "'") then
         quote = text(i:i)
      elseif (text(i:i) == '(') then
         depth = depth + 1_I4P
      elseif (text(i:i) == ')') then
         depth = depth - 1_I4P
      elseif (text(i:i) == ':' .and. depth == 0_I4P .and. n < 4_I4P) then
         n = n + 1_I4P
         cuts(n) = i + 1_I4P
      endif
   enddo
   allocate(character(len=len(text)) :: parts(n))
   do i = 1_I4P, n
      start = cuts(i)
      if (i < n) then
         parts(i) = text(start:cuts(i + 1_I4P) - 2_I4P)
      else
         parts(i) = text(start:)
      endif
   enddo
   endsubroutine split_range

   subroutine array_command(symbols, text, degrees, iostat, iomsg)
   !< gnuplot `array NAME[N]`, `array NAME[N] = [E1, E2, ...]`, `array NAME = [E1, ...]`: `text` follows `array`.
   type(symbols_object),          intent(inout) :: symbols  !< Symbols.
   character(len=*),              intent(in)    :: text     !< Text after `array`.
   logical,                       intent(in)    :: degrees  !< Angles in degrees.
   integer(I4P),                  intent(out)   :: iostat   !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg    !< Error message.
   character(len=*), parameter   :: LETTERS = UNAME_START
   character(len=:), allocatable :: s        !< Text, blanks around removed.
   character(len=:), allocatable :: name     !< Array name.
   character(len=:), allocatable :: size_text !< Size expression.
   character(len=:), allocatable :: list     !< Element list.
   type(token_object), allocatable :: parts(:) !< Element expressions.
   character(len=:), allocatable :: items(:) !< Element expressions, one array.
   integer(I4P)                  :: e        !< Name end.
   integer(I4P)                  :: close    !< Closing bracket.
   integer(I4P)                  :: width    !< Longest element expression.
   integer(I4P)                  :: k        !< Counter.

   iostat = 0_I4P
   iomsg = ''
   s = trim(adjustl(text))
   e = 0_I4P
   if (len(s) > 0) then
      if (scan(s(1:1), LETTERS) > 0) e = verify(s, UNAME_CHARS, kind=I4P)
   endif
   if (len(s) == 0 .or. e == 1_I4P .or. (e == 0_I4P .and. scan(s(1:1), LETTERS) == 0)) then
      call fail('array: a name is expected, array NAME[N] or array NAME = [...]', iostat, iomsg)
      return
   endif
   if (e == 0_I4P) e = len(s, kind=I4P) + 1_I4P
   name = s(1:e - 1_I4P)
   s = trim(adjustl(s(e:)))
   size_text = ''
   if (len(s) > 0) then
      if (s(1:1) == '[') then
         close = closing_bracket(s, 1_I4P)
         if (close == 0_I4P) then
            call fail('array '//name//': "]" expected', iostat, iomsg)
            return
         endif
         size_text = s(2:close - 1_I4P)
         if (len_trim(size_text) == 0) then
            call fail('array '//name//': a size is expected in [N]', iostat, iomsg)
            return
         endif
         s = trim(adjustl(s(close + 1_I4P:)))
      endif
   endif
   if (len(s) == 0) then
      if (len(size_text) == 0) then
         call fail('array '//name//': a size [N] or the elements = [...] are expected', iostat, iomsg)
         return
      endif
      call symbols%declare_array(name, size_text, iostat=iostat, iomsg=iomsg, degrees=degrees)
      return
   endif
   if (s(1:1) /= '=') then
      call fail('array '//name//': "=" expected, found "'//s//'"', iostat, iomsg)
      return
   endif
   s = trim(adjustl(s(2:)))
   close = 0_I4P
   if (len(s) > 0) then
      if (s(1:1) == '[') close = closing_bracket(s, 1_I4P)
   endif
   if (close /= len(s, kind=I4P)) then
      ! another array or a slice of one, array C = A[2:3]
      block
         type(value_list) :: elements !< Its elements.
         logical          :: found    !< An array or a slice.

         call symbols%array_value(s, elements, found, iostat, iomsg, degrees)
         if (iostat /= 0_I4P) return
         if (found .and. len(size_text) == 0) then
            call symbols%store_array(name, elements, iostat, iomsg)
            return
         endif
      endblock
      call fail('array '//name//': the elements in brackets are expected, = [E1, E2, ...]', iostat, iomsg)
      return
   endif
   list = s(2:close - 1_I4P)
   call split_arguments(list, parts)
   width = 1_I4P
   do k = 1_I4P, size(parts, kind=I4P)
      if (len_trim(parts(k)%text) == 0) then
         call fail('array '//name//': an empty element in "['//list//']"', iostat, iomsg)
         return
      endif
      width = max(width, len(parts(k)%text, kind=I4P))
   enddo
   allocate(character(len=width) :: items(size(parts)))
   do k = 1_I4P, size(parts, kind=I4P)
      items(k) = parts(k)%text
   enddo
   call symbols%declare_array(name, size_text, items, iostat, iomsg, degrees)
   endsubroutine array_command

   subroutine default_styles(self)
   !< gnuplot's default arrow styles (none) and rectangle style (filled with the page color, bordered black).
   type(script_object), intent(inout) :: self  !< Interpreter.
   type(shape_object)                 :: fresh !< Default object (not a constructor: see `apply_arrow_style`).

   if (allocated(self%arrow_styles)) deallocate(self%arrow_styles)
   allocate(self%arrow_styles(0))
   self%rectangle_style = fresh
   self%rectangle_style%style%border = .true.
   self%rectangle_style%style%fill = FILL_SOLID
   self%rectangle_style%style%density = 1.0_R8P
   self%rectangle_style%style%color = 'white'
   self%rectangle_style%style%border_color = 'black'
   endsubroutine default_styles

   subroutine expand_backquotes(statement, expanded, iostat, iomsg)
   !< gnuplot's command substitution: each `` `command` `` outside single quotes replaced by the command's standard
   !< output, its trailing newline dropped; in double quotes a backslash escapes the next character (`` \` ``, `\"`).
   character(len=*),              intent(in)  :: statement !< Statement.
   character(len=:), allocatable, intent(out) :: expanded  !< Statement substituted.
   integer(I4P),                  intent(out) :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out) :: iomsg     !< Error message.
   character(len=:), allocatable              :: output    !< Command output.
   character(len=1)                           :: quote     !< Open quote, blank if none.
   integer(I4P)                               :: i         !< Character counter.
   integer(I4P)                               :: close     !< Closing backquote.
   integer(I4P)                               :: status    !< Exit status.

   iostat = 0_I4P
   iomsg = ''
   expanded = ''
   quote = ' '
   i = 1_I4P
   do while (i <= len(statement, kind=I4P))
      if (quote == "'") then
         if (statement(i:i) == "'") quote = ' '
      elseif (statement(i:i) == "'" .and. quote == ' ') then
         quote = "'"
      elseif (quote == '"' .and. statement(i:i) == '\' .and. i < len(statement, kind=I4P)) then
         ! an escaped character, as it is: the string reader takes the escape
         expanded = expanded//statement(i:i + 1_I4P)
         i = i + 2_I4P
         cycle
      elseif (statement(i:i) == '"') then
         quote = merge(' ', '"', quote == '"')
      elseif (statement(i:i) == '#' .and. quote == ' ') then
         ! a comment: as it is
         expanded = expanded//statement(i:)
         return
      elseif (statement(i:i) == '`') then
         close = index(statement(i + 1_I4P:), '`', kind=I4P)
         if (close == 0_I4P) then
            call fail('unmatched ` (command substitution)', iostat, iomsg)
            return
         endif
         flush(output_unit)
         call command_output(statement(i + 1_I4P:i + close - 1_I4P), output, status)
         if (len(output) > 0) then
            if (output(len(output):len(output)) == new_line('a')) output = output(1:len(output) - 1)
         endif
         expanded = expanded//output
         i = i + close + 1_I4P
         cycle
      endif
      expanded = expanded//statement(i:i)
      i = i + 1_I4P
   enddo
   endsubroutine expand_backquotes

   pure function closing_bracket(s, open) result(close)
   !< Position of the `]` closing the `[` at `open` in `s` (quotes and nested brackets skipped), 0 if none.
   character(len=*), intent(in) :: s     !< Text.
   integer(I4P),     intent(in) :: open  !< Opening bracket.
   integer(I4P)                 :: close !< Closing bracket.
   character(len=1)             :: quote !< Open quote, blank if none.
   integer(I4P)                 :: depth !< Bracket depth.

   quote = ' '
   depth = 0_I4P
   do close = open, len(s, kind=I4P)
      if (quote /= ' ') then
         if (s(close:close) == quote) quote = ' '
         cycle
      endif
      select case (s(close:close))
      case ('"', "'")
         quote = s(close:close)
      case ('[')
         depth = depth + 1_I4P
      case (']')
         depth = depth - 1_I4P
         if (depth == 0_I4P) return
      endselect
   enddo
   close = 0_I4P
   endfunction closing_bracket

   pure subroutine split_arguments(text, parts)
   !< `text` cut at the commas outside quotes, parentheses and brackets (`print a, sprintf("%d,%d", 1, 2)`); no text
   !< is no part.
   character(len=*),                intent(in)  :: text     !< Text.
   type(token_object), allocatable, intent(out) :: parts(:) !< Parts, trimmed.
   type(token_object)                           :: part     !< One part.
   character(len=1)                             :: quote    !< Open quote, blank if none.
   integer(I4P)                                 :: depth    !< Parenthesis and bracket depth.
   integer(I4P)                                 :: start    !< Part start.
   integer(I4P)                                 :: i        !< Character counter.

   allocate(parts(0))
   if (len_trim(text) == 0) return
   quote = ' '
   depth = 0_I4P
   start = 1_I4P
   i = 1_I4P
   do while (i <= len(text, kind=I4P))
      if (quote /= ' ') then
         if (quote == '"' .and. text(i:i) == '\') then
            i = i + 1_I4P
         elseif (text(i:i) == quote) then
            quote = ' '
         endif
      else
         select case (text(i:i))
         case ('"', "'")
            quote = text(i:i)
         case ('(', '[', '{')
            ! braces: gnuplot's complex constants {re, im}
            depth = depth + 1_I4P
         case (')', ']', '}')
            depth = max(0_I4P, depth - 1_I4P)
         case (',')
            if (depth == 0_I4P) then
               part%text = trim(adjustl(text(start:i - 1_I4P)))
               call push(parts, part)
               start = i + 1_I4P
            endif
         endselect
      endif
      i = i + 1_I4P
   enddo
   part%text = trim(adjustl(text(start:)))
   call push(parts, part)
   endsubroutine split_arguments

   pure function after_command(statement) result(rest)
   !< Text of `statement` after its first word.
   character(len=*), intent(in)  :: statement !< Statement.
   character(len=:), allocatable :: rest      !< Remaining text.
   integer(I4P)                  :: i         !< First blank after the command word.

   rest = trim(adjustl(statement))
   i = scan(rest, ' '//achar(9), kind=I4P)
   if (i == 0_I4P) then
      rest = ''
   else
      rest = trim(adjustl(rest(i:)))
   endif
   endfunction after_command

   function axes_argument(tokens, axes, iostat, iomsg) result(ok)
   !< Optional axes names after a `logscale` option (default all: `xyy2cbx2`); a base other than 10 is an error.
   type(token_object),            intent(in)  :: tokens(:) !< Option tokens.
   character(len=:), allocatable, intent(out) :: axes      !< Axes letters.
   integer(I4P),                  intent(out) :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out) :: iomsg     !< Error message.
   logical                                    :: ok        !< Success.

   iostat = 0_I4P
   iomsg = ''
   axes = 'xyy2cbx2'
   ok = .true.
   if (size(tokens) >= 2) then
      axes = tokens(2)%text
      if (.not. valid_axes(axes)) then
         call fail('logscale: axes among x, y, y2, cb, x2 expected (e.g. y or xy2), found "'//axes//'"', iostat, iomsg)
         ok = .false.
         return
      endif
   endif
   if (size(tokens) >= 3) then
      if (tokens(3)%text /= '10' .or. size(tokens) > 3) then
         call fail('logscale: only base 10 is supported', iostat, iomsg)
         ok = .false.
      endif
   endif
   endfunction axes_argument

   pure subroutine regular_grid(x, y, z, xs, ys, grid, problem)
   !< Gather the points (`x`, `y`, `z`) on a regular grid: the sorted distinct finite abscissae `xs` and ordinates `ys`,
   !< evenly spaced, and the values `grid(i, j)` at (`xs(i)`, `ys(j)`), NaN where no point lies; `problem` if the
   !< points do not lie on such a grid.
   real(R8P),                     intent(in)  :: x(:)      !< Abscissae.
   real(R8P),                     intent(in)  :: y(:)      !< Ordinates.
   real(R8P),                     intent(in)  :: z(:)      !< Values.
   real(R8P), allocatable,        intent(out) :: xs(:)     !< Pixel centre abscissae.
   real(R8P), allocatable,        intent(out) :: ys(:)     !< Pixel centre ordinates.
   real(R8P), allocatable,        intent(out) :: grid(:,:) !< Values.
   character(len=:), allocatable, intent(out) :: problem   !< Problem, empty if none.
   logical, allocatable                       :: ok(:)     !< Placeable points.
   integer(I4P)                               :: k         !< Point counter.
   integer(I4P)                               :: i         !< Column.
   integer(I4P)                               :: j         !< Row.

   problem = ''
   ok = ieee_is_finite(x) .and. ieee_is_finite(y)
   xs = distinct(pack(x, ok))
   ys = distinct(pack(y, ok))
   if (size(xs) == 0 .or. size(ys) == 0) then
      problem = 'no points'
      allocate(grid(0, 0))
      return
   endif
   if (.not. (even(xs) .and. even(ys))) then
      problem = 'the points are not on a regular grid (evenly spaced x and y)'
      allocate(grid(0, 0))
      return
   endif
   allocate(grid(size(xs), size(ys)))
   grid = ieee_value(1.0_R8P, ieee_quiet_nan)
   do k = 1_I4P, size(x, kind=I4P)
      if (.not. ok(k)) cycle
      i = findloc(xs, x(k), dim=1)
      j = findloc(ys, y(k), dim=1)
      grid(i, j) = z(k)
   enddo
   contains
      pure function distinct(v) result(d)
      !< Sorted distinct values of `v`.
      real(R8P), intent(in)  :: v(:) !< Values.
      real(R8P), allocatable :: d(:) !< Distinct values, increasing.
      real(R8P)              :: t    !< Swap buffer.
      integer(I4P)           :: a    !< Counter.
      integer(I4P)           :: b    !< Counter.
      integer(I4P)           :: n    !< Distinct count.

      allocate(d(size(v)))
      n = 0_I4P
      do a = 1_I4P, size(v, kind=I4P)
         if (n > 0_I4P) then
            if (any(d(1:n) == v(a))) cycle
         endif
         n = n + 1_I4P
         d(n) = v(a)
      enddo
      d = d(1:n)
      do a = 2_I4P, n
         t = d(a)
         b = a - 1_I4P
         do while (b >= 1_I4P)
            if (d(b) <= t) exit
            d(b + 1_I4P) = d(b)
            b = b - 1_I4P
         enddo
         d(b + 1_I4P) = t
      enddo
      endfunction distinct

      pure function even(v) result(yes)
      !< Whether the increasing `v` are evenly spaced.
      real(R8P), intent(in) :: v(:) !< Values.
      logical               :: yes  !< Evenly spaced.
      real(R8P)             :: step !< Mean spacing.
      integer(I4P)          :: a    !< Counter.

      yes = .true.
      if (size(v) < 3) return
      step = (v(size(v)) - v(1)) / real(size(v) - 1, R8P)
      do a = 2_I4P, size(v, kind=I4P)
         if (abs(v(a) - v(a - 1_I4P) - step) > 1.0e-6_R8P * step) yes = .false.
      enddo
      endfunction even
   endsubroutine regular_grid

   function style_code(name) result(code)
   !< Style code of a full style name.
   character(len=*), intent(in) :: name !< Full style name.
   integer(I4P)                 :: code !< Style code.

   code = style_with(name)
   endfunction style_code

   pure function smooth_name(word) result(name)
   !< Full name of the `smooth` filter `word`, full or abbreviated as gnuplot 6.0 reads it (its `plot_smooth_tbl`, in
   !< order: `f` frequency, `cum` cumulative, `mcs` mcsplines, `fnor` fnormal, ...); `word` itself if no filter.
   character(len=*), intent(in)  :: word !< Filter word.
   character(len=:), allocatable :: name !< Full filter name.
   character(len=*), parameter :: TABLE(15) = [character(len=12) :: 'a$csplines', 'bins', 'b$ezier', 'c$splines', &
                                               's$bezier', 'u$nique', 'unwrap', 'f$requency', 'cum$ulative', &
                                               'k$density', 'cn$ormal', 'mcs$plines', 'fnor$mal', 'z$sort', 'path']
   integer :: k !< Table entry.

   name = word
   do k = 1, size(TABLE)
      if (gnuplot_abbreviates(word, trim(TABLE(k)))) then
         name = TABLE(k)(1:index(TABLE(k), '$') - 1)//TABLE(k)(index(TABLE(k), '$') + 1:)
         name = trim(name)
         return
      endif
   enddo
   endfunction smooth_name

   pure function canonical_style(word) result(style)
   !< Full gnuplot style name of `word` (full or abbreviated), empty if unsupported.
   character(len=*), intent(in)  :: word  !< Style word.
   character(len=:), allocatable :: style !< Full style name.

   style = style_name(word)
   ! gnuplot's `with table`, the rows written as text (`set table`)
   if (word == 'table') style = 'table'
   endfunction canonical_style

   pure function change_extension(file, ext) result(renamed)
   !< `file` with its extension replaced by `ext` (appended if none).
   character(len=*), intent(in)  :: file    !< File name.
   character(len=*), intent(in)  :: ext     !< New extension.
   character(len=:), allocatable :: renamed !< Renamed file.
   integer(I4P)                  :: dot     !< Last dot.
   integer(I4P)                  :: slash   !< Last slash.

   dot = index(file, '.', back=.true., kind=I4P)
   slash = index(file, '/', back=.true., kind=I4P)
   if (dot > slash) then
      renamed = file(1:dot)//ext
   else
      renamed = file//'.'//ext
   endif
   endfunction change_extension

   pure function extension(file) result(ext)
   !< Lower case extension of `file`, empty if none.
   character(len=*), intent(in)  :: file !< File name.
   character(len=:), allocatable :: ext  !< Extension.
   integer(I4P)                  :: dot  !< Last dot.
   integer(I4P)                  :: i    !< Counter.

   dot = index(file, '.', back=.true., kind=I4P)
   ext = ''
   if (dot == 0_I4P) return
   ext = file(dot + 1_I4P:)
   do i = 1_I4P, len(ext, kind=I4P)
      if (ext(i:i) >= 'A' .and. ext(i:i) <= 'Z') ext(i:i) = achar(iachar(ext(i:i)) + 32)
   enddo
   endfunction extension

   pure function is_multiplot_option(tokens) result(is)
   !< Whether the statement is `set|unset multiplot ...`.
   type(token_object), intent(in) :: tokens(:) !< Statement tokens.
   logical                        :: is        !< It is.

   is = .false.
   if (size(tokens) >= 2) is = keyword(tokens(2)%text, 'multiplot', 5_I4P)
   endfunction is_multiplot_option

   pure subroutine resolve_colors(tokens, iostat, iomsg)
   !< Replace each color string of a statement, a string after `rgb`, `lc`, `fc`, `tc` or `background` (and their
   !< long forms), by its SVG color, as gnuplot reads it (`gnuplot_color`): `"green"` is `#00ff00`, gnuplot's, not
   !< SVG's `#008000`. A string that is no color fails as gnuplot.
   type(token_object),            intent(inout) :: tokens(:) !< Tokens.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   character(len=:), allocatable                :: color     !< SVG color.
   character(len=:), allocatable                :: w         !< Previous word.
   logical                                      :: ok        !< A color.
   integer(I4P)                                 :: i         !< Token counter.

   iostat = 0_I4P
   iomsg = ''
   do i = 2_I4P, size(tokens, kind=I4P)
      if (tokens(i)%kind /= TOKEN_STRING .or. tokens(i - 1_I4P)%kind /= TOKEN_WORD) cycle
      w = tokens(i - 1_I4P)%text
      if (.not. (keyword(w, 'rgbcolor', 3_I4P) .or. w == 'lc' .or. keyword(w, 'linecolor', 5_I4P) .or. &
                 w == 'fc' .or. keyword(w, 'fillcolor', 5_I4P) .or. w == 'tc' .or. keyword(w, 'textcolor', 5_I4P) .or. &
                 keyword(w, 'background', 5_I4P))) cycle
      call gnuplot_color(tokens(i)%text, color, ok)
      ! gnuplot reads "#RRGGBB" by its hex digits, whatever follows (clipobject.dem's "#DDAA00' @fs")
      if (.not. ok .and. len(tokens(i)%text) > 7) then
         if (tokens(i)%text(1:1) == '#' .and. verify(tokens(i)%text(2:7), '0123456789abcdefABCDEF') == 0) then
            if (len(tokens(i)%text) >= 9) then
               if (verify(tokens(i)%text(8:9), '0123456789abcdefABCDEF') == 0) then
                  call gnuplot_color(tokens(i)%text(1:9), color, ok)
               else
                  call gnuplot_color(tokens(i)%text(1:7), color, ok)
               endif
            else
               call gnuplot_color(tokens(i)%text(1:7), color, ok)
            endif
         endif
      endif
      if (.not. ok) then
         call fail('unrecognized color name "'//tokens(i)%text//'" and not a string "#AARRGGBB" or "0xAARRGGBB"', &
                   iostat, iomsg)
         return
      endif
      tokens(i)%text = color
   enddo
   endsubroutine resolve_colors

   pure subroutine fail(message, iostat, iomsg)
   !< Set an error.
   character(len=*),              intent(in)  :: message !< Error message.
   integer(I4P),                  intent(out) :: iostat  !< Set to 1.
   character(len=:), allocatable, intent(out) :: iomsg   !< Set to `message`.

   iostat = 1_I4P
   iomsg = message
   endsubroutine fail

   pure function coordinate_system(word) result(system)
   !< The coordinate system `word` abbreviates (gnuplot's fir$st, sec$ond, gr$aph, sc$reen, char$acter), empty if none.
   character(len=*), intent(in)  :: word   !< Word.
   character(len=:), allocatable :: system !< System name.

   system = ''
   if (keyword(word, 'first', 3_I4P)) system = 'first'
   if (keyword(word, 'second', 3_I4P)) system = 'second'
   if (keyword(word, 'graph', 2_I4P)) system = 'graph'
   if (keyword(word, 'screen', 2_I4P)) system = 'screen'
   if (keyword(word, 'character', 4_I4P)) system = 'character'
   endfunction coordinate_system

   pure function keyword(word, full, minimum) result(match)
   !< Whether `word` abbreviates `full` with at least `minimum` characters, as gnuplot keywords.
   character(len=*), intent(in) :: word    !< Word.
   character(len=*), intent(in) :: full    !< Full keyword.
   integer(I4P),     intent(in) :: minimum !< Shortest accepted abbreviation.
   logical                      :: match   !< Match.

   match = len(word) >= minimum .and. len(word) <= len(full)
   if (match) match = full(1:len(word)) == word
   endfunction keyword

   pure function is_word(word, words) result(found)
   !< Whether `word` is one of the blank separated `words`.
   character(len=*), intent(in) :: word  !< Word.
   character(len=*), intent(in) :: words !< Blank separated words.
   logical                      :: found !< Found.

   found = len(word) > 0 .and. index(' '//words//' ', ' '//word//' ') > 0
   endfunction is_word

   function next_integer(tokens, i, value, iostat, iomsg, symbols) result(ok)
   !< Advance `i` to the next token, which must be an integer.
   type(token_object),            intent(in)    :: tokens(:) !< Tokens.
   integer(I4P),                  intent(inout) :: i         !< Token counter.
   integer(I4P),                  intent(out)   :: value     !< Integer.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   type(symbols_object),          intent(in), optional :: symbols !< User variables: a constant expression too.
   logical                                      :: ok        !< Success.
   character(len=:), allocatable                :: word      !< Token text.

   value = 0_I4P
   ok = next_word(tokens, i, word, iostat, iomsg)
   if (.not. ok) return
   ok = verify(word, '0123456789+-') == 0 .and. scan(word, '0123456789') > 0
   if (ok) then
      read(word, *, iostat=iostat) value
      ok = iostat == 0_I4P
   elseif (present(symbols)) then
      ! a constant expression, `lc i` in a plot for
      block
         real(R8P)                     :: v       !< Value.
         character(len=:), allocatable :: message !< Not a constant.
         integer(I4P)                  :: status  !< Constant status.

         call symbols%constant(word, v, status, message)
         if (status == 0_I4P) ok = abs(v) < 2.0e9_R8P
         if (ok) ok = v == aint(v)
         if (ok) value = int(v, I4P)
      endblock
   endif
   if (.not. ok) call fail('an integer was expected, found "'//word//'"', iostat, iomsg)
   endfunction next_integer

   function clip_words(panel, tokens, on, iostat, iomsg) result(ok)
   !< gnuplot `set clip` (`on`) and `unset clip` words after the option: `points`, `one`, `two`, `radial` (polar:
   !< accepted, foresight clips at the plot area); bare `set clip` is `points`, bare `unset clip` all of them.
   type(axes_object),             intent(inout) :: panel     !< Panel.
   type(token_object),            intent(in)    :: tokens(:) !< Option tokens.
   logical,                       intent(in)    :: on        !< `set`, else `unset`.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   logical                                      :: ok        !< Success.
   integer(I4P)                                 :: k         !< Token counter.

   iostat = 0_I4P
   iomsg = ''
   ok = .true.
   if (size(tokens) == 1) then
      panel%clip_points = on
      if (.not. on) then
         panel%clip_one = .false.
         panel%clip_two = .false.
      endif
      return
   endif
   do k = 2_I4P, size(tokens, kind=I4P)
      select case (tokens(k)%text)
      case ('points')
         panel%clip_points = on
      case ('one')
         panel%clip_one = on
      case ('two')
         panel%clip_two = on
      case ('radial')
         continue
      case default
         call fail('clip: points, one, two or radial expected, not "'//tokens(k)%text//'"', iostat, iomsg)
         ok = .false.
         return
      endselect
   enddo
   endfunction clip_words

   function next_real(tokens, i, value, iostat, iomsg, symbols) result(ok)
   !< Advance `i` to the next token, which must be a number.
   type(token_object),            intent(in)    :: tokens(:) !< Tokens.
   integer(I4P),                  intent(inout) :: i         !< Token counter.
   real(R8P),                     intent(out)   :: value     !< Number.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   type(symbols_object),          intent(in), optional :: symbols !< User variables: a constant expression too.
   logical                                      :: ok        !< Success.
   character(len=:), allocatable                :: word      !< Token text.

   value = 0.0_R8P
   ok = next_word(tokens, i, word, iostat, iomsg)
   if (.not. ok) return
   ok = to_number(word, value)
   if (.not. ok .and. present(symbols)) then
      ! a constant expression, `lw w`
      block
         character(len=:), allocatable :: message !< Not a constant.
         integer(I4P)                  :: status  !< Constant status.

         call symbols%constant(word, value, status, message)
         ok = status == 0_I4P
      endblock
   endif
   if (.not. ok) call fail('a number was expected, found "'//word//'"', iostat, iomsg)
   endfunction next_real

   function next_word(tokens, i, word, iostat, iomsg) result(ok)
   !< Advance `i` to the next token, which must be a bare word.
   type(token_object),            intent(in)    :: tokens(:) !< Tokens.
   integer(I4P),                  intent(inout) :: i         !< Token counter.
   character(len=:), allocatable, intent(out)   :: word      !< Token text.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   logical                                      :: ok        !< Success.

   iostat = 0_I4P
   iomsg = ''
   word = ''
   ok = .false.
   if (i + 1_I4P > size(tokens, kind=I4P)) then
      call fail('"'//tokens(i)%text//'" needs an argument', iostat, iomsg)
      return
   endif
   i = i + 1_I4P
   word = tokens(i)%text
   if (tokens(i)%kind /= TOKEN_WORD) then
      call fail('"'//tokens(i - 1_I4P)%text//'" needs a bare argument, found "'//word//'"', iostat, iomsg)
      return
   endif
   ok = .true.
   endfunction next_word

   function no_more(tokens, from, iostat, iomsg) result(ok)
   !< Error if tokens exist from position `from` on (unsupported sub-options).
   type(token_object),            intent(in)  :: tokens(:) !< Tokens.
   integer(I4P),                  intent(in)  :: from      !< First position that must be empty.
   integer(I4P),                  intent(out) :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out) :: iomsg     !< Error message.
   logical                                    :: ok        !< Success.

   iostat = 0_I4P
   iomsg = ''
   ok = size(tokens, kind=I4P) < from
   if (.not. ok) call fail('"'//tokens(1)%text//'": unsupported sub-option "'//tokens(from)%text//'"', iostat, iomsg)
   endfunction no_more

   subroutine parse_using(spec, fields, iostat, iomsg, degrees, symbols, sampled)
   !< `using` specification: 1 to 6 colon separated fields, each a column number (0 is the point number) or a
   !< parenthesized expression (with the user variables and functions of `symbols`), as in gnuplot; `sampled` names the
   !< sample variables of a pseudo-file (columns 1 and 2).
   character(len=*),                     intent(in)  :: spec      !< Specification.
   type(expression_object), allocatable, intent(out) :: fields(:) !< Fields.
   character(len=:), allocatable,        intent(out) :: iomsg     !< Error message.
   integer(I4P),                         intent(out) :: iostat    !< 0 on success.
   logical,                              intent(in)  :: degrees   !< Angles of the expressions in degrees.
   type(symbols_object),                 intent(inout) :: symbols !< User variables and functions.
   character(len=*),           optional, intent(in)  :: sampled   !< Sample variables of a pseudo-file.
   type(expression_object)                           :: field     !< Current field.
   character(len=:), allocatable                     :: text      !< Current field text (a copy: nvfortran 26.9
                                                                  !< blanks an associate name of a substring).
   integer(I4P)                                      :: start     !< Field start.
   integer(I4P)                                      :: finish    !< Field end.
   integer(I4P)                                      :: depth     !< Parenthesis depth.
   integer(I4P)                                      :: c         !< Column.
   character(len=1)                                  :: quote     !< Open quote, blank if none.

   iostat = 0_I4P
   iomsg = ''
   allocate(fields(0))
   start = 1_I4P
   do while (start <= len(spec) + 1)
      ! the field ends at the first ':' outside parentheses (a ?: inside an expression is not a separator)
      depth = 0_I4P
      quote = ' '
      finish = start
      do while (finish <= len(spec))
         if (quote /= ' ') then
            if (spec(finish:finish) == quote) quote = ' '
         elseif (spec(finish:finish) == '"' .or. spec(finish:finish) == "'") then
            quote = spec(finish:finish)
         else
            if (spec(finish:finish) == '(') depth = depth + 1_I4P
            if (spec(finish:finish) == ')') depth = depth - 1_I4P
            if (spec(finish:finish) == ':' .and. depth == 0_I4P) exit
         endif
         finish = finish + 1_I4P
      enddo
      text = spec(start:finish - 1_I4P)
      if (len(text) > 0 .and. verify(text, '0123456789') == 0 .and. len(text) < 10) then
         read(text, *) c
         call field%set_column(c)
      elseif (is_quoted(text)) then
         ! a column header name, gnuplot `using 1:"residual"`
         call field%set_name(text(2:len(text) - 1))
      elseif (text(1:min(1, len(text))) == '(') then
         ! compiled first, so that an unbalanced expression gets the precise syntax error
         call field%compile(text, iostat, iomsg, degrees=degrees, symbols=symbols, sampled=sampled)
         if (iostat /= 0_I4P) then
            iomsg = 'using: '//iomsg
            return
         endif
         ! a variable a field assigns read when run by the next ones, `(Total = $2+$3, ...):($4/Total)`, as gnuplot
         call symbols%learn_assigned(field)
         if (.not. is_parenthesized(text)) then
            call fail('using: field "'//text//'" must be a single parenthesized expression', iostat, iomsg)
            return
         endif
      elseif (constant_column(text)) then
         ! a constant expression, `using 1:i` in a plot for: a number is the column, a string a header name
         continue
      else
         call fail('using: field "'//text//'" is neither a column number, a "header" nor a parenthesized '// &
                   'expression (write ($2*1e3), not $2*1e3)', iostat, iomsg)
         return
      endif
      call push(fields, field)
      start = finish + 1_I4P
   enddo
   ! the styles check their own fields; `with table` writes any number of them, as gnuplot
   if (size(fields) > 100) call fail('using: "'//spec//'" has more than 100 fields', iostat, iomsg)
   contains
      pure function is_quoted(text) result(yes)
      !< Whether `text` is one quoted string, single or double quotes.
      character(len=*), intent(in) :: text !< Field.
      logical                      :: yes  !< Quoted.

      yes = len(text) >= 2
      if (yes) yes = (text(1:1) == '"' .or. text(1:1) == "'") .and. text(len(text):len(text)) == text(1:1) .and. &
                     index(text(2:len(text) - 1), text(1:1)) == 0
      endfunction is_quoted

      pure function is_parenthesized(text) result(yes)
      !< Whether `text` is one parenthesized group: `(...)`, the first parenthesis closed by the last character.
      character(len=*), intent(in) :: text  !< Field.
      logical                      :: yes   !< Parenthesized.
      integer(I4P)                 :: depth !< Parenthesis depth.
      integer(I4P)                 :: k     !< Character counter.

      yes = .false.
      if (len(text) < 2) return
      if (text(1:1) /= '(') return
      depth = 0_I4P
      do k = 1_I4P, len(text, kind=I4P)
         if (text(k:k) == '(') depth = depth + 1_I4P
         if (text(k:k) == ')') depth = depth - 1_I4P
         if (depth == 0_I4P) exit
      enddo
      yes = k == len(text, kind=I4P)
      endfunction is_parenthesized
      function constant_column(expression) result(ok)
      !< Whether `expression` is a constant giving a column (a whole number >= 0) or a header name; `field` set to it.
      character(len=*), intent(in)  :: expression !< Field text.
      logical                       :: ok         !< A constant column.
      character(len=:), allocatable :: value      !< Its value.
      character(len=:), allocatable :: message    !< Not a constant.
      integer(I4P)                  :: status     !< Constant status.
      logical                       :: is_string  !< A string.
      real(R8P)                     :: v          !< Number.

      ok = .false.
      call symbols%text_of(expression, value, is_string, status, message, degrees=degrees)
      if (status /= 0_I4P) return
      if (is_string) then
         call field%set_name(value)
         ok = .true.
         return
      endif
      call symbols%constant(expression, v, status, message, degrees=degrees)
      if (status /= 0_I4P) return
      if (v < 0.0_R8P .or. v > 1.0e9_R8P .or. v /= aint(v)) return
      call field%set_column(int(v, I4P))
      ok = .true.
      endfunction constant_column
   endsubroutine parse_using

   pure subroutine apply_line_style(styles, id, line, colors)
   !< Apply the line style `id` to `line`: its defined properties; an undefined style is the linetype `id`, as gnuplot.
   type(line_style_object), intent(in)    :: styles(:) !< Defined styles.
   integer(I4P),            intent(in)    :: id        !< Style number.
   type(line_style_object), intent(inout) :: line      !< Line properties.
   character(len=9),        intent(in), optional :: colors(:) !< Active linetype colors (`set colorsequence`).
   integer(I4P)                           :: s         !< Counter.

   do s = 1_I4P, size(styles, kind=I4P)
      if (styles(s)%id /= id) cycle
      if (allocated(styles(s)%lc)) then
         line%lc = styles(s)%lc
         line%palette = styles(s)%palette
      endif
      if (allocated(styles(s)%lw)) line%lw = styles(s)%lw
      if (allocated(styles(s)%dt)) line%dt = styles(s)%dt
      if (allocated(styles(s)%ps)) line%ps = styles(s)%ps
      if (allocated(styles(s)%pt)) line%pt = styles(s)%pt
      if (allocated(styles(s)%pt_char)) line%pt_char = styles(s)%pt_char
      if (allocated(styles(s)%pn)) line%pn = styles(s)%pn
      ! the style's point type when it has none: that of its `lt M`, else of the linetype `id` when predefined, else 1
      if (styles(s)%ptdef > 0_I4P) then
         line%ptdef = styles(s)%ptdef
      elseif (id >= 1_I4P .and. id <= 8_I4P) then
         line%ptdef = id
      else
         line%ptdef = 1_I4P
      endif
      return
   enddo
   if (id >= 1_I4P .and. id <= 8_I4P) line%ptdef = id
   ! gnuplot's special linetypes: black (-1), nodraw (-2), bgnd (-3)
   select case (id)
   case (-1_I4P)
      line%lc = special_color('black')
   case (-2_I4P)
      line%lc = special_color('nodraw')
   case (-3_I4P)
      line%lc = special_color('bgnd')
   case default
      line%lc = default_color(id, colors)
   endselect
   endsubroutine apply_line_style

   function columnhead_title(word, column) result(ok)
   !< Parse `columnhead`, `columnheader` or `columnhead(N)` (gnuplot `title columnhead`): `column` is N, or 0 for the
   !< column of the y field; false if `word` is none of them.
   character(len=*), intent(in)  :: word   !< Title word.
   integer(I4P),     intent(out) :: column !< Header column, 0 for the y one.
   logical                       :: ok     !< Well formed.
   integer(I4P)                  :: open   !< Opening parenthesis.
   integer(I4P)                  :: ios    !< Conversion status.

   column = 0_I4P
   open = index(word, '(', kind=I4P)
   if (open == 0_I4P) then
      ok = keyword(word, 'columnheader', 3_I4P)
      return
   endif
   ok = keyword(word(1:open - 1_I4P), 'columnheader', 3_I4P) .and. word(len(word):len(word)) == ')' .and. &
        len(word) > open + 1
   if (.not. ok) return
   ok = verify(word(open + 1_I4P:len(word) - 1), '0123456789') == 0
   if (ok) then
      read(word(open + 1_I4P:len(word) - 1), *, iostat=ios) column
      ok = ios == 0_I4P .and. column >= 1_I4P
   endif
   endfunction columnhead_title

   pure function function_drawable(with) result(yes)
   !< Whether the style `with` draws a function (FUNCTION_STYLES): not error bars, nor the filled and panel styles.
   character(len=*), intent(in) :: with !< Full style name.
   logical                      :: yes  !< Usable for functions.

   yes = is_word(with, 'lines points linespoints impulses steps fsteps histeps dots boxes filledcurves pm3d')
   endfunction function_drawable

   pure function colormap_index(self, name) result(k)
   !< Index of the colormap `name` (`set colormap new NAME`), 0 if none.
   class(script_object), intent(in) :: self !< Interpreter.
   character(len=*),     intent(in) :: name !< Colormap name.
   integer(I4P)                     :: k    !< Index.

   k = 0_I4P
   if (allocated(self%colormap_names)) k = findloc_name(self%colormap_names, name)
   endfunction colormap_index

   pure function plain_data_format(format) result(plain)
   !< Whether the data `format` of a using spec is blank separated numeric scanf conversions (`%lf %lf`):
   !< the default reading (a skipped column, `%*lf`, is not).
   character(len=*), intent(in) :: format !< Format.
   logical                      :: plain  !< Plain conversions.
   integer(I4P)                 :: k      !< Character counter.
   integer(I4P)                 :: e      !< Conversion end.

   plain = len_trim(format) > 0
   k = 1_I4P
   do while (plain .and. k <= len_trim(format, kind=I4P))
      if (format(k:k) == ' ' .or. format(k:k) == achar(9)) then
         k = k + 1_I4P
         cycle
      endif
      e = k
      do while (e <= len_trim(format, kind=I4P))
         if (format(e:e) == ' ' .or. format(e:e) == achar(9)) exit
         e = e + 1_I4P
      enddo
      plain = is_word(format(k:e - 1_I4P), '%lf %f %le %e %lg %g')
      k = e
   enddo
   endfunction plain_data_format

   pure function findloc_name(names, name) result(k)
   !< Index of `name` among `names`, 0 if absent (a loop: nvfortran 26.9 refuses findloc on some arrays). `names` is
   !< not allocatable: with a `character(len=*), allocatable` array dummy here, nvfortran 26.9 -O2 miscompiled the
   !< internal procedures of annotation_option (set label|arrow|object positions read wrong, bug 24).
   character(len=*), intent(in) :: names(:) !< Names.
   character(len=*), intent(in) :: name     !< Name.
   integer(I4P)                 :: k        !< Index.
   integer(I4P)                 :: j        !< Counter.

   k = 0_I4P
   do j = 1_I4P, size(names, kind=I4P)
      if (trim(names(j)) == name) then
         k = j
         return
      endif
   enddo
   endfunction findloc_name

   pure function in_wedge(t, tmin, tmax) result(inside)
   !< Whether the angle `t` [deg] lies in the wedge from `tmin` to `tmax` [deg] (gnuplot's in_theta_wedge).
   real(R8P), intent(in) :: t      !< Angle.
   real(R8P), intent(in) :: tmin   !< Wedge start.
   real(R8P), intent(in) :: tmax   !< Wedge end.
   logical               :: inside !< Within.

   inside = .true.
   if (tmax - tmin >= 360.0_R8P) return
   if (tmin >= 0.0_R8P .and. tmax <= 360.0_R8P) then
      inside = tmin <= t .and. t <= tmax
      return
   endif
   if (tmin < 0.0_R8P .and. (t < tmax .or. t > tmin + 360.0_R8P)) return
   if (tmax > 360.0_R8P .and. (t > tmin .or. t < tmax - 360.0_R8P)) return
   inside = .false.
   endfunction in_wedge

   pure function is_item_option(word) result(is)
   !< Whether `word` is a plot item option: it ends a function expression.
   character(len=*), intent(in) :: word !< Word.
   logical                      :: is   !< Item option.

   is = keyword(word, 'using', 1_I4P) .or. keyword(word, 'index', 1_I4P) .or. keyword(word, 'every', 2_I4P) .or. &
        keyword(word, 'with', 1_I4P) .or. keyword(word, 'title', 1_I4P) .or. keyword(word, 'notitle', 3_I4P) .or. &
        keyword(word, 'axes', 2_I4P) .or. keyword(word, 'smooth', 1_I4P) .or. word == 'ls' .or. &
        keyword(word, 'linestyle', 5_I4P) .or. is_line_option(word) .or. word == 'format' .or. word == 'fs' .or. &
        word == 'fill' .or. word == 'nocontours' .or. word == 'nosurface' .or. word == 'nogrid' .or. word == 'mask' .or. &
        keyword(word, 'fillstyle', 5_I4P) .or. keyword(word, 'matrix', 3_I4P) .or. keyword(word, 'whiskerbars', 7_I4P) &
        .or. word == 'bins' .or. index(word, 'bins=') == 1 .or. word == 'noenhanced' .or. word == 'enhanced' .or. &
        word == 'sharpen' .or. word == 'volatile' .or. keyword(word, 'noautoscale', 6_I4P) .or. word == 'convexhull' &
        .or. word == 'concavehull' .or. word == 'delaunay'
   endfunction is_item_option

   pure function is_line_option(word) result(is)
   !< Whether `word` names a line property: `lc`, `lt`, `lw`, `dt`, `ps`, `pt` or their long forms.
   character(len=*), intent(in) :: word !< Option word.
   logical                      :: is   !< Line property.

   is = word == 'lc' .or. keyword(word, 'linecolor', 5_I4P) .or. word == 'lt' .or. keyword(word, 'linetype', 5_I4P) &
        .or. word == 'lw' .or. keyword(word, 'linewidth', 5_I4P) .or. word == 'dt' .or. keyword(word, 'dashtype', 5_I4P) &
        .or. word == 'ps' .or. keyword(word, 'pointsize', 6_I4P) .or. word == 'pt' .or. keyword(word, 'pointtype', 6_I4P) &
        .or. word == 'pi' .or. keyword(word, 'pointinterval', 6_I4P) .or. word == 'pn' &
        .or. keyword(word, 'pointnumber', 6_I4P)
   endfunction is_line_option

   pure function special_color(word) result(color)
   !< SVG color of gnuplot's special linetypes: `black`, `nodraw` (nothing drawn), `bgnd` (the background, white).
   character(len=*), intent(in)  :: word  !< Special name.
   character(len=:), allocatable :: color !< SVG color.

   select case (word)
   case ('nodraw')
      color = 'none'
   case ('bgnd', 'background')
      color = '#ffffff'
   case default
      color = '#000000'
   endselect
   endfunction special_color

   pure function argb_color(v) result(color)
   !< The SVG color of gnuplot's number 0xAARRGGBB: `#rrggbb`, or `#rrggbbaa` with the opacity 255 - AA (AA the
   !< transparency, 0 opaque).
   real(R8P), intent(in)         :: v     !< Color number.
   character(len=:), allocatable :: color !< SVG color.
   character(len=*), parameter   :: HEX = '0123456789abcdef' !< Digits.
   integer(I8P)                  :: code  !< RGB, then opacity.
   integer(I4P)                  :: d     !< Digit counter.
   integer(I4P)                  :: digit !< A digit.

   color = '#000000'
   if (.not. ieee_is_finite(v)) return
   code = iand(int(v, I8P), int(z'FFFFFF', I8P))
   do d = 5_I4P, 0_I4P, -1_I4P
      digit = int(iand(ishft(code, -4_I4P * d), 15_I8P), I4P)
      color(7 - d:7 - d) = HEX(digit + 1:digit + 1)
   enddo
   code = 255_I8P - iand(ishft(int(v, I8P), -24_I4P), 255_I8P)
   if (code < 255_I8P) color = color//HEX(code / 16_I8P + 1_I8P:code / 16_I8P + 1_I8P)// &
                               HEX(mod(code, 16_I8P) + 1_I8P:mod(code, 16_I8P) + 1_I8P)
   endfunction argb_color

   function line_option(tokens, i, line, iostat, iomsg, colors, symbols) result(ok)
   !< Parse the line property at `tokens(i)` and its value into `line`, leaving `i` on the value's last token:
   !< `lc [rgb] "color"`, `lc N`, `lc [rgb] variable` (the color column marker), `lc palette [z|cb V|frac F]` (markers,
   !< the value in `line%palette`), `lt N` (linetype color N), `lw W`,
   !< `dt N`, `ps S`, `pt N`.
   type(token_object),            intent(in)    :: tokens(:) !< Tokens.
   integer(I4P),                  intent(inout) :: i         !< Token counter.
   type(line_style_object),       intent(inout) :: line      !< Line properties.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   character(len=9),              intent(in), optional :: colors(:) !< Active linetype colors (`set colorsequence`).
   type(symbols_object),          intent(in), optional :: symbols   !< User variables: `lc i`, `lw w`.
   logical                                      :: ok        !< Success.
   character(len=:), allocatable                :: word      !< Property word.
   integer(I4P)                                 :: number    !< Integer value.
   real(R8P)                                    :: value     !< Real value.
   logical                                      :: rgb       !< `lc rgb`.

   word = tokens(i)%text
   iostat = 0_I4P
   iomsg = ''
   ok = .true.
   ! `lt rgb COLOR` (and `lt palette`): gnuplot's line color given after lt
   if (word == 'lt' .or. keyword(word, 'linetype', 5_I4P)) then
      if (i < size(tokens, kind=I4P)) then
         if (tokens(i + 1_I4P)%kind == TOKEN_WORD .and. (keyword(tokens(i + 1_I4P)%text, 'rgbcolor', 3_I4P) .or. &
                                                        keyword(tokens(i + 1_I4P)%text, 'palette', 3_I4P))) word = 'lc'
      endif
   endif
   if (word == 'lc' .or. keyword(word, 'linecolor', 5_I4P)) then
      i = i + 1_I4P
      rgb = .false.
      if (i <= size(tokens, kind=I4P)) then
         if (tokens(i)%kind == TOKEN_WORD .and. keyword(tokens(i)%text, 'rgbcolor', 3_I4P)) then
            i = i + 1_I4P
            rgb = .true.
         endif
      endif
      if (i > size(tokens, kind=I4P)) then
         call fail('lc needs a color', iostat, iomsg)
         ok = .false.
      elseif (tokens(i)%kind == TOKEN_WORD .and. keyword(tokens(i)%text, 'variable', 3_I4P)) then
         ! the colors from the last using column: linetype numbers, or 24-bit RGB with rgb (gnuplot)
         line%lc = trim(merge(LC_RGB_VARIABLE, LC_VARIABLE, rgb))
      elseif (tokens(i)%kind == TOKEN_WORD .and. keyword(tokens(i)%text, 'palette', 3_I4P) .and. .not. rgb) then
         ! the palette: by the last using column (z, the default), a color axis value (cb V) or a fraction (frac F)
         line%lc = trim(LC_PALETTE_Z)
         if (i < size(tokens, kind=I4P)) then
            if (tokens(i + 1_I4P)%kind == TOKEN_WORD) then
               select case (tokens(i + 1_I4P)%text)
               case ('z')
                  i = i + 1_I4P
               case ('cb')
                  i = i + 1_I4P
                  ok = next_real(tokens, i, line%palette, iostat, iomsg)
                  line%lc = trim(LC_PALETTE_CB)
               case ('frac')
                  i = i + 1_I4P
                  ok = next_real(tokens, i, line%palette, iostat, iomsg)
                  if (ok .and. (line%palette < 0.0_R8P .or. line%palette > 1.0_R8P)) then
                     call fail('lc palette frac needs a fraction from 0 to 1', iostat, iomsg)
                     ok = .false.
                  endif
                  line%lc = trim(LC_PALETTE_FRAC)
               case default
                  ! a named colormap (gnuplot `set colormap new NAME`): z colored by it
                  if (.not. (is_item_option(tokens(i + 1_I4P)%text) .or. &
                             is_line_option(tokens(i + 1_I4P)%text))) then
                     i = i + 1_I4P
                     line%colormap = tokens(i)%text
                  endif
               endselect
            endif
         endif
      elseif (tokens(i)%kind == TOKEN_STRING) then
         line%lc = tokens(i)%text
      elseif (tokens(i)%kind == TOKEN_WORD .and. is_word(tokens(i)%text, 'bgnd background nodraw black')) then
         line%lc = special_color(tokens(i)%text)
      elseif (rgb) then
         ! `lc rgb 0xAARRGGBB`: a number (an expression), the color itself, as gnuplot (colornames)
         block
            real(R8P) :: v !< Color number.

            i = i - 1_I4P
            ok = next_real(tokens, i, v, iostat, iomsg, symbols)
            if (ok) line%lc = argb_color(v)
         endblock
      else
         i = i - 1_I4P
         ok = next_integer(tokens, i, number, iostat, iomsg, symbols)
         if (ok) line%lc = default_color(number, colors)
      endif
   elseif (word == 'lt' .or. keyword(word, 'linetype', 5_I4P)) then
      ! gnuplot's special linetypes: black (-1), nodraw (-2), bgnd (-3)
      if (i < size(tokens, kind=I4P)) then
         if (tokens(i + 1_I4P)%kind == TOKEN_WORD .and. is_word(tokens(i + 1_I4P)%text, 'bgnd background nodraw black')) then
            i = i + 1_I4P
            line%lc = special_color(tokens(i)%text)
            return
         endif
      endif
      ok = next_integer(tokens, i, number, iostat, iomsg, symbols)
      if (ok) then
         ! the special linetypes are solid: no dashes of the item's default linetype (gnuplot)
         if (number < 0_I4P .and. number >= -3_I4P) line%dt = 1_I4P
         select case (number)
         case (-1_I4P)
            line%lc = special_color('black')
         case (-2_I4P)
            line%lc = special_color('nodraw')
         case (-3_I4P)
            line%lc = special_color('bgnd')
         case default
            line%lc = default_color(number, colors)
            ! gnuplot's eight predefined linetypes carry point types 1..8; a higher one keeps the item's own
            if (number >= 1_I4P .and. number <= 8_I4P) line%ptdef = number
         endselect
      endif
   elseif (word == 'lw' .or. keyword(word, 'linewidth', 5_I4P)) then
      ok = next_real(tokens, i, value, iostat, iomsg, symbols)
      if (ok) line%lw = value
   elseif (word == 'dt' .or. keyword(word, 'dashtype', 5_I4P)) then
      ! a number, a dash string (`dt "-."`, or a string variable, `dt new`) or the lengths (`dt (50,6,2,6)`)
      block
         character(len=:), allocatable :: spec    !< Custom pattern.
         character(len=:), allocatable :: message !< Not a string.
         integer(I4P)                  :: status  !< String status.
         logical                       :: is_string !< A string.

         spec = ''
         if (i < size(tokens, kind=I4P)) then
            if (tokens(i + 1_I4P)%kind == TOKEN_STRING) then
               spec = tokens(i + 1_I4P)%text
               if (len(spec) == 0) spec = ' '
            elseif (tokens(i + 1_I4P)%kind == TOKEN_WORD .and. tokens(i + 1_I4P)%text(1:1) == '(') then
               spec = tokens(i + 1_I4P)%text
            elseif (tokens(i + 1_I4P)%kind == TOKEN_WORD .and. present(symbols)) then
               call symbols%text_of(tokens(i + 1_I4P)%text, spec, is_string, status, message)
               if (status /= 0_I4P .or. .not. is_string) spec = ''
               if (status == 0_I4P .and. is_string .and. len(spec) == 0) spec = ' '
            endif
         endif
         if (i < size(tokens, kind=I4P) .and. len(spec) == 0) then
            ! gnuplot's `dt solid`: dash type 1
            if (tokens(i + 1_I4P)%kind == TOKEN_WORD .and. tokens(i + 1_I4P)%text == 'solid') then
               i = i + 1_I4P
               line%dt = 1_I4P
               ok = .true.
               return
            endif
         endif
         if (len(spec) > 0) then
            i = i + 1_I4P
            line%dt = custom_dashtype(spec, ok)
            if (.not. ok) call fail('dt: a dash pattern of . - _ and blanks, or (solid, empty, ...) lengths, is '// &
                                    'expected, found "'//tokens(i)%text//'"', iostat, iomsg)
         else
            ok = next_integer(tokens, i, number, iostat, iomsg, symbols)
            if (ok) line%dt = number
         endif
      endblock
   elseif (word == 'pi' .or. keyword(word, 'pointinterval', 6_I4P)) then
      ! a point every |N|, a negative N with the line blanked under the points (gnuplot)
      ok = next_integer(tokens, i, number, iostat, iomsg, symbols)
      if (ok .and. number == 0_I4P) then
         call fail('pointinterval: N not 0 is expected', iostat, iomsg)
         ok = .false.
      endif
      if (ok) line%pi = number
   elseif (word == 'pn' .or. keyword(word, 'pointnumber', 6_I4P)) then
      ! about N points evenly spread (the negative N's line gap not drawn), as gnuplot
      ok = next_integer(tokens, i, number, iostat, iomsg, symbols)
      if (ok) line%pn = abs(number)
   elseif ((word == 'pt' .or. keyword(word, 'pointtype', 6_I4P)) .and. string_next()) then
      ! gnuplot `pt "c"`: the first character of the string as the point
      i = i + 1_I4P
      line%pt_char = first_character(tokens(i)%text)
      ok = .true.
   elseif (word == 'pt' .or. keyword(word, 'pointtype', 6_I4P)) then
      ok = next_integer(tokens, i, number, iostat, iomsg, symbols)
      if (ok .and. number < 0_I4P) then
         call fail('pt needs a point type >= 0, not '//int_str(int(number, I8P)), iostat, iomsg)
         ok = .false.
      endif
      if (ok) line%pt = number
   else
      ok = next_real(tokens, i, value, iostat, iomsg, symbols)
      if (ok) line%ps = value
   endif
   contains
      function string_next() result(yes)
      !< Whether the token after `i` is a quoted string.
      logical :: yes !< A string follows.

      yes = .false.
      if (i < size(tokens, kind=I4P)) yes = tokens(i + 1_I4P)%kind == TOKEN_STRING
      endfunction string_next

      pure function first_character(text) result(c)
      !< The first character of `text`, UTF-8 (1 to 4 bytes); empty for an empty text.
      character(len=*), intent(in)  :: text !< Text.
      character(len=:), allocatable :: c    !< First character.
      integer(I4P)                  :: b    !< Its first byte.
      integer(I4P)                  :: n    !< Its bytes.

      c = ''
      if (len(text) == 0) return
      b = iachar(text(1:1))
      n = 1_I4P
      if (b >= 240) then
         n = 4_I4P
      elseif (b >= 224) then
         n = 3_I4P
      elseif (b >= 192) then
         n = 2_I4P
      endif
      c = text(1:min(n, len(text, kind=I4P)))
      endfunction first_character
   endfunction line_option

   pure subroutine matrix_every(z, every, sub, cx, ry)
   !< The submatrix of `z(column, row)` gnuplot's `every` keeps: the columns as the points (point_incr, start_point,
   !< end_point), the rows as the blocks (block_incr, start_block, end_block), from 0; `cx`, `ry` their indices.
   real(R8P),              intent(in)  :: z(:,:)   !< Matrix.
   integer(I4P),           intent(in)  :: every(6) !< `every` fields, ends -1 for none.
   real(R8P), allocatable, intent(out) :: sub(:,:) !< Submatrix.
   real(R8P), allocatable, intent(out) :: cx(:)    !< Its column indices.
   real(R8P), allocatable, intent(out) :: ry(:)    !< Its row indices.
   integer(I4P), allocatable           :: cols(:)  !< Columns kept (from 1).
   integer(I4P), allocatable           :: rows(:)  !< Rows kept (from 1).
   integer(I4P)                        :: last     !< Last index.
   integer(I4P)                        :: k        !< Counter.

   last = size(z, 1, kind=I4P) - 1_I4P
   if (every(5) >= 0_I4P) last = min(last, every(5))
   cols = [(k + 1_I4P, k = every(3), last, max(1_I4P, every(1)))]
   last = size(z, 2, kind=I4P) - 1_I4P
   if (every(6) >= 0_I4P) last = min(last, every(6))
   rows = [(k + 1_I4P, k = every(4), last, max(1_I4P, every(2)))]
   sub = z(cols, rows)
   cx = real(cols - 1_I4P, R8P)
   ry = real(rows - 1_I4P, R8P)
   endsubroutine matrix_every

   subroutine parse_every(spec, every, iostat, iomsg, symbols)
   !< gnuplot `every point_incr:block_incr:start_point:start_block:end_point:end_block`; empty or missing fields keep
   !< their defaults (1, 1, 0, 0, no end, no end); with `symbols` a field may be an expression, `every ::j:0:j:0`.
   character(len=*),              intent(in)           :: spec     !< Specification.
   integer(I4P),                  intent(out)          :: every(6) !< Fields, ends -1 for none.
   integer(I4P),                  intent(out)          :: iostat   !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg    !< Error message.
   type(symbols_object),          intent(in), optional :: symbols  !< User variables and functions.
   integer(I4P)                                        :: start    !< Field start.
   integer(I4P)                                        :: colon    !< Field end.
   integer(I4P)                                        :: f        !< Field counter.
   logical                                             :: ok       !< Field valid.
   real(R8P)                                           :: v        !< Field value.

   iostat = 0_I4P
   iomsg = ''
   every = [1_I4P, 1_I4P, 0_I4P, 0_I4P, -1_I4P, -1_I4P]
   ok = verify(spec, '0123456789:') == 0
   if (.not. ok .and. present(symbols)) then
      ! expressions in the fields: each evaluated now
      ok = .true.
      start = 1_I4P
      f = 0_I4P
      do while (ok .and. start <= len(spec) + 1)
         f = f + 1_I4P
         colon = index(spec(start:), ':', kind=I4P)
         if (colon == 0_I4P) then
            colon = len(spec, kind=I4P) + 1_I4P
         else
            colon = start + colon - 1_I4P
         endif
         ok = f <= 6_I4P
         if (ok .and. len_trim(spec(start:colon - 1_I4P)) > 0) then
            call symbols%constant(spec(start:colon - 1_I4P), v, iostat, iomsg)
            if (iostat /= 0_I4P) then
               iomsg = 'plot: every: '//iomsg
               return
            endif
            ok = v >= 0.0_R8P .and. v < 1.0e9_R8P
            if (ok) every(f) = int(v, I4P)
         endif
         start = colon + 1_I4P
      enddo
      if (ok) ok = every(1) > 0_I4P .and. every(2) > 0_I4P
      if (.not. ok) call fail('plot: every needs up to 6 non-negative integers separated by ":", positive increments '// &
                              '(point_incr:block_incr:start_point:start_block:end_point:end_block), not "'//spec//'"', &
                              iostat, iomsg)
      return
   endif
   start = 1_I4P
   f = 0_I4P
   do while (ok .and. start <= len(spec) + 1)
      f = f + 1_I4P
      colon = index(spec(start:), ':', kind=I4P)
      if (colon == 0_I4P) then
         colon = len(spec, kind=I4P) + 1_I4P
      else
         colon = start + colon - 1_I4P
      endif
      ok = f <= 6_I4P .and. colon - start < 10_I4P
      if (ok .and. colon > start) read(spec(start:colon - 1_I4P), *) every(f)
      start = colon + 1_I4P
   enddo
   if (ok) ok = every(1) > 0_I4P .and. every(2) > 0_I4P
   if (.not. ok) call fail('plot: every needs up to 6 non-negative integers separated by ":", positive increments '// &
                           '(point_incr:block_incr:start_point:start_block:end_point:end_block), not "'//spec//'"', &
                           iostat, iomsg)
   endsubroutine parse_every

   pure function plain_columns(columns) result(fields)
   !< `using` fields of plain columns.
   integer(I4P),            intent(in) :: columns(:)             !< Columns.
   type(expression_object)             :: fields(size(columns)) !< Fields.
   integer(I4P)                        :: f                      !< Counter.

   do f = 1_I4P, size(columns, kind=I4P)
      call fields(f)%set_column(columns(f))
   enddo
   endfunction plain_columns

   pure function sum_head(token) result(yes)
   !< Whether `token` ends with gnuplot's `sum`, its range next: `sum [i=1:n] term`, `2*sum [i=1:n] term`.
   type(token_object), intent(in) :: token !< Token.
   logical                        :: yes   !< A sum head.
   integer(I4P)                   :: n     !< Length.

   yes = .false.
   if (token%kind /= TOKEN_WORD) return
   n = len(token%text, kind=I4P)
   if (n < 3_I4P) return
   if (token%text(n - 2_I4P:n) /= 'sum') return
   yes = n == 3_I4P
   if (.not. yes) yes = scan(token%text(n - 3_I4P:n - 3_I4P), &
                             UNAME_CHARS//'$') == 0
   endfunction sum_head

   function expression_end(tokens, first) result(last)
   !< Last token of the expression starting at token `first`: tokens join where an operator lies between them (a word
   !< ending or starting with one of `.+-*/%?:<>=!&|`, or `eq`, `ne`), and a range glued to its left neighbour is a
   !< substring, `s[1:2]`: `"run".i.".dat"`, `'f' . i`, `sprintf("%d", n)`.
   type(token_object), intent(in) :: tokens(:) !< Tokens.
   integer(I4P),       intent(in) :: first     !< First token.
   integer(I4P)                   :: last      !< Last token.

   last = first
   do while (last < size(tokens, kind=I4P))
      if (.not. joined(tokens(last), tokens(last + 1_I4P))) exit
      last = last + 1_I4P
   enddo
   contains
      pure function joined(a, b) result(yes)
      !< Whether `b` continues the expression ending with `a`.
      type(token_object), intent(in) :: a   !< Left token.
      type(token_object), intent(in) :: b   !< Right token.
      logical                        :: yes !< Joined.
      character(len=*), parameter    :: OPERATORS = '.+-*/%?:<>=!&|^~' !< Operator characters.

      yes = .false.
      if (a%kind == TOKEN_COMMA .or. b%kind == TOKEN_COMMA) return
      if (b%kind == TOKEN_RANGE) then
         yes = b%first == a%last + 1_I4P
         return
      endif
      if (a%kind == TOKEN_WORD .and. len(a%text) > 0) then
         yes = scan(a%text(len(a%text):len(a%text)), OPERATORS) > 0 .or. a%text == 'eq' .or. a%text == 'ne'
         ! a number ending with its point (`4.`) ends there, the point is no `.` operator
         if (yes .and. a%text(len(a%text):len(a%text)) == '.' .and. len(a%text) > 1) then
            if (verify(a%text, '0123456789.') == 0) yes = .false.
         endif
      endif
      if (b%kind == TOKEN_WORD .and. len(b%text) > 0 .and. .not. yes) then
         yes = scan(b%text(1:1), OPERATORS) > 0 .or. b%text == 'eq' .or. b%text == 'ne'
      endif
      endfunction joined
   endfunction expression_end

   pure function expression_source(tokens) result(source)
   !< Expression text of `tokens`: quoted strings quoted again (escapes restored in double quotes), ranges bracketed.
   type(token_object), intent(in) :: tokens(:) !< Tokens.
   character(len=:), allocatable  :: source    !< Expression.
   integer(I4P)                   :: k         !< Token counter.
   integer(I4P)                   :: c         !< Character counter.

   source = ''
   do k = 1_I4P, size(tokens, kind=I4P)
      select case (tokens(k)%kind)
      case (TOKEN_STRING)
         if (tokens(k)%quote == "'") then
            source = source//" '"//tokens(k)%text//"'"
         else
            source = source//' "'
            do c = 1_I4P, len(tokens(k)%text, kind=I4P)
               select case (tokens(k)%text(c:c))
               case ('"', '\')
                  source = source//'\'//tokens(k)%text(c:c)
               case (achar(9))
                  source = source//'\t'
               case default
                  source = source//tokens(k)%text(c:c)
               endselect
            enddo
            source = source//'"'
         endif
      case (TOKEN_RANGE)
         source = source//'['//tokens(k)%text//']'
      case default
         source = source//' '//tokens(k)%text
      endselect
   enddo
   source = trim(adjustl(source))
   endfunction expression_source

   pure function valid_axes(names) result(ok)
   !< Whether `names` concatenates supported axis names: x, y, y2, cb, x2.
   character(len=*), intent(in)  :: names !< Axis names.
   logical                       :: ok    !< Supported.
   character(len=:), allocatable :: bad   !< Unsupported rest.
   logical                       :: named(5) !< x, y, y2, cb, x2 named.

   named = .false.
   call axes_names(names, named(1), named(2), named(3), bad, cb=named(4), x2=named(5))
   ok = len(names) > 0 .and. len(bad) == 0
   endfunction valid_axes

   subroutine sharpened(func, x, y, sx, sy)
   !< gnuplot 6.0's sharpen filter: the samples `x`, `y` of `func` with the truncated extrema added, found by a
   !< golden section search between the neighbours of a sample lower (higher) than the two on each side where the
   !< 5-term Savitzky-Golay second derivative two samples away is negative (positive), as gnuplot (filters.c).
   type(expression_object), intent(inout)            :: func  !< Function.
   real(R8P),               intent(in)               :: x(:)  !< Sample abscissae.
   real(R8P),               intent(in)               :: y(:)  !< Sample values.
   real(R8P), allocatable,  intent(out)              :: sx(:) !< Abscissae, ascending.
   real(R8P), allocatable,  intent(out)              :: sy(:) !< Values.
   real(R8P), parameter                              :: BIG = 1.0e300_R8P !< gnuplot's VERYLARGE stand-in.
   real(R8P), allocatable                            :: p(:)  !< Values for the search: infinities large, other
                                                              !< undefined values 0.
   logical,   allocatable                            :: undefined(:) !< Undefined samples.
   real(R8P)                                         :: hx    !< Extremum abscissa.
   real(R8P)                                         :: hy    !< Extremum value.
   real(R8P)                                         :: t     !< Swap buffer.
   integer(I4P)                                      :: n     !< Samples.
   integer(I4P)                                      :: i     !< Sample counter.
   integer(I4P)                                      :: k     !< Sort counter.
   integer(I4P)                                      :: pass  !< 1 minima, 2 maxima.

   sx = x
   sy = y
   n = size(x, kind=I4P)
   if (n < 9_I4P) return
   p = y
   allocate(undefined(n))
   undefined = .not. ieee_is_finite(y)
   do i = 1_I4P, n
      if (ieee_is_nan(y(i))) then
         p(i) = 0.0_R8P
      elseif (.not. ieee_is_finite(y(i))) then
         p(i) = sign(BIG, y(i))
         undefined(i) = .false.
      endif
   enddo
   do pass = 1_I4P, 2_I4P
      do i = 5_I4P, n - 4_I4P
         if (pass == 1_I4P) then
            if (.not. (fpp(i - 2_I4P) < 0.0_R8P .or. fpp(i + 2_I4P) < 0.0_R8P)) cycle
            if (.not. (p(i) <= p(i - 1_I4P) .and. p(i) <= p(i + 1_I4P) .and. p(i) <= p(i - 2_I4P) .and. &
                       p(i) <= p(i + 2_I4P))) cycle
         else
            if (any(undefined(i - 1_I4P:i + 1_I4P))) cycle
            if (.not. (fpp(i - 2_I4P) > 0.0_R8P .or. fpp(i + 2_I4P) > 0.0_R8P)) cycle
            if (.not. (p(i) >= p(i - 1_I4P) .and. p(i) >= p(i + 1_I4P) .and. p(i) >= p(i - 2_I4P) .and. &
                       p(i) >= p(i + 2_I4P))) cycle
         endif
         hx = x(i)
         hy = p(i)
         call golden(pass == 2_I4P, x(i - 1_I4P), x(i + 1_I4P), hx, hy)
         sx = [sx, hx]
         sy = [sy, hy]
      enddo
   enddo
   ! in order
   do i = 2_I4P, size(sx, kind=I4P)
      k = i
      do while (k > 1_I4P)
         if (sx(k - 1_I4P) <= sx(k)) exit
         t = sx(k)
         sx(k) = sx(k - 1_I4P)
         sx(k - 1_I4P) = t
         t = sy(k)
         sy(k) = sy(k - 1_I4P)
         sy(k - 1_I4P) = t
         k = k - 1_I4P
      enddo
   enddo
   contains
      function fpp(c) result(d)
      !< Second derivative at sample `c` (5-term Savitzky-Golay, not normalized), 0 at an undefined sample.
      integer(I4P), intent(in) :: c !< Centre sample.
      real(R8P)                :: d !< Second derivative.

      d = 0.0_R8P
      if (undefined(c)) return
      d = (2.0_R8P * p(c - 2_I4P) - p(c - 1_I4P) - 2.0_R8P * p(c) - p(c + 1_I4P) + 2.0_R8P * p(c + 2_I4P)) / 7.0_R8P
      endfunction fpp

      subroutine golden(maximize, xlow, xhigh, xhit, yhit)
      !< Golden section search of the minimum (maximum) of `func` in [xlow, xhigh] from `xhit`, as gnuplot's
      !< bisect_hit.
      logical,   intent(in)    :: maximize !< Search a maximum.
      real(R8P), intent(in)    :: xlow     !< Interval start.
      real(R8P), intent(in)    :: xhigh    !< Interval end.
      real(R8P), intent(inout) :: xhit     !< Start, then the extremum abscissa.
      real(R8P), intent(inout) :: yhit     !< Its value.
      real(R8P), parameter     :: PHIM1 = 0.618034_R8P !< gnuplot's golden ratio - 1.
      real(R8P), parameter     :: EPSILON = 1.0e-14_R8P !< Relative tolerance.
      real(R8P)                :: x0, x1, x2, x3 !< Bracket.
      real(R8P)                :: f1, f2         !< Values at x1, x2.
      logical                  :: left           !< Move the bracket right.
      integer(I4P)             :: it             !< Iteration guard.

      x0 = xlow
      x3 = xhigh
      if (abs(xhigh - xhit) > abs(xhit - xlow)) then
         x1 = xhit
         x2 = xhit + (1.0_R8P - PHIM1) * (xhigh - xhit)
      else
         x2 = xhit
         x1 = xhit - (1.0_R8P - PHIM1) * (xhit - xlow)
      endif
      f1 = func%value_at(x1)
      f2 = func%value_at(x2)
      it = 0_I4P
      do while (abs(x3 - x0) > EPSILON * (abs(x1) + abs(x2)) .and. it < 500_I4P)
         it = it + 1_I4P
         if (maximize) then
            left = f2 > f1
         else
            left = f2 < f1
         endif
         if (left) then
            x0 = x1
            x1 = x2
            x2 = PHIM1 * x2 + (1.0_R8P - PHIM1) * x3
            f1 = f2
            f2 = func%value_at(x2)
         else
            x3 = x2
            x2 = x1
            x1 = PHIM1 * x1 + (1.0_R8P - PHIM1) * x0
            f2 = f1
            f1 = func%value_at(x1)
         endif
         if (abs(x1) + abs(x2) < EPSILON) exit
      enddo
      ! as gnuplot: the better of the last two
      if (maximize .eqv. (f1 > f2)) then
         xhit = x1
         yhit = f1
      else
         xhit = x2
         yhit = f2
      endif
      endsubroutine golden
   endsubroutine sharpened

   subroutine above_below_base(curve, base, band)
   !< gnuplot's `filledcurves above|below` without y=V nor a band: above or below y = 0; with an axis (`above x1`)
   !< the words are dropped, the curve filled to the axis (gnuplot 6.0 ignores them there).
   character(len=:), allocatable, intent(inout) :: curve !< Curve words.
   real(R8P),        allocatable, intent(inout) :: base  !< Base line.
   logical,                       intent(in)    :: band  !< A band x:y1:y2.
   character(len=:), allocatable                :: rest  !< Words not read.
   character(len=:), allocatable                :: word  !< Current word.
   character(len=:), allocatable                :: kept  !< Curve words kept.
   integer(I4P)                                 :: b     !< Blank after the word.
   logical                                      :: axis  !< An axis word.
   logical                                      :: side  !< `above` or `below`.

   if (.not. allocated(curve)) return
   axis = .false.
   side = .false.
   rest = trim(adjustl(curve))
   do while (len(rest) > 0)
      b = index(rest, ' ', kind=I4P)
      if (b == 0_I4P) b = len(rest, kind=I4P) + 1_I4P
      word = rest(1:b - 1_I4P)
      rest = trim(adjustl(rest(min(b, len(rest, kind=I4P) + 1_I4P):)))
      if (is_word(word, 'x1 x2 y1 y2 y')) axis = .true.
      if (is_word(word, 'above below')) side = .true.
      if (index(word, '=') > 0) return
   enddo
   if (.not. side) return
   if (axis) then
      kept = ''
      rest = trim(adjustl(curve))
      do while (len(rest) > 0)
         b = index(rest, ' ', kind=I4P)
         if (b == 0_I4P) b = len(rest, kind=I4P) + 1_I4P
         word = rest(1:b - 1_I4P)
         rest = trim(adjustl(rest(min(b, len(rest, kind=I4P) + 1_I4P):)))
         if (.not. is_word(word, 'above below')) kept = kept//' '//word
      enddo
      curve = kept
   elseif (.not. band .and. .not. allocated(base)) then
      allocate(base, source=0.0_R8P)
   endif
   endsubroutine above_below_base

   subroutine filled_options(text, curve, base, bad)
   !< The filledcurves options of `text` (words blank separated, `xy=X,Y` one word) as a plot item reads them: the
   !< curve words (`closed`, `x1`, `x2`, `above`, `below`, `y1`, `y2`, `y`, `x=V`, `xy=X,Y`) in `curve`, `y=V` (`y1=`,
   !< `y2=`) the `base`; `bad` names the problem, empty if none.
   character(len=*),              intent(in)    :: text  !< Options.
   character(len=:), allocatable, intent(inout) :: curve !< Curve words.
   real(R8P),        allocatable, intent(inout) :: base  !< Base line.
   character(len=:), allocatable, intent(out)   :: bad   !< Problem, empty if none.
   character(len=:), allocatable                :: rest  !< Words not read.
   character(len=:), allocatable                :: word  !< Current word.
   integer(I4P)                                 :: b     !< Blank after the word.
   real(R8P)                                    :: v     !< Number.

   bad = ''
   if (.not. allocated(curve)) curve = ''
   rest = trim(adjustl(text))
   do while (len(rest) > 0)
      b = index(rest, ' ', kind=I4P)
      if (b == 0_I4P) b = len(rest, kind=I4P) + 1_I4P
      word = rest(1:b - 1_I4P)
      rest = trim(adjustl(rest(min(b, len(rest, kind=I4P) + 1_I4P):)))
      if (is_word(word, 'closed x1 x2 above below y1 y2 y')) then
         curve = curve//' '//word
      elseif (index(word, 'x=') == 1 .or. index(word, 'x1=') == 1 .or. index(word, 'x2=') == 1) then
         if (.not. to_number(word(index(word, '=') + 1:), v)) then
            bad = word(1:index(word, '='))//'V needs a number, found "'//word//'"'
            return
         endif
         curve = curve//' '//word
      elseif (index(word, 'y=') == 1 .or. index(word, 'y1=') == 1 .or. index(word, 'y2=') == 1) then
         if (.not. to_number(word(index(word, '=') + 1:), v)) then
            bad = 'y=V needs a number, found "'//word//'"'
            return
         endif
         if (allocated(base)) deallocate(base)
         allocate(base, source=v)
      elseif (index(word, 'xy=') == 1 .and. index(word, ',') > 0) then
         curve = curve//' '//word
      else
         bad = 'unsupported option "'//word//'"'
         return
      endif
   enddo
   endsubroutine filled_options

   function read_whole(file, text) result(ok)
   !< The whole content of `file`, `ok` false if it cannot be read.
   character(len=*),              intent(in)  :: file !< File name.
   character(len=:), allocatable, intent(out) :: text !< Content.
   logical                                    :: ok   !< Read.
   integer(I4P)                               :: unit !< File unit.
   integer(I4P)                               :: bytes !< Size [bytes].
   integer(I4P)                               :: status !< I/O status.

   text = ''
   open(newunit=unit, file=file, access='stream', form='unformatted', action='read', status='old', iostat=status)
   ok = status == 0_I4P
   if (.not. ok) return
   inquire(unit=unit, size=bytes)
   allocate(character(len=max(0_I4P, bytes)) :: text)
   if (bytes > 0_I4P) read(unit, iostat=status) text
   close(unit)
   ok = status == 0_I4P
   endfunction read_whole

   function to_number(word, value) result(ok)
   !< Parse a number; false if malformed or beyond the real range.
   character(len=*), intent(in)  :: word   !< Text.
   real(R8P),        intent(out) :: value  !< Number.
   logical                       :: ok     !< Success.

   value = 0.0_R8P
   ok = verify(word, '0123456789+-.eEdD') == 0 .and. scan(word, '0123456789') > 0
   if (.not. ok) return
   call real_from_decimal(word, value, ok)
   endfunction to_number

   pure subroutine push_line_style(list, item)
   !< Append `item` to `list` (an unallocated `list` is empty), through a temporary: see `push`.
   type(line_style_object), allocatable, intent(inout) :: list(:)  !< List.
   type(line_style_object),              intent(in)    :: item     !< New item.
   type(line_style_object), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                        :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_line_style
endmodule foresight_script
