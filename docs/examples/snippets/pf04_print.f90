program pf04_print
!< One figure, two reports: SVG for the web page, PDF at its printed size for the PDF a converter makes (pandoc reads
!< the `{width=...}` attribute).
use foresight, only : figure_info, figure_object, I4P, R8P
implicit none
type(figure_object) :: fig    !< Figure.
type(figure_info)   :: web    !< The web figure.
type(figure_info)   :: print  !< The printed figure.
real(R8P)           :: x(200) !< Abscissae.
integer(I4P)        :: md     !< The printed report's unit.
integer(I4P)        :: k      !< Counter.
character(len=16)   :: width  !< Printed width.

x = [(0.05_R8P * k, k = 1, 200)]
call fig%init
call fig%set_theme('paper')
call fig%set_page_size(8.5_R8P, 6.0_R8P, 'cm')
call fig%set_xlabel('x')
call fig%set_ylabel('J_0(x)')
call fig%set_enhanced
call fig%plot(x, bessel_j0(x), title='J_0')
call fig%plot(x, bessel_j1(x), title='J_1', dt=2_I4P)
call fig%set_caption('Bessel functions of the first kind.')
call fig%save('pf04.svg', info=web)
call fig%save('pf04.pdf', info=print)
write(width, '(F0.2,A)') print%width_cm, 'cm'
open(newunit=md, file='pf04_print.md', status='replace', action='write')
write(md, '(A)') '!['//print%alt//']('//print%file//'){width='//trim(width)//'}', '', '*'//print%caption//'*'
close(md)
endprogram pf04_print
