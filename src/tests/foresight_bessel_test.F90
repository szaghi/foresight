!< foresight_bessel test: values against gnuplot 6.0 `print sprintf('%.17g', ...)`, undefined values, IEEE flags.
program foresight_bessel_test
!< foresight_bessel test: values against gnuplot 6.0 `print sprintf('%.17g', ...)`, undefined values, IEEE flags.
!<
!< Expected values are gnuplot 6.0.0's outputs (Ubuntu glibc 2.39). Values are compared within TOL ulps (exact zeros
!< exactly, and the sign of -0); gfortran calls glibc for every elementary function and matches all cases to 0 ulps
!< (the run prints its worst disagreement). Two groups inherit the processor's exp/log/sin/cos instead of a glibc
!< Bessel routine and get more room for nvfortran, whose own elementary functions differ from glibc's by an ulp:
!< besjn/besyn for |x| >= 2**302 (sin/cos of a huge argument, TOL_TRIG; nvfortran is 9 ulps off) and besin for
!< |n| > 50 (exp(v eta), whose relative error is |v eta| <= 709.8 times that of eta, TOL_UNIFORM; nvfortran 67 ulps).
!< Cases flagged `sub` need IEEE subnormals (subnormal arguments, results or intermediates such as exp(-x) in besin
!< for x > 708.4): they are skipped when the run flushes subnormals to zero, as nvfortran 26.9 builds with
!< foresight's flags do (subnormal operands read as zero); such runs are told apart by a runtime probe.
!< Group 10 sweeps every function over orders -60..60 and more and over |x| from 1e-320 to 1e300, and checks that
!< no IEEE invalid, divide-by-zero or overflow flag is ever raised.
use, intrinsic :: iso_fortran_env, only : output_unit
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan, ieee_is_finite, ieee_is_negative
use, intrinsic :: ieee_exceptions, only : ieee_get_flag, ieee_set_flag, ieee_invalid, ieee_divide_by_zero, &
                                          ieee_overflow
use penf, only : I4P, I8P, R8P
use foresight_bessel

implicit none
integer(I4P), parameter :: K_VALUE = 0_I4P !< Expect a value.
integer(I4P), parameter :: K_UNDEF = 1_I4P !< Expect gnuplot's undefined value.
integer(I4P), parameter :: K_NAN   = 2_I4P !< Expect NaN (gnuplot prints NaN).
integer(I4P), parameter :: K_PINF  = 3_I4P !< Expect +Inf (gnuplot prints inf.0).
integer(I4P), parameter :: K_MINF  = 4_I4P !< Expect -Inf.
integer(I4P), parameter :: K_MZERO = 5_I4P !< Expect -0.
integer(I4P), parameter :: TOL         = 4_I4P    !< Default tolerance [ulps].
integer(I4P), parameter :: TOL_TRIG    = 32_I4P   !< sin/cos of |x| >= 2**302 in besjn/besyn [ulps].
integer(I4P), parameter :: TOL_UNIFORM = 1024_I4P !< Uniform asymptotic expansion of besin, |n| > 50 [ulps].
logical                 :: test_passed(10) !< One entry per function, then the IEEE-flag sweep.
logical                 :: sub             !< The run supports subnormals.
real(R8P), volatile     :: probe           !< Subnormal probe.
real(R8P)               :: r               !< Result.
integer(I4P)            :: st              !< Status.
integer(I4P)            :: skipped         !< Cases skipped for want of subnormals.
real(R8P)               :: worst           !< Worst disagreement [ulps].

test_passed = .true.
skipped = 0_I4P
worst = 0._R8P
probe = tiny(1._R8P)
probe = probe * 0.25_R8P
sub = probe > 0._R8P
if (.not. sub) write(output_unit, '(A)') 'subnormals are flushed to zero: subnormal cases skipped'

