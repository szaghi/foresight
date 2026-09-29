!< foresight_ticks, axis tick placement and labelling.
module foresight_ticks
!< foresight_ticks, axis tick placement and labelling.
!<
!< Linear axes use the "nice numbers" rule (Heckbert, Graphics Gems, 1990): the step is rounded to `m * 10**e` with
!< `m` in {1, 2, 5}. Log axes place majors at integer decades. Tick values are carried as the integer pair (`n`, `e`)
!< meaning `n * 10**e`, so labels are exact decimal strings, free of floating point noise such as `0.30000000000000004`.
!<
!< The same rules will be mirrored by the interactive viewer, which must regenerate identical ticks after a zoom.
use penf, only : I4P, I8P, R8P
use foresight_format, only : decimal_str, int_str

implicit none
private
public :: linear_ticks
public :: log_ticks
public :: nice_step
public :: tick_object

type :: tick_object
   !< Axis tick.
   real(R8P)                     :: value = 0.0_R8P !< Data value.
   logical                       :: major = .true.  !< Major (labelled) tick, else minor.
   character(len=:), allocatable :: label           !< Label text, empty for minor ticks.
   character(len=:), allocatable :: sup             !< Superscript appended to the label, empty if none.
endtype tick_object

real(R8P), parameter :: TOL          = 1.0e-9_R8P !< Tolerance on tick-grid membership, in units of the step.
real(R8P), parameter :: TICK_SPACING = 50.0_R8P   !< Target distance between major ticks [px].
real(R8P), parameter :: SCI_HIGH     = 1.0e5_R8P  !< Labels switch to scientific notation from this magnitude...
real(R8P), parameter :: SCI_LOW      = 1.0e-3_R8P !< ...or below this one.

contains
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

   pure subroutine linear_ticks(lo, hi, npx, extend_lo, extend_hi, ticks)
   !< Major ticks of a linear axis `npx` pixels long; autoscaled ends are extended outward to the tick grid.
   real(R8P),                      intent(inout) :: lo        !< Value at the axis start (`lo > hi`: reversed axis).
   real(R8P),                      intent(inout) :: hi        !< Value at the axis end.
   real(R8P),                      intent(in)    :: npx       !< Axis length [px].
   logical,                        intent(in)    :: extend_lo !< Extend `lo` outward to the tick grid.
   logical,                        intent(in)    :: extend_hi !< Extend `hi` outward to the tick grid.
   type(tick_object), allocatable, intent(out)   :: ticks(:)  !< Ticks, ascending in value.
   real(R8P)                                     :: step      !< Tick step.
   integer(I8P)                                  :: m         !< Step mantissa.
   integer(I8P)                                  :: k         !< Tick index on the step grid.
   integer(I8P)                                  :: kmin      !< First tick index.
   integer(I8P)                                  :: kmax      !< Last tick index.
   integer(I4P)                                  :: e         !< Step exponent.
   logical                                       :: sci       !< Scientific labels.

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
   sci = is_scientific(max(abs(lo), abs(hi)))
   allocate(ticks(max(0_I8P, kmax - kmin + 1_I8P)))
   do k = kmin, kmax
      ticks(k - kmin + 1_I8P)%value = grid_value(k * m, e)
      call format_label(k * m, e, sci, ticks(k - kmin + 1_I8P)%label, ticks(k - kmin + 1_I8P)%sup)
   enddo
   endsubroutine linear_ticks

   pure subroutine log_ticks(lo, hi, npx, extend_lo, extend_hi, ticks)
   !< Ticks of a base-10 log axis `npx` pixels long; autoscaled ends are extended outward to whole decades.
   !<
   !< Majors sit at decades (labelled `10` with the exponent as superscript), minors at 2..9 times a decade when the
   !< axis spans at most 10 decades. With fewer than two decades in range the minors are labelled too, in plain decimals.
   real(R8P),                      intent(inout) :: lo        !< Value at the axis start, > 0.
   real(R8P),                      intent(inout) :: hi        !< Value at the axis end, > 0.
   real(R8P),                      intent(in)    :: npx       !< Axis length [px].
   logical,                        intent(in)    :: extend_lo !< Extend `lo` outward to a decade.
   logical,                        intent(in)    :: extend_hi !< Extend `hi` outward to a decade.
   type(tick_object), allocatable, intent(out)   :: ticks(:)  !< Ticks, majors first.
   type(tick_object)                             :: tick      !< Tick being built.
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

   if (lo <= hi) then
      if (extend_lo) lo = grid_value(1_I8P, floor(log10(lo) + TOL, I4P))
      if (extend_hi) hi = grid_value(1_I8P, ceiling(log10(hi) - TOL, I4P))
   else
      if (extend_lo) lo = grid_value(1_I8P, ceiling(log10(lo) - TOL, I4P))
      if (extend_hi) hi = grid_value(1_I8P, floor(log10(hi) + TOL, I4P))
   endif
   ta = log10(min(lo, hi))
   tb = log10(max(lo, hi))
   call nice_step((tb - ta) / max(2.0_R8P, npx / TICK_SPACING), m, e)
   s = 1_I8P
   if (e >= 0_I4P) s = m * 10_I8P**e
   kmin = ceiling(ta - TOL, I8P)
   kmax = floor(tb + TOL, I8P)
   plain = count([(modulo(k, s) == 0_I8P, k = kmin, kmax)]) < 2

   allocate(ticks(0))
   do k = kmin, kmax
      if (modulo(k, s) /= 0_I8P) cycle
      tick%value = grid_value(1_I8P, int(k, I4P))
      tick%major = .true.
      if (plain) then
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
            if (plain) then
               tick%label = decimal_str(d, int(-k, I4P))
            else
               tick%label = ''
            endif
            ticks = [ticks, tick]
         enddo
      enddo
   endif
   endsubroutine log_ticks

   ! private procedures
   pure function grid_value(n, e) result(value)
   !< Value `n * 10**e`, correctly rounded for `|e| <= 22` (powers of ten are exact there).
   integer(I8P), intent(in) :: n     !< Mantissa.
   integer(I4P), intent(in) :: e     !< Exponent.
   real(R8P)                :: value !< Value.

   if (e >= 0_I4P) then
      value = real(n, R8P) * 10.0_R8P**e
   else
      value = real(n, R8P) / 10.0_R8P**(-e)
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
