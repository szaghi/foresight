! a table written by a script into the page: the history every 20 iterations, its header from the CSV's
write(md, '(A)') '## History', '', 'Every 20 iterations, from `run.csv`.', ''
close(md)
call gp%run_text("set datafile separator comma; set datafile columnheaders"//nl// &
                 "set table '"//page//"' append markdown"//nl// &
                 "plot 'run.csv' every 20 using 1:""continuity"":""momentum"":""cd"" with table"//nl// &
                 "unset table", iostat, iomsg)
if (iostat /= 0_I4P) error stop iomsg
