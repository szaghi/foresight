!< foresight_expression, arithmetic expressions of gnuplot `using` fields and plotted functions.
module foresight_expression
!< foresight_expression, arithmetic expressions of gnuplot `using` fields and plotted functions.
!<
!< An expression such as `($2*1e3)` or `($3 > 0 ? log10($3) : 1/0)` is compiled once into stack code and evaluated on
!< each data row; compiled with a dummy variable, `sin(x)/x` is a function evaluated at sample abscissae (`value_at`),
!< where columns are errors. The semantics are gnuplot's:
!<
!< - operators, loosest first: `?:`, `||`, `&&`, `== !=`, `< <= > >=`, `+ -`, `* / %`, unary `- + !`, `**` (right
!<   associative, so `-2**2` is -4 and `2**3**2` is 512); `&&`, `||` and `?:` evaluate only what they need;
!< - operands: numbers, `$N` and `column(N)` (column N of the row, 0 is the point number), `column("name")` (the column
!<   of that header, see `resolve`), `pi`, and the functions
!<   `abs acos asin atan atan2 ceil cos cosh exp floor int log log10 sgn sin sinh sqrt tan tanh`;
!< - integer constants are integers: `1/2` is 0, `-5/2` is -2, `7/2.` is 3.5; an integer overflow gives a real;
!<   columns are real; `floor`, `ceil`, `int`, `sgn`, comparisons and logical operators give integers;
!< - a missing cell, a division by zero, a domain error (`sqrt(-1)`, `log(0)`) or an overflow make the whole value
!<   undefined: NaN, a gap in the plot, as gnuplot's `1/0`.
!<
!< Accepted beyond gnuplot: `%` and the logical operators on reals (gnuplot rejects them), and overflows give a gap
!< where gnuplot stops the plot. Every floating point operation is checked beforehand, so evaluation never raises an
!< IEEE invalid, division by zero or overflow exception.
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan, ieee_quiet_nan, ieee_value
use foresight_format, only : real_from_decimal
use penf, only : I4P, I8P, R8P

implicit none
private
public :: expression_object

! operation codes
integer(I4P), parameter :: OP_CONSTANT    = 1_I4P  !< Push the constant.
integer(I4P), parameter :: OP_COLUMN      = 2_I4P  !< Push column `arg`.
integer(I4P), parameter :: OP_COLUMN_OF   = 3_I4P  !< Replace the top with the column it numbers.
integer(I4P), parameter :: OP_NEGATE      = 4_I4P  !< Unary minus.
integer(I4P), parameter :: OP_NOT         = 5_I4P  !< Logical not.
integer(I4P), parameter :: OP_TRUTH       = 6_I4P  !< Replace the top with 0 or 1.
integer(I4P), parameter :: OP_ADD         = 7_I4P  !< `+`; binary operators run from here to OP_NE.
integer(I4P), parameter :: OP_SUBTRACT    = 8_I4P  !< `-`.
integer(I4P), parameter :: OP_MULTIPLY    = 9_I4P  !< `*`.
integer(I4P), parameter :: OP_DIVIDE      = 10_I4P !< `/`.
integer(I4P), parameter :: OP_MODULO      = 11_I4P !< `%`.
integer(I4P), parameter :: OP_POWER       = 12_I4P !< `**`.
integer(I4P), parameter :: OP_ATAN2       = 13_I4P !< `atan2(y, x)`.
integer(I4P), parameter :: OP_LT          = 14_I4P !< `<`.
integer(I4P), parameter :: OP_LE          = 15_I4P !< `<=`.
integer(I4P), parameter :: OP_GT          = 16_I4P !< `>`.
integer(I4P), parameter :: OP_GE          = 17_I4P !< `>=`.
integer(I4P), parameter :: OP_EQ          = 18_I4P !< `==`.
integer(I4P), parameter :: OP_NE          = 19_I4P !< `!=`.
integer(I4P), parameter :: OP_FUNCTION    = 20_I4P !< Function `arg` of the top.
integer(I4P), parameter :: OP_JUMP        = 21_I4P !< Jump to `arg`.
integer(I4P), parameter :: OP_JUMP_UNLESS = 22_I4P !< Pop; jump to `arg` if false.
integer(I4P), parameter :: OP_AND_JUMP    = 23_I4P !< If the top is false: make it 0, jump to `arg`; else pop.
integer(I4P), parameter :: OP_OR_JUMP     = 24_I4P !< If the top is true: make it 1, jump to `arg`; else pop.
integer(I4P), parameter :: OP_COLUMN_NAMED = 25_I4P !< Push the column of header `names(arg)`: undefined until resolved.

! one-argument functions, the `OP_FUNCTION` argument is the index
character(len=*), parameter :: FUNCTIONS(18) = [character(len=5) :: 'abs', 'acos', 'asin', 'atan', 'ceil', 'cos', &
                                                'cosh', 'exp', 'floor', 'int', 'log', 'log10', 'sgn', 'sin', 'sinh', &
                                                'sqrt', 'tan', 'tanh']

! binary operator levels of the grammar, loosest first
character(len=*), parameter :: LEVELS(6) = [character(len=11) :: '||', '&&', '== !=', '< <= > >=', '+ -', '* / %']

