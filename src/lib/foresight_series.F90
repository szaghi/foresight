!< foresight_series, a plotted data series.
module foresight_series
!< foresight_series, a plotted data series.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite
use foresight_font, only : font_object
use penf, only : I4P, R8P
use foresight_axis, only : axis_object
use foresight_style, only : style_object, WITH_ELLIPSES, WITH_HISTOGRAMS, WITH_VECTORS

implicit none
private
public :: series_object
public :: push
public :: LABEL_LEN

integer(I4P), parameter :: LABEL_LEN = 128_I4P !< Longest text label of a point (`xtic`, `labels`), longer ones cut;
                                               !< fixed: nvfortran 26.9 corrupts the heap assigning and copying
                                               !< deferred-length character array components.

interface push
   !< Append an item through a temporary: nvfortran 26.9 corrupts `list = [list, item]` (and any `list = f(list)`)
   !< when the items hold deferred-length characters.
   module procedure push_series
endinterface push

type :: series_object
   !< Data series.
   real(R8P), allocatable        :: x(:)  !< Abscissae.
   real(R8P), allocatable        :: y(:)  !< Ordinates.
   real(R8P), allocatable        :: xlow(:)  !< Horizontal error bar starts, allocated for x error bars.
   real(R8P), allocatable        :: xhigh(:) !< Horizontal error bar ends, allocated for x error bars.
   real(R8P), allocatable        :: ylow(:)  !< Vertical error bar starts, allocated for y error bars.
   real(R8P), allocatable        :: yhigh(:) !< Vertical error bar ends, allocated for y error bars.
   logical                       :: title_plain = .false. !< The title as it is, not enhanced text (an automatic
                                                          !< title, gnuplot's noenhanced).
   character(len=:), allocatable :: title !< Key title, empty for none; the label of a readout.
   character(len=:), allocatable :: format !< Readout format (foresight_readout), readouts only.
   character(len=LABEL_LEN), allocatable :: xlabels(:) !< Text labels of the abscissae (`xtic(N)`), blank for none.
   character(len=2)              :: label_axis = 'x' !< Axis the text labels mark: `x` (`xtic`), `x2` (`x2tic`) at the
                                                     !< abscissae, `y` (`ytic`), `y2` (`y2tic`) at the ordinates.
   integer(I4P)                  :: pointinterval = 1_I4P !< A point marker every N points, the first one included
                                                          !< (gnuplot `pointinterval`).
   character(len=24), allocatable :: own_colors(:) !< A histogram's colors per row (`lc variable`), kept through its
                                                   !< layouts (which rebuild `colors`).
   character(len=24), allocatable :: colors(:) !< Color of each point (gnuplot `lc variable`), unallocated for none;
                                               !< of `lc palette z`, set at each rendering.
   integer(I4P)                  :: palette_mode = 0_I4P !< Color from the palette (gnuplot `lc palette`): 0 none, 1 a
                                                         !< value per point (`z`, `zvalues`), 2 a color axis value
                                                         !< (`cb`), 3 a fraction of the palette (`frac`); `value`.
   real(R8P)                     :: palette_value = 0.0_R8P !< The `cb` value or the `frac` fraction.
   real(R8P), allocatable        :: zvalues(:) !< Palette value of each point (`lc palette z`), unallocated for none.
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
   real(R8P), allocatable        :: tips(:,:)  !< Second number pair per point (2, point): the tips of `vectors`, the
                                               !< length and angle [deg] of `arrows`.
   real(R8P), allocatable        :: shape(:,:) !< Ellipse major, minor diameter and angle [deg] (3, point); NaN
                                               !< diameters for the default size.
   integer(I4P)                  :: head = 1_I4P     !< Arrowheads: 0 none, 1 end, 2 start, 3 both.
   logical                       :: head_filled = .false. !< Filled arrowheads.
   character(len=LABEL_LEN), allocatable :: texts(:) !< Texts of `labels`, one per point.
   character(len=6)              :: text_anchor = 'middle' !< Label anchor: start, middle, end.
   real(R8P)                     :: text_rotate = 0.0_R8P  !< Label rotation [deg, counterclockwise].
   real(R8P)                     :: text_offset(2) = 0.0_R8P !< Label offset [characters, y upward].
   character(len=:), allocatable :: text_color !< Label color, the frame color if unallocated.
   type(font_object)             :: font       !< Label font (`with labels font "..."`).
   logical                       :: text_point = .false. !< Labels mark their point.
   integer(I4P)                  :: curve_to = 0_I4P  !< Fill of `filledcurves`: 0 closed, to `ylow` (a line or a
                                                      !< band); 1 to the bottom (gnuplot `x1`), 2 to the top (`x2`),
                                                      !< 3 to the point `curve_point` (`xy=`).
   integer(I4P)                  :: curve_side = 0_I4P !< Fill restricted where the curve is above (1) or below (-1)
                                                       !< its line or second curve; 0 both.
   real(R8P)                     :: curve_point(2) = 0.0_R8P !< Point of `xy=X,Y`.
   real(R8P)                     :: at = 0.0_R8P  !< Position of a parallel axis (gnuplot `at`); 0 for its number.
   integer(I4P)                  :: hist_group = 0_I4P !< Histogram group (gnuplot `newhistogram`), 0 the first.
   real(R8P), allocatable        :: rows(:)           !< Rows of a histogram (its abscissae as given), from 0.
   integer(I4P), allocatable     :: vertex_rows(:)    !< Data row of each vertex of `sectors` (0 for a separator).
   real(R8P), allocatable        :: vertex_centres(:,:) !< Centre (2, vertex) of the sector of each vertex (cartesian
                                                        !< `sectors`; NaN for a separator), for `units xx|yy`.
   logical                       :: hist_at_set = .false. !< The group starts at `hist_at`, else after the previous one.
   real(R8P)                     :: hist_at = 0.0_R8P  !< Start of the histogram group (gnuplot `newhistogram at X`).
   character(len=:), allocatable :: hist_title         !< Title of the histogram group, below the x axis.
   logical                       :: at_set = .false. !< `at` given.
   real(R8P), allocatable        :: channels(:,:,:) !< Red, green, blue, alpha of an RGB image (4, column, row),
                                                    !< 0 to 255 (`grid` holds the red ones); unallocated for a palette
                                                    !< image.
   type(style_object)            :: style !< Drawing style.
   logical                       :: y2 = .false. !< On the second y axis (gnuplot `axes x1y2`), else on the first.
   logical                       :: x2 = .false. !< On the second x axis (gnuplot `axes x2y1`), else on the first.
   logical                       :: spanned = .false. !< The autoscale also includes `span`.
   real(R8P)                     :: span(4) = 0.0_R8P !< Extent beyond the points, x from-to and y from-to: the outer
                                                      !< edges of `bins` and their y = 0, as gnuplot.
   logical                       :: text_boxed = .false. !< Labels in a text box (gnuplot `with labels boxed`).
   real(R8P)                     :: head_size(2) = 0.0_R8P !< Arrowhead length (0: the default head) and angle [deg]
                                                           !< of `vectors` and `arrows` (gnuplot `size L,A`).
   logical                       :: head_fixed = .false.   !< The heads keep their size on short arrows (`fixed`).
   character(len=9)              :: head_system = 'first' !< System of the head length: first, graph, screen,
                                                          !< character.
   integer(I4P)                  :: title_at = 0_I4P !< Title place (gnuplot `title ... at`): 0 the key, 1 before the
                                                     !< first point, 2 after the last one, 3 a page position, 4 a
                                                     !< plot area position (graph coordinates).
   real(R8P)                     :: title_xy(2) = 0.0_R8P !< That position, screen fractions from the bottom left.
   logical                       :: key_mid_palette = .false. !< Key sample in the palette's middle color (gnuplot's
                                                              !< polar gridded surface).
   logical                       :: crisp = .false. !< Polygons drawn with crisp edges, no antialiased seams between
                                                    !< them (gnuplot's svg cells of a polar gridded surface).
   real(R8P),        allocatable :: point_sizes(:)  !< Each point's size (gnuplot `ps variable`), else the style's.
   integer(I4P),     allocatable :: point_types(:)  !< Each point's type (gnuplot `pt variable`; 0 a dot), else
                                                    !< the style's.
   logical                       :: hypertext = .false. !< Labels shown on mouse-over of their points (`hypertext`).
   character(len=:), allocatable :: point_color     !< Color of the points of labels (their `lc`), black if unset.
   integer(I4P)                  :: title_justify = 0_I4P !< `title at beginning|end left|right`: 1 left, 2 right,
                                                          !< 0 the place's own (right before the first point).
   integer(I4P)                  :: pointnumber = 0_I4P !< About N point markers evenly spread, 0 for all (gnuplot
                                                        !< `pointnumber`).
   character(len=2)              :: ellipse_units = 'xy' !< Units of the ellipse diameters: `xy` (major in x, minor
                                                         !< in y), `xx` (both in x), `yy` (both in y).
   real(R8P), allocatable        :: text_rotations(:) !< Rotation of each label [deg] (gnuplot `rotate variable`),
                                                      !< `text_rotate` for all when unallocated.
   integer(I4P), allocatable     :: arrow_heads(:) !< Heads of each arrow (gnuplot `arrowstyle variable`), as `head`;
                                                   !< the series' own for all when unallocated.
   logical, allocatable          :: arrow_filled(:) !< Filled heads of each arrow, as `head_filled`.
   real(R8P), allocatable        :: arrow_widths(:) !< Line width of each arrow [px].
   real(R8P), allocatable        :: arrow_sizes(:,:) !< Head length and angle of each arrow, as `head_size`.
   character(len=9), allocatable :: arrow_systems(:) !< System of each head length, as `head_system`.
   character(len=LABEL_LEN), allocatable :: xlabels2(:) !< Text labels of a second axis (`xtic(..):ytic(..)`).
   character(len=2)              :: label_axis2 = 'y' !< Axis of those labels.
   logical                       :: title_auto = .false. !< The title a script's automatic one (the item as written).
   logical                       :: noautoscale = .false. !< Out of the autoscaling of its axes (gnuplot `noautoscale`).
   logical                       :: gnuplot_sample = .false. !< A script's key sample, as gnuplot 6.0: an arrow for
                                                             !< vectors and arrows, none for labels (their point
                                                             !< with `point`); else the library's line.
   logical                       :: fill_border = .false. !< `filledcurves`: the fill style's border, never drawn by the
                                                          !< library (see `fill_edges`).
   integer(I4P)                  :: fill_edges = 0_I4P !< `filledcurves`: where that border is drawn: 0 nowhere (the
                                                       !< library's), 1 as gnuplot 6.0 (a script's): around the key
                                                       !< sample, and along a closed curve (not its closing side).
   logical                       :: blank_ticks = .false. !< A blank text label is a tick too (a script's `xtic("")`,
                                                          !< the rug, as gnuplot); else no tick (the library's).
   integer(I4P)                  :: spider_group = 0_I4P !< Spider plot group (gnuplot `newspiderplot`), 0 the first:
                                                         !< its series restart at the first axis.
   logical                       :: spider_key = .false. !< A key entry of a spider plot group (gnuplot `keyentry with
                                                         !< spiderplot`), no axis.
   character(len=24)             :: spider_color = '' !< Polygon color of the group (the lc of its first item), blank
                                                      !< for the row linetypes.
   real(R8P)                     :: spider_lw = 0.0_R8P !< Polygon border width of the group (the lw of its first
                                                        !< item), 0 for the spider plot style's.
   logical                       :: radial_bars = .false. !< Error bars of a polar panel: the ends x:y in xlow:ylow and
                                                          !< xhigh:yhigh, drawn along the radius.
   integer(I4P)                  :: colormap = 0_I4P !< Named colormap of the palette colors (the panel's `colormaps`),
                                                     !< 0 for the panel palette.
   real(R8P), allocatable        :: z(:) !< Heights of a 3D series (gnuplot `splot`), one per point (NaN at the
                                         !< breaks between scans, as `x` and `y`); unallocated for a 2D series.
   integer(I4P), allocatable     :: scans(:,:) !< Scans of a 3D series (2, scan): the first and last point of each
                                               !< (gnuplot's iso-curves: a data block, a matrix row, a function line).
   integer(I4P), allocatable     :: scan_sets(:) !< Dataset of each scan, from 0: each a surface of its own (gnuplot).
   integer(I4P)                  :: grid_scans = 0_I4P !< Leading scans making the surface grid; the others are the
                                                       !< cross iso-curves of a function (drawn, not gridded).
   logical                       :: data_scans = .false. !< Scans read from data, which gnuplot keeps last first (its
                                                         !< table order); a function's are in order.
   logical                       :: key_blank = .false. !< A key entry of its title alone, no sample (gnuplot's pm3d
                                                        !< surfaces).
   logical                       :: no_contours = .false. !< No contour lines (gnuplot's item option `nocontours`).
   logical                       :: no_surface = .false.  !< Its surface not drawn (gnuplot's item option `nosurface`).
   logical                       :: masked = .false.      !< Masked by the `with mask` polygons (item option `mask`).
   character(len=:), allocatable :: back_color !< Color of the underside of a surface with `set hidden3d`, unallocated
                                               !< for its own.
   logical                       :: zvalues_rgb = .false. !< `zvalues` are packed colors 0xAARRGGBB (gnuplot's pm3d
                                                          !< `lc rgb variable`), not palette values.
   logical                       :: colors_kept = .false. !< `colors` set per point; the palette paints only the points
                                                          !< of a finite `zvalues` (the color range of pm3d quads).
   logical                       :: no_hidden = .false.   !< Out of the hidden surfaces of `set hidden3d` (item option
                                                          !< `nohidden3d`): drawn as it is.
   character(len=:), allocatable :: key_text !< A text as the key sample (gnuplot's `keyentry "text"`), unallocated if
                                             !< none.
   logical                       :: contour = .false.      !< Contour lines of a surface in a 3D view (drawn without its
                                                           !< surface too).
   logical                       :: contour_base = .false. !< Those on the base plane (`set contour base`).
   logical                       :: contour_labels = .false. !< Its contours drawn as labels of their levels (a function
                                                             !< `with labels`, gnuplot's cntr3d_labels).
   real(R8P), allocatable        :: zlow(:)  !< `with zerrorfill`: the low ends of the z errors.
   real(R8P), allocatable        :: zhigh(:) !< Their high ends.
   logical                       :: zerrorfill = .false. !< `with zerrorfill`: quadrangles from zlow to zhigh between
                                                         !< the points (gnuplot's plot3d_zerrorfill), the line through z.
   logical                       :: contourfill = .false. !< `with contourfill`: pm3d quadrangles clipped to z slices,
                                                          !< each slice in one color (gnuplot's plot3d_contourfill).
   real(R8P), allocatable        :: rgb_values(:) !< The packed colors 0xAARRGGBB of `lc rgb variable` lines (those of an
                                                  !< implicit pm3d surface, gnuplot's color_from_rgbvar).
   logical                       :: pm3d_pending = .false. !< A surface whose pm3d quadrangles a 3D view draws once its
                                                           !< projection is known (view3d_pm3d_quads), not drawn itself.
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
   if (self%spanned) then
      ! the outer bin edges widen x, unless only the y autoscale is asked (a window); y = 0 widens y, as gnuplot.
      ! Inline, not through `widen` with an optional argument: that made nvfortran 26.9 -O2 crash (fort1 signal 11)
      ! on one compilation in three.
      do i = 1_I4P, 2_I4P
         if (.not. present(xwindow) .and. xaxis%accepts(self%span(i))) then
            xmin = min(xmin, self%span(i))
            xmax = max(xmax, self%span(i))
         endif
         if (yaxis%accepts(self%span(2_I4P + i))) then
            ymin = min(ymin, self%span(2_I4P + i))
            ymax = max(ymax, self%span(2_I4P + i))
         endif
      enddo
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
   if (allocated(self%tips) .and. self%style%with == WITH_VECTORS) then
      ends = self%tips(1, :)
      call widen(ends, xaxis, xmin, xmax)
      ends = self%tips(2, :)
      call widen(ends, yaxis, ymin, ymax)
   endif
   if (self%style%with == WITH_ELLIPSES .and. allocated(self%shape)) then
      ! gnuplot's autoscale of ellipses (plot2d.c): half the larger diameter about the centre, times 1.1 on x for
      ! `units xx` and 1.4 on y but for `units yy` (its empirical factors for rotated ellipses on unequal scales)
      do i = 1_I4P, min(size(self%x, kind=I4P), size(self%shape, 2, kind=I4P))
         if (.not. (xaxis%accepts(self%x(i)) .and. yaxis%accepts(self%y(i)))) cycle
         if (.not. all(ieee_is_finite(self%shape(:, i)))) cycle
         if (present(xwindow)) then
            if (self%x(i) < minval(xwindow) .or. self%x(i) > maxval(xwindow)) cycle
         endif
         block
            real(R8P) :: a  !< Semi-major axis.
            real(R8P) :: b  !< Semi-minor axis.
            real(R8P) :: t  !< Angle [rad].
            real(R8P) :: hx !< Half width.
            real(R8P) :: hy !< Half height.

            a = 0.5_R8P * max(self%shape(1, i), self%shape(2, i))
            b = a
            t = 0.0_R8P
            hx = a * merge(1.1_R8P, 1.0_R8P, self%ellipse_units == 'xx')
            hy = b * merge(1.0_R8P, 1.4_R8P, self%ellipse_units == 'yy')
            if (xaxis%accepts(self%x(i) - hx)) xmin = min(xmin, self%x(i) - hx)
            if (xaxis%accepts(self%x(i) + hx)) xmax = max(xmax, self%x(i) + hx)
            if (yaxis%accepts(self%y(i) - hy)) ymin = min(ymin, self%y(i) - hy)
            if (yaxis%accepts(self%y(i) + hy)) ymax = max(ymax, self%y(i) + hy)
         endblock
      enddo
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

   pure subroutine push_series(list, item)
   !< Append `item` to `list` (an unallocated `list` is empty), through a temporary: see `push`.
   type(series_object), allocatable, intent(inout) :: list(:)  !< List.
   type(series_object),              intent(in)    :: item     !< New item.
   type(series_object), allocatable                :: grown(:) !< List, one more.
   integer(I4P)                                    :: n        !< Items before the push.

   n = 0_I4P
   if (allocated(list)) n = size(list, kind=I4P)
   allocate(grown(n + 1_I4P))
   if (n > 0_I4P) grown(1_I4P:n) = list
   grown(n + 1_I4P) = item
   call move_alloc(grown, list)
   endsubroutine push_series
endmodule foresight_series
