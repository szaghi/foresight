!< foresight, FORtran Easy Svg Interactive Gnuplot-like Html Tool.
module foresight
!< foresight, FORtran Easy Svg Interactive Gnuplot-like Html Tool.
!<
!< Library entry point: re-exports the public API of all foresight modules.
use foresight_figure, only : figure_object
use foresight_fit, only : fit, fit_report, fit_result, fit_settings, model_function
use foresight_fingerprint, only : file_fingerprint
use foresight_script, only : script_object
use foresight_stats, only : stats, stats_column, stats_report, stats_result
use foresight_sys, only : rename_file, sleep_ms
use foresight_theme, only : THEMES
use penf, only : I4P, I8P, R4P, R8P

implicit none
private
! expose foresight figure (gnuplot-like API)
public :: figure_object
! expose gnuplot's fit (Marquardt-Levenberg) for Fortran models
public :: fit
public :: fit_report
public :: fit_result
public :: fit_settings
public :: model_function
! expose gnuplot's stats for Fortran arrays
public :: stats
public :: stats_column
public :: stats_report
public :: stats_result
! expose foresight gnuplot-subset interpreter
public :: script_object
! expose foresight system services
public :: file_fingerprint
public :: rename_file
public :: sleep_ms
! expose the output theme names
public :: THEMES
! expose PENF kinds
public :: I4P, I8P, R4P, R8P
endmodule foresight
