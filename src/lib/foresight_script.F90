!< foresight_script, interpreter of a gnuplot command subset.
module foresight_script
!< foresight_script, interpreter of a gnuplot command subset.
!<
!< Supported (with gnuplot abbreviations):
!<
!< - `set|unset title|xlabel|ylabel|y2label ["text"]`, `set xrange|yrange|y2range [min:max]` (`*` or empty autoscales
!<   an end), `set|unset logscale [AXES]` (AXES concatenates x, y, y2, e.g. `xy2`; all when absent),
!<   `set|unset grid`, `set|unset key`, `set output "file"`, `set terminal svg|html [size W,H] [refresh SECONDS]`;
!< - `set terminal dumb [size COLS,ROWS]` (text, default 79x24 on standard output `-`);
!< - `set|unset multiplot [layout ROWS,COLS] [title "t"]`: each `plot` fills the next panel, settings carry over;
!<   without layout each panel lies in its `set origin X,Y` / `set size W,H` box (page fractions);
!< - `set xtics|ytics|y2tics [auto|STEP|START,STEP[,END]] [mirror|nomirror]` (y2 ticks are off until set),
!<   `unset xtics|ytics|y2tics`, `set format [AXES] ["fmt"]`, `unset format`,
!<   `set key [on|off] [left|right|center] [top|bottom|center] [box|nobox]`,
!<   `set style data|function STYLE`, `unset style function`, `set style line N [lc ...] [lt N] [lw W] [dt N] [ps S]`;
!< - `set datafile separator [whitespace|tab|comma|"chars"]`, `unset datafile [separator]`; `set samples N[,M]`;
!< - `plot 'file' [using [X:]Y[:...]] [index N] [every I:J:K:L:M:N] [with STYLE] [title "t"|notitle] [axes x1y1|x1y2]
!<   [lc [rgb] "color"|N] [lw W] [dt N] [ps S], ...` (`''` repeats the previous file), STYLE `lines|points|linespoints|
!<   yerrorbars|xerrorbars|xyerrorbars` (error bars: `x:y:dy` or `x:y:low:high`, `x:y:dx:dy` or
!<   `x:y:xlow:xhigh:ylow:yhigh`); `replot [items]`; a `using` field is a column number or a parenthesized expression,
!<   `($2*1e3)` (see foresight_expression); `ls N`, `lt N` in an item apply a line style, a palette color;
!< - a function of `x` as a plot item, `plot sin(x)/x title "sinc"` (same options, styles lines, points or linespoints,
!<   `set style function`, `lines` by default): sampled at `set samples` points (100) over the x range before its
!<   extension to the ticks, the data extent, or [-10:10] with neither; evenly in log x on a log axis.
!<
!< Anything else is an error naming the command, never silently ignored. Errors are returned (`iostat`, `iomsg` with
!< `source:line:`), not stopped on, so a watch loop can survive a bad cycle.
use foresight_axes, only : axes_names
use foresight_datafile, only : datafile_object
use foresight_expression, only : expression_object
use foresight_figure, only : figure_object
use foresight_format, only : format_check, int_str, real_from_decimal
use foresight_style, only : default_color
use foresight_ticks, only : tics_object
use foresight_tokens, only : split_statements, token_object, tokenize, TOKEN_COMMA, TOKEN_RANGE, TOKEN_STRING, &
                             TOKEN_WORD
use penf, only : I4P, I8P, R8P

implicit none
private
public :: script_object

real(R8P), parameter :: DUMB_CELL(2) = [0.55_R8P, 1.25_R8P] !< Text device cell size [font size].

