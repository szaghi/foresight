!< foresight_gammafun test: values and statuses against the installed gnuplot 6.0.0.
program foresight_gammafun_test
!< foresight_gammafun test: values and statuses against the installed gnuplot 6.0.0.
!<
!< Every expected value is gnuplot's own output, `gnuplot -e 'v = f(...); print sprintf("%.17g", real(v))'`; status 1 is
!< gnuplot's "undefined value" (also for igamma's complex results with |imag| > 1e-8, which a plot leaves out). Values
!< are compared within 4 ulps under gfortran (which calls glibc, as gnuplot: they agree to the last bit); nvfortran
!< uses its own exp/log/pow (libpgmath, up to 3 ulps off glibc's) and flushes subnormals to zero, so its tolerance is
!< given per case (32 ulps, more where the algorithm amplifies a 1 ulp log difference: large-a igamma/uigamma), and
!< subnormal expected values are checked absolutely (|r| < tiny). The extreme arguments (up to +-1e300) also check
!< that no IEEE exception is raised (build with -ffpe-trap=invalid,zero,overflow, or -Ktrap=fp).
use, intrinsic :: iso_fortran_env, only : output_unit
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan, ieee_quiet_nan, ieee_value
use foresight_gammafun
use penf, only : I4P, R8P

implicit none
integer(I4P), parameter :: NF = 12_I4P       !< Number of functions (one test_passed entry each).
real(R8P),    parameter :: GNU_ULPS = 4._R8P !< Tolerance in ulps (gfortran, glibc).
logical   :: test_passed(NF) !< Per function: erf erfc gamma lgamma norm invnorm inverf igamma uigamma invigamma
                             !< ibeta invibeta, all its checks passed.
real(R8P) :: qnan            !< Expected NaN (gnuplot prints `NaN`, status 0).

test_passed = .true.
qnan = ieee_value(1._R8P, ieee_quiet_nan)

call check(1_I4P, 'erf', [0._R8P], 0._R8P, 0_I4P, 32._R8P)
call check(1_I4P, 'erf', [0.5_R8P], 0.52049987781304652_R8P, 0_I4P, 32._R8P)
call check(1_I4P, 'erf', [-0.5_R8P], -0.52049987781304652_R8P, 0_I4P, 32._R8P)
call check(1_I4P, 'erf', [0.84375_R8P], 0.76722566123234159_R8P, 0_I4P, 32._R8P)
call check(1_I4P, 'erf', [1._R8P], 0.84270079294971489_R8P, 0_I4P, 32._R8P)
call check(1_I4P, 'erf', [2.5_R8P], 0.99959304798255499_R8P, 0_I4P, 32._R8P)
call check(1_I4P, 'erf', [-3._R8P], -0.99997790950300136_R8P, 0_I4P, 32._R8P)
call check(1_I4P, 'erf', [6._R8P], 1._R8P, 0_I4P, 32._R8P)
call check(1_I4P, 'erf', [1e-300_R8P], 1.1283791670955126e-300_R8P, 0_I4P, 32._R8P)
call check(1_I4P, 'erf', [1e300_R8P], 1._R8P, 0_I4P, 32._R8P)
call check(1_I4P, 'erf', [-1e300_R8P], -1._R8P, 0_I4P, 32._R8P)
call check(2_I4P, 'erfc', [0.5_R8P], 0.47950012218695348_R8P, 0_I4P, 32._R8P)
call check(2_I4P, 'erfc', [-1._R8P], 1.842700792949715_R8P, 0_I4P, 32._R8P)
call check(2_I4P, 'erfc', [3._R8P], 2.2090496998585438e-05_R8P, 0_I4P, 32._R8P)
call check(2_I4P, 'erfc', [10._R8P], 2.0884875837625449e-45_R8P, 0_I4P, 32._R8P)
call check(2_I4P, 'erfc', [26.5_R8P], 2.2109076642637343e-307_R8P, 0_I4P, 32._R8P)
! subnormal result (absolute check)
call check(2_I4P, 'erfc', [27.2_R8P], 9.8813129168249309e-324_R8P, 0_I4P, 32._R8P)
call check(2_I4P, 'erfc', [27.3_R8P], 0._R8P, 1_I4P, 32._R8P) ! glibc erfc underflows to 0 and sets ERANGE
call check(2_I4P, 'erfc', [30._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(2_I4P, 'erfc', [-30._R8P], 2._R8P, 0_I4P, 32._R8P)
call check(2_I4P, 'erfc', [1e300_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(2_I4P, 'erfc', [-1e300_R8P], 2._R8P, 0_I4P, 32._R8P)
call check(3_I4P, 'gamma', [0.5_R8P], 1.7724538509055161_R8P, 0_I4P, 32._R8P)
call check(3_I4P, 'gamma', [5._R8P], 24._R8P, 0_I4P, 32._R8P)
call check(3_I4P, 'gamma', [-0.5_R8P], -3.5449077018110318_R8P, 0_I4P, 32._R8P)
call check(3_I4P, 'gamma', [-2.5_R8P], -0.9453087204829419_R8P, 0_I4P, 32._R8P)
call check(3_I4P, 'gamma', [10.1_R8P], 454760.75144158542_R8P, 0_I4P, 32._R8P)
call check(3_I4P, 'gamma', [1e-300_R8P], 9.999999999999999e+299_R8P, 0_I4P, 32._R8P)
call check(3_I4P, 'gamma', [170.5_R8P], 5.5620924145600007e+305_R8P, 0_I4P, 32._R8P)
! just below the overflow at 171.62437695630271
call check(3_I4P, 'gamma', [171.6_R8P], 1.5858969096672563e+308_R8P, 0_I4P, 32._R8P)
call check(3_I4P, 'gamma', [-170.5_R8P], -3.3127395215386069e-308_R8P, 0_I4P, 32._R8P) ! tiny but normal
call check(3_I4P, 'gamma', [0._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(3_I4P, 'gamma', [-1._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(3_I4P, 'gamma', [-100._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(3_I4P, 'gamma', [172._R8P], 0._R8P, 1_I4P, 32._R8P) ! overflow: ERANGE
call check(3_I4P, 'gamma', [-180.5_R8P], 0._R8P, 1_I4P, 32._R8P) ! underflow to 0: ERANGE
call check(3_I4P, 'gamma', [1e-310_R8P], 0._R8P, 1_I4P, 32._R8P) ! 1/x overflows: ERANGE
call check(3_I4P, 'gamma', [1e300_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(3_I4P, 'gamma', [-1e300_R8P], 0._R8P, 1_I4P, 32._R8P) ! a negative integer: EDOM
call check(4_I4P, 'lgamma', [0.5_R8P], 0.57236494292470008_R8P, 0_I4P, 32._R8P)
call check(4_I4P, 'lgamma', [-0.5_R8P], 1.2655121234846454_R8P, 0_I4P, 32._R8P) ! ln|Gamma|: no sign
call check(4_I4P, 'lgamma', [-2.5_R8P], -0.056243716497674068_R8P, 0_I4P, 32._R8P)
call check(4_I4P, 'lgamma', [1._R8P], 0._R8P, 0_I4P, 32._R8P)
call check(4_I4P, 'lgamma', [2._R8P], 0._R8P, 0_I4P, 32._R8P)
call check(4_I4P, 'lgamma', [3.5_R8P], 1.2009736023470743_R8P, 0_I4P, 32._R8P)
call check(4_I4P, 'lgamma', [100._R8P], 359.13420536957545_R8P, 0_I4P, 32._R8P)
call check(4_I4P, 'lgamma', [1e-300_R8P], 690.77552789821368_R8P, 0_I4P, 32._R8P)
call check(4_I4P, 'lgamma', [1e300_R8P], 6.8977552789821374e+302_R8P, 0_I4P, 32._R8P)
call check(4_I4P, 'lgamma', [-1e10_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(4_I4P, 'lgamma', [-4503599627370495.5_R8P], -1.5782258434492883e+17_R8P, 0_I4P, 32._R8P)
call check(4_I4P, 'lgamma', [0._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(4_I4P, 'lgamma', [-3._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(4_I4P, 'lgamma', [2.6e305_R8P], 0._R8P, 1_I4P, 32._R8P) ! overflow: ERANGE
call check(4_I4P, 'lgamma', [-1e300_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(5_I4P, 'norm', [0._R8P], 0.5_R8P, 0_I4P, 32._R8P)
call check(5_I4P, 'norm', [1._R8P], 0.84134474606854304_R8P, 0_I4P, 32._R8P)
call check(5_I4P, 'norm', [-1._R8P], 0.15865525393145702_R8P, 0_I4P, 32._R8P)
call check(5_I4P, 'norm', [-5._R8P], 2.8665157187919365e-07_R8P, 0_I4P, 32._R8P)
call check(5_I4P, 'norm', [8._R8P], 0.99999999999999933_R8P, 0_I4P, 32._R8P)
call check(5_I4P, 'norm', [-20._R8P], 2.7536241186061926e-89_R8P, 0_I4P, 32._R8P)
call check(5_I4P, 'norm', [-37.5_R8P], 4.6053530095817151e-308_R8P, 0_I4P, 32._R8P)
! subnormal result (absolute check)
call check(5_I4P, 'norm', [-37.99_R8P], 4.2202155165885577e-316_R8P, 0_I4P, 32._R8P)
call check(5_I4P, 'norm', [-38._R8P], 0._R8P, 0_I4P, 32._R8P) ! gnuplot returns 0 below -38
call check(5_I4P, 'norm', [1e300_R8P], 1._R8P, 0_I4P, 32._R8P)
call check(5_I4P, 'norm', [-1e300_R8P], 0._R8P, 0_I4P, 32._R8P)
call check(6_I4P, 'invnorm', [0.5_R8P], 0._R8P, 0_I4P, 32._R8P)
call check(6_I4P, 'invnorm', [0.3_R8P], -0.52440051270804089_R8P, 0_I4P, 32._R8P)
call check(6_I4P, 'invnorm', [0.8_R8P], 0.8416212335729143_R8P, 0_I4P, 32._R8P)
call check(6_I4P, 'invnorm', [0.05_R8P], -1.6448536269514729_R8P, 0_I4P, 32._R8P)
call check(6_I4P, 'invnorm', [0.99_R8P], 2.3263478740408408_R8P, 0_I4P, 32._R8P)
call check(6_I4P, 'invnorm', [1e-10_R8P], -6.3613409024040557_R8P, 0_I4P, 32._R8P)
call check(6_I4P, 'invnorm', [1e-20_R8P], -9.2623400897984087_R8P, 0_I4P, 32._R8P) ! tail z > 8 (P2/Q2)
call check(6_I4P, 'invnorm', [1e-300_R8P], -37.047096299361201_R8P, 0_I4P, 32._R8P)
call check(6_I4P, 'invnorm', [0.9999999999999999_R8P], 8.2095361516013874_R8P, 0_I4P, 32._R8P)
call check(6_I4P, 'invnorm', [0._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(6_I4P, 'invnorm', [1._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(6_I4P, 'invnorm', [-1._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(6_I4P, 'invnorm', [1e300_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(7_I4P, 'inverf', [0._R8P], 0._R8P, 0_I4P, 32._R8P)
call check(7_I4P, 'inverf', [0.5_R8P], 0.47693627620446988_R8P, 0_I4P, 32._R8P)
call check(7_I4P, 'inverf', [-0.5_R8P], -0.47693627620446988_R8P, 0_I4P, 32._R8P)
call check(7_I4P, 'inverf', [0.7_R8P], 0.73286907795921685_R8P, 0_I4P, 32._R8P)
call check(7_I4P, 'inverf', [0.71_R8P], 0.74820497118498519_R8P, 0_I4P, 32._R8P) ! tail branch
call check(7_I4P, 'inverf', [-0.9_R8P], -1.1630871536766743_R8P, 0_I4P, 32._R8P)
call check(7_I4P, 'inverf', [0.999999_R8P], 3.4589107372831753_R8P, 0_I4P, 32._R8P)
call check(7_I4P, 'inverf', [-0.9999999999999999_R8P], -5.8639485322471199_R8P, 0_I4P, 32._R8P)
call check(7_I4P, 'inverf', [1e-300_R8P], 8.8622692545275799e-301_R8P, 0_I4P, 32._R8P)
call check(7_I4P, 'inverf', [1._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(7_I4P, 'inverf', [-1._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(7_I4P, 'inverf', [1.5_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(7_I4P, 'inverf', [1e300_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(8_I4P, 'igamma', [1._R8P, 1._R8P], 0.63212055882855778_R8P, 0_I4P, 32._R8P)
call check(8_I4P, 'igamma', [0.5_R8P, 0.2_R8P], 0.47291074313446146_R8P, 0_I4P, 32._R8P)
call check(8_I4P, 'igamma', [2._R8P, 10._R8P], 0.99950060077261271_R8P, 0_I4P, 32._R8P)
call check(8_I4P, 'igamma', [5._R8P, 3._R8P], 0.18473675547622836_R8P, 0_I4P, 32._R8P)
call check(8_I4P, 'igamma', [10._R8P, 30._R8P], 0.99999287824913718_R8P, 0_I4P, 32._R8P)
call check(8_I4P, 'igamma', [0.1_R8P, 50._R8P], 1._R8P, 0_I4P, 32._R8P)
call check(8_I4P, 'igamma', [150._R8P, 140._R8P], 0.2095436239185855_R8P, 0_I4P, 2048._R8P) ! Gauss-Legendre, a > 100
call check(8_I4P, 'igamma', [1000._R8P, 1100._R8P], 0.99894067674607001_R8P, 0_I4P, 32._R8P)
! Gauss-Legendre; ill-conditioned exponent
call check(8_I4P, 'igamma', [1e5_R8P, 99000._R8P], 0.00075741992118773368_R8P, 0_I4P, 1000000._R8P)
call check(8_I4P, 'igamma', [500._R8P, 1._R8P], 0._R8P, 0_I4P, 32._R8P) ! cexp underflow in the series: cleared, 0
! subnormal result (absolute check)
call check(8_I4P, 'igamma', [10._R8P, 1e-31_R8P], 2.7557321664454706e-317_R8P, 0_I4P, 32._R8P)
call check(8_I4P, 'igamma', [3._R8P, 1e300_R8P], 0._R8P, 1_I4P, 32._R8P) ! "Igamma: overflow", errno from cexp
! x < 0: complex, |imag| = 2.1e-16 <= 1e-8
call check(8_I4P, 'igamma', [1._R8P, -1._R8P], -1.7182818284590453_R8P, 0_I4P, 32._R8P)
call check_imag([1._R8P, -1._R8P], 2.1042883412554314e-16_R8P)
call check(8_I4P, 'igamma', [2._R8P, -0.5_R8P], 0.1756393646499359_R8P, 0_I4P, 32._R8P)
call check_imag([2._R8P, -0.5_R8P], 4.3019237144563758e-17_R8P)
! x < 0, a >= 75: series in complex arithmetic
call check(8_I4P, 'igamma', [80._R8P, -10._R8P], 2.7390278495815697e-35_R8P, 0_I4P, 32._R8P)
call check_imag([80._R8P, -10._R8P], 2.683473351012422e-49_R8P)
call check(8_I4P, 'igamma', [74.5_R8P, -3._R8P], 1.7428264890260198e-86_R8P, 0_I4P, 32._R8P)
call check_imag([74.5_R8P, -3._R8P], 2.3720762007505936e-72_R8P)
! complex, |imag| = 1.65 > 1e-8: undefined in a plot
call check(8_I4P, 'igamma', [0.5_R8P, -1._R8P], 0._R8P, 1_I4P, 32._R8P)
! cexp underflow in the continued fraction: ERANGE
call check(8_I4P, 'igamma', [1._R8P, 800._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(8_I4P, 'igamma', [1e6_R8P, 1.1e6_R8P], 0._R8P, 1_I4P, 32._R8P) ! cexp underflow in Gauss-Legendre: ERANGE
call check(8_I4P, 'igamma', [0._R8P, 1._R8P], qnan, 0_I4P, 32._R8P) ! a <= 0: NaN
call check(8_I4P, 'igamma', [-1._R8P, 1._R8P], qnan, 0_I4P, 32._R8P)
call check(8_I4P, 'igamma', [1._R8P, 0._R8P], 0._R8P, 0_I4P, 32._R8P)
call check(8_I4P, 'igamma', [1e300_R8P, 1e300_R8P], -0._R8P, 0_I4P, 32._R8P)
call check(9_I4P, 'uigamma', [1._R8P, 1._R8P], 0.36787944117144233_R8P, 0_I4P, 32._R8P)
call check(9_I4P, 'uigamma', [0.5_R8P, 0.2_R8P], 0.52708925686553854_R8P, 0_I4P, 32._R8P)
call check(9_I4P, 'uigamma', [2._R8P, 10._R8P], 0.00049939922738733355_R8P, 0_I4P, 32._R8P)
call check(9_I4P, 'uigamma', [5._R8P, 3._R8P], 0.81526324452377164_R8P, 0_I4P, 32._R8P)
call check(9_I4P, 'uigamma', [10._R8P, 30._R8P], 7.1217508628155801e-06_R8P, 0_I4P, 256._R8P)
call check(9_I4P, 'uigamma', [150._R8P, 140._R8P], 0.7904563760814145_R8P, 0_I4P, 512._R8P)
call check(9_I4P, 'uigamma', [1._R8P, 800._R8P], 0._R8P, 0_I4P, 32._R8P) ! ax < -MAXLOG: 0, defined
call check(9_I4P, 'uigamma', [500._R8P, 1._R8P], 1._R8P, 0_I4P, 32._R8P)
call check(9_I4P, 'uigamma', [1e5_R8P, 1.1e5_R8P], 2.6554004794545997e-206_R8P, 0_I4P, 32._R8P)
call check(9_I4P, 'uigamma', [1._R8P, 0._R8P], 1._R8P, 0_I4P, 32._R8P)
call check(9_I4P, 'uigamma', [-1._R8P, 1._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(9_I4P, 'uigamma', [1._R8P, -1._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(9_I4P, 'uigamma', [1e6_R8P, 1.1e6_R8P], 0._R8P, 0_I4P, 32._R8P)
call check(9_I4P, 'uigamma', [1e300_R8P, 1e300_R8P], qnan, 0_I4P, 32._R8P) ! NaN
call check(10_I4P, 'invigamma', [2._R8P, 0.5_R8P], 1.6783469900166623_R8P, 0_I4P, 32._R8P)
call check(10_I4P, 'invigamma', [0.5_R8P, 0.5_R8P], 0.22746821155978675_R8P, 0_I4P, 64._R8P)
call check(10_I4P, 'invigamma', [1._R8P, 0.5_R8P], 0.6931471805599454_R8P, 0_I4P, 32._R8P)
call check(10_I4P, 'invigamma', [10._R8P, 0.01_R8P], 4.1301991662732016_R8P, 0_I4P, 32._R8P)
call check(10_I4P, 'invigamma', [100._R8P, 0.99_R8P], 124.72256149072093_R8P, 0_I4P, 128._R8P)
call check(10_I4P, 'invigamma', [0.1_R8P, 0.9_R8P], 0.26615455373883828_R8P, 0_I4P, 32._R8P)
call check(10_I4P, 'invigamma', [3._R8P, 1e-10_R8P], 0._R8P, 0_I4P, 32._R8P) ! negative initial guess: 0
call check(10_I4P, 'invigamma', [5._R8P, 1._R8P], 228.60679774997897_R8P, 0_I4P, 32._R8P) ! max(100, a + 100 sqrt(a))
call check(10_I4P, 'invigamma', [0.25_R8P, 1._R8P], 100._R8P, 0_I4P, 32._R8P)
call check(10_I4P, 'invigamma', [5._R8P, 0._R8P], 0._R8P, 0_I4P, 32._R8P)
call check(10_I4P, 'invigamma', [5._R8P, 1e-300_R8P], 0._R8P, 0_I4P, 32._R8P)
call check(10_I4P, 'invigamma', [0._R8P, 0.5_R8P], 0._R8P, 1_I4P, 32._R8P) ! "invigamma: a<=0 invalid"
call check(10_I4P, 'invigamma', [2._R8P, 1.5_R8P], 0._R8P, 1_I4P, 32._R8P) ! "invigamma: p invalid"
call check(10_I4P, 'invigamma', [2._R8P, -0.1_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(10_I4P, 'invigamma', [1e300_R8P, 0.5_R8P], 1.0000000000000001e+300_R8P, 0_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [1._R8P, 1._R8P, 0.5_R8P], 0.5_R8P, 0_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [2._R8P, 3._R8P, 0.4_R8P], 0.52479999999999993_R8P, 0_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [0.5_R8P, 0.5_R8P, 0.3_R8P], 0.3690101195655453_R8P, 0_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [10._R8P, 2._R8P, 0.95_R8P], 0.89810540885756818_R8P, 0_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [5._R8P, 0.5_R8P, 0.99_R8P], 0.75715810910156234_R8P, 0_I4P, 32._R8P) ! reflection
call check(11_I4P, 'ibeta', [100._R8P, 200._R8P, 0.33_R8P], 0.45661816333400668_R8P, 0_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [1000._R8P, 1000._R8P, 0.5_R8P], 0.50000000000012834_R8P, 0_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [0.1_R8P, 10._R8P, 1e-5_R8P], 0.41655822619209371_R8P, 0_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [2._R8P, 2._R8P, 0._R8P], 0._R8P, 0_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [2._R8P, 2._R8P, 1._R8P], 1._R8P, 0_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [0._R8P, 1._R8P, 0.5_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [1._R8P, 1._R8P, 2._R8P], 0._R8P, 1_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [1._R8P, 1._R8P, -1e300_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [1e-310_R8P, 1._R8P, 0.5_R8P], 0._R8P, 1_I4P, 32._R8P) ! tgamma(a) overflows: ERANGE
! continued fraction overflows: NaN
call check(11_I4P, 'ibeta', [1e300_R8P, 1e300_R8P, 0.5_R8P], qnan, 0_I4P, 32._R8P)
call check(12_I4P, 'invibeta', [2._R8P, 2._R8P, 0.5_R8P], 0.5_R8P, 0_I4P, 32._R8P)
call check(12_I4P, 'invibeta', [2._R8P, 2._R8P, 0.9_R8P], 0.80419989434090833_R8P, 0_I4P, 32._R8P)
call check(12_I4P, 'invibeta', [2._R8P, 5._R8P, 0.75_R8P], 0.38947948520072434_R8P, 0_I4P, 32._R8P)
call check(12_I4P, 'invibeta', [0.5_R8P, 0.5_R8P, 0.1_R8P], 0.024471741852423221_R8P, 0_I4P, 32._R8P)
call check(12_I4P, 'invibeta', [5._R8P, 0.5_R8P, 0.5_R8P], 0.95331275466303356_R8P, 0_I4P, 32._R8P)
call check(12_I4P, 'invibeta', [0.5_R8P, 3._R8P, 0.2_R8P], 0.011554488147974145_R8P, 0_I4P, 32._R8P)
! p > 1 is only warned
call check(12_I4P, 'invibeta', [0.5_R8P, 0.5_R8P, 1.1_R8P], 0.99999511718749989_R8P, 0_I4P, 32._R8P)
! gnuplot takes sqrt of a negative deviate: EDOM
call check(12_I4P, 'invibeta', [2._R8P, 2._R8P, 0.1_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(12_I4P, 'invibeta', [2._R8P, 2._R8P, 1.1_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(12_I4P, 'invibeta', [0._R8P, 1._R8P, 0.5_R8P], qnan, 0_I4P, 32._R8P) ! a <= 0: NaN, defined
call check(12_I4P, 'invibeta', [2._R8P, 3._R8P, 0._R8P], 0._R8P, 0_I4P, 32._R8P)
call check(12_I4P, 'invibeta', [2._R8P, 3._R8P, 1._R8P], 1._R8P, 0_I4P, 32._R8P)
call check(12_I4P, 'invibeta', [1e300_R8P, 1e300_R8P, 0.5_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(8_I4P, 'igamma', [1e300_R8P, -1e300_R8P], qnan, 0_I4P, 32._R8P)
call check(8_I4P, 'igamma', [1e-300_R8P, -1e300_R8P], qnan, 0_I4P, 32._R8P)
call check(8_I4P, 'igamma', [1e-300_R8P, 1e300_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(8_I4P, 'igamma', [1e300_R8P, 1e-300_R8P], 0._R8P, 0_I4P, 32._R8P)
call check(8_I4P, 'igamma', [50._R8P, -1e300_R8P], qnan, 0_I4P, 32._R8P)
call check(8_I4P, 'igamma', [1e300_R8P, -1._R8P], 0._R8P, 0_I4P, 32._R8P)
call check(9_I4P, 'uigamma', [1e-300_R8P, 1e300_R8P], 0._R8P, 0_I4P, 32._R8P)
call check(9_I4P, 'uigamma', [1e300_R8P, 1e-300_R8P], 1._R8P, 0_I4P, 32._R8P)
call check(9_I4P, 'uigamma', [1e300_R8P, 1._R8P], 1._R8P, 0_I4P, 32._R8P)
call check(10_I4P, 'invigamma', [1e-300_R8P, 1e-300_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(10_I4P, 'invigamma', [1e300_R8P, 1e-300_R8P], 1.0000000000000001e+300_R8P, 0_I4P, 32._R8P)
call check(10_I4P, 'invigamma', [1e-300_R8P, 0.999_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [1e300_R8P, 1e-300_R8P, 0.5_R8P], 0._R8P, 0_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [1e-300_R8P, 1e300_R8P, 0.5_R8P], 0.99999999999999978_R8P, 0_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [1e-300_R8P, 1e-300_R8P, 1e-300_R8P], 0._R8P, 0_I4P, 32._R8P)
call check(11_I4P, 'ibeta', [1e300_R8P, 1._R8P, 1e-300_R8P], 0._R8P, 0_I4P, 32._R8P)
call check(12_I4P, 'invibeta', [1e-300_R8P, 1e300_R8P, 0.5_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(12_I4P, 'invibeta', [1e300_R8P, 1e-300_R8P, 0.5_R8P], 1._R8P, 0_I4P, 32._R8P)
call check(12_I4P, 'invibeta', [1e-300_R8P, 1e-300_R8P, 1e-300_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(12_I4P, 'invibeta', [1e300_R8P, 1e300_R8P, 1e300_R8P], 0._R8P, 1_I4P, 32._R8P)
call check(5_I4P, 'norm', [-1e-300_R8P], 0.5_R8P, 0_I4P, 32._R8P)
call check(3_I4P, 'gamma', [-1e-300_R8P], -9.999999999999999e+299_R8P, 0_I4P, 32._R8P)
call check(4_I4P, 'lgamma', [-1e-300_R8P], 690.77552789821368_R8P, 0_I4P, 32._R8P)

! branch-sensitive cases: each one changes if the named detail is ported differently
! series/continued fraction switch at x = a + 2
call check(10_I4P, 'invigamma', [0.0011137273741454188_R8P, 0.99998045205351072_R8P], &
           2.7701845836522558_R8P, 0_I4P, 32._R8P)
! series/continued fraction switch at x = a + 2
call check(8_I4P, 'igamma', [93.159594104129269_R8P, 95.523524471951518_R8P], &
           0.60924376762295029_R8P, 0_I4P, 2048._R8P)
! glibc clog: log1p for |x| in [0.5, 2)
call check(8_I4P, 'igamma', [153.0292089333775_R8P, -1.6010193180812191_R8P], &
           -3.9937135271219809e-238_R8P, 0_I4P, 32._R8P)
call check_imag([153.0292089333775_R8P, -1.6010193180812191_R8P], 3.6750550938118443e-239_R8P)
! glibc clog: log1p for |x| in [0.5, 2)
call check(8_I4P, 'igamma', [141.95412792048305_R8P, 0.5033720945820862_R8P], &
           1.3584129152793763e-288_R8P, 0_I4P, 32._R8P)
! glibc clog: log1p for |x| in [0.5, 2)
call check(9_I4P, 'uigamma', [8.5376128127195727_R8P, 8.2678440030620841_R8P], &
           0.49147673865649188_R8P, 0_I4P, 32._R8P)
! glibc clog: log1p for |x| in [0.5, 2)
call check(10_I4P, 'invigamma', [4.1900882591763864_R8P, 0.84250258518095422_R8P], &
           6.1698186422585746_R8P, 0_I4P, 128._R8P)
! Gauss-Legendre from a > 100
call check(8_I4P, 'igamma', [100.48281967796029_R8P, 108.52437462171791_R8P], &
           0.79241013065741528_R8P, 0_I4P, 512._R8P)
! Gauss-Legendre from a > 100
call check(10_I4P, 'invigamma', [100.3493366876022_R8P, 0.54692730959299674_R8P], &
           101.19962469753742_R8P, 0_I4P, 512._R8P)
! Gauss-Legendre from a > 100
call check(9_I4P, 'uigamma', [100.02257127829839_R8P, 86.033952858204827_R8P], &
           0.92450796477017028_R8P, 0_I4P, 32._R8P)
! incbet power series for x <= 0.95
call check(11_I4P, 'ibeta', [4631.973723976922_R8P, 0.15217694239313234_R8P, 0.91097712077159032_R8P], &
           2.7185964267609254e-191_R8P, 0_I4P, 32._R8P)
! incbet power series for x <= 0.95
call check(12_I4P, 'invibeta', [0.0014095625990583299_R8P, 0.12673649983419902_R8P, 0.99239053435991909_R8P], &
           0.94801243584216344_R8P, 0_I4P, 32._R8P)
! glibc log1p FMA contraction (2 ulps)
call check(10_I4P, 'invigamma', [1.8692687437810087_R8P, 0.23677874457068104_R8P], &
           0.83211516026799481_R8P, 0_I4P, 32._R8P)

write(output_unit, '(A,12L2)') 'foresight_gammafun checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1

contains
   subroutine check(k, fname, args, expected, expected_status, nvf_ulps)
   !< Evaluate `fname(args)` and compare it with gnuplot's value and status; record the outcome in test_passed(k).
   integer(I4P), intent(in) :: k               !< Function index.
   character(*), intent(in) :: fname           !< Function name.
   real(R8P),    intent(in) :: args(:)         !< Arguments, gnuplot's order.
   real(R8P),    intent(in) :: expected        !< gnuplot's value (NaN for gnuplot's printed NaN).
   integer(I4P), intent(in) :: expected_status !< gnuplot's status: 0 value, 1 undefined.
   real(R8P),    intent(in) :: nvf_ulps        !< Tolerance in ulps under nvfortran.

   real(R8P)    :: r, tol !< Result, tolerance in ulps.
   integer(I4P) :: status !< Status.
   logical      :: ok     !< Check outcome.

   select case (fname)
   case ('erf')
      call gp_erf(args(1), r, status)
   case ('erfc')
      call gp_erfc(args(1), r, status)
   case ('gamma')
      call gp_gamma(args(1), r, status)
   case ('lgamma')
      call gp_lgamma(args(1), r, status)
   case ('norm')
      call gp_norm(args(1), r, status)
   case ('invnorm')
      call gp_invnorm(args(1), r, status)
   case ('inverf')
      call gp_inverf(args(1), r, status)
   case ('igamma')
      call gp_igamma(args(1), args(2), r, status)
   case ('uigamma')
      call gp_uigamma(args(1), args(2), r, status)
   case ('invigamma')
      call gp_invigamma(args(1), args(2), r, status)
   case ('ibeta')
      call gp_ibeta(args(1), args(2), args(3), r, status)
   case ('invibeta')
      call gp_invibeta(args(1), args(2), args(3), r, status)
   case default
      error stop 'unknown function'
   endselect
#if defined(__NVCOMPILER)
   tol = nvf_ulps
#else
   tol = max(GNU_ULPS, 0._R8P * nvf_ulps) ! nvf_ulps only matters under nvfortran
#endif
   ok = status == expected_status
   if (ok .and. status == 0_I4P) then
      if (ieee_is_nan(expected)) then
         ok = ieee_is_nan(r)
      elseif (ieee_is_nan(r)) then
         ok = .false.
      elseif (abs(expected) < tiny(1._R8P)) then
         ok = abs(r) < tiny(1._R8P) ! zero or subnormal: absolute check (nvfortran flushes subnormals to zero)
      else
         ok = abs(r - expected) <= tol * spacing(abs(expected))
#if defined(__INTEL_LLVM_COMPILER) || defined(__INTEL_COMPILER)
         ! Intel's libm is not glibc: a relative 1e-10 (absolutely 1e-16 near a zero of the function)
         ok = ok .or. abs(r - expected) <= 1.0e-10_R8P * abs(expected) + 1.0e-16_R8P
#endif
      endif
   endif
   if (.not. ok) write(output_unit, '(A,I2,A,I2)') 'FAILED '//fname//'('//numbers(args)//'): got '//numbers([r])// &
                                                 ' status', status, ', gnuplot '//numbers([expected])//' status', &
                                                 expected_status
   test_passed(k) = test_passed(k) .and. ok
   endsubroutine check

   subroutine check_imag(args, expected)
   !< Check igamma's imaginary part for x < 0, |imag| against gnuplot's (sign: see gp_igamma).
   real(R8P), intent(in) :: args(2)  !< a, x.
   real(R8P), intent(in) :: expected !< gnuplot's |imag|.

   real(R8P)    :: r, ri, tol !< Real and imaginary parts, tolerance in ulps.
   integer(I4P) :: status     !< Status.
   logical      :: ok         !< Check outcome.

#if defined(__NVCOMPILER)
   tol = 64._R8P
#else
   tol = GNU_ULPS
#endif
   call gp_igamma(args(1), args(2), r, status, ri)
   ok = abs(abs(ri) - expected) <= tol * spacing(expected)
   if (.not. ok) write(output_unit, '(A)') 'FAILED imag igamma('//numbers(args)//'): got '//numbers([ri])// &
                                           ', gnuplot '//numbers([expected])
   test_passed(8) = test_passed(8) .and. ok
   endsubroutine check_imag

   function numbers(v) result(s)
   !< Values as text, NaN written by hand (nvfortran's formatted write of a NaN traps under -Ktrap=fp).
   real(R8P), intent(in) :: v(:) !< Values.
   character(len=26 * size(v))   :: s !< Text.

   integer(I4P) :: i !< Counter.

   s = ''
   do i = 1_I4P, size(v, kind=I4P)
      if (ieee_is_nan(v(i))) then
         s(26 * (i - 1) + 1:) = '                       NaN'
      else
         write(s(26 * (i - 1) + 1:26 * i), '(ES26.17E3)') v(i)
      endif
   enddo
   s = adjustl(s)
   endfunction numbers
endprogram foresight_gammafun_test
