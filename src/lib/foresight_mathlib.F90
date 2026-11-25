!< foresight_mathlib, gnuplot 6.0's real special functions by name: the table of names and arities the expression
!< compiler reads, and the dispatch of a call to the ports of gnuplot's algorithms (foresight_bessel, foresight_gammafun,
!< foresight_specfun), to the elementary ones (round, cbrt, asinh, acosh, atanh) and to the time ones (tm_sec ... tm_yday,
!< tm_week, weekdate_iso, weekdate_cdc).
module foresight_mathlib
!< foresight_mathlib, gnuplot 6.0's real special functions by name: the table of names and arities the expression
!< compiler reads, and the dispatch of a call to the ports of gnuplot's algorithms (foresight_bessel, foresight_gammafun,
!< foresight_specfun) and to the elementary ones (round, cbrt, asinh, acosh, atanh).
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite
use, intrinsic :: iso_c_binding, only : c_double
use foresight_bessel, only : gp_besi0, gp_besi1, gp_besin, gp_besj0, gp_besj1, gp_besjn, gp_besy0, gp_besy1, gp_besyn
use foresight_gammafun, only : gp_erf, gp_erfc, gp_gamma, gp_ibeta, gp_igamma, gp_inverf, gp_invibeta, gp_invigamma, &
                               gp_invnorm, gp_lgamma, gp_norm, gp_uigamma
use foresight_time, only : DAY_SEC, WEEK_SEC, civil_time, time_parts
use foresight_specfun, only : gp_airy, gp_EllipticE, gp_EllipticK, gp_EllipticPi, gp_expint, gp_lambertw, gp_SynchrotronF, &
                              gp_voigt, gp_zeta
use penf, only : I4P, I8P, R8P

implicit none
private
public :: MATH_FUNCTIONS
public :: MATH_ARGS
public :: math_function
public :: math_order

!< gnuplot's names (case matters: EllipticK), their arguments, and which take an integer order first
character(len=*), parameter :: MATH_FUNCTIONS(47) = [character(len=12) :: &
   'round', 'cbrt', 'asinh', 'acosh', 'atanh', &
   'erf', 'erfc', 'gamma', 'lgamma', 'norm', 'invnorm', 'inverf', 'igamma', 'uigamma', 'invigamma', 'ibeta', 'invibeta', &
   'besj0', 'besj1', 'besy0', 'besy1', 'besjn', 'besyn', 'besi0', 'besi1', 'besin', &
   'lambertw', 'airy', 'expint', 'EllipticK', 'EllipticE', 'EllipticPi', 'voigt', 'zeta', 'SynchrotronF', &
   'tm_sec', 'tm_min', 'tm_hour', 'tm_mday', 'tm_mon', 'tm_year', 'tm_wday', 'tm_yday', 'tm_week', &
   'weekdate_iso', 'weekdate_cdc', 'hsv2rgb'] !< Names (weekdate_*: the day, the third argument, 1 when omitted).
integer(I4P), parameter :: MATH_ARGS(47) = [1_I4P, 1_I4P, 1_I4P, 1_I4P, 1_I4P, &
   1_I4P, 1_I4P, 1_I4P, 1_I4P, 1_I4P, 1_I4P, 1_I4P, 2_I4P, 2_I4P, 2_I4P, 3_I4P, 3_I4P, &
   1_I4P, 1_I4P, 1_I4P, 1_I4P, 2_I4P, 2_I4P, 1_I4P, 1_I4P, 2_I4P, &
   1_I4P, 1_I4P, 2_I4P, 1_I4P, 1_I4P, 2_I4P, 2_I4P, 1_I4P, 1_I4P, &
   1_I4P, 1_I4P, 1_I4P, 1_I4P, 1_I4P, 1_I4P, 1_I4P, 1_I4P, 2_I4P, 3_I4P, 3_I4P, 3_I4P] !< Arguments.

interface
   pure function c_cbrt(x) bind(C, name='cbrt') result(y)
   !< libm's cbrt, gnuplot's (Fortran has no cube root intrinsic).
   import :: c_double
   real(c_double), value, intent(in) :: x !< Value.
   real(c_double)                    :: y !< Cube root.
   endfunction c_cbrt
endinterface

