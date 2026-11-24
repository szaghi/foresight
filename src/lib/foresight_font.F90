!< foresight_font, gnuplot's font specs ("family:Bold:Italic,size") per text element, and their SVG attributes.
module foresight_font
!< foresight_font, gnuplot's font specs ("family:Bold:Italic,size") per text element, and their SVG attributes.
!<
!< As gnuplot 6.0's svg terminal: the size after the first comma, `:Bold` and `:Italic` (or ` bold`, ` italic`) the
!< weight and the style, the rest the family. A family is written to the SVG as given (the reader's fonts render it);
!< font files (a path, `.ttf`) and gnuplot's `mbfont:` sets are not families an SVG can name: left out, as an empty
!< family is. Text widths stay foresight's estimate, whatever the family.
use penf, only : R8P

implicit none
private
public :: font_object
public :: font_of
public :: font_attributes

type :: font_object
   !< A text element's font: a size, a family, the weight and the style; unset parts take the page's.
   real(R8P)         :: size   = 0.0_R8P !< Size [px], 0 the page's.
   character(len=48) :: family = ''      !< CSS family, empty the page's.
   logical           :: bold   = .false. !< Bold.
   logical           :: italic = .false. !< Italic.
   contains
      procedure, pass(self) :: is_set  !< Whether any part is set.
      procedure, pass(self) :: size_px !< The size [px], the page's if unset.
endtype font_object

contains
   elemental function is_set(self) result(yes)
   !< Whether any part of the font is set.
   class(font_object), intent(in) :: self !< Font.
   logical                        :: yes  !< Set.

   yes = self%size > 0.0_R8P .or. len_trim(self%family) > 0 .or. self%bold .or. self%italic
   endfunction is_set

   elemental function size_px(self, page) result(size)
   !< The size [px]: the font's, or `page` if unset.
   class(font_object), intent(in) :: self !< Font.
   real(R8P),          intent(in) :: page !< Page font size [px].
   real(R8P)                      :: size !< Size [px].

   size = page
   if (self%size > 0.0_R8P) size = self%size
   endfunction size_px

   pure function font_of(spec) result(font)
   !< The font of gnuplot's spec `"family:Bold:Italic,size"` (each part optional: `",8"`, `":Bold"`, `"Times,14"`).
   character(len=*), intent(in)  :: spec   !< Font spec.
   type(font_object)             :: font   !< Font.
   character(len=:), allocatable :: name   !< Text before the first comma.
   character(len=:), allocatable :: number !< Text after it.
   integer                       :: comma  !< First comma.
   integer                       :: ios    !< Read status.

   font = font_object()
   comma = index(spec, ',')
   if (comma > 0) then
      name = spec(1:comma - 1)
      number = trim(adjustl(spec(comma + 1:)))
      if (len(number) > 0 .and. verify(number, '0123456789.') == 0) then
         read(number, *, iostat=ios) font%size
         if (ios /= 0 .or. font%size < 0.0_R8P) font%size = 0.0_R8P
      endif
   else
      name = spec
   endif
   call take(name, ':Bold', font%bold)
   call take(name, ':bold', font%bold)
   call take(name, ' bold', font%bold)
   call take(name, ' Bold', font%bold)
   call take(name, ':Italic', font%italic)
   call take(name, ':italic', font%italic)
   call take(name, ' italic', font%italic)
   call take(name, ' Italic', font%italic)
   name = trim(adjustl(name))
   ! a family an SVG can name: letters, digits, blanks, '-', '_' (not a font file, nor gnuplot's mbfont: sets)
   if (len(name) > 0 .and. len(name) <= len(font%family)) then
      if (verify(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 -_') == 0) font%family = name
   endif
   contains
      pure subroutine take(name, word, flag)
      !< Remove every `word` from `name`, setting `flag` if any.
      character(len=:), allocatable, intent(inout) :: name !< Font name.
      character(len=*),              intent(in)    :: word !< Word.
      logical,                       intent(inout) :: flag !< Found.
      integer                                      :: k    !< Position.

      do
         k = index(name, word)
         if (k == 0) exit
         flag = .true.
         name = name(1:k - 1)//name(k + len(word):)
      enddo
      endsubroutine take
   endfunction font_of

   pure function font_attributes(font, size) result(text)
   !< The SVG attributes of `font` (leading blank each), its size `size` [px] if set (0: none): `font-size`,
   !< `font-family` (quoted when it holds a blank), `font-weight`, `font-style`.
   type(font_object), intent(in)  :: font !< Font.
   real(R8P),         intent(in)  :: size !< Size to write [px], 0 for none.
   character(len=:), allocatable  :: text !< Attributes.
   character(len=32)              :: buffer !< Number.

   text = ''
   if (size > 0.0_R8P) then
      write(buffer, '(F0.2)') size
      ! the shortest form, as foresight's other numbers: 8.00 -> 8, 7.50 -> 7.5
      buffer = trim_zeros(buffer)
      text = text//' font-size="'//trim(buffer)//'"'
   endif
   if (len_trim(font%family) > 0) then
      if (index(trim(font%family), ' ') > 0) then
         text = text//' font-family="'''//trim(font%family)//'''"'
      else
         text = text//' font-family="'//trim(font%family)//'"'
      endif
   endif
   if (font%bold) text = text//' font-weight="bold"'
   if (font%italic) text = text//' font-style="italic"'
   contains
      pure function trim_zeros(number) result(short)
      !< `number` without trailing zeros of its fraction nor a trailing point.
      character(len=*), intent(in)  :: number !< Number.
      character(len=:), allocatable :: short  !< Shortened.

      short = trim(adjustl(number))
      if (index(short, '.') == 0) return
      do while (short(len(short):len(short)) == '0')
         short = short(1:len(short) - 1)
      enddo
      if (short(len(short):len(short)) == '.') short = short(1:len(short) - 1)
      if (short(1:1) == '.') short = '0'//short
      endfunction trim_zeros
   endfunction font_attributes
endmodule foresight_font
