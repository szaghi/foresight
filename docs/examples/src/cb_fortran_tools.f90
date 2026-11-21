!run cb_fortran_tools cb_fortran_tools
program cb_fortran_tools
!< Cookbook: from Fortran, a fit of an array (gnuplot's fit), its statistics (gnuplot's stats), a time axis and
!< annotations, in one figure.
use foresight, only : civil_time, figure_object, fit, fit_result, I4P, I8P, R8P, stats, stats_result
implicit none
type(figure_object)    :: fig
type(fit_result)       :: r
type(stats_result)     :: s
real(R8P), allocatable :: h(:), e(:), t(:), cd(:)
real(R8P)              :: q(2) = [1.0_R8P, 1.0_R8P]
integer(I4P)           :: i

h = [(0.1_R8P / 2.0_R8P**i, i = 0, 5)]
e = 0.21_R8P * h**2 * [1.02_R8P, 0.97_R8P, 1.01_R8P, 0.99_R8P, 1.03_R8P, 0.98_R8P]
call fit(power_law, h, e, q, names=['c', 'p'], result=r)
! a run stamped every 90 s from 2024-03-01 10:00 UTC
t = [(civil_time(2024_I8P, 3_I8P, 1_I8P, 10_I8P, 0_I8P, 90.0_R8P * real(i, R8P)), i = 0, 80)]
cd = [(0.30_R8P + 0.04_R8P * exp(-real(i, R8P) / 20.0_R8P) * cos(real(i, R8P) / 4.0_R8P), i = 0, 80)]
s = stats(cd(41:))
call fig%init(width=760_I4P, height=320_I4P)
call fig%set_multiplot(rows=1_I4P, cols=2_I4P)
call fig%set_title('fit(power_law, h, e, q)')
call fig%set_logscale('xy')
call fig%set_format('%h', 'y')
call fig%set_key(position='left top')
call fig%plot(h, e, title='errors', with='points', pt=7_I4P)
call fig%plot(h, q(1) * h**q(2), title='order 2 fit', dt=2_I4P)
call fig%set_label('p = '//trim(fixed2(q(2))), 0.004_R8P, 1e-3_R8P)
call fig%next_panel()
call fig%set_title('stats(cd), a time axis, annotations')
call fig%unset_logscale()
call fig%set_format('%g', 'y')
call fig%set_time_axes('x')
call fig%set_format('%H:%M', 'x')
call fig%set_object('rectangle', [t(41), t(81)], [0.0_R8P, 1.0_R8P], system='first graph', fc='#56b4e9', &
                    fs='solid 0.2 noborder', layer='behind')
call fig%plot(t, cd, title='cd', lw=2.0_R8P)
call fig%plot(t(41:), [(s%y%mean, i = 41, 81)], title='mean of the last half', dt=2_I4P)
call fig%set_arrow(t(20), 0.335_R8P, t(41), s%y%mean, head='head', filled='filled')
call fig%set_label('settled', t(20), 0.338_R8P, justify='center')
call fig%save('cb_fortran_tools.svg')
contains
   function power_law(x, p) result(f)
   real(R8P), intent(in) :: x, p(:)
   real(R8P)             :: f
   f = p(1) * x**p(2)
   endfunction power_law

   function fixed2(v) result(text)
   real(R8P), intent(in) :: v
   character(len=8)      :: text
   write(text, '(F8.2)') v
   text = adjustl(text)
   endfunction fixed2
endprogram cb_fortran_tools
