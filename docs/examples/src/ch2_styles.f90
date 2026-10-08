!run ch2 ch2_styles
program ch2_styles
!< Tutorial 2: three residuals, told apart by color, dash type, width and point type; the key outside.
use foresight, only : figure_object, I4P, R8P
implicit none
type(figure_object)    :: fig
real(R8P), allocatable :: it(:), rho(:), mom(:), energy(:)
integer(I4P)           :: i

it = [(real(i, R8P), i = 1, 120)]
rho = 10.0_R8P**(-0.045_R8P * it) * (1.0_R8P + 0.35_R8P * sin(it / 3.0_R8P))
mom = 10.0_R8P**(-0.040_R8P * it - 0.4_R8P) * (1.0_R8P + 0.25_R8P * cos(it / 4.0_R8P))
energy = 10.0_R8P**(-0.050_R8P * it + 0.3_R8P)

call fig%init(width=640_I4P, height=380_I4P)
call fig%set_title('Residual history')
call fig%set_xlabel('iteration')
!region styles
call fig%plot(it, rho, title='continuity', lw=2.0_R8P)
call fig%plot(it, mom, title='momentum', dt=2_I4P)
call fig%plot(it(::8), energy(::8), title='energy', with='linespoints', pt=7_I4P, lc='#e51e10')
call fig%set_key(position='outside right top', box=.true.)
!endregion styles
call fig%save('ch2.html')
endprogram ch2_styles