integer(I4P), parameter :: MAX_NESTING = 256_I4P                     !< Deepest parentheses and unary chains.
integer(I8P), parameter :: MOST        = huge(1_I8P)                 !< Largest integer.
integer(I8P), parameter :: LEAST       = -MOST - 1_I8P               !< Smallest integer.
real(R8P),    parameter :: HUGE_REAL   = huge(1.0_R8P)               !< Largest real.
real(R8P),    parameter :: LOG_HUGE    = log(HUGE_REAL) - 1.0e-6_R8P !< Largest safe `exp` argument.
real(R8P),    parameter :: LOG_TINY    = -745.0_R8P                  !< `exp` of less is 0.
real(R8P),    parameter :: INT_LIMIT   = 2.0_R8P**63                 !< Reals from here on are not I8P integers.
real(R8P),    parameter :: PI          = acos(-1.0_R8P)              !< pi.

type :: value_object
   !< Stack value: an integer or a real, as in gnuplot.
   real(R8P)    :: r      = 0.0_R8P !< Real value.
   integer(I8P) :: i      = 0_I8P   !< Integer value.
   logical      :: is_int = .false. !< Integer.
endtype value_object

type :: instruction_object
   !< Stack code instruction.
   integer(I4P)       :: op  = OP_CONSTANT !< Operation code.
   integer(I4P)       :: arg = 0_I4P       !< Column, function or jump target.
   type(value_object) :: v                 !< Constant.
endtype instruction_object

type :: name_object
   !< Column header name.
   character(len=:), allocatable :: text !< Name.
endtype name_object

type :: expression_object
   !< Compiled expression.
   character(len=:),         allocatable :: text          !< Source text.
   type(instruction_object), allocatable :: code(:)       !< Stack code.
   type(name_object),        allocatable :: names(:)      !< Column header names, `column("name")`.
   integer(I4P)                          :: depth = 0_I4P !< Stack size needed.
   contains
      procedure, pass(self) :: compile      !< Compile an expression.
      procedure, pass(self) :: evaluate     !< Value on a data row.
      procedure, pass(self) :: first_column !< First data column read.
      procedure, pass(self) :: name_count   !< Number of column header names.
      procedure, pass(self) :: name_of      !< A column header name.
      procedure, pass(self) :: resolve      !< Header names to column numbers.
      procedure, pass(self) :: set_column   !< Plain column.
      procedure, pass(self) :: set_name     !< Plain column of a header name.
      procedure, pass(self) :: value_at     !< Value of a function at its variable value.
endtype expression_object

