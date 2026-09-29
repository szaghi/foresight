!< foresight_format, deterministic number-to-text conversion and XML escaping.
module foresight_format
!< foresight_format, deterministic number-to-text conversion and XML escaping.
!<
!< Output files are compared byte-for-byte against reference files, and the processor-dependent details of Fortran edit
!< descriptors (optional leading zero of `F0.d`, signed zero, exponent layout) differ between compilers. Every number
!< written by foresight therefore goes through integer arithmetic here: a value is rounded once to an integer count of
!< `10**(-ndec)` units and the decimal string is assembled from its digits.
use penf, only : I4P, I8P, R8P

implicit none
private
public :: decimal_str
public :: fixed
public :: int_str
public :: xml_escape

real(R8P), parameter :: FIXED_CLAMP = 1.0e11_R8P !< Magnitude clamp keeping `v * 10**ndec` inside I8P for `ndec <= 7`.

contains
   pure function int_str(n) result(str)
   !< Integer to minimal-width decimal string.
   integer(I8P), intent(in)      :: n      !< Integer.
   character(len=:), allocatable :: str    !< Decimal string.
   character(len=21)             :: buffer !< Wide enough for `-huge(1_I8P)`.

   write(buffer, '(I0)') n
   str = trim(buffer)
   endfunction int_str

   pure function decimal_str(n, ndec) result(str)
   !< Exact decimal string of the value `n * 10**(-ndec)`, without trailing fractional zeros.
   !<
   !< A negative `ndec` appends zeros: `decimal_str(15_I8P, -2_I4P)` is `1500`.
   integer(I8P), intent(in)      :: n        !< Integer mantissa.
   integer(I4P), intent(in)      :: ndec     !< Number of decimal digits of the mantissa.
   character(len=:), allocatable :: str      !< Decimal string.
   character(len=:), allocatable :: digits   !< Digits of `|n|`.
   character(len=:), allocatable :: fraction !< Fractional digits.

   if (n == 0_I8P) then
      str = '0'
      return
   endif
   digits = int_str(abs(n))
   if (ndec <= 0_I4P) then
      str = digits//repeat('0', -ndec)
   else
      if (len(digits) <= ndec) digits = repeat('0', ndec - len(digits) + 1)//digits
      fraction = digits(len(digits) - ndec + 1:)
      str = digits(1:len(digits) - ndec)
      do while (len(fraction) > 0)
         if (fraction(len(fraction):len(fraction)) /= '0') exit
         fraction = fraction(1:len(fraction) - 1)
      enddo
      if (len(fraction) > 0) str = str//'.'//fraction
   endif
   if (n < 0_I8P) str = '-'//str
   endfunction decimal_str

   pure function fixed(v, ndec) result(str)
   !< Value rounded to `ndec <= 7` decimals, trailing zeros stripped; `-0` prints as `0`.
   !<
   !< Magnitudes are clamped to 1e11: callers format pixel and unit-square coordinates only, where larger values lie far
   !< outside any clip region. `v` must not be NaN.
   real(R8P),    intent(in)      :: v    !< Value.
   integer(I4P), intent(in)      :: ndec !< Number of decimals.
   character(len=:), allocatable :: str  !< Decimal string.

   str = decimal_str(nint(max(-FIXED_CLAMP, min(FIXED_CLAMP, v)) * 10.0_R8P**ndec, I8P), ndec)
   endfunction fixed

   pure function xml_escape(text) result(escaped)
   !< Escape the XML special characters `&`, `<`, `>` and `"`.
   character(len=*), intent(in)  :: text    !< Raw text.
   character(len=:), allocatable :: escaped !< Escaped text.
   integer(I4P)                  :: i       !< Character counter.

   escaped = ''
   do i = 1_I4P, len(text, kind=I4P)
      select case (text(i:i))
      case ('&')
         escaped = escaped//'&amp;'
      case ('<')
         escaped = escaped//'&lt;'
      case ('>')
         escaped = escaped//'&gt;'
      case ('"')
         escaped = escaped//'&quot;'
      case default
         escaped = escaped//text(i:i)
      endselect
   enddo
   endfunction xml_escape
endmodule foresight_format
