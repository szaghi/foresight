!< foresight_specfun: gnuplot 6.0.0 real special functions (lambertw, airy, expint, elliptic, voigt, zeta, synchrotron).
module foresight_specfun
!< gnuplot 6.0.0 real special functions, ported from its own C sources so values match gnuplot's to the last digits.
!<
!< Every entry point is a pure subroutine `gp_<name>(args..., r, status)`:
!<   status 0 = value in r (it can be NaN or +Inf when gnuplot prints NaN or inf);
!<   status 1 = gnuplot's undefined value (it prints "undefined value", plots a gap);
!<   status 2 = gnuplot stops with an error (no entry point here returns it: see EXPINT_ORDER_MSG).
!< gnuplot flags "undefined" also when a libm call sets errno (EDOM, ERANGE): those cases are reproduced by guards.
!< No IEEE invalid, divide-by-zero or overflow exception is raised for any finite argument.
!< All results are real (gnuplot complex values with zero imaginary part).
use, intrinsic :: iso_c_binding, only : c_double
use penf, only : I4P, I8P, R8P

implicit none
private
public :: gp_lambertw
public :: gp_airy
public :: gp_expint
public :: gp_EllipticK
public :: gp_EllipticE
public :: gp_EllipticPi
public :: gp_voigt
public :: gp_zeta
public :: gp_SynchrotronF
public :: EXPINT_ORDER_MSG

character(*), parameter :: EXPINT_ORDER_MSG = 'order of expint must be nonnegative integer' !< gnuplot int_error of
                                                                                              !< expint(n, x) when n is
                                                                                              !< not integer-typed.

real(R8P), parameter :: PI       = 3.14159265358979323846_R8P   !< M_PI.
real(R8P), parameter :: E_ONE    = 2.718281828459045235360287_R8P !< exp(1.0), constant-folded by gcc.
real(R8P), parameter :: E_MONE   = 0.367879441171442321595523770161460867_R8P !< exp(-1), constant-folded by gcc.
real(R8P), parameter :: FLT_EPS  = 1.1920928955078125e-7_R8P   !< FLT_EPSILON.
real(R8P), parameter :: DBL_EPS  = epsilon(1.0_R8P)            !< DBL_EPSILON (cephes MACHEP).
real(R8P), parameter :: FLT_MAXV = 3.40282346638528859811704183484516925e38_R8P !< FLT_MAX (specfun.c OFLOW).
real(R8P), parameter :: TWO_512  = 2.0_R8P**512                 !< Squares of values from here on overflow.
real(R8P), parameter :: TWO_1021 = 2.0_R8P**1021                !< Overflow threshold of a product scaled by 1/8.
real(R8P), parameter :: TWO_1023 = 2.0_R8P**1023                !< Overflow threshold of a sum scaled by 1/2.
real(R8P), parameter :: EXP_ZERO = -745.1332191019412_R8P     !< glibc exp(x) == 0 (errno ERANGE) for x <= this.
real(R8P), parameter :: POW113_ZERO = 5.539601752274629e-89_R8P !< glibc pow(x, 11/3) == 0 for 0 < x <= this.
integer(I8P), parameter :: QNAN_BITS = int(z'7FF8000000000000', I8P) !< Quiet NaN bit pattern.
integer(I8P), parameter :: PINF_BITS = int(z'7FF0000000000000', I8P) !< +Inf bit pattern.
real(R8P), parameter :: EXP_MAX_ARG = 709.782712893384_R8P   !< Largest x with finite exp(x).
real(R8P), parameter :: TWO_60   = 2.0_R8P**60                  !< Scale to compare subnormals with normal constants.
real(R8P), parameter :: TWO_M964 = 2.0_R8P**(-964)              !< 2**-1024 * 2**60: 1/z overflows for z <= 2**-1024.

! cephes airy (specfun.c, UNK tables)
real(R8P), parameter :: AIRY_C1    = 0.35502805388781723926_R8P  !< Ai(0).
real(R8P), parameter :: AIRY_C2    = 0.258819403792806798405_R8P !< -Ai'(0).
real(R8P), parameter :: AIRY_SQPII = 5.64189583547756286948E-1_R8P !< 1/sqrt(pi).
real(R8P), parameter :: MAXAIRY    = 25.77_R8P                   !< Ai(x) = 0 beyond.
real(R8P), parameter :: AN(8) = [3.46538101525629032477E-1_R8P, 1.20075952739645805542E1_R8P, &
                                 7.62796053615234516538E1_R8P, 1.68089224934630576269E2_R8P, &
                                 1.59756391350164413639E2_R8P, 7.05360906840444183113E1_R8P, &
                                 1.40264691163389668864E1_R8P, 9.99999999999999995305E-1_R8P] !< Ai numerator, x>2.09.
real(R8P), parameter :: AD(8) = [5.67594532638770212846E-1_R8P, 1.47562562584847203173E1_R8P, &
                                 8.45138970141474626562E1_R8P, 1.77318088145400459522E2_R8P, &
                                 1.64234692871529701831E2_R8P, 7.14778400825575695274E1_R8P, &
                                 1.40959135607834029598E1_R8P, 1.00000000000000000470E0_R8P] !< Ai denominator, x>2.09.
real(R8P), parameter :: AFN(9) = [-1.31696323418331795333E-1_R8P, -6.26456544431912369773E-1_R8P, &
                                  -6.93158036036933542233E-1_R8P, -2.79779981545119124951E-1_R8P, &
                                  -4.91900132609500318020E-2_R8P, -4.06265923594885404393E-3_R8P, &
                                  -1.59276496239262096340E-4_R8P, -2.77649108155232920844E-6_R8P, &
                                  -1.67787698489114633780E-8_R8P] !< Ai modulus numerator, x<-2.09.
real(R8P), parameter :: AFD(9) = [1.33560420706553243746E1_R8P, 3.26825032795224613948E1_R8P, &
                                  2.67367040941499554804E1_R8P, 9.18707402907259625840E0_R8P, &
                                  1.47529146771666414581E0_R8P, 1.15687173795188044134E-1_R8P, &
                                  4.40291641615211203805E-3_R8P, 7.54720348287414296618E-5_R8P, &
                                  4.51850092970580378464E-7_R8P] !< Ai modulus denominator (leading 1 implied).
real(R8P), parameter :: AGN(11) = [1.97339932091685679179E-2_R8P, 3.91103029615688277255E-1_R8P, &
                                   1.06579897599595591108E0_R8P, 9.39169229816650230044E-1_R8P, &
                                   3.51465656105547619242E-1_R8P, 6.33888919628925490927E-2_R8P, &
                                   5.85804113048388458567E-3_R8P, 2.82851600836737019778E-4_R8P, &
                                   6.98793669997260967291E-6_R8P, 8.11789239554389293311E-8_R8P, &
                                   3.41551784765923618484E-10_R8P] !< Ai phase numerator, x<-2.09.
