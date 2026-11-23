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
use penf, only : I4P, I8P, R8P

implicit none
private
public :: palette_object
public :: hex_color
public :: named_color
public :: gnuplot_color
public :: palette_gradient
public :: palette_words

integer(I4P), parameter :: PAL_FORMULAE = 0_I4P !< `rgbformulae`.
integer(I4P), parameter :: PAL_DEFINED  = 1_I4P !< `defined`.
integer(I4P), parameter :: PAL_GRAY     = 2_I4P !< `gray`.
integer(I4P), parameter :: PAL_TABLE    = 3_I4P !< A named palette of foresight_colormaps (`viridis`, `batlow`, ...).
integer(I4P), parameter :: PAL_CUBEHELIX = 4_I4P !< `cubehelix`.
real(R8P),    parameter :: CUBEHELIX_DEFAULT(3) = [0.5_R8P, -1.5_R8P, 1.0_R8P] !< gnuplot's start, cycles, saturation.
real(R8P),    parameter :: PI = acos(-1.0_R8P) !< Pi.
integer(I4P), parameter :: COLOR_NAMES_COUNT = 111 !< gnuplot's predefined colors (`show colornames`).
character(len=17), parameter :: COLOR_NAMES(COLOR_NAMES_COUNT) = [ & !< gnuplot 6.0 color names.
   'white            ', 'black            ', 'dark-grey        ', 'red              ', 'web-green        ', &
   'web-blue         ', 'dark-magenta     ', 'dark-cyan        ', 'dark-orange      ', 'dark-yellow      ', &
   'royalblue        ', 'goldenrod        ', 'dark-spring-green', 'purple           ', 'steelblue        ', &
   'dark-red         ', 'dark-chartreuse  ', 'orchid           ', 'aquamarine       ', 'brown            ', &
   'yellow           ', 'turquoise        ', 'grey0            ', 'grey10           ', 'grey20           ', &
   'grey30           ', 'grey40           ', 'grey50           ', 'grey60           ', 'grey70           ', &
   'grey             ', 'grey80           ', 'grey90           ', 'grey100          ', 'light-red        ', &
   'light-green      ', 'light-blue       ', 'light-magenta    ', 'light-cyan       ', 'light-goldenrod  ', &
   'light-pink       ', 'light-turquoise  ', 'gold             ', 'green            ', 'dark-green       ', &
   'spring-green     ', 'forest-green     ', 'sea-green        ', 'blue             ', 'dark-blue        ', &
   'midnight-blue    ', 'navy             ', 'medium-blue      ', 'skyblue          ', 'cyan             ', &
   'magenta          ', 'dark-turquoise   ', 'dark-pink        ', 'coral            ', 'light-coral      ', &
   'orange-red       ', 'salmon           ', 'dark-salmon      ', 'khaki            ', 'dark-khaki       ', &
   'dark-goldenrod   ', 'beige            ', 'olive            ', 'orange           ', 'violet           ', &
   'dark-violet      ', 'plum             ', 'dark-plum        ', 'dark-olivegreen  ', 'orangered4       ', &
   'brown4           ', 'sienna4          ', 'orchid4          ', 'mediumpurple3    ', 'slateblue        ', &
   'yellow4          ', 'sienna1          ', 'tan1             ', 'sandybrown       ', 'light-salmon     ', &
   'pink             ', 'khaki1           ', 'lemonchiffon     ', 'bisque           ', 'honeydew         ', &
   'slategrey        ', 'seagreen         ', 'antiquewhite     ', 'chartreuse       ', 'greenyellow      ', &
   'gray             ', 'light-gray       ', 'light-grey       ', 'dark-gray        ', 'slategray        ', &
   'gray0            ', 'gray10           ', 'gray20           ', 'gray30           ', 'gray40           ', &
   'gray50           ', 'gray60           ', 'gray70           ', 'gray80           ', 'gray90           ', &
   'gray100          ']
