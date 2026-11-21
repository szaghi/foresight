!< foresight_stats, gnuplot's `stats`: summary statistics of one or two columns.
module foresight_stats
!< foresight_stats, gnuplot's `stats`: summary statistics of one or two columns.
!<
!< A translation of gnuplot 6.0's stats.c, so that the values and the report are gnuplot's:
!<
!< - population moments: the standard deviation from the centred sum of squares, skewness and kurtosis from the third
!<   and fourth centred moments (NaN when the variance is 0), the sample standard deviation `stddev * sqrt(n/(n-1))`,
!<   the mean absolute deviation, the standard errors `stddev/sqrt(n)`, `stddev/sqrt(2n)`, `sqrt(6/n)`, `sqrt(24/n)`;
!< - the median and the quartiles of the sorted values as gnuplot's boxplots: an even count averages the two middle
!<   values, the quartiles average two values when the count is a multiple of 4;
!< - the minimum and the maximum with their 0-based index among the values (a sort that keeps equal values in order:
!<   the first of equal minima, the last of equal maxima);
!< - two columns: the least squares line `y = slope x + intercept`, its standard errors (for more than 2 points; 0 for
!<   2), the correlation, the sum of the products and the x of the y minimum and maximum.
!<
!< `stats` computes them from Fortran arrays, `stats_report` writes gnuplot's report.
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan, ieee_quiet_nan, ieee_value
use penf, only : I4P, I8P, R8P
use foresight_format, only : c_real, int_str

implicit none
private
public :: stats
public :: stats_column
public :: stats_report
public :: stats_result

