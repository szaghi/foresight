!run pf05 pf05_latex && cat pf05_figure.tex
program pf05_latex
!< A figure for a LaTeX report: the cairolatex picture and the figure environment around it, its caption and label
!< from the figure's information.
use foresight, only : figure_info, figure_object, I4P, R8P
implicit none
type(figure_object) :: fig     !< Figure.
type(figure_info)   :: meta    !< Its information.
real(R8P)           :: re(40)  !< Reynolds numbers.
integer(I4P)        :: tex     !< The fragment's unit.
integer(I4P)        :: k       !< Counter.

re = [(10.0_R8P**(2.0_R8P + 0.1_R8P * k), k = 1, 40)]
call fig%init
call fig%set_theme('paper')
call fig%set_page_size(8.5_R8P, 6.0_R8P, 'cm')
call fig%set_logscale('xy')
call fig%set_xlabel('$Re$')
call fig%set_ylabel('$C_f$')
call fig%plot(re, 0.074_R8P * re**(-0.2_R8P), title='$0.074\,Re^{-1/5}$')
call fig%set_caption('Skin friction of a flat plate, the turbulent correlation.')
!region environment
call fig%save('pf05.svg')
call fig%save('pf05.tex', info=meta)
open(newunit=tex, file='pf05_figure.tex', status='replace', action='write')
write(tex, '(A)') '\begin{figure}', '  \centering', '  % '//meta%alt, &
                  '  \input{'//meta%file//'}', '  \caption{'//meta%caption//'}', '  \label{fig:friction}', &
                  '\end{figure}'
close(tex)
!endregion environment
endprogram pf05_latex
