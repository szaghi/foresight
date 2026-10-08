!< foresight_tokens, lexer of the gnuplot-like command language.
module foresight_tokens
!< foresight_tokens, lexer of the gnuplot-like command language.
!<
!< A line is split into statements at `;` and cut at `#` (both outside quotes); a statement into tokens: words,
!< quoted strings (single quotes literal, double quotes with `\t` for a tab and `\` taking the next character literally,
!< so `\"` and `\\`, as gnuplot), commas and bracketed ranges `[a:b]`. Each token remembers where it lies in the
!< statement, so that a plot item can be quoted as written. Inside parentheses a word goes on across blanks and commas:
!< `($2 * 1e3)` and `atan2($2, $1)` are single words; quotes inside a word keep their content, blanks included, and a
!< quoted string followed by `:` starts a word: `1:"the res"` and `"it":"res"` are `using` specifications.
use penf, only : I4P

implicit none
private
public :: split_statements
public :: token_object
public :: tokenize
public :: TOKEN_COMMA, TOKEN_RANGE, TOKEN_STRING, TOKEN_WORD

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
   subroutine split_statements(line, statements)
   !< Split `line` at `;` outside quotes, dropping the `#` comment; blank statements are skipped.
   character(len=*),                intent(in)  :: line          !< Source line.
   type(token_object), allocatable, intent(out) :: statements(:) !< Statements (kind word).
   character(len=1)                             :: quote         !< Open quote, blank if none.
   integer(I4P)                                 :: i             !< Character counter.
   integer(I4P)                                 :: start         !< Current statement start.
   integer(I4P)                                 :: last          !< Last character of the code part.

   allocate(statements(0))
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
         case (';')
            call add(line(start:i - 1_I4P))
            start = i + 1_I4P
         endselect
      endif
      i = i + 1_I4P
   enddo
   call add(line(start:last))
   contains
      subroutine add(statement)
      !< Append a non-blank statement.
      character(len=*), intent(in) :: statement !< Statement.
      type(token_object)           :: token     !< New statement.

      if (len_trim(statement) == 0) return
      token%text = trim(adjustl(statement))
      statements = [statements, token]
      endsubroutine add
   endsubroutine split_statements

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
         if (j == 0_I4P) then
            iostat = 1_I4P
            iomsg = 'unterminated string'
            return
         endif
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
            if (i > n) then
               iostat = 1_I4P
               iomsg = 'unterminated string'
               return
            endif
            if (statement(i:i) == '"') exit
            if (statement(i:i) == '\' .and. i < n) then
               i = i + 1_I4P
               if (statement(i:i) == 't') then
                  token%text = token%text//achar(9)
                  i = i + 1_I4P
                  cycle
               endif
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
      tokens = [tokens, token]
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
endmodule foresight_tokens
