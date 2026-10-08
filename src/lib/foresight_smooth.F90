!< foresight_smooth, gnuplot `smooth` filters of a data series.
module foresight_smooth
!< foresight_smooth, gnuplot `smooth` filters of a data series.
!<
!< The filters gnuplot computes from the data alone, without a fit: each run of placeable points (a block of the data
!< file, broken by undefined points and by points not placeable on a log axis) is sorted by x, stably, and its points
!< of equal x are merged into one:
!<
!< - `unique`: the mean of their y;
!< - `frequency`: the sum of their y; `fnormal` divided by the sum of y over every run;
!< - `cumulative`: the sum of y up to that x within the run; `cnormal` divided by the sum of y over every run.
!<
!< Runs stay separate, joined by an undefined (NaN) point that breaks the line, as gnuplot draws them.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite, ieee_quiet_nan, ieee_value
use penf, only : I4P, R8P

implicit none
private
public :: smooth
public :: SMOOTH_MODES

character(len=*), parameter :: SMOOTH_MODES = 'unique frequency fnormal cumulative cnormal' !< Supported filters.

contains
   subroutine smooth(mode, x, y, xlog, ylog, xs, ys)
   !< Filter the series (`x`, `y`) with the `smooth` `mode` (one of `SMOOTH_MODES`) into (`xs`, `ys`); `xlog`, `ylog`
   !< tell the log axes, on which non-positive values are not placeable.
   character(len=*),       intent(in)  :: mode     !< Filter.
   real(R8P),              intent(in)  :: x(:)     !< Abscissae.
   real(R8P),              intent(in)  :: y(:)     !< Ordinates.
   logical,                intent(in)  :: xlog     !< Log x axis.
   logical,                intent(in)  :: ylog     !< Log y axis.
   real(R8P), allocatable, intent(out) :: xs(:)    !< Filtered abscissae.
   real(R8P), allocatable, intent(out) :: ys(:)    !< Filtered ordinates.
   logical,   allocatable              :: ok(:)    !< Placeable points.
   integer(I4P), allocatable           :: order(:) !< Run points sorted by x.
   real(R8P)                           :: total    !< Sum of y over every run.
   real(R8P)                           :: acc      !< Running sum within a run.
   real(R8P)                           :: gsum     !< Sum of y over a group of equal x.
   integer(I4P)                        :: n        !< Output points.
   integer(I4P)                        :: first    !< Run start.
   integer(I4P)                        :: last     !< Run end.
   integer(I4P)                        :: k        !< Group start in `order`.
   integer(I4P)                        :: g        !< Group end in `order`.

   ok = placeable(x, xlog) .and. placeable(y, ylog)
   total = sum(y, mask=ok)
   ! at most the points and a separator between two runs
   allocate(xs(2 * size(x)), ys(2 * size(x)))
   n = 0_I4P
   first = 1_I4P
   do while (first <= size(x, kind=I4P))
      if (.not. ok(first)) then
         first = first + 1_I4P
         cycle
      endif
      last = first
      do while (last < size(x, kind=I4P))
         if (.not. ok(last + 1_I4P)) exit
         last = last + 1_I4P
      enddo
      if (n > 0_I4P) call append(ieee_value(1.0_R8P, ieee_quiet_nan), ieee_value(1.0_R8P, ieee_quiet_nan))
      order = first - 1_I4P + sorted(x(first:last))
      acc = 0.0_R8P
      k = 1_I4P
      do while (k <= size(order, kind=I4P))
         g = k
         do while (g < size(order, kind=I4P))
            if (x(order(g + 1_I4P)) /= x(order(k))) exit
            g = g + 1_I4P
         enddo
         gsum = sum(y(order(k:g)))
         acc = acc + gsum
         select case (mode)
         case ('unique')
            call append(x(order(k)), gsum / real(g - k + 1_I4P, R8P))
         case ('frequency')
            call append(x(order(k)), gsum)
         case ('fnormal')
            call append(x(order(k)), normal(gsum))
         case ('cumulative')
            call append(x(order(k)), acc)
         case default
            call append(x(order(k)), normal(acc))
         endselect
         k = g + 1_I4P
      enddo
      first = last + 1_I4P
   enddo
   xs = xs(1:n)
   ys = ys(1:n)
   contains
      subroutine append(a, b)
      !< Append the point (`a`, `b`).
      real(R8P), intent(in) :: a !< Abscissa.
      real(R8P), intent(in) :: b !< Ordinate.

      n = n + 1_I4P
      xs(n) = a
      ys(n) = b
      endsubroutine append

      function normal(value) result(fraction)
      !< `value` over the total, undefined for a zero total.
      real(R8P), intent(in) :: value    !< Value.
      real(R8P)             :: fraction !< Fraction of the total.

      if (total == 0.0_R8P) then
         fraction = ieee_value(1.0_R8P, ieee_quiet_nan)
      else
         fraction = value / total
      endif
      endfunction normal
   endsubroutine smooth

   elemental function placeable(v, log) result(ok)
   !< Whether `v` is placeable on an axis: finite, and positive on a log axis (as foresight_axis%accepts).
   real(R8P), intent(in) :: v   !< Value.
   logical,   intent(in) :: log !< Log axis.
   logical               :: ok  !< Placeable.

   ok = ieee_is_finite(v)
   if (ok .and. log) ok = v > 0.0_R8P
   endfunction placeable

   pure function sorted(keys) result(order)
   !< Permutation sorting `keys` ascending, stable (equal keys keep their order): bottom-up merge sort.
   real(R8P), intent(in)     :: keys(:)   !< Keys, no NaN.
   integer(I4P), allocatable :: order(:)  !< Sorted positions.
   integer(I4P), allocatable :: merged(:) !< Merge buffer.
   integer(I4P)              :: n         !< Keys.
   integer(I4P)              :: width     !< Sorted run width.
   integer(I4P)              :: lo        !< Left run start.
   integer(I4P)              :: mid       !< Left run end.
   integer(I4P)              :: hi        !< Right run end.
   integer(I4P)              :: a         !< Left run counter.
   integer(I4P)              :: b         !< Right run counter.
   integer(I4P)              :: k         !< Merged counter.
   integer(I4P)              :: i         !< Counter.

   n = size(keys, kind=I4P)
   order = [(i, i = 1_I4P, n)]
   allocate(merged(n))
   width = 1_I4P
   do while (width < n)
      lo = 1_I4P
      do while (lo <= n)
         mid = min(lo + width - 1_I4P, n)
         hi = min(lo + 2_I4P * width - 1_I4P, n)
         a = lo
         b = mid + 1_I4P
         do k = lo, hi
            ! the left run wins ties: stable
            if (b > hi) then
               merged(k) = order(a)
               a = a + 1_I4P
            elseif (a > mid) then
               merged(k) = order(b)
               b = b + 1_I4P
            elseif (keys(order(b)) < keys(order(a))) then
               merged(k) = order(b)
               b = b + 1_I4P
            else
               merged(k) = order(a)
               a = a + 1_I4P
            endif
         enddo
         lo = hi + 1_I4P
      enddo
      order = merged
      width = 2_I4P * width
   enddo
   endfunction sorted
endmodule foresight_smooth