contains
   pure function math_order(f) result(message)
   !< The error of gnuplot when the first argument of function `f` is not an integer, empty if `f` takes none.
   integer(I4P), intent(in)      :: f       !< Function index in MATH_FUNCTIONS.
   character(len=:), allocatable :: message !< gnuplot's message.

   select case (trim(MATH_FUNCTIONS(f)))
   case ('besjn', 'besyn')
      message = 'For complex Bessel functions use BesselI, BesselJ, BesselY, BesselK'
   case ('besin')
      message = 'improper argument to besin(int,real)'
   case ('expint')
      message = 'order of expint must be nonnegative integer'
   case default
      message = ''
   endselect
   endfunction math_order

   pure subroutine math_function(f, x, n, r, is_int, ok)
   !< Function `f` (index in MATH_FUNCTIONS) of the arguments `x` (`n` the first one as an integer, for the orders):
   !< `r` the value, an integer if `is_int` (round); `ok` false for gnuplot's undefined value, and for a NaN or an
   !< infinity (foresight's values are finite).
   integer(I4P), intent(in)  :: f      !< Function index.
   real(R8P),    intent(in)  :: x(:)   !< Arguments.
   integer(I8P), intent(in)  :: n      !< First argument as an integer (orders).
   real(R8P),    intent(out) :: r      !< Value.
   logical,      intent(out) :: is_int !< Integer value (`r` holds it).
   logical,      intent(out) :: ok     !< Defined.
   integer(I4P)              :: status !< gnuplot status: 0 value, 1 undefined.
   real(R8P)                 :: a      !< An intermediate.

   r = 0.0_R8P
   is_int = .false.
   status = 0_I4P
   select case (trim(MATH_FUNCTIONS(f)))
   case ('round')
      ! C's round, half away from zero, an integer; beyond 64 bits gnuplot's NaN
      if (abs(x(1)) < 9.2e18_R8P) then
         r = anint(x(1))
         is_int = .true.
      else
         status = 1_I4P
      endif
   case ('cbrt')
      r = real(c_cbrt(real(x(1), c_double)), R8P)
   case ('asinh')
      ! gnuplot's f_asinh on a real: log(a + sqrt(a**2 - 1)), a = sqrt(y**2 + 1) (beyond 1e150 its infinity)
      if (x(1) == 0.0_R8P) then
         r = 0.0_R8P
      elseif (abs(x(1)) < 1.0e150_R8P) then
         a = sqrt(x(1) * x(1) + 1.0_R8P)
         r = sign(log(a + sqrt(a * a - 1.0_R8P)), x(1))
      else
         status = 1_I4P
      endif
   case ('acosh')
      ! gnuplot's f_acosh on a real above 1: log(x + sqrt(x**2 - 1)); below, a complex value (undefined here)
      if (x(1) > 1.0_R8P .and. x(1) < 1.0e150_R8P) then
         r = log(x(1) + sqrt(x(1) * x(1) - 1.0_R8P))
      elseif (x(1) == 1.0_R8P) then
         r = 0.0_R8P
      else
         status = 1_I4P
      endif
   case ('atanh')
      ! gnuplot's f_atanh on a real inside (-1, 1): log((y + 1)**2 / (y - 1)**2) / 4
      if (abs(x(1)) < 1.0_R8P) then
         r = log(((x(1) + 1.0_R8P) * (x(1) + 1.0_R8P)) / ((x(1) - 1.0_R8P) * (x(1) - 1.0_R8P))) / 4.0_R8P
      else
         status = 1_I4P
      endif
   case ('erf')
      call gp_erf(x(1), r, status)
   case ('erfc')
      call gp_erfc(x(1), r, status)
   case ('gamma')
      call gp_gamma(x(1), r, status)
   case ('lgamma')
      call gp_lgamma(x(1), r, status)
   case ('norm')
      call gp_norm(x(1), r, status)
   case ('invnorm')
      call gp_invnorm(x(1), r, status)
   case ('inverf')
      call gp_inverf(x(1), r, status)
   case ('igamma')
      call gp_igamma(x(1), x(2), r, status)
   case ('uigamma')
      call gp_uigamma(x(1), x(2), r, status)
   case ('invigamma')
      call gp_invigamma(x(1), x(2), r, status)
   case ('ibeta')
      call gp_ibeta(x(1), x(2), x(3), r, status)
   case ('hsv2rgb')
      ! an integer, as gnuplot's
      r = hsv_packed(x(1:3))
      is_int = .true.
   case ('invibeta')
      call gp_invibeta(x(1), x(2), x(3), r, status)
   case ('besj0')
      call gp_besj0(x(1), r, status)
   case ('besj1')
      call gp_besj1(x(1), r, status)
   case ('besy0')
      call gp_besy0(x(1), r, status)
   case ('besy1')
      call gp_besy1(x(1), r, status)
   case ('besjn')
      call gp_besjn(n, x(2), r, status)
   case ('besyn')
      call gp_besyn(n, x(2), r, status)
   case ('besi0')
      call gp_besi0(x(1), r, status)
   case ('besi1')
      call gp_besi1(x(1), r, status)
   case ('besin')
      call gp_besin(n, x(2), r, status)
   case ('lambertw')
      call gp_lambertw(x(1), r, status)
   case ('airy')
      call gp_airy(x(1), r, status)
   case ('expint')
      call gp_expint(n, x(2), r, status)
   case ('EllipticK')
      call gp_EllipticK(x(1), r, status)
   case ('EllipticE')
      call gp_EllipticE(x(1), r, status)
   case ('EllipticPi')
      call gp_EllipticPi(x(1), x(2), r, status)
   case ('voigt')
      call gp_voigt(x(1), x(2), r, status)
   case ('zeta')
      call gp_zeta(x(1), r, status)
   case ('SynchrotronF')
      call gp_SynchrotronF(x(1), r, status)
   case ('tm_sec', 'tm_min', 'tm_hour', 'tm_mday', 'tm_mon', 'tm_year', 'tm_wday', 'tm_yday')
      call time_field(trim(MATH_FUNCTIONS(f)), x(1), r)
   case ('tm_week')
      ! gnuplot's tmweek: standard 0 ISO 8601 (weeks from Monday), 1 CDC (from Sunday)
      if (x(2) == 0.0_R8P .or. x(2) == 1.0_R8P) then
         r = real(week_of(x(1), int(x(2), I4P)), R8P)
         is_int = .true.
      else
         status = 1_I4P
      endif
   case ('weekdate_iso', 'weekdate_cdc')
      ! gnuplot's weekdate: the arguments truncated to integers, day 0 as 1, an invalid week date undefined
      if (abs(x(1)) < 1.0e9_R8P .and. aint(x(2)) >= 1.0_R8P .and. aint(x(2)) <= 53.0_R8P .and. &
          aint(x(3)) >= 0.0_R8P .and. aint(x(3)) <= 7.0_R8P) then
         r = week_date(int(x(1), I8P), int(x(2), I8P), max(int(x(3), I8P), 1_I8P), &
                       merge(1_I4P, 0_I4P, trim(MATH_FUNCTIONS(f)) == 'weekdate_cdc'))
      else
         status = 1_I4P
      endif
   case default
      status = 1_I4P
   endselect
   ok = status == 0_I4P
   if (ok) ok = ieee_is_finite(r)
   if (.not. ok) then
      r = 0.0_R8P
      is_int = .false.
   endif
   endsubroutine math_function

   pure subroutine time_field(name, t, r)
   !< gnuplot's tm_sec ... tm_yday of the time `t` [s]: the field of its broken-down UTC time, as a real (tm_mon and
   !< tm_yday from 0, tm_wday 0 on Sunday, tm_year the whole year).
   character(len=*), intent(in)  :: name     !< Function name.
   real(R8P),        intent(in)  :: t        !< Time [s].
   real(R8P),        intent(out) :: r        !< Field.
   integer(I8P)                  :: parts(8) !< Year, month, day, hour, minute, second, day of the year, weekday.
   real(R8P)                     :: fraction !< Fraction of the second.

   call time_parts(t, parts(1), parts(2), parts(3), parts(4), parts(5), parts(6), fraction, parts(7), parts(8))
   select case (name)
   case ('tm_sec')
      r = real(parts(6), R8P)
   case ('tm_min')
      r = real(parts(5), R8P)
   case ('tm_hour')
      r = real(parts(4), R8P)
   case ('tm_mday')
      r = real(parts(3), R8P)
   case ('tm_mon')
      r = real(parts(2) - 1_I8P, R8P)
   case ('tm_year')
      r = real(parts(1), R8P)
   case ('tm_wday')
      r = real(parts(8), R8P)
   case default
      r = real(parts(7) - 1_I8P, R8P)
   endselect
   endsubroutine time_field

   pure function weekday_of(year, month, day) result(wday)
   !< Weekday of a date, 0 on Sunday.
   integer(I8P), intent(in) :: year  !< Year.
   integer(I8P), intent(in) :: month !< Month, from 1.
   integer(I8P), intent(in) :: day   !< Day of the month.
   integer(I8P)             :: wday  !< Weekday.

   wday = modulo(floor(civil_time(year, month, day, 0_I8P, 0_I8P, 0.0_R8P) / DAY_SEC, I8P) + 4_I8P, 7_I8P)
   endfunction weekday_of

   pure function week_of(t, standard) result(week)
   !< gnuplot's tmweek: the week of the time `t` [s], 1 to 53; `standard` 0 ISO 8601 (weeks from Monday, week 1 the
   !< one of the first Thursday), 1 CDC/MMWR (from Sunday). The first days of January may be in week 52 or 53 of the
   !< year before, the last days of December in week 1.
   real(R8P),    intent(in) :: t        !< Time [s].
   integer(I4P), intent(in) :: standard !< 0 ISO, 1 CDC.
   integer(I8P)             :: week     !< Week.
   integer(I8P)             :: parts(8) !< Year, month, day, hour, minute, second, day of the year, weekday.
   real(R8P)                :: fraction !< Fraction of the second.
   integer(I8P)             :: wday     !< Weekday from the first day of the week.
   integer(I8P)             :: jan01    !< Weekday of 1 January of the year before, 0 on Sunday.
   integer(I8P)             :: dec31    !< Weekday of 31 December of the year before.

   call time_parts(t, parts(1), parts(2), parts(3), parts(4), parts(5), parts(6), fraction, parts(7), parts(8))
   wday = parts(8)
   if (standard == 0_I4P) wday = modulo(6_I8P + parts(8), 7_I8P)
   week = (10_I8P + parts(7) - 1_I8P - wday) / 7_I8P
   if (parts(2) == 12_I8P) then
      if ((parts(3) == 31_I8P .and. wday < 3_I8P) .or. (parts(3) == 30_I8P .and. wday < 2_I8P) .or. &
          (parts(3) == 29_I8P .and. wday < 1_I8P)) week = 1_I8P
   endif
   if (week == 0_I8P) then
      jan01 = weekday_of(parts(1) - 1_I8P, 1_I8P, 1_I8P)
      dec31 = weekday_of(parts(1) - 1_I8P, 12_I8P, 31_I8P)
      if (standard == 0_I4P) then
         week = merge(53_I8P, 52_I8P, jan01 == 4_I8P .or. dec31 == 4_I8P)
      else
         week = merge(53_I8P, 52_I8P, jan01 == 3_I8P .or. dec31 == 3_I8P)
      endif
   endif
   endfunction week_of

   pure function week_date(year, week, day, standard) result(t)
   !< gnuplot's weekdate: the time [s] of day `day` (1 the first) of week `week` of year `year`; `standard` 0 ISO 8601
   !< (weeks from Monday), 1 CDC/MMWR (from Sunday): week 1 starts on the first day of the week nearest 1 January.
   integer(I8P), intent(in) :: year     !< Week-date year.
   integer(I8P), intent(in) :: week     !< Week, 1 to 53.
   integer(I8P), intent(in) :: day      !< Day of the week, 1 to 7.
   integer(I4P), intent(in) :: standard !< 0 ISO, 1 CDC.
   real(R8P)                :: t        !< Time [s].
   integer(I8P)             :: wday     !< Weekday of 1 January from the first day of the week.

   t = civil_time(year, 1_I8P, 1_I8P, 0_I8P, 0_I8P, 0.0_R8P)
   wday = weekday_of(year, 1_I8P, 1_I8P)
   if (standard == 0_I4P) wday = modulo(6_I8P + wday, 7_I8P)
   if (wday < 4_I8P) then
      t = t - real(wday, R8P) * DAY_SEC
   else
      t = t + real(7_I8P - wday, R8P) * DAY_SEC
   endif
   t = t + real(week - 1_I8P, R8P) * WEEK_SEC + real(day - 1_I8P, R8P) * DAY_SEC
   endfunction week_date

   pure function hsv_packed(hsv) result(rgb)
   !< gnuplot's hsv2rgb(h, s, v): the components clamped to 0..1, hue 0..1 (not degrees), to red, green and blue
   !< (getcolor.c HSV_2_RGB) packed as 0xRRGGBB, each channel int(255 c).
   real(R8P), intent(in) :: hsv(3) !< Hue, saturation, value.
   real(R8P)             :: rgb    !< Packed color.
   real(R8P)             :: c(3)   !< Clamped components.
   real(R8P)             :: f(3)   !< Red, green, blue.
   real(R8P)             :: h      !< Hue sextant position.
   real(R8P)             :: d      !< Fraction in the sextant.
   real(R8P)             :: p, q, t !< Low, falling and rising channels.
   integer(I4P)          :: i      !< Sextant.

   c = min(1.0_R8P, max(0.0_R8P, hsv))
   if (c(2) == 0.0_R8P) then
      f = c(3)
   else
      h = c(1) * 6.0_R8P
      i = floor(h, I4P)
      d = h - real(i, R8P)
      p = c(3) * (1.0_R8P - c(2))
      q = c(3) * (1.0_R8P - c(2) * d)
      t = c(3) * (1.0_R8P - c(2) * (1.0_R8P - d))
      select case (modulo(i, 6_I4P))
      case (0_I4P)
         f = [c(3), t, p]
      case (1_I4P)
         f = [q, c(3), p]
      case (2_I4P)
         f = [p, c(3), t]
      case (3_I4P)
         f = [p, q, c(3)]
      case (4_I4P)
         f = [t, p, c(3)]
      case default
         f = [c(3), p, q]
      endselect
   endif
   rgb = real(int(255.0_R8P * f(1), I8P) * 65536_I8P + int(255.0_R8P * f(2), I8P) * 256_I8P + int(255.0_R8P * f(3), I8P), &
              R8P)
   endfunction hsv_packed
endmodule foresight_mathlib
