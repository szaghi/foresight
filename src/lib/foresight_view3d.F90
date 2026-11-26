!< foresight_view3d, the view of the 3D panels (gnuplot `splot`): its settings, the projection and the map layout.
module foresight_view3d
!< foresight_view3d, the view of the 3D panels (gnuplot `splot`): its settings, the projection and the map layout.
!<
!< The settings follow gnuplot 6.0's `set view`, `set xyplane` (`set ticslevel`), `set surface` and `set isosamples`;
!< their defaults are gnuplot's (`set view 60, 30, 1, 1`, `set xyplane relative 0.5`).
use penf, only : I4P, I8P, R4P, R8P

implicit none
private
public :: map_geometry
public :: map_layout
public :: view3d_frame
public :: view3d_lin
public :: view3d_object
public :: view3d_page
public :: view3d_setup
public :: view3d_xyz

real(R8P), parameter :: PI_R8 = 4.0_R8P * atan(1.0_R8P) !< Pi.

type :: view3d_object
   !< View of a 3D panel.
   real(R8P)    :: rot_x = 60.0_R8P   !< Rotation about the x axis [deg] (gnuplot `set view ROT_X`).
   real(R8P)    :: rot_z = 30.0_R8P   !< Rotation about the z axis [deg] (`set view ,ROT_Z`).
   real(R8P)    :: scale = 1.0_R8P    !< Scale of the whole plot (`set view ,,SCALE`).
   real(R8P)    :: zscale = 1.0_R8P   !< Scale of the z axis (`set view ,,,SCALE_Z`).
   logical      :: map = .false.      !< Seen from above, as a map (gnuplot `set view map`).
   real(R8P)    :: map_scale = 1.0_R8P !< Scale of the map view (`set view map scale S`).
   integer(I4P) :: equal = 0_I4P      !< Equal axes: 0 none, 1 x and y (`set view equal xy`), 2 x, y and z (`xyz`).
   real(R8P)    :: azimuth = 0.0_R8P  !< Rotation about the line of sight [deg] (`set view azimuth A`).
   logical      :: xyplane_at = .false. !< The base plane at the height `xyplane_z` (`set xyplane at Z`), else
                                        !< relative to the z range (`set xyplane relative F`, `set ticslevel F`).
   real(R8P)    :: ticslevel = 0.5_R8P !< Base plane below the z range, a fraction of it.
   real(R8P)    :: xyplane_z = 0.0_R8P !< Base plane height.
   logical      :: surface = .true.   !< Surfaces drawn (`set surface`; `unset surface` leaves the contours only).
   logical      :: zzeroaxis = .false. !< The z zero axis (`set zzeroaxis`).
   logical      :: grid_vertical = .false. !< Vertical grid lines on the back walls at the x and y ticks (`set grid
                                           !< vertical`).
   logical      :: grid_z = .false. !< Grid lines at the z ticks on the back walls (`set grid ztics`).
   logical      :: hidden3d = .false. !< Hidden lines removed (`set hidden3d`): the surfaces drawn opaque, back to
                                      !< front (a painter's algorithm, not gnuplot's hidden3d.c).
   integer(I4P) :: hidden_offset = 1_I4P !< Linetype of the underside of a surface after its own (`set hidden3d
                                         !< offset N`; 0 the same, `nooffset`).
endtype view3d_object

