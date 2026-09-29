!< foresight_datafile test: gnuplot data file layout (comments, missing cells, blocks, datasets) and column extraction.
program foresight_datafile_test
!< foresight_datafile test: gnuplot data file layout (comments, missing cells, blocks, datasets) and column extraction.
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan
use, intrinsic :: iso_fortran_env, only : output_unit
use foresight_datafile, only : datafile_object
use penf, only : I4P, R8P

implicit none
character(len=*), parameter   :: file = 'foresight_datafile_test.dat' !< Test data file.
type(datafile_object)         :: data                                 !< Data.
real(R8P), allocatable        :: x(:)                                 !< Abscissae.
real(R8P), allocatable        :: y(:)                                 !< Ordinates.
character(len=:), allocatable :: iomsg                                !< Error message.
integer(I4P)                  :: iostat                               !< Status.
integer(I4P)                  :: ux                                   !< Default abscissa column.
integer(I4P)                  :: uy                                   !< Default ordinate column.
integer(I4P)                  :: unit                                 !< File unit.
logical                       :: test_passed(9)                       !< Per-check outcome.

! dataset 0: blocks {0,1,2} and {3,4}; dataset 1: {0,1}; a comment line and a missing cell
open(newunit=unit, file=file, action='write', status='replace')
write(unit, '(A)') '# t  a  b'
write(unit, '(A)') '0 1 10'
write(unit, '(A)') '# comment inside a block'
write(unit, '(A)') '1 2 ?'
write(unit, '(A)') '2 3 30   # trailing comment'
write(unit, '(A)') ''
write(unit, '(A)') '3 4 40'
write(unit, '(A)') '4 5 50'
write(unit, '(A)') ''
write(unit, '(A)') ''
write(unit, '(A)') '0 7 70'
write(unit, '(A)') '1 8'
close(unit)

call data%load(file, iostat, iomsg)
test_passed(1) = iostat == 0_I4P .and. data%nrows == 7_I4P

call data%default_using(ux, uy)
test_passed(2) = ux == 1_I4P .and. uy == 2_I4P

! all datasets: NaN breaks between blocks and datasets
call data%columns(1_I4P, 2_I4P, -1_I4P, 1_I4P, x, y)
test_passed(3) = size(x) == 9 .and. ieee_is_nan(x(4)) .and. ieee_is_nan(y(7)) .and. y(9) == 8.0_R8P

! missing cell and short row are NaN
call data%columns(1_I4P, 3_I4P, -1_I4P, 1_I4P, x, y)
test_passed(4) = ieee_is_nan(y(2)) .and. y(3) == 30.0_R8P .and. ieee_is_nan(y(9))

! index selects a dataset; pseudo-column 0 counts points within it
call data%columns(0_I4P, 2_I4P, 1_I4P, 1_I4P, x, y)
test_passed(5) = size(x) == 2 .and. x(1) == 0.0_R8P .and. x(2) == 1.0_R8P .and. y(1) == 7.0_R8P

! pseudo-column 0 runs across blocks of the same dataset
call data%columns(0_I4P, 2_I4P, 0_I4P, 1_I4P, x, y)
test_passed(6) = size(x) == 6 .and. x(5) == 3.0_R8P

! every 2 strides within each block
call data%columns(1_I4P, 2_I4P, -1_I4P, 2_I4P, x, y)
test_passed(7) = size(x) == 6 .and. y(1) == 1.0_R8P .and. y(2) == 3.0_R8P .and. y(4) == 4.0_R8P .and. y(6) == 7.0_R8P

! missing file is reported, not fatal
call data%load('foresight_no_such_file.dat', iostat, iomsg)
test_passed(8) = iostat /= 0_I4P .and. index(iomsg, 'cannot open') > 0

! single-column data defaults to 0:1
open(newunit=unit, file=file, action='write', status='replace')
write(unit, '(A)') '5'
write(unit, '(A)') '6'
close(unit)
call data%load(file, iostat, iomsg)
call data%default_using(ux, uy)
test_passed(9) = ux == 0_I4P .and. uy == 1_I4P
open(newunit=unit, file=file)
close(unit, status='delete')

write(output_unit, '(A,9L2)') 'foresight_datafile checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1
endprogram foresight_datafile_test