type :: line_style_object
   !< Line properties: a `set style line`, or the options of a plot item; unallocated means the default.
   integer(I4P)                  :: id = 0_I4P !< Style number.
   character(len=:), allocatable :: lc         !< Color.
   real(R8P),        allocatable :: lw         !< Line width.
   integer(I4P),     allocatable :: dt         !< Dash type.
   real(R8P),        allocatable :: ps         !< Point size.
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
   type(line_style_object), allocatable :: line_styles(:)      !< `set style line` definitions.
   character(len=:), allocatable   :: separator                !< Data cell separators, empty for whitespace.
   integer(I4P)                    :: samples = 100_I4P        !< Function samples, `set samples`.
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
   if (allocated(self%line_styles)) deallocate(self%line_styles)
   allocate(self%line_styles(0))
   self%separator = ''
   self%samples = 100_I4P
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
         call func%compile(written, iostat, iomsg, variable='x')
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
      set_index = -1_I4P
      every = [1_I4P, 1_I4P, 0_I4P, 0_I4P, -1_I4P, -1_I4P]
      with = self%data_style
      if (is_function) with = self%function_style
      has_title = .false.
      title = ''
      axes = 'x1y1'
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
            call parse_using(spec, fields, iostat, iomsg)
            if (iostat /= 0_I4P) return
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
               call fail('plot: unsupported style "'//word//'" (supported: lines, points, linespoints, yerrorbars, '// &
                         'xerrorbars, xyerrorbars)', iostat, iomsg)
               return
            endif
            if (is_function .and. .not. function_drawable(with)) then
               call fail('plot: a function is drawn with lines, points or linespoints, not '//with, iostat, iomsg)
               return
            endif
         elseif (keyword(word, 'axes', 2_I4P)) then
            if (.not. next_word(tokens, i, axes, iostat, iomsg)) return
            if (axes /= 'x1y1' .and. axes /= 'x1y2') then
               call fail('plot: axes x1y1 or x1y2 expected, found "'//axes//'" (no second x axis)', iostat, iomsg)
               return
            endif
         elseif (keyword(word, 'title', 1_I4P)) then
            i = i + 1_I4P
            if (i > size(tokens, kind=I4P)) then
               call fail('plot: title needs a quoted string', iostat, iomsg)
               return
            endif
            if (tokens(i)%kind /= TOKEN_STRING) then
               call fail('plot: title needs a quoted string', iostat, iomsg)
               return
            endif
            title = tokens(i)%text
            has_title = .true.
         elseif (keyword(word, 'notitle', 3_I4P)) then
            title = ''
            has_title = .true.
         elseif (word == 'ls' .or. keyword(word, 'linestyle', 5_I4P)) then
            if (.not. next_integer(tokens, i, number, iostat, iomsg)) return
            call apply_line_style(self%line_styles, number, line)
         elseif (is_line_option(word)) then
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
      if (is_function) then
         ! sampled at the end; gnuplot: the expression as written is the title
         if (.not. has_title) title = written
         call self%figure%plot([real(R8P) ::], [real(R8P) ::], title=title, with=with, lc=line%lc, lw=line%lw, &
                               dt=line%dt, ps=line%ps, axes=axes)
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
      if (file /= loaded) then
         call data%load(file, iostat, iomsg, separator=self%separator)
         if (iostat /= 0_I4P) return
         loaded = file
         call self%register_file(file)
      endif
      ! columns: gnuplot defaults are 1:2 (0:1 for one column), 1:2:3 for x/y error bars, 1:2:3:4 for xy error bars
      if (.not. allocated(fields)) then
         select case (with)
         case ('yerrorbars', 'xerrorbars')
            fields = plain_columns([1_I4P, 2_I4P, 3_I4P])
         case ('xyerrorbars')
            fields = plain_columns([1_I4P, 2_I4P, 3_I4P, 4_I4P])
         case default
            call data%default_using(ux, uy)
            fields = plain_columns([ux, uy])
         endselect
      elseif (size(fields) == 1) then
         call point%set_column(0_I4P)
         fields = [point, fields(1)]
      endif
      nbar = size(fields, kind=I4P) - 2_I4P
      select case (with)
      case ('yerrorbars', 'xerrorbars')
         if (nbar /= 1_I4P .and. nbar /= 2_I4P) then
            call fail('plot: '//with//' needs using x:y:delta or x:y:low:high', iostat, iomsg)
            return
         endif
      case ('xyerrorbars')
         if (nbar /= 2_I4P .and. nbar /= 4_I4P) then
            call fail('plot: xyerrorbars needs using x:y:dx:dy or x:y:xlow:xhigh:ylow:yhigh', iostat, iomsg)
            return
         endif
      case default
         if (nbar /= 0_I4P) then
            call fail('plot: '//with//' needs using X:Y or Y', iostat, iomsg)
            return
         endif
      endselect
      if (.not. has_title) then
         ! gnuplot: the item as written, '' included
         title = quote//written//quote
         if (len(spec) > 0) title = title//' '//using//' '//spec
      endif
      call data%table(fields, set_index, every, values)
      x = values(:, 1)
      y = values(:, 2)
      if (allocated(xlow)) deallocate(xlow, xhigh)
      if (allocated(ylow)) deallocate(ylow, yhigh)
      select case (with)
      case ('yerrorbars')
         if (nbar == 1_I4P) then
            ylow = y - values(:, 3)
            yhigh = y + values(:, 3)
         else
            ylow = values(:, 3)
            yhigh = values(:, 4)
         endif
      case ('xerrorbars')
         if (nbar == 1_I4P) then
            xlow = x - values(:, 3)
            xhigh = x + values(:, 3)
         else
            xlow = values(:, 3)
            xhigh = values(:, 4)
         endif
      case ('xyerrorbars')
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
      call self%figure%plot(x, y, title=title, with=with, lc=line%lc, lw=line%lw, dt=line%dt, ps=line%ps, &
                            xlow=xlow, xhigh=xhigh, ylow=ylow, yhigh=yhigh, axes=axes)
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
      if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
      call self%figure%set_grid(.true.)
   elseif (keyword(option, 'key', 1_I4P)) then
      call key_option
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
         call fail('set terminal: svg, html or dumb expected', iostat, iomsg)
         return
      endif
      select case (tokens(2)%text)
      case ('svg', 'html')
      case ('dumb')
         ! gnuplot dumb default size, in characters
         self%figure%width = 79.0_R8P * DUMB_CELL(1) * self%figure%font_size
         self%figure%height = 24.0_R8P * DUMB_CELL(2) * self%figure%font_size
      case default
         call fail('set terminal: unsupported terminal "'//tokens(2)%text//'" (supported: svg, html, dumb)', &
                   iostat, iomsg)
         return
      endselect
      i = 3_I4P
      do while (i <= size(tokens, kind=I4P))
         if (keyword(tokens(i)%text, 'size', 2_I4P)) then
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
            if (tokens(2)%text == 'dumb') then
               ! characters to the virtual pixels of the text device
               self%figure%width = real(width, R8P) * DUMB_CELL(1) * self%figure%font_size
               self%figure%height = real(height, R8P) * DUMB_CELL(2) * self%figure%font_size
            else
               self%figure%width = real(width, R8P)
               self%figure%height = real(height, R8P)
            endif
         elseif (keyword(tokens(i)%text, 'refresh', 3_I4P)) then
            if (.not. next_integer(tokens, i, seconds, iostat, iomsg)) return
            call self%figure%set_refresh(seconds)
         else
            call fail('set terminal: unsupported option "'//tokens(i)%text//'"', iostat, iomsg)
            return
         endif
         i = i + 1_I4P
      enddo
      ! the terminal decides the format of the default output, never of one set explicitly
      if (.not. self%output_set) then
         if (tokens(2)%text == 'dumb') then
            self%output = '-'
         elseif (self%output == '-') then
            self%output = 'foresight.'//tokens(2)%text
         else
            self%output = change_extension(self%output, tokens(2)%text)
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
      call pair_option([0.0_R8P, 0.0_R8P])
   elseif (keyword(option, 'size', 2_I4P)) then
      call pair_option([1.0_R8P, 1.0_R8P])
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
      !< `set key [on|off] [left|right|center] [top|bottom|center] [box|nobox] [inside]`.
      character(len=:), allocatable :: words !< Position words.
      logical                       :: on    !< Key on.
      logical, allocatable          :: box   !< Box, unallocated if not given.

      on = .true.
      words = ''
      do i = 2_I4P, size(tokens, kind=I4P)
         select case (tokens(i)%text)
         case ('on')
            on = .true.
         case ('off')
            on = .false.
         case ('box')
            box = .true.
         case ('nobox')
            box = .false.
         case ('inside', 'ins')
         case ('left', 'right', 'center', 'top', 'bottom')
            words = words//' '//tokens(i)%text
         case default
            call fail('set key: unsupported option "'//tokens(i)%text//'" (supported: on, off, left, right, center, '// &
                      'top, bottom, box, nobox, inside)', iostat, iomsg)
            return
         endselect
      enddo
      call self%figure%set_key(on, position=words, box=box)
      endsubroutine key_option

      subroutine pair_option(default)
      !< `set origin [X,Y]` and `set size [W,H]`, page fractions; no values restore `default`.
      real(R8P), intent(in) :: default(2) !< Default values.
      real(R8P)             :: pair(2)    !< Values.

      if (self%figure%layout) then
         call fail('set '//option//': not supported with a multiplot layout', iostat, iomsg)
         return
      endif
      pair = default
      if (size(tokens) > 1) then
         if (size(tokens) /= 4 .or. tokens(2)%kind /= TOKEN_WORD .or. tokens(3)%kind /= TOKEN_COMMA .or. &
             tokens(4)%kind /= TOKEN_WORD) then
            call fail('set '//option//': two numbers X,Y expected (ratio, square are not supported)', iostat, iomsg)
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

      subroutine tics_option(tics)
      !< `set xtics|ytics|y2tics [auto|autofreq|STEP|START,STEP|START,STEP,END] [mirror|nomirror]`: without positions
      !< the last ones are kept, turning off ticks on (gnuplot); `auto` resets them.
      type(tics_object), intent(inout) :: tics    !< Axis tick settings.
      type(token_object), allocatable  :: args(:) !< Position tokens, mirror words removed.
      character(len=:), allocatable    :: message !< Problem.
      logical                          :: ok      !< Well formed.
      logical, allocatable             :: mirror  !< Mirror setting, unallocated if not given.
      integer(I4P)                     :: n       !< Position tokens.

      allocate(args(0))
      do i = 2_I4P, size(tokens, kind=I4P)
         if (tokens(i)%kind == TOKEN_WORD .and. keyword(tokens(i)%text, 'mirror', 3_I4P)) then
            mirror = .true.
         elseif (tokens(i)%kind == TOKEN_WORD .and. keyword(tokens(i)%text, 'nomirror', 4_I4P)) then
            mirror = .false.
         else
            args = [args, tokens(i)]
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
               call fail('set style function: '//with//' is not usable for function plots (lines, points, '// &
                         'linespoints are)', iostat, iomsg)
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
      call fail('set style: only "data STYLE", "function STYLE" and "line N ..." are supported', iostat, iomsg)
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
   if (keyword(option, 'logscale', 3_I4P)) then
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
      call self%figure%set_grid(.false.)
   elseif (keyword(option, 'key', 1_I4P)) then
      call self%figure%set_key(.false.)
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

   pure function canonical_style(word) result(style)
   !< Full gnuplot style name of `word` (full or abbreviated), empty if unsupported.
   character(len=*), intent(in)  :: word  !< Style word.
   character(len=:), allocatable :: style !< Full style name.

   select case (word)
   case ('l', 'lines')
      style = 'lines'
   case ('p', 'points')
      style = 'points'
   case ('lp', 'linespoints')
      style = 'linespoints'
   case ('yerr', 'yerrorbars')
      style = 'yerrorbars'
   case ('xerr', 'xerrorbars')
      style = 'xerrorbars'
   case ('xyerr', 'xyerrorbars')
      style = 'xyerrorbars'
   case default
      style = ''
   endselect
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

   subroutine parse_using(spec, fields, iostat, iomsg)
   !< `using` specification: 1 to 6 colon separated fields, each a column number (0 is the point number) or a
   !< parenthesized expression, as in gnuplot.
   character(len=*),                     intent(in)  :: spec      !< Specification.
   type(expression_object), allocatable, intent(out) :: fields(:) !< Fields.
   character(len=:), allocatable,        intent(out) :: iomsg     !< Error message.
   integer(I4P),                         intent(out) :: iostat    !< 0 on success.
   type(expression_object)                           :: field     !< Current field.
   integer(I4P)                                      :: start     !< Field start.
   integer(I4P)                                      :: finish    !< Field end.
   integer(I4P)                                      :: depth     !< Parenthesis depth.
   integer(I4P)                                      :: c         !< Column.

   iostat = 0_I4P
   iomsg = ''
   allocate(fields(0))
   start = 1_I4P
   do while (start <= len(spec) + 1)
      ! the field ends at the first ':' outside parentheses (a ?: inside an expression is not a separator)
      depth = 0_I4P
      finish = start
      do while (finish <= len(spec))
         if (spec(finish:finish) == '(') depth = depth + 1_I4P
         if (spec(finish:finish) == ')') depth = depth - 1_I4P
         if (spec(finish:finish) == ':' .and. depth == 0_I4P) exit
         finish = finish + 1_I4P
      enddo
      associate(text => spec(start:finish - 1_I4P))
         if (len(text) > 0 .and. verify(text, '0123456789') == 0 .and. len(text) < 10) then
            read(text, *) c
            call field%set_column(c)
         elseif (text(1:min(1, len(text))) == '(') then
            ! compiled first, so that an unbalanced expression gets the precise syntax error
            call field%compile(text, iostat, iomsg)
            if (iostat /= 0_I4P) then
               iomsg = 'using: '//iomsg
               return
            endif
            if (.not. is_parenthesized(text)) then
               call fail('using: field "'//text//'" must be a single parenthesized expression', iostat, iomsg)
               return
            endif
         else
            call fail('using: field "'//text//'" is neither a column number nor a parenthesized expression '// &
                      '(write ($2*1e3), not $2*1e3)', iostat, iomsg)
            return
         endif
      endassociate
      fields = [fields, field]
      start = finish + 1_I4P
   enddo
   if (size(fields) > 6) call fail('using: "'//spec//'" has more than 6 fields', iostat, iomsg)
   contains
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
      return
   enddo
   line%lc = default_color(id)
   endsubroutine apply_line_style

   pure function function_drawable(with) result(yes)
   !< Whether the style `with` draws a function: lines, points or linespoints, not error bars.
   character(len=*), intent(in) :: with !< Full style name.
   logical                      :: yes  !< Usable for functions.

   yes = with == 'lines' .or. with == 'points' .or. with == 'linespoints'
   endfunction function_drawable

   pure function is_item_option(word) result(is)
   !< Whether `word` is a plot item option: it ends a function expression.
   character(len=*), intent(in) :: word !< Word.
   logical                      :: is   !< Item option.

   is = keyword(word, 'using', 1_I4P) .or. keyword(word, 'index', 1_I4P) .or. keyword(word, 'every', 2_I4P) .or. &
        keyword(word, 'with', 1_I4P) .or. keyword(word, 'title', 1_I4P) .or. keyword(word, 'notitle', 3_I4P) .or. &
        keyword(word, 'axes', 2_I4P) .or. word == 'ls' .or. keyword(word, 'linestyle', 5_I4P) .or. is_line_option(word)
   endfunction is_item_option

   pure function is_line_option(word) result(is)
   !< Whether `word` names a line property: `lc`, `lt`, `lw`, `dt`, `ps` or their long forms.
   character(len=*), intent(in) :: word !< Option word.
   logical                      :: is   !< Line property.

   is = word == 'lc' .or. keyword(word, 'linecolor', 5_I4P) .or. word == 'lt' .or. keyword(word, 'linetype', 5_I4P) &
        .or. word == 'lw' .or. keyword(word, 'linewidth', 5_I4P) .or. word == 'dt' .or. keyword(word, 'dashtype', 5_I4P) &
        .or. word == 'ps' .or. keyword(word, 'pointsize', 6_I4P)
   endfunction is_line_option

   function line_option(tokens, i, line, iostat, iomsg) result(ok)
   !< Parse the line property at `tokens(i)` and its value into `line`, leaving `i` on the value's last token:
   !< `lc [rgb] "color"`, `lc N`, `lt N` (palette color N), `lw W`, `dt N`, `ps S`.
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
