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
public :: view3d_object

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
   real(R8P),           intent(in) :: box(4)      !< Panel box: left, top, width, height [px].
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
endmodule foresight_view3d
