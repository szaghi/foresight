!< foresight_contour, gnuplot's contour lines of a surface grid.
module foresight_contour
!< foresight_contour, gnuplot's contour lines of a surface grid.
!<
!< A port of gnuplot 6.0's contour.c: each cell of the grid split into two triangles (edges in gnuplot's list order),
!< the edges crossing a level traced through the triangles, from the boundary first (open lines) then inside (closed
!< ones); each line in linear segments, a cubic spline through its points or a B-spline approximation of them; lines
!< cut into chunks of at most 99 points, the last one starting the next; the list built last first, as gnuplot's (its
!< table and drawing order). The levels: `auto N` (gnuplot's quantize_normal_tics of the z extent, guide 2 (N + 1)),
!< `discrete z1, z2, ...`, `incremental start, step[, end]`.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite, ieee_quiet_nan, ieee_value
use penf, only : I4P, R8P

implicit none
private
public :: contour_object
public :: contour_levels
public :: contour_lines
public :: CONTOUR_LINEAR, CONTOUR_CUBIC, CONTOUR_BSPLINE, LEVELS_AUTO, LEVELS_DISCRETE, LEVELS_INCREMENTAL

integer(I4P), parameter :: CONTOUR_LINEAR  = 0_I4P !< `set cntrparam linear`.
integer(I4P), parameter :: CONTOUR_CUBIC   = 1_I4P !< `cubicspline`.
integer(I4P), parameter :: CONTOUR_BSPLINE = 2_I4P !< `bspline`.
integer(I4P), parameter :: LEVELS_AUTO        = 0_I4P !< `levels auto N`.
integer(I4P), parameter :: LEVELS_DISCRETE    = 1_I4P !< `levels discrete z1, z2, ...`.
integer(I4P), parameter :: LEVELS_INCREMENTAL = 2_I4P !< `levels incremental start, step[, end]`.
integer(I4P), parameter :: MAX_POINTS = 100_I4P     !< gnuplot's MAX_POINTS_PER_CNTR: chunks of 99 points.
real(R8P),    parameter :: EPS = 1.0e-5_R8P         !< gnuplot's EPSILON: two points are the same.
integer(I4P), parameter :: BOUNDARY = 2_I4P         !< An edge of one triangle.
integer(I4P), parameter :: DIAGONAL = 3_I4P         !< The diagonal of a cell.

type :: contour_object
   !< Contour settings of a panel (gnuplot `set contour`, `set cntrparam`, `set cntrlabel`).
   logical                :: on = .false.         !< Contours drawn (`set contour`).
   character(len=7)       :: place = 'base'       !< `base`, `surface` or `both`.
   integer(I4P)           :: kind = CONTOUR_LINEAR !< Interpolation.
   integer(I4P)           :: levels_kind = LEVELS_AUTO !< Levels kind.
   integer(I4P)           :: levels = 5_I4P       !< Levels of `auto` (about), or of `incremental` with an end.
   real(R8P), allocatable :: list(:)              !< `discrete` levels, or `incremental` start and step.
   integer(I4P)           :: order = 4_I4P        !< B-spline order, 2 to 10.
   integer(I4P)           :: npoints = 5_I4P      !< Points per interval of the splines.
   integer(I4P)           :: firstlinetype = -1_I4P !< Linetype of the first level, else the surface's + 1.
   logical                :: sorted = .false.     !< Levels sorted high to low.
   character(len=64)      :: format = '%8.3g'     !< Label format (`set cntrlabel format`).
   logical                :: onecolor = .false.   !< All levels in the surface's color, one key entry (`onecolor`).
   integer(I4P)           :: label_start = 5_I4P  !< First labelled point of `with labels` (`start`).
   integer(I4P)           :: label_interval = 20_I4P !< Points between labels (`interval`).
endtype contour_object

type :: tracer
   !< The triangulation of a grid and the lines traced on it (gnuplot's contour.c state).
   type(contour_object)      :: settings             !< Settings.
   integer(I4P)              :: nx = 0_I4P           !< Points per row.
   real(R8P), allocatable    :: vx(:), vy(:), vz(:)  !< Vertices, (row - 1) nx + point.
   logical,   allocatable    :: vin(:), vdef(:)      !< Vertex in range, defined.
   real(R8P)                 :: unit_x = 1.0_R8P     !< Grid extent along x.
   real(R8P)                 :: unit_y = 1.0_R8P     !< Grid extent along y.
   integer(I4P), allocatable :: ev(:,:)              !< Edge vertices (2, edge).
   integer(I4P), allocatable :: ep(:,:)              !< Edge triangles (2, edge), 0 for none.
   integer(I4P), allocatable :: epos(:)              !< Edge position: 1 inner, BOUNDARY, DIAGONAL.
   logical,      allocatable :: active(:)            !< Edge crossing the current level.
   integer(I4P), allocatable :: pe(:,:)              !< Triangle edges (3, triangle).
   integer(I4P), allocatable :: hprev(:), hrow(:)    !< Horizontal edges of the previous and current rows.
   integer(I4P), allocatable :: htri(:)              !< Triangle of each upper edge of the current row.
   integer(I4P)              :: ne = 0_I4P           !< Edges.
   integer(I4P)              :: np = 0_I4P           !< Triangles.
   integer(I4P)              :: nactive = 0_I4P      !< Active edges.
   real(R8P), allocatable    :: px(:), py(:)         !< Points of the line being traced.
   integer(I4P)              :: npt = 0_I4P          !< Its points.
   real(R8P)                 :: cur(2 * MAX_POINTS) = 0.0_R8P !< gnuplot's crnt_cntr.
   integer(I4P)              :: ncur = 0_I4P         !< Its points.
   real(R8P), allocatable    :: kx(:), ky(:), kz(:)  !< Chunks made (in making order), NaN separated, their level.
   integer(I4P)              :: nk = 0_I4P           !< Rows made.
   integer(I4P), allocatable :: kfirst(:), klast(:)  !< First and last row of each chunk.
   logical,      allocatable :: knew(:)              !< Chunk flagged new level.
   integer(I4P)              :: nchunks = 0_I4P      !< Chunks made.
endtype tracer

contains
   pure function quantize(arg, guide) result(step)
   !< gnuplot's quantize_normal_tics: a step about `arg` / `guide` (a round number).
   real(R8P),    intent(in) :: arg   !< Extent.
   integer(I4P), intent(in) :: guide !< Steps wanted.
   real(R8P)                :: step  !< Step.
   real(R8P)                :: power !< Decade.
   real(R8P)                :: xnorm !< Extent in decades.
   real(R8P)                :: posns !< Steps per decade.
   real(R8P)                :: tics  !< Step in decades.

   power = 10.0_R8P**floor(log10(arg))
   xnorm = arg / power
   posns = real(guide, R8P) / xnorm
   if (posns > 40.0_R8P) then
      tics = 0.05_R8P
   elseif (posns > 20.0_R8P) then
      tics = 0.1_R8P
   elseif (posns > 10.0_R8P) then
      tics = 0.2_R8P
   elseif (posns > 4.0_R8P) then
      tics = 0.5_R8P
   elseif (posns > 2.0_R8P) then
      tics = 1.0_R8P
   elseif (posns > 0.5_R8P) then
      tics = 2.0_R8P
   else
      tics = ceiling(xnorm)
   endif
   step = tics * power
   endfunction quantize

   pure subroutine contour_levels(settings, zmin, zmax, zlog, levels)
   !< The levels of the contours of a surface of heights `zmin` to `zmax` (its defined points), as gnuplot's contour():
   !< `auto` levels at the multiples of a round step within the extent, `incremental` from start by step (a factor on
   !< a log z axis, `zlog`), `discrete` as given; sorted high to low with `sorted`.
   type(contour_object),   intent(in)  :: settings  !< Settings.
   real(R8P),              intent(in)  :: zmin      !< Lowest height.
   real(R8P),              intent(in)  :: zmax      !< Highest height.
   logical,                intent(in)  :: zlog      !< A log z axis.
   real(R8P), allocatable, intent(out) :: levels(:) !< Levels.
   real(R8P)                           :: dz        !< Step.
   real(R8P)                           :: z0        !< Start.
   real(R8P)                           :: t         !< A level, sorting.
   integer(I4P)                        :: n         !< Levels.
   integer(I4P)                        :: i, j      !< Counters.

   allocate(levels(0))
   select case (settings%levels_kind)
   case (LEVELS_DISCRETE)
      if (allocated(settings%list)) levels = settings%list
   case (LEVELS_INCREMENTAL)
      if (.not. allocated(settings%list)) return
      if (size(settings%list) < 2) return
      n = max(0_I4P, settings%levels)
      deallocate(levels)
      allocate(levels(n))
      do i = 0_I4P, n - 1_I4P
         if (zlog) then
            levels(i + 1) = settings%list(1) * settings%list(2)**i
         else
            levels(i + 1) = settings%list(1) + real(i, R8P) * settings%list(2)
         endif
      enddo
   case default
      dz = abs(zmax - zmin)
      if (dz == 0.0_R8P .or. .not. ieee_is_finite(dz)) return
      dz = quantize(dz, (settings%levels + 1_I4P) * 2_I4P)
      z0 = floor(zmin / dz) * dz
      n = int(floor((zmax - z0) / dz), I4P)
      if (n <= 0_I4P) return
      deallocate(levels)
      allocate(levels(n))
      do i = 0_I4P, n - 1_I4P
         levels(i + 1) = z0 + real(i + 1_I4P, R8P) * dz
         ! gnuplot's CheckZero: within a hundredth of a step of 0 is 0
         if (abs(levels(i + 1)) < dz * 0.01_R8P) levels(i + 1) = 0.0_R8P
      enddo
   endselect
   if (settings%sorted) then
      do i = 2_I4P, size(levels, kind=I4P)
         t = levels(i)
         j = i - 1_I4P
         do while (j >= 1_I4P)
            if (levels(j) >= t) exit
            levels(j + 1) = levels(j)
            j = j - 1_I4P
         enddo
         levels(j + 1) = t
      enddo
   endif
   endsubroutine contour_levels

   subroutine contour_lines(gx, gy, gz, inrange, defined, settings, zlog, cx, cy, cz, chunk_level, new_level)
   !< The contour lines of a grid of `size(gx, 1)` points per row and `size(gx, 2)` rows (gnuplot's iso-curves in their
   !< list order), as gnuplot's contour(): the grid triangulated over its points in range (`inrange`), its extent over
   !< the `defined` ones, the levels of contour_levels; the chunks of the lines in gnuplot's order (the last made
   !< first), as rows `cx`, `cy` (a NaN row after each chunk), `cz` their level; `chunk_level` the level of each chunk,
   !< `new_level` true on the first chunk of each level (its key entry, its table header).
   real(R8P),              intent(in)  :: gx(:,:)        !< Abscissae (point, row).
   real(R8P),              intent(in)  :: gy(:,:)        !< Ordinates.
   real(R8P),              intent(in)  :: gz(:,:)        !< Heights.
   logical,                intent(in)  :: inrange(:,:)   !< Points in range (gnuplot's INRANGE).
   logical,                intent(in)  :: defined(:,:)   !< Points defined.
   type(contour_object),   intent(in)  :: settings       !< Settings.
   logical,                intent(in)  :: zlog           !< A log z axis.
   real(R8P), allocatable, intent(out) :: cx(:)          !< Line abscissae, NaN after each chunk.
   real(R8P), allocatable, intent(out) :: cy(:)          !< Line ordinates.
   real(R8P), allocatable, intent(out) :: cz(:)          !< Their level.
   real(R8P), allocatable, intent(out) :: chunk_level(:) !< Level of each chunk.
   logical,   allocatable, intent(out) :: new_level(:)   !< First chunk of its level.
   type(tracer)                        :: st             !< Triangulation and lines.
   real(R8P),    allocatable           :: levels(:)      !< Levels.
   integer(I4P)                        :: nx             !< Points per row.
   integer(I4P)                        :: ny             !< Rows.
   integer(I4P)                        :: i, j, k        !< Counters.
   integer(I4P)                        :: v1, v2         !< First vertices of the lower and upper rows.
   integer(I4P)                        :: e0, e1, e2     !< Triangle edges.
   integer(I4P)                        :: lev            !< Level counter.
   integer(I4P)                        :: before         !< Chunks before the level.
   integer(I4P)                        :: start          !< Starting edge.
   logical                             :: closed         !< Looking for closed lines.
   real(R8P)                           :: zl             !< Current level.
   real(R8P)                           :: zmin, zmax     !< Extent of the heights.

   nx = size(gx, 1, kind=I4P)
   ny = size(gx, 2, kind=I4P)
   allocate(cx(0), cy(0), cz(0), chunk_level(0), new_level(0))
   if (nx < 2_I4P .or. ny < 2_I4P) return
   st%nx = nx
   st%settings = settings
   allocate(st%vx(nx * ny), st%vy(nx * ny), st%vz(nx * ny), st%vin(nx * ny), st%vdef(nx * ny))
   do j = 1_I4P, ny
      do i = 1_I4P, nx
         k = (j - 1_I4P) * nx + i
         st%vx(k) = gx(i, j)
         st%vy(k) = gy(i, j)
         st%vz(k) = gz(i, j)
         st%vin(k) = inrange(i, j)
         st%vdef(k) = defined(i, j)
      enddo
   enddo
   ! calc_min_max over the defined points
   zmin = 0.0_R8P
   zmax = 0.0_R8P
   st%unit_x = 0.0_R8P
   st%unit_y = 0.0_R8P
   if (any(st%vdef)) then
      zmin = minval(st%vz, mask=st%vdef)
      zmax = maxval(st%vz, mask=st%vdef)
      st%unit_x = maxval(st%vx, mask=st%vdef) - minval(st%vx, mask=st%vdef)
      st%unit_y = maxval(st%vy, mask=st%vdef) - minval(st%vy, mask=st%vdef)
   endif
   st%unit_x = max(st%unit_x, 1.0e-8_R8P)
   st%unit_y = max(st%unit_y, 1.0e-8_R8P)
   ! gen_triangle: the edges in gnuplot's list order; the upper horizontal edges of a row join it at the row's end
   allocate(st%ev(2, 3 * nx * ny), st%ep(2, 3 * nx * ny), st%epos(3 * nx * ny), st%pe(3, 2 * nx * ny))
   allocate(st%hprev(nx - 1_I4P), st%hrow(nx - 1_I4P), st%htri(nx - 1_I4P))
   st%ep = 0_I4P
   st%ne = 0_I4P
   st%np = 0_I4P
   do i = 1_I4P, nx - 1_I4P
      st%hprev(i) = new_edge(st, i, i + 1_I4P)
   enddo
   do j = 2_I4P, ny
      v1 = (j - 2_I4P) * nx
      v2 = (j - 1_I4P) * nx
      st%hrow = 0_I4P
      st%htri = 0_I4P
      e2 = new_edge(st, v1 + 1_I4P, v2 + 1_I4P)
      do i = 1_I4P, nx - 1_I4P
         e0 = e2
         e2 = st%hprev(i)
         e1 = new_edge(st, v1 + i + 1_I4P, v2 + i)
         if (e1 > 0_I4P) st%epos(e1) = DIAGONAL
         call new_triangle(st, e0, e1, e2)
         e0 = e1
         ! an upper edge numbered later: -1 for now, its triangle remembered
         e1 = 0_I4P
         if (st%vin(v2 + i) .and. st%vin(v2 + i + 1_I4P)) e1 = -1_I4P
         e2 = new_edge(st, v1 + i + 1_I4P, v2 + i + 1_I4P)
         st%hrow(i) = e1
         call new_triangle(st, e0, e1, e2)
         if (e1 /= 0_I4P .and. e0 /= 0_I4P .and. e2 /= 0_I4P) st%htri(i) = st%np
      enddo
      ! the row's upper edges join the list, their triangle told
      do i = 1_I4P, nx - 1_I4P
         if (st%hrow(i) == 0_I4P) cycle
         st%ne = st%ne + 1_I4P
         st%ev(:, st%ne) = [v2 + i, v2 + i + 1_I4P]
         st%ep(:, st%ne) = 0_I4P
         st%epos(st%ne) = 1_I4P
         st%hrow(i) = st%ne
         if (st%htri(i) > 0_I4P) then
            st%pe(2, st%htri(i)) = st%ne
            st%ep(1, st%ne) = st%htri(i)
         endif
      enddo
      st%hprev = st%hrow
   enddo
   do k = 1_I4P, st%ne
      if (st%ep(1, k) == 0_I4P .or. st%ep(2, k) == 0_I4P) st%epos(k) = BOUNDARY
   enddo
   ! the levels, and their lines
   call contour_levels(settings, zmin, zmax, zlog, levels)
   allocate(st%active(st%ne), st%px(st%ne + 2_I4P), st%py(st%ne + 2_I4P))
   allocate(st%kx(1024), st%ky(1024), st%kz(1024), st%kfirst(64), st%klast(64), st%knew(64))
   st%nk = 0_I4P
   st%nchunks = 0_I4P
   st%ncur = 0_I4P
   do lev = 1_I4P, size(levels, kind=I4P)
      zl = levels(lev)
      before = st%nchunks
      ! pass 1: the edges crossing the level
      st%nactive = 0_I4P
      do k = 1_I4P, st%ne
         st%active(k) = (st%vz(st%ev(1, k)) >= zl) .neqv. (st%vz(st%ev(2, k)) >= zl)
         if (st%active(k)) st%nactive = st%nactive + 1_I4P
      enddo
      ! pass 2: the lines, from the boundary first
      closed = .false.
      do while (st%nactive > 0_I4P)
         start = 0_I4P
         if (.not. closed) then
            do k = 1_I4P, st%ne
               if (st%active(k) .and. st%epos(k) == BOUNDARY) then
                  start = k
                  exit
               endif
            enddo
            if (start == 0_I4P) closed = .true.
         endif
         if (closed) then
            do k = 1_I4P, st%ne
               if (st%active(k) .and. st%epos(k) /= BOUNDARY) then
                  start = k
                  exit
               endif
            enddo
            if (start == 0_I4P) exit
         endif
         call trace(st, start, zl, closed)
         if (st%npt > 0_I4P) call put_line(st, zl, closed)
      enddo
      ! the level's first chunk in gnuplot's order: the last one made
      if (st%nchunks > before) st%knew(st%nchunks) = .true.
   enddo
   ! gnuplot's list order: the last chunk first
   deallocate(cx, cy, cz, chunk_level, new_level)
   allocate(chunk_level(st%nchunks), new_level(st%nchunks), cx(st%nk), cy(st%nk), cz(st%nk))
   k = 0_I4P
   do i = st%nchunks, 1_I4P, -1_I4P
      chunk_level(st%nchunks - i + 1_I4P) = st%kz(st%kfirst(i))
      new_level(st%nchunks - i + 1_I4P) = st%knew(i)
      do j = st%kfirst(i), st%klast(i) + 1_I4P
         k = k + 1_I4P
         cx(k) = st%kx(j)
         cy(k) = st%ky(j)
         cz(k) = st%kz(j)
      enddo
   enddo
   endsubroutine contour_lines

   function new_edge(st, a, b) result(e)
   !< gnuplot's add_edge to the main list: an edge of the vertices `a`, `b` if both are in range, else 0.
   type(tracer), intent(inout) :: st !< Triangulation.
   integer(I4P), intent(in)    :: a  !< First vertex.
   integer(I4P), intent(in)    :: b  !< Second vertex.
   integer(I4P)                :: e  !< Edge.

   e = 0_I4P
   if (.not. (st%vin(a) .and. st%vin(b))) return
   st%ne = st%ne + 1_I4P
   st%ev(:, st%ne) = [a, b]
   st%ep(:, st%ne) = 0_I4P
   st%epos(st%ne) = 1_I4P
   e = st%ne
   endfunction new_edge

   subroutine new_triangle(st, a, b, c)
   !< gnuplot's add_poly: a triangle of the edges `a`, `b`, `c` if all three exist (an upper edge numbered later, -1);
   !< each numbered edge told the triangle.
   type(tracer), intent(inout) :: st !< Triangulation.
   integer(I4P), intent(in)    :: a  !< First edge.
   integer(I4P), intent(in)    :: b  !< Second edge.
   integer(I4P), intent(in)    :: c  !< Third edge.

   if (a == 0_I4P .or. b == 0_I4P .or. c == 0_I4P) return
   st%np = st%np + 1_I4P
   st%pe(:, st%np) = [a, b, c]
   if (a > 0_I4P) call link(st, a)
   if (b > 0_I4P) call link(st, b)
   if (c > 0_I4P) call link(st, c)
   endsubroutine new_triangle

   subroutine link(st, e)
   !< Edge `e` told of the newest triangle.
   type(tracer), intent(inout) :: st !< Triangulation.
   integer(I4P), intent(in)    :: e  !< Edge.

   if (st%ep(1, e) /= 0_I4P) then
      st%ep(2, e) = st%np
   else
      st%ep(1, e) = st%np
   endif
   endsubroutine link

   subroutine trace(st, e_start, z, isclosed)
   !< gnuplot's trace_contour: the line from edge `e_start` through the triangles to a boundary edge or back to it,
   !< its points (`px`, `py`, `npt`) on the non-diagonal edges, nearby ones merged; none on a dead end.
   type(tracer), intent(inout) :: st       !< Triangulation and line.
   integer(I4P), intent(in)    :: e_start  !< First edge.
   real(R8P),    intent(in)    :: z        !< Level.
   logical,      intent(in)    :: isclosed !< Looking for closed lines.
   integer(I4P)                :: e        !< Current edge.
   integer(I4P)                :: enext    !< Next edge.
   integer(I4P)                :: poly     !< Current triangle.
   integer(I4P)                :: last_poly !< Triangle we came from.
   integer(I4P)                :: s        !< Side.
   real(R8P)                   :: qx, qy   !< A point.

   st%npt = 0_I4P
   e = e_start
   if (.not. isclosed) then
      st%active(e_start) = .false.
      st%nactive = st%nactive - 1_I4P
   endif
   if (st%ep(1, e) == 0_I4P .and. st%ep(2, e) == 0_I4P) return
   call edge_point(st, e, z, qx, qy)
   st%npt = 1_I4P
   st%px(1) = qx
   st%py(1) = qy
   last_poly = 0_I4P
   do
      if (st%ep(1, e) == last_poly) then
         poly = st%ep(2, e)
      else
         poly = st%ep(1, e)
      endif
      enext = 0_I4P
      if (poly > 0_I4P) then
         do s = 1_I4P, 3_I4P
            if (st%pe(s, poly) /= e) then
               if (st%active(st%pe(s, poly))) enext = st%pe(s, poly)
            endif
         enddo
      endif
      if (enext == 0_I4P) then
         ! gnuplot: unexpected end of contour, the line dropped
         st%npt = 0_I4P
         return
      endif
      e = enext
      last_poly = poly
      st%active(e) = .false.
      st%nactive = st%nactive - 1_I4P
      if (st%epos(e) /= DIAGONAL) then
         call edge_point(st, e, z, qx, qy)
         if (.not. same_point(st, st%px(st%npt), st%py(st%npt), qx, qy)) then
            st%npt = st%npt + 1_I4P
            st%px(st%npt) = qx
            st%py(st%npt) = qy
         endif
      endif
      if (e == e_start .or. st%epos(e) == BOUNDARY) exit
   enddo
   ! a closed line ends where it started
   if (e == e_start) then
      st%px(1) = st%px(st%npt)
      st%py(1) = st%py(st%npt)
   endif
   endsubroutine trace

   pure subroutine edge_point(st, e, z, qx, qy)
   !< gnuplot's update_cntr_pt: where edge `e` crosses level `z`, linearly.
   type(tracer), intent(in)  :: st !< Triangulation.
   integer(I4P), intent(in)  :: e  !< Edge.
   real(R8P),    intent(in)  :: z  !< Level.
   real(R8P),    intent(out) :: qx !< Abscissa.
   real(R8P),    intent(out) :: qy !< Ordinate.
   real(R8P)                 :: t  !< Fraction along the edge.

   t = (z - st%vz(st%ev(1, e))) / (st%vz(st%ev(2, e)) - st%vz(st%ev(1, e)))
   t = max(0.0_R8P, min(1.0_R8P, t))
   qx = st%vx(st%ev(2, e)) * t + st%vx(st%ev(1, e)) * (1.0_R8P - t)
   qy = st%vy(st%ev(2, e)) * t + st%vy(st%ev(1, e)) * (1.0_R8P - t)
   endsubroutine edge_point

   pure function same_point(st, ax, ay, bx, by) result(yes)
   !< gnuplot's fuzzy_equal: two points within EPS of the grid extent.
   type(tracer), intent(in) :: st             !< Grid extent.
   real(R8P),    intent(in) :: ax, ay, bx, by !< The points.
   logical                  :: yes            !< The same.

   yes = abs(ax / st%unit_x - bx / st%unit_x) < EPS .and. abs(ay / st%unit_y - by / st%unit_y) < EPS
   endfunction same_point

   subroutine put_line(st, z, isclosed)
   !< gnuplot's put_contour: the traced line as it is, through a cubic spline, or approximated by a B-spline.
   type(tracer), intent(inout) :: st       !< Line and chunks.
   real(R8P),    intent(in)    :: z        !< Level.
   logical,      intent(in)    :: isclosed !< A closed line.
   logical                     :: shut     !< Closed, or ending where it started (chk_contour_kind).
   integer(I4P)                :: k        !< Point counter.

   shut = isclosed
   if (.not. shut) shut = same_point(st, st%px(st%npt), st%py(st%npt), st%px(1), st%py(1))
   select case (st%settings%kind)
   case (CONTOUR_CUBIC)
      call put_cubic(st, z, shut)
   case (CONTOUR_BSPLINE)
      call put_bspline(st, z, shut)
   case default
      do k = 1_I4P, st%npt
         call add_point(st, st%px(k), st%py(k), z)
      enddo
      call end_chunk(st, z)
   endselect
   endsubroutine put_line

   subroutine add_point(st, x, y, z)
   !< gnuplot's add_cntr_point: a point of the current chunk, a full chunk ended and its last point the next's first.
   type(tracer), intent(inout) :: st   !< Chunks.
   real(R8P),    intent(in)    :: x    !< Abscissa.
   real(R8P),    intent(in)    :: y    !< Ordinate.
   real(R8P),    intent(in)    :: z    !< Level.
   integer(I4P)                :: last !< Last point.

   if (st%ncur >= MAX_POINTS - 1_I4P) then
      last = st%ncur
      call end_chunk(st, z)
      st%cur(1) = st%cur(2 * last - 1)
      st%cur(2) = st%cur(2 * last)
      st%ncur = 1_I4P
   endif
   st%ncur = st%ncur + 1_I4P
   st%cur(2 * st%ncur - 1) = x
   st%cur(2 * st%ncur) = y
   endsubroutine add_point

   subroutine end_chunk(st, z)
   !< gnuplot's end_crnt_cntr: the current chunk kept, a NaN row after it.
   type(tracer), intent(inout) :: st !< Chunks.
   real(R8P),    intent(in)    :: z  !< Level.
   real(R8P),    allocatable   :: t(:)  !< Grown copy.
   integer(I4P), allocatable   :: ti(:) !< Grown copy.
   logical,      allocatable   :: tl(:) !< Grown copy.
   integer(I4P)                :: q  !< Point counter.

   if (st%nk + st%ncur + 1_I4P > size(st%kx)) then
      allocate(t(2 * (st%nk + st%ncur + 1_I4P)))
      t(1:st%nk) = st%kx(1:st%nk)
      call move_alloc(t, st%kx)
      allocate(t(2 * (st%nk + st%ncur + 1_I4P)))
      t(1:st%nk) = st%ky(1:st%nk)
      call move_alloc(t, st%ky)
      allocate(t(2 * (st%nk + st%ncur + 1_I4P)))
      t(1:st%nk) = st%kz(1:st%nk)
      call move_alloc(t, st%kz)
   endif
   if (st%nchunks + 1_I4P > size(st%kfirst)) then
      allocate(ti(2 * size(st%kfirst)))
      ti(1:st%nchunks) = st%kfirst(1:st%nchunks)
      call move_alloc(ti, st%kfirst)
      allocate(ti(2 * size(st%klast)))
      ti(1:st%nchunks) = st%klast(1:st%nchunks)
      call move_alloc(ti, st%klast)
      allocate(tl(2 * size(st%knew)))
      tl(1:st%nchunks) = st%knew(1:st%nchunks)
      call move_alloc(tl, st%knew)
   endif
   st%nchunks = st%nchunks + 1_I4P
   st%kfirst(st%nchunks) = st%nk + 1_I4P
   do q = 1_I4P, st%ncur
      st%nk = st%nk + 1_I4P
      st%kx(st%nk) = st%cur(2 * q - 1)
      st%ky(st%nk) = st%cur(2 * q)
      st%kz(st%nk) = z
   enddo
   st%klast(st%nchunks) = st%nk
   st%knew(st%nchunks) = .false.
   st%nk = st%nk + 1_I4P
   st%kx(st%nk) = ieee_value(1.0_R8P, ieee_quiet_nan)
   st%ky(st%nk) = st%kx(st%nk)
   st%kz(st%nk) = z
   st%ncur = 0_I4P
   endsubroutine end_chunk

   subroutine put_cubic(st, z, isclosed)
   !< gnuplot's put_contour_cubic: a cubic spline through the points, parameter the length of the stroke in grid units,
   !< `npoints` points per interval.
   type(tracer), intent(inout) :: st       !< Line and chunks.
   real(R8P),    intent(in)    :: z        !< Level.
   logical,      intent(in)    :: isclosed !< A closed line.
   real(R8P), allocatable      :: qx(:), qy(:) !< Points (the first again at the end of a closed line).
   real(R8P), allocatable      :: d2x(:), d2y(:), dt(:) !< Second derivatives, interval lengths.
   integer(I4P)                :: n        !< Points.
   logical                     :: ok       !< Spline made.

   n = st%npt
   allocate(qx(n + 1), qy(n + 1))
   qx(1:n) = st%px(1:n)
   qy(1:n) = st%py(1:n)
   if (isclosed) then
      if (.not. same_point(st, st%px(n), st%py(n), st%px(1), st%py(1))) then
         qx(n + 1) = st%px(1)
         qy(n + 1) = st%py(1)
         n = n + 1_I4P
      endif
   endif
   allocate(d2x(n + 1), d2y(n + 1), dt(n + 1))
   d2x = 0.0_R8P
   d2y = 0.0_R8P
   dt = 0.0_R8P
   if (n > 2_I4P) then
      call cubic_spline(n, qx, qy, d2x, d2y, dt, isclosed, st%unit_x, st%unit_y, ok)
      if (.not. ok) return
   elseif (n > 1_I4P) then
      dt(1) = 1.0_R8P
   else
      return
   endif
   call cubic_points(st, n, qx, qy, d2x, d2y, dt, 1_I4P + (n - 1_I4P) * st%settings%npoints, z)
   call end_chunk(st, z)
   endsubroutine put_cubic

   subroutine cubic_points(st, n, qx, qy, d2x, d2y, dt, n_intpol, z)
   !< gnuplot's intp_cubic_spline: `n_intpol` points of the spline, evenly in its parameter.
   type(tracer), intent(inout) :: st       !< Chunks.
   integer(I4P), intent(in)    :: n        !< Points.
   real(R8P),    intent(in)    :: qx(:), qy(:) !< Points.
   real(R8P),    intent(in)    :: d2x(:), d2y(:), dt(:) !< Second derivatives, interval lengths.
   integer(I4P), intent(in)    :: n_intpol !< Points made.
   real(R8P),    intent(in)    :: z        !< Level.
   real(R8P)                   :: t, t_skip, t_max, x0, x1, y0, y1, d, hx, dx0, dx01, hy, dy0, dy01 !< Spline.
   integer(I4P)                :: q        !< Interval.

   t_max = sum(dt(1:n - 1))
   t_skip = (1.0_R8P - 1.0e-7_R8P) * t_max / real(n_intpol - 1_I4P, R8P)
   t = 0.0_R8P
   x1 = qx(1)
   y1 = qy(1)
   call add_point(st, x1, y1, z)
   t = t + t_skip
   do q = 1_I4P, n - 1_I4P
      d = dt(q)
      x0 = x1
      y0 = y1
      x1 = qx(q + 1)
      y1 = qy(q + 1)
      hx = (x1 - x0) / d
      hy = (y1 - y0) / d
      dx0 = (d2x(q + 1) + 2.0_R8P * d2x(q)) / 6.0_R8P
      dy0 = (d2y(q + 1) + 2.0_R8P * d2y(q)) / 6.0_R8P
      dx01 = (d2x(q + 1) - d2x(q)) / (6.0_R8P * d)
      dy01 = (d2y(q + 1) - d2y(q)) / (6.0_R8P * d)
      do while (t <= dt(q))
         call add_point(st, x0 + t * (hx + (t - d) * (dx0 + t * dx01)), y0 + t * (hy + (t - d) * (dy0 + t * dy01)), z)
         t = t + t_skip
      enddo
      t = t - dt(q)
   enddo
   endsubroutine cubic_points

   subroutine put_bspline(st, z, isclosed)
   !< gnuplot's put_contour_bspline and gen_bspline_approx: the B-spline of order `order` (less than the points)
   !< through the points as control points, open or (closed) float knots, `npoints` points per section.
   type(tracer), intent(inout) :: st       !< Line and chunks.
   real(R8P),    intent(in)    :: z        !< Level.
   logical,      intent(in)    :: isclosed !< A closed line.
   real(R8P), allocatable      :: qx(:), qy(:) !< Control points (wrapped around for a closed line).
   integer(I4P)                :: n        !< Points.
   integer(I4P)                :: npt      !< Points traced.
   integer(I4P)                :: order    !< B-spline order (gnuplot's order - 1).
   integer(I4P)                :: knot     !< Knot index.
   integer(I4P)                :: first    !< First control point to blend.
   integer(I4P)                :: count    !< Points made.
   integer(I4P)                :: q        !< Counter.
   real(R8P)                   :: t, dtt, next_t, t_min, t_max, x, y !< Parameter, point.

   npt = st%npt
   n = npt
   if (n < 2_I4P) return
   order = st%settings%order - 1_I4P
   if (order > n - 1_I4P) order = n - 1_I4P
   allocate(qx(npt + order + 1), qy(npt + order + 1))
   qx(1:npt) = st%px(1:npt)
   qy(1:npt) = st%py(1:npt)
   if (isclosed) then
      ! circular: the points after the last are the first ones again (the first skipped if it equals the last)
      if (same_point(st, st%px(npt), st%py(npt), st%px(1), st%py(1))) then
         do q = 1_I4P, order - 1_I4P
            qx(npt + q) = st%px(1 + modulo(q, npt - 1_I4P))
            qy(npt + q) = st%py(1 + modulo(q, npt - 1_I4P))
         enddo
         n = n + order - 1_I4P
      else
         do q = 0_I4P, order - 1_I4P
            qx(npt + q + 1) = st%px(1 + modulo(q, npt))
            qy(npt + q + 1) = st%py(1 + modulo(q, npt))
         enddo
         n = n + order
      endif
   endif
   t_min = knot_value(isclosed, n, order, order)
   t_max = knot_value(isclosed, n, order, n)
   t = t_min
   next_t = t_min + 1.0_R8P
   knot = order
   first = 1_I4P
   dtt = 1.0_R8P / real(st%settings%npoints, R8P)
   count = 1_I4P
   do while (t < t_max)
      if (t > next_t) then
         first = first + 1_I4P
         knot = knot + 1_I4P
         next_t = next_t + 1.0_R8P
      endif
      call bspline_point(t, qx(1:n), qy(1:n), first, n, order, knot, isclosed, x, y)
      call add_point(st, x, y, z)
      count = count + 1_I4P
      if (count == st%settings%npoints * (n - order) + 1_I4P) exit
      t = t + dtt
   enddo
   call bspline_point(t_max - EPS, qx(1:n), qy(1:n), first, n, order, knot, isclosed, x, y)
   call add_point(st, x, y, z)
   call end_chunk(st, z)
   endsubroutine put_bspline

   pure subroutine cubic_spline(n, qx, qy, d2x, d2y, dt, isclosed, unit_x, unit_y, ok)
   !< gnuplot's gen_cubic_spline: the second derivatives `d2x`, `d2y` at the points and the interval lengths `dt` of the
   !< cubic spline through them (parameter the stroke length in grid units), right sides cut at cusps beyond 90
   !< degrees; `ok` false if the system has no solution.
   integer(I4P), intent(in)    :: n        !< Points (at least 3).
   real(R8P),    intent(in)    :: qx(:), qy(:) !< Points.
   real(R8P),    intent(inout) :: d2x(:), d2y(:), dt(:) !< Second derivatives, interval lengths (n + 1).
   logical,      intent(in)    :: isclosed !< A closed line (first point = last).
   real(R8P),    intent(in)    :: unit_x, unit_y !< Grid extent.
   logical,      intent(out)   :: ok       !< Solved.
   real(R8P), allocatable      :: m(:,:)   !< The tridiagonal matrix (3, row).
   real(R8P)                   :: norm     !< Cusp norm.
   integer(I4P)                :: nn       !< System size.
   integer(I4P)                :: i        !< Counter.

   allocate(m(3, n + 1))
   do i = 1_I4P, n - 1_I4P
      d2x(i) = qx(i + 1) - qx(i)
      d2y(i) = qy(i + 1) - qy(i)
      dt(i) = sqrt((d2x(i) / unit_x)**2 + (d2y(i) / unit_y)**2)
      d2x(i) = d2x(i) / dt(i)
      d2y(i) = d2y(i) / dt(i)
   enddo
   nn = n - 2_I4P
   if (isclosed) then
      dt(n) = dt(1)
      d2x(n) = d2x(1)
      d2y(n) = d2y(1)
      nn = nn + 1_I4P
   endif
   do i = 1_I4P, nn
      m(1, i) = dt(i)
      m(2, i) = 2.0_R8P * (dt(i) + dt(i + 1))
      m(3, i) = dt(i + 1)
      d2x(i) = (d2x(i + 1) - d2x(i)) * 6.0_R8P
      d2y(i) = (d2y(i + 1) - d2y(i)) * 6.0_R8P
      norm = sqrt((d2x(i) / unit_x)**2 + (d2y(i) / unit_y)**2) / 8.5_R8P
      if (norm > 1.0_R8P) then
         d2x(i) = d2x(i) / norm
         d2y(i) = d2y(i) / norm
      endif
   enddo
   if (.not. isclosed) then
      m(2, 1) = m(2, 1) + m(1, 1)
      m(1, 1) = 0.0_R8P
      m(2, nn) = m(2, nn) + m(3, nn)
      m(3, nn) = 0.0_R8P
   endif
   call cholesky(m, nn, ok)
   if (.not. ok) return
   call cholesky_solve(m, d2x, nn)
   call cholesky_solve(m, d2y, nn)
   do i = nn + 1_I4P, 2_I4P, -1_I4P
      d2x(i) = d2x(i - 1)
      d2y(i) = d2y(i - 1)
   enddo
   if (isclosed) then
      d2x(1) = d2x(nn + 1)
      d2y(1) = d2y(nn + 1)
   else
      d2x(1) = d2x(2)
      d2y(1) = d2y(2)
      d2x(nn + 2) = d2x(nn + 1)
      d2y(nn + 2) = d2y(nn + 1)
   endif
   endsubroutine cubic_spline

   pure subroutine cholesky(m, n, ok)
   !< gnuplot's solve_cubic_1: the Cholesky decomposition of the cyclic tridiagonal matrix `m` (n >= 1).
   real(R8P),    intent(inout) :: m(:,:) !< Matrix (3, row), decomposed.
   integer(I4P), intent(in)    :: n      !< Size.
   logical,      intent(out)   :: ok     !< Positive definite.
   real(R8P)                   :: m_ij, m_n, m_nn, d !< Elements.
   integer(I4P)                :: i      !< Counter.

   ok = .false.
   if (n < 1_I4P) return
   d = m(2, 1)
   if (d <= 0.0_R8P) return
   m_n = m(1, 1)
   m_nn = m(2, n)
   do i = 1_I4P, n - 2_I4P
      m_ij = m(3, i)
      m(3, i) = m_ij / d
      m(1, i) = m_n / d
      m_nn = m_nn - m(1, i) * m_n
      m_n = -m(3, i) * m_n
      d = m(2, i + 1) - m(3, i) * m_ij
      if (d <= 0.0_R8P) return
      m(2, i + 1) = d
   enddo
   if (n >= 2_I4P) then
      m_n = m_n + m(3, n - 1)
      m(1, n - 1) = m_n / d
      d = m_nn - m(1, n - 1) * m_n
      m(2, n) = d
      if (d <= 0.0_R8P) return
   endif
   ok = .true.
   endsubroutine cholesky

   pure subroutine cholesky_solve(m, x, n)
   !< gnuplot's solve_cubic_2: `x` overwritten by the solution of the decomposed system with right side `x`.
   real(R8P),    intent(in)    :: m(:,:) !< Decomposed matrix.
   real(R8P),    intent(inout) :: x(:)   !< Right side, solution.
   integer(I4P), intent(in)    :: n      !< Size.
   real(R8P)                   :: x_n    !< Last element.
   integer(I4P)                :: i      !< Counter.

   x_n = x(n)
   do i = 1_I4P, n - 2_I4P
      x(i + 1) = x(i + 1) - m(3, i) * x(i)
      x_n = x_n - m(1, i) * x(i)
   enddo
   if (n >= 2_I4P) x(n) = x_n - m(1, n - 1) * x(n - 1)
   do i = 1_I4P, n
      x(i) = x(i) / m(2, i)
   enddo
   x_n = x(n)
   if (n >= 2_I4P) x(n - 1) = x(n - 1) - m(1, n - 1) * x_n
   do i = n - 2_I4P, 1_I4P, -1_I4P
      x(i) = x(i) - (m(3, i) * x(i + 1) + m(1, i) * x_n)
   enddo
   endsubroutine cholesky_solve

   pure function knot_value(isclosed, n, order, i) result(t)
   !< gnuplot's fetch_knot: knot `i` (from 0) of the uniform knot vector, open (the first and last `order` equal) or
   !< float (closed lines).
   logical,      intent(in) :: isclosed !< Float knots.
   integer(I4P), intent(in) :: n        !< Control points.
   integer(I4P), intent(in) :: order    !< Order.
   integer(I4P), intent(in) :: i        !< Knot.
   real(R8P)                :: t        !< Knot value.

   if (isclosed) then
      t = real(i, R8P)
   elseif (i <= order) then
      t = 0.0_R8P
   elseif (i <= n) then
      t = real(i - order, R8P)
   else
      t = real(n - order, R8P)
   endif
   endfunction knot_value

   pure subroutine bspline_point(t, qx, qy, first, n, order, j, isclosed, x, y)
   !< gnuplot's eval_bspline (de Boor): the point at `t` of the B-spline blending the control points from `first`,
   !< knot index `j`.
   real(R8P),    intent(in)  :: t        !< Parameter.
   real(R8P),    intent(in)  :: qx(:), qy(:) !< Control points.
   integer(I4P), intent(in)  :: first    !< First control point to blend.
   integer(I4P), intent(in)  :: n        !< Control points.
   integer(I4P), intent(in)  :: order    !< Order.
   integer(I4P), intent(in)  :: j        !< Knot index.
   logical,      intent(in)  :: isclosed !< Float knots.
   real(R8P),    intent(out) :: x        !< Abscissa.
   real(R8P),    intent(out) :: y        !< Ordinate.
   real(R8P)                 :: dx(0:j + order), dy(0:j + order) !< Blending.
   real(R8P)                 :: ti, tikp !< Knots.
   integer(I4P)              :: i, p, c  !< Counters.

   dx = 0.0_R8P
   dy = 0.0_R8P
   c = first
   do i = j - order, j
      if (c <= size(qx, kind=I4P)) then
         dx(i) = qx(c)
         dy(i) = qy(c)
      endif
      c = c + 1_I4P
   enddo
   do p = 1_I4P, order
      do i = j, j - order + p, -1_I4P
         ti = knot_value(isclosed, n, order, i)
         tikp = knot_value(isclosed, n, order, i + order + 1_I4P - p)
         if (ti /= tikp) then
            dx(i) = dx(i) * (t - ti) / (tikp - ti) + dx(i - 1) * (tikp - t) / (tikp - ti)
            dy(i) = dy(i) * (t - ti) / (tikp - ti) + dy(i - 1) * (tikp - t) / (tikp - ti)
         endif
      enddo
   enddo
   x = dx(j)
   y = dy(j)
   endsubroutine bspline_point
endmodule foresight_contour
