call fig%next_panel                              ! the second panel: the settings carry over, as in gnuplot
call fig%set_title('envelope, on a log axis')
call fig%set_ylabel('|u| [mm]')
call fig%set_logscale('y')
call fig%set_format('10^{%L}', axes='y')         ! powers of ten as superscripts...
call fig%set_enhanced                            ! ...read as gnuplot's enhanced text
call fig%plot(t, env, title='4 e^{-0.3 t}', lw=2.0_R8P)
