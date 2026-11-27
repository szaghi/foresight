!< foresight TeX math: a subset of LaTeX's inline math set as TeX sets it, with Latin Modern Math.
module foresight_math
!< A subset of LaTeX's inline math (`$...$`) laid out as LuaTeX lays it out with unicode-math and Latin Modern Math
!< (issue #5 step 4.1): letters in math italic, Greek (`\alpha`, `\Gamma`), sub- and superscripts (`^`, `_`, primes),
!< `\frac`, `\sqrt`, `\mathrm`, `\mathbf`, `\mathit`, operators and relations with TeX's spacing (`\cdot`, `\times`,
!< `\pm`, `\le`, `\ge`, `\partial`, `\nabla`, ...), inline `\sum`, `\prod` and `\int` (their limits as scripts),
!< accents (`\hat`, `\bar`, `\vec`, `\tilde`, `\dot`), `\left(` ... `\right)` sized to their content, operator names
!< (`\sin`, `\log`, ...) and explicit spaces (`\,`, `\;`, `\quad`). No display style, matrices nor line breaking.
!<
!< The formula is parsed into TeX's noads (Ord, Op, Bin, Rel, Open, Close, Punct, Inner, fractions, radicals, accents)
!< and set by TeX's rules (The TeXbook, appendix G) with the constants of the font's MATH table: the styles (text,
!< script, scriptscript, cramped), the spacing between atoms in mu (thin 3, medium 4, thick 5; none around binary and
!< relation atoms in scripts), the script shifts and gaps, the fraction shifts and clearances, the radical's size
!< variant and its rule, the delimiters' size variants. Script sizes are 70 % and 50 % (LaTeX's 7 and 5 pt at 10 pt),
!< with the font's script alternates (`ssty`). `\mathrm` and `\mathbf` (and operator names) are the serif text faces,
!< as unicode-math sets them in the main font.
use foresight_fontdata, only : glyph_index, glyph_advance, glyph_outline, face_upm
use foresight_mathfont
use penf, only : I4P, R8P

implicit none
private
public :: math_item
public :: math_layout
public :: has_math
public :: next_math
public :: any_upm
public :: any_advance
public :: any_outline
public :: MATH_FACE

integer(I4P), parameter :: MATH_FACE = 9_I4P !< Face number of the math font (the text faces are 1-8).
! noad kinds: TeX's atoms (1-8), then the constructions
integer(I4P), parameter :: ORD = 1_I4P, OP = 2_I4P, BIN = 3_I4P, REL = 4_I4P, OPEN = 5_I4P, CLOSE = 6_I4P, &
                           PUNCT = 7_I4P, INNER = 8_I4P, FRAC = 9_I4P, RADICAL = 10_I4P, ACCENT = 11_I4P, &
                           SPACE = 12_I4P, FENCED = 13_I4P
! styles: text, script, scriptscript (display is not used: labels are inline)
integer(I4P), parameter :: TEXT_STYLE = 1_I4P, SCRIPT_STYLE = 2_I4P, SCRIPTSCRIPT_STYLE = 3_I4P
! TeX's spacing between atoms (The TeXbook, chapter 18): 0 none, 1 thin, 2 medium, 3 thick, negative only in text style
integer(I4P), parameter :: SPACING(8, 8) = reshape([ &
   0, 1, -2, -3, 0, 0, 0, -1, &  ! after Ord
   1, 1, 9, -3, 0, 0, 0, -1, &   ! after Op
   -2, -2, 9, 9, -2, 9, 9, -2, & ! after Bin
   -3, -3, 9, 0, -3, 0, 0, -3, & ! after Rel
   0, 0, 9, 0, 0, 0, 0, 0, &     ! after Open
   0, 1, -2, -3, 0, 0, 0, -1, &  ! after Close
   -1, -1, 9, -1, -1, -1, -1, -1, & ! after Punct
   -1, 1, -2, -3, -1, 0, -1, -1], [8, 8]) !< SPACING(right, left).
real(R8P),    parameter :: MU(3) = [3.0_R8P, 4.0_R8P, 5.0_R8P] / 18.0_R8P !< Thin, medium, thick spaces [em].
real(R8P),    parameter :: NULL_DELIMITER = 0.12_R8P !< LaTeX's \nulldelimiterspace, 1.2 pt at 10 pt [em].
real(R8P),    parameter :: SCALE(3) = [1.0_R8P, 0.7_R8P, 0.5_R8P] !< Size of each style [base size].

