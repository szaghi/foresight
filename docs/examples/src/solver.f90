!run solver solver
!run solver-head head -n 4 run.dat
!run solver-csv head -n 3 run.csv
program solver
!< A pretend flow solver: the logs every chapter of the tutorial reads.
!<
!< run.dat: iteration, three residuals, drag coefficient and its error, whitespace separated, a restart (blank line)
!< at iteration 60; run.csv: the same history as CSV with a header row.
use, intrinsic :: iso_fortran_env, only : real64
implicit none
integer, parameter :: rk = real64
integer            :: dat, csv, it
real(rk)           :: t, rho, mom, energy, cd, dcd

open(newunit=dat, file='run.dat', status='replace', action='write')
open(newunit=csv, file='run.csv', status='replace', action='write')
write(dat, '(A)') '# iteration  continuity  momentum  energy  cd  dcd'
write(csv, '(A)') 'iteration,continuity,momentum,energy,cd,dcd'
do it = 1, 120
   t = real(it, rk)
   rho = 10.0_rk**(-0.045_rk * t) * (1.0_rk + 0.35_rk * sin(t / 3.0_rk))
   mom = 10.0_rk**(-0.040_rk * t - 0.4_rk) * (1.0_rk + 0.25_rk * cos(t / 4.0_rk))
   energy = 10.0_rk**(-0.050_rk * t + 0.3_rk)
   cd = 0.30_rk + 0.25_rk * exp(-t / 25.0_rk) * cos(t / 6.0_rk)
   dcd = 0.04_rk / sqrt(t)
   if (it == 61) write(dat, '(A)') ''
   write(dat, '(I0,5(1X,ES12.5E2))') it, rho, mom, energy, cd, dcd
   write(csv, '(I0,5(",",ES12.5E2))') it, rho, mom, energy, cd, dcd
enddo
close(dat)
close(csv)
endprogram solver
