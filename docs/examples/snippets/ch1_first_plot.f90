program ch1_first_plot
!< Tutorial 1: the residual of a run, plotted from the arrays that hold it.
use foresight, only : figure_object, I4P, R8P
implicit none
type(figure_object)    :: fig      ! the figure: one plot, gnuplot defaults
real(R8P), allocatable :: it(:)    ! iterations
real(R8P), allocatable :: res(:)   ! continuity residual
integer(I4P)           :: i

it = [(real(i, R8P), i = 1, 120)]
res = 10.0_R8P**(-0.045_R8P * it) * (1.0_R8P + 0.35_R8P * sin(it / 3.0_R8P))

call fig%init(width=640_I4P, height=380_I4P)
call fig%set_title('Residual history')
call fig%set_xlabel('iteration')
call fig%set_ylabel('continuity residual')
call fig%plot(it, res, title='continuity')
call fig%save('ch1.html')   ! interactive page
call fig%save('ch1.svg')    ! static image, the same drawing
endprogram ch1_first_plot