character(len=6), parameter :: COLOR_VALUES(COLOR_NAMES_COUNT) = [ & !< Their RRGGBB values.
   'ffffff', '000000', 'a0a0a0', 'ff0000', '00c000', '0080ff', 'c000ff', '00eeee', 'c04000', 'c8c800', '4169e1', &
   'ffc020', '008040', 'c080ff', '306080', '8b0000', '408000', 'ff80ff', '7fffd4', 'a52a2a', 'ffff00', '40e0d0', &
   '000000', '1a1a1a', '333333', '4d4d4d', '666666', '7f7f7f', '999999', 'b3b3b3', 'c0c0c0', 'cccccc', 'e5e5e5', &
   'ffffff', 'f03232', '90ee90', 'add8e6', 'f055f0', 'e0ffff', 'eedd82', 'ffb6c1', 'afeeee', 'ffd700', '00ff00', &
   '006400', '00ff7f', '228b22', '2e8b57', '0000ff', '00008b', '191970', '000080', '0000cd', '87ceeb', '00ffff', &
   'ff00ff', '00ced1', 'ff1493', 'ff7f50', 'f08080', 'ff4500', 'fa8072', 'e9967a', 'f0e68c', 'bdb76b', 'b8860b', &
   'f5f5dc', 'a08020', 'ffa500', 'ee82ee', '9400d3', 'dda0dd', '905040', '556b2f', '801400', '801414', '804014', &
   '804080', '8060c0', '8060ff', '808000', 'ff8040', 'ffa040', 'ffa060', 'ffa070', 'ffc0c0', 'ffff80', 'ffffc0', &
   'cdb79e', 'f0fff0', 'a0b6cd', 'c1ffc1', 'cdc0b0', '7cff40', 'a0ff20', 'bebebe', 'd3d3d3', 'd3d3d3', 'a0a0a0', &
   'a0b6cd', '000000', '1a1a1a', '333333', '4d4d4d', '666666', '7f7f7f', '999999', 'b3b3b3', 'cccccc', 'e5e5e5', &
   'ffffff']

