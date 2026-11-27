!< foresight_theme, output themes: the page colors of a figure (`classic`, `vfd`, `lcd`, `washi`, `night`, `paper`).
module foresight_theme
!< foresight_theme, output themes: the page colors of a figure (`classic`, `vfd`, `lcd`, `washi`, `night`, `paper`).
!<
!< A theme recolors the output, never the figure: the layout draws with gnuplot's colors (black frame and text, grey
!< grid, white page, the linetype colors) and the devices map them through `map` as they write. `classic` maps nothing,
!< so the default output is unchanged; `vfd` is a vacuum fluorescent display (black glass, emissive colors, labels
!< printed in blue, glowing data); `lcd` a backlit liquid crystal display (pale green glass, dark segments). `washi`
!< and `night` are the two faces of foresight's own identity, its documentation's light and dark modes: ink on warm
!< paper with a crimson first series, and light text on a near-black red ground with a rose first series; every
!< series color contrasts with its ground at least 3:1 (WCAG non-text contrast). `paper` is a figure for a paper: the
!< classic page with the Okabe-Ito colors (the figure adds 8 pt texts, foresight_figure `set_theme`). Colors
!< other than the frame, grid, page and palette ones (an `lc '#123456'` of the user) are kept. A new figure takes the
!< theme of the environment variable `FORESIGHT_THEME` (an unknown name ignored) until one is set (foresight_figure).
use penf, only : I4P, R8P
use foresight_style, only : default_color

implicit none
private
public :: theme_object
public :: theme_named
public :: THEMES

character(len=*), parameter :: THEMES = 'classic vfd lcd washi night paper' !< Theme names.

type :: theme_object
   !< Output theme.
   character(len=7) :: name       = 'classic' !< Name.
   character(len=7) :: background = '#ffffff' !< Page and window background.
   character(len=7) :: frame      = 'black'   !< Border, ticks and text.
   character(len=7) :: grid       = '#a0a0a0' !< Grid lines.
   character(len=7) :: palette(8) = ''        !< Series colors replacing the linetype colors; blank: kept.
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
   case ('washi')
      theme%name = 'washi'
      theme%background = '#f3ede1'
      theme%frame = '#1d1b18'
      theme%grid = '#a69a85'
      theme%palette = ['#b3163f', '#1f5f8b', '#2e7d4f', '#b86a00', '#6b3fa0', '#0f7c80', '#8a5a2b', '#1d1b18']
   case ('paper')
      ! figures for a paper: a white page, black frame and text, the Okabe-Ito colors (the figure sets 8 pt texts)
      theme%name = 'paper'
      theme%palette = ['#0072b2', '#d55e00', '#009e73', '#cc79a7', '#e69f00', '#56b4e9', '#f0e442', '#000000']
   case ('night')
      theme%name = 'night'
      theme%background = '#130d0f'
      theme%frame = '#e8ecf0'
      theme%grid = '#5c4950'
      theme%palette = ['#ff7092', '#6cb6ff', '#6fd99a', '#ffb454', '#c49bff', '#45d4d4', '#e6a87c', '#e8ecf0']
   endselect
   endfunction theme_named

   elemental function is_classic(self) result(yes)
   !< Whether the theme maps nothing (`classic`).
   class(theme_object), intent(in) :: self !< Theme.
   logical                         :: yes  !< Classic theme.

   yes = self%name == 'classic'
   endfunction is_classic

   pure function map(self, color) result(mapped)
   !< Theme color of the layout `color`: the frame (`black`), grid (`#a0a0a0`), page (`white`) and linetype
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
