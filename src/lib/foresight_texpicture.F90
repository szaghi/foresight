!< foresight LaTeX picture: the LaTeX file of the cairolatex terminal, with gnuplot 6.0's macros.
module foresight_texpicture
!< The LaTeX file of a cairolatex figure (issue #5 step 3.1): gnuplot 6.0's epslatex picture, its macros verbatim (so that
!< a document written for gnuplot's figures takes foresight's: `\ifGPcolor`, `\ifGPblacktext`, `\gplbacktext`,
!< `\gplfronttext`, gnuplot.cfg), the texts by `\put` in 0.05 bp, the graphics by `\includegraphics`; `standalone` a
!< compilable document (gnuplot's preamble: the font size's `size<N>.clo`, the paper of the figure's size).
!<
!< The templates write `~` for the backslash (nvfortran reads a backslash in a literal as an escape).
use foresight_format, only : int_str
use penf, only : I4P, I8P, R8P

implicit none
private
public :: tex_document
public :: tex_visible
public :: tex_number

character(len=1), parameter :: BS = achar(92) !< Backslash.
! gnuplot 6.0's cairolatex output, its fixed parts (pslatex.trm EPSLATEX_common_init)
character(len=*), parameter :: HEAD_SIZE(14) = [character(len=76) :: & !< Standalone: class, font size.
   "~documentclass{minimal}", &
   "% Set font size", &
   "~makeatletter", &
   "~def~@ptsize{{PT}}", &
   "~InputIfFileExists{size{SZ}.clo}{}{%", &
   "   ~GenericError{(gnuplot) ~space~space~space~@spaces}{%", &
   "      Gnuplot Error: File `size{SZ}.clo' not found! Could not set font size%", &
   "   }{See the gnuplot documentation for explanation.%", &
   "   }{For using a font size a file `size<fontsize>.clo' has to exist.", &
   "        Falling back ^^Jto default fontsize 10pt.}%", &
   "  ~def~@ptsize{0}", &
   "  ~input{size10.clo}%", &
   "}%", &
   "~makeatother"]
character(len=*), parameter :: HEAD_PACKAGES(43) = [character(len=66) :: & !< Standalone: packages, paper.
   "% Load packages", &
   "~usepackage{calc}", &
   "~usepackage{graphicx}", &
   "~usepackage{color}", &
   "~usepackage{transparent}", &
   "~makeatletter", &
   "% Select an appropriate default driver (from TeXLive graphics.cfg)", &
   "~begingroup", &
   "  ~chardef~x=0 %", &
   "  % check pdfTeX", &
   "  ~@ifundefined{pdfoutput}{}{%", &
   "    ~ifcase~pdfoutput", &
   "    ~else", &
   "      ~chardef~x=1 %", &
   "    ~fi", &
   "  }%", &
   "  % check VTeX", &
   "  ~@ifundefined{OpMode}{}{%", &
   "    ~chardef~x=2 %", &
   "  }%", &
   "~expandafter~endgroup", &
   "~ifcase~x", &
   "  % default case", &
   "  ~PassOptionsToPackage{dvips}{geometry}", &
   "~or", &
   "  % pdfTeX is running in pdf mode", &
   "  ~PassOptionsToPackage{pdftex}{geometry}", &
   "~else", &
   "  % VTeX is running", &
   "  ~PassOptionsToPackage{vtex}{geometry}", &
   "~fi", &
   "~makeatother", &
   "% Set papersize", &
   "~usepackage[papersize={{W}bp,{H}bp},text={{W}bp,{H}bp}]{geometry}", &
   "% No page numbers and no paragraph indentation", &
   "~pagestyle{empty}", &
   "~setlength{~parindent}{0bp}%", &
   "% Load configuration file", &
   "~InputIfFileExists{gnuplot.cfg}{%", &
   "  ~typeout{Using configuration file gnuplot.cfg}%", &
   "}{%", &
   " ~typeout{No configuration file gnuplot.cfg found.}%", &
   "}%"]
character(len=*), parameter :: MACROS(80) = [character(len=73) :: & !< The picture's macros.
   "  ~makeatletter", &
   "  ~providecommand~color[2][]{%", &
   "    ~GenericError{(gnuplot) ~space~space~space~@spaces}{%", &
   "      Package color not loaded in conjunction with", &
   "      terminal option `colourtext'%", &
   "    }{See the gnuplot documentation for explanation.%", &
   "    }{Either use 'blacktext' in gnuplot or load the package", &
   "      color.sty in LaTeX.}%", &
   "    ~renewcommand~color[2][]{}%", &
   "  }%", &
   "  ~providecommand~includegraphics[2][]{%", &
   "    ~GenericError{(gnuplot) ~space~space~space~@spaces}{%", &
   "      Package graphicx or graphics not loaded%", &
   "    }{See the gnuplot documentation for explanation.%", &
   "    }{The gnuplot epslatex terminal needs graphicx.sty or graphics.sty.}%", &
   "    ~renewcommand~includegraphics[2][]{}%", &
   "  }%", &
   "  ~providecommand~rotatebox[2]{#2}%", &
   "  ~@ifundefined{ifGPcolor}{%", &
   "    ~newif~ifGPcolor", &
   "    ~GPcolortrue", &
   "  }{}%", &
   "  ~@ifundefined{ifGPblacktext}{%", &
   "    ~newif~ifGPblacktext", &
   "    ~GPblacktexttrue", &
   "  }{}%", &
   "  % define a ~g@addto@macro without @ in the name:", &
   "  ~let~gplgaddtomacro~g@addto@macro", &
   "  % define empty templates for all commands taking text:", &
   "  ~gdef~gplbacktext{}%", &
   "  ~gdef~gplfronttext{}%", &
   "  ~makeatother", &
   "  ~ifGPblacktext", &
   "    % no textcolor at all", &
   "    ~def~colorrgb#1{}%", &
   "    ~def~colorgray#1{}%", &
   "  ~else", &
   "    % gray or color?", &
   "    ~ifGPcolor", &
   "      ~def~colorrgb#1{~color[rgb]{#1}}%", &
   "      ~def~colorgray#1{~color[gray]{#1}}%", &
   "      ~expandafter~def~csname LTw~endcsname{~color{white}}%", &
   "      ~expandafter~def~csname LTb~endcsname{~color{black}}%", &
   "      ~expandafter~def~csname LTa~endcsname{~color{black}}%", &
   "      ~expandafter~def~csname LT0~endcsname{~color[rgb]{1,0,0}}%", &
   "      ~expandafter~def~csname LT1~endcsname{~color[rgb]{0,1,0}}%", &
   "      ~expandafter~def~csname LT2~endcsname{~color[rgb]{0,0,1}}%", &
   "      ~expandafter~def~csname LT3~endcsname{~color[rgb]{1,0,1}}%", &
   "      ~expandafter~def~csname LT4~endcsname{~color[rgb]{0,1,1}}%", &
   "      ~expandafter~def~csname LT5~endcsname{~color[rgb]{1,1,0}}%", &
   "      ~expandafter~def~csname LT6~endcsname{~color[rgb]{0,0,0}}%", &
   "      ~expandafter~def~csname LT7~endcsname{~color[rgb]{1,0.3,0}}%", &
   "      ~expandafter~def~csname LT8~endcsname{~color[rgb]{0.5,0.5,0.5}}%", &
   "    ~else", &
   "      % gray", &
   "      ~def~colorrgb#1{~color{black}}%", &
   "      ~def~colorgray#1{~color[gray]{#1}}%", &
   "      ~expandafter~def~csname LTw~endcsname{~color{white}}%", &
   "      ~expandafter~def~csname LTb~endcsname{~color{black}}%", &
   "      ~expandafter~def~csname LTa~endcsname{~color{black}}%", &
   "      ~expandafter~def~csname LT0~endcsname{~color{black}}%", &
   "      ~expandafter~def~csname LT1~endcsname{~color{black}}%", &
   "      ~expandafter~def~csname LT2~endcsname{~color{black}}%", &
   "      ~expandafter~def~csname LT3~endcsname{~color{black}}%", &
   "      ~expandafter~def~csname LT4~endcsname{~color{black}}%", &
   "      ~expandafter~def~csname LT5~endcsname{~color{black}}%", &
   "      ~expandafter~def~csname LT6~endcsname{~color{black}}%", &
   "      ~expandafter~def~csname LT7~endcsname{~color{black}}%", &
   "      ~expandafter~def~csname LT8~endcsname{~color{black}}%", &
   "    ~fi", &
   "  ~fi", &
   "    ~setlength{~unitlength}{0.0500bp}%", &
   "    ~ifx~gptboxheight~undefined%", &
   "      ~newlength{~gptboxheight}%", &
   "      ~newlength{~gptboxwidth}%", &
   "      ~newsavebox{~gptboxtext}%", &
   "    ~fi%", &
   "    ~setlength{~fboxrule}{0.5pt}%", &
   "    ~setlength{~fboxsep}{1pt}%", &
   "    ~definecolor{tbcol}{rgb}{1,1,1}%"]

contains
   pure function tex_document(back, front, width, height, graphics, standalone, header, font, points, color, &
                              blacktext) result(doc)
   !< The LaTeX file of a figure of `width` x `height` bp whose graphics file is `graphics` (no extension), its back and
   !< front texts (`\put` lines): for `\input`, or with `standalone` a document of font size `points`; `header` LaTeX
   !< code (the preamble's end when standalone, else right after `\begingroup`), `font` gnuplot's LaTeX font name
   !< `family,series,shape` (each part optional); `color` and `blacktext` the defaults of `\ifGPcolor` and
   !< `\ifGPblacktext` (a document's own values win).
   character(len=*), intent(in)  :: back       !< Back texts.
   character(len=*), intent(in)  :: front      !< Front texts.
   real(R8P),        intent(in)  :: width      !< Width [bp].
   real(R8P),        intent(in)  :: height     !< Height [bp].
   character(len=*), intent(in)  :: graphics   !< Graphics file, without extension.
   logical,          intent(in)  :: standalone !< A whole document.
   character(len=*), intent(in)  :: header     !< LaTeX code, empty for none.
   character(len=*), intent(in)  :: font       !< LaTeX font name, empty for the document's.
   real(R8P),        intent(in)  :: points     !< Font size [pt].
   logical,          intent(in)  :: color      !< Color (else gray) texts.
   logical,          intent(in)  :: blacktext  !< Black texts.
   character(len=:), allocatable :: doc        !< Text.
   character(len=:), allocatable :: family     !< Font family.
   character(len=:), allocatable :: series     !< Font series.
   character(len=:), allocatable :: shape      !< Font shape.
   character(len=1), parameter   :: NL = new_line('a') !< Line end.
   integer(I4P)                  :: k          !< Counter.
   integer(I4P)                  :: c          !< Comma.

   family = font
   series = ''
   shape = ''
   c = index(family, ',')
   if (c > 0) then
      series = family(c + 1:)
      family = family(:c - 1)
      c = index(series, ',')
      if (c > 0) then
         shape = series(c + 1:)
         series = series(:c - 1)
      endif
   endif
   doc = '% foresight: LaTeX picture (gnuplot 6.0 cairolatex)'//NL
   if (standalone) then
      do k = 1_I4P, size(HEAD_SIZE, kind=I4P)
         doc = doc//fill(trim(HEAD_SIZE(k)))//NL
      enddo
      if (len(family) > 0) doc = doc//BS//'renewcommand*'//BS//'rmdefault{'//family//'}%'//NL
      if (len(series) > 0) doc = doc//BS//'renewcommand*'//BS//'mddefault{'//series//'}%'//NL
      if (len(shape) > 0) doc = doc//BS//'renewcommand*'//BS//'updefault{'//shape//'}%'//NL
      do k = 1_I4P, size(HEAD_PACKAGES, kind=I4P)
         doc = doc//fill(trim(HEAD_PACKAGES(k)))//NL
      enddo
      if (len(header) > 0) doc = doc//header//NL
      doc = doc//BS//'begin{document}'//NL
   endif
   doc = doc//BS//'begingroup'//NL
   if (.not. standalone) then
      if (len(family) > 0) doc = doc//'  '//BS//'fontfamily{'//family//'}%'//NL
      if (len(series) > 0) doc = doc//'  '//BS//'fontseries{'//series//'}%'//NL
      if (len(shape) > 0) doc = doc//'  '//BS//'fontshape{'//shape//'}%'//NL
      if (len(family) + len(series) + len(shape) > 0) doc = doc//'  '//BS//'selectfont'//NL
      if (len(header) > 0) doc = doc//header//NL
   endif
   do k = 1_I4P, size(MACROS, kind=I4P)
      if (.not. color .and. index(MACROS(k), '~GPcolortrue') > 0) then
         doc = doc//'    '//BS//'GPcolorfalse'//NL
      elseif (.not. blacktext .and. index(MACROS(k), '~GPblacktexttrue') > 0) then
         doc = doc//'    '//BS//'GPblacktextfalse'//NL
      else
         doc = doc//fill(trim(MACROS(k)))//NL
      endif
   enddo
   doc = doc//BS//'begin{picture}('//f2(20.0_R8P * width)//','//f2(20.0_R8P * height)//')%'//NL// &
         '    '//BS//'gplgaddtomacro'//BS//'gplbacktext{%'//NL//back//'    }%'//NL// &
         '    '//BS//'gplgaddtomacro'//BS//'gplfronttext{%'//NL//front//'    }%'//NL// &
         '    '//BS//'gplbacktext'//NL// &
         '    '//BS//'put(0,0){'//BS//'includegraphics[width={'//f2(width)//'bp},height={'//f2(height)//'bp}]{'// &
         graphics//'}}%'//NL// &
         '    '//BS//'gplfronttext'//NL//'  '//BS//'end{picture}%'//NL//BS//'endgroup'//NL
   if (standalone) doc = doc//BS//'end{document}'//NL
   contains
      pure function fill(line) result(text)
      !< A template line: its backslashes, the font size and the paper size in.
      character(len=*), intent(in)  :: line !< Template line.
      character(len=:), allocatable :: text !< Line.
      integer(I4P)                  :: j    !< Character.

      text = ''
      j = 1_I4P
      do while (j <= len(line, kind=I4P))
         if (line(j:j) == '~') then
            text = text//BS
         elseif (j + 3_I4P <= len(line, kind=I4P) .and. line(j:min(j + 3_I4P, len(line, kind=I4P))) == '{PT}') then
            text = text//int_str(int(nint(points), I8P) - 10_I8P)
            j = j + 3_I4P
         elseif (j + 3_I4P <= len(line, kind=I4P) .and. line(j:min(j + 3_I4P, len(line, kind=I4P))) == '{SZ}') then
            text = text//int_str(int(nint(points), I8P))
            j = j + 3_I4P
         elseif (j + 2_I4P <= len(line, kind=I4P) .and. line(j:min(j + 2_I4P, len(line, kind=I4P))) == '{W}') then
            text = text//f2(width)
            j = j + 2_I4P
         elseif (j + 2_I4P <= len(line, kind=I4P) .and. line(j:min(j + 2_I4P, len(line, kind=I4P))) == '{H}') then
            text = text//f2(height)
            j = j + 2_I4P
         else
            text = text//line(j:j)
         endif
         j = j + 1_I4P
      enddo
      endfunction fill
   endfunction tex_document

   pure function tex_number(v) result(text)
   !< `v` as C's `%.2f`.
   real(R8P), intent(in)         :: v    !< Value.
   character(len=:), allocatable :: text !< Text.

   text = f2(v)
   endfunction tex_number

   pure function tex_visible(text) result(shown)
   !< The characters of a LaTeX `text` that take room, as gnuplot counts them for the layout (term.c strlen_tex): a
   !< bracketed option skipped, a control word one character (an `m`), braces, `$`, `_` and `^` none.
   character(len=*), intent(in)  :: text  !< LaTeX text.
   character(len=:), allocatable :: shown !< Its characters.
   integer(I4P)                  :: j     !< Character.

   if (scan(text, '{}$[]'//BS) == 0) then
      shown = text
      return
   endif
   shown = ''
   j = 1_I4P
   do while (j <= len(text, kind=I4P))
      select case (text(j:j))
      case ('[')
         do while (j <= len(text, kind=I4P))
            if (text(j:j) == ']') exit
            j = j + 1_I4P
         enddo
         j = j + 1_I4P
      case (BS)
         j = j + 1_I4P
         do while (j <= len(text, kind=I4P))
            if (.not. is_letter(text(j:j))) exit
            j = j + 1_I4P
         enddo
         shown = shown//'m'
      case ('{', '}', '$', '_', '^')
         j = j + 1_I4P
      case default
         shown = shown//text(j:j)
         j = j + 1_I4P
      endselect
   enddo
   contains
      elemental function is_letter(ch) result(yes)
      !< `ch` an ASCII letter.
      character(len=1), intent(in) :: ch  !< Character.
      logical                      :: yes !< A letter.

      yes = (ch >= 'a' .and. ch <= 'z') .or. (ch >= 'A' .and. ch <= 'Z')
      endfunction is_letter
   endfunction tex_visible

   pure function f2(v) result(text)
   !< `v` with two decimals, as C's `%.2f`.
   real(R8P), intent(in)         :: v    !< Value.
   character(len=:), allocatable :: text !< Text.
   character(len=32)             :: buffer !< Buffer.

   write(buffer, '(F0.2)') v
   text = trim(adjustl(buffer))
   if (text(1:1) == '.') text = '0'//text
   if (len(text) > 1) then
      if (text(1:2) == '-.') text = '-0'//text(2:)
   endif
   if (text == '-0.00') text = '0.00'
   endfunction f2
endmodule foresight_texpicture
