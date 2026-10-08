call fig%init(width=640_I4P, height=380_I4P)
call fig%set_title('Residual history')
call fig%set_xlabel('iteration')
call fig%set_ylabel('continuity residual')
call fig%plot(it, res, title='continuity')
call fig%save('ch1.html')   ! interactive page
call fig%save('ch1.svg')    ! static image, the same drawing
