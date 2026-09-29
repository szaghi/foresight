!< foresight_style, series drawing style (gnuplot `with`, `lc`, `lw`, `dt`, `ps`).
module foresight_style
!< foresight_style, series drawing style (gnuplot `with`, `lc`, `lw`, `dt`, `ps`).
use penf, only : I4P, R8P
use foresight_format, only : fixed

implicit none
private
public :: default_color
public :: style_object
public :: style_with
public :: WITH_LINES, WITH_LINESPOINTS, WITH_POINTS

integer(I4P), parameter :: WITH_LINES       = 1_I4P !< gnuplot `with lines`.
integer(I4P), parameter :: WITH_POINTS      = 2_I4P !< gnuplot `with points`.
integer(I4P), parameter :: WITH_LINESPOINTS = 3_I4P !< gnuplot `with linespoints`.

character(len=7), parameter :: PALETTE(8) = ['#9400d3', '#009e73', '#56b4e9', '#e69f00', &
                                             '#f0e442', '#0072b2', '#e51e10', '#000000'] !< gnuplot 5 line colors.
real(R8P),        parameter :: DIAMETER_AT_UNIT_SIZE = 6.0_R8P !< Point diameter at `pointsize` 1 [px].

type :: style_object
   !< Series drawing style.
   integer(I4P)                  :: with      = WITH_LINES !< Plotting style.
   character(len=:), allocatable :: color                  !< Line and point color (SVG color).
   real(R8P)                     :: linewidth = 1.0_R8P    !< Line width [px].
   integer(I4P)                  :: dashtype  = 1_I4P      !< gnuplot dash type: 1 solid, 2..5 dash patterns.
   real(R8P)                     :: pointsize = 1.0_R8P    !< Point size scale factor.
   contains
      procedure, pass(self) :: dasharray      !< SVG dash array.
      procedure, pass(self) :: draws_lines    !< Whether lines are drawn.
      procedure, pass(self) :: draws_points   !< Whether points are drawn.
      procedure, pass(self) :: point_diameter !< Point diameter [px].
endtype style_object

contains
   pure function default_color(index) result(color)
   !< Default color of the `index`-th series, cycling the gnuplot 5 palette.
   integer(I4P), intent(in)      :: index !< Series index, from 1.
   character(len=:), allocatable :: color !< SVG color.

   color = PALETTE(modulo(index - 1_I4P, size(PALETTE, kind=I4P)) + 1_I4P)
   endfunction default_color

   function style_with(name) result(with)
   !< Plotting style code of a gnuplot `with` keyword, full or abbreviated (`l`, `p`, `lp`).
   character(len=*), intent(in) :: name !< gnuplot style keyword.
   integer(I4P)                 :: with !< Plotting style code.

   select case (trim(adjustl(name)))
   case ('l', 'lines')
      with = WITH_LINES
   case ('p', 'points')
      with = WITH_POINTS
   case ('lp', 'linespoints')
      with = WITH_LINESPOINTS
   case default
      error stop 'foresight: unsupported plotting style "'//trim(name)//'" (supported: lines, points, linespoints)'
   endselect
   endfunction style_with

   pure function dasharray(self) result(dashes)
   !< SVG `stroke-dasharray` of the dash type, scaled by the line width; empty for solid lines.
   class(style_object), intent(in) :: self   !< Style.
   character(len=:), allocatable   :: dashes !< Dash array.

   select case (modulo(self%dashtype - 1_I4P, 5_I4P) + 1_I4P)
   case (2_I4P)
      dashes = scaled([8.0_R8P, 4.0_R8P])
   case (3_I4P)
      dashes = scaled([2.0_R8P, 4.0_R8P])
   case (4_I4P)
      dashes = scaled([8.0_R8P, 4.0_R8P, 2.0_R8P, 4.0_R8P])
   case (5_I4P)
      dashes = scaled([8.0_R8P, 4.0_R8P, 2.0_R8P, 4.0_R8P, 2.0_R8P, 4.0_R8P])
   case default
      dashes = ''
   endselect
   contains
      pure function scaled(pattern) result(str)
      !< Comma separated pattern scaled by the line width.
      real(R8P), intent(in)         :: pattern(:) !< Dash pattern at unit line width [px].
      character(len=:), allocatable :: str        !< Dash array.
      integer(I4P)                  :: i          !< Counter.

      str = fixed(pattern(1) * max(1.0_R8P, self%linewidth), 2_I4P)
      do i = 2_I4P, size(pattern, kind=I4P)
         str = str//','//fixed(pattern(i) * max(1.0_R8P, self%linewidth), 2_I4P)
      enddo
      endfunction scaled
   endfunction dasharray

   elemental function draws_lines(self) result(lines)
   !< Whether the style draws lines.
   class(style_object), intent(in) :: self  !< Style.
   logical                         :: lines !< Lines are drawn.

   lines = self%with /= WITH_POINTS
   endfunction draws_lines

   elemental function draws_points(self) result(points)
   !< Whether the style draws points.
   class(style_object), intent(in) :: self   !< Style.
   logical                         :: points !< Points are drawn.

   points = self%with /= WITH_LINES
   endfunction draws_points

   elemental function point_diameter(self) result(diameter)
   !< Point diameter [px].
   class(style_object), intent(in) :: self     !< Style.
   real(R8P)                       :: diameter !< Point diameter [px].

   diameter = DIAMETER_AT_UNIT_SIZE * self%pointsize
   endfunction point_diameter
endmodule foresight_style
