!< foresight_view3d, the view of the 3D panels (gnuplot `splot`): its settings, the projection and the map layout.
module foresight_view3d
!< foresight_view3d, the view of the 3D panels (gnuplot `splot`): its settings, the projection and the map layout.
!<
!< The settings follow gnuplot 6.0's `set view`, `set xyplane` (`set ticslevel`), `set surface` and `set isosamples`;
!< their defaults are gnuplot's (`set view 60, 30, 1, 1`, `set xyplane relative 0.5`).
use penf, only : I4P, R8P

implicit none
private
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
endmodule foresight_view3d
