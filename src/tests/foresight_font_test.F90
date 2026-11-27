!< foresight_font test: the compiled-in faces' widths and kerning against fontTools' values.
program foresight_font_test
!< foresight_font test: the compiled-in faces' widths and kerning against fontTools' values.
!<
!< `foresight_font_test_data.inc` (written by scripts/gen_fonts.py with the generated faces) holds the widths at 10 pt
!< of a fixed string set (digits, the alphabet, accented and Greek letters, kerned pairs, math symbols) in each face,
!< computed by fontTools' advance widths and a pair-by-pair walk of the GPOS kerning, and the 40 strongest kerned
!< pairs of each face: foresight's `text_advance` and `glyph_kern` must give them to 0.01 pt.
use, intrinsic :: iso_fortran_env, only : output_unit
use foresight_font, only : face_of, family_face, font_object, text_advance, FAMILY_SANS, FAMILY_SERIF
use foresight_fontdata, only : face_upm, glyph_advance, glyph_index, glyph_kern
use penf, only : I4P, R8P

implicit none
include 'foresight_font_test_data.inc'
real(R8P), parameter :: TOLERANCE = 0.01_R8P !< Points.
logical              :: test_passed(6)       !< Per-check outcome.
real(R8P)            :: width                !< A width [pt].
real(R8P)            :: worst                !< Worst difference [pt].
integer(I4P)         :: k                    !< Counter.
integer(I4P)         :: face                 !< Face.
integer(I4P)         :: left                 !< Glyph index.
integer(I4P)         :: right                !< Glyph index.
integer(I4P)         :: family               !< Family.
logical              :: known                !< Family compiled in.
type(font_object)    :: font                 !< Font.

! 1: every string in every face
worst = 0.0_R8P
do k = 1_I4P, int(NREF, I4P)
   face = int(REF_FACE(k), I4P)
   width = text_advance(trim(REF_TEXT(modulo(k - 1_I4P, int(size(REF_TEXT), I4P)) + 1_I4P)), face, 10.0_R8P)
   worst = max(worst, abs(width - REF_WIDTH(k)))
   if (abs(width - REF_WIDTH(k)) > TOLERANCE) write(output_unit, '(A,I0,A,I0,2(A,F10.4))') 'string ', &
      modulo(k - 1_I4P, int(size(REF_TEXT), I4P)) + 1_I4P, ' face ', face, ': ', width, ' expected ', REF_WIDTH(k)
enddo
test_passed(1) = worst <= TOLERANCE
write(output_unit, '(A,I0,A,ES10.3,A)') 'widths: ', NREF, ' strings, worst difference ', worst, ' pt'

