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
   character(len=3) :: at = 's'             !< Where: `b` the base, `s` the surface, `t` the top, combined.
   integer(I4P)     :: interp(2) = 1_I4P    !< Steps along and between the scans (`interpolate N,M`; 0 or negative:
                                            !< gnuplot's automatic counts).
   integer(I4P)     :: corners = CORNERS_MEAN !< `corners2color`.
   logical          :: clip4in = .false.    !< `clip4in`: a quadrangle needs its 4 corners in range, else one.
   logical          :: border = .false.     !< `border`: the quadrangles outlined.
   character(len=24) :: border_color = 'black' !< Color of the outlines (`border lc|lt ...`); blank with `retrace`
                                            !< (each in its fill color).
   real(R8P)        :: border_lw = 1.0_R8P  !< Width of the outlines (`border lw W`).
endtype pm3d_object

contains
   pure subroutine pm3d_polygons(x, y, z, c, scans, sets, grid, settings, inrange, px, py, pc, rgb)
   !< The quadrangles of a surface: the points (`x`, `y`, `z`, color values `c`) of its first `grid` `scans` (first and
   !< last point of each), neighbouring scans of a dataset (`sets`) joined point by point over the shorter one, as
   !< gnuplot's pm3d_plot; a quadrangle needs its 4 corners defined and one in range (`inrange`; all 4 with `clip4in`).
   !< The result is a polygon per quadrangle: its 4 corners (`px`, `py`) and a NaN row, each row in the quadrangle's
   !< color value `pc` (NaN quadrangles left out). With `rgb` the color values are packed colors 0xAARRGGBB (gnuplot's
   !< `lc rgb variable`): a quadrangle takes the mean of its corners channel by channel (or one corner, `c1` ... `c4`),
   !< as gnuplot's pm3d_plot; the interpolated ones the plain mean of the numbers, as gnuplot's. A surface of fewer
   !< than 3 scans has its scans in reverse order (gnuplot's scansautomatic), as `c1` ... `c4` show.
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
   integer(I4P)                        :: ni         !< Steps along the scans.
   integer(I4P)                        :: nj         !< Steps between them.
   integer(I4P)                        :: s          !< Scan.
   integer(I4P)                        :: j          !< Point step.
   integer(I4P)                        :: n          !< Polygon rows.
   integer(I4P)                        :: a0, b0     !< First points of the scans A and B.
   integer(I4P)                        :: upto       !< Quadrangles along the pair.
   integer(I4P)                        :: ia, ia1, ib, ib1 !< Corner points.
   integer(I4P)                        :: i1, j1     !< Interpolation counters.
   integer(I4P)                        :: total      !< Quadrangles at most.
   integer(I4P)                        :: pts        !< Points of a scan in range.
   integer(I4P)                        :: max_pts    !< Most of them.
   integer(I4P)                        :: max_scans  !< Scans with any.
   real(R8P)                           :: cx(4), cy(4), cc(4) !< Corners.
   real(R8P), allocatable              :: bx(:,:), by(:,:), bc(:,:) !< Interpolated points.
   real(R8P)                           :: v          !< Quadrangle color value.
   real(R8P)                           :: nan        !< NaN.

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
   allocate(pc(size(px)))
   allocate(bx(0:ni, 0:nj), by(0:ni, 0:nj), bc(0:ni, 0:nj))
   n = 0_I4P
   do s = 1_I4P, grid - 1_I4P
      ! the neighbouring scans of one surface (a dataset)
      if (sets(s) /= sets(s + 1_I4P)) cycle
      a0 = scans(1, s)
      b0 = scans(1, s + 1_I4P)
      upto = min(scans(2, s) - scans(1, s), scans(2, s + 1_I4P) - scans(1, s + 1_I4P))
      do j = 0_I4P, upto - 1_I4P
         ia = a0 + j
         ia1 = ia + 1_I4P
         ib = b0 + j
         ib1 = ib + 1_I4P
         if (count(sets(1:grid) == sets(s)) < 3_I4P) then
            ! a surface of fewer than 3 scans: gnuplot's scansautomatic compares no depths and keeps its scans in the
            ! reverse order of the file, scan A the later one (pm3d_rearrange_part)
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
         cc = [c(ia), c(ib), c(ib1), c(ia1)]
         if (ni <= 1_I4P .and. nj <= 1_I4P) then
            ! gnuplot's order for the color: A(i), A(i+1), B(i), B(i+1)
            v = corner_color([c(ia), c(ia1), c(ib), c(ib1)], settings%corners)
            if (present(rgb)) then
               if (rgb) v = corner_rgb([c(ia), c(ia1), c(ib), c(ib1)], settings%corners)
            endif
            call add(px, py, pc, n, cx, cy, v)
            cycle
         endif
         ! bilinear interpolation: ni points along the scans A and B, nj between them
         do i1 = 0_I4P, ni
            bx(i1, 0) = ((cx(4) - cx(1)) / real(ni, R8P)) * real(i1, R8P) + cx(1)
            bx(i1, nj) = ((cx(3) - cx(2)) / real(ni, R8P)) * real(i1, R8P) + cx(2)
            by(i1, 0) = ((cy(4) - cy(1)) / real(ni, R8P)) * real(i1, R8P) + cy(1)
            by(i1, nj) = ((cy(3) - cy(2)) / real(ni, R8P)) * real(i1, R8P) + cy(2)
            bc(i1, 0) = ((cc(4) - cc(1)) / real(ni, R8P)) * real(i1, R8P) + cc(1)
            bc(i1, nj) = ((cc(3) - cc(2)) / real(ni, R8P)) * real(i1, R8P) + cc(2)
            do j1 = 1_I4P, nj - 1_I4P
               bx(i1, j1) = ((bx(i1, nj) - bx(i1, 0)) / real(nj, R8P)) * real(j1, R8P) + bx(i1, 0)
               by(i1, j1) = ((by(i1, nj) - by(i1, 0)) / real(nj, R8P)) * real(j1, R8P) + by(i1, 0)
               bc(i1, j1) = ((bc(i1, nj) - bc(i1, 0)) / real(nj, R8P)) * real(j1, R8P) + bc(i1, 0)
            enddo
         enddo
         do i1 = 0_I4P, ni - 1_I4P
            do j1 = 0_I4P, nj - 1_I4P
               v = corner_color([bc(i1, j1), bc(i1 + 1, j1), bc(i1 + 1, j1 + 1), bc(i1, j1 + 1)], settings%corners)
               call add(px, py, pc, n, [bx(i1, j1), bx(i1 + 1, j1), bx(i1 + 1, j1 + 1), bx(i1, j1 + 1)], &
                        [by(i1, j1), by(i1 + 1, j1), by(i1 + 1, j1 + 1), by(i1, j1 + 1)], v)
            enddo
         enddo
      enddo
   enddo
   px = px(1:n)
   py = py(1:n)
   pc = pc(1:n)
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
   real(R8P),    intent(in)    :: qx(4) !< Corner abscissae.
   real(R8P),    intent(in)    :: qy(4) !< Corner ordinates.
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
   real(R8P),    intent(in) :: cb(4) !< Corner values.
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
   real(R8P),    intent(in) :: cb(4) !< Corner colors.
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
endmodule foresight_pm3d
