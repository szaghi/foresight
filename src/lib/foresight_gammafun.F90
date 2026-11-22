!< gnuplot 6.0.0's error, gamma, incomplete gamma, incomplete beta and normal distribution functions.
module foresight_gammafun
!< gnuplot 6.0.0's error, gamma, incomplete gamma, incomplete beta and normal distribution functions.
!<
!< Ported from gnuplot 6.0.0 `specfun.c` (Cephes `ndtri`, `incbet`, `igamc`, the inverse functions) and
!< `complexfun.c` (`Igamma`, `lnGamma`), with gnuplot's coefficients, branch points and operation order, so that the
!< values match the installed gnuplot (Linux, glibc 2.39) to the last digit.
!<
!< Every entry point `gp_<name>` takes gnuplot's arguments in gnuplot's order and returns `r` and `status`:
!< 0 the value is in `r`; 1 gnuplot's undefined value ("undefined value", a gap in a plot); 2 a gnuplot error, which no
!< function of this family ever raises. gnuplot flags a result undefined when a libm call leaves `errno` at EDOM or
!< ERANGE (eval.c `evaluate_at`), even when the value is meaningful (`igamma(1, 800)`): that `errno` is tracked here.
!< All results are real (gnuplot prints `1.0`, not `1`). A NaN in `r` with status 0 is gnuplot's printed `NaN` (its
!< overflowing continued fractions and Halley steps end there). Where gnuplot's result is infinite (huge or tiny
!< arguments, see each docstring) status is 1 instead. Every operation that could overflow, divide by zero or be
!< invalid is guarded, so no finite argument raises an IEEE exception other than underflow and inexact.
!<
!< gnuplot calls glibc's `erf`, `erfc`, `tgamma`, `lgamma`, `exp`, `log`, `pow`, `sin`, `cos`: the Fortran intrinsics,
!< which are glibc's under gfortran. glibc's complex `clog` and `cexp` are emulated (`clog` uses `log1p` for moduli in
!< [0.5, 2), ported from glibc's FMA build, the one this machine's glibc dispatches).
#if !defined(__NVCOMPILER)
use, intrinsic :: ieee_arithmetic, only : ieee_fma
#endif
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan, ieee_quiet_nan, ieee_value
use penf, only : I4P, I8P, R8P

implicit none
private
public :: gp_erf
public :: gp_erfc
public :: gp_gamma
public :: gp_lgamma
public :: gp_norm
public :: gp_invnorm
public :: gp_inverf
public :: gp_igamma
public :: gp_uigamma
public :: gp_invigamma
public :: gp_ibeta
public :: gp_invibeta

real(R8P), parameter :: DBL_MAX = huge(1._R8P)                        !< C DBL_MAX.
real(R8P), parameter :: DBL_MIN = tiny(1._R8P)                        !< C DBL_MIN.
real(R8P), parameter :: MACHEP = epsilon(1._R8P)                      !< Cephes MACHEP = DBL_EPSILON.
real(R8P), parameter :: MAXLOG = 708.396418532264106224_R8P           !< Cephes MAXLOG, log(2**1022).
real(R8P), parameter :: MINLOG = -708.396418532264106224_R8P          !< Cephes MINLOG.
real(R8P), parameter :: MAXGAM = 171.624376956302725_R8P              !< Cephes MAXGAM.
real(R8P), parameter :: BIG = 4.503599627370496e15_R8P                !< Cephes incbet `big`.
real(R8P), parameter :: BIGINV = 2.22044604925031308085e-16_R8P       !< Cephes incbet `biginv`.
real(R8P), parameter :: IGAMMA_PRECISION = 1.e-14_R8P                 !< gnuplot IGAMMA_PRECISION.
real(R8P), parameter :: FLT_MAX = 3.40282346638528859811704183484516925440e+38_R8P !< C FLT_MAX (IGAMMA_OVERFLOW).
real(R8P), parameter :: VERYLARGE = DBL_MAX / 2._R8P                  !< gnuplot VERYLARGE, DBL_MAX/2-1.
real(R8P), parameter :: PI = 3.14159265358979323846_R8P               !< gnuplot PI and M_PI.
real(R8P), parameter :: SQRT_TWO = 1.41421356237309504880168872420969809_R8P !< gnuplot SQRT_TWO.
real(R8P), parameter :: LN2 = 0.693147180559945309417232121458176568_R8P     !< glibc M_LN2.
real(R8P), parameter :: ZERO_TOL = 1.e-8_R8P                         !< gnuplot `set zero`: plotted if |imag| <= it.
real(R8P), parameter :: EXP_ZERO = -745.13321910194122_R8P            !< glibc exp(x) is 0 (and ERANGE) iff x <= it.
real(R8P), parameter :: EXP_INF = 709.78271289338397_R8P              !< glibc exp(x) overflows (ERANGE) iff x > it.
real(R8P), parameter :: TGAMMA_MAX = 171.62437695630271_R8P           !< glibc tgamma(x) overflows iff x > it.
integer(I8P), parameter :: INV_TINY_BITS = 1125899906842625_I8P     !< Bits of the least x with 1/x finite, 5.56e-309:
                                                                      !< also glibc tgamma's overflow threshold near 0.
real(R8P), parameter :: LGAMMA_MAX = 2.5599833278516383e305_R8P       !< glibc lgamma(x) overflows iff x > it.
real(R8P), parameter :: ERFC_ZERO = 27.226364135742188_R8P            !< glibc erfc(x) is 0 (and ERANGE) iff x >= it.
real(R8P), parameter :: LOG_HALF_DENORM = -745.13321910194122_R8P     !< log(2**-1075): tgamma rounds to 0 below it.
real(R8P), parameter :: S2PI = 2.50662827463100050242E0_R8P           !< ndtri's sqrt(2pi).
real(R8P), parameter :: LANCZOS_SQRT2PI = 2.5066282746310005_R8P      !< complexfun.c lnGamma sqrt2pi.
real(R8P), parameter :: LANCZOS_G = 671._R8P / 128._R8P               !< complexfun.c lnGamma g.
real(R8P), parameter :: LANCZOS(0:14) = [0.99999999999999709182_R8P,                                    &
                                         57.156235665862923517_R8P, -59.597960355475491248_R8P,          &
                                         14.136097974741747174_R8P, -0.49191381609762019978_R8P,         &
                                         0.33994649984811888699e-4_R8P, 0.46523628927048575665e-4_R8P,   &
                                         -0.98374475304879564677e-4_R8P, 0.15808870322491248884e-3_R8P,  &
                                         -0.21026444172410488319e-3_R8P, 0.21743961811521264320e-3_R8P,  &
                                         -0.16431810653676389022e-3_R8P, 0.84418223983852743293e-4_R8P,  &
                                         -0.26190838401581408670e-4_R8P, 0.36899182659531622704e-5_R8P]
                                                                      !< complexfun.c lnGamma 14 term Lanczos coef.
real(R8P), parameter :: GL_Y(18) = [0.0021695375159141994_R8P,                                         &
                                    0.011413521097787704_R8P, 0.027972308950302116_R8P, 0.051727015600492421_R8P, &
                                    0.082502225484340941_R8P, 0.12007019910960293_R8P, 0.16415283300752470_R8P,   &
                                    0.21442376986779355_R8P, 0.27051082840644336_R8P, 0.33199876341447887_R8P,    &
                                    0.39843234186401943_R8P, 0.46931971407375483_R8P, 0.54413605556657973_R8P,    &
                                    0.62232745288031077_R8P, 0.70331500465597174_R8P, 0.78649910768313447_R8P,    &
                                    0.87126389619061517_R8P, 0.95698180152629142_R8P]
                                                                      !< Igamma_GL Gauss-Legendre abscissae.
real(R8P), parameter :: GL_W(18) = [0.0055657196642445571_R8P,                                         &
                                    0.012915947284065419_R8P, 0.020181515297735382_R8P, 0.027298621498568734_R8P, &
                                    0.034213810770299537_R8P, 0.040875750923643261_R8P, 0.047235083490265582_R8P, &
                                    0.053244713977759692_R8P, 0.058860144245324798_R8P, 0.064039797355015485_R8P, &
                                    0.068745323835736408_R8P, 0.072941885005653087_R8P, 0.076598410645870640_R8P, &
                                    0.079687828912071670_R8P, 0.082187266704339706_R8P, 0.084078218979661945_R8P, &
                                    0.085346685739338721_R8P, 0.085983275670394821_R8P]
                                                                      !< Igamma_GL Gauss-Legendre weights.
real(R8P), parameter :: NDTRI_P0(0:4) = [-5.99633501014107895267E1_R8P, 9.80010754185999661536E1_R8P,      &
                                         -5.66762857469070293439E1_R8P, 1.39312609387279679503E1_R8P,      &
                                         -1.23916583867381258016E0_R8P]   !< ndtri P0, 0 <= |y - 0.5| <= 3/8.
real(R8P), parameter :: NDTRI_Q0(0:7) = [1.95448858338141759834E0_R8P, 4.67627912898881538453E0_R8P,       &
                                         8.63602421390890590575E1_R8P, -2.25462687854119370527E2_R8P,      &
                                         2.00260212380060660359E2_R8P, -8.20372256168333339912E1_R8P,      &
                                         1.59056225126211695515E1_R8P, -1.18331621121330003142E0_R8P]
                                                                      !< ndtri Q0 (leading 1 omitted).
real(R8P), parameter :: NDTRI_P1(0:8) = [4.05544892305962419923E0_R8P, 3.15251094599893866154E1_R8P,       &
                                         5.71628192246421288162E1_R8P, 4.40805073893200834700E1_R8P,       &
                                         1.46849561928858024014E1_R8P, 2.18663306850790267539E0_R8P,       &
                                         -1.40256079171354495875E-1_R8P, -3.50424626827848203418E-2_R8P,   &
                                         -8.57456785154685413611E-4_R8P]  !< ndtri P1, z = sqrt(-2 log y) in [2, 8].
real(R8P), parameter :: NDTRI_Q1(0:7) = [1.57799883256466749731E1_R8P, 4.53907635128879210584E1_R8P,       &
                                         4.13172038254672030440E1_R8P, 1.50425385692907503408E1_R8P,       &
                                         2.50464946208309415979E0_R8P, -1.42182922854787788574E-1_R8P,     &
                                         -3.80806407691578277194E-2_R8P, -9.33259480895457427372E-4_R8P]
                                                                      !< ndtri Q1 (leading 1 omitted).
real(R8P), parameter :: NDTRI_P2(0:8) = [3.23774891776946035970E0_R8P, 6.91522889068984211695E0_R8P,       &
                                         3.93881025292474443415E0_R8P, 1.33303460815807542389E0_R8P,       &
                                         2.01485389549179081538E-1_R8P, 1.23716634817820021358E-2_R8P,     &
                                         3.01581553508235416007E-4_R8P, 2.65806974686737550832E-6_R8P,     &
                                         6.23974539184983293730E-9_R8P]   !< ndtri P2, z = sqrt(-2 log y) in [8, 64].
real(R8P), parameter :: NDTRI_Q2(0:7) = [6.02427039364742014255E0_R8P, 3.67983563856160859403E0_R8P,       &
                                         1.37702099489081330271E0_R8P, 2.16236993594496635890E-1_R8P,      &
                                         1.34204006088543189037E-2_R8P, 3.28014464682127739104E-4_R8P,     &
                                         2.89247864745380683936E-6_R8P, 6.79019408009981274425E-9_R8P]
                                                                      !< ndtri Q2 (leading 1 omitted).
real(R8P), parameter :: INVERF_A(0:3) = [0.886226899_R8P, -1.645349621_R8P, 0.914624893_R8P, -0.140543331_R8P]
                                                                      !< inverse_error_func a[].
