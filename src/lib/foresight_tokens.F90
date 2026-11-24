!< foresight_tokens, lexer of the gnuplot-like command language.
module foresight_tokens
!< foresight_tokens, lexer of the gnuplot-like command language.
!<
!< A line is split into statements at `;` and cut at `#` (both outside quotes); a statement into tokens: words,
!< quoted strings (single quotes literal, double quotes with `\t` for a tab, `\n` for a new line and `\` taking the
!< next character literally, so `\"` and `\\`, as gnuplot), commas and bracketed ranges `[a:b]`. Each token remembers
!< where it lies in the statement, so that a plot item can be quoted as written. Inside parentheses a word goes on
!< across blanks and commas: `($2 * 1e3)` and `atan2($2, $1)` are single words; quotes inside a word keep their
!< content, blanks included, and a quoted string followed by `:` starts a word: `1:"the res"` and `"it":"res"` are
!< `using` specifications.
use penf, only : I4P

implicit none
private
public :: brace_balance
public :: split_statements
public :: strip_comment
public :: token_object
public :: tokenize
public :: TOKEN_COMMA, TOKEN_RANGE, TOKEN_STRING, TOKEN_WORD
public :: gnuplot_escape
public :: UNAME_CHARS, UNAME_START
public :: push

interface push
   !< Append an item through a temporary: nvfortran 26.9 corrupts `list = [list, item]` (and any `list = f(list)`)
   !< when the items hold deferred-length characters.
   module procedure push_token
endinterface push

integer :: k_ !< Implied-do variable of the parameters below.
character(len=128), parameter :: HIGH_BYTES = transfer([(char(k_), k_ = 128, 255)], repeat(' ', 128)) !< Bytes 128-255.
!> The first character of a user name: a letter, `_`, or a byte of a UTF-8 character (gnuplot's `π = pi`).
character(len=*), parameter :: UNAME_START = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_'//HIGH_BYTES
character(len=*), parameter :: UNAME_CHARS = UNAME_START//'0123456789' !< The characters of a user name.
integer(I4P), parameter :: TOKEN_WORD   = 1_I4P !< Bare word: keyword, number, column spec.
integer(I4P), parameter :: TOKEN_STRING = 2_I4P !< Quoted string, quotes removed.
integer(I4P), parameter :: TOKEN_COMMA  = 3_I4P !< Comma.
integer(I4P), parameter :: TOKEN_RANGE  = 4_I4P !< Bracketed range, brackets removed.

type :: token_object
   !< Token.
   integer(I4P)                  :: kind = TOKEN_WORD !< Token kind.
   character(len=:), allocatable :: text              !< Token text.
   character(len=1)              :: quote = ' '       !< Quote of a string token, blank for others.
   integer(I4P)                  :: first = 0_I4P     !< First character in the statement, quotes or brackets included.
   integer(I4P)                  :: last  = 0_I4P     !< Last character in the statement.
endtype token_object

contains
   pure subroutine gnuplot_escape(src, pos, text)
   !< gnuplot's escape (parse_esc) in a double-quoted string, `src(pos:pos)` the character after the backslash, appended
   !< to `text`, `pos` then after it: \n, \t and \r; octal \ooo a byte (up to 4 digits after a 0, else 3); \U+ kept
   !< with its backslash for the enhanced text; another character as it is (\\ a backslash, \" a quote).
   character(len=*),              intent(in)    :: src  !< Text.
   integer(I4P),                  intent(inout) :: pos  !< Escaped character, then the next one.
   character(len=:), allocatable, intent(inout) :: text !< Text read.
   integer(I4P)                                 :: digits !< Octal digits read.
   integer(I4P)                                 :: limit  !< Most octal digits.
   integer(I4P)                                 :: code   !< Their value.
   character(len=1)                             :: byte   !< The octal byte (a variable: nvfortran 26.9 misreads
                                                          !< achar of a variable in a concatenation).

   select case (src(pos:pos))
   case ('n')
      text = text//achar(10)
   case ('t')
      text = text//achar(9)
   case ('r')
      text = text//achar(13)
   case ('0':'7')
      digits = 0_I4P
      code = 0_I4P
      limit = 3_I4P
      if (src(pos:pos) == '0') limit = 4_I4P
      do while (digits < limit)
         if (pos > len(src, kind=I4P)) exit
         if (scan(src(pos:pos), '01234567') == 0) exit
         code = 8_I4P * code + (iachar(src(pos:pos), kind=I4P) - 48_I4P)
         digits = digits + 1_I4P
         pos = pos + 1_I4P
      enddo
      byte = achar(mod(code, 256_I4P))
      text = text//byte
      return
   case ('U')
      if (pos < len(src, kind=I4P)) then
         if (src(pos + 1_I4P:pos + 1_I4P) == '+') text = text//'\'
      endif
      text = text//src(pos:pos)
   case default
      text = text//src(pos:pos)
   endselect
   pos = pos + 1_I4P
   endsubroutine gnuplot_escape

   subroutine split_statements(line, statements)
   !< Split `line` at `;` (and new lines) outside quotes and braces, dropping the `#` comment; blank statements are
   !< skipped. A block `do for [...] { ...; ... }` is one statement. Each statement's `first` and `last` are its
   !< characters in `line` (whether two are on the same line).
   character(len=*),                intent(in)  :: line          !< Source line.
   type(token_object), allocatable, intent(out) :: statements(:) !< Statements (kind word).
   character(len=1)                             :: quote         !< Open quote, blank if none.
   integer(I4P)                                 :: i             !< Character counter.
   integer(I4P)                                 :: start         !< Current statement start.
   integer(I4P)                                 :: last          !< Last character of the code part.
   integer(I4P)                                 :: depth         !< Brace depth.

   allocate(statements(0))
   depth = 0_I4P
   quote = ' '
   start = 1_I4P
   last = len(line, kind=I4P)
   i = 1_I4P
   do while (i <= last)
      if (quote /= ' ') then
         if (quote == '"' .and. line(i:i) == '\') then
            i = i + 1_I4P
         elseif (line(i:i) == quote) then
            quote = ' '
         endif
      else
         select case (line(i:i))
         case ('"', "'")
            quote = line(i:i)
         case ('#')
            last = i - 1_I4P
            exit
         case ('{')
            depth = depth + 1_I4P
         case ('}')
            depth = max(0_I4P, depth - 1_I4P)
         case (';', achar(10))
            if (depth == 0_I4P) then
               call add(line(start:i - 1_I4P), start)
               start = i + 1_I4P
            endif
         endselect
      endif
      i = i + 1_I4P
   enddo
   call add(line(start:last), start)
   contains
      subroutine add(statement, offset)
      !< Append a non-blank statement, starting at character `offset` of the line.
      character(len=*), intent(in) :: statement !< Statement.
      integer(I4P),     intent(in) :: offset    !< Its first character in the line.
      type(token_object)           :: token     !< New statement.
      integer(I4P)                 :: first     !< First character kept.
      integer(I4P)                 :: last      !< Last character kept.

      ! blanks, tabs and line ends around the statement removed (a block's body spans lines)
      first = verify(statement, ' '//achar(9)//achar(10)//achar(13), kind=I4P)
      if (first == 0_I4P) return
      last = verify(statement, ' '//achar(9)//achar(10)//achar(13), back=.true., kind=I4P)
      token%text = statement(first:last)
      token%first = offset + first - 1_I4P
      token%last = offset + last - 1_I4P
      call push(statements, token)
      endsubroutine add
   endsubroutine split_statements

   pure function strip_comment(line) result(code)
   !< `line` without its `#` comment (a `#` outside quotes).
   character(len=*), intent(in)  :: line  !< Line.
   character(len=:), allocatable :: code  !< Code part.
   character(len=1)              :: quote !< Open quote, blank if none.
   integer(I4P)                  :: i     !< Character counter.

   quote = ' '
   code = line
   i = 1_I4P
   do while (i <= len(line, kind=I4P))
      if (quote /= ' ') then
         if (quote == '"' .and. line(i:i) == '\') then
            i = i + 1_I4P
         elseif (line(i:i) == quote) then
            quote = ' '
         endif
      elseif (line(i:i) == '"' .or. line(i:i) == "'") then
         quote = line(i:i)
      elseif (line(i:i) == '#') then
         code = line(1:i - 1_I4P)
         return
      endif
      i = i + 1_I4P
   enddo
   endfunction strip_comment

   pure function brace_balance(code) result(balance)
   !< Braces opened minus closed in `code` (no comment), outside quotes: a block goes on while it is positive.
   character(len=*), intent(in) :: code    !< Code.
   integer(I4P)                 :: balance !< Open braces.
   character(len=1)             :: quote   !< Open quote, blank if none.
   integer(I4P)                 :: i       !< Character counter.

   balance = 0_I4P
   quote = ' '
   i = 1_I4P
   do while (i <= len(code, kind=I4P))
      if (quote /= ' ') then
         if (quote == '"' .and. code(i:i) == '\') then
            i = i + 1_I4P
         elseif (code(i:i) == quote) then
            quote = ' '
         endif
      elseif (code(i:i) == '"' .or. code(i:i) == "'") then
         quote = code(i:i)
      elseif (code(i:i) == '{') then
         balance = balance + 1_I4P
      elseif (code(i:i) == '}') then
         balance = balance - 1_I4P
      endif
      i = i + 1_I4P
   enddo
   endfunction brace_balance

   pure subroutine tokenize(statement, tokens, iostat, iomsg)
   !< Split `statement` into tokens.
   character(len=*),                intent(in)  :: statement !< Statement.
   type(token_object), allocatable, intent(out) :: tokens(:) !< Tokens.
   integer(I4P),                    intent(out) :: iostat    !< 0, or 1 on a lexical error.
   character(len=:), allocatable,   intent(out) :: iomsg     !< Error message.
   type(token_object)                           :: token     !< Token being built.
   character(len=1)                             :: c         !< Current character.
   integer(I4P)                                 :: i         !< Character counter.
   integer(I4P)                                 :: j         !< End of the token.
   integer(I4P)                                 :: n         !< Statement length.
   integer(I4P)                                 :: depth     !< Parenthesis depth in a word.
   character(len=1)                             :: quote     !< Open quote in a word, blank if none.
   character(len=1)                             :: lead      !< First character, `w` for a word glued to a string.

   allocate(tokens(0))
   iostat = 0_I4P
   iomsg = ''
   n = len(statement, kind=I4P)
   i = 1_I4P
   do while (i <= n)
      c = statement(i:i)
      if (c == ' ' .or. c == achar(9)) then
         i = i + 1_I4P
         cycle
      endif
      token%quote = ' '
      token%first = i
      lead = c
      if (c == '"' .or. c == "'") then
         ! a string glued to a `:` is part of a using specification
         j = closing_quote(i)
         if (j > 0_I4P .and. j < n) then
            if (statement(j + 1_I4P:j + 1_I4P) == ':') lead = 'w'
         endif
      endif
      select case (lead)
      case (',')
         token%kind = TOKEN_COMMA
         token%text = ','
         i = i + 1_I4P
      case ("'")
         j = index(statement(i + 1_I4P:), "'", kind=I4P)
         ! unterminated: the string ends with the line, as gnuplot's scanner closes it
         if (j == 0_I4P) j = n - i + 1_I4P
         token%kind = TOKEN_STRING
         token%quote = c
         token%text = statement(i + 1_I4P:i + j - 1_I4P)
         i = i + j + 1_I4P
      case ('"')
         token%kind = TOKEN_STRING
         token%quote = c
         token%text = ''
         i = i + 1_I4P
         do
            ! unterminated: the string ends with the line, as gnuplot's scanner closes it
            if (i > n) exit
            if (statement(i:i) == '"') exit
            if (statement(i:i) == '\' .and. i < n) then
               i = i + 1_I4P
               call gnuplot_escape(statement, i, token%text)
               cycle
            endif
            token%text = token%text//statement(i:i)
            i = i + 1_I4P
         enddo
         i = i + 1_I4P
      case ('[')
         j = index(statement(i + 1_I4P:), ']', kind=I4P)
         if (j == 0_I4P) then
            iostat = 1_I4P
            iomsg = 'unterminated range "["'
            return
         endif
         token%kind = TOKEN_RANGE
         token%text = trim(adjustl(statement(i + 1_I4P:i + j - 1_I4P)))
         i = i + j + 1_I4P
      case default
         ! up to a blank, comma or `[` outside parentheses and quotes
         j = i
         depth = 0_I4P
         quote = ' '
         do
            if (quote /= ' ') then
               if (quote == '"' .and. statement(j:j) == '\' .and. j < n) then
                  j = j + 1_I4P
               elseif (statement(j:j) == quote) then
                  quote = ' '
               endif
            elseif (statement(j:j) == '"' .or. statement(j:j) == "'") then
               quote = statement(j:j)
            elseif (statement(j:j) == '{' .and. complex_end(j) > 0_I4P) then
               ! a complex constant, gnuplot's {re, im}: its comma inside the word
               j = complex_end(j)
            else
               depth = count_parentheses(statement(j:j), depth)
            endif
            if (j >= n) exit
            if (quote == ' ' .and. depth == 0_I4P .and. scan(statement(j + 1_I4P:j + 1_I4P), ' ,['//achar(9)) > 0) exit
            j = j + 1_I4P
         enddo
         token%kind = TOKEN_WORD
         token%text = statement(i:j)
         i = j + 1_I4P
      endselect
      token%last = i - 1_I4P
      call push(tokens, token)
   enddo
   contains
      pure function closing_quote(open) result(close)
      !< Position of the quote closing the one at `open`, 0 if none; in double quotes `\` escapes the next character.
      integer(I4P), intent(in) :: open  !< Opening quote position.
      integer(I4P)             :: close !< Closing quote position.

      close = open + 1_I4P
      do while (close <= n)
         if (statement(open:open) == '"' .and. statement(close:close) == '\') then
            close = close + 2_I4P
            cycle
         endif
         if (statement(close:close) == statement(open:open)) return
         close = close + 1_I4P
      enddo
      close = 0_I4P
      endfunction closing_quote

      pure function complex_end(open) result(close)
      !< Position of the `}` ending a complex constant `{re, im}` (two signed numbers) opened at `open`, 0 if none.
      integer(I4P), intent(in) :: open  !< Opening brace position.
      integer(I4P)             :: close !< Closing brace position.
      integer(I4P)             :: comma !< Its comma.

      close = 0_I4P
      comma = index(statement(open + 1_I4P:), ',', kind=I4P)
      if (comma == 0_I4P) return
      comma = open + comma
      close = index(statement(comma + 1_I4P:), '}', kind=I4P)
      if (close == 0_I4P) return
      close = comma + close
      if (.not. (is_number(statement(open + 1_I4P:comma - 1_I4P)) .and. is_number(statement(comma + 1_I4P:close - 1_I4P)))) &
         close = 0_I4P
      endfunction complex_end

      pure function is_number(text) result(yes)
      !< Whether `text` (blanks around) is a signed decimal number.
      character(len=*), intent(in)  :: text !< Text.
      logical                       :: yes  !< A number.
      character(len=:), allocatable :: t    !< Text, trimmed.

      t = trim(adjustl(text))
      yes = len(t) > 0
      if (.not. yes) return
      if (scan(t(1:1), '+-') > 0) t = t(2:)
      yes = len(t) > 0
      if (yes) yes = verify(t, '0123456789.eE+-') == 0 .and. scan(t(1:1), '0123456789.') > 0
      endfunction is_number

      pure function count_parentheses(c, depth) result(new_depth)
      !< Parenthesis depth after character `c`.
      character(len=1), intent(in) :: c         !< Character.
      integer(I4P),     intent(in) :: depth     !< Depth before.
      integer(I4P)                 :: new_depth !< Depth after.

      new_depth = depth
      if (c == '(') new_depth = depth + 1_I4P
      if (c == ')') new_depth = max(0_I4P, depth - 1_I4P)
      endfunction count_parentheses
   endsubroutine tokenize

   pure subroutine push_token(list, item)
   !< Append `item` to `list` (an unallocated `list` is empty), through a temporary: see `push`.
   type(token_object), allocatable, intent(inout) :: list(:)  !< List.
   type(token_object),              intent(in)    :: item     !< New item.
   type(token_object), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                   :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_token
endmodule foresight_tokens
