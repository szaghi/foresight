!< foresight_ticks, axis tick placement and labelling.
module foresight_ticks
!< foresight_ticks, axis tick placement and labelling.
!<
!< Linear axes use the "nice numbers" rule (Heckbert, Graphics Gems, 1990): the step is rounded to `m * 10**e` with
!< `m` in {1, 2, 5}. Log axes place majors at integer decades. Tick values are carried as the integer pair (`n`, `e`)
!< meaning `n * 10**e`, so labels are exact decimal strings, free of floating point noise such as `0.30000000000000004`.
!<
!< User settings (`tics_object`, gnuplot `set xtics` and `set format`) replace the automatic rule: a fixed step from an
!< optional start to an optional end (a multiplying factor on log axes), no ticks at all, or a printf-like label format.
!< Fixed steps are kept as the decimal text the user wrote, so linear ticks stay exact decimals too.
!<
!< The same rules are mirrored by the interactive viewer, which must regenerate identical ticks after a zoom.
use penf, only : I4P, I8P, R8P
use foresight_format, only : decimal_of, decimal_str, format_decimal, int_str, parse_decimal

implicit none
private
public :: linear_ticks
public :: log_ticks
public :: nice_step
public :: tick_object
public :: tics_object
public :: TICS_AUTO, TICS_FIXED, TICS_NONE

type :: tick_object
   !< Axis tick.
   real(R8P)                     :: value = 0.0_R8P !< Data value.
   logical                       :: major = .true.  !< Major (labelled) tick, else minor.
   character(len=:), allocatable :: label           !< Label text, empty for minor ticks.
   character(len=:), allocatable :: sup             !< Superscript appended to the label, empty if none.
endtype tick_object

integer(I4P), parameter :: TICS_AUTO  = 0_I4P !< Ticks by the automatic rule.
integer(I4P), parameter :: TICS_FIXED = 1_I4P !< Ticks at a fixed step.
integer(I4P), parameter :: TICS_NONE  = 2_I4P !< No ticks.

type :: tics_object
   !< User tick settings of an axis, gnuplot `set xtics` and `set format`.
   integer(I4P)                  :: mode = TICS_AUTO !< TICS_AUTO, TICS_FIXED or TICS_NONE.
   character(len=:), allocatable :: start            !< Fixed ticks start (decimal text), empty for none.
   character(len=:), allocatable :: step             !< Fixed ticks step, a factor on log axes (decimal text).
   character(len=:), allocatable :: end              !< Fixed ticks end (decimal text), empty for none.
   character(len=:), allocatable :: format           !< Label format, empty for the default labels.
   contains
      procedure, pass(self) :: attribute  !< Viewer attribute of the tick positions.
      procedure, pass(self) :: has_format !< Whether a label format is set.
      procedure, pass(self) :: set_fixed  !< Set fixed ticks, validated.
endtype tics_object

real(R8P), parameter :: TOL          = 1.0e-9_R8P !< Tolerance on tick-grid membership, in units of the step.
real(R8P), parameter :: TICK_SPACING = 50.0_R8P   !< Target distance between major ticks [px].
real(R8P), parameter :: SCI_HIGH     = 1.0e5_R8P  !< Labels switch to scientific notation from this magnitude...
real(R8P), parameter :: SCI_LOW      = 1.0e-3_R8P !< ...or below this one.
integer(I8P), parameter :: MAX_TICKS = 1000_I8P   !< Tick count cap: no ticks beyond it (degenerate or extreme zoom).
integer(I8P), parameter :: MAX_POWER = 10000_I8P  !< Largest power of a fixed log step: no ticks beyond it.

