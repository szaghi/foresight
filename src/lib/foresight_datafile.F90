!< foresight_datafile, gnuplot-style text data files.
module foresight_datafile
!< foresight_datafile, gnuplot-style text data files.
!<
!< Format, as gnuplot's default: whitespace separated numeric columns; `#` starts a comment; one blank line ends a
!< block (plotted lines are broken there), two blank lines end a dataset (selected by `index`, 0-based); cells that
!< are `?`, `NaN`, `inf`, empty or not numbers are missing values (gaps). Pseudo-column 0 numbers the selected points of
!< each dataset from 0 (with `every`, only the points it keeps are counted, as gnuplot).
!<
!< With `label_column` N, the text of column N of every row is kept too (`labels`, `table(..., labels=...)`): the text
!< labels of `using ...:xtic(N)`; blanks around a cell and double quotes are removed, a missing cell is blank.
!<
!< The first row of each dataset is kept as text too: with headers in use (`table(..., header=.true.)`) it names the
!< columns, for `using 1:"name"` and `title columnhead`, and is not data; else it is a row as any other.
!<
!< A cell is read as gnuplot does, by C `strtod`: its longest leading number counts and the rest is ignored (`3abc` is
!< 3, `1.2.3` is 1.2, `1d3` is 1), hexadecimal included (`0x10` is 16, `0x1.8p1` is 3); a value beyond the real range
!< is a gap.
!<
!< With a separator (gnuplot `set datafile separator`, e.g. `,` for CSV) every one of its characters ends a cell:
!< two separators in a row leave an empty cell, a trailing one an empty last cell; blanks around a cell are ignored and
!< a cell in double quotes is read without them (`"7"` is 7), its separators kept. Without one, a double quoted cell
!< may hold blanks and is not a number, as gnuplot.
!<
!< Values are stored flattened, rows by offsets, with capacities doubled on growth: a large monitoring log costs one
!< real per value plus three integers per row.
use, intrinsic :: ieee_arithmetic, only : ieee_quiet_nan, ieee_value
use, intrinsic :: iso_fortran_env, only : iostat_end, iostat_eor
use foresight_expression, only : expression_object
use foresight_format, only : real_from_decimal
use penf, only : I4P, R8P

implicit none
private
public :: datafile_object

character(len=1), parameter :: TAB = achar(9) !< Tab character.

type :: text_object
   !< Cell text.
   character(len=:), allocatable :: text !< Text, unquoted.
endtype text_object

type :: header_object
   !< First row of a dataset, as text.
   type(text_object), allocatable :: cells(:) !< Cells.
endtype header_object

type :: datafile_object
   !< Data file content.
   character(len=:), allocatable :: file              !< File name.
   real(R8P),    allocatable     :: values(:)         !< Row values, flattened.
   integer(I4P), allocatable     :: first(:)          !< Index in `values` of the first value of each row (+1 sentinel).
   integer(I4P), allocatable     :: dataset(:)        !< Dataset (0-based) of each row.
   integer(I4P), allocatable     :: block(:)          !< Block (global counter) of each row.
   type(header_object), allocatable :: headers(:)     !< First row of each dataset as text, by dataset from 1.
   integer(I4P)                     :: label_column = 0_I4P !< Column kept as text in `labels`, 0 for none.
   type(text_object), allocatable   :: labels(:)       !< Text of column `label_column` of each row.
   integer(I4P)                  :: nrows   = 0_I4P   !< Number of data rows.
   integer(I4P)                  :: nvalues = 0_I4P   !< Number of stored values.
   contains
      procedure, pass(self) :: column_header !< Header name of a column.
      procedure, pass(self) :: columns       !< Extract a (x, y) series.
      procedure, pass(self) :: default_using !< gnuplot default columns.
      procedure, pass(self) :: header_names  !< Header names of a dataset.
      procedure, pass(self) :: load          !< Read a file.
      procedure, pass(self) :: matrix        !< Values as a matrix (gnuplot `matrix`).
      procedure, pass(self) :: missing_name  !< A header name of the fields found nowhere.
      procedure, pass(self) :: table         !< Evaluate `using` fields.
endtype datafile_object

