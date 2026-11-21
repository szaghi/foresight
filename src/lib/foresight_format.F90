!< foresight_format, deterministic number-to-text conversion and XML escaping.
module foresight_format
!< foresight_format, deterministic number-to-text conversion and XML escaping.
!<
!< Output files are compared byte-for-byte against reference files, and the processor-dependent details of Fortran edit
!< descriptors (optional leading zero of `F0.d`, signed zero, exponent layout) differ between compilers. Every number
!< written by foresight therefore goes through integer arithmetic here: a value is rounded once to an integer count of
!< `10**(-ndec)` units and the decimal string is assembled from its digits.
!<
!< User tick formats (gnuplot `set format`, a printf subset) are applied the same way, to the exact decimal value of a
!< tick: `format_decimal` works on digit strings and rounds half to even, so the interactive viewer, which mirrors it,
!< prints identical labels.
!<
!< printf conversions of gnuplot's `sprintf` (`c_real`, `c_integer`, `c_string`) are C's: a real is converted from its
!< exact binary value (`exact_decimal`), as glibc does, so `%.2f` of 2.675 is 2.67 (the double is 2.67499999...).
!<
!< Text to real goes through `real_from_decimal`, which never raises an IEEE overflow: a debug build trapping overflows
!< would otherwise stop on a data cell such as `1e999`, inside the C library conversion.
use, intrinsic :: ieee_arithmetic, only : ieee_copy_sign, ieee_is_finite, ieee_is_nan
use, intrinsic :: ieee_exceptions, only : ieee_get_flag, ieee_get_halting_mode, ieee_overflow, ieee_set_flag, &
                                         ieee_set_halting_mode
use penf, only : I4P, I8P, R8P

implicit none
private
public :: c_integer
public :: c_real
public :: c_string
public :: decimal_of
public :: decimal_str
public :: exact_decimal
public :: fixed
public :: format_check
public :: format_decimal
public :: gnuplot_real
public :: int_str
public :: parse_decimal
public :: real_from_decimal
public :: real_str
public :: split_format
public :: xml_escape

integer(I8P), parameter :: LIMB = 1000000000_I8P !< Base of the exact decimal digits.
real(R8P), parameter :: FIXED_CLAMP = 1.0e11_R8P !< Magnitude clamp keeping `v * 10**ndec` inside I8P for `ndec <= 7`.