type :: map_geometry
   !< Geometry of a map view, gnuplot 6.0's (graph3d.c, svg terminal metrics): the plot area and the tick, label and
   !< title places [px, y down].
   real(R8P) :: area(4) = 0.0_R8P !< Plot area: left, right, top, bottom.
   real(R8P) :: xtic = 0.0_R8P   !< Length of the x ticks at scale 1 (gnuplot's v_tic along the projected y).
   real(R8P) :: ytic = 0.0_R8P   !< Length of the y ticks at scale 1 (h_tic along the projected x).
   real(R8P) :: xdrop = 0.0_R8P  !< Anchor of the x tick labels below the axis (v_char along the projected y).
   real(R8P) :: ygap = 0.0_R8P   !< Anchor of the y tick labels left of the axis (h_char along the projected x).
   real(R8P) :: vchar = 0.0_R8P  !< gnuplot's character height.
   real(R8P) :: hchar = 0.0_R8P  !< gnuplot's character width.
   real(R8P) :: vtic = 0.0_R8P   !< gnuplot's tick length.
   real(R8P) :: shift = 0.0_R8P  !< Baseline of a text below its anchor (gnuplot's svg vertical centring).
   real(R8P) :: title_y = 0.0_R8P !< Anchor of the title, its first line (before the baseline shift).
endtype map_geometry


type :: view3d_frame
   !< A 3D view as gnuplot 6.0's do_3dplot sets it up (graph3d.c boundary3d, util3d.c): the transform of the
   !< normalized object space (-1..1 on each axis) to the view, the plot bounds and scales in the svg terminal units
   !< (1/100 px, y up), the axis ends, the base plane and the corners of the box where the axes and ticks lie.
   real(R8P) :: mat(4,4) = 0.0_R8P       !< Transform (row vectors, gnuplot's trans_mat).
   real(R8P) :: bounds(4) = 0.0_R8P      !< Plot bounds: left, right, bottom, top (gnuplot's page_bounds) [units].
   real(R8P) :: xspan(2) = 0.0_R8P       !< Left and right of the projected base plane (plot_bounds after the
                                         !< corners, the title's) [units].
   real(R8P) :: xmiddle = 0.0_R8P        !< Middle of the bounds, horizontally [units].
   real(R8P) :: ymiddle = 0.0_R8P        !< Middle of the bounds, vertically [units].
   real(R8P) :: xscaler = 1.0_R8P        !< Horizontal scale [units].
   real(R8P) :: yscaler = 1.0_R8P        !< Vertical scale [units].
   real(R8P) :: xyscaler = 1.0_R8P       !< Their geometric mean.
   real(R8P) :: height = 0.0_R8P         !< Page height [px].
   real(R8P) :: vchar = 0.0_R8P          !< gnuplot's character height [units].
   real(R8P) :: hchar = 0.0_R8P          !< gnuplot's character width [units].
   real(R8P) :: vtic = 0.0_R8P           !< gnuplot's vertical tick length [units].
   real(R8P) :: htic = 0.0_R8P           !< gnuplot's horizontal tick length [units].
   real(R8P) :: shift = 0.0_R8P          !< Baseline of a text below its anchor (svg vertical centring) [px].
   real(R8P) :: x(2) = 0.0_R8P           !< x axis ends (gnuplot's min and max), log10 on a log axis.
   real(R8P) :: y(2) = 0.0_R8P           !< y axis ends.
   real(R8P) :: z(2) = 0.0_R8P           !< z axis ends.
   logical   :: log(3) = .false.         !< Log axes x, y, z: values mapped by their log10.
   real(R8P) :: scale3d(3) = 1.0_R8P     !< gnuplot's xscale3d, yscale3d, zscale3d.
   real(R8P) :: center3d(3) = 0.0_R8P    !< gnuplot's xcenter3d, ycenter3d, zcenter3d.
   real(R8P) :: floor_z = 0.0_R8P        !< Bottom of the box (log10 on a log axis).
   real(R8P) :: ceiling_z = 0.0_R8P      !< Top of the box.
   real(R8P) :: base_z = 0.0_R8P         !< Height of the base plane.
   real(R8P) :: zaxis_xy(2) = 0.0_R8P    !< Corner of the z axis (gnuplot's zaxis_x, zaxis_y), axis values.
   real(R8P) :: back_xy(2) = 0.0_R8P     !< Back corner.
   real(R8P) :: right_xy(2) = 0.0_R8P    !< Right corner.
   real(R8P) :: front_xy(2) = 0.0_R8P    !< Front corner.
   real(R8P) :: xaxis_y = 0.0_R8P        !< y where the x axis lies.
   real(R8P) :: yaxis_x = 0.0_R8P        !< x where the y axis lies.
   logical   :: xz_plane = .false.       !< Seen edge-on along y (rot_x 90 or 270, rot_z 0 or 180).
   logical   :: yz_plane = .false.       !< Seen edge-on along x (rot_x 90 or 270, rot_z 90 or 270).
   real(R8P) :: title(2) = 0.0_R8P       !< Title anchor (gnuplot's title_x, title_y) [units].
endtype view3d_frame

contains
   pure function map_layout(view, box, page, font_size, title_lines, colorbox, x2label, y2label, x2tics, xmirror_out, &
                            margins, screen, ratio, xspan, yspan) result(geo)
   !< The map view of a panel in the `box` (left, top, width, height [px]) of a `page` (width, height [px]), as gnuplot
   !< 6.0's boundary3d and do_3dplot place it, in their integer terminal units (1/100 px of the svg terminal, its font
   !< metrics: v_char 1.5, h_char 0.7 font sizes, the ticks half a character height): the plot bounds within the
   !< margins (`margins` in characters or, `screen`, page fractions; negative for the default ones; left, right, top,
   !< bottom), narrowed for the color box (a tenth) and the x2 and y2 labels; their middle; the scales 4/7 of them
   !< (unless both margins of a side are on the screen); `set size ratio` (`ratio`, -1 equal units over the `xspan` and
   !< `yspan` ranges) or `set view equal xy`; the area the projection of the x and y ranges, `set view map scale` times
   !< 1.425 of the scales.
   type(view3d_object), intent(in) :: view        !< View.
   real(R8P),           intent(in) :: box(:)      !< Panel box: left, top, width, height [px].
   real(R8P),           intent(in) :: page(2)     !< Page width and height [px].
   real(R8P),           intent(in) :: font_size   !< Font size [px].
   integer(I4P),        intent(in) :: title_lines !< gnuplot's title lines (0 without a title).
   logical,             intent(in) :: colorbox    !< A color box at the right.
   logical,             intent(in) :: x2label     !< An x2 label.
   logical,             intent(in) :: y2label     !< A y2 label.
   logical,             intent(in) :: x2tics      !< x2 tick labels.
   real(R8P),           intent(in) :: xmirror_out !< Length of the mirrored x ticks above the border, outward [scale].
   real(R8P),           intent(in) :: margins(4)  !< Left, right, top, bottom margins, negative for the default.
   logical,             intent(in) :: screen(4)   !< The margin a page fraction (`at screen`), else characters.
   real(R8P),           intent(in) :: ratio       !< `set size ratio`, 0 for none, negative for units.
   real(R8P),           intent(in) :: xspan       !< x range (end minus start).
   real(R8P),           intent(in) :: yspan       !< y range.
   type(map_geometry)              :: geo         !< Geometry.
   integer(I8P)                    :: vchar, hchar, vtic, htic !< gnuplot's metrics.
   integer(I8P)                    :: xmax, ymax  !< Page size.
   integer(I8P)                    :: xleft, xright, ybot, ytop !< Plot bounds.
   integer(I8P)                    :: xmiddle, ymiddle !< Their middle.
   integer(I8P)                    :: xscaler, yscaler !< Scales.
   real(R8P)                       :: xyscaler    !< Their geometric mean.
   real(R8P)                       :: xoffset, yoffset, xsize, ysize !< Panel origin and size [page fractions].
   real(R8P)                       :: half        !< Half the surface scale.
   real(R8P)                       :: aspect      !< Aspect ratio.
   real(R8P)                       :: unit        !< A terminal unit [px].

   unit = 0.01_R8P
   vchar = int(font_size * 0.90_R8P * 100.0_R8P + font_size * 0.25_R8P * 100.0_R8P + font_size * 0.35_R8P * 100.0_R8P, &
               I8P)
   hchar = int(font_size * 0.70_R8P * 100.0_R8P, I8P)
   vtic = vchar / 2_I8P
   htic = vchar / 2_I8P
   xmax = int(page(1) * 100.0_R8P, I8P)
   ymax = int(page(2) * 100.0_R8P, I8P)
   xoffset = box(1) / page(1)
   yoffset = (page(2) - box(2) - box(4)) / page(2)
   xsize = box(3) / page(1)
   ysize = box(4) / page(2)
   if (screen(1)) then
      xleft = int(margins(1) * real(xmax, R8P) + 0.5_R8P, I8P)
   elseif (margins(1) >= 0.0_R8P) then
      xleft = int(margins(1) * real(hchar, R8P) + 0.5_R8P, I8P)
   else
      xleft = hchar * 2_I8P + htic
   endif
   if (screen(2)) then
      xright = int(margins(2) * real(xmax, R8P) + 0.5_R8P, I8P)
   elseif (margins(2) >= 0.0_R8P) then
      xright = int(xsize * real(xmax, R8P) - (margins(2) * real(hchar, R8P) + 0.5_R8P), I8P)
   else
      xright = int(xsize * real(xmax, R8P) - real(hchar * 2_I8P, R8P) - real(htic, R8P), I8P)
   endif
   if (screen(4)) then
      ybot = int(margins(4) * real(ymax, R8P) + 0.5_R8P, I8P)
   elseif (margins(4) >= 0.0_R8P) then
      ybot = int(real(vchar, R8P) * margins(4), I8P)
   else
      ybot = int(real(vchar, R8P) * 2.5_R8P + 1.0_R8P, I8P)
   endif
   if (screen(3)) then
      ytop = int(margins(3) * real(ymax, R8P) + 0.5_R8P, I8P)
   elseif (margins(3) >= 0.0_R8P) then
      ytop = int(ysize * real(ymax, R8P) - real(vchar, R8P) * (real(title_lines, R8P) + margins(3)) - 1.0_R8P, I8P)
   else
      ytop = int(ysize * real(ymax, R8P) - real(vchar, R8P) * (real(title_lines, R8P) + 1.5_R8P) - 1.0_R8P, I8P)
   endif
   if (colorbox .and. .not. screen(2)) xright = int(real(xright, R8P) - 0.1_R8P * real(xright - xleft, R8P), I8P)
   if (x2label) ytop = int(real(ytop, R8P) - 1.5_R8P * real(vchar, R8P), I8P)
   if (y2label) xright = int(real(xright, R8P) - 2.5_R8P * real(hchar, R8P), I8P)
   if (.not. screen(1)) xleft = int(real(xleft, R8P) + real(xmax, R8P) * xoffset, I8P)
   if (.not. screen(2)) xright = int(real(xright, R8P) + real(xmax, R8P) * xoffset, I8P)
   if (.not. screen(3)) ytop = int(real(ytop, R8P) + real(ymax, R8P) * yoffset, I8P)
   if (.not. screen(4)) ybot = int(real(ybot, R8P) + real(ymax, R8P) * yoffset, I8P)
   xmiddle = (xright + xleft) / 2_I8P
   ymiddle = (ytop + ybot) / 2_I8P
   xscaler = ((xright - xleft) * 4_I8P) / 7_I8P
   yscaler = ((ytop - ybot) * 4_I8P) / 7_I8P
   ! the surface scale is gnuplot's float
   half = real(real(1.425_R8P * real(real(view%map_scale, R4P), R8P), R4P), R8P) / 2.0_R8P
   if (screen(3) .and. screen(4)) yscaler = int(real(ytop - ybot, R8P) / (2.0_R8P * half), I8P)
   if (screen(1) .and. screen(2)) xscaler = int(real(xright - xleft, R8P) / (2.0_R8P * half), I8P)
   if (yscaler == 0_I8P) yscaler = 1_I8P
   if (xscaler == 0_I8P) xscaler = 1_I8P
   ! `set size ratio|square` and `set view equal xy` (gnuplot: the 2D aspect also rules the map)
   if (ratio /= 0.0_R8P .or. view%equal > 0_I4P) then
      aspect = ratio
      if (aspect == 0.0_R8P) aspect = -1.0_R8P
      if (aspect < 0.0_R8P .and. xspan /= 0.0_R8P) aspect = -aspect * abs(yspan / xspan)
      if (aspect >= 0.01_R8P .and. aspect <= 100.0_R8P) then
         if (real(yscaler, R8P) / real(xscaler, R8P) > aspect) then
            yscaler = int(real(xscaler, R8P) * aspect, I8P)
         else
            xscaler = int(real(yscaler, R8P) / aspect, I8P)
         endif
      endif
   endif
   xyscaler = sqrt(real(xscaler, R8P) * real(yscaler, R8P))
   ! the projected corners of the x and y ranges (TERMCOORD: truncated toward zero)
   geo%area(1) = real(xmiddle + int(-half * real(xscaler, R8P), I8P), R8P) * unit
   geo%area(2) = real(xmiddle + int(half * real(xscaler, R8P), I8P), R8P) * unit
   geo%area(3) = page(2) - real(ymiddle + int(half * real(yscaler, R8P), I8P), R8P) * unit
   geo%area(4) = page(2) - real(ymiddle + int(-half * real(yscaler, R8P), I8P), R8P) * unit
   ! the tick vectors are the unit projected directions times gnuplot's lengths (xtick_callback, ytick_callback)
   geo%xtic = 2.0_R8P * half * real(vtic, R8P) * real(yscaler, R8P) / xyscaler * unit
   geo%ytic = 2.0_R8P * half * real(htic, R8P) * real(xscaler, R8P) / xyscaler * unit
   geo%xdrop = 2.0_R8P * half * real(vchar, R8P) * real(yscaler, R8P) / xyscaler * unit
   geo%ygap = 2.0_R8P * half * real(hchar, R8P) * real(xscaler, R8P) / xyscaler * unit
   geo%vchar = real(vchar, R8P) * unit
   geo%hchar = real(hchar, R8P) * unit
   geo%vtic = real(vtic, R8P) * unit
   ! the svg terminal centres a text line on its anchor: the baseline (ascent - descent) / 2 below
   geo%shift = (font_size * 0.90_R8P - font_size * 0.25_R8P) / 2.0_R8P
   ! the title (do_3dplot): its lines (and half one) above the top, over upward mirrored ticks, the x2 tick labels and
   ! label
   geo%title_y = real(ymiddle + int(half * real(yscaler, R8P), I8P), R8P) + max(0.0_R8P, xmirror_out) * &
                 real(vtic, R8P) + (real(title_lines, R8P) + 0.5_R8P) * real(vchar, R8P)
   if (x2tics) geo%title_y = geo%title_y + 0.5_R8P * real(vchar, R8P)
   if (x2label) geo%title_y = geo%title_y + real(vchar, R8P)
   geo%title_y = page(2) - real(int(geo%title_y, I8P), R8P) * unit
   endfunction map_layout

   pure function view3d_setup(view, box, page, font_size, title_lines, xr, yr, zr, logs, base_drawn, margins, screen, &
                              key_side, key_below) result(f)
   !< The 3D view of a panel in the `box` (left, top, width, height [px]) of a `page` (width, height [px]), as gnuplot
   !< 6.0's do_3dplot and boundary3d set it up in the svg terminal units (font metrics as map_layout's): the plot bounds
   !< within the default margins (characters or `at screen` ones on the left, screen ones elsewhere), a key outside at
   !< the right or left (`key_side`, its width [units], negative at the left) or below (`key_below`, its height),
   !< squared by `set view equal`; the scales
   !< 4/7 of them; the transform rot_z, rot_x, half the view scale, then the azimuth; the base plane (`set xyplane`)
   !< and the box (`base_drawn`: x or y ticks or a base border draw it, so the box reaches it); the axis scales,
   !< `set view equal xy|xyz`; the corners of the axes by the quadrant of rot_z (and rot_x).
   type(view3d_object), intent(in) :: view        !< View.
   real(R8P),           intent(in) :: box(4)      !< Panel box: left, top, width, height [px].
   real(R8P),           intent(in) :: page(2)     !< Page width and height [px].
   real(R8P),           intent(in) :: font_size   !< Font size [px].
   integer(I4P),        intent(in) :: title_lines !< gnuplot's title lines (0 without a title).
   real(R8P),           intent(in) :: xr(2)       !< x axis ends (start, end).
   real(R8P),           intent(in) :: yr(2)       !< y axis ends.
   real(R8P),           intent(in) :: zr(2)       !< z axis ends.
   logical,             intent(in) :: logs(3)     !< Log axes x, y, z.
   logical,             intent(in) :: base_drawn  !< The base plane drawn: x or y ticks, or a base border.
   real(R8P),           intent(in) :: margins(4)  !< Left, right, top, bottom margins, negative for the default.
   logical,             intent(in) :: screen(4)   !< The margin a page fraction (`at screen`), else characters.
   real(R8P),           intent(in) :: key_side    !< Width of a key outside [units], at the right (negative: left).
   real(R8P),           intent(in) :: key_below   !< Height of a key below the plot [units] (gnuplot's bottom margin key).
   type(view3d_frame)              :: f           !< The view.
   real(R8P)                       :: m(4,4)      !< A transform.
   real(R8P)                       :: xmax, ymax  !< Page size [units].
   real(R8P)                       :: xoffset, yoffset, xsize, ysize !< Panel origin and size [page fractions].
   real(R8P)                       :: zmin, zmax  !< The z axis ends.
   real(R8P)                       :: base1       !< Base plane height.
   real(R8P)                       :: surface     !< The view scale (gnuplot's surface_scale, a float).
   real(R8P)                       :: zcorner(2)  !< Projected corners, a scratch.
   integer(I8P)                    :: w, h        !< Plot bounds size, squared.
   integer(I4P)                    :: quadrant    !< Quadrant of the rotation.
   real(R8P)                       :: v(3)        !< A projected vertex.
   real(R8P)                       :: xl, xb, xrr !< Projected base corners [units].

   f%vchar = real(int(font_size * 0.90_R8P * 100.0_R8P + font_size * 0.25_R8P * 100.0_R8P + &
                      font_size * 0.35_R8P * 100.0_R8P, I8P), R8P)
   f%hchar = real(int(font_size * 0.70_R8P * 100.0_R8P, I8P), R8P)
   f%vtic = real(int(f%vchar, I8P) / 2_I8P, R8P)
   f%htic = f%vtic
   f%shift = (font_size * 0.90_R8P - font_size * 0.25_R8P) / 2.0_R8P
   f%height = page(2)
   xmax = real(int(page(1) * 100.0_R8P, I8P), R8P)
   ymax = real(int(page(2) * 100.0_R8P, I8P), R8P)
   xoffset = box(1) / page(1)
   yoffset = (page(2) - box(2) - box(4)) / page(2)
   xsize = box(3) / page(1)
   ysize = box(4) / page(2)
   ! boundary3d: the plot bounds (integers)
   associate(xleft => f%bounds(1), xright => f%bounds(2), ybot => f%bounds(3), ytop => f%bounds(4))
      if (screen(1)) then
         xleft = aint(margins(1) * xmax + 0.5_R8P)
      elseif (margins(1) >= 0.0_R8P) then
         xleft = aint(margins(1) * f%hchar + 0.5_R8P)
      else
         xleft = f%hchar * 2.0_R8P + f%htic
      endif
      if (screen(2)) then
         xright = aint(margins(2) * xmax + 0.5_R8P)
      else
         xright = aint(xsize * xmax - f%hchar * 2.0_R8P - f%htic)
      endif
      if (screen(4)) then
         ybot = aint(margins(4) * ymax + 0.5_R8P)
      else
         ybot = aint(f%vchar * 2.5_R8P + 1.0_R8P)
      endif
      if (key_below > 0.0_R8P) ybot = ybot + aint(key_below)
      if (screen(3)) then
         ytop = aint(margins(3) * ymax + 0.5_R8P)
      else
         ytop = aint(ysize * ymax - f%vchar * (real(title_lines, R8P) + 1.5_R8P) - 1.0_R8P)
      endif
      if (key_side > 0.0_R8P .and. .not. screen(2)) xright = xright - aint(key_side)
      if (key_side < 0.0_R8P .and. .not. screen(1)) xleft = xleft + aint(-key_side)
      if (view%equal > 0_I4P) then
         h = int(ytop - ybot, I8P)
         w = int(xright - xleft, I8P)
         if (h > w) then
            ybot = ybot + real((h - w) / 2_I8P, R8P)
            ytop = ytop - real((h - w) / 2_I8P, R8P)
         else
            xleft = xleft + real((w - h) / 2_I8P, R8P)
            xright = xright - real((w - h) / 2_I8P, R8P)
         endif
      endif
      if (.not. screen(1)) xleft = aint(xleft + xmax * xoffset)
      if (.not. screen(2)) xright = aint(xright + xmax * xoffset)
      if (.not. screen(3)) ytop = aint(ytop + ymax * yoffset)
      if (.not. screen(4)) ybot = aint(ybot + ymax * yoffset)
      f%xmiddle = real((int(xright, I8P) + int(xleft, I8P)) / 2_I8P, R8P)
      f%ymiddle = real((int(ytop, I8P) + int(ybot, I8P)) / 2_I8P, R8P)
      f%xscaler = real((int(xright - xleft, I8P) * 4_I8P) / 7_I8P, R8P)
      f%yscaler = real((int(ytop - ybot, I8P) * 4_I8P) / 7_I8P, R8P)
      surface = real(real(view%scale, R4P), R8P)
      if (screen(3) .and. screen(4)) f%yscaler = aint((ytop - ybot) / surface)
      if (screen(1) .and. screen(2)) f%xscaler = aint((xright - xleft) / surface)
      if (f%yscaler == 0.0_R8P) f%yscaler = 1.0_R8P
      if (f%xscaler == 0.0_R8P) f%xscaler = 1.0_R8P
      f%xyscaler = sqrt(f%xscaler * f%yscaler)
   endassociate
   ! the transform: rot_z, then rot_x, then the scale (half the view's), then the azimuth about the line of sight
   f%mat = rot_z(real(real(view%rot_z, R4P), R8P))
   f%mat = matmul(f%mat, rot_x(real(real(view%rot_x, R4P), R8P)))
   m = unit4()
   m(1,1) = surface / 2.0_R8P
   m(2,2) = surface / 2.0_R8P
   m(3,3) = surface / 2.0_R8P
   f%mat = matmul(f%mat, m)
   if (view%azimuth /= 0.0_R8P) f%mat = matmul(f%mat, rot_z(real(real(view%azimuth, R4P), R8P)))
   ! the axes, in their linear space (log10 of a log axis)
   f%log = logs
   f%x = lin(xr, logs(1))
   f%y = lin(yr, logs(2))
   f%z = lin(zr, logs(3))
   zmin = f%z(1)
   zmax = f%z(2)
   ! the base plane: absolute (`set xyplane at Z`, the z axis start for a non positive Z on a log axis) or relative
   if (view%xyplane_at) then
      if (logs(3) .and. view%xyplane_z <= 0.0_R8P) then
         base1 = zmin
      else
         base1 = view3d_lin(view%xyplane_z, logs(3))
      endif
   else
      base1 = zmin - (zmax - zmin) * view%ticslevel
   endif
   f%base_z = base1
   if (base_drawn) then
      if (zmin > zmax) then
         f%floor_z = max(zmin, base1)
         f%ceiling_z = min(zmax, base1)
      else
         f%floor_z = min(zmin, base1)
         f%ceiling_z = max(zmax, base1)
      endif
   else
      f%floor_z = zmin
      f%ceiling_z = zmax
   endif
   ! the projection planes seen edge-on, their base the floor
   f%xz_plane = .false.
   f%yz_plane = .false.
   if (view%rot_x == 90.0_R8P .or. view%rot_x == 270.0_R8P) then
      if (view%rot_z == 0.0_R8P .or. view%rot_z == 180.0_R8P) then
         f%xz_plane = .true.
         f%base_z = f%floor_z
      endif
      if (view%rot_z == 90.0_R8P .or. view%rot_z == 270.0_R8P) then
         f%yz_plane = .true.
         if (view%rot_x == 270.0_R8P) f%base_z = f%ceiling_z
      endif
   endif
   ! the scales, `set view equal`
   f%scale3d(3) = 2.0_R8P / (f%ceiling_z - f%floor_z) * real(real(view%zscale, R4P), R8P)
   f%scale3d(2) = 2.0_R8P / (f%y(2) - f%y(1))
   f%scale3d(1) = 2.0_R8P / (f%x(2) - f%x(1))
   f%center3d = 0.0_R8P
   if (view%equal > 0_I4P) then
      if (f%scale3d(2) > f%scale3d(1)) then
         f%center3d(2) = 1.0_R8P - f%scale3d(1) / f%scale3d(2)
         f%scale3d(2) = f%scale3d(1)
      elseif (f%scale3d(1) > f%scale3d(2)) then
         f%center3d(1) = 1.0_R8P - f%scale3d(2) / f%scale3d(1)
         f%scale3d(1) = f%scale3d(2)
      endif
      if (view%equal > 1_I4P) f%scale3d(3) = f%scale3d(1)
   endif
   if (logs(3)) then
      f%center3d(3) = 0.0_R8P
   else
      f%center3d(3) = -(f%ceiling_z - f%floor_z) / 2.0_R8P * f%scale3d(3) + 1.0_R8P
   endif
   ! the box corners (setup_3d_box_corners), axis values
   quadrant = int(real(view%rot_z, R4P) / 90.0, I4P)
   if (iand(quadrant + 1_I4P, 2_I4P) /= 0_I4P) then
      f%zaxis_xy(1) = xr(2)
      f%right_xy(1) = xr(1)
      f%back_xy(2) = yr(1)
      f%front_xy(2) = yr(2)
   else
      f%zaxis_xy(1) = xr(1)
      f%right_xy(1) = xr(2)
      f%back_xy(2) = yr(2)
      f%front_xy(2) = yr(1)
   endif
   if (iand(quadrant, 2_I4P) /= 0_I4P) then
      f%zaxis_xy(2) = yr(2)
      f%right_xy(2) = yr(1)
      f%back_xy(1) = xr(2)
      f%front_xy(1) = xr(1)
   else
      f%zaxis_xy(2) = yr(1)
      f%right_xy(2) = yr(2)
      f%back_xy(1) = xr(1)
      f%front_xy(1) = xr(2)
   endif
   quadrant = int(real(view%rot_x, R4P) / 90.0, I4P)
   if (iand(quadrant, 2_I4P) /= 0_I4P) then
      zcorner(1) = f%front_xy(2)
      f%front_xy(2) = f%back_xy(2)
      f%back_xy(2) = zcorner(1)
      zcorner(1) = f%front_xy(1)
      f%front_xy(1) = f%back_xy(1)
      f%back_xy(1) = zcorner(1)
   endif
   if (iand(quadrant + 1_I4P, 2_I4P) /= 0_I4P) then
      f%yaxis_x = f%back_xy(1)
      f%xaxis_y = f%back_xy(2)
   else
      f%yaxis_x = f%front_xy(1)
      f%xaxis_y = f%front_xy(2)
   endif
   ! the title (do_3dplot): over the middle of the projected base plane (azimuth 0), its lines above the top
   f%xspan = f%bounds(1:2)
   if (view%azimuth == 0.0_R8P) then
      v = view3d_xyz(f, f%zaxis_xy(1), f%zaxis_xy(2), f%base_z, base=.true.)
      xl = aint(v(1) * f%xscaler) + f%xmiddle
      v = view3d_xyz(f, f%back_xy(1), f%back_xy(2), f%base_z, base=.true.)
      xb = aint(v(1) * f%xscaler) + f%xmiddle
      v = view3d_xyz(f, f%right_xy(1), f%right_xy(2), f%base_z, base=.true.)
      xrr = aint(v(1) * f%xscaler) + f%xmiddle
      f%xspan = [min(xl, xb), max(xb, xrr)]
   endif
   f%title(1) = real((int(f%xspan(1), I8P) + int(f%xspan(2), I8P)) / 2_I8P, R8P)
   f%title(2) = aint(f%bounds(4) + real(title_lines, R8P) * f%hchar)
   contains
      pure function unit4() result(u)
      !< The unit matrix.
      real(R8P)    :: u(4,4) !< Matrix.
      integer(I4P) :: i      !< Counter.

      u = 0.0_R8P
      do i = 1_I4P, 4_I4P
         u(i,i) = 1.0_R8P
      enddo
      endfunction unit4

      pure function rot_x(angle) result(r)
      !< gnuplot's mat_rot_x: a rotation about the x axis by `angle` [deg].
      real(R8P), intent(in) :: angle  !< Angle [deg].
      real(R8P)             :: r(4,4) !< Matrix.
      real(R8P)             :: c, s   !< Cosine, sine.

      c = cos(angle * PI_R8 / 180.0_R8P)
      s = sin(angle * PI_R8 / 180.0_R8P)
      r = unit4()
      r(2,2) = c
      r(2,3) = -s
      r(3,2) = s
      r(3,3) = c
      endfunction rot_x

      pure function rot_z(angle) result(r)
      !< gnuplot's mat_rot_z: a rotation about the z axis by `angle` [deg].
      real(R8P), intent(in) :: angle  !< Angle [deg].
      real(R8P)             :: r(4,4) !< Matrix.
      real(R8P)             :: c, s   !< Cosine, sine.

      c = cos(angle * PI_R8 / 180.0_R8P)
      s = sin(angle * PI_R8 / 180.0_R8P)
      r = unit4()
      r(1,1) = c
      r(1,2) = -s
      r(2,1) = s
      r(2,2) = c
      endfunction rot_z
   endfunction view3d_setup

   pure function view3d_xyz(f, x, y, z, base, linear) result(v)
   !< gnuplot's map3d_xyz: the point (`x`, `y`, `z`) (axis values; `base`: `z` already in the linear space of the z
   !< axis, as the base, floor and ceiling heights; `linear`: all three in the linear spaces of their axes) normalized
   !< to -1..1 over the box and transformed into the view.
   type(view3d_frame), intent(in)           :: f      !< The view.
   real(R8P),          intent(in)           :: x      !< Abscissa.
   real(R8P),          intent(in)           :: y      !< Ordinate.
   real(R8P),          intent(in)           :: z      !< Height.
   logical,            intent(in), optional :: base   !< `z` in the linear space of the axis.
   logical,            intent(in), optional :: linear !< `x`, `y` and `z` in the linear spaces of their axes.
   real(R8P)                                :: v(3)   !< View coordinates.
   real(R8P)                                :: p(4)   !< Homogeneous point.
   real(R8P)                                :: r(4)   !< Transformed.
   integer(I4P)                             :: i      !< Counter.
   logical                                  :: linear_z  !< `z` linear already.
   logical                                  :: linear_xy !< `x` and `y` linear already.

   linear_z = .false.
   linear_xy = .false.
   if (present(base)) linear_z = base
   if (present(linear)) then
      linear_z = linear_z .or. linear
      linear_xy = linear
   endif
   if (linear_xy) then
      p(1) = (x - f%x(1)) * f%scale3d(1) + f%center3d(1) - 1.0_R8P
      p(2) = (y - f%y(1)) * f%scale3d(2) + f%center3d(2) - 1.0_R8P
   else
      p(1) = (view3d_lin(x, f%log(1)) - f%x(1)) * f%scale3d(1) + f%center3d(1) - 1.0_R8P
      p(2) = (view3d_lin(y, f%log(2)) - f%y(1)) * f%scale3d(2) + f%center3d(2) - 1.0_R8P
   endif
   if (linear_z) then
      p(3) = (z - f%floor_z) * f%scale3d(3) + f%center3d(3) - 1.0_R8P
   else
      p(3) = (view3d_lin(z, f%log(3)) - f%floor_z) * f%scale3d(3) + f%center3d(3) - 1.0_R8P
   endif
   p(4) = 1.0_R8P
   do i = 1_I4P, 4_I4P
      r(i) = f%mat(4,i) + p(1) * f%mat(1,i) + p(2) * f%mat(2,i) + p(3) * f%mat(3,i)
   enddo
   if (r(4) == 0.0_R8P) r(4) = 1.0e-5_R8P
   v = r(1:3) / r(4)
   endfunction view3d_xyz

   pure function view3d_page(f, v, truncate, whole) result(p)
   !< The page position [px, y down] of the view point `v` (gnuplot's TERMCOORD_DOUBLE; `truncate`: TERMCOORD, the
   !< offset from the middle truncated toward zero to the terminal unit, as points and texts; `whole`: the terminal
   !< position truncated, as the lines of draw_clip_line).
   type(view3d_frame), intent(in)           :: f        !< The view.
   real(R8P),          intent(in)           :: v(:)     !< View coordinates.
   logical,            intent(in), optional :: truncate !< Truncate the offset to the terminal unit.
   logical,            intent(in), optional :: whole    !< Truncate the position to the terminal unit.
   real(R8P)                                :: p(2)     !< Page position [px].
   logical                                  :: trunc    !< Truncate.

   trunc = .false.
   if (present(truncate)) trunc = truncate
   if (present(whole)) then
      if (whole) then
         p(1) = aint(v(1) * f%xscaler + f%xmiddle) * 0.01_R8P
         p(2) = f%height - aint(v(2) * f%yscaler + f%ymiddle) * 0.01_R8P
         return
      endif
   endif
   if (trunc) then
      p(1) = (aint(v(1) * f%xscaler) + f%xmiddle) * 0.01_R8P
      p(2) = f%height - (aint(v(2) * f%yscaler) + f%ymiddle) * 0.01_R8P
   else
      p(1) = (v(1) * f%xscaler + f%xmiddle) * 0.01_R8P
      p(2) = f%height - (v(2) * f%yscaler + f%ymiddle) * 0.01_R8P
   endif
   endfunction view3d_page

   pure function lin(values, logarithmic) result(l)
   !< The values in the linear space of their axis: log10 on a log axis.
   real(R8P), intent(in) :: values(:)   !< Values.
   logical,   intent(in) :: logarithmic !< A log axis.
   real(R8P)             :: l(size(values)) !< Linear values.

   if (logarithmic) then
      l = log10(values)
   else
      l = values
   endif
   endfunction lin

   elemental function view3d_lin(value, logarithmic) result(l)
   !< A value in the linear space of its axis: log10 on a log axis.
   real(R8P), intent(in) :: value       !< Value.
   logical,   intent(in) :: logarithmic !< A log axis.
   real(R8P)             :: l           !< Linear value.

   if (logarithmic) then
      l = log10(value)
   else
      l = value
   endif
   endfunction view3d_lin
endmodule foresight_view3d
