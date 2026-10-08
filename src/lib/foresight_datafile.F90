!< foresight_datafile, gnuplot-style text data files.
module foresight_datafile
!< foresight_datafile, gnuplot-style text data files.
!<
!< Format, as gnuplot's default: whitespace separated numeric columns; `#` starts a comment; one blank line ends a
!< block (plotted lines are broken there), two blank lines end a dataset (selected by `index`, 0-based); cells that
!< are `?`, `NaN`, empty or not numbers are missing values (gaps). Pseudo-column 0 numbers the selected points of each
!< dataset from 0 (with `every`, only the points it keeps are counted, as gnuplot).
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
use penf, only : I4P, R8P

implicit none
private
public :: datafile_object

character(len=1), parameter :: TAB = achar(9) !< Tab character.

type :: datafile_object
   !< Data file content.
   character(len=:), allocatable :: file              !< File name.
   real(R8P),    allocatable     :: values(:)         !< Row values, flattened.
   integer(I4P), allocatable     :: first(:)          !< Index in `values` of the first value of each row (+1 sentinel).
   integer(I4P), allocatable     :: dataset(:)        !< Dataset (0-based) of each row.
   integer(I4P), allocatable     :: block(:)          !< Block (global counter) of each row.
   integer(I4P)                  :: nrows   = 0_I4P   !< Number of data rows.
   integer(I4P)                  :: nvalues = 0_I4P   !< Number of stored values.
   contains
      procedure, pass(self) :: columns       !< Extract a (x, y) series.
      procedure, pass(self) :: default_using !< gnuplot default columns.
      procedure, pass(self) :: load          !< Read a file.
      procedure, pass(self) :: table         !< Evaluate `using` fields.
endtype datafile_object

contains
   subroutine load(self, file, iostat, iomsg, separator)
   !< Read `file`, replacing the current content; cells are separated by whitespace, or by any of the `separator`
   !< characters when given and not empty.
   class(datafile_object),        intent(inout)        :: self      !< Data.
   character(len=*),              intent(in)           :: file      !< File name.
   integer(I4P),                  intent(out)          :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg     !< Error message.
   character(len=*),              intent(in), optional :: separator !< Cell separator characters.
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

   self%file = file
   sep = ''
   if (present(separator)) sep = separator
   self%nrows = 0_I4P
   self%nvalues = 0_I4P
   if (allocated(self%values)) deallocate(self%values)
   if (allocated(self%first)) deallocate(self%first)
   if (allocated(self%dataset)) deallocate(self%dataset)
   if (allocated(self%block)) deallocate(self%block)
   allocate(self%values(1024), self%first(257), self%dataset(256), self%block(256))
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
      self%dataset(self%nrows) = dset
      self%block(self%nrows) = blk
      self%first(self%nrows + 1_I4P) = self%nvalues + 1_I4P
      endsubroutine new_row

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

   subroutine table(self, fields, index, every, values)
   !< Values of the `using` `fields` on the rows of dataset `index` (all if negative) selected by `every`:
   !< `values(point, field)`.
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

   allocate(values(count_points(), size(fields)))
   call store_points
   contains
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

      k = 0_I4P
      in_block = -1_I4P
      in_set_block = -1_I4P
      last_blk = -1_I4P
      picked = -1_I4P
      set = -1_I4P
      do r = 1_I4P, self%nrows
         call advance(r, in_block, in_set_block)
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
            values(k, f) = fields(f)%evaluate(self%values(self%first(r):self%first(r + 1_I4P) - 1_I4P), picked)
         enddo
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

   ! private procedures
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
   !< Number in `token`; NaN if empty, missing (`?`) or not a number.
   character(len=*), intent(in) :: token  !< Cell text.
   real(R8P)                    :: v      !< Value.
   integer(I4P)                 :: iostat !< Conversion status.

   v = ieee_value(1.0_R8P, ieee_quiet_nan)
   if (len(token) == 0 .or. verify(token, '0123456789+-.eEdD') > 0) return
   read(token, *, iostat=iostat) v
   if (iostat /= 0_I4P) v = ieee_value(1.0_R8P, ieee_quiet_nan)
   endfunction to_real
endmodule foresight_datafile