real(R8P), parameter :: INVERF_B(0:3) = [-2.118377725_R8P, 1.442710462_R8P, -0.329097515_R8P, 0.012229801_R8P]
                                                                      !< inverse_error_func b[].
real(R8P), parameter :: INVERF_C(0:3) = [-1.970840454_R8P, -1.624906493_R8P, 3.429567803_R8P, 1.641345311_R8P]
                                                                      !< inverse_error_func c[].
real(R8P), parameter :: INVERF_D(0:1) = [3.543889200_R8P, 1.637067800_R8P] !< inverse_error_func d[].
real(R8P), parameter :: L1P_LN2_HI = 6.93147180369123816490e-01_R8P  !< glibc log1p ln2_hi.
real(R8P), parameter :: L1P_LN2_LO = 1.90821492927058770002e-10_R8P  !< glibc log1p ln2_lo.
real(R8P), parameter :: L1P_LP(7) = [6.666666666666735130e-01_R8P, 3.999999999940941908e-01_R8P,           &
                                     2.857142874366239149e-01_R8P, 2.222219843214978396e-01_R8P,           &
                                     1.818357216161805012e-01_R8P, 1.531383769920937332e-01_R8P,           &
                                     1.479819860511658591e-01_R8P]    !< glibc log1p Lp1..Lp7.

