!run cb_fortran_3d cb_fortran_3d
program cb_fortran_3d
!< Cookbook: the 3D views of phase 3 from Fortran: a lit surface, its contourfill slices, 3D boxes on the walls.
use foresight, only : figure_object, I4P, R8P
implicit none
type(figure_object)    :: fig
real(R8P), allocatable :: x(:), y(:), z(:,:)
integer(I4P)           :: i, j

x = [(-3.0_R8P + 0.25_R8P * real(i, R8P), i = 0, 24)]
y = x
allocate(z(size(x), size(y)))
do j = 1, size(y)
   z(:, j) = cos(sqrt(x**2 + y(j)**2)) * exp(-0.1_R8P * (x**2 + y(j)**2))
enddo
!region views
call fig%init(width=900_I4P, height=320_I4P)
call fig%set_multiplot(rows=1_I4P, cols=3_I4P)
call fig%set_colorbox(on=.false.)
call fig%set_title('lighting')
call fig%set_pm3d(lighting=.true., primary=0.5_R8P, specular=0.4_R8P)
call fig%splot(x, y, z, title='', with='pm3d')
call fig%next_panel
call fig%set_title('contourfill')
call fig%set_pm3d(lighting=.false.)
call fig%set_contourfill(levels=6_I4P)
call fig%splot(x, y, z, title='', with='contourfill')
call fig%next_panel
call fig%set_title('boxes and walls')
call fig%set_boxwidth(0.5_R8P)
call fig%set_boxdepth(depth=0.3_R8P)
call fig%set_pm3d(order='depthorder')
call fig%set_wall(which='y0')
call fig%set_wall(which='x0')
call fig%set_xyplane(relative=0.0_R8P)
call fig%set_yrange(min=0.0_R8P, max=2.0_R8P)
call fig%set_zrange(min=0.0_R8P, max=6.0_R8P)
call fig%splot([1._R8P, 2._R8P, 3._R8P, 4._R8P], [1._R8P, 1._R8P, 1._R8P, 1._R8P], [3._R8P, 5._R8P, 2._R8P, 4._R8P], &
               title='', with='boxes', fs='solid 0.8')
call fig%save('cb_fortran_3d.svg')
!endregion views
endprogram cb_fortran_3d
