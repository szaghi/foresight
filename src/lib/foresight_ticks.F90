!< foresight_ticks, axis tick placement and labelling.
module foresight_ticks
!< foresight_ticks, axis tick placement and labelling.
!<
!< Automatic steps are gnuplot's (`quantize_normal_tics`, guide 20): they depend on the axis range only, not on its
!< length in pixels (probed on gnuplot 6.0 from 150 to 1200 px: [-2:2] steps by 0.5, [0:1] by 0.2, [0:13] by 2). The
!< range normalised to its decade, f in [1, 10), gives the step 0.2 (f < 2), 0.5 (f < 5) or 1 times the decade. Log
!< axes place majors at integer decades, every 1, 2, 5, 10, ... decades by the same rule on the decade count. Tick
!< values are carried as the integer pair (`n`, `e`)
!< meaning `n * 10**e`, so labels are exact decimal strings, free of floating point noise such as `0.30000000000000004`.
!<
!< User settings (`tics_object`, gnuplot `set xtics` and `set format`) replace the automatic rule: a fixed step from an
!< optional start to an optional end (a multiplying factor on log axes), no ticks at all, or a printf-like label format.
!< Fixed steps are kept as the decimal text the user wrote, so linear ticks stay exact decimals too.
!<
!< An explicit list (gnuplot `set xtics ("label" pos level, ...)`) replaces those ticks, or is added to them (`add`): its
!< items inside the range, a label printed as written (a format when it has a conversion, `"%.1f"`), the axis label of
!< the position when absent; level 1 is a minor tick. A list alone does not extend the range to a tick grid.
!<
!< Minor ticks (gnuplot `set mxtics [N]`) divide each interval between consecutive major ticks of the automatic or fixed
!< ticks in N parts, linearly in value also on log axes, within the range and the fixed ticks' start and end; without N
!< (gnuplot's automatic count) in 2 when the step's leading digit is 2, else 5, and in 9 on log axes. By default linear
!< axes have none, log axes 9 intervals between majors (the 2..9 multiples of a decade on one-decade steps), as
!< gnuplot; `unset mxtics` removes them.
!<
!< Time axes (gnuplot `set xdata time`) follow gnuplot's time rules (`quantize_time_tics`): the step in whole seconds,
!< minutes, hours, days, weeks, months or years, the ticks justified to whole units (`time_tic_just`), labels written by
!< `strftime` with the format set or one gnuplot invents from the range (`%H:%M`, `%m/%d\n%H:%M`, ...).
!<
!< The same rules are mirrored by the interactive viewer, which must regenerate identical ticks after a zoom.
use penf, only : I4P, I8P, R8P
use foresight_format, only : decimal_of, decimal_str, format_check, format_decimal, int_str, parse_decimal, real_str
use foresight_time, only : civil_time, DAY_SEC, MON_SEC, WEEK_SEC, YEAR_SEC, strftime, time_format_check, time_justify, &
                           time_parts

implicit none
private
public :: linear_ticks
public :: list_ticks
public :: log_ticks
public :: merge_list
public :: nice_step
public :: tic_item
public :: tick_object
public :: tics_object
public :: time_ticks
public :: time_tick_format
public :: MINOR_AUTO, MINOR_DEFAULT, MINOR_NONE
public :: TICS_AUTO, TICS_FIXED, TICS_NONE
public :: labels_attribute
public :: push

interface push
   !< Append an item through a temporary: nvfortran 26.9 corrupts `list = [list, item]` (and any `list = f(list)`)
   !< when the items hold deferred-length characters.
   module procedure push_tick, push_item
endinterface push

type :: tick_object
   !< Axis tick.
   real(R8P)                     :: value = 0.0_R8P !< Data value.
   logical                       :: major = .true.  !< Major (labelled) tick, else minor.
   character(len=:), allocatable :: label           !< Label text, empty for minor ticks.
   character(len=:), allocatable :: sup             !< Superscript appended to the label, empty if none.
endtype tick_object

type :: tic_item
   !< Item of an explicit tick list, gnuplot `("label" pos level)`.
   real(R8P)                     :: value = 0.0_R8P   !< Position.
   logical                       :: major = .true.    !< Level 0 (labelled), else level 1: a minor tick.
   logical                       :: labelled = .false. !< The label is given, else the axis label of the position.
   character(len=:), allocatable :: label             !< Label as written, a format if it has a conversion.
endtype tic_item

integer(I4P), parameter :: TICS_AUTO  = 0_I4P !< Ticks by the automatic rule.
integer(I4P), parameter :: TICS_FIXED = 1_I4P !< Ticks at a fixed step.
integer(I4P), parameter :: TICS_NONE  = 2_I4P !< No ticks.

integer(I4P), parameter :: MINOR_DEFAULT = -1_I4P !< Minor ticks by default: none on linear axes, 2..9 on log ones.
integer(I4P), parameter :: MINOR_AUTO    = -2_I4P !< gnuplot's automatic count, `set mxtics`.
integer(I4P), parameter :: MINOR_NONE    = 0_I4P  !< No minor ticks, `unset mxtics`; N > 1: N intervals.

type :: tics_object
   !< User tick settings of an axis, gnuplot `set xtics` and `set format`.
   integer(I4P)                  :: mode = TICS_AUTO !< TICS_AUTO, TICS_FIXED or TICS_NONE.
   character(len=:), allocatable :: start            !< Fixed ticks start (decimal text), empty for none.
   character(len=:), allocatable :: step             !< Fixed ticks step, a factor on log axes (decimal text).
   character(len=:), allocatable :: end              !< Fixed ticks end (decimal text), empty for none.
   character(len=:), allocatable :: format           !< Label format, empty for the default labels.
   logical                       :: mirror = .true.  !< Ticks also on the opposite border, gnuplot `mirror`.
   logical                       :: series = .true.  !< The automatic or fixed ticks, else the explicit list alone.
   integer(I4P)                  :: minor = MINOR_DEFAULT !< Minor ticks: MINOR_DEFAULT, MINOR_AUTO, MINOR_NONE or N.
   integer(I4P)                  :: minor_count = 0_I4P !< Minor ticks of a time axis every `minor_count`
                                                        !< `minor_unit` (gnuplot `set mxtics time N UNITS`), 0 none.
   character(len=7)              :: minor_unit = ''   !< `seconds`, `minutes`, `hours`, `days`, `weeks`, `months`,
                                                      !< `years`.
   real(R8P)                     :: rotate = 0.0_R8P  !< Label angle [deg, counterclockwise], gnuplot `rotate by`.
   character(len=6)              :: justify = ''      !< Label justification of rotated labels: `left`, `right`,
                                                      !< `center`, or blank for gnuplot's (`right` for `rotate`).
   logical                       :: out = .false.     !< Ticks outward, gnuplot `out`.
   type(tic_item), allocatable   :: list(:)          !< Explicit list, gnuplot `set xtics ("label" pos level, ...)`.
   contains
      procedure, pass(self) :: attribute  !< Viewer attribute of the tick positions.
      procedure, pass(self) :: clear_list !< Forget the explicit list, back to the automatic or fixed ticks.
      procedure, pass(self) :: disable    !< No ticks, the explicit list forgotten, gnuplot `unset xtics`.
      procedure, pass(self) :: enable     !< Turn the ticks on, keeping their positions.
      procedure, pass(self) :: has_format !< Whether a label format is set.
      procedure, pass(self) :: has_list   !< Whether an explicit list is set.
      procedure, pass(self) :: anchor     !< Text anchor of the rotated labels.
      procedure, pass(self) :: set_auto   !< Automatic ticks, forgetting a fixed step.
      procedure, pass(self) :: set_fixed  !< Set fixed ticks, validated.
      procedure, pass(self) :: set_list   !< Set or extend the explicit list.
endtype tics_object

real(R8P), parameter :: TOL          = 1.0e-9_R8P !< Tolerance on tick-grid membership, in units of the step.
real(R8P), parameter :: SCI_HIGH     = 1.0e5_R8P  !< Labels switch to scientific notation from this magnitude...
real(R8P), parameter :: SCI_LOW      = 1.0e-3_R8P !< ...or below this one.
integer(I8P), parameter :: MAX_TICKS = 1000_I8P   !< Tick count cap: no ticks beyond it (degenerate or extreme zoom).
integer(I8P), parameter :: MAX_POWER = 10000_I8P  !< Largest power of a fixed log step: no ticks beyond it.

contains
   pure function attribute(self, lo, hi) result(text)
   !< Tick positions for the viewer: empty for automatic, `none`, or `START STEP END` with `*` for an absent end, then
   !< `minor auto|N` unless minor ticks are by default (`auto` first if automatic), `out` for outward ticks and
   !< `rotate ANGLE ANCHOR` for rotated labels. With an explicit list (and the axis
   !< range [`lo`, `hi`], for the default labels of its items): `labels` and its items (see `labels_attribute`), after
   !< `auto` or the step when the list is added to them.
   class(tics_object), intent(in)           :: self  !< Settings.
   real(R8P),          intent(in), optional :: lo    !< Value at the axis start.
   real(R8P),          intent(in), optional :: hi    !< Value at the axis end.
   character(len=:), allocatable            :: text  !< Attribute text.
   type(tick_object), allocatable           :: items(:) !< Labelled list items.

   select case (self%mode)
   case (TICS_FIXED)
      text = or_star(self%start)//' '//self%step//' '//or_star(self%end)
   case (TICS_NONE)
      text = 'none'
   case default
      text = ''
   endselect
   if (self%mode == TICS_NONE) return
   if (self%minor /= MINOR_DEFAULT) then
      if (len(text) == 0) text = 'auto'
      select case (self%minor)
      case (MINOR_AUTO)
         text = text//' minor auto'
      case default
         text = text//' minor '//int_str(int(self%minor, I8P))
      endselect
   endif
   if (self%out .or. self%rotate /= 0.0_R8P) then
      if (len(text) == 0) text = 'auto'
      if (self%out) text = text//' out'
      if (self%rotate /= 0.0_R8P) text = text//' rotate '//real_str(self%rotate)//' '//trim(self%anchor())
   endif
   if (.not. (self%has_list() .and. present(lo) .and. present(hi))) return
   call list_ticks(self, lo, hi, .true., items)
   if (self%series) then
      if (len(text) == 0) text = 'auto'
      text = text//' '//labels_attribute(items)
   else
      text = labels_attribute(items)
   endif
   contains
      pure function or_star(value) result(t)
      !< `value`, or `*` if empty.
      character(len=*), intent(in)  :: value !< Decimal text.
      character(len=:), allocatable :: t     !< Text.

      t = value
      if (len(t) == 0) t = '*'
      endfunction or_star
   endfunction attribute

   pure function labels_attribute(labels) result(text)
   !< Text labels for the viewer: `labels` then `value:label` pairs, blank separated, each label percent-encoded (every
   !< byte but letters, digits and `-._~`), so blanks and colons in a label never split it; a superscript follows as
   !< `^sup`, a minor tick is `value!`.
   type(tick_object), intent(in) :: labels(:) !< Labelled values.
   character(len=:), allocatable :: text      !< Attribute text.
   character(len=*), parameter   :: HEX = '0123456789ABCDEF' !< Hexadecimal digits.
   integer(I4P)                  :: k         !< Label counter.

   text = 'labels'
   do k = 1_I4P, size(labels, kind=I4P)
      if (.not. labels(k)%major) then
         text = text//' '//real_str(labels(k)%value)//'!'
         cycle
      endif
      text = text//' '//real_str(labels(k)%value)//':'//encoded(labels(k)%label)
      if (allocated(labels(k)%sup)) then
         if (len(labels(k)%sup) > 0) text = text//'^'//encoded(labels(k)%sup)
      endif
   enddo
   contains
      pure function encoded(raw) result(enc)
      !< `raw` percent-encoded.
      character(len=*), intent(in)  :: raw !< Text.
      character(len=:), allocatable :: enc !< Encoded text.
      integer(I4P)                  :: i   !< Byte counter.
      integer(I4P)                  :: b   !< Byte value.

      enc = ''
      do i = 1_I4P, len(raw, kind=I4P)
         b = ichar(raw(i:i))
         if (verify(raw(i:i), 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~') == 0) then
            enc = enc//raw(i:i)
         else
            enc = enc//'%'//HEX(b / 16 + 1:b / 16 + 1)//HEX(modulo(b, 16) + 1:modulo(b, 16) + 1)
         endif
      enddo
      endfunction encoded
   endfunction labels_attribute

   pure subroutine enable(self)
   !< Turn off ticks on again at their last positions, as gnuplot `set xtics` without positions: the fixed step if one
   !< was set (and not reset by `set_auto`), else automatic. Ticks already on are unchanged.
   class(tics_object), intent(inout) :: self !< Settings.

   if (self%mode /= TICS_NONE) return
   self%mode = TICS_AUTO
   if (allocated(self%step)) then
      if (len(self%step) > 0) self%mode = TICS_FIXED
   endif
   endsubroutine enable

   pure subroutine set_auto(self)
   !< Automatic ticks, as gnuplot `set xtics auto`: the fixed step is forgotten, so `enable` restores automatic ones.
   class(tics_object), intent(inout) :: self !< Settings.

   self%mode = TICS_AUTO
   self%step = ''
   self%start = ''
   self%end = ''
   call self%clear_list
   endsubroutine set_auto

   pure subroutine clear_list(self)
   !< Forget the explicit list: the automatic or fixed ticks again, as gnuplot `set xtics` with positions but no `add`.
   class(tics_object), intent(inout) :: self !< Settings.

   if (allocated(self%list)) deallocate(self%list)
   self%series = .true.
   endsubroutine clear_list

   pure subroutine disable(self)
   !< No ticks, as gnuplot `unset xtics`: the explicit list is forgotten, a fixed step kept for `enable`.
   class(tics_object), intent(inout) :: self !< Settings.

   self%mode = TICS_NONE
   call self%clear_list
   endsubroutine disable

   pure function anchor(self) result(text_anchor)
   !< Text anchor of the rotated labels, as gnuplot: by their justification, else `start` (gnuplot `rotate by`).
   class(tics_object), intent(in) :: self        !< Settings.
   character(len=6)               :: text_anchor !< `start`, `end` or `middle`.

   select case (trim(self%justify))
   case ('right')
      text_anchor = 'end'
   case ('center')
      text_anchor = 'middle'
   case default
      text_anchor = 'start'
   endselect
   endfunction anchor

   pure function has_list(self) result(has)
   !< Whether an explicit list is set.
   class(tics_object), intent(in) :: self !< Settings.
   logical                        :: has  !< List set.

   has = .false.
   if (allocated(self%list)) has = size(self%list) > 0
   endfunction has_list

   pure subroutine set_list(self, items, add)
   !< The explicit list `items` replaces the ticks, or with `add` extends the list and keeps the ticks, as gnuplot
   !< `set xtics [add] ("label" pos level, ...)`; ticks turned off are turned on.
   class(tics_object), intent(inout) :: self     !< Settings.
   type(tic_item),     intent(in)    :: items(:) !< Items.
   logical,            intent(in)    :: add      !< Added to the ticks and the list.
   integer(I4P)                      :: k        !< Item counter.

   if (.not. add) then
      if (allocated(self%list)) deallocate(self%list)
      self%series = .false.
   endif
   if (.not. allocated(self%list)) allocate(self%list(0))
   do k = 1_I4P, size(items, kind=I4P)
      call push(self%list, items(k))
   enddo
   call self%enable
   endsubroutine set_list

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
   self%series = .true.
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

   pure subroutine gnuplot_step(range, m, e)
   !< gnuplot's automatic step `m * 10**e` of an axis `range` (> 0) long: `quantize_normal_tics(range, 20)`, with the
   !< range normalised to its decade (f in [1, 10)): 2 10**(p-1) for f < 2, 5 10**(p-1) for f < 5, else 10**p. Exact
   !< powers of ten, so the viewer's mirror finds the same step.
   real(R8P),    intent(in)  :: range !< Axis range.
   integer(I8P), intent(out) :: m     !< Step mantissa.
   integer(I4P), intent(out) :: e     !< Step exponent.
   real(R8P)                 :: f     !< Range normalised to its decade.
   integer(I4P)              :: p     !< Decade of the range.

   m = 1_I8P
   e = 0_I4P
   if (.not. (range > 0.0_R8P .and. range <= huge(1.0_R8P))) return
   p = floor(log10(range), I4P)
   f = scaled(range, p)
   ! log10 may land on the wrong side of a decade
   if (f >= 10.0_R8P) then
      p = p + 1_I4P
      f = scaled(range, p)
   elseif (f < 1.0_R8P) then
      p = p - 1_I4P
      f = scaled(range, p)
   endif
   if (f < 2.0_R8P) then
      m = 2_I8P
      e = p - 1_I4P
   elseif (f < 5.0_R8P) then
      m = 5_I8P
      e = p - 1_I4P
   else
      m = 1_I8P
      e = p
   endif
   contains
      pure function scaled(x, k) result(y)
      !< `x / 10**k` by an exact power of ten.
      real(R8P),    intent(in) :: x !< Value.
      integer(I4P), intent(in) :: k !< Exponent.
      real(R8P)                :: y !< Scaled value.

      if (k >= 0_I4P) then
         y = x / 10.0_R8P**k
      else
         y = x * 10.0_R8P**(-k)
      endif
      endfunction scaled
   endsubroutine gnuplot_step

   pure subroutine time_ticks(lo, hi, extend_lo, extend_hi, ticks, tics, timefmt)
   !< Ticks of a time axis (values in seconds since 1970), as gnuplot's: the automatic step `quantize_time_tics` (or the
   !< fixed step of `tics`, in seconds), autoscaled ends extended outward to it and justified to whole time units,
   !< the ticks justified so too, labelled with the time format of `tics` or one invented from the range
   !< (`time_tick_format`, `timefmt` giving the day and month order). Minor ticks: `set mxtics N` divides each
   !< step in N, `set mxtics` gnuplot's automatic time step, none by default; `set mxtics time N UNITS` one at every
   !< N units of time (seconds to weeks: multiples of N units since the epoch; months and years: the first day of
   !< every N-th month or year, counted from 1970), as gnuplot 6.0.
   real(R8P),                      intent(inout) :: lo        !< Value at the axis start (`lo > hi`: reversed).
   real(R8P),                      intent(inout) :: hi        !< Value at the axis end.
   logical,                        intent(in)    :: extend_lo !< Extend `lo` outward to the tick grid.
   logical,                        intent(in)    :: extend_hi !< Extend `hi` outward to the tick grid.
   type(tick_object), allocatable, intent(out)   :: ticks(:)  !< Ticks, ascending in value.
   type(tics_object),              intent(in)    :: tics      !< User settings.
   character(len=*),               intent(in)    :: timefmt   !< Input time format (gnuplot `set timefmt`).
   real(R8P), parameter          :: SIGNIF = 0.01_R8P !< gnuplot's rounding tolerance, in steps.
   character(len=:), allocatable :: format    !< Label format.
   real(R8P)                     :: step      !< Tick step [s].
   real(R8P)                     :: lmin      !< Smaller end.
   real(R8P)                     :: lmax      !< Larger end.
   real(R8P)                     :: start     !< First tick before justification.
   real(R8P)                     :: last      !< Last tick before justification.
   real(R8P)                     :: tmin      !< Smallest tick kept.
   real(R8P)                     :: tmax      !< Largest tick kept.
   real(R8P)                     :: tic       !< Tick before justification.
   real(R8P)                     :: internal  !< Justified tick.
   real(R8P)                     :: ministep  !< Minor step [s], 0 for none.
   real(R8P)                     :: miniend   !< Minor ticks end within a step.
   real(R8P)                     :: mplace    !< Minor tick offset.
   real(R8P)                     :: v         !< Fixed start or end.
   integer(I8P)                  :: m         !< Step mantissa.
   integer(I8P)                  :: k         !< Tick counter.
   integer(I8P)                  :: nsteps    !< Ticks.
   integer(I4P)                  :: e         !< Step exponent.
   integer(I4P)                  :: level     !< Time level of the step.
   type(tick_object)             :: tick      !< One tick.
   logical                       :: has_start !< Fixed start.
   logical                       :: has_end   !< Fixed end.

   allocate(ticks(0))
   if (tics%mode == TICS_NONE .or. lo == hi .or. .not. (abs(hi - lo) <= huge(1.0_R8P))) return
   has_start = .false.
   has_end = .false.
   if (tics%mode == TICS_FIXED) then
      step = abs(decimal_value(tics%step))
      if (.not. (step > 0.0_R8P)) return
      level = time_level(step)
      if (allocated(tics%start)) has_start = len(tics%start) > 0
      if (allocated(tics%end)) has_end = len(tics%end) > 0
   else
      call gnuplot_step(abs(hi - lo), m, e)
      step = grid_value(m, e)
      call quantize_time_tics(step, abs(hi - lo), level)
   endif
   ! autoscaled ends outward to the step, then to a whole time unit
   if (lo <= hi) then
      if (extend_lo .and. .not. has_start) lo = outward(lo, .false.)
      if (extend_hi .and. .not. has_end) hi = outward(hi, .true.)
   else
      if (extend_lo .and. .not. has_start) lo = outward(lo, .true.)
      if (extend_hi .and. .not. has_end) hi = outward(hi, .false.)
   endif
   if (tics%has_format()) then
      format = time_tick_format(tics%format, level, lo, hi, timefmt)
   else
      format = time_tick_format('', level, lo, hi, timefmt)
   endif
   lmin = min(lo, hi)
   lmax = max(lo, hi)
   start = step * real(floor(lmin / step, I8P), R8P)
   last = step * real(ceiling(lmax / step, I8P), R8P)
   if (has_start) then
      v = decimal_value(tics%start)
      start = v
   endif
   if (has_end) then
      v = decimal_value(tics%end)
      last = v
   endif
   last = last + SIGNIF * step
   if (step < abs(lmax) + abs(lmin)) then
      tmin = lmin - SIGNIF * step
      tmax = lmax + SIGNIF * step
   else
      tmin = lmin
      tmax = lmax
   endif
   if ((tmax - tmin) / step > real(MAX_TICKS, R8P) .or. last < start) return
   nsteps = int((last - start) / step, I8P) + 1_I8P
   ! minor steps
   ministep = 0.0_R8P
   miniend = step
   if (tics%minor_count > 0_I4P) then
      continue
   elseif (tics%minor > 1_I4P) then
      ministep = step / real(tics%minor, R8P)
   elseif (tics%minor == MINOR_AUTO) then
      ministep = auto_time_minitics(level, step)
      miniend = 0.9_R8P * step
   endif
   do k = 0_I8P, nsteps - 1_I8P
      tic = start + real(k, R8P) * step
      internal = time_justify(level, tic)
      if (internal > tmax) exit
      if (internal >= tmin) then
         tick%value = internal
         if (abs(internal) < step * SIGNIF) tick%value = 0.0_R8P
         tick%major = .true.
         tick%label = strftime(format, tick%value)
         tick%sup = ''
         call push(ticks, tick)
      endif
      if (ministep > 0.0_R8P) then
         mplace = ministep
         do while (mplace < miniend)
            if (internal + mplace >= tmin .and. internal + mplace <= tmax .and. &
                internal + mplace >= start - step * SIGNIF .and. internal + mplace <= last) then
               tick%value = internal + mplace
               tick%major = .false.
               tick%label = ''
               tick%sup = ''
               call push(ticks, tick)
            endif
            mplace = mplace + ministep
         enddo
      endif
   enddo
   if (tics%minor_count > 0_I4P) call unit_minors(ticks)
   call sort_ticks(ticks)
   contains
      pure subroutine unit_minors(ticks)
      !< `set mxtics time N UNITS`: a minor tick at every N units within the axis, but on a major tick.
      type(tick_object), allocatable, intent(inout) :: ticks(:) !< Ticks.
      real(R8P)    :: unit  !< Unit [s] (seconds to weeks).
      real(R8P)    :: t     !< Minor tick.
      integer(I8P) :: n     !< Units.
      integer(I8P) :: j     !< Unit counter.
      integer(I8P) :: parts(6) !< Year, month, day, hour, minute, second of the start.
      real(R8P)    :: fraction !< Second fraction.
      integer(I8P) :: yday  !< Day of the year.
      integer(I8P) :: wday  !< Weekday.
      integer(I4P) :: count !< Ticks made.

      n = int(tics%minor_count, I8P)
      count = 0_I4P
      select case (trim(tics%minor_unit))
      case ('months', 'years')
         call time_parts(lmin, parts(1), parts(2), parts(3), parts(4), parts(5), parts(6), fraction, yday, wday)
         ! months since January 1970, from the start's month
         j = (parts(1) - 1970_I8P) * 12_I8P + parts(2) - 1_I8P
         if (trim(tics%minor_unit) == 'years') j = 12_I8P * (parts(1) - 1970_I8P)
         do
            if (trim(tics%minor_unit) == 'years') then
               if (modulo(j / 12_I8P, n) /= 0_I8P) then
                  j = j + 12_I8P
                  cycle
               endif
            elseif (modulo(j, n) /= 0_I8P) then
               j = j + 1_I8P
               cycle
            endif
            t = civil_time(1970_I8P + j / 12_I8P, modulo(j, 12_I8P) + 1_I8P, 1_I8P, 0_I8P, 0_I8P, 0.0_R8P)
            if (t > lmax) exit
            if (t >= lmin) call minor_at(ticks, t)
            j = j + merge(12_I8P, 1_I8P, trim(tics%minor_unit) == 'years')
            count = count + 1_I4P
            if (count > 10_I4P * MAX_TICKS) exit
         enddo
      case default
         select case (trim(tics%minor_unit))
         case ('seconds')
            unit = 1.0_R8P
         case ('minutes')
            unit = 60.0_R8P
         case ('hours')
            unit = 3600.0_R8P
         case ('days')
            unit = DAY_SEC
         case default
            unit = WEEK_SEC
         endselect
         unit = unit * real(n, R8P)
         if ((lmax - lmin) / unit > real(10_I4P * MAX_TICKS, R8P)) return
         do j = ceiling(lmin / unit, I8P), floor(lmax / unit, I8P)
            call minor_at(ticks, real(j, R8P) * unit)
         enddo
      endselect
      endsubroutine unit_minors

      pure subroutine minor_at(ticks, t)
      !< A minor tick at `t`, unless a major tick lies there.
      type(tick_object), allocatable, intent(inout) :: ticks(:) !< Ticks.
      real(R8P), intent(in) :: t    !< Value.
      type(tick_object)     :: mtick !< Minor tick.

      if (size(ticks) > 0) then
         if (any(ticks%major .and. abs(ticks%value - t) <= SIGNIF * step)) return
      endif
      mtick%value = t
      mtick%major = .false.
      mtick%label = ''
      mtick%sup = ''
      call push(ticks, mtick)
      endsubroutine minor_at

      pure function outward(input, upwards) result(edge)
      !< gnuplot's `round_outward` of a time axis end: to the step grid, then to the whole time unit beyond it.
      real(R8P), intent(in) :: input   !< Axis end.
      logical,   intent(in) :: upwards !< Extend upwards.
      real(R8P)             :: edge    !< Extended end.
      real(R8P)             :: ontime  !< Justified end.

      if (upwards) then
         edge = step * real(ceiling(input / step, I8P), R8P)
      else
         edge = step * real(floor(input / step, I8P), R8P)
      endif
      ontime = time_justify(level, edge)
      if ((upwards .and. ontime > edge) .or. (.not. upwards .and. ontime < edge)) edge = ontime
      endfunction outward
   endsubroutine time_ticks

   pure function time_tick_format(format, level, lo, hi, timefmt) result(chosen)
   !< Label format of a time axis: `format` if it is a time format (not a numeric printf one), else gnuplot's invented
   !< one (`copy_or_invent_formatstring`): within one day `%H:%M` (`:%S` for steps under a minute, `%M` alone at the
   !< day level); over days `%m/%d` (`%d/%m` when `timefmt` has the day first, then `/%y` or `/%Y` across years) and
   !< `\n%H:%M` below the week level.
   character(len=*), intent(in)  :: format  !< Format set, empty for none.
   integer(I4P),     intent(in)  :: level   !< Time level of the step.
   real(R8P),        intent(in)  :: lo      !< Axis start.
   real(R8P),        intent(in)  :: hi      !< Axis end.
   character(len=*), intent(in)  :: timefmt !< Input time format.
   character(len=:), allocatable :: chosen  !< Label format.
   integer(I8P)                  :: a(9)    !< Parts of the justified start.
   integer(I8P)                  :: b(9)    !< Parts of the justified end.
   real(R8P)                     :: frac    !< Fraction of a second.
   logical                       :: month_first !< `%m` before `%d` in `timefmt`.

   if (len(format) > 0) then
      if (len(time_format_check(format)) == 0 .and. .not. looks_numeric(format)) then
         chosen = format
         return
      endif
   endif
   call time_parts(time_justify(level, lo), a(1), a(2), a(3), a(4), a(5), a(6), frac, a(8), a(9))
   call time_parts(time_justify(level, hi), b(1), b(2), b(3), b(4), b(5), b(6), frac, b(8), b(9))
   ! gnuplot compares strchr positions: a missing letter is a null pointer, before any other
   month_first = index(timefmt, 'm') < index(timefmt, 'd')
   chosen = ''
   if (a(1) == b(1) .and. a(8) == b(8)) then
      if (a(4) /= b(4)) chosen = '%H'
      if (level < 3_I4P) then
         if (len(chosen) > 0) chosen = chosen//':'
         chosen = chosen//'%M'
      endif
      if (level < 2_I4P) chosen = chosen//':%S'
   else
      if (a(1) /= b(1)) then
         chosen = merge('%m/%d/%', '%d/%m/%', month_first)
         if (a(1) / 100_I8P /= b(1) / 100_I8P) then
            chosen = chosen//'Y'
         else
            chosen = chosen//'y'
         endif
      else
         chosen = merge('%m/%d', '%d/%m', month_first)
      endif
      if (level < 4_I4P) chosen = chosen//new_line('a')//'%H:%M'
   endif
   endfunction time_tick_format

   pure function looks_numeric(format) result(numeric)
   !< gnuplot's `looks_like_numeric`: the first conversion is a numeric printf one (`%5.2f`, `%g`, `%e`, ...).
   character(len=*), intent(in) :: format  !< Format.
   logical                      :: numeric !< Numeric.
   integer(I4P)                 :: i       !< Position.

   numeric = .false.
   i = index(format, '%', kind=I4P)
   if (i == 0_I4P) return
   i = i + 1_I4P
   do while (i <= len(format, kind=I4P))
      if (scan(format(i:i), '0123456789.-+ #') == 0) exit
      i = i + 1_I4P
   enddo
   if (i <= len(format)) numeric = scan(format(i:i), 'efgEFGh') > 0 .and. format(i:i) /= 'h'
   endfunction looks_numeric

   pure subroutine quantize_time_tics(tic, xr, level)
   !< gnuplot's `quantize_time_tics`: the step `tic` rounded to whole seconds, minutes, hours, days, weeks, months or
   !< years for a range `xr` [s], and its `level` (0 seconds ... 6 years).
   real(R8P),    intent(inout) :: tic   !< Step [s].
   real(R8P),    intent(in)    :: xr    !< Range [s].
   integer(I4P), intent(out)   :: level !< Time level.
   integer(I4P), parameter     :: GUIDE12 = 12_I4P !< Guide of the duodecimal rounding (20 * 3 / 5).
   integer(I8P)                :: m     !< Step mantissa.
   integer(I4P)                :: e     !< Step exponent.

   level = 0_I4P
   if (tic > 5.0_R8P) then
      tic = duodecimal(xr / 60.0_R8P, GUIDE12) * 60.0_R8P
      if (tic >= 60.0_R8P) level = 1_I4P
   endif
   if (tic > 300.0_R8P) then
      tic = duodecimal(xr / 3600.0_R8P, GUIDE12) * 3600.0_R8P
      if (tic >= 3600.0_R8P) level = 2_I4P
   endif
   if (tic > 3600.0_R8P) then
      tic = duodecimal(xr / DAY_SEC, GUIDE12) * DAY_SEC
      if (tic >= DAY_SEC) level = 3_I4P
   endif
   if (tic > 2.0_R8P * DAY_SEC) then
      call gnuplot_step(xr / WEEK_SEC, m, e)
      tic = max(grid_value(m, e) * WEEK_SEC, WEEK_SEC)
      level = 4_I4P
   endif
   if (tic > 3.0_R8P * WEEK_SEC) then
      call gnuplot_step(xr / MON_SEC, m, e)
      tic = max(grid_value(m, e) * MON_SEC, MON_SEC)
      level = 5_I4P
   endif
   if (tic > MON_SEC) then
      tic = duodecimal(xr / YEAR_SEC, GUIDE12) * YEAR_SEC
      if (tic >= YEAR_SEC) level = 6_I4P
   endif
   endsubroutine quantize_time_tics

   pure function duodecimal(arg, guide) result(tic)
   !< gnuplot's `quantize_duodecimal_tics`: a step for `arg` in a duodecimal reference (12 or 60 based).
   real(R8P),    intent(in) :: arg   !< Range in the unit.
   integer(I4P), intent(in) :: guide !< Approximate number of ticks.
   real(R8P)                :: tic   !< Step in the unit.
   real(R8P)                :: power !< Power of 12 below `arg`.
   real(R8P)                :: xnorm !< `arg` over it.
   real(R8P)                :: posns !< Ticks per power.

   power = 12.0_R8P**floor(log(arg) / log(12.0_R8P))
   xnorm = arg / power
   posns = real(guide, R8P) / xnorm
   if (posns > 24.0_R8P) then
      tic = power / 24.0_R8P
   elseif (posns > 12.0_R8P) then
      tic = power / 12.0_R8P
   elseif (posns > 6.0_R8P) then
      tic = power / 6.0_R8P
   elseif (posns > 4.0_R8P) then
      tic = power / 4.0_R8P
   elseif (posns > 2.0_R8P) then
      tic = power / 2.0_R8P
   elseif (posns > 1.0_R8P) then
      tic = power
   elseif (posns > 0.5_R8P) then
      tic = power * 2.0_R8P
   elseif (posns > 1.0_R8P / 3.0_R8P) then
      tic = power * 3.0_R8P
   else
      tic = power * ceiling(xnorm)
   endif
   endfunction duodecimal

   pure function time_level(step) result(level)
   !< Time level of a fixed step [s], as gnuplot's `setup_tics`.
   real(R8P), intent(in) :: step  !< Step [s].
   integer(I4P)          :: level !< Time level.

   if (step >= 365.0_R8P * DAY_SEC) then
      level = 6_I4P
   elseif (step >= 28.0_R8P * DAY_SEC) then
      level = 5_I4P
   elseif (step >= WEEK_SEC) then
      level = 4_I4P
   elseif (step >= DAY_SEC) then
      level = 3_I4P
   elseif (step >= 3600.0_R8P) then
      level = 2_I4P
   elseif (step >= 60.0_R8P) then
      level = 1_I4P
   else
      level = 0_I4P
   endif
   endfunction time_level

   pure function auto_time_minitics(level, incr) result(tinc)
   !< gnuplot's `make_auto_time_minitics`: the minor step [s] of a time step `incr` at `level`, 0 for none.
   integer(I4P), intent(in) :: level !< Time level.
   real(R8P),    intent(in) :: incr  !< Major step [s].
   real(R8P)                :: tinc  !< Minor step [s].

   tinc = 0.0_R8P
   select case (level)
   case (0_I4P, 1_I4P)
      if (incr >= 5.0_R8P) tinc = 1.0_R8P
      if (incr >= 10.0_R8P) tinc = 5.0_R8P
      if (incr >= 20.0_R8P) tinc = 10.0_R8P
      if (incr >= 60.0_R8P) tinc = 20.0_R8P
      if (incr >= 120.0_R8P) tinc = 60.0_R8P
      if (incr >= 360.0_R8P) tinc = 120.0_R8P
      if (incr >= 720.0_R8P) tinc = 180.0_R8P
      if (incr >= 1440.0_R8P) tinc = 360.0_R8P
   case (2_I4P)
      if (incr >= 1200.0_R8P) tinc = 600.0_R8P
      if (incr >= 3600.0_R8P) tinc = 1800.0_R8P
      if (incr >= 7200.0_R8P) tinc = 3600.0_R8P
      if (incr >= 21600.0_R8P) tinc = 7200.0_R8P
      if (incr >= 43200.0_R8P) tinc = 10800.0_R8P
      if (incr >= 86400.0_R8P) tinc = 21600.0_R8P
   case (3_I4P)
      if (incr > 7200.0_R8P) tinc = 3600.0_R8P
      if (incr > 14400.0_R8P) tinc = 7200.0_R8P
      if (incr > 25200.0_R8P) tinc = 10800.0_R8P
      if (incr > 46800.0_R8P) tinc = 21600.0_R8P
      if (incr > DAY_SEC) tinc = 43200.0_R8P
      if (incr > 2.0_R8P * DAY_SEC) tinc = DAY_SEC
   case (4_I4P)
      if (incr > 2.0_R8P * DAY_SEC) tinc = DAY_SEC
      if (incr > 7.0_R8P * DAY_SEC) tinc = 7.0_R8P * DAY_SEC
   case (5_I4P)
      if (incr > 2.0_R8P * DAY_SEC) tinc = DAY_SEC
      if (incr > 15.0_R8P * DAY_SEC) tinc = 10.0_R8P * DAY_SEC
      if (incr > 2.0_R8P * MON_SEC) tinc = MON_SEC
      if (incr > 6.0_R8P * MON_SEC) tinc = 3.0_R8P * MON_SEC
      if (incr > 2.0_R8P * YEAR_SEC) tinc = YEAR_SEC
   case default
      if (incr > 2.0_R8P * MON_SEC) tinc = MON_SEC
      if (incr > 6.0_R8P * MON_SEC) tinc = 3.0_R8P * MON_SEC
      if (incr > 2.0_R8P * YEAR_SEC) tinc = YEAR_SEC
      if (incr > 10.0_R8P * YEAR_SEC) tinc = 5.0_R8P * YEAR_SEC
      if (incr > 50.0_R8P * YEAR_SEC) tinc = 10.0_R8P * YEAR_SEC
      if (incr > 100.0_R8P * YEAR_SEC) tinc = 20.0_R8P * YEAR_SEC
      if (incr > 200.0_R8P * YEAR_SEC) tinc = 50.0_R8P * YEAR_SEC
      if (incr > 300.0_R8P * YEAR_SEC) tinc = 100.0_R8P * YEAR_SEC
   endselect
   endfunction auto_time_minitics

   pure function decimal_value(text) result(v)
   !< Value of a decimal text (a fixed tick start, step or end).
   character(len=*), intent(in) :: text !< Decimal text.
   real(R8P)                    :: v    !< Value.
   integer(I8P)                 :: n    !< Mantissa.
   integer(I4P)                 :: e    !< Exponent.
   logical                      :: ok   !< Parsed.

   call parse_decimal(text, n, e, ok)
   v = 0.0_R8P
   if (ok) v = grid_value(n, e)
   endfunction decimal_value

   pure subroutine sort_ticks(ticks)
   !< Sort the ticks by value (insertion sort: few ticks, the majors and minors interleaved).
   type(tick_object), intent(inout) :: ticks(:) !< Ticks.
   type(tick_object)                :: held     !< Tick being placed.
   integer(I4P)                     :: i        !< Counter.
   integer(I4P)                     :: j        !< Counter.

   do i = 2_I4P, size(ticks, kind=I4P)
      held = ticks(i)
      j = i - 1_I4P
      do while (j >= 1_I4P)
         if (ticks(j)%value <= held%value) exit
         ticks(j + 1_I4P) = ticks(j)
         j = j - 1_I4P
      enddo
      ticks(j + 1_I4P) = held
   enddo
   endsubroutine sort_ticks

   pure subroutine linear_ticks(lo, hi, npx, extend_lo, extend_hi, ticks, tics)
   !< Major ticks of a linear axis (`npx` pixels long, kept for the interface: gnuplot's density does not depend on it);
   !< autoscaled ends are extended outward to the tick grid.
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
   call gnuplot_step(abs(hi - lo), m, e)
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
   if (present(tics)) call append_minors(ticks, 0.0_R8P, step, .false., minor_count(tics, m, .false.), lo, hi, &
                                         -huge(1.0_R8P), huge(1.0_R8P))
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
   logical                                       :: default_minors !< Minor ticks by default (2..9 of a decade).
   integer(I4P)                                  :: nminor    !< Intervals between majors of the minor ticks.

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
   call gnuplot_step(tb - ta, m, e)
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
      call push(ticks, tick)
   enddo
   default_minors = .true.
   if (present(tics)) default_minors = tics%minor == MINOR_DEFAULT
   if (s == 1_I8P .and. tb - ta <= 10.0_R8P .and. (default_minors .or. plain)) then
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
            call push(ticks, tick)
         enddo
      enddo
   endif
   if (count(ticks%major) < 2) then
      a = lo
      b = hi
      call linear_ticks(a, b, npx, .false., .false., linear, tics)
      ticks = pack(linear, linear%value > 0.0_R8P)
   elseif (.not. plain .and. (.not. default_minors .or. s > 1_I8P)) then
      ! set minors, or the default ones of majors several decades apart: linear between majors, as gnuplot
      nminor = 9_I4P
      if (present(tics)) nminor = minor_count(tics, 1_I8P, .true.)
      call append_minors(ticks, 1.0_R8P, grid_value(1_I8P, int(s, I4P)), .true., nminor, lo, hi, -huge(1.0_R8P), &
                         huge(1.0_R8P))
   endif
   endsubroutine log_ticks

   ! private procedures
   pure subroutine append_minors(ticks, first, step, logaxis, n, lo, hi, lower, upper)
   !< Append to `ticks` the minor ticks of the majors `first + k step` (`first step**k` on a log axis), `n` intervals
   !< between consecutive majors, linear in value, inside [`lo`, `hi`] (either order) and [`lower`, `upper`]; none for
   !< `n` < 2.
   type(tick_object), allocatable, intent(inout) :: ticks(:) !< Ticks.
   real(R8P),                      intent(in)    :: first    !< A major tick.
   real(R8P),                      intent(in)    :: step     !< Major step, a factor (> 1) on a log axis.
   logical,                        intent(in)    :: logaxis  !< Log axis.
   integer(I4P),                   intent(in)    :: n        !< Intervals between majors.
   real(R8P),                      intent(in)    :: lo       !< Value at the axis start.
   real(R8P),                      intent(in)    :: hi       !< Value at the axis end.
   real(R8P),                      intent(in)    :: lower    !< Smallest value of the series.
   real(R8P),                      intent(in)    :: upper    !< Largest value of the series.
   type(tick_object)                             :: tick     !< Minor tick.
   real(R8P)                                     :: a        !< Smaller range end.
   real(R8P)                                     :: b        !< Larger range end.
   real(R8P)                                     :: slack    !< Tolerance on the ends (in decades on a log axis).
   real(R8P)                                     :: ma       !< Interval start.
   real(R8P)                                     :: mb       !< Interval end.
   integer(I8P)                                  :: k        !< Interval index.
   integer(I8P)                                  :: kmin     !< First interval.
   integer(I8P)                                  :: kmax     !< Last interval.
   integer(I4P)                                  :: j        !< Minor counter.

   if (n < 2_I4P .or. .not. (step > 0.0_R8P)) return
   if (logaxis .and. (step <= 1.0_R8P .or. first <= 0.0_R8P)) return
   a = min(lo, hi)
   b = max(lo, hi)
   slack = 1.0e-9_R8P * (b - a)
   if (logaxis) then
      if (a <= 0.0_R8P) return
      if (max(abs(log10(a)), abs(log10(b)), abs(log10(first))) / log10(step) > real(MAX_POWER, R8P)) return
      kmin = floor((log10(a) - log10(first)) / log10(step) + TOL, I8P) - 1_I8P
      kmax = ceiling((log10(b) - log10(first)) / log10(step) - TOL, I8P)
   else
      if (max(abs(a), abs(b), abs(first)) / step > 1.0e15_R8P) return
      kmin = floor((a - first) / step + TOL, I8P) - 1_I8P
      kmax = ceiling((b - first) / step - TOL, I8P)
   endif
   if ((kmax - kmin) * int(n, I8P) > 10_I8P * MAX_TICKS) return
   tick%major = .false.
   tick%label = ''
   tick%sup = ''
   do k = kmin, kmax
      if (logaxis) then
         ma = 10.0_R8P**(log10(first) + real(k, R8P) * log10(step))
         mb = ma * step
      else
         ma = first + real(k, R8P) * step
         mb = ma + step
      endif
      do j = 1_I4P, n - 1_I4P
         tick%value = ma + real(j, R8P) * (mb - ma) / real(n, R8P)
         if (logaxis) then
            if (.not. within(log10(tick%value), log10(a), log10(b), TOL)) cycle
            ! relative to the series ends, when there are ends (no overflow on huge)
            if (lower > -huge(1.0_R8P)) then
               if (tick%value < lower * (1.0_R8P - TOL)) cycle
            endif
            if (upper < huge(1.0_R8P)) then
               if (tick%value > upper * (1.0_R8P + TOL)) cycle
            endif
         else
            if (.not. within(tick%value, a, b, slack)) cycle
            if (tick%value < lower - slack .or. tick%value > upper + slack) cycle
         endif
         call push(ticks, tick)
      enddo
   enddo
   contains
      pure function within(v, low, high, margin) result(inside)
      !< Whether `v` lies in [`low`, `high`] to `margin`.
      real(R8P), intent(in) :: v      !< Value.
      real(R8P), intent(in) :: low    !< Lower end.
      real(R8P), intent(in) :: high   !< Upper end.
      real(R8P), intent(in) :: margin !< Tolerance.
      logical               :: inside !< Inside.

      inside = v >= low - margin .and. v <= high + margin
      endfunction within
   endsubroutine append_minors

   pure function minor_count(tics, mantissa, logaxis) result(n)
   !< Intervals between major ticks for the minor ticks of `tics`: 0 with none, N if set, by default 9 on a log axis and
   !< 0 on a linear one, else gnuplot's automatic count: 9 on a log axis, 2 when the leading digit of the step
   !< `mantissa` is 2, else 5.
   type(tics_object), intent(in) :: tics     !< Settings.
   integer(I8P),      intent(in) :: mantissa !< Step mantissa (any trailing zeros).
   logical,           intent(in) :: logaxis  !< Log axis.
   integer(I4P)                  :: n        !< Intervals, < 2 for none.
   integer(I8P)                  :: d        !< Leading digit.

   select case (tics%minor)
   case (MINOR_DEFAULT)
      ! by default none on linear axes, 9 intervals on log ones (the 2..9 of a decade on one-decade steps)
      n = merge(9_I4P, 0_I4P, logaxis)
   case (MINOR_NONE)
      n = 0_I4P
   case (MINOR_AUTO)
      if (logaxis) then
         n = 9_I4P
      else
         d = abs(mantissa)
         do while (d >= 10_I8P)
            d = d / 10_I8P
         enddo
         n = merge(2_I4P, 5_I4P, d == 2_I8P)
      endif
   case default
      n = tics%minor
   endselect
   endfunction minor_count

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

   pure subroutine list_ticks(tics, lo, hi, everywhere, ticks)
   !< The items of the explicit list of `tics` inside [`lo`, `hi`] (either order), or all of them if `everywhere`, in
   !< the list order: a label as written, by itself as the format if it is one (`"%.1f"`, gnuplot), the axis label of
   !< the position (`set format`, else the default one for the range) if absent; minor items have none.
   type(tics_object),              intent(in)  :: tics       !< Settings.
   real(R8P),                      intent(in)  :: lo         !< Value at the axis start.
   real(R8P),                      intent(in)  :: hi         !< Value at the axis end.
   logical,                        intent(in)  :: everywhere !< All the items, whatever the range.
   type(tick_object), allocatable, intent(out) :: ticks(:)   !< Ticks.
   type(tick_object)                           :: tick       !< Current tick.
   integer(I8P)                                :: n          !< Position mantissa.
   integer(I4P)                                :: e          !< Position exponent.
   integer(I4P)                                :: k          !< Item counter.
   logical                                     :: sci        !< Scientific default labels.

   allocate(ticks(0))
   if (.not. tics%has_list()) return
   sci = is_scientific(max(abs(lo), abs(hi)))
   do k = 1_I4P, size(tics%list, kind=I4P)
      associate(item => tics%list(k))
         ! the ends to 1e-9 of their magnitude: right on linear and log axes alike
         if (.not. everywhere .and. (item%value < min(lo, hi) - 1.0e-9_R8P * abs(min(lo, hi)) .or. &
                                     item%value > max(lo, hi) + 1.0e-9_R8P * abs(max(lo, hi)))) cycle
         tick%value = item%value
         tick%major = item%major
         tick%label = ''
         tick%sup = ''
         if (item%major) then
            call decimal_of(item%value, n, e)
            if (.not. item%labelled) then
               call tick_label(n, e, sci, tick%label, tick%sup, tics)
            elseif (index(item%label, '%') > 0 .and. len(format_check(item%label)) == 0) then
               call format_decimal(item%label, n, e, tick%label, tick%sup)
            else
               tick%label = item%label
            endif
         endif
      endassociate
      call push(ticks, tick)
   enddo
   endsubroutine list_ticks

   pure subroutine merge_list(tics, lo, hi, ticks)
   !< Add to `ticks` the items of the explicit list of `tics` inside [`lo`, `hi`], each replacing a tick at its position
   !< (gnuplot `set xtics add`): the remaining ticks keep their order, the items follow.
   type(tics_object),              intent(in)    :: tics     !< Settings.
   real(R8P),                      intent(in)    :: lo       !< Value at the axis start.
   real(R8P),                      intent(in)    :: hi       !< Value at the axis end.
   type(tick_object), allocatable, intent(inout) :: ticks(:) !< Ticks.
   type(tick_object), allocatable                :: items(:) !< List items in range.
   type(tick_object), allocatable                :: merged(:) !< Ticks not replaced, then the items.
   integer(I4P)                                  :: k        !< Tick counter.

   call list_ticks(tics, lo, hi, .false., items)
   if (size(items) == 0) return
   allocate(merged(0))
   do k = 1_I4P, size(ticks, kind=I4P)
      if (any(same_place(ticks(k)%value, items%value))) cycle
      call push(merged, ticks(k))
   enddo
   do k = 1_I4P, size(items, kind=I4P)
      call push(merged, items(k))
   enddo
   call move_alloc(merged, ticks)
   contains
      elemental function same_place(a, b) result(same)
      !< Whether `a` and `b` are one position, to 1e-9 of their magnitude (right on log axes too).
      real(R8P), intent(in) :: a    !< Value.
      real(R8P), intent(in) :: b    !< Value.
      logical               :: same !< Same position.

      same = abs(a - b) <= 1.0e-9_R8P * max(abs(a), abs(b))
      endfunction same_place
   endsubroutine merge_list

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
   call append_minors(ticks, first, step, .false., minor_count(tics, n(1), .false.), lo, hi, &
                      merge(first, -huge(1.0_R8P), has_start), merge(last, huge(1.0_R8P), has_end))
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
   call append_minors(ticks, first, factor, .true., minor_count(tics, n(1), .true.), lo, hi, &
                      merge(first, -huge(1.0_R8P), has_start), merge(last, huge(1.0_R8P), has_end))
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

   pure subroutine push_tick(list, item)
   !< Append `item` to `list` (an unallocated `list` is empty), through a temporary: see `push`.
   type(tick_object), allocatable, intent(inout) :: list(:)  !< List.
   type(tick_object),              intent(in)    :: item     !< New item.
   type(tick_object), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                  :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_tick

   pure subroutine push_item(list, item)
   !< Append `item` to `list` (an unallocated `list` is empty), through a temporary: see `push`.
   type(tic_item), allocatable, intent(inout) :: list(:)  !< List.
   type(tic_item),              intent(in)    :: item     !< New item.
   type(tic_item), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                               :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_item
endmodule foresight_ticks