contains
   ! public procedures

   pure subroutine gp_erf(x, r, status)
   !< gnuplot `erf(x)` (specfun.c f_erf): libm erf. Real result, always defined.
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< erf(x).
   integer(I4P), intent(out) :: status !< 0 (always defined).

   r = erf(x)
   status = 0_I4P
   endsubroutine gp_erf

   pure subroutine gp_erfc(x, r, status)
   !< gnuplot `erfc(x)` (specfun.c f_erfc): libm erfc. Real result; undefined when glibc's erfc underflows to 0
   !< (x >= 27.2263641357421875), since glibc then sets ERANGE.
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< erfc(x).
   integer(I4P), intent(out) :: status !< 0 defined, 1 undefined.

   if (x >= ERFC_ZERO) then
      r = 0._R8P
      status = 1_I4P
   else
      r = erfc(x)
      status = 0_I4P
   endif
   endsubroutine gp_erfc

   pure subroutine gp_gamma(x, r, status)
   !< gnuplot `gamma(x)` (specfun.c f_gamma): libm tgamma. Real result; undefined where glibc's tgamma sets errno: at 0
   !< and the negative integers, on overflow (x > 171.62437695630271, |x| < 5.56e-309) and when the result underflows
   !< to 0 (x < -184 or so, judged by lgamma so that a flush-to-zero build agrees).
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Gamma(x).
   integer(I4P), intent(out) :: status !< 0 defined, 1 undefined.

   r = 0._R8P
   status = 1_I4P
   if (inv_overflows(abs(x))) return
   if (x > TGAMMA_MAX) return
   if (x < 0._R8P) then
      if (x == aint(x)) return
      if (x < -200._R8P) return
      if (x < -170._R8P) then
         if (log_gamma(x) <= LOG_HALF_DENORM) return
      endif
   endif
   r = gamma(x)
   status = 0_I4P
   endsubroutine gp_gamma

   pure subroutine gp_lgamma(x, r, status)
   !< gnuplot `lgamma(x)` (specfun.c f_lgamma): libm lgamma, ln|Gamma(x)| (no sign: lgamma(-0.5) = 1.2655 > 0 while
   !< Gamma(-0.5) < 0). Real result; undefined at 0 and the negative integers (poles) and for x > 2.5599833278516383e305
   !< (overflow), where glibc sets ERANGE.
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< ln|Gamma(x)|.
   integer(I4P), intent(out) :: status !< 0 defined, 1 undefined.

   r = 0._R8P
   status = 1_I4P
   if (x == 0._R8P .or. x > LGAMMA_MAX) return
   if (x < 0._R8P) then
      if (x == aint(x)) return
   endif
   r = log_gamma(x)
   status = 0_I4P
   endsubroutine gp_lgamma

   pure subroutine gp_norm(x, r, status)
   !< gnuplot `norm(x)` (specfun.c f_normal): 0.5 erfc(-x/sqrt(2)) for x > -38, else 0. Real result, always defined.
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Normal cumulative distribution at x.
   integer(I4P), intent(out) :: status !< 0 (always defined).

   real(R8P) :: t !< Scaled argument.

   if (x > -38._R8P) then
      t = (0.5_R8P * SQRT_TWO) * x
      r = 0.5_R8P * erfc(-t)
   else
      r = 0._R8P
   endif
   status = 0_I4P
   endsubroutine gp_norm

   pure subroutine gp_invnorm(x, r, status)
   !< gnuplot `invnorm(x)` (specfun.c f_inverse_normal, Cephes ndtri). Real result; undefined for x <= 0 or x >= 1.
   real(R8P),    intent(in)  :: x      !< Probability.
   real(R8P),    intent(out) :: r      !< Normal quantile.
   integer(I4P), intent(out) :: status !< 0 defined, 1 undefined.

   if (x <= 0._R8P .or. x >= 1._R8P) then
      r = 0._R8P
      status = 1_I4P
   else
      r = ndtri(x)
      status = 0_I4P
   endif
   endsubroutine gp_invnorm

   pure subroutine gp_inverf(x, r, status)
   !< gnuplot `inverf(x)` (specfun.c f_inverse_erf, inverse_error_func: NIST rational guess and 4 Newton steps, with
   !< gnuplot's `b[3] * z + b[3]` typo kept). Real result; undefined for |x| >= 1.
   real(R8P),    intent(in)  :: x      !< Argument in (-1, 1).
   real(R8P),    intent(out) :: r      !< Inverse error function.
   integer(I4P), intent(out) :: status !< 0 defined, 1 undefined.

   if (abs(x) >= 1._R8P) then
      r = 0._R8P
      status = 1_I4P
   else
      r = inverse_error_func(x)
      status = 0_I4P
   endif
   endsubroutine gp_inverf

   pure subroutine gp_igamma(a, x, r, status, ri)
   !< gnuplot `igamma(a, x)`, the regularized lower incomplete gamma P(a, x): gnuplot 6.0 built with complex functions
   !< evaluates complexfun.c Igamma (AS239 series and continued fraction, Gauss-Legendre for large a, A&S 6.5.29 for
   !< x < 0), not specfun.c's real igamma. Real result for x >= 0; for x < 0 gnuplot returns a complex value: `r` is its
   !< real part, `ri` its imaginary part (for gnuplot's sampled `x`, imaginary part +0), and status is 1 when
   !< |imag| > 1e-8, as gnuplot's plot (`set zero`). a <= 0, or no convergence / overflow of the continued fraction
   !< (gnuplot warns "Igamma: overflow" or "Igamma: no convergence after %d iterations residual %g"): NaN, status 0,
   !< unless errno is set. Undefined (status 1) when glibc's cexp underflows to 0 in the continued fraction or the
   !< Gauss-Legendre sum (e.g. igamma(1, 800), igamma(1e6, 1.1e6)), and where gnuplot's result is infinite (x < 0
   !< with |x| beyond a few hundred, a beyond 1e300).
   real(R8P),    intent(in)            :: a      !< Shape, a > 0.
   real(R8P),    intent(in)            :: x      !< Upper limit.
   real(R8P),    intent(out)           :: r      !< P(a, x), real part.
   integer(I4P), intent(out)           :: status !< 0 defined, 1 undefined.
   real(R8P),    intent(out), optional :: ri     !< Imaginary part (nonzero only for x < 0).

   real(R8P) :: re, im             !< Igamma value.
   logical   :: fail, nanres       !< Igamma returned -1, NaN.
   logical   :: errno, bad          !< errno set, Igamma returned an infinity.

   im = 0._R8P
   status = 0_I4P
   if (a <= 0._R8P) then
      re = nan()
   elseif (x == 0._R8P) then
      re = 0._R8P
   else
      errno = .false.
      call igamma_core(a=a, z=x, re=re, im=im, fail=fail, nanres=nanres, errno=errno, bad=bad)
      if (bad) then
         re = 0._R8P
         im = 0._R8P
         status = 1_I4P
      elseif (fail .or. nanres) then
         re = nan()
         im = 0._R8P
         if (errno) status = 1_I4P
      else
         if (errno) status = 1_I4P
         if (abs(im) > ZERO_TOL) status = 1_I4P
      endif
   endif
   r = re
   if (present(ri)) ri = im
   endsubroutine gp_igamma

   pure subroutine gp_uigamma(a, x, r, status)
   !< gnuplot `uigamma(a, x)`, the regularized upper incomplete gamma Q(a, x) (specfun.c f_uigamma, Cephes igamc: for
   !< x < 1 or x < a 1 - igamma(a, x) with complexfun.c's igamma, so 2 when that fails). Real result; undefined for
   !< x < 0 or a <= 0 and when errno is set (as in igamma, or glibc's lgamma(a) overflowing, a > 2.56e305); NaN
   !< (status 0) where gnuplot's continued fraction overflows (a, x beyond about 1e154).
   real(R8P),    intent(in)  :: a      !< Shape, a > 0.
   real(R8P),    intent(in)  :: x      !< Lower limit, x >= 0.
   real(R8P),    intent(out) :: r      !< Q(a, x).
   integer(I4P), intent(out) :: status !< 0 defined, 1 undefined.

   r = 0._R8P
   status = 1_I4P
   if (x < 0._R8P .or. a <= 0._R8P) return
   call igamc(a, x, r, status)
   endsubroutine gp_uigamma

   pure subroutine gp_invigamma(a, p, r, status)
   !< gnuplot `invigamma(a, p)` (specfun.c f_inverse_igamma, inverse_incomplete_gamma: A&S or NR initial guess, 12
   !< Halley steps on complexfun.c's igamma). Real result: 0 for p = 0, max(100, a + 100 sqrt(a)) for p = 1.
   !< Undefined for a <= 0 (gnuplot warns "invigamma: a<=0 invalid"), p < 0 or p > 1 ("invigamma: p invalid"), and
   !< when errno is set during the iteration (gnuplot warns `inverse_incomplete_gamma: <strerror>...` and gives NaN).
   !< NaN (status 0) when a Halley step overflows (huge a).
   real(R8P),    intent(in)  :: a      !< Shape, a > 0.
   real(R8P),    intent(in)  :: p      !< Probability in [0, 1].
   real(R8P),    intent(out) :: r      !< x such that igamma(a, x) = p.
   integer(I4P), intent(out) :: status !< 0 defined, 1 undefined.

   r = 0._R8P
   status = 1_I4P
   if (a <= 0._R8P) return
   if (p < 0._R8P .or. p > 1._R8P) return
   status = 0_I4P
   if (p == 1._R8P) then
      r = max(100._R8P, a + 100._R8P * sqrt(a))
   elseif (p == 0._R8P) then
      r = 0._R8P
   else
      call inverse_incomplete_gamma(a, p, r, status)
   endif
   endsubroutine gp_invigamma

   pure subroutine gp_ibeta(a, b, x, r, status)
   !< gnuplot `ibeta(a, b, x)`, the regularized incomplete beta I_x(a, b) (specfun.c f_ibeta with Cephes incbet: power
   !< series or one of two continued fractions). Real result; undefined for a <= 0, b <= 0, x outside [0, 1], when
   !< glibc's tgamma or lgamma overflow (a or b below 5.56e-309, a + b above 2.56e305) and where gnuplot's power
   !< series returns inf (a below 5.56e-309 with a + b >= 171.6); NaN (status 0) where gnuplot's continued fractions
   !< overflow (a, b beyond about 1e150).
   real(R8P),    intent(in)  :: a      !< Shape a > 0.
   real(R8P),    intent(in)  :: b      !< Shape b > 0.
   real(R8P),    intent(in)  :: x      !< Upper limit in [0, 1].
   real(R8P),    intent(out) :: r      !< I_x(a, b).
   integer(I4P), intent(out) :: status !< 0 defined, 1 undefined.

   logical :: errno, bad, nanres !< errno set, infinite result, NaN result.

   status = 1_I4P
   errno = .false.
   call incbet(a, b, x, r, errno, bad, nanres)
   if (nanres) then
      r = nan()
      if (.not. errno) status = 0_I4P
   elseif (bad .or. errno .or. r == -1._R8P) then
      r = 0._R8P
   else
      status = 0_I4P
   endif
   endsubroutine gp_ibeta

   pure subroutine gp_invibeta(a, b, p, r, status)
   !< gnuplot `invibeta(a, b, p)` (specfun.c f_inverse_ibeta, inverse_incomplete_beta: A&S 26.5.22 or NR 6.4.8
   !< initial guess, 12 Halley steps on incbet). Real result: NaN for a <= 0 or b <= 0 (status 0, gnuplot prints NaN),
   !< 0 for p <= 0, 1 for |1 - p| < 1e-14; p outside [0, 1] is only warned ("f_inverse_ibeta: p %g not in domain") and
   !< computed. Undefined when errno is set: gnuplot's guess takes sqrt(z) of a negative normal deviate, so for a >= 1
   !< and b >= 1 every p < 0.5 is undefined (invibeta(2, 2, 0.1)), as in gnuplot 6.0.0. NaN (status 0) when a Halley
   !< step overflows.
   real(R8P),    intent(in)  :: a      !< Shape a > 0.
   real(R8P),    intent(in)  :: b      !< Shape b > 0.
   real(R8P),    intent(in)  :: p      !< Probability.
   real(R8P),    intent(out) :: r      !< x such that ibeta(a, b, x) = p.
   integer(I4P), intent(out) :: status !< 0 defined, 1 undefined.

   status = 0_I4P
   if (a <= 0._R8P .or. b <= 0._R8P) then
      r = nan()
   elseif (p <= 0._R8P) then
      r = 0._R8P
   elseif (abs(1._R8P - p) < IGAMMA_PRECISION) then
      r = 1._R8P
   else
      call inverse_incomplete_beta(a, b, p, r, status)
   endif
   endsubroutine gp_invibeta

   ! private procedures: libm and glibc emulation

   pure function nan() result(r)
   !< Quiet NaN, without raising an exception.
   real(R8P) :: r !< NaN.

   r = ieee_value(1._R8P, ieee_quiet_nan)
   endfunction nan

   pure function fma_(a, b, c) result(r)
   !< a * b + c rounded once (glibc's FMA build); nvfortran has no ieee_fma, -Mnofma leaves a * b + c unfused there.
   real(R8P), intent(in) :: a, b, c !< Operands.
   real(R8P)             :: r       !< a * b + c.

#if defined(__NVCOMPILER)
   r = a * b + c
#else
   r = ieee_fma(a, b, c)
#endif
   endfunction fma_

   pure function inv_overflows(x) result(ovf)
   !< 1/x overflows (x >= 0): x below 5.5626846462680084e-309, compared on the bits so that flush-to-zero builds
   !< (and their denormals-are-zero comparisons) agree.
   real(R8P), intent(in) :: x   !< Non negative value.
   logical               :: ovf !< 1/x is infinite.

   ovf = .true.
   if (x == 0._R8P) return
   ovf = transfer(x, 0_I8P) < INV_TINY_BITS
   endfunction inv_overflows

   pure function high_word(x) result(h)
   !< High 32 bits of the IEEE representation of x, as glibc's GET_HIGH_WORD.
   real(R8P), intent(in) :: x !< Value.
   integer(I4P)          :: h !< High word, signed.

   integer(I8P) :: bits !< IEEE bits.

   bits = transfer(x, 0_I8P)
   h = int((bits - modulo(bits, 4294967296_I8P)) / 4294967296_I8P, I4P) ! floor(bits / 2**32)
   endfunction high_word

   pure function with_high_word(x, h) result(y)
   !< x with its high 32 bits replaced by h, as glibc's SET_HIGH_WORD.
   real(R8P),    intent(in) :: x !< Value.
   integer(I4P), intent(in) :: h !< New high word (non negative).
   real(R8P)                :: y !< Result.

   integer(I8P) :: bits !< IEEE bits.

   bits = transfer(x, 0_I8P)
   bits = ior(shiftl(int(h, I8P), 32), iand(bits, 4294967295_I8P))
   y = transfer(bits, 0._R8P)
   endfunction with_high_word

   pure function log1p_glibc(x) result(r)
   !< glibc 2.39 `__log1p_fma` (fdlibm s_log1p.c built with FMA contraction), for x > -1.
   real(R8P), intent(in) :: x !< Argument.
   real(R8P)             :: r !< log(1 + x).

   real(R8P)    :: hfsq, f, c, s, z, rr, u, z2, z4, z6, r2, r3, r4, sr, fk !< Work.
   integer(I4P) :: k, hx, hu, ax                                         !< Work.

   c = 0._R8P
   f = 0._R8P
   hu = 0_I4P
   hx = high_word(x)
   ax = iand(hx, 2147483647_I4P)
   k = 1_I4P
   if (hx < 1071284858_I4P) then ! x < 0.41422
      if (ax >= 1072693248_I4P) then ! x <= -1, not reached by the callers
         r = nan()
         return
      endif
      if (ax < 1042284544_I4P) then ! |x| < 2**-29
         if (ax < 1016070144_I4P) then
            r = x
         else
            r = fma_(-(x * x), 0.5_R8P, x)
         endif
         return
      endif
      if (hx > 0_I4P .or. hx <= -1076707644_I4P) then ! -0.2929 < x < 0.41422
         k = 0_I4P
         f = x
         hu = 1_I4P
      endif
   elseif (hx >= 2146435072_I4P) then
      r = x + x
      return
   endif
   if (k /= 0_I4P) then
      if (hx < 1128267776_I4P) then
         u = 1._R8P + x
         hu = high_word(u)
         k = shiftr(hu, 20) - 1023_I4P
         if (k > 0_I4P) then
            c = 1._R8P - (u - x)
         else
            c = x - (u - 1._R8P)
         endif
         c = c / u
      else
         u = x
         hu = high_word(u)
         k = shiftr(hu, 20) - 1023_I4P
         c = 0._R8P
      endif
      hu = iand(hu, 1048575_I4P)
      if (hu < 434334_I4P) then
         u = with_high_word(u, ior(hu, 1072693248_I4P))
      else
         k = k + 1_I4P
         u = with_high_word(u, ior(hu, 1071644672_I4P))
         hu = shiftr(1048576_I4P - hu, 2)
      endif
      f = u - 1._R8P
   endif
   fk = real(k, R8P)
   hfsq = (0.5_R8P * f) * f
   if (hu == 0_I4P) then ! |f| < 2**-20
      if (f == 0._R8P) then
         if (k == 0_I4P) then
            r = 0._R8P
         else
            c = fma_(fk, L1P_LN2_LO, c)
            r = fma_(fk, L1P_LN2_HI, c)
         endif
         return
      endif
      rr = fma_(-f, 0.66666666666666666_R8P, 1._R8P) * hfsq
      if (k == 0_I4P) then
         r = f - rr
      else
         r = fma_(fk, L1P_LN2_HI, -((rr - fma_(fk, L1P_LN2_LO, c)) - f))
      endif
      return
   endif
   s = f / (2._R8P + f)
   z = s * s
   z2 = z * z
   r2 = fma_(z, L1P_LP(3), L1P_LP(2))
   z4 = z2 * z2
   r3 = fma_(z, L1P_LP(5), L1P_LP(4))
   z6 = z2 * z4
   r4 = fma_(z, L1P_LP(7), L1P_LP(6))
   rr = fma_(z6, r4, fma_(z4, r3, fma_(z, L1P_LP(1), z2 * r2)))
   sr = s * (rr + hfsq)
   if (k == 0_I4P) then
      r = f - (hfsq - sr)
   else
      r = fma_(fk, L1P_LN2_HI, -((hfsq - (fma_(fk, L1P_LN2_LO, c) + sr)) - f))
   endif
   endfunction log1p_glibc

   pure function clog_re(x) result(r)
   !< Real part of glibc's clog(x + 0i), x /= 0: log|x|, through log1p for |x| in [0.5, 2) as glibc does.
   real(R8P), intent(in) :: x !< Argument, nonzero.
   real(R8P)             :: r !< log|x| as glibc's clog.

   real(R8P)    :: ax    !< |x|, scaled.
   integer(I4P) :: scale !< Binary scaling.

   ax = abs(x)
   scale = 0_I4P
   if (ax > DBL_MAX / 2._R8P) then
      scale = -1_I4P
      ax = ax * 0.5_R8P
   elseif (ax < DBL_MIN) then
      scale = 53_I4P
      ax = ax * 9007199254740992._R8P
   endif
   if (ax == 1._R8P .and. scale == 0_I4P) then
      r = 0._R8P
   elseif (ax > 1._R8P .and. ax < 2._R8P .and. scale == 0_I4P) then
      r = log1p_glibc((ax - 1._R8P) * (ax + 1._R8P)) / 2._R8P
   elseif (ax < 1._R8P .and. ax >= 0.5_R8P .and. scale == 0_I4P) then
      r = log1p_glibc((ax - 1._R8P) * (ax + 1._R8P)) / 2._R8P
   else
      r = log(ax) - real(scale, R8P) * LN2
   endif
   endfunction clog_re

   pure subroutine cexp_(u, w, cr, ci, errno, ovf)
   !< glibc's cexp(u + i w) for finite u, w: exp(u) (cos w, sin w), scaled by exp(709) above 709; errno when exp(u)
   !< underflows to 0; `ovf` when the result overflows (gnuplot then holds infinities).
   real(R8P), intent(in)    :: u, w   !< Real and imaginary parts of the argument.
   real(R8P), intent(out)   :: cr, ci !< Result.
   logical,   intent(inout) :: errno  !< errno.
   logical,   intent(out)   :: ovf    !< Overflow.

   real(R8P) :: x, sinix, cosix, et, e !< Work.

   ovf = .false.
   cr = 0._R8P
   ci = 0._R8P
   if (abs(w) > DBL_MIN) then
      sinix = sin(w)
      cosix = cos(w)
   else
      sinix = w
      cosix = 1._R8P
   endif
   x = u
   if (x > 709._R8P) then
      et = exp(709._R8P)
      x = x - 709._R8P
      sinix = sinix * et
      cosix = cosix * et
      if (x > 709._R8P) then
         x = x - 709._R8P
         if (max(abs(sinix), abs(cosix)) > DBL_MAX / et) then
            ovf = .true.
            return
         endif
         sinix = sinix * et
         cosix = cosix * et
      endif
   endif
   if (x > 709._R8P) then
      ovf = .true.
      return
   endif
   if (x <= EXP_ZERO) then
      errno = .true.
      e = 0._R8P
   else
      e = exp(x)
   endif
   if (max(abs(sinix), abs(cosix)) > DBL_MAX / max(1._R8P, e)) then
      ovf = .true.
      return
   endif
   cr = e * cosix
   ci = e * sinix
   endsubroutine cexp_

   pure subroutine pow_(x, y, r, errno, ovf)
   !< glibc's pow(x, y): negative x only for integer y (else NaN and EDOM), errno on overflow and on underflow to 0.
   real(R8P), value         :: x, y  !< Base and exponent (by value: r may be one of them).
   real(R8P), intent(inout) :: r     !< x**y (inout: see mul_).
   logical,   intent(inout) :: errno !< errno.
   logical,   intent(out)   :: ovf   !< Overflow (r is then +-huge).

   real(R8P) :: lr !< y log|x|.
   logical   :: odd !< Odd integer exponent.

   ovf = .false.
   r = 0._R8P
   if (y == 0._R8P) then
      r = 1._R8P
      return
   endif
   if (x == 0._R8P) then
      if (y < 0._R8P) then
         errno = .true.
         ovf = .true.
      endif
      return
   endif
   odd = .false.
   if (x < 0._R8P) then
      if (y /= aint(y)) then
         errno = .true.
         r = nan()
         return
      endif
      if (abs(y) < 9007199254740992._R8P) odd = mod(y, 2._R8P) /= 0._R8P
   endif
   lr = log(abs(x))
   if (abs(y) > DBL_MAX / max(1._R8P, abs(lr))) then
      lr = sign(DBL_MAX, y) * sign(1._R8P, lr)
   else
      lr = y * lr
   endif
   if (lr > EXP_INF) then
      errno = .true.
      ovf = .true.
      r = DBL_MAX
   elseif (lr < -800._R8P) then
      errno = .true.
      r = 0._R8P
   else
      r = abs(x) ** y
      if (r == 0._R8P) errno = .true.
   endif
   if (odd) r = -r
   endsubroutine pow_

   pure subroutine pow_inf(x, r, ovf)
   !< glibc's pow(x, +inf): 0 for |x| < 1, 1 for |x| = 1, +inf (`ovf`) above, without errno.
   real(R8P), value       :: x   !< Base (by value: r may be it).
   real(R8P), intent(inout) :: r !< pow(x, +inf) (inout: see mul_).
   logical,   intent(out) :: ovf !< +inf result.

   ovf = .false.
   if (abs(x) < 1._R8P) then
      r = 0._R8P
   elseif (abs(x) == 1._R8P) then
      r = 1._R8P
   else
      r = DBL_MAX
      ovf = .true.
   endif
   endsubroutine pow_inf

   pure subroutine exp_(x, r, errno, ovf)
   !< glibc's exp(x): errno on overflow and on underflow to 0.
   real(R8P), intent(in)    :: x     !< Argument.
   real(R8P), intent(out)   :: r     !< exp(x).
   logical,   intent(inout) :: errno !< errno.
   logical,   intent(out)   :: ovf   !< Overflow (r is then huge).

   ovf = .false.
   if (x > EXP_INF) then
      errno = .true.
      ovf = .true.
      r = DBL_MAX
   elseif (x <= EXP_ZERO) then
      errno = .true.
      r = 0._R8P
   else
      r = exp(x)
   endif
   endsubroutine exp_

   pure subroutine lgamma_(x, r, errno)
   !< glibc's lgamma(x) for x > 0: ERANGE (and a huge value) on overflow.
   real(R8P), intent(in)    :: x     !< Argument, positive.
   real(R8P), intent(out)   :: r     !< ln Gamma(x).
   logical,   intent(inout) :: errno !< errno.

   if (x > LGAMMA_MAX) then
      errno = .true.
      r = DBL_MAX
   else
      r = log_gamma(x)
   endif
   endsubroutine lgamma_

   pure subroutine mul_(a, b, r, bad)
   !< r = a * b; `bad` set (and r = 0) when the product overflows.
   real(R8P), value         :: a, b !< Factors (by value: r may be one of them).
   real(R8P), intent(inout) :: r    !< a * b (inout, not out: gfortran clobbers an intent(out) actual that is also a
                                    !< value actual of the same call before reading it).
   logical,   intent(inout) :: bad  !< Overflow flag.

   r = 0._R8P
   if (abs(a) > 1._R8P .and. abs(b) > 1._R8P) then
      if (abs(a) > DBL_MAX / abs(b)) then
         bad = .true.
         return
      endif
   endif
   r = a * b
   endsubroutine mul_

   pure subroutine add_(a, b, r, bad)
   !< r = a + b; `bad` set (and r = 0) when the sum overflows.
   real(R8P), value         :: a, b !< Addends (by value: r may be one of them).
   real(R8P), intent(inout) :: r    !< a + b (inout: see mul_).
   logical,   intent(inout) :: bad  !< Overflow flag.

   r = 0._R8P
   if (sign(1._R8P, a) == sign(1._R8P, b)) then
      if (abs(a) > DBL_MAX - abs(b)) then
         bad = .true.
         return
      endif
   endif
   r = a + b
   endsubroutine add_

   pure subroutine div_(a, b, r, bad)
   !< r = a / b; `bad` set (and r = 0) when b is 0 or the quotient overflows.
   real(R8P), value         :: a, b !< Dividend and divisor (by value: r may be one of them).
   real(R8P), intent(inout) :: r    !< a / b (inout: see mul_).
   logical,   intent(inout) :: bad  !< Overflow flag.

   r = 0._R8P
   if (b == 0._R8P) then
      bad = .true.
      return
   endif
   if (abs(b) < 1._R8P) then
      if (abs(a) > DBL_MAX * abs(b)) then
         bad = .true.
         return
      endif
   endif
   r = a / b
   endsubroutine div_

   pure subroutine ratio_(a, b, c, d, r, bad)
   !< r = (a b) / (c d) as C evaluates it: 0 when only c d overflows (finite / inf), `bad` when a b overflows.
   real(R8P), intent(in)    :: a, b, c, d !< Operands.
   real(R8P), intent(out)   :: r          !< (a b) / (c d).
   logical,   intent(inout) :: bad        !< Overflow flag.

   real(R8P) :: n, m  !< Numerator and denominator.
   logical   :: dovf  !< Denominator overflow.

   r = 0._R8P
   call mul_(a, b, n, bad)
   if (bad) return
   dovf = .false.
   call mul_(c, d, m, dovf)
   if (dovf) return
   call div_(n, m, r, bad)
   endsubroutine ratio_

   pure function quotient_or_inf(a, b) result(r)
   !< |a / b| for b /= 0, huge where C gets inf (the continued fractions' relative change test goes on).
   real(R8P), intent(in) :: a, b !< Dividend and nonzero divisor.
   real(R8P)             :: r    !< |a / b|.

   r = DBL_MAX
   if (abs(b) < 1._R8P) then
      if (abs(a) > DBL_MAX * abs(b)) return
   endif
   r = abs(a / b)
   endfunction quotient_or_inf

   ! private procedures: gnuplot's algorithms

   pure function polevl(x, coef, n) result(ans)
   !< Cephes polevl: coef(0) x**n + ... + coef(n).
   real(R8P),    intent(in) :: x         !< Argument.
   real(R8P),    intent(in) :: coef(0:)  !< Coefficients, highest degree first.
   integer(I4P), intent(in) :: n         !< Degree.
   real(R8P)                :: ans       !< Polynomial value.

   integer(I4P) :: i !< Counter.

   ans = coef(0)
   do i = 1_I4P, n
      ans = ans * x + coef(i)
   enddo
   endfunction polevl

   pure function p1evl(x, coef, n) result(ans)
   !< Cephes p1evl: x**n + coef(0) x**(n-1) + ... + coef(n-1).
   real(R8P),    intent(in) :: x         !< Argument.
   real(R8P),    intent(in) :: coef(0:)  !< Coefficients, leading 1 omitted.
   integer(I4P), intent(in) :: n         !< Degree.
   real(R8P)                :: ans       !< Polynomial value.

   integer(I4P) :: i !< Counter.

   ans = x + coef(0)
   do i = 1_I4P, n - 1_I4P
      ans = ans * x + coef(i)
   enddo
   endfunction p1evl

   pure function ndtri(y0) result(x)
   !< specfun.c inverse_normal_func (Cephes ndtri), for 0 < y0 < 1.
   real(R8P), intent(in) :: y0 !< Probability.
   real(R8P)             :: x  !< Normal quantile.

   real(R8P), parameter :: EXPM2 = 0.13533528323661269189_R8P !< exp(-2).
   real(R8P)            :: y, z, y2, x0, x1                  !< Work.
   logical              :: negate                            !< Lower tail (Cephes code = 1).

   negate = .true.
   y = y0
   if (y > (1._R8P - EXPM2)) then
      y = 1._R8P - y
      negate = .false.
   endif
   if (y > EXPM2) then
      y = y - 0.5_R8P
      y2 = y * y
      x = y + y * ((y2 * polevl(y2, NDTRI_P0, 4_I4P)) / p1evl(y2, NDTRI_Q0, 8_I4P))
      x = x * S2PI
      return
   endif
   x = sqrt(-2._R8P * log(y))
   x0 = x - log(x) / x
   z = 1._R8P / x
   if (x < 8._R8P) then
      x1 = (z * polevl(z, NDTRI_P1, 8_I4P)) / p1evl(z, NDTRI_Q1, 8_I4P)
   else
      x1 = (z * polevl(z, NDTRI_P2, 8_I4P)) / p1evl(z, NDTRI_Q2, 8_I4P)
   endif
   x = x0 - x1
   if (negate) x = -x
   endfunction ndtri

   pure function inverse_error_func(y) result(x)
   !< specfun.c inverse_error_func, for |y| < 1.
   real(R8P), intent(in) :: y !< Argument.
   real(R8P)             :: x !< Inverse error function.

   real(R8P), parameter :: Y0 = 0.7_R8P !< Central range.
   real(R8P)            :: z, k         !< Work.
   integer(I4P)         :: i            !< Counter.

   x = 0._R8P
   if (-1._R8P < y .and. y < -Y0) then
      z = sqrt(-log((1._R8P + y) / 2._R8P))
      x = -(((INVERF_C(3) * z + INVERF_C(2)) * z + INVERF_C(1)) * z + INVERF_C(0)) / &
          ((INVERF_D(1) * z + INVERF_D(0)) * z + 1._R8P)
   elseif (-Y0 <= y .and. y <= Y0) then
      z = y * y
      x = (y * (((INVERF_A(3) * z + INVERF_A(2)) * z + INVERF_A(1)) * z + INVERF_A(0))) / &
          ((((INVERF_B(3) * z + INVERF_B(3)) * z + INVERF_B(1)) * z + INVERF_B(0)) * z + 1._R8P)
   elseif (Y0 < y .and. y < 1._R8P) then
      z = sqrt(-log((1._R8P - y) / 2._R8P))
      x = (((INVERF_C(3) * z + INVERF_C(2)) * z + INVERF_C(1)) * z + INVERF_C(0)) / &
          ((INVERF_D(1) * z + INVERF_D(0)) * z + 1._R8P)
   endif
   k = 2._R8P / sqrt(PI)
   do i = 1_I4P, 4_I4P
      x = x - (erf(x) - y) / (k * exp(-x * x))
   enddo
   endfunction inverse_error_func

   pure subroutine lngamma_lanczos(z, f, ok)
   !< complexfun.c lnGamma for real z > 0 (14 term Lanczos, glibc clog); `ok` false when gnuplot gets +inf.
   real(R8P), intent(in)  :: z  !< Argument, positive.
   real(R8P), intent(out) :: f  !< ln Gamma(z).
   logical,   intent(out) :: ok !< Finite result.

   real(R8P)    :: s, temp, l, q !< Work.
   integer(I4P) :: k             !< Counter.

   ok = .true.
   f = 0._R8P
   s = LANCZOS(0)
   do k = 1_I4P, 14_I4P
      s = s + LANCZOS(k) / (z + real(k, R8P))
   enddo
   if (z == 1._R8P .or. z == 2._R8P) return
   temp = z + LANCZOS_G
   l = clog_re(temp)
   if (z + 0.5_R8P > DBL_MAX / l) then
      ok = .false.
      return
   endif
   temp = (z + 0.5_R8P) * l - temp
   q = LANCZOS_SQRT2PI * s
   if (z < 1._R8P) then
      if (q > DBL_MAX * z) then
         ok = .false.
         return
      endif
   endif
   f = temp + clog_re(q / z)
   endsubroutine lngamma_lanczos

   pure subroutine igamma_core(a, z, re, im, fail, nanres, errno, bad)
   !< complexfun.c Igamma(a, z) for real a > 0 and real z /= 0 (imaginary parts +0). Outcomes: a value in re, im;
   !< `fail`, Igamma's -1 (overflow or no convergence); `nanres`, a NaN; `bad`, an infinite value.
   real(R8P), intent(in)    :: a      !< Shape, positive.
   real(R8P), intent(in)    :: z      !< Argument, nonzero.
   real(R8P), intent(out)   :: re, im !< Result.
   logical,   intent(out)   :: fail   !< Igamma returned -1 (overflow or no convergence).
   logical,   intent(out)   :: nanres !< Igamma returned NaN.
   logical,   intent(inout) :: errno  !< errno (cleared on entry, as Igamma does).
   logical,   intent(out)   :: bad    !< Igamma returned an infinity.

   real(R8P)    :: ga1, l, u, w, ar, ai, aa, an, b, rn, rnold, pn1, pn2, pn3, pn4, pn5, pn6 !< Work.
   real(R8P)    :: inf_sign, p1, p2                                                      !< Work.
   integer(I4P) :: i, argcls                                                             !< Counter, class of arg.
   logical      :: ok, ovf, rnold_inf, cf_ovf                                            !< Flags.

   re = 0._R8P
   im = 0._R8P
   fail = .false.
   nanres = .false.
   bad = .false.
   errno = .false.
   if (z < 0._R8P .and. a < 75._R8P) then
      call igamma_negative_z(a, z, re, im, fail, errno, bad)
      return
   endif
   if (z > 0._R8P .and. a > 100._R8P) then
      if (abs(z - a) / a < 0.2_R8P) then
         call igamma_gl(a, z, re, nanres, errno, bad)
         return
      endif
   endif
   ! arg = cexp(a clog(z) - z - lnGamma(a + 1)), class 0 finite, 1 infinite, 2 NaN; an exponent of -inf gives 0
   ar = 0._R8P
   ai = 0._R8P
   argcls = 0_I4P
   call lngamma_lanczos(a + 1._R8P, ga1, ok)
   l = clog_re(z)
   w = 0._R8P
   if (z < 0._R8P) then
      if (a > DBL_MAX / PI) then
         argcls = 3_I4P ! infinite imaginary part: cexp gives NaN, or 0 for a real part of -inf
      else
         w = a * PI
      endif
   endif
   if (a > DBL_MAX / max(1._R8P, abs(l))) then
      inf_sign = sign(1._R8P, l) ! a l overflows
   elseif (.not. ok) then
      inf_sign = -1._R8P ! - ga1 = -inf
   else
      inf_sign = 0._R8P
      u = a * l
      if (z < 0._R8P) then
         if (u > DBL_MAX + z) inf_sign = 1._R8P
      else
         if (u < -DBL_MAX + z) inf_sign = -1._R8P
      endif
      if (inf_sign == 0._R8P) then
         u = u - z
         if (ga1 > 0._R8P) then
            if (u < -DBL_MAX + ga1) inf_sign = -1._R8P
         endif
         if (inf_sign == 0._R8P) u = u - ga1
      endif
   endif
   if (inf_sign < 0._R8P) then
      argcls = 0_I4P ! cexp(-inf + i w) = 0
   elseif (inf_sign > 0._R8P .or. argcls == 3_I4P) then
      argcls = 2_I4P ! +inf - inf(lnGamma), cexp(+inf), cexp(u + i inf)
   else
      call cexp_(u, w, ar, ai, errno, ovf)
      if (ovf) argcls = 1_I4P
   endif
   if (abs(z) > 1._R8P .and. abs(z) >= a + 2._R8P) then
      ! continued fraction; an errno left by cexp survives to evaluate_at: undefined whatever the fraction gives
      if (errno) return
      ! an infinity in the fraction never converges again: gnuplot ends with "Igamma: overflow" or no convergence
      cf_ovf = .false.
      rnold_inf = .false.
      aa = 1._R8P - a
      b = (aa + z) + 1._R8P
      pn1 = 1._R8P
      pn2 = z
      pn3 = z + 1._R8P
      call mul_(z, b, pn4, cf_ovf)
      if (cf_ovf) then
         fail = .true.
         return
      endif
      rnold = pn3 / pn4
      do i = 1_I4P, 2000_I4P
         aa = aa + 1._R8P
         b = b + 2._R8P
         an = aa * real(i, R8P)
         call mul_(b, pn3, p1, cf_ovf)
         call mul_(an, pn1, p2, cf_ovf)
         call add_(p1, -p2, pn5, cf_ovf)
         call mul_(b, pn4, p1, cf_ovf)
         call mul_(an, pn2, p2, cf_ovf)
         call add_(p1, -p2, pn6, cf_ovf)
         if (cf_ovf) exit
         if (pn6 /= 0._R8P) then
            call div_(pn5, pn6, rn, cf_ovf)
            if (cf_ovf) then
               cf_ovf = .false.
               rnold_inf = .true.
            else
               if (.not. rnold_inf) then
                  if (abs(rnold - rn) <= min(IGAMMA_PRECISION, IGAMMA_PRECISION * abs(rn))) then
                     select case (argcls)
                     case (1_I4P)
                        bad = .true.
                     case (2_I4P)
                        nanres = .true.
                     case default
                        call mul_(ar, rn, p1, bad)
                        call mul_(p1, a, p2, bad)
                        re = 1._R8P - p2
                        call mul_(ai, rn, p1, bad)
                        call mul_(p1, a, p2, bad)
                        im = -p2
                     endselect
                     return
                  endif
               endif
               rnold = rn
               rnold_inf = .false.
            endif
         endif
         pn1 = pn3
         pn2 = pn4
         pn3 = pn5
         pn4 = pn6
         if (abs(pn5) >= FLT_MAX) then
            pn1 = pn1 / FLT_MAX
            pn2 = pn2 / FLT_MAX
            pn3 = pn3 / FLT_MAX
            pn4 = pn4 / FLT_MAX
         endif
      enddo
   else
      ! Pearson's series; handle_underflow(an) clears an errno left by cexp (arg is then 0)
      aa = a
      an = 1._R8P
      b = 1._R8P
      do i = 0_I4P, 1000_I4P
         aa = aa + 1._R8P
         an = an * (z / aa)
         if (errno) then
            an = 0._R8P
            errno = .false.
         endif
         b = b + an
         if (abs(an) < abs(b) * IGAMMA_PRECISION) then
            select case (argcls)
            case (1_I4P)
               bad = .true.
            case (2_I4P)
               nanres = .true.
            case default
               re = ar * b
               im = ai * b
            endselect
            return
         endif
      enddo
   endif
   fail = .true.
   endsubroutine igamma_core

   pure subroutine igamma_gl(a, z, re, nanres, errno, bad)
   !< complexfun.c Igamma_GL, 18 point Gauss-Legendre quadrature, for real a > 100 and real z > 0.
   real(R8P), intent(in)    :: a     !< Shape.
   real(R8P), intent(in)    :: z     !< Argument.
   real(R8P), intent(out)   :: re     !< Result.
   logical,   intent(out)   :: nanres !< NaN result.
   logical,   intent(inout) :: errno  !< errno.
   logical,   intent(out)   :: bad    !< Infinite result.

   real(R8P)    :: a1, lna1, sqrta1, xu, t, e, s, ans, lng, v, ev, ci !< Work.
   integer(I4P) :: j                                                  !< Counter.
   logical      :: ok, ovf, s_inf, ev_inf                             !< Flags.

   bad = .false.
   nanres = .false.
   re = 0._R8P
   a1 = a - 1._R8P
   lna1 = clog_re(a1)
   sqrta1 = sqrt(a1)
   if (z > a1) then
      call add_(z, 6._R8P * sqrta1, xu, bad)
      xu = max(abs(a1 + 11.5_R8P * sqrta1), abs(xu))
   else
      xu = min(abs(a1 - 7.5_R8P * sqrta1), abs(z - 5._R8P * sqrta1))
   endif
   if (bad) return
   ! all 18 nodes run (each cexp may set errno); an infinite node makes the sum infinite
   s = 0._R8P
   s_inf = .false.
   do j = 1_I4P, 18_I4P
      t = z + (xu - z) * GL_Y(j)
      call mul_(a1, clog_re(t) - lna1, e, bad)
      if (bad) then
         bad = .false.
         if (clog_re(t) > lna1) s_inf = .true. ! cexp(+inf); cexp(-inf) = 0
         cycle
      endif
      e = -(t - a1) + e
      call cexp_(e, 0._R8P, ev, ci, errno, ovf)
      if (ovf) then
         s_inf = .true.
      elseif (.not. s_inf) then
         call add_(s, GL_W(j) * ev, s, s_inf)
      endif
   enddo
   ! cexp(a1 (lna1 - 1) - lnGamma(a)): lnGamma(a) = +inf gives 0, unless a1 (lna1 - 1) is +inf too (NaN)
   call lngamma_lanczos(a, lng, ok)
   call mul_(a1, lna1 - 1._R8P, v, bad)
   if (bad) then
      nanres = .true.
      return
   endif
   ev_inf = .false.
   if (ok) then
      v = v - lng
      call cexp_(v, 0._R8P, ev, ci, errno, ovf)
      ev_inf = ovf
   else
      ev = 0._R8P
   endif
   ! ans = s (xu - z) ev: inf 0 is NaN, inf finite is inf
   if (s_inf .or. ev_inf) then
      if ((s_inf .and. ev == 0._R8P .and. .not. ev_inf) .or. (ev_inf .and. s == 0._R8P .and. .not. s_inf)) then
         nanres = .true.
      else
         bad = .true.
      endif
      return
   endif
   call mul_(s, xu - z, ans, bad)
   call mul_(ans, ev, ans, bad)
   if (bad) return
   if (z > a1) then
      re = 1._R8P - ans
   else
      re = -ans
   endif
   endsubroutine igamma_gl

   pure subroutine igamma_negative_z(a, z, re, im, fail, errno, bad)
   !< complexfun.c Igamma_negative_z (A&S 6.5.29), for real 0 < a < 75 and real z < 0 (imaginary part +0).
   real(R8P), intent(in)    :: a      !< Shape.
   real(R8P), intent(in)    :: z      !< Argument, negative.
   real(R8P), intent(out)   :: re, im !< Result.
   logical,   intent(out)   :: fail  !< Overflow (gnuplot returns -1).
   logical,   intent(inout) :: errno !< errno.
   logical,   intent(out)   :: bad   !< gnuplot's result is not finite.

   real(R8P)    :: t, v, p, q, l, u, cr, ci, lng, e, pr, pim !< Work.
   integer(I4P) :: k                                         !< Counter.
   logical      :: ok, ovf                                   !< Flags.

   re = 0._R8P
   im = 0._R8P
   fail = .false.
   bad = .false.
   if (inv_overflows(a)) then
      fail = .true.
      return
   endif
   t = 1._R8P / a
   v = t
   do k = 0_I4P, 999_I4P
      p = (a + real(k, R8P)) / ((a + real(k, R8P)) + 1._R8P)
      q = (-z * p) / real(k + 1_I4P, R8P)
      if (abs(t) > DBL_MAX / max(1._R8P, abs(q))) then
         fail = .true.
         return
      endif
      t = t * q
      if (.not. (abs(t) < VERYLARGE)) then
         fail = .true.
         return
      endif
      call add_(v, t, v, bad)
      if (bad) return ! v = inf: t / v = 0 ends the loop, the result is infinite
      if (abs(t / v) < IGAMMA_PRECISION) exit
   enddo
   ! t = v * cpow(z, a) / cexp(lnGamma(a)), cpow(z, a) = cexp(a clog(z))
   l = clog_re(z)
   call mul_(a, l, u, bad)
   if (bad) return
   call cexp_(u, a * PI, cr, ci, errno, ovf)
   if (ovf) then
      bad = .true.
      return
   endif
   call lngamma_lanczos(a, lng, ok)
   if (.not. ok) return ! v cpow / cexp(+inf) = 0
   call cexp_(lng, 0._R8P, e, pim, errno, ovf)
   if (ovf) then
      bad = .true.
      return
   endif
   call mul_(v, cr, pr, bad)
   call mul_(v, ci, pim, bad)
   if (bad) return
   call div_(pr, e, re, bad)
   call div_(pim, e, im, bad)
   endsubroutine igamma_negative_z

   pure subroutine igamma_re(a, z, re, fail, nanres, errno, bad)
   !< complexfun.c igamma(a, z) wrapper, creal(Igamma(a, z)), for real a > 0 and z >= 0 (-1 when Igamma fails).
   real(R8P), intent(in)    :: a      !< Shape.
   real(R8P), intent(in)    :: z      !< Argument.
   real(R8P), intent(out)   :: re     !< Real part.
   logical,   intent(out)   :: fail   !< Igamma returned -1 (re is -1).
   logical,   intent(out)   :: nanres !< Igamma returned NaN.
   logical,   intent(inout) :: errno  !< errno.
   logical,   intent(out)   :: bad    !< Igamma returned an infinity.

   real(R8P) :: im !< Imaginary part.

   fail = .false.
   nanres = .false.
   bad = .false.
   if (z == 0._R8P) then
      re = 0._R8P
      return
   endif
   call igamma_core(a=a, z=z, re=re, im=im, fail=fail, nanres=nanres, errno=errno, bad=bad)
   if (fail) re = -1._R8P
   endsubroutine igamma_re

   pure subroutine igamc(a, x, r, status)
   !< specfun.c igamc (Cephes), the complemented incomplete gamma, for a > 0 and x >= 0.
   real(R8P),    intent(in)  :: a      !< Shape.
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Q(a, x).
   integer(I4P), intent(out) :: status !< 0 defined, 1 undefined.

   real(R8P)    :: ax, c, yc, rr, t, y, z, pk, pkm1, pkm2, qk, qkm1, qkm2, ans, lg, ig !< Work.
   real(R8P)    :: e, p1, p2                                                         !< Work.
   logical      :: errno, bad, fail, nanres, ovf                                     !< Flags.
   integer(I8P) :: n                                                                 !< Iterations.

   r = 0._R8P
   status = 1_I4P
   errno = .false.
   bad = .false.
   if (x < 1._R8P .or. x < a) then
      call igamma_re(a, x, ig, fail, nanres, errno, bad)
      if (bad) return
      if (nanres) then
         r = nan()
      else
         r = 1._R8P - ig
      endif
      if (.not. errno) status = 0_I4P
      return
   endif
   call lgamma_(a, lg, errno)
   if (errno) return
   call mul_(a, log(x), ax, bad)
   if (bad) then
      r = nan() ! ax = +inf, exp(inf) = inf without errno, and the fraction ends in NaN
      status = 0_I4P
      return
   endif
   ax = (ax - x) - lg
   if (ax < -MAXLOG) then
      r = 0._R8P
      status = 0_I4P
      return
   endif
   call exp_(ax, e, errno, ovf)
   ax = e
   if (errno) return
   y = 1._R8P - a
   z = (x + y) + 1._R8P
   c = 0._R8P
   pkm2 = 1._R8P
   qkm2 = x
   pkm1 = x + 1._R8P
   call mul_(z, x, qkm1, bad)
   if (bad) then
      r = nan() ! an infinity in the fraction ends in NaN
      status = 0_I4P
      return
   endif
   ans = pkm1 / qkm1
   n = 0_I8P
   do
      c = c + 1._R8P
      y = y + 1._R8P
      z = z + 2._R8P
      yc = y * c
      call mul_(pkm1, z, p1, bad)
      call mul_(pkm2, yc, p2, bad)
      call add_(p1, -p2, pk, bad)
      call mul_(qkm1, z, p1, bad)
      call mul_(qkm2, yc, p2, bad)
      call add_(p1, -p2, qk, bad)
      if (.not. bad .and. qk /= 0._R8P) call div_(pk, qk, rr, bad)
      if (bad) then
         r = nan() ! an infinity in the fraction ends in NaN
         status = 0_I4P
         return
      endif
      if (qk /= 0._R8P) then
         if (rr == 0._R8P) then
            if (ans == 0._R8P) exit ! (0 - 0) / 0 is NaN: the C loop ends
            t = DBL_MAX ! (ans - 0) / 0 is inf: go on
         else
            call div_(ans - rr, rr, t, bad)
            if (bad) then
               bad = .false.
               t = DBL_MAX ! inf in C: go on
            endif
            t = abs(t)
         endif
         ans = rr
      else
         t = 1._R8P
      endif
      pkm2 = pkm1
      pkm1 = pk
      qkm2 = qkm1
      qkm1 = qk
      if (abs(pk) > BIG) then
         pkm2 = pkm2 * BIGINV
         pkm1 = pkm1 * BIGINV
         qkm2 = qkm2 * BIGINV
         qkm1 = qkm1 * BIGINV
      endif
      if (.not. (t > MACHEP)) exit
      n = n + 1_I8P
      if (n > 100000000_I8P) return ! gnuplot has no limit: give up as undefined instead of hanging
   enddo
   r = ans * ax
   status = 0_I4P
   endsubroutine igamc

   pure subroutine inverse_incomplete_gamma(a, p, z, status)
   !< specfun.c inverse_incomplete_gamma, Halley's method on igamma, for a > 0 and 0 < p < 1.
   real(R8P),    intent(in)  :: a      !< Shape.
   real(R8P),    intent(in)  :: p      !< Probability.
   real(R8P),    intent(out) :: z      !< Root.
   integer(I4P), intent(out) :: status !< 0 defined, 1 undefined.

   real(R8P), parameter :: EPS = 1.4901161193847656e-08_R8P    !< sqrt(MACHEP).
   real(R8P)            :: t, err, lngamma_a, afac, pp, ig, v, e !< Work.
   integer(I4P)         :: j, tcls, qcls, afac_cls               !< Counter; classes of t, q, afac (0, 1 +inf, 2 NaN).
   logical              :: errno, bad, fail, nanres, ovf, lng_inf, v_inf, nan_out !< Flags.

   z = 0._R8P
   status = 1_I4P
   errno = .false.
   bad = .false.
   nan_out = .false.
   ! lngamma_a = lgamma(a), +inf (ERANGE) beyond LGAMMA_MAX
   call lgamma_(a, lngamma_a, errno)
   lng_inf = errno
   ! afac = exp((a-1) (log(a-1) - 1) - lngamma_a): log(a-1) sets EDOM for a < 1, ERANGE for a = 1 (afac unused there)
   afac = 0._R8P
   afac_cls = 0_I4P
   if (a <= 1._R8P) then
      errno = .true.
   else
      v_inf = .false.
      call mul_(a - 1._R8P, log(a - 1._R8P) - 1._R8P, v, v_inf)
      if (v_inf .and. lng_inf) then
         afac_cls = 2_I4P ! inf - inf
      elseif (v_inf) then
         afac_cls = 1_I4P ! exp(+inf), no errno
      elseif (.not. lng_inf) then
         call exp_(v - lngamma_a, afac, errno, ovf)
         if (ovf) afac_cls = 1_I4P
      endif ! else exp(-inf) = 0, no errno
   endif
   ! initial guess
   if (a > 1._R8P) then
      if (p < 0.5_R8P) then
         pp = p
      else
         pp = 1._R8P - p
      endif
      t = sqrt(-2._R8P * log(pp))
      z = t - (2.30753_R8P + 0.27061_R8P * t) / ((1._R8P + 0.99229_R8P * t) + (0.04481_R8P * t) * t)
      if (p < 0.5_R8P) z = -z
      if (a > DBL_MAX / 9._R8P) then
         t = 1._R8P ! 2 / (9 a) = 2 / inf = 0
      else
         call pow_((1._R8P - 2._R8P / (9._R8P * a)) + z * sqrt(2._R8P / (9._R8P * a)), 3._R8P, t, errno, ovf)
         if (ovf) return
      endif
      call mul_(a, t, z, bad)
      if (bad) return
   else
      t = 1._R8P - a * (0.253_R8P + a * 0.12_R8P)
      if (inv_overflows(a)) return ! pow(p/t, inf) = 0, and log(a-1) already set EDOM
      if (p < t) then
         call pow_(p / t, 1._R8P / a, z, errno, ovf)
         if (ovf) return
      else
         v = 1._R8P - (p - t) / (1._R8P - t)
         if (v <= 0._R8P) return ! log(0): ERANGE
         z = 1._R8P - log(v)
      endif
   endif
   ! Halley's method
   do j = 0_I4P, 11_I4P
      if (z <= 0._R8P) then
         z = 0._R8P
         if (.not. errno) status = 0_I4P
         return
      endif
      call igamma_re(a, z, ig, fail, nanres, errno, bad)
      nan_out = bad .or. nanres
      bad = .false.
      err = ig - p
      tcls = 0_I4P
      if (a > 1._R8P) then
         call mul_(a - 1._R8P, log(z) - log(a - 1._R8P), v, bad)
         if (bad) then
            ! exponent +-inf: exp gives +inf or 0 without errno; t = afac inf goes on, 0 or NaN turns the step NaN
            bad = .false.
            if (log(z) > log(a - 1._R8P) .and. (afac_cls == 1_I4P .or. (afac_cls == 0_I4P .and. afac > 0._R8P))) then
               tcls = 1_I4P
            else
               nan_out = .true.
            endif
         else
            v = -(z - (a - 1._R8P)) + v
            call exp_(v, e, errno, ovf)
            if (ovf) return
         endif
         if (tcls == 0_I4P .and. .not. nan_out) then
            if (afac_cls == 2_I4P) then
               nan_out = .true.
            elseif (afac_cls == 1_I4P) then
               tcls = 1_I4P ! inf * e, e > 0 (e = 0 has errno set)
            else
               call mul_(afac, e, t, bad)
               if (bad) then
                  bad = .false.
                  tcls = 1_I4P
               endif
            endif
         endif
      else
         call mul_(a - 1._R8P, log(z), v, bad)
         if (bad) then
            nan_out = .true.
            exit
         endif
         v = (-z + v) - lngamma_a
         call exp_(v, t, errno, ovf)
         if (ovf) return
      endif
      if (errno) return ! gnuplot: warning, z = NaN, undefined
      if (nan_out) exit
      call div_(a - 1._R8P, z, v, bad)
      qcls = 0_I4P
      if (bad) then
         bad = .false.
         qcls = int(sign(1._R8P, a - 1._R8P), I4P)
      else
         v = v - 1._R8P
      endif
      call halley_step(err, t, tcls, v, qcls, e, nan_out)
      if (nan_out) exit
      t = e
      call add_(z, -t, z, nan_out)
      if (nan_out) exit
      if (z <= 0._R8P) z = 0.5_R8P * (z + t)
      if (abs(t) < z * EPS) exit
   enddo
   if (nan_out) then
      ! a NaN step: z stays NaN through the remaining iterations, which set no errno
      z = nan()
      if (errno) return
   endif
   if (.not. errno) status = 0_I4P
   endsubroutine inverse_incomplete_gamma

   pure subroutine halley_step(err, t, tcls, q, qcls, tn, nonfinite)
   !< gnuplot's Halley step tn = u / (1 - 0.5 min(1, u q)), u = err / t, with C's infinities: t is +inf for tcls 1,
   !< q is +-inf for qcls +-1 and NaN for qcls 2. `nonfinite` when tn is not finite (gnuplot's z then turns NaN).
   real(R8P),    intent(in)  :: err       !< Residual.
   real(R8P),    intent(in)  :: t         !< Derivative, >= 0.
   integer(I4P), intent(in)  :: tcls      !< Class of t: 0 finite, 1 +inf.
   real(R8P),    intent(in)  :: q         !< Second order factor.
   integer(I4P), intent(in)  :: qcls      !< Class of q: 0 finite, +-1 +-inf, 2 NaN.
   real(R8P),    intent(out) :: tn        !< Step.
   logical,      intent(out) :: nonfinite !< Step not finite.

   real(R8P)    :: u, m !< Work.
   integer(I4P) :: mcls !< Class of u q.
   logical      :: bad  !< Overflow.

   tn = 0._R8P
   nonfinite = .true.
   bad = .false.
   ! u = err / t: inf / NaN when t is 0, 0 when t is +inf
   if (tcls == 1_I4P) then
      u = 0._R8P
   else
      call div_(err, t, u, bad)
      if (bad) return
   endif
   ! m = u q
   if (qcls == 2_I4P) return
   if (qcls /= 0_I4P) then
      if (u == 0._R8P) return
      mcls = qcls * int(sign(1._R8P, u), I4P)
   else
      mcls = 0_I4P
      call mul_(u, q, m, bad)
      if (bad) mcls = int(sign(1._R8P, u) * sign(1._R8P, q), I4P)
      bad = .false.
   endif
   if (mcls == 1_I4P) then
      call div_(u, 0.5_R8P, tn, bad) ! min(1, +inf) = 1
      if (bad) return
   elseif (mcls == -1_I4P) then
      tn = 0._R8P ! u / inf
   else
      call div_(u, 1._R8P - 0.5_R8P * min(1._R8P, m), tn, bad)
      if (bad) return
   endif
   nonfinite = .false.
   endsubroutine halley_step

   pure subroutine incbet(aa, bb, xx, t, errno, bad, nanres)
   !< specfun.c incbet (Cephes): -1 for aa <= 0, bb <= 0 or xx outside [0, 1]; `bad` when gnuplot's result is
   !< infinite, `nanres` when it is NaN (a continued fraction overflowing).
   real(R8P), intent(in)    :: aa, bb, xx !< Shapes and argument.
   real(R8P), intent(out)   :: t          !< I_xx(aa, bb).
   logical,   intent(inout) :: errno      !< errno.
   logical,   intent(out)   :: bad        !< Infinite result.
   logical,   intent(out)   :: nanres     !< NaN result.

   real(R8P) :: a, b, x, xc, w, y, ratio, g, pa, px, lab, la, lb !< Work.
   logical   :: reflection, ovf, yinf                            !< Flags.

   bad = .false.
   nanres = .false.
   t = -1._R8P
   if (aa <= 0._R8P .or. bb <= 0._R8P) return
   if (xx <= 0._R8P .or. xx >= 1._R8P) then
      if (xx == 0._R8P) t = 0._R8P
      if (xx == 1._R8P) t = 1._R8P
      return
   endif
   t = 0._R8P
   reflection = .false.
   if (bb * xx <= 1._R8P .and. xx <= 0.95_R8P) then
      call pseries(aa, bb, xx, t, errno, bad)
      return
   endif
   w = 1._R8P - xx
   if (aa > DBL_MAX - bb) then
      ratio = 0._R8P ! aa / inf
   else
      ratio = aa / (aa + bb)
   endif
   if (xx > ratio) then
      reflection = .true.
      a = bb
      b = aa
      xc = xx
      x = w
   else
      a = aa
      b = bb
      xc = w
      x = xx
   endif
   if (reflection .and. b * x <= 1._R8P .and. x <= 0.95_R8P) then
      call pseries(a, b, x, t, errno, bad)
      if (bad) return
   else
      ! an overflow inside the continued fractions (or a + b = inf) ends in NaN, after lgamma's errno, if any
      call add_(a, b, y, nanres)
      if (.not. nanres) then
         y = x * (y - 2._R8P) - (a - 1._R8P)
         if (y < 0._R8P) then
            call incbcf(a, b, x, w, nanres)
         else
            call incbd(a, b, x, w, nanres)
            w = w / xc
         endif
      endif
      if (nanres) then
         if (a > DBL_MAX - b) then
            if (a > LGAMMA_MAX .or. b > LGAMMA_MAX) errno = .true. ! lgamma(a + b = inf) sets none
         elseif (a + b > LGAMMA_MAX) then
            errno = .true. ! the lgamma branch (a + b >= MAXGAM) overflows
         endif
         return
      endif
      ! y = a log(x), t = b log(xc): -inf when they overflow, and then the result is 0
      yinf = .false.
      call mul_(a, log(x), y, yinf)
      call mul_(b, log(xc), t, yinf)
      if (yinf) then
         call lgamma_(a + b, lab, errno)
         call lgamma_(a, la, errno)
         call lgamma_(b, lb, errno)
         t = 0._R8P
      elseif ((a + b) < MAXGAM .and. abs(y) < MAXLOG .and. abs(t) < MAXLOG) then
         call pow_(xc, b, t, errno, ovf)
         call pow_(x, a, px, errno, ovf)
         t = t * px
         if (inv_overflows(a) .or. inv_overflows(b)) then
            errno = .true. ! tgamma overflows
            return
         endif
         call div_(t, a, t, bad)
         call mul_(t, w, t, bad)
         if (bad) return
         g = gamma(a) ! a, b, a + b < MAXGAM: finite
         pa = gamma(b)
         if (g > DBL_MAX / max(1._R8P, pa)) then
            g = 0._R8P ! tgamma(a + b) / inf
         else
            g = gamma(a + b) / (g * pa)
         endif
         call mul_(t, g, t, bad)
         if (bad) return
      else
         call lgamma_(a + b, lab, errno)
         call lgamma_(a, la, errno)
         call lgamma_(b, lb, errno)
         if (errno) return
         y = y + (((t + lab) - la) - lb)
         if (w <= 0._R8P) then
            errno = .true. ! log of w <= 0
            return
         endif
         call div_(w, a, la, bad)
         if (bad) return
         y = y + log(la)
         if (y < MINLOG) then
            t = 0._R8P
         else
            call exp_(y, t, errno, ovf)
            if (ovf) return
         endif
      endif
   endif
   if (reflection) then
      if (t <= MACHEP) then
         t = 1._R8P - MACHEP
      else
         t = 1._R8P - t
      endif
   endif
   endsubroutine incbet

   pure subroutine incbcf(a, b, x, ans, bad)
   !< specfun.c incbcf, continued fraction expansion #1 for the incomplete beta integral.
   real(R8P), intent(in)    :: a, b, x !< Shapes and argument.
   real(R8P), intent(out)   :: ans     !< Continued fraction.
   logical,   intent(inout) :: bad     !< Overflow flag.

   real(R8P)    :: xk, pk, pkm1, pkm2, qk, qkm1, qkm2, k1, k2, k3, k4, k5, k6, k7, k8, r, t, thresh !< Work.
   real(R8P)    :: p1                                                                        !< Work.
   integer(I4P) :: n                                                                             !< Counter.

   k1 = a
   call add_(a, b, k2, bad)
   k3 = a
   k4 = a + 1._R8P
   k5 = 1._R8P
   k6 = b - 1._R8P
   k7 = k4
   k8 = a + 2._R8P
   pkm2 = 0._R8P
   qkm2 = 1._R8P
   pkm1 = 1._R8P
   qkm1 = 1._R8P
   ans = 1._R8P
   r = 1._R8P
   thresh = 3._R8P * MACHEP
   if (bad) return
   do n = 0_I4P, 299_I4P
      call ratio_(x * k1, k2, k3, k4, xk, bad)
      xk = -xk
      call mul_(pkm2, xk, p1, bad)
      call add_(pkm1, p1, pk, bad)
      call mul_(qkm2, xk, p1, bad)
      call add_(qkm1, p1, qk, bad)
      pkm2 = pkm1
      pkm1 = pk
      qkm2 = qkm1
      qkm1 = qk
      call ratio_(x * k5, k6, k7, k8, xk, bad)
      call mul_(pkm2, xk, p1, bad)
      call add_(pkm1, p1, pk, bad)
      call mul_(qkm2, xk, p1, bad)
      call add_(qkm1, p1, qk, bad)
      pkm2 = pkm1
      pkm1 = pk
      qkm2 = qkm1
      qkm1 = qk
      if (bad) return
      if (qk /= 0._R8P) call div_(pk, qk, r, bad)
      if (bad) return
      if (r /= 0._R8P) then
         t = quotient_or_inf(ans - r, r)
         ans = r
      else
         t = 1._R8P
      endif
      if (t < thresh) return
      k1 = k1 + 1._R8P
      k2 = k2 + 1._R8P
      k3 = k3 + 2._R8P
      k4 = k4 + 2._R8P
      k5 = k5 + 1._R8P
      k6 = k6 - 1._R8P
      k7 = k7 + 2._R8P
      k8 = k8 + 2._R8P
      if ((abs(qk) + abs(pk)) > BIG) then
         pkm2 = pkm2 * BIGINV
         pkm1 = pkm1 * BIGINV
         qkm2 = qkm2 * BIGINV
         qkm1 = qkm1 * BIGINV
      endif
      if ((abs(qk) < BIGINV) .or. (abs(pk) < BIGINV)) then
         pkm2 = pkm2 * BIG
         pkm1 = pkm1 * BIG
         qkm2 = qkm2 * BIG
         qkm1 = qkm1 * BIG
      endif
   enddo
   endsubroutine incbcf

   pure subroutine incbd(a, b, x, ans, bad)
   !< specfun.c incbd, continued fraction expansion #2 for the incomplete beta integral.
   real(R8P), intent(in)    :: a, b, x !< Shapes and argument.
   real(R8P), intent(out)   :: ans     !< Continued fraction.
   logical,   intent(inout) :: bad     !< Overflow flag.

   real(R8P)    :: xk, pk, pkm1, pkm2, qk, qkm1, qkm2, k1, k2, k3, k4, k5, k6, k7, k8, r, t, z, thresh !< Work.
   real(R8P)    :: p1                                                                           !< Work.
   integer(I4P) :: n                                                                                !< Counter.

   k1 = a
   k2 = b - 1._R8P
   k3 = a
   k4 = a + 1._R8P
   k5 = 1._R8P
   call add_(a, b, k6, bad)
   k7 = a + 1._R8P
   k8 = a + 2._R8P
   pkm2 = 0._R8P
   qkm2 = 1._R8P
   pkm1 = 1._R8P
   qkm1 = 1._R8P
   call div_(x, 1._R8P - x, z, bad)
   ans = 1._R8P
   r = 1._R8P
   thresh = 3._R8P * MACHEP
   if (bad) return
   do n = 0_I4P, 299_I4P
      call mul_(z, k1, p1, bad)
      call ratio_(p1, k2, k3, k4, xk, bad)
      xk = -xk
      call mul_(pkm2, xk, p1, bad)
      call add_(pkm1, p1, pk, bad)
      call mul_(qkm2, xk, p1, bad)
      call add_(qkm1, p1, qk, bad)
      pkm2 = pkm1
      pkm1 = pk
      qkm2 = qkm1
      qkm1 = qk
      call mul_(z, k5, p1, bad)
      call ratio_(p1, k6, k7, k8, xk, bad)
      call mul_(pkm2, xk, p1, bad)
      call add_(pkm1, p1, pk, bad)
      call mul_(qkm2, xk, p1, bad)
      call add_(qkm1, p1, qk, bad)
      pkm2 = pkm1
      pkm1 = pk
      qkm2 = qkm1
      qkm1 = qk
      if (bad) return
      if (qk /= 0._R8P) call div_(pk, qk, r, bad)
      if (bad) return
      if (r /= 0._R8P) then
         t = quotient_or_inf(ans - r, r)
         ans = r
      else
         t = 1._R8P
      endif
      if (t < thresh) return
      k1 = k1 + 1._R8P
      k2 = k2 - 1._R8P
      k3 = k3 + 2._R8P
      k4 = k4 + 2._R8P
      k5 = k5 + 1._R8P
      k6 = k6 + 1._R8P
      k7 = k7 + 2._R8P
      k8 = k8 + 2._R8P
      if ((abs(qk) + abs(pk)) > BIG) then
         pkm2 = pkm2 * BIGINV
         pkm1 = pkm1 * BIGINV
         qkm2 = qkm2 * BIGINV
         qkm1 = qkm1 * BIGINV
      endif
      if ((abs(qk) < BIGINV) .or. (abs(pk) < BIGINV)) then
         pkm2 = pkm2 * BIG
         pkm1 = pkm1 * BIG
         qkm2 = qkm2 * BIG
         qkm1 = qkm1 * BIG
      endif
   enddo
   endsubroutine incbd

   pure subroutine pseries(a, b, x, s, errno, bad)
   !< specfun.c pseries, power series for the incomplete beta integral (b x small, x not near 1).
   real(R8P), intent(in)    :: a, b, x !< Shapes and argument.
   real(R8P), intent(out)   :: s       !< Series value.
   logical,   intent(inout) :: errno   !< errno.
   logical,   intent(out)   :: bad     !< gnuplot's result is not finite.

   real(R8P) :: t, u, v, n, t1, z, ai, g, ga, gb, px, lab, la, lb !< Work.
   logical   :: ovf                                              !< Overflow.

   bad = .false.
   s = 0._R8P
   if (inv_overflows(a)) then
      bad = .true. ! 1/a = inf
      return
   endif
   ai = 1._R8P / a
   u = (1._R8P - b) * x
   v = u / (a + 1._R8P)
   t1 = v
   t = u
   n = 2._R8P
   s = 0._R8P
   z = MACHEP * ai
   do while (abs(v) > z)
      u = ((n - b) * x) / n
      t = t * u
      v = t / (a + n)
      s = s + v
      n = n + 1._R8P
   enddo
   s = s + t1
   s = s + ai
   call mul_(a, log(x), u, bad)
   if (bad) then
      ! u = -inf: t = ... + u + log(s) = -inf < MINLOG, s = 0
      bad = .false.
      call lgamma_(a + b, lab, errno)
      call lgamma_(a, la, errno)
      call lgamma_(b, lb, errno)
      s = 0._R8P
      return
   endif
   call add_(a, b, v, bad)
   if (bad) return
   if (v < MAXGAM .and. abs(u) < MAXLOG) then
      if (inv_overflows(a) .or. inv_overflows(b)) then
         errno = .true. ! tgamma overflows
         return
      endif
      ga = gamma(a)
      gb = gamma(b)
      if (ga > DBL_MAX / max(1._R8P, gb)) then
         g = 0._R8P ! tgamma(a + b) / inf
      else
         g = gamma(a + b) / (ga * gb)
      endif
      call pow_(x, a, px, errno, ovf)
      call mul_(s, g, s, bad)
      call mul_(s, px, s, bad)
   else
      call lgamma_(a + b, lab, errno)
      call lgamma_(a, la, errno)
      call lgamma_(b, lb, errno)
      if (errno) return
      if (s <= 0._R8P) then
         errno = .true. ! log of s <= 0
         return
      endif
      t = (((lab - la) - lb) + u) + log(s)
      if (t < MINLOG) then
         s = 0._R8P
      else
         call exp_(t, s, errno, ovf)
         if (ovf) bad = .true.
      endif
   endif
   endsubroutine pseries

   pure subroutine inverse_incomplete_beta(a, b, p, z, status)
   !< specfun.c inverse_incomplete_beta, Halley's method on incbet, for a > 0, b > 0, p > 0, |1 - p| >= 1e-14.
   real(R8P),    intent(in)  :: a, b, p !< Shapes and probability.
   real(R8P),    intent(out) :: z       !< Root.
   integer(I4P), intent(out) :: status  !< 0 defined, 1 undefined.

   real(R8P)    :: err, t, u, w, afac, pp, lambda, h, lab, la, lb, ib, v, e !< Work.
   integer(I4P) :: j, qcls, afac_cls                                       !< Counter; classes of q, afac.
   logical      :: errno, bad, ovf, nan_out, lab_inf, la_inf, lb_inf       !< Flags.

   z = 0._R8P
   status = 1_I4P
   errno = .false.
   bad = .false.
   nan_out = .false.
   ! afac = lgamma(a+b) - lgamma(a) - lgamma(b): ERANGE and +inf or NaN when they overflow
   call add_(a, b, v, bad)
   if (bad) return ! a + b = inf
   lab_inf = .false.
   la_inf = .false.
   lb_inf = .false.
   call lgamma_(v, lab, lab_inf)
   call lgamma_(a, la, la_inf)
   call lgamma_(b, lb, lb_inf)
   errno = lab_inf .or. la_inf .or. lb_inf
   afac_cls = 0_I4P
   afac = 0._R8P
   if (lab_inf) then
      afac_cls = 2_I4P ! inf - inf (a or b is as large as a + b)
      if (.not. (la_inf .or. lb_inf)) afac_cls = 1_I4P
   else
      afac = (lab - la) - lb
   endif
   if (a >= 1._R8P .and. b >= 1._R8P) then
      if (p < 0.5_R8P) then
         pp = p
      else
         pp = 1._R8P - p
      endif
      if (pp <= 0._R8P) return ! log of p > 1: EDOM, NaN
      t = sqrt(-2._R8P * log(pp))
      z = t - (2.30753_R8P + 0.27061_R8P * t) / ((1._R8P + 0.99229_R8P * t) + (0.04481_R8P * t) * t)
      if (p < 0.5_R8P) z = -z
      if (z < 0._R8P) return ! sqrt(z) of a negative z: EDOM, NaN
      lambda = (sqrt(z) - 3._R8P) / 6._R8P
      ! 1 / (2 a - 1) is 1 / inf = 0 for a > DBL_MAX / 2; h = 2 / 0 = inf gives NaN guesses
      la = 0._R8P
      lb = 0._R8P
      if (a <= DBL_MAX / 2._R8P) la = 1._R8P / (2._R8P * a - 1._R8P)
      if (b <= DBL_MAX / 2._R8P) lb = 1._R8P / (2._R8P * b - 1._R8P)
      call div_(2._R8P, la + lb, h, bad)
      if (bad) then
         z = nan()
         if (.not. errno) status = 0_I4P
         return
      endif
      if (h + lambda < 0._R8P) return ! EDOM
      u = 0._R8P
      if (h <= DBL_MAX / 3._R8P) u = 2._R8P / (3._R8P * h)
      w = (z * sqrt(h + lambda) / h) - (lb - la) * (lambda + 5._R8P / 6._R8P - u)
      call exp_(2._R8P * w, e, errno, ovf)
      if (ovf) then
         z = 0._R8P ! a / (a + inf)
      else
         call mul_(b, e, v, bad)
         if (.not. bad) call add_(a, v, v, bad)
         if (bad) then
            bad = .false.
            z = 0._R8P
         else
            z = a / v
         endif
      endif
   else
      ! log(a / (a + b)) is -inf (ERANGE) when the ratio underflows: exp(-inf) = 0
      if (a / v == 0._R8P) then
         errno = .true.
         t = 0._R8P
      else
         call exp_(a * log(a / v), t, errno, ovf)
         call div_(t, a, t, bad)
      endif
      if (b / v == 0._R8P) then
         errno = .true.
         u = 0._R8P
      else
         call exp_(b * log(b / v), u, errno, ovf)
         call div_(u, b, u, bad)
      endif
      if (.not. bad) call add_(t, u, w, bad)
      if (bad) return ! t, u or w infinite: NaN or infinite guesses, with errno set by now in gnuplot's cases
      if (w > 0._R8P) then
         ovf = p < t / w
      else
         ovf = .false. ! 0 / 0 is NaN: the comparison is false
      endif
      if (ovf) then
         call mul_(a, w, v, bad)
         if (.not. bad) call mul_(v, p, v, bad)
         if (bad) return
         if (inv_overflows(a)) then
            call pow_inf(v, z, ovf) ! pow(v, 1/a = +inf)
         else
            call pow_(v, 1._R8P / a, z, errno, ovf)
         endif
      else
         call mul_(b, w, v, bad)
         if (.not. bad) call mul_(v, 1._R8P - p, v, bad)
         if (bad) return
         if (inv_overflows(b)) then
            call pow_inf(v, v, ovf) ! pow(v, 1/b = +inf)
         else
            call pow_(v, 1._R8P / b, v, errno, ovf)
         endif
         z = 1._R8P - v
      endif
      if (ovf) return ! an infinite guess: the Halley step takes the log of a negative number, EDOM
      if (ieee_is_nan(z)) return
   endif
   if (abs(1._R8P - z) < IGAMMA_PRECISION) errno = .false.
   if (errno) return
   ! Halley's method
   do j = 0_I4P, 11_I4P
      if (z == 0._R8P .or. z == 1._R8P) exit
      call incbet(a, b, z, ib, errno, nan_out, bad)
      nan_out = nan_out .or. bad
      bad = .false.
      err = ib - p
      if (z < 0._R8P .or. z > 1._R8P) return ! log of a negative number: EDOM, NaN steps
      call mul_(a - 1._R8P, log(z), u, bad)
      call mul_(b - 1._R8P, log(1._R8P - z), v, bad)
      if (.not. bad) call add_(u, v, v, bad)
      if (bad .or. afac_cls == 2_I4P) then
         nan_out = .true. ! an infinite or NaN exponent: t is inf, 0 or NaN, and the step turns NaN
         exit
      endif
      if (afac_cls == 1_I4P) then
         ! exp(+inf) = inf without errno: u = err / inf = 0, a zero step
         t = 0._R8P
      else
         call add_(v, afac, v, bad)
         if (bad) then
            nan_out = .true.
            exit
         endif
         call exp_(v, t, errno, ovf)
         if (ovf .or. t == 0._R8P) return ! errno is set: undefined whatever follows
         if (nan_out) exit ! incbet was NaN: the step is NaN
         ! q = (a - 1) / z - (b - 1) / (1 - z), with C's infinities
         qcls = 0_I4P
         call div_(a - 1._R8P, z, v, bad)
         if (bad) then
            bad = .false.
            qcls = int(sign(1._R8P, a - 1._R8P), I4P)
         endif
         call div_(b - 1._R8P, 1._R8P - z, w, bad)
         if (bad) then
            bad = .false.
            if (qcls == 0_I4P) then
               qcls = -int(sign(1._R8P, b - 1._R8P), I4P)
            elseif (qcls == int(sign(1._R8P, b - 1._R8P), I4P)) then
               qcls = 2_I4P ! inf - inf
            endif
         elseif (qcls == 0_I4P) then
            call add_(v, -w, v, bad)
            if (bad) then
               bad = .false.
               qcls = int(sign(1._R8P, v - w), I4P)
            endif
         endif
         call halley_step(err, t, 0_I4P, v, qcls, e, nan_out)
         if (nan_out) exit
         t = e
      endif
      if (nan_out) exit
      z = z - t
      if (z <= 0._R8P) z = 0.5_R8P * (z + t)
      if (z >= 1._R8P) z = 0.5_R8P * (z + t + 1._R8P)
      if (abs(t) <= MACHEP .and. j > 1_I4P) exit
   enddo
   if (nan_out) z = nan()
   if (.not. errno) status = 0_I4P
   endsubroutine inverse_incomplete_beta
endmodule foresight_gammafun
