!< foresight_backend_pdf, PDF output device.
module foresight_backend_pdf
!< foresight_backend_pdf, PDF output device.
!<
!< One page, drawn in the pixel space of the other devices: the page's matrix maps a pixel to 0.75 pt (96 px to the
!< inch, as CSS) with y downward, so every coordinate is written as the SVG device writes it. The file is assembled in
!< memory (no dates nor random identifiers: the same figure gives the same bytes), its content stream uncompressed, and
!< renamed over `<file>` when the page ends. The plot area is a clipping path; the data in unit-square coordinates are
!< mapped to its pixels; the overlays of the SVG device (error bar caps, point type markers, arrowheads, data labels)
!< are drawn after the data, clipped to the plot area as there (markers whole across the border when one crosses it).
!< Texts are set in the 14 standard fonts (Helvetica for the sans faces, Times for the serif ones, Symbol for gnuplot's
!< `/Symbol` runs), WinAnsi encoded, placed with the compiled-in fonts' metrics. Groups hidden by the layout (a
!< `visible` false) are not drawn; hypertext, pixmaps and 3D scenes, which need a viewer or a PNG decoder, are left out.
use foresight_backend, only : arrow_head, axes_view, backend_object, sized_head
use foresight_backend_svg, only : marker_line, marker_path, segment_path, DIGIT_PITCH, POINT_OFFSET, SEGMENT_WIDTH, &
                                  SLANT
use foresight_enhanced, only : enhanced_run, enhanced_runs, has_markup, markup_width, run_face, shown
use foresight_font, only : face_of, font_object, text_advance
use foresight_fontdata, only : face_ascent, face_descent, face_line_ascent, face_line_descent, face_upm, glyph_advance, &
                              glyph_index, glyph_kern, glyph_outline
use foresight_format, only : fixed, int_str, latin1_utf8
use foresight_palette, only : named_color
use foresight_style, only : pattern_parts
use foresight_sys, only : rename_file
use foresight_texpicture, only : tex_document, tex_number, tex_visible
use foresight_math, only : any_advance, any_outline, any_upm
use foresight_textlayout, only : has_math, layout_text, math_text_width, placed_glyph
use penf, only : I1P, I4P, I8P, R8P

implicit none
private
public :: backend_pdf

real(R8P),        parameter :: PT_PER_PX = 0.75_R8P !< Points per pixel (96 px to the inch).
integer(I4P),     parameter :: CONTENT = 0_I4P      !< Destination: the page content.
integer(I4P),     parameter :: CAPS    = 1_I4P      !< Destination: the error bar caps of the plot area.
integer(I4P),     parameter :: MARKS   = 2_I4P      !< Destination: the point type markers of the plot area.
integer(I4P),     parameter :: HEADS   = 3_I4P      !< Destination: the arrowheads of the plot area.
integer(I4P),     parameter :: LABELS  = 4_I4P      !< Destination: the data labels of the plot area.
integer(I4P),     parameter :: SYMBOL_FONT = 9_I4P  !< Font resource of gnuplot's Symbol runs.
character(len=*), parameter :: BASE_FONTS(9) = [character(len=21) :: 'Helvetica', 'Helvetica-Bold', &
                                                'Helvetica-Oblique', 'Helvetica-BoldOblique', 'Times-Roman', &
                                                'Times-Bold', 'Times-Italic', 'Times-BoldItalic', 'Symbol'] !< Fonts.

