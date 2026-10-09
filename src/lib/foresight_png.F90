!< foresight_png, PNG images as base64 data, for raster plots (gnuplot `with image`) in SVG.
module foresight_png
!< foresight_png, PNG images as base64 data, for raster plots (gnuplot `with image`) in SVG.
!<
!< 8-bit RGBA, no interlace, every row unfiltered and the zlib stream made of stored (uncompressed) deflate blocks:
!< no compression to write, a file a few bytes per pixel, the same bytes for the same image (golden tests). CRC-32 and
!< Adler-32 as the PNG and zlib specifications; base64 by BeFoR64.
use befor64, only : b64_encode, b64_init, is_b64_initialized
use penf, only : I1P, I4P, I8P

implicit none
private
public :: png_base64

contains
   function png_base64(rgba) result(code)
   !< Base64 of the PNG of the image `rgba(channel, column, row)`: red, green, blue, alpha (0..255) of each pixel,
   !< columns left to right, rows top to bottom.
   integer(I4P), intent(in)      :: rgba(:,:,:) !< Pixels.
   character(len=:), allocatable :: code        !< Base64 text.
   integer(I1P), allocatable     :: png(:)      !< File bytes.
   integer(I1P), allocatable     :: raw(:)      !< Rows, each led by its filter byte (0).
   integer(I1P), allocatable     :: zlib(:)     !< zlib stream.
   integer(I4P)                  :: w           !< Width.
   integer(I4P)                  :: h           !< Height.
   integer(I4P)                  :: r           !< Row counter.
   integer(I4P)                  :: p           !< Byte position.

   w = size(rgba, 2, kind=I4P)
   h = size(rgba, 3, kind=I4P)
   allocate(raw(h * (1_I4P + 4_I4P * w)))
   p = 0_I4P
   do r = 1_I4P, h
      raw(p + 1_I4P) = 0_I1P
      raw(p + 2_I4P:p + 1_I4P + 4_I4P * w) = byte(reshape(rgba(:, :, r), [4_I4P * w]))
      p = p + 1_I4P + 4_I4P * w
   enddo
   zlib = stored(raw)
   png = [byte([137, 80, 78, 71, 13, 10, 26, 10]), &
          chunk('IHDR', [be32(w), be32(h), byte([8, 6, 0, 0, 0])]), chunk('IDAT', zlib), chunk('IEND', [integer(I1P) ::])]
   if (.not. is_b64_initialized) call b64_init
   call b64_encode(n=png, code=code)
   endfunction png_base64

   ! private procedures
   pure function stored(data) result(stream)
   !< zlib stream of `data` in stored deflate blocks of at most 65535 bytes, with its Adler-32.
   integer(I1P), intent(in)  :: data(:)   !< Data.
   integer(I1P), allocatable :: stream(:) !< zlib stream.
   integer(I4P)              :: n         !< Block length.
   integer(I4P)              :: p         !< Data position.
   integer(I4P)              :: q         !< Stream position.
   integer(I4P)              :: blocks    !< Blocks.

   blocks = max(1_I4P, (size(data, kind=I4P) + 65534_I4P) / 65535_I4P)
   allocate(stream(2 + 5 * blocks + size(data) + 4))
   stream(1:2) = byte([120, 1])
   p = 0_I4P
   q = 2_I4P
   do
      n = min(65535_I4P, size(data, kind=I4P) - p)
      stream(q + 1_I4P) = merge(1_I1P, 0_I1P, p + n == size(data, kind=I4P))
      stream(q + 2_I4P:q + 5_I4P) = byte([modulo(n, 256), n / 256, modulo(65535 - n, 256), (65535 - n) / 256])
      stream(q + 6_I4P:q + 5_I4P + n) = data(p + 1_I4P:p + n)
      q = q + 5_I4P + n
      p = p + n
      if (p >= size(data, kind=I4P)) exit
   enddo
   stream(q + 1_I4P:q + 4_I4P) = be32(adler32(data))
   endfunction stored

   pure function chunk(kind, data) result(bytes)
   !< PNG chunk: length, type, data, CRC-32 of type and data.
   character(len=4), intent(in) :: kind     !< Chunk type.
   integer(I1P),     intent(in) :: data(:)  !< Chunk data.
   integer(I1P), allocatable    :: bytes(:) !< Chunk bytes.
   integer(I1P)                 :: tag(4)   !< Type bytes.
   integer(I4P)                 :: k        !< Counter.

   do k = 1_I4P, 4_I4P
      tag(k) = byte(iachar(kind(k:k)))
   enddo
   bytes = [be32(size(data, kind=I4P)), tag, data, be32(crc32([tag, data]))]
   endfunction chunk

   pure function crc32(data) result(crc)
   !< CRC-32 (ISO 3309, as PNG) of `data`, as a signed 32-bit integer.
   integer(I1P), intent(in) :: data(:) !< Data.
   integer(I4P)             :: crc     !< CRC.
   integer(I8P)             :: c       !< Running CRC, unsigned 32 bits.
   integer(I4P)             :: i       !< Byte counter.
   integer(I4P)             :: k       !< Bit counter.

   c = int(z'FFFFFFFF', I8P)
   do i = 1_I4P, size(data, kind=I4P)
      c = ieor(c, iand(int(data(i), I8P), 255_I8P))
      do k = 1_I4P, 8_I4P
         if (btest(c, 0)) then
            c = ieor(shiftr(c, 1), int(z'EDB88320', I8P))
         else
            c = shiftr(c, 1)
         endif
      enddo
   enddo
   c = ieor(c, int(z'FFFFFFFF', I8P))
   crc = int(c - merge(4294967296_I8P, 0_I8P, c > 2147483647_I8P), I4P)
   endfunction crc32

   pure function adler32(data) result(sum)
   !< Adler-32 of `data`, as a signed 32-bit integer.
   integer(I1P), intent(in) :: data(:) !< Data.
   integer(I4P)             :: sum     !< Checksum.
   integer(I8P)             :: a       !< Byte sum.
   integer(I8P)             :: b       !< Sum of the byte sums.
   integer(I4P)             :: i       !< Counter.

   a = 1_I8P
   b = 0_I8P
   do i = 1_I4P, size(data, kind=I4P)
      a = modulo(a + iand(int(data(i), I8P), 255_I8P), 65521_I8P)
      b = modulo(b + a, 65521_I8P)
   enddo
   a = b * 65536_I8P + a
   sum = int(a - merge(4294967296_I8P, 0_I8P, a > 2147483647_I8P), I4P)
   endfunction adler32

   pure function be32(v) result(bytes)
   !< Big-endian bytes of the 32-bit integer `v` (two's complement).
   integer(I4P), intent(in) :: v        !< Value.
   integer(I1P)             :: bytes(4) !< Bytes.
   integer(I8P)             :: u        !< Unsigned value.

   u = int(v, I8P)
   if (u < 0_I8P) u = u + 4294967296_I8P
   bytes = byte([int(shiftr(u, 24)), int(iand(shiftr(u, 16), 255_I8P)), int(iand(shiftr(u, 8), 255_I8P)), &
                 int(iand(u, 255_I8P))])
   endfunction be32

   elemental function byte(v) result(b)
   !< Byte of the unsigned value `v` (0..255), stored two's complement.
   integer(I4P), intent(in) :: v !< Value.
   integer(I1P)             :: b !< Byte.

   b = int(v - merge(256, 0, v > 127), I1P)
   endfunction byte
endmodule foresight_png
