!< foresight_style, series drawing style (gnuplot `with`, `lc`, `lw`, `dt`, `pt`, `ps`, `fs`).
module foresight_style
!< foresight_style, series drawing style (gnuplot `with`, `lc`, `lw`, `dt`, `pt`, `ps`, `fs`).
!<
!< Filled styles (`boxes`, `filledcurves`) take gnuplot's fill style: `empty` (the default, the border only), `solid D`
!< (the line color at opacity D, 1 by default; `transparent` before it changes nothing in SVG, as gnuplot's svg
!< terminal), with a `border` in the line color, another color (`border lc "c"`, `border -1` black) or `noborder`.
!< foresight adds `segments N` (boxes and histograms): the y range cut into N cells, a bar lighting the cells it covers
!< at least half, the others drawn faintly, as the bar graphs of a 1980s display.
use penf, only : I4P, R8P
use foresight_colormaps, only : CATEGORICAL_LEVELS, categorical_hex, categorical_id
use foresight_format, only : fixed, real_from_decimal

implicit none
private
public :: default_color
public :: sequence_colors
public :: fill_style
public :: style_object
public :: style_name
public :: gnuplot_abbreviates
public :: custom_dashtype
public :: CUSTOM_DASH_BASE
public :: style_with
public :: WITH_BOXES, WITH_CIRCLES, WITH_FILLEDCURVES, WITH_HISTOGRAMS, WITH_IMAGE, WITH_LINES, WITH_PIE, &
          WITH_LINESPOINTS, WITH_POINTS, WITH_READOUT, WITH_GAUGE, WITH_RADAR, WITH_ROSE, &
          WITH_XERRORBARS, WITH_XYERRORBARS, WITH_YERRORBARS, WITH_IMPULSES, WITH_STEPS, WITH_FSTEPS, WITH_HISTEPS, &
          WITH_FILLSTEPS, WITH_PM3D, WITH_MASK, &
          WITH_DOTS, WITH_YERRORLINES, WITH_XERRORLINES, WITH_XYERRORLINES, WITH_BOXERRORBARS, WITH_BOXXYERROR, &
          WITH_CANDLESTICKS, WITH_FINANCEBARS, WITH_BOXPLOT, WITH_VECTORS, WITH_ARROWS, WITH_ELLIPSES, WITH_POLYGONS, &
          WITH_LABELS, WITH_SECTORS, WITH_PARALLELAXES, WITH_SPIDERPLOT
public :: STYLE_NAMES
public :: FILL_EMPTY, FILL_PATTERN, FILL_SOLID
public :: pattern_parts
public :: PATTERNS

integer(I4P), parameter :: CUSTOM_DASH_BASE = 1000_I4P !< Dash types above it are custom patterns (`custom_dashtype`).
integer(I4P), parameter :: MAX_CUSTOM_DASHES = 256_I4P  !< Custom dash patterns kept.
! the custom dash patterns of the session (gnuplot `dt "-."`, `dt (a,b,...)`): solid and empty lengths at line width
! 1 in gnuplot's units, comma separated; dash type CUSTOM_DASH_BASE + k is pattern k
character(len=160), save :: custom_dashes(MAX_CUSTOM_DASHES) = '' !< Patterns.
integer(I4P),       save :: custom_dash_count = 0_I4P             !< Patterns kept.
integer(I4P), parameter :: WITH_LINES       = 1_I4P !< gnuplot `with lines`.
integer(I4P), parameter :: WITH_POINTS      = 2_I4P !< gnuplot `with points`.
integer(I4P), parameter :: WITH_LINESPOINTS = 3_I4P !< gnuplot `with linespoints`.
integer(I4P), parameter :: WITH_YERRORBARS  = 4_I4P !< gnuplot `with yerrorbars`.
integer(I4P), parameter :: WITH_XERRORBARS  = 5_I4P !< gnuplot `with xerrorbars`.
integer(I4P), parameter :: WITH_XYERRORBARS = 6_I4P !< gnuplot `with xyerrorbars`.
integer(I4P), parameter :: WITH_READOUT     = 7_I4P !< foresight `with readout`: the last value in seven-segment digits.
integer(I4P), parameter :: WITH_BOXES       = 8_I4P !< gnuplot `with boxes`.
integer(I4P), parameter :: WITH_FILLEDCURVES = 9_I4P !< gnuplot `with filledcurves`.
integer(I4P), parameter :: WITH_HISTOGRAMS  = 10_I4P !< gnuplot `with histograms`.
integer(I4P), parameter :: WITH_IMAGE       = 11_I4P !< gnuplot `with image`.
integer(I4P), parameter :: WITH_CIRCLES     = 12_I4P !< gnuplot `with circles`: circles and wedges.
integer(I4P), parameter :: WITH_PIE         = 13_I4P !< foresight `with pie`: a pie or donut chart.
integer(I4P), parameter :: WITH_GAUGE       = 14_I4P !< foresight `with gauge`: the last value on a sweep gauge.
integer(I4P), parameter :: WITH_RADAR       = 15_I4P !< foresight `with radar`: a polygon over the spokes of the rows.
integer(I4P), parameter :: WITH_ROSE        = 16_I4P !< foresight `with rose`: equal sectors, area or radius by value.
integer(I4P), parameter :: WITH_IMPULSES    = 17_I4P !< gnuplot `with impulses`: a segment from y = 0 to each point.
integer(I4P), parameter :: WITH_STEPS       = 18_I4P !< gnuplot `with steps`: horizontal, then vertical.
integer(I4P), parameter :: WITH_FSTEPS      = 19_I4P !< gnuplot `with fsteps`: vertical, then horizontal.
integer(I4P), parameter :: WITH_HISTEPS     = 20_I4P !< gnuplot `with histeps`: steps around the points, from y = 0.
integer(I4P), parameter :: WITH_DOTS        = 21_I4P !< gnuplot `with dots`: a tiny dot per point.
integer(I4P), parameter :: WITH_YERRORLINES = 22_I4P !< gnuplot `with yerrorlines`: linespoints and y error bars.
integer(I4P), parameter :: WITH_XERRORLINES = 23_I4P !< gnuplot `with xerrorlines`: linespoints and x error bars.
integer(I4P), parameter :: WITH_XYERRORLINES = 24_I4P !< gnuplot `with xyerrorlines`: linespoints and both bars.
integer(I4P), parameter :: WITH_BOXERRORBARS = 25_I4P !< gnuplot `with boxerrorbars`: boxes with y error bars.
integer(I4P), parameter :: WITH_BOXXYERROR  = 26_I4P !< gnuplot `with boxxyerror`: a rectangle per point.
integer(I4P), parameter :: WITH_CANDLESTICKS = 27_I4P !< gnuplot `with candlesticks`: box and whiskers.
integer(I4P), parameter :: WITH_FINANCEBARS = 28_I4P !< gnuplot `with financebars`: high-low bars, open/close ticks.
integer(I4P), parameter :: WITH_BOXPLOT     = 29_I4P !< gnuplot `with boxplot`: quartiles of the values, outliers.
integer(I4P), parameter :: WITH_VECTORS     = 30_I4P !< gnuplot `with vectors`: arrows from x:y by dx:dy.
integer(I4P), parameter :: WITH_ARROWS      = 31_I4P !< gnuplot `with arrows`: arrows from x:y by length and angle.
integer(I4P), parameter :: WITH_ELLIPSES    = 32_I4P !< gnuplot `with ellipses`: an ellipse per point.
integer(I4P), parameter :: WITH_POLYGONS    = 33_I4P !< gnuplot `with polygons`: a closed polygon per block.
integer(I4P), parameter :: WITH_LABELS      = 34_I4P !< gnuplot `with labels`: text at each point.
integer(I4P), parameter :: WITH_SECTORS     = 35_I4P !< gnuplot `with sectors`: annular sectors.
integer(I4P), parameter :: WITH_PARALLELAXES = 36_I4P !< gnuplot `with parallelaxes`: an axis per item, a line per row.
integer(I4P), parameter :: WITH_SPIDERPLOT  = 37_I4P !< gnuplot `with spiderplot`: a radial axis per item, a polygon
                                                    !< per row.
