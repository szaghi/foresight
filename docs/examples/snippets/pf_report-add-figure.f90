subroutine add_figure(info)
!< The figure in the page: an image with its alternative text, its caption numbered below it.
type(figure_info), intent(in) :: info   !< The figure's information.
character(len=:), allocatable :: name   !< The file, relative to the page.
character(len=12)             :: number !< Figure number.

figures = figures + 1_I4P
write(number, '(I0)') figures
name = info%file(index(info%file, '/', back=.true.) + 1:)
write(md, '(A)') '!['//info%alt//']('//name//')', '', &
                 '*Figure '//trim(number)//'. '//info%caption//'*', ''
endsubroutine add_figure
