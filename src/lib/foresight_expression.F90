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
!<   `abs acos asin atan atan2 ceil cos cosh exp floor int log log10 sgn sin sinh sqrt tan tanh`, and gnuplot's special
!<   functions of foresight_mathlib (`erf`, `gamma`, `igamma`, `besj0`, `lambertw`, ...);
!< - with a `symbols_object`, user variables (`a = 2`: their value when the expression is compiled, integer or real)
!<   and user functions (`f(x, y) = ...`: compiled inline where called, the arguments read from their stack slots; a
!<   call of a function already being compiled, a recursion, jumps to a copy of its body compiled once after the main
!<   code, run on a call stack: past 251 nested calls, gnuplot's `recursion depth limit exceeded`), as gnuplot's
!<   `a = 2` and `f(x) = a*sin(x)`;
!< - integer constants are integers: `1/2` is 0, `-5/2` is -2, `7/2.` is 3.5; an integer overflow gives a real;
!<   columns are real; `floor`, `ceil`, `int`, `sgn`, comparisons and logical operators give integers; an integer
!<   overflow of `+`, `-`, `*` and `**` follows `overflow_mode` (gnuplot `set|unset overflow`, global as gnuplot's):
!<   a real (default), wrapped (`+` and `-` only, `unset overflow`), NaN or undefined;
!< - a missing cell, a division by zero, a domain error (`sqrt(-1)`, `log(0)`) or an overflow make the whole value
!<   undefined: NaN, a gap in the plot, as gnuplot's `1/0`;
!< - compiled with `degrees` (gnuplot `set angles degrees`), `sin`, `cos`, `tan` take degrees and `asin`, `acos`,
!<   `atan`, `atan2` return them.
!<
!< Strings, as gnuplot's: literals in double quotes (`\t`, `\n`, `\"`, `\\` escapes) or single quotes (literal), string
!< user variables and functions; `a . b` joins (`b` a string or an integer), `eq` and `ne` compare, `s[i:j]` is a
!< substring (1-based, ends clamped, `*` or nothing for an open end); `sprintf` (C conversions, from the exact binary
!< value), `gprintf`, `strlen`, `substr`, `strstrt`, `words`, `word`, `trim`; `value("name")`, `exists("name")`
!< (quoted names only). Arrays (`symbols_object%declare_array`): `A[i]` an element (an index known now resolved now,
!< else on each row), `|A|` the size, `index(A, value)`; datablocks (string variables named `$NAME`): `$NAME[i]` a
!< line, `|$NAME|` their number; gnuplot 6.0's `split(s [, sep])` (an array: assigned, printed, sized `|split(s)|`, in
!< `index` and `join`) and `join(A, sep)`, their arguments known when compiled. Arithmetic and `==` read a string's leading number (`"3" + 1` is 4); a string as a condition,
!< or where a number cannot be read, is an error of a constant expression and a gap on a data row.
!<
!< Complex numbers, as gnuplot's: constants `{re, im}` and `I` (`{0,1}`); `+ - * / **` (gnuplot's formulas: powers in
!< polar form, a negative base with a fractional exponent complex), `abs`, `arg`, `real`, `imag`, `conj`, `sqrt`,
!< `exp`, `log`, `log10` (of negative reals too), `sin`, `cos`, `tan`, `sinh`, `cosh`; comparisons `<`... of the real
!< parts, `==` `!=` of both; a plotted value whose imaginary part exceeds 1e-8 is undefined (gnuplot's `set zero`); the
!< other functions of a complex argument are undefined.
!<
!< Accepted beyond gnuplot: `%` and the logical operators on reals (gnuplot rejects them), and overflows give a gap
!< where gnuplot stops the plot. Every floating point operation is checked beforehand, so evaluation never raises an
!< IEEE invalid, division by zero or overflow exception.
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan, ieee_positive_inf, ieee_quiet_nan, ieee_value
use, intrinsic :: iso_fortran_env, only : output_unit
use foresight_format, only : c_integer, c_real, c_string, decimal_of, format_check, format_decimal, format_value, &
                             gnuplot_real, int_str, real_from_decimal
use foresight_mathlib, only : MATH_ARGS, MATH_FUNCTIONS, math_function, math_order
use foresight_sys, only : command_output
use foresight_tokens, only : gnuplot_escape, UNAME_CHARS, UNAME_START
use foresight_time, only : civil_time, strftime, strptime
use penf, only : I4P, I8P, R8P

implicit none
private
public :: expression_object
public :: list_text
public :: name_object
public :: saved_array
public :: saved_variable
public :: symbols_object
public :: value_list
public :: value_object
public :: block_hook
public :: block_call_interface
public :: store_hook
public :: element_hook
public :: element_fetch_hook
public :: fetch_hook
public :: store_interface
public :: fetch_interface
public :: push
public :: overflow_mode
public :: OVERFLOW_IGNORE
public :: OVERFLOW_FLOAT
public :: OVERFLOW_UNDEFINED
public :: OVERFLOW_NAN

interface push
   !< Append an item through a temporary: nvfortran 26.9 corrupts `list = [list, item]` (and any `list = f(list)`)
   !< when the items hold deferred-length characters.
   module procedure push_name
   module procedure push_variable
   module procedure push_function
   module procedure push_expression
   module procedure push_instruction
   module procedure push_array
   module procedure push_list
   module procedure push_value
endinterface push

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
integer(I4P), parameter :: OP_LOAD         = 26_I4P !< Push a copy of stack slot `arg` (a user function argument).
character(len=*), parameter :: SUM_FRAME = '(sum)' !< Frame name of a `sum` variable (no function is named so).
integer(I4P), parameter :: OP_COLLAPSE     = 27_I4P !< Drop the `arg` values under the top (a call's arguments).
integer(I4P), parameter :: OP_CONCAT       = 28_I4P !< `.`: string join.
integer(I4P), parameter :: OP_STREQ        = 29_I4P !< `eq`.
integer(I4P), parameter :: OP_STRNE        = 30_I4P !< `ne`.
integer(I4P), parameter :: OP_SUBSTRING    = 31_I4P !< `s[i:j]`: the string and both ends on the stack.
integer(I4P), parameter :: OP_CALL         = 32_I4P !< String function `arg` of the top `v%i` values.
integer(I4P), parameter :: OP_STRCOL       = 33_I4P !< Replace the top with the text of the column it numbers or names.
integer(I4P), parameter :: OP_COLUMNHEAD   = 34_I4P !< Replace the top with the header text of the column it numbers.
integer(I4P), parameter :: OP_TIMECOLUMN   = 35_I4P !< Column (under the top) read as a time with the format (top).
integer(I4P), parameter :: OP_ELEMENT      = 36_I4P !< Replace the top (an index) with that element of `lists(arg)`.
integer(I4P), parameter :: OP_RECURSE      = 37_I4P !< Call the body at `arg` on its `v%i` arguments (a recursion).
integer(I4P), parameter :: OP_RETURN       = 38_I4P !< End of a called body: its value replaces its arguments.
integer(I4P), parameter :: OP_STOP         = 39_I4P !< End of the main code, before the called bodies.
integer(I4P), parameter :: OP_DEPTH        = 40_I4P !< A call inlined in a called body: check the nested calls.
integer(I4P), parameter :: OP_BAND         = 41_I4P !< `&`; the bitwise operators of integers run from here to OP_SHR.
integer(I4P), parameter :: OP_BOR          = 42_I4P !< `|`.
integer(I4P), parameter :: OP_BXOR         = 43_I4P !< `^`.
integer(I4P), parameter :: OP_SHL          = 44_I4P !< `<<`.
integer(I4P), parameter :: OP_SHR          = 45_I4P !< `>>`, logical (gnuplot's on x86).
integer(I4P), parameter :: OP_BNOT         = 46_I4P !< `~`, unary.
integer(I4P), parameter :: OP_BLOCK        = 47_I4P !< Call the function block `blocks(arg)` on its `v%i` arguments.
integer(I4P), parameter :: OP_RAND         = 48_I4P !< gnuplot's rand(x) of the top: the next pseudo-random number.
integer(I4P), parameter :: OP_SPECIAL      = 49_I4P !< A special function `MATH_FUNCTIONS(arg)` (foresight_mathlib) of
                                                    !< its `MATH_ARGS(arg)` arguments.
integer(I4P), parameter :: OP_ASSIGN       = 50_I4P !< `name = value` inside an expression: the top stored in the user
                                                    !< variable `stores(arg)` (`store_hook`), and kept.
integer(I4P), parameter :: OP_FETCH        = 51_I4P !< Push the user variable `stores(arg)` as it is now (`fetch_hook`),
                                                    !< `v` its value when compiled if none (`calls` 1 when it had one).
integer(I4P), parameter :: OP_ASSIGN_ELEMENT = 52_I4P !< `name[i] = value` inside an expression: the top stored in
                                                      !< element i (below it) of the array `stores(arg)`
                                                      !< (`element_hook`); the index dropped, the value kept.
integer(I4P), parameter :: OP_FETCH_ELEMENT = 53_I4P !< Replace the top (an index) with that element of the array
                                                     !< `stores(arg)` as it is now (`element_fetch_hook`).

! functions of the data row: `strcol(N)` and `stringcolumn(N)` the text of a column, `columnhead(N)` and
! `columnheader(N)` the header text of a column (OP_STRCOL, OP_COLUMNHEAD)
character(len=*), parameter :: ROW_FUNCTIONS(5) = [character(len=12) :: 'strcol', 'stringcolumn', 'columnhead', &
                                                   'columnheader', 'timecolumn']

integer(I4P), parameter :: NO_COLUMN = -huge(1_I4P) !< Column of a header name found nowhere: reads nothing.
character(len=*), parameter :: DEFAULT_TIMEFMT = '%d/%m/%y,%H:%M' !< gnuplot's default `set timefmt`.

! one-argument functions, the `OP_FUNCTION` argument is the index
character(len=*), parameter :: FUNCTIONS(22) = [character(len=5) :: 'abs', 'acos', 'asin', 'atan', 'ceil', 'cos', &
                                                'cosh', 'exp', 'floor', 'int', 'log', 'log10', 'sgn', 'sin', 'sinh', &
                                                'sqrt', 'tan', 'tanh', 'real', 'imag', 'arg', 'conj']

! functions of strings, the `OP_CALL` argument is the index; their least and most arguments
character(len=*), parameter :: STRING_FUNCTIONS(10) = [character(len=8) :: 'sprintf', 'gprintf', 'strlen', 'substr', &
                                                       'strstrt', 'words', 'word', 'trim', 'strftime', 'strptime']
integer(I4P),     parameter :: LEAST_ARGS(10) = [1_I4P, 2_I4P, 1_I4P, 3_I4P, 2_I4P, 1_I4P, 2_I4P, 1_I4P, 2_I4P, 2_I4P]
integer(I4P),     parameter :: MOST_ARGS(10)  = [huge(1_I4P), 2_I4P, 1_I4P, 3_I4P, 2_I4P, 1_I4P, 2_I4P, 1_I4P, 2_I4P, &
                                                 2_I4P]

! errors of typed values (a constant expression reports them, a data row is undefined)
integer(I4P), parameter :: E_NONE       = 0_I4P !< No error.
integer(I4P), parameter :: E_NONNUMERIC = 1_I4P !< A string without a leading number in arithmetic.
integer(I4P), parameter :: E_NOTSTRING  = 2_I4P !< A number given to a string operator or function.
integer(I4P), parameter :: E_BOOLEAN    = 3_I4P !< A string as a condition.
integer(I4P), parameter :: E_FORMAT     = 4_I4P !< A bad sprintf/gprintf format.
integer(I4P), parameter :: E_STRING_ARG = 5_I4P !< A string printed with a numeric conversion.
integer(I4P), parameter :: E_NUMBER_ARG = 6_I4P !< A number printed with `%s`.
integer(I4P), parameter :: E_INDEX      = 7_I4P !< An array index out of range.
integer(I4P), parameter :: E_UNSET      = 8_I4P !< An array element never set.
integer(I4P), parameter :: E_DEPTH      = 9_I4P !< Too many nested calls of recursive user functions.
integer(I4P), parameter :: E_BITWISE    = 10_I4P !< A real or a string given to a bitwise operator.
integer(I4P), parameter :: E_BLOCK      = 11_I4P !< A function block failed: its message in `block_message`.
integer(I4P), parameter :: E_UNDEF      = 12_I4P !< The value is gnuplot's undefined one (`print` shows `<undefined>`).
integer(I4P), parameter :: E_UNINIT     = 13_I4P !< An operation on gnuplot's undefined value.
integer(I4P), parameter :: E_SEED       = 14_I4P !< rand(x): x not an integer seed.
integer(I4P), parameter :: E_ORDER      = 15_I4P !< A real order of besjn, besyn, besin or expint (`order_message`).
integer(I4P), parameter :: E_NOVAR      = 16_I4P !< A variable assigned by an expression read before it has a value.

! binary operator levels of the grammar, loosest first
character(len=*), parameter :: LEVELS(10) = [character(len=11) :: '||', '&&', '|', '^', '&', '== != eq ne', &
                                                 '< <= > >=', '<< >>', '+ - .', '* / %'] !< C's, as gnuplot.

integer(I4P), parameter :: MAX_NESTING = 256_I4P                     !< Deepest parentheses and unary chains.
integer(I4P), parameter :: MAX_CALLS   = 251_I4P                     !< Most nested user function calls (gnuplot's).
integer(I8P), parameter :: MOST        = huge(1_I8P)                 !< Largest integer.
integer(I8P), parameter :: LEAST       = -MOST - 1_I8P               !< Smallest integer.
integer(I4P), parameter :: OVERFLOW_IGNORE    = 0_I4P !< `unset overflow`: `+` and `-` wrap, `*` and `**` give a real.
integer(I4P), parameter :: OVERFLOW_FLOAT     = 1_I4P !< `set overflow [float]`: a real (gnuplot's default).
integer(I4P), parameter :: OVERFLOW_UNDEFINED = 2_I4P !< `set overflow undefined`: the value is undefined.
integer(I4P), parameter :: OVERFLOW_NAN       = 3_I4P !< `set overflow NaN`: NaN.
integer(I4P), save      :: overflow_mode = OVERFLOW_FLOAT !< Integer overflow handling, gnuplot's global setting.
real(R8P),    parameter :: HUGE_REAL   = huge(1.0_R8P)               !< Largest real.
real(R8P),    parameter :: LOG_HUGE    = log(HUGE_REAL) - 1.0e-6_R8P !< Largest safe `exp` argument.
real(R8P),    parameter :: LOG_TINY    = -745.0_R8P                  !< `exp` of less is 0.
real(R8P),    parameter :: INT_LIMIT   = 2.0_R8P**63                 !< Reals from here on are not I8P integers.
real(R8P),    parameter :: INT_GUARANTEED = 9.22337203685477478e+18_R8P !< gnuplot's LARGEST_GUARANTEED_NONOVERFLOW: int().
real(R8P),    parameter :: EXACT_HALF  = 2.0_R8P**52                 !< gnuplot's LARGEST_EXACT_INT/2: floor(), ceil().
real(R8P),    parameter :: PI          = acos(-1.0_R8P)              !< pi.
real(R8P),    parameter :: ZERO_IMAG   = 1.0e-8_R8P                  !< gnuplot's `set zero`: a larger imaginary part
                                                                     !< makes a plotted value undefined.

type :: value_object
   !< Stack value: an integer, a real or a string, as in gnuplot.
   real(R8P)                     :: r         = 0.0_R8P !< Real value.
   integer(I8P)                  :: i         = 0_I8P   !< Integer value.
   logical                       :: is_int    = .false. !< Integer.
   logical                       :: is_string = .false. !< String, in `s`.
   ! before `s`: nvfortran 26.9 fort1 crashes on a component after the deferred-length one here
   logical                       :: is_undef = .false.  !< gnuplot's undefined value: an array element without one, a
                                                        !< function block's missing return.
   real(R8P)                     :: im        = 0.0_R8P !< Imaginary part of a complex value, gnuplot's {re, im}.
   character(len=:), allocatable :: s                   !< String value.
endtype value_object

type :: instruction_object
   !< Stack code instruction.
   integer(I4P)       :: op  = OP_CONSTANT !< Operation code.
   integer(I4P)       :: arg = 0_I4P       !< Column, function or jump target.
   type(value_object) :: v                 !< Constant.
   integer(I4P)       :: calls = 0_I4P     !< OP_RECURSE: the nested calls it adds (the inline ones it is inside).
endtype instruction_object

type :: name_object
   !< Column header name.
   character(len=:), allocatable :: text !< Name.
endtype name_object

type :: frame_object
   !< A user function being compiled inline: its parameters read the stack slots from `base`.
   character(len=:), allocatable :: name      !< Function name.
   type(name_object), allocatable :: params(:) !< Parameter names.
   integer(I4P)                  :: base = 1_I4P !< Stack slot of the first argument.
endtype frame_object

type :: user_variable
   !< User variable, gnuplot `a = 2`.
   character(len=:), allocatable :: name !< Name.
   type(value_object)            :: v    !< Value, integer or real.
   logical                       :: block = .false. !< A function block, `function $f << EOF` (its body the value).
endtype user_variable

type :: user_function
   !< User function, gnuplot `f(x, y) = ...`.
   character(len=:), allocatable  :: name      !< Name.
   type(name_object), allocatable :: params(:) !< Parameter names.
   character(len=:), allocatable  :: body      !< Body text.
endtype user_function

type :: saved_variable
   !< A variable's state, kept to be restored: the variable of a `do for` loop is local to the loop, as gnuplot's.
   character(len=:), allocatable, private :: name           !< Name.
   logical,                       private :: found = .false. !< It existed.
   type(value_object),            private :: v              !< Its value.
endtype saved_variable

type :: value_list
   !< The elements of an array (gnuplot `array A[N]`) or the lines of a datablock, indexed at run time.
   type(value_object), allocatable :: items(:) !< Elements.
   logical,            allocatable :: set(:)   !< The element has a value (an array element may have none).
endtype value_list

type :: user_array
   !< User array, gnuplot `array A[N]`: elements of any type, some possibly without a value.
   character(len=:), allocatable :: name !< Name.
   type(value_list)              :: list !< Elements.
endtype user_array

type :: saved_array
   !< An array's state, kept to be restored: `call` sets ARGV and restores it after the script.
   type(user_array), private :: a              !< The array.
   logical,          private :: found = .false. !< It existed.
endtype saved_array

type :: symbols_object
   !< User variables and functions of a script, gnuplot's: `a = 2` stores the value now (integer or real), `f(x) = a*x`
   !< stores the text, compiled inline where it is called, so its variables take their values at that moment (plot
   !< time); recursive functions run on a call stack.
   type(user_variable), allocatable, private :: variables(:) !< Variables.
   type(user_function), allocatable, private :: functions(:) !< Functions.
   type(user_array),    allocatable, private :: arrays(:)    !< Arrays, gnuplot `array A[N]`.
   character(len=:),    allocatable          :: timefmt      !< Time format of `timecolumn(N)` (gnuplot `set timefmt`),
                                                             !< `%d/%m/%y,%H:%M` if unallocated.
   type(name_object),   allocatable, private :: assigned(:)  !< Variables a user function body assigns (`f(x) = (a = x,
                                                             !< a)`): read at run time wherever compiled.
   contains
      procedure, pass(self) :: assign   !< `name = expression`.
      procedure, pass(self) :: put      !< Set a variable to a typed value (an assignment run by an expression).
      procedure, pass(self) :: get      !< Typed value of a variable.
      procedure, pass(self) :: assign_element !< `name[index] = expression`.
      procedure, pass(self) :: set_element    !< Set an array element to a typed value.
      procedure, pass(self) :: get_element    !< Typed value of an array element.
      procedure, pass(self) :: learn_assigned !< Read the variables an expression assigns at run time from now on.
      procedure, pass(self) :: evaluate_constant !< Typed value of a constant expression.
      procedure, pass(self) :: array_data !< An array as the lines of a data file (index and value).
      procedure, pass(self) :: array_text !< An array as gnuplot's `print` shows it.
      procedure, pass(self) :: array_value !< An array or a slice `A[i:j]` given as text.
      procedure, pass(self) :: store_array !< Set an array to elements.
      procedure, pass(self) :: declare_array !< `array name[N] [= [...]]`, `array name = [...]`.
      procedure, pass(self) :: is_array !< Whether a name is an array.
      procedure, pass(self) :: defined  !< Whether a name is a variable, an array or `pi`, `NaN`.
      procedure, pass(self) :: datablock_names !< Names of the datablocks.
      procedure, pass(self) :: array_size !< Size of an array.
      procedure, pass(self) :: set_array !< Set an array to strings (ARGV).
      procedure, pass(self) :: clear    !< Forget every symbol.
      procedure, pass(self) :: constant !< Value of a constant expression.
      procedure, pass(self) :: define   !< `name(params) = body`.
      procedure, pass(self) :: value_of !< Value of a variable.
      procedure, pass(self) :: set_value !< Set a variable to a number.
      procedure, pass(self) :: set_string !< Set a variable to a string.
      procedure, pass(self) :: define_block !< Define a function block.
      procedure, pass(self) :: is_block   !< Whether a name is a function block.
      procedure, pass(self) :: save_variable !< Keep a variable's state.
      procedure, pass(self) :: save_array !< Keep an array's state.
      procedure, pass(self) :: restore_array !< Restore a kept array's state.
      procedure, pass(self) :: restore  !< Restore a kept variable's state.
      procedure, pass(self) :: remove   !< Forget a variable.
      procedure, pass(self) :: remove_prefix !< Forget the variables whose name starts with a prefix.
      procedure, pass(self) :: string_of !< Value of a string variable.
      procedure, pass(self) :: text_of  !< Value of a constant expression as text.
      procedure, pass(self), private :: array_index    !< Index of an array, 0 if none.
      procedure, pass(self), private :: function_index !< Index of a function, 0 if none.
      procedure, pass(self), private :: store          !< Set a variable to a typed value.
      procedure, pass(self), private :: variable_index !< Index of a variable, 0 if none.
endtype symbols_object

type :: expression_object
   !< Compiled expression.
   character(len=:),         allocatable :: text          !< Source text.
   type(instruction_object), allocatable :: code(:)       !< Stack code.
   type(name_object),        allocatable :: names(:)      !< Column header names, `column("name")`.
   integer(I4P)                          :: depth = 0_I4P !< Stack size needed.
   logical                               :: recursive = .false. !< Calls of recursive functions (OP_RECURSE).
   logical                               :: degrees = .false. !< Angles of the trigonometric functions in degrees
                                                              !< (gnuplot `set angles degrees`), else radians.
   character(len=:),         allocatable :: timefmt       !< Time format of a time field (`set xdata time`): a plain
                                                          !< column then reads a time with it.
   type(value_list),         allocatable :: lists(:)      !< Arrays and datablocks indexed at run time (`A[$1]`).
   type(name_object),        allocatable :: blocks(:)     !< Function blocks called (OP_BLOCK).
   type(name_object),        allocatable :: stores(:)     !< User variables assigned or read at run time (OP_ASSIGN,
                                                          !< OP_FETCH).
   contains
      procedure, pass(self) :: compile      !< Compile an expression.
      procedure, pass(self) :: set_time     !< Read a plain column as a time.
      procedure, pass(self) :: evaluate     !< Value on a data row.
      procedure, pass(self) :: evaluate_text !< Text on a data row (a label).
      procedure, pass(self) :: table_cell   !< Text of a `plot with table` field on a data row.
      procedure, pass(self) :: uses_text    !< Whether the row cell texts are read.
      procedure, pass(self) :: first_column !< First data column read.
      procedure, pass(self) :: name_count   !< Number of column header names.
      procedure, pass(self) :: name_of      !< A column header name.
      procedure, pass(self) :: reads_column !< Whether a data column is read.
      procedure, pass(self) :: plain_column !< The data column of a plain column field, 0 if none.
      procedure, pass(self) :: resolve      !< Header names to column numbers.
      procedure, pass(self) :: set_column   !< Plain column.
      procedure, pass(self) :: set_name     !< Plain column of a header name.
      procedure, pass(self) :: value_at     !< Value of a function at its variable value.
endtype expression_object

abstract interface
   recursive subroutine block_call_interface(name, args, result, ok, message)
   !< Run the function block `name` on `args` (gnuplot's ARGC, ARGV): its returned value; `ok` false if it failed
   !< (`message`, empty when it returned no value).
   import :: value_object
   character(len=*),              intent(in)  :: name    !< Block name.
   type(value_object),            intent(in)  :: args(:) !< Arguments.
   type(value_object),            intent(out) :: result  !< Returned value.
   logical,                       intent(out) :: ok      !< A value returned.
   character(len=:), allocatable, intent(out) :: message !< Error, empty if none.
   endsubroutine block_call_interface

   subroutine store_interface(name, v)
   !< Set the user variable `name` to `v` (an assignment inside an expression, gnuplot's `(a = 2, a + 1)`).
   import :: value_object
   character(len=*),   intent(in) :: name !< Variable name.
   type(value_object), intent(in) :: v    !< Value.
   endsubroutine store_interface

   subroutine element_store_interface(name, i, v, ok)
   !< Set element `i` of the user array `name` to `v` (`(A[i] = $2)` inside an expression), `ok` false if `i` is out
   !< of range.
   import :: I8P, value_object
   character(len=*),   intent(in)  :: name !< Array name.
   integer(I8P),       intent(in)  :: i    !< Element.
   type(value_object), intent(in)  :: v    !< Value.
   logical,            intent(out) :: ok   !< Stored.
   endsubroutine element_store_interface

   subroutine element_fetch_interface(name, i, v, found, set)
   !< Element `i` of the user array `name` now, `found` false if no such array or `i` is out of range, `set` false if
   !< it has no value.
   import :: I8P, value_object
   character(len=*),   intent(in)  :: name  !< Array name.
   integer(I8P),       intent(in)  :: i     !< Element.
   type(value_object), intent(out) :: v     !< Value.
   logical,            intent(out) :: found !< In range.
   logical,            intent(out) :: set   !< With a value.
   endsubroutine element_fetch_interface

   subroutine fetch_interface(name, v, found)
   !< Value of the user variable `name` now, `found` false if none.
   import :: value_object
   character(len=*),   intent(in)  :: name  !< Variable name.
   type(value_object), intent(out) :: v     !< Value.
   logical,            intent(out) :: found !< A variable of that name.
   endsubroutine fetch_interface
endinterface

procedure(block_call_interface), pointer :: block_hook => null() !< The interpreter's runner of function blocks.
procedure(store_interface),      pointer :: store_hook => null() !< The interpreter's store of a user variable.
procedure(fetch_interface),      pointer :: fetch_hook => null() !< The interpreter's value of a user variable.
procedure(element_store_interface), pointer :: element_hook => null() !< The interpreter's store of an array element.
procedure(element_fetch_interface), pointer :: element_fetch_hook => null() !< The interpreter's array element now.
integer(I8P), save :: rand_seeds(2) = 1234567890_I8P !< gnuplot's rand seeds (L'Ecuyer's combined generator).
character(len=:), allocatable :: block_message                   !< Message of the last function block failure.

contains
   subroutine compile(self, text, iostat, iomsg, variable, degrees, symbols, sampled)
   !< Compile `text`; on error `iostat` is not 0 and `iomsg` names the problem and its position.
   !<
   !< With `variable` (gnuplot's dummy `x`) the expression is a function of it, evaluated by `value_at`; columns are
   !< then errors. The variable is held as the only cell of the row `evaluate` receives. With `degrees` true the
   !< trigonometric functions work in degrees. With `symbols`, user variables are constants of their current values
   !< and user functions are compiled inline (the dummy variable wins over a user variable of its name, as gnuplot).
   !< With `sampled` (blank-separated names), each name reads the data column of its position, everywhere: gnuplot's
   !< sample variables of the `'+'` and `'++'` pseudo-files (`plot sample [t=0:1] '+' using (t):(t**2)`).
   class(expression_object),      intent(inout)        :: self     !< Expression.
   character(len=*),              intent(in)           :: text     !< Source text.
   integer(I4P),                  intent(out)          :: iostat   !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg    !< Error message.
   character(len=*),              intent(in), optional :: variable !< Dummy variable name, for a function.
   logical,                       intent(in), optional :: degrees  !< Angles in degrees.
   type(symbols_object),          intent(in), optional :: symbols  !< User variables and functions.
   character(len=*),              intent(in), optional :: sampled  !< Sample variables, columns 1, 2, ...

   call compile_expression(self, text, iostat, iomsg, variable=variable, degrees=degrees, symbols=symbols, &
                           sampled=sampled)
   endsubroutine compile

   subroutine compile_expression(self, text, iostat, iomsg, variable, degrees, symbols, frame_name, parameters, lenient, &
                                 sampled)
   !< `compile`, and the syntax check of a user function body: `parameters` of the function `frame_name` read the stack
   !< slots from 1, and with `lenient` unknown names and functions are accepted (resolved when called).
   !<
   !< Not recursive (nvfortran 26.9 -O2 then loops on a syntax error): the code it runs while compiling (`system`, the
   !< ends of a slice) calls no function block, so it is never entered again.
   class(expression_object),      intent(inout)        :: self       !< Expression.
   character(len=*),              intent(in)           :: text       !< Source text.
   integer(I4P),                  intent(out)          :: iostat     !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg      !< Error message.
   character(len=*),              intent(in), optional :: variable   !< Dummy variable name, for a function.
   logical,                       intent(in), optional :: degrees    !< Angles in degrees.
   type(symbols_object),          intent(in), optional :: symbols    !< User variables and functions.
   character(len=*),              intent(in), optional :: frame_name !< Function whose body `text` is.
   type(name_object),             intent(in), optional :: parameters(:) !< Its parameters.
   logical,                       intent(in), optional :: lenient    !< Unknown names accepted.
   character(len=*),              intent(in), optional :: sampled    !< Sample variables, columns 1, 2, ...
   character(len=:), allocatable                :: src     !< Text being read (a body while compiled inline).
   type(frame_object), allocatable              :: frames(:) !< User functions being compiled inline, innermost last.
   logical                                      :: loose   !< Unknown names accepted.
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
   integer(I4P)                                 :: guarded !< Inside operands run only if a condition holds (the right
                                                           !< one of `&&`, `||`, the branches of `?:`).
   type(name_object), allocatable               :: procs(:) !< Recursive functions called, compiled after the main code.
   integer(I4P), allocatable                    :: entries(:) !< Their first instructions.
   logical                                      :: in_procedure !< Compiling one of them.

   self%text = text
   if (allocated(self%code)) deallocate(self%code)
   allocate(self%code(0))
   if (allocated(self%names)) deallocate(self%names)
   allocate(self%names(0))
   if (allocated(self%lists)) deallocate(self%lists)
   if (allocated(self%blocks)) deallocate(self%blocks)
   allocate(self%blocks(0))
   if (allocated(self%stores)) deallocate(self%stores)
   allocate(self%stores(0))
   self%depth = 0_I4P
   self%recursive = .false.
   self%degrees = .false.
   if (present(degrees)) self%degrees = degrees
   iostat = 0_I4P
   iomsg = ''
   src = text
   pos = 1_I4P
   depth = 0_I4P
   nesting = 0_I4P
   guarded = 0_I4P
   loose = .false.
   if (present(lenient)) loose = lenient
   allocate(frames(0), procs(0), entries(0))
   in_procedure = .false.
   if (present(parameters)) then
      ! a body checked alone: the parameters on the stack
      call push_frame(frame_name, parameters, 1_I4P)
      depth = size(parameters, kind=I4P)
      self%depth = depth
   endif
   call next
   call parse_ternary
   if (iostat == 0_I4P .and. kind /= T_END) call syntax('unexpected "'//token//'"')
   if (iostat == 0_I4P .and. size(procs) > 0) call compile_procedures
   contains
      subroutine compile_procedures
      !< The bodies of the recursive functions the code calls, after the main code (and its OP_STOP), each once: its
      !< parameters read the slots from its frame, it ends by OP_RETURN; the stack then holds the main code's slots
      !< and MAX_CALLS frames of the deepest body.
      integer(I4P) :: p        !< Procedure counter.
      integer(I4P) :: k        !< Instruction or function index.
      integer(I4P) :: main     !< Stack slots of the main code.

      call emit(OP_STOP)
      main = self%depth
      self%depth = 0_I4P
      in_procedure = .true.
      p = 0_I4P
      do while (p < size(procs, kind=I4P) .and. iostat == 0_I4P)
         ! a body may call other recursive functions: procs grows while compiled
         p = p + 1_I4P
         k = symbols%function_index(procs(p)%text)
         entries = [entries, size(self%code, kind=I4P) + 1_I4P]
         associate(f => symbols%functions(k))
            deallocate(frames)
            allocate(frames(0))
            call push_frame(name=procs(p)%text, params=f%params, base=1_I4P)
            depth = size(f%params, kind=I4P)
            self%depth = max(self%depth, depth)
            src = f%body
            pos = 1_I4P
            call next
            call parse_ternary
            if (iostat == 0_I4P .and. kind /= T_END) call syntax('unexpected "'//token//'"')
            if (iostat /= 0_I4P) iomsg = 'in function '//procs(p)%text//': '//iomsg
            call pop_frame
         endassociate
         call emit(OP_RETURN)
      enddo
      do k = 1_I4P, size(self%code, kind=I4P)
         if (self%code(k)%op == OP_RECURSE) self%code(k)%arg = entries(self%code(k)%arg)
      enddo
      self%depth = main + MAX_CALLS * self%depth
      self%recursive = .true.
      endsubroutine compile_procedures

      subroutine block_call(name, nargs, at)
      !< `$f(args)`, a call of the function block `name` on the `nargs` arguments on the stack, run when evaluated.
      character(len=*), intent(in) :: name  !< Block name.
      integer(I4P),     intent(in) :: nargs !< Arguments.
      integer(I4P),     intent(in) :: at    !< Position.
      type(name_object)            :: item  !< Block name.
      logical                      :: known !< A function block.

      known = .false.
      if (present(symbols)) known = symbols%is_block(name)
      if (.not. known .and. .not. loose) then
         call syntax('Not a function block: '//name, at)
         return
      endif
      ! by components: nvfortran 26.9 miscompiles constructors of types with allocatable components
      item%text = name
      call push_name(self%blocks, item)
      call emit(OP_BLOCK, arg=size(self%blocks, kind=I4P), v=int_value(int(nargs, I8P)))
      endsubroutine block_call

      subroutine recurse_call(name, nargs, at)
      !< A call of the user function `name` being compiled (a recursion): OP_RECURSE to its body, compiled after the
      !< main code; it adds the inline calls it is inside, and itself, to the nested calls (gnuplot's depth).
      character(len=*), intent(in) :: name  !< Function name.
      integer(I4P),     intent(in) :: nargs !< Arguments given.
      integer(I4P),     intent(in) :: at    !< Position.
      integer(I4P)                 :: p     !< Procedure index.
      integer(I4P)                 :: n     !< Parameters.
      integer(I4P)                 :: k     !< Instruction index.
      type(name_object)            :: item  !< New procedure.

      n = size(symbols%functions(symbols%function_index(name))%params, kind=I4P)
      if (nargs /= n) then
         call syntax('function '//name//' requires '//trim(adjustl(int_text(n)))//' variable'// &
                     trim(merge('s', ' ', n /= 1_I4P)), at)
         return
      endif
      p = 0_I4P
      do k = 1_I4P, size(procs, kind=I4P)
         if (procs(k)%text == name) p = k
      enddo
      if (p == 0_I4P) then
         ! by components: nvfortran 26.9 miscompiles constructors of types with allocatable components
         item%text = name
         call push_name(procs, item)
         p = size(procs, kind=I4P)
      endif
      call emit(OP_RECURSE, arg=p, v=int_value(int(nargs, I8P)), k=k)
      ! the callee's depth: the inline calls around, in main code one more (no frame of its own there)
      self%code(k)%calls = size(frames, kind=I4P) + merge(0_I4P, 1_I4P, in_procedure)
      endsubroutine recurse_call

      subroutine syntax(message, at)
      !< Record the first syntax error, at the current token or at `at`.
      character(len=*), intent(in)           :: message !< Error.
      integer(I4P),     intent(in), optional :: at      !< Position.
      character(len=12)                      :: column  !< Position text.

      if (iostat /= 0_I4P) return
      iostat = 1_I4P
      ! the reader stops at an end: every parsing loop tests the token kind, so it ends whatever the optimizer keeps of
      ! iostat (nvfortran 26.9 -O2 loops forever on "0.3*sin(x/4)", x undefined, testing iostat alone)
      kind = T_END
      if (present(at)) then
         write(column, '(I0)') at
      else
         write(column, '(I0)') start
      endif
      iomsg = message//' at character '//trim(column)//' of "'//src//'"'
      endsubroutine syntax

      subroutine next
      !< Read the next token.
      character(len=*), parameter :: DIGITS = '0123456789'
      character(len=*), parameter :: LETTERS = UNAME_START
      integer(I4P)                :: n       !< Text length.
      integer(I4P)                :: ios     !< Conversion status.
      logical                     :: is_real !< Number with a point or an exponent.
      logical                     :: ok      !< Real conversion succeeded.
      character(len=1)            :: quote   !< Opening quote.

      if (iostat /= 0_I4P) then
         kind = T_END
         return
      endif
      n = len(src, kind=I4P)
      do while (pos <= n)
         if (src(pos:pos) /= ' ' .and. src(pos:pos) /= achar(9)) exit
         pos = pos + 1_I4P
      enddo
      start = pos
      if (pos > n) then
         kind = T_END
         token = 'end'
         return
      endif
      if (src(pos:pos) == '0' .and. next_is('xX', 1_I4P) .and. next_is('0123456789abcdefABCDEF', 2_I4P)) then
         ! a hexadecimal integer, gnuplot's 0xff (a real past the largest integer)
         kind = T_NUMBER
         pos = pos + 2_I4P
         call skip('0123456789abcdefABCDEF')
         token = src(start:pos - 1_I4P)
         call radix_number(token(3:), 16_I4P)
      elseif (scan(src(pos:pos), DIGITS) > 0 .or. (src(pos:pos) == '.' .and. next_is(DIGITS, 1_I4P))) then
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
         token = src(start:pos - 1_I4P)
         number = value_object()
         ios = 1_I4P
         if (.not. is_real .and. len(token) > 1 .and. token(1:1) == '0') then
            ! an octal integer, gnuplot's 017 (08 is 0 then an unexpected 8)
            if (verify(token, '01234567') > 0) then
               call syntax('unexpected "'//token(verify(token, '01234567'):)//'"', start + verify(token, '01234567') - 1)
               return
            endif
            call radix_number(token(2:), 8_I4P)
            return
         endif
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
      elseif (src(pos:pos) == '{') then
         ! a complex constant, gnuplot's {re, im}: two numbers
         kind = T_NUMBER
         call complex_constant
         token = src(start:min(pos - 1_I4P, n))
      elseif (src(pos:pos) == '$' .and. next_is(LETTERS, 1_I4P)) then
         ! a datablock name, `$DATA`
         kind = T_NAME
         pos = pos + 1_I4P
         call skip(LETTERS//DIGITS)
         token = src(start:pos - 1_I4P)
      elseif (src(pos:pos) == '$') then
         kind = T_COLUMN
         pos = pos + 1_I4P
         if (.not. next_is(DIGITS, 0_I4P)) then
            call syntax('"$" needs a column number')
            return
         endif
         call skip(DIGITS)
         token = src(start:pos - 1_I4P)
         number = value_object(is_int=.true.)
         read(token(2:), *, iostat=ios) number%i
         if (ios /= 0_I4P .or. number%i > huge(1_I4P)) call syntax('column number too large')
      elseif (src(pos:pos) == '"' .or. src(pos:pos) == "'") then
         ! single quotes literal, double quotes with gnuplot's escapes (gnuplot_escape)
         kind = T_STRING
         quote = src(pos:pos)
         token = ''
         pos = pos + 1_I4P
         do
            ! unterminated: the string ends with the text, as gnuplot's scanner closes it
            if (pos > n) exit
            if (src(pos:pos) == quote) exit
            if (quote == '"' .and. src(pos:pos) == '\' .and. pos < n) then
               pos = pos + 1_I4P
               call gnuplot_escape(src, pos, token)
               cycle
            else
               token = token//src(pos:pos)
            endif
            pos = pos + 1_I4P
         enddo
         pos = pos + 1_I4P
      elseif (scan(src(pos:pos), LETTERS) > 0) then
         kind = T_NAME
         call skip(LETTERS//DIGITS)
         token = src(start:pos - 1_I4P)
      else
         kind = T_OPERATOR
         token = src(pos:min(pos + 1_I4P, n))
         select case (token)
         case ('**', '<=', '>=', '==', '!=', '&&', '||', '<<', '>>')
            pos = pos + 2_I4P
         case default
            token = src(pos:pos)
            pos = pos + 1_I4P
            select case (token)
            case ('+', '-', '*', '/', '%', '!', '<', '>', '?', ':', '(', ')', ',', '.', '[', ']', '|', '&', '^', '~', '=')
               ! `|` a bitwise or, and around an array or a datablock, `|A|`; `=` an assignment, `a = 2`
            case default
               call syntax('unexpected "'//token//'"')
            endselect
         endselect
      endif
      endsubroutine next

      subroutine complex_constant
      !< `number` from the complex constant at `pos` (`{`): `{re, im}`, each part a signed number; `pos` after `}`.
      real(R8P)    :: part(2) !< Real and imaginary parts.
      integer(I4P) :: p       !< Part counter.
      integer(I4P) :: first   !< Start of a number.
      logical      :: ok      !< Number read.

      pos = pos + 1_I4P
      do p = 1_I4P, 2_I4P
         call skip(' '//achar(9))
         first = pos
         if (next_is('+-', 0_I4P)) pos = pos + 1_I4P
         call skip('0123456789.')
         if (next_is('eE', 0_I4P)) then
            pos = pos + 1_I4P
            if (next_is('+-', 0_I4P)) pos = pos + 1_I4P
            call skip('0123456789')
         endif
         ok = pos > first
         if (ok) call real_from_decimal(src(first:pos - 1_I4P), part(p), ok)
         call skip(' '//achar(9))
         if (ok) ok = next_is(merge(',', '}', p == 1_I4P), 0_I4P)
         if (.not. ok) then
            call syntax('invalid complex constant', start)
            return
         endif
         pos = pos + 1_I4P
      enddo
      number = value_object(r=part(1))
      number%im = part(2)
      endsubroutine complex_constant

      subroutine radix_number(digits, radix)
      !< `number` from the `digits` of an integer in base `radix`, a real past the largest integer (gnuplot).
      character(len=*), intent(in) :: digits !< Digits.
      integer(I4P),     intent(in) :: radix  !< Base.
      integer(I4P)                 :: j      !< Digit counter.
      integer(I4P)                 :: d      !< Digit value.
      real(R8P)                    :: r      !< Value as a real.

      number = value_object(is_int=.true.)
      r = 0.0_R8P
      do j = 1_I4P, len(digits, kind=I4P)
         d = index('0123456789abcdef', digits(j:j), kind=I4P) - 1_I4P
         if (d < 0_I4P) d = index('0123456789ABCDEF', digits(j:j), kind=I4P) - 1_I4P
         r = r * radix + d
         if (number%is_int) then
            if (number%i > (MOST - d) / radix) then
               number%is_int = .false.
            else
               number%i = number%i * radix + d
            endif
         endif
      enddo
      if (.not. number%is_int) then
         number%i = 0_I8P
         number%r = r
      endif
      endsubroutine radix_number

      function next_is(set, offset) result(yes)
      !< Whether the character `offset` places after `pos` is in `set`.
      character(len=*), intent(in) :: set    !< Characters.
      integer(I4P),     intent(in) :: offset !< Offset from `pos`.
      logical                      :: yes    !< Character in `set`.

      yes = .false.
      if (pos + offset <= len(src)) yes = scan(src(pos + offset:pos + offset), set) > 0
      endfunction next_is

      subroutine skip(set)
      !< Advance `pos` over characters of `set`.
      character(len=*), intent(in) :: set !< Characters.

      do while (pos <= len(src))
         if (scan(src(pos:pos), set) == 0) exit
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
      call push(self%code, instruction)
      if (present(k)) k = size(self%code, kind=I4P)
      select case (op)
      case (OP_CONSTANT, OP_COLUMN, OP_COLUMN_NAMED, OP_LOAD, OP_FETCH)
         depth = depth + 1_I4P
      case (OP_ADD:OP_NE, OP_CONCAT:OP_STRNE, OP_BAND:OP_SHR, OP_JUMP_UNLESS, OP_AND_JUMP, OP_OR_JUMP, OP_TIMECOLUMN)
         ! the conditional jumps pop on the path that falls through; timecolumn takes the column and the format
         depth = depth - 1_I4P
      case (OP_SUBSTRING)
         depth = depth - 2_I4P
      case (OP_ASSIGN_ELEMENT)
         depth = depth - 1_I4P
      case (OP_CALL, OP_RECURSE, OP_BLOCK)
         depth = depth - (int(instruction%v%i, I4P) - 1_I4P)
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
      if (element_assignment_ahead()) then
         ! `name[i] = value`, an element of a user array set when run (gnuplot's `(A[$0+1] = $2)`); its value the value
         block
            character(len=:), allocatable :: name !< Array.

            name = token
            call next
            call next
            call parse_ternary
            call expect(']')
            call expect('=')
            if (iostat /= 0_I4P) return
            call parse_ternary
            call emit(OP_ASSIGN_ELEMENT, arg=store_slot(name))
         endblock
         nesting = nesting - 1_I4P
         return
      endif
      if (assignment_ahead()) then
         ! `name = value`, gnuplot's assignment operator (right associative, its value the value): stored when run
         block
            character(len=:), allocatable :: name !< Variable.
            integer(I4P)                  :: at   !< Its position.
            integer(I4P)                  :: slot !< Its run time slot.

            name = token
            at = start
            call next
            call next
            call check_name(name, iostat, iomsg)
            if (iostat /= 0_I4P) then
               iostat = 0_I4P
               call syntax(iomsg, at)
               return
            endif
            ! known before the value is compiled: `s = s + $2` reads the variable when run
            slot = store_slot(name)
            call parse_ternary
            call emit(OP_ASSIGN, arg=slot)
         endblock
         nesting = nesting - 1_I4P
         return
      endif
      call parse_binary(1_I4P)
      if (accept('?')) then
         guarded = guarded + 1_I4P
         call emit(OP_JUMP_UNLESS, k=skip_a)
         call parse_ternary
         call expect(':')
         call emit(OP_JUMP, k=skip_b)
         call patch(skip_a)
         depth = depth - 1_I4P ! `b` starts where `a` did
         call parse_ternary
         call patch(skip_b)
         guarded = guarded - 1_I4P
      endif
      nesting = nesting - 1_I4P
      endsubroutine parse_ternary

      function assignment_ahead() result(yes)
      !< Whether the current token is a name followed by `=` (not `==`): an assignment.
      logical      :: yes !< An assignment.
      integer(I4P) :: j   !< Character counter.

      yes = .false.
      if (kind /= T_NAME) return
      if (token(1:1) == '$') return
      j = pos
      do while (j <= len(src, kind=I4P))
         if (src(j:j) /= ' ' .and. src(j:j) /= achar(9)) exit
         j = j + 1_I4P
      enddo
      if (j > len(src, kind=I4P)) return
      if (src(j:j) /= '=') return
      yes = .true.
      if (j < len(src, kind=I4P)) yes = src(j + 1_I4P:j + 1_I4P) /= '='
      endfunction assignment_ahead

      function element_assignment_ahead() result(yes)
      !< Whether the current token is an array of `symbols` followed by `[...]` and `=` (not `==`): an element assigned.
      logical      :: yes   !< An element assignment.
      integer(I4P) :: j     !< Character counter.
      integer(I4P) :: level !< Bracket nesting.
      character    :: quote !< Open quote, blank if none.

      yes = .false.
      if (kind /= T_NAME .or. .not. present(symbols)) return
      if (token(1:1) == '$') return
      if (symbols%array_index(token) == 0_I4P) return
      yes = indexed_assignment_at(pos)
      endfunction element_assignment_ahead

      function indexed_assignment_at(from) result(yes)
      !< Whether `src` from `from` (after a name) is blanks, `[...]`, blanks and `=` (not `==`).
      integer(I4P), intent(in) :: from  !< Start.
      logical                  :: yes   !< `[...] =` follows.
      integer(I4P)             :: j     !< Character counter.
      integer(I4P)             :: level !< Bracket nesting.
      character                :: quote !< Open quote, blank if none.

      yes = .false.
      j = skip_blanks(from)
      if (j > len(src, kind=I4P)) return
      if (src(j:j) /= '[') return
      level = 0_I4P
      quote = ' '
      do while (j <= len(src, kind=I4P))
         if (quote /= ' ') then
            if (src(j:j) == quote) quote = ' '
         elseif (src(j:j) == '"' .or. src(j:j) == "'") then
            quote = src(j:j)
         elseif (src(j:j) == '[') then
            level = level + 1_I4P
         elseif (src(j:j) == ']') then
            level = level - 1_I4P
            if (level == 0_I4P) exit
         endif
         j = j + 1_I4P
      enddo
      if (j > len(src, kind=I4P)) return
      j = skip_blanks(j + 1_I4P)
      if (j > len(src, kind=I4P)) return
      if (src(j:j) /= '=') return
      yes = .true.
      if (j < len(src, kind=I4P)) yes = src(j + 1_I4P:j + 1_I4P) /= '='
      endfunction indexed_assignment_at

      function element_assigned(name) result(yes)
      !< Whether the expression assigns an element of the array `name` anywhere (`name[i] = v`, outside quotes): its
      !< elements are then read when run.
      character(len=*), intent(in) :: name  !< Array name.
      logical                      :: yes   !< An element assigned.
      integer(I4P)                 :: j     !< Character counter.
      integer(I4P)                 :: n     !< Name length.
      character                    :: quote !< Open quote, blank if none.

      yes = .false.
      n = len(name, kind=I4P)
      quote = ' '
      j = 1_I4P
      do while (j <= len(src, kind=I4P) - n + 1_I4P)
         if (quote /= ' ') then
            if (src(j:j) == quote) quote = ' '
         elseif (src(j:j) == '"' .or. src(j:j) == "'") then
            quote = src(j:j)
         elseif (src(j:j + n - 1_I4P) == name) then
            if (name_boundary(j - 1_I4P) .and. name_boundary(j + n)) then
               if (indexed_assignment_at(j + n)) then
                  yes = .true.
                  return
               endif
            endif
         endif
         j = j + 1_I4P
      enddo
      endfunction element_assigned

      function name_boundary(j) result(yes)
      !< Whether `src(j:j)` is not part of a name (or `j` is outside `src`).
      integer(I4P), intent(in) :: j   !< Position.
      logical                  :: yes !< Not a name character.

      yes = .true.
      if (j < 1_I4P .or. j > len(src, kind=I4P)) return
      yes = .not. (verify(src(j:j), UNAME_CHARS//'$') == 0)
      endfunction name_boundary

      function skip_blanks(from) result(j)
      !< The first character of `src` from `from` that is not a blank.
      integer(I4P), intent(in) :: from !< Start.
      integer(I4P)             :: j    !< Character counter.

      j = from
      do while (j <= len(src, kind=I4P))
         if (src(j:j) /= ' ' .and. src(j:j) /= achar(9)) exit
         j = j + 1_I4P
      enddo
      endfunction skip_blanks

      function store_slot(name) result(k)
      !< Index of `name` among the variables assigned or read at run time (`stores`), added if new.
      character(len=*), intent(in) :: name !< Variable.
      integer(I4P)                 :: k    !< Index.
      type(name_object)            :: item !< New name.

      do k = 1_I4P, size(self%stores, kind=I4P)
         if (self%stores(k)%text == name) return
      enddo
      ! by components: nvfortran 26.9 miscompiles constructors of types with allocatable components
      item%text = name
      call push_name(self%stores, item)
      k = size(self%stores, kind=I4P)
      endfunction store_slot

      function run_time_name(name) result(yes)
      !< Whether `name` is assigned by this expression so far, or by a user function body: read when run.
      character(len=*), intent(in) :: name !< Variable.
      logical                      :: yes  !< Read at run time.
      integer(I4P)                 :: k    !< Counter.

      yes = .false.
      do k = 1_I4P, size(self%stores, kind=I4P)
         if (self%stores(k)%text == name) yes = .true.
      enddo
      if (yes .or. .not. present(symbols)) return
      if (.not. allocated(symbols%assigned)) return
      do k = 1_I4P, size(symbols%assigned, kind=I4P)
         if (symbols%assigned(k)%text == name) yes = .true.
      enddo
      endfunction run_time_name

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
      do while (iostat == 0_I4P .and. (kind == T_OPERATOR .or. kind == T_NAME))
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
            guarded = guarded + 1_I4P
            call parse_binary(level + 1_I4P)
            guarded = guarded - 1_I4P
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
      elseif (accept('~')) then
         call parse_unary
         call emit(OP_BNOT)
      else
         call parse_power
      endif
      nesting = nesting - 1_I4P
      endsubroutine parse_unary

      recursive subroutine parse_power
      !< primary [** unary]: right associative, tighter than a unary minus on its left.

      call parse_primary
      do while (accept('['))
         call parse_substring
      enddo
      if (accept('**')) then
         call parse_unary
         call emit(OP_POWER)
      endif
      endsubroutine parse_power

      recursive subroutine parse_substring
      !< `[i:j]` after a string: either end may be `*` or nothing (the first or the last character).

      if (iostat /= 0_I4P) return
      if (kind == T_OPERATOR .and. token == ':') then
         call emit(OP_CONSTANT, v=int_value(1_I8P))
      elseif (accept('*')) then
         call emit(OP_CONSTANT, v=int_value(1_I8P))
      else
         call parse_ternary
      endif
      call expect(':')
      if (iostat /= 0_I4P) return
      if (kind == T_OPERATOR .and. token == ']') then
         call emit(OP_CONSTANT, v=int_value(MOST))
      elseif (accept('*')) then
         call emit(OP_CONSTANT, v=int_value(MOST))
      else
         call parse_ternary
      endif
      call expect(']')
      call emit(OP_SUBSTRING)
      endsubroutine parse_substring

      recursive subroutine parse_primary
      !< Number, column, constant, function call or parenthesized expression.
      character(len=:), allocatable :: name  !< Function name.
      integer(I4P)                  :: at    !< Name position.
      integer(I4P)                  :: nargs !< Arguments given.
      integer(I4P)                  :: f     !< Function index.
      integer(I4P)                  :: first !< First instruction of the arguments.

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
         if (name == 'sum' .and. kind == T_OPERATOR .and. token == '[') then
            call sum_expression
            return
         endif
         if (.not. (kind == T_OPERATOR .and. token == '(')) then
            call name_value(name, at)
            return
         endif
         call next
         if (name == 'exist') name = 'exists'
         if ((name == 'value' .or. name == 'exists') .and. kind == T_STRING) then
            call symbol_query(name)
            return
         elseif (name == 'value' .or. name == 'exists') then
            call syntax(name//' takes a quoted variable name', at)
            return
         endif
         if (name == 'index' .and. kind == T_NAME) then
            if (token == 'split') then
               block
                  type(value_list) :: list !< Its elements.

                  call split_call(list)
                  if (iostat /= 0_I4P) return
                  call array_find(list, at, named=.false.)
               endblock
               return
            endif
            if (present(symbols)) then
               if (symbols%array_index(token) > 0_I4P) then
                  call array_find(symbols%arrays(symbols%array_index(token))%list, at)
                  return
               endif
            endif
         endif
         if (name == 'join') then
            call join_call(at)
            return
         endif
         if (name == 'split') then
            call syntax('split() is an array: assign it (A = split(s)), print it, size it |split(s)|, or pass it to '// &
                        'index() or join()', at)
            return
         endif
         if (name == 'column' .and. kind == T_STRING) then
            if (present(variable)) then
               call syntax('columns are only valid in using, not in a function', at)
               return
            endif
            call push(self%names, name_object(token))
            call next
            call expect(')')
            call emit(OP_COLUMN_NAMED, arg=size(self%names, kind=I4P))
            return
         endif
         nargs = 0_I4P
         first = size(self%code, kind=I4P) + 1_I4P
         if (.not. (kind == T_OPERATOR .and. token == ')')) then
            do
               call parse_ternary
               nargs = nargs + 1_I4P
               if (.not. accept(',')) exit
            enddo
         endif
         call expect(')')
         if (iostat /= 0_I4P) return
         if (name(1:1) == '$') then
            call block_call(name, nargs, at)
            return
         endif
         if (name == 'rand') then
            ! gnuplot's pseudo-random numbers: run on each evaluation
            if (nargs /= 1_I4P) then
               call syntax('rand needs 1 argument', at)
            else
               call emit(OP_RAND)
            endif
            return
         endif
         if (any(MATH_FUNCTIONS == name)) then
            ! gnuplot's special functions (foresight_mathlib)
            f = findloc(MATH_FUNCTIONS, name, dim=1)
            if ((name == 'weekdate_iso' .or. name == 'weekdate_cdc') .and. nargs == 2_I4P) then
               ! the day omitted: the first of the week
               call emit(OP_CONSTANT, v=int_value(1_I8P))
               nargs = 3_I4P
            endif
            if (nargs /= MATH_ARGS(f)) then
               call syntax(name//' needs '//trim(adjustl(int_text(MATH_ARGS(f))))//' argument'// &
                           trim(merge('s', ' ', MATH_ARGS(f) /= 1_I4P)), at)
            else
               call emit(OP_SPECIAL, arg=f)
            endif
            return
         endif
         f = findloc(FUNCTIONS, name, dim=1)
         if (any(STRING_FUNCTIONS == name)) then
            f = findloc(STRING_FUNCTIONS, name, dim=1)
            if (nargs < LEAST_ARGS(f) .or. nargs > MOST_ARGS(f)) then
               if (LEAST_ARGS(f) == MOST_ARGS(f)) then
                  call syntax(name//' needs '//trim(adjustl(int_text(LEAST_ARGS(f))))//' argument'// &
                              trim(merge('s', ' ', LEAST_ARGS(f) /= 1_I4P)), at)
               else
                  call syntax(name//' needs a format', at)
               endif
               return
            endif
            call emit(OP_CALL, arg=f, v=int_value(int(nargs, I8P)))
         elseif (name == 'atan2') then
            if (nargs /= 2_I4P) call syntax('atan2 needs 2 arguments', at)
            call emit(OP_ATAN2)
         elseif (name == 'timecolumn') then
            if (present(variable)) then
               call syntax(name//' is only valid in using, not in a function', at)
            elseif (nargs /= 1_I4P .and. nargs /= 2_I4P) then
               call syntax(name//' needs a column and an optional time format', at)
            else
               ! without a format, the timefmt now
               if (nargs == 1_I4P) then
                  if (present(symbols)) then
                     if (allocated(symbols%timefmt)) then
                        call emit(OP_CONSTANT, v=string_value(symbols%timefmt))
                     else
                        call emit(OP_CONSTANT, v=string_value(DEFAULT_TIMEFMT))
                     endif
                  else
                     call emit(OP_CONSTANT, v=string_value(DEFAULT_TIMEFMT))
                  endif
               endif
               call emit(OP_TIMECOLUMN)
            endif
         elseif (name == 'system') then
            if (nargs /= 1_I4P) then
               call syntax('system needs 1 argument, a shell command', at)
            else
               call run_system(first, at)
            endif
         elseif (name == 'time') then
            ! time(0) the integer seconds now, time(0.0) with their fraction, time("format") the time now as text: a
            ! constant of the compilation
            if (nargs /= 1_I4P) then
               call syntax('time needs 1 argument', at)
            else
               call time_now
            endif
         elseif (any(ROW_FUNCTIONS == name)) then
            if (present(variable)) then
               call syntax(name//' is only valid in using, not in a function', at)
            elseif (nargs /= 1_I4P) then
               call syntax(name//' needs 1 argument', at)
            elseif (name(1:3) == 'str') then
               call emit(OP_STRCOL)
            else
               call emit(OP_COLUMNHEAD)
            endif
         elseif (name == 'column' .and. present(variable)) then
            call syntax('columns are only valid in using, not in a function', at)
         elseif (name == 'column' .or. f > 0) then
            if (nargs /= 1_I4P) call syntax(name//' needs 1 argument', at)
            if (name == 'column') then
               call column_of
            else
               call emit(OP_FUNCTION, arg=f)
            endif
         else
            call user_call(name, nargs, at)
         endif
      case (T_STRING)
         call emit(OP_CONSTANT, v=string_value(token))
         call next
      case (T_OPERATOR)
         if (accept('(')) then
            call parse_ternary
            ! gnuplot's serial evaluation `(a, b)`: each evaluated, the last the value
            do while (accept(','))
               call parse_ternary
               call emit(OP_COLLAPSE, arg=1_I4P)
               depth = depth - 1_I4P
            enddo
            call expect(')')
         elseif (accept('|')) then
            call cardinality
         else
            call syntax('unexpected "'//token//'"')
         endif
      case default
         call syntax('unexpected end')
      endselect
      endsubroutine parse_primary

      subroutine cardinality
      !< `|A|`, the size of an array, or `|$D|`, the lines of a datablock: the current token the name.
      integer(I4P) :: n  !< Size.
      integer(I4P) :: at !< Name position.
      integer(I4P) :: j  !< Character counter.
      character(len=:), allocatable :: text  !< Datablock lines.
      logical                       :: found !< A datablock.
      character(len=:), allocatable :: name  !< Array name.
      integer(I4P)                  :: k     !< Array index.
      logical                       :: sliced !< A slice read.

      at = start
      name = token
      n = -1_I4P
      if (kind == T_NAME .and. token == 'split') then
         ! the size of gnuplot's split(), |split(s)|
         block
            type(value_list) :: list !< Its elements.

            call split_call(list)
            if (iostat /= 0_I4P) return
            call expect('|')
            if (iostat /= 0_I4P) return
            call emit(OP_CONSTANT, v=int_value(int(size(list%items), I8P)))
         endblock
         return
      endif
      if (kind == T_NAME .and. present(symbols)) then
         if (symbols%is_array(token)) then
            n = symbols%array_size(token)
         elseif (token(1:1) == '$') then
            call symbols%string_of(token, text, found)
            if (found) then
               n = 0_I4P
               do j = 1_I4P, len(text, kind=I4P)
                  if (text(j:j) == new_line('a')) n = n + 1_I4P
               enddo
            endif
         endif
      endif
      if (n < 0_I4P) then
         if (loose .and. kind == T_NAME) then
            n = 0_I4P
         else
            call syntax('|...| takes an array or a datablock', at)
            return
         endif
      endif
      call next
      if (present(symbols) .and. kind == T_OPERATOR .and. token == '[') then
         k = symbols%array_index(name)
         if (k > 0_I4P) then
            ! the size of a slice, |A[i:j]|
            call next
            call element(symbols%arrays(k)%list, name, at, sizing=.true., sliced=sliced)
            if (iostat == 0_I4P .and. .not. sliced) call syntax('|...| takes an array or a datablock', at)
            call expect('|')
            return
         endif
      endif
      call expect('|')
      if (iostat /= 0_I4P) return
      call emit(OP_CONSTANT, v=int_value(int(n, I8P)))
      endsubroutine cardinality

      recursive subroutine split_call(list)
      !< gnuplot 6.0 `split(string [, separator])`, its arguments known now: the current token is `split`, left after the
      !< closing parenthesis.
      type(value_list), intent(out) :: list  !< The pieces.
      type(value_object)            :: text  !< String.
      type(value_object)            :: sep   !< Separator.
      integer(I4P)                  :: first !< First instruction of an argument.
      integer(I4P)                  :: at    !< Call position.

      allocate(list%items(0), list%set(0))
      at = start
      call next
      call expect('(')
      first = size(self%code, kind=I4P) + 1_I4P
      call parse_ternary
      call fold(first, text)
      sep = string_value(' ')
      if (accept(',')) then
         first = size(self%code, kind=I4P) + 1_I4P
         call parse_ternary
         call fold(first, sep)
      endif
      call expect(')')
      if (iostat /= 0_I4P) return
      if (.not. (text%is_string .and. sep%is_string)) then
         call syntax('split takes strings: split("string" [, "separator"])', at)
         return
      endif
      list = split_list(text%s, sep%s)
      endsubroutine split_call

      recursive subroutine join_call(at)
      !< gnuplot 6.0 `join(A, separator)` (A an array or `split(...)`, the separator known now): the text of the string
      !< elements, the separator between every two elements (other elements add none), a constant; the current token
      !< follows the parenthesis.
      integer(I4P), intent(in)      :: at    !< Call position.
      type(value_list)              :: list  !< Elements.
      type(value_object)            :: sep   !< Separator.
      integer(I4P)                  :: first !< First instruction of the separator.
      integer(I4P)                  :: k     !< Element counter.
      integer(I4P)                  :: a     !< Array index.
      character(len=:), allocatable :: text  !< Joined text.

      if (kind == T_NAME .and. token == 'split') then
         call split_call(list)
      elseif (kind == T_NAME .and. present(symbols)) then
         a = symbols%array_index(token)
         if (a == 0_I4P) then
            call syntax('join: expecting join(array, "separator")', at)
            return
         endif
         ! through an index variable: nvfortran 26.9 stops ("bad dtype") on the array indexed by the function result
         list = symbols%arrays(a)%list
         call next
      else
         call syntax('join: expecting join(array, "separator")', at)
         return
      endif
      call expect(',')
      first = size(self%code, kind=I4P) + 1_I4P
      call parse_ternary
      call fold(first, sep)
      call expect(')')
      if (iostat /= 0_I4P) return
      if (.not. sep%is_string) then
         call syntax('join: expecting join(array, "separator")', at)
         return
      endif
      text = ''
      do k = 1_I4P, size(list%items, kind=I4P)
         if (list%set(k)) then
            if (list%items(k)%is_string) text = text//list%items(k)%s
         endif
         if (k < size(list%items, kind=I4P)) text = text//sep%s
      enddo
      call emit(OP_CONSTANT, v=string_value(text))
      endsubroutine join_call

      recursive subroutine array_find(list, at, named)
      !< `index(A, value)`: the first element of `list` equal to the value (numbers by value, strings by text), 0 if
      !< none; the current token is the array name (after it with `named` false: `split(...)` read), the value a constant.
      type(value_list), intent(in)           :: list  !< Array elements.
      integer(I4P),     intent(in)           :: at    !< Call position.
      logical,          intent(in), optional :: named !< The current token is the array name.
      integer(I4P)                           :: last  !< Last instruction.
      integer(I4P)                           :: k     !< Element counter.
      integer(I8P)                           :: found !< Index found.

      if (.not. present(named)) then
         call next
      elseif (named) then
         call next
      endif
      call expect(',')
      call parse_ternary
      call expect(')')
      if (iostat /= 0_I4P) return
      last = size(self%code, kind=I4P)
      if (self%code(last)%op /= OP_CONSTANT) then
         call syntax('index(A, value) takes a constant value', at)
         return
      endif
      found = 0_I8P
      associate(v => self%code(last)%v)
         do k = 1_I4P, size(list%items, kind=I4P)
            if (.not. list%set(k)) cycle
            if (v%is_string .neqv. list%items(k)%is_string) cycle
            if (v%is_string) then
               if (v%s /= list%items(k)%s) cycle
            elseif (real_of(v) /= real_of(list%items(k)) .or. v%im /= list%items(k)%im) then
               cycle
            endif
            found = int(k, I8P)
            exit
         enddo
      endassociate
      self%code(last)%v = int_value(found)
      endsubroutine array_find

      recursive subroutine element(list, name, at, sizing, sliced)
      !< `name[i]`, an element of `list` (an array, or the lines of a datablock): the current token follows `[`. A
      !< constant index is resolved now, another at run time. `name[i:j][k]` is an element of a slice; with `sizing`
      !< (inside `|...|`) a slice `name[i:j]` alone leaves its size as a constant.
      type(value_list), intent(in)           :: list   !< Elements.
      character(len=*), intent(in)           :: name   !< Array or datablock name.
      integer(I4P),     intent(in)           :: at     !< Name position.
      logical,          intent(in), optional :: sizing !< Inside `|...|`.
      logical,          intent(out), optional :: sliced !< A slice was read.
      integer(I4P)                 :: last  !< Last instruction.
      integer(I8P)                 :: i     !< Index.
      logical                      :: found !< A numeric index.
      integer(I4P)                 :: first !< First instruction of the index.
      type(value_list)             :: piece !< A slice.
      logical                      :: size_only !< Inside `|...|`.

      size_only = .false.
      if (present(sizing)) size_only = sizing
      if (present(sliced)) sliced = .false.

      first = size(self%code, kind=I4P) + 1_I4P
      if (kind == T_OPERATOR .and. (token == ':' .or. token == '*')) then
         ! a slice from the first element, A[:j] or A[*:j]
         if (token == '*') call next
         call emit(OP_CONSTANT, v=int_value(1_I8P))
      else
         call parse_ternary
      endif
      if (iostat /= 0_I4P) return
      if (kind == T_OPERATOR) then
         if (token == ':') then
            call slice(list, first, piece)
            if (iostat /= 0_I4P) return
            if (present(sliced)) sliced = .true.
            if (accept('[')) then
               ! an element of the slice, A[i:j][k]
               call element(piece, name//'[i:j]', at)
            elseif (size_only) then
               call emit(OP_CONSTANT, v=int_value(int(size(piece%items), I8P)))
            elseif (.not. size_only) then
               call syntax('the slice '//name//'[i:j] is an array: print it, size it |'//name//'[i:j]| or assign it', &
                           at)
            endif
            return
         endif
      endif
      call expect(']')
      if (iostat /= 0_I4P) return
      if (element_assigned(name)) then
         ! an array this expression assigns elements of: read when run
         call emit(OP_FETCH_ELEMENT, arg=store_slot(name))
         return
      endif
      last = size(self%code, kind=I4P)
      if (self%code(last)%op == OP_CONSTANT) then
         call index_of(self%code(last)%v, i, found)
         if (.not. found) then
            call syntax('array index of '//name//' is not a number', at)
            return
         elseif (i >= 1_I8P .and. i <= size(list%items, kind=I8P)) then
            if (list%set(i)) then
               self%code(last)%v = list%items(i)
               return
            endif
         endif
         ! out of range or without a value: known when (if) it is evaluated, as gnuplot (1 ? 5 : A[9] is 5)
      endif
      call push(self%lists, list)
      call emit(OP_ELEMENT, arg=size(self%lists, kind=I4P))
      endsubroutine element

      recursive subroutine slice(list, first, piece)
      !< `[i:j]` of `list`: the instructions from `first` its first end, the current token `:`; both ends known now
      !< (an empty or `*` end is the first or the last element), clamped to the list, as gnuplot.
      type(value_list), intent(in)  :: list  !< Elements.
      integer(I4P),     intent(in)  :: first !< First instruction of the first end.
      type(value_list), intent(out) :: piece !< The slice.
      type(value_object)            :: v     !< An end.
      integer(I8P)                  :: ends(2) !< First and last index.
      logical                       :: found !< A numeric end.
      integer(I4P)                  :: second !< First instruction of the second end.

      call fold(first, v)
      if (iostat /= 0_I4P) return
      call index_of(v, ends(1), found)
      if (.not. found) call syntax('a slice needs numeric ends')
      call next
      if (kind == T_OPERATOR .and. (token == ']' .or. token == '*')) then
         if (token == '*') call next
         ends(2) = size(list%items, kind=I8P)
      else
         second = size(self%code, kind=I4P) + 1_I4P
         call parse_ternary
         call fold(second, v)
         if (iostat /= 0_I4P) return
         call index_of(v, ends(2), found)
         if (.not. found) call syntax('a slice needs numeric ends')
      endif
      call expect(']')
      if (iostat /= 0_I4P) return
      piece = slice_list(list, ends(1), ends(2))
      endsubroutine slice

      subroutine fold(first, v)
      !< The value of the instructions from `first` on, known now (no column, no function argument), then dropped.
      integer(I4P),       intent(in)  :: first   !< First instruction.
      type(value_object), intent(out) :: v       !< Value.
      type(expression_object)         :: part    !< The instructions alone.
      logical                         :: defined !< Defined.
      integer(I4P)                    :: error   !< Type error.
      integer(I4P)                    :: k       !< Instruction counter.

      v = int_value(1_I8P)
      if (iostat /= 0_I4P) return
      if (loose) then
         call truncate_to(first)
         depth = depth - 1_I4P
         return
      endif
      do k = first, size(self%code, kind=I4P)
         select case (self%code(k)%op)
         case (OP_COLUMN, OP_COLUMN_NAMED, OP_COLUMN_OF, OP_LOAD, OP_STRCOL, OP_COLUMNHEAD, OP_TIMECOLUMN, OP_RECURSE, &
               OP_BLOCK)
            call syntax('the ends of a slice are known now: no column, no function argument, no function block')
            return
         endselect
      enddo
      part%code = self%code(first:)
      do k = 1_I4P, size(part%code, kind=I4P)
         select case (part%code(k)%op)
         case (OP_JUMP, OP_JUMP_UNLESS, OP_AND_JUMP, OP_OR_JUMP)
            part%code(k)%arg = part%code(k)%arg - first + 1_I4P
         endselect
      enddo
      part%depth = self%depth
      part%degrees = self%degrees
      if (allocated(self%lists)) part%lists = self%lists
      allocate(part%names(0))
      part%stores = self%stores
      call run(part, [real(R8P) ::], 0_I4P, v, defined, error)
      if (.not. defined) call syntax(error_text(error))
      depth = depth - 1_I4P
      call truncate_to(first)
      endsubroutine fold

      subroutine run_system(first, at)
      !< `system(command)`, the instructions from `first` its argument: the command, known now (no column, no argument
      !< of a user function), runs now and its standard output (one trailing newline dropped) replaces it, as gnuplot.
      !< A function body checked alone does not run it.
      integer(I4P), intent(in)      :: first   !< First instruction of the argument.
      integer(I4P), intent(in)      :: at      !< Call position.
      type(expression_object)       :: command !< The argument alone.
      type(value_object)            :: v       !< Its value.
      character(len=:), allocatable :: output  !< Command output.
      logical                       :: defined !< Defined.
      integer(I4P)                  :: error   !< Type error.
      integer(I4P)                  :: status  !< Exit status.
      integer(I4P)                  :: k       !< Instruction counter.

      if (iostat /= 0_I4P) return
      if (loose) then
         call truncate_to(first)
         call emit(OP_CONSTANT, v=string_value(''))
         depth = depth - 1_I4P
         return
      endif
      do k = first, size(self%code, kind=I4P)
         select case (self%code(k)%op)
         case (OP_COLUMN, OP_COLUMN_NAMED, OP_COLUMN_OF, OP_LOAD, OP_STRCOL, OP_COLUMNHEAD, OP_TIMECOLUMN, OP_RECURSE, &
               OP_BLOCK)
            call syntax('system takes a command known now: no column, no function argument, no recursion, no '// &
                        'function block', at)
            return
         endselect
      enddo
      ! the argument's instructions alone, their jump targets moved with them
      command%code = self%code(first:)
      do k = 1_I4P, size(command%code, kind=I4P)
         select case (command%code(k)%op)
         case (OP_JUMP, OP_JUMP_UNLESS, OP_AND_JUMP, OP_OR_JUMP)
            command%code(k)%arg = command%code(k)%arg - first + 1_I4P
         endselect
      enddo
      command%depth = self%depth
      command%degrees = self%degrees
      if (allocated(self%lists)) command%lists = self%lists
      allocate(command%names(0))
      call run(command, [real(R8P) ::], 0_I4P, v, defined, error)
      if (.not. defined) then
         call syntax('system: '//error_text(error), at)
         return
      elseif (.not. v%is_string) then
         call syntax('system takes a string, the shell command', at)
         return
      endif
      flush(output_unit)
      call command_output(v%s, output, status)
      if (len(output) > 0) then
         if (output(len(output):len(output)) == new_line('a')) output = output(1:len(output) - 1)
      endif
      call truncate_to(first)
      call emit(OP_CONSTANT, v=string_value(output))
      depth = depth - 1_I4P
      endsubroutine run_system

      subroutine truncate_to(first)
      !< Drop the instructions from `first` on.
      integer(I4P), intent(in)              :: first !< First instruction dropped.
      type(instruction_object), allocatable :: kept(:) !< Instructions kept.

      kept = self%code(1:first - 1_I4P)
      call move_alloc(kept, self%code)
      endsubroutine truncate_to

      subroutine time_now
      !< `time(x)`, the last instruction its argument: the time now (UTC) replaces it, as an integer (`x` an integer), a
      !< real (`x` a real) or, `x` a format, as the text `strftime(x, now)`.
      integer(I4P) :: last     !< Last instruction.
      integer(I4P) :: dt(8)    !< date_and_time values.
      real(R8P)    :: now      !< Seconds since 1970 UTC.
      type(value_object) :: v  !< Result.

      last = size(self%code, kind=I4P)
      if (self%code(last)%op /= OP_CONSTANT) then
         call syntax('time takes a constant: time(0), time(0.0) or time("format")')
         return
      endif
      call date_and_time(values=dt)
      now = civil_time(int(dt(1), I8P), int(dt(2), I8P), int(dt(3), I8P), int(dt(5), I8P), int(dt(6), I8P), &
                       real(dt(7), R8P) + 0.001_R8P * real(dt(8), R8P)) - 60.0_R8P * real(dt(4), R8P)
      if (self%code(last)%v%is_string) then
         v = string_value(strftime(self%code(last)%v%s, now))
      elseif (self%code(last)%v%is_int) then
         v = int_value(floor(now, I8P))
      else
         v = value_object(r=now)
      endif
      self%code(last)%v = v
      endsubroutine time_now

      subroutine column_of
      !< `column(...)`: of a string constant (a user variable), the column of that header, as `column("name")`.
      integer(I4P) :: last !< Last instruction.

      last = size(self%code, kind=I4P)
      if (last > 0_I4P) then
         if (self%code(last)%op == OP_CONSTANT .and. self%code(last)%v%is_string) then
            call push(self%names, name_object(self%code(last)%v%s))
            self%code(last)%op = OP_COLUMN_NAMED
            self%code(last)%arg = size(self%names, kind=I4P)
            self%code(last)%v = value_object()
            return
         endif
      endif
      call emit(OP_COLUMN_OF)
      endsubroutine column_of

      subroutine symbol_query(name)
      !< `value("name")` (the variable's value, NaN if none) or `exists("name")` (1 or 0), resolved now: the current
      !< token is the quoted name.
      character(len=*), intent(in) :: name !< `value` or `exists`.
      integer(I4P)                 :: k    !< Variable index.

      logical                      :: is_array !< An array.

      k = 0_I4P
      is_array = .false.
      if (present(symbols)) then
         k = symbols%variable_index(token)
         is_array = symbols%array_index(token) > 0_I4P
      endif
      call next
      call expect(')')
      if (iostat /= 0_I4P) return
      if (name == 'exists') then
         call emit(OP_CONSTANT, v=logical_value(k > 0_I4P .or. is_array))
      elseif (k > 0_I4P) then
         call emit(OP_CONSTANT, v=symbols%variables(k)%v)
      else
         call emit(OP_CONSTANT, v=value_object(r=ieee_value(1.0_R8P, ieee_quiet_nan)))
      endif
      endsubroutine symbol_query

      function is_variable(name) result(yes)
      !< Whether `name` is the dummy variable (not seen inside a user function body).
      character(len=*), intent(in) :: name !< Name.
      logical                      :: yes  !< The variable.

      integer(I4P)                 :: f    !< Frame.

      yes = .false.
      if (.not. present(variable)) return
      ! inside `sum` frames only, the dummy variable is still seen
      do f = 1_I4P, size(frames, kind=I4P)
         if (frames(f)%name /= SUM_FRAME) return
      enddo
      yes = name == variable
      endfunction is_variable

      function sampled_column(name) result(k)
      !< Position of `name` among the sample variables (`sampled`), 0 if none.
      character(len=*), intent(in)  :: name !< Name.
      integer(I4P)                  :: k    !< Position.
      character(len=:), allocatable :: rest !< Names not yet compared.
      integer(I4P)                  :: w    !< Word counter.
      integer(I4P)                  :: b    !< Blank after the word.

      k = 0_I4P
      if (.not. present(sampled)) return
      rest = trim(adjustl(sampled))
      w = 0_I4P
      do while (len(rest) > 0)
         w = w + 1_I4P
         b = index(rest, ' ', kind=I4P)
         if (b == 0_I4P) b = len(rest, kind=I4P) + 1_I4P
         if (rest(1:b - 1_I4P) == name) then
            k = w
            return
         endif
         if (b > len(rest, kind=I4P)) exit
         rest = trim(adjustl(rest(b:)))
      enddo
      endfunction sampled_column

      recursive subroutine name_value(name, at)
      !< A name alone: a parameter of the function being compiled inline, the dummy variable, a user variable, `pi`.
      character(len=*), intent(in) :: name !< Name.
      integer(I4P),     intent(in) :: at   !< Position.
      integer(I4P)                 :: k    !< Parameter or variable index.

      ! the innermost frame, and those around a `sum` (whose variable alone it binds)
      block
         integer(I4P) :: f !< Frame.

         do f = size(frames, kind=I4P), 1_I4P, -1_I4P
            do k = 1_I4P, size(frames(f)%params, kind=I4P)
               if (frames(f)%params(k)%text == name) then
                  call emit(OP_LOAD, arg=frames(f)%base + k - 1_I4P)
                  return
               endif
            enddo
            if (frames(f)%name /= SUM_FRAME) exit
         enddo
      endblock
      ! a sample variable of a pseudo-file, its column (gnuplot sets a user variable: seen in function bodies too)
      k = sampled_column(name)
      if (k > 0_I4P) then
         call emit(OP_COLUMN, arg=k)
         return
      endif
      if (is_variable(name)) then
         call emit(OP_COLUMN, arg=1_I4P)
         return
      endif
      k = 0_I4P
      if (present(symbols)) k = symbols%array_index(name)
      if (k > 0_I4P) then
         if (.not. (kind == T_OPERATOR .and. token == '[')) then
            call syntax('array '//name//' needs an index, '//name//'[i], or |'//name//'|', at)
            return
         endif
         call next
         call element(symbols%arrays(k)%list, name, at)
         return
      endif
      if (present(symbols)) k = symbols%variable_index(name)
      if (run_time_name(name)) then
         ! a variable an expression assigns: its value when run (its value now if the store has none)
         block
            type(value_object) :: now   !< Value now.
            integer(I4P)       :: index !< Instruction index.

            now = value_object()
            if (k > 0_I4P) now = symbols%variables(k)%v
            call emit(OP_FETCH, arg=store_slot(name), v=now, k=index)
            self%code(index)%calls = merge(1_I4P, 0_I4P, k > 0_I4P)
         endblock
         return
      endif
      if (k > 0_I4P .and. name(1:1) == '$' .and. kind == T_OPERATOR .and. token == '[') then
         ! a datablock line, `$D[i]`
         if (symbols%variables(k)%v%is_string) then
            call next
            block
               type(value_list) :: lines !< Datablock lines.

               lines = lines_list(symbols%variables(k)%v%s)
               call element(lines, name, at)
            endblock
            return
         endif
      endif
      if (k == 0_I4P .and. loose .and. kind == T_OPERATOR .and. token == '[') then
         ! an array not yet declared, in a function body checked alone: its element stands for it
         call next
         call parse_ternary
         call expect(']')
         return
      endif
      if (k > 0_I4P) then
         call emit(OP_CONSTANT, v=symbols%variables(k)%v)
      elseif (name == 'pi') then
         call emit(OP_CONSTANT, v=value_object(r=PI))
      elseif (name == 'I') then
         ! gnuplot 6.0's imaginary unit, {0,1} (a variable a script may redefine, as pi)
         block
            type(value_object) :: unit !< {0,1}.

            unit%im = 1.0_R8P
            call emit(OP_CONSTANT, v=unit)
         endblock
      elseif (name == 'NaN') then
         ! gnuplot's predefined NaN (a variable a script may redefine, as pi)
         call emit(OP_CONSTANT, v=value_object(r=ieee_value(1.0_R8P, ieee_quiet_nan)))
      elseif (loose) then
         call emit(OP_CONSTANT, v=value_object())
      elseif (guarded > 0_I4P) then
         ! in an operand run only if a condition holds (`exists("Q") && Q == 1`, gnuplot's idiom): read when run, an
         ! undefined variable error then if it still has no value
         block
            integer(I4P) :: index !< Instruction index.

            call emit(OP_FETCH, arg=store_slot(name), v=value_object(), k=index)
            self%code(index)%calls = 0_I4P
         endblock
      else
         call syntax('undefined variable: '//name, at)
      endif
      endsubroutine name_value

      recursive subroutine user_call(name, nargs, at)
      !< A call of the user function `name` whose `nargs` arguments are on the stack: its body compiled inline, the
      !< arguments then dropped under its value.
      character(len=*), intent(in) :: name  !< Function name.
      integer(I4P),     intent(in) :: nargs !< Arguments given.
      integer(I4P),     intent(in) :: at    !< Position.
      character(len=:), allocatable :: saved_src   !< Reader state of the caller.
      character(len=:), allocatable :: saved_token !< Current token of the caller.
      type(value_object)            :: saved_number !< Current number of the caller.
      integer(I4P)                  :: saved(3)    !< Position, kind and start of the caller's token.
      integer(I4P)                  :: k           !< Function index.
      integer(I4P)                  :: n           !< Parameters.

      k = 0_I4P
      if (present(symbols)) k = symbols%function_index(name)
      if (size(frames) > 0 .and. k > 0_I4P) then
         do n = 1_I4P, size(frames, kind=I4P)
            if (frames(n)%name /= name) cycle
            if (loose) then
               ! a body checked alone calling itself (or an older definition): as an unknown function
               k = 0_I4P
            else
               call recurse_call(name, nargs, at)
               return
            endif
            exit
         enddo
      endif
      if (k == 0_I4P) then
         if (loose) then
            ! unknown here, resolved where the body is used: its value stands for the call
            if (nargs == 0_I4P) then
               call emit(OP_CONSTANT, v=value_object())
            elseif (nargs > 1_I4P) then
               call emit(OP_COLLAPSE, arg=nargs - 1_I4P)
               depth = depth - (nargs - 1_I4P)
            endif
         else
            call syntax('unknown function "'//name//'"', at)
         endif
         return
      endif
      associate(f => symbols%functions(k))
         n = size(f%params, kind=I4P)
         if (nargs /= n) then
            call syntax('function '//name//' requires '//trim(adjustl(int_text(n)))//' variable'// &
                        trim(merge('s', ' ', n /= 1_I4P)), at)
            return
         endif
         call push_frame(name=name, params=f%params, base=depth - nargs + 1_I4P)
         if (in_procedure) then
            ! inside a called body the nesting is known at run time: its frame is the first, this call the last
            call emit(OP_DEPTH, k=n)
            self%code(n)%calls = size(frames, kind=I4P) - 1_I4P
            n = size(f%params, kind=I4P)
         endif
         saved_src = src
         saved_token = token
         saved_number = number
         saved = [pos, kind, start]
         src = f%body
         pos = 1_I4P
         call next
         call parse_ternary
         if (iostat == 0_I4P .and. kind /= T_END) call syntax('unexpected "'//token//'"')
         if (iostat /= 0_I4P) iomsg = 'in function '//name//': '//iomsg
         src = saved_src
         token = saved_token
         number = saved_number
         pos = saved(1)
         kind = saved(2)
         start = saved(3)
         call pop_frame
      endassociate
      if (iostat /= 0_I4P) return
      if (nargs > 0_I4P) then
         call emit(OP_COLLAPSE, arg=nargs)
         depth = depth - nargs
      endif
      endsubroutine user_call

      recursive subroutine sum_expression
      !< gnuplot `sum [VAR = START:END] EXPRESSION`, the current token `[`: the ends known now (integers), the expression
      !< compiled once per value of VAR (a stack slot read as a function argument, the names around still seen) and the
      !< terms added; an empty range is the integer 0, as gnuplot. EXPRESSION extends as far as an expression goes.
      character(len=:), allocatable :: var      !< Summation variable.
      character(len=:), allocatable :: body_token !< First token of the expression.
      type(value_object)            :: v        !< An end.
      type(value_object)            :: body_number !< Its number.
      integer(I8P)                  :: ends(2)  !< First and last values.
      integer(I8P)                  :: i        !< Value.
      integer(I4P)                  :: body(3)  !< Reader state at the expression: position, kind, start.
      integer(I4P)                  :: first    !< First instruction of an end.
      integer(I4P)                  :: j        !< Character counter.
      logical                       :: found    !< A numeric end.
      type(name_object)             :: param(1) !< VAR, as a parameter (components, not a constructor: nvfortran).
      character(len=*), parameter   :: NAME_CHARS = UNAME_CHARS

      if (in_procedure) then
         call syntax('sum is not supported inside a function block')
         return
      endif
      ! `VAR =`, read from the text (a lone = is no operator)
      j = pos
      do while (j <= len(src, kind=I4P))
         if (src(j:j) /= ' ') exit
         j = j + 1_I4P
      enddo
      start = j
      do while (j <= len(src, kind=I4P))
         if (scan(src(j:j), NAME_CHARS) == 0) exit
         j = j + 1_I4P
      enddo
      var = src(start:j - 1_I4P)
      param(1)%text = var
      do while (j <= len(src, kind=I4P))
         if (src(j:j) /= ' ') exit
         j = j + 1_I4P
      enddo
      if (len(var) == 0 .or. j > len(src, kind=I4P)) then
         call syntax('expecting sum [<var> = <start>:<end>] <expression>')
         return
      endif
      if (src(j:j) /= '=' .or. scan(var(1:1), UNAME_START) == 0) then
         call syntax('expecting sum [<var> = <start>:<end>] <expression>')
         return
      endif
      pos = j + 1_I4P
      call next
      if (iostat /= 0_I4P) return
      do j = 1_I4P, 2_I4P
         first = size(self%code, kind=I4P) + 1_I4P
         call parse_ternary
         if (iostat /= 0_I4P) return
         call fold(first, v)
         if (iostat /= 0_I4P) return
         call index_of(v, ends(j), found)
         if (.not. found) then
            call syntax('the ends of a sum are integers')
            return
         endif
         call expect(trim(merge(':', ']', j == 1_I4P)))
         if (iostat /= 0_I4P) return
      enddo
      if (loose) ends(2) = ends(1)
      if (ends(2) - ends(1) >= 10000_I8P) then
         call syntax('a sum of more than 10000 terms is not supported')
         return
      endif
      body = [pos, kind, start]
      body_token = token
      body_number = number
      i = ends(1)
      do
         ! one term: VAR's value pushed, the expression compiled reading it, then VAR dropped under the term
         pos = body(1)
         kind = body(2)
         start = body(3)
         token = body_token
         number = body_number
         call emit(OP_CONSTANT, v=int_value(i))
         call push_frame(name=SUM_FRAME, params=param, base=depth)
         call parse_ternary
         call pop_frame
         if (iostat /= 0_I4P) return
         call emit(OP_COLLAPSE, arg=1_I4P)
         depth = depth - 1_I4P
         if (ends(2) < ends(1)) then
            ! an empty sum: 0, the expression read once to pass it
            call emit(OP_CONSTANT, v=int_value(0_I8P))
            call emit(OP_COLLAPSE, arg=1_I4P)
            depth = depth - 1_I4P
            exit
         endif
         if (i > ends(1)) call emit(OP_ADD)
         if (i >= ends(2)) exit
         i = i + 1_I8P
      enddo
      endsubroutine sum_expression

      subroutine push_frame(name, params, base)
      !< Push the frame of a user function compiled inline (by a temporary: see `push`).
      character(len=*),  intent(in)   :: name      !< Function name.
      type(name_object), intent(in)   :: params(:) !< Parameter names.
      integer(I4P),      intent(in)   :: base      !< Stack slot of the first argument.
      type(frame_object), allocatable :: grown(:)  !< Frames, one more.
      integer(I4P)                    :: n         !< Frames before the push.

      n = size(frames, kind=I4P)
      allocate(grown(n + 1_I4P))
      grown(1:n) = frames
      grown(n + 1_I4P)%name = name
      grown(n + 1_I4P)%params = params
      grown(n + 1_I4P)%base = base
      call move_alloc(grown, frames)
      endsubroutine push_frame

      subroutine pop_frame
      !< Pop the innermost frame (by a temporary: see `push`).
      type(frame_object), allocatable :: shrunk(:) !< Frames, one less.

      shrunk = frames(1:size(frames) - 1)
      call move_alloc(shrunk, frames)
      endsubroutine pop_frame

      pure function int_text(n) result(s)
      !< Decimal text of `n`.
      integer(I4P), intent(in) :: n !< Number.
      character(len=12)        :: s !< Text.

      write(s, '(I0)') n
      endfunction int_text
   endsubroutine compile_expression

   recursive subroutine assign(self, name, text, iostat, iomsg, degrees)
   !< gnuplot `name = text`: the value of the expression now, integer, real or string, kept as a constant (a
   !< redefinition replaces it). Columns, undefined values (`1/0`), type errors and bad names are errors.
   class(symbols_object),         intent(inout), target :: self    !< Symbols.
   character(len=*),              intent(in)           :: name    !< Variable name.
   character(len=*),              intent(in)           :: text    !< Expression.
   integer(I4P),                  intent(out)          :: iostat  !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg   !< Error message.
   logical,                       intent(in), optional :: degrees !< Angles in degrees.
   type(expression_object)                             :: e       !< Compiled expression.
   type(value_object)                                  :: v       !< Value.
   logical                                             :: defined !< Defined.
   integer(I4P)                                        :: error   !< Type error.

   call check_name(name, iostat, iomsg)
   if (iostat /= 0_I4P) return
   call e%compile(text, iostat, iomsg, degrees=degrees, symbols=self)
   if (iostat /= 0_I4P) return
   if (e%first_column() > 0_I4P .or. any(e%code%op == OP_COLUMN) .or. any(e%code%op == OP_COLUMN_OF) .or. &
       size(e%names) > 0) then
      iostat = 1_I4P
      iomsg = 'columns are only valid in using, not in "'//name//' = '//text//'"'
      return
   endif
   call run(e, [real(R8P) ::], 0_I4P, v, defined, error)
   ! gnuplot's undefined value assigns nothing
   if (.not. defined .and. error == E_UNDEF) return
   if (.not. defined) then
      iostat = 1_I4P
      if (error /= E_NONE) then
         iomsg = error_text(error)//': '//name//' = '//text
      else
         iomsg = 'undefined value: '//name//' = '//text
      endif
      return
   endif
   call self%store(name, v)
   endsubroutine assign

   subroutine define(self, name, params, body, iostat, iomsg)
   !< gnuplot `name(params) = body`: the body is checked now, its names resolved when the function is called (a
   !< redefinition replaces it). Builtin function names, repeated or bad parameter names and recursion are errors.
   class(symbols_object),         intent(inout) :: self      !< Symbols.
   character(len=*),              intent(in)    :: name      !< Function name.
   character(len=*),              intent(in)    :: params(:) !< Parameter names.
   character(len=*),              intent(in)    :: body      !< Body.
   integer(I4P),                  intent(out)   :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg     !< Error message.
   type(expression_object)                      :: e         !< Body check.
   type(name_object), allocatable               :: names(:)  !< Parameters.
   type(user_function)                          :: fn        !< New function.
   integer(I4P)                                 :: k         !< Counter.
   integer(I4P)                                 :: j         !< Earlier parameter counter.

   call check_name(name, iostat, iomsg)
   if (iostat /= 0_I4P) return
   if (any(FUNCTIONS == name) .or. any(STRING_FUNCTIONS == name) .or. any(ROW_FUNCTIONS == name) .or. &
       any(MATH_FUNCTIONS == name) .or. &
       name == 'atan2' .or. name == 'column' .or. name == 'value' .or. name == 'exists' .or. name == 'time') then
      iostat = 1_I4P
      iomsg = '"'//name//'" is a builtin function'
      return
   endif
   allocate(names(0))
   do k = 1_I4P, size(params, kind=I4P)
      call check_name(trim(params(k)), iostat, iomsg)
      if (iostat /= 0_I4P) return
      do j = 1_I4P, size(names, kind=I4P)
         if (names(j)%text == trim(params(k))) then
            iostat = 1_I4P
            iomsg = 'repeated parameter "'//trim(params(k))//'" of '//name
            return
         endif
      enddo
      call push(names, name_object(trim(params(k))))
   enddo
   call compile_expression(e, body, iostat, iomsg, symbols=self, frame_name=name, parameters=names, lenient=.true.)
   if (iostat /= 0_I4P) then
      iomsg = 'in function '//name//': '//iomsg
      return
   endif
   ! the variables the body assigns are read at run time wherever compiled from now on
   if (.not. allocated(self%assigned)) allocate(self%assigned(0))
   if (allocated(e%stores)) then
      do k = 1_I4P, size(e%stores, kind=I4P)
         if (.not. any_name(self%assigned, e%stores(k)%text)) call push_name(self%assigned, e%stores(k))
      enddo
   endif
   ! by components: nvfortran 26.9 blanks `body` in user_function(name=name, params=names, body=body)
   fn%name = name
   fn%params = names
   fn%body = body
   if (.not. allocated(self%functions)) allocate(self%functions(0))
   k = self%function_index(name)
   if (k > 0_I4P) then
      self%functions(k) = fn
   else
      call push(self%functions, fn)
   endif
   endsubroutine define

   recursive subroutine constant(self, text, v, iostat, iomsg, degrees)
   !< Value of the constant expression `text` (numbers, user variables and functions, `pi`), as a range end
   !< `[0:2*pi]`; columns and undefined values are errors.
   class(symbols_object),         intent(in), target   :: self    !< Symbols.
   character(len=*),              intent(in)           :: text    !< Expression.
   real(R8P),                     intent(out)          :: v       !< Value.
   integer(I4P),                  intent(out)          :: iostat  !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg   !< Error message.
   logical,                       intent(in), optional :: degrees !< Angles in degrees.
   type(expression_object)                             :: e       !< Compiled expression.
   type(value_object)                                  :: value   !< Typed value.
   logical                                             :: defined !< Defined.
   integer(I4P)                                        :: error   !< Type error.

   v = 0.0_R8P
   call e%compile(text, iostat, iomsg, degrees=degrees, symbols=self)
   if (iostat /= 0_I4P) return
   if (any(e%code%op == OP_COLUMN) .or. any(e%code%op == OP_COLUMN_OF) .or. size(e%names) > 0) then
      iostat = 1_I4P
      iomsg = 'columns are only valid in using, not in "'//text//'"'
      return
   endif
   call run(e, [real(R8P) ::], 0_I4P, value, defined, error)
   if (defined .and. value%is_string) call numeric(value, defined, error)
   if (.not. defined) then
      iostat = 1_I4P
      if (error /= E_NONE) then
         iomsg = error_text(error)//': '//text
      else
         iomsg = 'undefined value: '//text
      endif
      return
   endif
   v = real_of(value)
   endsubroutine constant

   recursive subroutine text_of(self, text, value, is_string, iostat, iomsg, degrees)
   !< Value of the constant expression `text` as text: a string as it is (`is_string`), a number as gnuplot's `print`
   !< shows it (`3`, `2.5`, `100.0`, `1e+20`). Columns, undefined values and type errors are errors.
   class(symbols_object),         intent(in), target   :: self      !< Symbols.
   character(len=*),              intent(in)           :: text      !< Expression.
   character(len=:), allocatable, intent(out)          :: value     !< Value as text.
   logical,                       intent(out)          :: is_string !< A string.
   integer(I4P),                  intent(out)          :: iostat    !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg     !< Error message.
   logical,                       intent(in), optional :: degrees   !< Angles in degrees.
   type(expression_object)                             :: e         !< Compiled expression.
   type(value_object)                                  :: v         !< Typed value.
   logical                                             :: defined   !< Defined.
   integer(I4P)                                        :: error     !< Type error.

   value = ''
   is_string = .false.
   call e%compile(text, iostat, iomsg, degrees=degrees, symbols=self)
   if (iostat /= 0_I4P) return
   if (any(e%code%op == OP_COLUMN) .or. any(e%code%op == OP_COLUMN_OF) .or. size(e%names) > 0) then
      iostat = 1_I4P
      iomsg = 'columns are only valid in using, not in "'//text//'"'
      return
   endif
   call run(e, [real(R8P) ::], 0_I4P, v, defined, error)
   if (.not. defined .and. error == E_UNDEF) then
      ! gnuplot's print of the undefined value
      value = '<undefined>'
      return
   endif
   if (.not. defined) then
      iostat = 1_I4P
      if (error /= E_NONE) then
         iomsg = error_text(error)//': '//text
      else
         iomsg = 'undefined value: '//text
      endif
      return
   endif
   is_string = v%is_string
   value = number_text(v)
   endsubroutine text_of

   pure subroutine clear(self)
   !< Forget every variable and function.
   class(symbols_object), intent(inout) :: self !< Symbols.

   if (allocated(self%variables)) deallocate(self%variables)
   if (allocated(self%functions)) deallocate(self%functions)
   if (allocated(self%arrays)) deallocate(self%arrays)
   if (allocated(self%assigned)) deallocate(self%assigned)
   endsubroutine clear

   pure subroutine set_value(self, name, v, is_int)
   !< Set the variable `name` to the real `v` (an integer with `is_int`), creating it: `fit` sets its parameters and
   !< results so. The name is not checked.
   class(symbols_object), intent(inout) :: self   !< Symbols.
   character(len=*),      intent(in)    :: name   !< Variable name.
   real(R8P),             intent(in)    :: v      !< Value.
   logical,               intent(in)    :: is_int !< Integer value.
   type(value_object)                   :: value  !< Value.
   value%is_int = is_int
   if (is_int) then
      value%i = nint(v, I8P)
      value%r = real(value%i, R8P)
   else
      value%r = v
   endif
   call self%store(name, value)
   endsubroutine set_value

   pure subroutine set_string(self, name, text)
   !< Set the variable `name` to the string `text`, creating it. The name is not checked.
   class(symbols_object), intent(inout) :: self !< Symbols.
   character(len=*),      intent(in)    :: name !< Variable name.
   character(len=*),      intent(in)    :: text !< Value.

   call self%store(name, string_value(text))
   endsubroutine set_string

   pure subroutine save_variable(self, name, saved)
   !< The state of the variable `name` (its value, or that it does not exist), for `restore`.
   class(symbols_object), intent(in)  :: self  !< Symbols.
   character(len=*),      intent(in)  :: name  !< Variable name.
   type(saved_variable),  intent(out) :: saved !< State.
   integer(I4P)                       :: k     !< Index.

   saved%name = name
   k = self%variable_index(name)
   saved%found = k > 0_I4P
   if (saved%found) saved%v = self%variables(k)%v
   endsubroutine save_variable

   pure subroutine restore(self, saved)
   !< Restore a variable kept by `save_variable`: its value, or remove it if it did not exist.
   class(symbols_object), intent(inout) :: self  !< Symbols.
   type(saved_variable),  intent(in)    :: saved !< State.
   type(user_variable), allocatable     :: kept(:) !< Variables but the removed one.
   integer(I4P)                         :: k     !< Index.
   integer(I4P)                         :: j     !< Counter.

   if (saved%found) then
      call self%store(saved%name, saved%v)
      return
   endif
   k = self%variable_index(saved%name)
   if (k == 0_I4P) return
   ! by a push loop into another variable: nvfortran 26.9 corrupts `list = list(...)` of items holding deferred-length
   ! characters
   allocate(kept(0))
   do j = 1_I4P, size(self%variables, kind=I4P)
      if (j /= k) call push(kept, self%variables(j))
   enddo
   call move_alloc(kept, self%variables)
   endsubroutine restore

   pure subroutine remove(self, name)
   !< Forget the variable `name`, if it exists.
   class(symbols_object), intent(inout) :: self  !< Symbols.
   character(len=*),      intent(in)    :: name  !< Variable name.
   type(saved_variable)                 :: none  !< A variable that did not exist.

   type(user_array), allocatable        :: kept(:) !< Arrays but the removed one.
   integer(I4P)                         :: k     !< Index.
   integer(I4P)                         :: j     !< Counter.

   none%name = name
   none%found = .false.
   call self%restore(none)
   k = self%array_index(name)
   if (k == 0_I4P) return
   allocate(kept(0))
   do j = 1_I4P, size(self%arrays, kind=I4P)
      if (j /= k) call push(kept, self%arrays(j))
   enddo
   call move_alloc(kept, self%arrays)
   endsubroutine remove

   pure subroutine remove_prefix(self, prefix)
   !< Forget every variable whose name starts with `prefix` (gnuplot `undefine prefix*`).
   class(symbols_object), intent(inout) :: self    !< Symbols.
   character(len=*),      intent(in)    :: prefix  !< Name prefix.
   type(user_variable), allocatable     :: kept(:) !< Variables kept.
   type(user_array), allocatable        :: arrays(:) !< Arrays kept.
   integer(I4P)                         :: k       !< Counter.

   if (allocated(self%arrays)) then
      allocate(arrays(0))
      do k = 1_I4P, size(self%arrays, kind=I4P)
         if (index(self%arrays(k)%name, prefix) == 1) cycle
         call push(arrays, self%arrays(k))
      enddo
      call move_alloc(arrays, self%arrays)
   endif
   if (.not. allocated(self%variables)) return
   allocate(kept(0))
   do k = 1_I4P, size(self%variables, kind=I4P)
      if (index(self%variables(k)%name, prefix) == 1) cycle
      call push(kept, self%variables(k))
   enddo
   call move_alloc(kept, self%variables)
   endsubroutine remove_prefix

   pure subroutine string_of(self, name, text, found)
   !< Value of the string variable `name`; `found` false (and `text` empty) if there is none or it is a number.
   class(symbols_object),         intent(in)  :: self  !< Symbols.
   character(len=*),              intent(in)  :: name  !< Variable name.
   character(len=:), allocatable, intent(out) :: text  !< Value.
   logical,                       intent(out) :: found !< A string variable found.
   integer(I4P)                               :: k     !< Index.

   text = ''
   k = self%variable_index(name)
   found = k > 0_I4P
   if (.not. found) return
   found = self%variables(k)%v%is_string
   if (found) text = self%variables(k)%v%s
   endsubroutine string_of

   pure subroutine put(self, name, v)
   !< Set the variable `name` to the typed value `v`, creating it: an assignment run by an expression (`store_hook`).
   class(symbols_object), intent(inout) :: self !< Symbols.
   character(len=*),      intent(in)    :: name !< Variable name.
   type(value_object),    intent(in)    :: v    !< Value.

   call self%store(name, v)
   endsubroutine put

   pure subroutine get(self, name, v, found)
   !< Typed value of the variable `name`, `found` false (and `v` empty) if none.
   class(symbols_object), intent(in)  :: self  !< Symbols.
   character(len=*),      intent(in)  :: name  !< Variable name.
   type(value_object),    intent(out) :: v     !< Value.
   logical,               intent(out) :: found !< A variable of that name.
   integer(I4P)                       :: k     !< Index.

   v = value_object()
   k = self%variable_index(name)
   found = k > 0_I4P
   if (found) v = self%variables(k)%v
   endsubroutine get

   pure subroutine store(self, name, v)
   !< Set the variable `name` to `v`, creating it (by components: nvfortran 26.9 corrupts constructors of types holding
   !< deferred-length characters).
   class(symbols_object), intent(inout) :: self !< Symbols.
   character(len=*),      intent(in)    :: name !< Variable name.
   type(value_object),    intent(in)    :: v    !< Value.
   type(user_variable)                  :: item !< New variable.
   integer(I4P)                         :: k    !< Index.

   if (.not. allocated(self%variables)) allocate(self%variables(0))
   k = self%variable_index(name)
   if (k > 0_I4P) then
      self%variables(k)%v = v
      self%variables(k)%block = .false.
   else
      item%name = name
      item%v = v
      call push(self%variables, item)
   endif
   endsubroutine store

   pure subroutine define_block(self, name, body)
   !< gnuplot 6.0 `function $name << EOF ... EOF`: the function block `name`, its body the lines `body`.
   class(symbols_object), intent(inout) :: self !< Symbols.
   character(len=*),      intent(in)    :: name !< Block name, `$f`.
   character(len=*),      intent(in)    :: body !< Its lines, each ended by a new line.

   call self%store(name, string_value(body))
   self%variables(self%variable_index(name))%block = .true.
   endsubroutine define_block

   pure function is_block(self, name) result(yes)
   !< Whether `name` is a function block.
   class(symbols_object), intent(in) :: self !< Symbols.
   character(len=*),      intent(in) :: name !< Name.
   logical                           :: yes  !< A function block.
   integer(I4P)                      :: k    !< Variable index.

   yes = .false.
   k = self%variable_index(name)
   if (k > 0_I4P) yes = self%variables(k)%block
   endfunction is_block

   pure subroutine value_of(self, name, v, found, is_int)
   !< Value of the variable `name` (real), `found` false (and NaN) if none; `is_int` whether an integer.
   class(symbols_object), intent(in)            :: self   !< Symbols.
   character(len=*),      intent(in)            :: name   !< Variable name.
   real(R8P),             intent(out)           :: v      !< Value.
   logical,               intent(out)           :: found  !< Variable found.
   logical,               intent(out), optional :: is_int !< Integer value.
   integer(I4P)                                 :: k      !< Index.

   v = ieee_value(1.0_R8P, ieee_quiet_nan)
   if (present(is_int)) is_int = .false.
   k = self%variable_index(name)
   found = k > 0_I4P
   if (.not. found) return
   if (self%variables(k)%v%is_string) then
      ! a string variable: its leading number, NaN if none
      block
         type(value_object) :: number !< Its number.
         logical            :: ok     !< A number read.
         integer(I4P)       :: err    !< Type error.

         number = self%variables(k)%v
         ok = .true.
         call numeric(number, ok, err)
         if (ok) v = real_of(number)
         if (present(is_int)) is_int = ok .and. number%is_int
      endblock
      return
   endif
   v = real_of(self%variables(k)%v)
   if (present(is_int)) is_int = self%variables(k)%v%is_int
   endsubroutine value_of

   recursive subroutine declare_array(self, name, size_text, items, iostat, iomsg, degrees)
   !< gnuplot `array name[size_text]`, its elements without a value, or with the values of the constant expressions
   !< `items` (`array A[3] = [1, 2, 3]`, `array A = [...]`, `size_text` empty: the items' number). A redeclaration
   !< replaces the array; a variable of the name is removed.
   class(symbols_object),         intent(inout), target :: self     !< Symbols.
   character(len=*),              intent(in)           :: name     !< Array name.
   character(len=*),              intent(in)           :: size_text !< Size expression, empty for the items' number.
   character(len=*),              intent(in), optional :: items(:) !< Element expressions.
   integer(I4P),                  intent(out)          :: iostat   !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg    !< Error message.
   logical,                       intent(in), optional :: degrees  !< Angles in degrees.
   type(user_array)                                    :: a        !< New array.
   type(value_object)                                  :: v        !< Value.
   real(R8P)                                           :: r        !< Size.
   integer(I4P)                                        :: n        !< Size.
   integer(I4P)                                        :: k        !< Counter.

   call check_name(name, iostat, iomsg)
   if (iostat /= 0_I4P) return
   if (len_trim(size_text) > 0) then
      call self%constant(size_text, r, iostat, iomsg, degrees=degrees)
      if (iostat /= 0_I4P) return
      if (r < 0.0_R8P .or. r > real(huge(1_I4P), R8P)) then
         iostat = 1_I4P
         iomsg = 'array '//name//': a size of 0 or more is expected'
         return
      endif
      n = int(r, I4P)
   elseif (present(items)) then
      n = size(items, kind=I4P)
   else
      iostat = 1_I4P
      iomsg = 'array '//name//': a size [N] or the elements = [...] are expected'
      return
   endif
   if (present(items)) then
      if (size(items) > n) then
         iostat = 1_I4P
         iomsg = 'array '//name//': more elements than its size'
         return
      endif
   endif
   allocate(a%list%items(n), a%list%set(n))
   a%list%set = .false.
   if (present(items)) then
      do k = 1_I4P, size(items, kind=I4P)
         call self%evaluate_constant(items(k), v, iostat, iomsg, degrees)
         if (iostat /= 0_I4P) then
            iomsg = 'array '//name//': '//iomsg
            return
         endif
         a%list%items(k) = v
         a%list%set(k) = .true.
      enddo
   endif
   a%name = name
   call self%remove(name)
   if (.not. allocated(self%arrays)) allocate(self%arrays(0))
   call push(self%arrays, a)
   endsubroutine declare_array

   recursive subroutine assign_element(self, name, index_text, text, iostat, iomsg, degrees)
   !< gnuplot `name[index_text] = text`: the element of the array set to the value of the expression now.
   class(symbols_object),         intent(inout), target :: self       !< Symbols.
   character(len=*),              intent(in)           :: name       !< Array name.
   character(len=*),              intent(in)           :: index_text !< Index expression.
   character(len=*),              intent(in)           :: text       !< Value expression.
   integer(I4P),                  intent(out)          :: iostat     !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg      !< Error message.
   logical,                       intent(in), optional :: degrees    !< Angles in degrees.
   type(value_object)                                  :: v          !< Value.
   type(value_object)                                  :: at         !< Index value.
   integer(I8P)                                        :: i          !< Index.
   integer(I4P)                                        :: k          !< Array index.
   logical                                             :: found      !< A numeric index.

   k = self%array_index(name)
   if (k == 0_I4P) then
      iostat = 1_I4P
      iomsg = name//' is not an array (array '//name//'[N] declares one)'
      return
   endif
   call self%evaluate_constant(index_text, at, iostat, iomsg, degrees)
   if (iostat /= 0_I4P) return
   call index_of(at, i, found)
   if (.not. found) then
      iostat = 1_I4P
      iomsg = 'array index of '//name//' is not a number: '//index_text
      return
   endif
   if (i < 1_I8P .or. i > size(self%arrays(k)%list%items, kind=I8P)) then
      iostat = 1_I4P
      iomsg = 'array index out of range: '//name//'['//index_text//']'
      return
   endif
   call self%evaluate_constant(text, v, iostat, iomsg, degrees)
   if (iostat /= 0_I4P) return
   self%arrays(k)%list%items(i) = v
   self%arrays(k)%list%set(i) = .true.
   endsubroutine assign_element

   pure subroutine set_element(self, name, i, v, ok)
   !< Set element `i` of the array `name` to the typed value `v`, `ok` false if no such array or `i` is out of range.
   class(symbols_object), intent(inout) :: self !< Symbols.
   character(len=*),      intent(in)    :: name !< Array name.
   integer(I8P),          intent(in)    :: i    !< Element.
   type(value_object),    intent(in)    :: v    !< Value.
   logical,               intent(out)   :: ok   !< Set.
   integer(I4P)                         :: k    !< Array index.

   k = self%array_index(name)
   ok = k > 0_I4P
   if (ok) ok = i >= 1_I8P .and. i <= size(self%arrays(k)%list%items, kind=I8P)
   if (.not. ok) return
   self%arrays(k)%list%items(i) = v
   self%arrays(k)%list%set(i) = .true.
   endsubroutine set_element

   pure subroutine learn_assigned(self, e)
   !< The variables the expression `e` assigns (`name = value`) read at run time wherever compiled from now on, as
   !< those of a user function body: `using (Total = $2 + $3):($4 / Total)`.
   class(symbols_object),   intent(inout) :: self !< Symbols.
   type(expression_object), intent(in)    :: e    !< Compiled expression.
   integer(I4P)                           :: k    !< Store counter.
   integer(I4P)                           :: c    !< Instruction counter.

   if (.not. allocated(e%stores) .or. .not. allocated(e%code)) return
   if (.not. allocated(self%assigned)) allocate(self%assigned(0))
   do c = 1_I4P, size(e%code, kind=I4P)
      if (e%code(c)%op /= OP_ASSIGN) cycle
      k = e%code(c)%arg
      if (k < 1_I4P .or. k > size(e%stores, kind=I4P)) cycle
      if (.not. any_name(self%assigned, e%stores(k)%text)) call push_name(self%assigned, e%stores(k))
   enddo
   endsubroutine learn_assigned

   pure subroutine get_element(self, name, i, v, found, set)
   !< Typed value of element `i` of the array `name`, `found` false if no such array or `i` is out of range, `set`
   !< false if the element has no value.
   class(symbols_object), intent(in)  :: self  !< Symbols.
   character(len=*),      intent(in)  :: name  !< Array name.
   integer(I8P),          intent(in)  :: i     !< Element.
   type(value_object),    intent(out) :: v     !< Value.
   logical,               intent(out) :: found !< In range.
   logical,               intent(out) :: set   !< With a value.
   integer(I4P)                       :: k     !< Array index.

   v = value_object()
   set = .false.
   k = self%array_index(name)
   found = k > 0_I4P
   if (found) found = i >= 1_I8P .and. i <= size(self%arrays(k)%list%items, kind=I8P)
   if (.not. found) return
   set = self%arrays(k)%list%set(i)
   if (set) v = self%arrays(k)%list%items(i)
   endsubroutine get_element

   recursive subroutine evaluate_constant(self, text, v, iostat, iomsg, degrees, undefined)
   !< Typed value of the constant expression `text`: columns, undefined values and type errors are errors; with
   !< `undefined` gnuplot's undefined value is not (`v%is_undef`, a function block's `return A[9]`).
   class(symbols_object),         intent(in), target   :: self    !< Symbols.
   character(len=*),              intent(in)           :: text    !< Expression.
   type(value_object),            intent(out)          :: v       !< Value.
   integer(I4P),                  intent(out)          :: iostat  !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg   !< Error message.
   logical,                       intent(in), optional :: degrees !< Angles in degrees.
   logical,                       intent(in), optional :: undefined !< gnuplot's undefined value accepted.
   type(expression_object)                             :: e       !< Compiled expression.
   logical                                             :: defined !< Defined.
   integer(I4P)                                        :: error   !< Type error.

   call e%compile(text, iostat, iomsg, degrees=degrees, symbols=self)
   if (iostat /= 0_I4P) return
   if (any(e%code%op == OP_COLUMN) .or. any(e%code%op == OP_COLUMN_OF) .or. size(e%names) > 0) then
      iostat = 1_I4P
      iomsg = 'columns are only valid in using, not in "'//text//'"'
      return
   endif
   call run(e, [real(R8P) ::], 0_I4P, v, defined, error)
   if (.not. defined .and. error == E_UNDEF .and. present(undefined)) then
      if (undefined) then
         v%is_undef = .true.
         return
      endif
   endif
   if (.not. defined) then
      iostat = 1_I4P
      if (error /= E_NONE) then
         iomsg = error_text(error)//': '//text
      else
         iomsg = 'undefined value: '//text
      endif
   endif
   endsubroutine evaluate_constant

   pure subroutine set_array(self, name, texts)
   !< Set the array `name` to the strings `texts` (gnuplot's `ARGV`), replacing it. The name is not checked.
   class(symbols_object), intent(inout) :: self     !< Symbols.
   character(len=*),      intent(in)    :: name     !< Array name.
   character(len=*),      intent(in)    :: texts(:) !< Elements, trailing blanks dropped.
   type(user_array)                     :: a        !< New array.
   integer(I4P)                         :: k        !< Counter.

   allocate(a%list%items(size(texts)), a%list%set(size(texts)))
   do k = 1_I4P, size(texts, kind=I4P)
      a%list%items(k) = string_value(trim(texts(k)))
   enddo
   a%list%set = .true.
   a%name = name
   call self%remove(name)
   if (.not. allocated(self%arrays)) allocate(self%arrays(0))
   call push(self%arrays, a)
   endsubroutine set_array

   pure subroutine save_array(self, name, saved)
   !< The state of the array `name` (its elements, or that it does not exist), for `restore_array`.
   class(symbols_object), intent(in)  :: self  !< Symbols.
   character(len=*),      intent(in)  :: name  !< Array name.
   type(saved_array),     intent(out) :: saved !< State.
   integer(I4P)                       :: k     !< Index.

   saved%a%name = name
   k = self%array_index(name)
   saved%found = k > 0_I4P
   if (saved%found) saved%a%list = self%arrays(k)%list
   endsubroutine save_array

   pure subroutine restore_array(self, saved)
   !< Restore an array kept by `save_array`: its elements, or remove it if it did not exist.
   class(symbols_object), intent(inout) :: self  !< Symbols.
   type(saved_array),     intent(in)    :: saved !< State.

   call self%remove(saved%a%name)
   if (.not. saved%found) return
   if (.not. allocated(self%arrays)) allocate(self%arrays(0))
   call push(self%arrays, saved%a)
   endsubroutine restore_array

   pure subroutine datablock_names(self, names)
   !< Names of the datablocks (the variables named `$NAME`).
   class(symbols_object),         intent(in)  :: self     !< Symbols.
   character(len=:), allocatable, intent(out) :: names(:) !< Names, blank padded.
   integer(I4P)                               :: width    !< Longest name.
   integer(I4P)                               :: n        !< Datablocks.
   integer(I4P)                               :: k        !< Counter.

   width = 1_I4P
   n = 0_I4P
   if (allocated(self%variables)) then
      do k = 1_I4P, size(self%variables, kind=I4P)
         if (self%variables(k)%name(1:1) /= '$') cycle
         n = n + 1_I4P
         width = max(width, len(self%variables(k)%name, kind=I4P))
      enddo
   endif
   allocate(character(len=width) :: names(n))
   n = 0_I4P
   if (allocated(self%variables)) then
      do k = 1_I4P, size(self%variables, kind=I4P)
         if (self%variables(k)%name(1:1) /= '$') cycle
         n = n + 1_I4P
         names(n) = self%variables(k)%name
      enddo
   endif
   endsubroutine datablock_names

   pure function is_array(self, name) result(yes)
   !< Whether `name` is an array.
   class(symbols_object), intent(in) :: self !< Symbols.
   character(len=*),      intent(in) :: name !< Name.
   logical                           :: yes  !< An array.

   yes = self%array_index(name) > 0_I4P
   endfunction is_array

   pure function array_size(self, name) result(n)
   !< Size of the array `name`, 0 if there is none.
   class(symbols_object), intent(in) :: self !< Symbols.
   character(len=*),      intent(in) :: name !< Name.
   integer(I4P)                      :: n    !< Size.
   integer(I4P)                      :: k    !< Array index.

   n = 0_I4P
   k = self%array_index(name)
   if (k > 0_I4P) n = size(self%arrays(k)%list%items, kind=I4P)
   endfunction array_size

   pure function array_text(self, name) result(text)
   !< The array `name` as gnuplot's `print` shows it: `[1,2.5,"x",]` (strings quoted, an element without a value
   !< empty); empty if there is no such array.
   class(symbols_object), intent(in) :: self !< Symbols.
   character(len=*),      intent(in) :: name !< Array name.
   character(len=:), allocatable     :: text !< Text.
   integer(I4P)                      :: k    !< Array index.

   text = ''
   k = self%array_index(name)
   if (k > 0_I4P) text = list_text(self%arrays(k)%list)
   endfunction array_text

   recursive subroutine array_value(self, text, list, found, iostat, iomsg, degrees)
   !< The elements of `text` if it is an array, `A`, or a slice, `A[i:j]` (gnuplot 6.0: ends known now, an empty or `*`
   !< end the first or the last element, clamped, `[]` when empty); `found` false for anything else (`A[i]`, `A + 1`).
   class(symbols_object),         intent(in), target   :: self    !< Symbols.
   character(len=*),              intent(in)           :: text    !< Expression.
   type(value_list),              intent(out)          :: list    !< Elements.
   logical,                       intent(out)          :: found   !< An array or a slice.
   integer(I4P),                  intent(out)          :: iostat  !< 0 on success.
   character(len=:), allocatable, intent(out)          :: iomsg   !< Error message.
   logical,                       intent(in), optional :: degrees !< Angles in degrees.
   character(len=*), parameter   :: NAME_CHARS = &
                                    UNAME_CHARS !< Name characters.
   character(len=:), allocatable :: t      !< Text, trimmed.
   character(len=:), allocatable :: inner  !< Between the brackets.
   character(len=:), allocatable :: part   !< An end.
   integer(I4P)                  :: e      !< End of the name.
   integer(I4P)                  :: k      !< Array index.
   integer(I4P)                  :: j      !< Character counter.
   integer(I4P)                  :: nest   !< Bracket nesting.
   integer(I4P)                  :: colon  !< The top-level colon.
   integer(I8P)                  :: ends(2) !< First and last index.
   real(R8P)                     :: r      !< An end.
   character(len=1)              :: quote  !< Open quote, blank if none.

   found = .false.
   iostat = 0_I4P
   iomsg = ''
   allocate(list%items(0), list%set(0))
   t = trim(adjustl(text))
   if (len(t) == 0) return
   e = verify(t, NAME_CHARS, kind=I4P)
   if (e > 0_I4P) then
      if (t(1:e - 1_I4P) == 'split' .and. t(e:e) == '(' .and. t(len(t):len(t)) == ')' .and. &
          closing(t, e) == len(t, kind=I4P)) then
         ! gnuplot 6.0 split("string" [, "separator"]), its arguments known now
         block
            type(value_object) :: args(2) !< String and separator.
            integer(I4P)       :: comma   !< The top-level comma, 0 if none.

            comma = top_comma(t(e + 1_I4P:len(t) - 1))
            args(2) = string_value(' ')
            if (comma == 0_I4P) then
               call self%evaluate_constant(t(e + 1_I4P:len(t) - 1), args(1), iostat, iomsg, degrees=degrees)
            else
               call self%evaluate_constant(t(e + 1_I4P:e + comma - 1_I4P), args(1), iostat, iomsg, degrees=degrees)
               if (iostat == 0_I4P) call self%evaluate_constant(t(e + comma + 1_I4P:len(t) - 1), args(2), iostat, &
                                                                iomsg, degrees=degrees)
            endif
            if (iostat /= 0_I4P) return
            if (.not. (args(1)%is_string .and. args(2)%is_string)) then
               iostat = 1_I4P
               iomsg = 'split takes strings: split("string" [, "separator"])'
               return
            endif
            list = split_list(args(1)%s, args(2)%s)
            found = .true.
         endblock
         return
      endif
   endif
   if (e == 0_I4P) then
      k = self%array_index(t)
      if (k == 0_I4P) return
      list = self%arrays(k)%list
      found = .true.
      return
   endif
   if (t(e:e) /= '[' .or. t(len(t):len(t)) /= ']') return
   k = self%array_index(t(1:e - 1_I4P))
   if (k == 0_I4P) return
   inner = t(e + 1_I4P:len(t) - 1)
   ! the colon at the top level of the brackets, outside quotes; a bracket closing early means A[i] + B[j]
   nest = 0_I4P
   colon = 0_I4P
   quote = ' '
   do j = 1_I4P, len(inner, kind=I4P)
      if (quote /= ' ') then
         if (inner(j:j) == quote) quote = ' '
         cycle
      endif
      select case (inner(j:j))
      case ('"', "'")
         quote = inner(j:j)
      case ('(', '[')
         nest = nest + 1_I4P
      case (')', ']')
         nest = nest - 1_I4P
         if (nest < 0_I4P) return
      case (':')
         if (nest == 0_I4P .and. colon == 0_I4P) colon = j
      endselect
   enddo
   if (colon == 0_I4P) return
   associate(items => self%arrays(k)%list%items)
      ends = [1_I8P, size(items, kind=I8P)]
   endassociate
   do j = 1_I4P, 2_I4P
      if (j == 1_I4P) then
         part = trim(adjustl(inner(1:colon - 1_I4P)))
      else
         part = trim(adjustl(inner(colon + 1_I4P:)))
      endif
      if (len(part) == 0 .or. part == '*') cycle
      call self%constant(part, r, iostat, iomsg, degrees=degrees)
      if (iostat /= 0_I4P) return
      if (abs(r) > real(huge(1_I4P), R8P)) r = sign(real(huge(1_I4P), R8P), r)
      ends(j) = int(r, I8P)
   enddo
   list = slice_list(self%arrays(k)%list, ends(1), ends(2))
   found = .true.
   endsubroutine array_value

   pure subroutine store_array(self, name, list, iostat, iomsg)
   !< Set the array `name` to the elements `list` (gnuplot's `B = A[2:3]`), replacing a variable or an array of the name.
   class(symbols_object),         intent(inout) :: self   !< Symbols.
   character(len=*),              intent(in)    :: name   !< Array name.
   type(value_list),              intent(in)    :: list   !< Elements.
   integer(I4P),                  intent(out)   :: iostat !< 0 on success.
   character(len=:), allocatable, intent(out)   :: iomsg  !< Error message.
   type(user_array)                             :: a      !< New array.

   call check_name(name, iostat, iomsg)
   if (iostat /= 0_I4P) return
   a%list = list
   a%name = name
   call self%remove(name)
   if (.not. allocated(self%arrays)) allocate(self%arrays(0))
   call push(self%arrays, a)
   endsubroutine store_array

   pure function defined(self, name) result(yes)
   !< Whether `name` is a user variable, an array, or one of gnuplot's predefined `pi` and `NaN`.
   class(symbols_object), intent(in) :: self !< Symbols.
   character(len=*),      intent(in) :: name !< Name.
   logical                           :: yes  !< Defined.

   yes = self%variable_index(name) > 0_I4P .or. self%array_index(name) > 0_I4P .or. name == 'pi' .or. name == 'NaN'
   endfunction defined

   pure function array_data(self, name) result(text)
   !< The array `name` as data lines (gnuplot's `plot A`): the index, then the value (a string quoted, `NaN` for an
   !< element without a value); empty if there is no such array.
   class(symbols_object), intent(in) :: self !< Symbols.
   character(len=*),      intent(in) :: name !< Array name.
   character(len=:), allocatable     :: text !< Data lines.
   integer(I4P)                      :: k    !< Array index.
   integer(I4P)                      :: j    !< Element counter.

   text = ''
   k = self%array_index(name)
   if (k == 0_I4P) return
   associate(list => self%arrays(k)%list)
      do j = 1_I4P, size(list%items, kind=I4P)
         text = text//int_str(int(j, I8P))//' '
         if (.not. list%set(j)) then
            text = text//'NaN'
         elseif (list%items(j)%is_string) then
            text = text//'"'//list%items(j)%s//'"'
         elseif (list%items(j)%is_int) then
            text = text//int_str(list%items(j)%i)
         else
            text = text//gnuplot_real(list%items(j)%r)
         endif
         text = text//new_line('a')
      enddo
   endassociate
   endfunction array_data

   pure function array_index(self, name) result(k)
   !< Index of the array `name`, 0 if none.
   class(symbols_object), intent(in) :: self !< Symbols.
   character(len=*),      intent(in) :: name !< Name.
   integer(I4P)                      :: k    !< Index.

   if (allocated(self%arrays)) then
      do k = 1_I4P, size(self%arrays, kind=I4P)
         if (self%arrays(k)%name == name) return
      enddo
   endif
   k = 0_I4P
   endfunction array_index

   pure function variable_index(self, name) result(k)
   !< Index of the variable `name`, 0 if none.
   class(symbols_object), intent(in) :: self !< Symbols.
   character(len=*),      intent(in) :: name !< Name.
   integer(I4P)                      :: k    !< Index.

   if (allocated(self%variables)) then
      do k = 1_I4P, size(self%variables, kind=I4P)
         if (self%variables(k)%name == name) return
      enddo
   endif
   k = 0_I4P
   endfunction variable_index

   pure function function_index(self, name) result(k)
   !< Index of the function `name`, 0 if none.
   class(symbols_object), intent(in) :: self !< Symbols.
   character(len=*),      intent(in) :: name !< Name.
   integer(I4P)                      :: k    !< Index.

   if (allocated(self%functions)) then
      do k = 1_I4P, size(self%functions, kind=I4P)
         if (self%functions(k)%name == name) return
      enddo
   endif
   k = 0_I4P
   endfunction function_index

   recursive function evaluate(self, row, point, cells, heads, place) result(v)
   !< Value on a data row: `row` holds its cells (NaN if missing), `point` is its point number (column 0).
   !<
   !< `cells` are the texts of the row cells (`strcol`), `heads` those of the first row of its dataset (`columnhead`),
   !< `place` its block within the dataset and its dataset (the pseudo-columns -1 and -2), all from 0; without them
   !< those functions and pseudo-columns are undefined.
   !<
   !< NaN if undefined. Every floating point operation is checked beforehand, so no IEEE exception is raised.
   class(expression_object), intent(in)           :: self     !< Expression.
   real(R8P),                intent(in)           :: row(:)   !< Row cells.
   integer(I4P),             intent(in)           :: point    !< Point number.
   type(name_object),        intent(in), optional :: cells(:) !< Row cell texts.
   type(name_object),        intent(in), optional :: heads(:) !< Header cell texts of the row's dataset.
   integer(I4P),             intent(in), optional :: place(2) !< Block within the dataset and dataset, from 0.
   real(R8P)                                      :: v        !< Value.
   type(value_object)                             :: top      !< Typed value.
   logical                                        :: defined  !< Defined.
   integer(I4P)                                   :: err      !< Type error.

   v = ieee_value(1.0_R8P, ieee_quiet_nan)
   ! a time field: its plain column read with the time format
   if (allocated(self%timefmt) .and. present(cells)) then
      if (size(self%code) == 1) then
         if (self%code(1)%op == OP_COLUMN .and. self%code(1)%arg >= 1_I4P) then
            if (self%code(1)%arg <= size(cells, kind=I4P)) v = cells_time(cells, self%code(1)%arg, self%timefmt)
            return
         endif
      endif
   endif
   call run(self, row, point, top, defined, cells=cells, heads=heads, place=place)
   if (defined .and. top%is_string) call numeric(top, defined, err)
   if (defined) then
      ! a complex value: undefined beyond gnuplot's `set zero`
      if (abs(top%im) > ZERO_IMAG) then
         defined = .false.
      else
         v = real_of(top)
      endif
   endif
   endfunction evaluate

   pure function cells_time(cells, c, format) result(t)
   !< The time `format` reads from cell `c` on, the following cells joined by a blank as many times as the format has
   !< blanks (a time `2024-03-01 10:00` spans two whitespace separated cells, as gnuplot reads it); NaN if it does not
   !< match.
   type(name_object), intent(in) :: cells(:) !< Row cell texts.
   integer(I4P),      intent(in) :: c        !< First cell.
   character(len=*),  intent(in) :: format   !< Time format.
   real(R8P)                     :: t        !< Time [s].
   character(len=:), allocatable :: text     !< Joined cells.
   integer(I4P)                  :: k        !< Cell counter.
   integer(I4P)                  :: blanks   !< Blanks of the format.
   logical                       :: ok       !< Matched.

   blanks = 0_I4P
   do k = 1_I4P, len(format, kind=I4P)
      if (format(k:k) == ' ') blanks = blanks + 1_I4P
   enddo
   text = cells(c)%text
   do k = c + 1_I4P, min(c + blanks, size(cells, kind=I4P))
      text = text//' '//cells(k)%text
   enddo
   call strptime(format, text, t, ok)
   endfunction cells_time

   pure subroutine set_time(self, timefmt)
   !< Make the field a time field: a plain column is read with `timefmt` (empty: a number again).
   class(expression_object), intent(inout) :: self    !< Expression.
   character(len=*),         intent(in)    :: timefmt !< Time format.

   if (len(timefmt) == 0) then
      if (allocated(self%timefmt)) deallocate(self%timefmt)
   else
      self%timefmt = timefmt
   endif
   endsubroutine set_time

   recursive function evaluate_text(self, row, point, cells, heads, place) result(text)
   !< Text on a data row (arguments as `evaluate`), as gnuplot's label and tick label fields: a string value as it is;
   !< a number, the text of the first column the expression reads (gnuplot's `using 1:2:($2*2) with labels` writes
   !< the text of column 2), or the number as `%g` if it reads none; empty if undefined.
   class(expression_object), intent(in)           :: self     !< Expression.
   real(R8P),                intent(in)           :: row(:)   !< Row cells.
   integer(I4P),             intent(in)           :: point    !< Point number.
   type(name_object),        intent(in), optional :: cells(:) !< Row cell texts.
   type(name_object),        intent(in), optional :: heads(:) !< Header cell texts of the row's dataset.
   integer(I4P),             intent(in), optional :: place(2) !< Block within the dataset and dataset, from 0.
   character(len=:), allocatable                  :: text     !< Text.
   type(value_object)                             :: top      !< Typed value.
   logical                                        :: defined  !< Defined.
   integer(I4P)                                   :: c        !< First column read.

   text = ''
   ! a plain column: its text, a number or not
   c = self%plain_column()
   if (c > 0_I4P .and. present(cells)) then
      if (c <= size(cells, kind=I4P)) text = cells(c)%text
      return
   endif
   call run(self, row, point, top, defined, cells=cells, heads=heads, place=place)
   if (.not. defined) return
   if (top%is_string) then
      text = top%s
      return
   endif
   c = self%first_column()
   if (c > 0_I4P .and. present(cells)) then
      if (c <= size(cells, kind=I4P)) text = cells(c)%text
   elseif (top%is_int) then
      text = c_integer('', 0_I4P, -1_I4P, 'd', top%i)
   else
      text = c_real('', 0_I4P, -1_I4P, 'g', top%r)
   endif
   endfunction evaluate_text

   recursive subroutine table_cell(self, row, point, text, is_string, cells, heads, place)
   !< A field of gnuplot's `plot ... with table` on a data row (arguments as `evaluate`): a string as it is, a number
   !< as `%g`, `nan` if undefined.
   class(expression_object),      intent(in)           :: self      !< Expression.
   real(R8P),                     intent(in)           :: row(:)    !< Row cells.
   integer(I4P),                  intent(in)           :: point     !< Point number.
   character(len=:), allocatable, intent(out)          :: text      !< Text.
   logical,                       intent(out)          :: is_string !< A string value.
   type(name_object),             intent(in), optional :: cells(:)  !< Row cell texts.
   type(name_object),             intent(in), optional :: heads(:)  !< Header cell texts of the row's dataset.
   integer(I4P),                  intent(in), optional :: place(2)  !< Block within the dataset and dataset, from 0.
   type(value_object)                                  :: top       !< Typed value.
   logical                                             :: defined   !< Defined.

   is_string = .false.
   text = 'nan'
   call run(self, row, point, top, defined, cells=cells, heads=heads, place=place)
   if (.not. defined) return
   if (top%is_string) then
      text = top%s
      is_string = .true.
   elseif (ieee_is_nan(real_of(top))) then
      text = 'nan'
   else
      text = c_real('', 0_I4P, -1_I4P, 'g', real_of(top))
   endif
   endsubroutine table_cell

   elemental function uses_text(self) result(uses)
   !< Whether the expression reads the texts of the row cells (`strcol`), which the data must then keep.
   class(expression_object), intent(in) :: self !< Expression.
   logical                              :: uses !< Cell texts read.

   uses = allocated(self%timefmt)
   if (allocated(self%code)) uses = uses .or. any(self%code%op == OP_STRCOL) .or. any(self%code%op == OP_TIMECOLUMN)
   endfunction uses_text

   recursive subroutine run(self, row, point, top, defined, error, cells, heads, place)
   !< Run the stack code on a data row: `top` is the typed value, `defined` false if undefined; `error` the type error
   !< that made it undefined (E_NONE if none: a missing cell, a domain error); `cells`, `heads`, `place` as `evaluate`.
   class(expression_object), intent(in)            :: self                 !< Expression.
   real(R8P),                intent(in)            :: row(:)               !< Row cells.
   integer(I4P),             intent(in)            :: point                !< Point number.
   type(value_object),       intent(out)           :: top                  !< Value.
   logical,                  intent(out)           :: defined              !< Defined.
   integer(I4P),             intent(out), optional :: error                !< Type error.
   type(name_object),        intent(in),  optional :: cells(:)             !< Row cell texts.
   type(name_object),        intent(in),  optional :: heads(:)             !< Header cell texts of the dataset.
   integer(I4P),             intent(in),  optional :: place(2)             !< Block within the dataset and dataset.
   type(value_object)             :: stack(max(1_I4P, self%depth)) !< Operand stack.
   type(value_object)             :: result                         !< Operation result.
   integer(I8P)                   :: c                              !< Column number.
   integer(I4P)                   :: pc                             !< Next instruction.
   integer(I4P)                   :: sp                             !< Stack top.
   integer(I4P)                   :: n                              !< Arguments of a call.
   integer(I4P)                   :: err                            !< Type error.
   logical                        :: ok                             !< Defined.
   integer(I4P)                   :: fp                             !< Frame: slot before the arguments of a call.
   integer(I4P)                   :: level                          !< Nested user function calls (gnuplot's depth).
   integer(I4P)                   :: calls                          !< Active recursive calls.
   integer(I4P)                   :: back(3, merge(MAX_CALLS, 0_I4P, self%recursive)) !< Their return: pc, fp, level.
   character(len=:), allocatable  :: message                        !< A function block's error.

   top = value_object()
   defined = .false.
   fp = 0_I4P
   level = 0_I4P
   calls = 0_I4P
   if (present(error)) error = E_NONE
   err = E_NONE
   sp = 0_I4P
   pc = 1_I4P
   ok = .true.
   do while (pc <= size(self%code, kind=I4P))
      associate(instruction => self%code(pc))
         pc = pc + 1_I4P
         ! gnuplot's undefined value only passes along: an operation on it is an error
         n = operands(instruction%op, int(instruction%v%i, I4P))
         if (n > 0_I4P) then
            if (any(stack(sp - n + 1_I4P:sp)%is_undef)) then
               if (present(error)) error = E_UNINIT
               return
            endif
         endif
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
            call column(int(NO_COLUMN, I8P), stack(sp), ok)
         case (OP_COLUMN_OF)
            c = -1_I8P
            if (stack(sp)%is_string) call numeric(stack(sp), ok, err)
            if (.not. ok) then
               c = -1_I8P
            elseif (stack(sp)%is_int) then
               c = stack(sp)%i
            elseif (abs(stack(sp)%r) < INT_LIMIT) then
               c = int(stack(sp)%r, I8P)
            endif
            call column(c, stack(sp), ok)
         case (OP_STRCOL)
            call column_text(stack(sp), ok)
         case (OP_COLUMNHEAD)
            call header_text(stack(sp), ok, err)
         case (OP_TIMECOLUMN)
            call time_cell(stack(sp - 1_I4P), stack(sp), ok, err)
            sp = sp - 1_I4P
         case (OP_NEGATE)
            if (stack(sp)%is_string) call numeric(stack(sp), ok, err)
            if (.not. ok) then
               continue
            elseif (stack(sp)%is_int .and. stack(sp)%i /= LEAST) then
               stack(sp)%i = -stack(sp)%i
            else
               result = value_object(r=-real_of(stack(sp)))
               result%im = -stack(sp)%im
               stack(sp) = result
            endif
         case (OP_NOT)
            call condition(stack(sp), ok, err)
            if (ok) stack(sp) = logical_value(.not. truth(stack(sp)))
         case (OP_TRUTH)
            call condition(stack(sp), ok, err)
            if (ok) stack(sp) = logical_value(truth(stack(sp)))
         case (OP_ADD:OP_NE)
            if (stack(sp - 1_I4P)%is_string) call numeric(stack(sp - 1_I4P), ok, err)
            if (stack(sp)%is_string .and. ok) call numeric(stack(sp), ok, err)
            if (ok) call binary(instruction%op, stack(sp - 1_I4P), stack(sp), result, ok)
            if (self%degrees .and. instruction%op == OP_ATAN2 .and. ok) result%r = result%r * (180.0_R8P / PI)
            sp = sp - 1_I4P
            stack(sp) = result
         case (OP_BAND:OP_SHR)
            call bitwise(instruction%op, stack(sp - 1_I4P), stack(sp), result, ok, err)
            sp = sp - 1_I4P
            stack(sp) = result
         case (OP_BNOT)
            if (stack(sp)%is_int .and. .not. stack(sp)%is_string) then
               stack(sp)%i = not(stack(sp)%i)
            else
               ok = .false.
               err = E_BITWISE
            endif
         case (OP_CONCAT:OP_STRNE)
            call string_binary(instruction%op, stack(sp - 1_I4P), stack(sp), result, ok, err)
            sp = sp - 1_I4P
            stack(sp) = result
         case (OP_SUBSTRING)
            call substring(stack(sp - 2_I4P), stack(sp - 1_I4P), stack(sp), result, ok, err)
            sp = sp - 2_I4P
            stack(sp) = result
         case (OP_CALL)
            n = int(instruction%v%i, I4P)
            call string_function(instruction%arg, stack(sp - n + 1_I4P:sp), result, ok, err)
            sp = sp - n + 1_I4P
            stack(sp) = result
         case (OP_FUNCTION)
            if (stack(sp)%is_string) call numeric(stack(sp), ok, err)
            if (.not. ok) then
               continue
            elseif (self%degrees) then
               call unary_degrees(instruction%arg, stack(sp), result, ok)
            else
               call unary(instruction%arg, stack(sp), result, ok)
            endif
            stack(sp) = result
         case (OP_JUMP)
            pc = instruction%arg
         case (OP_JUMP_UNLESS)
            call condition(stack(sp), ok, err)
            if (.not. ok) then
               continue
            elseif (.not. truth(stack(sp))) then
               pc = instruction%arg
            endif
            sp = sp - 1_I4P
         case (OP_AND_JUMP)
            call condition(stack(sp), ok, err)
            if (.not. ok) then
               continue
            elseif (.not. truth(stack(sp))) then
               stack(sp) = logical_value(.false.)
               pc = instruction%arg
            else
               sp = sp - 1_I4P
            endif
         case (OP_OR_JUMP)
            call condition(stack(sp), ok, err)
            if (.not. ok) then
               continue
            elseif (truth(stack(sp))) then
               stack(sp) = logical_value(.true.)
               pc = instruction%arg
            else
               sp = sp - 1_I4P
            endif
         case (OP_ELEMENT)
            associate(list => self%lists(instruction%arg))
               call index_of(stack(sp), c, ok)
               if (.not. ok) then
                  err = E_NONNUMERIC
               elseif (c < 1_I8P .or. c > size(list%items, kind=I8P)) then
                  ok = .false.
                  err = E_INDEX
               elseif (.not. list%set(c)) then
                  ! an element without a value: gnuplot's undefined value
                  stack(sp) = undefined_value()
               else
                  stack(sp) = list%items(c)
               endif
            endassociate
         case (OP_LOAD)
            sp = sp + 1_I4P
            stack(sp) = stack(fp + instruction%arg)
         case (OP_RECURSE)
            if (level + instruction%calls > MAX_CALLS) then
               ok = .false.
               err = E_DEPTH
            else
               calls = calls + 1_I4P
               back(:, calls) = [pc, fp, level]
               fp = sp - int(instruction%v%i, I4P)
               level = level + instruction%calls
               pc = instruction%arg
            endif
         case (OP_DEPTH)
            if (level + instruction%calls > MAX_CALLS) then
               ok = .false.
               err = E_DEPTH
            endif
         case (OP_RETURN)
            stack(fp + 1_I4P) = stack(sp)
            sp = fp + 1_I4P
            pc = back(1, calls)
            fp = back(2, calls)
            level = back(3, calls)
            calls = calls - 1_I4P
         case (OP_STOP)
            exit
         case (OP_RAND)
            call random_next(stack(sp), ok, err)
         case (OP_SPECIAL)
            n = MATH_ARGS(instruction%arg)
            call special(instruction%arg, stack(sp - n + 1_I4P:sp), result, ok, err)
            sp = sp - n + 1_I4P
            stack(sp) = result
         case (OP_BLOCK)
            n = int(instruction%v%i, I4P)
            if (.not. associated(block_hook)) then
               ok = .false.
               err = E_BLOCK
               block_message = 'function blocks run in a script'
            else
               call block_hook(self%blocks(instruction%arg)%text, stack(sp - n + 1_I4P:sp), result, ok, message)
               if (.not. ok .and. len(message) > 0) then
                  err = E_BLOCK
                  block_message = message
               elseif (.not. ok) then
                  ! no return: gnuplot's undefined value
                  ok = .true.
                  result = undefined_value()
               endif
               sp = sp - n + 1_I4P
               stack(sp) = result
            endif
         case (OP_COLLAPSE)
            stack(sp - instruction%arg) = stack(sp)
            sp = sp - instruction%arg
         case (OP_ASSIGN)
            if (associated(store_hook)) call store_hook(self%stores(instruction%arg)%text, stack(sp))
         case (OP_FETCH_ELEMENT)
            call index_of(stack(sp), c, ok)
            if (.not. ok) then
               err = E_NONNUMERIC
            else
               block
                  logical :: set !< With a value.

                  set = .false.
                  if (associated(element_fetch_hook)) &
                     call element_fetch_hook(self%stores(instruction%arg)%text, c, stack(sp), ok, set)
                  if (.not. ok) then
                     err = E_INDEX
                  elseif (.not. set) then
                     stack(sp) = undefined_value()
                  endif
               endblock
            endif
         case (OP_ASSIGN_ELEMENT)
            call index_of(stack(sp - 1_I4P), c, ok)
            if (.not. ok) then
               err = E_NONNUMERIC
            else
               if (associated(element_hook)) call element_hook(self%stores(instruction%arg)%text, c, stack(sp), ok)
               if (.not. ok) err = E_INDEX
            endif
            if (ok) then
               stack(sp - 1_I4P) = stack(sp)
               sp = sp - 1_I4P
            endif
         case (OP_FETCH)
            sp = sp + 1_I4P
            block
               logical :: found !< The variable has a value.

               found = .false.
               if (associated(fetch_hook)) call fetch_hook(self%stores(instruction%arg)%text, stack(sp), found)
               if (.not. found) then
                  stack(sp) = instruction%v
                  if (instruction%calls == 0_I4P) then
                     ok = .false.
                     err = E_NOVAR
                  endif
               endif
            endblock
         endselect
      endassociate
      if (.not. ok) then
         if (present(error)) error = err
         return
      endif
   enddo
   if (sp == 1_I4P) then
      top = stack(1)
      defined = .not. top%is_undef
      if (top%is_undef .and. present(error)) error = E_UNDEF
   endif
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
      elseif ((c == -1_I8P .or. c == -2_I8P) .and. present(place)) then
         ! the pseudo-columns: -1 the block within the dataset, -2 the dataset (gnuplot's index), integers
         value = int_value(int(place(-c), I8P))
      else
         ok = .false.
      endif
      endsubroutine column

      pure subroutine column_text(value, ok)
      !< `strcol(value)`: the text of the column `value` numbers (a header name if a string), undefined if none.
      type(value_object), intent(inout) :: value !< Column number or name; its text.
      logical,            intent(inout) :: ok    !< Defined.
      integer(I8P)                      :: c     !< Column.
      integer(I4P)                      :: k     !< Header cell counter.

      c = -1_I8P
      if (value%is_string) then
         if (present(heads)) then
            do k = 1_I4P, size(heads, kind=I4P)
               if (heads(k)%text == value%s) then
                  c = k
                  exit
               endif
            enddo
         endif
      elseif (value%is_int) then
         c = value%i
      elseif (abs(value%r) < INT_LIMIT) then
         c = int(value%r, I8P)
      endif
      ok = present(cells)
      if (ok) ok = c >= 1_I8P .and. c <= size(cells, kind=I8P)
      if (ok) value = string_value(cells(c)%text)
      endsubroutine column_text

      pure subroutine time_cell(value, format, ok, err)
      !< `timecolumn(value, format)`: the column `value` numbers read as a time with `format` (the cells after it
      !< joined by blanks, as a format with blanks spans them), undefined if it does not match.
      type(value_object), intent(inout) :: value  !< Column number; its time.
      type(value_object), intent(in)    :: format !< Time format.
      logical,            intent(inout) :: ok     !< Defined.
      integer(I4P),       intent(inout) :: err    !< Type error.
      integer(I8P)                      :: c      !< Column.
      real(R8P)                         :: t      !< Time.

      c = -1_I8P
      if (.not. format%is_string) then
         ok = .false.
         err = E_NOTSTRING
         return
      endif
      if (value%is_string) call numeric(value, ok, err)
      if (.not. ok) return
      if (value%is_int) then
         c = value%i
      elseif (abs(value%r) < INT_LIMIT) then
         c = int(value%r, I8P)
      endif
      ok = present(cells)
      if (ok) ok = c >= 1_I8P .and. c <= size(cells, kind=I8P)
      if (.not. ok) return
      t = cells_time(cells, int(c, I4P), format%s)
      ok = .not. ieee_is_nan(t)
      if (ok) value = value_object(r=t)
      endsubroutine time_cell

      pure subroutine header_text(value, ok, err)
      !< `columnhead(value)`: the text of column `value` in the first row of the dataset, undefined if none.
      type(value_object), intent(inout) :: value !< Column number; its header text.
      logical,            intent(inout) :: ok    !< Defined.
      integer(I4P),       intent(inout) :: err   !< Type error.
      integer(I8P)                      :: c     !< Column.

      c = -1_I8P
      if (value%is_string) call numeric(value, ok, err)
      if (.not. ok) return
      if (value%is_int) then
         c = value%i
      elseif (abs(value%r) < INT_LIMIT) then
         c = int(value%r, I8P)
      endif
      ok = present(heads)
      if (ok) ok = c >= 1_I8P .and. c <= size(heads, kind=I8P)
      if (ok) value = string_value(heads(c)%text)
      endsubroutine header_text
   endsubroutine run

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

   pure function plain_column(self) result(c)
   !< The data column (from 1) of a plain column field (`using 2`, `using "name"` once resolved), 0 for any other
   !< expression (`$2`, `($2*2)`, column 0): gnuplot skips a point whose plain column holds no number, and leaves an
   !< expression on it undefined.
   class(expression_object), intent(in) :: self !< Expression.
   integer(I4P)                         :: c    !< Column.

   c = 0_I4P
   if (.not. allocated(self%code)) return
   ! a time field reads text
   if (allocated(self%timefmt)) return
   ! a compiled expression keeps its source text, a plain column (set_column, set_name) has none
   if (allocated(self%text)) then
      if (len(self%text) > 0) return
   endif
   if (size(self%code) /= 1) return
   if (self%code(1)%op == OP_COLUMN .and. self%code(1)%arg >= 1_I4P) c = self%code(1)%arg
   endfunction plain_column

   pure function reads_column(self, c) result(reads)
   !< Whether the expression reads the data column `c` (from 1): as a plain column or `$c`. A column read through
   !< `column(expr)` is known only when evaluated: a missing cell there reads as undefined (gnuplot reads the column
   !< the expression asks for, histograms.dem's `column(i)` with `set datafile missing`).
   class(expression_object), intent(in) :: self  !< Expression.
   integer(I4P),             intent(in) :: c     !< Column.
   logical                              :: reads !< Column read.
   integer(I4P)                         :: k     !< Instruction counter.

   reads = .false.
   if (.not. allocated(self%code)) return
   do k = 1_I4P, size(self%code, kind=I4P)
      if (self%code(k)%op == OP_COLUMN .and. self%code(k)%arg == c) then
         reads = .true.
         return
      endif
   enddo
   endfunction reads_column

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
         resolved%code(k) = instruction_object(op=OP_COLUMN, arg=NO_COLUMN)
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
   call single_instruction(self, OP_COLUMN, c)
   if (allocated(self%names)) deallocate(self%names)
   allocate(self%names(0))
   self%depth = 1_I4P
   endsubroutine set_column

   pure subroutine set_name(self, name)
   !< Make the expression the plain column of header `name`, as gnuplot `using 1:"name"`.
   class(expression_object), intent(inout) :: self !< Expression.
   character(len=*),         intent(in)    :: name !< Column header name.

   self%text = ''
   call single_instruction(self, OP_COLUMN_NAMED, 1_I4P)
   self%names = [name_object(name)]
   self%depth = 1_I4P
   endsubroutine set_name

   pure subroutine single_instruction(self, op, arg)
   !< Make the code the one instruction `op arg` (by components: nvfortran 26.9 crashes copying an array constructor
   !< of a structure constructor whose components hold a deferred-length character, `[instruction_object(...)]`).
   class(expression_object), intent(inout) :: self        !< Expression.
   integer(I4P),             intent(in)    :: op          !< Operation code.
   integer(I4P),             intent(in)    :: arg         !< Argument.
   type(instruction_object)                :: instruction !< The instruction.

   instruction%op = op
   instruction%arg = arg
   if (allocated(self%code)) deallocate(self%code)
   allocate(self%code(1))
   self%code(1) = instruction
   endsubroutine single_instruction

   recursive function value_at(self, x) result(v)
   !< Value of an expression compiled with a dummy variable at the variable value `x`; NaN if undefined.
   class(expression_object), intent(in) :: self !< Expression.
   real(R8P),                intent(in) :: x    !< Variable value.
   real(R8P)                            :: v    !< Value.

   v = self%evaluate([x], 0_I4P)
   endfunction value_at

   ! private procedures
   pure subroutine check_name(name, iostat, iomsg)
   !< A user symbol name: a letter or `_`, then letters, digits, `_`.
   character(len=*),              intent(in)  :: name   !< Name.
   integer(I4P),                  intent(out) :: iostat !< 0 if valid.
   character(len=:), allocatable, intent(out) :: iomsg  !< Error message.
   character(len=*), parameter :: LETTERS = UNAME_START

   iostat = 0_I4P
   iomsg = ''
   if (len(name) == 0) then
      iostat = 1_I4P
   elseif (scan(name(1:1), LETTERS) == 0 .or. verify(name, UNAME_CHARS) > 0) then
      iostat = 1_I4P
   endif
   if (iostat /= 0_I4P) iomsg = 'invalid name "'//name//'"'
   endsubroutine check_name

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
   case ('.')
      op = OP_CONCAT
   case ('eq')
      op = OP_STREQ
   case ('ne')
      op = OP_STRNE
   case ('&')
      op = OP_BAND
   case ('|')
      op = OP_BOR
   case ('^')
      op = OP_BXOR
   case ('<<')
      op = OP_SHL
   case ('>>')
      op = OP_SHR
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
   if (a%im /= 0.0_R8P .or. b%im /= 0.0_R8P) then
      call complex_binary(op, a, b, c, ok)
      return
   endif
   if (op == OP_POWER .and. x < 0.0_R8P .and. y /= aint(y)) then
      ! a negative base with a fractional exponent: complex, gnuplot's polar power
      call complex_binary(op, a, b, c, ok)
      return
   endif
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
      if (done) then
         c = int_value(i + j)
      elseif (j > 0_I8P) then
         ! wrapped as two's complement: each term moved by 2**63, the sum in range
         call overflowed(c, done, ok, (i + LEAST) + (j + LEAST))
      else
         call overflowed(c, done, ok, (i - LEAST) + (j - LEAST))
      endif
   case (OP_SUBTRACT)
      if (j < 0_I8P) then
         done = i <= MOST + j
      else
         done = i >= LEAST + j
      endif
      if (done) then
         c = int_value(i - j)
      elseif (j < 0_I8P) then
         call overflowed(c, done, ok, (i + LEAST) - (j - LEAST))
      else
         call overflowed(c, done, ok, (i - LEAST) - (j + LEAST))
      endif
   case (OP_MULTIPLY)
      done = fits_product(i, j)
      if (done) then
         c = int_value(i * j)
      else
         call overflowed(c, done, ok)
      endif
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
      if (done) then
         c = int_value(p)
      else
         call overflowed(c, done, ok)
      endif
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
   contains
      pure subroutine overflowed(c, done, ok, wrapped)
      !< An integer overflow, after `overflow_mode`: `wrapped` (`+`, `-`; absent: a real, as gnuplot's `*` and `**`),
      !< a real (`done` false), NaN or undefined (`ok` false).
      type(value_object),     intent(inout) :: c       !< Result.
      logical,                intent(inout) :: done    !< Result computed.
      logical,                intent(inout) :: ok      !< Defined.
      integer(I8P), optional, intent(in)    :: wrapped !< Two's complement result.

      done = .false.
      select case (overflow_mode)
      case (OVERFLOW_IGNORE)
         if (present(wrapped)) then
            c = int_value(wrapped)
            done = .true.
         endif
      case (OVERFLOW_NAN)
         c = value_object(r=ieee_value(1.0_R8P, ieee_quiet_nan))
         done = .true.
      case (OVERFLOW_UNDEFINED)
         ok = .false.
      endselect
      endsubroutine overflowed
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

   pure subroutine unary_degrees(f, a, c, ok)
   !< c = FUNCTIONS(f)(a) with the angles of the trigonometric functions in degrees; `ok` false if undefined.
   integer(I4P),       intent(in)    :: f  !< Function index.
   type(value_object), intent(in)    :: a  !< Argument.
   type(value_object), intent(out)   :: c  !< Result.
   logical,            intent(inout) :: ok !< Defined.

   select case (trim(FUNCTIONS(f)))
   case ('sin', 'cos', 'tan')
      block
         type(value_object) :: radians !< The argument in radians, both parts.

         radians = value_object(r=real_of(a) * (PI / 180.0_R8P))
         radians%im = a%im * (PI / 180.0_R8P)
         call unary(f, radians, c, ok)
      endblock
   case ('asin', 'acos', 'atan')
      call unary(f, a, c, ok)
      if (ok) c%r = c%r * (180.0_R8P / PI)
   case default
      call unary(f, a, c, ok)
   endselect
   endsubroutine unary_degrees

   pure recursive subroutine unary(f, a, c, ok)
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
   ! an undefined argument: an undefined value, no comparison of it (a NaN compared traps in debug builds)
   if (ieee_is_nan(x) .or. ieee_is_nan(a%im)) then
      c%r = ieee_value(1.0_R8P, ieee_quiet_nan)
      return
   endif
   if (a%im /= 0.0_R8P .or. (x < 0.0_R8P .and. (name == 'sqrt' .or. name == 'log' .or. name == 'log10'))) then
      ! a complex argument, or a negative one of sqrt and log: gnuplot's complex result
      call complex_unary(name, a, c, ok)
      return
   endif
   select case (name)
   case ('arg')
      ! gnuplot's angle of a real
      if (x < 0.0_R8P) c%r = PI
   case ('imag')
      c%r = 0.0_R8P
   case ('conj')
      c = a
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
      elseif (ieee_is_nan(x)) then
         ok = .false.
      elseif (abs(x) >= merge(INT_GUARANTEED, EXACT_HALF, name == 'int')) then
         ! beyond the integers gnuplot trusts the double to hold: NaN (undefined with `set overflow undefined`)
         c%r = ieee_value(1.0_R8P, ieee_quiet_nan)
         ok = overflow_mode /= OVERFLOW_UNDEFINED
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
   case ('real')
      c%r = x
   endselect
   endsubroutine unary

   pure function magnitude(a) result(m)
   !< gnuplot's magnitude of a complex value, without spurious overflow.
   type(value_object), intent(in) :: a !< Value.
   real(R8P)                      :: m !< |a|.
   real(R8P)                      :: q !< Quotient of the parts.

   associate(re => abs(real_of(a)), im => abs(a%im))
      if (im == 0.0_R8P) then
         m = re
      elseif (re > im) then
         q = im / re
         m = re * sqrt(1.0_R8P + q * q)
      else
         q = re / im
         m = im * sqrt(1.0_R8P + q * q)
      endif
   endassociate
   endfunction magnitude

   pure function angle(a) result(t)
   !< gnuplot's angle of a complex value: 0 or pi for a real, atan2 else.
   type(value_object), intent(in) :: a !< Value.
   real(R8P)                      :: t !< Angle [rad].

   if (a%im == 0.0_R8P) then
      t = merge(0.0_R8P, PI, real_of(a) >= 0.0_R8P)
   else
      t = atan2(a%im, real_of(a))
   endif
   endfunction angle

   pure function complex_value(re, im) result(c)
   !< The value {re, im} (a real when `im` is 0).
   real(R8P), intent(in) :: re !< Real part.
   real(R8P), intent(in) :: im !< Imaginary part.
   type(value_object)    :: c  !< Value.

   c = value_object(r=re)
   c%im = im
   endfunction complex_value

   pure subroutine complex_binary(op, a, b, c, ok)
   !< c = a op b, one of them complex, by gnuplot's formulas (internal.c); `ok` false if undefined.
   integer(I4P),       intent(in)    :: op  !< Operation code.
   type(value_object), intent(in)    :: a   !< Left operand.
   type(value_object), intent(in)    :: b   !< Right operand.
   type(value_object), intent(out)   :: c   !< Result.
   logical,            intent(inout) :: ok  !< Defined.
   real(R8P), parameter              :: BIG = 1.0e150_R8P !< Larger parts are not multiplied (no overflow).
   real(R8P)                         :: ar  !< a, real part.
   real(R8P)                         :: ai  !< a, imaginary part.
   real(R8P)                         :: br  !< b, real part.
   real(R8P)                         :: bi  !< b, imaginary part.
   real(R8P)                         :: f1  !< Division factor.
   real(R8P)                         :: f2  !< Division factor.
   real(R8P)                         :: den !< Division denominator.
   real(R8P)                         :: mag !< Power magnitude.
   real(R8P)                         :: ang !< Power angle.
   real(R8P)                         :: e   !< An exponent.

   c = value_object()
   ar = real_of(a)
   ai = a%im
   br = real_of(b)
   bi = b%im
   if (a%is_string .or. b%is_string) then
      ok = .false.
      return
   endif
   select case (op)
   case (OP_ADD, OP_SUBTRACT)
      if (op == OP_SUBTRACT) then
         br = -br
         bi = -bi
      endif
      call safe_add(ar, br, f1, ok)
      if (ok) call safe_add(ai, bi, f2, ok)
      if (ok) c = complex_value(f1, f2)
   case (OP_MULTIPLY)
      ok = max(abs(ar), abs(ai), abs(br), abs(bi)) < BIG
      if (ok) c = complex_value(ar * br - ai * bi, ar * bi + ai * br)
   case (OP_DIVIDE)
      ! gnuplot's cmplx_divide
      ok = abs(br) + abs(bi) > 0.0_R8P .and. max(abs(ar), abs(ai), abs(br), abs(bi)) < BIG
      if (.not. ok) return
      if (abs(br) >= abs(bi)) then
         f1 = 1.0_R8P
         f2 = bi / br
      else
         f1 = br / bi
         f2 = 1.0_R8P
      endif
      den = br * f1 + bi * f2
      ok = abs(den) > 1.0_R8P / BIG
      if (ok) c = complex_value((ar * f1 + ai * f2) / den, (ai * f1 - ar * f2) / den)
   case (OP_POWER)
      if (ar == 0.0_R8P .and. ai == 0.0_R8P) then
         ! 0**b: 1 for b 0, else 0; undefined for a complex or negative b
         ok = bi == 0.0_R8P .and. br >= 0.0_R8P
         c = value_object(r=merge(1.0_R8P, 0.0_R8P, br == 0.0_R8P))
         return
      endif
      ! the magnitude, its powers checked against overflow
      e = log(magnitude(a)) * abs(br)
      ok = e <= LOG_HUGE
      if (.not. ok) return
      mag = 0.0_R8P
      if (e > LOG_TINY) mag = magnitude(a)**abs(br)
      if (br < 0.0_R8P) then
         ok = mag /= 0.0_R8P
         if (.not. ok) return
         mag = 1.0_R8P / mag
      endif
      if (b%is_int) then
         ang = angle(a) * br
      else
         e = -bi * angle(a)
         ok = e <= LOG_HUGE
         if (.not. ok) return
         if (e > LOG_TINY) then
            mag = mag * exp(e)
         else
            mag = 0.0_R8P
         endif
         ang = br * angle(a) + bi * log(magnitude(a))
      endif
      c = complex_value(mag * cos(ang), mag * sin(ang))
   case (OP_LT)
      c = logical_value(ar < br)
   case (OP_LE)
      c = logical_value(ar <= br)
   case (OP_GT)
      c = logical_value(ar > br)
   case (OP_GE)
      c = logical_value(ar >= br)
   case (OP_EQ)
      c = logical_value(ar == br .and. ai == bi)
   case (OP_NE)
      c = logical_value(ar /= br .or. ai /= bi)
   case default
      ! `%` and atan2 of complex values: undefined
      ok = .false.
   endselect
   endsubroutine complex_binary

   pure recursive subroutine complex_unary(name, a, c, ok)
   !< c = name(a) for a complex argument (or a negative real one of sqrt, log, log10), by gnuplot's formulas
   !< (standard.c); the functions with no complex form here are undefined.
   character(len=*),   intent(in)    :: name !< Function name.
   type(value_object), intent(in)    :: a    !< Argument.
   type(value_object), intent(out)   :: c    !< Result.
   logical,            intent(inout) :: ok   !< Defined.
   real(R8P)                         :: re   !< Real part.
   real(R8P)                         :: im   !< Imaginary part.
   real(R8P)                         :: mag  !< A magnitude.
   real(R8P)                         :: ang  !< An angle.
   real(R8P)                         :: den  !< A denominator.

   c = value_object()
   re = real_of(a)
   im = a%im
   select case (name)
   case ('abs')
      c%r = magnitude(a)
   case ('arg')
      c%r = angle(a)
   case ('real')
      c%r = re
   case ('imag')
      c%r = im
   case ('conj')
      c = complex_value(re, -im)
   case ('sqrt')
      mag = sqrt(magnitude(a))
      if (im == 0.0_R8P) then
         c = complex_value(0.0_R8P, mag)
      else
         ang = angle(a) / 2.0_R8P
         c = complex_value(mag * cos(ang), mag * sin(ang))
      endif
   case ('exp')
      ok = re <= LOG_HUGE
      if (.not. ok) return
      mag = 0.0_R8P
      if (re > LOG_TINY) mag = exp(re)
      c = complex_value(mag * cos(im), mag * sin(im))
   case ('log', 'log10')
      ok = magnitude(a) > 0.0_R8P
      if (.not. ok) return
      c = complex_value(log(magnitude(a)), angle(a))
      if (name == 'log10') c = complex_value(c%r / log(10.0_R8P), c%im / log(10.0_R8P))
   case ('sin', 'cos', 'sinh', 'cosh')
      ok = abs(im) <= LOG_HUGE .and. abs(re) <= LOG_HUGE
      if (.not. ok) return
      select case (name)
      case ('sin')
         c = complex_value(sin(re) * cosh(im), cos(re) * sinh(im))
      case ('cos')
         c = complex_value(cos(re) * cosh(im), -sin(re) * sinh(im))
      case ('sinh')
         c = complex_value(sinh(re) * cos(im), cosh(re) * sin(im))
      case default
         c = complex_value(cosh(re) * cos(im), sinh(re) * sin(im))
      endselect
   case ('tan')
      ok = abs(2.0_R8P * im) <= LOG_HUGE
      if (.not. ok) return
      den = cos(2.0_R8P * re) + cosh(2.0_R8P * im)
      ok = den /= 0.0_R8P
      if (ok) c = complex_value(sin(2.0_R8P * re) / den, sinh(2.0_R8P * im) / den)
   case ('int', 'floor', 'ceil', 'sgn')
      ! of the real part, as gnuplot
      call unary(findloc(FUNCTIONS, name, dim=1, kind=I4P), value_object(r=re), c, ok)
   case default
      ok = .false.
   endselect
   endsubroutine complex_unary

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

   pure function closing(text, open) result(k)
   !< Position of the parenthesis closing the one at `open` in `text` (quotes skipped), 0 if none.
   character(len=*), intent(in) :: text  !< Text.
   integer(I4P),     intent(in) :: open  !< Opening parenthesis.
   integer(I4P)                 :: k     !< Closing parenthesis.
   integer(I4P)                 :: nest  !< Nesting.
   character(len=1)             :: quote !< Open quote, blank if none.

   nest = 0_I4P
   quote = ' '
   do k = open, len(text, kind=I4P)
      if (quote /= ' ') then
         if (text(k:k) == quote) quote = ' '
         cycle
      endif
      select case (text(k:k))
      case ('"', "'")
         quote = text(k:k)
      case ('(', '[', '{')
         nest = nest + 1_I4P
      case (')', ']', '}')
         nest = nest - 1_I4P
         if (nest == 0_I4P) return
      endselect
   enddo
   k = 0_I4P
   endfunction closing

   pure function top_comma(text) result(k)
   !< Position of the first comma of `text` outside quotes and brackets, 0 if none.
   character(len=*), intent(in) :: text  !< Text.
   integer(I4P)                 :: k     !< Comma.
   integer(I4P)                 :: nest  !< Nesting.
   character(len=1)             :: quote !< Open quote, blank if none.

   nest = 0_I4P
   quote = ' '
   do k = 1_I4P, len(text, kind=I4P)
      if (quote /= ' ') then
         if (text(k:k) == quote) quote = ' '
         cycle
      endif
      select case (text(k:k))
      case ('"', "'")
         quote = text(k:k)
      case ('(', '[', '{')
         nest = nest + 1_I4P
      case (')', ']', '}')
         nest = nest - 1_I4P
      case (',')
         if (nest == 0_I4P) return
      endselect
   enddo
   k = 0_I4P
   endfunction top_comma

   pure function split_list(string, sep) result(list)
   !< gnuplot 6.0's split: the pieces of `string` between occurrences of `sep` (each kept, blanks too), or its words
   !< for a blank or empty `sep` (runs of white space between them); none for an empty `string`.
   character(len=*), intent(in)    :: string   !< String.
   character(len=*), intent(in)    :: sep      !< Separator.
   type(value_list)                :: list     !< Pieces, strings.
   character(len=*), parameter     :: WHITE = ' '//achar(9)//achar(10)//achar(11)//achar(12)//achar(13) !< isspace.
   type(value_object), allocatable :: items(:) !< Pieces.
   integer(I4P)                    :: i        !< Position.
   integer(I4P)                    :: j        !< End of a piece.

   allocate(items(0))
   i = 1_I4P
   if (len(string) > 0) then
      if (len(sep) == 0 .or. sep == ' ') then
         do
            j = verify(string(i:), WHITE, kind=I4P)
            if (j == 0_I4P) exit
            i = i + j - 1_I4P
            j = scan(string(i:), WHITE, kind=I4P)
            if (j == 0_I4P) then
               call push_value(items, string_value(string(i:)))
               exit
            endif
            call push_value(items, string_value(string(i:i + j - 2_I4P)))
            i = i + j - 1_I4P
         enddo
      else
         do
            j = index(string(i:), sep, kind=I4P)
            if (j == 0_I4P) then
               call push_value(items, string_value(string(i:)))
               exit
            endif
            call push_value(items, string_value(string(i:i + j - 2_I4P)))
            i = i + j - 1_I4P + len(sep, kind=I4P)
            if (i > len(string, kind=I4P)) exit
         enddo
      endif
   endif
   allocate(list%set(size(items)))
   list%set = .true.
   call move_alloc(items, list%items)
   endfunction split_list

   pure function string_value(text) result(a)
   !< String value.
   character(len=*), intent(in) :: text !< Text.
   type(value_object)           :: a    !< Value.

   a%is_string = .true.
   a%s = text
   endfunction string_value

   pure function number_text(a) result(text)
   !< `a` as text: a string as it is, an integer in decimal, a real as gnuplot's `print` (`%.15g`, `.0` if integral).
   type(value_object), intent(in) :: a    !< Value.
   character(len=:), allocatable  :: text !< Text.

   if (a%is_string) then
      text = a%s
   elseif (a%is_int) then
      text = int_str(a%i)
   elseif (a%im /= 0.0_R8P) then
      ! gnuplot's complex value
      text = '{'//gnuplot_real(a%r)//', '//gnuplot_real(a%im)//'}'
   else
      text = gnuplot_real(a%r)
   endif
   endfunction number_text

   pure function undefined_value() result(a)
   !< gnuplot's undefined value (by components: nvfortran 26.9 crashes on its constructor here).
   type(value_object) :: a !< Value.

   a%is_undef = .true.
   endfunction undefined_value

   subroutine random_next(a, ok, error)
   !< gnuplot 6.0's rand(x) on `a`, replaced by its value: x = 0 the next number of L'Ecuyer's combined generator (from
   !< seeds 1234567890), x < 0 the generator reset first, x > 0 an integer seed first; another x is "Illegal seed value".
   type(value_object), intent(inout) :: a     !< Argument, then value.
   logical,            intent(inout) :: ok    !< Defined.
   integer(I4P),       intent(inout) :: error !< Type error.
   real(R8P)                         :: x     !< Argument.
   integer(I8P)                      :: k     !< Quotient.
   integer(I8P)                      :: z     !< Combined value.

   if (a%is_string) then
      ok = .false.
      error = E_NONNUMERIC
      return
   endif
   x = real_of(a)
   if (x /= 0.0_R8P) then
      if (x /= aint(x) .or. x > 2147483647.0_R8P) then
         ok = .false.
         error = E_SEED
         return
      endif
      if (x < 0.0_R8P) then
         rand_seeds = 1234567890_I8P
      else
         rand_seeds = int(x, I8P)
      endif
   endif
   k = rand_seeds(1) / 53668_I8P
   rand_seeds(1) = 40014_I8P * (rand_seeds(1) - k * 53668_I8P) - k * 12211_I8P
   if (rand_seeds(1) < 0_I8P) rand_seeds(1) = rand_seeds(1) + 2147483563_I8P
   k = rand_seeds(2) / 52774_I8P
   rand_seeds(2) = 40692_I8P * (rand_seeds(2) - k * 52774_I8P) - k * 3791_I8P
   if (rand_seeds(2) < 0_I8P) rand_seeds(2) = rand_seeds(2) + 2147483399_I8P
   z = rand_seeds(1) - rand_seeds(2)
   if (z < 1_I8P) z = z + 2147483562_I8P
   a = value_object(r=4.656613057e-10_R8P * real(z, R8P))
   endsubroutine random_next

   pure function operands(op, nargs) result(n)
   !< Stack values the operation `op` reads (`nargs`, its `v%i`, for a string function call), 0 for those that only
   !< move them (a load, a call's arguments, a return).
   integer(I4P), intent(in) :: op    !< Operation code.
   integer(I4P), intent(in) :: nargs !< Arguments of OP_CALL.
   integer(I4P)             :: n     !< Values read.

   select case (op)
   case (OP_COLUMN_OF, OP_STRCOL, OP_COLUMNHEAD, OP_NEGATE, OP_NOT, OP_TRUTH, OP_FUNCTION, OP_JUMP_UNLESS, &
         OP_AND_JUMP, OP_OR_JUMP, OP_ELEMENT, OP_BNOT, OP_RAND, OP_FETCH_ELEMENT)
      n = 1_I4P
   case (OP_TIMECOLUMN, OP_ADD:OP_NE, OP_CONCAT:OP_STRNE, OP_BAND:OP_SHR)
      n = 2_I4P
   case (OP_SUBSTRING)
      n = 3_I4P
   case (OP_CALL)
      n = nargs
   case default
      n = 0_I4P
   endselect
   endfunction operands

   pure subroutine bitwise(op, a, b, c, ok, error)
   !< `c = a op b` for the bitwise operators, of integers only (gnuplot: "non-integer passed to boolean operator"); the
   !< shifts as gnuplot's on x86: the count modulo 64, `>>` logical.
   integer(I4P),       intent(in)    :: op    !< Operation code.
   type(value_object), intent(in)    :: a     !< Left operand.
   type(value_object), intent(in)    :: b     !< Right operand.
   type(value_object), intent(out)   :: c     !< Result.
   logical,            intent(inout) :: ok    !< Defined.
   integer(I4P),       intent(inout) :: error !< Type error.
   integer(I4P)                      :: count !< Shift count.

   c = value_object()
   if (.not. (a%is_int .and. b%is_int) .or. a%is_string .or. b%is_string) then
      ok = .false.
      error = E_BITWISE
      return
   endif
   count = int(modulo(b%i, 64_I8P), I4P)
   select case (op)
   case (OP_BAND)
      c = int_value(iand(a%i, b%i))
   case (OP_BOR)
      c = int_value(ior(a%i, b%i))
   case (OP_BXOR)
      c = int_value(ieor(a%i, b%i))
   case (OP_SHL)
      c = int_value(shiftl(a%i, count))
   case default
      c = int_value(shiftr(a%i, count))
   endselect
   endsubroutine bitwise

   pure function error_text(error) result(text)
   !< Message of a type error.
   integer(I4P), intent(in)      :: error !< Error code.
   character(len=:), allocatable :: text  !< Message.

   select case (error)
   case (E_NONNUMERIC)
      text = 'non-numeric string found where a numeric expression was expected'
   case (E_NOTSTRING)
      text = 'a string operator or function applied to a number'
   case (E_BOOLEAN)
      text = 'a string used as a condition'
   case (E_FORMAT)
      text = 'unsupported or invalid format specifier'
   case (E_STRING_ARG)
      text = 'sprintf: a string printed with a numeric format'
   case (E_NUMBER_ARG)
      text = 'sprintf: a number printed with a string format'
   case (E_INDEX)
      text = 'array index out of range'
   case (E_UNSET)
      text = 'array element without a value'
   case (E_DEPTH)
      text = 'recursion depth limit exceeded'
   case (E_BITWISE)
      text = 'non-integer passed to boolean operator'
   case (E_BLOCK)
      text = 'function block'
      if (allocated(block_message)) text = block_message
   case (E_UNDEF)
      text = 'undefined value'
   case (E_UNINIT)
      text = 'uninitialized user variable'
   case (E_SEED)
      text = 'Illegal seed value'
   case (E_ORDER)
      text = 'the order of besjn, besyn, besin and expint must be an integer'
   case (E_NOVAR)
      text = 'undefined variable'
   case default
      text = 'undefined value'
   endselect
   endfunction error_text

   pure subroutine special(f, args, c, ok, error)
   !< `c` = special function `f` (MATH_FUNCTIONS) of `args`: strings read as numbers; an order (besjn, besyn, besin,
   !< expint) must be an integer, as gnuplot (E_ORDER); undefined (`ok` false) where gnuplot's is, and for a NaN or an
   !< infinity.
   integer(I4P),       intent(in)    :: f       !< Function.
   type(value_object), intent(inout) :: args(:) !< Arguments.
   type(value_object), intent(out)   :: c       !< Value.
   logical,            intent(inout) :: ok      !< Defined.
   integer(I4P),       intent(inout) :: error   !< Type error.
   real(R8P)                         :: x(3)    !< Arguments, real.
   real(R8P)                         :: r       !< Value.
   logical                           :: is_int  !< Integer value.
   integer(I4P)                      :: k       !< Counter.

   c = value_object()
   x = 0.0_R8P
   do k = 1_I4P, size(args, kind=I4P)
      if (args(k)%is_string) call numeric(args(k), ok, error)
      if (.not. ok) return
      x(k) = real_of(args(k))
   enddo
   if (len(math_order(f)) > 0) then
      if (.not. args(1)%is_int) then
         ok = .false.
         error = E_ORDER
         return
      endif
   endif
   call math_function(f, x(1:size(args)), args(1)%i, r, is_int, ok)
   if (.not. ok) return
   if (is_int) then
      c = int_value(int(r, I8P))
   else
      c%r = r
   endif
   endsubroutine special

   pure subroutine numeric(a, ok, error)
   !< Replace the string `a` by its leading number, as gnuplot reads a string in arithmetic: blanks, a sign, `0x` and hex
   !< digits, or digits with a point and a lower case `e` exponent (an integer without point nor exponent); the rest is
   !< ignored. No number: `ok` false, E_NONNUMERIC.
   type(value_object), intent(inout) :: a     !< Value.
   logical,            intent(inout) :: ok    !< Defined.
   integer(I4P),       intent(inout) :: error !< Type error.
   character(len=:), allocatable     :: t     !< The string.
   integer(I4P)                      :: i     !< Character counter.
   integer(I4P)                      :: first !< Number start.
   integer(I4P)                      :: j     !< Exponent start.
   integer(I4P)                      :: n     !< Length.
   integer(I4P)                      :: ndigits !< Digits read.
   integer(I4P)                      :: lead    !< Integer digits, leading zeros excluded.
   integer(I4P)                      :: x       !< Exponent part.
   integer(I4P)                      :: ios   !< Conversion status.
   integer(I8P)                      :: h     !< Hexadecimal value.
   logical                           :: is_real !< Point or exponent.
   logical                           :: minus !< Negative.
   character(len=3)                  :: word  !< Three letters, lower case.

   if (.not. a%is_string) return
   t = a%s
   a = value_object()
   n = len(t, kind=I4P)
   i = 1_I4P
   do while (i <= n)
      if (scan(t(i:i), ' '//achar(9)//new_line('a')) == 0) exit
      i = i + 1_I4P
   enddo
   first = i
   minus = .false.
   if (i <= n) then
      if (scan(t(i:i), '+-') > 0) then
         minus = t(i:i) == '-'
         i = i + 1_I4P
      endif
   endif
   if (i + 1_I4P < n) then
      if ((t(i:i + 1_I4P) == '0x' .or. t(i:i + 1_I4P) == '0X') .and. &
          scan(t(i + 2_I4P:i + 2_I4P), '0123456789abcdefABCDEF') > 0) then
         i = i + 2_I4P
         h = 0_I8P
         do while (i <= n)
            if (scan(t(i:i), '0123456789abcdefABCDEF') == 0) exit
            if (h > MOST / 16_I8P) then
               ok = .false.
               error = E_NONNUMERIC
               return
            endif
            h = h * 16_I8P + int(index('0123456789abcdef', to_lower(t(i:i))) - 1, I8P)
            i = i + 1_I4P
         enddo
         if (minus) h = -h
         a = int_value(h)
         return
      endif
   endif
   ! inf, infinity and nan in any case (C's strtod, gnuplot's reading)
   if (i + 2_I4P <= n) then
      word = to_lower(t(i:i))//to_lower(t(i + 1_I4P:i + 1_I4P))//to_lower(t(i + 2_I4P:i + 2_I4P))
      if (word == 'inf') then
         a = value_object(r=ieee_value(1.0_R8P, ieee_positive_inf))
         if (minus) a%r = -a%r
         return
      elseif (word == 'nan') then
         a = value_object(r=ieee_value(1.0_R8P, ieee_quiet_nan))
         return
      endif
   endif
   ndigits = 0_I4P
   lead = 0_I4P
   x = 0_I4P
   is_real = .false.
   do while (i <= n)
      if (scan(t(i:i), '0123456789') == 0) exit
      ndigits = ndigits + 1_I4P
      if (lead > 0_I4P .or. t(i:i) /= '0') lead = lead + 1_I4P
      i = i + 1_I4P
   enddo
   if (i <= n) then
      if (t(i:i) == '.') then
         is_real = .true.
         i = i + 1_I4P
         do while (i <= n)
            if (scan(t(i:i), '0123456789') == 0) exit
            ndigits = ndigits + 1_I4P
            i = i + 1_I4P
         enddo
      endif
   endif
   if (ndigits == 0_I4P) then
      ok = .false.
      error = E_NONNUMERIC
      return
   endif
   if (i < n) then
      if (t(i:i) == 'e') then
         if (scan(t(i + 1_I4P:i + 1_I4P), '0123456789') > 0) then
            is_real = .true.
            i = i + 1_I4P
         elseif (i + 1_I4P < n .and. scan(t(i + 1_I4P:i + 1_I4P), '+-') > 0) then
            if (scan(t(i + 2_I4P:i + 2_I4P), '0123456789') > 0) then
               is_real = .true.
               i = i + 2_I4P
            endif
         endif
         if (is_real) then
            j = i
            do while (i <= n)
               if (scan(t(i:i), '0123456789') == 0) exit
               i = i + 1_I4P
            enddo
            ! the exponent, capped: only its size matters below
            if (i - j > 4_I4P) then
               x = 9999_I4P
            else
               read(t(j:i - 1_I4P), *) x
            endif
            if (t(j - 1_I4P:j - 1_I4P) == '-') x = -x
         endif
      endif
   endif
   ios = 1_I4P
   if (.not. is_real) then
      read(t(first:i - 1_I4P), *, iostat=ios) a%i
      a%is_int = ios == 0_I4P
   endif
   if (ios /= 0_I4P) then
      ! an internal read cannot overflow once the decimal exponent is in range: beyond it, undefined, as an overflow
      if (lead + x > 308_I4P) then
         ok = .false.
      elseif (lead + x < -340_I4P) then
         a%r = 0.0_R8P
      else
         read(t(first:i - 1_I4P), *, iostat=ios) a%r
         ok = ios == 0_I4P
      endif
      if (.not. ok) error = E_NONNUMERIC
   endif
   endsubroutine numeric

   pure subroutine condition(a, ok, error)
   !< A condition must be a number: a string is an error (gnuplot: non-integer passed to boolean operator).
   type(value_object), intent(in)    :: a     !< Value.
   logical,            intent(inout) :: ok    !< Defined.
   integer(I4P),       intent(inout) :: error !< Type error.

   if (a%is_string) then
      ok = .false.
      error = E_BOOLEAN
   endif
   endsubroutine condition

   pure subroutine string_binary(op, a, b, c, ok, error)
   !< c = a . b (`a` a string, `b` a string or an integer), a eq b, a ne b (strings).
   integer(I4P),       intent(in)    :: op    !< Operation code.
   type(value_object), intent(in)    :: a     !< Left operand.
   type(value_object), intent(in)    :: b     !< Right operand.
   type(value_object), intent(out)   :: c     !< Result.
   logical,            intent(inout) :: ok    !< Defined.
   integer(I4P),       intent(inout) :: error !< Type error.

   c = value_object()
   if (.not. a%is_string) then
      ok = .false.
   elseif (op == OP_CONCAT) then
      if (b%is_string) then
         c = string_value(a%s//b%s)
      elseif (b%is_int) then
         c = string_value(a%s//int_str(b%i))
      else
         ok = .false.
      endif
   elseif (.not. b%is_string) then
      ok = .false.
   else
      c = logical_value((a%s == b%s .and. len(a%s) == len(b%s)) .eqv. op == OP_STREQ)
   endif
   if (.not. ok) error = E_NOTSTRING
   endsubroutine string_binary

   pure subroutine substring(a, first, last, c, ok, error)
   !< c = a[first:last], 1-based, the ends clamped to the string, empty if they cross.
   type(value_object), intent(in)    :: a     !< String.
   type(value_object), intent(in)    :: first !< First character.
   type(value_object), intent(in)    :: last  !< Last character.
   type(value_object), intent(out)   :: c     !< Result.
   logical,            intent(inout) :: ok    !< Defined.
   integer(I4P),       intent(inout) :: error !< Type error.
   integer(I8P)                      :: i     !< First, clamped.
   integer(I8P)                      :: j     !< Last, clamped.

   c = value_object()
   if (.not. a%is_string) then
      ok = .false.
      error = E_NOTSTRING
      return
   endif
   call whole(first, i, ok, error)
   call whole(last, j, ok, error)
   if (.not. ok) return
   i = max(1_I8P, i)
   j = min(int(len(a%s), I8P), j)
   if (i > j) then
      c = string_value('')
   else
      c = string_value(a%s(i:j))
   endif
   endsubroutine substring

   pure subroutine whole(a, i, ok, error)
   !< Integer value of `a` (a real truncated, a string read as a number), for indices and counts.
   type(value_object), intent(in)    :: a     !< Value.
   integer(I8P),       intent(out)   :: i     !< Integer.
   logical,            intent(inout) :: ok    !< Defined.
   integer(I4P),       intent(inout) :: error !< Type error.
   type(value_object)                :: b     !< Number.

   i = 0_I8P
   b = a
   if (b%is_string) call numeric(b, ok, error)
   if (.not. ok) return
   if (b%is_int) then
      i = b%i
   elseif (abs(b%r) < INT_LIMIT) then
      i = int(b%r, I8P)
   elseif (b%r > 0.0_R8P) then
      i = MOST
   else
      i = LEAST
   endif
   endsubroutine whole

   pure subroutine string_function(f, args, c, ok, error)
   !< c = STRING_FUNCTIONS(f)(args), as gnuplot's.
   integer(I4P),       intent(in)    :: f       !< Function index.
   type(value_object), intent(in)    :: args(:) !< Arguments.
   type(value_object), intent(out)   :: c       !< Result.
   logical,            intent(inout) :: ok      !< Defined.
   integer(I4P),       intent(inout) :: error   !< Type error.
   character(len=:), allocatable     :: label   !< gprintf text.
   character(len=:), allocatable     :: sup     !< gprintf superscript.
   integer(I8P)                      :: n       !< Integer argument.
   integer(I8P)                      :: mant    !< gprintf mantissa.
   integer(I4P)                      :: e       !< gprintf exponent.
   type(value_object)                :: x       !< Numeric argument.

   c = value_object()
   ! the string arguments (sprintf and gprintf check their own)
   select case (trim(STRING_FUNCTIONS(f)))
   case ('strlen', 'substr', 'words', 'word', 'trim', 'strftime')
      ok = args(1)%is_string
   case ('strptime')
      ok = args(1)%is_string .and. args(2)%is_string
   case ('strstrt')
      ok = args(1)%is_string .and. args(2)%is_string
   endselect
   if (.not. ok) then
      error = E_NOTSTRING
      return
   endif
   select case (trim(STRING_FUNCTIONS(f)))
   case ('sprintf')
      call sprintf_value(args, c, ok, error)
   case ('gprintf')
      if (.not. args(1)%is_string) then
         ok = .false.
         error = E_NOTSTRING
         return
      endif
      if (len(format_check(args(1)%s)) > 0) then
         ok = .false.
         error = E_FORMAT
         return
      endif
      x = args(2)
      if (x%is_string) call numeric(x, ok, error)
      if (.not. ok) return
      call decimal_of(real_of(x), mant, e)
      ! gnuplot's gprintf function passes 10 as the log10 of the base of %l and %L
      call format_value(args(1)%s, mant, e, 10.0_R8P, label, sup)
      ! the exponent of %h as gnuplot's enhanced text
      if (len(sup) > 0) label = label//'^{'//sup//'}'
      c = string_value(label)
   case ('strlen')
      c = int_value(int(len(args(1)%s), I8P))
   case ('substr')
      call substring(args(1), args(2), args(3), c, ok, error)
   case ('strstrt')
      c = int_value(int(index(args(1)%s, args(2)%s), I8P))
   case ('words')
      c = int_value(int(count_words(args(1)%s), I8P))
   case ('word')
      call whole(args(2), n, ok, error)
      if (ok) c = string_value(nth_word(args(1)%s, n))
   case ('trim')
      c = string_value(trim_blanks(args(1)%s))
   case ('strftime')
      x = args(2)
      if (x%is_string) call numeric(x, ok, error)
      if (.not. ok) return
      c = string_value(strftime(args(1)%s, real_of(x)))
   case ('strptime')
      block
         real(R8P) :: t       !< Time read.
         logical   :: matched !< Text matched.

         call strptime(args(1)%s, args(2)%s, t, matched)
         ok = matched
         if (ok) c = value_object(r=t)
      endblock
   endselect
   endsubroutine string_function

   pure subroutine sprintf_value(args, c, ok, error)
   !< gnuplot's `sprintf(format, ...)`: each C conversion takes the next argument (`%s` a string, the others a number:
   !< `d i u o x X c` its integer part, `f F e E g G` its real value), `%%` is `%`; once the arguments are used up the
   !< rest of the format is copied as it is, extra arguments are ignored.
   type(value_object), intent(in)    :: args(:) !< Format and values.
   type(value_object), intent(out)   :: c       !< Result.
   logical,            intent(inout) :: ok      !< Defined.
   integer(I4P),       intent(inout) :: error   !< Type error.
   character(len=:), allocatable     :: format  !< Format.
   character(len=:), allocatable     :: text    !< Result text.
   character(len=:), allocatable     :: flags   !< Conversion flags.
   character(len=1)                  :: type    !< Conversion type.
   integer(I4P)                      :: width   !< Field width.
   integer(I4P)                      :: prec    !< Precision, -1 if absent.
   integer(I4P)                      :: i       !< Format position.
   integer(I4P)                      :: j       !< Field start.
   integer(I4P)                      :: k       !< Next argument.
   integer(I8P)                      :: v       !< Integer value.
   type(value_object)                :: x       !< Argument.

   c = value_object()
   if (.not. args(1)%is_string) then
      ok = .false.
      error = E_NOTSTRING
      return
   endif
   format = args(1)%s
   text = ''
   k = 2_I4P
   i = 1_I4P
   do while (i <= len(format, kind=I4P))
      if (format(i:i) /= '%') then
         text = text//format(i:i)
         i = i + 1_I4P
         cycle
      endif
      if (i == len(format, kind=I4P)) then
         text = text//'%'
         exit
      endif
      if (format(i + 1_I4P:i + 1_I4P) == '%') then
         text = text//'%'
         i = i + 2_I4P
         cycle
      endif
      if (k > size(args, kind=I4P)) then
         ! no argument left: the conversion stays as written
         text = text//'%'
         i = i + 1_I4P
         cycle
      endif
      i = i + 1_I4P
      j = i
      do while (i <= len(format, kind=I4P))
         if (scan(format(i:i), '-+ 0#') == 0) exit
         i = i + 1_I4P
      enddo
      flags = format(j:i - 1_I4P)
      call digits_at(i, width)
      prec = -1_I4P
      if (i <= len(format, kind=I4P)) then
         if (format(i:i) == '.') then
            i = i + 1_I4P
            call digits_at(i, prec)
            prec = max(0_I4P, prec)
         endif
      endif
      if (i > len(format, kind=I4P) .or. width < 0_I4P .or. prec > 999_I4P) then
         ok = .false.
         error = E_FORMAT
         return
      endif
      type = format(i:i)
      i = i + 1_I4P
      x = args(k)
      k = k + 1_I4P
      if (type == 's') then
         if (.not. x%is_string) then
            ok = .false.
            error = E_NUMBER_ARG
            return
         endif
         text = text//c_string(flags, width, prec, x%s)
      elseif (scan(type, 'diouxXcfFeEgG') > 0) then
         if (x%is_string) then
            ok = .false.
            error = E_STRING_ARG
            return
         endif
         if (scan(type, 'diouxXc') > 0) then
            if (x%is_int) then
               v = x%i
            elseif (abs(x%r) < INT_LIMIT) then
               v = int(x%r, I8P)
            else
               v = LEAST
            endif
            text = text//c_integer(flags, width, prec, type, v)
         else
            text = text//c_real(flags, width, prec, type, real_of(x))
         endif
      else
         ok = .false.
         error = E_FORMAT
         return
      endif
   enddo
   c = string_value(text)
   contains
      pure subroutine digits_at(at, number)
      !< The decimal number starting at `at` (advanced past it), 0 if none; -1 if longer than 3 digits.
      integer(I4P), intent(inout) :: at     !< Position.
      integer(I4P), intent(out)   :: number !< Number.
      integer(I4P)                :: start  !< First digit.

      number = 0_I4P
      start = at
      do while (at <= len(format, kind=I4P))
         if (scan(format(at:at), '0123456789') == 0) exit
         if (at - start >= 3_I4P) then
            number = -1_I4P
         elseif (number >= 0_I4P) then
            number = number * 10_I4P + (iachar(format(at:at)) - iachar('0'))
         endif
         at = at + 1_I4P
      enddo
      endsubroutine digits_at
   endsubroutine sprintf_value

   pure function count_words(text) result(n)
   !< Number of blank-separated words of `text`.
   character(len=*), intent(in) :: text !< Text.
   integer(I4P)                 :: n    !< Words.
   integer(I4P)                 :: i    !< Character counter.
   logical                      :: in_word !< Inside a word.

   n = 0_I4P
   in_word = .false.
   do i = 1_I4P, len(text, kind=I4P)
      if (is_blank(text(i:i))) then
         in_word = .false.
      elseif (.not. in_word) then
         in_word = .true.
         n = n + 1_I4P
      endif
   enddo
   endfunction count_words

   pure function nth_word(text, k) result(w)
   !< Word `k` (from 1) of `text`, empty if none.
   character(len=*), intent(in)  :: text !< Text.
   integer(I8P),     intent(in)  :: k    !< Word number.
   character(len=:), allocatable :: w    !< Word.
   integer(I4P)                  :: i    !< Character counter.
   integer(I4P)                  :: start !< Word start.
   integer(I8P)                  :: n    !< Words seen.

   w = ''
   n = 0_I8P
   i = 1_I4P
   do while (i <= len(text, kind=I4P))
      if (is_blank(text(i:i))) then
         i = i + 1_I4P
         cycle
      endif
      start = i
      do while (i <= len(text, kind=I4P))
         if (is_blank(text(i:i))) exit
         i = i + 1_I4P
      enddo
      n = n + 1_I8P
      if (n == k) then
         w = text(start:i - 1_I4P)
         return
      endif
   enddo
   endfunction nth_word

   pure function trim_blanks(text) result(t)
   !< `text` without leading and trailing blanks (spaces, tabs, new lines).
   character(len=*), intent(in)  :: text  !< Text.
   character(len=:), allocatable :: t     !< Trimmed text.
   integer(I4P)                  :: first !< First kept.
   integer(I4P)                  :: last  !< Last kept.

   first = 1_I4P
   last = len(text, kind=I4P)
   do while (first <= last)
      if (.not. is_blank(text(first:first))) exit
      first = first + 1_I4P
   enddo
   do while (last >= first)
      if (.not. is_blank(text(last:last))) exit
      last = last - 1_I4P
   enddo
   t = text(first:last)
   endfunction trim_blanks

   elemental function is_blank(c) result(yes)
   !< Whether `c` is a space, a tab or a new line.
   character(len=1), intent(in) :: c   !< Character.
   logical                      :: yes !< Blank.

   yes = c == ' ' .or. c == achar(9) .or. c == achar(10) .or. c == achar(13)
   endfunction is_blank

   pure function to_lower(c) result(l)
   !< Lower case of an ASCII letter.
   character(len=1), intent(in) :: c !< Character.
   character(len=1)             :: l !< Lower case.

   l = c
   if (c >= 'A' .and. c <= 'Z') l = achar(iachar(c) + 32)
   endfunction to_lower

   pure subroutine push_instruction(list, item)
   !< Append `item` to `list` (an unallocated `list` is empty), through a temporary: see `push`.
   type(instruction_object), allocatable, intent(inout) :: list(:)  !< List.
   type(instruction_object),              intent(in)    :: item     !< New item.
   type(instruction_object), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                         :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_instruction

   pure subroutine index_of(v, i, ok)
   !< `v` as an array index (a real truncated, a string's leading number): false if it is not a number.
   type(value_object), intent(in)  :: v  !< Value.
   integer(I8P),       intent(out) :: i  !< Index.
   logical,            intent(out) :: ok !< A number.
   type(value_object)              :: n  !< Its number.
   integer(I4P)                    :: err !< Type error.

   i = 0_I8P
   n = v
   ok = .true.
   if (n%is_string) call numeric(n, ok, err)
   if (.not. ok) return
   if (n%is_int) then
      i = n%i
   elseif (ieee_is_nan(n%r) .or. abs(n%r) >= INT_LIMIT) then
      ok = .false.
   else
      i = int(n%r, I8P)
   endif
   endsubroutine index_of

   pure function list_text(list) result(text)
   !< Elements as gnuplot's `print` shows an array: `[1,2.5,"x",]` (strings quoted, an element without a value empty).
   type(value_list), intent(in)  :: list !< Elements.
   character(len=:), allocatable :: text !< Text.
   integer(I4P)                  :: j    !< Element counter.

   text = '['
   do j = 1_I4P, size(list%items, kind=I4P)
      if (j > 1_I4P) text = text//','
      if (.not. list%set(j)) cycle
      if (list%items(j)%is_string) then
         text = text//'"'//list%items(j)%s//'"'
      else
         text = text//number_text(list%items(j))
      endif
   enddo
   text = text//']'
   endfunction list_text

   pure function slice_list(list, first, last) result(piece)
   !< Elements `first` to `last` of `list`, clamped to it (gnuplot's A[0:9]), none if `first` > `last`.
   type(value_list), intent(in) :: list  !< Elements.
   integer(I8P),     intent(in) :: first !< First index.
   integer(I8P),     intent(in) :: last  !< Last index.
   type(value_list)             :: piece !< The slice.
   integer(I8P)                 :: a     !< First index kept.
   integer(I8P)                 :: b     !< Last index kept.

   a = max(1_I8P, first)
   b = min(size(list%items, kind=I8P), last)
   if (a > b) then
      allocate(piece%items(0), piece%set(0))
   else
      piece%items = list%items(a:b)
      piece%set = list%set(a:b)
   endif
   endfunction slice_list

   pure function lines_list(text) result(list)
   !< The lines of a datablock `text` (each ended by a newline) as string elements.
   character(len=*), intent(in) :: text !< Datablock text.
   type(value_list)             :: list !< Lines.
   integer(I4P)                 :: n    !< Lines.
   integer(I4P)                 :: k    !< Character counter.
   integer(I4P)                 :: first !< Current line start.

   n = 0_I4P
   do k = 1_I4P, len(text, kind=I4P)
      if (text(k:k) == new_line('a')) n = n + 1_I4P
   enddo
   allocate(list%items(n), list%set(n))
   list%set = .true.
   n = 0_I4P
   first = 1_I4P
   do k = 1_I4P, len(text, kind=I4P)
      if (text(k:k) /= new_line('a')) cycle
      n = n + 1_I4P
      list%items(n) = string_value(text(first:k - 1_I4P))
      first = k + 1_I4P
   enddo
   endfunction lines_list

   pure subroutine push_array(list, item)
   !< Append `item` to `list` (an unallocated `list` is empty), through a temporary: see `push`.
   type(user_array), allocatable, intent(inout) :: list(:)  !< List.
   type(user_array),              intent(in)    :: item     !< New item.
   type(user_array), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                 :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_array

   pure subroutine push_list(list, item)
   !< Append `item` to `list` (an unallocated `list` is empty), through a temporary: see `push`.
   type(value_list), allocatable, intent(inout) :: list(:)  !< List.
   type(value_list),              intent(in)    :: item     !< New item.
   type(value_list), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                 :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_list

   pure function any_name(list, name) result(yes)
   !< Whether `list` holds `name`.
   type(name_object), intent(in) :: list(:) !< List.
   character(len=*),  intent(in) :: name    !< Name.
   logical                       :: yes     !< Found.
   integer(I4P)                  :: k       !< Counter.

   yes = .false.
   do k = 1_I4P, size(list, kind=I4P)
      if (list(k)%text == name) yes = .true.
   enddo
   endfunction any_name

   pure subroutine push_value(list, item)
   !< Append `item` to `list` (an unallocated `list` is empty), through a temporary: see `push`.
   type(value_object), allocatable, intent(inout) :: list(:)  !< List.
   type(value_object),              intent(in)    :: item     !< New item.
   type(value_object), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                   :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_value

   pure subroutine push_name(list, item)
   !< Append `item` to `list` (an unallocated `list` is empty), through a temporary: see `push`.
   type(name_object), allocatable, intent(inout) :: list(:)  !< List.
   type(name_object),              intent(in)    :: item     !< New item.
   type(name_object), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                  :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_name

   pure subroutine push_variable(list, item)
   !< Append `item` to `list` (an unallocated `list` is empty), through a temporary: see `push`.
   type(user_variable), allocatable, intent(inout) :: list(:)  !< List.
   type(user_variable),              intent(in)    :: item     !< New item.
   type(user_variable), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                    :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_variable

   pure subroutine push_function(list, item)
   !< Append `item` to `list` (an unallocated `list` is empty), through a temporary: see `push`.
   type(user_function), allocatable, intent(inout) :: list(:)  !< List.
   type(user_function),              intent(in)    :: item     !< New item.
   type(user_function), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                    :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_function

   pure subroutine push_expression(list, item)
   !< Append `item` to `list` (an unallocated `list` is empty), through a temporary: see `push`.
   type(expression_object), allocatable, intent(inout) :: list(:)  !< List.
   type(expression_object),              intent(in)    :: item     !< New item.
   type(expression_object), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                        :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_expression
endmodule foresight_expression
