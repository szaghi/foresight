!< foresight_script, interpreter of a gnuplot command subset.
module foresight_script
!< foresight_script, interpreter of a gnuplot command subset.
!<
!< Supported (with gnuplot abbreviations):
!<
!< - `set|unset title|xlabel|ylabel|y2label ["text"]`, `set xrange|yrange|y2range [min:max]` (`*` or empty autoscales
!<   an end), `set|unset logscale [AXES]` (AXES concatenates x, y, y2, e.g. `xy2`; all when absent),
!<   `set|unset grid`, `set|unset key`, `set output "file"`, `set terminal svg|html [size W,H] [refresh SECONDS]`;
!< - `set terminal dumb [size COLS,ROWS] [mono|ansi|ansi256|ansirgb]` (text, default 79x24 on standard output `-`),
!<   `set terminal block [half|quadrants|sextants|braille] [size COLS,ROWS] [mono|ansi|ansi256|ansirgb]` (text drawn
!<   with Unicode block or Braille characters);
!< - `set|unset multiplot [layout ROWS,COLS] [title "t"]`: each `plot` fills the next panel, settings carry over;
!<   without layout each panel lies in its `set origin X,Y` / `set size W,H` box (page fractions);
!< - `set xtics|ytics|y2tics [auto|STEP|START,STEP[,END]] [mirror|nomirror]` (y2 ticks are off until set),
!<   `unset xtics|ytics|y2tics`, `set format [AXES] ["fmt"]`, `unset format`,
!<   `set key [on|off] [left|right|center] [top|bottom|center] [box|nobox] [autotitle [columnhead]|noautotitle]`,
!<   `set style data|function STYLE`, `unset style function`, `set style line N [lc ...] [lt N] [lw W] [dt N] [pt N]
!<   [ps S]`;
!< - `set datafile separator [whitespace|tab|comma|"chars"]`, `unset datafile [separator]`; `set samples N[,M]`;
!< - `plot 'file' [using [X:]Y[:...]] [index N] [every I:J:K:L:M:N] [with STYLE] [title "t"|notitle] [axes x1y1|x1y2]
!<   [smooth unique|frequency|fnormal|cumulative|cnormal] [lc [rgb] "color"|N] [lw W] [dt N] [pt N] [ps S], ...` (`''`
!<   repeats the previous file; smooth: see foresight_smooth), STYLE `lines|points|linespoints|impulses|steps|fsteps|
!<   histeps|dots|yerrorbars|xerrorbars|xyerrorbars|yerrorlines|xerrorlines|xyerrorlines` (error bars: `x:y:dy` or
!<   `x:y:low:high`, `x:y:dx:dy` or `x:y:xlow:xhigh:ylow:yhigh`), abbreviated as gnuplot (foresight_style);
!<   `replot [items]`; a `using` field is a column number or a parenthesized expression,
!<   `($2*1e3)` (see foresight_expression), or a column header name, `"residual"`; `title columnhead[(N)]` titles an
!<   item with a column header; `ls N`, `lt N` in an item apply a line style, a palette color;
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
!<   the labels replacing the x ticks;
!< - `plot 'file' [matrix] with image` (`using x:y:z` on a regular grid, or the values of a `matrix` file), `set palette
!<   [rgbformulae R,G,B|defined (v c, ...)|gray|color|viridis|positive|negative|maxcolors N]`, `set cbrange [min:max]`,
!<   `set|unset cblabel ["t"]`, `set|unset colorbox`;
!< - `with circles` (`using x:y[:r[:start:end]]`, wedges with angles in degrees); foresight's `with pie [donut F]`
!<   (`using Y[:xtic(N)]`, alone in its panel);
!< - foresight's panel charts: `with gauge range [A:B] [segments N] [format "fmt"]`, `with radar`, `with rose [linear]`
!<   (`using Y[:xtic(N)]`), alone in their panel (several gauges or radars side by side);
!< - `set|unset polar` (items theta:r, functions of `t` over `set trange [min:max]`), `set angles degrees|radians`
!<   (also the trigonometric functions of the expressions), `set|unset theta [right|top|left|bottom] [clockwise|cw|
!<   counterclockwise|ccw]`, `set rrange [min:max]`, `set|unset rtics [...]` (as xtics), `set|unset ttics [[START,]STEP]
!<   [format "fmt"]`, `set|unset raxis`, `set grid [polar [STEP]]`, `set border [MASK] [polar]`, `unset border`,
!<   `set size [square|nosquare|ratio R|noratio] [W,H]`;
!< - foresight extensions: `set terminal ... theme classic|vfd|lcd [glow|noglow]` (any terminal), the colors of a
!<   1980s display (see foresight_theme); `fs ... segments N`, bars cut into N cells over the y range (foresight_style); `plot ... with readout [format "fmt"]`, the last finite value of the item in seven-segment
!<   digits on a glass of `fmt` (a printf conversion with a field width, `%10.3e` by default; see foresight_readout),
!<   `lc` its only style option; `set readout [on|off] [left|right|center] [top|bottom|center] [horizontal|vertical]
!<   [opaque|noopaque] [size H]`, `unset readout`;
!< - a function of `x` as a plot item, `plot sin(x)/x title "sinc"` (same options, styles lines, points or linespoints,
!<   `set style function`, `lines` by default): sampled at `set samples` points (100) over the x range before its
!<   extension to the ticks, the data extent, or [-10:10] with neither; evenly in log x on a log axis.
!<
!< Anything else is an error naming the command, never silently ignored. Errors are returned (`iostat`, `iomsg` with
!< `source:line:`), not stopped on, so a watch loop can survive a bad cycle.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite, ieee_quiet_nan, ieee_value
use foresight_axes, only : axes_names, boxplot_style, boxplot_words, polar_series, spider_words, POLAR_STYLES
use foresight_datafile, only : datafile_object
use foresight_expression, only : expression_object
use foresight_figure, only : figure_object
use foresight_format, only : format_check, int_str, real_from_decimal
use foresight_readout, only : readout_check
use foresight_smooth, only : smooth, SMOOTH_MODES
use foresight_palette, only : palette_object, palette_words
use foresight_style, only : default_color, fill_style, style_name, style_object, style_with, STYLE_NAMES, WITH_GAUGE, &
                            WITH_PARALLELAXES, WITH_PIE, WITH_RADAR, WITH_ROSE, WITH_SPIDERPLOT
