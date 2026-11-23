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
!< - `with vectors|arrows [head|heads|nohead|backhead] [filled|empty|nofilled]`, `with ellipses [units xy]`,
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
!<   ordinates for y and y2; x2 and y2 once their ticks are set); `pi|pointinterval N` a marker every N points;
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
!<   their number;
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
!<
!< Anything else is an error naming the command, never silently ignored. Errors are returned (`iostat`, `iomsg` with
!< `source:line:`), not stopped on, so a watch loop can survive a bad cycle.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite, ieee_is_nan, ieee_quiet_nan, ieee_value
use, intrinsic :: iso_fortran_env, only : error_unit, input_unit, output_unit
use foresight_axes, only : axes_names, axes_object, MAX_LINETYPES, boxplot_style, boxplot_words, polar_series, &
                           spider_words, POLAR_STYLES
use foresight_datafile, only : datafile_object
use foresight_expression, only : block_hook, expression_object, list_text, push, saved_array, saved_variable, &
                                 symbols_object, value_list, value_object
use foresight_annotations, only : arrow_object, label_object, place_object, push, shape_object
use foresight_axis, only : axis_object
use foresight_figure, only : figure_object
use foresight_format, only : c_real, decimal_of, decimal_str, format_check, format_decimal, int_str, real_from_decimal
use foresight_readout, only : readout_check
use foresight_sys, only : command_output, sleep_ms
use foresight_time, only : strptime, time_format_check
use foresight_fit, only : fit_model, fit_report, fit_result, fit_settings, levenberg_marquardt
use foresight_stats, only : stats, stats_column, stats_report, stats_result
use foresight_smooth, only : bin_values, CURVE_MODES, smooth, smooth_curve, SMOOTH_MODES
use foresight_palette, only : gnuplot_color, hex_color, named_color, palette_gradient, palette_object, palette_words
use foresight_theme, only : THEMES
use foresight_style, only : default_color, fill_style, gnuplot_abbreviates, sequence_colors, style_name, style_object, style_with, &
                            STYLE_NAMES, WITH_GAUGE, WITH_PARALLELAXES, WITH_PIE, WITH_RADAR, WITH_ROSE, WITH_SPIDERPLOT, &
                            FILL_SOLID, WITH_BOXES, WITH_FILLEDCURVES, WITH_LABELS, WITH_XERRORBARS, WITH_XERRORLINES, &
                            WITH_XYERRORBARS, WITH_XYERRORLINES, WITH_YERRORBARS, WITH_YERRORLINES
use foresight_ticks, only : MINOR_AUTO, MINOR_DEFAULT, MINOR_NONE, push, tic_item, tics_object
use foresight_tokens, only : brace_balance, push, split_statements, strip_comment, token_object, tokenize, TOKEN_COMMA, &
                             TOKEN_RANGE, TOKEN_STRING, TOKEN_WORD
