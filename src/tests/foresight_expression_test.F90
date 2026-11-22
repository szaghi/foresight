!< foresight_expression test: gnuplot semantics of `using` expressions and plotted functions, values checked against
!< gnuplot 6.0.
program foresight_expression_test
!< foresight_expression test: gnuplot semantics of `using` expressions and plotted functions, values checked against
!< gnuplot 6.0.
!<
!< Built with the debug flags (`-ffpe-trap=invalid,zero,overflow`), the undefined cases also check that evaluation
!< raises no floating point exception.
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan, ieee_quiet_nan, ieee_value
use, intrinsic :: iso_fortran_env, only : error_unit, output_unit
use foresight_expression, only : expression_object, symbols_object
use penf, only : I4P, R8P

implicit none
real(R8P)    :: row(3)   !< Data row: 10, 20, missing.
integer(I4P) :: failures !< Failed checks.
integer(I4P) :: checks   !< Checks run.
type(symbols_object) :: symbols !< User variables and functions.

row = [10.0_R8P, 20.0_R8P, ieee_value(1.0_R8P, ieee_quiet_nan)]
failures = 0_I4P
checks = 0_I4P

! precedence and associativity
call check_value('-2**2', -4.0_R8P)
call check_value('2**3**2', 512.0_R8P)
call check_value('2**-1', 0.5_R8P)
call check_value('1 + 2*3 - 4/2', 5.0_R8P)
call check_value('1 < 2 < 3', 1.0_R8P)
call check_value('!0 + !5', 1.0_R8P)
call check_value('1 ? 2 : 3 ? 4 : 5', 2.0_R8P)
call check_value('0 ? 2 : 0 ? 4 : 5', 5.0_R8P)
! integer arithmetic, as gnuplot
call check_value('1/2', 0.0_R8P)
call check_value('7/2.', 3.5_R8P)
call check_value('-5/2', -2.0_R8P)
call check_value('5/-2', -2.0_R8P)
call check_value('-5%3', -2.0_R8P)
call check_value('int(-2.7)/2', -1.0_R8P)
call check_value('floor(2.5)/2', 1.0_R8P)
call check_value('ceil(2.1)/2', 1.0_R8P)
call check_value('abs(-3)/2', 1.0_R8P)
call check_value('(-8)**(1/3)', 1.0_R8P)
call check_value('(-2)**3', -8.0_R8P)
call check_value('(-2.)**3', -8.0_R8P)
call check_value('2**62*4', 18446744073709551616.0_R8P)
call check_value('9223372036854775807 + 1', 9223372036854775808.0_R8P)
call check_value('2**1000', 2.0_R8P**1000)
! columns: $0 is the point number, columns are reals
call check_value('$1*1e3', 1.0e4_R8P)
call check_value('$0', 3.0_R8P)
call check_value('$0/2', 1.5_R8P)
call check_value('column(2)', 20.0_R8P)
call check_value('column($0 - 1)', 20.0_R8P)
call check_value('$2 > 15 ? $2 : 1/0', 20.0_R8P)
! functions and constants
call check_value('sgn(-3) + sgn(0)', -1.0_R8P)
call check_value('atan2(0, 0)', 0.0_R8P)
call check_value('4*atan2(1, 1) - pi', 0.0_R8P, 1.0e-15_R8P)
call check_value('log10(1e-3) + exp(0) + sqrt(16)', 2.0_R8P, 1.0e-15_R8P)
call check_value('cos(pi) + sin(0) + tanh(0) + cosh(0)', 0.0_R8P, 1.0e-15_R8P)
! short circuits: the unneeded operand is not evaluated
call check_value('0 && 1/0', 0.0_R8P)
call check_value('1 || 1/0', 1.0_R8P)
call check_value('2 && 3', 1.0_R8P)
call check_value('1 ? 2 : 1/0', 2.0_R8P)
! undefined: gaps, and no floating point exception
call check_undefined('$3')
call check_undefined('$9')
call check_undefined('column(-2)')
call check_undefined('$1 > 15 ? $1 : 1/0')
call check_undefined('1/0')
call check_undefined('1%0')
call check_undefined('1./0')
call check_undefined('sqrt(-1)')
call check_undefined('log(0)')
call check_undefined('asin(2)')
call check_undefined('exp(1000)')
call check_undefined('cosh(1000)')
call check_undefined('1e308*10')
call check_undefined('1e308 + 1e308')
call check_undefined('1e308/1e-10')
call check_undefined('10.**400')
call check_undefined('(-8)**(1./3)')
call check_undefined('0**-1')
call check_undefined('int(1e300)')
call check_undefined('$3*0')
! syntax errors name the problem and its position
call check_error('$2 +', 'unexpected end at character 5')
call check_error('(1', 'expected ")", found "end"')
call check_error('1 2', 'unexpected "2" at character 3')
call check_error('foo(1)', 'unknown function "foo" at character 1')
call check_error('x*2', 'undefined variable: x at character 1')
call check_error('1 & 2', 'bitwise operator "&" not supported')
call check_error('atan2(1)', 'atan2 needs 2 arguments')
call check_error('$', '"$" needs a column number')
call check_error('1e+', 'malformed number')
call check_error('1e999', 'number out of range')
! an error followed by an operator of the same level (nvfortran 26.9 -O2 looped forever on these)
call check_error('0.3*sin(x/4)', 'undefined variable: x at character 9')
call check_error('0.5*x/4', 'undefined variable: x at character 5')
call check_undefined('"a" + 1')
call check_undefined('column("res")')
! strings, as gnuplot 6.0 prints them
call assign('sv', '"abc"')
call check_text('sv', 'abc')
call check_text('"de\tf" . "|"', 'de'//achar(9)//'f|')
call check_text("'de\tf'", 'de\tf')
call check_text('sv . 1', 'abc1')
call check_text('sv . -3', 'abc-3')
call check_text('(sv . 1) . 2', 'abc12')
call check_text('"x" . (1 < 2)', 'x1')
call check_text('"a" . 2*3', 'a6')
call check_text('"a" . "b" eq "ab"', '1')
call check_text('"a" eq "a" && 1', '1')
call check_text('sv eq "abc" ? "yes" : "no"', 'yes')
call check_text('1 ? "a" : "b"', 'a')
call check_text('0 ? "a" : 2', '2')
call check_text('"3" + 1', '4')
call check_text('"3.5" * 2', '7.0')
call check_text('"1.5e2" + 0', '150.0')
call check_text('"1E2" + 0', '1')
call check_text('"12abc" + 0', '12')
call check_text('" 4" + 0', '4')
call check_text('"0x10" + 0', '16')
call check_text('"2" / "4"', '0')
call check_text('"2." / 4', '0.5')
call check_text('-"3"', '-3')
call check_text('sv[2:3] . "|" . sv[2:] . "|" . sv[:2]', 'bc|bc|ab')
call check_text('sv[0:1] . "|" . sv[3:10] . "|" . sv[4:5] . "|" . sv[3:2] . "|"', 'a|c|||')
call check_text('sv[2:*] . sv[*:2]', 'bcab')
call check_text('sv[1+1:3]', 'bc')
call check_text('("ab")[1:1]', 'a')
call check_text('strlen(sv) + strlen("")', '3')
call check_text('strstrt(sv, "c")*10 + strstrt(sv, "z")', '30')
call check_text('substr(sv, 2, 3) . "|" . substr("hello", 0, 2) . "|" . substr("hello", 4, 99)', 'bc|he|lo')
call check_text('words("a b  c")', '3')
call check_text('word("a b  c", 2) . "|" . word("a b", 5) . "|" . word("a b", 0) . "|"', 'b|||')
call check_text('trim("  a b  ") . "|"', 'a b|')
call check_text('int("12") + int("2.9")', '14')
call check_text('real("3")', '3.0')
call check_text('sprintf("%d|%5.2f|%s|%e|%g|%x|%o|%c|%%", 42, 3.14159, "hi", 12345.678, 0.0001, 255, 8, 65)', &
                '42| 3.14|hi|1.234568e+04|0.0001|ff|10|A|%')
call check_text('sprintf("%d", 3.7) . sprintf("%d", -3.7) . sprintf("%f", 3)', '3-33.000000')
call check_text('sprintf("%5s|%-5s|", "ab", "cd") . sprintf("%05d|%+d|% d", 42, 42, 42)', '   ab|cd   |00042|+42| 42')
call check_text('sprintf("%d %d", 1)', '1 %d')
call check_text('sprintf("%d", 1, 2) . sprintf("no args")', '1no args')
call check_text('sprintf("%10.3e|%G|%E|%i", 1234.5, 1e-10, 2.5, 7)', ' 1.234e+03|1E-10|2.500000E+00|7')
call check_text('sprintf("%-+8.2f|", 3.14159) . sprintf("%#x|%#o", 255, 8)', '+3.14   |0xff|010')
call check_text('sprintf("%x", -1) . sprintf(" %d", 2**62) . sprintf(" %d", 1e20)', &
                'ffffffff 4611686018427387904 -9223372036854775808')
call check_text('sprintf("%.2s|", "abcdef") . sprintf("%3d|%-3d|", 5, 5)', 'ab|  5|5  |')
call check_text('sprintf("%e", 0) . sprintf(" %g", 100000) . sprintf(" %g", 1000000)', '0.000000e+00 100000 1e+06')
call check_text('sprintf("%.0f %.0f %.0f", 0.5, 1.5, 2.5)', '0 2 2')
call check_text('sprintf("%.2f", 2.675)', '2.67')
call check_text('sprintf("%5.1f%%", 12.345)', ' 12.3%')
call check_text('sprintf("%s", "%d")', '%d')
call check_text('sprintf("%s %s", "a")', 'a %s')
call check_text('sprintf("%5.3s|", "abcdef")', '  abc|')
call check_text('sprintf("%-10.4g|%10.4G|", 1234567, 0.000012345)', '1.235e+06 | 1.234E-05|')
call check_text('sprintf("%5.1d|", 3)', '    3|')
call check_text('sprintf("%.3f", pi)', '3.142')
call check_text('1/3.', '0.333333333333333')
call check_text('1e20', '1e+20')
call check_text('100.0', '100.0')
call check_text('2**0.5', '1.4142135623731')
call check_text('123456789.0', '123456789.0')
call check_text('2**63', '9.22337203685478e+18')
call check_text('exists("sv")*10 + exists("nope")', '10')
call check_text('value("sv")', 'abc')
call define('frun', ['x'], 'sprintf("run%d.dat", x)')
call check_text('frun(3)', 'run3.dat')
call define('gcat', ['a', 'b'], 'a . b')
call check_text('gcat("x", "y")', 'xy')
call assign('tv', '"x"')
call assign('tv', 'tv . "y"')
call check_text('tv', 'xy')
call check_constant('"2.5" * 2', 5.0_R8P)
call check_text_error('"x" . 1.5', 'a string operator or function applied to a number')
call check_text_error('1 . 2', 'a string operator or function applied to a number')
call check_text_error('"abc" + 1', 'non-numeric string found where a numeric expression was expected')
call check_text_error('"a" == "a"', 'non-numeric string')
call check_text_error('"1" eq 1', 'a string operator or function applied to a number')
call check_text_error('!"0"', 'a string used as a condition')
call check_text_error('"a" ? 1 : 2', 'a string used as a condition')
call check_text_error('strlen(5)', 'a string operator or function applied to a number')
call check_text_error('sprintf("%f", "x")', 'sprintf: a string printed with a numeric format')
call check_text_error('sprintf("%s", 3)', 'sprintf: a number printed with a string format')
call check_text_error('sprintf("%ld", 3)', 'unsupported or invalid format specifier')
call check_text_error('sprintf("%*d", 5, 3)', 'unsupported or invalid format specifier')
call check_text_error('sv[2]', 'expected ":"')
call check_text_error('strlen(sv, 1)', 'strlen needs 1 argument')
call check_text_error('value(sv)', 'value takes a quoted variable name')
call check_text_error('sv.1', 'unexpected')
call check_define_error('words', ['x'], 'x', 'builtin function')
call check_assign_error('uv', '"a" + 1', 'non-numeric string')
call check_error('1 = 2', 'unexpected "="')
call check_error(repeat('(', 300)//'1'//repeat(')', 300), 'nested too deeply')
! functions of the dummy variable x: a real, even at integer values; columns are errors
call check_function('x**2', 3.0_R8P, 9.0_R8P)
call check_function('1/x', 2.0_R8P, 0.5_R8P)
call check_function('x/2', 3.0_R8P, 1.5_R8P)
call check_function('sin(x)/x', 0.5_R8P * acos(-1.0_R8P), 2.0_R8P / acos(-1.0_R8P), 1.0e-15_R8P)
call check_function('x > 0 ? log(x) : 1/0', 1.0_R8P, 0.0_R8P)
call check_function('1/x', 0.0_R8P, ieee_value(1.0_R8P, ieee_quiet_nan))
call check_function('sqrt(x)', -1.0_R8P, ieee_value(1.0_R8P, ieee_quiet_nan))
call check_function_error('$1*x', 'columns are only valid in using, not in a function at character 1')
call check_function_error('column(1)', 'columns are only valid in using, not in a function at character 1')
call check_function_error('y', 'undefined variable: y')

! user variables and functions, against gnuplot 6.0: integers stay integers, functions see the variables when they are
! called, several parameters, nesting, the dummy variable winning over a user variable, arity and name errors
call assign('a', '2')
call assign('b', 'a/3')
call check_symbol('b', 0.0_R8P, is_int=.true.)
call assign('a2', '2.')
call check_symbol('a2/3', 2.0_R8P / 3.0_R8P)
call define('f', ['x'], 'a*x')
call assign('a', '3')
call check_symbol('f(2)', 6.0_R8P)
call assign('a', '1')
call assign('b', 'f(2)')
call assign('a', '5')
call check_symbol('b', 2.0_R8P)
call check_symbol('f(2)', 10.0_R8P)
call define('g', ['x', 'y'], 'x+y')
call check_symbol('g(1,2)', 3.0_R8P)
call check_symbol('g(f(1), g(2,3))', 10.0_R8P)
call check_symbol('g(1 && 0, 2)', 2.0_R8P)
call define('s', ['x'], 'x > 0 ? 1 : -1')
call check_symbol('s(-2) + 10*s(3)', 9.0_R8P)
call define('h', ['t'], 't**2')
call check_symbol('h(3)', 9.0_R8P, is_int=.true.)
call define('f', ['x'], 'x*2')
call check_symbol('f(f(1))', 4.0_R8P)
call define('f', ['x'], 'x*3')
call check_symbol('f(1)', 3.0_R8P)
call assign('a', '-2')
call check_symbol('a**2', 4.0_R8P)
call assign('a', '2**10')
call check_symbol('a/3', 341.0_R8P, is_int=.true.)
call assign('pi', '3')
call check_symbol('pi', 3.0_R8P)
call assign('a_1', '4')
call assign('A', '5')
call check_symbol('a_1*10 + A', 45.0_R8P)
call define('u', ['x'], 'v(x) + 1')
call define('v', ['x'], 'x*10')
call check_symbol('u(1)', 11.0_R8P)
call define('k', ['x'], 'q*x')
call check_symbol_error('k(2)', 'in function k: undefined variable: q')
call assign('q', '4')
call check_symbol('k(2)', 8.0_R8P)
call assign('scale', '2')
call check_symbol('($2*scale)', 40.0_R8P)
call assign('x', '3')
call check_symbol_function('x**2', 2.0_R8P, 4.0_R8P)
call define('w', ['t'], 't*x')
call check_symbol_function('w(x)', 2.0_R8P, 6.0_R8P)
call check_symbol_error('c + 1', 'undefined variable: c')
call check_symbol_error('f(1,2)', 'function f requires 1 variable')
call check_symbol_error('g(1)', 'function g requires 2 variables')
! recursive functions, as gnuplot 6.0: a call stack; 251 nested calls at most (gnuplot's t(250) runs, t(251) fails,
! g calling t counts too); an integer overflow gives a real
call define('fact', ['n'], 'n<=1 ? 1 : n*fact(n-1)')
call check_symbol('fact(5)', 120.0_R8P, is_int=.true.)
call check_symbol('fact(20)', 2432902008176640000.0_R8P, is_int=.true.)
call check_symbol('fact(21)', 51090942171709440000.0_R8P)
call define('fib', ['n'], 'n < 2 ? n : fib(n - 1) + fib(n - 2)')
call check_symbol('fib(10) + fact(3)', 61.0_R8P, is_int=.true.)
call define('ev', ['n'], 'n == 0 ? 1 : od(n - 1)')
call define('od', ['n'], 'n == 0 ? 0 : ev(n - 1)')
call check_symbol('ev(10) + 10*od(7) + 100*ev(250)', 111.0_R8P, is_int=.true.)
call define('tt', ['n'], 'n == 0 ? 0 : tt(n - 1)')
call define('gt', ['n'], 'tt(n)')
call check_symbol('tt(250) + gt(249)', 0.0_R8P, is_int=.true.)
call check_assign_error('z', 'tt(251)', 'recursion depth limit exceeded')
call check_assign_error('z', 'gt(250)', 'recursion depth limit exceeded')
call check_assign_error('z', 'ev(251)', 'recursion depth limit exceeded')
call check_symbol_function('fact(x) + fib(x)', 6.0_R8P, 728.0_R8P)
call check_symbol_error('fact(1, 2)', 'function fact requires 1 variable')
call check_define_error('sin', ['x'], '2', '"sin" is a builtin function')
call check_define_error('r', ['x', 'x'], 'x', 'repeated parameter "x"')
call check_define_error('r', ['x'], 'x*', 'in function r:')
call check_assign_error('z', '$1', 'columns are only valid in using')
call check_assign_error('z', '1/0', 'undefined value')
call check_assign_error('1z', '1', 'invalid name "1z"')
call check_constant('2*pi + a_1', 2.0_R8P * 3.0_R8P + 4.0_R8P)

write(output_unit, '(A,I0,A,I0,A)') 'foresight_expression checks: ', checks - failures, ' of ', checks, ' passed'
write(output_unit, '(A,L1)') 'Are all tests passed? ', failures == 0_I4P
if (failures /= 0_I4P) error stop 1

contains
   subroutine assign(name, text)
   !< `name = text` in the test symbols, recorded as a check.
   character(len=*), intent(in)  :: name   !< Variable.
   character(len=*), intent(in)  :: text   !< Expression.
   character(len=:), allocatable :: iomsg  !< Error message.
   integer(I4P)                  :: iostat !< Status.

   call symbols%assign(name, text, iostat, iomsg)
   call record(iostat == 0_I4P, name//' = '//text//' -> '//iomsg)
   endsubroutine assign

   subroutine define(name, params, body)
   !< `name(params) = body` in the test symbols, recorded as a check.
   character(len=*), intent(in)  :: name      !< Function.
   character(len=*), intent(in)  :: params(:) !< Parameters.
   character(len=*), intent(in)  :: body      !< Body.
   character(len=:), allocatable :: iomsg     !< Error message.
   integer(I4P)                  :: iostat    !< Status.

   call symbols%define(name, params, body, iostat, iomsg)
   call record(iostat == 0_I4P, name//'(...) = '//body//' -> '//iomsg)
   endsubroutine define

   subroutine check_symbol(text, expected, is_int)
   !< `text`, compiled with the test symbols, evaluates to `expected` on the test row (an integer if `is_int`: checked
   !< through a variable assigned from it).
   character(len=*), intent(in)           :: text       !< Expression.
   real(R8P),        intent(in)           :: expected   !< Value.
   logical,          intent(in), optional :: is_int     !< Integer expected.
   type(expression_object)                :: expression !< Compiled expression.
   character(len=:), allocatable          :: iomsg      !< Error message.
   integer(I4P)                           :: iostat     !< Status.
   real(R8P)                              :: v          !< Value.
   logical                                :: found      !< Variable found.
   logical                                :: whole      !< Integer value.
   logical                                :: passed     !< Check outcome.

   call expression%compile(text, iostat, iomsg, symbols=symbols)
   passed = iostat == 0_I4P
   if (passed) passed = abs(expression%evaluate(row, 3_I4P) - expected) <= 1.0e-15_R8P * max(1.0_R8P, abs(expected))
   if (passed .and. present(is_int)) then
      call symbols%assign('check_symbol_value', text, iostat, iomsg)
      call symbols%value_of('check_symbol_value', v, found, whole)
      passed = iostat == 0_I4P .and. found .and. (whole .eqv. is_int)
   endif
   if (.not. allocated(iomsg)) iomsg = ''
   call record(passed, text//' -> '//iomsg)
   endsubroutine check_symbol

   subroutine check_symbol_function(text, x, expected)
   !< Function `text` of the dummy `x`, compiled with the test symbols, is `expected` at `x`.
   character(len=*), intent(in)  :: text       !< Expression.
   real(R8P),        intent(in)  :: x          !< Dummy value.
   real(R8P),        intent(in)  :: expected   !< Value.
   type(expression_object)       :: expression !< Compiled expression.
   character(len=:), allocatable :: iomsg      !< Error message.
   integer(I4P)                  :: iostat     !< Status.

   call expression%compile(text, iostat, iomsg, variable='x', symbols=symbols)
   call record(iostat == 0_I4P .and. expression%value_at(x) == expected, text//' -> '//iomsg)
   endsubroutine check_symbol_function

   subroutine check_symbol_error(text, message)
   !< `text` does not compile with the test symbols, and the error contains `message`.
   character(len=*), intent(in)  :: text       !< Expression.
   character(len=*), intent(in)  :: message    !< Expected part of the error.
   type(expression_object)       :: expression !< Compiled expression.
   character(len=:), allocatable :: iomsg      !< Error message.
   integer(I4P)                  :: iostat     !< Status.

   call expression%compile(text, iostat, iomsg, symbols=symbols)
   call record(iostat /= 0_I4P .and. index(iomsg, message) > 0, text//' -> '//iomsg)
   endsubroutine check_symbol_error

   subroutine check_define_error(name, params, body, message)
   !< `name(params) = body` is refused, the error containing `message`.
   character(len=*), intent(in)  :: name      !< Function.
   character(len=*), intent(in)  :: params(:) !< Parameters.
   character(len=*), intent(in)  :: body      !< Body.
   character(len=*), intent(in)  :: message   !< Expected part of the error.
   character(len=:), allocatable :: iomsg     !< Error message.
   integer(I4P)                  :: iostat    !< Status.

   call symbols%define(name, params, body, iostat, iomsg)
   call record(iostat /= 0_I4P .and. index(iomsg, message) > 0, name//'(...) = '//body//' -> '//iomsg)
   endsubroutine check_define_error

   subroutine check_assign_error(name, text, message)
   !< `name = text` is refused, the error containing `message`.
   character(len=*), intent(in)  :: name    !< Variable.
   character(len=*), intent(in)  :: text    !< Expression.
   character(len=*), intent(in)  :: message !< Expected part of the error.
   character(len=:), allocatable :: iomsg   !< Error message.
   integer(I4P)                  :: iostat  !< Status.

   call symbols%assign(name, text, iostat, iomsg)
   call record(iostat /= 0_I4P .and. index(iomsg, message) > 0, name//' = '//text//' -> '//iomsg)
   endsubroutine check_assign_error

   subroutine check_text(text, expected)
   !< The constant expression `text` as text (`text_of`) is `expected`.
   character(len=*), intent(in)  :: text      !< Expression.
   character(len=*), intent(in)  :: expected  !< Text.
   character(len=:), allocatable :: value     !< Value as text.
   character(len=:), allocatable :: iomsg     !< Error message.
   integer(I4P)                  :: iostat    !< Status.
   logical                       :: is_string !< A string.

   call symbols%text_of(text, value, is_string, iostat, iomsg)
   if (iostat /= 0_I4P) value = ''
   call record(iostat == 0_I4P .and. value == expected .and. len(value) == len(expected), &
               text//' -> ['//value//'] '//iomsg)
   endsubroutine check_text

   subroutine check_text_error(text, message)
   !< The constant expression `text` fails (compiling or evaluating), the error containing `message`.
   character(len=*), intent(in)  :: text      !< Expression.
   character(len=*), intent(in)  :: message   !< Expected part of the error.
   character(len=:), allocatable :: value     !< Value as text.
   character(len=:), allocatable :: iomsg     !< Error message.
   integer(I4P)                  :: iostat    !< Status.
   logical                       :: is_string !< A string.

   call symbols%text_of(text, value, is_string, iostat, iomsg)
   call record(iostat /= 0_I4P .and. index(iomsg, message) > 0, text//' -> '//iomsg)
   endsubroutine check_text_error

   subroutine check_constant(text, expected)
   !< The constant expression `text` is `expected`.
   character(len=*), intent(in)  :: text     !< Expression.
   real(R8P),        intent(in)  :: expected !< Value.
   character(len=:), allocatable :: iomsg    !< Error message.
   integer(I4P)                  :: iostat   !< Status.
   real(R8P)                     :: v        !< Value.

   call symbols%constant(text, v, iostat, iomsg)
   call record(iostat == 0_I4P .and. abs(v - expected) <= 1.0e-15_R8P * abs(expected), text//' -> '//iomsg)
   endsubroutine check_constant

   subroutine check_value(text, expected, tolerance)
   !< `text` evaluates to `expected` on the test row, point number 3.
   character(len=*), intent(in)           :: text       !< Expression.
   real(R8P),        intent(in)           :: expected   !< Value.
   real(R8P),        intent(in), optional :: tolerance  !< Absolute tolerance, exact if absent.
   type(expression_object)                :: expression !< Compiled expression.
   character(len=:), allocatable          :: iomsg      !< Error message.
   integer(I4P)                           :: iostat     !< Status.
   real(R8P)                              :: v          !< Value.
   logical                                :: passed     !< Check outcome.

   call expression%compile(text, iostat, iomsg)
   passed = iostat == 0_I4P
   if (passed) then
      v = expression%evaluate(row, 3_I4P)
      passed = .not. ieee_is_nan(v)
      if (passed) then
         if (present(tolerance)) then
            passed = abs(v - expected) <= tolerance
         else
            passed = v == expected
         endif
      endif
   endif
   call record(passed, text)
   endsubroutine check_value

   subroutine check_undefined(text)
   !< `text` compiles and is undefined (NaN) on the test row.
   character(len=*), intent(in)  :: text       !< Expression.
   type(expression_object)       :: expression !< Compiled expression.
   character(len=:), allocatable :: iomsg      !< Error message.
   integer(I4P)                  :: iostat     !< Status.
   logical                       :: passed     !< Check outcome.

   call expression%compile(text, iostat, iomsg)
   passed = iostat == 0_I4P
   if (passed) passed = ieee_is_nan(expression%evaluate(row, 3_I4P))
   call record(passed, text)
   endsubroutine check_undefined

   subroutine check_error(text, message)
   !< `text` does not compile, and the error contains `message`.
   character(len=*), intent(in)  :: text       !< Expression.
   character(len=*), intent(in)  :: message    !< Expected part of the error.
   type(expression_object)       :: expression !< Compiled expression.
   character(len=:), allocatable :: iomsg      !< Error message.
   integer(I4P)                  :: iostat     !< Status.

   call expression%compile(text, iostat, iomsg)
   call record(iostat /= 0_I4P .and. index(iomsg, message) > 0, text//' -> '//iomsg)
   endsubroutine check_error

   subroutine check_function(text, x, expected, tolerance)
   !< Function `text` of `x` evaluates to `expected` at `x` (NaN expected: undefined).
   character(len=*), intent(in)           :: text       !< Expression.
   real(R8P),        intent(in)           :: x          !< Variable value.
   real(R8P),        intent(in)           :: expected   !< Value, NaN if undefined.
   real(R8P),        intent(in), optional :: tolerance  !< Absolute tolerance, exact if absent.
   type(expression_object)                :: expression !< Compiled expression.
   character(len=:), allocatable          :: iomsg      !< Error message.
   integer(I4P)                           :: iostat     !< Status.
   real(R8P)                              :: v          !< Value.
   logical                                :: passed     !< Check outcome.

   call expression%compile(text, iostat, iomsg, variable='x')
   passed = iostat == 0_I4P
   if (passed) then
      v = expression%value_at(x)
      if (ieee_is_nan(expected)) then
         passed = ieee_is_nan(v)
      elseif (ieee_is_nan(v)) then
         passed = .false.
      elseif (present(tolerance)) then
         passed = abs(v - expected) <= tolerance
      else
         passed = v == expected
      endif
   endif
   call record(passed, 'function '//text)
   endsubroutine check_function

   subroutine check_function_error(text, message)
   !< Function `text` of `x` does not compile, and the error contains `message`.
   character(len=*), intent(in)  :: text       !< Expression.
   character(len=*), intent(in)  :: message    !< Expected part of the error.
   type(expression_object)       :: expression !< Compiled expression.
   character(len=:), allocatable :: iomsg      !< Error message.
   integer(I4P)                  :: iostat     !< Status.

   call expression%compile(text, iostat, iomsg, variable='x')
   call record(iostat /= 0_I4P .and. index(iomsg, message) > 0, 'function '//text//' -> '//iomsg)
   endsubroutine check_function_error

   subroutine record(passed, what)
   !< Count a check, reporting a failure.
   logical,          intent(in) :: passed !< Check outcome.
   character(len=*), intent(in) :: what   !< Check description.

   checks = checks + 1_I4P
   if (.not. passed) then
      failures = failures + 1_I4P
      write(error_unit, '(A)') 'FAILED: '//what
   endif
   endsubroutine record
endprogram foresight_expression_test
