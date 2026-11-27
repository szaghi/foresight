!< foresight_font, gnuplot's font specs ("family:Bold:Italic,size") per text element, and their SVG attributes.
module foresight_font
!< foresight_font, gnuplot's font specs ("family:Bold:Italic,size") per text element, and their SVG attributes.
!<
!< As gnuplot 6.0's svg terminal: the size after the first comma, `:Bold` and `:Italic` (or ` bold`, ` italic`) the
!< weight and the style, the rest the family. A family is written to the SVG as given (the reader's fonts render it);
!< font files (a path, `.ttf`) and gnuplot's `mbfont:` sets are not families an SVG can name: left out, as an empty
!< family is.
!<
!< Widths come from the compiled-in faces (foresight_fontdata): Liberation Sans (Arial's metrics) for the sans families
!< and every family foresight does not have, Latin Modern Roman for the serif ones (`family_face`), each in four faces
!< (regular, bold, italic, bold italic); `text_advance` sums the advance widths of a UTF-8 text and the kerning of its
!< pairs, a character Liberation Sans lacks taken from Latin Modern, one no face has counting 0.556 em.
use foresight_fontdata, only : face_upm, glyph_advance, glyph_index, glyph_kern
use penf, only : I4P, R8P

implicit none
private
public :: font_object
public :: font_of
public :: font_attributes
public :: FAMILY_SANS, FAMILY_SERIF
public :: family_face
public :: face_of
public :: text_advance

integer(I4P), parameter :: FAMILY_SANS  = 1_I4P !< Liberation Sans, faces 1-4.
integer(I4P), parameter :: FAMILY_SERIF = 2_I4P !< Latin Modern Roman, faces 5-8.
real(R8P),    parameter :: MISSING_ADVANCE = 0.556_R8P !< Advance of a character no face has [em].

type :: font_object
   !< A text element's font: a size, a family, the weight and the style; unset parts take the page's.
   real(R8P)         :: size   = 0.0_R8P !< Size [px], 0 the page's.
   character(len=48) :: family = ''      !< CSS family, empty the page's.
   logical           :: bold   = .false. !< Bold.
   logical           :: italic = .false. !< Italic.
   contains
      procedure, pass(self) :: is_set  !< Whether any part is set.
      procedure, pass(self) :: size_px !< The size [px], the page's if unset.
endtype font_object

contains
   elemental function is_set(self) result(yes)
   !< Whether any part of the font is set.
   class(font_object), intent(in) :: self !< Font.
   logical                        :: yes  !< Set.

   yes = self%size > 0.0_R8P .or. len_trim(self%family) > 0 .or. self%bold .or. self%italic
   endfunction is_set

   elemental function size_px(self, page) result(size)
   !< The size [px]: the font's, or `page` if unset.
   class(font_object), intent(in) :: self !< Font.
   real(R8P),          intent(in) :: page !< Page font size [px].
   real(R8P)                      :: size !< Size [px].

   size = page
   if (self%size > 0.0_R8P) size = self%size
   endfunction size_px

   pure function font_of(spec) result(font)
   !< The font of gnuplot's spec `"family:Bold:Italic,size"` (each part optional: `",8"`, `":Bold"`, `"Times,14"`).
   character(len=*), intent(in)  :: spec   !< Font spec.
   type(font_object)             :: font   !< Font.
   character(len=:), allocatable :: name   !< Text before the first comma.
   character(len=:), allocatable :: number !< Text after it.
   integer                       :: comma  !< First comma.
   integer                       :: ios    !< Read status.

   font = font_object()
   comma = index(spec, ',')
   if (comma > 0) then
      name = spec(1:comma - 1)
      number = trim(adjustl(spec(comma + 1:)))
      if (len(number) > 0 .and. verify(number, '0123456789.') == 0) then
         read(number, *, iostat=ios) font%size
         if (ios /= 0 .or. font%size < 0.0_R8P) font%size = 0.0_R8P
      endif
   else
      name = spec
   endif
   call take(name, ':Bold', font%bold)
   call take(name, ':bold', font%bold)
   call take(name, ' bold', font%bold)
   call take(name, ' Bold', font%bold)
   call take(name, ':Italic', font%italic)
   call take(name, ':italic', font%italic)
   call take(name, ' italic', font%italic)
   call take(name, ' Italic', font%italic)
   name = trim(adjustl(name))
   ! a family an SVG can name: letters, digits, blanks, '-', '_' (not a font file, nor gnuplot's mbfont: sets)
   if (len(name) > 0 .and. len(name) <= len(font%family)) then
      if (verify(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 -_') == 0) font%family = name
   endif
   contains
      pure subroutine take(name, word, flag)
      !< Remove every `word` from `name`, setting `flag` if any.
      character(len=:), allocatable, intent(inout) :: name !< Font name.
      character(len=*),              intent(in)    :: word !< Word.
      logical,                       intent(inout) :: flag !< Found.
      integer                                      :: k    !< Position.

      do
         k = index(name, word)
         if (k == 0) exit
         flag = .true.
         name = name(1:k - 1)//name(k + len(word):)
      enddo
      endsubroutine take
   endfunction font_of

   pure function font_attributes(font, size) result(text)
   !< The SVG attributes of `font` (leading blank each), its size `size` [px] if set (0: none): `font-size`,
   !< `font-family` (quoted when it holds a blank), `font-weight`, `font-style`.
   type(font_object), intent(in)  :: font !< Font.
   real(R8P),         intent(in)  :: size !< Size to write [px], 0 for none.
   character(len=:), allocatable  :: text !< Attributes.
   character(len=32)              :: buffer !< Number.

   text = ''
   if (size > 0.0_R8P) then
      write(buffer, '(F0.2)') size
      ! the shortest form, as foresight's other numbers: 8.00 -> 8, 7.50 -> 7.5
      buffer = trim_zeros(buffer)
      text = text//' font-size="'//trim(buffer)//'"'
   endif
   if (len_trim(font%family) > 0) then
      if (index(trim(font%family), ' ') > 0) then
         text = text//' font-family="'''//trim(font%family)//'''"'
      else
         text = text//' font-family="'//trim(font%family)//'"'
      endif
   endif
   if (font%bold) text = text//' font-weight="bold"'
   if (font%italic) text = text//' font-style="italic"'
   contains
      pure function trim_zeros(number) result(short)
      !< `number` without trailing zeros of its fraction nor a trailing point.
      character(len=*), intent(in)  :: number !< Number.
      character(len=:), allocatable :: short  !< Shortened.

      short = trim(adjustl(number))
      if (index(short, '.') == 0) return
      do while (short(len(short):len(short)) == '0')
         short = short(1:len(short) - 1)
      enddo
      if (short(len(short):len(short)) == '.') short = short(1:len(short) - 1)
      if (short(1:1) == '.') short = '0'//short
      endfunction trim_zeros
   endfunction font_attributes

   pure subroutine family_face(family, index, known)
   !< The compiled-in family standing for the CSS `family` (case and blanks ignored): Latin Modern Roman for `serif`,
   !< `Latin Modern Roman`, `LM Roman`, `CMU Serif`, `Computer Modern`; Liberation Sans for every other one, `known`
   !< telling whether the family is one of Liberation Sans' (empty, `sans`, `sans-serif`, `Arial`, `Helvetica`,
   !< `Liberation Sans`, `Arimo`) or a fallback.
   character(len=*), intent(in)  :: family !< CSS family.
   integer(I4P),     intent(out) :: index  !< FAMILY_SANS or FAMILY_SERIF.
   logical,          intent(out) :: known  !< The family is compiled in (not a fallback).
   character(len=:), allocatable :: key    !< Lowercase family without blanks nor quotes.
   integer                       :: k      !< Counter.
   integer                       :: c      !< Character code.

   key = ''
   do k = 1, len_trim(family)
      c = iachar(family(k:k))
      if (c >= iachar('A') .and. c <= iachar('Z')) c = c + 32
      if (c /= iachar(' ') .and. c /= 39 .and. c /= iachar('"')) key = key//achar(c)
   enddo
   index = FAMILY_SANS
   known = .true.
   select case (key)
   case ('serif', 'latinmodernroman', 'latinmodern', 'lmroman', 'lmroman10', 'cmuserif', 'computermodern')
      index = FAMILY_SERIF
   case ('', 'sans', 'sans-serif', 'arial', 'helvetica', 'liberationsans', 'arimo')
   case default
      known = .false.
   endselect
   endsubroutine family_face

   elemental function face_of(font) result(face)
   !< The compiled-in face (foresight_fontdata, 1-8) of `font`: its family (family_face), weight and style.
   type(font_object), intent(in) :: font  !< Font.
   integer(I4P)                  :: face  !< Face.
   integer(I4P)                  :: index !< Family.
   logical                       :: known !< Family compiled in.

   call family_face(font%family, index, known)
   face = 4_I4P * (index - 1_I4P) + 1_I4P
   if (font%bold) face = face + 1_I4P
   if (font%italic) face = face + 2_I4P
   endfunction face_of

   pure function text_advance(text, face, size) result(width)
   !< The width of the UTF-8 `text` set in `face` at `size`, in the unit of `size`: the advance widths of its
   !< characters and the kerning of each pair. A character a sans face lacks is taken from the serif face of the same
   !< style (Latin Modern, whose data holds the math symbols), not kerned; one no face has counts 0.556 em.
   character(len=*), intent(in) :: text  !< UTF-8 text.
   integer(I4P),     intent(in) :: face  !< Face (foresight_fontdata, 1-8).
   real(R8P),        intent(in) :: size  !< Font size (em).
   real(R8P)                    :: width !< Width.
   real(R8P)                    :: em    !< Width in em of the fallback glyphs and missing characters.
   integer(I4P)                 :: units !< Advance in font units of `face`.
   integer(I4P)                 :: k     !< Byte.
   integer(I4P)                 :: n     !< Bytes of a character.
   integer(I4P)                 :: code  !< Code point.
   integer(I4P)                 :: glyph !< Glyph index.
   integer(I4P)                 :: prev  !< Previous glyph index, 0 none.
   integer(I4P)                 :: other !< Fallback face.

   units = 0_I4P
   em = 0.0_R8P
   prev = 0_I4P
   other = face + 4_I4P
   if (face > 4_I4P) other = 0_I4P
   k = 1_I4P
   do while (k <= len(text, kind=I4P))
      call decode(text, k, code, n)
      k = k + n
      glyph = glyph_index(face, code)
      if (glyph == 0_I4P) then
         prev = 0_I4P
         if (other > 0_I4P) glyph = glyph_index(other, code)
         if (glyph > 0_I4P) then
            em = em + real(glyph_advance(other, glyph), R8P) / real(face_upm(other), R8P)
         else
            em = em + MISSING_ADVANCE
         endif
         cycle
      endif
      units = units + glyph_advance(face, glyph)
      if (prev > 0_I4P) units = units + glyph_kern(face, prev, glyph)
      prev = glyph
   enddo
   width = size * (real(units, R8P) / real(max(1_I4P, face_upm(face)), R8P) + em)
   endfunction text_advance

   pure subroutine decode(text, k, code, n)
   !< The code point of the UTF-8 character at byte `k` of `text` and its bytes (a malformed byte: its own code).
   character(len=*), intent(in)  :: text !< UTF-8 text.
   integer(I4P),     intent(in)  :: k    !< First byte.
   integer(I4P),     intent(out) :: code !< Code point.
   integer(I4P),     intent(out) :: n    !< Bytes.
   integer(I4P)                  :: lead !< First byte's value.
   integer(I4P)                  :: j    !< Continuation byte.
   integer(I4P)                  :: b    !< Its value.

   lead = iachar(text(k:k), kind=I4P)
   select case (lead)
   case (240:247)
      n = 4_I4P
      code = iand(lead, 7_I4P)
   case (224:239)
      n = 3_I4P
      code = iand(lead, 15_I4P)
   case (192:223)
      n = 2_I4P
      code = iand(lead, 31_I4P)
   case default
      n = 1_I4P
      code = lead
      return
   endselect
   if (k + n - 1_I4P > len(text, kind=I4P)) then
      n = 1_I4P
      code = lead
      return
   endif
   do j = k + 1_I4P, k + n - 1_I4P
      b = iachar(text(j:j), kind=I4P)
      if (b < 128_I4P .or. b > 191_I4P) then
         n = 1_I4P
         code = lead
         return
      endif
      code = 64_I4P * code + (b - 128_I4P)
   enddo
   endsubroutine decode
endmodule foresight_font
