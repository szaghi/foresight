!< foresight_voxel, gnuplot 6.0's voxel grids (`set vgrid`, `vfill`, `voxel()`, `with isosurface`).
module foresight_voxel
!< foresight_voxel, gnuplot 6.0's voxel grids (`set vgrid`, `vfill`, `voxel()`, `with isosurface`).
!<
!< A voxel grid is N x N x N values (single precision, as gnuplot's t_voxel) at evenly spaced points of its ranges
!< (`set vxrange`, ... or the fixed x, y and z ranges when first used), as gnuplot's voxelgrid.c: a point is looked up
!< at the grid point of indices ceil((x - min) / delta), `vfill` adds a density to the grid points within a radius of
!< each data point, `splot $grid with points|dots` draws the grid points above a level and `with isosurface` the
!< surface of a level by marching cubes (vplot.c, gnuplot's tables).
use foresight_voxel_tables, only : CUBE_EDGE_FLAGS, QT_TABLE, TRIANGLE_TABLE, VERTEX_OFFSET
use penf, only : I4P, I8P, R4P, R8P
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan, ieee_quiet_nan, ieee_value

implicit none
private
public :: vgrid_object

type :: vgrid_object
   !< A voxel grid.
   character(len=:), allocatable :: name     !< Its name (`$grid`).
   integer(I4P)                  :: n = 0_I4P !< Size: N x N x N.
   real(R8P)                     :: lo(3) = 0.0_R8P   !< Ranges' starts (x, y, z).
   real(R8P)                     :: hi(3) = 0.0_R8P   !< Ranges' ends.
   logical                       :: ranged(3) = .false. !< Ranges set.
   real(R8P)                     :: delta(3) = 0.0_R8P  !< Spacing.
   real(R4P), allocatable        :: v(:)     !< Values, x fastest.
   contains
      procedure, pass(self) :: resize     !< Zero values of a new size.
      procedure, pass(self) :: spacing    !< Its spacing, once ranged.
      procedure, pass(self) :: lookup     !< The value at a point (gnuplot's voxel()).
      procedure, pass(self) :: cell       !< The index of a point's grid point, 0 out of the ranges.
      procedure, pass(self) :: neighbours !< The grid points within a radius of a point (vfill).
      procedure, pass(self) :: above      !< The grid points above a level (with points|dots).
      procedure, pass(self) :: isosurface !< The facets of a level (marching cubes).
      procedure, pass(self) :: stats      !< Non-zero values' min, max, mean, deviation; zero count.
endtype vgrid_object

contains
   pure subroutine resize(self, n)
   !< `n` x `n` x `n` zero values (kept when the size is the same, as gnuplot's set vgrid).
   class(vgrid_object), intent(inout) :: self !< Grid.
   integer(I4P),        intent(in)    :: n    !< Size.

   if (self%n == n .and. allocated(self%v)) return
   self%n = n
   if (allocated(self%v)) deallocate(self%v)
   allocate(self%v(int(n, I8P)**3))
   self%v = 0.0_R4P
   endsubroutine resize

   pure subroutine spacing(self)
   !< The spacing of the ranged grid: (max - min) / (N - 1) on each axis.
   class(vgrid_object), intent(inout) :: self !< Grid.

   self%delta = (self%hi - self%lo) / real(self%n - 1_I4P, R8P)
   endsubroutine spacing

   pure function cell(self, p) result(k)
   !< The index (1 based) of the grid point of `p` (indices ceil((p - min) / delta), gnuplot's), 0 out of the ranges.
   class(vgrid_object), intent(in) :: self !< Grid.
   real(R8P),           intent(in) :: p(3) !< Point.
   integer(I8P)                    :: k    !< Index.
   integer(I8P)                    :: i(3) !< Indices.

   k = 0_I8P
   if (any(p < self%lo) .or. any(p > self%hi)) return
   if (any(ieee_is_nan(p))) return
   i = int(ceiling((p - self%lo) / self%delta), I8P)
   i = min(max(i, 0_I8P), int(self%n - 1_I4P, I8P))
   k = 1_I8P + i(1) + i(2) * self%n + i(3) * int(self%n, I8P)**2
   endfunction cell

   pure function lookup(self, p) result(value)
   !< The value at `p` (gnuplot's voxel(x,y,z)), NaN out of the ranges.
   class(vgrid_object), intent(in) :: self  !< Grid.
   real(R8P),           intent(in) :: p(3)  !< Point.
   real(R8P)                       :: value !< Value.
   integer(I8P)                    :: k     !< Index.

   k = self%cell(p)
   if (k == 0_I8P) then
      value = ieee_value(1.0_R8P, ieee_quiet_nan)
   else
      value = real(self%v(k), R8P)
   endif
   endfunction lookup

   pure subroutine neighbours(self, p, radius, grid_units, index, distance, grid_distance)
   !< The grid points within `radius` of `p` (gnuplot's modify_voxels): the brick of floor(radius / delta) points on
   !< each side of the nearest one (floor(radius) with `grid_units`, vgfill), those within the radius (in user or grid
   !< units) and the nearest one always; their indices, distances and grid distances.
   class(vgrid_object),       intent(in)  :: self             !< Grid.
   real(R8P),                 intent(in)  :: p(3)             !< Point.
   real(R8P),                 intent(in)  :: radius           !< Radius.
   logical,                   intent(in)  :: grid_units       !< Radius in grid units.
   integer(I8P), allocatable, intent(out) :: index(:)         !< Indices.
   real(R8P),    allocatable, intent(out) :: distance(:)      !< Distances.
   real(R8P),    allocatable, intent(out) :: grid_distance(:) !< Grid distances.
   real(R8P)                              :: g(3)             !< Fractional indices.
   integer(I4P)                           :: c(3)             !< Nearest grid point.
   integer(I4P)                           :: r(3)             !< Brick half sizes.
   integer(I4P)                           :: ix, iy, iz       !< Indices.
   integer(I4P)                           :: m                !< Points kept.
   real(R8P)                              :: d, gd            !< Distances.
   real(R8P)                              :: q(3)             !< A grid point.

   g = (p - self%lo) / self%delta
   c = ceiling(g)
   if (grid_units) then
      r = floor(radius)
   else
      r = floor(radius / self%delta)
   endif
   allocate(index(product(int(2_I4P * r + 1_I4P, I8P))), distance(product(int(2_I4P * r + 1_I4P, I8P))), &
            grid_distance(product(int(2_I4P * r + 1_I4P, I8P))))
   m = 0_I4P
   do ix = c(1) - r(1), c(1) + r(1)
      if (ix < 0_I4P .or. ix >= self%n) cycle
      do iy = c(2) - r(2), c(2) + r(2)
         if (iy < 0_I4P .or. iy >= self%n) cycle
         do iz = c(3) - r(3), c(3) + r(3)
            if (iz < 0_I4P .or. iz >= self%n) cycle
            q = self%lo + real([ix, iy, iz], R8P) * self%delta
            d = sqrt(sum((q - p)**2))
            gd = sqrt(sum((g - real([ix, iy, iz], R8P))**2))
            if (any([ix, iy, iz] /= c)) then
               if (grid_units) then
                  if (gd > radius) cycle
               else
                  if (d > radius) cycle
               endif
            endif
            m = m + 1_I4P
            index(m) = 1_I8P + ix + iy * int(self%n, I8P) + iz * int(self%n, I8P)**2
            distance(m) = d
            grid_distance(m) = gd
         enddo
      enddo
   enddo
   index = index(1:m)
   distance = distance(1:m)
   grid_distance = grid_distance(1:m)
   endsubroutine neighbours

   pure subroutine above(self, level, every, x, y, z, v)
   !< The grid points of values above `level` (gnuplot's vplot_points: x outermost, then y, then z), every `every`-th
   !< on each axis (`pointinterval`, 0 or 1 for all).
   class(vgrid_object),    intent(in)  :: self  !< Grid.
   real(R8P),              intent(in)  :: level !< Level.
   integer(I4P),           intent(in)  :: every !< Downsampling.
   real(R8P), allocatable, intent(out) :: x(:), y(:), z(:), v(:) !< Points and values.
   integer(I4P)                        :: ix, iy, iz !< Indices.
   integer(I8P)                        :: k, m       !< Index, points kept.

   m = count(real(self%v, R8P) > level)
   allocate(x(m), y(m), z(m), v(m))
   m = 0_I8P
   do ix = 0_I4P, self%n - 1_I4P
      do iy = 0_I4P, self%n - 1_I4P
         do iz = 0_I4P, self%n - 1_I4P
            if (every > 1_I4P) then
               if (mod(ix, every) /= 0_I4P .or. mod(iy, every) /= 0_I4P .or. mod(iz, every) /= 0_I4P) cycle
            endif
            k = 1_I8P + ix + iy * int(self%n, I8P) + iz * int(self%n, I8P)**2
            if (.not. real(self%v(k), R8P) > level) cycle
            m = m + 1_I8P
            x(m) = self%lo(1) + real(ix, R8P) * self%delta(1)
            y(m) = self%lo(2) + real(iy, R8P) * self%delta(2)
            z(m) = self%lo(3) + real(iz, R8P) * self%delta(3)
            v(m) = real(self%v(k), R8P)
         enddo
      enddo
   enddo
   x = x(1:m)
   y = y(1:m)
   z = z(1:m)
   v = v(1:m)
   endsubroutine above

   pure subroutine isosurface(self, level, triangles, x, y, z, nf)
   !< The facets of the surface of `level` (gnuplot's vplot_isosurface and tessellate_one_cube): each voxel cube's
   !< corner pattern (a corner below the level inside) cut by gnuplot's tables, its edges at the level by linear
   !< interpolation; quadrangles and triangles (gnuplot's default, `set isosurface mixed`) or triangles only
   !< (`triangles`). Facets of 4 corners each (a triangle repeats its third), `nf` of them, in gnuplot's order.
   class(vgrid_object),    intent(in)  :: self      !< Grid.
   real(R8P),              intent(in)  :: level     !< Level.
   logical,                intent(in)  :: triangles !< Triangles only.
   real(R8P), allocatable, intent(out) :: x(:, :), y(:, :), z(:, :) !< Corners (4, facet).
   integer(I4P),           intent(out) :: nf        !< Facets.
   real(R4P)                           :: corner(0:7) !< Corner values.
   real(R8P)                           :: cut(3, 0:11) !< Edge intersections (plot coordinates).
   real(R4P)                           :: iso       !< Level, single precision (gnuplot's t_voxel).
   integer(I4P), parameter             :: EDGE(2, 0:11) = reshape([0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, &
                                                                   0, 4, 1, 5, 2, 6, 3, 7], [2, 12]) !< Edge ends.
   integer(I4P)                        :: ix, iy, iz, c, e, it, flags, edges, j, w, nv
   integer(I4P)                        :: row(13)   !< The pattern's table row.
   real(R8P), allocatable              :: grow(:, :) !< Growth scratch.

   iso = real(level, R4P)
   allocate(x(4, 1024), y(4, 1024), z(4, 1024))
   nf = 0_I4P
   do ix = 0_I4P, self%n - 2_I4P
      do iy = 0_I4P, self%n - 2_I4P
         do iz = 0_I4P, self%n - 2_I4P
            flags = 0_I4P
            do c = 0_I4P, 7_I4P
               corner(c) = self%v(1_I8P + (ix + VERTEX_OFFSET(1, c)) + (iy + VERTEX_OFFSET(2, c)) * int(self%n, I8P) + &
                                  (iz + VERTEX_OFFSET(3, c)) * int(self%n, I8P)**2)
               if (corner(c) < iso) flags = ior(flags, ishft(1_I4P, c))
            enddo
            edges = CUBE_EDGE_FLAGS(flags + 1_I4P)
            if (edges == 0_I4P) cycle
            do e = 0_I4P, 11_I4P
               if (iand(edges, ishft(1_I4P, e)) == 0_I4P) cycle
               do j = 1_I4P, 3_I4P
                  associate(a => EDGE(1, e), b => EDGE(2, e))
                     if (VERTEX_OFFSET(j, b) == VERTEX_OFFSET(j, a)) then
                        cut(j, e) = real(VERTEX_OFFSET(j, a), R8P)
                     else
                        ! single precision, as gnuplot's (int * (float - float) / (float - float))
                        cut(j, e) = real(VERTEX_OFFSET(j, a), R8P) + &
                                    real(real(VERTEX_OFFSET(j, b) - VERTEX_OFFSET(j, a), R4P) * &
                                         (iso - corner(a)) / (corner(b) - corner(a)), R8P)
                     endif
                  endassociate
               enddo
               cut(:, e) = self%lo + (real([ix, iy, iz], R8P) + cut(:, e)) * self%delta
            enddo
            if (triangles) then
               row = TRIANGLE_TABLE(:, flags + 1_I4P)
               w = 3_I4P
            else
               row = QT_TABLE(:, flags + 1_I4P)
               w = 4_I4P
            endif
            do it = 0_I4P, merge(3_I4P, 2_I4P, triangles)
               if (row(w * it + 1_I4P) < 0_I4P) exit
               if (nf == size(x, 2, kind=I4P)) then
                  allocate(grow(4, 2 * nf))
                  grow(:, 1:nf) = x
                  call move_alloc(grow, x)
                  allocate(grow(4, 2 * nf))
                  grow(:, 1:nf) = y
                  call move_alloc(grow, y)
                  allocate(grow(4, 2 * nf))
                  grow(:, 1:nf) = z
                  call move_alloc(grow, z)
               endif
               nf = nf + 1_I4P
               nv = 3_I4P
               if (w == 4_I4P) then
                  if (row(w * it + 4_I4P) >= 0_I4P) nv = 4_I4P
               endif
               do j = 1_I4P, 4_I4P
                  e = row(w * it + min(j, nv))
                  x(j, nf) = cut(1, e)
                  y(j, nf) = cut(2, e)
                  z(j, nf) = cut(3, e)
               enddo
            enddo
         enddo
      enddo
   enddo
   endsubroutine isosurface

   pure subroutine stats(self, lo, hi, mean, deviation, zeros)
   !< The non-zero values' min, max, mean and standard deviation, and the zero count (gnuplot's vgrid_stats).
   class(vgrid_object), intent(in)  :: self      !< Grid.
   real(R8P),           intent(out) :: lo, hi    !< Min and max.
   real(R8P),           intent(out) :: mean      !< Mean.
   real(R8P),           intent(out) :: deviation !< Standard deviation.
   integer(I8P),        intent(out) :: zeros     !< Zero values.
   real(R8P)                        :: s, s2     !< Sums.
   integer(I8P)                     :: k, m      !< Index, non-zero count.

   lo = huge(1.0_R8P)
   hi = -huge(1.0_R8P)
   s = 0.0_R8P
   s2 = 0.0_R8P
   m = 0_I8P
   do k = 1_I8P, size(self%v, kind=I8P)
      if (.not. abs(self%v(k)) > 0.0_R4P) cycle
      m = m + 1_I8P
      lo = min(lo, real(self%v(k), R8P))
      hi = max(hi, real(self%v(k), R8P))
      s = s + real(self%v(k), R8P)
      s2 = s2 + real(self%v(k), R8P)**2
   enddo
   zeros = size(self%v, kind=I8P) - m
   if (m == 0_I8P) then
      lo = 0.0_R8P
      hi = 0.0_R8P
      mean = 0.0_R8P
      deviation = 0.0_R8P
   else
      mean = s / real(m, R8P)
      deviation = sqrt(max(0.0_R8P, s2 / real(m, R8P) - mean**2))
   endif
   endsubroutine stats
endmodule foresight_voxel
