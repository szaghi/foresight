!< foresight_palette test: palette colors against gnuplot 6.0 (`test palette` tables, its PNG images), palette words.
program foresight_palette_test
!< foresight_palette test: palette colors against gnuplot 6.0 (`test palette` tables, its PNG images), palette words.
use, intrinsic :: iso_fortran_env, only : output_unit
use foresight_palette, only : hex_color, palette_object, palette_words
use penf, only : I4P, R8P

implicit none
type(palette_object)          :: p               !< Palette.
character(len=:), allocatable :: bad             !< Unknown word.
logical                       :: test_passed(10) !< Per-check outcome.

! the default, rgbformulae 7,5,15: gnuplot's pixels at gray 0.125 and 0.5
test_passed(1) = same(p%rgb(0.125_R8P), [90, 0, 180]) .and. same(p%rgb(0.5_R8P), [180, 32, 0]) .and. &
                 same(p%rgb(1.0_R8P), [255, 255, 0])
! maxcolors 4: band k takes the color at k/3 (gnuplot's PNG: gray 0.25 -> (147, 9, 221))
call palette_words('maxcolors 4', p, bad)
test_passed(2) = len(bad) == 0 .and. same(p%rgb(0.25_R8P), [147, 9, 221]) .and. same(p%rgb(0.2_R8P), [0, 0, 0]) .and. &
                 same(p%rgb(0.99_R8P), [255, 255, 0])
! viridis ends, gray (gamma 1.5), negative
p = palette_object()
call palette_words('viridis', p, bad)
test_passed(3) = hex_color(p%rgb(0.0_R8P)) == '#440154' .and. hex_color(p%rgb(1.0_R8P)) == '#fde725'
call palette_words('gray', p, bad)
test_passed(4) = same(p%rgb(0.5_R8P), [161, 161, 161])
call palette_words('color negative', p, bad)
test_passed(5) = same(p%rgb(0.0_R8P), [255, 255, 0]) .and. p%negative
! defined: values mapped to 0..1, colors by name or #rrggbb, linear in RGB
p = palette_object()
call palette_words('defined (0 "blue", 1 "white", 2 "#ff0000")', p, bad)
test_passed(6) = len(bad) == 0 .and. same(p%rgb(0.25_R8P), [128, 128, 255]) .and. same(p%rgb(0.75_R8P), [255, 128, 128])
! rgbformulae with commas, a negative formula (the formula of 1 - gray)
p = palette_object()
call palette_words('rgbformulae 33 , 13 , 10', p, bad)
test_passed(7) = len(bad) == 0 .and. all(p%formulae == [33, 13, 10])
call palette_words('rgbformulae -7 , 0 , 2', p, bad)
test_passed(8) = same(p%rgb(0.0_R8P), [255, 0, 255])
! the empty words restore the default
call palette_words('', p, bad)
test_passed(9) = p%is_default() .and. p%maxcolors == 0_I4P
! errors
call palette_words('cubehelix', p, bad)
test_passed(10) = bad == 'cubehelix'
call palette_words('defined (0 "blue", 1 "nocolor")', p, bad)
test_passed(10) = test_passed(10) .and. index(bad, 'a value and a color') > 0
call palette_words('rgbformulae 40 , 1 , 1', p, bad)
test_passed(10) = test_passed(10) .and. index(bad, '-36 to 36') > 0
write(output_unit, '(A,10L2)') 'foresight palette checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1

contains
   pure function same(c, expected) result(equal)
   !< Whether the channels `c` are `expected`.
   integer(I4P), intent(in) :: c(3)        !< Channels.
   integer,      intent(in) :: expected(3) !< Expected channels.
   logical                  :: equal       !< Equal.

   equal = all(c == expected)
   endfunction same
endprogram foresight_palette_test
