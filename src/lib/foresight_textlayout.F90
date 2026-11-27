!< foresight_textlayout, a text's glyphs placed along its baseline.
module foresight_textlayout
!< foresight_textlayout, a text's glyphs placed along its baseline.
!<
!< The layout of the devices that draw text from the compiled-in glyphs (the SVG device's `fontglyphs`): gnuplot's
!< enhanced runs (sizes, shifts, step-backs, faces; invisible runs advance without glyphs), each character's glyph in
!< its face or, for one Liberation Sans lacks, Latin Modern's of the same style, kerned with the previous glyph of the
!< same face (the rules of foresight_font `text_advance`, so the layout's widths are the measured ones); a superscript
!< at 0.75 size raised 0.3375 font sizes. With `math`, the `$...$` runs are TeX math (foresight_math): their glyphs (in
!< the math font, MATH_FACE, or the serif text faces) and rules (fraction bars, radical rules: face 0) placed as LaTeX
!< sets them; `\$` is a dollar.
use foresight_enhanced, only : enhanced_run, enhanced_runs, markup_width, run_face, shown
use foresight_font, only : text_advance
use foresight_fontdata, only : face_upm, glyph_advance, glyph_index, glyph_kern
use foresight_math, only : has_math, math_item, math_layout, next_math
use penf, only : I4P, R8P

implicit none
private
public :: placed_glyph
public :: layout_text
public :: math_text_width
public :: has_math

real(R8P), parameter :: MISSING_ADVANCE = 0.556_R8P !< Advance of a character no face has [em].

type :: placed_glyph
   !< A glyph of a text.
   integer(I4P) :: face = 0_I4P    !< Face holding it, 1-8, MATH_FACE (foresight_math); 0 for a rule.
   integer(I4P) :: glyph = 0_I4P   !< Glyph index (0: a character no face has, drawn as nothing).
   integer(I4P) :: unicode = 0_I4P !< Character.
   real(R8P)    :: x = 0.0_R8P     !< Origin along the baseline from the text's start [px].
   real(R8P)    :: y = 0.0_R8P     !< Origin across the baseline [px, downward].
   real(R8P)    :: size = 0.0_R8P  !< Font size [px].
   real(R8P)    :: width = 0.0_R8P  !< A rule's width [px] (its origin its top left).
   real(R8P)    :: height = 0.0_R8P !< A rule's height [px].
endtype placed_glyph

contains
   subroutine layout_text(text, markup, face, base, sup, glyphs, count, width, math)
   !< The glyphs of the UTF-8 `text` (enhanced markup read if `markup`) in `face` at `base` [px], its superscript `sup`
   !< after it: `glyphs(1:count)` from the text's start, and its `width` [px] (as text_advance and markup_width); with
   !< `math`, its `$...$` runs set as TeX math.
   character(len=*),                intent(in)  :: text      !< Text, UTF-8.
   logical,                         intent(in)  :: markup    !< Enhanced markup read.
   integer(I4P),                    intent(in)  :: face      !< Base face, 1-8.
   real(R8P),                       intent(in)  :: base      !< Base font size [px].
   character(len=*),                intent(in)  :: sup       !< Superscript, empty for none.
   type(placed_glyph), allocatable, intent(out) :: glyphs(:) !< Glyphs.
   integer(I4P),                    intent(out) :: count     !< Glyphs placed.
   real(R8P),                       intent(out) :: width     !< Width [px].
   logical,               optional, intent(in)  :: math      !< `$...$` runs are TeX math.
   type(enhanced_run), allocatable              :: runs(:)   !< Runs.
   real(R8P)                                    :: at        !< Pen position [px].
   integer(I4P)                                 :: k         !< Run.

   if (present(math)) then
      if (math .and. has_math(text)) then
         call layout_math
         return
      endif
   endif
   if (markup) then
      call enhanced_runs(text, runs)
   else
      allocate(runs(1))
      runs(1)%text = text
      runs(1)%family = ''
   endif
   allocate(glyphs(len(text) + len(sup)))
   count = 0_I4P
   at = 0.0_R8P
   do k = 1_I4P, size(runs, kind=I4P)
      at = at - runs(k)%back * base
      call place(shown(runs(k)), run_face(runs(k), face), runs(k)%size * base, -runs(k)%shift * base, &
                 .not. runs(k)%hidden)
   enddo
   if (len(sup) > 0) call place(sup, face, 0.75_R8P * base, -0.3375_R8P * base, .true.)
   width = max(0.0_R8P, at)
   if (.not. markup) width = at
   contains
      subroutine layout_math
      !< The text's math runs (next_math) set as TeX math, the text between them enhanced if `markup` (`\$` a dollar).
      type(math_item), allocatable :: items(:) !< A math run's glyphs and rules.
      character(len=:), allocatable :: piece   !< A run.
      real(R8P)                     :: w, h, d !< A math run's box.
      integer(I4P)                  :: start   !< Text left.
      integer(I4P)                  :: open    !< A math run's opening dollar.
      integer(I4P)                  :: close   !< Its closing dollar.
      integer(I4P)                  :: i       !< Item.

      allocate(glyphs(4 * len(text) + len(sup) + 16))
      count = 0_I4P
      at = 0.0_R8P
      start = 1_I4P
      do
         call next_math(text, start, open, close)
         if (open == 0_I4P) then
            piece = text(start:)
         else
            piece = text(start:open - 1_I4P)
         endif
         if (len(piece) > 0) then
            piece = unescape_dollars(piece)
            if (markup) then
               call enhanced_runs(piece, runs)
            else
               if (allocated(runs)) deallocate(runs)
               allocate(runs(1))
               runs(1)%text = piece
               runs(1)%family = ''
            endif
            do k = 1_I4P, size(runs, kind=I4P)
               at = at - runs(k)%back * base
               call place(shown(runs(k)), run_face(runs(k), face), runs(k)%size * base, -runs(k)%shift * base, &
                          .not. runs(k)%hidden)
            enddo
         endif
         if (open == 0_I4P) exit
         call math_layout(text(open + 1_I4P:close - 1_I4P), base, items, w, h, d)
         do i = 1_I4P, size(items, kind=I4P)
            if (count == size(glyphs, kind=I4P)) exit
            count = count + 1_I4P
            if (items(i)%face == 0_I4P) then
               glyphs(count) = placed_glyph(0_I4P, 0_I4P, 0_I4P, at + items(i)%x, -(items(i)%y + items(i)%height), &
                                            0.0_R8P, items(i)%size, items(i)%height)
            else
               glyphs(count) = placed_glyph(items(i)%face, items(i)%glyph, items(i)%unicode, at + items(i)%x, &
                                            -items(i)%y, items(i)%size, 0.0_R8P, 0.0_R8P)
            endif
         enddo
         at = at + w
         start = close + 1_I4P
      enddo
      if (len(sup) > 0) call place(sup, face, 0.75_R8P * base, -0.3375_R8P * base, .true.)
      width = max(0.0_R8P, at)
      endsubroutine layout_math

      subroutine place(piece, piece_face, piece_size, shift, drawn)
      !< Place the characters of `piece` in `piece_face` at `piece_size`, `shift` across the baseline, advancing the pen;
      !< glyphs recorded if `drawn`.
      character(len=*), intent(in) :: piece      !< Text, UTF-8.
      integer(I4P),     intent(in) :: piece_face !< Face.
      real(R8P),        intent(in) :: piece_size !< Size [px].
      real(R8P),        intent(in) :: shift      !< Across the baseline [px, downward].
      logical,          intent(in) :: drawn      !< Glyphs recorded.
      integer(I4P)                 :: j          !< Byte.
      integer(I4P)                 :: n          !< Bytes of a character.
      integer(I4P)                 :: code       !< Code point.
      integer(I4P)                 :: g          !< Glyph index.
      integer(I4P)                 :: owner      !< Face holding the glyph.
      integer(I4P)                 :: previous   !< Previous glyph of the same face, 0 none.

      previous = 0_I4P
      j = 1_I4P
      do while (j <= len(piece, kind=I4P))
         call decode(piece, j, code, n)
         j = j + n
         owner = piece_face
         g = glyph_index(piece_face, code)
         if (g == 0_I4P .and. piece_face <= 4_I4P) then
            g = glyph_index(piece_face + 4_I4P, code)
            if (g > 0_I4P) owner = piece_face + 4_I4P
         endif
         if (owner == piece_face .and. previous > 0_I4P .and. g > 0_I4P) &
            at = at + piece_size * real(glyph_kern(piece_face, previous, g), R8P) / real(face_upm(piece_face), R8P)
         if (drawn .and. count < size(glyphs, kind=I4P)) then
            count = count + 1_I4P
            glyphs(count) = placed_glyph(owner, g, code, at, shift, piece_size, 0.0_R8P, 0.0_R8P)
         endif
         if (g > 0_I4P) then
            at = at + piece_size * real(glyph_advance(owner, g), R8P) / real(face_upm(owner), R8P)
         else
            at = at + piece_size * MISSING_ADVANCE
         endif
         previous = 0_I4P
         if (owner == piece_face) previous = g
      enddo
      endsubroutine place
   endsubroutine layout_text

   pure function math_text_width(text, markup, face, base, sup) result(width)
   !< The width [px] of a text holding math (layout_text's with `math`): its text runs measured as text_advance and
   !< markup_width measure them (`markup`: enhanced), its math runs as foresight_math sets them, its superscript.
   character(len=*), intent(in) :: text   !< Text, UTF-8.
   logical,          intent(in) :: markup !< Enhanced markup read.
   integer(I4P),     intent(in) :: face   !< Base face, 1-8.
   real(R8P),        intent(in) :: base   !< Base font size [px].
   character(len=*), intent(in) :: sup    !< Superscript, empty for none.
   real(R8P)                    :: width  !< Width [px].
   type(math_item), allocatable :: items(:) !< A math run's glyphs.
   character(len=:), allocatable :: piece !< A run.
   real(R8P)                    :: w, h, d !< A math run's box.
   integer(I4P)                 :: start  !< Text left.
   integer(I4P)                 :: open   !< A math run's opening dollar.
   integer(I4P)                 :: close  !< Its closing dollar.

   width = 0.0_R8P
   start = 1_I4P
   do
      call next_math(text, start, open, close)
      if (open == 0_I4P) then
         piece = text(start:)
      else
         piece = text(start:open - 1_I4P)
      endif
      if (len(piece) > 0) then
         piece = unescape_dollars(piece)
         if (markup) then
            width = width + markup_width(piece, base, face)
         else
            width = width + text_advance(piece, face, base)
         endif
      endif
      if (open == 0_I4P) exit
      call math_layout(text(open + 1_I4P:close - 1_I4P), base, items, w, h, d)
      width = width + w
      start = close + 1_I4P
   enddo
   if (len(sup) > 0) width = width + text_advance(sup, face, 0.75_R8P * base)
   endfunction math_text_width

   pure function unescape_dollars(text) result(plain)
   !< `text` with `\$` as `$`.
   character(len=*), intent(in)  :: text  !< Text.
   character(len=:), allocatable :: plain !< Text unescaped.
   integer(I4P)                  :: k     !< Byte.

   plain = ''
   k = 1_I4P
   do while (k <= len(text, kind=I4P))
      if (text(k:k) == achar(92) .and. k < len(text, kind=I4P)) then
         if (text(k + 1_I4P:k + 1_I4P) == '$') then
            plain = plain//'$'
            k = k + 2_I4P
            cycle
         endif
      endif
      plain = plain//text(k:k)
      k = k + 1_I4P
   enddo
   endfunction unescape_dollars

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
endmodule foresight_textlayout
