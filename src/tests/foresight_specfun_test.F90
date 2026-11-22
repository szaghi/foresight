!< foresight_specfun test: values and domain behaviour against gnuplot 6.0.0 (sprintf("%.17g") probes).
program foresight_specfun_test
!< foresight_specfun test: values and domain behaviour against gnuplot 6.0.0 (sprintf("%.17g") probes).
!<
!< Each case: arguments, gnuplot value, expected status (0 value, 1 undefined), kind (0 number, 1 NaN, 2 +Inf;
!< plus 10 for a subnormal argument, skipped when the build flushes subnormals to zero as nvfortran does) and
!< a tolerance in ulps. gfortran (glibc libm) reproduces every value bit for bit; tolerances above 4 ulps are for
!< nvfortran, whose own exp/log/sin/pow differ from glibc by an ulp and whose -O2 reassociates: the comment of
!< each table says where that error is amplified. Expected values below tiny() are compared with an absolute
!< tolerance of tiny(), as nvfortran flushes subnormal results to zero.
use, intrinsic :: iso_fortran_env, only : output_unit
use penf, only : I4P, I8P, R8P
use foresight_specfun

implicit none
logical                 :: test_passed(9) !< List of passed tests.
logical                 :: ftz            !< Subnormals flush to zero in this build.
real(R8P), volatile     :: probe          !< Runtime probe of flush-to-zero.

probe = tiny(1.0_R8P)
probe = probe / 4.0_R8P
ftz = probe == 0.0_R8P
if (ftz) write(output_unit, '(A)') 'note: subnormals flush to zero, subnormal-argument cases skipped'
call test_lambertw(test_passed(1))
call test_airy(test_passed(2))
call test_expint(test_passed(3))
call test_elliptick(test_passed(4))
call test_elliptice(test_passed(5))
call test_ellipticpi(test_passed(6))
call test_voigt(test_passed(7))
call test_zeta(test_passed(8))
call test_synchrotronf(test_passed(9))

write(output_unit, '(A,9L2)') 'foresight_specfun checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1