contains
   subroutine load(self, file, iostat, iomsg, separator, label_column)
   !< Read `file`, replacing the current content; cells are separated by whitespace, or by any of the `separator`
   !< characters when given and not empty; with `label_column` > 0 the text of that column of each row is kept.
   class(datafile_object),        intent(inout)        :: self      !< Data.
   character(len=*),              intent(in)           :: file      !< File name.
   integer(I4P),                  intent(out)          :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg     !< Error message.
   character(len=*),              intent(in), optional :: separator !< Cell separator characters.
   integer(I4P),                  intent(in), optional :: label_column !< Column kept as text, 0 for none.
   character(len=:), allocatable                       :: line      !< Current line.
   character(len=:), allocatable                       :: sep       !< Cell separator characters, empty for whitespace.
   character(len=256)                                  :: message   !< I/O message.
   integer(I4P)                                        :: unit      !< File unit.
   integer(I4P)                                        :: blanks    !< Blank lines since the last data row.
   integer(I4P)                                        :: dset      !< Current dataset.
   integer(I4P)                                        :: blk       !< Current block.
   integer(I4P)                                        :: i         !< Character counter.
   integer(I4P)                                        :: j         !< Cell end.
   integer(I4P)                                        :: n         !< Code part length.
   logical                                             :: quoted    !< Inside double quotes.
   logical                                             :: eof       !< End of file reached.
   logical                                             :: recording !< Recording the header of a dataset.
   integer(I4P)                                        :: cell      !< Cell number in the row.

   self%file = file
   sep = ''
   if (present(separator)) sep = separator
   self%nrows = 0_I4P
   self%nvalues = 0_I4P
   if (allocated(self%values)) deallocate(self%values)
   if (allocated(self%first)) deallocate(self%first)
   if (allocated(self%dataset)) deallocate(self%dataset)
   if (allocated(self%block)) deallocate(self%block)
   if (allocated(self%headers)) deallocate(self%headers)
   if (allocated(self%labels)) deallocate(self%labels)
   self%label_column = 0_I4P
   if (present(label_column)) self%label_column = max(0_I4P, label_column)
   allocate(self%values(1024), self%first(257), self%dataset(256), self%block(256), self%headers(0), self%labels(0))
   self%first(1) = 1_I4P
   iomsg = ''
   open(newunit=unit, file=file, action='read', status='old', form='formatted', access='sequential', &
        iostat=iostat, iomsg=message)
   if (iostat /= 0_I4P) then
      iomsg = 'cannot open "'//file//'": '//trim(message)
      return
   endif
   blanks = 0_I4P
   dset = 0_I4P
   blk = 0_I4P
   do
      call read_line(unit, line, eof, iostat)
      if (iostat /= 0_I4P) then
         iomsg = 'read error in "'//file//'"'
         exit
      endif
      if (eof .and. len(line) == 0) exit
      n = index(line, '#', kind=I4P) - 1_I4P
      if (n < 0_I4P) n = len(line, kind=I4P)
      if (len_trim(line(1:n)) == 0) then
         ! comment lines are neither data nor separators
         if (n == len(line)) blanks = blanks + 1_I4P
      else
         if (self%nrows > 0_I4P) then
            if (blanks >= 2_I4P) dset = dset + 1_I4P
            if (blanks >= 1_I4P) blk = blk + 1_I4P
         endif
         blanks = 0_I4P
         call new_row(dset, blk)
         cell = 0_I4P
         i = 1_I4P
         if (len(sep) == 0) then
            ! whitespace separated: runs of blanks between cells, a quoted cell may hold blanks
            do while (i <= n)
               if (line(i:i) == ' ' .or. line(i:i) == TAB) then
                  i = i + 1_I4P
                  cycle
               endif
               j = i
               quoted = line(i:i) == '"'
               do while (j < n)
                  if (.not. quoted .and. (line(j + 1_I4P:j + 1_I4P) == ' ' .or. line(j + 1_I4P:j + 1_I4P) == TAB)) exit
                  j = j + 1_I4P
                  if (line(j:j) == '"') quoted = .not. quoted
               enddo
               call add_value(to_real(line(i:j)))
               if (recording) call record(line(i:j))
               cell = cell + 1_I4P
               if (cell == self%label_column) self%labels(self%nrows)%text = clean(line(i:j))
               i = j + 1_I4P
            enddo
         else
            ! every separator ends a cell, also an empty one; separators inside double quotes do not
            do
               j = i
               quoted = .false.
               do while (j <= n)
                  if (line(j:j) == '"') quoted = .not. quoted
                  if (.not. quoted .and. index(sep, line(j:j)) > 0) exit
                  j = j + 1_I4P
               enddo
               call add_value(cell_value(line(i:j - 1_I4P)))
               if (recording) call record(line(i:j - 1_I4P))
               cell = cell + 1_I4P
               if (cell == self%label_column) self%labels(self%nrows)%text = clean(line(i:j - 1_I4P))
               if (j > n) exit
               i = j + 1_I4P
            enddo
         endif
      endif
      if (eof) exit
   enddo
   close(unit)
   contains
      subroutine new_row(dset, blk)
      !< Start a new row, doubling the row arrays when full.
      integer(I4P), intent(in)  :: dset     !< Row dataset.
      integer(I4P), intent(in)  :: blk      !< Row block.
      integer(I4P), allocatable :: iwork(:) !< Growth buffer.
      integer(I4P)              :: capacity !< New row capacity.

      if (self%nrows == size(self%dataset, kind=I4P)) then
         capacity = 2_I4P * self%nrows
         allocate(iwork(capacity))
         iwork(1:self%nrows) = self%dataset(1:self%nrows)
         call move_alloc(iwork, self%dataset)
         allocate(iwork(capacity))
         iwork(1:self%nrows) = self%block(1:self%nrows)
         call move_alloc(iwork, self%block)
         allocate(iwork(capacity + 1_I4P))
         iwork(1:self%nrows + 1_I4P) = self%first(1:self%nrows + 1_I4P)
         call move_alloc(iwork, self%first)
      endif
      self%nrows = self%nrows + 1_I4P
      if (self%label_column > 0_I4P) then
         if (self%nrows > size(self%labels)) call grow_labels
         self%labels(self%nrows)%text = ''
      endif
      self%dataset(self%nrows) = dset
      self%block(self%nrows) = blk
      self%first(self%nrows + 1_I4P) = self%nvalues + 1_I4P
      ! the first row of a dataset is also kept as text, a header if one is used
      recording = self%nrows == 1_I4P
      if (.not. recording) recording = self%dataset(self%nrows - 1_I4P) /= dset
      if (recording) self%headers = [self%headers, header_object([text_object ::])]
      endsubroutine new_row

      subroutine record(cell)
      !< Append `cell` to the header of the current dataset: blanks around it and double quotes removed.
      character(len=*), intent(in)  :: cell !< Cell text.
      character(len=:), allocatable :: text !< Clean text (a temporary: gfortran 16 crashes on the function result
                                            !< in the constructor).

      text = clean(cell)
      associate(header => self%headers(size(self%headers)))
         header%cells = [header%cells, text_object(text)]
      endassociate
      endsubroutine record

      subroutine grow_labels
      !< Double the row labels.
      type(text_object), allocatable :: work(:) !< Growth buffer.

      allocate(work(max(256_I4P, 2_I4P * size(self%labels, kind=I4P))))
      work(1:size(self%labels)) = self%labels
      call move_alloc(work, self%labels)
      endsubroutine grow_labels

      subroutine add_value(v)
      !< Append a value to the current row, doubling the storage when full.
      real(R8P), intent(in)  :: v        !< Value.
      real(R8P), allocatable :: rwork(:) !< Growth buffer.

      if (self%nvalues == size(self%values, kind=I4P)) then
         allocate(rwork(2_I4P * self%nvalues))
         rwork(1:self%nvalues) = self%values(1:self%nvalues)
         call move_alloc(rwork, self%values)
      endif
      self%nvalues = self%nvalues + 1_I4P
      self%values(self%nvalues) = v
      self%first(self%nrows + 1_I4P) = self%nvalues + 1_I4P
      endsubroutine add_value
   endsubroutine load

   pure subroutine default_using(self, ux, uy)
   !< gnuplot default columns: `1:2`, or `0:1` for single-column data.
   class(datafile_object), intent(in)  :: self !< Data.
   integer(I4P),           intent(out) :: ux   !< Abscissa column.
   integer(I4P),           intent(out) :: uy   !< Ordinate column.

   ux = 1_I4P
   uy = 2_I4P
   if (self%nrows > 0_I4P) then
      if (self%first(2) - self%first(1) < 2_I4P) then
         ux = 0_I4P
         uy = 1_I4P
      endif
   endif
   endsubroutine default_using

   subroutine columns(self, ux, uy, index, every, x, y)
   !< Series of columns (`ux`, `uy`) of dataset `index` (all if negative), one point every `every` in each block.
   class(datafile_object), intent(in)  :: self      !< Data.
   integer(I4P),           intent(in)  :: ux        !< Abscissa column, 0 for the point number.
   integer(I4P),           intent(in)  :: uy        !< Ordinate column, 0 for the point number.
   integer(I4P),           intent(in)  :: index     !< Dataset, 0-based; negative for all.
   integer(I4P),           intent(in)  :: every     !< Point stride within each block.
   real(R8P), allocatable, intent(out) :: x(:)      !< Abscissae.
   real(R8P), allocatable, intent(out) :: y(:)      !< Ordinates.
   type(expression_object)             :: fields(2) !< Plain columns.
   real(R8P), allocatable              :: values(:,:) !< Points.

   call fields(1)%set_column(ux)
   call fields(2)%set_column(uy)
   call self%table(fields, index, [every, 1_I4P, 0_I4P, 0_I4P, -1_I4P, -1_I4P], values)
   x = values(:, 1)
   y = values(:, 2)
   endsubroutine columns

   subroutine table(self, fields, index, every, values, header, labels)
   !< Values of the `using` `fields` on the rows of dataset `index` (all if negative) selected by `every`:
   !< `values(point, field)`.
   !<
   !< With `header` the first row of each dataset names the columns: it is skipped, neither a point nor counted, and
   !< the column header names of the fields are resolved on the header of each dataset. `labels` returns the text of
   !< the label column (see `load`) of each point, blank for breaks or without a label column.
   !<
   !< `every` is gnuplot's `point_incr:block_incr:start_point:start_block:end_point:end_block`, an end negative for
   !< none. Points are numbered within their block, blocks within their dataset, from 0.
   !<
   !< A NaN point is inserted where a block or dataset changes, so that lines are broken as in gnuplot. Missing cells,
   !< rows too short for a column and undefined expressions give NaN values (gaps).
   class(datafile_object),  intent(in)  :: self        !< Data.
   type(expression_object), intent(in)  :: fields(:)   !< `using` fields.
   integer(I4P),            intent(in)  :: index       !< Dataset, 0-based; negative for all.
   integer(I4P),            intent(in)  :: every(6)    !< gnuplot `every` fields.
   real(R8P), allocatable,  intent(out) :: values(:,:) !< Points.
   logical,                 intent(in), optional :: header !< The first row of each dataset is a header.
   character(len=:), allocatable, intent(out), optional :: labels(:) !< Text labels of the points.
   logical                              :: headed      !< Headers in use.
   integer(I4P)                         :: width       !< Label length.
   integer(I4P)                         :: r           !< Row counter.

   headed = .false.
   if (present(header)) headed = header
   allocate(values(count_points(), size(fields)))
   if (present(labels)) then
      ! the longest row label, at least 1
      width = 1_I4P
      if (self%label_column > 0_I4P) then
         do r = 1_I4P, self%nrows
            width = max(width, len(self%labels(r)%text, kind=I4P))
         enddo
      endif
      allocate(character(len=width) :: labels(size(values, 1)))
      labels = ''
   endif
   call store_points
   contains
      pure function is_header(r) result(yes)
      !< Whether row `r` is a header: the first of its dataset, with headers in use.
      integer(I4P), intent(in) :: r   !< Row.
      logical                  :: yes !< Header row.

      yes = headed
      if (yes .and. r > 1_I4P) yes = self%dataset(r) /= self%dataset(r - 1_I4P)
      endfunction is_header

      pure function count_points() result(total)
      !< Number of points, breaks included.
      integer(I4P) :: total    !< Points.
      integer(I4P) :: r        !< Row counter.
      integer(I4P) :: in_block !< Point number within the block.
      integer(I4P) :: in_set_block !< Block number within the dataset.
      integer(I4P) :: last_blk !< Block of the last selected point.

      total = 0_I4P
      in_block = -1_I4P
      in_set_block = -1_I4P
      last_blk = -1_I4P
      do r = 1_I4P, self%nrows
         call advance(r, in_block, in_set_block)
         if (is_header(r)) then
            ! the next row is the first point of the block
            in_block = -1_I4P
            cycle
         endif
         if (.not. selected(r, in_block, in_set_block)) cycle
         if (last_blk >= 0_I4P .and. self%block(r) /= last_blk) total = total + 1_I4P
         last_blk = self%block(r)
         total = total + 1_I4P
      enddo
      endfunction count_points

      subroutine store_points
      !< Store the points, NaN breaks between blocks.
      integer(I4P) :: r        !< Row counter.
      integer(I4P) :: k        !< Point counter.
      integer(I4P) :: f        !< Field counter.
      integer(I4P) :: in_block !< Point number within the block.
      integer(I4P) :: in_set_block !< Block number within the dataset.
      integer(I4P) :: last_blk !< Block of the last selected point.
      integer(I4P) :: picked   !< Selected point number within the dataset: gnuplot's column 0.
      integer(I4P) :: set      !< Dataset of the last selected point.
      type(expression_object) :: resolved(size(fields)) !< Fields on the header of the current dataset.
      character(len=:), allocatable :: names(:) !< Header names of the current dataset.

      resolved = fields
      k = 0_I4P
      in_block = -1_I4P
      in_set_block = -1_I4P
      last_blk = -1_I4P
      picked = -1_I4P
      set = -1_I4P
      do r = 1_I4P, self%nrows
         call advance(r, in_block, in_set_block)
         if (is_header(r)) then
            in_block = -1_I4P
            call self%header_names(self%dataset(r), names)
            do f = 1_I4P, size(fields, kind=I4P)
               resolved(f) = fields(f)%resolve(names)
            enddo
            cycle
         endif
         if (.not. selected(r, in_block, in_set_block)) cycle
         if (last_blk >= 0_I4P .and. self%block(r) /= last_blk) then
            k = k + 1_I4P
            values(k, :) = ieee_value(1.0_R8P, ieee_quiet_nan)
         endif
         last_blk = self%block(r)
         if (self%dataset(r) /= set) picked = -1_I4P
         set = self%dataset(r)
         picked = picked + 1_I4P
         k = k + 1_I4P
         do f = 1_I4P, size(fields, kind=I4P)
            values(k, f) = resolved(f)%evaluate(self%values(self%first(r):self%first(r + 1_I4P) - 1_I4P), picked)
         enddo
         if (present(labels) .and. self%label_column > 0_I4P) labels(k) = self%labels(r)%text
      enddo
      endsubroutine store_points

      pure subroutine advance(r, in_block, in_set_block)
      !< Update the point number within the block and the block number within the dataset for row `r`.
      integer(I4P), intent(in)    :: r            !< Row.
      integer(I4P), intent(inout) :: in_block     !< Point number within the block.
      integer(I4P), intent(inout) :: in_set_block !< Block number within the dataset.

      if (r == 1_I4P) then
         in_set_block = 0_I4P
      elseif (self%dataset(r) /= self%dataset(r - 1_I4P)) then
         in_block = -1_I4P
         in_set_block = 0_I4P
      elseif (self%block(r) /= self%block(r - 1_I4P)) then
         in_block = -1_I4P
         in_set_block = in_set_block + 1_I4P
      endif
      in_block = in_block + 1_I4P
      endsubroutine advance

      pure function selected(r, in_block, in_set_block) result(yes)
      !< Whether row `r` belongs to the selected dataset and to the `every` selection.
      integer(I4P), intent(in) :: r            !< Row.
      integer(I4P), intent(in) :: in_block     !< Point number within the block.
      integer(I4P), intent(in) :: in_set_block !< Block number within the dataset.
      logical                  :: yes          !< Row selected.

      yes = in_loop(in_block, every(3), every(1), every(5)) .and. in_loop(in_set_block, every(4), every(2), every(6))
      if (index >= 0_I4P) yes = yes .and. self%dataset(r) == index
      endfunction selected

      pure function in_loop(k, first, increment, last) result(yes)
      !< Whether `k` is visited by the loop `first, last, increment` (no end if `last` is negative).
      integer(I4P), intent(in) :: k         !< Number.
      integer(I4P), intent(in) :: first     !< Loop start.
      integer(I4P), intent(in) :: increment !< Loop increment.
      integer(I4P), intent(in) :: last      !< Loop end, negative for none.
      logical                  :: yes       !< Visited.

      yes = k >= first
      if (yes) yes = modulo(k - first, max(1_I4P, increment)) == 0_I4P
      if (yes .and. last >= 0_I4P) yes = k <= last
      endfunction in_loop
   endsubroutine table

   pure subroutine matrix(self, index, z, message)
   !< Values of dataset `index` (all if negative) as gnuplot `matrix` data: `z(column, row)`, the column the x index
   !< and the row the y index, both from 0 in the file order; every row must have the same number of values.
   class(datafile_object),  intent(in)  :: self    !< Data.
   integer(I4P),            intent(in)  :: index   !< Dataset, 0-based; negative for all.
   real(R8P), allocatable,  intent(out) :: z(:,:)  !< Values.
   character(len=:), allocatable, intent(out) :: message !< Problem, empty if none.
   integer(I4P)                         :: r       !< Row counter.
   integer(I4P)                         :: n       !< Rows selected.
   integer(I4P)                         :: m       !< Values per row.

   message = ''
   n = 0_I4P
   m = -1_I4P
   do r = 1_I4P, self%nrows
      if (index >= 0_I4P .and. self%dataset(r) /= index) cycle
      if (m < 0_I4P) m = self%first(r + 1_I4P) - self%first(r)
      if (self%first(r + 1_I4P) - self%first(r) /= m) then
         message = 'matrix: every row needs the same number of values'
         allocate(z(0, 0))
         return
      endif
      n = n + 1_I4P
   enddo
   allocate(z(max(0_I4P, m), n))
   n = 0_I4P
   do r = 1_I4P, self%nrows
      if (index >= 0_I4P .and. self%dataset(r) /= index) cycle
      n = n + 1_I4P
      z(:, n) = self%values(self%first(r):self%first(r + 1_I4P) - 1_I4P)
   enddo
   endsubroutine matrix

   pure function column_header(self, set, c) result(name)
   !< Header name of column `c` (from 1) of dataset `set` (from 0), empty if none.
   class(datafile_object), intent(in) :: self !< Data.
   integer(I4P),           intent(in) :: set  !< Dataset.
   integer(I4P),           intent(in) :: c    !< Column.
   character(len=:), allocatable      :: name !< Header name.

   name = ''
   if (set < 0_I4P .or. set >= size(self%headers, kind=I4P)) return
   associate(header => self%headers(set + 1_I4P))
      if (c >= 1_I4P .and. c <= size(header%cells, kind=I4P)) name = header%cells(c)%text
   endassociate
   endfunction column_header

   pure subroutine header_names(self, set, names)
   !< Header names of the columns of dataset `set` (from 0), blank padded; none if no such dataset.
   !<
   !< A subroutine: a function with this deferred length array result, called in an internal procedure, is an internal
   !< compiler error of gfortran 16.
   class(datafile_object),        intent(in)  :: self     !< Data.
   integer(I4P),                  intent(in)  :: set      !< Dataset.
   character(len=:), allocatable, intent(out) :: names(:) !< Names of columns 1, 2, ...
   integer(I4P)                       :: c        !< Column counter.
   integer(I4P)                       :: width    !< Longest name.

   if (set < 0_I4P .or. set >= size(self%headers, kind=I4P)) then
      allocate(character(len=0) :: names(0))
      return
   endif
   associate(header => self%headers(set + 1_I4P))
      width = 0_I4P
      do c = 1_I4P, size(header%cells, kind=I4P)
         width = max(width, len(header%cells(c)%text, kind=I4P))
      enddo
      allocate(character(len=width) :: names(size(header%cells)))
      do c = 1_I4P, size(header%cells, kind=I4P)
         names(c) = header%cells(c)%text
      enddo
   endassociate
   endsubroutine header_names

   pure function missing_name(self, fields, index) result(name)
   !< First column header name of the `fields` that no header of dataset `index` (all if negative) has, empty if none.
   class(datafile_object),  intent(in) :: self      !< Data.
   type(expression_object), intent(in) :: fields(:) !< `using` fields.
   integer(I4P),            intent(in) :: index     !< Dataset, 0-based; negative for all.
   character(len=:), allocatable       :: name      !< Missing name.
   integer(I4P)                        :: f         !< Field counter.
   integer(I4P)                        :: k         !< Name counter.
   integer(I4P)                        :: set       !< Dataset counter.
   logical                             :: found     !< Name found.
   character(len=:), allocatable       :: names(:)  !< Header names of a dataset.

   do f = 1_I4P, size(fields, kind=I4P)
      do k = 1_I4P, fields(f)%name_count()
         name = fields(f)%name_of(k)
         found = .false.
         do set = 0_I4P, size(self%headers, kind=I4P) - 1_I4P
            if (index >= 0_I4P .and. set /= index) cycle
            call self%header_names(set, names)
            if (any(names == name)) then
               found = .true.
               exit
            endif
         enddo
         if (.not. found) return
      enddo
   enddo
   name = ''
   endfunction missing_name

   ! private procedures
   pure function clean(cell) result(text)
   !< `cell` without the blanks around it and its double quotes.
   character(len=*), intent(in)  :: cell  !< Cell text.
   character(len=:), allocatable :: text  !< Clean text.
   integer(I4P)                  :: first !< First character kept.
   integer(I4P)                  :: last  !< Last character kept.

   first = verify(cell, ' '//TAB, kind=I4P)
   last = verify(cell, ' '//TAB, back=.true., kind=I4P)
   if (first == 0_I4P) then
      first = 1_I4P
      last = 0_I4P
   elseif (last > first .and. cell(first:first) == '"' .and. cell(last:last) == '"') then
      first = first + 1_I4P
      last = last - 1_I4P
   endif
   text = cell(first:last)
   endfunction clean

   subroutine read_line(unit, line, eof, iostat)
   !< Read a whole line of any length; `eof` is set on the last one, which may still carry text.
   integer(I4P),                  intent(in)  :: unit   !< File unit.
   character(len=:), allocatable, intent(out) :: line   !< Line.
   logical,                       intent(out) :: eof    !< End of file reached.
   integer(I4P),                  intent(out) :: iostat !< 0, or an I/O error code.
   character(len=512)                         :: buffer !< Read buffer.
   integer(I4P)                               :: nread  !< Characters read.

   line = ''
   eof = .false.
   do
      read(unit, '(A)', advance='no', iostat=iostat, size=nread) buffer
      line = line//buffer(1:nread)
      if (iostat == iostat_eor) then
         iostat = 0_I4P
         exit
      elseif (iostat == iostat_end) then
         iostat = 0_I4P
         eof = .true.
         exit
      elseif (iostat /= 0_I4P) then
         exit
      endif
   enddo
   endsubroutine read_line

   function cell_value(cell) result(v)
   !< Number in a separated `cell`: blanks around it ignored, then double quotes around it; NaN if empty or not a number.
   character(len=*), intent(in) :: cell  !< Cell text.
   real(R8P)                    :: v     !< Value.
   integer(I4P)                 :: first !< First character of the trimmed cell.
   integer(I4P)                 :: last  !< Last character of the trimmed cell.

   first = verify(cell, ' '//TAB, kind=I4P)
   last = verify(cell, ' '//TAB, back=.true., kind=I4P)
   if (first == 0_I4P) then
      v = ieee_value(1.0_R8P, ieee_quiet_nan)
      return
   endif
   if (last > first .and. cell(first:first) == '"' .and. cell(last:last) == '"') then
      first = first + 1_I4P
      last = last - 1_I4P
   endif
   v = to_real(cell(first:last))
   endfunction cell_value

   function to_real(token) result(v)
   !< Value of the longest number at the start of `token`, as C `strtod`: `[+-]` then decimal `D[.D][e[+-]D]` or `.D...`,
   !< or hexadecimal `0xH[.H][p[+-]D]`; NaN if there is none (empty, `?`, `NaN`, `inf`) or it is out of range.
   character(len=*), intent(in) :: token !< Cell text.
   real(R8P)                    :: v     !< Value.
   integer(I4P)                 :: n     !< Token length.
   integer(I4P)                 :: i     !< Character counter.
   integer(I4P)                 :: last  !< End of the decimal mantissa.
   integer(I4P)                 :: body  !< First character after the sign.
   logical                      :: ok    !< Conversion succeeded.

   v = ieee_value(1.0_R8P, ieee_quiet_nan)
   n = len(token, kind=I4P)
   body = 1_I4P
   if (n > 0_I4P) then
      if (token(1:1) == '+' .or. token(1:1) == '-') body = 2_I4P
   endif
   if (body + 2_I4P <= n) then
      if (token(body:body) == '0' .and. (token(body + 1_I4P:body + 1_I4P) == 'x' .or. &
                                         token(body + 1_I4P:body + 1_I4P) == 'X')) then
         if (hexadecimal(token(body + 2_I4P:), v)) then
            if (token(1:1) == '-') v = -v
            return
         endif
      endif
   endif
   ! decimal mantissa: digits, a point, digits; at least one digit
   i = skip_digits(token, body)
   if (i <= n) then
      if (token(i:i) == '.') i = skip_digits(token, i + 1_I4P)
   endif
   last = i - 1_I4P
   if (verify(token(body:last), '.') == 0) return
   ! exponent, only if digits follow it
   if (i < n) then
      if (token(i:i) == 'e' .or. token(i:i) == 'E') then
         i = i + 1_I4P
         if (token(i:i) == '+' .or. token(i:i) == '-') i = i + 1_I4P
         if (i <= n) then
            if (scan(token(i:i), '0123456789') > 0) last = skip_digits(token, i) - 1_I4P
         endif
      endif
   endif
   call real_from_decimal(token(1:last), v, ok)
   if (.not. ok) v = ieee_value(1.0_R8P, ieee_quiet_nan)
   contains
      pure function skip_digits(text, from) result(next)
      !< First position from `from` on that is not a decimal digit.
      character(len=*), intent(in) :: text !< Text.
      integer(I4P),     intent(in) :: from !< Start.
      integer(I4P)                 :: next !< Position after the digits.

      next = from
      do while (next <= len(text))
         if (scan(text(next:next), '0123456789') == 0) exit
         next = next + 1_I4P
      enddo
      endfunction skip_digits
   endfunction to_real

   function hexadecimal(text, v) result(found)
   !< Value of the hexadecimal number at the start of `text` (after `0x`): digits, an optional point and digits, an
   !< optional binary exponent `p[+-]D`; false if no digit follows the `0x`. Out of range is NaN, never an IEEE overflow.
   character(len=*), intent(in)  :: text   !< Text after `0x`.
   real(R8P),        intent(out) :: v      !< Value.
   logical                       :: found  !< A hexadecimal digit was found.
   character(len=*), parameter   :: HEX = '0123456789abcdef'
   integer(I4P)                  :: i      !< Character counter.
   integer(I4P)                  :: d      !< Digit value.
   integer(I4P)                  :: shift  !< Binary exponent of the fraction digits.
   integer(I4P)                  :: p      !< Binary exponent.
   integer(I4P)                  :: ndig   !< Integer digits.
   integer(I4P)                  :: sgn    !< Exponent sign.
   logical                       :: point  !< After the point.

   v = 0.0_R8P
   found = .false.
   shift = 0_I4P
   ndig = 0_I4P
   point = .false.
   i = 1_I4P
   do while (i <= len(text))
      if (text(i:i) == '.' .and. .not. point) then
         point = .true.
      else
         d = index(HEX, lower(text(i:i)), kind=I4P) - 1_I4P
         if (d < 0_I4P) exit
         found = .true.
         ! digits beyond the precision cannot change the value: the integer ones only scale it
         if (v < 2.0_R8P**60) then
            v = 16.0_R8P * v + real(d, R8P)
            if (point) shift = shift - 4_I4P
         elseif (.not. point) then
            ndig = ndig + 1_I4P
         endif
      endif
      i = i + 1_I4P
   enddo
   if (.not. found) return
   shift = shift + 4_I4P * ndig
   ! binary exponent, only if digits follow it
   if (i < len(text)) then
      if (lower(text(i:i)) == 'p') then
         sgn = 1_I4P
         i = i + 1_I4P
         if (text(i:i) == '+' .or. text(i:i) == '-') then
            if (text(i:i) == '-') sgn = -1_I4P
            i = i + 1_I4P
         endif
         p = 0_I4P
         do while (i <= len(text))
            if (scan(text(i:i), '0123456789') == 0) exit
            ! clamped: far beyond any real exponent either way
            p = min(100000_I4P, 10_I4P * p + iachar(text(i:i)) - iachar('0'))
            i = i + 1_I4P
         enddo
         shift = shift + sgn * p
      endif
   endif
   if (v == 0.0_R8P) return
   if (exponent(v) + shift > maxexponent(v)) then
      v = ieee_value(1.0_R8P, ieee_quiet_nan)
   elseif (exponent(v) + shift < minexponent(v) - digits(v)) then
      v = 0.0_R8P
   else
      v = scale(v, shift)
   endif
   contains
      pure function lower(c) result(l)
      !< Lower case of the letter `c`.
      character(len=1), intent(in) :: c !< Character.
      character(len=1)             :: l !< Lower case.

      l = c
      if (c >= 'A' .and. c <= 'Z') l = achar(iachar(c) + 32)
      endfunction lower
   endfunction hexadecimal
endmodule foresight_datafile
