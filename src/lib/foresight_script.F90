!< foresight_script, interpreter of a gnuplot command subset.
module foresight_script
!< foresight_script, interpreter of a gnuplot command subset.
!<
!< Supported (with gnuplot abbreviations):
!<
!< - `set|unset title|xlabel|ylabel ["text"]`, `set xrange|yrange [min:max]` (`*` or empty autoscales an end),
!<   `set|unset logscale [x|y|xy]`, `set|unset grid`, `set|unset key`, `set output "file"`,
!<   `set terminal svg|html [size W,H] [refresh SECONDS]`;
!< - `set terminal dumb [size COLS,ROWS]` (text, default 79x24 on standard output `-`);
!< - `set|unset multiplot [layout ROWS,COLS] [title "t"]`: each `plot` fills the next panel, settings carry over;
!< - `plot 'file' [using [X:]Y[:...]] [index N] [every N] [with STYLE] [title "t"|notitle] [lc [rgb] "color"|N] [lw W]
!<   [dt N] [ps S], ...` (`''` repeats the previous file), STYLE `lines|points|linespoints|yerrorbars|xerrorbars|
!<   xyerrorbars` (error bars: `x:y:dy` or `x:y:low:high`, `x:y:dx:dy` or `x:y:xlow:xhigh:ylow:yhigh`); `replot [items]`;
!<   a `using` field is a column number or a parenthesized expression, `($2*1e3)` (see foresight_expression).
!<
!< Anything else is an error naming the command, never silently ignored. Errors are returned (`iostat`, `iomsg` with
!< `source:line:`), not stopped on, so a watch loop can survive a bad cycle.
use foresight_datafile, only : datafile_object
use foresight_expression, only : expression_object
use foresight_figure, only : figure_object
use foresight_format, only : int_str
use foresight_style, only : default_color
use foresight_tokens, only : split_statements, token_object, tokenize, TOKEN_COMMA, TOKEN_RANGE, TOKEN_STRING, &
                             TOKEN_WORD
use penf, only : I4P, I8P, R8P

implicit none
private
public :: script_object

