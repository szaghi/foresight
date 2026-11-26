!< foresight_pm3d, gnuplot's pm3d: the surfaces of the 3D plots as colored quadrangles.
module foresight_pm3d
!< foresight_pm3d, gnuplot's pm3d: the surfaces of the 3D plots as colored quadrangles.
!<
!< A port of gnuplot 6.0's pm3d.c (pm3d_plot): each pair of neighbouring scans of a surface grid joined point by point
!< into quadrangles, each colored by its corners (`corners2color`: their mean, geometric or harmonic mean, rms, median,
!< minimum, maximum, or one corner), optionally subdivided by bilinear interpolation (`interpolate N,M`, gnuplot's
!< automatic counts for 0 or negative values).
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite, ieee_is_nan, ieee_quiet_nan, ieee_value
use penf, only : I4P, I8P, R8P

implicit none
private
public :: pm3d_object
public :: pm3d_polygons
public :: packed_hex
public :: lit_color
public :: masked
public :: CORNERS_MEAN, CORNERS_GEOMEAN, CORNERS_HARMEAN, CORNERS_RMS, CORNERS_MEDIAN, CORNERS_MIN, CORNERS_MAX, &
          CORNERS_C1

integer(I4P), parameter :: CORNERS_MEAN    = 0_I4P !< `corners2color mean`, gnuplot's default.
integer(I4P), parameter :: CORNERS_GEOMEAN = 1_I4P !< `geomean`.
integer(I4P), parameter :: CORNERS_HARMEAN = 2_I4P !< `harmean`.
integer(I4P), parameter :: CORNERS_RMS     = 3_I4P !< `rms`.
integer(I4P), parameter :: CORNERS_MEDIAN  = 4_I4P !< `median`.
integer(I4P), parameter :: CORNERS_MIN     = 5_I4P !< `min`.
integer(I4P), parameter :: CORNERS_MAX     = 6_I4P !< `max`.
integer(I4P), parameter :: CORNERS_C1      = 7_I4P !< `c1`; `c2`, `c3`, `c4` the next three codes.

