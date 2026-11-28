call fig%save('pf05.svg')
call fig%save('pf05.tex', info=meta)
open(newunit=tex, file='pf05_figure.tex', status='replace', action='write')
write(tex, '(A)') '\begin{figure}', '  \centering', '  % '//meta%alt, &
                  '  \input{'//meta%file//'}', '  \caption{'//meta%caption//'}', '  \label{fig:friction}', &
                  '\end{figure}'
close(tex)