contains
   subroutine real_from_decimal(text, value, ok)
   !< Value of the decimal number `text` (Fortran list-directed syntax, e.g. `-1.5e-3`); `ok` false if it is malformed or
   !< beyond the real range, never raising an IEEE overflow.
   !<
   !< Only a text whose exponent and length could reach the overflow range is read with the overflow halting off (and
   !< the overflow flag restored): the common case stays a plain read.
   character(len=*), intent(in)  :: text     !< Decimal text.
   real(R8P),        intent(out) :: value    !< Value.
   logical,          intent(out) :: ok       !< Well formed and finite.
   integer(I4P)                  :: ios      !< Conversion status.
   integer(I4P)                  :: e        !< Exponent marker position.
   integer(I4P)                  :: digits   !< Exponent digits, nonzero ones from the first.
   logical                       :: halting  !< Overflow halting on.
   logical                       :: flagged  !< Overflow flag before the read.

   value = 0.0_R8P
   ! the decimal magnitude is at most the text length plus the exponent: bounded by the exponent digits
   e = scan(text, 'eEdD', back=.true., kind=I4P)
   digits = 0_I4P
   if (e > 0_I4P) then
      digits = verify(text(e + 1_I4P:), '+-0', kind=I4P)
      if (digits > 0_I4P) digits = len(text, kind=I4P) - e - digits + 1_I4P
   endif
   if (digits <= 2_I4P .and. len(text) < 200) then
      read(text, *, iostat=ios) value
   else
      call ieee_get_halting_mode(ieee_overflow, halting)
      call ieee_get_flag(ieee_overflow, flagged)
      if (halting) call ieee_set_halting_mode(ieee_overflow, .false.)
      read(text, *, iostat=ios) value
      call ieee_set_flag(ieee_overflow, flagged)
      if (halting) call ieee_set_halting_mode(ieee_overflow, .true.)
   endif
   ok = ios == 0_I4P
   if (ok) ok = ieee_is_finite(value)
   if (.not. ok) value = 0.0_R8P
   endsubroutine real_from_decimal

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

   pure function real_str(v) result(str)
   !< Finite `v` with 15 significant digits, as `d.ddde<exp>` (trailing zeros stripped) or `0`.
   !<
   !< Readable back by any language to within 1e-15 relative: used for metadata consumed by the interactive viewer.
   real(R8P), intent(in)         :: v        !< Value.
   character(len=:), allocatable :: str      !< Text.
   character(len=:), allocatable :: digits   !< Significant digits.
   integer(I8P)                  :: m        !< 15-digit mantissa.
   integer(I4P)                  :: e        !< Decimal exponent.

   if (v == 0.0_R8P) then
      str = '0'
      return
   endif
   e = floor(log10(abs(v)), I4P)
   m = nint(scale10(abs(v), 14_I4P - e), I8P)
   if (m < 10_I8P**14) then
      e = e - 1_I4P
      m = nint(scale10(abs(v), 14_I4P - e), I8P)
   endif
   if (m >= 10_I8P**15) then
      m = m / 10_I8P
      e = e + 1_I4P
   endif
   digits = decimal_str(m, 14_I4P)
   str = digits//'e'//int_str(int(e, I8P))
   if (v < 0.0_R8P) str = '-'//str
   endfunction real_str

   pure function xml_escape(text) result(escaped)
   !< Escape the XML special characters `&`, `<`, `>` and `"`, and new lines (`&#10;`: an attribute keeps them).
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
      case (achar(10))
         escaped = escaped//'&#10;'
      case default
         escaped = escaped//text(i:i)
      endselect
   enddo
   endfunction xml_escape

   pure subroutine decimal_of(v, n, e)
   !< Finite `v` rounded to 15 significant digits, as the exact decimal `n * 10**e` without trailing zeros in `n`.
   real(R8P),    intent(in)  :: v !< Value.
   integer(I8P), intent(out) :: n !< Mantissa.
   integer(I4P), intent(out) :: e !< Exponent.

   n = 0_I8P
   e = 0_I4P
   if (v == 0.0_R8P) return
   ! same steps as real_str
   e = floor(log10(abs(v)), I4P)
   n = nint(scale10(abs(v), 14_I4P - e), I8P)
   if (n < 10_I8P**14) then
      e = e - 1_I4P
      n = nint(scale10(abs(v), 14_I4P - e), I8P)
   endif
   if (n >= 10_I8P**15) then
      n = n / 10_I8P
      e = e + 1_I4P
   endif
   e = e - 14_I4P
   do while (modulo(n, 10_I8P) == 0_I8P)
      n = n / 10_I8P
      e = e + 1_I4P
   enddo
   if (v < 0.0_R8P) n = -n
   endsubroutine decimal_of

   pure subroutine parse_decimal(text, n, e, ok)
   !< Exact value of the decimal number `text` (`[sign]digits[.digits][e[sign]digits]`) as `n * 10**e`, without
   !< trailing zeros in `n`; `ok` false if malformed or beyond 18 significant digits.
   character(len=*), intent(in)  :: text   !< Number.
   integer(I8P),     intent(out) :: n      !< Mantissa.
   integer(I4P),     intent(out) :: e      !< Exponent.
   logical,          intent(out) :: ok     !< Well formed.
   character(len=:), allocatable :: digits !< Mantissa digits.
   integer(I4P)                  :: i      !< Character counter.
   integer(I4P)                  :: nfrac  !< Fraction digits.
   integer(I4P)                  :: x      !< Exponent part.
   integer(I4P)                  :: ios    !< Conversion status.
   logical                       :: point  !< Decimal point seen.
   logical                       :: minus  !< Negative.

   n = 0_I8P
   e = 0_I4P
   ok = .false.
   digits = ''
   nfrac = 0_I4P
   x = 0_I4P
   point = .false.
   i = 1_I4P
   minus = .false.
   if (len(text) == 0) return
   if (scan(text(1:1), '+-') > 0) then
      minus = text(1:1) == '-'
      i = 2_I4P
   endif
   do while (i <= len(text))
      if (text(i:i) == '.') then
         if (point) return
         point = .true.
      elseif (scan(text(i:i), '0123456789') > 0) then
         digits = digits//text(i:i)
         if (point) nfrac = nfrac + 1_I4P
      else
         exit
      endif
      i = i + 1_I4P
   enddo
   if (len(digits) == 0) return
   if (i <= len(text)) then
      if (scan(text(i:i), 'eEdD') == 0 .or. i == len(text)) return
      if (verify(text(i + 1_I4P:), '+-0123456789') > 0 .or. scan(text(i + 2_I4P:), '+-') > 0) return
      if (verify(text(i + 1_I4P:), '+-') == 0 .or. len(text) - i > 5) return
      read(text(i + 1_I4P:), *, iostat=ios) x
      if (ios /= 0_I4P) return
   endif
   do while (len(digits) > 1 .and. digits(1:1) == '0')
      digits = digits(2:)
   enddo
   if (len(digits) > 18) return
   read(digits, *) n
   e = x - nfrac
   if (n == 0_I8P) then
      e = 0_I4P
   else
      do while (modulo(n, 10_I8P) == 0_I8P)
         n = n / 10_I8P
         e = e + 1_I4P
      enddo
   endif
   if (minus) n = -n
   ok = .true.
   endsubroutine parse_decimal

   pure function format_check(format) result(message)
   !< Empty if `format` is a supported tick format: text with one conversion `%[flags][width][.precision]type`, flags
   !< among `-+ 0`, type `f`, `e`, `E`, `g`, `G` or `h` (gnuplot: `g` with a `x10` superscript exponent), and `%%` for `%`.
   character(len=*), intent(in)  :: format  !< Format.
   character(len=:), allocatable :: message !< Problem, empty if none.
   character(len=:), allocatable :: prefix  !< Text before the conversion.
   character(len=:), allocatable :: suffix  !< Text after the conversion.
   character(len=:), allocatable :: flags   !< Conversion flags.
   character(len=1)              :: type    !< Conversion type.
   integer(I4P)                  :: width   !< Field width.
   integer(I4P)                  :: prec    !< Precision, -1 if absent.

   call split_format(format, prefix, flags, width, prec, type, suffix, message)
   endfunction format_check

   pure subroutine format_decimal(format, n, e, label, sup)
   !< Apply the tick `format` (see `format_check`; the format itself is returned if invalid) to the exact value
   !< `n * 10**e`, as C printf would to that decimal, rounding half to even. `sup` is the exponent of the `%h` form.
   character(len=*),              intent(in)  :: format  !< Format.
   integer(I8P),                  intent(in)  :: n       !< Mantissa.
   integer(I4P),                  intent(in)  :: e       !< Exponent.
   character(len=:), allocatable, intent(out) :: label   !< Label.
   character(len=:), allocatable, intent(out) :: sup     !< Superscript, empty if none.
   character(len=:), allocatable              :: prefix  !< Text before the conversion.
   character(len=:), allocatable              :: suffix  !< Text after the conversion.
   character(len=:), allocatable              :: flags   !< Conversion flags.
   character(len=:), allocatable              :: message !< Format problem.
   character(len=:), allocatable              :: digits  !< Digits of |n|.
   character(len=:), allocatable              :: body    !< Converted number without sign.
   character(len=:), allocatable              :: sign    !< Sign text.
   character(len=1)                           :: type    !< Conversion type.
   integer(I4P)                               :: width   !< Field width.
   integer(I4P)                               :: prec    !< Precision, -1 if absent.
   integer(I4P)                               :: x       !< Decimal exponent of the leading digit, after rounding.
   integer(I4P)                               :: p       !< Significant digits of %g.

   sup = ''
   call split_format(format, prefix, flags, width, prec, type, suffix, message)
   if (len(message) > 0) then
      label = format
      return
   endif
   digits = int_str(abs(n))
   select case (type)
   case ('f')
      if (prec < 0_I4P) prec = 6_I4P
      body = fixed_digits(digits, e, prec)
   case ('e', 'E')
      if (prec < 0_I4P) prec = 6_I4P
      call exp_digits(digits, e, prec, body, x)
      body = body//exp_text(type, x)
   case default
      ! g, G, h: precision in significant digits, then the shorter of fixed and exponent forms, trailing zeros cut
      p = prec
      if (p < 0_I4P) p = 6_I4P
      if (p == 0_I4P) p = 1_I4P
      call exp_digits(digits, e, p - 1_I4P, body, x)
      if (x < p .and. x >= -4_I4P) then
         body = strip_zeros(fixed_digits(digits, e, p - 1_I4P - x))
      else
         body = strip_zeros(body)
         if (type == 'h') then
            body = body//'x10'
            sup = int_str(int(x, I8P))
         elseif (type == 'G') then
            body = body//exp_text('E', x)
         else
            body = body//exp_text('e', x)
         endif
      endif
   endselect
   sign = ''
   if (n < 0_I8P) then
      sign = '-'
   elseif (index(flags, '+') > 0) then
      sign = '+'
   elseif (index(flags, ' ') > 0) then
      sign = ' '
   endif
   if (len(sign) + len(body) < width) then
      if (index(flags, '-') > 0) then
         body = body//repeat(' ', width - len(sign) - len(body))
      elseif (index(flags, '0') > 0 .and. len(sup) == 0) then
         body = repeat('0', width - len(sign) - len(body))//body
      else
         sign = repeat(' ', width - len(sign) - len(body))//sign
      endif
   endif
   label = prefix//sign//body//suffix
   endsubroutine format_decimal

   pure subroutine split_format(format, prefix, flags, width, prec, type, suffix, message)
   !< Split a tick format into its text around the one conversion and the conversion fields.
   character(len=*),              intent(in)  :: format  !< Format.
   character(len=:), allocatable, intent(out) :: prefix  !< Text before the conversion, `%%` resolved.
   character(len=:), allocatable, intent(out) :: flags   !< Flags.
   integer(I4P),                  intent(out) :: width   !< Field width, 0 if absent.
   integer(I4P),                  intent(out) :: prec    !< Precision, -1 if absent.
   character(len=1),              intent(out) :: type    !< Conversion type.
   character(len=:), allocatable, intent(out) :: suffix  !< Text after the conversion, `%%` resolved.
   character(len=:), allocatable, intent(out) :: message !< Problem, empty if none.
   integer(I4P)                               :: i       !< Character counter.
   integer(I4P)                               :: j       !< Field start.
   logical                                    :: found   !< Conversion found.

   prefix = ''
   suffix = ''
   flags = ''
   width = 0_I4P
   prec = -1_I4P
   type = ' '
   message = ''
   found = .false.
   i = 1_I4P
   do while (i <= len(format))
      if (format(i:i) /= '%') then
         if (found) then
            suffix = suffix//format(i:i)
         else
            prefix = prefix//format(i:i)
         endif
         i = i + 1_I4P
         cycle
      endif
      if (i == len(format)) then
         message = 'format ends with "%"'
         return
      endif
      if (format(i + 1_I4P:i + 1_I4P) == '%') then
         if (found) then
            suffix = suffix//'%'
         else
            prefix = prefix//'%'
         endif
         i = i + 2_I4P
         cycle
      endif
      if (found) then
         message = 'more than one conversion in "'//format//'"'
         return
      endif
      found = .true.
      i = i + 1_I4P
      j = i
      do while (i <= len(format))
         if (scan(format(i:i), '-+ 0') == 0) exit
         i = i + 1_I4P
      enddo
      flags = format(j:i - 1_I4P)
      j = i
      do while (i <= len(format))
         if (scan(format(i:i), '0123456789') == 0) exit
         i = i + 1_I4P
      enddo
      if (i > j) then
         if (i - j > 3_I4P) then
            message = 'width too large in "'//format//'"'
            return
         endif
         read(format(j:i - 1_I4P), *) width
      endif
      if (i <= len(format)) then
         if (format(i:i) == '.') then
            i = i + 1_I4P
            j = i
            do while (i <= len(format))
               if (scan(format(i:i), '0123456789') == 0) exit
               i = i + 1_I4P
            enddo
            if (i - j > 2_I4P) then
               message = 'precision too large in "'//format//'"'
               return
            endif
            prec = 0_I4P
            if (i > j) read(format(j:i - 1_I4P), *) prec
         endif
      endif
      if (i > len(format)) then
         message = 'incomplete conversion in "'//format//'"'
         return
      endif
      type = format(i:i)
      if (scan(type, 'feEgGh') == 0) then
         message = 'unsupported conversion "%'//type//'" in "'//format//'" (supported: f, e, E, g, G, h)'
         return
      endif
      i = i + 1_I4P
   enddo
   if (.not. found) message = 'no conversion in "'//format//'"'
   endsubroutine split_format

   pure subroutine exact_decimal(v, digits, e)
   !< The exact decimal value of the finite `v`: `|v| = digits * 10**e`, `digits` without leading or trailing zeros (`0`
   !< for zero). A double is `m * 2**k`, that is `m * 5**(-k) * 10**k` when `k < 0`: the product is computed exactly in
   !< base 10**9 limbs (at most 767 digits).
   real(R8P),                     intent(in)  :: v      !< Value.
   character(len=:), allocatable, intent(out) :: digits !< Decimal digits.
   integer(I4P),                  intent(out) :: e      !< Decimal exponent.
   integer(I8P)                               :: limbs(100) !< Base 10**9 digits, least significant first.
   integer(I8P)                               :: m      !< Binary mantissa.
   integer(I4P)                               :: k      !< Binary exponent.
   integer(I4P)                               :: n      !< Limbs in use.
   integer(I4P)                               :: step   !< Exponent applied at once.
   integer(I4P)                               :: i      !< Counter.
   character(len=9)                           :: chunk  !< One limb.

   e = 0_I4P
   if (v == 0.0_R8P) then
      digits = '0'
      return
   endif
   m = int(fraction(abs(v)) * 2.0_R8P**53, I8P)
   k = exponent(abs(v)) - 53_I4P
   do while (k < 0_I4P .and. modulo(m, 2_I8P) == 0_I8P)
      m = m / 2_I8P
      k = k + 1_I4P
   enddo
   limbs = 0_I8P
   limbs(1) = modulo(m, LIMB)
   limbs(2) = modulo(m / LIMB, LIMB)
   limbs(3) = m / LIMB**2
   n = 3_I4P
   if (k >= 0_I4P) then
      do while (k > 0_I4P)
         step = min(k, 30_I4P)
         call limbs_multiply(limbs, n, 2_I8P**step)
         k = k - step
      enddo
   else
      e = k
      k = -k
      do while (k > 0_I4P)
         step = min(k, 13_I4P)
         call limbs_multiply(limbs, n, 5_I8P**step)
         k = k - step
      enddo
   endif
   do while (n > 1_I4P .and. limbs(n) == 0_I8P)
      n = n - 1_I4P
   enddo
   digits = int_str(limbs(n))
   do i = n - 1_I4P, 1_I4P, -1_I4P
      write(chunk, '(I9.9)') limbs(i)
      digits = digits//chunk
   enddo
   i = len(digits, kind=I4P)
   do while (i > 1_I4P .and. digits(i:i) == '0')
      i = i - 1_I4P
   enddo
   e = e + len(digits, kind=I4P) - i
   digits = digits(1:i)
   endsubroutine exact_decimal

   pure function c_real(flags, width, prec, type, v) result(text)
   !< C printf of the real `v` with the conversion `%<flags><width>.<prec><type>`, `type` among `f F e E g G`, `flags`
   !< among `-+ 0#`, `prec` -1 if absent (6): glibc's output, from the exact binary value, rounded half to even.
   character(len=*), intent(in)  :: flags !< Flags.
   integer(I4P),     intent(in)  :: width !< Field width, 0 if none.
   integer(I4P),     intent(in)  :: prec  !< Precision, -1 if absent.
   character(len=1), intent(in)  :: type  !< Conversion.
   real(R8P),        intent(in)  :: v     !< Value.
   character(len=:), allocatable :: text  !< Converted text.
   character(len=:), allocatable :: digits !< Exact digits of |v|.
   character(len=:), allocatable :: body  !< Text without sign.
   character(len=:), allocatable :: lead  !< Sign.
   integer(I4P)                  :: e     !< Exponent of `digits`.
   integer(I4P)                  :: p     !< Precision used.
   integer(I4P)                  :: x     !< Exponent of the leading digit.
   logical                       :: upper !< Upper case conversion.
   logical                       :: alt   !< `#` flag.

   upper = scan(type, 'FEG') > 0
   alt = index(flags, '#') > 0
   ! the sign bit, of a zero or a NaN too (no ordered comparison: a NaN would trap)
   lead = ''
   if (ieee_copy_sign(1.0_R8P, v) < 0.0_R8P) then
      lead = '-'
   elseif (index(flags, '+') > 0) then
      lead = '+'
   elseif (index(flags, ' ') > 0) then
      lead = ' '
   endif
   if (.not. ieee_is_finite(v)) then
      if (ieee_is_nan(v)) then
         body = 'nan'
      else
         body = 'inf'
      endif
      if (upper) body = upper_case(body)
      text = pad(lead, body, flags, width, .false.)
      return
   endif
   call exact_decimal(v, digits, e)
   p = prec
   if (p < 0_I4P) p = 6_I4P
   select case (type)
   case ('f', 'F')
      body = fixed_digits(digits, e, p)
      if (alt .and. p == 0_I4P) body = body//'.'
   case ('e', 'E')
      call exp_digits(digits, e, p, body, x)
      if (alt .and. p == 0_I4P) body = body//'.'
      body = body//exp_text(merge('E', 'e', upper), x)
   case default
      ! g, G: precision in significant digits, the fixed form when the exponent is in [-4, p)
      if (p == 0_I4P) p = 1_I4P
      call exp_digits(digits, e, p - 1_I4P, body, x)
      if (x < p .and. x >= -4_I4P) then
         body = fixed_digits(digits, e, p - 1_I4P - x)
         if (alt) then
            if (index(body, '.') == 0) body = body//'.'
         else
            body = strip_zeros(body)
         endif
      else
         if (alt) then
            if (index(body, '.') == 0) body = body//'.'
         else
            body = strip_zeros(body)
         endif
         body = body//exp_text(merge('E', 'e', upper), x)
      endif
   endselect
   text = pad(lead, body, flags, width, .true.)
   endfunction c_real

   pure function c_integer(flags, width, prec, type, i) result(text)
   !< C printf of the integer `i` with `%<flags><width>.<prec><type>`, `type` among `d i u o x X c`, as gnuplot passes it:
   !< a value that fits 32 bits as a C int (so `%x` of -1 is ffffffff), else as a 64-bit integer.
   character(len=*), intent(in)  :: flags  !< Flags.
   integer(I4P),     intent(in)  :: width  !< Field width, 0 if none.
   integer(I4P),     intent(in)  :: prec   !< Precision (minimum digits), -1 if absent.
   character(len=1), intent(in)  :: type   !< Conversion.
   integer(I8P),     intent(in)  :: i      !< Value.
   character(len=:), allocatable :: text   !< Converted text.
   character(len=:), allocatable :: body   !< Digits.
   character(len=:), allocatable :: lead   !< Sign or prefix.
   integer(I8P)                  :: u      !< Bits of the unsigned value.
   logical                       :: small  !< Fits a C int.
   logical                       :: zeros  !< `0` flag applies.

   small = i >= -2147483648_I8P .and. i <= 2147483647_I8P
   lead = ''
   select case (type)
   case ('c')
      text = pad('', achar(int(modulo(i, 256_I8P))), flags, width, .false.)
      return
   case ('d', 'i')
      if (i == -huge(1_I8P) - 1_I8P) then
         body = '9223372036854775808'
      else
         body = int_str(abs(i))
      endif
      if (i < 0_I8P) then
         lead = '-'
      elseif (index(flags, '+') > 0) then
         lead = '+'
      elseif (index(flags, ' ') > 0) then
         lead = ' '
      endif
   case default
      u = i
      if (small .and. i < 0_I8P) u = i + 4294967296_I8P
      select case (type)
      case ('u')
         body = unsigned_decimal(u)
      case ('o')
         body = radix_digits(u, 3_I4P, '01234567')
         if (index(flags, '#') > 0 .and. body(1:1) /= '0') body = '0'//body
      case ('x')
         body = radix_digits(u, 4_I4P, '0123456789abcdef')
         if (index(flags, '#') > 0 .and. u /= 0_I8P) lead = '0x'
      case default
         body = radix_digits(u, 4_I4P, '0123456789ABCDEF')
         if (index(flags, '#') > 0 .and. u /= 0_I8P) lead = '0X'
      endselect
   endselect
   if (prec >= 0_I4P) then
      if (prec == 0_I4P .and. i == 0_I8P .and. type /= 'o') body = ''
      if (len(body) < prec) body = repeat('0', prec - len(body))//body
   endif
   zeros = prec < 0_I4P
   text = pad(lead, body, flags, width, zeros)
   endfunction c_integer

   pure function c_string(flags, width, prec, s) result(text)
   !< C printf of the string `s` with `%<flags><width>.<prec>s`: the precision cuts, the width pads.
   character(len=*), intent(in)  :: flags !< Flags.
   integer(I4P),     intent(in)  :: width !< Field width, 0 if none.
   integer(I4P),     intent(in)  :: prec  !< Most characters, -1 if absent.
   character(len=*), intent(in)  :: s     !< Value.
   character(len=:), allocatable :: text  !< Converted text.

   if (prec >= 0_I4P .and. prec < len(s)) then
      text = pad('', s(1:prec), flags, width, .false.)
   else
      text = pad('', s, flags, width, .false.)
   endif
   endfunction c_string

   pure function gnuplot_real(v) result(text)
   !< A real as gnuplot's `print` shows it: `%.15g`, with `.0` appended to an integral value (`100.0`, `-0.0`), `NaN`.
   real(R8P), intent(in)         :: v    !< Value.
   character(len=:), allocatable :: text !< Text.

   if (ieee_is_nan(v)) then
      text = 'NaN'
      return
   endif
   text = c_real('', 0_I4P, 15_I4P, 'g', v)
   if (verify(text, '-0123456789') == 0) text = text//'.0'
   endfunction gnuplot_real

   ! private procedures
   pure function scale10(x, e) result(y)
   !< `x * 10**e`, in steps of at most 10**22 (exact powers of ten) to never overflow an intermediate.
   real(R8P),    intent(in) :: x  !< Value.
   integer(I4P), intent(in) :: e  !< Decimal exponent.
   real(R8P)                :: y  !< Scaled value.
   integer(I4P)             :: k  !< Remaining exponent.

   y = x
   k = e
   do while (k > 22_I4P)
      y = y * 1.0e22_R8P
      k = k - 22_I4P
   enddo
   do while (k < -22_I4P)
      y = y / 1.0e22_R8P
      k = k + 22_I4P
   enddo
   if (k >= 0_I4P) then
      y = y * 10.0_R8P**k
   else
      y = y / 10.0_R8P**(-k)
   endif
   endfunction scale10


   pure function round_digits(digits, drop) result(rounded)
   !< The decimal integer `digits` with its last `drop` digits removed, rounded half to even; `drop <= 0` appends
   !< `-drop` zeros. No leading zeros, except for `0`.
   character(len=*), intent(in)  :: digits  !< Decimal integer.
   integer(I4P),     intent(in)  :: drop    !< Digits to remove.
   character(len=:), allocatable :: rounded !< Result.
   character(len=:), allocatable :: work    !< Padded digits.
   character(len=:), allocatable :: tail    !< Removed digits.
   integer(I4P)                  :: k       !< Digit counter.
   logical                       :: up      !< Round up.

   if (drop <= 0_I4P) then
      rounded = digits//repeat('0', -drop)
   else
      work = repeat('0', max(0_I4P, drop + 1_I4P - len(digits, kind=I4P)))//digits
      tail = work(len(work) - drop + 1:)
      rounded = work(1:len(work) - drop)
      if (tail(1:1) > '5') then
         up = .true.
      elseif (tail(1:1) < '5') then
         up = .false.
      elseif (verify(tail(2:), '0') > 0) then
         up = .true.
      else
         up = scan(rounded(len(rounded):len(rounded)), '13579') > 0
      endif
      if (up) then
         k = len(rounded, kind=I4P)
         do while (k >= 1_I4P)
            if (rounded(k:k) /= '9') exit
            rounded(k:k) = '0'
            k = k - 1_I4P
         enddo
         if (k == 0_I4P) then
            rounded = '1'//rounded
         else
            rounded(k:k) = achar(iachar(rounded(k:k)) + 1)
         endif
      endif
   endif
   do while (len(rounded) > 1 .and. rounded(1:1) == '0')
      rounded = rounded(2:)
   enddo
   endfunction round_digits

   pure function fixed_digits(digits, e, prec) result(text)
   !< `digits * 10**e` with `prec` decimals (printf `%.<prec>f`), rounded half to even.
   character(len=*), intent(in)  :: digits  !< Decimal integer, no sign.
   integer(I4P),     intent(in)  :: e       !< Exponent.
   integer(I4P),     intent(in)  :: prec    !< Decimals.
   character(len=:), allocatable :: text    !< Result.
   character(len=:), allocatable :: units   !< Value in units of 10**(-prec).

   units = round_digits(digits, -prec - e)
   if (len(units) <= prec) units = repeat('0', prec - len(units) + 1)//units
   text = units(1:len(units) - prec)
   if (prec > 0_I4P) text = text//'.'//units(len(units) - prec + 1:)
   endfunction fixed_digits

   pure subroutine exp_digits(digits, e, prec, mantissa, x)
   !< Mantissa of `digits * 10**e` in exponent form with `prec` decimals (printf `%.<prec>e`), and its exponent.
   character(len=*),              intent(in)  :: digits   !< Decimal integer, no sign.
   integer(I4P),                  intent(in)  :: e        !< Exponent.
   integer(I4P),                  intent(in)  :: prec     !< Decimals of the mantissa.
   character(len=:), allocatable, intent(out) :: mantissa !< Mantissa.
   integer(I4P),                  intent(out) :: x        !< Exponent of the leading digit.
   character(len=:), allocatable              :: kept     !< Significant digits kept.

   if (verify(digits, '0') == 0) then
      kept = repeat('0', prec + 1_I4P)
      x = 0_I4P
   else
      x = len(digits, kind=I4P) - 1_I4P + e
      kept = round_digits(digits, len(digits, kind=I4P) - prec - 1_I4P)
      if (len(kept) > prec + 1_I4P) then
         ! rounded up to the next power of ten
         kept = kept(1:prec + 1_I4P)
         x = x + 1_I4P
      endif
   endif
   mantissa = kept(1:1)
   if (prec > 0_I4P) mantissa = mantissa//'.'//kept(2:)
   endsubroutine exp_digits

   pure function exp_text(letter, x) result(text)
   !< C exponent text: letter, sign, at least two digits.
   character(len=1), intent(in)  :: letter !< `e` or `E`.
   integer(I4P),     intent(in)  :: x      !< Exponent.
   character(len=:), allocatable :: text   !< Exponent text.
   character(len=:), allocatable :: digits !< Digits of |x|.

   digits = int_str(int(abs(x), I8P))
   if (len(digits) < 2) digits = '0'//digits
   if (x < 0_I4P) then
      text = letter//'-'//digits
   else
      text = letter//'+'//digits
   endif
   endfunction exp_text

   pure function strip_zeros(text) result(stripped)
   !< Remove trailing zeros of a fraction, and the point if nothing remains after it.
   character(len=*), intent(in)  :: text     !< Number without exponent.
   character(len=:), allocatable :: stripped !< Result.

   stripped = text
   if (index(stripped, '.') == 0) return
   do while (stripped(len(stripped):len(stripped)) == '0')
      stripped = stripped(1:len(stripped) - 1)
   enddo
   if (stripped(len(stripped):len(stripped)) == '.') stripped = stripped(1:len(stripped) - 1)
   endfunction strip_zeros
   pure subroutine limbs_multiply(limbs, n, f)
   !< `limbs(1:n) *= f` (base 10**9, least significant first; `f` below 2**31), `n` grown with the carry.
   integer(I8P), intent(inout) :: limbs(:) !< Digits.
   integer(I4P), intent(inout) :: n        !< Limbs in use.
   integer(I8P), intent(in)    :: f        !< Factor.
   integer(I8P)                :: carry    !< Carry.
   integer(I8P)                :: p        !< Partial product.
   integer(I4P)                :: j        !< Counter.

   carry = 0_I8P
   do j = 1_I4P, n
      p = limbs(j) * f + carry
      limbs(j) = modulo(p, LIMB)
      carry = p / LIMB
   enddo
   do while (carry > 0_I8P)
      n = n + 1_I4P
      limbs(n) = modulo(carry, LIMB)
      carry = carry / LIMB
   enddo
   endsubroutine limbs_multiply

   pure function pad(sign, body, flags, width, zeros) result(text)
   !< `sign` and `body` padded to `width` as printf: left justified with `-`, zero filled after the sign with `0` (when
   !< `zeros` allows it), else right justified with blanks.
   character(len=*), intent(in)  :: sign  !< Sign or prefix.
   character(len=*), intent(in)  :: body  !< Body.
   character(len=*), intent(in)  :: flags !< Flags.
   integer(I4P),     intent(in)  :: width !< Field width.
   logical,          intent(in)  :: zeros !< `0` flag allowed.
   character(len=:), allocatable :: text  !< Result.
   integer(I4P)                  :: gap   !< Padding.

   gap = width - len(sign, kind=I4P) - len(body, kind=I4P)
   if (gap <= 0_I4P) then
      text = sign//body
   elseif (index(flags, '-') > 0) then
      text = sign//body//repeat(' ', gap)
   elseif (index(flags, '0') > 0 .and. zeros) then
      text = sign//repeat('0', gap)//body
   else
      text = repeat(' ', gap)//sign//body
   endif
   endfunction pad

   pure function radix_digits(u, bits, symbols) result(text)
   !< Digits of `u` read as an unsigned 64-bit integer, `bits` per digit (3 octal, 4 hexadecimal).
   integer(I8P),     intent(in)  :: u       !< Value (bits).
   integer(I4P),     intent(in)  :: bits    !< Bits per digit.
   character(len=*), intent(in)  :: symbols !< Digit symbols.
   character(len=:), allocatable :: text    !< Digits.
   integer(I8P)                  :: w       !< Remaining bits.
   integer(I4P)                  :: d       !< Digit.

   text = ''
   w = u
   do
      d = int(iand(w, 2_I8P**bits - 1_I8P), I4P)
      text = symbols(d + 1:d + 1)//text
      w = ishft(w, -bits)
      if (w == 0_I8P) exit
   enddo
   endfunction radix_digits

   pure function unsigned_decimal(u) result(text)
   !< Decimal digits of `u` read as an unsigned 64-bit integer.
   integer(I8P), intent(in)      :: u     !< Value (bits).
   character(len=:), allocatable :: text  !< Digits.
   integer(I8P)                  :: limbs(4) !< Base 10**9 digits.
   integer(I4P)                  :: n     !< Limbs in use.
   integer(I4P)                  :: j     !< Counter.
   character(len=9)              :: chunk !< One limb.

   if (u >= 0_I8P) then
      text = int_str(u)
      return
   endif
   ! u = hi * 2**32 + lo
   limbs = 0_I8P
   limbs(1) = modulo(ishft(u, -32), LIMB)
   limbs(2) = ishft(u, -32) / LIMB
   n = 2_I4P
   call limbs_multiply(limbs, n, 2_I8P**16)
   call limbs_multiply(limbs, n, 2_I8P**16)
   limbs(1) = limbs(1) + iand(u, 4294967295_I8P)
   do j = 1_I4P, n - 1_I4P
      limbs(j + 1) = limbs(j + 1) + limbs(j) / LIMB
      limbs(j) = modulo(limbs(j), LIMB)
   enddo
   do while (n > 1_I4P .and. limbs(n) == 0_I8P)
      n = n - 1_I4P
   enddo
   text = int_str(limbs(n))
   do j = n - 1_I4P, 1_I4P, -1_I4P
      write(chunk, '(I9.9)') limbs(j)
      text = text//chunk
   enddo
   endfunction unsigned_decimal

   pure function upper_case(text) result(upper)
   !< `text` in upper case (ASCII).
   character(len=*), intent(in) :: text  !< Text.
   character(len=len(text))     :: upper !< Upper case text.
   integer(I4P)                 :: j     !< Counter.

   upper = text
   do j = 1_I4P, len(text, kind=I4P)
      if (text(j:j) >= 'a' .and. text(j:j) <= 'z') upper(j:j) = achar(iachar(text(j:j)) - 32)
   enddo
   endfunction upper_case
endmodule foresight_format
