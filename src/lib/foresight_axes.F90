!< foresight_axes, a plot panel: the axes, the plotted series, the key and the decorations.
module foresight_axes
!< foresight_axes, a plot panel: the axes, the plotted series, the key and the decorations.
!<
!< Layout follows gnuplot defaults: full border with inward ticks mirrored on the opposite side, tick labels outside
!< bottom and left, key inside the plot area (top right by default) with right-aligned titles and the samples on their
!< right. A key `outside` lies in a side margin (left, right) or, centred, above or below the plot; `below` and `above`
!< lay its entries out in rows (`horizontal`), as many per row as the panel width holds.
!<
!< A second y axis (gnuplot `y2`) scales the series plotted on it (`axes x1y2`) on its own, autoscaled from them alone;
!< as gnuplot, its ticks and labels are off until `set y2tics` (on the right border, not mirrored), and it is drawn only
!< when it has data or a fully fixed range.
!< Text extents are measured by the output device (estimated for vector formats, whose viewer renders the glyphs).
!<
!< Boxes stand on y = 0 (`boxes`) and fills reach their baseline (`filledcurves y=V`): the box edges and the baselines
!< are stored as the bar ends `xlow`/`xhigh` and `ylow`, so they widen the autoscale as error bars do. Unlike gnuplot,
!< which leaves zero out of the y autoscale of boxes and the auto-width edges out of the x one, bars are drawn whole
!< and with lengths proportional to their values.
!<
!< Histograms (`with histograms`) lay out their bars from all the histogram series of the panel, as gnuplot: rows at
!< their abscissae (the point numbers 0, 1, ... from a script), `clustered` the k series side by side in slots
!< 1/(k + gap) wide centred on the row, `rowstacked` one stack per row, 1 wide, positive values up from 0 and negative
!< ones down from 0; `boxwidth` scales each bar. The layout is redone at every histogram added, the original values
!< kept in `values`; the x autoscale reaches one unit beyond the first and last rows, as gnuplot. Unlike gnuplot,
!< clustered bars reach 0 in the y autoscale, as boxes.
!<
!< Text labels of the abscissae (`xtic(N)`) of every series replace the x ticks (see foresight_axis).
!<
!< Readouts (`with readout`, see foresight_readout) show the last finite value of their series in seven-segment
!< digits. They take no part in autoscale, the key or the plot area: they form a block of readouts, in a column or a
!< row, placed inside the plot area as the key is (top left by default) over a window hiding the curves below. A panel
!< of readouts alone has no axes: its block grows to fill the panel, unless a digit size is set.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite
use foresight_axis, only : axis_object
use foresight_backend, only : axes_view, backend_object
use foresight_readout, only : DEFAULT_READOUT_FORMAT, last_finite, readout_check, readout_glass
use foresight_series, only : series_object
use foresight_style, only : default_color, fill_style, FILL_EMPTY, FILL_SOLID, style_object, style_with, WITH_BOXES, &
                            WITH_FILLEDCURVES, WITH_HISTOGRAMS, WITH_READOUT
use foresight_ticks, only : labels_attribute, tick_object, tics_object, TICS_NONE
use penf, only : I4P, R8P

implicit none
private
public :: axes_object
public :: axes_names
public :: key_position
public :: readout_position

real(R8P),        parameter :: PAD           = 10.0_R8P  !< Outer padding [px].
real(R8P),        parameter :: TICK_MAJOR    = 6.0_R8P   !< Major tick length [px].
real(R8P),        parameter :: TICK_MINOR    = 3.0_R8P   !< Minor tick length [px].
real(R8P),        parameter :: GAP           = 6.0_R8P   !< Gap between border, tick labels and axis labels [px].
real(R8P),        parameter :: LINE_HEIGHT   = 1.25_R8P  !< Text line height [font size].
real(R8P),        parameter :: SAMPLE_LENGTH = 3.0_R8P   !< Key sample length [font size].
real(R8P),        parameter :: CAP_LENGTH    = 6.0_R8P   !< Error bar cap length [px].
character(len=*), parameter :: FRAME_COLOR   = 'black'   !< Border and tick color.
character(len=*), parameter :: GRID_COLOR    = '#a0a0a0' !< Grid line color.
character(len=*), parameter :: GRID_DASHES   = '2,3'     !< Grid line dash array.
character(len=*), parameter :: WINDOW_FILL   = 'white'   !< Readout window fill: the page background.
real(R8P),        parameter :: DIGIT_HEIGHT  = 2.5_R8P   !< Default readout digit height [font size].

type :: axes_object
   !< Plot panel.
   type(axis_object)                :: xaxis          !< Horizontal axis.
   type(axis_object)                :: yaxis          !< Vertical axis.
   type(axis_object)                :: y2axis = axis_object(tics=tics_object(mode=TICS_NONE, mirror=.false.)) !< Second
                                                      !< vertical axis, on the right: no ticks until set (gnuplot).
   logical                          :: y2_active = .false. !< The second y axis is drawn, set by `setup_axes`.
   type(series_object), allocatable :: series(:)      !< Plotted series.
   character(len=:), allocatable    :: title          !< Panel title, empty for none.
   logical                          :: grid = .false. !< Draw grid lines at the major ticks.
   logical                          :: key  = .true.  !< Draw the key.
   character(len=6)                 :: key_h = 'right' !< Key horizontal position: left, center, right.
   character(len=6)                 :: key_v = 'top'   !< Key vertical position: top, center, bottom.
   logical                          :: key_box = .false. !< Draw a box around the key.
   logical                          :: key_outside = .false. !< Key outside the plot area (gnuplot `outside`).
   character(len=6)                 :: key_margin = ''  !< `top` or `bottom` margin (gnuplot `above`, `below`), else
                                                        !< empty.
   logical                          :: key_horizontal = .false. !< Entries side by side, in rows.
   real(R8P)                        :: origin(2) = [0.0_R8P, 0.0_R8P] !< Bottom left corner, page fraction (`set origin`).
   real(R8P)                        :: size(2)   = [1.0_R8P, 1.0_R8P] !< Width, height, page fraction (`set size`).
   type(style_object)               :: fill_default     !< Fill of the filled styles, `set style fill` (its fill
                                                        !< components only).
   real(R8P)                        :: boxwidth = 0.0_R8P !< Box width, `set boxwidth`; 0 for auto (boxes touching).
   logical                          :: boxwidth_relative = .false. !< `boxwidth` scales the auto width.
   logical                          :: histogram_rowstacked = .false. !< Histograms stacked by row, else clustered.
   real(R8P)                        :: histogram_gap = 2.0_R8P !< Gap between clusters [bar slots].
   logical                          :: readout = .true. !< Draw the readouts.
   character(len=6)                 :: readout_h = 'left' !< Readout block horizontal position: left, center, right.
   character(len=6)                 :: readout_v = 'top'  !< Readout block vertical position: top, center, bottom.
   logical                          :: readout_horizontal = .false. !< Readouts side by side, else in a column.
   logical                          :: readout_opaque = .true. !< Window behind the readouts over a plot.
   real(R8P)                        :: readout_size = 0.0_R8P !< Digit height [px]; 0 for the default, which fills
                                                              !< a panel of readouts alone.
   contains
      procedure, pass(self) :: add_series                  !< Add a data series.
      procedure, pass(self) :: data_extent                 !< Extent of the placeable data.
      procedure, pass(self) :: render                      !< Render the panel.
      procedure, pass(self), private :: draw_frame         !< Draw border, ticks, labels and title.
      procedure, pass(self), private :: draw_grid          !< Draw the grid.
      procedure, pass(self), private :: draw_key           !< Draw the key.
      procedure, pass(self), private :: draw_readouts      !< Draw the readouts.
      procedure, pass(self), private :: key_layout         !< Key size and entry grid.
      procedure, pass(self), private :: key_place          !< Where the key lies.
      procedure, pass(self), private :: draw_series        !< Draw a series.
      procedure, pass(self), private :: has_title          !< Whether the panel has a title.
      procedure, pass(self), private :: is_readout         !< Whether a series is a readout.
      procedure, pass(self), private :: place_plot_area    !< Plot area from the margins.
      procedure, pass(self), private :: setup_axes         !< Effective ranges and ticks.
endtype axes_object