type :: stats_column
   !< Statistics of one column (gnuplot's STATS_mean, ... or STATS_mean_x, STATS_mean_y).
   real(R8P)    :: mean = 0.0_R8P         !< Mean.
   real(R8P)    :: stddev = 0.0_R8P       !< Population standard deviation.
   real(R8P)    :: ssd = 0.0_R8P          !< Sample standard deviation.
   real(R8P)    :: skewness = 0.0_R8P     !< Skewness.
   real(R8P)    :: kurtosis = 0.0_R8P     !< Kurtosis.
   real(R8P)    :: adev = 0.0_R8P         !< Mean absolute deviation.
   real(R8P)    :: mean_err = 0.0_R8P     !< Standard error of the mean.
   real(R8P)    :: stddev_err = 0.0_R8P   !< Standard error of the standard deviation.
   real(R8P)    :: skewness_err = 0.0_R8P !< Standard error of the skewness.
   real(R8P)    :: kurtosis_err = 0.0_R8P !< Standard error of the kurtosis.
   real(R8P)    :: sum = 0.0_R8P          !< Sum.
   real(R8P)    :: sumsq = 0.0_R8P        !< Sum of squares.
   real(R8P)    :: min = 0.0_R8P          !< Minimum.
   real(R8P)    :: max = 0.0_R8P          !< Maximum.
   real(R8P)    :: median = 0.0_R8P       !< Median.
   real(R8P)    :: lo_quartile = 0.0_R8P  !< Lower quartile.
   real(R8P)    :: up_quartile = 0.0_R8P  !< Upper quartile.
   integer(I4P) :: index_min = 0_I4P      !< 0-based index of the minimum.
   integer(I4P) :: index_max = 0_I4P      !< 0-based index of the maximum.
endtype stats_column

type :: stats_result
   !< gnuplot's STATS_* values: the file counts, one column (`y`) or two (`x`, `y` and their line).
   integer(I4P)       :: records = 0_I4P    !< Points analysed.
   integer(I4P)       :: invalid = 0_I4P    !< Records with an undefined value.
   integer(I4P)       :: headers = 0_I4P    !< Column header records.
   integer(I4P)       :: blank = 0_I4P      !< Blank lines.
   integer(I4P)       :: blocks = 0_I4P     !< Data blocks (separated by two blank lines).
   integer(I4P)       :: outofrange = 0_I4P !< Points outside the ranges.
   integer(I4P)       :: columns = 0_I4P    !< Columns of the file.
   logical            :: two = .false.      !< Two columns analysed.
   type(stats_column) :: x                  !< First column of two.
   type(stats_column) :: y                  !< The column, or the second of two.
   real(R8P)          :: slope = 0.0_R8P         !< Least squares slope.
   real(R8P)          :: intercept = 0.0_R8P     !< Least squares intercept.
   real(R8P)          :: slope_err = 0.0_R8P     !< Standard error of the slope.
   real(R8P)          :: intercept_err = 0.0_R8P !< Standard error of the intercept.
   real(R8P)          :: correlation = 0.0_R8P   !< Correlation coefficient.
   real(R8P)          :: sumxy = 0.0_R8P         !< Sum of the products.
   real(R8P)          :: pos_min_y = 0.0_R8P     !< x of the y minimum.
   real(R8P)          :: pos_max_y = 0.0_R8P     !< x of the y maximum.
endtype stats_result

interface stats
   !< Statistics of one column, `stats(y)`, or of two, `stats(x, y)`.
   module procedure stats_one
   module procedure stats_two
endinterface stats

contains
   pure function stats_one(y) result(r)
   !< gnuplot `stats ... using N` on the values `y` (at least one).
   real(R8P), intent(in) :: y(:) !< Values.
   type(stats_result)    :: r    !< Statistics.

   r%records = size(y, kind=I4P)
   r%blocks = 1_I4P
   r%columns = 1_I4P
   if (size(y) > 0) r%y = analyze(y)
   endfunction stats_one

   pure function stats_two(x, y) result(r)
   !< gnuplot `stats ... using N:M` on the pairs (`x`, `y`), of the same size (at least one).
   real(R8P), intent(in) :: x(:) !< First column.
   real(R8P), intent(in) :: y(:) !< Second column.
   type(stats_result)    :: r    !< Statistics.
   real(R8P)             :: n    !< Count.
   real(R8P)             :: ss   !< Residual variance.
   real(R8P)             :: ssyy !< Centred sum of y squares.
   real(R8P)             :: ssxx !< Centred sum of x squares.
   real(R8P)             :: ssxy !< Centred sum of products.
   integer(I4P)          :: i    !< Counter.

   r%records = size(y, kind=I4P)
   r%blocks = 1_I4P
   r%columns = 2_I4P
   r%two = .true.
   if (size(y) == 0) return
   r%x = analyze(x)
   r%y = analyze(y)
   r%sumxy = 0.0_R8P
   do i = 1_I4P, size(x, kind=I4P)
      r%sumxy = r%sumxy + x(i) * y(i)
   enddo
   n = real(size(x), R8P)
   ssyy = r%y%sumsq - r%y%sum * r%y%sum / n
   ssxx = r%x%sumsq - r%x%sum * r%x%sum / n
   ssxy = r%sumxy - r%x%sum * r%y%sum / n
   if (ssxx /= 0.0_R8P) then
      r%slope = ssxy / ssxx
   else
      r%slope = nan()
   endif
   r%intercept = r%y%mean - r%slope * r%x%mean
   if (r%y%stddev /= 0.0_R8P) then
      r%correlation = r%slope * r%x%stddev / r%y%stddev
   else
      r%correlation = nan()
   endif
   if (size(x) > 2) then
      ss = (ssyy - r%slope * ssxy) / (n - 2.0_R8P)
      if (ssxx /= 0.0_R8P) then
         r%slope_err = sqrt(ss / ssxx)
         r%intercept_err = sqrt(ss * (1.0_R8P / n + r%x%sum * r%x%sum / (n * n * ssxx)))
      else
         r%slope_err = nan()
         r%intercept_err = nan()
      endif
   elseif (size(x) == 2) then
      r%slope_err = 0.0_R8P
      r%intercept_err = 0.0_R8P
   else
      r%slope_err = nan()
      r%intercept_err = nan()
   endif
   r%pos_min_y = x(r%y%index_min + 1_I4P)
   r%pos_max_y = x(r%y%index_max + 1_I4P)
   endfunction stats_two

   subroutine stats_report(r, unit, formatted)
   !< gnuplot's report of `r` on `unit`: the screen layout (`formatted`, gnuplot's terminal) or the name-tab-value
   !< lines gnuplot writes to a `set print` file.
   type(stats_result), intent(in) :: r         !< Statistics.
   integer(I4P),       intent(in) :: unit      !< Output unit.
   logical,            intent(in) :: formatted !< Screen layout.
   character(len=:), allocatable  :: blank     !< Gap between the two columns.
   integer(I4P)                   :: width     !< Width of the counts.
   logical                        :: negative  !< Negative intercept.

   if (.not. formatted) then
      write(unit, '(A)') 'records'//achar(9)//int_str(int(r%records, I8P)), &
                         'invalid'//achar(9)//int_str(int(r%invalid, I8P)), &
                         'blanks'//achar(9)//int_str(int(r%blank, I8P)), &
                         'blocks'//achar(9)//int_str(int(r%blocks, I8P)), &
                         'headers'//achar(9)//int_str(int(r%headers, I8P)), &
                         'outofrange'//achar(9)//int_str(int(r%outofrange, I8P))
      if (r%two) then
         call plain_column(r%x, '_x')
         call plain_column(r%y, '_y')
         write(unit, '(A)') 'slope'//achar(9)//c_real('', 0_I4P, 6_I4P, 'f', r%slope)
         if (r%records > 2_I4P) write(unit, '(A)') 'slope_err'//achar(9)//c_real('', 0_I4P, 6_I4P, 'f', r%slope_err)
         write(unit, '(A)') 'intercept'//achar(9)//c_real('', 0_I4P, 6_I4P, 'f', r%intercept)
         if (r%records > 2_I4P) write(unit, '(A)') 'intercept_err'//achar(9)// &
                                                   c_real('', 0_I4P, 6_I4P, 'f', r%intercept_err)
         write(unit, '(A)') 'correlation'//achar(9)//c_real('', 0_I4P, 6_I4P, 'f', r%correlation), &
                            'sumxy'//achar(9)//c_real('', 0_I4P, 6_I4P, 'f', r%sumxy)
      else
         call plain_column(r%y, '_y')
      endif
      return
   endif
   width = 3_I4P
   if (r%records > 0_I4P) width = 1_I4P + int(log10(real(r%records, R8P)), I4P)
   write(unit, '(A)') '', '* FILE: ', &
                      '  Records:           '//right(int_str(int(r%records, I8P)), width), &
                      '  Out of range:      '//right(int_str(int(r%outofrange, I8P)), width), &
                      '  Invalid:           '//right(int_str(int(r%invalid, I8P)), width), &
                      '  Header records:    '//right(int_str(int(r%headers, I8P)), width), &
                      '  Blank:             '//right(int_str(int(r%blank, I8P)), width), &
                      '  Data Blocks:       '//right(int_str(int(r%blocks, I8P)), width)
   width = 1_I4P
   if (r%records > 0_I4P) width = 1_I4P + int(log10(real(r%records, R8P)), I4P)
   if (.not. r%two) then
      associate(s => r%y)
         write(unit, '(A)') '', '* COLUMN: ', &
                            '  Mean:          '//fmt(s%mean), '  Std Dev:       '//fmt(s%stddev), &
                            '  Sample StdDev: '//fmt(s%ssd), '  Skewness:      '//fmt(s%skewness), &
                            '  Kurtosis:      '//fmt(s%kurtosis), '  Avg Dev:       '//fmt(s%adev), &
                            '  Sum:           '//fmt(s%sum), '  Sum Sq.:       '//fmt(s%sumsq), '', &
                            '  Mean Err.:     '//fmt(s%mean_err), '  Std Dev Err.:  '//fmt(s%stddev_err), &
                            '  Skewness Err.: '//fmt(s%skewness_err), '  Kurtosis Err.: '//fmt(s%kurtosis_err), '', &
                            '  Minimum:       '//fmt(s%min)//' ['//right(int_str(int(s%index_min, I8P)), width)//']', &
                            '  Maximum:       '//fmt(s%max)//' ['//right(int_str(int(s%index_max, I8P)), width)//']', &
                            '  Quartile:      '//fmt(s%lo_quartile)//' ', '  Median:        '//fmt(s%median)//' ', &
                            '  Quartile:      '//fmt(s%up_quartile)//' ', ''
      endassociate
      return
   endif
   blank = repeat(' ', min(17_I4P, width + 4_I4P))
   associate(x => r%x, y => r%y)
      write(unit, '(A)') '', '* COLUMNS:', &
         '  Mean:          '//fmt(x%mean)//' '//blank//' '//fmt(y%mean), &
         '  Std Dev:       '//fmt(x%stddev)//' '//blank//' '//fmt(y%stddev), &
         '  Sample StdDev: '//fmt(x%ssd)//' '//blank//' '//fmt(y%ssd), &
         '  Skewness:      '//fmt(x%skewness)//' '//blank//' '//fmt(y%skewness), &
         '  Kurtosis:      '//fmt(x%kurtosis)//' '//blank//' '//fmt(y%kurtosis), &
         '  Avg Dev:       '//fmt(x%adev)//' '//blank//' '//fmt(y%adev), &
         '  Sum:           '//fmt(x%sum)//' '//blank//' '//fmt(y%sum), &
         '  Sum Sq.:       '//fmt(x%sumsq)//' '//blank//' '//fmt(y%sumsq), '', &
         '  Mean Err.:     '//fmt(x%mean_err)//' '//blank//' '//fmt(y%mean_err), &
         '  Std Dev Err.:  '//fmt(x%stddev_err)//' '//blank//' '//fmt(y%stddev_err), &
         '  Skewness Err.: '//fmt(x%skewness_err)//' '//blank//' '//fmt(y%skewness_err), &
         '  Kurtosis Err.: '//fmt(x%kurtosis_err)//' '//blank//' '//fmt(y%kurtosis_err), '', &
         '  Minimum:       '//fmt(x%min)//' ['//right(int_str(int(x%index_min, I8P)), width)//']   '//fmt(y%min)//' ['// &
         right(int_str(int(y%index_min, I8P)), width)//']', &
         '  Maximum:       '//fmt(x%max)//' ['//right(int_str(int(x%index_max, I8P)), width)//']   '//fmt(y%max)//' ['// &
         right(int_str(int(y%index_max, I8P)), width)//']', &
         '  Quartile:      '//fmt(x%lo_quartile)//' '//blank//' '//fmt(y%lo_quartile), &
         '  Median:        '//fmt(x%median)//' '//blank//' '//fmt(y%median), &
         '  Quartile:      '//fmt(x%up_quartile)//' '//blank//' '//fmt(y%up_quartile), ''
   endassociate
   ! C's NaN < 0 is false: the + form
   negative = .false.
   if (.not. ieee_is_nan(r%intercept)) negative = r%intercept < 0.0_R8P
   if (negative) then
      write(unit, '(A)') '  Linear Model:       y = '//g4(r%slope)//' x - '//g4(-r%intercept)
   else
      write(unit, '(A)') '  Linear Model:       y = '//g4(r%slope)//' x + '//g4(r%intercept)
   endif
   write(unit, '(A)') '  Slope:              '//g4(r%slope)//' +- '//g4(r%slope_err), &
                      '  Intercept:          '//g4(r%intercept)//' +- '//g4(r%intercept_err), &
                      '  Correlation:        r = '//g4(r%correlation), &
                      '  Sum xy:             '//g4(r%sumxy), ''
   contains
      subroutine plain_column(s, suffix)
      !< The name-tab-value lines of one column, as gnuplot's sgl_column_output_nonformat (`%f` values).
      type(stats_column), intent(in) :: s      !< Column.
      character(len=*),   intent(in) :: suffix !< `_x` or `_y`.

      write(unit, '(A)') 'mean'//suffix//achar(9)//f6(s%mean), 'stddev'//suffix//achar(9)//f6(s%stddev), &
                         'ssd'//suffix//achar(9)//f6(s%ssd), 'skewness'//suffix//achar(9)//f6(s%skewness), &
                         'kurtosis'//suffix//achar(9)//f6(s%kurtosis), 'adev'//suffix//achar(9)//f6(s%adev), &
                         'sum'//suffix//achar(9)//f6(s%sum), 'sum_sq'//suffix//achar(9)//f6(s%sumsq), &
                         'mean_err'//suffix//achar(9)//f6(s%mean_err), &
                         'stddev_err'//suffix//achar(9)//f6(s%stddev_err), &
                         'skewness_err'//suffix//achar(9)//f6(s%skewness_err), &
                         'kurtosis_err'//suffix//achar(9)//f6(s%kurtosis_err), 'min'//suffix//achar(9)//f6(s%min), &
                         'lo_quartile'//suffix//achar(9)//f6(s%lo_quartile), &
                         'median'//suffix//achar(9)//f6(s%median), &
                         'up_quartile'//suffix//achar(9)//f6(s%up_quartile), 'max'//suffix//achar(9)//f6(s%max), &
                         'min_index'//suffix//achar(9)//int_str(int(s%index_min, I8P)), &
                         'max_index'//suffix//achar(9)//int_str(int(s%index_max, I8P))
      endsubroutine plain_column
   endsubroutine stats_report

   ! private procedures
   pure function analyze(v) result(s)
   !< gnuplot's analyze_sgl_column on the values `v` (at least one).
   real(R8P), intent(in)     :: v(:)     !< Values.
   type(stats_column)        :: s        !< Statistics.
   integer(I4P), allocatable :: order(:) !< Sorting permutation.
   real(R8P)                 :: n        !< Count.
   real(R8P)                 :: t        !< Deviation.
   real(R8P)                 :: ad       !< Sum of absolute deviations.
   real(R8P)                 :: d        !< Sum of deviations.
   real(R8P)                 :: d2       !< Sum of squared deviations.
   real(R8P)                 :: d3       !< Sum of cubed deviations.
   real(R8P)                 :: d4       !< Sum of fourth powers of the deviations.
   real(R8P)                 :: var      !< Population variance.
   integer(I4P)              :: m        !< Count, integer.
   integer(I4P)              :: i        !< Counter.

   m = size(v, kind=I4P)
   n = real(m, R8P)
   s%sum = 0.0_R8P
   s%sumsq = 0.0_R8P
   do i = 1_I4P, m
      s%sum = s%sum + v(i)
      s%sumsq = s%sumsq + v(i) * v(i)
   enddo
   s%mean = s%sum / n
   ad = 0.0_R8P
   d = 0.0_R8P
   d2 = 0.0_R8P
   d3 = 0.0_R8P
   d4 = 0.0_R8P
   do i = 1_I4P, m
      t = v(i) - s%mean
      ad = ad + abs(t)
      d = d + t
      d2 = d2 + t * t
      d3 = d3 + t * t * t
      d4 = d4 + t * t * t * t
   enddo
   var = (d2 - d * d / n) / n
   s%stddev = sqrt(var)
   s%adev = ad / n
   if (var /= 0.0_R8P) then
      s%skewness = d3 / (n * var * s%stddev)
      s%kurtosis = d4 / (n * var * var)
   else
      s%skewness = nan()
      s%kurtosis = nan()
   endif
   s%mean_err = s%stddev / sqrt(n)
   s%stddev_err = s%stddev / sqrt(2.0_R8P * n)
   s%skewness_err = sqrt(6.0_R8P / n)
   s%kurtosis_err = sqrt(24.0_R8P / n)
   if (m > 1_I4P) then
      s%ssd = s%stddev * sqrt(n / (n - 1.0_R8P))
   else
      ! gnuplot divides by zero here: 0 * inf
      s%ssd = nan()
   endif
   order = sorted(v)
   s%min = v(order(1))
   s%index_min = order(1) - 1_I4P
   s%max = v(order(m))
   s%index_max = order(m) - 1_I4P
   if (mod(m, 2_I4P) == 0_I4P) then
      s%median = 0.5_R8P * (v(order(m / 2_I4P)) + v(order(m / 2_I4P + 1_I4P)))
   else
      s%median = v(order((m - 1_I4P) / 2_I4P + 1_I4P))
   endif
   if (mod(m, 4_I4P) == 0_I4P) then
      s%lo_quartile = 0.5_R8P * (v(order(m / 4_I4P)) + v(order(m / 4_I4P + 1_I4P)))
      s%up_quartile = 0.5_R8P * (v(order(m - m / 4_I4P + 1_I4P)) + v(order(m - m / 4_I4P)))
   else
      s%lo_quartile = v(order((m + 3_I4P) / 4_I4P))
      s%up_quartile = v(order(m - (m + 3_I4P) / 4_I4P + 1_I4P))
   endif
   endfunction analyze

   pure function sorted(v) result(order)
   !< The permutation sorting `v` ascending, equal values in their order (a merge sort, as glibc's qsort).
   real(R8P), intent(in)     :: v(:)     !< Values.
   integer(I4P), allocatable :: order(:) !< Indices of `v`, sorted.
   integer(I4P), allocatable :: work(:)  !< Merge buffer.
   integer(I4P)              :: n        !< Count.
   integer(I4P)              :: width    !< Run width.
   integer(I4P)              :: lo       !< Run start.
   integer(I4P)              :: mid      !< Second run start.
   integer(I4P)              :: hi       !< Run end.
   integer(I4P)              :: a        !< First run cursor.
   integer(I4P)              :: b        !< Second run cursor.
   integer(I4P)              :: k        !< Output cursor.

   n = size(v, kind=I4P)
   allocate(order(n), work(n))
   order = [(k, k = 1_I4P, n)]
   width = 1_I4P
   do while (width < n)
      lo = 1_I4P
      do while (lo <= n)
         mid = min(lo + width, n + 1_I4P)
         hi = min(lo + 2_I4P * width - 1_I4P, n)
         a = lo
         b = mid
         k = lo
         do while (k <= hi)
            if (b > hi) then
               work(k) = order(a)
               a = a + 1_I4P
            elseif (a >= mid) then
               work(k) = order(b)
               b = b + 1_I4P
            elseif (v(order(b)) < v(order(a))) then
               work(k) = order(b)
               b = b + 1_I4P
            else
               work(k) = order(a)
               a = a + 1_I4P
            endif
            k = k + 1_I4P
         enddo
         lo = lo + 2_I4P * width
      enddo
      order = work
      width = 2_I4P * width
   enddo
   endfunction sorted

   pure function fmt(v) result(text)
   !< gnuplot's stats number: `undefined` for NaN, `%11.4f` (0 below 1e-14, magnitudes from 1e-6 to 1e6), else `%11.5e`.
   real(R8P), intent(in)         :: v    !< Value.
   character(len=:), allocatable :: text !< Text, 11 characters at least.

   if (ieee_is_nan(v)) then
      text = right('undefined', 11_I4P)
   elseif (abs(v) < 1.0e-14_R8P) then
      text = c_real('', 11_I4P, 4_I4P, 'f', 0.0_R8P)
   elseif (abs(log10(abs(v))) < 6.0_R8P) then
      text = c_real('', 11_I4P, 4_I4P, 'f', v)
   else
      text = c_real('', 11_I4P, 5_I4P, 'e', v)
   endif
   endfunction fmt

   pure function g4(v) result(text)
   !< `%.4g`, `nan` for NaN as C prints it.
   real(R8P), intent(in)         :: v    !< Value.
   character(len=:), allocatable :: text !< Text.

   text = c_real('', 0_I4P, 4_I4P, 'g', v)
   endfunction g4

   pure function f6(v) result(text)
   !< `%f`.
   real(R8P), intent(in)         :: v    !< Value.
   character(len=:), allocatable :: text !< Text.

   text = c_real('', 0_I4P, 6_I4P, 'f', v)
   endfunction f6

   pure function right(text, width) result(padded)
   !< `text` right justified in `width` characters (`%*s`).
   character(len=*), intent(in)  :: text   !< Text.
   integer(I4P),     intent(in)  :: width  !< Field width.
   character(len=:), allocatable :: padded !< Padded text.

   padded = repeat(' ', max(0_I4P, width - len(text, kind=I4P)))//text
   endfunction right

   pure function nan() result(v)
   !< A quiet NaN.
   real(R8P) :: v !< NaN.

   v = ieee_value(1.0_R8P, ieee_quiet_nan)
   endfunction nan
endmodule foresight_stats
