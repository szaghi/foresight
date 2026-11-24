!< foresight_hulls, gnuplot's hull filters of a set of points: convexhull, concavehull and expand.
module foresight_hulls
!< foresight_hulls, gnuplot's hull filters of a set of points: convexhull, concavehull and expand.
!<
!< Ports of gnuplot 6.0's filters (filters.c, Ethan A Merritt 2021-2022), step by step so that the points come out in
!< gnuplot's order:
!<
!< - `convex_hull`: the bounding convex polygon (Graham's algorithm on the points sorted by x then y), clockwise from
!<   the point of smallest x, closed (its first point repeated at the end);
!< - `concave_hull`: a chi-shape (Duckham et al. 2008): the Delaunay triangulation (Bowyer-Watson), then the longest
!<   perimeter edge longer than the characteristic length removed with its triangle while that does not reduce the
!<   shape's connectivity to a single point; closed;
!< - `expand_hull`: each edge of a hull pushed outward by a distance, a convex vertex becoming two points (a bevel), a
!<   concave one moved toward the mouth of the concavity;
!< - `delaunay_triangles`: the triangles of the Delaunay triangulation, each closed (gnuplot's undocumented `delaunay`).
!<
!< The hulls return the rows of the points they keep (`idx`), so that the other columns of the data follow them.
use penf, only : I4P, R8P

implicit none
private
public :: concave_hull
public :: convex_hull
public :: delaunay_triangles
public :: expand_hull

integer(I4P), parameter :: GOOD = 1_I4P   !< Head of the list of the triangles of the triangulation.
integer(I4P), parameter :: BAD = 2_I4P    !< Head of the list of the triangles removed.
integer(I4P), parameter :: FROZEN = 3_I4P !< Head of the list of the triangles left of every point still to add.

type :: triangles_object
   !< Triangles in linked lists (gnuplot's), the slots GOOD, BAD and FROZEN the list heads.
   integer(I4P), allocatable :: v(:,:)     !< Vertices (3, slot), ascending.
   real(R8P),    allocatable :: c(:,:)     !< Circumcentre (2, slot).
   real(R8P),    allocatable :: r(:)       !< Circumradius.
   integer(I4P), allocatable :: next(:)    !< Next triangle of the list, 0 for none.
   integer(I4P)              :: n = 3_I4P  !< Slots in use.
endtype triangles_object

contains
   pure function cross(x1, y1, x2, y2, x3, y3) result(c)
   !< gnuplot's CROSS(p1, p2, p3): positive for a left turn p1 -> p2 -> p3.
   real(R8P), intent(in) :: x1, y1 !< First point.
   real(R8P), intent(in) :: x2, y2 !< Second point.
   real(R8P), intent(in) :: x3, y3 !< Third point.
   real(R8P)             :: c      !< Cross product.

   c = (x2 - x1) * (y3 - y2) - (y2 - y1) * (x3 - x2)
   endfunction cross

   pure subroutine sort_xy(x, y, order)
   !< The rows of (x, y) sorted by x then y, stably (gnuplot's compare_xyz through glibc's merge sort).
   real(R8P),                 intent(in)  :: x(:)     !< Abscissae.
   real(R8P),                 intent(in)  :: y(:)     !< Ordinates.
   integer(I4P), allocatable, intent(out) :: order(:) !< Sorted rows.
   integer(I4P), allocatable              :: work(:)  !< Merge buffer.
   integer(I4P)                           :: n        !< Points.
   integer(I4P)                           :: w        !< Run width.
   integer(I4P)                           :: lo       !< Run start.
   integer(I4P)                           :: mid      !< Second run start.
   integer(I4P)                           :: hi       !< Run end.
   integer(I4P)                           :: a        !< First run cursor.
   integer(I4P)                           :: b        !< Second run cursor.
   integer(I4P)                           :: k        !< Output cursor.
   integer(I4P)                           :: i        !< Counter.

   n = size(x, kind=I4P)
   order = [(i, i = 1_I4P, n)]
   allocate(work(n))
   w = 1_I4P
   do while (w < n)
      lo = 1_I4P
      do while (lo <= n)
         mid = min(lo + w, n + 1_I4P)
         hi = min(lo + 2_I4P * w - 1_I4P, n)
         a = lo
         b = mid
         k = lo
         do while (a < mid .or. b <= hi)
            if (b > hi) then
               work(k) = order(a)
               a = a + 1_I4P
            elseif (a >= mid) then
               work(k) = order(b)
               b = b + 1_I4P
            elseif (x(order(a)) > x(order(b)) .or. (x(order(a)) == x(order(b)) .and. y(order(a)) > y(order(b)))) then
               work(k) = order(b)
               b = b + 1_I4P
            else
               work(k) = order(a)
               a = a + 1_I4P
            endif
            k = k + 1_I4P
         enddo
         lo = lo + 2_I4P * w
      enddo
      order = work
      w = 2_I4P * w
   enddo
   endsubroutine sort_xy

   pure subroutine convex_hull(x, y, idx)
   !< gnuplot's `convexhull`: the rows of the convex hull of (x, y), clockwise from the smallest x, the first repeated at
   !< the end; fewer than 3 points are kept as they are, 3 closed in their order.
   real(R8P),                 intent(in)  :: x(:)   !< Abscissae.
   real(R8P),                 intent(in)  :: y(:)   !< Ordinates.
   integer(I4P), allocatable, intent(out) :: idx(:) !< Hull rows.
   integer(I4P), allocatable              :: p(:)   !< Rows sorted by x, y.
   integer(I4P), allocatable              :: s(:)   !< Stack of hull rows.
   integer(I4P)                           :: n      !< Points.
   integer(I4P)                           :: np     !< Stack height.
   integer(I4P)                           :: ntop   !< Stack height at the start of the lower arc.
   integer(I4P)                           :: i      !< Counter.

   n = size(x, kind=I4P)
   if (n < 3_I4P) then
      idx = [(i, i = 1_I4P, n)]
      return
   elseif (n == 3_I4P) then
      idx = [1_I4P, 2_I4P, 3_I4P, 1_I4P]
      return
   endif
   call sort_xy(x, y, p)
   allocate(s(n + 1_I4P))
   ! the upper arc, left to right
   s(1) = p(1)
   s(2) = p(2)
   np = 2_I4P
   do i = 3_I4P, n
      do while (np >= 2_I4P)
         if (cross(x(s(np - 1)), y(s(np - 1)), x(s(np)), y(s(np)), x(p(i)), y(p(i))) < 0.0_R8P) exit
         np = np - 1_I4P
      enddo
      np = np + 1_I4P
      s(np) = p(i)
   enddo
   ! the lower arc, right to left, from the point before the last
   np = np + 1_I4P
   s(np) = p(n - 1_I4P)
   ntop = np
   do i = n - 2_I4P, 1_I4P, -1_I4P
      do while (np >= ntop)
         if (cross(x(s(np - 1)), y(s(np - 1)), x(s(np)), y(s(np)), x(p(i)), y(p(i))) < 0.0_R8P) exit
         np = np - 1_I4P
      enddo
      np = np + 1_I4P
      s(np) = p(i)
   enddo
   idx = s(1:np)
   endsubroutine convex_hull

   pure subroutine expand_hull(x, y, d, ex, ey, src)
   !< gnuplot's `expand D` of a closed hull (x, y): each edge pushed outward by |D|; a convex vertex replaced by the two
   !< ends of the displaced edges, a concave one moved toward the mouth of the concavity. `src` the hull point each new
   !< point comes from.
   real(R8P),                 intent(in)  :: x(:)   !< Hull abscissae, closed.
   real(R8P),                 intent(in)  :: y(:)   !< Hull ordinates, closed.
   real(R8P),                 intent(in)  :: d      !< Displacement (its magnitude).
   real(R8P),    allocatable, intent(out) :: ex(:)  !< Expanded abscissae.
   real(R8P),    allocatable, intent(out) :: ey(:)  !< Expanded ordinates.
   integer(I4P), allocatable, intent(out) :: src(:) !< Hull point of each new point.
   real(R8P)                              :: dd     !< |D|.
   real(R8P)                              :: winding !< +1 clockwise, -1 anticlockwise.
   real(R8P)                              :: dx1, dy1 !< Displacement of the edge before the vertex.
   real(R8P)                              :: dx2, dy2 !< Displacement of the edge after the vertex.
   real(R8P)                              :: dnorm  !< Concave vertex scale.
   real(R8P)                              :: xmin   !< Smallest abscissa.
   integer(I4P)                           :: n      !< Hull points.
   integer(I4P)                           :: pin    !< Point of smallest x (the highest of them).
   integer(I4P)                           :: i1, i2, i3 !< Vertex and its neighbours.
   integer(I4P)                           :: m      !< New points.
   integer(I4P)                           :: i      !< Counter.

   n = size(x, kind=I4P)
   allocate(ex(2_I4P * n), ey(2_I4P * n), src(2_I4P * n))
   m = 0_I4P
   if (n < 3_I4P) then
      ex = x
      ey = y
      src = [(i, i = 1_I4P, n)]
      return
   endif
   dd = abs(d)
   ! the orientation, at the leftmost vertex (the highest of those of smallest x)
   xmin = huge(1.0_R8P)
   pin = 1_I4P
   do i = 1_I4P, n
      if (x(i) == xmin .and. y(i) > y(pin)) pin = i
      if (x(i) < xmin) then
         xmin = x(i)
         pin = i
      endif
   enddo
   i1 = merge(n - 1_I4P, pin - 1_I4P, pin == 1_I4P)
   i3 = min(pin + 1_I4P, n)
   winding = merge(1.0_R8P, -1.0_R8P, cross(x(pin), y(pin), x(i1), y(i1), x(i3), y(i3)) > 0.0_R8P)
   do i = 1_I4P, n
      i1 = merge(n - 1_I4P, i - 1_I4P, i == 1_I4P)
      i2 = i
      i3 = merge(2_I4P, i + 1_I4P, i == n)
      call displacement(x(i2) - x(i1), y(i2) - y(i1), dd, winding, dx1, dy1)
      call displacement(x(i3) - x(i2), y(i3) - y(i2), dd, winding, dx2, dy2)
      if (winding * cross(x(i1), y(i1), x(i2), y(i2), x(i3), y(i3)) < 0.0_R8P) then
         ! convex vertex: a bevel
         m = m + 1_I4P
         ex(m) = x(i2) + dx1
         ey(m) = y(i2) + dy1
         src(m) = i2
         m = m + 1_I4P
         ex(m) = x(i2) + dx2
         ey(m) = y(i2) + dy2
         src(m) = i2
      else
         ! concave vertex
         dnorm = (dx1 + dx2)**2 + (dy1 + dy2)**2
         m = m + 1_I4P
         if (dnorm > 0.0_R8P) then
            dnorm = dd / sqrt(dnorm)
            ex(m) = x(i2) + dnorm * (dx1 + dx2)
            ey(m) = y(i2) + dnorm * (dy1 + dy2)
         else
            ex(m) = x(i2)
            ey(m) = y(i2)
         endif
         src(m) = i2
      endif
   enddo
   ex = ex(1:m)
   ey = ey(1:m)
   src = src(1:m)
   endsubroutine expand_hull

   pure subroutine displacement(ux, uy, dd, winding, dx, dy)
   !< The outward displacement of a hull edge of direction (ux, uy): length `dd` along its normal (gnuplot's, through
   !< the slope, written without its divisions by zero).
   real(R8P), intent(in)  :: ux      !< Edge x extent.
   real(R8P), intent(in)  :: uy      !< Edge y extent.
   real(R8P), intent(in)  :: dd      !< Displacement length.
   real(R8P), intent(in)  :: winding !< +1 clockwise hull, -1 anticlockwise.
   real(R8P), intent(out) :: dx      !< Displacement x.
   real(R8P), intent(out) :: dy      !< Displacement y.
   real(R8P)              :: d2      !< Squared x displacement.

   d2 = 0.0_R8P
   if (ux * ux + uy * uy > 0.0_R8P) d2 = dd * dd * uy * uy / (ux * ux + uy * uy)
   dx = sign(sqrt(d2), -winding * uy)
   dy = sign(sqrt(max(dd * dd - d2, 0.0_R8P)), winding * ux)
   endsubroutine displacement

   pure subroutine concave_hull(x, y, chi_length, fraction, idx, chi_used)
   !< gnuplot's `concavehull`: the rows of the chi-shape of (x, y), closed; `chi_length` its characteristic length, if
   !< positive, else `fraction` of the longest edge of the convex hull (gnuplot's `set chi_shape fraction`, 0.6), the one
   !< used returned (GPVAL_CHI_LENGTH).
   real(R8P),                 intent(in)  :: x(:)       !< Abscissae.
   real(R8P),                 intent(in)  :: y(:)       !< Ordinates.
   real(R8P),                 intent(in)  :: chi_length !< Characteristic length, 0 or less for the default.
   real(R8P),                 intent(in)  :: fraction   !< Default length, fraction of the longest hull edge.
   integer(I4P), allocatable, intent(out) :: idx(:)     !< Hull rows.
   real(R8P),                 intent(out) :: chi_used   !< Characteristic length used.
   type(triangles_object)                 :: tri        !< Triangles.
   integer(I4P), allocatable              :: perm(:)    !< Rows sorted by x, y.
   real(R8P),    allocatable              :: px(:)      !< Sorted abscissae, then the 4 bounding vertices.
   real(R8P),    allocatable              :: py(:)      !< Sorted ordinates, then the 4 bounding vertices.
   logical,      allocatable              :: on_hull(:) !< Point on the current perimeter.
   integer(I4P), allocatable              :: edges(:,:) !< Edges (2, edge).
   real(R8P),    allocatable              :: lengths(:) !< Edge lengths.
   integer(I4P), allocatable              :: ring(:)    !< Perimeter, sorted point numbers.
   integer(I4P)                           :: nedges     !< Perimeter edges.
   integer(I4P)                           :: n          !< Points.
   integer(I4P)                           :: prev       !< Last perimeter point.
   integer(I4P)                           :: i          !< Counter.
   integer(I4P)                           :: k          !< Counter.
   logical                                :: dug        !< An edge removed or flagged.

   n = size(x, kind=I4P)
   chi_used = chi_length
   if (n < 3_I4P) then
      idx = [(i, i = 1_I4P, n)]
      return
   endif
   call sort_xy(x, y, perm)
   allocate(px(n + 4_I4P), py(n + 4_I4P))
   px(1:n) = x(perm)
   py(1:n) = y(perm)
   call delaunay(px, py, n, tri, edges, lengths, nedges, on_hull)
   if (nedges < 1_I4P) then
      call convex_hull(x, y, idx)
      return
   endif
   ! no length given: a fraction of the longest edge of the convex hull
   if (.not. chi_used > 0.0_R8P) chi_used = fraction * maxval(lengths(1:nedges))
   call sort_lengths(edges, lengths, nedges)
   do
      call dig_one_hole(tri, px, py, chi_used, on_hull, edges, lengths, nedges, dug)
      if (.not. dug) exit
      call sort_lengths(edges, lengths, nedges)
   enddo
   ! the perimeter as a closed curve, edge after edge from the longest
   allocate(ring(nedges + 1_I4P))
   ring(1) = edges(1, 1)
   ring(2) = edges(2, 1)
   prev = edges(2, 1)
   edges(:, 1) = -1_I4P
   do k = 3_I4P, nedges
      ring(k) = ring(k - 1_I4P)
      do i = 2_I4P, nedges
         if (prev == edges(1, i)) then
            prev = edges(2, i)
         elseif (prev == edges(2, i)) then
            prev = edges(1, i)
         else
            cycle
         endif
         ring(k) = prev
         edges(:, i) = -1_I4P
         exit
      enddo
   enddo
   ring(nedges + 1_I4P) = ring(1)
   idx = perm(ring)
   endsubroutine concave_hull

   pure subroutine delaunay_triangles(x, y, idx)
   !< gnuplot's `delaunay` filter: the rows of each triangle of the Delaunay triangulation of (x, y), closed (its first
   !< vertex again), then 0 for a blank line, in gnuplot's order.
   real(R8P),                 intent(in)  :: x(:)       !< Abscissae.
   real(R8P),                 intent(in)  :: y(:)       !< Ordinates.
   integer(I4P), allocatable, intent(out) :: idx(:)     !< Triangle rows, 0 between triangles.
   type(triangles_object)                 :: tri        !< Triangles.
   integer(I4P), allocatable              :: perm(:)    !< Rows sorted by x, y.
   real(R8P),    allocatable              :: px(:)      !< Sorted abscissae, then the 4 bounding vertices.
   real(R8P),    allocatable              :: py(:)      !< Sorted ordinates, then the 4 bounding vertices.
   logical,      allocatable              :: on_hull(:) !< Points on the perimeter.
   integer(I4P), allocatable              :: edges(:,:) !< Perimeter edges.
   real(R8P),    allocatable              :: lengths(:) !< Their lengths.
   integer(I4P)                           :: nedges     !< Perimeter edges.
   integer(I4P)                           :: n          !< Points.
   integer(I4P)                           :: m          !< Rows out.
   integer(I4P)                           :: t          !< Triangle.

   n = size(x, kind=I4P)
   allocate(idx(0))
   if (n < 3_I4P) return
   call sort_xy(x, y, perm)
   allocate(px(n + 4_I4P), py(n + 4_I4P))
   px(1:n) = x(perm)
   py(1:n) = y(perm)
   call delaunay(px, py, n, tri, edges, lengths, nedges, on_hull)
   m = 0_I4P
   t = tri%next(GOOD)
   do while (t /= 0_I4P)
      m = m + 1_I4P
      t = tri%next(t)
   enddo
   deallocate(idx)
   allocate(idx(5_I4P * m))
   m = 0_I4P
   t = tri%next(GOOD)
   do while (t /= 0_I4P)
      idx(m + 1_I4P:m + 5_I4P) = [perm(tri%v(1, t)), perm(tri%v(2, t)), perm(tri%v(3, t)), perm(tri%v(1, t)), 0_I4P]
      m = m + 5_I4P
      t = tri%next(t)
   enddo
   endsubroutine delaunay_triangles

   pure subroutine dig_one_hole(tri, px, py, chi, on_hull, edges, lengths, nedges, dug)
   !< gnuplot's dig_one_hole: the longest perimeter edge (the first), if longer than `chi`, removed with its triangle
   !< (its two other edges on the perimeter), unless the triangle's third vertex is on the perimeter already (the edge
   !< then flagged not removable, length -1).
   type(triangles_object),    intent(inout) :: tri        !< Triangles.
   real(R8P),                 intent(in)    :: px(:)      !< Abscissae.
   real(R8P),                 intent(in)    :: py(:)      !< Ordinates.
   real(R8P),                 intent(in)    :: chi        !< Characteristic length.
   logical,                   intent(inout) :: on_hull(:) !< Points on the perimeter.
   integer(I4P), allocatable, intent(inout) :: edges(:,:) !< Perimeter edges (2, edge).
   real(R8P),    allocatable, intent(inout) :: lengths(:) !< Their lengths.
   integer(I4P),              intent(inout) :: nedges     !< Perimeter edges.
   logical,                   intent(out)   :: dug        !< An edge removed or flagged.
   integer(I4P)                             :: t          !< Triangle.
   integer(I4P)                             :: pt         !< Triangle before it.
   integer(I4P)                             :: apex       !< Vertex opposite the edge.
   integer(I4P)                             :: edge1(2)   !< First new perimeter edge.
   integer(I4P)                             :: edge2(2)   !< Second new perimeter edge.

   dug = .false.
   if (lengths(1) <= chi) return
   pt = GOOD
   t = tri%next(pt)
   do while (t /= 0_I4P)
      apex = 0_I4P
      if (edges(1, 1) == tri%v(1, t)) then
         if (edges(2, 1) == tri%v(2, t)) then
            apex = tri%v(3, t)
            edge1 = [tri%v(1, t), tri%v(3, t)]
            edge2 = [tri%v(2, t), tri%v(3, t)]
         elseif (edges(2, 1) == tri%v(3, t)) then
            apex = tri%v(2, t)
            edge1 = [edges(1, 1), tri%v(2, t)]
            edge2 = [tri%v(2, t), tri%v(3, t)]
         endif
      elseif (edges(1, 1) == tri%v(2, t)) then
         if (edges(2, 1) == tri%v(3, t)) then
            apex = tri%v(1, t)
            edge1 = [tri%v(1, t), tri%v(2, t)]
            edge2 = [tri%v(1, t), tri%v(3, t)]
         endif
      endif
      if (apex > 0_I4P) then
         dug = .true.
         if (on_hull(apex)) then
            lengths(1) = -1.0_R8P
            return
         endif
         on_hull(apex) = .true.
         edges(:, 1) = edge1
         lengths(1) = sqrt((px(edge1(1)) - px(edge1(2)))**2 + (py(edge1(1)) - py(edge1(2)))**2)
         nedges = nedges + 1_I4P
         if (nedges > size(lengths, kind=I4P)) call grow_edges(edges, lengths)
         edges(:, nedges) = edge2
         lengths(nedges) = sqrt((px(edge2(1)) - px(edge2(2)))**2 + (py(edge2(1)) - py(edge2(2)))**2)
         call move_triangle(tri, pt, t, BAD)
         return
      endif
      pt = t
      t = tri%next(t)
   enddo
   endsubroutine dig_one_hole

   pure subroutine delaunay(px, py, n, tri, edges, lengths, nedges, on_hull)
   !< gnuplot's delaunay_triangulation (Bowyer-Watson) of the `n` points sorted by x in (px, py), whose 4 last slots
   !< take the vertices of the two bounding triangles: the triangles in the GOOD list, the perimeter edges (sorted
   !< point numbers, their lengths) and the points on it.
   real(R8P),                 intent(inout) :: px(:)      !< Abscissae, n + 4.
   real(R8P),                 intent(inout) :: py(:)      !< Ordinates, n + 4.
   integer(I4P),              intent(in)    :: n          !< Points.
   type(triangles_object),    intent(out)   :: tri        !< Triangles.
   integer(I4P), allocatable, intent(out)   :: edges(:,:) !< Perimeter edges (2, edge).
   real(R8P),    allocatable, intent(out)   :: lengths(:) !< Their lengths.
   integer(I4P),              intent(out)   :: nedges     !< Perimeter edges.
   logical,      allocatable, intent(out)   :: on_hull(:) !< Points on the perimeter.
   integer(I4P), allocatable                :: cavity(:,:) !< Edges of the removed triangles.
   real(R8P)                                :: gap        !< Distance of the bounding vertices.
   integer(I4P)                             :: frozen_tail !< Last frozen triangle (the first frozen), 0 if none.
   integer(I4P)                             :: ncav       !< Cavity edges.
   integer(I4P)                             :: t          !< Triangle.
   integer(I4P)                             :: pt         !< Triangle before it.
   integer(I4P)                             :: p          !< Point.
   integer(I4P)                             :: e          !< Edge counter.
   integer(I4P)                             :: a, b       !< Edge ends.
   logical                                  :: inside     !< The point in a triangle's circumcircle.
   logical                                  :: left       !< The circumcircle left of the point.

   allocate(tri%v(3, 64), tri%c(2, 64), tri%r(64), tri%next(64))
   tri%next = 0_I4P
   tri%n = 3_I4P
   gap = 100.0_R8P * max(maxval(px(1:n)) - minval(px(1:n)), maxval(py(1:n)) - minval(py(1:n)))
   px(n + 1:n + 4) = [minval(px(1:n)) - gap, maxval(px(1:n)) + gap, minval(px(1:n)) - gap, maxval(px(1:n)) + gap]
   py(n + 1:n + 4) = [minval(py(1:n)) - gap, minval(py(1:n)) - gap, maxval(py(1:n)) + gap, maxval(py(1:n)) + gap]
   call insert_triangle(tri, px, py, n + 1_I4P, n + 2_I4P, n + 3_I4P)
   call insert_triangle(tri, px, py, n + 2_I4P, n + 3_I4P, n + 4_I4P)
   frozen_tail = 0_I4P
   allocate(cavity(2, 96))
   do p = 1_I4P, n
      ! duplicate points once
      if (px(p) == px(p + 1) .and. py(p) == py(p + 1)) cycle
      ! the triangles whose circumcircle holds the point removed; those left of it for good frozen
      tri%next(BAD) = 0_I4P
      pt = GOOD
      t = tri%next(pt)
      do while (t /= 0_I4P)
         ! a triangle of collinear vertices (r < 0) has no circumcircle: kept (gnuplot's comparisons of NaN)
         inside = .false.
         left = .false.
         if (tri%r(t) >= 0.0_R8P) then
            inside = (tri%c(1, t) - px(p))**2 + (tri%c(2, t) - py(p))**2 < tri%r(t)**2
            left = tri%c(1, t) + tri%r(t) < px(p)
         endif
         if (inside) then
            call move_triangle(tri, pt, t, BAD)
         elseif (left) then
            call move_triangle(tri, pt, t, FROZEN)
            if (frozen_tail == 0_I4P) frozen_tail = t
         else
            pt = t
         endif
         t = tri%next(pt)
      enddo
      if (tri%next(BAD) == 0_I4P) cycle
      ! the edges of the cavity: those of the removed triangles, any shared one dropped
      ncav = 0_I4P
      t = tri%next(BAD)
      do while (t /= 0_I4P)
         if (ncav + 3_I4P > size(cavity, 2, kind=I4P)) cavity = reshape(cavity, [2, 2 * size(cavity, 2)], &
                                                                         pad=[0_I4P])
         cavity(:, ncav + 1) = [min(tri%v(1, t), tri%v(2, t)), max(tri%v(1, t), tri%v(2, t))]
         cavity(:, ncav + 2) = [min(tri%v(2, t), tri%v(3, t)), max(tri%v(2, t), tri%v(3, t))]
         cavity(:, ncav + 3) = [min(tri%v(3, t), tri%v(1, t)), max(tri%v(3, t), tri%v(1, t))]
         ncav = ncav + 3_I4P
         t = tri%next(t)
      enddo
      call sort_pairs(cavity, ncav)
      do e = 1_I4P, ncav - 1_I4P
         if (cavity(1, e) == cavity(1, e + 1) .and. cavity(2, e) == cavity(2, e + 1)) then
            cavity(1, e) = -1_I4P
            cavity(1, e + 1) = -1_I4P
         endif
      enddo
      do e = 1_I4P, ncav
         if (cavity(1, e) >= 0_I4P) call insert_triangle(tri, px, py, cavity(1, e), cavity(2, e), p)
      enddo
   enddo
   ! the frozen triangles back in the list
   if (frozen_tail /= 0_I4P) then
      tri%next(frozen_tail) = tri%next(GOOD)
      tri%next(GOOD) = tri%next(FROZEN)
      tri%next(FROZEN) = 0_I4P
   endif
   ! the triangles touching a bounding vertex removed: their other edges the perimeter
   tri%next(BAD) = 0_I4P
   pt = GOOD
   t = tri%next(pt)
   do while (t /= 0_I4P)
      if (any(tri%v(:, t) > n)) then
         call move_triangle(tri, pt, t, BAD)
      else
         pt = t
      endif
      t = tri%next(pt)
   enddo
   allocate(on_hull(n))
   on_hull = .false.
   allocate(edges(2, 16), lengths(16))
   nedges = 0_I4P
   t = tri%next(BAD)
   do while (t /= 0_I4P)
      a = merge(tri%v(3, t), tri%v(1, t), tri%v(1, t) > n)
      b = merge(tri%v(3, t), tri%v(2, t), tri%v(2, t) > n)
      if (.not. (a == b .or. a > n .or. b > n)) then
         nedges = nedges + 1_I4P
         if (nedges > size(lengths, kind=I4P)) call grow_edges(edges, lengths)
         edges(:, nedges) = [a, b]
         on_hull(a) = .true.
         on_hull(b) = .true.
         lengths(nedges) = sqrt((px(a) - px(b))**2 + (py(a) - py(b))**2)
      endif
      t = tri%next(t)
   enddo
   endsubroutine delaunay

   pure subroutine insert_triangle(tri, px, py, a, b, c)
   !< A new triangle (a, b, c), its vertices ascending, at the head of the GOOD list, with its circumcircle.
   type(triangles_object), intent(inout) :: tri   !< Triangles.
   real(R8P),              intent(in)    :: px(:) !< Abscissae.
   real(R8P),              intent(in)    :: py(:) !< Ordinates.
   integer(I4P),           intent(in)    :: a     !< Vertex.
   integer(I4P),           intent(in)    :: b     !< Vertex.
   integer(I4P),           intent(in)    :: c     !< Vertex.
   real(R8P)                             :: bx, by, cx, cy, dd !< Circumcircle terms (gnuplot's).
   real(R8P)                             :: ux, uy !< Centre from the first vertex.
   integer(I4P)                          :: t     !< New slot.

   if (tri%n == size(tri%r, kind=I4P)) then
      tri%v = reshape(tri%v, [3, 2 * size(tri%r)], pad=[0_I4P])
      tri%c = reshape(tri%c, [2, 2 * size(tri%r)], pad=[0.0_R8P])
      tri%r = [tri%r, spread(0.0_R8P, 1, size(tri%r))]
      tri%next = [tri%next, spread(0_I4P, 1, size(tri%next))]
   endif
   tri%n = tri%n + 1_I4P
   t = tri%n
   tri%v(1, t) = min(a, b, c)
   tri%v(3, t) = max(a, b, c)
   tri%v(2, t) = a + b + c - tri%v(1, t) - tri%v(3, t)
   tri%next(t) = tri%next(GOOD)
   tri%next(GOOD) = t
   bx = px(tri%v(2, t)) - px(tri%v(1, t))
   by = py(tri%v(2, t)) - py(tri%v(1, t))
   cx = px(tri%v(3, t)) - px(tri%v(1, t))
   cy = py(tri%v(3, t)) - py(tri%v(1, t))
   dd = 2.0_R8P * (bx * cy - by * cx)
   if (dd /= 0.0_R8P) then
      ux = (cy * (bx * bx + by * by) - by * (cx * cx + cy * cy)) / dd
      uy = (bx * (cx * cx + cy * cy) - cx * (bx * bx + by * by)) / dd
      tri%r(t) = sqrt(ux * ux + uy * uy)
   else
      ! collinear vertices: no circumcircle (gnuplot's divides by zero), flagged by a negative radius
      ux = 0.0_R8P
      uy = 0.0_R8P
      tri%r(t) = -1.0_R8P
   endif
   tri%c(1, t) = ux + px(tri%v(1, t))
   tri%c(2, t) = uy + py(tri%v(1, t))
   endsubroutine insert_triangle

   pure subroutine move_triangle(tri, pt, t, head)
   !< Triangle `t`, after `pt` in its list, moved to the head of the list `head` (gnuplot's invalidate or freeze).
   type(triangles_object), intent(inout) :: tri  !< Triangles.
   integer(I4P),           intent(in)    :: pt   !< Triangle before it.
   integer(I4P),           intent(in)    :: t    !< Triangle.
   integer(I4P),           intent(in)    :: head !< Destination list.

   tri%next(pt) = tri%next(t)
   tri%next(t) = tri%next(head)
   tri%next(head) = t
   endsubroutine move_triangle

   pure subroutine sort_pairs(pairs, n)
   !< The first `n` pairs sorted by their first then second element (insertion sort; equal pairs are equal).
   integer(I4P), intent(inout) :: pairs(:,:) !< Pairs (2, pair).
   integer(I4P), intent(in)    :: n          !< Pairs in use.
   integer(I4P)                :: key(2)     !< Pair moved.
   integer(I4P)                :: i          !< Counter.
   integer(I4P)                :: j          !< Counter.

   do i = 2_I4P, n
      key = pairs(:, i)
      j = i - 1_I4P
      do while (j >= 1_I4P)
         if (pairs(1, j) < key(1) .or. (pairs(1, j) == key(1) .and. pairs(2, j) <= key(2))) exit
         pairs(:, j + 1) = pairs(:, j)
         j = j - 1_I4P
      enddo
      pairs(:, j + 1) = key
   enddo
   endsubroutine sort_pairs

   pure subroutine sort_lengths(edges, lengths, n)
   !< The first `n` edges sorted by decreasing length, stably (gnuplot's compare_edgelength through glibc's merge sort).
   integer(I4P), intent(inout) :: edges(:,:) !< Edges (2, edge).
   real(R8P),    intent(inout) :: lengths(:) !< Lengths.
   integer(I4P), intent(in)    :: n          !< Edges in use.
   integer(I4P)                :: key(2)     !< Edge moved.
   real(R8P)                   :: l          !< Its length.
   integer(I4P)                :: i          !< Counter.
   integer(I4P)                :: j          !< Counter.

   do i = 2_I4P, n
      key = edges(:, i)
      l = lengths(i)
      j = i - 1_I4P
      do while (j >= 1_I4P)
         if (.not. lengths(j) < l) exit
         edges(:, j + 1) = edges(:, j)
         lengths(j + 1) = lengths(j)
         j = j - 1_I4P
      enddo
      edges(:, j + 1) = key
      lengths(j + 1) = l
   enddo
   endsubroutine sort_lengths

   pure subroutine grow_edges(edges, lengths)
   !< Twice the room for perimeter edges.
   integer(I4P), allocatable, intent(inout) :: edges(:,:) !< Edges (2, edge).
   real(R8P),    allocatable, intent(inout) :: lengths(:) !< Lengths.

   edges = reshape(edges, [2, 2 * size(lengths)], pad=[0_I4P])
   lengths = [lengths, spread(0.0_R8P, 1, size(lengths))]
   endsubroutine grow_edges
endmodule foresight_hulls
