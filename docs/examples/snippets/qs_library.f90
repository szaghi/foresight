program qs_library
!< A complete program with the foresight library: data, a figure with its labels, grid and key, three series of three
!< styles, a log axis on a second panel, and the same figure saved as an interactive page, an SVG, a PDF and text.
use foresight, only : figure_info, figure_object, I4P, R8P
implicit none
type(figure_object)    :: fig    ! the figure: its panels, their settings and series
type(figure_info)      :: meta   ! what save tells about a written file
real(R8P), allocatable :: t(:)   ! time [s]
real(R8P), allocatable :: u(:)   ! displacement [mm]
real(R8P), allocatable :: env(:) ! its envelope
integer(I4P)           :: i

t = [(0.05_R8P * i, i = 0, 200)]
u = 4.0_R8P * exp(-0.3_R8P * t) * cos(2.0_R8P * t)
env = 4.0_R8P * exp(-0.3_R8P * t)

call fig%init(width=760_I4P, height=380_I4P)    ! a new figure, 760 x 380 px
call fig%set_multiplot(rows=1_I4P, cols=2_I4P, title='A damped oscillator')
call fig%set_title('displacement')
call fig%set_xlabel('time [s]')
call fig%set_ylabel('u [mm]')
call fig%set_grid                                ! grid lines at the major ticks
call fig%set_key(position='top right', box=.true.)

call fig%plot(t, u, title='u(t)', lw=2.0_R8P)                                     ! a line, 2 px wide
call fig%plot(t, env, title='envelope', dt=2_I4P, lc='gray')                      ! dashed, gray
call fig%plot(t(::20), u(::20), title='samples', with='points', pt=7_I4P, ps=0.8_R8P) ! filled circles

call fig%next_panel                              ! the second panel: the settings carry over, as in gnuplot
call fig%set_title('envelope, on a log axis')
call fig%set_ylabel('|u| [mm]')
call fig%set_logscale('y')
call fig%set_format('10^{%L}', axes='y')         ! powers of ten as superscripts...
call fig%set_enhanced                            ! ...read as gnuplot's enhanced text
call fig%plot(t, env, title='4 e^{-0.3 t}', lw=2.0_R8P)

call fig%save('qs_library.html')                 ! the interactive page: zoom, pan, hover
call fig%save('qs_library.svg')                  ! the same drawing, a static image
call fig%save('qs_library.pdf', info=meta)       ! a PDF, its fonts embedded
call fig%save('qs_library.txt')                  ! text, as gnuplot's dumb terminal
print '(A,F0.1,A,F0.1,A)', 'wrote '//meta%file//', ', meta%width_cm, ' x ', meta%height_cm, ' cm'
print '(A)', 'its alternative text: '//meta%alt
endprogram qs_library