contains
   subroutine add_series(self, x, y, title, with, lc, lw, dt, ps, xlow, xhigh, ylow, yhigh, axes, pt, format, width, &
                         base, fs, xlabels)
   !< Add the series (`x`, `y`) with gnuplot-like style options; unset options take gnuplot defaults.
   !<
   !< Error bar styles need their bounds: `ylow`/`yhigh` for `yerrorbars`, `xlow`/`xhigh` for `xerrorbars`, all four for
   !< `xyerrorbars`. `axes` is gnuplot's `x1y1` (default) or `x1y2`, the second y axis. A `readout` takes its `format`
   !< (`DEFAULT_READOUT_FORMAT` if absent) and only the color among the style options.
   !<
   !< `boxes` take the box widths `width` (NaN for the default), else the panel `boxwidth`, else touching boxes;
   !< `filledcurves` fill to the line y = `base`, between `ylow` and `y`, or the closed polygon of the points. `fs`
   !< (gnuplot fill style words, `'solid 0.5 noborder'`) overrides the panel fill of either; `histograms` take the fill
   !< too. `xlabels` are text labels of the abscissae (blank for none), replacing the x ticks.
   class(axes_object), intent(inout)        :: self   !< Panel.
   real(R8P),          intent(in)           :: x(:)   !< Abscissae.
   real(R8P),          intent(in)           :: y(:)   !< Ordinates.
   character(len=*),   intent(in), optional :: title  !< Key title, empty or absent for none.
   character(len=*),   intent(in), optional :: with   !< Plotting style: `lines` (default), `points`, `linespoints`.
   character(len=*),   intent(in), optional :: lc     !< Line color (SVG color); default from the gnuplot palette.
   real(R8P),          intent(in), optional :: lw     !< Line width [px].
   integer(I4P),       intent(in), optional :: dt     !< Dash type, 1..5.
   real(R8P),          intent(in), optional :: ps     !< Point size scale factor.
   real(R8P),          intent(in), optional :: xlow(:)  !< Horizontal error bar starts.
   real(R8P),          intent(in), optional :: xhigh(:) !< Horizontal error bar ends.
   real(R8P),          intent(in), optional :: ylow(:)  !< Vertical error bar starts.
   real(R8P),          intent(in), optional :: yhigh(:) !< Vertical error bar ends.
   character(len=*),   intent(in), optional :: axes     !< Axes of the series: `x1y1` or `x1y2`.
   integer(I4P),       intent(in), optional :: pt       !< gnuplot point type: 0 a dot, 1.. the shapes.
   character(len=*),   intent(in), optional :: format   !< Readout format.
   real(R8P),          intent(in), optional :: width(:) !< Box widths.
   real(R8P),          intent(in), optional :: base     !< Baseline of a fill.
   character(len=*),   intent(in), optional :: fs       !< Fill style words.
   character(len=*),   intent(in), optional :: xlabels(:) !< Text labels of the abscissae.
   type(series_object)                      :: series !< New series.
   character(len=:), allocatable            :: bad    !< Unknown fill style word.
   character(len=:), allocatable            :: message !< Readout format problem.

   if (size(x) /= size(y)) error stop 'foresight: plot: x and y have different sizes'
   if (present(axes)) then
      if (axes /= 'x1y1' .and. axes /= 'x1y2') error stop 'foresight: plot: axes must be x1y1 or x1y2, not "'//axes//'"'
      series%y2 = axes == 'x1y2'
   endif
   if (.not. allocated(self%series)) allocate(self%series(0))
   series%x = x
   series%y = y
   series%title = ''
   if (present(title)) series%title = title
   if (present(with)) series%style%with = style_with(with)
   series%style%color = default_color(size(self%series, kind=I4P) + 1_I4P)
   if (present(lc)) series%style%color = lc
   if (present(lw)) series%style%linewidth = lw
   if (present(dt)) series%style%dashtype = dt
   if (present(ps)) series%style%pointsize = ps
   if (present(pt)) then
      if (pt < 0_I4P) error stop 'foresight: plot: the point type must not be negative'
      series%style%pointtype = pt
   endif
   if (series%style%with == WITH_READOUT) then
      if (present(lw) .or. present(dt) .or. present(ps) .or. present(pt) .or. present(axes)) &
         error stop 'foresight: plot: a readout takes lc only among the style options (no lw, dt, ps, pt, axes)'
      series%format = DEFAULT_READOUT_FORMAT
      if (present(format)) series%format = format
      message = readout_check(series%format)
      if (len(message) > 0) error stop 'foresight: plot: '//message
   elseif (present(format)) then
      error stop 'foresight: plot: format applies to readouts only'
   endif
   if (series%style%fills()) then
      series%style%fill = self%fill_default%fill
      series%style%density = self%fill_default%density
      series%style%border = self%fill_default%border
      series%style%segments = self%fill_default%segments
      if (allocated(self%fill_default%border_color)) series%style%border_color = self%fill_default%border_color
      if (present(fs)) then
         call fill_style(fs, series%style, bad)
         if (len(bad) > 0) error stop 'foresight: plot: unsupported fill style "'//bad//'"'
      endif
   elseif (present(fs) .or. present(width) .or. present(base)) then
      error stop 'foresight: plot: fs, width and base apply to boxes and filledcurves only'
   endif
   select case (series%style%with)
   case (WITH_BOXES)
      if (present(base) .or. present(ylow)) error stop 'foresight: plot: boxes stand on y = 0 (no base, no ylow)'
      if (present(width)) then
         if (size(width) /= size(x)) error stop 'foresight: plot: width and x have different sizes'
      endif
      call box_edges(series%xlow, series%xhigh)
      allocate(series%ylow(size(x)))
      series%ylow = 0.0_R8P
   case (WITH_HISTOGRAMS)
      if (present(base) .or. present(ylow) .or. present(width)) &
         error stop 'foresight: plot: histograms take no base, ylow nor width (set_boxwidth scales the bars)'
      series%values = y
   case (WITH_FILLEDCURVES)
      ! gnuplot fills a curve even with an empty fill style, and never draws its border
      if (series%style%fill == FILL_EMPTY) series%style%density = 1.0_R8P
      series%style%fill = FILL_SOLID
      series%style%border = .false.
      if (present(base) .and. present(ylow)) error stop 'foresight: plot: a fill takes base or ylow, not both'
      if (present(base)) then
         allocate(series%ylow(size(x)))
         series%ylow = base
      endif
   endselect
   if (series%style%draws_xbars()) then
      if (.not. (present(xlow) .and. present(xhigh))) error stop 'foresight: plot: x error bars need xlow and xhigh'
      if (size(xlow) /= size(x) .or. size(xhigh) /= size(x)) error stop 'foresight: plot: xlow/xhigh sizes differ from x'
      series%xlow = xlow
      series%xhigh = xhigh
   endif
   if (present(xlabels)) then
      if (size(xlabels) /= size(x)) error stop 'foresight: plot: xlabels and x have different sizes'
      series%xlabels = xlabels
   endif
   if (series%style%with == WITH_FILLEDCURVES .and. present(ylow)) then
      if (size(ylow) /= size(y)) error stop 'foresight: plot: ylow and y have different sizes'
      series%ylow = ylow
   endif
   if (series%style%draws_ybars()) then
      if (.not. (present(ylow) .and. present(yhigh))) error stop 'foresight: plot: y error bars need ylow and yhigh'
      if (size(ylow) /= size(y) .or. size(yhigh) /= size(y)) error stop 'foresight: plot: ylow/yhigh sizes differ from y'
      series%ylow = ylow
      series%yhigh = yhigh
   endif
   self%series = [self%series, series]
   if (series%style%with == WITH_HISTOGRAMS) call layout_histograms(self%series, self%histogram_rowstacked, &
                                                                     self%histogram_gap, self%boxwidth)
   contains
      pure subroutine box_edges(left, right)
      !< Box edges: halfway to the neighbours (gnuplot's auto width, the end boxes symmetric), scaled by a relative
      !< `boxwidth`; or `boxwidth` itself; or the box's own `width`.
      real(R8P), allocatable, intent(out) :: left(:)  !< Left edges.
      real(R8P), allocatable, intent(out) :: right(:) !< Right edges.
      real(R8P)                           :: dl       !< Distance to the previous point.
      real(R8P)                           :: dr       !< Distance to the next point.
      integer(I4P)                        :: n        !< Points.
      integer(I4P)                        :: i        !< Counter.

      n = size(x, kind=I4P)
      allocate(left(n), right(n))
      do i = 1_I4P, n
         dl = huge(1.0_R8P)
         dr = huge(1.0_R8P)
         if (i > 1_I4P) then
            if (ieee_is_finite(x(i - 1_I4P)) .and. ieee_is_finite(x(i))) dl = x(i) - x(i - 1_I4P)
         endif
         if (i < n) then
            if (ieee_is_finite(x(i + 1_I4P)) .and. ieee_is_finite(x(i))) dr = x(i + 1_I4P) - x(i)
         endif
         if (dl == huge(1.0_R8P)) dl = dr
         if (dr == huge(1.0_R8P)) dr = dl
         ! a single box: unit width
         if (dl == huge(1.0_R8P)) then
            dl = 1.0_R8P
            dr = 1.0_R8P
         endif
         dl = 0.5_R8P * dl
         dr = 0.5_R8P * dr
         if (self%boxwidth > 0.0_R8P) then
            if (self%boxwidth_relative) then
               dl = self%boxwidth * dl
               dr = self%boxwidth * dr
            else
               dl = 0.5_R8P * self%boxwidth
               dr = dl
            endif
         endif
         if (present(width)) then
            if (ieee_is_finite(width(i))) then
               dl = 0.5_R8P * width(i)
               dr = dl
            endif
         endif
         left(i) = x(i) - dl
         right(i) = x(i) + dr
      enddo
      endsubroutine box_edges
   endsubroutine add_series

   pure subroutine data_extent(self, xmin, xmax, ymin, ymax, found)
   !< Extent of the series points placeable on their axes, the whole data before any range is set: x over every series,
   !< y per axis (1 the first, 2 the second).
   class(axes_object), intent(in)  :: self     !< Panel.
   real(R8P),          intent(out) :: xmin     !< Smallest abscissa.
   real(R8P),          intent(out) :: xmax     !< Largest abscissa.
   real(R8P),          intent(out) :: ymin(2)  !< Smallest ordinate, per y axis.
   real(R8P),          intent(out) :: ymax(2)  !< Largest ordinate, per y axis.
   logical,            intent(out) :: found(2) !< Any placeable point, per y axis.
   integer(I4P)                    :: s        !< Series counter.
   integer(I4P)                    :: k        !< y axis of the series: 1 or 2.

   xmin = huge(1.0_R8P)
   xmax = -huge(1.0_R8P)
   ymin = huge(1.0_R8P)
   ymax = -huge(1.0_R8P)
   found = .false.
   do s = 1_I4P, size(self%series, kind=I4P)
      if (self%is_readout(s)) cycle
      k = merge(2_I4P, 1_I4P, self%series(s)%y2)
      if (k == 2_I4P) then
         call self%series(s)%extent(self%xaxis, self%y2axis, xmin, xmax, ymin(k), ymax(k), found(k))
      else
         call self%series(s)%extent(self%xaxis, self%yaxis, xmin, xmax, ymin(k), ymax(k), found(k))
      endif
   enddo
   endsubroutine data_extent

   subroutine render(self, backend, x0, y0, width, height, font_size)
   !< Render the panel into the pixel box of top-left corner (`x0`, `y0`) and size `width` x `height`.
   class(axes_object),    intent(inout) :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: x0        !< Box left side [px].
   real(R8P),             intent(in)    :: y0        !< Box top side [px].
   real(R8P),             intent(in)    :: width     !< Box width [px].
   real(R8P),             intent(in)    :: height    !< Box height [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   real(R8P)                            :: area(4)   !< Plot area: left, right, top, bottom [px].
   real(R8P)                            :: box(4)    !< Box left to the rest of the panel by an outside key:
                                                     !< left, top, width, height [px].
   real(R8P)                            :: key(2)    !< Key width and height [px].
   real(R8P)                            :: above     !< Room for a key above the plot [px].
   type(axes_view)                      :: view      !< Panel geometry and ranges for the device.
   integer(I4P)                         :: s         !< Series counter.
   integer(I4P)                         :: grid(3)   !< Key entries, columns, rows.

   if (.not. allocated(self%series)) allocate(self%series(0))
   if (size(self%series) > 0) then
      if (all([(self%is_readout(s), s = 1_I4P, size(self%series, kind=I4P))])) then
         ! readouts alone: no axes, the block fills the panel below the title
         area = [x0 + PAD, x0 + width - PAD, y0 + PAD, y0 + height - PAD]
         if (self%has_title()) then
            call backend%text(x0 + 0.5_R8P * width, y0 + PAD + font_size, self%title, 'middle')
            area(3) = area(3) + LINE_HEIGHT * font_size + GAP
         endif
         if (self%readout) call self%draw_readouts(backend, area, font_size, .true.)
         return
      endif
   endif
   ! an outside key takes its side of the panel box; above the plot it goes below the title, as gnuplot
   box = [x0, y0, width, height]
   above = 0.0_R8P
   call self%key_layout(backend, font_size, width - 2.0_R8P * PAD, grid, key)
   if (self%key .and. grid(1) > 0_I4P) then
      select case (self%key_place())
      case ('left')
         box(1) = x0 + PAD + key(1)
         box(3) = width - PAD - key(1)
      case ('right')
         box(3) = width - PAD - key(1)
      case ('bottom')
         box(4) = height - PAD - key(2)
      case ('top')
         above = key(2) + GAP
      endselect
   endif
   ! ticks depend on the plot area size, margins on the tick labels: refine a first guess twice
   associate(bx => box(1), by => box(2), bw => box(3), bh => box(4))
      area = [bx + 6.0_R8P * font_size, bx + bw - 2.0_R8P * font_size, &
              by + 2.0_R8P * font_size + above, by + bh - 4.0_R8P * font_size]
      call self%setup_axes(area)
      area = self%place_plot_area(backend, bx, by, bw, bh, font_size, above)
      call self%setup_axes(area)
      area = self%place_plot_area(backend, bx, by, bw, bh, font_size, above)
   endassociate

   view = axes_view(area=area, x=[self%xaxis%lo, self%xaxis%hi], y=[self%yaxis%lo, self%yaxis%hi], &
                    xlog=self%xaxis%log, ylog=self%yaxis%log, grid=self%grid, font_size=font_size)
   view%xtics = self%xaxis%tics%attribute()
   if (self%xaxis%labelled()) view%xtics = labels_attribute(self%xaxis%labels)
   view%ytics = self%yaxis%tics%attribute()
   view%xformat = ''
   view%yformat = ''
   if (self%xaxis%tics%has_format()) view%xformat = self%xaxis%tics%format
   if (self%yaxis%tics%has_format()) view%yformat = self%yaxis%tics%format
   view%mirror = [self%xaxis%tics%mirror, self%yaxis%tics%mirror, self%y2axis%tics%mirror]
   view%y2_active = self%y2_active
   if (self%y2_active) then
      view%y2 = [self%y2axis%lo, self%y2axis%hi]
      view%y2log = self%y2axis%log
      view%y2tics = self%y2axis%tics%attribute()
      view%y2format = ''
      if (self%y2axis%tics%has_format()) view%y2format = self%y2axis%tics%format
   endif
   call backend%begin_axes(view)
   ! grid lines always emitted, hidden when off: an interactive viewer can toggle them
   call backend%begin_group('fs-grid', visible=self%grid)
   call self%draw_grid(backend, area)
   call backend%end_group
   call backend%begin_plot_area(area(1), area(3), area(2) - area(1), area(4) - area(3))
   do s = 1_I4P, size(self%series, kind=I4P)
      if (self%is_readout(s)) cycle
      call backend%begin_group('fs-series', series=s)
      if (self%series(s)%y2) then
         call self%draw_series(backend, s, self%y2axis)
      else
         call self%draw_series(backend, s, self%yaxis)
      endif
      call backend%end_group
   enddo
   call backend%end_plot_area
   call self%draw_frame(backend, area, box(1), box(2), box(1) + box(3), font_size)
   if (self%key .and. grid(1) > 0_I4P) call self%draw_key(backend, area, [x0, y0, x0 + width, y0 + height], font_size, &
                                                         grid, key)
   if (self%readout .and. any([(self%is_readout(s), s = 1_I4P, size(self%series, kind=I4P))])) &
      call self%draw_readouts(backend, area, font_size, .false.)
   call backend%end_axes
   endsubroutine render

   ! private procedures
   subroutine draw_frame(self, backend, area, x0, y0, x1, font_size)
   !< Draw border, ticks (mirrored if so set), tick labels, axis labels and title.
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: area(4)   !< Plot area: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: x0        !< Box left side [px].
   real(R8P),             intent(in)    :: y0        !< Box top side [px].
   real(R8P),             intent(in)    :: x1        !< Box right side [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   real(R8P)                            :: p         !< Tick position [px].
   real(R8P)                            :: length    !< Tick length [px].
   integer(I4P)                         :: t         !< Tick counter.

   associate(left => area(1), right => area(2), top => area(3), bottom => area(4))
      call backend%rect(left, top, right - left, bottom - top, FRAME_COLOR, 'none', 1.0_R8P)
      call backend%begin_group('fs-xticks')
      do t = 1_I4P, size(self%xaxis%ticks, kind=I4P)
         p = left + self%xaxis%to_unit(self%xaxis%ticks(t)%value) * (right - left)
         length = merge(TICK_MAJOR, TICK_MINOR, self%xaxis%ticks(t)%major)
         call backend%polyline([p, p], [bottom, bottom - length], FRAME_COLOR, 1.0_R8P, '')
         if (self%xaxis%tics%mirror) call backend%polyline([p, p], [top, top + length], FRAME_COLOR, 1.0_R8P, '')
         if (self%xaxis%ticks(t)%major) call backend%text(p, bottom + GAP + font_size, self%xaxis%ticks(t)%label, &
                                                          'middle', sup=self%xaxis%ticks(t)%sup)
      enddo
      call backend%end_group
      call backend%begin_group('fs-yticks')
      do t = 1_I4P, size(self%yaxis%ticks, kind=I4P)
         p = bottom - self%yaxis%to_unit(self%yaxis%ticks(t)%value) * (bottom - top)
         length = merge(TICK_MAJOR, TICK_MINOR, self%yaxis%ticks(t)%major)
         call backend%polyline([left, left + length], [p, p], FRAME_COLOR, 1.0_R8P, '')
         if (self%yaxis%tics%mirror) call backend%polyline([right, right - length], [p, p], FRAME_COLOR, 1.0_R8P, '')
         if (self%yaxis%ticks(t)%major) call backend%text(left - GAP, p + 0.35_R8P * font_size, &
                                                          self%yaxis%ticks(t)%label, 'end', sup=self%yaxis%ticks(t)%sup)
      enddo
      call backend%end_group
      if (self%y2_active) then
         call backend%begin_group('fs-y2ticks')
         do t = 1_I4P, size(self%y2axis%ticks, kind=I4P)
            p = bottom - self%y2axis%to_unit(self%y2axis%ticks(t)%value) * (bottom - top)
            length = merge(TICK_MAJOR, TICK_MINOR, self%y2axis%ticks(t)%major)
            call backend%polyline([right, right - length], [p, p], FRAME_COLOR, 1.0_R8P, '')
            if (self%y2axis%tics%mirror) call backend%polyline([left, left + length], [p, p], FRAME_COLOR, 1.0_R8P, '')
            if (self%y2axis%ticks(t)%major) call backend%text(right + GAP, p + 0.35_R8P * font_size, &
                                                              self%y2axis%ticks(t)%label, 'start', &
                                                              sup=self%y2axis%ticks(t)%sup)
         enddo
         call backend%end_group
      endif
      if (self%xaxis%has_label()) call backend%text(0.5_R8P * (left + right), &
                                                    bottom + 2.0_R8P * GAP + (1.0_R8P + LINE_HEIGHT) * font_size, &
                                                    self%xaxis%label, 'middle')
      if (self%yaxis%has_label()) call backend%text(x0 + PAD + font_size, 0.5_R8P * (top + bottom), &
                                                    self%yaxis%label, 'middle', rotate=-90.0_R8P)
      ! read upward as the y label, the glyphs on the left of the baseline
      if (self%y2axis%has_label()) call backend%text(x1 - PAD - 0.25_R8P * font_size, 0.5_R8P * (top + bottom), &
                                                     self%y2axis%label, 'middle', rotate=-90.0_R8P)
      if (self%has_title()) call backend%text(0.5_R8P * (left + right), y0 + PAD + font_size, self%title, 'middle')
   endassociate
   endsubroutine draw_frame

   subroutine draw_grid(self, backend, area)
   !< Draw grid lines at the major ticks.
   class(axes_object),    intent(in)    :: self    !< Panel.
   class(backend_object), intent(inout) :: backend !< Output device.
   real(R8P),             intent(in)    :: area(4) !< Plot area: left, right, top, bottom [px].
   real(R8P)                            :: p       !< Tick position [px].
   integer(I4P)                         :: t       !< Tick counter.

   associate(left => area(1), right => area(2), top => area(3), bottom => area(4))
      do t = 1_I4P, size(self%xaxis%ticks, kind=I4P)
         if (.not. self%xaxis%ticks(t)%major) cycle
         p = left + self%xaxis%to_unit(self%xaxis%ticks(t)%value) * (right - left)
         call backend%polyline([p, p], [bottom, top], GRID_COLOR, 0.5_R8P, GRID_DASHES)
      enddo
      do t = 1_I4P, size(self%yaxis%ticks, kind=I4P)
         if (.not. self%yaxis%ticks(t)%major) cycle
         p = bottom - self%yaxis%to_unit(self%yaxis%ticks(t)%value) * (bottom - top)
         call backend%polyline([left, right], [p, p], GRID_COLOR, 0.5_R8P, GRID_DASHES)
      enddo
   endassociate
   endsubroutine draw_grid

   subroutine draw_key(self, backend, area, box, font_size, grid, extent)
   !< Draw the key at its place (`key_place`): right-aligned titles, style samples on their right; entries in a column,
   !< or row after row (`key_horizontal`).
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: area(4)   !< Plot area: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: box(4)    !< Panel box: left, top, right, bottom [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   integer(I4P),          intent(in)    :: grid(3)   !< Entries, columns, rows (`key_layout`).
   real(R8P),             intent(in)    :: extent(2) !< Key width and height [px] (`key_layout`).
   real(R8P)                            :: xs(2)     !< Sample abscissae [px].
   real(R8P)                            :: yc        !< Row centre ordinate [px].
   real(R8P)                            :: entry     !< Entry width, spacing included [px].
   real(R8P)                            :: left      !< Key left [px].
   real(R8P)                            :: top       !< Key top [px].
   integer(I4P)                         :: k         !< Entry counter.
   integer(I4P)                         :: s         !< Series counter.

   associate(width => extent(1), height => extent(2))
      entry = (width + GAP) / real(grid(2), R8P)
      select case (self%key_place())
      case ('left', 'right')
         ! beside the plot, aligned with its border
         if (self%key_place() == 'left') then
            left = box(1) + PAD
         else
            left = box(3) - PAD - width
         endif
         select case (trim(self%key_v))
         case ('bottom')
            top = area(4) - height
         case ('center')
            top = 0.5_R8P * (area(3) + area(4) - height)
         case default
            top = area(3)
         endselect
      case ('top', 'bottom')
         ! above or below the plot, aligned with it
         select case (trim(self%key_h))
         case ('left')
            left = area(1)
         case ('right')
            left = area(2) - width
         case default
            left = 0.5_R8P * (area(1) + area(2) - width)
         endselect
         if (self%key_place() == 'top') then
            top = area(3) - GAP - height
         else
            top = box(4) - PAD - height
         endif
      case default
         select case (trim(self%key_h))
         case ('left')
            left = area(1) + PAD
         case ('center')
            left = 0.5_R8P * (area(1) + area(2) - width)
         case default
            left = area(2) - PAD - width
         endselect
         select case (trim(self%key_v))
         case ('bottom')
            top = area(4) - GAP - height
         case ('center')
            top = 0.5_R8P * (area(3) + area(4) - height)
         case default
            top = area(3) + GAP
         endselect
      endselect
      if (self%key_box) call backend%rect(left - GAP, top - 0.5_R8P * GAP, width + 2.0_R8P * GAP, height + GAP, &
                                          FRAME_COLOR, 'none', 1.0_R8P)
   endassociate
   k = 0_I4P
   do s = 1_I4P, size(self%series, kind=I4P)
      if (len(self%series(s)%title) == 0 .or. self%is_readout(s)) cycle
      ! entry k (from 0) in column mod(k, columns), row k / columns
      xs(2) = left + real(modulo(k, grid(2)) + 1_I4P, R8P) * entry - GAP
      xs(1) = xs(2) - SAMPLE_LENGTH * font_size
      yc = top + (real(k / grid(2), R8P) + 0.5_R8P) * LINE_HEIGHT * font_size
      k = k + 1_I4P
      call backend%begin_group('fs-key-entry', series=s)
      if (self%series(s)%style%fills()) &
         call backend%polygon([xs(1), xs(2), xs(2), xs(1)], &
                              [yc + 0.35_R8P * font_size, yc + 0.35_R8P * font_size, yc - 0.35_R8P * font_size, &
                               yc - 0.35_R8P * font_size], self%series(s)%style%fill_color(), &
                              self%series(s)%style%density, self%series(s)%style%stroke_color(), &
                              self%series(s)%style%linewidth)
      if (self%series(s)%style%draws_lines()) &
         call backend%polyline(xs, [yc, yc], self%series(s)%style%color, self%series(s)%style%linewidth, &
                               self%series(s)%style%dasharray())
      if (self%series(s)%style%draws_ybars()) &
         call backend%polyline([0.5_R8P * (xs(1) + xs(2)), 0.5_R8P * (xs(1) + xs(2))], &
                               [yc - 0.4_R8P * font_size, yc + 0.4_R8P * font_size], self%series(s)%style%color, &
                               self%series(s)%style%linewidth, '')
      if (self%series(s)%style%draws_xbars()) &
         call backend%polyline(xs, [yc, yc], self%series(s)%style%color, self%series(s)%style%linewidth, '')
      if (self%series(s)%style%draws_points()) &
         call backend%dots([0.5_R8P * (xs(1) + xs(2))], [yc], self%series(s)%style%color, &
                           self%series(s)%style%point_diameter(), pt=self%series(s)%style%pointtype, &
                           line_width=self%series(s)%style%linewidth)
      call backend%text(xs(1) - GAP, yc + 0.35_R8P * font_size, self%series(s)%title, 'end')
      call backend%end_group
   enddo
   endsubroutine draw_key

   subroutine draw_readouts(self, backend, area, font_size, fill)
   !< Draw the block of readouts in `area`, as the key is placed inside the plot area: a column (or a row) of readouts,
   !< over an opaque window unless `fill`, where the readouts are alone in the panel and the digits grow until the
   !< block fills `area` (vector devices; text has one size), unless a digit size is set.
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: area(4)   !< Box: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   logical,               intent(in)    :: fill      !< Readouts alone, filling the box.
   type :: glass_object
      !< Readout content.
      integer(I4P), allocatable     :: masks(:) !< Segments of each cell.
      character(len=:), allocatable :: prefix   !< Text before the glass.
      character(len=:), allocatable :: suffix   !< Text after the glass.
   endtype glass_object
   type(glass_object), allocatable      :: glasses(:) !< Readouts, in series order.
   integer(I4P), allocatable            :: which(:)   !< Series of each readout.
   real(R8P),    allocatable            :: sizes(:,:) !< Width and height of each readout [px].
   real(R8P)                            :: height     !< Digit height [px].
   real(R8P)                            :: spacing    !< Space between readouts [px].
   real(R8P)                            :: block(2)   !< Block width and height [px].
   real(R8P)                            :: left       !< Block left [px].
   real(R8P)                            :: top        !< Block top [px].
   real(R8P)                            :: p          !< Position of the next readout [px].
   real(R8P)                            :: inset(2)   !< Block inset from the plot border, across and down [px].
   real(R8P)                            :: pad(2)     !< Window padding, across and down [px].
   integer(I4P)                         :: r          !< Readout counter.
   integer(I4P)                         :: s          !< Series counter.
   integer(I4P)                         :: along      !< Direction of the block: 1 a row, 2 a column.

   which = pack([(s, s = 1_I4P, size(self%series, kind=I4P))], [(self%is_readout(s), s = 1_I4P, &
                                                                  size(self%series, kind=I4P))])
   allocate(glasses(size(which)))
   do r = 1_I4P, size(which, kind=I4P)
      associate(series => self%series(which(r)))
         call readout_glass(series%format, last_finite(series%y), glasses(r)%masks, glasses(r)%prefix, &
                            glasses(r)%suffix)
      endassociate
   enddo
   along = merge(1_I4P, 2_I4P, self%readout_horizontal)
   spacing = merge(2.0_R8P, 1.0_R8P, self%readout_horizontal) * font_size
   height = DIGIT_HEIGHT * font_size
   if (self%readout_size > 0.0_R8P) then
      height = self%readout_size
   elseif (fill) then
      height = filling_height()
   endif
   call measure(height, sizes, block)
   select case (trim(self%readout_h))
   case ('right')
      left = area(2) - block(1)
   case ('center')
      left = 0.5_R8P * (area(1) + area(2) - block(1))
   case default
      left = area(1)
   endselect
   select case (trim(self%readout_v))
   case ('bottom')
      top = area(4) - block(2)
   case ('center')
      top = 0.5_R8P * (area(3) + area(4) - block(2))
   case default
      top = area(3)
   endselect
   if (.not. fill) then
      ! inside the plot area, the window clear of its border by a text cell at least: on a text device a smaller inset
      ! puts the window on the border row or column
      inset = [2.0_R8P * font_size, 2.0_R8P * LINE_HEIGHT * font_size]
      left = left + merge(-inset(1), merge(0.0_R8P, inset(1), trim(self%readout_h) == 'center'), &
                          trim(self%readout_h) == 'right')
      top = top + merge(-inset(2), merge(0.0_R8P, inset(2), trim(self%readout_v) == 'center'), &
                        trim(self%readout_v) == 'bottom')
   endif
   call backend%begin_group('fs-readouts')
   ! the window padding, a text cell, keeps the label off the window border on a text device too
   pad = [font_size, LINE_HEIGHT * font_size]
   if (.not. fill .and. self%readout_opaque) call backend%rect(left - pad(1), top - pad(2), block(1) + 2.0_R8P * pad(1), &
                                                               block(2) + 2.0_R8P * pad(2), FRAME_COLOR, WINDOW_FILL, &
                                                               1.0_R8P)
   p = merge(left, top, along == 1_I4P)
   do r = 1_I4P, size(which, kind=I4P)
      associate(series => self%series(which(r)))
         if (along == 1_I4P) then
            call backend%readout(p, top, height, glasses(r)%masks, series%title, glasses(r)%prefix, glasses(r)%suffix, &
                                 series%style%color, font_size)
         else
            call backend%readout(left, p, height, glasses(r)%masks, series%title, glasses(r)%prefix, glasses(r)%suffix, &
                                 series%style%color, font_size)
         endif
      endassociate
      p = p + sizes(along, r) + spacing
   enddo
   call backend%end_group
   contains
      subroutine measure(h, extents, total)
      !< Size of each readout and of the block at digit height `h`.
      real(R8P),              intent(in)  :: h          !< Digit height [px].
      real(R8P), allocatable, intent(out) :: extents(:,:) !< Width and height of each readout [px].
      real(R8P),              intent(out) :: total(2)   !< Block width and height [px].
      integer(I4P)                        :: k          !< Readout counter.

      allocate(extents(2, size(which)))
      do k = 1_I4P, size(which, kind=I4P)
         extents(:, k) = backend%readout_extent(h, size(glasses(k)%masks, kind=I4P), self%series(which(k))%title, &
                                                glasses(k)%prefix, glasses(k)%suffix, font_size)
      enddo
      total(along) = sum(extents(along, :)) + real(size(which) - 1, R8P) * spacing
      total(3_I4P - along) = maxval(extents(3_I4P - along, :))
      endsubroutine measure

      function filling_height() result(h)
      !< Largest digit height whose block fits `area`: readout sizes are affine in the digit height, measured at two
      !< heights; a device whose readouts do not grow (text) keeps the default.
      real(R8P)              :: h       !< Digit height [px].
      real(R8P), allocatable :: e1(:,:) !< Readout sizes at a unit height [px].
      real(R8P), allocatable :: e2(:,:) !< Readout sizes at twice the unit height [px].
      real(R8P)              :: t1(2)   !< Block size at a unit height [px].
      real(R8P)              :: t2(2)   !< Block size at twice the unit height [px].
      real(R8P)              :: room(2) !< Box width and height [px].
      integer(I4P)           :: d       !< Direction counter.

      call measure(font_size, e1, t1)
      call measure(2.0_R8P * font_size, e2, t2)
      room = [area(2) - area(1), area(4) - area(3)]
      h = huge(1.0_R8P)
      do d = 1_I4P, 2_I4P
         ! the block size along the stack is the sum of affine sizes (affine); across it, the largest one: bound each
         if (d == along) then
            call bound(t1(d), t2(d), room(d), h)
         else
            do s = 1_I4P, size(which, kind=I4P)
               call bound(e1(d, s), e2(d, s), room(d), h)
            enddo
         endif
      enddo
      if (h == huge(1.0_R8P)) h = DIGIT_HEIGHT * font_size
      h = max(h, font_size)
      endfunction filling_height

      pure subroutine bound(at1, at2, room, h)
      !< Lower `h` to the height whose size, `at1` at one font size and `at2` at two, reaches `room`.
      real(R8P), intent(in)    :: at1   !< Size at a digit height of one font size [px].
      real(R8P), intent(in)    :: at2   !< Size at a digit height of two font sizes [px].
      real(R8P), intent(in)    :: room  !< Room [px].
      real(R8P), intent(inout) :: h     !< Digit height [px].
      real(R8P)                :: slope !< Size per digit height.

      slope = (at2 - at1) / font_size
      if (slope > 0.0_R8P) h = min(h, font_size + (room - at1) / slope)
      endsubroutine bound
   endsubroutine draw_readouts

   pure subroutine key_layout(self, backend, font_size, room, grid, extent)
   !< Key grid and size: entries (titled series), columns (1, or as many as `room` holds when horizontal) and rows;
   !< each entry is the widest title, a gap and the sample, with a gap between entries.
   class(axes_object),    intent(in)  :: self      !< Panel.
   class(backend_object), intent(in)  :: backend   !< Output device, for text widths.
   real(R8P),             intent(in)  :: font_size !< Font size [px].
   real(R8P),             intent(in)  :: room      !< Width available to a row of entries [px].
   integer(I4P),          intent(out) :: grid(3)   !< Entries, columns, rows.
   real(R8P),             intent(out) :: extent(2) !< Key width and height [px].
   real(R8P)                          :: entry     !< Entry width, spacing included [px].
   integer(I4P)                       :: s         !< Series counter.

   grid = [0_I4P, 1_I4P, 0_I4P]
   entry = 0.0_R8P
   if (allocated(self%series)) then
      do s = 1_I4P, size(self%series, kind=I4P)
         if (len(self%series(s)%title) == 0 .or. self%is_readout(s)) cycle
         grid(1) = grid(1) + 1_I4P
         entry = max(entry, backend%text_width(self%series(s)%title, '', font_size))
      enddo
   endif
   ! one font size of slack: vector devices only estimate text widths, and wide glyphs (m, w) exceed the estimate
   entry = entry + font_size + GAP + SAMPLE_LENGTH * font_size + GAP
   if (self%key_horizontal .and. grid(1) > 0_I4P) grid(2) = max(1_I4P, min(grid(1), int((room + GAP) / entry, I4P)))
   grid(3) = (grid(1) + grid(2) - 1_I4P) / grid(2)
   extent = [real(grid(2), R8P) * entry - GAP, real(grid(3), R8P) * LINE_HEIGHT * font_size]
   endsubroutine key_layout

   pure function key_place(self) result(place)
   !< Where the key lies: `inside` the plot area, in the `left` or `right` margin, `top` (above the plot) or `bottom`
   !< (below it); outside and centred both ways it stays inside, as gnuplot.
   class(axes_object), intent(in) :: self  !< Panel.
   character(len=6)               :: place !< Place.

   place = 'inside'
   if (len_trim(self%key_margin) > 0) then
      place = self%key_margin
   elseif (self%key_outside) then
      if (trim(self%key_h) /= 'center') then
         place = self%key_h
      elseif (trim(self%key_v) /= 'center') then
         place = self%key_v
      endif
   endif
   endfunction key_place

   subroutine draw_series(self, backend, s, yaxis)
   !< Draw the `s`-th series in the plot area against its vertical axis `yaxis`; unplaceable points (NaN, non-positive
   !< on log axes) break the line.
   class(axes_object),    intent(in)    :: self     !< Panel.
   class(backend_object), intent(inout) :: backend  !< Output device.
   integer(I4P),          intent(in)    :: s        !< Series index.
   type(axis_object),     intent(in)    :: yaxis    !< Vertical axis of the series.
   logical, allocatable                 :: valid(:) !< Placeable points.
   real(R8P), allocatable               :: u(:)     !< Unit abscissae.
   real(R8P), allocatable               :: v(:)     !< Unit ordinates.
   integer(I4P)                         :: n        !< Number of points.
   integer(I4P)                         :: i1       !< First point of a run.
   integer(I4P)                         :: i2       !< Last point of a run.

   associate(series => self%series(s))
      n = size(series%x, kind=I4P)
      valid = series%valid(self%xaxis, yaxis)
      allocate(u(n), v(n))
      u = 0.0_R8P
      v = 0.0_R8P
      where (valid)
         u = self%xaxis%to_unit(series%x)
         v = yaxis%to_unit(series%y)
      endwhere
      if (series%style%with == WITH_BOXES .or. series%style%with == WITH_HISTOGRAMS) call draw_boxes
      if (series%style%with == WITH_FILLEDCURVES) call draw_fill
      if (series%style%draws_lines()) then
         i1 = 1_I4P
         do while (i1 <= n)
            if (.not. valid(i1)) then
               i1 = i1 + 1_I4P
               cycle
            endif
            i2 = i1
            do while (i2 < n)
               if (.not. valid(i2 + 1_I4P)) exit
               i2 = i2 + 1_I4P
            enddo
            if (i2 > i1) call backend%data_polyline(u(i1:i2), v(i1:i2), series%style%color, series%style%linewidth, &
                                                    series%style%dasharray())
            i1 = i2 + 1_I4P
         enddo
      endif
      if (series%style%draws_ybars()) call draw_bars(series%ylow, series%yhigh, yaxis, .true.)
      if (series%style%draws_xbars()) call draw_bars(series%xlow, series%xhigh, self%xaxis, .false.)
      if (series%style%draws_points() .and. any(valid)) &
         call backend%data_dots(pack(u, valid), pack(v, valid), series%style%color, series%style%point_diameter(), &
                                pt=series%style%pointtype, line_width=series%style%linewidth)
   endassociate
   contains
      subroutine draw_boxes
      !< One polygon per placeable box, from its baseline (0, or the axis bottom on a log axis) to its value; with
      !< `segments N`, the column of N cells over the y range, the ones the box covers at least half lit, the others
      !< ghosts.
      real(R8P) :: v0 !< Unit ordinate of the baseline.
      integer(I4P) :: i !< Box counter.

      associate(series => self%series(s))
         do i = 1_I4P, n
            if (.not. valid(i)) cycle
            if (.not. (self%xaxis%accepts(series%xlow(i)) .and. self%xaxis%accepts(series%xhigh(i)))) cycle
            v0 = -1.0_R8P
            if (yaxis%accepts(series%ylow(i))) v0 = yaxis%to_unit(series%ylow(i))
            if (series%style%segments > 0_I4P) then
               call draw_cells(self%xaxis%to_unit(series%xlow(i)), self%xaxis%to_unit(series%xhigh(i)), v0, v(i))
               cycle
            endif
            call backend%data_polygon([self%xaxis%to_unit(series%xlow(i)), self%xaxis%to_unit(series%xhigh(i)), &
                                       self%xaxis%to_unit(series%xhigh(i)), self%xaxis%to_unit(series%xlow(i))], &
                                      [v0, v0, v(i), v(i)], series%style%fill_color(), series%style%density, &
                                      series%style%stroke_color(), series%style%linewidth)
         enddo
      endassociate
      endsubroutine draw_boxes

      subroutine draw_cells(u1, u2, v0, v1)
      !< The cells of a segmented column between `u1` and `u2`: N cells over the unit height, each inset by an eighth of
      !< its height top and bottom and a tenth of the column on each side (touching boxes stay apart columns); lit when
      !< the box from `v0` to `v1` covers at least half of it, else a ghost.
      real(R8P), intent(in) :: u1   !< Column left [unit].
      real(R8P), intent(in) :: u2   !< Column right [unit].
      real(R8P), intent(in) :: v0   !< Box base [unit].
      real(R8P), intent(in) :: v1   !< Box top [unit].
      real(R8P)             :: h    !< Cell height [unit].
      real(R8P)             :: c0   !< Cell bottom [unit].
      real(R8P)             :: c1   !< Cell top [unit].
      real(R8P)             :: inset !< Cell inset, top and bottom [unit].
      real(R8P)             :: a    !< Cell left [unit].
      real(R8P)             :: b    !< Cell right [unit].
      integer(I4P)          :: c    !< Cell counter.

      associate(series => self%series(s))
         h = 1.0_R8P / real(series%style%segments, R8P)
         inset = 0.125_R8P * h
         a = u1 + 0.1_R8P * (u2 - u1)
         b = u2 - 0.1_R8P * (u2 - u1)
         do c = 0_I4P, series%style%segments - 1_I4P
            c0 = real(c, R8P) * h
            c1 = c0 + h
            if (min(max(v0, v1), c1) - max(min(v0, v1), c0) >= 0.5_R8P * h) then
               call backend%data_polygon([a, b, b, a], [c0 + inset, c0 + inset, c1 - inset, c1 - inset], &
                                         series%style%fill_color(), series%style%density, series%style%stroke_color(), &
                                         series%style%linewidth)
            else
               call backend%data_polygon([a, b, b, a], [c0 + inset, c0 + inset, c1 - inset, c1 - inset], &
                                         series%style%color, 1.0_R8P, 'none', 0.0_R8P, ghost=.true.)
            endif
         enddo
      endassociate
      endsubroutine draw_cells

      subroutine draw_fill
      !< One polygon per run of placeable points: the curve and back along the baseline or the lower curve, or the
      !< curve closed on itself.
      logical, allocatable   :: ok(:) !< Points placeable with their lower end.
      real(R8P), allocatable :: w(:)  !< Unit ordinates of the lower ends.
      integer(I4P)           :: a     !< First point of a run.
      integer(I4P)           :: b     !< Last point of a run.

      associate(series => self%series(s))
         ok = valid
         allocate(w(n))
         w = 0.0_R8P
         if (allocated(series%ylow)) then
            ok = ok .and. yaxis%accepts(series%ylow)
            where (ok) w = yaxis%to_unit(series%ylow)
         endif
         a = 1_I4P
         do while (a <= n)
            if (.not. ok(a)) then
               a = a + 1_I4P
               cycle
            endif
            b = a
            do while (b < n)
               if (.not. ok(b + 1_I4P)) exit
               b = b + 1_I4P
            enddo
            if (b > a) then
               if (allocated(series%ylow)) then
                  call backend%data_polygon([u(a:b), u(b:a:-1)], [v(a:b), w(b:a:-1)], series%style%fill_color(), &
                                            series%style%density, 'none', 0.0_R8P)
               else
                  call backend%data_polygon(u(a:b), v(a:b), series%style%fill_color(), series%style%density, 'none', &
                                            0.0_R8P)
               endif
            endif
            a = b + 1_I4P
         enddo
      endassociate
      endsubroutine draw_fill

      subroutine draw_bars(low, high, axis, vertical)
      !< Error bars of the placeable points whose both ends are placeable on `axis`.
      real(R8P),         intent(in) :: low(:)   !< Bar starts.
      real(R8P),         intent(in) :: high(:)  !< Bar ends.
      type(axis_object), intent(in) :: axis     !< Axis of the bars.
      logical,           intent(in) :: vertical !< Vertical bars.
      logical, allocatable          :: ok(:)    !< Drawn bars.
      real(R8P), allocatable        :: a(:)     !< Unit bar starts.
      real(R8P), allocatable        :: b(:)     !< Unit bar ends.

      ok = valid .and. axis%accepts(low) .and. axis%accepts(high)
      if (.not. any(ok)) return
      a = axis%to_unit(pack(low, ok))
      b = axis%to_unit(pack(high, ok))
      associate(series => self%series(s))
         if (vertical) then
            call backend%data_bars(pack(u, ok), a, pack(u, ok), b, series%style%color, series%style%linewidth, &
                                   CAP_LENGTH, .true.)
         else
            call backend%data_bars(a, pack(v, ok), b, pack(v, ok), series%style%color, series%style%linewidth, &
                                   CAP_LENGTH, .false.)
         endif
      endassociate
      endsubroutine draw_bars
   endsubroutine draw_series

   subroutine layout_histograms(all, rowstacked, gap, boxwidth)
   !< Bars of every histogram series of `all` from their `values`: clustered side by side in each row, or stacked by
   !< row (positive values up from 0, negative ones down, each sign on its own stack). A module procedure on the series
   !< array, not a binding: gfortran 16 corrupts the descriptor of `self%series` reached through the class dummy after
   !< its reallocation by `add_series`.
   type(series_object), intent(inout) :: all(:)     !< Series of the panel.
   logical,             intent(in)    :: rowstacked !< Stacked by row, else clustered.
   real(R8P),           intent(in)    :: gap        !< Gap between clusters [bar slots].
   real(R8P),           intent(in)    :: boxwidth   !< Bar width factor, 0 for 1.
   real(R8P), allocatable             :: up(:)      !< Top of the positive stack of each row.
   real(R8P), allocatable             :: down(:)    !< Bottom of the negative stack of each row.
   real(R8P)                          :: slot       !< Clustered slot width.
   real(R8P)                          :: scale      !< Bar width factor.
   real(R8P)                          :: centre     !< Bar centre offset from its row.
   integer(I4P)                       :: k          !< Histogram series.
   integer(I4P)                       :: j          !< Histogram series counter.
   integer(I4P)                       :: s          !< Series counter.
   integer(I4P)                       :: i          !< Row counter.
   integer(I4P)                       :: n          !< Rows.

   k = 0_I4P
   n = 0_I4P
   do s = 1_I4P, size(all, kind=I4P)
      if (all(s)%style%with /= WITH_HISTOGRAMS) cycle
      k = k + 1_I4P
      n = max(n, size(all(s)%values, kind=I4P))
   enddo
   allocate(up(n), down(n))
   up = 0.0_R8P
   down = 0.0_R8P
   scale = 1.0_R8P
   if (boxwidth > 0.0_R8P) scale = boxwidth
   slot = 1.0_R8P / (real(k, R8P) + gap)
   j = 0_I4P
   do s = 1_I4P, size(all, kind=I4P)
      if (all(s)%style%with /= WITH_HISTOGRAMS) cycle
      j = j + 1_I4P
      n = size(all(s)%values, kind=I4P)
      if (allocated(all(s)%xlow)) deallocate(all(s)%xlow)
      if (allocated(all(s)%xhigh)) deallocate(all(s)%xhigh)
      if (allocated(all(s)%ylow)) deallocate(all(s)%ylow)
      allocate(all(s)%xlow(n), all(s)%xhigh(n), all(s)%ylow(n))
      if (rowstacked) then
         do i = 1_I4P, n
            all(s)%xlow(i) = all(s)%x(i) - 0.5_R8P * scale
            all(s)%xhigh(i) = all(s)%x(i) + 0.5_R8P * scale
            all(s)%ylow(i) = 0.0_R8P
            all(s)%y(i) = all(s)%values(i)
            if (.not. ieee_is_finite(all(s)%values(i))) cycle
            if (all(s)%values(i) >= 0.0_R8P) then
               all(s)%ylow(i) = up(i)
               up(i) = up(i) + all(s)%values(i)
               all(s)%y(i) = up(i)
            else
               all(s)%ylow(i) = down(i)
               down(i) = down(i) + all(s)%values(i)
               all(s)%y(i) = down(i)
            endif
         enddo
      else
         centre = (real(j, R8P) - 0.5_R8P * real(k + 1_I4P, R8P)) * slot
         do i = 1_I4P, n
            all(s)%xlow(i) = all(s)%x(i) + centre - 0.5_R8P * slot * scale
            all(s)%xhigh(i) = all(s)%x(i) + centre + 0.5_R8P * slot * scale
            all(s)%ylow(i) = 0.0_R8P
            all(s)%y(i) = all(s)%values(i)
         enddo
      endif
   enddo
   endsubroutine layout_histograms

   elemental function is_readout(self, s) result(is)
   !< Whether the `s`-th series is a readout.
   class(axes_object), intent(in) :: self !< Panel.
   integer(I4P),       intent(in) :: s    !< Series index.
   logical                        :: is   !< Readout.

   is = self%series(s)%style%with == WITH_READOUT
   endfunction is_readout

   pure function has_title(self) result(has)
   !< Whether the panel has a non-empty title.
   class(axes_object), intent(in) :: self !< Panel.
   logical                        :: has  !< The title is set.

   has = .false.
   if (allocated(self%title)) has = len(self%title) > 0
   endfunction has_title

   pure function place_plot_area(self, backend, x0, y0, width, height, font_size, above) result(area)
   !< Plot area left by the margins that tick labels, axis labels, title and a key `above` need, measured by the device.
   class(axes_object),    intent(in) :: self       !< Panel.
   class(backend_object), intent(in) :: backend    !< Output device, for text widths.
   real(R8P),          intent(in) :: x0         !< Box left side [px].
   real(R8P),          intent(in) :: y0         !< Box top side [px].
   real(R8P),          intent(in) :: width      !< Box width [px].
   real(R8P),          intent(in) :: height     !< Box height [px].
   real(R8P),          intent(in) :: font_size  !< Font size [px].
   real(R8P),          intent(in) :: above      !< Room for a key between the title and the plot [px].
   real(R8P)                      :: area(4)    !< Plot area: left, right, top, bottom [px].
   real(R8P)                      :: margins(4) !< Left, right, top, bottom margins [px].
   real(R8P)                      :: y2_margin  !< Right margin the second y axis needs [px].
   integer(I4P)                   :: t          !< Tick counter.

   margins(1) = PAD + labels_width(self%yaxis) + GAP
   if (self%yaxis%has_label()) margins(1) = margins(1) + LINE_HEIGHT * font_size + GAP
   ! the rightmost x tick label is centred on the border: half of it sticks out
   margins(2) = PAD
   do t = 1_I4P, size(self%xaxis%ticks, kind=I4P)
      if (self%xaxis%ticks(t)%major) margins(2) = max(margins(2), &
         0.5_R8P * backend%text_width(self%xaxis%ticks(t)%label, self%xaxis%ticks(t)%sup, font_size))
   enddo
   if (self%y2_active .or. self%y2axis%has_label()) then
      y2_margin = PAD
      if (self%y2_active) then
         if (any(self%y2axis%ticks%major)) y2_margin = y2_margin + labels_width(self%y2axis) + GAP
      endif
      if (self%y2axis%has_label()) y2_margin = y2_margin + LINE_HEIGHT * font_size + GAP
      margins(2) = max(margins(2), y2_margin)
   endif
   margins(3) = PAD + 0.5_R8P * font_size
   if (self%has_title()) margins(3) = margins(3) + LINE_HEIGHT * font_size + GAP
   margins(3) = margins(3) + above
   margins(4) = PAD + GAP + LINE_HEIGHT * font_size
   if (self%xaxis%has_label()) margins(4) = margins(4) + LINE_HEIGHT * font_size + GAP
   area = [x0 + margins(1), x0 + width - margins(2), y0 + margins(3), y0 + height - margins(4)]
   contains
      pure function labels_width(axis) result(widest)
      !< Width of the widest major tick label of a vertical `axis` [px], measured by the device.
      type(axis_object), intent(in) :: axis   !< Axis.
      real(R8P)                     :: widest !< Width [px].
      integer(I4P)                  :: k      !< Tick counter.

      widest = 0.0_R8P
      do k = 1_I4P, size(axis%ticks, kind=I4P)
         if (axis%ticks(k)%major) widest = max(widest, backend%text_width(axis%ticks(k)%label, axis%ticks(k)%sup, &
                                                                          font_size))
      enddo
      endfunction labels_width
   endfunction place_plot_area

   subroutine setup_axes(self, area)
   !< Effective ranges and ticks for the plot area: x from every series, each y axis from its own series and the points
   !< inside the x range, as gnuplot. The second y axis is active when it has data or both its ends are fixed.
   class(axes_object), intent(inout) :: self      !< Panel.
   real(R8P),          intent(in)    :: area(4)   !< Plot area: left, right, top, bottom [px].
   real(R8P)                         :: xmin      !< Smallest abscissa.
   real(R8P)                         :: xmax      !< Largest abscissa.
   real(R8P)                         :: ymin(2)   !< Smallest ordinate, per y axis.
   real(R8P)                         :: ymax(2)   !< Largest ordinate, per y axis.
   logical                           :: found(2)  !< Any placeable point, per y axis.
   integer(I4P)                      :: s         !< Series counter.
   integer(I4P)                      :: k         !< y axis of the series: 1 or 2.

   call self%data_extent(xmin, xmax, ymin, ymax, found)
   call collect_labels
   call self%xaxis%setup(xmin, xmax, any(found), area(2) - area(1))
   xmin = huge(1.0_R8P)
   xmax = -huge(1.0_R8P)
   ymin = huge(1.0_R8P)
   ymax = -huge(1.0_R8P)
   found = .false.
   do s = 1_I4P, size(self%series, kind=I4P)
      if (self%is_readout(s)) cycle
      k = merge(2_I4P, 1_I4P, self%series(s)%y2)
      if (k == 2_I4P) then
         call self%series(s)%extent(self%xaxis, self%y2axis, xmin, xmax, ymin(k), ymax(k), found(k), &
                                    xwindow=[self%xaxis%lo, self%xaxis%hi])
      else
         call self%series(s)%extent(self%xaxis, self%yaxis, xmin, xmax, ymin(k), ymax(k), found(k), &
                                    xwindow=[self%xaxis%lo, self%xaxis%hi])
      endif
   enddo
   call self%yaxis%setup(ymin(1), ymax(1), found(1), area(4) - area(3))
   self%y2_active = found(2) .or. (self%y2axis%min_fixed .and. self%y2axis%max_fixed)
   if (self%y2_active) call self%y2axis%setup(ymin(2), ymax(2), found(2), area(4) - area(3))
   contains
      subroutine collect_labels
      !< Text labels of the abscissae of every series, by value (the first label of a value wins), ascending.
      type(tick_object), allocatable :: labels(:) !< Labels.
      type(tick_object)              :: t         !< Swap buffer.
      integer(I4P)                   :: i         !< Point counter.
      integer(I4P)                   :: j         !< Sort counter.
      integer(I4P)                   :: n         !< Labels.

      allocate(labels(0))
      do s = 1_I4P, size(self%series, kind=I4P)
         if (.not. allocated(self%series(s)%xlabels)) cycle
         associate(series => self%series(s))
            do i = 1_I4P, size(series%x, kind=I4P)
               if (len_trim(series%xlabels(i)) == 0 .or. .not. ieee_is_finite(series%x(i))) cycle
               if (size(labels) > 0) then
                  if (any(labels%value == series%x(i))) cycle
               endif
               labels = [labels, tick_object(value=series%x(i), major=.true., label=trim(series%xlabels(i)), sup='')]
            enddo
         endassociate
      enddo
      n = size(labels, kind=I4P)
      do i = 2_I4P, n
         t = labels(i)
         j = i - 1_I4P
         do while (j >= 1_I4P)
            if (labels(j)%value <= t%value) exit
            labels(j + 1_I4P) = labels(j)
            j = j - 1_I4P
         enddo
         labels(j + 1_I4P) = t
      enddo
      call move_alloc(labels, self%xaxis%labels)
      endsubroutine collect_labels
   endsubroutine setup_axes

   pure subroutine axes_names(names, x, y, y2, bad)
   !< Axes named by gnuplot's concatenated axis names, e.g. `x`, `y2`, `xy`, `xyy2`: each found one sets its flag (the
   !< others are left unchanged); `bad` is the first unsupported rest (`x2` included), empty if none.
   character(len=*),              intent(in)    :: names !< Axis names.
   logical,                       intent(inout) :: x     !< x named.
   logical,                       intent(inout) :: y     !< y named.
   logical,                       intent(inout) :: y2    !< y2 named.
   character(len=:), allocatable, intent(out)   :: bad   !< Unsupported rest, empty if none.
   integer(I4P)                                 :: i     !< Character counter.
   logical                                      :: two   !< A `2` follows.

   bad = ''
   i = 1_I4P
   do while (i <= len(names))
      two = .false.
      if (i < len(names)) two = names(i + 1:i + 1) == '2'
      if (names(i:i) == 'y' .and. two) then
         y2 = .true.
      elseif (names(i:i) == 'x' .and. .not. two) then
         x = .true.
      elseif (names(i:i) == 'y') then
         y = .true.
      else
         bad = names(i:)
         return
      endif
      i = i + merge(2_I4P, 1_I4P, two)
   enddo
   endsubroutine axes_names

   pure subroutine readout_position(words, horizontal, vertical, layout, bad)
   !< Update the readout block position from the `set key` position words inside the plot area (see `key_position`):
   !< `outside`, `below` and `above` are not readout positions.
   character(len=*),              intent(in)    :: words      !< Blank separated words.
   character(len=6),              intent(inout) :: horizontal !< Horizontal position.
   character(len=6),              intent(inout) :: vertical   !< Vertical position.
   logical,                       intent(inout) :: layout     !< Readouts side by side.
   character(len=:), allocatable, intent(out)   :: bad        !< First word not a position, empty if none.
   logical                                      :: outside    !< Outside the plot area.
   character(len=6)                             :: margin     !< Margin.

   outside = .false.
   margin = ''
   call key_position(words, horizontal, vertical, outside, margin, layout, bad)
   if (len(bad) == 0 .and. (outside .or. len_trim(margin) > 0)) &
      bad = 'outside/above/below (readouts lie inside the plot area)'
   endsubroutine readout_position

   pure subroutine key_position(words, horizontal, vertical, outside, margin, layout, bad)
   !< Update the key position from gnuplot `set key` position words, applied in order: `left`, `right`, `top`,
   !< `bottom`, and `center`, which centres the direction not given yet by `words` (both if none, as gnuplot);
   !< `inside`, `outside`; `below` (`under`) and `above` (`over`), centred rows below or above the plot; `horizontal`,
   !< `vertical` the layout of the entries.
   character(len=*),              intent(in)    :: words      !< Blank separated words.
   character(len=6),              intent(inout) :: horizontal !< Horizontal position.
   character(len=6),              intent(inout) :: vertical   !< Vertical position.
   logical,                       intent(inout) :: outside    !< Outside the plot area.
   character(len=6),              intent(inout) :: margin     !< `top`, `bottom` or empty.
   logical,                       intent(inout) :: layout     !< Entries side by side.
   character(len=:), allocatable, intent(out)   :: bad        !< First word not a position, empty if none.
   character(len=:), allocatable                :: word       !< Current word.
   integer(I4P)                                 :: start      !< Word start.
   integer(I4P)                                 :: finish     !< Word end.
   logical                                      :: h_set      !< Horizontal position given.
   logical                                      :: v_set      !< Vertical position given.

   bad = ''
   h_set = .false.
   v_set = .false.
   start = 1_I4P
   do while (start <= len(words))
      if (words(start:start) == ' ') then
         start = start + 1_I4P
         cycle
      endif
      finish = index(words(start:), ' ', kind=I4P)
      if (finish == 0_I4P) then
         finish = len(words, kind=I4P)
      else
         finish = start + finish - 2_I4P
      endif
      word = words(start:finish)
      start = finish + 1_I4P
      select case (word)
      case ('left', 'right')
         horizontal = word
         h_set = .true.
      case ('top', 'bottom')
         vertical = word
         v_set = .true.
      case ('center')
         if (h_set .and. .not. v_set) then
            vertical = 'center'
         elseif (v_set .and. .not. h_set) then
            horizontal = 'center'
         else
            horizontal = 'center'
            vertical = 'center'
         endif
      case ('inside', 'ins')
         outside = .false.
         margin = ''
      case ('outside', 'out')
         outside = .true.
         margin = ''
      case ('below', 'under', 'above', 'over')
         margin = merge('bottom', 'top   ', word == 'below' .or. word == 'under')
         horizontal = 'center'
         h_set = .false.
         layout = .true.
      case ('horizontal', 'horiz')
         layout = .true.
      case ('vertical', 'vert')
         layout = .false.
      case default
         bad = word
         return
      endselect
   enddo
   endsubroutine key_position
endmodule foresight_axes
