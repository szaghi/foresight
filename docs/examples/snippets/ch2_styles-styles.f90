call fig%plot(it, rho, title='continuity', lw=2.0_R8P)
call fig%plot(it, mom, title='momentum', dt=2_I4P)
call fig%plot(it(::8), energy(::8), title='energy', with='linespoints', pt=7_I4P, lc='#e51e10')
call fig%set_key(position='outside right top', box=.true.)
