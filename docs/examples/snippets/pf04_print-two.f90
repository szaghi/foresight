call fig%save('pf04.svg', info=web)
call fig%save('pf04.pdf', info=print)
write(width, '(F0.2,A)') print%width_cm, 'cm'
open(newunit=md, file='pf04_print.md', status='replace', action='write')
write(md, '(A)') '!['//print%alt//']('//print%file//'){width='//trim(width)//'}', '', '*'//print%caption//'*'
close(md)