integer(I4P), parameter :: WITH_FILLSTEPS   = 38_I4P !< gnuplot `with fillsteps`: the area under `steps` filled.
integer(I4P), parameter :: WITH_PM3D        = 39_I4P !< gnuplot `with pm3d` (splot): a surface as colored quadrangles.
integer(I4P), parameter :: WITH_MASK        = 40_I4P !< gnuplot `with mask`: polygons masking the `mask` items, not drawn.
character(len=*), parameter :: STYLE_NAMES = 'lines, points, linespoints, impulses, steps, fsteps, histeps, '// &
                                             'fillsteps, dots, '// &
                                             'yerrorbars, xerrorbars, xyerrorbars, yerrorlines, xerrorlines, '// &
                                             'xyerrorlines, boxes, boxerrorbars, boxxyerror, candlesticks, '// &
                                             'financebars, boxplot, vectors, arrows, ellipses, polygons, labels, '// &
                                             'sectors, parallelaxes, spiderplot, filledcurves, histograms, image, '// &
                                             'rgbimage, rgbalpha, '// &
                                             'circles, pie, '// &
                                             'gauge, radar, rose, readout, pm3d (splot)' !< Supported style names.
integer(I4P), parameter :: FILL_EMPTY       = 0_I4P !< gnuplot `set style fill empty`: no fill.
integer(I4P), parameter :: FILL_SOLID       = 1_I4P !< gnuplot `set style fill solid`.
integer(I4P), parameter :: FILL_PATTERN     = 2_I4P !< gnuplot `set style fill pattern N`.
integer(I4P), parameter :: PATTERNS         = 8_I4P !< Fill patterns of gnuplot's svg terminal, cycling: 0 empty, 1
                                                    !< crosshatch, 2 dense crosshatch, 3 solid, 4 and 7 lines down,
                                                    !< 5 and 6 lines up (6, 7 steeper).

character(len=7), parameter :: PALETTE(8) = ['#9400d3', '#009e73', '#56b4e9', '#e69f00', &
                                             '#f0e442', '#0072b2', '#e51e10', '#000000'] !< gnuplot 5 line colors.
real(R8P),        parameter :: DIAMETER_AT_UNIT_SIZE = 6.0_R8P !< Round dot diameter at `pointsize` 1 [px].
real(R8P),        parameter :: MARKER_AT_UNIT_SIZE   = 9.0_R8P !< Point type size at `pointsize` 1 [px], gnuplot svg.