use foresight_ticks, only : tics_object
use foresight_tokens, only : split_statements, token_object, tokenize, TOKEN_COMMA, TOKEN_RANGE, TOKEN_STRING, &
                             TOKEN_WORD
use penf, only : I4P, I8P, R8P

implicit none
private
public :: script_object

real(R8P), parameter :: DUMB_CELL(2) = [0.55_R8P, 1.25_R8P] !< Text device cell size [font size].
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
endtype line_style_object

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
   integer(I4P)                    :: samples = 100_I4P        !< Function samples, `set samples`.
   real(R8P)                       :: rgbmax = 255.0_R8P       !< Full intensity of RGB image components, `set rgbmax`.
   contains
      procedure, pass(self) :: execute                !< Execute one statement.
      procedure, pass(self) :: init                   !< Reset the interpreter.
      procedure, pass(self) :: run_file               !< Run a script file.
      procedure, pass(self) :: run_text               !< Run script text.
      procedure, pass(self), private :: plot_command  !< `plot`.
      procedure, pass(self), private :: register_file !< Remember a data file.
      procedure, pass(self), private :: save_output   !< Render to the current output.
      procedure, pass(self), private :: set_command   !< `set`.
      procedure, pass(self), private :: unset_command !< `unset`.
endtype script_object