type :: math_item
   !< A glyph or a rule of a formula, from its origin (the start of its baseline), y up.
   integer(I4P) :: face = 0_I4P    !< MATH_FACE (the math font) or a text face (1-8); 0 for a rule.
   integer(I4P) :: glyph = 0_I4P   !< Glyph number in its face.
   integer(I4P) :: unicode = 0_I4P !< Character shown.
   real(R8P)    :: x = 0.0_R8P     !< Origin abscissa (a rule's left).
   real(R8P)    :: y = 0.0_R8P     !< Baseline ordinate (a rule's bottom), up.
   real(R8P)    :: size = 0.0_R8P  !< Font size (a rule's width).
   real(R8P)    :: height = 0.0_R8P !< A rule's height.
endtype math_item

type :: noad_tree
   !< The parsed formula: noads in lists (linked by `next`), each with a nucleus and its scripts.
   integer(I4P), allocatable :: kind(:)  !< Noad kind.
   integer(I4P), allocatable :: face(:)  !< Face of a character nucleus (MATH_FACE or a text face).
   integer(I4P), allocatable :: glyph(:) !< Glyph of a character nucleus (an accent's, a radical's), 0 if a list.
   integer(I4P), allocatable :: code(:)  !< Its character.
   integer(I4P), allocatable :: list(:)  !< Nucleus list (a fraction's numerator, a radical's or accent's body).
   integer(I4P), allocatable :: other(:) !< A fraction's denominator.
   integer(I4P), allocatable :: left(:)  !< A fenced list's left delimiter glyph (0 none).
   integer(I4P), allocatable :: right(:) !< Its right delimiter glyph (0 none).
   integer(I4P), allocatable :: sup(:)   !< Superscript list, 0 none.
   integer(I4P), allocatable :: sub(:)   !< Subscript list, 0 none.
   integer(I4P), allocatable :: next(:)  !< Next noad of the list, 0 last.
   real(R8P),    allocatable :: space(:) !< An explicit space [em] (SPACE noads).
   integer(I4P)              :: n = 0_I4P !< Noads.
endtype noad_tree

type :: box_state
   !< The items of the formula being set and the boxes' extents.
   type(math_item), allocatable :: items(:) !< Items.
   integer(I4P)                 :: n = 0_I4P !< Items in use.
endtype box_state

contains
   pure subroutine math_layout(source, size, items, width, height, depth)
   !< The items of the math `source` (without its `$`) set in text style at font `size`: glyphs and rules from the
   !< formula's origin (y up, in the units of `size`), its `width`, `height` and `depth`.
   character(len=*),             intent(in)  :: source   !< LaTeX math.
   real(R8P),                    intent(in)  :: size     !< Font size.
   type(math_item), allocatable, intent(out) :: items(:) !< Glyphs and rules.
   real(R8P),                    intent(out) :: width    !< Width.
   real(R8P),                    intent(out) :: height   !< Height above the baseline.
   real(R8P),                    intent(out) :: depth    !< Depth below it.
   type(noad_tree)                           :: tree     !< Noads.
   type(box_state)                           :: state    !< Items.
   integer(I4P)                              :: at       !< Parse position.
   integer(I4P)                              :: head     !< The formula's list.
   integer(I4P)                              :: first    !< Its first item.
   integer(I4P)                              :: k        !< Counter.

   allocate(tree%kind(4 * len(source) + 8), tree%face(4 * len(source) + 8), tree%glyph(4 * len(source) + 8), &
            tree%code(4 * len(source) + 8), tree%list(4 * len(source) + 8), tree%other(4 * len(source) + 8), &
            tree%left(4 * len(source) + 8), tree%right(4 * len(source) + 8), tree%sup(4 * len(source) + 8), &
            tree%sub(4 * len(source) + 8), tree%next(4 * len(source) + 8), tree%space(4 * len(source) + 8))
   allocate(state%items(8 * len(source) + 16))
   at = 1_I4P
   call parse_list(tree, source, at, .false., head)
   first = 1_I4P
   call set_list(tree, state, head, TEXT_STYLE, .false., size, width, height, depth, first)
   allocate(items(state%n))
   do k = 1_I4P, state%n
      items(k) = state%items(k)
   enddo
   endsubroutine math_layout

   pure function has_math(text) result(yes)
   !< Whether `text` holds math (next_math).
   character(len=*), intent(in) :: text  !< Text.
   logical                      :: yes   !< It holds math.
   integer(I4P)                 :: open  !< A run's opening dollar.
   integer(I4P)                 :: close !< Its closing dollar.

   call next_math(text, 1_I4P, open, close)
   yes = open > 0_I4P
   endfunction has_math

   pure subroutine next_math(text, from, open, close)
   !< The next math run of `text` from `from`, as pandoc reads TeX math in text: an unescaped `$` followed by a non-blank
   !< opens it, the next unescaped `$` preceded by a non-blank and followed by no letter, digit nor `_` closes it
   !< (gnuplot's `$data` blocks and `$f(x)` function blocks, `$5 and $10`, are text); `open` and `close` the dollars'
   !< positions, 0 when there is none.
   character(len=*), intent(in)  :: text  !< Text.
   integer(I4P),     intent(in)  :: from  !< First position.
   integer(I4P),     intent(out) :: open  !< Opening dollar, 0 none.
   integer(I4P),     intent(out) :: close !< Closing dollar, 0 none.
   integer(I4P)                  :: i     !< Opening candidate.
   integer(I4P)                  :: j     !< Closing candidate.
   integer(I4P)                  :: n     !< Length.

   open = 0_I4P
   close = 0_I4P
   n = len(text, kind=I4P)
   do i = from, n - 1_I4P
      if (.not. dollar(i)) cycle
      if (text(i + 1_I4P:i + 1_I4P) == ' ' .or. text(i + 1_I4P:i + 1_I4P) == '$') cycle
      do j = i + 2_I4P, n
         if (.not. dollar(j)) cycle
         if (text(j - 1_I4P:j - 1_I4P) == ' ') cycle
         if (j < n) then
            if (is_letter(text(j + 1_I4P:j + 1_I4P)) .or. scan(text(j + 1_I4P:j + 1_I4P), '0123456789_') > 0) cycle
         endif
         open = i
         close = j
         return
      enddo
   enddo
   contains
      pure function dollar(k) result(yes)
      !< An unescaped dollar at `k`.
      integer(I4P), intent(in) :: k   !< Position.
      logical                  :: yes !< A dollar.

      yes = text(k:k) == '$'
      if (yes .and. k > 1_I4P) yes = text(k - 1_I4P:k - 1_I4P) /= achar(92)
      endfunction dollar
   endsubroutine next_math

   pure function any_upm(face) result(upm)
   !< Units to the em of a text face (1-8) or of the math font (MATH_FACE).
   integer(I4P), intent(in) :: face !< Face.
   integer(I4P)             :: upm  !< Units.

   if (face == MATH_FACE) then
      upm = MATH_UPM
   else
      upm = face_upm(face)
   endif
   endfunction any_upm

   pure function any_advance(face, glyph) result(advance)
   !< Advance of a glyph of a text face or of the math font [font units].
   integer(I4P), intent(in) :: face    !< Face.
   integer(I4P), intent(in) :: glyph   !< Glyph.
   integer(I4P)             :: advance !< Advance.

   if (face == MATH_FACE) then
      advance = math_advance(glyph)
   else
      advance = glyph_advance(face, glyph)
   endif
   endfunction any_advance

   pure subroutine any_outline(face, glyph, ops, points)
   !< Outline of a glyph of a text face or of the math font.
   integer(I4P),              intent(in)  :: face      !< Face.
   integer(I4P),              intent(in)  :: glyph     !< Glyph.
   integer(I4P), allocatable, intent(out) :: ops(:)    !< Operations.
   integer(I4P), allocatable, intent(out) :: points(:) !< Points, x and y.

   if (face == MATH_FACE) then
      call math_outline(glyph, ops, points)
   else
      call glyph_outline(face, glyph, ops, points)
   endif
   endsubroutine any_outline

   ! parsing
   pure recursive subroutine parse_list(tree, source, at, closed, head)
   !< The noads from `at` to the end, to the `}` closing the group (`closed`) or to a `\right`: its first noad.
   type(noad_tree),  intent(inout) :: tree   !< Noads.
   character(len=*), intent(in)    :: source !< LaTeX math.
   integer(I4P),     intent(inout) :: at     !< Position.
   logical,          intent(in)    :: closed !< A group: stop after its `}`.
   integer(I4P), intent(out) :: head   !< First noad, 0 for an empty list.
   integer(I4P)                    :: last   !< Last noad.
   integer(I4P)                    :: noad   !< A noad.

   head = 0_I4P
   last = 0_I4P
   do
      call skip_blanks(source, at)
      if (at > len(source, kind=I4P)) exit
      if (source(at:at) == '}') then
         if (closed) at = at + 1_I4P
         exit
      endif
      if (starts(source, at, achar(92)//'right')) exit
      if (source(at:at) == '^' .or. source(at:at) == '_' .or. source(at:at) == "'") then
         ! scripts of the previous noad (an empty Ord when there is none)
         if (last == 0_I4P) then
            call new_noad(tree, ORD, noad)
            head = noad
            last = noad
         endif
         call parse_scripts(tree, source, at, last)
         cycle
      endif
      call parse_atom(tree, source, at, noad)
      if (noad == 0_I4P) cycle
      if (last == 0_I4P) then
         head = noad
      else
         tree%next(last) = noad
      endif
      last = noad
   enddo
   endsubroutine parse_list

   pure recursive subroutine parse_scripts(tree, source, at, noad)
   !< The `^`, `_` and primes after a noad: its superscript and subscript lists.
   type(noad_tree),  intent(inout) :: tree   !< Noads.
   character(len=*), intent(in)    :: source !< LaTeX math.
   integer(I4P),     intent(inout) :: at     !< Position (at the first script sign).
   integer(I4P),     intent(in)    :: noad   !< The noad.
   integer(I4P)                    :: primes !< Primes.
   integer(I4P)                    :: p      !< A prime noad.
   integer(I4P)                    :: rest   !< A superscript after the primes.
   integer(I4P)                    :: hold   !< A list parsed.

   do
      call skip_blanks(source, at)
      if (at > len(source, kind=I4P)) return
      select case (source(at:at))
      case ("'")
         ! primes: a superscript of one prime per quote (U+2032, U+2033, U+2034), then a `^` joins them
         primes = 0_I4P
         do while (at <= len(source, kind=I4P))
            if (source(at:at) /= "'") exit
            primes = primes + 1_I4P
            at = at + 1_I4P
         enddo
         call new_char(tree, ORD, 8241_I4P + min(primes, 3_I4P), p)
         call skip_blanks(source, at)
         if (at <= len(source, kind=I4P)) then
            if (source(at:at) == '^') then
               at = at + 1_I4P
               call parse_argument(tree, source, at, rest)
               tree%next(p) = rest
            endif
         endif
         tree%sup(noad) = p
      case ('^')
         at = at + 1_I4P
         call parse_argument(tree, source, at, hold)
         tree%sup(noad) = hold
      case ('_')
         at = at + 1_I4P
         call parse_argument(tree, source, at, hold)
         tree%sub(noad) = hold
      case default
         return
      endselect
   enddo
   endsubroutine parse_scripts

   pure recursive subroutine parse_argument(tree, source, at, head)
   !< A macro's or a script's argument: a `{...}` group, else one atom.
   type(noad_tree),  intent(inout) :: tree   !< Noads.
   character(len=*), intent(in)    :: source !< LaTeX math.
   integer(I4P),     intent(inout) :: at     !< Position.
   integer(I4P), intent(out) :: head   !< First noad.

   call skip_blanks(source, at)
   head = 0_I4P
   if (at > len(source, kind=I4P)) return
   if (source(at:at) == '{') then
      at = at + 1_I4P
      call parse_list(tree, source, at, .true., head)
   else
      call parse_atom(tree, source, at, head)
   endif
   endsubroutine parse_argument

   pure recursive subroutine parse_atom(tree, source, at, noad)
   !< One atom at `at`: a character, a command, a group as an Ord; 0 for nothing (a font switch's empty group).
   type(noad_tree),  intent(inout) :: tree    !< Noads.
   character(len=*), intent(in)    :: source  !< LaTeX math.
   integer(I4P),     intent(inout) :: at      !< Position.
   integer(I4P), intent(out) :: noad    !< Noad.
   character(len=:), allocatable   :: name    !< Command name.
   integer(I4P)                    :: code    !< Character.
   integer(I4P)                    :: kind    !< Atom kind.
   integer(I4P)                    :: n       !< Bytes of a UTF-8 character.
   integer(I4P)                    :: hold    !< A list parsed.

   noad = 0_I4P
   if (source(at:at) == '{') then
      at = at + 1_I4P
      call new_noad(tree, ORD, noad)
      call parse_list(tree, source, at, .true., hold)
      tree%list(noad) = hold
      return
   endif
   if (source(at:at) /= achar(92)) then
      call utf8_code(source, at, code, n)
      at = at + n
      call math_char(tree, code, noad)
      return
   endif
   ! a command: a control word, or a backslash and one character
   at = at + 1_I4P
   if (at > len(source, kind=I4P)) return
   if (.not. is_letter(source(at:at))) then
      name = source(at:at)
      at = at + 1_I4P
   else
      name = ''
      do while (at <= len(source, kind=I4P))
         if (.not. is_letter(source(at:at))) exit
         name = name//source(at:at)
         at = at + 1_I4P
      enddo
   endif
   select case (name)
   case (',', ':', '>', ';', '!', ' ', 'quad', 'qquad')
      call new_noad(tree, SPACE, noad)
      select case (name)
      case (',')
         tree%space(noad) = MU(1)
      case (':', '>')
         tree%space(noad) = MU(2)
      case (';')
         tree%space(noad) = MU(3)
      case ('!')
         tree%space(noad) = -MU(1)
      case (' ')
         tree%space(noad) = 0.333_R8P
      case ('quad')
         tree%space(noad) = 1.0_R8P
      case default
         tree%space(noad) = 2.0_R8P
      endselect
   case ('{', '}', '|', '#', '%', '&', '_', '$')
      code = iachar(name(1:1))
      if (name == '|') code = 8214
      kind = ORD
      if (name == '{') kind = OPEN
      if (name == '}') kind = CLOSE
      call new_char(tree, kind, code, noad)
   case ('frac', 'dfrac', 'tfrac')
      call new_noad(tree, FRAC, noad)
      call parse_argument(tree, source, at, hold)
      tree%list(noad) = hold
      call parse_argument(tree, source, at, hold)
      tree%other(noad) = hold
   case ('sqrt')
      call new_noad(tree, RADICAL, noad)
      tree%glyph(noad) = math_glyph(8730_I4P)
      tree%code(noad) = 8730_I4P
      call parse_argument(tree, source, at, hold)
      tree%list(noad) = hold
   case ('hat', 'widehat', 'bar', 'overline', 'vec', 'tilde', 'widetilde', 'dot', 'ddot', 'check', 'breve', 'acute', &
         'grave')
      call new_noad(tree, ACCENT, noad)
      select case (name)
      case ('hat', 'widehat')
         code = 770
      case ('bar', 'overline')
         code = 772
      case ('vec')
         code = 8407
      case ('tilde', 'widetilde')
         code = 771
      case ('dot')
         code = 775
      case ('ddot')
         code = 776
      case ('check')
         code = 780
      case ('breve')
         code = 774
      case ('acute')
         code = 769
      case default
         code = 768
      endselect
      tree%code(noad) = code
      tree%glyph(noad) = math_glyph(code)
      tree%face(noad) = MATH_FACE
      call parse_argument(tree, source, at, hold)
      tree%list(noad) = hold
   case ('mathrm', 'mathbf', 'mathit', 'text', 'textrm', 'mathsf', 'operatorname')
      call new_noad(tree, ORD, noad)
      if (name == 'operatorname') tree%kind(noad) = OP
      call text_argument(tree, source, at, merge(6_I4P, merge(7_I4P, 5_I4P, name == 'mathit'), name == 'mathbf'), &
                         hold)
      tree%list(noad) = hold
   case ('sin', 'cos', 'tan', 'cot', 'sec', 'csc', 'sinh', 'cosh', 'tanh', 'exp', 'log', 'ln', 'lg', 'arcsin', &
         'arccos', 'arctan', 'det', 'dim', 'max', 'min', 'sup', 'inf', 'lim', 'arg', 'deg', 'gcd', 'ker', 'Pr')
      call new_noad(tree, OP, noad)
      call text_list(tree, name, 5_I4P, hold)
      tree%list(noad) = hold
   case ('left')
      call new_noad(tree, FENCED, noad)
      call delimiter(source, at, tree%left(noad))
      call parse_list(tree, source, at, .false., hold)
      tree%list(noad) = hold
      if (starts(source, at, achar(92)//'right')) then
         at = at + 6_I4P
         call delimiter(source, at, tree%right(noad))
      endif
   case ('displaystyle', 'textstyle', 'scriptstyle', 'limits', 'nolimits', 'left.', 'big', 'Big', 'bigl', 'bigr')
      noad = 0_I4P
   case default
      call command_code(name, kind, code)
      if (code == 0_I4P) then
         ! unknown: its name in the text face, as LaTeX would complain about it
         call new_noad(tree, ORD, noad)
         call text_list(tree, achar(92)//name, 5_I4P, hold)
         tree%list(noad) = hold
      else
         call new_char(tree, kind, code, noad)
      endif
   endselect
   endsubroutine parse_atom

   pure subroutine text_argument(tree, source, at, face, head)
   !< The `{...}` argument of `\mathrm` and its kin: its characters (blanks skipped, as math does; kept in `\text`) in a
   !< text face, as Ord noads.
   type(noad_tree),  intent(inout) :: tree   !< Noads.
   character(len=*), intent(in)    :: source !< LaTeX math.
   integer(I4P),     intent(inout) :: at     !< Position.
   integer(I4P),     intent(in)    :: face   !< Text face.
   integer(I4P), intent(out) :: head   !< First noad.
   integer(I4P)                    :: depth  !< Brace depth.
   integer(I4P)                    :: start  !< Argument start.

   call skip_blanks(source, at)
   head = 0_I4P
   if (at > len(source, kind=I4P)) return
   if (source(at:at) /= '{') then
      call text_list(tree, source(at:at), face, head)
      at = at + 1_I4P
      return
   endif
   depth = 0_I4P
   start = at + 1_I4P
   do while (at <= len(source, kind=I4P))
      if (source(at:at) == '{') depth = depth + 1_I4P
      if (source(at:at) == '}') depth = depth - 1_I4P
      at = at + 1_I4P
      if (depth == 0_I4P) exit
   enddo
   call text_list(tree, source(start:at - 2_I4P), face, head)
   endsubroutine text_argument

   pure subroutine text_list(tree, text, face, head)
   !< Ord noads of the characters of `text` (UTF-8, braces and blanks out) in a text face.
   type(noad_tree),  intent(inout) :: tree  !< Noads.
   character(len=*), intent(in)    :: text  !< Text.
   integer(I4P),     intent(in)    :: face  !< Text face.
   integer(I4P), intent(out) :: head  !< First noad.
   integer(I4P)                    :: last  !< Last noad.
   integer(I4P)                    :: noad  !< A noad.
   integer(I4P)                    :: j     !< Position.
   integer(I4P)                    :: code  !< Character.
   integer(I4P)                    :: n     !< Its bytes.

   head = 0_I4P
   last = 0_I4P
   j = 1_I4P
   do while (j <= len(text, kind=I4P))
      call utf8_code(text, j, code, n)
      j = j + n
      if (code == 123 .or. code == 125 .or. code == 32 .or. code == 92) cycle
      call new_noad(tree, ORD, noad)
      tree%face(noad) = face
      tree%code(noad) = code
      tree%glyph(noad) = glyph_index(face, code)
      if (last == 0_I4P) then
         head = noad
      else
         tree%next(last) = noad
      endif
      last = noad
   enddo
   endsubroutine text_list

   pure subroutine delimiter(source, at, glyph)
   !< The delimiter after `\left` or `\right`: its math glyph, 0 for `.`.
   character(len=*), intent(in)    :: source !< LaTeX math.
   integer(I4P),     intent(inout) :: at     !< Position.
   integer(I4P), intent(out) :: glyph  !< Glyph.
   integer(I4P)                    :: code   !< Character.
   integer(I4P)                    :: kind   !< Atom kind.
   integer(I4P)                    :: n      !< Bytes.
   character(len=:), allocatable   :: name   !< Command.

   call skip_blanks(source, at)
   glyph = 0_I4P
   if (at > len(source, kind=I4P)) return
   if (source(at:at) == achar(92)) then
      at = at + 1_I4P
      name = ''
      if (at <= len(source, kind=I4P)) then
         if (.not. is_letter(source(at:at))) then
            name = source(at:at)
            at = at + 1_I4P
         endif
      endif
      do while (at <= len(source, kind=I4P) .and. len(name) == 0)
         exit
      enddo
      if (len(name) == 0) then
         do while (at <= len(source, kind=I4P))
            if (.not. is_letter(source(at:at))) exit
            name = name//source(at:at)
            at = at + 1_I4P
         enddo
      endif
      select case (name)
      case ('{', 'lbrace')
         code = 123
      case ('}', 'rbrace')
         code = 125
      case ('|', 'Vert')
         code = 8214
      case default
         call command_code(name, kind, code)
      endselect
   else
      call utf8_code(source, at, code, n)
      at = at + n
      if (code == 46) return
   endif
   glyph = math_glyph(code)
   endsubroutine delimiter

   pure subroutine math_char(tree, code, noad)
   !< The noad of a character typed in math: letters in math italic, digits and signs upright, each its atom kind.
   type(noad_tree), intent(inout) :: tree !< Noads.
   integer(I4P),    intent(in)    :: code !< Character.
   integer(I4P), intent(out) :: noad !< Noad.
   integer(I4P)                   :: c    !< Character set.
   integer(I4P)                   :: kind !< Atom kind.

   c = code
   kind = ORD
   if (c >= 97 .and. c <= 122) then
      c = 119886 + c - 97
      if (code == 104) c = 8462
   elseif (c >= 65 .and. c <= 90) then
      c = 119860 + c - 65
   elseif (c >= 945 .and. c <= 969) then
      c = 120572 + c - 945
   else
      select case (c)
      case (43, 42, 8722, 177, 215, 8901, 183, 8723, 8728, 8729, 8745, 8746, 8743, 8744, 8853, 8855)
         kind = BIN
         if (c == 42) c = 8727
      case (45)
         kind = BIN
         c = 8722
      case (61, 60, 62, 58, 8804, 8805, 8800, 8776, 8801, 8764, 8771, 8773, 8733, 8594, 8592, 8596, 8658, 8656, &
            8660, 8712, 8713, 8834, 8835, 8838, 8839, 8810, 8811, 8869)
         kind = REL
      case (40, 91, 10216, 8968, 8970)
         kind = OPEN
      case (41, 93, 33, 63, 10217, 8969, 8971)
         kind = CLOSE
      case (44, 59)
         kind = PUNCT
      case (8721, 8719, 8747, 8750)
         kind = OP
      case (39)
         c = 8242
      endselect
   endif
   call new_char(tree, kind, c, noad)
   endsubroutine math_char

   pure subroutine command_code(name, kind, code)
   !< The character and atom kind of a symbol command, 0 if `name` is not one.
   character(len=*), intent(in)  :: name !< Command name.
   integer(I4P),     intent(out) :: kind !< Atom kind.
   integer(I4P), intent(out) :: code !< Character.
   character(len=*), parameter   :: GREEK = 'alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu nu xi '// &
                                            'omicron pi rho varsigma sigma tau upsilon phi chi psi omega' !< Lower case.
   character(len=*), parameter   :: CAPITALS = 'Gamma Delta Theta Lambda Xi Pi Sigma Upsilon Phi Psi Omega' !< Upright.
   integer(I4P),     parameter   :: CAPITAL_CODES(11) = [915, 916, 920, 923, 926, 928, 931, 933, 934, 936, 937] !< Codes.
   integer(I4P)                  :: k !< Word.

   kind = ORD
   code = 0_I4P
   k = word_number(GREEK, name)
   if (k > 0_I4P) then
      code = 120572 + k - 1
      return
   endif
   k = word_number(CAPITALS, name)
   if (k > 0_I4P) then
      code = CAPITAL_CODES(k)
      return
   endif
   select case (name)
   case ('varepsilon')
      code = 120576
   case ('vartheta')
      code = 120599
   case ('varphi')
      code = 120593
   case ('varpi')
      code = 120603
   case ('varrho')
      code = 120602
   case ('partial')
      code = 120597
   case ('nabla')
      code = 8711
   case ('infty')
      code = 8734
   case ('ell')
      code = 8467
   case ('hbar')
      code = 8463
   case ('prime')
      code = 8242
   case ('forall')
      code = 8704
   case ('exists')
      code = 8707
   case ('emptyset', 'varnothing')
      code = 8709
   case ('neg', 'lnot')
      code = 172
   case ('ldots', 'dots')
      code = 8230
   case ('cdots')
      code = 8943
   case ('vert')
      code = 124
   case ('cdot')
      code = 8901
      kind = BIN
   case ('times')
      code = 215
      kind = BIN
   case ('pm')
      code = 177
      kind = BIN
   case ('mp')
      code = 8723
      kind = BIN
   case ('circ')
      code = 8728
      kind = BIN
   case ('bullet')
      code = 8729
      kind = BIN
   case ('cap')
      code = 8745
      kind = BIN
   case ('cup')
      code = 8746
      kind = BIN
   case ('wedge', 'land')
      code = 8743
      kind = BIN
   case ('vee', 'lor')
      code = 8744
      kind = BIN
   case ('oplus')
      code = 8853
      kind = BIN
   case ('otimes')
      code = 8855
      kind = BIN
   case ('le', 'leq')
      code = 8804
      kind = REL
   case ('ge', 'geq')
      code = 8805
      kind = REL
   case ('ne', 'neq')
      code = 8800
      kind = REL
   case ('approx')
      code = 8776
      kind = REL
   case ('equiv')
      code = 8801
      kind = REL
   case ('sim')
      code = 8764
      kind = REL
   case ('simeq')
      code = 8771
      kind = REL
   case ('cong')
      code = 8773
      kind = REL
   case ('propto')
      code = 8733
      kind = REL
   case ('to', 'rightarrow')
      code = 8594
      kind = REL
   case ('leftarrow', 'gets')
      code = 8592
      kind = REL
   case ('leftrightarrow')
      code = 8596
      kind = REL
   case ('Rightarrow', 'implies')
      code = 8658
      kind = REL
   case ('Leftarrow')
      code = 8656
      kind = REL
   case ('Leftrightarrow', 'iff')
      code = 8660
      kind = REL
   case ('in')
      code = 8712
      kind = REL
   case ('notin')
      code = 8713
      kind = REL
   case ('subset')
      code = 8834
      kind = REL
   case ('supset')
      code = 8835
      kind = REL
   case ('subseteq')
      code = 8838
      kind = REL
   case ('supseteq')
      code = 8839
      kind = REL
   case ('ll')
      code = 8810
      kind = REL
   case ('gg')
      code = 8811
      kind = REL
   case ('perp')
      code = 8869
      kind = REL
   case ('mid')
      code = 8739
      kind = REL
   case ('parallel')
      code = 8741
      kind = REL
   case ('sum')
      code = 8721
      kind = OP
   case ('prod')
      code = 8719
      kind = OP
   case ('int')
      code = 8747
      kind = OP
   case ('oint')
      code = 8750
      kind = OP
   case ('langle')
      code = 10216
      kind = OPEN
   case ('rangle')
      code = 10217
      kind = CLOSE
   case ('lfloor')
      code = 8970
      kind = OPEN
   case ('rfloor')
      code = 8971
      kind = CLOSE
   case ('lceil')
      code = 8968
      kind = OPEN
   case ('rceil')
      code = 8969
      kind = CLOSE
   case ('lbrace')
      code = 123
      kind = OPEN
   case ('rbrace')
      code = 125
      kind = CLOSE
   endselect
   endsubroutine command_code

   pure subroutine new_noad(tree, kind, noad)
   !< A fresh noad of `kind`.
   type(noad_tree), intent(inout) :: tree !< Noads.
   integer(I4P),    intent(in)    :: kind !< Kind.
   integer(I4P), intent(out) :: noad !< Noad.

   tree%n = tree%n + 1_I4P
   noad = tree%n
   tree%kind(noad) = kind
   tree%face(noad) = MATH_FACE
   tree%glyph(noad) = 0_I4P
   tree%code(noad) = 0_I4P
   tree%list(noad) = 0_I4P
   tree%other(noad) = 0_I4P
   tree%left(noad) = 0_I4P
   tree%right(noad) = 0_I4P
   tree%sup(noad) = 0_I4P
   tree%sub(noad) = 0_I4P
   tree%next(noad) = 0_I4P
   tree%space(noad) = 0.0_R8P
   endsubroutine new_noad

   pure subroutine new_char(tree, kind, code, noad)
   !< A noad of `kind` whose nucleus is the math font's character `code`.
   type(noad_tree), intent(inout) :: tree !< Noads.
   integer(I4P),    intent(in)    :: kind !< Kind.
   integer(I4P),    intent(in)    :: code !< Character.
   integer(I4P), intent(out) :: noad !< Noad.

   call new_noad(tree, kind, noad)
   tree%code(noad) = code
   tree%glyph(noad) = math_glyph(code)
   endsubroutine new_char

   ! setting
   pure recursive subroutine set_list(tree, state, head, style, cramped, base, width, height, depth, first)
   !< Set the list from `head` in `style` (cramped or not) at base size `base`: its items appended from `first`, from
   !< the list's origin; its width, height and depth.
   type(noad_tree), intent(inout) :: tree    !< Noads.
   type(box_state), intent(inout) :: state   !< Items.
   integer(I4P),    intent(in)    :: head    !< First noad.
   integer(I4P),    intent(in)    :: style   !< Style.
   logical,         intent(in)    :: cramped !< Cramped.
   real(R8P),       intent(in)    :: base    !< Base font size.
   real(R8P),       intent(out)   :: width   !< Width.
   real(R8P),       intent(out)   :: height  !< Height.
   real(R8P),       intent(out)   :: depth   !< Depth.
   integer(I4P),    intent(out)   :: first   !< First item.
   integer(I4P)                   :: noad    !< A noad.
   integer(I4P)                   :: previous !< The previous atom's kind, 0 none.
   integer(I4P)                   :: kind    !< Its kind for spacing.
   integer(I4P)                   :: s       !< Space code.
   integer(I4P)                   :: from    !< A noad's first item.
   real(R8P)                      :: size    !< Font size of the style.
   real(R8P)                      :: w       !< A noad's width.
   real(R8P)                      :: h       !< Its height.
   real(R8P)                      :: d       !< Its depth.

   first = state%n + 1_I4P
   width = 0.0_R8P
   height = 0.0_R8P
   depth = 0.0_R8P
   size = base * SCALE(style)
   call binary_to_ordinary(tree, head)
   previous = 0_I4P
   noad = head
   do while (noad > 0_I4P)
      if (tree%kind(noad) == SPACE) then
         width = width + tree%space(noad) * size
         noad = tree%next(noad)
         cycle
      endif
      kind = atom_kind(tree%kind(noad))
      if (previous > 0_I4P) then
         s = SPACING(kind, previous)
         if (s < 0_I4P .and. style == TEXT_STYLE) width = width + MU(-s) * size
         if (s > 0_I4P .and. s < 9_I4P) width = width + MU(s) * size
      endif
      call set_noad(tree, state, noad, style, cramped, base, w, h, d, from, tree%next(noad) == 0_I4P)
      call shift(state, from, state%n, width, 0.0_R8P)
      width = width + w
      height = max(height, h)
      depth = max(depth, d)
      previous = kind
      noad = tree%next(noad)
   enddo
   endsubroutine set_list

   pure recursive subroutine set_noad(tree, state, noad, style, cramped, base, width, height, depth, first, last)
   !< Set one noad, its nucleus and scripts, from its origin; a character's italic correction added to its width unless
   !< it is the `last` of its list (as LuaTeX).
   type(noad_tree), intent(inout) :: tree    !< Noads.
   type(box_state), intent(inout) :: state   !< Items.
   integer(I4P),    intent(in)    :: noad    !< Noad.
   integer(I4P),    intent(in)    :: style   !< Style.
   logical,         intent(in)    :: cramped !< Cramped.
   real(R8P),       intent(in)    :: base    !< Base size.
   real(R8P),       intent(out)   :: width   !< Width.
   real(R8P),       intent(out)   :: height  !< Height.
   real(R8P),       intent(out)   :: depth   !< Depth.
   integer(I4P),    intent(out)   :: first   !< First item.
   logical,         intent(in)    :: last    !< The last noad of its list.
   real(R8P)                      :: size    !< Font size of the style.
   real(R8P)                      :: italic  !< Italic correction of a character nucleus.
   real(R8P)                      :: shift_y !< Vertical shift of a big operator.
   logical                        :: char    !< The nucleus is a character.

   first = state%n + 1_I4P
   size = base * SCALE(style)
   italic = 0.0_R8P
   char = .false.
   select case (tree%kind(noad))
   case (FRAC)
      call set_fraction(tree, state, noad, style, cramped, base, width, height, depth)
   case (RADICAL)
      call set_radical(tree, state, noad, style, base, width, height, depth)
   case (ACCENT)
      call set_accent(tree, state, noad, style, cramped, base, width, height, depth)
   case (FENCED)
      call set_fenced(tree, state, noad, style, cramped, base, width, height, depth)
   case default
      if (tree%list(noad) > 0_I4P .or. (tree%glyph(noad) == 0_I4P .and. tree%code(noad) == 0_I4P)) then
         block
            integer(I4P) :: inner !< First item of the list.

            call set_list(tree, state, tree%list(noad), style, cramped, base, width, height, depth, inner)
         endblock
      else
         char = .true.
         call set_char(state, tree%face(noad), tree%glyph(noad), tree%code(noad), style, size, width, height, depth, &
                       italic)
         if (tree%kind(noad) == OP .and. tree%face(noad) == MATH_FACE) then
            ! a big operator: centered on the axis (TeX's rule 13)
            shift_y = 0.5_R8P * (height - depth) - axis(size)
            call shift(state, first, state%n, 0.0_R8P, -shift_y)
            height = height - shift_y
            depth = depth + shift_y
         endif
      endif
   endselect
   if (tree%sup(noad) > 0_I4P .or. tree%sub(noad) > 0_I4P) then
      ! a big operator is a box for its scripts (TeX's rule 13 boxes it), its italic correction in its width
      if (char .and. tree%kind(noad) == OP .and. tree%face(noad) == MATH_FACE) then
         call set_scripts(tree, state, noad, style, cramped, base, .false., italic, width, height, depth, .true.)
      else
         call set_scripts(tree, state, noad, style, cramped, base, char, italic, width, height, depth, .false.)
      endif
   elseif (char .and. tree%face(noad) == MATH_FACE .and. .not. last) then
      width = width + italic
   endif
   endsubroutine set_noad

   pure subroutine set_char(state, face, glyph, code, style, size, width, height, depth, italic)
   !< A character in its face at `size`: in the math font its script alternate in script styles.
   type(box_state), intent(inout) :: state  !< Items.
   integer(I4P),    intent(in)    :: face   !< Face.
   integer(I4P),    intent(in)    :: glyph  !< Glyph.
   integer(I4P),    intent(in)    :: code   !< Character.
   integer(I4P),    intent(in)    :: style  !< Style.
   real(R8P),       intent(in)    :: size   !< Font size.
   real(R8P),       intent(out)   :: width  !< Advance.
   real(R8P),       intent(out)   :: height !< Height.
   real(R8P),       intent(out)   :: depth  !< Depth.
   real(R8P),       intent(out)   :: italic !< Italic correction.
   integer(I4P)                   :: g      !< Glyph drawn.

   g = glyph
   if (face == MATH_FACE .and. style > TEXT_STYLE) g = math_script_glyph(glyph, style - 1_I4P)
   call glyph_box(face, g, size, width, height, depth, italic)
   call add_glyph(state, face, g, code, 0.0_R8P, 0.0_R8P, size)
   endsubroutine set_char

   pure recursive subroutine set_scripts(tree, state, noad, style, cramped, base, char, italic, width, height, depth, &
                                    operator)
   !< The scripts of a set nucleus (its box `width` x `height` + `depth`, from its first item), TeX's rule 18 with the
   !< MATH constants of the nucleus' style; the box extended by them and the space after scripts.
   type(noad_tree), intent(inout) :: tree    !< Noads.
   type(box_state), intent(inout) :: state   !< Items.
   integer(I4P),    intent(in)    :: noad    !< Noad.
   integer(I4P),    intent(in)    :: style   !< Style of the nucleus.
   logical,         intent(in)    :: cramped !< Cramped.
   real(R8P),       intent(in)    :: base    !< Base size.
   logical,         intent(in)    :: char    !< The nucleus a character.
   real(R8P),       intent(in)    :: italic  !< Its italic correction.
   real(R8P),       intent(inout) :: width   !< Box width.
   real(R8P),       intent(inout) :: height  !< Height.
   real(R8P),       intent(inout) :: depth   !< Depth.
   logical,         intent(in)    :: operator !< A big operator: the subscript back by the italic correction.
   real(R8P)                      :: size    !< Font size of the nucleus' style.
   real(R8P)                      :: u       !< Superscript shift up.
   real(R8P)                      :: v       !< Subscript shift down.
   real(R8P)                      :: sw, sh, sd !< Superscript box.
   real(R8P)                      :: bw, bh, bd !< Subscript box.
   real(R8P)                      :: gap     !< Gap between them.
   integer(I4P)                   :: sfirst  !< Superscript's first item.
   integer(I4P)                   :: bfirst  !< Subscript's first item.
   integer(I4P)                   :: slast   !< Superscript's last item.
   integer(I4P)                   :: inner   !< Script style.
   real(R8P)                      :: delta   !< Italic correction before the superscript.
   real(R8P)                      :: back    !< The subscript's shift back.

   size = base * SCALE(style)
   inner = min(style + 1_I4P, SCRIPTSCRIPT_STYLE)
   if (char) then
      u = 0.0_R8P
      v = 0.0_R8P
   else
      u = height - em(MATH_SUPERSCRIPT_BASELINE_DROP_MAX, size)
      v = depth + em(MATH_SUBSCRIPT_BASELINE_DROP_MIN, size)
   endif
   sw = 0.0_R8P
   bw = 0.0_R8P
   delta = italic
   back = 0.0_R8P
   if (operator) then
      ! LuaTeX's OpenType operators: the superscript at the advance, the subscript back by the italic correction
      delta = 0.0_R8P
      back = italic
   endif
   sfirst = state%n + 1_I4P
   if (tree%sup(noad) > 0_I4P) call set_list(tree, state, tree%sup(noad), inner, cramped, base, sw, sh, sd, sfirst)
   slast = state%n
   bfirst = state%n + 1_I4P
   if (tree%sub(noad) > 0_I4P) call set_list(tree, state, tree%sub(noad), inner, .true., base, bw, bh, bd, bfirst)
   if (tree%sup(noad) == 0_I4P) then
      ! a subscript alone (rule 18b)
      v = max(v, em(MATH_SUBSCRIPT_SHIFT_DOWN, size), bh - em(MATH_SUBSCRIPT_TOP_MAX, size))
      call shift(state, bfirst, state%n, width - back, -v)
      depth = max(depth, bd + v)
      height = max(height, bh - v)
      width = width - back + bw
   else
      ! a superscript (rule 18c), with a subscript (18d, 18e)
      if (cramped) then
         u = max(u, em(MATH_SUPERSCRIPT_SHIFT_UP_CRAMPED, size))
      else
         u = max(u, em(MATH_SUPERSCRIPT_SHIFT_UP, size))
      endif
      u = max(u, sd + em(MATH_SUPERSCRIPT_BOTTOM_MIN, size))
      if (tree%sub(noad) > 0_I4P) then
         v = max(v, em(MATH_SUBSCRIPT_SHIFT_DOWN, size))
         gap = (u - sd) - (bh - v)
         if (gap < em(MATH_SUB_SUPERSCRIPT_GAP_MIN, size)) then
            v = v + em(MATH_SUB_SUPERSCRIPT_GAP_MIN, size) - gap
            gap = em(MATH_SUPERSCRIPT_BOTTOM_MAX_WITH_SUBSCRIPT, size) - (u - sd)
            if (gap > 0.0_R8P) then
               u = u + gap
               v = v - gap
            endif
         endif
         call shift(state, bfirst, state%n, width - back, -v)
         depth = max(depth, bd + v)
         height = max(height, bh - v)
      endif
      call shift(state, sfirst, slast, width + delta, u)
      height = max(height, sh + u)
      depth = max(depth, sd - u)
      width = max(width + delta + sw, width - back + bw)
   endif
   width = width + em(MATH_SPACE_AFTER_SCRIPT, size)
   endsubroutine set_scripts

   pure recursive subroutine set_fraction(tree, state, noad, style, cramped, base, width, height, depth)
   !< `\frac`: numerator and denominator one style smaller (the denominator cramped), TeX's rule 15 with the MATH
   !< constants, the rule on the axis, both centered, a null delimiter space on each side.
   type(noad_tree), intent(inout) :: tree    !< Noads.
   type(box_state), intent(inout) :: state   !< Items.
   integer(I4P),    intent(in)    :: noad    !< Noad.
   integer(I4P),    intent(in)    :: style   !< Style.
   logical,         intent(in)    :: cramped !< Cramped.
   real(R8P),       intent(in)    :: base    !< Base size.
   real(R8P),       intent(out)   :: width   !< Width.
   real(R8P),       intent(out)   :: height  !< Height.
   real(R8P),       intent(out)   :: depth   !< Depth.
   real(R8P)                      :: size    !< Font size.
   real(R8P)                      :: nw, nh, nd !< Numerator box.
   real(R8P)                      :: dw, dh, dd !< Denominator box.
   real(R8P)                      :: u       !< Numerator shift up.
   real(R8P)                      :: v       !< Denominator shift down.
   real(R8P)                      :: theta   !< Rule thickness.
   real(R8P)                      :: a       !< Axis height.
   real(R8P)                      :: inside  !< Content width.
   real(R8P)                      :: null    !< Null delimiter space.
   integer(I4P)                   :: nfirst  !< Numerator's first item.
   integer(I4P)                   :: dfirst  !< Denominator's first item.
   integer(I4P)                   :: nlast   !< Numerator's last item.
   integer(I4P)                   :: inner   !< Their style.

   size = base * SCALE(style)
   inner = min(style + 1_I4P, SCRIPTSCRIPT_STYLE)
   call set_list(tree, state, tree%list(noad), inner, cramped, base, nw, nh, nd, nfirst)
   nlast = state%n
   call set_list(tree, state, tree%other(noad), inner, .true., base, dw, dh, dd, dfirst)
   theta = em(MATH_FRACTION_RULE_THICKNESS, size)
   a = axis(size)
   u = em(MATH_FRACTION_NUMERATOR_SHIFT_UP, size)
   v = em(MATH_FRACTION_DENOMINATOR_SHIFT_DOWN, size)
   u = max(u, a + 0.5_R8P * theta + em(MATH_FRACTION_NUMERATOR_GAP_MIN, size) + nd)
   v = max(v, dh - (a - 0.5_R8P * theta) + em(MATH_FRACTION_DENOMINATOR_GAP_MIN, size))
   null = NULL_DELIMITER * base
   inside = max(nw, dw)
   call shift(state, nfirst, nlast, null + 0.5_R8P * (inside - nw), u)
   call shift(state, nlast + 1_I4P, state%n, null + 0.5_R8P * (inside - dw), -v)
   call add_rule(state, null, a - 0.5_R8P * theta, inside, theta)
   width = inside + 2.0_R8P * null
   height = nh + u
   depth = dd + v
   endsubroutine set_fraction

   pure recursive subroutine set_radical(tree, state, noad, style, base, width, height, depth)
   !< `\sqrt`: the body cramped, the radical's smallest size variant covering it (with the gap and the rule), the
   !< rule on the radical's top over the body (TeX's rule 11 with the MATH constants).
   type(noad_tree), intent(inout) :: tree   !< Noads.
   type(box_state), intent(inout) :: state  !< Items.
   integer(I4P),    intent(in)    :: noad   !< Noad.
   integer(I4P),    intent(in)    :: style  !< Style.
   real(R8P),       intent(in)    :: base   !< Base size.
   real(R8P),       intent(out)   :: width  !< Width.
   real(R8P),       intent(out)   :: height !< Height.
   real(R8P),       intent(out)   :: depth  !< Depth.
   real(R8P)                      :: size   !< Font size.
   real(R8P)                      :: bw, bh, bd !< Body box.
   real(R8P)                      :: rw, rh, rd, ri !< Radical glyph box.
   real(R8P)                      :: theta  !< Rule thickness.
   real(R8P)                      :: gap    !< Clearance.
   real(R8P)                      :: extra  !< The glyph's excess, half of it added to the clearance.
   real(R8P)                      :: shift_y !< The radical glyph's shift up.
   integer(I4P)                   :: bfirst !< Body's first item.
   integer(I4P)                   :: g      !< Radical glyph.
   integer(I4P)                   :: k      !< Variant.
   integer(I4P)                   :: rfirst !< Radical's item.

   size = base * SCALE(style)
   call set_list(tree, state, tree%list(noad), style, .true., base, bw, bh, bd, bfirst)
   theta = em(MATH_RADICAL_RULE_THICKNESS, size)
   gap = em(MATH_RADICAL_VERTICAL_GAP, size)
   g = tree%glyph(noad)
   if (style > TEXT_STYLE) g = math_script_glyph(g, style - 1_I4P)
   call glyph_box(MATH_FACE, g, size, rw, rh, rd, ri)
   k = 0_I4P
   do while (rh + rd < bh + bd + gap + theta)
      k = k + 1_I4P
      if (math_variant(tree%glyph(noad), k) == 0_I4P) exit
      g = math_variant(tree%glyph(noad), k)
      call glyph_box(MATH_FACE, g, size, rw, rh, rd, ri)
   enddo
   extra = (rh + rd) - (bh + bd + gap + theta)
   if (extra > 0.0_R8P) gap = gap + 0.5_R8P * extra
   ! the glyph's top at the body's height plus the gap and the rule
   shift_y = bh + gap + theta - rh
   rfirst = state%n + 1_I4P
   call shift(state, bfirst, state%n, rw, 0.0_R8P)
   call add_glyph(state, MATH_FACE, g, tree%code(noad), 0.0_R8P, shift_y, size)
   call add_rule(state, rw, bh + gap, bw, theta)
   width = rw + bw
   height = bh + gap + theta + em(MATH_RADICAL_EXTRA_ASCENDER, size)
   depth = max(bd, rd - shift_y)
   if (rfirst < 0_I4P) width = 0.0_R8P
   endsubroutine set_radical

   pure recursive subroutine set_accent(tree, state, noad, style, cramped, base, width, height, depth)
   !< An accent over its body: centered by the top accent attachments (the body's, else half its width; the accent's),
   !< raised by the body's height above the accent base height (TeX's rule 12).
   type(noad_tree), intent(inout) :: tree    !< Noads.
   type(box_state), intent(inout) :: state   !< Items.
   integer(I4P),    intent(in)    :: noad    !< Noad.
   integer(I4P),    intent(in)    :: style   !< Style.
   logical,         intent(in)    :: cramped !< Cramped.
   real(R8P),       intent(in)    :: base    !< Base size.
   real(R8P),       intent(out)   :: width   !< Width.
   real(R8P),       intent(out)   :: height  !< Height.
   real(R8P),       intent(out)   :: depth   !< Depth.
   real(R8P)                      :: size    !< Font size.
   real(R8P)                      :: aw, ah, ad, ai !< Accent glyph box.
   real(R8P)                      :: attach  !< The body's attachment.
   real(R8P)                      :: own     !< The accent's attachment.
   real(R8P)                      :: lift    !< The accent's shift up.
   integer(I4P)                   :: bfirst  !< Body's first item.
   integer(I4P)                   :: g       !< Accent glyph.
   integer(I4P)                   :: body    !< The body's glyph when one character, else 0.
   integer(I4P)                   :: first   !< The body's first noad.

   size = base * SCALE(style)
   call set_list(tree, state, tree%list(noad), style, .true., base, width, height, depth, bfirst)
   first = tree%list(noad)
   body = 0_I4P
   if (first > 0_I4P) then
      if (tree%next(first) == 0_I4P .and. tree%face(first) == MATH_FACE .and. tree%glyph(first) > 0_I4P .and. &
          tree%list(first) == 0_I4P) body = tree%glyph(first)
      if (body > 0_I4P .and. style > TEXT_STYLE) body = math_script_glyph(body, style - 1_I4P)
   endif
   attach = 0.5_R8P * width
   if (body > 0_I4P) then
      if (math_accent(body) /= -32768_I4P) attach = em(math_accent(body), size)
   endif
   g = tree%glyph(noad)
   if (style > TEXT_STYLE) g = math_script_glyph(g, style - 1_I4P)
   call glyph_box(MATH_FACE, g, size, aw, ah, ad, ai)
   own = 0.5_R8P * aw
   if (math_accent(g) /= -32768_I4P) own = em(math_accent(g), size)
   lift = max(0.0_R8P, height - em(MATH_ACCENT_BASE_HEIGHT, size))
   call add_glyph(state, MATH_FACE, g, tree%code(noad), attach - own, lift, size)
   height = max(height, ah + lift)
   if (cramped) height = height
   endsubroutine set_accent

   pure recursive subroutine set_fenced(tree, state, noad, style, cramped, base, width, height, depth)
   !< `\left` ... `\right`: the body between delimiters of the smallest size variant covering it around the axis
   !< (TeX's \delimiterfactor 901 and \delimitershortfall 5 pt), centered on the axis; an Inner atom.
   type(noad_tree), intent(inout) :: tree    !< Noads.
   type(box_state), intent(inout) :: state   !< Items.
   integer(I4P),    intent(in)    :: noad    !< Noad.
   integer(I4P),    intent(in)    :: style   !< Style.
   logical,         intent(in)    :: cramped !< Cramped.
   real(R8P),       intent(in)    :: base    !< Base size.
   real(R8P),       intent(out)   :: width   !< Width.
   real(R8P),       intent(out)   :: height  !< Height.
   real(R8P),       intent(out)   :: depth   !< Depth.
   real(R8P)                      :: size    !< Font size.
   real(R8P)                      :: bw, bh, bd !< Body box.
   real(R8P)                      :: need    !< Delimiter size needed.
   real(R8P)                      :: a       !< Axis height.
   integer(I4P)                   :: bfirst  !< Body's first item.
   integer(I4P)                   :: side    !< Left, right.
   real(R8P)                      :: dw, dh, dd, di !< Delimiter box.
   real(R8P)                      :: lift    !< Its shift up.
   integer(I4P)                   :: g       !< Delimiter glyph.
   integer(I4P)                   :: k       !< Variant.
   integer(I4P)                   :: dfirst  !< Its item.
   integer(I4P)                   :: blast   !< Body's last item.

   size = base * SCALE(style)
   a = axis(size)
   call set_list(tree, state, tree%list(noad), style, cramped, base, bw, bh, bd, bfirst)
   blast = state%n
   need = 2.0_R8P * max(bh - a, bd + a)
   need = max(need * 0.901_R8P, need - 0.5_R8P * base)
   width = 0.0_R8P
   height = bh
   depth = bd
   do side = 1_I4P, 2_I4P
      g = merge(tree%left(noad), tree%right(noad), side == 1_I4P)
      if (side == 2_I4P) call shift(state, bfirst, blast, width, 0.0_R8P)
      if (side == 2_I4P) width = width + bw
      if (g == 0_I4P) then
         width = width + NULL_DELIMITER * base
         cycle
      endif
      call glyph_box(MATH_FACE, g, size, dw, dh, dd, di)
      k = 0_I4P
      do while (dh + dd < need)
         k = k + 1_I4P
         if (math_variant(merge(tree%left(noad), tree%right(noad), side == 1_I4P), k) == 0_I4P) exit
         g = math_variant(merge(tree%left(noad), tree%right(noad), side == 1_I4P), k)
         call glyph_box(MATH_FACE, g, size, dw, dh, dd, di)
      enddo
      lift = a - 0.5_R8P * (dh - dd)
      dfirst = state%n + 1_I4P
      call add_glyph(state, MATH_FACE, g, math_unicode(g), width, lift, size)
      width = width + dw
      height = max(height, dh + lift)
      depth = max(depth, dd - lift)
   enddo
   endsubroutine set_fenced

   ! helpers
   pure subroutine binary_to_ordinary(tree, head)
   !< TeX's rules 5 and 6: a Bin first, or after Bin, Op, Rel, Open or Punct, or before Rel, Close or Punct, is an Ord.
   type(noad_tree), intent(inout) :: tree !< Noads.
   integer(I4P),    intent(in)    :: head !< First noad.
   integer(I4P)                   :: noad !< A noad.
   integer(I4P)                   :: previous !< The previous atom, 0 none.

   previous = 0_I4P
   noad = head
   do while (noad > 0_I4P)
      if (tree%kind(noad) /= SPACE) then
         if (tree%kind(noad) == BIN) then
            if (previous == 0_I4P) then
               tree%kind(noad) = ORD
            elseif (any(atom_kind(tree%kind(previous)) == [BIN, OP, REL, OPEN, PUNCT])) then
               tree%kind(noad) = ORD
            endif
         elseif (any(atom_kind(tree%kind(noad)) == [REL, CLOSE, PUNCT]) .and. previous > 0_I4P) then
            if (tree%kind(previous) == BIN) tree%kind(previous) = ORD
         endif
         previous = noad
      endif
      noad = tree%next(noad)
   enddo
   if (previous > 0_I4P) then
      if (tree%kind(previous) == BIN) tree%kind(previous) = ORD
   endif
   endsubroutine binary_to_ordinary

   elemental function atom_kind(kind) result(atom)
   !< The atom kind a noad spaces as: fractions, radicals and accents Ord (LaTeX's \frac a group), fenced lists Inner.
   integer(I4P), intent(in) :: kind !< Noad kind.
   integer(I4P)             :: atom !< Atom kind.

   select case (kind)
   case (FENCED)
      atom = INNER
   case (FRAC, RADICAL, ACCENT, SPACE)
      ! LaTeX's \frac is a group, {...\over...}: an Ord
      atom = ORD
   case default
      atom = kind
   endselect
   endfunction atom_kind

   pure subroutine glyph_box(face, glyph, size, width, height, depth, italic)
   !< The advance, height, depth and italic correction of a glyph at `size`.
   integer(I4P), intent(in)  :: face   !< Face.
   integer(I4P), intent(in)  :: glyph  !< Glyph.
   real(R8P),    intent(in)  :: size   !< Font size.
   real(R8P),    intent(out) :: width  !< Advance.
   real(R8P),    intent(out) :: height !< Height.
   real(R8P),    intent(out) :: depth  !< Depth.
   real(R8P),    intent(out) :: italic !< Italic correction.
   integer(I4P), allocatable :: ops(:) !< Outline operations.
   integer(I4P), allocatable :: pts(:) !< Outline points.
   integer(I4P)              :: k      !< Point.

   italic = 0.0_R8P
   if (face == MATH_FACE) then
      width = em(math_advance(glyph), size)
      height = max(0.0_R8P, em(math_ymax(glyph), size))
      depth = max(0.0_R8P, -em(math_ymin(glyph), size))
      italic = em(math_italic(glyph), size)
      return
   endif
   width = 0.0_R8P
   height = 0.0_R8P
   depth = 0.0_R8P
   if (glyph <= 0_I4P) return
   width = size * real(glyph_advance(face, glyph), R8P) / real(face_upm(face), R8P)
   call glyph_outline(face, glyph, ops, pts)
   do k = 2_I4P, size_of(pts), 2_I4P
      height = max(height, size * real(pts(k), R8P) / real(face_upm(face), R8P))
      depth = max(depth, -size * real(pts(k), R8P) / real(face_upm(face), R8P))
   enddo
   contains
      pure function size_of(a) result(n)
      !< Elements of `a`.
      integer(I4P), intent(in) :: a(:) !< Array.
      integer(I4P)             :: n    !< Elements.

      n = int(ubound(a, 1), I4P)
      endfunction size_of
   endsubroutine glyph_box

   pure function em(units, size) result(length)
   !< Font units of the math font at `size`.
   integer(I4P), intent(in) :: units  !< Font units.
   real(R8P),    intent(in) :: size   !< Font size.
   real(R8P)                :: length !< Length.

   length = size * real(units, R8P) / real(MATH_UPM, R8P)
   endfunction em

   pure function axis(size) result(height)
   !< The math axis at `size`.
   real(R8P), intent(in) :: size   !< Font size.
   real(R8P)             :: height !< Axis height.

   height = em(MATH_AXIS_HEIGHT, size)
   endfunction axis

   pure subroutine add_glyph(state, face, glyph, code, x, y, size)
   !< Append a glyph.
   type(box_state), intent(inout) :: state !< Items.
   integer(I4P),    intent(in)    :: face  !< Face.
   integer(I4P),    intent(in)    :: glyph !< Glyph.
   integer(I4P),    intent(in)    :: code  !< Character.
   real(R8P),       intent(in)    :: x     !< Abscissa.
   real(R8P),       intent(in)    :: y     !< Ordinate, up.
   real(R8P),       intent(in)    :: size  !< Font size.

   if (glyph <= 0_I4P) return
   state%n = state%n + 1_I4P
   state%items(state%n)%face = face
   state%items(state%n)%glyph = glyph
   state%items(state%n)%unicode = code
   if (face == MATH_FACE) state%items(state%n)%unicode = math_unicode(glyph)
   state%items(state%n)%x = x
   state%items(state%n)%y = y
   state%items(state%n)%size = size
   state%items(state%n)%height = 0.0_R8P
   endsubroutine add_glyph

   pure subroutine add_rule(state, x, y, width, thickness)
   !< Append a rule: its left, bottom, width and thickness.
   type(box_state), intent(inout) :: state     !< Items.
   real(R8P),       intent(in)    :: x         !< Left.
   real(R8P),       intent(in)    :: y         !< Bottom, up.
   real(R8P),       intent(in)    :: width     !< Width.
   real(R8P),       intent(in)    :: thickness !< Thickness.

   state%n = state%n + 1_I4P
   state%items(state%n)%face = 0_I4P
   state%items(state%n)%glyph = 0_I4P
   state%items(state%n)%unicode = 0_I4P
   state%items(state%n)%x = x
   state%items(state%n)%y = y
   state%items(state%n)%size = width
   state%items(state%n)%height = thickness
   endsubroutine add_rule

   pure subroutine shift(state, first, last, dx, dy)
   !< Move the items from `first` to `last`.
   type(box_state), intent(inout) :: state !< Items.
   integer(I4P),    intent(in)    :: first !< First item.
   integer(I4P),    intent(in)    :: last  !< Last item.
   real(R8P),       intent(in)    :: dx    !< Abscissa shift.
   real(R8P),       intent(in)    :: dy    !< Ordinate shift, up.
   integer(I4P)                   :: k     !< Item.

   do k = first, last
      state%items(k)%x = state%items(k)%x + dx
      state%items(k)%y = state%items(k)%y + dy
   enddo
   endsubroutine shift

   pure subroutine skip_blanks(source, at)
   !< Past the blanks at `at`.
   character(len=*), intent(in)    :: source !< Text.
   integer(I4P),     intent(inout) :: at     !< Position.

   do while (at <= len(source, kind=I4P))
      if (source(at:at) /= ' ') exit
      at = at + 1_I4P
   enddo
   endsubroutine skip_blanks

   pure function starts(source, at, word) result(yes)
   !< `source` has `word` at `at`.
   character(len=*), intent(in) :: source !< Text.
   integer(I4P),     intent(in) :: at     !< Position.
   character(len=*), intent(in) :: word   !< Word.
   logical                      :: yes    !< It has.

   yes = .false.
   if (at + len(word, kind=I4P) - 1_I4P > len(source, kind=I4P)) return
   yes = source(at:at + len(word, kind=I4P) - 1_I4P) == word
   endfunction starts

   elemental function is_letter(ch) result(yes)
   !< An ASCII letter.
   character(len=1), intent(in) :: ch  !< Character.
   logical                      :: yes !< A letter.

   yes = (ch >= 'a' .and. ch <= 'z') .or. (ch >= 'A' .and. ch <= 'Z')
   endfunction is_letter

   pure function word_number(words, word) result(k)
   !< The rank of `word` among the blank-separated `words`, 0 if absent.
   character(len=*), intent(in) :: words !< Words.
   character(len=*), intent(in) :: word  !< Word.
   integer(I4P)                 :: k     !< Rank.
   integer(I4P)                 :: j     !< Position.
   integer(I4P)                 :: e     !< Word end.
   integer(I4P)                 :: n     !< Words seen.

   k = 0_I4P
   n = 0_I4P
   j = 1_I4P
   do while (j <= len(words, kind=I4P))
      e = index(words(j:), ' ')
      if (e == 0) then
         e = len(words, kind=I4P) + 1_I4P
      else
         e = j + e - 1_I4P
      endif
      n = n + 1_I4P
      if (words(j:e - 1_I4P) == word) then
         k = n
         return
      endif
      j = e + 1_I4P
   enddo
   endfunction word_number

   pure subroutine utf8_code(text, at, code, n)
   !< The code point of the UTF-8 character at `at` and its bytes.
   character(len=*), intent(in)  :: text !< Text.
   integer(I4P),     intent(in)  :: at   !< Position.
   integer(I4P),     intent(out) :: code !< Code point.
   integer(I4P),     intent(out) :: n    !< Bytes.
   integer(I4P)                  :: b    !< First byte.
   integer(I4P)                  :: k    !< Byte.

   b = iachar(text(at:at))
   if (b < 128) then
      n = 1_I4P
      code = b
   elseif (b >= 240) then
      n = 4_I4P
      code = iand(b, 7)
   elseif (b >= 224) then
      n = 3_I4P
      code = iand(b, 15)
   elseif (b >= 192) then
      n = 2_I4P
      code = iand(b, 31)
   else
      n = 1_I4P
      code = b
      return
   endif
   if (at + n - 1_I4P > len(text, kind=I4P)) then
      n = 1_I4P
      code = b
      return
   endif
   do k = 1_I4P, n - 1_I4P
      code = code * 64_I4P + iand(iachar(text(at + k:at + k)), 63)
   enddo
   endsubroutine utf8_code
endmodule foresight_math
