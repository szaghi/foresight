call fig%plot(t, u, title='u(t)', lw=2.0_R8P)                                     ! a line, 2 px wide
call fig%plot(t, env, title='envelope', dt=2_I4P, lc='gray')                      ! dashed, gray
call fig%plot(t(::20), u(::20), title='samples', with='points', pt=7_I4P, ps=0.8_R8P) ! filled circles
