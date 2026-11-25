!< foresight_dgrid3d, gnuplot's dgrid3d: scattered 3D data gridded for surfaces, pm3d and contours.
module foresight_dgrid3d
!< foresight_dgrid3d, gnuplot's dgrid3d: scattered 3D data gridded for surfaces, pm3d and contours.
!<
!< A port of gnuplot 6.0's grid_nongrid_data (plot3d.c): a grid of `cols` iso-curves of x, `rows` points along y each,
!< over the bounding box of the defined points (the steps accumulated, as gnuplot's), each value a weighted mean of the
!< points: inverse distance to the power q (`qnorm q`, a point on the node its value), a kernel of the distance scaled
!< by `dx, dy` (`gauss`, `cauchy`, `exp`, `box`, `hann`; with `kdensity` the weighted sum, a density), or the thin plate
!< splines through them (`splines`, gnuplot's LU solution).
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite, ieee_quiet_nan, ieee_value
use foresight_series, only : series_object
use penf, only : I4P, R8P

implicit none
private
public :: dgrid3d_object
public :: dgrid3d_grid
public :: grid_series
public :: DGRID_QNORM, DGRID_SPLINES, DGRID_GAUSS, DGRID_CAUCHY, DGRID_EXP, DGRID_BOX, DGRID_HANN

integer(I4P), parameter :: DGRID_QNORM   = 0_I4P !< `qnorm q` (gnuplot's default, q 1).
integer(I4P), parameter :: DGRID_SPLINES = 1_I4P !< `splines`.
integer(I4P), parameter :: DGRID_GAUSS   = 2_I4P !< `gauss`.
integer(I4P), parameter :: DGRID_CAUCHY  = 3_I4P !< `cauchy`.
integer(I4P), parameter :: DGRID_EXP     = 4_I4P !< `exp`.
integer(I4P), parameter :: DGRID_BOX     = 5_I4P !< `box`.
integer(I4P), parameter :: DGRID_HANN    = 6_I4P !< `hann`.

type :: dgrid3d_object
   !< dgrid3d settings of a panel (gnuplot `set dgrid3d`).
   logical      :: on = .false.          !< Data gridded.
   integer(I4P) :: rows = 10_I4P         !< Points along y of each iso-curve.
   integer(I4P) :: cols = 10_I4P         !< Iso-curves of x.
   integer(I4P) :: mode = DGRID_QNORM    !< Weighting.
   integer(I4P) :: norm = 1_I4P          !< The q of `qnorm`.
   real(R8P)    :: scale(2) = 1.0_R8P    !< Kernel scales along x and y.
   logical      :: kdensity = .false.    !< Weighted sums, not means (`kdensity`).
endtype dgrid3d_object

contains
   pure subroutine dgrid3d_grid(px, py, pz, pc, defined, settings, gx, gy, gz, gc, ok)
   !< The grid of the points (`px`, `py`, `pz`, colors `pc`) where `defined`: `gx`, `gy`, `gz`, `gc` (point along y,
   !< iso-curve of x), the curves in gnuplot's making order (x growing); `ok` false if no point is defined.
   real(R8P),              intent(in)  :: px(:)      !< Abscissae.
   real(R8P),              intent(in)  :: py(:)      !< Ordinates.
   real(R8P),              intent(in)  :: pz(:)      !< Heights.
   real(R8P),              intent(in)  :: pc(:)      !< Color values.
   logical,                intent(in)  :: defined(:) !< Points defined.
   type(dgrid3d_object),   intent(in)  :: settings   !< Settings.
   real(R8P), allocatable, intent(out) :: gx(:,:)    !< Grid abscissae.
   real(R8P), allocatable, intent(out) :: gy(:,:)    !< Grid ordinates.
   real(R8P), allocatable, intent(out) :: gz(:,:)    !< Grid heights.
   real(R8P), allocatable, intent(out) :: gc(:,:)    !< Grid color values.
   logical,                intent(out) :: ok         !< Gridded.
   real(R8P), allocatable              :: b(:)       !< Spline coefficients.
   real(R8P), allocatable              :: xx(:), yy(:) !< The defined points (splines).
   real(R8P)                           :: xmin, xmax, ymin, ymax !< Bounding box.
   real(R8P)                           :: dx, dy     !< Steps.
   real(R8P)                           :: x, y       !< Node.
   real(R8P)                           :: z, c, w    !< Sums.
   real(R8P)                           :: dist       !< Distance.
   real(R8P)                           :: weight     !< Kernel weight.
   integer(I4P)                        :: i, j, k    !< Counters.
   integer(I4P)                        :: n          !< Defined points.
   logical                             :: on_node    !< A point on the node (qnorm).

   ok = any(defined)
   allocate(gx(settings%rows, settings%cols), gy(settings%rows, settings%cols), gz(settings%rows, settings%cols), &
            gc(settings%rows, settings%cols))
   gx = 0.0_R8P
   gy = 0.0_R8P
   gz = 0.0_R8P
   gc = 0.0_R8P
   if (.not. ok) return
   xmin = minval(px, mask=defined)
   xmax = maxval(px, mask=defined)
   ymin = minval(py, mask=defined)
   ymax = maxval(py, mask=defined)
   dx = (xmax - xmin) / real(settings%cols - 1_I4P, R8P)
   dy = (ymax - ymin) / real(settings%rows - 1_I4P, R8P)
   if (settings%mode == DGRID_SPLINES) then
      xx = pack(px, defined)
      yy = pack(py, defined)
      n = size(xx, kind=I4P)
      call thin_plate_splines(xx, yy, pack(pz, defined), b)
   endif
   x = xmin
   do i = 1_I4P, settings%cols
      y = ymin
      do j = 1_I4P, settings%rows
         z = 0.0_R8P
         c = 0.0_R8P
         w = 0.0_R8P
         if (settings%mode == DGRID_SPLINES) then
            z = b(n + 1)
            do k = 1_I4P, n
               z = z - b(k) * kernel(sqrt((xx(k) - x)**2 + (yy(k) - y)**2))
            enddo
            z = z + b(n + 2) * x + b(n + 3) * y
            c = z
         else
            on_node = .false.
            do k = 1_I4P, size(px, kind=I4P)
               if (.not. defined(k)) cycle
               if (settings%mode == DGRID_QNORM) then
                  dist = qnorm(abs(px(k) - x), abs(py(k) - y), settings%norm)
                  if (dist == 0.0_R8P) then
                     z = pz(k)
                     c = pc(k)
                     w = 1.0_R8P
                     on_node = .true.
                     exit
                  endif
                  z = z + pz(k) / dist
                  c = c + pc(k) / dist
                  w = w + 1.0_R8P / dist
               else
                  dist = pythag((px(k) - x) / settings%scale(1), (py(k) - y) / settings%scale(2))
                  select case (settings%mode)
                  case (DGRID_GAUSS)
                     weight = exp(-dist * dist)
                  case (DGRID_CAUCHY)
                     weight = 1.0_R8P / (1.0_R8P + dist * dist)
                  case (DGRID_EXP)
                     weight = exp(-dist)
                  case (DGRID_BOX)
                     weight = merge(1.0_R8P, 0.0_R8P, dist < 1.0_R8P)
                  case default
                     weight = 0.0_R8P
                     if (dist < 1.0_R8P) weight = 0.5_R8P * (1.0_R8P + cos(acos(-1.0_R8P) * dist))
                  endselect
                  z = z + pz(k) * weight
                  c = c + pc(k) * weight
                  w = w + weight
               endif
            enddo
            if (.not. settings%kdensity .or. on_node) then
               if (w == 0.0_R8P) then
                  ! no weight (box, hann beyond every point): undefined, as gnuplot's 0/0
                  z = ieee_value(1.0_R8P, ieee_quiet_nan)
                  c = z
               else
                  z = z / w
                  c = c / w
               endif
            endif
         endif
         gx(j, i) = x
         gy(j, i) = y
         gz(j, i) = z
         gc(j, i) = c
         y = y + dy
      enddo
      x = x + dx
   enddo
   endsubroutine dgrid3d_grid

   pure function kernel(h) result(k)
   !< gnuplot's splines_kernel: h^2 log h.
   real(R8P), intent(in) :: h !< Distance.
   real(R8P)             :: k !< Kernel.

   k = 0.0_R8P
   if (h > 0.0_R8P) k = h * h * log(h)
   endfunction kernel

   pure function pythag(dx, dy) result(d)
   !< gnuplot's pythag (Numerical Recipes): the length of (dx, dy) without overflow.
   real(R8P), intent(in) :: dx, dy !< Components.
   real(R8P)             :: d      !< Length.
   real(R8P)             :: x, y   !< Absolute values.

   x = abs(dx)
   y = abs(dy)
   if (x > y) then
      d = x * sqrt(1.0_R8P + (y * y) / (x * x))
   elseif (y == 0.0_R8P) then
      d = 0.0_R8P
   else
      d = y * sqrt(1.0_R8P + (x * x) / (y * y))
   endif
   endfunction pythag

   pure function qnorm(dist_x, dist_y, q) result(dist)
   !< gnuplot's qnorm: the distance (q 1), its square (q 2), its q-th power.
   real(R8P),    intent(in) :: dist_x, dist_y !< Components.
   integer(I4P), intent(in) :: q              !< Power.
   real(R8P)                :: dist           !< Distance.

   select case (q)
   case (1_I4P)
      dist = pythag(dist_x, dist_y)
   case (2_I4P)
      dist = dist_x * dist_x + dist_y * dist_y
   case default
      dist = pythag(dist_x, dist_y)**q
   endselect
   endfunction qnorm

   pure subroutine thin_plate_splines(xx, yy, zz, b)
   !< gnuplot's thin_plate_splines_setup: the coefficients `b` of the thin plate splines through the points (n weights,
   !< then the affine part), the system solved by gnuplot's LU decomposition.
   real(R8P),              intent(in)  :: xx(:), yy(:), zz(:) !< Points.
   real(R8P), allocatable, intent(out) :: b(:)                !< Coefficients (n + 3).
   real(R8P), allocatable              :: k(:,:)              !< System (row, column).
   integer(I4P), allocatable           :: indx(:)             !< Pivots.
   integer(I4P)                        :: n                   !< Points.
   integer(I4P)                        :: i, j                !< Counters.

   n = size(xx, kind=I4P)
   allocate(k(n + 3, n + 3), b(n + 3), indx(n + 3))
   k = 0.0_R8P
   do i = 1_I4P, n
      do j = i + 1_I4P, n
         k(i, j) = -kernel(sqrt((xx(i) - xx(j))**2 + (yy(i) - yy(j))**2))
         k(j, i) = k(i, j)
      enddo
      b(i) = zz(i)
   enddo
   do i = 1_I4P, n
      k(i, n + 1) = 1.0_R8P
      k(n + 1, i) = 1.0_R8P
      k(i, n + 2) = xx(i)
      k(n + 2, i) = xx(i)
      k(i, n + 3) = yy(i)
      k(n + 3, i) = yy(i)
   enddo
   b(n + 1:n + 3) = 0.0_R8P
   call lu_decomp(k, indx)
   call lu_backsubst(k, indx, b)
   endsubroutine thin_plate_splines

   pure subroutine lu_decomp(a, indx)
   !< gnuplot's lu_decomp (Crout with implicit pivoting, matrix.c): `a` overwritten by its LU decomposition, `indx`
   !< the row permutation.
   real(R8P),    intent(inout) :: a(:,:)  !< Matrix (row, column).
   integer(I4P), intent(out)   :: indx(:) !< Pivot rows.
   real(R8P), allocatable      :: vscal(:) !< Implicit scaling.
   real(R8P)                   :: large, dummy, t !< Pivoting.
   integer(I4P)                :: n, i, j, k, imax !< Counters.

   n = size(a, 1, kind=I4P)
   allocate(vscal(n))
   do i = 1_I4P, n
      large = maxval(abs(a(i, :)))
      vscal(i) = 0.0_R8P
      if (large /= 0.0_R8P) vscal(i) = 1.0_R8P / large
   enddo
   imax = 1_I4P
   do j = 1_I4P, n
      do i = 1_I4P, j - 1_I4P
         do k = 1_I4P, i - 1_I4P
            a(i, j) = a(i, j) - a(i, k) * a(k, j)
         enddo
      enddo
      large = 0.0_R8P
      do i = j, n
         do k = 1_I4P, j - 1_I4P
            a(i, j) = a(i, j) - a(i, k) * a(k, j)
         enddo
         dummy = vscal(i) * abs(a(i, j))
         if (dummy >= large) then
            large = dummy
            imax = i
         endif
      enddo
      if (j /= imax) then
         do k = 1_I4P, n
            t = a(imax, k)
            a(imax, k) = a(j, k)
            a(j, k) = t
         enddo
         vscal(imax) = vscal(j)
      endif
      indx(j) = imax
      if (a(j, j) == 0.0_R8P) a(j, j) = 1.0e-30_R8P
      if (j /= n) then
         dummy = 1.0_R8P / a(j, j)
         do i = j + 1_I4P, n
            a(i, j) = a(i, j) * dummy
         enddo
      endif
   enddo
   endsubroutine lu_decomp

   pure subroutine lu_backsubst(a, indx, b)
   !< gnuplot's lu_backsubst: `b` overwritten by the solution of the decomposed system.
   real(R8P),    intent(in)    :: a(:,:)  !< Decomposed matrix.
   integer(I4P), intent(in)    :: indx(:) !< Pivot rows.
   real(R8P),    intent(inout) :: b(:)    !< Right side, solution.
   real(R8P)                   :: s       !< Sum.
   integer(I4P)                :: n, i, j, ip, memi !< Counters.

   n = size(a, 1, kind=I4P)
   memi = 0_I4P
   do i = 1_I4P, n
      ip = indx(i)
      s = b(ip)
      b(ip) = b(i)
      if (memi > 0_I4P) then
         do j = memi, i - 1_I4P
            s = s - a(i, j) * b(j)
         enddo
      elseif (s /= 0.0_R8P) then
         memi = i
      endif
      b(i) = s
   enddo
   do i = n, 1_I4P, -1_I4P
      do j = i + 1_I4P, n
         b(i) = b(i) - a(i, j) * b(j)
      enddo
      b(i) = b(i) / a(i, i)
   enddo
   endsubroutine lu_backsubst

   subroutine grid_series(series, settings)
   !< The points of a 3D `series` replaced by their grid (foresight_dgrid3d, gnuplot's `set dgrid3d`): its iso-curves
   !< of x as its scans (gnuplot keeps them last first), its color values (palette z) gridded with its heights; the
   !< per point colors, sizes and texts dropped.
   type(series_object),  intent(inout) :: series   !< Series.
   type(dgrid3d_object), intent(in)    :: settings !< Gridding.
   real(R8P), allocatable              :: c(:)     !< Color values of the points.
   real(R8P), allocatable              :: gx(:,:), gy(:,:), gz(:,:), gc(:,:) !< Grid.
   integer(I4P), allocatable           :: scans(:,:) !< Scans of the grid.
   logical                             :: ok       !< Gridded.
   logical                             :: colored  !< Color values of their own.
   integer(I4P)                        :: i, n     !< Counters.

   c = series%z
   colored = .false.
   if (allocated(series%zvalues)) then
      if (size(series%zvalues) == size(series%z)) then
         c = series%zvalues
         colored = .true.
      endif
   endif
   call dgrid3d_grid(series%x, series%y, series%z, c, ieee_is_finite(series%x) .and. ieee_is_finite(series%y) .and. &
                     ieee_is_finite(series%z), settings, gx, gy, gz, gc, ok)
   if (.not. ok) return
   n = size(gx, 1, kind=I4P)
   deallocate(series%x, series%y, series%z)
   allocate(series%x((n + 1_I4P) * size(gx, 2) - 1_I4P), series%y((n + 1_I4P) * size(gx, 2) - 1_I4P), &
            series%z((n + 1_I4P) * size(gx, 2) - 1_I4P), scans(2, size(gx, 2)))
   series%x = ieee_value(1.0_R8P, ieee_quiet_nan)
   series%y = series%x
   series%z = series%x
   if (colored) then
      deallocate(series%zvalues)
      allocate(series%zvalues(size(series%x)))
      series%zvalues = series%x
   endif
   do i = 1_I4P, size(gx, 2, kind=I4P)
      scans(:, i) = [(i - 1_I4P) * (n + 1_I4P) + 1_I4P, (i - 1_I4P) * (n + 1_I4P) + n]
      series%x(scans(1, i):scans(2, i)) = gx(:, i)
      series%y(scans(1, i):scans(2, i)) = gy(:, i)
      series%z(scans(1, i):scans(2, i)) = gz(:, i)
      if (colored) series%zvalues(scans(1, i):scans(2, i)) = gc(:, i)
   enddo
   series%scans = scans
   series%scan_sets = [(0_I4P, i = 1_I4P, size(gx, 2, kind=I4P))]
   series%grid_scans = size(gx, 2, kind=I4P)
   series%data_scans = .true.
   if (allocated(series%colors)) deallocate(series%colors)
   if (allocated(series%point_sizes)) deallocate(series%point_sizes)
   if (allocated(series%texts)) deallocate(series%texts)
   if (allocated(series%xlabels)) deallocate(series%xlabels)
   endsubroutine grid_series
endmodule foresight_dgrid3d