real(R8P), parameter :: DUMB_CELL(2) = [0.55_R8P, 1.25_R8P] !< Text device cell size [font size].

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
         if (self%figure%current >= size(self%figure%panels, kind=I4P)) then
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
      call self%plot_command(tokens(2:), iostat, iomsg)
   elseif (keyword(command, 'replot', 3_I4P)) then
      if (len(self%last_plot) == 0) then
         call fail('replot: no previous plot', iostat, iomsg)
         return
      endif
      if (size(tokens) > 1) self%last_plot = self%last_plot//', '//after_command(statement)
      call tokenize(self%last_plot, tokens, iostat, iomsg)
      if (iostat /= 0_I4P) return
      call self%plot_command(tokens, iostat, iomsg)
   else
      call fail('unsupported command "'//command//'"', iostat, iomsg)
   endif
   endsubroutine execute

   ! private procedures
   subroutine plot_command(self, tokens, iostat, iomsg)
   !< `plot` items: each a data file with modifiers, comma separated; replaces the previous plot and renders it.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Items tokens.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   type(datafile_object)                        :: data      !< Current data file.
   character(len=:), allocatable                :: file      !< Item data file.
   character(len=:), allocatable                :: written   !< Item data file as written, for the automatic title.
   character(len=:), allocatable                :: spec      !< `using` specification as written, empty if none.
   character(len=:), allocatable                :: using     !< `using` keyword as written.
   character(len=1)                             :: quote     !< Quote of the data file.
   character(len=:), allocatable                :: loaded    !< File in `data`.
   character(len=:), allocatable                :: word      !< Modifier.
   character(len=:), allocatable                :: title     !< Item title.
   character(len=:), allocatable                :: with      !< Item style.
   character(len=:), allocatable                :: lc        !< Item color, unallocated for default.
   real(R8P),        allocatable                :: lw        !< Item line width, unallocated for default.
   real(R8P),        allocatable                :: ps        !< Item point size, unallocated for default.
   integer(I4P),     allocatable                :: dt        !< Item dash type, unallocated for default.
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
   integer(I4P)                                 :: every     !< Point stride.
   integer(I4P)                                 :: number    !< Integer argument.
   integer(I4P)                                 :: i         !< Token counter.
   logical                                      :: has_title !< Title given (or notitle).

   iostat = 0_I4P
   iomsg = ''
   loaded = ''
   call self%figure%clear
   if (size(tokens) == 0) then
      call fail('plot: nothing to plot', iostat, iomsg)
      return
   endif
   i = 1_I4P
   do
      ! data file
      if (i > size(tokens, kind=I4P)) then
         call fail('plot: missing item after ","', iostat, iomsg)
         return
      endif
      if (tokens(i)%kind /= TOKEN_STRING) then
         call fail('plot: only quoted data files can be plotted, found "'//tokens(i)%text// &
                   '" (functions and expressions are not supported)', iostat, iomsg)
         return
      endif
      file = tokens(i)%text
      written = file
      quote = tokens(i)%quote
      if (len(file) == 0) file = self%previous_file
      if (len(file) == 0) then
         call fail('plot: '''' needs a previous data file', iostat, iomsg)
         return
      endif
      self%previous_file = file
      ! modifiers
      if (allocated(fields)) deallocate(fields)
      spec = ''
      set_index = -1_I4P
      every = 1_I4P
      with = 'lines'
      has_title = .false.
      title = ''
      if (allocated(lc)) deallocate(lc)
      if (allocated(lw)) deallocate(lw)
      if (allocated(ps)) deallocate(ps)
      if (allocated(dt)) deallocate(dt)
      i = i + 1_I4P
      do while (i <= size(tokens, kind=I4P))
         if (tokens(i)%kind == TOKEN_COMMA) exit
         word = tokens(i)%text
         if (tokens(i)%kind /= TOKEN_WORD) then
            call fail('plot: unexpected "'//word//'"', iostat, iomsg)
            return
         endif
         if (keyword(word, 'using', 1_I4P)) then
            using = word
            if (.not. next_word(tokens, i, spec, iostat, iomsg)) return
            call parse_using(spec, fields, iostat, iomsg)
            if (iostat /= 0_I4P) return
         elseif (keyword(word, 'index', 1_I4P)) then
            if (.not. next_integer(tokens, i, set_index, iostat, iomsg)) return
         elseif (keyword(word, 'every', 2_I4P)) then
            if (.not. next_integer(tokens, i, every, iostat, iomsg)) return
            if (every < 1_I4P) then
               call fail('plot: every needs a positive stride', iostat, iomsg)
               return
            endif
         elseif (keyword(word, 'with', 1_I4P)) then
            if (.not. next_word(tokens, i, word, iostat, iomsg)) return
            with = canonical_style(word)
            if (len(with) == 0) then
               call fail('plot: unsupported style "'//word//'" (supported: lines, points, linespoints, yerrorbars, '// &
                         'xerrorbars, xyerrorbars)', iostat, iomsg)
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
         elseif (word == 'lc' .or. keyword(word, 'linecolor', 5_I4P)) then
            i = i + 1_I4P
            if (i <= size(tokens, kind=I4P)) then
               if (tokens(i)%kind == TOKEN_WORD .and. keyword(tokens(i)%text, 'rgbcolor', 3_I4P)) i = i + 1_I4P
            endif
            if (i > size(tokens, kind=I4P)) then
               call fail('plot: lc needs a color', iostat, iomsg)
               return
            endif
            if (tokens(i)%kind == TOKEN_STRING) then
               lc = tokens(i)%text
            else
               i = i - 1_I4P
               if (.not. next_integer(tokens, i, number, iostat, iomsg)) return
               lc = default_color(number)
            endif
         elseif (word == 'lw' .or. keyword(word, 'linewidth', 5_I4P)) then
            allocate(lw)
            if (.not. next_real(tokens, i, lw, iostat, iomsg)) return
         elseif (word == 'dt' .or. keyword(word, 'dashtype', 5_I4P)) then
            allocate(dt)
            if (.not. next_integer(tokens, i, dt, iostat, iomsg)) return
         elseif (word == 'ps' .or. keyword(word, 'pointsize', 6_I4P)) then
            allocate(ps)
            if (.not. next_real(tokens, i, ps, iostat, iomsg)) return
         else
            call fail('plot: unsupported option "'//word//'"', iostat, iomsg)
            return
         endif
         i = i + 1_I4P
      enddo
      ! data
      if (file /= loaded) then
         call data%load(file, iostat, iomsg)
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
      call self%figure%plot(x, y, title=title, with=with, lc=lc, lw=lw, dt=dt, ps=ps, &
                            xlow=xlow, xhigh=xhigh, ylow=ylow, yhigh=yhigh)
      if (i > size(tokens, kind=I4P)) exit
      i = i + 1_I4P
   enddo
   if (self%multiplot) self%advance_pending = .true.
   call self%save_output(iostat, iomsg)
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
   elseif (keyword(option, 'xrange', 2_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%xaxis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user)
      endassociate
   elseif (keyword(option, 'yrange', 2_I4P)) then
      associate(axis => self%figure%panels(self%figure%current)%yaxis)
         call set_range(axis%min_fixed, axis%min_user, axis%max_fixed, axis%max_user)
      endassociate
   elseif (keyword(option, 'logscale', 3_I4P)) then
      if (.not. axes_argument(tokens, text, iostat, iomsg)) return
      call self%figure%set_logscale(text)
   elseif (keyword(option, 'grid', 2_I4P)) then
      if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
      call self%figure%set_grid(.true.)
   elseif (keyword(option, 'key', 1_I4P)) then
      if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
      call self%figure%set_key(.true.)
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
      if (rows < 1_I4P .or. cols < 1_I4P) then
         call fail('set multiplot: layout ROWS,COLS with positive values is required', iostat, iomsg)
         return
      endif
      call self%figure%set_multiplot(rows, cols, text)
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
   endsubroutine set_command

   subroutine unset_command(self, tokens, iostat, iomsg)
   !< `unset` options.
   class(script_object),          intent(inout) :: self      !< Interpreter.
   type(token_object),            intent(in)    :: tokens(:) !< Option tokens.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   character(len=:), allocatable                :: option    !< Option word.
   character(len=:), allocatable                :: axes      !< Axes letters.

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
   endif
   if (.not. no_more(tokens, 2_I4P, iostat, iomsg)) return
   if (keyword(option, 'multiplot', 5_I4P)) then
      call self%figure%unset_multiplot
      self%multiplot = .false.
      self%advance_pending = .false.
   elseif (keyword(option, 'title', 3_I4P)) then
      call self%figure%set_title('')
   elseif (keyword(option, 'xlabel', 2_I4P)) then
      call self%figure%set_xlabel('')
   elseif (keyword(option, 'ylabel', 2_I4P)) then
      call self%figure%set_ylabel('')
   elseif (keyword(option, 'grid', 2_I4P)) then
      call self%figure%set_grid(.false.)
   elseif (keyword(option, 'key', 1_I4P)) then
      call self%figure%set_key(.false.)
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
   !< Optional axes letters after a `logscale` option (default `xy`); a base other than 10 is an error.
   type(token_object),            intent(in)  :: tokens(:) !< Option tokens.
   character(len=:), allocatable, intent(out) :: axes      !< Axes letters.
   integer(I4P),                  intent(out) :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out) :: iomsg     !< Error message.
   logical                                    :: ok        !< Success.

   iostat = 0_I4P
   iomsg = ''
   axes = 'xy'
   ok = .true.
   if (size(tokens) >= 2) then
      axes = tokens(2)%text
      if (len(axes) == 0 .or. verify(axes, 'xy') > 0) then
         call fail('logscale: axes x, y or xy expected, found "'//axes//'"', iostat, iomsg)
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

   function to_number(word, value) result(ok)
   !< Parse a number.
   character(len=*), intent(in)  :: word   !< Text.
   real(R8P),        intent(out) :: value  !< Number.
   logical                       :: ok     !< Success.
   integer(I4P)                  :: iostat !< Conversion status.

   value = 0.0_R8P
   ok = verify(word, '0123456789+-.eEdD') == 0 .and. scan(word, '0123456789') > 0
   if (.not. ok) return
   read(word, *, iostat=iostat) value
   ok = iostat == 0_I4P
   endfunction to_number
endmodule foresight_script
