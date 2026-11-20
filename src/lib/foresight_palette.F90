!< foresight_palette, gnuplot color palettes: gray levels (0 to 1) to colors, for images and color boxes.
module foresight_palette
!< foresight_palette, gnuplot color palettes: gray levels (0 to 1) to colors, for images and color boxes.
!<
!< As gnuplot 6.0 (values checked against its `test palette` tables): `rgbformulae R,G,B` (the default 7,5,15: sqrt,
!< cube, sin 2pi) with gnuplot's 37 formulae, a negative number meaning the formula of 1 - gray; `defined (v1 c1, ...)`
!< interpolating linearly in RGB between colors (`#rrggbb` or a gnuplot color name) at increasing values (the script's
!< `file` palettes too, through `palette_gradient`); `gray`
!< (gray to the power 1/1.5, gnuplot's gamma); `viridis`; `negative` reverses the gray axis; `maxcolors N` quantizes:
!< band k = floor(gray N) takes the color of gray k / (N - 1). Channels are rounded to 8 bits.
!< `color` (after `gray`, say) restores the last palette set by `rgbformulae`, `defined` or a name, else the default.
!< `cubehelix [start S] [cycles C] [saturation S]` (gnuplot's defaults 0.5, -1.5, 1 at each `cubehelix`): Green's
!< helix, angle 2pi (S/3 + C gray), lightness gray^(1/1.5) (gamma 1.5), amplitude saturation lightness (1 - lightness)/2.
!< Beyond gnuplot, any named palette of foresight_colormaps (`batlow`, `vik`, `magma`, `cividis`, ..., `viridis`),
!< matched case-insensitively: a 256-color table, gray g taking its color nint(255 g), so `maxcolors N` gives the
!< N colors nint(255 k / (N - 1)), Crameri's discrete palettes.
use, intrinsic :: ieee_arithmetic, only : ieee_is_finite
use foresight_colormaps, only : colormap_hex, colormap_id
use foresight_format, only : real_from_decimal
use penf, only : I4P, R8P

implicit none
private
public :: palette_object
public :: hex_color
public :: named_color
public :: palette_gradient
public :: palette_words

integer(I4P), parameter :: PAL_FORMULAE = 0_I4P !< `rgbformulae`.
integer(I4P), parameter :: PAL_DEFINED  = 1_I4P !< `defined`.
integer(I4P), parameter :: PAL_GRAY     = 2_I4P !< `gray`.
integer(I4P), parameter :: PAL_TABLE    = 3_I4P !< A named palette of foresight_colormaps (`viridis`, `batlow`, ...).
integer(I4P), parameter :: PAL_CUBEHELIX = 4_I4P !< `cubehelix`.
real(R8P),    parameter :: CUBEHELIX_DEFAULT(3) = [0.5_R8P, -1.5_R8P, 1.0_R8P] !< gnuplot's start, cycles, saturation.
real(R8P),    parameter :: PI = acos(-1.0_R8P) !< Pi.

type :: palette_object
   !< Color palette.
   integer(I4P)           :: mode = PAL_FORMULAE         !< Palette kind.
   integer(I4P)           :: formulae(3) = [7, 5, 15]   !< gnuplot rgbformulae, R, G, B.
   logical                :: negative = .false.          !< Gray axis reversed.
   integer(I4P)           :: maxcolors = 0_I4P           !< Colors of a quantized palette, 0 for continuous.
   integer(I4P)           :: table = 0_I4P               !< Named palette (foresight_colormaps index), `PAL_TABLE`.
   real(R8P)              :: cubehelix(3) = CUBEHELIX_DEFAULT !< `cubehelix` start, cycles, saturation.
   integer(I4P)           :: color_mode = PAL_FORMULAE   !< Mode `color` restores: the last set by `rgbformulae`,
                                                         !< `defined` or a name (as gnuplot's last gradient or formulae).
   real(R8P), allocatable :: positions(:)                !< `defined` positions, increasing.
   real(R8P), allocatable :: colors(:,:)                 !< `defined` colors (RGB 0..1, position).
   contains
      procedure, pass(self) :: is_default !< Whether the palette is gnuplot's default.
      procedure, pass(self) :: rgb        !< Color of a gray level, 8-bit channels.
endtype palette_object

contains
   elemental function is_default(self) result(yes)
   !< Whether the palette has gnuplot's default colors: rgbformulae 7,5,15, positive (quantized or not).
   class(palette_object), intent(in) :: self !< Palette.
   logical                           :: yes  !< Default colors.

   yes = self%mode == PAL_FORMULAE .and. all(self%formulae == [7, 5, 15]) .and. .not. self%negative
   endfunction is_default

   pure function rgb(self, gray) result(c)
   !< Color of the gray level `gray` (clamped to 0..1), 8-bit channels.
   class(palette_object), intent(in) :: self !< Palette.
   real(R8P),             intent(in) :: gray !< Gray level.
   integer(I4P)                      :: c(3) !< Red, green, blue, 0..255.
   real(R8P)                         :: g    !< Effective gray.
   real(R8P)                         :: f(3) !< Channels, 0..1.
   real(R8P)                         :: t    !< Interpolation weight.
   real(R8P)                         :: phi  !< Cubehelix angle [rad].
   real(R8P)                         :: a    !< Cubehelix amplitude.
   integer(I4P)                      :: k    !< Counter.

   g = min(1.0_R8P, max(0.0_R8P, gray))
   if (self%maxcolors > 0_I4P) then
      k = min(int(g * real(self%maxcolors, R8P), I4P), self%maxcolors - 1_I4P)
      g = 0.0_R8P
      if (self%maxcolors > 1_I4P) g = real(k, R8P) / real(self%maxcolors - 1_I4P, R8P)
   endif
   if (self%negative) g = 1.0_R8P - g
   select case (self%mode)
   case (PAL_DEFINED)
      f = self%colors(:, size(self%positions))
      if (g <= self%positions(1)) then
         f = self%colors(:, 1)
      else
         do k = 2_I4P, size(self%positions, kind=I4P)
            if (g <= self%positions(k)) then
               t = (g - self%positions(k - 1_I4P)) / (self%positions(k) - self%positions(k - 1_I4P))
               f = (1.0_R8P - t) * self%colors(:, k - 1_I4P) + t * self%colors(:, k)
               exit
            endif
         enddo
      endif
   case (PAL_CUBEHELIX)
      ! gnuplot's: the angle from the gray level, the gamma (1.5) on the lightness only
      phi = 2.0_R8P * PI * (self%cubehelix(1) / 3.0_R8P + g * self%cubehelix(2))
      t = g**(1.0_R8P / 1.5_R8P)
      a = self%cubehelix(3) * t * (1.0_R8P - t) / 2.0_R8P
      f(1) = t + a * (-0.14861_R8P * cos(phi) + 1.78277_R8P * sin(phi))
      f(2) = t + a * (-0.29227_R8P * cos(phi) - 0.90649_R8P * sin(phi))
      f(3) = t + a * (1.97294_R8P * cos(phi))
   case (PAL_GRAY)
      f = g**(1.0_R8P / 1.5_R8P)
   case (PAL_TABLE)
      f = hex_channels(colormap_hex(self%table, nint(g * 255.0_R8P, I4P))) / 255.0_R8P
   case default
      do k = 1_I4P, 3_I4P
         f(k) = formula(self%formulae(k), g)
      enddo
   endselect
   c = nint(255.0_R8P * min(1.0_R8P, max(0.0_R8P, f)), I4P)
   endfunction rgb

   pure function hex_color(c) result(hex)
   !< `#rrggbb` of the 8-bit channels `c`.
   integer(I4P), intent(in) :: c(3) !< Red, green, blue.
   character(len=7)         :: hex  !< Color.
   character(len=*), parameter :: DIGITS = '0123456789abcdef' !< Hexadecimal digits.
   integer(I4P)             :: k    !< Channel counter.

   hex = '#'
   do k = 1_I4P, 3_I4P
      hex(2 * k:2 * k) = DIGITS(c(k) / 16 + 1:c(k) / 16 + 1)
      hex(2 * k + 1:2 * k + 1) = DIGITS(modulo(c(k), 16) + 1:modulo(c(k), 16) + 1)
   enddo
   endfunction hex_color

   pure subroutine named_color(name, c, ok)
   !< Channels of a color: `#rrggbb` or one of gnuplot's names (black, white, red, green, blue, yellow, cyan, magenta,
   !< gray, grey, orange, purple, dark-green, dark-blue, brown, violet, navy).
   character(len=*), intent(in)  :: name !< Color.
   integer(I4P),     intent(out) :: c(3) !< Red, green, blue, 0..255.
   logical,          intent(out) :: ok   !< Color known.
   character(len=:), allocatable :: hex  !< Hexadecimal digits.

   ok = .true.
   select case (trim(name))
   case ('black')
      hex = '000000'
   case ('white')
      hex = 'ffffff'
   case ('red')
      hex = 'ff0000'
   case ('green')
      hex = '00ff00'
   case ('blue')
      hex = '0000ff'
   case ('yellow')
      hex = 'ffff00'
   case ('cyan')
      hex = '00ffff'
   case ('magenta')
      hex = 'ff00ff'
   case ('gray')
      hex = 'bebebe'
   case ('grey')
      hex = 'c0c0c0'
   case ('orange')
      hex = 'ffa500'
   case ('purple')
      hex = 'c080ff'
   case ('dark-green')
      hex = '006400'
   case ('dark-blue')
      hex = '00008b'
   case ('brown')
      hex = 'a52a2a'
   case ('violet')
      hex = 'ee82ee'
   case ('navy')
      hex = '000080'
   case default
      hex = ''
      if (len_trim(name) == 7) then
         if (name(1:1) == '#' .and. verify(name(2:7), '0123456789abcdefABCDEF') == 0) hex = name(2:7)
      endif
   endselect
   c = 0_I4P
   if (len(hex) == 0) then
      ok = .false.
      return
   endif
   c = nint(hex_channels(hex), I4P)
   endsubroutine named_color

   subroutine palette_words(words, palette, bad)
   !< Update `palette` from gnuplot `set palette` words: none (the default), `rgbformulae R , G , B` (`rgb`),
   !< `defined (v c, ...)`, `cubehelix [start S] [cycles C] [saturation S]`, `gray`/`grey`, `color`, `positive`,
   !< `negative`, `maxcolors N`, `model RGB`, and a palette
   !< name of foresight_colormaps (`viridis`, `batlow`, ..., case-insensitive); `bad` is the first word not understood.
   character(len=*),              intent(in)    :: words   !< Words, blank separated (a `defined` list one word).
   type(palette_object),          intent(inout) :: palette !< Palette.
   character(len=:), allocatable, intent(out)   :: bad     !< First word not understood, empty if none.
   character(len=:), allocatable                :: w       !< Current word.
   character(len=:), allocatable                :: rest    !< Remaining words.
   real(R8P)                                    :: v       !< Number.
   logical                                      :: ok      !< Number read.
   integer(I4P)                                 :: k       !< Formula counter, palette index.
   type(palette_object)                         :: initial !< Default palette (nvfortran: no empty constructor).

   bad = ''
   rest = trim(adjustl(words))
   if (len(rest) == 0) then
      palette = initial
      return
   endif
   do while (len(rest) > 0)
      call next(w)
      select case (w)
      case ('rgbformulae', 'rgb')
         do k = 1_I4P, 3_I4P
            call next(w)
            if (w == ',') call next(w)
            call real_from_decimal(w, v, ok)
            if (.not. ok) then
               bad = 'rgbformulae '//w//' (three formula numbers R,G,B are expected)'
               return
            endif
            if (abs(v) > 36.0_R8P .or. v /= aint(v)) then
               bad = 'rgbformulae '//w//' (the formulae are -36 to 36)'
               return
            endif
            palette%formulae(k) = int(v, I4P)
         enddo
         palette%mode = PAL_FORMULAE
         palette%color_mode = PAL_FORMULAE
      case ('defined')
         ! the list runs to its closing parenthesis, blanks included
         rest = trim(adjustl(rest))
         k = index(rest, ')', kind=I4P)
         if (len(rest) == 0 .or. k == 0_I4P) then
            bad = 'defined (a list (v1 "color1", v2 "color2", ...) is expected)'
            return
         endif
         w = rest(1:k)
         rest = rest(k + 1_I4P:)
         call defined_list(w)
         if (len(bad) > 0) return
      case ('cubehelix')
         palette%mode = PAL_CUBEHELIX
         palette%cubehelix = CUBEHELIX_DEFAULT
         call cubehelix_options
         if (len(bad) > 0) return
      case ('gray', 'grey')
         palette%mode = PAL_GRAY
      case ('color')
         palette%mode = palette%color_mode
      case ('positive')
         palette%negative = .false.
      case ('negative')
         palette%negative = .true.
      case ('maxcolors')
         call next(w)
         call real_from_decimal(w, v, ok)
         if (.not. ok .or. v < 0.0_R8P .or. v /= aint(v) .or. v > 1.0e6_R8P) then
            bad = 'maxcolors '//w//' (a number of colors is expected, 0 for continuous)'
            return
         endif
         palette%maxcolors = int(v, I4P)
      case ('model')
         call next(w)
         if (w /= 'RGB') then
            bad = 'model '//w//' (only RGB is supported)'
            return
         endif
      case default
         k = colormap_id(w)
         if (k == 0_I4P) then
            bad = w
            return
         endif
         palette%mode = PAL_TABLE
         palette%color_mode = PAL_TABLE
         palette%table = k
      endselect
   enddo
   contains
      subroutine next(word)
      !< Pop the next blank separated word of `rest`, empty if none.
      character(len=:), allocatable, intent(out) :: word !< Word.
      integer(I4P)                               :: e    !< Word end.

      rest = trim(adjustl(rest))
      e = index(rest, ' ', kind=I4P)
      if (e == 0_I4P) e = len(rest, kind=I4P) + 1_I4P
      word = rest(1:e - 1_I4P)
      rest = rest(e:)
      endsubroutine next

      subroutine cubehelix_options
      !< Read the `start S`, `cycles C`, `saturation S` right after `cubehelix`, in any order, the last one winning.
      character(len=:), allocatable :: key   !< Option.
      integer(I4P)                  :: e     !< Option end.
      integer(I4P)                  :: c     !< Parameter index.

      do
         rest = trim(adjustl(rest))
         e = index(rest, ' ', kind=I4P)
         if (e == 0_I4P) e = len(rest, kind=I4P) + 1_I4P
         key = rest(1:e - 1_I4P)
         select case (key)
         case ('start')
            c = 1_I4P
         case ('cycles')
            c = 2_I4P
         case ('saturation')
            c = 3_I4P
         case default
            exit
         endselect
         call next(key)
         call next(w)
         call real_from_decimal(w, v, ok)
         if (ok) ok = ieee_is_finite(v)
         if (.not. ok) then
            bad = 'cubehelix '//key//' '//w//' (a number is expected)'
            return
         endif
         palette%cubehelix(c) = v
      enddo
      endsubroutine cubehelix_options

      subroutine defined_list(list)
      !< Parse `(v1 c1, v2 c2, ...)`: increasing values, colors quoted or not; the values are mapped to 0..1.
      character(len=*), intent(in) :: list   !< List, parentheses included.
      character(len=:), allocatable :: body  !< List without parentheses.
      character(len=:), allocatable :: item  !< One `v c` pair.
      character(len=:), allocatable :: color !< Color word.
      real(R8P), allocatable        :: pos(:) !< Positions.
      real(R8P), allocatable        :: col(:,:) !< Colors.
      real(R8P), allocatable        :: grown(:,:) !< Colors, one more.
      integer(I4P)                  :: c(3)  !< Channels.
      integer(I4P)                  :: comma !< Item end.
      integer(I4P)                  :: blank !< Value end.
      logical                       :: known !< Color known.

      if (len(list) < 2) then
         bad = 'defined (a list (v1 "color1", v2 "color2", ...) is expected)'
         return
      endif
      if (list(1:1) /= '(' .or. list(len(list):len(list)) /= ')') then
         bad = 'defined '//list//' (a list (v1 "color1", v2 "color2", ...) is expected)'
         return
      endif
      body = list(2:len(list) - 1)
      allocate(pos(0), col(3, 0))
      do while (len_trim(body) > 0)
         comma = index(body, ',', kind=I4P)
         if (comma == 0_I4P) comma = len(body, kind=I4P) + 1_I4P
         item = trim(adjustl(body(1:comma - 1_I4P)))
         body = body(min(comma + 1_I4P, len(body, kind=I4P) + 1_I4P):)
         blank = index(item, ' ', kind=I4P)
         if (blank == 0_I4P) then
            bad = 'defined item "'//item//'" (a value and a color are expected)'
            return
         endif
         call real_from_decimal(item(1:blank - 1_I4P), v, ok)
         color = trim(adjustl(item(blank + 1_I4P:)))
         if (len(color) >= 2) then
            if ((color(1:1) == '"' .or. color(1:1) == "'") .and. color(len(color):len(color)) == color(1:1)) &
               color = color(2:len(color) - 1)
         endif
         call named_color(color, c, known)
         if (.not. ok .or. .not. known) then
            bad = 'defined item "'//item//'" (a value and a color, #rrggbb or a name, are expected)'
            return
         endif
         pos = [pos, v]
         ! grown into `grown`: nvfortran 26.9 -O2 zeroes `col = reshape([col, ...], ...)`
         grown = reshape([col, real(c, R8P) / 255.0_R8P], [3, size(pos)])
         call move_alloc(grown, col)
      enddo
      call palette_gradient(palette, pos, col, bad)
      if (len(bad) > 0) bad = 'defined ('//bad//')'
      endsubroutine defined_list
   endsubroutine palette_words

   pure subroutine palette_gradient(palette, positions, colors, bad)
   !< Make `palette` the gradient of `colors` (RGB 0..1, clipped) at `positions`, increasing (equal ones make a sharp
   !< step), mapped to 0..1, as gnuplot `defined` and `file` palettes; `bad` says why not, empty if done.
   type(palette_object),          intent(inout) :: palette      !< Palette.
   real(R8P),                     intent(in)    :: positions(:) !< Positions.
   real(R8P),                     intent(in)    :: colors(:,:)  !< Colors (RGB, position).
   character(len=:), allocatable, intent(out)   :: bad          !< Problem, empty if none.
   integer(I4P)                                 :: n            !< Colors.

   bad = ''
   n = size(positions, kind=I4P)
   if (.not. (all(ieee_is_finite(positions)) .and. all(ieee_is_finite(colors)))) then
      bad = 'finite values and colors are expected'
      return
   endif
   if (n < 2_I4P) then
      bad = 'at least two colors at different values are expected'
      return
   endif
   if (any(positions(2:) < positions(:n - 1_I4P))) then
      bad = 'the values must increase'
      return
   endif
   if (positions(n) == positions(1)) then
      bad = 'at least two colors at different values are expected'
      return
   endif
   palette%positions = (positions - positions(1)) / (positions(n) - positions(1))
   palette%colors = min(1.0_R8P, max(0.0_R8P, colors))
   palette%mode = PAL_DEFINED
   palette%color_mode = PAL_DEFINED
   endsubroutine palette_gradient

   ! private procedures
   pure function hex_channels(hex) result(c)
   !< Channels of `rrggbb` (0..255, as reals).
   character(len=6), intent(in) :: hex  !< Hexadecimal color.
   real(R8P)                    :: c(3) !< Red, green, blue.
   integer(I4P)                 :: k    !< Channel counter.

   do k = 1_I4P, 3_I4P
      c(k) = real(16 * digit(hex(2 * k - 1:2 * k - 1)) + digit(hex(2 * k:2 * k)), R8P)
   enddo
   contains
      pure function digit(ch) result(d)
      !< Value of a hexadecimal digit.
      character(len=1), intent(in) :: ch !< Digit.
      integer(I4P)                 :: d  !< Value.

      d = index('0123456789abcdef', ch) - 1
      if (d < 0) d = index('0123456789ABCDEF', ch) - 1
      endfunction digit
   endfunction hex_channels

   pure function formula(n, x) result(f)
   !< gnuplot rgbformula `n` (-36..36, negative for the formula of 1 - x) at `x`, clamped to 0..1.
   integer(I4P), intent(in) :: n !< Formula number.
   real(R8P),    intent(in) :: x !< Gray level.
   real(R8P)                :: f !< Channel.
   real(R8P), parameter     :: PI = 4.0_R8P * atan(1.0_R8P) !< pi.
   real(R8P)                :: g !< Formula argument.

   g = x
   if (n < 0_I4P) g = 1.0_R8P - x
   select case (abs(n))
   case (0_I4P)
      f = 0.0_R8P
   case (1_I4P)
      f = 0.5_R8P
   case (2_I4P)
      f = 1.0_R8P
   case (3_I4P)
      f = g
   case (4_I4P)
      f = g**2
   case (5_I4P)
      f = g**3
   case (6_I4P)
      f = g**4
   case (7_I4P)
      f = sqrt(g)
   case (8_I4P)
      f = sqrt(sqrt(g))
   case (9_I4P)
      f = sin(0.5_R8P * PI * g)
   case (10_I4P)
      f = cos(0.5_R8P * PI * g)
   case (11_I4P)
      f = abs(g - 0.5_R8P)
   case (12_I4P)
      f = (2.0_R8P * g - 1.0_R8P)**2
   case (13_I4P)
      f = sin(PI * g)
   case (14_I4P)
      f = abs(cos(PI * g))
   case (15_I4P)
      f = sin(2.0_R8P * PI * g)
   case (16_I4P)
      f = cos(2.0_R8P * PI * g)
   case (17_I4P)
      f = abs(sin(2.0_R8P * PI * g))
   case (18_I4P)
      f = abs(cos(2.0_R8P * PI * g))
   case (19_I4P)
      f = abs(sin(4.0_R8P * PI * g))
   case (20_I4P)
      f = abs(cos(4.0_R8P * PI * g))
   case (21_I4P)
      f = 3.0_R8P * g
   case (22_I4P)
      f = 3.0_R8P * g - 1.0_R8P
   case (23_I4P)
      f = 3.0_R8P * g - 2.0_R8P
   case (24_I4P)
      f = abs(3.0_R8P * g - 1.0_R8P)
   case (25_I4P)
      f = abs(3.0_R8P * g - 2.0_R8P)
   case (26_I4P)
      f = (3.0_R8P * g - 1.0_R8P) / 2.0_R8P
   case (27_I4P)
      f = (3.0_R8P * g - 2.0_R8P) / 2.0_R8P
   case (28_I4P)
      f = abs((3.0_R8P * g - 1.0_R8P) / 2.0_R8P)
   case (29_I4P)
      f = abs((3.0_R8P * g - 2.0_R8P) / 2.0_R8P)
   case (30_I4P)
      f = g / 0.32_R8P - 0.78125_R8P
   case (31_I4P)
      f = 2.0_R8P * g - 0.84_R8P
   case (32_I4P)
      if (g < 0.25_R8P) then
         f = 4.0_R8P * g
      elseif (g < 0.42_R8P) then
         f = 1.0_R8P
      elseif (g < 0.92_R8P) then
         f = -2.0_R8P * g + 1.84_R8P
      else
         f = g / 0.08_R8P - 11.5_R8P
      endif
   case (33_I4P)
      f = abs(2.0_R8P * g - 0.5_R8P)
   case (34_I4P)
      f = 2.0_R8P * g
   case (35_I4P)
      f = 2.0_R8P * g - 0.5_R8P
   case default
      f = 2.0_R8P * g - 1.0_R8P
   endselect
   f = min(1.0_R8P, max(0.0_R8P, f))
   endfunction formula
endmodule foresight_palette
