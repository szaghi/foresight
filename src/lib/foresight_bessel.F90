!< foresight_bessel: the real Bessel functions of gnuplot 6.0 (besj0, besj1, besy0, besy1, besjn, besyn, besi0, besi1,
!< besin), giving gnuplot's values and its undefined-value behaviour.
module foresight_bessel
!< The real Bessel functions of gnuplot 6.0.
!<
!< gnuplot 6.0 is built with HAVE_JN: besj0, besj1, besy0, besy1, besjn and besyn are the libm j0, j1, y0, y1, jn and
!< yn (standard.c `#define rj0(x) j0(x)`), reached here through the Fortran 2008 intrinsics bessel_j0/j1/y0/y1/jn, which
!< call the same libm under gfortran and nvfortran; yn is ported from glibc 2.39 (e_jn.c) because its forward
!< recurrence overflows. besi0/besi1 are the Cephes Chebyshev expansions of standard.c (ri0, ri1, chbevl); besin is
!< the Cephes/Boost iv() of specfun.c (Temme's method, uniform asymptotic expansion for orders above 50).
!<
!< gnuplot marks a result undefined (status 1) when libm sets errno to EDOM or ERANGE during the evaluation
!< (eval.c evaluate_at): exp overflow, exp underflow to zero, log(0), jn/j1 underflow to zero, y0/y1/yn poles and
!< overflow. Infinities and NaNs produced by plain arithmetic are not errors: gnuplot prints them (`inf.0`, `NaN`) and
!< these routines return them with status 0. No routine raises an IEEE invalid, divide-by-zero or overflow exception:
!< every operation that could overflow is decided before it is done, and divisions that an optimizer may hoist out
!< of their branch (nvfortran -O2 does) get a harmless stand-in operand.
!< Matching gnuplot needs IEEE subnormals: a build that flushes them to zero (nvfortran 26.9 with foresight's flags)
!< reads subnormal arguments as 0 and loses subnormal intermediates (besin(0, 709) becomes Inf there). Under
!< nvfortran the exp/log/sin/cos intrinsics are not glibc's: besin with |n| > 50 and besjn/besyn for |x| >= 2**302
!< then differ from gnuplot by tens of ulps (glibc-backed gfortran matches to the last bit).
!<
!< The order n of besjn, besyn and besin must be a gnuplot integer: when it is a real (even 2.0) gnuplot stops with
!< BESSEL_ERROR (besjn, besyn) or BESIN_ERROR (besin); the caller raises that error (status 2), the routines here take
!< the integer value. All results are real.
use, intrinsic :: ieee_arithmetic, only : ieee_value, ieee_quiet_nan, ieee_positive_inf, ieee_is_negative
use penf, only : I4P, I8P, R8P

implicit none
private
public :: gp_besj0, gp_besj1, gp_besy0, gp_besy1, gp_besjn, gp_besyn, gp_besi0, gp_besi1, gp_besin
public :: BESSEL_ERROR, BESIN_ERROR

character(*), parameter :: BESSEL_ERROR = & !< gnuplot error for a non-integer order of besjn/besyn.
                           'For complex Bessel functions use BesselI, BesselJ, BesselY, BesselK'
character(*), parameter :: BESIN_ERROR  = 'improper argument to besin(int,real)' !< gnuplot error, non-integer besin
                                                                                 !< order.

real(R8P),    parameter :: PI        = 3.14159265358979323846_R8P   !< M_PI.
real(R8P),    parameter :: INVSQRTPI = 5.64189583547756279280e-01_R8P !< 1/sqrt(pi) of glibc e_jn.c.
real(R8P),    parameter :: EULER     = 0.577215664901532860606512_R8P !< Euler_constant of specfun.c.
real(R8P),    parameter :: MACHEP    = epsilon(1._R8P)              !< DBL_EPSILON.
real(R8P),    parameter :: HUGE_R    = huge(1._R8P)                 !< DBL_MAX.
real(R8P),    parameter :: H2        = HUGE_R * 0.5_R8P             !< DBL_MAX/2: a/2 above it overflows doubled.
real(R8P),    parameter :: H4        = HUGE_R * 0.25_R8P            !< DBL_MAX/4: a/4 above it overflows times 4.
real(R8P),    parameter :: TWO_1023  = 2._R8P**1023                 !< Sums of two numbers below it cannot overflow.
real(R8P),    parameter :: CF1_TINY  = 1._R8P / sqrt(HUGE_R)        !< tiny of CF1_ik, 1/sqrt(DBL_MAX).
real(R8P),    parameter :: EXP_MAX   = 709.78271289338397_R8P       !< Largest y with a finite exp(y).
real(R8P),    parameter :: EXP_ZERO  = 745.13321910194122_R8P       !< exp(-x) is zero (ERANGE) for x >= EXP_ZERO.
real(R8P),    parameter :: X_LARGE   = 2._R8P**302                  !< glibc jn/yn use the sin/cos form from 2**302 up.
real(R8P),    parameter :: Y1_MIN    = transfer(716770142402833_I8P, 1._R8P) !< Smallest x with a finite y1(x),
                                                                    !< 3.5413150332597794e-309 (glibc -tpi/x).
integer(I8P), parameter :: TWO_30    = 2_I8P**30                    !< Orders from here up overflow glibc's int loops.
integer(I8P), parameter :: TWO_31    = 2_I8P**31                    !< INT_MIN magnitude.
integer(I8P), parameter :: TWO_32    = 2_I8P**32                    !< int wrap modulus.
integer(I4P), parameter :: MAXITER   = 500_I4P                      !< MAXITER of specfun.c.
real(R8P), parameter :: CHEB_I0_A(30) = [ & !< exp(-x) I0(x) on [0,8], Chebyshev (standard.c cheb_i0_A).
   -4.41534164647933937950E-18_R8P, 3.33079451882223809783E-17_R8P, -2.43127984654795469359E-16_R8P, &
   1.71539128555513303061E-15_R8P, -1.16853328779934516808E-14_R8P, 7.67618549860493561688E-14_R8P, &
   -4.85644678311192946090E-13_R8P, 2.95505266312963983461E-12_R8P, -1.72682629144155570723E-11_R8P, &
   9.67580903537323691224E-11_R8P, -5.18979560163526290666E-10_R8P,  2.65982372468238665035E-9_R8P, &
   -1.30002500998624804212E-8_R8P,  6.04699502254191894932E-8_R8P, -2.67079385394061173391E-7_R8P, &
    1.11738753912010371815E-6_R8P, -4.41673835845875056359E-6_R8P,  1.64484480707288970893E-5_R8P, &
   -5.75419501008210370398E-5_R8P,  1.88502885095841655729E-4_R8P, -5.76375574538582365885E-4_R8P, &
    1.63947561694133579842E-3_R8P, -4.32430999505057594430E-3_R8P,  1.05464603945949983183E-2_R8P, &
   -2.37374148058994688156E-2_R8P,  4.93052842396707084878E-2_R8P, -9.49010970480476444210E-2_R8P, &
    1.71620901522208775349E-1_R8P, -3.04682672343198398683E-1_R8P,  6.76795274409476084995E-1_R8P]
real(R8P), parameter :: CHEB_I1_A(29) = [ & !< exp(-x) I1(x)/x on [0,8], Chebyshev (standard.c cheb_i1_A).
   2.77791411276104639959E-18_R8P, -2.11142121435816608115E-17_R8P, 1.55363195773620046921E-16_R8P, &
   -1.10559694773538630805E-15_R8P, 7.60068429473540693410E-15_R8P, -5.04218550472791168711E-14_R8P, &
   3.22379336594557470981E-13_R8P, -1.98397439776494371520E-12_R8P, 1.17361862988909016308E-11_R8P, &
   -6.66348972350202774223E-11_R8P, 3.62559028155211703701E-10_R8P, -1.88724975172282928790E-9_R8P, &
    9.38153738649577178388E-9_R8P, -4.44505912879632808065E-8_R8P,  2.00329475355213526229E-7_R8P, &
   -8.56872026469545474066E-7_R8P,  3.47025130813767847674E-6_R8P, -1.32731636560394358279E-5_R8P, &
    4.78156510755005422638E-5_R8P, -1.61760815825896745588E-4_R8P,  5.12285956168575772895E-4_R8P, &
   -1.51357245063125314899E-3_R8P,  4.15642294431288815669E-3_R8P, -1.05640848946261981558E-2_R8P, &
    2.47264490306265168283E-2_R8P, -5.29459812080949914269E-2_R8P,  1.02643658689847095384E-1_R8P, &
   -1.76416518357834055153E-1_R8P,  2.52587186443633654823E-1_R8P]
real(R8P), parameter :: CHEB_I0_B(25) = [ & !< exp(-x) sqrt(x) I0(x) on [8,inf] (cheb_i0_B).
   -7.23318048787475395456E-18_R8P, -4.83050448594418207126E-18_R8P, 4.46562142029675999901E-17_R8P, &
   3.46122286769746109310E-17_R8P, -2.82762398051658348494E-16_R8P, -3.42548561967721913462E-16_R8P, &
   1.77256013305652638360E-15_R8P, 3.81168066935262242075E-15_R8P, -9.55484669882830764870E-15_R8P, &
   -4.15056934728722208663E-14_R8P, 1.54008621752140982691E-14_R8P, 3.85277838274214270114E-13_R8P, &
   7.18012445138366623367E-13_R8P, -1.79417853150680611778E-12_R8P, -1.32158118404477131188E-11_R8P, &
   -3.14991652796324136454E-11_R8P, 1.18891471078464383424E-11_R8P, 4.94060238822496958910E-10_R8P, &
    3.39623202570838634515E-9_R8P,  2.26666899049817806459E-8_R8P,  2.04891858946906374183E-7_R8P, &
    2.89137052083475648297E-6_R8P,  6.88975834691682398426E-5_R8P,  3.36911647825569408990E-3_R8P, &
    8.04490411014108831608E-1_R8P]
real(R8P), parameter :: CHEB_I1_B(25) = [ & !< exp(-x) sqrt(x) I1(x) on [8,inf] (cheb_i1_B).
   7.51729631084210481353E-18_R8P, 4.41434832307170791151E-18_R8P, -4.65030536848935832153E-17_R8P, &
   -3.20952592199342395980E-17_R8P, 2.96262899764595013876E-16_R8P, 3.30820231092092828324E-16_R8P, &
   -1.88035477551078244854E-15_R8P, -3.81440307243700780478E-15_R8P, 1.04202769841288027642E-14_R8P, &
   4.27244001671195135429E-14_R8P, -2.10154184277266431302E-14_R8P, -4.08355111109219731823E-13_R8P, &
   -7.19855177624590851209E-13_R8P, 2.03562854414708950722E-12_R8P, 1.41258074366137813316E-11_R8P, &
   3.25260358301548823856E-11_R8P, -1.89749581235054123450E-11_R8P, -5.58974346219658380687E-10_R8P, &
   -3.83538038596423702205E-9_R8P, -2.63146884688951950684E-8_R8P, -2.51223623787020892529E-7_R8P, &
   -3.88256480887769039346E-6_R8P, -1.10588938762623716291E-4_R8P, -9.76109749136146840777E-3_R8P, &
    7.78576235018280120474E-1_R8P]
real(R8P), parameter :: UFACTORS(0:30,0:10) = reshape([ & !< u_n(t) of AMS 9.3.9 (asymptotic_ufactors).
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 1._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, -0.20833333333333334_R8P, &
   0.0_R8P, 0.125_R8P, 0.0_R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0.3342013888888889_R8P, 0.0_R8P, -0.40104166666666669_R8P, 0.0_R8P, &
   0.0703125_R8P, 0.0_R8P, 0.0_R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, -1.0258125964506173_R8P, 0.0_R8P, 1.8464626736111112_R8P, &
   0.0_R8P, -0.89121093750000002_R8P, 0.0_R8P, 0.0732421875_R8P, &
   0.0_R8P, 0.0_R8P, 0.0_R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 4.6695844234262474_R8P, 0.0_R8P, &
   -11.207002616222995_R8P, 0.0_R8P, 8.78912353515625_R8P, 0.0_R8P, &
   -2.3640869140624998_R8P, 0.0_R8P, 0.112152099609375_R8P, 0.0_R8P, &
   0.0_R8P, 0.0_R8P, 0.0_R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, -28.212072558200244_R8P, &
   0.0_R8P, 84.636217674600744_R8P, 0.0_R8P, -91.818241543240035_R8P, &
   0.0_R8P, 42.534998745388457_R8P, 0.0_R8P, -7.3687943594796312_R8P, &
   0.0_R8P, 0.22710800170898438_R8P, 0.0_R8P, 0.0_R8P, &
   0.0_R8P, 0.0_R8P, 0.0_R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   212.5701300392171_R8P, 0.0_R8P, -765.25246814118157_R8P, 0.0_R8P, &
   1059.9904525279999_R8P, 0.0_R8P, -699.57962737613275_R8P, 0.0_R8P, &
   218.19051174421159_R8P, 0.0_R8P, -26.491430486951554_R8P, 0.0_R8P, &
   0.57250142097473145_R8P, 0.0_R8P, 0.0_R8P, 0.0_R8P, &
   0.0_R8P, 0.0_R8P, 0.0_R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, -1919.4576623184068_R8P, 0.0_R8P, 8061.7221817373083_R8P, &
   0.0_R8P, -13586.550006434136_R8P, 0.0_R8P, 11655.393336864536_R8P, &
   0.0_R8P, -5305.6469786134048_R8P, 0.0_R8P, 1200.9029132163525_R8P, &
   0.0_R8P, -108.09091978839464_R8P, 0.0_R8P, 1.7277275025844574_R8P, &
   0.0_R8P, 0.0_R8P, 0.0_R8P, 0.0_R8P, &
   0.0_R8P, 0.0_R8P, 0.0_R8P, &
   0._R8P, 0._R8P, 0._R8P, 0._R8P, &
   0._R8P, 0._R8P, 20204.291330966149_R8P, 0.0_R8P, &
   -96980.598388637503_R8P, 0.0_R8P, 192547.0012325315_R8P, 0.0_R8P, &
   -203400.17728041555_R8P, 0.0_R8P, 122200.46498301747_R8P, 0.0_R8P, &
   -41192.654968897557_R8P, 0.0_R8P, 7109.5143024893641_R8P, 0.0_R8P, &
   -493.915304773088_R8P, 0.0_R8P, 6.074042001273483_R8P, 0.0_R8P, &
   0.0_R8P, 0.0_R8P, 0.0_R8P, 0.0_R8P, &
   0.0_R8P, 0.0_R8P, 0.0_R8P, &
   0._R8P, 0._R8P, 0._R8P, -242919.18790055133_R8P, &
   0.0_R8P, 1311763.6146629769_R8P, 0.0_R8P, -2998015.9185381061_R8P, &
   0.0_R8P, 3763271.2976564039_R8P, 0.0_R8P, -2813563.2265865342_R8P, &
   0.0_R8P, 1268365.2733216248_R8P, 0.0_R8P, -331645.17248456361_R8P, &
   0.0_R8P, 45218.768981362737_R8P, 0.0_R8P, -2499.8304818112092_R8P, &
   0.0_R8P, 24.380529699556064_R8P, 0.0_R8P, 0.0_R8P, &
   0.0_R8P, 0.0_R8P, 0.0_R8P, 0.0_R8P, &
   0.0_R8P, 0.0_R8P, 0.0_R8P, &
   3284469.8530720375_R8P, 0.0_R8P, -19706819.11843222_R8P, 0.0_R8P, &
   50952602.492664628_R8P, 0.0_R8P, -74105148.211532637_R8P, 0.0_R8P, &
   66344512.274729028_R8P, 0.0_R8P, -37567176.660763353_R8P, 0.0_R8P, &
   13288767.166421819_R8P, 0.0_R8P, -2785618.1280864552_R8P, 0.0_R8P, &
   308186.40461266245_R8P, 0.0_R8P, -13886.089753717039_R8P, 0.0_R8P, &
   110.01714026924674_R8P, 0.0_R8P, 0.0_R8P, 0.0_R8P, &
   0.0_R8P, 0.0_R8P, 0.0_R8P, 0.0_R8P, &
   0.0_R8P, 0.0_R8P, 0.0_R8P], [31, 11])


contains
   ! public entry points

   pure subroutine gp_besj0(x, r, status)
   !< gnuplot besj0(x) (standard.c f_besj0): libm j0. Defined everywhere.
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.

   r = bessel_j0(x)
   status = 0_I4P
   endsubroutine gp_besj0

   pure subroutine gp_besj1(x, r, status)
   !< gnuplot besj1(x) (standard.c f_besj1): libm j1. Undefined when j1 underflows to zero (ERANGE), x = 4.9e-324.
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.

   r = bessel_j1(x)
   status = 0_I4P
   if (r == 0._R8P .and. x /= 0._R8P) call undefined(r, status)
   endsubroutine gp_besj1

   pure subroutine gp_besy0(x, r, status)
   !< gnuplot besy0(x) (standard.c f_besy0): libm y0 for x > 0, undefined for x <= 0.
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.

   if (.not. x > 0._R8P) then
      call undefined(r, status)
      return
   endif
   r = bessel_y0(x)
   status = 0_I4P
   endsubroutine gp_besy0

   pure subroutine gp_besy1(x, r, status)
   !< gnuplot besy1(x) (standard.c f_besy1): libm y1 for x > 0; undefined for x <= 0 and where y1 overflows (ERANGE).
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.

   if (.not. x > 0._R8P .or. x < Y1_MIN) then
      call undefined(r, status)
      return
   endif
   r = bessel_y1(x)
   status = 0_I4P
   endsubroutine gp_besy1

   pure subroutine gp_besjn(n, x, r, status)
   !< gnuplot besjn(n, x) (standard.c f_besjn): libm jn((int)n, x), as glibc 2.39 __ieee754_jn.
   !< Undefined when jn underflows to zero (ERANGE). The order is truncated to a C int as gnuplot does; for
   !< |int n| >= 2**30 glibc's int arithmetic overflows (undefined behaviour, runs of seconds, NaN): there the result
   !< is computed only for x = 0 and |x| >= 2**302 (well defined) and is undefined otherwise.
   integer(I8P), intent(in)  :: n      !< Order (gnuplot integer).
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.
   integer(I8P)              :: m      !< Order as C int.
   integer(I8P)              :: nn     !< |m|.
   real(R8P)                 :: xx     !< Argument after J(-n,x) = J(n,-x).
   real(R8P)                 :: s      !< sin(|x|).
   real(R8P)                 :: c      !< cos(|x|).
   real(R8P)                 :: temp   !< sqrt(2) cos(x - (2n+1)pi/4).
   logical                   :: sgn    !< Odd order and negative argument.

   status = 0_I4P
   m = c_int(n)
   if (m < 0_I8P) then
      nn = -m
      xx = -x
   else
      nn = m
      xx = x
   endif
   if (nn < TWO_30) then
      r = bessel_jn(int(nn, I4P), xx)
      if (r == 0._R8P .and. x /= 0._R8P) call undefined(r, status)
      return
   endif
   sgn = mod(nn, 2_I8P) == 1_I8P .and. ieee_is_negative(xx)
   if (x == 0._R8P) then
      r = 0._R8P
      if (sgn) r = -r
   elseif (abs(x) >= X_LARGE) then
      s = sin(abs(x))
      c = cos(abs(x))
      select case(mod(nn, 4_I8P))
      case(0_I8P)
         temp = c + s
      case(1_I8P)
         temp = -c + s
      case(2_I8P)
         temp = -c - s
      case default
         temp = c - s
      endselect
      r = INVSQRTPI * temp / sqrt(max(abs(x), X_LARGE))
      if (sgn) r = -r
      if (r == 0._R8P) call undefined(r, status)
   else
      call undefined(r, status)
   endif
   endsubroutine gp_besjn

   pure subroutine gp_besyn(n, x, r, status)
   !< gnuplot besyn(n, x) (standard.c f_besyn): libm yn((int)n, x), ported from glibc 2.39 __ieee754_yn so that the
   !< overflow of its forward recurrence is detected before it happens. Undefined for x <= 0 and where yn overflows
   !< (ERANGE). For 2**30 <= |int n| < 2**31 glibc's loop counter overflows: undefined unless x >= 2**302.
   integer(I8P), intent(in)  :: n      !< Order (gnuplot integer).
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.
   integer(I8P)              :: m      !< Order as C int.
   integer(I8P)              :: nn     !< |m| (2**31 for INT_MIN).
   integer(I8P)              :: i      !< Recurrence index.
   real(R8P)                 :: sgn    !< (-1)**n for negative n.
   real(R8P)                 :: a      !< Y(i-1).
   real(R8P)                 :: b      !< Y(i).
   real(R8P)                 :: t      !< 2i/x.
   real(R8P)                 :: p      !< 2i/x Y(i).
   real(R8P)                 :: s      !< sin(x).
   real(R8P)                 :: c      !< cos(x).
   real(R8P)                 :: temp   !< sqrt(2) sin(x - (2n+1)pi/4).
   logical                   :: ovf    !< Overflow.

   if (.not. x > 0._R8P) then
      call undefined(r, status)
      return
   endif
   status = 0_I4P
   m = c_int(n)
   sgn = 1._R8P
   nn = abs(m)
   if (m < 0_I8P .and. m /= -TWO_31) then
      if (mod(nn, 2_I8P) == 1_I8P) sgn = -1._R8P
   endif
   if (nn == 0_I8P) then
      r = bessel_y0(x)
      return
   endif
   if (nn == 1_I8P) then
      if (x < Y1_MIN) then
         call undefined(r, status)
         return
      endif
      r = sgn * bessel_y1(x)
      return
   endif
   if (x >= X_LARGE) then
      s = sin(x)
      c = cos(x)
      select case(mod(nn, 4_I8P))
      case(0_I8P)
         temp = s - c
      case(1_I8P)
         temp = -s - c
      case(2_I8P)
         temp = -s + c
      case default
         temp = s + c
      endselect
      b = INVSQRTPI * temp / sqrt(max(x, X_LARGE))
   elseif (nn == TWO_31) then
      ! INT_MIN stays negative after n = -n: glibc's loop `i < n` runs no step and yn returns y1(x)
      if (x < Y1_MIN) then
         call undefined(r, status)
         return
      endif
      b = bessel_y1(x)
   elseif (nn >= TWO_30) then
      call undefined(r, status)
      return
   else
      a = bessel_y0(x)
      if (x < Y1_MIN) then
         call undefined(r, status)
         return
      endif
      b = bessel_y1(x)
      do i = 1_I8P, nn - 1_I8P
         call div_safe(real(i + i, R8P), x, t, ovf)
         if (.not. ovf) call mul_safe(t, b, p, ovf)
         if (.not. ovf) then
            t = b
            call add_safe(p, -a, b, ovf)
            a = t
         endif
         if (ovf) then
            call undefined(r, status)
            return
         endif
      enddo
   endif
   r = sgn * b
   endsubroutine gp_besyn

   pure subroutine gp_besi0(x, r, status)
   !< gnuplot besi0(x) (standard.c f_besi0, ri0): Chebyshev expansions of exp(-x) I0(x). Undefined where exp(|x|)
   !< overflows (ERANGE), |x| > 709.78271289338397.
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.
   real(R8P)                 :: ax     !< |x|.

   ax = abs(x)
   if (ax > EXP_MAX) then
      call undefined(r, status)
      return
   endif
   status = 0_I4P
   if (ax <= 8._R8P) then
      r = exp(ax) * chbevl((ax / 2._R8P) - 2._R8P, CHEB_I0_A)
   else
      ! max() is a no-op here: it keeps a speculated evaluation of this branch at x = 0 from dividing by zero
      r = exp(ax) * chbevl(32._R8P / max(ax, 8._R8P) - 2._R8P, CHEB_I0_B) / sqrt(max(ax, 8._R8P))
   endif
   endsubroutine gp_besi0

   pure subroutine gp_besi1(x, r, status)
   !< gnuplot besi1(x) (standard.c f_besi1, ri1): Chebyshev expansions of exp(-x) I1(x). Undefined where exp(|x|)
   !< overflows (ERANGE), |x| > 709.78271289338397.
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.
   real(R8P)                 :: z      !< |x|, then the result.

   z = abs(x)
   if (z > EXP_MAX) then
      call undefined(r, status)
      return
   endif
   status = 0_I4P
   if (z <= 8._R8P) then
      z = chbevl((z / 2._R8P) - 2._R8P, CHEB_I1_A) * z * exp(z)
   else
      ! max() is a no-op here: it keeps a speculated evaluation of this branch at x = 0 from dividing by zero
      z = exp(z) * chbevl(32._R8P / max(z, 8._R8P) - 2._R8P, CHEB_I1_B) / sqrt(max(z, 8._R8P))
   endif
   if (x < 0._R8P) z = -z
   r = z
   endsubroutine gp_besi1

   pure subroutine gp_besin(n, x, r, status)
   !< gnuplot besin(n, x) (specfun.c f_besin, iv): modified Bessel function I_n(x) of integer order.
   !< Undefined where libm sets ERANGE: exp(-x) underflowing to zero (x >= 745.13321910194122), exp overflow in the
   !< uniform expansion (|n| > 50), log(0) for x = 4.9e-324. Returns +-Inf (gnuplot prints inf.0) where the Temme
   !< quotient overflows, NaN (gnuplot prints NaN) where its continued fraction CF1 overflows (x below ~1e-308).
   integer(I8P), intent(in)  :: n      !< Order (gnuplot integer).
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.

   call iv(real(n, R8P), x, r, status)
   endsubroutine gp_besin

   ! private helpers

   pure function c_int(n) result(m)
   !< The value of the C int that an int64 order converts to (gcc wraps modulo 2**32), as an I8P.
   integer(I8P), intent(in) :: n !< gnuplot integer.
   integer(I8P)             :: m !< (int)n.

   m = modulo(n, TWO_32)
   if (m >= TWO_31) m = m - TWO_32
   endfunction c_int

   pure subroutine undefined(r, status)
   !< Set gnuplot's undefined value.
   real(R8P),    intent(out) :: r      !< Result, 0.
   integer(I4P), intent(out) :: status !< 1.

   r = 0._R8P
   status = 1_I4P
   endsubroutine undefined

   pure function chbevl(x, array) result(r)
   !< Chebyshev series of the coefficients array at x/2 (standard.c chbevl).
   real(R8P), intent(in) :: x        !< Argument.
   real(R8P), intent(in) :: array(:) !< Coefficients, highest order first.
   real(R8P)             :: r        !< Series value.
   real(R8P)             :: b0       !< Clenshaw b(k).
   real(R8P)             :: b1       !< Clenshaw b(k+1).
   real(R8P)             :: b2       !< Clenshaw b(k+2).
   integer(I4P)          :: i        !< Coefficient index.

   b0 = array(1)
   b1 = 0._R8P
   b2 = 0._R8P
   do i = 2_I4P, size(array, kind=I4P)
      b2 = b1
      b1 = b0
      b0 = x * b1 - b2 + array(i)
   enddo
   r = 0.5_R8P * (b0 - b2)
   endfunction chbevl

   pure subroutine mul_safe(a, b, p, ovf)
   !< p = a*b exactly as IEEE rounds it, or ovf when that product overflows. The one multiplication is always done
   !< on operands that cannot overflow (scaled or zeroed beforehand), so no branch can raise even if speculated.
   real(R8P), intent(in)  :: a   !< Factor.
   real(R8P), intent(in)  :: b   !< Factor.
   real(R8P), intent(out) :: p   !< Product (0 on overflow).
   logical,   intent(out) :: ovf !< The product overflows.
   real(R8P)              :: aa  !< a, scaled or zeroed.
   real(R8P)              :: bb  !< b, scaled.
   integer(I4P)           :: e   !< Exponent of the product, within 2.
   integer(I4P)           :: sc  !< Power of two taken out.

   ovf = .false.
   aa = a
   bb = b
   sc = 0_I4P
   if (abs(a) > 1._R8P .and. abs(b) > 1._R8P) then
      e = exponent(a) + exponent(b)
      if (e >= 1026_I4P) then
         ovf = .true.
         aa = 0._R8P
      elseif (e >= 1024_I4P) then
         ! |a*b|/4 lies in [2**1020, 2**1023): scaling by 4 commutes with rounding
         sc = 2_I4P
         if (abs(a) >= abs(b)) then
            aa = scale(a, -2)
         else
            bb = scale(b, -2)
         endif
      endif
   endif
   p = aa * bb
   if (sc == 2_I4P .and. abs(p) > H4) ovf = .true.
   if (ovf) p = 0._R8P
   p = scale(p, sc)
   endsubroutine mul_safe

   pure subroutine div_safe(a, b, q, ovf)
   !< q = a/b exactly as IEEE rounds it, or ovf when that quotient overflows or b is zero. The one division is always
   !< done on operands that cannot raise (scaled or replaced beforehand), so no branch can raise even if speculated.
   real(R8P), intent(in)  :: a   !< Dividend.
   real(R8P), intent(in)  :: b   !< Divisor.
   real(R8P), intent(out) :: q   !< Quotient (0 on overflow).
   logical,   intent(out) :: ovf !< The quotient overflows (or b = 0).
   real(R8P)              :: aa  !< a, or zero.
   real(R8P)              :: bb  !< b, scaled or replaced by 1.
   integer(I4P)           :: e   !< Exponent of the quotient, within 1.
   integer(I4P)           :: sc  !< Power of two taken out.

   ovf = .false.
   aa = a
   bb = b
   sc = 0_I4P
   if (b == 0._R8P) then
      ovf = .true.
      aa = 0._R8P
      bb = 1._R8P
   elseif (abs(b) < 1._R8P .and. a /= 0._R8P) then
      e = exponent(a) - exponent(b)
      if (e >= 1025_I4P) then
         ovf = .true.
         aa = 0._R8P
         bb = 1._R8P
      elseif (e >= 1023_I4P) then
         ! |a/b|/4 lies in (2**1020, 2**1023): scaling by 4 commutes with rounding
         sc = 2_I4P
         bb = scale(b, 2)
      endif
   endif
   q = aa / bb
   if (sc == 2_I4P .and. abs(q) > H4) ovf = .true.
   if (ovf) q = 0._R8P
   q = scale(q, sc)
   endsubroutine div_safe

   pure subroutine add_safe(a, b, s, ovf)
   !< s = a+b exactly as IEEE rounds it, or ovf when that sum overflows. Operands from 2**1023 up are halved first.
   real(R8P), intent(in)  :: a   !< Addend.
   real(R8P), intent(in)  :: b   !< Addend.
   real(R8P), intent(out) :: s   !< Sum (0 on overflow).
   logical,   intent(out) :: ovf !< The sum overflows.
   real(R8P)              :: aa  !< a, halved.
   real(R8P)              :: bb  !< b, halved.
   integer(I4P)           :: sc  !< Power of two taken out.

   ovf = .false.
   aa = a
   bb = b
   sc = 0_I4P
   if (abs(a) >= TWO_1023 .or. abs(b) >= TWO_1023) then
      sc = 1_I4P
      aa = scale(a, -1)
      bb = scale(b, -1)
   endif
   s = aa + bb
   if (sc == 1_I4P .and. abs(s) > H2) ovf = .true.
   if (ovf) s = 0._R8P
   s = scale(s, sc)
   endsubroutine add_safe

   pure subroutine iv(v, x, r, status)
   !< Modified Bessel function I_v(x) (specfun.c iv), for the integral v that f_besin passes.
   real(R8P),    intent(in)  :: v      !< Order.
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.
   real(R8P)                 :: vv     !< Order after the symmetry I_-n = I_n.
   real(R8P)                 :: t      !< floor(v).
   real(R8P)                 :: sgn    !< Sign of the result.

   status = 0_I4P
   vv = v
   t = c_floor(vv)
   if (vv < 0._R8P) then
      if (t == vv) then
         vv = -vv
         t = -t
      endif
   endif
   sgn = 1._R8P
   if (x < 0._R8P) then
      if (t /= vv) then
         ! mtherr domain error (unreachable for integer orders)
         r = ieee_value(r, ieee_quiet_nan)
         return
      endif
      if (vv /= 2._R8P * c_floor(vv / 2._R8P)) sgn = -1._R8P
   endif
   if (x == 0._R8P) then
      if (vv == 0._R8P) then
         r = 1._R8P
      elseif (vv < 0._R8P) then
         ! mtherr overflow (unreachable for integer orders)
         r = ieee_value(r, ieee_positive_inf)
      else
         r = 0._R8P
      endif
      return
   endif
   if (abs(vv) > 50._R8P) then
      call ikv_asymptotic_uniform(vv, abs(x), r, status)
   else
      call ikv_temme(vv, abs(x), r, status)
   endif
   if (status == 0_I4P) r = r * sgn
   endsubroutine iv

   pure function c_floor(x) result(f)
   !< C floor() of a real, without conversion to an integer kind.
   real(R8P), intent(in) :: x !< Argument.
   real(R8P)             :: f !< Largest integral value not above x.

   f = aint(x)
   if (f > x) f = f - 1._R8P
   endfunction c_floor

   pure subroutine ikv_asymptotic_uniform(v, x, r, status)
   !< I_v(x) by the uniform asymptotic expansion for large v, AMS 9.7.7 (specfun.c ikv_asymptotic_uniform), v > 50.
   !< Undefined where exp(+-v eta) overflows or log meets 0 (libm ERANGE); the K part is not needed by besin.
   real(R8P),    intent(in)  :: v           !< Order (> 50).
   real(R8P),    intent(in)  :: x           !< Argument (> 0).
   real(R8P),    intent(out) :: r           !< Result.
   integer(I4P), intent(out) :: status      !< 0 value, 1 undefined.
   real(R8P)                 :: z           !< x/v.
   real(R8P)                 :: zz          !< z*z.
   real(R8P)                 :: t           !< 1/sqrt(1 + z*z).
   real(R8P)                 :: t2          !< t*t.
   real(R8P)                 :: g           !< Argument of the log in eta.
   real(R8P)                 :: eta         !< eta of AMS 9.3.38.
   real(R8P)                 :: ve          !< v*eta.
   real(R8P)                 :: i_prefactor !< sqrt(t/(2 pi v)) exp(v eta).
   real(R8P)                 :: i_sum       !< Series of the u_k.
   real(R8P)                 :: term        !< u_k(t)/v**k.
   real(R8P)                 :: divisor     !< v**k.
   integer(I4P)              :: k           !< Coefficient index.
   integer(I4P)              :: nn          !< Term index.
   logical                   :: ovf         !< z*z overflows.

   z = x / v
   call mul_safe(z, z, zz, ovf)
   if (ovf) then
      ! t = 0, so z/(1 + 1/t) = 0 and log(0) sets ERANGE
      call undefined(r, status)
      return
   endif
   t = 1._R8P / sqrt(1._R8P + zz)
   t2 = t * t
   g = z / (1._R8P + 1._R8P / t)
   if (g == 0._R8P) then
      call undefined(r, status)
      return
   endif
   if (g == 0._R8P) g = 1._R8P ! stand-in against speculated evaluation, never taken
   eta = sqrt(1._R8P + zz) + log(g)
   ! exp(v*eta) and exp(-v*eta) are both computed by gnuplot: either overflowing sets ERANGE
   ve = v * eta
   if (abs(ve) > EXP_MAX) then
      call undefined(r, status)
      return
   endif
   ve = min(max(ve, -EXP_MAX), EXP_MAX) ! no-op, against speculated evaluation
   status = 0_I4P
   i_prefactor = sqrt(t / (2._R8P * PI * v)) * exp(ve)
   i_sum = 1._R8P
   divisor = v
   term = 0._R8P
   do nn = 1_I4P, 10_I4P
      term = 0._R8P
      do k = 31_I4P - 1_I4P - 3_I4P * nn, 31_I4P - nn - 1_I4P, 2_I4P
         term = term * t2
         term = term + UFACTORS(k, nn)
      enddo
      do k = 1_I4P, nn - 1_I4P, 2_I4P
         term = term * t2
      enddo
      if (mod(nn, 2_I4P) == 1_I4P) term = term * t
      term = term / divisor
      i_sum = i_sum + term
      if (abs(term) < MACHEP) exit
      divisor = divisor * v
   enddo
   r = i_prefactor * i_sum
   endsubroutine ikv_asymptotic_uniform

   pure subroutine ikv_temme(v, x, r, status)
   !< I_v(x) by Temme's method (specfun.c ikv_temme, from Boost bessel_ik), integer 0 <= v <= 50 (so u = 0), x > 0,
   !< I only (no reflection: iv() has already made integer orders non-negative).
   !< K_u and K_u+1 from the Temme series (x <= 2) or CF2_ik, forward recurrence to K_v, CF1_ik for I_v+1/I_v and
   !< the Wronskian. The infinities gnuplot's arithmetic produces on the way are tracked as flags, not computed.
   real(R8P),    intent(in)  :: v       !< Order.
   real(R8P),    intent(in)  :: x       !< Argument (> 0).
   real(R8P),    intent(out) :: r       !< Result.
   integer(I4P), intent(out) :: status  !< 0 value, 1 undefined.
   real(R8P)                 :: u       !< v - n.
   real(R8P)                 :: w       !< Wronskian 1/x.
   real(R8P)                 :: ku      !< K_u.
   real(R8P)                 :: ku1     !< K_u+1.
   real(R8P)                 :: prev    !< K_k-1.
   real(R8P)                 :: current !< K_k.
   real(R8P)                 :: next    !< K_k+1.
   real(R8P)                 :: fv      !< I_v+1/I_v.
   real(R8P)                 :: p       !< Product, then K_v fv.
   real(R8P)                 :: q       !< Quotient.
   real(R8P)                 :: den     !< K_v fv + K_v+1.
   integer(I8P)              :: n       !< Integer part of v.
   integer(I8P)              :: k       !< Recurrence index.
   logical                   :: w_inf   !< 1/x overflows.
   logical                   :: cur_inf !< K_k is +Inf.
   logical                   :: prv_inf !< K_k-1 is +Inf.
   logical                   :: den_inf !< The denominator is +Inf.
   logical                   :: fv_nan  !< CF1_ik produced NaN.
   logical                   :: ovf     !< Overflow of one operation.

   status = 0_I4P
   n = int(c_floor(v + 0.5_R8P), I8P)
   u = v - real(n, R8P)
   call div_safe(1._R8P, x, w, w_inf)
   cur_inf = .false.
   den = 1._R8P
   if (x <= 2._R8P) then
      if (x / 2._R8P == 0._R8P) then
         ! log(x/2) = log(0) sets ERANGE
         call undefined(r, status)
         return
      endif
      call temme_ik_series(x, ku, ku1, cur_inf)
   else
      if (x >= EXP_ZERO) then
         ! exp(-x) underflows to zero and sets ERANGE
         call undefined(r, status)
         return
      endif
      call cf2_ik(u, x, ku, ku1)
   endif
   prev = ku
   current = ku1
   prv_inf = .false.
   do k = 1_I8P, n
      ovf = cur_inf
      next = 0._R8P
      if (.not. ovf) call mul_safe(2._R8P * (u + real(k, R8P)), current, p, ovf)
      if (.not. ovf) call div_safe(p, x, q, ovf)
      if (.not. ovf .and. .not. prv_inf) call add_safe(q, prev, next, ovf)
      if (prv_inf) ovf = .true.
      prev = current
      prv_inf = cur_inf
      current = next
      cur_inf = ovf
   enddo
   ! gnuplot's iv_asymptotic branch needs ((4v**2+10)/(8x))**4/24 < 10 eps with x > 100, i.e. x > 2604 at v = 0:
   ! there exp(-x) in CF2_ik has already set ERANGE, so it never yields a defined value and is not ported
   call cf1_ik(v, x, fv, fv_nan)
   if (fv_nan .or. (w_inf .and. (prv_inf .or. cur_inf))) then
      r = ieee_value(r, ieee_quiet_nan)
      return
   endif
   if (prv_inf .or. cur_inf) then
      den_inf = .true.
   else
      call mul_safe(prev, fv, p, den_inf)
      if (.not. den_inf) call add_safe(p, current, den, den_inf)
   endif
   if (den_inf) then
      r = 0._R8P
   elseif (w_inf .or. den == 0._R8P) then
      r = ieee_value(r, ieee_positive_inf)
   else
      call div_safe(w, den, r, ovf)
      if (ovf) r = ieee_value(r, ieee_positive_inf)
   endif
   endsubroutine ikv_temme

   pure subroutine temme_ik_series(x, k, k1, k1_inf)
   !< K_0(x) and K_1(x) by Temme's series, x <= 2 (specfun.c temme_ik_series at v = 0, the only order u = v - n
   !< that integer orders give). At v = 0 gnuplot's set-up reduces exactly (tgamma(1) = exp(0) = cosh(0) = 1, the
   !< ternaries take their limits) to gp = gm = 0, c = d = 1, gamma1 = -Euler, gamma2 = 1, p = q = 1/2 and
   !< f = -Euler - log(x/2); the v-dependent quotients are left out because optimizing compilers evaluate them
   !< speculatively (0/0) even on the branch gnuplot does not take.
   real(R8P), intent(in)  :: x      !< Argument, 0 < x <= 2 with x/2 > 0.
   real(R8P), intent(out) :: k      !< K_0.
   real(R8P), intent(out) :: k1     !< K_1 (0 when k1_inf).
   logical,   intent(out) :: k1_inf !< K_1 = 2 sum1/x overflows.
   real(R8P)              :: f      !< Series term factor.
   real(R8P)              :: h      !< Series term factor of K_1.
   real(R8P)              :: p      !< p_k.
   real(R8P)              :: q      !< q_k.
   real(R8P)              :: coef   !< (x**2/4)**k/k!.
   real(R8P)              :: sum    !< K_0 series.
   real(R8P)              :: sum1   !< K_1 series.
   real(R8P)              :: xh     !< x/2.
   integer(I4P)           :: kk     !< Term index.
   real(R8P)              :: rk     !< kk as a real.

   xh = x / 2._R8P
   if (xh == 0._R8P) xh = 1._R8P ! stand-in against speculated evaluation: the caller excludes x/2 = 0
   p = 0.5_R8P
   q = 0.5_R8P
   f = -EULER + (-log(xh))
   h = p
   coef = 1._R8P
   sum = coef * f
   sum1 = coef * h
   do kk = 1_I4P, MAXITER - 1_I4P
      rk = real(kk, R8P)
      f = (rk * f + p + q) / real(kk * kk, R8P)
      p = p / rk
      q = q / rk
      h = p - rk * f
      coef = coef * (x * x / (4._R8P * rk))
      sum = sum + coef * f
      sum1 = sum1 + coef * h
      if (abs(coef * f) < abs(sum) * MACHEP) exit
   enddo
   k = sum
   call div_safe(2._R8P * sum1, x, k1, k1_inf)
   endsubroutine temme_ik_series

   pure subroutine cf1_ik(v, x, fv, fv_nan)
   !< I_v+1(x)/I_v(x) by the continued fraction A&S 9.1.73, modified Lentz (specfun.c CF1_ik). When 2(v+k)/x
   !< overflows gnuplot computes Inf*0 and the fraction is NaN: fv_nan.
   real(R8P), intent(in)  :: v      !< Order.
   real(R8P), intent(in)  :: x      !< Argument (> 0).
   real(R8P), intent(out) :: fv     !< I_v+1/I_v.
   logical,   intent(out) :: fv_nan !< The fraction is NaN.
   real(R8P)              :: c, d, f, b, delta !< Lentz variables.
   integer(I4P)           :: k      !< Term index.

   fv_nan = .false.
   c = CF1_TINY
   f = CF1_TINY
   d = 0._R8P
   do k = 1_I4P, MAXITER - 1_I4P
      call div_safe(2._R8P * (v + real(k, R8P)), x, b, fv_nan)
      if (fv_nan) then
         fv = 0._R8P
         return
      endif
      c = b + 1._R8P / c
      d = b + 1._R8P * d
      if (c == 0._R8P) c = CF1_TINY
      if (d == 0._R8P) d = CF1_TINY
      d = 1._R8P / d
      delta = c * d
      f = f * delta
      if (abs(delta - 1._R8P) <= 2._R8P * MACHEP) exit
   enddo
   fv = f
   endsubroutine cf1_ik

   pure subroutine cf2_ik(v, x, kv, kv1)
   !< K_v(x) and K_v+1(x) by Steed's continued fraction, Thompson and Barnett (specfun.c CF2_ik), 2 < x < 745.13.
   real(R8P), intent(in)  :: v   !< Order, |v| <= 1/2.
   real(R8P), intent(in)  :: x   !< Argument.
   real(R8P), intent(out) :: kv  !< K_v.
   real(R8P), intent(out) :: kv1 !< K_v+1.
   real(R8P)              :: s, c, q, d, f, a, b, qq, delta, current, prev !< Steed variables (q is Q, qq is q).
   integer(I4P)           :: k   !< Term index.

   a = v * v - 0.25_R8P
   b = 2._R8P * (x + 1._R8P)
   d = 1._R8P / b
   f = d
   delta = d
   prev = 0._R8P
   current = 1._R8P
   c = -a
   q = c
   s = 1._R8P + q * delta
   do k = 2_I4P, MAXITER - 1_I4P
      a = a - real(2_I4P * (k - 1_I4P), R8P)
      b = b + 2._R8P
      d = 1._R8P / (b + a * d)
      delta = delta * (b * d - 1._R8P)
      f = f + delta
      qq = (prev - (b - 2._R8P) * current) / a
      prev = current
      current = qq
      c = c * (-a / real(k, R8P))
      q = q + c * qq
      s = s + q * delta
      if (abs(q * delta) < abs(s) * MACHEP) exit
   enddo
   kv = sqrt(PI / (2._R8P * x)) * exp(-x) / s
   kv1 = kv * (0.5_R8P + v + x + (v * v - 0.25_R8P) * f) / x
   endsubroutine cf2_ik
endmodule foresight_bessel
