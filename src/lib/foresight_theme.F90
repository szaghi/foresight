!< foresight_theme, output themes: the page colors of a figure (`classic`, `vfd`, `lcd`).
module foresight_theme
!< foresight_theme, output themes: the page colors of a figure (`classic`, `vfd`, `lcd`).
!<
!< A theme recolors the output, never the figure: the layout draws with gnuplot's colors (black frame and text, grey
!< grid, white page, the gnuplot palette) and the devices map them through `map` as they write. `classic` maps nothing,
!< so the default output is unchanged; `vfd` is a vacuum fluorescent display (black glass, emissive colors, labels
!< printed in blue, glowing data); `lcd` a backlit liquid crystal display (pale green glass, dark segments). Colors
!< other than the frame, grid, page and palette ones (an `lc '#123456'` of the user) are kept.
use penf, only : I4P, R8P
use foresight_style, only : default_color

implicit none
private
public :: theme_object
public :: theme_named
public :: THEMES

character(len=*), parameter :: THEMES = 'classic vfd lcd' !< Theme names.

type :: theme_object
   !< Output theme.
   character(len=7) :: name       = 'classic' !< Name.
   character(len=7) :: background = '#ffffff' !< Page and window background.
   character(len=7) :: frame      = 'black'   !< Border, ticks and text.
   character(len=7) :: grid       = '#a0a0a0' !< Grid lines.
   character(len=7) :: palette(8) = ''        !< Series colors replacing the gnuplot palette; blank: kept.
   logical          :: glow       = .false.   !< Data drawn with a glow.
   real(R8P)        :: ghost      = 0.07_R8P  !< Opacity of the unlit segments and cells.
   contains
      procedure, pass(self) :: is_classic !< Whether the theme maps nothing.
      procedure, pass(self) :: map        !< Theme color of a layout color.
endtype theme_object

contains
   pure function theme_named(name) result(theme)
   !< Theme `name` (see THEMES); `classic` for an unknown name.
   character(len=*), intent(in) :: name  !< Theme name.
   type(theme_object)           :: theme !< Theme.

   select case (trim(name))
   case ('vfd')
      theme%name = 'vfd'
      theme%background = '#04070a'
      theme%frame = '#5d9cff'
      theme%grid = '#15304a'
      theme%palette = ['#3dffc6', '#ffb000', '#ff4040', '#f5e663', '#ff4fd8', '#4fc3ff', '#ff7a1a', '#e8f0ff']
      theme%glow = .true.
      theme%ghost = 0.1_R8P
   case ('lcd')
      theme%name = 'lcd'
      theme%background = '#c8d0b8'
      theme%frame = '#1e2a22'
      theme%grid = '#a3ad98'
      theme%palette = ['#0b3d2e', '#8a3a10', '#1f3a7a', '#6b1f5e', '#4d4d00', '#2f5f8f', '#8f2f2f', '#1e2a22']
      theme%ghost = 0.1_R8P
   endselect
   endfunction theme_named

   elemental function is_classic(self) result(yes)
   !< Whether the theme maps nothing (`classic`).
   class(theme_object), intent(in) :: self !< Theme.
   logical                         :: yes  !< Classic theme.

   yes = self%name == 'classic'
   endfunction is_classic

   pure function map(self, color) result(mapped)
   !< Theme color of the layout `color`: the frame (`black`), grid (`#a0a0a0`), page (`white`) and gnuplot palette
   !< colors become the theme ones, any other color is kept.
   class(theme_object), intent(in) :: self   !< Theme.
   character(len=*),    intent(in) :: color  !< Layout color.
   character(len=:), allocatable   :: mapped !< Theme color.
   integer(I4P)                    :: k      !< Palette counter.

   mapped = color
   if (self%is_classic()) return
   select case (color)
   case ('black')
      mapped = trim(self%frame)
   case ('#a0a0a0')
      mapped = trim(self%grid)
   case ('white', '#ffffff', '#fff')
      mapped = trim(self%background)
   case default
      do k = 1_I4P, size(self%palette, kind=I4P)
         if (color == default_color(k) .and. len_trim(self%palette(k)) > 0) then
            mapped = trim(self%palette(k))
            return
         endif
      enddo
   endselect
   endfunction map
endmodule foresight_theme