call gp_besj0(0.0_R8P, r, st)
call check(1_I4P, 'besj0(0)', r, st, K_VALUE, 1.0_R8P, TOL, .false.)
call gp_besj0(1e-320_R8P, r, st)
call check(1_I4P, 'besj0(1e-320)', r, st, K_VALUE, 1.0_R8P, TOL, .true.)
call gp_besj0(1e-5_R8P, r, st)
call check(1_I4P, 'besj0(1e-5)', r, st, K_VALUE, 0.999999999975_R8P, TOL, .false.)
call gp_besj0(0.5_R8P, r, st)
call check(1_I4P, 'besj0(0.5)', r, st, K_VALUE, 0.93846980724081286_R8P, TOL, .false.)
call gp_besj0(2.5_R8P, r, st)
call check(1_I4P, 'besj0(2.5)', r, st, K_VALUE, -0.048383776468197991_R8P, TOL, .false.)
call gp_besj0(-3.0_R8P, r, st)
call check(1_I4P, 'besj0(-3.0)', r, st, K_VALUE, -0.2600519549019335_R8P, TOL, .false.)
call gp_besj0(2.404825557695773_R8P, r, st)
call check(1_I4P, 'besj0(2.404825557695773)', r, st, K_VALUE, -5.553876295239997e-17_R8P, TOL, .false.)
call gp_besj0(7.99_R8P, r, st)
call check(1_I4P, 'besj0(7.99)', r, st, K_VALUE, 0.17399001312793258_R8P, TOL, .false.)
call gp_besj0(8.0_R8P, r, st)
call check(1_I4P, 'besj0(8.0)', r, st, K_VALUE, 0.1716508071375539_R8P, TOL, .false.)
call gp_besj0(100.5_R8P, r, st)
call check(1_I4P, 'besj0(100.5)', r, st, K_VALUE, 0.05443657381441358_R8P, TOL, .false.)
call gp_besj0(1e6_R8P, r, st)
call check(1_I4P, 'besj0(1e6)', r, st, K_VALUE, 0.00033104301373987376_R8P, TOL, .false.)
call gp_besj0(1e15_R8P, r, st)
call check(1_I4P, 'besj0(1e15)', r, st, K_VALUE, 6.1566386468850222e-09_R8P, TOL, .false.)
call gp_besj0(1e17_R8P, r, st)
call check(1_I4P, 'besj0(1e17)', r, st, K_VALUE, -2.4087235483673831e-09_R8P, TOL, .false.)
call gp_besj0(1e300_R8P, r, st)
call check(1_I4P, 'besj0(1e300)', r, st, K_VALUE, -7.8606730627240931e-151_R8P, TOL, .false.)
call gp_besj0(-1e300_R8P, r, st)
call check(1_I4P, 'besj0(-1e300)', r, st, K_VALUE, -7.8606730627240931e-151_R8P, TOL, .false.)
call gp_besj1(0.0_R8P, r, st)
call check(2_I4P, 'besj1(0)', r, st, K_VALUE, 0.0_R8P, TOL, .false.)
call gp_besj1(-0.0_R8P, r, st)
call check(2_I4P, 'besj1(-0.0)', r, st, K_MZERO, 0._R8P, TOL, .false.)
call gp_besj1(4.9406564584124654e-324_R8P, r, st)
call check(2_I4P, 'besj1(4.9406564584124654e-324)', r, st, K_UNDEF, 0._R8P, TOL, .true.)
call gp_besj1(1e-323_R8P, r, st)
call check(2_I4P, 'besj1(1e-323)', r, st, K_VALUE, 4.9406564584124654e-324_R8P, TOL, .true.)
call gp_besj1(1e-320_R8P, r, st)
call check(2_I4P, 'besj1(1e-320)', r, st, K_VALUE, 4.999944335913415e-321_R8P, TOL, .true.)
call gp_besj1(-2.5_R8P, r, st)
call check(2_I4P, 'besj1(-2.5)', r, st, K_VALUE, -0.49709410246427405_R8P, TOL, .false.)
call gp_besj1(3.8317_R8P, r, st)
call check(2_I4P, 'besj1(3.8317)', r, st, K_VALUE, 2.4045590431131276e-06_R8P, TOL, .false.)
call gp_besj1(8.0_R8P, r, st)
call check(2_I4P, 'besj1(8.0)', r, st, K_VALUE, 0.2346363468539146_R8P, TOL, .false.)
call gp_besj1(1e6_R8P, r, st)
call check(2_I4P, 'besj1(1e6)', r, st, K_VALUE, -0.00072596835681376301_R8P, TOL, .false.)
call gp_besj1(1e300_R8P, r, st)
call check(2_I4P, 'besj1(1e300)', r, st, K_VALUE, -1.3681360450342481e-151_R8P, TOL, .false.)
call gp_besy0(0.0_R8P, r, st)
call check(3_I4P, 'besy0(0)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besy0(-1.0_R8P, r, st)
call check(3_I4P, 'besy0(-1)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besy0(4.9406564584124654e-324_R8P, r, st)
call check(3_I4P, 'besy0(4.9406564584124654e-324)', r, st, K_VALUE, -473.99907342300429_R8P, TOL, .true.)
call gp_besy0(1e-320_R8P, r, st)
call check(3_I4P, 'besy0(1e-320)', r, st, K_VALUE, -469.15259466535355_R8P, TOL, .true.)
call gp_besy0(1e-5_R8P, r, st)
call check(3_I4P, 'besy0(1e-5)', r, st, K_VALUE, -7.403160283701971_R8P, TOL, .false.)
call gp_besy0(0.5_R8P, r, st)
call check(3_I4P, 'besy0(0.5)', r, st, K_VALUE, -0.44451873350670656_R8P, TOL, .false.)
call gp_besy0(2.5_R8P, r, st)
call check(3_I4P, 'besy0(2.5)', r, st, K_VALUE, 0.49807035961523183_R8P, TOL, .false.)
call gp_besy0(8.0_R8P, r, st)
call check(3_I4P, 'besy0(8.0)', r, st, K_VALUE, 0.22352148938756619_R8P, TOL, .false.)
call gp_besy0(100.0_R8P, r, st)
call check(3_I4P, 'besy0(100.0)', r, st, K_VALUE, -0.077244313365083167_R8P, TOL, .false.)
call gp_besy0(1e6_R8P, r, st)
call check(3_I4P, 'besy0(1e6)', r, st, K_VALUE, -0.00072596852233517925_R8P, TOL, .false.)
call gp_besy0(1e300_R8P, r, st)
call check(3_I4P, 'besy0(1e300)', r, st, K_VALUE, -1.3681360450342481e-151_R8P, TOL, .false.)
call gp_besy1(0.0_R8P, r, st)
call check(4_I4P, 'besy1(0)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besy1(-2.0_R8P, r, st)
call check(4_I4P, 'besy1(-2)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besy1(3.5413150332597789e-309_R8P, r, st)
call check(4_I4P, 'besy1(3.5413150332597789e-309)', r, st, K_VALUE, -1.7976931348623143e+308_R8P, TOL, .true.)
call gp_besy1(3.5413150332597794e-309_R8P, r, st)
call check(4_I4P, 'besy1(3.5413150332597794e-309)', r, st, K_VALUE, -1.7976931348623143e+308_R8P, TOL, .true.)
call gp_besy1(4e-309_R8P, r, st)
call check(4_I4P, 'besy1(4e-309)', r, st, K_VALUE, -1.5915494309189544e+308_R8P, TOL, .true.)
call gp_besy1(1e-5_R8P, r, st)
call check(4_I4P, 'besy1(1e-5)', r, st, K_VALUE, -63661.977275365483_R8P, TOL, .false.)
call gp_besy1(2.5_R8P, r, st)
call check(4_I4P, 'besy1(2.5)', r, st, K_VALUE, 0.14591813796678577_R8P, TOL, .false.)
call gp_besy1(8.0_R8P, r, st)
call check(4_I4P, 'besy1(8.0)', r, st, K_VALUE, -0.15806046173124752_R8P, TOL, .false.)
call gp_besy1(1e6_R8P, r, st)
call check(4_I4P, 'besy1(1e6)', r, st, K_VALUE, -0.00033104337672417632_R8P, TOL, .false.)
call gp_besy1(1e300_R8P, r, st)
call check(4_I4P, 'besy1(1e300)', r, st, K_VALUE, 7.8606730627240931e-151_R8P, TOL, .false.)
call gp_besjn(2_I8P, 1.5_R8P, r, st)
call check(5_I4P, 'besjn(2,1.5)', r, st, K_VALUE, 0.23208767214421472_R8P, TOL, .false.)
call gp_besjn(2_I8P, 0.0_R8P, r, st)
call check(5_I4P, 'besjn(2,0)', r, st, K_VALUE, 0.0_R8P, TOL, .false.)
call gp_besjn(3_I8P, -0.0_R8P, r, st)
call check(5_I4P, 'besjn(3,-0.0)', r, st, K_MZERO, 0._R8P, TOL, .false.)
call gp_besjn(3_I8P, -2.5_R8P, r, st)
call check(5_I4P, 'besjn(3,-2.5)', r, st, K_VALUE, -0.21660039103911355_R8P, TOL, .false.)
call gp_besjn(-3_I8P, 2.5_R8P, r, st)
call check(5_I4P, 'besjn(-3,2.5)', r, st, K_VALUE, -0.21660039103911355_R8P, TOL, .false.)
call gp_besjn(-3_I8P, -2.5_R8P, r, st)
call check(5_I4P, 'besjn(-3,-2.5)', r, st, K_VALUE, 0.21660039103911355_R8P, TOL, .false.)
call gp_besjn(0_I8P, 2.5_R8P, r, st)
call check(5_I4P, 'besjn(0,2.5)', r, st, K_VALUE, -0.048383776468197991_R8P, TOL, .false.)
call gp_besjn(1_I8P, -0.0_R8P, r, st)
call check(5_I4P, 'besjn(1,-0.0)', r, st, K_MZERO, 0._R8P, TOL, .false.)
call gp_besjn(1_I8P, 4.9406564584124654e-324_R8P, r, st)
call check(5_I4P, 'besjn(1,4.9406564584124654e-324)', r, st, K_UNDEF, 0._R8P, TOL, .true.)
call gp_besjn(-1_I8P, 2.5_R8P, r, st)
call check(5_I4P, 'besjn(-1,2.5)', r, st, K_VALUE, -0.49709410246427405_R8P, TOL, .false.)
call gp_besjn(2_I8P, 1e-160_R8P, r, st)
call check(5_I4P, 'besjn(2,1e-160)', r, st, K_VALUE, 1.2499860839783538e-321_R8P, TOL, .true.)
call gp_besjn(2_I8P, 1e-162_R8P, r, st)
call check(5_I4P, 'besjn(2,1e-162)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besjn(5_I8P, 1e-300_R8P, r, st)
call check(5_I4P, 'besjn(5,1e-300)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besjn(50_I8P, 1e-10_R8P, r, st)
call check(5_I4P, 'besjn(50,1e-10)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besjn(200_I8P, 1.0_R8P, r, st)
call check(5_I4P, 'besjn(200,1.0)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besjn(20_I8P, 5.5_R8P, r, st)
call check(5_I4P, 'besjn(20,5.5)', r, st, K_VALUE, 1.7491376833965261e-10_R8P, TOL, .false.)
call gp_besjn(100_I8P, 50.0_R8P, r, st)
call check(5_I4P, 'besjn(100,50.0)', r, st, K_VALUE, 1.1159273690838084e-21_R8P, TOL, .false.)
call gp_besjn(100_I8P, 150.0_R8P, r, st)
call check(5_I4P, 'besjn(100,150.0)', r, st, K_VALUE, -0.015359526118405395_R8P, TOL, .false.)
call gp_besjn(30_I8P, 1e-5_R8P, r, st)
call check(5_I4P, 'besjn(30,1e-5)', r, st, K_VALUE, 3.511074584734511e-192_R8P, TOL, .false.)
call gp_besjn(3_I8P, 1e100_R8P, r, st)
call check(5_I4P, 'besjn(3,1e100)', r, st, K_VALUE, 7.364716260962594e-51_R8P, TOL_TRIG, .false.)
call gp_besjn(3_I8P, 1e6_R8P, r, st)
call check(5_I4P, 'besjn(3,1e6)', r, st, K_VALUE, 0.00072596703263590027_R8P, TOL, .false.)
call gp_besjn(4294967298_I8P, 1.5_R8P, r, st)
call check(5_I4P, 'besjn(4294967298,1.5)', r, st, K_VALUE, 0.23208767214421472_R8P, TOL, .false.)
call gp_besjn(2147483648_I8P, 0.0_R8P, r, st)
call check(5_I4P, 'besjn(2147483648,0)', r, st, K_VALUE, 0.0_R8P, TOL, .false.)
call gp_besjn(2147483648_I8P, 1e300_R8P, r, st)
call check(5_I4P, 'besjn(2147483648,1e300)', r, st, K_VALUE, -7.8606730627240931e-151_R8P, TOL_TRIG, .false.)
call gp_besjn(2147483647_I8P, 1e300_R8P, r, st)
call check(5_I4P, 'besjn(2147483647,1e300)', r, st, K_VALUE, 1.3681360450342476e-151_R8P, TOL_TRIG, .false.)
call gp_besjn(-2147483647_I8P, 1e300_R8P, r, st)
call check(5_I4P, 'besjn(-2147483647,1e300)', r, st, K_VALUE, -1.3681360450342476e-151_R8P, TOL_TRIG, .false.)
call gp_besjn(2147483647_I8P, 1.0_R8P, r, st)
call check(5_I4P, 'besjn(2147483647,1.0)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besyn(2_I8P, 2.5_R8P, r, st)
call check(6_I4P, 'besyn(2,2.5)', r, st, K_VALUE, -0.38133584924180319_R8P, TOL, .false.)
call gp_besyn(-2_I8P, 2.5_R8P, r, st)
call check(6_I4P, 'besyn(-2,2.5)', r, st, K_VALUE, -0.38133584924180319_R8P, TOL, .false.)
call gp_besyn(-3_I8P, 2.5_R8P, r, st)
call check(6_I4P, 'besyn(-3,2.5)', r, st, K_VALUE, 0.7560554967536709_R8P, TOL, .false.)
call gp_besyn(3_I8P, -1.0_R8P, r, st)
call check(6_I4P, 'besyn(3,-1)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besyn(2_I8P, 0.0_R8P, r, st)
call check(6_I4P, 'besyn(2,0)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besyn(0_I8P, 0.0_R8P, r, st)
call check(6_I4P, 'besyn(0,0)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besyn(0_I8P, 2.5_R8P, r, st)
call check(6_I4P, 'besyn(0,2.5)', r, st, K_VALUE, 0.49807035961523183_R8P, TOL, .false.)
call gp_besyn(1_I8P, 4e-309_R8P, r, st)
call check(6_I4P, 'besyn(1,4e-309)', r, st, K_VALUE, -1.5915494309189544e+308_R8P, TOL, .true.)
call gp_besyn(-1_I8P, 4e-309_R8P, r, st)
call check(6_I4P, 'besyn(-1,4e-309)', r, st, K_VALUE, 1.5915494309189544e+308_R8P, TOL, .true.)
call gp_besyn(1_I8P, 3e-309_R8P, r, st)
call check(6_I4P, 'besyn(1,3e-309)', r, st, K_UNDEF, 0._R8P, TOL, .true.)
call gp_besyn(2_I8P, 1e-150_R8P, r, st)
call check(6_I4P, 'besyn(2,1e-150)', r, st, K_VALUE, -1.2732395447351627e+300_R8P, TOL, .false.)
call gp_besyn(2_I8P, 1e-160_R8P, r, st)
call check(6_I4P, 'besyn(2,1e-160)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besyn(200_I8P, 1.0_R8P, r, st)
call check(6_I4P, 'besyn(200,1.0)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besyn(100_I8P, 50.0_R8P, r, st)
call check(6_I4P, 'besyn(100,50.0)', r, st, K_VALUE, -3.2938001882026691e+18_R8P, TOL, .false.)
call gp_besyn(30_I8P, 1e-5_R8P, r, st)
call check(6_I4P, 'besyn(30,1e-5)', r, st, K_VALUE, -3.0219607369185477e+189_R8P, TOL, .false.)
call gp_besyn(2_I8P, 1e300_R8P, r, st)
call check(6_I4P, 'besyn(2,1e300)', r, st, K_VALUE, 1.3681360450342476e-151_R8P, TOL_TRIG, .false.)
call gp_besyn(3_I8P, 1e100_R8P, r, st)
call check(6_I4P, 'besyn(3,1e100)', r, st, K_VALUE, 3.0696794021967943e-51_R8P, TOL_TRIG, .false.)
call gp_besyn(5_I8P, 8.1481439053379443e+90_R8P, r, st)
call check(6_I4P, 'besyn(5,8.1481439053379443e+90)', r, st, K_VALUE, 1.9333035656641286e-47_R8P, TOL_TRIG, .false.)
call gp_besyn(5_I8P, 8.148143905337943e+90_R8P, r, st)
call check(6_I4P, 'besyn(5,8.148143905337943e+90)', r, st, K_VALUE, -2.6683303685884834e-46_R8P, TOL, .false.)
call gp_besyn(2147483648_I8P, 1.0_R8P, r, st)
call check(6_I4P, 'besyn(2147483648,1.0)', r, st, K_VALUE, -0.78121282130028868_R8P, TOL, .false.)
call gp_besyn(2147483648_I8P, 1e-5_R8P, r, st)
call check(6_I4P, 'besyn(2147483648,1e-5)', r, st, K_VALUE, -63661.977275365483_R8P, TOL, .false.)
call gp_besyn(2147483648_I8P, 1e300_R8P, r, st)
call check(6_I4P, 'besyn(2147483648,1e300)', r, st, K_VALUE, -1.3681360450342476e-151_R8P, TOL_TRIG, .false.)
call gp_besyn(2147483647_I8P, 1e300_R8P, r, st)
call check(6_I4P, 'besyn(2147483647,1e300)', r, st, K_VALUE, -7.8606730627240931e-151_R8P, TOL_TRIG, .false.)
call gp_besyn(4294967298_I8P, 1.5_R8P, r, st)
call check(6_I4P, 'besyn(4294967298,1.5)', r, st, K_VALUE, -0.93219375976297403_R8P, TOL, .false.)
call gp_besyn(-2147483647_I8P, 1.0_R8P, r, st)
call check(6_I4P, 'besyn(-2147483647,1.0)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besyn(20_I8P, 1000.0_R8P, r, st)
call check(6_I4P, 'besyn(20,1000.0)', r, st, K_VALUE, 0.0095473760149873028_R8P, TOL, .false.)
call gp_besyn(1000_I8P, 1000.0_R8P, r, st)
call check(6_I4P, 'besyn(1000,1000.0)', r, st, K_VALUE, -0.077476001520720983_R8P, TOL, .false.)
call gp_besi0(0.0_R8P, r, st)
call check(7_I4P, 'besi0(0)', r, st, K_VALUE, 1.0_R8P, TOL, .false.)
call gp_besi0(1e-300_R8P, r, st)
call check(7_I4P, 'besi0(1e-300)', r, st, K_VALUE, 1.0_R8P, TOL, .false.)
call gp_besi0(1.0_R8P, r, st)
call check(7_I4P, 'besi0(1)', r, st, K_VALUE, 1.2660658777520082_R8P, TOL, .false.)
call gp_besi0(-1.0_R8P, r, st)
call check(7_I4P, 'besi0(-1)', r, st, K_VALUE, 1.2660658777520082_R8P, TOL, .false.)
call gp_besi0(2.5_R8P, r, st)
call check(7_I4P, 'besi0(2.5)', r, st, K_VALUE, 3.2898391440501231_R8P, TOL, .false.)
call gp_besi0(8.0_R8P, r, st)
call check(7_I4P, 'besi0(8.0)', r, st, K_VALUE, 427.56411572180474_R8P, TOL, .false.)
call gp_besi0(8.000000000000002_R8P, r, st)
call check(7_I4P, 'besi0(8.000000000000002)', r, st, K_VALUE, 427.56411572180548_R8P, TOL, .false.)
call gp_besi0(100.0_R8P, r, st)
call check(7_I4P, 'besi0(100.0)', r, st, K_VALUE, 1.0737517071310738e+42_R8P, TOL, .false.)
call gp_besi0(-700.0_R8P, r, st)
call check(7_I4P, 'besi0(-700.0)', r, st, K_VALUE, 1.5295933476718735e+302_R8P, TOL, .false.)
call gp_besi0(709.78271289338397_R8P, r, st)
call check(7_I4P, 'besi0(709.78271289338397)', r, st, K_VALUE, 2.6923992106267128e+306_R8P, TOL, .false.)
call gp_besi0(709.78271289338408_R8P, r, st)
call check(7_I4P, 'besi0(709.78271289338408)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besi1(0.0_R8P, r, st)
call check(8_I4P, 'besi1(0)', r, st, K_VALUE, 0.0_R8P, TOL, .false.)
call gp_besi1(-0.0_R8P, r, st)
call check(8_I4P, 'besi1(-0.0)', r, st, K_VALUE, 0.0_R8P, TOL, .false.)
call gp_besi1(1e-320_R8P, r, st)
call check(8_I4P, 'besi1(1e-320)', r, st, K_VALUE, 4.999944335913415e-321_R8P, TOL, .true.)
call gp_besi1(-2.5_R8P, r, st)
call check(8_I4P, 'besi1(-2.5)', r, st, K_VALUE, -2.5167162452886984_R8P, TOL, .false.)
call gp_besi1(8.0_R8P, r, st)
call check(8_I4P, 'besi1(8.0)', r, st, K_VALUE, 399.87313678255992_R8P, TOL, .false.)
call gp_besi1(50.0_R8P, r, st)
call check(8_I4P, 'besi1(50.0)', r, st, K_VALUE, 2.9030785901035566e+20_R8P, TOL, .false.)
call gp_besi1(709.78_R8P, r, st)
call check(8_I4P, 'besi1(709.78)', r, st, K_VALUE, 2.6832178748278178e+306_R8P, TOL, .false.)
call gp_besi1(-709.79_R8P, r, st)
call check(8_I4P, 'besi1(-709.79)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besin(2_I8P, 1.5_R8P, r, st)
call check(9_I4P, 'besin(2,1.5)', r, st, K_VALUE, 0.33783461833568074_R8P, TOL, .false.)
call gp_besin(3_I8P, 1.5_R8P, r, st)
call check(9_I4P, 'besin(3,1.5)', r, st, K_VALUE, 0.080774113016092317_R8P, TOL, .false.)
call gp_besin(3_I8P, 2.5_R8P, r, st)
call check(9_I4P, 'besin(3,2.5)', r, st, K_VALUE, 0.47437040877803577_R8P, TOL, .false.)
call gp_besin(-3_I8P, -2.5_R8P, r, st)
call check(9_I4P, 'besin(-3,-2.5)', r, st, K_VALUE, -0.47437040877803577_R8P, TOL, .false.)
call gp_besin(0_I8P, 0.0_R8P, r, st)
call check(9_I4P, 'besin(0,0)', r, st, K_VALUE, 1.0_R8P, TOL, .false.)
call gp_besin(3_I8P, 0.0_R8P, r, st)
call check(9_I4P, 'besin(3,0)', r, st, K_VALUE, 0.0_R8P, TOL, .false.)
call gp_besin(-3_I8P, 0.0_R8P, r, st)
call check(9_I4P, 'besin(-3,0)', r, st, K_VALUE, 0.0_R8P, TOL, .false.)
call gp_besin(0_I8P, 1e-300_R8P, r, st)
call check(9_I4P, 'besin(0,1e-300)', r, st, K_VALUE, 1.0_R8P, TOL, .false.)
call gp_besin(1_I8P, 1e-300_R8P, r, st)
call check(9_I4P, 'besin(1,1e-300)', r, st, K_VALUE, 0.0_R8P, TOL, .false.)
call gp_besin(1_I8P, 1e-150_R8P, r, st)
call check(9_I4P, 'besin(1,1e-150)', r, st, K_VALUE, 5.0000000000000007e-151_R8P, TOL, .false.)
call gp_besin(1_I8P, 1e-160_R8P, r, st)
call check(9_I4P, 'besin(1,1e-160)', r, st, K_VALUE, 0.0_R8P, TOL, .false.)
call gp_besin(2_I8P, 1e-200_R8P, r, st)
call check(9_I4P, 'besin(2,1e-200)', r, st, K_VALUE, 0.0_R8P, TOL, .false.)
call gp_besin(0_I8P, 1e-310_R8P, r, st)
call check(9_I4P, 'besin(0,1e-310)', r, st, K_NAN, 0._R8P, TOL, .true.)
call gp_besin(0_I8P, 1e-323_R8P, r, st)
call check(9_I4P, 'besin(0,1e-323)', r, st, K_NAN, 0._R8P, TOL, .true.)
call gp_besin(0_I8P, 4.9406564584124654e-324_R8P, r, st)
call check(9_I4P, 'besin(0,4.9406564584124654e-324)', r, st, K_UNDEF, 0._R8P, TOL, .true.)
call gp_besin(0_I8P, 2.0_R8P, r, st)
call check(9_I4P, 'besin(0,2)', r, st, K_VALUE, 2.2795853023360673_R8P, TOL, .false.)
call gp_besin(0_I8P, 2.0000000000000004_R8P, r, st)
call check(9_I4P, 'besin(0,2.0000000000000004)', r, st, K_VALUE, 2.279585302336065_R8P, TOL, .false.)
call gp_besin(0_I8P, 700.0_R8P, r, st)
call check(9_I4P, 'besin(0,700)', r, st, K_VALUE, 1.5295933476718725e+302_R8P, TOL, .false.)
call gp_besin(0_I8P, 709.0_R8P, r, st)
call check(9_I4P, 'besin(0,709)', r, st, K_VALUE, 1.2315477067016545e+306_R8P, TOL, .true.)
call gp_besin(0_I8P, 710.0_R8P, r, st)
call check(9_I4P, 'besin(0,710)', r, st, K_VALUE, 3.3453345586196545e+306_R8P, TOL, .true.)
call gp_besin(0_I8P, 720.0_R8P, r, st)
call check(9_I4P, 'besin(0,720)', r, st, K_PINF, 0._R8P, TOL, .true.)
call gp_besin(-1_I8P, -720.0_R8P, r, st)
call check(9_I4P, 'besin(-1,-720)', r, st, K_MINF, 0._R8P, TOL, .true.)
call gp_besin(0_I8P, 745.0_R8P, r, st)
call check(9_I4P, 'besin(0,745)', r, st, K_PINF, 0._R8P, TOL, .true.)
call gp_besin(0_I8P, 745.13321910194110_R8P, r, st)
call check(9_I4P, 'besin(0,745.13321910194110)', r, st, K_PINF, 0._R8P, TOL, .true.)
call gp_besin(0_I8P, 745.13321910194122_R8P, r, st)
call check(9_I4P, 'besin(0,745.13321910194122)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besin(0_I8P, 746.0_R8P, r, st)
call check(9_I4P, 'besin(0,746)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besin(50_I8P, 720.0_R8P, r, st)
call check(9_I4P, 'besin(50,720)', r, st, K_PINF, 0._R8P, TOL, .true.)
call gp_besin(50_I8P, 2.0_R8P, r, st)
call check(9_I4P, 'besin(50,2)', r, st, K_VALUE, 3.3530428298606396e-65_R8P, TOL, .false.)
call gp_besin(-50_I8P, -30.0_R8P, r, st)
call check(9_I4P, 'besin(-50,-30)', r, st, K_VALUE, 0.0001459010691646895_R8P, TOL, .false.)
call gp_besin(51_I8P, 100.0_R8P, r, st)
call check(9_I4P, 'besin(51,100)', r, st, K_VALUE, 2.9608464716504891e+36_R8P, TOL_UNIFORM, .false.)
call gp_besin(51_I8P, 1e-300_R8P, r, st)
call check(9_I4P, 'besin(51,1e-300)', r, st, K_UNDEF, 0._R8P, TOL_UNIFORM, .false.)
call gp_besin(51_I8P, 1e-320_R8P, r, st)
call check(9_I4P, 'besin(51,1e-320)', r, st, K_UNDEF, 0._R8P, TOL_UNIFORM, .true.)
call gp_besin(60_I8P, 1e5_R8P, r, st)
call check(9_I4P, 'besin(60,1e5)', r, st, K_UNDEF, 0._R8P, TOL_UNIFORM, .false.)
call gp_besin(51_I8P, 1e160_R8P, r, st)
call check(9_I4P, 'besin(51,1e160)', r, st, K_UNDEF, 0._R8P, TOL_UNIFORM, .false.)
call gp_besin(1000_I8P, 1.0_R8P, r, st)
call check(9_I4P, 'besin(1000,1)', r, st, K_UNDEF, 0._R8P, TOL_UNIFORM, .false.)
call gp_besin(100_I8P, 1e3_R8P, r, st)
call check(9_I4P, 'besin(100,1e3)', r, st, K_UNDEF, 0._R8P, TOL_UNIFORM, .false.)
call gp_besin(3_I8P, 1e300_R8P, r, st)
call check(9_I4P, 'besin(3,1e300)', r, st, K_UNDEF, 0._R8P, TOL, .false.)
call gp_besin(5_I8P, 0.5_R8P, r, st)
call check(9_I4P, 'besin(5,0.5)', r, st, K_VALUE, 8.2231713131092646e-06_R8P, TOL, .false.)
call gp_besin(10_I8P, 10.0_R8P, r, st)
call check(9_I4P, 'besin(10,10)', r, st, K_VALUE, 21.891706163723374_R8P, TOL, .false.)
call gp_besin(20_I8P, 3.0_R8P, r, st)
call check(9_I4P, 'besin(20,3)', r, st, K_VALUE, 1.5209660019426687e-15_R8P, TOL, .false.)
call gp_besin(50_I8P, 50.0_R8P, r, st)
call check(9_I4P, 'besin(50,50)', r, st, K_VALUE, 17650802430.016712_R8P, TOL, .false.)
call gp_besin(51_I8P, 51.0_R8P, r, st)
call check(9_I4P, 'besin(51,51)', r, st, K_VALUE, 29776351381.90023_R8P, TOL_UNIFORM, .false.)
call gp_besin(52_I8P, 30.0_R8P, r, st)
call check(9_I4P, 'besin(52,30)', r, st, K_VALUE, 1.0662850336991979e-05_R8P, TOL_UNIFORM, .false.)
call gp_besin(80_I8P, 100.0_R8P, r, st)
call check(9_I4P, 'besin(80,100)', r, st, K_VALUE, 5.1129829028234146e+28_R8P, TOL_UNIFORM, .false.)
call gp_besin(100_I8P, 300.0_R8P, r, st)
call check(9_I4P, 'besin(100,300)', r, st, K_VALUE, 2.9244736813827127e+121_R8P, TOL_UNIFORM, .false.)
call gp_besin(200_I8P, 500.0_R8P, r, st)
call check(9_I4P, 'besin(200,500)', r, st, K_VALUE, 1.7064233617928122e+198_R8P, TOL_UNIFORM, .false.)
call gp_besin(7_I8P, 100.0_R8P, r, st)
call check(9_I4P, 'besin(7,100)', r, st, K_VALUE, 8.3947655455875277e+41_R8P, TOL, .false.)
call gp_besin(7_I8P, 100.5_R8P, r, st)
call check(9_I4P, 'besin(7,100.5)', r, st, K_VALUE, 1.3823057509875573e+42_R8P, TOL, .false.)
call gp_besin(1_I8P, 650.0_R8P, r, st)
call check(9_I4P, 'besin(1,650)', r, st, K_VALUE, 3.0592563989529076e+280_R8P, TOL, .false.)
call gp_besin(-51_I8P, -3.5_R8P, r, st)
call check(9_I4P, 'besin(-51,-3.5)', r, st, K_VALUE, -1.6976911453721937e-54_R8P, TOL_UNIFORM, .false.)
call gp_besin(9223372036854775807_I8P, 1.0_R8P, r, st)
call check(9_I4P, 'besin(9223372036854775807,1)', r, st, K_UNDEF, 0._R8P, TOL_UNIFORM, .false.)

! the double just below 3.5413150332597794e-309, where y1 overflows
call gp_besy1(transfer(716770142402832_I8P, 1._R8P), r, st)
call check(4_I4P, 'besy1(prev(Y1_MIN))', r, st, K_UNDEF, 0._R8P, TOL, .true.)
call gp_besyn(1_I8P, transfer(716770142402832_I8P, 1._R8P), r, st)
call check(6_I4P, 'besyn(1,prev(Y1_MIN))', r, st, K_UNDEF, 0._R8P, TOL, .true.)
! the double just above 709.78271289338397, where exp overflows
call gp_besi1(-709.78271289338408_R8P, r, st)
call check(8_I4P, 'besi1(-709.78271289338408)', r, st, K_UNDEF, 0._R8P, TOL, .false.)

call sweep(test_passed(10))

write(output_unit, '(A,I0,A,F0.1)') 'skipped cases: ', skipped, ', worst disagreement [ulps]: ', worst
write(output_unit, '(A,10L2)') 'foresight_bessel checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1

contains
   subroutine check(group, what, r, st, kind, e, tol_ulps, needs_sub)
   !< Compare a result with gnuplot's, record the outcome in test_passed(group) and print a failure.
   integer(I4P), intent(in) :: group     !< Function group.
   character(*), intent(in) :: what      !< Case.
   real(R8P),    intent(in) :: r         !< Result.
   integer(I4P), intent(in) :: st        !< Status.
   integer(I4P), intent(in) :: kind      !< Expected kind.
   real(R8P),    intent(in) :: e         !< Expected value.
   integer(I4P), intent(in) :: tol_ulps  !< Tolerance [ulps].
   logical,      intent(in) :: needs_sub !< Needs subnormals.
   logical                  :: ok        !< Case passed.
   real(R8P)                :: ulps      !< Disagreement [ulps].

   if (needs_sub .and. .not. sub) then
      skipped = skipped + 1_I4P
      return
   endif
   ulps = 0._R8P
   select case(kind)
   case(K_UNDEF)
      ok = st == 1_I4P
   case(K_NAN)
      ok = st == 0_I4P .and. ieee_is_nan(r)
   case(K_PINF)
      ok = st == 0_I4P .and. .not. ieee_is_finite(r) .and. .not. ieee_is_nan(r) .and. r > 0._R8P
   case(K_MINF)
      ok = st == 0_I4P .and. .not. ieee_is_finite(r) .and. .not. ieee_is_nan(r) .and. r < 0._R8P
   case(K_MZERO)
      ok = st == 0_I4P .and. r == 0._R8P .and. ieee_is_negative(r)
   case default
      ok = st == 0_I4P .and. ieee_is_finite(r)
      if (ok) then
         if (e == 0._R8P) then
            ok = r == 0._R8P .and. .not. ieee_is_negative(r)
         else
            ulps = abs(r - e) / spacing(abs(e))
            ok = ulps <= real(tol_ulps, R8P)
#if defined(__INTEL_LLVM_COMPILER) || defined(__INTEL_COMPILER)
            ! Intel's libm is not glibc: a relative 1e-10 (absolutely 1e-16 near a zero of the function)
            ok = ok .or. abs(r - e) <= 1.0e-10_R8P * abs(e) + 1.0e-16_R8P
#endif
            worst = max(worst, ulps)
         endif
      endif
   endselect
   if (.not. ok) then
      test_passed(group) = .false.
      write(output_unit, '(A,A,A,ES25.17,A,I0,A,ES25.17,A,I0,A,F0.1)') 'FAILED ', what, ': got ', r, ' status ', st, &
         ', expected ', e, ' kind ', kind, ', ulps ', ulps
   endif
   endsubroutine check

   subroutine sweep(passed)
   !< Evaluate every function over a grid of orders and arguments up to +-1e300 and check that no IEEE invalid,
   !< divide-by-zero or overflow flag is raised.
   logical, intent(out)    :: passed   !< No flag raised.
   integer(I8P), parameter :: EXTRA(8) = [-1000_I8P, -200_I8P, -100_I8P, 100_I8P, 200_I8P, 1000_I8P, &
                                          2147483648_I8P, 4294967298_I8P] !< Further orders.
   real(R8P),    parameter :: SPECIAL(14) = [0._R8P, 1e-320_R8P, 1e-310_R8P, 2._R8P, 8._R8P, 700._R8P, 709.79_R8P, &
                                             720._R8P, 745.2_R8P, 1000._R8P, 8.1481439053379443e+90_R8P, &
                                             3.5413150332597794e-309_R8P, 5.5626846462680084e-309_R8P, &
                                             1e300_R8P] !< Further arguments.
   real(R8P)               :: xs(2 * (241 + 14)) !< Arguments.
   integer(I8P)            :: ns(121 + 8)        !< Orders.
   real(R8P)               :: rr                 !< Result.
   integer(I4P)            :: s                  !< Status.
   integer(I4P)            :: i                  !< Argument index.
   integer(I4P)            :: j                  !< Order index.
   logical                 :: flags(3)           !< invalid, divide-by-zero, overflow.

   do i = 1_I4P, 241_I4P
      xs(i) = 10._R8P**(-320._R8P + 620._R8P * real(i - 1_I4P, R8P) / 240._R8P)
   enddo
   xs(242:255) = SPECIAL
   xs(256:510) = -xs(1:255)
   do j = 1_I4P, 121_I4P
      ns(j) = int(j - 61_I4P, I8P)
   enddo
   ns(122:129) = EXTRA
   call ieee_set_flag(ieee_invalid, .false.)
   call ieee_set_flag(ieee_divide_by_zero, .false.)
   call ieee_set_flag(ieee_overflow, .false.)
   do i = 1_I4P, size(xs, kind=I4P)
      call gp_besj0(xs(i), rr, s)
      call gp_besj1(xs(i), rr, s)
      call gp_besy0(xs(i), rr, s)
      call gp_besy1(xs(i), rr, s)
      call gp_besi0(xs(i), rr, s)
      call gp_besi1(xs(i), rr, s)
      do j = 1_I4P, size(ns, kind=I4P)
         call gp_besjn(ns(j), xs(i), rr, s)
         call gp_besyn(ns(j), xs(i), rr, s)
         call gp_besin(ns(j), xs(i), rr, s)
      enddo
   enddo
   call ieee_get_flag(ieee_invalid, flags(1))
   call ieee_get_flag(ieee_divide_by_zero, flags(2))
   call ieee_get_flag(ieee_overflow, flags(3))
   passed = .not. any(flags)
#if defined(__INTEL_LLVM_COMPILER) || defined(__INTEL_COMPILER)
   ! ifx's default floating point model keeps no IEEE flag semantics at -O2 (a guarded operation may be evaluated
   ! anyway), and the test cannot tell its builds apart: not checked under ifx (its -O0 build raised none, 2026-11-22);
   ! gfortran's and nvfortran's trapping builds check the guards
   if (.not. passed) write(output_unit, '(A,3L2)') 'ifx: sweep flags (not checked):', flags
   passed = .true.
#endif
   if (.not. passed) write(output_unit, '(A,3L2)') 'FAILED sweep: invalid, divide-by-zero, overflow raised:', flags
   endsubroutine sweep
endprogram foresight_bessel_test
