!< foresight_palette test: palette colors against gnuplot 6.0 (`test palette` tables, its PNG images), palette words;
!< the named palettes against their authors' 8-bit tables.
program foresight_palette_test
!< foresight_palette test: palette colors against gnuplot 6.0 (`test palette` tables, its PNG images), palette words;
!< the named palettes against their authors' 8-bit tables.
use, intrinsic :: iso_fortran_env, only : output_unit
use foresight_palette, only : hex_color, palette_object, palette_words
use penf, only : I4P, R8P

implicit none
type(palette_object)          :: p               !< Palette.
character(len=:), allocatable :: bad             !< Unknown word.
type(palette_object)          :: q               !< Second palette.
logical                       :: test_passed(16) !< Per-check outcome.
integer(I4P)                  :: k               !< Band counter.
integer, parameter            :: BATLOW10(3, 10) = reshape([1, 25, 89, 16, 63, 96, 28, 90, 98, 60, 109, 86, &
                                                            104, 123, 62, 157, 137, 43, 210, 147, 67, 248, 161, 123, &
                                                            253, 183, 188, 250, 204, 250], [3, 10]) !< Crameri's batlow10.

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
! color restores viridis, the last palette set (gnuplot 6.0: `gradient named viridis`, `test palette` at 0: 253,231,37)
call palette_words('color negative', p, bad)
test_passed(5) = same(p%rgb(0.0_R8P), [253, 231, 37]) .and. p%negative
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
call palette_words('functions', p, bad)
test_passed(10) = bad == 'functions'
call palette_words('defined (0 "blue", 1 "nocolor")', p, bad)
test_passed(10) = test_passed(10) .and. index(bad, 'a value and a color') > 0
call palette_words('rgbformulae 40 , 1 , 1', p, bad)
test_passed(10) = test_passed(10) .and. index(bad, '-36 to 36') > 0
! named palettes: table ends and middle (gray 0.5 takes color nint(127.5) = 128), Crameri's .lut values
p = palette_object()
call palette_words('batlow', p, bad)
test_passed(11) = len(bad) == 0 .and. same(p%rgb(0.0_R8P), [1, 25, 89]) .and. same(p%rgb(0.5_R8P), [130, 130, 49]) .and. &
                  same(p%rgb(1.0_R8P), [250, 204, 250])
call palette_words('vik', p, bad)
test_passed(11) = test_passed(11) .and. same(p%rgb(0.0_R8P), [0, 18, 97]) .and. same(p%rgb(1.0_R8P), [89, 0, 8])
call palette_words('bukavu', p, bad)
test_passed(11) = test_passed(11) .and. same(p%rgb(0.5_R8P), [1, 64, 38]) .and. same(p%rgb(1.0_R8P), [237, 237, 252])
call palette_words('romaO', p, bad)
test_passed(11) = test_passed(11) .and. same(p%rgb(0.0_R8P), [115, 57, 87]) .and. same(p%rgb(1.0_R8P), [114, 57, 89])
call palette_words('magma', p, bad)
test_passed(11) = test_passed(11) .and. hex_color(p%rgb(0.0_R8P)) == '#000004' .and. hex_color(p%rgb(1.0_R8P)) == '#fcfdbf'
call palette_words('CIVIDIS', p, bad)
test_passed(11) = test_passed(11) .and. len(bad) == 0 .and. hex_color(p%rgb(0.0_R8P)) == '#00224e' .and. &
                  hex_color(p%rgb(1.0_R8P)) == '#fee838'
! maxcolors 10 gives Crameri's discrete batlow10 (DiscretePalettes/batlow10.txt), band k at gray (k + 0.5) / 10
p = palette_object()
call palette_words('batlow maxcolors 10', p, bad)
test_passed(12) = len(bad) == 0
do k = 0_I4P, 9_I4P
   test_passed(12) = test_passed(12) .and. same(p%rgb((real(k, R8P) + 0.5_R8P) / 10.0_R8P), BATLOW10(:, k + 1_I4P))
