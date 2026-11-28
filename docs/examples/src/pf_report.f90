!run pf_report pf_report && ls report
!run pf_report-head head -n 16 report/report.md
program pf_report
!< A run report in Markdown, written by the program that has the results: three figures with their alternative texts
!< and captions (`save(file, info=meta)`), a table of statistics written with `write`, and a table of the history
!< written by a script (`set table ... append markdown`) into the same page. It reads the logs of solver.f90.
use foresight, only : figure_info, figure_object, script_object, stats, stats_result, I4P, R8P
implicit none
character(len=*), parameter   :: page = 'report/report.md' !< The report.
character(len=1), parameter   :: nl = new_line('a')        !< New line.
type(script_object)           :: gp                        !< Script interpreter.
type(figure_object)           :: fig                       !< Library figure.
type(figure_info)             :: meta                      !< What the page needs of a figure.
type(stats_result)            :: r                         !< Statistics of a column.
character(len=:), allocatable :: iomsg                     !< Error message.
integer(I4P)                  :: iostat                    !< Error status.
integer(I4P)                  :: md                        !< The report's unit.
integer(I4P)                  :: figures = 0_I4P           !< Figures written.
real(R8P)                     :: it(120), rho(120), mom(120), energy(120), cd(120), dcd(120) !< The log.

call read_log
call execute_command_line('mkdir -p report')
open(newunit=md, file=page, status='replace', action='write')
write(md, '(A)') '# Run report', '', &
                 'The pretend flow solver of path A: 120 iterations, a restart at iteration 60. This page, its '// &
                 'figures and its tables were written by `pf_report.f90`.', ''

!region script-figure
! a figure drawn by a script: its caption set there, its information from the figure the script built
call gp%init('report/residuals.svg')
call gp%run_text("set terminal svg size 600,340 theme paper"//nl// &
                 "set logscale y; set format y '10^{%L}'"//nl// &
                 "set xlabel 'iteration'; set ylabel 'residual'; set title 'Convergence'"//nl// &
                 "set caption 'The three residuals fall by five decades or more; the restart at iteration 60 does not "// &
                 "disturb them.'"//nl// &
                 "plot 'run.dat' u 1:2 w l t 'continuity', '' u 1:3 w l t 'momentum', '' u 1:4 w l t 'energy'", &
                 iostat, iomsg)
if (iostat /= 0_I4P) error stop iomsg
call gp%figure%save('report/residuals.svg', info=meta)
call add_figure(meta)
!endregion script-figure

!region library-figure
! a figure of the library: the drag coefficient and its error bars
call fig%init(width=600_I4P, height=340_I4P)
call fig%set_theme('paper')
call fig%set_enhanced
call fig%set_title('Drag coefficient')
call fig%set_xlabel('iteration')
call fig%set_ylabel('c_d')
call fig%plot(it, cd, title='c_d', with='yerrorbars', ylow=cd - dcd, yhigh=cd + dcd)
call fig%set_caption('The drag coefficient settles at 0.30; its error bars shrink as one over the square root of '// &
                     'the iteration.')
call fig%save('report/drag.svg', info=meta)
call add_figure(meta)
!endregion library-figure

! a figure of the last iterations, from the same arrays
call fig%init(width=600_I4P, height=300_I4P)
call fig%set_theme('paper')
call fig%set_enhanced
call fig%set_xlabel('continuity residual')
call fig%set_ylabel('c_d')
call fig%set_logscale('x')
call fig%plot(rho(61:), cd(61:), title='after the restart', with='points')
call fig%set_caption('The drag coefficient against the continuity residual after the restart: it closes in on 0.30 '// &
                     'as the residual falls.')
call fig%save('report/drag_residual.svg', info=meta)
call add_figure(meta)

!region stats-table
! a table written by the program: statistics of the last 60 iterations
r = stats(cd(61:))
write(md, '(A)') '## Statistics', '', 'The last 60 iterations, after the restart.', '', &
                 '| quantity | mean | standard deviation | min | max |', '| --- | --: | --: | --: | --: |'
write(md, '(A,4(" | ",F8.5)," |")') '| drag coefficient', r%y%mean, r%y%stddev, r%y%min, r%y%max
r = stats(log10(rho(61:)))
write(md, '(A,4(" | ",F8.3)," |")') '| log10 continuity residual', r%y%mean, r%y%stddev, r%y%min, r%y%max
write(md, '(A)') ''
!endregion stats-table

!region script-table
! a table written by a script into the page: the history every 20 iterations, its header from the CSV's
write(md, '(A)') '## History', '', 'Every 20 iterations, from `run.csv`.', ''
close(md)
call gp%run_text("set datafile separator comma; set datafile columnheaders"//nl// &
                 "set table '"//page//"' append markdown"//nl// &
                 "plot 'run.csv' every 20 using 1:""continuity"":""momentum"":""cd"" with table"//nl// &
                 "unset table", iostat, iomsg)
if (iostat /= 0_I4P) error stop iomsg
!endregion script-table

contains
   !region add-figure
   subroutine add_figure(info)
   !< The figure in the page: an image with its alternative text, its caption numbered below it.
   type(figure_info), intent(in) :: info   !< The figure's information.
   character(len=:), allocatable :: name   !< The file, relative to the page.
   character(len=12)             :: number !< Figure number.

   figures = figures + 1_I4P
   write(number, '(I0)') figures
   name = info%file(index(info%file, '/', back=.true.) + 1:)
   write(md, '(A)') '!['//info%alt//']('//name//')', '', &
                    '*Figure '//trim(number)//'. '//info%caption//'*', ''
   endsubroutine add_figure
   !endregion add-figure

   subroutine read_log
   !< The log run.dat of solver.f90: iteration, three residuals, drag coefficient and its error (a comment line, a
   !< blank line at the restart).
   character(len=256) :: line !< A line.
   integer(I4P)       :: unit !< File unit.
   integer(I4P)       :: n    !< Rows read.
   integer(I4P)       :: ios  !< Read status.

   open(newunit=unit, file='run.dat', status='old', action='read')
   n = 0_I4P
   do
      read(unit, '(A)', iostat=ios) line
      if (ios /= 0) exit
      if (len_trim(line) == 0 .or. line(1:1) == '#') cycle
      n = n + 1_I4P
      read(line, *) it(n), rho(n), mom(n), energy(n), cd(n), dcd(n)
   enddo
   close(unit)
   endsubroutine read_log
endprogram pf_report
