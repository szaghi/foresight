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
use foresight_format, only : fixed, real_from_decimal

implicit none
private
public :: default_color
public :: fill_style
public :: style_object
public :: style_name
public :: style_with
public :: WITH_BOXES, WITH_CIRCLES, WITH_FILLEDCURVES, WITH_HISTOGRAMS, WITH_IMAGE, WITH_LINES, WITH_PIE, &
          WITH_LINESPOINTS, WITH_POINTS, WITH_READOUT, WITH_GAUGE, WITH_RADAR, WITH_ROSE, &
          WITH_XERRORBARS, WITH_XYERRORBARS, WITH_YERRORBARS, WITH_IMPULSES, WITH_STEPS, WITH_FSTEPS, WITH_HISTEPS, &
          WITH_DOTS, WITH_YERRORLINES, WITH_XERRORLINES, WITH_XYERRORLINES, WITH_BOXERRORBARS, WITH_BOXXYERROR, &
          WITH_CANDLESTICKS, WITH_FINANCEBARS, WITH_BOXPLOT, WITH_VECTORS, WITH_ARROWS, WITH_ELLIPSES, WITH_POLYGONS, &
          WITH_LABELS, WITH_SECTORS
public :: STYLE_NAMES
public :: FILL_EMPTY, FILL_SOLID

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
character(len=*), parameter :: STYLE_NAMES = 'lines, points, linespoints, impulses, steps, fsteps, histeps, dots, '// &
                                             'yerrorbars, xerrorbars, xyerrorbars, yerrorlines, xerrorlines, '// &
                                             'xyerrorlines, boxes, boxerrorbars, boxxyerror, candlesticks, '// &
                                             'financebars, boxplot, vectors, arrows, ellipses, polygons, labels, '// &
                                             'sectors, filledcurves, histograms, image, circles, pie, '// &
                                             'gauge, radar, rose, readout' !< Supported style names.
