!< foresight character cell test: each device's cell against gnuplot 6.0's terminal it stands for.
program foresight_cell_test
!< foresight character cell test: each device's cell against gnuplot 6.0's terminal it stands for.
!<
!< `v_char` and `h_char` are gnuplot 6.0's own (`GPVAL_TERM_VCHAR`, `GPVAL_TERM_HCHAR` after a plot, in terminal units:
!< 1/100 px for svg, 1/200 pt for the cairo terminals), recorded with
!<
!<    gnuplot -e "set terminal T font ',S'; set output 'x'; plot x; print GPVAL_TERM_VCHAR, GPVAL_TERM_HCHAR"
!<
!< for svg (size 600,400), pdfcairo and cairolatex (size 5in,3in) at three sizes S, the cairo terminals' "Sans"
!< aliased to Liberation Sans by fontconfig (scripts/fidelity/placement.py's alias), and once for Liberation Serif.
!< gnuplot does not export `v_tic` and `h_tic`: they are its terminals' rules on the recorded `v_char` (svg.trm: half;
!< cairo.trm: over 2.5, truncated). The svg cell must equal gnuplot's; the cairo one within a unit (1/200 pt): pango's
!< rounding of a line height. The drop from a text's centre to its baseline: svg.trm's 0.325 font sizes, and 0.375
!< of the drawn size measured on pdfcairo pages (pdftotext -bbox at 6, 8, 12, 16, 24 pt: 0.3747-0.3751).
use, intrinsic :: iso_fortran_env, only : error_unit, output_unit
use foresight_backend_pdf, only : backend_pdf
use foresight_backend_svg, only : backend_svg
use penf, only : I4P, R8P

implicit none
type(backend_svg)  :: svg              !< svg device.
type(backend_pdf)  :: pdf              !< PDF device (pdfcairo, cairolatex).
logical            :: test_passed(12)  !< Per-check outcome.
real(R8P), parameter :: SCALE = 16.0_R8P / 9.0_R8P !< Nominal pt to px of a cairo terminal font: 4/3 (pango's 96 dpi)
                                                     !< over 0.75 pt to the px.

test_passed = .false.
! svg: font S px, units 1/100 px
test_passed(1) = check('svg 8', svg%char_cell(8.0_R8P), 100.0_R8P, 1200, 560, 600, 0)
test_passed(2) = check('svg 12', svg%char_cell(12.0_R8P), 100.0_R8P, 1800, 839, 900, 0)
test_passed(3) = check('svg 16', svg%char_cell(16.0_R8P), 100.0_R8P, 2400, 1120, 1200, 0)
! pdfcairo: font S pt at fontscale 0.5, units 1/200 pt (150 to the px)
test_passed(4) = check('pdfcairo 8', pdf%char_cell(8.0_R8P * 0.5_R8P * SCALE), 150.0_R8P, 1191, 593, 476, 1)
test_passed(5) = check('pdfcairo 12', pdf%char_cell(12.0_R8P * 0.5_R8P * SCALE), 150.0_R8P, 1787, 890, 714, 1)
test_passed(6) = check('pdfcairo 16', pdf%char_cell(16.0_R8P * 0.5_R8P * SCALE), 150.0_R8P, 2383, 1186, 953, 1)
! cairolatex: font S pt at fontscale 0.6
test_passed(7) = check('cairolatex 8', pdf%char_cell(8.0_R8P * 0.6_R8P * SCALE), 150.0_R8P, 1430, 712, 572, 1)
test_passed(8) = check('cairolatex 11', pdf%char_cell(11.0_R8P * 0.6_R8P * SCALE), 150.0_R8P, 1966, 979, 786, 1)
test_passed(9) = check('cairolatex 14', pdf%char_cell(14.0_R8P * 0.6_R8P * SCALE), 150.0_R8P, 2502, 1246, 1000, 1)
! the serif family: Latin Modern Roman's line, ascender 1127 and descender 290 of 1000 (fontconfig has no Latin Modern
! for gnuplot to measure): ceiling(1.417 * 1600) - 1 units at 12 pt
pdf%page_family = 'serif'
test_passed(10) = check('pdfcairo serif 12', pdf%char_cell(12.0_R8P * 0.5_R8P * SCALE), 150.0_R8P, 2267, 800, 906, 1)
pdf%page_family = ''
! the drop from the centre to the baseline
test_passed(11) = near('svg centre', svg%char_cell(12.0_R8P), 0.325_R8P * 12.0_R8P)
test_passed(12) = near('pdf centre', pdf%char_cell(10.0_R8P), 0.375_R8P * 10.0_R8P)

if (all(test_passed)) then
   write(output_unit, '(A)') 'Are all tests passed? T'
else
   write(error_unit, '(A,12L2)') 'checks: ', test_passed
   write(output_unit, '(A)') 'Are all tests passed? F'
   error stop 1
endif

contains
   function check(name, c, units, v, h, tic, tolerance) result(ok)
   !< Whether the cell `c` [px] is gnuplot's: `v`, `h` and `tic` in `units` to the px, within `tolerance` units.
   character(len=*), intent(in) :: name      !< Case.
   real(R8P),        intent(in) :: c(5)      !< Cell [px].
   real(R8P),        intent(in) :: units     !< Terminal units to the px.
   integer,          intent(in) :: v, h, tic !< gnuplot's v_char, h_char and tick length [units].
   integer,          intent(in) :: tolerance !< Units allowed.
   logical                      :: ok        !< Within.
   integer                      :: got(4)    !< The cell in units.

   got = nint(c(1:4) * units)
   ok = abs(got(1) - v) <= tolerance .and. abs(got(2) - h) <= tolerance .and. abs(got(3) - tic) <= tolerance .and. &
        got(4) == got(3)
   write(output_unit, '(A,4I6,A,3I6,A,L2)') name//': v h vtic htic', got, '  gnuplot', v, h, tic, '  ', ok
   endfunction check

   function near(name, c, drop) result(ok)
   !< Whether the cell's centre to baseline drop is `drop` [px].
   character(len=*), intent(in) :: name !< Case.
   real(R8P),        intent(in) :: c(5) !< Cell [px].
   real(R8P),        intent(in) :: drop !< Expected [px].
   logical                      :: ok   !< Equal.

   ok = abs(c(5) - drop) < 1.0e-9_R8P
   write(output_unit, '(A,2F10.5,L2)') name//': ', c(5), drop, ok
   endfunction near
endprogram foresight_cell_test
