program cb_gaps
!< Cookbook: NaN values are gaps, as gnuplot undefined points; one figure saved in three formats.
use, intrinsic :: ieee_arithmetic, only : ieee_quiet_nan, ieee_value
use foresight, only : figure_object, I4P, R8P
implicit none
type(figure_object)    :: fig
real(R8P), allocatable :: x(:), y(:)
integer(I4P)           :: i

x = [(0.1_R8P * real(i, R8P), i = 0, 100)]
y = sin(x)
y(30:40) = ieee_value(1.0_R8P, ieee_quiet_nan)   ! a missing stretch: the line breaks there
call fig%init(width=560_I4P, height=320_I4P)
call fig%plot(x, y, title='sin(x), samples 30-40 missing')
call fig%save('cb_gaps.svg')
call fig%save('cb_gaps.html')
call fig%save('-')                                 ! text, on the standard output
endprogram cb_gaps