contains
   subroutine compile(self, text, iostat, iomsg, variable)
   !< Compile `text`; on error `iostat` is not 0 and `iomsg` names the problem and its position.
   !<
   !< With `variable` (gnuplot's dummy `x`) the expression is a function of it, evaluated by `value_at`; columns are
   !< then errors. The variable is held as the only cell of the row `evaluate` receives.
   class(expression_object),      intent(inout)        :: self     !< Expression.
   character(len=*),              intent(in)           :: text     !< Source text.
   integer(I4P),                  intent(out)          :: iostat   !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg    !< Error message.
   character(len=*),              intent(in), optional :: variable !< Dummy variable name, for a function.
   integer(I4P), parameter                      :: T_END = 0_I4P      !< End of text.
   integer(I4P), parameter                      :: T_NUMBER = 1_I4P   !< Number.
   integer(I4P), parameter                      :: T_COLUMN = 2_I4P   !< `$N`.
   integer(I4P), parameter                      :: T_NAME = 3_I4P     !< Constant or function name.
   integer(I4P), parameter                      :: T_OPERATOR = 4_I4P !< Operator or punctuation.
   integer(I4P), parameter                      :: T_STRING = 5_I4P   !< Quoted string, quotes removed.
   character(len=:), allocatable                :: token   !< Current token text.
   type(value_object)                           :: number  !< Current number or column token value.
   integer(I4P)                                 :: kind    !< Current token kind.
   integer(I4P)                                 :: start   !< Current token start.
   integer(I4P)                                 :: pos     !< Next character.
   integer(I4P)                                 :: depth   !< Current stack depth.
   integer(I4P)                                 :: nesting !< Current recursion depth.

   self%text = text
   if (allocated(self%code)) deallocate(self%code)
   allocate(self%code(0))
   if (allocated(self%names)) deallocate(self%names)
   allocate(self%names(0))
   self%depth = 0_I4P
   iostat = 0_I4P
   iomsg = ''
   pos = 1_I4P
   depth = 0_I4P
   nesting = 0_I4P
   call next
   call parse_ternary
   if (iostat == 0_I4P .and. kind /= T_END) call syntax('unexpected "'//token//'"')
   contains
      subroutine syntax(message, at)
      !< Record the first syntax error, at the current token or at `at`.
      character(len=*), intent(in)           :: message !< Error.
      integer(I4P),     intent(in), optional :: at      !< Position.
      character(len=12)                      :: column  !< Position text.

      if (iostat /= 0_I4P) return
      iostat = 1_I4P
      if (present(at)) then
         write(column, '(I0)') at
      else
         write(column, '(I0)') start
      endif
      iomsg = message//' at character '//trim(column)//' of "'//text//'"'
      endsubroutine syntax

      subroutine next
      !< Read the next token.
      character(len=*), parameter :: DIGITS = '0123456789'
      character(len=*), parameter :: LETTERS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_'
      integer(I4P)                :: n       !< Text length.
      integer(I4P)                :: ios     !< Conversion status.
      logical                     :: is_real !< Number with a point or an exponent.
      logical                     :: ok      !< Real conversion succeeded.
      integer(I4P)                :: close   !< Closing quote, from the opening one.

      if (iostat /= 0_I4P) return
      n = len(text, kind=I4P)
      do while (pos <= n)
         if (text(pos:pos) /= ' ' .and. text(pos:pos) /= achar(9)) exit
         pos = pos + 1_I4P
      enddo
      start = pos
      if (pos > n) then
         kind = T_END
         token = 'end'
         return
      endif
      if (scan(text(pos:pos), DIGITS) > 0 .or. (text(pos:pos) == '.' .and. next_is(DIGITS, 1_I4P))) then
         kind = T_NUMBER
         is_real = .false.
         call skip(DIGITS)
         if (next_is('.', 0_I4P)) then
            is_real = .true.
            pos = pos + 1_I4P
            call skip(DIGITS)
         endif
         if (next_is('eE', 0_I4P)) then
            is_real = .true.
            pos = pos + 1_I4P
            if (next_is('+-', 0_I4P)) pos = pos + 1_I4P
            if (.not. next_is(DIGITS, 0_I4P)) then
               call syntax('malformed number')
               return
            endif
            call skip(DIGITS)
         endif
         token = text(start:pos - 1_I4P)
         number = value_object()
         ios = 1_I4P
         if (.not. is_real) then
            ! integers too large for I8P are reals, as in gnuplot
            read(token, *, iostat=ios) number%i
            number%is_int = ios == 0_I4P
         endif
         if (ios /= 0_I4P) then
            ! the token is a well formed number: only an overflow fails
            call real_from_decimal(token, number%r, ok)
            if (.not. ok) call syntax('number out of range')
         endif
      elseif (text(pos:pos) == '$') then
         kind = T_COLUMN
         pos = pos + 1_I4P
         if (.not. next_is(DIGITS, 0_I4P)) then
            call syntax('"$" needs a column number')
            return
         endif
         call skip(DIGITS)
         token = text(start:pos - 1_I4P)
         number = value_object(is_int=.true.)
         read(token(2:), *, iostat=ios) number%i
         if (ios /= 0_I4P .or. number%i > huge(1_I4P)) call syntax('column number too large')
      elseif (text(pos:pos) == '"' .or. text(pos:pos) == "'") then
         kind = T_STRING
         close = index(text(pos + 1_I4P:), text(pos:pos), kind=I4P)
         if (close == 0_I4P) then
            call syntax('unterminated string')
            return
         endif
         token = text(pos + 1_I4P:pos + close - 1_I4P)
         pos = pos + close + 1_I4P
      elseif (scan(text(pos:pos), LETTERS) > 0) then
         kind = T_NAME
         call skip(LETTERS//DIGITS)
         token = text(start:pos - 1_I4P)
      else
         kind = T_OPERATOR
         token = text(pos:min(pos + 1_I4P, n))
         select case (token)
         case ('**', '<=', '>=', '==', '!=', '&&', '||')
            pos = pos + 2_I4P
         case default
            token = text(pos:pos)
            pos = pos + 1_I4P
            select case (token)
            case ('+', '-', '*', '/', '%', '!', '<', '>', '?', ':', '(', ')', ',')
            case ('&', '|', '^', '~')
               call syntax('bitwise operator "'//token//'" not supported')
            case default
               call syntax('unexpected "'//token//'"')
            endselect
         endselect
      endif
      endsubroutine next

      function next_is(set, offset) result(yes)
      !< Whether the character `offset` places after `pos` is in `set`.
      character(len=*), intent(in) :: set    !< Characters.
      integer(I4P),     intent(in) :: offset !< Offset from `pos`.
      logical                      :: yes    !< Character in `set`.

      yes = .false.
      if (pos + offset <= len(text)) yes = scan(text(pos + offset:pos + offset), set) > 0
      endfunction next_is

      subroutine skip(set)
      !< Advance `pos` over characters of `set`.
      character(len=*), intent(in) :: set !< Characters.

      do while (pos <= len(text))
         if (scan(text(pos:pos), set) == 0) exit
         pos = pos + 1_I4P
      enddo
      endsubroutine skip

      subroutine emit(op, arg, v, k)
      !< Append an instruction, tracking the stack depth; `k` is its index, for jump patching.
      integer(I4P),       intent(in)            :: op          !< Operation code.
      integer(I4P),       intent(in),  optional :: arg         !< Argument.
      type(value_object), intent(in),  optional :: v           !< Constant.
      integer(I4P),       intent(out), optional :: k           !< Instruction index.
      type(instruction_object)                  :: instruction !< New instruction.

      instruction%op = op
      if (present(arg)) instruction%arg = arg
      if (present(v)) instruction%v = v
      self%code = [self%code, instruction]
      if (present(k)) k = size(self%code, kind=I4P)
      select case (op)
      case (OP_CONSTANT, OP_COLUMN, OP_COLUMN_NAMED)
         depth = depth + 1_I4P
      case (OP_ADD:OP_NE, OP_JUMP_UNLESS, OP_AND_JUMP, OP_OR_JUMP)
         ! the conditional jumps pop on the path that falls through
         depth = depth - 1_I4P
      endselect
      self%depth = max(self%depth, depth)
      endsubroutine emit

      subroutine patch(k)
      !< Make jump `k` land on the next instruction.
      integer(I4P), intent(in) :: k !< Jump index.

      self%code(k)%arg = size(self%code, kind=I4P) + 1_I4P
      endsubroutine patch

      function accept(operator) result(yes)
      !< Consume the current token if it is `operator`.
      character(len=*), intent(in) :: operator !< Operator.
      logical                      :: yes      !< Consumed.

      yes = iostat == 0_I4P .and. kind == T_OPERATOR
      if (yes) yes = token == operator
      if (yes) call next
      endfunction accept

      subroutine expect(operator)
      !< Consume `operator` or fail.
      character(len=*), intent(in) :: operator !< Operator.

      if (.not. accept(operator)) call syntax('expected "'//operator//'", found "'//token//'"')
      endsubroutine expect

      recursive subroutine parse_ternary
      !< condition ? a : b, right associative.
      integer(I4P) :: skip_a !< Jump over `a`.
      integer(I4P) :: skip_b !< Jump over `b`.

      nesting = nesting + 1_I4P
      if (nesting > MAX_NESTING) call syntax('expression nested too deeply')
      if (iostat /= 0_I4P) return
      call parse_binary(1_I4P)
      if (accept('?')) then
         call emit(OP_JUMP_UNLESS, k=skip_a)
         call parse_ternary
         call expect(':')
         call emit(OP_JUMP, k=skip_b)
         call patch(skip_a)
         depth = depth - 1_I4P ! `b` starts where `a` did
         call parse_ternary
         call patch(skip_b)
      endif
      nesting = nesting - 1_I4P
      endsubroutine parse_ternary

      recursive subroutine parse_binary(level)
      !< Left associative binary operators of `level` and tighter levels.
      integer(I4P), intent(in)      :: level    !< Level in `LEVELS`.
      character(len=:), allocatable :: operator !< Operator found.
      integer(I4P)                  :: k        !< Jump index.

      if (level > size(LEVELS, kind=I4P)) then
         call parse_unary
         return
      endif
      call parse_binary(level + 1_I4P)
      do while (iostat == 0_I4P .and. kind == T_OPERATOR)
         if (.not. in_level(token, level)) exit
         operator = token
         call next
         select case (operator)
         case ('||', '&&')
            if (operator == '||') then
               call emit(OP_OR_JUMP, k=k)
            else
               call emit(OP_AND_JUMP, k=k)
            endif
            call parse_binary(level + 1_I4P)
            call emit(OP_TRUTH)
            call patch(k)
         case default
            call parse_binary(level + 1_I4P)
            call emit(binary_code(operator))
         endselect
      enddo
      endsubroutine parse_binary

      recursive subroutine parse_unary
      !< Unary `-`, `+`, `!`, then powers.

      nesting = nesting + 1_I4P
      if (nesting > MAX_NESTING) call syntax('expression nested too deeply')
      if (iostat /= 0_I4P) return
      if (accept('-')) then
         call parse_unary
         call emit(OP_NEGATE)
      elseif (accept('+')) then
         call parse_unary
      elseif (accept('!')) then
         call parse_unary
         call emit(OP_NOT)
      else
         call parse_power
      endif
      nesting = nesting - 1_I4P
      endsubroutine parse_unary

      recursive subroutine parse_power
      !< primary [** unary]: right associative, tighter than a unary minus on its left.

      call parse_primary
      if (accept('**')) then
         call parse_unary
         call emit(OP_POWER)
      endif
      endsubroutine parse_power

      recursive subroutine parse_primary
      !< Number, column, constant, function call or parenthesized expression.
      character(len=:), allocatable :: name  !< Function name.
      integer(I4P)                  :: at    !< Name position.
      integer(I4P)                  :: nargs !< Arguments given.
      integer(I4P)                  :: f     !< Function index.

      if (iostat /= 0_I4P) return
      select case (kind)
      case (T_NUMBER)
         call emit(OP_CONSTANT, v=number)
         call next
      case (T_COLUMN)
         if (present(variable)) then
            call syntax('columns are only valid in using, not in a function')
            return
         endif
         call emit(OP_COLUMN, arg=int(number%i, I4P))
         call next
      case (T_NAME)
         name = token
         at = start
         call next
         if (iostat /= 0_I4P) return
         if (.not. (kind == T_OPERATOR .and. token == '(')) then
            if (name == 'pi') then
               call emit(OP_CONSTANT, v=value_object(r=PI))
            elseif (is_variable(name)) then
               call emit(OP_COLUMN, arg=1_I4P)
            else
               call syntax('unknown name "'//name//'" (user variables are not supported)', at)
            endif
            return
         endif
         call next
         if (name == 'column' .and. kind == T_STRING) then
            if (present(variable)) then
               call syntax('columns are only valid in using, not in a function', at)
               return
            endif
            self%names = [self%names, name_object(token)]
            call next
            call expect(')')
            call emit(OP_COLUMN_NAMED, arg=size(self%names, kind=I4P))
            return
         endif
         nargs = 0_I4P
         if (.not. (kind == T_OPERATOR .and. token == ')')) then
            do
               call parse_ternary
               nargs = nargs + 1_I4P
               if (.not. accept(',')) exit
            enddo
         endif
         call expect(')')
         if (iostat /= 0_I4P) return
         f = findloc(FUNCTIONS, name, dim=1)
         if (name == 'atan2') then
            if (nargs /= 2_I4P) call syntax('atan2 needs 2 arguments', at)
            call emit(OP_ATAN2)
         elseif (name == 'column' .and. present(variable)) then
            call syntax('columns are only valid in using, not in a function', at)
         elseif (name == 'column' .or. f > 0) then
            if (nargs /= 1_I4P) call syntax(name//' needs 1 argument', at)
            if (name == 'column') then
               call emit(OP_COLUMN_OF)
            else
               call emit(OP_FUNCTION, arg=f)
            endif
         else
            call syntax('unknown function "'//name//'"', at)
         endif
      case (T_STRING)
         call syntax('a string is only valid as column("name")')
      case (T_OPERATOR)
         if (accept('(')) then
            call parse_ternary
            call expect(')')
         else
            call syntax('unexpected "'//token//'"')
         endif
      case default
         call syntax('unexpected end')
      endselect
      endsubroutine parse_primary

      function is_variable(name) result(yes)
      !< Whether `name` is the dummy variable.
      character(len=*), intent(in) :: name !< Name.
      logical                      :: yes  !< The variable.

      yes = .false.
      if (present(variable)) yes = name == variable
      endfunction is_variable
   endsubroutine compile

   pure function evaluate(self, row, point) result(v)
   !< Value on a data row: `row` holds its cells (NaN if missing), `point` is its point number (column 0).
   !<
   !< NaN if undefined. Every floating point operation is checked beforehand, so no IEEE exception is raised.
   class(expression_object), intent(in) :: self                           !< Expression.
   real(R8P),                intent(in) :: row(:)                         !< Row cells.
   integer(I4P),             intent(in) :: point                          !< Point number.
   real(R8P)                            :: v                              !< Value.
   type(value_object)                   :: stack(max(1_I4P, self%depth)) !< Operand stack.
   type(value_object)                   :: result                         !< Operation result.
   integer(I8P)                         :: c                              !< Column number.
   integer(I4P)                         :: pc                             !< Next instruction.
   integer(I4P)                         :: sp                             !< Stack top.
   logical                              :: ok                             !< Defined.

   v = ieee_value(1.0_R8P, ieee_quiet_nan)
   sp = 0_I4P
   pc = 1_I4P
   ok = .true.
   do while (pc <= size(self%code, kind=I4P))
      associate(instruction => self%code(pc))
         pc = pc + 1_I4P
         select case (instruction%op)
         case (OP_CONSTANT)
            sp = sp + 1_I4P
            stack(sp) = instruction%v
         case (OP_COLUMN)
            sp = sp + 1_I4P
            call column(int(instruction%arg, I8P), stack(sp), ok)
         case (OP_COLUMN_NAMED)
            ! a name not resolved against a header: no column
            sp = sp + 1_I4P
            call column(-1_I8P, stack(sp), ok)
         case (OP_COLUMN_OF)
            c = -1_I8P
            if (stack(sp)%is_int) then
               c = stack(sp)%i
            elseif (abs(stack(sp)%r) < INT_LIMIT) then
               c = int(stack(sp)%r, I8P)
            endif
            call column(c, stack(sp), ok)
         case (OP_NEGATE)
            if (stack(sp)%is_int .and. stack(sp)%i /= LEAST) then
               stack(sp)%i = -stack(sp)%i
            else
               stack(sp) = value_object(r=-real_of(stack(sp)))
            endif
         case (OP_NOT)
            stack(sp) = logical_value(.not. truth(stack(sp)))
         case (OP_TRUTH)
            stack(sp) = logical_value(truth(stack(sp)))
         case (OP_ADD:OP_NE)
            call binary(instruction%op, stack(sp - 1_I4P), stack(sp), result, ok)
            sp = sp - 1_I4P
            stack(sp) = result
         case (OP_FUNCTION)
            call unary(instruction%arg, stack(sp), result, ok)
            stack(sp) = result
         case (OP_JUMP)
            pc = instruction%arg
         case (OP_JUMP_UNLESS)
            if (.not. truth(stack(sp))) pc = instruction%arg
            sp = sp - 1_I4P
         case (OP_AND_JUMP)
            if (.not. truth(stack(sp))) then
               stack(sp) = logical_value(.false.)
               pc = instruction%arg
            else
               sp = sp - 1_I4P
            endif
         case (OP_OR_JUMP)
            if (truth(stack(sp))) then
               stack(sp) = logical_value(.true.)
               pc = instruction%arg
            else
               sp = sp - 1_I4P
            endif
         endselect
      endassociate
      if (.not. ok) return
   enddo
   if (sp == 1_I4P) v = real_of(stack(1))
   contains
      pure subroutine column(c, value, ok)
      !< Column `c` of the row; column 0 is the point number; a missing cell is undefined.
      integer(I8P),       intent(in)    :: c     !< Column.
      type(value_object), intent(out)   :: value !< Cell.
      logical,            intent(inout) :: ok    !< Defined.

      value = value_object()
      if (c == 0_I8P) then
         value%r = real(point, R8P)
      elseif (c >= 1_I8P .and. c <= size(row, kind=I8P)) then
         value%r = row(c)
         if (ieee_is_nan(value%r)) ok = .false.
      else
         ok = .false.
      endif
      endsubroutine column
   endfunction evaluate

   pure function first_column(self) result(c)
   !< First data column (from 1) the expression reads, 0 if none (an unresolved name is none): the column whose header
   !< titles the item, as gnuplot `title columnhead`.
   class(expression_object), intent(in) :: self !< Expression.
   integer(I4P)                         :: c    !< Column.
   integer(I4P)                         :: k    !< Instruction counter.

   c = 0_I4P
   do k = 1_I4P, size(self%code, kind=I4P)
      if (self%code(k)%op == OP_COLUMN .and. self%code(k)%arg >= 1_I4P) then
         c = self%code(k)%arg
         return
      endif
   enddo
   endfunction first_column

   elemental function name_count(self) result(n)
   !< Number of column header names used.
   class(expression_object), intent(in) :: self !< Expression.
   integer(I4P)                         :: n    !< Names.

   n = 0_I4P
   if (allocated(self%names)) n = size(self%names, kind=I4P)
   endfunction name_count

   pure function name_of(self, k) result(name)
   !< The `k`-th column header name.
   class(expression_object), intent(in) :: self !< Expression.
   integer(I4P),             intent(in) :: k    !< Name index.
   character(len=:), allocatable        :: name !< Name.

   name = self%names(k)%text
   endfunction name_of

   pure function resolve(self, header) result(resolved)
   !< The expression with its column header names replaced by their column numbers in `header` (the names of columns
   !< 1, 2, ...; trailing blanks ignored); a name not in it reads no column: undefined.
   class(expression_object), intent(in) :: self      !< Expression.
   character(len=*),         intent(in) :: header(:) !< Column names.
   type(expression_object)              :: resolved  !< Resolved expression.
   integer(I4P)                         :: k         !< Instruction counter.
   integer(I4P)                         :: c         !< Column counter.

   resolved = self
   do k = 1_I4P, size(resolved%code, kind=I4P)
      if (resolved%code(k)%op /= OP_COLUMN_NAMED) cycle
      associate(name => self%names(resolved%code(k)%arg)%text)
         resolved%code(k) = instruction_object(op=OP_COLUMN, arg=-1_I4P)
         do c = 1_I4P, size(header, kind=I4P)
            if (trim(header(c)) == name) then
               resolved%code(k)%arg = c
               exit
            endif
         enddo
      endassociate
   enddo
   endfunction resolve

   pure subroutine set_column(self, c)
   !< Make the expression the plain column `c` (0 is the point number).
   class(expression_object), intent(inout) :: self !< Expression.
   integer(I4P),             intent(in)    :: c    !< Column.

   self%text = ''
   self%code = [instruction_object(op=OP_COLUMN, arg=c)]
   self%names = [name_object ::]
   self%depth = 1_I4P
   endsubroutine set_column

   pure subroutine set_name(self, name)
   !< Make the expression the plain column of header `name`, as gnuplot `using 1:"name"`.
   class(expression_object), intent(inout) :: self !< Expression.
   character(len=*),         intent(in)    :: name !< Column header name.

   self%text = ''
   self%code = [instruction_object(op=OP_COLUMN_NAMED, arg=1_I4P)]
   self%names = [name_object(name)]
   self%depth = 1_I4P
   endsubroutine set_name

   pure function value_at(self, x) result(v)
   !< Value of an expression compiled with a dummy variable at the variable value `x`; NaN if undefined.
   class(expression_object), intent(in) :: self !< Expression.
   real(R8P),                intent(in) :: x    !< Variable value.
   real(R8P)                            :: v    !< Value.

   v = self%evaluate([x], 0_I4P)
   endfunction value_at

   ! private procedures
   pure function in_level(operator, level) result(yes)
   !< Whether `operator` is a binary operator of grammar level `level`.
   character(len=*), intent(in) :: operator !< Operator.
   integer(I4P),     intent(in) :: level    !< Level in `LEVELS`.
   logical                      :: yes      !< Operator of the level.

   yes = index(' '//trim(LEVELS(level))//' ', ' '//operator//' ') > 0
   endfunction in_level

   pure function binary_code(operator) result(op)
   !< Operation code of a binary operator.
   character(len=*), intent(in) :: operator !< Operator.
   integer(I4P)                 :: op       !< Operation code.

   select case (operator)
   case ('+')
      op = OP_ADD
   case ('-')
      op = OP_SUBTRACT
   case ('*')
      op = OP_MULTIPLY
   case ('/')
      op = OP_DIVIDE
   case ('%')
      op = OP_MODULO
   case ('<')
      op = OP_LT
   case ('<=')
      op = OP_LE
   case ('>')
      op = OP_GT
   case ('>=')
      op = OP_GE
   case ('==')
      op = OP_EQ
   case default
      op = OP_NE
   endselect
   endfunction binary_code

   pure function real_of(a) result(r)
   !< Real value of `a`.
   type(value_object), intent(in) :: a !< Value.
   real(R8P)                      :: r !< Real value.

   if (a%is_int) then
      r = real(a%i, R8P)
   else
      r = a%r
   endif
   endfunction real_of

   pure function truth(a) result(yes)
   !< Whether `a` is not zero.
   type(value_object), intent(in) :: a   !< Value.
   logical                        :: yes !< Not zero.

   if (a%is_int) then
      yes = a%i /= 0_I8P
   else
      yes = a%r /= 0.0_R8P
   endif
   endfunction truth

   pure function logical_value(yes) result(a)
   !< Integer 1 or 0.
   logical, intent(in) :: yes !< Truth.
   type(value_object)  :: a   !< Value.

   a = value_object(is_int=.true.)
   if (yes) a%i = 1_I8P
   endfunction logical_value

   pure function int_value(i) result(a)
   !< Integer value.
   integer(I8P), intent(in) :: i !< Integer.
   type(value_object)       :: a !< Value.

   a = value_object(i=i, is_int=.true.)
   endfunction int_value

   pure subroutine binary(op, a, b, c, ok)
   !< c = a op b: an integer when both are and the result fits, else a real; `ok` false if undefined.
   integer(I4P),       intent(in)    :: op   !< Operation code.
   type(value_object), intent(in)    :: a    !< Left operand.
   type(value_object), intent(in)    :: b    !< Right operand.
   type(value_object), intent(out)   :: c    !< Result.
   logical,            intent(inout) :: ok   !< Defined.
   real(R8P)                         :: x    !< Left operand, real.
   real(R8P)                         :: y    !< Right operand, real.
   logical                           :: done !< Integer result computed.

   c = value_object()
   done = .false.
   if (a%is_int .and. b%is_int) call integer_binary(op, a%i, b%i, c, done, ok)
   if (done .or. .not. ok) return
   x = real_of(a)
   y = real_of(b)
   select case (op)
   case (OP_ADD)
      call safe_add(x, y, c%r, ok)
   case (OP_SUBTRACT)
      call safe_add(x, -y, c%r, ok)
   case (OP_MULTIPLY)
      ! Fortran does not short-circuit: the guards are nested, never joined by .and.
      if (abs(x) > 1.0_R8P) ok = abs(y) <= HUGE_REAL / abs(x)
      if (ok) c%r = x * y
   case (OP_DIVIDE)
      ok = divisible(x, y)
      if (ok) c%r = x / y
   case (OP_MODULO)
      ok = divisible(x, y)
      if (ok) c%r = mod(x, y)
   case (OP_POWER)
      call safe_power(x, y, c%r, ok)
   case (OP_ATAN2)
      if (x /= 0.0_R8P .or. y /= 0.0_R8P) c%r = atan2(x, y)
   case (OP_LT)
      c = logical_value(x < y)
   case (OP_LE)
      c = logical_value(x <= y)
   case (OP_GT)
      c = logical_value(x > y)
   case (OP_GE)
      c = logical_value(x >= y)
   case (OP_EQ)
      c = logical_value(x == y)
   case (OP_NE)
      c = logical_value(x /= y)
   endselect
   endsubroutine binary

   pure subroutine integer_binary(op, i, j, c, done, ok)
   !< c = i op j on integers; `done` false when the result is not an integer (overflow, negative power, atan2).
   integer(I4P),       intent(in)    :: op   !< Operation code.
   integer(I8P),       intent(in)    :: i    !< Left operand.
   integer(I8P),       intent(in)    :: j    !< Right operand.
   type(value_object), intent(inout) :: c    !< Result.
   logical,            intent(out)   :: done !< Integer result computed.
   logical,            intent(inout) :: ok   !< Defined.
   integer(I8P)                      :: base !< Power base.
   integer(I8P)                      :: e    !< Remaining power exponent.
   integer(I8P)                      :: p    !< Power result.

   done = .true.
   select case (op)
   case (OP_ADD)
      ! each bound is computed only on the side where it cannot overflow itself
      if (j > 0_I8P) then
         done = i <= MOST - j
      else
         done = i >= LEAST - j
      endif
      if (done) c = int_value(i + j)
   case (OP_SUBTRACT)
      if (j < 0_I8P) then
         done = i <= MOST + j
      else
         done = i >= LEAST + j
      endif
      if (done) c = int_value(i - j)
   case (OP_MULTIPLY)
      done = fits_product(i, j)
      if (done) c = int_value(i * j)
   case (OP_DIVIDE, OP_MODULO)
      if (j == 0_I8P) then
         ok = .false.
      elseif (j == -1_I8P) then
         ! LEAST / -1 overflows, and traps on x86
         if (op == OP_MODULO) then
            c = int_value(0_I8P)
         else
            done = i /= LEAST
            if (done) c = int_value(-i)
         endif
      elseif (op == OP_DIVIDE) then
         c = int_value(i / j)
      else
         c = int_value(mod(i, j))
      endif
   case (OP_POWER)
      ! gnuplot: a negative exponent gives a real, 2**-1 is 0.5
      done = j >= 0_I8P
      if (.not. done) return
      p = 1_I8P
      base = i
      e = j
      do while (e > 0_I8P .and. done)
         if (mod(e, 2_I8P) == 1_I8P) then
            done = fits_product(p, base)
            if (done) p = p * base
         endif
         e = e / 2_I8P
         if (e > 0_I8P .and. done) then
            done = fits_product(base, base)
            if (done) base = base * base
         endif
      enddo
      if (done) c = int_value(p)
   case (OP_ATAN2)
      done = .false.
   case (OP_LT)
      c = logical_value(i < j)
   case (OP_LE)
      c = logical_value(i <= j)
   case (OP_GT)
      c = logical_value(i > j)
   case (OP_GE)
      c = logical_value(i >= j)
   case (OP_EQ)
      c = logical_value(i == j)
   case (OP_NE)
      c = logical_value(i /= j)
   endselect
   endsubroutine integer_binary

   pure function fits_product(i, j) result(yes)
   !< Whether i*j fits an I8P integer.
   integer(I8P), intent(in) :: i   !< Factor.
   integer(I8P), intent(in) :: j   !< Factor.
   logical                  :: yes !< No overflow.

   if (i == 0_I8P .or. j == 0_I8P) then
      yes = .true.
   elseif (i == LEAST .or. j == LEAST) then
      yes = i == 1_I8P .or. j == 1_I8P
   else
      yes = abs(i) <= MOST / abs(j)
   endif
   endfunction fits_product

   pure subroutine unary(f, a, c, ok)
   !< c = FUNCTIONS(f)(a); `ok` false if undefined.
   integer(I4P),       intent(in)    :: f    !< Function index.
   type(value_object), intent(in)    :: a    !< Argument.
   type(value_object), intent(out)   :: c    !< Result.
   logical,            intent(inout) :: ok   !< Defined.
   character(len=:), allocatable     :: name !< Function name.
   real(R8P)                         :: x    !< Argument, real.

   c = value_object()
   x = real_of(a)
   name = trim(FUNCTIONS(f))
   select case (name)
   case ('abs')
      if (a%is_int .and. a%i /= LEAST) then
         c = int_value(abs(a%i))
      else
         c%r = abs(x)
      endif
   case ('sgn')
      c = int_value(0_I8P)
      if (x > 0.0_R8P) c%i = 1_I8P
      if (x < 0.0_R8P) c%i = -1_I8P
   case ('int', 'floor', 'ceil')
      if (a%is_int) then
         c = a
      elseif (abs(x) < INT_LIMIT) then
         select case (name)
         case ('int')
            c = int_value(int(x, I8P))
         case ('floor')
            c = int_value(floor(x, I8P))
         case default
            c = int_value(ceiling(x, I8P))
         endselect
      else
         ok = .false.
      endif
   case ('sqrt')
      ok = x >= 0.0_R8P
      if (ok) c%r = sqrt(x)
   case ('exp')
      ok = x <= LOG_HUGE
      if (ok .and. x > LOG_TINY) c%r = exp(x)
   case ('log')
      ok = x > 0.0_R8P
      if (ok) c%r = log(x)
   case ('log10')
      ok = x > 0.0_R8P
      if (ok) c%r = log10(x)
   case ('asin')
      ok = abs(x) <= 1.0_R8P
      if (ok) c%r = asin(x)
   case ('acos')
      ok = abs(x) <= 1.0_R8P
      if (ok) c%r = acos(x)
   case ('sinh')
      ok = abs(x) <= LOG_HUGE
      if (ok) c%r = sinh(x)
   case ('cosh')
      ok = abs(x) <= LOG_HUGE
      if (ok) c%r = cosh(x)
   case ('sin')
      c%r = sin(x)
   case ('cos')
      c%r = cos(x)
   case ('tan')
      c%r = tan(x)
   case ('atan')
      c%r = atan(x)
   case ('tanh')
      c%r = tanh(x)
   endselect
   endsubroutine unary

   pure subroutine safe_add(x, y, z, ok)
   !< z = x + y, undefined on overflow.
   real(R8P), intent(in)    :: x  !< Addend.
   real(R8P), intent(in)    :: y  !< Addend.
   real(R8P), intent(out)   :: z  !< Sum.
   logical,   intent(inout) :: ok !< Defined.

   z = 0.0_R8P
   ! only operands of the same sign can overflow
   ok = .not. (sign(1.0_R8P, x) == sign(1.0_R8P, y) .and. abs(y) > HUGE_REAL - abs(x))
   if (ok) z = x + y
   endsubroutine safe_add

   pure function divisible(x, y) result(ok)
   !< Whether x / y is finite.
   real(R8P), intent(in) :: x  !< Dividend.
   real(R8P), intent(in) :: y  !< Divisor.
   logical               :: ok !< Finite quotient.

   ok = y /= 0.0_R8P
   if (ok .and. abs(y) < 1.0_R8P) ok = abs(x) <= HUGE_REAL * abs(y)
   endfunction divisible

   pure subroutine safe_power(x, y, z, ok)
   !< z = x ** y on reals; undefined when complex (negative base, fractional exponent), infinite or overflowing.
   real(R8P), intent(in)    :: x   !< Base.
   real(R8P), intent(in)    :: y   !< Exponent.
   real(R8P), intent(out)   :: z   !< Power.
   logical,   intent(inout) :: ok  !< Defined.
   real(R8P)                :: t   !< log(|x|).
   logical                  :: odd !< Odd integer exponent.

   z = 0.0_R8P
   if (x == 0.0_R8P) then
      ok = y >= 0.0_R8P
      if (y == 0.0_R8P) z = 1.0_R8P
      return
   endif
   if (x < 0.0_R8P .and. y /= aint(y)) then
      ok = .false.
      return
   endif
   ! reals of magnitude 2**53 and more are even integers
   odd = .false.
   if (x < 0.0_R8P .and. abs(y) < 2.0_R8P**53) odd = mod(y, 2.0_R8P) /= 0.0_R8P
   t = log(abs(x))
   if (abs(t) > 1.0_R8P) then
      if (abs(y) > HUGE_REAL / abs(t)) then
         ! |y*t| beyond any real: an overflow, or a result below the smallest real
         ok = sign(1.0_R8P, y) /= sign(1.0_R8P, t)
         return
      endif
   endif
   ok = y * t <= LOG_HUGE
   if (.not. ok) return
   if (y * t > LOG_TINY) z = abs(x)**y
   if (odd) z = -z
   endsubroutine safe_power
endmodule foresight_expression