contains
   pure function attribute(self) result(text)
   !< Tick positions for the viewer: empty for automatic, `none`, or `START STEP END` with `*` for an absent end.
   class(tics_object), intent(in) :: self !< Settings.
   character(len=:), allocatable  :: text !< Attribute text.

   select case (self%mode)
   case (TICS_FIXED)
      text = or_star(self%start)//' '//self%step//' '//or_star(self%end)
   case (TICS_NONE)
      text = 'none'
   case default
      text = ''
   endselect
   contains
      pure function or_star(value) result(t)
      !< `value`, or `*` if empty.
      character(len=*), intent(in)  :: value !< Decimal text.
      character(len=:), allocatable :: t     !< Text.

      t = value
      if (len(t) == 0) t = '*'
      endfunction or_star
   endfunction attribute

   pure function has_format(self) result(has)
   !< Whether a label format is set.
   class(tics_object), intent(in) :: self !< Settings.
   logical                        :: has  !< Format set.

   has = .false.
   if (allocated(self%format)) has = len(self%format) > 0
   endfunction has_format

   pure subroutine set_fixed(self, step, start, end, message)
   !< Fixed ticks every `step` (a factor on log axes) from `start` to `end`, given as decimal texts (empty for absent);
   !< `message` is empty on success, else the settings are unchanged.
   class(tics_object),            intent(inout) :: self    !< Settings.
   character(len=*),              intent(in)    :: step    !< Step.
   character(len=*),              intent(in)    :: start   !< Start, empty for none.
   character(len=*),              intent(in)    :: end     !< End, empty for none.
   character(len=:), allocatable, intent(out)   :: message !< Problem, empty if none.
   integer(I8P)                                 :: n(3)    !< Mantissas: step, start, end.
   integer(I4P)                                 :: e(3)    !< Exponents.
   logical                                      :: ok      !< Valid.

   message = ''
   call parse_decimal(step, n(1), e(1), ok)
   if (.not. ok .or. n(1) <= 0_I8P) then
      message = 'the step must be a positive number, not "'//step//'"'
      return
   endif
   n(2:3) = 0_I8P
   e(2:3) = e(1)
   if (len(start) > 0) then
      call parse_decimal(start, n(2), e(2), ok)
      if (.not. ok) then
         message = '"'//start//'" is not a number'
         return
      endif
   endif
   if (len(end) > 0) then
      call parse_decimal(end, n(3), e(3), ok)
      if (.not. ok) then
         message = '"'//end//'" is not a number'
         return
      endif
   endif
   call common_scale(n, e, ok)
   if (.not. ok) then
      message = 'start, step and end differ too much in magnitude'
      return
   endif
   self%mode = TICS_FIXED
   self%step = step
   self%start = start
   self%end = end
   endsubroutine set_fixed

   pure subroutine nice_step(raw, m, e)
   !< Round `raw > 0` to the "nice" step `m * 10**e` with `m` in {1, 2, 5}.
   real(R8P),    intent(in)  :: raw !< Raw step.
   integer(I8P), intent(out) :: m   !< Step mantissa.
   integer(I4P), intent(out) :: e   !< Step exponent.
   real(R8P)                 :: f   !< Raw step normalised to its decade.

   e = floor(log10(raw), I4P)
   ! scale by an exact power of ten: one rounding, identical in any IEEE implementation (e.g. 0.3 -> 3.0)
   if (e >= 0_I4P) then
      f = raw / 10.0_R8P**e
   else
      f = raw * 10.0_R8P**(-e)
   endif
   if (f < 1.5_R8P) then
      m = 1_I8P
   elseif (f < 3.0_R8P) then
      m = 2_I8P
   elseif (f < 7.0_R8P) then
      m = 5_I8P
   else
      m = 1_I8P
      e = e + 1_I4P
   endif
   endsubroutine nice_step

   pure subroutine linear_ticks(lo, hi, npx, extend_lo, extend_hi, ticks, tics)
   !< Major ticks of a linear axis `npx` pixels long; autoscaled ends are extended outward to the tick grid.
   !<
   !< With `tics`: no ticks and no extension (TICS_NONE), or the fixed grid (TICS_FIXED), and the label format.
   real(R8P),                      intent(inout)        :: lo        !< Value at the axis start (`lo > hi`: reversed).
   real(R8P),                      intent(inout)        :: hi        !< Value at the axis end.
   real(R8P),                      intent(in)           :: npx       !< Axis length [px].
   logical,                        intent(in)           :: extend_lo !< Extend `lo` outward to the tick grid.
   logical,                        intent(in)           :: extend_hi !< Extend `hi` outward to the tick grid.
   type(tick_object), allocatable, intent(out)          :: ticks(:)  !< Ticks, ascending in value.
   type(tics_object),              intent(in), optional :: tics      !< User settings.
   real(R8P)                                     :: step      !< Tick step.
   integer(I8P)                                  :: m         !< Step mantissa.
   integer(I8P)                                  :: k         !< Tick index on the step grid.
   integer(I8P)                                  :: kmin      !< First tick index.
   integer(I8P)                                  :: kmax      !< Last tick index.
   integer(I4P)                                  :: e         !< Step exponent.
   logical                                       :: sci       !< Scientific labels.

   if (present(tics)) then
      if (tics%mode == TICS_NONE) then
         allocate(ticks(0))
         return
      elseif (tics%mode == TICS_FIXED) then
         call fixed_linear_ticks(lo, hi, extend_lo, extend_hi, tics, ticks)
         return
      endif
   endif
   call nice_step(abs(hi - lo) / max(2.0_R8P, npx / TICK_SPACING), m, e)
   step = grid_value(m, e)
   if (lo <= hi) then
      if (extend_lo) lo = grid_value(m * floor(lo / step + TOL, I8P), e)
      if (extend_hi) hi = grid_value(m * ceiling(hi / step - TOL, I8P), e)
   else
      if (extend_lo) lo = grid_value(m * ceiling(lo / step - TOL, I8P), e)
      if (extend_hi) hi = grid_value(m * floor(hi / step + TOL, I8P), e)
   endif
   kmin = ceiling(min(lo, hi) / step - TOL, I8P)
   kmax = floor(max(lo, hi) / step + TOL, I8P)
   if (kmax - kmin >= MAX_TICKS) then
      allocate(ticks(0))
      return
   endif
   sci = is_scientific(max(abs(lo), abs(hi)))
   allocate(ticks(max(0_I8P, kmax - kmin + 1_I8P)))
   do k = kmin, kmax
      ticks(k - kmin + 1_I8P)%value = grid_value(k * m, e)
      call tick_label(k * m, e, sci, ticks(k - kmin + 1_I8P)%label, ticks(k - kmin + 1_I8P)%sup, tics)
   enddo
   endsubroutine linear_ticks

   pure subroutine log_ticks(lo, hi, npx, extend_lo, extend_hi, ticks, tics)
   !< Ticks of a base-10 log axis `npx` pixels long; autoscaled ends are extended outward to whole decades.
   !<
   !< Majors sit at decades (labelled `10` with the exponent as superscript), minors at 2..9 times a decade when the
   !< axis spans at most 10 decades. With fewer than two decades in range the minors are labelled too, in plain decimals;
   !< if still fewer than two ticks are labelled (a range inside one decade), linear ticks are placed instead.
   !<
   !< With `tics`: no ticks (TICS_NONE), or ticks multiplying by the step (TICS_FIXED), and the label format; the
   !< extension to decades applies anyway, as in gnuplot.
   real(R8P),                      intent(inout)        :: lo        !< Value at the axis start, > 0.
   real(R8P),                      intent(inout)        :: hi        !< Value at the axis end, > 0.
   real(R8P),                      intent(in)           :: npx       !< Axis length [px].
   logical,                        intent(in)           :: extend_lo !< Extend `lo` outward to a decade.
   logical,                        intent(in)           :: extend_hi !< Extend `hi` outward to a decade.
   type(tick_object), allocatable, intent(out)          :: ticks(:)  !< Ticks, majors first.
   type(tics_object),              intent(in), optional :: tics      !< User settings.
   type(tick_object)                             :: tick      !< Tick being built.
   type(tick_object), allocatable                :: linear(:) !< Fallback linear ticks.
   real(R8P)                                     :: a         !< Range start copy for the fallback.
   real(R8P)                                     :: b         !< Range end copy for the fallback.
   real(R8P)                                     :: ta        !< log10 of the lower value.
   real(R8P)                                     :: tb        !< log10 of the upper value.
   real(R8P)                                     :: t         !< log10 of a minor tick.
   integer(I8P)                                  :: m         !< Decade step mantissa.
   integer(I8P)                                  :: s         !< Decade step.
   integer(I8P)                                  :: k         !< Decade exponent.
   integer(I8P)                                  :: d         !< Minor tick multiplier.
   integer(I8P)                                  :: kmin      !< First major decade.
   integer(I8P)                                  :: kmax      !< Last major decade.
   integer(I4P)                                  :: e         !< Decade step exponent.
   logical                                       :: plain     !< Label minors, all in plain decimals.
   logical                                       :: custom    !< User label format.

   ! gnuplot extends autoscaled log axes to whole decades whatever the tick settings
   if (lo <= hi) then
      if (extend_lo) lo = grid_value(1_I8P, floor(log10(lo) + TOL, I4P))
      if (extend_hi) hi = grid_value(1_I8P, ceiling(log10(hi) - TOL, I4P))
   else
      if (extend_lo) lo = grid_value(1_I8P, ceiling(log10(lo) - TOL, I4P))
      if (extend_hi) hi = grid_value(1_I8P, floor(log10(hi) + TOL, I4P))
   endif
   custom = .false.
   if (present(tics)) then
      if (tics%mode == TICS_NONE) then
         allocate(ticks(0))
         return
      elseif (tics%mode == TICS_FIXED) then
         call fixed_log_ticks(lo, hi, tics, ticks)
         return
      endif
      custom = tics%has_format()
   endif
   ta = log10(min(lo, hi))
   tb = log10(max(lo, hi))
   call nice_step((tb - ta) / max(2.0_R8P, npx / TICK_SPACING), m, e)
   s = 1_I8P
   if (e >= 0_I4P) s = m * 10_I8P**e
   kmin = ceiling(ta - TOL, I8P)
   kmax = floor(tb + TOL, I8P)
   if (kmax - kmin >= MAX_TICKS) then
      allocate(ticks(0))
      return
   endif
   plain = count([(modulo(k, s) == 0_I8P, k = kmin, kmax)]) < 2

   allocate(ticks(0))
   do k = kmin, kmax
      if (modulo(k, s) /= 0_I8P) cycle
      tick%value = grid_value(1_I8P, int(k, I4P))
      tick%major = .true.
      if (custom) then
         call format_decimal(tics%format, 1_I8P, int(k, I4P), tick%label, tick%sup)
      elseif (plain) then
         tick%label = decimal_str(1_I8P, int(-k, I4P))
         tick%sup = ''
      else
         tick%label = '10'
         tick%sup = int_str(k)
      endif
      ticks = [ticks, tick]
   enddo
   if (s == 1_I8P .and. tb - ta <= 10.0_R8P) then
      do k = floor(ta - TOL, I8P), floor(tb + TOL, I8P)
         do d = 2_I8P, 9_I8P
            tick%value = grid_value(d, int(k, I4P))
            t = log10(tick%value)
            if (t < ta - TOL .or. t > tb + TOL) cycle
            tick%major = plain
            tick%sup = ''
            if (plain .and. custom) then
               call format_decimal(tics%format, d, int(k, I4P), tick%label, tick%sup)
            elseif (plain) then
               tick%label = decimal_str(d, int(-k, I4P))
            else
               tick%label = ''
            endif
            ticks = [ticks, tick]
         enddo
      enddo
   endif
   if (count(ticks%major) < 2) then
      a = lo
      b = hi
      call linear_ticks(a, b, npx, .false., .false., linear, tics)
      ticks = pack(linear, linear%value > 0.0_R8P)
   endif
   endsubroutine log_ticks

   ! private procedures
   pure subroutine common_scale(n, e, ok)
   !< Rescale the decimals `n * 10**e` to their smallest exponent, keeping every mantissa below 1e15 (exact in the
   !< viewer's double precision integers); `ok` false if impossible.
   integer(I8P), intent(inout) :: n(:) !< Mantissas.
   integer(I4P), intent(inout) :: e(:) !< Exponents, all equal on exit.
   logical,      intent(out)   :: ok   !< Rescaled.
   integer(I4P)                :: shift !< Exponent shift.
   integer(I4P)                :: k    !< Counter.

   ok = .true.
   do k = 1_I4P, size(n, kind=I4P)
      shift = e(k) - minval(e)
      if (shift > 15_I4P) then
         ok = .false.
      elseif (abs(n(k)) >= 10_I8P**(15_I4P - shift)) then
         ok = .false.
      endif
   enddo
   if (.not. ok) return
   do k = 1_I4P, size(n, kind=I4P)
      n(k) = n(k) * 10_I8P**(e(k) - minval(e))
   enddo
   e = minval(e)
   endsubroutine common_scale

   pure subroutine fixed_values(tics, n, e, has_start, has_end)
   !< Decimals of the fixed ticks at a common exponent: `n` holds step, start (0 if none) and end mantissas.
   type(tics_object), intent(in)  :: tics      !< Settings, TICS_FIXED (validated by `set_fixed`).
   integer(I8P),      intent(out) :: n(3)      !< Mantissas: step, start, end.
   integer(I4P),      intent(out) :: e(3)      !< Exponents, equal.
   logical,           intent(out) :: has_start !< Start given.
   logical,           intent(out) :: has_end   !< End given.
   logical                        :: ok        !< Parsed.

   call parse_decimal(tics%step, n(1), e(1), ok)
   n(2:3) = 0_I8P
   e(2:3) = e(1)
   has_start = len(tics%start) > 0
   has_end = len(tics%end) > 0
   if (has_start) call parse_decimal(tics%start, n(2), e(2), ok)
   if (has_end) call parse_decimal(tics%end, n(3), e(3), ok)
   call common_scale(n, e, ok)
   endsubroutine fixed_values

   pure subroutine fixed_linear_ticks(lo, hi, extend_lo, extend_hi, tics, ticks)
   !< Ticks at start + k * step within [start, end], as gnuplot `set xtics START,STEP,END`.
   !<
   !< An autoscaled end is extended outward to a multiple of the step, unless it lies outside [start, end] (gnuplot).
   real(R8P),                      intent(inout) :: lo        !< Value at the axis start.
   real(R8P),                      intent(inout) :: hi        !< Value at the axis end.
   logical,                        intent(in)    :: extend_lo !< `lo` autoscaled.
   logical,                        intent(in)    :: extend_hi !< `hi` autoscaled.
   type(tics_object),              intent(in)    :: tics      !< Settings, TICS_FIXED.
   type(tick_object), allocatable, intent(out)   :: ticks(:)  !< Ticks, ascending in value.
   integer(I8P)                                  :: n(3)      !< Step, start, end mantissas.
   integer(I4P)                                  :: e(3)      !< Common exponent.
   integer(I8P)                                  :: k         !< Tick index.
   integer(I8P)                                  :: kmin      !< First tick index.
   integer(I8P)                                  :: kmax      !< Last tick index.
   real(R8P)                                     :: step      !< Step value.
   real(R8P)                                     :: first     !< Start value.
   real(R8P)                                     :: last      !< End value.
   real(R8P)                                     :: offset    !< Start in steps.
   logical                                       :: has_start !< Start given.
   logical                                       :: has_end   !< End given.
   logical                                       :: sci       !< Scientific labels.

   allocate(ticks(0))
   call fixed_values(tics, n, e, has_start, has_end)
   step = grid_value(n(1), e(1))
   first = grid_value(n(2), e(1))
   last = grid_value(n(3), e(1))
   offset = real(n(2), R8P) / real(n(1), R8P)
   ! beyond 1e15 steps from the origin tick indexes are no longer exact integers
   if (max(abs(lo), abs(hi)) / step + abs(offset) > 1.0e15_R8P) return
   if (lo <= hi) then
      if (extend_lo .and. (.not. has_start .or. lo >= first)) lo = grid_value(n(1) * floor(lo / step + TOL, I8P), e(1))
      if (extend_hi .and. (.not. has_end .or. hi <= last)) hi = grid_value(n(1) * ceiling(hi / step - TOL, I8P), e(1))
   else
      if (extend_lo .and. (.not. has_end .or. lo <= last)) lo = grid_value(n(1) * ceiling(lo / step - TOL, I8P), e(1))
      if (extend_hi .and. (.not. has_start .or. hi >= first)) hi = grid_value(n(1) * floor(hi / step + TOL, I8P), e(1))
   endif
   kmin = ceiling(min(lo, hi) / step - offset - TOL, I8P)
   kmax = floor(max(lo, hi) / step - offset + TOL, I8P)
   if (has_start) kmin = max(kmin, 0_I8P)
   if (has_end) then
      if (n(3) < n(2)) return
      kmax = min(kmax, (n(3) - n(2)) / n(1))
   endif
   if (kmax < kmin .or. kmax - kmin >= MAX_TICKS) return
   sci = is_scientific(max(abs(lo), abs(hi)))
   deallocate(ticks)
   allocate(ticks(kmax - kmin + 1_I8P))
   do k = kmin, kmax
      associate(tick => ticks(k - kmin + 1_I8P))
         tick%value = grid_value(n(2) + k * n(1), e(1))
         call tick_label(n(2) + k * n(1), e(1), sci, tick%label, tick%sup, tics)
      endassociate
   enddo
   endsubroutine fixed_linear_ticks

   pure subroutine fixed_log_ticks(lo, hi, tics, ticks)
   !< Ticks of a log axis at start * step**k (start 1 if absent) within [start, end], as gnuplot `set ytics` on a log
   !< axis: the step is a factor, greater than 1.
   !<
   !< Tick values are built by repeated multiplication, so that the viewer reproduces them exactly.
   real(R8P),                      intent(in)    :: lo        !< Value at the axis start, > 0.
   real(R8P),                      intent(in)    :: hi        !< Value at the axis end, > 0.
   type(tics_object),              intent(in)    :: tics      !< Settings, TICS_FIXED.
   type(tick_object), allocatable, intent(out)   :: ticks(:)  !< Ticks, ascending in value.
   integer(I8P)                                  :: n(3)      !< Step, start, end mantissas.
   integer(I4P)                                  :: e(3)      !< Common exponent.
   integer(I8P)                                  :: k         !< Tick index.
   integer(I8P)                                  :: kmin      !< First tick index.
   integer(I8P)                                  :: kmax      !< Last tick index.
   integer(I8P)                                  :: mantissa  !< Label mantissa.
   integer(I4P)                                  :: exponent  !< Label exponent.
   real(R8P)                                     :: factor    !< Step value.
   real(R8P)                                     :: first     !< Start value.
   real(R8P)                                     :: last      !< End value.
   real(R8P)                                     :: lf        !< log10 of the factor.
   real(R8P)                                     :: v         !< Tick value.
   logical                                       :: has_start !< Start given.
   logical                                       :: has_end   !< End given.
   logical                                       :: sci       !< Scientific labels.

   allocate(ticks(0))
   call fixed_values(tics, n, e, has_start, has_end)
   factor = grid_value(n(1), e(1))
   first = 1.0_R8P
   if (has_start) first = grid_value(n(2), e(1))
   last = grid_value(n(3), e(1))
   if (factor <= 1.0_R8P .or. first <= 0.0_R8P) return
   lf = log10(factor)
   if (max(abs(log10(lo)), abs(log10(hi)), abs(log10(first))) / lf > real(MAX_POWER, R8P)) return
   kmin = ceiling((log10(min(lo, hi)) - log10(first)) / lf - TOL, I8P)
   kmax = floor((log10(max(lo, hi)) - log10(first)) / lf + TOL, I8P)
   if (has_start) kmin = max(kmin, 0_I8P)
   if (has_end) then
      if (last <= 0.0_R8P) return
      kmax = min(kmax, floor((log10(last) - log10(first)) / lf + TOL, I8P))
   endif
   if (kmax < kmin .or. kmax - kmin >= MAX_TICKS) return
   sci = is_scientific(max(lo, hi))
   deallocate(ticks)
   allocate(ticks(kmax - kmin + 1_I8P))
   v = power(first, factor, kmin)
   do k = kmin, kmax
      associate(tick => ticks(k - kmin + 1_I8P))
         tick%value = v
         call decimal_of(v, mantissa, exponent)
         call tick_label(mantissa, exponent, sci, tick%label, tick%sup, tics)
      endassociate
      v = v * factor
   enddo
   endsubroutine fixed_log_ticks

   pure function power(first, factor, k) result(v)
   !< first * factor**k by |k| multiplications or divisions: the operation sequence the viewer repeats.
   real(R8P),    intent(in) :: first  !< Start.
   real(R8P),    intent(in) :: factor !< Factor.
   integer(I8P), intent(in) :: k      !< Power.
   real(R8P)                :: v      !< Value.
   integer(I8P)             :: j      !< Counter.

   v = first
   do j = 1_I8P, abs(k)
      if (k > 0_I8P) then
         v = v * factor
      else
         v = v / factor
      endif
   enddo
   endfunction power

   pure subroutine tick_label(n, e, sci, label, sup, tics)
   !< Label of the tick value `n * 10**e`: by the user format of `tics` if any, else by `format_label`.
   integer(I8P),                  intent(in)           :: n     !< Value mantissa.
   integer(I4P),                  intent(in)           :: e     !< Value exponent.
   logical,                       intent(in)           :: sci   !< Scientific notation (default labels).
   character(len=:), allocatable, intent(out)          :: label !< Label text.
   character(len=:), allocatable, intent(out)          :: sup   !< Label superscript.
   type(tics_object),             intent(in), optional :: tics  !< User settings.

   if (present(tics)) then
      if (tics%has_format()) then
         call format_decimal(tics%format, n, e, label, sup)
         return
      endif
   endif
   call format_label(n, e, sci, label, sup)
   endsubroutine tick_label

   pure function grid_value(n, e) result(value)
   !< Value `n * 10**e`, correctly rounded for `|e| <= 22` (powers of ten are exact there); beyond, scaled in steps of
   !< 1e22, the operation sequence the viewer repeats.
   integer(I8P), intent(in) :: n     !< Mantissa.
   integer(I4P), intent(in) :: e     !< Exponent.
   real(R8P)                :: value !< Value.
   integer(I4P)             :: k     !< Remaining exponent.

   value = real(n, R8P)
   k = e
   do while (k > 22_I4P)
      value = value * 1.0e22_R8P
      k = k - 22_I4P
   enddo
   do while (k < -22_I4P)
      value = value / 1.0e22_R8P
      k = k + 22_I4P
   enddo
   if (k >= 0_I4P) then
      value = value * 10.0_R8P**k
   else
      value = value / 10.0_R8P**(-k)
   endif
   endfunction grid_value

   pure function is_scientific(magnitude) result(sci)
   !< Whether labels of an axis reaching `magnitude` use scientific notation.
   real(R8P), intent(in) :: magnitude !< Largest absolute value on the axis.
   logical               :: sci       !< Scientific labels.

   sci = magnitude >= SCI_HIGH .or. (magnitude > 0.0_R8P .and. magnitude < SCI_LOW)
   endfunction is_scientific

   pure subroutine format_label(n, e, sci, label, sup)
   !< Label of the tick value `n * 10**e`: plain decimal, or gnuplot-like `1.5x10` with the exponent as superscript.
   integer(I8P),                  intent(in)  :: n      !< Value mantissa.
   integer(I4P),                  intent(in)  :: e      !< Value exponent.
   logical,                       intent(in)  :: sci    !< Scientific notation.
   character(len=:), allocatable, intent(out) :: label  !< Label text.
   character(len=:), allocatable, intent(out) :: sup    !< Label superscript.
   character(len=:), allocatable              :: digits !< Significant digits.
   integer(I8P)                               :: nn     !< Mantissa without trailing zeros.
   integer(I8P)                               :: ee     !< Exponent matching `nn`.

   sup = ''
   if (.not. sci .or. n == 0_I8P) then
      label = decimal_str(n, -e)
      return
   endif
   nn = abs(n)
   ee = int(e, I8P)
   do while (modulo(nn, 10_I8P) == 0_I8P)
      nn = nn / 10_I8P
      ee = ee + 1_I8P
   enddo
   digits = int_str(nn)
   label = digits(1:1)
   if (len(digits) > 1) label = label//'.'//digits(2:)
   if (n < 0_I8P) label = '-'//label
   label = label//'x10'
   sup = int_str(ee + len(digits, kind=I8P) - 1_I8P)
   endsubroutine format_label
endmodule foresight_ticks