type, extends(backend_object) :: backend_pdf
   !< PDF output device.
   private
   logical, public :: embed = .true. !< Texts in the compiled-in fonts, embedded (Type 3, with their Unicode), else
                                      !< the standard fonts by name (`fontnames`: Helvetica, Times, Symbol).
   real(R8P),         public :: line_scale = 1.0_R8P !< Every line width times this (gnuplot pdfcairo `linewidth`).
   real(R8P),         public :: dash_scale = 1.0_R8P !< Every dash length times this (`dashlength`).
   character(len=7),  public :: cap = 'butt'         !< Line caps and joins: `butt` (miter joins), `rounded`, `square`.
   logical,           public :: mono = .false.       !< Monochrome: lines and texts black, fills gray (`mono`).
   logical,           public :: latex = .false.      !< cairolatex: the texts into the LaTeX picture `tex_file`, not
                                                     !< drawn (the PDF its graphics).
   character(len=:), allocatable, public :: tex_file   !< The LaTeX file (cairolatex).
   character(len=:), allocatable, public :: tex_header !< LaTeX code of the picture (`header`), empty for none.
   character(len=:), allocatable, public :: tex_font   !< LaTeX font name `family,series,shape`, empty for none.
   logical,           public :: tex_standalone = .false. !< A whole LaTeX document (`standalone`), else for \input.
   logical,           public :: tex_colortext = .false.  !< Texts in their colors (`colortext`), else black.
   real(R8P),         public :: tex_size = 11.0_R8P      !< Font size of a standalone document [pt].
   character(len=:), allocatable :: file              !< Final output file.
   real(R8P)                     :: page(2) = 0.0_R8P !< Page width and height [px].
   real(R8P)                     :: area(4) = 0.0_R8P !< Current plot area: left, top, width, height [px].
   logical                       :: spill = .false.   !< A marker of the current plot area crosses its border.
   integer(I4P)                  :: depth = 0_I4P     !< Groups open.
   integer(I4P)                  :: hidden = 0_I4P    !< Depth of the hidden group drawn inside, 0 if none.
   logical                       :: fonts(9) = .false. !< Standard font resources used.
   integer(I4P)                  :: font_refs(9) = 0_I4P !< Their objects.
   ! byte buffers (nvfortran 26.9: no deferred-length character component grown, bug 34)
   integer(I1P), allocatable     :: page_bytes(:)     !< Page content stream.
   integer(I4P)                  :: page_used = 0_I4P !< Its bytes in use.
   integer(I1P), allocatable     :: caps_bytes(:)     !< Error bar caps of the plot area.
   integer(I4P)                  :: caps_used = 0_I4P !< Its bytes in use.
   integer(I1P), allocatable     :: marks_bytes(:)    !< Point type markers of the plot area.
   integer(I4P)                  :: marks_used = 0_I4P !< Its bytes in use.
   integer(I1P), allocatable     :: heads_bytes(:)    !< Arrowheads of the plot area.
   integer(I4P)                  :: heads_used = 0_I4P !< Its bytes in use.
   integer(I1P), allocatable     :: labels_bytes(:)   !< Data labels of the plot area.
   integer(I4P)                  :: labels_used = 0_I4P !< Its bytes in use.
   integer(I1P), allocatable     :: back_bytes(:)     !< cairolatex: the `\put` lines of the back texts.
   integer(I4P)                  :: back_used = 0_I4P !< Its bytes in use.
   integer(I1P), allocatable     :: front_bytes(:)    !< cairolatex: the `\put` lines of the front texts.
   integer(I4P)                  :: front_used = 0_I4P !< Its bytes in use.
   logical                       :: front = .false.   !< cairolatex: texts now in front (the panel's plot area open).
   integer(I1P), allocatable     :: object_bytes(:)   !< Objects made while drawing (images, masks, patterns), whole.
   integer(I4P)                  :: object_used = 0_I4P !< Its bytes in use.
   integer(I4P), allocatable     :: object_at(:)      !< Offset of each of those objects in object_bytes.
   integer(I4P)                  :: objects = 0_I4P   !< Objects made while drawing; the first is object 5.
   integer(I4P), allocatable     :: images(:)         !< Object numbers of the image XObjects (/Im1, /Im2...).
   integer(I4P)                  :: nimages = 0_I4P   !< Images.
   integer(I4P), allocatable     :: patterns(:)       !< Object numbers of the tiling patterns (/P1, /P2...).
   integer(I4P)                  :: npatterns = 0_I4P !< Patterns.
   integer(I4P)                  :: pattern_last = 0_I4P !< Pattern made last, 0 none.
   integer(I8P)                  :: pattern_key = -1_I8P !< Its pattern, color and width, as one number.
   ! embedded fonts: the glyphs used, in the order of their first use (each face's codes 1-255 per font object)
   integer(I4P), allocatable     :: glyph_face(:)     !< Face of each glyph used.
   integer(I4P), allocatable     :: glyph_number(:)   !< Its glyph index in the face (0: a character no face has).
   integer(I4P), allocatable     :: glyph_unicode(:)  !< The character it shows.
   integer(I4P), allocatable     :: glyph_rank(:)     !< Its rank among the face's glyphs used, from 1.
   integer(I4P)                  :: nglyphs = 0_I4P   !< Glyphs used.
   integer(I4P)                  :: face_glyphs(9) = 0_I4P !< Glyphs used of each face (9: the math font).
   integer(I4P)                  :: font_objects(9, 16) = 0_I4P !< Object number of each face's Type 3 fonts.
   real(R8P),    allocatable     :: alphas(:)         !< Opacity of each graphics state (/GS1, /GS2...).
   logical,      allocatable     :: strokes(:)        !< Whether that opacity is the stroke's (CA), else the fill's (ca).
   integer(I4P)                  :: nalphas = 0_I4P   !< Graphics states.
   contains
      ! deferred bindings
      procedure, pass(self) :: begin_page
      procedure, pass(self) :: end_page
      procedure, pass(self) :: begin_axes
      procedure, pass(self) :: end_axes
      procedure, pass(self) :: begin_group
      procedure, pass(self) :: end_group
      procedure, pass(self) :: rect
      procedure, pass(self) :: polyline
      procedure, pass(self) :: dots
      procedure, pass(self) :: polygon
      procedure, pass(self) :: image
      procedure, pass(self) :: text
      procedure, pass(self) :: begin_plot_area
      procedure, pass(self) :: end_plot_area
      procedure, pass(self) :: data_polyline
      procedure, pass(self) :: data_dots
      procedure, pass(self) :: data_bars
      procedure, pass(self) :: data_polygon
      procedure, pass(self) :: data_image
      procedure, pass(self) :: text_width
      procedure, pass(self) :: readout
      procedure, pass(self) :: readout_extent
      procedure, pass(self) :: data_arrows
      procedure, pass(self) :: data_label
      procedure, pass(self) :: front_area !< The front layer of the plot area: its clip again, after the overlays.
      procedure, pass(self) :: char_cell  !< gnuplot's character cell: its cairo terminals'.
      ! private helpers
      procedure, pass(self), private :: emit         !< Write to a destination buffer.
      procedure, pass(self), private :: text_face    !< Face of the texts written now.
      procedure, pass(self), private :: draw_text    !< A text at a pixel point, into a destination.
      procedure, pass(self), private :: tex_put      !< A text of the LaTeX picture (cairolatex).
      procedure, pass(self), private :: paint_path   !< Fill and stroke a path, into a destination.
      procedure, pass(self), private :: color_op     !< Fill or stroke color operator (with its opacity state).
      procedure, pass(self), private :: alpha_state  !< Graphics state of an opacity.
      procedure, pass(self), private :: add_object   !< Append a whole object, return its number.
      procedure, pass(self), private :: add_image    !< An image XObject (and its mask): its resource name.
      procedure, pass(self), private :: pattern_name !< A tiling pattern of a fill pattern: its resource name.
      procedure, pass(self), private :: markers      !< Point type markers at pixel points, into a destination.
      procedure, pass(self), private :: visible      !< Whether drawing is shown (no hidden group open).
      procedure, pass(self), private :: glyph_slot   !< The font resource and code of a glyph, assigned on first use.
      procedure, pass(self), private :: embed_fonts  !< The Type 3 fonts of the glyphs used, as objects.
endtype backend_pdf

contains
   ! deferred bindings
   subroutine begin_page(self, file, width, height, font_size)
   !< Start the page of `width` x `height` px for `file`, its default `font_size` [px].
   class(backend_pdf), intent(inout) :: self      !< Device.
   character(len=*),   intent(in)    :: file      !< Output file.
   real(R8P),          intent(in)    :: width     !< Page width [px].
   real(R8P),          intent(in)    :: height    !< Page height [px].
   real(R8P),          intent(in)    :: font_size !< Default font size [px].

   self%file = file
   self%page = [width, height]
   self%text_size = font_size
   self%depth = 0_I4P
   self%hidden = 0_I4P
   self%fonts = .false.
   self%page_used = 0_I4P
   self%object_used = 0_I4P
   self%tex = self%latex
   self%front = .false.
   self%back_used = 0_I4P
   self%front_used = 0_I4P
   if (.not. allocated(self%back_bytes)) allocate(self%back_bytes(4096))
   if (.not. allocated(self%front_bytes)) allocate(self%front_bytes(4096))
   self%objects = 0_I4P
   self%nimages = 0_I4P
   self%npatterns = 0_I4P
   self%pattern_last = 0_I4P
   self%pattern_key = -1_I8P
   self%nalphas = 0_I4P
   self%nglyphs = 0_I4P
   self%face_glyphs = 0_I4P
   if (allocated(self%glyph_face)) deallocate(self%glyph_face, self%glyph_number, self%glyph_unicode, self%glyph_rank)
   allocate(self%glyph_face(64), self%glyph_number(64), self%glyph_unicode(64), self%glyph_rank(64))
   if (allocated(self%object_at)) deallocate(self%object_at)
   if (allocated(self%images)) deallocate(self%images)
   if (allocated(self%patterns)) deallocate(self%patterns)
   if (allocated(self%alphas)) deallocate(self%alphas)
   if (allocated(self%strokes)) deallocate(self%strokes)
   allocate(self%object_at(16), self%images(16), self%patterns(16), self%alphas(16), self%strokes(16))
   ! pixels: 0.75 pt each, y downward from the top left corner
   call self%emit(CONTENT, num(PT_PER_PX)//' 0 0 '//num(-PT_PER_PX)//' 0 '//num(PT_PER_PX * height)//' cm'// &
                  new_line('a'))
   endsubroutine begin_page

   subroutine end_page(self)
   !< Assemble the file (header, the catalog, the page tree, the page with its resources, its content, the objects made
   !< while drawing, the cross-reference table, the trailer) and publish it atomically.
   class(backend_pdf), intent(inout) :: self      !< Device.
   integer(I1P), allocatable         :: out(:)    !< File bytes.
   integer(I4P)                      :: used      !< Bytes in use.
   integer(I4P), allocatable         :: offset(:) !< Offset of each object.
   integer(I4P)                      :: total     !< Objects.
   integer(I4P)                      :: k         !< Counter.
   integer(I4P)                      :: unit      !< File unit.
   integer(I4P)                      :: iostat    !< I/O status.
   integer(I4P)                      :: xref      !< Offset of the cross-reference table.
   character(len=256)                :: iomsg     !< I/O message.
   character(len=:), allocatable     :: resources !< Resource dictionary.

   call self%embed_fonts
   ! the standard fonts as objects (pdffonts reads font dictionaries only as indirect objects)
   self%font_refs = 0_I4P
   do k = 1_I4P, size(self%fonts, kind=I4P)
      if (.not. self%fonts(k)) cycle
      if (k == SYMBOL_FONT) then
         self%font_refs(k) = self%add_object('<< /Type /Font /Subtype /Type1 /BaseFont /'//trim(BASE_FONTS(k))//' >>')
      else
         self%font_refs(k) = self%add_object('<< /Type /Font /Subtype /Type1 /BaseFont /'//trim(BASE_FONTS(k))// &
                                             ' /Encoding /WinAnsiEncoding >>')
      endif
   enddo
   total = 4_I4P + self%objects
   allocate(offset(total), out(self%page_used + self%object_used + 4096_I4P))
   used = 0_I4P
   ! a binary comment line: the file holds 8-bit data
   call put_text('%PDF-1.4'//new_line('a')//'%')
   call put_raw([int(-30_I4P, I1P), int(-29_I4P, I1P), int(-49_I4P, I1P), int(-45_I4P, I1P)])
   call put_text(new_line('a'))
   offset(1) = used
   call put_text('1 0 obj'//new_line('a')//'<< /Type /Catalog /Pages 2 0 R >>'//new_line('a')//'endobj'// &
                 new_line('a'))
   offset(2) = used
   call put_text('2 0 obj'//new_line('a')//'<< /Type /Pages /Kids [3 0 R] /Count 1 >>'//new_line('a')//'endobj'// &
                 new_line('a'))
   resources = resource_dictionary(self)
   offset(3) = used
   call put_text('3 0 obj'//new_line('a')//'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 '// &
                 num(PT_PER_PX * self%page(1))//' '//num(PT_PER_PX * self%page(2))//'] /Resources '//resources// &
                 ' /Contents 4 0 R >>'//new_line('a')//'endobj'//new_line('a'))
   offset(4) = used
   call put_text('4 0 obj'//new_line('a')//'<< /Length '//int_str(int(self%page_used, I8P))//' >>'//new_line('a')// &
                 'stream'//new_line('a'))
   call put_buffer(self%page_bytes, self%page_used)
   call put_text(new_line('a')//'endstream'//new_line('a')//'endobj'//new_line('a'))
   do k = 1_I4P, self%objects
      offset(4_I4P + k) = used + self%object_at(k)
   enddo
   if (self%object_used > 0_I4P) call put_buffer(self%object_bytes, self%object_used)
   xref = used
   call put_text('xref'//new_line('a')//'0 '//int_str(int(total + 1_I4P, I8P))//new_line('a')// &
                 '0000000000 65535 f '//new_line('a'))
   do k = 1_I4P, total
      call put_text(digits10(offset(k))//' 00000 n '//new_line('a'))
   enddo
   call put_text('trailer'//new_line('a')//'<< /Size '//int_str(int(total + 1_I4P, I8P))//' /Root 1 0 R >>'// &
                 new_line('a')//'startxref'//new_line('a')//int_str(int(xref, I8P))//new_line('a')//'%%EOF'// &
                 new_line('a'))
   open(newunit=unit, file=self%file//'.tmp', access='stream', form='unformatted', action='write', &
        status='replace', iostat=iostat, iomsg=iomsg)
   if (iostat /= 0_I4P) error stop 'foresight: cannot open "'//self%file//'.tmp": '//trim(iomsg)
   write(unit) out(1:used)
   close(unit)
   call rename_file(self%file//'.tmp', self%file)
   if (self%latex) call write_tex
   contains
      subroutine write_tex
      !< The LaTeX picture (cairolatex): its texts, the graphics (this PDF, named as written without its extension).
      character(len=:), allocatable :: graphics !< Graphics file, without extension.
      character(len=:), allocatable :: header   !< LaTeX code.
      character(len=:), allocatable :: font     !< LaTeX font.
      integer(I4P)                  :: dot      !< Extension's dot.

      graphics = self%file
      dot = index(graphics, '.', back=.true.)
      if (dot > index(graphics, '/', back=.true.) + 1_I4P) graphics = graphics(:dot - 1_I4P)
      header = ''
      if (allocated(self%tex_header)) header = self%tex_header
      font = ''
      if (allocated(self%tex_font)) font = self%tex_font
      open(newunit=unit, file=self%tex_file//'.tmp', access='stream', form='unformatted', action='write', &
           status='replace', iostat=iostat, iomsg=iomsg)
      if (iostat /= 0_I4P) error stop 'foresight: cannot open "'//self%tex_file//'.tmp": '//trim(iomsg)
      write(unit) tex_document(bytes_text(self%back_bytes, self%back_used), &
                               bytes_text(self%front_bytes, self%front_used), PT_PER_PX * self%page(1), &
                               PT_PER_PX * self%page(2), graphics, self%tex_standalone, header, font, self%tex_size, &
                               .not. self%mono, .not. self%tex_colortext)
      close(unit)
      call rename_file(self%tex_file//'.tmp', self%tex_file)
      endsubroutine write_tex

      subroutine put_text(text)
      !< Append `text`, a character at a time.
      character(len=*), intent(in) :: text !< Text.
      integer(I4P)                 :: k    !< Character.

      do k = 1_I4P, len(text, kind=I4P)
         call put_raw([byte(iachar(text(k:k), kind=I4P))])
      enddo
      endsubroutine put_text

      subroutine put_buffer(bytes, n)
      !< Append `bytes(1:n)`, element by element: nvfortran 26.9 -O2 passed the section `bytes(1:n)` of these components
      !< one element late (its first byte lost, a zero after its last).
      integer(I1P), intent(in) :: bytes(:) !< Buffer.
      integer(I4P), intent(in) :: n        !< Bytes in use.
      integer(I4P)             :: k        !< Byte.

      call reserve(n)
      do k = 1_I4P, n
         out(used + k) = bytes(k)
      enddo
      used = used + n
      endsubroutine put_buffer

      subroutine put_raw(bytes)
      !< Append `bytes`.
      integer(I1P), intent(in) :: bytes(:) !< Bytes.

      call reserve(size(bytes, kind=I4P))
      out(used + 1_I4P:used + size(bytes, kind=I4P)) = bytes
      used = used + size(bytes, kind=I4P)
      endsubroutine put_raw

      subroutine reserve(n)
      !< Room for `n` more bytes in `out`, grown by doubling.
      integer(I4P), intent(in)  :: n        !< Bytes.
      integer(I1P), allocatable :: grown(:) !< Larger buffer.

      if (used + n > size(out, kind=I4P)) then
         allocate(grown(2_I4P * (used + n)))
         grown(1:used) = out(1:used)
         call move_alloc(grown, out)
      endif
      endsubroutine reserve
   endsubroutine end_page

   subroutine begin_axes(self, view)
   !< Open a panel: nothing to write (its geometry is the viewer's); cairolatex texts in the back until its plot area.
   class(backend_pdf), intent(inout) :: self !< Device.
   type(axes_view),    intent(in)    :: view !< Panel geometry and axis ranges.

   self%front = .false.

   endsubroutine begin_axes

   subroutine end_axes(self)
   !< Close the panel.
   class(backend_pdf), intent(inout) :: self !< Device.

   endsubroutine end_axes

   subroutine begin_group(self, name, visible, series)
   !< Open a group: drawing inside a hidden one (`visible` false) is left out.
   class(backend_pdf), intent(inout)        :: self    !< Device.
   character(len=*),   intent(in)           :: name    !< Group name.
   logical,            intent(in), optional :: visible !< Group shown.
   integer(I4P),       intent(in), optional :: series  !< Series number.

   self%depth = self%depth + 1_I4P
   if (present(visible)) then
      if (.not. visible .and. self%hidden == 0_I4P) self%hidden = self%depth
   endif
   endsubroutine begin_group

   subroutine end_group(self)
   !< Close the group.
   class(backend_pdf), intent(inout) :: self !< Device.

   if (self%hidden == self%depth) self%hidden = 0_I4P
   self%depth = max(0_I4P, self%depth - 1_I4P)
   endsubroutine end_group

   subroutine rect(self, x, y, width, height, stroke, fill, line_width)
   !< Rectangle of top-left corner (`x`, `y`) [px].
   class(backend_pdf), intent(inout) :: self       !< Device.
   real(R8P),          intent(in)    :: x          !< Left side [px].
   real(R8P),          intent(in)    :: y          !< Top side [px].
   real(R8P),          intent(in)    :: width      !< Width [px].
   real(R8P),          intent(in)    :: height     !< Height [px].
   character(len=*),   intent(in)    :: stroke     !< Stroke color.
   character(len=*),   intent(in)    :: fill       !< Fill color.
   real(R8P),          intent(in)    :: line_width !< Stroke width [px].

   call self%paint_path(CONTENT, num(x)//' '//num(y)//' '//num(width)//' '//num(height)//' re', &
                        self%theme%map(fill), 1.0_R8P, self%theme%map(stroke), line_width, '', 0_I4P)
   endsubroutine rect

   subroutine polyline(self, x, y, color, line_width, dasharray)
   !< Open polyline through the points (`x`, `y`) [px].
   class(backend_pdf), intent(inout) :: self       !< Device.
   real(R8P),          intent(in)    :: x(:)       !< Abscissae [px].
   real(R8P),          intent(in)    :: y(:)       !< Ordinates [px].
   character(len=*),   intent(in)    :: color      !< Stroke color.
   real(R8P),          intent(in)    :: line_width !< Stroke width [px].
   character(len=*),   intent(in)    :: dasharray  !< SVG dash array, empty for solid.

   if (size(x) == 0) return
   call self%paint_path(CONTENT, path_of(x, y, .false.), 'none', 1.0_R8P, self%theme%map(color), line_width, &
                        dasharray, 0_I4P)
   endsubroutine polyline

   subroutine dots(self, x, y, color, diameter, pt, line_width)
   !< Filled round dots centred on the points (`x`, `y`) [px], or point type markers.
   class(backend_pdf), intent(inout)        :: self       !< Device.
   real(R8P),          intent(in)           :: x(:)       !< Abscissae [px].
   real(R8P),          intent(in)           :: y(:)       !< Ordinates [px].
   character(len=*),   intent(in)           :: color      !< Fill color.
   real(R8P),          intent(in)           :: diameter   !< Dot diameter, or marker width [px].
   integer(I4P),       intent(in), optional :: pt         !< gnuplot point type; negative or absent: round dots.
   real(R8P),          intent(in), optional :: line_width !< Marker line width [px].
   real(R8P)                                :: width      !< Marker line width [px].
   integer(I4P)                             :: kind       !< Point type, -1 for round dots.

   kind = -1_I4P
   if (present(pt)) kind = pt
   if (kind >= 0_I4P) then
      width = marker_line(diameter, kind)
      if (present(line_width)) width = line_width
      call self%markers(CONTENT, x, y, self%theme%map(color), diameter, kind, width)
   else
      call round_dots(self, CONTENT, x, y, self%theme%map(color), diameter)
   endif
   endsubroutine dots

   subroutine polygon(self, x, y, fill, opacity, stroke, line_width, ghost)
   !< Closed polygon of the vertices (`x`, `y`) [px], filled and stroked; a ghost faintly filled only.
   class(backend_pdf), intent(inout)        :: self       !< Device.
   real(R8P),          intent(in)           :: x(:)       !< Vertex abscissae [px].
   real(R8P),          intent(in)           :: y(:)       !< Vertex ordinates [px].
   character(len=*),   intent(in)           :: fill       !< Fill color.
   real(R8P),          intent(in)           :: opacity    !< Fill opacity.
   character(len=*),   intent(in)           :: stroke     !< Border color.
   real(R8P),          intent(in)           :: line_width !< Border width [px].
   logical,            intent(in), optional :: ghost      !< Unlit cell of a segmented fill.

   if (size(x) == 0) return
   call polygon_at(self, x, y, fill, opacity, stroke, line_width, ghost)
   endsubroutine polygon

   subroutine image(self, x0, y0, x1, y1, rgba)
   !< Raster image over the box of top-left (`x0`, `y0`) and bottom-right (`x1`, `y1`) corners [px].
   class(backend_pdf), intent(inout) :: self        !< Device.
   real(R8P),          intent(in)    :: x0          !< Left [px].
   real(R8P),          intent(in)    :: y0          !< Top [px].
   real(R8P),          intent(in)    :: x1          !< Right [px].
   real(R8P),          intent(in)    :: y1          !< Bottom [px].
   integer(I4P),       intent(in)    :: rgba(:,:,:) !< Pixels.

   call draw_image(self, x0, y0, x1, y1, rgba)
   endsubroutine image

   subroutine text(self, x, y, string, anchor, sup, rotate, color)
   !< Text whose baseline passes through the anchor point (`x`, `y`) [px], ISO 8859-1 texts read as such (`latin1`).
   class(backend_pdf), intent(inout)        :: self   !< Device.
   real(R8P),          intent(in)           :: x      !< Anchor abscissa [px].
   real(R8P),          intent(in)           :: y      !< Anchor ordinate (baseline) [px].
   character(len=*),   intent(in)           :: string !< Text.
   character(len=*),   intent(in)           :: anchor !< Horizontal anchor: `start`, `middle` or `end`.
   character(len=*),   intent(in), optional :: sup    !< Superscript appended to `string`.
   real(R8P),          intent(in), optional :: rotate !< Rotation about the anchor point [deg, clockwise].
   character(len=*),   intent(in), optional :: color  !< Text color, the frame's if absent.
   character(len=:), allocatable            :: utf8   !< Text in UTF-8.
   character(len=:), allocatable            :: super  !< Superscript.
   character(len=:), allocatable            :: ink    !< Color.
   real(R8P)                                :: angle  !< Rotation [deg, clockwise].

   utf8 = string
   if (self%latin1) utf8 = latin1_utf8(string)
   super = ''
   if (present(sup)) super = sup
   angle = 0.0_R8P
   if (present(rotate)) angle = rotate
   ink = self%theme%map('black')
   if (present(color)) ink = self%theme%map(color)
   call self%draw_text(CONTENT, x, y, utf8, anchor, super, angle, ink)
   endsubroutine text

   subroutine begin_plot_area(self, x, y, width, height)
   !< Open the plot area: a clipping path over its pixels.
   class(backend_pdf), intent(inout) :: self   !< Device.
   real(R8P),          intent(in)    :: x      !< Left side [px].
   real(R8P),          intent(in)    :: y      !< Top side [px].
   real(R8P),          intent(in)    :: width  !< Width [px].
   real(R8P),          intent(in)    :: height !< Height [px].

   self%area = [x, y, width, height]
   self%spill = .false.
   self%front = .true.
   self%caps_used = 0_I4P
   self%marks_used = 0_I4P
   self%heads_used = 0_I4P
   self%labels_used = 0_I4P
   ! structure, written whatever the visibility (a hidden group may open or close around the plot area)
   call add_text(self%page_bytes, self%page_used, ('q '//clip_box(self)//new_line('a')))
   endsubroutine begin_plot_area

   subroutine end_plot_area(self)
   !< Close the plot area, then draw its overlays: caps, markers (whole across the border if one crosses it, as the SVG
   !< device), arrowheads and data labels, clipped to the plot area.
   class(backend_pdf), intent(inout) :: self !< Device.

   call add_text(self%page_bytes, self%page_used, ('Q'//new_line('a')))
   call overlay(self%caps_bytes, self%caps_used, .true.)
   call overlay(self%marks_bytes, self%marks_used, .not. self%spill)
   call overlay(self%heads_bytes, self%heads_used, .true.)
   call overlay(self%labels_bytes, self%labels_used, .true.)
   self%caps_used = 0_I4P
   self%marks_used = 0_I4P
   self%heads_used = 0_I4P
   self%labels_used = 0_I4P
   contains
      subroutine overlay(bytes, used, clipped)
      !< The overlay `bytes(1:used)`, clipped to the plot area if `clipped`; nothing if empty.
      integer(I1P), allocatable, intent(in) :: bytes(:) !< Overlay.
      integer(I4P),              intent(in) :: used     !< Bytes in use.
      logical,                   intent(in) :: clipped  !< Clipped to the plot area.

      if (used == 0_I4P) return
      if (clipped) then
         call add_text(self%page_bytes, self%page_used, ('q '//clip_box(self)//new_line('a')))
      else
         call add_text(self%page_bytes, self%page_used, ('q'//new_line('a')))
      endif
      call add_bytes(self%page_bytes, self%page_used, bytes(1:used))
      call add_text(self%page_bytes, self%page_used, ('Q'//new_line('a')))
      endsubroutine overlay
   endsubroutine end_plot_area

   subroutine data_polyline(self, x, y, color, line_width, dasharray)
   !< Open polyline through the points (`x`, `y`) [unit square], round joins (as the SVG device).
   class(backend_pdf), intent(inout) :: self       !< Device.
   real(R8P),          intent(in)    :: x(:)       !< Abscissae [unit].
   real(R8P),          intent(in)    :: y(:)       !< Ordinates [unit].
   character(len=*),   intent(in)    :: color      !< Stroke color.
   real(R8P),          intent(in)    :: line_width !< Stroke width [px].
   character(len=*),   intent(in)    :: dasharray  !< SVG dash array, empty for solid.

   if (size(x) == 0) return
   call self%paint_path(CONTENT, path_of(page_x(self, x), page_y(self, y), .false.), 'none', 1.0_R8P, &
                        self%theme%map(color), line_width, dasharray, 1_I4P)
   endsubroutine data_polyline

   subroutine data_dots(self, x, y, color, diameter, pt, line_width)
   !< Round dots in the plot area, or point type markers queued for the markers' overlay.
   class(backend_pdf), intent(inout)        :: self       !< Device.
   real(R8P),          intent(in)           :: x(:)       !< Abscissae [unit].
   real(R8P),          intent(in)           :: y(:)       !< Ordinates [unit].
   character(len=*),   intent(in)           :: color      !< Fill color.
   real(R8P),          intent(in)           :: diameter   !< Dot diameter, or marker width [px].
   integer(I4P),       intent(in), optional :: pt         !< gnuplot point type; negative or absent: round dots.
   real(R8P),          intent(in), optional :: line_width !< Marker line width [px].
   real(R8P)                                :: width      !< Marker line width [px].
   integer(I4P)                             :: kind       !< Point type, -1 for round dots.

   if (size(x) == 0) return
   kind = -1_I4P
   if (present(pt)) kind = pt
   if (kind >= 0_I4P) then
      width = marker_line(diameter, kind)
      if (present(line_width)) width = line_width
      if (any(min(x, 1.0_R8P - x) * self%area(3) < 0.71_R8P * diameter + 0.5_R8P * width .or. &
              min(y, 1.0_R8P - y) * self%area(4) < 0.71_R8P * diameter + 0.5_R8P * width)) self%spill = .true.
      call self%markers(MARKS, page_x(self, x), page_y(self, y), self%theme%map(color), diameter, kind, width)
   else
      call round_dots(self, CONTENT, page_x(self, x), page_y(self, y), self%theme%map(color), diameter)
   endif
   endsubroutine data_dots

   subroutine data_bars(self, x1, y1, x2, y2, color, line_width, cap, vertical)
   !< Error bars [unit square]: the bars in the plot area, their caps in the caps' overlay.
   class(backend_pdf), intent(inout) :: self       !< Device.
   real(R8P),          intent(in)    :: x1(:)      !< Bar start abscissae.
   real(R8P),          intent(in)    :: y1(:)      !< Bar start ordinates.
   real(R8P),          intent(in)    :: x2(:)      !< Bar end abscissae.
   real(R8P),          intent(in)    :: y2(:)      !< Bar end ordinates.
   character(len=*),   intent(in)    :: color      !< Stroke color.
   real(R8P),          intent(in)    :: line_width !< Stroke width [px].
   real(R8P),          intent(in)    :: cap        !< Cap length [px].
   logical,            intent(in)    :: vertical   !< Vertical bars (horizontal caps), else horizontal.
   character(len=:), allocatable     :: bars       !< Path of the bars.
   character(len=:), allocatable     :: ends       !< Path of the caps.
   real(R8P)                         :: p(2)       !< Bar end [px].
   real(R8P)                         :: h          !< Half cap length [px].
   integer(I4P)                      :: i          !< Counter.
   integer(I4P)                      :: e          !< End counter.

   if (size(x1) == 0) return
   bars = ''
   ends = ''
   h = 0.5_R8P * cap
   do i = 1_I4P, size(x1, kind=I4P)
      bars = bars//point(page_x1(self, x1(i)), page_y1(self, y1(i)))//' m '// &
             point(page_x1(self, x2(i)), page_y1(self, y2(i)))//' l'//new_line('a')
      do e = 1_I4P, 2_I4P
         if (e == 1_I4P) then
            p = [page_x1(self, x1(i)), page_y1(self, y1(i))]
         else
            p = [page_x1(self, x2(i)), page_y1(self, y2(i))]
         endif
         if (vertical) then
            ends = ends//point(p(1) - h, p(2))//' m '//point(p(1) + h, p(2))//' l'//new_line('a')
         else
            ends = ends//point(p(1), p(2) - h)//' m '//point(p(1), p(2) + h)//' l'//new_line('a')
         endif
      enddo
   enddo
   call self%paint_path(CONTENT, bars, 'none', 1.0_R8P, self%theme%map(color), line_width, '', 0_I4P)
   call self%paint_path(CAPS, ends, 'none', 1.0_R8P, self%theme%map(color), line_width, '', 0_I4P)
   endsubroutine data_bars

   subroutine data_polygon(self, x, y, fill, opacity, stroke, line_width, ghost)
   !< Closed polygon of the vertices (`x`, `y`) [unit square], clipped by the plot area.
   class(backend_pdf), intent(inout)        :: self       !< Device.
   real(R8P),          intent(in)           :: x(:)       !< Vertex abscissae [unit].
   real(R8P),          intent(in)           :: y(:)       !< Vertex ordinates [unit].
   character(len=*),   intent(in)           :: fill       !< Fill color.
   real(R8P),          intent(in)           :: opacity    !< Fill opacity.
   character(len=*),   intent(in)           :: stroke     !< Border color.
   real(R8P),          intent(in)           :: line_width !< Border width [px].
   logical,            intent(in), optional :: ghost      !< Unlit cell of a segmented fill.

   if (size(x) == 0) return
   call polygon_at(self, page_x(self, x), page_y(self, y), fill, opacity, stroke, line_width, ghost)
   endsubroutine data_polygon

   subroutine data_image(self, x0, y0, x1, y1, rgba)
   !< Raster image over the box of bottom-left (`x0`, `y0`) and top-right (`x1`, `y1`) corners [unit square].
   class(backend_pdf), intent(inout) :: self        !< Device.
   real(R8P),          intent(in)    :: x0          !< Left [unit].
   real(R8P),          intent(in)    :: y0          !< Bottom [unit].
   real(R8P),          intent(in)    :: x1          !< Right [unit].
   real(R8P),          intent(in)    :: y1          !< Top [unit].
   integer(I4P),       intent(in)    :: rgba(:,:,:) !< Pixels.

   call draw_image(self, page_x1(self, x0), page_y1(self, y1), page_x1(self, x1), page_y1(self, y0), rgba)
   endsubroutine data_image

   pure function text_width(self, string, sup, font_size) result(width)
   !< Width of `string` with its superscript `sup` [px], from the compiled-in fonts, as the SVG device measures it.
   class(backend_pdf), intent(in) :: self      !< Device.
   character(len=*),   intent(in) :: string    !< Text.
   character(len=*),   intent(in) :: sup       !< Superscript.
   real(R8P),          intent(in) :: font_size !< Font size [px].
   real(R8P)                      :: width     !< Width [px].
   integer(I4P)                   :: face      !< Face.

   face = self%text_face()
   if (self%latex) then
      ! LaTeX sets it: the characters gnuplot counts (strlen_tex), measured in the face
      width = text_advance(tex_visible(string), face, font_size)
      if (len(sup) > 0) width = width + text_advance(tex_visible(sup), face, 0.75_R8P * font_size)
      return
   endif
   if (.not. self%literal .and. has_math(string)) then
      ! TeX math among the text (foresight_math)
      if (self%latin1) then
         width = math_text_width(latin1_utf8(string), self%enhanced .and. has_markup(string), face, font_size, sup)
      else
         width = math_text_width(string, self%enhanced .and. has_markup(string), face, font_size, sup)
      endif
      return
   endif
   if (self%enhanced .and. .not. self%literal .and. has_markup(string)) then
      if (self%latin1) then
         width = markup_width(latin1_utf8(string), font_size, face)
      else
         width = markup_width(string, font_size, face)
      endif
   elseif (self%latin1) then
      width = text_advance(latin1_utf8(string), face, font_size)
   else
      width = text_advance(string, face, font_size)
   endif
   if (len(sup) > 0) width = width + text_advance(sup, face, 0.75_R8P * font_size)
   endfunction text_width

   subroutine readout(self, x, y, height, masks, label, prefix, suffix, color, font_size)
   !< Seven-segment readout of top-left corner (`x`, `y`) [px], as the SVG device draws it: the bold label above a glass
   !< slanted by 8 degrees, the unlit segments faint, the unit texts beside it.
   class(backend_pdf), intent(inout) :: self      !< Device.
   real(R8P),          intent(in)    :: x         !< Left side [px].
   real(R8P),          intent(in)    :: y         !< Top side [px].
   real(R8P),          intent(in)    :: height    !< Digit height [px].
   integer(I4P),       intent(in)    :: masks(:)  !< Segments of each cell.
   character(len=*),   intent(in)    :: label     !< Label, empty for none.
   character(len=*),   intent(in)    :: prefix    !< Text before the glass.
   character(len=*),   intent(in)    :: suffix    !< Text after the glass.
   character(len=*),   intent(in)    :: color     !< Color of the lit segments.
   real(R8P),          intent(in)    :: font_size !< Font size of the texts [px].
   character(len=:), allocatable     :: lit       !< Path of the lit segments.
   character(len=:), allocatable     :: ghost     !< Path of the unlit segments.
   character(len=:), allocatable     :: piece     !< Path of a segment (SVG syntax).
   real(R8P)                         :: geometry(5) !< Glass left, top, width; prefix width; label row [px].
   real(R8P)                         :: ox        !< Cell left [px].
   real(R8P)                         :: t         !< Segment thickness [px].
   integer(I4P)                      :: k         !< Cell counter.
   integer(I4P)                      :: b         !< Segment bit.
   type(font_object)                 :: kept      !< Font of the texts written now.

   geometry = glass_geometry(self, x, y, height, size(masks, kind=I4P), label, prefix, font_size)
   t = SEGMENT_WIDTH * height
   lit = ''
   ghost = ''
   do k = 1_I4P, size(masks, kind=I4P)
      ox = real(k - 1_I4P, R8P) * DIGIT_PITCH * height
      do b = 0_I4P, 7_I4P
         if (b < 7_I4P) then
            piece = segment_path(ox, b, height)
         else
            piece = 'M'//num(ox + POINT_OFFSET * height)//','//num(height - 0.5_R8P * t)//'h'//num(t)//'v'//num(t)// &
                    'h'//num(-t)//'Z'
         endif
         if (btest(masks(k), b)) then
            lit = lit//svg_path(piece)
         else
            ghost = ghost//svg_path(piece)
         endif
      enddo
   enddo
   if (len(label) > 0) then
      kept = self%font
      self%font%bold = .true.
      call self%draw_text(CONTENT, x, y + font_size, label, 'start', '', 0.0_R8P, self%theme%map('black'))
      self%font = kept
   endif
   ! the glass: translated, skewed by -8 degrees (the bottom shifted left)
   call self%emit(CONTENT, 'q 1 0 '//num(-SLANT)//' 1 '//num(geometry(1))//' '//num(geometry(2))//' cm'// &
                  new_line('a'))
   if (len(ghost) > 0) call self%paint_path(CONTENT, ghost, self%theme%map(color), self%theme%ghost, 'none', &
                                            0.0_R8P, '', 0_I4P)
   if (len(lit) > 0) call self%paint_path(CONTENT, lit, self%theme%map(color), 1.0_R8P, 'none', 0.0_R8P, '', 0_I4P)
   call self%emit(CONTENT, 'Q'//new_line('a'))
   if (len(prefix) > 0) call self%text(x, geometry(2) + height, prefix, 'start')
   if (len(suffix) > 0) call self%text(geometry(1) + geometry(3) + 0.5_R8P * font_size, geometry(2) + height, suffix, &
                                       'start')
   endsubroutine readout

   pure function readout_extent(self, height, cells, label, prefix, suffix, font_size) result(extent)
   !< Width and height [px] of a readout, as the SVG device's.
   class(backend_pdf), intent(in) :: self      !< Device.
   real(R8P),          intent(in) :: height    !< Digit height [px].
   integer(I4P),       intent(in) :: cells     !< Glass cells.
   character(len=*),   intent(in) :: label     !< Label, empty for none.
   character(len=*),   intent(in) :: prefix    !< Text before the glass.
   character(len=*),   intent(in) :: suffix    !< Text after the glass.
   real(R8P),          intent(in) :: font_size !< Font size of the texts [px].
   real(R8P)                      :: extent(2) !< Width and height [px].
   real(R8P)                      :: geometry(5) !< Glass left, top, width; prefix width; label row [px].

   geometry = glass_geometry(self, 0.0_R8P, 0.0_R8P, height, cells, label, prefix, font_size)
   extent(1) = geometry(1) + geometry(3)
   if (len(suffix) > 0) extent(1) = extent(1) + 0.5_R8P * font_size + self%text_width(suffix, '', font_size)
   if (len(label) > 0) extent(1) = max(extent(1), self%text_width(label, '', font_size))
   extent(2) = geometry(5) + (1.0_R8P + SEGMENT_WIDTH) * height
   endfunction readout_extent

   subroutine data_arrows(self, x1, y1, x2, y2, color, line_width, head, filled)
   !< Arrows [unit square]: the shafts in the plot area, the heads (their pixel size) in the heads' overlay.
   class(backend_pdf), intent(inout) :: self       !< Device.
   real(R8P),          intent(in)    :: x1(:)      !< Tail abscissae [unit].
   real(R8P),          intent(in)    :: y1(:)      !< Tail ordinates [unit].
   real(R8P),          intent(in)    :: x2(:)      !< Tip abscissae [unit].
   real(R8P),          intent(in)    :: y2(:)      !< Tip ordinates [unit].
   character(len=*),   intent(in)    :: color      !< Stroke color.
   real(R8P),          intent(in)    :: line_width !< Stroke width [px].
   integer(I4P),       intent(in)    :: head       !< Heads: 0 none, 1 end, 2 start, 3 both.
   logical,            intent(in)    :: filled     !< Filled heads.
   character(len=:), allocatable     :: shafts     !< Path of the shafts.
   real(R8P)                         :: p(2, 2)    !< Tail and tip [px].
   integer(I4P)                      :: i          !< Counter.

   if (size(x1) == 0) return
   shafts = ''
   do i = 1_I4P, size(x1, kind=I4P)
      shafts = shafts//point(page_x1(self, x1(i)), page_y1(self, y1(i)))//' m '// &
               point(page_x1(self, x2(i)), page_y1(self, y2(i)))//' l'//new_line('a')
   enddo
   call self%paint_path(CONTENT, shafts, 'none', 1.0_R8P, self%theme%map(color), line_width, '', 0_I4P)
   if (head == 0_I4P) return
   do i = 1_I4P, size(x1, kind=I4P)
      p(:, 1) = [page_x1(self, x1(i)), page_y1(self, y1(i))]
      p(:, 2) = [page_x1(self, x2(i)), page_y1(self, y2(i))]
      if (head == 1_I4P .or. head == 3_I4P) call add_head(p(:, 1), p(:, 2))
      if (head == 2_I4P .or. head == 3_I4P) call add_head(p(:, 2), p(:, 1))
   enddo
   contains
      subroutine add_head(tail, tip)
      !< The head at `tip` of the shaft from `tail`, into the heads' overlay.
      real(R8P), intent(in)         :: tail(2)     !< Tail [px].
      real(R8P), intent(in)         :: tip(2)      !< Tip [px].
      real(R8P)                     :: barbs(2, 2) !< Barb ends [px].
      character(len=:), allocatable :: d           !< Path.

      if (self%head_px(1) > 0.0_R8P) then
         call sized_head(tail, tip, self%head_px(1), self%head_px(2), barbs, fixed=self%head_fixed)
      else
         call arrow_head(tail, tip, barbs)
      endif
      d = point(barbs(1, 1), barbs(2, 1))//' m '//point(tip(1), tip(2))//' l '//point(barbs(1, 2), barbs(2, 2))//' l'
      if (filled) then
         call self%paint_path(HEADS, d//' h', self%theme%map(color), 1.0_R8P, self%theme%map(color), line_width, '', &
                              0_I4P)
      else
         call self%paint_path(HEADS, d, 'none', 1.0_R8P, self%theme%map(color), line_width, '', 0_I4P)
      endif
      endsubroutine add_head
   endsubroutine data_arrows

   subroutine data_label(self, x, y, string, anchor, rotate, color, dx, dy)
   !< Text anchored at a data point [unit square] moved by (`dx`, `dy`) [px], in the labels' overlay.
   class(backend_pdf), intent(inout) :: self   !< Device.
   real(R8P),          intent(in)    :: x      !< Anchor abscissa [unit].
   real(R8P),          intent(in)    :: y      !< Anchor ordinate [unit].
   character(len=*),   intent(in)    :: string !< Text.
   character(len=*),   intent(in)    :: anchor !< Horizontal anchor: `start`, `middle` or `end`.
   real(R8P),          intent(in)    :: rotate !< Rotation [deg, counterclockwise].
   character(len=*),   intent(in)    :: color  !< Text color.
   real(R8P),          intent(in)    :: dx     !< Horizontal offset [px].
   real(R8P),          intent(in)    :: dy     !< Vertical offset [px, downward].
   character(len=:), allocatable     :: utf8   !< Text in UTF-8.

   utf8 = string
   if (self%latin1) utf8 = latin1_utf8(string)
   call self%draw_text(LABELS, page_x1(self, x) + dx, page_y1(self, y) + dy, utf8, anchor, '', -rotate, &
                       self%theme%map(color))
   endsubroutine data_label

   subroutine front_area(self, opening, separate)
   !< Open (`opening`) or close the front layer of the plot area, drawn after its overlays (gnuplot's `front` objects
   !< over the markers): the plot area's clipping path again.
   class(backend_pdf), intent(inout) :: self     !< Device.
   logical,            intent(in)    :: opening  !< Open, else close.
   logical,            intent(out)   :: separate !< A layer of its own.

   separate = .true.
   if (opening) then
      call add_text(self%page_bytes, self%page_used, ('q '//clip_box(self)//new_line('a')))
   else
      call add_text(self%page_bytes, self%page_used, ('Q'//new_line('a')))
   endif
   endsubroutine front_area

   ! private helpers
   subroutine emit(self, destination, text)
   !< Append `text` to the `destination` buffer, unless inside a hidden group.
   class(backend_pdf), intent(inout) :: self        !< Device.
   integer(I4P),       intent(in)    :: destination !< CONTENT, CAPS, MARKS, HEADS or LABELS.
   character(len=*),   intent(in)    :: text        !< Text.

   if (.not. self%visible()) return
   select case (destination)
   case (CAPS)
      call add_text(self%caps_bytes, self%caps_used, (text))
   case (MARKS)
      call add_text(self%marks_bytes, self%marks_used, (text))
   case (HEADS)
      call add_text(self%heads_bytes, self%heads_used, (text))
   case (LABELS)
      call add_text(self%labels_bytes, self%labels_used, (text))
   case default
      call add_text(self%page_bytes, self%page_used, (text))
   endselect
   endsubroutine emit

   pure function visible(self) result(shown_now)
   !< Whether drawing is shown: no hidden group open.
   class(backend_pdf), intent(in) :: self      !< Device.
   logical                        :: shown_now !< Shown.

   shown_now = self%hidden == 0_I4P
   endfunction visible

   pure function char_cell(self, font_size) result(c)
   !< gnuplot's character cell of its cairo terminals (pdfcairo, cairolatex) at a font of `font_size` px [px], the
   !< page's family (gp_cairo_set_termvar, cairo.trm), in the terminal's units of 1/200 pt: `v_char` the height of a line
   !< (the face's hhea ascender and descender) rounded up, less a unit; `h_char` the width of "0123456789" (each advance
   !< rounded to a unit, as pango's hinted metrics) over 10, rounded up; the ticks `v_char` / 2.5. The baseline is half
   !< the nominal font size (3/4 of the drawn one: pango draws at 96 dpi) below the centre.
   class(backend_pdf), intent(in) :: self      !< Device.
   real(R8P),          intent(in) :: font_size !< Font size [px].
   real(R8P)                      :: c(5)      !< v_char, h_char, v_tic, h_tic, centre to baseline [px].
   real(R8P), parameter           :: UNITS = 200.0_R8P * PT_PER_PX !< Terminal units to the px.
   type(font_object)              :: font      !< The page's font.
   integer(I4P)                   :: face      !< Its face.
   real(R8P)                      :: em        !< Font size [units].
   integer(I8P)                   :: v         !< v_char [units].
   integer(I8P)                   :: digits    !< Width of the ten digits [units].
   integer(I4P)                   :: k         !< Digit counter.

   font%family = self%page_family
   face = face_of(font)
   em = font_size * UNITS / real(face_upm(face), R8P)
   v = ceiling(real(face_line_ascent(face) - face_line_descent(face), R8P) * em, I8P) - 1_I8P
   digits = 0_I8P
   do k = 0_I4P, 9_I4P
      digits = digits + nint(real(glyph_advance(face, glyph_index(face, 48_I4P + k)), R8P) * em, I8P)
   enddo
   c(1) = real(v, R8P) / UNITS
   c(2) = real(ceiling(real(digits, R8P) / 10.0_R8P, I8P), R8P) / UNITS
   c(3) = real(int(real(v, R8P) / 2.5_R8P, I8P), R8P) / UNITS
   c(4) = c(3)
   c(5) = 0.375_R8P * font_size
   endfunction char_cell

   pure function text_face(self) result(face)
   !< The compiled-in face (1-8) of the texts written now: `self%font`, its family the page's when unset.
   class(backend_pdf), intent(in) :: self !< Device.
   integer(I4P)                   :: face !< Face.
   type(font_object)              :: font !< Font of the texts written now.

   font = self%font
   if (len_trim(font%family) == 0) font%family = self%page_family
   face = face_of(font)
   endfunction text_face

   subroutine draw_text(self, destination, x, y, string, anchor, sup, rotate, color)
   !< The UTF-8 `string` with its superscript `sup`, its baseline through (`x`, `y`) [px] anchored by `anchor`, rotated
   !< by `rotate` [deg, clockwise] about that point, in `color`, into `destination`: enhanced text by its runs (their
   !< sizes, shifts, step-backs, faces; invisible ones skipped), each run in the standard font of its face (Symbol for
   !< gnuplot's Symbol runs), placed by the compiled-in fonts' advances; a boxed text over the page color.
   class(backend_pdf), intent(inout) :: self        !< Device.
   integer(I4P),       intent(in)    :: destination !< Destination buffer.
   real(R8P),          intent(in)    :: x           !< Anchor abscissa [px].
   real(R8P),          intent(in)    :: y           !< Baseline [px].
   character(len=*),   intent(in)    :: string      !< Text, UTF-8.
   character(len=*),   intent(in)    :: anchor      !< `start`, `middle` or `end`.
   character(len=*),   intent(in)    :: sup         !< Superscript, empty for none.
   real(R8P),          intent(in)    :: rotate      !< Rotation [deg, clockwise].
   character(len=*),   intent(in)    :: color       !< Color.
   type(enhanced_run), allocatable   :: runs(:)     !< Runs.
   character(len=:), allocatable     :: ops         !< Text operators.
   real(R8P)                         :: base        !< Base font size [px].
   real(R8P)                         :: width       !< Whole width [px].
   real(R8P)                         :: at          !< Pen position along the baseline [px].
   real(R8P)                         :: c           !< Cosine of the rotation.
   real(R8P)                         :: s           !< Sine of the rotation.
   real(R8P)                         :: w           !< A run's width [px].
   integer(I4P)                      :: face        !< Base face.
   integer(I4P)                      :: f           !< A run's face.
   integer(I4P)                      :: k           !< Counter.

   if (len(string) == 0 .and. len(sup) == 0) return
   face = self%text_face()
   base = self%font%size_px(self%text_size)
   if (self%latex) then
      if (self%visible()) call self%tex_put(x, y, string, anchor, sup, rotate, color, base)
      return
   endif
   c = cos(rotate * acos(-1.0_R8P) / 180.0_R8P)
   s = sin(rotate * acos(-1.0_R8P) / 180.0_R8P)
   if (.not. self%literal .and. has_math(string)) then
      call math_text
      return
   endif
   if (self%enhanced .and. .not. self%literal .and. has_markup(string)) then
      call enhanced_runs(string, runs)
   else
      allocate(runs(1))
      runs(1)%text = string
      runs(1)%family = ''
   endif
   width = 0.0_R8P
   do k = 1_I4P, size(runs, kind=I4P)
      width = width - runs(k)%back * base + text_advance(shown(runs(k)), run_face(runs(k), face), runs(k)%size * base)
   enddo
   if (len(sup) > 0) width = width + text_advance(sup, face, 0.75_R8P * base)
   at = 0.0_R8P
   if (anchor == 'middle') at = -0.5_R8P * width
   if (anchor == 'end') at = -width
   if (self%boxed) call box_under(at, width)
   ops = 'BT'//new_line('a')
   do k = 1_I4P, size(runs, kind=I4P)
      at = at - runs(k)%back * base
      f = run_face(runs(k), face)
      w = text_advance(shown(runs(k)), f, runs(k)%size * base)
      if (.not. runs(k)%hidden .and. len(runs(k)%text) > 0) &
         ops = ops//show(f, runs(k)%size * base, at, -runs(k)%shift * base, runs(k))
      at = at + w
   enddo
   if (len(sup) > 0) then
      deallocate(runs)
      allocate(runs(1))
      runs(1)%text = sup
      runs(1)%family = ''
      ops = ops//show(face, 0.75_R8P * base, at, -0.3375_R8P * base, runs(1))
   endif
   ops = ops//'ET'//new_line('a')
   call self%emit(destination, 'q '//self%color_op(color, .false.)//new_line('a')//ops//'Q'//new_line('a'))
   contains
      subroutine math_text
      !< A text holding TeX math (foresight_textlayout with `math`): each glyph in its embedded Type 3 font (the math
      !< font's too, whatever `embed`), the formulas' rules filled, in the text's frame.
      type(placed_glyph), allocatable :: placed(:) !< Glyphs and rules.
      character(len=:), allocatable   :: name      !< Font resource of a glyph.
      integer(I4P)                    :: count     !< Glyphs placed.
      integer(I4P)                    :: slot      !< Its code.
      integer(I4P)                    :: j         !< Glyph.
      real(R8P)                       :: start     !< Text start from the anchor [px].
      real(R8P)                       :: along     !< A glyph along the baseline [px].

      call layout_text(string, self%enhanced .and. has_markup(string), face, base, sup, placed, count, width, &
                       math=.true.)
      start = 0.0_R8P
      if (anchor == 'middle') start = -0.5_R8P * width
      if (anchor == 'end') start = -width
      if (self%boxed) call box_under(start, width)
      ops = ''
      do j = 1_I4P, count
         along = start + placed(j)%x
         if (placed(j)%face == 0_I4P) then
            if (placed(j)%width > 0.0_R8P) &
               ops = ops//'q '//num(c)//' '//num(s)//' '//num(s)//' '//num(-c)//' '//num(x)//' '//num(y)//' cm '// &
                     num(along)//' '//num(-placed(j)%y - placed(j)%height)//' '//num(placed(j)%width)//' '// &
                     num(placed(j)%height)//' re f Q'//new_line('a')
            cycle
         endif
         call self%glyph_slot(placed(j)%face, placed(j)%glyph, placed(j)%unicode, name, slot)
         ops = ops//'BT /'//name//' '//num(placed(j)%size)//' Tf '//num(c)//' '//num(s)//' '//num(s)//' '// &
               num(-c)//' '//num(x + c * along - s * placed(j)%y)//' '//num(y + s * along + c * placed(j)%y)// &
               ' Tm <'//hex2(slot)//'> Tj ET'//new_line('a')
      enddo
      call self%emit(destination, 'q '//self%color_op(color, .false.)//new_line('a')//ops//'Q'//new_line('a'))
      endsubroutine math_text

      function show(face_k, font_size, along, up, run) result(op)
      !< Operators of `run` in `face_k` at `font_size`, at `along` px along the baseline and `up` px across it (negative:
      !< up) from the anchor: the embedded glyphs (each character's font and code, kerned by TJ adjustments), or the
      !< standard font of the face (the Symbol font for gnuplot's Symbol runs).
      integer(I4P),       intent(in) :: face_k    !< Face 1-8.
      real(R8P),          intent(in) :: font_size !< Size [px].
      real(R8P),          intent(in) :: along     !< Along the baseline [px].
      real(R8P),          intent(in) :: up        !< Across it [px, downward].
      type(enhanced_run), intent(in) :: run       !< Run.
      character(len=:), allocatable  :: op        !< Operators.
      character(len=:), allocatable  :: chars     !< Characters drawn, UTF-8.
      character(len=:), allocatable  :: font      !< Font resource of the open TJ.
      character(len=:), allocatable  :: name      !< Font resource of a character.
      integer(I4P)                   :: j         !< Byte.
      integer(I4P)                   :: n         !< Bytes of a character.
      integer(I4P)                   :: code      !< Code point.
      integer(I4P)                   :: slot      !< Code in its font.
      integer(I4P)                   :: g         !< Glyph index.
      integer(I4P)                   :: owner     !< Face holding the glyph.
      integer(I4P)                   :: previous  !< Previous glyph of the same face, 0 none.
      integer(I4P)                   :: kern      !< Kerning [font units].

      ! the glyphs upright in the flipped page: x along (cos, sin), y across (sin, -cos)
      op = num(c)//' '//num(s)//' '//num(s)//' '//num(-c)//' '//num(x + c * along - s * up)//' '// &
           num(y + s * along + c * up)//' Tm'//new_line('a')
      if (.not. self%embed) then
         if (run%symbol) then
            self%fonts(SYMBOL_FONT) = .true.
            op = '/F'//int_str(int(SYMBOL_FONT, I8P))//' '//num(font_size)//' Tf '//op//'('// &
                 pdf_string(run%text, .true.)//') Tj'//new_line('a')
         else
            self%fonts(face_k) = .true.
            op = '/F'//int_str(int(face_k, I8P))//' '//num(font_size)//' Tf '//op//'('// &
                 pdf_string(run%text, .false.)//') Tj'//new_line('a')
         endif
         return
      endif
      chars = shown(run)
      font = ''
      previous = 0_I4P
      j = 1_I4P
      do while (j <= len(chars, kind=I4P))
         call decode(chars, j, code, n)
         j = j + n
         owner = face_k
         g = glyph_index(face_k, code)
         if (g == 0_I4P .and. face_k <= 4_I4P) then
            ! a character Liberation Sans lacks: Latin Modern's of the same style (text_advance's rule)
            g = glyph_index(face_k + 4_I4P, code)
            if (g > 0_I4P) owner = face_k + 4_I4P
         endif
         call self%glyph_slot(owner, g, code, name, slot)
         kern = 0_I4P
         if (owner == face_k .and. previous > 0_I4P .and. g > 0_I4P) kern = glyph_kern(face_k, previous, g)
         if (name /= font) then
            if (len(font) > 0) op = op//'] TJ'//new_line('a')
            op = op//'/'//name//' '//num(font_size)//' Tf ['
            font = name
         elseif (kern /= 0_I4P) then
            ! TJ adjustments in thousandths of the font size, positive to the left
            op = op//' '//num(-1000.0_R8P * real(kern, R8P) / real(face_upm(face_k), R8P))//' '
         endif
         op = op//'<'//hex2(slot)//'>'
         previous = 0_I4P
         if (owner == face_k) previous = g
      enddo
      if (len(font) > 0) op = op//'] TJ'//new_line('a')
      endfunction show

      subroutine box_under(left, extent)
      !< The page color under the text's box (gnuplot's svg textbox: no border nor margin).
      real(R8P), intent(in) :: left   !< Box left from the anchor [px].
      real(R8P), intent(in) :: extent !< Box width [px].
      real(R8P)             :: top    !< Box top from the baseline [px, downward].
      real(R8P)             :: bottom !< Box bottom from the baseline [px, downward].

      top = -base * real(face_ascent(face), R8P) / real(face_upm(face), R8P)
      bottom = -base * real(face_descent(face), R8P) / real(face_upm(face), R8P)
      call self%emit(destination, 'q '//self%color_op(self%theme%map('white'), .false.)//' '//num(c)//' '//num(s)// &
                     ' '//num(-s)//' '//num(c)//' '//num(x)//' '//num(y)//' cm '//num(left)//' '//num(top)//' '// &
                     num(extent)//' '//num(bottom - top)//' re f Q'//new_line('a'))
      endsubroutine box_under
   endsubroutine draw_text

   subroutine tex_put(self, x, y, string, anchor, sup, rotate, color, base)
   !< The text `string` (LaTeX, its superscript `sup` raised) of the LaTeX picture, as gnuplot's epslatex texts: its
   !< center (gnuplot's vertical anchor, 0.35 `base` above foresight's baseline) by `\put` in 0.05 bp from the bottom
   !< left, `\makebox(0,0)[l|r]{\strut{}...}` (a text opening with `{` or `[` its own box), `\rotatebox` [deg,
   !< counterclockwise], its color by `\colorrgb` (shown or not by `\ifGPblacktext`), else the frame's; in the back
   !< texts until the panel's plot area opens.
   class(backend_pdf), intent(inout) :: self   !< Device.
   real(R8P),          intent(in)    :: x      !< Anchor abscissa [px].
   real(R8P),          intent(in)    :: y      !< Baseline [px].
   character(len=*),   intent(in)    :: string !< Text, LaTeX.
   character(len=*),   intent(in)    :: anchor !< `start`, `middle` or `end`.
   character(len=*),   intent(in)    :: sup    !< Superscript, empty for none.
   real(R8P),          intent(in)    :: rotate !< Rotation [deg, clockwise].
   character(len=*),   intent(in)    :: color  !< Color.
   real(R8P),          intent(in)    :: base   !< Font size [px].
   character(len=1),   parameter     :: BS = achar(92)     !< Backslash.
   character(len=1),   parameter     :: NL = new_line('a') !< Line end.
   character(len=:), allocatable     :: body   !< Text.
   character(len=:), allocatable     :: box    !< Its box.
   character(len=:), allocatable     :: line   !< Lines written.
   real(R8P)                         :: a      !< Rotation [rad].
   integer(I4P)                      :: c(3)   !< Color channels.
   logical                           :: ok     !< Color known.

   a = rotate * acos(-1.0_R8P) / 180.0_R8P
   body = string
   if (len(sup) > 0) body = body//'$^{'//sup//'}$'
   if (body(1:1) == '{' .or. body(1:1) == '[') then
      box = BS//'makebox(0,0)'//body
   elseif (anchor == 'start') then
      box = BS//'makebox(0,0)[l]{'//BS//'strut{}'//body//'}'
   elseif (anchor == 'end') then
      box = BS//'makebox(0,0)[r]{'//BS//'strut{}'//body//'}'
   else
      box = BS//'makebox(0,0){'//BS//'strut{}'//body//'}'
   endif
   if (rotate /= 0.0_R8P) box = BS//'rotatebox{'//tex_number(-rotate)//'}{'//box//'}'
   call named_color(trim(color), c, ok)
   if (.not. ok) c = 0_I4P
   if (any(c /= 0_I4P)) then
      line = '      '//BS//'colorrgb{'//tex_number(real(c(1), R8P) / 255.0_R8P)//','// &
             tex_number(real(c(2), R8P) / 255.0_R8P)//','//tex_number(real(c(3), R8P) / 255.0_R8P)//'}%%'//NL
   else
      line = '      '//BS//'csname LTb'//BS//'endcsname%%'//NL
   endif
   line = line//'      '//BS//'put('// &
          int_str(nint(20.0_R8P * PT_PER_PX * (x + 0.35_R8P * base * sin(a)), I8P))//','// &
          int_str(nint(20.0_R8P * PT_PER_PX * (self%page(2) - y + 0.35_R8P * base * cos(a)), I8P))//'){'//box//'}%'//NL
   if (self%front) then
      call add_text(self%front_bytes, self%front_used, (line))
   else
      call add_text(self%back_bytes, self%back_used, (line))
   endif
   endsubroutine tex_put

   subroutine paint_path(self, destination, path, fill, opacity, stroke, line_width, dasharray, join)
   !< Fill (`fill` at `opacity`, unless `none`) and stroke (`stroke` `line_width` px wide, dashed by the SVG
   !< `dasharray`, unless `none`) the `path` (PDF path operators, closed by the caller where needed), into
   !< `destination`, in its own graphics state; `join` 0 miter, 1 round.
   class(backend_pdf), intent(inout) :: self        !< Device.
   integer(I4P),       intent(in)    :: destination !< Destination buffer.
   character(len=*),   intent(in)    :: path        !< Path operators.
   character(len=*),   intent(in)    :: fill        !< Fill color, a pattern fill, or `none`.
   real(R8P),          intent(in)    :: opacity     !< Fill opacity.
   character(len=*),   intent(in)    :: stroke      !< Stroke color or `none`.
   real(R8P),          intent(in)    :: line_width  !< Stroke width [px].
   character(len=*),   intent(in)    :: dasharray   !< SVG dash array, empty for solid.
   integer(I4P),       intent(in)    :: join        !< Line join.
   character(len=:), allocatable     :: state       !< Graphics state operators.
   character(len=:), allocatable     :: operator    !< Painting operator.
   character(len=:), allocatable     :: pattern     !< Pattern resource, empty for none.
   character(len=:), allocatable     :: color       !< Pattern color.
   integer(I4P)                      :: kind        !< Pattern number, 0 for a plain color.
   logical                           :: filled      !< Filled.
   logical                           :: stroked     !< Stroked.

   if (.not. self%visible()) return
   call pattern_parts(fill, kind, color)
   filled = trim(fill) /= 'none' .and. trim(fill) /= 'transparent' .and. opacity > 0.0_R8P
   stroked = trim(stroke) /= 'none' .and. trim(stroke) /= 'transparent' .and. line_width > 0.0_R8P
   if (.not. (filled .or. stroked)) return
   state = 'q'
   pattern = ''
   if (filled) then
      if (kind > 0_I4P) then
         pattern = self%pattern_name(kind, self%theme%map(color), line_width)
         state = state//' /Pattern cs /'//pattern//' scn'
      else
         state = state//' '//self%color_op(fill, .false.)
         if (opacity < 1.0_R8P) state = state//' /'//self%alpha_state(opacity, .false.)//' gs'
      endif
   endif
   if (stroked) then
      state = state//' '//self%color_op(stroke, .true.)//' '//num(self%line_scale * line_width)//' w'
      select case (trim(self%cap))
      case ('rounded')
         state = state//' 1 J 1 j'
      case ('square')
         state = state//' 2 J'
         if (join == 1_I4P) state = state//' 1 j'
      case default
         if (join == 1_I4P) state = state//' 1 j'
      endselect
      if (len(dasharray) > 0) state = state//' ['//dashes(dasharray, self%dash_scale * self%line_scale)//'] 0 d'
   endif
   if (filled .and. stroked) then
      operator = 'B'
   elseif (filled) then
      operator = 'f'
   else
      operator = 'S'
   endif
   call self%emit(destination, state//new_line('a')//path//new_line('a')//operator//' Q'//new_line('a'))
   endsubroutine paint_path

   function color_op(self, color, stroke) result(op)
   !< `r g b rg` (or `RG` for a `stroke`) of the color `color`, `#rrggbbaa` with its opacity state; unknown colors black.
   class(backend_pdf), intent(inout) :: self   !< Device.
   character(len=*),   intent(in)    :: color  !< Color.
   logical,            intent(in)    :: stroke !< Stroke color, else fill.
   character(len=:), allocatable     :: op     !< Operators.
   integer(I4P)                      :: c(3)   !< Channels.
   integer(I4P)                      :: alpha  !< Alpha, 255 opaque.
   logical                           :: ok     !< Color known.

   alpha = 255_I4P
   if (len_trim(color) == 9 .and. color(1:1) == '#') then
      call named_color(color(1:7), c, ok)
      read(color(8:9), '(Z2)') alpha
   else
      call named_color(trim(color), c, ok)
   endif
   if (.not. ok) c = 0_I4P
   if (self%mono) then
      ! gnuplot's mono: lines and texts black, fills (and white) by their gray
      if (stroke .and. any(c < 250_I4P)) then
         c = 0_I4P
      else
         c = nint(0.299_R8P * c(1) + 0.587_R8P * c(2) + 0.114_R8P * c(3), I4P)
      endif
   endif
   op = num(real(c(1), R8P) / 255.0_R8P)//' '//num(real(c(2), R8P) / 255.0_R8P)//' '// &
        num(real(c(3), R8P) / 255.0_R8P)//merge(' RG', ' rg', stroke)
   if (alpha < 255_I4P) op = op//' /'//self%alpha_state(real(alpha, R8P) / 255.0_R8P, stroke)//' gs'
   endfunction color_op

   function alpha_state(self, alpha, stroke) result(name)
   !< The graphics state resource (`GS<n>`) of the fill (or `stroke`) opacity `alpha`, made once.
   class(backend_pdf), intent(inout) :: self   !< Device.
   real(R8P),          intent(in)    :: alpha  !< Opacity.
   logical,            intent(in)    :: stroke !< Stroke opacity, else fill.
   character(len=:), allocatable     :: name   !< Resource name.
   real(R8P),    allocatable         :: grown(:) !< Larger list.
   logical,      allocatable         :: kinds(:) !< Larger list.
   integer(I4P)                      :: k      !< Counter.
   real(R8P)                         :: a      !< Opacity rounded as written.

   a = real(nint(alpha * 1000.0_R8P), R8P) / 1000.0_R8P
   do k = 1_I4P, self%nalphas
      if (self%alphas(k) == a .and. (self%strokes(k) .eqv. stroke)) then
         name = 'GS'//int_str(int(k, I8P))
         return
      endif
   enddo
   if (self%nalphas == size(self%alphas, kind=I4P)) then
      allocate(grown(2_I4P * self%nalphas), kinds(2_I4P * self%nalphas))
      grown(1:self%nalphas) = self%alphas(1:self%nalphas)
      kinds(1:self%nalphas) = self%strokes(1:self%nalphas)
      call move_alloc(grown, self%alphas)
      call move_alloc(kinds, self%strokes)
   endif
   self%nalphas = self%nalphas + 1_I4P
   self%alphas(self%nalphas) = a
   self%strokes(self%nalphas) = stroke
   name = 'GS'//int_str(int(self%nalphas, I8P))
   endfunction alpha_state

   function add_object(self, body, stream) result(number)
   !< Append the object `body` (a dictionary), followed by `stream` if present, as the next object made while drawing:
   !< its number (5 the first).
   class(backend_pdf), intent(inout)        :: self      !< Device.
   character(len=*),   intent(in)           :: body      !< Dictionary.
   integer(I1P),       intent(in), optional :: stream(:) !< Stream data.
   integer(I4P)                             :: number    !< Object number.
   integer(I4P), allocatable                :: grown(:)  !< Larger list.

   if (self%objects == size(self%object_at, kind=I4P)) then
      allocate(grown(2_I4P * self%objects))
      grown(1:self%objects) = self%object_at(1:self%objects)
      call move_alloc(grown, self%object_at)
   endif
   self%objects = self%objects + 1_I4P
   self%object_at(self%objects) = self%object_used
   number = 4_I4P + self%objects
   call add_text(self%object_bytes, self%object_used, int_str(int(number, I8P))//' 0 obj'//new_line('a')//body)
   if (present(stream)) then
      call add_text(self%object_bytes, self%object_used, (new_line('a')//'stream'//new_line('a')))
      call add_bytes(self%object_bytes, self%object_used, stream)
      call add_text(self%object_bytes, self%object_used, (new_line('a')//'endstream'))
   endif
   call add_text(self%object_bytes, self%object_used, (new_line('a')//'endobj'//new_line('a')))
   endfunction add_object

   function add_image(self, rgba) result(name)
   !< An image XObject of `rgba(channel, column, row)` (rows top to bottom), 8-bit RGB samples uncompressed, with a soft
   !< mask of its alpha when not opaque: its resource name (`Im<n>`).
   class(backend_pdf), intent(inout) :: self        !< Device.
   integer(I4P),       intent(in)    :: rgba(:,:,:) !< Pixels.
   character(len=:), allocatable     :: name        !< Resource name.
   character(len=:), allocatable     :: mask        !< Soft mask entry.
   integer(I1P), allocatable         :: samples(:)  !< Samples.
   integer(I4P), allocatable         :: grown(:)    !< Larger list.
   integer(I4P)                      :: columns     !< Columns.
   integer(I4P)                      :: rows        !< Rows.
   integer(I4P)                      :: i           !< Column.
   integer(I4P)                      :: j           !< Row.
   integer(I4P)                      :: k           !< Sample.

   columns = size(rgba, 2, kind=I4P)
   rows = size(rgba, 3, kind=I4P)
   mask = ''
   if (any(rgba(4, :, :) < 255_I4P)) then
      allocate(samples(columns * rows))
      k = 0_I4P
      do j = 1_I4P, rows
         do i = 1_I4P, columns
            k = k + 1_I4P
            samples(k) = byte(rgba(4, i, j))
         enddo
      enddo
      mask = ' /SMask '//int_str(int(self%add_object('<< /Type /XObject /Subtype /Image /Width '// &
                                                     int_str(int(columns, I8P))//' /Height '//int_str(int(rows, I8P))// &
                                                     ' /ColorSpace /DeviceGray /BitsPerComponent 8 /Length '// &
                                                     int_str(int(size(samples), I8P))//' >>', samples), I8P))//' 0 R'
      deallocate(samples)
   endif
   allocate(samples(3_I4P * columns * rows))
   k = 0_I4P
   do j = 1_I4P, rows
      do i = 1_I4P, columns
         samples(k + 1_I4P:k + 3_I4P) = [byte(rgba(1, i, j)), byte(rgba(2, i, j)), byte(rgba(3, i, j))]
         k = k + 3_I4P
      enddo
   enddo
   if (self%nimages == size(self%images, kind=I4P)) then
      allocate(grown(2_I4P * self%nimages))
      grown(1:self%nimages) = self%images(1:self%nimages)
      call move_alloc(grown, self%images)
   endif
   self%nimages = self%nimages + 1_I4P
   self%images(self%nimages) = self%add_object('<< /Type /XObject /Subtype /Image /Width '// &
                                               int_str(int(columns, I8P))//' /Height '//int_str(int(rows, I8P))// &
                                               ' /ColorSpace /DeviceRGB /BitsPerComponent 8 /Interpolate false'// &
                                               mask//' /Length '//int_str(int(size(samples), I8P))//' >>', samples)
   name = 'Im'//int_str(int(self%nimages, I8P))
   endfunction add_image

   function pattern_name(self, kind, color, line_width) result(name)
   !< The tiling pattern of gnuplot's fill pattern `kind` in `color`, lines `line_width` px wide (1 px if not positive):
   !< the 8 px tile of the SVG device, in page pixels; made again only when pattern, color or width change.
   class(backend_pdf), intent(inout) :: self       !< Device.
   integer(I4P),       intent(in)    :: kind       !< Pattern number.
   character(len=*),   intent(in)    :: color      !< Line color.
   real(R8P),          intent(in)    :: line_width !< Line width [px].
   character(len=:), allocatable     :: name       !< Resource name.
   character(len=:), allocatable     :: lines      !< Tile path.
   character(len=:), allocatable     :: tile       !< Tile content.
   integer(I4P), allocatable         :: grown(:)   !< Larger list.
   integer(I8P)                      :: key        !< Pattern, color and width.
   integer(I4P)                      :: c(3)       !< Channels.
   real(R8P)                         :: width      !< Line width [px].
   logical                           :: ok         !< Color known.

   width = 1.0_R8P
   if (line_width > 0.0_R8P) width = line_width
   call named_color(color(1:min(7, len_trim(color))), c, ok)
   key = int(kind, I8P) + 16_I8P * (int(c(1), I8P) + 256_I8P * (int(c(2), I8P) + 256_I8P * int(c(3), I8P))) + &
         268435456_I8P * int(nint(width * 100.0_R8P), I8P)
   if (self%pattern_last > 0_I4P .and. key == self%pattern_key) then
      name = 'P'//int_str(int(self%pattern_last, I8P))
      return
   endif
   select case (kind)
   case (1_I4P)
      lines = 'M0,0 L8,8 M0,8 L8,0'
   case (2_I4P)
      lines = 'M0,0 L8,8 M0,8 L8,0 M0,4 L4,8 L8,4 L4,0 L0,4'
   case (4_I4P)
      lines = 'M-4,0 L8,12 M0,-4 L12,8'
   case (5_I4P)
      lines = 'M-4,8 L8,-4 M0,12 L12,0'
   case (6_I4P)
      lines = 'M-2,8 L4,-4 M0,12 L8,-4 M4,12 L10,0'
   case default
      lines = 'M-2,0 L4,12 M0,-4 L8,12 M4,-4 L10,8'
   endselect
   tile = self%color_op(color(1:min(7, len_trim(color))), .true.)//' '//num(width)//' w '//svg_path(lines)//' S'
   if (self%npatterns == size(self%patterns, kind=I4P)) then
      allocate(grown(2_I4P * self%npatterns))
      grown(1:self%npatterns) = self%patterns(1:self%npatterns)
      call move_alloc(grown, self%patterns)
   endif
   self%npatterns = self%npatterns + 1_I4P
   ! pattern space is the page's default space: the tile in pixels, y downward from the top left corner
   self%patterns(self%npatterns) = self%add_object('<< /Type /Pattern /PatternType 1 /PaintType 1 /TilingType 1 '// &
                                                   '/BBox [0 0 8 8] /XStep 8 /YStep 8 /Resources << >> /Matrix ['// &
                                                   num(PT_PER_PX)//' 0 0 '//num(-PT_PER_PX)//' 0 '// &
                                                   num(PT_PER_PX * self%page(2))//'] /Length '// &
                                                   int_str(int(len(tile), I8P))//' >>', text_bytes(tile))
   self%pattern_last = self%npatterns
   self%pattern_key = key
   name = 'P'//int_str(int(self%npatterns, I8P))
   endfunction pattern_name

   subroutine markers(self, destination, x, y, color, diameter, pt, line_width)
   !< The markers of gnuplot point type `pt` (`marker_path`, the SVG device's shapes) centred on (`x`, `y`) [px], into
   !< `destination`: the filled shapes (the dot, odd types from 5) filled and stroked, the others stroked.
   class(backend_pdf), intent(inout) :: self        !< Device.
   integer(I4P),       intent(in)    :: destination !< Destination buffer.
   real(R8P),          intent(in)    :: x(:)        !< Abscissae [px].
   real(R8P),          intent(in)    :: y(:)        !< Ordinates [px].
   character(len=*),   intent(in)    :: color       !< Color.
   real(R8P),          intent(in)    :: diameter    !< Marker width [px].
   integer(I4P),       intent(in)    :: pt          !< Point type, >= 0.
   real(R8P),          intent(in)    :: line_width  !< Line width [px].
   character(len=:), allocatable     :: d           !< Path.
   integer(I4P)                      :: shape       !< Shape: 0 the dot, 1..15.
   integer(I4P)                      :: i           !< Counter.

   if (size(x) == 0) return
   shape = 0_I4P
   if (pt > 0_I4P) shape = modulo(pt - 1_I4P, 15_I4P) + 1_I4P
   d = ''
   do i = 1_I4P, size(x, kind=I4P)
      d = d//svg_path(marker_path(x(i), y(i), 0.5_R8P * diameter, shape))
   enddo
   if (shape == 0_I4P .or. modulo(shape, 2_I4P) == 1_I4P .and. shape >= 5_I4P) then
      call self%paint_path(destination, d, color, 1.0_R8P, color, line_width, '', 0_I4P)
   else
      call self%paint_path(destination, d, 'none', 1.0_R8P, color, line_width, '', 0_I4P)
   endif
   endsubroutine markers

   subroutine glyph_slot(self, face, glyph, unicode, name, code)
   !< The font resource `name` (`E<face>_<n>`) and `code` (1-255) of the glyph `glyph` of `face` showing `unicode`
   !< (glyph 0: a character no face has, drawn as nothing 0.556 em wide), assigned on its first use.
   class(backend_pdf), intent(inout)          :: self    !< Device.
   integer(I4P),       intent(in)             :: face    !< Face, 1-8.
   integer(I4P),       intent(in)             :: glyph   !< Glyph index, 0 none.
   integer(I4P),       intent(in)             :: unicode !< Character.
   character(len=:), allocatable, intent(out) :: name    !< Font resource.
   integer(I4P),       intent(out)            :: code    !< Code in that font.
   integer(I4P), allocatable                  :: grown(:) !< Larger list.
   integer(I4P)                               :: k       !< Counter.
   integer(I4P)                               :: rank    !< Rank among the face's glyphs.

   rank = 0_I4P
   do k = 1_I4P, self%nglyphs
      if (self%glyph_face(k) == face .and. self%glyph_number(k) == glyph) then
         ! a glyph shows one character (ToUnicode); a missing one is a slot per character
         if (glyph > 0_I4P .or. self%glyph_unicode(k) == unicode) then
            rank = self%glyph_rank(k)
            exit
         endif
      endif
   enddo
   if (rank == 0_I4P) then
      if (self%nglyphs == size(self%glyph_face, kind=I4P)) then
         allocate(grown(2_I4P * self%nglyphs))
         grown(1:self%nglyphs) = self%glyph_face(1:self%nglyphs)
         call move_alloc(grown, self%glyph_face)
         allocate(grown(2_I4P * self%nglyphs))
         grown(1:self%nglyphs) = self%glyph_number(1:self%nglyphs)
         call move_alloc(grown, self%glyph_number)
         allocate(grown(2_I4P * self%nglyphs))
         grown(1:self%nglyphs) = self%glyph_unicode(1:self%nglyphs)
         call move_alloc(grown, self%glyph_unicode)
         allocate(grown(2_I4P * self%nglyphs))
         grown(1:self%nglyphs) = self%glyph_rank(1:self%nglyphs)
         call move_alloc(grown, self%glyph_rank)
      endif
      self%face_glyphs(face) = min(self%face_glyphs(face) + 1_I4P, 255_I4P * size(self%font_objects, 2, kind=I4P))
      self%nglyphs = self%nglyphs + 1_I4P
      self%glyph_face(self%nglyphs) = face
      self%glyph_number(self%nglyphs) = glyph
      self%glyph_unicode(self%nglyphs) = unicode
      self%glyph_rank(self%nglyphs) = self%face_glyphs(face)
      rank = self%face_glyphs(face)
   endif
   name = 'E'//int_str(int(face, I8P))//'_'//int_str(int((rank - 1_I4P) / 255_I4P + 1_I4P, I8P))
   code = modulo(rank - 1_I4P, 255_I4P) + 1_I4P
   endsubroutine glyph_slot

   subroutine embed_fonts(self)
   !< The Type 3 fonts of the glyphs used: for each face and each 255 of its glyphs, a font of 1000 units to the em
   !< whose glyph procedures fill the outlines (quadratic segments as cubic ones), its widths, and a ToUnicode map (the
   !< text is selectable and searchable). Their object numbers go to `font_objects`.
   class(backend_pdf), intent(inout) :: self      !< Device.
   integer(I4P), allocatable         :: ops(:)    !< Outline operations.
   integer(I4P), allocatable         :: points(:) !< Outline points, x then y.
   character(len=:), allocatable     :: procs     !< CharProcs entries.
   character(len=:), allocatable     :: widths    !< Widths.
   character(len=:), allocatable     :: names     !< Differences.
   character(len=:), allocatable     :: cmap      !< ToUnicode entries.
   character(len=:), allocatable     :: proc      !< A glyph procedure.
   real(R8P)                         :: scale     !< Glyph units to 1000 to the em.
   real(R8P)                         :: box(4)    !< Glyph box.
   real(R8P)                         :: advance   !< Glyph width [1000 to the em].
   integer(I4P)                      :: face      !< Face.
   integer(I4P)                      :: font      !< Font of the face.
   integer(I4P)                      :: k         !< Glyph used.
   integer(I4P)                      :: code      !< Code in the font.
   integer(I4P)                      :: count     !< Codes in the font.
   integer(I4P)                      :: unicode_obj !< Object of the ToUnicode map.

   self%font_objects = 0_I4P
   do face = 1_I4P, size(self%face_glyphs, kind=I4P)
      do font = 1_I4P, (self%face_glyphs(face) + 254_I4P) / 255_I4P
         scale = 1000.0_R8P / real(any_upm(face), R8P)
         procs = ''
         widths = ''
         names = ''
         cmap = ''
         count = 0_I4P
         do k = 1_I4P, self%nglyphs
            if (self%glyph_face(k) /= face .or. (self%glyph_rank(k) - 1_I4P) / 255_I4P + 1_I4P /= font) cycle
            code = modulo(self%glyph_rank(k) - 1_I4P, 255_I4P) + 1_I4P
            count = max(count, code)
            if (self%glyph_number(k) > 0_I4P) then
               advance = scale * real(any_advance(face, self%glyph_number(k)), R8P)
               call any_outline(face, self%glyph_number(k), ops, points)
               proc = outline_ops(ops, scale * real(points, R8P), box)
            else
               advance = 556.0_R8P
               proc = ''
               box = 0.0_R8P
            endif
            proc = num(advance)//' 0 '//num(box(1))//' '//num(box(2))//' '//num(box(3))//' '//num(box(4))//' d1'// &
                   new_line('a')//proc
            procs = procs//' /g'//int_str(int(code, I8P))//' '// &
                    int_str(int(self%add_object('<< /Length '//int_str(int(len(proc), I8P))//' >>', &
                                                text_bytes(proc)), I8P))//' 0 R'
            names = names//' '//int_str(int(code, I8P))//' /g'//int_str(int(code, I8P))
            cmap = cmap//'<'//hex2(code)//'> <'//utf16(self%glyph_unicode(k))//'>'//new_line('a')
            widths = widths//' '//num(advance)
         enddo
         ! codes are assigned in order: the widths list runs from 1 to count
         unicode_obj = self%add_object('<< /Length '//int_str(int(len(to_unicode(cmap, count)), I8P))//' >>', &
                                       text_bytes(to_unicode(cmap, count)))
         self%font_objects(face, font) = self%add_object('<< /Type /Font /Subtype /Type3 /FontBBox [0 0 0 0] '// &
                                                         '/FontMatrix [0.001 0 0 0.001 0 0] /CharProcs <<'//procs// &
                                                         ' >> /Encoding << /Type /Encoding /Differences ['//names// &
                                                         '] >> /FirstChar 1 /LastChar '// &
                                                         int_str(int(count, I8P))//' /Widths ['//widths// &
                                                         '] /Resources << >> /ToUnicode '// &
                                                         int_str(int(unicode_obj, I8P))//' 0 R >>')
      enddo
   enddo
   endsubroutine embed_fonts

   ! module procedures
   function outline_ops(ops, points, box) result(path)
   !< The fill of a glyph outline (operations 0 move, 1 line, 2 quadratic, 3 cubic, 4 close; points already scaled)
   !< and its box (left, bottom, right, top).
   integer(I4P), intent(in)      :: ops(:)    !< Operations.
   real(R8P),    intent(in)      :: points(:) !< Points, x then y.
   real(R8P),    intent(out)     :: box(4)    !< Box.
   character(len=:), allocatable :: path      !< Operators.
   real(R8P)                     :: p(2)      !< Current point.
   real(R8P)                     :: q(2)      !< Quadratic control point.
   real(R8P)                     :: e(2)      !< End point.
   integer(I4P)                  :: k         !< Operation.
   integer(I4P)                  :: at        !< Next point (x at points(at)).

   path = ''
   box = 0.0_R8P
   if (size(points) >= 2) box = [minval(points(1::2)), minval(points(2::2)), maxval(points(1::2)), maxval(points(2::2))]
   p = 0.0_R8P
   at = 1_I4P
   do k = 1_I4P, size(ops, kind=I4P)
      select case (ops(k))
      case (0_I4P)
         p = points(at:at + 1_I4P)
         at = at + 2_I4P
         path = path//num(p(1))//' '//num(p(2))//' m'//new_line('a')
      case (1_I4P)
         p = points(at:at + 1_I4P)
         at = at + 2_I4P
         path = path//num(p(1))//' '//num(p(2))//' l'//new_line('a')
      case (2_I4P)
         q = points(at:at + 1_I4P)
         e = points(at + 2_I4P:at + 3_I4P)
         at = at + 4_I4P
         ! the quadratic as a cubic: controls two thirds of the way to its control point
         path = path//num(p(1) + 2.0_R8P / 3.0_R8P * (q(1) - p(1)))//' '//num(p(2) + 2.0_R8P / 3.0_R8P * (q(2) - p(2)))// &
                ' '//num(e(1) + 2.0_R8P / 3.0_R8P * (q(1) - e(1)))//' '//num(e(2) + 2.0_R8P / 3.0_R8P * (q(2) - e(2)))// &
                ' '//num(e(1))//' '//num(e(2))//' c'//new_line('a')
         p = e
      case (3_I4P)
         path = path//num(points(at))//' '//num(points(at + 1_I4P))//' '//num(points(at + 2_I4P))//' '// &
                num(points(at + 3_I4P))//' '//num(points(at + 4_I4P))//' '//num(points(at + 5_I4P))//' c'//new_line('a')
         p = points(at + 4_I4P:at + 5_I4P)
         at = at + 6_I4P
      case default
         path = path//'h'//new_line('a')
      endselect
   enddo
   if (len(path) > 0) path = path//'f'
   endfunction outline_ops

   pure function to_unicode(entries, count) result(cmap)
   !< The ToUnicode CMap of `entries` (`<code> <unicode>` lines), codes 1 to `count`, in blocks of 100 (the limit of a
   !< beginbfchar block).
   character(len=*), intent(in)  :: entries !< Lines.
   integer(I4P),     intent(in)  :: count   !< Codes.
   character(len=:), allocatable :: cmap    !< CMap.
   integer(I4P)                  :: a       !< Line start.
   integer(I4P)                  :: e       !< Line end.
   integer(I4P)                  :: n       !< Lines of the block.
   integer(I4P)                  :: left    !< Lines left.

   cmap = '/CIDInit /ProcSet findresource begin'//new_line('a')//'12 dict begin'//new_line('a')//'begincmap'// &
          new_line('a')//'/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def'//new_line('a')// &
          '/CMapName /Adobe-Identity-UCS def'//new_line('a')//'/CMapType 2 def'//new_line('a')// &
          '1 begincodespacerange'//new_line('a')//'<00> <FF>'//new_line('a')//'endcodespacerange'//new_line('a')
   a = 1_I4P
   left = count
   do while (left > 0_I4P)
      n = min(100_I4P, left)
      cmap = cmap//int_str(int(n, I8P))//' beginbfchar'//new_line('a')
      do e = 1_I4P, n
         ! each line is `<cc> <uuuu>` (`<uuuuuuuu>`: a surrogate pair) and a new line
         cmap = cmap//entries(a:a + index(entries(a:), new_line('a')) - 1_I4P)
         a = a + index(entries(a:), new_line('a'))
      enddo
      cmap = cmap//'endbfchar'//new_line('a')
      left = left - n
   enddo
   cmap = cmap//'endcmap'//new_line('a')//'CMapName currentdict /CMapResource defineresource pop'//new_line('a')// &
          'end'//new_line('a')//'end'
   endfunction to_unicode

   pure function hex2(value) result(text)
   !< `value` (0-255) as two hexadecimal digits.
   integer(I4P), intent(in) :: value !< Value.
   character(len=2)         :: text  !< Digits.

   write(text, '(Z2.2)') value
   endfunction hex2

   pure function utf16(value) result(text)
   !< The UTF-16 code units of the code point `value`, in hexadecimal: four digits, eight for a surrogate pair.
   integer(I4P), intent(in)      :: value !< Code point.
   character(len=:), allocatable :: text  !< Digits.

   if (value > 65535_I4P) then
      text = hex4(55296_I4P + (value - 65536_I4P) / 1024_I4P)//hex4(56320_I4P + modulo(value - 65536_I4P, 1024_I4P))
   else
      text = hex4(value)
   endif
   endfunction utf16

   pure function hex4(value) result(text)
   !< `value` (0-65535) as four hexadecimal digits.
   integer(I4P), intent(in) :: value !< Value.
   character(len=4)         :: text  !< Digits.

   write(text, '(Z4.4)') value
   endfunction hex4

   subroutine round_dots(self, destination, x, y, color, diameter)
   !< Filled round dots of `diameter` [px] centred on (`x`, `y`) [px]: zero-length segments with round caps.
   class(backend_pdf), intent(inout) :: self        !< Device.
   integer(I4P),       intent(in)    :: destination !< Destination buffer.
   real(R8P),          intent(in)    :: x(:)        !< Abscissae [px].
   real(R8P),          intent(in)    :: y(:)        !< Ordinates [px].
   character(len=*),   intent(in)    :: color       !< Color.
   real(R8P),          intent(in)    :: diameter    !< Diameter [px].
   character(len=:), allocatable     :: d           !< Path.
   integer(I4P)                      :: i           !< Counter.

   if (size(x) == 0 .or. trim(color) == 'none') return
   d = ''
   do i = 1_I4P, size(x, kind=I4P)
      d = d//point(x(i), y(i))//' m '//point(x(i), y(i))//' l'//new_line('a')
   enddo
   call self%emit(destination, 'q '//self%color_op(color, .true.)//' '//num(diameter)//' w 1 J'//new_line('a')//d// &
                  'S Q'//new_line('a'))
   endsubroutine round_dots

   subroutine polygon_at(self, x, y, fill, opacity, stroke, line_width, ghost)
   !< Closed polygon of the vertices (`x`, `y`) [px]: filled and stroked in the theme colors; a ghost faintly filled.
   class(backend_pdf), intent(inout)        :: self       !< Device.
   real(R8P),          intent(in)           :: x(:)       !< Vertex abscissae [px].
   real(R8P),          intent(in)           :: y(:)       !< Vertex ordinates [px].
   character(len=*),   intent(in)           :: fill       !< Fill color.
   real(R8P),          intent(in)           :: opacity    !< Fill opacity.
   character(len=*),   intent(in)           :: stroke     !< Border color.
   real(R8P),          intent(in)           :: line_width !< Border width [px].
   logical,            intent(in), optional :: ghost      !< Unlit cell of a segmented fill.
   logical                                  :: faint      !< Ghost.

   faint = .false.
   if (present(ghost)) faint = ghost
   if (faint) then
      call self%paint_path(CONTENT, path_of(x, y, .true.), self%theme%map(fill), self%theme%ghost, 'none', 0.0_R8P, '', &
                           0_I4P)
   else
      call self%paint_path(CONTENT, path_of(x, y, .true.), map_fill(self, fill), opacity, self%theme%map(stroke), &
                           line_width, '', 0_I4P)
   endif
   endsubroutine polygon_at

   function map_fill(self, fill) result(mapped)
   !< The theme color of a fill, a pattern fill's color mapped inside it.
   class(backend_pdf), intent(in) :: self   !< Device.
   character(len=*),   intent(in) :: fill   !< Fill.
   character(len=:), allocatable  :: mapped !< Mapped fill.
   character(len=:), allocatable  :: color  !< Pattern color.
   integer(I4P)                   :: kind   !< Pattern number.

   call pattern_parts(fill, kind, color)
   if (kind > 0_I4P) then
      mapped = fill
   else
      mapped = self%theme%map(fill)
   endif
   endfunction map_fill

   subroutine draw_image(self, left, top, right, bottom, rgba)
   !< `rgba` stretched over the box from (`left`, `top`) to (`right`, `bottom`) [px], its first row at the top.
   class(backend_pdf), intent(inout) :: self        !< Device.
   real(R8P),          intent(in)    :: left        !< Left [px].
   real(R8P),          intent(in)    :: top         !< Top [px].
   real(R8P),          intent(in)    :: right       !< Right [px].
   real(R8P),          intent(in)    :: bottom      !< Bottom [px].
   integer(I4P),       intent(in)    :: rgba(:,:,:) !< Pixels.
   character(len=:), allocatable     :: name        !< Resource name.

   if (.not. self%visible() .or. size(rgba, 2) == 0 .or. size(rgba, 3) == 0) return
   name = self%add_image(rgba)
   ! the image's unit square: its bottom row at `bottom`, its top row at `top` (the page is flipped)
   call self%emit(CONTENT, 'q '//num(right - left)//' 0 0 '//num(top - bottom)//' '//num(left)//' '//num(bottom)// &
                  ' cm /'//name//' Do Q'//new_line('a'))
   endsubroutine draw_image

   pure function glass_geometry(self, x, y, height, cells, label, prefix, font_size) result(geometry)
   !< Glass of a readout of top-left corner (`x`, `y`), as the SVG device's.
   class(backend_pdf), intent(in) :: self        !< Device.
   real(R8P),          intent(in) :: x           !< Left side [px].
   real(R8P),          intent(in) :: y           !< Top side [px].
   real(R8P),          intent(in) :: height      !< Digit height [px].
   integer(I4P),       intent(in) :: cells       !< Glass cells.
   character(len=*),   intent(in) :: label       !< Label, empty for none.
   character(len=*),   intent(in) :: prefix      !< Text before the glass.
   real(R8P),          intent(in) :: font_size   !< Font size of the texts [px].
   real(R8P)                      :: geometry(5) !< Glass left, top, width; prefix width; label row [px].

   geometry(4) = 0.0_R8P
   if (len(prefix) > 0) geometry(4) = self%text_width(prefix, '', font_size) + 0.5_R8P * font_size
   geometry(5) = 0.0_R8P
   if (len(label) > 0) geometry(5) = 1.25_R8P * font_size
   geometry(1) = x + geometry(4) + (SLANT + 0.5_R8P * SEGMENT_WIDTH) * height
   geometry(2) = y + geometry(5) + 0.5_R8P * SEGMENT_WIDTH * height
   geometry(3) = (real(cells - 1_I4P, R8P) * DIGIT_PITCH + POINT_OFFSET + SEGMENT_WIDTH) * height
   endfunction glass_geometry

   function resource_dictionary(self) result(dictionary)
   !< The page's resources: the fonts used, the opacity states, the images, the patterns.
   class(backend_pdf), intent(in) :: self       !< Device.
   character(len=:), allocatable  :: dictionary !< Dictionary.
   integer(I4P)                   :: k          !< Counter.
   integer(I4P)                   :: f          !< Face.

   dictionary = '<< /ProcSet [/PDF /Text /ImageB /ImageC]'
   if (any(self%fonts) .or. any(self%font_objects > 0_I4P)) then
      dictionary = dictionary//' /Font <<'
      do k = 1_I4P, size(self%fonts, kind=I4P)
         if (self%fonts(k)) dictionary = dictionary//' /F'//int_str(int(k, I8P))//' '// &
                                         int_str(int(self%font_refs(k), I8P))//' 0 R'
      enddo
      do f = 1_I4P, size(self%font_objects, 1, kind=I4P)
         do k = 1_I4P, size(self%font_objects, 2, kind=I4P)
            if (self%font_objects(f, k) > 0_I4P) dictionary = dictionary//' /E'//int_str(int(f, I8P))//'_'// &
                                                              int_str(int(k, I8P))//' '// &
                                                              int_str(int(self%font_objects(f, k), I8P))//' 0 R'
         enddo
      enddo
      dictionary = dictionary//' >>'
   endif
   if (self%nalphas > 0_I4P) then
      dictionary = dictionary//' /ExtGState <<'
      do k = 1_I4P, self%nalphas
         dictionary = dictionary//' /GS'//int_str(int(k, I8P))//' << /'//trim(merge('CA', 'ca', self%strokes(k)))// &
                      ' '//num(self%alphas(k))//' >>'
      enddo
      dictionary = dictionary//' >>'
   endif
   if (self%nimages > 0_I4P) then
      dictionary = dictionary//' /XObject <<'
      do k = 1_I4P, self%nimages
         dictionary = dictionary//' /Im'//int_str(int(k, I8P))//' '//int_str(int(self%images(k), I8P))//' 0 R'
      enddo
      dictionary = dictionary//' >>'
   endif
   if (self%npatterns > 0_I4P) then
      dictionary = dictionary//' /Pattern <<'
      do k = 1_I4P, self%npatterns
         dictionary = dictionary//' /P'//int_str(int(k, I8P))//' '//int_str(int(self%patterns(k), I8P))//' 0 R'
      enddo
      dictionary = dictionary//' >>'
   endif
   dictionary = dictionary//' >>'
   endfunction resource_dictionary

   pure function clip_box(self) result(ops)
   !< The plot area as the clipping path.
   class(backend_pdf), intent(in) :: self !< Device.
   character(len=:), allocatable  :: ops  !< Operators.

   ops = num(self%area(1))//' '//num(self%area(2))//' '//num(self%area(3))//' '//num(self%area(4))//' re W n'
   endfunction clip_box

   pure function page_x(self, u) result(x)
   !< Pixel abscissae of the unit-square abscissae `u` of the plot area.
   class(backend_pdf), intent(in) :: self       !< Device.
   real(R8P),          intent(in) :: u(:)       !< Abscissae [unit].
   real(R8P)                      :: x(size(u)) !< Abscissae [px].

   x = self%area(1) + u * self%area(3)
   endfunction page_x

   pure function page_y(self, v) result(y)
   !< Pixel ordinates of the unit-square ordinates `v` (upward) of the plot area.
   class(backend_pdf), intent(in) :: self       !< Device.
   real(R8P),          intent(in) :: v(:)       !< Ordinates [unit].
   real(R8P)                      :: y(size(v)) !< Ordinates [px].

   y = self%area(2) + (1.0_R8P - v) * self%area(4)
   endfunction page_y

   pure function page_x1(self, u) result(x)
   !< Pixel abscissa of the unit-square abscissa `u`.
   class(backend_pdf), intent(in) :: self !< Device.
   real(R8P),          intent(in) :: u    !< Abscissa [unit].
   real(R8P)                      :: x    !< Abscissa [px].

   x = self%area(1) + u * self%area(3)
   endfunction page_x1

   pure function page_y1(self, v) result(y)
   !< Pixel ordinate of the unit-square ordinate `v`.
   class(backend_pdf), intent(in) :: self !< Device.
   real(R8P),          intent(in) :: v    !< Ordinate [unit].
   real(R8P)                      :: y    !< Ordinate [px].

   y = self%area(2) + (1.0_R8P - v) * self%area(4)
   endfunction page_y1

   function path_of(x, y, closed) result(path)
   !< Path operators through the points (`x`, `y`) [px], `closed` or open; non-finite points are skipped.
   real(R8P), intent(in)         :: x(:)   !< Abscissae [px].
   real(R8P), intent(in)         :: y(:)   !< Ordinates [px].
   logical,   intent(in)         :: closed !< Closed.
   character(len=:), allocatable :: path   !< Operators.
   character(len=:), allocatable :: buffer !< Path being written (grown by doubling).
   integer(I4P)                  :: used   !< Characters in use.
   integer(I4P)                  :: i      !< Counter.
   logical                       :: first  !< Next point starts the path.

   allocate(character(len=64 * size(x) + 16) :: buffer)
   used = 0_I4P
   first = .true.
   do i = 1_I4P, size(x, kind=I4P)
      if (.not. (abs(x(i)) <= huge(1.0_R8P) .and. abs(y(i)) <= huge(1.0_R8P))) cycle
      if (first) then
         call append(point(x(i), y(i))//' m')
         first = .false.
      else
         call append(point(x(i), y(i))//' l')
      endif
      if (modulo(i, 8_I4P) == 0_I4P) then
         call append(new_line('a'))
      else
         call append(' ')
      endif
   enddo
   if (closed) call append('h')
   path = buffer(1:used)
   contains
      subroutine append(piece)
      !< Append `piece`.
      character(len=*), intent(in)  :: piece !< Text.
      character(len=:), allocatable :: grown !< Larger buffer.

      if (used + len(piece) > len(buffer)) then
         allocate(character(len=2 * (used + len(piece))) :: grown)
         grown(1:used) = buffer(1:used)
         call move_alloc(grown, buffer)
      endif
      buffer(used + 1:used + len(piece)) = piece
      used = used + len(piece, kind=I4P)
      endsubroutine append
   endfunction path_of

   function svg_path(d) result(path)
   !< PDF path operators of the SVG path data `d` of foresight's shapes: `M`, `L`, `H`, `V` (absolute), `h`, `v`
   !< (relative), `Z`, and `A` half circles (two make a marker's circle), each written as two Bezier quarter arcs.
   character(len=*), intent(in)  :: d     !< SVG path data.
   character(len=:), allocatable :: path  !< Operators.
   real(R8P)                     :: v(7)  !< Numbers of a command.
   real(R8P)                     :: p(2)  !< Current point.
   real(R8P)                     :: s(2)  !< Subpath start.
   real(R8P)                     :: c(2)  !< Arc centre.
   real(R8P)                     :: r     !< Arc radius.
   real(R8P)                     :: a0    !< Arc start angle.
   real(R8P)                     :: k     !< Bezier handle factor.
   integer(I4P)                  :: at    !< Position in `d`.
   integer(I4P)                  :: n     !< Numbers read.
   integer(I4P)                  :: q     !< Quarter counter.
   character(len=1)              :: cmd   !< Command.

   path = ''
   p = 0.0_R8P
   s = 0.0_R8P
   at = 1_I4P
   k = 0.5522847498_R8P
   do while (at <= len(d, kind=I4P))
      cmd = d(at:at)
      at = at + 1_I4P
      select case (cmd)
      case ('M')
         call numbers(2_I4P)
         p = v(1:2)
         s = p
         path = path//point(p(1), p(2))//' m '
      case ('L')
         call numbers(2_I4P)
         p = v(1:2)
         path = path//point(p(1), p(2))//' l '
      case ('H')
         call numbers(1_I4P)
         p(1) = v(1)
         path = path//point(p(1), p(2))//' l '
      case ('V')
         call numbers(1_I4P)
         p(2) = v(1)
         path = path//point(p(1), p(2))//' l '
      case ('h')
         call numbers(1_I4P)
         p(1) = p(1) + v(1)
         path = path//point(p(1), p(2))//' l '
      case ('v')
         call numbers(1_I4P)
         p(2) = p(2) + v(1)
         path = path//point(p(1), p(2))//' l '
      case ('A')
         ! a half circle from p to the end point: its centre the middle, drawn through the side of the sweep
         call numbers(7_I4P)
         c = 0.5_R8P * (p + v(6:7))
         r = 0.5_R8P * norm2(v(6:7) - p)
         a0 = atan2(p(2) - c(2), p(1) - c(1))
         do q = 1_I4P, 2_I4P
            path = path//quarter(a0, merge(1.0_R8P, -1.0_R8P, v(5) > 0.5_R8P))
            a0 = a0 + merge(1.0_R8P, -1.0_R8P, v(5) > 0.5_R8P) * 0.5_R8P * acos(-1.0_R8P)
         enddo
         p = v(6:7)
      case ('Z', 'z')
         path = path//'h '
         p = s
      case default
         continue
      endselect
   enddo
   path = path//new_line('a')
   contains
      subroutine numbers(count)
      !< Read `count` numbers after the command (separated by commas or blanks) into `v`.
      integer(I4P), intent(in) :: count !< Numbers.
      integer(I4P)             :: e     !< End of a number.
      integer(I4P)             :: ios   !< Read status.

      v = 0.0_R8P
      do n = 1_I4P, count
         do while (at <= len(d, kind=I4P))
            if (d(at:at) /= ' ' .and. d(at:at) /= ',') exit
            at = at + 1_I4P
         enddo
         e = at
         do while (e <= len(d, kind=I4P))
            if (index('0123456789.-+eE', d(e:e)) == 0) exit
            if (e > at .and. (d(e:e) == '-' .or. d(e:e) == '+') .and. index('eE', d(e - 1:e - 1)) == 0) exit
            e = e + 1_I4P
         enddo
         if (e > at) read(d(at:e - 1), *, iostat=ios) v(n)
         at = e
      enddo
      endsubroutine numbers

      function quarter(angle, direction) result(op)
      !< A quarter circle from `angle` in `direction` (+1 increasing angle), as a Bezier curve.
      real(R8P), intent(in)         :: angle     !< Start angle.
      real(R8P), intent(in)         :: direction !< Direction.
      character(len=:), allocatable :: op        !< Operator.
      real(R8P)                     :: b         !< End angle.
      real(R8P)                     :: p0(2)     !< Start.
      real(R8P)                     :: p3(2)     !< End.

      b = angle + direction * 0.5_R8P * acos(-1.0_R8P)
      p0 = c + r * [cos(angle), sin(angle)]
      p3 = c + r * [cos(b), sin(b)]
      op = point(p0(1) - direction * k * r * sin(angle), p0(2) + direction * k * r * cos(angle))//' '// &
           point(p3(1) + direction * k * r * sin(b), p3(2) - direction * k * r * cos(b))//' '//point(p3(1), p3(2))// &
           ' c '
      endfunction quarter
   endfunction svg_path

   function dashes(dasharray, scale) result(list)
   !< The PDF dash array of an SVG one (`4,2` -> `4 2`), its lengths times `scale` (1 leaves them as written).
   character(len=*), intent(in)  :: dasharray !< SVG dash array.
   real(R8P),        intent(in)  :: scale     !< Length factor.
   character(len=:), allocatable :: list      !< PDF dash array.
   character(len=len(dasharray)) :: work      !< Dash array, blanks for commas.
   real(R8P)                     :: v         !< A length.
   integer(I4P)                  :: k         !< Counter.
   integer(I4P)                  :: a         !< Start of a length.
   integer(I4P)                  :: ios       !< Read status.

   work = dasharray
   do k = 1_I4P, len(work, kind=I4P)
      if (work(k:k) == ',') work(k:k) = ' '
   enddo
   if (scale == 1.0_R8P) then
      list = trim(work)
      return
   endif
   list = ''
   a = 1_I4P
   do while (a <= len_trim(work))
      do while (work(a:a) == ' ')
         a = a + 1_I4P
      enddo
      k = index(work(a:)//' ', ' ', kind=I4P) + a - 2_I4P
      read(work(a:k), *, iostat=ios) v
      if (ios /= 0_I4P) v = 0.0_R8P
      if (len(list) > 0) list = list//' '
      list = list//num(scale * v)
      a = k + 1_I4P
      if (a > len_trim(work)) exit
   enddo
   endfunction dashes

   pure function pdf_string(text, symbol) result(literal)
   !< The PDF literal string of the UTF-8 `text`: WinAnsi codes (Latin-1 and the typographic characters of 128-159),
   !< `?` for a character WinAnsi lacks, raw bytes for the Symbol font (`symbol`); `(`, `)` and `\` escaped, codes
   !< above 126 written as octal escapes (the content stream stays ASCII).
   character(len=*), intent(in)  :: text    !< Text, UTF-8.
   logical,          intent(in)  :: symbol  !< In the Symbol font: the bytes as they are.
   character(len=:), allocatable :: literal !< String content.
   character(len=4 * len(text))  :: buffer  !< Escaped bytes.
   integer(I4P)                  :: used    !< Characters in use.
   integer(I4P)                  :: k       !< Byte.
   integer(I4P)                  :: n       !< Bytes of a character.
   integer(I4P)                  :: code    !< Code point.
   integer(I4P)                  :: w       !< WinAnsi code.

   used = 0_I4P
   k = 1_I4P
   do while (k <= len(text, kind=I4P))
      if (symbol) then
         code = iachar(text(k:k), kind=I4P)
         n = 1_I4P
      else
         call decode(text, k, code, n)
      endif
      k = k + n
      w = code
      if (.not. symbol) w = winansi(code)
      if (w == 40_I4P .or. w == 41_I4P .or. w == 92_I4P) then
         buffer(used + 1:used + 2) = '\'//achar(w)
         used = used + 2_I4P
      elseif (w < 32_I4P .or. w > 126_I4P) then
         write(buffer(used + 1:used + 4), '(A,O3.3)') '\', w
         used = used + 4_I4P
      else
         buffer(used + 1:used + 1) = achar(w)
         used = used + 1_I4P
      endif
   enddo
   literal = buffer(1:used)
   endfunction pdf_string

   elemental function winansi(code) result(w)
   !< The WinAnsi code of the code point `code`, `?` (63) if it has none.
   integer(I4P), intent(in) :: code !< Code point.
   integer(I4P)             :: w    !< WinAnsi code.
   integer(I4P), parameter  :: HIGH(27) = [8364, 8218, 402, 8222, 8230, 8224, 8225, 710, 8240, 352, 8249, 338, 381, &
                                           8216, 8217, 8220, 8221, 8226, 8211, 8212, 732, 8482, 353, 8250, 339, 382, &
                                           376] !< Code points of WinAnsi 128-159 (the defined ones).
   integer(I4P), parameter  :: SLOT(27) = [128, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 142, 145, 146, &
                                           147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 158, 159] !< Their codes.
   integer(I4P)             :: k    !< Counter.

   w = 63_I4P
   if ((code >= 32_I4P .and. code <= 126_I4P) .or. (code >= 160_I4P .and. code <= 255_I4P)) then
      w = code
      return
   endif
   do k = 1_I4P, size(HIGH, kind=I4P)
      if (HIGH(k) == code) w = SLOT(k)
   enddo
   endfunction winansi

   pure subroutine decode(text, k, code, n)
   !< The code point of the UTF-8 character at byte `k` of `text` and its bytes (a malformed byte: its own code).
   character(len=*), intent(in)  :: text !< UTF-8 text.
   integer(I4P),     intent(in)  :: k    !< First byte.
   integer(I4P),     intent(out) :: code !< Code point.
   integer(I4P),     intent(out) :: n    !< Bytes.
   integer(I4P)                  :: lead !< First byte's value.
   integer(I4P)                  :: j    !< Continuation byte.
   integer(I4P)                  :: b    !< Its value.

   lead = iachar(text(k:k), kind=I4P)
   select case (lead)
   case (240:247)
      n = 4_I4P
      code = iand(lead, 7_I4P)
   case (224:239)
      n = 3_I4P
      code = iand(lead, 15_I4P)
   case (192:223)
      n = 2_I4P
      code = iand(lead, 31_I4P)
   case default
      n = 1_I4P
      code = lead
      return
   endselect
   if (k + n - 1_I4P > len(text, kind=I4P)) then
      n = 1_I4P
      code = lead
      return
   endif
   do j = k + 1_I4P, k + n - 1_I4P
      b = iachar(text(j:j), kind=I4P)
      if (b < 128_I4P .or. b > 191_I4P) then
         n = 1_I4P
         code = lead
         return
      endif
      code = 64_I4P * code + (b - 128_I4P)
   enddo
   endsubroutine decode

   pure subroutine add_bytes(buffer, used, bytes)
   !< Append `bytes` to `buffer(1:used)`, grown by doubling.
   integer(I1P), allocatable, intent(inout) :: buffer(:) !< Buffer.
   integer(I4P),              intent(inout) :: used      !< Bytes in use.
   integer(I1P),              intent(in)    :: bytes(:)  !< Bytes.
   integer(I1P), allocatable                :: grown(:)  !< Larger buffer.

   if (.not. allocated(buffer)) then
      allocate(buffer(max(4096_I4P, 2_I4P * size(bytes, kind=I4P))))
      used = 0_I4P
   endif
   if (used + size(bytes, kind=I4P) > size(buffer, kind=I4P)) then
      allocate(grown(2_I4P * (used + size(bytes, kind=I4P))))
      grown(1:used) = buffer(1:used)
      call move_alloc(grown, buffer)
   endif
   buffer(used + 1_I4P:used + size(bytes, kind=I4P)) = bytes
   used = used + size(bytes, kind=I4P)
   endsubroutine add_bytes

   pure subroutine add_text(buffer, used, text)
   !< Append the characters of `text` to `buffer(1:used)`, grown by doubling.
   integer(I1P), allocatable, intent(inout) :: buffer(:) !< Buffer.
   integer(I4P),              intent(inout) :: used      !< Bytes in use.
   character(len=*),          intent(in)    :: text      !< Text.
   integer(I1P), allocatable                :: grown(:)  !< Larger buffer.
   integer(I4P)                             :: k         !< Character.

   if (.not. allocated(buffer)) then
      allocate(buffer(max(4096_I4P, 2_I4P * len(text, kind=I4P))))
      used = 0_I4P
   endif
   if (used + len(text, kind=I4P) > size(buffer, kind=I4P)) then
      allocate(grown(2_I4P * (used + len(text, kind=I4P))))
      grown(1:used) = buffer(1:used)
      call move_alloc(grown, buffer)
   endif
   do k = 1_I4P, len(text, kind=I4P)
      buffer(used + k) = byte(iachar(text(k:k), kind=I4P))
   enddo
   used = used + len(text, kind=I4P)
   endsubroutine add_text

   pure function text_bytes(text) result(bytes)
   !< The bytes of `text`.
   character(len=*), intent(in) :: text            !< Text.
   integer(I1P)                 :: bytes(len(text)) !< Bytes.
   integer(I4P)                 :: k                !< Counter.

   do k = 1_I4P, len(text, kind=I4P)
      bytes(k) = byte(iachar(text(k:k), kind=I4P))
   enddo
   endfunction text_bytes

   elemental function byte(value) result(b)
   !< The byte of `value` in 0..255.
   integer(I4P), intent(in) :: value !< Value.
   integer(I1P)             :: b     !< Byte.

   if (value > 127_I4P) then
      b = int(value - 256_I4P, I1P)
   else
      b = int(value, I1P)
   endif
   endfunction byte

   pure function digits10(value) result(text)
   !< `value` on 10 digits, zero-padded (a cross-reference offset).
   integer(I4P), intent(in) :: value !< Value.
   character(len=10)        :: text  !< Digits.

   write(text, '(I10.10)') value
   endfunction digits10

   pure function point(x, y) result(text)
   !< `x y` [px].
   real(R8P), intent(in)         :: x    !< Abscissa.
   real(R8P), intent(in)         :: y    !< Ordinate.
   character(len=:), allocatable :: text !< Text.

   text = num(x)//' '//num(y)
   endfunction point

   pure function bytes_text(bytes, n) result(text)
   !< The first `n` bytes of `bytes` as characters.
   integer(I1P), intent(in)      :: bytes(:) !< Bytes.
   integer(I4P), intent(in)      :: n        !< Bytes in use.
   character(len=:), allocatable :: text     !< Text.
   integer(I4P)                  :: k        !< Byte.

   allocate(character(len=n) :: text)
   do k = 1_I4P, n
      text(k:k) = achar(iand(int(bytes(k), I4P), 255_I4P))
   enddo
   endfunction bytes_text

   pure function num(v) result(text)
   !< A number of the content: 3 decimals at most, trailing zeros stripped (foresight_format `fixed`).
   real(R8P), intent(in)         :: v    !< Value.
   character(len=:), allocatable :: text !< Text.

   text = fixed(v, 3_I4P)
   endfunction num
endmodule foresight_backend_pdf
