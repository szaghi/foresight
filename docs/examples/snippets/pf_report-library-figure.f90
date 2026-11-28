! a figure of the library: the drag coefficient and its error bars
call fig%init(width=600_I4P, height=340_I4P)
call fig%set_enhanced
call fig%set_title('Drag coefficient')
call fig%set_xlabel('iteration')
call fig%set_ylabel('c_d')
call fig%plot(it, cd, title='c_d', with='yerrorbars', ylow=cd - dcd, yhigh=cd + dcd)
call fig%set_caption('The drag coefficient settles at 0.30; its error bars shrink as one over the square root of '// &
                     'the iteration.')
call fig%save('report/drag.svg', info=meta)
call add_figure(meta)
