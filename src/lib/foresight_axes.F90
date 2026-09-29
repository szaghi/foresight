!< foresight_axes, a plot panel: two axes, the plotted series, the key and the decorations.
module foresight_axes
!< foresight_axes, a plot panel: two axes, the plotted series, the key and the decorations.
!<
!< Layout follows gnuplot defaults: full border with inward ticks mirrored on the opposite side, tick labels outside
!< bottom and left, key at the top right inside the plot area with right-aligned titles and the samples on their right.
!< Text extents are estimated from a mean glyph advance, since the viewer renders the glyphs.
use foresight_axis, only : axis_object
use foresight_backend, only : backend_object
use foresight_series, only : series_object
use foresight_style, only : default_color, style_with
use penf, only : I4P, R8P

implicit none
private
public :: axes_object

real(R8P),        parameter :: PAD           = 10.0_R8P  !< Outer padding [px].
real(R8P),        parameter :: TICK_MAJOR    = 6.0_R8P   !< Major tick length [px].
real(R8P),        parameter :: TICK_MINOR    = 3.0_R8P   !< Minor tick length [px].
real(R8P),        parameter :: GAP           = 6.0_R8P   !< Gap between border, tick labels and axis labels [px].
real(R8P),        parameter :: CHAR_WIDTH    = 0.55_R8P  !< Mean glyph advance [font size] (Arial digits: 0.556).
real(R8P),        parameter :: LINE_HEIGHT   = 1.25_R8P  !< Text line height [font size].
real(R8P),        parameter :: SAMPLE_LENGTH = 3.0_R8P   !< Key sample length [font size].
character(len=*), parameter :: FRAME_COLOR   = 'black'   !< Border and tick color.
character(len=*), parameter :: GRID_COLOR    = '#a0a0a0' !< Grid line color.
character(len=*), parameter :: GRID_DASHES   = '2,3'     !< Grid line dash array.

type :: axes_object
   !< Plot panel.
   type(axis_object)                :: xaxis          !< Horizontal axis.
   type(axis_object)                :: yaxis          !< Vertical axis.
   type(series_object), allocatable :: series(:)      !< Plotted series.
   character(len=:), allocatable    :: title          !< Panel title, empty for none.
   logical                          :: grid = .false. !< Draw grid lines at the major ticks.
   logical                          :: key  = .true.  !< Draw the key.
   contains
      procedure, pass(self) :: add_series                  !< Add a data series.
      procedure, pass(self) :: render                      !< Render the panel.
      procedure, pass(self), private :: draw_frame         !< Draw border, ticks, labels and title.
      procedure, pass(self), private :: draw_grid          !< Draw the grid.
      procedure, pass(self), private :: draw_key           !< Draw the key.
      procedure, pass(self), private :: draw_series        !< Draw a series.
      procedure, pass(self), private :: has_title          !< Whether the panel has a title.
      procedure, pass(self), private :: place_plot_area    !< Plot area from the margins.
      procedure, pass(self), private :: setup_axes         !< Effective ranges and ticks.
      procedure, pass(self), private :: ytick_labels_width !< Width of the widest y tick label.
endtype axes_object