real(R8P), parameter :: AGD(10) = [9.30892908077441974853E0_R8P, 1.98352928718312140417E1_R8P, &
                                   1.55646628932864612953E1_R8P, 5.47686069422975497931E0_R8P, &
                                   9.54293611618961883998E-1_R8P, 8.64580826352392193095E-2_R8P, &
                                   4.12656523824222607191E-3_R8P, 1.01259085116509135510E-4_R8P, &
                                   1.17166733214413521882E-6_R8P, 4.91834570062930015649E-9_R8P] !< Ai phase denom.

! Humlicek voigt (specfun.c humlik)
real(R8P), parameter :: HUM_C(0:5) = [1.0117281_R8P, -0.75197147_R8P, 0.012557727_R8P, &
                                      0.010022008_R8P, -2.4206814e-4_R8P, 5.0084806e-7_R8P] !< CPF12 c.
real(R8P), parameter :: HUM_S(0:5) = [1.393237_R8P, 0.23115241_R8P, -0.15535147_R8P, &
                                      0.0062183662_R8P, 9.1908299e-5_R8P, -6.2752596e-7_R8P] !< CPF12 s.
real(R8P), parameter :: HUM_T(0:5) = [0.31424038_R8P, 0.94778839_R8P, 1.5976826_R8P, &
                                      2.2795071_R8P, 3.020637_R8P, 3.8897249_R8P] !< CPF12 t.
real(R8P), parameter :: HUM_RRTPI = 0.56418958_R8P !< 1/sqrt(pi) as in humlik.

! Lanczos lnGamma (complexfun.c lnGamma)
real(R8P), parameter :: LANCZOS(0:14) = [0.99999999999999709182_R8P, &
                                         57.156235665862923517_R8P, -59.597960355475491248_R8P, &
                                         14.136097974741747174_R8P, -0.49191381609762019978_R8P, &
                                         0.33994649984811888699e-4_R8P, 0.46523628927048575665e-4_R8P, &
                                         -0.98374475304879564677e-4_R8P, 0.15808870322491248884e-3_R8P, &
                                         -0.21026444172410488319e-3_R8P, 0.21743961811521264320e-3_R8P, &
                                         -0.16431810653676389022e-3_R8P, 0.84418223983852743293e-4_R8P, &
                                         -0.26190838401581408670e-4_R8P, 0.36899182659531622704e-5_R8P] !< coef.
real(R8P), parameter :: LANCZOS_SQRT2PI = 2.5066282746310005_R8P !< sqrt(2 pi) as in lnGamma.
real(R8P), parameter :: LANCZOS_G = 671.0_R8P / 128.0_R8P      !< Lanczos g.

! MacLeod synchrotron Chebyshev coefficients (specfun.c f1_c .. f4_c)
real(R8P), parameter :: SYN_F1(6) = [2.4105383531095902_R8P, 0.0203052715485175_R8P, 0.0001333568543455_R8P, &
                                     0.0000002309772357_R8P, 0.0000000001998684_R8P, 0.0000000000001047_R8P] !< f1.
real(R8P), parameter :: SYN_F2(5) = [0.1577621017755018_R8P, 0.0003758515021084_R8P, 0.0000003988488202_R8P, &
                                     0.0000000002436560_R8P, 0.0000000000000971_R8P] !< f2.
real(R8P), parameter :: SYN_F3(19) = [1.3216565315966927_R8P, -0.5065739548627054_R8P, 0.0183439310952146_R8P, &
                                      0.0253507299516339_R8P, -0.0047005797257551_R8P, -0.0002534396748095_R8P, &
                                      0.0001725150548613_R8P, -0.0000147584170505_R8P, -0.0000019684687917_R8P, &
                                      0.0000004832573584_R8P, -0.0000000174479076_R8P, -0.0000000052436671_R8P, &
                                      0.0000000007070160_R8P, -0.0000000000011112_R8P, -0.0000000000074073_R8P, &
                                      0.0000000000006102_R8P, 0.0000000000000189_R8P, -0.0000000000000065_R8P, &
                                      0.0000000000000003_R8P] !< f3.
real(R8P), parameter :: SYN_F4(23) = [2.1496191117235133_R8P, 0.0707950115291429_R8P, -0.0036549721782930_R8P, &
                                      0.0003175929093108_R8P, -0.0000361428956832_R8P, 0.0000049140690366_R8P, &
                                      -0.0000007612313048_R8P, 0.0000001305499914_R8P, -0.0000000243177802_R8P, &
                                      0.0000000048537057_R8P, -0.0000000010276744_R8P, 0.0000000002290392_R8P, &
                                      -0.0000000000534048_R8P, 0.0000000000129634_R8P, -0.0000000000032626_R8P, &
                                      0.0000000000008485_R8P, -0.0000000000002273_R8P, 0.0000000000000626_R8P, &
                                      -0.0000000000000177_R8P, 0.0000000000000051_R8P, -0.0000000000000015_R8P, &
                                      0.0000000000000005_R8P, -0.0000000000000001_R8P] !< f4.

interface
   pure function c_log1p(x) bind(C, name='log1p')
   !< libm log1p (glibc clog uses it near |z| = 1); no Fortran intrinsic exists.
   import :: c_double
   real(c_double), value :: x !< Argument.
   real(c_double)        :: c_log1p
   endfunction c_log1p
endinterface