integer(I4P), parameter :: FILL_EMPTY       = 0_I4P !< gnuplot `set style fill empty`: no fill.
integer(I4P), parameter :: FILL_SOLID       = 1_I4P !< gnuplot `set style fill solid`.

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
   pure function default_color(index) result(color)
   !< Default color of the `index`-th series, cycling the gnuplot 5 palette.
   integer(I4P), intent(in)      :: index !< Series index, from 1.
   character(len=:), allocatable :: color !< SVG color.

   color = PALETTE(modulo(index - 1_I4P, size(PALETTE, kind=I4P)) + 1_I4P)
   endfunction default_color

   pure function style_name(word) result(name)
   !< Full name of the gnuplot style `word`, full or abbreviated as gnuplot accepts it (`l`, `p`, `lp`, `i`, `st`, `fs`,
   !< `his`, `d`, `yerr`, `yerrorl`, ...), or foresight's `readout`, `pie`, `gauge`, `radar`, `rose` (full words only);
   !< empty if unsupported. As gnuplot, `his` is histeps and histograms need `hist`.
   character(len=*), intent(in)  :: word !< Style word.
   character(len=:), allocatable :: name !< Full style name.

   select case (word)
   case ('l', 'lines')
      name = 'lines'
   case ('p', 'points')
      name = 'points'
   case ('lp', 'linespoints')
      name = 'linespoints'
   case ('yerr', 'yerrorbars')
      name = 'yerrorbars'
   case ('xerr', 'xerrorbars')
      name = 'xerrorbars'
   case ('xyerr', 'xyerrorbars')
      name = 'xyerrorbars'
   case ('his', 'histe', 'histep', 'histeps')
      name = 'histeps'
   case ('hist', 'histo', 'histog', 'histogr', 'histogra', 'histogram', 'histograms')
      name = 'histograms'
   case ('filledc', 'filledcu', 'filledcur', 'filledcurv', 'filledcurve', 'filledcurves')
      name = 'filledcurves'
   case ('ima', 'imag', 'image')
      name = 'image'
   case ('cir', 'circ', 'circl', 'circle', 'circles')
      name = 'circles'
   case ('boxes', 'boxplot', 'arrows', 'labels', 'readout', 'pie', 'gauge', 'radar', 'rose')
      name = word
   case default
      name = ''
      if (abbreviates(word, 'impulses', 1)) name = 'impulses'
      if (abbreviates(word, 'steps', 2)) name = 'steps'
      if (abbreviates(word, 'fsteps', 2)) name = 'fsteps'
      if (abbreviates(word, 'dots', 1)) name = 'dots'
      if (abbreviates(word, 'yerrorlines', 7)) name = 'yerrorlines'
      if (abbreviates(word, 'xerrorlines', 7)) name = 'xerrorlines'
      if (abbreviates(word, 'xyerrorlines', 8)) name = 'xyerrorlines'
      if (abbreviates(word, 'boxerrorbars', 5)) name = 'boxerrorbars'
      if (abbreviates(word, 'boxxyerror', 4)) name = 'boxxyerror'
      if (abbreviates(word, 'candlesticks', 3)) name = 'candlesticks'
      if (abbreviates(word, 'financebars', 3)) name = 'financebars'
      if (abbreviates(word, 'vectors', 3)) name = 'vectors'
      if (abbreviates(word, 'ellipses', 3)) name = 'ellipses'
      if (abbreviates(word, 'polygons', 4)) name = 'polygons'
      if (abbreviates(word, 'sectors', 3)) name = 'sectors'
   endselect
   contains
      pure function abbreviates(w, full, minimum) result(match)
      !< Whether `w` abbreviates `full` with at least `minimum` characters.
      character(len=*), intent(in) :: w       !< Word.
      character(len=*), intent(in) :: full    !< Full name.
      integer,          intent(in) :: minimum !< Shortest abbreviation.
      logical                      :: match   !< Match.

      match = len(w) >= minimum .and. len(w) <= len(full)
      if (match) match = full(1:len(w)) == w
      endfunction abbreviates
   endfunction style_name

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
   case ('labels')
      with = WITH_LABELS
   case ('sectors')
      with = WITH_SECTORS
   case default
      error stop 'foresight: unsupported plotting style "'//trim(name)//'" (supported: '//STYLE_NAMES//')'
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
                                    WITH_POLYGONS, WITH_LABELS, WITH_SECTORS])
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
                              WITH_ELLIPSES, WITH_POLYGONS, WITH_SECTORS])
   endfunction fills

   pure function fill_color(self) result(color)
   !< Fill color of a filled style: the line color when solid, `none` when empty.
   class(style_object), intent(in) :: self  !< Style.
   character(len=:), allocatable   :: color !< SVG color or `none`.

   color = 'none'
   if (self%fill == FILL_SOLID) color = self%color
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

   subroutine fill_style(words, style, bad)
   !< Update the fill of `style` from gnuplot fill style words, blank separated: `empty`, `solid [D]`,
   !< `transparent solid [D]`, `border [lc [rgb] COLOR | -1]` (COLOR quoted or not), `noborder`, and foresight's
   !< `segments N` (N from 1 to 1000; `segments 0` for none); `bad` is the first word not understood.
   character(len=*),              intent(in)    :: words !< Fill style words.
   type(style_object),            intent(inout) :: style !< Style updated.
   character(len=:), allocatable, intent(out)   :: bad   !< First word not understood, empty if none.
   character(len=:), allocatable                :: list(:) !< Words.
   real(R8P)                                    :: v     !< Density.
   logical                                      :: ok    !< Number read.
   integer(I4P)                                 :: k     !< Word counter.

   bad = ''
   list = split(words)
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
            select case (trim(list(k + 1_I4P)))
            case ('-1')
               style%border_color = 'black'
               k = k + 1_I4P
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
         bad = 'pattern (fill patterns are not supported)'
         return
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
      integer(I4P)                  :: i        !< Character counter.
      integer(I4P)                  :: start    !< Word start.
      integer(I4P)                  :: n        !< Words.

      n = 0_I4P
      allocate(character(len=max(1, len(text))) :: parts(len(text) / 2 + 1))
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
         parts(n) = text(start:i - 1_I4P)
      enddo
      parts = parts(1:n)
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
