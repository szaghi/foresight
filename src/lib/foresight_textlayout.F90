!< foresight_textlayout, a text's glyphs placed along its baseline.
module foresight_textlayout
!< foresight_textlayout, a text's glyphs placed along its baseline.
!<
!< The layout of the devices that draw text from the compiled-in glyphs (the SVG device's `fontglyphs`): gnuplot's
!< enhanced runs (sizes, shifts, step-backs, faces; invisible runs advance without glyphs), each character's glyph in
!< its face or, for one Liberation Sans lacks, Latin Modern's of the same style, kerned with the previous glyph of the
!< same face (the rules of foresight_font `text_advance`, so the layout's widths are the measured ones); a superscript
!< at 0.75 size raised 0.3375 font sizes.
use foresight_enhanced, only : enhanced_run, enhanced_runs, run_face, shown
use foresight_fontdata, only : face_upm, glyph_advance, glyph_index, glyph_kern
use penf, only : I4P, R8P

implicit none
private
public :: placed_glyph
public :: layout_text

real(R8P), parameter :: MISSING_ADVANCE = 0.556_R8P !< Advance of a character no face has [em].

type :: placed_glyph
   !< A glyph of a text.
   integer(I4P) :: face = 0_I4P    !< Face holding it, 1-8.
   integer(I4P) :: glyph = 0_I4P   !< Glyph index (0: a character no face has, drawn as nothing).
   integer(I4P) :: unicode = 0_I4P !< Character.
   real(R8P)    :: x = 0.0_R8P     !< Origin along the baseline from the text's start [px].
   real(R8P)    :: y = 0.0_R8P     !< Origin across the baseline [px, downward].
   real(R8P)    :: size = 0.0_R8P  !< Font size [px].
endtype placed_glyph

contains
   subroutine layout_text(text, markup, face, base, sup, glyphs, count, width)
   !< The glyphs of the UTF-8 `text` (enhanced markup read if `markup`) in `face` at `base` [px], its superscript `sup`
   !< after it: `glyphs(1:count)` from the text's start, and its `width` [px] (as text_advance and markup_width).
   character(len=*),                intent(in)  :: text      !< Text, UTF-8.
   logical,                         intent(in)  :: markup    !< Enhanced markup read.
   integer(I4P),                    intent(in)  :: face      !< Base face, 1-8.
   real(R8P),                       intent(in)  :: base      !< Base font size [px].
   character(len=*),                intent(in)  :: sup       !< Superscript, empty for none.
   type(placed_glyph), allocatable, intent(out) :: glyphs(:) !< Glyphs.
   integer(I4P),                    intent(out) :: count     !< Glyphs placed.
   real(R8P),                       intent(out) :: width     !< Width [px].
   type(enhanced_run), allocatable              :: runs(:)   !< Runs.
   real(R8P)                                    :: at        !< Pen position [px].
   integer(I4P)                                 :: k         !< Run.

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
         if (drawn) then
            count = count + 1_I4P
            glyphs(count) = placed_glyph(owner, g, code, at, shift, piece_size)
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