enddo
! negative reverses a named palette; the last mode wins
p = palette_object()
call palette_words('vik negative', p, bad)
test_passed(13) = len(bad) == 0 .and. same(p%rgb(0.0_R8P), [89, 0, 8]) .and. same(p%rgb(1.0_R8P), [0, 18, 97])
call palette_words('positive gray', p, bad)
test_passed(13) = test_passed(13) .and. same(p%rgb(0.5_R8P), [161, 161, 161])
! names are case-insensitive (viridis too); gnuplot's own words are not; an unknown name is reported
p = palette_object()
q = palette_object()
call palette_words('BatLow', p, bad)
call palette_words('batlow', q, bad)
test_passed(14) = len(bad) == 0 .and. p%table == q%table .and. same(p%rgb(0.3_R8P), q%rgb(0.3_R8P))
call palette_words('VIRIDIS', p, bad)
test_passed(14) = test_passed(14) .and. len(bad) == 0 .and. hex_color(p%rgb(0.0_R8P)) == '#440154'
call palette_words('grayc', p, bad)
call palette_words('grayC', q, bad)
test_passed(14) = test_passed(14) .and. len(bad) == 0 .and. p%table == q%table .and. p%table > 0_I4P
call palette_words('batlw', p, bad)
test_passed(14) = test_passed(14) .and. bad == 'batlw'
call palette_words('GRAY', p, bad)
test_passed(14) = test_passed(14) .and. bad == 'GRAY'
! color restores the last palette set by rgbformulae, defined or a name (gnuplot 6.0: `show palette` after each)
p = palette_object()
call palette_words('defined (0 "red", 1 "blue")', p, bad)
call palette_words('gray', p, bad)
call palette_words('color', p, bad)
test_passed(15) = same(p%rgb(0.0_R8P), [255, 0, 0]) .and. same(p%rgb(1.0_R8P), [0, 0, 255])
p = palette_object()
call palette_words('viridis', p, bad)
call palette_words('gray', p, bad)
call palette_words('color', p, bad)
test_passed(15) = test_passed(15) .and. hex_color(p%rgb(0.0_R8P)) == '#440154'
q = palette_object()
call palette_words('rgbformulae 3 , 4 , 5', q, bad)
call palette_words('viridis', p, bad)
call palette_words('rgbformulae 3 , 4 , 5', p, bad)
call palette_words('color', p, bad)
test_passed(15) = test_passed(15) .and. same(p%rgb(0.3_R8P), q%rgb(0.3_R8P))
p = palette_object()
call palette_words('gray', p, bad)
call palette_words('color', p, bad)
test_passed(15) = test_passed(15) .and. p%is_default()
call palette_words('batlow gray color', p, bad)
test_passed(15) = test_passed(15) .and. len(bad) == 0 .and. same(p%rgb(0.0_R8P), [1, 25, 89])
! cubehelix against gnuplot 6.0's PNG pixels (ramp 0..255, gray k/255): the defaults, other parameters (clipped
! channels), negative, maxcolors; each `cubehelix` restarts from the defaults; options only right after it
p = palette_object()
call palette_words('cubehelix', p, bad)
test_passed(16) = len(bad) == 0 .and. same(p%rgb(0.0_R8P), [0, 0, 0]) .and. same(p%rgb(64.0_R8P / 255.0_R8P), [48, 126, 117]) &
                  .and. same(p%rgb(128.0_R8P / 255.0_R8P), [192, 155, 111]) .and. &
                  same(p%rgb(200.0_R8P / 255.0_R8P), [213, 213, 249]) .and. same(p%rgb(1.0_R8P), [255, 255, 255])
call palette_words('cubehelix start 0 cycles 1 saturation 2', p, bad)
test_passed(16) = test_passed(16) .and. len(bad) == 0 .and. same(p%rgb(40.0_R8P / 255.0_R8P), [148, 26, 131]) .and. &
                  same(p%rgb(128.0_R8P / 255.0_R8P), [169, 179, 44]) .and. same(p%rgb(230.0_R8P / 255.0_R8P), [220, 243, 255])
call palette_words('cubehelix negative', p, bad)
test_passed(16) = test_passed(16) .and. same(p%rgb(0.0_R8P), [255, 255, 255]) .and. &
                  same(p%rgb(64.0_R8P / 255.0_R8P), [216, 201, 245])
call palette_words('positive maxcolors 4', p, bad)
test_passed(16) = test_passed(16) .and. same(p%rgb(77.0_R8P / 255.0_R8P), [76, 152, 91])
p = palette_object()
call palette_words('cubehelix start 1', p, bad)
call palette_words('cubehelix cycles 2', p, bad)
test_passed(16) = test_passed(16) .and. all(p%cubehelix == [0.5_R8P, 2.0_R8P, 1.0_R8P])
call palette_words('cubehelix start 1 start 2 saturation -1', p, bad)
test_passed(16) = test_passed(16) .and. all(p%cubehelix == [2.0_R8P, -1.5_R8P, -1.0_R8P])
call palette_words('cubehelix color', p, bad)
test_passed(16) = test_passed(16) .and. p%is_default()
call palette_words('cubehelix negative start 1', p, bad)
test_passed(16) = test_passed(16) .and. bad == 'start'
call palette_words('cubehelix start', p, bad)
test_passed(16) = test_passed(16) .and. index(bad, 'a number is expected') > 0
write(output_unit, '(A,16L2)') 'foresight palette checks:', test_passed
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