contains
   subroutine add_series(self, x, y, title, with, lc, lw, dt, ps)
   !< Add the series (`x`, `y`) with gnuplot-like style options; unset options take gnuplot defaults.
   class(axes_object), intent(inout)        :: self   !< Panel.
   real(R8P),          intent(in)           :: x(:)   !< Abscissae.
   real(R8P),          intent(in)           :: y(:)   !< Ordinates.
   character(len=*),   intent(in), optional :: title  !< Key title, empty or absent for none.
   character(len=*),   intent(in), optional :: with   !< Plotting style: `lines` (default), `points`, `linespoints`.
   character(len=*),   intent(in), optional :: lc     !< Line color (SVG color); default from the gnuplot palette.
   real(R8P),          intent(in), optional :: lw     !< Line width [px].
   integer(I4P),       intent(in), optional :: dt     !< Dash type, 1..5.
   real(R8P),          intent(in), optional :: ps     !< Point size scale factor.
   type(series_object)                      :: series !< New series.

   if (size(x) /= size(y)) error stop 'foresight: plot: x and y have different sizes'
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
   self%series = [self%series, series]
   endsubroutine add_series

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
   integer(I4P)                         :: s         !< Series counter.

   if (.not. allocated(self%series)) allocate(self%series(0))
   ! ticks depend on the plot area size, margins on the tick labels: refine a first guess twice
   area = [x0 + 6.0_R8P * font_size, x0 + width - 2.0_R8P * font_size, &
           y0 + 2.0_R8P * font_size, y0 + height - 4.0_R8P * font_size]
   call self%setup_axes(area)
   area = self%place_plot_area(x0, y0, width, height, font_size)
   call self%setup_axes(area)
   area = self%place_plot_area(x0, y0, width, height, font_size)

   if (self%grid) call self%draw_grid(backend, area)
   call backend%begin_plot_area(area(1), area(3), area(2) - area(1), area(4) - area(3))
   do s = 1_I4P, size(self%series, kind=I4P)
      call self%draw_series(backend, s)
   enddo
   call backend%end_plot_area
   call self%draw_frame(backend, area, x0, y0, font_size)
   if (self%key) call self%draw_key(backend, area, font_size)
   endsubroutine render

   ! private procedures
   subroutine draw_frame(self, backend, area, x0, y0, font_size)
   !< Draw border, mirrored ticks, tick labels, axis labels and title.
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: area(4)   !< Plot area: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: x0        !< Box left side [px].
   real(R8P),             intent(in)    :: y0        !< Box top side [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   real(R8P)                            :: p         !< Tick position [px].
   real(R8P)                            :: length    !< Tick length [px].
   integer(I4P)                         :: t         !< Tick counter.

   associate(left => area(1), right => area(2), top => area(3), bottom => area(4))
      call backend%rect(left, top, right - left, bottom - top, FRAME_COLOR, 'none', 1.0_R8P)
      do t = 1_I4P, size(self%xaxis%ticks, kind=I4P)
         p = left + self%xaxis%to_unit(self%xaxis%ticks(t)%value) * (right - left)
         length = merge(TICK_MAJOR, TICK_MINOR, self%xaxis%ticks(t)%major)
         call backend%polyline([p, p], [bottom, bottom - length], FRAME_COLOR, 1.0_R8P, '')
         call backend%polyline([p, p], [top, top + length], FRAME_COLOR, 1.0_R8P, '')
         if (self%xaxis%ticks(t)%major) call backend%text(p, bottom + GAP + font_size, self%xaxis%ticks(t)%label, &
                                                          'middle', sup=self%xaxis%ticks(t)%sup)
      enddo
      do t = 1_I4P, size(self%yaxis%ticks, kind=I4P)
         p = bottom - self%yaxis%to_unit(self%yaxis%ticks(t)%value) * (bottom - top)
         length = merge(TICK_MAJOR, TICK_MINOR, self%yaxis%ticks(t)%major)
         call backend%polyline([left, left + length], [p, p], FRAME_COLOR, 1.0_R8P, '')
         call backend%polyline([right, right - length], [p, p], FRAME_COLOR, 1.0_R8P, '')
         if (self%yaxis%ticks(t)%major) call backend%text(left - GAP, p + 0.35_R8P * font_size, &
                                                          self%yaxis%ticks(t)%label, 'end', sup=self%yaxis%ticks(t)%sup)
      enddo
      if (self%xaxis%has_label()) call backend%text(0.5_R8P * (left + right), &
                                                    bottom + 2.0_R8P * GAP + (1.0_R8P + LINE_HEIGHT) * font_size, &
                                                    self%xaxis%label, 'middle')
      if (self%yaxis%has_label()) call backend%text(x0 + PAD + font_size, 0.5_R8P * (top + bottom), &
                                                    self%yaxis%label, 'middle', rotate=-90.0_R8P)
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

   subroutine draw_key(self, backend, area, font_size)
   !< Draw the key at the top right of the plot area: right-aligned titles, style samples on their right.
   class(axes_object),    intent(in)    :: self      !< Panel.
   class(backend_object), intent(inout) :: backend   !< Output device.
   real(R8P),             intent(in)    :: area(4)   !< Plot area: left, right, top, bottom [px].
   real(R8P),             intent(in)    :: font_size !< Font size [px].
   real(R8P)                            :: xs(2)     !< Sample abscissae [px].
   real(R8P)                            :: yc        !< Row centre ordinate [px].
   integer(I4P)                         :: row       !< Key row.
   integer(I4P)                         :: s         !< Series counter.

   xs = [area(2) - PAD - SAMPLE_LENGTH * font_size, area(2) - PAD]
   row = 0_I4P
   do s = 1_I4P, size(self%series, kind=I4P)
      if (len(self%series(s)%title) == 0) cycle
      row = row + 1_I4P
      yc = area(3) + GAP + (real(row, R8P) - 0.5_R8P) * LINE_HEIGHT * font_size
      if (self%series(s)%style%draws_lines()) &
         call backend%polyline(xs, [yc, yc], self%series(s)%style%color, self%series(s)%style%linewidth, &
                               self%series(s)%style%dasharray())
      if (self%series(s)%style%draws_points()) &
         call backend%dots([0.5_R8P * (xs(1) + xs(2))], [yc], self%series(s)%style%color, &
                           self%series(s)%style%point_diameter())
      call backend%text(xs(1) - GAP, yc + 0.35_R8P * font_size, self%series(s)%title, 'end')
   enddo
   endsubroutine draw_key

   subroutine draw_series(self, backend, s)
   !< Draw the `s`-th series in the plot area; unplaceable points (NaN, non-positive on log axes) break the line.
   class(axes_object),    intent(in)    :: self     !< Panel.
   class(backend_object), intent(inout) :: backend  !< Output device.
   integer(I4P),          intent(in)    :: s        !< Series index.
   logical, allocatable                 :: valid(:) !< Placeable points.
   real(R8P), allocatable               :: u(:)     !< Unit abscissae.
   real(R8P), allocatable               :: v(:)     !< Unit ordinates.
   integer(I4P)                         :: n        !< Number of points.
   integer(I4P)                         :: i1       !< First point of a run.
   integer(I4P)                         :: i2       !< Last point of a run.

   associate(series => self%series(s))
      n = size(series%x, kind=I4P)
      valid = series%valid(self%xaxis, self%yaxis)
      allocate(u(n), v(n))
      u = 0.0_R8P
      v = 0.0_R8P
      where (valid)
         u = self%xaxis%to_unit(series%x)
         v = self%yaxis%to_unit(series%y)
      endwhere
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
      if (series%style%draws_points() .and. any(valid)) &
         call backend%data_dots(pack(u, valid), pack(v, valid), series%style%color, series%style%point_diameter())
   endassociate
   endsubroutine draw_series

   pure function has_title(self) result(has)
   !< Whether the panel has a non-empty title.
   class(axes_object), intent(in) :: self !< Panel.
   logical                        :: has  !< The title is set.

   has = .false.
   if (allocated(self%title)) has = len(self%title) > 0
   endfunction has_title

   pure function place_plot_area(self, x0, y0, width, height, font_size) result(area)
   !< Plot area left by the margins that tick labels, axis labels and title need.
   class(axes_object), intent(in) :: self       !< Panel.
   real(R8P),          intent(in) :: x0         !< Box left side [px].
   real(R8P),          intent(in) :: y0         !< Box top side [px].
   real(R8P),          intent(in) :: width      !< Box width [px].
   real(R8P),          intent(in) :: height     !< Box height [px].
   real(R8P),          intent(in) :: font_size  !< Font size [px].
   real(R8P)                      :: area(4)    !< Plot area: left, right, top, bottom [px].
   real(R8P)                      :: margins(4) !< Left, right, top, bottom margins [px].
   integer(I4P)                   :: t          !< Tick counter.

   margins(1) = PAD + self%ytick_labels_width(font_size) + GAP
   if (self%yaxis%has_label()) margins(1) = margins(1) + LINE_HEIGHT * font_size + GAP
   ! the rightmost x tick label is centred on the border: half of it sticks out
   margins(2) = PAD
   do t = 1_I4P, size(self%xaxis%ticks, kind=I4P)
      if (self%xaxis%ticks(t)%major) margins(2) = max(margins(2), &
         0.5_R8P * label_width(self%xaxis%ticks(t)%label, self%xaxis%ticks(t)%sup, font_size))
   enddo
   margins(3) = PAD + 0.5_R8P * font_size
   if (self%has_title()) margins(3) = margins(3) + LINE_HEIGHT * font_size + GAP
   margins(4) = PAD + GAP + LINE_HEIGHT * font_size
   if (self%xaxis%has_label()) margins(4) = margins(4) + LINE_HEIGHT * font_size + GAP
   area = [x0 + margins(1), x0 + width - margins(2), y0 + margins(3), y0 + height - margins(4)]
   endfunction place_plot_area

   subroutine setup_axes(self, area)
   !< Effective ranges and ticks for the plot area; y autoscales on the points inside the x range, as gnuplot.
   class(axes_object), intent(inout) :: self    !< Panel.
   real(R8P),          intent(in)    :: area(4) !< Plot area: left, right, top, bottom [px].
   real(R8P)                         :: xmin    !< Smallest abscissa.
   real(R8P)                         :: xmax    !< Largest abscissa.
   real(R8P)                         :: ymin    !< Smallest ordinate.
   real(R8P)                         :: ymax    !< Largest ordinate.
   logical                           :: found   !< Any placeable point.
   integer(I4P)                      :: s       !< Series counter.

   xmin = huge(1.0_R8P)
   xmax = -huge(1.0_R8P)
   ymin = huge(1.0_R8P)
   ymax = -huge(1.0_R8P)
   found = .false.
   do s = 1_I4P, size(self%series, kind=I4P)
      call self%series(s)%extent(self%xaxis, self%yaxis, xmin, xmax, ymin, ymax, found)
   enddo
   call self%xaxis%setup(xmin, xmax, found, area(2) - area(1))
   xmin = huge(1.0_R8P)
   xmax = -huge(1.0_R8P)
   ymin = huge(1.0_R8P)
   ymax = -huge(1.0_R8P)
   found = .false.
   do s = 1_I4P, size(self%series, kind=I4P)
      call self%series(s)%extent(self%xaxis, self%yaxis, xmin, xmax, ymin, ymax, found, &
                                 xwindow=[self%xaxis%lo, self%xaxis%hi])
   enddo
   call self%yaxis%setup(ymin, ymax, found, area(4) - area(3))
   endsubroutine setup_axes

   pure function ytick_labels_width(self, font_size) result(width)
   !< Estimated width of the widest y tick label [px].
   class(axes_object), intent(in) :: self      !< Panel.
   real(R8P),          intent(in) :: font_size !< Font size [px].
   real(R8P)                      :: width     !< Width [px].
   integer(I4P)                   :: t         !< Tick counter.

   width = 0.0_R8P
   do t = 1_I4P, size(self%yaxis%ticks, kind=I4P)
      if (self%yaxis%ticks(t)%major) width = max(width, &
         label_width(self%yaxis%ticks(t)%label, self%yaxis%ticks(t)%sup, font_size))
   enddo
   endfunction ytick_labels_width

   pure function label_width(label, sup, font_size) result(width)
   !< Estimated width of a label with its superscript [px].
   character(len=*), intent(in) :: label     !< Label text.
   character(len=*), intent(in) :: sup       !< Superscript.
   real(R8P),        intent(in) :: font_size !< Font size [px].
   real(R8P)                    :: width     !< Width [px].

   width = CHAR_WIDTH * font_size * (real(len(label), R8P) + 0.75_R8P * real(len(sup), R8P))
   endfunction label_width
endmodule foresight_axes
