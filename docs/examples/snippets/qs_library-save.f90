call fig%save('qs_library.html')                 ! the interactive page: zoom, pan, hover
call fig%save('qs_library.svg')                  ! the same drawing, a static image
call fig%save('qs_library.pdf', info=meta)       ! a PDF, its fonts embedded
call fig%save('qs_library.txt')                  ! text, as gnuplot's dumb terminal
print '(A,F0.1,A,F0.1,A)', 'wrote '//meta%file//', ', meta%width_cm, ' x ', meta%height_cm, ' cm'
print '(A)', 'its alternative text: '//meta%alt
