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
use foresight_expression, only : expression_object
use penf, only : I4P, R8P

implicit none
real(R8P)    :: row(3)   !< Data row: 10, 20, missing.
integer(I4P) :: failures !< Failed checks.
integer(I4P) :: checks   !< Checks run.

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
call check_error('x*2', 'unknown name "x" (user variables are not supported) at character 1')
call check_error('1 & 2', 'bitwise operator "&" not supported')
call check_error('atan2(1)', 'atan2 needs 2 arguments')
call check_error('$', '"$" needs a column number')
call check_error('1e+', 'malformed number')
call check_error('1e999', 'number out of range')
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
call check_function_error('y', 'unknown name "y"')

write(output_unit, '(A,I0,A,I0,A)') 'foresight_expression checks: ', checks - failures, ' of ', checks, ' passed'
write(output_unit, '(A,L1)') 'Are all tests passed? ', failures == 0_I4P
if (failures /= 0_I4P) error stop 1

contains
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
