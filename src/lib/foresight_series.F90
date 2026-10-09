!< foresight_series, a plotted data series.
module foresight_series
!< foresight_series, a plotted data series.
use penf, only : I4P, R8P
use foresight_axis, only : axis_object
use foresight_style, only : style_object, WITH_HISTOGRAMS

implicit none
private
public :: series_object

type :: series_object
   !< Data series.
   real(R8P), allocatable        :: x(:)  !< Abscissae.
   real(R8P), allocatable        :: y(:)  !< Ordinates.
   real(R8P), allocatable        :: xlow(:)  !< Horizontal error bar starts, allocated for x error bars.
   real(R8P), allocatable        :: xhigh(:) !< Horizontal error bar ends, allocated for x error bars.
   real(R8P), allocatable        :: ylow(:)  !< Vertical error bar starts, allocated for y error bars.
   real(R8P), allocatable        :: yhigh(:) !< Vertical error bar ends, allocated for y error bars.
   character(len=:), allocatable :: title !< Key title, empty for none; the label of a readout.
   character(len=:), allocatable :: format !< Readout format (foresight_readout), readouts only.
   character(len=:), allocatable :: xlabels(:) !< Text labels of the abscissae (`xtic(N)`), blank for none.
   real(R8P), allocatable        :: values(:) !< Values of a histogram, `y` being the top of its bar or stack segment.
   real(R8P), allocatable        :: grid(:,:) !< Values of an image (column, row), rows upward; `x` and `y` are then its
                                              !< left and right, bottom and top pixel edges.
   real(R8P), allocatable        :: radius(:) !< Radii of circles [x units], NaN for the default (2% of the plot width).
   real(R8P), allocatable        :: arcs(:,:) !< Start and end angles of wedges (2, point) [deg, counterclockwise from
                                              !< the x direction]; unallocated for whole circles.
   real(R8P)                     :: donut = 0.0_R8P !< Inner radius of a pie, a fraction of its radius (0: a pie).
   real(R8P)                     :: scale(2) = [0.0_R8P, 1.0_R8P] !< Value range of a gauge: start and end of its sweep.
   logical                       :: linear = .false. !< Rose sectors with the radius (not the area) by value.
   real(R8P), allocatable        :: bounds(:,:) !< Second pair of ordinates per point (2, point): the error bar ends of
                                                !< `boxerrorbars`, the box ends of `candlesticks` (open, close) and of
                                                !< `boxplot` (first, third quartile); unallocated otherwise.
   real(R8P), allocatable        :: outliers(:,:) !< Outliers of a boxplot (2, outlier): abscissa, ordinate.
   real(R8P)                     :: whiskerbars = 0.0_R8P !< Crossbars of the candlestick whiskers, a fraction of
                                                          !< the box width; 0 for none.
   type(style_object)            :: style !< Drawing style.
   logical                       :: y2 = .false. !< On the second y axis (gnuplot `axes x1y2`), else on the first.
   contains
      procedure, pass(self) :: extent !< Accumulate the data extent.
      procedure, pass(self) :: valid  !< Mask of the placeable points.
endtype series_object

