!< foresight_axis, a plot axis: user settings and the derived effective range and ticks.
module foresight_axis
!< foresight_axis, a plot axis: user settings and the derived effective range and ticks.
!<
!< Range semantics follow gnuplot `set xrange [min:max]`: `min` is the value at the axis start and `max` at its end
!< (`min > max` reverses the axis); an unset end is autoscaled to the data and extended outward to the tick grid.
!<
!< Text labels from the data (`using ...:xtic(1)`), when any, replace the ticks, as gnuplot: a tick at each labelled
!< value inside the range, the range itself not extended. They are derived per rendering (`labels`), never stored in
!< the user settings `tics`, so a multiplot does not carry the categories of a panel into the next one.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite
use penf, only : R8P
use foresight_ticks, only : linear_ticks, list_ticks, log_ticks, merge_list, tick_object, tics_object, time_ticks, TICS_NONE

implicit none
private
public :: axis_object

type :: axis_object
   !< Plot axis.
   logical                        :: has_data  = .false.    !< Data placed on the axis, set by `setup`.
   logical                        :: noextend  = .false.    !< Autoscaled ends not extended to the ticks, set by the
                                                            !< user (gnuplot `set autoscale noextend`, `fix`).
   real(R8P)                      :: data_lo   = 0.0_R8P    !< Smallest data value placed, set by `setup`.
   real(R8P)                      :: data_hi   = 0.0_R8P    !< Largest data value placed, set by `setup`.
   real(R8P)                      :: offset(2) = 0.0_R8P    !< Autoscaled ends moved out, start and end (gnuplot
                                                            !< `set offsets`): in axis units, or graph fractions.
   logical                        :: offset_graph(2) = .false. !< `offset` in graph fractions of the autoscaled range.
   character(len=:), allocatable  :: label                  !< Axis label, empty for none.
   logical                        :: log       = .false.    !< Base-10 logarithmic scale.
   logical                        :: min_fixed = .false.    !< Axis start set by the user, else autoscaled.
   logical                        :: max_fixed = .false.    !< Axis end set by the user, else autoscaled.
   real(R8P)                      :: min_user  = 0.0_R8P    !< User value at the axis start.
   real(R8P)                      :: max_user  = 0.0_R8P    !< User value at the axis end.
   logical                        :: plot_min_fixed = .false. !< Axis start of the current plot, over the user one,
                                                              !< gnuplot `plot [min:max]`.
   logical                        :: plot_max_fixed = .false. !< Axis end of the current plot, over the user one.
   real(R8P)                      :: plot_min  = 0.0_R8P    !< Value at the axis start of the current plot.
   real(R8P)                      :: plot_max  = 0.0_R8P    !< Value at the axis end of the current plot.
   real(R8P)                      :: lo        = -10.0_R8P  !< Effective value at the axis start, set by `setup`.
   real(R8P)                      :: hi        = 10.0_R8P   !< Effective value at the axis end, set by `setup`.
   type(tics_object)              :: tics                   !< User tick settings: fixed step, none, label format.
   logical                        :: time      = .false.    !< Time values (seconds since 1970): time ticks and labels,
                                                            !< gnuplot `set xdata time`.
   character(len=:), allocatable  :: timefmt                !< Input time format, the day and month order of the
                                                            !< invented labels (gnuplot `set timefmt`).
   logical                        :: tight     = .false.    !< Autoscaled ends not extended to the ticks (images,
                                                            !< the color axis), as gnuplot.
   type(tick_object), allocatable :: ticks(:)               !< Ticks, set by `setup`.
   type(tick_object), allocatable :: labels(:)              !< Text labels from the data, by value; none if unallocated
                                                            !< or empty.
   logical                        :: reverse   = .false.    !< Reversed when an end is autoscaled (gnuplot `set xrange
                                                             !< reverse`).
   contains
      procedure, pass(self) :: accepts   !< Whether a value can be placed on the axis.
      procedure, pass(self) :: has_label !< Whether the axis has a label.
      procedure, pass(self) :: labelled  !< Whether text labels from the data replace the ticks.
      procedure, pass(self) :: range_of  !< Range before the tick extension.
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

   pure function labelled(self) result(yes)
   !< Whether text labels from the data replace the ticks: some are set and the ticks are not turned off.
   class(axis_object), intent(in) :: self !< Axis.
   logical                        :: yes  !< Labelled axis.

   yes = .false.
   if (allocated(self%labels)) yes = size(self%labels) > 0 .and. self%tics%mode /= TICS_NONE
   endfunction labelled

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

   pure subroutine range_of(self, dmin, dmax, has_data, lo, hi)
   !< Values at the axis start and end from the data extent and the user ends, before the extension to the ticks: the
   !< range functions are sampled on, as gnuplot.
   !<
   !< A degenerate range is widened by 1% (gnuplot "empty range" behaviour); with no data the range defaults to
   !< [-10:10], or [1:10] on a log axis.
   class(axis_object), intent(in)  :: self     !< Axis.
   real(R8P),          intent(in)  :: dmin     !< Smallest placeable data value.
   real(R8P),          intent(in)  :: dmax     !< Largest placeable data value.
   logical,            intent(in)  :: has_data !< Whether `dmin`/`dmax` are meaningful.
   real(R8P),          intent(out) :: lo       !< Value at the axis start.
   real(R8P),          intent(out) :: hi       !< Value at the axis end.

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
   ! a range of the plot command overrides the set one, for that plot
   if (self%plot_min_fixed) lo = self%plot_min
   if (self%plot_max_fixed) hi = self%plot_max
   associate(min_fixed => self%min_fixed .or. self%plot_min_fixed, max_fixed => self%max_fixed .or. self%plot_max_fixed)
      if (lo == hi .and. .not. (min_fixed .and. max_fixed)) then
         if (self%log) then
            if (.not. min_fixed) lo = lo * 0.99_R8P
            if (.not. max_fixed) hi = hi * 1.01_R8P
         elseif (lo == 0.0_R8P) then
            if (.not. min_fixed) lo = -1.0_R8P
            if (.not. max_fixed) hi = 1.0_R8P
         else
            if (.not. min_fixed) lo = lo - 0.01_R8P * abs(lo)
            if (.not. max_fixed) hi = hi + 0.01_R8P * abs(hi)
         endif
      endif
   endassociate
   endsubroutine range_of

   subroutine setup(self, dmin, dmax, has_data, npx)
   !< Compute the effective range (`range_of`) and the ticks from the data extent and the axis length.
   class(axis_object), intent(inout) :: self     !< Axis.
   real(R8P),          intent(in)    :: dmin     !< Smallest placeable data value.
   real(R8P),          intent(in)    :: dmax     !< Largest placeable data value.
   logical,            intent(in)    :: has_data !< Whether `dmin`/`dmax` are meaningful.
   real(R8P),          intent(in)    :: npx      !< Axis length [px].
   real(R8P)                         :: lo       !< Value at the axis start.
   real(R8P)                         :: hi       !< Value at the axis end.

   call self%range_of(dmin, dmax, has_data, lo, hi)
   ! gnuplot `set offsets`: the autoscaled ends moved out (functions are sampled on the range before), by axis units
   ! or by fractions of the range (on a log axis in decades, graph fractions only)
   if (any(self%offset /= 0.0_R8P)) call offsets(lo, hi)
   self%has_data = has_data
   self%data_lo = min(dmin, dmax)
   self%data_hi = max(dmin, dmax)
   if (self%log .and. (lo <= 0.0_R8P .or. hi <= 0.0_R8P)) error stop 'foresight: log scale needs a positive range'
   if (lo == hi) error stop 'foresight: empty axis range'
   if (self%labelled()) then
      self%ticks = pack(self%labels, self%labels%value >= min(lo, hi) .and. self%labels%value <= max(lo, hi))
   elseif (.not. self%tics%series .and. self%tics%mode /= TICS_NONE) then
      ! an explicit list alone: the range is not extended to a tick grid, as gnuplot
      call list_ticks(self%tics, lo, hi, .false., self%ticks)
   elseif (self%time .and. .not. self%log) then
      if (.not. allocated(self%timefmt)) self%timefmt = '%d/%m/%y,%H:%M'
      call time_ticks(lo, hi, .not. (self%min_fixed .or. self%plot_min_fixed .or. self%tight), &
                      .not. (self%max_fixed .or. self%plot_max_fixed .or. self%tight), self%ticks, self%tics, &
                      self%timefmt)
   elseif (self%log) then
      call log_ticks(lo, hi, npx, .not. (self%min_fixed .or. self%plot_min_fixed .or. self%tight), &
                     .not. (self%max_fixed .or. self%plot_max_fixed .or. self%tight), &
                     self%ticks, self%tics)
   else
      call linear_ticks(lo, hi, npx, .not. (self%min_fixed .or. self%plot_min_fixed .or. self%tight), &
                        .not. (self%max_fixed .or. self%plot_max_fixed .or. self%tight), &
                        self%ticks, self%tics)
   endif
   ! a list added to the ticks, after the extension of the range
   if (.not. self%labelled() .and. self%tics%series .and. self%tics%mode /= TICS_NONE) &
      call merge_list(self%tics, lo, hi, self%ticks)
   ! gnuplot `reverse`: an axis with an autoscaled end runs from its largest value (axis_invert_if_requested)
   if (self%reverse .and. .not. ((self%min_fixed .or. self%plot_min_fixed) .and. (self%max_fixed .or. &
       self%plot_max_fixed)) .and. lo < hi) then
      self%lo = hi
      self%hi = lo
      return
   endif
   self%lo = lo
   self%hi = hi
   contains
      pure subroutine offsets(lo, hi)
      !< `lo` and `hi` moved out by the offsets.
      real(R8P), intent(inout) :: lo   !< Start.
      real(R8P), intent(inout) :: hi   !< End.
      real(R8P)                :: span !< Range, before the offsets.
      real(R8P)                :: d(2) !< Moves, out.
      real(R8P)                :: a    !< Start before.

      a = lo
      if (self%log) then
         if (lo <= 0.0_R8P .or. hi <= 0.0_R8P) return
         span = log10(hi) - log10(lo)
         d = merge(self%offset * span, 0.0_R8P, self%offset_graph)
         if (.not. (self%min_fixed .or. self%plot_min_fixed)) lo = lo / 10.0_R8P**min(300.0_R8P, d(1))
         if (.not. (self%max_fixed .or. self%plot_max_fixed)) hi = hi * 10.0_R8P**min(300.0_R8P, d(2))
      else
         span = hi - lo
         d = merge(self%offset * span, self%offset, self%offset_graph)
         if (.not. (self%min_fixed .or. self%plot_min_fixed)) lo = a - d(1)
         if (.not. (self%max_fixed .or. self%plot_max_fixed)) hi = hi + d(2)
      endif
      endsubroutine offsets
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
