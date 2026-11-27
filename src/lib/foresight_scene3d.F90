!< foresight_scene3d, the scene of a 3D view for the HTML viewer's mouse rotation.
module foresight_scene3d
!< foresight_scene3d, the scene of a 3D view for the HTML viewer's mouse rotation.
!<
!< A 3D panel of an HTML page carries its scene: the lines, filled polygons, points and texts of the view in the box's
!< normalized coordinates (-1..1 over the box, gnuplot's map3d_xyz before its transform), with the view's rotation,
!< scale and frame. The viewer re-projects them with the same transform when the mouse turns the view (a painter's
!< algorithm, farthest first); the page itself is foresight's static drawing of the script's view. Coordinates are
!< written with 4 decimals (a tenth of a pixel on a 1000 px plot), as JSON:
!< `{"v":[rot_x,rot_z,scale,azimuth],"f":[xmiddle,ymiddle,xscaler,yscaler,height],"keep":"title",
!< "l":[[color,width,dash,[x,y,z,...]],...],"q":[[fill,stroke,[x,y,z,...]],...],"p":[[color,radius,[x,y,z,...]],...],
!< "t":[[text,x,y,z,anchor,color],...]}`.
use foresight_view3d, only : view3d_frame, view3d_lin
use penf, only : I1P, I4P, I8P, R8P

implicit none
private
public :: scene3d_object

type :: scene3d_object
   !< The scene of a 3D view: its parts as JSON arrays, being written, as bytes (nvfortran 26.9 corrupts the heap
   !< growing a deferred-length character component by move_alloc).
   integer(I1P), allocatable :: lines(:)   !< Polylines.
   integer(I4P)              :: nl = 0_I4P !< Bytes of `lines` used.
   integer(I1P), allocatable :: quads(:)   !< Filled polygons.
   integer(I4P)              :: nq = 0_I4P !< Bytes of `quads` used.
   integer(I1P), allocatable :: points(:)  !< Points.
   integer(I4P)              :: np = 0_I4P !< Bytes of `points` used.
   integer(I1P), allocatable :: texts(:)   !< Texts.
   integer(I4P)              :: nt = 0_I4P !< Bytes of `texts` used.
   contains
      procedure, pass(self) :: add_line  !< A polyline (axis values; breaks at undefined points).
      procedure, pass(self) :: add_poly  !< A filled polygon (axis values).
      procedure, pass(self) :: add_point !< A point.
      procedure, pass(self) :: add_text  !< A text at a point.
      procedure, pass(self) :: json      !< The scene as JSON.
endtype scene3d_object

contains
   pure function cube(f, x, y, z) result(p)
   !< The box coordinates (-1..1 over the box) of the point (`x`, `y`, `z`) in axis values (view3d_xyz before the
   !< transform).
   type(view3d_frame), intent(in) :: f    !< The view.
   real(R8P),          intent(in) :: x    !< Abscissa.
   real(R8P),          intent(in) :: y    !< Ordinate.
   real(R8P),          intent(in) :: z    !< Height.
   real(R8P)                      :: p(3) !< Box coordinates.

   p(1) = (view3d_lin(x, f%log(1)) - f%x(1)) * f%scale3d(1) + f%center3d(1) - 1.0_R8P
   p(2) = (view3d_lin(y, f%log(2)) - f%y(1)) * f%scale3d(2) + f%center3d(2) - 1.0_R8P
   p(3) = (view3d_lin(z, f%log(3)) - f%floor_z) * f%scale3d(3) + f%center3d(3) - 1.0_R8P
   endfunction cube

   pure function num(v) result(s)
   !< `v` with 4 decimals, no trailing zeros (JSON).
   real(R8P), intent(in)         :: v !< Value.
   character(len=:), allocatable :: s !< Text.
   character(len=32)             :: b !< Buffer.

   write(b, '(F0.4)') v
   s = trim(adjustl(b))
   if (index(s, '.') > 0) then
      do while (s(len(s):len(s)) == '0')
         s = s(1:len(s) - 1)
      enddo
      if (s(len(s):len(s)) == '.') s = s(1:len(s) - 1)
   endif
   if (len(s) == 0) s = '0'
   if (s(1:1) == '.') s = '0'//s
   if (len(s) > 1) then
      if (s(1:2) == '-.') s = '-0'//s(2:)
   endif
   if (s == '-0') s = '0'
   endfunction num

   pure function str(text) result(s)
   !< `text` as a JSON string, `&`, `<` and `>` as their \u escapes: the scene goes into the page's XML as it is.
   character(len=*), intent(in)  :: text !< Text.
   character(len=:), allocatable :: s    !< JSON string.
   integer(I4P)                  :: k    !< Character counter.

   s = '"'
   do k = 1_I4P, len(text, kind=I4P)
      select case (text(k:k))
      case ('"', '\')
         s = s//'\'//text(k:k)
      case ('&')
         s = s//'\u0026'
      case ('<')
         s = s//'\u003c'
      case ('>')
         s = s//'\u003e'
      case default
         if (iachar(text(k:k)) < 32) then
            s = s//' '
         else
            s = s//text(k:k)
         endif
      endselect
   enddo
   s = s//'"'
   endfunction str

   pure subroutine put(buffer, used, piece)
   !< `piece` appended to the bytes `buffer(1:used)`, a comma before it unless first, doubling the buffer as needed.
   integer(I1P), allocatable, intent(inout) :: buffer(:) !< Bytes.
   integer(I4P),              intent(inout) :: used      !< Bytes used.
   character(len=*),          intent(in)    :: piece     !< Piece.
   integer(I1P), allocatable                :: bigger(:) !< Grown buffer.
   integer(I4P)                             :: k         !< Character counter.

   if (.not. allocated(buffer)) then
      allocate(buffer(max(4096, 2 * len(piece) + 2)))
      used = 0_I4P
   endif
   if (used + len(piece, kind=I4P) + 1_I4P > size(buffer, kind=I4P)) then
      allocate(bigger(2 * (size(buffer) + len(piece) + 1)))
      bigger(1:used) = buffer(1:used)
      call move_alloc(bigger, buffer)
   endif
   if (used > 0_I4P) then
      buffer(used + 1_I4P) = transfer(',', 0_I1P)
      used = used + 1_I4P
   endif
   do k = 1_I4P, len(piece, kind=I4P)
      buffer(used + k) = transfer(piece(k:k), 0_I1P)
   enddo
   used = used + len(piece, kind=I4P)
   endsubroutine put

   pure function coords(f, x, y, z) result(s)
   !< The box coordinates of the points (`x`, `y`, `z`), as a JSON array of x, y, z triples.
   type(view3d_frame), intent(in) :: f    !< The view.
   real(R8P),          intent(in) :: x(:) !< Abscissae.
   real(R8P),          intent(in) :: y(:) !< Ordinates.
   real(R8P),          intent(in) :: z(:) !< Heights.
   character(len=:), allocatable  :: s    !< JSON array.
   integer(I1P), allocatable      :: b(:) !< Buffer.
   integer(I4P)                   :: used !< Its bytes used.
   real(R8P)                      :: p(3) !< Box coordinates.
   integer(I4P)                   :: k    !< Point counter.

   used = 0_I4P
   do k = 1_I4P, size(x, kind=I4P)
      p = cube(f, x(k), y(k), z(k))
      call put(b, used, num(p(1))//','//num(p(2))//','//num(p(3)))
   enddo
   s = '['//part(b, used)//']'
   endfunction coords

   pure subroutine add_line(self, f, x, y, z, color, width, dash)
   !< A polyline through the points (`x`, `y`, `z`) (axis values), broken at the undefined ones and out of the box.
   class(scene3d_object), intent(inout) :: self  !< Scene.
   type(view3d_frame),    intent(in)    :: f     !< The view.
   real(R8P),             intent(in)    :: x(:)  !< Abscissae.
   real(R8P),             intent(in)    :: y(:)  !< Ordinates.
   real(R8P),             intent(in)    :: z(:)  !< Heights.
   character(len=*),      intent(in)    :: color !< Color.
   real(R8P),             intent(in)    :: width !< Width [px].
   character(len=*),      intent(in)    :: dash  !< SVG dash array, empty for solid.
   integer(I4P)                         :: a     !< First point of a run.
   integer(I4P)                         :: b     !< Last point of a run.
   integer(I4P)                         :: n     !< Points.

   n = size(x, kind=I4P)
   a = 1_I4P
   do while (a <= n)
      if (.not. inside(f, x(a), y(a), z(a))) then
         a = a + 1_I4P
         cycle
      endif
      b = a
      do while (b < n)
         if (.not. inside(f, x(b + 1_I4P), y(b + 1_I4P), z(b + 1_I4P))) exit
         b = b + 1_I4P
      enddo
      if (b > a) call put(self%lines, self%nl, '['//str(color)//','//num(width)//','//str(dash)//','// &
                                               coords(f, x(a:b), y(a:b), z(a:b))//']')
      a = b + 1_I4P
   enddo
   endsubroutine add_line

   pure subroutine add_poly(self, f, x, y, z, fill, stroke)
   !< A filled polygon of corners (`x`, `y`, `z`) (axis values), dropped if a corner is undefined.
   class(scene3d_object), intent(inout) :: self   !< Scene.
   type(view3d_frame),    intent(in)    :: f      !< The view.
   real(R8P),             intent(in)    :: x(:)   !< Abscissae.
   real(R8P),             intent(in)    :: y(:)   !< Ordinates.
   real(R8P),             intent(in)    :: z(:)   !< Heights.
   character(len=*),      intent(in)    :: fill   !< Fill color.
   character(len=*),      intent(in)    :: stroke !< Border color, empty for none.
   integer(I4P)                         :: k      !< Corner counter.

   do k = 1_I4P, size(x, kind=I4P)
      if (.not. finite3(x(k), y(k), z(k))) return
   enddo
   call put(self%quads, self%nq, '['//str(fill)//','//str(stroke)//','//coords(f, x, y, z)//']')
   endsubroutine add_poly

   pure subroutine add_point(self, f, x, y, z, color, radius)
   !< A round point at (`x`, `y`, `z`) (axis values), if in the box.
   class(scene3d_object), intent(inout) :: self   !< Scene.
   type(view3d_frame),    intent(in)    :: f      !< The view.
   real(R8P),             intent(in)    :: x      !< Abscissa.
   real(R8P),             intent(in)    :: y      !< Ordinate.
   real(R8P),             intent(in)    :: z      !< Height.
   character(len=*),      intent(in)    :: color  !< Color.
   real(R8P),             intent(in)    :: radius !< Radius [px].

   if (.not. inside(f, x, y, z)) return
   call put(self%points, self%np, '['//str(color)//','//num(radius)//','//coords(f, [x], [y], [z])//']')
   endsubroutine add_point

   pure subroutine add_text(self, f, text, x, y, z, anchor, color)
   !< The `text` anchored (`start`, `middle`, `end`) at (`x`, `y`, `z`) (axis values; `z` in the z axis's linear space
   !< as the box heights are).
   class(scene3d_object), intent(inout) :: self   !< Scene.
   type(view3d_frame),    intent(in)    :: f      !< The view.
   character(len=*),      intent(in)    :: text   !< Text.
   real(R8P),             intent(in)    :: x      !< Abscissa.
   real(R8P),             intent(in)    :: y      !< Ordinate.
   real(R8P),             intent(in)    :: z      !< Height.
   character(len=*),      intent(in)    :: anchor !< Anchor.
   character(len=*),      intent(in)    :: color  !< Color, empty for the default.
   real(R8P)                            :: p(3)   !< Box coordinates.

   if (.not. finite3(x, y, z)) return
   p = cube(f, x, y, z)
   call put(self%texts, self%nt, '['//str(text)//','//num(p(1))//','//num(p(2))//','//num(p(3))//','//str(anchor)// &
                                 ','//str(color)//']')
   endsubroutine add_text

   pure function json(self, f, rot_x, rot_z, scale, azimuth, keep) result(s)
   !< The scene as JSON, with the view (`rot_x`, `rot_z`, the scale gnuplot's surface_scale, `azimuth`), its frame and
   !< the text of the panel's static drawing kept while turning (its title).
   class(scene3d_object), intent(in) :: self    !< Scene.
   type(view3d_frame),    intent(in) :: f       !< The view.
   real(R8P),             intent(in) :: rot_x   !< Rotation about x [deg].
   real(R8P),             intent(in) :: rot_z   !< Rotation about z [deg].
   real(R8P),             intent(in) :: scale   !< View scale.
   real(R8P),             intent(in) :: azimuth !< Azimuth [deg].
   character(len=*),      intent(in) :: keep    !< Text kept (the title), empty for none.
   character(len=:), allocatable     :: s       !< JSON.

   s = '{"v":['//num(rot_x)//','//num(rot_z)//','//num(scale)//','//num(azimuth)//'],"f":['//num(f%xmiddle)//','// &
       num(f%ymiddle)//','//num(f%xscaler)//','//num(f%yscaler)//','//num(f%height)//'],"keep":'//str(keep)// &
       ',"l":['//part(self%lines, self%nl)//'],"q":['//part(self%quads, self%nq)//'],"p":['// &
       part(self%points, self%np)//'],"t":['//part(self%texts, self%nt)//']}'
   endfunction json

   pure function part(buffer, used) result(t)
   !< The used bytes of a scene part as text, empty if none.
   integer(I1P), allocatable, intent(in) :: buffer(:) !< Part.
   integer(I4P),              intent(in) :: used      !< Bytes used.
   character(len=:), allocatable         :: t         !< Text.
   integer(I4P)                          :: k         !< Byte counter.

   if (.not. allocated(buffer)) then
      t = ''
      return
   endif
   if (used <= 0_I4P) then
      t = ''
      return
   endif
   allocate(character(len=used) :: t)
   do k = 1_I4P, used
      t(k:k) = transfer(buffer(k), 'a')
   enddo
   endfunction part

   pure function finite3(x, y, z) result(yes)
   !< Whether the three values are finite (not NaN nor infinite).
   real(R8P), intent(in) :: x, y, z !< Values.
   logical               :: yes     !< All finite.

   yes = abs(x) <= huge(x) .and. abs(y) <= huge(y) .and. abs(z) <= huge(z)
   endfunction finite3

   pure function inside(f, x, y, z) result(yes)
   !< Whether the point (`x`, `y`, `z`) is defined and within the box (in the linear spaces of the axes, a tolerance).
   type(view3d_frame), intent(in) :: f    !< The view.
   real(R8P),          intent(in) :: x    !< Abscissa.
   real(R8P),          intent(in) :: y    !< Ordinate.
   real(R8P),          intent(in) :: z    !< Height.
   logical                        :: yes  !< Inside.
   real(R8P)                      :: l(3) !< Linear values.

   yes = finite3(x, y, z)
   if (.not. yes) return
   if (f%log(1) .and. x <= 0.0_R8P) yes = .false.
   if (f%log(2) .and. y <= 0.0_R8P) yes = .false.
   if (f%log(3) .and. z <= 0.0_R8P) yes = .false.
   if (.not. yes) return
   l = [view3d_lin(x, f%log(1)), view3d_lin(y, f%log(2)), view3d_lin(z, f%log(3))]
   yes = within(l(1), f%x) .and. within(l(2), f%y) .and. within(l(3), [f%floor_z, f%ceiling_z])
   endfunction inside

   pure function within(v, ends) result(yes)
   !< Whether `v` lies between the `ends` (either order, a relative tolerance of 1e-9 of their span).
   real(R8P), intent(in) :: v       !< Value.
   real(R8P), intent(in) :: ends(2) !< Ends.
   logical               :: yes     !< Within.
   real(R8P)             :: tol     !< Tolerance.

   tol = 1.0e-9_R8P * abs(ends(2) - ends(1))
   yes = v >= minval(ends) - tol .and. v <= maxval(ends) + tol
   endfunction within
endmodule foresight_scene3d