contains
   subroutine init(self, output)
   !< Reset the interpreter; plots go to `output` until `set output`.
   class(script_object), intent(inout) :: self   !< Interpreter.
   character(len=*),     intent(in)    :: output !< Default output file.

   call self%figure%init
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
   self%samples = 100_I4P
   self%rgbmax = 255.0_R8P
   endsubroutine init

   subroutine run_file(self, file, iostat, iomsg)
   !< Run the script `file`.
   class(script_object),          intent(inout) :: self    !< Interpreter.
   character(len=*),              intent(in)    :: file    !< Script file.
   integer(I4P),                  intent(out)   :: iostat  !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg   !< Error message.
   character(len=:), allocatable                :: text    !< Script text.
   character(len=256)                           :: message !< I/O message.
   integer(I4P)                                 :: unit    !< File unit.
   integer(I4P)                                 :: bytes   !< File size.

   iomsg = ''
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

   subroutine run_text(self, text, iostat, iomsg, source)
   !< Run script `text`: lines ending in `\` continue on the next one; the first error stops the run.
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

   iostat = 0_I4P
   iomsg = ''
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
      call process(line)
      if (iostat /= 0_I4P) return
      line = ''
   enddo
   ! a continuation on the last line
   if (len(line) > 0) call process(line)
   contains
      subroutine process(logical_line)
      !< Execute the statements of a logical line.
      character(len=*), intent(in)    :: logical_line  !< Logical line.
      type(token_object), allocatable :: statements(:) !< Statements.
      integer(I4P)                    :: s             !< Statement counter.

      call split_statements(logical_line, statements)
      do s = 1_I4P, size(statements, kind=I4P)
         call self%execute(statements(s)%text, iostat, iomsg)
         if (iostat /= 0_I4P) then
            iomsg = name//':'//int_str(int(first_line, I8P))//': '//iomsg
            return
         endif
      enddo
      endsubroutine process
   endsubroutine run_text

   subroutine execute(self, statement, iostat, iomsg)
   !< Execute one statement.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   character(len=*),              intent(in)    :: statement !< Statement.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   type(token_object), allocatable              :: tokens(:) !< Statement tokens.
   character(len=:), allocatable                :: command   !< Command word.

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

   ! private procedures
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
   character(len=:), allocatable                :: axes      !< Item axes, `x1y1` or `x1y2`.
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
   integer(I4P)                                 :: label_col !< Column of `xtic(N)`, 0 for none.
   character(len=:), allocatable                :: xlabels(:) !< Text labels of the points.
   logical                                      :: one_field !< `using` gives one field (before the point number).
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
   logical                                      :: polar_ok !< The item can be drawn on a polar panel.
   logical                                      :: headed    !< The first row of each dataset is a header.
   integer(I4P)                                 :: title_column !< Header column titling the item: 0 the y one,
                                                                !< negative for none (gnuplot `title columnhead(N)`).
   character(len=:), allocatable                :: missing   !< Header name found nowhere.

   iostat = 0_I4P
   iomsg = ''
   loaded = ''
   allocate(functions(0), slots(0))
   call self%figure%clear
   if (size(tokens) == 0) then
      call fail('plot: nothing to plot', iostat, iomsg)
      return
   endif
   i = 1_I4P
   do
      ! data file or function
      if (i > size(tokens, kind=I4P)) then
         call fail('plot: missing item after ","', iostat, iomsg)
         return
      endif
      is_function = tokens(i)%kind == TOKEN_WORD
      if (tokens(i)%kind == TOKEN_RANGE) then
         call fail('plot: inline ranges are not supported, found "['//tokens(i)%text//']" (use set xrange)', &
                   iostat, iomsg)
         return
      elseif (tokens(i)%kind == TOKEN_COMMA) then
         call fail('plot: missing item before ","', iostat, iomsg)
         return
      elseif (is_function) then
         ! the expression runs up to the first item option: blanks may separate its words, `x * 2`
         head = i
         do while (i < size(tokens, kind=I4P))
            if (tokens(i + 1_I4P)%kind /= TOKEN_WORD) exit
            if (is_item_option(tokens(i + 1_I4P)%text)) exit
            i = i + 1_I4P
         enddo
         written = text(tokens(head)%first:tokens(i)%last)
         ! gnuplot's dummy variable is t in polar mode
         associate(panel => self%figure%panels(self%figure%current))
            call func%compile(written, iostat, iomsg, variable=merge('t', 'x', panel%polar), degrees=panel%degrees)
         endassociate
         if (iostat /= 0_I4P) then
            iomsg = 'plot: '//iomsg
            return
         endif
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
            call split_xtic(spec, label_col, iostat, iomsg, keyed)
            if (iostat /= 0_I4P) return
            call parse_using(spec, fields, iostat, iomsg, self%figure%panels(self%figure%current)%degrees)
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
         elseif (keyword(word, 'smooth', 1_I4P)) then
            if (.not. next_word(tokens, i, filter, iostat, iomsg)) return
            if (.not. is_word(filter, SMOOTH_MODES)) then
               call fail('plot: unsupported smooth "'//filter//'" (supported: '//SMOOTH_MODES//')', iostat, iomsg)
               return
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
            if (axes /= 'x1y1' .and. axes /= 'x1y2') then
               call fail('plot: axes x1y1 or x1y2 expected, found "'//axes//'" (no second x axis)', iostat, iomsg)
               return
            endif
         elseif (keyword(word, 'title', 1_I4P)) then
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) then
               call fail('plot: title needs a quoted string or columnhead', iostat, iomsg)
               return
            endif
            if (tokens(i)%kind == TOKEN_WORD) then
               if (.not. columnhead_title(tokens(i)%text, title_column)) then
                  call fail('plot: title needs a quoted string or columnhead, found "'//tokens(i)%text//'"', &
                            iostat, iomsg)
                  return
               endif
               if (is_function) then
                  call fail('plot: a function has no column header', iostat, iomsg)
                  return
               endif
            elseif (tokens(i)%kind /= TOKEN_STRING) then
               call fail('plot: title needs a quoted string or columnhead', iostat, iomsg)
               return
            else
               title = tokens(i)%text
            endif
            has_title = .true.
         elseif (keyword(word, 'notitle', 3_I4P)) then
            title = ''
            has_title = .true.
         elseif (word == 'ls' .or. keyword(word, 'linestyle', 5_I4P)) then
            if (.not. next_integer(tokens, i, number, iostat, iomsg)) return
            call apply_line_style(self%line_styles, number, line)
         elseif (is_line_option(word)) then
            if (.not. (word == 'lc' .or. keyword(word, 'linecolor', 5_I4P) .or. word == 'lt' .or. &
                       keyword(word, 'linetype', 5_I4P))) shaping = word
            if (.not. line_option(tokens, i, line, iostat, iomsg)) then
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
            if (allocated(axes)) polar_ok = polar_ok .and. axes /= 'x1y2'
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
         call self%figure%plot([real(R8P) ::], [real(R8P) ::], title=title, with=with, lc=line%lc, lw=line%lw, &
                               dt=line%dt, ps=line%ps, axes=axes, pt=line%pt)
         functions = [functions, func]
         ! associate alias: see the gfortran 16 -fcheck=bounds workaround in foresight_figure
         associate(panel => self%figure%panels(self%figure%current))
            slots = [slots, size(panel%series, kind=I4P)]
         endassociate
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
         elseif (size(fields) == 3) then
            word = trim(adjustl(spec(index(spec, ':', back=.true.) + 1:)))
            if (len(word) == 0 .or. verify(word, '0123456789') /= 0 .or. len(word) > 9) then
               call fail('plot: the labels text (3rd using field) must be a column number', iostat, iomsg)
               return
            endif
            read(word, *) label_col
            fields = fields(1:2)
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
            fields = fields(1:3)
         endif
      endif
      ! reloaded to keep the text of the xtic column
      if (file /= loaded .or. (label_col > 0_I4P .and. data%label_column /= label_col)) then
         call data%load(file, iostat, iomsg, separator=self%separator, label_column=label_col)
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
         endselect
         one_field = is_word(with, 'histograms pie radar rose gauge parallelaxes spiderplot')
      elseif (size(fields) == 1) then
         one_field = .true.
         call point%set_column(0_I4P)
         fields = [point, fields(1)]
      endif
      nbar = size(fields, kind=I4P) - 2_I4P
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
         if (nbar /= 0_I4P) then
            call fail('plot: '//with//' needs using X:Y or Y', iostat, iomsg)
            return
         endif
      endselect
      if (len(filter) > 0 .and. nbar /= 0_I4P) then
         call fail('plot: smooth applies to lines, points and linespoints, not to '//with, iostat, iomsg)
         return
      endif
      if (.not. has_title) then
         select case (self%autotitle)
         case ('columnhead')
            title_column = 0_I4P
         case ('file')
            ! gnuplot: the item as written, '' included
            title = quote//written//quote
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
         call data%table(fields, set_index, every, values, header=headed, labels=xlabels)
      else
         call data%table(fields, set_index, every, values, header=headed)
         if (allocated(xlabels)) deallocate(xlabels)
      endif
      x = values(:, 1)
      y = values(:, 2)
      if (len(filter) > 0) then
         ! associate alias: see the gfortran 16 -fcheck=bounds workaround in foresight_figure
         associate(panel => self%figure%panels(self%figure%current))
            if (axes == 'x1y2') then
               call smooth(filter, values(:, 1), values(:, 2), panel%xaxis%log, panel%y2axis%log, x, y)
            else
               call smooth(filter, values(:, 1), values(:, 2), panel%xaxis%log, panel%yaxis%log, x, y)
            endif
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
      else
         call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, ps=line%ps, &
                               xlow=xlow, xhigh=xhigh, ylow=ylow, yhigh=yhigh, axes=axes, pt=line%pt, xlabels=xlabels)
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

      subroutine image_item
      !< An image item: the values of a `matrix` file, or `using x:y:z` (default 1:2:3) gathered on a regular grid.
      real(R8P), allocatable        :: z(:,:)  !< Grid values.
      real(R8P), allocatable        :: xs(:)   !< Pixel centre abscissae.
      real(R8P), allocatable        :: ys(:)   !< Pixel centre ordinates.
      character(len=:), allocatable :: problem !< Grid problem.

      if (.not. has_title .and. self%autotitle == 'file') then
         title = quote//written//quote
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
      call data%table(fields, set_index, every, values)
      call regular_grid(values(:, 1), values(:, 2), values(:, 3), xs, ys, z, problem)
      if (len(problem) > 0) then
         call fail('plot: image of "'//file//'": '//problem, iostat, iomsg)
         return
      endif
      call self%figure%image(z, xs, ys, title=title)
      endsubroutine image_item

      subroutine rgb_item
      !< An `rgbimage` (`using x:y:r:g:b`) or `rgbalpha` (`x:y:r:g:b:a`) item on a regular grid, the components scaled
      !< from [0:rgbmax] to [0:255].
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
      call data%table(fields, set_index, every, values)
      do k = 1_I4P, m
         call regular_grid(values(:, 1), values(:, 2), values(:, 2_I4P + k) * (255.0_R8P / self%rgbmax), xs, ys, z, &
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

      subroutine split_xtic(spec, column, iostat, iomsg, keyed)
      !< Remove a last `using` field `xtic(N)` or `xticlabels(N)` from `spec`, returning N (0 if none); `key(N)` (the
      !< row names of a spider plot) likewise, with `keyed` true.
      character(len=:), allocatable, intent(inout) :: spec   !< `using` specification.
      integer(I4P),                  intent(out)   :: column !< Label column, 0 for none.
      integer(I4P),                  intent(inout) :: iostat !< Status.
      character(len=:), allocatable, intent(inout) :: iomsg  !< Error message.
      logical,                       intent(out)   :: keyed  !< The field is `key(N)`.
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
      if (last(len(last):len(last)) /= ')' .or. .not. to_number(inner, v)) then
         call fail('plot: xtic needs a column number, xtic(1), found "'//last//'"', iostat, iomsg)
         return
      endif
      if (v < 1.0_R8P .or. v /= aint(v)) then
         call fail('plot: xtic needs a column number, xtic(1), found "'//last//'"', iostat, iomsg)
         return
      endif
      column = int(v, I4P)
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
      !< user ends, the data extent, else the axis default range): evenly, in log x on a log axis.
      real(R8P), allocatable :: xs(:)     !< Sample abscissae.
      real(R8P), allocatable :: ys(:)     !< Sample values.
      real(R8P)              :: xmin      !< Smallest data abscissa.
      real(R8P)              :: xmax      !< Largest data abscissa.
      real(R8P)              :: ymin(2)   !< Smallest data ordinates, unused.
      real(R8P)              :: ymax(2)   !< Largest data ordinates, unused.
      real(R8P)              :: lo        !< Range start.
      real(R8P)              :: hi        !< Range end.
      real(R8P)              :: a         !< Range start, log10 on a log axis.
      real(R8P)              :: step      !< Sample spacing, in log10 on a log axis.
      logical                :: found(2)  !< Any data per y axis.
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
         call panel%data_extent(xmin, xmax, ymin, ymax, found)
         call panel%xaxis%range_of(xmin, xmax, any(found), lo, hi)
         ! a log axis on a non-positive range is reported by the rendering
         if (panel%xaxis%log .and. (lo <= 0.0_R8P .or. hi <= 0.0_R8P)) return
         a = lo
         if (panel%xaxis%log) a = log10(lo)
         ! never hi - lo, which overflows on extreme ends
         if (panel%xaxis%log) then
            step = log10(hi) / real(n - 1_I4P, R8P) - a / real(n - 1_I4P, R8P)
         else
            step = hi / real(n - 1_I4P, R8P) - lo / real(n - 1_I4P, R8P)
         endif
         allocate(xs(n), ys(n))
         do j = 1_I4P, n
            xs(j) = a + real(j - 1_I4P, R8P) * step
            if (panel%xaxis%log) xs(j) = 10.0_R8P**xs(j)
         enddo
         ! exact ends: a sample past an autoscaled end would widen the axis by a rounding error
         xs(1) = lo
         xs(n) = hi
         do f = 1_I4P, size(functions, kind=I4P)
            do j = 1_I4P, n
               ys(j) = functions(f)%value_at(xs(j))
            enddo
            panel%series(slots(f))%x = xs
            panel%series(slots(f))%y = ys
         enddo
      endassociate
      endsubroutine sample_functions
   endsubroutine plot_command

   subroutine register_file(self, file)
   !< Remember `file` among the data files read (once).
   class(script_object), intent(inout) :: self  !< Interpreter.
   character(len=*),     intent(in)    :: file  !< Data file.
   type(token_object)                  :: entry !< New entry.
   integer(I4P)                        :: f     !< Counter.

   do f = 1_I4P, size(self%data_files, kind=I4P)
      if (self%data_files(f)%text == file) return
   enddo
   entry%text = file
   self%data_files = [self%data_files, entry]
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
      if (.not. string_argument(tokens, text, iostat, iomsg)) return
      call self%figure%set_title(text)
   elseif (keyword(option, 'xlabel', 2_I4P)) then
      if (.not. string_argument(tokens, text, iostat, iomsg)) return
      call self%figure%set_xlabel(text)
   elseif (keyword(option, 'ylabel', 2_I4P)) then
      if (.not. string_argument(tokens, text, iostat, iomsg)) return
      call self%figure%set_ylabel(text)
   elseif (keyword(option, 'y2label', 3_I4P)) then
      if (.not. string_argument(tokens, text, iostat, iomsg)) return
      call self%figure%set_y2label(text)
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
   elseif (keyword(option, 'cbrange', 3_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%cbaxis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user)
      endassociate
   elseif (keyword(option, 'cblabel', 3_I4P)) then
      if (.not. string_argument(tokens, text, iostat, iomsg)) return
      call self%figure%set_cblabel(text)
   elseif (keyword(option, 'colorbox', 4_I4P)) then
      if (size(tokens) > 1) then
         call fail('set colorbox: no options are supported (the box is at the right of the plot)', iostat, iomsg)
         return
      endif
      call self%figure%set_colorbox(.true.)
   elseif (keyword(option, 'boxwidth', 3_I4P)) then
      call boxwidth_option
   elseif (keyword(option, 'output', 2_I4P)) then
      if (.not. string_argument(tokens, text, iostat, iomsg)) return
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
               call fail('set terminal: theme needs a name (classic, vfd, lcd)', iostat, iomsg)
               return
            endif
            if (.not. is_word(tokens(i)%text, 'classic vfd lcd')) then
               call fail('set terminal: unknown theme "'//tokens(i)%text//'" (supported: classic, vfd, lcd)', iostat, &
                         iomsg)
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
   elseif (keyword(option, 'datafile', 5_I4P)) then
      call datafile_option
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
            if (tokens(i)%kind /= TOKEN_STRING) then
               call fail('set multiplot: title needs a quoted string', iostat, iomsg)
               return
            endif
            text = tokens(i)%text
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
      !< One range end: empty or `*` autoscales, else a number.
      character(len=*), intent(in)    :: text  !< End text.
      logical,          intent(inout) :: fixed !< End fixed.
      real(R8P),        intent(inout) :: value !< End value.
      real(R8P)                       :: v     !< Parsed value.

      if (len_trim(text) == 0 .or. trim(adjustl(text)) == '*') then
         fixed = .false.
         return
      endif
      if (.not. to_number(trim(adjustl(text)), v)) then
         call fail('set '//option//': "'//trim(adjustl(text))//'" is not a number', iostat, iomsg)
         return
      endif
      fixed = .true.
      value = v
      endsubroutine range_end
      subroutine key_option
      !< `set key [on|off] [left|right|center] [top|bottom|center] [box|nobox] [inside|outside|below|above]
      !< [horizontal|vertical] [autotitle [columnhead]|noautotitle]`.
      character(len=:), allocatable :: words !< Position words.
      logical                       :: on    !< Key on.
      logical, allocatable          :: box   !< Box, unallocated if not given.

      on = .true.
      words = ''
      do i = 2_I4P, size(tokens, kind=I4P)
         select case (tokens(i)%text)
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
               'over', 'horizontal', 'horiz', 'vertical', 'vert')
            words = words//' '//tokens(i)%text
         case default
            call fail('set key: unsupported option "'//tokens(i)%text//'" (supported: on, off, left, right, center, '// &
                      'top, bottom, box, nobox, inside, outside, below, above, horizontal, vertical, autotitle '// &
                      '[columnhead], noautotitle)', iostat, iomsg)
            return
         endselect
      enddo
      call self%figure%set_key(on, position=words, box=box)
      endsubroutine key_option

      subroutine palette_option
      !< `set palette [WORDS]`: checked on a copy, then applied (see foresight_palette).
      type(palette_object)          :: probe !< Palette the words are tried on.
      character(len=:), allocatable :: words !< Palette words.
      character(len=:), allocatable :: bad   !< Unknown word.

      words = ''
      do i = 2_I4P, size(tokens, kind=I4P)
         words = words//' '//tokens(i)%text
      enddo
      probe = self%figure%panels(self%figure%current)%palette
      call palette_words(words, probe, bad)
      if (len(bad) > 0) then
         call fail('set palette: unsupported option "'//bad//'"', iostat, iomsg)
         return
      endif
      call self%figure%set_palette(words)
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
            rest = [rest, tokens(i)]
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
      !< `set xtics|ytics|y2tics [auto|autofreq|STEP|START,STEP|START,STEP,END] [mirror|nomirror]`: without positions
      !< the last ones are kept, turning off ticks on (gnuplot); `auto` resets them. `words` (the tics keyword and its
      !< arguments) replaces the option tokens.
      type(tics_object),  intent(inout)        :: tics     !< Axis tick settings.
      type(token_object), intent(in), optional :: words(:) !< Option tokens, if not the command ones.
      type(token_object), allocatable  :: args(:) !< Position tokens, mirror words removed.
      type(token_object), allocatable  :: toks(:) !< Option tokens.
      character(len=:), allocatable    :: message !< Problem.
      logical                          :: ok      !< Well formed.
      logical, allocatable             :: mirror  !< Mirror setting, unallocated if not given.
      integer(I4P)                     :: n       !< Position tokens.

      if (present(words)) then
         toks = words
      else
         toks = tokens
      endif
      allocate(args(0))
      do i = 2_I4P, size(toks, kind=I4P)
         if (toks(i)%kind == TOKEN_WORD .and. keyword(toks(i)%text, 'mirror', 3_I4P)) then
            mirror = .true.
         elseif (toks(i)%kind == TOKEN_WORD .and. keyword(toks(i)%text, 'nomirror', 4_I4P)) then
            mirror = .false.
         else
            args = [args, toks(i)]
         endif
      enddo
      n = size(args, kind=I4P)
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

      subroutine datafile_option
      !< `set datafile separator [whitespace|tab|comma|"chars"]`: no argument restores whitespace.
      if (size(tokens) < 2) then
         call fail('set datafile: only "separator" is supported', iostat, iomsg)
         return
      endif
      if (.not. keyword(tokens(2)%text, 'separator', 3_I4P) .or. tokens(2)%kind /= TOKEN_WORD) then
         call fail('set datafile: unsupported option "'//tokens(2)%text//'" (only separator is)', iostat, iomsg)
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
      !< `set format [x|y|xy] ["format"]`: no format restores the default labels.
      character(len=:), allocatable :: axes    !< Axes letters.
      character(len=:), allocatable :: format  !< Label format.
      character(len=:), allocatable :: message !< Problem.

      axes = 'xyy2'
      format = ''
      i = 2_I4P
      if (i <= size(tokens, kind=I4P)) then
         if (tokens(i)%kind == TOKEN_WORD) then
            axes = tokens(i)%text
            if (.not. valid_axes(axes)) then
               call fail('set format: axes must be among x, y, y2 (e.g. y or xy2), not "'//axes//'"', iostat, iomsg)
               return
            endif
            i = i + 1_I4P
         endif
      endif
      if (i <= size(tokens, kind=I4P)) then
         if (tokens(i)%kind /= TOKEN_STRING .or. i < size(tokens, kind=I4P)) then
            call fail('set format: a single quoted format is expected', iostat, iomsg)
            return
         endif
         format = tokens(i)%text
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
               if (.not. line_option(tokens, i, style, iostat, iomsg)) then
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
            self%line_styles = [self%line_styles, style]
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
      ! all the datafile settings, or the separator only: the same here
      if (size(tokens) > 1) then
         if (.not. keyword(tokens(2)%text, 'separator', 3_I4P)) then
            call fail('unset datafile: unsupported option "'//tokens(2)%text//'" (only separator is)', iostat, iomsg)
            return
         endif
      endif
      if (.not. no_more(tokens, 3_I4P, iostat, iomsg)) return
      self%separator = ''
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
   elseif (keyword(option, 'xtics', 3_I4P)) then
      call self%figure%unset_xtics
   elseif (keyword(option, 'ytics', 3_I4P)) then
      call self%figure%unset_ytics
   elseif (keyword(option, 'y2tics', 4_I4P)) then
      call self%figure%unset_y2tics
   elseif (keyword(option, 'format', 3_I4P)) then
      call self%figure%set_format('')
   else
      call fail('unsupported option "unset '//option//'"', iostat, iomsg)
   endif
   endsubroutine unset_command

   ! helpers
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
   !< Optional axes names after a `logscale` option (default all: `xyy2`); a base other than 10 is an error.
   type(token_object),            intent(in)  :: tokens(:) !< Option tokens.
   character(len=:), allocatable, intent(out) :: axes      !< Axes letters.
   integer(I4P),                  intent(out) :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out) :: iomsg     !< Error message.
   logical                                    :: ok        !< Success.

   iostat = 0_I4P
   iomsg = ''
   axes = 'xyy2'
   ok = .true.
   if (size(tokens) >= 2) then
      axes = tokens(2)%text
      if (.not. valid_axes(axes)) then
         call fail('logscale: axes among x, y, y2 expected (e.g. y or xy2), found "'//axes//'"', iostat, iomsg)
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

   function next_integer(tokens, i, value, iostat, iomsg) result(ok)
   !< Advance `i` to the next token, which must be an integer.
   type(token_object),            intent(in)    :: tokens(:) !< Tokens.
   integer(I4P),                  intent(inout) :: i         !< Token counter.
   integer(I4P),                  intent(out)   :: value     !< Integer.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   logical                                      :: ok        !< Success.
   character(len=:), allocatable                :: word      !< Token text.

   value = 0_I4P
   ok = next_word(tokens, i, word, iostat, iomsg)
   if (.not. ok) return
   ok = verify(word, '0123456789+-') == 0 .and. scan(word, '0123456789') > 0
   if (ok) then
      read(word, *, iostat=iostat) value
      ok = iostat == 0_I4P
   endif
   if (.not. ok) call fail('an integer was expected, found "'//word//'"', iostat, iomsg)
   endfunction next_integer

   function next_real(tokens, i, value, iostat, iomsg) result(ok)
   !< Advance `i` to the next token, which must be a number.
   type(token_object),            intent(in)    :: tokens(:) !< Tokens.
   integer(I4P),                  intent(inout) :: i         !< Token counter.
   real(R8P),                     intent(out)   :: value     !< Number.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   logical                                      :: ok        !< Success.
   character(len=:), allocatable                :: word      !< Token text.

   value = 0.0_R8P
   ok = next_word(tokens, i, word, iostat, iomsg)
   if (.not. ok) return
   ok = to_number(word, value)
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

   subroutine parse_using(spec, fields, iostat, iomsg, degrees)
   !< `using` specification: 1 to 6 colon separated fields, each a column number (0 is the point number) or a
   !< parenthesized expression, as in gnuplot.
   character(len=*),                     intent(in)  :: spec      !< Specification.
   type(expression_object), allocatable, intent(out) :: fields(:) !< Fields.
   character(len=:), allocatable,        intent(out) :: iomsg     !< Error message.
   integer(I4P),                         intent(out) :: iostat    !< 0 on success.
   logical,                              intent(in)  :: degrees   !< Angles of the expressions in degrees.
   type(expression_object)                           :: field     !< Current field.
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
      associate(text => spec(start:finish - 1_I4P))
         if (len(text) > 0 .and. verify(text, '0123456789') == 0 .and. len(text) < 10) then
            read(text, *) c
            call field%set_column(c)
         elseif (is_quoted(text)) then
            ! a column header name, gnuplot `using 1:"residual"`
            call field%set_name(text(2:len(text) - 1))
         elseif (text(1:min(1, len(text))) == '(') then
            ! compiled first, so that an unbalanced expression gets the precise syntax error
            call field%compile(text, iostat, iomsg, degrees=degrees)
            if (iostat /= 0_I4P) then
               iomsg = 'using: '//iomsg
               return
            endif
            if (.not. is_parenthesized(text)) then
               call fail('using: field "'//text//'" must be a single parenthesized expression', iostat, iomsg)
               return
            endif
         else
            call fail('using: field "'//text//'" is neither a column number, a "header" nor a parenthesized '// &
                      'expression (write ($2*1e3), not $2*1e3)', iostat, iomsg)
            return
         endif
      endassociate
      fields = [fields, field]
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
   endsubroutine parse_using

   pure subroutine apply_line_style(styles, id, line)
   !< Apply the line style `id` to `line`: its defined properties; an undefined style is the linetype `id`, as gnuplot.
   type(line_style_object), intent(in)    :: styles(:) !< Defined styles.
   integer(I4P),            intent(in)    :: id        !< Style number.
   type(line_style_object), intent(inout) :: line      !< Line properties.
   integer(I4P)                           :: s         !< Counter.

   do s = 1_I4P, size(styles, kind=I4P)
      if (styles(s)%id /= id) cycle
      if (allocated(styles(s)%lc)) line%lc = styles(s)%lc
      if (allocated(styles(s)%lw)) line%lw = styles(s)%lw
      if (allocated(styles(s)%dt)) line%dt = styles(s)%dt
      if (allocated(styles(s)%ps)) line%ps = styles(s)%ps
      if (allocated(styles(s)%pt)) line%pt = styles(s)%pt
      return
   enddo
   line%lc = default_color(id)
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
        keyword(word, 'fillstyle', 5_I4P) .or. keyword(word, 'matrix', 3_I4P) .or. keyword(word, 'whiskerbars', 7_I4P)
   endfunction is_item_option

   pure function is_line_option(word) result(is)
   !< Whether `word` names a line property: `lc`, `lt`, `lw`, `dt`, `ps`, `pt` or their long forms.
   character(len=*), intent(in) :: word !< Option word.
   logical                      :: is   !< Line property.

   is = word == 'lc' .or. keyword(word, 'linecolor', 5_I4P) .or. word == 'lt' .or. keyword(word, 'linetype', 5_I4P) &
        .or. word == 'lw' .or. keyword(word, 'linewidth', 5_I4P) .or. word == 'dt' .or. keyword(word, 'dashtype', 5_I4P) &
        .or. word == 'ps' .or. keyword(word, 'pointsize', 6_I4P) .or. word == 'pt' .or. keyword(word, 'pointtype', 6_I4P)
   endfunction is_line_option

   function line_option(tokens, i, line, iostat, iomsg) result(ok)
   !< Parse the line property at `tokens(i)` and its value into `line`, leaving `i` on the value's last token:
   !< `lc [rgb] "color"`, `lc N`, `lt N` (palette color N), `lw W`, `dt N`, `ps S`, `pt N`.
   type(token_object),            intent(in)    :: tokens(:) !< Tokens.
   integer(I4P),                  intent(inout) :: i         !< Token counter.
   type(line_style_object),       intent(inout) :: line      !< Line properties.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   logical                                      :: ok        !< Success.
   character(len=:), allocatable                :: word      !< Property word.
   integer(I4P)                                 :: number    !< Integer value.
   real(R8P)                                    :: value     !< Real value.

   word = tokens(i)%text
   iostat = 0_I4P
   iomsg = ''
   ok = .true.
   if (word == 'lc' .or. keyword(word, 'linecolor', 5_I4P)) then
      i = i + 1_I4P
      if (i <= size(tokens, kind=I4P)) then
         if (tokens(i)%kind == TOKEN_WORD .and. keyword(tokens(i)%text, 'rgbcolor', 3_I4P)) i = i + 1_I4P
      endif
      if (i > size(tokens, kind=I4P)) then
         call fail('lc needs a color', iostat, iomsg)
         ok = .false.
      elseif (tokens(i)%kind == TOKEN_STRING) then
         line%lc = tokens(i)%text
      else
         i = i - 1_I4P
         ok = next_integer(tokens, i, number, iostat, iomsg)
         if (ok) line%lc = default_color(number)
      endif
   elseif (word == 'lt' .or. keyword(word, 'linetype', 5_I4P)) then
      ok = next_integer(tokens, i, number, iostat, iomsg)
      if (ok) line%lc = default_color(number)
   elseif (word == 'lw' .or. keyword(word, 'linewidth', 5_I4P)) then
      ok = next_real(tokens, i, value, iostat, iomsg)
      if (ok) line%lw = value
   elseif (word == 'dt' .or. keyword(word, 'dashtype', 5_I4P)) then
      ok = next_integer(tokens, i, number, iostat, iomsg)
      if (ok) line%dt = number
   elseif (word == 'pt' .or. keyword(word, 'pointtype', 6_I4P)) then
      ok = next_integer(tokens, i, number, iostat, iomsg)
      if (ok .and. number < 0_I4P) then
         call fail('pt needs a point type >= 0, not '//int_str(int(number, I8P)), iostat, iomsg)
         ok = .false.
      endif
      if (ok) line%pt = number
   else
      ok = next_real(tokens, i, value, iostat, iomsg)
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

   function string_argument(tokens, text, iostat, iomsg) result(ok)
   !< Optional single quoted string after an option; absent means empty.
   type(token_object),            intent(in)  :: tokens(:) !< Option tokens.
   character(len=:), allocatable, intent(out) :: text      !< String.
   integer(I4P),                  intent(out) :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out) :: iomsg     !< Error message.
   logical                                    :: ok        !< Success.

   iostat = 0_I4P
   iomsg = ''
   text = ''
   ok = .true.
   if (size(tokens) < 2) return
   if (tokens(2)%kind /= TOKEN_STRING .or. size(tokens) > 2) then
      call fail('set '//tokens(1)%text//': a single quoted string is expected', iostat, iomsg)
      ok = .false.
      return
   endif
   text = tokens(2)%text
   endfunction string_argument

   pure function valid_axes(names) result(ok)
   !< Whether `names` concatenates supported axis names: x, y, y2.
   character(len=*), intent(in)  :: names !< Axis names.
   logical                       :: ok    !< Supported.
   character(len=:), allocatable :: bad   !< Unsupported rest.
   logical                       :: named(3) !< x, y, y2 named.

   named = .false.
   call axes_names(names, named(1), named(2), named(3), bad)
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
endmodule foresight_script
