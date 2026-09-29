!< foresight_tokens, lexer of the gnuplot-like command language.
module foresight_tokens
!< foresight_tokens, lexer of the gnuplot-like command language.
!<
!< A line is split into statements at `;` and cut at `#` (both outside quotes); a statement into tokens: words,
!< quoted strings (single quotes literal, double quotes with `\"` and `\\` escapes, as gnuplot), commas and bracketed
!< ranges `[a:b]`.
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
      select case (c)
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
         token%text = statement(i + 1_I4P:i + j - 1_I4P)
         i = i + j + 1_I4P
      case ('"')
         token%kind = TOKEN_STRING
         token%text = ''
         i = i + 1_I4P
         do
            if (i > n) then
               iostat = 1_I4P
               iomsg = 'unterminated string'
               return
            endif
            if (statement(i:i) == '"') exit
            if (statement(i:i) == '\' .and. i < n) i = i + 1_I4P
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
         j = i
         do while (j < n)
            if (scan(statement(j + 1_I4P:j + 1_I4P), ' ,['//achar(9)) > 0) exit
            j = j + 1_I4P
         enddo
         token%kind = TOKEN_WORD
         token%text = statement(i:j)
         i = j + 1_I4P
      endselect
      tokens = [tokens, token]
   enddo
   endsubroutine tokenize
endmodule foresight_tokens
