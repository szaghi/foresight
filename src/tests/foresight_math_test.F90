!< foresight_math test: the 40 reference formulas laid out as LuaLaTeX lays them out.
program foresight_math_test
!< foresight_math against LuaLaTeX (issue #5 step 4.1): each formula of src/tests/math_refs.txt (scripts/gen_math_refs.py:
!< LuaLaTeX, unicode-math, Latin Modern Math, 10 pt) laid out at 10 pt, every glyph of LaTeX's matched with foresight's
!< glyph of the same character nearest to it: within 0.5 pt, and as many glyphs.
use, intrinsic :: iso_fortran_env, only : error_unit, output_unit
use foresight_math, only : math_item, math_layout
use penf, only : I4P, R8P

implicit none
character(len=*), parameter  :: REFS = 'src/tests/math_refs.txt' !< Reference layout.
real(R8P),        parameter  :: TOLERANCE = 0.5_R8P              !< Largest distance [pt].
type(math_item), allocatable :: items(:)                         !< foresight's glyphs and rules.
logical,         allocatable :: used(:)                          !< foresight's glyphs matched.
character(len=512)           :: line                             !< A line of the references.
character(len=:), allocatable :: formula                         !< The formula.
integer(I4P)                 :: unit                             !< File unit.
integer(I4P)                 :: ios                              !< I/O status.
integer(I4P)                 :: code                             !< A reference glyph's character.
integer(I4P)                 :: formulas                         !< Formulas read.
integer(I4P)                 :: passed                           !< Formulas within the tolerance.
integer(I4P)                 :: glyphs                           !< Reference glyphs of the formula.
integer(I4P)                 :: k                                !< Item.
integer(I4P)                 :: best                             !< Nearest item.
real(R8P)                    :: x                                !< A reference glyph's origin.
real(R8P)                    :: y                                !< Its baseline.
real(R8P)                    :: d                                !< A distance.
real(R8P)                    :: worst                            !< The formula's largest distance.
real(R8P)                    :: w, h, dp                         !< Formula box.
logical                      :: ok                               !< The formula passes.

open(newunit=unit, file=REFS, status='old', action='read', iostat=ios)
if (ios /= 0) error stop 'foresight_math_test: cannot read '//REFS
formulas = 0
passed = 0
formula = ''
do
   read(unit, '(A)', iostat=ios) line
   if (ios /= 0 .or. line(1:2) == 'F ') then
      if (len(formula) > 0) call finish
      if (ios /= 0) exit
      formula = trim(line(3:))
      formulas = formulas + 1
      call math_layout(formula, 10.0_R8P, items, w, h, dp)
      allocate(used(size(items)))
      used = .false.
      glyphs = 0
      worst = 0.0_R8P
      ok = .true.
      cycle
   endif
   if (line(1:2) /= 'G ') cycle
   read(line(3:), *) code, x, y
   glyphs = glyphs + 1
   best = 0
   do k = 1, size(items)
      if (used(k) .or. items(k)%face == 0 .or. items(k)%unicode /= code) cycle
      d = max(abs(items(k)%x - x), abs(items(k)%y - y))
      if (best == 0) then
         best = k
      elseif (d < max(abs(items(best)%x - x), abs(items(best)%y - y))) then
         best = k
      endif
   enddo
   if (best == 0) then
      write(error_unit, '(A,I0,A)') formula//': no glyph U+', code, ' in foresight''s'
      ok = .false.
      cycle
   endif
   used(best) = .true.
   d = max(abs(items(best)%x - x), abs(items(best)%y - y))
   worst = max(worst, d)
   if (d > TOLERANCE) then
      write(error_unit, '(A,I0,4(A,F7.3))') formula//': U+', code, ' at ', items(best)%x, ',', items(best)%y, &
                                             ' LaTeX ', x, ',', y
      ok = .false.
   endif
enddo
close(unit)
write(output_unit, '(A,I0,A,I0,A)') 'foresight_math: ', passed, '/', formulas, ' formulas within 0.5 pt of LuaLaTeX'
if (passed /= formulas .or. formulas /= 40) then
   write(output_unit, '(A)') 'Are all tests passed? F'
   error stop 1
endif
write(output_unit, '(A)') 'Are all tests passed? T'
contains
   subroutine finish
   !< Close the formula: count foresight's glyphs left unmatched, report.
   integer(I4P) :: extra !< Unmatched glyphs.

   extra = count(.not. used .and. items%face /= 0)
   if (extra > 0) then
      write(error_unit, '(A,I0,A)') formula//': ', extra, ' glyphs more than LaTeX''s'
      ok = .false.
   endif
   if (ok) passed = passed + 1
   write(output_unit, '(A,F6.3,A,L1)') '  '//formula//repeat(' ', max(0, 38 - len(formula)))//' worst ', worst, &
                                       ' pt ', ok
   deallocate(used)
   formula = ''
   endsubroutine finish
endprogram foresight_math_test
