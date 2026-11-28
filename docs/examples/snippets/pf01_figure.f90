program pf01_figure
!< A figure and what a report needs of it: `save(file, info=meta)`, then the Markdown of the figure.
use foresight, only : figure_info, figure_object, I4P, R8P
implicit none
type(figure_object) :: fig     !< Figure.
type(figure_info)   :: meta    !< What the report needs of it.
real(R8P)           :: t(50)   !< Time.
integer(I4P)        :: k       !< Counter.

t = [(0.2_R8P * k, k = 1, 50)]
call fig%init(width=600_I4P, height=320_I4P)
call fig%set_theme('paper')
call fig%set_title('Decay')
call fig%set_xlabel('time [s]')
call fig%set_ylabel('amplitude')
call fig%plot(t, exp(-t / 3.0_R8P) * cos(2.0_R8P * t), title='measured')
call fig%plot(t, exp(-t / 3.0_R8P), title='envelope')
call fig%set_caption('A damped oscillation and its envelope, exp(-t/3).')
call fig%save('pf01.svg', info=meta)

print '(A)', 'file:    '//meta%file
print '(A)', 'format:  '//meta%format
print '(A,F0.1,A,F0.1,A,F0.2,A,F0.2,A)', 'size:    ', meta%width_px, ' x ', meta%height_px, ' px, ', &
                                         meta%width_cm, ' x ', meta%height_cm, ' cm'
print '(A)', 'alt:     '//meta%alt
print '(A)', 'caption: '//meta%caption
print '(A)', ''
print '(A)', '!['//meta%alt//']('//meta%file//')'
print '(A)', ''
print '(A)', '*Figure 1. '//meta%caption//'*'
endprogram pf01_figure