contains
   ! public entry points

   pure subroutine gp_lambertw(x, r, status)
   !< lambertw(x), principal branch: specfun.c lambertw (Halley iteration) and f_lambertw.
   !< Undefined (status 1) for x < -1/e, on non-convergence and for results <= -1 (as f_lambertw).
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.
   real(R8P)                 :: p, e, t, w, a, b, h, wp1
   logical                   :: a_inf, b_inf, den_inf
   integer(I4P)              :: i

   r = 0.0_R8P
   status = 1_I4P
   if (x < -E_MONE) return
   if (abs(x) <= FLT_EPS) then
      r = x
      status = 0_I4P
      return
   endif
   if (x < 1.0_R8P) then
      a = 2.0_R8P * (E_ONE * x + 1.0_R8P)
      if (a < 0.0_R8P) return ! sqrt(negative): EDOM
      p = sqrt(a)
      w = ((-1.0_R8P + p) - p * p / 3.0_R8P) + (((11.0_R8P / 72.0_R8P) * p) * p) * p
   else
      w = log(x)
   endif
   if (x > 3.0_R8P) w = w - log(w)
   do i = 1, 20
      ! w = -1 makes the Halley denominator 0/0 or t/0: gnuplot ends with -1 (undefined) either way
      if (w == -1.0_R8P) return
      if (w > EXP_MAX_ARG) return ! exp overflows: errno ERANGE
      e = exp(w)
      if (mul_overflows(abs(w), e)) return ! t = Inf, then Inf/Inf = NaN
      t = w * e - x
      ! Halley denominator e*(w+1) - 0.5*(w+2)*t/(w+1), with gnuplot's Inf arithmetic: an infinite denominator
      ! gives t = 0 and convergence on the current w, a NaN or zero denominator never converges (undefined)
      wp1 = w + 1.0_R8P
      h = 0.5_R8P * (w + 2.0_R8P)
      a_inf = mul_overflows(e, abs(wp1))
      if (.not. a_inf) a = e * wp1
      b_inf = mul_overflows(abs(h), abs(t))
      if (.not. b_inf) then
         b = h * t
         b_inf = div_overflows(abs(b), abs(wp1))
         if (.not. b_inf) b = b / wp1
      endif
      if (a_inf .and. b_inf) then
         if (sign(1.0_R8P, wp1) == sign(1.0_R8P, h) * sign(1.0_R8P, t) * sign(1.0_R8P, wp1)) return ! Inf - Inf
         den_inf = .true.
      elseif (a_inf .or. b_inf) then
         den_inf = .true.
      else
         den_inf = .false.
         if (sign(1.0_R8P, a) /= sign(1.0_R8P, b)) den_inf = add_overflows(abs(a), abs(b))
      endif
      if (den_inf) then
         t = 0.0_R8P
      else
         a = a - b
         if (a == 0.0_R8P) return
         if (div_overflows(abs(t), abs(a))) return
         t = t / a
         w = w - t
      endif
      if (abs(t) < FLT_EPS * (1.0_R8P + abs(w))) then
         if (w <= -1.0_R8P) return
         r = w
         status = 0_I4P
         return
      endif
   enddo
   endsubroutine gp_lambertw

   pure subroutine gp_airy(x, r, status)
   !< airy(x) = Ai(x): specfun.c airy (cephes 2.8, UNK tables) and f_airy, which pushes only Ai.
   !< Ai = 0 for x > 25.77 (MAXAIRY); undefined (status 1) when -2x*sqrt(-x) overflows (sin(inf) sets EDOM).
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.
   real(R8P)                 :: z, zz, t, f, g, uf, ug, k, zeta, theta, a

   r = 0.0_R8P
   status = 0_I4P
   if (x > MAXAIRY) return
   if (x < -2.09_R8P) then
      t = sqrt(-x)
      if (mul_overflows(2.0_R8P, -x)) then
         status = 1_I4P
         return
      endif
      a = -2.0_R8P * x
      if (mul_overflows(a, t)) then
         status = 1_I4P
         return
      endif
      zeta = a * t / 3.0_R8P
      t = sqrt(t)
      k = AIRY_SQPII / t
      z = 1.0_R8P / zeta
      zz = z * z
      uf = 1.0_R8P + zz * polevl(zz, AFN, 8) / p1evl(zz, AFD, 9)
      ug = z * polevl(zz, AGN, 10) / p1evl(zz, AGD, 10)
      theta = zeta + 0.25_R8P * PI
      f = sin(theta)
      g = cos(theta)
      r = k * (f * uf - g * ug)
      return
   endif
   if (x >= 2.09_R8P) then
      t = sqrt(x)
      zeta = 2.0_R8P * x * t / 3.0_R8P
      g = exp(zeta)
      t = sqrt(t)
      k = 2.0_R8P * t * g
      z = 1.0_R8P / zeta
      f = polevl(z, AN, 7) / polevl(z, AD, 7)
      r = AIRY_SQPII * f / k
      return
   endif
   ! power series, |x| < 2.09
   f = 1.0_R8P
   g = x
   t = 1.0_R8P
   uf = 1.0_R8P
   ug = x
   k = 1.0_R8P
   z = x * x * x
   do while (t > DBL_EPS)
      uf = uf * z
      k = k + 1.0_R8P
      uf = uf / k
      ug = ug * z
      k = k + 1.0_R8P
      ug = ug / k
      uf = uf / k
      f = f + uf
      k = k + 1.0_R8P
      ug = ug / k
      g = g + ug
      t = abs(uf / f)
   enddo
   uf = AIRY_C1 * f
   ug = AIRY_C2 * g
   r = uf - ug
   endsubroutine gp_airy

   pure subroutine gp_expint(n, x, r, status)
   !< expint(n, x) = E_n(x): specfun.c expint (A&S 5.1.22 continued fraction for x > 3, series 5.1.12 and
   !< recurrence 5.1.14 otherwise) and f_expint.
   !< Undefined (status 1) for n < 0, x < 0, x = 0 with n < 2, and when exp(-x) underflows to 0 (x > 745.13,
   !< glibc errno ERANGE). gnuplot stops with EXPINT_ORDER_MSG when n is not integer-typed: the caller checks it.
   !< expint(0, x) overflows to +Inf (status 0) for x <= 2**-1024. For x <= 3 the recurrence runs n-1 steps as in
   !< gnuplot; for n >= 2**53 gnuplot never terminates, here it returns undefined.
   integer(I8P), intent(in)  :: n      !< Order (gnuplot integer).
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.
   real(R8P)                 :: rn, z, y, y_prev, ez
   real(R8P)                 :: n0, n1, n2, n3, d0, d1, d2, d3
   real(R8P)                 :: t, m
   integer(I4P)              :: i

   r = 0.0_R8P
   status = 1_I4P
   rn = real(n, R8P)
   z = x
   if (rn < 0.0_R8P .or. z < 0.0_R8P) return
   if (z == 0.0_R8P .and. rn < 2.0_R8P) return
   if (z == 0.0_R8P) then
      r = 1.0_R8P / (rn - 1.0_R8P)
      status = 0_I4P
      return
   endif
   if (-z <= EXP_ZERO) return ! exp(-z) underflows to 0: glibc errno ERANGE
   ez = exp(-z)
   if (rn == 0.0_R8P) then
      if (z * TWO_60 <= TWO_M964) then
         r = transfer(PINF_BITS, 1.0_R8P)
      else
         r = ez / z
      endif
      status = 0_I4P
      return
   endif
   if (z > 3.0_R8P) then
      y_prev = 1.0_R8P
      n0 = 0.0_R8P
      n1 = 1.0_R8P
      d0 = 1.0_R8P
      d1 = z
      y = 0.0_R8P
      do i = 0, 332
         n2 = n0 * (rn + i) + n1
         d2 = d0 * (rn + i) + d1
         n3 = n1 * (1 + i) + n2 * z
         d3 = d1 * (1 + i) + d2 * z
         y = n3 / d3
         if (y == y_prev) exit
         y_prev = y
         n0 = n2
         n1 = n3
         d0 = d2
         d1 = d3
         if (d3 >= FLT_MAXV) then
            n0 = n0 / FLT_MAXV
            n1 = n1 / FLT_MAXV
            d0 = d0 / FLT_MAXV
            d1 = d1 / FLT_MAXV
         endif
      enddo
      y = exp(-z) * y
   else
      if (rn >= 2.0_R8P**53) return
      y_prev = 0.0_R8P
      y = -0.577215664901532860606512_R8P - log(z)
      t = 1.0_R8P
      m = 1.0_R8P
      do while (m < 333.0_R8P)
         t = -t * z / m
         y = y - t / m
         if (y == y_prev) exit
         y_prev = y
         m = m + 1.0_R8P
      enddo
      m = 1.0_R8P
      do while (m < rn)
         y = (exp(-z) - z * y) / m
         m = m + 1.0_R8P
      enddo
   endif
   if (y <= -1.0_R8P) return
   r = y
   status = 0_I4P
   endsubroutine gp_expint

   pure subroutine gp_EllipticK(k, r, status)
   !< EllipticK(k), complete elliptic integral of the first kind: standard.c f_ellip_first, Carlson R_F(0, 1-k^2, 1).
   !< Undefined (status 1) for |k| >= 1.
   real(R8P),    intent(in)  :: k      !< Modulus.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.
   real(R8P)                 :: q

   r = 0.0_R8P
   status = 1_I4P
   if (abs(k) >= 1.0_R8P) return ! q = (1-k)(1+k) <= 0
   q = (1.0_R8P - k) * (1.0_R8P + k)
   r = carlson_rf(0.0_R8P, q, 1.0_R8P)
   status = 0_I4P
   endsubroutine gp_EllipticK

   pure subroutine gp_EllipticE(k, r, status)
   !< EllipticE(k), complete elliptic integral of the second kind: standard.c f_ellip_second,
   !< R_F(0, q, 1) - k^2 R_D(0, q, 1)/3 with q = 1-k^2. E(+-1) = 1; undefined (status 1) for |k| > 1.
   real(R8P),    intent(in)  :: k      !< Modulus.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.
   real(R8P)                 :: q

   r = 0.0_R8P
   status = 1_I4P
   if (abs(k) > 1.0_R8P) return ! q < 0
   status = 0_I4P
   if (abs(k) == 1.0_R8P) then
      r = 1.0_R8P
      return
   endif
   q = (1.0_R8P - k) * (1.0_R8P + k)
   r = carlson_rf(0.0_R8P, q, 1.0_R8P) - (k * k) * carlson_rd(0.0_R8P, q, 1.0_R8P) / 3.0_R8P
   endsubroutine gp_EllipticE

   pure subroutine gp_EllipticPi(n, k, r, status)
   !< EllipticPi(n, k), complete elliptic integral of the third kind: standard.c f_ellip_third,
   !< R_F(0, q, 1) + n R_J(0, q, 1, 1-n)/3 with q = 1-k^2. Undefined (status 1) for |k| >= 1 or n >= 1.
   !< For n below about -4.5e102 gnuplot's R_J overflows and the result is NaN (status 0), reproduced here.
   real(R8P),    intent(in)  :: n      !< Characteristic.
   real(R8P),    intent(in)  :: k      !< Modulus.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.
   real(R8P)                 :: q, rj
   logical                   :: nan

   r = 0.0_R8P
   status = 1_I4P
   if (abs(k) >= 1.0_R8P .or. n >= 1.0_R8P) return
   status = 0_I4P
   q = (1.0_R8P - k) * (1.0_R8P + k)
   call carlson_rj(0.0_R8P, q, 1.0_R8P, 1.0_R8P - n, rj, nan)
   if (nan) then
      r = transfer(QNAN_BITS, 1.0_R8P)
      return
   endif
   r = carlson_rf(0.0_R8P, q, 1.0_R8P) + n * rj / 3.0_R8P
   endsubroutine gp_EllipticPi

   pure subroutine gp_voigt(x, y, r, status)
   !< voigt(x, y), Voigt profile K(x, y): specfun.c f_voigt fallback (no libcerf) = humlik, Humlicek W4/CPF12.
   !< Undefined (status 1) for y below about -10.81 (sqrt of a negative xlim, EDOM) and, for y <= 1e-6, when
   !< exp(-x^2) underflows to 0 in CPF12 region II (|x| > 27.29, ERANGE). NaN (status 0) when a CPF12
   !< denominator is exactly zero (y = -1.5 and x = +-t_j), as in gnuplot.
   real(R8P),    intent(in)  :: x      !< Real part of the complex argument.
   real(R8P),    intent(in)  :: y      !< Imaginary part of the complex argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.
   real(R8P)                 :: yq, yrrtpi, abx, xq
   real(R8P)                 :: xlim0, xlim1, xlim2, xlim3, xlim4, a
   real(R8P)                 :: a0, d0, d2, e0, e2, e4, h0, h2, h4, h6
   real(R8P)                 :: p0, p2, p4, p6, p8, z0, z2, z4, z6, z8
   real(R8P)                 :: mf(0:5), pf(0:5), mq(0:5), pq(0:5), xm(0:5), ym(0:5), xp(0:5), yp(0:5)
   real(R8P)                 :: ypy0, ypy0q, d, k, yf
   integer(I4P)              :: j

   r = 0.0_R8P
   status = 0_I4P
   yrrtpi = y * HUM_RRTPI
   abx = abs(x)
   if (y >= 70.55_R8P) then
      r = region0(abx, y, yrrtpi)
      return
   endif
   a = y * (40.0_R8P - y * 3.6_R8P) + 15100.0_R8P
   if (a < 0.0_R8P) then ! sqrt(negative): EDOM
      status = 1_I4P
      return
   endif
   xlim0 = sqrt(a)
   if (y >= 8.425_R8P) then
      xlim1 = 0.0_R8P
   else
      a = 164.0_R8P - y * (y * 1.8_R8P + 4.3_R8P)
      if (a < 0.0_R8P) then ! sqrt(negative): EDOM
         status = 1_I4P
         return
      endif
      xlim1 = sqrt(a)
   endif
   xlim2 = 6.8_R8P - y
   xlim3 = y * 2.4_R8P
   xlim4 = y * 18.1_R8P + 1.65_R8P
   if (y <= 1e-6_R8P) then
      xlim1 = xlim0
      xlim2 = xlim0
   endif
   if (abx >= xlim0) then ! region 0
      r = region0(abx, y, yrrtpi)
      return
   endif
   ! from here on abx < xlim0 <= 123, y < 70.55: no overflow
   yq = y * y
   xq = abx * abx
   if (abx >= xlim1) then ! Humlicek W4 region 1
      a0 = yq + 0.5_R8P
      d0 = a0 * a0
      d2 = yq + yq - 1.0_R8P
      r = HUM_RRTPI / (d0 + xq * (d2 + xq)) * y * (a0 + xq)
   elseif (abx > xlim2) then ! Humlicek W4 region 2
      h0 = yq * (yq * (yq * (yq + 6.0_R8P) + 10.5_R8P) + 4.5_R8P) + 0.5625_R8P
      h2 = yq * (yq * (yq * 4.0_R8P + 6.0_R8P) + 9.0_R8P) - 4.5_R8P
      h4 = 10.5_R8P - yq * (6.0_R8P - yq * 6.0_R8P)
      h6 = yq * 4.0_R8P - 6.0_R8P
      e0 = yq * (yq * (yq + 5.5_R8P) + 8.25_R8P) + 1.875_R8P
      e2 = yq * (yq * 3.0_R8P + 1.0_R8P) + 5.25_R8P
      e4 = h6 * 0.75_R8P
      r = HUM_RRTPI / (h0 + xq * (h2 + xq * (h4 + xq * (h6 + xq)))) * y * (e0 + xq * (e2 + xq * (e4 + xq)))
   elseif (abx < xlim3) then ! Humlicek W4 region 3
      z0 = y * (y * (y * (y * (y * (y * (y * (y * (y * (y + 13.3988_R8P) + 88.26741_R8P) + 369.1989_R8P) &
           + 1074.409_R8P) + 2256.981_R8P) + 3447.629_R8P) + 3764.966_R8P) + 2802.87_R8P) + 1280.829_R8P) &
           + 272.1014_R8P
      z2 = y * (y * (y * (y * (y * (y * (y * (y * 5.0_R8P + 53.59518_R8P) + 266.2987_R8P) + 793.4273_R8P) &
           + 1549.675_R8P) + 2037.31_R8P) + 1758.336_R8P) + 902.3066_R8P) + 211.678_R8P
      z4 = y * (y * (y * (y * (y * (y * 10.0_R8P + 80.39278_R8P) + 269.2916_R8P) + 479.2576_R8P) &
           + 497.3014_R8P) + 308.1852_R8P) + 78.86585_R8P
      z6 = y * (y * (y * (y * 10.0_R8P + 53.59518_R8P) + 92.75679_R8P) + 55.02933_R8P) + 22.03523_R8P
      z8 = y * (y * 5.0_R8P + 13.3988_R8P) + 1.49646_R8P
      p0 = y * (y * (y * (y * (y * (y * (y * (y * (y * 0.3183291_R8P + 4.264678_R8P) + 27.93941_R8P) &
           + 115.3772_R8P) + 328.2151_R8P) + 662.8097_R8P) + 946.897_R8P) + 919.4955_R8P) + 549.3954_R8P) &
           + 153.5168_R8P
      p2 = y * (y * (y * (y * (y * (y * (y * 1.2733163_R8P + 12.79458_R8P) + 56.81652_R8P) + 139.4665_R8P) &
           + 189.773_R8P) + 124.5975_R8P) - 1.322256_R8P) - 34.16955_R8P
      p4 = y * (y * (y * (y * (y * 1.9099744_R8P + 12.79568_R8P) + 29.81482_R8P) + 24.01655_R8P) &
           + 10.46332_R8P) + 2.584042_R8P
      p6 = y * (y * (y * 1.273316_R8P + 4.266322_R8P) + 0.9377051_R8P) - 0.07272979_R8P
      p8 = y * 0.3183291_R8P + 5.480304e-4_R8P
      r = 1.7724538_R8P / (z0 + xq * (z2 + xq * (z4 + xq * (z6 + xq * (z8 + xq))))) &
          * (p0 + xq * (p2 + xq * (p4 + xq * (p6 + xq * p8))))
   else ! Humlicek CPF12
      ypy0 = y + 1.5_R8P
      ypy0q = ypy0 * ypy0
      do j = 0, 5
         d = x - HUM_T(j)
         mq(j) = d * d
         pq(j) = (x + HUM_T(j)) * (x + HUM_T(j))
         if (mq(j) + ypy0q == 0.0_R8P .or. pq(j) + ypy0q == 0.0_R8P) then ! 1/0 then 0*inf in gnuplot
            r = transfer(QNAN_BITS, 1.0_R8P)
            return
         endif
      enddo
      do j = 0, 5
         d = x - HUM_T(j)
         mq(j) = d * d
         mf(j) = 1.0_R8P / (mq(j) + ypy0q)
         xm(j) = mf(j) * d
         ym(j) = mf(j) * ypy0
         d = x + HUM_T(j)
         pq(j) = d * d
         pf(j) = 1.0_R8P / (pq(j) + ypy0q)
         xp(j) = pf(j) * d
         yp(j) = pf(j) * ypy0
      enddo
      k = 0.0_R8P
      if (abx <= xlim4) then ! CPF12 region I
         do j = 0, 5
            k = k + (HUM_C(j) * (ym(j) + yp(j)) - HUM_S(j) * (xm(j) - xp(j)))
         enddo
      else ! CPF12 region II
         yf = y + 3.0_R8P
         do j = 0, 5
            k = k + ((HUM_C(j) * (mq(j) * mf(j) - ym(j) * 1.5_R8P) + HUM_S(j) * yf * xm(j)) / (mq(j) + 2.25_R8P) &
                     + (HUM_C(j) * (pq(j) * pf(j) - yp(j) * 1.5_R8P) - HUM_S(j) * yf * xp(j)) / (pq(j) + 2.25_R8P))
         enddo
         if (-xq <= EXP_ZERO) then ! exp underflows to 0: glibc errno ERANGE
            status = 1_I4P
            return
         endif
         k = y * k + exp(-xq)
      endif
      r = k
   endif
   endsubroutine gp_voigt

   pure subroutine gp_zeta(s, r, status)
   !< zeta(s), Riemann zeta for real s: complexfun.c f_zeta and Riemann_zeta (Borwein algorithm 3, n = 18), the
   !< reflection formula with the Lanczos lnGamma for s < 0, glibc cpow/clog/csin/cexp reduced to real arithmetic.
   !< zeta(s) = 1 for s > 55; NaN (status 0) for s < -170; 0 at negative even integers; +Inf (status 0) where
   !< 1 - 2**(1-s) rounds to 0 (s = 1 and its neighbours: gnuplot gives {inf, NaN}, a complex with NaN imaginary).
   real(R8P),    intent(in)  :: s      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value.
   real(R8P)                 :: z, lng
   integer(I8P)              :: is

   status = 0_I4P
   if (s > 55.0_R8P) then
      r = 1.0_R8P
   elseif (s < -170.0_R8P) then
      r = transfer(QNAN_BITS, 1.0_R8P)
   elseif (s < 0.0_R8P) then
      if (s == aint(s)) then
         is = -int(aint(s), I8P)
         if (iand(is, 1_I8P) == 0_I8P) then
            r = 0.0_R8P
            return
         endif
      endif
      z = 1.0_R8P - s
      lng = lngamma_lanczos(z)
      r = exp(s * log(2.0_R8P)) * exp((s - 1.0_R8P) * log(PI))
      r = r * sin(PI * s / 2.0_R8P)
      r = r * exp(lng)
      r = r * riemann_zeta(z)
   else
      r = riemann_zeta(s)
   endif
   endsubroutine gp_zeta

   pure subroutine gp_SynchrotronF(x, r, status)
   !< SynchrotronF(x) = x * int_x^inf K_{5/3}(y) dy: specfun.c f_SynchrotronF (MacLeod 2000 Chebyshev fits).
   !< NaN (status 0) for x < 0, 0 for x > 745; undefined (status 1) when x**(11/3) underflows to 0 (0 < x < ~7e-89,
   !< glibc pow sets errno ERANGE).
   real(R8P),    intent(in)  :: x      !< Argument.
   real(R8P),    intent(out) :: r      !< Result.
   integer(I4P), intent(out) :: status !< 0 value, 1 undefined.
   real(R8P), parameter      :: PI_SQRT3 = PI / sqrt(3.0_R8P) !< M_PI/sqrt(3.), constant-folded by gcc.
   real(R8P)                 :: t, f, p113

   status = 0_I4P
   if (x < 0.0_R8P) then
      r = transfer(QNAN_BITS, 1.0_R8P)
   elseif (x > 745.0_R8P) then
      r = 0.0_R8P
   elseif (x < 27.0_R8P / 64.0_R8P) then
      if (x > 0.0_R8P .and. x <= POW113_ZERO) then ! pow underflows to 0: glibc errno ERANGE
         r = 0.0_R8P
         status = 1_I4P
         return
      endif
      p113 = x**(11.0_R8P / 3.0_R8P)
      t = ((x * x) * 8192.0_R8P) / 729.0_R8P - 1.0_R8P
      f = x**(1.0_R8P / 3.0_R8P) * expand_cheby(t, SYN_F1, 6) - p113 * expand_cheby(t, SYN_F2, 5) - x
      r = f * PI_SQRT3
   elseif (x <= 2197.0_R8P / 512.0_R8P) then
      t = (128.0_R8P * x**(2.0_R8P / 3.0_R8P) - 205.0_R8P) / 133.0_R8P
      f = x**(1.0_R8P / 3.0_R8P) * exp(-x**(2.0_R8P / 3.0_R8P)) * expand_cheby(t, SYN_F3, 19)
      r = f * PI_SQRT3
   else
      t = 2197.0_R8P / (256.0_R8P * x) - 1.0_R8P
      r = sqrt(PI * x / 2.0_R8P) * exp(-x) * expand_cheby(t, SYN_F4, 23)
   endif
   endsubroutine gp_SynchrotronF

   ! private helpers

   pure function add_overflows(a, b) result(ovf)
   !< True when a + b (a, b >= 0, finite) rounds to +Inf: the halved sum reaches 2**1023 (halving is exact).
   real(R8P), intent(in) :: a   !< First addend.
   real(R8P), intent(in) :: b   !< Second addend.
   logical               :: ovf !< Overflow flag.

   ovf = 0.5_R8P * a + 0.5_R8P * b >= TWO_1023
   endfunction add_overflows

   pure function mul_overflows(a, b) result(ovf)
   !< True when a * b (a, b >= 0, finite) rounds to +Inf: exponent bound, then the product scaled by 1/8.
   real(R8P), intent(in) :: a   !< First factor.
   real(R8P), intent(in) :: b   !< Second factor.
   logical               :: ovf !< Overflow flag.
   integer(I4P)          :: e

   ovf = .false.
   if (a == 0.0_R8P .or. b == 0.0_R8P) return
   e = exponent(a) + exponent(b)
   if (e <= 1023_I4P) return
   if (e > 1026_I4P) then
      ovf = .true.
      return
   endif
   ovf = (0.125_R8P * a) * b >= TWO_1021
   endfunction mul_overflows

   pure function div_overflows(a, b) result(ovf)
   !< True when a / b (a, b >= 0, finite, b /= 0) rounds to +Inf: exponent bound, then the quotient scaled by 1/8.
   real(R8P), intent(in) :: a   !< Dividend.
   real(R8P), intent(in) :: b   !< Divisor.
   logical               :: ovf !< Overflow flag.
   integer(I4P)          :: e

   ovf = .false.
   if (a == 0.0_R8P) return
   e = exponent(a) - exponent(b)
   if (e <= 1022_I4P) return
   if (e >= 1025_I4P) then
      ovf = .true.
      return
   endif
   ovf = a / (8.0_R8P * b) >= TWO_1021
   endfunction div_overflows

   pure function region0(abx, y, yrrtpi) result(v)
   !< humlik region 0, y/sqrt(pi)/(x^2 + y^2), returning gnuplot's signed zero where x^2 + y^2 overflows.
   real(R8P), intent(in) :: abx    !< |x|.
   real(R8P), intent(in) :: y      !< y.
   real(R8P), intent(in) :: yrrtpi !< y/sqrt(pi).
   real(R8P)             :: v      !< Value.

   v = sign(0.0_R8P, yrrtpi) ! yrrtpi/Inf
   if (abx >= TWO_512 .or. abs(y) >= TWO_512) return
   if (add_overflows(abx * abx, y * y)) return
   v = yrrtpi / (abx * abx + y * y)
   endfunction region0

   pure function polevl(x, coef, n) result(ans)
   !< cephes polevl: coef(1)*x**n + ... + coef(n+1), Horner.
   real(R8P),    intent(in) :: x       !< Argument.
   real(R8P),    intent(in) :: coef(:) !< Coefficients, highest degree first.
   integer(I4P), intent(in) :: n       !< Degree.
   real(R8P)                :: ans     !< Value.
   integer(I4P)             :: i

   ans = coef(1)
   do i = 2, n + 1
      ans = ans * x + coef(i)
   enddo
   endfunction polevl

   pure function p1evl(x, coef, n) result(ans)
   !< cephes p1evl: x**n + coef(1)*x**(n-1) + ... + coef(n), Horner with implied leading 1.
   real(R8P),    intent(in) :: x       !< Argument.
   real(R8P),    intent(in) :: coef(:) !< Coefficients after the leading 1.
   integer(I4P), intent(in) :: n       !< Degree.
   real(R8P)                :: ans     !< Value.
   integer(I4P)             :: i

   ans = x + coef(1)
   do i = 2, n
      ans = ans * x + coef(i)
   enddo
   endfunction p1evl

   pure function expand_cheby(t, coef, n) result(v)
   !< specfun.c expand_cheby: Clenshaw sum of a Chebyshev series, halved leading term.
   real(R8P),    intent(in) :: t       !< Argument in [-1, 1].
   real(R8P),    intent(in) :: coef(:) !< Coefficients.
   integer(I4P), intent(in) :: n       !< Number of coefficients.
   real(R8P)                :: v       !< Value.
   real(R8P)                :: u0, u1, u2
   integer(I4P)             :: i

   u0 = 0.0_R8P
   u1 = 0.0_R8P
   u2 = 0.0_R8P
   do i = n, 1, -1
      u2 = u1
      u1 = u0
      u0 = coef(i) + 2.0_R8P * t * u1 - u2
   enddo
   v = (u0 - u2) / 2.0_R8P
   endfunction expand_cheby

   pure function carlson_rf(x, y, z) result(v)
   !< standard.c carlson_elliptic_rf, Carlson R_F(x, y, z) (Numerical Recipes rf, ERRTOL 0.0025).
   real(R8P), intent(in) :: x !< First argument.
   real(R8P), intent(in) :: y !< Second argument.
   real(R8P), intent(in) :: z !< Third argument.
   real(R8P)             :: v !< Value.
   real(R8P)             :: alamb, ave, delx, dely, delz, e2, e3, sqrtx, sqrty, sqrtz, xt, yt, zt

   xt = x
   yt = y
   zt = z
   do
      sqrtx = sqrt(xt)
      sqrty = sqrt(yt)
      sqrtz = sqrt(zt)
      alamb = sqrtx * (sqrty + sqrtz) + sqrty * sqrtz
      xt = 0.25_R8P * (xt + alamb)
      yt = 0.25_R8P * (yt + alamb)
      zt = 0.25_R8P * (zt + alamb)
      ave = (1.0_R8P / 3.0_R8P) * (xt + yt + zt)
      delx = (ave - xt) / ave
      dely = (ave - yt) / ave
      delz = (ave - zt) / ave
      if (.not. (abs(delx) > 0.0025_R8P .or. abs(dely) > 0.0025_R8P .or. abs(delz) > 0.0025_R8P)) exit
   enddo
   e2 = delx * dely - delz * delz
   e3 = delx * dely * delz
   v = (1.0_R8P + ((1.0_R8P / 24.0_R8P) * e2 - (0.1_R8P) - (3.0_R8P / 44.0_R8P) * e3) * e2 &
        + (1.0_R8P / 14.0_R8P) * e3) / sqrt(ave)
   endfunction carlson_rf

   pure function carlson_rd(x, y, z) result(v)
   !< standard.c carlson_elliptic_rd, Carlson R_D(x, y, z) (Numerical Recipes rd, ERRTOL 0.0015).
   real(R8P), intent(in) :: x !< First argument.
   real(R8P), intent(in) :: y !< Second argument.
   real(R8P), intent(in) :: z !< Third argument.
   real(R8P)             :: v !< Value.
   real(R8P), parameter  :: C1 = 3.0_R8P / 14.0_R8P, C2 = 1.0_R8P / 6.0_R8P, C3 = 9.0_R8P / 22.0_R8P
   real(R8P), parameter  :: C4 = 3.0_R8P / 26.0_R8P, C5 = 0.25_R8P * C3, C6 = 1.5_R8P * C4
   real(R8P)             :: alamb, ave, delx, dely, delz, ea, eb, ec, ed, ee, fac
   real(R8P)             :: sqrtx, sqrty, sqrtz, s, xt, yt, zt

   xt = x
   yt = y
   zt = z
   s = 0.0_R8P
   fac = 1.0_R8P
   do
      sqrtx = sqrt(xt)
      sqrty = sqrt(yt)
      sqrtz = sqrt(zt)
      alamb = sqrtx * (sqrty + sqrtz) + sqrty * sqrtz
      s = s + fac / (sqrtz * (zt + alamb))
      fac = 0.25_R8P * fac
      xt = 0.25_R8P * (xt + alamb)
      yt = 0.25_R8P * (yt + alamb)
      zt = 0.25_R8P * (zt + alamb)
      ave = 0.2_R8P * (xt + yt + 3.0_R8P * zt)
      delx = (ave - xt) / ave
      dely = (ave - yt) / ave
      delz = (ave - zt) / ave
      if (.not. (abs(delx) > 0.0015_R8P .or. abs(dely) > 0.0015_R8P .or. abs(delz) > 0.0015_R8P)) exit
   enddo
   ea = delx * dely
   eb = delz * delz
   ec = ea - eb
   ed = ea - 6.0_R8P * eb
   ee = ed + ec + ec
   v = 3.0_R8P * s + fac * (1.0_R8P + ed * (-C1 + C5 * ed - C6 * delz * ee) &
       + delz * (C2 * ee + delz * (-C3 * ec + delz * C4 * ea))) / (ave * sqrt(ave))
   endfunction carlson_rd

   pure subroutine carlson_rc(x, y, v, nan)
   !< standard.c carlson_elliptic_rc for y > 0 (the only case R_J with p > 0 calls), Carlson R_C(x, y).
   !< nan is true where gnuplot's iteration overflows to Inf and ends in NaN.
   real(R8P), intent(in)  :: x   !< First argument.
   real(R8P), intent(in)  :: y   !< Second argument, > 0.
   real(R8P), intent(out) :: v   !< Value.
   logical,   intent(out) :: nan !< Overflow (NaN result in gnuplot).
   real(R8P), parameter   :: C1 = 0.3_R8P, C2 = 1.0_R8P / 7.0_R8P, C3 = 0.375_R8P, C4 = 9.0_R8P / 22.0_R8P
   real(R8P)              :: alamb, ave, s, xt, yt, a

   v = 0.0_R8P
   nan = .true.
   xt = x
   yt = y
   do
      a = 2.0_R8P * sqrt(xt)
      if (mul_overflows(a, sqrt(yt))) return
      a = a * sqrt(yt)
      if (add_overflows(a, yt)) return
      alamb = a + yt
      if (add_overflows(xt, alamb) .or. add_overflows(yt, alamb)) return
      xt = 0.25_R8P * (xt + alamb)
      yt = 0.25_R8P * (yt + alamb)
      if (add_overflows(xt, yt)) return
      if (add_overflows(xt + yt, yt)) return
      ave = (1.0_R8P / 3.0_R8P) * (xt + yt + yt)
      s = (yt - ave) / ave
      if (.not. (abs(s) > 0.0012_R8P)) exit
   enddo
   nan = .false.
   v = (1.0_R8P + s * s * (C1 + s * (C2 + s * (C3 + s * C4)))) / sqrt(ave)
   endsubroutine carlson_rc

   pure subroutine carlson_rj(x, y, z, p, v, nan)
   !< standard.c carlson_elliptic_rj for p > 0 (EllipticPi always has p = 1-n > 0), Carlson R_J(x, y, z, p).
   !< nan is true where gnuplot's alpha/beta (or R_C) overflow to Inf and the result is NaN.
   real(R8P), intent(in)  :: x   !< First argument.
   real(R8P), intent(in)  :: y   !< Second argument.
   real(R8P), intent(in)  :: z   !< Third argument.
   real(R8P), intent(in)  :: p   !< Fourth argument, > 0.
   real(R8P), intent(out) :: v   !< Value.
   logical,   intent(out) :: nan !< Overflow (NaN result in gnuplot).
   real(R8P), parameter   :: C1 = 3.0_R8P / 14.0_R8P, C2 = 1.0_R8P / 3.0_R8P, C3 = 3.0_R8P / 22.0_R8P
   real(R8P), parameter   :: C4 = 3.0_R8P / 26.0_R8P, C5 = 0.75_R8P * C3, C6 = 1.5_R8P * C4
   real(R8P), parameter   :: C7 = 0.5_R8P * C2, C8 = C3 + C3
   real(R8P)              :: alamb, alpha, ave, beta, delp, delx, dely, delz, ea, eb, ec, ed, ee, fac
   real(R8P)              :: pt, sqrtx, sqrty, sqrtz, s, xt, yt, zt, a, b, rc

   v = 0.0_R8P
   nan = .true.
   s = 0.0_R8P
   fac = 1.0_R8P
   xt = x
   yt = y
   zt = z
   pt = p
   do
      sqrtx = sqrt(xt)
      sqrty = sqrt(yt)
      sqrtz = sqrt(zt)
      alamb = sqrtx * (sqrty + sqrtz) + sqrty * sqrtz
      a = sqrtx + sqrty + sqrtz
      if (mul_overflows(pt, a)) return
      a = pt * a
      b = sqrtx * sqrty * sqrtz
      if (add_overflows(a, b)) return
      a = a + b
      if (mul_overflows(a, a)) return
      alpha = a * a
      if (add_overflows(pt, alamb)) return
      b = pt + alamb
      if (mul_overflows(b, b)) return
      b = b * b
      if (mul_overflows(pt, b)) return
      beta = pt * b
      call carlson_rc(alpha, beta, rc, nan)
      if (nan) return
      nan = .true.
      s = s + fac * rc
      fac = 0.25_R8P * fac
      xt = 0.25_R8P * (xt + alamb)
      yt = 0.25_R8P * (yt + alamb)
      zt = 0.25_R8P * (zt + alamb)
      pt = 0.25_R8P * (pt + alamb)
      if (add_overflows(xt + yt + zt, pt)) return
      if (add_overflows(xt + yt + zt + pt, pt)) return
      ave = 0.2_R8P * (xt + yt + zt + pt + pt)
      delx = (ave - xt) / ave
      dely = (ave - yt) / ave
      delz = (ave - zt) / ave
      delp = (ave - pt) / ave
      if (.not. (abs(delx) > 0.0015_R8P .or. abs(dely) > 0.0015_R8P .or. abs(delz) > 0.0015_R8P &
                 .or. abs(delp) > 0.0015_R8P)) exit
   enddo
   nan = .false.
   ea = delx * (dely + delz) + dely * delz
   eb = delx * dely * delz
   ec = delp * delp
   ed = ea - 3.0_R8P * ec
   ee = eb + 2.0_R8P * delp * (ea - ec)
   v = 3.0_R8P * s + fac * (1.0_R8P + ed * (-C1 + C5 * ed - C6 * ee) + eb * (C7 + delp * (-C8 + delp * C4)) &
       + delp * ea * (C2 - delp * C3) - C2 * delp * ec) / (ave * sqrt(ave))
   endsubroutine carlson_rj

   pure function clog_re(v) result(l)
   !< Real part of glibc clog(v + 0i) for finite v > 0: log1p((v-1)(v+1))/2 for 0.5 <= v < 2, else log(v).
   real(R8P), intent(in) :: v !< Argument, > 0.
   real(R8P)             :: l !< log(v) as glibc's clog computes it.

   if (v == 1.0_R8P) then
      l = 0.0_R8P
   elseif (v >= 0.5_R8P .and. v < 2.0_R8P) then
      l = c_log1p((v - 1.0_R8P) * (v + 1.0_R8P)) / 2.0_R8P
   else
      l = log(v)
   endif
   endfunction clog_re

   pure function lngamma_lanczos(z) result(f)
   !< complexfun.c lnGamma (14-term Lanczos, Numerical Recipes form) for real z >= 1.
   real(R8P), intent(in) :: z !< Argument, >= 1.
   real(R8P)             :: f !< ln Gamma(z).
   real(R8P)             :: s, temp
   integer(I4P)          :: k

   s = LANCZOS(0)
   do k = 1, 14
      s = s + LANCZOS(k) / (z + k)
   enddo
   if (z == 1.0_R8P .or. z == 2.0_R8P) then
      f = 0.0_R8P
      return
   endif
   temp = z + LANCZOS_G
   temp = (z + 0.5_R8P) * clog_re(temp) - temp
   f = temp + clog_re(LANCZOS_SQRT2PI * s / z)
   endfunction lngamma_lanczos

   pure function riemann_zeta(s) result(v)
   !< complexfun.c Riemann_zeta for real s >= 0 (cpow(j, s) = exp(s*log(j)) as glibc evaluates it for real s).
   !< +Inf where 1 - 2**(1-s) rounds to 0 (gnuplot: libgcc complex division by 0 gives {inf, NaN}).
   real(R8P), intent(in) :: s !< Argument.
   real(R8P)             :: v !< Value.
   integer(I4P), parameter :: N = 18_I4P         !< Terms.
   real(R8P),    parameter :: TWO_N = 262144.0_R8P !< 2**N.
   real(R8P)               :: ej_sum, ej_term, ej_sign, sm, t, a
   integer(I4P)            :: j

   sm = 0.0_R8P
   ej_sign = 1.0_R8P
   do j = 0, N - 1
      sm = sm + ej_sign * (-TWO_N) / exp(s * log(real(j + 1, R8P)))
      ej_sign = -ej_sign
   enddo
   ej_sum = 1.0_R8P
   ej_term = 1.0_R8P
   do j = N, 2 * N - 1
      sm = sm + ej_sign * (ej_sum - TWO_N) / exp(s * log(real(j + 1, R8P)))
      ej_sign = -ej_sign
      ej_term = ej_term * real(2 * N - j, R8P)
      ej_term = ej_term / real(j - N + 1, R8P)
      ej_sum = ej_sum + ej_term
   enddo
   t = 1.0_R8P - exp((1.0_R8P - s) * log(2.0_R8P))
   a = -sm
   if (t == 0.0_R8P) then
      v = sign(transfer(PINF_BITS, 1.0_R8P), a)
      return
   endif
   v = a / (TWO_N * t)
   endfunction riemann_zeta
endmodule foresight_specfun
