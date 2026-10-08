program ch3_axes
!< Tutorial 3: a log axis for residuals that fall over decades; grid, range, ticks and label formats.
use foresight, only : figure_object, I4P, R8P
implicit none
type(figure_object)    :: fig
real(R8P), allocatable :: it(:), rho(:), mom(:)
integer(I4P)           :: i

it = [(real(i, R8P), i = 1, 120)]
rho = 10.0_R8P**(-0.045_R8P * it) * (1.0_R8P + 0.35_R8P * sin(it / 3.0_R8P))
mom = 10.0_R8P**(-0.040_R8P * it - 0.4_R8P) * (1.0_R8P + 0.25_R8P * cos(it / 4.0_R8P))

call fig%init(width=640_I4P, height=380_I4P)
call fig%set_title('Residual history')
call fig%set_xlabel('iteration')
call fig%set_logscale('y')                     ! residuals span decades
call fig%set_grid                              ! grid lines at the major ticks
call fig%set_xrange(min=0.0_R8P, max=120.0_R8P)
call fig%set_xtics(step=20.0_R8P)              ! a tick every 20 iterations
call fig%set_format('%.0e', axes='y')          ! 1e-03 instead of 10^-3
call fig%plot(it, rho, title='continuity')
call fig%plot(it, mom, title='momentum')
call fig%save('ch3.html')
endprogram ch3_axes
