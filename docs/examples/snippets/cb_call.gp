set terminal svg size 760,300; set output 'cb_call.svg'
# one panel script called with arguments (files/panel.gp: ARG1 the column, ARG2 the title)
set multiplot layout 1,2
call 'panel.gp' 2 'continuity'
call 'panel.gp' 3 'momentum'
unset multiplot
