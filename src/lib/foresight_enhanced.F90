!< foresight_enhanced, gnuplot's enhanced text: the markup of titles, labels and key entries as styled runs.
module foresight_enhanced
!< foresight_enhanced, gnuplot's enhanced text: the markup of titles, labels and key entries as styled runs.
!<
!< As gnuplot 6.0 (its svg terminal): `^` a superscript and `_` a subscript of the next character or `{group}`, at 0.8
!< times the size, raised 0.5 or lowered 0.3 of the current size (nested: again); `{/Font:Bold=N text}` changes the
!< font (`/Symbol` the Greek letters, written here as Unicode letters where gnuplot writes the Symbol font), its size
!< (`=N` absolute, `*F` relative), weight (`:Bold`) and style (`:Italic`); `@` makes the next element take no room (the
!< one after it written over it, as `a@^b_c`); `&` makes the next element invisible, keeping its room; `~a{.8-}`
!< overprints the second element on the first, raised by the fraction of the size; `\` makes the next character
!< literal. Widths come from the compiled-in fonts (foresight_font): each run in its face (its family, else the base
!< one; its weight and style, or the base ones) at its size, kerned.
use foresight_font, only : family_face, text_advance
use foresight_format, only : escape => xml_escape, utf8_char
use penf, only : I4P, R8P

implicit none
private

character(len=*), parameter :: HEX = '0123456789abcdefABCDEF' !< Hexadecimal digits.
public :: enhanced_run
public :: enhanced_runs
public :: has_markup
public :: markup_literal
public :: markup_plain
public :: markup_svg
public :: markup_width
public :: run_face
public :: shown

type :: enhanced_run
   !< A piece of text in one style.
   real(R8P)                     :: size = 1.0_R8P !< Size, times the base size.
   real(R8P)                     :: shift = 0.0_R8P !< Baseline offset up, times the base size.
   real(R8P)                     :: back = 0.0_R8P  !< Step back before it, times the base size.
   logical                       :: bold = .false.  !< Bold.
   logical                       :: italic = .false. !< Italic.
   logical                       :: hidden = .false. !< Invisible, its room kept (`&`).
   logical                       :: phantom = .false. !< No room taken (`@`): the next run steps back over it.
   logical                       :: symbol = .false. !< In the Symbol font: the Greek letters (Latin in `text`).
   ! the deferred-length components last (nvfortran 26.9: see foresight#3, bug 17)
   character(len=:), allocatable :: text          !< Text.
   character(len=:), allocatable :: family        !< Font family, empty for the default.
endtype enhanced_run

type :: style_state
   !< The style of the text being read.
   real(R8P)                     :: size = 1.0_R8P  !< Size, times the base size.
   real(R8P)                     :: shift = 0.0_R8P !< Baseline offset up, times the base size.
   logical                       :: bold = .false.  !< Bold.
   logical                       :: italic = .false. !< Italic.
   logical                       :: hidden = .false. !< Invisible.
   logical                       :: phantom = .false. !< No room taken.
   logical                       :: symbol = .false. !< The Greek letters of the Symbol font.
   character(len=:), allocatable :: family          !< Font family, empty for the default.
endtype style_state

contains
   pure function has_markup(text) result(yes)
   !< Whether `text` holds a character of the markup (`^ _ { } @ & ~ \`).
   character(len=*), intent(in) :: text !< Text.
   logical                      :: yes  !< Markup present.

   yes = scan(text, '^_{}@&~\') > 0
   endfunction has_markup

   pure subroutine enhanced_runs(text, runs)
   !< The runs of the enhanced `text`.
   character(len=*),                intent(in)  :: text    !< Text with markup.
   type(enhanced_run), allocatable, intent(out) :: runs(:) !< Runs.
   type(style_state)                            :: base    !< Base style.
   integer(I4P)                                 :: pos     !< Next character.

   allocate(runs(0))
   base%family = ''
   pos = 1_I4P
   call sequence(text, pos, base, runs, .false.)
   endsubroutine enhanced_runs

   pure recursive subroutine sequence(text, pos, state, runs, group)
   !< The elements from `pos` to the end of `text`, or to the `}` closing a group (`group`, `pos` left after it).
   character(len=*),                intent(in)    :: text    !< Text.
   integer(I4P),                    intent(inout) :: pos     !< Next character.
   type(style_state),               intent(in)    :: state   !< Style.
   type(enhanced_run), allocatable, intent(inout) :: runs(:) !< Runs.
   logical,                         intent(in)    :: group   !< Inside `{...}`.

   do while (pos <= len(text, kind=I4P))
      if (group .and. text(pos:pos) == '}') then
         pos = pos + 1_I4P
         return
      endif
      call element(text, pos, state, runs)
   enddo
   endsubroutine sequence

   pure recursive subroutine element(text, pos, state, runs)
   !< One element at `pos`: a character, an escaped one, a `{group}`, a font group, or a markup construct.
   character(len=*),                intent(in)    :: text    !< Text.
   integer(I4P),                    intent(inout) :: pos     !< Next character.
   type(style_state),               intent(in)    :: state   !< Style.
   type(enhanced_run), allocatable, intent(inout) :: runs(:) !< Runs.
   type(style_state)                              :: inner   !< Style of a nested element.
   integer(I4P)                                   :: first   !< First run of a phantom or overprinted element.
   real(R8P)                                      :: w       !< Width of an element [base size].
   real(R8P)                                      :: raise   !< Overprint raise [size].
   integer(I4P)                                   :: k       !< Counter.

   select case (text(pos:pos))
   case ('\')
      ! gnuplot's \U+hhhh: the character of that code point (its hex digits read greedily, as gnuplot)
      if (pos + 2_I4P < len(text, kind=I4P)) then
         if (text(pos + 1_I4P:pos + 2_I4P) == 'U+' .and. scan(text(pos + 3_I4P:pos + 3_I4P), HEX) > 0) then
            block
               integer(I4P) :: code !< Code point.

               pos = pos + 3_I4P
               code = 0_I4P
               do while (pos <= len(text, kind=I4P))
                  if (scan(text(pos:pos), HEX) == 0) exit
                  if (code < 16777216_I4P) code = 16_I4P * code + (index(HEX, text(pos:pos)) - 1_I4P) - &
                                                  merge(6_I4P, 0_I4P, index(HEX, text(pos:pos)) > 16_I4P)
                  pos = pos + 1_I4P
               enddo
               call put(utf8_char(code), state, runs)
            endblock
            return
         endif
      endif
      ! the next character as it is (a lone backslash at the end too)
      if (pos < len(text, kind=I4P)) pos = pos + 1_I4P
      call put(text(pos:pos + utf8_length(text(pos:pos)) - 1_I4P), state, runs)
      pos = pos + utf8_length(text(pos:pos))
   case ('^', '_')
      inner = state
      inner%size = 0.8_R8P * state%size
      if (text(pos:pos) == '^') then
         inner%shift = state%shift + 0.5_R8P * state%size
      else
         inner%shift = state%shift - 0.3_R8P * state%size
      endif
      pos = pos + 1_I4P
      if (pos <= len(text, kind=I4P)) call element(text, pos, inner, runs)
   case ('{')
      pos = pos + 1_I4P
      inner = state
      if (pos <= len(text, kind=I4P)) then
         if (text(pos:pos) == '/') call font_spec(text, pos, inner)
      endif
      call sequence(text, pos, inner, runs, .true.)
   case ('@')
      ! the next element takes no room: the one after it steps back over it
      inner = state
      inner%phantom = .true.
      pos = pos + 1_I4P
      first = size(runs, kind=I4P) + 1_I4P
      if (pos <= len(text, kind=I4P)) call element(text, pos, inner, runs)
      w = runs_width(runs(first:), .true.)
      if (pos <= len(text, kind=I4P)) then
         first = size(runs, kind=I4P) + 1_I4P
         call element(text, pos, state, runs)
         if (first <= size(runs, kind=I4P)) runs(first)%back = runs(first)%back + w
      endif
   case ('&')
      ! the next element invisible, its room kept
      inner = state
      inner%hidden = .true.
      pos = pos + 1_I4P
      if (pos <= len(text, kind=I4P)) call element(text, pos, inner, runs)
   case ('~')
      ! ~a{.8-}: the second element over the first, raised by the fraction of the size
      pos = pos + 1_I4P
      first = size(runs, kind=I4P) + 1_I4P
      if (pos <= len(text, kind=I4P)) call element(text, pos, state, runs)
      w = runs_width(runs(first:))
      if (pos <= len(text, kind=I4P)) then
         raise = 0.0_R8P
         inner = state
         if (text(pos:pos) == '{') then
            pos = pos + 1_I4P
            ! a number, an optional sign then digits and a point: the raise
            k = 0_I4P
            if (scan(text(pos:pos), '+-') > 0) k = 1_I4P
            k = k + verify(text(pos + k:)//'}', '0123456789.', kind=I4P) - 1_I4P
            if (k > 0_I4P) then
               if (scan(text(pos:pos + k - 1_I4P), '0123456789') > 0) then
                  raise = number_of(text(pos:pos + k - 1_I4P))
                  pos = pos + k
               endif
            endif
            inner%shift = state%shift + raise * state%size
            first = size(runs, kind=I4P) + 1_I4P
            call sequence(text, pos, inner, runs, .true.)
         else
            first = size(runs, kind=I4P) + 1_I4P
            call element(text, pos, inner, runs)
         endif
         if (first <= size(runs, kind=I4P)) runs(first)%back = runs(first)%back + w
         ! the overprint takes no room of its own
         if (first <= size(runs, kind=I4P)) runs(size(runs))%phantom = .true.
      endif
   case default
      k = utf8_length(text(pos:pos))
      call put(text(pos:min(len(text, kind=I4P), pos + k - 1_I4P)), state, runs)
      pos = pos + k
   endselect
   endsubroutine element

   pure subroutine font_spec(text, pos, state)
   !< `/Font:Bold:Italic=N` or a relative size `*F` after `{` (at `pos`, left on the text after the blank ending it): the style.
   character(len=*),  intent(in)    :: text  !< Text.
   integer(I4P),      intent(inout) :: pos   !< Next character.
   type(style_state), intent(inout) :: state !< Style.
   character(len=:), allocatable    :: spec  !< The specification.
   character(len=:), allocatable    :: name  !< Font name.
   integer(I4P)                     :: e     !< End of the specification.
   integer(I4P)                     :: k     !< Position.
   real(R8P)                        :: v     !< Size.

   e = scan(text(pos:), ' }', kind=I4P)
   if (e == 0_I4P) e = len(text(pos:), kind=I4P) + 1_I4P
   spec = text(pos + 1_I4P:pos + e - 2_I4P)
   pos = pos + e - 1_I4P
   if (pos <= len(text, kind=I4P)) then
      if (text(pos:pos) == ' ') pos = pos + 1_I4P
   endif
   ! a size: =N absolute (in base sizes of 12) or *F relative
   k = scan(spec, '=*', kind=I4P)
   if (k > 0_I4P) then
      v = number_of(spec(k + 1_I4P:))
      if (v > 0.0_R8P) then
         if (spec(k:k) == '*') then
            state%size = state%size * v
         else
            state%size = v / 12.0_R8P
         endif
      endif
      spec = spec(1:k - 1_I4P)
   endif
   if (index(spec, ':Bold') > 0) state%bold = .true.
   if (index(spec, ':Italic') > 0) state%italic = .true.
   k = index(spec, ':')
   name = spec
   if (k > 0_I4P) name = spec(1:k - 1_I4P)
   if (name == 'Symbol') then
      state%symbol = .true.
   elseif (len(name) > 0) then
      state%family = name
   endif
   endsubroutine font_spec

   pure subroutine put(piece, state, runs)
   !< Append `piece` in `state`, joined to the last run if the style is the same.
   character(len=*),                intent(in)    :: piece   !< Text.
   type(style_state),               intent(in)    :: state   !< Style.
   type(enhanced_run), allocatable, intent(inout) :: runs(:) !< Runs.
   type(enhanced_run), allocatable                :: grown(:) !< Runs, one more.
   character(len=:), allocatable                  :: text    !< The piece.
   integer(I4P)                                   :: n       !< Runs.

   text = piece
   n = size(runs, kind=I4P)
   if (n > 0_I4P) then
      associate(last => runs(n))
         if (last%size == state%size .and. last%shift == state%shift .and. (last%bold .eqv. state%bold) .and. &
             (last%italic .eqv. state%italic) .and. (last%hidden .eqv. state%hidden) .and. &
             (last%phantom .eqv. state%phantom) .and. .not. state%phantom .and. last%family == state%family .and. &
             (last%symbol .eqv. state%symbol)) then
            last%text = last%text//text
            return
         endif
      endassociate
   endif
   ! through a temporary (nvfortran 26.9: see foresight_tokens push)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1:n) = runs
   grown(n + 1_I4P)%text = text
   grown(n + 1_I4P)%size = state%size
   grown(n + 1_I4P)%shift = state%shift
   grown(n + 1_I4P)%bold = state%bold
   grown(n + 1_I4P)%italic = state%italic
   grown(n + 1_I4P)%hidden = state%hidden
   grown(n + 1_I4P)%phantom = state%phantom
   grown(n + 1_I4P)%symbol = state%symbol
   grown(n + 1_I4P)%family = state%family
   call move_alloc(grown, runs)
   endsubroutine put

   pure function runs_width(runs, all, base) result(w)
   !< Width of `runs` [base size], each run in its face (run_face) at its size; phantom runs take none (all do with
   !< `all`).
   type(enhanced_run), intent(in)           :: runs(:) !< Runs.
   logical,            intent(in), optional :: all     !< Phantom runs counted.
   integer(I4P),       intent(in), optional :: base    !< Base face (foresight_fontdata, 1-8), 1 if absent.
   real(R8P)                                :: w       !< Width.
   integer(I4P)                             :: k       !< Counter.
   integer(I4P)                             :: face    !< Base face.
   logical                                  :: every   !< Phantom runs counted.

   every = .false.
   if (present(all)) every = all
   face = 1_I4P
   if (present(base)) face = base
   w = 0.0_R8P
   do k = 1_I4P, size(runs, kind=I4P)
      w = w - runs(k)%back
      if (every .or. .not. runs(k)%phantom) w = w + text_advance(shown(runs(k)), run_face(runs(k), face), runs(k)%size)
   enddo
   endfunction runs_width

   pure function run_face(run, base) result(face)
   !< The face of `run` (foresight_fontdata, 1-8): its family if set, else the base face's; bold or italic if the run
   !< or the base face is.
   type(enhanced_run), intent(in) :: run    !< Run.
   integer(I4P),       intent(in) :: base   !< Base face, 1-8.
   integer(I4P)                   :: face   !< Face.
   integer(I4P)                   :: family !< Family index (1 sans, 2 serif).
   integer(I4P)                   :: style  !< 0 regular, 1 bold, 2 italic, 3 bold italic.
   logical                        :: known  !< Family compiled in.

   family = (base - 1_I4P) / 4_I4P + 1_I4P
   style = modulo(base - 1_I4P, 4_I4P)
   if (allocated(run%family)) then
      if (len_trim(run%family) > 0) call family_face(run%family, family, known)
   endif
   if (run%bold) style = ior(style, 1_I4P)
   if (run%italic) style = ior(style, 2_I4P)
   face = 4_I4P * (family - 1_I4P) + style + 1_I4P
   endfunction run_face

   pure function markup_width(text, font_size, base) result(width)
   !< Width of the enhanced `text` [px] at `font_size`, its runs in their faces (`base`, 1-8, the face of the text
   !< without markup; 1 if absent).
   character(len=*), intent(in)           :: text      !< Text with markup.
   real(R8P),        intent(in)           :: font_size !< Base font size [px].
   integer(I4P),     intent(in), optional :: base      !< Base face.
   real(R8P)                              :: width     !< Width [px].
   type(enhanced_run), allocatable        :: runs(:)   !< Runs.
   real(R8P)                              :: w         !< Width [base size].
   integer(I4P)                           :: face      !< Base face.

   face = 1_I4P
   if (present(base)) face = base
   call enhanced_runs(text, runs)
   w = runs_width(runs, .true., face)
   width = max(0.0_R8P, w) * font_size
   endfunction markup_width

   pure function markup_literal(text) result(literal)
   !< The `text` read as it is by the enhanced text parser: every markup character escaped with a backslash (the
   !< `noenhanced` texts whose width is measured where the device cannot be told).
   character(len=*), intent(in)  :: text    !< Text.
   character(len=:), allocatable :: literal !< Escaped text.
   integer(I4P)                  :: k       !< Counter.

   literal = ''
   do k = 1_I4P, len(text, kind=I4P)
      if (scan(text(k:k), '^_{}@&~\') > 0) then
         literal = literal//'\'//text(k:k)
      else
         literal = literal//text(k:k)
      endif
   enddo
   endfunction markup_literal

   pure function markup_plain(text) result(plain)
   !< The visible characters of the enhanced `text`, the markup dropped (the text devices; the Symbol font as its
   !< Latin letters, as gnuplot's dumb terminal).
   character(len=*), intent(in)    :: text    !< Text with markup.
   character(len=:), allocatable   :: plain   !< Plain text.
   type(enhanced_run), allocatable :: runs(:) !< Runs.
   integer(I4P)                    :: k       !< Counter.

   call enhanced_runs(text, runs)
   plain = ''
   do k = 1_I4P, size(runs, kind=I4P)
      if (runs(k)%hidden) then
         plain = plain//repeat(' ', characters(runs(k)%text))
      else
         plain = plain//runs(k)%text
      endif
   enddo
   endfunction markup_plain

   pure function markup_svg(text, font_size) result(svg)
   !< The SVG `<tspan>` elements of the enhanced `text` at `font_size` [px], as gnuplot's svg terminal writes them: a
   !< font size and a `dy` where they change, `dx` stepping back, `fill="none"` for the invisible runs; the texts XML
   !< escaped. (No escape function as an argument: nvfortran 26.9 crashes passing a function with a deferred-length
   !< result, see foresight#3.)
   character(len=*), intent(in)    :: text      !< Text with markup.
   real(R8P),        intent(in)    :: font_size !< Base font size [px].
   character(len=:), allocatable   :: svg     !< Elements.
   type(enhanced_run), allocatable :: runs(:) !< Runs.
   real(R8P)                       :: shift   !< Current baseline offset [base size].
   integer(I4P)                    :: k       !< Counter.

   call enhanced_runs(text, runs)
   svg = ''
   ! one run in the base style (escaped markup alone): the text, no element
   if (size(runs) == 1) then
      associate(r => runs(1))
         if (r%size == 1.0_R8P .and. r%shift == 0.0_R8P .and. r%back == 0.0_R8P .and. .not. (r%bold .or. r%italic &
             .or. r%hidden) .and. len(r%family) == 0) then
            svg = escape(shown(r))
            return
         endif
      endassociate
   endif
   shift = 0.0_R8P
   do k = 1_I4P, size(runs, kind=I4P)
      associate(r => runs(k))
         svg = svg//'<tspan'
         if (r%size /= 1.0_R8P) svg = svg//' font-size="'//fixed(r%size * font_size)//'"'
         if (r%back /= 0.0_R8P) svg = svg//' dx="'//fixed(-r%back * font_size)//'"'
         if (r%shift /= shift) svg = svg//' dy="'//fixed(-(r%shift - shift) * font_size)//'"'
         if (r%bold) svg = svg//' font-weight="bold"'
         if (r%italic) svg = svg//' font-style="italic"'
         if (len(r%family) > 0) svg = svg//' font-family="'//escape(r%family)//'"'
         if (r%hidden) svg = svg//' fill="none"'
         svg = svg//'>'//escape(shown(r))//'</tspan>'
         shift = r%shift
      endassociate
   enddo
   endfunction markup_svg

   pure function shown(run) result(text)
   !< The text of `run` as drawn: the Greek letters in the Symbol font.
   type(enhanced_run), intent(in) :: run  !< Run.
   character(len=:), allocatable  :: text !< Text.

   if (run%symbol) then
      text = greek(run%text)
   else
      text = run%text
   endif
   endfunction shown

   pure function greek(text) result(g)
   !< The letters of `text` as the Greek letters of the Symbol font (Adobe's encoding), in UTF-8, and the characters
   !< 160-255 as its symbols (\362 the integral, \245 infinity); others as they are.
   character(len=*), intent(in)  :: text !< Latin letters.
   character(len=:), allocatable :: g    !< Greek letters.
   character(len=*), parameter   :: LATIN = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' !< Letters.
   integer, parameter            :: CODES(52) = [945, 946, 967, 948, 949, 966, 947, 951, 953, 981, 954, 955, 956, &
                                                 957, 959, 960, 952, 961, 963, 964, 965, 982, 969, 958, 968, 950, &
                                                 913, 914, 935, 916, 917, 934, 915, 919, 921, 977, 922, 923, 924, &
                                                 925, 927, 928, 920, 929, 931, 932, 933, 962, 937, 926, 936, 918] !< Code points.
   integer, parameter            :: HIGH(0:95) = [8364, 978, 8242, 8804, 8260, 8734, 402, 9827, 9830, 9829, 9824, &
                                                 8596, 8592, 8593, 8594, 8595, 176, 177, 8243, 8805, 215, 8733, &
                                                 8706, 8226, 247, 8800, 8801, 8776, 8230, 9168, 9135, 8629, 8501, &
                                                 8465, 8476, 8472, 8855, 8853, 8709, 8745, 8746, 8835, 8839, 8836, &
                                                 8834, 8838, 8712, 8713, 8736, 8711, 174, 169, 8482, 8719, 8730, &
                                                 8901, 172, 8743, 8744, 8660, 8656, 8657, 8658, 8659, 9674, 9001, &
                                                 174, 169, 8482, 8721, 9115, 9116, 9117, 9121, 9122, 9123, 9127, &
                                                 9128, 9129, 9130, 0, 9002, 8747, 8992, 9134, 8993, 9118, 9119, &
                                                 9120, 9124, 9125, 9126, 9131, 9132, 9133, 0] !< Code points of 160-255.
   character(len=2 * len(text))  :: buffer !< Bytes (nvfortran 26.9 pads `g = g//achar(...)`: a fixed buffer).
   character(len=:), allocatable :: glyph  !< A symbol in UTF-8.
   integer(I4P)                  :: k      !< Counter.
   integer(I4P)                  :: c      !< Letter index.
   integer(I4P)                  :: n      !< Bytes written.
   integer(I4P)                  :: code   !< Latin-1 code of a two-byte character.

   n = 0_I4P
   k = 0_I4P
   do while (k < len(text, kind=I4P))
      k = k + 1_I4P
      c = index(LATIN, text(k:k), kind=I4P)
      ! the upper half of the Symbol encoding (a Latin-1 character in UTF-8: `set encoding iso_8859_1`, or written so)
      if (c == 0_I4P .and. k < len(text, kind=I4P) .and. (text(k:k) == achar(194) .or. text(k:k) == achar(195))) then
         code = 64_I4P * (iachar(text(k:k), kind=I4P) - 192_I4P) + iachar(text(k + 1_I4P:k + 1_I4P), kind=I4P) - 128_I4P
         if (code >= 160_I4P .and. code <= 255_I4P) then
            if (HIGH(code - 160_I4P) > 0) then
               glyph = utf8_char(int(HIGH(code - 160_I4P), I4P))
               buffer(n + 1_I4P:n + len(glyph, kind=I4P)) = glyph
               n = n + len(glyph, kind=I4P)
               k = k + 1_I4P
               cycle
            endif
         endif
      endif
      if (c == 0_I4P) then
         buffer(n + 1_I4P:n + 1_I4P) = text(k:k)
         n = n + 1_I4P
      else
         ! two UTF-8 bytes: 110xxxxx 10xxxxxx
         buffer(n + 1_I4P:n + 1_I4P) = achar(192 + CODES(c) / 64)
         buffer(n + 2_I4P:n + 2_I4P) = achar(128 + modulo(CODES(c), 64))
         n = n + 2_I4P
      endif
   enddo
   g = buffer(1:n)
   endfunction greek

   pure function utf8_length(lead) result(n)
   !< Bytes of the UTF-8 character starting with `lead`.
   character(len=1), intent(in) :: lead !< First byte.
   integer(I4P)                 :: n    !< Bytes.

   select case (iachar(lead))
   case (240:247)
      n = 4_I4P
   case (224:239)
      n = 3_I4P
   case (192:223)
      n = 2_I4P
   case default
      n = 1_I4P
   endselect
   endfunction utf8_length

   pure function characters(text) result(n)
   !< Characters of the UTF-8 `text` (continuation bytes not counted).
   character(len=*), intent(in) :: text !< Text.
   integer(I4P)                 :: n    !< Characters.
   integer(I4P)                 :: k    !< Byte counter.

   n = 0_I4P
   do k = 1_I4P, len(text, kind=I4P)
      if (iachar(text(k:k)) < 128 .or. iachar(text(k:k)) >= 192) n = n + 1_I4P
   enddo
   endfunction characters

   pure function number_of(text) result(v)
   !< The leading decimal number of `text`, 0 if none.
   character(len=*), intent(in) :: text !< Text.
   real(R8P)                    :: v    !< Number.
   integer(I4P)                 :: ios  !< Status.
   integer(I4P)                 :: e    !< End of the number.

   v = 0.0_R8P
   e = verify(text, '0123456789.+-eE', kind=I4P) - 1_I4P
   if (e < 0_I4P) e = len(text, kind=I4P)
   if (e == 0_I4P) return
   read(text(1:e), *, iostat=ios) v
   if (ios /= 0_I4P) v = 0.0_R8P
   endfunction number_of

   pure function fixed(v) result(s)
   !< `v` with two decimals, no trailing zeros (gnuplot writes `9.6`, `-6.00`).
   real(R8P), intent(in)         :: v !< Value.
   character(len=:), allocatable :: s !< Text.
   character(len=32)             :: buffer !< Buffer.

   write(buffer, '(F0.2)') v
   s = trim(adjustl(buffer))
   if (index(s, '.') > 0) then
      do while (s(len(s):len(s)) == '0')
         s = s(1:len(s) - 1)
      enddo
      if (s(len(s):len(s)) == '.') s = s(1:len(s) - 1)
   endif
   if (s(1:1) == '.') s = '0'//s
   if (len(s) > 1) then
      if (s(1:2) == '-.') s = '-0'//s(2:)
   endif
   if (s == '-0') s = '0'
   endfunction fixed
endmodule foresight_enhanced
