!< foresight, FORtran Easy Svg Interactive Gnuplot-like Html Tool.
module foresight
!< foresight, FORtran Easy Svg Interactive Gnuplot-like Html Tool.
!<
!< Library entry point: re-exports the public API of all foresight modules.
use foresight_figure, only : figure_object
use foresight_script, only : script_object
use foresight_sys, only : rename_file, sleep_ms
use penf, only : I4P, I8P, R4P, R8P

implicit none
private
! expose foresight figure (gnuplot-like API)
public :: figure_object
! expose foresight gnuplot-subset interpreter
public :: script_object
! expose foresight system services
public :: rename_file
public :: sleep_ms
! expose PENF kinds
public :: I4P, I8P, R4P, R8P
endmodule foresight
