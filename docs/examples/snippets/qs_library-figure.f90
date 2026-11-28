call fig%init(width=760_I4P, height=380_I4P)    ! a new figure, 760 x 380 px
call fig%set_multiplot(rows=1_I4P, cols=2_I4P, title='A damped oscillator')
call fig%set_title('displacement')
call fig%set_xlabel('time [s]')
call fig%set_ylabel('u [mm]')
call fig%set_grid                                ! grid lines at the major ticks
call fig%set_key(position='top right', box=.true.)
