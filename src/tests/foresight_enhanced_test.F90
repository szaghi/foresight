!< foresight_enhanced test: gnuplot 6.0's enhanced text markup as SVG `<tspan>` elements (sizes, baseline steps and
!< step backs as its svg terminal writes them for a 12 px font), as plain text, escaped, and its width estimate.
program foresight_enhanced_test
!< foresight_enhanced test: gnuplot 6.0's enhanced text markup as SVG `<tspan>` elements (sizes, baseline steps and
!< step backs as its svg terminal writes them for a 12 px font), as plain text, escaped, and its width estimate.
use, intrinsic :: iso_fortran_env, only : output_unit
use foresight_enhanced, only : has_markup, markup_literal, markup_plain, markup_svg, markup_width
use penf, only : R8P

implicit none
logical :: test_passed(10) !< Per-check outcome.

! superscript and subscript: 0.8 of the size, up half the current size, down 0.3 of it; nested ones apply again
test_passed(1) = svg_is('x^{a^b}', '<tspan>x</tspan><tspan font-size="9.6" dy="-6">a</tspan>'// &
                        '<tspan font-size="7.68" dy="-4.8">b</tspan>') .and. &
                 svg_is('x_{i_j}', '<tspan>x</tspan><tspan font-size="9.6" dy="3.6">i</tspan>'// &
                        '<tspan font-size="7.68" dy="2.88">j</tspan>') .and. &
                 svg_is('T_{n-1}(x) = x^2', '<tspan>T</tspan><tspan font-size="9.6" dy="3.6">n-1</tspan>'// &
                        '<tspan dy="-3.6">(x) = x</tspan><tspan font-size="9.6" dy="-6">2</tspan>')
! a subscript right after a superscript: from the superscript's baseline, as gnuplot
test_passed(2) = svg_is('x^2_3', '<tspan>x</tspan><tspan font-size="9.6" dy="-6">2</tspan>'// &
                        '<tspan font-size="9.6" dy="9.6">3</tspan>')
! & invisible (room kept), @ phantom (the next element steps back over it: b at 9.6 px, 1139/2048 em of Liberation
! Sans), ~ overprint raised by 0.8 (back over a at 12 px)
test_passed(3) = svg_is('a&{bb}c', '<tspan>a</tspan><tspan fill="none">bb</tspan><tspan>c</tspan>') .and. &
                 svg_is('a@_bc', '<tspan>a</tspan><tspan font-size="9.6" dy="3.6">b</tspan>'// &
                        '<tspan dx="-5.34" dy="-3.6">c</tspan>') .and. &
                 svg_is('~a{.8-}', '<tspan>a</tspan><tspan dx="-6.67" dy="-9.6">-</tspan>')
! font specifications: absolute and relative sizes, bold, italic, a family; Symbol as the Greek letters
test_passed(4) = svg_is('{/=8 s}{/*1.5 L}', '<tspan font-size="8">s</tspan><tspan font-size="18">L</tspan>') .and. &
                 svg_is('{/:Italic i}{/:Bold=16 b}', '<tspan font-style="italic">i</tspan>'// &
                        '<tspan font-size="16" font-weight="bold">b</tspan>') .and. &
                 svg_is('{/Helvetica:Italic h}', '<tspan font-style="italic" font-family="Helvetica">h</tspan>') .and. &
                 svg_is('{/Symbol abg}', char(206)//char(177)//char(206)//char(178)//char(206)//char(179))
! a backslash takes the next character as it is: no element for a text in the base style; XML characters escaped
test_passed(5) = svg_is('x\^2', 'x^2') .and. svg_is('a\_1', 'a_1') .and. svg_is('plain', 'plain') .and. &
                 svg_is('<b>_1', '<tspan>&lt;b&gt;</tspan><tspan font-size="9.6" dy="3.6">1</tspan>')
! the text devices: the visible characters, the invisible ones as blanks, the Symbol font as its Latin letters (as
! gnuplot's dumb terminal)
test_passed(6) = markup_plain('T_{n-1}(x) = x^2') == 'Tn-1(x) = x2' .and. markup_plain('a&{bb}c') == 'a  c' .and. &
                 markup_plain('x\^2') == 'x^2' .and. markup_plain('{/Symbol a}^2') == 'a2'
! escaped, read as it is
test_passed(7) = markup_literal('a_{1}^2') == 'a\_\{1\}\^2' .and. markup_plain(markup_literal('p & q~@\')) == 'p & q~@\'
! the width, Liberation Sans' advances: the smaller sizes narrower (x at 12 px, 2 at 9.6), a phantom taking no room,
! the escapes none (a, _ and 1 at 12 px, 1139/2048 em each)
test_passed(8) = abs(markup_width('x^2', 12.0_R8P) - 11.3390625_R8P) < 1.0e-9_R8P .and. &
                 abs(markup_width('a@_bc', 12.0_R8P) - markup_width('ac', 12.0_R8P)) < 1.0e-9_R8P .and. &
                 abs(markup_width('a\_1', 12.0_R8P) - 20.021484375_R8P) < 1.0e-9_R8P
! the markup characters
test_passed(9) = has_markup('x^2') .and. has_markup('a\b') .and. .not. has_markup('x**2 + 1 (m/s)')
! gnuplot's \U+hhhh (hex digits read greedily) and the Symbol font's upper half (a Latin-1 character in UTF-8): the
! integral (U+222B) and infinity (U+221E) for \362 and \245
test_passed(10) = svg_is('a\U+2192 b', 'a'//char(226)//char(134)//char(146)//' b') .and. &
                  svg_is('{/Symbol '//char(195)//char(178)//char(194)//char(165)//'}', &
                         char(226)//char(136)//char(171)//char(226)//char(136)//char(158))

write(output_unit, '(A,10L2)') 'foresight enhanced checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1
contains
   function svg_is(text, expected) result(same)
   !< Whether the `<tspan>` elements of `text` at 12 px are `expected`.
   character(len=*), intent(in)  :: text     !< Enhanced text.
   character(len=*), intent(in)  :: expected !< Elements.
   logical                       :: same     !< Equal.
   character(len=:), allocatable :: svg      !< Elements made.

   svg = markup_svg(text, 12.0_R8P)
   same = svg == expected
   if (.not. same) write(output_unit, '(A)') '"'//text//'": '//svg//', expected '//expected
   endfunction svg_is
endprogram foresight_enhanced_test