! 2: the kerned pairs, alone and inside a text (the text's width less the two advances)
worst = 0.0_R8P
do k = 1_I4P, int(NPAIR, I4P)
   face = int(PAIR_DATA(1, k), I4P)
   left = glyph_index(face, int(PAIR_DATA(2, k), I4P))
   right = glyph_index(face, int(PAIR_DATA(3, k), I4P))
   width = 10.0_R8P * real(glyph_kern(face, left, right), R8P) / real(face_upm(face), R8P)
   worst = max(worst, abs(width - PAIR_KERN(k)))
   width = text_advance(pair_text(int(PAIR_DATA(2, k), I4P), int(PAIR_DATA(3, k), I4P)), face, 10.0_R8P) - &
           10.0_R8P * real(glyph_advance(face, left) + glyph_advance(face, right), R8P) / real(face_upm(face), R8P)
   worst = max(worst, abs(width - PAIR_KERN(k)))
enddo
test_passed(2) = worst <= TOLERANCE .and. NPAIR == 320
write(output_unit, '(A,I0,A,ES10.3,A)') 'kerning: ', NPAIR, ' pairs, worst difference ', worst, ' pt'

! 3: families, weights and styles to faces; unknown families fall back to Liberation Sans
call family_face('Arial', family, known)
test_passed(3) = family == FAMILY_SANS .and. known
call family_face('Latin Modern Roman', family, known)
test_passed(3) = test_passed(3) .and. family == FAMILY_SERIF .and. known
call family_face('Times', family, known)
test_passed(3) = test_passed(3) .and. family == FAMILY_SANS .and. .not. known
font = font_object()
test_passed(4) = face_of(font) == 1_I4P
font%family = 'serif'
font%bold = .true.
font%italic = .true.
test_passed(4) = test_passed(4) .and. face_of(font) == 8_I4P

! 5: a character no face has counts 0.556 em; one Liberation Sans lacks (nabla) is Latin Modern's of the same style
test_passed(5) = abs(text_advance(utf8(int(z'4E2D', I4P)), 1_I4P, 10.0_R8P) - 5.56_R8P) < 1.0e-9_R8P .and. &
                 glyph_index(1_I4P, int(z'2207', I4P)) == 0_I4P .and. glyph_index(5_I4P, int(z'2207', I4P)) > 0_I4P
test_passed(5) = test_passed(5) .and. abs(text_advance(utf8(int(z'2207', I4P)), 3_I4P, 10.0_R8P) - &
                 text_advance(utf8(int(z'2207', I4P)), 7_I4P, 10.0_R8P)) < 1.0e-9_R8P

! 6: malformed UTF-8 (a lone continuation byte, a truncated sequence) is read byte by byte, without a crash
width = text_advance(achar(150)//'A'//achar(226)//achar(130), 1_I4P, 10.0_R8P)
test_passed(6) = width > 0.0_R8P

write(output_unit, '(A,6L2)') 'foresight_font checks:', test_passed
write(output_unit, '(A,L1)') 'Are all tests passed? ', all(test_passed)
if (.not. all(test_passed)) error stop 1
contains
   pure function pair_text(left, right) result(text)
   !< The two code points `left` and `right` in UTF-8 (a buffer, not a concatenation: nvfortran 26.9 bug 25).
   integer(I4P), intent(in)      :: left   !< First code point.
   integer(I4P), intent(in)      :: right  !< Second code point.
   character(len=:), allocatable :: text   !< Bytes.
   character(len=8)              :: buffer !< Bytes.
   character(len=:), allocatable :: a      !< First character.
   character(len=:), allocatable :: b      !< Second character.

   a = utf8(left)
   b = utf8(right)
   buffer(1:len(a)) = a
   buffer(len(a) + 1:len(a) + len(b)) = b
   text = buffer(1:len(a) + len(b))
   endfunction pair_text

   pure function utf8(code) result(text)
   !< The UTF-8 bytes of the code point `code` (written into a buffer: nvfortran 26.9 miscompiles concatenated
   !< `achar(var)`, bug 25).
   integer(I4P), intent(in)      :: code   !< Code point.
   character(len=:), allocatable :: text   !< Bytes.
   character(len=4)              :: buffer !< Bytes.
   integer(I4P)                  :: n      !< Bytes used.

   if (code < 128_I4P) then
      n = 1_I4P
      buffer(1:1) = achar(code)
   elseif (code < 2048_I4P) then
      n = 2_I4P
      buffer(1:1) = achar(192_I4P + code / 64_I4P)
      buffer(2:2) = achar(128_I4P + modulo(code, 64_I4P))
   elseif (code < 65536_I4P) then
      n = 3_I4P
      buffer(1:1) = achar(224_I4P + code / 4096_I4P)
      buffer(2:2) = achar(128_I4P + modulo(code / 64_I4P, 64_I4P))
      buffer(3:3) = achar(128_I4P + modulo(code, 64_I4P))
   else
      n = 4_I4P
      buffer(1:1) = achar(240_I4P + code / 262144_I4P)
      buffer(2:2) = achar(128_I4P + modulo(code / 4096_I4P, 64_I4P))
      buffer(3:3) = achar(128_I4P + modulo(code / 64_I4P, 64_I4P))
      buffer(4:4) = achar(128_I4P + modulo(code, 64_I4P))
   endif
   text = buffer(1:n)
   endfunction utf8
endprogram foresight_font_test
