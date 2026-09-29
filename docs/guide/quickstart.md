---
title: Quick Start
---

# Quick Start

## A plot from Fortran

```fortran
program quickstart
use foresight, only : figure_object, I4P, R8P
implicit none
type(figure_object)    :: fig
real(R8P), allocatable :: t(:)
integer(I4P)           :: i

t = [(0.1_R8P * i, i = 0, 100)]
call fig%set_title('Damped oscillation')
call fig%set_xlabel('t [s]')
call fig%set_ylabel('u')
call fig%plot(t, exp(-0.3_R8P * t) * cos(2.0_R8P * t), title='u(t)')
call fig%plot(t, exp(-0.3_R8P * t), title='envelope', dt=2_I4P)
call fig%save('quickstart.html')   ! interactive page
call fig%save('quickstart.svg')    ! static vector image
endprogram quickstart
```

```bash
gfortran -I foresight/lib/mod quickstart.f90 foresight/lib/libforesight.a -o quickstart
./quickstart
```

![Damped oscillation and its envelope](/examples/quickstart.svg)

Open [quickstart.html](/foresight/examples/quickstart.html){target="_self"} in a browser: wheel to zoom, drag to pan, `a` to
autoscale back, `h` for the list of keys.

## A plot from the shell

A gnuplot script, `residuals.gp`:

```gnuplot
# residuals.gp: convergence monitor of a running job
set title "Residuals"
set xlabel "iteration"
set ylabel "L2 norm"
set logscale y
set grid
plot 'residuals.dat' using 1:2 with lines title 'continuity', \
     ''              using 1:3 with lines title 'momentum'
```

```bash
foresight residuals.gp                                    # writes residuals.html
foresight -e "set terminal svg" residuals.gp              # writes residuals.svg
foresight -e "set terminal dumb size 70,20" residuals.gp  # prints to the terminal
foresight --watch residuals.gp                            # re-renders while residuals.dat grows
```

The text output of the third command:

```
                                   Residuals
      10^1+-----+-----+----+-----+-----+-----+-----+----+-----+-----+
          +     .     .    .     .     .     .     continuity****** +
      10^0+#####.....................................momentum######.+
          +*****#######    .     .     .     .     .    .     .     +
   L      +     ******######     .     .     .     .    .     .     +
   2 10^-1+..........******.#######.................................+
          +     .     .   *****  .#######    .     .    .     .     +
   n 10^-2+....................******....######.....................+
   o      +     .     .    .     .  *****    . ######   .     .     +
   r 10^-3+..............................*****.......#######........+
   m      +     .     .    .     .     .     .*****.    .  #######  +
          +     .     .    .     .     .     .     *****.     .  ###+
     10^-4+.............................................*****.......+
          +     .     .    .     .     .     .     .    .   ******  +
     10^-5+-----+-----+----+-----+-----+-----+-----+----+-----+-----+
          0    10    20   30    40    50    60    70   80    90    100
                                   iteration
```

## Next

- [Fortran Library](library): the full `figure_object` API
- [Command Line](cli) and [gnuplot Subset](gnuplot-subset): what scripts can do
- [Live Monitoring](monitoring): watching a running job
