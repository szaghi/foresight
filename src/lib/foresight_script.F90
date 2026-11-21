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
!<   clustered [gap G]|rowstacked`; `using ...:xtic(N)` / `xticlabels(N)`: the text of column N labels the abscissae,
!<   the labels replacing the x ticks; `xtic(EXPR)` a string expression (`strcol(1) . ' K'`);
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
!< - datablocks `$NAME << WORD` (the lines up to one starting with WORD) plotted, fitted, stated as a file (`plot $D`),
!<   `print $NAME`, `load FILE`, `call FILE ARG1 ...` (ARG0..ARG9, ARGC, restored after it), `eval STRING`, macros
!<   `@name` (a string variable's value), `undefine NAME|NAME*|$NAME`;
!< - a function of `x` as a plot item, `plot sin(x)/x title "sinc"` (same options, styles lines, points or linespoints,
!<   `set style function`, `lines` by default): sampled at `set samples` points (100) over the x range before its
!<   extension to the ticks, the data extent, or [-10:10] with neither; evenly in log x on a log axis.
!<
!< Anything else is an error naming the command, never silently ignored. Errors are returned (`iostat`, `iomsg` with
!< `source:line:`), not stopped on, so a watch loop can survive a bad cycle.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite, ieee_quiet_nan, ieee_value
use, intrinsic :: iso_fortran_env, only : error_unit, output_unit
use foresight_axes, only : axes_names, boxplot_style, boxplot_words, polar_series, spider_words, POLAR_STYLES
use foresight_datafile, only : datafile_object
use foresight_expression, only : expression_object, push, saved_variable, symbols_object
use foresight_figure, only : figure_object
use foresight_format, only : c_real, format_check, int_str, real_from_decimal
use foresight_readout, only : readout_check
use foresight_fit, only : fit_model, fit_report, fit_result, fit_settings, levenberg_marquardt
use foresight_stats, only : stats, stats_column, stats_report, stats_result
use foresight_smooth, only : bin_values, CURVE_MODES, smooth, smooth_curve, SMOOTH_MODES
use foresight_palette, only : palette_gradient, palette_object, palette_words
use foresight_theme, only : THEMES
use foresight_style, only : default_color, fill_style, sequence_colors, style_name, style_object, style_with, &
                            STYLE_NAMES, WITH_GAUGE, WITH_PARALLELAXES, WITH_PIE, WITH_RADAR, WITH_ROSE, WITH_SPIDERPLOT
use foresight_ticks, only : MINOR_AUTO, MINOR_DEFAULT, push, tic_item, tics_object
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
character(len=12), parameter :: LC_VARIABLE     = '*variable'    !< `lc variable` marker in a line color.
character(len=12), parameter :: LC_RGB_VARIABLE = '*rgbvariable' !< `lc rgb variable` marker in a line color.
character(len=12), parameter :: LC_PALETTE_Z    = '*palettez'    !< `lc palette [z]` marker in a line color.
character(len=12), parameter :: LC_PALETTE_CB   = '*palettecb'   !< `lc palette cb V` marker in a line color.
character(len=12), parameter :: LC_PALETTE_FRAC = '*palettefrac' !< `lc palette frac F` marker in a line color.
character(len=*), parameter :: FUNCTION_STYLES = 'lines, points, linespoints, impulses, steps, fsteps, histeps or dots' !< Styles
                                                 !< drawing functions.

type :: line_style_object
   !< Line properties: a `set style line`, or the options of a plot item; unallocated means the default.
   integer(I4P)                  :: id = 0_I4P !< Style number.
   character(len=:), allocatable :: lc         !< Color.
   real(R8P),        allocatable :: lw         !< Line width.
   integer(I4P),     allocatable :: dt         !< Dash type.
   real(R8P),        allocatable :: ps         !< Point size.
   integer(I4P),     allocatable :: pt         !< Point type.
   real(R8P)                     :: palette = 0.0_R8P !< Value of `lc palette cb V` or `frac F`.
endtype line_style_object

type :: loop_level
   !< One `for [...]` clause of a plot item: its variable, values, the value in use and the variable before the loop.
   character(len=:), allocatable   :: name           !< Loop variable.
   type(token_object), allocatable :: values(:)      !< Values, as text.
   logical                         :: words = .false. !< String values.
   integer(I4P)                    :: pos = 1_I4P    !< Value in use.
   type(saved_variable)            :: saved          !< The variable before the loop.
endtype loop_level

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
   character(len=:), allocatable   :: print_file               !< `set print`: '' the standard error (gnuplot's
                                                               !< default), '-' the standard output, else a file.
   integer(I4P)                    :: loop_depth = 0_I4P       !< Loops (`do for`, `while`) being run.
   integer(I4P)                    :: loop_signal = 0_I4P      !< `break` (1) or `continue` (2) pending, else 0.
   contains
      procedure, pass(self) :: execute                !< Execute one statement.
      procedure, pass(self) :: init                   !< Reset the interpreter.
      procedure, pass(self) :: run_file               !< Run a script file.
      procedure, pass(self) :: run_text               !< Run script text.
      procedure, pass(self), private :: assignment    !< `a = 2`, `f(x) = ...`.
      procedure, pass(self), private :: plot_command  !< `plot`.
      procedure, pass(self), private :: fit_command   !< `fit`.
      procedure, pass(self), private :: print_command !< `print`.
      procedure, pass(self), private :: stats_command !< `stats`.
      procedure, pass(self), private :: load_data     !< Load a data file or a datablock.
      procedure, pass(self), private :: call_command  !< `load`, `call`.
      procedure, pass(self), private :: expand_macros !< `@name` substitution.
      procedure, pass(self), private :: do_block      !< `do for [...] { ... }`.
      procedure, pass(self), private :: while_block   !< `while (...) { ... }`.
      procedure, pass(self), private :: if_block      !< `if (...) { ... } else ...`.
      procedure, pass(self), private :: run_body      !< The statements of a block.
      procedure, pass(self), private :: run_loops     !< Nested `for` clauses of a block.
      procedure, pass(self), private :: string_expression !< A string expression across tokens.
      procedure, pass(self), private :: string_argument   !< The string after a set option.
      procedure, pass(self), private :: register_file !< Remember a data file.
      procedure, pass(self), private :: save_output   !< Render to the current output.
      procedure, pass(self), private :: set_command   !< `set`.
      procedure, pass(self), private :: unset_command !< `unset`.
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

contains
   subroutine init(self, output, theme)
   !< Reset the interpreter; plots go to `output` until `set output`, in the output `theme` (see foresight_theme, blank
   !< or absent: `classic`) until `set terminal ... theme`.
   class(script_object), intent(inout)        :: self   !< Interpreter.
   character(len=*),     intent(in)           :: output !< Default output file.
   character(len=*),     intent(in), optional :: theme  !< Default output theme.

   call self%figure%init
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
   self%fit_options = fit_settings()
   self%fit_verbosity = 'quiet'
   self%fit_logfile = ''
   self%fit_errorvariables = .true.
   self%print_file = ''
   self%loop_depth = 0_I4P
   self%loop_signal = 0_I4P
   endsubroutine init

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
   endsubroutine run_file

   recursive subroutine run_text(self, text, iostat, iomsg, source)
   !< Run script `text`: lines ending in `\` continue on the next one; the first error stops the run. A line
   !< `$NAME << WORD` starts a datablock: the lines after it, as they are, up to a line starting with WORD.
   class(script_object),          intent(inout)        :: self       !< Interpreter.
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
            call self%symbols%set_string(here_name, here_text)
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
      if (len(block) == 0 .and. heredoc(line, here_name, here_end)) then
         here_text = ''
         here_line = first_line
         line = ''
         cycle
      endif
      call take(line)
      if (iostat /= 0_I4P) return
      line = ''
   enddo
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

      call split_statements(logical_line, statements)
      do s = 1_I4P, size(statements, kind=I4P)
         call self%execute(statements(s)%text, iostat, iomsg)
         if (iostat /= 0_I4P) then
            iomsg = name//':'//int_str(int(at, I8P))//': '//iomsg
            return
         endif
      enddo
      endsubroutine process
   endsubroutine run_text

   recursive subroutine execute(self, statement, iostat, iomsg)
   !< Execute one statement.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   character(len=*),              intent(in)    :: statement !< Statement.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   type(token_object), allocatable              :: tokens(:) !< Statement tokens.
   character(len=:), allocatable                :: command   !< Command word.
   character(len=:), allocatable                :: expanded  !< Statement after `@name` substitution.
   character(len=:), allocatable                :: text      !< String argument.
   integer(I4P)                                 :: i         !< Token counter.

   ! blocks, flow control (their bodies are expanded statement by statement, when they run)
   command = leading_word(statement)
   if (.not. is_word(command, 'do while if else')) then
      call self%expand_macros(statement, expanded, iostat, iomsg)
      if (iostat /= 0_I4P) return
      if (expanded /= statement) then
         call self%execute(expanded, iostat, iomsg)
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
   if (tokens(1)%kind /= TOKEN_WORD) then
      call fail('a command was expected, found "'//tokens(1)%text//'"', iostat, iomsg)
      return
   endif
   command = tokens(1)%text
   ! in a multiplot, the first command after a plot opens the next panel (the multiplot options excepted)
   if (self%advance_pending .and. (keyword(command, 'set', 2_I4P) .or. keyword(command, 'unset', 3_I4P) .or. &
                                   keyword(command, 'plot', 1_I4P))) then
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
      ! variables and datablocks; NAME* every variable whose name starts with NAME
      if (size(tokens) < 2) then
         call fail('undefine: a variable name is expected', iostat, iomsg)
         return
      endif
      do i = 2_I4P, size(tokens, kind=I4P)
         text = tokens(i)%text
         if (tokens(i)%kind /= TOKEN_WORD .or. len(text) == 0) then
            call fail('undefine: a variable name is expected, found "'//text//'"', iostat, iomsg)
            return
         endif
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
      if (is_datablock(tokens(i)%text)) then
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

   recursive subroutine do_block(self, statement, iostat, iomsg)
   !< gnuplot `do for [i = a:b[:c]] [for [...]] { ... }` and `do for [w in "words"] { ... }`: the body run for each value,
   !< the clauses nested left to right; the loop variable is local to the loop (its value before is restored, or it is
   !< removed), bounds are truncated to integers, `break` leaves the whole `do`, `continue` its innermost clause.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   character(len=*),              intent(in)    :: statement !< The whole statement.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   type(token_object), allocatable              :: specs(:)  !< `for` clauses, brackets removed.
   type(token_object)                           :: spec      !< One clause.
   character(len=:), allocatable                :: rest      !< Text still to read.
   character(len=:), allocatable                :: after     !< Text after a part read.
   character(len=:), allocatable                :: body      !< Block body.
   integer(I4P)                                 :: close     !< Closing bracket.

   iostat = 0_I4P
   iomsg = ''
   allocate(specs(0))
   rest = trim(adjustl(statement))
   rest = trim(adjustl(rest(3:)))
   do while (leading_word(rest) == 'for')
      rest = trim(adjustl(rest(4:)))
      close = 0_I4P
      if (len(rest) > 0) then
         if (rest(1:1) == '[') close = matching(rest, 1_I4P)
      endif
      if (close == 0_I4P) then
         call fail('do for: [i = a:b] or [w in "words"] expected', iostat, iomsg)
         return
      endif
      spec%text = rest(2:close - 1_I4P)
      call push(specs, spec)
      rest = trim(adjustl(rest(close + 1_I4P:)))
   enddo
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
   self%loop_signal = 0_I4P
   endsubroutine do_block

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
      if (iostat /= 0_I4P .or. self%loop_signal == 1_I4P) exit
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
      if (iostat /= 0_I4P .or. self%loop_signal == 1_I4P) exit
      self%loop_signal = 0_I4P
   enddo
   self%loop_depth = self%loop_depth - 1_I4P
   self%loop_signal = 0_I4P
   endsubroutine while_block

   recursive subroutine if_block(self, statement, iostat, iomsg)
   !< gnuplot `if (condition) { ... } [else if (condition) { ... }]... [else { ... }]`: the first block whose condition
   !< holds is run. gnuplot's old one-line form, `if (condition) command`, is not supported.
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
         call fail('if: { ... } expected after the condition (the old one-line form is not supported)', iostat, iomsg)
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
      call self%execute(statements(s)%text, iostat, iomsg)
      if (iostat /= 0_I4P .or. self%loop_signal /= 0_I4P) return
   enddo
   endsubroutine run_body

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
   found = is_datablock(file)
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
      !< Blank lines and blocks of the file (a block ends at two blank lines), header records, columns: gnuplot's.
      character(len=:), allocatable :: text  !< File content.
      character(len=256)            :: line  !< One line.
      integer(I4P)                  :: u     !< Unit.
      integer(I4P)                  :: ios   !< Status.
      integer(I4P)                  :: run   !< Consecutive blank lines.
      integer(I4P)                  :: doubles !< Second blank lines.

      r%blank = 0_I4P
      doubles = 0_I4P
      run = 0_I4P
      open(newunit=u, file=file, action='read', iostat=ios)
      if (ios == 0_I4P) then
         do
            read(u, '(A)', iostat=ios) line
            if (ios /= 0_I4P) exit
            text = trim(line)
            if (len(trim(adjustl(text))) == 0 .or. text == achar(13)) then
               r%blank = r%blank + 1_I4P
               run = run + 1_I4P
               if (run == 2_I4P) doubles = doubles + 1_I4P
            else
               run = 0_I4P
            endif
         enddo
         close(u)
      endif
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
      call self%symbols%text_of(parts(k)%text, value, is_string, iostat, iomsg, &
                                degrees=self%figure%panels(self%figure%current)%degrees)
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
   real(R8P),        allocatable                :: arcs(:,:) !< Wedge angles of circles.
   integer(I4P)                                 :: label_col !< Column of `xtic(N)`, 1 for an expression, 0 for none.
   type(expression_object)                      :: label_field !< Field of the text labels (`xtic(...)`, labels).
   logical                                      :: needs_text !< The cell texts are read (`strcol`, labels).
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
   integer(I4P)                                 :: nranges   !< Inline ranges read.

   iostat = 0_I4P
   iomsg = ''
   loaded = ''
   allocate(functions(0), slots(0))
   call self%figure%clear
   if (size(tokens) == 0) then
      call fail('plot: nothing to plot', iostat, iomsg)
      return
   endif
   ! gnuplot's dummy variable is t in polar mode
   dummy = merge('t', 'x', self%figure%panels(self%figure%current)%polar)
   ! inline ranges, [x] then [y], for this plot only: plot [0:2*pi] [-1:1] sin(x), plot [t=0:1] t**2
   i = 1_I4P
   nranges = 0_I4P
   do while (i <= size(tokens, kind=I4P))
      if (tokens(i)%kind /= TOKEN_RANGE) exit
      nranges = nranges + 1_I4P
      if (nranges > 2_I4P) then
         call fail('plot: at most two inline ranges, [x] and [y], are supported', iostat, iomsg)
         return
      endif
      if (self%figure%panels(self%figure%current)%polar) then
         call fail('plot: inline ranges are not supported in polar mode (use set trange and set rrange)', iostat, iomsg)
         return
      endif
      call inline_range(tokens(i)%text, nranges == 1_I4P)
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
      is_function = tokens(i)%kind == TOKEN_WORD
      quote = ' '
      ! a word joined to strings or substrings is a string expression, a file name: d[1:3] . "x.dat"
      if (is_function) is_function = all(tokens(i:expression_end(tokens, i))%kind == TOKEN_WORD)
      if (tokens(i)%kind == TOKEN_RANGE) then
         call fail('plot: inline ranges go before the first item, found "['//tokens(i)%text//']"', iostat, iomsg)
         return
      elseif (tokens(i)%kind == TOKEN_COMMA) then
         call fail('plot: missing item before ","', iostat, iomsg)
         return
      elseif (is_datablock(tokens(i)%text) .and. tokens(i)%kind == TOKEN_WORD) then
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
      ! modifiers
      if (allocated(fields)) deallocate(fields)
      spec = ''
      label_col = 0_I4P
      is_matrix = .false.
      set_index = -1_I4P
      every = [1_I4P, 1_I4P, 0_I4P, 0_I4P, -1_I4P, -1_I4P]
      with = self%data_style
      if (is_function) with = self%function_style
      has_title = .false.
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
            call split_xtic(spec, label_col, iostat, iomsg, keyed, label_field)
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
            if (is_function .and. .not. function_drawable(with)) then
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
                  if (is_word(word, 'closed x1 x2 above below')) then
                     i = i + 1_I4P
                     curve = curve//' '//word
                  elseif (index(word, 'y=') == 1 .or. index(word, 'y1=') == 1) then
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
                  elseif (is_word(word, 'y1 y2 r') .or. index(word, 'x=') == 1 .or. index(word, 'x1=') == 1 .or. &
                          index(word, 'x2=') == 1 .or. index(word, 'y2=') == 1 .or. index(word, 'r=') == 1) then
                     call fail('plot: filledcurves '//word//' is not supported (closed, x1, x2, y=V, xy=X,Y, above, '// &
                               'below and a band x:y1:y2 are)', iostat, iomsg)
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
      if (keyed .and. with /= 'spiderplot') then
         call fail('plot: key(N) names the rows of a spider plot', iostat, iomsg)
         return
      endif
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
      if (is_function) then
         ! sampled at the end; gnuplot: the expression as written is the title
         if (.not. has_title .and. self%autotitle /= 'none') title = written
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
         call self%figure%plot([real(R8P) ::], [real(R8P) ::], title=title, with=with, lc=line%lc, lw=line%lw, &
                               dt=line%dt, ps=line%ps, axes=axes, pt=line%pt)
         if (len(palette_lc) > 0) call paint_last
         call push(functions, func)
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
      needs_text = label_col > 0_I4P
      if (allocated(fields)) needs_text = needs_text .or. any(fields%uses_text())
      if (file /= loaded .or. (needs_text .and. .not. data%has_text)) then
         call self%load_data(data, file, iostat, iomsg, keep_text=needs_text)
         if (iostat /= 0_I4P) return
         loaded = file
         call self%register_file(file)
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
         if (.not. is_word(with, 'lines points linespoints impulses')) then
            call fail('plot: '//word//' applies to lines, points, linespoints and impulses, not to '//with, iostat, &
                      iomsg)
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
            ! gnuplot: the item as written, '' included
            title = trim(quote)//written//trim(quote)
            if (len(spec) > 0) title = title//' '//using//' '//spec
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
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, axes=axes, fs=fs, &
                               xlabels=xlabels, radius=widths, angles=arcs)
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
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, axes=axes, fs=fs, &
                               major=xlow, minor=xhigh, angle=ylow)
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
         if ((index(curve, 'x1') > 0 .or. index(curve, 'x2') > 0 .or. index(curve, 'xy=') > 0) .and. &
             (allocated(base) .or. allocated(ylow))) then
            call fail('plot: filledcurves x1, x2, xy= fill to the plot or a point: not with y=V nor a band', iostat, &
                      iomsg)
            return
         endif
         if ((index(curve, 'above') > 0 .or. index(curve, 'below') > 0) .and. &
             .not. (allocated(base) .or. allocated(ylow))) then
            call fail('plot: filledcurves above and below need y=V or a band x:y1:y2', iostat, iomsg)
            return
         endif
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, ylow=ylow, axes=axes, &
                               base=base, fs=fs, xlabels=xlabels, curve=curve)
      elseif (with == 'boxes' .or. with == 'filledcurves' .or. with == 'histograms') then
         if (allocated(fs)) then
            if (.not. fill_ok(fs)) return
         endif
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, ylow=ylow, axes=axes, &
                               width=widths, base=base, fs=fs, xlabels=xlabels)
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
      if (binned) then
         ! the autoscale spans the outer bin edges and y = 0, as gnuplot
         associate(panel => self%figure%panels(self%figure%current))
            panel%series(size(panel%series))%spanned = .true.
            panel%series(size(panel%series))%span = [bin_edges(1), bin_edges(2), 0.0_R8P, 0.0_R8P]
         endassociate
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
   if (size(functions) > 0) call sample_functions
   if (self%multiplot) self%advance_pending = .true.
   ! a multiplot on the standard output is printed once, complete, at unset multiplot (as gnuplot); files are rewritten
   ! at each plot, so that a watched page shows the panels done so far
   if (self%multiplot .and. self%output == '-') return
   call self%save_output(iostat, iomsg)
   contains
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
         call for_values(self, tokens(i + 1_I4P)%text, level%name, level%values, level%words, iostat, iomsg)
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

      subroutine inline_range(text, first)
      !< An inline range `[min:max]` of the plot command (`text` without brackets): of x if `first` (where
      !< `[name=min:max]` also names the dummy variable), else of y; an empty or `*` end keeps the set one, as gnuplot.
      character(len=*), intent(in)  :: text  !< Range text.
      logical,          intent(in)  :: first !< The first range: x.
      character(len=:), allocatable :: body  !< Range without the dummy variable.
      integer(I4P)                  :: colon !< Separator.
      integer(I4P)                  :: equal !< Dummy variable separator.

      body = text
      equal = index(text, '=', kind=I4P)
      colon = index(text, ':', kind=I4P)
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
         colon = index(body, ':', kind=I4P)
      endif
      if (len_trim(body) == 0) return
      if (colon == 0_I4P) then
         call fail('plot: inline range "['//text//']": [min:max] expected', iostat, iomsg)
         return
      endif
      associate(panel => self%figure%panels(self%figure%current))
         if (first) then
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
      if (.not. to_number(trim(adjustl(text)), v)) then
         call self%symbols%constant(trim(adjustl(text)), v, iostat, iomsg, &
                                    degrees=self%figure%panels(self%figure%current)%degrees)
         if (iostat /= 0_I4P) then
            iomsg = 'plot: inline range: '//iomsg
            return
         endif
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

      subroutine split_xtic(spec, column, iostat, iomsg, keyed, field)
      !< Remove a last `using` field `xtic(...)` or `xticlabels(...)` from `spec`, returning its `field`: a column N
      !< (`column` N), or a string expression (`xtic(strcol(1) . ' K')`, `xtic("a")` the same text on every row;
      !< `column` 1), `column` 0 if none; `key(N)` (the row names of a spider plot) likewise, with `keyed` true.
      character(len=:), allocatable, intent(inout) :: spec   !< `using` specification.
      integer(I4P),                  intent(out)   :: column !< Label column, 0 for none.
      integer(I4P),                  intent(inout) :: iostat !< Status.
      character(len=:), allocatable, intent(inout) :: iomsg  !< Error message.
      logical,                       intent(out)   :: keyed  !< The field is `key(N)`.
      type(expression_object),       intent(inout) :: field  !< Label field.
      character(len=:), allocatable                :: last   !< Last field.
      character(len=:), allocatable                :: inner  !< Argument of the label field.
      integer(I4P)                                 :: k      !< Character counter.
      integer(I4P)                                 :: depth  !< Parenthesis depth.
      integer(I4P)                                 :: cut    !< Last top-level colon, 0 for none.
      real(R8P)                                    :: v      !< Column number.

      column = 0_I4P
      keyed = .false.
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
      if (index(last, 'xtic(') /= 1 .and. index(last, 'xticlabels(') /= 1 .and. .not. keyed) then
         if (index(last, 'ytic(') == 1 .or. index(last, 'x2tic(') == 1 .or. index(last, 'ticlabels(') > 0) &
            call fail('plot: only xtic(N) labels are supported, found "'//last//'"', iostat, iomsg)
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
               panel%series(slots(f))%x = xs
               panel%series(slots(f))%y = ys
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
                  series%x = xs2
               else
                  series%x = xs
               endif
               series%y = ys
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
   endif
   call self%register_file(file)
   call self%run_file(file, status, message)
   ! the ARG variables back, also after an error
   do k = 1_I4P, 11_I4P
      call self%symbols%restore(saved(k))
   enddo
   iostat = status
   iomsg = message
   endsubroutine call_command

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

   if (is_datablock(file)) then
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

   if (is_datablock(file)) return
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
   integer(I4P)                                 :: width     !< Terminal width.
   integer(I4P)                                 :: height    !< Terminal height.
   integer(I4P)                                 :: seconds   !< Refresh period.
   integer(I4P)                                 :: rows      !< Multiplot rows.
   integer(I4P)                                 :: cols      !< Multiplot columns.

   iostat = 0_I4P
   iomsg = ''
   if (size(tokens) == 0) then
      call fail('set: missing option', iostat, iomsg)
      return
   endif
   option = tokens(1)%text
   if (keyword(option, 'title', 3_I4P)) then
      if (.not. self%string_argument(tokens, text, iostat, iomsg)) return
      call self%figure%set_title(text)
   elseif (keyword(option, 'xlabel', 2_I4P)) then
      if (.not. self%string_argument(tokens, text, iostat, iomsg)) return
      call self%figure%set_xlabel(text)
   elseif (keyword(option, 'ylabel', 2_I4P)) then
      if (.not. self%string_argument(tokens, text, iostat, iomsg)) return
      call self%figure%set_ylabel(text)
   elseif (keyword(option, 'y2label', 3_I4P)) then
      if (.not. self%string_argument(tokens, text, iostat, iomsg)) return
      call self%figure%set_y2label(text)
   elseif (keyword(option, 'x2label', 3_I4P)) then
      if (.not. self%string_argument(tokens, text, iostat, iomsg)) return
      call self%figure%set_x2label(text)
   elseif (keyword(option, 'xrange', 2_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%xaxis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user)
      endassociate
   elseif (keyword(option, 'yrange', 2_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%yaxis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user)
      endassociate
   elseif (keyword(option, 'y2range', 3_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%y2axis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user)
      endassociate
   elseif (keyword(option, 'x2range', 3_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%x2axis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user)
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
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user)
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
      i = 3_I4P
      do while (i <= size(tokens, kind=I4P))
         if ((text == 'dumb' .or. text == 'block') .and. is_word(tokens(i)%text, 'mono ansi ansi256 ansirgb')) then
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
      i = 2_I4P
      do while (i <= size(tokens, kind=I4P))
         if (keyword(tokens(i)%text, 'layout', 3_I4P)) then
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
      endif
      self%multiplot = .true.
      self%advance_pending = .false.
   else
      call fail('unsupported option "set '//option//'"', iostat, iomsg)
   endif
   contains
      subroutine set_range(min_fixed, min_user, max_fixed, max_user)
      !< Parse `[min:max]`: `*` or an empty end autoscales it.
      logical,   intent(inout) :: min_fixed !< Start fixed.
      real(R8P), intent(inout) :: min_user  !< Start value.
      logical,   intent(inout) :: max_fixed !< End fixed.
      real(R8P), intent(inout) :: max_user  !< End value.
      integer(I4P)             :: colon     !< Separator position.

      if (size(tokens) /= 2) then
         call fail('set '//option//': [min:max] expected', iostat, iomsg)
         return
      endif
      colon = index(tokens(2)%text, ':', kind=I4P)
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
      if (.not. to_number(trim(adjustl(text)), v)) then
         call self%symbols%constant(trim(adjustl(text)), v, iostat, iomsg, &
                                    degrees=self%figure%panels(self%figure%current)%degrees)
         if (iostat /= 0_I4P) then
            iomsg = 'set '//option//': '//iomsg
            return
         endif
      endif
      fixed = .true.
      value = v
      endsubroutine range_end
      subroutine print_option
      !< `set print ["file" [append] | "-"]`: where `print` writes; a file is emptied unless `append`; bare, the
      !< standard error.
      character(len=:), allocatable :: name   !< File name.
      integer(I4P)                  :: unit   !< File unit.
      integer(I4P)                  :: k      !< Last token of the name.
      logical                       :: append !< `append` given.

      if (size(tokens) == 1) then
         self%print_file = ''
         return
      endif
      k = 2_I4P
      if (tokens(2)%kind == TOKEN_STRING .or. tokens(2)%kind == TOKEN_WORD) then
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

      subroutine key_option
      !< `set key [on|off] [left|right|center] [top|bottom|center] [box|nobox] [inside|outside|below|above|lmargin|
      !< rmargin|tmargin|bmargin|at POSITION] [horizontal|vertical] [autotitle [columnhead]|noautotitle]`; POSITION is
      !< `[SYSTEM] X, [SYSTEM] Y`, SYSTEM `first` (default), `second`, `graph` or `screen`, y taking the one of x.
      character(len=:), allocatable :: words  !< Position words.
      logical                       :: on     !< Key on.
      logical, allocatable          :: box    !< Box, unallocated if not given.
      real(R8P), allocatable        :: at(:)  !< Key position, unallocated if not given.
      character(len=6)              :: sys(2) !< Coordinate systems of the position.

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
         case ('autotitle')
            self%autotitle = 'file'
            if (i < size(tokens, kind=I4P)) then
               if (keyword(tokens(i + 1_I4P)%text, 'columnheader', 7_I4P)) self%autotitle = 'columnhead'
            endif
         case ('noautotitle')
            self%autotitle = 'none'
         case ('columnhead', 'columnheader')
            if (i == 2_I4P) then
               call fail('set key: columnhead goes after autotitle', iostat, iomsg)
               return
            endif
            if (tokens(i - 1_I4P)%text /= 'autotitle') then
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
         case default
            call fail('set key: unsupported option "'//tokens(i)%text//'" (supported: on, off, left, right, center, '// &
                      'top, bottom, box, nobox, inside, outside, below, above, lmargin, rmargin, tmargin, bmargin, '// &
                      'at, horizontal, vertical, autotitle [columnhead], noautotitle)', iostat, iomsg)
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
      !< `set grid [polar [STEP]]`: the rectangular grid, or the polar one with spokes every STEP (30 by default) in
      !< the angle unit.
      real(R8P) :: step !< Spoke step.

      if (size(tokens) == 1) then
         call self%figure%set_grid(.true., polar=0.0_R8P)
         return
      endif
      if (keyword(tokens(2)%text, 'spiderplot', 6_I4P) .and. size(tokens) == 2) then
         call self%figure%set_grid(spider=.true.)
         return
      endif
      if (.not. keyword(tokens(2)%text, 'polar', 2_I4P) .or. tokens(2)%kind /= TOKEN_WORD .or. size(tokens) > 3) then
         call fail('set grid: only "polar [STEP]" and "spiderplot" are supported', iostat, iomsg)
         return
      endif
      step = 30.0_R8P
      if (size(tokens) == 3) then
         if (.not. to_number(tokens(3)%text, step)) then
            call fail('set grid polar: "'//tokens(3)%text//'" is not a number', iostat, iomsg)
            return
         endif
         ! in the angle unit
         if (.not. self%figure%panels(self%figure%current)%degrees) step = step * (180.0_R8P / acos(-1.0_R8P))
      endif
      if (.not. (step > 0.0_R8P .and. step < 360.0_R8P)) then
         call fail('set grid polar: the step must be positive and below a full turn', iostat, iomsg)
         return
      endif
      call self%figure%set_grid(.true., polar=step)
      endsubroutine grid_option

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
      do i = 2_I4P, size(tokens, kind=I4P)
         if (tokens(i)%kind == TOKEN_WORD .and. keyword(tokens(i)%text, 'polar', 2_I4P)) then
            polar = .true.
         elseif (to_number(tokens(i)%text, v)) then
            if (v < 0.0_R8P .or. v > 4095.0_R8P .or. v /= aint(v)) then
               call fail('set border: the mask is an integer 0 to 4095', iostat, iomsg)
               return
            endif
            mask = int(v, I4P)
         else
            call fail('set border: only a MASK and "polar" are supported', iostat, iomsg)
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
      integer(I4P)                     :: n       !< Position tokens.

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
         elseif (toks(i)%kind == TOKEN_WORD .and. keyword(toks(i)%text, 'mirror', 3_I4P)) then
            mirror = .true.
         elseif (toks(i)%kind == TOKEN_WORD .and. keyword(toks(i)%text, 'nomirror', 4_I4P)) then
            mirror = .false.
         elseif (toks(i)%kind == TOKEN_WORD .and. toks(i)%text == 'add') then
            add = .true.
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
      if (ok) ok = all(args(1:n:2)%kind == TOKEN_WORD)
      if (ok .and. n > 1_I4P) ok = all(args(2:n:2)%kind == TOKEN_COMMA)
      if (.not. ok) then
         call fail('set '//option//': supported forms are STEP, START,STEP, START,STEP,END and auto, with mirror or '// &
                   'nomirror', iostat, iomsg)
         return
      endif
      message = ''
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
      !< `set mxtics|mytics|my2tics|mcbtics [N|default]`: N intervals between consecutive major ticks, gnuplot's
      !< automatic count without N; `default` restores the minor ticks by default (none, 2..9 on log axes).
      type(tics_object), intent(inout) :: tics !< Axis tick settings.
      integer(I4P)                     :: n    !< Intervals.
      integer(I4P)                     :: ios  !< Read status.

      if (size(tokens) == 1) then
         tics%minor = MINOR_AUTO
         return
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
      !< `set format [x|y|y2|cb|x2|xy...] ["format"]` (all axes by default): no format restores the default labels.
      character(len=:), allocatable :: axes    !< Axes letters.
      character(len=:), allocatable :: format  !< Label format.
      character(len=:), allocatable :: message !< Problem.

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
         if (i < size(tokens, kind=I4P)) then
            call fail('set format: unexpected "'//tokens(i + 1_I4P)%text//'" after the format', iostat, iomsg)
            return
         endif
         if (len(format) > 0) then
            message = format_check(format)
            if (len(message) > 0) then
               call fail('set format: '//message, iostat, iomsg)
               return
            endif
         endif
      endif
      call self%figure%set_format(format, axes)
      endsubroutine format_option

      subroutine style_option
      !< `set style data|function STYLE`, `set style line N [lc ...] [lt N] [lw W] [dt N] [ps S]`.
      type(line_style_object) :: style !< New line style.
      character(len=:), allocatable :: with !< Style name.
      integer(I4P) :: s !< Counter.

      if (size(tokens) >= 2) then
         if (keyword(tokens(2)%text, 'data', 1_I4P)) then
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
               logical                :: rows !< Row stacked.
               real(R8P), allocatable :: gap  !< Cluster gap.
               real(R8P)              :: v    !< Number.

               rows = .false.
               s = 3_I4P
               do while (s <= size(tokens, kind=I4P))
                  if (tokens(s)%text == 'clustered') then
                     rows = .false.
                  elseif (keyword(tokens(s)%text, 'rowstacked', 4_I4P)) then
                     rows = .true.
                  elseif (tokens(s)%text == 'gap') then
                     s = s + 1_I4P
                     if (s > size(tokens, kind=I4P)) then
                        call fail('set style histogram: gap needs a number', iostat, iomsg)
                        return
                     endif
                     if (.not. to_number(tokens(s)%text, v)) then
                        call fail('set style histogram: gap needs a number', iostat, iomsg)
                        return
                     endif
                     if (v < 0.0_R8P) then
                        call fail('set style histogram: the gap must not be negative', iostat, iomsg)
                        return
                     endif
                     gap = v
                  else
                     call fail('set style histogram: unsupported option "'//tokens(s)%text//'" (clustered [gap G] '// &
                               'and rowstacked are supported)', iostat, iomsg)
                     return
                  endif
                  s = s + 1_I4P
               enddo
               call self%figure%set_style_histogram(merge('rowstacked', 'clustered ', rows), gap)
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
   elseif (keyword(option, 'style', 2_I4P)) then
      ok = .false.
      if (size(tokens) == 2) ok = keyword(tokens(2)%text, 'function', 1_I4P)
      if (.not. ok) then
         call fail('unset style: only "function" is supported', iostat, iomsg)
         return
      endif
      self%function_style = 'lines'
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
   if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
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
   elseif (keyword(option, 'xrange', 2_I4P)) then
      call self%figure%set_xrange()
   elseif (keyword(option, 'yrange', 2_I4P)) then
      call self%figure%set_yrange()
   elseif (keyword(option, 'y2range', 3_I4P)) then
      call self%figure%set_y2range()
   elseif (keyword(option, 'x2range', 3_I4P)) then
      call self%figure%set_x2range()
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
   else
      call fail('unsupported option "unset '//option//'"', iostat, iomsg)
   endif
   endsubroutine unset_command

   ! helpers
   pure function is_datablock(word) result(yes)
   !< Whether `word` names a datablock: `$`, then a letter or `_`, then letters, digits, `_` (gnuplot `$DATA`).
   character(len=*), intent(in) :: word !< Word.
   logical                      :: yes  !< A datablock name.
   character(len=*), parameter  :: LETTERS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_'

   yes = len(word) >= 2
   if (yes) yes = word(1:1) == '$' .and. scan(word(2:2), LETTERS) > 0
   if (yes) yes = verify(word(2:), LETTERS//'0123456789') == 0
   endfunction is_datablock

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

   pure function canonical_style(word) result(style)
   !< Full gnuplot style name of `word` (full or abbreviated), empty if unsupported.
   character(len=*), intent(in)  :: word  !< Style word.
   character(len=:), allocatable :: style !< Full style name.

   style = style_name(word)
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
   if (size(fields) > 6) call fail('using: "'//spec//'" has more than 6 fields', iostat, iomsg)
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
      ok = keyword(word, 'columnheader', 7_I4P)
      return
   endif
   ok = keyword(word(1:open - 1_I4P), 'columnheader', 7_I4P) .and. word(len(word):len(word)) == ')' .and. &
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

   yes = is_word(with, 'lines points linespoints impulses steps fsteps histeps dots')
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
        .or. word == 'bins' .or. index(word, 'bins=') == 1
   endfunction is_item_option

   pure function is_line_option(word) result(is)
   !< Whether `word` names a line property: `lc`, `lt`, `lw`, `dt`, `ps`, `pt` or their long forms.
   character(len=*), intent(in) :: word !< Option word.
   logical                      :: is   !< Line property.

   is = word == 'lc' .or. keyword(word, 'linecolor', 5_I4P) .or. word == 'lt' .or. keyword(word, 'linetype', 5_I4P) &
        .or. word == 'lw' .or. keyword(word, 'linewidth', 5_I4P) .or. word == 'dt' .or. keyword(word, 'dashtype', 5_I4P) &
        .or. word == 'ps' .or. keyword(word, 'pointsize', 6_I4P) .or. word == 'pt' .or. keyword(word, 'pointtype', 6_I4P)
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
      character(len=*), parameter    :: OPERATORS = '.+-*/%?:<>=!&|' !< Operator characters.

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