type :: style_object
   !< Series drawing style.
   integer(I4P)                  :: with      = WITH_LINES !< Plotting style.
   character(len=:), allocatable :: color                  !< Line and point color (SVG color).
   real(R8P)                     :: linewidth = 1.0_R8P    !< Line width [px].
   integer(I4P)                  :: dashtype  = 1_I4P      !< gnuplot dash type: 1 solid, 2..5 dash patterns.
   real(R8P)                     :: pointsize = 1.0_R8P    !< Point size scale factor.
   integer(I4P)                  :: pointtype = -1_I4P     !< gnuplot point type: 0 a dot, 1.. the shapes (cycling every
                                                           !< 15); negative for foresight's round dot.
   integer(I4P)                  :: fill      = FILL_EMPTY !< Fill of filled styles.
   real(R8P)                     :: density   = 1.0_R8P    !< Fill opacity, solid fills.
   logical                       :: border    = .true.     !< Border of filled styles.
   character(len=:), allocatable :: border_color           !< Border color, empty for the line color.
   integer(I4P)                  :: segments  = 0_I4P      !< Cells over the y range of a segmented fill, 0 for none.
   integer(I4P)                  :: pattern   = 0_I4P      !< Fill pattern (FILL_PATTERN), cycling every PATTERNS.
   character(len=:), allocatable :: fill_rgb               !< Fill color (gnuplot `fc`), empty or unallocated for the
                                                           !< line color.
   character(len=:), allocatable :: point_char             !< A character as the point (gnuplot `pt "c"`), drawn in
                                                           !< place of the point type when allocated and not empty.
   contains
      procedure, pass(self) :: dasharray      !< SVG dash array.
      procedure, pass(self) :: draws_xbars    !< Whether horizontal error bars are drawn.
      procedure, pass(self) :: fills          !< Whether the style is a filled one.
      procedure, pass(self) :: fill_color     !< Fill color, `none` if empty.
      procedure, pass(self) :: stroke_color   !< Border color of a filled style, `none` if no border.
      procedure, pass(self) :: draws_ybars    !< Whether vertical error bars are drawn.
      procedure, pass(self) :: draws_lines    !< Whether lines are drawn.
      procedure, pass(self) :: draws_points   !< Whether points are drawn.
      procedure, pass(self) :: point_diameter !< Point diameter [px].
endtype style_object

