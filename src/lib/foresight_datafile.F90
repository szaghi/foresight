!< foresight_datafile, gnuplot-style text data files.
module foresight_datafile
!< foresight_datafile, gnuplot-style text data files.
!<
!< Format, as gnuplot's default: whitespace separated numeric columns; `#` starts a comment; one blank line ends a
!< block (plotted lines are broken there), two blank lines end a dataset (selected by `index`, 0-based); cells that
!< are `?`, `NaN` or not numbers are missing values (gaps). Pseudo-column 0 is the point number within the dataset.
!<
!< Values are stored flattened, rows by offsets, with capacities doubled on growth: a large monitoring log costs one
!< real per value plus three integers per row.
use, intrinsic :: ieee_arithmetic, only : ieee_quiet_nan, ieee_value
use, intrinsic :: iso_fortran_env, only : iostat_end, iostat_eor
use penf, only : I4P, R8P

implicit none
private
public :: datafile_object

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
endtype datafile_object

contains
   subroutine load(self, file, iostat, iomsg)
   !< Read `file`, replacing the current content.
   class(datafile_object),        intent(inout) :: self    !< Data.
   character(len=*),              intent(in)    :: file    !< File name.
   integer(I4P),                  intent(out)   :: iostat  !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg   !< Error message.
   character(len=:), allocatable                :: line    !< Current line.
   character(len=256)                           :: message !< I/O message.
   integer(I4P)                                 :: unit    !< File unit.
   integer(I4P)                                 :: blanks  !< Blank lines since the last data row.
   integer(I4P)                                 :: dset    !< Current dataset.
   integer(I4P)                                 :: blk     !< Current block.
   integer(I4P)                                 :: i       !< Character counter.
   integer(I4P)                                 :: j       !< Token end.
   integer(I4P)                                 :: n       !< Code part length.
   logical                                      :: eof     !< End of file reached.

   self%file = file
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
         do while (i <= n)
            if (line(i:i) == ' ' .or. line(i:i) == achar(9)) then
               i = i + 1_I4P
               cycle
            endif
            j = i
            do while (j < n)
               if (line(j + 1_I4P:j + 1_I4P) == ' ' .or. line(j + 1_I4P:j + 1_I4P) == achar(9)) exit
               j = j + 1_I4P
            enddo
            call add_value(to_real(line(i:j)))
            i = j + 1_I4P
         enddo
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
   !<
   !< A NaN point is inserted where a block or dataset changes, so that lines are broken as in gnuplot. Missing cells
   !< and rows too short for a column give NaN values (gaps).
   class(datafile_object), intent(in)  :: self  !< Data.
   integer(I4P),           intent(in)  :: ux    !< Abscissa column, 0 for the point number.
   integer(I4P),           intent(in)  :: uy    !< Ordinate column, 0 for the point number.
   integer(I4P),           intent(in)  :: index !< Dataset, 0-based; negative for all.
   integer(I4P),           intent(in)  :: every !< Point stride within each block.
   real(R8P), allocatable, intent(out) :: x(:)  !< Abscissae.
   real(R8P), allocatable, intent(out) :: y(:)  !< Ordinates.
   integer(I4P)                        :: n     !< Number of points.

   n = count_points()
   allocate(x(n), y(n))
   call store_points
   contains
      pure function count_points() result(total)
      !< Number of points, breaks included.
      integer(I4P) :: total    !< Points.
      integer(I4P) :: r        !< Row counter.
      integer(I4P) :: in_set   !< Point number within the dataset.
      integer(I4P) :: in_block !< Point number within the block.
      integer(I4P) :: last_blk !< Block of the last selected point.

      total = 0_I4P
      in_set = -1_I4P
      in_block = -1_I4P
      last_blk = -1_I4P
      do r = 1_I4P, self%nrows
         call advance(r, in_set, in_block)
         if (.not. selected(r, in_block)) cycle
         if (last_blk >= 0_I4P .and. self%block(r) /= last_blk) total = total + 1_I4P
         last_blk = self%block(r)
         total = total + 1_I4P
      enddo
      endfunction count_points

      subroutine store_points
      !< Store the points, NaN breaks between blocks.
      integer(I4P) :: r        !< Row counter.
      integer(I4P) :: k        !< Point counter.
      integer(I4P) :: in_set   !< Point number within the dataset.
      integer(I4P) :: in_block !< Point number within the block.
      integer(I4P) :: last_blk !< Block of the last selected point.

      k = 0_I4P
      in_set = -1_I4P
      in_block = -1_I4P
      last_blk = -1_I4P
      do r = 1_I4P, self%nrows
         call advance(r, in_set, in_block)
         if (.not. selected(r, in_block)) cycle
         if (last_blk >= 0_I4P .and. self%block(r) /= last_blk) then
            k = k + 1_I4P
            x(k) = ieee_value(1.0_R8P, ieee_quiet_nan)
            y(k) = ieee_value(1.0_R8P, ieee_quiet_nan)
         endif
         last_blk = self%block(r)
         k = k + 1_I4P
         x(k) = cell(r, ux, in_set)
         y(k) = cell(r, uy, in_set)
      enddo
      endsubroutine store_points

      pure subroutine advance(r, in_set, in_block)
      !< Update the point numbers within dataset and block for row `r`.
      integer(I4P), intent(in)    :: r        !< Row.
      integer(I4P), intent(inout) :: in_set   !< Point number within the dataset.
      integer(I4P), intent(inout) :: in_block !< Point number within the block.

      if (r > 1_I4P) then
         if (self%dataset(r) /= self%dataset(r - 1_I4P)) in_set = -1_I4P
         if (self%block(r) /= self%block(r - 1_I4P)) in_block = -1_I4P
      endif
      in_set = in_set + 1_I4P
      in_block = in_block + 1_I4P
      endsubroutine advance

      pure function selected(r, in_block) result(yes)
      !< Whether row `r` belongs to the selected dataset and stride.
      integer(I4P), intent(in) :: r        !< Row.
      integer(I4P), intent(in) :: in_block !< Point number within the block.
      logical                  :: yes      !< Row selected.

      yes = modulo(in_block, max(1_I4P, every)) == 0_I4P
      if (index >= 0_I4P) yes = yes .and. self%dataset(r) == index
      endfunction selected

      pure function cell(r, c, in_set) result(v)
      !< Value of column `c` of row `r`; column 0 is the point number within the dataset.
      integer(I4P), intent(in) :: r      !< Row.
      integer(I4P), intent(in) :: c      !< Column.
      integer(I4P), intent(in) :: in_set !< Point number within the dataset.
      real(R8P)                :: v      !< Value.

      if (c == 0_I4P) then
         v = real(in_set, R8P)
      elseif (c <= self%first(r + 1_I4P) - self%first(r)) then
         v = self%values(self%first(r) + c - 1_I4P)
      else
         v = ieee_value(1.0_R8P, ieee_quiet_nan)
      endif
      endfunction cell
   endsubroutine columns

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

   function to_real(token) result(v)
   !< Number in `token`; NaN if missing (`?`) or not a number.
   character(len=*), intent(in) :: token  !< Cell text.
   real(R8P)                    :: v      !< Value.
   integer(I4P)                 :: iostat !< Conversion status.

   v = ieee_value(1.0_R8P, ieee_quiet_nan)
   if (verify(token, '0123456789+-.eEdD') > 0) return
   read(token, *, iostat=iostat) v
   if (iostat /= 0_I4P) v = ieee_value(1.0_R8P, ieee_quiet_nan)
   endfunction to_real
endmodule foresight_datafile
