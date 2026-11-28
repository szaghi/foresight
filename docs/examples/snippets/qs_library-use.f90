use foresight, only : figure_info, figure_object, I4P, R8P
implicit none
type(figure_object)    :: fig    ! the figure: its panels, their settings and series
type(figure_info)      :: meta   ! what save tells about a written file
real(R8P), allocatable :: t(:)   ! time [s]
real(R8P), allocatable :: u(:)   ! displacement [mm]
real(R8P), allocatable :: env(:) ! its envelope
integer(I4P)           :: i
