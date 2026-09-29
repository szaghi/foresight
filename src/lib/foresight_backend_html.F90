!< foresight_backend_html, interactive HTML output device.
module foresight_backend_html
!< foresight_backend_html, interactive HTML output device.
!<
!< A self-contained HTML page: the SVG document of `backend_svg` inline, followed by the embedded viewer script
!< (zoom, pan, gnuplot-like hotkeys). No external resources: the page works from a local file.
use foresight_backend_svg, only : backend_svg
use foresight_format, only : int_str, xml_escape
use foresight_viewer_js, only : write_viewer_js
use penf, only : I4P, I8P, R8P

implicit none
private
public :: backend_html

type, extends(backend_svg) :: backend_html
   !< Interactive HTML output device.
   character(len=:), allocatable :: title           !< Page title, empty for the default.
   integer(I4P)                  :: refresh = 0_I4P !< Page reload period [s], 0 for none (live monitoring).
   contains
      procedure, pass(self) :: begin_page
      procedure, pass(self) :: end_page
endtype backend_html

contains
   subroutine begin_page(self, file, width, height, font_size)
   !< Open the output `file`: HTML head, then the inline SVG root of `width` x `height` px.
   class(backend_html), intent(inout) :: self      !< Device.
   character(len=*),    intent(in)    :: file      !< Output file.
   real(R8P),           intent(in)    :: width     !< Page width [px].
   real(R8P),           intent(in)    :: height    !< Page height [px].
   real(R8P),           intent(in)    :: font_size !< Default font size [px].
   character(len=:), allocatable      :: title     !< Page title.

   title = 'foresight'
   if (allocated(self%title)) then
      if (len(self%title) > 0) title = self%title
   endif
   call self%open_file(file)
   call self%put('<!DOCTYPE html>')
   call self%put('<html lang="en">')
   call self%put('<head>')
   call self%put('<meta charset="utf-8">')
   call self%put('<title>'//xml_escape(title)//'</title>')
   call self%put('<style>body{margin:0;background:#fff}svg{display:block;user-select:none}</style>')
   call self%put('</head>')
   call self%put('<body>')
   call self%open_svg(width, height, font_size, ' data-refresh="'//int_str(int(self%refresh, I8P))//'"')
   endsubroutine begin_page

   subroutine end_page(self)
   !< Close the SVG, append the viewer script, close the page and publish it atomically.
   class(backend_html), intent(inout) :: self !< Device.

   call self%put('</svg>')
   call self%put('<script>')
   call write_viewer_js(self%output_unit())
   call self%put('</script>')
   call self%put('</body>')
   call self%put('</html>')
   call self%close_file
   endsubroutine end_page
endmodule foresight_backend_html
