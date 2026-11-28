!< foresight figure information test: what `save(file, info=)` returns for a document.
program foresight_info_test
!< foresight figure information test: what `save(file, info=)` returns for a document.
!<
!< Every field of `figure_info` for svg, html, pdf, cairolatex (input and standalone) and text saves, `set caption` in
!< scripts and the library, and the alternative text of 5 figures (no text, one panel, a multiplot, a 3D plot, enhanced
!< markup and TeX math). Run from the repository root.
use, intrinsic :: iso_fortran_env, only : error_unit, output_unit
use foresight, only : figure_info, figure_object, I4P, R8P, script_object

implicit none
character(len=*), parameter   :: base = 'foresight_info_test' !< Output files' base name.
type(figure_object)           :: fig                          !< Library figure.
type(script_object)           :: interpreter                  !< Interpreter.
type(figure_info)             :: info                         !< Information returned.
character(len=:), allocatable :: iomsg                        !< Error message.
integer(I4P)                  :: iostat                       !< Status.
real(R8P)                     :: x(5)                         !< Abscissae.
integer(I4P)                  :: i                            !< Counter.
logical                       :: test_passed(14)              !< Per-check outcome.

test_passed = .false.
x = [(real(i, R8P), i = 1, 5)]

! 1-2: a library figure saved as svg, its caption set
call fig%init
call fig%set_title('Residual history')
call fig%set_xlabel('iteration')
call fig%set_ylabel('residual')
call fig%plot(x, 1.0_R8P / x, title='rho')
call fig%plot(x, 2.0_R8P / x, title='u')
call fig%set_caption('Residuals of the run.')
call fig%save(base//'.svg', info=info)
test_passed(1) = expect('svg file', info%file, base//'.svg') .and. expect('svg format', info%format, 'svg') .and. &
                 expect('svg graphics', info%graphics, '') .and. near('svg width px', info%width_px, 600.0_R8P) .and. &
                 near('svg height px', info%height_px, 480.0_R8P) .and. &
                 near('svg width cm', info%width_cm, 15.875_R8P) .and. near('svg height cm', info%height_cm, 12.7_R8P) &
                 .and. expect('svg caption', info%caption, 'Residuals of the run.') .and. exists(base//'.svg')
test_passed(2) = expect('alt one panel', info%alt, &
                        'Plot: Residual history. x axis: iteration. y axis: residual. Series: rho, u.')

! 3: the same figure as html: its format, the caption kept
call fig%save(base//'.html', info=info)
test_passed(3) = expect('html format', info%format, 'html') .and. near('html width px', info%width_px, 600.0_R8P) .and. &
                 expect('html caption', info%caption, 'Residuals of the run.') .and. exists(base//'.html')

! 4: a pdfcairo figure of physical size: px at 96 to the inch, cm back as set
call interpreter%init('x.html')
call interpreter%run_text("set terminal pdfcairo size 8cm,6cm; set output '"//base//".pdf'"//new_line('a')// &
                          "set caption 'A PDF figure.'"//new_line('a')// &
                          "set xlabel 'x'; plot sin(x) title 'sin'", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
call interpreter%figure%save(base//'.pdf', info=info)
test_passed(4) = iostat == 0_I4P .and. expect('pdf format', info%format, 'pdf') .and. &
                 expect('pdf graphics', info%graphics, '') .and. &
                 near('pdf width px', info%width_px, 8.0_R8P / 2.54_R8P * 96.0_R8P) .and. &
                 near('pdf width cm', info%width_cm, 8.0_R8P) .and. near('pdf height cm', info%height_cm, 6.0_R8P) .and. &
                 expect('pdf caption', info%caption, 'A PDF figure.') .and. exists(base//'.pdf') .and. &
                 expect('pdf alt', info%alt, 'Plot. x axis: x. Series: sin.')

! 5: unset caption
call interpreter%run_text("unset caption", iostat, iomsg)
call interpreter%figure%save(base//'.pdf', info=info)
test_passed(5) = iostat == 0_I4P .and. expect('unset caption', info%caption, '')

! 6-7: cairolatex, for \input and standalone: the picture and the graphics it includes
call fig%set_cairolatex(standalone=.false.)
call fig%save(base//'.tex', info=info)
test_passed(6) = expect('tex file', info%file, base//'.tex') .and. expect('tex format', info%format, 'tex') .and. &
                 expect('tex graphics', info%graphics, base//'.pdf') .and. near('tex width cm', info%width_cm, 15.875_R8P) &
                 .and. exists(base//'.tex') .and. exists(base//'.pdf')
call fig%set_cairolatex(standalone=.true.)
call fig%save(base//'_sa.tex', info=info)
test_passed(7) = expect('standalone graphics', info%graphics, base//'_sa-inc.pdf') .and. exists(base//'_sa-inc.pdf') &
                 .and. expect('standalone caption', info%caption, 'Residuals of the run.')

! 8: text: no size
call fig%save(base//'.txt', info=info)
test_passed(8) = expect('txt format', info%format, 'txt') .and. near('txt width px', info%width_px, 0.0_R8P) .and. &
                 near('txt width cm', info%width_cm, 0.0_R8P) .and. exists(base//'.txt')

! 9: a figure without texts
call fig%init
call fig%plot(x, x)
call fig%save(base//'.svg', info=info)
test_passed(9) = expect('alt no text', info%alt, 'Plot.') .and. expect('no caption', info%caption, '')

! 10: a multiplot with its title, two panels
call interpreter%init('x.html')
call interpreter%run_text("set terminal svg; set output '"//base//"_mp.svg'"//new_line('a')// &
                          "set multiplot layout 1,2 title 'Monitor'"//new_line('a')// &
                          "set title 'residual'; set ylabel 'L2 norm'; plot x title 'res'"//new_line('a')// &
                          "set title 'drag'; unset ylabel; plot x**2 title 'cd', x**3 notitle", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
! the panels, before `unset multiplot` draws them and starts a new page
call interpreter%figure%save(base//'_mp.svg', info=info)
call interpreter%run_text("unset multiplot", iostat, iomsg)
test_passed(10) = iostat == 0_I4P .and. expect('alt multiplot', info%alt, &
                  'Figure: Monitor. Panel 1, plot: residual. y axis: L2 norm. Series: res. Panel 2, plot: drag. Series: cd.')

! 11: a 3D plot
call interpreter%init('x.html')
call interpreter%run_text("set terminal svg; set output '"//base//"_3d.svg'"//new_line('a')// &
                          "set title 'Gaussian'; set xlabel 'x'; set ylabel 'y'; set zlabel 'height'"//new_line('a')// &
                          "splot exp(-x**2-y**2) title 'g'", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
call interpreter%figure%save(base//'_3d.svg', info=info)
test_passed(11) = iostat == 0_I4P .and. expect('alt 3D', info%alt, &
                  'Surface plot: Gaussian. x axis: x. y axis: y. z axis: height. Series: g.')

! 12: enhanced markup dropped, TeX math kept, a color axis label
call interpreter%init('x.html')
call interpreter%run_text("set terminal svg; set output '"//base//"_en.svg'"//new_line('a')// &
                          "set title 'E = mc^2'; set xlabel 'time t_{0}'; set ylabel '$\alpha_1$'"//new_line('a')// &
                          "set cblabel 'T [K]'; plot x title 'a^{2}'", iostat, iomsg)
if (iostat /= 0_I4P) write(error_unit, '(A)') iomsg
call interpreter%figure%save(base//'_en.svg', info=info)
test_passed(12) = iostat == 0_I4P .and. expect('alt enhanced', info%alt, &
                  'Plot: E = mc2. x axis: time t0. y axis: $\alpha_1$. Color axis: T [K]. Series: a2.')

! 13: `reset` clears the caption, as every setting
call interpreter%run_text("set caption 'kept?'"//new_line('a')//"reset", iostat, iomsg)
call interpreter%figure%save(base//'_en.svg', info=info)
test_passed(13) = iostat == 0_I4P .and. expect('reset caption', info%caption, '')

! 14: text on standard output: format txt, no size
call fig%init
call fig%set_text(charset='dumb')
call fig%plot(x, x, title='y = x')
call fig%save('-', info=info)
test_passed(14) = expect('stdout file', info%file, '-') .and. expect('stdout format', info%format, 'txt') .and. &
                  near('stdout height px', info%height_px, 0.0_R8P) .and. expect('stdout alt', info%alt, 'Plot. Series: y = x.')
call cleanup

if (all(test_passed)) then
   write(output_unit, '(A)') 'All tests passed'
else
   do i = 1, size(test_passed)
      if (.not. test_passed(i)) write(error_unit, '(A,I0,A)') 'check ', i, ' failed'
   enddo
   error stop 1
endif

contains
   function expect(what, got, want) result(ok)
   !< `got` equals `want`; reports the difference otherwise.
   character(len=*), intent(in) :: what !< Check name.
   character(len=*), intent(in) :: got  !< Value got.
   character(len=*), intent(in) :: want !< Value expected.
   logical                      :: ok   !< Equal.

   ok = got == want .and. len(got) == len(want)
   if (.not. ok) write(error_unit, '(A)') what//': got "'//got//'", expected "'//want//'"'
   endfunction expect

   function near(what, got, want) result(ok)
   !< `got` within 1e-9 of `want`; reports the difference otherwise.
   character(len=*), intent(in) :: what !< Check name.
   real(R8P),        intent(in) :: got  !< Value got.
   real(R8P),        intent(in) :: want !< Value expected.
   logical                      :: ok   !< Near.

   ok = abs(got - want) <= 1.0e-9_R8P * max(1.0_R8P, abs(want))
   if (.not. ok) write(error_unit, '(A,2(1X,ES24.16))') what//': got, expected', got, want
   endfunction near

   function exists(file) result(ok)
   !< `file` was written.
   character(len=*), intent(in) :: file !< File.
   logical                      :: ok   !< Exists.

   inquire(file=file, exist=ok)
   if (.not. ok) write(error_unit, '(A)') 'not written: '//file
   endfunction exists

   subroutine cleanup
   !< Delete the files written.
   character(len=24), parameter :: suffixes(10) = [character(len=24) :: '.svg', '.html', '.pdf', '.tex', '_sa.tex', &
                                                   '_sa-inc.pdf', '.txt', '_mp.svg', '_3d.svg', '_en.svg']
   integer(I4P) :: k    !< Counter.
   integer(I4P) :: unit !< File unit.
   logical      :: here !< The file exists.

   do k = 1, size(suffixes, kind=I4P)
      inquire(file=base//trim(suffixes(k)), exist=here)
      if (.not. here) cycle
      open(newunit=unit, file=base//trim(suffixes(k)))
      close(unit, status='delete')
   enddo
   endsubroutine cleanup
endprogram foresight_info_test