type :: palette_object
   !< Color palette.
   integer(I4P)           :: mode = PAL_FORMULAE         !< Palette kind.
   integer(I4P)           :: formulae(3) = [7, 5, 15]   !< gnuplot rgbformulae, R, G, B.
   logical                :: negative = .false.          !< Gray axis reversed.
   integer(I4P)           :: maxcolors = 0_I4P           !< Colors of a quantized palette, 0 for continuous.
   logical                :: hsv = .false.               !< `model HSV`: the components are hue, saturation, value.
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
   ! gnuplot `model HSV`: the components (clamped) are hue, saturation and value, the gray palette excepted
   if (self%hsv .and. self%mode /= PAL_GRAY) f = hsv_rgb(min(1.0_R8P, max(0.0_R8P, f)))
   c = nint(255.0_R8P * min(1.0_R8P, max(0.0_R8P, f)), I4P)
   endfunction rgb

   pure function hsv_rgb(hsv) result(f)
   !< Red, green, blue (0..1) of `hsv`, hue 0..1 (not degrees), as gnuplot's HSV_2_RGB.
   real(R8P), intent(in) :: hsv(3) !< Hue, saturation, value.
   real(R8P)             :: f(3)   !< Red, green, blue.
   real(R8P)             :: h      !< Hue sextant position.
   real(R8P)             :: r      !< Fraction in the sextant.
   real(R8P)             :: p      !< Low channel.
   real(R8P)             :: q      !< Falling channel.
   real(R8P)             :: t      !< Rising channel.
   integer(I4P)          :: i      !< Sextant.

   if (hsv(2) == 0.0_R8P) then
      f = hsv(3)
      return
   endif
   h = hsv(1) * 6.0_R8P
   i = floor(h, I4P)
   r = h - real(i, R8P)
   p = hsv(3) * (1.0_R8P - hsv(2))
   q = hsv(3) * (1.0_R8P - hsv(2) * r)
   t = hsv(3) * (1.0_R8P - hsv(2) * (1.0_R8P - r))
   select case (modulo(i, 6_I4P))
   case (0_I4P)
      f = [hsv(3), t, p]
   case (1_I4P)
      f = [q, hsv(3), p]
   case (2_I4P)
      f = [p, hsv(3), t]
   case (3_I4P)
      f = [p, q, hsv(3)]
   case (4_I4P)
      f = [t, p, hsv(3)]
   case default
      f = [hsv(3), p, q]
   endselect
   endfunction hsv_rgb

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

   pure function color_index(name) result(k)
   !< Index of gnuplot's color `name` (trailing blanks allowed), 0 if none: an exact match, else the first name of the
   !< table that begins `name`, as gnuplot's lookup_table_nth (`grey75` is `grey`).
   character(len=*), intent(in) :: name !< Color name.
   integer(I4P)                 :: k    !< Index.
   integer(I4P)                 :: j    !< Counter.

   do k = 1_I4P, COLOR_NAMES_COUNT
      if (name == COLOR_NAMES(k)) return
   enddo
   k = 0_I4P
   if (len_trim(name) == 0) return
   do j = 1_I4P, COLOR_NAMES_COUNT
      if (index(trim(name), trim(COLOR_NAMES(j))) == 1) then
         k = j
         return
      endif
   enddo
   endfunction color_index

   pure subroutine named_color(name, c, ok)
   !< Channels of a palette color, as gnuplot `set palette defined`: `#rrggbb`, `0xrrggbb` or one of gnuplot's 111
   !< color names (`show colornames`: `red`, `dark-green`, `gray90`, ..., case sensitive).
   character(len=*), intent(in)  :: name !< Color.
   integer(I4P),     intent(out) :: c(3) !< Red, green, blue, 0..255.
   logical,          intent(out) :: ok   !< Color known.
   character(len=:), allocatable :: hex  !< Hexadecimal digits.
   integer(I4P)                  :: k    !< Name counter.

   hex = ''
   k = color_index(name)
   if (k > 0_I4P) hex = COLOR_VALUES(k)
   if (len(hex) == 0) then
      if (len_trim(name) == 7) then
         if (name(1:1) == '#' .and. verify(name(2:7), '0123456789abcdefABCDEF') == 0) hex = name(2:7)
      elseif (len_trim(name) == 8) then
         if ((name(1:2) == '0x' .or. name(1:2) == '0X') .and. verify(name(3:8), '0123456789abcdefABCDEF') == 0) &
            hex = name(3:8)
      endif
   endif
   c = 0_I4P
   ok = len(hex) > 0
   if (ok) c = nint(hex_channels(hex), I4P)
   endsubroutine named_color

   pure subroutine gnuplot_color(spec, color, ok)
   !< SVG color of a gnuplot color string, as `lc rgb "spec"`: one of gnuplot's 111 color names (`show colornames`,
   !< case sensitive, trailing blanks allowed) as its `#rrggbb`, `black` and `white` kept as names (the themes restyle
   !< them); or `#` or `0x` and 1 to 8 hexadecimal digits, read as gnuplot does as the number 0xAARRGGBB (`#0f0` is
   !< 0x0000f0): `#rrggbb`, or with an alpha A (0 opaque, 255 transparent) `#rrggbbaa`, aa = 255 - A.
   character(len=*),              intent(in)  :: spec   !< gnuplot color.
   character(len=:), allocatable, intent(out) :: color  !< SVG color, empty if not a color.
   logical,                       intent(out) :: ok     !< A color.
   character(len=:), allocatable              :: digits !< Hexadecimal digits.
   integer(I8P)                               :: v      !< Number 0xAARRGGBB.
   integer(I4P)                               :: alpha  !< Alpha, 0 opaque.
   integer(I4P)                               :: k      !< Counter.
   integer(I4P)                               :: d      !< Digit value.
   character(len=7)                           :: opacity !< Opacity 255 - A, as the red of `#rr0000`.

   color = ''
   ok = .false.
   k = color_index(spec)
   if (k > 0_I4P) then
      if (trim(COLOR_NAMES(k)) == 'black' .or. trim(COLOR_NAMES(k)) == 'white') then
         color = trim(COLOR_NAMES(k))
      else
         color = '#'//COLOR_VALUES(k)
      endif
      ok = .true.
      return
   endif
   digits = ''
   if (len_trim(spec) >= 2) then
      if (spec(1:1) == '#') then
         digits = trim(spec(2:))
      elseif (len_trim(spec) >= 3) then
         if (spec(1:2) == '0x' .or. spec(1:2) == '0X') digits = trim(spec(3:))
      endif
   endif
   if (len(digits) < 1 .or. len(digits) > 8) return
   v = 0_I8P
   do k = 1_I4P, len(digits, kind=I4P)
      d = index('0123456789abcdef', digits(k:k), kind=I4P) - 1_I4P
      if (d < 0_I4P) d = index('0123456789ABCDEF', digits(k:k), kind=I4P) - 1_I4P
      if (d < 0_I4P) return
      v = 16_I8P * v + int(d, I8P)
   enddo
   alpha = int(v / 16_I8P**6, I4P)
   v = modulo(v, 16_I8P**6)
   color = hex_color([int(v / 65536_I8P, I4P), int(modulo(v / 256_I8P, 256_I8P), I4P), int(modulo(v, 256_I8P), I4P)])
   if (alpha > 0_I4P) then
      ! the alpha's two digits: those of the red channel of hex_color (no substring of a function result)
      opacity = hex_color([255_I4P - alpha, 0_I4P, 0_I4P])
      color = color//opacity(2:3)
   endif
   ok = .true.
   endsubroutine gnuplot_color

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
      case ('model', 'mode')
         ! gnuplot also reads `mode` (its demo colorwheel); RGB or HSV (CMY, XYZ, YIQ not supported)
         call next(w)
         select case (w)
         case ('RGB', 'rgb')
            palette%hsv = .false.
         case ('HSV', 'hsv')
            palette%hsv = .true.
         case default
            bad = 'model '//w//' (RGB and HSV are supported)'
            return
         endselect
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
      logical                       :: triple !< Three numbers.
      real(R8P)                     :: rgb3(3) !< The three components, 0..1.

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
         ! `v r g b`: the three components, 0 to 1 (hue, saturation, value in model HSV), as gnuplot
         triple = components(color, rgb3)
         known = triple
         if (.not. triple) call named_color(color, c, known)
         if (.not. ok .or. .not. known) then
            bad = 'defined item "'//item//'" (a value and a color, #rrggbb, a name or r g b, are expected)'
            return
         endif
         pos = [pos, v]
         if (.not. triple) rgb3 = real(c, R8P) / 255.0_R8P
         ! grown into `grown`: nvfortran 26.9 -O2 zeroes `col = reshape([col, ...], ...)`
         grown = reshape([col, rgb3], [3, size(pos)])
         call move_alloc(grown, col)
      enddo
      call palette_gradient(palette, pos, col, bad)
      if (len(bad) > 0) bad = 'defined ('//bad//')'
      endsubroutine defined_list

      function components(text, f) result(yes)
      !< Whether `text` is three numbers (`r g b`), returned clamped to 0..1 in `f`.
      character(len=*), intent(in)  :: text !< Color text.
      real(R8P),        intent(out) :: f(3) !< Components.
      logical                       :: yes  !< Three numbers.
      integer(I4P)                  :: ios  !< Read status.

      f = 0.0_R8P
      yes = .false.
      if (len_trim(text) == 0 .or. scan(text, '"#'//"'") > 0) return
      if (verify(trim(text), '0123456789.+-eE ') /= 0) return
      read(text, *, iostat=ios) f
      yes = ios == 0_I4P
      if (yes) f = min(1.0_R8P, max(0.0_R8P, f))
      endfunction components
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