use penf, only : I4P, I8P, R8P

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
character(len=12), parameter :: LC_PALETTE_CB   = '*palettecb'   !< `lc palette cb V` marker in a line color.
character(len=12), parameter :: LC_PALETTE_FRAC = '*palettefrac' !< `lc palette frac F` marker in a line color.
character(len=*), parameter :: FUNCTION_STYLES = 'lines, points, linespoints, impulses, steps, fsteps, histeps, dots, '// &
                                                  'boxes or filledcurves' !< Styles
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
endtype line_style_object

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
   character(len=:), allocatable   :: separator                !< Data cell separators, empty for whitespace.
   character(len=:), allocatable   :: missing                  !< Missing data string, empty for none.
   character(len=:), allocatable   :: comments                 !< Characters starting a comment in data files.
   integer(I4P)                    :: samples = 100_I4P        !< Function samples, `set samples`.
   real(R8P)                       :: rgbmax = 255.0_R8P       !< Full intensity of RGB image components, `set rgbmax`.
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
   character(len=:), allocatable   :: term_name                !< The terminal: GPVAL_TERM.
   integer(I4P), public            :: exit_status = 0_I4P      !< `exit status N`: the status the run ends with.
   character(len=:), allocatable   :: dummy                    !< `set dummy NAME`: the functions' variable, empty for
                                                               !< gnuplot's (x, t in polar mode).
   contains
      procedure, pass(self) :: execute                !< Execute one statement.
      procedure, pass(self) :: init                   !< Reset the interpreter.
      procedure, pass(self) :: run_file               !< Run a script file.
      procedure, pass(self) :: run_text               !< Run script text.
      procedure, pass(self), private :: assignment    !< `a = 2`, `f(x) = ...`.
      procedure, pass(self), private :: plot_command  !< `plot`.
      procedure, pass(self), private :: reset_command !< `reset`.
      procedure, pass(self), private :: pause_command !< `pause`.
      procedure, pass(self), private :: write_table   !< The points of a plot as text (`set table`).
      procedure, pass(self), private :: fit_command   !< `fit`.
      procedure, pass(self), private :: print_command !< `print`.
      procedure, pass(self), private :: stats_command !< `stats`.
      procedure, pass(self), private :: load_data     !< Load a data file or a datablock.
      procedure, pass(self), private :: set_time_data !< `set xdata time`, `set xdata`.
      procedure, pass(self), private :: range_value   !< Value of a range end.
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
   if (present(theme)) then
      if (len_trim(theme) > 0) call self%figure%set_theme(name=trim(theme))
   endif
   self%output = output
   self%output_set = .false.
   self%multiplot = .false.
   self%advance_pending = .false.
   self%previous_file = ''
   self%last_plot = ''
   if (allocated(self%data_files)) deallocate(self%data_files)
   allocate(self%data_files(0))
   self%data_style = 'lines'
   self%function_style = 'lines'
   self%autotitle = 'file'
   if (allocated(self%line_styles)) deallocate(self%line_styles)
   allocate(self%line_styles(0))
   self%separator = ''
   self%missing = ''
   self%comments = '#'
   self%samples = 100_I4P
   self%rgbmax = 255.0_R8P
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
   self%parametric = .false.
   self%encoding = 'default'
   self%term_name = 'html'
   if (len(output) > 4) then
      if (output(len(output) - 3:) == '.svg') self%term_name = 'svg'
   endif
   call gnuplot_values(self)
   block_hook => run_block
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
                                '-LIBCERF -COMPLEX_FUNCS -CHI_SHAPES -WATCHPOINTS -EXTERNAL_FUNCTIONS')
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

   active => self
   ! after quit (or exit status N), nothing more runs
   if (self%loop_signal == 4_I4P) return
   here_function = .false.
   iostat = 0_I4P
   iomsg = ''
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
            e = verify(local_name, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789', kind=I4P)
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
   call resolve_colors(tokens, iostat, iomsg)
   if (iostat /= 0_I4P) return
   if (tokens(1)%kind /= TOKEN_WORD) then
      call fail('a command was expected, found "'//tokens(1)%text//'"', iostat, iomsg)
      return
   endif
   command = tokens(1)%text
   ! in a multiplot, the first command after a plot opens the next panel (the multiplot options excepted)
   if (self%advance_pending .and. (keyword(command, 'set', 2_I4P) .or. keyword(command, 'unset', 3_I4P) .or. &
                                   keyword(command, 'plot', 1_I4P) .or. keyword(command, 'reset', 3_I4P))) then
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
      call self%plot_command(tokens(2:), statement, iostat, iomsg)
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
         if (scan(text(1:1), 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$') == 0) then
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
      call self%plot_command(tokens, self%last_plot, iostat, iomsg)
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
   if (len(var) == 0 .or. verify(var, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789') > 0) then
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
   integer(I4P)                                 :: nranges   !< Ranges given.
   integer(I4P)                                 :: set_index !< Dataset, -1 for all.
   integer(I4P)                                 :: every(6)  !< `every` fields.
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
         call parse_every(word, every, iostat, iomsg)
         if (iostat /= 0_I4P) return
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
             verify(prefix, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789') > 0) then
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
   call self%load_data(data, file, iostat, iomsg, keep_text=texts)
   if (iostat /= 0_I4P) then
      iomsg = 'stats: '//iomsg
      return
   endif
   self%previous_file = file
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
   call data%table(fields, set_index, every, values, header=any(fields%name_count() > 0_I4P))
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
   real(R8P)                                    :: range(2)  !< x range, inline.
   real(R8P)                                    :: v         !< Number.
   logical                                      :: ranged    !< x range given.
   logical                                      :: found     !< Variable found.
   logical                                      :: weighted  !< Errors given.
   logical                                      :: unit      !< `unitweights` given.
   integer(I4P)                                 :: set_index !< Dataset, -1 for all.
   integer(I4P)                                 :: every(6)  !< `every` fields.
   integer(I4P)                                 :: i         !< Token counter.
   integer(I4P)                                 :: k         !< Counter.
   integer(I4P)                                 :: colon     !< Range separator.
   integer(I4P)                                 :: first     !< First token of the model.

   iostat = 0_I4P
   iomsg = ''
   ranged = .false.
   i = 1_I4P
   if (size(tokens) == 0) then
      call fail('fit: a function, a data file and via are expected', iostat, iomsg)
      return
   endif
   if (tokens(1)%kind == TOKEN_RANGE) then
      colon = index(tokens(1)%text, ':', kind=I4P)
      if (colon == 0_I4P .or. index(tokens(1)%text, '=') > 0) then
         call fail('fit: the range is [min:max], of x', iostat, iomsg)
         return
      endif
      call self%symbols%constant(trim(adjustl(tokens(1)%text(1:colon - 1_I4P))), range(1), iostat, iomsg)
      if (iostat == 0_I4P) call self%symbols%constant(trim(adjustl(tokens(1)%text(colon + 1_I4P:))), range(2), &
                                                      iostat, iomsg)
      if (iostat /= 0_I4P) then
         iomsg = 'fit: range: '//iomsg
         return
      endif
      ranged = .true.
      i = 2_I4P
   endif
   ! the model: the text up to the data file name
   first = i
   do while (i <= size(tokens, kind=I4P))
      if (tokens(i)%kind == TOKEN_STRING) exit
      if (is_datablock(tokens(i)%text)) exit
      i = i + 1_I4P
   enddo
   if (i > size(tokens, kind=I4P) .or. i == first) then
      call fail('fit: a function then a quoted data file (or a datablock) are expected', iostat, iomsg)
      return
   endif
   text = trim(adjustl(statement(tokens(first)%first:tokens(i)%first - 1_I4P)))
   file = tokens(i)%text
   spec = ''
   set_index = -1_I4P
   every = [1_I4P, 1_I4P, 0_I4P, 0_I4P, -1_I4P, -1_I4P]
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
         if (.not. next_integer(tokens, i, set_index, iostat, iomsg)) return
      elseif (keyword(word, 'every', 2_I4P)) then
         if (.not. next_word(tokens, i, word, iostat, iomsg)) return
         call parse_every(word, every, iostat, iomsg)
         if (iostat /= 0_I4P) return
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
   ! the data: x, z and the errors of z (`using 1:2:3`, gnuplot's version 4 syntax, or with yerrors)
   if (.not. allocated(fields)) fields = plain_columns([1_I4P, 2_I4P])
   if (size(fields) == 1 .or. size(fields) > 3) then
      call fail('fit: using X:Y or X:Y:YERROR (one independent variable)', iostat, iomsg)
      return
   endif
   ! three columns with unitweights are gnuplot's x:y:z, a function of x and y
   if (size(fields) == 3 .and. unit) then
      call fail('fit: using X:Y:Z unitweights fits a function of two variables (one independent variable is '// &
                'supported)', iostat, iomsg)
      return
   endif
   if (size(fields) == 3) weighted = .true.
   if (weighted .and. size(fields) /= 3) then
      call fail('fit: yerrors needs using X:Y:YERROR', iostat, iomsg)
      return
   endif
   call self%load_data(data, file, iostat, iomsg, keep_text=any(fields%uses_text()))
   if (iostat /= 0_I4P) then
      iomsg = 'fit: '//iomsg
      return
   endif
   call data%table(fields, set_index, every, values, header=any(fields%name_count() > 0_I4P))
   allocate(use(size(values, 1)))
   use = ieee_is_finite(values(:, 1)) .and. ieee_is_finite(values(:, 2))
   if (weighted) use = use .and. ieee_is_finite(values(:, 3))
   if (ranged) then
      do k = 1_I4P, size(use, kind=I4P)
         if (use(k)) use(k) = values(k, 1) >= min(range(1), range(2)) .and. values(k, 1) <= max(range(1), range(2))
      enddo
   endif
   x = pack(values(:, 1), use)
   z = pack(values(:, 2), use)
   if (weighted) then
      err = pack(values(:, 3), use)
   else
      allocate(err(size(z)))
      err = 1.0_R8P
   endif
   ! the parameters: their values now, 1 if undefined (gnuplot)
   allocate(start(size(names)))
   do k = 1_I4P, size(names, kind=I4P)
      call self%symbols%value_of(trim(names(k)), v, found)
      if (.not. found) v = 1.0_R8P
      start(k) = v
      call self%symbols%set_value(trim(names(k)), v, .false.)
   enddo
   call model%compile(text, iostat, iomsg, variable='x', degrees=self%figure%panels(self%figure%current)%degrees, &
                      symbols=self%symbols)
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
   fitted%degrees = self%figure%panels(self%figure%current)%degrees
   fitted%symbols = self%symbols
   call levenberg_marquardt(fitted, z, err, start, options, result, weighted)
   if (len(result%message) > 0) then
      do k = 1_I4P, size(names, kind=I4P)
         call self%symbols%set_value(trim(names(k)), start(k), .false.)
      enddo
   else
      do k = 1_I4P, size(names, kind=I4P)
         call self%symbols%set_value(trim(names(k)), result%params(k), .false.)
         if (self%fit_errorvariables) call self%symbols%set_value(trim(names(k))//'_err', result%errors(k), .false.)
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
      call self%symbols%set_value(trim(self%names(q)), p(q), .false.)
   enddo
   call e%compile(self%text, ios, msg, variable='x', degrees=self%degrees, symbols=self%symbols)
   ok = ios == 0_I4P
   if (.not. ok) return
   do q = 1_I4P, size(self%x, kind=I4P)
      f(q) = e%value_at(self%x(q))
   enddo
   ok = all(ieee_is_finite(f))
   endsubroutine script_model_values

   ! private procedures
   function assignment(self, statement, iostat, iomsg) result(done)
   !< gnuplot's `NAME = expression` (a user variable, its value now) or `NAME(P1, ...) = expression` (a user function):
   !< an `=` right after the name or the parameter list, not `==`. False if `statement` is neither.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   character(len=*),              intent(in)    :: statement !< Statement.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   logical                                      :: done      !< An assignment or a definition.
   character(len=*), parameter   :: LETTERS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_'
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
   e = verify(s, LETTERS//'0123456789', kind=I4P)
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

   subroutine plot_command(self, tokens, text, iostat, iomsg)
   !< `plot` items: each a data file or a function with modifiers, comma separated; replaces the previous plot and
   !< renders it.
   !<
   !< Functions are sampled once all the items are read: their x range depends on the data of the whole plot, as gnuplot.
   !< Until then each holds its place (its color, its key row) as an empty series.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Items tokens.
   character(len=*),              intent(in)    :: text      !< Text the tokens come from, for function titles.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   type(datafile_object)                        :: data      !< Current data file.
   type(expression_object)                      :: func      !< Current function.
   type(expression_object), allocatable         :: functions(:) !< Functions of the plot.
   type(expression_object), allocatable         :: yfunctions(:) !< y(t) of the parametric functions, in their order.
   type(expression_object)                      :: yfunc     !< Current y(t) of a parametric pair.
   integer(I4P),            allocatable         :: slots(:)  !< Series index of each function.
   character(len=:), allocatable                :: axes      !< Item axes, `x1y1`, `x1y2`, `x2y1` or `x2y2`.
   character(len=:), allocatable                :: file      !< Item data file.
   character(len=:), allocatable                :: written   !< Item data file as written, for the automatic title.
   character(len=:), allocatable                :: spec      !< `using` specification as written, empty if none.
   character(len=:), allocatable                :: using     !< `using` keyword as written.
   character(len=1)                             :: quote     !< Quote of the data file.
   character(len=:), allocatable                :: loaded    !< File in `data`.
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
   logical                                      :: lcz       !< lc palette z: the palette values from the last column.
   character(len=:), allocatable                :: palette_lc !< `lc palette` marker of the item, empty for none.
   real(R8P),        allocatable                :: zcolors(:) !< Palette values of the points (`lc palette z`).
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
   logical                                      :: one_field !< `using` gives one field (before the point number).
   logical                                      :: weight_one !< The single column is x, each point of weight 1.
   logical                                      :: is_matrix !< The item reads a `matrix` file.
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
   integer(I4P)                                 :: number    !< Integer argument.
   integer(I4P)                                 :: i         !< Token counter.
   integer(I4P)                                 :: head      !< First token of a function.
   logical                                      :: has_title !< Title given (or notitle).
   logical                                      :: is_function !< The item is a function, else a data file.
   logical                                      :: is_head     !< `title columnhead[(N)]`.
   integer(I4P)                                 :: head_column !< Column of `title columnhead(N)`.
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

   iostat = 0_I4P
   iomsg = ''
   loaded = ''
   allocate(functions(0), slots(0), yfunctions(0), own_range(2, 0), own_set(2, 0), own_base(0))
   call self%figure%clear
   if (size(tokens) == 0) then
      call fail('plot: nothing to plot', iostat, iomsg)
      return
   endif
   ! gnuplot's dummy variable is t in polar and parametric modes
   dummy = merge('t', 'x', self%figure%panels(self%figure%current)%polar .or. self%parametric)
   if (len(self%dummy) > 0) dummy = self%dummy
   ! inline ranges, [x] then [y], for this plot only: plot [0:2*pi] [-1:1] sin(x), plot [t=0:1] t**2
   i = 1_I4P
   nranges = 0_I4P
   do while (i <= size(tokens, kind=I4P))
      if (tokens(i)%kind /= TOKEN_RANGE) exit
      nranges = nranges + 1_I4P
      if (nranges > merge(3_I4P, 2_I4P, self%parametric)) then
         if (self%parametric) then
            call fail('plot: at most three inline ranges, [t], [x] and [y], in parametric mode', iostat, iomsg)
         else
            call fail('plot: at most two inline ranges, [x] and [y], are supported', iostat, iomsg)
         endif
         return
      endif
      if (self%figure%panels(self%figure%current)%polar) then
         call fail('plot: inline ranges are not supported in polar mode (use set trange and set rrange)', iostat, iomsg)
         return
      endif
      ! parametric: [t] [x] [y]
      if (self%parametric) then
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
      ! data file or function
      if (i > size(tokens, kind=I4P)) then
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
      if (tokens(i)%kind == TOKEN_RANGE) then
         item_prefix = '['//tokens(i)%text//'] '
         block
            integer(I4P) :: colon !< Separator.

            colon = top_colon(tokens(i)%text)
            if (colon == 0_I4P .or. index(tokens(i)%text, '=') > 0) then
               call fail('plot: a sampling range [min:max] is expected, found "['//tokens(i)%text//']"', iostat, iomsg)
               return
            endif
            call inline_end(tokens(i)%text(1:colon - 1_I4P), item_set(1), item_range(1))
            if (iostat == 0_I4P) call inline_end(tokens(i)%text(colon + 1_I4P:), item_set(2), item_range(2))
            if (iostat /= 0_I4P) return
         endblock
         i = i + 1_I4P
         if (i > size(tokens, kind=I4P)) then
            call fail('plot: missing item after "'//trim(item_prefix)//'"', iostat, iomsg)
            return
         endif
      endif
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
            if (index(text(tokens(i)%first:tokens(last)%last), '=') > 0) then
               if (self%assignment(text(tokens(i)%first:tokens(last)%last), status, message)) then
                  if (status /= 0_I4P) then
                     call fail('plot: '//message, iostat, iomsg)
                     return
                  endif
                  i = last + 1_I4P
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
      is_function = tokens(i)%kind == TOKEN_WORD
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
      elseif (is_function) then
         ! the expression runs up to the first item option: blanks may separate its words, `x * 2`
         head = i
         do while (i < size(tokens, kind=I4P))
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
         if (is_function) then
            associate(panel => self%figure%panels(self%figure%current))
               call func%compile(written, iostat, iomsg, variable=dummy, degrees=panel%degrees, &
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
                     if (tokens(i + 1_I4P)%kind /= TOKEN_WORD) exit
                     if (is_item_option(tokens(i + 1_I4P)%text)) exit
                     i = i + 1_I4P
                  enddo
                  written2 = text(tokens(head2)%first:tokens(i)%last)
                  associate(panel => self%figure%panels(self%figure%current))
                     call yfunc%compile(written2, iostat, iomsg, variable=dummy, degrees=panel%degrees, &
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
      if (len(item_prefix) > 0 .and. .not. is_function) then
         write(error_unit, '(A)') 'foresight: warning: ignoring sample range in non-sampled data plot'
         item_set = .false.
      endif
      ! modifiers
      if (allocated(fields)) deallocate(fields)
      spec = ''
      label_col = 0_I4P
      label_axis = 'x'
      is_matrix = .false.
      set_index = -1_I4P
      every = [1_I4P, 1_I4P, 0_I4P, 0_I4P, -1_I4P, -1_I4P]
      with = self%data_style
      if (is_function) with = self%function_style
      has_table_if = .false.
      has_title = .false.
      auto_title = .false.
      plain_item = .false.
      title = ''
      title_column = -1_I4P
      axes = 'x1y1'
      filter = ''
      bandwidth = 0.0_R8P
      binned = .false.
      nbins = self%samples
      binrange = 0.0_R8P
      binwidth = -1.0_R8P
      binavg = .false.
      lcvar = .false.
      if (allocated(format)) deallocate(format)
      if (allocated(hole)) deallocate(hole)
      if (allocated(whisker)) deallocate(whisker)
      heads = ''
      label_opts = ''
      curve = ''
      keyed = .false.
      if (allocated(at_x)) deallocate(at_x)
      if (allocated(gauge_scale)) deallocate(gauge_scale)
      cells = 0_I4P
      rose_linear = .false.
      if (allocated(fs)) deallocate(fs)
      if (allocated(base)) deallocate(base)
      shaping = ''
      line = line_style_object()
      i = i + 1_I4P
      do while (i <= size(tokens, kind=I4P))
         if (tokens(i)%kind == TOKEN_COMMA) exit
         word = tokens(i)%text
         if (tokens(i)%kind /= TOKEN_WORD) then
            call fail('plot: unexpected "'//word//'"', iostat, iomsg)
            return
         endif
         if (is_function .and. (keyword(word, 'using', 1_I4P) .or. keyword(word, 'index', 1_I4P) .or. &
                                keyword(word, 'every', 2_I4P))) then
            call fail('plot: "'//word//'" applies to data files, not to the function "'//written//'"', iostat, iomsg)
            return
         elseif (keyword(word, 'using', 1_I4P)) then
            using = word
            if (.not. next_word(tokens, i, spec, iostat, iomsg)) return
            call split_xtic(spec, label_col, iostat, iomsg, keyed, label_field, label_axis)
            if (iostat /= 0_I4P) return
            call parse_using(spec, fields, iostat, iomsg, self%figure%panels(self%figure%current)%degrees, self%symbols)
            if (iostat /= 0_I4P) return
         elseif (keyword(word, 'matrix', 3_I4P)) then
            if (is_function) then
               call fail('plot: matrix applies to data files, not to the function "'//written//'"', iostat, iomsg)
               return
            endif
            is_matrix = .true.
         elseif (keyword(word, 'index', 1_I4P)) then
            if (.not. next_integer(tokens, i, set_index, iostat, iomsg)) return
         elseif (keyword(word, 'every', 2_I4P)) then
            if (.not. next_word(tokens, i, word, iostat, iomsg)) return
            call parse_every(word, every, iostat, iomsg)
            if (iostat /= 0_I4P) return
         elseif (keyword(word, 'with', 1_I4P)) then
            if (.not. next_word(tokens, i, word, iostat, iomsg)) return
            with = canonical_style(word)
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
            if (is_function .and. .not. function_drawable(with) .and. with /= 'table') then
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
               ! arrow style words right after the style, as gnuplot
               do while (i < size(tokens, kind=I4P))
                  if (.not. is_word(tokens(i + 1_I4P)%text, 'head heads nohead backhead filled empty nofilled')) exit
                  i = i + 1_I4P
                  heads = heads//' '//tokens(i)%text
               enddo
            endif
            if (with == 'ellipses' .and. i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%text == 'units') then
                  i = i + 2_I4P
                  if (i > size(tokens, kind=I4P)) then
                     call fail('plot: ellipses units xy expected', iostat, iomsg)
                     return
                  endif
                  if (tokens(i)%text /= 'xy') then
                     call fail('plot: ellipses take units xy only (diameters in x and y units)', iostat, iomsg)
                     return
                  endif
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
                  elseif (word == 'r' .or. index(word, 'r=') == 1) then
                     call fail('plot: filledcurves '//word//' (polar) is not supported', iostat, iomsg)
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
            filter = smooth_name(filter)
            if (.not. (is_word(filter, SMOOTH_MODES) .or. is_word(filter, CURVE_MODES))) then
               call fail('plot: unsupported smooth "'//filter//'" (supported: '//SMOOTH_MODES//' '//CURVE_MODES//')', &
                         iostat, iomsg)
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
         elseif (word == 'fs' .or. keyword(word, 'fillstyle', 5_I4P)) then
            call fill_words(fs)
            if (iostat /= 0_I4P) return
         elseif (with == 'labels' .and. is_word(word, 'left center centre right norotate point nopoint rotate offset '// &
                                                'tc textcolor')) then
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
         elseif (keyword(word, 'notitle', 3_I4P)) then
            title = ''
            has_title = .true.
         elseif (is_word(word, 'noenhanced enhanced')) then
            ! the title as it is, or as enhanced text
            plain_item = word == 'noenhanced'
         elseif (word == 'ls' .or. keyword(word, 'linestyle', 5_I4P)) then
            if (.not. next_integer(tokens, i, number, iostat, iomsg)) return
            call apply_line_style(self%line_styles, number, line, self%figure%panels(self%figure%current)%linecolors)
         elseif (is_line_option(word)) then
            if (.not. (word == 'lc' .or. keyword(word, 'linecolor', 5_I4P) .or. word == 'lt' .or. &
                       keyword(word, 'linetype', 5_I4P))) shaping = word
            if (.not. line_option(tokens, i, line, iostat, iomsg, self%figure%panels(self%figure%current)%linecolors, &
                                  self%symbols)) then
               iomsg = 'plot: '//iomsg
               return
            endif
         else
            call fail('plot: unsupported option "'//word//'"', iostat, iomsg)
            return
         endif
         i = i + 1_I4P
      enddo
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
         if (index(line%lc, '*palette') == 1 .and. is_word(with, 'readout gauge pie radar rose parallelaxes '// &
                                                                 'spiderplot labels image rgbimage rgbalpha')) then
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
      if (allocated(fs) .and. .not. is_word(with, 'boxes filledcurves histograms circles pie gauge radar rose '// &
                                            'boxerrorbars boxxyerror candlesticks boxplot ellipses polygons sectors')) then
         call fail('plot: fs applies to boxes, filledcurves, histograms, circles, the box styles and the panel charts '// &
                   'only', iostat, iomsg)
         return
      endif
      associate(panel => self%figure%panels(self%figure%current))
         if (panel%polar) then
            polar_ok = is_word(with, 'lines points linespoints filledcurves sectors readout') .and. .not. allocated(base)
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
         if (.not. has_title .and. self%autotitle /= 'none') then
            ! the expression as it is, not enhanced text
            title = item_prefix//written
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
         call push(functions, func)
         if (self%parametric) call push(yfunctions, yfunc)
         if (allocated(base)) then
            own_base = [own_base, base]
         else
            own_base = [own_base, ieee_value(1.0_R8P, ieee_quiet_nan)]
         endif
         ! grown through temporaries: nvfortran 26.9 -O2 zeroes `a = reshape([a, ...], ...)` (see boxplot_stats)
         block
            real(R8P), allocatable :: grown_range(:,:) !< own_range, one more.
            logical,   allocatable :: grown_set(:,:)   !< own_set, one more.

            grown_range = reshape([own_range, item_range], [2, size(functions)])
            call move_alloc(grown_range, own_range)
            grown_set = reshape([own_set, item_set], [2, size(functions)])
            call move_alloc(grown_set, own_set)
         endblock
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
            call fail('plot: labels take their text column, not xtic()', iostat, iomsg)
            return
         endif
         if (.not. allocated(fields)) then
            label_col = 3_I4P
            call label_field%set_column(label_col)
         elseif (size(fields) == 3) then
            ! a column number (its text) or an expression: a string (`(sprintf(...))`, `(strcol(1))`), or a number
            ! written as the text of the first column it reads, as gnuplot
            word = trim(adjustl(spec(index(spec, ':', back=.true.) + 1:)))
            if (len(word) > 0 .and. verify(word, '0123456789') == 0 .and. len(word) <= 9) then
               read(word, *) label_col
               call label_field%set_column(label_col)
            else
               label_col = 1_I4P
               label_field = fields(3)
            endif
            kept = fields(1:2)
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
      if (file /= loaded .or. (needs_text .and. .not. data%has_text)) then
         call self%load_data(data, file, iostat, iomsg, keep_text=needs_text)
         if (iostat /= 0_I4P) return
         loaded = file
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
      if (lcvar .or. lcz) then
         word = trim(merge('lc palette z', 'lc variable ', lcz))
         if (.not. (is_word(with, 'lines points linespoints impulses') .or. &
                    (lcvar .and. is_word(with, 'circles ellipses boxes')))) then
            call fail('plot: '//word//' applies to lines, points, linespoints and impulses (lc variable also to '// &
                      'circles, ellipses and boxes), not to '//with, iostat, iomsg)
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
      nbar = size(fields, kind=I4P) - 2_I4P - merge(1_I4P, 0_I4P, lcvar .or. lcz)
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
         if (.not. one_field) then
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
         if (nbar /= 2_I4P) then
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
      case ('polygons', 'labels')
         if (nbar /= 0_I4P) then
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
         ! smooth acsplines: X:Y:WEIGHT, the weights read by the smoothing
         if (nbar /= 0_I4P .and. .not. (nbar == 1_I4P .and. filter == 'acsplines')) then
            call fail('plot: '//with//' needs using X:Y or Y', iostat, iomsg)
            return
         endif
      endselect
      if (len(filter) > 0 .and. nbar /= 0_I4P .and. .not. (nbar == 1_I4P .and. filter == 'acsplines')) then
         call fail('plot: smooth applies to lines, points and linespoints, not to '//with, iostat, iomsg)
         return
      endif
      if (.not. has_title) then
         select case (self%autotitle)
         case ('columnhead')
            title_column = 0_I4P
         case ('file')
            ! gnuplot: the item as written, '' included, as it is (not enhanced text)
            title = trim(quote)//written//trim(quote)
            if (len(spec) > 0) title = title//' '//using//' '//spec
            auto_title = .true.
         endselect
      endif
      ! the first row of each dataset is a header as soon as one is used, as gnuplot
      headed = title_column >= 0_I4P .or. self%autotitle == 'columnhead' .or. any(fields%name_count() > 0_I4P)
      if (headed) then
         missing = data%missing_name(fields, set_index)
         if (len(missing) > 0) then
            call fail('plot: no column with header "'//missing//'" in "'//file//'"', iostat, iomsg)
            return
         endif
         if (title_column >= 0_I4P) title = header_title(max(0_I4P, set_index))
      endif
      if (label_col > 0_I4P) then
         call data%table(fields, set_index, every, values, header=headed, labels=xlabels, label=label_field)
      else
         call data%table(fields, set_index, every, values, header=headed)
         if (allocated(xlabels)) deallocate(xlabels)
      endif
      if (weight_one) then
         values(:, 1) = values(:, 2)
         values(:, 2) = 1.0_R8P
      endif
      x = values(:, 1)
      y = values(:, 2)
      if (lcvar) call variable_colors(values(:, size(values, 2)), line%lc == LC_RGB_VARIABLE)
      if (lcz) zcolors = values(:, size(values, 2))
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
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, xlow=xlow, &
                               xhigh=xhigh, ylow=ylow, yhigh=yhigh, axes=axes, width=widths, fs=fs, xlabels=xlabels)
      elseif (with == 'candlesticks' .or. with == 'financebars') then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, ylow=ylow, &
                               yhigh=yhigh, close=closes, axes=axes, width=widths, fs=fs, xlabels=xlabels, &
                               whiskerbars=whisker)
      elseif (with == 'vectors') then
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, axes=axes, dx=xlow, &
                               dy=xhigh, head=heads)
      elseif (with == 'arrows') then
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, axes=axes, &
                               length=xlow, angle=xhigh, head=heads)
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
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, ps=line%ps, pt=line%pt, &
                               axes=axes, labels=xlabels, label=label_opts)
      elseif (with == 'parallelaxes' .or. with == 'spiderplot') then
         if (keyed .and. with == 'parallelaxes') then
            call fail('plot: key(N) names the rows of a spider plot', iostat, iomsg)
            return
         endif
         if (label_col > 0_I4P .and. .not. keyed) then
            call fail('plot: '//with//' takes key(N), not xtic(N)', iostat, iomsg)
            return
         endif
         if (keyed) then
            call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, labels=xlabels, &
                                  at=at_x)
         else
            call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, at=at_x)
         endif
      elseif (with == 'boxplot') then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         if (label_col > 0_I4P) then
            call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, ps=line%ps, &
                                  axes=axes, width=widths, fs=fs, factors=xlabels)
         else
            call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, ps=line%ps, &
                                  axes=axes, width=widths, fs=fs)
         endif
      elseif (with == 'filledcurves' .and. len(curve) > 0) then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
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
   if (self%multiplot) self%advance_pending = .true.
   ! a multiplot on the standard output is printed once, complete, at unset multiplot (as gnuplot); files are rewritten
   ! at each plot, so that a watched page shows the panels done so far
   if (self%multiplot .and. self%output == '-') return
   call self%save_output(iostat, iomsg)
   contains
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
         if (i + 3_I4P > size(tokens, kind=I4P)) then
            call fail('plot: labels offset X,Y expected', iostat, iomsg)
            return
         endif
         if (tokens(i + 2_I4P)%kind /= TOKEN_COMMA) then
            call fail('plot: labels offset X,Y expected', iostat, iomsg)
            return
         endif
         label_opts = label_opts//' offset '//tokens(i + 1_I4P)%text//','//tokens(i + 3_I4P)%text
         i = i + 3_I4P
      case ('tc', 'textcolor')
         if (i < size(tokens, kind=I4P)) then
            if (tokens(i + 1_I4P)%text == 'rgb') i = i + 1_I4P
         endif
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

      subroutine color_last
      !< `lc variable` of circles, ellipses and boxes: each shape in its point's color, the key sample in the first one's
      !< (gnuplot).
      associate(panel => self%figure%panels(self%figure%current))
         associate(last => panel%series(size(panel%series)))
            if (size(point_colors) /= size(last%x)) return
            last%colors = point_colors
            if (size(point_colors) > 0) last%style%color = trim(point_colors(1))
         endassociate
      endassociate
      endsubroutine color_last

      subroutine mark_last
      !< The series just added: the axis of its text labels (`ytic(N)`, ...) and its point interval.
      integer(I4P) :: last !< Series just added.

      associate(panel => self%figure%panels(self%figure%current))
         last = size(panel%series, kind=I4P)
         if (last < 1_I4P) return
         panel%series(last)%label_axis = label_axis
         if (allocated(line%pi)) panel%series(last)%pointinterval = line%pi
         panel%series(last)%title_plain = auto_title .or. plain_item
      endassociate
      endsubroutine mark_last

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
      !< number (`set colorsequence`), or with `rgb` the 24-bit color 0xRRGGBB; an undefined value takes linetype 1.
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
            code = iand(int(c(k), I8P), int(z'FFFFFF', I8P))
            point_colors(k) = '#'
            do d = 5_I4P, 0_I4P, -1_I4P
               digit = int(iand(ishft(code, -4_I4P * d), 15_I8P), I4P)
               point_colors(k)(7 - d:7 - d) = HEX(digit + 1:digit + 1)
            enddo
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
      endassociate
      if (len(problem) > 0) call fail('plot: smooth '//filter//': '//problem, iostat, iomsg)
      endsubroutine curve_filter

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

      subroutine inline_range(text, axis)
      !< An inline range `[min:max]` of the plot command (`text` without brackets): of x (`axis` 1), y (2) or t (3,
      !< the first range in parametric mode); `[name=min:max]` of x or t also names the dummy variable; an empty or `*`
      !< end keeps the set one, as gnuplot.
      character(len=*), intent(in)  :: text  !< Range text.
      integer(I4P),     intent(in)  :: axis  !< 1 x, 2 y, 3 t.
      logical                       :: first !< A range of the dummy variable (x or t).
      character(len=:), allocatable :: body  !< Range without the dummy variable.
      integer(I4P)                  :: colon !< Separator.
      integer(I4P)                  :: equal !< Dummy variable separator.

      first = axis /= 2_I4P
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
         if (verify(dummy, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_') /= 0 .or. &
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
         if (axis == 3_I4P) then
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
         title = trim(quote)//written//trim(quote)
         if (len(spec) > 0) title = title//' '//using//' '//spec
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
      !< Remove a last `using` field `xtic(...)` or `xticlabels(...)` from `spec`, returning its `field`: a column N
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
      select case (head)
      case ('xtic', 'xticlabels')
         axis = 'x'
      case ('x2tic', 'x2ticlabels')
         axis = 'x2'
      case ('ytic', 'yticlabels')
         axis = 'y'
      case ('y2tic', 'y2ticlabels')
         axis = 'y2'
      case default
         if (.not. keyed) return
      endselect
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
               if (series%x2) then
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
   endsubroutine plot_command

   recursive subroutine call_command(self, tokens, is_call, iostat, iomsg)
   !< gnuplot `load FILE` and `call FILE [ARG1 ... ARG9]`: run the script FILE (a string expression), ARG0 its name
   !< and, for `call`, ARGC the number of arguments and ARG1 to ARG9 their texts (a quoted string as it is, a number
   !< as written, a variable or a parenthesized expression its value: a string as it is, a number as `%g`); those
   !< variables are restored after it, as gnuplot's. The script is watched as a data file is.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Statement tokens, the command first.
   logical,                       intent(in)    :: is_call   !< `call`, else `load`.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   character(len=*), parameter                  :: DIGITS = '0123456789' !< Argument numbers.
   type(saved_variable)                         :: saved(11) !< ARG0 to ARG9 and ARGC before the call.
   type(saved_array)                            :: saved_argv !< ARGV before the call.
   type(token_object), allocatable              :: args(:)   !< Argument texts.
   type(token_object)                           :: arg       !< One argument.
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
   allocate(args(0))
   do while (i < size(tokens, kind=I4P))
      i = i + 1_I4P
      if (.not. is_call) then
         call fail('load: unexpected "'//tokens(i)%text//'" (call passes arguments)', iostat, iomsg)
         return
      endif
      if (tokens(i)%kind == TOKEN_STRING) then
         arg%text = tokens(i)%text
      elseif (tokens(i)%kind /= TOKEN_WORD) then
         call fail('call: unexpected "'//tokens(i)%text//'"', iostat, iomsg)
         return
      elseif (to_number(tokens(i)%text, number)) then
         arg%text = tokens(i)%text
      else
         call self%symbols%text_of(tokens(i)%text, value, is_string, iostat, iomsg, &
                                   degrees=self%figure%panels(self%figure%current)%degrees)
         if (iostat /= 0_I4P) then
            iomsg = 'call: '//iomsg
            return
         endif
         if (.not. is_string) then
            call self%symbols%constant(tokens(i)%text, number, iostat, iomsg, &
                                       degrees=self%figure%panels(self%figure%current)%degrees)
            if (iostat /= 0_I4P) then
               iomsg = 'call: '//iomsg
               return
            endif
            value = c_real('', 0_I4P, -1_I4P, 'g', number)
         endif
         arg%text = value
      endif
      if (size(args) == 9) then
         call fail('call: at most 9 arguments', iostat, iomsg)
         return
      endif
      call push(args, arg)
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
         character(len=:), allocatable :: texts(:) !< Argument texts.
         integer(I4P)                  :: width    !< Longest.

         width = 1_I4P
         do k = 1_I4P, size(args, kind=I4P)
            width = max(width, len(args(k)%text, kind=I4P))
         enddo
         allocate(character(len=width) :: texts(size(args)))
         do k = 1_I4P, size(args, kind=I4P)
            texts(k) = args(k)%text
         enddo
         call self%symbols%set_array('ARGV', texts)
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
   self%samples = 100_I4P
   self%rgbmax = 255.0_R8P
   self%timefmt = '%d/%m/%y,%H:%M'
   self%symbols%timefmt = self%timefmt
   self%time_data = .false.
   self%dummy = ''
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

   iostat = 0_I4P
   iomsg = ''
   text = ''
   associate(panel => self%figure%panels(self%figure%current))
      n = 0_I4P
      if (allocated(panel%series)) n = size(panel%series, kind=I4P)
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

      if (.not. ieee_is_finite(v)) then
         t = 'NaN'
         if (index(format, '% ') > 0) t = ' NaN'
         return
      endif
      call decimal_of(v, mantissa, e)
      call format_decimal(format, mantissa, e, t, sup)
      if (len(sup) > 0) t = t//'e'//sup
      endfunction number

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
   character(len=*), parameter    :: LETTERS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_' !< Name start.
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
               e = verify(statement(i + 1_I4P:), LETTERS//'0123456789', kind=I4P)
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
   type(place_object)                           :: p         !< A position.
   type(line_style_object)                      :: line      !< Line properties read.
   integer(I4P)                                 :: i         !< Token counter.
   integer(I4P)                                 :: tag       !< Tag.
   integer(I4P)                                 :: k         !< Counter.
   logical                                      :: found     !< The tag exists.
   logical                                      :: placed    !< A position given.
   logical                                      :: kind_set  !< An object kind given.
   real(R8P)                                    :: v         !< A number.

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
   else
      option = 'object'
   endif
   i = 2_I4P
   tag = 0_I4P
   ! a tag: a number (or an expression) before anything else
   if (i <= size(tokens, kind=I4P)) then
      if (tokens(i)%kind == TOKEN_WORD .and. .not. is_annotation_word(tokens(i)%text)) then
         call self%symbols%value_of(tokens(i)%text, v, found)
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
   label%tag = tag
   arrow%tag = tag
   object%tag = tag
   placed = found
   kind_set = found
   select case (option)
   case ('label')
      call label_words
   case ('arrow', 'style arrow')
      call arrow_words
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
      !< Keep `arrow` as the arrow style of its tag (replacing it): its look only.
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

      pure function is_annotation_word(w) result(yes)
      !< Whether `w` is an option word of the annotations (not a tag).
      character(len=*), intent(in) :: w   !< Word.
      logical                      :: yes !< An option word.

      yes = is_word(w, 'at from to rto left center centre right rotate norotate front back behind tc textcolor '// &
                    'point nopoint offset font noenhanced enhanced rect rectangle circle ellipse polygon size arc '// &
                    'angle fc fillcolor fs fillstyle lw linewidth lc linecolor lt linetype dt dashtype nohead head '// &
                    'backhead heads filled empty nofilled noborder clip noclip default units boxed as arrowstyle')
      endfunction is_annotation_word

      subroutine position(q)
      !< A position `[SYS] x, [SYS] y` from token `i` (left on its last token).
      type(place_object), intent(out) :: q !< Position.

      q = place_object()
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
      if (tokens(i)%kind == TOKEN_WORD .and. is_word(tokens(i)%text, 'first second graph screen character')) then
         system = tokens(i)%text
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
         elseif (word == 'offset') then
            block
               character(len=9) :: system !< Offset system (characters only).

               system = 'first'
               call pair(label%offset, system)
            endblock
         elseif (word == 'font') then
            ! the font is the page's: the name is read and ignored
            i = i + 1_I4P
         elseif (is_word(word, 'noenhanced enhanced')) then
            label%plain = word == 'noenhanced'
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
      real(R8P) :: size2(2) !< Head length and angle.

      do while (i <= size(tokens, kind=I4P))
         word = tokens(i)%text
         if (word == 'from') then
            call position(arrow%from)
            placed = .true.
         elseif (word == 'to' .or. word == 'rto') then
            call position(arrow%to)
            arrow%relative = word == 'rto'
         elseif (is_word(word, 'nohead head backhead heads')) then
            arrow%head = merge(0_I4P, merge(1_I4P, merge(2_I4P, 3_I4P, word == 'backhead'), word == 'head'), &
                               word == 'nohead')
         elseif (word == 'size') then
            arrow%length_system = 'first'
            call pair(size2, arrow%length_system)
            arrow%length = size2(1)
            if (size2(2) /= 0.0_R8P) arrow%angle = size2(2)
            ! a back angle is read and ignored
            if (i < size(tokens, kind=I4P)) then
               if (tokens(i + 1_I4P)%kind == TOKEN_COMMA) i = i + 2_I4P
            endif
         elseif (is_word(word, 'filled empty nofilled noborder')) then
            arrow%fill = word
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
         elseif (word == 'size') then
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

   subroutine load_data(self, data, file, iostat, iomsg, keep_text)
   !< Load the data file `file`, or the datablock it names (`$DATA`), with the `set datafile` options.
   class(script_object),          intent(in)           :: self      !< Interpreter.
   type(datafile_object),         intent(inout)        :: data      !< Data.
   character(len=*),              intent(in)           :: file      !< File or datablock name.
   integer(I4P),                  intent(out)          :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg     !< Error message.
   logical,                       intent(in), optional :: keep_text !< Keep the cell texts.
   character(len=:), allocatable                       :: lines     !< Datablock lines.
   logical                                             :: found     !< Datablock found.

   if (self%symbols%is_array(file)) then
      ! an array: the index and the value of each element, as gnuplot's `plot A`
      call data%load(file, iostat, iomsg, separator='', missing=self%missing, comments=self%comments, &
                     keep_text=keep_text, content=self%symbols%array_data(file))
   elseif (is_datablock(file)) then
      call self%symbols%string_of(file, lines, found)
      if (.not. found) then
         call fail('no datablock '//file, iostat, iomsg)
         return
      endif
      call data%load(file, iostat, iomsg, separator=self%separator, missing=self%missing, comments=self%comments, &
                     keep_text=keep_text, content=lines)
   else
      call data%load(file, iostat, iomsg, separator=self%separator, missing=self%missing, comments=self%comments, &
                     keep_text=keep_text)
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

   subroutine set_command(self, tokens, iostat, iomsg)
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

   iostat = 0_I4P
   iomsg = ''
   if (size(tokens) == 0) then
      call fail('set: missing option', iostat, iomsg)
      return
   endif
   option = tokens(1)%text
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
   elseif (keyword(option, 'label', 3_I4P) .or. keyword(option, 'arrow', 3_I4P) .or. keyword(option, 'object', 3_I4P)) &
      then
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
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user, tight=axis%noextend)
      endassociate
   elseif (keyword(option, 'yrange', 2_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%yaxis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user, tight=axis%noextend)
      endassociate
   elseif (keyword(option, 'y2range', 3_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%y2axis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user, tight=axis%noextend)
      endassociate
   elseif (keyword(option, 'x2range', 3_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%x2axis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user, tight=axis%noextend)
      endassociate
   elseif (keyword(option, 'logscale', 3_I4P)) then
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
      if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
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
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user)
         if (iostat == 0_I4P .and. axis%min_fixed .and. axis%max_fixed) then
            if (.not. axis%max_user > axis%min_user) call fail('set rrange: max must exceed min', iostat, iomsg)
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
   elseif (keyword(option, 'colorsequence', 6_I4P)) then
      call colorsequence_option
   elseif (keyword(option, 'cbrange', 3_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%cbaxis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user, tight=axis%noextend)
      endassociate
   elseif (keyword(option, 'cblabel', 3_I4P)) then
      if (.not. self%string_argument(tokens, text, iostat, iomsg)) return
      call self%figure%set_cblabel(text)
   elseif (keyword(option, 'colorbox', 4_I4P)) then
      call colorbox_option
   elseif (keyword(option, 'boxwidth', 3_I4P)) then
      call boxwidth_option
   elseif (keyword(option, 'output', 2_I4P)) then
      if (.not. self%string_argument(tokens, text, iostat, iomsg)) return
      if (len(text) == 0) then
         call fail('set output: a file name is required', iostat, iomsg)
         return
      endif
      self%output = text
      self%output_set = .true.
   elseif (keyword(option, 'encoding', 3_I4P)) then
      ! gnuplot's encodings foresight writes faithfully: default (bytes as they are) and utf8 (locale, here)
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
      if (.not. is_word(text, 'default utf8')) then
         call fail('set encoding: only default, utf8 and locale are supported (the output is UTF-8), not "'//text//'"', &
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
      elseif (tokens(2)%kind /= TOKEN_WORD .or. &
              verify(tokens(2)%text, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789') /= 0 .or. &
              scan(tokens(2)%text(1:1), '0123456789') > 0) then
         call fail('set dummy: a variable name is expected, found "'//tokens(2)%text//'"', iostat, iomsg)
         return
      else
         self%dummy = tokens(2)%text
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
            i = i + 1_I4P
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
      call samples_option
   elseif (keyword(option, 'format', 3_I4P)) then
      call format_option
   elseif (keyword(option, 'origin', 2_I4P)) then
      call pair_option([0.0_R8P, 0.0_R8P], tokens)
   elseif (keyword(option, 'size', 2_I4P)) then
      call size_option
   elseif (keyword(option, 'multiplot', 5_I4P)) then
      rows = 0_I4P
      cols = 0_I4P
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
            ! the font of the title: one font in foresight, the name read and ignored
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) then
               call fail('set multiplot: font needs a name', iostat, iomsg)
               return
            endif
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
      endif
      self%multiplot = .true.
      self%advance_pending = .false.
   else
      call fail('unsupported option "set '//option//'"', iostat, iomsg)
   endif
   contains
      subroutine set_range(min_fixed, min_user, max_fixed, max_user, tight)
      !< Parse `[min:max] [noextend|extend] [noreverse] [nowriteback]`: `*` or an empty end autoscales it, `[]` keeps
      !< both; `noextend` keeps autoscaled ends at the data (`tight`), as gnuplot.
      logical,   intent(inout)           :: min_fixed !< Start fixed.
      real(R8P), intent(inout)           :: min_user  !< Start value.
      logical,   intent(inout)           :: max_fixed !< End fixed.
      real(R8P), intent(inout)           :: max_user  !< End value.
      logical,   intent(inout), optional :: tight     !< Autoscaled ends not extended to the ticks.
      integer(I4P)                       :: colon     !< Separator position.
      integer(I4P)                       :: k         !< Option counter.

      if (size(tokens) < 2) then
         call fail('set '//option//': [min:max] expected', iostat, iomsg)
         return
      endif
      do k = 3_I4P, size(tokens, kind=I4P)
         select case (tokens(k)%text)
         case ('noextend', 'extend')
            if (.not. present(tight)) then
               call fail('set '//option//': '//tokens(k)%text//' applies to x, y, x2, y2 and cb', iostat, iomsg)
               return
            endif
            tight = tokens(k)%text == 'noextend'
         case ('noreverse', 'nowriteback')
            continue
         case default
            call fail('set '//option//': unsupported option "'//tokens(k)%text//'" (noextend, extend, noreverse, '// &
                      'nowriteback)', iostat, iomsg)
            return
         endselect
      enddo
      if (tokens(2)%kind == TOKEN_RANGE .and. len_trim(tokens(2)%text) == 0) return
      colon = top_colon(tokens(2)%text)
      if (tokens(2)%kind /= TOKEN_RANGE .or. colon == 0_I4P) then
         call fail('set '//option//': [min:max] expected', iostat, iomsg)
         return
      endif
      call range_end(tokens(2)%text(1:colon - 1_I4P), min_fixed, min_user)
      if (iostat /= 0_I4P) return
      call range_end(tokens(2)%text(colon + 1_I4P:), max_fixed, max_user)
      endsubroutine set_range

      subroutine range_end(text, fixed, value)
      !< One range end: empty or `*` autoscales, else a number or a constant expression (`2*pi`, user variables).
      character(len=*), intent(in)    :: text  !< End text.
      logical,          intent(inout) :: fixed !< End fixed.
      real(R8P),        intent(inout) :: value !< End value.
      real(R8P)                       :: v     !< Parsed value.

      if (len_trim(text) == 0 .or. trim(adjustl(text)) == '*') then
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
               ! the font is the page's: the name is read and ignored
               s = s + 2_I4P
            elseif (is_word(tokens(s + 1_I4P)%text, 'enhanced noenhanced')) then
               s = s + 1_I4P
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
         case ('logfile')
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
         case ('nologfile')
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
               ! one font in foresight: the name is read and ignored
               if (i < size(tokens, kind=I4P)) i = i + 1_I4P
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
      character(len=7), allocatable :: list(:) !< Linetype colors.
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
            ! the names kept for the themes (black, white) as their #rrggbb
            if (len(lt%lc) /= 7 .or. lt%lc(1:1) /= '#') then
               block
                  integer(I4P) :: c(3) !< Channels.
                  logical      :: ok   !< A named color.

                  call named_color(lt%lc, c, ok)
                  if (.not. ok) then
                     call fail('set linetype: a fixed opaque color is expected, not "'//lt%lc//'"', iostat, iomsg)
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
      integer(I4P), intent(in)      :: axis   !< Axis: 1 x, 2 y, 3 y2, 4 x2.
      logical                       :: ok     !< Success.
      character(len=*), parameter   :: WORDS = 'offset font tc textcolor textc textco textcol textcolo rotate norotate '// &
                                               'left right center centre noenhanced noenh enhanced enh' !< Options.
      real(R8P)                     :: offset(2) !< Shift [characters].
      real(R8P)                     :: z      !< gnuplot's z offset, ignored.
      character(len=24)             :: color  !< Color.
      logical                       :: plain  !< `noenhanced`: the label as it is.
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
      ok = .false.
      plain = .false.
      offset = self%figure%panels(self%figure%current)%label_offset(:, axis)
      color = self%figure%panels(self%figure%current)%label_color(axis)
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
            k = k + 1_I4P
            if (k > size(tokens, kind=I4P)) then
               call fail('set '//tokens(1)%text//': font needs a name', iostat, iomsg)
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
         case default
            call fail('set '//tokens(1)%text//': unexpected "'//tokens(k)%text//'" (offset, font, tc, rotate, '// &
                      'noenhanced)', iostat, iomsg)
            return
         endselect
         k = k + 1_I4P
      enddo
      self%figure%panels(self%figure%current)%label_plain(axis) = plain
      self%figure%panels(self%figure%current)%label_offset(:, axis) = offset
      self%figure%panels(self%figure%current)%label_color(axis) = color
      ok = .true.
      endfunction axis_label

      subroutine title_option
      !< `set title ["text"] [offset X,Y] [font "f"] [left|center|right] [tc COLOR] [noenhanced] [enhanced]`: the text,
      !< shifted by characters (x right, y up), justified about the centre (gnuplot's), in its color; `font` is read and
      !< ignored (one font in foresight); `noenhanced` writes it as it is, not enhanced text.
      real(R8P) :: offset(2) !< Shift [characters].
      integer(I4P) :: j      !< First option token.
      logical   :: plain     !< `noenhanced`: the title as it is.
      character(len=6)  :: anchor !< Justification.
      character(len=24) :: color  !< Color.

      j = size(tokens, kind=I4P) + 1_I4P
      do i = 2_I4P, size(tokens, kind=I4P)
         if (tokens(i)%kind /= TOKEN_WORD) cycle
         if (is_word(tokens(i)%text, 'offset font noenhanced noenh enhanced enh left right center centre tc '// &
                     'textcolor textc textco textcol textcolo')) then
            j = i
            exit
         endif
      enddo
      if (.not. self%string_argument(tokens(1:j - 1_I4P), text, iostat, iomsg)) return
      offset = self%figure%panels(self%figure%current)%title_offset
      anchor = self%figure%panels(self%figure%current)%title_anchor
      color = self%figure%panels(self%figure%current)%title_color
      plain = .false.
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
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) then
               call fail('set title: font needs a name', iostat, iomsg)
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
         case default
            call fail('set title: unexpected "'//tokens(i)%text//'" (offset, font, left, center, right, tc, '// &
                      'noenhanced)', iostat, iomsg)
            return
         endselect
         i = i + 1_I4P
      enddo
      call self%figure%set_title(text, offset=offset)
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
            if (.not. key_coordinate(at(1), sys(1), 'first ')) return
            if (i >= size(tokens, kind=I4P)) then
               call fail('set key at: X, Y expected', iostat, iomsg)
               return
            endif
            i = i + 1_I4P
            if (tokens(i)%kind /= TOKEN_COMMA) then
               call fail('set key at: X, Y expected', iostat, iomsg)
               return
            endif
            if (.not. key_coordinate(at(2), sys(2), sys(1))) return
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
            if (.not. next_real(tokens, i, xy(2), iostat, iomsg, self%symbols)) return
            call self%figure%set_key_style(offset=xy)
         case ('title')
            ! a string expression, or nothing (no title)
            if (i < size(tokens, kind=I4P)) then
               if (.not. is_word(tokens(i + 1_I4P)%text, 'font noenhanced enhanced box nobox')) then
                  i = i + 1_I4P
                  if (.not. self%string_expression(tokens, i, text, iostat, iomsg)) then
                     iomsg = 'set key title: '//iomsg
                     return
                  endif
                  call self%figure%set_key_style(title=text)
                  cycle
               endif
            endif
            call self%figure%set_key_style(title='')
         case ('notitle')
            call self%figure%set_key_style(title='')
         case ('font')
            ! read and ignored: one font in foresight
            i = i + 1_I4P
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

      function key_coordinate(v, system, default) result(ok)
      !< The coordinate after token `i` of `set key at`, `[SYSTEM] NUMBER`, advancing `i` to its number; `system` the
      !< one given, else `default`. Fails the command if malformed.
      real(R8P),        intent(out) :: v       !< Coordinate.
      character(len=6), intent(out) :: system  !< Its coordinate system.
      character(len=6), intent(in)  :: default !< System if none is given.
      logical                       :: ok      !< Read.

      ok = .false.
      v = 0.0_R8P
      system = default
      if (i >= size(tokens, kind=I4P)) then
         call fail('set key at: X, Y expected', iostat, iomsg)
         return
      endif
      if (is_word(tokens(i + 1_I4P)%text, 'first second graph screen')) then
         i = i + 1_I4P
         system = tokens(i)%text
      elseif (keyword(tokens(i + 1_I4P)%text, 'character', 4_I4P) .or. tokens(i + 1_I4P)%text == 'polar') then
         call fail('set key at: '//tokens(i + 1_I4P)%text//' coordinates are not supported (first, second, graph, '// &
                   'screen are)', iostat, iomsg)
         return
      endif
      if (i >= size(tokens, kind=I4P)) then
         call fail('set key at: X, Y expected', iostat, iomsg)
         return
      endif
      i = i + 1_I4P
      if (.not. to_number(tokens(i)%text, v)) then
         call fail('set key at: a number is expected, found "'//tokens(i)%text//'"', iostat, iomsg)
         return
      endif
      ok = .true.
      endfunction key_coordinate

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
      character(len=7), allocatable :: list(:) !< Colors.
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

      subroutine palette_option
      !< `set palette [WORDS]`: checked on a copy, then applied (see foresight_palette). `file 'f' [index N] [every E]
      !< [using U]` reads a gradient as gnuplot: 4 columns gray:r:g:b, or 3 columns r:g:b evenly spaced (default: 4
      !< if the rows have a 4th column), components 0 to 1 (clipped), `#` comments skipped, no blank lines.
      type(palette_object)                 :: probe  !< Palette the words are tried on.
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
      i = 2_I4P
      do while (i <= size(tokens, kind=I4P))
         if (tokens(i)%kind == TOKEN_WORD .and. tokens(i)%text == 'file' .and. len(file) == 0) then
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
                  call parse_every(word, pevery, iostat, iomsg)
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
      if (len(file) == 0) then
         call self%figure%set_palette(words)
         return
      endif
      call self%load_data(pdata, file, iostat, iomsg)
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
      if (size(pfields) /= 3 .and. size(pfields) /= 4) then
         call fail('set palette file: using needs r:g:b or gray:r:g:b', iostat, iomsg)
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
         call fail('set paxis: an axis number is expected, found "'//tokens(2)%text//'"', iostat, iomsg)
         return
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
            if (size(tokens) /= 4) then
               call fail('set paxis: range [min:max] expected', iostat, iomsg)
               return
            endif
            block
               integer(I4P) :: colon !< Separator position.

               colon = index(tokens(4)%text, ':', kind=I4P)
               if (tokens(4)%kind /= TOKEN_RANGE .or. colon == 0_I4P) then
                  call fail('set paxis: range [min:max] expected', iostat, iomsg)
                  return
               endif
               associate(axis => panel%paxes(n)%axis)
                  call range_end(tokens(4)%text(1:colon - 1_I4P), axis%min_fixed, axis%min_user)
                  if (iostat /= 0_I4P) return
                  call range_end(tokens(4)%text(colon + 1_I4P:), axis%max_fixed, axis%max_user)
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
                  if (to_number(tokens(i)%text, ratio)) then
                     if (ratio > 0.0_R8P) exit ok_ratio
                  endif
               endif
               call fail('set size: ratio needs a positive number (negative ratios are not supported)', iostat, iomsg)
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
      character(len=:), allocatable :: w      !< Word.
      character(len=:), allocatable :: base   !< Word without no.
      type(line_style_object)       :: style  !< Line properties.
      integer(I4P)                  :: k      !< Line index.

      associate(panel => self%figure%panels(self%figure%current))
         lines = panel%grid_lines
      endassociate
      polar = .false.
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
         elseif (keyword(w, 'polar', 2_I4P)) then
            polar = .true.
            if (i < size(tokens, kind=I4P)) then
               if (to_number(tokens(i + 1_I4P)%text, v)) then
                  step = v
                  ! in the angle unit
                  if (.not. self%figure%panels(self%figure%current)%degrees) step = step * (180.0_R8P / acos(-1.0_R8P))
                  i = i + 1_I4P
               endif
            endif
            if (.not. (step > 0.0_R8P .and. step < 360.0_R8P)) then
               call fail('set grid polar: the step must be positive and below a full turn', iostat, iomsg)
               return
            endif
         elseif (is_line_option(w)) then
            if (keyword(w, 'linetype', 5_I4P) .or. w == 'lt') then
               ! lt 0: gnuplot's grid dots, lt -1: the border's solid black
               if (.not. next_real(tokens, i, v, iostat, iomsg, self%symbols)) return
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
                      'front, back, layerdefault, lt, lc, lw, dt, polar [STEP], spiderplot)', iostat, iomsg)
            return
         endif
         i = i + 1_I4P
      enddo
      if (.not. any(lines)) lines(1:2) = .true.
      if (polar) then
         call self%figure%set_grid(.true., polar=step, lines=lines)
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
      !< `set ttics [[START,]STEP] [format "fmt"]`: theta labels [deg]; no step: every 45 degrees.
      character(len=:), allocatable :: format  !< Label format.
      character(len=:), allocatable :: message !< Format problem.
      real(R8P)                     :: v(2)    !< Start, step.
      integer(I4P)                  :: n       !< Position tokens.

      n = size(tokens, kind=I4P) - 1_I4P
      if (n >= 2_I4P) then
         if (keyword(tokens(n)%text, 'format', 1_I4P) .and. tokens(n)%kind == TOKEN_WORD .and. &
             tokens(n + 1_I4P)%kind == TOKEN_STRING) then
            format = tokens(n + 1_I4P)%text
            message = format_check(format)
            if (len(message) > 0) then
               call fail('set ttics: '//message, iostat, iomsg)
               return
            endif
            n = n - 2_I4P
         endif
      endif
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
      case default
         n = -1_I4P
      endselect
      if (n < 0_I4P) call fail('set ttics: supported forms are STEP and START,STEP (degrees, step > 0), with '// &
                               'format "fmt"', iostat, iomsg)
      endsubroutine ttics_option

      subroutine border_option
      !< `set border [MASK] [polar]`: the sides of the frame (1 bottom, 2 left, 4 top, 8 right; 31 by default) and the
      !< circle of the largest r on a polar panel.
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
         elseif (tokens(i)%kind == TOKEN_WORD .and. tokens(i)%text == 'front') then
            ! foresight draws the border over the data, gnuplot's default
            continue
         elseif (tokens(i)%kind == TOKEN_WORD .and. is_line_option(tokens(i)%text)) then
            if (.not. line_props(tokens, i, 'border')) return
         elseif (to_number(tokens(i)%text, v)) then
            if (v < 0.0_R8P .or. v > 4095.0_R8P .or. v /= aint(v)) then
               call fail('set border: the mask is an integer 0 to 4095', iostat, iomsg)
               return
            endif
            mask = int(v, I4P)
         else
            call fail('set border: unsupported option "'//tokens(i)%text//'" (MASK, polar, front, lt, lc, lw, dt)', &
                      iostat, iomsg)
            return
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
      if (tokens(i + 1_I4P)%text == 'at') then
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
            elseif (toks(i)%kind == TOKEN_WORD .and. is_word(toks(i)%text, 'rangelimited norangelimit')) then
               ! the ticks (and the border sides) within the data ranges
               panel%xaxis%tics%rangelimited = toks(i)%text == 'rangelimited'
               panel%yaxis%tics%rangelimited = toks(i)%text == 'rangelimited'
               panel%x2axis%tics%rangelimited = toks(i)%text == 'rangelimited'
               panel%y2axis%tics%rangelimited = toks(i)%text == 'rangelimited'
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
      !< (`fmt`, checked: a number or a time format), `font "f"` (read and ignored: one font), `offset X[,Y]`
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
         ! the font is the page's: the name is read and ignored
         if (i < size(toks, kind=I4P)) then
            if (toks(i + 1_I4P)%kind == TOKEN_STRING) i = i + 1_I4P
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
         copy = toks
         copy(i)%text = 'lc'
         if (.not. line_option(copy, i, probe, iostat, iomsg, self%figure%panels(self%figure%current)%linecolors, &
                               self%symbols)) return
         if (allocated(probe%lc)) then
            if (index(probe%lc, '*') == 1 .or. len(probe%lc) > len(tics%color)) then
               call fail('set '//option//': textcolor: variable and palette colors do not apply', iostat, iomsg)
               return
            endif
            tics%color = probe%lc
         endif
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
            if (.not. (keyword(option, 'xtics', 3_I4P) .or. keyword(option, 'x2tics', 4_I4P)) .and. &
                (toks(i)%text == 'rotate' .or. toks(i)%text == 'norotate')) then
               call fail('set '//option//': rotate is supported on xtics and x2tics only', iostat, iomsg)
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
         elseif (toks(i)%kind == TOKEN_WORD .and. is_word(toks(i)%text, 'rangelimited norangelimit')) then
            ! the ticks (and the border side) within the data range
            tics%rangelimited = toks(i)%text == 'rangelimited'
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
      if (allocated(fmt)) tics%format = fmt
      if (len_trim(justify) > 0) then
         if (tics%rotate == 0.0_R8P) then
            call fail('set '//option//': '//trim(justify)//' justifies rotated labels (with rotate)', iostat, iomsg)
            return
         endif
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
      if (n == 0_I4P) then
         if (allocated(mirror)) tics%mirror = mirror
         call tics%enable
         return
      endif
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
                  unit = tokens(4)%text
                  if (unit(len(unit):len(unit)) /= 's') unit = unit//'s'
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
         endif
         call item_position(rest, item)
         if (iostat /= 0_I4P) return
         call push(items, item)
      enddo
      endsubroutine list_items

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

      subroutine samples_option
      !< `set samples N[,M]`: N function samples, M (for surfaces) checked and ignored.
      integer(I4P) :: n !< Samples.
      integer(I4P) :: m !< Second sampling rate.

      i = 1_I4P
      if (.not. next_integer(tokens, i, n, iostat, iomsg)) then
         iomsg = 'set samples: '//iomsg
         return
      endif
      m = n
      if (size(tokens, kind=I4P) > i) then
         i = i + 1_I4P
         if (tokens(i)%kind /= TOKEN_COMMA) then
            call fail('set samples: N or N,M expected', iostat, iomsg)
            return
         endif
         if (.not. next_integer(tokens, i, m, iostat, iomsg)) then
            iomsg = 'set samples: '//iomsg
            return
         endif
         if (.not. no_more(tokens, i + 1_I4P, iostat, iomsg)) return
      endif
      if (n < 2_I4P .or. m < 2_I4P) then
         call fail('set samples: the sampling rate must be > 1', iostat, iomsg)
         return
      endif
      self%samples = n
      endsubroutine samples_option

      subroutine format_option
      !< `set format [x|y|y2|cb|x2|xy...] ["format"] [timedate|numeric]` (all axes by default): no format restores the
      !< default labels; a time format (`%H:%M`) labels time axes; `timedate` makes the axes time axes (ticks and
      !< labels, the data read as numbers), `numeric` numeric ones.
      character(len=:), allocatable :: axes    !< Axes letters.
      character(len=:), allocatable :: format  !< Label format.
      character(len=:), allocatable :: message !< Problem.
      character(len=:), allocatable :: kind    !< `timedate`, `numeric` or empty.

      axes = 'xyy2cbx2'
      format = ''
      i = 2_I4P
      ! a lone word before the format names the axes
      if (i < size(tokens, kind=I4P)) then
         if (tokens(i)%kind == TOKEN_WORD .and. expression_end(tokens, i) == i) then
            axes = tokens(i)%text
            if (.not. valid_axes(axes)) then
               call fail('set format: axes must be among x, y, y2, cb, x2 (e.g. y or xy2), not "'//axes//'"', iostat, iomsg)
               return
            endif
            i = i + 1_I4P
         endif
      elseif (i == size(tokens, kind=I4P)) then
         if (tokens(i)%kind == TOKEN_WORD .and. valid_axes(tokens(i)%text)) then
            axes = tokens(i)%text
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
      call self%figure%set_format(format, axes)
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
      !< `set style data|function STYLE`, `set style line N [lc ...] [lt N] [lw W] [dt N] [ps S]`.
      type(line_style_object) :: style !< New line style.
      character(len=:), allocatable :: with !< Style name.
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
            if (size(tokens) /= 3) then
               call fail('set style data: one style is expected', iostat, iomsg)
               return
            endif
            with = canonical_style(tokens(3)%text)
            if (len(with) == 0) then
               call fail('set style data: unsupported style "'//tokens(3)%text//'"', iostat, iomsg)
               return
            endif
            self%data_style = with
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
            if (size(tokens) /= 3) then
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
            self%function_style = with
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
      call fail('set style: only "data STYLE", "function STYLE", "line N ...", "fill ..." and "histogram ..." are '// &
                'supported', iostat, iomsg)
      endsubroutine style_option
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
   elseif (keyword(option, 'logscale', 3_I4P)) then
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
      if (size(tokens) == 2) ok = keyword(tokens(2)%text, 'function', 1_I4P) .or. keyword(tokens(2)%text, 'arrow', 3_I4P)
      if (.not. ok) then
         call fail('unset style: only "function" and "arrow" are supported', iostat, iomsg)
         return
      endif
      if (keyword(tokens(2)%text, 'arrow', 3_I4P)) then
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
         else
            call fail('unset datafile: unsupported option "'//tokens(2)%text//'" (separator, missing and '// &
                      'commentschars are)', iostat, iomsg)
            return
         endif
         if (.not. no_more(tokens, 3_I4P, iostat, iomsg)) return
         return
      endif
      self%separator = ''
      self%missing = ''
      self%comments = '#'
      return
   endif
   ! labels, arrows, objects take a tag (handled below)
   if (.not. (keyword(option, 'label', 3_I4P) .or. keyword(option, 'arrow', 3_I4P) .or. &
              keyword(option, 'object', 3_I4P))) then
      if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
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
   elseif (keyword(option, 'grid', 2_I4P)) then
      call self%figure%set_grid(.false., polar=0.0_R8P)
   elseif (keyword(option, 'polar', 3_I4P)) then
      call self%figure%set_polar(.false.)
   elseif (option == 'rgbmax') then
      self%rgbmax = 255.0_R8P
   elseif (keyword(option, 'spiderplot', 3_I4P)) then
      call self%figure%set_spiderplot(.false.)
      if (self%data_style == 'spiderplot') self%data_style = 'lines'
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
   else
      call fail('unsupported option "unset '//option//'"', iostat, iomsg)
   endif
   endsubroutine unset_command

   ! helpers
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
   character(len=*), parameter  :: LETTERS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_'

   yes = len(word) >= 2
   if (yes) yes = word(1:1) == '$' .and. scan(word(2:2), LETTERS) > 0
   if (yes) yes = verify(word(2:), LETTERS//'0123456789') == 0
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
   if (verify(rest(1:e), 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789') /= 0) return
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
   e = verify(t, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_', kind=I4P)
   if (e == 0_I4P) e = len(t, kind=I4P) + 1_I4P
   word = t(1:e - 1_I4P)
   endfunction leading_word

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
   character(len=*), parameter  :: WORD = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789'
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
   character(len=*), parameter   :: LETTERS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_'
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
      if (scan(s(1:1), LETTERS) > 0) e = verify(s, LETTERS//'0123456789', kind=I4P)
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
   !< output, its trailing newline dropped.
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
         case ('(', '[')
            depth = depth + 1_I4P
         case (')', ']')
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

   subroutine parse_using(spec, fields, iostat, iomsg, degrees, symbols)
   !< `using` specification: 1 to 6 colon separated fields, each a column number (0 is the point number) or a
   !< parenthesized expression (with the user variables and functions of `symbols`), as in gnuplot.
   character(len=*),                     intent(in)  :: spec      !< Specification.
   type(expression_object), allocatable, intent(out) :: fields(:) !< Fields.
   character(len=:), allocatable,        intent(out) :: iomsg     !< Error message.
   integer(I4P),                         intent(out) :: iostat    !< 0 on success.
   logical,                              intent(in)  :: degrees   !< Angles of the expressions in degrees.
   type(symbols_object),                 intent(in)  :: symbols   !< User variables and functions.
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
         call field%compile(text, iostat, iomsg, degrees=degrees, symbols=symbols)
         if (iostat /= 0_I4P) then
            iomsg = 'using: '//iomsg
            return
         endif
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
   character(len=7),        intent(in), optional :: colors(:) !< Active linetype colors (`set colorsequence`).
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
      return
   enddo
   line%lc = default_color(id, colors)
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

   yes = is_word(with, 'lines points linespoints impulses steps fsteps histeps dots boxes filledcurves')
   endfunction function_drawable

   pure function is_item_option(word) result(is)
   !< Whether `word` is a plot item option: it ends a function expression.
   character(len=*), intent(in) :: word !< Word.
   logical                      :: is   !< Item option.

   is = keyword(word, 'using', 1_I4P) .or. keyword(word, 'index', 1_I4P) .or. keyword(word, 'every', 2_I4P) .or. &
        keyword(word, 'with', 1_I4P) .or. keyword(word, 'title', 1_I4P) .or. keyword(word, 'notitle', 3_I4P) .or. &
        keyword(word, 'axes', 2_I4P) .or. keyword(word, 'smooth', 1_I4P) .or. word == 'ls' .or. &
        keyword(word, 'linestyle', 5_I4P) .or. is_line_option(word) .or. word == 'format' .or. word == 'fs' .or. &
        keyword(word, 'fillstyle', 5_I4P) .or. keyword(word, 'matrix', 3_I4P) .or. keyword(word, 'whiskerbars', 7_I4P) &
        .or. word == 'bins' .or. index(word, 'bins=') == 1 .or. word == 'noenhanced' .or. word == 'enhanced'
   endfunction is_item_option

   pure function is_line_option(word) result(is)
   !< Whether `word` names a line property: `lc`, `lt`, `lw`, `dt`, `ps`, `pt` or their long forms.
   character(len=*), intent(in) :: word !< Option word.
   logical                      :: is   !< Line property.

   is = word == 'lc' .or. keyword(word, 'linecolor', 5_I4P) .or. word == 'lt' .or. keyword(word, 'linetype', 5_I4P) &
        .or. word == 'lw' .or. keyword(word, 'linewidth', 5_I4P) .or. word == 'dt' .or. keyword(word, 'dashtype', 5_I4P) &
        .or. word == 'ps' .or. keyword(word, 'pointsize', 6_I4P) .or. word == 'pt' .or. keyword(word, 'pointtype', 6_I4P) &
        .or. word == 'pi' .or. keyword(word, 'pointinterval', 6_I4P)
   endfunction is_line_option

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
   character(len=7),              intent(in), optional :: colors(:) !< Active linetype colors (`set colorsequence`).
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
                  if (.not. (is_item_option(tokens(i + 1_I4P)%text) .or. &
                             is_line_option(tokens(i + 1_I4P)%text))) then
                     call fail('lc palette '//tokens(i + 1_I4P)%text//': only z, cb V and frac F (no named colormap)', &
                               iostat, iomsg)
                     ok = .false.
                  endif
               endselect
            endif
         endif
      elseif (tokens(i)%kind == TOKEN_STRING) then
         line%lc = tokens(i)%text
      else
         i = i - 1_I4P
         ok = next_integer(tokens, i, number, iostat, iomsg, symbols)
         if (ok) line%lc = default_color(number, colors)
      endif
   elseif (word == 'lt' .or. keyword(word, 'linetype', 5_I4P)) then
      ok = next_integer(tokens, i, number, iostat, iomsg, symbols)
      if (ok) line%lc = default_color(number, colors)
   elseif (word == 'lw' .or. keyword(word, 'linewidth', 5_I4P)) then
      ok = next_real(tokens, i, value, iostat, iomsg, symbols)
      if (ok) line%lw = value
   elseif (word == 'dt' .or. keyword(word, 'dashtype', 5_I4P)) then
      ok = next_integer(tokens, i, number, iostat, iomsg, symbols)
      if (ok) line%dt = number
   elseif (word == 'pi' .or. keyword(word, 'pointinterval', 6_I4P)) then
      ! a point every N (gnuplot's negative N, the line broken around the points, draws the points every |N|)
      ok = next_integer(tokens, i, number, iostat, iomsg, symbols)
      if (ok .and. number == 0_I4P) then
         call fail('pointinterval: N not 0 is expected', iostat, iomsg)
         ok = .false.
      endif
      if (ok) line%pi = abs(number)
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
   endfunction line_option

   subroutine parse_every(spec, every, iostat, iomsg)
   !< gnuplot `every point_incr:block_incr:start_point:start_block:end_point:end_block`; empty or missing fields keep
   !< their defaults (1, 1, 0, 0, no end, no end).
   character(len=*),              intent(in)  :: spec     !< Specification.
   integer(I4P),                  intent(out) :: every(6) !< Fields, ends -1 for none.
   integer(I4P),                  intent(out) :: iostat   !< 0 on success.
   character(len=:), allocatable, intent(out) :: iomsg    !< Error message.
   integer(I4P)                               :: start    !< Field start.
   integer(I4P)                               :: colon    !< Field end.
   integer(I4P)                               :: f        !< Field counter.
   logical                                    :: ok       !< Field valid.

   iostat = 0_I4P
   iomsg = ''
   every = [1_I4P, 1_I4P, 0_I4P, 0_I4P, -1_I4P, -1_I4P]
   ok = verify(spec, '0123456789:') == 0
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