contains
   pure function valid(self, xaxis, yaxis) result(mask)
   !< Mask of the points placeable on both axes; the others are gaps, as gnuplot undefined points.
   class(series_object), intent(in) :: self    !< Series.
   type(axis_object),    intent(in) :: xaxis   !< Horizontal axis.
   type(axis_object),    intent(in) :: yaxis   !< Vertical axis.
   logical, allocatable             :: mask(:) !< Placeable points.

   mask = xaxis%accepts(self%x) .and. yaxis%accepts(self%y)
   endfunction valid

   pure subroutine extent(self, xaxis, yaxis, xmin, xmax, ymin, ymax, found, xwindow)
   !< Widen the extent (`xmin`, `xmax`, `ymin`, `ymax`) to the placeable points of the series.
   !<
   !< With `xwindow` only the points whose abscissa lies inside it count: gnuplot autoscales y on the points inside the
   !< x range only. Error bar ends placeable on their axis widen the extent too, as in gnuplot; histogram rows widen the
   !< x extent by one unit on each side, as gnuplot.
   class(series_object), intent(in)           :: self       !< Series.
   type(axis_object),    intent(in)           :: xaxis      !< Horizontal axis.
   type(axis_object),    intent(in)           :: yaxis      !< Vertical axis.
   real(R8P),            intent(inout)        :: xmin       !< Smallest abscissa.
   real(R8P),            intent(inout)        :: xmax       !< Largest abscissa.
   real(R8P),            intent(inout)        :: ymin       !< Smallest ordinate.
   real(R8P),            intent(inout)        :: ymax       !< Largest ordinate.
   logical,              intent(inout)        :: found      !< Set if the series has any counted point.
   real(R8P),            intent(in), optional :: xwindow(2) !< Abscissa window, in any order.
   logical, allocatable                       :: mask(:)    !< Counted points.
   real(R8P), allocatable                     :: ends(:)    !< Bounds of the points.
   integer(I4P)                               :: i          !< Counter.

   mask = self%valid(xaxis, yaxis)
   if (present(xwindow)) then
      ! element-wise, never comparing a NaN abscissa (IEEE invalid)
      do i = 1_I4P, size(mask, kind=I4P)
         if (mask(i)) mask(i) = self%x(i) >= minval(xwindow) .and. self%x(i) <= maxval(xwindow)
      enddo
   endif
   if (.not. any(mask)) return
   found = .true.
   xmin = min(xmin, minval(self%x, mask=mask))
   xmax = max(xmax, maxval(self%x, mask=mask))
   ymin = min(ymin, minval(self%y, mask=mask))
   ymax = max(ymax, maxval(self%y, mask=mask))
   ! histograms: one unit beyond the first and last rows, as gnuplot
   if (self%style%with == WITH_HISTOGRAMS .and. .not. present(xwindow)) then
      xmin = min(xmin, minval(self%x, mask=mask) - 1.0_R8P)
      xmax = max(xmax, maxval(self%x, mask=mask) + 1.0_R8P)
   endif
   if (allocated(self%xlow)) call widen(self%xlow, xaxis, xmin, xmax)
   if (allocated(self%xhigh)) call widen(self%xhigh, xaxis, xmin, xmax)
   if (allocated(self%ylow)) call widen(self%ylow, yaxis, ymin, ymax)
   if (allocated(self%yhigh)) call widen(self%yhigh, yaxis, ymin, ymax)
   if (allocated(self%bounds)) then
      ! local copies: gfortran 16 debug builds misread sections of components reached through the class dummy
      ends = self%bounds(1, :)
      call widen(ends, yaxis, ymin, ymax)
      ends = self%bounds(2, :)
      call widen(ends, yaxis, ymin, ymax)
   endif
   if (allocated(self%outliers)) then
      do i = 1_I4P, size(self%outliers, 2, kind=I4P)
         if (.not. (xaxis%accepts(self%outliers(1, i)) .and. yaxis%accepts(self%outliers(2, i)))) cycle
         if (present(xwindow)) then
            if (self%outliers(1, i) < minval(xwindow) .or. self%outliers(1, i) > maxval(xwindow)) cycle
         endif
         ymin = min(ymin, self%outliers(2, i))
         ymax = max(ymax, self%outliers(2, i))
      enddo
   endif
   contains
      pure subroutine widen(ends, axis, lo, hi)
      !< Widen [`lo`, `hi`] to the placeable bar `ends` of the counted points.
      real(R8P),         intent(in)    :: ends(:) !< Bar ends.
      type(axis_object), intent(in)    :: axis    !< Axis of the bar ends.
      real(R8P),         intent(inout) :: lo      !< Extent start.
      real(R8P),         intent(inout) :: hi      !< Extent end.
      logical, allocatable             :: ok(:)   !< Counted placeable ends.

      ok = mask .and. axis%accepts(ends)
      if (.not. any(ok)) return
      lo = min(lo, minval(ends, mask=ok))
      hi = max(hi, maxval(ends, mask=ok))
      endsubroutine widen
   endsubroutine extent
endmodule foresight_series