contains
   pure function default_color(index, colors) result(color)
   !< Color of linetype `index`, cycling the active sequence `colors` (`set colorsequence`), else gnuplot 5's
   !< linetype colors.
   integer(I4P),     intent(in)           :: index     !< Series index, from 1.
   character(len=9), intent(in), optional :: colors(:) !< Active color sequence; absent or empty: gnuplot's default.
   character(len=:), allocatable          :: color     !< SVG color.

   if (present(colors)) then
      if (size(colors) > 0) then
         color = trim(colors(modulo(index - 1_I4P, size(colors, kind=I4P)) + 1_I4P))
         return
      endif
   endif
   color = PALETTE(modulo(index - 1_I4P, size(PALETTE, kind=I4P)) + 1_I4P)
   endfunction default_color

   pure subroutine sequence_colors(name, n, colors, bad)
   !< Colors of the sequence `name`, as gnuplot `set colorsequence`: `default` (gnuplot 5's, returned empty: the
   !< default), `podo` (8 colors) or `classic` (gnuplot's svg terminal, 13 colors); beyond gnuplot, a categorical order
   !< of foresight_colormaps (`batlowS`, ..., any case), its first `n` colors (8 if `n` < 1), the most distinct first.
   character(len=*),              intent(in)  :: name      !< Sequence name.
   integer(I4P),                  intent(in)  :: n         !< Colors of a categorical order; < 1 for 8.
   character(len=9), allocatable, intent(out) :: colors(:) !< Colors, `#rrggbb`; empty for gnuplot's default.
   character(len=:), allocatable, intent(out) :: bad       !< Why not, empty if done.
   integer(I4P)                               :: id        !< Categorical order.
   integer(I4P)                               :: m         !< Colors taken.
   integer(I4P)                               :: k         !< Counter.

   bad = ''
   select case (name)
   case ('default')
      allocate(colors(0))
   case ('podo')
      colors = ['#000000', '#e69f00', '#56b4e9', '#009e73', '#f0e442', '#0072b2', '#d55e00', '#cc79a7']
   case ('classic')
      colors = ['#ff0000', '#008000', '#0000ff', '#00ffff', '#157545', '#000094', '#ff9900', '#0099a1', '#d6d645', &
                '#a391ff', '#ffcc00', '#d60078', '#abd600']
   case default
      id = categorical_id(name)
      if (id == 0_I4P) then
         bad = 'unknown color sequence "'//name//'" (default, podo, classic or a categorical order: batlowS, ...)'
         allocate(colors(0))
         return
      endif
      m = 8_I4P
      if (n > 0_I4P) m = n
      if (m > CATEGORICAL_LEVELS) then
         bad = 'a categorical order has 1 to 100 colors'
         allocate(colors(0))
         return
      endif
      allocate(colors(m))
      do k = 1_I4P, m
         colors(k) = '#'//categorical_hex(id, k)
      enddo
   endselect
   endsubroutine sequence_colors

   function custom_dashtype(spec, ok) result(dt)
   !< The dash type of gnuplot's custom pattern `spec`: a dash string (`.` dot and short gap, `-` dash and gap, `_` long
   !< dash and gap, a blank lengthening the last gap) or the lengths `(solid, empty, ...)` at line width 1; kept for the
   !< session (a pattern seen before gets its number back). `ok` false for a malformed one; 1 (solid) for an empty one.
   character(len=*), intent(in)  :: spec !< Pattern: a dash string, or the lengths in parentheses.
   logical,          intent(out) :: ok   !< Well formed.
   integer(I4P)                  :: dt   !< Dash type.
   character(len=:), allocatable :: lengths !< Comma separated lengths.
   real(R8P)                     :: v(64) !< Lengths.
   integer(I4P)                  :: n    !< Lengths read.
   integer(I4P)                  :: lead !< Leading blanks.
   integer(I4P)                  :: k    !< Counter.
   integer(I4P)                  :: ios  !< Read status.

   dt = 1_I4P
   ok = .true.
   n = 0_I4P
   lead = 0_I4P
   if (len_trim(spec) > 0 .and. spec(1:1) == '(') then
      ! (a, b, c, d): solid and empty lengths in pairs
      if (spec(len_trim(spec):len_trim(spec)) /= ')') then
         ok = .false.
         return
      endif
      lengths = spec(2:len_trim(spec) - 1)
      n = 1_I4P
      do k = 1_I4P, len(lengths, kind=I4P)
         if (lengths(k:k) == ',') n = n + 1_I4P
      enddo
      if (n > 64_I4P .or. mod(n, 2_I4P) /= 0_I4P) then
         ok = .false.
         return
      endif
      read(lengths, *, iostat=ios) v(1:n)
      if (ios /= 0_I4P) then
         ok = .false.
         return
      endif
   else
      do k = 1_I4P, len(spec, kind=I4P)
         if (n + 2_I4P > 64_I4P) exit
         select case (spec(k:k))
         case ('.')
            v(n + 1_I4P:n + 2_I4P) = [2.0_R8P, 5.0_R8P]
            n = n + 2_I4P
         case ('-')
            v(n + 1_I4P:n + 2_I4P) = [10.0_R8P, 10.0_R8P]
            n = n + 2_I4P
         case ('_')
            v(n + 1_I4P:n + 2_I4P) = [20.0_R8P, 10.0_R8P]
            n = n + 2_I4P
         case (' ')
            if (n == 0_I4P) then
               lead = lead + 1_I4P
            else
               v(n) = v(n) + 10.0_R8P
            endif
         case default
            ok = .false.
            return
         endselect
      enddo
      if (n == 0_I4P) return
      v(n) = v(n) + 10.0_R8P * real(lead, R8P)
   endif
   if (any(v(1:n) < 0.0_R8P)) then
      ok = .false.
      return
   endif
   lengths = ''
   do k = 1_I4P, n
      if (k > 1_I4P) lengths = lengths//','
      lengths = lengths//fixed(v(k), 4_I4P)
   enddo
   do k = 1_I4P, custom_dash_count
      if (trim(custom_dashes(k)) == lengths) then
         dt = CUSTOM_DASH_BASE + k
         return
      endif
   enddo
   if (custom_dash_count >= MAX_CUSTOM_DASHES .or. len(lengths) > len(custom_dashes(1))) then
      ok = .false.
      return
   endif
   custom_dash_count = custom_dash_count + 1_I4P
   custom_dashes(custom_dash_count) = lengths
   dt = CUSTOM_DASH_BASE + custom_dash_count
   endfunction custom_dashtype

   pure function style_name(word) result(name)
   !< Full name of the gnuplot style `word`, full or abbreviated as gnuplot 6.0 reads it (its `plotstyle_tbl`, searched
   !< in order, `$` marking the shortest abbreviation: `l`, `line`, `p`, `lp`, `i`, `st`, `fs`, `his`, `e`, `ye`,
   !< `yerrorl`, ...), or foresight's `readout`, `pie`, `gauge`, `radar`, `rose` (full words only); empty if
   !< unsupported (gnuplot styles foresight lacks included). As gnuplot, `his` is histeps and histograms need `hist`.
   !<
   !< A chain of tests, not a table: nvfortran 26.9 misreads a 2-D character parameter built by `reshape` here.
   character(len=*), intent(in)  :: word !< Style word.
   character(len=:), allocatable :: name !< Full style name.
   if (gnuplot_abbreviates(word, 'l$ines')) then
      name = 'lines'
   elseif (gnuplot_abbreviates(word, 'i$mpulses')) then
      name = 'impulses'
   elseif (gnuplot_abbreviates(word, 'p$oints')) then
      name = 'points'
   elseif (gnuplot_abbreviates(word, 'linesp$oints')) then
      name = 'linespoints'
   elseif (gnuplot_abbreviates(word, 'lp')) then
      name = 'linespoints'
   elseif (gnuplot_abbreviates(word, 'd$ots')) then
      name = 'dots'
   elseif (gnuplot_abbreviates(word, 'yerrorl$ines')) then
      name = 'yerrorlines'
   elseif (gnuplot_abbreviates(word, 'errorl$ines')) then
      name = 'yerrorlines'
   elseif (gnuplot_abbreviates(word, 'xerrorl$ines')) then
      name = 'xerrorlines'
   elseif (gnuplot_abbreviates(word, 'xyerrorl$ines')) then
      name = 'xyerrorlines'
   elseif (gnuplot_abbreviates(word, 'ye$rrorbars')) then
      name = 'yerrorbars'
   elseif (gnuplot_abbreviates(word, 'e$rrorbars')) then
      name = 'yerrorbars'
   elseif (gnuplot_abbreviates(word, 'xe$rrorbars')) then
      name = 'xerrorbars'
   elseif (gnuplot_abbreviates(word, 'xye$rrorbars')) then
      name = 'xyerrorbars'
   elseif (gnuplot_abbreviates(word, 'boxes')) then
      name = 'boxes'
   elseif (gnuplot_abbreviates(word, 'hist$ograms')) then
      name = 'histograms'
   elseif (gnuplot_abbreviates(word, 'isosurface')) then
      name = ''
   elseif (gnuplot_abbreviates(word, 'filledc$urves')) then
      name = 'filledcurves'
   elseif (gnuplot_abbreviates(word, 'boxer$rorbars')) then
      name = 'boxerrorbars'
   elseif (gnuplot_abbreviates(word, 'boxx$yerrorbars')) then
      name = 'boxxyerror'
   elseif (gnuplot_abbreviates(word, 'st$eps')) then
      name = 'steps'
   elseif (gnuplot_abbreviates(word, 'fillst$eps')) then
      name = 'fillsteps'
   elseif (gnuplot_abbreviates(word, 'fs$teps')) then
      name = 'fsteps'
   elseif (gnuplot_abbreviates(word, 'his$teps')) then
      name = 'histeps'
   elseif (gnuplot_abbreviates(word, 'vec$tors')) then
      name = 'vectors'
   elseif (gnuplot_abbreviates(word, 'arrow$s')) then
      name = 'arrows'
   elseif (gnuplot_abbreviates(word, 'fin$ancebars')) then
      name = 'financebars'
   elseif (gnuplot_abbreviates(word, 'can$dlesticks')) then
      name = 'candlesticks'
   elseif (gnuplot_abbreviates(word, 'boxplot')) then
      name = 'boxplot'
   elseif (gnuplot_abbreviates(word, 'pm$3d')) then
      name = 'pm3d'
   elseif (word == 'mask') then
      name = 'mask'
   elseif (gnuplot_abbreviates(word, 'poly$gons')) then
      name = 'polygons'
   elseif (gnuplot_abbreviates(word, 'labels')) then
      name = 'labels'
   elseif (gnuplot_abbreviates(word, 'ima$ge')) then
      name = 'image'
   elseif (gnuplot_abbreviates(word, 'rgbima$ge')) then
      name = 'rgbimage'
   elseif (gnuplot_abbreviates(word, 'rgba$lpha')) then
      name = 'rgbalpha'
   elseif (gnuplot_abbreviates(word, 'cir$cles')) then
      name = 'circles'
   elseif (gnuplot_abbreviates(word, 'sec$tors')) then
      name = 'sectors'
   elseif (gnuplot_abbreviates(word, 'sur$face')) then
      ! gnuplot's polar gridded surface (`set polar grid`), drawn by scripts as polygons
      name = 'surface'
   elseif (gnuplot_abbreviates(word, 'ell$ipses')) then
      name = 'ellipses'
   elseif (gnuplot_abbreviates(word, 'sur$face')) then
      name = ''
   elseif (gnuplot_abbreviates(word, 'parallel$axes')) then
      name = 'parallelaxes'
   elseif (gnuplot_abbreviates(word, 'spider$plot')) then
      name = 'spiderplot'
   elseif (gnuplot_abbreviates(word, 'table')) then
      name = ''
   elseif (gnuplot_abbreviates(word, 'zerror$fill')) then
      name = ''
   elseif (gnuplot_abbreviates(word, 'contourfill')) then
      name = ''
   elseif (gnuplot_abbreviates(word, 'readout')) then
      name = 'readout'
   elseif (gnuplot_abbreviates(word, 'pie')) then
      name = 'pie'
   elseif (gnuplot_abbreviates(word, 'gauge')) then
      name = 'gauge'
   elseif (gnuplot_abbreviates(word, 'radar')) then
      name = 'radar'
   elseif (gnuplot_abbreviates(word, 'rose')) then
      name = 'rose'
   else
      name = ''
   endif
   endfunction style_name

   pure function gnuplot_abbreviates(word, pattern) result(match)
   !< Whether `word` is the keyword `pattern` as gnuplot's `almost_equals` reads it: the whole of it, or, if it holds a
   !< `$`, any abbreviation at least as long as the part before the `$`.
   character(len=*), intent(in) :: word    !< Word.
   character(len=*), intent(in) :: pattern !< Keyword, `$` before its optional part.
   logical                      :: match   !< Match.
   integer                      :: dollar  !< Position of `$`.
   character(len=:), allocatable :: full   !< Keyword without `$`.

   dollar = index(pattern, '$')
   if (dollar == 0) then
      match = word == pattern
      return
   endif
   full = pattern(1:dollar - 1)//pattern(dollar + 1:)
   match = len(word) >= dollar - 1 .and. len(word) <= len(full)
   if (match) match = full(1:len(word)) == word
   endfunction gnuplot_abbreviates

   function style_with(name) result(with)
   !< Plotting style code of a gnuplot `with` keyword, full or abbreviated (see `style_name`).
   character(len=*), intent(in) :: name !< gnuplot style keyword.
   integer(I4P)                 :: with !< Plotting style code.

   select case (style_name(trim(adjustl(name))))
   case ('lines')
      with = WITH_LINES
   case ('points')
      with = WITH_POINTS
   case ('linespoints')
      with = WITH_LINESPOINTS
   case ('yerrorbars')
      with = WITH_YERRORBARS
   case ('xerrorbars')
      with = WITH_XERRORBARS
   case ('xyerrorbars')
      with = WITH_XYERRORBARS
   case ('readout')
      with = WITH_READOUT
   case ('boxes')
      with = WITH_BOXES
   case ('filledcurves')
      with = WITH_FILLEDCURVES
   case ('histograms')
      with = WITH_HISTOGRAMS
   case ('image')
      with = WITH_IMAGE
   case ('circles')
      with = WITH_CIRCLES
   case ('pie')
      with = WITH_PIE
   case ('gauge')
      with = WITH_GAUGE
   case ('radar')
      with = WITH_RADAR
   case ('rose')
      with = WITH_ROSE
   case ('impulses')
      with = WITH_IMPULSES
   case ('steps')
      with = WITH_STEPS
   case ('fsteps')
      with = WITH_FSTEPS
   case ('histeps')
      with = WITH_HISTEPS
   case ('fillsteps')
      with = WITH_FILLSTEPS
   case ('dots')
      with = WITH_DOTS
   case ('yerrorlines')
      with = WITH_YERRORLINES
   case ('xerrorlines')
      with = WITH_XERRORLINES
   case ('xyerrorlines')
      with = WITH_XYERRORLINES
   case ('boxerrorbars')
      with = WITH_BOXERRORBARS
   case ('boxxyerror')
      with = WITH_BOXXYERROR
   case ('candlesticks')
      with = WITH_CANDLESTICKS
   case ('financebars')
      with = WITH_FINANCEBARS
   case ('boxplot')
      with = WITH_BOXPLOT
   case ('vectors')
      with = WITH_VECTORS
   case ('arrows')
      with = WITH_ARROWS
   case ('ellipses')
      with = WITH_ELLIPSES
   case ('polygons')
      with = WITH_POLYGONS
   case ('pm3d')
      with = WITH_PM3D
   case ('mask')
      with = WITH_MASK
   case ('labels')
      with = WITH_LABELS
   case ('sectors')
      with = WITH_SECTORS
   case ('parallelaxes')
      with = WITH_PARALLELAXES
   case ('spiderplot')
      with = WITH_SPIDERPLOT
   case ('rgbimage', 'rgbalpha')
      error stop 'foresight: plot: RGB images are plotted by figure%rgbimage'
   case default
      error stop 'foresight: unsupported plotting style "'//trim(name)//'" (supported: '//STYLE_NAMES//')'
   endselect
   endfunction style_with

   pure function dasharray(self) result(dashes)
   !< SVG `stroke-dasharray` of the dash type, scaled by the line width; empty for solid lines.
   class(style_object), intent(in) :: self   !< Style.
   character(len=:), allocatable   :: dashes !< Dash array.

   if (self%dashtype > CUSTOM_DASH_BASE .and. self%dashtype <= CUSTOM_DASH_BASE + custom_dash_count) then
      ! a custom pattern, scaled as gnuplot's svg terminal: half the line width per unit
      dashes = custom(trim(custom_dashes(self%dashtype - CUSTOM_DASH_BASE)))
      return
   endif
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
      pure function custom(pattern) result(str)
      !< The comma separated `pattern` scaled by half the line width.
      character(len=*), intent(in)  :: pattern !< Lengths at line width 1.
      character(len=:), allocatable :: str     !< Dash array.
      real(R8P)                     :: v       !< A length.
      integer(I4P)                  :: a       !< Element start.
      integer(I4P)                  :: b       !< Element end.
      integer(I4P)                  :: ios     !< Read status.

      str = ''
      a = 1_I4P
      do while (a <= len(pattern, kind=I4P))
         b = index(pattern(a:), ',', kind=I4P)
         if (b == 0_I4P) then
            b = len(pattern, kind=I4P)
         else
            b = a + b - 2_I4P
         endif
         read(pattern(a:b), *, iostat=ios) v
         if (ios /= 0_I4P) v = 0.0_R8P
         if (len(str) > 0) str = str//','
         str = str//fixed(0.5_R8P * v * self%linewidth, 2_I4P)
         a = b + 2_I4P
      enddo
      endfunction custom

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

   lines = any(self%with == [WITH_LINES, WITH_LINESPOINTS, WITH_YERRORLINES, WITH_XERRORLINES, WITH_XYERRORLINES, &
                             WITH_STEPS, WITH_FSTEPS, WITH_HISTEPS])
   endfunction draws_lines

   elemental function draws_points(self) result(points)
   !< Whether the style draws points: every style but lines and readouts (error bars mark their points).
   class(style_object), intent(in) :: self   !< Style.
   logical                         :: points !< Points are drawn.

   points = .not. any(self%with == [WITH_LINES, WITH_READOUT, WITH_BOXES, WITH_FILLEDCURVES, WITH_HISTOGRAMS, WITH_IMAGE, &
                                    WITH_CIRCLES, WITH_PIE, WITH_GAUGE, WITH_RADAR, WITH_ROSE, WITH_IMPULSES, WITH_STEPS, &
                                    WITH_FSTEPS, WITH_HISTEPS, WITH_BOXERRORBARS, WITH_BOXXYERROR, WITH_CANDLESTICKS, &
                                    WITH_FINANCEBARS, WITH_BOXPLOT, WITH_VECTORS, WITH_ARROWS, WITH_ELLIPSES, &
                                    WITH_POLYGONS, WITH_LABELS, WITH_SECTORS, WITH_PARALLELAXES, WITH_SPIDERPLOT, &
                                    WITH_FILLSTEPS, WITH_PM3D, WITH_MASK])
   endfunction draws_points

   elemental function draws_xbars(self) result(bars)
   !< Whether the style draws horizontal error bars.
   class(style_object), intent(in) :: self !< Style.
   logical                         :: bars !< Bars are drawn.

   bars = any(self%with == [WITH_XERRORBARS, WITH_XYERRORBARS, WITH_XERRORLINES, WITH_XYERRORLINES])
   endfunction draws_xbars

   elemental function draws_ybars(self) result(bars)
   !< Whether the style draws vertical error bars.
   class(style_object), intent(in) :: self !< Style.
   logical                         :: bars !< Bars are drawn.

   bars = any(self%with == [WITH_YERRORBARS, WITH_XYERRORBARS, WITH_YERRORLINES, WITH_XYERRORLINES])
   endfunction draws_ybars

   elemental function fills(self) result(filled)
   !< Whether the style is a filled one: boxes, filledcurves, histograms, circles and the panel charts (pie, gauge,
   !< radar, rose).
   class(style_object), intent(in) :: self   !< Style.
   logical                         :: filled !< Filled style.

   filled = any(self%with == [WITH_BOXES, WITH_FILLEDCURVES, WITH_HISTOGRAMS, WITH_CIRCLES, WITH_PIE, WITH_GAUGE, &
                              WITH_RADAR, WITH_ROSE, WITH_BOXERRORBARS, WITH_BOXXYERROR, WITH_CANDLESTICKS, WITH_BOXPLOT, &
                              WITH_ELLIPSES, WITH_POLYGONS, WITH_SECTORS, WITH_FILLSTEPS])
   endfunction fills

   pure function fill_color(self) result(color)
   !< Fill color of a filled style: its own (`fc`) or the line color when solid, `none` when empty.
   class(style_object), intent(in) :: self  !< Style.
   character(len=:), allocatable   :: color !< SVG color or `none`.
   character(len=1)                :: digit !< Pattern number (a fixed length: nvfortran 26.9 sizes a deferred-length
                                            !< `color = ...//achar(i)//...` by the value of i).

   !< A pattern fill is `pattern:N:color` (see `pattern_parts`), N from 1 to PATTERNS - 1 but 3, the solid one, given
   !< as its color; pattern 0 is empty.
   character(len=:), allocatable   :: base  !< The fill's own color (`fc`), else the line color.

   color = 'none'
   base = self%color
   if (allocated(self%fill_rgb)) then
      if (len(self%fill_rgb) > 0) base = self%fill_rgb
   endif
   if (self%fill == FILL_SOLID) color = base
   if (self%fill == FILL_PATTERN) then
      select case (modulo(self%pattern, PATTERNS))
      case (0_I4P)
      case (3_I4P)
         color = base
      case default
         digit = achar(iachar('0') + modulo(self%pattern, PATTERNS))
         color = 'pattern:'//digit//':'//base
      endselect
   endif
   endfunction fill_color

   pure function stroke_color(self) result(color)
   !< Border color of a filled style: its own, the line color, or `none` without border.
   class(style_object), intent(in) :: self  !< Style.
   character(len=:), allocatable   :: color !< SVG color or `none`.

   color = 'none'
   if (.not. self%border) return
   color = self%color
   if (allocated(self%border_color)) then
      if (len(self%border_color) > 0) color = self%border_color
   endif
   endfunction stroke_color

   pure subroutine pattern_parts(fill, pattern, color)
   !< The pattern (1 to PATTERNS - 1) and color of a pattern fill `pattern:N:color` (`fill_color`); `pattern` 0 and
   !< `color` the fill itself for any other fill.
   character(len=*),              intent(in)  :: fill    !< Fill color.
   integer(I4P),                  intent(out) :: pattern !< Pattern, 0 for none.
   character(len=:), allocatable, intent(out) :: color   !< Color.

   pattern = 0_I4P
   color = fill
   if (len(fill) < 11) return
   if (fill(1:8) /= 'pattern:' .or. fill(10:10) /= ':') return
   pattern = iachar(fill(9:9)) - iachar('0')
   color = fill(11:)
   endsubroutine pattern_parts

   subroutine fill_style(words, style, bad)
   !< Update the fill of `style` from gnuplot fill style words, blank separated: `empty`, `solid [D]`,
   !< `transparent solid [D]`, `border [lc [rgb] COLOR | lt N | -1]` (COLOR quoted or not), `noborder` (abbreviated as
   !< gnuplot: `s`, `bo`, `nobo`, ...), and foresight's
   !< `segments N` (N from 1 to 1000; `segments 0` for none); `bad` is the first word not understood.
   character(len=*),              intent(in)    :: words !< Fill style words.
   type(style_object),            intent(inout) :: style !< Style updated.
   character(len=:), allocatable, intent(out)   :: bad   !< First word not understood, empty if none.
   character(len=:), allocatable                :: list(:) !< Words.
   character(len=:), allocatable                :: full    !< Words, written in full.
   real(R8P)                                    :: v     !< Density.
   logical                                      :: ok    !< Number read.
   integer(I4P)                                 :: k     !< Word counter.

   bad = ''
   list = split(words)
   ! gnuplot's abbreviations, the words written in full: e$mpty, s$olid, p$attern, tr$ansparent, bo$rder, nobo$rder
   full = ''
   do k = 1_I4P, size(list, kind=I4P)
      if (gnuplot_abbreviates(trim(list(k)), 'e$mpty')) then
         full = full//' empty'
      elseif (gnuplot_abbreviates(trim(list(k)), 's$olid')) then
         full = full//' solid'
      elseif (gnuplot_abbreviates(trim(list(k)), 'p$attern')) then
         full = full//' pattern'
      elseif (gnuplot_abbreviates(trim(list(k)), 'tr$ansparent')) then
         full = full//' transparent'
      elseif (gnuplot_abbreviates(trim(list(k)), 'bo$rder')) then
         full = full//' border'
      elseif (gnuplot_abbreviates(trim(list(k)), 'nobo$rder')) then
         full = full//' noborder'
      else
         full = full//' '//trim(list(k))
      endif
   enddo
   list = split(full)
   k = 1_I4P
   do while (k <= size(list, kind=I4P))
      select case (trim(list(k)))
      case ('empty')
         style%fill = FILL_EMPTY
      case ('transparent')
      case ('solid')
         style%fill = FILL_SOLID
         style%density = 1.0_R8P
         if (k < size(list, kind=I4P)) then
            call real_from_decimal(trim(list(k + 1_I4P)), v, ok)
            if (ok) then
               if (v < 0.0_R8P .or. v > 1.0_R8P) then
                  bad = trim(list(k + 1_I4P))//' (the density is between 0 and 1)'
                  return
               endif
               style%density = v
               k = k + 1_I4P
            endif
         endif
      case ('border')
         style%border = .true.
         style%border_color = ''
         if (k < size(list, kind=I4P)) then
            ! gnuplot `border {lt} N`: a bare number is a linetype too
            call real_from_decimal(trim(list(k + 1_I4P)), v, ok)
            if (ok .and. trim(list(k + 1_I4P)) /= '-1') then
               k = k + 1_I4P
               if (v < 0.0_R8P) then
                  style%border_color = 'black'
               else
                  style%border_color = default_color(max(1_I4P, nint(v, I4P)))
               endif
               k = k + 1_I4P
               cycle
            endif
            select case (trim(list(k + 1_I4P)))
            case ('-1')
               style%border_color = 'black'
               k = k + 1_I4P
            case ('lt', 'linetype')
               ! the color of linetype N, -1 black (gnuplot's `border lt N`)
               k = k + 1_I4P
               ok = .false.
               if (k < size(list, kind=I4P)) call real_from_decimal(trim(list(k + 1_I4P)), v, ok)
               if (.not. ok) then
                  bad = 'border lt (a linetype number is expected)'
                  return
               endif
               k = k + 1_I4P
               if (v < 0.0_R8P) then
                  style%border_color = 'black'
               else
                  style%border_color = default_color(max(1_I4P, nint(v, I4P)))
               endif
            case ('lc', 'linecolor')
               k = k + 1_I4P
               if (k < size(list, kind=I4P)) then
                  if (trim(list(k + 1_I4P)) == 'rgb' .or. trim(list(k + 1_I4P)) == 'rgbcolor') k = k + 1_I4P
               endif
               if (k >= size(list, kind=I4P)) then
                  bad = 'border lc (a color is expected)'
                  return
               endif
               k = k + 1_I4P
               style%border_color = unquoted(trim(list(k)))
               ! gnuplot's special colors: the background (white, the theme's page), black
               select case (style%border_color)
               case ('bgnd', 'background')
                  style%border_color = 'white'
               case ('black')
                  style%border_color = 'black'
               endselect
            endselect
         endif
      case ('noborder')
         style%border = .false.
      case ('segments')
         ok = .false.
         if (k < size(list, kind=I4P)) call real_from_decimal(trim(list(k + 1_I4P)), v, ok)
         if (.not. ok) then
            bad = 'segments (a number of cells is expected)'
            return
         endif
         if (v < 0.0_R8P .or. v > 1000.0_R8P .or. v /= aint(v)) then
            bad = trim(list(k + 1_I4P))//' (segments takes a whole number of cells, 0 to 1000)'
            return
         endif
         style%segments = int(v, I4P)
         k = k + 1_I4P
      case ('pattern')
         style%fill = FILL_PATTERN
         style%density = 1.0_R8P
         style%pattern = 0_I4P
         if (k < size(list, kind=I4P)) then
            call real_from_decimal(trim(list(k + 1_I4P)), v, ok)
            if (ok) then
               if (v < 0.0_R8P .or. v /= aint(v) .or. v > 1000.0_R8P) then
                  bad = trim(list(k + 1_I4P))//' (the pattern is a whole number >= 0)'
                  return
               endif
               style%pattern = int(v, I4P)
               k = k + 1_I4P
            endif
         endif
      case default
         bad = trim(list(k))
         return
      endselect
      k = k + 1_I4P
   enddo
   contains
      pure function unquoted(word) result(text)
      !< `word` without the quotes around it, if any: `"black"` and `'black'` are `black`.
      character(len=*), intent(in)  :: word !< Word.
      character(len=:), allocatable :: text !< Text.

      text = word
      if (len(word) >= 2) then
         if ((word(1:1) == '"' .or. word(1:1) == "'") .and. word(len(word):len(word)) == word(1:1)) &
            text = word(2:len(word) - 1)
      endif
      endfunction unquoted

      pure function split(text) result(parts)
      !< Blank separated words of `text`.
      character(len=*), intent(in)  :: text     !< Text.
      character(len=:), allocatable :: parts(:) !< Words.
      character(len=:), allocatable :: words(:) !< Words, the first `n` (a temporary: nvfortran 26.9 corrupts
                                                !< `parts = parts(1:n)`).
      integer(I4P)                  :: i        !< Character counter.
      integer(I4P)                  :: start    !< Word start.
      integer(I4P)                  :: n        !< Words.

      n = 0_I4P
      allocate(character(len=max(1, len(text))) :: words(len(text) / 2 + 1))
      i = 1_I4P
      do while (i <= len(text))
         if (text(i:i) == ' ') then
            i = i + 1_I4P
            cycle
         endif
         start = i
         do while (i <= len(text))
            if (text(i:i) == ' ') exit
            i = i + 1_I4P
         enddo
         n = n + 1_I4P
         words(n) = text(start:i - 1_I4P)
      enddo
      parts = words(1:n)
      endfunction split
   endsubroutine fill_style

   elemental function point_diameter(self) result(diameter)
   !< Point size [px]: the round dot diameter, or the width of a point type shape (gnuplot svg scale).
   class(style_object), intent(in) :: self     !< Style.
   real(R8P)                       :: diameter !< Point size [px].

   if (self%pointtype >= 0_I4P) then
      diameter = MARKER_AT_UNIT_SIZE * self%pointsize
   else
      diameter = DIAMETER_AT_UNIT_SIZE * self%pointsize
   endif
   endfunction point_diameter
endmodule foresight_style
