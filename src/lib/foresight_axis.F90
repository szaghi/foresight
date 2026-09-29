!< foresight_axis, a plot axis: user settings and the derived effective range and ticks.
module foresight_axis
!< foresight_axis, a plot axis: user settings and the derived effective range and ticks.
!<
!< Range semantics follow gnuplot `set xrange [min:max]`: `min` is the value at the axis start and `max` at its end
!< (`min > max` reverses the axis); an unset end is autoscaled to the data and extended outward to the tick grid.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite
use penf, only : R8P
use foresight_ticks, only : linear_ticks, log_ticks, tick_object

implicit none
private
public :: axis_object

type :: axis_object
   !< Plot axis.
   character(len=:), allocatable  :: label                  !< Axis label, empty for none.
   logical                        :: log       = .false.    !< Base-10 logarithmic scale.
   logical                        :: min_fixed = .false.    !< Axis start set by the user, else autoscaled.
   logical                        :: max_fixed = .false.    !< Axis end set by the user, else autoscaled.
   real(R8P)                      :: min_user  = 0.0_R8P    !< User value at the axis start.
   real(R8P)                      :: max_user  = 0.0_R8P    !< User value at the axis end.
   real(R8P)                      :: lo        = -10.0_R8P  !< Effective value at the axis start, set by `setup`.
   real(R8P)                      :: hi        = 10.0_R8P   !< Effective value at the axis end, set by `setup`.
   type(tick_object), allocatable :: ticks(:)               !< Ticks, set by `setup`.
   contains
      procedure, pass(self) :: accepts   !< Whether a value can be placed on the axis.
      procedure, pass(self) :: has_label !< Whether the axis has a label.
      procedure, pass(self) :: set_range !< Set the range, gnuplot style.
      procedure, pass(self) :: setup     !< Compute effective range and ticks.
      procedure, pass(self) :: to_unit   !< Map a value to the unit interval.
endtype axis_object

contains
   elemental function accepts(self, v) result(ok)
   !< Whether `v` can be placed on the axis: finite, and positive on a log axis.
   class(axis_object), intent(in) :: self !< Axis.
   real(R8P),          intent(in) :: v    !< Value.
   logical                        :: ok   !< `v` is placeable.

   ok = ieee_is_finite(v)
   if (ok .and. self%log) ok = v > 0.0_R8P
   endfunction accepts

   pure function has_label(self) result(has)
   !< Whether the axis has a non-empty label.
   class(axis_object), intent(in) :: self !< Axis.
   logical                        :: has  !< The label is set.

   has = .false.
   if (allocated(self%label)) has = len(self%label) > 0
   endfunction has_label

   pure subroutine set_range(self, min, max)
   !< Set the range as gnuplot `set xrange [min:max]`: an absent end is autoscaled.
   class(axis_object), intent(inout)        :: self !< Axis.
   real(R8P),          intent(in), optional :: min  !< Value at the axis start.
   real(R8P),          intent(in), optional :: max  !< Value at the axis end.

   self%min_fixed = present(min)
   if (present(min)) self%min_user = min
   self%max_fixed = present(max)
   if (present(max)) self%max_user = max
   endsubroutine set_range

   subroutine setup(self, dmin, dmax, has_data, npx)
   !< Compute the effective range and the ticks from the data extent and the axis length.
   !<
   !< A degenerate range is widened by 1% (gnuplot "empty range" behaviour); with no data the range defaults to
   !< [-10:10], or [1:10] on a log axis.
   class(axis_object), intent(inout) :: self     !< Axis.
   real(R8P),          intent(in)    :: dmin     !< Smallest placeable data value.
   real(R8P),          intent(in)    :: dmax     !< Largest placeable data value.
   logical,            intent(in)    :: has_data !< Whether `dmin`/`dmax` are meaningful.
   real(R8P),          intent(in)    :: npx      !< Axis length [px].
   real(R8P)                         :: lo       !< Value at the axis start.
   real(R8P)                         :: hi       !< Value at the axis end.

   if (has_data) then
      lo = dmin
      hi = dmax
   elseif (self%log) then
      lo = 1.0_R8P
      hi = 10.0_R8P
   else
      lo = -10.0_R8P
      hi = 10.0_R8P
   endif
   if (self%min_fixed) lo = self%min_user
   if (self%max_fixed) hi = self%max_user
   if (self%log .and. (lo <= 0.0_R8P .or. hi <= 0.0_R8P)) error stop 'foresight: log scale needs a positive range'
   if (lo == hi) then
      if (self%min_fixed .and. self%max_fixed) error stop 'foresight: empty axis range'
      if (self%log) then
         if (.not. self%min_fixed) lo = lo * 0.99_R8P
         if (.not. self%max_fixed) hi = hi * 1.01_R8P
      elseif (lo == 0.0_R8P) then
         if (.not. self%min_fixed) lo = -1.0_R8P
         if (.not. self%max_fixed) hi = 1.0_R8P
      else
         if (.not. self%min_fixed) lo = lo - 0.01_R8P * abs(lo)
         if (.not. self%max_fixed) hi = hi + 0.01_R8P * abs(hi)
      endif
   endif
   if (self%log) then
      call log_ticks(lo, hi, npx, .not. self%min_fixed, .not. self%max_fixed, self%ticks)
   else
      call linear_ticks(lo, hi, npx, .not. self%min_fixed, .not. self%max_fixed, self%ticks)
   endif
   self%lo = lo
   self%hi = hi
   endsubroutine setup

   elemental function to_unit(self, v) result(u)
   !< Map the placeable value `v` to the axis unit interval: 0 at the axis start, 1 at its end.
   class(axis_object), intent(in) :: self !< Axis.
   real(R8P),          intent(in) :: v    !< Value.
   real(R8P)                      :: u    !< Unit coordinate.

   if (self%log) then
      u = (log10(v) - log10(self%lo)) / (log10(self%hi) - log10(self%lo))
   else
      u = (v - self%lo) / (self%hi - self%lo)
   endif
   endfunction to_unit
endmodule foresight_axis