contains

   subroutine test_lambertw(passed)
   !< lambertw: Halley iteration; undefined below -1/e (and at -1/e, where w = -1); x near DBL_MAX goes
   !< through gnuplot's Inf arithmetic (t/Inf = 0) and returns the starting guess, as gnuplot does.
   logical, intent(out) :: passed !< Test result.
   real(R8P), parameter :: ARG_A(19) = [ &
      -0.36787944117144233_R8P, -0.3678794411714423_R8P, -0.36_R8P, &
      -0.1_R8P, -1e-3_R8P, -1.2e-7_R8P, &
      1e-10_R8P, 1.19e-7_R8P, 0.5_R8P, &
      1.0_R8P, 2.718281828459045_R8P, 3.0000001_R8P, &
      10.0_R8P, 1e10_R8P, 1e300_R8P, &
      8.9e307_R8P, 1.79e308_R8P, -0.37_R8P, &
      -1e300_R8P]
   real(R8P), parameter :: EXPECTED(19) = [ &
      0.0_R8P, -0.99999998755249386_R8P, -0.80608431597081753_R8P, &
      -0.11183255915896298_R8P, -0.0010010015026718857_R8P, -1.2000001440000259e-07_R8P, &
      1e-10_R8P, 1.1899999999999999e-07_R8P, 0.35173371124919578_R8P, &
      0.56714329040978384_R8P, 1.0_R8P, 1.0499089120364877_R8P, &
      1.7455280027406994_R8P, 20.028685413304952_R8P, 684.24720862976085_R8P, &
      702.51570692935059_R8P, 703.21347141919421_R8P, 0.0_R8P, &
      0.0_R8P]
   integer(I4P), parameter :: STATUS_E(19) = [ &
      1_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 1_I4P, 1_I4P]
   integer(I4P), parameter :: KINDS(19) = [ &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P]
   integer(I4P), parameter :: ULPS(19) = [ &
      4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, &
      4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, &
      4_I4P, 4_I4P, 4_I4P]
   real(R8P)            :: r
   integer(I4P)         :: st, i

   passed = .true.
   do i = 1, 19
      if (KINDS(i) >= 10_I4P .and. ftz) cycle
      call gp_lambertw(ARG_A(i), r, st)
      call check('lambertw', ARG_A(i), 0.0_R8P, r, st, EXPECTED(i), STATUS_E(i), KINDS(i), ULPS(i), passed)
   enddo
   endsubroutine test_lambertw

   subroutine test_airy(passed)
   !< airy = Ai(x): cephes; 0 beyond 25.77; undefined where -2x*sqrt(-x) overflows (sin(Inf) sets EDOM).
   logical, intent(out) :: passed !< Test result.
   real(R8P), parameter :: ARG_A(22) = [ &
      -1e300_R8P, -3e205_R8P, -2e205_R8P, &
      -1e200_R8P, -1e5_R8P, -100.5_R8P, &
      -10.0_R8P, -2.1_R8P, -2.09_R8P, &
      -2.0899999_R8P, -1.0_R8P, 0.0_R8P, &
      0.5_R8P, 2.0899999_R8P, 2.09_R8P, &
      5.0_R8P, 8.32_R8P, 8.33_R8P, &
      20.0_R8P, 25.77_R8P, 25.8_R8P, &
      1e300_R8P]
   real(R8P), parameter :: EXPECTED(22) = [ &
      0.0_R8P, 0.0_R8P, -1.388272302989809e-52_R8P, &
      3.3624325778706243e-51_R8P, -0.013152978710780951_R8P, 0.027927645277984581_R8P, &
      0.040241238486441955_R8P, 0.1634845129992927_R8P, 0.17005055173203007_R8P, &
      0.17005061721671888_R8P, 0.53556088329235219_R8P, 0.35502805388781722_R8P, &
      0.23169360648083343_R8P, 0.03042032307203657_R8P, 0.030420318363198369_R8P, &
      0.00010834442813607433_R8P, 1.8631290741071666e-08_R8P, 1.8096100200998914e-08_R8P, &
      1.6916728686705318e-27_R8P, 1.6642658723814637e-39_R8P, 0.0_R8P, &
      0.0_R8P]
   integer(I4P), parameter :: STATUS_E(22) = [ &
      1_I4P, 1_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P]
   integer(I4P), parameter :: KINDS(22) = [ &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P]
   integer(I4P), parameter :: ULPS(22) = [ &
      4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, &
      4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, &
      4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P]
   real(R8P)            :: r
   integer(I4P)         :: st, i

   passed = .true.
   do i = 1, 22
      if (KINDS(i) >= 10_I4P .and. ftz) cycle
      call gp_airy(ARG_A(i), r, st)
      call check('airy', ARG_A(i), 0.0_R8P, r, st, EXPECTED(i), STATUS_E(i), KINDS(i), ULPS(i), passed)
   enddo
   endsubroutine test_airy

   subroutine test_expint(passed)
   !< expint(n, x): undefined for n < 0, x < 0, x = 0 with n < 2 and where exp(-x) underflows to 0.
   logical, intent(out) :: passed !< Test result.
   integer(I8P), parameter :: ARG_A(25) = [ &
      0_I8P, 0_I8P, 0_I8P, 1_I8P, 2_I8P, 3_I8P, &
      -1_I8P, 1_I8P, 1_I8P, 1_I8P, 1_I8P, 1_I8P, &
      1_I8P, 1_I8P, 5_I8P, 10_I8P, 50_I8P, 1000_I8P, &
      1000_I8P, 2_I8P, 1_I8P, 1_I8P, 1_I8P, 0_I8P, &
      1_I8P]
   real(R8P), parameter :: ARG_B(25) = [ &
      1e-300_R8P, 0.5_R8P, 745.0_R8P, &
      0.0_R8P, 0.0_R8P, 0.0_R8P, &
      1.0_R8P, -1.0_R8P, 1e-10_R8P, &
      0.5_R8P, 2.9_R8P, 3.0_R8P, &
      3.0000001_R8P, 10.0_R8P, 1.0_R8P, &
      50.0_R8P, 0.1_R8P, 0.5_R8P, &
      5.0_R8P, 700.0_R8P, 745.1332191019411_R8P, &
      745.1332191019412_R8P, 1e300_R8P, 5.562684646268003e-309_R8P, &
      1e-320_R8P]
   real(R8P), parameter :: EXPECTED(25) = [ &
      9.999999999999999e+299_R8P, 1.2130613194252668_R8P, 0.0_R8P, &
      0.0_R8P, 1.0_R8P, 0.5_R8P, &
      0.0_R8P, 0.0_R8P, 22.448635265138922_R8P, &
      0.55977359477616073_R8P, 0.014824019227261292_R8P, 0.013048381094196811_R8P, &
      0.013048379434628202_R8P, 4.1569689296853246e-06_R8P, 0.070454237461720401_R8P, &
      3.2232965867491109e-24_R8P, 0.018427680452776905_R8P, 0.00060683377272660642_R8P, &
      6.7110692673674814e-06_R8P, 1.4045180121540397e-307_R8P, 0.0_R8P, &
      0.0_R8P, 0.0_R8P, 0.0_R8P, &
      736.25002522607235_R8P]
   integer(I4P), parameter :: STATUS_E(25) = [ &
      0_I4P, 0_I4P, 0_I4P, 1_I4P, 0_I4P, 0_I4P, 1_I4P, 1_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 1_I4P, 1_I4P, 0_I4P, &
      0_I4P]
   integer(I4P), parameter :: KINDS(25) = [ &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 12_I4P, &
      10_I4P]
   integer(I4P), parameter :: ULPS(25) = [ &
      4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, &
      4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, &
      4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, &
      4_I4P]
   real(R8P)            :: r
   integer(I4P)         :: st, i

   passed = .true.
   do i = 1, 25
      if (KINDS(i) >= 10_I4P .and. ftz) cycle
      call gp_expint(ARG_A(i), ARG_B(i), r, st)
      call check('expint', real(ARG_A(i), R8P), ARG_B(i), r, st, EXPECTED(i), STATUS_E(i), KINDS(i), ULPS(i), passed)
   enddo
   endsubroutine test_expint

   subroutine test_elliptick(passed)
   !< EllipticK(k): Carlson R_F; undefined for |k| >= 1.
   logical, intent(out) :: passed !< Test result.
   real(R8P), parameter :: ARG_A(11) = [ &
      -1.5_R8P, -1.0_R8P, -0.99_R8P, &
      -0.5_R8P, 0.0_R8P, 0.3_R8P, &
      0.9_R8P, 0.999999_R8P, 0.9999999999999999_R8P, &
      1.0000000000000002_R8P, 1e300_R8P]
   real(R8P), parameter :: EXPECTED(11) = [ &
      0.0_R8P, 0.0_R8P, 3.3566005233611924_R8P, &
      1.6857503548125963_R8P, 1.5707963267948968_R8P, 1.6080486199305128_R8P, &
      2.2805491384227703_R8P, 7.9474797735479692_R8P, 19.408121055678475_R8P, &
      0.0_R8P, 0.0_R8P]
   integer(I4P), parameter :: STATUS_E(11) = [ &
      1_I4P, 1_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 1_I4P, 1_I4P]
   integer(I4P), parameter :: KINDS(11) = [ &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P]
   integer(I4P), parameter :: ULPS(11) = [ &
      4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, &
      4_I4P, 4_I4P, 4_I4P]
   real(R8P)            :: r
   integer(I4P)         :: st, i

   passed = .true.
   do i = 1, 11
      if (KINDS(i) >= 10_I4P .and. ftz) cycle
      call gp_EllipticK(ARG_A(i), r, st)
      call check('EllipticK', ARG_A(i), 0.0_R8P, r, st, EXPECTED(i), STATUS_E(i), KINDS(i), ULPS(i), passed)
   enddo
   endsubroutine test_elliptick

   subroutine test_elliptice(passed)
   !< EllipticE(k): Carlson R_F, R_D; 1 at |k| = 1, undefined for |k| > 1.
   logical, intent(out) :: passed !< Test result.
   real(R8P), parameter :: ARG_A(12) = [ &
      -1.5_R8P, -1.0_R8P, -0.99_R8P, &
      -0.5_R8P, 0.0_R8P, 0.3_R8P, &
      0.9_R8P, 0.999999_R8P, 0.9999999999999999_R8P, &
      1.0_R8P, 1.0000000000000002_R8P, 1e300_R8P]
   real(R8P), parameter :: EXPECTED(12) = [ &
      0.0_R8P, 1.0_R8P, 1.0284758090288051_R8P, &
      1.4674622093394274_R8P, 1.5707963267948968_R8P, 1.5348334649232491_R8P, &
      1.171697052781614_R8P, 1.0000074474777243_R8P, 1.0000000000000142_R8P, &
      1.0_R8P, 0.0_R8P, 0.0_R8P]
   integer(I4P), parameter :: STATUS_E(12) = [ &
      1_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 1_I4P, 1_I4P]
   integer(I4P), parameter :: KINDS(12) = [ &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P]
   integer(I4P), parameter :: ULPS(12) = [ &
      4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, &
      4_I4P, 4_I4P, 4_I4P, 4_I4P]
   real(R8P)            :: r
   integer(I4P)         :: st, i

   passed = .true.
   do i = 1, 12
      if (KINDS(i) >= 10_I4P .and. ftz) cycle
      call gp_EllipticE(ARG_A(i), r, st)
      call check('EllipticE', ARG_A(i), 0.0_R8P, r, st, EXPECTED(i), STATUS_E(i), KINDS(i), ULPS(i), passed)
   enddo
   endsubroutine test_elliptice

   subroutine test_ellipticpi(passed)
   !< EllipticPi(n, k): Carlson R_F, R_J; undefined for n >= 1 or |k| >= 1; NaN where R_J overflows.
   logical, intent(out) :: passed !< Test result.
   real(R8P), parameter :: ARG_A(14) = [ &
      0.0_R8P, 0.5_R8P, 0.9_R8P, &
      0.9999999999999999_R8P, -0.5_R8P, -10.0_R8P, &
      -1e10_R8P, -1e50_R8P, -4e102_R8P, &
      -4.5e102_R8P, -1e300_R8P, 1.0_R8P, &
      0.5_R8P, 0.5_R8P]
   real(R8P), parameter :: ARG_B(14) = [ &
      0.5_R8P, 0.3_R8P, 0.9_R8P, &
      0.5_R8P, 0.0_R8P, 0.5_R8P, &
      0.9_R8P, 0.5_R8P, 0.5_R8P, &
      0.5_R8P, 0.5_R8P, 0.5_R8P, &
      1.0_R8P, -1.5_R8P]
   real(R8P), parameter :: EXPECTED(14) = [ &
      1.6857503548125963_R8P, 2.2833505881933975_R8P, 8.9942562031858699_R8P, &
      172140923.98024538_R8P, 1.2825498301618643_R8P, 0.48922452759653967_R8P, &
      1.5708074151632445e-05_R8P, -4.4408920985006262e-16_R8P, -4.4408920985006262e-16_R8P, &
      0.0_R8P, 0.0_R8P, 0.0_R8P, &
      0.0_R8P, 0.0_R8P]
   integer(I4P), parameter :: STATUS_E(14) = [ &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 1_I4P, 1_I4P, 1_I4P]
   integer(I4P), parameter :: KINDS(14) = [ &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 1_I4P, 1_I4P, 0_I4P, 0_I4P, 0_I4P]
   integer(I4P), parameter :: ULPS(14) = [ &
      4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, &
      4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P]
   real(R8P)            :: r
   integer(I4P)         :: st, i

   passed = .true.
   do i = 1, 14
      if (KINDS(i) >= 10_I4P .and. ftz) cycle
      call gp_EllipticPi(ARG_A(i), ARG_B(i), r, st)
      call check('EllipticPi', ARG_A(i), ARG_B(i), r, st, EXPECTED(i), STATUS_E(i), KINDS(i), ULPS(i), passed)
   enddo
   endsubroutine test_ellipticpi

   subroutine test_voigt(passed)
   !< voigt(x, y): Humlicek; signed zero where x^2 + y^2 overflows; undefined for y < -10.81 and where
   !< exp(-x^2) underflows (y <= 1e-6); NaN at the zero CPF12 denominators. y < 0: 64 ulps, cancellation under
   !< nvfortran -O2; y >= 0: 16 ulps, nvfortran -O2 reassociation.
   logical, intent(out) :: passed !< Test result.
   real(R8P), parameter :: ARG_A(26) = [ &
      0.0_R8P, 1.0_R8P, 0.5_R8P, &
      -2.0_R8P, 3.0_R8P, 5.0_R8P, &
      6.5_R8P, 8.0_R8P, 100.0_R8P, &
      122.0_R8P, 130.0_R8P, 0.0_R8P, &
      1.0_R8P, 1e300_R8P, 1e300_R8P, &
      1e154_R8P, 1.4e154_R8P, 1.0_R8P, &
      0.0_R8P, 1.0_R8P, 1.0_R8P, &
      27.3_R8P, 50.0_R8P, 0.31424038_R8P, &
      27.0_R8P, 27.29_R8P]
   real(R8P), parameter :: ARG_B(26) = [ &
      0.0_R8P, 0.5_R8P, 0.01_R8P, &
      3.0_R8P, 1e-7_R8P, 1.0_R8P, &
      5.0_R8P, 8.425_R8P, 1e-5_R8P, &
      0.5_R8P, 8.0_R8P, 10000000000.0_R8P, &
      1e300_R8P, 1.0_R8P, -1.0_R8P, &
      70.55_R8P, 1e154_R8P, -10.0_R8P, &
      -1.5_R8P, -10.82_R8P, -60.0_R8P, &
      0.0_R8P, 0.0_R8P, -1.5_R8P, &
      0.0_R8P, 0.0_R8P]
   real(R8P), parameter :: EXPECTED(26) = [ &
      0.99999957331421196_R8P, 0.35489945867162048_R8P, 0.77234489835904629_R8P, &
      0.13075746284742407_R8P, 0.00012341766056118172_R8P, 0.023003133299669933_R8P, &
      0.042417067335144408_R8P, 0.035331084975242615_R8P, 5.6427421548985782e-10_R8P, &
      1.8954480058448599e-05_R8P, 0.0002660644093374204_R8P, 5.6418957999999997e-11_R8P, &
      0.0_R8P, 0.0_R8P, -0.0_R8P, &
      3.9803574868999995e-307_R8P, 0.0_R8P, -0.055598470581323889_R8P, &
      9.1661507400719877_R8P, 0.0_R8P, 0.0_R8P, &
      0.0_R8P, 0.0_R8P, 0.0_R8P, &
      2.507972078894169e-317_R8P, 4.9406564584124654e-324_R8P]
   integer(I4P), parameter :: STATUS_E(26) = [ &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 1_I4P, 1_I4P, 1_I4P, 1_I4P, 0_I4P, &
      0_I4P, 0_I4P]
   integer(I4P), parameter :: KINDS(26) = [ &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 1_I4P, &
      0_I4P, 0_I4P]
   integer(I4P), parameter :: ULPS(26) = [ &
      16_I4P, 16_I4P, 16_I4P, 16_I4P, 16_I4P, 16_I4P, 16_I4P, 16_I4P, &
      16_I4P, 16_I4P, 16_I4P, 16_I4P, 16_I4P, 16_I4P, 64_I4P, 16_I4P, &
      16_I4P, 64_I4P, 64_I4P, 4_I4P, 4_I4P, 4_I4P, 4_I4P, 64_I4P, &
      16_I4P, 16_I4P]
   real(R8P)            :: r
   integer(I4P)         :: st, i

   passed = .true.
   do i = 1, 26
      if (KINDS(i) >= 10_I4P .and. ftz) cycle
      call gp_voigt(ARG_A(i), ARG_B(i), r, st)
      call check('voigt', ARG_A(i), ARG_B(i), r, st, EXPECTED(i), STATUS_E(i), KINDS(i), ULPS(i), passed)
   enddo
   endsubroutine test_voigt

   subroutine test_zeta(passed)
   !< zeta(s): Borwein; 1 above 55, NaN below -170, 0 at negative even integers, +Inf where 1 - 2**(1-s) = 0.
   !< 512 ulps for s < -20: exp(lnGamma(1-s)) turns 1 ulp of lnGamma (up to 706) into ~500 ulps under nvfortran;
   !< 32 ulps elsewhere (alternating sum, reflection product).
   logical, intent(out) :: passed !< Test result.
   real(R8P), parameter :: ARG_A(28) = [ &
      -1e300_R8P, -171.0_R8P, -170.0_R8P, &
      -169.5_R8P, -169.0_R8P, -100.5_R8P, &
      -20.5_R8P, -11.0_R8P, -10.0_R8P, &
      -3.0_R8P, -2.0_R8P, -1.5_R8P, &
      -1.0_R8P, -0.5_R8P, 0.0_R8P, &
      0.5_R8P, 0.9_R8P, 0.9999999999999999_R8P, &
      1.0_R8P, 1.0000000000000002_R8P, 1.01_R8P, &
      1.5_R8P, 2.0_R8P, 3.0_R8P, &
      10.0_R8P, 55.0_R8P, 56.0_R8P, &
      1e300_R8P]
   real(R8P), parameter :: EXPECTED(28) = [ &
      0.0_R8P, 0.0_R8P, 0.0_R8P, &
      -6.3986100410826746e+169_R8P, -1.740946592037694e+169_R8P, -1.2790431911215309e+78_R8P, &
      -108.21747505877559_R8P, 0.021092796092796087_R8P, 0.0_R8P, &
      0.0083333333333333263_R8P, 0.0_R8P, -0.025485201889833053_R8P, &
      -0.083333333333333343_R8P, -0.20788622497735471_R8P, -0.5_R8P, &
      -1.4603545088095873_R8P, -9.4301140194022501_R8P, 0.0_R8P, &
      0.0_R8P, 6243314768165358.0_R8P, 100.57794333849716_R8P, &
      2.6123753486854886_R8P, 1.6449340668482266_R8P, 1.2020569031595942_R8P, &
      1.0009945751278184_R8P, 1.0_R8P, 1.0_R8P, &
      1.0_R8P]
   integer(I4P), parameter :: STATUS_E(28) = [ &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P]
   integer(I4P), parameter :: KINDS(28) = [ &
      1_I4P, 1_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 2_I4P, 2_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P]
   integer(I4P), parameter :: ULPS(28) = [ &
      512_I4P, 512_I4P, 512_I4P, 512_I4P, 512_I4P, 512_I4P, 512_I4P, 32_I4P, &
      32_I4P, 32_I4P, 32_I4P, 32_I4P, 32_I4P, 32_I4P, 32_I4P, 32_I4P, &
      32_I4P, 32_I4P, 32_I4P, 32_I4P, 32_I4P, 32_I4P, 32_I4P, 32_I4P, &
      32_I4P, 32_I4P, 32_I4P, 32_I4P]
   real(R8P)            :: r
   integer(I4P)         :: st, i

   passed = .true.
   do i = 1, 28
      if (KINDS(i) >= 10_I4P .and. ftz) cycle
      call gp_zeta(ARG_A(i), r, st)
      call check('zeta', ARG_A(i), 0.0_R8P, r, st, EXPECTED(i), STATUS_E(i), KINDS(i), ULPS(i), passed)
   enddo
   endsubroutine test_zeta

   subroutine test_synchrotronf(passed)
   !< SynchrotronF(x): MacLeod; NaN for x < 0, 0 above 745, undefined where x**(11/3) underflows.
   !< 16 ulps: nvfortran pow/exp.
   logical, intent(out) :: passed !< Test result.
   real(R8P), parameter :: ARG_A(19) = [ &
      -1.0_R8P, 0.0_R8P, 5.539601752274629e-89_R8P, &
      5.53960175227463e-89_R8P, 1e-50_R8P, 0.01_R8P, &
      0.421875_R8P, 0.4219_R8P, 1.0_R8P, &
      4.0_R8P, 4.291015625_R8P, 4.2911_R8P, &
      10.0_R8P, 100.0_R8P, 700.0_R8P, &
      744.0_R8P, 745.0001_R8P, 746.0_R8P, &
      1e300_R8P]
   real(R8P), parameter :: EXPECTED(19) = [ &
      0.0_R8P, 0.0_R8P, 0.0_R8P, &
      8.1941266105329805e-30_R8P, 4.6310182107651245e-17_R8P, 0.44497250411421074_R8P, &
      0.89612314590100428_R8P, 0.89611613070215057_R8P, 0.65142281535536406_R8P, &
      0.052827396697866819_R8P, 0.040600479204911027_R8P, 0.040597370971078066_R8P, &
      0.00019223826430086899_R8P, 4.6975936659221719e-43_R8P, 3.2729881765370873e-303_R8P, &
      3.3596463917204765e-322_R8P, 0.0_R8P, 0.0_R8P, &
      0.0_R8P]
   integer(I4P), parameter :: STATUS_E(19) = [ &
      0_I4P, 0_I4P, 1_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P]
   integer(I4P), parameter :: KINDS(19) = [ &
      1_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, 0_I4P, &
      0_I4P, 0_I4P, 0_I4P]
   integer(I4P), parameter :: ULPS(19) = [ &
      16_I4P, 16_I4P, 4_I4P, 16_I4P, 16_I4P, 16_I4P, 16_I4P, 16_I4P, &
      16_I4P, 16_I4P, 16_I4P, 16_I4P, 16_I4P, 16_I4P, 16_I4P, 16_I4P, &
      16_I4P, 16_I4P, 16_I4P]
   real(R8P)            :: r
   integer(I4P)         :: st, i

   passed = .true.
   do i = 1, 19
      if (KINDS(i) >= 10_I4P .and. ftz) cycle
      call gp_SynchrotronF(ARG_A(i), r, st)
      call check('SynchrotronF', ARG_A(i), 0.0_R8P, r, st, EXPECTED(i), STATUS_E(i), KINDS(i), ULPS(i), passed)
   enddo
   endsubroutine test_synchrotronf

   subroutine check(name, a, b, r, st, e, est, kd, tol, passed)
   !< Compare one result with gnuplot's, print the case when it fails.
   character(*), intent(in)    :: name   !< Function name.
   real(R8P),    intent(in)    :: a      !< First argument.
   real(R8P),    intent(in)    :: b      !< Second argument (0 for one-argument functions).
   real(R8P),    intent(in)    :: r      !< Result.
   integer(I4P), intent(in)    :: st     !< Status.
   real(R8P),    intent(in)    :: e      !< gnuplot value.
   integer(I4P), intent(in)    :: est    !< Expected status.
   integer(I4P), intent(in)    :: kd     !< Kind: 0 number, 1 NaN, 2 +Inf (plus 10: subnormal argument).
   integer(I4P), intent(in)    :: tol    !< Tolerance in ulps.
   logical,      intent(inout) :: passed !< Test result.
   logical                     :: ok

   ok = st == est
   if (ok .and. est == 0_I4P) then
      select case (mod(kd, 10_I4P))
      case (1_I4P)
         ok = r /= r
      case (2_I4P)
         ok = r > huge(1.0_R8P)
      case default
         if (r /= r .or. abs(r) > huge(1.0_R8P)) then
            ok = .false.
         elseif (abs(e) < tiny(1.0_R8P)) then
            ok = abs(r - e) <= tiny(1.0_R8P)
            if (ok .and. e == 0.0_R8P .and. r == 0.0_R8P) ok = sign(1.0_R8P, r) == sign(1.0_R8P, e)
         else
            ok = abs(r - e) <= tol * spacing(abs(e))
#if defined(__INTEL_LLVM_COMPILER) || defined(__INTEL_COMPILER)
            ! Intel's libm is not glibc: a relative 1e-10 (absolutely 1e-16 near a zero of the function)
            ok = ok .or. abs(r - e) <= 1.0e-10_R8P * abs(e) + 1.0e-16_R8P
#endif
         endif
      endselect
   endif
   if (.not. ok) then
      passed = .false.
      if (r /= r) then
         write(output_unit, '(A,2ES25.16E3,A,I0,A,ES25.16E3,A,I0)') 'FAILED '//name//' args', a, b, &
            ' status ', st, ' expected ', e, ' status ', est
      elseif (abs(r) > huge(1.0_R8P)) then
         write(output_unit, '(A,2ES25.16E3,A,I0,A,ES25.16E3,A,I0)') 'FAILED '//name//' args', a, b, &
            ' Inf, status ', st, ' expected ', e, ' status ', est
      else
         write(output_unit, '(A,2ES25.16E3,A,ES25.16E3,A,I0,A,ES25.16E3,A,I0)') 'FAILED '//name//' args', a, b, &
            ' got ', r, ' status ', st, ' expected ', e, ' status ', est
      endif
   endif
   endsubroutine check
endprogram foresight_specfun_test