type :: pm3d_object
   !< pm3d settings of a panel (gnuplot `set pm3d`).
   logical          :: implicit = .false.   !< Every surface drawn with pm3d too (`set pm3d`, `implicit`), else only
                                            !< the items `with pm3d` (`explicit`, `unset pm3d`).
   character(len=6) :: at = 's'             !< Where: `b` the base, `s` the surface, `t` the top, combined (gnuplot's
                                            !< `at bstbst`: drawn in that order).
   integer(I4P)     :: interp(2) = 1_I4P    !< Steps along and between the scans (`interpolate N,M`; 0 or negative:
                                            !< gnuplot's automatic counts).
   integer(I4P)     :: corners = CORNERS_MEAN !< `corners2color`.
   logical          :: clip4in = .false.    !< `clip4in`: a quadrangle needs its 4 corners in range, else one.
   logical          :: border = .false.     !< `border`: the quadrangles outlined.
   character(len=24) :: border_color = 'black' !< Color of the outlines (`border lc|lt ...`); blank with `retrace`
                                            !< (each in its fill color).
   real(R8P)        :: border_lw = 1.0_R8P  !< Width of the outlines (`border lw W`).
   integer(I4P)     :: direction = 0_I4P    !< Drawing order in 3D views: 0 `scansautomatic`, 1 `scansforward`, 2
                                            !< `scansbackward`, 3 `depthorder`.
   logical          :: base_sort = .false.  !< `depthorder base`: sorted by the depth of the base below each.
   real(R8P)        :: strength = 0.0_R8P   !< `lighting primary F`: the primary light's share, 0 without lighting.
   real(R8P)        :: spec = 0.0_R8P       !< `lighting specular F`: the specular highlights' share.
   real(R8P)        :: spec2 = 0.0_R8P      !< `lighting spec2 F`: the spotlight's share.
   real(R8P)        :: spot_rot(2) = [50.0_R8P, 90.0_R8P] !< `spotlight rot_x A rot_z B` [deg].
   integer(I4P)     :: spot_rgb = 16711748_I4P !< `spotlight rgbcolor C` (gnuplot's 0xff0044).
   real(R8P)        :: spot_phong = 4.0_R8P !< `spotlight Phong P`.
endtype pm3d_object

contains
   pure subroutine pm3d_polygons(x, y, z, c, scans, sets, grid, settings, inrange, px, py, pc, rgb, pz, swap_scans, &
                                 reverse_points)
   !< The quadrangles of a surface: the points (`x`, `y`, `z`, color values `c`) of its first `grid` `scans` (first and
   !< last point of each), neighbouring scans of a dataset (`sets`) joined point by point over the shorter one, as
   !< gnuplot's pm3d_plot; a quadrangle needs its 4 corners defined and one in range (`inrange`; all 4 with `clip4in`).
   !< The result is a polygon per quadrangle: its 4 corners (`px`, `py`, their heights `pz`) and a NaN row, each row in
   !< the quadrangle's color value `pc` (NaN quadrangles left out). With `rgb` the color values are packed colors
   !< 0xAARRGGBB (gnuplot's `lc rgb variable`): a quadrangle takes the mean of its corners channel by channel (or one
   !< corner, `c1` ... `c4`), as gnuplot's pm3d_plot; the interpolated ones the plain mean of the numbers, as gnuplot's.
   !< The order of gnuplot's scan array: with `swap_scans` the scans taken from the last (scan A the later of a pair, the
   !< pairs from the last), with `reverse_points` the points of a pair from the last (gnuplot's pm3d_rearrange_part, the
   !< 3D views); without them, the map's: a surface of fewer than 3 scans has its scans in reverse order (gnuplot's
   !< scansautomatic when no depth tells), as `c1` ... `c4` show.
   real(R8P),              intent(in)  :: x(:)       !< Abscissae.
   real(R8P),              intent(in)  :: y(:)       !< Ordinates.
   real(R8P),              intent(in)  :: z(:)       !< Heights.
   real(R8P),              intent(in)  :: c(:)       !< Color values (the heights, or a column of their own).
   integer(I4P),           intent(in)  :: scans(:,:) !< Scans: first and last point.
   integer(I4P),           intent(in)  :: sets(:)    !< Dataset of each scan.
   integer(I4P),           intent(in)  :: grid       !< Scans of the grid.
   type(pm3d_object),      intent(in)  :: settings   !< pm3d settings.
   logical,                intent(in)  :: inrange(:) !< Points within the x and y ranges.
   real(R8P), allocatable, intent(out) :: px(:)      !< Polygon abscissae.
   real(R8P), allocatable, intent(out) :: py(:)      !< Polygon ordinates.
   real(R8P), allocatable, intent(out) :: pc(:)      !< Polygon color values.
   logical, optional,      intent(in)  :: rgb        !< Packed colors.
   real(R8P), allocatable, intent(out), optional :: pz(:) !< Polygon heights.
   logical, optional,      intent(in)  :: swap_scans !< Scans from the last (scan A the later one).
   logical, optional,      intent(in)  :: reverse_points !< Points from the last.
   real(R8P), allocatable              :: hz(:)      !< Polygon heights.
   integer(I4P)                        :: ni         !< Steps along the scans.
   integer(I4P)                        :: nj         !< Steps between them.
   integer(I4P)                        :: s          !< Scan.
   integer(I4P)                        :: q          !< Pair counter.
   integer(I4P)                        :: j          !< Point step.
   integer(I4P)                        :: jj         !< Point step counter.
   integer(I4P)                        :: n          !< Polygon rows.
   integer(I4P)                        :: n0         !< Rows before a quadrangle.
   integer(I4P)                        :: a0, b0     !< First points of the scans A and B.
   integer(I4P)                        :: upto       !< Quadrangles along the pair.
   integer(I4P)                        :: ia, ia1, ib, ib1 !< Corner points.
   integer(I4P)                        :: i1, j1     !< Interpolation counters.
   integer(I4P)                        :: total      !< Quadrangles at most.
   integer(I4P)                        :: pts        !< Points of a scan in range.
   integer(I4P)                        :: max_pts    !< Most of them.
   integer(I4P)                        :: max_scans  !< Scans with any.
   real(R8P)                           :: cx(4), cy(4), cc(4), cz(4) !< Corners.
   real(R8P), allocatable              :: bx(:,:), by(:,:), bc(:,:), bz(:,:) !< Interpolated points.
   real(R8P)                           :: v          !< Quadrangle color value.
   real(R8P)                           :: nan        !< NaN.
   logical                             :: swap       !< Scan A the later one of the pair.
   logical                             :: back       !< Points from the last.

   nan = ieee_value(1.0_R8P, ieee_quiet_nan)
   ni = settings%interp(1)
   nj = settings%interp(2)
   if (ni <= 0_I4P .or. nj <= 0_I4P) then
      ! gnuplot's automatic steps: about 200 points (or -N) along and across the grid
      max_pts = 0_I4P
      max_scans = 0_I4P
      do s = 1_I4P, grid - 1_I4P
         pts = count(inrange(scans(1, s):scans(2, s)))
         if (pts > 0_I4P) then
            max_pts = max(max_pts, pts)
            max_scans = max_scans + 1_I4P
         endif
      enddo
      if (ni <= 0_I4P) ni = merge(200_I4P, -ni, ni == 0_I4P) / max(1_I4P, max_pts) + 1_I4P
      if (nj <= 0_I4P) nj = merge(200_I4P, -nj, nj == 0_I4P) / max(1_I4P, max_scans) + 1_I4P
   endif
   total = 0_I4P
   do s = 1_I4P, grid - 1_I4P
      if (sets(s) /= sets(s + 1_I4P)) cycle
      total = total + max(0_I4P, min(scans(2, s) - scans(1, s), scans(2, s + 1_I4P) - scans(1, s + 1_I4P)))
   enddo
   allocate(px(5_I4P * total * max(1_I4P, ni) * max(1_I4P, nj)), py(5_I4P * total * max(1_I4P, ni) * max(1_I4P, nj)))
   allocate(pc(size(px)), hz(size(px)))
   allocate(bx(0:ni, 0:nj), by(0:ni, 0:nj), bc(0:ni, 0:nj), bz(0:ni, 0:nj))
   back = .false.
   if (present(reverse_points)) back = reverse_points
   n = 0_I4P
   do q = 1_I4P, grid - 1_I4P
      s = q
      if (present(swap_scans)) then
         if (swap_scans) s = grid - q
      endif
      ! the neighbouring scans of one surface (a dataset)
      if (sets(s) /= sets(s + 1_I4P)) cycle
      if (present(swap_scans)) then
         swap = swap_scans
      else
         ! a surface of fewer than 3 scans: gnuplot's scansautomatic compares no depths and keeps its scans in the
         ! reverse order of the file, scan A the later one (pm3d_rearrange_part)
         swap = count(sets(1:grid) == sets(s)) < 3_I4P
      endif
      a0 = scans(1, s)
      b0 = scans(1, s + 1_I4P)
      upto = min(scans(2, s) - scans(1, s), scans(2, s + 1_I4P) - scans(1, s + 1_I4P))
      do jj = 0_I4P, upto - 1_I4P
         j = jj
         if (back) j = upto - 1_I4P - jj
         ia = a0 + j
         ia1 = ia + 1_I4P
         ib = b0 + j
         ib1 = ib + 1_I4P
         if (swap) then
            ia = b0 + j
            ia1 = ia + 1_I4P
            ib = a0 + j
            ib1 = ib + 1_I4P
         endif
         if (.not. (defined(x, y, z, c, ia) .and. defined(x, y, z, c, ia1) .and. defined(x, y, z, c, ib) .and. &
                    defined(x, y, z, c, ib1))) cycle
         if (settings%clip4in) then
            if (.not. (inrange(ia) .and. inrange(ia1) .and. inrange(ib) .and. inrange(ib1))) cycle
         elseif (.not. (inrange(ia) .or. inrange(ia1) .or. inrange(ib) .or. inrange(ib1))) then
            cycle
         endif
         ! gnuplot's corners: A(i), B(i), B(i+1), A(i+1)
         cx = [x(ia), x(ib), x(ib1), x(ia1)]
         cy = [y(ia), y(ib), y(ib1), y(ia1)]
         cz = [z(ia), z(ib), z(ib1), z(ia1)]
         cc = [c(ia), c(ib), c(ib1), c(ia1)]
         if (ni <= 1_I4P .and. nj <= 1_I4P) then
            ! gnuplot's order for the color: A(i), A(i+1), B(i), B(i+1)
            v = corner_color([c(ia), c(ia1), c(ib), c(ib1)], settings%corners)
            if (present(rgb)) then
               if (rgb) v = corner_rgb([c(ia), c(ia1), c(ib), c(ib1)], settings%corners)
            endif
            n0 = n
            call add(px, py, pc, n, cx, cy, v)
            if (n > n0) then
               hz(n0 + 1:n0 + 4) = cz
               hz(n0 + 5) = nan
            endif
            cycle
         endif
         ! bilinear interpolation: ni points along the scans A and B, nj between them
         do i1 = 0_I4P, ni
            bx(i1, 0) = ((cx(4) - cx(1)) / real(ni, R8P)) * real(i1, R8P) + cx(1)
            bx(i1, nj) = ((cx(3) - cx(2)) / real(ni, R8P)) * real(i1, R8P) + cx(2)
            by(i1, 0) = ((cy(4) - cy(1)) / real(ni, R8P)) * real(i1, R8P) + cy(1)
            by(i1, nj) = ((cy(3) - cy(2)) / real(ni, R8P)) * real(i1, R8P) + cy(2)
            bz(i1, 0) = ((cz(4) - cz(1)) / real(ni, R8P)) * real(i1, R8P) + cz(1)
            bz(i1, nj) = ((cz(3) - cz(2)) / real(ni, R8P)) * real(i1, R8P) + cz(2)
            bc(i1, 0) = ((cc(4) - cc(1)) / real(ni, R8P)) * real(i1, R8P) + cc(1)
            bc(i1, nj) = ((cc(3) - cc(2)) / real(ni, R8P)) * real(i1, R8P) + cc(2)
            do j1 = 1_I4P, nj - 1_I4P
               bx(i1, j1) = ((bx(i1, nj) - bx(i1, 0)) / real(nj, R8P)) * real(j1, R8P) + bx(i1, 0)
               by(i1, j1) = ((by(i1, nj) - by(i1, 0)) / real(nj, R8P)) * real(j1, R8P) + by(i1, 0)
               bz(i1, j1) = ((bz(i1, nj) - bz(i1, 0)) / real(nj, R8P)) * real(j1, R8P) + bz(i1, 0)
               bc(i1, j1) = ((bc(i1, nj) - bc(i1, 0)) / real(nj, R8P)) * real(j1, R8P) + bc(i1, 0)
            enddo
         enddo
         do i1 = 0_I4P, ni - 1_I4P
            do j1 = 0_I4P, nj - 1_I4P
               v = corner_color([bc(i1, j1), bc(i1 + 1, j1), bc(i1 + 1, j1 + 1), bc(i1, j1 + 1)], settings%corners)
               n0 = n
               call add(px, py, pc, n, [bx(i1, j1), bx(i1 + 1, j1), bx(i1 + 1, j1 + 1), bx(i1, j1 + 1)], &
                        [by(i1, j1), by(i1 + 1, j1), by(i1 + 1, j1 + 1), by(i1, j1 + 1)], v)
               if (n > n0) then
                  hz(n0 + 1:n0 + 4) = [bz(i1, j1), bz(i1 + 1, j1), bz(i1 + 1, j1 + 1), bz(i1, j1 + 1)]
                  hz(n0 + 5) = nan
               endif
            enddo
         enddo
      enddo
   enddo
   px = px(1:n)
   py = py(1:n)
   pc = pc(1:n)
   if (present(pz)) pz = hz(1:n)
   endsubroutine pm3d_polygons

   pure function masked(x, y, mx, my) result(yes)
   !< Whether the point (`x`, `y`) is masked: inside none of the mask polygons (`mx`, `my`, NaN separated, closed or
   !< not), gnuplot's masked() over its interior() even-odd test (gadgets.c); no polygon masks nothing.
   real(R8P), intent(in) :: x     !< Abscissa.
   real(R8P), intent(in) :: y     !< Ordinate.
   real(R8P), intent(in) :: mx(:) !< Polygon abscissae.
   real(R8P), intent(in) :: my(:) !< Polygon ordinates.
   logical               :: yes   !< Masked.
   integer(I4P)          :: a     !< First vertex of a polygon.
   integer(I4P)          :: b     !< Last one.
   integer(I4P)          :: i, j  !< Edge ends.
   logical               :: inside !< Odd crossings so far.
   logical               :: any_polygon !< A polygon seen.

   yes = .false.
   any_polygon = .false.
   a = 1_I4P
   do while (a <= size(mx, kind=I4P))
      if (.not. (ieee_is_finite(mx(a)) .and. ieee_is_finite(my(a)))) then
         a = a + 1_I4P
         cycle
      endif
      b = a
      do while (b < size(mx, kind=I4P))
         if (.not. (ieee_is_finite(mx(b + 1_I4P)) .and. ieee_is_finite(my(b + 1_I4P)))) exit
         b = b + 1_I4P
      enddo
      any_polygon = .true.
      inside = .false.
      j = b
      do i = a, b
         if ((my(i) > y) .neqv. (my(j) > y)) then
            if (x < (mx(j) - mx(i)) * (y - my(i)) / (my(j) - my(i)) + mx(i)) inside = .not. inside
         endif
         j = i
      enddo
      if (inside) return
      a = b + 1_I4P
   enddo
   yes = any_polygon
   endfunction masked

   pure function defined(x, y, z, c, k) result(yes)
   !< Whether point `k` is defined: its coordinates and color finite.
   real(R8P),    intent(in) :: x(:) !< Abscissae.
   real(R8P),    intent(in) :: y(:) !< Ordinates.
   real(R8P),    intent(in) :: z(:) !< Heights.
   real(R8P),    intent(in) :: c(:) !< Color values.
   integer(I4P), intent(in) :: k    !< Point.
   logical                  :: yes  !< Defined.

   yes = ieee_is_finite(x(k)) .and. ieee_is_finite(y(k)) .and. ieee_is_finite(z(k)) .and. .not. ieee_is_nan(c(k))
   endfunction defined

   pure subroutine add(px, py, pc, n, qx, qy, value)
   !< Append the quadrangle (`qx`, `qy`) of color `value` and its NaN row at row `n` of the polygons, unless the value
   !< is NaN.
   real(R8P),    intent(inout) :: px(:) !< Polygon abscissae.
   real(R8P),    intent(inout) :: py(:) !< Polygon ordinates.
   real(R8P),    intent(inout) :: pc(:) !< Polygon color values.
   integer(I4P), intent(inout) :: n     !< Rows used.
   real(R8P),    intent(in)    :: qx(:) !< Corner abscissae.
   real(R8P),    intent(in)    :: qy(:) !< Corner ordinates.
   real(R8P),    intent(in)    :: value !< Color value.

   if (ieee_is_nan(value)) return
   px(n + 1:n + 4) = qx
   py(n + 1:n + 4) = qy
   pc(n + 1:n + 4) = value
   px(n + 5) = ieee_value(1.0_R8P, ieee_quiet_nan)
   py(n + 5) = px(n + 5)
   pc(n + 5) = px(n + 5)
   n = n + 5_I4P
   endsubroutine add

   pure function corner_color(cb, mode) result(v)
   !< The color value of a quadrangle from its corners `cb`, gnuplot's (pm3d.c): their mean, geometric mean (0 for mixed
   !< signs), harmonic mean (NaN unless all positive), rms (half the root of the sum of squares), median, minimum,
   !< maximum, or one of them (`c1` ... `c4`, in gnuplot's corner order).
   real(R8P),    intent(in) :: cb(:) !< Corner values.
   integer(I4P), intent(in) :: mode  !< `corners2color`.
   real(R8P)                :: v     !< Value.
   integer(I4P)             :: neg   !< Negative corners.
   real(R8P)                :: a(4)  !< Sorted pairs.

   select case (mode)
   case (CORNERS_GEOMEAN)
      neg = count(cb < 0.0_R8P)
      v = cb(1) * cb(2) * cb(3) * cb(4)
      if (v == 0.0_R8P .or. (neg >= 1_I4P .and. neg <= 3_I4P)) then
         v = 0.0_R8P
      else
         v = sqrt(sqrt(abs(v)))
         if (neg == 4_I4P) v = -v
      endif
   case (CORNERS_HARMEAN)
      if (any(cb <= 0.0_R8P)) then
         v = ieee_value(1.0_R8P, ieee_quiet_nan)
      else
         v = 4.0_R8P / (1.0_R8P / cb(1) + 1.0_R8P / cb(2) + 1.0_R8P / cb(3) + 1.0_R8P / cb(4))
      endif
   case (CORNERS_RMS)
      v = 0.5_R8P * sqrt(cb(1) * cb(1) + cb(2) * cb(2) + cb(3) * cb(3) + cb(4) * cb(4))
   case (CORNERS_MEDIAN)
      a = [min(cb(1), cb(2)), max(cb(1), cb(2)), min(cb(3), cb(4)), max(cb(3), cb(4))]
      v = (max(a(1), a(3)) + min(a(2), a(4))) * 0.5_R8P
   case (CORNERS_MIN)
      v = min(min(cb(1), cb(2)), min(cb(3), cb(4)))
   case (CORNERS_MAX)
      v = max(max(cb(1), cb(2)), max(cb(3), cb(4)))
   case (CORNERS_C1:CORNERS_C1 + 3_I4P)
      v = cb(mode - CORNERS_C1 + 1_I4P)
   case default
      v = (cb(1) + cb(2) + cb(3) + cb(4)) * 0.25_R8P
   endselect
   endfunction corner_color

   pure function corner_rgb(cb, mode) result(v)
   !< The packed color 0xAARRGGBB of a quadrangle from its corners' `cb`, gnuplot's (pm3d.c, `lc rgb variable`): one of
   !< them (`c1` ... `c4`), else the mean of each channel, the sums shifted right by two and masked (the transparency
   !< as gnuplot's: its sum shifted left by 22).
   real(R8P),    intent(in) :: cb(:) !< Corner colors.
   integer(I4P), intent(in) :: mode  !< `corners2color`.
   real(R8P)                :: v     !< Color.
   integer(I8P)             :: u(4)  !< Corners as unsigned 32-bit numbers.
   integer(I8P)             :: r, g, b, a !< Channel sums.
   integer(I8P)             :: k     !< Corner counter.

   if (mode >= CORNERS_C1 .and. mode <= CORNERS_C1 + 3_I4P) then
      v = cb(mode - CORNERS_C1 + 1_I4P)
      return
   endif
   do k = 1_I8P, 4_I8P
      u(k) = iand(int(cb(k), I8P), int(z'FFFFFFFF', I8P))
   enddo
   r = sum(iand(u, int(z'FF0000', I8P)))
   g = sum(iand(u, int(z'FF00', I8P)))
   b = sum(iand(u, int(z'FF', I8P)))
   a = sum(iand(ishft(u, -24), 255_I8P))
   v = real(iand(ishft(r, -2), int(z'FF0000', I8P)) + iand(ishft(g, -2), int(z'FF00', I8P)) + &
            iand(ishft(b, -2), int(z'FF', I8P)) + iand(ishft(a, 22), int(z'FF000000', I8P)), R8P)
   endfunction corner_rgb

   pure function packed_hex(v) result(color)
   !< The SVG color of a packed color 0xAARRGGBB (gnuplot's `rgb variable`), its number truncated to 32 bits:
   !< `#rrggbb`, with the opacity `aa` = 255 - AA appended unless opaque (`#rrggbbaa`); blank for a NaN.
   real(R8P), intent(in)       :: v     !< Packed color.
   character(len=9)            :: color !< SVG color.
   character(len=*), parameter :: HEX = '0123456789abcdef' !< Hexadecimal digits.
   integer(I8P)                :: code  !< Packed color as a number.
   integer(I8P)                :: alpha !< Opacity.
   integer(I4P)                :: d     !< Digit counter.
   integer(I4P)                :: digit !< Hexadecimal digit.

   color = ''
   if (.not. ieee_is_finite(v)) return
   code = iand(int(v, I8P), int(z'FFFFFFFF', I8P))
   color(1:1) = '#'
   do d = 5_I4P, 0_I4P, -1_I4P
      digit = int(iand(ishft(code, -4_I4P * d), 15_I8P), I4P)
      color(7 - d:7 - d) = HEX(digit + 1:digit + 1)
   enddo
   alpha = 255_I8P - iand(ishft(code, -24_I4P), 255_I8P)
   if (alpha < 255_I8P) color(8:9) = HEX(alpha / 16_I8P + 1_I8P:alpha / 16_I8P + 1_I8P)// &
                                     HEX(mod(alpha, 16_I8P) + 1_I8P:mod(alpha, 16_I8P) + 1_I8P)
   endfunction packed_hex

   pure recursive function lit_color(f, alpha, v0, v1, v2, v3, pm, scale3d, rot_x, rot_z) result(packed)
   !< The packed color 0xAARRGGBB of a pm3d quadrangle of color `f` (red, green, blue from 0 to 1, transparency
   !< `alpha` in the top byte) lit by gnuplot's apply_lighting_model (`set pm3d lighting`): the normal of its corners
   !< `v0`, `v1`, `v2` (linear spaces, scaled by the view's `scale3d`) turned to the viewer (`rot_x`, `rot_z` [deg]),
   !< towards the viewer; the ambient light 1, the primary light (from 45, 85 degrees) of share `strength`, its Phong
   !< highlights (exponent 5) of share `spec`, the spotlight (`spec2`, from `spot_rot`, in `spot_rgb`, exponent
   !< `spot_phong`) on the faces turned away; a degenerate corner `v2` replaced by `v3` once.
   real(R8P),         intent(in) :: f(3)       !< Red, green, blue, 0 to 1.
   integer(I8P),      intent(in) :: alpha      !< Transparency, in the top byte.
   real(R8P),         intent(in) :: v0(3)      !< Corner A(i).
   real(R8P),         intent(in) :: v1(3)      !< Corner A(i+1).
   real(R8P),         intent(in) :: v2(3)      !< Corner B(i).
   real(R8P),         intent(in) :: v3(3)      !< Corner B(i+1).
   type(pm3d_object), intent(in) :: pm         !< pm3d settings.
   real(R8P),         intent(in) :: scale3d(3) !< The view's x, y, z scales.
   real(R8P),         intent(in) :: rot_x      !< View rotation about x [deg].
   real(R8P),         intent(in) :: rot_z      !< View rotation about z [deg].
   integer(I8P)                  :: packed     !< Lit color.
   real(R8P), parameter          :: D2R = 3.14159265358979323846_R8P / 180.0_R8P !< Degrees to radians.
   real(R8P)                     :: n(3), n1(3), light(3), light2(3), refl(3) !< Normal, lights, reflection.
   real(R8P)                     :: t, psi, phi, dot, shade, spec, tmp(3) !< Work.

   n(1) = (v1(2) - v0(2)) * (v2(3) - v0(3)) * scale3d(2) * scale3d(3) - &
          (v1(3) - v0(3)) * (v2(2) - v0(2)) * scale3d(2) * scale3d(3)
   n(2) = (v1(3) - v0(3)) * (v2(1) - v0(1)) * scale3d(1) * scale3d(3) - &
          (v1(1) - v0(1)) * (v2(3) - v0(3)) * scale3d(1) * scale3d(3)
   n(3) = (v1(1) - v0(1)) * (v2(2) - v0(2)) * scale3d(1) * scale3d(2) - &
          (v1(2) - v0(2)) * (v2(1) - v0(1)) * scale3d(1) * scale3d(2)
   t = sqrt(n(1) * n(1) + n(2) * n(2) + n(3) * n(3))
   if (t < 1.0e-12_R8P) then
      if (all(v2 == v3)) then
         packed = alpha + int(f(1) * 255.0_R8P, I8P) * 65536_I8P + int(f(2) * 255.0_R8P, I8P) * 256_I8P + &
                  int(f(3) * 255.0_R8P, I8P)
      else
         packed = lit_color(f, alpha, v0, v1, v3, v3, pm, scale3d, rot_x, rot_z)
      endif
      return
   endif
   n = n / t
   ! the light fixed with respect to the viewer
   psi = -D2R * rot_z
   phi = -D2R * rot_x
   n1 = [cos(psi) * n(1) - sin(psi) * n(2), sin(psi) * n(1) + cos(psi) * n(2), n(3)]
   n = [n1(1), cos(phi) * n1(2) - sin(phi) * n1(3), sin(phi) * n1(2) + cos(phi) * n1(3)]
   if (n(3) < 0.0_R8P) n = -n
   light = [cos(-D2R * 45.0_R8P) * cos(-D2R * 85.0_R8P), sin(-D2R * 45.0_R8P), &
            cos(-D2R * 45.0_R8P) * sin(-D2R * 85.0_R8P)]
   dot = n(1) * light(1) + n(2) * light(2) + n(3) * light(3)
   shade = 0.0_R8P
   if (dot < 0.0_R8P) shade = -dot
   tmp = f * (1.0_R8P - pm%strength + shade * pm%strength)
   if (pm%spec > 0.0_R8P) then
      refl = -light + 2.0_R8P * dot * n
      refl = refl / sqrt(refl(1) * refl(1) + refl(2) * refl(2) + refl(3) * refl(3))
      dot = -refl(3)
      spec = abs(dot)**5.0_R8P
      if (dot > 0.0_R8P) tmp = tmp + pm%spec * spec
   endif
   if (pm%spec2 > 0.0_R8P) then
      light2 = [cos(-D2R * pm%spot_rot(1)) * cos(-D2R * pm%spot_rot(2)), sin(-D2R * pm%spot_rot(1)), &
                cos(-D2R * pm%spot_rot(1)) * sin(-D2R * pm%spot_rot(2))]
      dot = n(1) * light2(1) + n(2) * light2(2) + n(3) * light2(3)
      refl = -light2 + 2.0_R8P * dot * n
      refl = refl / sqrt(refl(1) * refl(1) + refl(2) * refl(2) + refl(3) * refl(3))
      dot = -refl(3)
      spec = abs(dot)**pm%spot_phong
      if (dot < 0.0_R8P) tmp = tmp + pm%spec2 * spec * &
                                     real([ishft(pm%spot_rgb, -16), iand(ishft(pm%spot_rgb, -8), 255_I4P), &
                                           iand(pm%spot_rgb, 255_I4P)], R8P) / 255.0_R8P
   endif
   tmp = min(1.0_R8P, max(0.0_R8P, tmp))
   packed = alpha + int(tmp(1) * 255.0_R8P, I8P) * 65536_I8P + int(tmp(2) * 255.0_R8P, I8P) * 256_I8P + &
            int(tmp(3) * 255.0_R8P, I8P)
   endfunction lit_color
endmodule foresight_pm3d
