call fig%set_logscale('y')                     ! residuals span decades
call fig%set_grid                              ! grid lines at the major ticks
call fig%set_xrange(min=0.0_R8P, max=120.0_R8P)
call fig%set_xtics(step=20.0_R8P)              ! a tick every 20 iterations
call fig%set_format('%.0e', axes='y')          ! 1e-03 instead of 10^-3
