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
!<
!< The curves (`smooth_curve`) are sampled at `set samples` points: the natural cubic spline (`csplines`), the smoothing
!< spline of Reinsch (`acsplines`, weights from a third column), the Bezier curve of the points (`bezier`, in the file
!< order; `sbezier` sorted and merged) and the Gaussian kernel density estimate (`kdensity`), as gnuplot 6.0.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite, ieee_quiet_nan, ieee_value
use penf, only : I4P, R8P

implicit none
private
public :: smooth
public :: smooth_curve
public :: CURVE_MODES
public :: SMOOTH_MODES

character(len=*), parameter :: SMOOTH_MODES = 'unique frequency fnormal cumulative cnormal' !< Filters of `smooth`.
character(len=*), parameter :: CURVE_MODES = 'csplines acsplines bezier sbezier kdensity' !< Filters of `smooth_curve`.

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

   subroutine smooth_curve(mode, x, y, w, samples, lo, hi, bandwidth, xlog, ylog, xs, ys, message)
   !< Smooth the series (`x`, `y`) with the `mode` of `CURVE_MODES`, `samples` points per run, as gnuplot:
   !<
   !< - `csplines`: the natural cubic spline through the points sorted by x, those of equal x merged into their mean;
   !< - `acsplines`: the smoothing (approximation) spline of Reinsch, the weights `w` (larger: closer to the points);
   !< - `bezier`: the Bezier curve with the points as control points, in the file order; `sbezier` after sorting and
   !<   merging them;
   !< - `kdensity`: the Gaussian kernel density estimate of the x values weighted by y, over [`lo`, `hi`], of
   !<   `bandwidth` (gnuplot's default, (4/3n)^(1/5) times the standard deviation of x, if not positive).
   !<
   !< The splines are sampled over the run, within [`lo`, `hi`]; runs are joined by an undefined point. `message` is
   !< empty on success.
   character(len=*),              intent(in)  :: mode      !< Filter.
   real(R8P),                     intent(in)  :: x(:)      !< Abscissae.
   real(R8P),                     intent(in)  :: y(:)      !< Ordinates.
   real(R8P),                     intent(in)  :: w(:)      !< Weights (acsplines).
   integer(I4P),                  intent(in)  :: samples   !< Points per run.
   real(R8P),                     intent(in)  :: lo        !< Smallest abscissa sampled.
   real(R8P),                     intent(in)  :: hi        !< Largest abscissa sampled.
   real(R8P),                     intent(in)  :: bandwidth !< kdensity bandwidth, default if not positive.
   logical,                       intent(in)  :: xlog      !< Log x axis.
   logical,                       intent(in)  :: ylog      !< Log y axis.
   real(R8P), allocatable,        intent(out) :: xs(:)     !< Smoothed abscissae.
   real(R8P), allocatable,        intent(out) :: ys(:)     !< Smoothed ordinates.
   character(len=:), allocatable, intent(out) :: message   !< Problem, empty if none.
   real(R8P), allocatable                     :: rx(:)     !< Run abscissae.
   real(R8P), allocatable                     :: ry(:)     !< Run ordinates.
   real(R8P), allocatable                     :: rw(:)     !< Run weights.
   logical,   allocatable                     :: ok(:)     !< Placeable points.
   integer(I4P)                               :: n         !< Output points.
   integer(I4P)                               :: first     !< Run start.
   integer(I4P)                               :: last      !< Run end.

   message = ''
   ok = placeable(x, xlog) .and. placeable(y, ylog)
   allocate(xs(0), ys(0))
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
      rx = x(first:last)
      ry = y(first:last)
      rw = w(first:last)
      if (mode /= 'bezier' .and. mode /= 'kdensity') call merge_equal(rx, ry, rw)
      if (size(xs) > 0) call append([ieee_value(1.0_R8P, ieee_quiet_nan)], [ieee_value(1.0_R8P, ieee_quiet_nan)])
      select case (mode)
      case ('csplines')
         if (size(rx) < 3) then
            message = 'csplines need at least 3 points of distinct x'
            return
         endif
         call spline_samples(rx, natural_spline(rx, ry))
      case ('acsplines')
         if (size(rx) < 4) then
            message = 'acsplines need at least 4 points of distinct x'
            return
         endif
         if (any(.not. (rw > 0.0_R8P))) then
            message = 'acsplines need positive weights'
            return
         endif
         call spline_samples(rx, approximation_spline(rx, ry, rw))
      case ('bezier', 'sbezier')
         call bezier_samples(rx, ry)
      case default
         call kdensity_samples(rx, ry)
      endselect
      first = last + 1_I4P
   enddo
   contains
      subroutine append(a, b)
      !< Append the points (`a`, `b`), through temporaries (see foresight_tokens push).
      real(R8P), intent(in)  :: a(:)  !< Abscissae.
      real(R8P), intent(in)  :: b(:)  !< Ordinates.
      real(R8P), allocatable :: t(:)  !< Grown array.

      allocate(t(n + size(a)))
      t(1:n) = xs(1:n)
      t(n + 1:) = a
      call move_alloc(t, xs)
      allocate(t(n + size(b)))
      t(1:n) = ys(1:n)
      t(n + 1:) = b
      call move_alloc(t, ys)
      n = n + size(a, kind=I4P)
      endsubroutine append

      subroutine spline_samples(knots, c)
      !< Sample the cubic spline of coefficients `c(0:3, i)` on the intervals of `knots` (`c(0, i) + c(1, i) t +
      !< c(2, i) t**2 + c(3, i) t**3`, t from knots(i)), `samples` points over the knots within [lo, hi].
      real(R8P), intent(in)  :: knots(:) !< Spline knots, increasing.
      real(R8P), intent(in)  :: c(0:, :) !< Coefficients by interval.
      real(R8P), allocatable :: px(:)    !< Sampled abscissae.
      real(R8P), allocatable :: py(:)    !< Sampled ordinates.
      real(R8P)              :: a        !< Sampled start.
      real(R8P)              :: b        !< Sampled end.
      real(R8P)              :: t        !< Offset in the interval.
      integer(I4P)           :: i        !< Sample counter.
      integer(I4P)           :: l        !< Interval.

      a = max(knots(1), min(lo, hi))
      b = min(knots(size(knots)), max(lo, hi))
      if (.not. a < b) return
      allocate(px(samples), py(samples))
      l = 1_I4P
      do i = 1_I4P, samples
         px(i) = a + real(i - 1_I4P, R8P) * (b - a) / real(max(1_I4P, samples - 1_I4P), R8P)
         do while (l < size(knots, kind=I4P) - 1_I4P)
            if (px(i) < knots(l + 1_I4P)) exit
            l = l + 1_I4P
         enddo
         t = px(i) - knots(l)
         py(i) = ((c(3, l) * t + c(2, l)) * t + c(1, l)) * t + c(0, l)
      enddo
      call append(px, py)
      endsubroutine spline_samples

      subroutine bezier_samples(cx, cy)
      !< Sample the Bezier curve of control points (`cx`, `cy`) at `samples` evenly spaced parameters: the Bernstein
      !< weights through logarithms, finite for thousands of points.
      real(R8P), intent(in)  :: cx(:)  !< Control abscissae.
      real(R8P), intent(in)  :: cy(:)  !< Control ordinates.
      real(R8P), allocatable :: px(:)  !< Sampled abscissae.
      real(R8P), allocatable :: py(:)  !< Sampled ordinates.
      real(R8P), allocatable :: lnc(:) !< Logarithms of the binomial coefficients.
      real(R8P)              :: t      !< Curve parameter.
      real(R8P)              :: b      !< Bernstein weight.
      integer(I4P)           :: m      !< Degree.
      integer(I4P)           :: i      !< Sample counter.
      integer(I4P)           :: k      !< Control point counter.

      m = size(cx, kind=I4P) - 1_I4P
      allocate(px(samples), py(samples))
      lnc = [(log_gamma(real(m + 1_I4P, R8P)) - log_gamma(real(k + 1_I4P, R8P)) - log_gamma(real(m - k + 1_I4P, R8P)), &
              k = 0_I4P, m)]
      do i = 1_I4P, samples
         t = real(i - 1_I4P, R8P) / real(max(1_I4P, samples - 1_I4P), R8P)
         if (m == 0_I4P .or. t == 0.0_R8P) then
            px(i) = cx(1)
            py(i) = cy(1)
            cycle
         elseif (t == 1.0_R8P) then
            px(i) = cx(m + 1_I4P)
            py(i) = cy(m + 1_I4P)
            cycle
         endif
         px(i) = 0.0_R8P
         py(i) = 0.0_R8P
         do k = 0_I4P, m
            b = exp(lnc(k + 1_I4P) + real(k, R8P) * log(t) + real(m - k, R8P) * log(1.0_R8P - t))
            px(i) = px(i) + b * cx(k + 1_I4P)
            py(i) = py(i) + b * cy(k + 1_I4P)
         enddo
      enddo
      call append(px, py)
      endsubroutine bezier_samples

      subroutine kdensity_samples(cx, cy)
      !< Sample the Gaussian kernel density of the abscissae `cx` weighted by `cy` over [lo, hi].
      real(R8P), intent(in)  :: cx(:) !< Abscissae.
      real(R8P), intent(in)  :: cy(:) !< Weights.
      real(R8P), allocatable :: px(:) !< Sampled abscissae.
      real(R8P), allocatable :: py(:) !< Sampled densities.
      real(R8P)              :: h     !< Bandwidth.
      real(R8P)              :: mean  !< Mean of the abscissae.
      real(R8P)              :: sigma !< Standard deviation of the abscissae (population).
      integer(I4P)           :: i     !< Sample counter.

      h = bandwidth
      if (.not. h > 0.0_R8P) then
         mean = sum(cx) / real(size(cx), R8P)
         sigma = sqrt(max(0.0_R8P, sum(cx**2) / real(size(cx), R8P) - mean**2))
         h = (4.0_R8P / (3.0_R8P * real(size(cx), R8P)))**0.2_R8P * sigma
      endif
      if (.not. h > 0.0_R8P) then
         message = 'kdensity needs a positive bandwidth (the x values are all equal)'
         return
      endif
      allocate(px(samples), py(samples))
      do i = 1_I4P, samples
         px(i) = lo + real(i - 1_I4P, R8P) * (hi - lo) / real(max(1_I4P, samples - 1_I4P), R8P)
         py(i) = sum(cy * exp(-0.5_R8P * ((px(i) - cx) / h)**2)) / (h * sqrt(2.0_R8P * acos(-1.0_R8P)))
      enddo
      call append(px, py)
      endsubroutine kdensity_samples
   endsubroutine smooth_curve

   pure subroutine merge_equal(x, y, w)
   !< Sort the points by x, stably, and merge those of equal x into one, the mean of their y and weights (gnuplot's
   !< preparation of the splines and of sbezier).
   real(R8P), allocatable, intent(inout) :: x(:)     !< Abscissae.
   real(R8P), allocatable, intent(inout) :: y(:)     !< Ordinates.
   real(R8P), allocatable, intent(inout) :: w(:)     !< Weights.
   real(R8P), allocatable                :: mx(:)    !< Merged abscissae.
   real(R8P), allocatable                :: my(:)    !< Merged ordinates.
   real(R8P), allocatable                :: mw(:)    !< Merged weights.
   integer(I4P), allocatable             :: order(:) !< Sorted positions.
   integer(I4P)                          :: n        !< Merged points.
   integer(I4P)                          :: k        !< Group start.
   integer(I4P)                          :: g        !< Group end.

   order = sorted(x)
   allocate(mx(size(x)), my(size(x)), mw(size(x)))
   n = 0_I4P
   k = 1_I4P
   do while (k <= size(order, kind=I4P))
      g = k
      do while (g < size(order, kind=I4P))
         if (x(order(g + 1_I4P)) /= x(order(k))) exit
         g = g + 1_I4P
      enddo
      n = n + 1_I4P
      mx(n) = x(order(k))
      my(n) = sum(y(order(k:g))) / real(g - k + 1_I4P, R8P)
      mw(n) = sum(w(order(k:g))) / real(g - k + 1_I4P, R8P)
      k = g + 1_I4P
   enddo
   x = mx(1:n)
   y = my(1:n)
   w = mw(1:n)
   endsubroutine merge_equal

   pure function natural_spline(x, y) result(c)
   !< Coefficients `c(0:3, i)` of the natural cubic spline through (`x`, `y`) (x increasing, at least 3 points) on each
   !< interval i, in powers of x - x(i): second derivative zero at both ends.
   real(R8P), intent(in)  :: x(:)     !< Knots.
   real(R8P), intent(in)  :: y(:)     !< Values.
   real(R8P), allocatable :: c(:,:)   !< Coefficients.
   real(R8P), allocatable :: h(:)     !< Interval widths.
   real(R8P), allocatable :: diag(:)  !< Diagonal.
   real(R8P), allocatable :: rhs(:)   !< Right side, then half the second derivatives.
   real(R8P)              :: f        !< Elimination factor.
   integer(I4P)           :: n        !< Knots.
   integer(I4P)           :: i        !< Counter.

   n = size(x, kind=I4P)
   ! allocated before the assignment: nvfortran 26.9 reads h(1) as 0 in the loops below when h is allocated by it
   allocate(h(n - 1_I4P))
   h(:) = x(2:) - x(:n - 1)
   allocate(c(0:3, n), diag(n), rhs(n))
   ! half the second derivatives s(i) = c(2, i): s(1) = s(n) = 0, and for the inner knots
   ! h(i-1) s(i-1) + 2 (h(i-1) + h(i)) s(i) + h(i) s(i+1) = 3 ((y(i+1) - y(i)) / h(i) - (y(i) - y(i-1)) / h(i-1))
   diag = 1.0_R8P
   rhs = 0.0_R8P
   do i = 2_I4P, n - 1_I4P
      diag(i) = 2.0_R8P * (h(i - 1_I4P) + h(i))
      rhs(i) = 3.0_R8P * ((y(i + 1_I4P) - y(i)) / h(i) - (y(i) - y(i - 1_I4P)) / h(i - 1_I4P))
   enddo
   ! Thomas algorithm on the inner knots (the ends are zero)
   do i = 3_I4P, n - 1_I4P
      f = h(i - 1_I4P) / diag(i - 1_I4P)
      diag(i) = diag(i) - f * h(i - 1_I4P)
      rhs(i) = rhs(i) - f * rhs(i - 1_I4P)
   enddo
   c(2, :) = 0.0_R8P
   do i = n - 1_I4P, 2_I4P, -1_I4P
      c(2, i) = rhs(i)
      if (i < n - 1_I4P) c(2, i) = c(2, i) - h(i) * c(2, i + 1_I4P)
      c(2, i) = c(2, i) / diag(i)
   enddo
   call fill_coefficients(x, y, c)
   endfunction natural_spline

   pure function approximation_spline(x, y, w) result(c)
   !< Coefficients `c(0:3, i)` of the smoothing spline of Reinsch through (`x`, `y`) with weights `w` (x increasing, at
   !< least 4 points), as gnuplot's acsplines: natural, its values at the knots c(0, i) drawn towards y(i) by w(i).
   real(R8P), intent(in)  :: x(:)     !< Knots.
   real(R8P), intent(in)  :: y(:)     !< Values.
   real(R8P), intent(in)  :: w(:)     !< Weights, positive.
   real(R8P), allocatable :: c(:,:)   !< Coefficients.
   real(R8P), allocatable :: h(:)     !< Interval widths.
   real(R8P), allocatable :: band(:,:) !< Pentadiagonal matrix, band(-2:2, row), symmetric positive definite.
   real(R8P), allocatable :: rhs(:)   !< Right side, then the inner half second derivatives.
   real(R8P), allocatable :: values(:) !< Spline values at the knots.
   real(R8P)              :: f        !< Elimination factor.
   integer(I4P)           :: n        !< Knots.
   integer(I4P)           :: m        !< Inner knots.
   integer(I4P)           :: i        !< Row.
   integer(I4P)           :: j        !< Row below.
   integer(I4P)           :: k        !< Column.

   n = size(x, kind=I4P)
   m = n - 2_I4P
   ! allocated before the assignment, as in natural_spline (nvfortran 26.9)
   allocate(h(n - 1_I4P))
   h(:) = x(2:) - x(:n - 1)
   allocate(c(0:3, n), band(-2:2, m), rhs(m))
   band = 0.0_R8P
   ! row r (inner knot r+1) for the half second derivatives s(2..n-1): the cubic spline conditions with the knot values
   ! y - (2/w) times the jump of the third derivative (Reinsch), written with 1-based knots: q(i) = 1/h(i)
   do i = 1_I4P, m
      rhs(i) = 3.0_R8P * ((y(i + 2_I4P) - y(i + 1_I4P)) / h(i + 1_I4P) - (y(i + 1_I4P) - y(i)) / h(i))
      band(0, i) = 2.0_R8P * (h(i) + h(i + 1_I4P)) + 6.0_R8P / w(i) / h(i)**2 + &
                   6.0_R8P / w(i + 1_I4P) * (1.0_R8P / h(i) + 1.0_R8P / h(i + 1_I4P))**2 + &
                   6.0_R8P / w(i + 2_I4P) / h(i + 1_I4P)**2
      if (i > 1_I4P) band(-1, i) = h(i) - 6.0_R8P / w(i) / h(i) * (1.0_R8P / h(i - 1_I4P) + 1.0_R8P / h(i)) - &
                                   6.0_R8P / w(i + 1_I4P) / h(i) * (1.0_R8P / h(i) + 1.0_R8P / h(i + 1_I4P))
      if (i > 2_I4P) band(-2, i) = 6.0_R8P / w(i) / h(i - 1_I4P) / h(i)
      if (i < m) band(1, i) = h(i + 1_I4P) - 6.0_R8P / w(i + 1_I4P) / h(i + 1_I4P) * (1.0_R8P / h(i) + &
                              1.0_R8P / h(i + 1_I4P)) - 6.0_R8P / w(i + 2_I4P) / h(i + 1_I4P) * &
                              (1.0_R8P / h(i + 1_I4P) + 1.0_R8P / h(i + 2_I4P))
      if (i < m - 1_I4P) band(2, i) = 6.0_R8P / w(i + 2_I4P) / h(i + 1_I4P) / h(i + 2_I4P)
   enddo
   ! banded Gaussian elimination, no pivoting (symmetric positive definite)
   do i = 1_I4P, m - 1_I4P
      do j = i + 1_I4P, min(i + 2_I4P, m)
         f = band(i - j, j) / band(0, i)
         do k = i + 1_I4P, min(i + 2_I4P, m)
            band(k - j, j) = band(k - j, j) - f * band(k - i, i)
         enddo
         rhs(j) = rhs(j) - f * rhs(i)
      enddo
   enddo
   do i = m, 1_I4P, -1_I4P
      do k = i + 1_I4P, min(i + 2_I4P, m)
         rhs(i) = rhs(i) - band(k - i, i) * rhs(k)
      enddo
      rhs(i) = rhs(i) / band(0, i)
   enddo
   c(2, 1) = 0.0_R8P
   c(2, 2:n - 1) = rhs
   c(2, n) = 0.0_R8P
   ! the spline values at the knots
   c(0, 1) = y(1) + 2.0_R8P / w(1) / h(1) * (c(2, 1) - c(2, 2))
   do i = 2_I4P, n - 1_I4P
      c(0, i) = y(i) - 2.0_R8P / w(i) * (c(2, i - 1_I4P) / h(i - 1_I4P) - c(2, i) * (1.0_R8P / h(i - 1_I4P) + &
                1.0_R8P / h(i)) + c(2, i + 1_I4P) / h(i))
   enddo
   c(0, n) = y(n) - 2.0_R8P / w(n) / h(n - 1_I4P) * (c(2, n - 1_I4P) - c(2, n))
   ! a copy: the knot values must not alias the coefficients they fill
   values = c(0, :)
   call fill_coefficients(x, values, c)
   endfunction approximation_spline

   pure subroutine fill_coefficients(x, v, c)
   !< The first and third order coefficients of a cubic spline from its knot values `v` and half second derivatives
   !< c(2, :): c(1, i) the slope, c(3, i) a third of the change of c(2, :) per unit, on each interval.
   real(R8P), intent(in)    :: x(:)     !< Knots.
   real(R8P), intent(in)    :: v(:)     !< Knot values.
   real(R8P), intent(inout) :: c(0:, :) !< Coefficients.
   real(R8P)                :: h        !< Interval width.
   integer(I4P)             :: i        !< Interval.

   c(0, :) = v
   do i = 1_I4P, size(x, kind=I4P) - 1_I4P
      h = x(i + 1_I4P) - x(i)
      c(1, i) = (v(i + 1_I4P) - v(i)) / h - h / 3.0_R8P * (c(2, i + 1_I4P) + 2.0_R8P * c(2, i))
      c(3, i) = (c(2, i + 1_I4P) - c(2, i)) / 3.0_R8P / h
   enddo
   c(1, size(x)) = 0.0_R8P
   c(3, size(x)) = 0.0_R8P
   endsubroutine fill_coefficients

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
