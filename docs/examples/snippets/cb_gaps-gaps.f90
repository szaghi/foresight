y(30:40) = ieee_value(1.0_R8P, ieee_quiet_nan)   ! a missing stretch: the line breaks there
call fig%init(width=560_I4P, height=320_I4P)
call fig%plot(x, y, title='sin(x), samples 30-40 missing')
call fig%save('cb_gaps.svg')
call fig%save('cb_gaps.html')
call fig%save('-')                                 ! text, on the standard output
