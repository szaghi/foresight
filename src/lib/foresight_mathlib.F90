!< foresight_mathlib, gnuplot 6.0's real special functions by name: the table of names and arities the expression
!< compiler reads, and the dispatch of a call to the ports of gnuplot's algorithms (foresight_bessel, foresight_gammafun,
!< foresight_specfun) and to the elementary ones (round, cbrt, asinh, acosh, atanh).
module foresight_mathlib
!< foresight_mathlib, gnuplot 6.0's real special functions by name: the table of names and arities the expression
!< compiler reads, and the dispatch of a call to the ports of gnuplot's algorithms (foresight_bessel, foresight_gammafun,
!< foresight_specfun) and to the elementary ones (round, cbrt, asinh, acosh, atanh).
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite
use, intrinsic :: iso_c_binding, only : c_double
use foresight_bessel, only : gp_besi0, gp_besi1, gp_besin, gp_besj0, gp_besj1, gp_besjn, gp_besy0, gp_besy1, gp_besyn
use foresight_gammafun, only : gp_erf, gp_erfc, gp_gamma, gp_ibeta, gp_igamma, gp_inverf, gp_invibeta, gp_invigamma, &
                               gp_invnorm, gp_lgamma, gp_norm, gp_uigamma
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
character(len=*), parameter :: MATH_FUNCTIONS(35) = [character(len=12) :: &
   'round', 'cbrt', 'asinh', 'acosh', 'atanh', &
   'erf', 'erfc', 'gamma', 'lgamma', 'norm', 'invnorm', 'inverf', 'igamma', 'uigamma', 'invigamma', 'ibeta', 'invibeta', &
   'besj0', 'besj1', 'besy0', 'besy1', 'besjn', 'besyn', 'besi0', 'besi1', 'besin', &
   'lambertw', 'airy', 'expint', 'EllipticK', 'EllipticE', 'EllipticPi', 'voigt', 'zeta', 'SynchrotronF'] !< Names.
integer(I4P), parameter :: MATH_ARGS(35) = [1_I4P, 1_I4P, 1_I4P, 1_I4P, 1_I4P, &
   1_I4P, 1_I4P, 1_I4P, 1_I4P, 1_I4P, 1_I4P, 1_I4P, 2_I4P, 2_I4P, 2_I4P, 3_I4P, 3_I4P, &
   1_I4P, 1_I4P, 1_I4P, 1_I4P, 2_I4P, 2_I4P, 1_I4P, 1_I4P, 2_I4P, &
   1_I4P, 1_I4P, 2_I4P, 1_I4P, 1_I4P, 2_I4P, 2_I4P, 1_I4P, 1_I4P] !< Arguments.

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
endmodule foresight_mathlib
