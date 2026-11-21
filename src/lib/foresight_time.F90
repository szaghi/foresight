!< foresight_time, gnuplot's time values: seconds since 1970-01-01 00:00 UTC, written and read as gnuplot 6.0's
!< `strftime` and `strptime` do.
module foresight_time
!< foresight_time, gnuplot's time values: seconds since 1970-01-01 00:00 UTC, written and read as gnuplot 6.0's
!< `strftime` and `strptime` do.
!<
!< Dates are proleptic Gregorian, without leap seconds or time zones, as gnuplot's. The conversions are gnuplot's own
!< (`gstrftime`, `gstrptime`), not C's: `%p` writes `am`/`pm`, `%.3S` writes fractional seconds, `%tH`, `%tM`, `%tS`
!< write and read elapsed times; a conversion gnuplot does not know writes nothing.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite, ieee_quiet_nan, ieee_value
use penf, only : I4P, I8P, R8P

implicit none
private
public :: DAY_SEC
public :: MON_SEC
public :: WEEK_SEC
public :: YEAR_SEC
public :: civil_time
public :: time_format_check
public :: time_justify
public :: strftime
public :: strptime
public :: time_parts

real(R8P), parameter :: DAY_SEC  = 86400.0_R8P           !< Seconds of a day.
real(R8P), parameter :: WEEK_SEC = 7.0_R8P * DAY_SEC     !< Seconds of a week.
real(R8P), parameter :: YEAR_SEC = 365.25_R8P * DAY_SEC  !< Seconds of a mean year (gnuplot's).
real(R8P), parameter :: MON_SEC  = YEAR_SEC / 12.0_R8P   !< Seconds of a mean month (gnuplot's).

character(len=9), parameter :: DAY_NAMES(0:6) = [character(len=9) :: 'Sunday', 'Monday', 'Tuesday', 'Wednesday', &
                                                 'Thursday', 'Friday', 'Saturday'] !< Weekday names.
character(len=9), parameter :: MONTH_NAMES(12) = [character(len=9) :: 'January', 'February', 'March', 'April', 'May', &
                                                  'June', 'July', 'August', 'September', 'October', 'November', &
                                                  'December'] !< Month names.

contains
   pure function days_from_civil(y, m, d) result(days)
   !< Days from 1970-01-01 to the date `y`-`m`-`d` (H. Hinnant's algorithm; `m` and `d` may overflow their ranges).
   integer(I8P), intent(in) :: y    !< Year.
   integer(I8P), intent(in) :: m    !< Month, 1 for January.
   integer(I8P), intent(in) :: d    !< Day of the month, from 1.
   integer(I8P)             :: days !< Days since the epoch.
   integer(I8P)             :: yy   !< Year from March.
   integer(I8P)             :: mm   !< Month from March, 0-based.
   integer(I8P)             :: era  !< 400-year era.
   integer(I8P)             :: yoe  !< Year of the era.
   integer(I8P)             :: doy  !< Day of the year from March.
   integer(I8P)             :: doe  !< Day of the era.

   ! months beyond 1..12 carried into the year
   yy = y + floor(real(m - 1_I8P, R8P) / 12.0_R8P, I8P)
   mm = modulo(m - 1_I8P, 12_I8P) + 1_I8P
   if (mm <= 2_I8P) yy = yy - 1_I8P
   era = floor(real(yy, R8P) / 400.0_R8P, I8P)
   yoe = yy - era * 400_I8P
   doy = (153_I8P * (mm + merge(-3_I8P, 9_I8P, mm > 2_I8P)) + 2_I8P) / 5_I8P + d - 1_I8P
   doe = yoe * 365_I8P + yoe / 4_I8P - yoe / 100_I8P + doy
   days = era * 146097_I8P + doe - 719468_I8P
   endfunction days_from_civil

   pure subroutine civil_from_days(days, y, m, d)
   !< The date of `days` since 1970-01-01 (H. Hinnant's algorithm).
   integer(I8P), intent(in)  :: days !< Days since the epoch.
   integer(I8P), intent(out) :: y    !< Year.
   integer(I8P), intent(out) :: m    !< Month, 1 for January.
   integer(I8P), intent(out) :: d    !< Day of the month, from 1.
   integer(I8P)              :: z    !< Days from 0000-03-01.
   integer(I8P)              :: era  !< 400-year era.
   integer(I8P)              :: doe  !< Day of the era.
   integer(I8P)              :: yoe  !< Year of the era.
   integer(I8P)              :: doy  !< Day of the year from March.
   integer(I8P)              :: mp   !< Month from March, 0-based.

   z = days + 719468_I8P
   era = floor(real(z, R8P) / 146097.0_R8P, I8P)
   doe = z - era * 146097_I8P
   yoe = (doe - doe / 1460_I8P + doe / 36524_I8P - doe / 146096_I8P) / 365_I8P
   y = yoe + era * 400_I8P
   doy = doe - (365_I8P * yoe + yoe / 4_I8P - yoe / 100_I8P)
   mp = (5_I8P * doy + 2_I8P) / 153_I8P
   d = doy - (153_I8P * mp + 2_I8P) / 5_I8P + 1_I8P
   m = mp + merge(3_I8P, -9_I8P, mp < 10_I8P)
   if (m <= 2_I8P) y = y + 1_I8P
   endsubroutine civil_from_days

   pure function civil_time(year, month, day, hour, minute, second) result(t)
   !< Seconds since the epoch of a date and time (fields may overflow their ranges, as `mktime`'s).
   integer(I8P), intent(in) :: year   !< Year.
   integer(I8P), intent(in) :: month  !< Month, 1 for January.
   integer(I8P), intent(in) :: day    !< Day of the month, from 1.
   integer(I8P), intent(in) :: hour   !< Hour.
   integer(I8P), intent(in) :: minute !< Minute.
   real(R8P),    intent(in) :: second !< Second, with its fraction.
   real(R8P)                :: t      !< Time [s].

   t = real(days_from_civil(year, month, day), R8P) * DAY_SEC + real(hour * 3600_I8P + minute * 60_I8P, R8P) + second
   endfunction civil_time

   pure subroutine time_parts(t, year, month, day, hour, minute, second, fraction, yday, wday)
   !< The broken-down time of `t` [s since the epoch]: `yday` the day of the year from 1, `wday` the weekday from 0
   !< (Sunday); `second` whole, `fraction` the rest of it (in [0, 1)).
   real(R8P),    intent(in)  :: t        !< Time [s].
   integer(I8P), intent(out) :: year     !< Year.
   integer(I8P), intent(out) :: month    !< Month, 1 for January.
   integer(I8P), intent(out) :: day      !< Day of the month, from 1.
   integer(I8P), intent(out) :: hour     !< Hour.
   integer(I8P), intent(out) :: minute   !< Minute.
   integer(I8P), intent(out) :: second   !< Second.
   real(R8P),    intent(out) :: fraction !< Fraction of the second.
   integer(I8P), intent(out) :: yday     !< Day of the year, from 1.
   integer(I8P), intent(out) :: wday     !< Weekday, 0 Sunday.
   integer(I8P)              :: whole    !< Whole seconds.
   integer(I8P)              :: days     !< Days since the epoch.
   integer(I8P)              :: rest     !< Seconds of the day.

   whole = floor(t, I8P)
   fraction = t - real(whole, R8P)
   days = floor(real(whole, R8P) / DAY_SEC, I8P)
   rest = whole - days * 86400_I8P
   call civil_from_days(days, year, month, day)
   hour = rest / 3600_I8P
   minute = mod(rest, 3600_I8P) / 60_I8P
   second = mod(rest, 60_I8P)
   yday = days - days_from_civil(year, 1_I8P, 1_I8P) + 1_I8P
   wday = modulo(days + 4_I8P, 7_I8P)
   endsubroutine time_parts

   pure function strftime(format, t) result(text)
   !< `t` [s since the epoch] written with the time `format`, as gnuplot's `strftime`: `%a %A %b %B %h` names,
   !< `%d %m %y %Y %j %H %I %M %S` numbers (zero padded), `%k %l` hours (blank padded), `%p` am/pm, `%s` the seconds
   !< since the epoch, `%w` the weekday number, `%U %W` week numbers, `%D` (`%m/%d/%y`), `%F` (`%Y-%m-%d`), `%T`
   !< (`%H:%M:%S`), `%R` (`%H:%M`), `%r` (`%I:%M:%S %p`), `%.NS` the seconds with N decimals, `%tH %tM %tS` the
   !< elapsed hours, minutes, seconds (the largest unit present unbounded), `%%`; others write nothing.
   character(len=*), intent(in)  :: format !< Time format.
   real(R8P),        intent(in)  :: t      !< Time [s].
   character(len=:), allocatable :: text   !< Text.
   integer(I8P)                  :: p(9)   !< Year, month, day, hour, minute, second, -, yday, wday.
   real(R8P)                     :: frac   !< Fraction of the second.
   integer(I4P)                  :: i      !< Format position.
   integer(I4P)                  :: prec   !< Precision of `%.NS`, -1 if none.
   logical                       :: has_th !< `%tH` in the format.
   logical                       :: has_tm !< `%tM` in the format.

   text = ''
   if (.not. ieee_is_finite(t)) return
   call time_parts(t, p(1), p(2), p(3), p(4), p(5), p(6), frac, p(8), p(9))
   has_th = index(format, '%tH') > 0
   has_tm = index(format, '%tM') > 0
   i = 1_I4P
   do while (i <= len(format, kind=I4P))
      if (format(i:i) /= '%' .or. i == len(format)) then
         text = text//format(i:i)
         i = i + 1_I4P
         cycle
      endif
      i = i + 1_I4P
      prec = -1_I4P
      if (format(i:i) == '.' .and. i < len(format)) then
         ! %.NS: the seconds with N decimals
         if (scan(format(i + 1_I4P:i + 1_I4P), '0123456789') > 0) then
            prec = index('0123456789', format(i + 1_I4P:i + 1_I4P)) - 1_I4P
            i = i + 2_I4P
            if (i > len(format)) exit
         endif
      endif
      select case (format(i:i))
      case ('a')
         text = text//DAY_NAMES(p(9))(1:3)
      case ('A')
         text = text//trim(DAY_NAMES(p(9)))
      case ('b', 'h')
         text = text//MONTH_NAMES(p(2))(1:3)
      case ('B')
         text = text//trim(MONTH_NAMES(p(2)))
      case ('d')
         text = text//padded(p(3), 2_I4P, '0')
      case ('D')
         text = text//padded(p(2), 2_I4P, '0')//'/'//padded(p(3), 2_I4P, '0')//'/'//padded(modulo(p(1), 100_I8P), 2_I4P, '0')
      case ('F')
         text = text//padded(p(1), 4_I4P, '0')//'-'//padded(p(2), 2_I4P, '0')//'-'//padded(p(3), 2_I4P, '0')
      case ('H')
         text = text//padded(p(4), 2_I4P, '0')
      case ('I')
         text = text//padded(hour12(p(4)), 2_I4P, '0')
      case ('k')
         text = text//padded(p(4), 2_I4P, ' ')
      case ('l')
         text = text//padded(hour12(p(4)), 2_I4P, ' ')
      case ('p')
         text = text//merge('am', 'pm', p(4) < 12_I8P)
      case ('j')
         text = text//padded(p(8), 3_I4P, '0')
      case ('m')
         text = text//padded(p(2), 2_I4P, '0')
      case ('M')
         text = text//padded(p(5), 2_I4P, '0')
      case ('S')
         text = text//padded(p(6), 2_I4P, '0')
         if (prec > 0_I4P) text = text//decimals(frac, prec)
      case ('s')
         text = text//padded(floor(t, I8P), 1_I4P, '0')
      case ('T')
         text = text//padded(p(4), 2_I4P, '0')//':'//padded(p(5), 2_I4P, '0')//':'//padded(p(6), 2_I4P, '0')
      case ('R')
         text = text//padded(p(4), 2_I4P, '0')//':'//padded(p(5), 2_I4P, '0')
      case ('r')
         text = text//padded(hour12(p(4)), 2_I4P, '0')//':'//padded(p(5), 2_I4P, '0')//':'// &
                padded(p(6), 2_I4P, '0')//' '//merge('am', 'pm', p(4) < 12_I8P)
      case ('w')
         text = text//padded(p(9), 2_I4P, '0')
      case ('U')
         text = text//padded((p(8) + 7_I8P - p(9)) / 7_I8P, 2_I4P, '0')
      case ('W')
         text = text//padded((p(8) + 7_I8P - modulo(p(9) + 6_I8P, 7_I8P)) / 7_I8P, 2_I4P, '0')
      case ('y')
         text = text//padded(modulo(p(1), 100_I8P), 2_I4P, '0')
      case ('Y')
         text = text//padded(p(1), 4_I4P, '0')
      case ('t')
         if (i < len(format)) then
            i = i + 1_I4P
            text = text//elapsed(format(i:i))
         endif
      case ('%')
         text = text//'%'
      endselect
      i = i + 1_I4P
   enddo
   contains
      pure function hour12(h) result(h12)
      !< Hour on the 12-hour clock.
      integer(I8P), intent(in) :: h   !< Hour, 0 to 23.
      integer(I8P)             :: h12 !< Hour, 1 to 12.

      h12 = modulo(h + 11_I8P, 12_I8P) + 1_I8P
      endfunction hour12

      pure function elapsed(unit) result(part)
      !< `%tH`, `%tM`, `%tS`: hours, minutes, seconds of the elapsed time `t`; the largest unit of the format holds the
      !< whole of it (hours, or minutes without `%tH`, or seconds alone), its sign first.
      character(len=1), intent(in)  :: unit !< `H`, `M` or `S`.
      character(len=:), allocatable :: part !< Text.
      real(R8P)                     :: a    !< Magnitude.
      integer(I8P)                  :: n    !< Whole units.

      part = ''
      a = abs(t)
      select case (unit)
      case ('H')
         n = int(a / 3600.0_R8P, I8P)
         part = padded(n, 1_I4P, '0')
         if (t < 0.0_R8P) part = '-'//part
      case ('M')
         if (has_th) then
            n = int((a - 3600.0_R8P * aint(a / 3600.0_R8P)) / 60.0_R8P, I8P)
            part = padded(n, 2_I4P, '0')
         else
            n = int(a / 60.0_R8P, I8P)
            part = padded(n, 2_I4P, '0')
            if (t < 0.0_R8P) part = '-'//part
         endif
      case ('S')
         if (has_th .or. has_tm) then
            n = int(a - 60.0_R8P * aint(a / 60.0_R8P), I8P)
            part = padded(n, 2_I4P, '0')
         else
            n = int(a, I8P)
            part = padded(n, 2_I4P, '0')
            if (t < 0.0_R8P) part = '-'//part
         endif
      endselect
      endfunction elapsed
   endfunction strftime

   pure subroutine strptime(format, text, t, ok)
   !< `text` read with the time `format`, as gnuplot's `strptime`: `%d %m %H %M` (up to 2 digits), `%y` (2 digits, 69
   !< to 99 the 1900s, else the 2000s), `%Y` (up to 4), `%j` (up to 3), `%S` (seconds with a fraction), `%s` (seconds
   !< since the epoch), `%b %B` (month names or their 3 first letters), `%a %A` (weekday names, skipped), `%p` (`pm`
   !< adds 12 hours), `%tH %tM %tS` (elapsed hours, minutes, seconds, signed, the last with a fraction); a blank
   !< matches any run of blanks, any other character itself. Fields not given are those of 1970-01-01 00:00:00.
   !< `ok` false (`t` NaN) if `text` does not match.
   character(len=*), intent(in)  :: format !< Time format.
   character(len=*), intent(in)  :: text   !< Text.
   real(R8P),        intent(out) :: t      !< Time [s].
   logical,          intent(out) :: ok     !< Text matched.
   integer(I8P)                  :: year   !< Year.
   integer(I8P)                  :: month  !< Month.
   integer(I8P)                  :: day    !< Day.
   integer(I8P)                  :: hour   !< Hour.
   integer(I8P)                  :: minute !< Minute.
   integer(I8P)                  :: yday   !< Day of the year, 0 if not given.
   integer(I8P)                  :: n      !< A number read.
   real(R8P)                     :: second !< Second.
   real(R8P)                     :: offset !< Seconds added (`%s`, `%t`, `%p`).
   real(R8P)                     :: v      !< A real read.
   integer(I4P)                  :: i      !< Format position.
   integer(I4P)                  :: j      !< Text position.
   integer(I4P)                  :: k      !< Name counter.
   logical                       :: epoch  !< `%s` given.
   logical                       :: found  !< A field read.

   t = ieee_value(1.0_R8P, ieee_quiet_nan)
   ok = .false.
   year = 1970_I8P
   month = 1_I8P
   day = 1_I8P
   hour = 0_I8P
   minute = 0_I8P
   second = 0.0_R8P
   yday = 0_I8P
   offset = 0.0_R8P
   epoch = .false.
   i = 1_I4P
   j = 1_I4P
   do while (i <= len(format, kind=I4P))
      if (format(i:i) == ' ') then
         do while (j <= len(text, kind=I4P))
            if (text(j:j) /= ' ' .and. text(j:j) /= achar(9)) exit
            j = j + 1_I4P
         enddo
         i = i + 1_I4P
         cycle
      endif
      if (format(i:i) /= '%' .or. i == len(format)) then
         if (j > len(text)) return
         if (text(j:j) /= format(i:i)) return
         i = i + 1_I4P
         j = j + 1_I4P
         cycle
      endif
      i = i + 1_I4P
      select case (format(i:i))
      case ('d')
         call digits(j, 2_I4P, day, found)
         if (.not. found) return
      case ('m')
         call digits(j, 2_I4P, month, found)
         if (.not. found) return
      case ('y')
         call digits(j, 2_I4P, year, found)
         if (.not. found) return
         year = year + merge(1900_I8P, 2000_I8P, year >= 69_I8P)
      case ('Y')
         call digits(j, 4_I4P, year, found)
         if (.not. found) return
      case ('j')
         call digits(j, 3_I4P, yday, found)
         if (.not. found) return
      case ('H')
         call digits(j, 2_I4P, hour, found)
         if (.not. found) return
      case ('M')
         call digits(j, 2_I4P, minute, found)
         if (.not. found) return
      case ('S')
         call digits(j, 2_I4P, n, found)
         if (.not. found) return
         second = real(n, R8P)
         if (j <= len(text)) then
            if (text(j:j) == '.') then
               call number(j, v, .false., found)
               if (.not. found) return
               second = second + v
            endif
         endif
      case ('s')
         call number(j, v, .true., found)
         if (.not. found) return
         offset = offset + v
         epoch = .true.
      case ('b', 'B', 'h')
         do k = 1_I4P, 12_I4P
            call named(j, MONTH_NAMES(k), found)
            if (found) exit
         enddo
         if (k > 12_I4P) return
         month = k
      case ('a', 'A')
         do k = 0_I4P, 6_I4P
            call named(j, DAY_NAMES(k), found)
            if (found) exit
         enddo
         if (k > 6_I4P) return
      case ('p')
         if (j + 1_I4P > len(text)) return
         if (lower(text(j:j + 1_I4P)) == 'pm') then
            offset = offset + 43200.0_R8P
         elseif (lower(text(j:j + 1_I4P)) /= 'am') then
            return
         endif
         j = j + 2_I4P
      case ('t')
         if (i == len(format)) return
         i = i + 1_I4P
         call number(j, v, .true., found)
         if (.not. found) return
         select case (format(i:i))
         case ('H')
            offset = offset + 3600.0_R8P * v
         case ('M')
            offset = offset + 60.0_R8P * v
         case ('S')
            offset = offset + v
         case default
            return
         endselect
      case ('%')
         if (j > len(text)) return
         if (text(j:j) /= '%') return
         j = j + 1_I4P
      case default
         return
      endselect
      i = i + 1_I4P
   enddo
   if (epoch) then
      t = offset
   elseif (yday > 0_I8P) then
      t = civil_time(year, 1_I8P, yday, hour, minute, second) + offset
   else
      t = civil_time(year, month, day, hour, minute, second) + offset
   endif
   ok = .true.
   contains
      pure subroutine digits(j, most, value, found)
      !< Read up to `most` digits (a sign first for none) at `j`, advancing it.
      integer(I4P), intent(inout) :: j   !< Text position.
      integer(I4P), intent(in)  :: most  !< Most digits.
      integer(I8P), intent(out) :: value !< Value.
      logical,      intent(out) :: found !< A digit read.
      integer(I4P)              :: count !< Digits read.

      value = 0_I8P
      count = 0_I4P
      do while (j <= len(text, kind=I4P) .and. count < most)
         if (scan(text(j:j), '0123456789') == 0) exit
         value = 10_I8P * value + int(index('0123456789', text(j:j)) - 1, I8P)
         j = j + 1_I4P
         count = count + 1_I4P
      enddo
      found = count > 0_I4P
      endsubroutine digits

      pure subroutine number(j, value, signed, found)
      !< Read a decimal number at `j` (`[sign]digits[.digits]`, or `.digits` for a fraction), advancing it.
      integer(I4P), intent(inout) :: j !< Text position.
      real(R8P), intent(out) :: value  !< Value.
      logical,   intent(in)  :: signed !< A sign may lead.
      logical,   intent(out) :: found  !< A number read.
      real(R8P)              :: scale  !< Place of a decimal.
      real(R8P)              :: sign   !< Sign.

      value = 0.0_R8P
      sign = 1.0_R8P
      found = .false.
      if (signed .and. j <= len(text)) then
         if (text(j:j) == '-' .or. text(j:j) == '+') then
            if (text(j:j) == '-') sign = -1.0_R8P
            j = j + 1_I4P
         endif
      endif
      do while (j <= len(text, kind=I4P))
         if (scan(text(j:j), '0123456789') == 0) exit
         value = 10.0_R8P * value + real(index('0123456789', text(j:j)) - 1, R8P)
         j = j + 1_I4P
         found = .true.
      enddo
      if (j <= len(text)) then
         if (text(j:j) == '.') then
            j = j + 1_I4P
            scale = 0.1_R8P
            do while (j <= len(text, kind=I4P))
               if (scan(text(j:j), '0123456789') == 0) exit
               value = value + scale * real(index('0123456789', text(j:j)) - 1, R8P)
               scale = scale / 10.0_R8P
               j = j + 1_I4P
               found = .true.
            enddo
         endif
      endif
      value = sign * value
      endsubroutine number

      pure subroutine named(j, name, found)
      !< Read `name` or its 3 first letters at `j` (any case), advancing it.
      integer(I4P),     intent(inout) :: j  !< Text position.
      character(len=*), intent(in) :: name  !< Full name.
      logical,          intent(out) :: found !< Name read.
      integer(I4P)                 :: l     !< Full name length.

      found = .false.
      l = len_trim(name, kind=I4P)
      if (j + l - 1_I4P <= len(text)) then
         if (lower(text(j:j + l - 1_I4P)) == lower(name(1:l))) then
            j = j + l
            found = .true.
            return
         endif
      endif
      if (j + 2_I4P <= len(text)) then
         if (lower(text(j:j + 2_I4P)) == lower(name(1:3))) then
            j = j + 3_I4P
            found = .true.
         endif
      endif
      endsubroutine named
   endsubroutine strptime

   pure function time_format_check(format) result(message)
   !< Empty if `format` is a time format: text whose `%` conversions are among those `strftime` knows (a gnuplot
   !< `set format x "%H:%M"` on a time axis); else the problem.
   character(len=*), intent(in)  :: format  !< Format.
   character(len=:), allocatable :: message !< Problem, empty if none.
   character(len=*), parameter   :: KNOWN = 'aAbBhdDFHIklpjmMSsTRrwUWyY%' !< Conversions.
   integer(I4P)                  :: i       !< Position.

   message = ''
   i = 1_I4P
   do while (i <= len(format, kind=I4P))
      if (format(i:i) /= '%') then
         i = i + 1_I4P
         cycle
      endif
      i = i + 1_I4P
      if (i > len(format)) then
         message = 'a lone "%" ends the time format "'//format//'"'
         return
      endif
      if (format(i:i) == '.' .and. i + 2_I4P <= len(format)) then
         if (scan(format(i + 1_I4P:i + 1_I4P), '0123456789') > 0 .and. format(i + 2_I4P:i + 2_I4P) == 'S') then
            i = i + 3_I4P
            cycle
         endif
      endif
      if (format(i:i) == 't' .and. i < len(format)) then
         if (scan(format(i + 1_I4P:i + 1_I4P), 'HMS') > 0) then
            i = i + 2_I4P
            cycle
         endif
      endif
      if (scan(format(i:i), KNOWN) == 0) then
         message = 'unknown time conversion "%'//format(i:i)//'" in "'//format//'"'
         return
      endif
      i = i + 1_I4P
   enddo
   endfunction time_format_check

   pure function time_justify(level, t) result(justified)
   !< `t` moved to a whole time unit of the tick `level` (0 seconds, 1 minutes, 2 hours, 3 days, 4 weeks, 5 months,
   !< 6 years), as gnuplot's `time_tic_just`: days and longer at 0 AM, minutes and hours rounded up past 55, months
   !< to the 1st (the next month past the 25th).
   integer(I4P), intent(in) :: level     !< Tick level.
   real(R8P),    intent(in) :: t         !< Time [s].
   real(R8P)                :: justified !< Justified time [s].
   integer(I8P)             :: p(9)      !< Year, month, day, hour, minute, second, -, yday, wday.
   real(R8P)                :: frac      !< Fraction of the second.

   justified = t
   if (level <= 0_I4P .or. .not. ieee_is_finite(t)) return
   call time_parts(t, p(1), p(2), p(3), p(4), p(5), p(6), frac, p(8), p(9))
   if (level >= 3_I4P) then
      p(4:6) = 0_I8P
      frac = 0.0_R8P
   endif
   if (level >= 1_I4P) then
      if (p(6) > 55_I8P) p(5) = p(5) + 1_I8P
      p(6) = 0_I8P
      frac = 0.0_R8P
   endif
   if (level >= 2_I4P) then
      if (p(5) > 55_I8P) p(4) = p(4) + 1_I8P
      p(5) = 0_I8P
   endif
   if (level >= 5_I4P) then
      if (p(3) > 25_I8P) p(2) = p(2) + 1_I8P
      p(3) = 1_I8P
   endif
   justified = civil_time(p(1), p(2), p(3), p(4), p(5), real(p(6), R8P) + frac)
   endfunction time_justify

   pure function padded(n, width, pad) result(text)
   !< `n` in decimal, padded on the left with `pad` to `width` characters (a minus sign first).
   integer(I8P),     intent(in)  :: n     !< Number.
   integer(I4P),     intent(in)  :: width !< Least width.
   character(len=1), intent(in)  :: pad   !< Padding character.
   character(len=:), allocatable :: text  !< Text.
   character(len=24)             :: buffer !< Digits.

   write(buffer, '(I0)') abs(n)
   text = trim(buffer)
   if (len(text) < width) text = repeat(pad, width - len(text))//text
   if (n < 0_I8P) text = '-'//text
   endfunction padded

   pure function decimals(fraction, prec) result(text)
   !< `.` then the first `prec` decimals of `fraction` (in [0, 1)), truncated, as gnuplot's `%.NS`.
   real(R8P),    intent(in)      :: fraction !< Fraction.
   integer(I4P), intent(in)      :: prec     !< Decimals.
   character(len=:), allocatable :: text     !< Text.
   integer(I8P)                  :: scaled   !< Decimals as an integer.

   scaled = int(fraction * 10.0_R8P**prec, I8P)
   text = '.'//padded(scaled, prec, '0')
   endfunction decimals

   pure function lower(text) result(low)
   !< `text` in lower case.
   character(len=*), intent(in) :: text !< Text.
   character(len=len(text))     :: low  !< Lower case text.
   integer(I4P)                 :: k    !< Character counter.

   low = text
   do k = 1_I4P, len(text, kind=I4P)
      if (text(k:k) >= 'A' .and. text(k:k) <= 'Z') low(k:k) = achar(iachar(text(k:k)) + 32)
   enddo
   endfunction lower
endmodule foresight_time
